import times, jstrutils, strutils, kdom, karax, karaxdsl, vdom, tables

var
  results: seq[cstring]
  dragEventsCompleted = initTable[DragEventTypes, bool]()
  touchEventsCompleted = initTable[TouchEventTypes, bool]()
  testRunning: array[13, bool]
  testCompleted: array[13, bool]
  test2ImageDrop = false
  dblClickCount = 0
  test6ClickCount = 0
  test8Failure = false
  test10inputFocusCount = 0
  test12Failure = false

proc getLogText(text: string): cstring =
  result = "[$#]: $#" % [format(getLocalTime(getTime()), "HH:mm:ss"), $text]

proc log(text: string, clear: bool = false) =
  if clear:
    results = @[]
  results.add getLogText(text)
  echo text
  redrawSync()

  # Scroll to top after adding text using JQuery
  discard window.setTimeout("$('#results').animate({ scrollTop: 0 }, 100);", 100)
    
proc check(cond: bool, msg: string) =
  if not cond:
    log "FAIL: " & msg
    doAssert(cond, msg)

proc check(cond: bool, msg: string, warn: bool): bool =
  if not cond:
    if warn:
      log "WARNING: " & msg
    else:
      log "FAIL: " & msg
      doAssert(cond, msg)
  result = cond

proc dragDivDragStart(ev: kdom.Event) =
  dragEventsCompleted[DragStart] = true
  var dgev = cast[DragEvent](ev)
  var dragDiv = document.getElementById("dragDiv")

  if dragDiv != nil:
    var style = window.getComputedStyle(dgev.target)
    var dataX = $(parseInt(style.left) - dgev.clientX)
    var dataY = $(parseInt(style.top) - dgev.clientY)
    dgev.dataTransfer.setData("text/plain", dataX & "," & dataY)
    var img = (ImageElement)document.createElement("img")
    img.src ="https://nim-lang.org/assets/img/logo.svg"
    dgev.dataTransfer.setDragImage(img, 0, 0)

proc dragDivDragOver(ev: kdom.Event) =
  dragEventsCompleted[DragOver] = true
  ev.preventDefault()

proc touchDivTouchStart(ev: kdom.Event) =
  var tev = cast[TouchEvent](ev)
  if tev.touches.len > 0:
    let t = tev.touches[0]
    log fmt"[TE] touch start - page: {t.pageX.repr} {t.pageY.repr}"
    log fmt"[TE] touch start - radius: {t.radiusX.repr} {t.radiusY.repr}"
    log fmt"[TE] touch start - rotation: {t.rotationAngle.repr}"
    # log "[TE] touch start: " & $t.pageX & ", " & $t.pageY
    touchEventsCompleted[TouchStart] = true

proc touchDivTouchMove(ev: kdom.Event) =
  var tev = cast[TouchEvent](ev)
  if tev.touches.len > 0:
    let t = tev.touches[0]
    log "[TE] touch move: " & t.pageX.repr & ", " & t.pageY.repr
    touchEventsCompleted[TouchMove] = true

proc touchDivTouchEnd(ev: kdom.Event) =
  var tev = cast[TouchEvent](ev)
  # end has no touches so use changedTouches
  if tev.changedTouches.len > 0:
    let t = tev.changedTouches[0]
    log "[TE] touch end: " & t.pageX.repr & ", " & t.pageY.repr
    touchEventsCompleted[TouchEnd] = true
    document.getElementById("touchDiv").style.visibility = "hidden"

proc checkAllTests() =
  var allTestsPassed = true
  for a in testCompleted:
    if not a:
      allTestsPassed = false
      break
  
  if allTestsPassed:
    log "All tests completed successfully!"
  else:
    log "Some tests failed. Check the log."
    
proc completeTest13() =
  testRunning[12] = false
  testCompleted[12] = true
  log "Test 13 completed successfully."
  checkAllTests()

proc test13() =
  testRunning[12] = true
  log "Test 13 started."
  log "This test verifies KeyboardEvent getModifierState functionality."
  log "To continue, press the left CTRL key."
    
proc test12focus1(ev: kdom.Event) =
  ev.stopImmediatePropagation()

proc test12focus2(ev: kdom.Event) =
  test12Failure = true
  check false, "Unexpected listener invocation."

proc test12focus3(ev: kdom.Event) =
  test12Failure = true
  check false, "Unexpected listener invocation."

