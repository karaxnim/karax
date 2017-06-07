#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Declaration of the Document Object Model for the `JavaScript backend
## <backends.html#the-javascript-target>`_.

when not defined(js) and not defined(Nimdoc):
  {.error: "This module only works on the JavaScript platform".}

type
  EventTarget* = ref EventTargetObj
  EventTargetObj {.importc.} = object of RootObj
    onabort*: proc (event: Event) {.nimcall.}
    onblur*: proc (event: Event) {.nimcall.}
    onchange*: proc (event: Event) {.nimcall.}
    onclick*: proc (event: Event) {.nimcall.}
    ondblclick*: proc (event: Event) {.nimcall.}
    onerror*: proc (event: Event) {.nimcall.}
    onfocus*: proc (event: Event) {.nimcall.}
    onkeydown*: proc (event: Event) {.nimcall.}
    onkeypress*: proc (event: Event) {.nimcall.}
    onkeyup*: proc (event: Event) {.nimcall.}
    onload*: proc (event: Event) {.nimcall.}
    onmousedown*: proc (event: Event) {.nimcall.}
    onmousemove*: proc (event: Event) {.nimcall.}
    onmouseout*: proc (event: Event) {.nimcall.}
    onmouseover*: proc (event: Event) {.nimcall.}
    onmouseup*: proc (event: Event) {.nimcall.}
    onreset*: proc (event: Event) {.nimcall.}
    onselect*: proc (event: Event) {.nimcall.}
    onsubmit*: proc (event: Event) {.nimcall.}
    onunload*: proc (event: Event) {.nimcall.}

  Window* = ref WindowObj
  WindowObj {.importc.} = object of EventTargetObj
    document*: Document
    event*: Event
    history*: History
    location*: Location
    closed*: bool
    defaultStatus*: cstring
    innerHeight*, innerWidth*: int
    locationbar*: ref LocationBar
    menubar*: ref MenuBar
    name*: cstring
    outerHeight*, outerWidth*: int
    pageXOffset*, pageYOffset*: int
    personalbar*: ref PersonalBar
    scrollbars*: ref ScrollBars
    statusbar*: ref StatusBar
    status*: cstring
    toolbar*: ref ToolBar
    frames*: seq[Frame]

  Frame* = ref FrameObj
  FrameObj {.importc.} = object of WindowObj

  ClassList* = ref ClassListObj
  ClassListObj {.importc.} = object of RootObj

  NodeType* = enum
    ElementNode = 1,
    AttributeNode,
    TextNode,
    CDATANode,
    EntityRefNode,
    EntityNode,
    ProcessingInstructionNode,
    CommentNode,
    DocumentNode,
    DocumentTypeNode,
    DocumentFragmentNode,
    NotationNode

  Node* = ref NodeObj
  NodeObj {.importc.} = object of EventTargetObj
    attributes*: seq[Node]
    childNodes*: seq[Node]
    children*: seq[Node]
    data*: cstring
    firstChild*: Node
    lastChild*: Node
    nextSibling*: Node
    nodeName*: cstring
    nodeType*: NodeType
    nodeValue*: cstring
    parentNode*: Node
    previousSibling*: Node
    innerHTML*: cstring
    style*: Style

  Document* = ref DocumentObj
  DocumentObj {.importc.} = object of NodeObj
    alinkColor*: cstring
    bgColor*: cstring
    body*: Element
    charset*: cstring
    cookie*: cstring
    defaultCharset*: cstring
    fgColor*: cstring
    head*: Element
    lastModified*: cstring
    linkColor*: cstring
    referrer*: cstring
    title*: cstring
    URL*: cstring
    vlinkColor*: cstring
    anchors*: seq[AnchorElement]
    forms*: seq[FormElement]
    images*: seq[ImageElement]
    applets*: seq[Element]
    embeds*: seq[EmbedElement]
    links*: seq[LinkElement]

  Element* = ref ElementObj
  ElementObj {.importc.} = object of NodeObj
    classList*: Classlist
    checked*: bool
    defaultChecked*: bool
    defaultValue*: cstring
    disabled*: bool
    form*: FormElement
    name*: cstring
    readOnly*: bool
    options*: seq[OptionElement]

  # https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement
  HtmlElement* = ref object of Element
    contentEditable*: string
    isContentEditable*: bool
    dir*: string
    offsetHeight*: int
    offsetWidth*: int
    offsetLeft*: int
    offsetTop*: int

  LinkElement* = ref LinkObj
  LinkObj {.importc.} = object of ElementObj
    target*: cstring
    text*: cstring
    x*: int
    y*: int

  EmbedElement* = ref EmbedObj
  EmbedObj {.importc.} = object of ElementObj
    height*: int
    hspace*: int
    src*: cstring
    width*: int
    `type`*: cstring
    vspace*: int

  AnchorElement* = ref AnchorObj
  AnchorObj {.importc.} = object of ElementObj
    text*: cstring
    x*, y*: int

  OptionElement* = ref OptionObj
  OptionObj {.importc.} = object of ElementObj
    defaultSelected*: bool
    selected*: bool
    selectedIndex*: int
    text*: cstring
    value*: cstring

  FormElement* = ref FormObj
  FormObj {.importc.} = object of ElementObj
    action*: cstring
    encoding*: cstring
    `method`*: cstring
    target*: cstring
    elements*: seq[Element]

  ImageElement* = ref ImageObj
  ImageObj {.importc.} = object of ElementObj
    border*: int
    complete*: bool
    height*: int
    hspace*: int
    lowsrc*: cstring
    src*: cstring
    vspace*: int
    width*: int

  Style = ref StyleObj
  StyleObj {.importc.} = object of RootObj
    background*: cstring
    backgroundAttachment*: cstring
    backgroundColor*: cstring
    backgroundImage*: cstring
    backgroundPosition*: cstring
    backgroundRepeat*: cstring
    border*: cstring
    borderBottom*: cstring
    borderBottomColor*: cstring
    borderBottomStyle*: cstring
    borderBottomWidth*: cstring
    borderColor*: cstring
    borderLeft*: cstring
    borderLeftColor*: cstring
    borderLeftStyle*: cstring
    borderLeftWidth*: cstring
    borderRight*: cstring
    borderRightColor*: cstring
    borderRightStyle*: cstring
    borderRightWidth*: cstring
    borderStyle*: cstring
    borderTop*: cstring
    borderTopColor*: cstring
    borderTopStyle*: cstring
    borderTopWidth*: cstring
    borderWidth*: cstring
    bottom*: cstring
    captionSide*: cstring
    clear*: cstring
    clip*: cstring
    color*: cstring
    cursor*: cstring
    direction*: cstring
    display*: cstring
    emptyCells*: cstring
    cssFloat*: cstring
    font*: cstring
    fontFamily*: cstring
    fontSize*: cstring
    fontStretch*: cstring
    fontStyle*: cstring
    fontVariant*: cstring
    fontWeight*: cstring
    height*: cstring
    left*: cstring
    letterSpacing*: cstring
    lineHeight*: cstring
    listStyle*: cstring
    listStyleImage*: cstring
    listStylePosition*: cstring
    listStyleType*: cstring
    margin*: cstring
    marginBottom*: cstring
    marginLeft*: cstring
    marginRight*: cstring
    marginTop*: cstring
    maxHeight*: cstring
    maxWidth*: cstring
    minHeight*: cstring
    minWidth*: cstring
    overflow*: cstring
    padding*: cstring
    paddingBottom*: cstring
    paddingLeft*: cstring
    paddingRight*: cstring
    paddingTop*: cstring
    pageBreakAfter*: cstring
    pageBreakBefore*: cstring
    position*: cstring
    right*: cstring
    scrollbar3dLightColor*: cstring
    scrollbarArrowColor*: cstring
    scrollbarBaseColor*: cstring
    scrollbarDarkshadowColor*: cstring
    scrollbarFaceColor*: cstring
    scrollbarHighlightColor*: cstring
    scrollbarShadowColor*: cstring
    scrollbarTrackColor*: cstring
    tableLayout*: cstring
    textAlign*: cstring
    textDecoration*: cstring
    textIndent*: cstring
    textTransform*: cstring
    top*: cstring
    verticalAlign*: cstring
    visibility*: cstring
    width*: cstring
    wordSpacing*: cstring
    zIndex*: int

  # TODO: A lot of the fields in Event belong to a more specific type of event.
  # TODO: Should we clean this up?
  Event* = ref EventObj
  EventObj {.importc.} = object of RootObj
    target*: Node
    altKey*, ctrlKey*, shiftKey*: bool
    button*: int
    clientX*, clientY*: int
    keyCode*: int
    layerX*, layerY*: int
    modifiers*: int
    ALT_MASK*, CONTROL_MASK*, SHIFT_MASK*, META_MASK*: int
    offsetX*, offsetY*: int
    pageX*, pageY*: int
    screenX*, screenY*: int
    which*: int
    `type`*: cstring
    x*, y*: int
    ABORT*: int
    BLUR*: int
    CHANGE*: int
    CLICK*: int
    DBLCLICK*: int
    DRAGDROP*: int
    ERROR*: int
    FOCUS*: int
    KEYDOWN*: int
    KEYPRESS*: int
    KEYUP*: int
    LOAD*: int
    MOUSEDOWN*: int
    MOUSEMOVE*: int
    MOUSEOUT*: int
    MOUSEOVER*: int
    MOUSEUP*: int
    MOVE*: int
    RESET*: int
    RESIZE*: int
    SELECT*: int
    SUBMIT*: int
    UNLOAD*: int

  TouchList* {.importc.} = ref object of RootObj
    length*: int

  TouchEvent* {.importc.} = ref object of Event
    changedTouches*, targetTouches*, touches*: TouchList

  Touch* {.importc.} = ref object of RootObj
    identifier*: int
    screenX*, screenY*, clientX*, clientY*, pageX*, pageY*: int
    target*: Element
    radiusX*, radiusY*: int
    rotationAngle*: int
    force*: float

  Location* = ref LocationObj
  LocationObj {.importc.} = object of RootObj
    hash*: cstring
    host*: cstring
    hostname*: cstring
    href*: cstring
    pathname*: cstring
    port*: cstring
    protocol*: cstring
    search*: cstring

  History* = ref HistoryObj
  HistoryObj {.importc.} = object of RootObj
    length*: int

  Navigator* = ref NavigatorObj
  NavigatorObj {.importc.} = object of RootObj
    appCodeName*: cstring
    appName*: cstring
    appVersion*: cstring
    cookieEnabled*: bool
    language*: cstring
    platform*: cstring
    userAgent*: cstring
    mimeTypes*: seq[ref MimeType]

  Plugin* {.importc.} = object of RootObj
    description*: cstring
    filename*: cstring
    name*: cstring

  MimeType* {.importc.} = object of RootObj
    description*: cstring
    enabledPlugin*: ref Plugin
    suffixes*: seq[cstring]
    `type`*: cstring

  LocationBar* {.importc.} = object of RootObj
    visible*: bool
  MenuBar* = LocationBar
  PersonalBar* = LocationBar
  ScrollBars* = LocationBar
  ToolBar* = LocationBar
  StatusBar* = LocationBar

  Screen = ref ScreenObj
  ScreenObj {.importc.} = object of RootObj
    availHeight*: int
    availWidth*: int
    colorDepth*: int
    height*: int
    pixelDepth*: int
    width*: int

  TimeOut* {.importc.} = ref object of RootObj
  Interval* {.importc.} = object of RootObj

