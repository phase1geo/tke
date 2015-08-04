namespace eval sessions {

  source [file join $::tke_dir lib ns.tcl]

  variable sessions_dir [file join $::tke_home sessions]
  variable user_name    ""
  variable current_name ""

  array set names {}

  ######################################################################
  # Loads the names of all available sessions.  This should be called
  # before any sessions are loaded.
  proc preload {} {

    variable sessions_dir
    variable names

    if {[file exists $sessions_dir]} {
      foreach name [glob -nocomplain -directory $sessions_dir -tails *.tkedat] {
        set names([file rootname $name]) 1
      }
    }

  }

  ######################################################################
  # Save the current settings as a given session.
  proc save {{name ""}} {

    variable sessions_dir
    variable user_name
    variable names
    variable current_name

    # If the name has not been specified, ask the user for a name
    if {$name eq ""} {
      if {[[ns gui]::get_user_response "Session name:" sessions::user_name 0]} {
        set name         $user_name
        set names($name) 1
      } else {
        return
      }
    }

    # Create the sessions directory if it does not exist
    if {![file exists $sessions_dir]} {
      file mkdir $sessions_dir
    }

    # Get the session information
    set content(gui) [[ns gui]::save_session]

    # Create the session file path
    set session_file [file join $sessions_dir $name.tkedat]

    # Write the content to the save file
    catch { [ns tkedat]::write $session_file [array get content] }

    # Save the current name
    set current_name $name
    
    # Update the title
    [ns gui]::set_title
    
    # Indicate to the user that we successfully saved
    [ns gui]::set_info_message "Session \"$current_name\" saved"

  }

  ######################################################################
  # Loads the given session.
  proc load {name new_window} {

    variable sessions_dir
    variable current_name

    # If we need to open
    if {($current_name ne "") && $new_window} {
      exec -ignorestderr [info nameofexecutable] [file normalize $::argv0] -s $name &
      return
    }

    # Get the path of the session file
    set session_file [file join $sessions_dir $name.tkedat]

    # Read the information from the session file
    if {[catch { [ns tkedat]::read $session_file } rc]} {
      [ns gui]::set_info_message "Unable to load session \"$name\""
      return
    }

    array set content $rc

    # Clear the UI
    [ns gui]::close_all
    [ns sidebar]::clear

    # Load the GUI session information
    [ns gui]::load_session {} $content(gui)

    # Save the current name
    set current_name $name

    # Update the title
    [ns gui]::set_title

  }

  ######################################################################
  # Deletes the session with the given name.
  proc delete {name} {

    variable sessions_dir
    variable current_name
    variable names

    if {[info exists names($name)]} {
      catch { file delete -force [file join $sessions_dir $name.tkedat] }
      unset names($name)
    }
    
    # If the name matches the current name, clear the current name and update the title
    if {$current_name eq $name} {
      set current_name ""
      [ns gui]::set_title
    }

  }

  ######################################################################
  # Returns the current session name.
  proc current {} {

    variable current_name

    return $current_name

  }

  ######################################################################
  # Returns the list of session names.
  proc get_names {} {

    variable names

    return [lsort [array names names]]

  }

}
