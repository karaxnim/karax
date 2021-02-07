## Raw DOM manipulation. No DOM diff'ing, no cry.

import std / [macros, tables, dom]
from std / strutils import startsWith, toLowerAscii

when defined(js):
  type kstring* = cstring
else:
  type kstring* = string

type
  Tag* {.pure.} = enum
    text = "#text",

    html, head, title, base, link, meta, style,
    script, noscript,
    body, section, nav, article, aside,
    h1, h2, h3, h4, h5, h6,
    header, footer, address, main,

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
    param, video, audio, source, track, canvas, map, area,

    # SVG elements
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
    details, summary, command, menu

type
  EventKind* {.pure.} = enum ## The events supported by the DOM.
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

    onwheel ## fires when the user rotates a wheel button on a pointing device.

macro buildLookupTables(): untyped =
  var a = newTree(nnkBracket)
  for i in low(Tag)..high(Tag):
    let x = $i
    let y = if x[0] == '#': x else: toLowerAscii(x)
    a.add(newCall("kstring", newLit(y)))
  var e = newTree(nnkBracket)
  for i in low(EventKind)..high(EventKind):
    e.add(newCall("kstring", newLit(substr($i, 2))))

  template tmpl(a, e) {.dirty.} =
    const
      toTagName*: array[Tag, kstring] = a
      toEventName*: array[EventKind, kstring] = e

  result = getAst tmpl(a, e)

buildLookupTables()

# ---------------- CSS ----------------------------------------------

type
  StyleAttr* {.pure.} = enum
    ## The style attributes supported by the virtual DOM.
    ## Reference: https://www.w3schools.com/jsref/dom_obj_style.asp
    alignContent
    alignItems
    alignSelf
    animation
    animationDelay
    animationDirection
    animationDuration
    animationFillMode
    animationIterationCount
    animationName
    animationTimingFunction
    animationPlayState
    background
    backgroundAttachment
    backgroundColor
    backgroundImage
    backgroundPosition
    backgroundRepeat
    backgroundClip
    backgroundOrigin
    backgroundSize
    backfaceVisibility
    border
    borderBottom
    borderBottomColor
    borderBottomLeftRadius
    borderBottomRightRadius
    borderBottomStyle
    borderBottomWidth
    borderCollapse
    borderColor
    borderImage
    borderImageOutset
    borderImageRepeat
    borderImageSlice
    borderImageSource
    borderImageWidth
    borderLeft
    borderLeftColor
    borderLeftStyle
    borderLeftWidth
    borderRadius
    borderRight
    borderRightColor
    borderRightStyle
    borderRightWidth
    borderSpacing
    borderStyle
    borderTop
    borderTopColor
    borderTopLeftRadius
    borderTopRightRadius
    borderTopStyle
    borderTopWidth
    borderWidth
    bottom
    boxDecorationBreak
    boxShadow
    boxSizing
    captionSide
    clear
    clip
    color
    columnCount
    columnFill
    columnGap
    columnRule
    columnRuleColor
    columnRuleStyle
    columnRuleWidth
    columns
    columnSpan
    columnWidth
    content
    counterIncrement
    counterReset
    cursor
    direction
    display
    emptyCells
    filter
    flex
    flexBasis
    flexDirection
    flexFlow
    flexGrow
    flexShrink
    flexWrap
    cssFloat
    font
    fontFamily
    fontSize
    fontSizeAdjust
    fontStretch
    fontStyle
    fontVariant
    fontWeight
    hangingPunctuation
    height
    hyphens
    icon
    imageOrientation
    justifyContent
    left
    letterSpacing
    lineHeight
    listStyle
    listStyleImage
    listStylePosition
    listStyleType
    margin
    marginBottom
    marginLeft
    marginRight
    marginTop
    maxHeight
    maxWidth
    minHeight
    minWidth
    navDown
    navIndex
    navLeft
    navRight
    navUp
    opacity
    order
    orphans
    outline
    outlineColor
    outlineOffset
    outlineStyle
    outlineWidth
    overflow
    overflowX
    overflowY
    padding
    paddingBottom
    paddingLeft
    paddingRight
    paddingTop
    pageBreakAfter
    pageBreakBefore
    pageBreakInside
    perspective
    perspectiveOrigin
    pointerEvents
    position
    quotes
    resize
    right
    scrollbar3dLightColor # note: missing in w3schools reference
    scrollbarArrowColor # note: missing in w3schools reference
    scrollbarBaseColor # note: missing in w3schools reference
    scrollbarDarkshadowColor # note: missing in w3schools reference
    scrollbarFaceColor # note: missing in w3schools reference
    scrollbarHighlightColor # note: missing in w3schools reference
    scrollbarShadowColor # note: missing in w3schools reference
    scrollbarTrackColor # note: missing in w3schools reference
    tableLayout
    tabSize
    textAlign
    textAlignLast
    textDecoration
    textDecorationColor
    textDecorationLine
    textDecorationStyle
    textIndent
    textJustify
    textOverflow
    textShadow
    textTransform
    top
    transform
    transformOrigin
    transformStyle
    transition
    transitionDelay
    transitionDuration
    transitionProperty
    transitionTimingFunction
    unicodeBidi
    userSelect
    verticalAlign
    visibility
    whiteSpace
    width
    wordBreak
    wordSpacing
    wordWrap
    widows
    zIndex

