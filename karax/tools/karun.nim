## Simple tool to quickly run Karax applications. Generates the HTML
## required to run a Karax app and opens it in a browser.

import os, 
  strutils, 
  parseopt, 
  browsers, 
  times, 
  tables
  


const
  css = """
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.4/css/bulma.min.css">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
"""
  html = """
<!DOCTYPE html>
<html>
<head>
  <meta content="width=device-width, initial-scale=1" name="viewport" />
  <title>$1</title>
  $2
</head>
<body id="body">
<div id="ROOT" />
<script type="text/javascript" src="$1.js"></script>
</body>
</html>
"""

proc exec(cmd: string) =
  if os.execShellCmd(cmd) != 0:
    quit "External command failed: " & cmd

proc build(name: string, rest: string, selectedCss: string, run: bool) =
  echo("Building...")
  exec("nim js --out:" & name & ".js " & rest)
  let dest = name & ".html"
  writeFile(dest, html % [name, selectedCss])
  if run: openDefaultBrowser(dest)

proc main =
  var op = initOptParser()
  var rest = op.cmdLineRest
  var file = ""
  var run = false
  var selectedCss = ""
  var watch = false
  var files: Table[string, Time] = {"path": getLastModificationTime(".")}.toTable

  while true:
    op.next()
    case op.kind
    of cmdLongOption:
      case op.key
      of "run":
        run = true
        rest = rest.replace("--run ")
      of "css":
        selectedCss = css
        rest = rest.replace("--css ")
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
  let name = file.splitFile.name
  build(name, rest, selectedCss, run)
  if watch:
    # TODO: launch http server
    while true:
      sleep(300)
      for path in walkDirRec("."):
        if ".git" in path:
          continue
        if files.hasKey(path):
          if files[path] != getLastModificationTime(path):
            echo("File changed: " & path)
            build(name, rest, selectedCss, run)
            files[path] = getLastModificationTime(path)
        else:
          files[path] = getLastModificationTime(path)

main()