proc len*(x: Node): int {.importcpp: "#.childNodes.length".}
proc `[]`*(x: Node; idx: int): Element {.importcpp: "#.childNodes[#]".}

proc setTimeout*(action: proc(); ms: int): Timeout {.importc, nodecl.}
proc clearTimeout*(t: Timeout) {.importc, nodecl.}
proc getElementById*(id: cstring): Element {.importc: "document.getElementById", nodecl.}

{.push importcpp.}

# EventTarget "methods"
proc addEventListener*(et: EventTarget, ev: cstring, cb: proc(ev: Event), useCapture: bool = false)

# Window "methods"
proc alert*(w: Window, msg: cstring)
proc back*(w: Window)
proc blur*(w: Window)
proc captureEvents*(w: Window, eventMask: int) {.deprecated.}
proc clearInterval*(w: Window, interval: ref Interval)
proc clearTimeout*(w: Window, timeout: TimeOut)
proc close*(w: Window)
proc confirm*(w: Window, msg: cstring): bool
proc disableExternalCapture*(w: Window)
proc enableExternalCapture*(w: Window)
proc find*(w: Window, text: cstring, caseSensitive = false,
           backwards = false)
proc focus*(w: Window)
proc forward*(w: Window)
proc handleEvent*(w: Window, e: Event)
proc home*(w: Window)
proc moveBy*(w: Window, x, y: int)
proc moveTo*(w: Window, x, y: int)
proc open*(w: Window, uri, windowname: cstring,
           properties: cstring = nil): Window
