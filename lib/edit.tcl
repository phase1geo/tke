# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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
  proc insert_line_above_current {txtt} {

    # If we are operating in Vim mode,
    [ns vim]::edit_mode $txtt
    
    # Create the new line
    if {[[ns multicursor]::enabled $txtt]} {
      [ns multicursor]::adjust $txtt "-1l" 1 dspace
    } else {
      $txtt insert "insert linestart" "\n"
    }
    
    # Place the insertion cursor
    ::tk::TextSetCursor $txtt "insert-1l"
    
    # Perform the proper indentation
    [ns indent]::newline $txtt insert
    
    # Start recording
    [ns vim]::record_start
    
  }

  ######################################################################
  # Inserts a blank line below the current line in the given editor.
  proc insert_line_below_current {txtt} {

    # If we are operating in Vim mode, switch to edit mode
    [ns vim]::edit_mode $txtt

    # Get the current insertion point
    set insert [$txtt index insert]

    # Add the line(s)
    if {[[ns multicursor]::enabled $txtt]} {
      [ns multicursor]::adjust $txtt "+1l" 1 dspace
    } else {
      $txtt insert "insert lineend" "\n"
    }

    # Perform the insertion
    if {$insert == [$txtt index insert]} {
      ::tk::TextSetCursor $txtt "insert+1l"
    }
    $txtt see insert

    # Perform the proper indentation
    [ns indent]::newline $txtt insert

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
  proc delete_current_line {txtt {num ""}} {

    # Clear the clipboard
    clipboard clear

    # Add the text to be deleted to the clipboard and delete the text
    if {$num ne ""} {
      clipboard append [$txtt get "insert linestart" "insert linestart+[expr $num - 1]l lineend"]\n
      $txtt delete "insert linestart" "insert linestart+${num}l"
    } else {
      clipboard append [$txtt get "insert linestart" "insert lineend"]\n
      $txtt delete "insert linestart" "insert linestart+1l"
    }

  }

  ######################################################################
  # Deletes the current word (i.e., dw Vim mode).
  proc delete_current_word {txtt {num ""}} {

    # Clear the clipboard
    clipboard clear

    if {$num ne ""} {
      set word [get_word $txtt next [expr $num - 1]]
      clipboard append [$txtt get "insert wordstart" "$word wordend"]
      $txtt delete "insert wordstart" "$word wordend"
    } else {
      clipboard append [$txtt get "insert wordstart" "insert wordend"]
      $txtt delete "insert wordstart" "insert wordend"
    }

  }

  ######################################################################
  # Delete from the current cursor to the end of the line
  proc delete_to_end {txtt} {

    # Delete from the current cursor to the end of the line
    if {[[ns multicursor]::enabled $txtt]} {
      [ns multicursor]::delete $txtt "lineend"
    } else {
      clipboard clear
      clipboard append [$txtt get insert "insert lineend"]
      $txtt delete insert "insert lineend"
    }

  }

  ######################################################################
  # Delete from the start of the current line to just before the current cursor.
  proc delete_from_start {txtt} {

    # Delete from the beginning of the line to just before the current cursor
    if {[[ns multicursor]::enabled $txtt]} {
      [ns multicursor]::delete $txtt "linestart"
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

    if {[[ns multicursor]::enabled $txtt]} {
      foreach key [list pnumber nnumber] {
        [ns multicursor]::delete $txtt pattern $patterns($key)
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
      [ns multicursor]::delete $txtt pattern $patterns(nspace)
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
      [ns multicursor]::delete $txtt pattern $patterns(pspace)
    } elseif {[regexp $patterns(pspace) [$txtt get "insert linestart" insert] match]} {
      $txtt delete "insert-[string length $match]c" insert
    }

  }

  ######################################################################
  # Get the start and end positions for the pair defined by char.
  proc get_char_positions {txtt endchar} {

    array set pairs {\{ \} \} \{ \( \) \) \( \[ \] \] \[ < > > <}

    # Initialize
    set retval [set end_index 0]

    # Get the matching character
    if {[info exists pairs($endchar)]} {
      if {[set start_index [[ns gui]::find_match_pair $txtt $pairs($endchar) $endchar -backwards]] != -1} {
        set retval [expr {[set end_index [[ns gui]::find_match_pair $txtt $endchar $pairs($endchar) -forwards]] != -1}]
      }
    } else {
      if {[set start_index [[ns gui]::find_match_char $txtt $endchar -backwards]] != -1} {
        set retval [expr {[set end_index [[ns gui]::find_match_char $txtt $endchar -forwards]] != -1}]
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
      [ns vim]::set_select_anchor $txtt $start_index+1c
      return 1
    }

    return 0

  }

  ######################################################################
  # Formats all text between the pair of characters.  Returns 1 if a match
  # occurred (and the text was formatted); otherwise, returns 0.
  proc format_between_char {txtt char} {

    if {[lassign [get_char_positions $txtt $char] start_index end_index]} {
      [ns indent]::format_text $txtt $start_index+1c $end_index
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
  # Converts the case to the given type for the entire string.
  proc convert_case_all {txtt index str type} {

    set strlen [string length $str]

    # Replace the text
    $txtt replace $index "$index+${strlen}c" [string to$type $str]

  }

  ######################################################################
  # Converts the case to the given type on a word basis.
  proc convert_case_words {txtt index str type} {

    while {[regexp {^(\w+)(\W*)(.*)$} $str -> word wspace str]} {
      set wordlen [string length $word]
      set strlen  [expr $wordlen + [string length $wspace]]
      $txtt replace $index "$index+${wordlen}c" [string to$type $word]
      set index   [$txtt index "$index+${strlen}c"]
    }

  }

  ######################################################################
  # Perform a case toggle operation.
  proc transform_toggle_case {txtt {num ""}} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        convert_case_toggle $txtt $startpos [$txtt get $startpos $endpos]
      }
      $txtt tag remove sel 1.0 end
    } else {
      set num_chars [expr {($num ne "") ? $num : 1}]
      set str       [string range [$txtt get insert "insert lineend"] 0 [expr $num_chars - 1]]
      convert_case_toggle $txtt insert $str
    }

  }

  ######################################################################
  # Perform a lowercase conversion.
  proc transform_to_lower_case {txtt {num ""}} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        convert_case_all $txtt $startpos [$txtt get $startpos $endpos] lower
      }
      $txtt tag remove sel 1.0 end
    } else {
      set num_chars [expr {($num ne "") ? $num : 1}]
      set str       [string range [$txtt get insert "insert lineend"] 0 [expr $num_chars - 1]]
      convert_case_all $txtt insert $str lower
    }

  }

  ######################################################################
  # Perform an uppercase conversion.
  proc transform_to_upper_case {txtt {num ""}} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        convert_case_all $txtt $startpos [$txtt get $startpos $endpos] upper
      }
      $txtt tag remove sel 1.0 end
    } else {
      set num_chars [expr {($num ne "") ? $num : 1}]
      set str       [string range [$txtt get insert "insert lineend"] 0 [expr $num_chars - 1]]
      convert_case_all $txtt insert $str upper
    }

  }

  ######################################################################
  # Perform a title case conversion.
  proc transform_to_title_case {txtt} {

    if {[llength [set sel_ranges [$txtt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse $sel_ranges] {
        convert_case_words $txtt [$txtt index "$startpos wordstart"] [$txtt get "$startpos wordstart" $endpos] title
      }
      $txtt tag remove sel 1.0 end
    } else {
      set str [$txtt get "insert wordstart" "insert wordend"]
      convert_case_words $txtt [$txtt index "insert wordstart"] $str title
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
          set line    [string trimleft [$txtt get "$lastpos linestart" "$lastpos lineend"]
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
        set str [$txtt get "$end_range+1l linestart" "$end_range+l2 linestart"]
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
      [ns gui]::set_info_message [format "%s (%s)" [msgcat::mc "Filename already exists"] $fname]
      return 0
    } else {
      if {[catch { open $fname w } rc]} {
        [ns gui]::set_info_message [format "%s %s" [msgcat::mc "Unable to write"] $fname]
        return 0
      } else {
        puts $rc [$txt get $from $to]
        close $rc
        [ns gui]::set_info_message [format "%s (%s)" [msgcat::mc "File successfully written"] $fname]
      }
    }

    return 1

  }

  ######################################################################
  # Comments out the currently selected text.
  proc comment {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

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
  proc uncomment {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

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
  proc comment_toggle {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

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
    set indent_str [string repeat " " [[ns indent]::get_shiftwidth $txtt]]

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

    # Position the cursor at the beginning of the first word
    move_cursor $txtt firstword

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
    set unindent_str [string repeat " " [[ns indent]::get_shiftwidth $txtt]]
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

    # Position the cursor at the beginning of the first word
    move_cursor $txtt firstword

    # Create a separator
    $txtt edit separator

  }

  ######################################################################
  # Replaces the current line with the output contents of it as a script.
  proc replace_line_with_script {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Get the current line
    set cmd [$txt get "insert linestart" "insert lineend"]

    # Execute the line text
    catch { exec -ignorestderr {*}$cmd } rc

    # Replace the line with the given text
    $txt replace "insert linestart" "insert lineend" $rc

  }

  ######################################################################
  # Returns true if the current line is empty; otherwise, returns false.
  proc current_line_empty {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    return [expr {[$txt get "insert linestart" "insert lineend"] eq ""}]

  }

  ######################################################################
  # Aligns the current cursors.
  proc align_cursors {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Align multicursors
    multicursor::align $txt

  }

  ######################################################################
  # Inserts an enumeration when in multicursor mode.
  proc insert_enumeration {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Perform the insertion
    gui::insert_numbers $txt

  }

  ######################################################################
  # Jumps to the given line number.
  proc jump_to_line {txt linenum} {

    # Set the insertion cursor to the given line number
    ::tk::TextSetCursor $txt $linenum

    # Adjust the insertion cursor
    [ns vim]::adjust_insert $txt

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

      # Use a brute-force method of finding the next word
      while {[$txt compare $curr_index < end]} {
        if {![string is space [$txt get $curr_index]]} {
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
  # Moves the cursor to a position that is specified by position and num.
  # Valid values for position are:
  # - first      First line in file
  # - last       Last line in file
  # - nextword   Beginning of next word
  # - prevword   Beginning of previous word
  # - firstword  Beginning of first word on the current line
  # - linestart  Start of current line
  # - lineend    End of current line
  # - screentop  Top of current screen
  # - screenmid  Middle of current screen
  # - screenbot  Bottom of current screen
  proc move_cursor {txtt position {num ""}} {

    # Clear the selection
    $txtt tag remove sel 1.0 end

    # Get the new cursor position
    switch $position {
      first     { set index "1.0" }
      last      { set index "end" }
      nextword  { set index [get_word $txtt next [expr {($num eq "") ? 1 : $num}]] }
      prevword  { set index [get_word $txtt prev [expr {($num eq "") ? 1 : $num}]] }
      firstword {
        if {[string is space [$txtt get [set index "insert linestart"]]]} {
          if {[$txtt compare [set index [get_word $txtt next 1 $index]] >= "insert lineend"]} {
            set index "insert lineend"
          }
        }
      }
      linestart { set index "insert linestart" }
      lineend   { set index "insert lineend-1c" }
      screentop { set index "@0,0" }
      screenmid { set index "@0,[expr [winfo height $txtt] / 2]" }
      screenbot { set index "@0,[winfo height $txtt]" }
      default   { set index insert }
    }

    # Set the insertion position and make it visible
    ::tk::TextSetCursor $txtt $index

    # Adjust the insertion cursor in Vim mode
    [ns vim]::adjust_insert $txtt

  }

  ######################################################################
  # Moves the cursor up/down by a single page.  Valid values for dir are:
  # - Next
  # - Prior
  proc move_cursor_by_page {txtt dir} {

    # Adjust the view
    eval [string map {%W $txtt} [bind Text <[string totitle $dir]>]]

    # Adjust the insertion cursor in Vim mode
    [ns vim]::adjust_insert $txtt

  }

  ######################################################################
  # Moves multicursors in the modifier direction for the given text widget.
  proc move_cursors {txtt modifier} {

    # Clear the selection
    $txtt tag remove sel 1.0 end

    # Adjust the cursors
    [ns multicursor]::adjust $txtt $modifier

  }

}
