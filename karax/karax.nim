## Karax -- Single page applications for Nim.

import kdom, vdom, jstrutils, compact, jdict, vstyles

export kdom.Event, kdom.Blob

when defined(nimNoNil):
  {.experimental: "notnil".}

proc createElementNS(document: Document, namespace, tag: cstring): Node {.importjs: "#.createElementNS(@)".}
proc `classBaseVal=`(n: Node, v: cstring) {.importjs: "#.className.baseVal = #".}

proc kout*[T](x: T) {.importc: "console.log", varargs.}
  ## The preferred way of debugging karax applications.

type
  PatchKind = enum
    pkReplace, pkRemove, pkAppend, pkInsertBefore, pkDetach, pkSame
  Patch = object
    k: PatchKind
    parent, current: Node
    newNode, oldNode: VNode
  PatchV = object
    parent, newChild: VNode
    pos: int
  ComponentPair = object
    oldNode, newNode: VComponent
    parent, current: Node

type
  RouterData* = ref object ## information that is passed to the 'renderer' callback
    hashPart*: cstring     ## the hash part of the URL for routing.
    queryString*: cstring  ## The search string, can be used for passing data to karax

  KaraxInstance* = ref object ## underlying karax instance. Usually you don't have
                              ## know about this.
    rootId: cstring
    renderer: proc (data: RouterData): VNode {.closure.}
    currentTree: VNode
    postRenderCallback: proc (data: RouterData)
    toFocus: Node
    toFocusV: VNode
    renderId: int
    rendering: bool
    patches: seq[Patch] # we reuse this to save allocations
    patchLen: int
    patchesV: seq[PatchV]
    patchLenV: int
    runCount: int
    components: seq[ComponentPair]
    surpressRedraws*: bool
    byId: JDict[cstring, VNode]
    when defined(stats):
      recursion: int
    orphans: JDict[cstring, bool]

# const kxiname = instantiationInfo().filename # does not work :/
const kxiname {.strdefine.} = ""
var
  kxi* {.exportc: "kxi__" & kxiname .}:  KaraxInstance ## The current Karax instance. This is always used
                      ## as the default. **Note**: Within the karax DSL
                      ## always a symbol of the name *kxi* is assumed, so
                      ## if you have a local karax instance to use instead
                      ## in your 'buildHtml' statement, it needs to be named
                      ## 'kxi'.

proc setFocus*(n: VNode; enabled = true; kxi: KaraxInstance = kxi) =
  if enabled:
    kxi.toFocusV = n

# ----------------- event wrapping ---------------------------------------

template nativeValue(ev): cstring = cast[Element](ev.target).value
template setNativeValue(ev, val) = cast[Element](ev.target).value = val

template keyeventBody() =
  let v = nativeValue(ev)
  n.value = v
  assert action != nil
  action(ev, n)
  if n.value != v:
    setNativeValue(ev, n.value)
  # Do not call redraw() here! That is already done
  # by ``karax.addEventHandler``.

proc karaxEvents(d: Node): JSeq[(cstring, NativeEventHandler)] {.importcpp: "#.karaxEvents".}
proc `karaxEvents=`(d: Node; value: JSeq[(cstring, NativeEventHandler)]) {.importcpp: "#.karaxEvents = #".}

proc addEventShell(d: Node; name: cstring; h: NativeEventHandler) =
  # The DOM is such a pathetic piece of junk that it doesn't
  # offer 'removeAllEventHandlers()'. Hence we store the event
  # handler twice in 'd' so that we can emulate this properly.
  # This is required to fix bug #139.
  d.addEventListener(name, h)
  if d.karaxEvents == nil:
    d.karaxEvents = newJSeq[(cstring, NativeEventHandler)]()
  d.karaxEvents.add((name, h))

proc removeAllEventHandlers(d: Node) =
  if d.karaxEvents != nil:
    for i in 0..<d.karaxEvents.len:
      d.removeEventListener(d.karaxEvents[i][0], d.karaxEvents[i][1])

