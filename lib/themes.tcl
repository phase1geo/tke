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
# Name:    themes.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    07/09/2014
# Brief:   Creates and sets the main UI theme to the given value.
######################################################################

namespace eval themes {

  variable curr_theme ""

  array set files {}

  set themes_dir [file join $::tke_home themes]

  ######################################################################
  # Updates the user's home themes directory
  proc update_themes_dir {} {

    variable themes_dir

    foreach fname [glob -nocomplain -directory $themes_dir *.tketheme] {
      file mkdir [file rootname $fname]
      file rename $fname [file rootname $fname]
    }

  }

  ######################################################################
  # Loads the theme information.
  proc load {} {

    variable files
    variable themes_dir

    # Update the user's themes directory
    update_themes_dir

    # Trace changes to syntax preference values
    if {[array size files] == 0} {
      trace variable preferences::prefs(Appearance/Theme)        w themes::handle_theme_change
      trace variable preferences::prefs(Appearance/Colorize)     w themes::handle_colorize_change
      trace variable preferences::prefs(Appearance/HiddenThemes) w themes::handle_hidden_change
    }

    # Reset the files/themes arrays and unregister launcher items
    array unset files
    launcher::unregister [msgcat::mc "Theme:*"]

    # Load the tke_dir theme files
    set tfiles [utils::glob_install [file join $::tke_dir data themes] *.tketheme]

    # Load the theme files
    foreach item [glob -nocomplain -directory $themes_dir -types d *] {
      if {[file exists [file join $item [file tail $item].tketheme]]} {
        lappend tfiles [file join $item [file tail $item].tketheme]
      }
    }

    # Get the theme information
    foreach tfile $tfiles {
      set name         [file rootname [file tail $tfile]]
      set files($name) $tfile
    }

    # Create the launcher items (only display the visible themes)
    foreach name [get_visible_themes] {
      launcher::register [format "%s: %s" [msgcat::mc "Theme"] $name] [list theme::load_theme $files($name)] "" [list themes::theme_okay]
    }

    # Allow the preferences UI to be updated, if it exists
    pref_ui::themes_populate_table

  }

  ######################################################################
  # Deletes the given theme from the file system.
  proc delete_theme {name} {

    variable files

    # If the theme file exists, delete the file
    if {[info exists files($name)] && [file exists $files($name)]} {
      file delete -force $files($name)
    }

    # Reload the theme information
    load

  }

  ######################################################################
  # Returns true if it is okay to change the theme.
  proc theme_okay {} {

    return [expr [themer::window_exists] ^ 1]

  }

  ######################################################################
  # Returns the filename associated with the given theme name.  If the
  # theme name does not exist, returns an error.
  proc get_file {theme_name} {

    variable files

    if {[info exists files($theme_name)]} {
      return $files($theme_name)
    }

    return -code error "Filename for theme $theme_name does not exist"

  }

  ######################################################################
  # Returns a sorted list of all the themes.
  proc get_all_themes {} {

    variable files

    return [lsort [array names files]]

  }

  ######################################################################
  # Returns the list of themes that will be visible from the theme menu.
  proc get_visible_themes {} {

    variable files

    # Create list of files to
    return [lsort [::struct::set difference [array names files] [preferences::get Appearance/HiddenThemes]]]

  }

  ######################################################################
  # Called whenever the Appearance/Theme preference value is changed.
  proc handle_theme_change {{name1 ""} {name2 ""} {op ""}} {

    variable files

    set user_theme [preferences::get Appearance/Theme]

    if {[info exists files($user_theme)]} {
      theme::load_theme $files($user_theme)
    } else {
      theme::load_theme $files(Default)
    }

  }

  ######################################################################
  # Called whenever the Appearance/Colorize preference value is changed.
  proc handle_colorize_change {name1 name2 op} {

    theme::update_syntax

  }

  ######################################################################
  # Handle a change to the Appearance/HiddenThemes preference value.
  proc handle_hidden_change {name1 name2 op} {

    # Reload the themes
    load

  }

  ######################################################################
  # Imports the contents of the given theme file (which must have either
  # the .tketheme or .tkethemz file extensions).  Imports the theme into
  # the user directory.  Returns the name of the installed .tketheme file
  # if successful; otherwise, returns the empty string.
  proc import {parent_win fname} {

    variable files
    variable themes_dir

    # Unzip the file contents
    if {[catch { zipper::unzip $fname $themes_dir } rc]} {
      tk_messageBox -parent $parent_win -icon error -type ok -default ok \
        -message "Unable to unzip theme file" -detail $rc
      return ""
    }

    # Reload the available themes
    load

    # Return the pathname of the installed .tketheme file
    return $files([file rootname [file tail $fname]])

  }

