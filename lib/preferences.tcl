# Name:    preferences.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for handling preferences

namespace eval preferences {

  variable base_preferences_file [file join [file dirname $::tke_dir] data preferences.tkedat]
  variable user_preferences_file [file join $::tke_home preferences.tkedat]
  
  array set prefs {}
  
  ######################################################################
  # Loads the preferences file
  proc load {} {
  
    variable base_preferences_file
    variable user_preferences_file
    
    # Load the preferences file contents
    load_file
    
    # Add our launcher commands
    launcher::register "Preferences: Edit user preferences" \
      [list gui::add_file end $user_preferences_file -savecommand preferences::load_file]
    launcher::register "Preferences: View global preferences" \
      [list gui::add_file end $base_preferences_file -lock 1 -readonly 1] 
    launcher::register "Preferences: Use default preferences" "preferences::copy_default"
    launcher::register "Preferences: Reload preferences" "preferences::load_file"
  
  }
  
  ######################################################################
  # Constantly monitors changes to the tke preferences file.
  proc load_file {} {
  
    variable base_preferences_file
    variable user_preferences_file
    variable prefs
    variable menus
    
    # If the preferences file does not exist, add it from the data directory
    if {[file exists $user_preferences_file]} {
      if {![catch "tkedat::read $base_preferences_file" rc]} {
        array set prefs $rc
      }
    } else {
      copy_default 0
    }
    
    # Check for file differences
    if {![catch "tkedat::read $user_preferences_file" rc]} {
      array set prefs $rc
    }
    
  }
  
  ######################################################################
  # Copies the default preference settings into the user's tke directory.
  proc copy_default {{load 1}} {
  
    variable base_preferences_file
    
    # Copy the default file to the tke_home directory
    file copy -force $base_preferences_file $::tke_home
    
    # Load the preferences file
    if {$load} {
      load_file
    }
    
  }
  
}

