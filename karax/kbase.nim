## Karax -- Single page applications for Nim.

## Basic type definitions for Karax.
when defined(js):
  type kstring* = cstring
else:
  type kstring* = string

