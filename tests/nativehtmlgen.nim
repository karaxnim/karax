## Simple test that shows Karax can also do client-side HTML rendering.

import "../karax" / [karaxdsl, vdom]

when defined(js):
  {.error: "Use 'nim c' to compile this example".}

template kxi(): int = 0
template addEventHandler(n: VNode; k: EventKind; action: string; kxi: int) =
  n.setAttr($k, action)

let tab = buildHtml(table):
  tr:
    td:
      text "Cell A"
    td:
      text "Cell B"
  tr:
    td:
      text "Cell C"
    td:
      text "Cell D"
    td:
      a(href = "#/", onclick = "javascript:myFunc()"):
        text"haha"

echo tab
