
include karax / prelude
from sugar import `=>`
import karax / errors

proc loginField(desc, field, class: kstring;
                validator: proc (field: kstring): proc ()): VNode =
  result = buildHtml(tdiv):
    label(`for` = field):
      text desc
    input(class = class, id = field, onchange = validator(field))

# some consts in order to prevent typos:
const
  username = kstring"username"
  password = kstring"password"

proc validateNotEmpty(field: kstring): proc () =
  result = proc () =
    let x = getVNodeById(field)
    if x.text.isNil or x.text == "":
      errors.setError(field, field & " must not be empty")
    else:
      errors.setError(field, "")

var loggedIn: bool

proc loginDialog(): VNode =
  result = buildHtml(tdiv):
    if not loggedIn:
      loginField("Name :", username, "input", validateNotEmpty)
      loginField("Password: ", password, "password", validateNotEmpty)
      button(onclick = () => (loggedIn = true), disabled = errors.disableOnError()):
        text "Login"
      p:
        text errors.getError(username)
      p:
        text errors.getError(password)
    else:
      p:
        text "You are now logged in."

setError username, username & " must not be empty"
setError password, password & " must not be empty"

when not declared(toychat):
  setRenderer loginDialog
