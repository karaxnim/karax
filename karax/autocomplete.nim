
import karax, karaxdsl, vdom, kdom, jstrutils

type
  AutocompleteState* = ref object
    choices, candidates: seq[cstring]
    selected, maxMatches: int
    showCandidates, controlPressed: bool

proc newAutocomplete*(choices: seq[cstring]; maxMatches = 5): AutocompleteState =
  ## Creates a new state for the autocomplete widget. ``maxMatches`` is the maximum
  ## number of elements to show.
  AutocompleteState(choices: choices, candidates: @[],
    selected: -1, maxMatches: maxMatches, showCandidates: false,
    controlPressed: false)

proc autocomplete*(s: AutocompleteState; onselection: proc(s: cstring)): VNode =
  var inp: VNode

  proc commit(ev: Event) =
    s.showCandidates = false
    onselection(inp.dom.value)
    when false:
      if inp.dom != nil:
        echo "setting to A ", inp.dom.value.isNil
        result.text = inp.dom.value
      else:
        echo "setting to B ", inp.text.isNil
        result.text = inp.text
      for e in result.events:
        if e[0] == EventKind.onchange:
          e[1](ev, result)

  proc onkeyuplater(ev: Event; n: VNode) =
    if not s.controlPressed:
      let v = n.value
      s.candidates.setLen 0
      for c in s.choices:
        if v.len == 0 or c.containsIgnoreCase(v): s.candidates.add(c)

  proc onkeydown(ev: Event; n: VNode) =
    const
      LEFT = 37
      UP = 38
      RIGHT = 39
      DOWN = 40
      TAB = 9
      ESC = 27
      ENTER = 13
    # UP: Move focus to the previous item. If on first item, move focus to the input.
    #     If on the input, move focus to last item.
    # DOWN: Move focus to the next item. If on last item, move focus to the input.
    #       If on the input, move focus to the first item.
    # ESCAPE: Close the menu.
    # ENTER: Select the currently focused item and close the menu.
    # TAB: Select the currently focused item, close the menu, and
    #      move focus to the next focusable element
    s.controlPressed = false
    case ev.keyCode
    of UP:
      s.controlPressed = true
      s.showCandidates = true
      if s.selected > 0:
        dec s.selected
        n.setInputText s.candidates[s.selected]
    of DOWN:
      s.controlPressed = true
      s.showCandidates = true
      if s.selected < s.candidates.len - 1:
        inc s.selected
        n.setInputText s.candidates[s.selected]
    of ESC:
      s.showCandidates = false
      s.controlPressed = true
    of ENTER:
      s.controlPressed = true
#      inp.setInputText s.choices[i]
      commit(ev)
    else:
      discard

  proc window(s: AutocompleteState): (int, int) =
    var first, last: int
    if s.selected >= 0:
      first = s.selected - (s.maxMatches div 2)
      last = s.selected + (s.maxMatches div 2)
      if first < 0: first = 0
      # too few because we had to trim first?
      if (last - first + 1) < s.maxMatches: last = first + s.maxMatches - 1
    else:
      first = 0
      last = s.maxMatches - 1
    if last > high(s.candidates): last = high(s.candidates)
    # still too few because we're at the end?
    if (last - first + 1) < s.maxMatches:
      first = last - s.maxMatches + 1
      if first < 0: first = 0

    result = (first, last)

  inp = buildHtml:
    input(onkeyuplater = onkeyuplater,
      onkeydown = onkeydown,
      # onblur = proc (ev: Event; n: VNode) = commit(ev),
      onfocus = proc (ev: Event; n: VNode) =
        onkeyuplater(ev, n)
        s.showCandidates = true)

  proc select(i: int): proc(ev: Event; n: VNode) =
    result = proc(ev: Event; n: VNode) =
      s.selected = i
      s.showCandidates = false
      inp.setInputText s.choices[i]
      commit(ev)

  result = buildHtml(table):
    tr:
      td:
        inp
    if s.showCandidates:
      let (first, last) = window(s)
      for i in first..last:
        tr:
          td(onclick = select(i), class = cstring"button " &
              (if i == s.selected: cstring"is-primary" else: "")):
            text s.candidates[i]

when isMainModule:
  const suggestions = @[cstring"ActionScript",
    "AppleScript",
    "Asp",
    "BASIC",
    "C",
    "C++",
    "Clojure",
    "COBOL",
    "Erlang",
    "Fortran",
    "Groovy",
    "Haskell",
    "Java",
    "JavaScript",
    "Lisp",
    "Nim",
    "Perl",
    "PHP",
    "Python",
    "Ruby",
    "Scala",
    "Scheme"]

  var s = newAutocomplete(suggestions)

  proc main(): VNode =
    result = buildHtml(tdiv):
      autocomplete(s, proc (s: cstring) = echo "now ", s)#:
      #  proc onchange(ev: Event; n: VNode) =
      #    echo "now selected ", n.kind

  setRenderer(main)
