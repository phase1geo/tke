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

  array set themes {
    dark {"#303030" "#b0b0b0"}
  }

  ######################################################################
  # Initializes the themes list.
  proc initialize {} {

    variable themes

    # Add a few styles to the default (light) theme
    ttk::style theme settings clam {

      # BButton
      ttk::style configure BButton [ttk::style configure TButton]
      ttk::style configure BButton -anchor center -padding 2 -relief flat
      ttk::style map       BButton [ttk::style map TButton]
      ttk::style layout    BButton [ttk::style layout TButton]

    }

    # Add the light theme colors
    array set themes [list \
      light [list [ttk::style configure "." -background] [ttk::style configure "." -foreground]] \
    ]

    foreach name [array names themes] {

      # Get the primary and secondary colors for the given theme
      lassign $themes($name) primary secondary

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

#        ttk::style configure DButton \
#          -anchor center -width -11 -padding 5 -relief sunken -background $colors(-darker) -foreground $colors(-frame)
#        ttk::style map DButton \
#          -background  [list disabled  $colors(-lighter) \
#                             pressed   $colors(-darker) \
#                             active    $colors(-darker)] \
#          -lightcolor  [list pressed   $colors(-darker)] \
#          -darkcolor   [list pressed   $colors(-darker)] \
#          -bordercolor [list alternate "#000000"]

#        ttk::style configure FButton \
#          -anchor center -padding 2 -relief flat -background $colors(-lightframe) -foreground $colors(-frame)
#        ttk::style map FButton \
#          -background  [list disabled  $colors(-lighter) \
#                             pressed   $colors(-darker) \
#                             active    $colors(-dark)] \
#          -lightcolor  [list pressed   $colors(-darker)] \
#          -darkcolor   [list pressed   $colors(-darker)] \
#          -bordercolor [list alternate "#000000"]

        ttk::style configure BButton \
          -anchor center -padding 2 -relief flat -background $colors(-frame) -foreground $colors(-frame)
        ttk::style map BButton \
          -background  [list disabled  $colors(-frame) \
                             pressed   $colors(-darker) \
                             active    $colors(-lightframe)] \
          -lightcolor  [list pressed   $colors(-darker)] \
          -darkcolor   [list pressed   $colors(-darker)] \
          -bordercolor [list alternate "#000000"]

#        ttk::style configure LButton \
#          -anchor center -padding 4 -relief flat -background $colors(-frame) -foreground $colors(-frame)
#        ttk::style map LButton \
#          -background  [list disabled  $colors(-frame) \
#                             pressed   $colors(-darker) \
#                             active    $colors(-dark)] \
#          -lightcolor  [list pressed   $colors(-darker)] \
#          -darkcolor   [list pressed   $colors(-darker)] \
#          -bordercolor [list alternate "#000000"]

#        ttk::style configure Toolbutton \
#          -anchor center -padding 2 -relief flat
#        ttk::style map Toolbutton \
#          -relief     [list disabled flat \
#                            selected sunken \
#                            pressed  sunken \
#                            active   raised] \
#          -background [list disabled $colors(-frame) \
#                            pressed  $colors(-darker) \
#                            active   $colors(-lighter)] \
#          -lightcolor [list pressed  $colors(-darker)] \
#          -darkcolor  [list pressed  $colors(-darker)]

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

    # Watch for any changes to the General/WindowTheme preference value
    trace variable preferences::prefs(General/WindowTheme) w "themes::handle_theme_change"

  }

  ######################################################################
  # Handles any changes to the General/WindowTheme preference variable.
  proc handle_theme_change {{name1 ""} {name2 ""} {op ""}} {

    variable themes

    set theme $preferences::prefs(General/WindowTheme)

    if {[info exists themes($theme)]} {
      ttk::style theme use         $theme
      menus::handle_window_theme   $theme
      gui::handle_window_theme     $theme
      sidebar::handle_window_theme $theme
    }

  }

}
