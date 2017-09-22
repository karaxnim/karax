## Example program that shows how to create menus with Karax.

include karaxprelude
import jstrutils, kdom

var
  candidates: seq[cstring] = @[]
  selected: cstring
  showCandidates: bool

proc autocomplete(choices: seq[cstring]): VNode =
  proc onkeyuplater(ev: Event; n: VNode) =
    let v = n.value
    if v.len > 0:
      candidates.setLen 0
      for c in choices:
        if v in c: candidates.add(c)

  let inp = buildHtml:
    input(onkeyuplater = onkeyuplater,
      #onblur = proc () = showCandidates = false,
      onfocus = proc () = showCandidates = true)

  proc select(t: cstring): proc() =
    result = proc() =
      selected = t
      showCandidates = false
      inp.text = t
      inp.dom.value = t

  result = buildHtml(tdiv):
    inp
    if showCandidates: # or true:
      for candy in candidates:
        tdiv(onclick = select(candy)):
          text candy

proc contentA(): VNode =
  result = buildHtml(tdiv):
    text "content A"

proc contentB(): VNode =
  result = buildHtml(tdiv):
    text "content B"

proc contentC(): VNode =
  result = buildHtml(tdiv):
    text "content C"
    autocomplete(@[cstring"ActionScript",
      "AppleScript",
      "Asp",
      "BASIC",
      "C",
      "C++",
      "Clojure",
      "COBOL",
      "Erlang",
      "Fortran",
      "Groovy",
      "Haskell",
      "Java",
      "JavaScript",
      "Lisp",
      "Nim",
      "Perl",
      "PHP",
      "Python",
      "Ruby",
      "Scala",
      "Scheme"])



type
  MenuItemHandler = proc(): VNode

var content: MenuItemHandler = contentA

proc menuAction(x: MenuItemHandler): proc() =
  result = proc() = content = x

proc buildMenu(): VNode =
  result = buildHtml(tdiv):
    nav(class="navbar is-primary"):
      tdiv(class="navbar-brand"):
        a(class="navbar-item", onclick = menuAction(contentA)):
          strong:
            text "My awesome menu"

      tdiv(id="navMenuTransparentExample", class="navbar-menu"):
        tdiv(class = "navbar-start"):
          tdiv(class="navbar-item has-dropdown is-hoverable"):
            a(class="navbar-link", onclick = menuAction(contentB)):
              text "Masters"
            tdiv(class="navbar-dropdown is-boxed"):
              a(class="navbar-item", onclick = menuAction(contentC)):
                text "Inventory"
              a(class="navbar-item", onclick = menuAction(contentC)):
                text "Product"
              hr(class="navbar-divider"):
                a(class="navbar-item", onclick = menuAction(contentC)):
                  text "Product"

        tdiv(class="navbar-item has-dropdown is-hoverable"):
          a(class="navbar-link", onclick = menuAction(contentC)):
            text "Transactions"
          tdiv(class = "navbar-dropdown is-boxed", id="blogDropdown"):
            a(class="navbar-item", onclick = menuAction(contentC)):
              text "Purchase Bill"
            a(class="navbar-item", onclick = menuAction(contentC)):
              text "Purchase Return"
            a(class="navbar-item", onclick = menuAction(contentC)):
              text "Sale Bill"
            hr(class="navbar-divider"):
              a(class="navbar-item", onclick = menuAction(contentC)):
                text "Stock Adjustment"
    content()

setRenderer buildMenu
