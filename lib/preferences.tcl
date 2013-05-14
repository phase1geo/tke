# Name:    preferences.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for handling preferences

namespace eval preferences {

  variable preferences_file [file join $::tke_home preferences.dat]
  variable last_mtime       0
  
  array set prefs {}
  
  ######################################################################
  # Loads the preferences file
  proc load {} {
  
    variable preferences_file
    
    # Start polling on the preferences file
    poll
    
    # Add our launcher commands
    launcher::register "Preferences: Edit preferences"        "gui::add_file end $preferences_file"
    launcher::register "Preferences: Use default preferences" "preferences::copy_default"
  
  }
  
  ######################################################################
  # Constantly monitors changes to the tke preferences file.
  proc poll {} {
  
    variable preferences_file
    variable last_mtime
    variable prefs
    variable menus
    
    # If the preferences file does not exist, add it from the data directory
    if {![file exists $preferences_file]} {
      copy_default
    }
    
    # Check for file differences
    file stat $preferences_file stat
    if {$stat(mtime) != $last_mtime} {
      set last_mtime $stat(mtime)
      if {![catch "open $preferences_file r" rc]} {
        array set prefs [read $rc]
        close $rc
      }
    }
    
    # Check every second for a change to the preferences file
    after 1000 [list preferences::poll]
    
  }
  
  ######################################################################
  # Copies the default preference settings into the user's tke directory.
  proc copy_default {} {
  
    variable preferences_file
    
    file copy [file join [file dirname $::tke_dir] data [file tail $preferences_file]] $::tke_home
    
  }
  
}