proc wrapEvent(d: Node; n: VNode; k: EventKind;
               action: EventHandler): NativeEventHandler =
  proc stdWrapper(): NativeEventHandler =
    let action = action
    let n = n
    result = proc (ev: Event) =
      if n.kind == VNodeKind.textarea or n.kind == VNodeKind.input or n.kind == VNodeKind.select:
        keyeventBody()
      else: action(ev, n)

  proc enterWrapper(): NativeEventHandler =
    let action = action
    let n = n
    result = proc (ev: Event) =
      if cast[KeyboardEvent](ev).keyCode == 13: keyeventBody()

  proc laterWrapper(): NativeEventHandler =
    let action = action
    let n = n
    var timer: Timeout
    result = proc (ev: Event) =
      proc wrapper() = keyeventBody()
      if timer != nil: clearTimeout(timer)
      timer = setTimeout(wrapper, 400)

  case k
  of EventKind.onkeyuplater:
    result = laterWrapper()
    d.addEventShell("keyup", result)
  of EventKind.onkeyupenter:
    result = enterWrapper()
    d.addEventShell("keyup", result)
  else:
    result = stdWrapper()
    d.addEventShell(toEventName[k], result)

# --------------------- DOM diff -----------------------------------------

template detach(n: VNode) =
  addPatch(kxi, pkDetach, nil, nil, nil, n)

template attach(n: VNode) =
  n.dom = result
  if n.id != nil: kxi.byId[n.id] = n

proc applyEvents(n: VNode) =
  let dest = n.dom
  for i in 0..<len(n.events):
    n.events[i][2] = wrapEvent(dest, n, n.events[i][0], n.events[i][1])

proc reapplyEvents(n: VNode) =
  removeAllEventHandlers(n.dom)
  applyEvents(n)

proc getVNodeById*(id: cstring; kxi: KaraxInstance = kxi): VNode =
  ## Get the VNode that was marked with ``id``. Returns ``nil``
  ## if no node exists.
  if kxi.byId.contains(id):
    result = kxi.byId[id]

proc toDom*(n: VNode; useAttachedNode: bool; kxi: KaraxInstance = nil): Node =
  if useAttachedNode:
    if n.dom != nil:
      if n.id != nil: kxi.byId[n.id] = n
      return n.dom
  if n.kind == VNodeKind.text:
    result = document.createTextNode(n.text)
    attach n
  elif n.kind == VNodeKind.verbatim:
    result = document.createElement("div")
    result.innerHTML = n.text
    attach n
    return result
  elif n.kind == VNodeKind.vthunk:
    let x = callThunk(vcomponents[n.text], n)
    result = toDom(x, useAttachedNode, kxi)
    #n.key = result.key
    attach n
    return result
  elif n.kind == VNodeKind.dthunk:
    result = n.dom #callThunk(dcomponents[n.text], n)
    assert result != nil
    #n.key = result.key
    attach n
    return result
  elif n.kind == VNodeKind.component:
    let x = VComponent(n)
    if x.onAttachImpl != nil: x.onAttachImpl(x)
    assert x.renderImpl != nil
    if x.expanded == nil:
      x.expanded = x.renderImpl(x)
      #  x.updatedImpl(x, nil)
    assert x.expanded != nil
    result = toDom(x.expanded, useAttachedNode, kxi)
    attach n
    return result
  else:
    result =
      if n.kind in svgElements:
        document.createElementNS(svgNamespace, toTag[n.kind])
      elif n.kind in mathElements:
        document.createElementNS(mathNamespace, toTag[n.kind])
      else:
        document.createElement(toTag[n.kind])
    attach n
    for k in n:
      appendChild(result, toDom(k, useAttachedNode, kxi))
    # text is mapped to 'value':
    if n.text != nil:
      result.value = n.text
  if n.id != nil:
    result.id = n.id
  if n.class != nil:
    if n.kind in svgElements:
      result.classBaseVal = n.class.cstring
    else:
      result.class = n.class
  #if n.key >= 0:
  #  result.key = n.key
  for k, v in attrs(n):
    if v != nil:
      result.setAttr(k, v)
  applyEvents(n)
  if kxi != nil and n == kxi.toFocusV and kxi.toFocus.isNil:
    kxi.toFocus = result
  if not n.style.isNil:
    applyStyle(result, n.style)
    n.styleVersion = n.style.version

