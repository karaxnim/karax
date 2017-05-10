
import asynchttpserver, asyncdispatch, asyncnet, "../../../websocket/websocket", common, json,
  strutils, times

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
    let val = if t[2].kind == JNull: string(nil) else: t[2].str
    result[i] = [t[0].str, t[1].str, val]
    inc i

proc messageFromJson(j: JsonNode): Message =
  Message(kind: MessageKind(j["kind"].num), id: MessageId(j["id"].num),
          data: triplesFromJson(j["data"]), version: j["version"].num.int)

proc error(msg: string) = echo msg
proc warn(msg: string) = echo msg

type
  Tx = object
    data: string
    version: int
  Client = ref object
    socket: AsyncSocket
    connected: bool
    hostname: string
    lastMessage: float
    rapidMessageCount: int

  Server = ref object
    clients: seq[Client]
    needsUpdate: bool
    txs: seq[Tx]
    version: int

proc newClient(socket: AsyncSocket, hostname: string): Client =
  Client(socket: socket, connected: true, hostname: hostname)

proc `$`(client: Client): string =
  "Client(ip: $1)" % [client.hostname]

proc updateClients(server: Server) {.async.} =
  while true:
    var needsUpdate = false
    for client in server.clients:
      if not client.connected:
        needsUpdate = true
        break

    server.needsUpdate = server.needsUpdate or needsUpdate
    if server.needsUpdate and server.txs.len != 0:
      var someDead = false
      # perform a copy to prevent the race condition:
      var txs = server.txs
      setLen(server.txs, 0)
      for tx in txs:
        for c in server.clients:
          if c.connected:
            await c.socket.sendText(tx.data, false)
          else:
            someDead = true
      if someDead:
        var i = 0
        while i < server.clients.len:
          if not server.clients[i].connected: del(server.clients, i)
          else: inc i
      server.needsUpdate = false
    # let other stuff in the main loop run:
    await sleepAsync(10)

proc processMessage(server: Server, client: Client, data: string) {.async.} =
  # Check if last message was relatively recent. If so, kick the user.
  echo "processMessage ", data
  if epochTime() - client.lastMessage < 0.1: # 100ms
    client.rapidMessageCount.inc
  else:
    client.rapidMessageCount = 0

  client.lastMessage = epochTime()
  if client.rapidMessageCount > 10:
    warn("Client ($1) is firing messages too rapidly. Killing." % $client)
    client.connected = false
  let msgj = parseJson(data)
  let msg = messageFromJson(msgj)
  case msg.kind
  of Newdata:
    if msg.version == server.version:
      server.txs.add Tx(data: data, version: msg.version)
      server.needsUpdate = true
      inc server.version
    else:
      let om = Message(kind: Rejected, id: msg.id, data: @[], version: server.version)
      await client.socket.sendText($(%*om), false)
  else:
    # either Disconnect or an invalid message type:
    client.connected = false
    server.needsUpdate = true

proc processClient(server: Server, client: Client) {.async.} =
  while client.connected:
    var frameFut = client.socket.readData(false)
    yield frameFut
    if frameFut.failed:
      error("Error occurred handling client messages.\n" &
            frameFut.error.msg)
      client.connected = false
      break

    let frame = frameFut.read()
    if frame.opcode == Opcode.Text:
      let processFut = processMessage(server, client, frame.data)
      if processFut.failed:
        error("Client ($1) attempted to send bad JSON? " % $client & "\n" &
              processFut.error.msg)
        client.connected = false

  client.socket.close()

proc onRequest(server: Server, req: Request) {.async.} =
  let (success, error) = await verifyWebsocketRequest(req, "karaxdb")
  if success:
    echo("Client connected from ", req.hostname)
    server.clients.add(newClient(req.client, req.hostname))
    asyncCheck processClient(server, server.clients[^1])
  else:
    echo("WS negotiation failed: ", error)
    await req.respond(Http400, "WebSocket negotiation failed: " & error)
    req.client.close()

proc main =
  let httpServer = newAsyncHttpServer()
  let server = Server(clients: @[], txs: @[])

  proc cb(req: Request): Future[void] {.async.} = await onRequest(server, req)

  asyncCheck updateClients(server)
  waitFor httpServer.serve(Port(8080), cb)

main()
