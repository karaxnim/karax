include ../karax/prelude

block:
  type
    TestEnum {.pure.} = enum
      ValA, ValB

  var e = TestEnum.ValA

  proc renderDom(): VNode {.used.} =
    result = buildHtml():
      tdiv():
        case e
        of TestEnum.ValA:
          tdiv: text "A"
        of TestEnum.ValB:
          tdiv: text "B"

