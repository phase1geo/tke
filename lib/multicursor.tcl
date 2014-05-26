# Name:    multicursor.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/15/2013
# Brief:   Namespace to handle cases where multiple cursor support is needed.

namespace eval multicursor {
  
  variable selected            0
  variable select_start_line   ""
  variable select_start_column ""
  variable cursor anchor       ""
   
  ######################################################################
  # Adds bindings for multicursor support to the supplied text widget.
  proc add_bindings {txt} {
      
    # Create tag for the multicursor stuff
    $txt tag configure mcursor -underline 1

    # Create multicursor bindings
    bind mcursor$txt <<Selection>> {
      set multicursor::selected 0
      if {[llength [set sel [%W tag ranges sel]]] > 2} {
        set multicursor::selected 1
        %W tag remove mcursor 1.0 end
        set i 0
        foreach {start end} $sel {
          %W tag add mcursor $start $end
          incr i
        }
      }
    }
    bind mcursor$txt <Alt-Button-1> {
      multicursor::add_cursor %W [%W index @%x,%y]
    }
    bind mcursor$txt <Alt-Button-3> {
      multicursor::add_cursors %W [%W index @%x,%y]
    }
    
    # Handle a column select
    bind mcursor$txt <Shift-Alt-ButtonPress-1> {
      lassign [split [%W index @%x,%y] .] multicursor::select_start_line multicursor::select_start_column
      %W tag remove sel 1.0 end
      break
    }
    bind mcursor$txt <Shift-Alt-B1-Motion> {
      lassign [split [%W index @%x,%y] .] line column
      lassign [split [lindex [%W tag ranges sel] end] .] last_line last_column
      if {($last_line eq "") || ($line != $last_line) || ($column != $last_column)} {
        %W tag remove sel 1.0 end
        for {set i $multicursor::select_start_line} {$i <= $line} {incr i} {
          %W tag add sel $i.$multicursor::select_start_column $i.$column
        }
      }
      break
    }
    bind mcursor$txt <Shift-Alt-ButtonRelease-1> {
      set multicursor::select_start_line   ""
      set multicursor::select_start_column ""
      break
    }
    
    bind mcursor$txt <Key-Delete> {
      if {![vim::in_vim_mode %W] && [multicursor::delete %W "+1c"]} {
        break
      }
    }
    bind mcursor$txt <Key-BackSpace> {
      if {![vim::in_vim_mode %W] && [multicursor::delete %W "-1c"]} {
        break
      }
    }
    bind mcursor$txt <Return> {
      if {![vim::in_vim_mode %W] && [multicursor::insert %W "\n" indent::newline]} {
        break
      }
    }
    bind mcursor$txt <Any-KeyPress> {
      if {([string compare -length 5 %K "Shift"] != 0) && \
          ([string compare -length 7 %K "Control"] != 0) && \
          ![vim::in_vim_mode %W]} {
        if {[string length %A] == 0} {
          multicursor::disable %W
        } elseif {[string is print %A] && [multicursor::insert %W %A indent::check_indent]} {
          break
        }
      }
    }
    bind mcursor$txt <Escape> {
      if {[vim::in_vim_mode %W]} {
        multicursor::disable %W
      }
    }
    bind mcursor$txt <Button-1> { multicursor::disable %W }
    
    # Add the multicursor bindings to the text widget's bindtags
    bindtags $txt.t [linsert [bindtags $txt.t] 2 mcursor$txt]

  }
  
  ######################################################################
  # Returns 1 if multiple selections exist; otherwise, returns 0.
  proc enabled {txt} {
      
    return [expr [llength [$txt tag ranges mcursor]] > 0]
        
  }
  
  ######################################################################
  # Disables the multicursor mode for the given text widget.
  proc disable {txt} {
    
    variable cursor_anchor
    
    # Clear the start positions value
    $txt tag remove mcursor 1.0 end

    # Clear the current anchor
    set cursor_anchor ""
  
  }
  
  ######################################################################
  # Set a multicursor at the given index.
  proc add_cursor {txt index} {
    
    variable cursor_anchor
    
    if {[$txt index "$index lineend"] eq $index} {
      $txt insert $index " "
    }
    
    if {[llength [set mcursors [lsearch -inline [$txt tag names $index] mcursor*]]] == 0} {
      $txt tag add mcursor $index
    } else {
      $txt tag remove mcursor $index
    }
    
    # Set the cursor anchor to the current index
    set cursor_anchor $index
      
  }
  
