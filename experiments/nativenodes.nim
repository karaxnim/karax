

include karax / prelude
import karax / kdom

proc myInput: VNode =
  result = buildHtml:
    input()

var inp = vnodeToDom(myInput())

proc myAwesomeComponent(x: Node): VNode =
  result = dthunk(x)

proc main: VNode =
  result = myAwesomeComponent(inp)

setRenderer main
