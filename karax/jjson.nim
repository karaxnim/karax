## This module implements some small zero-overhead 'JsonNode' type
## and helper that maps directly to JavaScript objects.

type
  JsonNode* {.importc.} = ref object

proc `[]`*(obj: JsonNode; fieldname: cstring): JsonNode {.importcpp: "#[#]".}
proc `[]`*(obj: JsonNode; index: int): JsonNode {.importcpp: "#[#]".}
proc `[]=`*[T](obj: JsonNode; fieldname: cstring; value: T)
  {.importcpp: "#[#] = #".}
proc length(x: JsonNode): int {.importcpp: "#.length".}
proc len*(x: JsonNode): int = (if x.isNil: 0 else: x.length)

proc newJsonNode*(fields: varargs[(cstring, JsonNode)]): JsonNode =
  result = JsonNode()
  for f in fields:
    result[f[0]] = f[1]

proc newJObject*(): JsonNode =
  result = JsonNode()

proc newJNull*(): JsonNode = nil

template `%`*(x: typed): JsonNode = cast[JsonNode](x)

proc getNum*(x: JsonNode): int {.importcpp: "#".}

proc getInt*(x: JsonNode): int {.importcpp: "#".}
proc getStr*(x: JsonNode): cstring {.importcpp: "#".}
proc getFNum*(x: JsonNode): cstring {.importcpp: "#".}

iterator items*(x: JsonNode): JsonNode =
  for i in 0..<len(x): yield x[i]