macro buildStyleLookupTable(): untyped =
  var e = newTree(nnkBracket)
  for i in low(StyleAttr)..high(StyleAttr):
    e.add(newCall("kstring", newLit($i)))
  template tmpl(e) {.dirty.} =
    const
      toStyleAttrName: array[StyleAttr, kstring] = e
  result = getAst tmpl(e)

buildStyleLookupTable()

proc setStyle(s: Style; key, val: cstring) {.importcpp: "#[#] = #", noSideEffect.}

proc applyStyles*(e: Element; pairs: openArray[(StyleAttr, kstring)]) =
  for x in pairs:
    e.style.setStyle(toStyleAttrName[x[0]], x[1])

# ------------------ Namespaces --------------------------------------

type
  Namespace* {.pure.} = enum
    none, html, mathml, svg

const
  toNS*: array[Namespace, kstring] = [
    Namespace.none: kstring"",
    Namespace.html: kstring"http://www.w3.org/1999/xhtml",
    Namespace.mathml: kstring"http://www.w3.org/1998/Math/MathML",
    Namespace.svg: kstring"http://www.w3.org/2000/svg"
  ]

proc getNamespace*(s: kstring): Namespace =
  # Use with element.namespaceURI
  let i = find(toNS, s)
  if i >= 0: result = Namespace(i)
  else: result = Namespace.none

proc getNamespace*(kind: Tag): Namespace =
  case kind
  of Tag.svg:
    result = Namespace.svg
  of Tag.math:
    result = Namespace.mathml
  else:
    result = Namespace.none

proc getChildNamespace*(parentNamespace: Namespace; kind: Tag): Namespace =
  if parentNamespace in {Namespace.none, Namespace.html}:
    result = getNamespace(kind)
  elif parentNamespace == Namespace.svg and kind == Tag.foreignObject:
    result = Namespace.html
  else: result = parentNamespace

# ------- Tree manipulation ---------------------------

proc parent*(x: Element): Element {.importcpp: "#.parentNode".}
proc up*(x: Element; className: cstring): Element =
  result = x
  while result != nil and result.class != className:
    result = result.parent
proc add*(n, child: Node) {.importcpp: "appendChild".}
proc replace*(self, by: Element) = replaceChild(self.parent, by, self)
proc delete*(self: Element) = removeChild(self.parent, self)
proc insert*(before, newNode: Element) = insertBefore(before.parent, newNode, before)
proc text*(s: kstring): Node = createTextNode(document, s)

iterator items*(n: Element): Element =
  for i in 0..<n.len: yield n[i]

proc newNode*(ns: Namespace; kind: Tag): Element =
  if ns in {Namespace.html, Namespace.none}:
    result = createElement(document, toTagName[kind])
  else:
    result = createElementNS(document, toNS[ns], toTagName[kind])

proc newNode*(ns: Namespace; kind: Tag;
              attrs: openarray[(kstring, kstring)]): Element =
  result = newNode(ns, kind)
  for a in attrs: result.setAttr(a[0], a[1])

# other arbitrary stuff belonging to Element
proc toChecked*(checked: bool): cstring =
  (if checked: cstring"checked" else: cstring(nil))

proc toDisabled*(disabled: bool): cstring =
  (if disabled: cstring"disabled" else: cstring(nil))

# -------------- Event handling --------------------

type
  EventHandler* = proc (ev: Event) {.closure.}

proc addEventHandler*(e: Element; k: EventKind; action: EventHandler) =
  case k
  of EventKind.onkeyuplater:
    proc laterWrapper(): EventHandler =
      let action = action
      var timer: Timeout
      result = proc (ev: Event) =
        proc wrapper() = action(ev)
        if timer != nil: clearTimeout(timer)
        timer = setTimeout(wrapper, 400)

    e.addEventListener("keyup", laterWrapper())
  of EventKind.onkeyupenter:
    proc enterWrapper(): EventHandler =
      let action = action
      result = proc (ev: Event) =
        if KeyboardEvent(ev).code == cstring"Enter": action(ev)

    e.addEventListener("keyup", enterWrapper())
  else:
    e.addEventListener(toEventName[k], action)

