# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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
# Name:    preferences.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for handling preferences
######################################################################

namespace eval preferences {

  source [file join $::tke_dir lib ns.tcl]

  variable base_preference_file [file join $::tke_dir data preferences.tkedat]

  array set loaded_prefs  {}
  array set prefs         {}
  array set base_prefs    {}
  array set base_comments {}

  set preferences_dir $::tke_home

  ######################################################################
  # Returns the preference item for the given name.
  proc get {name {dflt ""}} {

    variable prefs

    if {[info exists prefs($name)]} {
      return $prefs($name)
    }

    return $dflt

  }

  ######################################################################
  # Returns a reference to the preference variable associated with
  # the given name.
  proc ref {{name ""}} {

    if {$name eq ""} {
      return "[ns preferences]::prefs"
    } else {
      return "[ns preferences]::prefs($name)"
    }

  }

  ######################################################################
  # Returns the pathname of the given user preference file.
  proc get_user_preference_file {} {

    variable preferences_dir

    return [file join $preferences_dir preferences.tkedat]

  }

  ######################################################################
  # Returns the loaded preference values for the given session name and
  # language.
  proc get_loaded {{session ""} {language ""}} {

    variable loaded_prefs

    # If the session has not been previously loaded, attempt to do it now
    if {($session ne "") && ![info exists loaded_prefs(session,$session,global)]} {
      [ns sessions]::load_prefs $session
    }

    # Figure out key prefix
    if {($session eq "") || ![info exists loaded_prefs(session,$session,global)]} {
      set prefix "user"
    } else {
      set prefix "session,$session"
      array set lprefs $loaded_prefs(user,global)
    }

    array set lprefs $loaded_prefs($prefix,global)

    if {($language ne "") && [info exists loaded_prefs($prefix,$language)]} {
      array set lprefs $loaded_prefs($prefix,$language)
    }

    return [array get lprefs]

  }

  ######################################################################
  # Called whenever the current text is changed.  Reloads the preferences
  # based on the given set of preferences.
  proc update_prefs {{session ""}} {

    variable loaded_prefs
    variable prefs

    # Calculate the preference prefix
    if {($session ne "") && [info exists loaded_prefs(session,$session,global)]} {
      set prefix "session,$session"
    } else {
      set prefix "user"
    }

    array set temp_prefs $loaded_prefs($prefix,global)

    # Load language-specific preferences, if necessary
    if {([set txt [[ns gui]::current_txt {}]] ne "") && \
        ([set language [[ns syntax]::get_language $txt]] ne "None") && \
        [info exists loaded_prefs($prefix,$language)]} {
      array set temp_prefs $loaded_prefs($prefix,$language)
    }

    # Remove any preferences that have not changed value
    foreach {name value} [array get temp_prefs] {
      if {[info exists prefs($name)] && ($prefs($name) eq $temp_prefs($name))} {
        unset temp_prefs($name)
      }
    }

    # Set the preferences
    array set prefs [array get temp_prefs]

  }

  ######################################################################
  # Loads the base preferences information, sorting out the comments from
  # the preferences information and storing this information in the
  # namespace base_prefs and base_comments arrays.
  proc load_base_prefs {} {

    variable base_preference_file
    variable base_prefs
    variable base_comments

    # Only load the base preferences information if we have previously done so
    if {[array size base_prefs] == 0} {

      # Read the base preferences file (sort out comments from preferences)
      if {![catch { [ns tkedat]::read $base_preference_file } rc]} {
        foreach {key value} $rc {
          if {[lassign [split $key ,] opt] eq "comment"} {
            set base_comments($opt) $value
          } else {
            set base_prefs($opt) $value
          }
        }
      }

    }

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

    variable base_preference_file

    [ns gui]::add_file end $base_preference_file -readonly 1 -sidebar 0

  }

  ######################################################################
  # Adds the user preferences file to the editor, auto-reloading the
  # file when it is saved.
  proc edit_global {{session ""}} {

    # Figure out the title to use in the tab
    if {$session eq ""} {
      set title       "User Global Preferences"
      set key         "user,global"
      set for_session 0
    } else {
      set title       "Session Global Preferences"
      set key         "session,$session,global"
      set for_session 1
    }

    # Create the buffer
    [ns gui]::add_buffer end $title [list [ns preferences]::save_buffer_contents $session {}] -lang tkeData

    # Insert information
    insert_information $key $for_session 0

  }

