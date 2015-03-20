set auto_path [list [pwd] {*}$auto_path]

package require -exact ctext 5.0

# Create the UI
pack [ctext .t -linemap 1 -linemap_minwidth 2 -diff_mode 1 -wrap none]

# Insert content
if {![catch { open [file join api.tcl] r } rc]} {
  .t insert end [read $rc]
  close $rc
}

.t tag add diff:A:S:1 1.0 3.end
.t tag add diff:A:D:4 4.0 5.end
.t tag add diff:A:S:4 6.0 end

.t tag add diff:B:S:1  1.0 10.end
.t tag add diff:B:D:11 11.0 14.end
.t tag add diff:B:S:11 15.0 end
