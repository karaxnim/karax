type
    History* = ref HistoryObj
    HistoryObj {.importc.} = object of RootObj
        length*: int