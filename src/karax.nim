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
  if a.key == -1 and b.key == -1:
    return eq(a, b)
  else:
    if a.kind != b.kind: return false
    if a.id != b.id: return false
    if a.key != b.key: return false
    if a.kind == VNodeKind.text:
      if a.text != b.text: return false
    elif a.kind == VNodeKind.vthunk or a.kind == VNodeKind.dthunk:
      if a.text != b.text: return false
    if not sameAttrs(a, b): return false
    if a.class != b.class: return false
    # XXX test event listeners here?
    return true

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

proc printChildren(parent: Node): cstring =
  discard
  # if parent != nil and parent.hasChildNodes:
  #   var it = parent.firstChild
  #   result = ""
  #   while it != nil:
  #     if it.id == nil:
  #       result.add(" nil")
  #     else:
  #       result.add(" " & $it.id)
  #     it = it.nextSibling

proc printChildren(parent: VNode): cstring =
  discard
  # if parent != nil:
  #   result = ""
  #   for i in 0..parent.len-1:
  #     if parent[i] == nil or parent[i].id == nil:
  #       result.add(" nil")
  #     else:
  #       result.add(" " & $(parent[i].id))

proc print(s: cstring, ident: int) =
  discard
  # var result = ""
  # for i in 0..ident:
  #   result.add "  "
  # result.add(s)
  # kout cstring(result)

proc longestIncreasingSubsequence(a: seq[int]): seq[int] =
  if len(a) == 0:
    return @[]
    
  result.add 0
  var parent = newSeq[int](len(a))
  for i in 0..<len(a):
    var j = result[len(result) - 1]
    if a[j] < a[i]:
      parent[i] = j
      result.add(i)
      continue
    
    var left = 0
    var right = len(result) - 1

    while left < right:
      var mid = (left + right) div 2
      if a[result[mid]] < a[i]:
        left = mid + 1
      else:
        right = mid
    
    if a[i] < a[result[left]]:
      if left > 0:
        parent[i] = result[left - 1]
      result[left] = i
    
  var pos = len(result)
  var v = result[pos - 1]
  while pos > 0:
    result[pos] = v
    v = parent[v]
    dec pos

