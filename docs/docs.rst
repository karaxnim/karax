
Virtual DOM
===========

The virtual dom is in the ``vdom`` module.

The ``VNodeKind`` enum describes every tag that the HTML 5 spec includes
and some extensions that allow for an efficient component system.

These extensions are:

``VNodeKind.int``
     The node has a single integer field.

``VNodeKind.bool``
     The node has a single boolean field.

``VNodeKind.vthunk``
     The node is a `virtual thunk`:idx:. This means there is a
     function attached to it that produces the ``VNode`` structure
     on demand.

``VNodeKind.dthunk``
     The node is a `DOM thunk`:idx:. This means there is a
     function attached to it that produces the ``Node`` DOM structure
     on demand.

For convenience of the resulting Nim DSL these tags have enum names
that differ from their HTML equivalent:

=================     =======================================================
Enum value            HTML
=================     =======================================================
``tdiv``              ``div``  (changed because ``div`` is a keyword in Nim)
``italic``            ``i``
``bold``              ``b``
``strikethrough``     ``s``
``underlined``        ``u``
=================     =======================================================


A virtual dom node also has a special field set called ``key``, an integer
that can be used as a data model specific key/id. It can be accessed in event
handlers to change the data model. See the todoapp for an example of how to
use it.

**Note**: This is not a hint for the DOM diff algorithm, multipe nodes can
all have the same key value.


Event system
============

Karax does not abstract over the event system the DOM offers much: The same
``Event`` structure is used. Every callback has the
signature ``proc (ev: Event; n: VNode)`` or empty ``proc ()``.


