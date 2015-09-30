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
# Name:     scroller.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     3/23/2015
# Brief:    Scrollbar used in editor.
######################################################################

namespace eval scroller {

  array set data {}

  ######################################################################
  # Creates the difference map which is basically a colored scrollbar.
  proc scroller {win args} {

    variable data

    array set opts {
      -background "black"
      -foreground "white"
      -orient     "vertical"
      -command    ""
    }
    array set opts $args

    set data($win,-background) $opts(-background)
    set data($win,-foreground) $opts(-foreground)
    set data($win,-orient)     $opts(-orient)

    # Create the canvas
    if {$data($win,-orient) eq "vertical"} {
      set data($win,canvas) [canvas $win -width 15  -relief flat -bd 1 -highlightthickness 0 -bg $data($win,-background)]
    } else {
      set data($win,canvas) [canvas $win -height 15 -relief flat -bd 1 -highlightthickness 0 -bg $data($win,-background)]
    }

    # Create canvas bindings
    bind $data($win,canvas) <Configure>  [list scroller::configure $win]
    bind $data($win,canvas) <Button-1>   [list scroller::position_slider %W %y $opts(-command)]
    bind $data($win,canvas) <B1-Motion>  [list scroller::position_slider %W %y $opts(-command)]

    rename ::$win $win
    interp alias {} ::$win {} scroller::widget_command $win

    return $win

  }

  ######################################################################
  # Executes map commands.
  proc widget_command {win args} {

    variable data

    set args [lassign $args cmd]

    switch $cmd {

      set {
        lassign $args first last
        if {$data($win,-orient) eq "vertical"} {
          set height [winfo height $data($win,canvas)]
          set x1     0
          set y1     [expr int( $height * $first )]
          set x2     15
          set y2     [expr $y1 + $data($win,ssize)]
        } else {
          set width  [winfo width $data($win,canvas)]
          set x1     [expr int( $width * $first )]
          set y1     0
          set x2     [expr $x1 + $data($win,ssize)]
          set y2     15
        }

        # Adjust the size and position of the slider
        $data($win,canvas) coords $data($win,slider) [expr $x1 + 2] [expr $y1 + 2] $x2 $y2
      }

      configure {
        array set opts $args
        if {[info exists opts(-background)]} {
          set data($win,-background) $opts(-background)
        }
        if {[info exists opts(-foreground)]} {
          set data($win,-foreground) $opts(-foreground)
        }
        $data($win,canvas) configure -bg $data($win,-background)
        $data($win,canvas) itemconfigure $data($win,slider) -outline $data($win,-foreground)
      }

      default {
        return -code error "scroller called with invalid command ($cmd)"
      }

    }

  }

  ######################################################################
  # Handles a left-click or click-drag in the canvas area, positioning
  # the cursor at the given position.
  proc position_slider {W y cmd} {

    variable data

    if {$cmd ne ""} {

      # Calculate the moveto fraction
      set moveto [expr ($y.0 - ($data($W,ssize) / 2)) / [winfo height $W]]

      # Call the command
      uplevel #0 "$cmd moveto $moveto"

    }

  }

  ######################################################################
  # Called whenever the map widget is configured.
  proc configure {win} {

    variable data

    # Remove all canvas items
    $data($win,canvas) delete all

    # Calculate the slider height
    lassign [$win yview] first last
    if {$data($win,-orient) eq "vertical"} {
      set size [winfo height $data($win,canvas)]
      lassign {2 0 15 10} x1 y1 x2 y2
    } else {
      set size [winfo width $data($win,canvas)]
      lassign {2 0 15 10} y1 x1 y2 x2
    }
    set ssize            [expr ((int( $size * $last ) - int( $size * $first )) + 1) - 4]
    set data($win,ssize) [expr ($ssize < 11) ? 11 : $ssize]

    # Add cursor
    set data($win,slider) [$data($win,canvas) create rectangle $x1 $y1 $x2 $y2 -outline $data($win,-foreground) -width 2]
    widget_command $win set $first $last

  }

}

