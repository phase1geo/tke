######################################################################
# Name:    api.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    07/09/2013
# Brief:   Provides user API to tke functionality.
######################################################################

namespace eval api {



  source [file join $::tke_dir lib ns.tcl]

  ######################################################################
  ## \return Returns true if we are doing tke_development.
  proc tke_development {interp pname} {

    return [::tke_development]

  }

  ######################################################################
  ## \return Returns the pathname to the TKE directory.
  proc get_plugin_directory {interp pname} {

    set plugin_dir [file join $::tke_dir plugins $pname]

    if {[$interp issafe]} {
      return [::safe::interpFindInAccessPath $interp $plugin_dir]
    } else {
      return $plugin_dir
    }

  }

  ######################################################################
  ## \return Returns the pathname to the tke plugin images directory.
  proc get_images_directory {interp pname} {

    set img_dir [file join $::tke_dir plugins images]

    if {[$interp issafe]} {
      return [::safe::interpFindInAccessPath $interp $img_dir]
    } else {
      return $img_dir
    }

  }

  ######################################################################
  ## \return Returns the pathname to the user's home tke directory.
  proc get_home_directory {interp pname} {

    # Figure out the home directory
    set home [file join $::tke_home plugins $pname]

    # If the home directory does not exist, create it
    file mkdir $home

    if {[$interp issafe]} {
      return [::safe::interpFindInAccessPath $interp $home]
    } else {
      return $home
    }

  }

  ######################################################################
  ## \return Returns a fully NFS normalized filename based on the given host.
  #
  #  \param host   Name of the host that contains the filename
  #  \param fname  Name of the file to normalize
  proc normalize_filename {interp pname host fname} {

    return [gui::normalize $host $fname]

  }

  ######################################################################
  ## Registers the given description and command in the command launcher.
  proc register_launcher {interp pname description command} {

    launcher::register "Plugin: $description" "$interp eval $command"

  }

  ######################################################################
  ## Unregisters a previously registered command launcher with the same
  #  description.
  proc unregister_launcher {interp pname description} {

    launcher::unregister "Plugin: $description"

  }

  ######################################################################
  ## Invokes the given menu path.
  #
  # \param menu_path  Hierarchical menu path (separated by '/') to invoke.
  proc invoke_menu {interp pname menu_path} {

    # Get the menu path
    set menu_path [split $menu_path /]

    # Get the parent menu
    set parent [menus::get_menu [lrange $menu_path 0 end-1]]

    # Invoke the menu entry in the parent
    menus::invoke $parent [lindex $menu_path end]

  }

  ######################################################################
  ## Displays the given message string in the information bar.  The
  #  message must not contain any newline characters.
  #
  #  \param msg    Message to display in the information bar
  #  \param delay  Specifies the amount of time to wait before clearing the message
  proc show_info {interp pname msg {clear_delay 3000}} {

    # Displays the given message
    gui::set_info_message $msg $clear_delay

  }

  ######################################################################
  ## Displays a widget that allows the user to provide input.  This
  #  procedure will block until the user has either provided a response
  #  or has cancelled the input by hitting the escape key.
  #
  #  \param msg         Message to display next to input field (prompt)
  #  \param pvar        Reference to variable to store user input to
  #  \param allow_vars  If set to 1, variables embedded in string will have
  #                     substitutions performed; otherwise, the raw string
  #                     will be returned.
  #
  #  \return Returns a list containing two elements.  The first element is set to a
  #          1 if the user provided input; otherwise, returns 0 to indicate that the
  #          user cancelled the input operation.  The second item is the user provided
  #          value (if the first value is set to 1).
  proc get_user_input {interp pname msg pvar {allow_vars 1}} {

    set var ""

    if {[gui::user_response_get $msg var $allow_vars]} {
      $interp eval set $pvar [list $var]
      return 1
    }

    return 0

  }

  namespace eval file {

    ######################################################################
    ## \return Returns the file index of the file being currently edited.  If no
    #          such file exists, returns a value of -1.
    proc current_file_index {interp pname} {

      return [gui::current_file]

    }

    ######################################################################
    ## \return Returns the file information at the given file index.
    #
    #  \param file_index  Unique file identifier that is passed to some plugins.
    #  \param attr        File attribute to retrieve.  The following values are
    #                     valid for this option:
    #                     - \b fname    : Normalized file name
    #                     - \b mtime    : Last mofication timestamp (in seconds)
    #                     - \b lock     : Specifies the current lock status of the file
    #                     - \b readonly : Specifies if the file is readonly
    #                     - \b modified : Specifies if the file has been modified since the last save.
    #                     - \b sb_index : Specifies the index of the file in the sidebar.
    #                     - \b txt      : Specifies the text widget associated with the file
    #                     - \b current  : Returns 1 if the file is the current file being edited
    proc get_info {interp pname file_index attr} {

      return [gui::get_file_info $file_index $attr]

    }

