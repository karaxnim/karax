
import vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils, reactive

proc textInput*(text: RString; focus: RBool): VNode {.track.} =
  proc onFlip(ev: Event; target: VNode) =
    focus <- not focus.value

  proc onKeyupEnter(ev: Event; target: VNode) =
    text <- target.value

  proc onkeyup(ev: Event; n: VNode) =
    # keep displayValue up to date, but do not tell the client yet!
    text.value = n.value

  result = buildHtml(input(`type`="text",
    value=text.value, onblur=onFlip, onfocus=onFlip,
    onkeyupenter=onkeyupenter, onkeyup=onkeyup, setFocus=focus.value))

var
  errmsg = rstr("")

makeReactive:
  type
    User = ref object
      firstname, lastname: cstring
      selected: bool

var gu = newRSeq(@[ (User(rawFirstname: "Some", rawLastname: "Body")),
                    (User(rawFirstname: "Some", rawLastname: "One")),
                    (User(rawFirstname: "Some", rawLastname: "Two"))])
var prevSelected: User = nil #newReactive[User](nil)

proc unselect() =
  if prevSelected != nil:
    prevSelected.selected = false
    prevSelected = nil

proc select(u: User) =
  unselect()
  u.selected = true
  prevSelected = u

proc toUI*(isFirstname: bool): RString =
  result = RString()
  result.subscribe proc (v: cstring) =
    if v.len > 0:
      let p = prevSelected #selected.value
      if p != nil:
        if isFirstName:
          p.firstname = v
        else:
          p.lastname = v
        unselect()
      errmsg <- ""
    else:
      errmsg <- "name must not be empty"

var inpFirstname = toUI(true)
var inpLastname = toUI(false)

proc adaptFocus(def = false): RBool =
  result = RBool()
  result.value = def
  when false:
    result.subscribe proc (hasFocus: bool) =
      if not hasFocus:
        unselect()

var focusA = adaptFocus()
var focusB = adaptFocus()

proc styler(): VStyle =
  result = style(
    (StyleAttr.position, cstring"relative"),
    (StyleAttr.paddingLeft, cstring"10px"),
    (StyleAttr.paddingRight, cstring"5px"),
    (StyleAttr.height, cstring"30px"),
    (StyleAttr.lineHeight, cstring"30px"),
    (StyleAttr.border, cstring"solid 8px " & (if focusA.value: cstring"red" else: cstring"black")),
    (StyleAttr.fontSize, cstring"12px"),
    (StyleAttr.fontWeight, cstring"600")
  )

var clicks = 0

proc renderUser(u: User): VNode {.track.} =
  result = buildHtml(tdiv):
    if u.selected:
      inpFirstname <- u.firstname
      tdiv:
        textInput inpFirstname, focusA
      inpLastname <- u.lastname
      tdiv:
        textInput inpLastname, focusB
    else:
      button:
        text "..."
        proc onclick(ev: Event; n: VNode) =
          select(u)
      text u.firstname & " " & u.lastname
    button:
      text "(x)"
      proc onclick(ev: Event; n: VNode) =
        gu.deleteElem(u)

proc main(gu: RSeq[User]): VNode =
  result = buildHtml(tdiv):
    tdiv:
      button:
        text "Add User"
        proc onclick(ev: Event; n: VNode) =
          inc clicks
          gu.add User(rawFirstname: "Added", rawLastname: &clicks)
    tdiv:
      text errmsg
    vmapIt(gu, tdiv, renderUser(it))

proc init(): VNode = main(gu)

setInitializer(init)
