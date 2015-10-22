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
# Name:    bitmap.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    05/21/2013
# Brief:   Widget tool to create a two-color bitmap.
######################################################################

set tke_dir [file join ~ projects tke-code]

source [file join $::tke_dir lib utils.tcl]

namespace eval bitmap {

  array set data {}

  if {[catch { ttk::spinbox .__tmp }]} {
    set bg                [utils::get_default_background]
    set fg                [utils::get_default_foreground]
    set data(sb)          "spinbox"
    set data(sb_opts)     "-relief flat -buttondownrelief flat -buttonuprelief flat -background $bg -foreground $fg"
    set data(sb_normal)   "configure -state normal"
    set data(sb_disabled) "configure -state disabled"
  } else {
    set data(sb)          "ttk::spinbox"
    set data(sb_opts)     ""
    set data(sb_normal)   "state !disabled"
    set data(sb_disabled) "state disabled"
    destroy .__tmp
  }

  ######################################################################
  # Creates a bitmap widget and returns the widget name.
  proc create {w args} {

    variable data

    array set opts {
      -background white
      -color1     blue
      -color2     green
      -size       10
      -width      16
      -height     16
      -swatches   {}
    }

    array set opts $args

    set data($w,-background) $opts(-background)
    set data($w,-size)       $opts(-size)
    set data($w,colors)      [list $opts(-background) $opts(-color1) $opts(-color2)]
    set data($w,-width)      $opts(-width)
    set data($w,-height)     $opts(-height)
    set data($w,-swatches)   $opts(-swatches)

    ttk::frame $w

    # Create the bitmap canvas
    set width  [expr ($data($w,-width)  * $data($w,-size)) + 1]
    set height [expr ($data($w,-height) * $data($w,-size)) + 1]
    set data($w,grid) [canvas $w.c -background $opts(-background) -width $width -height $height]

    bind $data($w,grid) <B1-Motion> [list bitmap::change_square_motion $w %x %y]
    bind $data($w,grid) <B3-Motion> [list bitmap::change_square_motion $w %x %y]

    # Create the right frame
    ttk::frame $w.rf
    set data($w,plabel) [label $w.rf.p -background black]
    ttk::label $w.rf.l1 -text "Color-1:"
    set data($w,color1) [ttk::menubutton $w.rf.sb1 -text [lindex $data($w,colors) 1] -menu [set data($w,color1_mnu) [menu $w.rf.mnu1 -tearoff 0]]]
    ttk::label $w.rf.l2 -text "Color-2:"
    set data($w,color2) [ttk::menubutton $w.rf.sb2 -text [lindex $data($w,colors) 2] -menu [set data($w,color2_mnu) [menu $w.rf.mnu2 -tearoff 0]]]
    ttk::label $w.rf.l3 -text "Width:"
    set data($w,width)  [$data(sb) $w.rf.width {*}$data(sb_opts)  -width 2 -values [list 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16] -command [list bitmap::set_grid_size $w width]]
    ttk::label $w.rf.l4 -text "Height:"
    set data($w,height) [$data(sb) $w.rf.height {*}$data(sb_opts) -width 2 -values [list 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16] -command [list bitmap::set_grid_size $w height]]

    $data($w,width)  set $data($w,-width)
    $data($w,height) set $data($w,-height)

    grid rowconfigure    $w.rf 5 -weight 1
    grid columnconfigure $w.rf 1 -weight 1
    grid $data($w,plabel) -row 0 -column 0 -padx 2 -pady 2 -columnspan 2
    grid $w.rf.l1         -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $data($w,color1) -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.rf.l2         -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $data($w,color2) -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid $w.rf.l3         -row 3 -column 0 -sticky news -padx 2 -pady 2
    grid $data($w,width)  -row 3 -column 1 -sticky news -padx 2 -pady 2
    grid $w.rf.l4         -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid $data($w,height) -row 4 -column 1 -sticky news -padx 2 -pady 2

    pack $data($w,grid) -side left -padx 2 -pady 2 -fill both -expand yes
    pack $w.rf          -side left -padx 2 -pady 2 -fill y

    # Draw the bitmap
    draw_grid $w $data($w,-width) $data($w,-height)

    # Update the menus
    update_menus $w

    # Create the preview image
    array set info [gen_info $w]
    set data($w,preview) [image create bitmap -data $info(dat) -maskdata $info(msk) -foreground $info(fg) -background $info(bg)]
    $data($w,plabel) configure -image $data($w,preview)

    return $w

  }

  ######################################################################
  # Draws the bitmap grid.
  proc draw_grid {w width height} {

    variable data

    # Clear the grid
    $data($w,grid) delete all

    # Set the canvas size
    set width  [expr ($data($w,-width)  * $data($w,-size)) + 1]
    set height [expr ($data($w,-height) * $data($w,-size)) + 1]
    $data($w,grid) configure -width $width -height $height

    for {set row 0} {$row < $height} {incr row} {

      for {set col 0} {$col < $width} {incr col} {

        # Calculate the square positions
        set x1 [expr ($col * $data($w,-size)) + 1]
        set y1 [expr ($row * $data($w,-size)) + 1]
        set x2 [expr (($col + 1) * $data($w,-size)) + 1]
        set y2 [expr (($row + 1) * $data($w,-size)) + 1]

        # Create the square
        set data($w,$row,$col) [$data($w,grid) create rectangle $x1 $y1 $x2 $y2 -fill $data($w,-background) -outline black -width 1 -tags s0]

        # Create the square bindings
        $data($w,grid) bind $data($w,$row,$col) <ButtonPress-1> [list bitmap::change_square $w $row $col  1]
        $data($w,grid) bind $data($w,$row,$col) <ButtonPress-3> [list bitmap::change_square $w $row $col -1]

      }

    }

  }

