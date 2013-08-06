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
        indent::remove_indent_levels %W mcursor*
        set i 0
        foreach {start end} $sel {
          %W tag add mcursor $start $end
          indent::add_indent_level %W mcursor$i
          incr i
        }
      }
    }
    bind mcursor$txt <Control-Button-1> {
      multicursor::add_cursor %W [%W index @%x,%y]
    }
    bind mcursor$txt <Control-Button-3> {
      multicursor::add_cursors %W [%W index @%x,%y]
    }
    
    # Handle a column select
    bind mcursor$txt <Shift-ButtonPress-1> {
      lassign [split [%W index @%x,%y] .] multicursor::select_start_line multicursor::select_start_column
      %W tag remove sel 1.0 end
      break
    }
    bind mcursor$txt <Shift-B1-Motion> {
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
    bind mcursor$txt <Shift-ButtonRelease-1> {
      set multicursor::select_start_line   ""
      set multicursor::select_start_column ""
      break
    }
    
    bind mcursor$txt <Key-Delete> {
      if {[multicursor::delete %W "+1c"]} {
        break
      }
    }
    bind mcursor$txt <Key-BackSpace> {
      if {[multicursor::delete %W "-1c"]} {
        break
      }
    }
    # We will want to indent the text if we are a multicursor key event
    bind mcursor$txt <Key-braceleft> {
      if {[multicursor::insert %W %A indent::increment]} {
        break
      }
    }
    bind mcursor$txt <Key-braceright> {
      if {[multicursor::insert %W %A indent::decrement]} {
        break
      }
    }
    bind mcursor$txt <Return> {
      if {[multicursor::insert %W "\n" indent::newline]} {
        break
      }
    }
    bind mcursor$txt <Any-KeyPress> {
      if {([string compare -length 5 %K "Shift"] != 0) && \
          ([string compare -length 7 %K "Control"] != 0) && \
          ![vim::in_vim_mode %W]} {
        if {[string length %A] == 0} {
          multicursor::disable %W
        } elseif {[string is print %A] && [multicursor::insert %W %A]} {
          break
        }
      }
    }
    bind mcursor$txt <Escape>   "multicursor::disable %W"
    bind mcursor$txt <Button-1> "multicursor::disable %W"
    
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

    # Remove the indent levels
    indent::remove_indent_levels $txt mcursor*
    
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
      indent::add_indent_level $txt mcursor[expr [llength [$txt tag ranges mcursor]] / 2]
    } else {
      $txt tag remove mcursor $index
      indent::remove_indent_levels $txt $mcursors
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
        for {set i [expr $curr_row + 1]} {$i <= $row} {incr i} {
          add_cursor $txt $i.$col
        }
      }
      
      # Re-set the cursor anchor
      set cursor_anchor $orig_anchor
      
    }
    
  }
  
  ######################################################################
  # Adjusts the cursors by the given suffix.
  proc adjust {txt suffix {insert 0} {insert_tag ""}} {
    
    puts "In multicursor::adjust, txt: $txt, suffix: $suffix, insert: $insert, insert_tag: $insert_tag"
    
    foreach {end start} [lreverse [$txt tag ranges mcursor]] {
      puts "  start: $start"
      $txt tag remove mcursor $start
      if {$insert} {
        if {($suffix eq "+1c") && [$txt compare $start "$start lineend"]} {
          $txt insert "$start+1c" " "
          if {$insert_tag ne ""} {
            $txt tag add $insert_tag "$start+1c"
          }
          $txt tag add mcursor "$start+1c"
        } elseif {$suffix eq "+1l"} {
          catch {
            $txt insert "$start lineend" "\n "
            if {$insert_tag ne ""} {
              $txt tag add $insert_tag "$start+1l linestart"
            }
            $txt tag add mcursor "$start+1l linestart"
            puts "Setting mcursor [$txt index {$start+1l linestart}]"
          } rc
          puts "  rc: $rc"
        } elseif {$suffix eq "-1l"} {
          $txt insert "$start linestart" " \n"
          if {$insert_tag ne ""} {
            $txt tag add $insert_tag "$start linestart"
          }
          $txt tag add mcursor "$start linestart"
        }
      } else {
        $txt tag add mcursor "$start$suffix"
      }
      break
    }
    
  }
  
  ######################################################################
  # Handles the deletion key.
  proc delete {txt suffix} {
    
    variable selected
    
    # Only perform this if muliple cursors
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
      set i 0
      foreach {end start} [lreverse [$txt tag ranges mcursor]] {
        $txt insert $start $value
        if {$indent_cmd ne ""} {
          $indent_cmd $txt [$txt index $start+1c] mcursor$i
        }
        incr i
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
