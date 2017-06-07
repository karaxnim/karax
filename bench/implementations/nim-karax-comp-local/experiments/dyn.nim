

type
  EntryPoint = proc()


proc dynmain =
  echo "dynamically loaded"


var plugins {.importc.}: seq[(string, EntryPoint)]

plugins.add(("dyn", EntryPoint dynmain))