    ######################################################################
    ## Adds a file to the browser.  If the first argument does not start with
    #  a '-' character, the argument is considered to be the name of a file
    #  to add.  If no filename is specified, an empty/unnamed file will be added.
    #  All other options are considered to be parameters.
    #
    #   -savecommand \e command
    #     * Specifies the name of a command to execute after
    #       the file is saved.
    #
    #   -lock (0|1)
    #     * If set to 0, the file will begin in the unlocked
    #       state (i.e., the user can edit the file immediately).
    #     * If set to 1, the file will begin in the locked state
    #       (i.e., the user must unlock the file to edit it)
    #
    #   -readonly (0|1)
    #     * If set to 1, the file will be considered readonly
    #       (i.e., the file will be locked indefinitely); otherwise,
    #       the file will be able to be edited.
    #
    #   -sidebar (0|1)
    #     * If set to 1 (default), the file's directory contents
    #       will be included in the sidebar; otherwise, the file's
    #       directory components will not be added to the sidebar.
    #
    #   -saveas (0|1)
    #     * If set to 0 (default), the file will be saved to the
    #       current file; otherwise, the file will always force a
    #       save as dialog to be displayed when saving.
    #
    #   -buffer (0|1)
    #     * If set to 0 (default, the file will be added as a normal file;
    #       however, if set to 1, the file will be treated as a temporary file
    #       that will be automatically deleted when the tab is closed.
    #
    #   -gutters \e list
    #     * Creates a gutter in the editor.  The contents of list are as follows:
    #       \code {name {{symbol_name {symbol_tag_options+}}+}}+ \endcode
    #       For a list of valid symbol_tag_options, see the options available for
    #       tags in a text widget.
    proc add {interp pname args} {

      set fname ""
      array set opts [list]

      # If no filename is given, add a new file to the editor
      if {([llength $args] > 0) && ([string index [lindex $args 0] 0] ne "-")} {

        # Peel the filename from the rest of the arguments
        set args [lassign $args fname]

        # Check to make sure that the file is safe to add to the editor, and
        # if it is, create the normalized pathname of the filename.
        if {[set fname [interpreter::check_file $pname $fname]] eq ""} {
          return -code error "permission error"
        }

      }

      # If we have an odd number of arguments, we have an error condition
      if {[expr [llength $args] % 2] == 1} {
        return -code error [msgcat::mc "Argument list to api::add_file was not an even key/value pair"]
      }

      # Get the options
      array set opts $args

      # If the -savecommand option was given, wrap it in an interp eval call
      # so that we don't execute the command in the master interpreter.
      if {[info exists opts(-savecommand)]} {
        set opts(-savecommand) "$interp eval $opts(-savecommand)"
      }

      # Change out the gutter commands with interpreter versions
      if {[info exists opts(-gutters)]} {
        set new_gutters [list]
        foreach gutter $opts(-gutters) {
          set new_sym [list]
          foreach {symname symopts} [lassign $gutter gutter_name] {
            set new_symopts [list]
            foreach {symopt symval} $symopts {
              switch $symopt {
                "-onenter" -
                "-onleave" -
                "-onclick" {
                  lappend new_symopts $symopt "$interp eval $symval"
                }
                default {
                  lappend new_symopts $symopt $symval
                }
              }
            }
            lappend new_sym $symname $new_symopts
          }
          lappend new_gutters [list $gutter_name {*}$new_sym]
        }
        set opts(-gutters) $new_gutters
      }

      # Finally, add the new file
      if {$fname eq ""} {
        gui::add_new_file end {*}[array get opts]
      } else {
        gui::add_file end $fname {*}[array get opts]
      }

      # Allow the plugin to manipulate the ctext widget
      set txt [gui::current_txt {}]
      $interp alias $txt $txt

      return $txt

    }

  }

  namespace eval sidebar {

    ######################################################################
    ## \return Returns the selected sidebar file index.
    proc get_selected_index {interp pname} {

      return [sidebar::get_selected_index]

    }

    ######################################################################
    ## \return Returns the value for the specified attribute of the
    #          file/directory in the sidebar with the given index.
    #
    #  \param sb_index  Sidebar index of file/directory in the sidebar
    #  \param attr      Attribute to return the value of.  Valid attribute
    #                   names are:
    #                   - \b fname      : Normalized name file or directory
    #                   - \b file_index : If not set, indicates the file has
    #                                     not been opened in the editor; otherwise,
    #                                     specifies the file index of the opened
    #                                     file.
    proc get_info {interp pname sb_index attr} {

      return [sidebar::get_info $sb_index $attr]

    }

  }
  
  namespace eval plugin {

    ######################################################################
    ## Saves the value of the given variable name to non-corruptible memory
    #  so that it can be later retrieved when the plugin is reloaded.
    #
    #  \param index  Unique value that is passed to the on_reload save command.
    #  \param name   Name of the variable to store
    #  \param value  Variable value to store
    proc save_variable {interp pname index name value} {

      plugins::save_data $index $name $value

    }

    ######################################################################
    ## Retrieves the value of the named variable from non-corruptible memory
    #  (from a previous save_variable call.
    #
    #  \param index  Unique value that is passed to the on_reload retrieve command.
    #  \param name   Name of the variable to get the value of.  If the named variable
    #                could not be found), an empty string is returned.
    proc load_variable {interp pname index name} {

      return [plugins::restore_data $index $name]

    }

  }

  namespace eval utils {

    ######################################################################
    ## Opens the given file in a file browser.  If in_background is set to
    #  a value of 1, the focus will remain in the editor; otherwise, focus
    #  will be given to the opening application.
    proc open_file {interp pname fname {in_background 0}} {

      utils::open_file_externally $fname $in_background

    }

  }

}
