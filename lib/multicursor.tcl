# Name:    multicursor.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/15/2013
# Brief:   Namespace to handle cases where multiple cursor support is needed.

namespace eval multicursor {
  
  variable selected 0
   
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
      set index [%W index @%x,%y]
      if {[%W index "$index lineend"] eq $index} {
        %W insert $index " "
      }
      if {[llength [set mcursors [lsearch -inline [%W tag names $index] mcursor*]]] == 0} {
        %W tag add mcursor $index
        indent::add_indent_level %W mcursor[expr [llength [%W tag ranges mcursor]] / 2]
      } else {
        %W tag remove mcursor $index
        indent::remove_indent_levels %W $mcursors
      }
    }
    
    bind mcursor$txt <Key-Delete> {
      if {[multicursor::delete %W]} {
        break
      }
    }
    bind mcursor$txt <Key-BackSpace> {
      if {[multicursor::delete %W]} {
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
      if {[string compare -length 5 %K "Shift"] != 0} {
        if {[string length %A] == 0} {
          multicursor::disable %W
        } elseif {[multicursor::insert %W %A]} {
          break
        }
      }
    }
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
      
    # Clear the start positions value
    $txt tag remove mcursor 1.0 end

    # Remove the indent levels
    indent::remove_indent_levels $txt mcursor*
  
  }
  
  ######################################################################
  # Handles the deletion key.
  proc delete {txt} {
    
    variable selected
        
    # Only perform this if muliple cursors
    if {[enabled $txt]} {
      if {$selected} {
        foreach {start end} [$txt tag ranges mcursor] {
          $txt delete $start $end
          $txt tag add mcursor $start
        }
        set selected 0
      } else {
        foreach {start end} [$txt tag ranges mcursor] {
          $txt tag add mcursor [set position [$txt index $start-1c]]
          $txt delete $start
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
   
}
