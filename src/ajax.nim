## Karax -- Single page applications for Nim.

## This module implements support for `ajax`:idx: socket
## handling.

import karax

proc ajax(meth, url: cstring; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int; response: cstring)) =
  proc contWrapper(httpStatus: int; response: cstring) =
    cont(httpStatus, response)
    redraw()

  proc setRequestHeader(a, b: cstring) {.importc: "ajax.setRequestHeader".}
  {.emit: """
  var ajax = new XMLHttpRequest();
  ajax.open(`meth`,`url`,true);""".}
  for a, b in items(headers):
    setRequestHeader(a, b)
  {.emit: """
  ajax.onreadystatechange = function(){
    if(this.readyState == 4){
      if(this.status == 200){
        `contWrapper`(this.status, this.responseText);
      } else {
        `contWrapper`(this.status, this.statusText);
      }
    }
  }
  ajax.send(`data`);
  """.}

proc ajaxPut*(url: cstring; headers: openarray[(cstring, cstring)];
          data: cstring;
          cont: proc (httpStatus: int, response: cstring)) =
  ajax("PUT", url, headers, data, cont)

proc ajaxGet*(url: cstring; headers: openarray[(cstring, cstring)];
          cont: proc (httpStatus: int, response: cstring)) =
  ajax("GET", url, headers, nil, cont)

proc toJson*[T](data: T): cstring {.importc: "JSON.stringify".}
proc fromJson*[T](blob: cstring): T {.importc: "JSON.parse".}
