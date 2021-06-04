## Karax -- Single page applications for Nim.

from dom import nil

when not declared(dom.DomApiVersion):
  include kdom_impl

else:
  import dom

  when not declared(dom.checked):
    proc checked*(n: Node): bool {.importcpp: "#.checked", nodecl.}
  when not declared(dom.`checked=`):
    proc `checked=`*(n: Node; v: bool) {.importcpp: "#.checked = #", nodecl.}
  when not declared(dom.createElementNS): # added in nim 1.5.1
    proc createElementNS*(d: Document, namespaceURI, qualifiedIdentifier: cstring): Element {.importcpp.}
  when not declared(dom.setAttributeNS):
    proc setAttributeNS*(n: Node, ns, name, value: cstring) {.importcpp.}
  when not declared(dom.setAttrNs):
    proc setAttrNs*(n: Node, ns, name, value: cstring) = n.setAttributeNS(ns, name, value)

  export dom
