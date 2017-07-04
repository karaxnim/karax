
include "../src/karax"
import "../src/karaxdsl"

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
  discard diff(b, a, nil, vnodeToDom(a, kxi), kxi)
  for i in 0..<kxi.patchLen:
    let p = $kxi.patches[i].k & " " & shortRepr(kxi.patches[i].n)
    if i >= expected.len:
      echo "patches differ; expected nothing but got: ", p
      inc err
    elif p != expected[i]:
      echo "patches differ; expected ", expected[i], " but got: ", p
      inc err
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
      li: text "C"
  doDiff(a, b, "pkAppend li C")

proc testInsert() =
  let a = buildHtml(tdiv):
    ul:
      li: text "A"
      li: text "C"
  let b = buildHtml(tdiv):
    ul:
      li: text "A"
      li: text "B"
      li: text "C"
  doDiff(a, b, "pkInsertBefore li B")

proc testInsert2() =
  let a = buildHtml(tdiv):
    tdiv:
      tdiv:
        ul:
          li: text "A"
          li: text "D"
  let b = buildHtml(tdiv):
    tdiv:
      tdiv:
        ul:
          li: text "A"
          li: text "B"
          li: text "C"
          li: text "D"
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

kxi = KaraxInstance(rootId: cstring"ROOT", renderer: proc (): VNode = discard)

testAppend()
testInsert()
testInsert2()
testDelete()
if err == 0:
  echo "Success"
else:
  quit 1
