# Name:    multicursor.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/15/2013
# Brief:   Namespace to handle cases where multiple cursor support is needed.

namespace eval multicursor {
 
  ######################################################################
  # Adds bindings for multicursor support to the supplied text widget.
  proc add_bindings {txt} {
    
#    bind mcursor$txt <Key-Delete>    "catch { puts A; if {[multicursor::delete $txt]} { break } } rc; puts $rc"
    bind mcursor$txt <Key-Delete>    "puts %W; multicursor::delete $txt"
    bind mcursor$txt <Key-BackSpace> "puts B; if {[multicursor::delete $txt]} { break }"
    
    bindtags $txt.t [linsert [bindtags $txt.t] 2 mcursor$txt]

    puts "bindtags: [bindtags $txt.t]"
    
  }
  
  ######################################################################
  # Returns 1 if multiple selections exist; otherwise, returns 0.
  proc multiple {txt} {
    
    puts "In multiple, sel: [$txt tag ranges sel]"

    return [expr [llength [$txt tag ranges sel]] > 2]
    
  }
  
  ######################################################################
  # Handles the deletion key.
  proc delete {txt} {
    
    puts "HERE 1"

    # Only perform this if muliple cursors
    if {[multiple $txt]} {
      puts "HERE A"
      foreach {start end} [$txt tag ranges sel] {
        $txt delete $start $end
      }
      return 1
    }
    
    return 0
    
  }
   
}
