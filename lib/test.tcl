set tke_dir [file normalize [file join [pwd] ..]]

source emmet_parser.tcl

foreach str [list "nav>ul>li" \
                  "div+p+bq" \
                  "div+div>p>span+em^bq" \
                  "div+div>p>span+em^^bq" \
                  "div>(header>ul>li*2>a)+footer>p" \
                  "a{Click me}" \
                  "div#header" \
                  "div.title" \
                  "p.class1.class2.class3" \
                  "form#search.wide" \
                  "p\[title=\"Hello World\"\]" \
                  "td\[rowspan=2 colspan=3 title\]" \
                  "p>{Click }+a{here}+{ to continue}" \
                  "link" \
                  "link\[rel=prefetch title=\"Hello world\"\]" \
                  ".wrap>.content" \
                  "em>.info" \
                  "ul>.item" \
                  "table>#row>\[colspan=2\]" \
                  "\[a='value' b=\"value2\"\]" \
                  "ul>li.b$*5" \
                  "ul>li.b$@4*5" \
                  "ul>li.b$@-*5" \
                  "ul>li.class$$@-3*5" \
                  "a{click}+b{here}" \
                  "a>{click}+b{here}" \
                  "(div>dl>(dt+dd)*3)+foobar>p" \
                  "ul>li.item$$$*6" \
                  "h$\[title=item$\]{Header $}*3" \
                  "!!!4t" \
                  "html>(head>meta\[charset=UTF-8\]+title{Document})+body" \
                  "doc" \
                  "xsl" \
                  ] {
  puts "str: $str\n"
  puts [parse_emmet $str]
  puts "-------------------"
}