proc completeTest12() =
  if not test12Failure:
    var elmt = document.getElementById("test12input")
    elmt.style.visibility = "hidden"
    testRunning[11] = false
    testCompleted[11] = true
    log "Test 12 completed successfully."
    test13()

proc test12() =
  testRunning[11] = true
  log "Test 12 started."
  log "This test verifies stopImmediatePropagation functionality."

  var elmt = document.getElementById("test12input")
  elmt.style.visibility = "visible"
  elmt.addEventListener($Focus, test12focus1)
  elmt.addEventListener($Focus, test12focus2)
  elmt.addEventListener($Focus, test12focus3)
  elmt.focus()
  discard setTimeout(completeTest12, 500)
  
proc completeTest11() =
  document.querySelector("h3").style.visibility = "hidden"
  
  testRunning[10] = false
  testCompleted[10] = true
  log "Test 11 completed."
  test12()

proc test11() =
  testRunning[10] = true
  log "Test 11 started."
  log "This test checks querySelector and querySelectorAll."
  
  document.getElementById("test11h3").style.visibility = "visible"

  var elmt = document.querySelector("h3")
  check elmt != nil, "querySelector returned nil."
  log "text: " & $elmt.innerHTML
  check $elmt.innerHTML == "test 11", "Unexpected h3 value."

  var elmts = document.querySelectorAll("h3")
  log "elmts len: " & $elmts.len
  check elmts.len == 1, "Unexpected elmts len."

  log "text: " & $elmts[0].innerHTML
  check $elmts[0].innerHTML == "test 11", "Unexpected h3 value."

  discard setTimeout(completeTest11, 500)

proc completeTest10() =
  testRunning[9] = false
  testCompleted[9] = true
  var test10input1 = document.getElementById("test10input1")
  var test10input2 = document.getElementById("test10input2")
  test10input1.style.visibility = "hidden"
  test10input2.style.visibility = "hidden"
  log "Test 10 completed."
  test11()

proc test10inputOnfocus(ev: kdom.Event) =
  if testRunning[9]:
    inc test10inputFocusCount
    if test10inputFocusCount > 3:
      discard setTimeout(completeTest10, 500)

proc test10() =
  log "Test 10 started."
  log "This test checks element.focus()."
  testRunning[9] = true
  var test10input1 = document.getElementById("test10input1")
  var test10input2 = document.getElementById("test10input2")
  test10input1.style.visibility = "visible"
  test10input2.style.visibility = "visible"
  test10input1.addEventListener($DomEvent.Focus, test10inputOnfocus)
  test10input2.addEventListener($DomEvent.Focus, test10inputOnfocus)
  test10input1.focus()
  test10input2.focus()
  test10input1.focus()
  test10input2.focus()

proc completeTest9() =
  var test9Value = $document.getElementById("test9value").value
  doAssert(test9Value == "[test9]", "Unexpected test9 value.")
  testRunning[8] = false
  testCompleted[8] = true
  test10()

proc test9() =
  log "Test 9 started."
  log "This tests the setTimeout(w: Window, code: cstring, pause: int) proc."
  testRunning[8] = true

  discard window.setTimeout("document.getElementById('test9value').value = '[test9]';", 500)
  discard window.setTimeout(completeTest9, 1000)
  
proc completeTest8() =
  if not test8Failure:
    log "Test 8 completed successfully."
    testRunning[7] = false
    testCompleted[7] = true
    test9()
  else:
    log "Test 8 failed."

proc failTest8() =
  test8Failure = true
  check(false, "ClearTimeout failed.")

proc test8() =
  log "Test 8 started."
  log "This test checks that clearTimeout() works correctly."
  testRunning[7] = true
  var timeout = setTimeout(failTest8, 1000)
  clearTimeout(timeout)
  discard setTimeout(completeTest8, 1200)
  
proc test7() =
  log "Test 7 started."
  log "This test ensures that mouse events correctly pass button and key modifier information."
  log "To continue, right-click while holding SHIFT."
  testRunning[6] = true

# A mouseMove handler is needed (even if empty) so mouseDown will have a value for movementX and movementY
proc mouseMove(ev: kdom.Event) =
  discard

