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
      -background  "black"
      -foreground  "white"
      -orient      "vertical"
      -command     ""
      -markcommand ""
      -thickness   15
    }
    array set opts $args

    set data($win,-background)  $opts(-background)
    set data($win,-foreground)  $opts(-foreground)
    set data($win,-orient)      $opts(-orient)
    set data($win,-command)     $opts(-command)
    set data($win,-markcommand) $opts(-markcommand)
    set data($win,-thickness)   $opts(-thickness)

    # Constant values
    set data($win,minwidth)  3
    set data($win,minheight) 21

    # Variables
    set data($win,width)   $data($win,minwidth)
    set data($win,pressed) 0
    set data($win,first)   0.0
    set data($win,last)    1.0

    # Create the canvas
    if {$data($win,-orient) eq "vertical"} {
      set data($win,canvas) [canvas $win -width  $data($win,-thickness) -relief flat -bd 1 -highlightthickness 0 -bg $data($win,-background)]
    } else {
      set data($win,canvas) [canvas $win -height $data($win,-thickness) -relief flat -bd 1 -highlightthickness 0 -bg $data($win,-background)]
    }

    # Create canvas bindings
    bind $data($win,canvas) <Configure>       [list scroller::configure       %W]
    bind $data($win,canvas) <ButtonPress-1>   [list scroller::position_slider %W %x %y 0]
    bind $data($win,canvas) <ButtonRelease-1> [list scroller::release_slider  %W]
    bind $data($win,canvas) <B1-Motion>       [list scroller::position_slider %W %x %y 1]
    bind $data($win,canvas) <Enter>           [list scroller::expand_slider   %W]
    bind $data($win,canvas) <Leave>           [list scroller::collapse_slider %W]

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

      get {
        return [list $data($win,first) $data($win,last)]
      }

      set {
        if {![info exists data($win,ssize)]} {
          return
        }
        lassign $args first last
        set data($win,first) $first
        set data($win,last)  $last
        if {$data($win,-orient) eq "vertical"} {
          set height [winfo height $data($win,canvas)]
          set x1     [expr $data($win,-thickness) - $data($win,width)]
          set y1     [expr int( $height * $first )]
          set x2     $data($win,-thickness)
          set y2     [expr $y1 + $data($win,ssize)]
        } else {
          set width  [winfo width $data($win,canvas)]
          set x1     [expr int( $width * $first )]
          set y1     [expr $data($win,-thickness) - $data($win,width)]
          set x2     [expr $x1 + $data($win,ssize)]
          set y2     $data($win,-thickness)
        }

        # Adjust the size and position of the slider
        $data($win,canvas) coords $data($win,slider) [expr $x1 + 2] [expr $y1 + 2] $x2 $y2

        # Draw the markers
        update_markers $win
      }

      configure {
        array set opts $args
        if {[info exists opts(-background)]} {
          set data($win,-background) $opts(-background)
          $data($win,canvas) configure -bg $data($win,-background)
        }
        if {[info exists opts(-foreground)]} {
          set data($win,-foreground) $opts(-foreground)
          if {[info exists data($win,slider)]} {
            $data($win,canvas) itemconfigure $data($win,slider) -outline $data($win,-foreground) -fill $data($win,-foreground)
          }
        }
        if {[info exists opts(-thickness)]} {
          set data($win,-thickness) $opts(-thickness)
          if {$data($win,-orient) eq "vertical"} {
            $data($win,canvas) configure -width $data($win,-thickness)
          } else {
            $data($win,canvas) configure -height $data($win,-thickness)
          }
        }
      }

      default {
        return -code error "scroller called with invalid command ($cmd)"
      }

    }

  }

  ######################################################################
  # Handles a left-click or click-drag in the canvas area, positioning
  # the cursor at the given position.
  proc position_slider {W x y motion} {

    variable data

    if {$data($W,-command) ne ""} {

      # Indicate that we are pressed
      set data($W,pressed) 1

      if {$motion || ([$data($W,canvas) find withtag current] eq "")} {

        # Calculate the moveto fraction
        if {$data($W,-orient) eq "vertical"} {
          set moveto [expr ($y.0 - ($data($W,ssize) / 2)) / [winfo height $W]]
        } else {
          set moveto [expr ($x.0 - ($data($W,ssize) / 2)) / [winfo width $W]]
        }

        # Call the command
        uplevel #0 "$data($W,-command) moveto $moveto"

      }

    }

  }

  ######################################################################
  # Indicate that the slider button has been released.
  proc release_slider {W} {

    variable data

    set data($W,pressed) 0

  }

  ######################################################################
  # Expands the slider to make it easier to grab.
  proc expand_slider {W} {

    variable data

    if {!$data($W,pressed)} {

      set data($W,width) $data($W,-thickness)

      lassign [eval $data($W,-command)] first last

      widget_command $W set $first $last

    }

  }

  ######################################################################
  # Collapses the slider to make it less obtrusive.
  proc collapse_slider {W} {

    variable data

    if {!$data($W,pressed)} {

      set data($W,width) $data($W,minwidth)

      lassign [eval $data($W,-command)] first last

      widget_command $W set $first $last

    }

  }

  ######################################################################
  # Called whenever the map widget is configured.
  proc configure {win} {

    variable data

    # Remove all canvas items
    $data($win,canvas) delete all

    # Calculate the slider height
    lassign [eval $data($win,-command)] first last
    if {$data($win,-orient) eq "vertical"} {
      set size [winfo height $data($win,canvas)]
      lassign [list [expr $data($win,-thickness) - $data($win,minwidth)] 0 $data($win,-thickness) [expr $data($win,minheight) - 1]] x1 y1 x2 y2
    } else {
      set size [winfo width $data($win,canvas)]
      lassign [list [expr $data($win,-thickness) - $data($win,minwidth)] 0 $data($win,-thickness) [expr $data($win,minheight) - 1]] y1 x1 y2 x2
    }
    set ssize            [expr ((int( $size * $last ) - int( $size * $first )) + 1) - 4]
    set data($win,ssize) [expr ($ssize < $data($win,minheight)) ? $data($win,minheight) : $ssize]

    # Add the slider
    set data($win,slider) [$data($win,canvas) create rectangle $x1 $y1 $x2 $y2 -outline $data($win,-foreground) -fill $data($win,-foreground) -width 2]

    # Run the set command
    widget_command $win set $first $last

  }

  ######################################################################
  # Draw the markers in the scrollbar.
  proc update_markers {win} {

    variable data

    # If the -markcommand was not set, don't continue
    if {$data($win,-markcommand) eq ""} {
      return
    }

    # Delete all markers
    $data($win,canvas) delete mark

    # Get the lines
    set height [winfo height $win]

    # Draw each of the markers
    foreach {startpos endpos color} [uplevel #0 $data($win,-markcommand)] {
      # set x1 [expr $data($win,-thickness) - $data($win,width)]
      set x1 0
      set y1 [expr int( $height * $startpos)]
      set x2 $data($win,-thickness)
      set y2 [expr int( $height * $endpos)]
      $data($win,canvas) create rectangle $x1 $y1 $x2 $y2 -fill $color -width 0 -tags mark
    }

  }

}

