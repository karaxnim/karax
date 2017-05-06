
when defined(js):
  type kstring* = cstring
else:
  type kstring* = string

type
  TripleKind* = enum
    Subj, Pred, Obj

  DbValue* = kstring
  Triple* = array[TripleKind, DbValue]

  MessageId* = distinct int

  MessageKind* = enum
    Newdata, Conflict, Accepted
