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

    # Create the tree
    ::struct::tree tree

    # Save the tree in the new shared memory
    set_tree $win

    # Destroy the tree
    tree destroy

  }

  ######################################################################
  # Removes the memory associated with the model.
  proc destroy {win} {

    if {[tsv::exists trees $win]} {
      tsv::unset trees $win
    }

  }

  ######################################################################
  # Retrieves the given tree from shared memory and returns it to the
  # calling procedure.
  proc get_tree {win} {
    
    ::struct::tree tree deserialize [tsv::get trees $win]
    
    return tree
    
  }
  
  ######################################################################
  # Saves the tree back to shared memory.
  proc set_tree {win} {
    
    tsv::set trees $win [tree serialize]
    
  }
  
  ######################################################################
  # Outputs the current contents of the tree to standard output.
  proc debug_show {win {msg "Tree"}} {

    ::struct::tree tree deserialize [tsv::get trees $win]
    
    puts -nonewline "$msg: [tree_string tree root [expr [string length $msg] + 2]]"
    
    tree destroy

  }
  
  ######################################################################
  # Displays the given tree in a hierarchical format.
  proc tree_string {tree node prefix_len} {
  
    if {($node ne "root") && [$tree index $node] > 0} {
      set str [string repeat { } [expr ([$tree depth $node] * 25) + $prefix_len]]
    }
    
    append str [format "%-25s" [node_string tree $node]]
    
    if {[$tree isleaf $node]} {
      append str "\n"
    }
    
    foreach child [$tree children $node] {
      append str [tree_string $tree $child $prefix_len]
    }
    
    return $str
    
  }
  
  ######################################################################
  # Displays the information for a single node.
  proc debug_show_node {tree node {msg "Node"}} {
    
    puts "$msg: [node_string $tree $node]"
      
  }

  ######################################################################
  # Returns a string version of the given node for display purposes.
  proc node_string {tree node} {
    
    if {$node eq "root"} {
      return "(root)"
    }
    
    set left  "NA"
    set right "NA"
    set type  [$tree get $node type]
    
    if {[$tree keyexists $node left]}  { set left  [$tree get $node left] }
    if {[$tree keyexists $node right]} { set right [$tree get $node right] }
    
    return [format "(%s-%s %s)" [position $left] [position $right] $type]
    
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
  # Adjusts all of the model indices based on the inserted text position.
  proc adjust_insert_indices {win startpos endpos} {
    
    # Get a copy of the tree from shared memory
    set tree [get_tree $win]
    
    $tree descendants root filter [list model::adjust_greater_than {*}[index $startpos] {*}[index $endpos]]
    
    # Save the modified tree
    set_tree $win
    
    # Destroy the tree
    $tree destroy
    
  }
  
  ######################################################################
  # Adjusts the affected indices of the given node based on the inserted
  # text positions.
  proc adjust_greater_than {srow scol erow ecol tree node} {
    
    foreach side {right left} {
      if {[$tree keyexists $node $side]} {
        lassign [$tree get $node $side] row col
        if {($srow == $row) && ($scol <= $col)} {
          $tree set $node $side [list $erow [expr ($col - $scol) + $ecol]]
        } elseif {$srow > $row} {
          $tree set $node $side [list [expr ($row - $srow) + $erow] $col]
        } else {
          return 0
        }
      }
    }
    
    return 0
    
  }

  ######################################################################
  # Inserts the given items into the tree.
  proc insert {win elements block} {

    variable current
    
    # Get a copy of the tree from shared memory
    set tree [get_tree $win]
    
    # Find the node to start the insertion
    set current [find_container $tree [lindex $elements 2]]
    debug_show_node $tree $current "Current"

    foreach {type side pos} $elements {
      insert_$side $tree $current [index $pos] $type $block
    }

    # Put the tree back into shared memory
    set_tree $win
    
    # Get rid of the tree
    tree destroy

  }
  
  ######################################################################
  # Inserts a left character type into the tree.
  proc insert_left {tree node index type block} {

    if {($node eq "root") || ![$tree keyexists $node right]} {
      add_node $tree $node end left $index $type $block
    } elseif {![$tree keyexists $node left] && ([$tree get $node type] eq $type)} {
      $tree set $node left $index
    }

  }

  ######################################################################
  # Inserts an ending character type into the tree.
  proc insert_right {tree node index type block} {
    
    variable current

    if {($node eq "root") || [$tree keyexists $node right]} {
      add_node $tree $node end right $index $type $block
    } elseif {[$tree get $node type] eq $type} {
      $tree set $node right $index
      set current [$tree parent $node]
    }
    
  }

  ######################################################################
  # Adds the given node contents to the parent node
  proc add_node {tree parent cindex pos index type block} {
    
    variable current
    
    set current [$tree insert $parent $cindex]
    
    # Initialize the node
    $tree set $current $pos   $index
    $tree set $current type   $type
    $tree set $current block  $block
    $tree set $current hidden 0
    
  }

  ######################################################################
  # Gets an index list of all nodes in the tree that are not matched.
  proc get_mismatched {win} {

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
