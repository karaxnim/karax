
import vdom, karax, karaxdsl

when false:
  var plugins {.exportc.}: seq[(string, proc())] = @[]

  proc onInput(val: cstring) =
    kout val
    if val == "dyn":
      let body = getElementById("body")
      body.prepend(tree("script", [("type", "text/javascript"), ("src", "nimcache/dyn.js")]))
      redraw()
    kout(plugins.len)
    if plugins.len > 0:
      plugins[0][1]()

var entries: seq[cstring]

proc onTodoEnter(val: cstring) =
  entries.add val

proc onclickHandler(ev: Event; n: VNode) =
  let id = suffixAsInt(n.id, "remove:")
  entries.delete(id)

proc createEntry(i: int; d: cstring): VNode =
  result = buildHtml(tr) do:
    td:
      text d
    td:
      span(id="remove:" & $i, onclick=onclickHandler):
        text "[remove]"

proc createDom(): VNode =
  result = buildHtml(tdiv) do:
    tdiv(id = "sheader"):
      #text "plugin"
      #realtimeInput("by-name", "", onInput)
      #br()

      text "todo"
      enterInput("todo-input", "", onTodoEnter)
    table(class = "wl"):
      for i, d in entries:
        createEntry(i, d)

setRenderer createDom

proc onload(session: cstring) {.exportc.} =
  for i in 0..10_000:
    entries.add("Entry " & $i)
  redraw()
