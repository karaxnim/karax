
import karax / [karax, karaxdsl, vdom, kdom, compact]

const
  Play = 0
  Big = 1
  Small = 2
  Normal = 3

proc paused(n: Node): bool {.importcpp: "#.paused".}
proc play(n: Node) {.importcpp.}
proc pause(n: Node) {.importcpp.}
proc `width=`(n: Node, w: int) {.importcpp: "#.width = #".}

proc mplayer*(id, resource: cstring): VNode {.compact.} =
  proc handler(ev: Event; n: VNode) =
    let myVideo = document.getElementById(id)
    case n.index
    of Play:
      if myVideo.paused:
        myVideo.play()
      else:
        myVideo.pause()
    of Big: myVideo.width = 560
    of Small: myVideo.width = 320
    of Normal: myVideo.width = 420
    else: discard

  result = buildHtml(tdiv):
    button(onclick=handler, index=Play):
      text "Play/Pause"
    button(onclick=handler, index=Big):
      text "Big"
    button(onclick=handler, index=Small):
      text "Small"
    button(onclick=handler, index=Normal):
      text "Normal"
    br()
    br()
    video(id=id, width="420"):
      source(src=resource, `type`="video/mp4"):
        text "Your browser does not support HTML5 video."
