# Name:    utils.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace for general purpose utility procedures

namespace eval utils {

  source [file join $::tke_dir lib ns.tcl]
    
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

  ######################################################################
  # Returns the default foreground color.
  proc get_default_foreground {} {

    return [ttk::style configure "." -foreground]
    
  }

  ######################################################################
  # Returns the default background color.
  proc get_default_background {} {

    return [ttk::style configure "." -background]
    
  }

  ######################################################################
  # Converts an RGB value into an HSV value.
  proc rgb_to_hsv {r g b} {
   
    set sorted [lsort -real [list $r $g $b]]
    set temp [lindex $sorted 0]
    set v [lindex $sorted 2]
   
    set bottom [expr {$v-$temp}]
    if {$bottom == 0} {
      set h 0
      set s 0
      set v $v
    } else {
      if {$v == $r} {
        set top [expr {$g-$b}]
        if {$g >= $b} {
          set angle 0
        } else {
          set angle 360
        }
      } elseif {$v == $g} {
        set top [expr {$b-$r}]
        set angle 120
      } elseif {$v == $b} {
        set top [expr {$r-$g}]
        set angle 240
      }
      set h [expr { round( 60 * ( double($top) / $bottom ) + $angle ) }]
    }
   
    if {$v == 0} {
      set s 0
    } else {
      set s [expr { round( 255 - 255 * ( double($temp) / $v ) ) }]
    }
   
    return [list $h $s $v]
   
  }
   
  ######################################################################
  # Converts an HSV value into an RGB value.
  proc hsv_to_rgb {h s v} {
   
    set hi [expr { int( double($h) / 60 ) % 6 }]
    set f  [expr { double($h) / 60 - $hi }]
    set s  [expr { double($s)/255 }]
    set v  [expr { double($v)/255 }]
    set p  [expr { double($v) * (1 - $s) }]
    set q  [expr { double($v) * (1 - $f * $s) }]
    set t  [expr { double($v) * (1 - (1 - $f) * $s) }]
   
    switch -- $hi {
      0 {
        set r $v
        set g $t
        set b $p
      }
      1 {
        set r $q
        set g $v
        set b $p
      }
      2 {
        set r $p
        set g $v
        set b $t
      }
      3 {
        set r $p
        set g $q
        set b $v
      }
      4 {
        set r $t
        set g $p
        set b $v
      }
      5 {
        set r $v
        set g $p
        set b $q
      }
      default {
        error "Wrong hi value in hsv_to_rgb procedure! This should never happen!"
      }
    }
   
    set r [expr {round($r*255)}]
    set g [expr {round($g*255)}]
    set b [expr {round($b*255)}]
   
    return [list $r $g $b]
   
  }
  
  ######################################################################
  # Automatically adjusts the given color by a value equal to diff such
  # that if color is a darker color, the value will be lightened and if
  # color is a lighter color, the value will be darkened.
  proc auto_adjust_color {color diff} {
    
    # Create the lighter version of the primary color
    lassign [winfo rgb . $color] r g b
    lassign [rgb_to_hsv [expr $r >> 8] [expr $g >> 8] [expr $b >> 8]] hue saturation value
    set value [expr ($value < 128) ? ($value + $diff) : ($value - $diff)]
    set rgb   [hsv_to_rgb $hue $saturation $value]
      
    return [format {#%02x%02x%02x} {*}$rgb]

  }
  
}
