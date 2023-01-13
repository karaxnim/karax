
##[
  An example that uses ajax to load the nim package list and display a simple searchable index
]##

import karax/[karax, karaxdsl, vdom, jstrutils, kajax, jjson]

type
  Package = object
    name, description, url: cstring

  Progress = enum
    Loading,
    Loaded

  AppState = object
    progress: Progress
    packages: seq[Package]
    searchText: cstring

var state = AppState()

proc init =
  # start a request to get the package list from github
  ajaxGet("https://raw.githubusercontent.com/nim-lang/packages/master/packages.json", @[], proc (status: int, response: cstring) =
    for json in parse(response):
      # only add entries that aren't aliases
      if not json.hasField("alias"):
        state.packages.add(Package(
          name: json["name"].getStr(),
          description: json["description"].getStr(),
          url: json["url"].getStr()
        ))
    state.progress = Loaded
  )

proc drawPackage(package: Package): VNode =
  buildHtml(tdiv(class="result")):
    h2:
      a(href=package.url):
        text package.name
    p: text package.description

proc loadingView: VNode =
  buildHtml(tdiv):
    h1: text "Loading..."

proc searchView: VNode =
  buildHtml(tdiv):
    h1: text "Search"
    input:
      proc onkeyup(e: Event, n: VNode) =
        state.searchText = n.value

    # we show up to 50 packages that match the search text. If the input is
    # empty, we just show the first 50 packages in the list
    var found = 0

    for package in state.packages:
      if state.searchText.len == 0 or package.name.contains(state.searchText) or package.description.contains(state.searchText):
        drawPackage(package)
        inc found
        if found > 50:
          break

proc main: VNode =
  if state.progress == Loading:
    loadingView()
  else:
    searchView()

setRenderer(main)
init()
