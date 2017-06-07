Karax -- Single page applications in Nim
========================================

Karax is a framework for developing single page applications in Nim.
It's still in heavy development, so keep in mind that the API is subject
to change.

To try it out, run::

  nimble install # For first time

  cd examples/todoapp
  nim js todoapp.nim
  open todoapp.html
  cd ../..

  cd examples/mediaplayer
  nim js playerapp.nim
  open playerapp.html

It uses a virtual DOM like React, but is much smaller than the existing
frameworks plus of course it's written in Nim for Nim. No external
dependencies! And thanks to Nim's whole program optimization only what
is used ends up in the generated JavaScript code.


Goals
=====

- Leverage Nim's macro system to produce a framework that allows
  for the development of applications that are boilerplate free.
- Keep it small, keep it fast, keep it flexible.


Todo
====

- Expose a nice API to do Ajax requests.
