# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2017  Trevor Williams (phase1geo@gmail.com)
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
  variable show_birdseye   0
  variable indent_mode     "IND+"
  variable last_devel_mode ""
  variable line_numbering  "absolute"
  variable code_folding    0
  variable line_wrapping   0
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

    # If the menubar is disabled, don't allow any menu invocations
    if {[.menubar entrycget 0 -state] eq "disabled"} {
      return
    }

    # If the menu contains a postcommand, execute it first
    if {[$mnu cget -postcommand] ne ""} {
      eval [$mnu cget -postcommand]
    }

    # Next, invoke the menu
    $mnu invoke $index

  }

  ######################################################################
  # Sets the given state on all menus in the menubar.
  proc set_state {state} {

    set last [.menubar index end]

    for {set i 0} {$i <= $last} {incr i} {
      .menubar entryconfigure $i -state $state
    }

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
        $mb add command -label [msgcat::mc "Export Custom Themes"] -command [list themes::export_custom]
        $mb add separator
        $mb add command -label [msgcat::mc "Start Profiling"]            -underline 0 -command "menus::start_profiling_command $mb"
        $mb add command -label [msgcat::mc "Stop Profiling"]             -underline 1 -command "menus::stop_profiling_command $mb 1" -state disabled
        $mb add command -label [msgcat::mc "Show Last Profiling Report"] -underline 5 -command "menus::show_last_profiling_report"
        $mb add separator
        $mb add command -label [msgcat::mc "Show Diagnostic Logfile"]    -underline 5 -command "logger::view_log"
        if {[preferences::get View/ShowConsole]} {
          $mb add command -label [msgcat::mc "Hide Tcl Console"] -underline 5 -command [list menus::hide_console_view $mb]
        } else {
          $mb add command -label [msgcat::mc "Show Tcl Console"] -underline 5 -command [list menus::show_console_view $mb]
        }
        $mb add separator
        $mb add command -label [format "%s %s" [msgcat::mc "Run"] "BIST"] -underline 4 -command "menus::run_bist"
        $mb add separator
        $mb add command -label [format "%s %s" [msgcat::mc "Restart"] "TKE"] -underline 0 -command "menus::restart_command"

        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Export Custom Themes"]]           [list themes::export_custom]
        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Start profiling"]]                [list menus::start_profiling_command $mb]
        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Stop profiling"]]                 [list menus::stop_profiling_command $mb 1]
        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Show last profiling report"]]     [list menus::show_last_profiling_report]
        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Show diagnostic logfile"]]        [list logger::view_log]
        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Show Tcl console"]]               [list menus::show_console_view $mb]
        launcher::register [make_menu_cmd "Tools" [msgcat::mc "Hide Tcl console"]]               [list menus::hide_console_view $mb]
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

        set mb ".menubar.help"
        $mb insert 2 separator
        $mb insert 3 command -label [msgcat::mc "Plugin Developer Guide"] -underline 0 -command [list menus::help_devel_guide]

        launcher::register [make_menu_cmd "Help" [msgcat::mc "Show plugin developer guide"]] [list menus::help_devel_guide]

      } elseif {$last_devel_mode ne ""} {

        set mb    ".menubar.tools"
        set index [$mb index [msgcat::mc "Start Profiling"]]
        $mb delete [expr $index - 1] end
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Start profiling"]] * *
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Stop profiling"]] * *
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Show last profiling report"]] * *
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Show diagnostic logfile"]] * *
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Show Tcl console"]] * *
        launcher::unregister [make_menu_cmd "Tools" [msgcat::mc "Hide Tcl console"]] * *
        launcher::unregister [make_menu_cmd "Tools" [format "%s %s" [msgcat::mc "Run"] "BIST"]] * *
        launcher::unregister [make_menu_cmd "Tools" [format "%s %s" [msgcat::mc "Restart"] "TKE"]] * *

        set mb ".menubar.plugins"
        $mb delete 3 4
        launcher::unregister [make_menu_cmd "Plugins" [msgcat::mc "Create new plugin"]] * *

        set mb ".menubar.help"
        $mb delete 2 3
        launcher::unregister [make_menu_cmd "Help" [msgcat::mc "Show plugin developer guide"]] * *

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

    # If we are running on Mac OS X, add the window menu with the windowlist package
    if {[tk windowingsystem] eq "aqua"} {

      # Add the window menu with the windowlist package
      windowlist::windowMenu $mb

      # Add the launcher command to show the about window
      launcher::register [make_menu_cmd "Help" [format "%s %s" [msgcat::mc "About"] "TKE"]] gui::show_about

    }

    # Add the help menu
    $mb add cascade -label [msgcat::mc "Help"] -menu [make_menu $mb.help -tearoff false -postcommand "menus::help_posting $mb.help"]
    add_help $mb.help

    if {([tk windowingsystem] eq "aqua") || [preferences::get View/ShowMenubar]} {
      . configure -menu $mb
    }

    # Handle the default development mode
    handle_development_mode

    # Load and apply the menu bindings
    bindings::load

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

    pref_ui::create "" "" shortcuts
    pref_ui::shortcut_edit_item [string map {# .} [lindex [split $w .] end]] [$w entrycget @$y -label]

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
    if {![catch { gui::get_info {} current fileindex fname readonly lock diff buffer modified remote }]} {

      # Get state if the file is a buffer
      set buffer_state [expr {($buffer || $diff) ? "disabled" : "normal"}]

      # Get the state if the current editing buffer is a difference buffer
      set diff_state [expr {$diff ? "disabled" : "normal"}]

      # Get the state for items that are not valid for remote files
      set no_remote_state [expr {($remote eq "") ? $buffer_state : "disabled"}]

      # Get the current favorite status
      set favorite [favorites::is_favorite $fname]

      # Configure the Lock/Unlock menu item
      if {$lock} {
        if {![catch { $mb index [msgcat::mc "Lock"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Unlock"] -state $diff_state -command "menus::unlock_command $mb"
        }
        $mb entryconfigure [msgcat::mc "Unlock"] -state [expr {$readonly ? "disabled" : $diff_state}]
      } else {
        if {![catch { $mb index [msgcat::mc "Unlock"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Lock"] -state $diff_state -command "menus::lock_command $mb"
        }
        $mb entryconfigure [msgcat::mc "Lock"] -state [expr {$readonly ? "disabled" : $diff_state}]
      }

      # Configure the Favorite/Unfavorite menu item
      if {$favorite} {
        if {![catch { $mb index [msgcat::mc "Favorite"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Unfavorite"] -command "menus::unfavorite_command $mb"
        }
        $mb entryconfigure [msgcat::mc "Unfavorite"] -state [expr {(($fname ne "") && !$diff) ? $no_remote_state : "disabled"}]
      } else {
        if {![catch { $mb index [msgcat::mc "Unfavorite"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Favorite"] -command "menus::favorite_command $mb"
        }
        $mb entryconfigure [msgcat::mc "Favorite"] -state [expr {(($fname ne "") && !$diff) ? $no_remote_state : "disabled"}]
      }

      # Configure the Delete/Move To Trash
      if {($remote eq "") && [preferences::get General/UseMoveToTrash]} {
        if {![catch { $mb index [msgcat::mc "Delete"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Move To Trash"] -command [list menus::move_to_trash_command]
        }
        $mb entryconfigure [msgcat::mc "Move To Trash"] -state $buffer_state
      } else {
        if {![catch { $mb index [msgcat::mc "Move To Trash"] } index]} {
          $mb entryconfigure $index -label [msgcat::mc "Delete"] -command [list menus::delete_command]
        }
        $mb entryconfigure [msgcat::mc "Delete"] -state $buffer_state
      }

      # Make sure that the file-specific items are enabled
      $mb entryconfigure [msgcat::mc "Reopen File"]                        -state $buffer_state
      $mb entryconfigure [msgcat::mc "Show File Difference"]               -state $no_remote_state
      $mb entryconfigure [msgcat::mc "Save"]                               -state [expr {$modified ? $diff_state : "disabled"}]
      $mb entryconfigure [format "%s..." [msgcat::mc "Save As"]]           -state $diff_state
      $mb entryconfigure [format "%s..." [msgcat::mc "Save As Remote"]]    -state $diff_state
      $mb entryconfigure [format "%s..." [msgcat::mc "Save As Template"]]  -state $diff_state
      $mb entryconfigure [format "%s..." [msgcat::mc "Save Selection As"]] -state [expr {[gui::selected] ? "normal" : "disabled"}]
      $mb entryconfigure [msgcat::mc "Save All"]                           -state normal
      $mb entryconfigure [format "%s..." [msgcat::mc "Export"]]            -state $diff_state
      $mb entryconfigure [msgcat::mc "Line Ending"]                        -state $diff_state
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
    gui::get_info {} current fname

    # Display the current file as a difference
    gui::add_file end $fname -diff 1 -other [preferences::get View/ShowDifferenceInOtherPane]

  }

  ######################################################################
  # Saves the current tab file.
  proc save_command {} {

    gui::save_current -force 1

  }

  ######################################################################
  # Saves the current tab file as a new filename.
  proc save_as_command {} {

    # Get some of the save options
    if {[set sfile [gui::prompt_for_save]] ne ""} {
      gui::save_current -force 1 -save_as $sfile
    }

  }

  ######################################################################
  # Saves the current tab file as a new filename on a remote server.
  proc save_as_remote_command {} {

    set fname [file tail [gui::get_info {} current fname]]

    lassign [remote::create save $fname] connection sfile

    if {$sfile ne ""} {
      gui::save_current -force 1 -save_as $sfile -remote $connection
    }

  }

  ######################################################################
  # Saves the currently selected text to a new file.
  proc save_selection_as_command {} {

    # Get the filename
    if {[set sfile [gui::prompt_for_save]] ne ""} {

      # Get the current text widget
      set txt [gui::current_txt]

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
    set txt [gui::current_txt]

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

    # Get the scrubbed contents of the current buffer
    set contents [gui::scrub_text $txt]

    # Export the string contents
    if {[catch { utils::export $contents $lang $fname } rc]} {
      gui::set_error_message [msgcat::mc "Unable to write export file"]
      return
    }

    # Let the user know that the operation has completed
    gui::set_info_message [msgcat::mc "Export complete"]

  }

  ######################################################################
  # Renames the current file.
  proc rename_command {} {

    # Get the current name
    gui::get_info {} current fname remote

    set old_name $fname
    set new_name $fname
    set selrange [utils::basename_range $fname]

    # Get the new name from the user
    if {[gui::get_user_response [msgcat::mc "File Name:"] new_name -allow_vars 1 -selrange $selrange]} {

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
    gui::get_info {} current fname remote

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
    gui::get_info {} current fname remote

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
    gui::get_info {} current fname

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
    if {[gui::set_current_file_lock 1]} {

      # Set the menu up to display the unlock file menu option
      $mb entryconfigure [msgcat::mc "Lock"] -label [msgcat::mc "Unlock"] -command "menus::unlock_command $mb"

    }

  }

  ######################################################################
  # Unlocks the current file.
  proc unlock_command {mb} {

    # Unlock the current file
    if {[gui::set_current_file_lock 0]} {

      # Set the menu up to display the lock file menu option
      $mb entryconfigure [msgcat::mc "Unlock"] -label [msgcat::mc "Lock"] -command "menus::lock_command $mb"

    }

  }

  ######################################################################
  # Marks the current file as a favorite.
  proc favorite_command {mb} {

    # Get current file information
    gui::get_info {} current fileindex fname

    # Get the current file index (if one exists)
    if {$fileindex != -1} {

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
    gui::get_info {} current fileindex fname

    # Get the current file index (if one exists)
    if {$fileindex != -1} {

      # Remove the file as a favorite
      if {[favorites::remove $fname]} {

        $mb entryconfigure [msgcat::mc "Unfavorite"] -label [msgcat::mc "Favorite"] -command "menus::favorite_command $mb"

      }

    }

  }

  ######################################################################
  # Closes the current tab.
  proc close_command {} {

    gui::close_current

  }

  ######################################################################
  # Closes all opened tabs.
  proc close_all_command {} {

    gui::close_all -force 1

  }

  ######################################################################
  # Cleans up the application to prepare it for being exited.
  proc exit_cleanup {} {

    # Close the themer if it is open
    themer::close_window 1

    # Save the session information if we are not told to exit on close
    sessions::save "last"

    # Close all of the tabs
    gui::close_all -force 1 -exiting 1

    # Destroy the ctext namespace
    catch { ctext::destroy }

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

    # Clean up the application (if there are any errors, ignore them)
    catch { exit_cleanup }

    # If we are doing code coverage, call cleanup directly
    if {[namespace exists ::_instrument_]} {
      ::_instrument_::cleanup
    }

    # Destroy the interface
    destroy .

  }

  ######################################################################
  # Adds the edit menu.
  proc add_edit {mb} {

    # Add edit menu commands
    $mb add command -label [msgcat::mc "Undo"] -underline 0 -command [list gui::undo]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Undo"]] [list gui::undo]

    $mb add command -label [msgcat::mc "Redo"] -underline 0 -command [list gui::redo]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Redo"]] [list gui::redo]

    $mb add separator

    $mb add command -label [msgcat::mc "Cut"] -underline 0 -command [list gui::cut]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Cut text"]] [list gui::cut]

    $mb add command -label [msgcat::mc "Copy"] -underline 1 -command [list gui::copy]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Copy text"]] [list gui::copy]

    $mb add command -label [msgcat::mc "Paste"] -underline 0 -command [list gui::paste]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Paste text from clipboard"]] [list gui::paste]

    $mb add command -label [msgcat::mc "Paste and Format"] -underline 10 -command [list gui::paste_and_format]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Paste and format text from clipboard"]] [list gui::paste_and_format]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Select"] -underline 0 -menu [make_menu $mb.selectPopup -tearoff 0 -postcommand [list menus::edit_select_posting $mb.selectPopup]]

    $mb add command -label [msgcat::mc "Select Mode"] -underline 7 -command [list menus::select_mode]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Enter selection mode"]] [list menus::select_mode]

    $mb add separator

    $mb add checkbutton -label [msgcat::mc "Vim Mode"] -underline 0 -variable preferences::prefs(Editor/VimMode) -command [list vim::set_vim_mode_all]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Enable Vim mode"]]  "set preferences::prefs(Editor/VimMode) 1; vim::set_vim_mode_all"
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Disable Vim mode"]] "set preferences::prefs(Editor/VimMode) 0; vim::set_vim_mode_all"

    $mb add separator

    $mb add command -label [msgcat::mc "Toggle Comment"] -underline 0 -command [list edit::comment_toggle]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Toggle comment"]] [list edit::comment_toggle]

    $mb add cascade -label [msgcat::mc "Indentation"] -underline 0 -menu [make_menu $mb.indentPopup -tearoff 0 -postcommand [list menus::edit_indent_posting $mb.indentPopup]]
    $mb add cascade -label [msgcat::mc "Cursor"]      -underline 1 -menu [make_menu $mb.cursorPopup -tearoff 0 -postcommand [list menus::edit_cursor_posting $mb.cursorPopup]]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Insert"]    -menu [make_menu $mb.insertPopup    -tearoff 0 -postcommand [list menus::edit_insert_posting $mb.insertPopup]]
    $mb add cascade -label [msgcat::mc "Transform"] -menu [make_menu $mb.transformPopup -tearoff 0 -postcommand [list menus::edit_transform_posting $mb.transformPopup]]
    $mb add cascade -label [msgcat::mc "Format"]    -menu [make_menu $mb.formatPopup    -tearoff 0 -postcommand [list menus::edit_format_posting $mb.formatPopup]]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Snippets"]      -menu [make_menu $mb.snipPopup  -tearoff 0 -postcommand [list menus::edit_snippets_posting $mb.snipPopup]]
    $mb add cascade -label [msgcat::mc "Templates"]     -menu [make_menu $mb.tempPopup  -tearoff 0 -postcommand [list menus::edit_templates_posting $mb.tempPopup]]
    $mb add cascade -label "Emmet"                      -menu [make_menu $mb.emmetPopup -tearoff 0 -postcommand [list menus::edit_emmet_posting $mb.emmetPopup]]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Preferences"]   -menu [make_menu $mb.prefPopup  -tearoff 0 -postcommand [list menus::edit_preferences_posting $mb.prefPopup]]

    #########################
    # Populate selection menu
    #########################

    $mb.selectPopup add command -label [msgcat::mc "All"] -underline 0 -command [list select::quick_select all]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Select all text"]] [list select::quick_select all]

    $mb.selectPopup add command -label [msgcat::mc "Current Line"] -underline 8 -command [list select::quick_select line]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Select current line"]] [list select::quick_select line]

    $mb.selectPopup add command -label [msgcat::mc "Current Word"] -underline 8 -command [list select::quick_select word]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Select current word"]] [list select::quick_select word]

    $mb.selectPopup add command -label [msgcat::mc "Current Sentence"] -underline 8 -command [list select::quick_select sentence]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Select current sentence"]] [list select::quick_select sentence]

    $mb.selectPopup add command -label [msgcat::mc "Current Paragraph"] -underline 8 -command [list select::quick_select paragraph]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Select current paragraph"]] [list select::quick_select paragraph]

    $mb.selectPopup add command -label [msgcat::mc "Current Bounded Text"] -underline 8 -command [list select::quick_select bracket]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Select current bracketed text, strings or comment block"]] [list select::quick_select bracket]

    $mb.selectPopup add separator

    $mb.selectPopup add command -label [msgcat::mc "Add Next Line"] -underline 4 -command [list select::quick_add_line next]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Add next line to selection"]] [list select::quick_add_line next]

    $mb.selectPopup add command -label [msgcat::mc "Add Previous Line"] -underline 5 -command [list select::quick_add_line prev]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Add previous line to selection"]] [list select::quick_add_line prev]

    ###########################
    # Populate indentation menu
    ###########################

    $mb.indentPopup add command -label [msgcat::mc "Indent"] -underline 0 -command [list menus::indent_command]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Indent selected text"]] [list menus::indent_command]

    $mb.indentPopup add command -label [msgcat::mc "Unindent"] -underline 1 -command [list menus::unindent_command]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Unindent selected text"]] [list menus::unindent_command]

    $mb.indentPopup add separator

    $mb.indentPopup add command -label [msgcat::mc "Format Text"] -command [list gui::format_text]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Format indentation for text"]] [list gui::format_text]

    $mb.indentPopup add separator

    $mb.indentPopup add radiobutton -label [msgcat::mc "Indent Off"] -variable menus::indent_mode -value "OFF" -command [list indent::set_indent_mode OFF]
    launcher::register [make_menu_cmd "Edit" [format "%s %s" [msgcat::mc "Set indent mode to"] "OFF"]] [list indent::set_indent_mode OFF]

    $mb.indentPopup add radiobutton -label [msgcat::mc "Auto-Indent"] -variable menus::indent_mode -value "IND" -command [list indent::set_indent_mode IND]
    launcher::register [make_menu_cmd "Edit" [format "%s %s" [msgcat::mc "Set indent mode to"] "IND"]] [list indent::set_indent_mode IND]

    $mb.indentPopup add radiobutton -label [msgcat::mc "Smart Indent"] -variable menus::indent_mode -value "IND+" -command [list indent::set_indent_mode IND+]
    launcher::register [make_menu_cmd "Edit" [format "%s %s" [msgcat::mc "Set indent mode to"] "IND+"]] [list indent::set_indent_mode IND+]

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

    $mb.cursorPopup add command -label [msgcat::mc "Move to Next Word"] -command [list menus::edit_cursor_move nextwordstart]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to next word"]] [list menus::edit_cursor_move nextwordstart]

    $mb.cursorPopup add command -label [msgcat::mc "Move to Previous Word"] -command [list menus::edit_cursor_move prevwordstart]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move cursor to previous word"]] [list menus::edit_cursor_move prevwordstart]

    $mb.cursorPopup add separator

    $mb.cursorPopup add command -label [msgcat::mc "Move Cursors Up"] -command [list menus::edit_cursors_move up]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move multicursors up one line"]] [list menus::edit_cursors_move up]

    $mb.cursorPopup add command -label [msgcat::mc "Move Cursors Down"] -command [list menus::edit_cursors_move down]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move multicursors down one line"]] [list menus::edit_cursors_move down]

    $mb.cursorPopup add command -label [msgcat::mc "Move Cursors Left"] -command [list menus::edit_cursors_move left]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move multicursors left one line"]] [list menus::edit_cursors_move left]

    $mb.cursorPopup add command -label [msgcat::mc "Move Cursors Right"] -command [list menus::edit_cursors_move right]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Move multicursors right one line"]] [list menus::edit_cursors_move right]

    $mb.cursorPopup add separator

    $mb.cursorPopup add command -label [msgcat::mc "Align Cursors Only"] -command [list edit::align_cursors -text 0]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Align cursors only"]] [list edit::align_cursors -text 0]

    $mb.cursorPopup add command -label [msgcat::mc "Align Cursors and Text"] -command [list edit::align_cursors -text 1]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Align cursors and text"]] [list edit::align_cursors -text 1]

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

    $mb.insertPopup add command -label [msgcat::mc "Enumeration"] -underline 7 -command [list edit::insert_enumeration]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert enumeration"]] [list edit::insert_enumeration]

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

    $mb.transformPopup add command -label [msgcat::mc "Replace Line With Script"] -command [list edit::replace_line_with_script]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Replace line with script"]] [list edit::replace_line_with_script]

    ##########################
    # Populate formatting menu
    ##########################

    set fmtstr [msgcat::mc "formatting"]

    $mb.formatPopup add command -label [msgcat::mc "Bold"] -command [list menus::edit_format bold]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert bold formatting"]] [list menus::edit_format bold]

    $mb.formatPopup add command -label [msgcat::mc "Italics"] -command [list menus::edit_format italics]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert italics formatting"]] [list menus::edit_format italics]

    $mb.formatPopup add command -label [msgcat::mc "Underline"] -command [list menus::edit_format underline]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert underline formatting"]] [list menus::edit_format underline]

    $mb.formatPopup add command -label [msgcat::mc "Strikethrough"] -command [list menus::edit_format strikethrough]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert strikethrough formatting"]] [list menus::edit_format strikethrough]

    $mb.formatPopup add command -label [msgcat::mc "Highlight"] -command [list menus::edit_format highlight]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert highlight formatting"]] [list menus::edit_format highlight]

    $mb.formatPopup add command -label [msgcat::mc "Superscript"] -command [list menus::edit_format superscript]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert superscript formatting"]] [list menus::edit_format superscript]

    $mb.formatPopup add command -label [msgcat::mc "Subscript"] -command [list menus::edit_format subscript]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert subscript formatting"]] [list menus::edit_format subscript]

    $mb.formatPopup add command -label [msgcat::mc "Code"] -command [list menus::edit_format code]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert code formatting"]] [list menus::edit_format code]

    $mb.formatPopup add separator

    $mb.formatPopup add command -label [format "%s 1" [msgcat::mc "Header"]] -command [list menus::edit_format header1]
    launcher::register [make_menu_cmd "Edit" [format "%s 1 %s" [msgcat::mc "Insert header style"] $fmtstr]] [list menus::edit_format header1]

    $mb.formatPopup add command -label [format "%s 2" [msgcat::mc "Header"]] -command [list menus::edit_format header2]
    launcher::register [make_menu_cmd "Edit" [format "%s 2 %s" [msgcat::mc "Insert header style"] $fmtstr]] [list menus::edit_format header2]

    $mb.formatPopup add command -label [format "%s 3" [msgcat::mc "Header"]] -command [list menus::edit_format header3]
    launcher::register [make_menu_cmd "Edit" [format "%s 3 %s" [msgcat::mc "Insert header style"] $fmtstr]] [list menus::edit_format header3]

    $mb.formatPopup add command -label [format "%s 4" [msgcat::mc "Header"]] -command [list menus::edit_format header4]
    launcher::register [make_menu_cmd "Edit" [format "%s 4 %s" [msgcat::mc "Insert header style"] $fmtstr]] [list menus::edit_format header4]

    $mb.formatPopup add command -label [format "%s 5" [msgcat::mc "Header"]] -command [list menus::edit_format header5]
    launcher::register [make_menu_cmd "Edit" [format "%s 5 %s" [msgcat::mc "Insert header style"] $fmtstr]] [list menus::edit_format header5]

    $mb.formatPopup add command -label [format "%s 6" [msgcat::mc "Header"]] -command [list menus::edit_format header6]
    launcher::register [make_menu_cmd "Edit" [format "%s 6 %s" [msgcat::mc "Insert header style"] $fmtstr]] [list menus::edit_format header6]

    $mb.formatPopup add separator

    $mb.formatPopup add command -label [msgcat::mc "Unordered Bullet"] -command [list menus::edit_format unordered]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert unordered list formatting"]] [list menus::edit_format unordered]

    $mb.formatPopup add command -label [msgcat::mc "Ordered Bullet"] -command [list menus::edit_format ordered]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert ordered list formatting"]] [list menus::edit_format ordered]

    $mb.formatPopup add command -label [msgcat::mc "Checkbox"] -command [list menus::edit_format checkbox]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert checklist formatting"]] [list menus::edit_format checkbox]

    $mb.formatPopup add separator

    $mb.formatPopup add command -label [msgcat::mc "Link"] -command [list menus::edit_format link]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert link formatting"]] [list menus::edit_format link]

    $mb.formatPopup add command -label [msgcat::mc "Image"] -command [list menus::edit_format image]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Insert image formatting"]] [list menus::edit_format image]

    $mb.formatPopup add separator

    $mb.formatPopup add command -label [msgcat::mc "Remove Formatting"] -command [list menus::edit_format_remove]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Remove formatting from selected text"]] [list menus::edit_format_remove]

    ###########################
    # Populate preferences menu
    ###########################

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Edit User"] [msgcat::mc "Global"]] -command [list menus::edit_user_global]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit user global preferences"]] [list menus::edit_user_global]

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Edit User"] [msgcat::mc "Language"]] -command [list menus::edit_user_language]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit user current language preferences"]] [list menus::edit_user_language]

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Delete User"] [msgcat::mc "Language"]] -command [list menus::delete_user_language]

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Global"]] -command [list menus::edit_session_global]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit session global preferences"]] [list menus::edit_session_global]

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Language"]] -command [list menus::edit_session_language]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit session current language preferences"]] [list menus::edit_session_language]

    $mb.prefPopup add separator

    $mb.prefPopup add command -label [format "%s - %s" [msgcat::mc "Delete Session"] [msgcat::mc "Language"]] -command [list menus::delete_session_language]

    ########################
    # Populate snippets menu
    ########################

    $mb.snipPopup add command -label [msgcat::mc "Edit User"] -command [list menus::add_new_snippet user]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit user snippets"]] [list menus::add_new_snippet user]

    $mb.snipPopup add command -label [msgcat::mc "Edit Language"] -command [list menus::add_new_snippet lang]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit language snippets"]] [list menus::add_new_snippet lang]

    $mb.snipPopup add separator

    $mb.snipPopup add command -label [msgcat::mc "Reload"] -command [list snippets::reload_snippets]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Reload snippets"]] [list snippets::reload_snippets]

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

    $mb.emmetPopup add command -label [msgcat::mc "Expand Abbreviation"] -command [list emmet::expand_abbreviation]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Expand Emmet abbreviation"]] [list emmet::expand_abbreviation]

    $mb.emmetPopup add command -label [msgcat::mc "Wrap With Abbreviation"] -command [list emmet::wrap_with_abbreviation]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Wrap tag with Emmet abbreviation"]] [list emmet::wrap_with_abbreviation]

    $mb.emmetPopup add separator

    $mb.emmetPopup add command -label [msgcat::mc "Balance Outward"] -command [list emmet::balance_outward]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Balance tag pair moving outward"]] [list emmet::balance_outward]

    $mb.emmetPopup add command -label [msgcat::mc "Balance Inward"] -command [list emmet::balance_inward]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Balance tag pair moving inward"]] [list emmet::balance_inward]

    $mb.emmetPopup add command -label [msgcat::mc "Go to Matching Pair"] -command [list emmet::go_to_matching_pair]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Go to matching tag pair"]] [list emmet::go_to_matching_pair]

    $mb.emmetPopup add separator

    $mb.emmetPopup add command -label [msgcat::mc "Toggle Comment"] -command [list emmet::toggle_comment]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Toggle tag/rule comment"]] [list emmet::toggle_comment]

    $mb.emmetPopup add command -label [msgcat::mc "Split/Join Tag"] -command [list emmet::split_join_tag]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Split/Join tag"]] [list emmet::split_join_tag]

    $mb.emmetPopup add command -label [msgcat::mc "Remove Tag"] -command [list emmet::remove_tag]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Remove tag"]] [list emmet::remove_tag]

    $mb.emmetPopup add command -label [msgcat::mc "Merge Lines"] -command [list emmet::merge_lines]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Merge Lines"]] [list emmet::merge_lines]

    $mb.emmetPopup add command -label [msgcat::mc "Update Image Size"] -command [list emmet::update_image_size]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Update img tag width and height attributes"]] [list emmet::update_image_size]

    $mb.emmetPopup add command -label [msgcat::mc "Encode/Decode Image to Data:URL"] -command [list emmet::encode_decode_image_to_data_url]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Encode/Decode image to data:URL"]] [list emmet::encode_decode_image_to_data_url]

    $mb.emmetPopup add command -label [msgcat::mc "Reflect CSS Value"] -command [list emmet_css::reflect_css_value]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Reflect current CSS value"]] [list emmet_css::reflect_css_value]

    $mb.emmetPopup add separator

    $mb.emmetPopup add command -label [msgcat::mc "Next Edit Point"] -command [list emmet::go_to_edit_point next]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Go to next edit point"]] [list emmet::go_to_edit_point next]

    $mb.emmetPopup add command -label [msgcat::mc "Previous Edit Point"] -command [list emmet::go_to_edit_point prev]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Go to previous edit point"]] [list emmet::go_to_edit_point prev]

    $mb.emmetPopup add separator

    $mb.emmetPopup add command -label [msgcat::mc "Select Next Item"] -command [list emmet::select_item next]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Select next tag item"]] [list emmet::select_item next]

    $mb.emmetPopup add command -label [msgcat::mc "Select Previous Item"] -command [list emmet::select_item prev]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Select previous tag item"]] [list emmet::select_item prev]

    $mb.emmetPopup add separator

    $mb.emmetPopup add command -label [msgcat::mc "Evaluate Math Expression"] -command [list emmet::evaluate_math_expression]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Evaluate the current math expression"]] [list emmet::evaluate_math_expression]

    $mb.emmetPopup add separator

    $mb.emmetPopup add command -label [msgcat::mc "Increment by 10"] -command [list emmet::change_number 10]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Increment number by 10"]] [list emmet::change_number 10]

    $mb.emmetPopup add command -label [msgcat::mc "Increment by 1"] -command [list emmet::change_number 1]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Increment number by 1"]] [list emmet::change_number 1]

    $mb.emmetPopup add command -label [msgcat::mc "Increment by 0.1"] -command [list emmet::change_number 0.1]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Increment number by 0.1"]] [list emmet::change_number 0.1]

    $mb.emmetPopup add command -label [msgcat::mc "Decrement by 10"] -command [list emmet::change_number -10]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Decrement number by 10"]] [list emmet::change_number -10]

    $mb.emmetPopup add command -label [msgcat::mc "Decrement by 1"] -command [list emmet::change_number -1]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Decrement number by 1"]] [list emmet::change_number -1]

    $mb.emmetPopup add command -label [msgcat::mc "Decrement by 0.1"] -command [list emmet::change_number -0.1]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Decrement number by 0.1"]] [list emmet::change_number -0.1]

    $mb.emmetPopup add separator

    $mb.emmetPopup add command -label [msgcat::mc "Edit Custom Abbreviations"] -command [list emmet::edit_abbreviations]
    launcher::register [make_menu_cmd "Edit" [msgcat::mc "Edit custom Emmet abbreviations"]] [list emmet::edit_abbreviations]

  }

  ######################################################################
  # Called just prior to posting the edit menu.  Sets the state of all
  # menu items to match the proper state of the UI.
  proc edit_posting {mb} {

    if {[catch { gui::get_info {} current txt readonly diff }]} {
      $mb entryconfigure [msgcat::mc "Undo"]             -state disabled
      $mb entryconfigure [msgcat::mc "Redo"]             -state disabled
      $mb entryconfigure [msgcat::mc "Cut"]              -state disabled
      $mb entryconfigure [msgcat::mc "Copy"]             -state disabled
      $mb entryconfigure [msgcat::mc "Paste"]            -state disabled
      $mb entryconfigure [msgcat::mc "Paste and Format"] -state disabled
      $mb entryconfigure [msgcat::mc "Select Mode"]      -state disabled
      $mb entryconfigure [msgcat::mc "Vim Mode"]         -state disabled
      $mb entryconfigure [msgcat::mc "Toggle Comment"]   -state disabled
      $mb entryconfigure [msgcat::mc "Indentation"]      -state disabled
      $mb entryconfigure [msgcat::mc "Cursor"]           -state disabled
      $mb entryconfigure [msgcat::mc "Insert"]           -state disabled
      $mb entryconfigure [msgcat::mc "Transform"]        -state disabled
      $mb entryconfigure [msgcat::mc "Format"]           -state disabled
    } else {
      set readonly_state [expr {($readonly || $diff) ? "disabled" : "normal"}]
      if {[gui::undoable]} {
        $mb entryconfigure [msgcat::mc "Undo"] -state $readonly_state
      } else {
        $mb entryconfigure [msgcat::mc "Undo"] -state disabled
      }
      if {[gui::redoable]} {
        $mb entryconfigure [msgcat::mc "Redo"] -state $readonly_state
      } else {
        $mb entryconfigure [msgcat::mc "Redo"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Cut"]  -state $readonly_state
      $mb entryconfigure [msgcat::mc "Copy"] -state normal
      if {[gui::pastable]} {
        $mb entryconfigure [msgcat::mc "Paste"]            -state $readonly_state
        $mb entryconfigure [msgcat::mc "Paste and Format"] -state $readonly_state
      } else {
        $mb entryconfigure [msgcat::mc "Paste"]            -state disabled
        $mb entryconfigure [msgcat::mc "Paste and Format"] -state disabled
      }
      $mb entryconfigure [msgcat::mc "Select Mode"] -state normal
      $mb entryconfigure [msgcat::mc "Vim Mode"]    -state $readonly_state
      if {[lindex [syntax::get_comments [gui::current_txt]] 0] eq ""} {
        $mb entryconfigure [msgcat::mc "Toggle Comment"] -state disabled
      } else {
        $mb entryconfigure [msgcat::mc "Toggle Comment"] -state $readonly_state
      }
      $mb entryconfigure [msgcat::mc "Indentation"] -state $readonly_state
      $mb entryconfigure [msgcat::mc "Cursor"]      -state $readonly_state
      if {[gui::editable]} {
        $mb entryconfigure [msgcat::mc "Insert"]    -state $readonly_state
        $mb entryconfigure [msgcat::mc "Transform"] -state $readonly_state
      } else {
        $mb entryconfigure [msgcat::mc "Insert"]    -state disabled
        $mb entryconfigure [msgcat::mc "Transform"] -state disabled
      }
      if {[gui::editable] && ([llength [syntax::get_formatting $txt]] > 0)} {
        $mb entryconfigure [msgcat::mc "Format"] -state $readonly_state
      } else {
        $mb entryconfigure [msgcat::mc "Format"] -state disabled
      }
    }

  }

  ######################################################################
  # Called just prior to posting the edit/selection menu option.  Sets
  # the menu option states to match the current UI state.
  proc edit_select_posting {mb} {

    set state [expr {([gui::current_txt] eq "") ? "disabled" : "normal"}]

    $mb entryconfigure [msgcat::mc "All"]                  -state $state
    $mb entryconfigure [msgcat::mc "Current Line"]         -state $state
    $mb entryconfigure [msgcat::mc "Current Word"]         -state $state
    $mb entryconfigure [msgcat::mc "Current Sentence"]     -state $state
    $mb entryconfigure [msgcat::mc "Current Paragraph"]    -state $state
    $mb entryconfigure [msgcat::mc "Current Bounded Text"] -state $state
    $mb entryconfigure [msgcat::mc "Add Next Line"]        -state $state
    $mb entryconfigure [msgcat::mc "Add Previous Line"]    -state $state

  }

  ######################################################################
  # Called just prior to posting the edit/indentation menu option.  Sets
  # the menu option states to match the current UI state.
  proc edit_indent_posting {mb} {

    variable indent_mode

    set state "disabled"

    # Set the indentation mode for the current editor
    if {[set txt [gui::current_txt]] ne ""} {
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
    if {[set txt [gui::current_txt]] ne ""} {
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

    $mb entryconfigure [msgcat::mc "Move Cursors Up"]        -state $mstate
    $mb entryconfigure [msgcat::mc "Move Cursors Down"]      -state $mstate
    $mb entryconfigure [msgcat::mc "Move Cursors Left"]      -state $mstate
    $mb entryconfigure [msgcat::mc "Move Cursors Right"]     -state $mstate
    $mb entryconfigure [msgcat::mc "Align Cursors Only"]     -state $mstate
    $mb entryconfigure [msgcat::mc "Align Cursors and Text"] -state $mstate

  }

  ######################################################################
  # Called just prior to posting the edit/insert menu option.  Sets the
  # menu option states to match the current UI state.
  proc edit_insert_posting {mb} {

    set tstate "disabled"
    set mstate "disabled"

    if {[set txt [gui::current_txt]] ne ""} {
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
  # Called just prior to posting the edit/transform menu option.  Sets
  # the menu option states to match the current UI state.
  proc edit_transform_posting {mb} {

    # Get the state
    set state [expr {([gui::current_txt] eq "") ? "disabled" : "normal"}]

    $mb entryconfigure [msgcat::mc "Toggle Case"]              -state $state
    $mb entryconfigure [msgcat::mc "Lower Case"]               -state $state
    $mb entryconfigure [msgcat::mc "Upper Case"]               -state $state
    $mb entryconfigure [msgcat::mc "Title Case"]               -state $state
    $mb entryconfigure [msgcat::mc "Join Lines"]               -state $state
    $mb entryconfigure [msgcat::mc "Bubble Up"]                -state $state
    $mb entryconfigure [msgcat::mc "Bubble Down"]              -state $state
    $mb entryconfigure [msgcat::mc "Replace Line With Script"] -state $state

    if {[edit::current_line_empty]} {
      $mb entryconfigure [msgcat::mc "Replace Line With Script"] -state disabled
    }

  }

  ######################################################################
  # Called just prior to posting the edit/format menu option.  Sets the
  # menu option states to match the current UI state.
  proc edit_format_posting {mb} {

    set txt [gui::get_info {} current txt]

    # Place the contents of the formatting information in the array
    array set formatting [syntax::get_formatting $txt]

    $mb entryconfigure [msgcat::mc "Bold"]                   -state [expr {[info exists formatting(bold)]          ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Italics"]                -state [expr {[info exists formatting(italics)]       ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Underline"]              -state [expr {[info exists formatting(underline)]     ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Strikethrough"]          -state [expr {[info exists formatting(strikethrough)] ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Highlight"]              -state [expr {[info exists formatting(highlight)]     ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Superscript"]            -state [expr {[info exists formatting(superscript)]   ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Subscript"]              -state [expr {[info exists formatting(subscript)]     ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Code"]                   -state [expr {[info exists formatting(code)]          ? "normal" : "disabled"}]
    $mb entryconfigure [format "%s 1" [msgcat::mc "Header"]] -state [expr {[info exists formatting(header1)]       ? "normal" : "disabled"}]
    $mb entryconfigure [format "%s 2" [msgcat::mc "Header"]] -state [expr {[info exists formatting(header2)]       ? "normal" : "disabled"}]
    $mb entryconfigure [format "%s 3" [msgcat::mc "Header"]] -state [expr {[info exists formatting(header3)]       ? "normal" : "disabled"}]
    $mb entryconfigure [format "%s 4" [msgcat::mc "Header"]] -state [expr {[info exists formatting(header4)]       ? "normal" : "disabled"}]
    $mb entryconfigure [format "%s 5" [msgcat::mc "Header"]] -state [expr {[info exists formatting(header5)]       ? "normal" : "disabled"}]
    $mb entryconfigure [format "%s 6" [msgcat::mc "Header"]] -state [expr {[info exists formatting(header6)]       ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Unordered Bullet"]       -state [expr {[info exists formatting(unordered)]     ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Ordered Bullet"]         -state [expr {[info exists formatting(ordered)]       ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Checkbox"]               -state [expr {[info exists formatting(checkbox)]      ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Link"]                   -state [expr {[info exists formatting(link)]          ? "normal" : "disabled"}]
    $mb entryconfigure [msgcat::mc "Image"]                  -state [expr {[info exists formatting(image)]         ? "normal" : "disabled"}]

  }

  ######################################################################
  # Called just prior to posting the edit/preferences menu option.  Sets
  # the menu option states to match the current UI state.
  proc edit_preferences_posting {mb} {

    if {[set txt [gui::current_txt]] eq ""} {
      $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit User"]      [msgcat::mc "Language"]] -state disabled
      $mb entryconfigure [format "%s - %s" [msgcat::mc "Delete User"]    [msgcat::mc "Language"]] -state disabled
      $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"]   [msgcat::mc "Language"]] -state disabled
      $mb entryconfigure [format "%s - %s" [msgcat::mc "Delete Session"] [msgcat::mc "Language"]] -state disabled
    } else {
      $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit User"] [msgcat::mc "Language"]] -state normal
      if {[preferences::language_exists "" [syntax::get_language $txt]]} {
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Delete User"] [msgcat::mc "Language"]] -state normal
      } else {
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Delete User"] [msgcat::mc "Language"]] -state disabled
      }
      if {[set session [sessions::current]] eq ""} {
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"]   [msgcat::mc "Global"]]   -state disabled
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"]   [msgcat::mc "Language"]] -state disabled
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Delete Session"] [msgcat::mc "Language"]] -state disabled
      } else {
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Global"]]   -state normal
        $mb entryconfigure [format "%s - %s" [msgcat::mc "Edit Session"] [msgcat::mc "Language"]] -state normal
        if {[preferences::language_exists $session [syntax::get_language $txt]]} {
          $mb entryconfigure [format "%s - %s" [msgcat::mc "Delete Session"] [msgcat::mc "Language"]] -state normal
        } else {
          $mb entryconfigure [format "%s - %s" [msgcat::mc "Delete Session"] [msgcat::mc "Language"]] -state disabled
        }
      }
    }

  }

  ######################################################################
  # Called just prior to posting the edit/menu bindings menu option.
  # Sets the menu option states to match the current UI state.
  proc edit_snippets_posting {mb} {

    $mb entryconfigure [msgcat::mc "Edit User"] -state normal

    if {[gui::current_txt] eq ""} {
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

    if {[catch { gui::get_info {} current txt lang }]} {

      $mb entryconfigure [msgcat::mc "Expand Abbreviation"]             -state disabled
      $mb entryconfigure [msgcat::mc "Wrap With Abbreviation"]          -state disabled
      $mb entryconfigure [msgcat::mc "Balance Outward"]                 -state disabled
      $mb entryconfigure [msgcat::mc "Balance Inward"]                  -state disabled
      $mb entryconfigure [msgcat::mc "Go to Matching Pair"]             -state disabled
      $mb entryconfigure [msgcat::mc "Toggle Comment"]                  -state disabled
      $mb entryconfigure [msgcat::mc "Split/Join Tag"]                  -state disabled
      $mb entryconfigure [msgcat::mc "Remove Tag"]                      -state disabled
      $mb entryconfigure [msgcat::mc "Merge Lines"]                     -state disabled
      $mb entryconfigure [msgcat::mc "Update Image Size"]               -state disabled
      $mb entryconfigure [msgcat::mc "Encode/Decode Image to Data:URL"] -state disabled
      $mb entryconfigure [msgcat::mc "Reflect CSS Value"]               -state disabled
      $mb entryconfigure [msgcat::mc "Next Edit Point"]                 -state disabled
      $mb entryconfigure [msgcat::mc "Previous Edit Point"]             -state disabled
      $mb entryconfigure [msgcat::mc "Select Next Item"]                -state disabled
      $mb entryconfigure [msgcat::mc "Select Previous Item"]            -state disabled
      $mb entryconfigure [msgcat::mc "Evaluate Math Expression"]        -state disabled
      $mb entryconfigure [msgcat::mc "Increment by 10"]                 -state disabled
      $mb entryconfigure [msgcat::mc "Increment by 1"]                  -state disabled
      $mb entryconfigure [msgcat::mc "Increment by 0.1"]                -state disabled
      $mb entryconfigure [msgcat::mc "Decrement by 10"]                 -state disabled
      $mb entryconfigure [msgcat::mc "Decrement by 1"]                  -state disabled
      $mb entryconfigure [msgcat::mc "Decrement by 0.1"]                -state disabled

    } else {

      set intag       [emmet::inside_tag $txt -allow010 1]
      set innode      [emmet::get_node_range $txt]
      set inurl       [emmet_css::in_url $txt]
      set intag_mode  [expr {($intag  eq "") ? "disabled" : "normal"}]
      set innode_mode [expr {($innode eq "") ? "disabled" : "normal"}]
      set inurl_mode  [expr {$inurl ? "normal" : "disabled"}]
      set sel_mode    [expr {([llength [$txt tag ranges sel]] == 2) ? "normal" : $intag_mode}]
      set html_mode   [expr {($lang eq "HTML") ? "normal" : "disabled"}]
      set css_mode    [expr {($lang eq "CSS")  ? "normal" : "disabled"}]
      set html_or_css [expr {(($lang eq "HTML") || ($lang eq "CSS")) ? "normal" : "disabled"}]
      set url_mode    [expr {($lang eq "HTML") ? $intag_mode : $inurl_mode}]

      $mb entryconfigure [msgcat::mc "Expand Abbreviation"]             -state normal
      $mb entryconfigure [msgcat::mc "Wrap With Abbreviation"]          -state $sel_mode
      $mb entryconfigure [msgcat::mc "Balance Outward"]                 -state $intag_mode
      $mb entryconfigure [msgcat::mc "Balance Inward"]                  -state $intag_mode
      $mb entryconfigure [msgcat::mc "Go to Matching Pair"]             -state $intag_mode
      $mb entryconfigure [msgcat::mc "Toggle Comment"]                  -state $html_or_css
      $mb entryconfigure [msgcat::mc "Split/Join Tag"]                  -state $innode_mode
      $mb entryconfigure [msgcat::mc "Remove Tag"]                      -state $intag_mode
      $mb entryconfigure [msgcat::mc "Merge Lines"]                     -state $innode_mode
      $mb entryconfigure [msgcat::mc "Update Image Size"]               -state $url_mode
      $mb entryconfigure [msgcat::mc "Encode/Decode Image to Data:URL"] -state $url_mode
      $mb entryconfigure [msgcat::mc "Reflect CSS Value"]               -state $css_mode
      $mb entryconfigure [msgcat::mc "Next Edit Point"]                 -state $html_mode
      $mb entryconfigure [msgcat::mc "Previous Edit Point"]             -state $html_mode
      $mb entryconfigure [msgcat::mc "Select Next Item"]                -state $html_or_css
      $mb entryconfigure [msgcat::mc "Select Previous Item"]            -state $html_or_css
      $mb entryconfigure [msgcat::mc "Evaluate Math Expression"]        -state normal
      $mb entryconfigure [msgcat::mc "Increment by 10"]                 -state normal
      $mb entryconfigure [msgcat::mc "Increment by 1"]                  -state normal
      $mb entryconfigure [msgcat::mc "Increment by 0.1"]                -state normal
      $mb entryconfigure [msgcat::mc "Decrement by 10"]                 -state normal
      $mb entryconfigure [msgcat::mc "Decrement by 1"]                  -state normal
      $mb entryconfigure [msgcat::mc "Decrement by 0.1"]                -state normal

    }

  }

  ######################################################################
  # Enables the selection mode.
  proc select_mode {} {

    select::set_select_mode [gui::current_txt].t 1

  }

  ######################################################################
  # Indents the current line or current selection.
  proc indent_command {} {

    edit::indent [gui::current_txt].t

  }

  ######################################################################
  # Unindents the current line or current selection.
  proc unindent_command {} {

    edit::unindent [gui::current_txt].t

  }

  ######################################################################
  # Moves the current cursor by the given modifier for the current
  # text widget.
  proc edit_cursor_move {modifier} {

    # Get the current text widget
    set txtt [gui::current_txt].t

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
    set txtt [gui::current_txt].t

    # Move the cursor if we are not in multicursor mode
    if {![multicursor::enabled $txtt]} {
      edit::move_cursor_by_page $txtt $dir
    }

  }

  ######################################################################
  # Moves multicursors
  proc edit_cursors_move {modifier} {

    # Get the current text widget
    set txtt [gui::current_txt].t

    # If we are in multicursor mode, move the cursors in the direction given by modifier
    if {[multicursor::enabled $txtt]} {
      edit::move_cursors $txtt $modifier
    }

  }

  ######################################################################
  # Inserts a new line above the current line.
  proc edit_insert_line_above {} {

    edit::insert_line_above_current [gui::current_txt].t

  }

  ######################################################################
  # Inserts a new line below the current line.
  proc edit_insert_line_below {} {

    edit::insert_line_below_current [gui::current_txt].t

  }

  ######################################################################
  # Get the name of a file from the user using the open file chooser.
  # Inserts the contents of the file after the current line.
  proc edit_insert_file_after_current_line {} {

    if {[set fname [tk_getOpenFile -parent . -initialdir [gui::get_browse_directory] -multiple 1]] ne ""} {
      edit::insert_file [gui::current_txt].t $fname
      gui::set_txt_focus [gui::current_txt]
    }

  }

  ######################################################################
  # Gets a shell command from the user via the user input field.  Executes
  # the command and output the results after the current line.
  proc edit_insert_command_after_current_line {} {

    set cmd ""

    if {[gui::get_user_response [format "%s:" [msgcat::mc "Command"]] cmd -allow_vars 1]} {
      edit::insert_file [gui::current_txt].t "|$cmd"
    }

  }

  ######################################################################
  # Perform a case toggle operation.
  proc edit_transform_toggle_case {} {

    set txtt [gui::current_txt].t

    if {[catch { $txtt tag ranges sel } sel]} {
      foreach {startpos endpos} $sel {
        edit::transform_toggle_case $txtt $startpos $endpos
      }
    } else {
      edit::transform_toggle_case $txtt insert "insert+1c"
    }

  }

  ######################################################################
  # Perform a lowercase conversion.
  proc edit_transform_to_lower_case {} {

    set txtt [gui::current_txt].t

    if {[catch { $txtt tag ranges sel } sel]} {
      foreach {startpos endpos} $sel {
        edit::transform_to_lower_case $txtt $startpos $endpos
      }
    } else {
      edit::transform_to_lower_case $txtt insert "insert+1c"
    }

  }

  ######################################################################
  # Perform an uppercase conversion.
  proc edit_transform_to_upper_case {} {

    set txtt [gui::current_txt].t

    if {[catch { $txtt tag ranges sel } sel]} {
      foreach {startpos endpos} $sel {
        edit::transform_to_upper_case $txtt $startpos $endpos
      }
    } else {
      edit::transform_to_upper_case $txtt insert "insert+1c"
    }

  }

  ######################################################################
  # Perform a title case conversion.
  proc edit_transform_to_title_case {} {

    set txtt [gui::current_txt].t

    if {[catch { $txtt tag ranges sel } sel]} {
      foreach {startpos endpos} $sel {
        edit::transform_to_title_case $txtt $startpos $endpos
      }
    } else {
      edit::transform_to_title_case $txtt insert "insert+1c"
    }

  }

  ######################################################################
  # Joins selected lines or the line beneath the current lines.
  proc edit_transform_join_lines {} {

    edit::transform_join_lines [gui::current_txt].t

  }

  ######################################################################
  # Moves selected lines or the current line up by one line.
  proc edit_transform_bubble_up {} {

    edit::transform_bubble_up [gui::current_txt].t

  }

  ######################################################################
  # Moves selected lines or the current line down by one line.
  proc edit_transform_bubble_down {} {

    edit::transform_bubble_down [gui::current_txt].t

  }

  ######################################################################
  # Adds the specified formatting around the selected text.
  proc edit_format {type} {

    # Perform the editing
    edit::format [gui::current_txt].t $type

  }

  ######################################################################
  # Removes all formatting within the selected text.
  proc edit_format_remove {} {

    # Unapply any formatting found in the selected text
    edit::unformat [gui::current_txt].t

  }

  ######################################################################
  # Edits the user global preference settings.
  proc edit_user_global {} {

    # preferences::edit_global
    pref_ui::create "" ""

  }

  ######################################################################
  # Edits the user current language preference settings.
  proc edit_user_language {} {

    pref_ui::create "" [syntax::get_language [gui::current_txt]]

  }

  ######################################################################
  # Delete the current language preferences file.
  proc delete_user_language {} {

    set message [msgcat::mc "Delete language preferences?"]
    set detail  [msgcat::mc "All language-specific settings will be removed and the global settings will be applied for the specified language."]

    if {[tk_messageBox -parent . -type yesno -default no -message $message -detail $detail] eq "yes"} {
      preferences::delete_language_prefs "" [syntax::get_language [gui::current_txt]]
    }

  }

  ######################################################################
  # Edits the session global preference settings.
  proc edit_session_global {} {

    pref_ui::create [sessions::current] ""

  }

  ######################################################################
  # Edits the session current language preference settings.
  proc edit_session_language {} {

    pref_ui::create [sessions::current] [syntax::get_language [gui::current_txt]]

  }

  ######################################################################
  # Delete the current session/language preferences file.
  proc delete_session_language {} {

    set message [msgcat::mc "Delete session language preferences?"]
    set detail  [msgcat::mc "All language-specific settings for the current session will be removed and the global settings will be applied for the specified language."]

    if {[tk_messageBox -parent . -type yesno -default no -message $message -detail $detail] eq "yes"} {
      preferences::delete_language_prefs [sessions::current] [syntax::get_language [gui::current_txt]]
    }

  }

  ######################################################################
  # Adds a new snippet via the preferences GUI or text editor.
  proc add_new_snippet {language} {

    if {$language eq "user"} {
      pref_ui::create "" "" snippets
    } else {
      pref_ui::create "" [syntax::get_language [gui::current_txt]] snippets
    }

  }

  ######################################################################
  # Add the find menu.
  proc add_find {mb} {

    # Add find menu commands
    $mb add command -label [msgcat::mc "Find"] -underline 0 -command [list gui::search]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find"]] [list gui::search]

    $mb add command -label [msgcat::mc "Find Next"] -underline 7 -command [list menus::find_next_command]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find next occurrence"]] [list menus::find_next_command]

    $mb add command -label [msgcat::mc "Find Previous"] -underline 7 -command [list menus::find_prev_command]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find previous occurrence"]] [list menus::find_prev_command]

    $mb add separator

    $mb add command -label [msgcat::mc "Select Current Match"] -underline 1 -command [list menus::find_select_current_command]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Append current find text to selection"]] [list menus::find_select_current_command]

    $mb add command -label [msgcat::mc "Select All Matches"] -underline 7 -command [list menus::find_select_all_command]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Select all find matches"]] [list menus::find_select_all_command]

    $mb add separator

    $mb add command -label [msgcat::mc "Find and Replace"] -underline 9 -command [list gui::search_and_replace]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find and Replace"]] [list gui::search_and_replace]

    $mb add separator

    $mb add command -label [msgcat::mc "Jump Backward"] -underline 5 -command [list gui::jump_to_cursor -1 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Jump backward"]] [list gui::jump_to_cursor -1 1]

    $mb add command -label [msgcat::mc "Jump Forward"] -underline 5 -command [list gui::jump_to_cursor 1 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Jump forward"]] [list gui::jump_to_cursor 1 1]

    $mb add command -label [msgcat::mc "Jump To Line"] -underline 8 -command [list menus::jump_to_line]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Jump to line"]] [list menus::jump_to_line]

    $mb add separator

    $mb add command -label [msgcat::mc "Next Difference"] -underline 0 -command [list gui::jump_to_difference 1 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Goto next difference"]] [list gui::jump_to_difference 1 1]

    $mb add command -label [msgcat::mc "Previous Difference"] -underline 0 -command [list gui::jump_to_difference -1 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Goto previous difference"]] [list gui::jump_to_difference -1 1]

    $mb add command -label [msgcat::mc "Show Selected Line Change"] -underline 19 -command [list gui::show_difference_line_change 1]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Show selected line change"]] [list gui::show_difference_line_change 1]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Markers"] -underline 5 -menu [make_menu $mb.markerPopup -tearoff 0 -postcommand [list menus::find_marker_posting $mb.markerPopup]]

    $mb add separator

    $mb add command -label [msgcat::mc "Find Matching Bracket"] -underline 5 -command [list gui::show_match_pair]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find matching character pair"]] [list gui::show_match_pair]

    $mb add separator

    $mb add command -label [msgcat::mc "Find Next Bracket Mismatch"] -command [list gui::goto_mismatch next]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find next mismatching bracket"]] [list gui::goto_mismatch next]

    $mb add command -label [msgcat::mc "Find Previous Bracket Mismatch"] -command [list gui::goto_mismatch prev]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find previous mismatching bracket"]] [list gui::goto_mismatch prev]

    $mb add separator

    $mb add command -label [msgcat::mc "Find In Files"] -underline 5 -command [list search::fif_start]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Find in files"]] [list search::fif_start]

    # Add marker popup launchers
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Create marker at current line"]]          [list gui::create_current_marker]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Remove marker from current line"]]        [list gui::remove_current_marker]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Remove all markers from current buffer"]] [list gui::remove_current_markers]
    launcher::register [make_menu_cmd "Find" [msgcat::mc "Remove all markers"]]                     [list gui::remove_all_markers]

  }

  ######################################################################
  # Called just prior to posting the find menu.  Sets the state of the menu
  # items to match the current UI state.
  proc find_posting {mb} {

    if {[catch { gui::get_info {} current txt readonly diff }]} {
      $mb entryconfigure [msgcat::mc "Find"]                           -state disabled
      $mb entryconfigure [msgcat::mc "Find and Replace"]               -state disabled
      $mb entryconfigure [msgcat::mc "Find Next"]                      -state disabled
      $mb entryconfigure [msgcat::mc "Find Previous"]                  -state disabled
      $mb entryconfigure [msgcat::mc "Select Current Match"]           -state disabled
      $mb entryconfigure [msgcat::mc "Select All Matches"]             -state disabled
      $mb entryconfigure [msgcat::mc "Jump Backward"]                  -state disabled
      $mb entryconfigure [msgcat::mc "Jump Forward"]                   -state disabled
      $mb entryconfigure [msgcat::mc "Next Difference"]                -state disabled
      $mb entryconfigure [msgcat::mc "Previous Difference"]            -state disabled
      $mb entryconfigure [msgcat::mc "Show Selected Line Change"]      -state disabled
      $mb entryconfigure [msgcat::mc "Markers"]                        -state disabled
      $mb entryconfigure [msgcat::mc "Find Matching Bracket"]          -state disabled
      $mb entryconfigure [msgcat::mc "Find Next Bracket Mismatch"]     -state disabled
      $mb entryconfigure [msgcat::mc "Find Previous Bracket Mismatch"] -state disabled
    } else {
      set readonly_state  [expr {($readonly || $diff)                 ? "disabled" : "normal"}]
      set found_state     [expr {[search::enable_find_view $txt]      ? "normal" : "disabled"}]
      set sel_curr_state  [expr {[search::enable_select_current $txt] ? "normal" : "disabled"}]
      set jump_forw_state [expr {[gui::jump_to_cursor -1 0]           ? "normal" : "disabled"}]
      set jump_back_state [expr {[gui::jump_to_cursor  1 0]           ? "normal" : "disabled"}]
      set jump_diff_state [expr {[gui::jump_to_difference 1 0]        ? "normal" : "disabled"}]
      set show_line_state [expr {[gui::show_difference_line_change 0] ? "normal" : "disabled"}]
      set next_mism_state [expr {[gui::goto_mismatch next -check 1]   ? "normal" : "disabled"}]
      set prev_mism_state [expr {[gui::goto_mismatch prev -check 1]   ? "normal" : "disabled"}]
      $mb entryconfigure [msgcat::mc "Find"]                           -state normal
      $mb entryconfigure [msgcat::mc "Find and Replace"]               -state $readonly_state
      $mb entryconfigure [msgcat::mc "Find Next"]                      -state $found_state
      $mb entryconfigure [msgcat::mc "Find Previous"]                  -state $found_state
      $mb entryconfigure [msgcat::mc "Select Current Match"]           -state $sel_curr_state
      $mb entryconfigure [msgcat::mc "Select All Matches"]             -state $found_state
      $mb entryconfigure [msgcat::mc "Jump Backward"]                  -state $jump_back_state
      $mb entryconfigure [msgcat::mc "Jump Forward"]                   -state $jump_forw_state
      $mb entryconfigure [msgcat::mc "Next Difference"]                -state $jump_diff_state
      $mb entryconfigure [msgcat::mc "Previous Difference"]            -state $jump_diff_state
      $mb entryconfigure [msgcat::mc "Show Selected Line Change"]      -state $show_line_state
      $mb entryconfigure [msgcat::mc "Find Matching Bracket"]          -state $readonly_state
      $mb entryconfigure [msgcat::mc "Find Next Bracket Mismatch"]     -state $next_mism_state
      $mb entryconfigure [msgcat::mc "Find Previous Bracket Mismatch"] -state $prev_mism_state
      $mb entryconfigure [msgcat::mc "Markers"]                        -state normal
    }

  }

  ######################################################################
  # Called when the marker menu is opened.
  proc find_marker_posting {mb} {

    gui::get_info {} current tab txt

    set line_exists  [markers::exists_at_line $tab [lindex [split [$txt index insert] .] 0]]
    set create_state [expr {$line_exists ? "disabled" : "normal"}]
    set remove_state [expr {$line_exists ? "normal"   : "disabled"}]
    set tab_state    [expr {[markers::exists $tab] ? "normal" : "disabled"}]
    set all_state    [expr {[markers::exists *]    ? "normal" : "disabled"}]

    # Clear the menu
    $mb delete 0 end

    # Populate the markerPopup menu
    $mb add command -label [msgcat::mc "Create at Current Line"]         -underline 0  -command [list gui::create_current_marker]  -state $create_state
    $mb add separator
    $mb add command -label [msgcat::mc "Remove From Current Line"]       -underline 0  -command [list gui::remove_current_marker]  -state $remove_state
    $mb add command -label [msgcat::mc "Remove All From Current Buffer"] -underline 24 -command [list gui::remove_current_markers] -state $tab_state
    $mb add command -label [msgcat::mc "Remove All Markers"]             -underline 7  -command [list gui::remove_all_markers]     -state $all_state

    if {[llength [set markers [gui::get_marker_list]]] > 0} {
      $mb add separator
      foreach marker $markers {
        lassign $marker name txt mname
        $mb add command -label $name -command [list gui::jump_to_marker $txt $mname]
      }
    }

  }

  ######################################################################
  # Finds the next occurrence of the find regular expression for the current
  # text widget.
  proc find_next_command {} {

    search::find_next [gui::current_txt]

  }

  ######################################################################
  # Finds the previous occurrence of the find regular expression for the
  # current text widget.
  proc find_prev_command {} {

    search::find_prev [gui::current_txt]

  }

  ######################################################################
  # Selects the current found text item to the selection.
  proc find_select_current_command {} {

    search::select_current [gui::current_txt]

  }

  ######################################################################
  # Adds all matched values to the selection.
  proc find_select_all_command {} {

    search::select_all [gui::current_txt]

  }

  ######################################################################
  # Jumps to a line that is entered by the user.
  proc jump_to_line {} {

    set linenum ""

    # Get the line number from the user
    if {[gui::get_user_response [format "%s:" [msgcat::mc "Line Number"]] linenum] && [string is integer $linenum]} {
      edit::jump_to_line [gui::current_txt].t $linenum.0
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

    $mb add cascade     -label [msgcat::mc "Line Numbering"] -menu [make_menu $mb.numPopup -tearoff 0]
    $mb add checkbutton -label [msgcat::mc "Line Wrapping"]  -underline 5 -variable menus::line_wrapping -command [list menus::set_line_wrapping]

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

    $mb add checkbutton -label [msgcat::mc "Split View"] -underline 6 -variable menus::show_split_pane -command [list gui::toggle_split_pane]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Toggle split view mode"]] [list gui::toggle_split_pane]

    $mb add checkbutton -label [msgcat::mc "Bird's Eye View"] -underline 0 -variable menus::show_birdseye -command [list gui::toggle_birdseye]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Toggle bird's eye view mode"]] [list gui::toggle_birdseye]

    $mb add command -label [msgcat::mc "Move to Other Pane"] -underline 0 -command [list gui::move_to_pane]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Move to other pane"]] [list gui::move_to_pane]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Panes"]   -underline 0 -menu [make_menu $mb.panePopup -tearoff 0]
    $mb add cascade -label [msgcat::mc "Tabs"]    -underline 0 -menu [make_menu $mb.tabPopup  -tearoff 0 -postcommand "menus::view_tabs_posting $mb.tabPopup"]
    $mb add cascade -label [msgcat::mc "Folding"] -underline 0 -menu [make_menu $mb.foldPopup -tearoff 0 -postcommand "menus::view_fold_posting $mb.foldPopup"]

    $mb add separator

    $mb add cascade -label [msgcat::mc "Set Syntax"] -underline 9 -menu [syntax::create_menu $mb.syntax]
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

    $mb.tabPopup add command -label [msgcat::mc "Hide Current Tab"] -underline 5 -command [list gui::hide_current]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Hide Current Tab"]] [list gui::hide_current]

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

    $mb.foldPopup add command -label [msgcat::mc "Close Selected Folds"] -command [list menus::close_folds selected]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Close selected folds"]] [list menus::close_folds selected]

    $mb.foldPopup add command -label [msgcat::mc "Close All Folds"] -command [list menus::close_folds all]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Close all folds"]] [list menus::close_folds all]

    $mb.foldPopup add separator

    $mb.foldPopup add cascade -label [msgcat::mc "Open Current Fold"] -menu [make_menu $mb.fopenCurrPopup -tearoff 0]

    $mb.foldPopup add command -label [msgcat::mc "Open Selected Folds"] -command [list menus::open_folds selected]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Open selected folds"]] [list menus::open_folds selected]

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

    # Setup the folding open current popup menu
    $mb.fopenCurrPopup add command -label [msgcat::mc "One Level"]  -command [list menus::open_folds current 1]
    $mb.fopenCurrPopup add command -label [msgcat::mc "All Levels"] -command [list menus::open_folds current 0]

    launcher::register [make_menu_cmd "View" [msgcat::mc "Open fold at current line - one level"]]  [list menus::open_folds current 1]
    launcher::register [make_menu_cmd "View" [msgcat::mc "Open fold at current line - all levels"]] [list menus::open_folds current 0]

  }

  ######################################################################
  # Called just prior to posting the view menu.  Sets the state of the
  # menu options to match the current UI state.
  proc view_posting {mb} {

    variable show_split_pane
    variable show_birdseye
    variable line_numbering
    variable line_wrapping

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

    if {[gui::current_txt] eq ""} {
      catch { $mb entryconfigure [msgcat::mc "Show Line Numbers"]    -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Hide Line Numbers"]    -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Line Numbering"]       -state disabled }
      $mb entryconfigure [msgcat::mc "Line Wrapping"]                -state disabled
      catch { $mb entryconfigure [msgcat::mc "Show Marker Map"]      -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Hide Marker Map"]      -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Show Meta Characters"] -state disabled }
      catch { $mb entryconfigure [msgcat::mc "Hide Meta Characters"] -state disabled }
      $mb entryconfigure [msgcat::mc "Display Text Info"]            -state disabled
      $mb entryconfigure [msgcat::mc "Split View"]                   -state disabled
      $mb entryconfigure [msgcat::mc "Bird's Eye View"]              -state disabled
      $mb entryconfigure [msgcat::mc "Move to Other Pane"]           -state disabled
      if {[tk windowingsystem] ne "aqua"} {
        $mb entryconfigure [msgcat::mc "Set Syntax"]                 -state disabled
      }
      $mb entryconfigure [msgcat::mc "Folding"]                      -state disabled
    } else {
      gui::get_info {} current tab txt
      catch { $mb entryconfigure [msgcat::mc "Show Line Numbers"]  -state normal }
      catch { $mb entryconfigure [msgcat::mc "Hide Line Numbers"]  -state normal }
      catch { $mb entryconfigure [msgcat::mc "Line Numbering"]     -state normal }
      $mb entryconfigure [msgcat::mc "Line Wrapping"]              -state normal
      if {[markers::exists $tab]} {
        catch { $mb entryconfigure [msgcat::mc "Show Marker Map"] -state normal }
        catch { $mb entryconfigure [msgcat::mc "Hide Marker Map"] -state normal }
      } else {
        catch { $mb entryconfigure [msgcat::mc "Show Marker Map"] -state disabled }
        catch { $mb entryconfigure [msgcat::mc "Hide Marker Map"] -state disabled }
      }
      if {[syntax::contains_meta_chars [gui::current_txt]]} {
        catch { $mb entryconfigure [msgcat::mc "Show Meta Characters"] -state normal }
        catch { $mb entryconfigure [msgcat::mc "Hide Meta Characters"] -state normal }
      } else {
        catch { $mb entryconfigure [msgcat::mc "Show Meta Characters"] -state disabled }
        catch { $mb entryconfigure [msgcat::mc "Hide Meta Characters"] -state disabled }
      }
      $mb entryconfigure [msgcat::mc "Display Text Info"] -state normal
      $mb entryconfigure [msgcat::mc "Split View"]        -state normal
      $mb entryconfigure [msgcat::mc "Bird's Eye View"]   -state normal
      if {[gui::movable_to_other_pane]} {
        $mb entryconfigure [msgcat::mc "Move to Other Pane"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Move to Other Pane"] -state disabled
      }
      if {[tk windowingsystem] ne "aqua"} {
        $mb entryconfigure [msgcat::mc "Set Syntax"] -state normal
      }
      $mb entryconfigure [msgcat::mc "Folding"]    -state normal
      gui::get_info {} current txt2 beye
      set show_split_pane [winfo exists $txt2]
      set show_birdseye   [winfo exists $beye]

      # Get the current line numbering
      set line_numbering [[gui::current_txt] cget -linemap_type]

      # Get the current line wrapping
      set line_wrapping  [expr {[[gui::current_txt] cget -wrap] eq "word"}]

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
  # Called just prior to posting the view/folding menu.  Sets the state
  # fo the menu options to match the current UI state.
  proc view_fold_posting {mb} {

    variable code_folding

    # Get the current text widget
    set txt          [gui::current_txt]
    set line         [lindex [split [$txt index insert] .] 0]
    set state        [$txt gutter get folding $line]
    set code_folding [expr {[$txt cget -foldstate] ne "none"}]
    set sel_state    [expr {([$txt tag ranges sel] ne "") ? "normal" : "disabled"}]

    if {[$txt cget -foldstate] eq "manual"} {
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
    if {![catch {$mb entryconfigure [msgcat::mc "Show Tcl Console"] -label [msgcat::mc "Hide Tcl Console"] -command "menus::hide_console_view $mb"}]} {
      gui::show_console_view
    }

  }

  ######################################################################
  # Hides the console.
  proc hide_console_view {mb} {

    # Convert the menu command into the show console command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Tcl Console"] -label [msgcat::mc "Show Tcl Console"] -command "menus::show_console_view $mb"}]} {
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
      gui::set_line_number_view 1
    }

  }

  ######################################################################
  # Hides the line numbers in the editor.
  proc hide_line_numbers {mb} {

    # Convert the menu command into the hide line numbers command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Line Numbers"] -label [msgcat::mc "Show Line Numbers"] -command "menus::show_line_numbers $mb"}]} {
      gui::set_line_number_view 0
    }

  }

  ######################################################################
  # Sets the line numbering for the current editing buffer to either
  # 'absolute' or 'relative'.
  proc set_line_numbering {type} {

    [gui::current_txt] configure -linemap_type $type

  }

  ######################################################################
  # Sets the line wrapping mode based on the configured value in the menu.
  proc set_line_wrapping {} {

    variable line_wrapping

    [gui::current_txt] configure -wrap [expr {$line_wrapping ? "word" : "none"}]

  }

  ######################################################################
  # Shows the marker map for the current edit window.
  proc show_marker_map {mb} {

    # Convert the menu command into the hide marker map command
    if {![catch {$mb entryconfigure [msgcat::mc "Show Marker Map"] -label [msgcat::mc "Hide Marker Map"] -command "menus::hide_marker_map $mb"}]} {
      [winfo parent [gui::current_txt]].vb configure -markhide1 0
    }

  }

  ######################################################################
  # Hides the marker map for the current edit window.
  proc hide_marker_map {mb} {

    # Convert the menu command into the show marker map command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Marker Map"] -label [msgcat::mc "Show Marker Map"] -command "menus::show_marker_map $mb"}]} {
      [winfo parent [gui::current_txt]].vb configure -markhide1 1
    }

  }

  ######################################################################
  # Shows the meta characters in the current edit window.
  proc show_meta_chars {mb} {

    # Convert the menu command into the hide line numbers command
    if {![catch {$mb entryconfigure [msgcat::mc "Show Meta Characters"] -label [msgcat::mc "Hide Meta Characters"] -command "menus::hide_meta_chars $mb"}]} {
      syntax::set_meta_visibility [gui::current_txt] 1
    }

  }

  ######################################################################
  # Hides the meta characters in the current edit window.
  proc hide_meta_chars {mb} {

    # Convert the menu command into the hide line numbers command
    if {![catch {$mb entryconfigure [msgcat::mc "Hide Meta Characters"] -label [msgcat::mc "Show Meta Characters"] -command "menus::show_meta_chars $mb"}]} {
      syntax::set_meta_visibility [gui::current_txt] 0
    }

  }

  ######################################################################
  # Display the line and character counts in the information bar.
  proc display_text_info {} {

    gui::display_file_counts [gui::current_txt].t

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
    set txt [gui::current_txt]

    # If the user specified a value, set it
    if {$value ne ""} {
      set code_folding $value
    }

    # Set the fold enable value
    $txt configure -foldstate [gui::get_folding_method $txt $code_folding]

  }

  ######################################################################
  # Create a fold for the selected code and close the fold.
  proc add_fold_from_selection {} {

    set txt [gui::current_txt]

    $txt fold add {*}[$txt tag ranges sel]

  }

  ######################################################################
  # Delete one or more folds based on type.  Valid values for type are:
  #  - current  (deletes fold at the current line)
  #  - selected (deletes any selected folds)
  #  - all      (deletes all folds)
  proc delete_folds {type} {

    set txt [gui::current_txt]

    switch $type {
      current {
        $txt fold delete [lindex [split [$txt index insert] .] 0] -depth 1
      }
      all {
        $txt fold delete all
      }
      selected {
        foreach {startpos endpos} [$txt tag ranges sel] {
          set startline [lindex [split $startpos .] 0]
          set endline   [lindex [split $endpos   .] 0]
          $txt fold delete $startline $endline
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

    set txt [gui::current_txt]

    switch $type {
      current {
        $txt fold close [lindex [split [$txt index insert] .] 0] $depth
      }
      all {
        $txt fold close all
      }
      selected {
        foreach {startpos endpos} [$txt tag ranges sel] {
          $txt fold close $startpos $endpos 1
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

    set txt [gui::current_txt]

    switch $type {
      current  {
        $txt fold open [lindex [split [$txt index insert] .] 0] $depth
      }
      all      {
        $txt fold open all
      }
      show     {
        $txt fold open [lindex [split [$txt index insert] .] 0]
      }
      selected {
        foreach {startpos endpos} [$txt tag ranges sel] {
          $txt fold open $startpos $endpos $depth
        }
      }
    }

  }

  ######################################################################
  # Jump to the fold indicator in the given direction from the current
  # cursor position.
  proc jump_to_fold {dir} {

    set txt [gui::current_txt]

    if {[set line [$txt fold find insert $dir]] ne ""} {
      $txt cursor set $line.0
    }

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

      # Handle the state of the Show/Hide Console entry (if it exists)
      if {[winfo exists .tkcon]} {
        if {[winfo ismapped .tkcon]} {
          catch { $mb entryconfigure [msgcat::mc "Show Tcl Console"] -label [msgcat::mc "Hide Tcl Console"] -command [list menus::hide_console_view $mb] }
        } else {
          catch { $mb entryconfigure [msgcat::mc "Hide Tcl Console"] -label [msgcat::mc "Show Tcl Console"] -command [list menus::show_console_view $mb]}
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

    $mb add separator

    $mb add cascade -label [msgcat::mc "Language Documentation"] -menu [make_menu $mb.refPopup -tearoff 0 -postcommand [list menus::help_lang_ref_posting $mb.refPopup]]
    $mb add command -label [msgcat::mc "Search References"] -underline 0 -command [list search::search_documentation]
    launcher::register [make_menu_cmd "Help" [msgcat::mc "Search reference documentation"]] [list search::search_documentation]

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

    # Create search popup menu
    menu $mb.refPopup.searchPopup -tearoff 0

    launcher::register [make_menu_cmd "Help" [msgcat::mc "Search language reference documentation"]] [list gui::search_documentation]

  }

  ######################################################################
  # Called when the help menu is posted.  Controls the state of the help
  # menu items.
  proc help_posting {mb} {

    set docs [list {*}[syntax::get_references [gui::get_info {} current lang]] {*}[preferences::get Documentation/References]]

    if {[lsearch -index 1 -not $docs "*{query}*"] == -1} {
      $mb entryconfigure [msgcat::mc "Language Documentation"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Language Documentation"] -state normal
    }

    if {[lsearch -index 1 $docs "*{query}*"] == -1} {
      $mb entryconfigure [msgcat::mc "Search References"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Search References"] -state normal
    }

  }

  ######################################################################
  # Called when the language reference submenu is posted.
  proc help_lang_ref_posting {mb} {

    gui::get_info {} current lang

    # Get the documentation elements to add
    set syntax [lsearch -index 1 -inline -all -not [syntax::get_references $lang] "*{query}*"]
    set user   [lsearch -index 1 -inline -all -not [preferences::get Documentation/References] "*{query}*"]

    # Clean the menu
    $mb delete 0 end

    # Add the syntax items
    foreach item $syntax {
      lassign $item name url
      $mb add command -label $name -command [list utils::open_file_externally $url 1]
    }

    if {([llength $syntax] > 0) && ([llength $user] > 0)} {
      $mb add separator
    }

    # Add the user documentation
    foreach item $user {
      lassign $item name url
      $mb add command -label $name -command [list utils::open_file_externally $url 1]
    }

  }

  ######################################################################
  # Displays the User Guide.
  proc help_user_guide {} {

    utils::open_file_externally [file join $::tke_dir doc UserGuide.html] 1

  }

  ######################################################################
  # Displays the Developer Guide.
  proc help_devel_guide {} {

    utils::open_file_externally [file join $::tke_dir doc DeveloperGuide.html] 1

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
      specl::check_for_update 0 [expr $specl::RTYPE_STABLE | $specl::RTYPE_DEVEL] -title [msgcat::mc "TKE Updater"] -cleanup_script menus::exit_cleanup
    } else {
      specl::check_for_update 0 $specl::RTYPE_STABLE -title [msgcat::mc "TKE Updater"] -cleanup_script menus::exit_cleanup
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

