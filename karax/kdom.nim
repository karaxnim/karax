## Karax -- Single page applications for Nim.

from dom import nil

when not declared(dom.DomApiVersion):
  include kdom_impl

else:
  import dom
  export dom
