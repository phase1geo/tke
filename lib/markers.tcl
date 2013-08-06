######################################################################
# Name:    markers.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    08/05/2013
# Brief:   Namespace to support markers.
######################################################################

namespace eval markers {
  
  array set markers {}
  
  ######################################################################
  # Adds a new marker for the given index.
  proc add {txt index {name ""}} {
    
    variable markers
    
    # If the name wasn't specified, ask the user
    if {$name eq ""} {
      set resp ""
      if {![gui::user_response_get "Marker name:" name]} {
        lassign [split $index .] row col
        set name "Line $row, Column $col"
      }
    }
    
    # Add the marker
    set markers($txt,$name) $index
  
  }
  
  ######################################################################
  # Deletes the marker of the given name, if it exists.
  proc delete_by_name {txt name} {
    
    variable markers
    
    if {[info exists markers($txt,$name)]} {
      unset markers($txt,$name)
    }
    
  }
  
  ######################################################################
  # Deletes the marker of the given index, if it exists.
  proc delete_by_index {txt index} {
    
    variable markers
    
    foreach {name i} [array get markers $txt,*] {
      if {$i eq $index} {
        unset markers($name)
      }
    }
    
  }
  
  ######################################################################
  # Returns the marker names.
  proc get_names {txt} {
    
    variable markers
    
    # Figure out the starting character
    set start [expr [string length $txt] + 1]
    
    # Get the list of names
    set names [list]
    foreach name [array names markers $txt,*] {
      lappend names [string range $name $start end]
    }
    
    return [lsort -dictionary $names]
    
  }
  
  ######################################################################
  # Returns the index for the given marker name.
  proc get_index {txt name} {
    
    variable markers
    
    if {[info exists markers($name)]} {
      if {[regexp {^\d+$} $markers($name)]} {
        return $markers($name).0
      } else {
        return $markers($name)
      }
    } else {
      return ""
    }
    
  }
  
}
