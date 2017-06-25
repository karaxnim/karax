import kdom, jstrutils

proc installRootTag*() =
  document.body.innerHTML &= cstring"<div id='ROOT'></div>"

proc clearRootTag*() =
  document.getElementById("ROOT").innerHTML = ""

proc simpleTimeout*(p: proc()) =
  discard setTimeout(p, 100)

# --------------------- DOM validation ---------------------------------------
type
  ExpNode* = ref object
    nodeName*: cstring
    id*: cstring
    class*: cstring
    text*: cstring
    # TODO: attributes etc.
    children*: seq[ExpNode]

  ExpNodes* = seq[ExpNode]

proc node*(nodeName: cstring; id, class: cstring = nil; children: ExpNodes = @[]): ExpNode =
  ExpNode(
    nodeName: nodeName,
    id: id,
    class: class,
    text: nil,
    children: children,
  )

proc ntext*(text: cstring): ExpNode =
  ExpNode(
    nodeName: "#text",
    id: nil,
    class: nil,
    text: text,
    children: @[],
  )

template equals(a, b, msg) =
  doAssert a == b, "is not equal because " & $a & " != " & $b & ". Occurred in: " & msg

proc expectDomToMatch*(domParent: Element, expNodes: ExpNodes) =

  equals domParent.len, expNodes.len, "Check number of children"

  for i in 0 ..< expNodes.len:
    let expElement = expNodes[i]
    let domElement = domParent[i]
    if expElement.nodeName == "#text":
      equals expElement.text, domElement.nodeValue, "Text comparison"
    else:
      # node name
      equals domElement.nodeName.toLowerCase(), expElement.nodeName.toLowerCase(), "nodeName match"
      # id
      if expElement.id != nil:
        equals domElement.id, expElement.id, "id matching"
      else:
        equals domElement.id, "", "id empty check"
      # class
      if expElement.class != nil:
        equals domElement.class, expElement.class, "class matching"
      else:
        equals domElement.class, "", "class empty check"

      expectDomToMatch(domElement, expElement.children)

proc expectDomToMatch*(elementId: cstring, expNodes: ExpNodes) =
  let element = document.getElementById(elementId)
  expectDomToMatch(element, expNodes)

