include karax / prelude
import karax / vstyles

proc createDom(): VNode =
  result = buildHtml(tdiv):
    tdiv(style = style(StyleAttr.color, "red".cstring)):
      text "red"
    tdiv(style = style(StyleAttr.color, "blue")):
      text "blue"
    # explicit `kstring` required for varargs overload
    tdiv(style = style((fontStyle, "italic".kstring), (color, "orange".kstring))):
      text "italic orange"
    # can use a string directly
    tdiv(style = "font-style: oblique; color: pink".toCss):
      text "oblique pink"

setRenderer createDom
