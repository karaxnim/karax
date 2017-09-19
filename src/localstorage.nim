## Karax -- Single page applications for Nim.

## This module contains wrappers for the HTML 5 local storage.

proc getItem*(key: cstring): cstring {.importc: "localStorage.getItem".}
proc setItem*(key, value: cstring) {.importc: "localStorage.setItem".}
proc hasItem*(key: cstring): bool {.importcpp: "(localStorage.getItem(#) !== null)".}
proc clear*() {.importc: "localStorage.clear".}

proc removeItem*(key: cstring) {.importc: "localStorage.removeItem".}
