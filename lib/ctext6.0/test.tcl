lappend auto_path [pwd]

package require ctext 6.0

pack [ctext .t -matchaudit 1 -xscrollcommand {.hb set} -yscrollcommand {.vb set}] -fill both -expand yes
ttk::scrollbar .vb -orient vertical   -command {.t yview}
ttk::scrollbar .hb -orient horizontal -command {.t xview}

grid rowconfigure . 0 -weight 1
grid columnconfigure . 0 -weight 1
grid .t  -row 0 -column 0 -sticky news
grid .vb -row 0 -column 1 -sticky ns
grid .hb -row 1 -column 0 -sticky ew

# Initialize the ctext widget
ctext::initialize .t

ctext::addHighlightClass    .t keywords "red"
ctext::addHighlightKeywords .t {proc set variable puts for while if expr return namespace incr list lreplace lindex linsert lassign lset lappend string append foreach switch default break continue llength upvar uplevel after source file package event} class keywords
ctext::addHighlightKeywords .t {proc set variable puts for while if expr return namespace incr list lreplace lindex linsert lassign lset lappend string append foreach switch default break continue llength upvar uplevel after source file package event} class keywords
# ctext::setContextPatterns   .t bcomment comment "" {{{/\*} {\*/}}} "grey"
ctext::setContextPatterns   .t lcomment comment "" {{{^\s*#} {$}} {{;#} {$}}} "grey"
ctext::setBrackets          .t "" {curly square paren double} "green"

source model.tcl

proc show_serial {} {
  puts [tsv::get serial .t]
}

proc show_tree {} {
  model::load_all .t
  model::debug_show_tree
  model::destroy .t
}

set f [open ctext.tcl r]
set contents [read $f]
close $f
puts [time { .t insert end $contents }]
