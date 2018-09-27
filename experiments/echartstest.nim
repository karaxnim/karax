import karax / [kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils, jjson]

type
  Views = enum
    Customers, Products

var
  currentView = Customers

type
  EChart* = ref object

proc echartsInit(n: Element): EChart {.importc: "echarts.init".}
proc setOption(x: EChart; option: JsonNode) {.importcpp.}

proc postRender(data: RouterData) =
  if currentView == Products:
    let myChart = echartsInit(kdom.getElementById("echartSection"))
    # specify chart configuration item and data
    let option = %*{
      "title": {
        "text": "ECharts entry example"
      },
      "tooltip": {},
      "legend": {
        "data": ["Sales"]
      },
      "xAxis": {
        "data": ["shirt","cardign","chiffon shirt","pants","heels","socks"]
      },
      "yAxis": {},
      "series": [{
        "name": "Sales",
        "type": "bar",
        "data": [5, 20, 36, 10, 10, 20]
      }]
    }
    myChart.setOption(option)

proc createDom(data: RouterData): VNode =
  let hash = data.hashPart
  if hash == cstring"#/Products": currentView = Products
  else: currentView = Customers

  result = buildHtml(tdiv):
    ul(class = "tabs"):
      for v in low(Views)..high(Views):
        li:
          a(href = "#/" & $v):
            text cstring($v)

    if currentView == Products:
      tdiv(id = "echartSection", style = style((width, kstring"600px"), (height, kstring"400px")))
    tdiv:
      text "other section"

setRenderer createDom, "ROOT", postRender
setForeignNodeId "echartSection"
