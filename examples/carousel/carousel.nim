## This demo shows how you can develop your own stateful components with Karax.

import vdom, vstyles, karax, karaxdsl, jdict, jstrutils, kdom

type
  Carousel = ref object of VComponent
    counter: int
    cntdown: int
    timer: TimeOut
    list: seq[cstring]

const ticksUntilChange = 5

var
  images: seq[cstring] = @[cstring"a", "b", "c", "d"]

var 
  refA:Carousel
  refB:Carousel
  refC:Carousel
  refD:Carousel
proc render(x: VComponent): VNode =
  let self = Carousel(x)

  proc docount() =
    dec self.cntdown
    if self.cntdown == 0:
      self.counter = (self.counter + 1) mod self.list.len
      self.cntdown = ticksUntilChange
    else:
      self.timer = setTimeout(docount, 30)
    markDirty(self)
    redraw()

  proc onclick(ev: Event; n: VNode) =
    if self.timer != nil:
      clearTimeout(self.timer)
    self.timer = setTimeout(docount, 30)

  let col =
    case self.counter
    of 0: cstring"#4d4d4d"
    of 1: cstring"#ff00ff"
    of 2: cstring"#00ffff"
    of 3: cstring"#ffff00"
    else: cstring"red"
  result = buildHtml(tdiv()):
    text self.list[self.counter]
    button(onclick = onclick):
      text "Next"
    tdiv(style = style(StyleAttr.color, col)):
      text "This changes its color."
    if self.cntdown != ticksUntilChange:
      text &self.cntdown

proc carousel(nref:var Carousel): Carousel =
  if nref == nil:
    nref = newComponent(Carousel, render)
    nref.list = images
    nref.cntdown = ticksUntilChange
    return nref
  else:
    return nref

proc createDom(): VNode =
  result = buildHtml(table):
    tr:
      td:
        carousel(nref=refA)
      td:
        carousel(nref=refB)
    tr:
      td:
        carousel(nref=refC)
      td:
        carousel(nref=refD)

setRenderer createDom
