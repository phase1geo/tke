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
# Name:    edit.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    05/21/2013
# Brief:   Namespace containing procedures used for editing.  These are
#          shared between Vim and non-Vim modes of operation.
######################################################################

namespace eval edit {

  source [file join $::tke_dir lib ns.tcl]

  array set patterns {
    nnumber {^([0-9]+|0x[0-9a-fA-F]+|[0-9]+\.[0-9]+)}
    pnumber {([0-9]+|0x[0-9a-fA-F]+|[0-9]+\.[0-9]+)$}
    nspace  {^[ \t]+}
    pspace  {[ \t]+$}
  }

  ######################################################################
  # Inserts the line above the current line in the given editor.
  proc insert_line_above_current {txt} {

    # If we are operating in Vim mode,
    [ns vim]::edit_mode $txt

    # Create the new line
    if {[[ns multicursor]::enabled $txt]} {
      [ns multicursor]::adjust $txt "-1l" 1 dspace
    } else {
      $txt insert "insert linestart" "\n"
    }

    # Place the insertion cursor
    $txt mark set insert "insert-1l"
    $txt see insert

    # Perform the proper indentation
    [ns indent]::newline $txt insert

    # Start recording
    [ns vim]::record_start

  }

  ######################################################################
  # Inserts a blank line below the current line in the given editor.
  proc insert_line_below_current {txt} {

    # If we are operating in Vim mode, switch to edit mode
    [ns vim]::edit_mode $txt

    # Get the current insertion point
    set insert [$txt index insert]

    # Add the line(s)
    if {[[ns multicursor]::enabled $txt]} {
      [ns multicursor]::adjust $txt "+1l" 1 dspace
    } else {
      $txt insert "insert lineend" "\n"
    }

    # Perform the insertion
    if {$insert == [$txt index insert]} {
      $txt mark set insert "insert+1l"
    }
    $txt see insert

    # Perform the proper indentation
    [ns indent]::newline $txt insert

    # Start recording
    [ns vim]::record_start

  }

  ######################################################################
  # Inserts the given file contents beneath the current insertion line.
  proc insert_file {txt fname} {

    # Attempt to open the file
    if {[catch { open $fname r } rc]} {
      return
    }

    # Read the contents of the file and close the file
    set contents [read $rc]
    close $rc

    # Insert the file contents beneath the current insertion line
    $txt insert "insert lineend" "\n$contents"

    # Adjust the insertion point, if necessary
    [ns vim]::adjust_insert $txt

  }

  ######################################################################
  # Deletes the current line.
  proc delete_current_line {txt {num ""}} {

    # Clear the clipboard
    clipboard clear

    # Add the text to be deleted to the clipboard and delete the text
    if {$num ne ""} {
      clipboard append [$txt get "insert linestart" "insert linestart+[expr $num - 1]l lineend"]\n
      $txt delete "insert linestart" "insert linestart+${num}l"
    } else {
      clipboard append [$txt get "insert linestart" "insert lineend"]\n
      $txt delete "insert linestart" "insert linestart+1l"
    }

  }

  ######################################################################
  # Deletes the current word (i.e., dw Vim mode).
  proc delete_current_word {txt {num ""}} {

    # Clear the clipboard
    clipboard clear

    if {$num ne ""} {
      set word [get_word $txt next [expr $num - 1]]
      clipboard append [$txt get "insert wordstart" "$word wordend"]
      $txt delete "insert wordstart" "$word wordend"
    } else {
      clipboard append [$txt get "insert wordstart" "insert wordend"]
      $txt delete "insert wordstart" "insert wordend"
    }

  }

  ######################################################################
  # Delete from the current cursor to the end of the line
  proc delete_to_end {txt} {

    # Delete from the current cursor to the end of the line
    if {[[ns multicursor]::enabled $txt]} {
      [ns multicursor]::delete $txt "lineend"
    } else {
      clipboard clear
      clipboard append [$txt get insert "insert lineend"]
      $txt delete insert "insert lineend"
    }

  }

  ######################################################################
  # Delete from the start of the current line to just before the current cursor.
  proc delete_from_start {txt} {

    # Delete from the beginning of the line to just before the current cursor
    if {[[ns multicursor]::enabled $txt]} {
      [ns multicursor]::delete $txt "linestart"
    } else {
      clipboard clear
      clipboard append [$txt get "insert linestart" insert]
      $txt delete "insert linestart" insert
    }

  }

  ######################################################################
  # Delete all consecutive numbers from cursor to end of line.
  proc delete_next_numbers {txt} {

    variable patterns

    if {[[ns multicursor]::enabled $txt]} {
      [ns multicursor]::delete $txt pattern $patterns(nnumber)
    } else {
      if {[regexp $patterns(nnumber) [$txt get insert "insert lineend"] match]} {
        clipboard clear
        clipboard append [$txt get insert "insert+[string length $match]c"]
        $txt delete insert "insert+[string length $match]c"
      }
    }

  }

  ######################################################################
  # Deletes all consecutive numbers prior to the cursor.
  proc delete_prev_numbers {txt} {

    variable patterns

    if {[[ns multicursor]::enabled $txt]} {
      [ns multicursor]::delete $txt pattern $patterns(pnumber)
    } else {
      if {[regexp $patterns(pnumber) [$txt get "insert linestart" insert] match]} {
        clipboard clear
        clipboard append [$txt get "insert-[string length $match]c" insert]
        $txt delete "insert-[string length $match]c" insert
      }
    }

  }

