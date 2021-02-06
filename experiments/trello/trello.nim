
import knete, widgets
import karax / jstrutils
import std / dom

type
  Attachable* = ref object of RootObj ## an element that is attachable to
                                      ## DOM elements.
    attachedTo*: seq[Element]

  TaskId = int
  Task = ref object
    id: TaskId
    name, desc: kstring

  ColumnId = distinct int
  Column = ref object of Attachable
    id: ColumnId
    header: kstring
    tasks: seq[Task]

  Board = ref object
    columns: seq[Column]

var b = Board(columns: @[Column(id: ColumnId 0, header: "To Do"),
                         Column(id: ColumnId 1, header: "Doing"),
                         Column(id: ColumnId 2, header: "Done")])

proc removeTask(t: TaskId) =
  for c in b.columns:
    for i in 0 ..< c.tasks.len:
      if c.tasks[i].id == t:
        delete(c.tasks, i)
        break

proc moveTask(t: TaskId; dest: Column) =
  for c in b.columns:
    for i in 0 ..< c.tasks.len:
      let task = c.tasks[i]
      if task.id == t:
        delete(c.tasks, i)
        dest.tasks.add task
        return

var nextTaskId = 0 ## negative because they are not yet backed
                   ## up by the database

proc createTask(c: Column; name, desc: kstring): Task =
  dec nextTaskId
  result = Task(id: TaskId nextTaskId, name: name, desc: desc)
  c.tasks.add result

# --------------------- UI -----------------------------------------------

proc renderTask(t: Task): Element =
  proc dodelete =
    removeTask t.id
    delete result

  proc dragstart(ev: Event) =
    ev.prepareDragData("taskid", ev.target.id)

  result = buildHtml():
    tdiv(draggable="true", ondragstart=dragstart, id = &t.id):
      bindField t.name
      br()
      bindField t.desc
      button(onclick = dodelete):
        text cross

type
  NewTaskPanel = object
    c: Column
    e: Element

proc open(p: var NewTaskPanel; c: Column) =
  p.e.style.display = "block"
  p.c = c

proc newTaskDialog(): NewTaskPanel =
  var nameInp = buildHtml():
    input(setFocus = true)
  var descInp = buildHtml():
    input()

  proc close =
    result.e.style.display = "none"

  proc submit =
    let t = createTask(result.c, nameInp.value, descInp.value)
    close()
    result.c.attachedTo[0].add renderTask(t)

  result.e = buildHtml():
    tdiv(style={display: "none", position: "fixed",
        left: "0", top: "0", width: "100%", height: "100%",
        overflow: "auto",
        backgroundColor: "rgb(0,0,0)",
        backgroundColor: "rgba(0,0,0,0.4)", zIndex: "1"}):
      tdiv(style={backgroundColor: "#fefefe",
          margin: "15% auto", padding: "20px", border: "1px solid #888",
          width: "80%"}):
        span(onclick = close, style={color: "#aaa",
            cssFloat: "right",
            fontSize: "28px",
            fontWeight: "bold"}):
          text cross
        p:
          text "Task name"
          nameInp
        p:
          text "Task description"
          descInp
        span(onclick = submit, style={color: "#0f0",
            cssFloat: "left",
            fontWeight: "bold"}):
          text "Submit"

var dialog = newTaskDialog()

proc renderColumn(c: Column): Element =
  proc doadd(c: Column): proc () =
    result = proc() = dialog.open(c)

  proc allowDrop(ev: Event) = ev.preventDefault()
  proc drop(ev: Event) =
    ev.preventDefault()
    let data = ev.recvDragData("taskid")
    moveTask(parseInt data, c)
    Element(ev.target).up("mycolumn").add(getElementById(data))

  result = buildHtml():
    tdiv(class = "mycolumn", style = {cssFloat: "left", width: "20%"},
         ondrop = drop, ondragover = allowDrop):
      tdiv(class = "myheader"):
        bindField c.header
        span(onclick = doadd(c)):
          text plus
      for t in c.tasks:
        renderTask(t)
  c.attachedTo.add result

proc renderBoard(b: Board): Element =
  result = buildHtml(tdiv):
    dialog.e
    for c in b.columns:
      renderColumn(c)

proc main(hashPart: kstring): Element =
  result = renderBoard(b)

setInitializer main
