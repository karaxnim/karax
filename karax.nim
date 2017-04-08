# Simple lib to write JS UIs

import dom, vdom, jstrutils

export dom.Element, dom.Event, dom.cloneNode, dom

proc kout*[T](x: T) {.importc: "console.log", varargs.}
  ## the preferred way of debugging karax applications.

proc id*(e: Node): cstring {.importcpp: "#.id", nodecl.}
proc `id=`*(e: Node; x: cstring) {.importcpp: "#.id = #", nodecl.}
proc class*(e: Node): cstring {.importcpp: "#.className", nodecl.}
proc `class=`*(e: Node; v: cstring) {.importcpp: "#.className = #", nodecl.}

proc value*(e: Element): cstring {.importcpp: "#.value", nodecl.}
proc `value=`*(e: Element; v: cstring) {.importcpp: "#.value = #", nodecl.}

proc `disabled=`*(e: Element; v: bool) {.importcpp: "#.disabled = #", nodecl.}

proc getElementsByClass*(e: Element; name: cstring): seq[Element] {.
  importcpp: "#.getElementsByClassName(#)", nodecl.}

type
  Timeout* = ref object

var
  document* {.importc.}: Document
  toFocus: Element
  toFocusV: VNode

proc setFocus*(n: VNode) =
  toFocusV = n

proc vnodeToDom(n: VNode): Element =
  if n.kind == VNodeKind.text:
    result = cast[Element](document.createTextNode(n.text))
  else:
    result = document.createElement(toTag[n.kind])
    for k in n:
      appendChild(result, vnodeToDom(k))
    # text is mapped to 'value':
    if n.text != nil:
      result.value = n.text
  if n.id != nil:
    result.id = n.id
  if n.class != nil:
    result.class = n.class
  for k, v in attrs(n):
    if v != nil:
      result.setAttribute(k, v)
  let myn = n
  for e, h in items(n.events):
    proc wrapper(): proc (ev: Event) =
      let hh = h
      result = proc (ev: Event) =
        assert myn != nil
        hh(ev, myn)
    result.addEventListener(toEventName[e], wrapper())
  if n == toFocusV and toFocus.isNil:
    toFocus = result

proc same(n: VNode, e: Element): bool =
  if toTag[n.kind] == e.nodename:
    result = true
    if n.kind != VNodeKind.text:
      if e.childNodes.len != n.len: return false
      for i in 0 ..< n.len:
        if not same(n[i], cast[Element](e.childNodes[i])): return false

var
  dorender: proc (): VNode {.closure.}
  drawTimeout: Timeout
  currentTree: VNode

proc setRenderer*(renderer: proc (): VNode) =
  dorender = renderer

proc setTimeout*(action: proc(); ms: int): Timeout {.importc, nodecl.}
proc clearTimeout*(t: Timeout) {.importc, nodecl.}
#proc targetElem*(e: Event): Element = cast[Element](e.target)

proc getElementById*(id: cstring): Element {.importc: "document.getElementById", nodecl.}

#proc getElementsByClassName*(cls: cstring): seq[Element] {.importc:
#  "document.getElementsByClassName", nodecl.}

proc textContent(e: Element): cstring {.
  importcpp: "#.textContent", nodecl.}

proc replaceById(id: cstring; newTree: Node) =
  let x = document.getElementById(id)
  x.parentNode.replaceChild(newTree, x)
  #newTree.id = id

proc equals(a, b: VNode): bool =
  if a.kind != b.kind: return false
  if a.id != b.id: return false
  if a.kind == VNodeKind.text:
    if a.text != b.text: return false
  if not sameAttrs(a, b): return false
  if a.class != b.class: return false
  # XXX test event listeners here?
  # --> maybe give nodes a hash?
  when false:
    # this needs to be done differently in a virtual DOM:
    if a.class != b.class:
      # style differences are updated in place and we pretend
      # it's still the same node
      a.class = b.class
  return true

proc equalsTree(a, b : VNode): bool =
  # kout cstring("equalsTree: (" & $a.kind & " = " & a.id & ") -> (" &
  #     $b.kind & " = " & b.id & ")")
  # assert a != nil and b != nil
  # kout cstring("equalsTree")
  if not equals(a, b):
    return false
  else:
    if len(a) != len(b):
      return false
    for i in 0..len(a)-1:
      if not equalsTree(a[i], b[i]):
        return false
    return true

