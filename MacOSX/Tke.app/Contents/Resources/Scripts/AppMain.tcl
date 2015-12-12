# Remove AppMain.tcl if it is the first argument
if {[info script] eq [lindex $argv 0]} {
  set argv [lrange $argv 1 end]
  incr argc -1
}

# Remove the -psn option, if present
if {[string first "-psn" [lindex $argv 0]] == 0} {
  set argv [lrange $argv 1 end]
  incr argc -1
}

# Avoid populating the sidebar on startup
lappend argv "-nosb"
incr argc

if {[catch { source [file join [file dirname $argv0] tke lib tke.tcl] }]} {
  puts $errorInfo
}
