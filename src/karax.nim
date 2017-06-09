## Karax -- Single page applications for Nim.

import kdom, vdom, jstrutils, components, jdict, vstyles, future

export kdom.Event

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

# ----------------- karax instance ---------------------------------------

type
  KaraxInstance* = ref object
    rootId: cstring not nil
    renderer: proc (): VNode {.closure.}
    currentTree: VNode

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
    #n.key = result.key
    attach n
    return result
  elif n.kind == VNodeKind.dthunk:
    result = callThunk(dcomponents[n.text], n)
    #n.key = result.key
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
  #if n.key >= 0:
  #  result.key = n.key
  for k, v in attrs(n):
    if v != nil:
      result.setAttr(k, v)
  for e, h in items(n.events):
    wrapEvent(result, n, e, h)
  if n == toFocusV and toFocus.isNil:
    toFocus = result
  if not n.style.isNil: applyStyle(result, n.style)

proc same(n: VNode, e: Node): bool =
  if toTag[n.kind] == e.nodename:
    result = true
    if n.kind != VNodeKind.text:
      if e.len != n.len: return false
      for i in 0 ..< n.len:
        if not same(n[i], e[i]): return false

proc replaceById(id: cstring; newTree: Node) =
  let x = document.getElementById(id)
  x.parentNode.replaceChild(newTree, x)
  #newTree.id = id

type
  EqResult = enum
    different, similar, identical

proc eq(a, b: VNode; deep: bool): EqResult =
  if a.kind != b.kind: return different
  if a.id != b.id: return different
  result = identical
  if a.key != b.key: return different
  if a.kind == VNodeKind.text:
    if a.text != b.text: return different
  elif a.kind == VNodeKind.vthunk or a.kind == VNodeKind.dthunk:
    if a.text != b.text: return different
    if a.len != b.len: return different
    for i in 0..<a.len:
      if eq(a[i], b[i], deep) == different: return different
  elif deep:
    if a.len != b.len: return different
    for i in 0..<a.len:
      let res = eq(a[i], b[i], deep)
      if res == different: return different
      elif res == similar:
        # but continue, maybe something makes it 'different'!
        result = similar
  if not sameAttrs(a, b): return different
  if a.class != b.class: return different
  # XXX Fixme: smart diffing still is broken for complex apps:
  if a.style != b.style: return different # similar
  # Do not test event listeners here!
  return result

proc updateDirtyElements(karax: KaraxInstance, parent, current: Node, newNode: VNode) =
  if newNode.key >= 0 and isDirty(newNode.key):
    unmarkDirty(newNode.key)
    let n = vnodeToDom(newNode)
    if parent == nil:
      replaceById(karax.rootId, n)
    else:
      parent.replaceChild(n, current)
  elif newNode.kind != VNodeKind.text and newNode.kind != VNodeKind.vthunk and
       newNode.kind != VNodeKind.dthunk:
    for i in 0..newNode.len-1:
      updateDirtyElements(karax, current, current[i], newNode[i])
      # leave early if we know there cannot be anything left to do:
      #if dirtyCount <= 0: return

proc updateStyles(newNode, oldNode: VNode; deep: bool) =
  # we keep the oldNode, but take over the style from the new node:
  if oldNode.dom != nil:
    if newNode.style != nil: applyStyle(oldNode.dom, newNode.style)
    else: oldNode.dom.style = Style()
  oldNode.style = newNode.style
  if deep:
    assert newNode.len == oldNode.len
    for i in 0 ..< newNode.len:
      updateStyles(newNode[i], oldNode[i], deep)

proc updateDom(newNode, oldNode: VNode) =
  newNode.dom = oldNode.dom
  assert newNode.len == oldNode.len
  for i in 0 ..< newNode.len:
    updateDom(newNode[i], oldNode[i])

