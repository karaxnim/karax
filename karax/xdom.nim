import std/[xmltree, strtabs, strutils]
import ./vdom

converter toXmlNode*(el: VNode): XmlNode =
  let xAttrs = @[].toXmlAttributes
  for k, v in el.attrs:
    xAttrs[k] = v
  var kids: seq[XmlNode]
  if el.len > 0:
    for k in el:
      kids.add k.toXmlNode
  result = newXmlTree($el.kind, kids, attributes = xAttrs)

converter toVNode*(el: XmlNode): VNode =
  try:
    case el.kind:
      of xnElement:
        let kind = parseEnum[VNodeKind](el.tag)
        var vnAttrs: seq[(string, string)]
        if not el.attrs.isnil:
          for k, v in el.attrs:
            vnAttrs.add (k, v)
        var kids: seq[VNode]
        if el.len > 0:
          for k in el:
            kids.add k.toVNode
        tree(kind, vnAttrs, kids)
      of xnText:
        vn($el)
      else:
        verbatim($el)
  except ValueError: # karax doesn't support the node tag
    verbatim($el)
