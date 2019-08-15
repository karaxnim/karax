Karax – Single page applications in Nim |travis|
================================================

Karax is a framework for developing single page applications in Nim.

To try it out, run::

  cd ~/projects # Insert your favourite directory for projects

  nimble develop karax # This will clone Karax and create a link to it in ~/.nimble

  cd karax

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

.. |travis| image:: https://travis-ci.org/pragmagic/karax.svg?branch=master
    :target: https://travis-ci.org/pragmagic/karax


Hello World
===========

The simplest Karax program looks like this:

.. code-block:: nim

  include karax / prelude

  proc createDom(): VNode =
    result = buildHtml(tdiv):
      text "Hello World!"

  setRenderer createDom


Since ``div`` is a keyword in Nim, karax choose to use ``tdiv`` instead
here. ``tdiv`` produces a ``<div>`` virtual DOM node.

As you can see, karax comes with its own ``buildHtml`` DSL for convenient
construction of (virtual) DOM trees (of type ``VNode``). Karax provides
a tiny build tool called ``karun`` that generates the HTML boilerplate code that
embeds and invokes the generated JavaScript code::

  nim c karax/tools/karun
  karax/tools/karun -r helloworld.nim

Via ``-d:debugKaraxDsl`` we can have a look at the produced Nim code by
``buildHtml``:

.. code-block:: nim

  let tmp1 = tree(VNodeKind.tdiv)
  add(tmp1, text "Hello World!")
  tmp1

(I shortened the IDs for better readability.)

Ok, so ``buildHtml`` introduces temporaries and calls ``add`` for the tree
construction so that it composes with all of Nim's control flow constructs:


.. code-block:: nim

  include karax / prelude
  import random

  proc createDom(): VNode =
    result = buildHtml(tdiv):
      if random(100) <= 50:
        text "Hello World!"
      else:
        text "Hello Universe"

  randomize()
  setRenderer createDom


Produces:

.. code-block:: nim

  let tmp1 = tree(VNodeKind.tdiv)
  if random(100) <= 50:
    add(tmp1, text "Hello World!")
  else:
    add(tmp1, text "Hello Universe")
  tmp1


Event model
===========

Karax does not change the DOM's event model much, here is a program
that writes "Hello simulated universe" on a button click:

.. code-block:: nim

  include karax / prelude
  # alternatively: import karax / [kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils, jjson]

  var lines: seq[kstring] = @[]

  proc createDom(): VNode =
    result = buildHtml(tdiv):
      button:
        text "Say hello!"
        proc onclick(ev: Event; n: VNode) =
          lines.add "Hello simulated universe"
      for x in lines:
        tdiv:
          text x

  setRenderer createDom


``kstring`` is Karax's alias for ``cstring`` (which stands for "compatible
string"; for the JS target that is an immutable JavaScript string) which
is preferred for efficiency on the JS target. However, on the native targets
``kstring`` is mapped  to ``string`` for efficiency. The DSL for HTML
construction is also avaible for the native targets (!) and the ``kstring``
abstraction helps to deal with these conflicting requirements.

Karax's DSL is quite flexible when it comes to event handlers, so the
following syntax is also supported:

.. code-block:: nim

  include karax / prelude
  from sugar import `=>`

  var lines: seq[kstring] = @[]

  proc createDom(): VNode =
    result = buildHtml(tdiv):
      button(onclick = () => lines.add "Hello simulated universe"):
        text "Say hello!"
      for x in lines:
        tdiv:
          text x

  setRenderer createDom


The ``buildHtml`` macro produces this code for us:

.. code-block:: nim

  let tmp2 = tree(VNodeKind.tdiv)
  let tmp3 = tree(VNodeKind.button)
  addEventHandler(tmp3, EventKind.onclick,
                  () => lines.add "Hello simulated universe", kxi)
  add(tmp3, text "Say hello!")
  add(tmp2, tmp3)
  for x in lines:
    let tmp4 = tree(VNodeKind.tdiv)
    add(tmp4, text x)
    add(tmp2, tmp4)
  tmp2

As the examples grow larger it becomes more and more visible of what
a DSL that composes with the builtin Nim control flow constructs buys us.
Once you have tasted this power there is no going back and languages
without AST based macro system simply don't cut it anymore.


Attaching data to an event handler
==================================

Since the type of an event handler is ``(ev: Event; n: VNode)`` or ``()`` any
additional data that should be passed to the event handler needs to be
done via Nim's closures. In general this means a pattern like this:

