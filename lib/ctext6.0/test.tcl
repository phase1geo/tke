lappend auto_path [pwd]

package require ctext 6.0

pack [ctext .t -matchaudit 1 -wrap none -matchchar 1 -xscrollcommand {.hb set} -yscrollcommand {.vb set}] \
  -fill both -expand yes
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
# ctext::setContextPatterns   .t bcomment comment "" {{{/\*} {\*/}}} "grey"
ctext::setContextPatterns   .t lcomment comment "" {{{^\s*#} {$}} {{;#} {$}}} "blue"
ctext::setBrackets          .t "" {curly square paren double} "green"

proc set_debug {value} {
  thread::send -async $ctext::model_tid [list model::set_debug .t $value]
}

proc show_serial {} {
  thread::send -async $ctext::model_tid [list model::debug_show_serial .t]
}

proc show_tree {} {
  thread::send -async $ctext::model_tid [list model::debug_show_tree .t]
}

# set_debug 1

# set f [open ctext.tcl r]
set f [open utils.tcl r]
# set f [open ../menus.tcl r]
set contents [read $f]
close $f
puts [time { .t insert end $contents }]