proc updateElement(parent, current: Node, newNode, oldNode: VNode) =
  #kout cstring("updateElement: (" & current.nodeName & " = " & current.id & ")")
  if not equals(newNode, oldNode):
    let n = vnodeToDom(newNode)
    if parent == nil:
      replaceById("ROOT", n)
    else:
      parent.replaceChild(n, current)
    kout cstring("---- replaceChild")
    #kout cstring("ReplaceChild: (" & current.nodeName & " = " & newNode.id & ") -> (" &
    #  n.nodeName & " = " & oldNode.id & ")")
  elif newNode.kind != VNodeKind.text:
    let newLength = newNode.len
    var oldLength = oldNode.len
    let minLength = min(newLength, oldLength)
    assert oldNode.kind == newNode.kind
    when false:
      if current.nodeName != toTag[oldNode.kind]:
        kout current.nodeName
        kout toTag[oldNode.kind]
        assert false

    var commonPrefix = 0
    while commonPrefix < minLength and equalsTree(newNode[commonPrefix], oldNode[commonPrefix]):
      inc commonPrefix
    
    var oldPos = oldLength - 1
    var newPos = newLength - 1
    while oldPos >= commonPrefix and newPos >= commonPrefix and equalsTree(newNode[newPos], oldNode[oldPos]):
      dec oldPos
      dec newPos

    if commonPrefix + newLength - newPos > 1000:
      kout cstring($(commonPrefix + newLength - newPos))

    var pos = min(oldPos, newPos) + 1

    # kout cstring("commonPrefix = " & $commonPrefix)
    # kout cstring("oldPos = " & $oldPos)
    # kout cstring("newPos = " & $newPos)
    # kout cstring("newLength = " & $newLength)
    # kout cstring("oldLength = " & $oldLength)
    # kout cstring("-----------")
    # for i in items(newNode):
    #   kout cstring(i.id)
    # kout cstring("-----")
    # for i in items(oldNode):
    #   kout cstring(i.id)

    for i in commonPrefix..pos-1:
      updateElement(current, current.childNodes[i],
        newNode[i],
        oldNode[i])
      #kout cstring(newNode[i].id & " " & oldNode[i].id)
    #kout cstring("----------")

    var nextChildPos = oldPos + 1
    # kout cstring("pos = " & $pos) 
    # kout cstring("nextChildPos = " & $nextChildPos)
    while pos <= newPos:
      if nextChildPos == oldLength:
        current.appendChild(vnodeToDom(newNode[pos]))
        kout cstring"---- appendChild"
        # kout cstring("commonPrefix = " & $commonPrefix)
        # kout cstring("oldPos = " & $oldPos)
        # kout cstring("newPos = " & $newPos)
        # kout cstring("newLength = " & $newLength)
        # kout cstring("oldLength = " & $oldLength)

        # kout cstring("pos = " & $pos)
        # kout cstring("nextChildPos = " & $nextChildPos)
        # kout cstring("-----------")
        #kout cstring("pos = " & $pos)
        #kout cstring("newLength = " & $newLength)
      else:
        kout cstring"---- insertBefore"
        current.insertBefore(vnodeToDom(newNode[pos]), current.childNodes[nextChildPos])
      inc oldLength
      inc pos
      inc nextChildPos
  
    for i in 0..oldPos-pos:
      kout cstring"---- removeChild"
      current.removeChild(current.childNodes[pos])
    
    # var itNew = newPos + 1
    # var itOld = oldPos + 1
    # while itNew < newLength and itOld < oldLength:
    #   updateElement(current, current.childNodes[itNew],
    #     newNode[itNew],
    #     oldNode[itOld])

    # kout cstring("commonPrefix = " & $commonPrefix)
    # kout cstring("oldPos = " & $oldPos)
    # kout cstring("newPos = " & $newPos)
    # kout cstring("newLength = " & $newLength)
    # kout cstring("oldLength = " & $oldLength)

    # for i in 0..min(newLength, oldLength)-1:
    #   updateElement(current, current.childNodes[i],
    #     newNode[i],
    #     oldNode[i])
    # if newLength > oldLength:
    #   for i in oldLength..newLength-1:
    #     kout cstring"appendChild"
    #     current.appendChild(vnodeToDom(newNode[i]))
    # elif oldLength > newLength:
    #   for i in countdown(oldLength-1, newLength):
    #     kout cstring"removeChild"
    #     current.removeChild(current.lastChild)


proc dodraw() =
  let newtree = dorender()
  newtree.id = "ROOT"
  toFocus = nil
  if currentTree == nil:
    currentTree = newtree
    let asdom = vnodeToDom currentTree
    replaceById("ROOT", asdom)
  else:
    let olddom = document.getElementById("ROOT")
    updateElement(nil, olddom, newtree, currentTree)
    assert same(newtree, document.getElementById("ROOT"))
    currentTree = newtree
  # now that it's part of the DOM, give it the focus:
  if toFocus != nil:
    toFocus.focus()

proc reqFrame(callback: proc()) {.importc: "window.requestAnimationFrame".}

proc redraw*() =
  # we buffer redraw requests:
  when false:
    if drawTimeout != nil:
      clearTimeout(drawTimeout)
    drawTimeout = setTimeout(dodraw, 30)
  elif true:
    reqFrame(dodraw)
  else:
    dodraw()

proc init*() =
  reqFrame(dodraw)

#proc prepend*(parent, kid: Element) =
#  parent.insertBefore(kid, parent.firstChild)
#  prependChild(parent, kid)

proc len(x: Element): int {.importcpp: "#.childNodes.length".}
proc `[]`(x: Element; idx: int): Element {.importcpp: "#.childNodes[#]".}

