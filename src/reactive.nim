
import jdict

type
  Message = enum
    Unchanged
    Changed
    Mark
    Inserted
    Deleted
    Replaced

  State = object
    stale: int
    outdated: bool
    phantom: bool

type
  SinkSeq = seq[proc(msg: Message, pos: int)]
  ReactiveBase* = ref object of RootObj ## everything that is a "reactive"
                                        ## value derives from that
    sinks*: SinkSeq
    dups: JDict[cstring, int]
    id: int
  Reactive*[T] = ref object of ReactiveBase
    value*: T

  RString* = Reactive[cstring]
#  RTime* = Reactive[Time]
  RInt* = Reactive[int]

  RBool* = Reactive[bool]

  RSeq*[T] = ref object of ReactiveBase
    s: seq[T]
    L: RInt

var rid: int

proc addSink(x: ReactiveBase; key: cstring; sink: proc(msg: Message; pos: int)) =
  if x.dups == nil: x.dups = newJDict[cstring, int]()
  if not x.dups.contains(key):
    x.dups[key] = x.sinks.len
    x.sinks.add sink
    if x.id == 0:
      inc rid
      x.id = rid
  else:
    # update existing entry:
    x.sinks[x.dups[key]] = sink

proc addSink(x: ReactiveBase; sink: proc(msg: Message; pos: int)) =
  x.sinks.add sink
  if x.id == 0:
    inc rid
    x.id = rid

var inhibited: int

proc broadcast(x: ReactiveBase, msg: Message; pos = 0) =
  if inhibited == 0:
    for s in x.sinks: s(msg, pos)

var toTrack: seq[(cstring, proc (msg: Message; pos: int))] = @[]

template withTrack(key, t, body) =
  toTrack.add((key, t))
  body
  discard toTrack.pop()

proc trackDependency*(r: ReactiveBase) =
  for t in toTrack:
    r.addSink t[0], t[1]

template wrapObserver(f: untyped) =
  var state: State
  proc helper(msg: Message; pos: int) =
    case msg.kind:
    of Changed, Unchanged:
      state.outdated = state.outdated or (msg.kind == Changed)
      dec state.stale
      if state.stale == 0:
        if state.outdated:
          var t = f()
          let thisChanged = if x.value != t: Changed else: Unchanged
          x.value = t
          x.broadcast(thisChanged, pos)
          state.outdated = false
        else:
          x.broadcast(Unchanged, pos)
    of Mark:
      if state.stale == 0: x.broadcast(msg, pos)
      inc state.stale
    of Inserted, Deleted, Replaced:
      dec state.stale
      if state.stale == 0:
        x.broadcast(msg, pos)
        #state.phantom = true
  helper

template glitchFree(f: untyped) =
  var state: State
  proc helper(msg: Message; pos: int) =
    case msg.kind:
    of Changed, Unchanged:
      state.outdated = state.outdated or (msg.kind == Changed)
      dec state.stale
      if state.stale == 0:
        if state.outdated:
          x.value = f
          x.broadcast(msg.kind, pos)
          state.outdated = false
        else:
          x.broadcast(Unchanged, pos)
    of Mark:
      if state.stale == 0: x.broadcast(msg, pos)
      inc state.stale
    of Inserted, Deleted, Replaced:
      dec state.stale
      if state.stale == 0:
        x.broadcast(msg, pos)
  helper

proc `<-`*[T](x: Reactive[T], val: T) =
  #if x.value != val:
  x.value = val
  x.broadcast(Mark)
  x.broadcast(Changed)

proc notifyObservers*(x: ReactiveBase) =
  x.broadcast(Mark)
  x.broadcast(Changed)

proc subscribe*[T](x: Reactive[T], f: proc(x: T)) =
  let reactor = proc (msg: Message, pos: int) =
    case msg:
    of Mark: discard
    of Changed, Unchanged: f(x.value)
    of Inserted, Deleted, Replaced: discard
  x.addSink reactor

