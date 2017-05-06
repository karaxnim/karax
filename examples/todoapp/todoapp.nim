
import vdom, karax, karaxdsl, jstrutils, components, karaxdb/client

type
  Filter = enum
    all, active, completed

var
  selectedEntry = -1
  filter: Filter
  entriesLen: int
  data: Db

registerOnUpdate proc(newDb: Db) =
  merge(newDb, data)
  data = newDb
  redraw()

const
  contentSuffix = cstring"content"
  completedSuffix = cstring"completed"
  lenSuffix = cstring"entriesLen"

proc getEntryContent(pos: int): cstring =
  extract(data, &pos, contentSuffix)

proc isCompleted(pos: int): bool =
  var value = extract(data, &pos, completedSuffix)
  result = value == cstring"true"

proc setEntryContent(pos: int, content: cstring) =
  insert(data, &pos, contentSuffix, content)

proc markAsCompleted(pos: int, completed: bool) =
  insert(data, &pos, completedSuffix, &completed)

proc addEntry(content: cstring, completed: bool) =
  setEntryContent(entriesLen, content)
  markAsCompleted(entriesLen, completed)
  inc entriesLen
  insert(data, lenSuffix, "equals", &entriesLen)

proc updateEntry(pos: int, content: cstring, completed: bool) =
  setEntryContent(pos, content)
  markAsCompleted(pos, completed)

proc onTodoEnter(ev: Event; n: VNode) =
  addEntry(n.value, false)
  n.value = ""

proc removeHandler(ev: Event; n: VNode) =
  updateEntry(n.key, cstring(nil), false)

proc editHandler(ev: Event; n: VNode) =
  selectedEntry = n.key

proc focusLost(ev: Event; n: VNode) = selectedEntry = -1

proc editEntry(ev: Event; n: VNode) =
  setEntryContent(n.key, n.value)
  selectedEntry = -1

proc toggleEntry(ev: Event; n: VNode) =
  let id = n.key
  markAsCompleted(id, not isCompleted(id))

proc onAllDone(ev: Event; n: VNode) =
  insert(data, lenSuffix, "equals", "0")
  selectedEntry = -1

proc clearCompleted(ev: Event, n: VNode) =
  for i in 0..<entriesLen:
    if isCompleted(i): setEntryContent(i, nil)

proc toClass(completed: bool): cstring =
  (if completed: cstring"completed" else: cstring(nil))

proc toChecked(checked: bool): cstring =
  (if checked: cstring"checked" else: cstring(nil))

proc selected(v: Filter): cstring =
  (if filter == v: cstring"selected" else: cstring(nil))

proc createEntry(id: int; d: cstring; completed, selected: bool): VNode {.component.} =
  result = buildHtml(tr):
    li(class=toClass(completed)):
      if not selected:
        tdiv(class = "view"):
          input(class = "toggle", `type` = "checkbox", checked = toChecked(completed),
                onclick=toggleEntry, key=id)
          label(onDblClick=editHandler, key=id):
            text d
          button(class = "destroy", key=id, onclick=removeHandler)
      else:
        input(class = "edit", name = "title", key=id,
          onblur = focusLost,
          onkeyupenter = editEntry, value = d, setFocus)

proc makeFooter(entriesCount, completedCount: int): VNode {.component.} =
  result = buildHtml(footer(class = "footer")):
    span(class = "todo-count"):
      strong:
        text(&entriesCount)
      text cstring" item" & &(if entriesCount != 1: "s left" else: " left")
    ul(class = "filters"):
      li:
        a(class = selected(all), href = "#/"):
          text "All"
      li:
        a(class = selected(active), href = "#/active"):
          text "Active"
      li:
        a(class = selected(completed), href = "#/completed"):
          text "Completed"
    button(class = "clear-completed", onclick = clearCompleted):
      text "Clear completed (" & &completedCount & ")"

proc makeHeader(): VNode {.component.} =
  result = buildHtml(header(class = "header")):
    h1:
      text "todos"
    input(class = "new-todo", placeholder="What needs to be done?", name = "newTodo",
          onkeyupenter = onTodoEnter, setFocus)

proc createDom(): VNode =
  result = buildHtml(tdiv(class="todomvc-wrapper")):
    section(class = "todoapp"):
      makeHeader()
      section(class = "main"):
        input(class = "toggle-all", `type` = "checkbox", name = "toggle")
        label(`for` = "toggle-all", onclick = onAllDone):
          text "Mark all as complete"
        var entriesCount = 0
        var completedCount = 0
        ul(class = "todo-list"):
          #for i, d in pairs(entries):
          for i in 0..entriesLen-1:
            var d0 = getEntryContent(i)
            var d1 = isCompleted(i)
            if d0 != nil:
              let b = case filter
                      of all: true
                      of active: not d1
                      of completed: d1
              if b:
                createEntry(i, d0, d1, i == selectedEntry)
              inc completedCount, ord(d1)
              inc entriesCount
      makeFooter(entriesCount, completedCount)

setOnHashChange(proc(hash: cstring) =
  if hash == "#/": filter = all
  elif hash == "#/completed": filter = completed
  elif hash == "#/active": filter = active
)

entriesLen = 0
setRenderer createDom
