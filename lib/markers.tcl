######################################################################
# Name:    markers.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    08/05/2013
# Brief:   Namespace to support markers.
######################################################################

namespace eval markers {

  source [file join $::tke_dir lib ns.tcl]
    
  variable curr_marker 0
  
  array set markers {}
  
  ######################################################################
  # Adds a new marker for the given index.  Returns 1 if the marker
  # was added; otherwise, returns 0.
  proc add {txt tag {name ""}} {
    
    variable markers
    variable curr_marker
    
    # If the name wasn't specified, ask the user
    if {($name eq "") && ![gui::user_response_get [msgcat::mc "Marker name:"] name]} {
      return 0
    }
    
    # Add the marker
    if {$name eq ""} {
      set markers($txt,Marker-[incr curr_marker]) $tag
    } else {
      set markers($txt,$name) $tag
    }
    
    return 1
  
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
  # Deletes the marker of the given tag, if it exists.
  proc delete_by_tag {txt tag} {
    
    variable markers
    
    foreach {name t} [array get markers $txt,*] {
      if {$t eq $tag} {
        unset markers($name)
      }
    }
    
  }
  
  ######################################################################
  # Deletes all markers at the given line.
  proc delete_by_line {txt line} {
    
    variable markers
    
    foreach {name tag} [array get markers $txt,*] {
      if {[lsearch [$txt tag ranges $tag] $line.0] != -1} {
        unset markers($name)
      }
    }
    
  }
  
  ######################################################################
  # Returns all of the marker names.
  proc get_all_names {txt} {
    
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
    
    if {[info exists markers($txt,$name)]} {
      return [lindex [$txt tag ranges $markers($txt,$name)] 0]
    } else {
      return ""
    }
    
  }
  
  ######################################################################
  # Returns all of the names for the given index.
  proc get_names {txt line} {
    
    variable markers
    
    set names [list]
    foreach {name index} [array get markers] {
      if {[lindex [split $index .] 0] == $line} {
        lappend names $name
      }
    }
    
    return $names
    
  }
  
}
