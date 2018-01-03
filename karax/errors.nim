## Error handling logic for form input validation.

import karax, jdict

var
  gerrorMsgs = newJDict[cstring, cstring]()
  gerrorCounter = 0

proc hasErrors*(): bool = gerrorCounter != 0

proc hasError*(field: cstring): bool = gerrorMsgs.contains(field) and len(gerrorMsgs[field]) > 0

proc disableOnError*(): cstring = toDisabled(hasErrors())

proc getError*(field: cstring): cstring =
  if not gerrorMsgs.contains(field):
    result = ""
  else:
    result = gerrorMsgs[field]

proc setError*(field, msg: cstring) =
  let previous = getError(field)
  if len(msg) == 0:
    if len(previous) != 0: dec(gerrorCounter)
  else:
    if len(previous) == 0: inc(gerrorCounter)
  gerrorMsgs[field] = msg

proc clearErrors*() =
  let m = gerrorMsgs
  for k in m.keys:
    setError(k, "")
