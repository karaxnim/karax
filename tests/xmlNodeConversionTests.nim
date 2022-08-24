import std/xmltree
import "../karax"/[vdom, xdom]

let xn = newXmlTree("div", @[], attributes = [("a", "b")].toXmlAttributes)
let vn = tree(tdiv, attrs = (@[("a", "b"), ("c", "d")]))
vn.add newVNode(a)
vn[0].add vn("bbb")
vn.add verbatim("<app>abc</app>")
xn.add newXmlTree("i", @[], attributes = [("a", "b")].toXmlAttributes)

let vnX = vn.toXmlNode

doassert vnX[0].len == 1 and vnX[1][0].kind == xnText
doassert $vnX[1].tag == "app"
doassert $vnX == """<div c="d" a="b">
  <a>bbb</a>
  <app>abc</app>
</div>"""
doassert $xn.toVNode == """<div a="b"><i a="b"></i></div>"""
