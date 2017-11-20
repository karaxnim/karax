include karax / prelude

proc createDom(): VNode =
  result = buildHtml(tdiv):
    text "Hello World!"

setRenderer createDom
