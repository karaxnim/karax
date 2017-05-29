
import karax, karaxdsl, vdom, kdom, components

const
  Play = 0
  Big = 1
  Small = 2
  Normal = 3

proc paused(n: Node): bool {.importcpp: "#.paused".}
proc play(n: Node) {.importcpp.}
proc pause(n: Node) {.importcpp.}
proc `width=`(n: Node, w: int) {.importcpp: "#.width = #".}

proc mplayer*(karax: KaraxInstance, id, resource: cstring): VNode =
  proc handler(ev: Event; n: VNode) =
    let myVideo = document.getElementById(id)
    case n.key
    of Play:
      if myVideo.paused:
        myVideo.play()
      else:
        myVideo.pause()
    of Big: myVideo.width = 560
    of Small: myVideo.width = 320
    of Normal: myVideo.width = 420
    else: discard

  result = karax.buildHtml(tdiv):
    button(onclick=handler, key=Play):
      text "Play/Pause"
    button(onclick=handler, key=Big):
      text "Big"
    button(onclick=handler, key=Small):
      text "Small"
    button(onclick=handler, key=Normal):
      text "Normal"
    br()
    br()
    video(id=id, width="420"):
      source(src=resource, `type`="video/mp4"):
        text "Your browser does not support HTML5 video."
