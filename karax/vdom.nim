## Virtual DOM implementation for Karax.

when defined(js):
  from kdom import Event, Node
else:
  type
    Event* = ref object
    Node* = ref object

import macros, vstyles, kbase
from strutils import toUpperAscii, toLowerAscii, tokenize

type
  VNodeKind* {.pure.} = enum
    text = "#text", int = "#int", bool = "#bool",
    vthunk = "#vthunk", dthunk = "#dthunk",
    component = "#component", verbatim = "#verbatim",

    html, head, title, base, link, meta, style,
    script, noscript,
    body, section, nav, article, aside,
    h1, h2, h3, h4, h5, h6, hgroup,
    header, footer, address, main,

    p, hr, pre, blockquote, ol, ul, li,
    dl, dt, dd,
    figure, figcaption,

    tdiv = "div",

    a, em, strong, small,
    strikethrough = "s", cite, quote,
    dfn, abbr, data, time, code, `var` = "var", samp,
    kbd, sub, sup, italic = "i", bold = "b", underlined = "u",
    mark, ruby, rt, rp, bdi, dbo, span, br, wbr,
    ins, del, img, iframe, embed, `object` = "object",
    param, video, audio, source, track, canvas, map, area,

    # SVG elements, see: https://www.w3.org/TR/SVG2/eltindex.html
    animate, animateMotion, animateTransform, circle, clipPath, defs, desc,
    `discard` = "discard", ellipse, feBlend, feColorMatrix, feComponentTransfer,
    feComposite, feConvolveMatrix, feDiffuseLighting, feDisplacementMap,
    feDistantLight, feDropShadow, feFlood, feFuncA, feFuncB, feFuncG, feFuncR,
    feGaussianBlur, feImage, feMerge, feMergeNode, feMorphology, feOffset,
    fePointLight, feSpecularLighting, feSpotLight, feTile, feTurbulence,
    filter, foreignObject, g, image, line, linearGradient, marker, mask,
    metadata, mpath, path, pattern, polygon, polyline, radialGradient, rect,
    `set` = "set", stop, svg, switch, symbol, stext = "text", textPath, tspan,
    unknown, use, view,

    # MathML elements
    maction, math, menclose, merror, mfenced, mfrac, mglyph, mi, mlabeledtr,
    mmultiscripts, mn, mo, mover, mpadded, mphantom, mroot, mrow, ms, mspace,
    msqrt, mstyle, msub, msubsup, msup, mtable, mtd, mtext, mtr, munder,
    munderover, semantics,

    table, caption, colgroup, col, tbody, thead,
    tfoot, tr, td, th,

    form, fieldset, legend, label, input, button,
    select, datalist, optgroup, option, textarea,
    keygen, output, progress, meter,
    details, summary, command, menu,

    bdo, dialog, slot, `template`="template"

const
  selfClosing = {area, base, br, col, embed, hr, img, input,
    link, meta, param, source, track, wbr}

  svgElements* = {animate .. view}
  mathElements* = {maction .. semantics}

var
  svgNamespace* = "http://www.w3.org/2000/svg"
  mathNamespace* = "http://www.w3.org/1998/Math/MathML"

type
  EventKind* {.pure.} = enum ## The events supported by the virtual DOM.
    onclick, ## An element is clicked.
    oncontextmenu, ## An element is right-clicked.
    ondblclick, ## An element is double clicked.
    onkeyup, ## A key was released.
    onkeydown, ## A key is pressed.
    onkeypressed, ## A key was pressed.
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

    onanimationstart,
    onanimationend,
    onanimationiteration,

    onkeyupenter, ## vdom extension: an input field received the ENTER key press
    onkeyuplater,  ## vdom extension: a key was pressed and some time
                  ## passed (useful for on-the-fly text completions)
    onload, ## img

    ontransitioncancel,
    ontransitionend,
    ontransitionrun,
    ontransitionstart,

    onpaste,

    onwheel ## fires when the user rotates a wheel button on a pointing device.

const
  toTag* = block:
    var res: array[VNodeKind, kstring]
    for kind in VNodeKind:
      res[kind] = kstring($kind)
    res

  toEventName* = block:
    var res: array[EventKind, kstring]
    for kind in EventKind:
      res[kind] = kstring(($kind)[2..^1])
    res

