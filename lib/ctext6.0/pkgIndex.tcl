package ifneeded ctext 6.0 \
  "namespace eval ctext { proc DIR {} { return [list $dir] } }; \
   source [list [file join $dir ctext.tcl]]"

