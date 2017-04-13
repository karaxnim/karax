# Virtual DOM implementation

from dom import Event
import shash

type
  VNodeKind* {.pure.} = enum
    text, int, bool, vthunk, dthunk,
    anchor,
    tdiv,
    table, tr, td, th, thead, tbody,
    link, span, label, br, select, option,
    fieldset, input, button, ul, li, section, header, footer,
    h1, h2, h3, h4, h5, strong

const
  toTag*: array[VNodeKind, cstring] = [
    cstring"#text", "#int", "#bool", "#vthunk", "#dthunk",
    "A", "DIV", "TABLE", "TR", "TD",
    "TH", "THEAD",
    "TBODY", "LINK",
    "SPAN", "LABEL", "BR", "SELECT", "OPTION", "FIELDSET", "INPUT", "BUTTON", "UL",
    "LI", "SECTION", "HEADER", "FOOTER", "H1", "H2", "H3", "H4", "H5", "STRONG"
  ]

type
  EventKind* {.pure.} = enum
    onclick, ondblclick, onkeyup, onkeydown, onkeypressed, onblur, onchange, onscroll

const
  toEventName*: array[EventKind, cstring] = [
    cstring"click", "dblclick", "keyup", "keydown", "keypressed", "blur",
    "change", "scroll"
  ]

type
  EventHandler* = proc (ev: Event; target: VNode) {.closure.}
  VKey* = int
  VNode* = ref object
    kind*: VNodeKind
    key*: VKey
    id*, class*, text*: cstring
    kids: seq[VNode]
    # even index: key, odd index: value; done this way for memory efficiency:
    attrs: seq[cstring]
    events*: seq[(EventKind, EventHandler)]
    hash*: Hash
    validHash*: bool

proc value*(n: VNode): cstring = n.text
proc `value=`*(n: VNode; v: cstring) = n.text = v

proc intValue*(n: VNode): int = n.key
proc vn*(i: int): VNode = VNode(kind: VNodeKind.int, key: i)
proc vn*(b: bool): VNode = VNode(kind: VNodeKind.int, key: ord(b))
proc vn*(x: cstring): VNode = VNode(kind: VNodeKind.text, key: -1, text: x)

template callThunk*(fn: typed; n: VNode): untyped =
  ## for internal usage only.
  fn(n.kids)

proc vthunk*(name: cstring; args: varargs[VNode, vn]): VNode =
  VNode(kind: VNodeKind.vthunk, text: name, kids: @args)

proc dthunk*(name: cstring; args: varargs[VNode, vn]): VNode =
  VNode(kind: VNodeKind.dthunk, text: name, kids: @args)

proc eq*(a, b: VNode): bool =
  if a.kind != b.kind: return false
  if a.id != b.id: return false
  if a.class != b.class: return false
  if a.key != b.key: return false
  if a.kind != VNodeKind.text:
    if a.kids.len != b.kids.len: return false
    for i in 0..<a.kids.len:
      if not eq(a.kids[i], b.kids[i]): return false
  if a.text != b.text: return false
  if a.attrs.len != b.attrs.len: return false
  for i in 0..<a.attrs.len:
    if a.attrs[i] != b.attrs[i]: return false
  result = true

proc setAttr*(n: VNode; key: cstring; val: cstring = "") =
  if n.attrs.isNil:
    n.attrs = @[key, val]
  else:
    for i in countup(0, n.attrs.len-2, 2):
      if n.attrs[i] == key:
        n.attrs[i+1] = val
        return
    n.attrs.add key
    n.attrs.add val

proc getAttr*(n: VNode; key: cstring): cstring =
  for i in countup(0, n.attrs.len-2, 2):
    if n.attrs[i] == key: return n.attrs[i+1]

proc len*(x: VNode): int = x.kids.len
proc `[]`*(x: VNode; idx: int): VNode = x.kids[idx]
proc add*(parent, kid: VNode) = parent.kids.add kid
proc newVNode*(kind: VNodeKind): VNode = VNode(kind: kind, key: -1)

proc tree*(kind: VNodeKind; kids: varargs[VNode]): VNode =
  result = newVNode(kind)
  for k in kids: result.add k

proc tree*(kind: VNodeKind; attrs: openarray[(cstring, cstring)];
           kids: varargs[VNode]): VNode =
  result = tree(kind, kids)
  for a in attrs: result.setAttr(a[0], a[1])

proc text*(s: string): VNode = VNode(kind: VNodeKind.text, text: cstring(s), key: -1)
proc text*(s: cstring): VNode = VNode(kind: VNodeKind.text, text: s, key: -1)

iterator items*(n: VNode): VNode =
  for i in 0..<n.kids.len: yield n.kids[i]

iterator attrs*(n: VNode): (cstring, cstring) =
  for i in countup(0, n.attrs.len-2, 2):
    yield (n.attrs[i], n.attrs[i+1])

proc sameAttrs*(a, b: VNode): bool =
  if a.attrs.len == b.attrs.len:
    result = true
    for i in 0 ..< a.attrs.len:
      if a.attrs[i] != b.attrs[i]: return false

proc addEventListener*(n: VNode; event: EventKind; handler: EventHandler) =
  n.events.add((event, handler))

template toStringAttr(field) =
  if n.field != nil:
    result.add " " & astToStr(field) & " = " & $n.field

proc toString*(n: VNode; result: var string; indent: int) =
  for i in 1..indent: result.add ' '
  if result.len > 0: result.add '\L'
  result.add "<" & $n.kind
  toStringAttr(id)
  toStringAttr(class)
  for k, v in attrs(n):
    result.add " " & $k & " = " & $v
  result.add ">\L"
  if n.kind == VNodeKind.text:
    result.add n.text
  else:
    if n.text != nil:
      result.add " value = "
      result.add n.text
    for child in items(n):
      toString(child, result, indent+2)
  for i in 1..indent: result.add ' '
  result.add "\L</" & $n.kind & ">"

proc calcHash*(n: VNode) =
  if n.validHash: return
  n.validHash = true
  var h: Hash = ord n.kind
  if n.id != nil:
    h &= "id"
    h &= n.id
  if n.class != nil:
    h &= "class"
    h &= n.class
  if n.key >= 0:
    h &= "k"
    h &= n.key
  for k, v in attrs(n):
    h &= " "
    h &= k
    h &= "="
    h &= v
  if n.kind == VNodeKind.text or n.text != nil:
    h &= "t"
    h &= n.text
  else:
    for child in items(n):
      calcHash(child)
      h &= child.hash
  n.hash = h

proc `$`*(n: VNode): cstring =
  var res = ""
  toString(n, res, 0)
  result = cstring(res)
