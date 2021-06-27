# Introduction

## What is Karax?
Karax is a framework for developing SPAs (single page applications) using Nim. 
It is designed to be easy to use and fast, by using a virtual DOM model similar to React.

## Getting Started
> We assume that the reader has knowledge of basic HTML, CSS, and Nim.
> Knowledge of Javascript (specifically events) is reccomended, but not required.

We'll be using `karun` for most of this guide, although it is possible to compile Karax applications using `nim js` 

Here's a simple example:
```nim
include karax/prelude # imports many of the basic Karax modules

proc createDom(): VNode = # define a function to return our HTML nodes
  buildHtml(p): # create a paragraph element
    text "Welcome to Karax!" # set the text inside of the paragraph element

setRenderer createDom # tell Karax to use function to render
```

Save this file as `ìndex.nim`. Then, run
```
karun -r index.nim
```
This should compile the file using the `js` backend from Nim and open the file in your default browser!
Note that you can also pass in the `-w` flag to make it so that whenever you save the `ìndex.nim` file, it will automatically rebuild and refresh the page.

The syntax here shouldn't be too confusing. 
Karax comes with a built in DSL (domain specific language) to aid in generating HTML nodes.

If you want to bind to an HTML attribute, you can do the following:
```nim
include karax/prelude

proc createDom(): VNode =
  buildHtml(p(title = "Here is some help text!")):
    text "Hover over me to see the help text!"

setRenderer createDom
```
Pretty simple, right? You can specify any HTML attribute that you want here.

### Conditionals and Loops
It's simple to toggle whether an element exists as well.

```nim
include karax/prelude
var show = true
proc createDom(): VNode =
  buildHtml(tdiv):
    if show:
      p:
        text "Now you see me!"
    else:
      p:
        text "Now you dont!"

setRenderer createDom
```
Go ahead and try running this. Change `show` to `false`, and you should see the text change as well!
Standard Nim if statements work just fine and are handled by the DSL.

There is one thing that is unfamiliar here though: What is the `tdiv` tag? 
Since Nim has `div` as a reserved keyword, Karax defines tdiv to refer to the `div` element.
You can see a list of all of the tags along with their mapping at the top of this file: [vdom.nim](https://github.com/karaxnim/karax/blob/master/karax/vdom.nim)

How do we display a list of elements in Karax? As you might expect, using a Nim for loop.

```nim
include karax/prelude
var list = @[kstring"Apples", "Oranges", "Bananas"]
proc createDom(): VNode =
  buildHtml(tdiv):
    for fruit in list:
      p:
        text fruit
        text " is a fruit"

setRenderer createDom
```
It just works! Note that we used multiple text functions to add more text together.
It is also possible to do this using string concatenation or interpolation, but this is simpler.

#### `kstring` vs `string` vs `cstring`
As you may have noticed above, we made `list` into a seq[kstring] rather than a seq[string].
If you've ever worked with Nim's `js` backend, you would know that Javascript strings are different from Nim strings. 
Nim uses the `cstring` type to denote a "compatible string". 
In our case, this corresponds to the native Javascript string type. 
In fact, if you try using Nim's string type on the Javascript backend, you'll get something like:
```
[45, 67, 85, 34, ...]
```
This is how Nim strings are handle internally - a sequence of numbers.
We use `cstring` to avoid taking a performance penalty when working with strings, as the native string type is faster than a list of numbers.

What is `kstring` then? `kstring` corresponds to a `cstring` when compiled using the `js` backend, and a `string` otherwise.
This makes it much easier to write code that can be used on multiple platforms.

### Handling User Input
Karax allows you to simply utilize existing DOM events to handle user input.

```nim
include karax/prelude
import algorithm
var message = "Karax is fun!"
proc createDom(): VNode =
  buildHtml(tdiv):
    p:
      text message
    button:
      text "Click me to reverse!"
      proc onclick =
        message.reverse()

setRenderer createDom
```
Clicking that button causes the onclick event to fire, which reverses our string.
Note that we treat `message` as a string - that way we can reverse the string using Nim's `algorithm` module.

Karax can work with text inputs as well!

```nim
include karax/prelude
var message = kstring"Karax is fun!"
proc createDom(): VNode =
  buildHtml(tdiv):
    p:
      text message
    input(value = message):
      proc oninput(e: Event, n: VNode) =
        message = n.value

setRenderer createDom
```
No manual DOM manipulation required! 
Just change the variable and everything magically updates.

You may notice that this time our `proc` has two arguments. 
You can see the Karax documentation for information on VNode, but the `Event` type is from the `dom` module in the stdlib.
It is defined similarly to a DOM event in Javascript.

### Composing and Reusability
Unlike other web frameworks, Karax doesn't have explicit components.
Instead, it gives you the freedom to organize your code how you want.

So, to mimic what components do we can just use functions.

```nim
include karax/prelude
type Task = ref object
  id: int
  text: kstring
var tasks = @[
  Task(id: 0, text: "Buy milk"),
  Task(id: 1, text: "Clean table"),
  Task(id: 2, text: "Call mom")
]
proc render(t: Task): VNode =
  buildHtml(li):
    text t.text

proc createDom(): VNode =
  buildHtml(tdiv):
    ol:
      for task in tasks:
        task.render()

setRenderer createDom
```
With this, we can easily divide up parts of a more complex application.
Function arguments can take the place of "props", and we're not constrained by "components" in any way.

We've briefly covered many of the features that Karax offers.
Interested in more? Continue reading for more advanced topics!
