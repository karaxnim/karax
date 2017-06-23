
include "../src/karax"
import "../src/karaxdsl"

proc doDiff(a, b: VNode) =
  var patches: seq[Patch] = @[]
  echo diff(nil, vnodeToDom(a, kxi), b, a, patches, kxi)
  echo patches

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

kxi = KaraxInstance(rootId: cstring"ROOT", renderer: proc (): VNode = discard)

#testAppend()
testInsert()
