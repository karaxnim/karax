include karaxprelude
import future, sequtils

var
  modelData = @[5, 2, 4]

  refA = VNodeRef()
  refB = VNodeRef()
  refSeq = newSeq[VNodeRef]()

proc onClick(ev: Event, n: VNode) =
  kout(refA.vnode)
  kout(refB.vnode)
  kout(refSeq.map(nref => nref.vnode))

proc secureRefSlot(i: int): VNodeRef =
  while refSeq.len <= i:
    refSeq.add(VNodeRef())
  result = refSeq[i]

proc view(): VNode =
  result = buildHtml():
    tdiv:
      button(onclick=onClick):
        text "click me"
      # storing refs to single elements is straightforward now
      tdiv(nref=refA):
        text "A"
      tdiv(nref=refB):
        text "B"
      # It's a bit more tricky when containers are involved:
      for i, x in modelData.pairs:
        tdiv(nref=secureRefSlot(i)):
          text "List item: " & $x

proc renderer(): VNode =
  view()

setRenderer renderer
