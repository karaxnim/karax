var
  linkCounter: int

proc link*(id: int): VNode =
  result = newVNode(VNodeKind.anchor)
  result.setAttr("href", "#")
  inc linkCounter
  result.setAttr("id", $linkCounter & ":" & $id)

proc link*(action: EventHandler): VNode =
  result = newVNode(VNodeKind.anchor)
  result.setAttr("href", "#")
  result.setOnclick action

when false:
  proc button*(caption: cstring; action: EventHandler; disabled=false): VNode =
    result = newVNode(VNodeKind.button)
    result.add text(caption)
    if action != nil:
      result.setOnClick action
    if disabled:
      result.setAttr("disabled", "true")

proc select*(choices: openarray[cstring]): VNode =
  result = newVNode(VNodeKind.select)
  var i = 0
  for c in choices:
    result.add tree(VNodeKind.option, [(cstring"value", toCstr(i))], text(c))
    inc i

proc select*(choices: openarray[(int, cstring)]): VNode =
  result = newVNode(VNodeKind.select)
  for c in choices:
    result.add tree(VNodeKind.option, [(cstring"value", toCstr(c[0]))], text(c[1]))

var radioCounter: int

proc radio*(choices: openarray[(int, cstring)]): VNode =
  result = newVNode(VNodeKind.fieldset)
  var i = 0
  inc radioCounter
  for c in choices:
    let id = cstring"radio_" & c[1] & toCstr(i)
    var kid = tree(VNodeKind.input, [(cstring"type", cstring"radio"),
      (cstring"id", id), (cstring"name", cstring"radio" & toCStr(radioCounter)),
      (cstring"value", toCStr(c[0]))])
    if i == 0:
      kid.setAttr(cstring"checked", cstring"checked")
    var lab = tree(VNodeKind.label, [(cstring"for", id)], text(c[1]))
    kid.add lab
    result.add kid
    inc i

proc tag*(kind: VNodeKind; id=cstring(nil), class=cstring(nil)): VNode =
  result = newVNode(kind)
  result.id = id
  result.class = class

proc tdiv*(id=cstring(nil), class=cstring(nil)): VNode = tag(VNodeKind.tdiv, id, class)
proc span*(id=cstring(nil), class=cstring(nil)): VNode = tag(VNodeKind.span, id, class)

proc valueAsInt*(e: Node): int = parseInt(e.value)

proc th*(s: cstring): VNode =
  result = newVNode(VNodeKind.th)
  result.add text(s)

proc td*(s: string): VNode =
  result = newVNode(VNodeKind.td)
  result.add text(s)

proc td*(s: VNode): VNode =
  result = newVNode(VNodeKind.td)
  result.add s

proc td*(class: cstring; s: VNode): VNode =
  result = newVNode(VNodeKind.td)
  result.add s
  result.class = class

proc table*(class=cstring(nil), kids: varargs[VNode]): VNode =
  result = tag(VNodeKind.table, nil, class)
  for k in kids: result.add k

proc tr*(kids: varargs[VNode]): VNode =
  result = newVNode(VNodeKind.tr)
  for k in kids:
    if k.kind in {VNodeKind.td, VNodeKind.th}:
      result.add k
    else:
      result.add td(k)

proc suffix*(s, prefix: cstring): cstring =
  if s.startsWith(prefix):
    result = s.substr(prefix.len)
  else:
    kout(cstring"bug! " & s & cstring" does not start with " & prefix)

proc suffixAsInt*(s, prefix: cstring): int = parseInt(suffix(s, prefix))

#proc ceil(f: float): int {.importc: "Math.ceil", nodecl.}

proc realtimeInput*(val: cstring; action: EventHandler): VNode =
  var timer: Timeout
  proc onkeyup(ev: Event; n: VNode) =
    proc wrapper() = keyeventBody()

    if timer != nil: clearTimeout(timer)
    timer = setTimeout(wrapper, 400)
  result = tree(VNodeKind.input, [(cstring"type", cstring"text")])
  result.value = val
  result.addEventListener(EventKind.onkeyup, onkeyup)

proc enterInput*(id, val: cstring; action: EventHandler): VNode =
  proc onkeyup(ev: Event; n: VNode) =
    if ev.keyCode == 13: keyeventBody()

  result = tree(VNodeKind.input, [(cstring"type", cstring"text")])
  result.id = id
  result.value = val
  result.addEventListener(EventKind.onkeyup, onkeyup)

