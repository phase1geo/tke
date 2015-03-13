# Name:    menus.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace containing menu functionality

namespace eval menus {

  variable profile_report  [file join $::tke_home profiling_report.log]
  variable show_split_pane 0

  array set profiling_info {}

  #######################
  #  PUBLIC PROCEDURES  #
  #######################

  ######################################################################
  # Returns the menu associated with the given menu path.  The menu path
  # should be a list where each menu item is the name of the menu within
  # the path.  The final menu in the path should not be included in the
  # path.
  proc get_menu {menu_path} {

    set parent .menubar

    foreach mnu $menu_path {
      if {([set mnu_index [$parent index [msgcat::mc $mnu]]] eq "none") || ([$parent type $mnu_index] ne "cascade")} {
        return -code error "Invalid menu path specified"
      }
      set parent [$parent entrycget $mnu_index -menu]
    }

    return $parent

  }

  ######################################################################
  # Invokes the given index in the given menu, executing the menu's postcommand
  # if one exists.
  proc invoke {mnu index} {

    # If the menu contains a postcommand, execute it first
    if {[$mnu cget -postcommand] ne ""} {
      eval [$mnu cget -postcommand]
    }

    # Next, invoke the menu
    $mnu invoke $index

  }

  ######################################################################
  # Creates the main menu.
  proc create {} {

    set foreground [utils::get_default_foreground]
    set background [utils::get_default_background]

    set mb [menu .menubar -foreground $foreground -background $background -relief flat -tearoff false]

    # Add the file menu
    $mb add cascade -label [msgcat::mc "File"] -menu [menu $mb.file -relief flat -tearoff false -postcommand "menus::file_posting $mb.file"]
    add_file $mb.file

    # Add the edit menu
    $mb add cascade -label [msgcat::mc "Edit"] -menu [menu $mb.edit -tearoff false -postcommand "menus::edit_posting $mb.edit"]
    add_edit $mb.edit

    # Add the find menu
    $mb add cascade -label [msgcat::mc "Find"] -menu [menu $mb.find -tearoff false -postcommand "menus::find_posting $mb.find"]
    add_find $mb.find

    # Add the text menu
    $mb add cascade -label [msgcat::mc "Text"] -menu [menu $mb.text -tearoff false -postcommand "menus::text_posting $mb.text"]
    add_text $mb.text

    # Add the view menu
    $mb add cascade -label [msgcat::mc "View"] -menu [menu $mb.view -tearoff false -postcommand "menus::view_posting $mb.view"]
    add_view $mb.view

    # Add the tools menu
    $mb add cascade -label [msgcat::mc "Tools"] -menu [menu $mb.tools -tearoff false -postcommand "menus::tools_posting $mb.tools"]
    add_tools $mb.tools

    # Add the plugins menu
    $mb add cascade -label [msgcat::mc "Plugins"] -menu [menu $mb.plugins -tearoff false]
    add_plugins $mb.plugins

    # Add the help menu
    $mb add cascade -label [msgcat::mc "Help"] -menu [menu $mb.help -tearoff false]
    add_help $mb.help

    # If we are running on Mac OS X, add the window menu with the windowlist package
    if {[tk windowingsystem] eq "aqua"} {

      # Add the window menu with the windowlist package
      windowlist::windowMenu $mb

      # Add the launcher command to show the about window
      launcher::register "Menus: About TKE" gui::show_about

    }

    if {([tk windowingsystem] eq "aqua") || [preferences::get View/ShowMenubar]} {
      . configure -menu $mb
    }

    # Load and apply the menu bindings
    bindings::load

  }

  ######################################################################
  # Handles any changes to the General/WindowTheme preference variable.
  proc handle_window_theme {theme} {

    set foreground [utils::get_default_foreground]
    set background [utils::get_default_background]

    if {[winfo exists .menubar] && ([tk windowingsystem] ne "aqua")} {
      .menubar configure -foreground $foreground -background $background
    }

  }

  ########################
  #  PRIVATE PROCEDURES  #
  ########################

  ######################################################################
  # Adds the file menu.
  proc add_file {mb} {

    $mb delete 0 end

    $mb add command -label [msgcat::mc "New"] -underline 0 -command "menus::new_command"
    launcher::register [msgcat::mc "Menu: New file"] menus::new_command

    $mb add command -label [msgcat::mc "Open File..."] -underline 0 -command "menus::open_command"
    launcher::register [msgcat::mc "Menu: Open file"] menus::open_command

    $mb add command -label [msgcat::mc "Open Directory..."] -underline 5 -command "menus::open_dir_command"
    launcher::register [msgcat::mc "Menu: Open directory"] menus::open_dir_command

    $mb add cascade -label [msgcat::mc "Open Recent"] -menu [menu $mb.recent -tearoff false -postcommand "menus::file_recent_posting $mb.recent"]
    launcher::register [msgcat::mc "Menu: Open Recent"] menus::launcher

    $mb add cascade -label [msgcat::mc "Open Favorite"] -menu [menu $mb.favorites -tearoff false -postcommand "menus::file_favorites_posting $mb.favorites"]
    launcher::register [msgcat::mc "Menu: Open Favorite"] favorites::launcher

    $mb add separator

    $mb add command -label [msgcat::mc "Save"] -underline 0 -command "menus::save_command"
    launcher::register [msgcat::mc "Menu: Save file"] menus::save_command

    $mb add command -label [msgcat::mc "Save As..."] -underline 5 -command "menus::save_as_command"
    launcher::register [msgcat::mc "Menu: Save file as"] menus::save_as_command

    $mb add command -label [msgcat::mc "Save All"] -underline 6 -command "gui::save_all"
    launcher::register [msgcat::mc "Menu: Save all files"] gui::save_all

    $mb add separator

    $mb add command -label [msgcat::mc "Lock"] -underline 0 -command "menus::lock_command $mb"
    launcher::register [msgcat::mc "Menu: Lock file"] "menus::lock_command $mb"
    launcher::register [msgcat::mc "Menu: Unlock file"] "menus::unlock_command $mb"

    $mb add command -label [msgcat::mc "Favorite"] -underline 0 -command "menus::favorite_command $mb"
    launcher::register [msgcat::mc "Menu: Favorite file"] "menus::favorite_command $mb"
    launcher::register [msgcat::mc "Menu: Unfavorite file"] "menus::unfavorite_command $mb"

    $mb add separator

    $mb add command -label [msgcat::mc "Close"] -underline 0 -command "menus::close_command"
    launcher::register [msgcat::mc "Menu: Close current tab"] menus::close_command

    $mb add command -label [msgcat::mc "Close All"] -underline 6 -command "menus::close_all_command"
    launcher::register [msgcat::mc "Menu: Close all tabs"] menus::close_all_command

    # Only add the quit menu to File if we are not running in aqua
    if {[tk windowingsystem] ne "aqua"} {
      $mb add separator
      $mb add command -label [msgcat::mc "Quit"] -underline 0 -command "menus::exit_command"
    }
    launcher::register [msgcat::mc "Menu: Quit application"] menus::exit_command

  }

