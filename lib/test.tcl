set auto_path [list [pwd] {*}$auto_path]

package require -exact ctext 5.0

# Create the UI
pack [ctext .t -linemap 1 -linemap_minwidth 4 -diff_mode 1 -wrap none]

# Insert content
if {![catch { open [file join api.tcl] r } rc]} {
  .t insert end [read $rc]
  close $rc
}

.t tag add diff:A:1 1.0 3.end
.t tag add diff:A:4 6.0 end
.t tag add diff:B:1 1.0 end