proc same(n: VNode, e: Node; nesting = 0): bool =
  if kxi.orphans.contains(n.id): return true
  if n.kind == VNodeKind.component:
    result = same(VComponent(n).expanded, e, nesting+1)
  elif n.kind == VNodeKind.verbatim:
    result = true
  elif n.kind == VNodeKind.vthunk or n.kind == VNodeKind.dthunk:
    # we don't check these:
    result = true
  elif toTag[n.kind] == e.nodeName:
    result = true
    if n.kind != VNodeKind.text:
      # BUGFIX: Microsoft's Edge gives the textarea a child containing the text node!
      if e.len != n.len and n.kind != VNodeKind.textarea:
        when defined(karaxDebug):
          echo "expected ", n.len, " real ", e.len, " ", toTag[n.kind], " nesting ", nesting
        return false
      for i in 0 ..< n.len:
        if not same(n[i], e[i], nesting+1): return false
  else:
    when defined(karaxDebug):
      echo "VDOM: ", toTag[n.kind], " DOM: ", e.nodeName

proc replaceById(id: cstring; newTree: Node) =
  let x = document.getElementById(id)
  x.parentNode.replaceChild(newTree, x)
  newTree.id = id

type
  EqResult = enum
    componentsIdentical, different, similar, identical, usenewNode

when defined(profileKarax):
  type
    DifferEnum = enum
      deKind, deId, deIndex, deText, deComponent, deClass,
      deSimilar

  var
    reasons: array[DifferEnum, int]

  proc echa(a: array[DifferEnum, int]) =
    for i in low(DifferEnum)..high(DifferEnum):
      echo i, " value: ", a[i]

proc eq(a, b: VNode; recursive: bool): EqResult =
  if a.kind != b.kind:
    when defined(profileKarax): inc reasons[deKind]
    return different
  if a.id != b.id:
    when defined(profileKarax): inc reasons[deId]
    return different
  result = identical
  if a.index != b.index:
    when defined(profileKarax): inc reasons[deIndex]
    return different
  if a.kind == VNodeKind.text:
    if a.text != b.text:
      when defined(profileKarax): inc reasons[deText]
      return different # similar
  elif a.kind == VNodeKind.vthunk:
    if a.text != b.text: return different
    if a.len != b.len: return different
    for i in 0..<a.len:
      if eq(a[i], b[i], recursive) == different: return different
  elif a.kind == VNodeKind.dthunk:
    if a.dom == b.dom:
      return identical
    else: # fix #119
      return different
  elif a.kind == VNodeKind.verbatim:
    if a.text != b.text:
      return different
  elif b.kind == VNodeKind.component:
    # different component names mean different components:
    if a.text != b.text:
      when defined(profileKarax): inc reasons[deComponent]
      return different
    #if VComponent(a).key.isNil and VComponent(b).key.isNil:
    #  when defined(profileKarax): inc reasons[deComponent]
    #  return different
    if VComponent(a).key != VComponent(b).key:
      when defined(profileKarax): inc reasons[deComponent]
      return different
    return componentsIdentical
  #if:
  #  when defined(profileKarax): inc reasons[deClass]
  #  return different

  if a.class != b.class or not (eq(a.style, b.style) and versionMatch(a.style, b.styleVersion)) or not sameAttrs(a, b):
    when defined(profileKarax): inc reasons[deSimilar]
    return similar

  if recursive:
    if a.len != b.len:
      return different
    for i in 0..<a.len:
      if eq(a[i], b[i], true) != identical:
        return different

  # Do not test event listeners here!
  return result

proc updateStyles(newNode, oldNode: VNode) =
  # we keep the oldNode, but take over the style from the new node:
  if oldNode.dom != nil:
    if newNode.style != nil:
      applyStyle(oldNode.dom, newNode.style)
      newNode.styleVersion = newNode.style.version
    else: oldNode.dom.style = Style()
    if oldNode.kind in svgElements:
      oldNode.dom.classBaseVal = newNode.class
    else:
      oldNode.dom.class = newNode.class
  oldNode.style = newNode.style
  oldNode.class = newNode.class

proc updateAttributes(newNode, oldNode: VNode) =
  # we keep the oldNode, but take over the attributes from the new node:
  if oldNode.dom != nil:
    for k, _ in attrs(oldNode):
      oldNode.dom.removeAttribute(k)
    for k, v in attrs(newNode):
      if v != nil:
        oldNode.dom.setAttr(k, v)
  takeOverAttr(newNode, oldNode)

