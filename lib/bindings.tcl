# Name:    bindings.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/12/2013
# Brief:   Handles menu bindings from configuration file

namespace eval bindings {

  variable bindings_file [file join $::tke_home menu_bindings.dat]
  variable last_mtime    0

  array set menu_bindings {}
  
  ######################################################################
  # Polls on the bindings file in the tke home directory.  Whenever it
  # changes modification time, re-read the file and store it in the
  # menu_bindings array
  proc poll {} {
  
    variable bindings_file
    variable last_mtime
    variable menu_bindings
    
    if {[file exists $bindings_file]} {
      file stat $bindings_file stat
      if {$stat(mtime) != $last_mtime} {
        set last_mtime $stat(mtime)
        if {![catch "open $bindings_file r" rc]} {
          array unset menu_bindings
          array set menu_bindings [read $rc]
          close $rc
        }
      }
    } else {
      array unset menu_bindings
    }
    
    # Set to poll after 1 second
    after 1000 [bindings::poll]
  
  }

  ######################################################################
  # Applies the current bindings from the configuration file.
  proc apply {mnu} {

    variable menu_bindings

    # Iterate through the menu items
    for {set i 0} {$i <= [$mnu index end]} {incr i} {
      if {[$mnu type $i] eq "command"} {
        set label [$mnu itemcget $i -label]
        if {[info exists menu_bindings($mnu/$label)]} {
          $mnu itemconfigure $i -accelerator $menu_bindings($mnu/$label)
          bind all <$menu_bindings($mnu/$label)> "$mnu invoke $i"
        }
      }
    }
  
  }

}

