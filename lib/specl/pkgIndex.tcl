#
# Tcl package index file
#
package ifneeded specl 2.0 [list apply { dir {
  namespace eval specl [list proc DIR {} [list return $dir]]
  source [file join $dir lib specl.tcl]
}} $dir]

