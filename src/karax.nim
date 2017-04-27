## Karax -- Single page applications for Nim.

import dom, vdom, jstrutils, components, jdict

export dom.Event

proc kout*[T](x: T) {.importc: "console.log", varargs.}
  ## the preferred way of debugging karax applications.

proc hasProp(e: Node; prop: cstring): bool {.importcpp: "(#.hasOwnProperty(#))".}
proc rawkey(e: Node): VKey {.importcpp: "#.karaxKey", nodecl.}
proc key*(e: Node): VKey =
  if e.hasProp"karaxKey": result = e.rawkey
  else: result = -1
proc `key=`*(e: Node; x: VKey) {.importcpp: "#.karaxKey = #", nodecl.}

var
  toFocus: Node
  toFocusV: VNode

proc setFocus*(n: VNode) =
  toFocusV = n

# ----------------- event wrapping ---------------------------------------

template nativeValue(ev): cstring = cast[Element](ev.target).value
template setNativeValue(ev, val) = cast[Element](ev.target).value = val

template keyeventBody() =
  n.value = nativeValue(ev)
  action(ev, n)
  setNativeValue(ev, n.value)
  # Do not call redraw() here! That is already done
  # by ``karax.addEventHandler``.

proc wrapEvent(d: Node; n: VNode; k: EventKind; action: EventHandler) =
  proc stdWrapper(): (proc (ev: Event)) =
    let action = action
    let n = n
    result = proc (ev: Event) =
      action(ev, n)

  proc enterWrapper(): (proc (ev: Event)) =
    let action = action
    let n = n
    result = proc (ev: Event) =
      if ev.keyCode == 13: keyeventBody()

  proc laterWrapper(): (proc (ev: Event)) =
    let action = action
    let n = n
    var timer: Timeout
    result = proc (ev: Event) =
      proc wrapper() = keyeventBody()
      if timer != nil: clearTimeout(timer)
      timer = setTimeout(wrapper, 400)

  case k
  of EventKind.onkeyuplater:
    d.addEventListener("keyup", laterWrapper())
  of EventKind.onkeyupenter:
    d.addEventListener("keyup", enterWrapper())
  else:
    d.addEventListener(toEventName[k], stdWrapper())

# --------------------- DOM diff -----------------------------------------

template detach(n: VNode) = n.dom = nil
template attach(n: Vnode) = n.dom = result

proc vnodeToDom(n: VNode): Node =
  if n.kind == VNodeKind.text:
    result = document.createTextNode(n.text)
    attach n
  elif n.kind == VNodeKind.vthunk:
    let x = callThunk(vcomponents[n.text], n)
    result = vnodeToDom(x)
    n.key = result.key
    attach n
    return result
  elif n.kind == VNodeKind.dthunk:
    result = callThunk(dcomponents[n.text], n)
    n.key = result.key
    attach n
    return result
  else:
    result = document.createElement(toTag[n.kind])
    attach n
    for k in n:
      appendChild(result, vnodeToDom(k))
    # text is mapped to 'value':
    if n.text != nil:
      result.value = n.text
  if n.id != nil:
    result.id = n.id
  if n.class != nil:
    result.class = n.class
  if n.key >= 0:
    result.key = n.key
  for k, v in attrs(n):
    if v != nil:
      result.setAttr(k, v)
  for e, h in items(n.events):
    wrapEvent(result, n, e, h)
  if n == toFocusV and toFocus.isNil:
    toFocus = result

proc same(n: VNode, e: Node): bool =
  if toTag[n.kind] == e.nodename:
    result = true
    if n.kind != VNodeKind.text:
      if e.len != n.len: return false
      for i in 0 ..< n.len:
        if not same(n[i], e[i]): return false

var
  dorender: proc (): VNode {.closure.}
  currentTree: VNode

proc replaceById(id: cstring; newTree: Node) =
  let x = document.getElementById(id)
  x.parentNode.replaceChild(newTree, x)
  #newTree.id = id

proc equalsShallow(a, b: VNode): bool =
  if a.kind != b.kind: return false
  if a.id != b.id: return false
  if a.key != b.key: return false
  if a.kind == VNodeKind.text:
    if a.text != b.text: return false
  elif a.kind == VNodeKind.vthunk or a.kind == VNodeKind.dthunk:
    if a.text != b.text: return false
    if a.len != b.len: return false
    for i in 0..<a.len:
      if not equalsShallow(a[i], b[i]): return false
  if not sameAttrs(a, b): return false
  if a.class != b.class: return false
  # XXX test event listeners here?
  return true

proc equalsTree(a, b: VNode): bool =
  when false:
    # hashing is too fragile now with component support:
    if not a.validHash:
      a.calcHash()
    if not b.validHash:
      b.calcHash()
    return a.hash == b.hash
  else:
    result = eq(a, b)

