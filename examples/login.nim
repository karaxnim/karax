
include karax / prelude
from future import `=>`
import karax / errors

proc loginField(desc, field, class: kstring;
                validator: proc (field: kstring): proc ()): VNode =
  result = buildHtml(tdiv):
    label(`for` = field):
      text desc
    input(class = class, id = field, onkeyuplater = validator(field))

const
  login = kstring"login" # a const to prevent typos

proc validateNotEmpty(field: kstring): proc () =
  result = proc () =
    let x = getVNodeById(field)
    if x.text.isNil or x.text == "":
      errors.setError(login, field & " must not be empty")
    else:
      errors.setError(login, "")


# some consts in order to prevent typos:
const
  username = kstring"username"
  password = kstring"password"

var loggedIn: bool

proc loginDialog(): VNode =
  result = buildHtml(tdiv):
    if not loggedIn:
      loginField("Name :", username, "input", validateNotEmpty)
      loginField("Password: ", password, "password", validateNotEmpty)
      button(onclick = () => (loggedIn = true), disabled = errors.disableOnError()):
        text "Login"
      p:
        text errors.getError(login)
    else:
      p:
        text "You are now logged in."

setError login, username & " must not be empty"

when not declared(toychat):
  setRenderer loginDialog
