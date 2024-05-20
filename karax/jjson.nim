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

proc parse*(input: cstring): JsonNode {.importcpp: "JSON.parse(#)".}
proc hasField*(obj: JsonNode; fieldname: cstring): bool {.importcpp: "#[#] !== undefined".}

proc newJsonNode*(fields: varargs[(cstring, JsonNode)]): JsonNode =
  result = JsonNode()
  for f in fields:
    result[f[0]] = f[1]

proc newJObject*(): JsonNode =
  result = JsonNode()

proc newJArray*(elements: varargs[JsonNode]): JsonNode {.importcpp: "#".}

proc newJNull*(): JsonNode = nil

template `%`*(x: typed): JsonNode = cast[JsonNode](x)
template `%`*(x: string): JsonNode = cast[JsonNode](cstring x)

proc getNum*(x: JsonNode): int {.importcpp: "#".}

proc getInt*(x: JsonNode): int {.importcpp: "#".}
proc getStr*(x: JsonNode): cstring {.importcpp: "#".}
proc getFNum*(x: JsonNode): cstring {.importcpp: "#".}
proc getBool*(x: JsonNode): bool {.importcpp: "#".}

iterator items*(x: JsonNode): JsonNode =
  for i in 0..<len(x): yield x[i]

import macros

proc toJson(x: NimNode): NimNode {.compiletime.} =
  case x.kind
  of nnkBracket:
    result = newCall(bindSym"newJArray")
    for i in 0 ..< x.len:
      result.add(toJson(x[i]))
  of nnkTableConstr:
    result = newCall(bindSym"newJsonNode")
    for i in 0 ..< x.len:
      x[i].expectKind nnkExprColonExpr
      let key = x[i][0]
      let a = if key.kind in {nnkIdent, nnkSym, nnkAccQuoted}:
                newLit($key)
              else:
                key
      result.add newTree(nnkPar, newCall(bindSym"cstring", a), toJson(x[i][1]))
  of nnkCurly:
    x.expectLen(0)
    result = newCall(bindSym"newJObject")
  of nnkNilLit:
    result = newCall(bindSym"newJNull")
  else:
    result = newCall(bindSym"%", x)

macro `%*`*(x: untyped): untyped =
  ## Convert an expression to a JsonNode directly, without having to specify
  ## `%` for every element.
  result = toJson(x)