proc mouseDown(ev: kdom.Event) =
  var me = (MouseEvent)ev
  if testRunning[5]:
    log "[ME] button: " & $me.button
    log "[ME] buttons: " & $me.buttons
    log "[ME] altKey: " & $me.altKey
    log "[ME] ctrlKey: " & $me.ctrlKey
    log "[ME] metaKey: " & $me.metaKey
    log "[ME] shiftKey: " & $me.shiftKey

    log "[ME] clientX: " & $me.clientX
    check me.clientX > 0, "Unexpected clientX value."

    log "[ME] clientY: " & $me.clientY
    check me.clientY > 0, "Unexpected clientY value."

    log "[ME] movementX: " & $me.movementX
    check me.movementX > 0, "Unexpected movementX value."

    log "[ME] movementY: " & $me.movementY
    check me.movementY > 0, "Unexpected movementY value."
    
    log "[ME] offsetX: " & $me.offsetX
    check me.offsetX > 0, "Unexpected offsetX value."
    
    log "[ME] offsetY: " & $me.offsetY
    check me.offsetY > 0, "Unexpected offsetY value."

    log "[ME] pageX: " & $me.pageX
    check me.pageX > 0, "Unexpected pageX value."

    log "[ME] pageY: " & $me.pageY
    check me.pageY > 0, "Unexpected pageY value."

    log "[ME] relatedTarget == nil: " & $(me.relatedTarget == nil)

    log "[ME] screenX: " & $me.screenX
    check me.screenX > 0, "Unexpected screenX value."

    log "[ME] screenY: " & $me.screenY
    check me.screenY > 0, "Unexpected screenY value."

    log "[ME] x: " & $me.x
    check me.x > 0, "Unexpected x value."

    log "[ME] y: " & $me.y
    check me.y > 0, "Unexpected y value."

    if dblClickCount == 1:
      inc test6ClickCount

      if test6ClickCount > 1:
        testRunning[5] = false
        testCompleted[5] = true
        log "Test 6 completed successfully."
        test7()
  elif testRunning[6]:
    log "[ME] buttons: " & $me.buttons
    var passed = check(me.buttons == (int)SecondaryButton, "Unexpected buttons value.", true)
    
    log "[ME] shiftKey: " & $me.shiftKey
    passed = passed and check(me.shiftKey, "Unexpected shiftKey value.", true)
    
    var isShiftPressed = me.getModifierState($KeyboardEventKey.Shift)
    log "[ME] getModifierState shift result: " & $isShiftPressed
    passed = passed and check(isShiftPressed, "Unexpected getModifierState shift result.", true)
    
    if passed:
      log "Test 7 completed successfully."
      testRunning[6] = false
      testCompleted[6] = true

    ev.preventDefault()

    if testCompleted[6]:
      test8()

proc dblClick(ev: kdom.Event) =
  inc dblClickCount
  check dblClickCount == 1, "Unexpected double-click event invocation."
  log "Try double-clicking again."

proc test6() =
  log "Test 6 started."
  log "This test validates that addEventListener can be called by passing AddEventListenerOptions, and the options work correctly."
  log "To continue, try double-clicking the mouse."
  var options = AddEventListenerOptions(once:true)
  document.addEventListener($DomEvent.DblClick, dblClick, options)
  testRunning[5] = true

proc test5() =
  log "Test 5 started."
  log "This test validates the newly added properties: window.screen.width, window.scren.height, element.clientWidth, and element.clientHeight."
  log "window.screen.width: " & $window.screen.width
  check(window.screen.width > 0, "Unexpected value for window.screen.width.")

  log "window.screen.height: " & $window.screen.height
  check(window.screen.height > 0, "Unexpected value for window.screen.height.")
  
  var elem = document.getElementById("results")
  log "results div clientWidth: " & $elem.clientWidth
  check(elem.clientWidth > 0, "Unexpected value for clientWidth.")

  log "results div clientHeight: " & $elem.clientHeight
  check(elem.clientHeight > 0, "Unexpected value for clientHeight.")
  
  testRunning[4] = false
  testCompleted[4] = true

  log "Test 5 completed successfully."
  test6()
  
