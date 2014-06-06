# Package index file for the embeddable TKE editor package

package ifneeded embed_tke 1.0 \
  "namespace eval embed_tke { proc DIR {} {return [list $dir]} }; source [file join $dir lib embed_tke.tcl]"
