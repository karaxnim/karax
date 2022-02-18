# include karax / prelude

# proc createDom1*(): VNode =
#   result = buildHtml(tdiv):
#     text "Hello World1"
#     echo "1"

# var a1 = setRenderer(createDom1, "ROOT1")


include karax / prelude

var lines: seq[kstring] = @[]

proc createDom(): VNode =
  result = buildHtml(tdiv):
    button:
      text "Say hello!"
      proc onclick(ev: Event; n: VNode) =
        lines.add "Hello simulated universe"
    for x in lines:
      tdiv:
        text x

var a1 = setRenderer(createDom, "ROOT1")