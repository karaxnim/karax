# For now we only test that the things still compile.

import os

proc exec(cmd: string) =
  if os.execShellCmd(cmd) != 0:
    quit "command failed " & cmd

proc main =
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
