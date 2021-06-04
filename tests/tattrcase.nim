# https://github.com/karaxnim/karax/issues/100
import karax / [karaxdsl,karax, vdom, vstyles]
import karax
import strformat

proc mkCircle*(radius: int, width: int, fill: string,
               msg: string = "success"): VNode =
  let center = width / 2
  result = buildHtml(tdiv):
    svg(width = $width, height = $width, viewBox = &"0 0 {width} {width}", style = style( (StyleAttr.width, "16".cstring),(StyleAttr.height, "16".cstring) ) ):
      title: text msg
      circle(fill = "LightGreen", stroke = "gray",
              cx = $center, cy = $center, r = $radius)
proc render(): VNode =
  result = buildHtml(tdiv):
    mkCircle(6, 16, "blue", "test")

when isMainModule:
  setRenderer render