
import macros, vdom, compact, kbase
from strutils import startsWith, toLowerAscii, cmpIgnoreStyle

when defined(js):
  import karax

const
  StmtContext = ["kout", "inc", "echo", "dec", "!"]
  SpecialAttrs = ["id", "class", "value", "index", "style"]

proc getName(n: NimNode): string =
  case n.kind
  of nnkIdent, nnkSym:
    result = $n
  of nnkAccQuoted:
    result = ""
    for i in 0..<n.len:
      result.add getName(n[i])
  of nnkStrLit..nnkTripleStrLit:
    result = n.strVal
  of nnkInfix:
    # allow 'foo-bar' syntax:
    if n.len == 3 and $n[0] == "-":
      result = getName(n[1]) & "-" & getName(n[2])
    else:
      expectKind(n, nnkIdent)
  of nnkDotExpr:
    result = getName(n[0]) & "." & getName(n[1])
  of nnkOpenSymChoice, nnkClosedSymChoice:
    result = getName(n[0])
  else:
    #echo repr n
    expectKind(n, nnkIdent)

proc toKstring(n: NimNode): NimNode =
  if n.kind == nnkStrLit:
    result = newCall(bindSym"kstring", n)
  else:
    result = copyNimNode(n)
    for child in n:
      result.add toKstring(child)

proc newDotAsgn(tmp: NimNode, key: string, x: NimNode): NimNode =
  result = newTree(nnkAsgn, newDotExpr(tmp, newIdentNode key), x)

proc handleNoRedrawPragma(call: NimNode, tmpContext, name, anon: NimNode): NimNode =
  when defined(js):
    if anon.pragma.kind == nnkPragma and len(anon.pragma) > 0:
      var hasNoRedrawPragma = false
      for i in 0 ..< len(anon.pragma):
        # using anon because anon needs to get rid of the pragma
        if anon.pragma[i].kind == nnkIdent and cmpIgnoreStyle(anon.pragma[i].strVal, "noredraw") == 0:
          hasNoRedrawPragma = true
          anon.pragma.del(i)
          break
      if hasNoRedrawPragma:
        return newCall(ident"addEventHandlerNoRedraw", tmpContext,
                       newDotExpr(bindSym"EventKind", name), anon)
  result = call

