
import macros, karax, vdom
from strutils import startsWith, toLowerAscii

const
  StmtContext = ["kout", "inc", "echo", "dec", "!"]

proc getName(n: NimNode): string =
  case n.kind
  of nnkIdent:
    result = $n.ident
  of nnkAccQuoted:
    result = ""
    for i in 0..<n.len:
      result.add getName(n[i])
  of nnkStrLit..nnkTripleStrLit:
    result = n.strVal
  else:
    #echo repr n
    expectKind(n, nnkIdent)

proc newDotAsgn(tmp: NimNode, key: string, x: NimNode): NimNode =
  result = newTree(nnkAsgn, newDotExpr(tmp, newIdentNode key), x)

proc isTag(s: string): bool =
  for i in VNodeKind.low.succ..VNodeKind.high:
    if $i == s: return true

proc tcall2(n, tmpContext: NimNode): NimNode =
  # we need to distinguish statement and expression contexts:
  # every call statement 's' needs to be transformed to 'dest.add s'.
  # If expressions need to be distinguished from if statements. Since
  # we know we start in a statement context, it's pretty simple to
  # figure out expression contexts: In calls everything is an expression
  # (except for the last child of the macros we consider here),
  # lets, consts, types can be considered as expressions
  # case is complex, calls are assumed to produce a value.
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
  of nnkStmtList, nnkStmtListExpr, nnkWhenStmt, nnkIfStmt, nnkCaseStmt,
     nnkTryStmt, nnkFinally:
    # recurse for every child:
    result = copyNimNode(n)
    for x in n:
      result.add tcall2(x, tmpContext)
  of nnkVarSection, nnkLetSection, nnkConstSection:
    result = n
  of nnkCallKinds:
    let op = getName(n[0])
    if isTag(op):
      let tmp = genSym(nskLet, "tmp")
      result = newTree(
        if tmpContext == nil: nnkStmtListExpr else: nnkStmtList,
        newLetStmt(tmp, newCall(bindSym"tree", newDotExpr(bindSym"VNodeKind", n[0]))))
      for i in 1 ..< n.len:
        # named parameters are transformed into attributes or events:
        let x = n[i]
        if x.kind == nnkExprEqExpr:
          let key = getName x[0]
          if key.startsWith("on"):
            result.add newCall(!("set" & key), tmp, x[1])
          elif key == "id" or key == "class" or key == "value":
            result.add newDotAsgn(tmp, key, x[1])
          else:
            result.add newCall(bindSym"setAttr", tmp, newLit(key), x[1])
        elif x.kind == nnkIdent:
          result.add newCall(x, tmp)
        else:
          result.add tcall2(x, tmp)
      if tmpContext == nil:
        result.add tmp
      else:
        result.add newCall(bindSym"add", tmpContext, tmp)
    elif tmpContext != nil and op notin StmtContext:
      result = newCall(bindSym"add", tmpContext, n)
    elif op == "!" and n.len == 2:
      result = n[1]
    else:
      result = n
  else:
    result = n

macro buildHtml*(tag, children: untyped): VNode =
  expectKind children, nnkDo
  var call: NimNode
  if tag.kind in nnkCallKinds:
    call = tag
  else:
    call = newCall(tag)
  call.add body(children)
  result = tcall2(call, nil)
  when defined(debugKaraxDsl):
    echo repr result

macro buildHtml*(children: untyped): VNode =
  expectKind children, nnkDo
  result = tcall2(body(children), nil)
  when defined(debugKaraxDsl):
    echo repr result
