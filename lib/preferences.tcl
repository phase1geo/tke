# Name:    preferences.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for handling preferences

namespace eval preferences {

  source [file join $::tke_dir lib ns.tcl]
  
  variable base_preferences_file [file join $::tke_dir data preferences.tkedat]
  variable user_preferences_file [file join $::tke_home preferences.tkedat]
  
  array set prefs {}
  
  ######################################################################
  # Returns the preference item for the given name.
  proc get {name} {
  
    variable prefs
    
    return $prefs($name)
    
  }
  
  ######################################################################
  # Loads the preferences file
  proc load {} {
  
    # Load the preferences file contents
    load_file
    
  }
  
  ######################################################################
  # Adds the global preferences file as a readonly file.
  proc view_global {} {
    
    variable base_preferences_file
    
    [ns gui]::add_file end $base_preferences_file -readonly 1 -sidebar 0
    
  }
  
  ######################################################################
  # Adds the user preferences file to the editor, auto-reloading the
  # file when it is saved.
  proc edit_user {} {
    
    variable user_preferences_file
    
    [ns gui]::add_file end $user_preferences_file -sidebar 0 -savecommand preferences::load_file
    
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
      
      # Get the file status information for both the base and user files
      file stat $base_preferences_file base_stat
      file stat $user_preferences_file user_stat
      
      # Read the user preferences file
      if {![catch { [ns tkedat]::read $user_preferences_file } rc]} {
        array set user_prefs $rc
      }
      
      # If the base preferences file was changed since the user file has changed, see if the
      # user file needs to be updated and update it if necessary
      if {$base_stat(mtime) > $user_stat(mtime)} {

        # Read both the base the preferences file
        if {![catch { [ns tkedat]::read $base_preferences_file } rc]} {
          array set base_prefs $rc
        }
        
        # If the preferences are different between the base and user, update the user
        if {[lsort [array names base_prefs]] ne [lsort [array names user_prefs]]} {
          
          # Copy only the members in the user preferences that are in the base preferences
          # (omit the comments)
          foreach name [array names user_prefs] {
            if {[info exists base_prefs($name)] && ([string first ",comment" $name] == -1)} {
              set base_prefs($name) $user_prefs($name)
            }
          }
          
          # Write the base_prefs array to the user preferences file
          if {![catch {[ns tkedat]::write $user_preferences_file [array get base_prefs]} rc]} {
            array set prefs [array get base_prefs]
          }
          
        # Otherwise, assign the user preferences to the 
        } else {
          array set prefs [array get user_prefs]
        }
        
      # Otherwise, just use the user preferences file
      } else {
        array set prefs [array get user_prefs]
      }
        
    } else {
        
      # Copy the base preferences to the user preferences file
      copy_default 0
       
      # Read the contents of the user file
      if {![catch { [ns tkedat]::read $user_preferences_file } rc]} {
        array set prefs $rc
      }
        
    }
    
    # Perform environment variable setting from the General/Variables preference option
    [ns utils]::set_environment $prefs(General/Variables)
    
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

