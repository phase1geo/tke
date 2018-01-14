# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
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
# Name:    multicursor.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/15/2013
# Brief:   Namespace to handle cases where multiple cursor support is needed.
######################################################################

namespace eval multicursor {

  variable selected      0
  variable select_anchor ""
  variable cursor_anchor ""

  array set copy_cursors {}

  ######################################################################
  # Handles a selection of the widget in the multicursor mode.
  proc handle_selection {W} {

    variable selected

    # If we are in multimove Vim mode, return immediately
    if {[vim::in_multimove $W]} {
      return
    }

    set selected 0

    if {[llength [set sel [$W tag ranges sel]]] > 2} {
      set selected 1
      $W tag remove mcursor 1.0 end
      foreach {start end} $sel {
        $W tag add mcursor $start
      }
    }

  }

  ######################################################################
  # Handles an escape event in multicursor mode.
  proc handle_escape {W} {

    if {[set first [lindex [$W tag ranges mcursor] 0]] ne ""} {

      # If we are not in a multimove, delete the mcursors
      if {![vim::in_multimove $W] && ([vim::get_edit_mode $W] eq "")} {
        disable $W

      # Otherwise, position the insertion cursor on the first multicursor position
      } else {
        $W cursor set $first
      }

    }

  }

  ######################################################################
  # Searches for any string matches in the from/to range that match the
  # regular expression "exp".  Whenever a match is found, the first
  # character in the match is added to the current cursor list.
  proc search_and_add_cursors {txt from to exp} {

    foreach index [$txt search -regexp -all $exp $from $to] {
      add_cursor $txt $index
    }

  }

  ######################################################################
  # Adjusts the view to make sure that previously viewable cursors are
  # still visible.
  proc adjust_set_and_view {txtt prev next} {

    # Add the multicursor
    $txtt tag add mcursor $next

    # If our next cursor is going off screen, make it viewable
    if {([$txtt bbox $prev] ne "") && ([$txtt bbox $next] eq "")} {
      $txtt see $next
    }

  }

  ######################################################################
  # Adjusts the selection if we are in a Vim visual mode.
  proc adjust_select {txtt} {

    if {[vim::in_visual_mode $txtt]} {
      $txtt tag remove sel 1.0 end
      set i 0
      foreach {start end} [$txtt tag ranges mcursor] {
        vim::adjust_select $txtt $i $start
        incr i
      }
    }

  }

  ######################################################################
  # Returns true if the given motion is not supported by multicursor mode.
  proc motion_unsupported {txtt motion} {

    return [expr [lsearch [list linenum screentop screenmid screenbot first last] $motion] != -1]

  }

  ######################################################################
  # Moves all of the cursors using the positional arguments.
  proc move {txtt posargs} {

    array set opts {
      -num 1
    }
    array set opts [lassign $posargs motion]

    # If the motion is not supported, return now
    if {[motion_unsupported $txtt $motion]} {
      return
    }

    # Get the existing ranges
    set ranges [$txtt tag ranges mcursor]

    # Get the list of new ranges
    set new_ranges [list]
    foreach {start end} $ranges {
      set new_start [$txtt index [$txtt index [list {*}$posargs -startpos $start]]]
      if {[$txtt compare $new_start == "$new_start lineend"] && [$txtt compare $new_start > "$new_start linestart"]} {
        set new_start [$txtt index $new_start-1c]
      }
      lappend new_ranges $start $new_start
    }

    # If any cursors are going to "fall off" an edge, don't perform the move
    switch $motion {
      left {
        foreach {start new_start} $new_ranges {
          if {([lindex [split $start .] 1] - [lindex [split $new_start .] 1]) < $opts(-num)} {
            adjust_select $txtt
            return
          }
        }
      }
      right {
        foreach {start new_start} $new_ranges {
          if {([lindex [split $new_start .] 1] - [lindex [split $start .] 1]) < $opts(-num)} {
            adjust_select $txtt
            return
          }
        }
      }
      up {
        if {([lindex [split [lindex $new_ranges 0] .] 0] - [lindex [split [lindex $new_ranges 1] .] 0]) < $opts(-num)} {
          adjust_select $txtt
          return
        }
      }
      down {
        if {([lindex [split [lindex $new_ranges end] .] 0] - [lindex [split [lindex $new_ranges end-1] .] 0]) < $opts(-num)} {
          adjust_select $txtt
          return
        }
      }
    }

    # Move the cursors
    $txtt tag remove mcursor 1.0 end
    foreach {new_start start} [lreverse $new_ranges] {
      if {[$txtt compare "$new_start linestart" == "$new_start lineend"]} {
        [winfo parent $txtt]._t insert "$new_start lineend" " " dspace
      }
      adjust_set_and_view $txtt $start $new_start
    }

    # Adjust the selection
    adjust_select $txtt

  }

