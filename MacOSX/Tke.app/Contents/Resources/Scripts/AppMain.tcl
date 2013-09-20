if {[string first "-psn" [lindex $argv 0]] == 0} { set argv [lrange $argv 1 end]}

# This line should be removed when using the actual application (i.e., it's for debug purposes only)
console show

if [catch {source [file join [file dirname [info script]] tke tke.tcl]}] { puts $errorInfo}
