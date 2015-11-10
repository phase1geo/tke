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

  array set files       {}
  array set themes      {}
  array set theme       {}
  array set base_colors {}

  ######################################################################
  # Loads the theme information.
  proc load {} {

    variable files
    variable themes
    variable base_colors

    # Reset the files/themes arrays and unregister launcher items
    array unset files
    array unset themes
    [ns launcher]::unregister [msgcat::mc "Theme:*"]

    # Load the tke_dir theme files
    set tfiles [glob -nocomplain -directory [file join $::tke_dir data themes] *.tketheme]

    # Load the tke_home theme files
    lappend tfiles {*}[glob -nocomplain -directory [file join $::tke_home themes] *.tketheme]

    # Get the theme information
    foreach tfile $tfiles {
      set name         [file rootname [file tail $tfile]]
      set files($name) $tfile
      [ns launcher]::register [msgcat::mc "Theme:  %s" $name] [list [ns themes]::set_theme $name]
    }

    # Only perform the following on the first call of this procedure
    if {![info exists base_colors(light)]} {

      # Setup the base colors
      set base_colors(light) [list [[ns utils]::get_default_background] [[ns utils]::get_default_foreground]]
      set base_colors(dark)  [list "#303030" "#b0b0b0"]

      # Trace changes to syntax preference values
      trace variable [ns preferences]::prefs(General/WindowTheme) w [ns themes]::handle_theme_change
      trace variable [ns preferences]::prefs(Appearance/Theme)    w [ns themes]::handle_theme_change
      trace variable [ns preferences]::prefs(Appearance/Colorize) w [ns themes]::handle_colorize_change

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
  proc reload {{theme ""}} {

    variable files
    variable curr_theme

    # If the user has specified a theme to use, set the current theme
    if {$theme ne ""} {
      set curr_theme $theme

    # If the current theme is no longer available, select the first theme
    } elseif {![info exists files($curr_theme)]} {
      set curr_theme [lindex [array names files] 0]
    }

    # Reload the themes
    themes::load

    # Reset the theme
    set_theme $curr_theme 1

  }

  if {0} {
    # Set the theme in the UI
    if {($win_theme eq "light") || ($win_theme eq "dark")} {

      # Create the ttk theme if it currently does not exist
      if {[lsearch [ttk::style theme names] $win_theme] == -1} {
        create_ttk_theme $win_theme
      }

      # Configure the theme
      set_ttk_theme $win_theme [get_ttk_theme_colors {*}$base_colors($win_theme)]

      # Set the ttk theme
      ttk::style theme use $win_theme

      set bg           [[ns utils]::get_default_background]
      set fg           [[ns utils]::get_default_foreground]
      set abg          [[ns utils]::auto_adjust_color $bg 30]
      set menu_opts    [set theme(menus)             [list -background $bg -foreground $fg -relief flat]]
      set tab_opts     [set theme(tabs)              [list -background $bg -foreground $fg -activebackground $abg -inactivebackground $bg]]
      set tsb_opts     [set theme(text_scrollbar)    [list -background $syntax(background) -foreground $syntax(warning_width)]]
      set sidebar_opts [set theme(sidebar)           [list -foreground $fg -background $bg -selectbackground $abg -selectforeground $fg -highlightbackground $bg -highlightcolor $bg]]
      set ssb_opts     [set theme(sidebar_scrollbar) [list -foreground $abg -background $bg]]
      set syntax_opts  $theme(syntax)

      array set image_opts [list sidebar_open [list]]

    } else {

      # Create the ttk theme if it currently does not exist
      if {[lsearch [ttk::style theme names] theme-$theme_name] == -1} {
        create_ttk_theme theme-$theme_name
      }

      # Configure the theme
      set_ttk_theme theme-$theme_name $theme(ttk_style)

      # Set the ttk theme
      ttk::style theme use "theme-$theme_name"

      set menu_opts    $theme(menus)
      set tab_opts     $theme(tabs)
      set tsb_opts     $theme(text_scrollbar)
      set sidebar_opts $theme(sidebar)
      set ssb_opts     $theme(sidebar_scrollbar)
      set syntax_opts  $theme(syntax)

      array set image_opts $theme(images)

    }
  }

  ######################################################################
  # Repopulates the specified theme selection menu.
  proc populate_theme_menu {mnu} {

    variable files

    # Clear the menu
    $mnu delete 0 end

    # Populate the menu with the available themes
    foreach name [lsort [array names files]] {
      $mnu add radiobutton -label $name -variable [ns themes]::curr_theme -value $name -command [list [ns themes]::set_theme $name]
    }

    return $mnu

  }

}
