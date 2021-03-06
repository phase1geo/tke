namespace eval perforce {

  variable disable_edit 0
  variable include_dirs {}

  ######################################################################
  # Allow us to change the disable status of the "edit on open" menu
  # option.
  proc toggle_edit_do {} {

    # We don't need to do anything special here

  }

  ######################################################################
  # Always allow the user to change the state of the "edit on open"
  # menu option.
  proc toggle_edit_state {} {

    return 1

  }

  ######################################################################
  # Allows the user to edit the include directories.
  proc edit_include_dirs_do {} {

    # Get the name of the file containing the included directories
    set id_fname [file join [api::get_home_directory] perforce.dat]

    # If the file does not exist, create it
    if {![file exists $id_fname]} {
      if {![catch { open $id_fname w } rc]} {
        puts $rc "# Host                    Directory"
        puts $rc "# ----------------------  -------------------------------------------------"
        close $rc
      }
    }

    # Add the file to the editor
    api::file::add_file $id_fname -sidebar 0 -savecommand [list perforce::edit_include_dirs_save $id_fname]

  }

  ######################################################################
  # Handles a save action on the specified include directory file.
  proc edit_include_dirs_save {fname file_index} {

    variable include_dirs

    # Open the file for reading
    if {![catch { open $fname r } rc]} {

      # Clear the include directories
      set include_dirs [list]

      # Add directories that actually exist
      foreach line [split [read $rc] \n] {
        if {[set line [string trim $line]] ne ""} {
          if {[string index $line 0] ne "#"} {
            if {([llength $line] == 2) && ([info hostname] eq [lindex $line 0]) && [file exists [lindex $line 1]]} {
              lappend include_dirs [lindex $line 1]
            }
          }
        }
      }

      # Close the file
      close $rc

    }

  }

  ######################################################################
  # Sets the state of the "Edit include directories" command.
  proc edit_include_dirs_state {} {

    return 1

  }

  ######################################################################
  # Reverts the current file.
  proc revert_file_do {} {

    # Get the index of the current file being edited
    if {[set index [api::file::current_index]] != -1} {

      # Get the name of the file
      set fname [api::file::get_info $index fname]

      # Perform a Perforce revert operation
      catch { exec p4 revert $fname } rc

    }

  }

  ######################################################################
  # This option should always be available.
  proc revert_file_state {} {

    return [expr [api::file::current_index] != -1]

  }

  ######################################################################
  # When the application starts, read the include directory file.
  proc on_start_do {} {

    edit_include_dirs_save [file join [api::get_home_directory] perforce.dat] 0

  }

  ######################################################################
  # Returns 1 if the given file is located in one of the included
  # directories.
  proc included {fdir} {

    variable include_dirs

    foreach include_dir $include_dirs {
      if {[string compare -length [string length $include_dir] $include_dir $fdir] == 0} {
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # When a file is opened in a tab, this procedure is invoked which will
  # perform a Perforce edit if the file exists.
  proc on_save_do {file_index} {

    variable disable_edit

    if {!$disable_edit} {

      # Get the filename
      if {[included [set fname [api::file::get_info $file_index fname]]] && [file exists $fname]} {

        # If the file is a symlink, edit the original file
        if {![catch { file readlink $fname } rc]} {
          set orig_pwd [pwd]; cd [file dirname $fname]; set fname [file normalize $rc]; cd $orig_pwd
          if {![included $fname]} {
            return
          }
        }

        # If the file exists and we don't get an error when editing the file
        if {![file writable $fname]} {
          catch { exec p4 edit $fname } rc
        }

      }

    }

  }

  ######################################################################
  # When a file is renamed, handle it from Perforce's point of view.
  proc on_rename_do {old_fname new_fname} {

    if {[included $old_fname]} {

      # If the new filename exists within a Perforce directory, rename it
      if {[included $new_fname]} {
        catch { exec p4 rename $old_fname $new_fname }

      # Otherwise, delete the old file from the depot
      } else {
        catch { exec p4 delete $old_fname }
      }

    }

  }

  ######################################################################
  # When a file/folder is deleted, handle it from Perforce's point of
  # view.
  proc on_delete_do {fname} {

    if {[included $fname]} {

      # Perform the Perforce deletion
      if {[file isdirectory $fname]} {
        if {![catch { exec -ignorestderr p4 delete $fname/...}]} {
          catch { exec touch $fname }
        }
      } else {
        if {![catch { exec p4 delete $fname }]} {
          catch { exec touch $fname }
        }
      }

    }

  }

  ######################################################################
  # Handles a writeplugin event.
  proc writeplugin_do {} {

    variable include_dirs

    return [list [list include_dirs $include_dirs]]

  }

  ######################################################################
  # Handles a readplugin event.
  proc readplugin_do {opt val} {

    variable include_dirs

    switch $opt {
      include_dirs { lappend include_dirs $val }
    }

  }

}

api::register perforce {
  {menu {checkbutton perforce::disable_edit} "Perforce Options/Disable edit on open" perforce::toggle_edit_do perforce::toggle_edit_state}
  {menu command   "Perforce Options/Edit include directories" perforce::edit_include_dirs_do perforce::edit_include_dirs_state}
  {menu separator "Perforce Options"}
  {menu command   "Perforce Options/Revert current file"      perforce::revert_file_do       perforce::revert_file_state}
  {on_start     perforce::on_start_do}
  {on_save      perforce::on_save_do}
  {on_rename    perforce::on_rename_do}
  {on_delete    perforce::on_delete_do}
}
