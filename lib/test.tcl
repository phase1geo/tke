lappend auto_path [file join [pwd] tkcon]
lappend auto_path [file join [pwd] ctext]

package require tkcon
package require ctext

source "edit.tcl"
source "select.tcl"

ttk::frame .f
ctext .f.t -xscrollcommand [list .f.hb set] -yscrollcommand [list .f.vb set]
ttk::scrollbar .f.vb -orient vertical   -command [list .f.t yview]
ttk::scrollbar .f.hb -orient horizontal -command [list .f.t xview]

select::add .f.t .f.sb

grid rowconfigure    .f 0 -weight 1
grid columnconfigure .f 0 -weight 1
grid .f.t  -row 0 -column 0 -sticky news
grid .f.vb -row 0 -column 1 -sticky ns
grid .f.hb -row 1 -column 0 -sticky ew
grid .f.sb -row 0 -column 2 -sticky ns -rowspan 2

grid remove .f.sb

pack .f -fill both -expand yes

bind all <Control-m> [list select::set_select_mode .f.t.t 1]

.f.t insert end "This is some test text to use for selections."

ttk::style theme use clam

tkcon show
