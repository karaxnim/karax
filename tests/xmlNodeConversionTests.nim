import xmltree
import "../karax"/[vdom, xdom]

let xn = newXmlTree("div", @[], attributes = [("a", "b")].toXmlAttributes)
let vn = tree(tdiv, attrs = (@[("a", "b"), ("c", "d")]))
vn.add newVNode(a)
xn.add newXmlTree("i", @[], attributes = [("a", "b")].toXmlAttributes)

doassert $vn.toXmlNode == """<div c="d" a="b">
  <a />
</div>"""
doassert $xn.toVNode == """<div a="b"><i a="b"></i></div>"""
