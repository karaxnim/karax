
include "../karax/karax"
import "../karax/karaxdsl"

proc hasDom(n: Vnode) =
  if n.kind in {VNodeKind.component, VNodeKind.vthunk, VNodeKind.dthunk}:
    discard
  else:
    doAssert n.dom != nil
    for i in 0..<n.len: hasDom(n[i])

proc shortRepr(n: VNode): string =
  if n == nil:
    result = "nil"
  elif n.kind == VNodeKind.text:
    result = $n.text
  else:
    result = $n.kind
    for i in 0..<n.len:
      result &= " " & shortRepr(n[i])

var err = 0

proc doDiff(a, b: VNode; expected: varargs[string]) =
  diff(b, a, nil, vnodeToDom(a, kxi), kxi)
  var j = 0
  for i in 0..<kxi.patchLen:
    if kxi.patches[i].k != pkSame:
      let n = if kxi.patches[i].k == pkDetach: kxi.patches[i].oldNode else: kxi.patches[i].newNode
      let p = $kxi.patches[i].k & " " & shortRepr(n)
      if j >= expected.len:
        echo "patches differ; expected nothing but got: ", p
        inc err
      elif p != expected[j]:
        echo "patches differ; expected ", expected[i], " but got: ", p
        inc err
      inc j
  #hasDom(kxi.currentTree)
  kxi.patchLen = 0

proc testAppend() =
  let a = buildHtml(tdiv):
    ul:
      li: text "A"
      li: text "B"
  let b = buildHtml(tdiv):
    ul:
      li: text "A"
      li: text "B"
      li:
        tdiv:
          text "C"
  doDiff(a, b, "pkAppend li div C")

proc testInsert() =
  let a = buildHtml(tdiv):
    ul:
      li: text "A"
      li:
        button:
          text "C"
  let b = buildHtml(tdiv):
    ul:
      li: text "A"
      li: text "B"
      li:
        button:
          text "C"
  doDiff(a, b, "pkInsertBefore li B")

proc testInsert2() =
  let a = buildHtml(tdiv):
    tdiv:
      tdiv:
        ul:
          li: text "A"
          li:
            button:
              text "D"
  let b = buildHtml(tdiv):
    tdiv:
      tdiv:
        ul:
          li: text "A"
          li: text "B"
          li: text "C"
          li:
            button:
              text "D"
  doDiff(a, b, "pkInsertBefore li B", "pkInsertBefore li C")

proc testDelete() =
  let a = buildHtml(tdiv):
    ul:
      li: text "A"
      li: text "B"
      li: text "C"
  let b = buildHtml(tdiv):
    ul:
      discard
  doDiff(a, b, "pkDetach li A", "pkRemove nil",
               "pkDetach li B", "pkRemove nil",
               "pkDetach li C", "pkRemove nil")

proc testDeleteMiddle() =
  let a = buildHtml(tdiv):
    ul:
      li:
        tdiv: text "A"
      li:
        tdiv: text "B"
      li:
        tdiv: text "C"
      li:
        tdiv: text "D"
      li:
        tdiv: text "E"
      li:
        tdiv: text "F"
      li:
        tdiv: text "G"
      li:
        button:
          tdiv: text "H"
  let b = buildHtml(tdiv):
    ul:
      li:
        tdiv: text "A"
      li:
        tdiv: text "B"
      li:
        tdiv: text "C"
      li:
        tdiv: text "D"
      li:
        tdiv: text "E"
      li:
        tdiv: text "F"
      li:
        button:
          tdiv: text "H"
  doDiff(a, b, "pkDetach li div G", "pkRemove nil")

proc createEntry(id: cstring): VNode =
  result = buildHtml():
    button(id="" & id):
      text id

proc createEntries(entries: seq[cstring]): VNode =
  result = buildHtml(tdiv()):
    ul(id="ul"):
      for e in entries:
        createEntry(e)
    for r in entries:
      tdiv:
        text r

proc testWild() =
  var entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring"7", cstring("5")]
  let a = createEntries(entries)
  entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5")]
  let b = createEntries(entries)
  doDiff(a, b, "pkDetach button 7", "pkRemove nil", "pkDetach div 7", "pkRemove nil")

proc testWildInsert() =
  var entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5")]
  let a = createEntries(entries)
  entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring"7", cstring("5")]
  let b = createEntries(entries)
  doDiff(a, b, "pkInsertBefore button 7", "pkInsertBefore div 7")

proc newStubEventNode(): Node {.importcpp: "({addEventListener: function(){}, removeEventListener: function(){}})", nodecl.}
  ## A minimal event target: the nodejs DOM emulation (kdom_impl) has no
  ## real addEventListener, so the event path stubs its own node.

proc testEventBookkeepingDoesNotLeak() =
  ## Regression test: re-merging events on a redrawn node must not
  ## accumulate handler tuples in the DOM node's `karaxEvents` array —
  ## every leaked tuple's closure retains its render generation's whole
  ## VNode tree (memory), and the removal loop in `removeAllEventHandlers`
  ## walks the array on every redraw (CPU). `updateElement` calls
  ## `mergeEvents` for every visited event-carrying node, so one entry
  ## leaked per redraw per node.
  let handler: EventHandler = proc (ev: Event; n: VNode) = discard
  proc gen(): VNode =
    result = buildHtml(button):
      text "b"
    result.addEventListener(EventKind.onclick, handler)
  var a = gen()
  a.dom = newStubEventNode()
  applyEvents(a)              # the initial attach, as toDom does
  for i in 1..10:
    let b = gen()
    mergeEvents(b, a, kxi)    # what updateElement does on every redraw
  let leaked = a.dom.karaxEvents.len
  if leaked > 2:
    echo "event bookkeeping leaks: karaxEvents grew to ", leaked,
         " entries after 10 event re-merges (expected to stay at 1)"
    inc err

kxi = KaraxInstance(rootId: cstring"ROOT", renderer: proc (data: RouterData): VNode = discard,
                    byId: newJDict[cstring, VNode]())

testAppend()
testInsert()
testInsert2()
testDelete()
testWild()
testWildInsert()
testDeleteMiddle()
testEventBookkeepingDoesNotLeak()
if err == 0:
  echo "Success"
else:
  quit 1
