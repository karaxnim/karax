# Simple hashing for the JS target.

type
  Hash* = int

{.push checks: off.}
proc sdbmHash(hash: Hash, c: int): Hash {.inline.} =
  return Hash(c) + (hash shl 6) + (hash shl 16) - hash
{.pop.}

proc charCodeAt(s: cstring; i: int): int {.importcpp: "#.charCodeAt(#)".}

template `&=`*(x: var Hash, c: int) = x = sdbmHash(x, c)
template `&=`*(x: var Hash, s: cstring) =
  for i in 0..<s.len:
    let c = charCodeAt(s, i)
    x = sdbmHash(x, c)