proc updateDirtyElements(parent, current: Node, newNode: VNode) =
  if newNode.key >= 0 and isDirty(newNode.key):
    unmarkDirty(newNode.key)
    let n = vnodeToDom(newNode)
    if parent == nil:
      replaceById("ROOT", n)
    else:
      parent.replaceChild(n, current)
  elif newNode.kind != VNodeKind.text and newNode.kind != VNodeKind.vthunk and
       newNode.kind != VNodeKind.dthunk:
    for i in 0..newNode.len-1:
      updateDirtyElements(current, current[i], newNode[i])
      # leave early if we know there cannot be anything left to do:
      #if dirtyCount <= 0: return

proc updateElement(parent, current: Node, newNode, oldNode: VNode) =
  if not equalsShallow(newNode, oldNode):
    detach(oldNode)
    let n = vnodeToDom(newNode)
    if parent == nil:
      replaceById("ROOT", n)
    else:
      parent.replaceChild(n, current)
  elif newNode.kind != VNodeKind.text:
    let newLength = newNode.len
    var oldLength = oldNode.len
    let minLength = min(newLength, oldLength)
    assert oldNode.kind == newNode.kind
    when defined(simpleDiff):
      for i in 0..min(newLength, oldLength)-1:
        updateElement(current, current[i], newNode[i], oldNode[i])
      if newLength > oldLength:
        for i in oldLength..newLength-1:
          current.appendChild(vnodeToDom(newNode[i]))
      elif oldLength > newLength:
        for i in countdown(oldLength-1, newLength):
          detach(oldNode[i])
          current.removeChild(current.lastChild)
    else:
      var commonPrefix = 0
      while commonPrefix < minLength and
          equalsTree(newNode[commonPrefix], oldNode[commonPrefix]):
        inc commonPrefix

      var oldPos = oldLength - 1
      var newPos = newLength - 1
      while oldPos >= commonPrefix and newPos >= commonPrefix and
          equalsTree(newNode[newPos], oldNode[oldPos]):
        dec oldPos
        dec newPos

      var pos = min(oldPos, newPos) + 1
      for i in commonPrefix..pos-1:
        updateElement(current, current.childNodes[i], newNode[i], oldNode[i])

      var nextChildPos = oldPos + 1
      while pos <= newPos:
        if nextChildPos == oldLength:
          current.appendChild(vnodeToDom(newNode[pos]))
        else:
          current.insertBefore(vnodeToDom(newNode[pos]), current.childNodes[nextChildPos])
        # added new Node, so old state of VDOM have one more Node
        inc oldLength
        inc pos
        inc nextChildPos

      for i in pos..oldPos:
        detach(oldNode[i])
        current.removeChild(current.childNodes[pos])

when false:
  var drawTimeout: Timeout

proc dodraw() =
  if dorender.isNil: return
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
    #assert same(newtree, document.getElementById("ROOT"))
    if someDirty:
      updateDirtyElements(nil, olddom, newtree)
      someDirty = false
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

proc redrawForce*() = dodraw()

proc init(ev: Event) =
  reqFrame(dodraw)

proc setRenderer*(renderer: proc (): VNode) =
  dorender = renderer
  window.onload = init

proc setRendererOnly*(renderer: proc (): VNode) =
  dorender = renderer

proc setOnloadOnly*() =
  window.onload = init

proc addEventHandler*(n: VNode; k: EventKind; action: EventHandler) =
  ## Implements the foundation of Karax's event management.
  ## Karax DSL transforms ``tag(onEvent = handler)`` to
  ## ``tempNode.addEventHandler(tagNode, EventKind.onEvent, wrapper)``
  ## where ``wrapper`` calls the passed ``action`` and then triggers
  ## a ``redraw``.
  proc wrapper(ev: Event; n: VNode) =
    action(ev, n)
    redraw()
  addEventListener(n, k, wrapper)

proc setOnHashChange*(action: proc (hashPart: cstring)) =
  var onhashChange {.importc: "window.onhashchange".}: proc()
  var hashPart {.importc: "window.location.hash".}: cstring
  proc wrapper() =
    action(hashPart)
    redraw()
  onhashchange = wrapper

{.push stackTrace:off.}

proc setupErrorHandler*() =
  ## Installs an error handler that transforms native JS unhandled
  ## exceptions into Nim based stack traces. If `useAlert` is false,
  ## the error message is put into the console, otherwise `alert`
  ## is called.
  proc stackTraceAsCstring(): cstring = cstring(getStackTrace())
  var onerror {.importc: "window.onerror".} =
    proc (msg, url: cstring, line, col: int, error: cstring): bool =
      var x = cstring"Error: " & msg & "\n" & stackTraceAsCstring()
      kout(x)
      return true # suppressErrorAlert
{.pop.}

proc prepend(parent, kid: Element) =
  parent.insertBefore(kid, parent.firstChild)

proc loadScript*(jsfilename: cstring) =
  let body = getElementById("body")
  let s = document.createElement("script")
  s.setAttr "type", "text/javascript"
  s.setAttr "src", jsfilename
  body.prepend(s)
  redraw()