  ######################################################################
  # Called prior to the file menu posting.
  proc file_posting {mb} {

    # Get the current file index (if one exists)
    if {[set file_index [gui::current_file]] != -1} {

      # Get the current readonly status
      set readonly [gui::get_file_info $file_index readonly]

      # Get the current file lock status
      set file_lock [expr $readonly || [gui::get_file_info [gui::current_file] lock]]

      # Get the current favorite status
      set favorite [favorites::is_favorite [gui::get_file_info $file_index fname]]

      # Configure the Lock/Unlock menu item
      if {$file_lock && ![catch "$mb index Lock" index]} {
        $mb entryconfigure $index -label [msgcat::mc "Unlock"] -state normal -command "menus::unlock_command $mb"
        if {$readonly} {
          $mb entryconfigure $index -state disabled
        }
      } elseif {!$file_lock && ![catch "$mb index Unlock" index]} {
        $mb entryconfigure $index -label [msgcat::mc "Lock"] -state normal -command "menus::lock_command $mb"
      }

      # Configure the Favorite/Unfavorite menu item
      if {$favorite && ![catch "$mb index Favorite" index]} {
        $mb entryconfigure $index -label [msgcat::mc "Unfavorite"] -state normal -command "menus::unfavorite_command $mb"
      } elseif {!$favorite && ![catch "$mb index Unfavorite" index]} {
        $mb entryconfigure $index -label [msgcat::mc "Favorite"] -state normal -command "menus::favorite_command $mb"
      }

      # Make sure that the file-specific items are enabled
      $mb entryconfigure [msgcat::mc "Save"]       -state normal
      $mb entryconfigure [msgcat::mc "Save As..."] -state normal
      $mb entryconfigure [msgcat::mc "Save All"]   -state normal
      $mb entryconfigure [msgcat::mc "Close"]      -state normal
      $mb entryconfigure [msgcat::mc "Close All"]  -state normal

    } else {

      # Disable file menu items associated with current tab (since one doesn't currently exist)
      $mb entryconfigure [msgcat::mc "Save"]       -state disabled
      $mb entryconfigure [msgcat::mc "Save As..."] -state disabled
      $mb entryconfigure [msgcat::mc "Save All"]   -state disabled
      $mb entryconfigure [msgcat::mc "Lock"]       -state disabled
      $mb entryconfigure [msgcat::mc "Favorite"]   -state disabled
      $mb entryconfigure [msgcat::mc "Close"]      -state disabled
      $mb entryconfigure [msgcat::mc "Close All"]  -state disabled

    }

    # Configure the Open Recent menu
    if {([preferences::get View/ShowRecentlyOpened] == 0) || ([llength [gui::get_last_opened]] == 0)} {
      $mb entryconfigure [msgcat::mc "Open Recent"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Open Recent"] -state normal
    }

    # Configure the Open Favorite menu
    if {[llength [favorites::get_list]] == 0} {
      $mb entryconfigure [msgcat::mc "Open Favorite"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Open Favorite"] -state normal
    }

  }

  ######################################################################
  # Sets up the "Open Recent" menu prior to it being posted.
  proc file_recent_posting {mb} {

    # Clear the menu
    $mb delete 0 end

    # Populate the menu with the filenames and a "Clear All" menu option
    foreach fname [lrange [gui::get_last_opened] 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
      $mb add command -label [file tail $fname] -command "puts \"Adding $fname\"; gui::add_file end $fname"
    }
    $mb add separator
    $mb add command -label [msgcat::mc "Clear All"] -command "gui::clear_last_opened"

  }

  ######################################################################
  # Updates the "Open Favorite" menu prior to it being posted.
  proc file_favorites_posting {mb} {

    # Clear the menu
    $mb delete 0 end

    # Populate the menu with the filenames from the favorite list
    foreach path [favorites::get_list] {
      if {[file isdirectory $path]} {
        $mb add command -label $path -command "sidebar::add_directory $path"
      } else {
        $mb add command -label $path -command "gui::add_file end $path"
      }
    }

  }

  ######################################################################
  # Implements the "create new file" command.
  proc new_command {} {

    gui::add_new_file end

  }

  ######################################################################
  # Opens a new file and adds a new tab for the file.
  proc open_command {} {

    # Get the directory of the current file
    set dirname [file dirname [gui::current_filename]]

    if {[set ofiles [tk_getOpenFile -parent . -initialdir $dirname -filetypes [syntax::get_filetypes] -defaultextension .tcl -multiple 1]] ne ""} {
      foreach ofile $ofiles {
        gui::add_file end $ofile
      }
    }

  }

  ######################################################################
  # Opens a directory in the sidebar.
  proc open_dir_command {} {

    # Get the directory of the current file
    set dirname [file dirname [gui::current_filename]]

    if {[set odir [tk_chooseDirectory -parent . -initialdir $dirname -mustexist 1]] ne ""} {
      sidebar::add_directory $odir
    }

  }

  ######################################################################
  # Saves the current tab file.
  proc save_command {} {

    if {[set sfile [gui::current_filename]] eq ""} {
      save_as_command
    } else {
      gui::save_current {} $sfile
    }

  }

  ######################################################################
  # Saves the current tab file as a new filename.
  proc save_as_command {} {

    # Get the directory of the current file
    set dirname [file dirname [gui::current_filename]]

    # Get some of the save options
    set save_opts [list]
    if {[llength [set extensions [syntax::get_extensions {}]]] > 0} {
      lappend save_opts -defaultextension [lindex $extensions 0]
    }

    if {[set sfile [tk_getSaveFile {*}$save_opts -title [msgcat::mc "Save As"] -parent . -initialdir $dirname]] ne ""} {
      gui::save_current {} $sfile
    }

  }

  ######################################################################
  # Locks the current file.
  proc lock_command {mb} {

    # Lock the current file
    if {[gui::set_current_file_lock {} 1]} {

      # Set the menu up to display the unlock file menu option
      $mb entryconfigure [msgcat::mc "Lock"] -label [msgcat::mc "Unlock"] -command "menus::unlock_command $mb"

    }

  }

  ######################################################################
  # Unlocks the current file.
  proc unlock_command {mb} {

    # Unlock the current file
    if {[gui::set_current_file_lock {} 0]} {

      # Set the menu up to display the lock file menu option
      $mb entryconfigure [msgcat::mc "Unlock"] -label [msgcat::mc "Lock"] -command "menus::lock_command $mb"

    }

  }

  ######################################################################
  # Marks the current file as a favorite.
  proc favorite_command {mb} {

    # Get the current file index (if one exists)
    if {[set file_index [gui::current_file]] != -1} {

      # Add the file as a favorite
      if {[favorites::add [gui::get_file_info $file_index fname]]} {

        # Set the menu up to display the unfavorite file menu option
        $mb entryconfigure [msgcat::mc "Favorite"] -label [msgcat::mc "Unfavorite"] -command "menus::unfavorite_command $mb"

      }

    }

  }

  ######################################################################
  # Marks the current file as not favorited.
  proc unfavorite_command {mb} {

    # Get the current file index (if one exists)
    if {[set file_index [gui::current_file]] != -1} {

      # Remove the file as a favorite
      if {[favorites::remove [gui::get_file_info $file_index fname]]} {

        $mb entryconfigure [msgcat::mc "Unfavorite"] -label [msgcat::mc "Favorite"] -command "menus::favorite_command $mb"

      }

    }

  }

  ######################################################################
  # Closes the current tab.
  proc close_command {} {

    gui::close_current {}

  }

  ######################################################################
  # Closes all opened tabs.
  proc close_all_command {} {

    gui::close_all

  }

  ######################################################################
  # Cleans up the application to prepare it for being exited.
  proc exit_cleanup {} {

    # Save the session information if we are not told to exit on close
    gui::save_session

    # Close all of the tabs
    gui::close_all 1

    # Save the clipboard history
    cliphist::save

    # Handle on_quit plugins
    plugins::handle_on_quit

    # Turn off profiling (if it was turned on)
    if {[::tke_development]} {
      stop_profiling_command .menubar.tools 0
    }

  }

  ######################################################################
  # Exits the application.
  proc exit_command {} {

    # Clean up the application
    exit_cleanup

    # Destroy the interface
    destroy .

  }

  ######################################################################
  # Adds the edit menu.
  proc add_edit {mb} {

    # Add edit menu commands
    $mb add command -label [msgcat::mc "Undo"] -underline 0 -command "gui::undo {}"
    launcher::register [msgcat::mc "Menu: Undo"] "gui::undo {}"

    $mb add command -label [msgcat::mc "Redo"] -underline 0 -command "gui::redo {}"
    launcher::register [msgcat::mc "Menu: Redo"] "gui::redo {}"

    $mb add separator

    $mb add command -label [msgcat::mc "Cut"] -underline 0 -command "gui::cut {}"
    launcher::register [msgcat::mc "Menu: Cut selected text"] "gui::cut {}"

    $mb add command -label [msgcat::mc "Copy"] -underline 1 -command "gui::copy {}"
    launcher::register [msgcat::mc "Menu: Copy selected text"] "gui::copy {}"

    $mb add command -label [msgcat::mc "Paste"] -underline 0 -command "gui::paste {}"
    launcher::register [msgcat::mc "Menu: Paste text from clipboard"] "gui::paste {}"

    $mb add command -label [msgcat::mc "Paste and Format"] -underline 10 -command "gui::paste_and_format {}"
    launcher::register [msgcat::mc "Menu: Paste and format text from clipboard"] "gui::paste_and_format {}"

    $mb add command -label [msgcat::mc "Select All"] -underline 7 -command "gui::select_all {}"
    launcher::register [msgcat::mc "Menu: Select all text"] "gui::select_all {}"

    $mb add separator

    $mb add command -label [msgcat::mc "Enable Auto-Indent"] -underline 12 -command "gui::set_current_auto_indent {} 1"
    launcher::register [msgcat::mc "Menu: Enable auto-indent"]  "gui::set_current_auto_indent {} 1"
    launcher::register [msgcat::mc "Menu: Disable auto-indent"] "gui::set_current_auto_indent {} 0"

    $mb add separator

    $mb add cascade -label [msgcat::mc "Insert Text"] -menu [menu $mb.insertPopup -tearoff 0 -postcommand "menus::edit_insert_posting $mb.insertPopup"]
    $mb add cascade -label [msgcat::mc "Format Text"] -menu [menu $mb.formatPopup -tearoff 0 -postcommand "menus::edit_format_posting $mb.formatPopup"]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Preferences"]   -menu [menu $mb.prefPopup -tearoff 0 -postcommand "menus::edit_preferences_posting $mb.prefPopup"]
    $mb add cascade -label [msgcat::mc "Menu Bindings"] -menu [menu $mb.bindPopup -tearoff 0]
    $mb add cascade -label [msgcat::mc "Snippets"]      -menu [menu $mb.snipPopup -tearoff 0 -postcommand "menus::edit_snippets_posting $mb.snipPopup"]

    # Create insertion menu
    $mb.insertPopup add command -label [msgcat::mc "From Clipboard"] -command "cliphist::show_cliphist"
    launcher::register [msgcat::mc "Menu: Insert from clipboard"] "cliphist::show_cliphist"

    $mb.insertPopup add command -label [msgcat::mc "Snippet"] -command "snippets::show_snippets"
    launcher::register [msgcat::mc "Menu: Insert snippet"] "snippets::show_snippets"

    # Create formatting menu
    $mb.formatPopup add command -label [msgcat::mc "Selected"] -command "gui::format {} selected"
    launcher::register [msgcat::mc "Menu: Format selected text"] "gui::format {} selected"

    $mb.formatPopup add command -label [msgcat::mc "All"]      -command "gui::format {} all"
    launcher::register [msgcat::mc "Menu: Format all text"] "gui::format {} selected"

    # Create preferences menu
    $mb.prefPopup add command -label [msgcat::mc "View Base"] -command "preferences::view_global"
    launcher::register [msgcat::mc "Menu: View global preferences"] "preferences::view_global"

    $mb.prefPopup add command -label [msgcat::mc "Edit User"] -command "preferences::edit_user"
    launcher::register [msgcat::mc "Menu: Edit user preferences"] "preferences::edit_user"
    
    $mb.prefPopup add command -label [msgcat::mc "Edit Language"] -command "preferences::edit_language"
    launcher::register [msgcat::mc "Menu: Edit language preferences"] "preferences::edit_language"

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [msgcat::mc "Reset User to Base"] -command "preferences::copy_default"
    launcher::register [msgcat::mc "Menu: Set user preferences to global preferences"] "preferences::copy_default"

    # Create menu bindings menu
    $mb.bindPopup add command -label [msgcat::mc "View Global"] -command "bindings::view_global"
    launcher::register [msgcat::mc "Menu: View global menu bindings"] "bindings::view_global"

    $mb.bindPopup add command -label [msgcat::mc "Edit User"] -command "bindings::edit_user"
    launcher::register [msgcat::mc "Menu: Edit user menu bindings"] "bindings::edit_user"

    $mb.bindPopup add separator

    $mb.bindPopup add command -label [msgcat::mc "Set User to Global"] -command "bindings::copy_default"
    launcher::register [msgcat::mc "Menu: Set user bindings to global bindings"] "bindings::copy_default"

    # Create snippets menu
    $mb.snipPopup add command -label [msgcat::mc "Edit Current"] -command "snippets::add_new_snippet {}"
    launcher::register [msgcat::mc "Menu: Edit current snippets"] "snippets::add_new_snippet {}"

    $mb.snipPopup add separator

    $mb.snipPopup add command -label [msgcat::mc "Reload Current"] -command "snippets::reload_snippets"
    launcher::register [msgcat::mc "Menu: Reload current snippets"] "snippets::reload_snippets"

  }

  ######################################################################
  # Called just prior to posting the edit menu.  Sets the state of all
  # menu items to match the proper state of the UI.
  proc edit_posting {mb} {

    if {[gui::current_txt {}] eq ""} {
      $mb entryconfigure [msgcat::mc "Undo"]             -state disabled
      $mb entryconfigure [msgcat::mc "Redo"]             -state disabled
      $mb entryconfigure [msgcat::mc "Cut"]              -state disabled
      $mb entryconfigure [msgcat::mc "Copy"]             -state disabled
      $mb entryconfigure [msgcat::mc "Paste"]            -state disabled
      $mb entryconfigure [msgcat::mc "Paste and Format"] -state disabled
      $mb entryconfigure [msgcat::mc "Select All"]       -state disabled
      catch { $mb entryconfigure [msgcat::mc "Enable Auto-Indent"]  -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Disable Auto-Indent"] -state disabled }
      $mb entryconfigure [msgcat::mc "Insert Text"]      -state disabled
      $mb entryconfigure [msgcat::mc "Format Text"]      -state disabled
    } else {
      if {[gui::undoable {}]} {
        $mb entryconfigure [msgcat::mc "Undo"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Undo"] -state disabled
      }
      if {[gui::redoable {}]} {
        $mb entryconfigure [msgcat::mc "Redo"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Redo"] -state disabled
      }
      if {[gui::selected {}]} {
        $mb entryconfigure [msgcat::mc "Cut"]  -state normal
        $mb entryconfigure [msgcat::mc "Copy"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Cut"]  -state disabled
        $mb entryconfigure [msgcat::mc "Copy"] -state disabled
      }
      if {[gui::pastable {}]} {
        $mb entryconfigure [msgcat::mc "Paste"]            -state normal
        $mb entryconfigure [msgcat::mc "Paste and Format"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Paste"]            -state disabled
        $mb entryconfigure [msgcat::mc "Paste and Format"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Select All"]  -state normal
      set auto_indent_state [expr {[indent::is_auto_indent_available [gui::current_txt {}]] ? "normal" : "disabled"}]
      if {[indent::get_auto_indent [gui::current_txt {}]] && ![catch "$mb index {Enable Auto-Indent}" index]} {
        $mb entryconfigure $index -label [msgcat::mc "Disable Auto-Indent"] -underline 13 -state $auto_indent_state -command "gui::set_current_auto_indent {} 0"
      } elseif {![indent::get_auto_indent [gui::current_txt {}]] && ![catch "$mb index {Disable Auto-Indent}" index]} {
        $mb entryconfigure $index -label [msgcat::mc "Enable Auto-Indent"] -underline 12 -state $auto_indent_state -command "gui::set_current_auto_indent {} 1"
      }
      if {[gui::editable {}]} {
        $mb entryconfigure [msgcat::mc "Insert Text"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Insert Text"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Format Text"] -state normal
    }

  }

  ######################################################################
  # Called just prior to posting the edit/insert menu option.  Sets the
  # menu option states to match the current UI state.
  proc edit_insert_posting {mb} {

    if {[llength [cliphist::get_history]] > 0} {
      $mb entryconfigure [msgcat::mc "From Clipboard"] -state normal
    } else {
      $mb entryconfigure [msgcat::mc "From Clipboard"] -state disabled
    }

    if {[llength [snippets::get_current_snippets]] > 0} {
      $mb entryconfigure [msgcat::mc "Snippet"] -state normal
    } else {
      $mb entryconfigure [msgcat::mc "Snippet"] -state disabled
    }

  }

  ######################################################################
  # Called just prior to posting the edit/format menu option.  Sets the
  # menu option states to match the current UI state.
  proc edit_format_posting {mb} {

    if {[gui::selected {}]} {
      $mb entryconfigure [msgcat::mc "Selected"] -state normal
    } else {
      $mb entryconfigure [msgcat::mc "Selected"] -state disabled
    }

  }
  
  ######################################################################
  # Called just prior to posting the edit/preferences menu option.  Sets
  # the menu option states to match the current UI state.
  proc edit_preferences_posting {mb} {
    
    if {[gui::current_txt {}] eq ""} {
      $mb entryconfigure [msgcat::mc "Edit Language"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Edit Language"] -state normal
    }
    
  }

  ######################################################################
  # Called just prior to posting the edit/menu bindings menu option.
  # Sets the menu option states to match the current UI state.
  proc edit_snippets_posting {mb} {

    if {[gui::current_txt {}] eq ""} {
      $mb entryconfigure [msgcat::mc "Edit Current"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Edit Current"] -state normal
    }

  }

  ######################################################################
  # Add the find menu.
  proc add_find {mb} {

    # Add find menu commands
    $mb add command -label [msgcat::mc "Find"] -underline 0 -command "gui::search {}"
    launcher::register [msgcat::mc "Menu: Find"] "gui::search {}"

    $mb add command -label [msgcat::mc "Find and Replace"] -underline 9 -command "gui::search_and_replace"
    launcher::register [msgcat::mc "Menu: Find and Replace"] gui::search_and_replace

    $mb add separator

    $mb add command -label [msgcat::mc "Select next occurrence"] -underline 7 -command "gui::search_next {} 0"
    launcher::register [msgcat::mc "Menu: Find next occurrence"] "gui::search_next {}0"

    $mb add command -label [msgcat::mc "Select previous occurrence"] -underline 7 -command "gui::search_prev {} 0"
    launcher::register [msgcat::mc "Menu: Find previous occurrence"] "gui::search_prev {} 0"

    $mb add command -label [msgcat::mc "Append next occurrence"] -underline 1 -command "gui::search_next {} 1"
    launcher::register [msgcat::mc "Menu: Append next occurrence"] "gui::search_next {} 1"

    $mb add command -label [msgcat::mc "Select all occurrences"] -underline 7 -command "gui::search_all {}"
    launcher::register [msgcat::mc "Menu: Select all occurrences"] "gui::search_all {}"
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Jump backward"] -underline 5 -command "gui::jump_to_cursor {} -1 1"
    launcher::register [msgcat::mc "Menu: Jump backward"] "gui::jump_to_cursor {} -1 1"

    $mb add command -label [msgcat::mc "Jump forward"] -underline 5 -command "gui::jump_to_cursor {} 1 1"
    launcher::register [msgcat::mc "Menu: Jump forward"] "gui::jump_to_cursor {} 1 1"

    $mb add separator

    $mb add cascade -label [msgcat::mc "Find marker"] -underline 5 -menu [menu $mb.markerPopup -tearoff 0 -postcommand "menus::find_marker_posting $mb.markerPopup"]

    $mb add separator

    $mb add command -label [msgcat::mc "Find matching pair"] -underline 5 -command "gui::show_match_pair {}"
    launcher::register [msgcat::mc "Menu: Find matching character pair"] "gui::show_match_pair {}"

    $mb add separator

    $mb add command -label [msgcat::mc "Find in files"] -underline 5 -command "menus::find_in_files"
    launcher::register [msgcat::mc "Menu: Find in files"] "menus::find_in_files"

  }

  ######################################################################
  # Called just prior to posting the find menu.  Sets the state of the menu
  # items to match the current UI state.
  proc find_posting {mb} {

    if {[set txt [gui::current_txt {}]] eq ""} {
      $mb entryconfigure [msgcat::mc "Find"]                       -state disabled
      $mb entryconfigure [msgcat::mc "Find and Replace"]           -state disabled
      $mb entryconfigure [msgcat::mc "Select next occurrence"]     -state disabled
      $mb entryconfigure [msgcat::mc "Select previous occurrence"] -state disabled
      $mb entryconfigure [msgcat::mc "Append next occurrence"]     -state disabled
      $mb entryconfigure [msgcat::mc "Select all occurrences"]     -state disabled
      $mb entryconfigure [msgcat::mc "Jump backward"]              -state disabled
      $mb entryconfigure [msgcat::mc "Jump forward"]               -state disabled
      $mb entryconfigure [msgcat::mc "Find marker"]                -state disabled
      $mb entryconfigure [msgcat::mc "Find matching pair"]         -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Find"]                       -state normal
      $mb entryconfigure [msgcat::mc "Find and Replace"]           -state normal
      $mb entryconfigure [msgcat::mc "Select next occurrence"]     -state normal
      $mb entryconfigure [msgcat::mc "Select previous occurrence"] -state normal
      $mb entryconfigure [msgcat::mc "Append next occurrence"]     -state normal
      $mb entryconfigure [msgcat::mc "Select all occurrences"]     -state normal
      if {[gui::jump_to_cursor {} -1 0]} {
        $mb entryconfigure [msgcat::mc "Jump backward"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Jump backward"] -state disabled
      }
      if {[gui::jump_to_cursor {} 1 0]} {
        $mb entryconfigure [msgcat::mc "Jump forward"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Jump forward"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Find matching pair"] -state normal
      if {[llength [gui::get_marker_list {}]] > 0} {
        $mb entryconfigure [msgcat::mc "Find marker"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Find marker"] -state disabled
      }
    }

  }

  ######################################################################
  # Called when the marker menu is opened.
  proc find_marker_posting {mb} {

    # Clear the menu
    $mb delete 0 end

    foreach {marker pos} [gui::get_marker_list {}] {
      $mb add command -label $marker -command "gui::jump_to {} $pos"
    }

  }

  ######################################################################
  # Performs an egrep-like search in a user-specified list of files/directories.
  proc find_in_files {} {

    set rsp_list [list]

    # Display the find UI to the user and get input
    if {[gui::fif_get_input rsp_list]} {

      array set rsp $rsp_list

      # Convert directories into files
      array set files {}
      foreach file $rsp(in) {
        if {[file isdirectory $file]} {
          foreach sfile [glob -nocomplain -directory $file -types {f r} *] {
            if {![sidebar::ignore_file $sfile]} {
              set files($sfile) 1
            }
          }
        } elseif {![sidebar::ignore_file $file]} {
          set files($file) 1
        }
      }

      # Perform egrep operation (test)
      if {[array size files] > 0} {
        bgproc::system find_in_files "egrep -a -H -C[preferences::get Find/ContextNum] -n $rsp(egrep_opts) -s {$rsp(find)} [lsort [array names files]]" -killable 1 \
          -callback "menus::find_in_files_callback [list $rsp(find)] [array size files]"
      } else {
        gui::set_info_message "No files found in specified directories"
      }

    }

  }

  ######################################################################
  # Called when the egrep operation has completed.
  proc find_in_files_callback {find_expr num_files err data} {

    variable txt_cursor

    # Add the file to the viewer
    gui::add_file end Results -sidebar 0 -buffer 1

    # Add bindings to allow one-click file opening
    set txt [gui::current_txt {}]

    # Get the last index of the text widget
    set last_line [$txt index end]

    # Insert a starting mark
    $txt insert end "----\n"

    if {!$err || ($num_files == 0)} {

      # Save the text cursor
      set txt_cursor [$txt cget -cursor]

      # Append the results to the text widget
      $txt insert end [find_in_files_format $data]

      # Highlight and bind the matches
      $txt tag configure fif -underline 1 -borderwidth 1 -relief raised -foreground black -background yellow
      set i 0
      foreach index [$txt search -regexp -all -count find_counts -- $find_expr $last_line] {
        $txt tag add fif $index "$index + [lindex $find_counts $i]c"
        $txt tag bind fif <Enter>           { %W configure -cursor hand2 }
        $txt tag bind fif <Leave>           { %W configure -cursor $menus::txt_cursor }
        $txt tag bind fif <ButtonRelease-1> { menus::find_in_files_handle_click %W %x %y }
        incr i
      }

      bind $txt <Key-space> { if {[menus::find_in_files_handle_space %W]} break }

    } else {

      $txt insert end "ERROR: $data\n\n\n"

    }

    # Adjust the Vim insert cursor
    vim::adjust_insert $txt.t

    # Make sure that the beginning of the inserted text is in view
    $txt see end
    $txt mark set insert $last_line
    $txt see $last_line

  }

  ######################################################################
  # Formats the raw egrep data to make it more readable.
  proc find_in_files_format {data} {

    set results         ""
    set file_results    [list]
    set last_linenum    ""
    set first_separator 1
    array set indices   {}
    array set fnames    {}
    set index           0
    set matches         0

    foreach line [split $data \n] {
      if {[regexp {^(.*?)([:-])(\d+)[:-](.*)$} $line -> fname type linenum content]} {
        set first_separator 1
        if {![info exists fnames($fname)]} {
          set fnames($fname) 1
          if {[llength $file_results] > 0} {
            if {[string trim [lindex $file_results end]] eq "..."} {
              set file_results [lrange $file_results 0 end-1]
            }
            append results "[join $file_results \n]\n\n"
            set file_results [list]
          }
          lappend file_results "  [file normalize $fname]:\n"
          set last_linenum ""
          array unset indices
        }
        if {$type eq ":"} {
          if {($last_linenum eq "") || ($linenum > $last_linenum)} {
            lappend file_results [format "    %6d: %s" $linenum $content]
            set indices($linenum) $index
            set last_linenum $linenum
            incr index
          } else {
            lset file_results $indices($linenum) [string replace [lindex $file_results $indices($linenum)] 11 11 ":"]
          }
          incr matches
        } else {
          if {($last_linenum eq "") || ($linenum > $last_linenum)} {
            lappend file_results [format "    %6d  %s" $linenum $content]
            set indices($linenum) $index
            set last_linenum $linenum
            incr index
          }
        }
      } elseif {[string trim $line] eq "--"} {
        if {$first_separator} {
          set first_separator 0
        } else {
          lappend file_results "    ..."
        }
      }
    }

    # Append the last files information to the results string
    append results "[join $file_results \n]\n\n"

    return "Found $matches [expr {($matches != 1) ? {matches} : {match}}] in [array size fnames] [expr {([array size fnames] != 1) ? {files} : {file}}]\n\n$results"

  }

  ######################################################################
  # Handles a left-click on a matched pattern in the given text widget.
  # Causes the matching file to be opened and we jump to the matching line.
  proc find_in_files_handle_selection {W index} {

    # Get the line number from the beginning of the line
    regexp {^\s*(\d+)} [$W get "$index linestart" $index] -> linenum

    # Get the filename of the line that is clicked
    set findex [$W search -regexp -backwards -count fif_count -- {^\s*/.*:$} $index]
    set fname  [$W get $findex "$findex+[expr $fif_count - 1]c"]

    # Add the file to the file viewer (if necessary)
    gui::add_file end [string trim $fname]

    # Jump to the line and set the cursor to the beginning of the line
    set txt [gui::current_txt {}]
    $txt see $linenum.0
    $txt mark set insert $linenum.0

  }

  ######################################################################
  # Handles a left-click on a matched pattern in the given text widget.
  proc find_in_files_handle_click {W x y} {

    find_in_files_handle_selection $W [$W index @$x,$y]

  }

  ######################################################################
  # Handles a space bar key hit on a matched pattern in the given text
  # widget.
  proc find_in_files_handle_space {W} {

    # Get the current insertion index
    set insert [$W index insert]

    # Check to see if the space bar was hit inside of a tag
    foreach {first last} [$W tag ranges fif] {
      if {[$W compare $first <= $insert] && [$W compare $insert < $last]} {
        find_in_files_handle_selection $W [$W index insert]
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Adds the text menu commands.
  proc add_text {mb} {

    $mb add command -label [msgcat::mc "Comment"] -underline 0 -command "texttools::comment {}"
    launcher::register [msgcat::mc "Menu: Comment selected text"] "texttools::comment {}"

    $mb add command -label [msgcat::mc "Uncomment"] -underline 0 -command "texttools::uncomment {}"
    launcher::register [msgcat::mc "Menu: Uncomment selected text"] "texttools::uncomment {}"

    $mb add command -label [msgcat::mc "Indent"] -underline 0 -command "texttools::indent {}"
    launcher::register [msgcat::mc "Menu: Indent selected text"] "texttools::indent {}"

    $mb add command -label [msgcat::mc "Unindent"] -underline 1 -command "texttools::unindent {}"
    launcher::register [msgcat::mc "Menu: Unindent selected text"] "texttools::unindent {}"

    $mb add separator

    $mb add command -label [msgcat::mc "Align cursors"] -underline 0 -command "texttools::align {}"
    launcher::register [msgcat::mc "Menu: Align cursors"] "texttools::align {}"

    $mb add command -label [msgcat::mc "Insert enumeration"] -underline 7 -command "texttools::insert_enumeration {}"
    launcher::register [msgcat::mc "Menu: Insert enumeration"] "texttools::insert_enumeration {}"

  }

  ######################################################################
  # Called prior to the text menu posting.
  proc text_posting {mb} {

    if {[set txt [gui::current_txt {}]] eq ""} {
      $mb entryconfigure [msgcat::mc "Comment"]            -state disabled
      $mb entryconfigure [msgcat::mc "Uncomment"]          -state disabled
      $mb entryconfigure [msgcat::mc "Indent"]             -state disabled
      $mb entryconfigure [msgcat::mc "Unindent"]           -state disabled
      $mb entryconfigure [msgcat::mc "Align cursors"]      -state disabled
      $mb entryconfigure [msgcat::mc "Insert enumeration"] -state disabled
    } else {
      if {[lindex [syntax::get_comments [gui::current_txt {}]] 0] eq ""} {
        $mb entryconfigure [msgcat::mc "Comment"]   -state disabled
        $mb entryconfigure [msgcat::mc "Uncomment"] -state disabled
      } else {
        $mb entryconfigure [msgcat::mc "Comment"]   -state normal
        $mb entryconfigure [msgcat::mc "Uncomment"] -state normal
      }
      $mb entryconfigure [msgcat::mc "Indent"]   -state normal
      $mb entryconfigure [msgcat::mc "Unindent"] -state normal
      if {[multicursor::enabled $txt]} {
        $mb entryconfigure [msgcat::mc "Align cursors"]      -state normal
        $mb entryconfigure [msgcat::mc "Insert enumeration"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Align cursors"]      -state disabled
        $mb entryconfigure [msgcat::mc "Insert enumeration"] -state disabled
      }
    }

  }

  ######################################################################
  # Adds the view menu commands.
  proc add_view {mb} {

    if {[preferences::get View/ShowSidebar]} {
      $mb add command -label [msgcat::mc "Hide Sidebar"] -underline 5 -command "menus::hide_sidebar_view $mb"
    } else {
      $mb add command -label [msgcat::mc "Show Sidebar"] -underline 5 -command "menus::show_sidebar_view $mb"
    }
    launcher::register [msgcat::mc "Menu: Show sidebar"] "menus::show_sidebar_view $mb"
    launcher::register [msgcat::mc "Menu: Hide sidebar"] "menus::hide_sidebar_view $mb"

    if {![catch "console hide"]} {
      if {[preferences::get View/ShowConsole]} {
        $mb add command -label [msgcat::mc "Hide Console"] -underline 5 -command "menus::hide_console_view $mb"
      } else {
        $mb add command -label [msgcat::mc "Show Console"] -underline 5 -command "menus::show_console_view $mb"
      }
      launcher::register [msgcat::mc "Menu: Show console"] "menus::show_console_view $mb"
      launcher::register [msgcat::mc "Menu: Hide console"] "menus::hide_console_view $mb"
    }

    if {[preferences::get View/ShowTabBar]} {
      $mb add command -label [msgcat::mc "Hide Tab Bar"] -underline 5 -command "menus::hide_tab_view $mb"
    } else {
      $mb add command -label [msgcat::mc "Show Tab Bar"] -underline 5 -command "menus::show_tab_view $mb"
    }
    launcher::register [msgcat::mc "Menu: Show Tab Bar"] "menus::show_tab_view $mb"
    launcher::register [msgcat::mc "Menu: Hide Tab Bar"] "menus::hide_tab_view $mb"

    if {[preferences::get View/ShowStatusBar]} {
      $mb add command -label [msgcat::mc "Hide Status Bar"] -underline 12 -command "menus::hide_status_view $mb"
    } else {
      $mb add command -label [msgcat::mc "Show Status Bar"] -underline 12 -command "menus::show_status_view $mb"
    }
    launcher::register [msgcat::mc "Menu: Show status bar"] "menus::show_status_view $mb"
    launcher::register [msgcat::mc "Menu: Hide status bar"] "menus::hide_status_view $mb"

    $mb add separator

    $mb add checkbutton -label [msgcat::mc "Split view"] -underline 6 -variable menus::show_split_pane -command "gui::toggle_split_pane {}"
    launcher::register [msgcat::mc "Menu: Toggle split view mode"] "gui::toggle_split_pane {}"

    $mb add command -label [msgcat::mc "Move to other pane"] -underline 0 -command "gui::move_to_pane"
    launcher::register [msgcat::mc "Menu: Move to other pane"] "gui::move_to_pane"

    $mb add separator

    $mb add cascade -label [msgcat::mc "Tabs"] -underline 0 -menu [menu $mb.tabPopup -tearoff 0 -postcommand "menus::view_tabs_posting $mb.tabPopup"]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Set Syntax"] -underline 9 -menu [menu $mb.syntaxMenu -tearoff 0 -postcommand "syntax::populate_syntax_menu $mb.syntaxMenu"]
    $mb add cascade -label [msgcat::mc "Set Theme"]  -underline 7 -menu [menu $mb.themeMenu  -tearoff 0 -postcommand "syntax::populate_theme_menu $mb.themeMenu"]

    # Setup the tab popup menu
    $mb.tabPopup add command -label [msgcat::mc "Goto Next Tab"] -underline 5 -command "gui::next_tab"
    launcher::register [msgcat::mc "Menu: Goto next tab"] "gui::next_tab"

    $mb.tabPopup add command -label [msgcat::mc "Goto Previous Tab"] -underline 5 -command "gui::previous_tab"
    launcher::register [msgcat::mc "Menu: Goto previous tab"] "gui::previous_tab"

    $mb.tabPopup add command -label [msgcat::mc "Goto Last Tab"] -underline 5 -command "gui::last_tab"
    launcher::register [msgcat::mc "Menu: Goto last tab"] "gui::last_tab"

    $mb.tabPopup add command -label [msgcat::mc "Goto Other Pane"] -underline 11 -command "gui::next_pane"
    launcher::register [msgcat::mc "Menu: Goto other pane"] "gui::next_pane"

    $mb.tabPopup add separator

    $mb.tabPopup add command -label [msgcat::mc "Sort Tabs"] -underline 0 -command "gui::sort_tabs"
    launcher::register [msgcat::mc "Menu: Sort tabs"] "gui::sort_tabs"

  }

  ######################################################################
  # Called just prior to posting the view menu.  Sets the state of the
  # menu options to match the current UI state.
  proc view_posting {mb} {

    variable show_split_pane

    if {([gui::tabs_in_pane] < 2) && ([gui::panes] < 2)} {
      $mb entryconfigure [msgcat::mc "Tabs"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Tabs"] -state normal
    }

    if {[gui::current_txt {}] eq ""} {
      $mb entryconfigure [msgcat::mc "Split view"]         -state disabled
      $mb entryconfigure [msgcat::mc "Move to other pane"] -state disabled
      $mb entryconfigure [msgcat::mc "Set Syntax"]         -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Split view"]         -state normal
      if {[gui::movable_to_other_pane]} {
        $mb entryconfigure [msgcat::mc "Move to other pane"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Move to other pane"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Set Syntax"]         -state normal
      set show_split_pane [expr {[llength [[gui::current_txt {}] peer names]] > 0}]
    }

  }

  ######################################################################
  # Called just prior to posting the view/tabs menu.  Sets the state of
  # the menu options to match the current UI state.
  proc view_tabs_posting {mb} {

    if {[gui::tabs_in_pane] < 2} {
      $mb entryconfigure [msgcat::mc "Goto Next Tab"]     -state disabled
      $mb entryconfigure [msgcat::mc "Goto Previous Tab"] -state disabled
      $mb entryconfigure [msgcat::mc "Goto Last Tab"]     -state disabled
      $mb entryconfigure [msgcat::mc "Sort Tabs"]         -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Goto Next Tab"]     -state normal
      $mb entryconfigure [msgcat::mc "Goto Previous Tab"] -state normal
      $mb entryconfigure [msgcat::mc "Goto Last Tab"]     -state normal
      $mb entryconfigure [msgcat::mc "Sort Tabs"]         -state normal
    }

    if {[gui::panes] < 2} {
      $mb entryconfigure [msgcat::mc "Goto Other Pane"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Goto Other Pane"] -state normal
    }

  }

  ######################################################################
  # Shows the sidebar panel.
  proc show_sidebar_view {mb} {

    # Convert the menu command into the hide sidebar command
    if {![catch {$mb entryconfigure [msgcat::mc "Show Sidebar"] -label [msgcat::mc "Hide Sidebar"] -command "menus::hide_sidebar_view $mb"}]} {
      gui::show_sidebar_view
    }

  }

  ######################################################################
  # Hides the sidebar panel.
  proc hide_sidebar_view {mb} {

    # Convert the menu command into the hide sidebar command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Sidebar"] -label [msgcat::mc "Show Sidebar"] -command "menus::show_sidebar_view $mb"}]} {
      gui::hide_sidebar_view
    }

  }

  ######################################################################
  # Shows the console.
  proc show_console_view {mb} {

    # Convert the menu command into the hide console command
    if {![catch {$mb entryconfigure [msgcat::mc "Show Console"] -label [msgcat::mc "Hide Console"] -command "menus::hide_console_view $mb"}]} {
      gui::show_console_view
    }

  }

  ######################################################################
  # Hides the console.
  proc hide_console_view {mb} {

    # Convert the menu command into the show console command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Console"] -label [msgcat::mc "Show Console"] -command "menus::show_console_view $mb"}]} {
      gui::hide_console_view
    }

  }

  ######################################################################
  # Shows the tab bar.
  proc show_tab_view {mb} {

    # Convert the menu command into the hide tab bar command
    if {![catch {$mb entryconfigure [msgcat::mc "Show Tab Bar"] -label [msgcat::mc "Hide Tab Bar"] -command "menus::hide_tab_view $mb"}]} {
      gui::show_tab_view
    }

  }

  ######################################################################
  # Hides the tab bar.
  proc hide_tab_view {mb} {

    # Convert the menu command into the show tab bar command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Tab Bar"] -label [msgcat::mc "Show Tab Bar"] -command "menus::show_tab_view $mb"}]} {
      gui::hide_tab_view
    }

  }

  ######################################################################
  # Shows the status bar.
  proc show_status_view {mb} {

    # Convert the menu command into the hide status bar command
    if {![catch {$mb entryconfigure [msgcat::mc "Show Status Bar"] -label [msgcat::mc "Hide Status Bar"] -command "menus::hide_status_view $mb"}]} {
      gui::show_status_view
    }

  }

  ######################################################################
  # Hides the status bar.
  proc hide_status_view {mb} {

    # Convert the menu command into the show status bar command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Status Bar"] -label [msgcat::mc "Show Status Bar"] -command "menus::show_status_view $mb"}]} {
      gui::hide_status_view
    }

  }

  ######################################################################
  # Adds the tools menu commands.
  proc add_tools {mb} {

    # Add tools menu commands
    $mb add command -label [msgcat::mc "Launcher"] -underline 0 -command "launcher::launch"

    $mb add cascade -label [msgcat::mc "Theme Creator"] -underline 0 -menu [menu $mb.themer -tearoff 0]

    $mb.themer add command -label [msgcat::mc "Create new..."] -underline 0 -command "menus::create_theme_command"
    launcher::register [msgcat::mc "Menu: Create new theme"] "themer::create_theme_command"

    $mb.themer add command -label [msgcat::mc "Edit..."] -underline 0 -command "menus::edit_theme_command"
    launcher::register [msgcat::mc "Menu: Edit Tke theme"] "menus::edit_theme_command"

    $mb.themer add command -label [msgcat::mc "Import TextMate theme..."] -underline 0 -command "menus::import_tm_command"
    launcher::register [msgcat::mc "Menu: Import TextMate theme"] "menus::import_tm_command"

    $mb add separator

    $mb add checkbutton -label [msgcat::mc "Vim Mode"] -underline 0 -variable preferences::prefs(Tools/VimMode) -command "vim::set_vim_mode_all"
    launcher::register [msgcat::mc "Menu: Enable Vim mode"]  "set preferences::prefs(Tools/VimMode) 1; vim::set_vim_mode_all"
    launcher::register [msgcat::mc "Menu: Disable Vim mode"] "set preferences::prefs(Tools/VimMode) 0; vim::set_vim_mode_all"

    # Add development tools
    if {[::tke_development]} {

      $mb add separator

      $mb add command -label [msgcat::mc "Start Profiling"] -underline 0 -command "menus::start_profiling_command $mb"
      launcher::register [msgcat::mc "Menu: Start profiling"] "menus::start_profiling_command $mb"

      $mb add command -label [msgcat::mc "Stop Profiling"] -underline 1 -command "menus::stop_profiling_command $mb 1" -state disabled
      launcher::register [msgcat::mc "Menu: Stop profiling"] "menus::stop_profiling_command $mb 1"

      $mb add command -label [msgcat::mc "Show Last Profiling Report"] -underline 1 -command "menus::show_last_profiling_report"
      launcher::register [msgcat::mc "Menu: Show last profiling report"] "menus::show_last_profiling_report"

      $mb add separator

      $mb add command -label [msgcat::mc "Restart tke"] -underline 0 -command "menus::restart_command"
      launcher::register [msgcat::mc "Menu: Restart tke"] "menus::restart_command"

    }

  }

  ######################################################################
  # Called prior to the tools menu posting.
  proc tools_posting {mb} {

    variable profile_report

    if {[::tke_development]} {
      if {[file exists $profile_report]} {
        $mb entryconfigure [msgcat::mc "Show*Profiling*"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Show*Profiling*"] -state disabled
      }
    }

  }

  ######################################################################
  # Creates a new theme and reloads the themes.
  proc create_theme_command {} {

    # Create a new theme using the theme creation tool
    themer::create_new syntax::load_themes

  }

  ######################################################################
  # Allows the user to select one of the Tke themes to edit and calls
  # up the theme editor.
  proc edit_theme_command {} {

    # Attempt to get the name of an available theme
    if {[set name [themer::get_theme]] ne ""} {

      # Call the themer importer for the given tke file
      themer::import_tke $name syntax::load_themes

    }

  }

  ######################################################################
  # Allows the user to select an existing TextMate theme to import and
  # calls the theme importer.
  proc import_tm_command {} {

    # Open a TextMate theme
    if {[set name [tk_getOpenFile -filetypes {{TextMate {.tmTheme .tmtheme}}} -initialdir [pwd] -parent . -title "Select TextMate theme"]] ne ""} {

      # Call the themer importer for the given TextMate file
      themer::import_tm $name syntax::load_themes

    }

  }

  ######################################################################
  # Starts the procedure profiling.
  proc start_profiling_command {mb} {

    if {[$mb entrycget [msgcat::mc "Start Profiling"] -state] eq "normal"} {

      # Turn on procedure profiling
      profile {*}[preferences::get Tools/ProfileReportOptions] on

      # Indicate that profiling mode is on
      $mb entryconfigure [msgcat::mc "Start Profiling"] -state disabled
      $mb entryconfigure [msgcat::mc "Stop Profiling"]  -state normal

      # Indicate that profiling has started in the information bar
      gui::set_info_message [msgcat::mc "Profiling started"]

    }

  }

  ######################################################################
  # Stops the profiling process, generates a report and displays the
  # report file to a new editor tab.
  proc stop_profiling_command {mb show_report} {

    variable profile_report
    variable profiling_info

    if {[$mb entrycget [msgcat::mc "Stop Profiling"] -state] eq "normal"} {

      # Turn off procedure profiling
      profile off profiling_info

      # Generate a report file
      generate_profile_report
      # set sortby [preferences::get Tools/ProfileReportSortby]
      # profrep profiling_info $sortby $profile_report "Profiling Information Sorted by $sortby"

      # Indicate that profiling has completed
      gui::set_info_message [msgcat::mc "Profiling stopped"]

      # Add the report to the tab list
      if {$show_report} {
        show_last_profiling_report
      }

      # Indicate that profiling mode is off
      $mb entryconfigure [msgcat::mc "Stop Profiling"] -state disabled
      $mb entryconfigure [msgcat::mc "Start Profiling"] -state normal

    }

  }

  ######################################################################
  # Displays the last profiling report.
  proc show_last_profiling_report {} {

    variable profile_report

    # If the profiling report exists, display it
    if {[file exists $profile_report]} {
      gui::add_file end $profile_report -lock 1
    }

  }

  ######################################################################
  # Generates a profiling report.
  proc generate_profile_report {} {

    variable profile_report
    variable profiling_info

    # Recollect the data
    set info_list [list]
    foreach info [array names profiling_info] {

      set name [lindex $info 0]

      # If the name matches anything that we don't want to profile,
      # skip to the next iteration now
      if {[regexp {^(((::)?(tk::|tcl::|ttk::|tablelist::|mwutil::))|<global>|::\w+$)} $name]} {
        continue
      }

      set calls [lindex $profiling_info($info) 0]
      set real  [lindex $profiling_info($info) 1]
      set cpu   [lindex $profiling_info($info) 2]

      if {[set index [lsearch -index 0 $info_list [lindex $info 0]]] == -1} {
        lappend info_list [list [lindex $info 0] $calls $real $cpu 0.0 0.0]
      } else {
        set info_entry [lindex $info_list $index]
        lset info_list $index 1 [expr [lindex $info_entry 1] + $calls]
        lset info_list $index 2 [expr [lindex $info_entry 2] + $real]
        lset info_list $index 3 [expr [lindex $info_entry 3] + $cpu]
      }

    }

    # Calculate the real/call and cpu/call values
    for {set i 0} {$i < [llength $info_list]} {incr i} {
      set info_entry [lindex $info_list $i]
      if {[lindex $info_entry 1] > 0} {
        lset info_list $i 4 [expr [lindex $info_entry 2].0 / [lindex $info_entry 1]]
        lset info_list $i 5 [expr [lindex $info_entry 3].0 / [lindex $info_entry 1]]
      }
    }

    # Sort the information
    switch [preferences::get Tools/ProfileReportSortby] {
      "calls"         { set info_list [lsort -decreasing -integer -index 1 $info_list] }
      "real"          { set info_list [lsort -decreasing -integer -index 2 $info_list] }
      "cpu"           { set info_list [lsort -decreasing -integer -index 3 $info_list] }
      "real_per_call" { set info_list [lsort -decreasing -real -index 4 $info_list] }
      "cpu_per_call"  { set info_list [lsort -decreasing -real -index 5 $info_list] }
      default         { set info_list [lsort -index 0 $info_list] }
    }

    # Create the report file
    if {![catch "open $profile_report w" rc]} {

      puts $rc "=============================================================================================================="
      puts $rc [msgcat::mc "                                  Profiling Report Sorted By (%s)" [preferences::get Tools/ProfileReportSortby]]
      puts $rc "=============================================================================================================="
      puts $rc [format "%-50s  %10s  %10s  %10s  %10s  %10s" "Procedure" "Calls" "Real" "CPU" "Real/Calls" "CPU/Calls"]
      puts $rc "=============================================================================================================="

      foreach info $info_list {
        puts $rc [format "%-50s  %10d  %10d  %10d  %10.3f  %10.3f" {*}$info]
      }

      close $rc

    }

  }

  ######################################################################
  # Restart the GUI.
  proc restart_command {} {

    # Get the list of filenames to start
    set filenames [gui::get_actual_filenames]

    # Execute the restart command
    exec [info nameofexecutable] [file join $::tke_dir restart.tcl] [info nameofexecutable] [file join $::tke_dir tke.tcl] {*}$filenames &

  }

  ######################################################################
  # Add the plugins menu commands.
  proc add_plugins {mb} {

    # Add plugins menu commands
    $mb add command -label [msgcat::mc "Install..."] -underline 0 -command "plugins::install"
    launcher::register [msgcat::mc "Menu: Install plugin"] "plugins::install"

    $mb add command -label [msgcat::mc "Uninstall..."] -underline 0 -command "plugins::uninstall"
    launcher::register [msgcat::mc "Menu: Uninstall plugin"] "plugins::uninstall"

    $mb add command -label [msgcat::mc "Reload"] -underline 0 -command "plugins::reload"
    launcher::register [msgcat::mc "Menu: Reload all plugins"] "plugins::reload"

    if {[::tke_development]} {

      $mb add separator
      $mb add command -label [msgcat::mc "Create..."] -underline 0 -command "plugins::create_new_plugin"
      launcher::register [msgcat::mc "Menu: Create new plugin"] "plugins::create_new_plugin"

    }

    # Allow the plugin architecture to add menu items
    plugins::handle_plugin_menu $mb

  }

  ######################################################################
  # Adds the help menu commands.
  proc add_help {mb} {

    $mb add command -label [msgcat::mc "User Guide"] -underline 0 -command [list utils::open_file_externally [file join $::tke_dir doc UserGuide.pdf]]
    launcher::register [msgcat::mc "Menu: View User Guide"] [list utils::open_file_externally [file join $::tke_dir doc UserGuide.pdf]]

    if {![string match *Win* $::tcl_platform(os)]} {
      if {[preferences::get General/UpdateReleaseType] eq "devel"} {
        set check_cmd "specl::check_for_update 0 [expr $specl::RTYPE_STABLE | $specl::RTYPE_DEVEL] {} menus::exit_cleanup"
      } else {
        set check_cmd "specl::check_for_update 0 $specl::RTYPE_STABLE {} menus::exit_cleanup"
      }
      $mb add separator
      $mb add command -label [msgcat::mc "Check for Update"] -underline 0 -command $check_cmd
      launcher::register [msgcat::mc "Menu: Check for Update"] $check_cmd
    }

    $mb add separator
    $mb add command -label [msgcat::mc "Send Feedback"] -underline 5 -command "menus::help_feedback_command"
    launcher::register [msgcat::mc "Menu: Send Feedback"] "menus::help_feedback_command"

    if {[tk windowingsystem] ne "aqua"} {
      $mb add command -label [msgcat::mc "About TKE"] -underline 0 -command "gui::show_about"
      launcher::register [msgcat::mc "Menu: About TKE"] "gui::show_about"
    }

  }

  ######################################################################
  # Generates an e-mail compose window to provide feedback.
  proc help_feedback_command {} {

    utils::open_file_externally "mailto:phase1geo@gmail.com?subject=Feedback for TKE" 1

  }

  ######################################################################
  # Displays the launcher with recently opened files.
  proc launcher {} {

    # Add favorites to launcher
    foreach fname [lrange [gui::get_last_opened] 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
      launcher::register_temp "`RECENT:$fname" [list gui::add_file end $fname] $fname
    }

    # Display the launcher in RECENT: mode
    launcher::launch "`RECENT:"

    # Unregister the recents
    foreach fname [lrange [gui::get_last_opened] 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
      launcher::unregister "`RECENT:$fname"
    }

  }

}

