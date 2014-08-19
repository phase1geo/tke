######################################################################
# Name:    tkedat.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    08/08/2013
# Brief:   Namespace for reading .tkedat files.
######################################################################

namespace eval tkedat {

  source [file join $::tke_dir lib ns.tcl]
    
  ######################################################################
  # Reads the given tkedat file, stripping/storing comments and verifying
  # that no Tcl commands are called.
  proc read {fname {include_comments 1}} {
    
    array set contents [list]
    
    if {![catch "open $fname r" rc]} {
      
      set comments [list]
      set value_ip 0
      
      foreach line [split [::read $rc] \n] {
        
        if {!$value_ip && [regexp {^\s*#(.*)$} $line -> comment]} {
          lappend comments $comment
        } elseif {!$value_ip && [regexp {^\s*(\{.*?\}|\S+)\s+(\{.*?\}|\S+)\s*$} $line -> key value]} {
          set key   [string map {\{ {} \} {}} $key]
          set value [string map {\{ {} \} {}} $value]
          set contents($key) $value
          if {[regexp {\[.*\]} $contents($key)]} {
            unset contents($key)
          } elseif {$include_comments} {
            set contents($key,comment) $comments
          }
          set comments [list]
        } elseif {!$value_ip && [regexp {^\s*(\{.*?\}|\S+)\s+\{(.*)$} $line -> key value]} {
          set key [string map {\{ {} \} {}} $key]
          if {$include_comments} {
            set contents($key) "$value\n"
          } else {
            set contents($key) [string trim $value]
          }
          set value_ip       1
        } elseif {$value_ip && [regexp {^([^\}]*)$} $line -> value]} {
          if {$include_comments} {
            append contents($key) "$value\n"
          } else {
            append contents($key) " [string trim $value]"
          }
        } elseif {$value_ip && [regexp {^(.*)\}\s*$} $line -> value]} {
          if {$include_comments} {
            append contents($key) "$value"
          } else {
            append contents($key) " [string trim $value]"
          }
          if {[regexp {\[.*\]} [string map {\n { }} $contents($key)]]} {
            unset contents($key)
          } elseif {$include_comments} {
            set contents($key,comment) $comments
          }
          set comments [list]
          set value_ip 0
        }
        
      }
      
      close $rc
      
    } else {
      
      return -code error [msgcat::mc "Unable to open %s for reading" $fname]
      
    }

    return [array get contents]
    
  }
  
  ######################################################################
  # Writes the given array to the given tkedat file, adding the comments
  # back to the file.
  proc write {fname contents} {

    if {![catch "open $fname w" rc]} {

      array set content $contents
      
      foreach name [lsort [array names content]] {
        if {![regexp {,comment$} $name]} {
          if {[info exists content($name,comment)]} {
            foreach comment $content($name,comment) {
              puts $rc "# $comment"
            }
            # puts $rc "\n"
          }
          puts $rc "{$name} {$content($name)}\n"
        }
      }
      
      close $rc
      
    } else {
      
      return -code error [msgcat::mc "Unable to open %s for writing" $fname]
      
    }
    
  }
  
}