proc addEventHandler*(e: Element; k: EventKind; action: proc()) =
  addEventHandler e, k, (proc (ev: Event) = action())

proc prepareDragData*(ev: Event; datatype, data: cstring)
  {.importcpp: "#.dataTransfer.setData(@)".}

proc recvDragData*(ev: Event; datatype: cstring): cstring
  {.importcpp: "#.dataTransfer.getData(@)".}

# ------------------ Init handling -----------------------------------

proc replaceById*(newTree: Element; id: cstring = "ROOT") =
  let x = getElementById(id)
  x.parent.replaceChild(newTree, x)
  newTree.id = id

proc setWindowOnload(h: EventHandler) {.importcpp: "window.onload = #".}
proc setInitializer*(initializer: proc (hashPart: kstring): Element;
                     root: cstring = "ROOT") =
  var onhashChange {.importc: "window.onhashchange".}: proc()
  var hashPart {.importc: "window.location.hash".}: cstring

  setWindowOnload proc (ev: Event) =
    replaceById initializer(hashPart), root
  onhashchange = proc () =
    replaceById initializer(hashPart), root

# ------------------ DSL section -------------------------------------

const
  StmtContext = ["inc", "echo", "dec", "!"]
  SpecialAttrs = ["id", "value"]

type
  ComponentKind {.pure.} = enum
    None,
    Tag

var
  allcomponents {.compileTime.} = initTable[string, ComponentKind]()

proc isComponent(x: string): ComponentKind {.compileTime.} =
  allcomponents.getOrDefault(x)

proc addTags() {.compileTime.} =
  let x = (bindSym"Tag").getTypeImpl
  expectKind(x, nnkEnumTy)
  for i in ord(Tag.html)..ord(Tag.high):
    # +1 because of empty node at the start of the enum AST:
    let tag = $x[i+1]
    allcomponents[tag] = ComponentKind.Tag

static:
  addTags()

proc getName(n: NimNode): string =
  case n.kind
  of nnkIdent, nnkSym:
    result = $n
  of nnkAccQuoted:
    result = ""
    for i in 0..<n.len:
      result.add getName(n[i])
  of nnkStrLit..nnkTripleStrLit:
    result = n.strVal
  of nnkInfix:
    # allow 'foo-bar' syntax:
    if n.len == 3 and $n[0] == "-":
      result = getName(n[1]) & "-" & getName(n[2])
    else:
      expectKind(n, nnkIdent)
  of nnkDotExpr:
    result = getName(n[0]) & "." & getName(n[1])
  of nnkOpenSymChoice, nnkClosedSymChoice:
    result = getName(n[0])
  else:
    #echo repr n
    expectKind(n, nnkIdent)

proc newDotAsgn(tmp: NimNode, key: string, x: NimNode): NimNode =
  result = newTree(nnkAsgn, newDotExpr(tmp, newIdentNode key), x)

proc toKstring(n: NimNode): NimNode =
  if n.kind == nnkStrLit:
    result = newCall(bindSym"kstring", n)
  else:
    result = copyNimNode(n)
    for child in n:
      result.add toKstring(child)

