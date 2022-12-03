# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2019  Trevor Williams (phase1geo@gmail.com)
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

  variable columns ""

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

    $txtt insert -indentend 0 linestart "\n"
    $txtt cursor move [list lineend -num -1]

  }

  ######################################################################
  # Inserts a blank line below the current line in the given editor.
  proc insert_line_below_current {txtt} {

    # If we are operating in Vim mode, switch to edit mode
    vim::edit_mode $txtt

    $txtt cursor move lineend
    $txtt insert lineend "\n"

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

      # Select all lines, if called to
      if {$line} {
        foreach {start end} $selected {
          $txtt tag add sel "$start linestart" "$end lineend"
        }
      }

      # Delete the selected text
      $txtt delete

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
    if {$adjust && ($insertpos ne "")} {
      $txtt mark set insert $insertpos
    }

  }

  ######################################################################
  # Delete from the current cursor to the end of the line
  proc delete_to_end {txtt copy {num 1}} {
    set espec [list lineend -num $num -adjust +1c]
    if {$copy} {
      $txtt copy cursor $espec
    }
    $txtt delete cursor $espec
  }

  ######################################################################
  # Delete from the start of the current line to just before the current cursor.
  proc delete_from_start {txtt copy} {
    set sspec [list linestart -num $num]
    if {$copy} {
      $txtt copy $sspec cursor
    }
    $txtt delete $sspec cursor
  }

  ######################################################################
  # Delete from the start of the firstchar to just before the current cursor.
  proc delete_to_firstchar {txtt copy} {
    if {$copy} {
      $txtt copy cursor firstchar
    }
    $txtt delete cursor firstchar
  }

  ######################################################################
  # Delete all consecutive numbers from cursor to end of line.
  proc delete_next_numbers {txtt copy} {
    if {$copy} {
      $txtt copy cursor numberend
    }
    $txtt delete cursor numberend
  }

  ######################################################################
  # Deletes all consecutive numbers from the insertion toward the start of
  # the current line.
  proc delete_prev_numbers {txtt copy} {
    if {$copy} {
      $txtt copy numberstart cursor
    }
    $txtt delete numberstart cursor
  }

  ######################################################################
  # Deletes all consecutive whitespace starting from cursor to the end of
  # the line.
  proc delete_next_space {txtt copy} {
    if {$copy} {
      $txtt copy cursor spaceend
    }
    $txtt delete cursor spaceend
  }

  ######################################################################
  # Deletes all consecutive whitespace starting from cursor to the start
  # of the line.
  proc delete_prev_space {txtt copy} {
    if {$copy} {
      $txtt copy spacestart cursor
    }
    $txtt delete spacestart cursor
  }

  ######################################################################
  # Deletes from the current insert postion to (and including) the next
  # character on the current line.
  proc delete_to_next_char {txtt char copy {num 1} {exclusive 0}} {
    set espec [list findchar -dir next -char $char -num $num -exclusive $exclusive]
    if {$copy} {
      $txtt copy cursor $espec
    }
    $txtt delete cursor $espec
  }

  ######################################################################
  # Deletes from the current insert position to (and including) the
  # previous character on the current line.
  proc delete_to_prev_char {txtt char copy {num 1} {exclusive 0}} {
    set sspec [list findchar -dir prev -char $char -num $num -exclusive $exclusive]
    if {$copy} {
      $txtt copy $sspec cursor
    }
    $txtt delete $sspec cursor
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
  # Perform a case toggle operation.
  proc transform_toggle_case {txtt startpos endpos {cursorpos insert}} {
    vim::run_editor_command $txtt [list $txtt transform $startpos $endpos ctext::transform_toggle_case]
  }

  ######################################################################
  # Perform a lowercase conversion.
  proc transform_to_lower_case {txtt startpos endpos {cursorpos insert}} {
    vim::run_editor_command $txtt [list $txtt transform $startpos $endpos lower_case]
  }

  ######################################################################
  # Perform an uppercase conversion.
  proc transform_to_upper_case {txtt startpos endpos} {
    vim::run_editor_command $txtt [list $txtt transform $startpos $endpos upper_case]
  }

  ######################################################################
  # Transforms all text in the given range to rot13.
  proc transform_to_rot13 {txtt startpos endpos} {
    vim::run_editor_command $txtt [list $txtt transform $startpos $endpos rot13]
  }

  ######################################################################
  # Perform a title case conversion.
  proc transform_to_title_case {txtt startpos endpos} {
    vim::run_editor_command $txtt [list $txtt transform $startpos $endpos title_case]
  }

  ######################################################################
  # Transform function.
  proc join_lines_simple {str} {
    return [string map {\n { }} $str]
  }

  ######################################################################
  # If a selection occurs, joins the selected lines; otherwise, joins the
  # number of specified lines.
  proc transform_join_lines {txtt simple num} {

    if {[set cursors [$txtt cursor get]] eq ""} {
      lappend lineends [$txtt index lineend]
    } else {
      foreach index $cursors {
        lappend lineends [$txtt index lineend -startpos $index]
      }
    }

    $txtt edit separator
    $txtt transform lastchar [list firstchar -num [expr ($num == 1) ? 1 : ($num - 1)]] [expr {$simple ? "edit::join_lines_simple" : "join_lines"}]
    $txtt cursor replace wordstart $lineends
    $txtt edit separator

  }

  ######################################################################
  # Moves selected lines or the current line up by one line.
  proc transform_bubble_up {txtt} {
    vim::run_editor_command $txtt [list $txtt transform -cursor {0 firstchar} [list linestart -num -1] lineend bubble_up]
  }

  ######################################################################
  # Moves selected lines or the current line down by one line.
  proc transform_bubble_down {txtt} {
    vim::run_editor_command $txtt [list $txtt transform -cursor {0 {firstchar -num 1}} linestart [list lineend -num 1] bubble_down]
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
  # Comments out the currently selected text in the current text widget.
  proc comment {{txtt ""}} {

    if {$txtt eq ""} {
      set txtt [gui::current_txt].t
    }

    # Get the current text widget
    vim::run_editor_command $txtt [list $txtt transform -cursor {0 firstchar} linestart lineend comment]

    return 1

  }

  ######################################################################
  # Uncomments out the currently selected text in the current text widget.
  proc uncomment {{txtt ""}} {

    if {$txtt eq ""} {
      set txtt [gui::current_txt].t
    }

    vim::run_editor_command $txtt [list $ttxt transform -cursor {0 firstchar} linestart lineend uncomment]

    return 1

  }

  ######################################################################
  # Toggles the toggle status of the currently selected lines in the current
  # text widget.
  proc comment_toggle {{txtt ""}} {

    if {$txtt eq ""} {
      set txtt [gui::current_txt].t
    }

    vim::run_editor_command $txtt [list $txtt transform -cursor {0 firstchar} linestart lineend comment_toggle]

    return 1

  }

  ######################################################################
  # Indents the selected text of the current text widget by one
  # indentation level.
  proc indent {txtt {startpos "insert"} {endpos "insert"}} {
    vim::run_editor_command $txtt [list $txtt indent right $startpos $endpos]
  }

  ######################################################################
  # Unindents the selected text of the current text widget by one
  # indentation level.
  proc unindent {txtt {startpos "insert"} {endpos "insert"}} {
    vim::run_editor_command $txtt [list $txtt indent left $startpos $endpos]
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

    return 1

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
    $txt cursor align

    return 1

  }

  ######################################################################
  # Aligns the current cursors, keeping each multicursor locked to its
  # text.
  proc align_cursors_and_text {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Align multicursors
    $txt cursor align_with_text

    return 1

  }

  ######################################################################
  # Inserts an enumeration when in multicursor mode.
  proc insert_enumeration {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Perform the insertion
    gui::insert_numbers $txt

    return 1

  }

  ######################################################################
  # Handles word/WORD range motions.
  proc get_range_word {txtt type num inner {cursor insert}} {

    if {$inner} {

      # Get the starting position of the selection
      if {[string is space [$txtt get $cursor]]} {
        set startpos [$txtt index spacestart -dir prev -startpos "$cursor+1c"]
      } else {
        set startpos [$txtt index ${type}start -dir prev -startpos "$cursor+1c"]
      }

      # Count spaces and non-spaces
      set endpos $cursor
      for {set i 0} {$i < $num} {incr i} {
        if {$type eq "WORD"} {
          set endpos [$txtt index "$endpos+1c"]
        }
        if {[string is space [$txtt get $endpos]]} {
          set endpos [$txtt index spaceend -dir next -startpos $endpos]
        } else {
          set endpos [$txtt index ${type}end -dir next -startpos $endpos]
        }
      }

    } else {

      set endpos [$txtt index ${type}end -dir next -num $num -startpos [expr {($type eq "word") ? $cursor : "$cursor-1c"}]]

      # If the cursor is within a space, make the startpos be the start of the space
      if {[string is space [$txtt get $cursor]]} {
        set startpos [$txtt index spacestart -dir prev -startpos "$cursor+1c"]

      # Otherwise, the insertion cursor is within a word, if the character following
      # the end of the word is a space, the start is the start of the word while the end is
      # the whitspace after the word.
      } elseif {[$txtt compare "$endpos+1c" < "$endpos lineend"] && [string is space [$txtt get "$endpos+1c"]]} {
        set startpos [$txtt index ${type}start -dir prev -startpos "$cursor+1c"]
        set endpos   [$txtt index spaceend -dir next -startpos "$endpos+1c"]

      # Otherwise, set the start of the selection to the be the start of the preceding
      # whitespace.
      } else {
        set startpos [$txtt index ${type}start -dir prev -startpos "$cursor+1c"]
        if {[$txtt compare $startpos > "$startpos linestart"] && [string is space [$txtt get "$startpos-1c"]]} {
          set startpos [$txtt index spacestart -dir prev -startpos "$startpos-1c"]
        }
      }

    }

    return [list $startpos $endpos]

  }

  ######################################################################
  # Handles WORD range motion.
  proc get_range_WORD {txtt num inner {cursor insert}} {

    if {[string is space [$txtt get $cursor]]} {
      set pos_list [list [$txtt index spacestart -dir prev -startpos "$cursor+1c"] [$txtt index spaceend -dir next -adjust "-1c"]]
    } else {
      set pos_list [list [$txtt index $start -dir prev -startpos "$cursor+1c"] [$txtt index $end -dir next -num $num]]
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

    lset pos_list 1 [$txtt index [lindex $pos_list 1]]

    return $pos_list

  }

  ######################################################################
  # Returns a range the is split by sentences.
  proc get_range_sentences {txtt type num inner {cursor insert}} {

    set pos_list [list [$txtt index $type -dir prev -startpos "$cursor+1c"] [$txtt index $type -dir next -num $num]]

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
  proc get_range_block {txtt type num inner {cursor insert}} {

    # Search backwards
    set txt      [winfo parent $txtt]
    set number   $num
    set startpos [expr {([lsearch [$txtt tag names $cursor] __${type}L] == -1) ? $cursor : "$cursor+1c"}]

    while {[set index [ctext::getMatchBracket $txt ${type}L $startpos]] ne ""} {
      if {[incr number -1] == 0} {
        set right [ctext::getMatchBracket $txt ${type}R $index]
        if {($right eq "") || [$txtt compare $right < $cursor]} {
          return [list "" ""]
        } else {
          return [expr {$inner ? [list [$txt index "$index+1c"] [$txt index $right]] : [list $index [$txt index "$right+1c"]]}]
        }
      } else {
        set startpos $index
      }
    }

    return [list "" ""]

  }

  ######################################################################
  # Returns the text range for the given string type.
  proc get_range_string {txtt char tag inner {cursor insert}} {

    if {[$txtt get $cursor] eq $char} {
      if {[lsearch [$txtt tag names $cursor-1c] __${tag}*] == -1} {
        set index [gui::find_match_char [winfo parent $txtt] $char -forwards]
        return [expr {$inner ? [list [$txtt index "$cursor+1c"] [$txtt index "$index-1c"]] : [list [$txtt index $cursor] [$txtt index $index]]}]
      } else {
        set index [gui::find_match_char [winfo parent $txtt] $char -backwards]
        return [expr {$inner ? [list [$txtt index "$index+1c"] [$txtt index "$cursor-1c"]] : [list $index [$txtt index $cursor]]}]
      }
    } elseif {[set tag [lsearch -inline [$txtt tag names $cursor] __${tag}*]] ne ""} {
      lassign [$txtt tag prevrange $tag $cursor] startpos endpos
      return [expr {$inner ? [list [$txtt index "$startpos+1c"] [$txtt index "$endpos-2c"]] : [list $startpos [$txtt index "$endpos-1c"]]}]
    }

    return [list "" ""]

  }

  ######################################################################
  # Returns the startpos/endpos range based on the supplied arguments.
  proc get_range {txtt pos1args pos2args object {cursor insert}} {

    if {$object ne ""} {

      set type  [lindex $pos1args 0]
      set num   [lindex $pos1args 1]
      set inner [expr {$object eq "i"}]

      switch [lindex $pos1args 0] {
        "word"      { return [get_range_word $txtt word $num $inner $cursor] }
        "WORD"      { return [get_range_word $txtt WORD $num $inner $cursor] }
        "paragraph" { return [get_range_sentences $txtt paragraph $num $inner $cursor] }
        "sentence"  { return [get_range_sentences $txtt sentence  $num $inner $cursor] }
        "tag"       {
          set insert [$txtt index $cursor]
          while {[set ranges [ctext::get_node_range $txtt]] ne ""} {
            if {[incr num -1] == 0} {
              $txtt mark set insert $insert
              if {$inner} {
                return [list [lindex $ranges 1] [$txtt index "[lindex $ranges 2]-1c"]]
              } else {
                return [list [lindex $ranges 0] [$txtt index "[lindex $ranges 3]-1c"]]
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
        "angled" { return [get_range_block $txtt $type $num $inner $cursor] }
        "double" { return [get_range_string $txtt \" comstr0d $inner $cursor] }
        "single" { return [get_range_string $txtt \' comstr0s $inner $cursor] }
        "btick"  { return [get_range_string $txtt \` comstr0b $inner $cursor] }
      }

    } else {

      set pos1 [$txtt index {*}$pos1args -startpos $cursor]

      if {$pos2args ne ""} {
        set pos2 [$txtt index {*}$pos2args -startpos $cursor]
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
    set index [$txtt index $position {*}$args]

    # Set the insertion position and make it visible
    ::tk::TextSetCursor $txtt $index

  }

  ######################################################################
  # Moves the cursor up/down by a single page.  Valid values for dir are:
  # - Next
  # - Prior
  proc move_cursor_by_page {txtt dir} {

    # Adjust the view
    eval [string map {%W $txtt} [bind Text <[string totitle $dir]>]]

  }

  ######################################################################
  # Moves multicursors in the modifier direction for the given text widget.
  proc move_cursors {txtt modifier} {

    # Adjust the cursors
    $txtt cursor move $modifier

  }

  ######################################################################
  # Applies the specified formatting to the given text widget.
  proc format {txtt type} {

    # Get the range of lines to modify
    if {[set ranges [$txtt tag ranges sel]] ne ""} {
      $txtt tag remove sel 1.0 end
    } else {
      if {[$txtt cursor enabled]} {
        foreach cursor [$txtt cursor get] {
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

    # I'm not sure if ranges is really necessary here as the insert, delete, replace can do this calculation for us.

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
                $txtt replace "$start linestart" "$start lineend" $newstr
                if {$oldstr eq ""} {
                  if {($ranges_len == 2) && [$txtt compare $start+1l >= $end]} {
                    $txtt cursor set "$start linestart+${textpos}c"
                  } else {
                    $txtt cursor add "$start linestart+${textpos}c"
                  }
                }
                if {[string first \n $newstr]} {
                  $txtt indent auto "$start linestart" "$start linestart+[string length $newstr]c"
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
            $txtt replace $start $end $newstr
            if {$oldstr eq ""} {
              if {$ranges_len == 2} {
                $txtt cursor set "$start+${textpos}c"
              } else {
                $txtt cursor add [$txtt index "$start+${textpos}c"]
              }
            }
            if {[string first \n $newstr]} {
              $txtt indent auto $start "$start+[string length $newstr]c" 0
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
  proc unformat {txtt} {

    # Get the formatting information for the current text widget
    array set formatting [syntax::get_formatting [winfo parent $txtt]]

    # Get the range of lines to check
    if {[set ranges [$txtt tag ranges sel]] eq ""} {
      if {[$txtt cursor enabled]} {
        set last ""
        foreach mcursor [$txtt cursor get] {
          if {($last eq "") || [$txtt compare "$mcursor linestart" != "$last linestart"]} {
            lappend ranges [$txtt index "$mcursor linestart"] [$txtt index "$mcursor lineend"]
            set last $mcursor
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
            $txtt replace $index "$index+[lindex $lengths $i]c" $str
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
