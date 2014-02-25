if {[string first "-psn" [lindex $argv 0]] == 0} { set argv [lrange $argv 1 end]}

# Avoid populating the sidebar on startup
set argv [concat "-nosb" $argv]
incr argc

if [catch {source [file join [file dirname $argv0] lib tke.tcl]}] { puts $errorInfo}
