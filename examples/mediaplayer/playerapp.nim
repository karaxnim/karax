## Example app that shows how to write and embed a custom component.

include karax/prelude
import mediaplayer

const url = "https://www.w3schools.com/html/mov_bbb.mp4"

proc createDom(): VNode =
  result = buildHtml(table):
    tr:
      td:
        mplayer("vid1", url)
      td:
        mplayer("vid2", url)
    tr:
      td:
        mplayer("vid3", url)
      td:
        mplayer("vid4", url)

setRenderer createDom
