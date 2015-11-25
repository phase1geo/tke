# TKE - Advanced Programmer's Editor
# Copyright (C) 2014  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:    menus.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace containing menu functionality
######################################################################

namespace eval menus {

  variable profile_report  [file join $::tke_home profiling_report.log]
  variable show_split_pane 0
  variable indent_mode     "IND+"
  variable last_devel_mode ""

  array set profiling_info {}

  trace add variable preferences::prefs(Debug/DevelopmentMode) write menus::handle_development_mode

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
  # Handles any changes to the Debug/DevelopmentMode preference value.
  proc handle_development_mode {{name1 ""} {name2 ""} {op ""}} {

    variable last_devel_mode

    # If the menubar does not exist, we have nothing further to do
    if {![winfo exists .menubar]} {
      return
    }

    # Get the development mode
    if {[set devel_mode [::tke_development]] ne $last_devel_mode} {

      # Delete the development tools if they exist but we are no longer in development mode
      if {$devel_mode} {

        set mb ".menubar.tools"
        $mb add separator
        $mb add command -label [msgcat::mc "Start Profiling"]            -underline 0 -command "menus::start_profiling_command $mb"
        $mb add command -label [msgcat::mc "Stop Profiling"]             -underline 1 -command "menus::stop_profiling_command $mb 1" -state disabled
        $mb add command -label [msgcat::mc "Show Last Profiling Report"] -underline 5 -command "menus::show_last_profiling_report"
        $mb add separator
        $mb add command -label [msgcat::mc "Show Diagnostic Logfile"]    -underline 5 -command "logger::view_log"
        $mb add separator
        $mb add command -label [msgcat::mc "Restart TKE"]                -underline 0 -command "menus::restart_command"

        launcher::register [msgcat::mc "Tools Menu: Start profiling"] "menus::start_profiling_command $mb"
        launcher::register [msgcat::mc "Tools Menu: Stop profiling"] "menus::stop_profiling_command $mb 1"
        launcher::register [msgcat::mc "Tools Menu: Show last profiling report"] "menus::show_last_profiling_report"
        launcher::register [msgcat::mc "Tools Menu: Show diagnostic logfile"] "logger::view_log"
        launcher::register [msgcat::mc "Tools Menu: Restart TKE"] "menus::restart_command"

        # If profiling was enabled at startup, disable start and enable stop
        if {$::cl_profile} {
          $mb entryconfigure [msgcat::mc "Start Profiling"] -state disabled
          $mb entryconfigure [msgcat::mc "Stop Profiling"]  -state normal
        }

        set mb ".menubar.plugins"
        $mb insert 3 separator
        $mb insert 4 command -label [msgcat::mc "Create..."] -underline 0 -command "plugins::create_new_plugin"

        launcher::register [msgcat::mc "Plugins Menu: Create new plugin"] "plugins::create_new_plugin"

      } elseif {$last_devel_mode ne ""} {

        set mb    ".menubar.tools"
        set index [$mb index [msgcat::mc "Start Profiling"]]
        $mb delete [expr $index - 1] end
        launcher::unregister [msgcat::mc "Tools Menu: Start profiling"] * *
        launcher::unregister [msgcat::mc "Tools Menu: Stop profiling"] * *
        launcher::unregister [msgcat::mc "Tools Menu: Show last profiling report"] * *
        launcher::unregister [msgcat::mc "Tools Menu: Show diagnostic logfile"] * *
        launcher::unregister [msgcat::mc "Tools Menu: Restart TKE"] * *

        set mb ".menubar.plugins"
        $mb delete 3 4
        launcher::unregister [msgcat::mc "Plugins Menu: Create new plugin"] * *

      }

      # Store the development mode
      set last_devel_mode $devel_mode

    }

  }

  ######################################################################
  # Creates the main menu.
  proc create {} {

    set foreground [utils::get_default_foreground]
    set background [utils::get_default_background]

    set mb [menu .menubar -foreground $foreground -background $background -relief flat -tearoff false]

    # Add the file menu
    $mb add cascade -label [msgcat::mc "File"] -menu [menu $mb.file -tearoff false -postcommand "menus::file_posting $mb.file"]
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

    # Add the sessions menu
    $mb add cascade -label [msgcat::mc "Sessions"] -menu [menu $mb.sessions -tearoff false -postcommand "menus::sessions_posting $mb.sessions"]
    add_sessions $mb.sessions

    # Add the plugins menu
    $mb add cascade -label [msgcat::mc "Plugins"] -menu [menu $mb.plugins -tearoff false -postcommand "menus::plugins_posting $mb.plugins"]
    add_plugins $mb.plugins

    # Add the help menu
    $mb add cascade -label [msgcat::mc "Help"] -menu [menu $mb.help -tearoff false]
    add_help $mb.help

    # If we are running on Mac OS X, add the window menu with the windowlist package
    if {[tk windowingsystem] eq "aqua"} {

      # Add the window menu with the windowlist package
      windowlist::windowMenu $mb

      # Add the launcher command to show the about window
      launcher::register [msgcat::mc "Menus: About TKE"] gui::show_about

    }

    if {([tk windowingsystem] eq "aqua") || [preferences::get View/ShowMenubar]} {
      . configure -menu $mb
    }

    # Load and apply the menu bindings
    bindings::load

    # Handle the default development mode
    handle_development_mode

    # Register the menubar for theming purposes
    theme::register_widget $mb menus

  }

  ########################
  #  PRIVATE PROCEDURES  #
  ########################

