## Virtual DOM implementation for Karax.

from kdom import Event, Node
import shash, macros, vstyles
from strutils import toUpperAscii

type
  VNodeKind* {.pure.} = enum
    text = "#text", int = "#int", bool = "#bool",
    vthunk = "#vthunk", dthunk = "#dthunk",
    component = "#component",

    html, head, title, base, link, meta, style,
    script, noscript,
    body, section, nav, article, aside,
    h1, h2, h3, h4, h5, h6,
    header, footer, address, main

    p, hr, pre, blockquote, ol, ul, li,
    dl, dt, dd,
    figure, figcaption,

    tdiv = "div",

    a, em, strong, small,
    strikethrough = "s", cite, quote,
    dfn, abbr, data, time, code, `var` = "var", samp,
    kdb, sub, sup, italic = "i", bold = "b", underlined = "u",
    mark, ruby, rt, rp, bdi, dbo, span, br, wbr,
    ins, del, img, iframe, embed, `object` = "object",
    param, video, audio, source, track, canvas, map,
    area, svg, math,

    table, caption, colgroup, col, tbody, thead,
    tfoot, tr, td, th,

    form, fieldset, legend, label, input, button,
    select, datalist, optgroup, option, textarea,
    keygen, output, progress, meter,
    details, summary, command, menu

type
  EventKind* {.pure.} = enum ## The events supported by the virtual DOM.
    onclick, ## An element is clicked.
    oncontextmenu, ## An element is right-clicked.
    ondblclick, ## An element is double clicked.
    onkeyup, ## A key was released.
    onkeydown, ## A key is pressed.
    onkeypressed, # A key was pressed.
    onfocus, ## An element got the focus.
    onblur, ## An element lost the focus.
    onchange, ## The selected value of an element was changed.
    onscroll, ## The user scrolled within an element.

    onmousedown, ## A pointing device button (usually a mouse) is pressed
                 ## on an element.
    onmouseenter, ## A pointing device is moved onto the element that
                  ## has the listener attached.
    onmouseleave, ## A pointing device is moved off the element that
                  ## has the listener attached.
    onmousemove, ## A pointing device is moved over an element.
    onmouseout, ## A pointing device is moved off the element that
                ## has the listener attached or off one of its children.
    onmouseover, ## A pointing device is moved onto the element that has
                 ## the listener attached or onto one of its children.
    onmouseup, ## A pointing device button is released over an element.

    ondrag,  ## An element or text selection is being dragged (every 350ms).
    ondragend, ## A drag operation is being ended (by releasing a mouse button
               ## or hitting the escape key).
    ondragenter, ## A dragged element or text selection enters a valid drop target.
    ondragleave, ## A dragged element or text selection leaves a valid drop target.
    ondragover, ## An element or text selection is being dragged over a valid
                ## drop target (every 350ms).
    ondragstart, ## The user starts dragging an element or text selection.
    ondrop, ## An element is dropped on a valid drop target.

    onsubmit, ## A form is submitted
    oninput, ## An input value changes

    onkeyupenter, ## vdom extension: an input field received the ENTER key press
    onkeyuplater  ## vdom extension: a key was pressed and some time
                  ## passed (useful for on-the-fly text completions)


macro buildLookupTables(): untyped =
  var a = newTree(nnkBracket)
  for i in low(VNodeKind)..high(VNodeKind):
    let x = $i
    let y = if x[0] == '#': x else: toUpperAscii(x)
    a.add(newCall("cstring", newLit(y)))
  var e = newTree(nnkBracket)
  for i in low(EventKind)..high(EventKind):
    e.add(newCall("cstring", newLit(substr($i, 2))))

  template tmpl(a, e) {.dirty.} =
    const
      toTag*: array[VNodeKind, cstring] = a
      toEventName*: array[EventKind, cstring] = e

  result = getAst tmpl(a, e)

buildLookupTables()