  ######################################################################
  # Set multicursors between the anchor and the current line.
  proc add_cursors {txt index} {
    
    variable cursor_anchor
    
    if {$cursor_anchor ne ""} {
      
      # Get the anchor line and column
      lassign [split [set orig_anchor $cursor_anchor] .] row col
      
      # Get the current row
      set curr_row [lindex [split $index .] 0]
      
      # Set the cursor
      if {$row < $curr_row} {
        for {set i [expr $row + 1]} {$i <= $curr_row} {incr i} {
          add_cursor $txt $i.$col
        }
      } else {
        for {set i $curr_row} {$i < $row} {incr i} {
          add_cursor $txt $i.$col
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
      foreach {end start} [lreverse [$txt tag ranges mcursor]] {
        $txt tag remove mcursor $start
        switch $suffix {
          "+1c" {
            if {[$txt compare $start == "$start lineend-1c"]} {
              if {$insert} {
                $txt insert "$start+1c" " "
                if {$insert_tag ne ""} {
                  $txt tag add $insert_tag "$start+1c"
                }
                $txt tag add mcursor "$start+1c"
              } else {
                $txt tag add mcursor $start
                break
              }
            } else {
              $txt tag add mcursor "$start+1c"
            }
          }
          "+1l" {
            if {$insert} {
              $txt insert "$start lineend" "\n "
              if {$insert_tag ne ""} {
                $txt tag add $insert_tag "$start+1l linestart"
              }
              $txt tag add mcursor "$start+1l linestart"
            } elseif {[$txt compare $start < "end-1l"]} {
              $txt tag add mcursor "$start+1l"
            } else {
              $txt tag add mcursor $start
              break
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
      foreach {start end} [$txt tag ranges mcursor] {
        $txt tag remove mcursor $start
        switch $suffix {
          "-1c" {
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
              $txt tag add mcursor "$start-1c"
            }
          }
          "-1l" {
            if {$insert} {
              $txt insert "$start linestart" " \n"
              if {$insert_tag ne ""} {
                $txt tag add $insert_tag "$start linestart"
              }
              $txt tag add mcursor "$start linestart"
            } elseif {[$txt compare $start >= 2.0]} {
              $txt tag add mcursor "$start-1l"
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
  # Handles the deletion key.
  proc delete {txt suffix} {
    
    variable selected
    
    # Only perform this if multiple cursors
    if {[enabled $txt]} {
      if {$selected} {
        foreach {start end} [$txt tag ranges mcursor] {
          $txt delete $start $end
          $txt tag add mcursor $start
        }
        set selected 0
      } elseif {$suffix eq "linestart"} {
        foreach {start end} [$txt tag ranges mcursor] {
          $txt delete "$start linestart" $start
          $txt tag add mcursor "$start linestart"
        }
      } elseif {$suffix eq "lineend"} {
        foreach {end start} [lreverse [$txt tag ranges mcursor]] {
          $txt delete $start "$start lineend"
          if {[$txt compare $start > "$start linestart"]} {
            $txt tag add mcursor "$start-1c"
          }
        }
      } elseif {[string index $suffix 0] eq "-"} {
        foreach {start end} [$txt tag ranges mcursor] {
          if {[$txt compare "$start$suffix" < "$start linestart"]} {
            $txt delete "$start linestart" $start
            $txt tag add mcursor "$start$suffix"
          } else {
            $txt delete "$start$suffix" $start
            $txt tag add mcursor "$start$suffix"
          }
        }
      } else {
        foreach {end start} [lreverse [$txt tag ranges mcursor]] {
          if {[$txt compare "$start$suffix" > "$start lineend"]} {
            $txt delete $start "$start lineend"
            $txt tag add mcursor "$start-1c"
          } else {
            $txt delete $start "$start$suffix"
            $txt tag add mcursor $start
          }
        }
      }
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # Handles the insertion of a printable character.
  proc insert {txt value {indent_cmd ""}} {
    
    variable selected

    # Insert the value into the text widget for each of the starting positions
    if {[enabled $txt]} {
      if {$selected} {
        foreach {end start} [lreverse [$txt tag ranges mcursor]] {
          $txt delete $start $end
          $txt tag add mcursor $start
        }
        set selected 0
      }
      set i 1
      foreach {end start} [lreverse [$txt tag ranges mcursor]] {
        $txt insert $start $value
        if {$indent_cmd ne ""} {
          $indent_cmd $txt [$txt index $start+1c]
        }
        incr i
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
   
}
