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
    ::struct::tree newtree

    # Save the tree in the new shared memory
    tsv::set trees $win [newtree serialize]

    # Destroy the tree
    newtree destroy

  }

  ######################################################################
  # Removes the memory associated with the model.
  proc destroy {win} {

    if {[tsv::exists trees $win]} {
      tsv::unset trees $win
    }

  }

  ######################################################################
  # Outputs the current contents of the tree to standard output.
  proc debug_show {win} {

    puts [tsv::get trees $win]

  }

  ######################################################################
  # Compares to index values.  Returns -1 if a comes before b.  Returns 1
  # if b comes before a.
  proc index_compare {a b} {

    return [expr {[string equal $a [lindex [lsort -dictionary [list $a $b]] 0]] ? -1 : 1}]

  }

  ######################################################################
  # Inserts the given items into the tree.
  proc insert {win elements} {

    # Get a copy of the tree from shared memory
    ::struct::tree tree deserialize [tsv::get trees $win]

    foreach {type pos index} $elements {
      insert_$pos tree $index $type
    }

    # Put the tree back into shared memory
    tsv::set trees $win [tree serialize]

    # Get rid of the tree
    tree destroy

  }

  ######################################################################
  # Inserts a starting character type into the tree.
  proc insert_start {tree index type {parent root}} {

    foreach node [$tree children $parent] {
      if {[index_compare [$tree get $node start] $index] == -1} {
        if {![$tree keyexists $node end] || ([index_compare $index [$tree get $node end]] == -1)} {
          insert_start $tree $index $type $node
          return
        }
      } else {
        set new [$tree insert $parent [$tree index $node]]
        $tree set $new start $index
        $tree set $new type  $type
        return
      }
    }

    set new [$tree insert $parent end]
    $tree set $new start $index
    $tree set $new type  $type

  }

  ######################################################################
  # Inserts an ending character type into the tree.
  proc insert_end {tree index type {parent root}} {

    puts "In insert_end, index: $index, type: $type, parent: $parent"

    foreach node [$tree children $parent] {
      if {[index_compare [$tree get $node start] $index] == -1} {
        if {[$tree get $node type] eq $type} {
          if {![$tree keyexists $node end]} {
            if {[$tree numchildren $node] == 0} {
              $tree set $node end $index
            } else {
              insert_end $tree $index $type $node
            }
            return
          } elseif {[index_compare $index [$tree get $node end] == -1]} {
            insert_end $tree $index $type $node
            return
          }
        } else {
          if {![$tree keyexists $node end] || ([index_compare $index [$tree get $node end]] == -1)} {
            insert_end $tree $index $type $node
            return
          }
        }
      } else {
        set new [$tree insert $parent [$tree index $node]]
        $tree set $new end  $index
        $tree set $new type $type
        return
      }
    }

    set new [$tree insert $parent end]
    $tree set $new end  $index
    $tree set $new type $type

  }

  ######################################################################
  # Finds the lowest level node that contains the given index.  This is
  # meant to be a helper function for a higher level function.
  proc container {tree index {parent root}} {

    foreach node [$tree children $parent] {
      if {[$tree get $node start] eq $index} {
        return $node
      }
      if {![$tree keyexists $node start] || ([index_compare [$tree get $node start] $index] == -1)} {
        if {[$tree keyexists $node end] && [index_compare $index [$tree get $node end]] == -1} {
          return [container $tree $index $node]
        }
      }
    }

    return $parent

  }

}
