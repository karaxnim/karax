
import macros, kbase
from strutils import `%`

macro fieldNamesAsArray*(t: typed; pattern = "$1"): untyped =
  var impl = getTypeImpl(getTypeImpl(t)[1])
  if impl.kind == nnkRefTy: impl = getTypeImpl(impl[0])
  expectKind impl, nnkObjectTy
  impl = impl[2]
  expectKind impl, nnkRecList
  result = newTree(nnkBracket)
  for x in impl:
    expectKind x, nnkIdentDefs
    result.add(newCall(bindSym"kstring", newLit(pattern.strVal % $x[0])))

proc str(n: NimNode): NimNode =
  if n.kind in {nnkStrLit, nnkTripleStrLit}:
    result = newCall(bindSym"kstring", n)
  else:
    result = copyNimNode(n)
    for i in 0..<n.len:
      result.add str(n[i])

macro kstrLits*(x: untyped): untyped =
  ## Transforms every string literal "abc" to ``kstring"abc"``. This makes
  ## things much easier to write. String literals of the form ``r"abc"`` are
  ## not affected.
  result = str(x)

when isMainModule:
  type
    MyObject = ref object
      x*: string
      next*: int
      more, here*: float

  const myObjectFields = fieldNamesAsArray(MyObject, "MyObject_$1")
  for f in myObjectFields: echo f
