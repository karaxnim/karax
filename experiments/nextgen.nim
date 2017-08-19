
import vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils, reactive

type
  User = ref object of ReactiveBase
    firstname, lastname: cstring

var gu = newRSeq(@[ (User(firstname: "Some", lastname: "Body")),
                    (User(firstname: "Some", lastname: "One")),
                    (User(firstname: "Some", lastname: "Two"))])
var clicks = 0

discard """
  # Text gets a *reactive* string in the first place!
  # Text can register and knows how to update itself!
  proc toReact(): RString =
    observe(u):
      u.firstname & u.lastname

  let t = text(u.firstname & " " & u.lastname)
  observe(u, t.update(u.firstname & " " & u.lastname))
  t
"""

proc renderUser(u: User): VNode = #{.track.} =
  proc inner(u: User): VNode =
    result = buildHtml(tdiv):
      text u.firstname & " " & u.lastname
      button:
        text "(X)"
        proc onclick(ev: Event; n: VNode) =
          #u.firstname = "kfdj"
          #u.lastname = &clicks
          #notifyObservers(u)
          gu.deleteElem(u)

  result = inner(u)
  doTrack(u, result, inner(u))

template vmap(x: RSeq; elem, f: untyped): VNode =
  let tmp = buildHtml(elem):
    for i in 0..<len(x):
      f(x[i])
  doTrackResize(x, tmp, f(x[pos]))
  tmp

proc main(gu: RSeq[User]): VNode = #{.track.} =
  proc inner(gu: RSeq[User]): VNode =
    result = buildHtml(tdiv):
      vmap(gu, tdiv, renderUser)
      tdiv:
        button:
          text "Add User"
          proc onclick(ev: Event; n: VNode) =
            inc clicks
            gu.add User(firstname: "Added", lastname: &clicks)
  result = inner(gu)
  doTrack(gu, result, inner(gu))

proc init(): VNode = main(gu)

setInitializer(init)
