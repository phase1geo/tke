set tke_dir  [file normalize [file join [pwd] ..]]
set fail_cnt 0

source emmet_parser.tcl

foreach {str expect} {
  
  {nav>ul>li}
  
{<nav>
  <ul>
    <li></li>
  </ul>
</nav>}

  {div+p+bq}
  
{<div></div>
<p></p>
<blockquote></blockquote>}

  {div+div>p>span+em^bq}
  
{<div></div>
<div>
  <p>
    <span></span>
    <em></em>
  </p>
  <blockquote></blockquote>
</div>}

  {div+div>p>span+em^^bq}
  
{<div></div>
<div>
  <p>
    <span></span>
    <em></em>
  </p>
</div>
<blockquote></blockquote>}

  {div>(header>ul>li*2>a)+footer>p}
  
{<div>
  <header>
    <ul>
      <li>
        <a href=""></a>
      </li>
      <li>
        <a href=""></a>
      </li>
    </ul>
  </header>
  <footer>
    <p></p>
  </footer>
</div>}

  {a{Click me}}
  
{<a href="">Click me</a>}

  {div#header}
  
{<div id="header"></div>}

  {div.title}
  
{<div class="title"></div>}

  {p.class1.class2.class3}
  
{<p class="class3 class2 class1"></p>}

  {form#search.wide}
 
{<form id="search" class="wide" action=""></form>}

  {p[title="Hello World"]}
  
{<p title="Hello World"></p>}

  {td[rowspan=2 colspan=3 title]}
  
{<td rowspan="2" title="" colspan="3"></td>}

  {p>{Click }+a{here}+{ to continue}}
  
{<p>
  Click 
  <a href="">here</a>
   to continue
</p>}

  {link}
  
{<link href="" rel="stylesheet" />}

  {link[rel=prefetch title="Hello world"]}
  
{<link href="" title="Hello world" rel="prefetch" />}

  {.wrap>.content}
  
{<div class="wrap">
  <div class="content"></div>
</div>}

  {em>.info}
  
{<em>
  <span class="info"></span>
</em>}

  {ul>.item}
  
{<ul>
  <li class="item"></li>
</ul>}

  {table>#row>[colspan=2]}
  
{<table>
  <tr id="row">
    <td colspan="2"></td>
  </tr>
</table>}

  {[a='value' b="value2"]}
  
{<div a="value" b="value2"></div>}

  {ul>li.b$*5}
  
{<ul>
  <li class="b1"></li>
  <li class="b2"></li>
  <li class="b3"></li>
  <li class="b4"></li>
  <li class="b5"></li>
</ul>}

  {ul>li.b$@4*5}
  
{<ul>
  <li class="b4"></li>
  <li class="b5"></li>
  <li class="b6"></li>
  <li class="b7"></li>
  <li class="b8"></li>
</ul>}

  {ul>li.b$@-*5}
  
{<ul>
  <li class="b5"></li>
  <li class="b4"></li>
  <li class="b3"></li>
  <li class="b2"></li>
  <li class="b1"></li>
</ul>}

  {ul>li.class$$@-3*5}
  
{<ul>
  <li class="class07"></li>
  <li class="class06"></li>
  <li class="class05"></li>
  <li class="class04"></li>
  <li class="class03"></li>
</ul>}

  {a{click}+b{here}}
  
{<a href="">click</a>
<b>here</b>}
  
  {a>{click}+b{here}}
  
{<a href="">
  click
  <b>here</b>
</a>}

  {(div>dl>(dt+dd)*3)+foobar>p}
  
{<div>
  <dl>
    <dt></dt>
    <dd></dd>
    <dt></dt>
    <dd></dd>
    <dt></dt>
    <dd></dd>
  </dl>
</div>
<foobar>
  <p></p>
</foobar>}

  {ul>li.item$$$*6}
  
{<ul>
  <li class="item001"></li>
  <li class="item002"></li>
  <li class="item003"></li>
  <li class="item004"></li>
  <li class="item005"></li>
  <li class="item006"></li>
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
  <body></body>
</html>}

  {doc}
  
{<html>
  <head>
    <meta charset="UTF-8" />
    <title>Document</title>
  </head>
  <body></body>
</html>}

  {xsl:stylesheet[version=1.0 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"]}
  
{<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"></xsl:stylesheet>}

  {xsl}
  
{<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"></xsl:stylesheet>}

  {(choose+)+foobar}
  
{<xml:choose>
  <xsl:when test=""></xsl:when>
  <xsl:otherwise></xsl:otherwise>
</xml:choose>
<foobar></foobar>}

} {
  
  set actual [parse_emmet $str]
  
  # puts "str: $str\n"
  # puts $generated
  
  if {$expect ne $actual} {
    puts "-------------------"
    puts "ERROR:  $str\n"
    puts "Actual ([string length $actual]):\n([string map {{ } {_}} $actual])\n"
    puts "Expect ([string length $expect]):\n([string map {{ } {_}} $expect])"
    incr fail_cnt
  }
  
}

if {$fail_cnt == 0} {
  puts "\nPASSED!"
} else {
  puts "\nFAILED!"
}
