## Components in Karax are built by the ``.component`` macro annotation.

import macros, jdict, dom, vdom, tables, strutils

type
  StateDict*[V] = ref object

proc `[]`*[V](d: StateDict[V], k: VKey): V {.importcpp: "#[#]".}
proc put[V](d: StateDict[V], k: VKey, v: V) {.importcpp: "#[#] = #".}

proc contains*[V](d: StateDict[V], k: VKey): bool {.importcpp: "#.hasOwnProperty(#)".}
proc del*[V](d: StateDict[V], k: VKey) {.importcpp: "delete #[#]".}

proc newStateDict*[V](): StateDict[V] {.importcpp: "{@}".}

var
  dirty = newStateDict[bool]()
  someDirty*: bool

proc markDirty*(key: VKey) =
  dirty.put(key, true)
  someDirty = true

proc unmarkDirty*(key: VKey) = dirty.del key
proc isDirty*(key: VKey): bool = dirty.contains(key)

proc `[]=`*[V](d: StateDict[V], k: VKey, v: V) =
  d.put(k, v)
  markDirty(k)

var
  vcomponents* = newJDict[cstring, proc(args: seq[VNode]): VNode]()
  dcomponents* = newJDict[cstring, proc(args: seq[VNode]): Node]()

type
  ComponentKind* {.pure.} = enum
    None,
    Tag,
    VNode,
    Node

var
  allcomponents {.compileTime.} = initTable[string, ComponentKind]()

proc isComponent*(x: string): ComponentKind {.compileTime.} =
  allcomponents.getOrDefault(x)

proc addTags() {.compileTime.} =
  let x = (bindSym"VNodeKind").getTypeImpl
  expectKind(x, nnkEnumTy)
  for i in ord(VNodeKind.html)..ord(VNodeKind.high):
    # +1 because of empty node at the start of the enum AST:
    let tag = $x[i+1]
    allcomponents[tag] = ComponentKind.Tag

static:
  addTags()

proc stateDecl(n: NimNode; names: TableRef[string, bool]) =
  case n.kind
  of nnkVarSection, nnkLetSection:
    for c in n:
      expectKind c, nnkIdentDefs
      for i in 0 .. c.len-3:
        let v = $c[i]
        names[v] = true
  of nnkStmtList, nnkStmtListExpr:
    for x in n: stateDecl(x, names)
  of nnkDo:
    stateDecl(n.body, names)
  else: discard

proc accessesState(n: NimNode; names: TableRef[string, bool]): bool =
  case n.kind
  of nnkSym, nnkIdent:
    result = $n in names
  of nnkBracketExpr, nnkDotExpr:
    result = accessesState(n[0], names)
  else:
    for i in 0..<n.len:
      if accessesState(n[i], names): return true

proc doState(n: NimNode; names: TableRef[string, bool];
             outer: NimNode): NimNode =
  result = n
  case n.kind
  of nnkCallKinds:
    # handle 'state' declaration and move it to the outer block:
    if n.len == 2 and repr(n[0]) == "state":
      stateDecl(n[1], names)
      outer.add n[1]
      result = newEmptyNode()
  of nnkAsgn, nnkFastAsgn:
    if accessesState(n[0], names):
      result = newStmtList(n, newCall(bindSym"markDirty", newIdentNode"key"))
  else:
    for i in 0..<n.len:
      result[i] = doState(n[i], names, outer)

proc compBody(body, outer: NimNode): NimNode =
  var names = newTable[string, bool]()
  result = doState(body, names, outer)

proc unpack(symbolicType: NimNode; index: int): NimNode {.compileTime.} =
  #let t = symbolicType.getTypeImpl
  let t = repr(symbolicType)
  case t
  of "cstring":
    result = quote do:
      args[`index`].text
  of "int", "VKey":
    result = quote do:
      args[`index`].intValue
  of "bool":
    result = quote do:
      args[`index`].intValue != 0
  elif t.endsWith"Kind":
    result = quote do:
      `symbolicType`(args[`index`].intValue)
  else:
    # just pass it along, maybe there is some conversion for it:
    result = quote do:
      args[`index`]

proc newname*(n: NimNode): NimNode =
  if n.kind == nnkPostfix:
    n[1] = newname(n[1])
    result = n
  elif n.kind == nnkSym:
    result = ident($n.symbol)
  else:
    result = n

macro component*(prc: untyped): untyped =
  ## A component takes an proc body and registers it as a component to the
  ## virtual dom.
  var n = prc.copyNimNode
  for i in 0..6: n.add prc[i].copyNimTree
  expectKind(n, nnkProcDef)
  if n[0].kind == nnkEmpty:
    error("please pass a non anonymous proc", n[0])
  let name = n[0]
  let params = params(n)
  let rettype = repr params[0]
  var isvirtual = ComponentKind.None
  if rettype == "VNode":
    isvirtual = ComponentKind.VNode
  elif rettype == "Node":
    isvirtual = ComponentKind.Node
  else:
    error "component must return VNode or Node", params[0]
  let realName = if name.kind == nnkPostfix: name[1] else: name
  let nn = $realName
  n[0] = ident("inner" & nn)
  var unpackCall = newCall(n[0])
  var counter = 0
  for i in 1.. <params.len:
    let param = params[i]
    let L = param.len
    let typ = param[L-2]
    for j in 0 .. L-3:
      unpackCall.add unpack(typ, counter)
      inc counter

  let outer = newTree(nnkStmtList)
  discard compBody(n.body, outer)

  template vwrapper(pname, unpackCall) {.dirty.} =
    proc pname(args: seq[VNode]): VNode =
      unpackCall

  template dwrapper(pname, unpackCall) {.dirty.} =
    proc pname(args: seq[VNode]): Node =
      unpackCall

  template vregister(key, val) =
    bind jdict.`[]=`
    `[]=`(vcomponents, cstring(key), val)

  template dregister(key, val) =
    bind jdict.`[]=`
    `[]=`(dcomponents, cstring(key), val)

  outer.add n
  #outer.add body
  outer.add unpackCall
  result = newTree(nnkStmtList)
  if isvirtual == ComponentKind.VNode:
    result.add getAst(vwrapper(newname name, outer))
    result.add getAst(vregister(newLit(nn), realName))
  else:
    result.add getAst(dwrapper(newname name, outer))
    result.add getAst(dregister(newLit(nn), realName))
  allcomponents[nn] = isvirtual
  when defined(debugKaraxDsl):
    echo repr result

when isMainModule:
  proc public*(key: VKey; x, y: int, b: bool; s: cstring): VNode {.component.} =
    state:
      var foo = 89

    proc callback() =
      foo = 78

    let cc = callback

  proc private(x, y: int, b: bool; s: cstring): VNode {.component.} =
    discard

