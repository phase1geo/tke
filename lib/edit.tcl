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
# Name:    edit.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    05/21/2013
# Brief:   Namespace containing procedures used for editing.  These are
#          shared between Vim and non-Vim modes of operation.
######################################################################

namespace eval edit {

  array set patterns {
    nnumber   {^([0-9]+|0x[0-9a-fA-F]+|[0-9]*\.[0-9]+)}
    pnumber   {([0-9]+|0x[0-9a-fA-F]+|[0-9]+\.[0-9]*)$}
    sentence  {[.!?][])\"']*\s+\S}
    nspace    {^[ \t]+}
    pspace    {[ \t]+$}
  }

  variable rot13_map {
    a n b o c p d q e r f s g t h u i v j w k x l y m z n a o b p c q d r e s f t g u h v i w j x k y l z m
    A N B O C P D Q E R F S G T H U I V J W K X L Y M Z N A O B P C Q D R E S F T G U H V I W J X K Y L Z M
  }

  ######################################################################
  # Inserts the line above the current line in the given editor.
  proc insert_line_above_current {txtt} {

    # If we are operating in Vim mode,
    vim::edit_mode $txtt

    # Create the new line
    if {[multicursor::enabled $txtt]} {
      multicursor::move $txtt up
    } elseif {[$txtt compare "insert linestart" == 1.0]} {
      $txtt insert "insert linestart" "\n"
      ::tk::TextSetCursor $txtt "insert-1l"
    } else {
      ::tk::TextSetCursor $txtt "insert-1l lineend"
      $txtt insert "insert lineend" "\n"
    }

    indent::newline $txtt insert 1

  }

  ######################################################################
  # Inserts a blank line below the current line in the given editor.
  proc insert_line_below_current {txtt} {

    # If we are operating in Vim mode, switch to edit mode
    vim::edit_mode $txtt

    # Get the current insertion point
    set insert [$txtt index insert]

    # Add the line(s)
    if {[multicursor::enabled $txtt]} {
      multicursor::move $txtt down
    } else {
      ::tk::TextSetCursor $txtt "insert lineend"
      $txtt insert "insert lineend" "\n"
    }

    # Make sure the inserted text is seen
    $txtt see insert

    # Perform the proper indentation
    indent::newline $txtt insert 1

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
    vim::adjust_insert $txt

  }

  ######################################################################
  # Checks to see if any text is currently selected.  If it is, performs
  # the deletion on the selected text.
  proc delete_selected {txtt line} {

    # If we have selected text, perform the deletion
    if {[llength [set selected [$txtt tag ranges sel]]] > 0} {

      # Allow multicursors to be handled, if enabled
      if {![multicursor::delete $txtt selected]} {

        if {$line} {

          # Save the selected text to the clipboard
          clipboard clear
          foreach {start end} $selected {
            clipboard append [$txtt get "$start linestart" "$end lineend"]
          }

          # Set the cursor to the first character of the selection prior to deletion
          $txtt mark set insert [lindex $selected 0]

          # Delete the text
          foreach {end start} [lreverse $selected] {
            $txtt delete "$start linestart" "$end lineend"
          }

        } else {

          # Save the selected text to the clipboard
          clipboard clear
          foreach {start end} $selected {
            clipboard append [$txtt get $start $end]
          }

          # Set the cursor to the first character of the selection prior to deletion
          $txtt mark set insert [lindex $selected 0]

          # Delete the text
          foreach {end start} [lreverse $selected] {
            $txtt delete $start $end
          }

        }

      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Deletes the current line.
  proc delete_current_line {txtt copy {num 1}} {

    # Clear the clipboard and copy the line(s) that will be deleted
    if {$copy} {
      clipboard clear
      clipboard append [$txtt get "insert linestart" "insert+${num}l linestart"]
    }

    # If we are deleting the last line, move the cursor up one line
    if {[$txtt compare "insert+${num}l linestart" == end]} {
      if {[$txtt compare "insert linestart" == 1.0]} {
        $txtt delete "insert linestart" "insert lineend"
      } else {
        set new_index [$txtt index "insert-1l"]
        $txtt delete "insert-1l lineend" "end-1c"
        $txtt mark set insert $new_index
      }
    } else {
      $txtt delete "insert linestart" "insert+${num}l linestart"
    }

    # Position the cursor at the beginning of the first word
    move_cursor $txtt firstchar

    # Adjust the insertion cursor
    if {$copy} {
      vim::adjust_insert $txtt
    }

  }

  ######################################################################
  # Deletes the current word (i.e., dw Vim mode).
  proc delete {txtt startpos endpos copy adjust} {

    # If the starting and ending position are the same, return now
    if {[$txtt compare $startpos == $endpos]} {
      return
    }

    # Copy the text to the clipboard, if specified
    if {$copy} {
      clipboard clear
      clipboard append [$txtt get $startpos $endpos]
    }

    set insertpos ""

    if {[$txtt compare $endpos == end]} {
      if {[$txtt compare $startpos == 1.0]} {
        set endpos "$startpos lineend"
      } elseif {[$txtt compare $startpos == "$startpos linestart"]} {
        set insertpos "$startpos-1l"
        set startpos  "$startpos-1l lineend"
        set endpos    "end-1c"
      }
    }

    # Delete the text
    $txtt delete $startpos $endpos

    # Adjust the insertion cursor if this was a delete and not a change
    if {$adjust} {
      if {$insertpos ne ""} {
        $txtt mark set insert $insertpos
      }
      vim::adjust_insert $txtt
    }

  }

  ######################################################################
  # Delete from the current cursor to the end of the line
  proc delete_to_end {txtt copy {num 1}} {

    # Delete from the current cursor to the end of the line
    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt "lineend"
    } else {
      set endpos [get_index $txtt lineend -num $num]+1c
      if {$copy} {
        clipboard clear
        clipboard append [$txtt get insert $endpos]
      }
      $txtt delete insert $endpos
      if {$copy} {
        vim::adjust_insert $txtt
      }
    }

  }

  ######################################################################
  # Delete from the start of the current line to just before the current cursor.
  proc delete_from_start {txtt copy} {

    # Delete from the beginning of the line to just before the current cursor
    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt "linestart"
    } else {
      if {$copy} {
        clipboard clear
        clipboard append [$txtt get "insert linestart" insert]
      }
      $txtt delete "insert linestart" insert
    }

  }

  ######################################################################
  # Delete from the start of the firstchar to just before the current cursor.
  proc delete_to_firstchar {txtt copy} {

    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt firstchar
    } else {
      set firstchar [get_index $txtt firstchar]
      if {[$txtt compare $firstchar < insert]} {
        if {$copy} {
          clipboard clear
          clipboard append [$txtt get $firstchar insert]
        }
        $txtt delete $firstchar insert
      } elseif {[$txtt compare $firstchar > insert]} {
        if {$copy} {
          clipboard clear
          clipboard append [$txtt get insert $firstchar]
        }
        $txtt delete insert $firstchar
        if {$copy} {
          vim::adjust_insert $txtt
        }
      }
    }

  }