proc subscribeSelf*[T: ReactiveBase](x: T, f: proc()) =
  let reactor = proc (msg: Message, pos: int) =
    case msg:
    of Mark: discard
    of Changed, Unchanged: f()
    of Inserted, Deleted, Replaced: discard
  x.addSink reactor

template lift1(op: untyped) =
  proc op[T](a: Reactive[T]): (proc(): T) =
    result = proc(): T = op(a.now)

template lift2(op: untyped) =
  proc op[T](a, b: Reactive[T]): (proc(): T) =
    result = proc(): T = op(a.now, b.now)

lift1 `not`
lift2 `&`

proc newReactive*[T](x: T): Reactive[T] =
  result = Reactive[T](value: x)

proc rstr*(x: cstring): RString =
  result = RString(value: x)

proc newRSeq*[T](len: int = 0): RSeq[T] =
  result = RSeq[T](s: newSeq[T](len), L: newReactive[int](0))

proc newRSeq*[T](data: seq[T]): RSeq[T] =
  result = RSeq[T](s: newSeq[T](data.len), L: newReactive[int](0))
  for i in 0..high(data):
    result.s[i] = data[i]

proc `[]=`*[T](x: RSeq[T]; index: int; v: T) =
  x.s[index] = v
  x.broadcast(Mark)
  x.broadcast(Replaced, index)

proc `[]`*[T](x: RSeq[T]; index: int): T = x.s[index]
proc len*[T](x: RSeq[T]): int = x.s.len

proc add*[T](x: RSeq[T]; y: T) =
  let position = x.s.len
  x.s.add(y)
  x.broadcast(Mark)
  x.broadcast(Inserted, position)

proc insert*[T](x: RSeq[T]; y: T; position = 0) =
  x.s.insert(y, position)
  x.broadcast(Mark)
  x.broadcast(Inserted, position)

proc delete*[T](x: RSeq[T]; position = 0) =
  x.s.delete(position)
  x.broadcast(Mark)
  x.broadcast(Deleted, position)

proc deleteElem*[T](x: RSeq[T]; y: T) =
  var position = -1
  for i in 0..<x.len:
    if x[i] == y:
      position = i; break
  if position >= 0:
    x.s.delete(position)
    x.broadcast(Mark)
    x.broadcast(Deleted, position)

when false:
  proc `:=`[T](x: Reactive[T], f: proc(): T) =
    toTrack = wrapObserver(f())
    x.value = f()
    toTrack = nil

  proc map*[T, U](x: RSeq[T], f: proc(x: T): U): RSeq[U] =
    let xl = x.L.value
    let res = newRSeq[U](xl)
    for i in 0..<xl:
      res.s[i] := proc(): U = f(x[i].now)

    let reactor = proc (msg: Message, pos: int) =
      case msg:
      of Mark, Changed, Unchanged: discard "nothing to do"
      of Inserted:
        res.insert(f(x[pos]), pos)
      of Deleted:
        res.delete(pos)
    x.addSink reactor
    result = res

import macros

template protect(body: untyped) =
  #var tmp: seq[proc(msg: Message, pos: int)]
  #swap(r.sinks, tmp)
  inc inhibited
  body
  dec inhibited
  #swap(r.sinks, tmp)

template trackStart(key: cstring; a, b: untyped) =
  proc differ(m: Message; pos: int) =
    if m == Changed:
      protect:
        karax.runDiff(kxi, a, b)
  toTrack.add((key, differ))

template trackEnd() =
  discard toTrack.pop()

template doTrack(r: ReactiveBase; a, b: untyped) {.dirty.} =
  bind addSink, Message, RSeq, Changed, Deleted, Inserted
  addSink r, proc(m: Message; pos: int) =
    #when r is RSeq:
    #echo "Message: ", m, " ", pos
    if m == Changed:
      protect r:
        karax.runDiff(kxi, a, b)

template doTrackResize(r: ReactiveBase; a, b: untyped) {.dirty.} =
  bind addSink, Message, RSeq, Changed, Deleted, Inserted
  addSink r, proc(m: Message; pos: int) =
    #when r is RSeq:
    #echo "Message: ", m, " ", pos
    case m
    of Deleted: karax.runDel(kxi, a, pos)
    of Inserted:
      let it {.used.} = r[pos]
      karax.runIns(kxi, a, b, pos)
    else: discard

