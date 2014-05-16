######################################################################
# Name:    api.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    07/09/2013
# Brief:   Provides user API to tke functionality.
###################################################################### 

namespace eval api {
  
  ######################################################################
  # Returns true if we are doing tke_development.
  proc tke_development {} {
    
    return [::tke_development]
    
  }
  
  if {[tke_development]} {
    
    ######################################################################
    # Returns the pathname to the TKE directory.
    proc get_tke_directory {} {
      
      return $::tke_dir
      
    }
    
  }
  
  ######################################################################
  # Returns the pathname to the tke plugin images directory.
  #
  # Parameters:
  #   none
  proc get_images_directory {} {
    
    return [file join $::tke_dir plugins images]
    
  }
  
  ######################################################################
  # Returns the pathname to the user's home tke directory.
  #
  # Parameters:
  #   none
  proc get_home_directory {} {
    
    # Get the name of the plugin
    if {[regexp {plugins::(.*)$} [uplevel {namespace current}] -> name]} {
      
      # Figure out the home directory
      set home [file join $::tke_home plugins $name]
      
      # If the home directory does not exist, create it
      file mkdir $home
      
      return $home
      
    } else {
      
      return -code error [msgcat::mc "get_home_directory can only be called within plugin code"]
      
    }
    
  }
  
  ######################################################################
  # Returns a fully NFS normalized filename based on the given host.
  #
  # Parameters:
  #   host  - Name of the host that contains the filename
  #   fname - Name of the file to normalize
  proc normalize_filename {host fname} {
    
    return [gui::normalize $host $fname]
    
  }
  
  ######################################################################
  # Displays the given message string in the information bar.  The
  # message must not contain any newline characters.
  #
  # Parameters:
  #   msg   - Message to display in the information bar
  #   delay - Specifies the amount of time to wait before displaying the message
  proc show_info {msg {delay 100}} {
  
    # Displays the given message
    after $delay [list gui::set_info_message $msg]
  
  }
  
  ######################################################################
  # Displays a widget that allows the user to provide input.  This
  # procedure will block until the user has either provided a response
  # or has cancelled the input by hitting the escape key.
  # 
  # Parameters:
  #   msg        - Message to display next to input field (prompt)
  #   pvar       - Reference to variable to store user input to
  #   allow_vars - If set to 1, variables embedded in string will have
  #                substitutions performed; otherwise, the raw string
  #                will be returned.
  #
  # Returns:
  #   Returns 1 if the user provided input; otherwise, returns 0 to
  #   indicate that the user cancelled the input operation.
  proc get_user_input {msg pvar {allow_vars 1}} {
    
    upvar $pvar var
    
    return [gui::user_response_get $msg var $allow_vars]
    
  }
  
  namespace eval file {
  
    ######################################################################
    # Returns the file index of the file being currently edited.  If no
    # such file exists, returns a value of -1.
    proc current_file_index {} {
      
      return [gui::current_file]
      
    }
    
    ######################################################################
    # Returns the file information at the given file index.
    #
    # Parameters:
    #   file_index - Unique file identifier that is passed to some plugins.
    #   attr       - File attribute to retrieve.  The following values are
    #                valid for this option:
    #                  fname    - Normalized file name
    #                  mtime    - Last mofication timestamp (in seconds)
    #                  lock     - Specifies the current lock status of the file
    #                  readonly - Specifies if the file is readonly
    #                  modified - Specifies if the file has been modified since
    #                             the last save.
    proc get_info {file_index attr} {
      
      return [gui::get_file_info $file_index $attr]
      
    }
    
    ######################################################################
    # Adds a file to the browser.  If the first argument does not start with
    # a '-' character, the argument is considered to be the name of a file
    # to add.  If no filename is specified, an empty/unnamed file will be added.
    # All other options are considered to be parameters.
    #
    # Parameters:
    #   -savecommand <command>  Specifies the name of a command to execute after
    #                           the file is saved.
    #
    #   -lock (0|1)             If set to 0, the file will begin in the unlocked
    #                           state (i.e., the user can edit the file immediately).
    #                           If set to 1, the file will begin in the locked state
    #                           (i.e., the user must unlock the file to edit it)
    #
    #   -readonly (0|1)         If set to 1, the file will be considered readonly
    #                           (i.e., the file will be locked indefinitely); otherwise,
    #                           the file will be able to be edited.
    #
    #   -sidebar (0|1)          If set to 1 (default), the file's directory contents
    #                           will be included in the sidebar; otherwise, the file's
    #                           directory components will not be added to the sidebar.
    #
    #   -saveas (0|1)           If set to 0 (default), the file will be saved to the
    #                           current file; otherwise, the file will always force a
    #                           save as dialog to be displayed when saving.
    proc add {args} {
     
      if {([llength $args] == 0) || ([string index [lindex $args 0] 0] eq "-")} {
        if {[expr [llength $args] % 2] == 1} {
          return -code error [msgcat::mc "Argument list to api::add_file was not an even key/value pair"]
        }
        gui::add_new_file end {*}$args
      } else {
        if {[expr [llength $args] % 2] == 0} {
          return -code error [msgcat::mc "Argument list to api::add_file was not in the form 'filename [<option> <value>]*'"]
        }
        gui::add_file end {*}$args
      }
      
    }
    
  }
  
  namespace eval plugin {
  
    ######################################################################
    # Saves the value of the given variable name to non-corruptible memory
    # so that it can be later retrieved when the plugin is reloaded.
    #
    # Parameters:
    #   index - Unique value that is passed to the on_reload save command.
    #   name  - Name of the variable to store
    #   value - Variable value to store
    proc save_variable {index name value} {
      
      plugins::save_data $index $name $value
      
    }
     
    ######################################################################
    # Retrieves the value of the named variable from non-corruptible memory
    # (from a previous save_variable call.
    #
    # Parameters:
    #   index - Unique value that is passed to the on_reload retrieve command.
    #   name  - Name of the variable to get the value of.  If the named variable
    #           could not be found), an empty string is returned.
    proc load_variable {index name} {
      
      return [plugins::restore_data $index $name]
      
    }
    
  }
  
}
