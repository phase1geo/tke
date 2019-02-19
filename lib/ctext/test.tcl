lappend auto_path [file join .. tkcon]

source ctext.tcl

package require tkcon

pack [ctext .t -warnwidth 60 -wrap word] -fill both -expand yes
pack [ttk::button .b1 -text "Show" -command {
  ctext::undo_display .t undo
  puts ""
  focus .t.t
}]
pack [ttk::button .b2 -text "Undo" -command {
  ctext::undo .t
  focus .t.t
}]
pack [ttk::button .b3 -text "Redo" -command {
  ctext::redo .t
  focus .t.t
}]

bind . <Control-c> [list event generate .t <<Copy>>]
bind . <Control-x> [list event generate .t <<Cut>>]
bind . <Control-v> [list event generate .t <<Paste>>]
bind . <Control-z> [list event generate .t <<Undo>>]
bind . <Control-Z> [list event generate .t <<Redo>>]

.t insert end "This is good\nThis is bad"
.t cursor add 1.8 2.8
.t insert insert "not "

ctext::setIndentation .t {} {\{} indent
ctext::setIndentation .t {} {\}} unindent

tkcon show
