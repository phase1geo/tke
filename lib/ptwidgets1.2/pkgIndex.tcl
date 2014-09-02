#
# Tcl package index file
#
package ifneeded tokenentry 1.2 [list apply { dir {
	namespace eval tokenentry [list proc DIR {} [list return $dir]]
	source [file join $dir library tokenentry.tcl]
}} $dir]

package ifneeded tokensearch 1.2 [list apply { dir {
  namespace eval tokensearch [list proc DIR {} [list return $dir]]
  source [file join $dir library tokensearch.tcl]
}} $dir]

package ifneeded wmarkentry 1.2 [list apply { dir {
  namespace eval wmarkentry [list proc DIR {} [list return $dir]]
  source [file join $dir library wmarkentry.tcl]
}} $dir]

package ifneeded toggleswitch 1.2 [list apply { dir {
	namespace eval toggleswitch [list proc DIR {} [list return $dir]]
	source [file join $dir library toggleswitch.tcl]
}} $dir]

package ifneeded carousel 1.2 [list apply { dir {
  namespace eval carousel [list proc DIR {} [list return $dir]]
  source [file join $dir library carousel.tcl]
}} $dir]

package ifneeded timeline 1.2 [list apply { dir {
  namespace eval timeline [list proc DIR {} [list return $dir]]
  source [file join $dir library timeline.tcl]
}} $dir]

package ifneeded specl 1.2 [list apply { dir {
  namespace eval specl [list proc DIR {} [list return $dir]]
  source [file join $dir library specl.tcl]
}} $dir]

package ifneeded tabbar 1.2 [list apply { dir {
  namespace eval tabbar [list proc DIR {} [list return $dir]]
  source [file join $dir library tabbar.tcl]
}} $dir]
