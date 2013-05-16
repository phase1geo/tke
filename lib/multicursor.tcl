# Name:    multicursor.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/15/2013
# Brief:   Namespace to handle cases where multiple cursor support is needed.

namespace eval multicursor {
   
  ######################################################################
  # Adds bindings for multicursor support to the supplied text widget.
  proc add_bindings {txt} {
      
    # Create tag for the multicursor stuff
    $txt tag configure mcursor -background blue

    # Create multicursor bindings
    bind mcursor$txt <<Selection>> {
      if {[llength [set sel [%W tag ranges sel]]] > 1} {
        %W tag remove mcursor 1.0 end
        foreach {start end} $sel {
          %W tag add mcursor $start $end
        }
      }
    }
    bind mcursor$txt <Control-Button-1> {
      %W tag add mcursor [%W index @%x,%y]
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
      if {[multicursor::insert %W %A]} {
        indent::increment %W
        break
      }
    }
    bind mcursor$txt <Key-braceright> {
      if {[multicursor::insert %W %A]} {
        indent::increment %W
        break
      }
    }
    bind mcursor$txt <Key-Return> {
      if {[multicursor::insert %W %A]} {
        indent::newline %W
        break
      }
    }
    bind mcursor$txt <Any-KeyPress> {
      puts "KeyPress: (%A)"
      if {[string length %A] == 0} {
        puts "HERE!  %A"
        multicursor::disable %W
      } elseif {[string is print %A] && [multicursor::insert %W %A]} {
        break
      }
    }
    bind mcursor$txt <Button-1>   "multicursor::disable %W"
    
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
  
  }
  
  ######################################################################
  # Handles the deletion key.
  proc delete {txt} {
        
    # Only perform this if muliple cursors
    if {[enabled $txt]} {
      set i 0
      foreach {start end} [$txt tag ranges mcursor] {
        if {$start != $end} {
          $txt delete $start $end
          $txt tag add mcursor $start
        } else {
          $txt tag add mcursor [set position [$txt index $start-1c]]
          $txt delete $start
        }
        incr i
      }
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # Handles the insertion of a printable character.
  proc insert {txt value} {
    
    # Insert the value into the text widget for each of the starting positions
    if {[enabled $txt]} {
      set i 0
      puts "mcursor: [$txt tag ranges mcursor]"
      foreach {end start} [lreverse [$txt tag ranges mcursor]] {
        puts "  start: $start, end: $end"
        if {$start != $end} {
          $txt delete $start $end
          $txt tag add mcursor $start
        }
        puts "  mcursor: [$txt tag ranges mcursor]"
        $txt insert $start $value
        puts "  mcursor: [$txt tag ranges mcursor], start: $start, value: $value"
        incr i
      }
      puts "mcursor: [$txt tag ranges mcursor]"
      return 1
    }
    
    return 0
  
  }
   
}
