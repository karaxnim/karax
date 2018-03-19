
import karax / [vdom, karax, karaxdsl, jstrutils, compact, localstorage]

type
  Filter = enum
    all, active, completed

var
  selectedEntry = -1
  filter: Filter
  entriesLen: int

const
  contentSuffix = cstring"content"
  completedSuffix = cstring"completed"
  lenSuffix = cstring"entriesLen"

when defined(hotReloading):
  # When hot reloading is enabled, we won't store the list of
  # to-do items in persistent storage in order to demonstrate
  # the state preserving behavior of the hot reloading engine.
  import jsconsole, tables

  var
    todoStore = initTable[cstring, cstring]()

  proc getItem(key: cstring): cstring = todoStore[key]
  proc setItem(k, v: cstring) = todoStore[k] = v
  proc hasItem(k: cstring): bool = todoStore.hasKey(k)
  proc clear() = todoStore.clear()

  once:
    console.log "HOT-RELOADING ENABLED"

proc getEntryContent(pos: int): cstring =
  result = getItem(&pos & contentSuffix)
  if result == cstring"null":
    result = nil

proc isCompleted(pos: int): bool =
  var value = getItem(&pos & completedSuffix)
  result = value == cstring"true"

proc setEntryContent(pos: int, content: cstring) =
  setItem(&pos & contentSuffix, content)

proc markAsCompleted(pos: int, completed: bool) =
  setItem(&pos & completedSuffix, &completed)

proc addEntry(content: cstring, completed: bool) =
  setEntryContent(entriesLen, content)
  markAsCompleted(entriesLen, completed)
  inc entriesLen
  setItem(lenSuffix, &entriesLen)

proc updateEntry(pos: int, content: cstring, completed: bool) =
  setEntryContent(pos, content)
  markAsCompleted(pos, completed)

proc onTodoEnter(ev: Event; n: VNode) =
  addEntry(n.value, false)
  n.value = ""

proc removeHandler(ev: Event; n: VNode) =
  updateEntry(n.index, cstring(nil), false)

proc editHandler(ev: Event; n: VNode) =
  selectedEntry = n.index

proc focusLost(ev: Event; n: VNode) = selectedEntry = -1

proc editEntry(ev: Event; n: VNode) =
  setEntryContent(n.index, n.value)
  selectedEntry = -1

proc toggleEntry(ev: Event; n: VNode) =
  let id = n.index
  markAsCompleted(id, not isCompleted(id))

proc onAllDone(ev: Event; n: VNode) =
  clear()
  selectedEntry = -1

proc clearCompleted(ev: Event, n: VNode) =
  for i in 0..<entriesLen:
    if isCompleted(i): setEntryContent(i, nil)

proc toClass(completed: bool): cstring =
  (if completed: cstring"completed" else: cstring(nil))

proc selected(v: Filter): cstring =
  (if filter == v: cstring"selected" else: cstring(nil))

proc createEntry(id: int; d: cstring; completed, selected: bool): VNode {.compact.} =
  result = buildHtml(tr):
    li(class=toClass(completed)):
      if not selected:
        tdiv(class = "view"):
          input(class = "toggle", `type` = "checkbox", checked = toChecked(completed),
                onclick=toggleEntry, index=id)
          label(onDblClick=editHandler, index=id):
            text d
          button(class = "destroy", index=id, onclick=removeHandler)
      else:
        input(class = "edit", name = "title", index=id,
          onblur = focusLost,
          onkeyupenter = editEntry, value = d, setFocus=true)

proc makeFooter(entriesCount, completedCount: int): VNode =
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

proc makeHeader(): VNode {.compact.} =
  result = buildHtml(header(class = "header")):
    h1:
      text "todos"
    input(class = "new-todo", placeholder="What needs to be done?", name = "newTodo",
          onkeyupenter = onTodoEnter, setFocus)

proc createDom(todoStore: RouterData): VNode =
  if todoStore.hashPart == "#/": filter = all
  elif todoStore.hashPart == "#/completed": filter = completed
  elif todoStore.hashPart == "#/active": filter = active
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

if hasItem(lenSuffix):
  entriesLen = parseInt getItem(lenSuffix)
else:
  entriesLen = 0

setRenderer createDom
redraw()

