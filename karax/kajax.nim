## Karax -- Single page applications for Nim.

## This module implements support for `ajax`:idx: socket
## handling.

import karax
import jsffi except `&`
import jscore
import dom

type
  ProgressEvent* {.importc.}= object
    loaded*: float
    total*: float

  FormData* {.importc.} = JsObject

  HttpRequest* {.importc.} = ref object
    readyState, status: int
    responseText, statusText: cstring

  XMLHttpRequestUpload* {.importc.} = JsObject

proc newFormData*(): FormData {.importcpp: "new FormData()".}
proc append*(f: FormData, key: cstring, value: Blob) {.importcpp:"#.append(@)".}
proc append*(f: FormData, key: cstring, value: cstring) {.importcpp:"#.append(@)".}

proc setRequestHeader*(r: HttpRequest; a, b: cstring) {.importcpp: "#.setRequestHeader(@)".}
proc statechange*(r: HttpRequest; cb: proc()) {.importcpp: "#.onreadystatechange = #".}
proc send*(r: HttpRequest; data: cstring) {.importcpp: "#.send(#)".}
proc send*(r: HttpRequest, data: Blob) {.importcpp: "#.send(#)".}
proc open*(r: HttpRequest; meth, url: cstring; async: bool) {.importcpp: "#.open(@)".}
proc newRequest*(): HttpRequest {.importcpp: "new XMLHttpRequest(@)".}

when not declared(dom.File):
  type
    DomFile = ref FileObj
    FileObj {.importc.} = object of Blob
      lastModified: int
      name: cstring
else:
  type
    DomFile = dom.File

proc uploadFile*(url: cstring, file: Blob, onprogress :proc(data: ProgressEvent),
                cont: proc (httpStatus: int; response: cstring);
                headers: openarray[(cstring, cstring)] = []) =
  proc contWrapper(httpStatus: int; response: cstring) =
    cont(httpStatus, response)

  proc upload(r: HttpRequest):XMLHttpRequestUpload {.importcpp: "#.upload".}

  var formData = newFormData()
  formData.append("upload_file",file)
  formData.append("filename", DomFile(file).name)
  let ajax = newRequest()
  ajax.open("POST", url, true)
  for a, b in items(headers):
    ajax.setRequestHeader(a, b)
  ajax.statechange proc() =
    if ajax.readyState == 4:
      contWrapper(ajax.status, ajax.responseText)
  ajax.upload.onprogress = onprogress
  ajax.send(formData.to(cstring))

proc ajax*(meth, url: cstring; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int; response: cstring);
          doRedraw: bool = true,
          kxi: KaraxInstance = kxi,
          useBinary: bool = false,
          blob: Blob = nil) =
  proc contWrapper(httpStatus: int; response: cstring) =
    cont(httpStatus, response)
    if doRedraw: redraw(kxi)


  let ajax = newRequest()
  ajax.open(meth, url, true)
  for a, b in items(headers):
    ajax.setRequestHeader(a, b)
  ajax.statechange proc() =
    if ajax.readyState == 4:
      if ajax.status == 200:
        contWrapper(ajax.status, ajax.responseText)
      else:
        contWrapper(ajax.status, ajax.responseText)
  if useBinary:
    ajax.send(blob)
  else:
    ajax.send(data)

proc ajaxPost*(url: cstring; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true,
          kxi: KaraxInstance = kxi) =
  ajax("POST", url, headers, data, cont, doRedraw, kxi)

proc ajaxPost*(url: cstring; headers: openarray[(cstring, cstring)];
          data: Blob;
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true,
          kxi: KaraxInstance = kxi) =
  ajax("POST", url, headers, "", cont, doRedraw, kxi, true, data)

proc ajaxGet*(url: cstring; headers: openarray[(cstring, cstring)];
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true,
          kxi: KaraxInstance = kxi) =
  ajax("GET", url, headers, nil, cont, doRedraw, kxi)

proc ajaxPut*(url: cstring; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true,
          kxi: KaraxInstance = kxi) =
  ajax("PUT", url, headers, data, cont, doRedraw, kxi)

proc ajaxDelete*(url: cstring; headers: openarray[(cstring, cstring)];
          cont: proc (httpStatus: int, response: cstring);
          doRedraw: bool = true,
          kxi: KaraxInstance = kxi) =
  ajax("DELETE", url, headers, nil, cont, doRedraw, kxi)


proc toJson*[T](data: T): cstring {.importc: "JSON.stringify".}
proc fromJson*[T](blob: cstring): T {.importc: "JSON.parse".}