proc mergeEvents(newNode, oldNode: VNode; kxi: KaraxInstance) =
  let d = oldNode.dom
  if d != nil:
    removeAllEventHandlers(d)
    when false:
      for i in 0..<oldNode.events.len:
        let k = oldNode.events[i][0]
        let name = case k
                  of EventKind.onkeyuplater, EventKind.onkeyupenter: cstring"keyup"
                  else: toEventName[k]
        d.removeEventListener(name, oldNode.events[i][2])
  shallowCopy(oldNode.events, newNode.events)
  applyEvents(oldNode)

when false:
  proc printV(n: VNode; depth: cstring = "") =
    kout depth, cstring($n.kind), cstring"key ", n.index
    #for k, v in pairs(n.style):
    #  kout depth, "style: ", k, v
    if n.kind == VNodeKind.component:
      let nn = VComponent(n)
      if nn.expanded != nil: printV(nn.expanded, ">>" & depth)
    elif n.kind == VNodeKind.text:
      kout depth, n.text
    for i in 0 ..< n.len:
      printV(n[i], depth & "  ")

proc addPatch(kxi: KaraxInstance; ka: PatchKind; parenta, currenta: Node;
              na, oldNode: VNode) =
  let L = kxi.patchLen
  if L >= kxi.patches.len:
    # allocate more space:
    kxi.patches.add(Patch(k: ka, parent: parenta, current: currenta,
                          newNode: na, oldNode: oldNode))
  else:
    kxi.patches[L].k = ka
    kxi.patches[L].parent = parenta
    kxi.patches[L].current = currenta
    kxi.patches[L].newNode = na
    kxi.patches[L].oldNode = oldNode
  inc kxi.patchLen

proc addPatchV(kxi: KaraxInstance; parent: VNode; pos: int; newChild: VNode) =
  let L = kxi.patchLenV
  if L >= kxi.patchesV.len:
    # allocate more space:
    kxi.patchesV.add(PatchV(parent: parent, newChild: newChild, pos: pos))
  else:
    kxi.patchesV[L].parent = parent
    kxi.patchesV[L].newChild = newChild
    kxi.patchesV[L].pos = pos
  inc kxi.patchLenV

proc moveDom(dest, src: VNode) =
  dest.dom = src.dom
  src.dom = nil
  reapplyEvents(dest)
  if dest.id != nil:
    kxi.byId[dest.id] = dest
  assert dest.len == src.len
  for i in 0..<dest.len:
    moveDom(dest[i], src[i])

proc applyPatch(kxi: KaraxInstance) =
  for i in 0..<kxi.patchLen:
    let p = kxi.patches[i]
    case p.k
    of pkReplace:
      let nn = toDom(p.newNode, useAttachedNode = true, kxi)
      if p.parent == nil:
        replaceById(kxi.rootId, nn)
      else:
        if p.current.parentNode == p.parent:
          p.parent.replaceChild(nn, p.current)
        else: # fix #121
          p.parent.appendChild(nn)
    of pkSame:
      moveDom(p.newNode, p.oldNode)
    of pkRemove:
      p.parent.removeChild(p.current)
    of pkAppend:
      let nn = toDom(p.newNode, useAttachedNode = true, kxi)
      p.parent.appendChild(nn)
    of pkInsertBefore:
      let nn = toDom(p.newNode, useAttachedNode = true, kxi)
      p.parent.insertBefore(nn, p.current)
    of pkDetach:
      let n = p.oldNode
      if n.id != nil: kxi.byId.del(n.id)
      if n.kind == VNodeKind.component:
        let x = VComponent(n)
        if x.onDetachImpl != nil: x.onDetachImpl(x)
      # XXX for some reason this causes assertion errors otherwise:
      if not kxi.surpressRedraws: n.dom = nil
  kxi.patchLen = 0
  for i in 0..<kxi.patchLenV:
    let p = kxi.patchesV[i]
    p.parent[p.pos] = p.newChild
    assert p.newChild.dom != nil
  kxi.patchLenV = 0

# ASSUME: We patch both the virtual DOM and the real DOM and throw away
# the newly produced DOM. Thus on updates like 'newNode.dom = oldNode.dom'
# are required. The only exception is when the top level node is replaced.
# Then we have to take the new virtual DOM. In fact, we trigger a full DOM
# rebuild then. However, we don't have to consider old event handlers then
# so everything stays simple.
# We also do not produce "Patch sets" anymore, everything is done as simply
# as possible. Ok, let's assume that we seek to update event handler lists:
# The new node has captures to itself or to other new nodes, never to old
# nodes! --> We cannot ever use the old VDOM, we have to use the new virtual
# DOM. For identical nodes we need to take over the .dom field from the old
# node since we don't recompute them. This must be done recursively. In
# vnodeToDom we have to check whether the 'dom' field was already set. If so,
# There is nothing to do.
# "Similar" nodes can have the opposite effect; consider
#
# AAAABAAAA
# AAAACDAAAA
#
# In this example B did change to C and 'D' is new. However, replacing B by
# CD is fine.
#


