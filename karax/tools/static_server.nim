import net, os, strutils, uri, mimetypes, asyncnet, asyncdispatch, md5,
       logging, httpcore, asyncfile, options
import asynchttpserver
from cgi import decodeUrl
import ws,tables,times
import dotenv

type 
  RawHeaders* = seq[tuple[key, val: string]]

proc toStr(headers: Option[RawHeaders]): string =
  return $newHttpHeaders(headers.get(@({:})))

proc send(
  request: Request, code: HttpCode, headers: Option[RawHeaders], body: string
): Future[void] =
  return request.respond(
    code, body, newHttpHeaders(headers.get(@({:})))
  )

proc statusContent(request: Request, status: HttpCode, content: string,
                   headers: Option[RawHeaders]): Future[void] =
  try:
    result = send(request, status, headers, content)
    when not defined(release):
      logging.debug("  $1 $2" % [$status, toStr(headers)])
  except:
    logging.error("Could not send response: $1" % osErrorMsg(osLastError()))

proc sendStaticIfExists(
  req: Request, paths: seq[string]
): Future[HttpCode] {.async.} =
  result = Http200
  let mimes = newMimetypes()
  for p in paths:
    if fileExists(p):

      var fp = getFilePermissions(p)
      if not fp.contains(fpOthersRead):
        return Http403

      let fileSize = getFileSize(p)
      let ext = p.splitFile.ext
      let mimetype = mimes.getMimetype(
        if ext.len > 0: ext[1 .. ^1]
        else: ""
      )
      if fileSize < 10_000_000: # 10 mb
        var file = readFile(p)

        var hashed = getMD5(file)

        # If the user has a cached version of this file and it matches our
        # version, let them use it
        if req.headers.hasKey("If-None-Match") and req.headers["If-None-Match"] == hashed:
          await req.statusContent(Http304, "", none[RawHeaders]())
        else:
          await req.statusContent(Http200, file, some(@({
            "Content-Type": mimetype,
            "ETag": hashed
          })))
      else:
        let headers = @({
          "Content-Type": mimetype,
          "Content-Length": $fileSize
        })
        await req.statusContent(Http200, "", some(headers))

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


proc handleFileRequest(
  req: Request
): Future[HttpCode] {.async.} =
  # Find static file.
  var reqPath = cgi.decodeUrl(req.url.path)
  var publicUrl = getEnv("publicUrl")
  var staticDir = getEnv("staticDir")
  if not publicUrl.endsWith("/"):
    publicUrl = publicUrl & "/"
  reqPath = reqPath.substr(publicUrl.len)
  
  let path = normalizedPath(
    staticDir / reqPath
  )

  # Verify that this isn't outside our static dir.
  var status = Http400
  let pathDir = path.splitFile.dir / ""

  if pathDir.startsWith(publicUrl):
    if dirExists(path):
      status = await sendStaticIfExists(
        req,
        @[path / "index.html", path / "index.htm"]
      )
  else:
    status = await sendStaticIfExists(req, @[path])
  return status

proc handleWs(req: Request) {.async.} =
  var ws = await newWebSocket(req)
  await ws.send("Welcome to simple echo server")
  var files: Table[string, Time] = {"path": getLastModificationTime(".")}.toTable
  let watchedFiles = [absolutePath "app.js",absolutePath "app.html"]
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
  if fileExists( "static.env" ):
    var env:DotEnv
    env = initDotEnv(getCurrentDir(), "static.env")
    env.overload()
  else:
    loadEnvFromString("""
    staticDir="./src/assets/"
    publicUrl="public"
    """)
  
  var server = newAsyncHttpServer()
  proc cb(req: Request) {.gcsafe, async.} =
    if req.url.path == "/ws":
      await handleWs(req)
    if req.url.path == "/":
      await req.respond(Http200, readFile "app.html" )
    elif req.url.path == "/app.js":
      let file = absolutePath("app" & ".js")
      if not file.fileExists:
        logging.error("$1 not exists!" % file )
      if fpUserRead notin os.getFilePermissions(file):
        logging.error("Could not read $1!" % file )
      await req.respond(Http200, readFile( file ))
    else:
      let status = await handleFileRequest(req)
      if status != Http200:
        await req.respond(status,"")

  waitFor server.serve(Port(8080), cb)

when isMainModule:
  serveStatic()
