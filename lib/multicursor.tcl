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
# Name:    multicursor.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/15/2013
# Brief:   Namespace to handle cases where multiple cursor support is needed.
######################################################################

namespace eval multicursor {

  source [file join $::tke_dir lib ns.tcl]

  variable selected            0
  variable select_start_line   ""
  variable select_start_column ""
  variable cursor_anchor       ""

  array set copy_cursors {}

  ######################################################################
  # Adds bindings for multicursor support to the supplied text widget.
  proc add_bindings {txt} {

    # Create tag for the multicursor stuff
    $txt tag configure mcursor -underline 1

    # Create multicursor bindings
    bind mcursor$txt <<Selection>>                "[ns multicursor]::handle_selection %W"
    bind mcursor$txt <Mod2-Button-1>              "[ns multicursor]::handle_alt_button1 %W %x %y"
    bind mcursor$txt <Mod2-Button-$::right_click> "[ns multicursor]::handle_alt_button3 %W %x %y"
    bind mcursor$txt <Shift-Mod2-ButtonPress-1>   "[ns multicursor]::handle_shift_alt_buttonpress1 %W %x %y; break"
    bind mcursor$txt <Shift-Mod2-B1-Motion>       "[ns multicursor]::handle_shift_alt_motion %W %x %y; break"
    bind mcursor$txt <Shift-Mod2-ButtonRelease-1> "[ns multicursor]::handle_shift_alt_buttonrelease1 %W %x %y; break"
    bind mcursor$txt <Key-Delete>                 "if {\[[ns multicursor]::handle_delete %W\]} { break }"
    bind mcursor$txt <Key-BackSpace>              "if {\[[ns multicursor]::handle_backspace %W\]} { break }"
    bind mcursor$txt <Return>                     "if {\[[ns multicursor]::handle_return %W\]} { break }"
    bind mcursor$txt <Any-KeyPress>               "if {\[[ns multicursor]::handle_keypress %W %A %K\]} { break }"
    bind mcursor$txt <Escape>                     "[ns multicursor]::handle_escape %W"
    bind mcursor$txt <Button-1>                   "[ns multicursor]::disable %W"

    # Add the multicursor bindings to the text widget's bindtags
    bindtags $txt.t [linsert [bindtags $txt.t] 2 mcursor$txt]

  }