.. code-block:: nim

  proc menuAction(menuEntry: kstring): proc() =
    result = proc() =
      echo "clicked ", menuEntry

  proc buildMenu(menu: seq[kstring]): VNode =
    result = buildHtml(tdiv):
      for m in menu:
        nav(class="navbar is-primary"):
          tdiv(class="navbar-brand"):
            a(class="navbar-item", onclick = menuAction(m)):


DOM diffing
===========

Ok, so now we have seen DOM creation and event handlers. But how does
Karax actually keep the DOM up to date? The trick is that every event
handler is wrapped in a helper proc that triggers a *redraw* operation
that calls the *renderer* that you initially passed to ``setRenderer``.
So a new virtual DOM is created and compared against the previous
virtual DOM. This comparison produces a patch set that is then applied
to the real DOM the browser uses internally. This process is called
"virtual DOM diffing" and other frameworks, most notably Facebook's
*React*, do quite similar things. The virtual DOM is faster to create
and manipulate than the real DOM so this approach is quite efficient.


Form validation
===============

Most applications these days have some "login"
mechanism consisting of ``username`` and ``password`` and
a ``login`` button. The login button should only be clickable
if ``username`` and ``password`` are not empty. An error
message should be shown as long as one input field is empty.

To create new UI elements we write a ``loginField`` proc that
returns a ``VNode``:

.. code-block:: nim

  proc loginField(desc, field, class: kstring;
                  validator: proc (field: kstring): proc ()): VNode =
    result = buildHtml(tdiv):
      label(`for` = field):
        text desc
      input(class = class, id = field, onchange = validator(field))

We use the ``karax / errors`` module to help with this error
logic. The ``errors`` module is mostly a mapping from strings to
strings but it turned out that the logic is tricky enough to warrant
a library solution. ``validateNotEmpty`` returns a closure that
captures the ``field`` parameter:

.. code-block:: nim

  proc validateNotEmpty(field: kstring): proc () =
    result = proc () =
      let x = getVNodeById(field)
      if x.text.isNil or x.text == "":
        errors.setError(field, field & " must not be empty")
      else:
        errors.setError(field, "")

This indirection is required because
event handlers in Karax need to have the type ``proc ()``
or ``proc (ev: Event; n: VNode)``. The errors module also
gives us a handy ``disableOnError`` helper. It returns
``"disabled"`` if there are errors. Now we have all the
pieces together to write our login dialog:


.. code-block:: nim

  # some consts in order to prevent typos:
  const
    username = kstring"username"
    password = kstring"password"

  var loggedIn: bool

  proc loginDialog(): VNode =
    result = buildHtml(tdiv):
      if not loggedIn:
        loginField("Name :", username, "input", validateNotEmpty)
        loginField("Password: ", password, "password", validateNotEmpty)
        button(onclick = () => (loggedIn = true), disabled = errors.disableOnError()):
          text "Login"
        p:
          text errors.getError(username)
        p:
          text errors.getError(password)
      else:
        p:
          text "You are now logged in."

  setRenderer loginDialog

(Full example `here <https://github.com/pragmagic/karax/blob/master/examples/login.nim>`_.)

This code still has a bug though, when you run it, the ``login`` button is not
disabled until some input fields are validated! This is easily fixed,
at initialization we have to do:

.. code-block:: nim

  setError username, username & " must not be empty"
  setError password, password & " must not be empty"

There are likely more elegant solutions to this problem.


Routing
=======

For routing ``setRenderer`` can be called with a callback that takes a parameter of
type ``RouterData``. Here is the relevant excerpt from the famous "Todo App" example:

.. code-block:: nim

  proc createDom(data: RouterData): VNode =
    if data.hashPart == "#/": filter = all
    elif data.hashPart == "#/completed": filter = completed
    elif data.hashPart == "#/active": filter = active
    result = buildHtml(tdiv(class="todomvc-wrapper")):
      section(class = "todoapp"):
        ...

  setRenderer createDom

(Full example `here <https://github.com/pragmagic/karax/blob/master/examples/todoapp/todoapp.nim>`_.)


Server Side HTML Rendering
==========================

Karax can also be used to render HTML on the server.  Only a subset of
modules can be used since there is no JS interpreter.

.. code-block:: nim

  import karax / [karaxdsl, vdom]

  const places = @["boston", "cleveland", "los angeles", "new orleans"]

  proc render*(): string =
    let vnode = buildHtml(tdiv(class = "mt-3")):
      h1: text "My Web Page"
      p: text "Hello world"
      ul:
        for place in places:
          li: text place
      dl:
        dt: text "Can I use Karax for client side single page apps?"
        dd: text "Yes"

        dt: text "Can I use Karax for server side HTML rendering?"
        dd: text "Yes"
    result = $vnode

  echo render()
