
import asynchttpserver, asyncdispatch, asyncnet, "../../../websocket/websocket", common, json

type
  Message = object
    kind: MessageKind
    id: MessageId
    data: seq[Triple]
    version: int

proc `%`(id: MessageId): JsonNode = %BiggestInt(id)
proc `%`(k: MessageKind): JsonNode = %BiggestInt(k)

proc triplesFromJson(j: JsonNode): seq[Triple] =
  result = newSeq[Triple](j.len)
  var i = 0
  for t in j:
    doAssert t.kind == JArray
    result[i] = [t[0].str, t[1].str, t[2].str]
    inc i

proc messageFromJson(j: JsonNode): Message =
  Message(kind: MessageKind(j["kind"].num), id: MessageId(j["id"].num),
          data: triplesFromJson(j["data"]), version: j["version"].num.int)

var server = newAsyncHttpServer()

proc cb(req: Request) {.async.} =
  let (success, error) = await(verifyWebsocketRequest(req, "karaxdb"))
  if not success:
    echo "WS negotiation failed: " & error
    await req.respond(Http400, "Websocket negotiation failed: " & error)
    req.client.close
  else:
    echo "New websocket customer arrived!"
    while true:
      try:
        var f = await req.client.readData(false)
        echo "(opcode: " & $f.opcode & ", data: " & $f.data.len & ")"
        let m = messageFromJson(f.data.parseJson)
        let om = Message(kind: Accepted, id: m.id, data: @[], version: m.version)
        let oms = $(%*om)
        echo "OUTPUT ", oms
        if f.opcode == Opcode.Text:
          waitFor req.client.sendText(oms, false)
        else:
          echo "protocol error"
          #waitFor req.client.sendBinary(f.data, false)
      except:
        echo getCurrentExceptionMsg()
        break

    req.client.close()
    echo ".. socket went away."

waitFor server.serve(Port(8080), cb)