proc updateElement(parent, current: Node, newNode, oldNode: VNode, ident: int = 0) =
  if newNode.key != -1:
    kout cstring($newNode.key)
  if oldNode.key != -1:
    kout cstring($oldNode.key)
  newNode.dom = oldNode.dom
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
      #kout cstring("start") 
      print("----------------", ident)
      print("----------------", ident)
      var before = printChildren(current)

      # maximal common prefix
      var left = 0
      while left < minLength and equalsShallow(newNode[left], oldNode[left]):
        updateElement(current, oldNode[left].dom, newNode[left], oldNode[left], ident + 1)
        inc left

      # maximal common suffix
      var rightOld = oldLength - 1
      var rightNew = newLength - 1
      while rightOld >= left and rightNew >= left and equalsShallow(newNode[rightNew], oldNode[rightOld]):
        updateElement(current, oldNode[rightOld].dom, newNode[rightNew], oldNode[rightOld], ident + 1)
        dec rightOld
        dec rightNew

      var leftOld = left
      var leftNew = left
      
     
      var flag = false
      #if rightOld >= leftOld and rightNew >= leftNew and equalsShallow(oldNode[leftOld], newNode[rightNew]):
      print("current", ident)
      print(printChildren(current), ident)
      print("oldNode", ident)
      print(printChildren(oldNode), ident)
      print("newNode", ident)
      print(printChildren(newNode), ident)
      flag = true
      
      # cross comparing
      while rightOld >= leftOld and rightNew >= leftNew and equalsShallow(oldNode[leftOld], newNode[rightNew]):
        print($oldNode[leftOld].id & " " & $newNode[rightNew].id, ident)
        print("pos: " & $leftOld & " " & $rightNew, ident)

        var nextNode: Node = nil
        if rightNew + 1 < newLength:
          nextNode = newNode[rightNew + 1].dom
        print("update", ident)
        updateElement(current, oldNode[leftOld].dom, newNode[rightNew], oldNode[leftOld], ident + 1)
        print("update", ident)
        if nextNode == nil:
          current.appendChild(oldNode[leftOld].dom)
          print("append", ident)
        else:
          print("insertBefore", ident)
          current.insertBefore(oldNode[leftOld].dom, nextNode)
        print($oldNode[leftOld], ident)
        inc leftOld
        dec rightNew

      while rightOld >= leftOld and rightNew >= leftNew and equalsShallow(oldNode[rightOld], newNode[leftNew]):
        var nextNode: Node = oldNode[leftOld].dom
        updateElement(current, oldNode[rightOld].dom, newNode[leftNew], oldNode[rightOld], ident + 1)
        current.insertBefore(oldNode[rightOld].dom, nextNode)
        inc leftNew
        dec rightOld

      if flag:
        print("after", ident)
        print(printChildren(current), ident)

      var isKeyed = true
      for i in leftNew..rightNew:
        if newNode[i].key == -1:
          isKeyed = false
          break

      for i in leftOld..rightOld:
        if oldNode[i].key == -1:
          isKeyed = false
        if not isKeyed:
          break

      if rightNew - leftNew + 1 + rightOld - leftOld + 1 == 0:
        isKeyed = false

      
      if isKeyed:
        if rightNew > leftNew:
          # remove redundant old nodes
          for i in leftOld..rightOld:
            current.removeChild(oldNode[i].dom)
            detach(oldNode[i])
        else:
          # permute elements using LIS
          var positionByKey = newJDict[VKey, int]()
          var positions = newSeq[int]()
          for i in leftOld..rightOld:
            positionByKey[oldNode[i].key] = i
          for i in leftNew..rightNew:
            if positionByKey.contains(newNode[i].key):
              positions.add positionByKey[newNode[i].key]
          
          #if len(positions) > 0:
          # kout cstring("new segment len = " & $(rightNew - leftNew + 1))
          # kout cstring("old segment len = " & $(rightOld - leftOld + 1))
          # var t = ""
          # for i in 0..<len(positions):
          #   t.add($positions[i] & " ")
          # kout cstring(t)

          var lis = longestIncreasingSubsequence(positions)
          var lisPos = 0
          var isNotRedundant = newSeq[bool](rightOld - leftOld + 1)
          for i in leftNew..rightNew:
            if lisPos < len(lis):
              var index = lis[lisPos]
              if oldNode[index].key == newNode[i].key:
                isNotRedundant[index - leftOld] = true
                updateElement(current, oldNode[index].dom, newNode[i], oldNode[index], ident + 1)
                inc lisPos
              else:
                if positionByKey.contains(newNode[i].key):
                  var oldPos = positionByKey[newNode[i].key]
                  isNotRedundant[oldPos - leftOld] = true
                  current.insertBefore(oldNode[oldPos].dom, oldNode[index].dom)
                else:
                  current.insertBefore(vnodeToDom(newNode[i]), oldNode[index].dom)
            else:
              if positionByKey.contains(newNode[i].key):
                var oldPos = positionByKey[newNode[i].key]
                isNotRedundant[oldPos - leftOld] = true
                current.appendChild(oldNode[oldPos].dom)
              else:
                current.appendChild(vnodeToDom(newNode[i]))
            
            # remove redundant old nodes
            for i in leftOld..rightOld:
              if not isNotRedundant[i]:
                current.removeChild(oldNode[i].dom)
      else:
        # simply diff 
        print($leftOld & " " & $rightOld & " " & $leftNew & " " & $rightNew, ident)
        while rightOld >= leftOld and rightNew >= leftNew:
          updateElement(current, oldNode[leftOld].dom, newNode[leftNew], oldNode[leftOld], ident + 1)
          inc leftNew
          inc leftOld
        
        print("TEMP", ident)
        print(printChildren(current), ident)
        print($leftOld & " " & $rightOld & " " & $leftNew & " " & $rightNew, ident)
        print("other part start", ident)
        var isPushBack = (rightNew + 1 == newLength)
        var nextNode: Node = nil
        if not isPushBack:
          print($(rightNew + 1), ident)
          nextNode = newNode[rightNew + 1].dom
        while leftNew <= rightNew:
          var node = vnodeToDom(newNode[leftNew])
          if isPushBack:
            current.appendChild(node)
          else:
            current.insertBefore(node, nextNode)
          inc leftNew
        print("other part finish", ident)

        for i in leftOld..rightOld:
          current.removeChild(oldNode[i].dom)
          detach(oldNode[i])

        print("----------------", ident)
        print("before", ident)
        print(before, ident)
        print("finish", ident)
        print(printChildren(current), ident)
        print("----------------", ident)
        print("----------------", ident)

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