  ######################################################################
  # Adds the specified language preferences file to the editor, auto-reloading
  # the file when it is saved.
  proc edit_language {{session ""}} {

    # Get the language of the current buffer
    set language [[ns syntax]::get_language [[ns gui]::current_txt {}]]

    # Get the title to use in the tabbar
    if {$session eq ""} {
      set title       "User $language Preferences"
      set key         "user,$language"
      set for_session 0
    } else {
      set title       "Session $language Preferences"
      set key         "session,$session,$language"
      set for_session 1
    }

    # Create the buffer
    [ns gui]::add_buffer end $title [list [ns preferences]::save_buffer_contents $session $language] -lang tkeData

    # Insert information
    insert_information $key $for_session 1

  }

  ######################################################################
  # Inserts the loaded preference information into the current text
  # widget.
  proc insert_information {key for_session for_lang} {

    variable loaded_prefs
    variable base_comments

    # Get the curren text widget
    set txt [[ns gui]::current_txt {}]

    # Make sure the base preference information is loaded
    load_base_prefs

    # Get the preference content
    if {[info exists loaded_prefs($key)]} {
      array set content $loaded_prefs($key)
    } else {
      array set content $loaded_prefs(user,global)
    }

    # If the data is for a language, only allow Editor/* preferences
    if {$for_lang} {
      set tmp [array get content Editor/*]
      array unset content
      array set content $tmp
    } elseif {$for_session} {
      array unset content General/*
      array unset content Help/*
      array unset content Debug/*
      array unset content Tools/Profile*
    }

    set str ""
    foreach name [lsort [array names content]] {
      if {[info exists base_comments($name)]} {
        foreach comment $base_comments($name) {
          append str "#$comment\n"
        }
        append str "\n{$name} {$content($name)}\n\n"
      }
    }

    # Insert the string
    $txt insert -moddata ignore end $str

  }

  ######################################################################
  # Gathers the buffer contents and updates the preference data.
  proc save_buffer_contents {session language file_index} {

    variable loaded_prefs
    variable prefs
    variable preferences_dir

    # Get the current buffer
    set txt [[ns gui]::current_txt {}]

    # Get the buffer contents
    array set data [[ns tkedat]::parse [[ns gui]::scrub_text $txt] 0]

    # Get the buffer contents and store them in the appropriate array
    if {$session eq ""} {

      # Get the filename to write and update the appropriate loaded_prefs array
      if {$language eq ""} {
        set loaded_prefs(user,global) [array get data]
        [ns tkedat]::write [get_user_preference_file] $loaded_prefs(user,global) 0
      } else {
        set loaded_prefs(user,$language) [array get data Editor/*]
        [ns tkedat]::write [file join $preferences_dir preferences.$language.tkedat] $loaded_prefs(user,$language) 0
      }

    } else {

      if {$language eq ""} {
        array unset data General/*
        array unset data Help/*
        array unset data Debug/*
        array unset data Tools/Profile*
        set loaded_prefs(session,$session,global) [array get data]
      } else {
        set loaded_prefs(session,$session,$language) [array get data Editor/*]
      }

      # Save the preference information to the sessions file
      [ns sessions]::save "prefs" $session

    }

    # Update the UI
    update_prefs $session

    # Perform environment variable setting from the General/Variables preference option
    [ns utils]::set_environment $prefs(General/Variables)

    return 0

  }

  ######################################################################
  # Save the preference array to the preferences file.
  proc save_prefs {session language data} {

    variable loaded_prefs
    variable prefs
    variable preferences_dir

    if {$session eq ""} {

      # Get the filename to write and update the appropriate loaded_prefs array
      if {$language eq ""} {
        set loaded_prefs(user,global) $data
        [ns tkedat]::write [get_user_preference_file] $loaded_prefs(user,global) 0
      } else {
        array set content $data
        set loaded_prefs(user,$language) [array get content Editor/*]
        [ns tkedat]::write [file join $preferences_dir preferences.$language.tkedat] $loaded_prefs(user,$language) 0
      }

    } else {

      # Get the filename to write and update the appropriate loaded_prefs array
      if {$language eq ""} {
        array set content $data
        array unset content General/*
        array unset content Help/*
        array unset content Debug/*
        array unset content Tools/Profile*
        set loaded_prefs(session,$session,global) [array get content]
      } else {
        array set content $data
        set loaded_prefs(session,$session,$language) [array get content Editor/*]
      }

      # Save the preference information to the sessions file
      [ns sessions]::save "prefs" $session

    }

    # Update the UI/environment if the session name matches the current one
    if {$session eq [[ns sessions]::current]} {

      # Update the UI
      update_prefs $session

      # Perform environment variable setting from the General/Variables preference option
      [ns utils]::set_environment $prefs(General/Variables)

    }

  }

  ######################################################################
  # Constantly monitors changes to the tke preferences file.
  proc load_file {{language ""}} {

    variable base_preference_file
    variable loaded_prefs
    variable prefs
    variable menus
    variable base_comments
    variable base_prefs
    variable preferences_dir

    # Get the user preferences file
    set user_preference_file [get_user_preference_file]

    # If the preferences file does not exist, add it from the data directory
    if {[file exists $user_preference_file]} {

      # Get the file status information for both the base and user files
      file stat $base_preference_file base_stat
      file stat $user_preference_file user_stat

      # Read the user preferences file
      if {![catch { [ns tkedat]::read $user_preference_file 0 } rc]} {
        array set user_prefs $rc
      }

      # If the base preferences file was changed since the user file has changed, see if the
      # user file needs to be updated and update it if necessary
      if {$base_stat(ctime) > $user_stat(ctime)} {

        # Read both the base the preferences file (sort out comments from preferences)
        load_base_prefs

        # If the preferences are different between the base and user, update the user
        if {[lsort [array names base_prefs]] ne [lsort [array names user_prefs]]} {

          # Copy only the members in the user preferences that are in the base preferences
          # (omit the comments)
          foreach name [array names user_prefs -regexp {^[^,]+$}] {
            if {[info exists base_prefs($name)]} {
              set base_prefs($name) $user_prefs($name)
            }
          }

          # Write the base_prefs array to the user preferences file
          if {![catch { [ns tkedat]::write $user_preference_file [array get base_prefs] 0 } rc]} {
            set loaded_prefs(user,global) [array get base_prefs]
          }

        # Otherwise, assign the user preferences to the
        } else {
          set loaded_prefs(user,global) [array get user_prefs]
        }

      # Otherwise, just use the user preferences file
      } else {
        set loaded_prefs(user,global) [array get user_prefs]
      }

    } else {

      # Copy the base preferences to the user preferences file
      copy_default 0

      # Read the contents of the user file
      if {![catch { [ns tkedat]::read $user_preference_file 0 } rc]} {
        set loaded_prefs(user,global) $rc
      }

    }

    # Read the language preference file
    if {$language ne ""} {
      set languages $language
    } else {
      set languages [list]
      foreach lang_file [glob -nocomplain -directory $preferences_dir -tails preferences.*.tkedat] {
        if {[regexp {preferences\.(.*)\.tkedat} $lang_file -> lang]} {
          lappend languages $lang
        }
      }
    }

    # Save off settings from each language
    foreach lang $languages {
      if {![catch { [ns tkedat]::read [file join $preferences_dir preferences.$lang.tkedat] 0 } rc]} {
        set loaded_prefs(user,$lang) $rc
      }
    }

    # Update the preferences
    update_prefs

    # Perform environment variable setting from the General/Variables preference option
    [ns utils]::set_environment $prefs(General/Variables)

  }

  ######################################################################
  # Copies the default preference settings into the user's tke directory.
  proc copy_default {{load 1}} {

    variable base_preference_file
    variable preferences_dir

    # Copy the default file to the home directory
    file copy -force $base_preference_file $preferences_dir

    # Load the preferences file
    if {$load} {
      load_file
    }

  }

  ######################################################################
  # Loads session information.
  proc load_session {name data} {

    variable base_prefs
    variable loaded_prefs

    # Make sure that the base preferences are loaded
    load_base_prefs

    # Get the session key and data
    lassign $data key sdata

    # Initialize with the base preferences (to make sure that we don't allow session preferences to get stale)
    set loaded_prefs($key) [array get base_prefs]

    # Override base preferences with user preferences
    set loaded_prefs($key) $loaded_prefs(user,global)

    # Set the incoming preference information into the loaded_prefs array
    set loaded_prefs($key) $sdata

    # Update the UI
    if {$name eq [[ns sessions]::current]} {
      update_prefs $name
    }

  }

  ######################################################################
  # Save session information.
  proc save_session {name} {

    variable loaded_prefs

    if {![info exists loaded_prefs(session,$name,global)]} {
      foreach user_type [array names loaded_prefs user,*] {
        lassign [split $user_type ,] user type
        set loaded_prefs(session,$name,$type) $loaded_prefs($user_type)
      }
    }

    return [array get loaded_prefs session,$name,*]

  }

  ######################################################################
  # Returns the list of files in the TKE home directory to copy.
  proc get_share_items {dir} {

    variable preferences_dir

    return [glob -nocomplain -directory $dir -tails preferences*.tkedat]

  }

  ######################################################################
  # Called whenever the sharing directory changes.
  proc share_changed {dir} {

    variable preferences_dir

    set preferences_dir $dir

  }

}

