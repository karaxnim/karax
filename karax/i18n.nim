## Karax -- Single page applications for Nim.

## i18n support for Karax applications. We distinguish between:
##
## - translate:  Lookup text translations
## - localize:   Localize Date and Time objects to local formats
##
## Localization has not yet been implemented.

import languages, jdict, jstrutils

var currentLanguage = Language.enUS

proc getLanguage(): cstring =
  {.emit: "`result` = (navigator.languages && navigator.languages.length) ? navigator.languages[0] : navigator.language;".}

proc detectLanguage*(): Language =
  let x = getLanguage()
  for i in low(Language)..high(Language):
    if languageToCode[i] == x: return i
  return Language.enUS

proc setCurrentLanguage*(newLanguage = detectLanguage()) =
  currentLanguage = newLanguage

proc getCurrentLanguage*(): Language = currentLanguage

type Translation* = JDict[cstring, cstring]

var
  translations: array[Language, Translation]

proc registerTranslation*(lang: Language; t: Translation) = translations[lang] = t

proc addTranslation*(lang: Language; key, val: cstring) =
  if translations[lang].isNil: translations[lang] = newJDict[cstring, cstring]()
  translations[lang][key] = val

proc translate(x: cstring): cstring =
  let y = translations[currentLanguage]
  if y != nil and y.contains(x):
    result = y[x]
  else:
    result = x

type TranslatedString* = distinct cstring

template i18n*(x: string): TranslatedString = TranslatedString(translate(cstring x))

proc raiseInvalidFormat(errmsg: string) =
  raise newException(ValueError, errmsg)

discard """
  $[1:item|items]1$ selected.
"""

proc `{}`(x: cstring; i: int): char {.importcpp: "#.charCodeAt(#)".}
proc sadd(s: JSeq[char]; c: char) {.importcpp: "#.push(String.fromCharCode(#))".}

proc parseChoice(f: cstring; i, choice: int,
                 r: JSeq[char]) =
  var i = i
  while i < f.len:
    var n = 0
    let oldI = i
    var toAdd = false
    while i < f.len and f{i} >= '0' and f{i} <= '9':
      n = n * 10 + ord(f{i}) - ord('0')
      inc i
    if oldI != i:
      if f{i} == ':':
        inc i
      else:
        raiseInvalidFormat"':' after number expected"
      toAdd = choice == n
    else:
      # an else section does not start with a number:
      toAdd = true
    while i < f.len and f{i} != ']' and f{i} != '|':
      if toAdd: r.sadd f{i}
      inc i
    if toAdd: break
    inc i

proc join(x: JSeq[char]): cstring {.importcpp: "#.join(\"\")".}
proc add(x: JSeq[char]; y: cstring) =
  for i in 0..<y.len: x.sadd y{i}

proc `%`*(formatString: TranslatedString; args: openArray[cstring]): cstring =
  let f = cstring(formatString)
  var i = 0
  var num = 0
  var r = newJSeq[char]()
  while i < f.len:
    if f{i} == '$' and i+1 < f.len:
      inc i
      case f{i}
      of '#':
        r.add args[num]
        inc i
        inc num
      of '1'..'9', '-':
        var j = 0
        var negative = f{i} == '-'
        if negative: inc i
        while f{i} >= '0' and f{i} <= '9':
          j = j * 10 + ord(f{i}) - ord('0')
          inc i
        let idx = if not negative: j-1 else: args.len-j
        r.add args[idx]
      of '$':
        inc(i)
        r.add '$'
      of '[':
        let start = i+1
        while i < f.len and f{i} != ']': inc i
        inc i
        if i >= f.len: raiseInvalidFormat"']' expected"
        case f{i}
        of '#':
          parseChoice(f, start, parseInt args[num], r)
          inc i
          inc num
        of '1'..'9', '-':
          var j = 0
          var negative = f{i} == '-'
          if negative: inc i
          while f{i} >= '0' and f{i} <= '9':
            j = j * 10 + ord(f{i}) - ord('0')
            inc i
          let idx = if not negative: j-1 else: args.len-j
          parseChoice(f, start, parseInt args[idx], r)
        else: raiseInvalidFormat"argument index expected after ']'"
      else:
        raiseInvalidFormat("'#', '$', or number expected")
      if i < f.len and f{i} == '$': inc i
    else:
      r.sadd f{i}
      inc i
  result = join(r)


when isMainModule:
  addTranslation(Language.deDE, "$#$ -> $#$", "$2 macht $1")
  setCurrentLanguage(Language.deDE)

  echo(i18n"$#$ -> $#$" % [cstring"1", "2"])
  echo(i18n"$[1:item |items ]1$ -> $1" % [cstring"1", "2"])
  echo(i18n"$[1:item |items ]1 -> $1" % [cstring"0", "2"])
  echo(i18n"$[1:item |items ]1 -> $1" % [cstring"2", "2"])
  echo(i18n"$[1:item |items ]1$ -> $1" % [cstring"3", "2"])
  echo(i18n"$1 $[1:item |4:huha |items ]1$ -> $1" % [cstring"4", "2"])