proc keyDown(ev: kdom.Event) =
  var kbev = ((KeyboardEvent)ev)
  if testRunning[2]:
    log "[KB] altKey: " & $kbev.altKey
    log "[KB] ctrlKey: " & $kbev.ctrlKey
    log "[KB] metaKey: " & $kbev.metaKey
    log "[KB] shiftKey: " & $kbev.shiftKey
    log "[KB] code: " & $kbev.code
    log "[KB] isComposing: " & $kbev.isComposing
    log "[KB] key: " & $kbev.key
    log "[KB] keyCode: " & $kbev.keyCode
    log "[KB] location: " & $kbev.location

    log "Test 3 completed successfully."
    testRunning[2] = false
    testCompleted[2] = true

    testRunning[3] = true
    log "Test 4 started."
    log "This test ensures the child events have access to base event settings."

    log "[KB] event.bubbles: " & $kbev.bubbles
    check kbev.bubbles, "Unexpected event.bubbles value."

    log "[KB] event.cancelBubble: " & $kbev.cancelBubble
    check kbev.cancelBubble == false, "Unexpected event.cancelBubble value."

    log "[KB] event.cancelable: " & $kbev.cancelable
    check kbev.cancelable, "Unexpected event.cancelable value."

    log "[KB] event.composed: " & $kbev.composed
    check kbev.composed, "Unexpected event.composed value."

    log "[KB] event.currentTarget.nodeName: " & $kbev.currentTarget.nodeName
    check kbev.currentTarget.nodeName == "#document", "Unexpected event.currentTarget.nodeName value."

    log "[KB] event.defaultPrevented: " & $kbev.defaultPrevented
    check kbev.defaultPrevented == false, "Unexpected event.defaultPrevented value."

    log "[KB] event.eventPhase: " & $kbev.eventPhase
    check EventPhase(kbev.eventPhase) == BubblingPhase, "Unexpected event.eventPhase value."

    log "[KB] event.isTrusted: " & $kbev.isTrusted
    check kbev.isTrusted, "Unexpected event.isTrusted value."

    log "[UI] kbev.detail: " & $kbev.detail

    log "[UI] kbev.view.outerHeight: " & $kbev.view.outerHeight
    check kbev.view.outerHeight > 0, "Unexpected view.outerHeight value."

    log "[UI] kbev.view.outerWidth: " & $kbev.view.outerWidth
    check kbev.view.outerWidth > 0, "Unexpected view.outerWidth value."

    testRunning[3] = false
    testCompleted[3] = true
    log "Test 4 completed."
    test5()
  elif testRunning[12]:
    if kbev.code == "ControlLeft":
      log "[KB] altKey: " & $kbev.altKey
      log "[KB] ctrlKey: " & $kbev.ctrlKey
      log "[KB] metaKey: " & $kbev.metaKey
      log "[KB] shiftKey: " & $kbev.shiftKey
      log "[KB] code: " & $kbev.code
      log "[KB] isComposing: " & $kbev.isComposing
      log "[KB] key: " & $kbev.key
      log "[KB] keyCode: " & $kbev.keyCode
      log "[KB] location: " & $kbev.location
      var isControl = kbev.getModifierState($KeyboardEventKey.Control)
      log "[KB] getModifierState result: " & $isControl
      check isControl, "Unexpected getModifierState return value."
      completeTest13()
      
proc test3() =
  log "Test 3 started."
  log "This test validates KeyboardEvent handling."
  log "Click on the browser to focus, and then press any key."
  testRunning[2] = true
  
