
import vdom, karax, karaxdsl, jstrutils

proc onTodoEnter(ev: Event; n: VNode) =
  kout cstring"ENTER"

proc test(ev: Event, n: VNode) = 
  kout cstring"teeest"

proc createDom(): VNode =
  result = buildHtml(tdiv(class="todomvc-wrapper")):
    section(class = "todoapp"):
      header(class = "header"):
        input(class = "new-todo", id = "test", placeholder="What needs to be done?", name = "newTodo",
              onkeyupenter = onTodoEnter, setFocus)
      #button(class = "a", onclick = test):
        #text "TEEEEST"

setRenderer createDom
