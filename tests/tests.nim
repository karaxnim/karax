import kdom, vdom, karax, karaxdsl, jstrutils, sequtils
import future
import test_utils
import jasmine

installRootTag()


describe("Dom diffing of simple seq model") do ():

  proc initValues(): auto = @[0, 1, 2, 3, 4, 5].map(x => cstring($x))

  var entries = initValues()

  proc createEntry(id: int): VNode =
    result = buildHtml():
      button(id = $id):
        text $id

  proc createDom(): VNode =
    result = buildHtml(tdiv()):
      ul():
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
        node("ul", children = @[
          node("button", id="0", children = @[ntext "0"]),
          node("button", id="1", children = @[ntext "1"]),
          node("button", id="2", children = @[ntext "2"]),
          node("button", id="3", children = @[ntext "3"]),
          node("button", id="4", children = @[ntext "4"]),
          node("button", id="5", children = @[ntext "5"]),
        ])
      ])
      done()

  it("should handle single insertion") do (done: Done):

    entries.insert(cstring("7"), 5)
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        node("ul", children = @[
          node("button", id="0", children = @[ntext "0"]),
          node("button", id="1", children = @[ntext "1"]),
          node("button", id="2", children = @[ntext "2"]),
          node("button", id="3", children = @[ntext "3"]),
          node("button", id="4", children = @[ntext "4"]),
          node("button", id="7", children = @[ntext "7"]),
          node("button", id="5", children = @[ntext "5"]),
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
        node("ul", children = @[
          node("button", id="8", children = @[ntext "8"]),
          node("button", id="0", children = @[ntext "0"]),
          node("button", id="1", children = @[ntext "1"]),
          node("button", id="2", children = @[ntext "2"]),
          node("button", id="3", children = @[ntext "3"]),
          node("button", id="4", children = @[ntext "4"]),
          node("button", id="7", children = @[ntext "7"]),
          node("button", id="5", children = @[ntext "5"]),
        ])
      ])
      done()

  it("should handle replacing the seq") do (done: Done):

    entries = @[2, 3, 4, 1].map(x => cstring($x))
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        node("ul", children = @[
          node("button", id="2", children = @[ntext "2"]),
          node("button", id="3", children = @[ntext "3"]),
          node("button", id="4", children = @[ntext "4"]),
          node("button", id="1", children = @[ntext "1"]),
        ])
      ])
      done()

  it("should handle a single-element seq") do (done: Done):

    entries = @[cstring"42"]
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        node("ul", children = @[
          node("button", id="42", children = @[ntext "42"]),
        ])
      ])
      done()

  it("should handle an empty seq") do (done: Done):

    entries = @[]
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.getElementById("ROOT").innerHTML)
      expectDomToMatch("ROOT", @[
        node("ul")
      ])
      done()


describe("The testing framework") do ():

  beforeAll() do ():
    clearRootTag()

  it("should verify number of children") do (done: Done):
    proc createDom(): VNode =
      result = buildHtml():
        span(id="NOT-ROOT", class="test"): # id is not applied
          tdiv()
          tdiv()
    setRenderer createDom
    kxi.redraw()

    simpleTimeout() do ():
      # kout(document.body.innerHTML)
      # 2 => okay
      expectDomToMatch("ROOT", @[
        node("div"), node("div"),
      ])
      # 1 or 3 should raise
      expect(() => expectDomToMatch("ROOT", @[
        node("div"),
      ])).toThrowErrorRegexp("Check number of children")
      expect(() => expectDomToMatch("ROOT", @[
        node("div"), node("div"), node("div"),
      ])).toThrowErrorRegexp("Check number of children")
      done()

  it("should verify id") do (done: Done):
    proc createDom(): VNode =
      result = buildHtml():
        tdiv():
          tdiv(id="1")
          tdiv(id="2")
          tdiv()
    setRenderer createDom
    kxi.redraw()

    simpleTimeout() do ():
      expectDomToMatch("ROOT", @[
        node("div", id="1"),
        node("div", id="2"),
        node("div"),
      ])
      expect(() => expectDomToMatch("ROOT", @[
        node("div", id="11"),
        node("div", id="2"),
        node("div"),
      ])).toThrowErrorRegexp(".*id matching.*")
      expect(() => expectDomToMatch("ROOT", @[
        node("div", id="1"),
        node("div", id="2"),
        node("div", id="3"),
      ])).toThrowErrorRegexp(".*id matching.*")
      expect(() => expectDomToMatch("ROOT", @[
        node("div"),
        node("div"),
        node("div"),
      ])).toThrowErrorRegexp(".*id empty check.*")
      done()

  it("should verify class") do (done: Done):
    proc createDom(): VNode =
      result = buildHtml():
        tdiv():
          tdiv(class="1")
          tdiv(class="2")
          tdiv()
    setRenderer createDom
    kxi.redraw()

    simpleTimeout() do ():
      expectDomToMatch("ROOT", @[
        node("div", class="1"),
        node("div", class="2"),
        node("div"),
      ])
      expect(() => expectDomToMatch("ROOT", @[
        node("div", class="11"),
        node("div", class="2"),
        node("div"),
      ])).toThrowErrorRegexp(".*class matching.*")
      expect(() => expectDomToMatch("ROOT", @[
        node("div", class="1"),
        node("div", class="2"),
        node("div", class="3"),
      ])).toThrowErrorRegexp(".*class matching.*")
      expect(() => expectDomToMatch("ROOT", @[
        node("div"),
        node("div"),
        node("div"),
      ])).toThrowErrorRegexp(".*class empty check.*")
      done()

  it("should verify text nodes") do (done: Done):
    proc createDom(): VNode =
      result = buildHtml():
        tdiv():
          tdiv():
            text "A"
          tdiv():
            text "B"
            text "C"
    setRenderer createDom
    kxi.redraw()

    simpleTimeout() do ():
      expectDomToMatch("ROOT", @[
        node("div", children = @[ntext "A"]),
        node("div", children = @[ntext "B", ntext "C"]),
      ])
      expect(() => expectDomToMatch("ROOT", @[
        node("div", children = @[ntext "a"]),
        node("div", children = @[ntext "B", ntext "C"]),
      ])).toThrowErrorRegexp(".*Text comparison.*")
      done()
