import vdom, kdom, kajax, karax as karax_module

proc cb(httpStatus: int, response: cstring) =
  echo "Worked!"

proc createDom(): VNode =
  nil

var karax = initKarax(createDom)

karax.ajaxGet("https://httpbin.org/get", @[], cb)