proc dragDivDrop(ev: kdom.Event) =
  dragEventsCompleted[Drop] = true
  var dgev = cast[DragEvent](ev)
  var dragDiv = document.getElementById("dragDiv")
  var data = $dgev.dataTransfer.getData("text/plain")
  var dt = dgev.dataTransfer
  
  if not test2ImageDrop:
    var offset = data.split(",")
    var newLeft = dgev.clientX + parseInt(offset[0])
    var newTop = dgev.clientY + parseInt(offset[1])

    if newLeft < 0: newLeft = 0
    if newTop < 0: newTop = 0
    if newLeft + dragDiv.clientWidth > window.outerWidth: newLeft = window.outerWidth - dragDiv.clientWidth
    if newTop + dragDiv.clientHeight > window.outerHeight: newTop = window.outerHeight - dragDiv.clientHeight

    dragDiv.style.left = $newLeft & "px"
    dragDiv.style.top = $newTop & "px"

    if testRunning[0]:
      log "[drop] Drop coords: $#, $#" % [$newLeft, $newTop]

  if testCompleted[0] and not testCompleted[1] and not testRunning[1]:
    testRunning[1] = true
    log "Test 2 started."
    log "This test validates the DataTransfer and DataTransferItem objects passed as part of the drag events."
    var isChrome = ($navigator.userAgent).contains("Chrome")

    log "[DT] effectAllowed: " & $dt.effectAllowed
    var expectedEffectAllowed = $Uninitialized
    if isChrome:
      expectedEffectAllowed = if test2ImageDrop: $DataTransferEffectAllowed.Copy else: $DataTransferEffectAllowed.All
    check(dt.effectAllowed == $expectedEffectAllowed, "Unexpected effectAllowed value.")

    if not test2ImageDrop:
      log "[DT] dropEffect: " & $dt.dropEffect
      var expectedDropEffect = if isChrome: $DataTransferDropEffect.None else: $DataTransferDropEffect.Move
      check(dt.dropEffect == $expectedDropEffect, "Unexpected dropEffect value.")

    var expectedFilesLen = if test2ImageDrop: 1 else: 0
    log "[DT] files len: " & $dt.files.len
    check(dt.files.len == expectedFilesLen, "Unexpected files length.")
    
    var expectedItemsLen = 1
    log "[DT] items len: " & $dt.items.len
    check(dt.items.len == expectedItemsLen, "Unexpected items length.")

    var expectedItemKind = if test2ImageDrop: $DataTransferItemKind.File else: $DataTransferItemKind.String
    log "[DT] items[0].kind: " & $dt.items[0].kind
    check(dt.items[0].kind == expectedItemKind, "Unexpected item kind.")

    var expectedItemType = if test2ImageDrop: "image/png" else: "text/plain"
    log "[DT] items[0].type: " & $dt.items[0].`type`
    check(dt.items[0].`type` == expectedItemType, "Unexpected item type.")
    
    var expectedTypesLen = if not isChrome and test2ImageDrop: 2 else: 1
    log "[DT] types len: " & $dt.types.len
    check(dt.types.len == expectedTypesLen, "Unexpected types length.")

    if test2ImageDrop:
      log "[DT] types[0]: " & $dt.types[0]
      if isChrome:
        check(dt.types[0] == "Files", "Unexpected type value.")
      else:
        log "[DT] types[1]: " & $dt.types[1]
        check(dt.types[0] == "application/x-moz-file", "Unexpected type value.")
        check(dt.types[1] == "Files", "Unexpected type value.")
            
    if test2ImageDrop:
      test2ImageDrop = false

      # TODO: Determine why getAsString() does invoke callback
      # proc getAsString*(dti: DataTransferItem, callback: proc(data: cstring))
      
      var jfile = dt.items[0].getAsFile()
      log "[DT] file name: " & $jfile.name
      check(jfile.name.len > 0, "Unexpected file name length.")
          
      testCompleted[1] = true
      testRunning[1] = false
      log "Test 2 completed successfully."
      test3()
  
      ev.preventDefault()
      return

    document.getElementById("dragDiv").style.visibility = "hidden"
    log "To continue, drag a .PNG file (file type matters) anywhere on this page."
    log "NOTE: If the browser redirects to the image, then consider this test as failed."
    test2ImageDrop = true
    testRunning[1] = false

  ev.preventDefault()

proc dragDivDrag(ev: kdom.Event) =
  dragEventsCompleted[Drag] = true
  ev.preventDefault()

proc dragDivDragLeave(ev: kdom.Event) =
  dragEventsCompleted[DragLeave] = true
  if testRunning[0]:
    log "[dragLeave]"
  ev.preventDefault()

proc dragDivDragExit(ev: kdom.Event) =
  dragEventsCompleted[DragExit] = true
  if testRunning[0]:
    log "[dragExit]"
  ev.preventDefault()
  
proc dragDivDragEnd(ev: kdom.Event) =
  dragEventsCompleted[DragEnd] = true
  if testRunning[0]:
    log "[dragEnd]"
  ev.preventDefault()
      
proc dragDivDragEnter(ev: kdom.Event) =
  dragEventsCompleted[DragEnter] = true
  if testRunning[0]:
    log "[dragEnter]"
  ev.preventDefault()

proc initDragEvents() =
  log "Drag event initialization started."
  var dragDiv = document.getElementById("dragDiv")
  document.addEventListener($DragEventTypes.DragOver, dragDivDragOver, false)
  document.addEventListener($DragEventTypes.Drop, dragDivDrop, false)
  document.addEventListener($DragEventTypes.Drag, dragDivDrag, false)
  dragDiv.addEventListener($DragEventTypes.DragStart, dragDivDragStart, false)
  dragDiv.addEventListener($DragEventTypes.DragExit, dragDivDragExit, false)
  dragDiv.addEventListener($DragEventTypes.DragLeave, dragDivDragLeave, false)
  dragDiv.addEventListener($DragEventTypes.DragEnd, dragDivDragEnd, false)
  dragDiv.addEventListener($DragEventTypes.DragEnter, dragDivDragEnter, false)
  log "Drag event initialization complete."
  log "Drag the div to continue the test. Make sure you drag the div over another element."
  log "Then click the \"Check test 1 status\" button."

