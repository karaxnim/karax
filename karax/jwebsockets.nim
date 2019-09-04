## Websockets support for the JSON backend.

type
  MessageEvent* {.importc.} = ref object
    data*: cstring

  WebSocket* {.importc.} = ref object
    onmessage*: proc (e: MessageEvent)
    onopen*: proc (e: MessageEvent)
    readyState*: int

proc newWebSocket*(url, key: cstring): WebSocket
  {.importcpp: "new WebSocket(@)".}

proc newWebSocket*(url: cstring): WebSocket
  {.importcpp: "new WebSocket(@)".}

proc send*(w: WebSocket; data: cstring) {.importcpp.}