proc diff(newNode, oldNode: VNode; parent, current: Node; kxi: KaraxInstance) =
  when defined(stats):
    if kxi.recursion > 100:
      echo "newNode ", newNode.kind, " oldNode ", oldNode.kind, " eq ", eq(newNode, oldNode, false)
      if oldNode.kind == VNodeKind.text:
        echo oldNode.text
    inc kxi.recursion
  let result = eq(newNode, oldNode, false)
  case result
  of componentsIdentical:
    kxi.components.add ComponentPair(oldNode: VComponent(oldNode),
                                      newNode: VComponent(newNode),
                                      parent: parent,
                                      current: current)
  of identical, similar:
    newNode.dom = oldNode.dom
    if result == similar:
      updateStyles(newNode, oldNode)
      updateAttributes(newNode, oldNode)

      if oldNode.kind == VNodeKind.text:
        oldNode.text = newNode.text
        oldNode.dom.nodeValue = newNode.text

      # Set the value of the input field to update
      if oldNode.kind == VNodeKind.input:
        oldNode.dom.value = newNode.text

        let checked = newNode.getAttr("checked")
        oldNode.dom.checked = if checked.isNil: false else: true

      # Set the value of the textarea field to update
      if oldNode.kind == VNodeKind.textarea:
        oldNode.dom.value = newNode.text

    if newNode.events.len != 0 or oldNode.events.len != 0:
      mergeEvents(newNode, oldNode, kxi)

    let newLength = newNode.len
    let oldLength = oldNode.len
    if newLength == 0 and oldLength == 0: return
    let minLength = min(newLength, oldLength)

    assert oldNode.kind == newNode.kind
    var commonPrefix = 0

    # compute common prefix:
    while commonPrefix < minLength:
      if eq(newNode[commonPrefix], oldNode[commonPrefix], true) == identical:
        kxi.addPatch(pkSame, nil, nil, newNode[commonPrefix], oldNode[commonPrefix])
        inc commonPrefix
      else:
        break

    # compute common suffix:
    var oldPos = oldLength - 1
    var newPos = newLength - 1
    while oldPos >= commonPrefix and newPos >= commonPrefix:
      if eq(newNode[newPos], oldNode[oldPos], true) == identical:
        kxi.addPatch(pkSame, nil, nil, newNode[newPos], oldNode[oldPos])
        dec oldPos
        dec newPos
      else:
        break

    let pos = min(oldPos, newPos) + 1
    # now the different children are in commonPrefix .. pos - 1:
    for i in commonPrefix..pos-1:
      diff(newNode[i], oldNode[i], current, oldNode[i].dom, kxi)

    if oldPos + 1 == oldLength:
      for i in pos..newPos:
        kxi.addPatch(pkAppend, current, nil, newNode[i], nil)
    else:
      let before = current.childNodes[oldPos + 1]
      for i in pos..newPos:
        kxi.addPatch(pkInsertBefore, current, before, newNode[i], nil)
    # XXX call 'attach' here?
    for i in pos..oldPos:
      detach(oldNode[i])
      #doAssert i < current.childNodes.len
      kxi.addPatch(pkRemove, current, current.childNodes[i], nil, nil)
  of different:
    detach(oldNode)
    kxi.addPatch(pkReplace, parent, current, newNode, nil)
  of usenewNode: doAssert(false, "eq returned usenewNode")
  when defined(stats):
    dec kxi.recursion

