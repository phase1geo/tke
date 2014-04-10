#
# Tcl package index file
#
package ifneeded tokenentry  1.2 \
  "namespace eval tokenentry { proc DIR {} {return [list $dir]} }; source [file join $dir library tokenentry.tcl]"
package ifneeded tokensearch 1.2 \
  "namespace eval tokensearch { proc DIR {} {return [list $dir]} }; source [file join $dir library tokensearch.tcl]"
package ifneeded wmarkentry 1.2 \
  "namespace eval wmarkentry { proc DIR {} {return [list $dir]} }; source [file join $dir library wmarkentry.tcl]"
package ifneeded toggleswitch 1.2 \
  "namespace eval toggleswitch { proc DIR {} {return [list $dir]} }; source [file join $dir library toggleswitch.tcl]"
package ifneeded carousel 1.2 \
  "namespace eval carousel { proc DIR {} {return [list $dir]} }; source [file join $dir library carousel.tcl]"
package ifneeded timeline 1.2 \
  "namespace eval timeline { proc DIR {} {return [list $dir]} }; source [file join $dir library timeline.tcl]"
package ifneeded specl 1.2 \
  "namespace eval specl { proc DIR {} {return [list $dir]} }; source [file join $dir library specl.tcl]"
package ifneeded tabbar 1.2 \
  "namespace eval tabbar { proc DIR {} {return [list $dir]} }; source [file join $dir library tabbar.tcl]"