proc initTouchEvents() =
  log "Touch event initialization started."
  var touchDiv = document.getElementById("touchDiv")
  if touchDiv != nil:
    touchDiv.addEventListener($TouchEventTypes.TouchStart, touchDivTouchStart, false)
    touchDiv.addEventListener($TouchEventTypes.TouchMove, touchDivTouchMove, false)
    touchDiv.addEventListener($TouchEventTypes.TouchEnd, touchDivTouchEnd, false)
    log "Touch event initialization complete."
    log "Enable the developer console (F12) and open the Device Toolbar (Ctrl + Shift + M) to a touchable device."
    log "Touch and drag the \"touch div\" to continue the test."
    log "Then click the \"Check test !!! status\" button."
  else:
    log "Touch div not found."

proc initMouseEvents() =
  log "Mouse event initialization started."
  document.addEventListener($DomEvent.MouseDown, mouseDown, false)
  document.addEventListener($DomEvent.MouseMove, mouseMove, false)
  log "Mouse event initialization complete."
  
proc initKbEvents() =
  log "KB event initialization started."
  document.addEventListener($DomEvent.KeyDown, keyDown, false)
  log "KB event initialization complete."
  
proc startTests() =
  log "[Disclaimer: these tests have been tested successfully on Linux with Firefox and Chromium. Your results may vary.]"
  log "Note: these tests require some manual steps, which will be shown here."
  log "Note: new entries appear in this text area at the top, so read in this direction."
  log "  | |    | |    | |    | |    | |    | |    | |    | |    | |    | |    | |"
  log " /  \\  /   \\ /   \\ /   \\ /   \\ /   \\ /   \\ /   \\ /   \\ /   \\ /   \\"
  log "Test 1 started."
  log "This test checks that drag and touch events are fired."
  testRunning[0] = true
  for evt in [Drag, DragEnd, DragEnter, DragExit, DragLeave, DragOver, DragStart, Drop]:
    dragEventsCompleted.add(evt, false)
  for evt in [TouchStart, TouchMove, TouchEnd]:
    touchEventsCompleted.add(evt, false)
  initKbEvents()
  initMouseEvents()
  initDragEvents()
  initTouchEvents()

proc checkTest1Status() =
  var
    dragEvtsCompleted = true
    touchEvtsCompleted = true

  # Chrome doesn't seem to send DragExit, so ignore this
  if (($navigator.userAgent).contains("Chrome")):
    dragEventsCompleted[DragExit] = true
  
  for evt, completed in dragEventsCompleted:
    if not completed:
      dragEvtsCompleted = false
      break

  for evt, completed in touchEventsCompleted:
    if not completed:
      touchEvtsCompleted = false
      break

  if dragEvtsCompleted and touchEvtsCompleted:
    testRunning[0] = false
    log "Test 1 completed successfully. Drag the div anywhere to start the next test."
    testCompleted[0] = true
    document.getElementById("checkTest1").style.visibility = "hidden"
  else:
    if not dragEvtsCompleted:
      log "Test 1 has not completed yet. Make sure you drag the div over another element."
      log "Status:"
      for evt, completed in dragEventsCompleted:
        log $evt & ": " & $completed
    else:
      log "Test 1 drag events were completed. Touch tests pending..."
    if not touchEvtsCompleted:
      log "Test 1 has not completed yet. Enable a touchable device in the developer console and drag the touch div."
      log "Status:"
      for evt, completed in touchEventsCompleted:
        log $evt & ": " & $completed
    else:
      log "Test 1 touch events were completed. Drag tests pending..."

proc createDom(): VNode =
  result = buildHtml(tdiv()):
    tdiv(id="dragDiv", draggable="true"):
      tdiv(class="divcontent"):
        text "draggable div"
    tdiv(id="touchDiv"):
      tdiv(class="divcontent"):
        text "touch div"
    tdiv(id="results"):
      for i in countdown(results.len - 1, 0):
        tdiv:
          text $results[i]
    tdiv(id="checkTest1"):
      button(onclick=checkTest1Status):
        text "Check test 1 status"
    input(`type`="hidden", id="test9value")
    input(`type`="text", id="test10input1")
    input(`type`="text", id="test10input2")
    h3(id="test11h3"):
      text "test 11"
    input(`type`="text", id="test12input")
      
proc onload() =
  startTests()
  
setRenderer createDom
onload()
