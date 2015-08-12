set tke_dir   [file join [pwd] ..]
set auto_path [list [pwd] {*}$auto_path]

package require -exact ctext 5.0

source utils.tcl
source diff.tcl

# Create the UI
grid rowconfigure    . 0 -weight 1
grid columnconfigure . 0 -weight 1
grid [ctext .t -linemap 1 -linemap_minwidth 2 -diff_mode 1 -wrap none] -row 0 -column 0 -sticky news
grid [diff::map .m .t] -row 0 -column 1 -sticky ns

# Insert content
if {![catch { open {| hg cat -r 499 api.tcl} r } rc]} {
  .t insert end [read $rc]
  close $rc
}

# Insert the unified diff information into the text widget
diff::parse_unified_diff .t "hg diff -r 1157 -r 1188 sidebar.tcl"
# diff::parse_unified_diff .t "hg diff -r 495 -r 499 api.tcl"