proc applyComponents(kxi: KaraxInstance) =
  # the first 'diff' pass detects components in the VDOM. The
  # 'applyComponents' expands components and so on until no
  # components are left to check.
  var i = 0
  # beware: 'diff' appends to kxi.components!
  # So this is actually a fixpoint iteration:
  while i < kxi.components.len:
    let x = kxi.components[i].oldNode
    let newNode = kxi.components[i].newNode
    when defined(karaxDebug):
      echo "Processing component ", newNode.text, " changed impl set ", x.changedImpl != nil
    if x.changedImpl != nil and x.changedImpl(x, newNode):
      when defined(karaxDebug):
        echo "Component ", newNode.text, " did change"
      let current = kxi.components[i].current
      let parent = kxi.components[i].parent
      x.updatedImpl(x, newNode)
      let oldExpanded = x.expanded
      x.expanded = x.renderImpl(x)
      when defined(karaxDebug):
        echo "Component ", newNode.text, " re-rendered"
      x.renderedVersion = x.version
      if oldExpanded == nil:
        detach(x)
        kxi.addPatch(pkReplace, parent, current, x.expanded, nil)
        when defined(karaxDebug):
          echo "Component ", newNode.text, ": old expansion didn't exist"
      else:
        diff(x.expanded, oldExpanded, parent, current, kxi)
        when false:
          if res == usenewNode:
            when defined(karaxDebug):
              echo "Component ", newNode.text, ": re-render triggered a DOM change (case A)"
            discard "diff created a patchset for us, so this is fine"
          elif res != different:
            when defined(karaxDebug):
              echo "Component ", newNode.text, ": re-render triggered no DOM change whatsoever"
            x.expanded = oldExpanded
            assert oldExpanded.dom != nil, "old expanded.dom is nil"
          else:
            when defined(karaxDebug):
              echo "Component ", newNode.text, ": re-render triggered a DOM change (case B)"
            assert x.expanded.dom != nil, "expanded.dom is nil"
    inc i
  setLen(kxi.components, 0)

when defined(stats):
  proc depth(n: VNode; total: var int): int =
    var m = 0
    for i in 0..<n.len:
      m = max(m, depth(n[i], total))
    result = m + 1
    inc total

proc runDel*(kxi: KaraxInstance; parent: VNode; position: int) =
  detach(parent[position])
  let current = parent.dom
  kxi.addPatch(pkRemove, current, current.childNodes[position], nil, nil)
  parent.delete(position)
  applyPatch(kxi)
  doAssert same(kxi.currentTree, document.getElementById(kxi.rootId))

proc runIns*(kxi: KaraxInstance; parent, kid: VNode; position: int) =
  let current = parent.dom
  if position >= parent.len:
    kxi.addPatch(pkAppend, current, nil, kid, nil)
    parent.add(kid)
  else:
    let before = current.childNodes[position]
    kxi.addPatch(pkInsertBefore, current, before, kid, nil)
    parent.insert(kid, position)
  applyPatch(kxi)
  doAssert same(kxi.currentTree, document.getElementById(kxi.rootId))

proc runDiff*(kxi: KaraxInstance; oldNode, newNode: VNode) =
  let olddom = oldNode.dom
  doAssert olddom != nil
  diff(newNode, oldNode, nil, olddom, kxi)
  # this is a bit nasty: Since we cannot patch the 'parent' of
  # the current VNode (because we don't store it at all!), we
  # need to override the fields individually:
  takeOverFields(newNode, oldNode)
  applyComponents(kxi)
  applyPatch(kxi)
  if kxi.currentTree == oldNode:
    kxi.currentTree = newNode
  doAssert same(kxi.currentTree, document.getElementById(kxi.rootId))

var onhashChange {.importc: "window.onhashchange".}: proc()
var hashPart {.importc: "window.location.hash".}: cstring
var queryString {.importc: "window.location.search".}: cstring

proc avoidDomDiffing*(kxi: KaraxInstance = kxi) =
  ## enforce a full redraw for the next redraw operation.
  ## This can be used as a temporary way to workaround DOM diffing
  ## problems or to avoid the DOM diffing when you already know
  ## it should use a completely new DOM.
  ## This is an experimental API.
  kxi.currentTree = nil

proc reqFrame(callback: proc()): int {.importc: "window.requestAnimationFrame".}
when false:
  proc cancelFrame(id: int) {.importc: "window.cancelAnimationFrame".}