proc setOnEnter*(n: VNode; action: EventHandler) =
  proc onkeyup(ev: Event; n: VNode) =
    if ev.keyCode == 13: keyeventBody()
  n.addEventListener(EventKind.onkeyup, onkeyup)

proc setOnscroll*(action: proc(min, max: VKey; diff: int)) =
  var oldY = window.pageYOffset

  proc wrapper(ev: Event) =
    let dir = window.pageYOffset - oldY
    if dir == 0: return

    var a = VKey high(int)
    var b = VKey 0
    var h, count: int
    document.visibleKeys(a, b, h, count)
    let avgh = h / count
    let diff = toInt(dir.float / avgh)
    if diff != 0:
      oldY = window.pageYOffset
      action(a, b, diff)
      redraw()

  document.addEventListener("scroll", wrapper)

when false:
  var plugins {.exportc.}: seq[(string, proc())] = @[]

  proc onInput(val: cstring) =
    kout val
    if val == "dyn":
    kout(plugins.len)
    if plugins.len > 0:
      plugins[0][1]()

var
  images: seq[cstring] = @[cstring"a", "b", "c", "d"]

proc carousel*(): VNode =
  var currentIndex = 0

  proc next(ev: Event; n: VNode) =
    currentIndex = (currentIndex + 1) mod images.len

  proc prev(ev: Event; n: VNode) =
    currentIndex = (currentIndex - 1) mod images.len

  result = buildHtml(tdiv):
    text images[currentIndex]
    button(onclick = next):
      text "Next"
    button(onclick = prev):
      text "Previous"

#proc targetElem*(e: Event): Element = cast[Element](e.target)

#proc getElementsByClassName*(cls: cstring): seq[Element] {.importc:
#  "document.getElementsByClassName", nodecl.}
#proc textContent(e: Node): cstring {.
#  importcpp: "#.textContent", nodecl.}

proc isElementInViewport(el: Node; h: var int): bool =
  let rect = el.getBoundingClientRect()
  h = rect.bottom - rect.top
  result = rect.top >= 0 and rect.left >= 0 and
           rect.bottom <= clientHeight() and
           rect.right <= clientWidth()

proc visibleKeys(e: Node; a, b: var VKey; h, count: var int) =
  # we only care about nodes that have a key:
  var hh = 0
  # do not recurse if there is a 'key' field already:
  if e.key >= 0:
    if isElementInViewport(e, hh):
      inc count
      inc h, hh
      a = min(a, e.key)
      b = max(b, e.key)
  else:
    for i in 0..<e.len:
      visibleKeys(e[i], a, b, h, count)

template toState(x): untyped = "state" & x
proc accessState(sv: string): NimNode {.compileTime.} =
  newTree(nnkBracketExpr, newIdentNode(sv), newIdentNode("key"))

proc stateDecl(n: NimNode; names: TableRef[string, bool]; decl, init: NimNode) =
  case n.kind
  of nnkVarSection, nnkLetSection:
    for c in n:
      expectKind c, nnkIdentDefs
      let typ = c[^2]
      let val = c[^1]
      let usedType = if typ.kind != nnkEmpty: typ else: val
      if usedType.kind == nnkEmpty:
        error("cannot determine the variable's type", c)
      for i in 0 .. c.len-3:
        let v = $c[i]
        let sv = toState v
        decl.add quote do:
          var `sv` = newJDict[VKey, `usedType`]()
        if val.kind != nnkEmpty:
          init.add newTree(nnkAsgn, accessState(sv), val)
        names[v] = true
  of nnkStmtList, nnkStmtListExpr:
    for x in n: stateDecl(x, names, decl, init)
  of nnkDo:
    stateDecl(n.body, names, decl, init)
  of nnkCommentStmt: discard
  else:
    error("invalid 'state' declaration", n)

proc doState(n: NimNode; names: TableRef[string, bool];
             decl, init: NimNode): NimNode =
  result = n
  case n.kind
  of nnkCallKinds:
    # handle 'state' declaration and remove it from the AST:
    if n.len == 2 and repr(n[0]) == "state":
      stateDecl(n[1], names, decl, init)
      result = newTree(nnkEmpty)
  of nnkSym, nnkIdent:
    let v = $n
    if v in names:
      let sv = toState v
      result = accessState(sv)
  else:
    for i in 0..<n.len:
      result[i] = doState(n[i], names, decl, init)
