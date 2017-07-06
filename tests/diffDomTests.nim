
import kdom, vdom, times, karax, karaxdsl, jdict, jstrutils, parseutils, sequtils

var
  entries: seq[cstring]
  results: seq[cstring]

proc reset() =
  entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5")]
  redrawSync()

proc checkOrder(order: seq[int]): bool =
  var ul = getElementById("ul")
  if ul == nil or len(ul.children) != len(order):
    kout ul, len(order)
    return false
  var pos = 0
  for child in ul.children:
    if child.id != $order[pos]:
      kout pos
      return false
    inc pos
  return true

proc check(name: cstring; order: seq[int]) =
  let result = checkOrder(order)
  results.add name & (if result: cstring" - OK" else: cstring" -FAIL")

proc test1() =
  results.add cstring"test1 started"
  entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5")]
  entries.insert(cstring("7"), 5)
  redrawSync()
  check("test1", @[0, 1, 2, 3, 4, 7, 5])

proc test2() =
  results.add cstring"test2 started"
  entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5")]
  entries.insert(cstring("7"), 5)
  entries.insert(cstring("8"), 0)
  redrawSync()
  check("test2", @[8, 0, 1, 2, 3, 4, 7, 5])

proc test3() =
  results.add cstring"test3 started"
  entries = @[cstring("2"), cstring("3"), cstring("4"), cstring("1")]
  redrawSync()
  check("test3", @[2, 3, 4, 1])

proc test4() =
  results.add cstring"test4 started"
  entries = @[cstring("5"), cstring("6"), cstring("7"), cstring("8") ]
  redrawSync()
  check("test4", @[5, 6, 7, 8])

proc test5() =
  results.add cstring"test5 started"
  entries = @[cstring("0"), cstring("1"), cstring("3"), cstring("5"), cstring("4"), cstring("5")]
  redrawSync()
  check("test 5", @[0, 1, 3, 5, 4, 5])

proc test6() =
  results.add cstring"test6 started"
  entries = @[]
  redrawSync()
  check("test 6", @[])

# result: 2
proc test7() =
  results.add cstring"test7 started"
  entries = @[cstring("2")]
  redrawSync()
  check("test 7", @[2])

proc createEntry(id: int): VNode =
  result = buildHtml():
    button(id="" & $id):
      text $id

proc createDom(): VNode =
  result = buildHtml(tdiv()):
    ul(id="ul"):
      for e in entries:
        createEntry(parseInt(e))
    for r in results:
      tdiv:
        text r

proc onload() =
  for i in 0..5: # 0_000:
    entries.add(cstring($i))
  test1()
  reset()
  test2()
  reset()
  test3()
  reset()
  test4()
  reset()
  test5()
  reset()
  test6()
  reset()
  test7()

setRenderer createDom
onload()
