import kdom, vdom, karax, karaxdsl, jstrutils, sequtils
import future
import test_utils
import jasmine

installRootTag()


describe("Dom diffing of simple seq model"):

  proc initValues(): auto = @[0, 1, 2, 3, 4, 5].map(x => cstring($x))

  var entries = initValues()

  proc createEntry(id: int): VNode =
    result = buildHtml():
      button(id = $id):
        text $id

  proc createDom(): VNode =
    result = buildHtml(tdiv()):
      ul(id="ul"):
        for e in entries:
          createEntry(parseInt(e))

  beforeAll() do ():
    clearRootTag()
    setRenderer createDom

  beforeEach() do ():
    entries = initValues()

  it("should match after intialization values") do (done: Done):

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        tag("ul", children = @[
          tag("button", id="0"),
          tag("button", id="1"),
          tag("button", id="2"),
          tag("button", id="3"),
          tag("button", id="4"),
          tag("button", id="5"),
        ])
      ])
      done()

  it("should handle single insertion") do (done: Done):

    entries.insert(cstring("7"), 5)
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        tag("ul", children = @[
          tag("button", id="0"),
          tag("button", id="1"),
          tag("button", id="2"),
          tag("button", id="3"),
          tag("button", id="4"),
          tag("button", id="7"),
          tag("button", id="5"),
        ])
      ])
      done()

  it("should handle double insertion") do (done: Done):

    entries.insert(cstring("7"), 5)
    entries.insert(cstring("8"), 0)
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        tag("ul", children = @[
          tag("button", id="8"),
          tag("button", id="0"),
          tag("button", id="1"),
          tag("button", id="2"),
          tag("button", id="3"),
          tag("button", id="4"),
          tag("button", id="7"),
          tag("button", id="5"),
        ])
      ])
      done()

  it("should handle replacing the seq") do (done: Done):

    entries = @[2, 3, 4, 1].map(x => cstring($x))
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        tag("ul", children = @[
          tag("button", id="2"),
          tag("button", id="3"),
          tag("button", id="4"),
          tag("button", id="1"),
        ])
      ])
      done()

  it("should handle a single-element seq") do (done: Done):

    entries = @[cstring"42"]
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        tag("ul", children = @[
          tag("button", id="42"),
        ])
      ])
      done()

  it("should handle an empty seq") do (done: Done):

    entries = @[]
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        tag("ul")
      ])
      done()
