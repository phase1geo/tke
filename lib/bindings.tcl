# Name:    bindings.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/12/2013
# Brief:   Handles menu bindings from configuration file

namespace eval bindings {

  variable bindings_file [file join $::tke_home menu_bindings.dat]
  variable last_mtime    0

  array set menus         {}
  array set menu_bindings {}
  
  #######################
  #  PUBLIC PROCEDURES  #
  #######################
  
  ######################################################################
  # Loads the bindings information
  proc load {} {
  
    variable bindings_file
    
    # If the bindings file does not exist, copy the one from the "data"
    # directory to the tke_home directory.
    if {![file exists $bindings_file]} {
      copy_default
    }
  
    # Start the polling process on the bindings information
    poll
    
    # Add our launcher commands
    launcher::register "Menu Bindings: Edit menu bindings"        "gui::add_file end $bindings_file"
    launcher::register "Menu Bindings: Use default menu bindings" "bindings::copy_default"
  
  }
  
  ########################
  #  PRIVATE PROCEDURES  #
  ########################
  
  ######################################################################
  # Polls on the bindings file in the tke home directory.  Whenever it
  # changes modification time, re-read the file and store it in the
  # menu_bindings array
  proc poll {} {
  
    variable bindings_file
    variable last_mtime
    variable menu_bindings
    variable menus
    
    if {[file exists $bindings_file]} {
      file stat $bindings_file stat
      if {$stat(mtime) != $last_mtime} {
        set last_mtime $stat(mtime)
        if {![catch "open $bindings_file r" rc]} {
          remove_all_bindings
          array set menu_bindings [read $rc]
          close $rc
          foreach mnu [array names menus] {
            apply $mnu
          }
        }
      }
    } else {
      array unset menu_bindings
    }
    
    # Set to poll after 1 second
    after 1000 [list bindings::poll]
  
  }

  ######################################################################
  # Applies the current bindings from the configuration file.
  proc apply {mnu} {

    variable menu_bindings
    variable menus
    
    # Add the menu to the list of menus
    set menus($mnu) 1

    # Iterate through the menu items
    for {set i 0} {$i <= [$mnu index end]} {incr i} {
      if {[$mnu type $i] eq "command"} {
        set label [$mnu entrycget $i -label]
        if {[info exists menu_bindings($mnu/$label)]} {
          $mnu entryconfigure $i -accelerator [bind_to_accelerator $menu_bindings($mnu/$label)]
          bind all <$menu_bindings($mnu/$label)> "$mnu invoke $i"
        }
      }
    }
  
  }
  
  ######################################################################
  # Removes all of the menu bindings.
  proc remove_all_bindings {} {
  
    variable menus
    variable menu_bindings
    
    foreach mnu [array names menus] {
      for {set i 0} {$i <= [$mnu index end]} {incr i} {
        if {[$mnu type $i] eq "command"} {
          set label [$mnu entrycget $i -label]
          if {[info exists menu_bindings($mnu/$label)]} {
            $mnu entryconfigure $i -accelerator ""
            bind all <$menu_bindings($mnu/$label)> ""
          }
        }
      }
    }
   
    # Delete the menu_bindings array
    array unset menu_bindings
    
  }
  
  ######################################################################
  # Convert the Tcl binding to an appropriate accelerator.
  proc bind_to_accelerator {value} {
    
    set accelerator ""
    
    foreach value [split $value -] {
      switch $value {
        Control { append accelerator "Ctrl-" }
        Alt     { append accelerator "Alt-" }
        default {
          if {[regexp {^[A-Z]$} $value]} {
            append accelerator "Shft-$value"
          } else {
            append accelerator [string totitle $value]
          }
        }
      }
    }

    return $accelerator
    
  }
  
  ######################################################################
  # Copies the default settings to the user's .tke directory.
  proc copy_default {} {
  
    variable bindings_file
    
    file copy -force [file join [file dirname $::tke_dir] data [file tail $bindings_file]] $::tke_home
    
  }

}



