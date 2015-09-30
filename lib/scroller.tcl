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

  ######################################################################
  # Creates the difference map which is basically a colored scrollbar.
  proc scroller {win txt args} {

    variable data

    array set opts {
      -command ""
    }
    array set opts $args

    # Get the background color
    set bg [utils::get_default_background]

    # Create the canvas
    set data($txt,canvas) [canvas $win -width 15 -relief flat -bd 1 -highlightthickness 0 -bg $bg]

    # Create canvas bindings
    bind $data($txt,canvas) <Configure>  [list [ns diff]::map_configure $txt]
    bind $data($txt,canvas) <Button-1>   [list [ns diff]::map_position_slider %W %y $txt $opts(-command)]
    bind $data($txt,canvas) <B1-Motion>  [list [ns diff]::map_position_slider %W %y $txt $opts(-command)]
    bind $data($txt,canvas) <MouseWheel> "event generate $txt.t <MouseWheel> -delta %D"
    bind $data($txt,canvas) <4>          "event generate $txt.t <4>"
    bind $data($txt,canvas) <5>          "event generate $txt.t <5>"

    rename ::$win $win
    interp alias {} ::$win {} [ns diff]::widget_command $txt

    return $win

  }

  ######################################################################
  # Executes map commands.
  proc widget_command {txt args} {

    variable data

    set args [lassign $args cmd]

    switch $cmd {

      set {
        lassign $args first last
        set height [winfo height $data($txt,canvas)]
        set y1     [expr int( $height * $first )]

        # Adjust the size and position of the slider
        $data($txt,canvas) coords $data($txt,slider) 2 [expr $y1 + 2] 15 [expr $y1 + $data($txt,sheight)]
      }

      default {
        return -code error "scroller called with invalid command ($cmd)"
      }

    }

  }

  ######################################################################
  # Handles a left-click or click-drag in the canvas area, positioning
  # the cursor at the given position.
  proc map_position_slider {W y txt cmd} {

    variable data

    if {$cmd ne ""} {

      # Calculate the moveto fraction
      set moveto [expr ($y.0 - ($data($txt,sheight) / 2)) / [winfo height $W]]

      # Call the command
      uplevel #0 "$cmd moveto $moveto"

    }

  }

  ######################################################################
  # Called whenever the map widget is configured.
  proc map_configure {txt} {

    variable data

    # Remove all canvas items
    $data($txt,canvas) delete all

    # Add the difference bars
    foreach type [list sub add] {
      foreach {start end} [$txt diff ranges $type] {
        set start_line [lindex [split $start .] 0]
        set end_line   [lindex [split $end .] 0]
        map_add $txt $type $start_line [expr $end_line - $start_line]
      }
    }

    # Calculate the slider height
    lassign [$txt yview] first last
    set height             [winfo height $data($txt,canvas)]
    set sheight            [expr ((int( $height * $last ) - int( $height * $first )) + 1) - 4]
    set data($txt,sheight) [expr ($sheight < 11) ? 11 : $sheight]

    # Add cursor
    set bg                [utils::get_default_background]
    set abg               [utils::auto_adjust_color $bg 50]
    set data($txt,slider) [$data($txt,canvas) create rectangle 2 0 15 10 -outline $abg -width 2]
    map_command $txt set $first $last

  }

  ######################################################################
  # Adds a sub or add bar to the associated widget.
  proc map_add {txt type start lines} {

    variable data

    # Get the number of lines in the text widget
    set txt_lines [lindex [split [$txt index end-1c] .] 0]

    # Get the height of the box to add
    set y1 [expr int( ($start.0 / $txt_lines) * [winfo height $data($txt,canvas)] )]
    set y2 [expr int( (($start + $lines.0) / $txt_lines) * [winfo height $data($txt,canvas)] )]

    # Get the color to display
    set color [expr {($type eq "sub") ? [$txt cget -diffsubbg] : [$txt cget -diffaddbg]}]

    # Create the rectangle and place it in the widget
    $data($txt,canvas) create rectangle 0 $y1 15 $y2 -fill $color -width 0

  }

}

