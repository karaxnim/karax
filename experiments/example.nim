
import vdom, components, karax, karaxdsl, jdict, jstrutils, dom

var
  images: seq[cstring] = @[cstring"a", "b", "c", "d"]

proc carousel*(key: VKey): VNode {.component.} =
  state:
    var counter: int = 0
    var cntdown: int = 5
    var timer: Timeout = nil

  proc docount() =
    cntdown = cntdown - 1
    if cntdown == 0:
      counter = (counter + 1) mod images.len
      cntdown = 5
    else:
      timer = setTimeout(docount, 30)
    redraw()

  proc next(ev: Event; n: VNode) =
    if timer != nil:
      clearTimeout(timer)
    timer = setTimeout(docount, 30)

  result = buildHtml(tdiv(key=key)):
    text images[counter]
    button(onclick = next):
      text "Next"
    if cntdown != 5:
      text &cntdown

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
