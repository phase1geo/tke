namespace eval emmet {

  variable current_tab

  ######################################################################
  # Common diagnostic initialization procedure.  Returns the pathname
  # to the added text widget.
  proc initialize {} {

    variable current_tab

    # Add a new file
    set current_tab [gui::add_new_file end]

    # Get the text widget
    set txt [gui::get_info $current_tab tab txt]

    # Set the current syntax to HTML
    syntax::set_language $txt HTML

    # Get out of Vim mode if we are in it
    catch { vim::remove_bindings $txt }

    return $txt

  }

  ######################################################################
  # Common cleanup procedure.  If a fail message is provided, return an
  # error with the given error message.
  proc cleanup {{fail_msg ""}} {

    variable current_tab

    # Close the current tab
    gui::close_tab $current_tab -check 0

    # Output the fail message and cause a failure
    if {$fail_msg ne ""} {
      return -code error $fail_msg
    }

  }

  # Verify that the child operator works correctly.
  proc run_test1 {} {

    set txt [initialize]
    set str {nav>ul>li}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<nav>
  <ul>
    <li></li>
  </ul>
</nav>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify sibling operators.
  proc run_test2 {} {

    set txt [initialize]
    set str {div+p+bq}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div></div>
<p>$2</p>
<blockquote>$3</blockquote>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify combination of child, sibling and climb operators.
  proc run_test3 {} {

    set txt [initialize]
    set str {div+div>p>span+em^bq}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div></div>
<div>
  <p><span>$2</span><em>$3</em></p>
  <blockquote>$4</blockquote>
</div>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify climb operator
  proc run_test4 {} {

    set txt [initialize]
    set str {div+div>p>span+em^^bq}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div></div>
<div>
  <p><span>$2</span><em>$3</em></p>
</div>
<blockquote>$4</blockquote>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify grouping operators.
  proc run_test5 {} {

    set txt [initialize]
    set str {div>(header>ul>li*2>a)+footer>p}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div>
  <header>
    <ul>
      <li><a href="">$2</a></li>
      <li><a href="$3">$4</a></li>
    </ul>
  </header>
  <footer>
    <p>$5</p>
  </footer>
</div>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify associated text value.
  proc run_test6 {} {

    set txt [initialize]
    set str {a{Click me}}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<a href="">Click me</a>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify ID attributes.
  proc run_test7 {} {

    set txt [initialize]
    set str {div#header}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<div id="header"></div>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify class attributes.
  proc run_test8 {} {

    set txt [initialize]
    set str {div.title}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<div class="title"></div>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify class stringing.
  proc run_test9 {} {

    set txt [initialize]
    set str {p.class1.class2.class3}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<p class="class3 class2 class1"></p>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify mix of class and ID stringing.
  proc run_test10 {} {

    set txt [initialize]
    set str {form#search.wide}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<form id="search" class="wide" action="">$2</form>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify custom attributes.
  proc run_test11 {} {

    set txt [initialize]
    set str {p[title="Hello World"]}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<p title="Hello World"></p>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify multiple custom attributes including attribute without assignment.
  proc run_test12 {} {

    set txt [initialize]
    set str {td[rowspan=2 colspan=3 title]}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<td rowspan="2" title="" colspan="3">$2</td>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify sibling text and child text values.
  proc run_test13 {} {

    set txt [initialize]
    set str {p>{Click }+a{here}+{ to continue}}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<p>Click <a href="">here</a> to continue</p>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify leaf node output.
  proc run_test14 {} {

    set txt [initialize]
    set str {link}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<link href="" rel="stylesheet" />$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify leaf node attribute override.
  proc run_test15 {} {

    set txt [initialize]
    set str {link[rel=prefetch title="Hello world"]}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<link href="" title="Hello world" rel="prefetch" />$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify div implicit tags.
  proc run_test16 {} {

    set txt [initialize]
    set str {.wrap>.content}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div class="wrap">
  <div class="content"></div>
</div>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify emphasis implicit tags.
  proc run_test17 {} {

    set txt [initialize]
    set str {em>.info}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<em><span class="info"></span></em>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify unordered implicit tags.
  proc run_test18 {} {

    set txt [initialize]
    set str {ul>.item}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="item"></li>
</ul>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify table implicit tags.
  proc run_test19 {} {

    set txt [initialize]
    set str {table>#row>[colspan=2]}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<table>
  <tr id="row">
    <td colspan="2"></td>
  </tr>
</table>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify dir implicit tagging for custom attributes.
  proc run_test20 {} {

    set txt [initialize]
    set str {[a='value' b="value2"]}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<div a="value" b="value2"></div>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify multiplier and enumeration.
  proc run_test21 {} {

    set txt [initialize]
    set str {ul>li.b$*5}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="b1"></li>
  <li class="b2">$2</li>
  <li class="b3">$3</li>
  <li class="b4">$4</li>
  <li class="b5">$5</li>
</ul>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify enumeration with starting value.
  proc run_test22 {} {

    set txt [initialize]
    set str {ul>li.b$@4*5}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="b4"></li>
  <li class="b5">$2</li>
  <li class="b6">$3</li>
  <li class="b7">$4</li>
  <li class="b8">$5</li>
</ul>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify enumeration with a negative increment.
  proc run_test23 {} {

    set txt [initialize]
    set str {ul>li.b$@-*5}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="b5"></li>
  <li class="b4">$2</li>
  <li class="b3">$3</li>
  <li class="b2">$4</li>
  <li class="b1">$5</li>
</ul>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify enumeration with a negative increment and starting value.
  proc run_test24 {} {

    set txt [initialize]
    set str {ul>li.class$$@-7*5}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="class11"></li>
  <li class="class10">$2</li>
  <li class="class09">$3</li>
  <li class="class08">$4</li>
  <li class="class07">$5</li>
</ul>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify proper text value handling.
  proc run_test25 {} {

    set txt [initialize]
    set str {a{click}+b{here}}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<a href="">click</a><b>here</b>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify proper text value handling.
  proc run_test26 {} {

    set txt [initialize]
    set str {a>{click}+b{here}}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<a href="">click<b>here</b></a>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify multiplication of groups.
  proc run_test27 {} {

    set txt [initialize]
    set str {(div>dl>(dt+dd)*3)+foobar>p}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div>
  <dl>
    <dt></dt>
    <dd>$2</dd>
    <dt>$3</dt>
    <dd>$4</dd>
    <dt>$5</dt>
    <dd>$6</dd>
  </dl>
</div>
<foobar>
  <p>$7</p>
</foobar>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify enumeration formatting.
  proc run_test28 {} {

    set txt [initialize]
    set str {ul>li.item$$$*6}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="item001"></li>
  <li class="item002">$2</li>
  <li class="item003">$3</li>
  <li class="item004">$4</li>
  <li class="item005">$5</li>
  <li class="item006">$6</li>
</ul>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify enumeration is applied to all elements of a node.
  proc run_test29 {} {

    set txt [initialize]
    set str {h$[title=item$]{Header $}*3}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<h1 title="item1">Header 1</h1>
<h2 title="item2">Header 2</h2>
<h3 title="item3">Header 3</h3>}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify nodes with exclamation points.
  proc run_test30 {} {

    set txt [initialize]
    set str {!!!4t}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<!DOCTYPE HTML="PUBLIC" -//W3C//DTD HTML 4.01 Transitional//EN="http://www.w3.org/TR/html4/loose.dtd">}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify substitution.
  proc run_test31 {} {

    set txt [initialize]
    set str {doc}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<html>
  <head>
    <meta charset="UTF-8" />
    <title>Document</title>
  </head>
  <body>$2</body>
</html>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ([join [split $actual \n] ,\n])"
    }

    cleanup

  }

  # Verify substitution in XSL.
  proc run_test32 {} {

    set txt [initialize]
    set str {xsl}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"></xsl:stylesheet>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify substitution in expression.
  proc run_test33 {} {

    set txt [initialize]
    set str {(choose+)+foobar}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<xml:choose>
  <xsl:when test="">$2</xsl:when>
  <xsl:otherwise>$3</xsl:otherwise>
</xml:choose>
<foobar>$4</foobar>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify complicated expression output.
  proc run_test34 {} {

    set txt [initialize]
    set str {#page>div.logo+ul#navigation>li*5>a{Item $}}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div id="page">
  <div class="logo"></div>
  <ul id="navigation">
    <li><a href="$2">Item 1</a></li>
    <li><a href="$3">Item 2</a></li>
    <li><a href="$4">Item 3</a></li>
    <li><a href="$5">Item 4</a></li>
    <li><a href="$6">Item 5</a></li>
  </ul>
</div>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Another complex output example.
  proc run_test35 {} {

    set txt [initialize]
    set str {nav#menuSystem.navMenu.isOpen>div#hotelLogo>div.navMenuIcon.logoIcon+div#arrowPointer+ul#navMenuMain>li.navMenuItem.navMenuItem$$$*10>div.navMenuIcon{Item $}+a{Item $}}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<nav id="menuSystem" class="isOpen navMenu">
  <div id="hotelLogo">
    <div class="logoIcon navMenuIcon"></div>
    <div id="arrowPointer">$2</div>
    <ul id="navMenuMain">
      <li class="navMenuItem001 navMenuItem">
        <div class="navMenuIcon">Item 1</div>
        <a href="$3">Item 1</a>
      </li>
      <li class="navMenuItem002 navMenuItem">
        <div class="navMenuIcon">Item 2</div>
        <a href="$4">Item 2</a>
      </li>
      <li class="navMenuItem003 navMenuItem">
        <div class="navMenuIcon">Item 3</div>
        <a href="$5">Item 3</a>
      </li>
      <li class="navMenuItem004 navMenuItem">
        <div class="navMenuIcon">Item 4</div>
        <a href="$6">Item 4</a>
      </li>
      <li class="navMenuItem005 navMenuItem">
        <div class="navMenuIcon">Item 5</div>
        <a href="$7">Item 5</a>
      </li>
      <li class="navMenuItem006 navMenuItem">
        <div class="navMenuIcon">Item 6</div>
        <a href="$8">Item 6</a>
      </li>
      <li class="navMenuItem007 navMenuItem">
        <div class="navMenuIcon">Item 7</div>
        <a href="$9">Item 7</a>
      </li>
      <li class="navMenuItem008 navMenuItem">
        <div class="navMenuIcon">Item 8</div>
        <a href="$10">Item 8</a>
      </li>
      <li class="navMenuItem009 navMenuItem">
        <div class="navMenuIcon">Item 9</div>
        <a href="$11">Item 9</a>
      </li>
      <li class="navMenuItem010 navMenuItem">
        <div class="navMenuIcon">Item 10</div>
        <a href="$12">Item 10</a>
      </li>
    </ul>
  </div>
</nav>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify a user-input tabstop with default value can work properly.
  proc run_test36 {} {

    set txt [initialize]
    set str {a{{|foobar}}}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {<a href="">foobar</a>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify that an expansion occurs and replaces the proper code.
  proc run_test37 {} {

    set txt [initialize]
    set str {<div>ul>li</div>}

    $txt insert end "\n$str"
    $txt cursor set 2.10

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div><ul>
  <li></li>
</ul>$0</div>}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify that abbrevation stops at whitespace.
  proc run_test38 {} {

    set txt [initialize]
    set str {This is b{good}!}

    $txt insert end "\n$str"
    $txt cursor set 2.15

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {This is <b>good</b>!}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify that abbreviation stops at whitespace that is not a part of the abbreviation.
  proc run_test39 {} {

    set txt [initialize]
    set str {This is b{very good}!}

    $txt insert end "\n$str"
    $txt cursor set 2.20

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {This is <b>very good</b>!}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify that abbreviation stops at whitespace that is not a part of the
  # abbreviation.
  proc run_test40 {} {

    set txt [initialize]
    set str {This is a[href='great game']{good}!}

    $txt insert end "\n$str"
    $txt cursor set 2.34

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {This is <a href="great game">good</a>!}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify that abbreviation stops at whitespace that is not a part of the
  # abbreviation.
  proc run_test41 {} {

    set txt [initialize]
    set str {This is a[href="great game"]{good}!}

    $txt insert end "\n$str"
    $txt cursor set 2.34

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect {This is <a href="great game">good</a>!}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify that the proper whitespace is used
  proc run_test42 {} {

    set txt [initialize]
    set str {  nav>ul>li}

    $txt insert end "\n$str"
    $txt cursor set end-1c

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{  <nav>
    <ul>
      <li></li>
    </ul>
  </nav>$0}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify that the initial whitespace is used for indentation
  proc run_test43 {} {

    set txt [initialize]
    set str {  <nav>ul>li</nav>}

    $txt insert end "\n$str"
    $txt cursor set 2.12

    emmet::expand_abbreviation

    set actual [$txt get 2.0 end-1c]
    set expect \
{  <nav><ul>
    <li></li>
  </ul>$0</nav>}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  proc run_test44 {} {

    set txt [initialize]
    set str "<html>\n<nav>ul>li</nav>\n</html>"

    $txt insert end $str
    $txt cursor set 2.10

    emmet::expand_abbreviation

    set actual [$txt get 1.0 end-1c]
    set expect \
{<html>
<nav><ul>
  <li></li>
</ul>$0</nav>
</html>}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Wrap with simple abbreviation from selection
  proc run_test100 {} {

    # Initialize
    set txt [initialize]

    $txt insert end "\n<p>Hello</p>"
    $txt tag add sel 2.0 2.12

    emmet::wrap_with_abbreviation -test "body>dir"

    set actual [$txt get 1.0 end-1c]
    set expect {
<body>
  <dir><p>Hello</p></dir>
</body>}

    if {$actual ne $expect} {
      cleanup "abbreviation not wrapped correctly ($actual)"
    }

    # Cleanup
    cleanup

  }

  # Wrap with simple abbreviation with no selection
  proc run_test101 {} {

    # Initialize
    set txt [initialize]

    $txt insert end "\n<p>Hello</p>"
    $txt cursor set 2.1

    emmet::wrap_with_abbreviation -test "ul>li"

    set actual [$txt get 1.0 end-1c]
    set expect {
<ul>
  <li><p>Hello</p></li>
</ul>}

    if {$actual ne $expect} {
      cleanup "abbreviation not wrapped correctly ($actual)"
    }

    # Cleanup
    cleanup

  }

  # Wrap multiple lines with abbreviation
  proc run_test102 {} {

    # Initialize
    set txt [initialize]

    $txt insert end "\nHello\nWorld\nAgain"
    $txt tag add sel 2.0 5.0

    emmet::wrap_with_abbreviation -test "ul>li*>p"

    set actual [$txt get 1.0 end-1c]
    set expect \
{<ul>
  <li>
    <p>Hello</p>
  </li>
  <li>
    <p>World</p>
  </li>
  <li>
    <p>Again</p>
  </li>
</ul>}

    if {$actual ne $expect} {
      cleanup "abbreviation not wrapped correctly ($actual)"
    }

    # Cleanup
    cleanup

  }

  # Wrap multi-line abbreviation with attributes
  proc run_test103 {} {

    # Initialize
    set txt [initialize]

    $txt insert end "\nHello\nWorld\nGo"
    $txt tag add sel 2.0 5.0

    emmet::wrap_with_abbreviation -test {ul>li[title=$#]*>{$#}+img[alt=$#]}

    set actual [$txt get 1.0 end-1c]
    set expect \
{<ul>
  <li title="Hello">
    Hello
    <img alt="Hello" src="" />
  </li>
  <li title="World">
    World
    <img alt="World" src="$2" />
  </li>
  <li title="Go">
    Go
    <img alt="Go" src="$3" />
  </li>
</ul>$0}

    if {$actual ne $expect} {
      cleanup "abbreviation not wrapped correctly ($actual)"
    }

    # Cleanup
    cleanup

  }

  # Wrap with bad abbreviation
  proc run_test104 {} {

    # Initialize
    set txt [initialize]

    $txt insert end "\nHello World"
    $txt cursor set 2.0
    $txt tag add sel 2.0 3.0

    emmet::wrap_with_abbreviation -test {ul<li}

    if {[$txt get 1.0 end-1c] ne "\nHello World"} {
      cleanup "Bad abbreviation was used when it should not have been used ([$txt get 1.0 end-1c])"
    }
    if {[$txt tag ranges sel] ne [list 2.0 3.0]} {
      cleanup "Selection was removed ([$txt tag ranges sel])"
    }

    # Cleanup
    cleanup

  }

  # Verify balance outward and inward actions
  proc run_test110 {} {

    # Initialize
    set txt [initialize]

    $txt insert end {
<div id="page">
  <section class="content">
    <h1>Document example</h1>
    <p>Lorem ipsum dolor sit amet.</p>
  </section>
</div>}
    $txt cursor set 5.10

    foreach {startpos endpos} [list 5.7 5.34 5.4 5.38 3.27 6.2 3.2 6.12 2.15 7.0 2.0 7.6 2.0 7.6] {
      emmet::balance_outward
      if {[$txt tag ranges sel] ne [list $startpos $endpos]} {
        cleanup "outward balance mismatched $startpos $endpos ([$txt tag ranges sel])"
      }
      if {[$txt index insert] ne $startpos} {
        cleanup "outward cursor incorrect ([$txt index insert])"
      }
    }

    foreach {startpos endpos} [list 2.15 7.0 3.2 6.12 3.27 6.2 4.4 4.29 4.8 4.24 4.8 4.24] {
      emmet::balance_inward
      if {[$txt tag ranges sel] ne [list $startpos $endpos]} {
        cleanup "inward balance mismatched $startpos $endpos ([$txt tag ranges sel])"
      }
      if {[$txt index insert] ne $startpos} {
        cleanup "inward cursor incorrect ([$txt index insert])"
      }
    }

    # Clear the selection and run balance inward
    $txt tag remove sel 1.0 end
    emmet::balance_inward
    if {[$txt tag ranges sel] ne [list 4.8 4.24]} {
      cleanup "inward balance called when no selection exists incorrect ([$txt tag ranges sel])"
    }
    if {[$txt index insert] ne "4.8"} {
      cleanup "inward cursor incorrect ([$txt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Verify Go to Matching Pair action
  proc run_test111 {} {

    # Initialize
    set txt [initialize]

    $txt insert end {
<div id="page">
  <section class="content">
    <h1>Document example</h1>
    <p>Lorem ipsum <p>dolor</p> sit amet.</p>
    <p>Nothing.
  </section>
</div>}
    $txt cursor set 8.2

    emmet::go_to_matching_pair
    if {[$txt index insert] ne "2.0"} {
      cleanup "starting matching pair cursor A incorrect ([$txt index insert])"
    }

    emmet::go_to_matching_pair
    if {[$txt index insert] ne "8.0"} {
      cleanup "ending matching pair cursor incorrect ([$txt index insert])"
    }

    emmet::go_to_matching_pair
    if {[$txt index insert] ne "2.0"} {
      cleanup "starting matching pair cursor B incorrect ([$txt index insert])"
    }

    # Attempt to go to matching pair when we are not within a tag
    $txt cursor set 3.0
    emmet::go_to_matching_pair
    if {[$txt index insert] ne "3.0"} {
      cleanup "cursor moved when we are not within a tag ([$txt index insert])"
    }

    # Attempt to jump to a tag which does not have a matching pair
    $txt cursor set 6.4
    emmet::go_to_matching_pair
    if {[$txt index insert] ne "6.4"} {
      cleanup "cursor moved when we are in a tag that doesn't have a match ([$txt index insert])"
    }

    # Attempt to go to a matching paire that passes through multiple tags of the same type
    $txt cursor set 5.4
    emmet::go_to_matching_pair
    if {[$txt index insert] ne "5.41"} {
      cleanup "ending matching pair cursor C incorrect ([$txt index insert])"
    }

    emmet::go_to_matching_pair
    if {[$txt index insert] ne "5.4"} {
      cleanup "starting matching pair cursor C incorrect ([$txt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Verify Go to Next/Previous Edit Point action
  proc run_test112 {} {

    # Initialize
    set txt [initialize]

    $txt insert end [string map {XX {  }} {
<ul>
  <li><a href=""></a></li>
  <li><a href="foo" bar="nice"></a></li>
</ul>
<div>
XX
</div>}]
    $txt cursor set 1.0

    foreach cursor [list 3.6 3.15 3.17 3.21 4.6 4.31 4.35 7.2 7.2] {
      emmet::go_to_edit_point next
      if {[$txt index insert] ne $cursor} {
        cleanup "next cursor is incorrect $cursor ([$txt index insert])"
      }
    }

    $txt cursor set 8.0
    foreach cursor [list 7.2 4.35 4.31 4.6 3.21 3.17 3.15 3.6 3.6] {
      emmet::go_to_edit_point prev
      if {[$txt index insert] ne $cursor} {
        cleanup "prev cursor is incorrect $cursor ([$txt index insert])"
      }
    }

    # Cleanup
    cleanup

  }

  # Verify Select Next/Previous Item action
  proc run_test113 {} {

    # Initialize
    set txt [initialize]

    $txt insert end {
<body>

  <a href="http://foobar.com" target="parent child sibling">
    <img src="images/advanced.gif" width="32" height="32" />
    <ul>
      <li class="" id=""><p>Hello world</p></li>
      <li></li>
      <li class="blah" />
    </ul>
  </a>
</body>}
    $txt cursor set 3.0

    foreach {startpos endpos} [list 4.3 4.4 4.5 4.29 4.11 4.28 4.30 4.59 4.38 4.58 4.38 4.44 4.45 4.50 4.51 4.58 \
                                    5.5 5.8 5.9 5.34 5.14 5.33 5.35 5.45 5.42 5.44 5.46 5.57 5.54 5.56 \
                                    6.5 6.7 \
                                    7.7 7.9 7.10 7.18 7.19 7.24 7.26 7.27 \
                                    8.7 8.9 \
                                    9.7 9.9 9.10 9.22 9.17 9.21 9.17 9.21] {
      emmet::select_item next
      if {[$txt tag ranges sel] ne [list $startpos $endpos]} {
        cleanup "next select item incorrect $startpos $endpos ([$txt tag ranges sel])"
      }
      if {[$txt index insert] ne $endpos} {
        cleanup "next cursor incorrect $endpos ([$txt index insert])"
      }
    }

    foreach {startpos endpos} [list 9.10 9.22 9.7 9.9 \
                                    8.7 8.9 \
                                    7.26 7.27 7.19 7.24 7.10 7.18 7.7 7.9 \
                                    6.5 6.7 \
                                    5.54 5.56 5.46 5.57 5.42 5.44 5.35 5.45 5.14 5.33 5.9 5.34 5.5 5.8 \
                                    4.51 4.58 4.45 4.50 4.38 4.44 4.38 4.58 4.30 4.59 4.11 4.28 4.5 4.29 4.3 4.4 \
                                    2.1 2.5 2.1 2.5] {
      emmet::select_item prev
      if {[$txt tag ranges sel] ne [list $startpos $endpos]} {
        cleanup "prev select item incorrect $startpos $endpos ([$txt tag ranges sel])"
      }
      if {[$txt index insert] ne $endpos} {
        cleanup "next cursor incorrect $endpos ([$txt index insert])"
      }
    }

    foreach test [list {4.2 4.3 4.4} {4.3 4.3 4.4} {4.4 4.5 4.29} {4.5 4.5 4.29} {4.6 4.5 4.29} {4.11 4.11 4.28} {4.28 4.30 4.59}] {
      $txt mark set insert [lindex $test 0]
      emmet::select_item next
      if {[$txt tag ranges sel] ne [lrange $test 1 2]} {
        cleanup "next select item incorrect [lindex $test 0] ([$txt tag ranges sel])"
      }
      if {[$txt index insert] ne [lindex $test 2]} {
        cleanup "next select cursor incorrect [lindex $test 0] ([$txt index insert])"
      }
    }

    foreach test [list {4.29 4.11 4.28} {4.28 4.5 4.29}] {
      $txt mark set insert [lindex $test 0]
      emmet::select_item prev
      if {[$txt tag ranges sel] ne [lrange $test 1 2]} {
        cleanup "prev select item incorrect [lindex $test 0] ([$txt tag ranges sel])"
      }
      if {[$txt index insert] ne [lindex $test 2]} {
        cleanup "prev select cursor incorrect [lindex $test 0] ([$txt index insert])"
      }
    }

    # Cleanup
    cleanup

  }

  # Verify Toggle Comment action
  proc run_test114 {} {

    # Initialize
    set txt [initialize]

    $txt insert end [set value {
<body>
  <img src="stuff.png" />
  <p>Here is <b>bold</b></p>
</body>}]
    $txt cursor set 2.0

    emmet::toggle_comment
    if {[$txt get 1.0 end-1c] ne [set body_value "\n<!-- <body>\n  <img src=\"stuff.png\" />\n  <p>Here is <b>bold</b></p>\n</body> -->"]} {
      cleanup "body was not commented correctly ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "2.5"} {
      cleanup "body comment cursor incorrect ([$txt index insert])"
    }

    emmet::toggle_comment
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "body was not uncommented correctly ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "2.0"} {
      cleanup "body uncomment cursor incorrect ([$txt index insert])"
    }

    $txt cursor set 4.0
    emmet::toggle_comment
    if {[$txt get 1.0 end-1c] ne $body_value} {
      cleanup "body was not commented correctly B ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "4.0"} {
      cleanup "body comment cursor incorrect B ([$txt index insert])"
    }

    emmet::toggle_comment
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "body was not uncommented correctly B ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 3.3
    emmet::toggle_comment
    if {[$txt get 1.0 end-1c] ne "\n<body>\n  <!-- <img src=\"stuff.png\" /> -->\n  <p>Here is <b>bold</b></p>\n</body>"} {
      cleanup "img was not commented correctly ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "3.8"} {
      cleanup "img comment cursor incorrect ([$txt index insert])"
    }

    $txt cursor set 2.2
    emmet::toggle_comment
    if {[$txt get 1.0 end-1c] ne $body_value} {
      cleanup "body was not commented correctly C ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "2.7"} {
      cleanup "body comment cursor incorrect C ([$txt index insert])"
    }

    # Attempt to comment nothing and make sure that nothing happens
    $txt cursor set 1.0
    emmet::toggle_comment
    if {[$txt get 1.0 end-1c] ne $body_value} {
      cleanup "blank space was not left alone ([utils::ostr [$txt get 1.0 end-1c]])"
    }
    if {[$txt index insert] ne "1.0"} {
      cleanup "cursor was not left on blank space ([$txt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Verify Split/Join Tag action
  proc run_test115 {} {

    # Initialize
    set txt [initialize]

    $txt insert end {
<example>
    Lorem ipsum dolor sit amet
</example>}
    $txt cursor set 2.0

    emmet::split_join_tag
    if {[$txt get 1.0 end-1c] ne "\n<example />"} {
      cleanup "Tag join incorrect ([$txt get 1.0 end-1c])"
    }

    emmet::split_join_tag
    if {[$txt get 1.0 end-1c] ne "\n<example></example>"} {
      cleanup "Tag split incorrect ([$txt get 1.0 end-1c])"
    }

    # Make sure that nothing happens if we attempt to split/join when we are not within a node.
    $txt cursor set 1.0
    emmet::split_join_tag
    if {[$txt get 1.0 end-1c] ne "\n<example></example>"} {
      cleanup "Tag was joined when cursor is not within node/tag ([$txt get 1.0 end-1c])"
    }

    # Cleanup
    cleanup

  }

  # Verify remove tag
  proc run_test116 {} {

    # Initialize
    set txt [initialize]

    $txt insert end [set value {
<body>
  <div class="wrapper">
    <h1>Title</h1>
    <p>Lorem ipsum <p>dolor</p> sit amet.</p>
    <p></p>
    <p />
    <p />Good
  </div>
</body>}]
    $txt edit separator
    $txt cursor set 3.2

    emmet::remove_tag
    if {[$txt get 1.0 end-1c] ne [set remove_value "\n<body>\n  <h1>Title</h1>\n  <p>Lorem ipsum <p>dolor</p> sit amet.</p>\n  <p></p>\n  <p />\n  <p />Good\n</body>"]} {
      cleanup "tag removed incorrectly ([$txt get 1.0 end-1c])"
    }

    gui::undo
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "A tag undo incorrectly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 4.0
    emmet::remove_tag
    if {[$txt get 1.0 end-1c] ne $remove_value} {
      cleanup "tag removed incorrectly B ([$txt get 1.0 end-1c])"
    }

    gui::undo
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "B tag undo incorrectly ([$txt get 1.0 end-1c])"
    }

    # Make sure that a single blank node can be removed properly
    $txt cursor set 6.4
    emmet::remove_tag
    if {[$txt get 1.0 end-1c] ne "\n<body>\n  <div class=\"wrapper\">\n    <h1>Title</h1>\n    <p>Lorem ipsum <p>dolor</p> sit amet.</p>\n    <p />\n    <p />Good\n  </div>\n</body>"} {
      cleanup "Single blank tag removed incorrectly ([$txt get 1.0 end-1c])"
    }

    gui::undo
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "C tag undo incorrectly ([$txt get 1.0 end-1c])"
    }

    # Delete inner <p>
    $txt cursor set 5.20
    emmet::remove_tag
    if {[$txt get 1.0 end-1c] ne [set remove_value "\n<body>\n  <div class=\"wrapper\">\n    <h1>Title</h1>\n    <p>Lorem ipsum dolor sit amet.</p>\n    <p></p>\n    <p />\n    <p />Good\n  </div>\n</body>"]} {
      cleanup "Deleting inner tag did not work ([$txt get 1.0 end-1c])($remove_value)"
    }

    gui::undo
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "D tag undo incorrectly ([$txt get 1.0 end-1c])"
    }

    # Delete combo tag
    $txt cursor set 7.5
    emmet::remove_tag
    if {[$txt get 1.0 end-1c] ne "\n<body>\n  <div class=\"wrapper\">\n    <h1>Title</h1>\n    <p>Lorem ipsum <p>dolor</p> sit amet.</p>\n    <p></p>\n    <p />Good\n  </div>\n</body>"} {
      cleanup "deleting combo tag did not work ([$txt get 1.0 end-1c])"
    }

    gui::undo
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "E tag undo incorrectly ([$txt get 1.0 end-1c])"
    }

    # Delete combo tag that contains other stuff on the line
    $txt cursor set 8.5
    emmet::remove_tag
    if {[$txt get 1.0 end-1c] ne "\n<body>\n  <div class=\"wrapper\">\n    <h1>Title</h1>\n    <p>Lorem ipsum <p>dolor</p> sit amet.</p>\n    <p></p>\n    <p />\n    Good\n  </div>\n</body>"} {
      cleanup "deleting combo tag with text on the line did not work ([$txt get 1.0 end-1c])"
    }

    gui::undo
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "F tag undo incorrectly ([$txt get 1.0 end-1c])"
    }

    # Attempt to delete empty space
    $txt cursor set 1.0
    emmet::remove_tag
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "deleting tag when we are not within a tag/node did not work ([$txt get 1.0 end-1c])"
    }

    # Cleanup
    cleanup

  }

  # Verify Merge Lines action
  proc run_test117 {} {

    # Initialize
    set txt [initialize]

    $txt insert end [set value {
<p>
  Line 1.

  <b>Line</b> 2.
</p>}]
    $txt edit separator
    $txt cursor set 2.0

    emmet::merge_lines
    if {[$txt get 1.0 end-1c] ne [set merge_value "\n<p>Line 1.<b>Line</b> 2.</p>"]} {
      cleanup "merge lines incorrect ([$txt get 1.0 end-1c])"
    }

    gui::undo
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "merge undo incorrect ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 5.0
    emmet::merge_lines
    if {[$txt get 1.0 end-1c] ne $merge_value} {
      cleanup "merge lines incorrect B ([$txt get 1.0 end-1c])"
    }

    gui::undo
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "merge undo incorrect ([$txt get 1.0 end-1c])"
    }

    # Verify that merging a line that is not within a node does nothing
    $txt cursor set 1.0
    emmet::merge_lines
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "merge lines when not in a node changed text ([$txt get 1.0 end-1c])"
    }

    # Cleanup
    cleanup

  }

  # Verify Update Image Size action
  proc run_test118 {} {

    # Initialize
    set txt    [initialize]
    set url    "http://tke.sourceforge.net/screenshots_files/page2-1000-thumb.jpg"
    set bad    "http://tke.sourceforge.net/blah.jpg"
    set width  144
    set height 144
    set tags   [list [list "\n<img src=\"$url\" alt=\"\" />"                             "\n<img src=\"$url\" width=\"$width\" height=\"$height\" alt=\"\" />"] \
                     [list "\n<img src=\"$url\" alt=\"\" width=\"10\" />"                "\n<img src=\"$url\" alt=\"\" width=\"$width\" height=\"$height\" />"] \
                     [list "\n<img src=\"$url\" alt=\"\" height=\"11\" />"               "\n<img src=\"$url\" alt=\"\" width=\"$width\" height=\"$height\" />"] \
                     [list "\n<img src=\"$url\" alt=\"\" height=\"20\" width=\"100\" />" "\n<img src=\"$url\" alt=\"\" height=\"$height\" width=\"$width\" />"] \
                     [list "\n<img src=\"$url\" alt=\"\" width=\"20\" height=\"100\" />" "\n<img src=\"$url\" alt=\"\" width=\"$width\" height=\"$height\" />"] \
                     [list "\n<img src=\"$bad\" alt=\"\" height=\"20\" width=\"100\" />" "\n<img src=\"$bad\" alt=\"\" height=\"20\" width=\"100\" />"]]

    set i 0
    foreach tag $tags {

      $txt delete 1.0 end
      $txt insert end [lindex $tag 0]
      $txt edit separator
      $txt cursor set 2.0

      emmet::update_image_size
      if {[$txt get 1.0 end-1c] ne [lindex $tag 1]} {
        cleanup "$i img tag does not match expected ([$txt get 1.0 end-1c])"
      }

      incr i

    }

    # Verify that updating an image outside of an image tag does not work
    $txt delete 1.0 end
    $txt insert end [lindex $tags 0 0]
    $txt edit separator
    $txt cursor set 1.0

    emmet::update_image_size
    if {[$txt get 1.0 end-1c] ne [lindex $tags 0 0]} {
      cleanup "image update did not work properly ([$txt get 1.0 end-1c])"
    }

    # Cleanup
    cleanup

  }

  # Verify Evaluate Math Expression
  proc run_test119 {} {

    # Initialize
    set txt [initialize]

    $txt insert end "\n100+91\nabs(-10)\n10/4\n10.0/4\n\nNothing 2*3"
    $txt cursor set 2.0

    emmet::evaluate_math_expression
    if {[$txt get 1.0 end-1c] ne "\n191\nabs(-10)\n10/4\n10.0/4\n\nNothing 2*3"} {
      cleanup "Addition did not work correctly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 3.0
    emmet::evaluate_math_expression
    if {[$txt get 1.0 end-1c] ne "\n191\n10\n10/4\n10.0/4\n\nNothing 2*3"} {
      cleanup "Absolute did not work properly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 4.0
    emmet::evaluate_math_expression
    if {[$txt get 1.0 end-1c] ne "\n191\n10\n2\n10.0/4\n\nNothing 2*3"} {
      cleanup "Integer division did not work properly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 5.0
    emmet::evaluate_math_expression
    if {[$txt get 1.0 end-1c] ne "\n191\n10\n2\n2.5\n\nNothing 2*3"} {
      cleanup "Real division did not work properly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 6.0
    emmet::evaluate_math_expression
    if {[$txt get 1.0 end-1c] ne "\n191\n10\n2\n2.5\n\nNothing 2*3"} {
      cleanup "Empty line did not work properly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 7.0
    emmet::evaluate_math_expression
    if {[$txt get 1.0 end-1c] ne "\n191\n10\n2\n2.5\n\nNothing 2*3"} {
      cleanup "NAN did not work properly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 7.10
    emmet::evaluate_math_expression
    if {[$txt get 1.0 end-1c] ne "\n191\n10\n2\n2.5\n\nNothing 6"} {
      cleanup "Multiplication did not work properly ([$txt get 1.0 end-1c])"
    }

    # Cleanup
    cleanup

  }

  # Verify Increment/Decrement Number action
  proc run_test120 {} {

    # Initialize
    set txt [initialize]

    $txt insert end "\nx100x\nx-100x\nNothing\n-x\n0x10"
    $txt cursor set 2.1

    emmet::change_number 10
    if {[$txt get 1.0 end-1c] ne "\nx110x\nx-100x\nNothing\n-x\n0x10"} {
      cleanup "Increment by 10 did not work properly ([$txt get 1.0 end-1c])"
    }

    emmet::change_number 1
    if {[$txt get 1.0 end-1c] ne "\nx111x\nx-100x\nNothing\n-x\n0x10"} {
      cleanup "Increment by 1 did not work properly ([$txt get 1.0 end-1c])"
    }

    emmet::change_number 0.1
    if {[$txt get 1.0 end-1c] ne "\nx111.1x\nx-100x\nNothing\n-x\n0x10"} {
      cleanup "Increment by 0.1 did not work properly ([$txt get 1.0 end-1c])"
    }

    emmet::change_number -10
    if {[$txt get 1.0 end-1c] ne "\nx101.1x\nx-100x\nNothing\n-x\n0x10"} {
      cleanup "Decrement by 10 did not work properly ([$txt get 1.0 end-1c])"
    }

    emmet::change_number -1
    if {[$txt get 1.0 end-1c] ne "\nx100.1x\nx-100x\nNothing\n-x\n0x10"} {
      cleanup "Decrement by 1 did not work properly ([$txt get 1.0 end-1c])"
    }

    emmet::change_number -0.1
    if {[$txt get 1.0 end-1c] ne "\nx100x\nx-100x\nNothing\n-x\n0x10"} {
      cleanup "Decrement by 0.1 did not work properly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 2.0
    emmet::change_number 1
    if {[$txt get 1.0 end-1c] ne "\nx100x\nx-100x\nNothing\n-x\n0x10"} {
      cleanup "Changing non-number did not work properly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 2.4
    emmet::change_number 1
    if {[$txt get 1.0 end-1c] ne "\nx100x\nx-100x\nNothing\n-x\n0x10"} {
      cleanup "Changing non-number did not work properly 2 ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 3.1
    emmet::change_number 1
    if {[$txt get 1.0 end-1c] ne "\nx100x\nx-99x\nNothing\n-x\n0x10"} {
      cleanup "Changing negative number did not work properly ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 3.2
    emmet::change_number 1
    if {[$txt get 1.0 end-1c] ne "\nx100x\nx-98x\nNothing\n-x\n0x10"} {
      cleanup "Changing negative number did not work properly B ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 3.3
    emmet::change_number 1
    if {[$txt get 1.0 end-1c] ne "\nx100x\nx-97x\nNothing\n-x\n0x10"} {
      cleanup "Changing negative number did not work properly C ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 4.0
    emmet::change_number 1
    if {[$txt get 1.0 end-1c] ne "\nx100x\nx-97x\nNothing\n-x\n0x10"} {
      cleanup "Changing non-number did not work properly 3 ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 5.0
    emmet::change_number 1
    if {[$txt get 1.0 end-1c] ne "\nx100x\nx-97x\nNothing\n-x\n0x10"} {
      cleanup "Changing non-number did not work properly 4 ([$txt get 1.0 end-1c])"
    }

    $txt cursor set 6.3
    emmet::change_number 1
    if {[$txt get 1.0 end-1c] ne "\nx100x\nx-97x\nNothing\n-x\n0x10"} {
      cleanup "Changing hexidecimal number should do nothing ([$txt get 1.0 end-1c])"
    }

    # Cleanup
    cleanup

  }

  # Verify Encode/Decode data:URL action
  proc run_test121 {} {

    # Initialize
    set txt [initialize]
    set url "http://tke.sourceforge.net/resources/unchecked.gif"
    set ro  [file join $::tke_home readonly.png]

    $txt insert end [set value "\n<img src=\"$url\" width=\"11\" height=\"11\" />"]
    $txt edit separator
    $txt cursor set 2.20

    emmet::encode_decode_image_to_data_url
    if {[$txt get 1.0 end-1c] ne [set expect "\n<img src=\"data:image/gif;base64,R0lGODdhCwALAJEAAH9/f////////////ywAAAAACwALAAACH4SPRvEPADEIYPwDQAwCGP8AEIMAxj8AxCCA8Y/goxUAOw==\" width=\"11\" height=\"11\" />"]} {
      cleanup "File not encoded properly ([$txt get 1.0 end-1c])"
    }

    emmet::encode_decode_image_to_data_url -test "foobar.gif"
    if {![file exists "foobar.gif"]} {
      cleanup "foobar.gif was not created"
    }
    file delete -force "foobar.gif"
    if {[$txt get 1.0 end-1c] ne "\n<img src=\"./foobar.gif\" width=\"11\" height=\"11\" />"} {
      cleanup "Data not decoded properly ([$txt get 1.0 end-1c])"
    }

    gui::undo
    gui::undo
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "Undo did not work ([$txt get 1.0 end-1c])"
    }

    # Make sure that the encode does not work even if insertion cursor is only within tag
    $txt cursor set 2.0
    emmet::encode_decode_image_to_data_url
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "cursor within tag does not encode ([$txt get 1.0 end-1c])"
    }

    # Verify that nothing happens when we are not in an image tag
    $txt cursor set 1.0
    emmet::encode_decode_image_to_data_url
    if {[$txt get 1.0 end-1c] ne $value} {
      cleanup "text changed even though we were not on an image tag ([$txt get 1.0 end-1c])"
    }

    set i     0
    set tests [list "\n<img alt=\"foo\" src=\"\" />" 2.20 "" \
                    "\n<img src=\"[file join $::tke_dir lib api.tcl]\" />" 2.10 "" \
                    "\n<img src=\"data:image/png;base64,CABBAGE\" />" 2.10 $ro]

    set rc [open $ro w]
    puts $rc "Test"
    close $rc

    file attributes $ro -permissions r--------

    foreach {line cursor fname} $tests {
      $txt delete 1.0 end
      $txt insert end $line
      $txt cursor set $cursor
      emmet::encode_decode_image_to_data_url -test $fname
      if {[$txt get 1.0 end-1c] ne $line} {
        file attributes $ro -permissions rw-------
        file delete -force $ro
        cleanup "text changed when there was an error $i ([$txt get 1.0 end-1c])"
      }
      incr i
    }

    file attributes $ro -permissions rw-------
    file delete -force $ro

    # Cleanup
    cleanup

  }

}
