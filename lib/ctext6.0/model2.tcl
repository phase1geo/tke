# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2017  Trevor Williams (phase1geo@gmail.com)
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
# Name:    model.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/20/2017
# Brief:   Data model for a syntax buffer.  Contains marker positions that would otherwise
#          be stored within the text widget as tags, but is much more performant.
#          This code will be executed by all threads and manipulates a data structure
#          that will be shared in its nature.
######################################################################

package require Thread

# TBD - We need to enhance this
load -lazy ./model.so

namespace eval model {

  array set data {}

  ######################################################################
  # Creates a new tree for the given window
  proc create {win} {

    variable data

    set data($win,model) [model]
    set data($win,debug) 0

    # Add the escape type
    add_type "escape" 0

  }

  ######################################################################
  # Removes the memory associated with the model.
  proc destroy {win} {

    variable data

    # Destroy the tree
    $data($win,model) -delete

    # Clear the rest of the memory
    array unset data $win,*

  }

  ######################################################################
  # Sets the debug variable and save it for future purposes
  proc set_debug {win value} {

    variable data

    set data($win,debug) $value

  }

  ######################################################################
  # Displays the serial list to standard output.
  proc debug_show_serial {win {msg "Serial"}} {

    variable data

    utils::log "$msg:"
    utils::log [$data($win,model) showserial]

  }

  ######################################################################
  # Displays the specified tree to standard output.
  proc debug_show_tree {win {msg "Tree"}} {

    variable data

    utils::log "$msg:"
    utils::log [$data($win,model) showtree]

  }

  ######################################################################
  # Adds the given types to the model.
  proc add_types {win types comstr {tagname ""}} {

    variable data

    foreach type $types {
      add_type $type $comstr
      if {$tagname ne ""} {
        set data($win,tags,$type) $tagname
      }
    }

  }

  ######################################################################
  # Returns the tagname associated with the given type.
  proc get_tagname {win type} {

    variable data

    return $data($win,tags,$type)

  }

  ######################################################################
  # Returns true if the character at the given index is escaped.
  proc is_escaped {win tindex} {

    variable data

    return [$data($win,model) isescaped $tindex]

  }

  ######################################################################
  # Inserts the given items into the tree.
  proc insert {win ranges} {

    variable data

    $data($win,model) insert $ranges

  }

  ######################################################################
  # Deletes the given text range and updates the model.
  proc delete {win ranges} {

    variable data

    $data($win,model) delete $ranges

  }

  ######################################################################
  # Update the model with the replacement information.
  proc replace {win ranges} {

    variable data

    $data($win,model) replace $ranges

  }

  ######################################################################
  # Temporarily merge the current serial list with the tags
  # so that we can figure out which contexts to serially highlight
  proc get_context_tags {win linestart lineend ptags} {

    variable data

    upvar $ptags tags

    set tags [$data($win,model) getcontexts $linestart $lineend [lsort -dictionary -index 2 $tags]]

  }

  ######################################################################
  # Updates the model, inserting the given parsed elements prior to rebuilding
  # the model tree.
  proc update {win linestart lineend elements} {

    variable data

    utils::log "In update, linestart: $linestart, lineend: $lineend, elements: $elements"

    return [$data($win,model) update $linestart $lineend $elements]
    
  }

  ######################################################################
  # Gets an index list of all nodes in the tree that are not matched.
  proc get_mismatched {win} {

    variable data
    
    return [$data($win,model) mismatched]

  }

  ######################################################################
  # Returns the depth of the given node.
  proc get_depth {win tindex {type ""}} {

    variable data

    return [$data($win,model) depth $tindex $type]

  }

  ######################################################################
  # Returns 1 if the given text widget index has a matching character
  # the tindex parameter will be populated with the matching character
  # text widget index.  If the character does not contain a match, a value
  # of 0 will be returned.
  proc get_match_char {win ptindex} {

    variable data

    upvar $ptindex tindex

    return [expr {[set tindex [$data($win,model) matchindex $tindex]] ne ""}]

  }

}
