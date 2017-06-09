## Example that shows how to accomplish an "infinitely scrolling" app.

include karaxprelude
import jstrutils, kdom, vstyles

var karax: KaraxInstance

var entries: seq[cstring] = @[]
for i in 1..500:
  entries.add(cstring("Entry ") & &i)

proc scrollEvent(ev: Event; n: VNode) =
  let d = n.dom
  if d != nil and inViewport(d.lastChild):
    # "load" more data:
    for i in 1..50:
      entries.add(cstring("Loaded Entry ") & &i)

proc createDom(): VNode =
  let scrollStyle = style(
    (StyleAttr.height, cstring"400px"),
    (StyleAttr.overflow, cstring"scroll"),
  )
  result = karax.buildHtml:
    tdiv(onscroll=scrollEvent, style=scrollStyle):
      for x in entries:
        tdiv:
          text x

window.onload = proc(ev: Event) =
  karax = initKarax(createDom)
