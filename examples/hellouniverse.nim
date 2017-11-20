
include karax / prelude
import random

proc createDom(): VNode =
  result = buildHtml(tdiv):
    if random(100) <= 50:
      text "Hello World!"
    else:
      text "Hello Universe"

randomize()
setRenderer createDom