type
  EventHandler* = proc (ev: Event; target: VNode) {.closure.}
  NativeEventHandler* = proc (ev: Event) {.closure.}

  EventHandlers* = seq[(EventKind, EventHandler, NativeEventHandler)]

  VKey* = cstring

  VNode* = ref object of RootObj
    kind*: VNodeKind
    index*: int ## a generally useful 'index'
    id*, class*, text*: cstring
    kids: seq[VNode]
    # even index: key, odd index: value; done this way for memory efficiency:
    attrs: seq[cstring]
    events*: EventHandlers
    when false:
      hash*: Hash
      validHash*: bool
    style*: VStyle ## the style that should be applied to the virtual node.
    dom*: Node ## the attached real DOM node. Can be 'nil' if the virtual node
               ## is not part of the virtual DOM anymore.

  VComponent* = ref object of VNode ## The abstract class for every karax component.
    key*: VKey                      ## key that determines if two components are
                                    ## identical.
    renderImpl*: proc(self: VComponent): VNode
    changedImpl*: proc(self, newInstance: VComponent): bool
    updatedImpl*: proc(self, newInstance: VComponent)
    onAttachImpl*: proc(self: VComponent)
    onDetachImpl*: proc(self: VComponent)
    realDomImpl*: proc(self: VComponent): kdom.Node
    version*: int         ## Update this to trigger a redraw by karax. Usually you
                          ## should call 'markDirty' instead which is an alias for
                          ## 'inc version'.
    renderedVersion*: int ## Do not touch. Used by karax. The last version of the
                          ## component we rendered.
    expanded*: VNode      ## Do not touch. Used by karax. The VDOM the component
                          ## expanded to.
    debugId*: int

proc value*(n: VNode): cstring = n.text
proc `value=`*(n: VNode; v: cstring) = n.text = v

proc intValue*(n: VNode): int = n.index
proc vn*(i: int): VNode = VNode(kind: VNodeKind.int, index: i)
proc vn*(b: bool): VNode = VNode(kind: VNodeKind.int, index: ord(b))
proc vn*(x: cstring): VNode = VNode(kind: VNodeKind.text, index: -1, text: x)

template callThunk*(fn: typed; n: VNode): untyped =
  ## for internal usage only.
  fn(n.kids)

proc vthunk*(name: cstring; args: varargs[VNode, vn]): VNode =
  VNode(kind: VNodeKind.vthunk, text: name, index: -1, kids: @args)

proc dthunk*(name: cstring; args: varargs[VNode, vn]): VNode =
  VNode(kind: VNodeKind.dthunk, text: name, index: -1, kids: @args)

proc setEventIfNoConflict(v: VNode; kind: EventKind; handler: EventHandler) =
  assert handler != nil
  for i in 0..<v.events.len:
    if v.events[i][0] == kind:
      #v.events[i][1] = handler
      return
  v.events.add((kind, handler, nil))

proc mergeEvents*(v: VNode; handlers: EventHandlers) =
  ## Overrides or adds the event handlers to `v`'s internal event handler list.
  for h in handlers: v.setEventIfNoConflict(h[0], h[1])

proc defaultChangedImpl*(v, newInstance: VComponent): bool =
  ## The default implementation of 'changed'.
  result = v.key != newInstance.key or v.version != v.renderedVersion

proc defaultUpdatedImpl*(v, newInstance: VComponent) =
  discard

var gid = 0
proc getDebugId(): int =
  inc(gid)
  gid

template newComponent*[T](t: typeDesc[T];
                 render: (proc(self: VComponent): VNode) = nil,
                 onAttach: proc(self: VComponent) = nil,
                 onDetach: proc(self: VComponent) = nil,
                 changed: (proc(self, newInstance: VComponent): bool) = defaultChangedImpl,
                 updated: proc(self, newInstance: VComponent) = defaultUpdatedImpl): T =
  ## Use this template to create new components.
  T(kind: VNodeKind.component, index: -1,
    text: cstring(astToStr(t)), renderImpl: render,
    changedImpl: changed, updatedImpl: updated,
    onAttachImpl: onAttach, onDetachImpl: onDetach,
    debugId: getDebugId())

template markDirty*(c: VComponent) =
  ## mark the component as dirty so that it is re-rendered.
  inc c.version

