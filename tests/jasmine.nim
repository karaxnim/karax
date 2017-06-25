## Note: Jasmine bindings are incomplete, but cover major functionality.
import future

# Not jasmine specific, maybe move into Karax core?
type
  RegExp* = ref object

proc newRegExp*(s: cstring): RegExp {.importcpp: "new RegExp(#)".}

type
  Done* = () -> void

proc beforeEach*(body: () -> void) {.importc.}
proc beforeAll*(body: () -> void) {.importc.}
proc afterEach*(body: () -> void) {.importc.}
proc afterAll*(body: () -> void) {.importc.}

proc describe*(description: cstring, body: () -> void) {.importc.}

proc it*(description: cstring, body: () -> void) {.importc.}
proc it*(description: cstring, body: (Done) -> void) {.importc.}

type
  JasmineRequireObj* {.importc.} = ref object
    `not`* {.importc: "not".}: JasmineRequireObj

proc expect*[T](x: T): JasmineRequireObj {.importc.}

proc toBe*[T](e: JasmineRequireObj, x: T) {.importcpp.}
proc toBe*[T](e: JasmineRequireObj, x: T, msg: cstring) {.importcpp.}

proc toEqual*[T](e: JasmineRequireObj, x: T) {.importcpp.}

proc toThrow*(e: JasmineRequireObj) {.importcpp.}

proc toThrowError*(e: JasmineRequireObj, msg: cstring|RegExp) {.importcpp.}

proc toThrowErrorRegExp*(e: JasmineRequireObj, msg: cstring) =
  e.toThrowError(newRegExp(msg))