  ######################################################################
  # Deletes all consecutive whitespace starting from cursor to the end of
  # the line.
  proc delete_next_space {txt} {

    variable patterns

    if {[multicursor::enabled $txt]} {
      [ns multicursor]::delete $txt pattern $patterns(nspace)
    } else {
      if {[regexp $patterns(nspace) [$txt get insert "insert lineend"] match]} {
        clipboard clear
        clipboard append [$txt get insert "insert+[string length $match]c"]
        $txt delete insert "insert+[string length $match]c"
      }
    }

  }

  ######################################################################
  # Deletes all consecutive whitespace prior to the cursor.
  proc delete_prev_space {txt} {

    variable patterns

    if {[multicursor::enabled $txt]} {
      [ns multicursor]::delete $txt pattern $patterns(pspace)
    } else {
      if {[regexp $patterns(pspace) [$txt get "insert linestart" insert] match]} {
        clipboard clear
        clipboard append [$txt get "insert-[string length $match]c" insert]
        $txt delete "insert-[string length $match]c" insert
      }
    }

  }

  ######################################################################
  # Deletes all text found between the given character such that the
  # current insertion cursor sits between the character set.  Returns 1
  # if a match occurred (and text was deleted); otherwise, returns 0.
  proc delete_between_char {txt char} {

    if {([set start_index [$txt search -backwards $char insert 1.0]] ne "") && \
        ([set end_index   [$txt search -forwards  $char insert end]] ne "")} {
      clipboard clear
      clipboard append [$txt get $start_index+1c $end_index]
      $txt delete $start_index+1c $end_index
      return 1
    }

    return 0

  }

  ######################################################################
  # If a selection occurs, joins the selected lines; otherwise, joins the
  # number of specified lines.
  proc transform_join_lines {txt {num ""}} {

    # Specifies if at least one line was deleted in the join
    set deleted 0

    # Create a separator
    $txt edit separator

    if {[llength [set selected [$txt tag ranges sel]]] > 0} {

      # Clear the selection
      $txt tag remove sel 1.0 end

      set lastpos ""
      foreach {endpos startpos} [lreverse $selected] {
        set lines [$txt count -lines $startpos $endpos]
        for {set i 0} {$i < $lines} {incr i} {
          set line    [string trimleft [$txt get "$startpos+1l linestart" "$startpos+1l lineend"]]
          $txt delete "$startpos lineend" "$startpos+1l lineend"
          if {$line ne ""} {
            $txt insert "$startpos lineend" " $line"
          }
        }
        set deleted [expr $deleted || ($lines > 0)]
        if {$lastpos ne ""} {
          set line    [string trimleft [$txt get "$lastpos linestart" "$lastpos lineend"]
          $txt delete "$lastpos-1l lineend" "$lastpos lineend"
          $txt insert "$startpos lineend" " $line"
        }
        set lastpos $startpos
      }

      set index [$txt index "$startpos lineend"]

    } else {

      set lines [expr {($num ne "") ? $num : 1}]
      for {set i 0} {$i < $lines} {incr i} {
        set line    [string trimleft [$txt get "insert+1l linestart" "insert+1l lineend"]]
        $txt delete "insert lineend" "insert+1l lineend"
        if {$line ne ""} {
          $txt insert "insert lineend" " $line"
        }
      }

      set deleted [expr $lines > 0]
      set index   [$txt index "insert lineend"]

    }

    if {$deleted} {

      # Set the insertion cursor and make it viewable
      $txt mark set insert $index
      $txt see insert

      # Create a separator
      $txt edit separator

    }

  }

  ######################################################################
  # Moves selected lines or the current line up by one line.
  proc transform_bubble_up {txt} {

    # Create undo separator
    $txt edit separator

    # If lines are selected, move all selected lines up one line
    if {[llength [set selected [$txt tag ranges sel]]] > 0} {
      foreach {end_range start_range} [lreverse $selected] {
        set str [$txt get "$start_range-1l linestart" "$start_range linestart"]
        $txt delete "$start_range-1l linestart" "$start_range linestart"
        $txt insert "$end_range+1l linestart" $str
      }

    # Otherwise, move the current line up by one line
    } else {
      set str [$txt get "insert-1l linestart" "insert linestart"]
      $txt delete "insert-1l linestart" "insert linestart"
      if {[$txt compare "insert+1l linestart" == end]} {
        set str "\n[string trimright $str]"
      }
      $txt insert "insert+1l linestart" $str
    }

    # Create undo separator
    $txt edit separator

  }

  ######################################################################
  # Moves selected lines or the current line down by one line.
  proc transform_bubble_down {txt} {

    # Create undo separator
    $txt edit separator

    # If lines are selected, move all selected lines down one line
    if {[llength [set selected [$txt tag ranges sel]]] > 0} {
      foreach {end_range start_range} [lreverse $selected] {
        set str [$txt get "$end_range+1l linestart" "$end_range+l2 linestart"]
        $txt delete "$end_range lineend" "$end_range+1l lineend"
        $txt insert "$start_range linestart" $str
      }

    # Otherwise, move the current line down by one line
    } else {
      set str [$txt get "insert+1l linestart" "insert+2l linestart"]
      $txt delete "insert lineend" "insert+1l lineend"
      $txt insert "insert linestart" $str
    }

    # Create undo separator
    $txt edit separator

  }

  ######################################################################
  # Refreshes the current file contents.
  proc file_refresh {} {

    # TBD

  }

}