type
  EventHandler* = proc (ev: Event; target: VNode) {.closure.}
  NativeEventHandler* = proc (ev: Event) {.closure.}

  EventHandlers* = seq[(EventKind, EventHandler, NativeEventHandler)]

  VKey* = kstring

  VNode* = ref object of RootObj
    kind*: VNodeKind
    index*: int ## a generally useful 'index'
    id*, class*, text*: kstring
    kids: seq[VNode]
    # even index: key, odd index: value; done this way for memory efficiency:
    attrs: seq[kstring]
    events*: EventHandlers
    when false:
      hash*: Hash
      validHash*: bool
    style*: VStyle ## the style that should be applied to the virtual node.
    styleVersion*: int
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
    version*: int         ## Update this to trigger a redraw by karax. Usually you
                          ## should call 'markDirty' instead which is an alias for
                          ## 'inc version'.
    renderedVersion*: int ## Do not touch. Used by karax. The last version of the
                          ## component we rendered.
    expanded*: VNode      ## Do not touch. Used by karax. The VDOM the component
                          ## expanded to.
    debugId*: int

proc value*(n: VNode): kstring = n.text
proc `value=`*(n: VNode; v: kstring) = n.text = v

proc intValue*(n: VNode): int = n.index
proc vn*(i: int): VNode = VNode(kind: VNodeKind.int, index: i)
proc vn*(b: bool): VNode = VNode(kind: VNodeKind.int, index: ord(b))
proc vn*(x: kstring): VNode = VNode(kind: VNodeKind.text, index: -1, text: x)

template callThunk*(fn: typed; n: VNode): untyped =
  ## for internal usage only.
  fn(n.kids)

proc vthunk*(name: kstring; args: varargs[VNode, vn]): VNode =
  VNode(kind: VNodeKind.vthunk, text: name, index: -1, kids: @args)

proc dthunk*(dom: Node): VNode =
  VNode(kind: VNodeKind.dthunk, dom: dom)

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
    text: kstring(astToStr(t)), renderImpl: render,
    changedImpl: changed, updatedImpl: updated,
    onAttachImpl: onAttach, onDetachImpl: onDetach,
    debugId: getDebugId())

template markDirty*(c: VComponent) =
  ## mark the component as dirty so that it is re-rendered.
  inc c.version

proc setAttr*(n: VNode; key: kstring; val: kstring = "") =
  if n.attrs.len == 0:
    n.attrs = @[key, val]
  else:
    for i in countup(0, n.attrs.len-2, 2):
      if n.attrs[i] == key:
        n.attrs[i+1] = val
        return
    n.attrs.add key
    n.attrs.add val

proc setAttr*(n: VNode, key: kstring, val: bool) =
  when defined(js):
    n.setAttr(key, if val: cstring"" else: cstring(nil))
  else:
    if val:
      n.setAttr(key, "")
    else:
      for i in countup(0, n.attrs.len-2, 2):
        if n.attrs[i] == key:
          n.attrs.delete i+1
          n.attrs.delete i
          break

proc getAttr*(n: VNode; key: kstring): kstring =
  for i in countup(0, n.attrs.len-2, 2):
    if n.attrs[i] == key: return n.attrs[i+1]

proc takeOverAttr*(newNode, oldNode: VNode) =
  when defined(gcArc) or defined(gcOrc):
    oldNode.attrs = move newNode.attrs
  else:
    shallowCopy oldNode.attrs, newNode.attrs

proc takeOverFields*(newNode, oldNode: VNode) =
  template take(field) =
    when defined(gcArc) or defined(gcOrc):
      oldNode.field = move newNode.field
    else:
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
  take styleVersion
  take dom

proc len*(x: VNode): int = x.kids.len
proc `[]`*(x: VNode; idx: int): VNode = x.kids[idx]
proc `[]=`*(x: VNode; idx: int; y: VNode) = x.kids[idx] = y

proc add*(parent, kid: VNode) =
  when not defined(js) and not defined(nimNoNil):
    if parent.kids.isNil: parent.kids = @[]
  parent.kids.add kid

proc delete*(parent: VNode; position: int) =
  parent.kids.delete(position)
proc insert*(parent, kid: VNode; position: int) =
   parent.kids.insert(kid, position)
proc newVNode*(kind: VNodeKind): VNode = VNode(kind: kind, index: -1)

proc tree*(kind: VNodeKind; kids: varargs[VNode]): VNode =
  result = newVNode(kind)
  for k in kids: result.add k

proc tree*(kind: VNodeKind; attrs: openarray[(kstring, kstring)];
           kids: varargs[VNode]): VNode =
  result = tree(kind, kids)
  for a in attrs: result.setAttr(a[0], a[1])

when defined(js):
  proc text*(s: string): VNode = VNode(kind: VNodeKind.text, text: kstring(s), index: -1)
proc text*(s: kstring): VNode = VNode(kind: VNodeKind.text, text: s, index: -1)

