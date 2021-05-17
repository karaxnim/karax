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

  export dom
