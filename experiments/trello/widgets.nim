## Common widget implemenations

import knete
import std / dom

const
  cross* = kstring"x"
  plus* = kstring"+"

const
  LEFT* = 37
  UP* = 38
  RIGHT* = 39
  DOWN* = 40
  TAB* = 9
  ESC* = 27
  ENTER* = 13

proc editable*(x: kstring; onchanged: proc (value: kstring);
               isEdited = false): Element =
  proc onenter(ev: Event) = Element(ev.target).blur()
  proc submit(ev: Event) =
    onchanged(ev.target.value)
    # close the loop: This is a common pattern in Knete.
    replace(result, editable(ev.target.value, onchanged, false))

  proc makeEditable() =
    # close the loop: This is a common pattern in Knete.
    replace(result, editable(x, onchanged, true))

  result = buildHtml():
    if isEdited:
      input(class = "edit",
        onblur = submit,
        onkeyupenter = onenter,
        value = x,
        setFocus = true)
    else:
      span(onclick = makeEditable):
        text x

template bindField*(field): Element =
  editable field, proc (value: kstring) =
    field = value
