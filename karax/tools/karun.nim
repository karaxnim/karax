
import os, strutils, browsers,times, tables 
import parseopt
import threadpool
import static_server

const
  css = """
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.4/css/bulma.min.css">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
"""

const html = """
<!DOCTYPE html>
<html>
<head>
  <meta content="width=device-width, initial-scale=1" name="viewport" />
  <title>$1</title>
  $2
</head>
<body id="body" class="site">
<div id="ROOT"></div>
<script type="text/javascript" src="/app.js"></script>
$3
</body>
</html>
"""
const websocket = """
<script type="text/javascript">
var ws = new WebSocket("ws://localhost:8080/ws");

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

proc build(rest: string, selectedCss: string, run: bool, watch: bool) =
  echo("Building...")
  let cmd = "nim js --out:" & "app" & ".js " & rest
  if watch:
    discard os.execShellCmd(cmd)
  else:
    exec cmd
  let dest = "app" & ".html"
  let script = if run and watch: websocket else: ""
  writeFile(dest, html % ["app", selectedCss, script])
  if run: openDefaultBrowser("http://localhost:8080")

proc watchBuild(filePath: string, selectedCss: string, rest: string) {.thread.} = 
  var files: Table[string, Time] = {"path": getLastModificationTime(".")}.toTable
  while true:
    sleep(300)
    for path in walkDirRec("."):
      if ".git" in path:
        continue
      var (_, _, ext) = splitFile(path)
      if ext in [".scss",".sass",".less",".styl",".pcss",".postcss"]:
        continue
      if files.hasKey(path):
        if files[path] != getLastModificationTime(path):
          echo("File changed: " & path)
          build(rest,selectedCss, false, true)
          files[path] = getLastModificationTime(path)
      else:
        if absolutePath(path) in [absolutePath("app" & ".js"),absolutePath("app" & ".html")]:
          continue
        files[path] = getLastModificationTime(path)

proc serve(){.thread.} =
  serveStatic()

proc main =
  var op = initOptParser()
  var rest = op.cmdLineRest
  var file = ""
  var run = false
  var watch = false
  var selectedCss = ""
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
      else: discard
    of cmdShortOption:
      if op.key == "r":
        run = true
        rest = rest.replace("-r ")
      if op.key == "w":
        watch = true
        rest = rest.replace("-w ")
    of cmdArgument: file = op.key
    of cmdEnd: break

  if file.len == 0: quit "filename expected"
  if run:
    spawn serve()
  if watch:
    spawn watchBuild(file, selectedCss, rest)
  build(rest,selectedCss, run, watch)
  sync()

main()