macro track*(procDef: untyped): untyped =
  let params = params(procDef)
  var trackings = newStmtList()
  var inner = copyNimTree(procDef)
  inner[0] = ident($procDef.name & "Inner")
  var call = newCall(inner[0])

  for j in 1..<params.len:
    let x = params[j]
    expectKind x, nnkIdentDefs
    for i in 0..x.len-3:
      let param = x[i]
      call.add(param)

  trackings.add inner
  let key = newCall("cstring", newLit lineInfo(procDef))
  trackings.add getAst(trackStart(key, ident"result", call))
  trackings.add newAssignment(ident"result", call)
  trackings.add getAst(trackEnd())

  result = copyNimTree(procDef)
  result.body = trackings
  when defined(debugKaraxDsl):
    echo repr result

proc generatePrivateAccessors(name, hidden, typ, fieldTyp: NimNode): NimNode =
  template helper(name, hidden, typ, fieldTyp) {.dirty.} =
    proc name(self: typ): fieldTyp =
      trackDependency(self)
      result = self.hidden
    proc `name=`(self: typ; val: fieldTyp) =
      self.hidden = val
      notifyObservers(self)
  result = getAst(helper(name, hidden, typ, fieldTyp))

proc generatePublicAccessors(name, hidden, typ, fieldTyp: NimNode): NimNode =
  template helper(name, hidden, typ, fieldTyp) {.dirty.} =
    proc name*(self: typ): fieldTyp =
      trackDependency(self)
      result = self.hidden
    proc `name=`*(self: typ; val: fieldTyp) =
      self.hidden = val
      notifyObservers(self)
  result = getAst(helper(name, hidden, typ, fieldTyp))

proc transform(n: NimNode; stmts, obj: NimNode): NimNode =
  if n.kind == nnkIdentDefs and obj.kind == nnkIdent:
    for i in 0..n.len-3:
      let it = n[i]
      let itB = if it.kind == nnkPostFix: it[1] else: it
      let hidden = newIdentNode("raw" & $itB)
      if it.kind == nnkPostFix:
        stmts.add generatePublicAccessors(itB, hidden, obj, n[n.len-2])
      else:
        stmts.add generatePrivateAccessors(itB, hidden, obj, n[n.len-2])
      n[i] = hidden
    result = n
  else:
    var objB = if n.kind == nnkTypeDef: n[0] else: obj
    result = copyNimNode(n)
    for i in 0..<n.len:
      if n.kind == nnkObjectTy and i == 1 and n[1].kind == nnkEmpty:
        result.add newTree(nnkOfInherit, ident("ReactiveBase"))
      else:
        result.add transform(n[i], stmts, objB)

macro makeReactive*(n: untyped): untyped =
  var a = newStmtList()
  a.add newEmptyNode()
  let t = transform(n, a, newEmptyNode())
  a[0] = t
  result = a
  when defined(debugKaraxDsl):
    echo repr result

import vdom

template vmap*(x: RSeq; elem, f: untyped): VNode =
  let tmp = buildHtml(elem):
    for i in 0..<len(x):
      f(x[i])
  doTrackResize(x, tmp, f(x[pos]))
  tmp

template vmapIt*(x: RSeq; elem, call: untyped): VNode =
  var it {.inject.}: type(x[0])
  let tmp = buildHtml(elem):
    for i in 0..<len(x):
      it = x[i]
      call
  doTrackResize(x, tmp, call)
  tmp

proc text*(s: RString): VNode =
  result = text(s.value)
  s.subscribe proc(v: cstring) =
    if result.dom != nil: result.dom.nodeValue = v

when isMainModule:
  makeReactive:
    type
      Foo = ref object of ReactiveBase
        x, y: int
      Bar = ref object of ReactiveBase
        z: string
        exported*: int
      Another = ref object
        a, b: cstring
        c: bool
