import std / [os, strutils, browsers, times, tables, parseopt, threadpool, nativesockets]
import static_server

var port = 8080.Port

const
  css = """
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.4/css/bulma.min.css">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
"""

  html = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"/>
  <meta content="width=device-width, initial-scale=1" name="viewport"/>
  <title>$1</title>
  <link href="styles.css" rel="stylesheet" type="text/css">
  $2
</head>
<body id="body" class="site">
<div id="ROOT">$3</div>
$4
</body>
</html>
"""
var
  websocket = """
<script type="text/javascript">
var ws = new WebSocket("ws://localhost:""" & $port & """/ws");

ws.onopen = function(evt) {
  console.log("Connection open ...");
  ws.send("Hello WebSockets!");
};

ws.onmessage = function(evt) {
  console.log( "Received Message: " + evt.data);
  if(evt.data == "refresh"){
    window.location.href = window.location.href
  }
};

ws.onclose = function(evt) {
  console.log("Connection closed.");
};
</script>
"""

proc exec(cmd: string) =
  if os.execShellCmd(cmd) != 0:
    quit "External command failed: " & cmd

proc build(ssr: bool, entry: string, rest: string, selectedCss: string, run: bool, watch: bool, websocket: string) =
  echo("Building...")
  var cmd: string
  var content = ""
  var outTempPath: string
  var outHtmlName: string
  if ssr:
    outHtmlName = changeFileExt(extractFilename(entry),"html")
    outTempPath = getTempDir() / outHtmlName
    cmd = "nim c -r " & rest & " " &  outTempPath
  else:
    cmd = "nim js --out:" & "app" & ".js " & rest
  if watch:
    discard os.execShellCmd(cmd)
  else:
    exec cmd
  let dest = "app" & ".html"
  let script = if ssr:"" else: """<script type="text/javascript" src="/app.js"></script>""" & (if watch: websocket else: "")
  if ssr:
    content = readFile(outTempPath)
  writeFile(dest, html % [if ssr: outHtmlName else:"app", selectedCss,content, script])
  if run: openDefaultBrowser("http://localhost:" & $port)

proc watchBuild(ssr: bool, filePath: string, selectedCss: string, rest: string, websocket: string) {.thread.} =
  var files: Table[string, Time] = {"path": getLastModificationTime(".")}.toTable
  while true:
    sleep(300)
    for path in walkDirRec("."):
      if ".git" in path:
        continue
      var (_, _, ext) = splitFile(path)
      if ext in [".scss", ".sass", ".less", ".styl", ".pcss", ".postcss"]:
        continue
      if files.hasKey(path):
        if files[path] != getLastModificationTime(path):
          echo("File changed: " & path)
          build(ssr, filePath, rest,selectedCss, false, true, websocket)
          files[path] = getLastModificationTime(path)
      else:
        if absolutePath(path) in [absolutePath("app" & ".js"), absolutePath("app" & ".html")]:
          continue
        files[path] = getLastModificationTime(path)

proc serve(port: Port) {.thread.} =
  serveStatic(port)

proc main =
  var op = initOptParser()
  var rest = op.cmdLineRest
  var file = ""
  var run = false
  var watch = false
  var selectedCss = ""
  var ssr = false
  while true:
    op.next()
    case op.kind
    of cmdLongOption:
      case op.key
      of "run":
        run = true
        rest = rest.replace("--run ")
      of "css":
        if op.val != "":
          selectedCss = readFile(op.val)
        else:
          selectedCss = css
        rest = rest.substr(rest.find(" "))
      of "port":
        rest = rest.replace("--port ")
        if op.val != "":
          port = op.val.parseInt.Port
      of "ssr":
        ssr = true
        rest = rest.replace("--ssr ")
      else: discard
    of cmdShortOption:
      if op.key == "r":
        run = true
        rest = rest.replace("-r ")
      if op.key == "p":
        rest = rest.replace("-p ")
        if op.val != "":
          port = op.val.parseInt.Port
      if op.key == "w":
        watch = true
        rest = rest.replace("-w ")
      if op.key == "s":
        ssr = true
        rest = rest.replace("-s ")
    of cmdArgument: file = op.key
    of cmdEnd: break

  if file.len == 0: quit "filename expected"
  var ws: string
  ws.addr.moveMem websocket.addr, websocket.len.Natural
  if run:
    spawn serve(port)
  if watch:
    spawn watchBuild(ssr, file, selectedCss, rest, ws)
  build(ssr, file, rest, selectedCss, run, watch, ws)
  sync()

main()
