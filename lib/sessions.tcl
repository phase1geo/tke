# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:    sessions.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    8/3/2015
# Brief:   Namespace for session support.
######################################################################

namespace eval sessions {

  variable user_name    ""
  variable current_name ""

  array set names           {}
  array set current_content {}

  set sessions_dir [file join $::tke_home sessions]

  ######################################################################
  # Loads the names of all available sessions.  This should be called
  # before any sessions are loaded.
  proc preload {} {

    variable names
    variable sessions_dir

    if {[file exists $sessions_dir]} {
      foreach name [glob -nocomplain -directory $sessions_dir -tails *.tkedat] {
        set names([file rootname $name]) 1
      }
    }

  }

  ######################################################################
  # Save the current settings as a given session.  The legal values for
  # type are the following:
  #   - last  = Save information useful for the next time TKE is started.
  #   - prefs = Only save preference information to the session file, leaving the rest intact.
  #   - find  = Only save find information to the session file, leaving the rest intact.
  #   - full  = Save all information
  proc save {type {name ""}} {

    variable user_name
    variable names
    variable current_name
    variable current_content
    variable sessions_dir

    # If we are being told to save the last session, set the name to the session.tkedat file
    if {$type eq "last"} {
      set name [file join $::tke_home session]
    }

    # If the name has not been specified, ask the user for a name
    if {$name eq ""} {
      if {[gui::get_user_response "Session name:" sessions::user_name]} {
        set name         $user_name
        set names($name) 1
        set current_name $name
      } else {
        return
      }
    }

    # Create the sessions directory if it does not exist
    if {![file exists $sessions_dir]} {
      file mkdir $sessions_dir
    }

    # If we are saving preferences only, set the value of content to match
    # the currently loaded session.
    if {($type eq "prefs") || ($type eq "find")} {

      # Get the current content information
      array set content [array get current_content]

      # Make sure that the content(session) is not set
      catch { unset content(session) }

    # Update and save the UI state on a full/last save
    } else {

      # Get the session information from the UI
      set content(gui) [gui::save_session]

      # Set the session name if we are saving the last
      if {$type eq "last"} {
        set content(session) $current_name
      }

    }

    # Get the session information from preferences
    if {($type eq "prefs") || ($type eq "full")} {
      set content(prefs) [preferences::save_session $name]
    }

    # Get the find information from the UI
    if {($type eq "find") || ($type eq "full") || ($type eq "last")} {
      set content(find) [search::save_session]
    }

    # Create the session file path
    if {$type eq "last"} {
      set session_file $name.tkedat
    } else {
      set session_file [file join $sessions_dir $name.tkedat]
    }

    # Write the content to the save file
    catch { tkedat::write $session_file [array get content] }

    if {$type eq "full"} {

      # Save the current name
      set current_name $name

      # Update the title
      gui::set_title

      # Indicate to the user that we successfully saved
      gui::set_info_message "Session \"$current_name\" saved"

    } elseif {$type eq "prefs"} {
      gui::set_info_message "Session \"$name\" preferences saved"

    }

  }

  ######################################################################
  # Loads the given session.  The legal values for type are the following:
  #   - last   = Save information useful for the next time TKE is started.
  #   - prefs  = Only save preference information to the session file, leaving the rest intact.
  #   - full   = Save all information
  #   - nosave = Only read the given session name without worrying about saving.
  # Name specifies the base name of the session to load while 'new'
  # specifies whether the session should be loaded in the current window (0)
  # or a new window (1).
  proc load {type name new} {

    variable current_name
    variable current_content
    variable sessions_dir

    # If we need to load the last saved session, set the name appropriately
    if {$type eq "last"} {
      set name         ""
      set session_file [file join $::tke_home session.tkedat]
    } else {
      set session_file [file join $sessions_dir $name.tkedat]
    }

    # If we need to open
    if {$current_name ne ""} {
      if {$new} {
        array set frame [info frame 0]
        exec -ignorestderr [info nameofexecutable] $frame(file) -s $name -n &
        return
      }
    } elseif {($type eq "full") && ![gui::untitled_check]} {
      switch [tk_messageBox -parent . -icon question -default yes -type yesnocancel -message [msgcat::mc "Save session?"] -detail [msgcat::mc "Session state will be lost if not saved"]] {
        yes    { save "full" }
        cancel { return }
      }
    }

    # Read the information from the session file
    if {[catch { tkedat::read $session_file } rc]} {
      gui::set_info_message "Unable to load session \"$name\""
      return
    }

    array set content $rc

    # Clear the UI
    gui::close_all
    sidebar::clear

    # Load the GUI session information (provide backward compatibility)
    if {[info exists content(gui)]} {
      gui::load_session $content(gui) $new
    } else {
      gui::load_session $rc $new
    }

    # Load the find session information
    if {[info exists content(find)]} {
      search::load_session $content(find)
    }

    # Save the current name (provide backward compatibility)
    if {[info exists content(session)] && [file exists [file join $sessions_dir $content(session).tkedat]]} {
      set current_name $content(session)
    } else {
      set current_name $name
    }

    # Load the preference session information (provide backward compatibility)
    if {[info exists content(prefs)]} {
      preferences::load_session $name $content(prefs)
    } elseif {$current_name ne ""} {
      load_prefs $current_name
    }

    # Save the current content
    array set current_content [array get content]

    # Update the title
    gui::set_title

  }

  ######################################################################
  # Load the preferences information for the given session.
  proc load_prefs {name} {

    variable sessions_dir

    # Get the path of the session file
    set session_file [file join $sessions_dir $name.tkedat]

    # Read the information from the session file
    if {[catch { tkedat::read $session_file } rc]} {
      return
    }

    array set content $rc

    # Load the preference session information (provide backward compatibility)
    if {[info exists content(prefs)]} {
      preferences::load_session $name $content(prefs)
    }

  }

  ######################################################################
  # Loads the given session and raises the window.
  proc load_and_raise_window {name} {

    # Load the session in the current window
    after idle [list sessions::load full $name 0]

    # Raise the window
    gui::raise_window

  }

  ######################################################################
  # Closes the currently opened session.
  proc close_current {} {

    variable current_name

    # Clear the current name
    set current_name ""

    # Update the window title
    gui::set_title

    # Load the default preferences
    preferences::update_prefs

  }

  ######################################################################
  # Deletes the session with the given name.
  proc delete {name} {

    variable current_name
    variable names
    variable sessions_dir

    if {[info exists names($name)]} {

      # Confirm the deletion
      if {[tk_messageBox -icon warning -parent . -default no -type yesnocancel -message "Delete session \"$name\"?"] ne "yes"} {
        return
      }

      # Delete the session file
      catch { file delete -force [file join $sessions_dir $name.tkedat] }

      # Delete the name from the names list
      unset names($name)

    }

    # If the name matches the current name, clear the current name and update the title
    if {$current_name eq $name} {
      set current_name ""
      gui::set_title
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

  ######################################################################
  # Returns the list of files in the TKE home directory to copy.
  proc get_share_items {dir} {

    return [list sessions]

  }

  ######################################################################
  # Called whenever the share directory changes.
  proc share_changed {dir} {

    variable sessions_dir

    set sessions_dir [file join $dir sessions]

  }

}