proc updateElement(karax: KaraxInstance; parent, current: Node, newNode, oldNode: VNode) =
  let res = eq(newNode, oldNode, deep=false)
  if res == different:
    detach(oldNode)
    let n = vnodeToDom(newNode)
    if parent == nil:
      replaceById(karax.rootId, n)
    else:
      parent.replaceChild(n, current)
  else:
    if res == similar: updateStyles(newNode, oldNode, false)
    newNode.dom = oldNode.dom

    if newNode.kind != VNodeKind.text:
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

        template eqAndUpdate(a, b: VNode; action: untyped) =
          let r = eq(a, b, true)
          case r
          of identical:
            updateDom(a, b)
            action
          of different: break
          of similar:
            updateDom(a, b)
            updateStyles(a, b, true)
            action

        while commonPrefix < minLength:
          eqAndUpdate(newNode[commonPrefix], oldNode[commonPrefix]):
            inc commonPrefix

        var oldPos = oldLength - 1
        var newPos = newLength - 1
        while oldPos >= commonPrefix and newPos >= commonPrefix:
          eqAndUpdate(newNode[newPos], oldNode[oldPos]):
            dec oldPos
            dec newPos

        var pos = min(oldPos, newPos) + 1
        for i in commonPrefix..pos-1:
          updateElement(karax, current, current.childNodes[i], newNode[i], oldNode[i])

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


proc reqFrame(callback: proc()) {.importc: "window.requestAnimationFrame".}


proc dodraw(karax: KaraxInstance) =
  if karax.renderer.isNil: return
  let newtree = karax.renderer()
  newtree.id = karax.rootId
  toFocus = nil
  if karax.currentTree == nil:
    karax.currentTree = newtree
    let asdom = vnodeToDom karax.currentTree
    replaceById(karax.rootId, asdom)
  else:
    let olddom = document.getElementById(karax.rootId)
    updateElement(karax, nil, olddom, newtree, karax.currentTree)
    #assert same(newtree, document.getElementById(karax.rootId))
    if someDirty:
      updateDirtyElements(karax, nil, olddom, newtree)
      someDirty = false
    karax.currentTree = newtree
  # now that it's part of the DOM, give it the focus:
  if toFocus != nil:
    toFocus.focus()


when false:
  var drawTimeout: Timeout

proc redraw*(karax: KaraxInstance) =
  # we buffer redraw requests:
  when false:
    if drawTimeout != nil:
      clearTimeout(drawTimeout)
    drawTimeout = setTimeout(dodraw, 30)
  elif true:
    reqFrame(() => karax.dodraw())
  else:
    dodraw()


proc setOnHashChange*(karax: KaraxInstance, action: proc (hashPart: cstring)) =
  var onhashChange {.importc: "window.onhashchange".}: proc()
  var hashPart {.importc: "window.location.hash".}: cstring
  proc wrapper() =
    action(hashPart)
    karax.redraw()
  onhashchange = wrapper


proc addEventHandler*(karax: KaraxInstance, n: VNode; k: EventKind; action: EventHandler) =
  ## Implements the foundation of Karax's event management.
  ## Karax DSL transforms ``tag(onEvent = handler)`` to
  ## ``tempNode.addEventHandler(state, tagNode, EventKind.onEvent, wrapper)``
  ## where ``wrapper`` calls the passed ``action`` and then triggers
  ## a ``redraw``.
  proc wrapper(ev: Event; n: VNode) =
    action(ev, n)
    karax.redraw()
  addEventListener(n, k, wrapper)


proc initKarax*(renderer: () -> VNode, rootId: cstring = cstring"ROOT"): KaraxInstance =
  ## Starts the Karax rendering. Typically this function
  ## is called from within a window.onload handler to
  ## make sure that the DOM is available.
  var karax = KaraxInstance(
    rootId: rootId,
    renderer: renderer,
  )
  reqFrame(() => karax.dodraw())
  result = karax


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

proc loadScript*(karax: KaraxInstance, jsfilename: cstring) =
  let body = getElementById("body")
  let s = document.createElement("script")
  s.setAttr "type", "text/javascript"
  s.setAttr "src", jsfilename
  body.prepend(s)
  karax.redraw()