  ######################################################################
  # Exports the contents of the given theme to the given .tkethemz
  # directory.
  proc export {parent_win theme odir creator website license} {

    # Create the theme directory
    file mkdir [set theme_dir [file join $odir $theme]]

    # Populate the theme directory with the given contents
    if {![theme::export $theme $theme_dir $creator $website $license]} {
      tk_messageBox -parent $parent_win -icon error -type ok -default ok \
        -message "Unable to export theme contents"
    }

    # Get the current working directory
    set pwd [pwd]

    # Set the current working directory to the user themes directory
    cd $odir

    # Perform the archive
    if {[catch { zipper::list2zip $theme [glob -directory $theme -tails *] [file join $theme.tkethemz] } rc]} {
      tk_messageBox -parent $parent_win -icon error -type ok -default ok \
        -message "Unable to zip theme file"
    }

    # Restore the current working directory
    cd $pwd

    # Delete the theme directory and its contents
    file delete {*}[glob -nocomplain -directory $theme_dir *]
    file delete -force $theme_dir

  }

  ######################################################################
  # Batch exports all custom themes to a directory on the Desktop.
  proc export_custom {{parent_win .}} {

    variable files
    variable themes_dir

    # Create the themes directory
    set output_dir [file join ~ Desktop UpdatedThemes]
    set current    [theme::get_current_theme]

    # If the output directory exists, delete it
    if {[file exists $output_dir]} {
      file delete -force $output_dir
    }

    # Make the output directory
    file mkdir $output_dir

    # Load each theme and then export it
    foreach {name theme_file} [array get files] {

      # Only consider themes from the themes_dir
      if {[string compare -length [string length $themes_dir] $theme_file $themes_dir] != 0} {
        continue
      }

      # Initialize some variables
      set license [file join [file dirname $theme_file] LICENSE]

      # Load the theme
      theme::read_tketheme $theme_file

      # Export the theme to the output directory
      array set attrs [list creator "" website "" date ""]
      array set attrs [theme::get_attributions]

      # Export the loaded theme
      export $parent_win $name $output_dir $attrs(creator) $attrs(website) $license

    }

    # Restore the theme namespace with the current theme contents
    theme::load_theme $files($current)

    # Tell the user that the export was successful
    gui::set_info_message [msgcat::mc "Batch custom theme export completed successfully"]

  }

  ######################################################################
  # Repopulates the specified theme selection menu.
  proc populate_theme_menu {mnu} {

    variable files
    variable curr_theme

    # Get the current theme
    set curr_theme [theme::get_current_theme]

    # Figure out the state for the items
    set state [expr {[themer::window_exists] ? "disabled" : "normal"}]

    # Clear the menu
    $mnu delete 0 end

    # Populate the menu with the available themes
    foreach name [get_visible_themes] {
      $mnu add radiobutton -label $name -variable themes::curr_theme -value $name -command [list theme::load_theme $files($name)] -state $state
    }

    return $mnu

  }

  ######################################################################
  # Returns the name of the currently displayed theme.
  proc get_current_theme {} {

    variable curr_theme

    return $curr_theme

  }

  ######################################################################
  # Returns 1 if the given file is imported; otherwise, returns 0.
  proc get_imported {name} {

    variable files
    variable themes_dir

    if {[info exists files($name)]} {
      return [expr [string compare -length [string length $themes_dir] $themes_dir $files($name)] == 0]
    }

    return 0

  }

  ######################################################################
  # Returns the creator, website and/or date information from the file in array format.
  proc get_attributions {name} {

    variable files

    array set attrs [list creator "" website "" date ""]

    if {[info exists files($name)]} {
      array set attrs [theme::get_file_attributions $files($name)]
    }

    return [array get attrs]

  }

  ######################################################################
  # Returns the location of the user themes directory.
  proc get_user_directory {} {

    variable themes_dir

    return $themes_dir

  }

  ######################################################################
  # Returns the list of files in the TKE home directory to copy.
  proc get_share_items {dir} {

    return [list themes]

  }

  ######################################################################
  # Called whenever the share directory changes.
  proc share_changed {dir} {

    variable themes_dir

    set themes_dir [file join $dir themes]

  }

}
