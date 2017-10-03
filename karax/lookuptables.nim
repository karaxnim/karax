
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

when isMainModule:
  type
    MyObject = ref object
      x*: string
      next*: int
      more, here*: float

  const myObjectFields = fieldNamesAsArray(MyObject, "MyObject_$1")
  for f in myObjectFields: echo f
