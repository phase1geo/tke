namespace eval terminal {
  
  variable user_command ""
  
  ######################################################################
  # Adds command launcher registrations.
  proc on_start_do {} {
    
    api::register_launcher "Terminal: Run Command" "terminal::run_command_do"
    
  }
  
  ######################################################################
  # Inserts the given text.
  proc insert_text {txt data {tag ""}} {
    
    $txt configure -state normal
    $txt insert end $data {*}$tag
    $txt configure -state disabled
    $txt see end     
    
  }
  
  ######################################################################
  # Displays the Terminal window and waits for user input.
  proc run_command_do {} {
    
    variable user_command
    
    # Create/Display a terminal buffer
    set txt [api::file::add Terminal -sidebar 0 -buffer 1 -readonly 1]
    
    # Add the prompt> string if the buffer is empty
    if {[lsearch [$txt tag names] prompt] == -1} {
      
      # Clear the text widget
      $txt delete 1.0 end
      
      # Add a tag for prompt lines
      $txt tag configure prompt -foreground purple
    
      # Insert the prompt text
      insert_text $txt "prompt> " prompt
      
    }
    
    # Display the user input entry field
    if {[api::get_user_input "Enter command:" terminal::user_command]} {
      
      # Add the user command to the text widget
      insert_text $txt "$user_command\n"
      
      # Perform an update
      update
      
      # Execute the command
      catch { exec -ignorestderr {*}$user_command } rc
      insert_text $txt "$rc\n"
      insert_text $txt "prompt> " prompt
      
    }
    
  }
  
  ######################################################################
  # Handles the state of the "Run Command..." menu option.
  proc run_command_handle_state {} {
    
    return 1
    
  }

}

api::register terminal {
  {on_start terminal::on_start_do}
  {menu command "Terminal/Run Command..." terminal::run_command_do termina::run_command_handle_state}
}
