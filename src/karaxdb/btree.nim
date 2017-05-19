
## General purpose BTree implementation. Can also be used as a persistent
## data structure. The persistent operations use a 'Ps' suffix.
## Can also use a page manager for allocations. The page manager be used
## to off load pages to a file system or to send it over the wire.

## Todo:
## - Add logic to deal with the fact that keys do not have to be unique.
## - Ranged queries
## - Make it generic and low level
## - Support for external nodes and a page cache

const
  M = 4   # max children per B-tree node = M-1
          # (must be even and greater than 2)
  Mhalf = M div 2

  SupportFullTableScan = true
  SupportDuplicateKeys = true

## Due to the fact that leaves are shared among multiple BTrees the following
## fields in a Node are downright impossible:
## - parent
## - next
## - prev

type
  Key = string
  Val = string
  Node = ref object
    m: int
    keys: array[M, Key]
    case isInternal: bool
    of false:
      vals: array[M, Val]
    of true:
      links: array[M, Node]
  BTree = object
    root: Node
    height: int ## height
    n: int      ## number of key-value pairs
  CmpKind {.pure.} = enum
    eq, le, lt, ge, gt, neq
  Cursor = object
    n: Node
    i, dir: int
    up: seq[(Node, int)]

proc newBTree(): BTree = BTree(root: Node(m: 0, isInternal: false))

proc less(a, b: Key): bool = cmp(a, b) < 0

proc eq(a, b: Key): bool = cmp(a, b) == 0

proc search(x: Node, key: Key, ht: int): Val =
  if ht == 0:
    assert(not x.isInternal)
    for j in 0 ..< x.m:
      if eq(key, x.keys[j]): return x.vals[j]
  else:
    assert(x.isInternal)
    for j in 0 ..< x.m:
      if j+1 == x.m or less(key, x.keys[j+1]):
        return search(x.links[j], key, ht-1)

proc `=~`(i: int; k: CmpKind): bool =
  ## check if the result of 'cmp' matches what was requested by 'k':
  case k
  of CmpKind.eq: i == 0
  of CmpKind.le: i <= 0
  of CmpKind.lt: i < 0
  of CmpKind.ge: i >= 0
  of CmpKind.gt: i > 0
  of CmpKind.neq: i != 0

proc follow(i: int; k: CmpKind): bool =
  case k
  of CmpKind.eq:
    # we demand equality so if less than, follow it
    i < 0
  of CmpKind.le:
    i <= 0
  of CmpKind.lt: i <= 0
  of CmpKind.ge: i >= 0
  of CmpKind.gt: i >= 0
  of CmpKind.neq: true

proc startingPoint(x: Node; key: Key; kind: CmpKind): Cursor =
  if x.isInternal:
    for j in 0 ..< x.m:
      if j+1 == x.m or cmp(key, x.keys[j+1]) =~ kind:
        return startingPoint(x.links[j], key, kind)
  else:
    for j in 0 ..< x.m:
      let cmpRes = cmp(key, x.keys[j])
      if cmpRes =~ kind: return Cursor(n: x, i: j)

proc dos(x: Node; kind: CmpKind; key: Key; withKey: proc(k: Key; v: Val)) =
  if not x.isInternal:
    for j in 0 ..< x.m:
      if cmp(x.keys[j], key) =~ kind:
        withKey(x.keys[j], x.vals[j])
  else:
    # we compute the range of links to follow first, before
    # recursing:
    var followA = 0
    var followB = -1
    case kind
    of CmpKind.eq:
      # want: key == 10
      # keys: 0 3  4 5  10 20
      # keys: 20 30 40
      for j in 1..x.m:
        if j == x.m or cmp(key, x.keys[j]) < 0:
          followA = j-1
          followB = j-1
          break
    of CmpKind.le, CmpKind.lt:
      # want: key <= 10  or   key < 10
      # keys: 0 3  4 5  10 20
      # keys: 20 30 40

      # Case A: all keys are bigger:
      if cmp(key, x.keys[1]) < 0:
        # --> use the very first branch
        followA = 0
        followB = 0
      else:
        # Case B: all keys are smaller --> use all branches is covered too
        # by this loop.
        for j in 1..<x.m:
          let cmpRes = cmp(key, x.keys[j])
          if cmpRes >= 0:
            if followB < 0: followA = j-1
            # if the keys are identical and we require 'lt', we know
            # only the left branch is required:
            followB = j - ord(kind == CmpKind.lt and cmpRes == 0)
          else:
            # it's already greater, all others are greater too:
            break
    of CmpKind.ge, CmpKind.gt:
      # want: key >= 10  or  key > 10
      # keys: 0 3  4 5  10 20
      # keys: 20 30 40

      # Case A:  all keys are smaller:
      if cmp(key, x.keys[x.m-1]) >= 0:
        # --> use the very last branch
        followA = x.m-1
        followB = x.m-1
      else:
        # also covers case B: all keys are bigger --> use all branches
        # we find the key that is bigger or equal to ours and from
        # then on, follow every branch:
        for j in 1..<x.m:
          let cmpRes = cmp(key, x.keys[j])
          if cmpRes <= 0:
            # if the keys are identical and we need 'ge', we don't have
            # to consider the 'j-1' branch:
            followA = j - ord(kind != CmpKind.ge or cmpRes != 0)
            # we know everything else is even bigger:
            followB = x.m-1
            break
    of CmpKind.neq:
      # neq: just follow all for now:
      followA = 0
      followB = x.m-1
    # now recurse into the branches that hold candidates we're interested in:
    for i in followA..followB:
      dos(x.links[i], kind, key, withKey)

