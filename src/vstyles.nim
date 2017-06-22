
import kdom, macros

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
    e.add(newCall("cstring", newLit($i)))
  template tmpl(e) {.dirty.} =
    const
      toStyleAttrName: array[StyleAttr, cstring] = e
  result = getAst tmpl(e)

buildLookupTables()

type
  VStyle* = ref object
    attrs: array[StyleAttr, cstring]
    mask: set[StyleAttr]

proc kout[T](x: T) {.importc: "console.log", varargs.}

proc eq*(a, b: VStyle): bool =
  if a.isNil:
    if b.isNil: return true
    else: return false
  elif b.isNil: return false
  if a.mask != b.mask: return false
  for x in a.mask:
    if a.attrs[x] != b.attrs[x]: return false
  return true

proc setAttr*(s: VStyle; attr: StyleAttr, value: cstring) =
  assert value != nil, "value must not be nil"
  s.attrs[attr] = value
  incl(s.mask, attr)

proc getAttr*(s: VStyle; attr: StyleAttr): cstring =
  ## returns 'nil' if the attribute has not been set.
  result = s.attrs[attr]

proc style*(pairs: varargs[(StyleAttr, cstring)]): VStyle =
  ## constructs a VStyle object from a list of (attribute, value)-pairs.
  result = VStyle(mask: {})
  for x in pairs:
    result.setAttr x[0], x[1]

proc style*(a: StyleAttr; val: cstring): VStyle =
  ## constructs a VStyle object from a single (attribute, value)-pair.
  result = VStyle(mask: {})
  result.setAttr a, val

proc setStyle(d: Style; key, val: cstring) {.importcpp: "#[#] = #".}

proc merge*(a, b: VStyle): VStyle =
  ## merges two styles. ``b`` takes precedence over ``a``.
  result = VStyle(mask: {})
  for i in low(StyleAttr)..high(StyleAttr):
    result.attrs[i] = if b.attrs[i].isNil: a.attrs[i] else: b.attrs[i]
    if result.attrs[i] != nil: incl(result.mask, i)

proc applyStyle*(n: Node; s: VStyle) =
  ## apply the style to the real DOM node ``n``.
  n.style = Style()
  for x in s.mask:
    n.style.setStyle(toStyleAttrName[x], s.attrs[x])

iterator pairs*(v: VStyle): (cstring, cstring) =
  if v != nil:
    for x in v.mask:
      yield (toStyleAttrName[x], v.attrs[x])

import jstrutils

proc rgb*(r, g, b: range[0..255]): cstring =
  cstring"rgb(" & &r & cstring", " & &g & cstring", " & &b & cstring")"

proc rgba*(r, g, b: range[0..255], alpha: float): cstring =
  cstring"rgba(" & &r & cstring", " & &g & cstring", " & &b & cstring", " & &alpha & cstring")"
