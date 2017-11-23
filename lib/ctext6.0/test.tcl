lappend auto_path [pwd]

package require ctext 6.0

set auto_separate 1

pack [ctext .t -matchaudit 1 -wrap none -matchchar 1 -xscrollcommand {.hb set} -yscrollcommand {.vb set}] \
  -fill both -expand yes
ttk::scrollbar .vb -orient vertical   -command {.t yview}
ttk::scrollbar .hb -orient horizontal -command {.t xview}

ttk::frame .bf
pack [ttk::button .bf.undo -text "Undo" -command {
  ctext::undo .t
  focus .t.t
} -state disabled] -side left -padx 2 -pady 2
pack [ttk::button .bf.redo -text "Redo" -command {
  ctext::redo .t
  focus .t.t
} -state disabled] -side left -padx 2 -pady 2
pack [ttk::checkbutton .bf.auto -text "Auto-separate" -variable auto_separate -command {
  .t configure -autoseparators $auto_separate
}] -side right -padx 2 -pady 2

bind .t <<Modified>> {
  if {[.t edit undoable]} {
    .bf.undo configure -state normal
  } else {
    .bf.undo configure -state disabled
  }
  if {[.t edit redoable]} {
    .bf.redo configure -state normal
  } else {
    .bf.redo configure -state disabled
  }
}

grid rowconfigure . 0 -weight 1
grid columnconfigure . 0 -weight 1
grid .t  -row 0 -column 0 -sticky news
grid .vb -row 0 -column 1 -sticky ns
grid .hb -row 1 -column 0 -sticky ew
grid .bf -row 2 -column 0 -sticky ew -columnspan 2

# Initialize the ctext widget
ctext::initialize .t

ctext::addHighlightClass    .t keywords "red"
ctext::addHighlightKeywords .t {proc set variable puts for while if expr return namespace incr list lreplace lindex linsert lassign lset lappend string append foreach switch default break continue llength upvar uplevel after source file package event} class keywords
# ctext::setContextPatterns   .t bcomment comment "" {{{/\*} {\*/}}} "grey"
ctext::setContextPatterns   .t lcomment comment "" {{{^\s*#} {$}} {{;#} {$}}} "blue"
ctext::setBrackets          .t "" {curly square paren double} "green"

# Create a gutter
.t gutter create foo {a {-symbol a -fg red} b {-symbol b -fg green}}
.t gutter create bar {c {-symbol c -fg orange} d {-symbol d -fg purple}}

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

# Populate the gutter
.t gutter set foo {a {1 3 5 7 9 11 13 30 38} b {2 4 6 31 32}}
.t gutter set bar {c {1 5 10 15 20 25 30} d {4 8 12 16 21 24}}
