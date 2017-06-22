import vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils

type TextInput* = ref object of VComponent
  value: cstring
  isActive: bool

var renderId: int
proc render(x: VComponent): VNode =
  let self = TextInput(x)

  let style = style(
    (StyleAttr.position, cstring"relative"),
    (StyleAttr.paddingLeft, cstring"10px"),
    (StyleAttr.paddingRight, cstring"5px"),
    (StyleAttr.height, cstring"30px"),
    (StyleAttr.lineHeight, cstring"30px"),
    (StyleAttr.border, cstring"solid 1px " & (if self.isActive: cstring"red" else: cstring"black")),
    (StyleAttr.fontSize, cstring"12px"),
    (StyleAttr.fontWeight, cstring"600")
  ).merge(self.style)

  let inputStyle = style.merge(style(
    (StyleAttr.color, cstring"inherit"),
    (StyleAttr.fontSize, cstring"inherit"),
    (StyleAttr.fontWeight, cstring"inherit"),
    (StyleAttr.fontFamily, cstring"inherit"),
    (StyleAttr.position, cstring"absolute"),
    (StyleAttr.top, cstring"0"),
    (StyleAttr.left, cstring"0"),
    (StyleAttr.height, cstring"100%"),
    (StyleAttr.width, cstring"100%"),
    (StyleAttr.border, cstring"none"),
    (StyleAttr.backgroundColor, cstring"transparent"),
  ))

  proc flip(ev: Event; n: VNode) =
    self.isActive = not self.isActive
    markDirty(self)

  kout cstring"rendering ", self.myid
  inc renderId
  result = buildHtml(tdiv(style=style, key=renderId)):
    input(style=inputStyle, value=self.value, onblur=flip, onfocus=flip,
          key=renderId)

var gid = 0
proc newTextInput*(style: VStyle = VStyle(); value: cstring = cstring""): TextInput =
  result = newComponent(TextInput, render)
  result.style = style
  result.value = value
  inc gid
  result.myid = gid

proc createDom(): VNode =
  result = buildHtml(tdiv):
    newTextInput(value=cstring"test")

setRenderer createDom
