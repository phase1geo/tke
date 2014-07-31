namespace eval todo {
  
  variable todo_lists {}
  variable user_input ""
      
  array set images {}

  ######################################################################
  # Create checkbox images.
  proc on_start_do {} {
    
    variable images
    
    # Create images files
    set images(checked)   [image create photo -file [file join [api::get_images_directory] checked.gif]]
    set images(unchecked) [image create photo -file [file join [api::get_images_directory] unchecked.gif]]
    
    # Load the todo information
    load_todos
    
  }
  
  ######################################################################
  # Loads the todo information from the file.
  proc load_todos {} {
    
    variable todo_lists
    
    # Initialize the todo_lists list
    set todo_lists [list]
    
    # Read each list file from the home directory and store the contents into todo_lists
    if {![catch "open [file join [api::get_home_directory] all.list] r" rc]} {
      set todo_lists [read $rc]
      close $rc
    }
    
    # If we are a TKE developer, add the TKE development todo list
    if {[api::tke_development]} {
      if {![catch "open [file join [api::get_tke_directory] data todo.list] r" rc]} {
        lappend todo_lists [read $rc]
        close $rc
      } else {
        lappend todo_lists [list "TKE Development" [list]]
      }
    }
    
  }
  
  ######################################################################
  # Saves the todo lists to the plugin home directory.
  proc save_todo_lists {} {
    
    variable todo_lists
    
    # If we are doing TKE development, write that todo list and remove it from all.list
    if {[api::tke_development]} {
      if {![catch "open [file join [api::get_tke_directory] data todo.list] w" rc]} {
        puts $rc [lindex $todo_lists end]
        close $rc
      }
      set temp_todo_lists [lrange $todo_lists 0 end-1]
    } else {
      set temp_todo_lists $todo_lists
    }
    
    # Write the file contents
    if {![catch "open [file join [api::get_home_directory] all.list] w" rc]} {
      puts $rc $temp_todo_lists
      close $rc
    }
    
  }
  
  ######################################################################
  # Saves the current plugin information when we are reloading.
  proc on_reload_save {index} {
    
    variable images
    variable todo_lists
    
    # Save the image information
    api::plugin::save_variable $index checked   $images(checked)
    api::plugin::save_variable $index unchecked $images(unchecked)
    
    # Save the todo list array
    api::plugin::save_variable $index todo_lists $todo_lists
    
  }
  
  ######################################################################
  # Restores the saved plugin information when we are done reloading.
  proc on_reload_restore {index} {
    
    variable images
    variable todo_lists
    
    set images(checked)   [api::plugin::load_variable $index checked]
    set images(unchecked) [api::plugin::load_variable $index unchecked]
    set todo_lists        [api::plugin::load_variable $index todo_lists]
    
  }
  
  #############################################################
  # Returns the cascading menu for a given list.
  proc add_lists_do {mnu} {
    
    variable todo_lists
    variable images
    
    # Populate the menu with the todo lists
    set list_index 0
    foreach todo_list $todo_lists {
      
      # Create a menu item for each todo list
      set list_menu [menu $mnu.[string map {{ } _} [string tolower [lindex $todo_list 0]]] -tearoff 0]
      $mnu add cascade -label [lindex $todo_list 0] -menu $list_menu
      
      # Add the todo items for the given list
      set todo_index 0
      foreach todo [lindex $todo_list 1] {
        
        # Create the todo menu
        set todo_menu [menu $list_menu.[string map {{ } _} [string tolower [lindex $todo 0]]] -tearoff 0]
        
        # Figure out the appropriate checkbutton image to draw
        if {[lindex $todo 1]} {
          set img $images(checked)
        } else {
          set img $images(unchecked)
        }
        
        # Create the todo menu item in the list
        $list_menu add cascade -compound left -image $img -label [lindex $todo 0] -menu $todo_menu
        
        # Create the todo menu item contents
        if {[lindex $todo 1]} {
          $todo_menu add command -label "Mark as not done" -command "todo::mark_todo_as $list_index $todo_index 0"
        } else {
          $todo_menu add command -label "Mark as done" -command "todo::mark_todo_as $list_index $todo_index 1"
        }
        $todo_menu add separator
        $todo_menu add command -label "Delete" -command "todo::delete_todo $list_index $todo_index"
        
        incr todo_index
        
      }
      
      # Add items to the end of the todo list menu
      if {$todo_index > 0} {
        $list_menu add separator
      }
      $list_menu add command -label "Create new todo" -command "todo::create_new_todo $list_index"
      $list_menu add separator
      $list_menu add command -label "Delete list" -command "todo::delete_list $list_index"
      
      incr list_index
      
    }
    
    # Add a command entry to allow the user to create a new list
    if {$list_index > 0} {
      $mnu add separator
    }
    $mnu add command -label "Create new list" -command "todo::create_new_list"
    
  }
  
  ######################################################################
  # Creates a new list and adds it to the todo list structure.
  proc create_new_list {} {
    
    variable todo_lists
    variable user_input
    
    # Get the new list name from the user
    if {[api::get_user_input "TODO List Name:" todo::user_input]} {
      
      # Append the todo list to the list of todos
      lappend todo_lists [list $user_input [list]]
      
      # Save the new todo list
      save_todo_lists
      
    }
    
  }
  
  ######################################################################
  # Deletes the entire list at the given index.
  proc delete_list {list_index} {
    
    variable todo_lists
    
    # Delete the list file
    file delete -force [file join [api::get_home_directory] [lindex $todo_lists $list_index 0].list]

    # Delete the todo list at the given index
    set todo_lists [lreplace $todo_lists $list_index $list_index]
    
  }
  
  ######################################################################
  # Creates a new todo under the given todo list.
  proc create_new_todo {list_index} {
    
    variable todo_lists
    variable user_input
    
    # Get the new todo from the user
    if {[api::get_user_input "TODO Description:" todo::user_input]} {
    
      # Get the list of todos
      set todos [lindex $todo_lists $list_index 1]
      
      # Append the new todo to the list
      lappend todos [list $user_input 0]
      
      # Replace the todos list into the todo_lists list
      lset todo_lists $list_index 1 $todos
      
      # Save the todo list
      save_todo_lists
      
    }
    
  }
  
  ######################################################################
  # Marks the specified todo as done.
  proc mark_todo_as {list_index todo_index done} {
    
    variable todo_lists
    
    # Set the done bit to the specified value for the given todo item
    lset todo_lists $list_index 1 $todo_index 1 $done
    
    # Save the todo list
    save_todo_lists
    
  }
  
  ######################################################################
  # Deletes the given todo.
  proc delete_todo {list_index todo_index} {
    
    variable todo_lists
    
    # Get the todos
    set todos [lindex $todo_lists $list_index 1]
    
    # Delete the todo at the specified index
    set todos [lreplace $todos $todo_index $todo_index]
    
    # Replace the todos list
    lset todo_lists $list_index 1 $todos
    
    # Save the todo list
    save_todo_lists
    
  }
  
}

plugins::register todo {
  {on_start todo::on_start_do}
  {on_reload todo::on_reload_save todo::on_reload_restore}
  {menu cascade "ToDo Lists" todo::add_lists_do}
}