  ######################################################################
  # Adds the file menu.
  proc add_file {mb} {

    $mb delete 0 end

    $mb add command -label [msgcat::mc "New File"] -underline 0 -command "menus::new_command"
    launcher::register [msgcat::mc "File Menu: New file"] menus::new_command

    $mb add command -label [msgcat::mc "Open File..."] -underline 0 -command "menus::open_command"
    launcher::register [msgcat::mc "File Menu: Open file"] menus::open_command

    $mb add command -label [msgcat::mc "Open Directory..."] -underline 5 -command "menus::open_dir_command"
    launcher::register [msgcat::mc "File Menu: Open directory"] menus::open_dir_command

    $mb add cascade -label [msgcat::mc "Open Recent"] -menu [menu $mb.recent -tearoff false -postcommand "menus::file_recent_posting $mb.recent"]
    launcher::register [msgcat::mc "File Menu: Open Recent"] menus::launcher

    $mb add cascade -label [msgcat::mc "Open Favorite"] -menu [menu $mb.favorites -tearoff false -postcommand "menus::file_favorites_posting $mb.favorites"]
    launcher::register [msgcat::mc "File Menu: Open Favorite"] favorites::launcher

    $mb add separator

    $mb add command -label [msgcat::mc "Show File Difference"] -underline 3 -command "menus::show_file_diff"
    launcher::register [msgcat::mc "File Menu: Show file difference"] menus::show_file_diff

    $mb add separator

    $mb add command -label [msgcat::mc "Save"] -underline 0 -command "menus::save_command"
    launcher::register [msgcat::mc "File Menu: Save file"] menus::save_command

    $mb add command -label [msgcat::mc "Save As..."] -underline 5 -command "menus::save_as_command"
    launcher::register [msgcat::mc "File Menu: Save file as"] menus::save_as_command

    $mb add command -label [msgcat::mc "Save All"] -underline 6 -command "gui::save_all"
    launcher::register [msgcat::mc "File Menu: Save all files"] gui::save_all

    $mb add separator

    $mb add command -label [msgcat::mc "Lock"] -underline 0 -command "menus::lock_command $mb"
    launcher::register [msgcat::mc "File Menu: Lock file"] "menus::lock_command $mb"
    launcher::register [msgcat::mc "File Menu: Unlock file"] "menus::unlock_command $mb"

    $mb add command -label [msgcat::mc "Favorite"] -underline 0 -command "menus::favorite_command $mb"
    launcher::register [msgcat::mc "File Menu: Favorite file"] "menus::favorite_command $mb"
    launcher::register [msgcat::mc "File Menu: Unfavorite file"] "menus::unfavorite_command $mb"

    $mb add separator

    $mb add command -label [msgcat::mc "Close"] -underline 0 -command "menus::close_command"
    launcher::register [msgcat::mc "File Menu: Close current tab"] menus::close_command

    $mb add command -label [msgcat::mc "Close All"] -underline 6 -command "menus::close_all_command"
    launcher::register [msgcat::mc "File Menu: Close all tabs"] menus::close_all_command

    # Only add the quit menu to File if we are not running in aqua
    if {[tk windowingsystem] ne "aqua"} {
      $mb add separator
      $mb add command -label [msgcat::mc "Quit"] -underline 0 -command "menus::exit_command"
    }
    launcher::register [msgcat::mc "File Menu: Quit application"] menus::exit_command

  }

