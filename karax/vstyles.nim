##[
see examples/hellostyle.nim
]##

import std/[macros, strutils]
import kbase

when defined(js):
  import kdom, jdict

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

macro buildLookupTables(): untyped =
  var e = newTree(nnkBracket)
  for i in low(StyleAttr)..high(StyleAttr):
    e.add(newCall("kstring", newLit($i)))
  template tmpl(e) {.dirty.} =
    const
      toStyleAttrName: array[StyleAttr, kstring] = e
  result = getAst tmpl(e)

buildLookupTables()

# I optimized the heck out of this representation since profiling showed
# it's relevant.
# even index: key, odd index: value; done this way for memory efficiency:

when defined(js):
  type
    VStyle* = JSeq[cstring]
else:
  type
    VStyle* = ref seq[string]
  proc len*(a: VStyle): int = len(a[])
  proc add*(a: VStyle; x: string) = add(a[], x)

proc eq*(a, b: VStyle): bool =
  if a.isNil:
    if b.isNil: return true
    else: return false
  elif b.isNil: return false
  if a.len != b.len: return false
  for i in 0..<a.len:
    if a[i] != b[i]: return false
  return true

proc setAttr*(s: VStyle; a, value: kstring) {.noSideEffect.} =
  ## inserts (a, value) in sorted order of key `a`
  # worst case quadratic complexity (if given styles in reverse order), hopefully
  # not a concern assuming small cardinal
  var i = 0
  while i < s.len:
    if s[i] == a:
      s[i+1] = value
      return
    elif s[i] > a:
      s.add ""
      s.add ""
      # insertion point here, shift all remaining pairs by 2 indexes
      for j in countdown(s.len-1, i+3, 2):
        s[j] = s[j-2]
        s[j-1] = s[j-3]
      s[i] = a
      s[i+1] = value
      return
    inc i, 2
  s.add a
  s.add value

# PRTEMP
proc setAttr2*(s: VStyle; a, value: kstring) {.noSideEffect.} =
  setAttr(s, a, value)

proc setAttr*(s: VStyle; attr: StyleAttr, value: kstring) {.noSideEffect.} =
  when kstring is cstring:
    assert value != nil, "value must not be nil"
  setAttr(s, toStyleAttrName[attr], value)

proc getAttr*(s: VStyle; attr: StyleAttr): kstring {.noSideEffect.} =
  ## returns "" if the attribute has not been set.
  var i = 0
  let a = toStyleAttrName[attr]
  while i < s.len:
    if s[i] == a:
      return s[i+1]
    elif s[i] > a:
      return ""
    inc i, 2

proc style*(pairs: varargs[(StyleAttr, kstring)]): VStyle {.noSideEffect.} =
  ## constructs a VStyle object from a list of (attribute, value)-pairs.
  when defined(js):
    result = newJSeq[cstring]()
  else:
    new(result)
    result[] = @[]
  for x in pairs:
    result.setAttr x[0], x[1]

proc style*(a: StyleAttr; val: kstring): VStyle {.noSideEffect.} =
  ## constructs a VStyle object from a single (attribute, value)-pair.
  when defined(js):
    result = newJSeq[cstring]()
  else:
    new(result)
    result[] = @[]
  result.setAttr a, val

proc toCss*(a: string): VStyle =
  ##[
  See example in hellostyle.nim
  Allows passing a css string directly, eg:
  tdiv(style = style((fontStyle, "italic".kstring), (color, "orange".kstring))): discard
  tdiv(style = "font-style: oblique; color: pink".toCss): discard
  ]##
  when defined(js):
    result = newJSeq[cstring]()
  else:
    new(result)
    result[] = @[]
  for ai in a.split(";"):
    var ai = ai.strip
    if ai.len == 0: continue
    let aj = ai.strip.split(":", maxsplit=1)
    result.setAttr(aj[0], aj[1])

when defined(js):
  proc setStyle(d: Style; key, val: cstring) {.importcpp: "#[#] = #", noSideEffect.}

  proc applyStyle*(n: Node; s: VStyle) {.noSideEffect.} =
    ## apply the style to the real DOM node ``n``.

    #n.style = Style() # optimized, this is a hotspot:
    {.emit: "`n`.style = {};".}
    for i in countup(0, s.len-1, 2):
      n.style.setStyle(s[i], s[i+1])

proc merge*(a, b: VStyle): VStyle {.noSideEffect.} =
  ## merges two styles. ``b`` takes precedence over ``a``.
  when defined(js):
    result = newJSeq[cstring]()
  else:
    new(result)
    result[] = @[]
  for i in 0..<a.len:
    result.add a[i]
  for i in countup(0, b.len-1, 2):
    setAttr(result, b[i], b[i+1])

iterator pairs*(s: VStyle): (kstring, kstring) {.noSideEffect.} =
  if s != nil:
    for i in countup(0, s.len-1, 2):
      yield (s[i], s[i+1])

when defined(js):
  import jstrutils
else:
  template `&`(x: untyped): untyped = $x

proc rgb*(r, g, b: range[0..255]): kstring =
  kstring"rgb(" & &r & kstring", " & &g & kstring", " & &b & kstring")"

proc rgba*(r, g, b: range[0..255], alpha: float): kstring =
  kstring"rgba(" & &r & kstring", " & &g & kstring", " & &b & kstring", " & &alpha & kstring")"