proc tcall2(n, tmpContext: NimNode): NimNode =
  # we need to distinguish statement and expression contexts:
  # every call statement 's' needs to be transformed to 'dest.add s'.
  # If expressions need to be distinguished from if statements. Since
  # we know we start in a statement context, it's pretty simple to
  # figure out expression contexts: In calls everything is an expression
  # (except for the last child of the macros we consider here),
  # lets, consts, types can be considered as expressions
  # case is complex, calls are assumed to produce a value.
  when defined(js):
    template evHandler(): untyped = bindSym"addEventHandler"
  else:
    template evHandler(): untyped = ident"addEventHandler"

  case n.kind
  of nnkLiterals, nnkIdent, nnkSym, nnkDotExpr, nnkBracketExpr:
    if tmpContext != nil:
      result = newCall(bindSym"add", tmpContext, n)
    else:
      result = n
  of nnkForStmt, nnkIfExpr, nnkElifExpr, nnkElseExpr,
      nnkOfBranch, nnkElifBranch, nnkExceptBranch, nnkElse,
      nnkConstDef, nnkWhileStmt, nnkIdentDefs, nnkVarTuple:
    # recurse for the last son:
    result = copyNimTree(n)
    let L = n.len
    assert n.len == result.len
    if L > 0:
      result[L-1] = tcall2(result[L-1], tmpContext)
  of nnkStmtList, nnkStmtListExpr, nnkWhenStmt, nnkIfStmt, nnkTryStmt,
     nnkFinally, nnkBlockStmt, nnkBlockExpr:
    # recurse for every child:
    result = copyNimNode(n)
    for x in n:
      result.add tcall2(x, tmpContext)
  of nnkCaseStmt:
    # recurse for children, but don't add call for case ident
    result = copyNimNode(n)
    result.add n[0]
    for i in 1 ..< n.len:
      result.add tcall2(n[i], tmpContext)
  of nnkProcDef:
    let name = getName n[0]
    if name.startsWith"on":
      # turn it into an anon proc:
      let anon = copyNimTree(n)
      anon[0] = newEmptyNode()
      if tmpContext == nil:
        error "no VNode to attach the event handler to"
      else:
        let call = newCall(evHandler(), tmpContext,
                           newDotExpr(bindSym"EventKind", n[0]), anon, ident("kxi"))
        result = handleNoRedrawPragma(call, tmpContext, n[0], anon)
    else:
      result = n
  of nnkVarSection, nnkLetSection, nnkConstSection:
    result = n
  of nnkCallKinds - {nnkInfix}:
    let op = getName(n[0])
    let ck = isComponent(op)
    if ck != ComponentKind.None:
      let tmp = genSym(nskLet, "tmp")
      let call = if ck == ComponentKind.Tag:
                   newCall(bindSym"tree", newDotExpr(bindSym"VNodeKind", n[0]))
                 elif ck == ComponentKind.VNode:
                   newCall(bindSym"vthunk", newLit(op))
                 else:
                   newCall(bindSym"dthunk", newLit(op))
      result = newTree(
        if tmpContext == nil: nnkStmtListExpr else: nnkStmtList,
        newLetStmt(tmp, call))
      for i in 1 ..< n.len:
        # named parameters are transformed into attributes or events:
        let x = n[i]
        if x.kind == nnkExprEqExpr:
          let key = getName x[0]
          if key.startsWith("on"):
            result.add newCall(evHandler(),
              tmp, newDotExpr(bindSym"EventKind", x[0]), x[1], ident("kxi"))
          elif eqIdent(key, "style") and x[1].kind == nnkTableConstr:
            result.add newDotAsgn(tmp, key, newCall("style", toKstring x[1]))
          elif key in SpecialAttrs:
            result.add newDotAsgn(tmp, key, x[1])
            if key == "value":
              result.add newCall(bindSym"setAttr", tmp, newLit(key), x[1])
          elif eqIdent(key, "setFocus"):
            result.add newCall(key, tmp, x[1], ident"kxi")
          elif eqIdent(key, "events"):
            result.add newCall(bindSym"mergeEvents", tmp, x[1])
          else:
            result.add newCall(bindSym"setAttr", tmp, newLit(key), x[1])
        elif ck != ComponentKind.Tag:
          call.add x
        elif eqIdent(x, "setFocus"):
          result.add newCall(x, tmp, bindSym"true", ident"kxi")
        else:
          result.add tcall2(x, tmp)
      if tmpContext == nil:
        result.add tmp
      else:
        result.add newCall(bindSym"add", tmpContext, tmp)
    elif tmpContext != nil and op notin StmtContext:
      var hasEventHandlers = false
      for i in 1..<n.len:
        let it = n[i]
        if it.kind in {nnkProcDef, nnkStmtList}:
          hasEventHandlers = true
          break
      if not hasEventHandlers:
        result = newCall(bindSym"add", tmpContext, n)
      else:
        let tmp = genSym(nskLet, "tmp")
        var slicedCall = newCall(n[0])
        let ex = newTree(nnkStmtListExpr)
        ex.add newEmptyNode() # will become the let statement
        for i in 1..<n.len:
          let it = n[i]
          if it.kind in {nnkProcDef, nnkStmtList}:
            ex.add tcall2(it, tmp)
          else:
            slicedCall.add it
        ex[0] = newLetStmt(tmp, slicedCall)
        ex.add tmp
        result = newCall(bindSym"add", tmpContext, ex)
    elif op == "!" and n.len == 2:
      result = n[1]
    else:
      result = n
  else:
    result = n

macro buildHtml*(tag, children: untyped): VNode =
  let kids = newProc(procType=nnkDo, body=children)
  expectKind kids, nnkDo
  var call: NimNode
  if tag.kind in nnkCallKinds:
    call = tag
  else:
    call = newCall(tag)
  call.add body(kids)
  result = tcall2(call, nil)
  when defined(debugKaraxDsl):
    echo repr result

macro buildHtml*(children: untyped): VNode =
  let kids = newProc(procType=nnkDo, body=children)
  expectKind kids, nnkDo
  result = tcall2(body(kids), nil)
  when defined(debugKaraxDsl):
    echo repr result

macro flatHtml*(tag: untyped): VNode {.deprecated.} =
  result = tcall2(tag, nil)
  when defined(debugKaraxDsl):
    echo repr result
