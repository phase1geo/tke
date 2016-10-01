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

if {[file exists [lindex $argv 0]]} {

  set argv [lassign $argv argv0]

  # Execute the given script
  if {[catch { source $argv0 }]} {
    puts $errorInfo
  }

} else {

  # Avoid populating the sidebar on startup
  lappend argv "-nosb"
  incr argc

  # Execute tke.tcl
  if {[catch { source [file join [file dirname $argv0] tke lib tke.tcl] }]} {
    puts $errorInfo
  }

}
