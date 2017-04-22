
import vdom, karax, karaxdsl, jstrutils, components

type
  Filter = enum
    all, active, completed

var
  selectedEntry = -1
  filter: Filter
  entriesSize: int

proc getItem(key : cstring ): cstring {.importc: "localStorage.getItem"}
proc setItem(key, value : cstring ) {.importc: "localStorage.setItem"}
proc clearEntries() {.importc: "localStorage.clear"}

proc getEntryCstring(pos : int): cstring =
    result = getItem(cstring($pos & "cstring"))
    if result == cstring"null":
      result = nil

proc getEntryBool(pos : int): bool =
    var value = getItem(cstring($pos & "bool"))
    result = value == cstring"true"

proc setEntryCstring(pos : int, value : cstring) =
    setItem(cstring($pos & "cstring"), value)

proc setEntryBool(pos : int, value  : bool) =
    var val = cstring"true"
    if not value:
        val = cstring"false"
    setItem(cstring($pos & "bool"), val)

proc addEntry(str : cstring, bval : bool) =
  setEntryCstring(entriesSize, str)
  setEntryBool(entriesSize, bval)
  inc entriesSize

proc setEntry(pos : int, str : cstring, bval : bool) =
  setEntryCstring(pos, str)
  setEntryBool(pos, bval)

proc onTodoEnter(ev: Event; n: VNode) =
  addEntry(n.value, false)
  n.value = ""

proc removeHandler(ev: Event; n: VNode) =
  setEntry(n.key, cstring(nil), false)

proc editHandler(ev: Event; n: VNode) =
  selectedEntry = n.key

proc focusLost(ev: Event; n: VNode) = selectedEntry = -1

proc editEntry(ev: Event; n: VNode) =
  setEntryCstring(n.key, n.value)
  selectedEntry = -1

proc toggleEntry(ev: Event; n: VNode) =
  let id = n.key
  setEntryBool(id, not getEntryBool(id))

proc onAllDone(ev: Event; n: VNode) =
  clearEntries()
  selectedEntry = -1

proc clearCompleted(ev: Event, n: VNode) =
  for i in 0..<entriesSize:
    if getEntryBool(i): setEntryCstring(i, nil)

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
          for i in 0..entriesSize-1:
  
            var d0 = getEntryCstring(i)
            var d1 = getEntryBool(i)
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
entriesSize = 0
setRenderer createDom
