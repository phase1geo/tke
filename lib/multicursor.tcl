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
  # Adds bindings for multicursor support to the supplied text widget.
  proc add_bindings {txt} {

    # Create tag for the multicursor stuff
    $txt tag configure mcursor -underline 1
    $txt tag place mcursor visible1

    # Create multicursor bindings
    bind mcursor$txt <<Selection>>                [list multicursor::handle_selection %W]
    bind mcursor$txt <Mod2-Button-1>              [list multicursor::handle_alt_button1 %W %x %y]
    bind mcursor$txt <Mod2-Button-$::right_click> [list multicursor::handle_alt_button3 %W %x %y]
    bind mcursor$txt <Key-Delete>                 "if {\[multicursor::handle_delete %W\]} { break }"
    bind mcursor$txt <Key-BackSpace>              "if {\[multicursor::handle_backspace %W\]} { break }"
    bind mcursor$txt <Return>                     "if {\[multicursor::handle_return %W\]} { break }"
    bind mcursor$txt <Any-KeyPress>               "if {\[multicursor::handle_keypress %W %A %K\]} { break }"
    bind mcursor$txt <Escape>                     [list multicursor::handle_escape %W]
    bind mcursor$txt <Button-1>                   [list multicursor::disable %W]

    # Add the multicursor bindings to the text widget's bindtags
    set all_index [lsearch -exact [bindtags $txt.t] all]
    bindtags $txt.t [linsert [bindtags $txt.t] [expr $all_index + 1] mcursor$txt]

  }

  ######################################################################
  # Called when the specified text widget is destroyed.
  proc handle_destroy_txt {txt} {

    variable copy_cursors

    array unset copy_cursors $txt.t,*

  }

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
  # Handles an Alt-Button-1 event when in multicursor mode.
  proc handle_alt_button1 {W x y} {

    add_cursor $W [$W index @$x,$y]

  }

  ######################################################################
  # Handles an Alt-Button-3 event when in multicursor mode.
  proc handle_alt_button3 {W x y} {

    add_cursors $W [$W index @$x,$y]

  }

  ######################################################################
  # Handles a delete key event in multicursor mode.
  proc handle_delete {W} {

    if {![vim::in_vim_mode $W] && [multicursor::delete $W [list char -dir next] ""]} {
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a backspace key event in multicursor mode.
  proc handle_backspace {W} {

    if {![vim::in_vim_mode $W] && [multicursor::delete $W [list char -dir prev] ""]} {
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a return key event in multicursor mode.
  proc handle_return {W} {

    if {![vim::in_vim_mode $W] && [multicursor::insert $W "\n" indent::newline]} {
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a keypress event in multicursor mode.
  proc handle_keypress {W A K} {

    if {([string compare -length 5 $K "Shift"]   != 0) && \
        ([string compare -length 7 $K "Control"] != 0) && \
        ([string compare -length 3 $K "Alt"]     != 0) && \
        ($K ne "??") && \
        ![vim::in_vim_mode $W]} {
      if {[string length $A] == 0} {
        multicursor::disable $W
      } elseif {[string is print $A] && [multicursor::insert $W $A indent::check_indent]} {
        return 1
      }
    }

    return 0

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
        ::tk::TextSetCursor $W $first
      }

    }

  }

  ######################################################################
  # Returns 1 if multiple selections exist; otherwise, returns 0.
  proc enabled {txtt} {

    return [expr [llength [$txtt tag ranges mcursor]] > 0]

  }

  ######################################################################
  # Disables the multicursor mode for the given text widget.
  proc disable {txtt} {

    variable cursor_anchor

    # Clear the start positions value
    $txtt tag remove mcursor 1.0 end

    # Clear the current anchor
    set cursor_anchor ""

  }

  ######################################################################
  # Set a multicursor at the given index.
  proc add_cursor {txtt index} {

    variable cursor_anchor

    if {[$txtt compare "$index lineend" == $index]} {
      $txtt insert $index " "
    }

    if {[llength [set mcursors [lsearch -inline [$txtt tag names $index] mcursor*]]] == 0} {
      $txtt tag add mcursor $index
    } else {
      $txtt tag remove mcursor $index
    }

    # Set the cursor anchor to the current index
    set cursor_anchor $index

  }

  ######################################################################
  # Set multicursors between the anchor and the current line.
  proc add_cursors {txtt index} {

    variable cursor_anchor

    if {$cursor_anchor ne ""} {

      # Get the anchor line and column
      lassign [split [set orig_anchor $cursor_anchor] .] row col

      # Get the current row
      set curr_row [lindex [split $index .] 0]

      # Set the cursor
      if {$row < $curr_row} {
        for {set i [expr $row + 1]} {$i <= $curr_row} {incr i} {
          add_cursor $txtt $i.$col
        }
      } else {
        for {set i $curr_row} {$i < $row} {incr i} {
          add_cursor $txtt $i.$col
        }
      }

      # Re-set the cursor anchor
      set cursor_anchor $orig_anchor

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
      set new_start [$txtt index [list {*}$posargs -startpos $start]]
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
        $txtt fastinsert -update 0 -undo 0 "$new_start lineend" " " dspace
      }
      adjust_set_and_view $txtt $start $new_start
    }

    # Adjust the selection
    adjust_select $txtt

  }

  ######################################################################
  # Handles multicursor deletion using the esposargs and sposargs parameters
  # for calculating the deletion ranges.
  proc delete {txtt eposargs {sposargs ""} {object ""}} {

    variable selected

    set start   1.0
    set ranges  [list]
    set do_tags [list]
    set txt     [winfo parent $txtt]
    set dat     ""

    # Only perform this if multiple cursors
    if {[enabled $txtt]} {

      # If the motion is not supported, return now
      if {[motion_unsupported $txtt [lindex $eposargs 0]]} {
        return 1
      }

      if {$selected || ($eposargs eq "selected")} {
        set range [$txt tag nextrange sel $start]
        while {$range ne [list]} {
          lassign $range start end
          append dat [$txt get $start $end]
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt tag remove mcursor [lindex $range 0]
          $txt fastdelete -update 0 $start $end
          lappend ranges [$txt index "$start linestart"] [$txt index "$start lineend"]
          set range [$txt tag nextrange sel $start]
          if {([$txtt compare $start == "$start linestart"]) || ([$txtt compare $start != "$start lineend"])} {
            add_cursor $txtt $start
          } else {
            add_cursor $txtt "$start-1c"
          }
        }
        set selected 0

      } else {
        set range [$txt tag nextrange mcursor $start]
        while {$range ne [list]} {
          lassign [edit::get_range $txt $eposargs $sposargs $object 0 [lindex $range 0]] start end
          if {([set next [lindex [$txt tag nextrange mcursor [lindex $range 1]] 0]] ne "") && [$txt compare $end > $next]} {
            set end $next
          }
          append dat [$txt get $start $end]
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt tag remove mcursor [lindex $range 0]
          $txt fastdelete -update 0 $start $end
          lappend ranges [$txt index "$start linestart"] [$txt index "$start lineend"]
          set range [$txt tag nextrange mcursor $start]
          if {([$txtt compare $start == "$start linestart"]) || ([$txtt compare $start != "$start lineend"])} {
            add_cursor $txtt $start
          } else {
            add_cursor $txtt "$start-1c"
          }
        }

      }

      # Highlight and audit brackets
      if {[ctext::highlightAll $txt $ranges 0 $do_tags]} {
        ctext::checkAllBrackets $txt
      } else {
        ctext::checkAllBrackets $txt $dat
      }
      ctext::modified $txt 1 [list delete $ranges ""]

      event generate $txt.t <<CursorChanged>>

      return 1

    }

    return 0

  }

  ######################################################################
  # Handles the insertion of a printable character.
  proc insert {txtt value {indent_cmd ""}} {

    variable selected

    # Insert the value into the text widget for each of the starting positions
    if {[enabled $txtt]} {

      set do_tags [list]
      set txt     [winfo parent $txtt]
      if {$selected} {
        foreach {end start} [lreverse [$txtt tag ranges mcursor]] {
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txtt fastdelete $start $end
          $txtt tag add mcursor $start
        }
        set selected 0
      }
      set start    1.0
      set ranges   [list]
      set valuelen [string length $value]
      while {[set range [$txtt tag nextrange mcursor $start]] ne [list]} {
        set start [lindex $range 0]
        $txtt fastinsert -update 0 $start $value
        ctext::comments_do_tag $txt $start "$start+${valuelen}c" do_tags
        lappend ranges "$start linestart" "$start+${valuelen}c lineend"
        set start "$start+[expr $valuelen + 1]c"
      }
      if {[ctext::highlightAll $txt $ranges 1 $do_tags]} {
        ctext::checkAllBrackets $txt
      } else {
        ctext::checkAllBrackets $txt $value
      }
      ctext::modified $txt 1 [list insert $ranges ""]
      if {$indent_cmd ne ""} {
        set start 1.0
        while {[set range [$txtt tag nextrange mcursor $start]] ne [list]} {
          set start [$indent_cmd $txtt [lindex $range 0] 0]+2c
        }
      } else {
        event generate $txtt <<CursorChanged>>
      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Handle the replacement of a given character.
  proc replace {txtt value {indent_cmd ""}} {

    variable selected

    set txt [winfo parent $txtt]

    # Replace the current insertion cursor with the given value
    if {[enabled $txt]} {
      if {$selected} {
        return [insert $txt $value $indent_cmd]
      } else {
        set start    1.0
        set do_tags  [list]
        set valuelen [string length $value]
        set dat      $value
        while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
          lassign $range start end
          append dat [$txt get $start $end]
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt fastreplace -update 0 $start "$start+1c" $value
          ctext::comments_do_tag $txt $start "$start+${valuelen}c" do_tags
          $txt tag add mcursor "$start+${valuelen}c"
          set start "$start+[expr $valuelen + 1]c"
          lappend ranges {*}$range
        }
        if {[ctext::highlightAll $txt $ranges 1 $do_tags]} {
          ctext::checkAllBrackets $txt
        } else {
          ctext::checkAllBrackets $txt $dat
        }
        ctext::modified $txt 1 [list replace $ranges ""]
        if {$indent_cmd ne ""} {
          set start 1.0
          while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
            set start [$indent_cmd $txtt [lindex $range 0] 0]+2c
          }
        } else {
          event generate $txt.t <<CursorChanged>>
        }
        return 1
      }
    }

    return 0

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
  # Perform text indentation formatting for each multicursor line.
  proc format_text {txtt eposargs sposargs object} {

    if {[enabled [winfo parent $txtt]]} {

      # If the motion is not supported, return now
      if {[motion_unsupported $txtt [lindex $eposargs 0]]} {
        return 1
      }

      foreach {start end} [$txtt tag ranges mcursor] {
        indent::format_text $txtt {*}[edit::get_range $txtt $eposargs $sposargs $object 0 $start]
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
  # Parses the given number string with the format of:
  #   (d|o|x)?<number>+
  # Where d means to parse and insert decimal numbers, o means to parse
  # and insert octal numbers, and x means to parse and insert hexidecimal
  # numbers.  If d, o or x are not specified, d is assumed.
  # Numbers will be inserted at each cursor location such that the first
  # cursor will be replaced with the number specified by <number>+ and
  # each successive cursor will have an incrementing value inserted
  # at its location.
  proc insert_numbers {txt numstr} {

    variable selected

    # If the number string is a decimal number without a preceding 'd' character, add it now
    if {[set d_added [regexp {^[0-9]+([+-]\d*)?$} $numstr]]} {
      set numstr "d$numstr"
    }

    # Parse the number string to verify that it's valid
    if {[regexp -nocase {^(.*)(b[0-1]*|d[0-9]*|o[0-7]*|[xh][0-9a-fA-F]*)([+-]\d*)?$} $numstr -> prefix numstr increment]} {

      # Get the cursors
      set mcursors [lreverse [$txt tag ranges mcursor]]

      # Get the last number
      set num_mcursors [expr ([llength $mcursors] / 2)]

      # If things were selected, delete their characters and re-add the multicursors
      if {$selected} {
        foreach {end start} $mcursors {
          $txt delete $start $end
          $txt tag add mcursor $start
        }
        set selected 0
      }

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

      # Calculate the num and increment values
      if {[string index $increment 0] eq "+"} {
        set increment [string range $increment 1 end]
        set num       [expr $num + (($num_mcursors - 1) * $increment)]
        set increment "-$increment"
      } else {
        set increment [string range $increment 1 end]
        set num       [expr $num - (($num_mcursors - 1) * $increment)]
        set increment "+$increment"
      }

      # Handle the value insertions
      switch [string tolower [string index $numstr 0]] {
        b {
          foreach {end start} $mcursors {
            set binRep [binary format c $num]
            binary scan $binRep B* binStr
            $txt insert $start [format "%s%s%s" $prefix [string trimleft [string range $binStr 0 end-1] 0] [string index $binStr end]]
            incr num $increment
          }
        }
        d {
          foreach {end start} $mcursors {
            $txt insert $start [format "%s%d" $prefix $num]
            incr num $increment
          }
        }
        o {
          foreach {end start} $mcursors {
            $txt insert $start [format "%s%o" $prefix $num]
            incr num $increment
          }
        }
        h -
        x {
          foreach {end start} $mcursors {
            $txt insert $start [format "%s%x" $prefix $num]
            incr num $increment
          }
        }
      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Aligns all multicursors to each other, aligning them to the cursor
  # that is closest to the start of its line.
  proc align {txt} {

    set last_row -1
    set min_col  1000000
    set rows     [list]

    # Find the cursor that is closest to the start of its line
    foreach {start end} [$txt tag ranges mcursor] {
      lassign [split $start .] row col
      if {$row ne $last_row} {
        set last_row $row
        if {$col < $min_col} {
          set min_col $col
        }
        lappend rows $row
      }
    }

    if {[llength $rows] > 0} {

      # Create the cursors list
      foreach row $rows {
        lappend cursors $row.$min_col $row.[expr $min_col + 1]
      }

      # Remove the multicursors
      $txt tag remove mcursor 1.0 end

      # Add the cursors back
      $txt tag add mcursor {*}$cursors

    }

  }

  ######################################################################
  # Aligns all of the cursors by inserting spaces prior to each cursor
  # that is less than the one in the highest column position.  If multiple
  # cursors exist on the same line, the cursor in the lowest column position
  # is used.
  proc align_with_text {txt} {

    set last_row -1
    set max_col  0
    set cursors  [list]

    # Find the cursor position to align to and the cursors to align
    foreach {start end} [$txt tag ranges mcursor] {
      lassign [split $start .] row col
      if {$row ne $last_row} {
        set last_row $row
        if {$col > $max_col} {
          set max_col $col
        }
        lappend cursors [list $row $col]
      }
    }

    # Insert spaces to align all columns
    foreach cursor $cursors {
      $txt insert [join $cursor .] [string repeat " " [expr $max_col - [lindex $cursor 1]]]
    }

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
