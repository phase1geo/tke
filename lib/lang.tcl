#!wish8.5

######################################################################
# Name:    lang.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    10/11/2013
# Brief:   Creates new internationalization files and helps to maintain
#          them.
######################################################################

set tke_dir [file dirname [file dirname [file normalize $argv0]]]

namespace eval lang {
  
  array set phrases {}
  
  ######################################################################
  # Gets all of the msgcat::mc procedure calls for all of the library
  # files.
  proc gather_msgcat {} {
    
    variable phrases
    
    foreach src [glob -directory [file join $::tke_dir lib] *.tcl] {
      
      if {![catch "open $src r" rc]} {
        
        # Read the contents of the file and close the file
        set contents [read $rc]
        close $rc
        
        # Store all of the found msgcat::mc calls in the phrases array
        set start 0
        while {[regexp -indices -start $start {\[msgcat::mc\s+\"([^\"]+)\"} $contents -> phrase_index]} {
          set phrase [string range $contents {*}$phrase_index]
          if {[info exists phrases($phrase)]} {
            if {[lindex $phrases($phrase) 0] ne $src} {
              set phrases($phrase) [list General [expr [lindex $phrases($phrase) 1] + 1]]
            } else {
              set phrases($phrase) [list $src [expr [lindex $phrases($phrase) 1] + 1]]
            }
          } else {
            set phrases($phrase) [list $src 1]
          }
          set start [lindex $phrase_index 1]
        }
        
      }
      
    }
    
  }
  
}

# Gather all of the msgcat::mc calls in the library source files
lang::gather_msgcat
