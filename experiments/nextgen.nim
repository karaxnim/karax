
import vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils

type
  Message = enum
    Unchanged
    Changed
    Mark
    Inserted
    Deleted

  State = object
    stale: int
    outdated: bool
    phantom: bool

type
  ReactiveBase* = ref object of RootObj ## everything that is a "reactive"
                                        ## value derives from that
    sinks*: seq[proc(msg: Message, pos: int)]
  Reactive*[T] = ref object of ReactiveBase
    value*: T

  RString* = Reactive[cstring]
#  RTime* = Reactive[Time]
  RInt* = Reactive[int]

  RBool* = Reactive[bool]

  RSeq*[T] = ref object of ReactiveBase
    s: seq[T]
    L: RInt

proc addSink[T](x: Reactive[T]; sink: proc(msg: Message; pos: int)) =
  x.sinks.add sink

proc broadcast(x: ReactiveBase, msg: Message; pos = 0) =
  for s in x.sinks: s(msg, pos)

var toTrack: proc (msg: Message; pos: int) = nil

proc now[T](x: Reactive[T]): T =
  if toTrack != nil:
    x.addSink toTrack
  result = x.value

proc `:=`[T](x: Reactive[T], f: proc(): T) =
  var state: State

  toTrack = proc(msg: Message; pos: int) =
    if not state.phantom:
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
        if state.stale == 0:
          x.broadcast(msg, pos)
        inc state.stale
      of Inserted, Deleted:
        dec state.stale
        if state.stale == 0:
          x.broadcast(msg, pos)
          #state.phantom = true

  x.value = f()
  toTrack = nil

proc `<-`[T](x: Reactive[T], val: T) =
  if x.value != val:
    x.value = val
    x.broadcast(Mark)
    x.broadcast(Changed)

proc changed*(x: ReactiveBase) =
  x.broadcast(Mark)
  x.broadcast(Changed)

proc subscribe[T](x: Reactive[T], f: proc(x: T)) =
  let reactor = proc (msg: Message, pos: int) =
    case msg:
    of Mark: discard
    of Changed, Unchanged: f(x.value)
    of Inserted, Deleted: discard
  x.addSink reactor

template lift1(op: untyped) =
  proc op[T](a: Reactive[T]): (proc(): T) =
    result = proc(): T = op(a.now)

template lift2(op: untyped) =
  proc op[T](a, b: Reactive[T]): (proc(): T) =
    result = proc(): T = op(a.now, b.now)

lift1 `not`
lift2 `&`

proc newReactive[T](x: T): Reactive[T] =
  result = Reactive[T](value: x)

proc rstr(x: cstring): RString =
  result = RString(value: x)

proc newRSeq*[T](len: int): RSeq[T] =
  result = RSeq[T](s: newSeq[T](len), L: newReactive[int](0))

proc newRSeq*[T](data: seq[T]): RSeq[T] =
  result = RSeq[T](s: newSeq[T](data.len), L: newReactive[int](0))
  for i in 0..high(data):
    result.s[i] = data[i]

proc `[]=`[T](x: RSeq[T]; index: int; v: T) =
  x.s[index] = v

proc `[]`[T](x: RSeq[T]; index: int): T = x.s[index]

proc insert*[T](x: RSeq[T]; y: T; position = 0) =
  x.s.insert(y, position)
  x.broadcast(Mark)
  x.broadcast(Inserted, position)

proc delete*[T](x: RSeq[T]; position = 0) =
  x.s.delete(position)
  x.broadcast(Mark)
  x.broadcast(Deleted, position)

proc map[T, U](x: RSeq[T], f: proc(x: T): U): RSeq[U] =
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

type
  User = ref object
    firstname, lastname: cstring

var gu = newReactive(User(firstname: "Some", lastname: "Body"))

proc renderUser(u: Reactive[User]): VNode =
  result = buildHtml(button):
    text u.now.firstname & " " & u.now.lastname
    proc onclick(ev: Event; n: VNode) =
      gu <- User(firstname: "Another", lastname: "Guy")

template track(r: ReactiveBase; a, b: VNode) =
  r.addSink proc(m: Message; pos: int) =
    if m == Changed:
      runDiff(kxi, a, b)

proc main(): VNode =
  result = renderUser(gu)
  track gu, result, renderUser(gu)

setInitializer(main)
