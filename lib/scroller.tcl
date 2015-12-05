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
      -background   "black"
      -foreground   "white"
      -orient       "vertical"
      -command      ""
      -markcommand1 ""
      -markcommand2 ""
      -thickness    15
      -markhide1    0
      -markhide2    0
      -autohide     0
    }
    array set opts $args

    set data($win,-background)   $opts(-background)
    set data($win,-foreground)   $opts(-foreground)
    set data($win,-orient)       $opts(-orient)
    set data($win,-command)      $opts(-command)
    set data($win,-markcommand1) $opts(-markcommand1)
    set data($win,-markcommand2) $opts(-markcommand2)
    set data($win,-thickness)    $opts(-thickness)
    set data($win,-markhide1)    $opts(-markhide1)
    set data($win,-markhide2)    $opts(-markhide2)
    set data($win,-autohide)     $opts(-autohide)

    # Constant values
    set data($win,minwidth)  3
    set data($win,minheight) 21

    # Variables
    set data($win,extra_width)  [expr {(($opts(-markcommand1) ne "") ? 3 : 0) + (($opts(-markcommand2) ne "") ? 3 : 0)}]
    set data($win,slider_width) $data($win,minwidth)
    set data($win,pressed)      0
    set data($win,first)        0.0
    set data($win,last)         1.0
    set data($win,marks)        0

    # Create the canvas
    if {$data($win,-orient) eq "vertical"} {
      set data($win,canvas) [canvas $win -width  [expr $data($win,-thickness) + $data($win,extra_width)] -relief flat -bd 1 -highlightthickness 0 -bg $data($win,-background)]
    } else {
      set data($win,canvas) [canvas $win -height $data($win,-thickness) -relief flat -bd 1 -highlightthickness 0 -bg $data($win,-background)]
    }

    # Create canvas bindings
    bind $data($win,canvas) <Configure>                  [list scroller::configure       %W]
    bind $data($win,canvas) <ButtonPress-1>              [list scroller::position_slider %W %x %y 0]
    bind $data($win,canvas) <ButtonRelease-1>            [list scroller::release_slider  %W]
    bind $data($win,canvas) <ButtonPress-$::right_click> [list scroller::page_slider     %W %x %y]
    bind $data($win,canvas) <B1-Motion>                  [list scroller::position_slider %W %x %y 1]
    bind $data($win,canvas) <Enter>                      [list scroller::expand_slider   %W]
    bind $data($win,canvas) <Leave>                      [list scroller::collapse_slider %W]
    bind $data($win,canvas) <MouseWheel>                 [list scroller::wheel_slider    %W %D]
    bind $data($win,canvas) <4>                          [list scroller::wheel_slider    %W 1]
    bind $data($win,canvas) <5>                          [list scroller::wheel_slider    %W -1]

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
        if {![info exists data($win,slider)]} {
          return
        }
        lassign $args first last
        set data($win,first) $first
        set data($win,last)  $last
        if {$data($win,-orient) eq "vertical"} {
          set height [winfo height $data($win,canvas)]
          set x1     [expr ($data($win,-thickness) + $data($win,extra_width)) - $data($win,slider_width)]
          set y1     [expr int( $height * $first )]
          set x2     [expr $data($win,-thickness) + $data($win,extra_width)]
          set y2     [expr int( $height * $last )]
          if {($y2 - $y1) < $data($win,minheight)} {
            set height [expr $height - ($data($win,minheight) - ($y2 - $y1))]
            set y1     [expr int( $height * $first )]
            set y2     [expr $y1 + $data($win,minheight)]
          }
          $data($win,canvas) configure -width [expr (($first == 0) && ($last == 1) && ($data($win,marks) == 0) && $data($win,-autohide)) ? 0 : ($data($win,-thickness) + $data($win,extra_width))]
        } else {
          set width  [winfo width $data($win,canvas)]
          set x1     [expr int( $width * $first )]
          set y1     [expr $data($win,-thickness) - $data($win,slider_width)]
          set x2     [expr int( $width * $last )]
          set y2     $data($win,-thickness)
          if {($x2 - $x1) < $data($win,minheight)} {
            set width [expr $width - ($data($win,minheight) - ($x2 - $x1))]
            set x1    [expr int( $width * $first )]
            set x2    [expr $x1 + $data($win,minheight)]
          }
          $data($win,canvas) configure -height [expr (($first == 0) && ($last == 1) && ($data($win,marks) == 0) && $data($win,-autohide)) ? 0 : $data($win,-thickness)]
        }
        $data($win,canvas) coords $data($win,slider) [expr $x1 + 2] [expr $y1 + 2] $x2 $y2
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
            $data($win,canvas) configure -width [expr $data($win,-thickness) + $data($win,extra_width)]
          } else {
            $data($win,canvas) configure -height $data($win,-thickness)
          }
        }
        if {($data($win,-orient) eq "vertical") && ([info exists opts(-markhide1)] || [info exists opts(-markhide2)])} {
          for {set i 1} {$i <= 2} {incr i} {
            if {[info exists opts(-markhide$i)]} {
              set data($win,-markhide$i) $opts(-markhide$i)
            }
          }
          update_markers $win
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

      if {$motion || ([$data($W,canvas) find withtag current] ne $data($W,slider))} {

        # Get the coordinates for the slider
        lassign [$data($W,canvas) coords $data($W,slider)] x1 y1 x2 y2

        # Calculate the moveto fraction
        if {$data($W,-orient) eq "vertical"} {
          set moveto [expr ($y.0 - (($y2 - $y1) / 2)) / [winfo height $W]]
        } else {
          set moveto [expr ($x.0 - (($x2 - $x1) / 2)) / [winfo width $W]]
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

      set data($W,slider_width) $data($W,-thickness)

      lassign [eval $data($W,-command)] first last

      widget_command $W set $first $last

    }

  }

  ######################################################################
  # Collapses the slider to make it less obtrusive.
  proc collapse_slider {W} {

    variable data

    if {!$data($W,pressed)} {

      set data($W,slider_width) $data($W,minwidth)

      lassign [eval $data($W,-command)] first last

      widget_command $W set $first $last

    }

  }

  ######################################################################
  # Moves the text view up or left by a page.
  proc page_slider {W x y} {

    variable data

    if {[$data($W,canvas) find withtag current] ne $data($W,slider)} {
      lassign [$data($W,canvas) coords $data($W,slider)] x1 y1
      if {(($data($W,-orient) eq "vertical") && ($y < $y1)) || (($data($W,-orient) eq "horizontal") && ($x < $x1))} {
        uplevel #0 [list {*}$data($W,-command) scroll -1 pages]
      } else {
        uplevel #0 [list {*}$data($W,-command) scroll  1 pages]
      }
    }

  }

  ######################################################################
  # Moves the text view via a mousewheel event.
  proc wheel_slider {W d} {

    variable data

    switch [tk windowingsystem] {
      x11 -
      aqua  { uplevel #0 [list {*}$data($W,-command) scroll [expr -($d)] units] }
      win32 { uplevel #0 [list {*}$data($W,-command) scroll [expr int( pow( %d / -120, 3))]] }
    }

  }

  ######################################################################
  # Called whenever the map widget is configured.
  proc configure {win} {

    variable data

    # Remove all canvas items
    $data($win,canvas) delete all

    # Draw the markers
    update_markers $win

    # Add the slider
    set data($win,slider) [$data($win,canvas) create rectangle 0 0 1 1 -outline $data($win,-foreground) -fill $data($win,-foreground) -width 2]

    # Set the size and position of the slider
    widget_command $win set {*}[eval $data($win,-command)]

  }

  ######################################################################
  # Draw the markers in the scrollbar.
  proc update_markers {win} {

    variable data

    # Get the lines
    set height [winfo height $win]

    # Delete all markers
    $data($win,canvas) delete mark

    # Clear the marker count
    set data($win,marks) 0

    for {set i 1} {$i <= 2} {incr i} {

      # If the -markcommandx was not set or the -hide indicator is set for markcommand1, don't continue
      if {($data($win,-markcommand$i) eq "") || $data($win,-markhide$i)} {
        continue
      }

      # Draw each of the markers
      foreach {startpos endpos color} [uplevel #0 $data($win,-markcommand$i)] {
        set x1 [expr ($i == 1) ? 0 : 3]
        set y1 [expr int( $height * $startpos)]
        set x2 [expr $data($win,-thickness) + $data($win,extra_width)]
        set y2 [expr int( $height * $endpos)]
        set marker [$data($win,canvas) create rectangle $x1 $y1 $x2 $y2 -fill $color -width 0 -tags mark]
        incr data($win,marks)
      }

    }

    # Put the scrollbar above everything
    catch { $data($win,canvas) raise $data($win,slider) }

  }

}

