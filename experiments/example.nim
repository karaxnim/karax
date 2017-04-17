
import vdom, components, karax, karaxdsl, jdict, jstrutils

var
  images: seq[cstring] = @[cstring"a", "b", "c", "d"]

proc carousel*(key: VKey): VNode {.component.} =
  state:
    var counter = 0

  proc next(ev: Event; n: VNode) =
    counter = (counter + 1) mod images.len

  result = buildHtml(tdiv(key=key)):
    text images[counter]
    button(onclick = next):
      text "Next"

proc createDom(): VNode =
  result = buildHtml(table):
    tr:
      td:
        carousel(0)
      td:
        carousel(1)
    tr:
      td:
        carousel(2)
      td:
        carousel(3)

setRenderer createDom
