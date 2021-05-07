# For now we only test that the things still compile.

import os, osproc
import parseutils

proc exec(cmd: string) =
  if os.execShellCmd(cmd) != 0:
    quit "command failed " & cmd

proc main =
  for guide in os.walkDirRec("guide"):
    let contents = guide.readFile
    var last = 0
    var trash = ""
    const startDelim = "```nim"
    const endDelim = "```"
    while true:
      last += contents.parseUntil(trash, startDelim, last)
      if last == contents.len: break # no matches found
      var code = ""
      last += contents.parseUntil(code, endDelim, last+startDelim.len)
      var res = execCmdEx("nim js -", input = code)
      if res.exitCode != 0:
        echo code
        echo res.output
        quit "Failed to compile"
  exec("nim js tests/diffDomTests.nim")
  exec("nim js tests/compiler_tests.nim")
  exec("nim js examples/todoapp/todoapp.nim")
  exec("nim js examples/scrollapp/scrollapp.nim")
  exec("nim js examples/mediaplayer/playerapp.nim")
  exec("nim js examples/carousel/carousel.nim")
  exec("nim js -d:nodejs -r tests/difftest.nim")
  exec("nim c tests/nativehtmlgen.nim")

  for test in os.walkFiles("examples/*.nim"):
    exec("nim js " & test)

main()
