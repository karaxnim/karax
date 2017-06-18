
import vdom, vstyles, karax, karaxdsl, jdict, jstrutils, kdom

type
  Car = ref object of VComponent
    counter: int
    cntdown: int
    timer: TimeOut
    list: seq[cstring]
    change: bool
    onclick: proc (ev: Event; n: VNode)

const ticksUntilChange = 5

proc car*(images: seq[cstring]): Car =
  new(result)
  result.list = images
  result.cntdown = ticksUntilChange

  proc docount() =
    dec result.cntdown
    if result.cntdown == 0:
      result.counter = (result.counter + 1) mod result.list.len
      result.cntdown = ticksUntilChange
    else:
      result.timer = setTimeout(docount, 30)
    result.change = true
    redraw()

  result.onclick = proc (ev: Event; n: VNode) =
    result.change = false
    if result.timer != nil:
      clearTimeout(result.timer)
    result.timer = setTimeout(docount, 30)

method changed(c: Car): bool = true

var
  images: seq[cstring] = @[cstring"a", "b", "c", "d"]

proc carousel*(): VNode =
  let c = car(images)
  let col =
    case c.counter
    of 0: cstring"#4d4d4d"
    of 1: cstring"#ff00ff"
    of 2: cstring"#00ffff"
    of 3: cstring"#ffff00"
    else: cstring"red"
  result = buildHtml(tdiv(nref = c)):
    text images[c.counter]
    button(onclick = c.onclick):
      text "Next"
    tdiv(style = style(StyleAttr.color, col)):
      text "This changes its color."
    if c.cntdown != ticksUntilChange:
      text &c.cntdown

proc createDom(): VNode =
  result = buildHtml(table):
    tr:
      td:
        carousel()
      td:
        carousel()
    tr:
      td:
        carousel()
      td:
        carousel()

setRenderer createDom