proc setAttr*(n: VNode; key: cstring; val: cstring = "") =
  if n.attrs.isNil:
    n.attrs = @[key, val]
  else:
    for i in countup(0, n.attrs.len-2, 2):
      if n.attrs[i] == key:
        n.attrs[i+1] = val
        return
    n.attrs.add key
    n.attrs.add val

proc getAttr*(n: VNode; key: cstring): cstring =
  for i in countup(0, n.attrs.len-2, 2):
    if n.attrs[i] == key: return n.attrs[i+1]

proc takeOverAttr*(newNode, oldNode: VNode) =
  shallowCopy oldNode.attrs, newNode.attrs

proc takeOverFields*(newNode, oldNode: VNode) =
  template take(field) =
    shallowCopy oldNode.field, newNode.field
  take kind
  take index
  take id
  take class
  take text
  take kids
  take attrs
  take events
  take style
  take dom

proc len*(x: VNode): int = x.kids.len
proc `[]`*(x: VNode; idx: int): VNode = x.kids[idx]
proc `[]=`*(x: VNode; idx: int; y: VNode) = x.kids[idx] = y
proc add*(parent, kid: VNode) = parent.kids.add kid
proc delete*(parent: VNode; position: int) =
  parent.kids.delete(position)
proc insert*(parent, kid: VNode; position: int) =
   parent.kids.insert(kid, position)
proc newVNode*(kind: VNodeKind): VNode = VNode(kind: kind, index: -1)

proc tree*(kind: VNodeKind; kids: varargs[VNode]): VNode =
  result = newVNode(kind)
  for k in kids: result.add k

proc tree*(kind: VNodeKind; attrs: openarray[(cstring, cstring)];
           kids: varargs[VNode]): VNode =
  result = tree(kind, kids)
  for a in attrs: result.setAttr(a[0], a[1])

proc text*(s: string): VNode = VNode(kind: VNodeKind.text, text: cstring(s), index: -1)
proc text*(s: cstring): VNode = VNode(kind: VNodeKind.text, text: s, index: -1)

iterator items*(n: VNode): VNode =
  for i in 0..<n.kids.len: yield n.kids[i]

iterator attrs*(n: VNode): (cstring, cstring) =
  for i in countup(0, n.attrs.len-2, 2):
    yield (n.attrs[i], n.attrs[i+1])

proc sameAttrs*(a, b: VNode): bool =
  if a.attrs.len == b.attrs.len:
    result = true
    for i in 0 ..< a.attrs.len:
      if a.attrs[i] != b.attrs[i]: return false

proc addEventListener*(n: VNode; event: EventKind; handler: EventHandler) =
  n.events.add((event, handler, nil))

template toStringAttr(field) =
  if n.field != nil:
    result.add " " & astToStr(field) & " = " & $n.field

proc toString*(n: VNode; result: var string; indent: int) =
  for i in 1..indent: result.add ' '
  if result.len > 0: result.add '\L'
  result.add "<" & $n.kind
  toStringAttr(id)
  toStringAttr(class)
  for k, v in attrs(n):
    result.add " " & $k & " = " & $v
  result.add ">\L"
  if n.kind == VNodeKind.text:
    result.add n.text
  else:
    if n.text != nil:
      result.add " value = "
      result.add n.text
    for child in items(n):
      toString(child, result, indent+2)
  for i in 1..indent: result.add ' '
  result.add "\L</" & $n.kind & ">"

when false:
  proc calcHash*(n: VNode) =
    if n.validHash: return
    n.validHash = true
    var h: Hash = ord n.kind
    if n.id != nil:
      h &= "id"
      h &= n.id
    if n.class != nil:
      h &= "class"
      h &= n.class
    if n.key >= 0:
      h &= "k"
      h &= n.key
    for k, v in attrs(n):
      h &= " "
      h &= k
      h &= "="
      h &= v
    if n.kind == VNodeKind.text or n.text != nil:
      h &= "t"
      h &= n.text
    else:
      for child in items(n):
        calcHash(child)
        h &= child.hash
    n.hash = h

proc `$`*(n: VNode): cstring =
  var res = ""
  toString(n, res, 0)
  result = cstring(res)
