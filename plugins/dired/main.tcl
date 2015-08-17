# Plugin namespace
namespace eval dired {
  
  array set data {}
  
  ######################################################################
  # Returns 1 if the current file is the dired file.
  proc is_dired {{file_index ""}} {
    
    variable data
    
    if {$file_index eq ""} {
      set file_index [api::file::current_file_index]
    }
    
    return [expr {[info exists data(file)] && ($data(file) eq [api::file::get_info $file_index fname])}]
    
  }
  
  ######################################################################
  # Opens the currently selected directory.
  proc do_open_directory {} {
    
    variable data
    
    # Create the temporary filename
    set data(file) [file join [api::get_plugin_directory] dired]
    
    # Get the currently selected directories
    foreach index [api::sidebar::get_selected_indices] {
      lappend data(dirs) [api::sidebar::get_info $index fname]
    }
    
    # Write the dired file
    write_directories
      
    # Add the dired file
    api::file::add $data(file) -sidebar 0 -buffer 1 -gutters {{changes D {-symbol "D" -fg red} A {-symbol "A" -fg green} R {-symbol "R" -fg yellow}}} -tags key_bindings
    
  }
  
  ######################################################################
  # Always allow the user to open dired.
  proc handle_state_open_directory {} {
    
    return 1
    
  }
  
  ######################################################################
  # Changes the dired file to include the given directories.
  proc write_directories {} {
    
    variable data
    
    # Open the file for writing
    if {![catch { open $data(file) w } rc]} {
    
      # Get the currently selected directories
      foreach dirname $data(dirs) {
        
        puts $rc "# $dirname\n"
        puts $rc "  .."
        
        # Get the directory contents
        foreach elem [glob -directory $dirname -tails *] {
          puts $rc "  $elem"
        }
        
        puts $rc ""
        
      }
      
      close $rc
      
    }
    
  }
  
  ######################################################################
  # When the directed file is saved, performs a confirmation prior to the
  # save.
  proc on_save {file_index} {
    
    variable data
    
    # If the current file is the dired file and modifications have been made, ask the user for confirmation
    if {[is_dired $file_index] && [api::file::get_info $file_index modified]} {
      
      # Confirm the changes
      if {[tk_messageBox -parent . -message "Apply changes?" -type yesno -default yes]} {
        
        # Apply the changes
        apply_changes [api::file::get_info $index txt]
        
        # Update the directories file
        write_directories
        
      }
      
    }
    
  }
  
  ######################################################################
  # Finds the changes in the given text widget.
  proc apply_changes {txt} {
    
    variable data
    
    # Handle changes
    foreach type {D A R} {
      foreach linenum [$txt gutter get changes D] {
        if {[set elem [string trim [$txt get $linenum.0 $linenum.end]]] ne ""} {
          switch $type {
            D {
              file delete -force $elem
            }
            A {
              if {![catch { open $elem w } rc]} {
                close $rc
              }
            }
            R {
              file rename -force $data(orig,$elem) $elem
            }
          }
        }
      }
    }
    
    # Clear the changes gutter
    $txt gutter clear changes 0 end
    
  }

  ######################################################################
  # Handles text binding.
  proc do_binding {btag} {
    
    bind $btag <Key> [list if {[dired::handle_any {%W} {%K}]} { break }]
    
  }
  
  ######################################################################
  # Handles any keystrokes.
  proc handle_any {w keysym} {
    
    switch $keysym {
      d {
        mark_as $w D
      }
      u {
        mark_clear $w
      }
      a -
      o {
        $w insert "insert lineend" "\n  "
        $w mark set insert "insert+1l lineend"
        mark_as $w A
      }
      j -
      k -
      l -
      h {
        return 0
      }
    }
    
    return 1
    
  }
  
  ######################################################################
  # Mark the current line with the given type.
  proc mark_as {txt type} {
    
    $txt gutter set changes $type [lindex [split [$txt index insert] .] 0]
    
  }
  
  ######################################################################
  # Clears the current mark.
  proc mark_clear {txt} {
    
    variable data
    
    # Get the current line
    set line [lindex [split [$txt index insert] .] 0]
    
    # Get the current line type
    switch [$txt gutter get changes $line] {
      D {
        $txt gutter clear changes $line
      }
      A {
        $txt delete $line.0 "$line.end+1c"
      }
      R {
        $txt gutter clear changes $line
        set elem [string trim [$txt get $line.0 $line.end]]
        $txt delete $line.0 $line.end
        $txt insert $line.0 $data(orig,$elem)
        unset data(orig,$elem)
      }
    }
    
  }

}

# Register all plugin actions
api::register dired {
  {text_binding pretext key_bindings only dired::do_binding}
  {root_popup command "Open dired view" dired::do_open_directory dired::handle_state_open_directory}
  {dir_popup  command "Open dired view" dired::do_open_directory dired::handle_state_open_directory}
  {on_save dired::on_save}
}
