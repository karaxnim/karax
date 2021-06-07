
type
  JDict*[K, V] = ref object

proc `[]`*[K, V](d: JDict[K, V], k: K): V {.importcpp: "#[#]".}
proc `[]=`*[K, V](d: JDict[K, V], k: K, v: V) {.importcpp: "#[#] = #".}

proc newJDict*[K, V](): JDict[K, V] {.importcpp: "{@}".}

proc toJDict*[A, B](pairs: openArray[(A, B)]): JDict[A, B] =
  result = newJDict[A, B]()
  for key, val in items(pairs): result[key] = val

proc contains*[K, V](d: JDict[K, V], k: K): bool {.importcpp: "#.hasOwnProperty(#)".}

proc del*[K, V](d: JDict[K, V], k: K) {.importcpp: "delete #[#]".}

iterator keys*[K, V](d: JDict[K, V]): K =
  var kkk: K
  {.emit: ["for (", kkk, " in ", d, ") {"].}
  yield kkk
  {.emit: ["}"].}

type
  JSeq*[T] = ref object

proc `[]`*[T](s: JSeq[T], i: int): T {.importcpp: "#[#]", noSideEffect.}
proc `[]=`*[T](s: JSeq[T], i: int, v: T) {.importcpp: "#[#] = #", noSideEffect.}

proc newJSeq*[T](len: int = 0): JSeq[T] {.importcpp: "new Array(#)".}
proc len*[T](s: JSeq[T]): int {.importcpp: "#.length", noSideEffect.}
proc add*[T](s: JSeq[T]; x: T) {.importcpp: "#.push(#)", noSideEffect.}

proc shrink*[T](s: JSeq[T]; shorterLen: int) {.importcpp: "#.length = #", noSideEffect.}