proc print*(w: Window)
proc prompt*(w: Window, text, default: cstring): cstring
proc releaseEvents*(w: Window, eventMask: int) {.deprecated.}
proc resizeBy*(w: Window, x, y: int)
proc resizeTo*(w: Window, x, y: int)
proc routeEvent*(w: Window, event: Event)
proc scrollBy*(w: Window, x, y: int)
proc scrollTo*(w: Window, x, y: int)
proc setInterval*(w: Window, code: cstring, pause: int): ref Interval
proc setInterval*(w: Window, function: proc (), pause: int): ref Interval
proc setTimeout*(w: Window, code: cstring, pause: int): TimeOut
proc setTimeout*(w: Window, function: proc (), pause: int): ref Interval
proc stop*(w: Window)
proc requestAnimationFrame*(w: Window, function: proc (time: float)): int
proc cancelAnimationFrame*(w: Window, id: int)

# Node "methods"
proc appendChild*(n, child: Node)
proc appendData*(n: Node, data: cstring)
proc cloneNode*(n: Node, copyContent: bool): Node
proc deleteData*(n: Node, start, len: int)
proc getAttribute*(n: Node, attr: cstring): cstring
proc getAttributeNode*(n: Node, attr: cstring): Node
proc hasChildNodes*(n: Node): bool
proc insertBefore*(n, newNode, before: Node)
proc insertData*(n: Node, position: int, data: cstring)
proc removeAttribute*(n: Node, attr: cstring)
proc removeAttributeNode*(n, attr: Node)
proc removeChild*(n, child: Node)
proc replaceChild*(n, newNode, oldNode: Node)
proc replaceData*(n: Node, start, len: int, text: cstring)
proc scrollIntoView*(n: Node)
proc setAttribute*(n: Node, name, value: cstring)
proc setAttributeNode*(n: Node, attr: Node)

