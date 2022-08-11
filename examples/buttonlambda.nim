include karax / prelude
from sugar import `=>`

var lines: seq[kstring] = @[]

proc createDom(): VNode =
  result = buildHtml(tdiv):
    button(onclick = () => lines.add "Hello simulated universe"):
      text "Say hello!"
    for x in lines:
      tdiv:
        text x

setRenderer createDom
