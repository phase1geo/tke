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

    # Set the current syntax to Tcl
    syntax::set_language $txt Tcl

    return $txt

  }

  ######################################################################
  # Common cleanup procedure.  If a fail message is provided, return an
  # error with the given error message.
  proc cleanup {{fail_msg ""}} {

    variable current_tab

    # Close the current tab
    gui::close_tab {} $current_tab -check 0

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<nav>
  <ul>
    <li></li>
  </ul>
</nav>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div></div>
<p>$2</p>
<blockquote>$3</blockquote>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div></div>
<div>
  <p><span>$2</span><em>$3</em></p>
  <blockquote>$4</blockquote>
</div>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div></div>
<div>
  <p><span>$2</span><em>$3</em></p>
</div>
<blockquote>$4</blockquote>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

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
</div>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<a href="">Click me</a>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<div id="header"></div>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<div class="title"></div>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<p class="class3 class2 class1"></p>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<form id="search" class="wide" action="">$2</form>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<p title="Hello World"></p>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<td rowspan="2" title="" colspan="3">$2</td>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<p>Click <a href="">here</a> to continue</p>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<link href="" rel="stylesheet" />}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<link href="" title="Hello world" rel="prefetch" />}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div class="wrap">
  <div class="content"></div>
</div>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<em><span class="info"></span></em>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="item"></li>
</ul>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<table>
  <tr id="row">
    <td colspan="2"></td>
  </tr>
</table>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<div a="value" b="value2"></div>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="b1"></li>
  <li class="b2">$2</li>
  <li class="b3">$3</li>
  <li class="b4">$4</li>
  <li class="b5">$5</li>
</ul>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="b4"></li>
  <li class="b5">$2</li>
  <li class="b6">$3</li>
  <li class="b7">$4</li>
  <li class="b8">$5</li>
</ul>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="b5"></li>
  <li class="b4">$2</li>
  <li class="b3">$3</li>
  <li class="b2">$4</li>
  <li class="b1">$5</li>
</ul>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="class11"></li>
  <li class="class10">$2</li>
  <li class="class09">$3</li>
  <li class="class08">$4</li>
  <li class="class07">$5</li>
</ul>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<a href="">click</a><b>here</b>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<a href="">click<b>here</b></a>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

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
</foobar>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<ul>
  <li class="item001"></li>
  <li class="item002">$2</li>
  <li class="item003">$3</li>
  <li class="item004">$4</li>
  <li class="item005">$5</li>
  <li class="item006">$6</li>
</ul>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<html>
  <head>
    <meta charset="UTF-8" />
    <title>Document</title>
  </head>
  <body>$2</body>
</html>}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

  # Verify substitution in XSL.
  proc run_test32 {} {

    set txt [initialize]
    set str {xsl}

    $txt insert end "\n$str"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"></xsl:stylesheet>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<xml:choose>
  <xsl:when test="">$2</xsl:when>
  <xsl:otherwise>$3</xsl:otherwise>
</xml:choose>
<foobar>$4</foobar>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

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
</div>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

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
</nav>}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {<a href="">foobar</a>}

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
    $txt mark set insert 2.10

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{<div><ul>
  <li></li>
</ul></div>}

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
    $txt mark set insert 2.15

    emmet::expand_abbreviation {}

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
    $txt mark set insert 2.20

    emmet::expand_abbreviation {}

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
    $txt mark set insert 2.34

    emmet::expand_abbreviation {}

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
    $txt mark set insert 2.34

    emmet::expand_abbreviation {}

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
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{  <nav>
    <ul>
      <li></li>
    </ul>
  </nav>}

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
    $txt mark set insert 2.12

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{  <nav><ul>
    <li></li>
  </ul></nav>}

    if {$actual ne $expect} {
      cleanup "$str did not expand properly ($actual)"
    }

    cleanup

  }

}
