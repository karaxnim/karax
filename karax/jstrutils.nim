# cstring handling utilities for performance

proc split*(s, sep: cstring): seq[cstring] {.importcpp, nodecl.}

proc split*(s, sep: cstring; max: int): seq[cstring] {.importcpp, nodecl.}
proc slice*(s: cstring; istart: int): cstring {.importcpp, nodecl.}
proc slice*(s: cstring; istart, iend: int): cstring {.importcpp, nodecl.}

proc endsWith*(a, b: cstring): bool {.importcpp, nodecl.}
proc startsWith*(a, b: cstring): bool {.importcpp, nodecl.}
proc contains*(a, b: cstring): bool {.importcpp: "(#.indexOf(#)>=0)", nodecl.}
proc indexOf*(a, b: cstring): int {.importcpp, nodecl.}
proc replace*(s: cstring, pattern: auto,
              replacement: cstring): cstring {.importcpp, nodecl.}
proc toLowerCase*(s: cstring): cstring {.importcpp, nodecl.}
proc toUpperCase*(s: cstring): cstring {.importcpp, nodecl.}

proc containsIgnoreCase*(a, b: cstring): bool {.
  importcpp: """(#.search(new RegExp(#.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$$\|]/g, "\\$$&") , "i"))>=0)""", nodecl.}

proc substr*(s: cstring; start: int): cstring {.importcpp: "substr", nodecl.}
proc substr*(s: cstring; start, length: int): cstring {.importcpp: "substr", nodecl.}

#proc len*(s: cstring): int {.importcpp: "#.length", nodecl.}
proc `&`*(a, b: cstring): cstring {.importcpp: "(# + #)", nodecl.}
proc toCstr*(s: int): cstring {.importcpp: "((#)+'')", nodecl.}
proc `&`*(s: int): cstring {.importcpp: "((#)+'')", nodecl.}
proc `&`*(s: bool): cstring {.importcpp: "((#)+'')", nodecl.}
proc `&`*(s: float): cstring {.importcpp: "((#)+'')", nodecl.}

proc `&`*(s: cstring): cstring {.importcpp: "(#)", nodecl.}

proc isInt*(s: cstring): bool {.asmNoStackFrame.} =
  asm """
    return `s`.match(/^[0-9]+$/);
  """

proc parseInt*(s: cstring): int {.importcpp: "parseInt(#, 10)", nodecl.}
proc parseFloat*(s: cstring): BiggestFloat {.importc, nodecl.}
