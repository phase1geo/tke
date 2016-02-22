set tke_dir [file normalize [file join [pwd] ..]]

source emmet_parser.tcl

foreach str [list "nav>ul>li" \
                  "div+p+bq" \
                  "div+div>p>span+em^bq" \
                  "div+div>p>span+em^^bq" \
                  "div>(header>ul>li>a)+footer>p" \
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
                  ] {
  puts "str: $str\n"
  puts [parse_emmet $str]
  puts "-------------------"
}
