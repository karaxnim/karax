## Karax -- Single page applications for Nim.

## This module contains wrappers for the HTML 5 IndexedDB.
## Code is from https://github.com/enimatek-nl/tangu/

import std/[jsffi, asyncjs, dom]

type
  IndexedDB {.importc.} = ref object of RootObj
  
  #IDBTransactionMode = enum
  #  readOnly = "readonly", readWrite = "readwrite", versionChange = "versionchange"

  IDBOptions = ref object of RootObj
    autoIncrement: bool
    keyPath: cstring

  IDBTransaction {.importc.} = ref object of RootObj
    onerror*: proc (event: Event) {.closure.}
    oncomplete*: proc (event: Event) {.closure.}

  IDBDatabase {.importc.} = ref object of RootObj
    name: cstring
    version: cint
    objectStoreNames: seq[cstring]

  IDBObjectStore {.importc.} = ref object of RootObj
    indexNames: seq[cstring]
    name: cstring
    transaction: IDBTransaction
    autoIncrement: bool

  IDBRequest {.importc.} = ref object of RootObj 
    onerror*: proc (event: Event) {.closure.}
    onsuccess*: proc (event: Event) {.closure.}
    result: JsObject

  IDBOpenDBRequest {.importc.} = ref object of RootObj
    onerror*: proc (event: Event) {.closure.}
    onsuccess*: proc (event: Event) {.closure.}
    onupgradeneeded*: proc (event: Event) {.closure.}
    result: IDBDatabase

proc indexedDB*(): IndexedDB {.importcpp: "function() { return window.indexedDB; }()".}

proc open(self: IndexedDB, dbName: cstring): IDBOpenDBRequest {.importcpp.}
proc open(self: IndexedDB, dbName: cstring, s: cint): IDBOpenDBRequest {.importcpp.}

proc transaction(self: IDBDatabase, names: cstring): IDBTransaction {.importcpp.}
proc transaction(self: IDBDatabase, names: seq[cstring]): IDBTransaction {.importcpp.}
proc transaction(self: IDBDatabase, names: cstring, mode: cstring): IDBTransaction {.importcpp.}
proc transaction(self: IDBDatabase, names: seq[cstring], mode: cstring): IDBTransaction {.importcpp.}

proc deleteObjectStore(self: IDBDatabase, name: cstring) {.importcpp.}
proc createObjectStore(self: IDBDatabase, name: cstring, options: IDBOptions): IDBObjectStore {.importcpp.}
proc close(self: IDBDatabase) {.importcpp.}

proc objectStore(self: IDBTransaction, name: cstring): IDBObjectStore {.importcpp.}

proc add(self: IDBObjectStore, value: JsObject): IDBRequest {.importcpp.}
proc get(self: IDBObjectStore, id: cint): IDBRequest {.importcpp.}
proc getAll(self: IDBObjectStore): IDBRequest {.importcpp.}
proc put(self: IDBObjectStore, value: JsObject): IDBRequest {.importcpp.}
proc delete(self: IDBObjectStore, key: cstring): IDBRequest {.importcpp.}

proc getAll*(indexedDB: IndexedDB, storeName: cstring): Future[JsObject] =
  var promise = newPromise() do (resolve: proc(response: JsObject)):
    let request = indexedDB.open(storeName)
    request.onerror = proc (event: Event) =
      resolve(nil)
    request.onupgradeneeded = proc (event: Event) =
      let database = request.result
      discard database.createObjectStore(storeName, IDBOptions(autoIncrement: true, keyPath: "id"))
      echo "upgraded getAll"
    request.onsuccess = proc (event: Event) =
      let database = request.result
      let transaction = database.transaction(storeName, "readonly")
      let obj_store = transaction.objectStore(storeName)
      let obj_req = obj_store.getAll()
      obj_req.onerror = proc (event: Event) =
        resolve(nil)
      obj_req.onsuccess = proc (event: Event) =
        resolve(obj_req.result)
  return promise

proc put*(indexedDB: IndexedDB, storeName: cstring, obj: JsObject): Future[bool] =
  var promise = newPromise() do (resolve: proc(response: bool)):
    let request = indexedDB.open(storeName)
    request.onerror = proc (event: Event) =
      resolve(false)
    request.onupgradeneeded = proc (event: Event) =
      let database = request.result
      discard database.createObjectStore(storeName, IDBOptions(autoIncrement: true, keyPath: "id"))
      echo "upgraded put"
    request.onsuccess = proc (event: Event) =
      let database = request.result
      let transaction = database.transaction(storeName, "readwrite")
      let obj_store = transaction.objectStore(storeName)
      let obj_req = obj_store.put(obj)
      obj_req.onerror = proc (event: Event) =
        resolve(false)
      obj_req.onsuccess = proc (event: Event) =
        resolve(true)
  return promise

proc delete*(indexedDB: IndexedDB, storeName: cstring, id: cstring): Future[bool] =
  var promise = newPromise() do (resolve: proc(response: bool)):
    let request = indexedDB.open(storeName)
    request.onerror = proc (event: Event) =
      resolve(false)
    request.onupgradeneeded = proc (event: Event) =
      let database = request.result
      discard database.createObjectStore(storeName, IDBOptions(autoIncrement: true, keyPath: "id"))
      echo "upgraded delete"
    request.onsuccess = proc (event: Event) =
      let database = request.result
      let transaction = database.transaction(storeName, "readwrite")
      let obj_store = transaction.objectStore(storeName)
      let obj_req = obj_store.delete(id)
      obj_req.onerror = proc (event: Event) =
        resolve(false)
      obj_req.onsuccess = proc (event: Event) =
        resolve(true)
  return promise

