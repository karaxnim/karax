## Karax -- Single page applications for Nim.

## This module contains wrappers for the HTML 5 local storage.

proc getItem*(key: cstring): cstring {.importc: "sessionStorage.getItem".}
proc setItem*(key, value: cstring) {.importc: "sessionStorage.setItem".}
proc hasItem*(key: cstring): bool {.importcpp: "(sessionStorage.getItem(#) !== null)".}
proc clear*() {.importc: "sessionStorage.clear".}

proc removeItem*(key: cstring) {.importc: "sessionStorage.removeItem".}