  ######################################################################
  # Set the size of the grid.
  proc set_grid_size {w type} {

    variable data

    # Get the spinbox value
    set data($w,-$type) [$data($w,$type) get]

    # Redraw the grid
    draw_grid $w $data($w,-width) $data($w,-height)

    # Update the preview
    array set info [gen_info $w]
    $data($w,preview) configure -data $info(dat) -maskdata $info(msk)

    # Generate the event
    event generate $w <<BitmapChanged>> -data [array get info]

  }

  ######################################################################
  # Changes the fill color of the selected square to the color indicated
  # by the current color
  proc change_square {w row col dir} {

    variable data

    # Get the current color
    set curr_tag [string index [$data($w,grid) itemcget $data($w,$row,$col) -tags] 1]

    # If this is the initial press, save the replace color
    set data($w,replace)      $curr_tag
    set data($w,replace_with) [expr ($curr_tag + $dir) % 3]

    # Set the square fill color
    $data($w,grid) itemconfigure $data($w,$row,$col) -fill [lindex $data($w,colors) $data($w,replace_with)] -tags s$data($w,replace_with)

    # Update the preview
    array set info [gen_info $w]
    $data($w,preview) configure -data $info(dat) -maskdata $info(msk)

    # Generate the event
    event generate $w <<BitmapChanged>> -data [array get info]

  }

  ######################################################################
  # Specifies that the current change is done.
  proc change_square_motion {w x y} {

    variable data

    set id [$data($w,grid) find closest $x $y]

    # Get the current color
    set tag [string index [$data($w,grid) itemcget $id -tags] 1]

    if {$data($w,replace) eq $tag} {

      # Configure the square color
      $data($w,grid) itemconfigure $id -fill [lindex $data($w,colors) $data($w,replace_with)] -tags s$data($w,replace_with)

      # Update the preview
      array set info [gen_info $w]
      $data($w,preview) configure -data $info(dat) -maskdata $info(msk)

      # Generate the event
      event generate $w <<BitmapChanged>> -data [array get info]

    }

  }

  ######################################################################
  # Returns the bitmap information in the form of an array.
  proc gen_info {w} {

    variable data

    set dat "#define img_width $data($w,-width)\n#define img_height $data($w,-height)\nstatic char img_bits\[\] = {\n"
    set msk "#define img_width $data($w,-width)\n#define img_height $data($w,-height)\nstatic char img_bits\[\] = {\n"

    lassign $data($w,colors) dummy color1 color2

    for {set row 0} {$row < $data($w,-height)} {incr row} {
      set dat_val 0
      set msk_val 0
      for {set col 0} {$col < $data($w,-width)} {incr col} {
        set color [$data($w,grid) itemcget $data($w,$row,$col) -fill]
        if {$color eq $color1} {
          set dat_val [expr $dat_val | (0x1 << $col)]
          set msk_val [expr $msk_val | (0x1 << $col)]
        } elseif {$color eq $color2} {
          set msk_val [expr $msk_val | (0x1 << $col)]
        }
      }
      for {set i 0} {$i < [expr $data($w,-width) / 8]} {incr i } {
        append dat [format {0x%02x, } [expr ($dat_val >> ($i * 8)) & 0xff]]
        append msk [format {0x%02x, } [expr ($msk_val >> ($i * 8)) & 0xff]]
      }
      if {[expr $data($w,-width) % 8]} {
        set byte [expr $data($w,-width) / 8]
        append dat [format {0x%02x, } [expr ($dat_val >> ($byte * 8)) & 0xff]]
        append msk [format {0x%02x, } [expr ($msk_val >> ($byte * 8)) & 0xff]]
      }
    }

    set dat "[string range $dat 0 end-2]};"
    set msk "[string range $msk 0 end-2]};"

    return [list dat $dat msk $msk fg [lindex $data($w,colors) 1] bg [lindex $data($w,colors) 2]]

  }

  ######################################################################
  # Update the widget from the information.
  proc set_from_info {w args} {

    array set info $args

  }

  ######################################################################
  # Updates the color menus
  proc update_menus {w} {

    variable data

    for {set i 1} {$i <= 2} {incr i} {
      set mnu $data($w,color${i}_mnu)
      $mnu delete 0 end
      $mnu add command -label "Custom color..." -command [list bitmap::set_custom_color $w $i]
      if {[llength $data($w,-swatches)] > 0} {
        $mnu add separator
        foreach swatch $data($w,-swatches) {
          $mnu add command -label $swatch -command [list bitmap::set_color $w $i $label]
        }
      }
    }

  }

  ######################################################################
  # Set a custom color
  proc set_custom_color {w index} {

    variable data

    if {[set color [tk_chooseColor -initialcolor [lindex $data($w,colors) $index]]] ne ""} {
      set_color $w $index $color
    }

  }

  ######################################################################
  # Sets the specified color index with the given color and updates the
  # widget.
  proc set_color {w index color} {

    variable data

    # Set the color
    lset data($w,colors) $index $color

    # Set the preview color
    if {$index == 1} {
      $data($w,preview) configure -foreground $color
    } else {
      $data($w,preview) configure -background $color
    }

    # Set the menubutton label
    $data($w,color$index) configure -text $color

    # Update the colors
    foreach id [$data($w,grid) find withtag s$index] {
      $data($w,grid) itemconfigure $id -fill $color
    }

  }

}

pack [bitmap::create .bm]
