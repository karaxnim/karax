
import vdom, karax, karaxdsl, jdict, jstrutils, compact

type
  Filter = enum
    all, active, completed

var
  entries: seq[(cstring, bool)]
  visibleA = 0
  visibleB = 10
  selectedEntry = -1
  filter: Filter

proc onTodoEnter(ev: Event; n: VNode) =
  entries.add((n.value, false))
  n.value = ""

proc removeHandler(ev: Event; n: VNode) =
  entries[n.key] = (cstring(nil), false)

proc editHandler(ev: Event; n: VNode) =
  selectedEntry = n.key

proc focusLost(ev: Event; n: VNode) = selectedEntry = -1

proc editEntry(ev: Event; n: VNode) =
  entries[n.key][0] = n.value
  selectedEntry = -1

proc toggleEntry(ev: Event; n: VNode) =
  let id = n.key
  entries[id][1] = not entries[id][1]

proc onAllDone(ev: Event; n: VNode) =
  entries = @[]
  selectedEntry = -1

proc clearCompleted(ev: Event, n: VNode) =
  for i in 0..<entries.len:
    if entries[i][1]: entries[i][0] = nil

proc toClass(completed: bool): cstring =
  (if completed: cstring"completed" else: cstring(nil))

proc toChecked(checked: bool): cstring =
  (if checked: cstring"checked" else: cstring(nil))

proc selected(v: Filter): cstring =
  (if filter == v: cstring"selected" else: cstring(nil))

proc createEntry(id: int; d: cstring;
                 completed: bool, selected: bool): VNode {.component.} =
  result = buildHtml(tr):
    li(class=toClass(completed), key = id):
      if not selected:
        tdiv(class = "view"):
          input(class = "toggle", `type` = "checkbox", checked = toChecked(completed),
                onclick=toggleEntry, key = id)
          label(onclick=editHandler, key = id):
            text d
          button(class = "destroy", key = id, onclick = removeHandler)
      else:
        input(class = "edit", name = "title", key = id,
          onfocusLost = focusLost,
          onenter = editEntry, value = d, setFocus)

proc myscroll(ev: Event; n: VNode) =
  kout cstring"scrolling event here"

proc createDom(): VNode =
  result = buildHtml(tdiv(class="todomvc-wrapper")):
    section(class = "todoapp"):
      header(class = "header"):
        h1:
          text "todos"
        input(class = "new-todo", placeholder="What needs to be done?", name = "newTodo",
              onenter = onTodoEnter, setFocus)
      section(class = "main"):
        input(class = "toggle-all", `type` = "checkbox", name = "toggle")
        label(`for` = "toggle-all", onclick = onAllDone):
          text "Mark all as complete"

        var entriesCount = 0
        var completedCount = 0
        ul(class = "todo-list"):
          for i in visibleA..visibleB:
            let d = entries[i]
            if d[0] != nil:
              let b = case filter
                      of all: true
                      of active: not d[1]
                      of completed: d[1]
              if b:
                createEntry(i, d[0], d[1], i == selectedEntry)
              inc completedCount, ord(d[1])
              inc entriesCount
      footer(class = "footer"):
        span(class = "todo-count"):
          strong:
            text(&entriesCount)
          text cstring" item" & &(if entriesCount != 1: "s left" else: " left")
        ul(class = "filters"):
          li:
            anchor(class = selected(all), href = "#/"):
              text "All"
          li:
            anchor(class = selected(active), href = "#/active"):
              text "Active"
          li:
            anchor(class = selected(completed), href = "#/completed"):
              text "Completed"
        button(class = "clear-completed", onclick = clearCompleted):
          text "Clear completed (" & &completedCount & ")"


when false:
  setOnscroll(proc(a, b: VKey; diff: int) =
    const
      overshoot1 = 50
      overshoot2 = 5
    if diff > 0:
      # scroll downwards:
      visibleA = max(a-overshoot2, 0)
      visibleB = min(b+diff+overshoot1, entries.len-1)
    elif diff < 0:
      # scroll upwards:
      visibleA = max(a+diff-overshoot1, 0)
      visibleB = min(b+overshoot2, entries.len-1)
  )

setOnHashChange(proc(hash: cstring) =
  if hash == cstring"#/": filter = all
  elif hash == cstring"#/completed": filter = completed
  elif hash == cstring"#/active": filter = active
)
setRenderer createDom

proc onload(session: cstring) {.exportc.} =
  for i in 0..visibleB:
    entries.add((cstring"Entry " & &i, false))
  init()
