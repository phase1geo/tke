namespace eval diff {
  
  ######################################################################
  # Executes the given diff command that produces diff output in unified
  # format.  Updates the specified text widget with the result.  The
  # command must be called only after the file is inserted into the editor.
  # Additionally, the file that is in the editor must be the same version
  # that is associated with the '+++' file in the diff output.
  proc parse_unified_diff {txt cmd} {

    # Execute the difference command
    if {[catch { exec -ignorestderr {*}$cmd } rc]} {
      return -code error "ERROR:  Diff command failed, $rc"
    }
    
    # Reset the diff output
    $txt diff reset

    # Initialize variables
    set adds       0
    set subs       0
    set strSub     ""
    set total_subs 0
     
    # Parse the output
    foreach line [split $rc \n] {
      if {[regexp {^@@\s+\-\d+,\d+\s+\+(\d+),\d+\s+@@$} $line -> tline]} {
        set adds   0
        set subs   0
        set strSub ""
        incr tline $total_subs
      } else {
        if {[regexp {^\+([^+]|$)} $line]} {
          if {$subs > 0} {
            $txt diff sub [expr $tline - $subs] $subs $strSub
            set subs   0
            set strSub ""
          }
          incr adds
        } elseif {[regexp {^\-([^-].*$|$)} $line -> str]} {
          if {$adds > 0} {
            $txt diff add [expr $tline - $adds] $adds
            set adds 0
          }
          append strSub "$str\n"
          incr subs
          incr total_subs
        } else {
          if {$adds > 0} {
            $txt diff add [expr $tline - $adds] $adds
            set adds 0
          } elseif {$subs > 0} {
            $txt diff sub [expr $tline - $subs] $subs $strSub
            set subs   0
            set strSub ""
          }
        }
        incr tline
      }
    }
    
  }
  
}
