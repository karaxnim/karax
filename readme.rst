Karax – Nim单页应用 |travis|
================================================

Karax是用Nim开发单面应用的框架。

尝试运行::

  cd ~/projects # 使用你的项目目录

  nimble develop karax # 克隆Karax并在~/.nimble创建链接

  cd karax

  cd examples/todoapp
  nim js todoapp.nim
  open todoapp.html
  cd ../..

  cd examples/mediaplayer
  nim js playerapp.nim
  open playerapp.html

它使用像React的虚拟DOM, 但它比已有的框架轻量许多加之它是用Nim为Nim而写。 
没有外部依赖，得益于Nim的整体程序优化，只有使用的模块会出现在生成的JavaScript代码中。


目标
=====

- 利用Nim的宏系统生成允许无样板的应用开发框架。
- 保持小巧、快速、灵活。

.. |travis| image:: https://travis-ci.org/pragmagic/karax.svg?branch=master
    :target: https://travis-ci.org/pragmagic/karax


Hello World
===========

最简单的Karax程序看起来是这样的：

.. code-block:: nim

  include karax / prelude

  proc createDom(): VNode =
    result = buildHtml(tdiv):
      text "Hello World!"

  setRenderer createDom


因为 ``div`` 是Nim中的关键字，karax选择用 ``tdiv`` 替换。 ``tdiv`` 生成 ``<div>`` 虚拟DOM节点。

如你所见，karax用自己的 ``buildHtml`` DSL构造(虚拟)DOM树(``VNode`` 节点类型)非常方便。
Karax提供小型构建工具 ``karun`` 生成HTML样板代码嵌入并调用生成的JavaScript代码::

  nim c karax/tools/karun
  karax/tools/karun -r helloworld.nim

通过 ``-d:debugKaraxDsl`` 可以看到 ``buildHtml`` 生成的Nim代码:

.. code-block:: nim

  let tmp1 = tree(VNodeKind.tdiv)
  add(tmp1, text "Hello World!")
  tmp1

(为了更好的可读性，缩减了IDs。)

可以看到 ``buildHtml`` 引入临时变量调用 ``add`` 构造树以便于它和Nim控制流并存:


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


生成:

.. code-block:: nim

  let tmp1 = tree(VNodeKind.tdiv)
  if random(100) <= 50:
    add(tmp1, text "Hello World!")
  else:
    add(tmp1, text "Hello Universe")
  tmp1


事件模型
===========

Karax没有太多改变DOM事件模型，这里有一个程序在点击按钮时输出"Hello simulated universe":

.. code-block:: nim

  include karax / prelude
  # 可选: import karax / [kbase, vdom, kdom, vstyles, karax, karaxdsl, jdict, jstrutils, jjson]

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


``kstring`` 是Karax中 ``cstring`` 的别名(代表可兼容字符串；对JS来说是不可改变的JavaScript字符串)，是JS目标效率的首选。
原生目标上为效率将 ``kstring`` 映射成 ``string`` 。 
HTML构造的DSL也可用于原生目标，``kstring`` 抽象帮助解决了这些冲突。

Karax的DSL在事件处理也非常灵活，下面的语法也是支持的：

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


``buildHtml`` 宏生成的代码：

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

随着示例变得越来越大，由内置Nim控制流构成的DSL所提供的东西越来越多。

一旦您体会到了这种力量，就没有回头路了，没有基于AST的宏系统的语言就再也不会对它构成任何威胁。



向事件处理附加数据
==================================

因为事件处理是 ``(ev: Event; n: VNode)`` 或 ``()`` ，任意应当传递给事件处理的附加数据需要通过Nim的闭包完成。一般是这种形式：

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


DOM差分算法
===========

我们已经看到DOM创建和事件处理，Karax如何保持DOM是最新的？
秘诀在于每个事件处理封装在一个中间过程，它会触发 *redraw* 操作来调用一开始传递给 ``setRenderer`` 的 *renderer* 。

新虚拟DOM创建并与之前虚拟DOM对比。
这种对比产生一个补丁集，随后应用在浏览器内部使用的真实DOM上。这个过程叫做“虚拟DOM差分”，与其它框架中比较著名的Facebook的 *React* 类似。
虚拟DOM比DOM创建和操作更快，这种方法非常高效。


表单验证
===============

现代的大多数应用有登录机制，由 ``username`` 和 ``password`` 以及 ``login`` 按钮构成。
登录按钮应当只在 ``username`` 和 ``password`` 非空的时候可以点击。
输入字段为空是应当显示错误消息。


我们写一个返回 ``VNode`` 的 ``loginField`` 过程来创建新UI元素：

.. code-block:: nim

  proc loginField(desc, field, class: kstring;
                  validator: proc (field: kstring): proc ()): VNode =
    result = buildHtml(tdiv):
      label(`for` = field):
        text desc
      input(class = class, id = field, onchange = validator(field))

我们使用 ``karax / errors`` 模块处理错误逻辑。 
``errors`` 模块主要是从字符串到字符串的映射，但事实证明该逻辑非常棘手，需要库解决方案。
``validateNotEmpty`` 返回一个捕获 ``field`` 参数的闭包：

.. code-block:: nim

  proc validateNotEmpty(field: kstring): proc () =
    result = proc () =
      let x = getVNodeById(field)
      if x.text.isNil or x.text == "":
        errors.setError(field, field & " must not be empty")
      else:
        errors.setError(field, "")

这种间接处理方式是必须的，因为Karax中的事件处理需要具有 ``proc ()`` 或 ``proc (ev: Event; n: VNode)`` 类型。
errors模块也提供一个方便的 ``disableOnError`` 过程。如果有错误将返回 ``"disabled"`` 。
现在把这些片段组装起来写我们的登录对话：


.. code-block:: nim

  # 防止输错的常量：
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

(完整示例 `here <https://github.com/pragmagic/karax/blob/master/examples/login.nim>`_.)

这段代码有bug，运行时 ``login`` 按钮没有disable，直到输入字段验证完成。这很容易修复，初始化时我们需要

.. code-block:: nim

  setError username, username & " must not be empty"
  setError password, password & " must not be empty"


对于这个问题可能有更优雅的解决方案。


路由
=======

对于路由``setRenderer``，可以使用带有参数 ``RouterData`` 的回调来调用。
以下是有名的“Todo App”示例的相关摘录：

.. code-block:: nim

  proc createDom(data: RouterData): VNode =
    if data.hashPart == "#/": filter = all
    elif data.hashPart == "#/completed": filter = completed
    elif data.hashPart == "#/active": filter = active
    result = buildHtml(tdiv(class="todomvc-wrapper")):
      section(class = "todoapp"):
        ...

  setRenderer createDom

(完整示例 `here <https://github.com/pragmagic/karax/blob/master/examples/todoapp/todoapp.nim>`_.)


服务端HTML渲染
==========================

Karax也可用于在服务器上渲染HTML。只有其中的几个模块可以用，因为没有JS解释器。

.. code-block:: nim

  import karax / [karaxdsl, vdom]

  const places = @["boston", "cleveland", "los angeles", "new orleans"]

  proc render*(): string =
    let node = buildHtml(tdiv(class = "mt-3")):
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
