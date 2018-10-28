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

    # If we are operating in Vim mode, switch to edit mode
    vim::edit_mode $txtt

    # Create the new line
    $txtt insert linestart "\n"
    $txtt cursor move up

  }

  ######################################################################
  # Inserts a blank line below the current line in the given editor.
  proc insert_line_below_current {txtt} {

    # If we are operating in Vim mode, switch to edit mode
    vim::edit_mode $txtt

    # Get the current insertion point
    set insert [$txtt index insert]

    # Add the line(s)
    $txtt cursor move lineend
    $txtt insert insert "\n"

    # Make sure the inserted text is seen
    $txtt see insert

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

  }

  ######################################################################
  # Checks to see if any text is currently selected.  If it is, performs
  # the deletion on the selected text.
  proc delete_selected {txtt line} {

    # If we have selected text, perform the deletion
    if {[llength [set selected [$txtt tag ranges sel]]] > 0} {

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
          $txtt delete -userange 1 "$start linestart" "$end lineend"
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
          $txtt delete -userange 1 $start $end
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
        $txtt cursor set $insertpos
      } else {
        $txtt cursor set insert
      }
    }

  }

  ######################################################################
  # Delete from the current cursor to the end of the line
  proc delete_to_end {txtt copy {num 1}} {

    set spec [list lineend -num $num]

    # Delete from the current cursor to the end of the line
    if {$copy && ([$txtt cursor num] == 0) && ([set str [$txtt get insert $spec]] ne "")} {
      clipboard clear
      clipboard append $str
    }

    $txtt delete insert $spec

  }

  ######################################################################
  # Delete from the start of the current line to just before the current cursor.
  proc delete_from_start {txtt copy} {

    set spec [list linestart]

    # Delete from the beginning of the line to just before the current cursor
    if {$copy && ([$txtt cursor num] == 0) && ([set str [$txtt get $spec insert]] ne "")} {
      clipboard clear
      clipboard append $str
    }

    $txtt delete $spec insert

  }

  ######################################################################
  # Delete from the start of the firstchar to just before the current cursor.
  proc delete_to_firstchar {txtt copy} {

    set spec [list firstchar]

    if {[$txtt cursor num] == 0} {
      if {[$txtt compare $firstchar < insert]} {
        if {$copy} {
          clipboard clear
          clipboard append [$txtt get $spec insert]
        }
        $txtt delete $firstchar insert
      } elseif {[$txtt compare $firstchar > insert]} {
        if {$copy} {
          clipboard clear
          clipboard append [$txtt get insert $spec]
        }
        $txtt delete insert $firstchar
      }
    }

  }

  ######################################################################
  # Delete all consecutive numbers from cursor to end of line.
  proc delete_next_numbers {txtt copy} {

    set spec [list numberend]

    if {$copy && ([$txtt cursor num] == 0) && ([set str [$txtt get insert $spec]] ne "")} {
      clipboard clear
      clipboard append $str
    }

    # Delete the text
    $txtt delete insert $spec

  }

  ######################################################################
  # Deletes all consecutive numbers from the insertion toward the start of
  # the current line.
  proc delete_prev_numbers {txtt copy} {

    set spec [list numberstart]

    if {$copy && ([$txtt cursor num] == 0) && ([set str [$txtt get $spec insert]] ne "")} {
      clipboard clear
      clipboard append $str
    }

    # Delete the text
    $txtt delete $spec insert

  }

  ######################################################################
  # Deletes all consecutive whitespace starting from cursor to the end of
  # the line.
  proc delete_next_space {txtt} {

    $txtt delete insert spaceend

  }

  ######################################################################
  # Deletes all consecutive whitespace starting from cursor to the start
  # of the line.
  proc delete_prev_space {txtt} {

    $txtt delete spacestart insert

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
  # Converts a character-by-character case inversion of the given text.
  proc convert_case_toggle {str} {

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

    return $newstr

  }

  ######################################################################
  # Converts the case to the given type on a word basis.
  proc convert_case_to_title {str} {

    set start 0
    foreach index [regexp -indices -start $start {\w+} $str indices] {
      set str   [string replace $str {*}$indices [string totitle [string range $str {*}$indices]]]
      set start [expr [lindex $indices 1] + 1]
    }

    return $str

  }

  ######################################################################
  # Converts the given string
  proc convert_to_lower_case {str} {

    return [string tolower $str]

  }

  ######################################################################
  # Converts the given string
  proc convert_to_upper_case {str} {

    return [string toupper $str]

  }

  ######################################################################
  # Converts the text to rot13.
  proc convert_to_rot13 {str} {

    variable rot13_map

    return [string map $rot13_map $str]

  }

  ######################################################################
  # Converts the text to text that is right-shifted by one level of
  # indentation.
  proc convert_indent {str} {

    # Get the indent spacing
    set txt        [gui::current_txt]
    set indent_str [string repeat " " [$txt cget -shiftwidth]]
    set modlines   [list]

    foreach line [split $str \n] {
      lappend modlines "$indent_str$line"
    }

    return [join $modlines \n]

  }

  ######################################################################
  # Converts the text to text that is left-shifted by one level of
  # indentation.
  proc convert_unindent {str} {

    set txt      [gui::current_txt]
    set shiftw   [$txt cget -shiftwidth]
    set modlines [list]

    foreach line [split $str \n] {
      if {[string trim [string range $line 0 [expr $shiftw - 1]]] eq ""} {
        lappend modlines [string range $line $shiftw end]
      }
    }

    return [join $modlines \n]

  }

  ######################################################################
  # If text is selected, the case will be toggled for each selected
  # character.  Returns 1 if selected text was found; otherwise, returns 0.
  proc transform_toggle_case_selected {txtt} {

    if {[llength [set ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $ranges] {
        convert_case_toggle $txtt $startpos $endpos
      }
      $txtt cursor set $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Perform a case toggle operation.
  proc transform_toggle_case {txtt startpos endpos {cursorpos insert}} {

    if {![transform_toggle_case_selected $txtt]} {
      convert_case_toggle $txtt $startpos $endpos
      $txtt cursor set $cursorpos
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
      $txtt cursor set $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Perform a lowercase conversion.
  proc transform_to_lower_case {txtt startpos endpos {cursorpos insert}} {

    if {![transform_to_lower_case_selected $txtt]} {
      convert_to_lower_case $txtt $startpos $endpos
      $txtt cursor set $cursorpos
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
      $txtt cursor set $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Perform an uppercase conversion.
  proc transform_to_upper_case {txtt startpos endpos {cursorpos insert}} {

    if {![transform_to_upper_case_selected $txtt]} {
      convert_to_upper_case $txtt $startpos $endpos
      $txtt cursor set $cursorpos
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
      $txtt cursor set $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Transforms all text in the given range to rot13.
  proc transform_to_rot13 {txtt startpos endpos {cursorpos insert}} {

    if {![transform_to_rot13_selected $txtt]} {
      convert_to_rot13 $txtt $startpos $endpos
      $txtt cursor set $cursorpos
    }

  }

  ######################################################################
  # Perform a title case conversion.
  proc transform_to_title_case {txtt startpos endpos {cursorpos insert}} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        convert_case_to_title $txtt [$txtt index "$startpos wordstart"] $endpos
      }
      $txtt cursor set $startpos
    } else {
      set str [$txtt get "insert wordstart" "insert wordend"]
      convert_case_to_title $txtt [$txtt index "$startpos wordstart"] $endpos
      $txtt cursor set $cursorpos
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
      $txtt cursor set $index

      # Create a separator
      $txtt edit separator

    }

  }

  ######################################################################
  # Returns the number of newlines contained in the given string.
  proc newline_count {str} {

    return [expr {[string length $str] - [string length [string map {\n {}} $str]]}]

  }

  ######################################################################
  # Moves selected lines or the current line up by one line.
  proc transform_bubble_up {txtt} {

    # Create undo separator
    $txtt edit separator

    # If lines are selected, move all selected lines up one line
    if {[llength [set selected [$txtt tag ranges sel]]] > 0} {

      switch [set type [select::get_type $txtt]] {
        none -
        line {
          foreach {end_range start_range} [lreverse $selected] {
            set str [$txtt get "$start_range-1l linestart" "$start_range linestart"]
            $txtt delete "$start_range-1l linestart" "$start_range linestart"
            if {[$txtt compare "$end_range linestart" == end]} {
              set str "\n[string trimright $str]"
            }
            $txtt insert "$end_range linestart" $str
          }
        }
        sentence {
          set startpos [$txtt index [list $type -dir prev -startpos [lindex $selected 0]]]
          regexp {^(.*?)(\s*)$} [$txtt get $startpos [lindex $selected 0]] -> pstr pbetween
          regexp {^(.*?)(\s*)$} [$txtt get [lindex $selected 0] [lindex $selected end]] -> cstr cbetween
          if {$cbetween eq ""} {
            set cbetween "  "
          }
          if {[newline_count $pbetween] >= 2} {
            set wo_ws [string trimright [set full [$txtt get [lindex $selected 0] [lindex $selected end]]]]
            set eos   [$txtt index "[lindex $selected 0]+[string length $wo_ws]c"]
            $txtt delete  $eos [lindex $selected end]
            $txtt insert  $eos $pbetween sel
            $txtt replace -str "  " "[lindex $selected 0]-[string length $pbetween]c" [lindex $selected 0]
          } elseif {[newline_count $cbetween] >= 2} {
            set index [$txtt index "[lindex $selected end]-[string length $cbetween]c"]
            $txtt insert $index $pbetween$pstr
            $txtt tag remove sel "$index+[string length $pbetween]c" [lindex $selected end]
            $txtt delete $startpos [lindex $selected 0]
          } else {
            $txtt insert [lindex $selected end] $pstr$pbetween
            $txtt delete $startpos [lindex $selected 0]
          }
        }
        paragraph {
          set startpos [$txtt index [list $type -dir prev -startpos [lindex $selected 0]]]
          regexp {^(.*)(\s*)$} [$txtt get $startpos [lindex $selected 0]] -> str between
          $txtt insert [lindex $selected end] $between$str
          $txtt delete $startpos [lindex $selected 0]
        }
        node {
          if {[set range [select::node_prev_sibling $txtt [lindex $selected 0]]] ne ""} {
            set str     [$txtt get {*}$range]
            set between [$txtt get [lindex $range 1] [lindex $selected 0]]
            $txtt insert [lindex $selected end] $between$str
            $txtt delete [lindex $range 0] [lindex $selected 0]
          }
        }
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

      switch [set type [select::get_type $txtt]] {
        none -
        line {
          foreach {end_range start_range} [lreverse $selected] {
            set str [$txtt get "$end_range+1l linestart" "$end_range+2l linestart"]
            $txtt delete "$end_range lineend" "$end_range+1l lineend"
            $txtt insert "$start_range linestart" $str
          }
        }
        sentence {
          set startpos [$txtt index [list $type -dir prev -startpos [lindex $selected 0]]]
          set endpos   [$txtt index [list $type -dir next -startpos "[lindex $selected end]+1 display chars"]]
          regexp {^(.*?)(\s*)$} [$txtt get $startpos [lindex $selected 0]] -> pstr pbetween
          regexp {^(.*?)(\s*)$} [$txtt get [lindex $selected 0] [lindex $selected end]] -> cstr cbetween
          regexp {^(.*?)(\s*)$} [$txtt get [lindex $selected end] $endpos] -> astr abetween
          if {[newline_count $cbetween] >= 2} {
            set index [$txtt index "[lindex $selected 0]+[string length $cstr]c"]
            $txtt tag remove sel $index [lindex $selected end]
            if {$astr eq ""} {
              $txtt insert [lindex $selected end] $cstr sel
            } else {
              $txtt insert [lindex $selected end] "$cstr  " sel
            }
            $txtt delete "[lindex $selected 0]-[string length $pbetween]c" $index
          } elseif {[newline_count $abetween] >= 2} {
            set index [$txtt index "[lindex $selected end]+[string length $astr]c"]
            $txtt tag add sel $index $endpos
            $txtt insert $index $cbetween {} $cstr sel
            $txtt delete [lindex $selected 0] [lindex $selected end]
          } elseif {$abetween eq ""} {
            $txtt delete "[lindex $selected end]-[string length $cbetween]c" $endpos
            $txtt insert [lindex $selected 0] $astr$cbetween
          } else {
            $txtt delete [lindex $selected end] $endpos
            $txtt insert [lindex $selected 0] $astr$cbetween
          }
        }
        paragraph {
          set endpos [$txtt index [list $type -dir next -startpos "[lindex $selected end]+1 display chars"]]
          set str [string trimright [$txtt get [lindex $selected end] $endpos]]
          regexp {(\s*)$} [$txtt get {*}$selected] -> between
          $txtt delete [lindex $selected end] $endpos
          $txtt insert [lindex $selected 0] $str$between
        }
        node {
          if {[set range [select::node_next_sibling $txtt "[lindex $selected end]-1c"]] ne ""} {
            set str     [$txtt get {*}$range]
            set between [$txtt get [lindex $selected end] [lindex $range 0]]
            $txtt delete [lindex $selected end] [lindex $range end]
            $txtt insert [lindex $selected 0] $str$between
          }
        }
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
      gui::set_info_message [format "%s (%s)" [msgcat::mc "Filename already exists"] $fname]
      return 0
    } else {
      if {[catch { open $fname w } rc]} {
        gui::set_info_message [format "%s %s" [msgcat::mc "Unable to write"] $fname]
        return 0
      } else {
        puts $rc [$txt get $from $to]
        close $rc
        gui::set_info_message [format "%s (%s)" [msgcat::mc "File successfully written"] $fname]
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
    lassign [syntax::get_comments $txt] icomment

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

    # Strip out comment syntax
    foreach {endpos startpos} [lreverse [set ranges [ctext::getCommentMarkers $txt $selected]]] {
      $txt delete -highlight 0 $endpos $startpos
    }

    # Re-highlight the widget
    $txt syntax highlight {*}$ranges

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
      } elseif {[$txt is inblockcomment]} {
        lassign [$txt syntax prevrange comment insert] startpos endpos
        if {[regexp "^[lindex $bcomments 0 0](.*)[lindex $bcomments 0 1]\$" [$txt get $startpos $endpos] -> str]} {
          $txt replace -str $str $startpos $endpos
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

    foreach {epos spos} [lreverse [set ranges [ctext::getCommentMarkers $txt [list $startpos $endpos]]]] {
      $txt delete -highlight 0 $spos $epos
      set retval 1
    }

    # Perform syntax highlighting
    $txt syntax highlight {*}$ranges

    return $retval

  }

  ######################################################################
  # Performs indentation on selected text, if available.
  proc indent_selected {txtt} {

    if {[set selected [$txtt tag ranges sel]] ne ""} {
      foreach {endpos startpos} [lreverse $selected] {
        $txtt replace -transform edit::convert_indent [list linestart -startpos $startpos] [list lineend -startpos $endpos]
      }
      $txtt cursor set $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Perform indentation on a specified range.
  proc indent {txtt startpos endpos {cursorpos insert}} {

    if {![indent_selected $txtt]} {
      $txtt replace -transform edit::convert_indent [list linestart -startpos $startpos] [list lineend -startpos $endpos]
      $txtt cursor set $cursorpos
    }

  }

  ######################################################################
  # Perform unindentation on the selected text, if applicable.
  proc unindent_selected {txtt} {

    if {[set selected [$txtt tag ranges sel]] ne ""} {
      foreach {endpos startpos} [lreverse $selected] {
        $txtt replace -transform edit::convert_unindent [list linestart -startpos $startpos] [list lineend -startpos $endpos]
      }
      $txtt cursor set $startpos
      return 1
    }

    return 0

  }

  ######################################################################
  # Perform unindentation on a specified range.
  proc unindent {txtt startpos endpos {cursorpos insert}} {

    if {![unindent_selected $txtt]} {
      $txtt replace -transform edit::convert_unindent [list linestart -startpos $startpos] [list lineend -startpos $endpos]
      $txtt cursor set $cursorpos
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
    $txt replace -str $rc "insert linestart" "insert lineend"

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
  proc align_cursors {args} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Align multicursors only
    $txt cursor align {*}$args

  }

  ######################################################################
  # Inserts an enumeration when in multicursor mode.
  proc enumerate {{txt ""}} {

    # Get the current text widget
    if {$txt eq ""} {
      set txt [gui::current_txt]
    }

    # Only execute if we are in multicursor mode
    if {[set num [llength [$txt cursor get]]] > 1} {

      set var ""

      # Get the number string from the user
      if {[gui::get_user_response [msgcat::mc "Starting number:"] var]} {

        # Insert the numbers (if not successful, output an error to the user)
        if {![insert_numbers $txt $num $var]} {
          gui::set_info_message [msgcat::mc "Unable to successfully parse number string"]
        }

      }

    # Otherwise, display an error message to the user
    } else {
      gui::set_info_message [msgcat::mc "Must be in multicursor mode to insert numbers"]
    }

  }

  ######################################################################
  # Parses the given number string with the format of:
  #   (d|o|x)?<number>+
  # Where d means to parse and insert decimal numbers, o means to parse
  # and insert octal numbers, and x means to parse and insert hexidecimal
  # numbers.  If d, o or x are not specified, d is assumed.
  # Numbers will be inserted at each cursor location such that the first
  # cursor will be replaced with the number specified by <number>+ and
  # each successive cursor will have an incrementing value inserted
  # at its location.
  proc insert_numbers {txt count numstr} {

    # If the number string is a decimal number without a preceding 'd' character, add it now
    if {[set d_added [regexp {^[0-9]+([+-]\d*)?$} $numstr]]} {
      set numstr "d$numstr"
    }

    # Parse the number string to verify that it's valid
    if {[regexp -nocase {^(.*)(b[0-1]*|d[0-9]*|o[0-7]*|[xh][0-9a-fA-F]*)([+-]\d*)?$} $numstr -> prefix numstr increment]} {

      # Get the number portion of the number string.  If one does not exist,
      # default the number to 0.
      if {[set num [string range $numstr 1 end]] eq ""} {
        set num 0
      }

      # Initialize the value of increment if it was not specified by the user explicitly
      if {$increment eq ""} {
        set increment "+1"
      } elseif {$increment eq "+"} {
        set increment "+1"
      } elseif {$increment eq "-"} {
        set increment "-1"
      }

      if {0} {
      # Calculate the num and increment values
      if {[string index $increment 0] eq "+"} {
        set increment [string range $increment 1 end]
        set num       [expr $num + (($count - 1) * $increment)]
        set increment "-$increment"
      } else {
        set increment [string range $increment 1 end]
        set num       [expr $num - (($count - 1) * $increment)]
        set increment "+$increment"
      }
      }

      # Get the list of values to insert
      set values [list]
      switch [string tolower [string index $numstr 0]] {
        b {
          for {set i 0} {$i < $count} {incr i} {
            set binRep [binary format c $num]
            binary scan $binRep B* binStr
            lappend values [format "%s%s%s" $prefix [string trimleft [string range $binStr 0 end-1] 0] [string index $binStr end]]
            incr num $increment
          }
        }
        d {
          for {set i 0} {$i < $count} {incr i} {
            lappend values [format "%s%d" $prefix $num]
            incr num $increment
          }
        }
        o {
          for {set i 0} {$i < $count} {incr i} {
            lappend values [format "%s%o" $prefix $num]
            incr num $increment
          }
        }
        h -
        x {
          for {set i 0} {$i < $count} {incr i} {
            lappend values [format "%s%x" $prefix $num]
            incr num $increment
          }
        }
      }

      # Insert the list of values
      $txt insertlist $values

      return 1

    }

    return 0

  }

  ######################################################################
  # Jumps to the given line number.
  proc jump_to_line {txt linenum} {

    # Set the insertion cursor to the given line number
    $txt cursor set $linenum

  }

  ######################################################################
  # Handles word/WORD range motions.
  proc get_range_word {txtt type num inner adjust {cursor insert}} {

    if {$inner} {

      # Get the starting position of the selection
      if {[string is space [$txtt get $cursor]]} {
        set startpos [$txtt index [list spacestart -dir prev -startpos "$cursor+1c"]]
      } else {
        set startpos [$txtt index [list ${type}start -dir prev -startpos "$cursor+1c"]]
      }

      # Count spaces and non-spaces
      set endpos [expr {($type eq "word") ? "$cursor-1c" : $cursor}]
      for {set i 0} {$i < $num} {incr i} {
        set endpos [$txtt index "$endpos+1c"]
        if {[string is space [$txtt get $endpos]]} {
          set endpos [$txtt index [list spaceend -dir next -startpos $endpos]]
        } else {
          set endpos [$txtt index [list ${type}end -dir next -startpos $endpos]]
        }
      }

    } else {

      set endpos [$txtt index [list ${type}end -dir next -num $num -startpos [expr {($type eq "word") ? $cursor : "$cursor-1c"}]]]

      # If the cursor is within a space, make the startpos be the start of the space
      if {[string is space [$txtt get $cursor]]} {
        set startpos [$txtt index [list spacestart -dir prev -startpos "$cursor+1c"]]

      # Otherwise, the insertion cursor is within a word, if the character following
      # the end of the word is a space, the start is the start of the word while the end is
      # the whitspace after the word.
      } elseif {[$txtt compare "$endpos+1c" < "$endpos lineend"] && [string is space [$txtt get "$endpos+1c"]]} {
        set startpos [$txtt index [list ${type}start -dir prev -startpos "$cursor+1c"]]
        set endpos   [$txtt index [list spaceend -dir next -startpos "$endpos+1c"]]

      # Otherwise, set the start of the selection to the be the start of the preceding
      # whitespace.
      } else {
        set startpos [$txtt index [list ${type}start -dir prev -startpos "$cursor+1c"]]
        if {[$txtt compare $startpos > "$startpos linestart"] && [string is space [$txtt get "$startpos-1c"]]} {
          set startpos [$txtt index [list spacestart -dir prev -startpos "$startpos-1c"]]
        }
      }

    }

    return [list $startpos [$txtt index "$endpos$adjust"]]

  }

  ######################################################################
  # Handles WORD range motion.
  proc get_range_WORD {txtt num inner adjust {cursor insert}} {

    if {[string is space [$txtt get $cursor]]} {
      set pos_list [list [$txtt index [list spacestart -dir prev -startpos "$cursor+1c"]] [$txtt index [list spaceend -dir next -adjust "-1c"]]]
    } else {
      set pos_list [list [$txtt index [list $start -dir prev -startpos "$cursor+1c"]] [$txtt index [list $end -dir next -num $num]]]
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
  proc get_range_sentences {txtt type num inner adjust {cursor insert}} {

    set pos_list [list [$txtt index [list $type -dir prev -startpos "$cursor+1c"]] [$txtt index [list $type -dir next -num $num]]]

    if {$inner} {
      set str  [$txtt get {*}$pos_list]
      set less [expr ([string length $str] - [string length [string trimright $str]]) + 1]
      lset pos_list 1 [$txtt index "[lindex $pos_list 1]-${less}c"]
    }


    return $pos_list

  }

  ######################################################################
  # Returns the text range for a bracketed block of text.
  proc get_range_block {txtt type num inner adjust {cursor insert}} {

    # Search backwards
    set txt      [winfo parent $txtt]
    set number   $num
    set startpos [expr {![$txtt is $type left] ? $cursor : "$cursor+1c"}]

    while {[set index [$txt matchchar $startpos]] ne ""} {
      if {[incr number -1] == 0} {
        set right [ctext::getMatchBracket $txt ${type}R $index]
        if {($right eq "") || [$txtt compare $right < $cursor]} {
          return [list "" ""]
        } else {
          return [expr {$inner ? [list [$txt index "$index+1c"] [$txt index "$right-1c$adjust"]] : [list $index [$txt index "$right$adjust"]]}]
        }
      } else {
        set startpos $index
      }
    }

    return [list "" ""]

  }

  ######################################################################
  # Returns the text range for the given string type.
  proc get_range_string {txtt char tag inner adjust {cursor insert}} {

    if {[$txtt get $cursor] eq $char} {
      if {![$txtt is $tag $cursor-1c]} {
        set index [gui::find_match_char [winfo parent $txtt] $char -forwards]
        return [expr {$inner ? [list [$txtt index "$cursor+1c"] [$txtt index "$index-1c$adjust"]] : [list [$txtt index $cursor] [$txtt index "$index$adjust"]]}]
      } else {
        set index [gui::find_match_char [winfo parent $txtt] $char -backwards]
        return [expr {$inner ? [list [$txtt index "$index+1c"] [$txtt index "$cursor-1c$adjust"]] : [list $index [$txtt index "$cursor$adjust"]]}]
      }
    } elseif {[$txtt is $tag $cursor]} {
      lassign [$txtt range prev $tag $cursor] startpos endpos
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
        "word"      { return [get_range_word $txtt word $num $inner $adjust $cursor] }
        "WORD"      { return [get_range_word $txtt WORD $num $inner $adjust $cursor] }
        "paragraph" { return [get_range_sentences $txtt paragraph $num $inner $adjust $cursor] }
        "sentence"  { return [get_range_sentences $txtt sentence  $num $inner $adjust $cursor] }
        "tag"       {
          set insert [$txtt index $cursor]
          while {[set ranges [emmet::get_node_range [winfo parent $txtt]]] ne ""} {
            if {[incr num -1] == 0} {
              $txtt mark set insert $insert
              if {$inner} {
                return [list [lindex $ranges 1] [$txtt index "[lindex $ranges 2]-1c$adjust"]]
              } else {
                return [list [lindex $ranges 0] [$txtt index "[lindex $ranges 3]-1c$adjust"]]
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
        "angled" { return [get_range_block $txtt $type $num $inner $adjust $cursor] }
        "double" { return [get_range_string $txtt \" double $inner $adjust $cursor] }
        "single" { return [get_range_string $txtt \' single $inner $adjust $cursor] }
        "btick"  { return [get_range_string $txtt \` btick $inner $adjust $cursor] }
      }

    } else {

      set pos1 [$txtt index [list {*}$pos1args -startpos $cursor]]

      if {$pos2args ne ""} {
        set pos2 [$txtt index [list {*}$pos2args -startpos $cursor]]
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
    set index [$txtt index [list $position {*}$args]]

    # Set the insertion position and make it visible
    $txtt cursor set $index

  }

  ######################################################################
  # Moves the cursor up/down by a single page.  Valid values for dir are:
  # - Next
  # - Prior
  proc move_cursor_by_page {txtt dir} {

    # Adjust the view
    eval [string map {%W $txtt} [bind Text <[string totitle $dir]>]]

    # Make sure that the cursor position is set through the widget
    $txtt cursor set insert

  }

  ######################################################################
  # Moves multicursors in the modifier direction for the given text widget.
  proc move_cursors {txtt modifier} {

    # Clear the selection
    $txtt tag remove sel 1.0 end

    # Adjust the cursors
    $txtt cursor move $modifier

  }

  ######################################################################
  # Applies the specified formatting to the given text widget.
  proc add_formatting {txtt type} {

    # Get the range of lines to modify
    if {[set ranges [$txtt tag ranges sel]] eq ""} {
      if {[set cursors [$txtt cursor get]] ne ""} {
        foreach cursor $cursors {
          if {[string trim [$txtt get "$cursor wordstart" "$cursor wordend"]] ne ""} {
            lappend ranges [$txtt index "$cursor wordstart"] [$txtt index "$cursor wordend"]
          } else {
            lappend ranges $cursor $cursor
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

    if {[set ranges_len [llength $ranges]] > 0} {

      # Get the formatting information for the current text widget
      array set formatting [syntax::get_formatting [winfo parent $txtt]]

      if {[info exists formatting($type)]} {

        lassign $formatting($type) stype pattern

        # Figure out the string to use when asking the user for a reference
        switch $type {
          link    { set refmsg [msgcat::mc "Link URL"] }
          image   { set refmsg [msgcat::mc "Image URL"] }
          default { set refmsg "" }
        }

        # If we need to resolve a reference do that now
        if {$refmsg ne ""} {
          set ref ""
          if {[gui::get_user_response $refmsg ref -allow_vars 1]} {
            set pattern [string map [list \{REF\} $ref] $pattern]
          } else {
            return
          }
        }

        # Find the position of the {TEXT} substring
        set textpos [string first \{TEXT\} $pattern]

        # Remove any multicursors
        $txtt cursor disable

        $txtt edit separator

        if {$stype eq "line"} {
          set last ""
          foreach {end start} [lreverse $ranges] {
            if {($last eq "") || [$txtt compare "$start linestart" != "$last linestart"]} {
              while {[$txtt compare $start < $end]} {
                set oldstr [$txtt get "$start linestart" "$start lineend"]
                set newstr [string map [list \{TEXT\} $oldstr] $pattern]
                $txtt replace -str $newstr "$start linestart" "$start lineend"
                if {$oldstr eq ""} {
                  if {($ranges_len == 2) && [$txtt compare $start+1l >= $end]} {
                    $txtt mark set insert "$start linestart+${textpos}c"
                  } else {
                    $txtt cursor add "$start linestart+${textpos}c"
                  }
                }
                if {[string first \n $newstr]} {
                  $txtt indent "$start linestart" "$start linestart+[string length $newstr]c"
                }
                set last  $start
                set start [$txtt index "$start+1l"]
              }
            }
          }
        } else {
          foreach {end start} [lreverse $ranges] {
            set oldstr [$txtt get $start $end]
            set newstr [string map [list \{TEXT\} $oldstr] $pattern]
            $txtt replace -str $newstr $start $end
            if {$oldstr eq ""} {
              if {$ranges_len == 2} {
                $txtt mark set insert "$start+${textpos}c"
              } else {
                $txtt cursor add "$start+${textpos}c"
              }
            }
            if {[string first \n $newstr]} {
              $txtt indent $start "$start+[string length $newstr]c"
            }
          }
        }

        $txtt edit separator

      }

    }

  }

  ######################################################################
  # Removes any applied text formatting found in the selection or (if no
  # text is currently selected the current line).
  proc remove_formatting {txtt} {

    # Get the formatting information for the current text widget
    array set formatting [syntax::get_formatting [winfo parent $txtt]]

    # Get the range of lines to check
    if {[set ranges [$txtt tag ranges sel]] eq ""} {
      if {[set cursors [$txtt cursor get]] ne ""} {
        set last ""
        foreach cursor $cursors {
          if {($last eq "") || [$txtt compare "$cursor linestart" != "$last linestart"]} {
            lappend ranges [$txtt index "$cursor linestart"] [$txtt index "$cursor lineend"]
            set last $cursor
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
        lassign $chars stype pattern
        set new_ranges [list]
        set metalen    [string length [string map {\{REF\} {} \{TEXT\} {}} $pattern]]
        set pattern    [string map {\{REF\} {.*?} \{TEXT\} {(.*?)} \{ \\\{ \} \\\} * \\* + \\+ \\ \\\\ \( \\\( \) \\\) \[ \\\[ \] \\\] \. \\\. \? \\\? ^ \\\^ \$ \\\$} $pattern]
        set pattern    [regsub -all {\n\s*} $pattern {\s+}]
        if {$stype eq "line"} {
          set pattern "^$pattern\$"
        }
        foreach {end start} [lreverse $ranges] {
          set i 0
          foreach index [$txtt search -all -count lengths -regexp -- $pattern $start $end] {
            regexp $pattern [$txtt get $index "$index+[lindex $lengths $i]c"] -> str
            $txtt replace -str $str $index "$index+[lindex $lengths $i]c"
            incr i
          }
          lappend new_ranges [$txtt index "$end-[expr $metalen * $i]c"] $start
        }
        set ranges     [lreverse $new_ranges]
        set new_ranges [list]
      }

      $txtt edit separator

    }

  }

}
