include karax / prelude
import karax / kdom

let id = "foo1"
let id2 = "foo2"
let valueInitial = "150"
var value = valueInitial
proc updateText() =
  value = $document.getElementById($id).value
proc createDom(): VNode =
  result = buildHtml(tdiv):
    input(`type`="range", min = "10", max = "170", value = valueInitial, id = id):
      proc oninput(ev: Event; target: VNode) = updateText()
    tdiv(id=id2):
      text value


var a2 = setRenderer(createDom, "ROOT2")