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
    nnumber {^([0-9]+|0x[0-9a-fA-F]+|[0-9]+\.[0-9]+)}
    pnumber {([0-9]+|0x[0-9a-fA-F]+|[0-9]+\.[0-9]+)$}
    nspace  {^[ \t]+}
    pspace  {[ \t]+$}
  }

  ######################################################################
  # Inserts the line above the current line in the given editor.
  proc insert_line_above_current {txtt} {

    # If we are operating in Vim mode,
    vim::edit_mode $txtt

    # Create the new line
    if {[multicursor::enabled $txtt]} {
      multicursor::adjust_up $txtt 1
    } elseif {[$txtt compare "insert linestart" == 1.0]} {
      $txtt insert "insert linestart" "\n"
      ::tk::TextSetCursor $txtt "insert-1l"
    } else {
      ::tk::TextSetCursor $txtt "insert-1l lineend"
      $txtt insert "insert lineend" "\n"
    }

    # Perform the proper indentation
    indent::newline $txtt insert 1

    # Start recording
    vim::record_start

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
      multicursor::adjust_down $txtt 1
    } else {
      ::tk::TextSetCursor $txtt "insert lineend"
      $txtt insert "insert lineend" "\n"
    }

    # Make sure the inserted text is seen
    $txtt see insert

    # Perform the proper indentation
    indent::newline $txtt insert 1

    # Start recording
    vim::record_start

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
  # Deletes the current line.
  proc delete_current_line {txtt {num 1}} {

    # Clear the clipboard and copy the line(s) that will be deleted
    clipboard clear
    clipboard append [$txtt get "insert linestart" "insert+${num}l linestart"]

    # If we are deleting the last line, move the cursor up one line
    if {[$txtt compare "insert+${num}l linestart" == end]} {
      if {[$txtt compare "insert linestart" == 1.0]} {
        $txtt delete "insert linestart" "insert lineend"
      } else {
        $txtt mark set insert insert-1l
        $txtt delete "insert lineend" "insert+${num}l lineend"
      }
    } else {
      $txtt delete "insert linestart" "insert+${num}l linestart"
    }

    # Position the cursor at the beginning of the first word
    move_cursor $txtt firstword

    # Adjust the insertion cursor
    vim::adjust_insert $txtt

  }

  ######################################################################
  # Deletes the current word (i.e., dw Vim mode).
  proc delete_current_word {txtt {num 1}} {

    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt word $num
    } else {
      set endpos [get_index $txtt nextword -num $num]
      clipboard clear
      clipboard append [$txtt get insert $endpos]
      $txtt delete insert $endpos
      vim::adjust_insert $txtt
    }

  }

  ######################################################################
  # Delete from the current cursor to the end of the line
  proc delete_to_end {txtt {num 1}} {

    # Delete from the current cursor to the end of the line
    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt "lineend"
    } else {
      set endpos [get_index $txtt lineend -num $num]+1c
      clipboard clear
      clipboard append [$txtt get insert $endpos]
      $txtt delete insert $endpos
      vim::adjust_insert $txtt
    }

  }

  ######################################################################
  # Delete from the start of the current line to just before the current cursor.
  proc delete_from_start {txtt} {

    # Delete from the beginning of the line to just before the current cursor
    if {[multicursor::enabled $txtt]} {
      multicursor::delete $txtt "linestart"
    } else {
      clipboard clear
      clipboard append [$txtt get "insert linestart" insert]
      $txtt delete "insert linestart" insert
    }

  }

  ######################################################################
  # Delete all consecutive numbers from cursor to end of line.
  proc delete_current_number {txtt} {

    variable patterns

    if {[multicursor::enabled $txtt]} {
      foreach key [list pnumber nnumber] {
        multicursor::delete $txtt pattern $patterns($key)
      }
    } else {
      set first 1
      if {[regexp $patterns(pnumber) [$txtt get "insert linestart" insert] match]} {
        if {$first} {
          clipboard clear
          set first 0
        }
        clipboard append [$txtt get "insert-[string length $match]c" insert]
        $txtt delete "insert-[string length $match]c" insert
      }
      if {[regexp $patterns(nnumber) [$txtt get insert "insert lineend"] match]} {
        if {$first} {
          clipboard clear
          set first 0
        }
        clipboard append [$txtt get insert "insert+[string length $match]c"]
        $txtt delete insert "insert+[string length $match]c"
      }
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
  proc delete_to_next_char {txtt char {num 1} {inclusive 1}} {

    if {[set index [find_char $txtt next $char $num]] ne "insert"} {
      clipboard clear
      if {$inclusive} {
        clipboard append [$txtt get insert "$index+1c"]
        $txtt delete insert "$index+1c"
      } else {
        clipboard append [$txtt get insert $index]
        $txtt delete insert $index
      }
    }

  }

  ######################################################################
  # Deletes from the current insert position to (and including) the
  # previous character on the current line.
  proc delete_to_prev_char {txtt char {num 1} {inclusive 1}} {

    if {[set index [find_char $txtt prev $char $num]] ne "insert"} {
      clipboard clear
      if {$inclusive} {
        clipboard append [$txtt get $index insert]
        $txtt delete $index insert
      } else {
        clipboard append [$txtt get $index+1c insert]
        $txtt delete $index+1c insert
      }
    }

  }

  ######################################################################
  # Get the start and end positions for the pair defined by char.
  proc get_char_positions {txtt endchar} {

    array set pairs {\{ \\\} \} \\\{ \( \\\) \) \\\( \[ \\\] \] \\\[ < > > <}

    # Initialize
    set retval [set end_index 0]

    # Get the matching character
    if {[info exists pairs($endchar)]} {
      if {[set start_index [gui::find_match_pair $txtt $pairs($endchar) \\$endchar -backwards]] != -1} {
        set retval [expr {[set end_index [gui::find_match_pair $txtt \\$endchar $pairs($endchar) -forwards]] != -1}]
      }
    } else {
      if {[set start_index [gui::find_match_char $txtt $endchar -backwards]] != -1} {
        set retval [expr {[set end_index [gui::find_match_char $txtt $endchar -forwards]] != -1}]
      }
    }

    return [list $start_index $end_index $retval]

  }

  ######################################################################
  # Deletes all text found between the given character such that the
  # current insertion cursor sits between the character set.  Returns 1
  # if a match occurred (and text was deleted); otherwise, returns 0.
  proc delete_between_char {txtt char} {

    if {[lassign [get_char_positions $txtt $char] start_index end_index]} {
      clipboard clear
      clipboard append [$txtt get $start_index+1c $end_index]
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
  proc convert_case_toggle {txtt index str} {

    set strlen [string length $str]

    for {set i 0} {$i < $strlen} {incr i} {
      set char [string index $str $i]
      append newstr [expr {[string is lower $char] ? [string toupper $char] : [string tolower $char]}]
    }

    $txtt replace $index "$index+${strlen}c" $newstr

  }

  ######################################################################
  # Converts the case to the given type on a word basis.
  proc convert_case_to_title {txtt index str} {

    while {[regexp {^(\w+)(\W*)(.*)$} $str -> word wspace str]} {
      set wordlen [string length $word]
      set strlen  [expr $wordlen + [string length $wspace]]
      $txtt replace $index "$index+${wordlen}c" [string to$type $word]
      set index   [$txtt index "$index+${strlen}c"]
    }

  }

  ######################################################################
  # Perform a case toggle operation.
  proc transform_toggle_case {txtt startpos endpos} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        convert_case_toggle $txtt $startpos [$txtt get $startpos $endpos]
      }
      $txtt tag remove sel 1.0 end
    } else {
      convert_case_toggle $txtt $startpos [$txtt get $startpos $endpos]
    }

  }

  ######################################################################
  # Perform a lowercase conversion.
  proc transform_to_lower_case {txtt startpos endpos} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        $txtt replace $startpos $endpos [string tolower [$txtt get $startpos $endpos]]
      }
      $txtt tag remove sel 1.0 end
    } else {
      $txtt replace $startpos $endpos [string tolower [$txtt get $startpos $endpos]]
    }

  }

  ######################################################################
  # Perform an uppercase conversion.
  proc transform_to_upper_case {txtt startpos endpos} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        $txtt replace $startpos $endpos [string toupper [$txtt get $startpos $endpos]]
      }
      $txtt tag remove sel 1.0 end
    } else {
      $txtt replace $startpos $endpos [string toupper [$txtt get $startpos $endpos]]
    }

  }

  ######################################################################
  # Perform a title case conversion.
  proc transform_to_title_case {txtt startpos endpos} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        convert_case_to_title $txtt [$txtt index "$startpos wordstart"] [$txtt get "$startpos wordstart" $endpos]
      }
      $txtt tag remove sel 1.0 end
    } else {
      set str [$txtt get "insert wordstart" "insert wordend"]
      convert_case_to_title $txtt [$txtt index "$startpos wordstart"] [$txtt get "$startpos wordstart" "$endpos wordend"]
    }

  }

  ######################################################################
  # If a selection occurs, joins the selected lines; otherwise, joins the
  # number of specified lines.
  # TBD - Needs work
  proc transform_join_lines {txtt {num ""}} {

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

      set lines [expr {($num ne "") ? $num : 1}]
      for {set i 0} {$i < $lines} {incr i} {
        set line    [string trimleft [$txtt get "insert+1l linestart" "insert+1l lineend"]]
        $txtt delete "insert lineend" "insert+1l lineend"
        if {![string is space [$txtt get "insert lineend-1c"]]} {
          set line " $line"
        }
        if {$line ne ""} {
          $txtt insert "insert lineend" $line
        }
      }

      set deleted [expr $lines > 0]
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
      set str [$txtt get "insert+1l linestart" "insert+l2 linestart"]
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
  proc comment {} {

    # Get the current text widget
    set txt [gui::current_txt]

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
  # Uncomments out the currently selected text in the current text
  # widget.
  proc uncomment {} {

    # Get the current text widget
    set txt [gui::current_txt]

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
  # Handles commenting/uncommenting either the currently selected code
  # or the current cursor.
  proc comment_toggle {} {

    # Get the current text widget
    set txt [gui::current_txt]

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
  # Indents the selected text of the current text widget by one
  # indentation level.
  proc indent {txtt {startpos "insert"} {endpos "insert"}} {

    # Create a separator
    $txtt edit separator

    # Get the indent spacing
    set indent_str [string repeat " " [indent::get_shiftwidth $txtt]]

    # Get the selection ranges
    if {[llength [set selected [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $selected] {
        while {[$txtt index "$startpos linestart"] <= [$txtt index "$endpos linestart"]} {
          $txtt insert "$startpos linestart" $indent_str
          set startpos [$txtt index "$startpos linestart+1l"]
        }
      }
    } else {
      while {[$txtt index "$startpos linestart"] <= [$txtt index "$endpos linestart"]} {
        $txtt insert "$startpos linestart" $indent_str
        set startpos [$txtt index "$startpos linestart+1l"]
      }
    }

    # Create a separator
    $txtt edit separator

  }

  ######################################################################
  # Unindents the selected text of the current text widget by one
  # indentation level.
  proc unindent {txtt {startpos "insert"} {endpos "insert"}} {

    # Create a separator
    $txtt edit separator

    # Get the indent spacing
    set unindent_str [string repeat " " [indent::get_shiftwidth $txtt]]
    set unindent_len [string length $unindent_str]

    # Get the selection ranges
    if {[llength [set selected [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $selected] {
        while {[$txtt index "$startpos linestart"] <= [$txtt index "$endpos linestart"]} {
          if {[regexp "^$unindent_str" [$txtt get "$startpos linestart" "$startpos lineend"]]} {
            $txtt delete "$startpos linestart" "$startpos linestart+${unindent_len}c"
          }
          set startpos [$txtt index "$startpos linestart+1l"]
        }
      }
    } else {
      while {[$txtt index "$startpos linestart"] <= [$txtt index "$endpos linestart"]} {
        if {[regexp "^$unindent_str" [$txtt get "$startpos linestart" "$startpos lineend"]]} {
          $txtt delete "$startpos linestart" "$startpos linestart+${unindent_len}c"
        }
        set startpos [$txtt index "$startpos linestart+1l"]
      }
    }

    # Create a separator
    $txtt edit separator

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
  proc get_word {txt dir {num 1} {start insert}} {

    # If the direction is 'next', search forward
    if {$dir eq "next"} {

      # Get the end of the current word (this will be the beginning of the next word)
      set curr_index [$txt index "$start display wordend"]

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
          set last_wordend $curr_index
          if {[incr num -1] == 0} {
            return [$txt index "$curr_index display wordstart"]
          }
        }
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
        if {![string is space [$txt get $curr_index]] && \
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
  # Returns the starting index of the given character.
  proc find_char {txtt dir char {num 1}} {

    # Perform the character search
    if {$dir eq "next"} {
      set indices [$txtt search -all -- $char "insert+1c" "insert lineend"]
      if {[set index [lindex $indices [expr $num - 1]]] eq ""} {
        set index "insert"
      }
    } else {
      set indices [$txtt search -all -- $char "insert linestart" insert]
      if {[set index [lindex $indices end-[expr $num - 1]]] eq ""} {
        set index "insert"
      }
    }

    return $index

  }

  ######################################################################
  # Returns the index of the requested permission.
  # - left       Move the cursor to the left on the current line
  # - right      Move the cursor to the right on the current line
  # - first      First line in file
  # - last       Last line in file
  # - nextchar   Next character
  # - prevchar   Previous character
  # - nextword   Beginning of next word
  # - prevword   Beginning of previous word
  # - firstword  Beginning of first word on the current line
  # - nextfirst  Beginning of first word in next line
  # - prevfirst  Beginning of first word in previous line
  # - column     Move the cursor to the specified column in the current line
  # - linestart  Start of current line
  # - lineend    End of current line
  # - screentop  Top of current screen
  # - screenmid  Middle of current screen
  # - screenbot  Bottom of current screen
  proc get_index {txtt position args} {

    array set opts {
      -num  1
      -char ""
    }
    array set opts $args

    set num $opts(-num)

    # Get the new cursor position
    switch $position {
      left        {
        if {[$txtt compare "insert display linestart" > "insert-${num} display chars"]} {
          set index "insert display linestart"
        } else {
          set index "insert-${num} display chars"
        }
      }
      right       {
        if {[$txtt compare "insert display lineend" < "insert+${num} display chars"]} {
          set index "insert display lineend"
        } else {
          set index "insert+${num} display chars"
        }
      }
      first       {
        if {[$txtt get -displaychars 1.0] eq ""} {
          set index "1.0+1 display chars"
        } else {
          set index "1.0"
        }
      }
      last        { set index "end" }
      nextchar    { set index [get_char $txtt next $num] }
      prevchar    { set index [get_char $txtt prev $num] }
      nextword    { set index [get_word $txtt next $num] }
      prevword    { set index [get_word $txtt prev $num] }
      nextfirst   -
      prevfirst   -
      firstword   {
        switch $position {
          nextfirst {
            if {[$txtt compare [set index [$txtt index "insert+${num} display lines"]] == end]} {
              set index [$txtt index "$index-1 display lines"]
            }
          }
          prevfirst {
            if {[$txtt compare [set index [$txtt index "insert-${num} display lines"]] == end]} {
              set index [$txtt index "$index-1 display lines"]
            }
          }
          default {
            set index "insert"
          }
        }
        if {[lsearch [$txtt tag names "$index linestart"] _prewhite] != -1} {
          set index [lindex [$txtt tag nextrange _prewhite "$index linestart"] 1]-1c
        } else {
          set index "$index lineend"
        }
      }
      column      { set index [lindex [split [$txtt index insert] .] 0].[expr $num - 1] }
      linestart   {
        set index [$txtt index "insert linestart+1 display chars"]
        if {[$txtt compare "$index-1 display chars" >= "$index linestart"]} {
          set index "$index-1 display chars"
        }
      }
      lineend     {
        if {$num == 1} {
          set index "insert lineend-1 display chars"
        } else {
          set index [$txtt index "insert+[expr $num - 1] display lines"]
          set index "$index lineend-1 display chars"
        }
      }
      screentop   { set index "@0,0" }
      screenmid   { set index "@0,[expr [winfo height $txtt] / 2]" }
      screenbot   { set index "@0,[winfo height $txtt]" }
      nextfind    {
        if {[set index [find_char $txtt next $opts(-char) $num]] ne "insert"} {
          set index [$txtt index $index-1c]
        }
      }
      prevfind    {
        if {[set index [find_char $txtt prev $opts(-char) $num]] ne "insert"} {
          set index [$txtt index $index+1c]
        }
      }
      nextfindinc { set index [find_char $txtt next $opts(-char) $num] }
      prevfindinc { set index [find_char $txtt prev $opts(-char) $num] }
      default     { set index insert }
    }

    return $index

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
    multicursor::adjust $txtt $modifier

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
