
import vdom, karax, karaxdsl, jdict, jstrutils, parseutils, sequtils

var
    entries: seq[cstring]

# result: 0 1 2 3 4 7 5
proc test1(ev: Event; n: VNode) =
    entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5") ]
    entries.insert(cstring("7"), 5)

# result: 8 0 1 2 3 4 7 5
proc test2(ev: Event; n: VNode) =
    entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5") ]
    entries.insert(cstring("7"), 5)
    entries.insert(cstring("8"), 0)

# result: 2 3 4 1
proc test3(ev: Event; n: VNode) =
    entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5") ]
    entries = @[cstring("2"), cstring("3"), cstring("4"), cstring("1") ]

# result: 5 6 7 8
proc test4(ev: Event; n: VNode) =
    entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5") ]
    entries = @[cstring("5"), cstring("6"), cstring("7"), cstring("8") ]

# result: 0 1 3 5 4 5
proc test5(ev: Event; n: VNode) =
    entries = @[cstring("0"), cstring("1"), cstring("2"), cstring("3"), cstring("4"), cstring("5") ]
    entries = @[cstring("0"), cstring("1"), cstring("3"), cstring("5"), cstring("4"), cstring("5") ]
     
    
proc createEntry(id: int): VNode =
  result = buildHtml():
    button(id="" & $id):
        text $id

proc createDom(): VNode =
    result = buildHtml(tdiv()):
        button(onclick=test1):
            text "Test1"
        button(onclick=test2):
            text "Test2"
        button(onclick=test3):
            text "Test3"
        button(onclick=test4):
            text "Test4"
        button(onclick=test5):
            text "Test5"
        ul():
            for e in entries:
                li:
                    createEntry(parseInt(e))
                    
                
setRenderer createDom

proc onload(session: cstring) {.exportc.} =
    for i in 0..5: # 0_000:
        entries.add(cstring($i))
    init()
