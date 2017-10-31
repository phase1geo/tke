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

package require struct::tree
package require Thread

namespace eval model {

  variable serial ""

  ######################################################################
  # Creates a new tree for the given window
  proc create {win} {

    # Create the tree
    ::struct::tree tree

    utils::log "Saving serial, win: $win"

    # Save the serial list in the new shared memory
    save_serial $win

    # Save the tree in the new shared memory
    save_tree $win

  }

  ######################################################################
  # Removes the memory associated with the model.
  proc destroy {win} {

    tsv::unset serial $win

    if {[tsv::exists tree $win]} {
      tsv::unset tree $win
    }

  }

  ######################################################################
  # Retrieves the given tree from shared memory and returns it to the
  # calling procedure.
  proc load_serial {win} {

    variable serial

    # Get the serial list
    set serial [tsv::get serial $win]

  }

  ######################################################################
  # Loads the tree structure from memory.
  proc load_all {win} {

    # Load the serial list
    load_serial

    # Get the tree
    ::struct::tree tree deserialize [tsv::get tree $win]

  }

  ######################################################################
  # Saves the tree back to shared memory.
  proc save_serial {win} {

    variable serial

    puts "Saving serial $win"

    # Save the serial list and tree to shared memory.
    tsv::set serial $win $serial

  }

  ######################################################################
  # Saves the tree to shared memory.
  proc save_tree {win} {

    catch {
      tsv::set tree $win [tree serialize]
      tree destroy
    }

  }

  ######################################################################
  # Outputs the current contents of the tree to standard output.
  proc debug_show {win {msg "Tree"}} {

    ::struct::tree tree deserialize [tsv::get tree $win]

    puts -nonewline "$msg: [tree_string tree root [expr [string length $msg] + 2]]"

    tree destroy

  }

  ######################################################################
  # Displays the given tree in a hierarchical format.
  proc tree_string {node prefix_len} {

    set width 30

    if {($node ne "root") && [tree index $node] > 0} {
      set str [string repeat { } [expr ([tree depth $node] * $width) + $prefix_len]]
    }

    append str [format "%-${width}s" [node_string tree $node]]

    if {[tree isleaf $node]} {
      append str "\n"
    }

    foreach child [tree children $node] {
      append str [tree_string $child $prefix_len]
    }

    return $str

  }

  ######################################################################
  # Displays the specified tree to standard output.
  proc debug_show_tree {{msg "Tree"}} {

    puts -nonewline "$msg: [tree_string root [expr [string length $msg] + 2]]"

  }

  ######################################################################
  # Displays the information for a single node.
  proc debug_show_node {tree node {msg "Node"}} {

    puts "$msg: [node_string $node]"

  }

  ######################################################################
  # Returns a string version of the given node for display purposes.
  proc node_string {tree node} {

    variable current

    if {$node eq "root"} {
      if {$current eq $node} {
        return "(root)*"
      } else {
        return "(root)"
      }
    }

    set left  "??"
    set right "??"
    set type  [tree get $node type]
    set curr  [expr {($node eq $current) ? "*" : ""}]

    if {[tree keyexists $node left]}  { set left  [tree get $node left] }
    if {[tree keyexists $node right]} { set right [tree get $node right] }

    return [format "(%s-%s {%s})%s" [position $left] [position $right] $type $curr]

  }

  ######################################################################
  # Creates an index out of the given position.
  proc index {pos} {

    split $pos .

  }

  ######################################################################
  # Returns the text widget position from the given tree index.
  proc position {index {adjust 0}} {

    if {$adjust != 0} {
      lset index 1 [expr [lindex $index 1] + $adjust]
    }

    join $index .

  }