proc dodraw(kxi: KaraxInstance) =
  if kxi.renderer.isNil: return
  kxi.renderId = 0

  if kxi.rendering:
    # there is a render already running, delay 1 frame
    kxi.renderId = reqFrame(proc () = kxi.dodraw)
    return

  kxi.rendering = true
  
  var rdata = RouterData()
  if cstring"?" in hashPart: 
    let hashSplit = hashPart.split(cstring"?")
    rdata.hashPart = hashSplit[0]
    rdata.queryString = join(hashSplit[1..^1], cstring"?")
  else:
    rdata.hashPart = hashPart
    rdata.queryString = queryString
    
  let newtree = kxi.renderer(rdata)
  inc kxi.runCount
  newtree.id = kxi.rootId
  kxi.toFocus = nil
  if kxi.currentTree == nil:
    let asdom = toDom(newtree, useAttachedNode = true, kxi)
    replaceById(kxi.rootId, asdom)
  else:
    when defined(debugKaraxSame):
      doAssert same(kxi.currentTree, document.getElementById(kxi.rootId))
    let olddom = document.getElementById(kxi.rootId)
    diff(newtree, kxi.currentTree, nil, olddom, kxi)
  when defined(profileKarax):
    echo "<<<<<<<<<<<<<<"
    echa reasons
  applyComponents(kxi)
  when defined(profileKarax):
    echo "--------------"
    echa reasons
    echo ">>>>>>>>>>>>>>"
  applyPatch(kxi)
  kxi.currentTree = newtree
  when defined(debugKaraxSame):
    doAssert same(kxi.currentTree, document.getElementById(kxi.rootId))

  if not kxi.postRenderCallback.isNil:
    kxi.postRenderCallback(rdata)

  # now that it's part of the DOM, give it the focus:
  if kxi.toFocus != nil:
    kxi.toFocus.focus()
  kxi.rendering = false
  when defined(stats):
    kxi.recursion = 0
    var total = 0
    echo "depth ", depth(kxi.currentTree, total), " total ", total

proc redraw*(kxi: KaraxInstance = kxi) =
  # we buffer redraw requests:
  when false:
    if drawTimeout != nil:
      clearTimeout(drawTimeout)
    drawTimeout = setTimeout(dodraw, 30)
  elif true:
    if kxi.renderId == 0:
      kxi.renderId = reqFrame(proc () = kxi.dodraw)
  else:
    dodraw(kxi)

proc redrawSync*(kxi: KaraxInstance = kxi) = dodraw(kxi)

proc init(ev: Event) =
  kxi.renderId = reqFrame(proc () = kxi.dodraw)

proc setRenderer*(renderer: proc (data: RouterData): VNode,
                  root: cstring = "ROOT",
                  clientPostRenderCallback:
                    proc (data: RouterData) = nil): KaraxInstance {.
                    discardable.} =
  ## Setup Karax. Usually the return value can be ignored.
  if document.getElementById(root).isNil:
    let msg = "Could not find a <div> with id=" & root &
              ". Karax needs it as its rendering target."
    raise newException(Exception, $msg)

  result = KaraxInstance(rootId: root, renderer: renderer,
                         postRenderCallback: clientPostRenderCallback,
                         patches: newSeq[Patch](60),
                         patchesV: newSeq[PatchV](30),
                         components: @[],
                         surpressRedraws: false,
                         byId: newJDict[cstring, VNode](),
                         orphans: newJDict[cstring, bool]())
  kxi = result
  window.addEventListener("load", init)
  onhashChange = proc() = redraw()

proc setRenderer*(renderer: proc (): VNode, root: cstring = "ROOT",
                  clientPostRenderCallback: proc () = nil): KaraxInstance {.discardable.} =
  ## Setup Karax. Usually the return value can be ignored.
  proc wrapRenderer(data: RouterData): VNode = result = renderer()
  proc wrapPostRender(data: RouterData) =
    if clientPostRenderCallback != nil: clientPostRenderCallback()
  setRenderer(wrapRenderer, root, wrapPostRender)

when not defined(js):
  import parseopt
  proc setRenderer*(renderer: proc (): VNode) =
    var op = initOptParser()
    var file = ""
    while true:
      op.next()
      case op.kind
      of cmdArgument: file = op.key
      of cmdEnd: break
      else: discard
      writeFile file, $renderer()

proc setInitializer*(renderer: proc (data: RouterData): VNode, root: cstring = "ROOT",
                    clientPostRenderCallback:
                      proc (data: RouterData) = nil): KaraxInstance {.discardable.} =
  ## Setup Karax. Usually the return value can be ignored.
  result = KaraxInstance(rootId: root, renderer: renderer,
                        postRenderCallback: clientPostRenderCallback,
                        patches: newSeq[Patch](60),
                        patchesV: newSeq[PatchV](30),
                        components: @[],
                        surpressRedraws: true,
                        byId: newJDict[cstring, VNode](),
                        orphans: newJDict[cstring, bool]())
  kxi = result
  window.onload = init

