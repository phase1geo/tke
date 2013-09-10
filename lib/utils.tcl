# Name:      utils.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace for general purpose utility procedures

namespace eval utils {
  
  array set xignore    {}
  array set xignore_id {}

  ##########################################################
  # Useful process for debugging.
  proc stacktrace {} {

    set stack "Stack trace:\n"
    for {set i 1} {$i < [info level]} {incr i} {
      set lvl [info level -$i]
      set pname [lindex $lvl 0]
      if {[namespace which -command $pname] eq ""} {
        for {set j [expr $i + 1]} {$j < [info level]} {incr j} {
          if {[namespace which -command [lindex [info level -$j] 0]] ne ""} {
            set pname "[namespace qualifiers [lindex [info level -$j] 0]]::$pname"
            break
          }
        }
      }
      append stack [string repeat " " $i]$pname
      foreach value [lrange $lvl 1 end] arg [info args $pname] {
        if {$value eq ""} {
          info default $pname $arg value
        }
        append stack " $arg='$value'"
      }
      append stack \n
    }

    return $stack

  }
  
  ###########################################################################
  # Performs the set operation on a given yscrollbar.
  proc set_yscrollbar {sb first last} {
        
    # If everything is displayed, hide the scrollbar
    if {($first == 0) && ($last == 1)} {
      grid remove $sb
    } else {
      grid $sb
      $sb set $first $last
    }

  }
  
  ######################################################################
  # Performs the set operation on a given xscrollbar.
  proc set_xscrollbar {sb first last} {
    
    variable xignore
    variable xignore_id
    
    if {($first == 0) && ($last == 1)} {
      grid remove $sb
      set_xignore $sb 1 0
      set xignore_id($sb) [after 1000 [list utils::set_xignore $sb 0 1]]
    } else {
      if {![info exists xignore($sb)] || !$xignore($sb)} {
        grid $sb
        $sb set $first $last
      }
      set_xignore $sb 0 0
    }
    
  }
  
  ######################################################################
  # Clears the xignore and xignore_id values.
  proc set_xignore {sb value auto} {
  
    variable xignore
    variable xignore_id
        
    # Clear the after (if it exists)
    if {[info exists xignore_id($sb)]} {
      after cancel $xignore_id($sb)
      unset xignore_id($sb)
    }
    
    # Set the xignore value to the specified value
    set xignore($sb) $value
    
  }

  ######################################################################
  # Compares the two text indices.  Returns 0 if the are the same index
  # value.  Returns -1 if index1 is less then index2.  Returns 1 if index1
  # is greater than index2.
  proc compare_indices {index1 index2} {

    if {$index1 eq $index2} {
      return 0
    } else {
      lassign [split $index1 .] line1 col1
      lassign [split $index2 .] line2 col2
      if {$line1 == $line2} {
        if {$col1 < $col2} {
          return -1
        } else {
          return 1
        }
      } elseif {$line1 < $line2} {
        return -1
      } else {
        return 1
      }
    }

  }
  
  ######################################################################
  # Returns the mark of the anchor.
  proc text_anchor {w} {

    if {[info procs ::tk::TextAnchor] ne ""} {
      return [::tk::TextAnchor $w]
    } else {
      return tk::anchor$w
    }

  }

}
