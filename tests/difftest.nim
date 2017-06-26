
include "../src/karax"
import "../src/karaxdsl"

proc hasDom(n: Vnode) =
  if n.kind in {VNodeKind.component, VNodeKind.vthunk, VNodeKind.dthunk}:
    discard
  else:
    doAssert n.dom != nil
    for i in 0..<n.len: hasDom(n[i])

proc doDiff(a, b: VNode) =
  var patches = newJSeq[Patch]()
  echo diff(b, a, nil, vnodeToDom(a, kxi), patches)
  for i in 0..<patches.len:
    echo patches[i]
  #hasDom(kxi.currentTree)

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
  doDiff(a, b)

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
  doDiff(a, b)

proc testDelete() =
  let a = buildHtml(tdiv):
    ul:
      li: text "A"
      li: text "B"
      li: text "C"
  let b = buildHtml(tdiv):
    ul:
      discard
  doDiff(a, b)

kxi = KaraxInstance(rootId: cstring"ROOT", renderer: proc (): VNode = discard)

testAppend()
testInsert()
testDelete()
