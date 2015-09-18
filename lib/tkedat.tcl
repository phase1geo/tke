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
# Name:    tkedat.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    08/08/2013
# Brief:   Namespace for reading .tkedat files.
######################################################################

namespace eval tkedat {

  source [file join $::tke_dir lib ns.tcl]

  variable bcount 0

  ######################################################################
  # Counts the number of curly brackets found in the given string.
  proc bracket_count {line line_num start_col} {

    variable bcount

    while {[regexp -indices -start $start_col {([\{\}])(.*)$} $line -> char]} {
      set start [lindex $char 0]
      if {![regexp {(\\+)$} [string range $line 0 [expr $start - 1]] -> escapes] || ([expr [string length $escapes] % 2] == 0)} {
        if {[string index $line $start] eq "\{"} {
          incr bcount
        } else {
          if {$bcount == 0} {
            return -code error "Bad tkedat format (line: $line_num, col: $start)"
          }
          incr bcount -1
        }
      }
      set start_col [expr $start + 1]
    }

    return $bcount

  }

  ######################################################################
  # Reads the given tkedat file, stripping/storing comments and verifying
  # that no Tcl commands are called.
  proc read {fname {include_comments 1}} {

    set contents ""
    
    # Open the file for reading and return an error if we have an issue
    if {[catch { open $fname r } rc]} {
      return -code error [msgcat::mc "Unable to open %s for reading" $fname]
    }
    
    # Read the file contents
    set contents [::read $rc]  
    close $rc
    
    return [parse $contents $include_comments]
    
  }
  
  ######################################################################
  # Parses the given string for tkedat formatted text.
  proc parse {str {include_comments 1}} {

    array set contents [list]
    
    set comments [list]
    set value_ip 0
    set linenum  1
 
    foreach line [split $str \n] {
 
      if {!$value_ip && [regexp {^\s*#(.*)$} $line -> comment]} {
 
        lappend comments $comment
 
      } elseif {!$value_ip && [regexp -indices {^\s*(\{[^\}]*\}|\S+)\s+(\{.*)$} $line -> key value]} {

        set key [string map {\{ {} \} {}} [string range $line {*}$key]]
 
        if {[bracket_count $line $linenum [lindex $value 0]] == 0} {
        	set contents($key) [string range [string trim [string range $line {*}$value]] 1 end-1]
          if {[regexp {\[.*\]} $contents($key)]} {
            unset contents($key)
          } elseif {$include_comments} {
            set contents($key,comment) $comments
          }
          set comments [list]
        } else {
        	set contents($key) [string range [string range $line {*}$value] 1 end]
          set value_ip 1
        }

      } elseif {!$value_ip && [regexp {^\s*(\{[^\}]*\}|\S+)\s+(\S+)$} $line -> key value]} {

        set key [string map {\{ {} \} {}} $key]
        set contents($key) [string trim $value]
 
        if {[regexp {\[.*\]} $contents($key)]} {
          unset contents($key)
        } elseif {$include_comments} {
          set contents($key,comment) $comments
        }
        set comments [list]
 
      } elseif {$value_ip} {
 
        if {[bracket_count $line $linenum 0] == 0} {
          append contents($key) " [string range [string trim $line] 0 end-1]"
          if {[regexp {\[.*\]} $contents($key)]} {
            unset contents($key)
          } elseif {$include_comments} {
            set contents($key,comment) $comments
          }
          set comments [list]
          set value_ip 0
        } else {
         	if {$include_comments} {
            append contents($key) "$line\n"
          } else {
            append contents($key) " [string trim $line]"
          }
        }

      }

      incr linenum

    }

    return [array get contents]

  }

  ######################################################################
  # Writes the given array to the given tkedat file, adding the comments
  # back to the file.
  proc write {fname contents {include_comments 1}} {

    if {![catch { open $fname w } rc]} {

      array set content $contents

      foreach name [lsort [array names content]] {
        if {![regexp {,comment$} $name]} {
          if {$include_comments} {
            if {[info exists content($name,comment)]} {
              foreach comment $content($name,comment) {
                puts $rc "#$comment"
              }
            }
            puts $rc "\n{$name} {$content($name)}\n"
          } else {
            puts $rc "{$name} {$content($name)}"
          }
        }
      }

      close $rc

    } else {

      return -code error [msgcat::mc "Unable to open %s for writing" $fname]

    }

  }

}
