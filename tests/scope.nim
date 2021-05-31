include karax / prelude

proc render():VNode = 
  build_html tdiv:
    block:
      let a = 1
      tdiv():
        text $a
    block:
      let a = 2
      tdiv():
        text $a

setRenderer render