  ######################################################################
  # Toggles the case of all characters that match the given positional arguments.
  proc toggle_case {txtt eposargs sposargs object} {

    if {[enabled [winfo parent $txtt]]} {

      # If the motion is not supported, return now
      if {[motion_unsupported $txtt [lindex $eposargs 0]]} {
        return 1
      }

      foreach {start end} [$txtt tag ranges mcursor] {
        edit::convert_case_toggle $txtt {*}[edit::get_range $txtt $eposargs $sposargs $object 0 $start]
        $txtt tag add mcursor $start
      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Transforms all text to upper case for the given multicursor ranges.
  proc upper_case {txtt eposargs sposargs object} {

    if {[enabled [winfo parent $txtt]]} {

      # If the motion is not supported, return now
      if {[motion_unsupported $txtt [lindex $eposargs 0]]} {
        return 1
      }

      foreach {start end} [$txtt tag ranges mcursor] {
        edit::convert_to_upper_case $txtt {*}[edit::get_range $txtt $eposargs $sposargs $object 0 $start]
        $txtt tag add mcursor $start
      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Transforms all text to lower case for the given multicursor ranges.
  proc lower_case {txtt eposargs sposargs object} {

    if {[enabled [winfo parent $txtt]]} {

      # If the motion is not supported, return now
      if {[motion_unsupported $txtt [lindex $eposargs 0]]} {
        return 1
      }

      foreach {start end} [$txtt tag ranges mcursor] {
        edit::convert_to_lower_case $txtt {*}[edit::get_range $txtt $eposargs $sposargs $object 0 $start]
        $txtt tag add mcursor $start
      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Transforms all text to rot13 for the given multicursor ranges.
  proc rot13 {txtt eposargs sposargs object} {

    if {[enabled [winfo parent $txtt]]} {

      # If the motion is not supported, return now
      if {[motion_unsupported $txtt [lindex $eposargs 0]]} {
        return 1
      }

      foreach {start end} [$txtt tag ranges mcursor] {
        edit::convert_to_rot13 $txtt {*}[edit::get_range $txtt $eposargs $sposargs $object 0 $start]
        $txtt tag add mcursor $start
      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Perform a left or right indentation shift for each multicursor line.
  proc shift {txtt dir eposargs sposargs object } {

    if {[enabled [winfo parent $txtt]]} {

      # If the motion is not supported, return now
      if {[motion_unsupported $txtt [lindex $eposargs 0]]} {
        return 1
      }

      if {$dir eq "right"} {
        foreach {start end} [$txtt tag ranges mcursor] {
          edit::indent $txtt {*}[edit::get_range $txtt $eposargs $sposargs $object 0 $start]
        }
      } else {
        foreach {start end} [$txtt tag ranges mcursor] {
          edit::unindent $txtt {*}[edit::get_range $txtt $eposargs $sposargs $object 0 $start]
        }
      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Copies any multicursors found in the given text block.
  proc copy {txt start end} {

    variable copy_cursors

    # Current index
    set current $start

    # Initialize copy cursor information
    set copy_cursors($txt,offsets) [list]
    set copy_cursors($txt,value)   [clipboard get]

    # Get the mcursor offsets from start
    while {[set index [$txt tag nextrange mcursor $current $end]] ne ""} {
      lappend copy_cursors($txt,offsets) [$txt count -chars $start [lindex $index 0]]
      set current [$txt index "[lindex $index 0]+1c"]
    }

  }

  ######################################################################
  # Adds multicursors to the given pasted text.
  proc paste {txt start} {

    variable copy_cursors

    # Only perform the operation if the stored value matches the clipboard contents
    if {[info exists copy_cursors($txt,value)] && ($copy_cursors($txt,value) eq [clipboard get])} {

      # Add the mcursors
      foreach offset $copy_cursors($txt,offsets) {
        $txt tag add mcursor "$start+${offset}c"
      }

    }

  }

}
