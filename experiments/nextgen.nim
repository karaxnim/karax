
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

type
  User = ref object of ReactiveBase
    firstname, lastname: cstring
    selected: bool

var gu = newRSeq(@[ (User(firstname: "Some", lastname: "Body")),
                    (User(firstname: "Some", lastname: "One")),
                    (User(firstname: "Some", lastname: "Two"))])
var prevSelected: User = nil #newReactive[User](nil)

proc unselect() =
  if prevSelected != nil:
    prevSelected.selected = false
    notifyObservers(prevSelected)
    prevSelected = nil

proc select(u: User) =
  unselect()
  u.selected = true
  notifyObservers(u)
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
        notifyObservers(p)
        unselect()
      errmsg <- ""
    else:
      errmsg <- "name must not be empty"

var firstname = toUI(true)
var lastname = toUI(false)

proc adaptFocus(def = false): RBool =
  result = RBool()
  result.value = def
  when false:
    result.subscribe proc (hasFocus: bool) =
      if not hasFocus:
        unselect()
        firstname.notifyObservers()
        lastname.notifyObservers()

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

discard """
  # Text gets a *reactive* string in the first place!
  # Text can register and knows how to update itself!
  proc toReact(): RString =
    observe(u):
      u.firstname & u.lastname

  let t = text(u.firstname & " " & u.lastname)
  observe(u, t.update(u.firstname & " " & u.lastname))
  t

template observe(s: cstring): RString =
  let tmp = rstr(s)
  u.subscribeSelf proc () =
    tmp <- s
  temp
"""

proc renderUser(u: User): VNode {.track.} =
  result = buildHtml(tdiv):
    if u.selected:
      firstname <- u.firstname
      tdiv:
        textInput firstname, focusA
      lastname <- u.lastname
      tdiv:
        textInput lastname, focusB
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

template vmap(x: RSeq; elem, f: untyped): VNode =
  let tmp = buildHtml(elem):
    for i in 0..<len(x):
      f(x[i])
  doTrackResize(x, tmp, f(x[pos]))
  tmp

template vmapIt(x: RSeq; elem, call: untyped): VNode =
  var it {.inject}: type(x[0])
  let tmp = buildHtml(elem):
    for i in 0..<len(x):
      it = x[i]
      call
  doTrackResize(x, tmp, call)
  tmp

proc hasNativeNode(parent, x: Node): bool =
  if parent == x: return true
  for i in 0..<parent.len:
    if hasNativeNode(parent[i], x): return true

proc text*(s: RString): VNode =
  result = text(s.value)
  s.subscribe proc(v: cstring) =
    if result.dom != nil: result.dom.nodeValue = v

proc main(gu: RSeq[User]): VNode =
  result = buildHtml(tdiv):
    tdiv:
      button:
        text "Add User"
        proc onclick(ev: Event; n: VNode) =
          inc clicks
          gu.add User(firstname: "Added", lastname: &clicks)
    tdiv:
      text errmsg
    vmapIt(gu, tdiv, renderUser(it))

proc init(): VNode = main(gu)

setInitializer(init)
