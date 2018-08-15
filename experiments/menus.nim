## Example program that shows how to create menus with Karax.

include prelude
import jstrutils, kdom

proc contentA(): VNode =
  result = buildHtml(tdiv):
    text "content A"

proc contentB(): VNode =
  result = buildHtml(tdiv):
    text "content B"

proc contentC(): VNode =
  result = buildHtml(tdiv):
    text "content C"



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
