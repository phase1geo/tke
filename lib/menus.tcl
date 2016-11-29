# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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
  variable line_numbering  "absolute"
  variable code_folding    0
  variable sync_panes      0

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
  # Set the pane sync indicator to the given value (0 or 1).
  proc set_pane_sync_indicator {value} {

    variable sync_panes

    set sync_panes $value

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
        $mb add command -label [format "%s %s" [msgcat::mc "Run"] "BIST"] -underline 4 -command "menus::run_bist"
        $mb add separator
        $mb add command -label [format "%s %s" [msgcat::mc "Restart"] "TKE"] -underline 0 -command "menus::restart_command"

        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Start profiling"]]                [list menus::start_profiling_command $mb]
        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Stop profiling"]]                 [list menus::stop_profiling_command $mb 1]
        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Show last profiling report"]]     [list menus::show_last_profiling_report]
        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Show diagnostic logfile"]]        [list logger::view_log]
        launcher::register [make_menu_cmd "Tools" [format "%s %s" [msgcat::mc "Run"] "BIST"]]    [list menus::run_bist]
        launcher::register [make_menu_cmd "Tools" [format "%s %s" [msgcat::mc "Restart"] "TKE"]] [list menus::restart_command]

        # If profiling was enabled at startup, disable start and enable stop
        if {$::cl_profile} {
          $mb entryconfigure [msgcat::mc "Start Profiling"] -state disabled
          $mb entryconfigure [msgcat::mc "Stop Profiling"]  -state normal
        }

        set mb ".menubar.plugins"
        $mb insert 3 separator
        $mb insert 4 command -label [format "%s..." [msgcat::mc "Create"]] -underline 0 -command [list plugins::create_new_plugin]

        launcher::register [make_menu_cmd "Plugins" [msgcat::mc "Create new plugin"]] [list plugins::create_new_plugin]

      } elseif {$last_devel_mode ne ""} {

        set mb    ".menubar.tools"
        set index [$mb index [msgcat::mc "Start Profiling"]]
        $mb delete [expr $index - 1] end
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Start profiling"]] * *
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Stop profiling"]] * *
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Show last profiling report"]] * *
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Show diagnostic logfile"]] * *
        launcher::unregister [make_menu_cmd "Tools" [format "%s %s" [msgcat::mc "Run"] "BIST"]] * *
        launcher::unregister [make_menu_cmd "Tools" [format "%s %s" [msgcat::mc "Restart"] "TKE"]] * *

        set mb ".menubar.plugins"
        $mb delete 3 4
        launcher::unregister [make_menu_cmd "Plugins" [msgcat::mc "Create new plugin"]] * *

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
    $mb add cascade -label [msgcat::mc "File"] -menu [make_menu $mb.file -tearoff false -postcommand "menus::file_posting $mb.file"]
    add_file $mb.file

    # Add the edit menu
    $mb add cascade -label [msgcat::mc "Edit"] -menu [make_menu $mb.edit -tearoff false -postcommand "menus::edit_posting $mb.edit"]
    add_edit $mb.edit

    # Add the find menu
    $mb add cascade -label [msgcat::mc "Find"] -menu [make_menu $mb.find -tearoff false -postcommand "menus::find_posting $mb.find"]
    add_find $mb.find

    # Add the view menu
    $mb add cascade -label [msgcat::mc "View"] -menu [make_menu $mb.view -tearoff false -postcommand "menus::view_posting $mb.view"]
    add_view $mb.view

    # Add the tools menu
    $mb add cascade -label [msgcat::mc "Tools"] -menu [make_menu $mb.tools -tearoff false -postcommand "menus::tools_posting $mb.tools"]
    add_tools $mb.tools

    # Add the sessions menu
    $mb add cascade -label [msgcat::mc "Sessions"] -menu [make_menu $mb.sessions -tearoff false -postcommand "menus::sessions_posting $mb.sessions"]
    add_sessions $mb.sessions

    # Add the plugins menu
    $mb add cascade -label [msgcat::mc "Plugins"] -menu [make_menu $mb.plugins -tearoff false -postcommand "menus::plugins_posting $mb.plugins"]
    add_plugins $mb.plugins

    # Add the help menu
    $mb add cascade -label [msgcat::mc "Help"] -menu [make_menu $mb.help -tearoff false]
    add_help $mb.help

    # If we are running on Mac OS X, add the window menu with the windowlist package
    if {[tk windowingsystem] eq "aqua"} {

      # Add the window menu with the windowlist package
      windowlist::windowMenu $mb

      # Add the launcher command to show the about window
      launcher::register [make_menu_cmd "Help" [format "%s %s" [msgcat::mc "About"] "TKE"]] gui::show_about

    }

    if {([tk windowingsystem] eq "aqua") || [preferences::get View/ShowMenubar]} {
      . configure -menu $mb
    }

    # Load and apply the menu bindings
    bindings::load

    # Handle the default development mode
    handle_development_mode

    # Register the menubar for theming purposes if we are running on MacOSX
    if {[tk windowingsystem] ne "aqua"} {
      theme::register_widget $mb menus
    }

  }

  ########################
  #  PRIVATE PROCEDURES  #
  ########################

  ######################################################################
  # Returns a menu that will be used in the main menu system.
  proc make_menu {w args} {

    # Create the menu
    set mnu [menu $w {*}$args]

    # Create menu binding that will allow us to Shift click menu items to
    # edit their shortcuts in the preferences window.
    bind $mnu <Control-Button-1>        { menus::handle_menu_shift_click %W %y; break }
    bind $mnu <Control-ButtonRelease-1> { break }

    return $mnu

  }

  ######################################################################
  # Handles menu shift click events.  If the preference GUI is enabled,
  # automatically open preferences, display the Shortcuts panel and
  # set the selected menu for editing.
  proc handle_menu_shift_click {w y} {

    # Unpost the menu (and all of its ancestors)
    catch { tk::MenuUnpost $w }

    if {[preferences::get General/EditPreferencesUsingGUI]} {
      pref_ui::create "" "" shortcuts
      pref_ui::shortcut_edit_item [string map {# .} [lindex [split $w .] end]] [$w entrycget @$y -label]
    } else {
      bindings::edit_user
    }

  }

  ######################################################################
  # Returns the menu string with language support.
  proc make_menu_cmd {mnu lbl} {

    return [format "%s %s: %s" [msgcat::mc $mnu] [msgcat::mc "Menu"] $lbl]

  }

  ######################################################################
  # Adds the file menu.
  proc add_file {mb} {

    $mb delete 0 end

    $mb add command -label [msgcat::mc "New Window"] -underline 4 -command [list menus::new_window_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "New window"]] [list menus::new_window_command]

    $mb add command -label [msgcat::mc "New File"] -underline 0 -command [list menus::new_file_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "New file"]] [list menus::new_file_command]

    $mb add command -label [format "%s..." [msgcat::mc "New From Template"]] -underline 9 -command [list templates::show_templates load_abs]
    launcher::register [make_menu_cmd "File" [msgcat::mc "New file from template"]] [list templates::show_templates load_abs]

    $mb add separator

    $mb add command -label [format "%s..." [msgcat::mc "Open File"]] -underline 0 -command [list menus::open_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Open file"]] [list menus::open_command]

    $mb add command -label [format "%s..." [msgcat::mc "Open Directory"]] -underline 5 -command [list menus::open_dir_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Open directory"]] [list menus::open_dir_command]

    $mb add command -label [format "%s..." [msgcat::mc "Open Remote"]] -underline 0 -command [list menus::open_remote_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Open remote file or directory"]] [list menus::open_remote_command]

    $mb add cascade -label [msgcat::mc "Open Recent"] -menu [make_menu $mb.recent -tearoff false -postcommand [list menus::file_recent_posting $mb.recent]]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Open Recent"]] [list menus::launcher]

    $mb add cascade -label [msgcat::mc "Open Favorite"] -menu [make_menu $mb.favorites -tearoff false -postcommand [list menus::file_favorites_posting $mb.favorites]]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Open Favorite"]] [list favorites::launcher]

    $mb add command -label [msgcat::mc "Reopen File"] -underline 0 -command [list gui::update_current]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Reopen current file"]] [list gui::update_current]

    $mb add separator

    $mb add command -label [msgcat::mc "Change Working Directory"] -underline 0 -command [list menus::change_working_directory]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Change working directory"]] [list menus::change_working_directory]

    $mb add separator

    $mb add command -label [msgcat::mc "Show File Difference"] -underline 3 -command [list menus::show_file_diff]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Show file difference"]] [list menus::show_file_diff]

    $mb add separator

    $mb add command -label [msgcat::mc "Save"] -underline 0 -command [list menus::save_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Save file"]] [list menus::save_command]

    $mb add command -label [format "%s..." [msgcat::mc "Save As"]] -underline 5 -command [list menus::save_as_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Save file as"]] menus::save_as_command

    $mb add command -label [format "%s..." [msgcat::mc "Save As Remote"]] -command [list menus::save_as_remote_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Save file as remote file"]] menus::save_as_remote_command

    $mb add command -label [format "%s..." [msgcat::mc "Save As Template"]] -command [list templates::save_as]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Save file as template"]] [list templates::save_as]

    $mb add command -label [format "%s..." [msgcat::mc "Save Selection As"]] -underline 7 -command [list menus::save_selection_as_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Save selected lines"]] [list menus::save_selection_as_command]

    $mb add command -label [msgcat::mc "Save All"] -underline 6 -command [list gui::save_all]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Save all files"]] [list gui::save_all]

    $mb add separator

    # Populate the export menu
    $mb add command -label [format "%s..." [msgcat::mc "Export"]] -command [list menus::export_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Export file contents"]] [list menus::export_command]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Line Ending"] -menu [make_menu $mb.eolPopup -tearoff 0 -postcommand [list menus::file_eol_posting $mb.eolPopup]]

    $mb add separator

    $mb add command -label [msgcat::mc "Rename"] -underline 4 -command [list menus::rename_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Rename current file"]] [list menus::rename_command]

    $mb add command -label [msgcat::mc "Duplicate"] -underline 1 -command [list menus::duplicate_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Duplicate current file"]] [list menus::duplicate_command]

    $mb add command -label [msgcat::mc "Delete"] -underline 0 -command [list menus::delete_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Delete current file"]] [list menus::delete_command]

    $mb add separator

    $mb add command -label [msgcat::mc "Lock"] -underline 0 -command [list menus::lock_command $mb]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Lock file"]] [list menus::lock_command $mb]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Unlock file"]] [list menus::unlock_command $mb]

    $mb add command -label [msgcat::mc "Favorite"] -underline 0 -command [list menus::favorite_command $mb]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Favorite file"]] [list menus::favorite_command $mb]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Unfavorite file"]] [list menus::unfavorite_command $mb]

    $mb add separator

    $mb add command -label [msgcat::mc "Close"] -underline 0 -command [list menus::close_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Close current tab"]] [list menus::close_command]

    $mb add command -label [msgcat::mc "Close All"] -underline 6 -command [list menus::close_all_command]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Close all tabs"]] [list menus::close_all_command]

    # Only add the quit menu to File if we are not running in aqua
    if {[tk windowingsystem] ne "aqua"} {
      $mb add separator
      $mb add command -label [msgcat::mc "Quit"] -underline 0 -command [list menus::exit_command]
    }
    launcher::register [make_menu_cmd "File" [msgcat::mc "Quit application"]] [list menus::exit_command]

    # Populate the end-of-line menu
    $mb.eolPopup add radiobutton -label [msgcat::mc "Windows"]     -variable menus::line_ending -value "crlf" -command [list gui::set_current_eol_translation crlf]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Set current file line ending to CRLF for Windows"]] [list gui::set_current_eol_translation crlf]

    $mb.eolPopup add radiobutton -label [msgcat::mc "Unix"]        -variable menus::line_ending -value "lf"   -command [list gui::set_current_eol_translation lf]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Set current file line ending to LF for Unix"]] [list gui::set_current_eol_translation lf]

    $mb.eolPopup add radiobutton -label [msgcat::mc "Classic Mac"] -variable menus::line_ending -value "cr"   -command [list gui::set_current_eol_translation cr]
    launcher::register [make_menu_cmd "File" [msgcat::mc "Set current file line ending to CR for Classic Mac"]] [list gui::set_current_eol_translation cr]

  }

  ######################################################################
  # Called prior to the file menu posting.
  proc file_posting {mb} {

    # Get information for current file
    lassign [gui::get_info {} current {fileindex fname readonly lock diff buffer modified remote}] file_index fname readonly file_lock diff_mode buffer modified remote

    # Get the current file index (if one exists)
    if {$file_index != -1} {

      # Get state if the file is a buffer
      set buffer_state [expr {$buffer ? "disabled" : "normal"}]

      # Get the state for items that are not valid for remote files
      set no_remote_state [expr {($remote eq "") ? $buffer_state : "disabled"}]

      # Get the current favorite status
      set favorite [favorites::is_favorite $fname]

      # Configure the Lock/Unlock menu item
      if {$file_lock && ![catch { $mb index [msgcat::mc "Lock"] } index]} {
        $mb entryconfigure $index -label [msgcat::mc "Unlock"] -state normal -command "menus::unlock_command $mb"
        if {$readonly} {
          $mb entryconfigure $index -state disabled
        }
      } elseif {!$file_lock && ![catch { $mb index [msgcat::mc "Unlock"] } index]} {
        $mb entryconfigure $index -label [msgcat::mc "Lock"] -state normal -command "menus::lock_command $mb"
      }

      # Configure the Favorite/Unfavorite menu item
      if {$favorite} {
        if {![catch { $mb index [msgcat::mc "Favorite"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Unfavorite"] -command "menus::unfavorite_command $mb"
        }
        $mb entryconfigure [msgcat::mc "Unfavorite"] -state [expr {(($fname ne "") && !$diff_mode) ? $no_remote_state : "disabled"}]
      } else {
        if {![catch { $mb index [msgcat::mc "Unfavorite"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Favorite"] -command "menus::favorite_command $mb"
        }
        $mb entryconfigure [msgcat::mc "Favorite"] -state [expr {(($fname ne "") && !$diff_mode) ? $no_remote_state : "disabled"}]
      }

      # Configure the Delete/Move To Trash
      if {($remote eq "") && [preferences::get General/UseMoveToTrash]} {
        if {![catch { $mb index [msgcat::mc "Delete"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Move To Trash"] -command [list menus::move_to_trash_command] -state $buffer_state
        }
      } else {
        if {![catch { $mb index [msgcat::mc "Move To Trash"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Delete"] -command [list menus::delete_command] -state $buffer_state
        }
      }

      # Make sure that the file-specific items are enabled
      $mb entryconfigure [msgcat::mc "Reopen File"]                        -state $buffer_state
      $mb entryconfigure [msgcat::mc "Show File Difference"]               -state $no_remote_state
      $mb entryconfigure [msgcat::mc "Save"]                               -state [expr {$modified ? "normal" : "disabled"}]
      $mb entryconfigure [format "%s..." [msgcat::mc "Save As"]]           -state normal
      $mb entryconfigure [format "%s..." [msgcat::mc "Save As Remote"]]    -state normal
      $mb entryconfigure [format "%s..." [msgcat::mc "Save As Template"]]  -state normal
      $mb entryconfigure [format "%s..." [msgcat::mc "Save Selection As"]] -state [expr {[gui::selected {}] ? "normal" : "disabled"}]
      $mb entryconfigure [msgcat::mc "Save All"]                           -state normal
      $mb entryconfigure [format "%s..." [msgcat::mc "Export"]]            -state normal
      $mb entryconfigure [msgcat::mc "Line Ending"]                        -state normal
      $mb entryconfigure [msgcat::mc "Rename"]                             -state $buffer_state
      $mb entryconfigure [msgcat::mc "Duplicate"]                          -state $buffer_state
      $mb entryconfigure [msgcat::mc "Close"]                              -state normal
      $mb entryconfigure [msgcat::mc "Close All"]                          -state normal

    } else {

      # Disable file menu items associated with current tab (since one doesn't currently exist)
      $mb entryconfigure [msgcat::mc "Reopen File"]                        -state disabled
      $mb entryconfigure [msgcat::mc "Show File Difference"]               -state disabled
      $mb entryconfigure [msgcat::mc "Save"]                               -state disabled
      $mb entryconfigure [format "%s..." [msgcat::mc "Save As"]]           -state disabled
      $mb entryconfigure [format "%s..." [msgcat::mc "Save As Remote"]]    -state disabled
      $mb entryconfigure [format "%s..." [msgcat::mc "Save As Template"]]  -state disabled
      $mb entryconfigure [format "%s..." [msgcat::mc "Save Selection As"]] -state disabled
      $mb entryconfigure [msgcat::mc "Save All"]                           -state disabled
      $mb entryconfigure [format "%s..." [msgcat::mc "Export"]]            -state disabled
      $mb entryconfigure [msgcat::mc "Line Ending"]                        -state disabled
      $mb entryconfigure [msgcat::mc "Rename"]                             -state disabled
      $mb entryconfigure [msgcat::mc "Duplicate"]                          -state disabled
      $mb entryconfigure [msgcat::mc "Delete"]                             -state disabled
      $mb entryconfigure [msgcat::mc "Lock"]                               -state disabled
      $mb entryconfigure [msgcat::mc "Favorite"]                           -state disabled
      $mb entryconfigure [msgcat::mc "Close"]                              -state disabled
      $mb entryconfigure [msgcat::mc "Close All"]                          -state disabled

    }

    $mb entryconfigure [format "%s..." [msgcat::mc "New From Template"]] -state [expr {[templates::valid] ? "normal" : "disabled"}]

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
      $mb add command -label [msgcat::mc "Recent Directories"] -state disabled
      foreach sdir [lrange $sdirs 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
        $mb add command -label [format "   %s" $sdir] -command [list sidebar::add_directory $sdir]
      }
      $mb add separator
    }

    # Populate the menu with the filenames
    if {[llength [set fnames [gui::get_last_opened]]] > 0} {
      $mb add command -label [msgcat::mc "Recent Files"] -state disabled
      foreach fname [lrange $fnames 0 [expr [preferences::get View/ShowRecentlyOpened] - 1]] {
        $mb add command -label [format "   %s" $fname] -command [list gui::add_file end $fname]
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
  # Called when the export file menu is posted.
  proc file_export_posting {mb} {

    # TBD

  }

  ######################################################################
  # Called just prior to the EOL menu being posted.
  proc file_eol_posting {mb} {

    variable line_ending

    # Set the line_ending to the current line ending to use
    set line_ending [gui::get_info {} current eol]

  }

  ######################################################################
  # Starts a new session (window)
  proc new_window_command {} {

    # Execute the restart command
    if {[file tail [info nameofexecutable]] eq "tke.exe"} {
      exec -ignorestderr [info nameofexecutable] -n &
    } else {
      array set frame [info frame 1]
      exec -ignorestderr [info nameofexecutable] $::argv0 -- -n &
    }

  }

  ######################################################################
  # Implements the "create new file" command.
  proc new_file_command {} {

    gui::add_new_file end -sidebar 1

  }

  ######################################################################
  # Displays the templates in the command launcher.
  proc new_file_from_template {} {

    templates::show_templates load_abs

  }

  ######################################################################
  # Opens a new file and adds a new tab for the file.
  proc open_command {} {

    # Get the directory of the current file
    set dirname [gui::get_browse_directory]

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
    set dirname [gui::get_browse_directory]

    if {[set odir [tk_chooseDirectory -parent . -initialdir $dirname -mustexist 1]] ne ""} {
      sidebar::add_directory $odir
    }

  }

  ######################################################################
  # Opens one or more remote files in editing buffer(s).
  proc open_remote_command {} {

    # Get the directory or file
    lassign [remote::create open] conn_name ofiles

    # Add the files to the editing area
    foreach ofile $ofiles {
      if {[lassign $ofile fname]} {
        sidebar::add_directory $fname -remote $conn_name
      } else {
        gui::add_file end $fname -remote $conn_name
      }
    }

  }

  ######################################################################
  # Change the current working directory to a specified value.
  proc change_working_directory {} {

    if {[set dir [tk_chooseDirectory -parent . -initialdir [gui::get_browse_directory] -mustexist 1]] ne ""} {
      gui::change_working_directory $dir
    }

  }

  ######################################################################
  # Displays the difference of the current file.
  proc show_file_diff {} {

    # Get the current filename
    set fname [gui::get_info {} current fname]

    # Display the current file as a difference
    gui::add_file end $fname -diff 1 -other [preferences::get View/ShowDifferenceInOtherPane]

  }

  ######################################################################
  # Saves the current tab file.
  proc save_command {} {

    gui::save_current {} -force 1

  }

  ######################################################################
  # Saves the current tab file as a new filename.
  proc save_as_command {} {

    # Get some of the save options
    if {[set sfile [gui::prompt_for_save {}]] ne ""} {
      gui::save_current {} -force 1 -save_as $sfile
    }

  }

  ######################################################################
  # Saves the current tab file as a new filename on a remote server.
  proc save_as_remote_command {} {

    set fname [file tail [gui::get_info {} current fname]]

    lassign [remote::create save $fname] connection sfile

    if {$sfile ne ""} {
      gui::save_current {} -force 1 -save_as $sfile -remote $connection
    }

  }

  ######################################################################
  # Saves the currently selected text to a new file.
  proc save_selection_as_command {} {

    # Get the filename
    if {[set sfile [gui::prompt_for_save {}]] ne ""} {

      # Get the current text widget
      set txt [gui::current_txt {}]

      # Save the current selection
      edit::save_selection $txt [$txt index sel.first] [$txt index sel.last] 1 $sfile

    }

  }

  ######################################################################
  # If the current editing buffer is using the Markdown language, exports
  # the contents of the buffer to HTML using the Markdown parser.
  proc export_command {} {

    # Get the directory of the current file
    set dirname [gui::get_browse_directory]

    # Get the current editing buffer
    set txt [gui::current_txt {}]

    # Get the current editing buffer language
    set lang [syntax::get_language $txt]

    # Create additional options to the getSaveFile call
    set opts [list]
    if {$lang eq "Markdown"} {
      if {[set ext [preferences::get General/DefaultMarkdownExportExtension]] ne ""} {
        set ext ".$ext"
      }
      lappend opts -initialfile [file rootname [file tail [gui::get_info $txt txt fname]]]$ext
    }

    # Get the name of the file to output
    if {[set fname [tk_getSaveFile -parent . -title [msgcat::mc "Export As"] -initialdir $dirname {*}$opts]] eq ""} {
      return
    }

    # Get the export name file extension
    set ext [file extension $fname]

    # Get the scrubbed contents of the current buffer
    set contents [gui::scrub_text $txt]

    # Perform any snippet substitutions
    set contents [snippets::substitute $contents [syntax::get_language $txt]]

    if {$lang eq "Markdown"} {
      set md [file join $::tke_dir lib ptwidgets1.2 common Markdown_1.0.1 Markdown.pl]
      if {$ext eq ".xhtml"} {
        set contents [exec echo $contents | $md -]
      } else {
        set contents [exec echo $contents | $md --html4tags -]
      }
    }

    # Open the file for writing
    if {[catch { open $fname w } rc]} {
      gui::set_error_message [msgcat::mc "Unable to write export file"] $rc
      return
    }

    # Write and the close the file
    puts $rc $contents
    close $rc

    # Let the user know that the operation has completed
    gui::set_info_message [msgcat::mc "Export complete"]

  }

  ######################################################################
  # Renames the current file.
  proc rename_command {} {

    # Get the current name
    lassign [gui::get_info {} current {fname remote}] new_name remote

    set old_name $new_name

    # Get the new name from the user
    if {[gui::get_user_response [msgcat::mc "File Name:"] new_name]} {

      # If the value of the cell hasn't changed or is empty, do nothing else.
      if {($old_name eq $new_name) || ($new_name eq "")} {
        return
      }

      if {[catch { files::rename_file $old_name $new_name $remote } new_name]} {
        gui::set_error_message [msgcat::mc "Unable to rename file"] $new_name
        return
      }

      # Add the file directory
      sidebar::update_directory [sidebar::add_directory [file dirname $new_name] -remote $remote]

      # Update the old directory
      if {[set sidebar_index [sidebar::get_index [file dirname $old_name] $remote]] ne ""} {
        sidebar::update_directory $sidebar_index
      }

    }

  }

  ######################################################################
  # Duplicates the current file and adds the duplicated file to the editor.
  proc duplicate_command {} {

    # Get the filename of the current selection
    lassign [gui::get_info {} current {fname remote}] fname remote

    # Create the default name of the duplicate file
    if {[catch { files::duplicate_file $fname $remote } dup_fname]} {
      gui::set_error_message "Unable to duplicate file" $dup_fname
      return
    }

    # Add the file to the editor
    gui::add_file end $dup_fname -remote $remote

    # Update the old directory
    if {[set sidebar_index [sidebar::get_index [file dirname $dup_fname] $remote]] ne ""} {
      sidebar::update_directory $sidebar_index
    }

  }

  ######################################################################
  # Deletes the current file from the file system and removes it from
  # editor.
  proc delete_command {} {

    # Get the full pathname
    lassign [gui::get_info {} current {fname remote}] fname remote

    # Get confirmation from the user
    if {[tk_messageBox -parent . -type yesno -default yes -message [format "%s %s?" [msgcat::mc "Delete"] $fname]] eq "yes"} {

      # Delete the file
      if {[catch { files::delete_file $fname $remote } rc]} {
        gui::set_error_message [msgcat::mc "Unable to delete file"] $rc
        return
      }

      # Update the old directory
      if {[set sidebar_index [sidebar::get_index [file dirname $fname] $remote]] ne ""} {
        sidebar::update_directory $sidebar_index
      }

    }

  }

  ######################################################################
  # Moves the current file to the trash.
  proc move_to_trash_command {} {

    # Get the full pathname
    set fname [lindex [gui::get_info {} current fname] 0]

    # Move the file to the trash
    if {[catch { files::move_to_trash $fname 0 }]} {
      return
    }

    # Update the old directory
    if {[set sidebar_index [sidebar::get_index [file dirname $fname] ""]] ne ""} {
      sidebar::update_directory $sidebar_index
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

    # Get current file information
    lassign [gui::get_info {} current {fileindex fname}] file_index fname

    # Get the current file index (if one exists)
    if {$file_index != -1} {

      # Add the file as a favorite
      if {[favorites::add $fname]} {

        # Set the menu up to display the unfavorite file menu option
        $mb entryconfigure [msgcat::mc "Favorite"] -label [msgcat::mc "Unfavorite"] -command "menus::unfavorite_command $mb"

      }

    }

  }

  ######################################################################
  # Marks the current file as not favorited.
  proc unfavorite_command {mb} {

    # Get current file information
    lassign [gui::get_info {} current {fileindex fname}] file_index fname

    # Get the current file index (if one exists)
    if {$file_index != -1} {

      # Remove the file as a favorite
      if {[favorites::remove $fname]} {

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
    themer::close_window 1

    # Save the session information if we are not told to exit on close
    sessions::save "last"

    # Close all of the tabs
    gui::close_all 1 1

    # Save the clipboard history
    cliphist::save

    # Close the opened remote connections
    remote::disconnect_all

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
    $mb add command -label [msgcat::mc "Undo"] -underline 0 -command [list gui::undo {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Undo"]] [list gui::undo {}]

    $mb add command -label [msgcat::mc "Redo"] -underline 0 -command [list gui::redo {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Redo"]] [list gui::redo {}]

    $mb add separator

    $mb add command -label [msgcat::mc "Cut"] -underline 0 -command [list gui::cut {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Cut text"]] [list gui::cut {}]

    $mb add command -label [msgcat::mc "Copy"] -underline 1 -command [list gui::copy {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Copy text"]] [list gui::copy {}]

    $mb add command -label [msgcat::mc "Paste"] -underline 0 -command [list gui::paste {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Paste text from clipboard"]] [list gui::paste {}]

    $mb add command -label [msgcat::mc "Paste and Format"] -underline 10 -command [list gui::paste_and_format {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Paste and format text from clipboard"]] [list gui::paste_and_format {}]

    $mb add command -label [msgcat::mc "Select All"] -underline 7 -command [list gui::select_all {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Select all text"]] [list gui::select_all {}]

    $mb add separator

    $mb add checkbutton -label [msgcat::mc "Vim Mode"] -underline 0 -variable preferences::prefs(Editor/VimMode) -command [list vim::set_vim_mode_all]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Enable Vim mode"]]  "set preferences::prefs(Editor/VimMode) 1; vim::set_vim_mode_all"
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Disable Vim mode"]] "set preferences::prefs(Editor/VimMode) 0; vim::set_vim_mode_all"

    $mb add separator

    $mb add command -label [msgcat::mc "Toggle Comment"] -underline 0 -command [list edit::comment_toggle {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Toggle comment"]] [list edit::comment_toggle {}]

    $mb add cascade -label [msgcat::mc "Indentation"] -underline 0 -menu [make_menu $mb.indentPopup -tearoff 0 -postcommand [list menus::edit_indent_posting $mb.indentPopup]]
    $mb add cascade -label [msgcat::mc "Cursor"]      -underline 1 -menu [make_menu $mb.cursorPopup -tearoff 0 -postcommand [list menus::edit_cursor_posting $mb.cursorPopup]]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Insert"]    -menu [make_menu $mb.insertPopup    -tearoff 0 -postcommand [list menus::edit_insert_posting $mb.insertPopup]]
    $mb add cascade -label [msgcat::mc "Delete"]    -menu [make_menu $mb.deletePopup    -tearoff 0 -postcommand [list menus::edit_delete_posting $mb.deletePopup]]
    $mb add cascade -label [msgcat::mc "Transform"] -menu [make_menu $mb.transformPopup -tearoff 0 -postcommand [list menus::edit_transform_posting $mb.transformPopup]]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Preferences"]   -menu [make_menu $mb.prefPopup  -tearoff 0 -postcommand [list menus::edit_preferences_posting $mb.prefPopup]]
    $mb add cascade -label [msgcat::mc "Menu Bindings"] -menu [make_menu $mb.bindPopup  -tearoff 0]
    $mb add cascade -label [msgcat::mc "Snippets"]      -menu [make_menu $mb.snipPopup  -tearoff 0 -postcommand [list menus::edit_snippets_posting $mb.snipPopup]]
    $mb add cascade -label [msgcat::mc "Templates"]     -menu [make_menu $mb.tempPopup  -tearoff 0 -postcommand [list menus::edit_templates_posting $mb.tempPopup]]
    $mb add cascade -label "Emmet"                      -menu [make_menu $mb.emmetPopup -tearoff 0 -postcommand [list menus::edit_emmet_posting $mb.emmetPopup]]
    $mb add cascade -label [msgcat::mc "Sharing"]       -menu [make_menu $mb.sharePopup -tearoff 0]

    ###########################
    # Populate indentation menu
    ###########################

    $mb.indentPopup add command -label [msgcat::mc "Indent"] -underline 0 -command [list menus::indent_command]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Indent selected text"]] [list menus::indent_command]

    $mb.indentPopup add command -label [msgcat::mc "Unindent"] -underline 1 -command [list menus::unindent_command]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Unindent selected text"]] [list menus::unindent_command]

    $mb.indentPopup add separator

    $mb.indentPopup add command -label [msgcat::mc "Format Text"] -command [list gui::format_text {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Format indentation for text"]] [list gui::format_text {}]

    $mb.indentPopup add separator

    $mb.indentPopup add radiobutton -label [msgcat::mc "Indent Off"] -variable menus::indent_mode -value "OFF" -command [list indent::set_indent_mode {} OFF]
    launcher::register [make_menu_cmd "Edit" [format "%s %s" [msgcat::mc "Set indent mode to"] "OFF"]] [list indent::set_indent_mode {} OFF]

    $mb.indentPopup add radiobutton -label [msgcat::mc "Auto-Indent"] -variable menus::indent_mode -value "IND" -command [list indent::set_indent_mode {} IND]
    launcher::register [make_menu_cmd "Edit" [format "%s %s" [msgcat::mc "Set indent mode to"] "IND"]] [list indent::set_indent_mode {} IND]

    $mb.indentPopup add radiobutton -label [msgcat::mc "Smart Indent"] -variable menus::indent_mode -value "IND+" -command [list indent::set_indent_mode {} IND+]
    launcher::register [make_menu_cmd "Edit" [format "%s %s" [msgcat::mc "Set indent mode to"] "IND+"]] [list indent::set_indent_mode {} IND+]

    ######################
    # Populate cursor menu
    ######################

    $mb.cursorPopup add command -label [msgcat::mc "Move to First Line"] -command [list menus::edit_cursor_move first]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to first line"]] [list menus::edit_cursor_move first]

    $mb.cursorPopup add command -label [msgcat::mc "Move to Last Line"] -command [list menus::edit_cursor_move last]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to last line"]] [list menus::edit_cursor_move last]

    $mb.cursorPopup add command -label [msgcat::mc "Move to Next Page"] -command [list menus::edit_cursor_move_by_page next]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to next page"]] [list menus::edit_cursor_move_by_page next]

    $mb.cursorPopup add command -label [msgcat::mc "Move to Previous Page"] -command [list menus::edit_cursor_move_by_page prior]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to previous page"]] [list menus::edit_cursor_move_by_page prior]

    $mb.cursorPopup add separator

    $mb.cursorPopup add command -label [msgcat::mc "Move to Screen Top"] -command [list menus::edit_cursor_move screentop]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to top of screen"]] [list menus::edit_cursor_move screentop]

    $mb.cursorPopup add command -label [msgcat::mc "Move to Screen Middle"] -command [list menus::edit_cursor_move screenmid]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to middle of screen"]] [list menus::edit_cursor_move screenmid]

    $mb.cursorPopup add command -label [msgcat::mc "Move to Screen Bottom"] -command [list menus::edit_cursor_move screenbot]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to bottom of screen"]] [list menus::edit_cursor_move screenbot]

    $mb.cursorPopup add separator

    $mb.cursorPopup add command -label [msgcat::mc "Move to Line Start"] -command [list menus::edit_cursor_move linestart]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to start of current line"]] [list menus::edit_cursor_move linestart]

    $mb.cursorPopup add command -label [msgcat::mc "Move to Line End"] -command [list menus::edit_cursor_move lineend]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to end of current line"]] [list menus::edit_cursor_move lineend]

    $mb.cursorPopup add command -label [msgcat::mc "Move to Next Word"] -command [list menus::edit_cursor_move nextword]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to next word"]] [list menus::edit_cursor_move nextword]

    $mb.cursorPopup add command -label [msgcat::mc "Move to Previous Word"] -command [list menus::edit_cursor_move prevword]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to previous word"]] [list menus::edit_cursor_move prevword]

    $mb.cursorPopup add separator

    $mb.cursorPopup add command -label [msgcat::mc "Move Cursors Up"] -command [list menus::edit_cursors_move "-1l"]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move multicursors up one line"]] [list menus::edit_cursors_move "-1l"]

    $mb.cursorPopup add command -label [msgcat::mc "Move Cursors Down"] -command [list menus::edit_cursors_move "+1l"]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move multicursors down one line"]] [list menus::edit_cursors_move "+1l"]

    $mb.cursorPopup add command -label [msgcat::mc "Move Cursors Left"] -command [list menus::edit_cursors_move "-1c"]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move multicursors left one line"]] [list menus::edit_cursors_move "-1c"]

    $mb.cursorPopup add command -label [msgcat::mc "Move Cursors Right"] -command [list menus::edit_cursors_move "+1c"]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move multicursors right one line"]] [list menus::edit_cursors_move "+1c"]

    $mb.cursorPopup add separator

    $mb.cursorPopup add command -label [msgcat::mc "Align Cursors"] -command [list edit::align_cursors {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Align cursors"]] [list edit::align_cursors {}]

    #########################
    # Populate insertion menu
    #########################

    $mb.insertPopup add command -label [msgcat::mc "Line Above Current"] -command [list menus::edit_insert_line_above]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert line above current line"]] [list menus::edit_insert_line_above]

    $mb.insertPopup add command -label [msgcat::mc "Line Below Current"] -command [list menus::edit_insert_line_below]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert line below current line"]] [list menus::edit_insert_line_below]

    $mb.insertPopup add separator

    $mb.insertPopup add command -label [msgcat::mc "File Contents"] -command [list menus::edit_insert_file_after_current_line]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert file contents after current line"]] [list menus::edit_insert_file_after_current_line]

    $mb.insertPopup add command -label [msgcat::mc "Command Result"] -command [list menus::edit_insert_command_after_current_line]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert command result after current line"]] [list menus::edit_insert_command_after_current_line]

    $mb.insertPopup add separator

    $mb.insertPopup add command -label [msgcat::mc "From Clipboard"] -command [list cliphist::show_cliphist]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert from clipboard"]] [list cliphist::show_cliphist]

    $mb.insertPopup add command -label [msgcat::mc "Snippet"] -command [list snippets::show_snippets]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert snippet"]] [list snippets::show_snippets]

    $mb.insertPopup add separator

    $mb.insertPopup add command -label [msgcat::mc "Enumeration"] -underline 7 -command [list edit::insert_enumeration {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert enumeration"]] [list edit::insert_enumeration {}]

    ########################
    # Populate deletion menu
    ########################

    $mb.deletePopup add command -label [msgcat::mc "Current Line"] -command [list menus::edit_delete_current_line]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Delete current line"]] [list menus::edit_delete_current_line]

    $mb.deletePopup add command -label [msgcat::mc "Current Word"] -command [list menus::edit_delete_current_word]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Delete current word"]] [list menus::edit_delete_current_word]

    $mb.deletePopup add command -label [msgcat::mc "Current Number"] -command [list menus::edit_delete_current_number]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Delete the current number"]] [list menus::edit_delete_current_number]

    $mb.deletePopup add separator

    $mb.deletePopup add command -label [msgcat::mc "Cursor to Line End"] -command [list menus::edit_delete_to_end]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Delete from cursor to end of line"]] [list menus::edit_delete_to_end]

    $mb.deletePopup add command -label [msgcat::mc "Cursor from Line Start"] -command [list menus::edit_delete_from_start]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Delete from start of line to cursor"]] [list menus::edit_delete_from_start]

    $mb.deletePopup add separator

    $mb.deletePopup add command -label [msgcat::mc "Whitespace Forward"] -command [list menus::edit_delete_next_space]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Delete the whitespace to right of cursor"]] [list menus::edit_delete_next_space]

    $mb.deletePopup add command -label [msgcat::mc "Whitespace Backward"] -command [list menus::edit_delete_prev_space]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Delete the whitespace to left of cursor"]] [list menus::edit_delete_prev_space]

    $mb.deletePopup add separator

    $mb.deletePopup add command -label [msgcat::mc "Text Between Character"] -command [list menus::edit_delete_between_char]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Delete text between character"]] [list menus::edit_delete_between_char]

    #########################
    # Populate transform menu
    #########################

    $mb.transformPopup add command -label [msgcat::mc "Toggle Case"] -command [list menus::edit_transform_toggle_case]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Toggle case of current character"]] [list menus::edit_transform_toggle_case]

    $mb.transformPopup add command -label [msgcat::mc "Lower Case"] -command [list menus::edit_transform_to_lower_case]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Convert case to lower"]] [list menus::edit_transform_to_lower_case]

    $mb.transformPopup add command -label [msgcat::mc "Upper Case"] -command [list menus::edit_transform_to_upper_case]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Convert case to upper"]] [list menus::edit_transform_to_upper_case]

    $mb.transformPopup add command -label [msgcat::mc "Title Case"] -command [list menus::edit_transform_to_title_case]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Convert case to title"]] [list menus::edit_transform_to_title_case]

    $mb.transformPopup add separator

    $mb.transformPopup add command -label [msgcat::mc "Join Lines"] -command [list menus::edit_transform_join_lines]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Join lines"]] [list menus::edit_transform_join_lines]

    $mb.transformPopup add separator

    $mb.transformPopup add command -label [msgcat::mc "Bubble Up"] -command [list menus::edit_transform_bubble_up]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Bubble lines up one line"]] [list menus::edit_transform_bubble_up]

    $mb.transformPopup add command -label [msgcat::mc "Bubble Down"] -command [list menus::edit_transform_bubble_down]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Bubble lines down one line"]] [list menus::edit_transform_bubble_down]

    $mb.transformPopup add separator

    $mb.transformPopup add command -label [msgcat::mc "Replace Line With Script"] -command [list edit::replace_line_with_script {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Replace line with script"]] [list edit::replace_line_with_script {}]

    ###########################
    # Populate preferences menu
    ###########################

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Edit User"] [msgcat::mc "Global"]] -command [list menus::edit_user_global]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit user global preferences"]] [list menus::edit_user_global]

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Edit User"] [msgcat::mc "Language"]] -command [list menus::edit_user_language]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit user current language preferences"]] [list menus::edit_user_language]

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Global"]] -command [list menus::edit_session_global]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit session global preferences"]] [list menus::edit_session_global]

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Language"]] -command [list menus::edit_session_language]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit session current language preferences"]] [list menus::edit_session_language]

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [msgcat::mc "View Base"] -command [list preferences::view_global]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "View base preferences file"]] [list preferences::view_global]

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [msgcat::mc "Reset User to Base"] -command [list preferences::copy_default]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Set user preferences to global preferences"]] [list preferences::copy_default]

    #############################
    # Populate menu bindings menu
    #############################

    $mb.bindPopup add command -label [msgcat::mc "Edit User"] -command [list menus::bindings_edit_user]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit user menu bindings"]] [list menus::bindings_edit_user]

    $mb.bindPopup add separator

    $mb.bindPopup add command -label [msgcat::mc "View Global"] -command [list bindings::view_global]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "View global menu bindings"]] [list bindings::view_global]

    $mb.bindPopup add separator

    $mb.bindPopup add command -label [msgcat::mc "Set User to Global"] -command [list bindings::copy_default]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Set user bindings to global bindings"]] [list bindings::copy_default]

    ########################
    # Populate snippets menu
    ########################

    $mb.snipPopup add command -label [msgcat::mc "Edit User"] -command [list menus::add_new_snippet user]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit user snippets"]] [list menus::add_new_snippet user]

    $mb.snipPopup add command -label [msgcat::mc "Edit Language"] -command [list menus::add_new_snippet lang]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit language snippets"]] [list menus::add_new_snippet lang]

    $mb.snipPopup add separator

    $mb.snipPopup add command -label [msgcat::mc "Reload"] -command [list snippets::reload_snippets {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Reload snippets"]] [list snippets::reload_snippets {}]

    #########################
    # Populate templates menu
    #########################

    $mb.tempPopup add command -label [msgcat::mc "Edit"] -command [list templates::show_templates edit]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit template"]] [list templates::show_templates edit]

    $mb.tempPopup add command -label [msgcat::mc "Delete"] -command [list templates::show_templates delete]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Delete template"]] [list templates::show_templates delete]

    $mb.tempPopup add separator

    $mb.tempPopup add command -label [msgcat::mc "Reload"] -command [list templates::preload]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Reload template information"]] [list templates::preload]

    #####################
    # Populate Emmet menu
    #####################

    $mb.emmetPopup add command -label [msgcat::mc "Expand Abbreviation"] -command [list emmet::expand_abbreviation {}]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Expand Emmet abbreviation"]] [list emmet::expand_abbreviation {}]

    $mb.emmetPopup add separator

    $mb.emmetPopup add command -label [msgcat::mc "Edit Custom Abbreviations"] -command [list emmet::edit_abbreviations]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit custom Emmet abbreviations"]] [list emmet::edit_abbreviations]

    ########################
    # Populate Sharing menu
    ########################

    $mb.sharePopup add command -label [format "%s..." [msgcat::mc "Edit"]] -command [list menus::share_setup]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit settings sharing preferences"]] [list menus::share_setup]

    $mb.sharePopup add separator

    $mb.sharePopup add command -label [format "%s..." [msgcat::mc "Export Settings"]] -command [list share::create_export]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Export settings data"]] [list share::create_export]

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
      $mb entryconfigure [msgcat::mc "Toggle Comment"]   -state disabled
      $mb entryconfigure [msgcat::mc "Indentation"]      -state disabled
      $mb entryconfigure [msgcat::mc "Insert"]           -state disabled
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
      if {[lindex [syntax::get_comments [gui::current_txt {}]] 0] eq ""} {
        $mb entryconfigure [msgcat::mc "Toggle Comment"] -state disabled
      } else {
        $mb entryconfigure [msgcat::mc "Toggle Comment"] -state normal
      }
      $mb entryconfigure [msgcat::mc "Indentation"] -state normal
      if {[gui::editable {}]} {
        $mb entryconfigure [msgcat::mc "Insert"]    -state normal
        $mb entryconfigure [msgcat::mc "Delete"]    -state normal
        $mb entryconfigure [msgcat::mc "Transform"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Insert"]    -state disabled
        $mb entryconfigure [msgcat::mc "Delete"]    -state disabled
        $mb entryconfigure [msgcat::mc "Transform"] -state disabled
      }
    }

  }

  ######################################################################
  # Called just prior to posting the edit/indentation menu option.  Sets
  # the menu option states to match the current UI state.
  proc edit_indent_posting {mb} {

    variable indent_mode

    set state "disabled"

    # Set the indentation mode for the current editor
    if {[set txt [gui::current_txt {}]] ne ""} {
      set indent_mode [indent::get_indent_mode $txt]
      set state       "normal"
    }

    $mb entryconfigure [msgcat::mc "Unindent"]     -state $state
    $mb entryconfigure [msgcat::mc "Indent"]       -state $state
    $mb entryconfigure [msgcat::mc "Indent Off"]   -state $state
    $mb entryconfigure [msgcat::mc "Auto-Indent"]  -state $state
    $mb entryconfigure [msgcat::mc "Smart Indent"] -state $state

  }

  ######################################################################
  # Called just prior to posting the edit/cursor menu option.  Sets the
  # menu option states to match the current UI state.
  proc edit_cursor_posting {mb} {

    set mstate "disabled"
    set sstate "disabled"

    # Get the current text widget
    if {[set txt [gui::current_txt {}]] ne ""} {
      if {[multicursor::enabled $txt]} {
        set mstate "normal"
      } else {
        set sstate "normal"
      }
    }

    $mb entryconfigure [msgcat::mc "Move to First Line"]    -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Last Line"]     -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Next Page"]     -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Previous Page"] -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Screen Top"]    -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Screen Middle"] -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Screen Bottom"] -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Line Start"]    -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Line End"]      -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Next Word"]     -state $sstate
    $mb entryconfigure [msgcat::mc "Move to Previous Word"] -state $sstate

    $mb entryconfigure [msgcat::mc "Move Cursors Up"]       -state $mstate
    $mb entryconfigure [msgcat::mc "Move Cursors Down"]     -state $mstate
    $mb entryconfigure [msgcat::mc "Move Cursors Left"]     -state $mstate
    $mb entryconfigure [msgcat::mc "Move Cursors Right"]    -state $mstate
    $mb entryconfigure [msgcat::mc "Align Cursors"]         -state $mstate

  }

  ######################################################################
  # Called just prior to posting the edit/insert menu option.  Sets the
  # menu option states to match the current UI state.
  proc edit_insert_posting {mb} {

    set tstate "disabled"
    set mstate "disabled"

    if {[set txt [gui::current_txt {}]] ne ""} {
      set tstate "normal"
      if {[multicursor::enabled $txt]} {
        set mstate "normal"
      }
    }

    $mb entryconfigure [msgcat::mc "Line Above Current"] -state $tstate
    $mb entryconfigure [msgcat::mc "Line Below Current"] -state $tstate
    $mb entryconfigure [msgcat::mc "File Contents"]      -state $tstate
    $mb entryconfigure [msgcat::mc "Command Result"]     -state $tstate

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

    $mb entryconfigure [msgcat::mc "Enumeration"] -state $mstate

  }

  ######################################################################
  # Called just prior to posting the edit/delete menu option.  Sets the
  # menu option states to match the current UI state.
  proc edit_delete_posting {mb} {

    # Get the state
    set state [expr {([gui::current_txt {}] eq "") ? "disabled" : "normal"}]

    $mb entryconfigure [msgcat::mc "Current Line"]           -state $state
    $mb entryconfigure [msgcat::mc "Current Word"]           -state $state
    $mb entryconfigure [msgcat::mc "Current Number"]         -state $state
    $mb entryconfigure [msgcat::mc "Cursor to Line End"]     -state $state
    $mb entryconfigure [msgcat::mc "Cursor from Line Start"] -state $state
    $mb entryconfigure [msgcat::mc "Whitespace Forward"]     -state $state
    $mb entryconfigure [msgcat::mc "Whitespace Backward"]    -state $state
    $mb entryconfigure [msgcat::mc "Text Between Character"] -state $state

  }

  ######################################################################
  # Called just prior to posting the edit/transform menu option.  Sets
  # the menu option states to match the current UI state.
  proc edit_transform_posting {mb} {

    # Get the state
    set state [expr {([gui::current_txt {}] eq "") ? "disabled" : "normal"}]

    $mb entryconfigure [msgcat::mc "Toggle Case"]              -state $state
    $mb entryconfigure [msgcat::mc "Lower Case"]               -state $state
    $mb entryconfigure [msgcat::mc "Upper Case"]               -state $state
    $mb entryconfigure [msgcat::mc "Title Case"]               -state $state
    $mb entryconfigure [msgcat::mc "Join Lines"]               -state $state
    $mb entryconfigure [msgcat::mc "Bubble Up"]                -state $state
    $mb entryconfigure [msgcat::mc "Bubble Down"]              -state $state
    $mb entryconfigure [msgcat::mc "Replace Line With Script"] -state $state

    if {[edit::current_line_empty {}]} {
      $mb entryconfigure [msgcat::mc "Replace Line With Script"] -state disabled
    }

  }

  ######################################################################
  # Called just prior to posting the edit/preferences menu option.  Sets
  # the menu option states to match the current UI state.
  proc edit_preferences_posting {mb} {

    if {[gui::current_txt {}] eq ""} {
      $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit User"]    [msgcat::mc "Language"]] -state disabled
      $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Language"]] -state disabled
    } else {
      $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit User"] [msgcat::mc "Language"]] -state normal
      if {[sessions::current] eq ""} {
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Global"]]   -state disabled
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Language"]] -state disabled
      } else {
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Global"]]   -state normal
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Language"]] -state normal
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
  # Called just prior to posting the edit/templates bindings menu option.
  # Sets the menu option states to match the current UI state.
  proc edit_templates_posting {mb} {

    set state [expr {[templates::valid] ? "normal" : "disabled"}]

    $mb entryconfigure [msgcat::mc "Edit"]   -state $state
    $mb entryconfigure [msgcat::mc "Delete"] -state $state

  }

  ######################################################################
  # Called just prior to posting the edit/emmet bindings menu option.
  # Sets the menu option states to match the current UI state.
  proc edit_emmet_posting {mb} {

    if {[gui::current_txt {}] eq ""} {
      $mb entryconfigure [msgcat::mc "Expand Abbreviation"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Expand Abbreviation"] -state normal
    }

  }

  ######################################################################
  # Indents the current line or current selection.
  proc indent_command {} {

    edit::indent [gui::current_txt {}].t

  }

  ######################################################################
  # Unindents the current line or current selection.
  proc unindent_command {} {

    edit::unindent [gui::current_txt {}].t

  }

  ######################################################################
  # Moves the current cursor by the given modifier for the current
  # text widget.
  proc edit_cursor_move {modifier} {

    # Get the current text widget
    set txtt [gui::current_txt {}].t

    # Move the cursor if we are not in multicursor mode
    if {![multicursor::enabled $txtt]} {
      edit::move_cursor $txtt $modifier
    }

  }

  ######################################################################
  # Moves the current cursor by the given page direction for the current
  # text widget.
  proc edit_cursor_move_by_page {dir} {

    # Get the current text widget
    set txtt [gui::current_txt {}].t

    # Move the cursor if we are not in multicursor mode
    if {![multicursor::enabled $txtt]} {
      edit::move_cursor_by_page $txtt $dir
    }

  }

  ######################################################################
  # Moves multicursors
  proc edit_cursors_move {modifier} {

    # Get the current text widget
    set txtt [gui::current_txt {}].t

    # If we are in multicursor mode, move the cursors in the direction given by modifier
    if {[multicursor::enabled $txtt]} {
      edit::move_cursors $txtt $modifier
    }

  }

  ######################################################################
  # Inserts a new line above the current line.
  proc edit_insert_line_above {} {

    edit::insert_line_above_current [gui::current_txt {}].t

  }

  ######################################################################
  # Inserts a new line below the current line.
  proc edit_insert_line_below {} {

    edit::insert_line_below_current [gui::current_txt {}].t

  }

  ######################################################################
  # Get the name of a file from the user using the open file chooser.
  # Inserts the contents of the file after the current line.
  proc edit_insert_file_after_current_line {} {

    if {[set fname [tk_getOpenFile -parent . -initialdir [gui::get_browse_directory] -multiple 1]] ne ""} {
      edit::insert_file [gui::current_txt {}].t $fname
      gui::set_txt_focus [gui::current_txt {}]
    }

  }

  ######################################################################
  # Gets a shell command from the user via the user input field.  Executes
  # the command and output the results after the current line.
  proc edit_insert_command_after_current_line {} {

    set cmd ""

    if {[gui::get_user_response [format "%s:" [msgcat::mc "Command"]] cmd 1]} {
      edit::insert_file [gui::current_txt {}].t "|$cmd"
    }

  }

  ######################################################################
  # Deletes the current line.
  proc edit_delete_current_line {} {

    edit::delete_current_line [gui::current_txt {}].t

  }

  ######################################################################
  # Deletes the current word.
  proc edit_delete_current_word {} {

    edit::delete_current_word [gui::current_txt {}].t

  }

  ######################################################################
  # Deletes from the current cursor position to the end of the line.
  proc edit_delete_to_end {} {

    edit::delete_to_end [gui::current_txt {}].t

  }

  ######################################################################
  # Deletes from the start of the current line to just before the cursor.
  proc edit_delete_from_start {} {

    edit::delete_from_start [gui::current_txt {}].t

  }

  ######################################################################
  # Deletes the current number.
  proc edit_delete_current_number {} {

    edit::delete_current_number [gui::current_txt {}].t

  }

  ######################################################################
  # Deletes all consecutive whitespace starting from cursor to the end of
  # the line.
  proc edit_delete_next_space {} {

    edit::delete_next_space [gui::current_txt {}].t

  }

  ######################################################################
  # Deletes all consecutive whitespace prior to the cursor.
  proc edit_delete_prev_space {} {

    edit::delete_prev_space [gui::current_txt {}].t

  }

  ######################################################################
  # Deletes all text between the character set that surrounds the current
  # insertion cursor.
  proc edit_delete_between_char {} {

    set char ""

    if {[gui::get_user_response [format "%s:" [msgcat::mc "Character"]] char 0] && ([string length $char] == 1)} {
      edit::delete_between_char [gui::current_txt {}].t $char
    }

  }

  ######################################################################
  # Perform a case toggle operation.
  proc edit_transform_toggle_case {} {

    edit::transform_toggle_case [gui::current_txt {}].t

  }

  ######################################################################
  # Perform a lowercase conversion.
  proc edit_transform_to_lower_case {} {

    edit::transform_to_lower_case [gui::current_txt {}].t

  }

  ######################################################################
  # Perform an uppercase conversion.
  proc edit_transform_to_upper_case {} {

    edit::transform_to_upper_case [gui::current_txt {}].t

  }

  ######################################################################
  # Perform a title case conversion.
  proc edit_transform_to_title_case {} {

    edit::transform_to_title_case [gui::current_txt {}].t

  }

  ######################################################################
  # Joins selected lines or the line beneath the current lines.
  proc edit_transform_join_lines {} {

    edit::transform_join_lines [gui::current_txt {}].t

  }

  ######################################################################
  # Moves selected lines or the current line up by one line.
  proc edit_transform_bubble_up {} {

    edit::transform_bubble_up [gui::current_txt {}].t

  }

  ######################################################################
  # Moves selected lines or the current line down by one line.
  proc edit_transform_bubble_down {} {

    edit::transform_bubble_down [gui::current_txt {}].t

  }

  ######################################################################
  # Edits the user global preference settings.
  proc edit_user_global {} {

    # preferences::edit_global
    if {[preferences::get General/EditPreferencesUsingGUI]} {
      pref_ui::create "" ""
    } else {
      preferences::edit_global
    }

  }

  ######################################################################
  # Edits the user current language preference settings.
  proc edit_user_language {} {

    if {[preferences::get General/EditPreferencesUsingGUI]} {
      pref_ui::create "" [syntax::get_language [gui::current_txt {}]]
    } else {
      preferences::edit_language
    }

  }

  ######################################################################
  # Edits the session global preference settings.
  proc edit_session_global {} {

    if {[preferences::get General/EditPreferencesUsingGUI]} {
      pref_ui::create [sessions::current] ""
    } else {
      preferences::edit_global [sessions::current]
    }

  }

  ######################################################################
  # Edits the session current language preference settings.
  proc edit_session_language {} {

    if {[preferences::get General/EditPreferencesUsingGUI]} {
      pref_ui::create [sessions::current] [syntax::get_language [gui::current_txt {}]]
    } else {
      preferences::edit_language [sessions::current]
    }

  }

  ######################################################################
  # Edits the user menu bindings (shortcuts) using either the preference
  # GUI (if enabled) or the editor.
  proc bindings_edit_user {} {

    if {[preferences::get General/EditPreferencesUsingGUI]} {
      pref_ui::create "" "" shortcuts
    } else {
      bindings::edit_user
    }

  }

  ######################################################################
  # Adds a new snippet via the preferences GUI or text editor.
  proc add_new_snippet {language} {

    if {[preferences::get General/EditPreferencesUsingGUI]} {
      if {$language eq "user"} {
        pref_ui::create "" "" snippets
      } else {
        pref_ui::create "" [syntax::get_language [gui::current_txt {}]] snippets
      }
    } else {
      snippets::add_new_snippet {} $language
    }

  }

  ######################################################################
  # Edits the sharing setup information using either the preference GUI
  # (if enabled) or the editor.
  proc share_setup {} {

    if {[preferences::get General/EditPreferencesUsingGUI]} {
      pref_ui::create "" "" general sharing
    } else {
      share::edit_setup
    }

  }

  ######################################################################
  # Add the find menu.
  proc add_find {mb} {

    # Add find menu commands
    $mb add command -label [msgcat::mc "Find"] -underline 0 -command [list gui::search {}]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find"]] [list gui::search {}]

    $mb add command -label [msgcat::mc "Find and Replace"] -underline 9 -command [list gui::search_and_replace]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find and Replace"]] [list gui::search_and_replace]

    $mb add separator

    $mb add command -label [msgcat::mc "Select Next Occurrence"] -underline 7 -command [list menus::find_next_command 0]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find next occurrence"]] [list menus::find_next_command 0]

    $mb add command -label [msgcat::mc "Select Previous Occurrence"] -underline 7 -command [list menus::find_prev_command 0]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find previous occurrence"]] [list menus::find_prev_command 0]

    $mb add command -label [msgcat::mc "Select All Occurrences"] -underline 7 -command [list menus::find_all_command]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Select all occurrences"]] [list menus::find_all_command]

    $mb add command -label [msgcat::mc "Append Next Occurrence"] -underline 1 -command [list menus::find_next_command 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Append next occurrence"]] [list menus::find_next_command 1]

    $mb add separator

    $mb add command -label [msgcat::mc "Jump Backward"] -underline 5 -command [list gui::jump_to_cursor {} -1 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Jump backward"]] [list gui::jump_to_cursor {} -1 1]

    $mb add command -label [msgcat::mc "Jump Forward"] -underline 5 -command [list gui::jump_to_cursor {} 1 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Jump forward"]] [list gui::jump_to_cursor {} 1 1]

    $mb add command -label [msgcat::mc "Jump To Line"] -underline 8 -command [list menus::jump_to_line]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Jump to line"]] [list menus::jump_to_line]

    $mb add separator

    $mb add command -label [msgcat::mc "Next Difference"] -underline 0 -command [list gui::jump_to_difference {} 1 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Goto next difference"]] [list gui::jump_to_difference {} 1 1]

    $mb add command -label [msgcat::mc "Previous Difference"] -underline 0 -command [list gui::jump_to_difference {} -1 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Goto previous difference"]] [list gui::jump_to_difference {} -1 1]

    $mb add command -label [msgcat::mc "Show Selected Line Change"] -underline 19 -command [list gui::show_difference_line_change {} 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Show selected line change"]] [list gui::show_difference_line_change {} 1]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Markers"] -underline 5 -menu [make_menu $mb.markerPopup -tearoff 0 -postcommand [list menus::find_marker_posting $mb.markerPopup]]

    $mb add separator

    $mb add command -label [msgcat::mc "Find Matching Bracket"] -underline 5 -command [list gui::show_match_pair {}]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find matching character pair"]] [list gui::show_match_pair {}]

    $mb add separator

    $mb add command -label [msgcat::mc "Find Next Bracket Mismatch"] -command [list completer::goto_mismatch next]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find next mismatching bracket"]] [list completer::goto_mismatch next]

    $mb add command -label [msgcat::mc "Find Previous Bracket Mismatch"] -command [list completer::goto_mismatch prev]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find previous mismatching bracket"]] [list completer::goto_mismatch prev]

    $mb add separator

    $mb add command -label [msgcat::mc "Find In Files"] -underline 5 -command [list search::fif_start]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find in files"]] [list search::fif_start]

    # Add marker popup launchers
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Create marker at current line"]]   [list gui::create_current_marker {}]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Remove marker from current line"]] [list gui::remove_current_marker {}]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Remove all markers"]]              [list gui::remove_all_markers {}]

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
      $mb entryconfigure [msgcat::mc "Find Matching Bracket"]      -state disabled
      $mb entryconfigure [msgcat::mc "Find Next Bracket Mismatch"]     -state disabled
      $mb entryconfigure [msgcat::mc "Find Previous Bracket Mismatch"] -state disabled
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
        $mb entryconfigure [msgcat::mc "Next Difference"]     -state normal
        $mb entryconfigure [msgcat::mc "Previous Difference"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Next Difference"]     -state disabled
        $mb entryconfigure [msgcat::mc "Previous Difference"] -state disabled
      }
      if {[gui::show_difference_line_change {} 0]} {
        $mb entryconfigure [msgcat::mc "Show Selected Line Change"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Show Selected Line Change"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Find Matching Bracket"] -state normal
      if {[completer::goto_mismatch next -check 1]} {
        $mb entryconfigure [msgcat::mc "Find Next Bracket Mismatch"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Find Next Bracket Mismatch"] -state disabled
      }
      if {[completer::goto_mismatch prev -check 1]} {
        $mb entryconfigure [msgcat::mc "Find Previous Bracket Mismatch"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Find Previous Bracket Mismatch"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Markers"] -state normal
    }

  }

  ######################################################################
  # Called when the marker menu is opened.
  proc find_marker_posting {mb} {

    # Clear the menu
    $mb delete 0 end

    # Populate the markerPopup menu
    $mb add command -label [msgcat::mc "Create at Current Line"]   -underline 0 -command [list gui::create_current_marker {}]
    $mb add separator
    $mb add command -label [msgcat::mc "Remove From Current Line"] -underline 0 -command [list gui::remove_current_marker {}]
    $mb add command -label [msgcat::mc "Remove All Markers"]       -underline 7 -command [list gui::remove_all_markers {}]

    if {[llength [set markers [gui::get_marker_list]]] > 0} {
      $mb add separator
      foreach marker $markers {
        lassign $marker name txt pos
        $mb add command -label $name -command [list gui::jump_to_txt $txt $pos]
      }
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
  # Jumps to a line that is entered by the user.
  proc jump_to_line {} {

    set linenum ""

    # Get the line number from the user
    if {[gui::get_user_response [format "%s:" [msgcat::mc "Line Number"]] linenum 0] && [string is integer $linenum]} {
      edit::jump_to_line [gui::current_txt {}].t $linenum.0
    }

  }

  ######################################################################
  # Adds the view menu commands.
  proc add_view {mb} {

    if {[preferences::get View/ShowSidebar]} {
      $mb add command -label [msgcat::mc "Hide Sidebar"] -underline 5 -command [list menus::hide_sidebar_view $mb]
    } else {
      $mb add command -label [msgcat::mc "Show Sidebar"] -underline 5 -command [list menus::show_sidebar_view $mb]
    }
    launcher::register [make_menu_cmd "View" [msgcat::mc "Show sidebar"]] [list menus::show_sidebar_view $mb]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Hide sidebar"]] [list menus::hide_sidebar_view $mb]

    if {![catch "console hide"]} {
      if {[preferences::get View/ShowConsole]} {
        $mb add command -label [msgcat::mc "Hide Console"] -underline 5 -command [list menus::hide_console_view $mb]
      } else {
        $mb add command -label [msgcat::mc "Show Console"] -underline 5 -command [list menus::show_console_view $mb]
      }
      launcher::register [make_menu_cmd "View" [msgcat::mc "Show console"]] [list menus::show_console_view $mb]
      launcher::register [make_menu_cmd "View" [msgcat::mc "Hide console"]] [list menus::hide_console_view $mb]
    }

    if {[preferences::get View/ShowTabBar]} {
      $mb add command -label [msgcat::mc "Hide Tab Bar"] -underline 5 -command [list menus::hide_tab_view $mb]
    } else {
      $mb add command -label [msgcat::mc "Show Tab Bar"] -underline 5 -command [list menus::show_tab_view $mb]
    }
    launcher::register [make_menu_cmd "View" [msgcat::mc "Show tab bar"]] [list menus::show_tab_view $mb]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Hide tab bar"]] [list menus::hide_tab_view $mb]

    if {[preferences::get View/ShowStatusBar]} {
      $mb add command -label [msgcat::mc "Hide Status Bar"] -underline 12 -command [list menus::hide_status_view $mb]
    } else {
      $mb add command -label [msgcat::mc "Show Status Bar"] -underline 12 -command [list menus::show_status_view $mb]
    }
    launcher::register [make_menu_cmd "View" [msgcat::mc "Show status bar"]] [list menus::show_status_view $mb]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Hide status bar"]] [list menus::hide_status_view $mb]

    $mb add separator

    if {[preferences::get View/ShowLineNumbers]} {
      $mb add command -label [msgcat::mc "Hide Line Numbers"] -underline 5 -command [list menus::hide_line_numbers $mb]
    } else {
      $mb add command -label [msgcat::mc "Show Line Numbers"] -underline 5 -command [list menus::show_line_numbers $mb]
    }
    launcher::register [make_menu_cmd "View" [msgcat::mc "Show line numbers"]] [list menus::show_line_numbers $mb]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Hide line numbers"]] [list menus::hide_line_numbers $mb]

    $mb add cascade -label [msgcat::mc "Line Numbering"] -menu [make_menu $mb.numPopup -tearoff 0]

    $mb add separator

    if {[preferences::get View/ShowMarkerMap]} {
      $mb add command -label [msgcat::mc "Hide Marker Map"] -underline 8 -command [list menus::hide_marker_map $mb]
    } else {
      $mb add command -label [msgcat::mc "Show Marker Map"] -underline 8 -command [list menus::show_marker_map $mb]
    }
    launcher::register [make_menu_cmd "View" [msgcat::mc "Show marker map"]] [list menus::show_marker_map $mb]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Hide marker map"]] [list menus::hide_marker_map $mb]

    $mb add command -label [msgcat::mc "Hide Meta Characters"] -underline 5 -command [list menus::hide_meta_chars $mb]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Show meta characters"]] [list menus::show_meta_chars $mb]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Hide meta characters"]] [list menus::hide_meta_chars $mb]

    $mb add separator

    $mb add command -label [msgcat::mc "Display Text Info"] -underline 13 -command [list menus::display_text_info]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Display text information"]] [list menus::display_text_info]

    $mb add separator

    $mb add checkbutton -label [msgcat::mc "Split View"] -underline 6 -variable menus::show_split_pane -command [list gui::toggle_split_pane {}]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Toggle split view mode"]] [list gui::toggle_split_pane {}]

    $mb add command -label [msgcat::mc "Move to Other Pane"] -underline 0 -command [list gui::move_to_pane]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Move to other pane"]] [list gui::move_to_pane]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Panes"]   -underline 0 -menu [make_menu $mb.panePopup -tearoff 0]
    $mb add cascade -label [msgcat::mc "Tabs"]    -underline 0 -menu [make_menu $mb.tabPopup  -tearoff 0 -postcommand "menus::view_tabs_posting $mb.tabPopup"]
    $mb add cascade -label [msgcat::mc "Folding"] -underline 0 -menu [make_menu $mb.foldPopup -tearoff 0 -postcommand "menus::view_fold_posting $mb.foldPopup"]

    $mb add separator

    if {[tk windowingsystem] ne "aqua"} {
      $mb add cascade -label [msgcat::mc "Set Syntax"] -underline 9 \
        -menu [make_menu $mb.syntaxMenu -tearoff 0 -postcommand "syntax::populate_syntax_menu $mb.syntaxMenu syntax::set_current_language syntax::current_lang [msgcat::mc None]"]
    }

    $mb add cascade -label [msgcat::mc "Set Theme"]  -underline 7 -menu [make_menu $mb.themeMenu  -tearoff 0 -postcommand "themes::populate_theme_menu $mb.themeMenu"]

    # Setup the line numbering popup menu
    $mb.numPopup add radiobutton -label [msgcat::mc "Absolute"] -variable menus::line_numbering -value absolute -command [list menus::set_line_numbering absolute]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Absolute line numbering"]] [list menus::set_line_numbering absolute]

    $mb.numPopup add radiobutton -label [msgcat::mc "Relative"] -variable menus::line_numbering -value relative -command [list menus::set_line_numbering relative]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Relative line numbering"]] [list menus::set_line_numbering relative]

    # Setup the pane popup menu
    $mb.panePopup add checkbutton -label [msgcat::mc "Enable Synchronized Scrolling"] -variable menus::sync_panes -command [list menus::sync_panes]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Enable two-pane scrolling synchronization"]]  [list gui::set_pane_sync 1]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Disable two-pane scrolling Synchronization"]] [list gui::set_pane_sync 0]

    $mb.panePopup add command -label [msgcat::mc "Align Panes"] -command [list gui::align_panes]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Align current lines in both panes"]] [list gui::align_panes]

    $mb.panePopup add separator

    $mb.panePopup add command -label [msgcat::mc "Merge Panes"] -underline 3 -command [list gui::merge_panes]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Merge panes"]] [list gui::merge_panes]

    # Setup the tab popup menu
    $mb.tabPopup add command -label [msgcat::mc "Goto Next Tab"] -underline 5 -command [list gui::next_tab]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Goto next tab"]] [list gui::next_tab]

    $mb.tabPopup add command -label [msgcat::mc "Goto Previous Tab"] -underline 5 -command [list gui::previous_tab]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Goto previous tab"]] [list gui::previous_tab]

    $mb.tabPopup add command -label [msgcat::mc "Goto Last Tab"] -underline 5 -command [list gui::last_tab]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Goto last tab"]] [list gui::last_tab]

    $mb.tabPopup add command -label [msgcat::mc "Goto Other Pane"] -underline 11 -command [list gui::next_pane]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Goto other pane"]] [list gui::next_pane]

    $mb.tabPopup add separator

    $mb.tabPopup add command -label [msgcat::mc "Sort Tabs"] -underline 0 -command [list gui::sort_tabs]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Sort tabs"]] [list gui::sort_tabs]

    $mb.tabPopup add separator

    $mb.tabPopup add command -label [msgcat::mc "Hide Current Tab"] -underline 5 -command [list gui::hide_current {}]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Hide Current Tab"]] [list gui::hide_current {}]

    $mb.tabPopup add command -label [msgcat::mc "Hide All Tabs"] -underline 5 -command [list gui::hide_all]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Hide All Tabs"]] [list gui::hide_all]

    $mb.tabPopup add command -label [msgcat::mc "Show All Tabs"] -underline 0 -command [list gui::show_all]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Show All Tabs"]] [list gui::show_all]

    # Setup the folding popup menu
    $mb.foldPopup add checkbutton -label [msgcat::mc "Enable Code Folding"] -variable menus::code_folding -command [list menus::set_code_folding]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Enable code folding"]]  [list menus::set_code_folding 1]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Disable code folding"]] [list menus::set_code_folding 0]

    $mb.foldPopup add separator

    $mb.foldPopup add command -label [msgcat::mc "Create Fold From Selection"] -command [list menus::add_fold_from_selection]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Create fold from selection"]] [list menus::add_fold_from_selection]

    $mb.foldPopup add separator

    $mb.foldPopup add command -label [msgcat::mc "Delete Current Fold"] -command [list menus::delete_folds current]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Delete fold at current line"]] [list menus::delete_folds current]

    $mb.foldPopup add command -label [msgcat::mc "Delete Selected Folds"] -command [list menus::delete_folds selected]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Delete all selected folds"]] [list menus::delete_folds selected]

    $mb.foldPopup add command -label [msgcat::mc "Delete All Folds"] -command [list menus::delete_folds all]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Delete all folds"]] [list menus::delete_folds all]

    $mb.foldPopup add separator

    $mb.foldPopup add cascade -label [msgcat::mc "Close Current Fold"] -menu [make_menu $mb.fcloseCurrPopup -tearoff 0]

    $mb.foldPopup add cascade -label [msgcat::mc "Close Selected Folds"] -menu [make_menu $mb.fcloseSelPopup -tearoff 0]

    $mb.foldPopup add command -label [msgcat::mc "Close All Folds"] -command [list menus::close_folds all]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Close all folds"]] [list menus::close_folds all]

    $mb.foldPopup add separator

    $mb.foldPopup add cascade -label [msgcat::mc "Open Current Fold"] -menu [make_menu $mb.fopenCurrPopup -tearoff 0]

    $mb.foldPopup add cascade -label [msgcat::mc "Open Selected Folds"] -menu [make_menu $mb.fopenSelPopup -tearoff 0]

    $mb.foldPopup add command -label [msgcat::mc "Open All Folds"] -command [list menus::open_folds all]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Open all folds"]] [list menus::open_folds all]

    $mb.foldPopup add separator

    $mb.foldPopup add command -label [msgcat::mc "Show Cursor"] -command [list menus::open_folds show]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Open folds to show cursor"]] [list menus::open_folds show]

    $mb.foldPopup add separator

    $mb.foldPopup add command -label [msgcat::mc "Jump to Next Fold Mark"] -command [list menus::jump_to_fold next]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Jump to the next fold indicator"]] [list menus::jump_to_fold next]

    $mb.foldPopup add command -label [msgcat::mc "Jump to Previous Fold Mark"] -command [list menus::jump_to_fold prev]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Jump to the previous fold indicator"]] [list menus::jump_to_fold prev]

    # Setup the folding close current popup menu
    $mb.fcloseCurrPopup add command -label [msgcat::mc "One Level"]  -command [list menus::close_folds current 1]
    $mb.fcloseCurrPopup add command -label [msgcat::mc "All Levels"] -command [list menus::close_folds current 0]

    launcher::register [make_menu_cmd "View" [msgcat::mc "Close fold at current line - one level"]]  [list menus::close_folds current 1]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Close fold at current line - all levels"]] [list menus::close_folds current 0]

    # Setup the folding close selected popup menu
    $mb.fcloseSelPopup add command -label [msgcat::mc "One Level"]  -command [list menus::close_folds selected 1]
    $mb.fcloseSelPopup add command -label [msgcat::mc "All Levels"] -command [list menus::close_folds selected 0]

    launcher::register [make_menu_cmd "View" [msgcat::mc "Close selected folds - one level"]]  [list menus::close_folds selected 1]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Close selected folds - all levels"]] [list menus::close_folds selected 0]

    # Setup the folding open current popup menu
    $mb.fopenCurrPopup add command -label [msgcat::mc "One Level"]  -command [list menus::open_folds current 1]
    $mb.fopenCurrPopup add command -label [msgcat::mc "All Levels"] -command [list menus::open_folds current 0]

    launcher::register [make_menu_cmd "View" [msgcat::mc "Open fold at current line - one level"]]  [list menus::open_folds current 1]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Open fold at current line - all levels"]] [list menus::open_folds current 0]

    # Setup the folding open selected popup menu
    $mb.fopenSelPopup add command -label [msgcat::mc "One Level"]  -command [list menus::open_folds selected 1]
    $mb.fopenSelPopup add command -label [msgcat::mc "All Levels"] -command [list menus::open_folds selected 0]

    launcher::register [make_menu_cmd "View" [msgcat::mc "Open selected folds - one level"]]  [list menus::open_folds selected 1]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Open selected folds - all levels"]] [list menus::open_folds selected 0]

  }

  ######################################################################
  # Called just prior to posting the view menu.  Sets the state of the
  # menu options to match the current UI state.
  proc view_posting {mb} {

    variable show_split_pane
    variable line_numbering

    if {([gui::tabs_in_pane] < 2) && ([gui::panes] < 2)} {
      $mb entryconfigure [msgcat::mc "Tabs"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Tabs"] -state normal
    }

    if {[gui::panes] < 2} {
      $mb entryconfigure [msgcat::mc "Panes"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Panes"] -state normal
    }

    if {[gui::current_txt {}] eq ""} {
      catch { $mb entryconfigure [msgcat::mc "Show Line Numbers"]    -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Hide Line Numbers"]    -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Line Numbering"]       -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Show Marker Map"]      -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Hide Marker Map"]      -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Show Meta Characters"] -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Hide Meta Characters"] -state disabled }
      $mb entryconfigure [msgcat::mc "Display Text Info"]  -state disabled
      $mb entryconfigure [msgcat::mc "Split View"]         -state disabled
      $mb entryconfigure [msgcat::mc "Move to Other Pane"] -state disabled
      if {[tk windowingsystem] ne "aqua"} {
        $mb entryconfigure [msgcat::mc "Set Syntax"]         -state disabled
      }
      $mb entryconfigure [msgcat::mc "Folding"]            -state disabled
    } else {
      catch { $mb entryconfigure [msgcat::mc "Show Line Numbers"]  -state normal }
      catch { $mb entryconfigure [msgcat::mc "Hide Line Numbers"]  -state normal }
      catch { $mb entryconfigure [msgcat::mc "Line Numbering"]     -state normal }
      if {[markers::exist [gui::current_txt {}]]} {
        catch { $mb entryconfigure [msgcat::mc "Show Marker Map"] -state normal }
        catch { $mb entryconfigure [msgcat::mc "Hide Marker Map"] -state normal }
      } else {
        catch { $mb entryconfigure [msgcat::mc "Show Marker Map"] -state disabled }
        catch { $mb entryconfigure [msgcat::mc "Hide Marker Map"] -state disabled }
      }
      if {[syntax::contains_meta_chars [gui::current_txt {}]]} {
        catch { $mb entryconfigure [msgcat::mc "Show Meta Characters"] -state normal }
        catch { $mb entryconfigure [msgcat::mc "Hide Meta Characters"] -state normal }
      } else {
        catch { $mb entryconfigure [msgcat::mc "Show Meta Characters"] -state disabled }
        catch { $mb entryconfigure [msgcat::mc "Hide Meta Characters"] -state disabled }
      }
      $mb entryconfigure [msgcat::mc "Display Text Info"] -state normal
      $mb entryconfigure [msgcat::mc "Split View"]        -state normal
      if {[gui::movable_to_other_pane]} {
        $mb entryconfigure [msgcat::mc "Move to Other Pane"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Move to Other Pane"] -state disabled
      }
      if {[tk windowingsystem] ne "aqua"} {
        $mb entryconfigure [msgcat::mc "Set Syntax"] -state normal
      }
      $mb entryconfigure [msgcat::mc "Folding"]    -state normal
      set show_split_pane [expr {[llength [[gui::current_txt {}] peer names]] > 0}]
    }

    # Get the current line numbering
    set line_numbering [[gui::current_txt {}] cget -linemap_type]

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
  # Called just prior to posting the view/folding menu.  Sets the state
  # fo the menu options to match the current UI state.
  proc view_fold_posting {mb} {

    variable code_folding

    # Get the current text widget
    set txt          [gui::current_txt {}]
    set state        [folding::fold_state $txt [lindex [split [$txt index insert] .] 0]]
    set code_folding [folding::get_enable $txt]
    set sel_state    [expr {([$txt tag ranges sel] ne "") ? "normal" : "disabled"}]

    if {[folding::get_method $txt] eq "manual"} {
      $mb entryconfigure [msgcat::mc "Create Fold From Selection"] -state $sel_state
      $mb entryconfigure [msgcat::mc "Delete Selected Folds"]      -state $sel_state
      $mb entryconfigure [msgcat::mc "Delete Current Fold"]        -state normal
      $mb entryconfigure [msgcat::mc "Delete All Folds"]           -state normal
    } else {
      $mb entryconfigure [msgcat::mc "Create Fold From Selection"] -state disabled
      $mb entryconfigure [msgcat::mc "Delete Selected Folds"]      -state disabled
      $mb entryconfigure [msgcat::mc "Delete Current Fold"]        -state disabled
      $mb entryconfigure [msgcat::mc "Delete All Folds"]           -state disabled
    }

    $mb entryconfigure [msgcat::mc "Close Selected Folds"] -state $sel_state
    $mb entryconfigure [msgcat::mc "Open Selected Folds"]  -state $sel_state

    if {$state eq "open"} {
      $mb entryconfigure [msgcat::mc "Close Current Fold"] -state normal
    } else {
      $mb entryconfigure [msgcat::mc "Close Current Fold"] -state disabled
    }

    if {$state eq "close"} {
      $mb entryconfigure [msgcat::mc "Open Current Fold"] -state normal
    } else {
      $mb entryconfigure [msgcat::mc "Open Current Fold"] -state disabled
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
  # Sets the line numbering for the current editing buffer to either
  # 'absolute' or 'relative'.
  proc set_line_numbering {type} {

    [gui::current_txt {}] configure -linemap_type $type

  }

  ######################################################################
  # Shows the marker map for the current edit window.
  proc show_marker_map {mb} {

    # Convert the menu command into the hide marker map command
    if {![catch {$mb entryconfigure [msgcat::mc "Show Marker Map"] -label [msgcat::mc "Hide Marker Map"] -command "menus::hide_marker_map $mb"}]} {
      [winfo parent [gui::current_txt {}]].vb configure -markhide1 0
    }

  }

  ######################################################################
  # Hides the marker map for the current edit window.
  proc hide_marker_map {mb} {

    # Convert the menu command into the show marker map command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Marker Map"] -label [msgcat::mc "Show Marker Map"] -command "menus::show_marker_map $mb"}]} {
      [winfo parent [gui::current_txt {}]].vb configure -markhide1 1
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
  # Display the line and character counts in the information bar.
  proc display_text_info {} {

    gui::display_file_counts [gui::current_txt {}].t

  }

  ######################################################################
  # Enables/disables two-pane scroll synchronization.
  proc sync_panes {} {

    variable sync_panes

    gui::set_pane_sync $sync_panes

  }

  ######################################################################
  # Disables code folding from being drawn.
  proc set_code_folding {{value ""}} {

    variable code_folding

    # Get the current text widget
    set txt [gui::current_txt {}]

    # Set the fold enable value
    if {$value eq ""} {
      folding::set_fold_enable $txt $code_folding
    } else {
      folding::set_fold_enable $txt [set code_folding $value]
    }

  }

  ######################################################################
  # Create a fold for the selected code and close the fold.
  proc add_fold_from_selection {} {

    folding::close_selected [gui::current_txt {}]

  }

  ######################################################################
  # Delete one or more folds based on type.  Valid values for type are:
  #  - current  (deletes fold at the current line)
  #  - selected (deletes any selected folds)
  #  - all      (deletes all folds)
  proc delete_folds {type} {

    set txt [gui::current_txt {}]

    switch $type {
      current  { folding::delete_fold $txt [lindex [split [$txt index insert] .] 0] }
      all      { folding::delete_all_folds $txt }
      selected {
        foreach {startpos endpos} [$txt tag ranges sel] {
          set startline [lindex [split $startpos .] 0]
          set endline   [lindex [split $endpos   .] 0]
          folding::delete_folds_in_range $txt $startline $endline
        }
      }
    }

  }

  ######################################################################
  # Closes one or more folds based on type and depth.  Valid values for
  # type are:
  #  - current  (closes fold at the current line)
  #  - selected (closes any selected folds)
  #  - all      (closes all folds)
  proc close_folds {type {depth 0}} {

    set txt [gui::current_txt {}]

    switch $type {
      current  { folding::close_fold $depth $txt [lindex [split [$txt index insert] .] 0] }
      all      { folding::close_all_folds $txt }
      selected {
        foreach {startpos endpos} [$txt tag ranges sel] {
          set startline [lindex [split $startpos .] 0]
          set endline   [lindex [split $endpos   .] 0]
          folding::close_folds_in_range $txt $startline $endline $depth
        }
      }
    }

  }

  ######################################################################
  # Opens one or more folds based on type and depth.  Valid values for
  # type are:
  #  - current  (opens fold at the current line)
  #  - selected (opens any selected folds)
  #  - all      (opens all folds)
  proc open_folds {type {depth 0}} {

    set txt [gui::current_txt {}]

    switch $type {
      current  { folding::open_fold $depth $txt [lindex [split [$txt index insert] .] 0] }
      all      { folding::open_all_folds $txt }
      show     { folding::show_line $txt [lindex [split [$txt index insert] .] 0] }
      selected {
        foreach {startpos endpos} [$txt tag ranges sel] {
          set startline [lindex [split $startpos .] 0]
          set endline   [lindex [split $endpos   .] 0]
          folding::open_folds_in_range $txt $startline $endline $depth
        }
      }
    }

  }

  ######################################################################
  # Jump to the fold indicator in the given direction from the current
  # cursor position.
  proc jump_to_fold {dir} {

    folding::jump_to [gui::current_txt {}] $dir

  }

  ######################################################################
  # Adds the tools menu commands.
  proc add_tools {mb} {

    # Add tools menu commands
    $mb add command -label [msgcat::mc "Launcher"] -underline 0 -command [list launcher::launch]

    $mb add command -label [msgcat::mc "Theme Editor"] -underline 0 -command [list menus::theme_edit_command]
    launcher::register [make_menu_cmd "Tools" [msgcat::mc "Run theme editor"]] [list menus::theme_edit_command]

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

      puts "Turning profiling off!"
      puts [utils::stacktrace]

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
      puts $rc [format "                                  %s (%s)" [msgcat::mc "Profiling Report Sorted By"] [preferences::get Tools/ProfileReportSortby]]
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
  # Runs bist.
  proc run_bist {} {

    # Source the bist.tcl file
    uplevel #0 [list source [file join $::tke_dir lib bist.tcl]]

    # Run bist
    bist::create

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
    $mb add cascade -label [msgcat::mc "Switch To"] -menu [make_menu $mb.switch -tearoff false]
    launcher::register [make_menu_cmd "Sessions" [msgcat::mc "Switch to session"]] [list menus::sessions_switch_launcher]

    $mb add separator

    $mb add command -label [msgcat::mc "Close Current"] -underline 0 -command [list menus::sessions_close_current]
    launcher::register [make_menu_cmd "Sessions" [msgcat::mc "Close current session"]] [list menus::sessions_close_current]

    $mb add separator

    $mb add command -label [msgcat::mc "Save Current"] -underline 0 -command [list menus::sessions_save_current]
    launcher::register [make_menu_cmd "Sessions" [msgcat::mc "Save current session"]] [list menus::sessions_save_current]

    $mb add command -label [msgcat::mc "Save As"] -underline 5 -command [list menus::sessions_save_as]
    launcher::register [make_menu_cmd "Sessions" [msgcat::mc "Save sessions as"]] [list menus::sessions_save_as]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Delete"] -menu [make_menu $mb.delete -tearoff false]
    launcher::register [make_menu_cmd "Sessions" [msgcat::mc "Delete session"]] [list menus::sessions_delete_launcher]

  }

  ######################################################################
  # Called when the sessions menu is posted.
  proc sessions_posting {mb} {

    # Get the list of sessions names
    set names [sessions::get_names]

    # Update the open, switch to, and delete menus
    $mb.switch delete 0 end
    $mb.delete delete 0 end

    foreach name $names {
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
      $mb entryconfigure [msgcat::mc "Switch To"] -state disabled
      $mb entryconfigure [msgcat::mc "Delete"]    -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Switch To"] -state normal
      $mb entryconfigure [msgcat::mc "Delete"]    -state normal
    }

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

    sessions::close_current

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
    $mb add command -label [format "%s..." [msgcat::mc "Install"]] -underline 0 -command [list plugins::install]
    launcher::register [make_menu_cmd "Plugins" [msgcat::mc "Install plugin"]] [list plugins::install]

    $mb add command -label [format "%s..." [msgcat::mc "Uninstall"]] -underline 0 -command [list plugins::uninstall]
    launcher::register [make_menu_cmd "Plugins" [msgcat::mc "Uninstall plugin"]] [list plugins::uninstall]

    $mb add command -label [format "%s..." [msgcat::mc "Show Installed"]] -underline 0 -command [list plugins::show_installed]
    launcher::register [make_menu_cmd "Plugins" [msgcat::mc "Show installed plugins"]] [list plugins::show_installed]

    $mb add command -label [msgcat::mc "Reload"] -underline 0 -command [list plugins::reload]
    launcher::register [make_menu_cmd "Plugins" [msgcat::mc "Reload all plugins"]] [list plugins::reload]

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

    $mb add command -label [msgcat::mc "User Guide"] -underline 0 -command [list menus::help_user_guide]
    launcher::register [make_menu_cmd "Help" [msgcat::mc "View user guide"]] [list menus::help_user_guide]

    $mb add command -label [msgcat::mc "Tips & Tricks"] -underline 0 -command [list menus::help_tips_tricks]
    launcher::register [make_menu_cmd "Help" [msgcat::mc "View tips & tricks articles"]] [list menus::help_tips_tricks]

    if {![string match *Win* $::tcl_platform(os)]} {
      $mb add separator
      $mb add command -label [msgcat::mc "Check for Update"] -underline 0 -command [list menus::check_for_update]
      launcher::register [make_menu_cmd "Help" [msgcat::mc "Check for update"]] [list menus::check_for_update]
    }

    $mb add separator

    $mb add command -label [msgcat::mc "Send Feedback"] -underline 5 -command [list menus::help_feedback_command]
    launcher::register [make_menu_cmd "Help" [msgcat::mc "Send feedback"]] [list menus::help_feedback_command]

    $mb add command -label [msgcat::mc "Send Bug Report"] -underline 5 -command [list menus::help_submit_report]
    launcher::register [make_menu_cmd "Help" [msgcat::mc "Send bug report"]] [list menus::help_submit_report]

    if {[tk windowingsystem] ne "aqua"} {
      $mb add separator
      $mb add command -label [format "%s %s" [msgcat::mc "About"] "TKE"] -underline 0 -command [list gui::show_about]
      launcher::register [make_menu_cmd "Help" [format "%s %s" [msgcat::mc "About"] "TKE"]] [list gui::show_about]
    }

  }

  ######################################################################
  # Displays the User Guide.  First, attempts to show the epub version.
  # If that fails, display the pdf version.
  proc help_user_guide {} {

    if {[preferences::get Help/UserGuideFormat] eq "pdf"} {
      utils::open_file_externally [file join $::tke_dir doc UserGuide.pdf] 1
    } else {
      utils::open_file_externally [file join $::tke_dir doc UserGuide.epub] 1
    }

  }

  ######################################################################
  # Launches the web browser, displaying the Tips & Tricks blog articles.
  proc help_tips_tricks {} {

    utils::open_file_externally "http://tkeeditor.wordpress.com"

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
    utils::open_file_externally "mailto:phase1geo@gmail.com?subject=Bug Report for TKE&body=$body" 1

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

