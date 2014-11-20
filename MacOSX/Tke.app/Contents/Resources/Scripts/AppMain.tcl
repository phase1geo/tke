if {[string first "-psn" [lindex $argv 0]] == 0} {
  set argv [lrange $argv 1 end]
}

if {[llength $argv] > 0} {
  
  set argv [lassign $argv argv0]
  if {[catch { source $argv0 }]} {
    puts $errorInfo
  }
  
} else {

  # Avoid populating the sidebar on startup
  set argv [concat "-nosb" $argv]
  incr argc

  if {[catch { source [file join [file dirname $argv0] tke lib tke.tcl] }]} {
    puts $errorInfo
  }
  
}