  ######################################################################
  # Called prior to the file menu posting.
  proc file_posting {mb} {

    # Get the current file index (if one exists)
    if {[set file_index [gui::current_file]] != -1} {

      # Get the current filename
      set fname [gui::get_file_info $file_index fname]

      # Get the current readonly status
      set readonly [gui::get_file_info $file_index readonly]

      # Get the current file lock status
      set file_lock [expr $readonly || [gui::get_file_info $file_index lock]]

      # Get the current difference mode
      set diff_mode [gui::get_file_info $file_index diff]

      # Get the current favorite status
      set favorite [favorites::is_favorite $fname]

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
      if {$favorite} {
        if {![catch "$mb index Favorite" index]} {
          $mb entryconfigure $index -label [msgcat::mc "Unfavorite"] -command "menus::unfavorite_command $mb"
        }
        $mb entryconfigure [msgcat::mc "Unfavorite"] -state [expr {(($fname ne "") && !$diff_mode) ? "normal" : "disabled"}]
      } elseif {![catch "$mb index Unfavorite" index]} {
        $mb entryconfigure $index -label [msgcat::mc "Favorite"] -state normal -command "menus::favorite_command $mb"
      }

      # Make sure that the file-specific items are enabled
      $mb entryconfigure [msgcat::mc "Show File Difference"] -state [expr {($fname ne "") ? "normal" : "disabled"}]
      $mb entryconfigure [msgcat::mc "Save"]                 -state normal
      $mb entryconfigure [msgcat::mc "Save As..."]           -state normal
      $mb entryconfigure [msgcat::mc "Save All"]             -state normal
      $mb entryconfigure [msgcat::mc "Close"]                -state normal
      $mb entryconfigure [msgcat::mc "Close All"]            -state normal

    } else {

      # Disable file menu items associated with current tab (since one doesn't currently exist)
      $mb entryconfigure [msgcat::mc "Show File Difference"] -state disabled
      $mb entryconfigure [msgcat::mc "Save"]                 -state disabled
      $mb entryconfigure [msgcat::mc "Save As..."]           -state disabled
      $mb entryconfigure [msgcat::mc "Save All"]             -state disabled
      $mb entryconfigure [msgcat::mc "Lock"]                 -state disabled
      $mb entryconfigure [msgcat::mc "Favorite"]             -state disabled
      $mb entryconfigure [msgcat::mc "Close"]                -state disabled
      $mb entryconfigure [msgcat::mc "Close All"]            -state disabled

    }

    # Configure the Open Recent menu
    if {([preferences::get View/ShowRecentlyOpened] == 0) || (([llength [gui::get_last_opened]] == 0) && ([llength [sidebar::get_last_opened]] == 0))} {
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

    # Populate the menu with the directories
    if {[llength [set sdirs [sidebar::get_last_opened]]] > 0} {
      foreach sdir [lrange $sdirs 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
        $mb add command -label $sdir -command [list sidebar::add_directory $sdir]
      }
      $mb add separator
    }

    # Populate the menu with the filenames
    if {[llength [set fnames [gui::get_last_opened]]] > 0} {
      foreach fname [lrange $fnames 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
        $mb add command -label $fname -command [list gui::add_file end $fname]
      }
      $mb add separator
    }

    # Add "Clear All" menu option
    $mb add command -label [msgcat::mc "Clear All"] -command "menus::clear_last_opened"

  }

  ######################################################################
  # Clears the last opened files and directories.
  proc clear_last_opened {} {

    sidebar::clear_last_opened
    gui::clear_last_opened

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

    gui::add_new_file end -sidebar 1

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
  # Displays the difference of the current file.
  proc show_file_diff {} {

    # Get the current filename
    set fname [gui::current_filename]

    # Display the current file as a difference
    gui::add_file end $fname -diff 1 -other [preferences::get View/ShowDifferenceInOtherPane]

  }

  ######################################################################
  # Saves the current tab file.
  proc save_command {} {

    gui::save_current {} 1 ""

  }

  ######################################################################
  # Saves the current tab file as a new filename.
  proc save_as_command {} {

    # Get the directory of the current file
    set dirname [file dirname [gui::current_filename]]

    # Get some of the save options
    if {[set sfile [gui::prompt_for_save {}]] ne ""} {
      gui::save_current {} 1 $sfile
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

    gui::close_current {} 1

  }

  ######################################################################
  # Closes all opened tabs.
  proc close_all_command {} {

    gui::close_all 1

  }

  ######################################################################
  # Cleans up the application to prepare it for being exited.
  proc exit_cleanup {} {

    # Close the themer if it is open
    themer::close_window

    # Save the session information if we are not told to exit on close
    sessions::save "last"

    # Close all of the tabs
    gui::close_all 1 1

    # Save the clipboard history
    cliphist::save

    # Handle on_quit plugins
    plugins::handle_on_quit

    # Turn off profiling (if it was turned on)
    if {[::tke_development]} {
      stop_profiling_command .menubar.tools 0
    }

    # Stop the logger
    logger::on_exit

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
    launcher::register [msgcat::mc "Edit Menu: Undo"] "gui::undo {}"

    $mb add command -label [msgcat::mc "Redo"] -underline 0 -command "gui::redo {}"
    launcher::register [msgcat::mc "Edit Menu: Redo"] "gui::redo {}"

    $mb add separator

    $mb add command -label [msgcat::mc "Cut"] -underline 0 -command "gui::cut {}"
    launcher::register [msgcat::mc "Edit Menu: Cut text"] "gui::cut {}"

    $mb add command -label [msgcat::mc "Copy"] -underline 1 -command "gui::copy {}"
    launcher::register [msgcat::mc "Edit Menu: Copy text"] "gui::copy {}"

    $mb add command -label [msgcat::mc "Paste"] -underline 0 -command "gui::paste {}"
    launcher::register [msgcat::mc "Edit Menu: Paste text from clipboard"] "gui::paste {}"

    $mb add command -label [msgcat::mc "Paste and Format"] -underline 10 -command "gui::paste_and_format {}"
    launcher::register [msgcat::mc "Edit Menu: Paste and format text from clipboard"] "gui::paste_and_format {}"

    $mb add command -label [msgcat::mc "Select All"] -underline 7 -command "gui::select_all {}"
    launcher::register [msgcat::mc "Edit Menu: Select all text"] "gui::select_all {}"

    $mb add separator

    $mb add cascade -label [msgcat::mc "Indent Mode"] -underline 0 -menu [menu $mb.indentPopup -tearoff 0 -postcommand "indent::populate_indent_menu $mb.indentPopup"]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Insert Text"] -menu [menu $mb.insertPopup -tearoff 0 -postcommand "menus::edit_insert_posting $mb.insertPopup"]
    $mb add cascade -label [msgcat::mc "Format Text"] -menu [menu $mb.formatPopup -tearoff 0 -postcommand "menus::edit_format_posting $mb.formatPopup"]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Preferences"]   -menu [menu $mb.prefPopup -tearoff 0 -postcommand "menus::edit_preferences_posting $mb.prefPopup"]
    $mb add cascade -label [msgcat::mc "Menu Bindings"] -menu [menu $mb.bindPopup -tearoff 0]
    $mb add cascade -label [msgcat::mc "Snippets"]      -menu [menu $mb.snipPopup -tearoff 0 -postcommand "menus::edit_snippets_posting $mb.snipPopup"]

    # Create indentation menu
    $mb.indentPopup add radiobutton -label [msgcat::mc "Indent Off"] -variable menus::indent_mode -value "OFF" -command "gui::set_current_indent_mode {} OFF"
    launcher::register [msgcat::mc "Edit Menu: Set indent mode to OFF"] "gui::set_current_indent_mode {} OFF"

    $mb.indentPopup add radiobutton -label [msgcat::mc "Auto-Indent"] -variable menus::indent_mode -value "IND" -command "gui::set_current_indent_mode {} IND"
    launcher::register [msgcat::mc "Edit Menu: Set indent mode to IND"] "gui::set_current_indent_mode {} IND"

    $mb.indentPopup add radiobutton -label [msgcat::mc "Smart Indent"] -variable menus::indent_mode -value "IND+" -command "gui::set_current_indent_mode {} IND+"
    launcher::register [msgcat::mc "Edit Menu: Set indent mode to IND+"] "gui::set_current_indent_mode {} IND+"

    # Create insertion menu
    $mb.insertPopup add command -label [msgcat::mc "From Clipboard"] -command "cliphist::show_cliphist"
    launcher::register [msgcat::mc "Edit Menu: Insert from clipboard"] "cliphist::show_cliphist"

    $mb.insertPopup add command -label [msgcat::mc "Snippet"] -command "snippets::show_snippets"
    launcher::register [msgcat::mc "Edit Menu: Insert snippet"] "snippets::show_snippets"

    # Create formatting menu
    $mb.formatPopup add command -label [msgcat::mc "Selected"] -command "gui::format {} selected"
    launcher::register [msgcat::mc "Edit Menu: Format selected text"] "gui::format {} selected"

    $mb.formatPopup add command -label [msgcat::mc "All"]      -command "gui::format {} all"
    launcher::register [msgcat::mc "Edit Menu: Format all text"] "gui::format {} selected"

    # Create preferences menu
    $mb.prefPopup add command -label [msgcat::mc "Edit User - Global"] -command "menus::edit_user_global"
    launcher::register [msgcat::mc "Edit Menu: Edit user global preferences"] "menus::edit_user_global"

    $mb.prefPopup add command -label [msgcat::mc "Edit User - Language"] -command "menus::edit_user_language"
    launcher::register [msgcat::mc "Edit Menu: Edit user current language preferences"] "menus::edit_user_language"

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [msgcat::mc "Edit Session - Global"] -command "menus::edit_session_global"
    launcher::register [msgcat::mc "Edit Menu: Edit session global preferences"] "menus::edit_session_global"

    $mb.prefPopup add command -label [msgcat::mc "Edit Session - Language"] -command "menus::edit_session_language"
    launcher::register [msgcat::mc "Edit Menu: Edit session current language preferences"] "menus::edit_session_language"

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [msgcat::mc "View Base"] -command "preferences::view_global"
    launcher::register [msgcat::mc "Edit Menu: View base preferences file"] "preferences::view_global"

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [msgcat::mc "Reset User to Base"] -command "preferences::copy_default"
    launcher::register [msgcat::mc "Edit Menu: Set user preferences to global preferences"] "preferences::copy_default"

    # Create menu bindings menu
    $mb.bindPopup add command -label [msgcat::mc "Edit User"] -command "bindings::edit_user"
    launcher::register [msgcat::mc "Edit Menu: Edit user menu bindings"] "bindings::edit_user"

    $mb.bindPopup add separator

    $mb.bindPopup add command -label [msgcat::mc "View Global"] -command "bindings::view_global"
    launcher::register [msgcat::mc "Edit Menu: View global menu bindings"] "bindings::view_global"

    $mb.bindPopup add separator

    $mb.bindPopup add command -label [msgcat::mc "Set User to Global"] -command "bindings::copy_default"
    launcher::register [msgcat::mc "Edit Menu: Set user bindings to global bindings"] "bindings::copy_default"

    # Create snippets menu
    $mb.snipPopup add command -label [msgcat::mc "Edit User"] -command "snippets::add_new_snippet {} user"
    launcher::register [msgcat::mc "Edit Menu Edit user snippets"] "snippets::add_new_snippet {} user"

    $mb.snipPopup add command -label [msgcat::mc "Edit Language"] -command "snippets::add_new_snippet {} lang"
    launcher::register [msgcat::mc "Edit Menu: Edit language snippets"] "snippets::add_new_snippet {} lang"

    $mb.snipPopup add separator

    $mb.snipPopup add command -label [msgcat::mc "Reload"] -command "snippets::reload_snippets {}"
    launcher::register [msgcat::mc "Edit Menu: Reload snippets"] "snippets::reload_snippets {}"

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
      $mb entryconfigure [msgcat::mc "Indent Mode"]      -state disabled
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
      $mb entryconfigure [msgcat::mc "Cut"]  -state normal
      $mb entryconfigure [msgcat::mc "Copy"] -state normal
      if {[gui::pastable {}]} {
        $mb entryconfigure [msgcat::mc "Paste"]            -state normal
        $mb entryconfigure [msgcat::mc "Paste and Format"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Paste"]            -state disabled
        $mb entryconfigure [msgcat::mc "Paste and Format"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Select All"]  -state normal
      $mb entryconfigure [msgcat::mc "Indent Mode"] -state normal
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
      $mb entryconfigure [msgcat::mc "Edit User - Language"]    -state disabled
      $mb entryconfigure [msgcat::mc "Edit Session - Language"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Edit User - Language"] -state normal
      if {[sessions::current] eq ""} {
        $mb entryconfigure [msgcat::mc "Edit Session - Global"]   -state disabled
        $mb entryconfigure [msgcat::mc "Edit Session - Language"] -state disabled
      } else {
        $mb entryconfigure [msgcat::mc "Edit Session - Global"]   -state normal
        $mb entryconfigure [msgcat::mc "Edit Session - Language"] -state normal
      }
    }

  }

  ######################################################################
  # Called just prior to posting the edit/menu bindings menu option.
  # Sets the menu option states to match the current UI state.
  proc edit_snippets_posting {mb} {

    $mb entryconfigure [msgcat::mc "Edit User"] -state normal

    if {[gui::current_txt {}] eq ""} {
      $mb entryconfigure [msgcat::mc "Edit Language"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Edit Language"] -state normal
    }

  }

  ######################################################################
  # Edits the user global preference settings.
  proc edit_user_global {} {

    preferences::edit_global

  }

  ######################################################################
  # Edits the user current language preference settings.
  proc edit_user_language {} {

    preferences::edit_language

  }

  ######################################################################
  # Edits the session global preference settings.
  proc edit_session_global {} {

    preferences::edit_global [sessions::current]

  }

  ######################################################################
  # Edits the session current language preference settings.
  proc edit_session_language {} {

    preferences::edit_language [sessions::current]

  }

  ######################################################################
  # Add the find menu.
  proc add_find {mb} {

    # Add find menu commands
    $mb add command -label [msgcat::mc "Find"] -underline 0 -command "gui::search {}"
    launcher::register [msgcat::mc "Find Menu: Find"] "gui::search {}"

    $mb add command -label [msgcat::mc "Find and Replace"] -underline 9 -command "gui::search_and_replace"
    launcher::register [msgcat::mc "Find Menu: Find and Replace"] gui::search_and_replace

    $mb add separator

    $mb add command -label [msgcat::mc "Select Next Occurrence"] -underline 7 -command "menus::find_next_command 0"
    launcher::register [msgcat::mc "Find Menu: Find next occurrence"] "menus::find_next_command 0"

    $mb add command -label [msgcat::mc "Select Previous Occurrence"] -underline 7 -command "menus::find_prev_command 0"
    launcher::register [msgcat::mc "Find Menu: Find previous occurrence"] "menus::find_prev_command 0"

    $mb add command -label [msgcat::mc "Append Next Occurrence"] -underline 1 -command "menus::find_next_command 1"
    launcher::register [msgcat::mc "Find Menu: Append next occurrence"] "menus::find_next_command 1"

    $mb add command -label [msgcat::mc "Select All Occurrences"] -underline 7 -command "menus::find_all_command"
    launcher::register [msgcat::mc "Find Menu: Select all occurrences"] "menus::find_all_command"

    $mb add separator

    $mb add command -label [msgcat::mc "Jump Backward"] -underline 5 -command "gui::jump_to_cursor {} -1 1"
    launcher::register [msgcat::mc "Find Menu: Jump backward"] "gui::jump_to_cursor {} -1 1"

    $mb add command -label [msgcat::mc "Jump Forward"] -underline 5 -command "gui::jump_to_cursor {} 1 1"
    launcher::register [msgcat::mc "Find Menu: Jump forward"] "gui::jump_to_cursor {} 1 1"

    $mb add separator

    $mb add command -label [msgcat::mc "Next Difference"] -underline 0 -command "gui::jump_to_difference {} 1 1"
    launcher::register [msgcat::mc "Find Menu: Goto next difference"] "gui::jump_to_difference {} 1 1"

    $mb add command -label [msgcat::mc "Previous Difference"] -underline 0 -command "gui::jump_to_difference {} -1 1"
    launcher::register [msgcat::mc "Find Menu: Goto previous difference"] "gui::jump_to_difference {} -1 1"

    $mb add command -label [msgcat::mc "Show Selected Line Change"] -underline 19 -command "gui::show_difference_line_change {} 1"
    launcher::register [msgcat::mc "Find Menu: Show selected line change"] "gui::show_difference_line_change {} 1"

    $mb add separator

    $mb add cascade -label [msgcat::mc "Markers"] -underline 5 -menu [menu $mb.markerPopup -tearoff 0 -postcommand "menus::find_marker_posting $mb.markerPopup"]

    $mb add separator

    $mb add command -label [msgcat::mc "Find Matching Pair"] -underline 5 -command "gui::show_match_pair {}"
    launcher::register [msgcat::mc "Find Menu: Find matching character pair"] "gui::show_match_pair {}"

    $mb add separator

    $mb add command -label [msgcat::mc "Find In Files"] -underline 5 -command "search::fif_start"
    launcher::register [msgcat::mc "Find Menu: Find in files"] "search::fif_start"

    # Add marker popup launchers
    launcher::register [msgcat::mc "Find Menu: Create marker at current line"] "gui::create_current_marker {}"
    launcher::register [msgcat::mc "Find Menu: Remove marker from current line"] "gui::remove_current_marker {}"
    launcher::register [msgcat::mc "Find Menu: Remove all markers"] "gui::remove_all_markers {}"

  }

  ######################################################################
  # Called just prior to posting the find menu.  Sets the state of the menu
  # items to match the current UI state.
  proc find_posting {mb} {

    if {[set txt [gui::current_txt {}]] eq ""} {
      $mb entryconfigure [msgcat::mc "Find"]                       -state disabled
      $mb entryconfigure [msgcat::mc "Find and Replace"]           -state disabled
      $mb entryconfigure [msgcat::mc "Select Next Occurrence"]     -state disabled
      $mb entryconfigure [msgcat::mc "Select Previous Occurrence"] -state disabled
      $mb entryconfigure [msgcat::mc "Append Next Occurrence"]     -state disabled
      $mb entryconfigure [msgcat::mc "Select All Occurrences"]     -state disabled
      $mb entryconfigure [msgcat::mc "Jump Backward"]              -state disabled
      $mb entryconfigure [msgcat::mc "Jump Forward"]               -state disabled
      $mb entryconfigure [msgcat::mc "Next Difference"]            -state disabled
      $mb entryconfigure [msgcat::mc "Previous Difference"]        -state disabled
      $mb entryconfigure [msgcat::mc "Show Selected Line Change"]  -state disabled
      $mb entryconfigure [msgcat::mc "Markers"]                    -state disabled
      $mb entryconfigure [msgcat::mc "Find Matching Pair"]         -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Find"]                       -state normal
      $mb entryconfigure [msgcat::mc "Find and Replace"]           -state normal
      $mb entryconfigure [msgcat::mc "Select Next Occurrence"]     -state normal
      $mb entryconfigure [msgcat::mc "Select Previous Occurrence"] -state normal
      $mb entryconfigure [msgcat::mc "Append Next Occurrence"]     -state normal
      $mb entryconfigure [msgcat::mc "Select All Occurrences"]     -state normal
      if {[gui::jump_to_cursor {} -1 0]} {
        $mb entryconfigure [msgcat::mc "Jump Backward"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Jump Backward"] -state disabled
      }
      if {[gui::jump_to_cursor {} 1 0]} {
        $mb entryconfigure [msgcat::mc "Jump Forward"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Jump Forward"] -state disabled
      }
      if {[gui::jump_to_difference {} 1 0]} {
        $mb entryconfigure [msgcat::mc "Next Difference"]           -state normal
        $mb entryconfigure [msgcat::mc "Previous Difference"]       -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Next Difference"]           -state disabled
        $mb entryconfigure [msgcat::mc "Previous Difference"]       -state disabled
      }
      if {[gui::show_difference_line_change {} 0]} {
        $mb entryconfigure [msgcat::mc "Show Selected Line Change"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Show Selected Line Change"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Find Matching Pair"] -state normal
      $mb entryconfigure [msgcat::mc "Markers"] -state normal
    }

  }

  ######################################################################
  # Called when the marker menu is opened.
  proc find_marker_posting {mb} {

    # Clear the menu
    $mb delete 0 end

    # Populate the markerPopup menu
    $mb add command -label [msgcat::mc "Create at Current Line"] -underline 0 -command "gui::create_current_marker {}"
    $mb add separator
    $mb add command -label [msgcat::mc "Remove From Current Line"] -underline 0 -command "gui::remove_current_marker {}"
    $mb add command -label [msgcat::mc "Remove All Markers"] -underline 7 -command "gui::remove_all_markers {}"

    if {[llength [set markers [gui::get_marker_list {}]]] > 0} {
      $mb add separator
    }

    foreach {marker pos} $markers {
      $mb add command -label $marker -command "gui::jump_to {} $pos"
    }

  }

  ######################################################################
  # Finds the next occurrence of the find regular expression for the current
  # text widget.
  proc find_next_command {app} {

    search::find_next [gui::current_txt {}] $app

  }

  ######################################################################
  # Finds the previous occurrence of the find regular expression for the
  # current text widget.
  proc find_prev_command {app} {

    search::find_prev [gui::current_txt {}] $app

  }

  ######################################################################
  # Finds all occurrences of the find regular expression for the current
  # text widget and adds it to the selection.
  proc find_all_command {} {

    search::find_all [gui::current_txt {}]

  }

  ######################################################################
  # Adds the text menu commands.
  proc add_text {mb} {

    $mb add command -label [msgcat::mc "Toggle Comment"] -underline 0 -command "texttools::comment_toggle {}"
    launcher::register [msgcat::mc "Text Menu: Toggle comment"] "texttools::comment_toggle {}"

    $mb add command -label [msgcat::mc "Indent"] -underline 0 -command "texttools::indent {}"
    launcher::register [msgcat::mc "Text Menu: Indent selected text"] "texttools::indent {}"

    $mb add command -label [msgcat::mc "Unindent"] -underline 1 -command "texttools::unindent {}"
    launcher::register [msgcat::mc "Text Menu: Unindent selected text"] "texttools::unindent {}"

    $mb add separator

    $mb add command -label [msgcat::mc "Replace Line With Script"] -command "texttools::replace_line_with_script {}"
    launcher::register [msgcat::mc "Text Menu: Replace line with script"] "texttools::replace_line_with_script {}"

    $mb add separator

    $mb add command -label [msgcat::mc "Align Cursors"] -underline 0 -command "texttools::align {}"
    launcher::register [msgcat::mc "Text Menu: Align cursors"] "texttools::align {}"

    $mb add command -label [msgcat::mc "Insert Enumeration"] -underline 7 -command "texttools::insert_enumeration {}"
    launcher::register [msgcat::mc "Text Menu: Insert enumeration"] "texttools::insert_enumeration {}"

  }

  ######################################################################
  # Called prior to the text menu posting.
  proc text_posting {mb} {

    if {[set txt [gui::current_txt {}]] eq ""} {
      $mb entryconfigure [msgcat::mc "Toggle Comment"]           -state disabled
      $mb entryconfigure [msgcat::mc "Indent"]                   -state disabled
      $mb entryconfigure [msgcat::mc "Unindent"]                 -state disabled
      $mb entryconfigure [msgcat::mc "Replace Line With Script"] -state disabled
      $mb entryconfigure [msgcat::mc "Align Cursors"]            -state disabled
      $mb entryconfigure [msgcat::mc "Insert Enumeration"]       -state disabled
    } else {
      if {[lindex [syntax::get_comments [gui::current_txt {}]] 0] eq ""} {
        $mb entryconfigure [msgcat::mc "Toggle Comment"] -state disabled
      } else {
        $mb entryconfigure [msgcat::mc "Toggle Comment"] -state normal
      }
      $mb entryconfigure [msgcat::mc "Indent"]   -state normal
      $mb entryconfigure [msgcat::mc "Unindent"] -state normal
      if {[texttools::current_line_empty {}]} {
        $mb entryconfigure [msgcat::mc "Replace Line With Script"] -state disabled
      } else {
        $mb entryconfigure [msgcat::mc "Replace Line With Script"] -state normal
      }
      if {[multicursor::enabled $txt]} {
        $mb entryconfigure [msgcat::mc "Align Cursors"]      -state normal
        $mb entryconfigure [msgcat::mc "Insert Enumeration"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Align Cursors"]      -state disabled
        $mb entryconfigure [msgcat::mc "Insert Enumeration"] -state disabled
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
    launcher::register [msgcat::mc "View Menu: Show sidebar"] "menus::show_sidebar_view $mb"
    launcher::register [msgcat::mc "View Menu: Hide sidebar"] "menus::hide_sidebar_view $mb"

    if {![catch "console hide"]} {
      if {[preferences::get View/ShowConsole]} {
        $mb add command -label [msgcat::mc "Hide Console"] -underline 5 -command "menus::hide_console_view $mb"
      } else {
        $mb add command -label [msgcat::mc "Show Console"] -underline 5 -command "menus::show_console_view $mb"
      }
      launcher::register [msgcat::mc "View Menu: Show console"] "menus::show_console_view $mb"
      launcher::register [msgcat::mc "View Menu: Hide console"] "menus::hide_console_view $mb"
    }

    if {[preferences::get View/ShowTabBar]} {
      $mb add command -label [msgcat::mc "Hide Tab Bar"] -underline 5 -command "menus::hide_tab_view $mb"
    } else {
      $mb add command -label [msgcat::mc "Show Tab Bar"] -underline 5 -command "menus::show_tab_view $mb"
    }
    launcher::register [msgcat::mc "View Menu: Show tab bar"] "menus::show_tab_view $mb"
    launcher::register [msgcat::mc "View Menu: Hide tab bar"] "menus::hide_tab_view $mb"

    if {[preferences::get View/ShowStatusBar]} {
      $mb add command -label [msgcat::mc "Hide Status Bar"] -underline 12 -command "menus::hide_status_view $mb"
    } else {
      $mb add command -label [msgcat::mc "Show Status Bar"] -underline 12 -command "menus::show_status_view $mb"
    }
    launcher::register [msgcat::mc "View Menu: Show status bar"] "menus::show_status_view $mb"
    launcher::register [msgcat::mc "View Menu: Hide status bar"] "menus::hide_status_view $mb"

    $mb add separator

    if {[preferences::get View/ShowLineNumbers]} {
      $mb add command -label [msgcat::mc "Hide Line Numbers"] -underline 5 -command "menus::hide_line_numbers $mb"
    } else {
      $mb add command -label [msgcat::mc "Show Line Numbers"] -underline 5 -command "menus::show_line_numbers $mb"
    }
    launcher::register [msgcat::mc "View Menu: Show line numbers"] "menus::show_line_numbers $mb"
    launcher::register [msgcat::mc "View Menu: Hide line numbers"] "menus::hide_line_numbers $mb"

    $mb add command -label [msgcat::mc "Hide Meta Characters"] -underline 5 -command "menus::hide_meta_chars $mb"
    launcher::register [msgcat::mc "View Menu: Show meta characters"] "menus::show_meta_chars $mb"
    launcher::register [msgcat::mc "View Menu: Hide meta characters"] "menus::hide_meta_chars $mb"

    $mb add separator

    $mb add checkbutton -label [msgcat::mc "Split View"] -underline 6 -variable menus::show_split_pane -command "gui::toggle_split_pane {}"
    launcher::register [msgcat::mc "View Menu: Toggle split view mode"] "gui::toggle_split_pane {}"

    $mb add command -label [msgcat::mc "Move to Other Pane"] -underline 0 -command "gui::move_to_pane"
    launcher::register [msgcat::mc "View Menu: Move to other pane"] "gui::move_to_pane"

    $mb add command -label [msgcat::mc "Merge Panes"] -underline 3 -command "gui::merge_panes"
    launcher::register [msgcat::mc "View Menu: Merge panes"] "gui::merge_panes"

    $mb add separator

    $mb add cascade -label [msgcat::mc "Tabs"] -underline 0 -menu [menu $mb.tabPopup -tearoff 0 -postcommand "menus::view_tabs_posting $mb.tabPopup"]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Set Syntax"] -underline 9 -menu [menu $mb.syntaxMenu -tearoff 0 -postcommand "syntax::populate_syntax_menu $mb.syntaxMenu"]
    $mb add cascade -label [msgcat::mc "Set Theme"]  -underline 7 -menu [menu $mb.themeMenu  -tearoff 0 -postcommand "themes::populate_theme_menu $mb.themeMenu"]

    # Setup the tab popup menu
    $mb.tabPopup add command -label [msgcat::mc "Goto Next Tab"] -underline 5 -command "gui::next_tab"
    launcher::register [msgcat::mc "View Menu: Goto next tab"] "gui::next_tab"

    $mb.tabPopup add command -label [msgcat::mc "Goto Previous Tab"] -underline 5 -command "gui::previous_tab"
    launcher::register [msgcat::mc "View Menu: Goto previous tab"] "gui::previous_tab"

    $mb.tabPopup add command -label [msgcat::mc "Goto Last Tab"] -underline 5 -command "gui::last_tab"
    launcher::register [msgcat::mc "View Menu: Goto last tab"] "gui::last_tab"

    $mb.tabPopup add command -label [msgcat::mc "Goto Other Pane"] -underline 11 -command "gui::next_pane"
    launcher::register [msgcat::mc "View Menu: Goto other pane"] "gui::next_pane"

    $mb.tabPopup add separator

    $mb.tabPopup add command -label [msgcat::mc "Sort Tabs"] -underline 0 -command "gui::sort_tabs"
    launcher::register [msgcat::mc "View Menu: Sort tabs"] "gui::sort_tabs"

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

    if {[gui::panes] < 2} {
      $mb entryconfigure [msgcat::mc "Merge Panes"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Merge Panes"] -state normal
    }

    if {[gui::current_txt {}] eq ""} {
      catch { $mb entryconfigure [msgcat::mc "Show Line Numbers"]  -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Hide Line Numbers"]  -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Show Meta Characters"] -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Hide Meta Characters"] -state disabled }
      $mb entryconfigure [msgcat::mc "Split View"]         -state disabled
      $mb entryconfigure [msgcat::mc "Move to Other Pane"] -state disabled
      $mb entryconfigure [msgcat::mc "Set Syntax"]         -state disabled
    } else {
      catch { $mb entryconfigure [msgcat::mc "Show Line Numbers"]  -state normal }
      catch { $mb entryconfigure [msgcat::mc "Hide Line Numbers"]  -state normal }
      if {[syntax::contains_meta_chars [gui::current_txt {}]]} {
        catch { $mb entryconfigure [msgcat::mc "Show Meta Characters"] -state normal }
        catch { $mb entryconfigure [msgcat::mc "Hide Meta Characters"] -state normal }
      } else {
        catch { $mb entryconfigure [msgcat::mc "Show Meta Characters"] -state disabled }
        catch { $mb entryconfigure [msgcat::mc "Hide Meta Characters"] -state disabled }
      }
      $mb entryconfigure [msgcat::mc "Split View"] -state normal
      if {[gui::movable_to_other_pane]} {
        $mb entryconfigure [msgcat::mc "Move to Other Pane"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Move to Other Pane"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Set Syntax"] -state normal
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
  # Shows the line numbers in the editor.
  proc show_line_numbers {mb} {

    # Convert the menu command into the hide line numbers command
    if {![catch {$mb entryconfigure [msgcat::mc "Show Line Numbers"] -label [msgcat::mc "Hide Line Numbers"] -command "menus::hide_line_numbers $mb"}]} {
      gui::set_line_number_view {} 1
    }

  }

  ######################################################################
  # Hides the line numbers in the editor.
  proc hide_line_numbers {mb} {

    # Convert the menu command into the hide line numbers command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Line Numbers"] -label [msgcat::mc "Show Line Numbers"] -command "menus::show_line_numbers $mb"}]} {
      gui::set_line_number_view {} 0
    }

  }

  ######################################################################
  # Shows the meta characters in the current edit window.
  proc show_meta_chars {mb} {

    # Convert the menu command into the hide line numbers command
    if {![catch {$mb entryconfigure [msgcat::mc "Show Meta Characters"] -label [msgcat::mc "Hide Meta Characters"] -command "menus::hide_meta_chars $mb"}]} {
      syntax::set_meta_visibility [gui::current_txt {}] 1
    }

  }

  ######################################################################
  # Hides the meta characters in the current edit window.
  proc hide_meta_chars {mb} {

    # Convert the menu command into the hide line numbers command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Meta Characters"] -label [msgcat::mc "Show Meta Characters"] -command "menus::show_meta_chars $mb"}]} {
      syntax::set_meta_visibility [gui::current_txt {}] 0
    }

  }

  ######################################################################
  # Adds the tools menu commands.
  proc add_tools {mb} {

    # Add tools menu commands
    $mb add command -label [msgcat::mc "Launcher"] -underline 0 -command "launcher::launch"

    $mb add command -label [msgcat::mc "Theme Editor"] -underline 0 -command "menus::theme_edit_command"
    launcher::register [msgcat::mc "Tools Menu: Run theme editor"] "menus::theme_edit_command"

    $mb add separator

    $mb add checkbutton -label [msgcat::mc "Vim Mode"] -underline 0 -variable preferences::prefs(Tools/VimMode) -command "vim::set_vim_mode_all"
    launcher::register [msgcat::mc "Tools Menu: Enable Vim mode"]  "set preferences::prefs(Tools/VimMode) 1; vim::set_vim_mode_all"
    launcher::register [msgcat::mc "Tools Menu: Disable Vim mode"] "set preferences::prefs(Tools/VimMode) 0; vim::set_vim_mode_all"

  }

  ######################################################################
  # Called prior to the tools menu posting.
  proc tools_posting {mb} {

    variable profile_report

    if {[::tke_development]} {
      catch {
        if {[file exists $profile_report]} {
          $mb entryconfigure [msgcat::mc "Show Last Profiling Report"] -state normal
        } else {
          $mb entryconfigure [msgcat::mc "Show Last Profiling Report"] -state disabled
        }
      }
    }

  }

  ######################################################################
  # Creates a new theme and reloads the themes.
  proc theme_edit_command {} {

    # Edit the current theme
    themer::edit_current_theme

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
      $mb entryconfigure [msgcat::mc "Stop Profiling"]  -state disabled
      $mb entryconfigure [msgcat::mc "Start Profiling"] -state normal

    }

  }

  ######################################################################
  # Displays the last profiling report.
  proc show_last_profiling_report {} {

    variable profile_report

    # If the profiling report exists, display it
    if {[file exists $profile_report]} {
      gui::add_file end $profile_report -lock 1 -sidebar 0
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

    # Perform exit cleanup
    exit_cleanup

    # Execute the restart command
    if {[file tail [info nameofexecutable]] eq "tke.exe"} {
      exec [info nameofexecutable] &
    } else {
      exec [info nameofexecutable] [file normalize $::argv0] &
    }

    exit

  }

  ######################################################################
  # Adds the sessions menu options to the sessions menu.
  proc add_sessions {mb} {

    # Add sessions menu commands
    $mb add cascade -label [msgcat::mc "Open"] -menu [menu $mb.open -tearoff false]
    launcher::register [msgcat::mc "Sessions Menu: Open session"] "menus::sessions_open_launcher"

    $mb add cascade -label [msgcat::mc "Switch To"] -menu [menu $mb.switch -tearoff false]
    launcher::register [msgcat::mc "Sessions Menu: Switch to session"] "menus::sessions_switch_launcher"

    $mb add separator

    $mb add command -label [msgcat::mc "Close Current"] -underline 0 -command "menus::sessions_close_current"
    launcher::register [msgcat::mc "Sessions Menu: Close current session"] "menus::sessions_close_current"

    $mb add separator

    $mb add command -label [msgcat::mc "Save Current"] -underline 0 -command "menus::sessions_save_current"
    launcher::register [msgcat::mc "Sessions Menu: Save current session"] "menus::sessions_save_current"

    $mb add command -label [msgcat::mc "Save As"] -underline 5 -command "menus::sessions_save_as"
    launcher::register [msgcat::mc "Sessions Menu: Save sessions as"] "menus::sessions_save_as"

    $mb add separator

    $mb add cascade -label [msgcat::mc "Delete"] -menu [menu $mb.delete -tearoff false]
    launcher::register [msgcat::mc "Sessions Menu: Delete session"] "menus::sessions_delete_launcher"

  }

  ######################################################################
  # Called when the sessions menu is posted.
  proc sessions_posting {mb} {

    # Get the list of sessions names
    set names [sessions::get_names]

    # Update the open, switch to, and delete menus
    $mb.open   delete 0 end
    $mb.switch delete 0 end
    $mb.delete delete 0 end

    foreach name $names {
      $mb.open   add command -label $name -command [list sessions::load "full" $name 1]
      $mb.switch add command -label $name -command [list sessions::load "full" $name 0]
      $mb.delete add command -label $name -command [list sessions::delete $name]
    }

    # If the current session is not set, disable the menu item
    if {[sessions::current] eq ""} {
      $mb entryconfigure [msgcat::mc "Close Current"] -state disabled
      $mb entryconfigure [msgcat::mc "Save Current"]  -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Close Current"] -state normal
      $mb entryconfigure [msgcat::mc "Save Current"]  -state normal
    }

    # If there are no names, disable the Open, Switch to and Delete menu commands
    if {[llength $names] == 0} {
      $mb entryconfigure [msgcat::mc "Open"]      -state disabled
      $mb entryconfigure [msgcat::mc "Switch To"] -state disabled
      $mb entryconfigure [msgcat::mc "Delete"]    -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Open"]      -state normal
      $mb entryconfigure [msgcat::mc "Switch To"] -state normal
      $mb entryconfigure [msgcat::mc "Delete"]    -state normal
    }

  }

  ######################################################################
  # Displays the available sessions that can be opened in the launcher.
  proc sessions_open_launcher {} {

    set i 0
    foreach name [sessions::get_names] {
      launcher::register_temp "`SESSION:$name" [list sessions::load "full" $name 1] $name $i
      incr i
    }

    # Display the launcher in SESSION: mode
    launcher::launch "`SESSION:"

  }

  ######################################################################
  # Displays the available sessions that can be switched to in the launcher.
  proc sessions_switch_launcher {} {

    set i 0
    foreach name [sessions::get_names] {
      launcher::register_temp "`SESSION:$name" [list sessions::load "full" $name 0] $name $i
      incr i
    }

    # Display the launcher in SESSION: mode
    launcher::launch "`SESSION:"

  }

  ######################################################################
  # Closes the current session by switching to the last session.
  proc sessions_close_current {} {

    sessions::load "last" "" 0

  }

  ######################################################################
  # Saves the current session as the same name.
  proc sessions_save_current {} {

    sessions::save "full" [sessions::current]

  }

  ######################################################################
  # Saves the current session as.
  proc sessions_save_as {} {

    sessions::save "full"

  }

  ######################################################################
  # Shows launcher with a list of available sessions to delete.
  proc sessions_delete_launcher {} {

    set i 0
    foreach name [sessions::get_names] {
      launcher::register_temp "`SESSION:$name" [list sessions::delete $name] $name $i
      incr i
    }

    # Display the launcher in SESSION: mode
    launcher::launch "`SESSION:"

  }

  ######################################################################
  # Add the plugins menu commands.
  proc add_plugins {mb} {

    # Add plugins menu commands
    $mb add command -label [msgcat::mc "Install..."] -underline 0 -command "plugins::install"
    launcher::register [msgcat::mc "Plugins Menu: Install plugin"] "plugins::install"

    $mb add command -label [msgcat::mc "Uninstall..."] -underline 0 -command "plugins::uninstall"
    launcher::register [msgcat::mc "Plugins Menu: Uninstall plugin"] "plugins::uninstall"

    $mb add command -label [msgcat::mc "Reload"] -underline 0 -command "plugins::reload"
    launcher::register [msgcat::mc "Plugins Menu: Reload all plugins"] "plugins::reload"

    # Allow the plugin architecture to add menu items
    plugins::handle_plugin_menu $mb

  }

  ######################################################################
  # Called when the plugins menu needs to be posted.
  proc plugins_posting {mb} {

    # TBD

  }

  ######################################################################
  # Adds the help menu commands.
  proc add_help {mb} {

    $mb add command -label [msgcat::mc "User Guide"] -underline 0 -command "menus::help_user_guide"
    launcher::register [msgcat::mc "Help Menu: View user guide"] "menus::help_user_guide"

    if {![string match *Win* $::tcl_platform(os)]} {
      $mb add separator
      $mb add command -label [msgcat::mc "Check for Update"] -underline 0 -command "menus::check_for_update"
      launcher::register [msgcat::mc "Help Menu: Check for update"] "menus::check_for_update"
    }

    $mb add separator

    $mb add command -label [msgcat::mc "Send Feedback"] -underline 5 -command "menus::help_feedback_command"
    launcher::register [msgcat::mc "Help Menu: Send feedback"] "menus::help_feedback_command"

    $mb add command -label [msgcat::mc "Send Bug Report"] -underline 5 -command "menus::help_submit_report"
    launcher::register [msgcat::mc "Help Menu: Send bug report"] "menus::help_submit_report"

    if {[tk windowingsystem] ne "aqua"} {
      $mb add separator
      $mb add command -label [msgcat::mc "About TKE"] -underline 0 -command "gui::show_about"
      launcher::register [msgcat::mc "Help Menu: About TKE"] "gui::show_about"
    }

  }

  ######################################################################
  # Displays the User Guide.  First, attempts to show the epub version.
  # If that fails, display the pdf version.
  proc help_user_guide {} {

    if {[preferences::get Help/UserGuideFormat] eq "pdf"} {
      utils::open_file_externally "[file join $::tke_dir doc UserGuide.pdf]"
    } else {
      utils::open_file_externally "[file join $::tke_dir doc UserGuide.epub]"
    }

  }

  ######################################################################
  # Checks for an application update.
  proc check_for_update {} {

    if {[preferences::get General/UpdateReleaseType] eq "devel"} {
      specl::check_for_update 0 [expr $specl::RTYPE_STABLE | $specl::RTYPE_DEVEL] {} menus::exit_cleanup
    } else {
      specl::check_for_update 0 $specl::RTYPE_STABLE {} menus::exit_cleanup
    }

  }

  ######################################################################
  # Generates an e-mail compose window to provide feedback.
  proc help_feedback_command {} {

    utils::open_file_externally "mailto:phase1geo@gmail.com?subject=Feedback for TKE" 1

  }

  ######################################################################
  # Generates an e-mail compose window to provide a bug report.  Appends
  # the diagnostic logfile information to the bug report.
  proc help_submit_report {} {

    # Retrieve the contents of the diagnostic logfile
    set log_content [logger::get_log]

    # Create the message body
    set body "Add bug description:\n\n\n\n\n$log_content"

    # Send an e-mail with the logfile contents
    utils::open_file_externally "mailto:phase1geo@gmail.com?subject=Bug Report for TKE&body=$body"

  }

  ######################################################################
  # Displays the launcher with recently opened files.
  proc launcher {} {

    # Add recent directories to launcher
    foreach sdir [lrange [sidebar::get_last_opened] 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
      launcher::register_temp "`RECENT:$sdir" [list sidebar::add_directory $sdir] $sdir
    }

    # Add recent files to launcher
    foreach fname [lrange [gui::get_last_opened] 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
      launcher::register_temp "`RECENT:$fname" [list gui::add_file end $fname] $fname
    }

    # Display the launcher in RECENT: mode
    launcher::launch "`RECENT:"

    # Unregister the recents
    foreach sdir [lrange [sidebar::get_last_opened] 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
      launcher::unregister "`RECENT:$sdir"
    }
    foreach fname [lrange [gui::get_last_opened] 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
      launcher::unregister "`RECENT:$fname"
    }

  }

}

