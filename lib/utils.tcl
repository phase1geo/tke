# Name:    utils.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace for general purpose utility procedures

namespace eval utils {
  
  array set xignore    {}
  array set xignore_id {}
  array set vars       {}

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
  # Returns the mark of the anchor.
  proc text_anchor {w} {

    if {[info procs ::tk::TextAnchor] ne ""} {
      return [::tk::TextAnchor $w]
    } else {
      return tk::anchor$w
    }

  }
  
  ######################################################################
  # Parses the given string for any variables and substitutes those
  # variables with their respective values.  If a variable was found that
  # has not been defined, no substitution occurs for it.  The fully
  # substituted string is returned.
  proc perform_substitutions {str} {
    
    variable vars
    
    return [subst [regsub -all {\$([a-zA-Z0-9_]+)} $str {[expr {[info exists vars(\1)] ? $vars(\1) : {&}}]}]]
    
  }
  
  ######################################################################
  # Adds the given environment variables to the environment.
  proc set_environment {var_list} {
    
    variable vars
        
    array unset vars
    
    # Pre-load the vars with the environment variables
    array set vars [array get ::env]
    
    # Load the var_list into vars
    foreach var_pair $var_list {
      set vars([string toupper [lindex $var_pair 0]]) [perform_substitutions [lindex $var_pair 1]]
    }
    
  }
  
  ######################################################################
  # Opens the given filename in an external application, using one of the
  # open terminal commands to determine the proper application to use.
  proc open_file_externally {fname} {
    
    switch -glob $::tcl_platform(os) {
      Darwin {
        catch { exec open $fname }
      }
      Linux* {
        catch { exec xdg-open $fname }
      }
      *Win* {
        return -code error "Internal error:  Unable to open $fname in a Windows environment!"
      }
    }
    
  }

}
