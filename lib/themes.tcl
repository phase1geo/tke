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
# Name:    themes.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    07/09/2014
# Brief:   Creates and sets the main UI theme to the given value.
######################################################################

namespace eval themes {

  source [file join $::tke_dir lib ns.tcl]

  variable curr_theme ""

  array set files {}

  ######################################################################
  # Updates the user's home themes directory
  proc update_themes_dir {} {

    foreach fname [glob -nocomplain -directory [file join $::tke_home themes] *.tketheme] {
      file mkdir [file rootname $fname]
      file rename $fname [file rootname $fname]
    }

  }

  ######################################################################
  # Loads the theme information.
  proc load {} {

    variable files

    # Update the user's themes directory
    update_themes_dir

    # Trace changes to syntax preference values
    if {[array size files] == 0} {
      trace variable [ns preferences]::prefs(Appearance/Theme)    w [ns themes]::handle_theme_change
      trace variable [ns preferences]::prefs(Appearance/Colorize) w [ns themes]::handle_colorize_change
    }

    # Reset the files/themes arrays and unregister launcher items
    array unset files
    [ns launcher]::unregister [msgcat::mc "Theme:*"]

    # Load the tke_dir theme files
    set tfiles [glob -nocomplain -directory [file join $::tke_dir data themes] *.tketheme]

    # Load the tke_home theme files
    foreach item [glob -nocomplain -directory [file join $::tke_home themes] -type d *] {
      if {[file exists [file join $item [file tail $item].tketheme]]} {
        lappend tfiles [file join $item [file tail $item.tketheme]]
      }
    }

    # Get the theme information
    foreach tfile $tfiles {
      set name         [file rootname [file tail $tfile]]
      set files($name) $tfile
      [ns launcher]::register [msgcat::mc "Theme:  %s" $name] [list [ns themes]::set_theme $name]
    }

  }

  ######################################################################
  # Called whenever the Appearance/Theme preference value is changed.
  proc handle_theme_change {{name1 ""} {name2 ""} {op ""}} {

    variable files

    set user_theme [[ns preferences]::get Appearance/Theme]

    if {[info exists files($user_theme)]} {
      theme::load_theme $files($user_theme)
    } else {
      theme::load_theme $files(default)
    }

  }

  ######################################################################
  # Called whenever the Appearance/Colorize preference value is changed.
  proc handle_colorize_change {name1 name2 op} {

    theme::update_syntax

  }

  ######################################################################
  # Reloads the available themes and resets the UI with the current theme.
  proc reload {} {

    variable files
    variable curr_theme

    # If the current theme is no longer available, select the first theme
    if {![info exists files($curr_theme)]} {
      set curr_theme [lindex [array names files] 0]
    }

    # Reload the themes
    theme::load_theme $files($curr_theme)

  }

  ######################################################################
  # Imports the contents of the given theme file (which must have either
  # the .tketheme or .tkethemz file extensions).  Imports the theme into
  # the user directory.
  proc import {parent_win fname} {

    # Unzip the file contents
    if {[catch { exec -ignorestderr unzip $fname -d [file join $::tke_home themes] } rc]} {
      tk_messageBox -parent $parent_win -icon error -type ok -default ok \
        -message "Unable to unzip theme file" -detail $rc
      return
    }

    # Figure out the theme name
    set theme [file rootname [file tail $fname]]

    # Reload the available themes
    load

  }

  ######################################################################
  # Exports the contents of the given theme to the given .tkethemz
  # directory.
  proc export {parent_win theme odir} {

    # Create the theme directory
    file mkdir [set theme_dir [file join $odir $theme]]

    # Populate the theme directory with the given contents
    if {![theme::export $theme_dir]} {
      tk_messageBox -parent $parent_win -icon error -type ok -default ok \
        -message "Unable to export theme contents"
    }

    # Get the current working directory
    set pwd [pwd]

    # Set the current working directory to the user themes directory
    cd $odir

    # Perform the archive
    if {[catch { exec -ignorestderr zip [file join $theme.tkethemz] $theme } rc]} {
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
  # Repopulates the specified theme selection menu.
  proc populate_theme_menu {mnu} {

    variable files
    variable curr_theme

    # Get the current theme
    set curr_theme [[ns theme]::get_current_theme]

    # Clear the menu
    $mnu delete 0 end

    # Populate the menu with the available themes
    foreach name [lsort [array names files]] {
      $mnu add radiobutton -label $name -variable [ns themes]::curr_theme -value $name -command [list [ns theme]::load_theme $files($name)]
    }

    return $mnu

  }

}
