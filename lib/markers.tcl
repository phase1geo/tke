# TKE - Advanced Programmer's Editor
# Copyright (C) 2014  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

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
  # Adds a new marker for the given index.  Returns 1 if the marker was
  # added; otherwise, returns 0.
  proc add {txt tag {name ""}} {

    variable markers
    variable curr_marker

    # If the name wasn't specified, ask the user
    if {($name eq "") && ![gui::get_user_response [msgcat::mc "Marker name:"] name]} {
      return 0
    }

    # Add the marker
    if {$name eq ""} {
      set name "Marker-[incr curr_marker]"
    } elseif {[regexp {^Marker-(\d+)$} $name -> id] && ($curr_marker <= $id)} {
      set curr_marker $id
    }

    # Set the marker
    set markers($txt,$name) $tag

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
  proc get_markers {{txt "*"}} {

    variable markers

    set data [list]

    # Get the list of all names
    foreach key [array names markers $txt,*] {
      if {[llength [set ranges [$txt tag ranges $markers($key)]]] > 0} {
        set name [join [lassign [split $key ,] txt] ,]
        lappend data $name $txt [lindex $ranges 0]
      }
    }

    return $data

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

  ######################################################################
  # Returns the marked lines.
  proc get_positions {txt} {

    variable markers

    set pos   [list]
    set lines [$txt count -lines 1.0 end]
    set color [[ns theme]::get_value syntax cursor]

    foreach {name tag} [array get markers $txt,*] {
      set start_line [lindex [$txt tag ranges $tag] 0]
      lappend pos [expr $start_line / $lines] [expr $start_line / $lines] $color
    }

    return $pos

  }

  ######################################################################
  # Returns true if one or more markers exist in the specified text widget.
  proc exist {txt} {

    variable markers

    return [expr [llength [array names markers $txt,*]] > 0]

  }

}
