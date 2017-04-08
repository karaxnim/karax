
import vdom, times, karax, karaxdsl, jdict, jstrutils, parseutils, sequtils

var
    entries: seq[cstring]
    timeout : Timeout

proc reset() =
    kout cstring"reset started"
    entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5") ]
    redraw()
    kout cstring"reset finished"

proc checkOrder(order : seq[int]) = 
    var ul = getElementById("ul")
    assert ul != nil
    assert len(ul.children) == len(order)
    var pos = 0
    for child in ul.children:
        assert child.id == $order[pos]
        inc pos

proc check1() =
    checkOrder(@[0, 1, 2, 3, 4, 7, 5])
    kout cstring"test1 finished"

# result: 0 1 2 3 4 7 5
proc test1() =
    kout cstring"test1 started"
    entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5") ]
    entries.insert(cstring("7"), 5)
    redraw()
    timeout = setTimeout(check1, 20)

proc check2() =
    checkOrder(@[8, 0, 1, 2, 3, 4, 7, 5])
    kout cstring"test2 finished"

# result: 8 0 1 2 3 4 7 5
proc test2() =
    kout cstring"test2 started"
    entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5") ]
    entries.insert(cstring("7"), 5)
    entries.insert(cstring("8"), 0)
    redraw()
    timeout = setTimeout(check2, 20)

proc check3() =
    checkOrder(@[2, 3, 4, 1])
    kout cstring"test3 finished"

# result: 2 3 4 1
proc test3() =
    kout cstring"test3 started"
    entries = @[cstring("2"), cstring("3"), cstring("4"), cstring("1") ]
    redraw()
    timeout = setTimeout(check3, 20)

proc check4() =
    checkOrder(@[5, 6, 7, 8])
    kout cstring"test4 finished"

# result: 5 6 7 8
proc test4() =
    kout cstring"test4 started"
    entries = @[cstring("5"), cstring("6"), cstring("7"), cstring("8") ]
    redraw()
    timeout = setTimeout(check4, 20)

proc check5() =
    checkOrder(@[0, 1, 3, 5, 4, 5])
    kout cstring"test5 finished"

# result: 0 1 3 5 4 5
proc test5() =
    kout cstring"test5 started"
    entries = @[cstring("0"), cstring("1"), cstring("3"), cstring("5"), cstring("4"), cstring("5") ]
    redraw()
    timeout = setTimeout(check5, 20)
     
proc check6() =
    checkOrder(@[])
    kout cstring"test6 finished"

# result: empty
proc test6() =
    kout cstring"test6 started"
    entries = @[]
    redraw()
    timeout = setTimeout(check6, 20)

proc check7() =
    checkOrder(@[2])
    kout cstring"test7 finished"

# result: 2
proc test7() =
    kout cstring"test7 started"
    entries = @[cstring("2")]
    redraw()
    timeout = setTimeout(check7, 20)
    
proc createEntry(id: int): VNode =
  result = buildHtml():
    button(id="" & $id):
        text $id

proc createDom(): VNode =
    result = buildHtml(tdiv()):
        ul(id="ul"):
            for e in entries:
                createEntry(parseInt(e)) 
                
setRenderer createDom

proc onload(session: cstring) {.exportc.} =
    for i in 0..5: # 0_000:
        entries.add(cstring($i))
    init()

    var dtReset = 100
    var dtTest = 500

    var t = dtReset
    timeout = setTimeout(test1, t)
    t += dtTest
    timeout = setTimeout(reset, t)
    t += dtReset

    timeout = setTimeout(test2, t)
    t += dtTest
    timeout = setTimeout(reset, t)
    t += dtReset

    timeout = setTimeout(test3, t)
    t += dtTest
    timeout = setTimeout(reset, t)
    t += dtReset

    timeout = setTimeout(test4, t)
    t += dtTest
    timeout = setTimeout(reset, t)
    t += dtReset

    timeout = setTimeout(test5, t)
    t += dtTest
    timeout = setTimeout(reset, t)
    t += dtReset

    timeout = setTimeout(test6, t)
    t += dtTest
    timeout = setTimeout(reset, t)
    t += dtReset

    timeout = setTimeout(test7, t)
    t += dtTest
    timeout = setTimeout(reset, t)
    t += dtReset
