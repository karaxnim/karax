import dom, vdom, karax, karaxdsl, jdict, jstrutils, kajax

type
    HomeState {.importc.} = ref object
    TableItemState {.importc.} = ref object
        id: int
        active: bool
        props: seq[cstring]
    TableState {.importc.} = ref object
        items: seq[TableItemState]
    AnimBoxState {.importc.} = ref object
        id: int
        time: int
    AnimState {.importc.} = ref object
        items: seq[AnimBoxState]
    TreeNodeState {.importc.} = ref object
        id: int
        container: bool
        children: seq[TreeNodeState]
    TreeState {.importc.} = ref object
        root: TreeNodeState
    AppState {.importc.} = ref object
        location: cstring
        home: HomeState
        table: TableState
        anim: AnimState
        tree: TreeState

proc init*(a: cstring, b: cstring) {.importc: "uibench.init", nodecl.}
proc run*(a: proc(state: AppState), b: proc(samples: RootRef)) {.importc: "uibench.run", nodecl.}

init(cstring"Nim-karax", cstring"0.6.1")

var container = document.getElementById("#App")
var appState: AppState

proc createTableCell(id: cstring): VNode =
    proc tableCellClick(ev: karax.Event; n: VNode) =
        kout "Clicked" & id
        # ev.stopPropogation()
    result = buildHtml(td(className="TableCell", onclick=tableCellClick)):
        text id

proc createTableRow(item: TableItemState): VNode =
    var children = createTableCell("#" & &item.id)
    for i in 0..<len(item.props):
        children.add(createTableCell(item.props[i]))
    var dataId = &item.id

    proc createRow(): VNode =
        var className = cstring"TableRow"
        if item.active:
            className = cstring"TableRow active"
        result = buildHtml(tr(class=className, `data-id`=dataId)):
            children
    result = createRow()


proc tableCreateVNode(data: TableState): VNode =
    result = buildHtml(table(class="Table")):
        tbody:
            for child in data.items:
                createTableRow(child)

proc createAnimBox(item: AnimBoxState): VNode =
    var time = item.time
    var dataId: cstring = &item.id
    var color: float = float(time mod 10) / 10
    var divStyles: cstring = "borderRadius: " & &(time mod 10) & "px; background: rgba(0,0,0," & cstring($color) & ")"
    result = flatHtml(tdiv(className="AnimBox", `data-id`=dataId, style=divStyles))

proc animCreateVNode(data: AnimState): VNode =
    var items = data.items
    var children: seq[VNode] = @[]
    for i in 0..<len(children):
        var item = items[i]
        children.add createAnimBox(item)
    result = buildHtml(tdiv(className="Anim")):
        for child in children:
            child

proc createTreeLeaf(data: TreeNodeState): VNode =
    result = buildHtml(li(className="TreeLeaf")):
        text &data.id

proc createTreeNode(data: TreeNodeState): VNode =
    var children: seq[VNode] = @[]
    for i in 0..<len(data.children):
        var n = data.children[i]
        if n.container:
            children.add(createTreeNode(n))
        else:
            children.add(createTreeLeaf(n))

proc treeCreateVNode(data: TreeState): VNode =
    result = buildHtml(tdiv(className="Tree")):
        createTreeNode(data.root)


proc update(): VNode =
    if appState == nil: return newVNode(VNodeKind.tdiv)
    let location = appState.location
    var children: VNode = nil
    if location == cstring"table":
        children = tableCreateVNode(appState.table)
    elif location == cstring"anim":
        children = animCreateVNode(appState.anim)
    elif location == cstring"tree":
        children = treeCreateVNode(appState.tree)
    kout cstring"update", children
    result = buildHtml():
        tdiv(class="Main"):
            children

proc a(state: AppState) =
    appState = state
    redraw()

proc b(samples: RootRef) =
    #document.body.innerHTML = cstring"<pre>" & toJson(samples) & cstring"</pre>"
    #redraw()
    discard

kout cstring"updating"
setRenderer update
kout cstring"running"
run(a, b)