  ######################################################################
  # Returns true if the character at the given index is escaped.
  proc is_escaped {index} {

    variable serial

    lassign [split $index .] row col

    # We can't escape the first character of a row
    if {($col == 0) || ([set index [find_serial_index [list $row $col]] == 0)} {
      return 0
    }

    # Get the previous character's information
    lassign [lindex $serial [expr $index - 1]] type side prev_index

    # Otherwise, if the previous character is an escape character
    expr {($type eq "escape") && ($prev_index eq [list $row [expr $col - 1]])}

  }

  ######################################################################
  # Compares to index values.  Returns 1 if a is less than b; otherwise,
  # returns 0.
  proc is_less {a b} {

    lassign $a arow acol
    lassign $b brow bcol

    expr {($arow < $brow) || (($arow == $brow) && ($acol < $bcol))}

  }

  ######################################################################
  # Returns true if the given type matches the node.
  proc type_matches {node type} {

    expr {[tree get $node type] eq $type}

  }

  ######################################################################
  # Adjusts all of the model indices based on the inserted text position.
  proc adjust_indices {startpos endpos start_index last_index} {

    variable serial

    # If we are inserting text at the end, there's nothing left to do here
    if {$start_index == $last_index} {
      return
    }

    lassign $startpos srow scol
    lassign $endpos   erow ecol

    set i $start_index
    while {($i < $last_index) && ([lindex $serial $i 2 0] <= $erow)} {
      lset serial $i 2 1 [expr ([lindex $serial $i 2 1] - $scol) + $ecol]
      incr i
    }

    if {$srow != $erow} {
      set line_incr [expr $erow - $srow]
      set i         0
      while {$i < $last_index} {
        lset serial $i 2 0 [expr [lindex $serial $i 2 0] + $line_incr]
        incr i
      }
    }

  }

  ######################################################################
  # Finds the index in the serial list to begin transforming the list.
  proc find_serial_index {index} {

    variable serial

    set len [llength $serial]

    if {($len == 0) || [is_less $index [lindex $serial 0 2]]} {
      return 0
    } elseif {![is_less $index [lindex $serial end 2]]} {
      return $len
    } else {
      set start 0
      set end   $len
      while {($end - $start) > 1} {
        set mid [expr (($end - $start) / 2) + $start]
        if {[is_less $index [lindex $serial $mid 2]]} {
          set end $mid
        } else {
          set start $mid
        }
      }
      return $end
    }

  }

  ######################################################################
  # Inserts the given items into the tree.
  proc insert {win ranges} {

    variable serial 

    # Load the shared information
    load_serial $win

    set last [llength $serial]

    foreach {startpos endpos} $ranges {

      # Find the node to start the insertion
      set start_index [find_serial_index $startpos]
      set end_index   [find_serial_index $endpos]

      # Remove anything found between the two indices
      set serial [lreplace $serial[set serial {}] $start_index $end_index]

      # Adjust the indices
      adjust_indices $startpos $endpos $end_index $last

      set last $start_index

    }

    # Put the tree back into shared memory
    save_serial $win

  }

  ######################################################################
  # Deletes the given text range and updates the model.
  proc delete {win ranges} {

    variable serial

    load_serial $win

    set last [llength $serial]

    foreach {startpos endpos} $ranges {

      # Calculate the indices in the serial list
      set start_index [find_serial_index $startpos]
      set end_index   [find_serial_index $endpos] 

      # Remove items between indices
      set serial [lreplace $serial[set serial {}] $start_index $end_index]

      # Adjust the serial list indices
      adjust_indices $startpos $endpos $end_index $last

      set last $start_index

    }

    save_serial $win

  }

  ######################################################################
  # Update the model with the replacement information.
  proc replace {win ranges} {

    variable serial

    load_serial $win

    set last [llength $serial]

    foreach {startpos endpos newendpos} $ranges {

      # Calculate the indices in the serial list
      set start_index [find_serial_index $startpos]
      set end_index   [find_serial_index $endpos]

      # Remove all elements between indices
      set serial [lreplace $serial[set serial {}] $start_index $end_index]

      # Adjust the serial list indices
      adjust_indices $startpos $newendpos $end_index $last

      set last $start_index

    }

    # Save the results of the replacement
    save_serial $win

  }

  ######################################################################
  # Updates the model, inserting the given parsed elements prior to rebuilding
  # the model tree.
  proc update {tid win elements} {

    variable serial

    # Load the serial list from shared memory
    load_serial $win

    # If we have something to insert into the serial list, do it now
    if {[llength $elements] > 0} {
      set insert_index [find_serial_index [lindex $elements 0 2]]
      set serial       [linsert $serial[set $serial {}] $insert_index {*}$elements]
    }

    # Rebuild the model tree
    make_tree $win

    # Save the serial list to shared memory
    save_serial $win

  }

  ######################################################################
  # Rebuilds the entire pairs tree based on the current serial tree.
  proc make_tree {win} {

    variable serial
    variable current

    # Clear the tree
    ::struct::tree tree

    set current root
    set i       0

    foreach item $serial {
      lassign $item type side index
      insert_position tree $current $side $i $type
      incr i
    }

    # debug_show_tree

    save_tree $win

  }

  ######################################################################
  # Inserts a character type into the tree.
  proc insert_position {tree node side index type} {

    variable current

    # If the current node is root, add a new node as a chilid
    if {$node eq "root"} {
      set current [add_child_node $node end $side $index $type]

    } else {
      switch $side {
        left -
        right {
          if {[tree get $node type] eq $type} {
            if {[tree keyexists $node $side]} {
              set current [add_child_node $node end $side $index $type]
            } else {
              tree set $node $side $index
              set current [tree parent $node]
            }
          } else {
            set current [add_child_node $node end $side $index $type]
          }
        }
        any {
          if {![tree keyexists $node right] && ([tree get $node type] eq $type)} {
            tree set $node right $index
            set current [tree parent $node]
          } else {
            set current [add_sibling_node $node left $index $type]
          }
        }
      }
    }

    # puts "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    # puts "Inserted index: $index, type: $type"
    # debug_show_tree

  }

  ######################################################################
  # Adds the given node contents to the parent node
  proc add_child_node {parent cindex side index type} {

    set new [tree insert $parent $cindex]

    # Initialize the node
    tree set $new $side  $index
    tree set $new type   $type
    tree set $new hidden 0

    return $new

  }

  ######################################################################
  # Adds a sibling node of the given node in the tree and initializes the
  # node with the given values.
  proc add_sibling_node {node side index type} {

    set parent     [tree parent $node]
    set node_index [tree index $node]
    set cindex     [expr {($side eq "left") ? $node_index : ($node_index+1)}]

    return [add_child_node $parent $cindex $side $index $type]

  }

  ######################################################################
  # Gets an index list of all nodes in the tree that are not matched.
  proc get_mismatched {win} {

    # Get the tree information
    load_all $win

    # Find all of the nodes that are mismatched and create a list of them
    set ranges [list]
    foreach node [tree descendants root filter model::mismatched] {
      if {[tree keyexists $node left]} {
        set index [tree get $node left]
      } else {
        set index [tree get $node right]
      }
      lappend ranges [position $index] [position $index 1]
    }

    # Destroy the tree
    tree destroy

    return $ranges

  }

  ######################################################################
  # Returns 1 if the given node is a mismatched node.
  proc mismatched {tree node} {

    expr {![tree keyexists $node left] || ![tree keyexists $node right]}

  }

  ######################################################################
  # Finds the lowest level node that contains the given index.  This is
  # meant to be a helper function for a higher level function.
  proc find_node {index {node root}} {

    foreach child [tree children $node] {
      if {![tree keyexists $child left] || [iless [tree get $child left] $index]} {
        if {[tree keyexists $child right] && [iless $index [tree get $child right]]} {
          return [find_node $index $child]
        }
      } elseif {[tree get $child left] eq $index} {
        return $child
      }
    }

    return $node

  }

  ######################################################################
  # Returns the depth of the given node.
  proc get_depth {win pos type} {

    # Get the tree information
    load_all $win

    # Get the node that contains the given index
    set depth [tree depth [find_match tree [index $pos] $type]]

    # Destroy the tree
    tree destroy

    return $depth

  }

  ######################################################################
  # Returns the node that contains the given index and matches the given
  # type.  If no match was found, we will return the root node.
  proc find_match {index type} {

    set node [find_node $index]

    while {($node ne "root") && ([tree get $node type] ne $type)} {
      set node [tree parent $node]
    }

    return $node

  }

}
