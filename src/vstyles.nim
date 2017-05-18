
import dom, macros

type
  StyleAttr* {.pure.} = enum ## the style attributes supported by the virtual DOM.
    background
    backgroundAttachment
    backgroundColor
    backgroundImage
    backgroundPosition
    backgroundRepeat
    border
    borderBottom
    borderBottomColor
    borderBottomStyle
    borderBottomWidth
    borderColor
    borderLeft
    borderLeftColor
    borderLeftStyle
    borderLeftWidth
    borderRight
    borderRightColor
    borderRightStyle
    borderRightWidth
    borderStyle
    borderTop
    borderTopColor
    borderTopStyle
    borderTopWidth
    borderWidth
    bottom
    captionSide
    clear
    clip
    color
    cursor
    direction
    display
    emptyCells
    cssFloat
    font
    fontFamily
    fontSize
    fontStretch
    fontStyle
    fontVariant
    fontWeight
    height
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
    overflow
    padding
    paddingBottom
    paddingLeft
    paddingRight
    paddingTop
    pageBreakAfter
    pageBreakBefore
    position
    right
    scrollbar3dLightColor
    scrollbarArrowColor
    scrollbarBaseColor
    scrollbarDarkshadowColor
    scrollbarFaceColor
    scrollbarHighlightColor
    scrollbarShadowColor
    scrollbarTrackColor
    tableLayout
    textAlign
    textDecoration
    textIndent
    textTransform
    top
    verticalAlign
    visibility
    width
    wordSpacing
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

proc `==`*(a, b: VStyle): bool =
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
  result = VStyle(mask: a.mask + b.mask)
  for i in low(StyleAttr)..high(StyleAttr):
    result.attrs[i] = if b.attrs[i].isNil: a.attrs[i] else: b.attrs[i]

proc applyStyle*(n: Node; s: VStyle) =
  ## apply the style to the real DOM node ``n``.
  n.style = Style()
  for x in s.mask:
    n.style.setStyle(toStyleAttrName[x], s.attrs[x])
