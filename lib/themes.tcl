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
  array set colorizers {
    keywords       1
    comments       1
    strings        1
    numbers        1
    punctuation    1
    precompile     1
    miscellaneous1 1
    miscellaneous2 1
    miscellaneous3 1
  }

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

    set_theme [[ns preferences]::get Appearance/Theme]

  }

  ######################################################################
  # Called whenever the Appearance/Colorize preference value is changed.
  proc handle_colorize_change {name1 name2 op} {

    set_theme [[ns preferences]::get Appearance/Theme]

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
    set_theme $curr_theme

  }

  ######################################################################
  # Sets the theme to the specified value.  Returns 1 if the theme was
  # set; otherwise, returns 0.
  proc set_theme {{theme_name ""}} {

    variable files
    variable themes
    variable theme
    variable colorizers
    variable curr_theme
    variable base_colors

    # If the theme was not set, default to the current theme
    if {$theme_name eq ""} {
      set theme_name $curr_theme
    }

    # If the theme name is not valid, return immediately
    if {![info exists files($theme_name)]} {
      return
    }

    # Load the theme file, if necessary
    if {![info exists themes($theme_name)]} {
      if {![catch { open $files($theme_name) r } rc]} {
        puts "READING THEME FILE, theme_name: $theme_name!"
        set themes($theme_name) [list {*}[read $rc]]
        close $rc
      } else {
        return
      }
    }

    # Get the preference window theme
    set win_theme [[ns preferences]::get General/WindowTheme]

    # Save the current theme name
    set curr_theme $theme_name

    # Set the current theme array
    array unset theme
    array set theme $themes($theme_name)

    # Make ourselves backwards compatible
    if {![info exists theme(syntax)]} {
      set temp [array get theme]
      array unset theme
      set theme(syntax) $temp
      if {$win_theme eq "themed"} {
        set win_theme "light"
      }
    }

    # Remove theme values that aren't in the Appearance/Colorize array
    array set syntax $theme(syntax)
    foreach name [array names theme(syntax)] {
      if {[info exists colorizers($name)] && ([lsearch [[ns preferences]::get Appearance/Colorize] $name] == -1)} {
        set syntax($name) ""
      }
    }
    set theme(syntax) [array get syntax]

    # Set the theme in the UI
    puts "win_theme: $win_theme"
    if {($win_theme eq "light") || ($win_theme eq "dark")} {

      # Create the ttk theme if it currently does not exist
      if {[lsearch [ttk::style theme names] $win_theme] == -1} {
        create_ttk_theme $win_theme [get_ttk_theme_colors {*}$base_colors($win_theme)]
      }

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

    } else {

      # Create the ttk theme if it currently does not exist
      if {[lsearch [ttk::style theme names] theme-$theme_name] == -1} {
        create_ttk_theme theme-$theme_name $theme(ttk_style)
      }

      # Set the ttk theme
      ttk::style theme use "theme-$theme_name"

      set menu_opts    $theme(menus)
      set tab_opts     $theme(tabs)
      set tsb_opts     $theme(text_scrollbar)
      set sidebar_opts $theme(sidebar)
      set ssb_opts     $theme(sidebar_scrollbar)
      set syntax_opts  $theme(syntax)

    }

    # Set the theme information in the rest of the UI
    menus::handle_theme_change   $menu_opts
    gui::handle_theme_change     $tab_opts $tsb_opts $syntax_opts
    sidebar::handle_theme_change $sidebar_opts $ssb_opts

  }

  ######################################################################
  # Returns the currently selected theme.
  proc get_current_theme {} {

    variable curr_theme

    return $curr_theme

  }

  ######################################################################
  # Returns the syntax color theme information for the current theme.
  proc get_syntax_colors {} {

    variable theme

    return $theme(syntax)

  }

  ######################################################################
  # Returns the scrollbar color theme information for the current theme.
  proc get_scrollbar_colors {} {

    variable theme

    return $theme(text_scrollbar)

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

    variable files

    # Clear the menu
    $mnu delete 0 end

    # Populate the menu with the available themes
    foreach name [lsort [array names files]] {
      $mnu add radiobutton -label $name -variable [ns themes]::curr_theme -value $name -command [list [ns themes]::set_theme $name]
    }

    return $mnu

  }

  ######################################################################
  # Initializes the themes list.
  proc create_ttk_theme {name color_list} {

    # Add a few styles to the default (light) theme
    ttk::style theme settings clam {

      # BButton
      ttk::style configure BButton [ttk::style configure TButton]
      ttk::style configure BButton -anchor center -padding 2 -relief flat
      ttk::style map       BButton [ttk::style map TButton]
      ttk::style layout    BButton [ttk::style layout TButton]

    }

    # Create colors palette
    array set colors $color_list

    # Create the theme
    ttk::style theme create $name -parent clam

    # Configure the theme
    ttk::style theme settings $name {

      # Configure the application
      ttk::style configure "." \
        -background        $colors(frame) \
        -foreground        $colors(lighter) \
        -bordercolor       $colors(darkest) \
        -darkcolor         $colors(dark) \
        -troughcolor       $colors(darker) \
        -arrowcolor        $colors(lighter) \
        -selectbackground  $colors(selectbg) \
        -selectforeground  $colors(selectfg) \
        -selectborderwidth 0 \
        -font              TkDefaultFont
      ttk::style map "." \
        -background       [list disabled $colors(frame) \
                                active   $colors(lighter)] \
        -foreground       [list disabled $colors(disabledfg)] \
        -selectbackground [list !focus   $colors(darkest)] \
        -selectforeground [list !focus   white]

      # Configure TButton widgets
      ttk::style configure TButton \
        -anchor center -width -11 -padding 5 -relief raised -background $colors(frame) -foreground $colors(lighter)
      ttk::style map TButton \
        -background  [list disabled  $colors(lighter) \
                           pressed   $colors(darker) \
                           active    $colors(lightframe)] \
        -lightcolor  [list pressed   $colors(darker)] \
        -darkcolor   [list pressed   $colors(darker)] \
        -bordercolor [list alternate "#000000"]

      # Configure BButton widgets
      ttk::style configure BButton \
        -anchor center -padding 2 -relief flat -background $colors(frame) -foreground $colors(lighter)
      ttk::style map BButton \
        -background  [list disabled  $colors(frame) \
                           pressed   $colors(darker) \
                           active    $colors(lightframe)] \
        -lightcolor  [list pressed   $colors(darker)] \
        -darkcolor   [list pressed   $colors(darker)] \
        -bordercolor [list alternate "#000000"]

      # Configure ttk::menubutton widgets
      ttk::style configure TMenubutton \
        -width 0 -padding 0 -relief flat -background $colors(frame) -foreground $colors(lighter)
      ttk::style map TMenubutton \
        -background  [list disabled  $colors(frame) \
                           pressed   $colors(lightframe) \
                           active    $colors(lightframe)] \
        -lightcolor  [list pressed   $colors(darker)] \
        -darkcolor   [list pressed   $colors(darker)] \
        -bordercolor [list alternate "#000000"]

      # Configure ttk::radiobutton widgets
      ttk::style configure TRadiobutton \
        -width 0 -padding 0 -relief flat -background $colors(frame) -foreground $colors(lighter)
      ttk::style map TRadiobutton \
        -background  [list disabled $colors(frame) \
                           active   $colors(lightframe)]

      # Configure ttk::entry widgets
      ttk::style configure TEntry -padding 1 -insertwidth 1 -foreground black
      ttk::style map TEntry \
        -background  [list readonly $colors(frame)] \
        -foreground  [list readonly $colors(lighter)] \
        -bordercolor [list focus    $colors(selectbg)] \
        -lightcolor  [list focus    "#6f9dc6"] \
        -darkcolor   [list focus    "#6f9dc6"]

      # Configure ttk::scrollbar widgets
      ttk::style configure TScrollbar \
        -relief flat -troughcolor $colors(lightframe) ;# -background $colors(-frame) -troughcolor $colors(-frame)
      ttk::style map TScrollbar \
        -background  [list disabled $colors(frame) \
                           active   $colors(frame)]

      # Configure ttk::labelframe widgets
      ttk::style configure TLabelframe \
        -labeloutside true -labelmargins {0 0 0 4} -borderwidth 2 -relief raised

      # Configure ttk::spinbox widgets
      ttk::style configure TSpinbox \
        -relief flat -padding 2 -background $colors(frame) -foreground $colors(lighter) -fieldbackground $colors(frame)

      # Configure ttk::checkbutton widgets
      ttk::style configure TCheckbutton \
        -relief flat -padding 2 -background $colors(frame) -foreground $colors(lighter)
      ttk::style map TCheckbutton \
        -background  [list disabled  $colors(lighter) \
                           pressed   $colors(darker) \
                           active    $colors(lightframe)] \
        -lightcolor  [list pressed   $colors(darker)] \
        -darkcolor   [list pressed   $colors(darker)] \
        -bordercolor [list alternate "#000000"]

      # Configure panedwindow sash widgets
      ttk::style configure Sash -sashthickness 5 -gripcount 10

    }

  }

}
