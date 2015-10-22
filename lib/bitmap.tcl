namespace eval bitmap {

  array set data {}

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

    set data(-background) $opts(-background)
    set data(-size)       $opts(-size)
    set data(colors)      [list $opts(-background) $opts(-color1) $opts(-color2)]
    set data(-width)      $opts(-width)
    set data(-height)     $opts(-height)
    set data(-swatches)   $opts(-swatches)

    ttk::frame $w

    # Create the bitmap canvas
    set width      [expr ($data(-width)  * $data(-size)) + 1]
    set height     [expr ($data(-height) * $data(-size)) + 1]
    set data(grid) [canvas $w.c -background $opts(-background) -width $width -height $height]

    bind $data(grid) <B1-Motion> [list bitmap::change_square_motion %x %y]
    bind $data(grid) <B3-Motion> [list bitmap::change_square_motion %x %y]

    # Create the right frame
    ttk::frame $w.rf
    set data(plabel) [label $w.rf.p]
    set data(color1) [ttk::menubutton $w.rf.sb1 -text [lindex $data(colors) 1] -menu [set data(color1_mnu) [menu $w.rf.mnu1 -tearoff 0]]]
    set data(color2) [ttk::menubutton $w.rf.sb2 -text [lindex $data(colors) 2] -menu [set data(color2_mnu) [menu $w.rf.mnu2 -tearoff 0]]]

    pack $data(plabel) -side top -padx 2 -pady 2
    pack $data(color1) -side top -padx 2 -pady 2 -fill x
    pack $data(color2) -side top -padx 2 -pady 2 -fill x

    pack $data(grid) -side left -padx 2 -pady 2
    pack $w.rf       -side left -padx 2 -pady 2 -fill y

    # Draw the bitmap
    draw_grid $data(-width) $data(-height)

    # Update the menus
    update_menus

    # Create the preview image
    array set info [gen_info]
    set data(preview) [image create bitmap -data $info(dat) -maskdata $info(msk) -foreground $info(fg) -background $info(bg)]
    $data(plabel) configure -image $data(preview)

    return $w

  }

  ######################################################################
  # Draws the bitmap grid.
  proc draw_grid {width height} {

    variable data

    for {set row 0} {$row < $height} {incr row} {

      for {set col 0} {$col < $width} {incr col} {

        # Calculate the square positions
        set x1 [expr ($col * $data(-size)) + 2]
        set y1 [expr ($row * $data(-size)) + 2]
        set x2 [expr (($col + 1) * $data(-size)) + 2]
        set y2 [expr (($row + 1) * $data(-size)) + 2]

        # Create the square
        set data($row,$col) [$data(grid) create rectangle $x1 $y1 $x2 $y2 -fill $data(-background) -outline black -width 1 -tags s0]

        # Create the square bindings
        $data(grid) bind $data($row,$col) <ButtonPress-1> [list bitmap::change_square $row $col  1]
        $data(grid) bind $data($row,$col) <ButtonPress-3> [list bitmap::change_square $row $col -1]

      }

    }

  }

  ######################################################################
  # Changes the fill color of the selected square to the color indicated
  # by the current color
  proc change_square {row col dir} {

    variable data

    # Get the current color
    set curr_tag [string index [$data(grid) itemcget $data($row,$col) -tags] 1]

    # If this is the initial press, save the replace color
    set data(replace)      $curr_tag
    set data(replace_with) [expr ($curr_tag + $dir) % 3]

    # Set the square fill color
    $data(grid) itemconfigure $data($row,$col) -fill [lindex $data(colors) $data(replace_with)] -tags s$data(replace_with)

    # Update the preview
    array set info [gen_info]
    $data(preview) configure -data $info(dat) -maskdata $info(msk)

  }

  ######################################################################
  # Specifies that the current change is done.
  proc change_square_motion {x y} {

    variable data

    set id [$data(grid) find closest $x $y]

    # Get the current color
    set tag [string index [$data(grid) itemcget $id -tags] 1]

    if {$data(replace) eq $tag} {

      # Configure the square color
      $data(grid) itemconfigure $id -fill [lindex $data(colors) $data(replace_with)] -tags s$data(replace_with)

      # Update the preview
      array set info [gen_info]
      $data(preview) configure -data $info(dat) -maskdata $info(msk)

    }

  }

  ######################################################################
  # Returns the bitmap information in the form of an array.
  proc gen_info {} {

    variable data

    set dat "#define img_width $data(-width)\n#define img_height $data(-height)\nstatic char img_bits\[\] = {\n"
    set msk "#define img_width $data(-width)\n#define img_height $data(-height)\nstatic char img_bits\[\] = {\n"

    lassign $data(colors) dummy color1 color2

    for {set row 0} {$row < $data(-height)} {incr row} {
      set dat_val 0
      set msk_val 0
      for {set col 0} {$col < $data(-width)} {incr col} {
        set color [$data(grid) itemcget $data($row,$col) -fill]
        if {$color eq $color1} {
          set dat_val [expr $dat_val | (0x1 << $col)]
          set msk_val [expr $msk_val | (0x1 << $col)]
        } elseif {$color eq $color2} {
          set msk_val [expr $msk_val | (0x1 << $col)]
        }
      }
      for {set i 0} {$i < [expr $data(-width) / 8]} {incr i } {
        append dat [format {0x%02x, } [expr ($dat_val >> ($i * 8)) & 0xff]]
        append msk [format {0x%02x, } [expr ($msk_val >> ($i * 8)) & 0xff]]
      }
      if {[expr $data(-width) % 8]} {
        set byte [expr ($data(-width) / 8) + 1]
        append dat [format {0x%02x, } [expr ($dat_val >> ($byte * 8)) & 0xff]]
        append msk [format {0x%02x, } [expr ($msk_val >> ($byte * 8)) & 0xff]]
      }
    }

    set dat "[string range $dat 0 end-2]};"
    set msk "[string range $msk 0 end-2]};"

    return [list dat $dat msk $msk fg [lindex $data(colors) 1] bg [lindex $data(colors) 2]]

  }

  ######################################################################
  # Update the widget from the information.
  proc set_from_info {args} {

    array set info $args

  }

  ######################################################################
  # Updates the color menus
  proc update_menus {} {

    variable data

    for {set i 1} {$i <= 2} {incr i} {
      set mnu $data(color${i}_mnu)
      $mnu delete 0 end
      $mnu add command -label "Custom color..." -command [list bitmap::set_custom_color $i]
      if {[llength $data(-swatches)] > 0} {
        $mnu add separator
        foreach swatch $data(-swatches) {
          $mnu add command -label $swatch -command [list bitmap::set_color $i $label]
        }
      }
    }

  }

  ######################################################################
  # Set a custom color
  proc set_custom_color {index} {

    variable data

    if {[set color [tk_chooseColor -initialcolor [lindex $data(colors) $index]]] ne ""} {
      set_color $index $color
    }

  }

  ######################################################################
  # Sets the specified color index with the given color and updates the
  # widget.
  proc set_color {index color} {

    variable data

    # Set the color
    lset data(colors) $index $color

    # Set the preview color
    if {$index == 1} {
      $data(preview) configure -foreground $color
    } else {
      $data(preview) configure -background $color
    }

    # Set the menubutton label
    $data(color$index) configure -text $color

    # Update the colors
    foreach id [$data(grid) find withtag s$index] {
      $data(grid) itemconfigure $id -fill $color
    }

  }

}

pack [bitmap::create .bm]
