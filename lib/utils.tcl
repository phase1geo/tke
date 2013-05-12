# Name:      utils.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace for general purpose utility procedures

namespace eval utils {

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
  # Performs the set operation on a given scrollbar.
  proc set_scrollbar {sb first last} {
  
    # If everything is displayed, hide the scrollbar
    if {($first == 0) && ($last == 1)} {
      grid remove $sb
    } else {
      grid $sb
      $sb set $first $last
    }

  }
  
}
