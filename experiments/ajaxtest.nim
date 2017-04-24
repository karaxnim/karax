import dom, kajax

proc cb(httpStatus: int, response: cstring) =
  echo "Worked!"

ajaxGet("https://httpbin.org/get", @[], cb)
