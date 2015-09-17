 namespace eval notes {
  
  variable user_input ""
  
  array set note_info {
    id 0
  }
  
  ######################################################################
  # Create checkbox images.
  proc on_start_do {} {
    
    variable note_info
    
    # Load the note information
    load_note_info
    
    # Add the command launcher commands
    api::register_launcher "Notes: Create list" notes::create_new_list
    
    # Add create note and delete list commands for each list
    foreach key [array get note_info list,*] {
      set list_name [lindex [split $key ,] 1]
      add_launchers $list_name
    }
    
  }
  
  ######################################################################
  # Adds list launchers to command launcher.
  proc add_launchers {list_name} {
    
    api::register_launcher "Notes: Create note in $list_name" [list notes::create_new_note $list_name]
    api::register_launcher "Notes: Delete list $list_name"    [list notes::delete_list $list_name]
    
  }
  
  ######################################################################
  # Removes list launchers to command launcher.
  proc remove_launchers {list_name} {
    
    api::unregister_launcher "Notes: Create note in $list_name"
    api::unregister_launcher "Notes: Delete list $list_name"
    
  }
  
  ######################################################################
  # Loads the note information from the file.
  proc load_note_info {} {
    
    variable note_info
    
    # Read each list file from the home directory and store the contents into note_info
    if {![catch { open [file join [api::get_home_directory] all.list] r } rc]} {
      array set note_info [read $rc]
      close $rc
    }
    
  }
  
  ######################################################################
  # Saves the note lists to the plugin home directory.
  proc save_note_info {} {
    
    variable note_info
    
    # Write the file contents
    if {![catch { open [file join [api::get_home_directory] all.list] w } rc]} {
      puts $rc [array get note_info]
      close $rc
    }
    
  }
  
  ######################################################################
  # Saves the current plugin information when we are reloading.
  proc on_reload_save {index} {
    
    variable note_info
    
    # Save the note list array
    api::plugin::save_variable $index note_info [array get note_info]
    
  }
  
  ######################################################################
  # Restores the saved plugin information when we are done reloading.
  proc on_reload_restore {index} {
    
    variable note_info
    
    array unset note_info
    
    array set note_info [api::plugin::load_variable $index note_info]
    
  }
  
  ######################################################################
  # Returns the title to use for the given note file.
  proc get_title {note_path} {
    
    # Get the first line of the note
    if {[catch { open $note_path r } rc]} {
      return -code error $rc
    }
      
    # Read the file content
    set contents [read $rc]
    close $rc
      
    # Get the first line of the file
    foreach line [split $contents \n] {
      if {[set line [string trim $line]] ne ""} {
        return [string range $line 0 50]
      }
    }
      
  }
  
  ######################################################################
  # Creates a note menu and returns it to the calling procedure.
  proc create_note_menu {list_menu note_path} {
    
    variable note_info
    
    # Create the menu
    set note_menu [menu $list_menu.[file rootname [file tail $note_path]] -tearoff 0]
    
    # Create the move_to menu
    set move_to_mnu [menu $note_menu.move -tearoff 0]
    
    # Populate the note menu
    $note_menu add command -label "View/Edit" -command [list notes::show_note $note_path]
    $note_menu add cascade -label "Move to"   -menu $move_to_mnu -state disabled
    $note_menu add separator
    $note_menu add command -label "Delete"    -command [list notes::delete_note $note_path]
    
    # Create the move to menu if necessary
    if {[llength [array names note_info list,*]] > 1} {
      foreach list_key [lsort [array names note_info list,*]] {
        set list_name [lindex [split $list_key ,] 1]
        if {[lindex [file split $note_path] 0] ne $list_name} {
          set list_name [lindex [split $list_key ,] 1]
          $move_to_mnu add command -label $list_name -command [list notes::move_to_list $list_name $note_path]
        }
      }
      $note_menu entryconfigure "Move to" -state normal
    }
      
    return $note_menu
    
  }
  
  ######################################################################
  # Moves the given note path to the given list.
  proc move_to_list {list_name note_path} {
    
    variable note_info
    
    # First, let's actually copy the note file
    file copy [file join [api::get_home_directory] $note_path] [file join [api::get_home_directory] $list_name]
    
    # Then let's delete the original
    file delete -force [file join [api::get_home_directory] $note_path]
    
    # Now let's remove the note from the original list
    set title $note_info(note,$note_path)
    unset note_info(note,$note_path)
    
    # Add the note to the new list
    set note_info(note,[file join $list_name [file tail note_path]]) $title
    
    # Save the note info
    save_note_info
    
    # Let the user know that the note has been deleted
    api::show_info "List has been moved to $list_name"
      
  }
  
  ######################################################################
  # Adds a new notes list.
  proc add_lists_do {mnu} {
    
    variable note_info
    
    # Get the lists
    foreach list_key [array names note_info list,*] {
        
      # Get the list name
      set list_name [lindex [split $list_key ,] 1]
      
      # Create the list menu item
      set list_menu [menu $mnu.[string map {{ } _} [string tolower $list_name]] -tearoff 0]
      $mnu add cascade -label $list_name -menu $list_menu
        
      # Now grab all of the notes within the list directory and add them to the list
      foreach note_key [array names note_info note,[file join $list_name *]] {
        set note_path [lindex [split $note_key ,] 1]
        $list_menu add cascade -label $note_info($note_key) -menu [create_note_menu $list_menu $note_path]
      }
        
      # Add the remaining items to the list menu
      if {[$list_menu index end] ne "none"} {
        $list_menu add separator
      }
      $list_menu add command -label "Create new note" -command [list notes::create_new_note $list_name]
      $list_menu add separator
      $list_menu add command -label "Delete list" -command [list notes::delete_list $list_name]
        
    }
    
    # Add items to the menu
    if {[$mnu index end] ne "none"} {
      $mnu add separator 
    }
    $mnu add command -label "Create new list" -command "notes::create_new_list"
    $mnu add separator
    $mnu add command -label "Rebuild notes" -command "notes::rebuild"
      
  }
  
  ######################################################################
  # Creates a new note list.
  proc create_new_list {} {
      
    variable user_input
    variable note_info
      
    # Get the new list name from the user
    if {[api::get_user_input "Notes List Name:" notes::user_input]} {
       
      # Get the list path
      set list_path [file join [api::get_home_directory] $user_input]
      
      # Create a directory with the given list name
      file mkdir $list_path
      
      # Add the list to the note_info array
      set note_info(list,$user_input) 1
      
      # Save the note info
      save_note_info
      
      # Add command launchers
      add_launchers $user_input
      
      # Let the user know that the note has been deleted
      api::show_info "List $user_input has been created"
      
    }
    
  }
 
  ######################################################################
  # Deletes the entire list at the given index.
  proc delete_list {list_name} {
    
    variable note_info
    
    # Make sure that the user wants to delete the list
    if {[tk_messageBox -parent . -message "Delete note list?" -type yesno -default no] eq "yes"} {
    
      # Deletes the given list directory
      if {[file exists [file join [api::get_home_directory] $list_name]]} {
      
        # Delete the list directory
        file delete -force [file join [api::get_home_directory] $list_name]
      
        # Get the notes within the list directory
        array unset note_info note,[file join $list_name *]
        array unset note_info list,$list_name
        save_note_info
        
        # Unregister the commands
        remove_launchers $list_name
      
        # Let the user know that the note has been deleted
        api::show_info "List $list_name has been deleted"
      
      }
      
    }
    
  }
  
  ######################################################################
  # Creates a new note under the given note list.
  proc create_new_note {list_path} {
    
    variable note_info
    
    # Create the filename of the note
    set note_name [file join [api::get_home_directory] $list_path n[incr note_info(id)].note]
    
    # Save the note_info
    save_note_info
    
    # Add a new file to the editor
    api::file::add_file $note_name -sidebar 0 -savecommand [list notes::save_note [file join $list_path [file tail $note_name]]]
    
  }
  
  ######################################################################
  # Saves the note to the note_info array.
  proc save_note {note_name} {
    
    variable note_info
    
    # Get the title of the note
    set title [get_title [file join [api::get_home_directory] $note_name]]
    
    # If the first line has changed, update the note name ane save it
    if {![info exists note_info(note,$note_name)] || ($note_info(note,$note_name) ne $title)} {
      set note_info(note,$note_name) $title
      save_note_info
    }
      
  }
  
  ######################################################################
  # Displays the given note in the editor.
  proc show_note {note_path} {
    
    api::file::add_file [file join [api::get_home_directory] $note_path] -sidebar 0
    
  }
  
  ######################################################################
  # Deletes the current note.
  proc delete_note {note_path} {
    
    variable note_info
    
    # Make sure that the user wants to delete the note
    if {[tk_messageBox -parent . -message "Delete note?" -type yesno -default no] eq "yes"} {
    
      # Delete the note file
      file delete -force [file join [api::get_home_directory] $note_path]
    
      # Delete the note from the note_info list
      array unset note_info note,$note_path
    
      # Save the note info
      save_note_info
      
      # Let the user know that the note has been deleted
      api::show_info "Note has been deleted"
      
    }
    
  }
  
  ######################################################################
  # Rebuilds the all.list based on the contents of the notes directory.
  proc rebuild {} {
    
    variable note_info
    
    # Delete the current contents of note_info
    array unset note_info
    
    # Remove command launchers
    api::unregister_launcher "Notes: Create note in *"
    api::unregister_launcher "Notes: Delete list *"
    
    # Initialize the note_info
    array set note_info {
      id 0
    }
    
    # Rebuild the note_info list
    foreach list_path [glob -nocomplain -directory [api::get_home_directory] *] {
      if {[file isdirectory $list_path]} {
        set list_name [file tail $list_path]
        set note_info(list,$list_name) 1
        foreach note_path [glob -nocomplain -directory $list_path *] {
          set note_info(note,[file join $list_name [file tail $note_path]]) [get_title $note_path]
          if {[regexp {n(\d+)\.note} $note_path -> id] && ($note_info(id) < $id)} {
            set note_info(id) $id
          }
        }
      } 
    }
    
    # Finally, save the note_info
    save_note_info
    
    # Let the user know that the action completed
    api::show_info "Notes have been rebuilt"
    
  }
  
}

api::register notes {
  {on_start notes::on_start_do}
  {on_reload notes::on_reload_save notes::on_reload_restore}
  {menu cascade "Notes" notes::add_lists_do}
}
