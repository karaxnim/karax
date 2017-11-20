
include login

const
  message = "message"

type
  TextMessage = ref object
    name, content: kstring

var allMessages: seq[TextMessage] = @[]

proc doSendMessage() =
  let inputField = getVNodeById(message)
  allMessages.add(TextMessage(name: "you", content: inputField.text))
  inputField.setInputText ""

proc main(): VNode =
  result = buildHtml(tdiv):
    loginDialog()
    tdiv:
      table:
        for m in allMessages:
          tr:
            td:
              bold:
                text m.name
            td:
              text m.content
    tdiv:
      if loggedIn:
        label(`for` = message):
          text "Message: "
        input(class = "input", id = message, onkeyupenter = doSendMessage)

setRenderer main
