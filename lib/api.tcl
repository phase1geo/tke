######################################################################
# Name:    api.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    07/09/2013
# Brief:   Provides user API to tke functionality.
###################################################################### 

namespace eval api {
  
  ######################################################################
  # Displays a widget that allows the user to provide input.  This
  # procedure will block until the user has either provided a response
  # or has cancelled the input by hitting the escape key.
  # 
  # Parameters:
  #   msg  - Message to display next to input field (prompt)
  #   pvar - Reference to variable to store user input to
  #
  # Returns:
  #   Returns 1 if the user provided input; otherwise, returns 0 to
  #   indicate that the user cancelled the input operation.
  proc get_user_input {msg pvar} {
    
    return [gui::user_response_get]
    
  }
  
  ######################################################################
  # Returns the file information at the given file index.
  #
  # Parameters:
  #   file_index - Unique file identifier that is passed to some plugins.
  #   attr       - File attribute to retrieve.  The following values are
  #                valid for this option:
  #                  fname - Normalized file name
  #                  mtime - Last mofication timestamp (in seconds)
  #                  pane  - Specifies which pane the file tab exists within
  #                  tab   - Specifies the index of the tab in its pane
  proc get_file_info {file_index attr} {
    
    return [gui::get_file_info $file_index $attr]
    
  }
  
}
