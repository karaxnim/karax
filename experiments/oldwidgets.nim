var
  linkCounter: int

proc link*(id: int): VNode =
  result = newVNode(VNodeKind.anchor)
  result.setAttr("href", "#")
  inc linkCounter
  result.setAttr("id", $linkCounter & ":" & $id)

proc link*(action: EventHandler): VNode =
  result = newVNode(VNodeKind.anchor)
  result.setAttr("href", "#")
  result.setOnclick action

when false:
  proc button*(caption: cstring; action: EventHandler; disabled=false): VNode =
    result = newVNode(VNodeKind.button)
    result.add text(caption)
    if action != nil:
      result.setOnClick action
    if disabled:
      result.setAttr("disabled", "true")

proc select*(choices: openarray[cstring]): VNode =
  result = newVNode(VNodeKind.select)
  var i = 0
  for c in choices:
    result.add tree(VNodeKind.option, [(cstring"value", toCstr(i))], text(c))
    inc i

proc select*(choices: openarray[(int, cstring)]): VNode =
  result = newVNode(VNodeKind.select)
  for c in choices:
    result.add tree(VNodeKind.option, [(cstring"value", toCstr(c[0]))], text(c[1]))

var radioCounter: int

proc radio*(choices: openarray[(int, cstring)]): VNode =
  result = newVNode(VNodeKind.fieldset)
  var i = 0
  inc radioCounter
  for c in choices:
    let id = cstring"radio_" & c[1] & toCstr(i)
    var kid = tree(VNodeKind.input, [(cstring"type", cstring"radio"),
      (cstring"id", id), (cstring"name", cstring"radio" & toCStr(radioCounter)),
      (cstring"value", toCStr(c[0]))])
    if i == 0:
      kid.setAttr(cstring"checked", cstring"checked")
    var lab = tree(VNodeKind.label, [(cstring"for", id)], text(c[1]))
    kid.add lab
    result.add kid
    inc i

proc tag*(kind: VNodeKind; id=cstring(nil), class=cstring(nil)): VNode =
  result = newVNode(kind)
  result.id = id
  result.class = class

proc tdiv*(id=cstring(nil), class=cstring(nil)): VNode = tag(VNodeKind.tdiv, id, class)
proc span*(id=cstring(nil), class=cstring(nil)): VNode = tag(VNodeKind.span, id, class)

proc valueAsInt*(e: Node): int = parseInt(e.value)

proc th*(s: cstring): VNode =
  result = newVNode(VNodeKind.th)
  result.add text(s)

proc td*(s: string): VNode =
  result = newVNode(VNodeKind.td)
  result.add text(s)

proc td*(s: VNode): VNode =
  result = newVNode(VNodeKind.td)
  result.add s

proc td*(class: cstring; s: VNode): VNode =
  result = newVNode(VNodeKind.td)
  result.add s
  result.class = class

proc table*(class=cstring(nil), kids: varargs[VNode]): VNode =
  result = tag(VNodeKind.table, nil, class)
  for k in kids: result.add k

proc tr*(kids: varargs[VNode]): VNode =
  result = newVNode(VNodeKind.tr)
  for k in kids:
    if k.kind in {VNodeKind.td, VNodeKind.th}:
      result.add k
    else:
      result.add td(k)

proc suffix*(s, prefix: cstring): cstring =
  if s.startsWith(prefix):
    result = s.substr(prefix.len)
  else:
    kout(cstring"bug! " & s & cstring" does not start with " & prefix)

proc suffixAsInt*(s, prefix: cstring): int = parseInt(suffix(s, prefix))

#proc ceil(f: float): int {.importc: "Math.ceil", nodecl.}


when false:
  var plugins {.exportc.}: seq[(string, proc())] = @[]

  proc onInput(val: cstring) =
    kout val
    if val == "dyn":
    kout(plugins.len)
    if plugins.len > 0:
      plugins[0][1]()

