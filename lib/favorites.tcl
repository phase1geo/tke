######################################################################
# Name:    favorites.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    07/17/2014
# Brief:   Handles functionality associated with favorite files/directories.
######################################################################

namespace eval favorites {
  
  variable favorites_file [file join $::tke_home favorites.tkedat]
  variable files
  
  ######################################################################
  # Loads the favorite information file into memory.
  proc load {} {
    
    variable favorites_file
    variable files
    
    set files [list]
    
    if {![catch "open $favorites_file r" rc]} {
      set files [::read $rc]
      close $rc
    }
    
  }
  
  ######################################################################
  # Stores the favorite information back out to the file.
  proc store {} {
    
    variable favorites_file
    variable files
    
    if {![catch "open $favorites_file w" rc]} {
      foreach file $files {
        puts $rc $file
      }
      close $rc
    }
    
  }
  
  ######################################################################
  # Adds a file to the list of favorites.
  proc add {fname} {
    
    variable files
    
    # Only add the file if it currently does not exist
    if {[lsearch -index 0 $files $fname] == -1} {
      lappend files [list $fname [FOOBAR]]
    }
    
  }
  
  ######################################################################
  # Returns the normalized filenames based on the current host.
  proc get_files {} {
    
    variable files
    
    return $files
    
  }
  
}

