import
  std/[net, os, strutils, uri, mimetypes, asyncnet, asyncdispatch, md5,
  logging, httpcore, asyncfile, asynchttpserver, tables, times]
from cgi import decodeUrl
import ws, dotenv

var logger = newConsoleLogger()
addHandler(logger)

when defined(release):
  setLogFilter(lvlError)

type
  RawHeaders* = seq[tuple[key, val: string]]

proc toStr(headers: RawHeaders): string =
  $newHttpHeaders(headers)

proc send(request: Request, code: HttpCode, headers: RawHeaders,
    body: string): Future[void] =
  return request.respond(code, body, newHttpHeaders(headers))

proc statusContent(request: Request, status: HttpCode, content: string,
    headers: RawHeaders): Future[void] =
  try:
    result = send(request, status, headers, content)
    debug("  ", status, " ", toStr(headers))
  except:
    error("Could not send response: ", osErrorMsg(osLastError()))

proc sendStaticIfExists(req: Request, paths: seq[string]): Future[HttpCode] {.async.} =
  result = Http200
  let mimes = newMimetypes()
  for p in paths:
    if fileExists(p):
      if fpOthersRead notin getFilePermissions(p):
        return Http403
      let fileSize = getFileSize(p)
      let extPos = searchExtPos(p)
      let mimetype = mimes.getMimetype(
        if extPos >= 0: p.substr(extPos + 1)
        else: "")
      if fileSize < 10_000_000: # 10 mb
        var file = readFile(p)
        var hashed = getMD5(file)
        # If the user has a cached version of this file and it matches our
        # version, let them use it
        if req.headers.getOrDefault("If-None-Match") == hashed:
          await req.statusContent(Http304, "", default(RawHeaders))
        else:
          await req.statusContent(Http200, file, @{
            "Content-Type": mimetype,
            "ETag": hashed
          })
      else:
        let headers = @{
          "Content-Type": mimetype,
          "Content-Length": $fileSize
        }
        await req.statusContent(Http200, "", headers)
        var fileStream = newFutureStream[string]("sendStaticIfExists")
        var file = openAsync(p, fmRead)
        # Let `readToStream` write file data into fileStream in the
        # background.
        asyncCheck file.readToStream(fileStream)
        # The `writeFromStream` proc will complete once all the data in the
        # `bodyStream` has been written to the file.
        while true:
          let (hasValue, value) = await fileStream.read()
          if hasValue:
            await req.client.send(value)
          else:
            break
        file.close()
      return
  # If we get to here then no match could be found.
  return Http404

proc handleFileRequest(req: Request): Future[HttpCode] {.async.} =
  # Find static file.
  var reqPath = cgi.decodeUrl(req.url.path)
  var staticDir = getEnv("staticDir") # it's assumed a relative dir
  var status = Http400
  var path = staticDir / reqPath
  normalizePathEnd(path, false)
  if dirExists(path):
    status = await sendStaticIfExists(req, @[path / "index.html", path / "index.htm"])
  else:
    status = await sendStaticIfExists(req, @[path])
  return status

proc handleWs(req: Request) {.async.} =
  var ws = await newWebSocket(req)
  await ws.send("Welcome to simple echo server")

  var files: Table[string, Time] = {"path": getLastModificationTime(".")}.toTable
  let watchedFiles = [absolutePath "app.js", absolutePath "app.html"]
  for path in watchedFiles:
    files[path] = getLastModificationTime(path)

  while ws.readyState == Open:
    await sleepAsync(500)
    var changed = false
    for path in watchedFiles:
      if files[path] != getLastModificationTime(path):
        changed = true
        files[path] = getLastModificationTime(path)
    if changed:
      await ws.send("refresh")
      changed = false

proc serveStatic*() =
  if fileExists("static.env"):
    overload(getCurrentDir(), "static.env")
  else:
    putEnv("staticDir", "assets/")

  var server = newAsyncHttpServer()
  proc cb(req: Request) {.gcsafe, async.} =
    if req.url.path == "/ws":
      await handleWs(req)
    if req.url.path == "/":
      await req.respond(Http200, readFile "app.html")
    elif req.url.path == "/app.js":
      let file = absolutePath("app" & ".js")
      if not file.fileExists:
        error(file, " does not exist!")
      if fpUserRead notin os.getFilePermissions(file):
        error("Could not read ", file, "!")
      await req.respond(Http200, readFile(file))
    else:
      let status = await handleFileRequest(req)
      if status != Http200:
        await req.respond(status, "")

  waitFor server.serve(Port(8080), cb)

when isMainModule:
  serveStatic()