proc init(x: Node): Cursor =
  result.up = @[]
  result.i = 0
  var it = x
  while it.isInternal:
    result.up.add((it, 0))
    it = it.links[0]
  result.n = it

proc next(c: var Cursor) =
  assert c.n != nil
  if c.i >= c.n.m:
    # current leaf exhausted, pick the next one:
    if c.up.len > 0:
      (c.n, c.i) = c.up.pop()

  inc c.i
  var u = 1
  while c.i > c.n.m or c.n.isInternal:
    if c.up.len > 0:
      (c.n, c.i) = c.up[c.up.len - u]
    else:
      c.n = nil
      return
  assert(c.n == nil or not c.n.isInternal)

proc atEnd(c: Cursor): bool = c.n == nil

proc getKey(c: Cursor): Key = discard
proc getVal(c: Cursor): Val = discard

proc get(t: BTree; key: Key): Val = search(t.root, key, t.height)

proc copyHalf(h, result: Node; offset: int) =
  for j in 0 ..< Mhalf:
    result.keys[j] = h.keys[offset + j]
  if h.isInternal:
    for j in 0 ..< Mhalf:
      result.links[j] = h.links[offset + j]
  else:
    for j in 0 ..< Mhalf:
      shallowCopy(result.vals[j], h.vals[offset + j])

proc split(h: Node): Node =
  ## split node in half
  result = Node(m: Mhalf, isInternal: h.isInternal)
  h.m = Mhalf
  copyHalf(h, result, Mhalf)

when false:
  # unnecessary because when we call 'split' we know it's not a
  # shared node!
  proc splitPs(h: Node): (Node, Node) =
    ## persistent variant of 'split'.
    var a = Node(m: Mhalf, isInternal: h.isInternal)
    var b = Node(m: Mhalf, isInternal: h.isInternal)
    copyHalf(h, a, Mhalf)
    copyHalf(h, b, 0)
    result = (a, b)

proc insert(h: Node, key: Key, val: Val, ht: int): Node =
  #var t = Entry(key: key, val: val, next: nil)
  var newKey = key
  var j = 0
  if ht == 0:
    assert(not h.isInternal)
    while j < h.m:
      if less(key, h.keys[j]): break
      inc j
    for i in countdown(h.m, j+1):
      shallowCopy(h.vals[i], h.vals[i-1])
    h.vals[j] = val
  else:
    assert h.isInternal
    var newLink: Node = nil
    while j < h.m:
      if j+1 == h.m or less(key, h.keys[j+1]):
        let u = insert(h.links[j], key, val, ht-1)
        inc j
        if u == nil: return nil
        newKey = u.keys[0]
        newLink = u
        break
      inc j
    for i in countdown(h.m, j+1):
      h.links[i] = h.links[i-1]
    h.links[j] = newLink

  for i in countdown(h.m, j+1):
    h.keys[i] = h.keys[i-1]
  h.keys[j] = newKey
  inc h.m
  return if h.m < M: nil else: split(h)

proc insertPs(h: Node, key: Key, val: Val, ht: int): (Node, Node) =
  var j = 0
  var hh = Node(m: h.m, isInternal: h.isInternal)
  for i in 0 ..< h.m: hh.keys[i] = h.keys[i]
  if ht == 0:
    assert(not h.isInternal)
    while j < h.m:
      if less(key, h.keys[j]): break
      inc j
    for i in countdown(h.m, j+1): shallowCopy(hh.vals[i], h.vals[i-1])
    for i in 0 ..< j: shallowCopy(hh.vals[i], h.vals[i])
    for i in countdown(h.m, j+1): hh.keys[i] = hh.keys[i-1]
    hh.vals[j] = val
    hh.keys[j] = key
  else:
    assert h.isInternal
    # could optimize this copying here:
    for i in 0 ..< h.m: hh.links[i] = h.links[i]
    while j < h.m:
      if j+1 == h.m or less(key, h.keys[j+1]):
        let (root, r) = insertPs(h.links[j], key, val, ht-1)
        hh.links[j] = root
        if r == nil:
          return (hh, nil)
        else:
          inc j
          for i in countdown(h.m, j+1):
            hh.links[i] = hh.links[i-1]
            hh.keys[i] = hh.keys[i-1]
          hh.links[j] = r
          hh.keys[j] = r.keys[0]
          break
      inc j
  inc hh.m
  return if hh.m < M: (hh, nil) else: (hh, split(hh))

