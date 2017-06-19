
import vdom, vstyles, karax, karaxdsl, jdict, jstrutils, kdom

type
  Carousel = ref object of VComponent
    counter: int
    cntdown, myid: int
    timer: TimeOut
    list: seq[cstring]
    change: bool

const ticksUntilChange = 5

var
  images: seq[cstring] = @[cstring"a", "b", "c", "d"]

proc render(x: VComponent): VNode =
  let self = Carousel(x)

  proc docount() =
    dec self.cntdown
    if self.cntdown == 0:
      self.counter = (self.counter + 1) mod self.list.len
      self.cntdown = ticksUntilChange
    else:
      self.timer = setTimeout(docount, 30)
    self.change = true
    redraw()

  proc onclick(ev: Event; n: VNode) =
    self.change = false
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
      text "This changes its color." & &self.myid
    if self.cntdown != ticksUntilChange:
      text &self.cntdown

var gid: int

proc carousel(): Carousel =
  result = Carousel(kind: VNodeKind.component, key: -1)
  result.render = render
  result.list = images
  result.changed = proc (c: VComponent): bool =
    let x = Carousel(c)
    result = x.change
  result.cntdown = ticksUntilChange
  result.myid = gid
  inc gid
  #result.onAttach = proc (_: VComponent) =
  #  result.cntdown = ticksUntilChange
  #  kout cstring"attached!"

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
