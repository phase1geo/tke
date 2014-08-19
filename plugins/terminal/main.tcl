namespace eval terminal {
  
  variable user_command ""
  
  ######################################################################
  # Displays the Terminal window and waits for user input.
  proc run_command_do {} {
    
    variable user_command
    
    # Create/Display a terminal buffer
    set txt [api::file::add Terminal -sidebar 0 -buffer 1 -readonly 1]
    
    # Display the user input entry field
    if {[api::get_user_input "Enter command:" terminal::user_command]} {
      
      # Add the user command to the text widget
      $txt configure -state normal
      $txt insert end "prompt> $user_command\n"
      $txt configure -state disabled
      
      # Perform an update
      update
      
      # Execute the command
      $txt configure -state normal
      $txt insert end "[exec -ignorestderr {*}$user_command]\n"
      $txt configure -state disabled
      $txt see end     
      
    }
    
  }
  
  ######################################################################
  # Handles the state of the "Run Command..." menu option.
  proc run_command_handle_state {} {
    
    return 1
    
  }

}

api::register terminal {
 {menu command "Terminal/Run Command..." terminal::run_command_do termina::run_command_handle_state}
}
