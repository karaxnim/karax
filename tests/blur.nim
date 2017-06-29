import vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils

type TextInput* = ref object of VComponent
  value: cstring
  isActive: bool
  onchange: proc (value: cstring)

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
    kout cstring"onflip", n.value
    markDirty(self)

  proc onchanged(ev: Event; n: VNode) =
    if self.onchange != nil and self.value != n.value:
      self.onchange n.value
      self.value = n.value

  result = buildHtml(tdiv(style=style)):
    input(style=inputStyle, value=self.value, onblur=flip, onfocus=flip, onkeyup=onchanged)

proc setValue(x: TextInput; value: cstring) =
  x.value = value
  markDirty(x)

proc newTextInput*(style: VStyle = VStyle(); value: cstring = cstring"",
                   onchange: proc(v: cstring) = nil): TextInput =
  result = newComponent(TextInput, render)
  result.style = style
  result.value = value
  result.onchange = onchange

type
  Combined = ref object of VComponent
    a, b: TextInput

proc renderComb(self: VComponent): VNode =
  let self = Combined(self)

  proc bu(ev: Event; n: VNode) =
    self.a.value = ""
    self.b.value = ""
    markDirty(self.a)
    markDirty(self.b)

  result = buildHtml(tdiv(style=self.style)):
    self.a
    self.b
    button(onclick=bu):
      text "reset"

proc changed(self: VComponent): bool =
  let self = Combined(self)
  result = self.a.changedImpl(self.a) or self.b.changedImpl(self.b)

proc newCombined*(style: VStyle = VStyle()): Combined =
  result = newComponent(Combined, renderComb, changed=changed)
  result.a = newTextInput(style, "AAA")
  result.b = newTextInput(style, "BBB")


var
  persons: seq[cstring] = @[cstring"Karax", "Abathur", "Fenix"]
  selected = -1
  errmsg = cstring""
  ti = newTextInput(VStyle(), "", proc (v: cstring) =
    if v.len > 0:
      if selected >= 0: persons[selected] = v
      errmsg = ""
    else:
      errmsg = "name must not be empty"
  )

proc renderPerson(text: cstring, index: int): VNode =
  proc select(ev: Event, n: VNode) =
    selected = index
    ti.setValue(persons[selected])

  result = buildHtml():
    tdiv(onClick=select):
      text text

proc createDom(): VNode =
  result = buildHtml(tdiv):
    tdiv:
      for index, text in persons.pairs:
        renderPerson(text, index)
    tdiv:
      ti
    tdiv:
      text errmsg

setRenderer createDom
