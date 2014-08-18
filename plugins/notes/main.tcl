 namespace eval notes {
  
  variable user_input ""
  
  array set note_info {
    id 0
  }
  
  ######################################################################
  # Create checkbox images.
  proc on_start_do {} {
    
    # Load the note information
    load_notes
    
  }
  
  ######################################################################
  # Loads the note information from the file.
  proc load_notes {} {
    
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
  # Creates a note menu and returns it to the calling procedure.
  proc create_note_menu {list_menu note_path} {
    
    # Create the menu
    set note_menu [menu $list_menu.[file rootname [file tail $note_path]] -tearoff 0]
    
    # Populate the note menu
    $note_menu add command -label "View/Edit" -command [list notes::show_note $note_path]
    $note_menu add separator
    $note_menu add command -label "Delete"    -command [list notes::delete_note $note_path]
    
    return $note_menu
    
  }
  
  ######################################################################
  # Adds a new notes list.
  proc add_lists_do {mnu} {
    
    variable note_info
    
    # Get the lists
    foreach list_path [glob -nocomplain -directory [api::get_home_directory] *] {
      
      # If this is a directory, it is a list
      if {[file isdirectory $list_path]} {
        
        # Create the list menu item
        set list_menu [menu $mnu.[string map {{ } _} [string tolower [file tail $list_path]]] -tearoff 0]
        $mnu add cascade -label [file tail $list_path] -menu $list_menu
        
        # Now grab all of the notes within the list directory and add them to the list
        foreach note_path [glob -nocomplain -directory $list_path *.note] {
          set short_path [file join [file tail $list_path] [file tail $note_path]]
          $list_menu add cascade -label $note_info(note,$short_path) -menu [create_note_menu $list_menu $short_path]
        }
        
        # Add the remaining items to the list menu
        if {[$list_menu index end] ne "none"} {
          $list_menu add separator
        }
        $list_menu add command -label "Create new note" -command [list notes::create_new_note [file tail $list_path]]
        $list_menu add separator
        $list_menu add command -label "Delete list" -command [list notes::delete_list [file tail $list_path]]
        
      }
      
    }
    
    # Add items to the menu
    if {[$mnu index end] ne "none"} {
      $mnu add separator 
    }
    $mnu add command -label "Create new list" -command "notes::create_new_list"
      
  }
  
  ######################################################################
  # Creates a new note list.
  proc create_new_list {} {
      
    variable user_input
      
    # Get the new list name from the user
    if {[api::get_user_input "Notes List Name:" notes::user_input]} {
       
      # Get the list path
      set list_path [file join [api::get_home_directory] $user_input]
      
      # Create a directory with the given list name
      file mkdir $list_path
      
    }
    
  }
 
  ######################################################################
  # Deletes the entire list at the given index.
  proc delete_list {list_path} {
    
    variable note_info
    
    # Deletes the given list directory
    if {[file exists [file join [api::get_home_directory] $list_path]]} {
      
      # Get the notes within the list directory
      array unset note_info note,[file join $list_path *]
      
      # Delete the list directory
      file delete -force [file join [api::get_home_directory] $list_path]
      
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
    api::file::add $note_name -sidebar 0 -savecommand [list notes::save_note [file join $list_path [file tail $note_name]]]
    
  }
  
  ######################################################################
  # Saves the note to the note_info array.
  proc save_note {note_name} {
    
    variable note_info
    
    # Get the first line of the note
    if {![catch { open [file join [api::get_home_directory] $note_name] r } rc]} {
      
      # Read the file content
      set contents [read $rc]
      close $rc
      
      # Get the first line of the file
      set first_line ""
      foreach line [split $contents \n] {
        if {[string trim $line] ne ""} {
          set first_line [expr {([string length $line] > 50) ? [string range $line 0 50] : $line}]
          break
        }
      }
      
      # If the first line has changed, update the note name ane save it
      if {![info exists note_info(note,$note_name)] || ($note_info(note,$note_name) ne $first_line)} {
        set note_info(note,$note_name) $first_line
        save_note_info
      }
      
    }
    
  }
  
  ######################################################################
  # Displays the given note in the editor.
  proc show_note {note_path} {
    
    api::file::add [file join [api::get_home_directory] $note_path] -sidebar 0
    
  }
  
  ######################################################################
  # Deletes the current note.
  proc delete_note {note_path} {
    
    variable note_info
    
    # Delete the note file
    file delete -force [file join [api::get_home_directory] $note_path]
    
    # Delete the note from the note_info list
    array unset note_info note,$note_path
    
    # Save the note info
    save_note_info
    
  }
  
}

api::register notes {
  {on_start notes::on_start_do}
  {on_reload notes::on_reload_save notes::on_reload_restore}
  {menu cascade "Notes" notes::add_lists_do}
}