when defined(js):
  proc verbatim*(s: string): VNode =
    VNode(kind: VNodeKind.verbatim, text: kstring(s), index: -1)
proc verbatim*(s: kstring): VNode =
  VNode(kind: VNodeKind.verbatim, text: s, index: -1)


iterator items*(n: VNode): VNode =
  for i in 0..<n.kids.len: yield n.kids[i]

iterator attrs*(n: VNode): (kstring, kstring) =
  for i in countup(0, n.attrs.len-2, 2):
    yield (n.attrs[i], n.attrs[i+1])

proc sameAttrs*(a, b: VNode): bool =
  if a.attrs.len == b.attrs.len:
    result = true
    for i in 0 ..< a.attrs.len:
      if a.attrs[i] != b.attrs[i]: return false

proc addEventListener*(n: VNode; event: EventKind; handler: EventHandler) =
  n.events.add((event, handler, nil))

when kstring is cstring:
  proc len(a: kstring): int =
    # xxx: maybe move where kstring is defined
    # without this, `n.field.len` fails on js (non web) platform
    if a == nil: 0 else: system.len(a)

template toStringAttr(field) =
  if n.field.len > 0:
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
    if n.text.len > 0:
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


proc add*(result: var string, n: VNode, indent = 0, indWidth = 2) =
  ## adds the textual representation of `n` to `result`.

  proc addEscapedAttr(result: var string, s: kstring) =
    # `addEscaped` alternative with less escaped characters.
    # Only to be used for escaping attribute values enclosed in double quotes!
    for c in items(s):
      case c
      of '<': result.add("&lt;")
      of '>': result.add("&gt;")
      of '&': result.add("&amp;")
      of '"': result.add("&quot;")
      else: result.add(c)

  proc addEscaped(result: var string, s: kstring) =
    ## same as ``result.add(escape(s))``, but more efficient.
    for c in items(s):
      case c
      of '<': result.add("&lt;")
      of '>': result.add("&gt;")
      of '&': result.add("&amp;")
      of '"': result.add("&quot;")
      of '\'': result.add("&#x27;")
      of '/': result.add("&#x2F;")
      else: result.add(c)

  proc addIndent(result: var string, indent: int) =
    result.add("\n")
    for i in 1..indent: result.add(' ')

  if n.kind == VNodeKind.text:
    result.addEscaped(n.text)
  elif n.kind == VNodeKind.verbatim:
    result.add(n.text)
  else:
    let kind = $n.kind
    result.add('<')
    result.add(kind)
    if n.id.len > 0:
      result.add " id=\""
      result.addEscapedAttr(n.id)
      result.add('"')
    if n.class.len > 0:
      result.add " class=\""
      result.addEscapedAttr(n.class)
      result.add('"')
    for k, v in attrs(n):
      result.add(' ')
      result.add(k)
      result.add("=\"")
      result.addEscapedAttr(v)
      result.add('"')
    if n.style != nil:
      result.add " style=\""
      for k, v in pairs(n.style):
        if v.len == 0: continue
        for t in tokenize($k, seps={'A' .. 'Z'}):
          if t.isSep: result.add '-'
          result.add toLowerAscii(t.token)
        result.add ": "
        result.add v
        result.add "; "
      result.add('"')
    if n.len > 0:
      result.add('>')
      if n.len > 1:
        var noWhitespace = false
        for i in 0..<n.len:
          if n[i].kind == VNodeKind.text:
            noWhitespace = true
            break

        if noWhitespace:
          # for mixed leaves, we cannot output whitespace for readability,
          # because this would be wrong. For example: ``a<b>b</b>`` is
          # different from ``a <b>b</b>``.
          for i in 0..<n.len: result.add(n[i], indent+indWidth, indWidth)
        else:
          for i in 0..<n.len:
            result.addIndent(indent+indWidth)
            result.add(n[i], indent+indWidth, indWidth)
          result.addIndent(indent)
      else:
        result.add(n[0], indent+indWidth, indWidth)
      result.add("</")
      result.add(kind)
      result.add(">")
    elif n.kind in selfClosing:
      result.add(" />")
    else:
      result.add(">")
      result.add("</")
      result.add(kind)
      result.add(">")


proc `$`*(n: VNode): kstring =
  when defined(js):
    var res = ""
    toString(n, res, 0)
    result = kstring(res)
  else:
    result = ""
    add(result, n)

proc getVNodeById*(n: VNode; id: cstring): VNode =
  ## Get the VNode that was marked with ``id``. Returns ``nil``
  ## if no node exists.
  if n.id == id: return n
  for i in 0..<n.len:
    result = getVNodeById(n[i], id)
    if result != nil: return result
