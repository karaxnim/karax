
import "../kajax", "../jdict", common
export common
from "../karax" import kout

type
  Db* = ref object
    data: seq[Triple]
    version*: int
    next: Db

  Query* = object
    constraints*: set[TripleKind]
    t*: Triple

  Message {.importc.} = ref object
    kind: MessageKind
    data: seq[Triple]
    version: int
    id: MessageId
#  RequestMessage {.importc.} = ref object

let conn = newWebSocket("ws://localhost:8080", "karaxdb")
var gid: MessageId
var pendingIds = newJDict[MessageId, Message]()
var pending: int

#proc loadDb*(url: cstring): Db =
#  result = nil

proc newTransaction*(): Db =
  result = Db(data: @[])

proc insert*(head, newdb: Db) =
  newdb.next = head
  #result = newdb
  let expectedVersion = if not head.isNil: head.version + 1 else: 1
  inc gid.int
  let m = Message(kind: NewData, data: newdb.data, version: expectedVersion, id: gid)
  pendingIds[gid] = m
  inc pending
  conn.send(toJson(m))

proc merge*(newer, older: Db) =
  newer.next = older

proc registerOnUpdate*(update: proc(db: Db)) =
  conn.onmessage =
    proc (e: MessageEvent) =
      let msg = fromJson[Message](e.data)
      case msg.kind
      of Conflict:
        # conflict, so throw away the sent data, don't apply the changes:
        if pending > 0:
          pendingIds.del msg.id
          dec pending
        # server sent data that caused the conflict:
        if msg.data.len > 0:
          let db = Db(data: msg.data, version: msg.version)
          update(db)
      of Accepted:
        kout cstring"accepted", pending
        if pending > 0:
          let d = pendingIds[msg.id]
          # data was not submitted again, so we use the in-memory version
          # of the data:
          let db = Db(data: d.data, version: d.version)
          pendingIds.del msg.id
          dec pending
          update(db)
      of Newdata:
        let db = Db(data: msg.data, version: msg.version)
        update(db)

iterator list*(db: Db, q: Query): Triple =
  # XXX here the datamodel comes in! We must not
  # yield outdated data!
  var it = db
  while it != nil:
    for d in it.data:
      var match = true
      for k in q.constraints:
        if d[k] != q.t[k]: match = false
      if match: yield d
    it = it.next

proc extract*(db: Db, q: Query): Triple =
  for x in list(db, q):
    result = x
    break

proc extract*(db: Db, subj, pred: kstring): kstring =
  let q = Query(constraints: {Subj, Pred}, t: [subj, pred, ""])
  result = extract(db, q)[Obj]

proc insert*(db: Db, subj, pred, obj: kstring) =
  let result = Db()
  result.data.add([subj, pred, obj])
  insert(db, result)
