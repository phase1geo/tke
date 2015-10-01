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

  array set win_types {}
  array set themes    {}

  ######################################################################
  # Loads the theme information.
  proc load {} {

    variable themes

    # Clear the themes and unregister any themes from the launcher
    array unset themes
    [ns launcher]::unregister "Theme:*"

    # Load the tke_dir theme files
    set tfiles [glob -nocomplain -tails -directory [file join $::tke_dir data themes] *.tketheme]

    # Load the tke_home theme files
    lappend tfiles {*}[glob -nocomplain -tails -directory [file join $::tke_home themes] *.tketheme]

    # Get the theme information
    foreach tfile $tfiles {
      if {![catch { open $tfile r } rc]} {
        set themes([set name [file rootname $tfile]) ""
        [ns launcher]::register [msgcat::mc "Theme:  %s" $name] [list [ns themes]::set_theme $name]
      }
    }

    # Sets the current theme
    set_theme [[ns preferences]::get Appearance/Theme]

    # Trace changes to syntax preference values
    trace variable [ns preferences]::prefs(General/WindowTheme) w [ns themes]::handle_theme_change
    trace variable [ns preferences]::prefs(Appearance/Theme)    w [ns themes]::handle_theme_change
    trace variable [ns preferences]::prefs(Appearance/Colorize) w [ns themes]::handle_colorize_change

  }

  ######################################################################
  # Called whenever the Appearance/Theme preference value is changed.
  proc handle_theme_change {name1 name2 op} {

    set_theme [[ns preferences]::get Appearance/Theme]

  }

  ######################################################################
  # Called whenever the Appearance/Colorize preference value is changed.
  proc handle_colorize_change {name1 name2 op} {

    set_theme [[ns preferences]::get Appearance/Theme]

  }

  ######################################################################
  # Sets the theme to the specified value.  Returns 1 if the theme was
  # set; otherwise, returns 0.
  proc set_theme {theme_name} {

    variable themes
    variable theme
    variable curr_lang
    variable curr_theme
    variable colorizers
    variable win_types

    if {[info exists themes($theme_name)]} {

      # Load the theme file, if necessary
      if {$themes($theme_name) eq ""} {
        if {![catch { open $tfile r } rc]} {
          set themes($theme_name) [list {*}[read $rc]]
          close $rc
        }
      }

      # Set the current theme array
      array set theme $themes($theme_name)

      # Remove theme values that aren't in the Appearance/Colorize array
      foreach name [array names theme] {
        if {[info exists colorizers($name)] && \
            [lsearch [[ns preferences]::get Appearance/Colorize] $name] == -1} {
          set theme($name) ""
        }
      }

      # Update the current tab
      if {([set txt [[ns gui]::current_txt {}]] ne "") && (![info exists curr_theme($txt)] || ($curr_theme($txt) ne $theme_name))} {
        set curr_theme($txt) $theme_name
        [ns syntax]::set_language $curr_lang($txt) $txt 0
      }

      # Get the preference window theme
      set win_theme [[ns preferences]::get General/WindowTheme]

      # Set the theme in the UI
      if {($win_theme eq "light") || ($win_theme eq "dark")} {

        # Create the ttk theme if it currently does not exist
        if {[lsearch [ttk::style theme names] $win_theme] == -1} {
          create_ttk_theme $win_theme [get_ttk_theme_colors [[ns utils]::get_default_background] [[ns utils]::get_default_foreground]]
        }

        set ttk_theme    $win_theme
        set bg           [[ns utils]::get_default_background]
        set fg           [[ns utils]::get_default_foreground]
        set abg          [[ns utils]::auto_adjust_color $bg 30]
        set menu_opts    [list -background [list -background $bg -foreground $fg -relief flat]
        set tab_opts     [list -background $bg -foreground $fg -activebackground $abg -inactivebackground $bg]
        set syntax_opts  $theme(syntax)
        set sidebar_opts FOOBAR

      } else {

        # Create the ttk theme if it currently does not exist
        if {[lsearch [ttk::style theme names] theme-$theme_name] == -1} {
          create_ttk_theme theme-$theme_name $theme(ttk_style)
        }

        set ttk_theme    "theme-$theme_name"
        set menu_opts    $theme(menus)
        set tab_opts     $theme(tabs)
        set syntax_opts  $theme(syntax)
        set sidebar_opts $theme(sidebar)

      }

      # Set the theme information in the rest of the UI
      ttk::style theme use $ttk_theme
      menus::handle_window_theme   $menu_opts
      gui::handle_window_theme     $tab_opts $syntax_opts
      sidebar::handle_window_theme $tab_opts $sidebar_opts

    }

  }

  ######################################################################
  # Returns a list of colors to use when creating ttk themes, given just
  # two colors (primary and secondary).
  proc get_ttk_theme_colors {primary secondary} {

    # Create the slightly different version of the primary color
    set light_primary [utils::auto_adjust_color $primary 25]

    # Create colors palette
    return [list \
      disabledfg "#999999" \
      frame      $primary \
      lightframe $light_primary \
      window     $primary \
      dark       "#cfcdc8" \
      darker     "#bab5ab" \
      darkest    "#9e9a91" \
      lighter    $secondary \
      lightest   $secondary \
      selectbg   "#4a6984" \
      selectfg   "#ffffff" \
    ]

  }


  ######################################################################
  # Repopulates the specified theme selection menu.
  proc populate_theme_menu {mnu} {

    variable themes

    # Clear the menu
    $mnu delete 0 end

    # Populate the menu with the available themes
    foreach name [lsort [array names themes]] {
      $mnu add radiobutton -label $name -variable [ns syntax]::theme(name) -value $name -command [list [ns themes]::set_theme $name]
    }

    return $mnu

  }

  ######################################################################
  # Initializes the themes list.
  proc initialize {} {

    variable theme_types

    # Add a few styles to the default (light) theme
    ttk::style theme settings clam {

      # BButton
      ttk::style configure BButton [ttk::style configure TButton]
      ttk::style configure BButton -anchor center -padding 2 -relief flat
      ttk::style map       BButton [ttk::style map TButton]
      ttk::style layout    BButton [ttk::style layout TButton]

    }

    # Add the light theme colors
    array set win_types [list \
      light [list [ttk::style configure "." -background] [ttk::style configure "." -foreground]] \
      dark  [list "#303030" "#b0b0b0"]
    ]

    foreach name [array names win_types] {

      # Get the primary and secondary colors for the given theme
      lassign $win_types($name) primary secondary

      # Create the slightly different version of the primary color
      set light_primary [utils::auto_adjust_color $primary 25]

      # Create colors palette
      array set colors [list \
        -disabledfg "#999999" \
        -frame      $primary \
        -lightframe $light_primary \
        -window     $primary \
        -dark       "#cfcdc8" \
        -darker     "#bab5ab" \
        -darkest    "#9e9a91" \
        -lighter    $secondary \
        -lightest   $secondary \
        -selectbg   "#4a6984" \
        -selectfg   "#ffffff" \
      ]

      ttk::style theme create $name -parent clam

      ttk::style theme settings $name {

        ttk::style configure "." \
          -background        $colors(-frame) \
          -foreground        $colors(-lighter) \
          -bordercolor       $colors(-darkest) \
          -darkcolor         $colors(-dark) \
          -troughcolor       $colors(-darker) \
          -arrowcolor        $colors(-lighter) \
          -selectbackground  $colors(-selectbg) \
          -selectforeground  $colors(-selectfg) \
          -selectborderwidth 0 \
          -font              TkDefaultFont

        ttk::style map "." \
          -background       [list disabled $colors(-frame) \
                                  active   $colors(-lighter)] \
          -foreground       [list disabled $colors(-disabledfg)] \
          -selectbackground [list !focus   $colors(-darkest)] \
          -selectforeground [list !focus   white]

        ttk::style configure TButton \
          -anchor center -width -11 -padding 5 -relief raised -background $colors(-frame) -foreground $colors(-lighter)
        ttk::style map TButton \
          -background  [list disabled  $colors(-lighter) \
                             pressed   $colors(-darker) \
                             active    $colors(-lightframe)] \
          -lightcolor  [list pressed   $colors(-darker)] \
          -darkcolor   [list pressed   $colors(-darker)] \
          -bordercolor [list alternate "#000000"]

        ttk::style configure BButton \
          -anchor center -padding 2 -relief flat -background $colors(-frame) -foreground $colors(-frame)
        ttk::style map BButton \
          -background  [list disabled  $colors(-frame) \
                             pressed   $colors(-darker) \
                             active    $colors(-lightframe)] \
          -lightcolor  [list pressed   $colors(-darker)] \
          -darkcolor   [list pressed   $colors(-darker)] \
          -bordercolor [list alternate "#000000"]

        ttk::style configure TMenubutton \
          -width 0 -padding 0 -relief flat -background $colors(-frame) -foreground $colors(-lighter)
        ttk::style map TMenubutton \
          -background  [list disabled  $colors(-frame) \
                             pressed   $colors(-lightframe) \
                             active    $colors(-lightframe)] \
          -lightcolor  [list pressed   $colors(-darker)] \
          -darkcolor   [list pressed   $colors(-darker)] \
          -bordercolor [list alternate "#000000"]

        # ttk::style configure TEntry -padding 1 -insertwidth 1 -fieldbackground $colors(-lighter) -foreground black
        ttk::style configure TEntry -padding 1 -insertwidth 1 -foreground black
        ttk::style map TEntry \
          -background  [list readonly $colors(-frame)] \
          -foreground  [list readonly $colors(-lighter)] \
          -bordercolor [list focus    $colors(-selectbg)] \
          -lightcolor  [list focus    "#6f9dc6"] \
          -darkcolor   [list focus    "#6f9dc6"]

        ttk::style configure TScrollbar \
          -relief flat -troughcolor $colors(-lightframe) ;# -background $colors(-frame) -troughcolor $colors(-frame)
        ttk::style map TScrollbar \
          -background  [list disabled $colors(-frame) \
                             active   $colors(-frame)]

        ttk::style configure TLabelframe \
          -labeloutside true -labelmargins {0 0 0 4} -borderwidth 2 -relief raised

        ttk::style configure TSpinbox \
          -relief flat -padding 2 -background $colors(-frame) -foreground $colors(-lighter) -fieldbackground $colors(-frame)

        ttk::style configure TCheckbutton \
          -relief flat -padding 2 -background $colors(-frame) -foreground $colors(-lighter)
        ttk::style map TCheckbutton \
          -background  [list disabled  $colors(-lighter) \
                             pressed   $colors(-darker) \
                             active    $colors(-lightframe)] \
          -lightcolor  [list pressed   $colors(-darker)] \
          -darkcolor   [list pressed   $colors(-darker)] \
          -bordercolor [list alternate "#000000"]

        ttk::style configure Sash -sashthickness 5 -gripcount 10

      }

    }

  }

}
