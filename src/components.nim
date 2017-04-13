## Components in Karax are built by the ``.component`` macro annotation.

import macros, jdict, dom, vdom, tables, strutils

var
  vcomponents* = newJDict[cstring, proc(args: seq[VNode]): VNode]()
  dcomponents* = newJDict[cstring, proc(args: seq[VNode]): Node]()

type
  ComponentKind* {.pure.} = enum
    None,
    VNode,
    Node

var
  allcomponents {.compileTime.} = initTable[string, ComponentKind]()

proc isComponent*(x: string): ComponentKind {.compileTime.} =
  allcomponents.getOrDefault(x)

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
    error("please pass a non anonymous proc")
  let name = n[0]
  let params = params(n)
  let rettype = repr params[0]
  var isvirtual = ComponentKind.None
  if rettype == "VNode":
    isvirtual = ComponentKind.VNode
  elif rettype == "Node":
    isvirtual = ComponentKind.Node
  else:
    error "component must return VNode or Node"
  n[0] = ident("inner" & $name)
  var unpackCall = newCall(n[0])
  var counter = 0
  for i in 1.. <params.len:
    let param = params[i]
    let L = param.len
    let typ = param[L-2]
    for j in 0 .. L-3:
      unpackCall.add unpack(typ, counter)
      inc counter

  template vwrapper(wname, nameStrLit, unpackCall) {.dirty.} =
    proc wname*(args: seq[VNode]): VNode =
      unpackCall
    vcomponents[cstring(nameStrLit)] = wname

  template dwrapper(wname, nameStrLit, unpackCall) {.dirty.} =
    proc wname(args: seq[VNode]): Node =
      unpackCall
    dcomponents[cstring(nameStrLit)] = wname

  result = newTree(nnkStmtList, n)
  if isvirtual == ComponentKind.VNode:
    result.add getAst(vwrapper(newname name, newLit($name), unpackCall))
  else:
    result.add getAst(dwrapper(newname name, newLit($name), unpackCall))
  allcomponents[$name] = isvirtual
  when defined(debugKaraxDsl):
    echo repr result

when isMainModule:
  proc foo(x, y: int, b: bool; s: cstring): VNode {.component.} =
    discard


