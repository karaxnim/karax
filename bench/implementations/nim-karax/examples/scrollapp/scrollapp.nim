## Example that shows how to accomplish an "infinitely scrolling" app.

include karaxprelude
import jstrutils, dom

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
  result = buildHtml():
    tdiv(onscroll=scrollEvent, style="height: 400px; overflow: scroll"):
      for x in entries:
        tdiv:
          text x

setRenderer createDom