  ######################################################################
  # Handles a selection of the widget in the multicursor mode.
  proc handle_selection {W} {

    variable selected

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
  # Handles a Shift-Alt-Buttonpress-1 event when in multicursor mode.
  proc handle_shift_alt_buttonpress1 {W x y} {

    variable select_start_line
    variable select_start_column

    lassign [split [$W index @$x,$y] .] select_start_line select_start_column
    $W tag remove sel 1.0 end

  }

  ######################################################################
  # Handles a Shift-Alt-Button1-Motion event when in multicursor mode.
  proc handle_shift_alt_motion {W x y} {

    variable select_start_line
    variable select_start_column

    lassign [split [$W index @$x,$y] .] line column
    lassign [split [lindex [$W tag ranges sel] end] .] last_line last_column

    if {($last_line eq "") || ($line != $last_line) || ($column != $last_column)} {
      $W tag remove sel 1.0 end
      for {set i $select_start_line} {$i <= $line} {incr i} {
        $W tag add sel $i.$select_start_column $i.$column
      }
    }

  }

  ######################################################################
  # Handles a Shift-Alt-Buttonrelease-1 event when in multicursor mode.
  proc handle_shift_alt_buttonrelease1 {W x y} {

    variable select_start_line
    variable select_start_column

    set select_start_line   ""
    set select_start_column ""

  }

  ######################################################################
  # Handles a delete key event in multicursor mode.
  proc handle_delete {W} {

    if {![[ns vim]::in_vim_mode $W] && [[ns multicursor]::delete $W "+1c"]} {
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a backspace key event in multicursor mode.
  proc handle_backspace {W} {

    if {![[ns vim]::in_vim_mode $W] && [[ns multicursor]::delete $W "-1c"]} {
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a return key event in multicursor mode.
  proc handle_return {W} {

    if {![[ns vim]::in_vim_mode $W] && [[ns multicursor]::insert $W "\n" [ns indent]::newline]} {
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a keypress event in multicursor mode.
  proc handle_keypress {W A K} {

    if {([string compare -length 5 $K "Shift"]   != 0) && \
        ([string compare -length 7 $K "Control"] != 0) && \
        ![[ns vim]::in_vim_mode $W]} {
      if {[string length $A] == 0} {
        [ns multicursor]::disable $W
      } elseif {[string is print $A] && [[ns multicursor]::insert $W $A [ns indent]::check_indent]} {
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Handles an escape event in multicursor mode.
  proc handle_escape {W} {

    if {[[ns vim]::get_edit_mode $W] eq ""} {
      disable $W
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
  proc adjust_set_and_view {txt prev next} {

    # Add the multicursor
    $txt tag add mcursor $next

    # If our next cursor is going off screen, make it viewable
    if {([$txt bbox $prev] ne "") && ([$txt bbox $next] eq "")} {
      $txt see $next
    }

  }

  ######################################################################
  # Adjusts the cursors by the given suffix.  The valid values for suffix
  # are:
  #  +1c - Adjusts the cursors one character to the right.
  #  -1c - Adjusts the cursors one character to the left.
  #  +1l - Adjusts the cursors one line down.
  #  -1l - Adjusts the cursors one line up.
  #
  # If the insert value is set to 1 and moving the character would cause
  # the cursor to be lost (beginning/end of line or beginning/end of file),
  # a line or character will be inserted and the cursor set to that position.
  # The inserted text will be given the tag name of "insert_tag".
  proc adjust {txt suffix {insert 0} {insert_tag ""}} {

    if {[string index $suffix 0] eq "+"} {

      # If any of the cursors would "fall off the edge", don't modify any of them
      if {!$insert && ([string index $suffix end] eq "c")} {
        foreach {start end} [$txt tag ranges mcursor] {
          if {[$txt compare $start == "$start lineend-1c"]} {
            return
          }
        }
      }

      # Move the cursors
      switch $suffix {
        "+1c" {
          foreach {end start} [lreverse [$txt tag ranges mcursor]] {
            $txt tag remove mcursor $start
            if {[$txt compare $start == "$start lineend-1c"]} {
              if {$insert} {
                $txt insert "$start+1c" " "
                if {$insert_tag ne ""} {
                  $txt tag add $insert_tag "$start+1 display char"
                }
                adjust_set_and_view $txt $start "$start+1 display char"
              } else {
                $txt tag add mcursor $start
                break
              }
            } else {
              adjust_set_and_view $txt $start "$start+1c"
            }
          }
        }
        "+1l" {
          foreach {end start} [lreverse [$txt tag ranges mcursor]] {
            $txt tag remove mcursor $start
            lassign [split $start .] row col
            set pos $row.end
            set pos [$txt search \n "$pos+1c" end]
            if {$pos eq ""} {
              $txt tag add mcursor $start
              break
            } else {
              set row [lindex [split $pos .] 0]
              if {$insert} {
                $txt insert "$start lineend" "\n "
                if {$insert_tag ne ""} {
                  $txt tag add $insert_tag $row.0
                }
                adjust_set_and_view $txt $start $row.0
              } else {
                adjust_set_and_view $txt $start $row.$col
              }
            }
          }
        }
      }

    } else {

      # If any of the cursors would "fall off the edge", don't adjust any of them
      if {!$insert && ([string index $suffix end] eq "c")} {
        foreach {start end} [$txt tag ranges mcursor] {
          if {[$txt compare $start == "$start linestart"]} {
            return
          }
        }
      }

      # Adjust the cursors
      switch $suffix {
        "-1c" {
          foreach {start end} [$txt tag ranges mcursor] {
            $txt tag remove mcursor $start
            if {[$txt compare $start == "$start linestart"]} {
              if {$insert} {
                $txt insert $start " "
                if {$insert_tag ne ""} {
                  $txt tag add $insert_tag $start
                }
                $txt tag add mcursor $start
              } else {
                $txt tag add mcursor $start
                break
              }
            } else {
              adjust_set_and_view $txt $start "$start-1c"
            }
          }
        }
        "-1l" {
          foreach {start end} [$txt tag ranges mcursor] {
            $txt tag remove mcursor $start
            if {$insert} {
              $txt insert "$start linestart" " \n"
              if {$insert_tag ne ""} {
                $txt tag add $insert_tag "$start linestart"
              }
              adjust_set_and_view $txt $start "$start linestart"
            } elseif {[$txt compare $start >= 2.0]} {
              adjust_set_and_view $txt $start "$start-1 display line"
            } else {
              $txt tag add mcursor $start
              break
            }
          }
        }
      }

    }

  }

  ######################################################################
  # Handles the deletion key.  The value of suffix defines what text will
  # be deleted.  The following is a listing of valid values for suffix:
  # - selected  = Forces selected text to be deleted (by default this is detected)
  # - line      = Delete the entire line of the current cursor.
  # - word      = Delete the number of words from the current cursor.
  # - linestart = Delete the line from the start to the current cursor.
  # - lineend   = Delete the line from the current cursor to the end of the line.
  # - pattern   = Delete if the start of the text matches the given pattern.
  # - -#type    = Delete # of types prior to the cursor to the cursor.
  # - +#type    = Delete from the cursor to # of types after the cursor.
  proc delete {txtt suffix {data ""}} {

    variable selected

    set start   1.0
    set ranges  [list]
    set do_tags [list]
    set txt     [winfo parent $txtt]

    # Only perform this if multiple cursors
    if {[enabled $txtt]} {

      if {$selected || ($suffix eq "selected")} {
        while {[set range [$txt tag nextrange sel $start]] ne [list]} {
          lassign $range start end
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt fastdelete -update 0 $start $end
          lappend ranges $start $end
          if {([$txtt compare $start == "$start linestart"]) || \
              ([$txtt compare $start != "$start lineend"])} {
            add_cursor $txtt $start
            set start "$start+2c"
          } else {
            add_cursor $txtt "$start-1c"
            set start "$start+1c"
          }
        }
        set selected 0

      } elseif {$suffix eq "line"} {
        while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
          set start [$txt index "[lindex $range 0] linestart"]
          set end   [$txt index "[lindex $range 1] lineend"]
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt fastdelete -update 0 $start $end
          add_cursor $txt.t $start
          lappend ranges $start $end
          set start "$start+2c"
        }

      } elseif {$suffix eq "word"} {
        while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
          set start [$txt index "[lindex $range 0] wordstart"]
          set end   [[ns edit]::get_word $txtt next [expr $data - 1] $start]
          if {[$txt compare $end > "$start lineend"]} {
            set end [$txt index "$start lineend"]
          }
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt fastdelete -update 0 $start $end
          lappend ranges $start $end
          if {([$txtt compare $start == "$start linestart"]) || \
              ([$txtt compare $start != "$start lineend"])} {
            add_cursor $txtt $start
            set start "$start+2c"
          } else {
            add_cursor $txtt "$start-1c"
            set start "$start+1c"
          }
        }

      } elseif {$suffix eq "linestart"} {
        while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
          set start [$txt index "[lindex $range 0] linestart"]
          set end   [lindex $range 0]
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt fastdelete -update 0 $start $end
          lappend ranges $start $end
          set start "$start+2c"
        }

      } elseif {$suffix eq "lineend"} {
        while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
          set start [lindex $range 0]
          set end   [$txt index "[lindex $range 0] lineend"]
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt fastdelete -update 0 $start $end
          lappend ranges $start $end
          if {([$txtt compare $start == "$start linestart"]) || \
              ([$txtt compare $start != "$start lineend"])} {
            add_cursor $txtt $start
            set start "$start+2c"
          } else {
            add_cursor $txtt "$start-1c"
            set start "$start+1c"
          }
        }

      } elseif {$suffix eq "pattern"} {
        if {[string index $data 0] eq "^"} {
          while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
            set start [lindex $range 0]
            if {[regexp $data [$txt get $start "$start lineend"] match]} {
              set end [$txt index "$start+[string length $match]c"]
              ctext::comments_chars_deleted $txt $start $end do_tags
              $txt fastdelete -update 0 $start $end
              lappend ranges $start $end
              if {([$txtt compare $start == "$start linestart"]) || \
                  ([$txtt compare $start != "$start lineend"])} {
                add_cursor $txtt $start
                set start "$start+2c"
              } else {
                add_cursor $txtt "$start-1c"
                set start "$start+1c"
              }
            } else {
              set start "$start+2c"
            }
          }
        } else {
          while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
            set start [lindex $range 0]
            if {[regexp $data [$txt get "$start linestart" $start] match]} {
              set start [$txt index "[lindex $range 0]-[string length $match]c"]
              set end   [lindex $range 0]
              ctext::comments_chars_deleted $txt $start $end do_tags
              $txt fastdelete -update 0 $start $end
              lappend ranges $start $end
            }
            set start "$start+2c"
          }
        }

      } elseif {[string index $suffix 0] eq "-"} {
        while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
          set start [lindex $range 0]
          if {[$txt compare "$start$suffix" < "$start linestart"]} {
            set start [$txt index "[lindex $range 0] linestart"]
          } else {
            set start [$txt index "[lindex $range 0]$suffix"]
          }
          set end [lindex $range 0]
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt fastdelete -update 0 $start $end
          lappend ranges $start $end
          set start "[lindex $range 0]$suffix+2c"
        }

      } else {
        while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
          set start [lindex $range 0]
          if {[$txt compare "$start$suffix" >= "$start lineend"]} {
            set end [$txt index "$start lineend"]
          } else {
            set end [$txt index "$start$suffix"]
          }
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt fastdelete -update 0 $start $end
          lappend ranges $start $end
          if {([$txtt compare $start == "$start linestart"]) || \
              ([$txtt compare $start != "$start lineend"])} {
            add_cursor $txtt $start
            set start "$start+2c"
          } else {
            add_cursor $txtt "$start-1c"
            set start "$start+1c"
          }
        }
      }

      $txt highlight -dotags $do_tags {*}$ranges

      foreach {start end} $ranges {
        set linestart [$txt._t index "$start linestart"]
        set lineend   [$txt._t index "$end+1c lineend"]
        ctext::modified $txt 1 [list delete [list $linestart $lineend] [list]]
      }

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
        set start "$start+[expr $valuelen + 1]c"
        lappend ranges {*}$range
      }
      $txtt highlight -insert 1 -dotags $do_tags {*}$ranges
      foreach {start end} $ranges {
        ctext::modified $txt 1 [list insert [list $start $end] [list]]
      }
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
        while {[set range [$txt tag nextrange mcursor $start]] ne [list]} {
          lassign $range start end
          ctext::comments_chars_deleted $txt $start $end do_tags
          $txt fastreplace -update 0 $start "$start+1c" $value
          ctext::comments_do_tag $txt $start "$start+${valuelen}c" do_tags
          $txt tag add mcursor "$start+${valuelen}c"
          set start "$start+[expr $valuelen + 1]c"
          lappend ranges {*}$range
        }
        $txt highlight -insert 1 -dotags $do_tags {*}$ranges
        foreach {start end} $ranges {
          ctext::modified $txt 1 [list delete [list $start $end] [list]]
          ctext::modified $txt 1 [list insert [list $start $end] [list]]
        }
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
    if {[set d_added [regexp {^[0-9]+$} $numstr]]} {
      set numstr "d$numstr"
    }

    # Parse the number string to verify that it's valid
    if {[regexp {^(.*)((b[0-1]*)|(d[0-9]*)|(o[0-7]*)|([xh][0-9a-fA-F]*))$} $numstr -> prefix numstr]} {

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

      # Handle the value insertions
      switch [string tolower [string index $numstr 0]] {
        b {
          set num [expr 0b$num + ($num_mcursors - 1)]
          foreach {end start} $mcursors {
            set binRep [binary format c $num]
            binary scan $binRep B* binStr
            $txt insert $start [format "%s%s%s%s" $prefix [string index $numstr 0] [string trimleft [string range $binStr 0 end-1] 0] [string index $binStr end]]
            incr num -1
          }
        }
        d {
          set num [expr $num + ($num_mcursors - 1)]
          foreach {end start} $mcursors {
            $txt insert $start [format "%s%s%d" $prefix [expr {$d_added ? "" : [string index $numstr 0]}] $num]
            incr num -1
          }
        }
        o {
          set num [expr 0o$num + ($num_mcursors - 1)]
          foreach {end start} $mcursors {
            $txt insert $start [format "%s%s%o" $prefix [string index $numstr 0] $num]
            incr num -1
          }
        }
        h -
        x {
          set num [expr 0x$num + ($num_mcursors - 1)]
          foreach {end start} $mcursors {
            $txt insert $start [format "%s%s%x" $prefix [string index $numstr 0] $num]
            incr num -1
          }
        }
      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Aligns all of the cursors by inserting spaces prior to each cursor
  # that is less than the one in the highest column position.  If multiple
  # cursors exist on the same line, the cursor in the lowest column position
  # is used.
  proc align {txt} {

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
