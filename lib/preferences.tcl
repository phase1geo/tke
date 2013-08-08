# Name:    preferences.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for handling preferences

namespace eval preferences {

  variable preferences_file [file join $::tke_home preferences.tkedat]
  
  array set prefs {}
  
  ######################################################################
  # Loads the preferences file
  proc load {} {
  
    variable preferences_file
    
    # Load the preferences file contents
    load_file
    
    # Add our launcher commands
    launcher::register "Preferences: Edit preferences" \
      [list gui::add_file end $preferences_file preferences::load_file]
    launcher::register "Preferences: Use default preferences" "preferences::copy_default"
    launcher::register "Preferences: Reload preferences" "preferences::load_file"
  
  }
  
  ######################################################################
  # Constantly monitors changes to the tke preferences file.
  proc load_file {} {
  
    variable preferences_file
    variable prefs
    variable menus
    
    # If the preferences file does not exist, add it from the data directory
    if {![file exists $preferences_file]} {
      copy_default
    }
    
    # Check for file differences
    if {![catch "tkedat::read $preferences_file" rc]} {
      array set prefs $rc
    }
    
  }
  
  ######################################################################
  # Copies the default preference settings into the user's tke directory.
  proc copy_default {} {
  
    variable preferences_file
    
    # Copy the default file to the tke_home directory
    file copy -force [file join [file dirname $::tke_dir] data [file tail $preferences_file]] $::tke_home
    
    # Load the preferences file
    load_file
    
  }
  
}

