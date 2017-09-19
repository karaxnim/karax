import vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils

type TextInput* = ref object of VComponent
  value: cstring
  isActive: bool

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
    echo "flip! ", self.isActive, " id: ", self.debugId, " version ", self.version
    markDirty(self)

  result = buildHtml(tdiv(style=style)):
    input(style=inputStyle, value=self.value, onblur=flip, onfocus=flip,
                    events=self.events)

proc update(current, next: VComponent) =
  let current = TextInput(current)
  let next = TextInput(next)
  current.value = next.value
  current.key = next.key

proc changed(current, next: VComponent): bool = true

proc newTextInput*(style: VStyle = VStyle(); key: cstring;
                   value = cstring""): TextInput =
  result = newComponent(TextInput, render, changed=changed, updated=update)
  result.style = style
  result.value = value
  #result.key = key

when false:
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
  errmsg = cstring""

proc renderPerson(text: cstring, index: int): VNode =
  result = buildHtml(tdiv):
    newTextInput(VStyle(), &index, text):
      proc onkeyuplater(ev: Event; n: VNode) =
        let v = n.value
        if v.len > 0:
          persons[index] = v
          errmsg = ""
        else:
          errmsg = "name must not be empty"
    button:
      proc onclick(ev: Event; n: VNode) =
        persons.delete(index)
        errmsg = ""
        echo persons
      text "(x)"


proc createDom(): VNode =
  result = buildHtml(tdiv):
    tdiv:
      for index, text in persons.pairs:
        renderPerson(text, index)
    tdiv:
      newTextInput(VStyle(), &persons.len, ""):
        proc onkeyupenter(ev: Event; n: VNode) =
          let v = n.value
          if v.len > 0:
            persons.add v
            errmsg = ""
          else:
            errmsg = "name must not be empty"
    tdiv:
      text errmsg

setRenderer createDom
