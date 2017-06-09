## Example app that shows how to write and embed a custom component.

include karaxprelude
import mediaplayer, kdom

var karax: KaraxInstance

const url = "https://www.w3schools.com/html/mov_bbb.mp4"

proc createDom(): VNode =
  result = karax.buildHtml(table):
    tr:
      td:
        mplayer(karax, "vid1", url)
      td:
        mplayer(karax, "vid2", url)
    tr:
      td:
        mplayer(karax, "vid3", url)
      td:
        mplayer(karax, "vid4", url)

window.onload = proc(ev: Event) =
  karax = initKarax(createDom)
