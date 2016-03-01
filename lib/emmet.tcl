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
    tag      {(.*)(<\/?[\w:-]+(?:\s+[\w:-]+(?:\s*=\s*(?:(?:".*?")|(?:'.*?')|[^>\s]+))?)*\s*(\/?)>)}
    brackets {(.*?)(\[.*?\]|\{.*?\})}
    space    {(.*?)(\s+)}
  }

  ######################################################################
  # Returns a three element list containing the snippet text, starting and ending
  # position of that text.
  proc get_snippet_text_pos {tid} {
    
    variable data
    
    # Get the current text widget
    set txt [[ns gui]::current_txt $tid]
    
    # Get the current line and column numbers
    lassign [split [$txt index insert] .] line endcol

    # Get the current line
    set str [$txt get "insert linestart" insert]
    
    # Get the prespace of the current line
    regexp {^([ \t]*)} $str -> prespace
    
    # If we have a tag, ignore all text prior to it
    set startcol [expr {[regexp $data(tag) $str match] ? [string length $match] : 0}]
    
    # Gather the positions of any square or curly brackets in the left-over area
    foreach key [list brackets space] {
      set pos($key) [list]
      set col       $startcol
      while {[regexp -start $col -- $data($key) $str match pre]} {
        lappend pos($key) [expr $col + [string length $pre]] [expr $col + [string length $match]]
        set col [lindex $pos($key) end]
      }
    }
    
    # See if there is a space which does not exist within a square or curly brace
    foreach {endpos startpos} [lreverse $pos(space)] {
      if {[expr [lsearch [lsort -integer [concat $pos(brackets) $endpos]] $endpos] % 2] == 0} {
        return [list [string range $str $endpos end] $line.$endpos $line.$endcol $prespace]
      }
    }
    
    return [list [string range $str $startcol end] $line.$startcol $line.$endcol $prespace]

  }

  ######################################################################
  # Parses the current Emmet snippet found in the current editing buffer.
  # Returns a three element list containing the generated code, the
  # starting index of the snippet and the ending index of the snippet.
  proc expand_abbreviation {tid} {

    # Find the snippet text
    lassign [get_snippet_text_pos $tid] str startpos endpos prespace
    
    # Parse the snippet and if no error, insert the resulting string
    if {![catch { ::parse_emmet $str $prespace } str]} {
      [ns snippets]::insert_snippet_into_current $tid $str $startpos $endpos
    }

  }

}

