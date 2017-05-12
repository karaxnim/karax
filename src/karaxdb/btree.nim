
# max children per B-tree node = M-1
# (must be even and greater than 2)
const
   M = 4
   Mhalf = M div 2

type
  Key = string
  Val = string
  Entry = ref object
    key: Key
    val: Val # external nodes only
    next: Node   # internal nodes only; helper field to iterate over array entries
  Node = ref object
    m: int
    children: array[M, Entry]
  BTree = ref object
    root: Node
    height: int ## height
    n: int      ## number of key-value pairs

proc newBTree(): BTree = BTree(root: Node(m: 0))

proc less(a, b: Key): bool = cmp(a, b) < 0

proc eq(a, b: Key): bool = cmp(a, b) == 0

proc search(x: Node, key: Key, ht: int): Val =
  if ht == 0:
    # external node
    for j in 0 ..< x.m:
      if eq(key, x.children[j].key): return x.children[j].val
  else:
    # internal node
    for j in 0 ..< x.m:
      if j+1 == x.m or less(key, x.children[j+1].key):
        return search(x.children[j].next, key, ht-1)
  return nil

proc candidates(x: Node, key: Key, ht: int): Node =
  if ht == 0:
    return x
  else:
    # internal node
    for j in 0 ..< x.m:
      if j+1 == x.m or less(key, x.children[j+1].key):
        return candidates(x.children[j].next, key, ht-1)
  return nil

iterator allValues(t: BTree; key: Key): Val =
  let x = candidates(t.root, key, t.height)
  if x != nil:
    for j in 0 ..< x.m:
      if eq(key, x.children[j].key): yield x.children[j].val

proc get(t: BTree; key: Key): Val = search(t.root, key, t.height)

proc split(h: Node): Node =
  ## split node in half
  result = Node(m: Mhalf)
  h.m = Mhalf
  for j in 0 ..< Mhalf:
    result.children[j] = h.children[Mhalf + j]

proc insert(h: Node, key: Key, val: Val, ht: int): Node =
  var t = Entry(key: key, val: val, next: nil)
  var j = 0
  if ht == 0:
    # external node:
    while j < h.m:
      if less(key, h.children[j].key): break
      inc j
  else:
    # internal node
    while j < h.m:
      if j+1 == h.m or less(key, h.children[j+1].key):
        let u = insert(h.children[j].next, key, val, ht-1)
        inc j
        if u == nil: return nil
        t.key = u.children[0].key
        t.next = u
        break
      inc j
  for i in countdown(h.m, j+1):
    h.children[i] = h.children[i-1]
  h.children[j] = t
  inc h.m
  return if h.m < M: nil else: split(h)

proc put(b: BTree; key: Key; val: Val) =
  let u = insert(b.root, key, val, b.height)
  inc b.n
  if u == nil: return

  # need to split root
  let t = Node(m: 2)
  t.children[0] = Entry(key: b.root.children[0].key, val: nil, next: b.root)
  t.children[1] = Entry(key: u.children[0].key, val: nil, next: u)
  b.root = t
  inc b.height

proc toString(h: Node, ht: int, indent: string; result: var string) =
  if ht == 0:
    for j in 0..<h.m:
      result.add(indent)
      result.add($h.children[j].key & " " & $h.children[j].val & "\n")
  else:
    for j in 0..<h.m:
      if j > 0: result.add(indent & "(" & $h.children[j].key & ")\n")
      toString(h.children[j].next, ht-1, indent & "   ", result)

proc `$`(b: BTree): string =
  result = ""
  toString(b.root, b.height, "", result)

proc main =
  var st = newBTree()
  st.put("www.cs.princeton.edu", "128.112.136.12")
  st.put("www.cs.princeton.edu", "128.112.136.11")
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

  echo("cs.princeton.edu:  ", st.get("www.cs.princeton.edu"))
  echo("hardvardsucks.com: ", st.get("www.harvardsucks.com"))
  echo("simpsons.com:      ", st.get("www.simpsons.com"))
  echo("apple.com:         ", st.get("www.apple.com"))
  echo("ebay.com:          ", st.get("www.ebay.com"))
  echo("dell.com:          ", st.get("www.dell.com"))
  echo()
  echo("size:    ", st.n)
  echo("height:  ", st.height)
  echo(st)

  var dups = newBTree()
  for i in 0..20:
    dups.put("testme", $i)
  echo dups
  for v in allValues(dups, "testme"):
    echo v
  echo dups.get("testme")

main()
