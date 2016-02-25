# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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
# Name:    emmet.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    02/24/2016
# Brief:   Namespace containing Emmet-related functionality.
######################################################################

source [file join $::tke_dir lib emmet_parser.tcl]

namespace eval emmet {

  source [file join $::tke_dir lib ns.tcl]
  
  array set data {
    tag {(.*?)(<\/?[\w:-]+(?:\s+[\w:-]+(?:\s*=\s*(?:(?:".*?")|(?:'.*?')|[^>\s]+))?)*\s*(\/?)>)}
  }

  ######################################################################
  # Returns a three element list containing the snippet text, starting and ending
  # position of that text.
  proc get_snippet_text_pos {} {
    
    variable data
    
    # Get the current text widget
    set txt [[ns gui]::current_txt {}]

    # Get the index of the caret
    lassign [split [$txt index insert] .] row curr_col

    # Get the default starting and ending columns
    set startcol [lindex [split [$txt index "insert linestart"] .] 1]
    set endcol   [lindex [split [$txt index "insert lineend"]   .] 1]

    # Get the current line
    set str [$txt get "insert linestart" "insert lineend"]

    # Move backward through the string, searching for a non-snippet character
    set col 0
    while {[regexp -start $col -- $data(tag) $str match pre tag]} {
      if {[expr $col + [string length $match]] < $curr_col} {
        incr col [string length $match]
      } elseif {[expr $col + [string length $pre]] >= $curr_col} {
        set startcol $col
        set endcol   [expr $col + [string length $pre]]
        break
      } else {
        return [list "" $row.$startcol $row.$endcol]
      }
    }
    
    return [list [$txt get $row.$startcol $row.$endcol] $row.$startcol $row.$endcol 1]

  }

  ######################################################################
  # Parses the current Emmet snippet found in the current editing buffer.
  # Returns a three element list containing the generated code, the
  # starting index of the snippet and the ending index of the snippet.
  proc parse {} {

    # Find the snippet text
    lassign [get_snippet_text_pos] str startpos endpos

    return [list [parse_emmet $str] $startpos $endpos]

  }

}