  ######################################################################
  # Delete all consecutive numbers from cursor to end of line.
  proc delete_next_numbers {txtt copy} {

    variable patterns

    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt pattern $patterns(nnumber)
    } elseif {[regexp $patterns(nnumber) [$txtt get insert "insert lineend"] match]} {
      if {$copy} {
        clipboard clear
        clipboard append [$txtt get insert "insert+[string length $match]c"]
      }
      $txtt delete insert "insert+[string length $match]c"
      if {$copy} {
        vim::adjust_insert $txtt
      }
    }

  }

  ######################################################################
  # Deletes all consecutive numbers from the insertion toward the start of
  # the current line.
  proc delete_prev_numbers {txtt copy} {

    variable patterns

    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt pattern $patterns(pnumber)
    } elseif {[regexp $patterns(pnumber) [$txtt get "insert linestart" insert] match]} {
      if {$copy} {
        clipboard clear
        clipboard append [$txtt get "insert-[string length $match]c" insert]
      }
      $txtt delete "insert-[string length $match]c" insert
    }

  }

  ######################################################################
  # Deletes all consecutive whitespace starting from cursor to the end of
  # the line.
  proc delete_next_space {txtt} {

    variable patterns

    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt pattern $patterns(nspace)
    } elseif {[regexp $patterns(nspace) [$txtt get insert "insert lineend"] match]} {
      $txtt delete insert "insert+[string length $match]c"
    }

  }

  ######################################################################
  # Deletes all consecutive whitespace starting from cursor to the start
  # of the line.
  proc delete_prev_space {txtt} {

    variable patterns

    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt pattern $patterns(pspace)
    } elseif {[regexp $patterns(pspace) [$txtt get "insert linestart" insert] match]} {
      $txtt delete "insert-[string length $match]c" insert
    }

  }

  ######################################################################
  # Deletes from the current insert postion to (and including) the next
  # character on the current line.
  proc delete_to_next_char {txtt char copy {num 1} {exclusive 0}} {

    if {[set index [find_char $txtt next $char $num insert $exclusive]] ne "insert"} {
      if {$copy} {
        clipboard clear
        clipboard append [$txtt get insert $index]
      }
      $txtt delete insert $index
      if {$copy && $inclusive} {
        vim::adjust_insert $txtt
      }
    }

  }

  ######################################################################
  # Deletes from the current insert position to (and including) the
  # previous character on the current line.
  proc delete_to_prev_char {txtt char copy {num 1} {exclusive 0}} {

    if {[set index [find_char $txtt prev $char $num insert $exclusive]] ne "insert"} {
      if {$copy} {
        clipboard clear
        clipboard append [$txtt get $index insert]
      }
      $txtt delete $index insert
    }

  }

  ######################################################################
  # Get the start and end positions for the pair defined by char.
  proc get_char_positions {txtt char} {

    array set pairs {
      \{ {\\\} L}
      \} {\\\{ R}
      \( {\\\) L}
      \) {\\\( R}
      \[ {\\\] L}
      \] {\\\[ R}
      <  {> L}
      >  {< R}
    }

    # Initialize
    set retval [set end_index 0]

    # Get the matching character
    if {[info exists pairs($char)]} {
      if {[lindex $pairs($char) 1] eq "R"} {
        if {[set start_index [gui::find_match_pair $txtt [lindex $pairs($char) 0] \\$char -backwards]] != -1} {
          set retval [expr {[set end_index [gui::find_match_pair $txtt \\$char [lindex $pairs($char) 0] -forwards]] != -1}]
        }
      } else {
        if {[set start_index [gui::find_match_pair $txtt \\$char [lindex $pairs($char) 0] -backwards]] != -1} {
          set retval [expr {[set end_index [gui::find_match_pair $txtt [lindex $pairs($char) 0] \\$char -forwards]] != -1}]
        }
      }
    } else {
      if {[set start_index [gui::find_match_char $txtt $char -backwards]] != -1} {
        set retval [expr {[set end_index [gui::find_match_char $txtt $char -forwards]] != -1}]
      }
    }

    return [list $start_index $end_index $retval]

  }

  ######################################################################
  # Deletes all text found between the given character such that the
  # current insertion cursor sits between the character set.  Returns 1
  # if a match occurred (and text was deleted); otherwise, returns 0.
  proc delete_between_char {txtt char copy} {

    if {[lassign [get_char_positions $txtt $char] start_index end_index]} {
      if {$copy} {
        clipboard clear
        clipboard append [$txtt get $start_index+1c $end_index]
      }
      $txtt delete $start_index+1c $end_index
      return 1
    }

    return 0

  }

  ######################################################################
  # Selects all of the text between the pair of characters.  Returns 1
  # if a match occurred (and the text was selected); otherwise, return 0.
  proc select_between_char {txtt char} {

    if {[lassign [get_char_positions $txtt $char] start_index end_index]} {
      $txtt tag remove sel 1.0 end
      ::tk::TextSetCursor $txtt $end_index
      $txtt tag add sel $start_index+1c $end_index
      vim::set_select_anchors $txtt $start_index+1c
      return 1
    }

    return 0

  }

  ######################################################################
  # Formats all text between the pair of characters.  Returns 1 if a match
  # occurred (and the text was formatted); otherwise, returns 0.
  proc format_between_char {txtt char} {

    if {[lassign [get_char_positions $txtt $char] start_index end_index]} {
      indent::format_text $txtt $start_index+1c $end_index
      return 1
    }

    return 0

  }

  ######################################################################
  # Left shifts all text between the pair of characters.  Returns 1 if a
  # match occurred (and the text was formatted); otherwise, returns 0.
  proc lshift_between_char {txtt char} {

    if {[lassign [get_char_positions $txtt $char] start_index end_index]} {
      unindent $txtt $start_index+1l $end_index-1l
      return 1
    }

    return 0

  }

  ######################################################################
  # Right shifts all text between the pair of characters.  Returns 1 if a
  # match occurred (and the text was formatted); otherwise, returns 0.
  proc rshift_between_char {txtt char} {

    if {[lassign [get_char_positions $txtt $char] start_index end_index]} {
      indent $txtt $start_index+1l $end_index-1l
      return 1
    }

    return 0

  }

  ######################################################################
  # Converts a character-by-character case inversion of the given text.
  proc convert_case_toggle {txtt startpos endpos} {

    # Get the string
    set str [$txtt get $startpos $endpos]

    # Adjust the string so that we don't add an extra new line
    if {[string index $str end] eq "\n"} {
      set str [string range $str 0 end-1]
    }

    set strlen [string length $str]
    set newstr ""

    for {set i 0} {$i < $strlen} {incr i} {
      set char [string index $str $i]
      append newstr [expr {[string is lower $char] ? [string toupper $char] : [string tolower $char]}]
    }

    $txtt replace $startpos "$startpos+${strlen}c" $newstr

  }

  ######################################################################
  # Converts the case to the given type on a word basis.
  proc convert_case_to_title {txtt startpos endpos} {

    set i 0
    foreach index [$txtt search -all -count lengths -regexp -- {\w+} $startpos $endpos] {
      set endpos   [$txtt index "$index+[lindex $lengths $i]c"]
      set word     [$txtt get $index $endpos]
      $txtt replace $index $endpos [string totitle $word]
      incr i
    }

    # Set the cursor
    ::tk::TextSetCursor $txtt $startpos

  }

  ######################################################################
  # Converts the given string
  proc convert_to_lower_case {txtt startpos endpos} {

    # Get the string
    set str [$txtt get $startpos $endpos]

    # Substitute the text
    $txtt replace $startpos "$startpos+[string length $str]c" [string tolower $str]

  }

  ######################################################################
  # Converts the given string
  proc convert_to_upper_case {txtt startpos endpos} {

    # Get the string
    set str [$txtt get $startpos $endpos]

    # Substitute the text
    $txtt replace $startpos "$startpos+[string length $str]c" [string toupper $str]

  }

  ######################################################################
  # Converts the text to rot13.
  proc convert_to_rot13 {txtt startpos endpos} {

    variable rot13_map

    # Get the string
    set str [$txtt get $startpos $endpos]

    # Perform the substitution
    $txtt replace $startpos "$startpos+[string length $str]c" [string map $rot13_map $str]

    # Set the cursor
    ::tk::TextSetCursor $txtt $startpos

  }

  ######################################################################
  # If text is selected, the case will be toggled for each selected
  # character.  Returns 1 if selected text was found; otherwise, returns 0.
  proc transform_toggle_case_selected {txtt} {

    if {[llength [set ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $ranges] {
        convert_case_toggle $txtt $startpos $endpos
      }
      ::tk::TextSetCursor $txtt $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Perform a case toggle operation.
  proc transform_toggle_case {txtt startpos endpos {cursorpos insert}} {

    if {![transform_toggle_case_selected $txtt]} {
      convert_case_toggle $txtt $startpos $endpos
      ::tk::TextSetCursor $txtt $cursorpos
    }

  }

  ######################################################################
  # If text is selected, the case will be lowered for each selected
  # character.  Returns 1 if selected text was found; otherwise, returns 0.
  proc transform_to_lower_case_selected {txtt} {

    if {[llength [set ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $ranges] {
        convert_to_lower_case $txtt $startpos $endpos
      }
      ::tk::TextSetCursor $txtt $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Perform a lowercase conversion.
  proc transform_to_lower_case {txtt startpos endpos {cursorpos insert}} {

    if {![transform_to_lower_case_selected $txtt]} {
      convert_to_lower_case $txtt $startpos $endpos
      ::tk::TextSetCursor $txtt $cursorpos
    }

  }

  ######################################################################
  # If text is selected, the case will be uppered for each selected
  # character.  Returns 1 if selected text was found; otherwise, returns 0.
  proc transform_to_upper_case_selected {txtt} {

    if {[llength [set ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $ranges] {
        convert_to_upper_case $txtt $startpos $endpos
      }
      ::tk::TextSetCursor $txtt $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Perform an uppercase conversion.
  proc transform_to_upper_case {txtt startpos endpos {cursorpos insert}} {

    if {![transform_to_upper_case_selected $txtt]} {
      convert_to_upper_case $txtt $startpos $endpos
      ::tk::TextSetCursor $txtt $cursorpos
    }

  }

  ######################################################################
  # If text is selected, the selected text will be rot13'ed.  Returns 1
  # if selected text was found; otherwise, returns 0.
  proc transform_to_rot13_selected {txtt} {

    if {[llength [set ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $ranges] {
        convert_to_rot13 $txtt $startpos $endpos
      }
      ::tk::TextSetCursor $txtt $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Transforms all text in the given range to rot13.
  proc transform_to_rot13 {txtt startpos endpos {cursorpos insert}} {

    if {![transform_to_rot13_selected $txtt]} {
      convert_to_rot13 $txtt $startpos $endpos
      ::tk::TextSetCursor $txtt $cursorpos
    }

  }

  ######################################################################
  # Perform a title case conversion.
  proc transform_to_title_case {txtt startpos endpos {cursorpos insert}} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        convert_case_to_title $txtt [$txtt index "$startpos wordstart"] $endpos
      }
      ::tk::TextSetCursor $txtt $startpos
    } else {
      set str [$txtt get "insert wordstart" "insert wordend"]
      convert_case_to_title $txtt [$txtt index "$startpos wordstart"] $endpos
      ::tk::TextSetCursor $txtt $cursorpos
    }

  }

  ######################################################################
  # If a selection occurs, joins the selected lines; otherwise, joins the
  # number of specified lines.
  # TBD - Needs work
  proc transform_join_lines {txtt {num 1}} {

    # Specifies if at least one line was deleted in the join
    set deleted 0

    # Create a separator
    $txtt edit separator

    if {[llength [set selected [$txtt tag ranges sel]]] > 0} {

      # Clear the selection
      $txtt tag remove sel 1.0 end

      set lastpos ""
      foreach {endpos startpos} [lreverse $selected] {
        set lines [$txtt count -lines $startpos $endpos]
        for {set i 0} {$i < $lines} {incr i} {
          set line    [string trimleft [$txtt get "$startpos+1l linestart" "$startpos+1l lineend"]]
          $txtt delete "$startpos lineend" "$startpos+1l lineend"
          if {![string is space [$txtt get "$startpos lineend-1c"]]} {
            set line " $line"
          }
          if {$line ne ""} {
            $txtt insert "$startpos lineend" $line
          }
        }
        set deleted [expr $deleted || ($lines > 0)]
        if {$lastpos ne ""} {
          set line    [string trimleft [$txtt get "$lastpos linestart" "$lastpos lineend"]]
          $txtt delete "$lastpos-1l lineend" "$lastpos lineend"
          if {![string is space [$txtt get "$startpos lineend-1c"]]} {
            set line " $line"
          }
          $txtt insert "$startpos lineend" $line
        }
        set lastpos $startpos
      }

      set index [$txtt index "$startpos lineend-[string length $line]c"]

    } elseif {[$txtt compare "insert+1l" < end]} {

      for {set i 0} {$i < $num} {incr i} {
        set line    [string trimleft [$txtt get "insert+1l linestart" "insert+1l lineend"]]
        $txtt delete "insert lineend" "insert+1l lineend"
        if {![string is space [$txtt get "insert lineend-1c"]]} {
          set line " $line"
        }
        if {$line ne ""} {
          $txtt insert "insert lineend" $line
        }
      }

      set deleted [expr $num > 0]
      set index   [$txtt index "insert lineend-[string length $line]c"]

    }

    if {$deleted} {

      # Set the insertion cursor and make it viewable
      ::tk::TextSetCursor $txtt $index

      # Create a separator
      $txtt edit separator

    }

  }

  ######################################################################
  # Moves selected lines or the current line up by one line.
  proc transform_bubble_up {txtt} {

    # Create undo separator
    $txtt edit separator

    # If lines are selected, move all selected lines up one line
    if {[llength [set selected [$txtt tag ranges sel]]] > 0} {
      foreach {end_range start_range} [lreverse $selected] {
        set str [$txtt get "$start_range-1l linestart" "$start_range linestart"]
        $txtt delete "$start_range-1l linestart" "$start_range linestart"
        $txtt insert "$end_range+1l linestart" $str
      }

    # Otherwise, move the current line up by one line
    } else {
      set str [$txtt get "insert-1l linestart" "insert linestart"]
      $txtt delete "insert-1l linestart" "insert linestart"
      if {[$txtt compare "insert+1l linestart" == end]} {
        set str "\n[string trimright $str]"
      }
      $txtt insert "insert+1l linestart" $str
    }

    # Create undo separator
    $txtt edit separator

  }

  ######################################################################
  # Moves selected lines or the current line down by one line.
  proc transform_bubble_down {txtt} {

    # Create undo separator
    $txtt edit separator

    # If lines are selected, move all selected lines down one line
    if {[llength [set selected [$txtt tag ranges sel]]] > 0} {
      foreach {end_range start_range} [lreverse $selected] {
        set str [$txtt get "$end_range+1l linestart" "$end_range+2l linestart"]
        $txtt delete "$end_range lineend" "$end_range+1l lineend"
        $txtt insert "$start_range linestart" $str
      }

    # Otherwise, move the current line down by one line
    } else {
      set str [$txtt get "insert+1l linestart" "insert+2l linestart"]
      $txtt delete "insert lineend" "insert+1l lineend"
      $txtt insert "insert linestart" $str
    }

    # Create undo separator
    $txtt edit separator

  }

  ######################################################################
  # Saves the given selection to the specified filename.  If overwrite
  # is set to 1, the file will be written regardless of whether the file
  # already exists; otherwise, a message will be displayed that the file
  # already exists and the operation will end.
  proc save_selection {txt from to overwrite fname} {

    if {!$overwrite && [file exists $fname]} {
      gui::set_info_message [::format "%s (%s)" [msgcat::mc "Filename already exists"] $fname]
      return 0
    } else {
      if {[catch { open $fname w } rc]} {
        gui::set_info_message [::format "%s %s" [msgcat::mc "Unable to write"] $fname]
        return 0
      } else {
        puts $rc [$txt get $from $to]
        close $rc
        gui::set_info_message [::format "%s (%s)" [msgcat::mc "File successfully written"] $fname]
      }
    }

    return 1

  }

  ######################################################################
  # Comments out the currently selected text.
  proc comment_text {txt} {

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    # Get the comment syntax
    lassign [syntax::get_comments $txt] icomment lcomments bcomments

    # Insert comment lines/blocks
    foreach {endpos startpos} [lreverse $selected] {
      if {[llength $icomment] == 1} {
        set i 0
        foreach line [split [$txt get $startpos $endpos] \n] {
          if {$i == 0} {
            $txt insert $startpos "[lindex $icomment 0]"
            $txt tag add sel $startpos "$startpos lineend"
          } else {
            $txt insert "$startpos+${i}l linestart" "[lindex $icomment 0]"
          }
          incr i
        }
      } else {
        $txt insert $endpos   "[lindex $icomment 1]"
        $txt insert $startpos "[lindex $icomment 0]"
        if {[lindex [split $startpos .] 0] == [lindex [split $endpos .] 0]} {
          set endpos "$endpos+[expr [string length [lindex $icomment 0]] + [string length [lindex $icomment 1]]]c"
        } else {
          set endpos "$endpos+[string length [lindex $icomment 1]]c"
        }
        $txt tag add sel $startpos $endpos
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Comments out the currently selected text in the current text widget.
  proc comment {} {

    # Get the current text widget
    comment_text [gui::current_txt]

  }

  ######################################################################
  # Uncomments out the currently selected text in the specified text
  # widget.
  proc uncomment_text {txt} {

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    # Get the comment syntax
    lassign [syntax::get_comments $txt] icomment lcomments bcomments

    # Get the comment syntax to remove
    set comments [join [eval concat $lcomments $bcomments] |]

    # Strip out comment syntax
    foreach {endpos startpos} [lreverse $selected] {
      set linestart $startpos
      foreach line [split [$txt get $startpos $endpos] \n] {
        if {[regexp -indices -- "($comments)+?" $line -> com]} {
          set delstart [$txt index "$linestart+[lindex $com 0]c"]
          set delend   [$txt index "$linestart+[expr [lindex $com 1] + 1]c"]
          $txt delete $delstart $delend
        }
        set linestart [$txt index "$linestart+1l linestart"]
        incr i
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Uncomments out the currently selected text in the current text widget.
  proc uncomment {} {

    # Get the current text widget
    uncomment_text [gui::current_txt]

  }

  ######################################################################
  # Handles commenting/uncommenting either the currently selected code
  # or the current cursor.
  proc comment_toggle_text {txt} {

    # Create a separator
    $txt edit separator

    # Get various comments
    lassign [syntax::get_comments $txt] icomment lcomments bcomments

    # Get the current selection
    set selected 1
    if {[llength [set ranges [$txt tag ranges sel]]] == 0} {
      if {[llength [set mcursors [$txt tag ranges mcursor]]] > 0} {
        foreach {startpos endpos} $mcursors {
          lappend ranges [$txt index "$startpos linestart"] [$txt index "$startpos lineend"]
        }
      } elseif {[lsearch [$txt tag names insert] _cComment] != -1} {
        lassign [$txt tag prevrange _cComment insert] startpos endpos
        if {[regexp "^[lindex $bcomments 0 0](.*)[lindex $bcomments 0 1]\$" [$txt get $startpos $endpos] -> str]} {
          $txt replace $startpos $endpos $str
          $txt edit separator
        }
        return
      } else {
        set ranges [list [$txt index "insert linestart"] [$txt index "insert lineend"]]
      }
      set selected 0
    }

    # Iterate through each range
    foreach {endpos startpos} [lreverse $ranges] {
      if {![do_uncomment $txt $startpos $endpos]} {
        if {[llength $icomment] == 1} {
          set i 0
          foreach line [split [$txt get $startpos $endpos] \n] {
            if {$i == 0} {
              $txt insert $startpos "[lindex $icomment 0]"
              if {$selected} {
                $txt tag add sel $startpos "$startpos lineend"
              }
            } else {
              $txt insert "$startpos+${i}l linestart" "[lindex $icomment 0]"
            }
            incr i
          }
        } else {
          $txt insert $endpos   "[lindex $icomment 1]"
          $txt insert $startpos "[lindex $icomment 0]"
          if {$selected} {
            if {[lindex [split $startpos .] 0] == [lindex [split $endpos .] 0]} {
              set endpos "$endpos+[expr [string length [lindex $icomment 0]] + [string length [lindex $icomment 1]]]c"
            } else {
              set endpos "$endpos+[string length [lindex $icomment 1]]c"
            }
            $txt tag add sel $startpos $endpos
          }
        }
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Toggles the toggle status of the currently selected lines in the current
  # text widget.
  proc comment_toggle {} {

    # Get the current text widget
    comment_toggle_text [gui::current_txt]

  }

  ######################################################################
  # Determines if the given range can be uncommented.  If so, performs
  # the uncomment and returns 1; otherwise, returns 0.
  proc do_uncomment {txt startpos endpos} {

    set retval 0

    # Get the comment syntax
    lassign [syntax::get_comments $txt] icomment lcomments bcomments

    # Get the comment syntax to remove
    set comments [join [eval concat $lcomments $bcomments] |]

    set linestart $startpos
    foreach line [split [$txt get $startpos $endpos] \n] {
      if {[regexp -indices -- "($comments)+?" $line -> com]} {
        set delstart [$txt index "$linestart+[lindex $com 0]c"]
        set delend   [$txt index "$linestart+[expr [lindex $com 1] + 1]c"]
        $txt delete $delstart $delend
        set retval 1
      }
      set linestart [$txt index "$linestart+1l linestart"]
      incr i
    }

    return $retval

  }

  ######################################################################
  # Perform indentation on a specified range.
  proc do_indent {txtt startpos endpos} {

    # Get the indent spacing
    set indent_str [string repeat " " [indent::get_shiftwidth $txtt]]

    while {[$txtt index "$startpos linestart"] <= [$txtt index "$endpos linestart"]} {
      $txtt insert "$startpos linestart" $indent_str
      set startpos [$txtt index "$startpos linestart+1l"]
    }

  }

  ######################################################################
  # Perform unindentation on a specified range.
  proc do_unindent {txtt startpos endpos} {

    # Get the indent spacing
    set unindent_str [string repeat " " [indent::get_shiftwidth $txtt]]
    set unindent_len [string length $unindent_str]

    while {[$txtt index "$startpos linestart"] <= [$txtt index "$endpos linestart"]} {
      if {[regexp "^$unindent_str" [$txtt get "$startpos linestart" "$startpos lineend"]]} {
        $txtt delete "$startpos linestart" "$startpos linestart+${unindent_len}c"
      }
      set startpos [$txtt index "$startpos linestart+1l"]
    }

  }

  ######################################################################
  # If text is selected, performs one level of indentation.  Returns 1 if
  # text was selected; otherwise, returns 0.
  proc indent_selected {txtt} {

    if {[llength [set range [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $range] {
        do_indent $txtt $startpos $endpos
      }
      ::tk::TextSetCursor $txtt [get_index $txtt firstchar -startpos $startpos -num 0]
      return 1
    }

    return 0

  }

  ######################################################################
  # Indents the selected text of the current text widget by one
  # indentation level.
  proc indent {txtt {startpos "insert"} {endpos "insert"}} {

    if {![indent_selected $txtt]} {
      do_indent $txtt $startpos $endpos
      ::tk::TextSetCursor $txtt [get_index $txtt firstchar -startpos $startpos -num 0]
    }

  }

  ######################################################################
  # If text is selected, unindents the selected lines by one level and
  # return a value of 1; otherwise, return a value of 0.
  proc unindent_selected {txtt} {

    if {[llength [set range [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $range] {
        do_unindent $txtt $startpos $endpos
      }
      ::tk::TextSetCursor $txtt [get_index $txtt firstchar -startpos $startpos -num 0]
      return 1
    }

    return 0

  }

  ######################################################################
  # Unindents the selected text of the current text widget by one
  # indentation level.
  proc unindent {txtt {startpos "insert"} {endpos "insert"}} {

    if {![unindent_selected $txtt]} {
      do_unindent $txtt $startpos $endpos
      ::tk::TextSetCursor $txtt [get_index $txtt firstchar -startpos $startpos -num 0]
    }

  }

  ######################################################################
  # Replaces the current line with the output contents of it as a script.
  proc replace_line_with_script {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the current line
    set cmd [$txt get "insert linestart" "insert lineend"]

    # Execute the line text
    catch { exec -ignorestderr {*}$cmd } rc

    # Replace the line with the given text
    $txt replace "insert linestart" "insert lineend" $rc

  }

  ######################################################################
  # Returns true if the current line is empty; otherwise, returns false.
  proc current_line_empty {} {

    # Get the current text widget
    set txt [gui::current_txt]

    return [expr {[$txt get "insert linestart" "insert lineend"] eq ""}]

  }

  ######################################################################
  # Aligns the current cursors such that all cursors will be aligned to
  # the cursor closest to the start of its line.
  proc align_cursors {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Align multicursors only
    multicursor::align $txt

  }

  ######################################################################
  # Aligns the current cursors, keeping each multicursor locked to its
  # text.
  proc align_cursors_and_text {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Align multicursors
    multicursor::align_with_text $txt

  }

  ######################################################################
  # Inserts an enumeration when in multicursor mode.
  proc insert_enumeration {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Perform the insertion
    gui::insert_numbers $txt

  }

  ######################################################################
  # Jumps to the given line number.
  proc jump_to_line {txt linenum} {

    # Set the insertion cursor to the given line number
    ::tk::TextSetCursor $txt $linenum

    # Adjust the insertion cursor
    vim::adjust_insert $txt

  }

  ######################################################################
  # Returns the index of the character located num chars in the direction
  # specified from the starting index.
  proc get_char {txt dir {num 1} {start insert}} {

    if {$dir eq "next"} {

      while {($num > 0) && [$txt compare $start < end-2c]} {
        if {[set line_chars [$txt count -displaychars $start "$start lineend"]] == 0} {
          set start [$txt index "$start+1 display lines"]
          set start "$start linestart"
          incr num -1
        } elseif {$line_chars <= $num} {
          set start [$txt index "$start+1 display lines"]
          set start "$start linestart"
          incr num -$line_chars
        } else {
          set start "$start+$num display chars"
          set num 0
        }
      }

      return [$txt index $start]

    } else {

      set first 1
      while {($num > 0) && [$txt compare $start > 1.0]} {
        if {([set line_chars [$txt count -displaychars "$start linestart" $start]] == 0) && !$first} {
          if {[incr num -1] > 0} {
            set start [$txt index "$start-1 display lines"]
            set start "$start lineend"
          }
        } elseif {$line_chars < $num} {
          set start [$txt index "$start-1 display lines"]
          set start "$start lineend"
          incr num -$line_chars
        } else {
          set start "$start-$num display chars"
          set num 0
        }
        set first 0
      }

      return [$txt index $start]

    }

  }

  ######################################################################
  # Returns the index of the beginning next/previous word.  If num is
  # given a value > 1, the procedure will return the beginning index of
  # the next/previous num'th word.  If no word was found, return the index
  # of the current word.
  proc get_wordstart {txt dir {num 1} {start insert} {exclusive 0}} {

    # If the direction is 'next', search forward
    if {$dir eq "next"} {

      # Get the end of the current word (this will be the beginning of the next word)
      set curr_index [$txt index "$start display wordend"]
      set last_index $curr_index

      # This works around a text issue with wordend
      if {[$txt count -displaychars $curr_index "$curr_index+1c"] == 0} {
        set curr_index [$txt index "$curr_index display wordend"]
      }

      # If num is 0, do not continue
      if {$num <= 0} {
        return $curr_index
      }

      # Use a brute-force method of finding the next word
      while {[$txt compare $curr_index < end]} {
        if {![string is space [$txt get $curr_index]]} {
          if {[incr num -1] == 0} {
            return [$txt index "$curr_index display wordstart"]
          }
        } elseif {[$txt compare "$curr_index linestart" == "$curr_index lineend"] && $exclusive} {
          if {[incr num -1] == 0} {
            return [$txt index "$curr_index display wordstart"]
          }
        } elseif {!$exclusive && ([string first "\n" [$txt get $last_index $curr_index]] != -1) && ($num == 1)} {
          return $curr_index
        }
        set last_index $curr_index
        set curr_index [$txt index "$curr_index display wordend"]
      }

      return [$txt index "$curr_index display wordstart"]

    } else {

      # Get the index of the current word
      set curr_index [$txt index "$start display wordstart"]

      # If num is 0, do not continue
      if {$num <= 0} {
        return $curr_index
      }

      while {[$txt compare $curr_index > 1.0]} {
        if {(![string is space [$txt get $curr_index]] || [$txt compare "$curr_index linestart" == "$curr_index lineend"]) && \
             [$txt compare $curr_index != $start]} {
          if {[incr num -1] == 0} {
            return $curr_index
          }
        }
        set curr_index [$txt index "$curr_index-1 display chars wordstart"]
      }

      return $curr_index

    }

  }

  ######################################################################
  # Returns the index of the ending next/previous word.  If num is
  # given a value > 1, the procedure will return the beginning index of
  # the next/previous num'th word.  If no word was found, return the index
  # of the current word.
  proc get_wordend {txt dir {num 1} {start insert} {exclusive 0}} {

    if {$dir eq "next"} {

      set curr_index [$txt index "$start display wordend"]
      set last_index $curr_index

      while {[$txt compare $curr_index < end]} {
        if {![string is space [$txt get $curr_index-1c]] && ([$txt compare "$curr_index-1c" != $start] || ($exclusive == 0))} {
          if {[incr num -1] == 0} {
            return [$txt index "$curr_index-1c"]
          }
        } elseif {[$txt compare "$curr_index linestart" == "$curr_index lineend"] && $exclusive} {
          if {[incr num -1] == 0} {
            return $curr_index
          }
        } elseif {([string first "\n" [$txt get $last_index $curr_index]] != -1) && !$exclusive && ($num == 1)} {
          return $curr_index
        }
        set last_index $curr_index
        set curr_index [$txt index "$curr_index display wordend"]
      }

      return [$txt index "$curr_index display wordend"]

    } else {

      # Get the index of the current wordstart
      set curr_index [$txt index "$start display wordstart"]

      # If num is 0, do not continue
      if {$num <= 0} {
        return [$txt index "$curr_index-1c"]
      }

      while {[$txt compare $curr_index > 1.0]} {
        if {![string is space [$txt get $curr_index-1c]]} {
          if {[incr num -1] == 0} {
            return [$txt index "$curr_index-1c"]
          }
        } elseif {[$txt compare "$curr_index linestart" == "$curr_index lineend"]} {
          if {[incr num -1] == 0} {
            return $curr_index
          }
        }
        set curr_index [$txt index "$curr_index-1 display chars wordstart"]
      }

      return $curr_index

    }

  }

  ######################################################################
  # Returns the index of the start of a Vim WORD (any character that is
  # preceded by whitespace, the first character of a line, or an empty
  # line.
  proc get_WORDstart {txtt dir {num 1} {start insert} {exclusive 0}} {

    if {$dir eq "next"} {
      set diropt   "-forwards"
      set startpos $start
      set endpos   "end"
      set suffix   "+1c"
    } else {
      set diropt   "-backwards"
      set startpos "$start-1c"
      set endpos   "1.0"
      set suffix   ""
    }

    while {[set index [$txtt search $diropt -regexp -- {\s\S|\n\n} $startpos $endpos]] ne ""} {
      if {[incr num -1] == 0} {
        return [$txtt index $index+1c]
      }
      set startpos "$index$suffix"
    }

    return $start

  }

  ######################################################################
  # Returns the index of the end of a Vim WORD (any character that is
  # succeeded by whitespace, the last character of a line or an empty line.
  proc get_WORDend {txtt dir {num 1} {start insert} {exclusive 0}} {

    if {$dir eq "next"} {
      set diropt   "-forwards"
      set startpos "$start+1c"
      set endpos   "end"
      set suffix   "+1c"
    } else {
      set diropt   "-backwards"
      set startpos $start
      set endpos   "1.0"
      set suffix   ""
    }

    while {[set index [$txtt search $diropt -regexp -- {\S\s|\n\n} $startpos $endpos]] ne ""} {
      if {[$txtt get $index] eq "\n"} {
        if {[incr num -1] == 0} {
          return [$txtt index $index+1c]
        }
      } else {
        if {[incr num -1] == 0} {
          return [$txtt index $index]
        }
      }
      set startpos "$index$suffix"
    }

    return $start

  }

  ######################################################################
  # Returns the starting index of the given character.
  proc find_char {txtt dir char num startpos exclusive} {

    # Perform the character search
    if {$dir eq "next"} {
      set indices [$txtt search -all -- $char "$startpos+1c" "$startpos lineend"]
      if {[set index [lindex $indices [expr $num - 1]]] eq ""} {
        set index "insert"
      } elseif {$exclusive} {
        set index "$index-1c"
      }
    } else {
      set indices [$txtt search -all -- $char "$startpos linestart" insert]
      if {[set index [lindex $indices end-[expr $num - 1]]] eq ""} {
        set index "insert"
      } elseif {$exclusive} {
        set index "$index+1c"
      }
    }

    return $index

  }

  ######################################################################
  # Returns the exclusive position of the given character search.
  proc between_char {txtt dir char {startpos "insert"}} {

    array set pairs {
      \{ {\\\} L}
      \} {\\\{ R}
      \( {\\\) L}
      \) {\\\( R}
      \[ {\\\] L}
      \] {\\\[ R}
      <  {> L}
      >  {< R}
    }

    # Get the matching character
    if {[info exists pairs($char)]} {
      if {[lindex $pairs($char) 1] eq "R"} {
        if {$dir eq "prev"} {
          set index [gui::find_match_pair $txtt [lindex $pairs($char) 0] \\$char -backwards]
        } else {
          set index [gui::find_match_pair $txtt \\$char [lindex $pairs($char) 0] -forwards]
        }
      } else {
        if {$dir eq "prev"} {
          set index [gui::find_match_pair $txtt \\$char [lindex $pairs($char) 0] -backwards]
        } else {
          set index [gui::find_match_pair $txtt [lindex $pairs($char) 0] \\$char -forwards]
        }
      }
    } else {
      if {$dir eq "prev"} {
        set index [gui::find_match_char $txtt $char -backwards]
      } else {
        set index [gui::find_match_char $txtt $char -forwards]
      }
    }

    if {$index == -1} {
      return [expr {($dir eq "prev") ? 1.0 : "end-1c"}]
    } else {
      return [expr {($dir eq "prev") ? "$index+1c" : $index}]
    }

  }

  ######################################################################
  # Gets the previous or next sentence as defined by the Vim specification.
  proc get_sentence {txtt dir num {startpos "insert"}} {

    variable patterns

    # Search for the end of the previous sentence
    set index [$txtt search -backwards -count lengths -regexp -- $patterns(sentence) $startpos 1.0]

    if {$dir eq "next"} {

      # If we could not find the end of a previous sentence, find the first
      # non-whitespace character in the file and if it is after the startpos,
      # return the index.
      if {($index eq "") && ([set index [$txtt search -forwards -regexp -- {\S} 1.0 end-1c]] ne "")} {
        if {[$txtt compare $index > $startpos] && ([incr num -1] == 0)} {
          return $index
        }
        set index ""
      }

      if {($index ne "") && [$txtt compare $startpos < "$index+[expr [lindex $lengths 0] - 1]c"]} {
        set startpos $index
      }

      while {[set index [$txtt search -forwards -count lengths -regexp -- $patterns(sentence) $startpos end]] ne ""} {
        set startpos [$txtt index "$index+[expr [lindex $lengths 0] - 1]c"]
        if {[incr num -1] == 0} {
          return $startpos
        }
      }

      return "end-1c"

    } else {

      if {($index ne "") && [$txtt compare $startpos <= "$index+[expr [lindex $lengths 0] - 1]c"]} {
        set startpos $index
      }

      while {[set index [$txtt search -backwards -count lengths -regexp -- $patterns(sentence) $startpos-1c 1.0]] ne ""} {
        set startpos $index
        if {[incr num -1] == 0} {
          return [$txtt index "$index+[expr [lindex $lengths 0] - 1]c"]
        }
      }

      if {([incr num -1] == 0) && \
          ([set index [$txtt search -forwards -regexp -- {\S} 1.0 end-1c]] ne "") && \
          ([$txtt compare $index < $startpos])} {
        return $index
      } else {
        return "1.0"
      }

    }

  }

  ######################################################################
  # Find the next or previous paragraph.
  proc get_paragraph {txtt dir num {start insert}} {

    if {$dir eq "next"} {

      set nl 0
      while {[$txtt compare $start < end-1c]} {
        if {([$txtt get "$start linestart" "$start lineend"] eq "") || \
            ([lsearch [$txtt tag names $start] dspace] != -1)} {
          set nl 1
        } elseif {$nl && ([incr num -1] == 0)} {
          return "$start linestart"
        } else {
          set nl 0
        }
        set start [$txtt index "$start+1 display lines"]
      }

      return [$txtt index end-1c]

    } else {

      # If the start position is in the first column adjust the starting
      # line to the line above to avoid matching ourselves
      if {[$txtt compare $start == "$start linestart"]} {
        set start [$txtt index "$start-1 display lines"]
      }

      set nl 1
      while {[$txtt compare $start > 1.0]} {
        if {([$txtt get "$start linestart" "$start lineend"] ne "") && \
            ([lsearch [$txtt tag names $start] dspace] == -1)} {
          set nl 0
        } elseif {!$nl && ([incr num -1] == 0)} {
          return [$txtt index "$start+1 display lines linestart"]
        } else {
          set nl 1
        }
        set start [$txtt index "$start-1 display lines"]
      }

      if {(([$txtt get "$start linestart" "$start lineend"] eq "") || \
           ([lsearch [$txtt tag names $start] dspace] != -1)) && !$nl && \
          ([incr num -1] == 0)} {
        return [$txtt index "$start+1 display lines linestart"]
      } else {
        return 1.0
      }

    }

  }

  ######################################################################
  # Returns the index of the requested permission.
  # - left       Move the cursor to the left on the current line
  # - right      Move the cursor to the right on the current line
  # - first      First line in file
  # - last       Last line in file
  # - nextchar   Next character
  # - prevchar   Previous character
  # - firstchar  First character of the line
  # - lastchar   Last character of the line
  # - nextword   Beginning of next word
  # - prevword   Beginning of previous word
  # - nextfirst  Beginning of first word in next line
  # - prevfirst  Beginning of first word in previous line
  # - column     Move the cursor to the specified column in the current line
  # - linestart  Start of current line
  # - lineend    End of current line
  # - screentop  Top of current screen
  # - screenmid  Middle of current screen
  # - screenbot  Bottom of current screen
  proc get_index {txtt position args} {

    variable patterns

    array set opts {
      -dir       "next"
      -startpos  "insert"
      -num       1
      -char      ""
      -exclusive 0
      -column    ""
      -adjust    ""
    }
    array set opts $args

    # Create a default index to use
    set index $opts(-startpos)

    # Get the new cursor position
    switch $position {
      left        {
        if {[$txtt compare "$opts(-startpos) display linestart" > "$opts(-startpos)-$opts(-num) display chars"]} {
          set index "$opts(-startpos) display linestart"
        } else {
          set index "$opts(-startpos)-$opts(-num) display chars"
        }
      }
      right       {
        if {[$txtt compare "$opts(-startpos) display lineend" < "$opts(-startpos)+$opts(-num) display chars"]} {
          set index "$opts(-startpos) display lineend"
        } else {
          set index "$opts(-startpos)+$opts(-num) display chars"
        }
      }
      up          {
        if {[set $opts(-column)] eq ""} {
          set $opts(-column) [lindex [split [$txtt index $opts(-startpos)] .] 1]
        }
        set index $opts(-startpos)
        for {set i 0} {$i < $opts(-num)} {incr i} {
          set index [$txtt index "$index linestart-1 display lines"]
        }
        set index [lindex [split $index .] 0].[set $opts(-column)]
      }
      down        {
        if {[set $opts(-column)] eq ""} {
          set $opts(-column) [lindex [split [$txtt index $opts(-startpos)] .] 1]
        }
        set index $opts(-startpos)
        for {set i 0} {$i < $opts(-num)} {incr i} {
          if {[$txtt compare [set index [$txtt index "$index lineend+1 display lines"]] == end]} {
            set index [$txtt index "end-1c"]
            break
          }
        }
        set index [lindex [split $index .] 0].[set $opts(-column)]
      }
      first       {
        if {[$txtt get -displaychars 1.0] eq ""} {
          set index "1.0+1 display chars"
        } else {
          set index "1.0"
        }
      }
      last          { set index "end" }
      char          { set index [get_char $txtt $opts(-dir) $opts(-num) $opts(-startpos)] }
      dchar         {
        if {$opts(-dir) eq "next"} {
          set index "$opts(-startpos)+$opts(-num) display chars"
        } else {
          set index "$opts(-startpos)-$opts(-num) display chars"
        }
      }
      findchar      { set index [find_char $txtt $opts(-dir) $opts(-char) $opts(-num) $opts(-startpos) $opts(-exclusive)] }
      betweenchar   { set index [between_char $txtt $opts(-dir) $opts(-char) $opts(-startpos)] }
      firstchar     {
        if {$opts(-num) == 0} {
          set index $opts(-startpos)
        } elseif {$opts(-dir) eq "next"} {
          if {[$txtt compare [set index [$txtt index "$opts(-startpos)+$opts(-num) display lines"]] == end]} {
            set index [$txtt index "$index-1 display lines"]
          }
        } else {
          set index [$txtt index "$opts(-startpos)-$opts(-num) display lines"]
        }
        if {[lsearch [$txtt tag names "$index linestart"] _prewhite] != -1} {
          set index [lindex [$txtt tag nextrange _prewhite "$index linestart"] 1]-1c
        } else {
          set index "$index lineend"
        }
      }
      lastchar      {
        set line  [expr [lindex [split [$txtt index $opts(-startpos)] .] 0] + ($opts(-num) - 1)]
        set index "$line.0+[string length [string trimright [$txtt get $line.0 $line.end]]]c"
      }
      wordstart     { set index [get_wordstart $txtt $opts(-dir) $opts(-num) $opts(-startpos) $opts(-exclusive)] }
      wordend       { set index [get_wordend   $txtt $opts(-dir) $opts(-num) $opts(-startpos) $opts(-exclusive)] }
      WORDstart     { set index [get_WORDstart $txtt $opts(-dir) $opts(-num) $opts(-startpos) $opts(-exclusive)] }
      WORDend       { set index [get_WORDend   $txtt $opts(-dir) $opts(-num) $opts(-startpos) $opts(-exclusive)] }
      column        { set index [lindex [split [$txtt index $opts(-startpos)] .] 0].[expr $opts(-num) - 1] }
      linenum       {
        if {[lsearch [$txtt tag names "$opts(-num).0"] _prewhite] != -1} {
          set index [lindex [$txtt tag nextrange _prewhite "$opts(-num).0"] 1]-1c
        } else {
          set index "$opts(-num).0 lineend"
        }
      }
      linestart     {
        if {$opts(-num) > 1} {
          if {[$txtt compare [set index [$txtt index "$opts(-startpos)+[expr $opts(-num) - 1] display lines linestart"]] == end]} {
            set index "end"
          } else {
            set index "$index+1 display chars"
          }
        } else {
          set index [$txtt index "$opts(-startpos) linestart+1 display chars"]
        }
        if {[$txtt compare "$index-1 display chars" >= "$index linestart"]} {
          set index "$index-1 display chars"
        }
      }
      lineend       {
        if {$opts(-num) == 1} {
          set index "$opts(-startpos) lineend"
        } else {
          set index [$txtt index "$opts(-startpos)+[expr $opts(-num) - 1] display lines"]
          set index "$index lineend"
        }
      }
      dispstart     { set index "@0,[lindex [$txtt bbox $opts(-startpos)] 1]" }
      dispmid       { set index "@[expr [winfo width $txtt] / 2],[lindex [$txtt bbox $opts(-startpos)] 1]" }
      dispend       { set index "@[winfo width $txtt],[lindex [$txtt bbox $opts(-startpos)] 0]" }
      sentence      { set index [get_sentence  $txtt $opts(-dir) $opts(-num) $opts(-startpos)] }
      paragraph     { set index [get_paragraph $txtt $opts(-dir) $opts(-num) $opts(-startpos)] }
      screentop     { set index "@0,0" }
      screenmid     { set index "@0,[expr [winfo height $txtt] / 2]" }
      screenbot     { set index "@0,[winfo height $txtt]" }
      numberstart   {
        if {[regexp $patterns(pnumber) [$txtt get "$opts(-startpos) linestart" $opts(-startpos)] match]} {
          set index "$opts(-startpos)-[string length $match]c"
        }
      }
      numberend     {
        if {[regexp $patterns(nnumber) [$txtt get $opts(-startpos) "$opts(-startpos) lineend"] match]} {
          set index "$opts(-startpos)+[string length $match]c"
        }
      }
      spacestart    {
        if {[regexp $patterns(pspace) [$txtt get "$opts(-startpos) linestart" $opts(-startpos)] match]} {
          set index "$opts(-startpos)-[string length $match]c"
        }
      }
      spaceend      {
        if {[regexp $patterns(nspace) [$txtt get $opts(-startpos) "$opts(-startpos) lineend"] match]} {
          set index "$opts(-startpos)+[string length $match]c"
        }
      }
      tagstart      {
        set insert [$txtt index insert]
        while {[set ranges [emmet::get_node_range [winfo parent $txtt]]] ne ""} {
          if {[incr opts(-num) -1] == 0} {
            set index [expr {$opts(-exclusive) ? [lindex $ranges 1] : [lindex $ranges 0]}]
            break
          } else {
            $txtt mark set insert "[lindex $ranges 0]-1c"
          }
        }
        $txtt mark set insert $insert
      }
      tagend        {
        set insert [$txtt index insert]
        while {[set ranges [emmet::get_node_range [winfo parent $txtt]]] ne ""} {
          if {[incr opts(-num) -1] == 0} {
            set index [expr {$opts(-exclusive) ? [lindex $ranges 2] : [lindex $ranges 3]}]
            break
          } else {
            $txtt mark set insert "[lindex $ranges 0]-1c"
          }
        }
        $txtt mark set insert $insert
      }
    }

    # Make any necessary adjustments, if needed
    if {($index ne $opts(-startpos)) && ($opts(-adjust) ne "")} {
      set index [$txtt index "$index$opts(-adjust)"]
    }

    return $index

  }

  ######################################################################
  # Handles word/WORD range motions.
  proc get_range_word {txtt type num inner adjust} {

    set start insert

    if {$inner} {

      # Get the starting position of the selection
      if {[string is space [$txtt get insert]]} {
        set startpos [get_index $txtt spacestart -dir prev -startpos "insert+1c"]
      } else {
        set startpos [get_index $txtt ${type}start -dir prev -startpos "insert+1c"]
      }

      # Count spaces and non-spaces
      set endpos "insert-1c"
      for {set i 0} {$i < $num} {incr i} {
        puts "i: $i, endpos: [$txtt index $endpos]"
        if {[string is space [$txtt get $endpos]]} {
          puts "  in space"
          set endpos [get_index $txtt spaceend -dir next -startpos $endpos]
        } else {
          set endpos [$txtt index "[get_index $txtt ${type}end -dir next -startpos $endpos]+1c"]
        }
      }

      puts "endpos: [$txtt index $endpos]"

      set pos_list [list $startpos $endpos]
      puts "pos_list: $pos_list"

    } else {


    }

    if {[string is space [$txtt get insert]]} {
      set pos_list [list [get_index $txtt spacestart -dir prev -startpos "insert+1c"] [get_index $txtt spaceend -dir next -adjust "-1c"]]
    } else {
      set pos_list [list [get_index $txtt $start -dir prev -startpos "insert+1c"] [get_index $txtt $end -dir next -num $num]]
    }

    if {!$inner} {
      set index [$txtt search -forwards -regexp -- {\S} "[lindex $pos_list 1]+1c" "[lindex $pos_list 1] lineend"]
      if {($index ne "") && [$txtt compare "[lindex $pos_list 1]+1c" != $index]} {
        lset pos_list 1 [$txtt index "$index-1c"]
      } else {
        set index [$txtt search -backwards -regexp -- {\S} [lindex $pos_list 0] "[lindex $pos_list 0] linestart"]
        if {($index ne "") && [$txtt compare "[lindex $pos_list 0]-1c" != $index]} {
          lset pos_list 0 [$txtt index "$index+1c"]
        }
      }
    }

    lset pos_list 1 [$txtt index "[lindex $pos_list 1]$adjust"]

    return $pos_list

  }

  ######################################################################
  # Handles WORD range motion.
  proc get_range_WORD {txtt num inner adjust} {

    if {[string is space [$txtt get insert]]} {
      set pos_list [list [get_index $txtt spacestart -dir prev -startpos "insert+1c"] [get_index $txtt spaceend -dir next -adjust "-1c"]]
    } else {
      set pos_list [list [get_index $txtt $start -dir prev -startpos "insert+1c"] [get_index $txtt $end -dir next -num $num]]
    }

    if {!$inner} {
      set index [$txtt search -forwards -regexp -- {\S} "[lindex $pos_list 1]+1c" "[lindex $pos_list 1] lineend"]
      if {($index ne "") && [$txtt compare "[lindex $pos_list 1]+1c" != $index]} {
        lset pos_list 1 [$txtt index "$index-1c"]
      } else {
        set index [$txtt search -backwards -regexp -- {\S} [lindex $pos_list 0] "[lindex $pos_list 0] linestart"]
        if {($index ne "") && [$txtt compare "[lindex $pos_list 0]-1c" != $index]} {
          lset pos_list 0 [$txtt index "$index+1c"]
        }
      }
    }

    lset pos_list 1 [$txtt index "[lindex $pos_list 1]$adjust"]

    return $pos_list

  }
  ######################################################################
  # Returns a range the is split by sentences.
  proc get_range_sentences {txtt type num inner adjust} {

    set pos_list [list [get_index $txtt $type -dir prev -startpos "insert+1c"] [get_index $txtt $type -dir next -num $num]]

    if {$inner} {
      set str  [$txtt get {*}$pos_list]
      set less [expr ([string length $str] - [string length [string trimright $str]]) + 1]
    } else {
      set less 1
    }

    lset pos_list 1 [$txtt index "[lindex $pos_list 1]-${less}c"]

    return $pos_list

  }

  ######################################################################
  # Returns the text range for a bracketed block of text.
  proc get_range_block {txtt type num inner adjust} {

    # Search backwards
    set txt      [winfo parent $txtt]
    set number   $num
    set startpos insert
    while {[set index [ctext::get_match_bracket $txt ${type}L $startpos]] != -1} {
      if {[incr number -1] == 0} {
        set right [ctext::get_match_bracket $txt ${type}R $index]
        return [expr {$inner ? [list [$txt index "$index+1c"] [$txt index "$right-1c$adjust"]] : [list $index [$txt index "$right$adjust"]]}]
      } else {
        set startpos $index
      }
    }

    return [list "" ""]

  }

  ######################################################################
  # Returns the text range for the given string type.
  proc get_range_string {txtt char tag inner adjust} {

    if {[$txtt get insert] eq $char} {
      if {[lsearch [$txtt tag names insert-1c] $tag] == -1} {
        set index [gui::find_match_char [winfo parent $txt] $char -forwards]
        return [expr {$inner ? [list [$txtt index "insert+1c"] [$txtt index "$index-1c$adjust"]] : [list [$txtt index insert] [$txtt index "$index$adjust"]]}]
      } else {
        set index [gui::find_match_char [winfo parent $txt] $char -backwards]
        return [expr {$inner ? [list [$txtt index "$index+1c"] [$txtt index "insert-1c$adjust"]] : [list $index [$txtt index "insert$adjust"]]}]
      }
    } elseif {[set tag [lsearch -inline [$txtt tag names insert] _${tag}*]] ne ""} {
      lassign [$txtt tag prevrange $tag insert] startpos endpos
      return [expr {$inner ? [list [$txtt index "$startpos+1c"] [$txtt index "$endpos-2c$adjust"]] : [list $startpos [$txtt index "$endpos-1c$adjust"]]}]
    }

    return [list "" ""]

  }

  ######################################################################
  # Returns the startpos/endpos range based on the supplied arguments.
  proc get_range {txtt pos1args pos2args object move {cursor insert}} {

    if {$object ne ""} {

      set type   [lindex $pos1args 0]
      set num    [lindex $pos1args 1]
      set inner  [expr {$object eq "i"}]
      set adjust [expr {$move ? "" : "+1c"}]

      switch [lindex $pos1args 0] {
        "word"      { return [get_range_word $txtt word $num $inner $adjust] }
        "WORD"      { return [get_range_word $txtt WORD $num $inner $adjust] }
        "paragraph" { return [get_range_sentences $txtt paragraph $num $inner $adjust] }
        "sentence"  { return [get_range_sentences $txtt sentence  $num $inner $adjust] }
        "tag"       {
          set insert [$txtt index insert]
          while {[set ranges [emmet::get_node_range [winfo parent $txtt]]] ne ""} {
            if {[incr num -1] == 0} {
              $txtt mark set insert $insert
              if {$inner} {
                return [list [lindex $ranges 1] [$txtt index "[lindex $ranges 2]$adjust"]]
              } else {
                return [list [lindex $ranges 0] [$txtt index "[lindex $ranges 3]$adjust"]]
              }
            } else {
              $txtt mark set insert "[lindex $ranges 0]-1c"
            }
          }
          $txtt mark set insert $insert
        }
        "paren"  -
        "curly"  -
        "square" -
        "angled" { return [get_range_block $txtt $type $num $inner $adjust] }
        "double" { return [get_range_string $txtt \" comstr0d $inner $adjust] }
        "single" { return [get_range_string $txtt \' comstr0s $inner $adjust] }
        "btick"  { return [get_range_string $txtt \` comstr0b $inner $adjust] }
      }

    } else {

      set pos1 [$txtt index [edit::get_index $txtt {*}$pos1args -startpos $cursor]]

      if {$pos2args ne ""} {
        set pos2 [$txtt index [edit::get_index $txtt {*}$pos2args -startpos $cursor]]
      } else {
        set pos2 [$txtt index $cursor]
      }

      # Return the start/end position in the correct order.
      return [expr {[$txtt compare $pos1 < $pos2] ? [list $pos1 $pos2] : [list $pos2 $pos1]}]

    }

  }

  ######################################################################
  # Moves the cursor to the given position
  proc move_cursor {txtt position args} {

    # Get the index to move to
    set index [get_index $txtt $position {*}$args]

    # Set the insertion position and make it visible
    ::tk::TextSetCursor $txtt $index

    # Adjust the insertion cursor in Vim mode
    vim::adjust_insert $txtt

  }

  ######################################################################
  # Moves the cursor up/down by a single page.  Valid values for dir are:
  # - Next
  # - Prior
  proc move_cursor_by_page {txtt dir} {

    # Adjust the view
    eval [string map {%W $txtt} [bind Text <[string totitle $dir]>]]

    # Adjust the insertion cursor in Vim mode
    vim::adjust_insert $txtt

  }

  ######################################################################
  # Moves multicursors in the modifier direction for the given text widget.
  proc move_cursors {txtt modifier} {

    # Clear the selection
    $txtt tag remove sel 1.0 end

    # Adjust the cursors
    multicursor::move $txtt $modifier

  }

  ######################################################################
  # Applies the specified formatting to the given text widget.
  proc format {txtt type} {

    # Get the range of lines to modify
    if {[set ranges [$txtt tag ranges sel]] eq ""} {
      if {[multicursor::enabled $txtt]} {
        foreach {start end} [$txtt tag ranges mcursor] {
          if {[string trim [$txtt get "$start wordstart" "$start wordend"]] ne ""} {
            lappend ranges [$txtt index "$start wordstart"] [$txtt index "$start wordend"]
          } else {
            lappend ranges $start $start
          }
        }
      } else {
        if {[string trim [$txtt get "insert wordstart" "insert wordend"]] ne ""} {
          set ranges [list [$txtt index "insert wordstart"] [$txtt index "insert wordend"]]
        } else {
          set ranges [list [$txtt index "insert"] [$txtt index "insert"]]
        }
      }
    }

    if {[llength $ranges] > 0} {

      # Get the formatting information for the current text widget
      array set formatting [syntax::get_formatting [winfo parent $txtt]]

      if {[info exists formatting($type)]} {

        lassign $formatting($type) stype startchars endchars

        $txtt edit separator

        set insert [$txtt index insert]

        if {$stype eq "line"} {
          set last ""
          foreach {end start} [lreverse $ranges] {
            if {($last eq "") || [$txtt compare "$start linestart" != "$last linestart"]} {
              while {[$txtt compare $start < $end]} {
                $txtt insert "$start linestart" $startchars
                set last  $start
                set start [$txtt index "$start+1l"]
              }
            }
          }
        } elseif {$endchars ne ""} {
          foreach {end start} [lreverse $ranges] {
            $txtt insert $end $endchars
            if {[$txtt compare $insert != insert]} {
              $txtt mark set insert $insert
            }
            $txtt insert $start $startchars
          }
        } else {
          foreach {end start} [lreverse $ranges] {
            $txtt insert $start $startchars
          }
        }

        $txtt edit separator

      }

    }

  }

  ######################################################################
  # Removes any applied text formatting found in the selection or (if no
  # text is currently selected the current line).
  proc unformat {txtt} {

    # Get the formatting information for the current text widget
    array set formatting [syntax::get_formatting [winfo parent $txtt]]

    # Get the range of lines to check
    if {[set ranges [$txtt tag ranges sel]] eq ""} {
      if {[multicursor::enabled $txtt]} {
        set last ""
        foreach {start end} [$txtt tag ranges mcursor] {
          if {($last eq "") || [$txtt compare "$start linestart" != "$last linestart"]} {
            lappend ranges [$txtt index "$start linestart"] [$txtt index "$start lineend"]
            set last $start
          }
        }
      } else {
        set ranges [list [$txtt index "insert linestart"] [$txtt index "insert lineend"]]
      }
    }

    # If we have at least one range to unformat, go for it
    if {[llength $ranges] > 0} {

      $txtt edit separator

      foreach {type chars} [array get formatting] {
        lassign $chars stype startchars endchars
        if {$stype eq "line"} {
          set startlen [string length $startchars]
          foreach {end start} [lreverse $ranges] {
            if {[$txtt get "$start linestart" "$start linestart+${startlen}c"] eq $startchars} {
              $txtt delete "$start linestart" "$start linestart+${startlen}c"
              lappend new_ranges [$txtt index $end-${startlen}c] $start
            } else {
              lappend new_ranges $end $start
            }
          }
        } elseif {$endchars ne ""} {
          set pattern  ""
          set startlen [string length $startchars]
          set endlen   [string length $endchars]
          append pattern [string map {\{ \\\{ \} \\\} * \\* + \\+ \\ \\\\} $startchars] ".+?" [string map {\{ \\\{ \} \\\} * \\* + \\+ \\ \\\\} $endchars]
          foreach {end start} [lreverse $ranges] {
            set i 0
            foreach index [$txtt search -all -count lengths -regexp -- $pattern $start $end] {
              set format_end [$txtt index $index+[lindex $lengths $i]c]
              $txtt delete $format_end-${endlen}c $format_end
              $txtt delete $index $index+${startlen}c
              incr i
            }
            lappend new_ranges [$txtt index $end-[expr ($endlen + $startlen) * $i]c] $start
          }
        } else {
          set pattern  [string map {\{ \\\{ \} \\\} * \\* + \\+ \\ \\\\} $startchars]
          set startlen [string length $startchars]
          foreach {end start} [lreverse $ranges] {
            set i 0
            foreach index [$txtt search -all -count lengths -regexp -- $pattern $start $end] {
              $txtt delete $index "$index+[lindex $lengths $i]c"
              incr i
            }
            lappend new_ranges [$txtt index $end-[expr $startlen * $i]c] $start
          }
        }
        set ranges     [lreverse $new_ranges]
        set new_ranges [list]
      }

      $txtt edit separator

    }

  }

}
