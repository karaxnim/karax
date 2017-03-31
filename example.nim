
import vdom, karax, karaxdsl, jdict

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
  #entries.delete(id)
  entries[id] = nil

var entryCache = newJDict[int, VNode]()

proc createEntry(i: int; d: cstring): VNode =
  # implement caching:
  if entryCache.contains(i):
    let old = entryCache[i]
    return old

  result = buildHtml(tr) do:
    td:
      text d
    td:
      span(id="remove:" & $i, onclick=onclickHandler):
        text "[remove]"
  entryCache[i] = result

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
        if d != nil:
          createEntry(i, d)

setRenderer createDom

proc onload(session: cstring) {.exportc.} =
  for i in 0..10_000:
    entries.add("Entry " & $i)
  redraw()