proc addEventHandler*(n: VNode; k: EventKind; action: EventHandler;
                      kxi: KaraxInstance = kxi) =
  ## Implements the foundation of Karax's event management.
  ## Karax DSL transforms ``tag(onEvent = handler)`` to
  ## ``tempNode.addEventHandler(tagNode, EventKind.onEvent, wrapper)``
  ## where ``wrapper`` calls the passed ``action`` and then triggers
  ## a ``redraw``.
  proc wrapper(ev: Event; n: VNode) =
    action(ev, n)
    if not kxi.surpressRedraws: redraw(kxi)
  addEventListener(n, k, wrapper)

proc addEventHandler*(n: VNode; k: EventKind; action: proc();
                      kxi: KaraxInstance = kxi) =
  ## Implements the foundation of Karax's event management.
  ## Karax DSL transforms ``tag(onEvent = handler)`` to
  ## ``tempNode.addEventHandler(tagNode, EventKind.onEvent, wrapper)``
  ## where ``wrapper`` calls the passed ``action`` and then triggers
  ## a ``redraw``.
  proc wrapper(ev: Event; n: VNode) =
    action()
    if not kxi.surpressRedraws: redraw(kxi)
  addEventListener(n, k, wrapper)

proc addEventHandlerNoRedraw*(n: VNode; k: EventKind; action: EventHandler) =
  addEventListener(n, k, action)

proc addEventHandlerNoRedraw*(n: VNode; k: EventKind; action: proc()) =
  proc wrapper(ev: Event; n: VNode) =
    action()
  addEventListener(n, k, wrapper)

proc setOnHashChange*(action: proc (hashPart: cstring)) {.deprecated: "use setRenderer instead".} =
  ## Now deprecated, instead pass a callback to ``setRenderer`` that receives
  ## a ``data: RouterData`` parameter.
  proc wrapper() =
    action(hashPart)
    redraw()
  onhashchange = wrapper

proc setForeignNodeId*(id: cstring; kxi: KaraxInstance = kxi) =
  ## Declares a node ID as "foreign". Foreign nodes are not
  ## under Karax's control in the sense that Karax does not attempt
  ## to perform structural checks on them.
  kxi.orphans[id] = true

{.push stackTrace:off.}
proc setupErrorHandler*() =
  ## Installs an error handler that transforms native JS unhandled
  ## exceptions into Nim based stack traces. If `useAlert` is false,
  ## the error message is put into the console, otherwise `alert`
  ## is called.
  proc stackTraceAsCstring(): cstring = cstring(getStackTrace())
  var onerror {.importc: "window.onerror", used.} =
    proc (msg, url: cstring, line, col: int, error: cstring): bool =
      var x = cstring"Error: " & msg & "\n" & stackTraceAsCstring()
      echo(x)
      return true # suppressErrorAlert
{.pop.}

proc prepend(parent, kid: Element) =
  parent.insertBefore(kid, parent.firstChild)

proc loadScript*(jsfilename: cstring; kxi: KaraxInstance = kxi) =
  let s = document.createElement("script")
  s.setAttr "type", "text/javascript"
  s.setAttr "src", jsfilename
  document.body.prepend(s)
  redraw(kxi)

proc runLater*(action: proc(); later = 400): Timeout {.discardable.} =
  proc wrapper() =
    action()
    redraw()
  result = setTimeout(wrapper, later)

proc setInputText*(n: VNode; s: cstring) =
  ## Sets the text of input elements.
  n.text = s
  if n.dom != nil: n.dom.value = s

proc getInputText*(n: VNode): cstring =
  if n.dom != nil:
    result = n.dom.value

proc toChecked*(checked: bool): cstring =
  (if checked: cstring"checked" else: cstring(nil))

proc toDisabled*(disabled: bool): cstring =
  (if disabled: cstring"disabled" else: cstring(nil))

proc toSelected*(selected: bool): cstring =
  (if selected: cstring"selected" else: cstring(nil))

proc toAttr*(value: bool): cstring =
  (if value: cstring"true" else: cstring(nil))

proc vnodeToDom*(n: VNode; kxi: KaraxInstance = nil): Node =
  result = toDom(n, useAttachedNode = false, kxi)
