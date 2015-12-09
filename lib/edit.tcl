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
      clipboard append [$txt get "insert linestart" "insert linestart+[expr $number($txt) - 1]l lineend"]\n
      $txt delete "insert linestart" "insert linestart+$number($txt)l"
    } else {
      clipboard append [$txt get "insert linestart" "insert lineend"]\n
      $txt delete "insert linestart" "insert linestart+1l"
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
        $txt delete "insert-[string length $match]c" insert
      }
    }

  }

  ######################################################################
  # Refreshes the current file contents.
  proc file_refresh {} {

    # TBD

  }

}
