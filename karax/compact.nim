## Components in Karax are built by the ``.component`` macro annotation.

when defined(js):
  import jdict, kdom

import macros, vdom, tables, strutils, kbase

when defined(js):
  var
    vcomponents* = newJDict[cstring, proc(args: seq[VNode]): VNode]()
else:
  var
    vcomponents* = newTable[kstring, proc(args: seq[VNode]): VNode]()

type
  ComponentKind* {.pure.} = enum
    None,
    Tag,
    VNode

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

when defined(js):
  macro compact*(prc: untyped): untyped =
    ## A 'compact' tree generation proc is one that only depends on its
    ## inputs and should be stored as a compact virtual DOM tree and
    ## only expanded on demand (when its inputs changed).
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
    else:
      error "component must return VNode", params[0]
    let realName = if name.kind == nnkPostfix: name[1] else: name
    let nn = $realName
    n[0] = ident("inner" & nn)
    var unpackCall = newCall(n[0])
    var counter = 0
    for i in 1 ..< params.len:
      let param = params[i]
      let L = param.len
      let typ = param[L-2]
      for j in 0 .. L-3:
        unpackCall.add unpack(typ, counter)
        inc counter

    template vwrapper(pname, unpackCall) {.dirty.} =
      proc pname(args: seq[VNode]): VNode =
        unpackCall

    template vregister(key, val) =
      bind jdict.`[]=`
      `[]=`(vcomponents, kstring(key), val)

    result = newTree(nnkStmtList, n)

    if isvirtual == ComponentKind.VNode:
      result.add getAst(vwrapper(newname name, unpackCall))
      result.add getAst(vregister(newLit(nn), realName))
    allcomponents[nn] = isvirtual
    when defined(debugKaraxDsl):
      echo repr result
