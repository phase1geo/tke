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
  # Returns the directory of the file at the current insert line.
  proc get_directory {txt} {

    foreach line [lreverse [$txt get 1.0 "insert linestart"]] {
      if {[regexp {^#\s(.*)$} $line -> elem]} {
        set elem [string trim $elem]
        if {[file isdirectory $elem]} {
          return $elem
        }
      }
    }

    return ""

  }

  ######################################################################
  # Opens the currently selected directory.
  proc do_open_directory {} {

    variable data

    # Create the temporary filename
    set data(file) [file join [api::get_plugin_directory] dired]

    # Initialize variables
    set data(mode) ""
    set data(dirs) [list]

    # Get the currently selected directories
    foreach index [api::sidebar::get_selected_indices] {
      lappend data(dirs) [api::sidebar::get_info $index fname]
    }

    # Write the dired file
    write_directories

    # Add the dired file
    api::file::add $data(file) -sidebar 0 -gutters {{changes D {-symbol "D" -fg red} A {-symbol "A" -fg green} R {-symbol "R" -fg yellow}}} -tags {pre_key_bindings post_key_bindings}

  }

  ######################################################################
  # Opens the file or directory on the current line.
  proc open_file_dir {txt} {

    variable data

    # Get the file/directory on the current line
    set elem [file join [get_directory] [string trim [$txt get "insert linestart" "insert lineend"]]]

    # If the entry is a file, add it to the editor
    if {[file isfile $elem]} {

      api::file::add $elem

    # If the entry is a directory, open it in a new dired file
    } elseif {[file isdirectory $elem]} {

      # If the file underwent changes, ask to save and then proceed
      on_save [api::file::current_file_index]

      # Save the directory (we need to figure out the native name)
      set data(dirs) $elem

      # Write the dired file
      write_directories

    }

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
  # Handles pre text binding.
  proc do_pretext_binding {btag} {

    bind $btag <Key> [list if {[dired::handle_any_pretext {%W} {%K}]} { break }]

  }

  ######################################################################
  # Handles post text binding.
  proc do_posttext_binding {btag} {

    bind $btag <Key> [list dired::handle_any_posttext {%W} {%K}]

  }

  ######################################################################
  # Handles any keystrokes.
  proc handle_any_pretext {w keysym} {

    variable data

    # If the escape key is hit, clear the mode
    if {$keysym eq "Escape"} {
      set data(mode) ""
      return 0
    }

    # Get the current Vim mode
    set vim_mode [api::file::get_info [api::file::current_file_index] vimmode]

    # If we are editing text in Vim mode, set the current line to rename
    if {$data(mode) ne ""} {
      mark_as $w R
      return 0
    }

    puts "In keysym: $keysym"

    switch $keysym {
      Return -
      Space {
        open_file_dir $w
        return 1
      }
      d {
        mark_as $w D
      }
      u {
        mark_clear $w
      }
      o {
        set data(mode) "add"
        if {!$vim_mode} {
          $w insert "insert lineend" "\n  "
          $w mark set insert "insert+1l lineend"
          mark_as $w A
          return 1
        } else {
          return 0
        }
      }
      O {
        set data(mode) "add"
        if {!$vim_mode} {
          $w insert "insert linestart" "\n  "
          $w mark set insert "insert lineend"
          mark_as $w A
          return 1
        } else {
          return 0
        }
      }
      i -
      a {
        set data(mode) "rename"
        return [expr $vim_mode == 0]
      }
      h {
        if {$vim_mode} {
          return 0
        } else {
          tk::TextSetCursor $w insert-1displayindices
          return 1
        }
      }
      j {
        if {$vim_mode} {
          return 0
        } else {
          tk::TextSetCursor $w [tk::TextUpDownLine $w 1]
          return 1
        }
      }
      k {
        if {$vim_mode} {
          return 0
        } else {
          tk::TextSetCursor $w [tk::TextUpDownLine $w -1]
          return 1
        }
      }
      l {
        if {$vim_mode} {
          return 0
        } else {
          tk::TextSetCursor $w insert+1displayindices
          return 1
        }
      }
    }

    return 1

  }

  ######################################################################
  # Handles any necessary post-text key entry.
  proc handle_any_posttext {w keysym} {

    variable data

    # Get the current Vim mode
    set vim_mode [api::file::get_info [api::file::current_file_index] vimmode]

    switch $keysym {
      o -
      O {
        if {$vim_mode} {
          mark_as $W R
        }
      }
    }

    return 0

  }

  ######################################################################
  # Mark the current line with the given type.
  proc mark_as {txt type {line ""}} {

    # If the line was not specified use the insertion line
    if {$line eq ""} {
      set line [lindex [split [$txt index insert] .] 0]
    }

    set current_type [$txt gutter get changes $line]

    if {$current_type eq ""} {
      $txt gutter set changes $type $line
    } elseif {($current_type eq "D") && ($type eq "R")} {
      $txt gutter set changes $type $line
    }

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

  ######################################################################
  # Handles a file close event.
  proc on_close {file_index} {

    variable data

    # Do we need to save?

    # Delete the dired file
    if {[info exists data(file)] && [file exists $data(file)]} {
      file delete -force $data(file)
    }

  }

}

# Register all plugin actions
api::register dired {
  {text_binding pretext  pre_key_bindings  only dired::do_pretext_binding}
  {text_binding posttext post_key_bindings only dired::do_posttext_binding}
  {root_popup command "Open dired view" dired::do_open_directory dired::handle_state_open_directory}
  {dir_popup  command "Open dired view" dired::do_open_directory dired::handle_state_open_directory}
  {on_save dired::on_save}
  {on_close dired::on_close}
}
