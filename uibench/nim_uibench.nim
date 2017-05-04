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

var appState: AppState

proc createTableCell(id: cstring): VNode =
    proc tableCellClick(ev: karax.Event; n: VNode) =
        kout "Clicked" & id
    result = buildHtml(td(class="TableCell", onclick=tableCellClick)):
        text id

proc createTableRow(item: TableItemState): VNode =
    let className = if item.active: cstring"TableRow active" else: cstring"TableRow"
    result = buildHtml(tr(class=className, `data-id` = &item.id, key = item.id)):
        createTableCell("#" & &item.id)
        for i in 0..<len(item.props):
            createTableCell(item.props[i])

proc tableCreateVNode(data: TableState): VNode =
    result = buildHtml(table(class="Table")):
        tbody:
            for child in data.items:
                createTableRow(child)

proc createAnimBox(item: AnimBoxState): VNode =
    let time = item.time
    let t10 = time mod 10
    let color = float(t10) / 10
    let divStyles = cstring"border-radius: " & &t10 &
         "px; background: rgba(0,0,0," & cstring($color) & ")"
    result = flatHtml(tdiv(class="AnimBox", `data-id` = &item.id, key = item.id,
        style=divStyles))

proc animCreateVNode(data: AnimState): VNode =
    result = buildHtml(tdiv(class="Anim")):
        for child in data.items:
            createAnimBox(child)

proc createTreeNode(data: TreeNodeState): VNode =
    result = buildHtml(ul(class="TreeNode")):
        for n in data.children:
            if n.container:
                createTreeNode(n)
            else:
                li(class="TreeLeaf"):
                    text &n.id

proc treeCreateVNode(data: TreeState): VNode =
    result = buildHtml(tdiv(class="Tree")):
        createTreeNode(data.root)

proc update(): VNode =
    assert appState != nil
    let location = appState.location
    var children: VNode = nil
    if location == cstring"table":
        children = tableCreateVNode(appState.table)
    elif location == cstring"anim":
        children = animCreateVNode(appState.anim)
    elif location == cstring"tree":
        children = treeCreateVNode(appState.tree)
    result = buildHtml():
        tdiv(class="Main"):
            children

proc a(state: AppState) =
    appState = state
    redrawForce()

proc myToJson[T](x: T): cstring {.importcpp: "JSON.stringify(#, null, ' ')".}

proc b(samples: RootRef) =
    document.body.innerHTML = cstring"<pre>" & myToJson(samples) & cstring"</pre>"

proc init*(a: cstring, b: cstring) {.importc: "uibench.init", nodecl.}
proc run*(a: proc(state: AppState), b: proc(samples: RootRef)) {.importc: "uibench.run", nodecl.}

init(cstring"Nim-karax", cstring"0.6.1")

setRendererOnly update
run(a, b)