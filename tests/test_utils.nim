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
    tag*: cstring
    id*: cstring
    text*: cstring
    # TODO: attributes etc.
    children*: seq[ExpNode]

  ExpNodes* = seq[ExpNode]

proc tag*(tag: cstring; id, text: cstring = nil; children: ExpNodes = @[]): ExpNode =
  ExpNode(
    tag: tag,
    id: id,
    text: text,
    children: children,
  )

proc expectDomToMatch*(domParent: Element, expNodes: ExpNodes) =
  # We can't use domParent.len, only element nodes are relevant
  var numDomElements = 0
  for i in 0 ..< domParent.len:
    if domParent[i].nodeType == ElementNode:
      numDomElements += 1
  doAssert numDomElements == expNodes.len, "Number of children differs"

  for i in 0 ..< expNodes.len:
    let domElement = domParent[i]
    let expElement = expNodes[i]
    doAssert domElement.tagName.toLowerCase() == expElement.tag.toLowerCase(), "tag doesn't match"
    if expElement.id != nil:
      doAssert domElement.id == expElement.id, "id doesn't match"
    if expElement.text != nil:
      doAssert domElement.value == expElement.text, "text doesn't match"
    expectDomToMatch(domElement, expElement.children)

proc expectDomToMatch*(elementId: cstring, expNodes: ExpNodes) =
  let element = document.getElementById(elementId)
  expectDomToMatch(element, expNodes)