proc put(b: var BTree; key: Key; val: Val) =
  let u = insert(b.root, key, val, b.height)
  inc b.n
  if u == nil: return

  # need to split root
  let t = Node(m: 2, isInternal: true)
  t.keys[0] = b.root.keys[0]
  t.links[0] = b.root
  t.keys[1] = u.keys[0]
  t.links[1] = u
  b.root = t
  inc b.height

proc putPs(b: BTree; key: Key; val: Val): BTree =
  let (root, u) = insertPs(b.root, key, val, b.height)
  result.n = b.n + 1
  result.height = b.height
  if u == nil:
    result.root = root
    return
  # need to split root
  let t = Node(m: 2, isInternal: true)
  t.keys[0] = root.keys[0]
  t.links[0] = root
  t.keys[1] = u.keys[0]
  t.links[1] = u
  result.root = t
  inc result.height

proc toString(h: Node, ht: int, indent: string; result: var string) =
  if ht == 0:
    assert(not h.isInternal)
    for j in 0..<h.m:
      result.add(indent)
      result.add($h.keys[j] & " " & $h.vals[j] & "\n")
  else:
    assert(h.isInternal)
    for j in 0..<h.m:
      if j > 0: result.add(indent & "(" & $h.keys[j] & ")\n")
      toString(h.links[j], ht-1, indent & "   ", result)

proc `$`(b: BTree): string =
  result = ""
  toString(b.root, b.height, "", result)

when isMainModule:
  proc main =
    var st = newBTree()
    st.put("www.cs.princeton.edu", "abc")
    st.put("www.cs.princeton.edu", "xyz")
    st.put("www.princeton.edu",    "128.112.128.15")
    st.put("www.yale.edu",         "130.132.143.21")
    st.put("www.simpsons.com",     "209.052.165.60")
    st.put("www.apple.com",        "17.112.152.32")
    st.put("www.amazon.com",       "207.171.182.16")
    st.put("www.ebay.com",         "66.135.192.87")
    st.put("www.cnn.com",          "64.236.16.20")
    st.put("www.google.com",       "216.239.41.99")
    st.put("www.nytimes.com",      "199.239.136.200")
    st.put("www.microsoft.com",    "207.126.99.140")
    st.put("www.dell.com",         "143.166.224.230")
    st.put("www.slashdot.org",     "66.35.250.151")
    st.put("www.espn.com",         "199.181.135.201")
    st.put("www.weather.com",      "63.111.66.11")
    st.put("www.yahoo.com",        "216.109.118.65")

    assert st.get("www.cs.princeton.edu") == "abc"
    assert st.get("www.harvardsucks.com") == nil

    assert st.get("www.simpsons.com") == "209.052.165.60"
    assert st.get("www.apple.com") == "17.112.152.32"
    assert st.get("www.ebay.com") == "66.135.192.87"
    assert st.get("www.dell.com") == "143.166.224.230"
    assert(st.n == 17)

    when false:
      var b2 = newBTree()
      const iters = 10_000
      for i in 1..iters:
        b2.put($i, $(iters - i))
      for i in 1..iters:
        let x = b2.get($i)
        if x != $(iters - i):
          echo "got ", x, ", but expected ", iters - i
      echo b2.n
      echo b2.height

    when true:
      var b1 = newBTree()
      var b2 = newBTree()
      const iters = 9 #60_000
      for i in 1..iters:
        b2 = b2.putPs($i, $(iters - i))
        b1.put($i, $(iters - i))
      for i in 1..iters:
        let x = b2.get($i)
        if x != $(iters - i):
          echo i, "th iteration; got ", x, ", but expected ", iters - i
      echo b2.n, " = ", b1.n
      echo b2.height, " = ", b1.height
      echo " >= 5"
      dos(b1.root, CmpKind.ge, "5", proc(k: Key; v: Val) = echo("k ", k, " = ", v))
      echo " <= 5"
      dos(b1.root, CmpKind.le, "5", proc(k: Key; v: Val) = echo("k ", k, " = ", v))

      echo " == 5"
      dos(b1.root, CmpKind.eq, "5", proc(k: Key; v: Val) = echo("k ", k, " = ", v))
      echo " < 5"
      dos(b1.root, CmpKind.lt, "5", proc(k: Key; v: Val) = echo("k ", k, " = ", v))
      echo " > 5"
      dos(b1.root, CmpKind.gt, "5", proc(k: Key; v: Val) = echo("k ", k, " = ", v))

  main()