proc tcall2(n, tmpContext, nsContext: NimNode): NimNode =
  # we need to distinguish statement and expression contexts:
  # every call statement 's' needs to be transformed to 'dest.add s'.
  # If expressions need to be distinguished from if statements. Since
  # we know we start in a statement context, it's pretty simple to
  # figure out expression contexts: In calls everything is an expression
  # (except for the last child of the macros we consider here),
  # lets, consts, types can be considered as expressions
  # case is complex, calls are assumed to produce a value.
  when defined(js):
    template evHandler(): untyped = bindSym"addEventHandler"
  else:
    template evHandler(): untyped = ident"addEventHandler"

  case n.kind
  of nnkLiterals, nnkIdent, nnkSym, nnkDotExpr, nnkBracketExpr:
    if tmpContext != nil:
      result = newCall(bindSym"add", tmpContext, n)
    else:
      result = n
  of nnkForStmt, nnkIfExpr, nnkElifExpr, nnkElseExpr,
      nnkOfBranch, nnkElifBranch, nnkExceptBranch, nnkElse,
      nnkConstDef, nnkWhileStmt, nnkIdentDefs, nnkVarTuple:
    # recurse for the last son:
    result = copyNimTree(n)
    let L = n.len
    assert n.len == result.len
    if L > 0:
      result[L-1] = tcall2(result[L-1], tmpContext, nsContext)
  of nnkStmtList, nnkStmtListExpr, nnkWhenStmt, nnkIfStmt, nnkTryStmt,
     nnkFinally:
    # recurse for every child:
    result = copyNimNode(n)
    for x in n:
      result.add tcall2(x, tmpContext, nsContext)
  of nnkCaseStmt:
    # recurse for children, but don't add call for case ident
    result = copyNimNode(n)
    result.add n[0]
    for i in 1 ..< n.len:
      result.add tcall2(n[i], tmpContext, nsContext)
  of nnkProcDef:
    let name = getName n[0]
    if name.startsWith"on":
      # turn it into an anon proc:
      let anon = copyNimTree(n)
      anon[0] = newEmptyNode()
      if tmpContext == nil:
        error "no Element to attach the event handler to"
      else:
        result = newCall(evHandler(), tmpContext,
                         newDotExpr(bindSym"EventKind", n[0]), anon)
    else:
      result = n
  of nnkVarSection, nnkLetSection, nnkConstSection:
    result = n
  of nnkCallKinds - {nnkInfix}:
    let op = getName(n[0])
    if isComponent(op) == ComponentKind.Tag:
      let tmp = genSym(nskLet, "tmp")
      let ns = genSym(nskLet, "ns")
      let parentNamespace =
        if nsContext == nil: newDotExpr(bindSym"Namespace", ident"none")
        else: nsContext
      let call1 = newCall(bindSym"getChildNamespace", parentNamespace,
                          newDotExpr(bindSym"Tag", n[0]))
      let call2 = newCall(bindSym"newNode", ns,
                          newDotExpr(bindSym"Tag", n[0]))
      result = newTree(
        if tmpContext == nil: nnkStmtListExpr else: nnkStmtList,
        newLetStmt(ns, call1),
        newLetStmt(tmp, call2))
      for i in 1 ..< n.len:
        # named parameters are transformed into attributes or events:
        let x = n[i]
        if x.kind == nnkExprEqExpr:
          let key = getName x[0]
          if key.startsWith("on"):
            result.add newCall(evHandler(),
              tmp, newDotExpr(bindSym"EventKind", x[0]), x[1])
          elif key in SpecialAttrs:
            result.add newDotAsgn(tmp, key, x[1])
          elif eqIdent(key, "style"):
            result.add newCall(bindSym"applyStyles", tmp, toKstring x[1])
          elif eqIdent(key, "setFocus"):
            result.add newCall(bindSym"focus", tmp)
          else:
            result.add newCall(bindSym"setAttr", tmp, newLit(key), x[1])
        elif eqIdent(x, "setFocus"):
          result.add newCall(bindSym"focus", tmp)
        else:
          result.add tcall2(x, tmp, ns)
      if tmpContext == nil:
        result.add tmp
      else:
        result.add newCall(bindSym"add", tmpContext, tmp)
    elif tmpContext != nil and op notin StmtContext:
      var hasEventHandlers = false
      for i in 1..<n.len:
        let it = n[i]
        if it.kind in {nnkProcDef, nnkStmtList}:
          hasEventHandlers = true
          break
      if not hasEventHandlers:
        result = newCall(bindSym"add", tmpContext, n)
      else:
        let tmp = genSym(nskLet, "tmp")
        var slicedCall = newCall(n[0]) #todo support namespaces
        let ex = newTree(nnkStmtListExpr)
        ex.add newEmptyNode() # will become the let statement
        for i in 1..<n.len:
          let it = n[i]
          if it.kind in {nnkProcDef, nnkStmtList}:
            ex.add tcall2(it, tmp, nil)
          else:
            slicedCall.add it
        ex[0] = newLetStmt(tmp, slicedCall)
        ex.add tmp
        result = newCall(bindSym"add", tmpContext, ex)
    elif op == "!" and n.len == 2:
      result = n[1]
    else:
      result = n
  else:
    result = n

macro buildHtml*(tag, children: untyped): Element =
  let kids = newProc(procType=nnkDo, body=children)
  expectKind kids, nnkDo
  var call: NimNode
  if tag.kind in nnkCallKinds:
    call = tag
  else:
    call = newCall(tag)
  call.add body(kids)
  result = tcall2(call, nil, nil)
  when defined(debugKaraxDsl):
    echo repr result

macro buildHtml*(children: untyped): Element =
  let kids = newProc(procType=nnkDo, body=children)
  expectKind kids, nnkDo
  result = tcall2(body(kids), nil, nil)
  when defined(debugKaraxDsl):
    echo repr result

macro flatHtml*(tag: untyped): Element =
  result = tcall2(tag, nil, nil)
  when defined(debugKaraxDsl):
    echo repr result