# Document "methods"
proc captureEvents*(d: Document, eventMask: int) {.deprecated.}
proc createAttribute*(d: Document, identifier: cstring): Node
proc createElement*(d: Document, identifier: cstring): Element
proc createTextNode*(d: Document, identifier: cstring): Node
proc getElementById*(d: Document, id: cstring): Element
proc getElementsByName*(d: Document, name: cstring): seq[Element]
proc getElementsByTagName*(d: Document, name: cstring): seq[Element]
proc getElementsByClassName*(d: Document, name: cstring): seq[Element]
proc getSelection*(d: Document): cstring
proc handleEvent*(d: Document, event: Event)
proc open*(d: Document)
proc releaseEvents*(d: Document, eventMask: int) {.deprecated.}
proc routeEvent*(d: Document, event: Event)
proc write*(d: Document, text: cstring)
proc writeln*(d: Document, text: cstring)

# Element "methods"
proc blur*(e: Element)
proc click*(e: Element)
proc focus*(e: Node)
proc handleEvent*(e: Element, event: Event)
proc select*(e: Element)
proc getElementsByTagName*(e: Element, name: cstring): seq[Element]
proc getElementsByClassName*(e: Element, name: cstring): seq[Element]

# FormElement "methods"
proc reset*(f: FormElement)
proc submit*(f: FormElement)

