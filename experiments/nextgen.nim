
import vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils, reactive

type
  User = ref object
    firstname, lastname: cstring

var gu = @[newReactive(User(firstname: "Some", lastname: "Body")),
           newReactive(User(firstname: "Some", lastname: "One")),
           newReactive(User(firstname: "Some", lastname: "Two"))]
var clicks = 0

proc renderUser(u: Reactive[User]): VNode {.track.} =
  result = buildHtml(button):
    text u.now.firstname & " " & u.now.lastname
    proc onclick(ev: Event; n: VNode) =
      inc clicks
      u <- User(firstname: "Another", lastname: &clicks)

proc main(): VNode =
  result = buildHtml(tdiv):
    for i in 0..high(gu):
      renderUser(gu[i])

setInitializer(main)
