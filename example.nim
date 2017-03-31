
import vdom, karax, karaxdsl, jdict, jstrutils

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

var
  entries: seq[cstring]
  selectedEntry = -1

proc onTodoEnter(val: cstring) =
  entries.add val

proc removeHandler(ev: Event; n: VNode) =
  let id = suffixAsInt(n.id, "remove:")
  #entries.delete(id)
  entries[id] = nil

proc editHandler(ev: Event; n: VNode) =
  let id = suffixAsInt(n.id, "edit:")
  selectedEntry = id

when defined(usecache):
  var entryCache = newJDict[int, VNode]()

proc editInput(i: int; d: cstring): VNode =
  proc onTodoChange(val: cstring) =
    entries[i] = val
    selectedEntry = -1
  result = enterInput("todo-edit", d, onTodoChange)
  result.setOnfocuslost(proc (ev: Event; n: VNode) = selectedEntry = -1)

proc createEntry(i: int; d: cstring; selected: bool): VNode =
  # implement caching:
  when defined(usecache):
    if entryCache.contains(i):
      let old = entryCache[i]
      return old

  result = buildHtml(tr) do:
    td(id="edit:" & $i, onclick=editHandler):
      if selected:
        editInput(i, d)
      else:
        text d
    td:
      span(id="remove:" & $i, onclick=removeHandler):
        text "[remove]"
  when defined(usecache):
    entryCache[i] = result

proc createDom(): VNode =
  result = buildHtml(tdiv) do:
    tdiv(id = "sheader"):
      #text "plugin"
      #realtimeInput("by-name", "", onInput)
      #br()

      text cstring"todo"
      enterInput("todo-input", "", onTodoEnter)
    var entriesCount = 0
    table(class = "wl"):
      for i, d in entries:
        if d != nil:
          createEntry(i, d, i == selectedEntry)
          inc entriesCount
    tdiv(id = "footer"):
      text cstring"Entries: " & &entriesCount
      proc onAllDone(ev: Event; n: VNode) =
        entries = @[]
        selectedEntry = -1
      button "All done!", onAllDone, entriesCount == 0 or selectedEntry >= 0

setRenderer createDom

proc onload(session: cstring) {.exportc.} =
  for i in 0..10_000:
    entries.add("Entry " & $i)
  redraw()
