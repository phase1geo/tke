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

  array set data {}

  ######################################################################
  # Creates a new tree for the given window
  proc create {win} {

    variable data

    # Create the tree
    ::struct::tree [set data($win,tree) tree$win]

    set data($win,serial) [list]
    set data($win,debug)  0

  }

  ######################################################################
  # Removes the memory associated with the model.
  proc destroy {win} {

    variable data

    # Destroy the tree
    $data($win,tree) destroy

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
  # Outputs the current contents of the tree to standard output.
  proc debug_show {win {msg "Tree"}} {

    variable data

    utils::log -nonewline "$msg: [tree_string $data($win,tree) root [expr [string length $msg] + 2]]"

  }

  ######################################################################
  # Displays the given tree in a hierarchical format.
  proc tree_string {win tree node prefix_len} {

    set width 30

    if {($node ne "root") && [$tree index $node] > 0} {
      set str [string repeat { } [expr ([$tree depth $node] * $width) + $prefix_len]]
    }

    append str [format "%-${width}s" [node_string $win $tree $node]]

    if {[$tree isleaf $node]} {
      append str "\n"
    }

    foreach child [$tree children $node] {
      append str [tree_string $win $tree $child $prefix_len]
    }

    return $str

  }

  ######################################################################
  proc debug_show_serial {win {msg "Serial"}} {

    variable data

    utils::log "$msg: $data($win,serial)"

  }

  ######################################################################
  # Displays the specified tree to standard output.
  proc debug_show_tree {win {msg "Tree"}} {

    variable data

    utils::log -nonewline "\n$msg: [tree_string $win $data($win,tree) root [expr [string length $msg] + 2]]"

  }

  ######################################################################
  # Displays the information for a single node.
  proc debug_show_node {win node {msg "Node"}} {

    variable data

    utils::log "$msg: [node_string $win $data($win,tree) $node]"

  }

  ######################################################################
  # Returns a string version of the given node for display purposes.
  proc node_string {win tree node} {

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
    set type  [$tree get $node type]
    set curr  [expr {($node eq $current) ? "*" : ""}]

    if {[$tree keyexists $node left]}  { set left  [lindex [nindex_to_tindices $win [$tree get $node left]] 0] }
    if {[$tree keyexists $node right]} { set right [lindex [nindex_to_tindices $win [$tree get $node right]] 0] }

    return [format "(%s-%s {%s})%s" $left $right $type $curr]

  }

  ######################################################################
  # Creates an model index out of the given text index.
  proc tindex_to_sindex {pos} {

    lassign [split $pos .] row col

    return [list $row [list $col $col]]

  }

  ######################################################################
  # Returns the text widget position from the given tree index.
  proc nindex_to_tindices {win nindex} {

    variable data

    lassign [lindex $data($win,serial) $nindex 2] row cols

    return [list $row.[lindex $cols 0] $row.[expr [lindex $cols 1] + 1]]

  }

  ######################################################################
  # Returns true if the character at the given index is escaped.
  proc is_escaped {win tindex} {

    variable data

    lassign [split $tindex .] row col

    # We can't escape the first character of a row
    if {($col == 0) || ([set index [find_serial_index data($win,serial) $row.$col]] == 0)} {
      return 0
    }

    # Get the previous character's information
    lassign [lindex $data($win,serial) [expr $index - 1]] type side prev_index

    # Otherwise, if the previous character is an escape character
    expr {($type eq "escape") && ($prev_index eq [list $row [expr $col - 1]])}

  }

  ######################################################################
  # Compares two index values.  Returns -1 if a is less than b, 0 if a is
  # within b, or 1 if a is greater than b.
  proc compare {a b} {

    lassign $a arow acol
    lassign $b brow bcol

    if {$arow == $brow} {
      return [expr {($acol < [lindex $bcol 0]) ? -1 : (($acol > [lindex $bcol 1]) ? 1 : 0)}]
    } else {
      return [expr {($arow < $brow) ? -1 : 1}]
    }

  }

  ######################################################################
  # Adjusts all of the model indices based on the inserted text position.
  proc adjust_indices {win from_pos to_pos start_index last_index} {

    variable data

    lassign $start_index si sin
    lassign $last_index  li lin

    # If we are inserting text at the end, there's nothing left to do here
    if {$si == $li} {
      return
    }

    lassign [split $from_pos .] frow fcol
    lassign [split $to_pos .]   trow tcol

    set col_diff [expr $tcol - $fcol]
    set row_diff [expr $trow - $frow]

    if {$sin} {
      if {$fcol == [lindex $data($win,serial) $si 2 1 0]} {
        lset data($win,serial) $si 2 1 0 $tcol
      }
      lset data($win,serial) $si 2 1 1 [expr [lindex $data($win,serial) $si 2 1 1] + $col_diff]
      incr si
    }

    set i $si
    while {($i < $li) && ([lindex $data($win,serial) $i 2 0] == $frow)} {
      lset data($win,serial) $i 2 1 0 [expr [lindex $data($win,serial) $i 2 1 0] + $col_diff]
      lset data($win,serial) $i 2 1 1 [expr [lindex $data($win,serial) $i 2 1 1] + $col_diff]
      incr i
    }

    if {$row_diff} {
      while {$i < $li} {
        lset data($win,serial) $i 2 0 [expr [lindex $data($win,serial) $i 2 0] + $row_diff]
        incr i
      }
    }

  }

  ######################################################################
  # Finds the index in the serial list to begin transforming the list.
  # Index must be a valid text index in the form of row.col.
  proc find_serial_index {pserial index} {

    upvar $pserial serial

    set len   [llength $serial]
    set index [split $index .]

    if {($len == 0) || ([compare $index [lindex $serial 0 2]] == -1)} {
      return [list 0 0]
    } elseif {[compare $index [lindex $serial end 2]] == 1} {
      return [list $len 0]
    } else {
      set start 0
      set end   $len
      set mid   $end
      while {($end - $start) > 0} {
        set mid [expr (($end - $start) / 2) + $start]
        switch [compare $index [lindex $serial $mid 2]] {
          -1 { set end $mid }
           0 { return [list $mid 1] }
           1 { if {$start == $mid} { return [list $end 0] } else { set start $mid } }
        }
      }
      return [list $end 0]
    }

  }

  ######################################################################
  # Inserts the given items into the tree.
  proc insert {win ranges} {

    variable data

    set last [list [llength $data($win,serial)] 1]

    foreach {startpos endpos} $ranges {

      # Find the node to start the insertion
      set start_index [find_serial_index data($win,serial) $startpos]
      set end_index   [find_serial_index data($win,serial) $endpos]

      # Adjust the indices
      adjust_indices $win $startpos $endpos $start_index $last

      set last $start_index

    }

  }

  ######################################################################
  # Deletes the given text range and updates the model.
  proc delete {win ranges} {

    variable data

    set last [list [llength $data($win,serial)] 1]

    foreach {startpos endpos} $ranges {

      # Calculate the indices in the serial list
      set start_index [find_serial_index data($win,serial) $startpos]
      set end_index   [find_serial_index data($win,serial) $endpos]

      # Adjust the serial list indices
      adjust_indices $win $endpos $startpos $end_index $last

      # Delete the range of items in the serial list
      if {$start_index ne $end_index} {
        set data($win,serial) [lreplace $data($win,serial)[set data($win,serial) {}] \
          [lindex $start_index 0] [expr [lindex $end_index 0] - 1]]
      }

      set last $start_index

    }

  }

  ######################################################################
  # Update the model with the replacement information.
  proc replace {win ranges} {

    variable data

    set last [list [llength $data($win,serial)] 1]

    foreach {startpos endpos newendpos} $ranges {

      # Calculate the indices in the serial list
      set start_index [find_serial_index data($win,serial) $startpos]
      set end_index   [find_serial_index data($win,serial) $endpos]

      # Adjust the serial list indices
      adjust_indices $win $startpos $newendpos $end_index $last

      # Delete the range of items in the serial list
      if {$start_index ne $end_index} {
        set data($win,serial) [lreplace $data($win,serial)[set data($win,serial) {}] \
          [lindex $start_index 0] [expr ([lindex $end_index 0] + [lindex $end_index 1]) - 1]]
      }

      set last $start_index

    }

  }

  ######################################################################
  # Temporarily merge the current serial list with the tags
  # so that we can figure out which contexts to serially highlight
  proc get_context_tags {win linestart lineend ptags} {

    variable data

    upvar $ptags tags

    set ctags       [lsearch -all -inline -index 3 -exact $data($win,serial) 1]
    set start_index [find_serial_index ctags $linestart]
    set end_index   [find_serial_index ctags $lineend]

    if {[llength $tags] > 0} {
      if {$start_index ne $end_index} {
        set tags [lreplace $ctags [lindex $start_index 0] [expr ([lindex $end_index 0] + [lindex $end_index 1]) - 1] \
          {*}[lsort -dictionary -index 2 $tags]]
      } else {
        set tags [linsert $ctags [lindex $start_index 0] {*}[lsort -dictionary -index 2 $tags]]
      }
    }

  }

  ######################################################################
  # Updates the model, inserting the given parsed elements prior to rebuilding
  # the model tree.
  proc update {win linestart lineend elements} {

    variable data

    set start_index [find_serial_index data($win,serial) $linestart]
    set end_index   [find_serial_index data($win,serial) $lineend]
    set updated     0

    if {$data($win,debug)} {
      utils::log "============================================="
      utils::log "UPDATE:"
      utils::log "linestart: $linestart, lineend: $lineend, start_index: $start_index, end_index: $end_index"
      utils::log "elements: $elements"
    }

    # If we have something to insert into the serial list, do it now
    if {[llength $elements] > 0} {
      if {$start_index ne $end_index} {
        set data($win,serial) [lreplace $data($win,serial)[set data($win,serial) {}] \
         [lindex $start_index 0] [expr ([lindex $end_index 0] + [lindex $end_index 1]) - 1] {*}$elements]
      } else {
        set data($win,serial) [linsert $data($win,serial)[set data($win,serial) {}] \
         [lindex $start_index 0] {*}$elements]
      }
      make_tree $win
      set updated 1
    }

    if {$data($win,debug)} {
      utils::log "serial: $data($win,serial)"
      utils::log "---------------------------------------------"
    }
    
    return $updated

  }

  ######################################################################
  # Rebuilds the entire pairs tree based on the current serial tree.
  proc make_tree {win} {

    variable data
    variable current
    variable lescape

    # Clear the tree
    foreach child [$data($win,tree) children root] {
      $data($win,tree) delete $child
    }

    utils::log "After tree delete, size: [$data($win,tree) size]"
    utils::log [utils::stacktrace]

    set current root
    set i       0
    set lescape [list 0 0]

    foreach item $data($win,serial) {
      lassign $item type side index
      set node [insert_position $data($win,tree) $current $side $i $type $index]
      lset data($win,serial) $i 4 $node
      incr i
    }

    if {$data($win,debug)} {
      debug_show_tree $win
    }

  }

  ######################################################################
  # Inserts a character type into the tree.
  proc insert_position {tree node side index type sindex} {

    variable current
    variable lescape

    # Calculate the starting index and if it is escaped, skip the insertion
    if {$lescape eq [set sindex [list [lindex $sindex 0] [lindex $sindex 1 0]]]} {
      return ""
    }

    # If the current node is root, add a new node as a chilid
    if {$node eq "root"} {
      return [insert_root_$side $tree $node $index $type $sindex]

    # Otherwise, add the position to the tree unless it is being placed within
    # a comment/string.
    } elseif {![$tree get $node comstr] || ([$tree get $node type] eq $type) || ($side eq "none")} {
      return [insert_$side $tree $node $index $type $sindex]
    }

  }

  ######################################################################
  # Handles the insertion of a left side item into the root node.
  proc insert_root_left {tree node index type sindex} {

    return [add_child_node $tree $node end left $index $type]

  }

  ######################################################################
  # Handles the insertion of a right side item into the root node.
  proc insert_root_right {tree node index type sindex} {

    variable current

    set retval [add_child_node $tree $node end right $index $type]
    set current $node

    return $retval

  }

  ######################################################################
  # Handles the insertion of an item into the root node that can be
  # either a left or right side item.
  proc insert_root_any {tree node index type sindex} {

    return [add_child_node $tree $node end left $index $type]

  }

  ######################################################################
  # Handles the insertion of an item that won't be inserted into the
  # tree.
  proc insert_root_none {tree node index type sindex} {

    variable lescape

    if {$type eq "escape"} {
      lset sindex 1 [expr [lindex $sindex 1] + 1]
      set lescape $sindex
    }

    return ""

  }

  ######################################################################
  # Inserts a new node in the tree as a child of the current node.
  proc insert_left {tree node index type sindex} {

    return [add_child_node $tree $node end left $index $type]

  }

  ######################################################################
  # Inserts the current item to a right side of a node, creating a new
  # node or finishing an existing node.
  proc insert_right {tree node index type sindex} {

    variable current

    if {[$tree get $node type] eq $type} {

      $tree set $node right $index
      set current [$tree parent $node]

      return $node

    } else {

      # Check to see if the matching left already exists
      set tnode $node
      while {[set tnode [$tree parent $tnode]] ne "root"} {
        if {[$tree get $tnode type] eq $type} {
          $tree set $tnode right $index
          set current [$tree parent $tnode]
          return $tnode
        }
      }

      # If we didn't find it going up, add the item below it but keep
      # the current node the current node
      set retval [add_child_node $tree $node end right $index $type]
      set current $node

      return $retval

    }

  }

  ######################################################################
  # Handles the insertion of an element that can be either a left or
  # right side item.
  proc insert_any {tree node index type sindex} {

    variable current

    if {[$tree get $node type] eq $type} {
      $tree set $node right $index
      set current [$tree parent $node]
      return $node
    } else {
      return [add_child_node $tree $node end left $index $type]
    }

  }

  ######################################################################
  # Handles the insertion of an element that will not be inserted.
  proc insert_none {tree node index type sindex} {

    return [insert_root_none $tree $node $index $type $sindex]

  }

  ######################################################################
  # Adds the given node contents to the parent node
  proc add_child_node {tree parent cindex side index type} {

    variable current

    set current [$tree insert $parent $cindex]

    # Initialize the node
    $tree set $current $side  $index
    $tree set $current type   $type
    $tree set $current hidden 0
    $tree set $current comstr [expr [lsearch [list bcomment lcomment double single btick tdouble tsingle tbtick] [lindex [split $type :] 0]] != -1]

    return $current

  }

  ######################################################################
  # Adds a sibling node of the given node in the tree and initializes the
  # node with the given values.
  proc add_sibling_node {tree node side index type} {

    set parent     [$tree parent $node]
    set node_index [$tree index $node]
    set cindex     [expr {($side eq "left") ? $node_index : ($node_index+1)}]

    return [add_child_node $tree $parent $cindex $side $index $type]

  }

  ######################################################################
  # Gets an index list of all nodes in the tree that are not matched.
  proc get_mismatched {win} {

    variable data
    
    # Find all of the nodes that are mismatched and create a list of them
    set ranges [list]
    foreach node [$data($win,tree) descendants root filter model::mismatched] {
      if {[$data($win,tree) keyexists $node left]} {
        set nindex [$data($win,tree) get $node left]
      } else {
        set nindex [$data($win,tree) get $node right]
      }
      lappend ranges {*}[nindex_to_tindices $win $nindex]
    }

    return $ranges

  }

  ######################################################################
  # Returns 1 if the given node is a mismatched node.
  proc mismatched {tree node} {

    expr {![$tree keyexists $node left] || ![$tree keyexists $node right]}

  }

  ######################################################################
  # Returns the depth of the given node.
  proc get_depth {win tindex {pattern *}} {

    variable data

    # Get the node that contains the given index
    return [$data($win,tree) depth [find_match $win $tindex $pattern]]

  }

  ######################################################################
  # Returns 1 if the given text widget index has a matching character
  # the tindex parameter will be populated with the matching character
  # text widget index.  If the character does not contain a match, a value
  # of 0 will be returned.
  proc get_match_char {win ptindex} {

    variable data

    upvar $ptindex tindex

    # Get the serial index to search for
    lassign [find_serial_index data($win,serial) $tindex] index matches

    utils::log "In get_match_char, index: $index, matches: $matches"
    
    if {$matches} {
      set node [lindex $data($win,serial) $index 4]
      utils::log "  node: $node"
      if {[$data($win,tree) keyexists $node left] && ([$data($win,tree) get $node left] == $index)} {
        if {[$data($win,tree) keyexists $node right]} {
          set tindex [nindex_to_tindices $win [$data($win,tree) get $node right]]
          return 1
        }
      } elseif {[$data($win,tree) keyexists $node left]} {
        set tindex [nindex_to_tindices $win [$data($win,tree) get $node left]]
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Returns the node that contains the given index and matches the given
  # type.  If no match was found, we will return the root node.
  proc find_match {win tindex pattern} {

    variable data

    # Find the node that contains the text index
    set node [find_node $tindex]

    # Search upwards in the tree looking for a node with a matching type
    while {($node ne "root") && ![string match $pattern [data($win,tree) get $node type]]} {
      set node [$data($win,tree) parent $node]
    }

    return $node

  }

  ######################################################################
  # Finds the node in the tree which contains the given text widgets index.
  # If the index is not within a node range, we will return the root node.
  proc find_node {win tindex} {

    variable data

    # Get the serial index to search for
    lassign [find_serial_index data($win,serial) $tindex] index matches
    
    # Get the node on the right
    if {[set b [lindex $data($win,serial) $index 4]] eq ""} {
      if {[set i [lsearch -start $index -index 4 -not $data($win,serial) ""]] == -1} {
        return "root"
      }
      set b [lindex $data($win,serial) $i 4]

    # If the node is valid and we exactly match, return the node immediately
    } elseif {$matches} {
      return $b
    }

    # Find the closest on the left
    set i [expr $index - 1]
    while {($i >= 0) && ([lindex $data($win,serial) $i 4] eq "")} {
      incr i -1
    }
    if {$i == -1} {
      return "root"
    }
    set a [lindex $data($win,serial) $i 4]

    if {($a eq $b) || ([$data($win,tree) parent $b] eq $a)} {
      return $a
    } elseif {[$data($win,tree) parent $a] eq $b} {
      return $b
    } else {
      return [$data($win,tree) parent $a]
    }

  }

}
