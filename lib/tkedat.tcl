######################################################################
# Name:    tkedat.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    08/08/2013
# Brief:   Namespace for reading .tkedat files.
######################################################################

namespace eval tkedat {
  
  ######################################################################
  # Reads the given tkedat file, stripping/storing comments and verifying
  # that no Tcl commands are called.
  proc read {fname} {
    
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
          set contents([lindex $line 0],comment) $comments
          set comments [list]
        }
        
      }
      
      close $rc
      
    } else {
      
      return -code error "Unable to open $fname for reading"
      
    }
    
    return [array get contents]
    
  }
  
  ######################################################################
  # Writes the given array to the given tkedat file, adding the comments
  # back to the file.
  proc write {fname content} {
    
    if {![catch "open $fname w" rc]} {
      
      foreach {key value} $content {
        
        if {![regexp {^(.*),comment$} $key -> basekey] || \
            ![info exists content($basekey)]} {
          if {[info exists content($key,comment)]} {
            foreach comment $content($key,comment) {
              puts $rc "$comment\n"
            }
            puts $rc "\n"
          }
          puts $rc $content($key)
        }
        
      }
      
      close $rc
      
    } else {
      
      return -code error "Unable to open $fname for writing"
      
    }
    
  }
  
}
