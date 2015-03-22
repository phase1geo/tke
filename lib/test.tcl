set auto_path [list [pwd] {*}$auto_path]

package require -exact ctext 5.0

source diff.tcl

# Create the UI
pack [ctext .t -linemap 1 -linemap_minwidth 2 -diff_mode 1 -wrap none] -fill both -expand yes

# Insert content
if {![catch { open {| hg cat -r 499 api.tcl} r } rc]} {
  .t insert end [read $rc]
  close $rc
}

# Insert the unified diff information into the text widget
diff::parse_unified_diff .t "hg diff -r 495 -r 499 api.tcl"
