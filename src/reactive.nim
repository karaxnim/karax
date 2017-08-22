
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
  ReactiveBase* = ref object of RootObj ## everything that is a "reactive"
                                        ## value derives from that
    sinks*: seq[proc(msg: Message, pos: int)]
    dups: JDict[cstring, bool] # prevent duplicate registrations
  Reactive*[T] = ref object of ReactiveBase
    value*: T

  RString* = Reactive[cstring]
#  RTime* = Reactive[Time]
  RInt* = Reactive[int]

  RBool* = Reactive[bool]

  RSeq*[T] = ref object of ReactiveBase
    s: seq[T]
    L: RInt

proc addSink(x: ReactiveBase; sink: proc(msg: Message; pos: int)) =
  x.sinks.add sink

proc addSink(x: ReactiveBase; key: cstring; sink: proc(msg: Message; pos: int)) =
  if x.dups == nil: x.dups = newJDict[cstring, bool]()
  if not x.dups.contains(key):
    x.dups[key] = true
    x.sinks.add sink

proc broadcast(x: ReactiveBase, msg: Message; pos = 0) =
  for s in x.sinks: s(msg, pos)

var toTrack: proc (msg: Message; pos: int) = nil

proc now*[T](x: Reactive[T]): T =
  if toTrack != nil:
    x.addSink toTrack
  result = x.value

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

proc `:=`[T](x: Reactive[T], f: proc(): T) =
  toTrack = wrapObserver(f())
  x.value = f()
  toTrack = nil

proc `<-`*[T](x: Reactive[T], val: T) =
  #if x.value != val:
  x.value = val
  x.broadcast(Mark)
  x.broadcast(Changed)

proc notifyObservers*(x: ReactiveBase) =
  x.broadcast(Mark)
  x.broadcast(Changed)

proc subscribeVal*[T](x: Reactive[T], f: proc(x: T)) =
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

proc newRSeq*[T](len: int): RSeq[T] =
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

template trackImpl(r: ReactiveBase; key: cstring; a, b: untyped) =
  when r is ReactiveBase:
    addSink r, key, proc(m: Message; pos: int) =
      if m == Changed:
        runDiff(kxi, a, b)

template doTrack*(r: ReactiveBase; a, b: untyped) {.dirty.} =
  bind addSink, Message, RSeq, Changed, Deleted, Inserted
  addSink r, proc(m: Message; pos: int) =
    #when r is RSeq:
    #echo "Message: ", m, " ", pos
    if m == Changed: karax.runDiff(kxi, a, b)

template doTrackResize*(r: ReactiveBase; a, b: untyped) {.dirty.} =
  bind addSink, Message, RSeq, Changed, Deleted, Inserted
  addSink r, proc(m: Message; pos: int) =
    #when r is RSeq:
    #echo "Message: ", m, " ", pos
    case m
    of Deleted: karax.runDel(kxi, a, pos)
    of Inserted:
      karax.runIns(kxi, a, b, pos)
    else: discard

template notifyImpl(r: untyped) =
  when r is ReactiveBase:
    notifyObservers(r)

proc root(n: NimNode): NimNode =
  result = n
  while result.kind in {nnkDotExpr, nnkBracketExpr}: result = result[0]

proc analyse(n: NimNode; paramList: seq[NimNode]): NimNode =
  result = n
  #if n.kind in {nnkAsgn, nnkFastAsgn}:
  #
  #   n[0]
  #else:
  #  recurse()

macro track*(procDef: untyped): untyped =
  let params = params(procDef)
  let key = lineInfo(procDef)
  var call = newCall(procDef.name)
  var trackings = newStmtList()
  var paramList: seq[NimNode] = @[]
  for j in 1..<params.len:
    let x = params[j]
    expectKind x, nnkIdentDefs
    for i in 0..x.len-3: paramList.add(x[i])

  for b in procDef.body: trackings.add analyse(b, paramList)
  for param in paramList:
    call.add param
    trackings.add getAst(trackImpl(param, key, ident"result", call))

  result = copyNimTree(procDef)
  result.body = trackings
