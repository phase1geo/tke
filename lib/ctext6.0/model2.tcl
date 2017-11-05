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

  ######################################################################
  # Creates a new tree for the given window
  proc create {win} {

    variable data

    # Save the tree in the new shared memory
    tsv::set serial $win [list]
    tsv::set pairs  $win [list]

  }

  ######################################################################
  # Removes the memory associated with the model.
  proc destroy {win} {

    tsv::unset serial $win
    tsv::unset pairs  $win

  }

  ######################################################################
  # Retrieves the given tree from shared memory and returns it to the
  # calling procedure.
  proc get_data {win} {

    variable data

    array set data [tsv::array get model$win]

  }

  ######################################################################
  # Saves the tree back to shared memory.
  proc set_data {win} {

    variable data

    tsv::array set model$win [array get data]

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
  # Compares to index values.  Returns 1 if a is less than b; otherwise,
  # returns 0.
  proc iless {a b} {

    lassign $a arow acol
    lassign $b brow bcol

    expr {($arow < $brow) || (($arow == $brow) && ($acol < $bcol))}

  }

  ######################################################################
  # Finds the index in the serial list.
  proc find_index {pserial index} {

    upvar $pserial serial

    return [lsearch [lsort -dictionary -index 0 [concat $serial $index]] $index]

  }

  ######################################################################
  # Inserts the given items into the tree.  The parameter 'same' should
  # be set
  proc insert {win startpos endpos elements} {

    # Get the shared data
    set serial [tsv::get serial $win]

    # Find the node to start the insertion
    set insertpos [find_index serial $startpos]

    # Adjust the indices
    adjust_indices serial $startpos $endpos $insertpos

    # If the serial list has changed indices, we need to update it and rebuild the pairings lists
    if {[llength $elements] > 0} {

      set serial [linsert $serial $insertpos {*}$elements]

      # Build the pairing data structure
      tsv::set pairs $win [build_pairings serial]

    }

    # Store the serial list
    tsv::set serial $win $serial

  }

  ######################################################################
  # Adjusts the indices in the serial list based on what was inserted.
  proc adjust_indices {pserial startpos endpos insertpos} {

    upvar $pserial serial

    set size [llength $serial]
    set i    $insertpos

    # If we are inserting text at the end, there's nothing left to do here
    if {$i == $size} {
      return
    }

    lassign [split $startpos .] srow scol
    lassign [split $endpos   .] erow ecol

    while {($i < $size) && ([lindex $serial $i 2] <= $erow)} {
      lset serial $i 3 [expr ([lindex $serial $i 3] - $scol) + $ecol]
      incr i
    }

    if {$srow != $erow} {
      set line_incr [expr $erow - $srow]
      set i         0
      while {$i < $size} {
        lset serial $i 2 [expr [lindex $serial $i 2] + $line_incr]
        incr i
      }
    }

  }

  ######################################################################
  # Build pairings lists from the serial list.
  proc build_pairings {pserial} {

    upvar $pserial serial

    set pairs [list]
    set stack [list]

    set index 0
    foreach item $serial {
      lassign $item tag side row col context
      build_pairing_$side $index $tag stack$context pairs$context
      incr index
    }

    return $pairs

  }

  ######################################################################
  proc build_pairing_left {index tag pstack ppairs} {

    upvar $pstack stack

    # Add the item to the stack
    lappend stack [list $index $tag]

  }

  ######################################################################
  proc build_pairing_right {index tag pstack ppairs} {

    upvar $pstack stack
    upvar $ppairs pairs

    set top [lindex $stack end 0]

    # Add the pair to the list of pairs for the given context
    lappend pairs [list $top $index $tag]

    # Update the stack
    set stack [lreplace $stack end end]

  }

  ######################################################################
  proc build_pairing_any {index tag pstack ppairs} {

    upvar $pstack stack
    upvar $ppairs pairs

    set side [lindex [list left right] [expr [llength $pairs] % 2]]

    build_pairing_$side $index $tag stack pairs

  }

  ######################################################################
  # Handles characters that don't indicate position.
  proc build_pairing_none {index tag pstack ppairs} {

    # Do nothing

  }

  ######################################################################
  # Inserts a character type into the tree.
  proc insert_position {tree node side index type block} {

    variable current

    set other [expr {($side eq "left") ? "right" : "left"}]

    if {$node eq "root"} {
      set current [add_child_node $tree $node end $side $index $type $block]
    } elseif {[is_side_set $tree $node $side $type]} {
      if {[$tree get $node $side] eq $index} {
        $tree set $node alttype $type
      } elseif {[is_side_set $tree $node $other $type] && [type_matches $tree $node $type]} {
        set current [add_sibling_node $tree $node $side [$tree get $node $side] $type $block]
        set_side $tree $node $side $type $index
      } else {
        set current [add_child_node $tree $node end $side $index $type $block]
      }
    } else {
      if {[type_matches $tree $node $type]} {
        set_side $tree $node $side $type $index
        set current [$tree parent $node]
      } else {
        add_sibling_node $tree $node $side $index $type $block
      }
    }

  }

  ######################################################################
  # Adds the given node contents to the parent node
  proc add_child_node {tree parent cindex side index type block} {

    set new [$tree insert $parent $cindex]

    # Initialize the node
    $tree set $new $side  $index
    $tree set $new type   $type
    $tree set $new block  $block
    $tree set $new hidden 0

    return $new

  }

  ######################################################################
  # Adds a sibling node of the given node in the tree and initializes the
  # node with the given values.
  proc add_sibling_node {tree node side index type block} {

    set parent     [$tree parent $node]
    set node_index [$tree index $node]
    set cindex     [expr {($side eq "left") ? $node_index : ($node_index+1)}]

    return [add_child_node $tree $parent $cindex $side $index $type $block]

  }

  ######################################################################
  # Gets an index list of all nodes in the tree that are not matched.
  proc get_mismatched {win types} {

    # Get the tree information
    set tree [get_tree $win]

    # Find all of the nodes that are mismatched and create a list of them
    set ranges [list]
    foreach node [$tree descendants root filter model::mismatched] {
      if {[$tree keyexists $node left]} {
        set index [$tree get $node left]
      } else {
        set index [$tree get $node right]
      }
      lappend ranges [position $index] [position $index 1]
    }

    # Destroy the tree
    $tree destroy

    return $ranges

  }

  ######################################################################
  # Returns 1 if the given node is a mismatched node.
  proc mismatched {tree node} {

    expr {![$tree keyexists $node left] || ![$tree keyexists $node right]}

  }

  ######################################################################
  # Finds the lowest level node that contains the given index.  This is
  # meant to be a helper function for a higher level function.
  proc find_container {tree index {node root}} {

    foreach child [$tree children $node] {
      if {![$tree keyexists $child left] || [iless [$tree get $child left] $index]} {
        if {[$tree keyexists $child right] && [iless $index [$tree get $child right]]} {
          return [find_container $tree $index $child]
        }
      } elseif {[$tree get $child left] eq $index} {
        return $child
      }
    }

    return $node

  }

  ######################################################################
  # Returns the depth of the given node.
  proc get_depth {win pos type} {

    # Get the tree information
    set tree [get_tree $win]

    # Get the node that contains the given index
    set depth [$tree depth [find_match $tree [index $pos] $type]]

    # Destroy the tree
    $tree destroy

    return $depth

  }

  ######################################################################
  # Returns the node that contains the given index and matches the given
  # type.  If no match was found, we will return the root node.
  proc find_match {tree index type} {

    set node [find_container $tree $index]

    while {($node ne "root") && ([$tree get $node type] ne $type)} {
      set node [$tree parent $node]
    }

    return $node

  }

}
