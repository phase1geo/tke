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
      
      foreach line [split [::read $rc] \n] {
        
        if {[regexp {^\s*#(.*)$} $line -> comment]} {
          lappend comments $comment
        } elseif {[regexp {\S} [set line [string trim $line]]] && \
                  ![regexp {\[.*\]} $line] && \
                  ([llength $line] == 2)} {
          set contents([lindex $line 0]) [lindex $line 1]
          if {$include_comments} {
            set contents([lindex $line 0],comment) $comments
          }
          set comments [list]
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
