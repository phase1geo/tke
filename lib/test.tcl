set tke_dir  [file normalize [file join [pwd] ..]]
set fail_cnt 0

package require http

source emmet_parser.tcl

puts [::emmet_get_lorem 20]

foreach {str expect} {
  
  {nav>ul>li}
  
{<nav>
  <ul>
    <li>$1</li>
  </ul>
</nav>}

  {div+p+bq}
  
{<div>$1</div>
<p>$2</p>
<blockquote>$3</blockquote>}

  {div+div>p>span+em^bq}
  
{<div>$1</div>
<div>
  <p><span>$2</span><em>$3</em></p>
  <blockquote>$4</blockquote>
</div>}

  {div+div>p>span+em^^bq}
  
{<div>$1</div>
<div>
  <p><span>$2</span><em>$3</em></p>
</div>
<blockquote>$4</blockquote>}

  {div>(header>ul>li*2>a)+footer>p}
  
{<div>
  <header>
    <ul>
      <li><a href="$1">$2</a></li>
      <li><a href="$3">$4</a></li>
    </ul>
  </header>
  <footer>
    <p>$5</p>
  </footer>
</div>}

  {a{Click me}}
  
{<a href="$1">Click me</a>}

  {div#header}
  
{<div id="header">$1</div>}

  {div.title}
  
{<div class="title">$1</div>}

  {p.class1.class2.class3}
  
{<p class="class3 class2 class1">$1</p>}

  {form#search.wide}
 
{<form id="search" class="wide" action="$1">$2</form>}

  {p[title="Hello World"]}
  
{<p title="Hello World">$1</p>}

  {td[rowspan=2 colspan=3 title]}
  
{<td rowspan="2" title="$1" colspan="3">$2</td>}

  {p>{Click }+a{here}+{ to continue}}
  
{<p>Click <a href="$1">here</a> to continue</p>}

  {link}
  
{<link href="$1" rel="stylesheet" />}

  {link[rel=prefetch title="Hello world"]}
  
{<link href="$1" title="Hello world" rel="prefetch" />}

  {.wrap>.content}
  
{<div class="wrap">
  <div class="content">$1</div>
</div>}

  {em>.info}
  
{<em><span class="info">$1</span></em>}

  {ul>.item}
  
{<ul>
  <li class="item">$1</li>
</ul>}

  {table>#row>[colspan=2]}
  
{<table>
  <tr id="row">
    <td colspan="2">$1</td>
  </tr>
</table>}

  {[a='value' b="value2"]}
  
{<div a="value" b="value2">$1</div>}

  {ul>li.b$*5}
  
{<ul>
  <li class="b1">$1</li>
  <li class="b2">$2</li>
  <li class="b3">$3</li>
  <li class="b4">$4</li>
  <li class="b5">$5</li>
</ul>}

  {ul>li.b$@4*5}
  
{<ul>
  <li class="b4">$1</li>
  <li class="b5">$2</li>
  <li class="b6">$3</li>
  <li class="b7">$4</li>
  <li class="b8">$5</li>
</ul>}

  {ul>li.b$@-*5}
  
{<ul>
  <li class="b5">$1</li>
  <li class="b4">$2</li>
  <li class="b3">$3</li>
  <li class="b2">$4</li>
  <li class="b1">$5</li>
</ul>}

  {ul>li.class$$@-7*5}
  
{<ul>
  <li class="class11">$1</li>
  <li class="class10">$2</li>
  <li class="class09">$3</li>
  <li class="class08">$4</li>
  <li class="class07">$5</li>
</ul>}

  {a{click}+b{here}}
  
{<a href="$1">click</a><b>here</b>}
  
  {a>{click}+b{here}}
  
{<a href="$1">click<b>here</b></a>}

  {(div>dl>(dt+dd)*3)+foobar>p}
  
{<div>
  <dl>
    <dt>$1</dt>
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

  {ul>li.item$$$*6}
  
{<ul>
  <li class="item001">$1</li>
  <li class="item002">$2</li>
  <li class="item003">$3</li>
  <li class="item004">$4</li>
  <li class="item005">$5</li>
  <li class="item006">$6</li>
</ul>}

  {h$[title=item$]{Header $}*3}
  
{<h1 title="item1">Header 1</h1>
<h2 title="item2">Header 2</h2>
<h3 title="item3">Header 3</h3>}

  {!!!4t}
  
{<!DOCTYPE HTML="PUBLIC" -//W3C//DTD HTML 4.01 Transitional//EN="http://www.w3.org/TR/html4/loose.dtd">}
 
  {html>(head>meta[charset=UTF-8]+title{Document})+body}
  
{<html>
  <head>
    <meta charset="UTF-8" />
    <title>Document</title>
  </head>
  <body>$1</body>
</html>}

  {doc}
  
{<html>
  <head>
    <meta charset="UTF-8" />
    <title>${1:Document}</title>
  </head>
  <body>$2</body>
</html>}

  {xsl:stylesheet[version=1.0 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"]}
  
{<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">$1</xsl:stylesheet>}

  {xsl}
  
{<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">$1</xsl:stylesheet>}

  {(choose+)+foobar}
  
{<xml:choose>
  <xsl:when test="$1">$2</xsl:when>
  <xsl:otherwise>$3</xsl:otherwise>
</xml:choose>
<foobar>$4</foobar>}

  {#page>div.logo+ul#navigation>li*5>a{Item $}}
  
{<div id="page">
  <div class="logo">$1</div>
  <ul id="navigation">
    <li><a href="$2">Item 1</a></li>
    <li><a href="$3">Item 2</a></li>
    <li><a href="$4">Item 3</a></li>
    <li><a href="$5">Item 4</a></li>
    <li><a href="$6">Item 5</a></li>
  </ul>
</div>}

  {nav#menuSystem.navMenu.isOpen>div#hotelLogo>div.navMenuIcon.logoIcon+div#arrowPointer+ul#navMenuMain>li.navMenuItem.navMenuItem$$$*10>div.navMenuIcon{Item $}+a{Item $}}
  
{<nav id="menuSystem" class="isOpen navMenu">
  <div id="hotelLogo">
    <div class="logoIcon navMenuIcon">$1</div>
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

  {a{{|foobar}}}
  
{<a href="$1">${2:foobar}</a>}

  {lorem10}
  
{}

} {
  
  if {[catch { parse_emmet $str } actual]} {
    puts "ERROR: "
    puts $str
    puts $::emmet_errstr
    puts $::emmet_errmsg
    puts "rc: $actual"
    puts "$::errorInfo"
    exit 1
  }
  
  if {$expect ne $actual} {
    puts "-------------------"
    puts "ERROR:  $str\n"
    puts "Actual ([string length $actual]):\n($actual)\n"
    puts "Expect ([string length $expect]):\n($expect)"
    incr fail_cnt
  }
  
}

if {$fail_cnt == 0} {
  puts "\nPASSED!"
} else {
  puts "\nFAILED!"
}