# EmbedElement "methods"
proc play*(e: EmbedElement)
proc stop*(e: EmbedElement)

# Location "methods"
proc reload*(loc: Location)
proc replace*(loc: Location, s: cstring)

# History "methods"
proc back*(h: History)
proc forward*(h: History)
proc go*(h: History, pagesToJump: int)

# Navigator "methods"
proc javaEnabled*(h: Navigator): bool

# ClassList "methods"
proc add*(c: ClassList, class: cstring)
proc remove*(c: ClassList, class: cstring)
proc contains*(c: ClassList, class: cstring):bool
proc toggle*(c: ClassList, class: cstring)

# Style "methods"
proc getAttribute*(s: Style, attr: cstring, caseSensitive=false): cstring
proc removeAttribute*(s: Style, attr: cstring, caseSensitive=false)
proc setAttribute*(s: Style, attr, value: cstring, caseSensitive=false)

# Event "methods"
proc preventDefault*(ev: Event)

# TouchEvent "methods"
proc identifiedTouch*(list: TouchList): Touch
proc item*(list: TouchList, i: int): Touch

{.pop.}

proc setAttr*(n: Node; key, val: cstring) {.importcpp: "#.setAttribute(@)".}

var
  window* {.importc, nodecl.}: Window
  document* {.importc, nodecl.}: Document
  navigator* {.importc, nodecl.}: Navigator
  screen* {.importc, nodecl.}: Screen

proc decodeURI*(uri: cstring): cstring {.importc, nodecl.}
proc encodeURI*(uri: cstring): cstring {.importc, nodecl.}

proc escape*(uri: cstring): cstring {.importc, nodecl.}
proc unescape*(uri: cstring): cstring {.importc, nodecl.}

proc decodeURIComponent*(uri: cstring): cstring {.importc, nodecl.}
proc encodeURIComponent*(uri: cstring): cstring {.importc, nodecl.}
proc isFinite*(x: BiggestFloat): bool {.importc, nodecl.}
proc isNaN*(x: BiggestFloat): bool {.importc, nodecl.}
proc parseFloat*(s: cstring): BiggestFloat {.importc, nodecl.}
proc parseInt*(s: cstring): int {.importc, nodecl.}
proc parseInt*(s: cstring, radix: int):int {.importc, nodecl.}


proc id*(n: Node): cstring {.importcpp: "#.id", nodecl.}
proc `id=`*(n: Node; x: cstring) {.importcpp: "#.id = #", nodecl.}
proc class*(n: Node): cstring {.importcpp: "#.className", nodecl.}
proc `class=`*(n: Node; v: cstring) {.importcpp: "#.className = #", nodecl.}

proc value*(n: Node): cstring {.importcpp: "#.value", nodecl.}
proc `value=`*(n: Node; v: cstring) {.importcpp: "#.value = #", nodecl.}

proc `disabled=`*(n: Node; v: bool) {.importcpp: "#.disabled = #", nodecl.}

proc getElementsByClass*(n: Node; name: cstring): seq[Node] {.
  importcpp: "#.getElementsByClassName(#)", nodecl.}


type
  BoundingRect* {.importc.} = object
    top*, bottom*, left*, right*: int

proc getBoundingClientRect*(e: Node): BoundingRect {.
  importcpp: "getBoundingClientRect", nodecl.}
proc clientHeight*(): int {.
  importcpp: "(window.innerHeight || document.documentElement.clientHeight)@", nodecl}
proc clientWidth*(): int {.
  importcpp: "(window.innerWidth || document.documentElement.clientWidth)@", nodecl}

proc inViewport*(el: Node): bool =
  let rect = el.getBoundingClientRect()
  result = rect.top >= 0 and rect.left >= 0 and
           rect.bottom <= clientHeight() and
           rect.right <= clientWidth()

proc scrollTop*(e: Node): int {.importcpp: "#.scrollTop", nodecl.}
proc offsetHeight*(e: Node): int {.importcpp: "#.offsetHeight", nodecl.}
proc offsetTop*(e: Node): int {.importcpp: "#.offsetTop", nodecl.}
