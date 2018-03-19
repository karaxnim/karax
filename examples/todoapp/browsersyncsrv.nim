import
  jsffi, dom, strformat, jsconsole, ospaths

import ../../karax/jstrutils except `&`

type
  js = JsObject

var
  bs = require("browser-sync").create()
  p = require "path"
  child_process = require "child_process"

var options = js{
  host: cstring "127.0.0.1",
  port: 9700,
  ui: js{ port: 9701 },
  localOnly: true,
  plugins: []
}

var
  RegExp* {.importc.}: proc (source: cstring, flag: cstring): js

template len(o: js): int = cast[int](o.length)

{.push stackTrace:off.}
proc browserCode(bs: js) =

  proc splitUrl(url: cstring): js =
    var url = url
    var hash, params: cstring

    let hashtagIdx = url.indexOf("#")
    if hashtagIdx >= 0:
      hash = url.slice(hashtagIdx)
      url = url.slice(0, hashtagIdx)
    else:
      hash = ""

    let paramIdx = url.indexOf("?")
    if paramIdx >= 0:
      params = url.slice(paramIdx)
      url = url.slice(0, paramIdx)
    else:
      params = ""

    return js{
      url: url,
      params: params,
      hash: hash
    }

  proc pathFromUrl(url: cstring): cstring =
    var url = cast[cstring](splitUrl(url).url)
    var path: cstring
    if url.indexOf("file://") == 0:
      path = url.replace(jsnew RegExp("^file://(localhost)?", ""), "")
    else:
      #                                 http:  // hostname:8080 /
      path = url.replace(jsnew RegExp("^([^:]+:)?//([^:/]+)(:\\d*)?", ""), "/")

    # decodeURI has special handling of characters such as
    # semicolons, so use decodeURIComponent:
    return decodeURIComponent(path)

  proc numberOfMatchingSegments(path1, path2: cstring): int =
    # get rid of leading slashes and normalize to lower case
    var path1 = path1.replace(jsnew RegExp("^\\/+", ""), "").toLowerCase()
    var path2 = path2.replace(jsnew RegExp("^\\/+", ""), "").toLowerCase()

    if path1 == path2:
      return 10000

    var p1dirs = path1.split("/").toJs
    var p2dirs = path2.split("/").toJs
    var len = Math.min(p1dirs.len, p2dirs.len)

    var eqCount = 0
    while eqCount <= len and
          p1dirs[<p1dirs.len - eqCount] == p2dirs[<p2dirs.len - eqCount]:
      inc eqCount

    return eqCount

  proc pathsMatch(path1, path2: cstring): bool =
    var res = numberOfMatchingSegments(path1, path2)
    return res > 0

  bs.socket.on("symbiosis-view-reloaded") do (ev: js):
    var scripts = document.querySelectorAll("script")
    for existingScript in scripts:
      let
        changedFile = cast[cstring](ev.path)
        scriptTagSrc = existingScript.getAttribute("src")

      if pathsMatch(changedFile, pathFromUrl(scriptTagSrc)):
        var newScript = document.createElement("script")
        newScript.setAttribute("type", "text/javascript")
        newScript.setAttribute("src", scriptTagSrc)

        console.log "[BS] Reloading:", newScript
        document.head.appendChild(newScript)

        var parentTag = existingScript.parentNode.toJs
        if cast[bool](parentTag):
          parentTag.removeChild existingScript
        return
{.pop.}

let browserCodeText = $(browserCode.toJs)

proc noop = discard

options.plugins.push js{
  plugin: noop,
  hooks: js{
    "client:js": cstring(fmt";({browserCodeText})(___browserSync___);")
  }
}

type
  WatchEntry = object
    rootDir: cstring
    files: seq[cstring]

bs.init(options) do (err, instance: js):
  var watchedFiles = @[
    WatchEntry(rootDir: ".", files: @[cstring("*.*"), "nimcache/*.*"])
  ]

  for entry in watchedFiles:
    let dir = entry.rootDir & "/"
    for glob in entry.files:
      let pattern = cstring(fmt"{dir}{glob}")
      console.log "[BS] Monitoring:", pattern

      bs.watch(pattern) do (event, path: cstring):
        if event != "add" and event != "change":
          return

        case splitFile($path).ext
        of ".js":
          console.log "[BS] View changed:", path
          instance.io.sockets.emit "symbiosis-view-reloaded", js{path: path}
        of ".css", ".jpg", ".png", ".gif", ".html":
          console.log "[BS] Static file changed:", path
          bs.reload p.basename(path)

