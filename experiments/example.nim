
import vdom, vstyles, components, karax, karaxdsl, jdict, jstrutils, kdom

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

  let col =
    case counter
    of 0: cstring"#4d4d4d"
    of 1: cstring"#ff00ff"
    of 2: cstring"#00ffff"
    of 3: cstring"#ffff00"
    else: cstring"red"

  result = buildHtml(tdiv(key=key)):
    text images[counter]
    button(onclick = next):
      text "Next"
    tdiv(style = style(StyleAttr.color, col)):
      text "This changes its color."
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