proc isInt*(s: cstring): bool {.asmNoStackFrame.} =
  asm """
    return s.match(/^[0-9]+$/);
  """

proc suffix*(s, prefix: cstring): cstring =
  if s.startsWith(prefix):
    result = s.substr(prefix.len)
  else:
    kout(cstring"bug! " & s & cstring" does not start with " & prefix)

proc suffixAsInt*(s, prefix: cstring): int = parseInt(suffix(s, prefix))

proc scrollTop*(e: Element): int {.importcpp: "#.scrollTop", nodecl.}
proc offsetHeight*(e: Element): int {.importcpp: "#.offsetHeight", nodecl.}
proc offsetTop*(e: Element): int {.importcpp: "#.offsetTop", nodecl.}

template onImpl(s) {.dirty.} =
  proc wrapper(ev: Event; n: VNode) =
    action(ev, n)
    redraw()
  addEventListener(e, s, wrapper)

proc setOnclick*(e: VNode; action: EventHandler) =
  onImpl EventKind.onclick

proc setOnDblclick*(e: VNode; action: EventHandler) =
  onImpl EventKind.onclick

proc setOnfocuslost*(e: VNode; action: EventHandler) =
  onImpl EventKind.onblur

proc setOnchanged*(e: VNode; action: EventHandler) =
  onImpl EventKind.onchange

proc setOnscroll*(e: VNode; action: EventHandler) =
  onImpl EventKind.onscroll

proc setOnHashChange*(action: proc (hashPart: cstring)) =
  var onhashChange {.importc: "window.onhashchange".}: proc()
  var hashPart {.importc: "window.location.hash".}: cstring
  proc wrapper() =
    action(hashPart)
    redraw()
  onhashchange = wrapper

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

proc valueAsInt*(e: Element): int = parseInt(e.value)

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

proc getAttr(e: Element; key: cstring): cstring {.
  importcpp: "#.getAttribute(#)", nodecl.}

template nativeValue(ev): cstring = cast[Element](ev.target).value
template setNativeValue(ev, val) = cast[Element](ev.target).value = val

template keyeventBody() =
  n.value = nativeValue(ev)
  action(ev, n)
  setNativeValue(ev, n.value)
  redraw()

proc realtimeInput*(val: cstring; action: EventHandler): VNode =
  #let oldElem = getElementById(id)
  #if oldElem != nil: return oldElem
  #let newVal = if oldElem.isNil: val else: $oldElem.value
  var timer: Timeout
  proc onkeyup(ev: Event; n: VNode) =
    proc wrapper() = keyeventBody()

    if timer != nil: clearTimeout(timer)
    timer = setTimeout(wrapper, 400)
  result = tree(VNodeKind.input, [(cstring"type", cstring"text")])
  result.value = val
  result.addEventListener(EventKind.onkeyup, onkeyup)

proc enterInput*(id, val: cstring; action: EventHandler): VNode =
  #let oldElem = getElementById(id)
  #if oldElem != nil: return oldElem
  #let newVal = if oldElem.isNil: val else: $oldElem.value
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

proc ajax(meth, url: cstring; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int; response: cstring)) =
  proc setRequestHeader(a, b: cstring) {.importc: "ajax.setRequestHeader".}
  {.emit: """
  var ajax = new XMLHttpRequest();
  ajax.open(`meth`,`url`,true);""".}
  for a, b in items(headers):
    setRequestHeader(a, b)
  {.emit: """
  ajax.onreadystatechange = function(){
    if(this.readyState == 4){
      if(this.status == 200){
        `cont`(this.status, this.responseText);
      } else {
        `cont`(this.status, this.statusText);
      }
    }
  }
  ajax.send(`data`);
  """.}

proc ajaxPut*(url: string; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int, response: cstring)) =
  ajax("PUT", url, headers, data, cont)

proc ajaxGet*(url: string; headers: openarray[(cstring, cstring)];
          cont: proc (httpStatus: int, response: cstring)) =
  ajax("GET", url, headers, nil, cont)

{.push stackTrace:off.}

proc setupErrorHandler*(useAlert=false) =
  ## Installs an error handler that transforms native JS unhandled
  ## exceptions into Nim based stack traces. If `useAlert` is false,
  ## the error message is put into the console, otherwise `alert`
  ## is called.
  proc stackTraceAsCstring(): cstring = cstring(getStackTrace())
  {.emit: """
  window.onerror = function(msg, url, line, col, error) {
    var x = "Error: " + msg + "\n" + `stackTraceAsCstring`()
    if (`useAlert`)
      alert(x);
    else
      console.log(x);
    var suppressErrorAlert = true;
    return suppressErrorAlert;
  };""".}

{.pop.}

when false:
  var plugins {.exportc.}: seq[(string, proc())] = @[]

  proc onInput(val: cstring) =
    kout val
    if val == "dyn":
      let body = getElementById("body")
      body.prepend(tree("script", [("type", "text/javascript"), ("src", "nimcache/dyn.js")]))
      redraw()
    kout(plugins.len)
    if plugins.len > 0:
      plugins[0][1]()

