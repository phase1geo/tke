# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2017  Trevor Williams (phase1geo@gmail.com)
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

if {0} {
  set tke_dir [file join ~ projects tke-code]
  source [file join $::tke_dir lib utils.tcl]
}

namespace eval bitmap {

  array set data {}

  set data(bg) [utils::get_default_background]
  set data(fg) [utils::get_default_foreground]

  if {[catch { ttk::spinbox .__tmp }]} {
    set data(sb)          "spinbox"
    set data(sb_opts)     "-relief flat -buttondownrelief flat -buttonuprelief flat -background $data(bg) -foreground $data(fg)"
    set data(sb_normal)   "configure -state normal"
    set data(sb_disabled) "configure -state disabled"
    set data(sb_readonly) "configure -state readonly"
  } else {
    set data(sb)          "ttk::spinbox"
    set data(sb_opts)     "-justify center"
    set data(sb_normal)   "state !disabled"
    set data(sb_disabled) "state disabled"
    set data(sb_readonly) "state readonly"
    destroy .__tmp
  }

  ######################################################################
  # Creates a bitmap widget and returns the widget name.
  proc create {w type args} {

    variable data

    array set opts {
      -color1     blue
      -color2     green
      -size       10
      -width      32
      -height     32
      -swatches   {}
    }

    array set opts $args

    # Initialize variables
    set data($w,type)      $type
    set data($w,-size)     $opts(-size)
    set data($w,-width)    $opts(-width)
    set data($w,-height)   $opts(-height)
    set data($w,-swatches) $opts(-swatches)

    if {$type eq "mono"} {
      set data($w,colors) [list $data(bg) $opts(-color1)]
    } else {
      set data($w,colors) [list $data(bg) $opts(-color1) $opts(-color2)]
    }

    ttk::frame $w

    # Create the bitmap canvas
    set width  [expr ($data($w,-size) * 32) + 1]
    set height [expr ($data($w,-size) * 32) + 1]
    set data($w,grid) [canvas $w.c -background $data(bg) -width $width -height $height]

    bind $data($w,grid) <B1-Motion> [list bitmap::change_square_motion $w %x %y]
    bind $data($w,grid) <B$::right_click-Motion> [list bitmap::change_square_motion $w %x %y]

    # Create the right frame
    ttk::frame $w.rf
    set data($w,plabel) [ttk::label $w.rf.p -relief solid -padding 10 -anchor center]
    ttk::labelframe $w.rf.mf -text [msgcat::mc "Transform Tools"]
    grid columnconfigure $w.rf.mf 0 -weight 1
    grid columnconfigure $w.rf.mf 4 -weight 1
    grid [ttk::button $w.rf.mf.up     -style BButton -text "\u25b2" -command [list bitmap::move $w up]]         -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid [ttk::button $w.rf.mf.left   -style BButton -text "\u25c0" -command [list bitmap::move $w left]]       -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid [ttk::button $w.rf.mf.center -style BButton -text "\u25fc" -command [list bitmap::move $w center]]     -row 1 -column 2 -sticky news -padx 2 -pady 2
    grid [ttk::button $w.rf.mf.right  -style BButton -text "\u25b6" -command [list bitmap::move $w right]]      -row 1 -column 3 -sticky news -padx 2 -pady 2
    grid [ttk::button $w.rf.mf.down   -style BButton -text "\u25bc" -command [list bitmap::move $w down]]       -row 2 -column 2 -sticky news -padx 2 -pady 2
    grid [ttk::button $w.rf.mf.flipv  -style BButton -text "\u2b0c" -command [list bitmap::flip $w vertical]]   -row 3 -column 1 -sticky news -padx 2 -pady 2
    grid [ttk::button $w.rf.mf.rot    -style BButton -text "\u21ba" -command [list bitmap::rotate $w]]          -row 3 -column 2 -sticky news -padx 2 -pady 2
    grid [ttk::button $w.rf.mf.fliph  -style BButton -text "\u2b0d" -command [list bitmap::flip $w horizontal]] -row 3 -column 3 -sticky news -padx 2 -pady 2
    set data($w,c1_lbl) [ttk::label $w.rf.l1 -text "Color-1:" -background [lindex $data($w,colors) 1]]
    set data($w,color1) [ttk::menubutton $w.rf.sb1 -text [lindex $data($w,colors) 1] -menu [set data($w,color1_mnu) [menu $w.rf.mnu1 -tearoff 0]]]
    if {$type eq "mono"} {
      $data($w,c1_lbl) configure -text "Color:"
    } else {
      set data($w,c2_lbl) [ttk::label $w.rf.l2 -text "Color-2:" -background [lindex $data($w,colors) 2]]
      set data($w,color2) [ttk::menubutton $w.rf.sb2 -text [lindex $data($w,colors) 2] -menu [set data($w,color2_mnu) [menu $w.rf.mnu2 -tearoff 0]]]
    }
    ttk::label $w.rf.l3 -text "Width:"
    set data($w,width)  [$data(sb) $w.rf.width {*}$data(sb_opts)  -width 2 -values [list 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16] -command [list bitmap::set_grid_size $w width]]
    ttk::label $w.rf.l4 -text "Height:"
    set data($w,height) [$data(sb) $w.rf.height {*}$data(sb_opts) -width 2 -values [list 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16] -command [list bitmap::set_grid_size $w height]]

    $data($w,width)  set $data($w,-width)
    $data($w,height) set $data($w,-height)
    $data($w,width)  {*}$data(sb_readonly)
    $data($w,height) {*}$data(sb_readonly)

    tooltip::tooltip $w.rf.mf.up     [msgcat::mc "Move image up"]
    tooltip::tooltip $w.rf.mf.left   [msgcat::mc "Move image left"]
    tooltip::tooltip $w.rf.mf.center [msgcat::mc "Center image"]
    tooltip::tooltip $w.rf.mf.right  [msgcat::mc "Move image right"]
    tooltip::tooltip $w.rf.mf.down   [msgcat::mc "Move image down"]
    tooltip::tooltip $w.rf.mf.flipv  [msgcat::mc "Flip image vertically"]
    tooltip::tooltip $w.rf.mf.rot    [msgcat::mc "Rotate image 90 degrees"]
    tooltip::tooltip $w.rf.mf.fliph  [msgcat::mc "Flip image horizontally"]

    grid rowconfigure    $w.rf 1 -weight 1
    grid rowconfigure    $w.rf 3 -weight 1
    grid columnconfigure $w.rf 1 -weight 1
    grid $data($w,plabel) -row 0 -column 0 -padx 2 -pady 2 -columnspan 2
    grid $w.rf.mf         -row 2 -column 0 -padx 2 -pady 2 -columnspan 2
    grid $data($w,c1_lbl) -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid $data($w,color1) -row 4 -column 1 -sticky news -padx 2 -pady 2
    if {$type ne "mono"} {
      grid $data($w,c2_lbl) -row 5 -column 0 -sticky news -padx 2 -pady 2
      grid $data($w,color2) -row 5 -column 1 -sticky news -padx 2 -pady 2
    }
    grid $w.rf.l3         -row 6 -column 0 -sticky news -padx 2 -pady 2
    grid $data($w,width)  -row 6 -column 1 -sticky news -padx 2 -pady 2
    grid $w.rf.l4         -row 7 -column 0 -sticky news -padx 2 -pady 2
    grid $data($w,height) -row 7 -column 1 -sticky news -padx 2 -pady 2

    pack $w.c  -side left -padx 2 -pady 2
    pack $w.rf -side left -padx 2 -pady 2 -fill y

    # Draw the bitmap
    draw_grid $w $data($w,-width) $data($w,-height)

    # Update the menus
    update_menus $w

    # Create the preview image
    array set info [get_info $w]
    if {$type eq "mono"} {
      set data($w,preview) [image create bitmap -data $info(dat) -maskdata $info(msk) -foreground $info(fg)]
    } else {
      set data($w,preview) [image create bitmap -data $info(dat) -maskdata $info(msk) -foreground $info(fg) -background $info(bg)]
    }
    $data($w,plabel) configure -image $data($w,preview)

    rename ::$w $w
    interp alias {} ::$w {} bitmap::widget_cmd $w

    return $w

  }

  ######################################################################
  # Runs the specified widget command.
  proc widget_cmd {w args} {

    set args [lassign $args cmd]

    switch -exact $cmd {
      cget      { return [cget $w {*}$args] }
      configure { return [configure $w {*}$args] }
      default   { return -code error "Unknown bitmap command ($cmd)" }
    }

  }

  ######################################################################
  # Returns the specified bitmap option value.
  proc cget {w args} {

    variable data

    if {[llength $args] != 1} {
      return -code error "Illegal number of arguments to bitmap::cget"
    }

    if {![info exists data($w,[lindex $args 0])]} {
      return -code error "Unknown bitmap option [lindex $args 0]"
    }

    return $data($w,[lindex $args 0])

  }

  ######################################################################
  # Sets options in the bitmap widget.
  proc configure {w args} {

    variable data

    if {[llength $args] % 2} {
      return -code error "Illegal number of arguments to bitmap::configure"
    }

    array set opts {
      -background {}
      -swatches   {}
    }
    array set opts $args

    # Store the options
    set data($w,-swatches) $opts(-swatches)

    # If a background color was specified, change the color in the widget
    if {$opts(-background) ne ""} {
      lset data($w,colors) 0 $opts(-background)
      $data($w,grid)   configure -background $opts(-background)
      $data($w,plabel) configure -background $opts(-background)
    }

    # Update the UI
    update_menus $w

  }

  ######################################################################
  # Draws the bitmap grid.
  proc draw_grid {w width height {fg ""}} {

    variable data

    # Calculate the background and foreground colors, if necessary
    set bg [lindex $data($w,colors) 0]
    set fg [expr {($fg eq "") ? $data(fg) : $fg}]

    # Clear the grid
    $data($w,grid) delete all

    # Calculate the x and y adjustment
    set x_adjust [expr ((32 - $width)  * ($data($w,-size) / 2)) + 1]
    set y_adjust [expr ((32 - $height) * ($data($w,-size) / 2)) + 1]

    for {set row 0} {$row < $height} {incr row} {

      for {set col 0} {$col < $width} {incr col} {

        # Calculate the square positions
        set x1 [expr ($col * $data($w,-size)) + $x_adjust]
        set y1 [expr ($row * $data($w,-size)) + $y_adjust]
        set x2 [expr (($col + 1) * $data($w,-size)) + $x_adjust]
        set y2 [expr (($row + 1) * $data($w,-size)) + $y_adjust]

        # Create the square
        set data($w,$row,$col) [$data($w,grid) create rectangle $x1 $y1 $x2 $y2 -fill $bg -outline $fg -width 1 -tags s0]

        # Create the square bindings
        $data($w,grid) bind $data($w,$row,$col) <ButtonPress-1> [list bitmap::change_square $w $row $col  1]
        $data($w,grid) bind $data($w,$row,$col) <ButtonPress-$::right_click> [list bitmap::change_square $w $row $col -1]

      }

    }

  }

  ######################################################################
  # Set the size of the grid.
  proc set_grid_size {w type} {

    variable data

    # Get the spinbox value
    set data($w,-$type) [$data($w,$type) get]

    # Update the grid
    set_from_info $w [set info [get_info $w]] 0

    # Generate the event
    event generate $w <<BitmapChanged>> -data $info

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
    set data($w,replace_with) [expr ($curr_tag + $dir) % [llength $data($w,colors)]]

    # Set the square fill color
    $data($w,grid) itemconfigure $data($w,$row,$col) -fill [lindex $data($w,colors) $data($w,replace_with)] -tags s$data($w,replace_with)

    # Update the preview
    array set info [get_info $w]
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
      array set info [get_info $w]
      $data($w,preview) configure -data $info(dat) -maskdata $info(msk)

      # Generate the event
      event generate $w <<BitmapChanged>> -data [array get info]

    }

  }

  ######################################################################
  # Returns the bitmap information in the form of an array.
  proc get_info {w} {

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

    if {$data($w,type) eq "mono"} {
      return [list dat $dat msk $msk fg $color1]
    } else {
      return [list dat $dat msk $msk fg $color1 bg $color2]
    }

  }

  ######################################################################
  # Update the widget from the information.
  proc set_from_info {w info_list {resize 1}} {

    variable data

    array set info $info_list

    # Set the background color if it does not exist
    if {($data($w,type) ne "mono") && ![info exists info(bg)]} {
      set info(bg) $data(bg)
    }

    # Set the grid foreground
    set grid_fg [expr {($info(fg) eq "black") ? "grey" : "black"}]

    # Parse the data and mask BMP strings
    if {[catch {
      array set dat_info [parse_bmp $info(dat)]
      if {$data($w,type) eq "mono"} {
        array set msk_info [array get dat_info]
      } else {
        array set msk_info [parse_bmp $info(msk)]
      }
    } rc]} {
      return -code error "Error parsing BMP file ($rc)"
    }

    # Set the variables
    if {$resize} {
      set data($w,-width)  $dat_info(width)
      set data($w,-height) $dat_info(height)
    }
    if {$data($w,type) eq "mono"} {
      lset data($w,colors) 1 $info(fg)
    } else {
      lset data($w,colors) 1 $info(fg)
      lset data($w,colors) 2 $info(bg)
    }

    # Update the preview
    if {$data($w,type) eq "mono"} {
      $data($w,preview) configure -foreground $info(fg) -data $info(dat) -maskdata $info(msk)
    } else {
      $data($w,preview) configure -foreground $info(fg) -background $info(bg) -data $info(dat) -maskdata $info(msk)
    }

    # Redraw the grid
    draw_grid $w $data($w,-width) $data($w,-height) $grid_fg

    # Update the widgets
    $data($w,c1_lbl) configure -background $info(fg) -foreground [utils::get_complementary_mono_color $info(fg)]
    $data($w,color1) configure -text $info(fg)
    if {$data($w,type) ne "mono"} {
      $data($w,c2_lbl) configure -background $info(bg) -foreground [utils::get_complementary_mono_color $info(bg)]
      $data($w,color2) configure -text $info(bg)
    }
    $data($w,width)  set $dat_info(width)
    $data($w,height) set $dat_info(height)

    for {set row 0} {$row < $data($w,-height)} {incr row} {
      set dat_val [lindex $dat_info(rows) $row]
      set msk_val [lindex $msk_info(rows) $row]
      for {set col 0} {$col < $data($w,-width)} {incr col} {
        if {[expr $dat_val & (0x1 << $col)]} {
          $data($w,grid) itemconfigure $data($w,$row,$col) -fill $info(fg) -tags s1
        } elseif {[expr $msk_val & (0x1 << $col)]} {
          $data($w,grid) itemconfigure $data($w,$row,$col) -fill $info(bg) -tags s2
        } else {
          $data($w,grid) itemconfigure $data($w,$row,$col) -tags s0
        }
      }
    }

  }

  ######################################################################
  # Parses the given BMP file contents and returns a more usable format
  # of the data.
  proc parse_bmp {bmp_str} {

    array set bmp_data [list]

    # Parse out the width and height
    if {[regexp {#define\s+\w+\s+(\d+).*#define\s+\w+\s+(\d+).*\{(.*)\}} [string map {\n { }} $bmp_str] -> bmp_data(width) bmp_data(height) values]} {
      if {$bmp_data(width) > 32} {
        return -code error "BMP data width is greater than 32"
      }
      if {$bmp_data(height) > 32} {
        return -code error "BMP data height is greater than 32"
      }
      set values [string map {{,} {}} [string trim $values]]
      switch [expr ($bmp_data(width) - 1) / 8] {
        0 {
          foreach val $values {
            lappend bmp_data(rows) $val
          }
        }
        1 {
          foreach {val1 val2} $values {
            lappend bmp_data(rows) [expr ($val2 << 8) | $val1]
          }
        }
        2 {
          foreach {val1 val2 val3} $values {
            lappend bmp_data(rows) [expr ($val3 << 16) | ($val2 << 8) | $val1]
          }
        }
        3 {
          foreach {val1 val2 val3 val4} $value {
            lappend bmp_data(rows) [expr ($val4 << 24) | ($val3 << 16) | ($val2 << 8) | $val1]
          }
        }
      }
      return [array get bmp_data]
    }

    return -code error "Illegal BMP data string specified"

  }

  ######################################################################
  # Updates the color menus
  proc update_menus {w} {

    variable data

    for {set i 1} {$i <= [expr {($data($w,type) eq "mono") ? 1 : 2}]} {incr i} {
      set mnu $data($w,color${i}_mnu)
      $mnu delete 0 end
      $mnu add command -label "Custom color..." -command [list bitmap::set_custom_color $w $i]
      if {[llength $data($w,-swatches)] > 0} {
        $mnu add separator
        $mnu add command -label "Swatch Colors" -state disabled
        foreach swatch $data($w,-swatches) {
          $mnu add command -label $swatch -command [list bitmap::set_color $w $i $swatch]
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

    # Set the label background color
    $data($w,c${index}_lbl) configure -background $color

    # Set the menubutton label
    $data($w,color$index) configure -text $color

    # Update the colors
    foreach id [$data($w,grid) find withtag s$index] {
      $data($w,grid) itemconfigure $id -fill $color
    }

    # Generate a BitmapChanged event
    event generate $w <<BitmapChanged>> -data [get_info $w]

  }

  ######################################################################
  # Prompts the user for a file to import and updates the UI based on
  # the read in file and type specified.
  proc import {w vec} {

    variable data

    # Prompt the user for a BMP filename
    if {[set fname [tk_getOpenFile -parent $w -filetypes {{{Bitmap files} {.bmp}}}]] ne ""} {

      # Open the file for reading
      if {[catch { open $fname r } rc]} {
        return -code error "Unable to open $fname for reading"
      }

      # Get the file content
      set content [read $rc]
      close $rc

      # Update the UI
      array set info [get_info $w]
      if {$vec & 0x1} {
        set info(dat) $content
      }
      if {$vec & 0x2} {
        set info(msk) $content
      }
      if {[catch { set_from_info $w [array get info] } rc]} {
        tk_messageBox -parent $w -icon error -message "Unable to parse BMP file $fname"
      }

      # Generate the event
      event generate $w <<BitmapChanged>> -data [array get info]

    }

  }

  ######################################################################
  # Exports the current bitmap information to a file.  The value of type
  # can be 'data' or 'mask'.
  proc export {w type} {

    # Prompt the user for a BMP filename to save to
    if {[set fname [tk_getSaveFile -parent $w -filetypes {{{Bitmap files} {.bmp}}}]] ne ""} {

      # Open the file for writing
      if {[catch { open $fname w } rc]} {
        return -code error "Unable to open $fname for writing"
      }

      # Get the bitmap information
      array set info [get_info $w]

      # Write the information
      if {$type eq "data"} {
        puts $rc $info(dat)
      } else {
        puts $rc $info(msk)
      }

      # Close the file
      close $rc

    }

  }

  ######################################################################
  # Counts the number of blanks for the given orientation.
  proc count_blanks {w orient rows cols} {

    variable data

    set blanks 0

    if {$orient eq "row"} {
      foreach row $rows {
        foreach col $cols {
          if {[$data($w,grid) itemcget $data($w,$row,$col) -tags] ne "s0"} {
            return $blanks
          }
        }
        incr blanks
      }
    } else {
      foreach col $cols {
        foreach row $rows {
          if {[$data($w,grid) itemcget $data($w,$row,$col) -tags] ne "s0"} {
            return $blanks
          }
        }
        incr blanks
      }
    }

    return $blanks

  }

  ######################################################################
  # Moves all of the pixels in the canvas in the given direction by one
  # pixel.
  proc move {w dir} {

    variable data

    set row_adjust 0
    set col_adjust 0

    for {set i 0} {$i < $data($w,-height)} {incr i} { lappend rows $i }
    for {set i 0} {$i < $data($w,-width)}  {incr i} { lappend cols $i }

    switch $dir {
      up     { set row_adjust  1 }
      down   { set row_adjust -1; set rows [lreverse $rows] }
      left   { set col_adjust  1 }
      right  { set col_adjust -1; set cols [lreverse $cols] }
      center {
        set top    [count_blanks $w row $rows $cols]
        set bottom [count_blanks $w row [lreverse $rows] $cols]
        set left   [count_blanks $w col $rows $cols]
        set right  [count_blanks $w col $rows [lreverse $cols]]
        if {[set row_adjust [expr $top - (($top + $bottom) / 2)]] < 0} {
          set rows [lreverse $rows]
        }
        if {[set col_adjust [expr $left - (($left + $right) / 2)]] < 0} {
          set cols [lreverse $cols]
        }
        if {($row_adjust == 0) && ($col_adjust == 0)} {
          return
        }
      }
    }

    foreach row $rows {
      set old_row [expr $row + $row_adjust]
      foreach col $cols {
        set old_col [expr $col + $col_adjust]
        if {($old_row < 0) || ($old_row >= $data($w,-height)) || ($old_col < 0) || ($old_col >= $data($w,-width))} {
          $data($w,grid) itemconfigure $data($w,$row,$col) -fill "" -tags s0
        } else {
          $data($w,grid) itemconfigure $data($w,$row,$col) \
            -fill [$data($w,grid) itemcget $data($w,$old_row,$old_col) -fill] \
            -tags [$data($w,grid) itemcget $data($w,$old_row,$old_col) -tags]
        }
      }
    }

    # Update the preview
    array set info [get_info $w]
    $data($w,preview) configure -data $info(dat) -maskdata $info(msk)

    # Generate the event
    event generate $w <<BitmapChanged>> -data [array get info]

  }

  ######################################################################
  # Flips the image horizontally or vertically.
  proc flip {w orient} {

    variable data

    for {set i 0} {$i < $data($w,-height)} {incr i} { lappend rows $i }
    for {set i 0} {$i < $data($w,-width)}  {incr i} { lappend cols $i }

    if {$orient eq "vertical"} {
      foreach row $rows {
        foreach lcol $cols rcol [lreverse $cols] {
          if {$lcol >= $rcol} {
            break
          } else {
            set fill [$data($w,grid) itemcget $data($w,$row,$lcol) -fill]
            set tags [$data($w,grid) itemcget $data($w,$row,$lcol) -tags]
            $data($w,grid) itemconfigure $data($w,$row,$lcol) \
              -fill [$data($w,grid) itemcget $data($w,$row,$rcol) -fill] \
              -tags [$data($w,grid) itemcget $data($w,$row,$rcol) -tags]
            $data($w,grid) itemconfigure $data($w,$row,$rcol) -fill $fill -tags $tags
          }
        }
      }
    } else {
      foreach col $cols {
        foreach trow $rows brow [lreverse $rows] {
          if {$trow >= $brow} {
            break
          } else {
            set fill [$data($w,grid) itemcget $data($w,$trow,$col) -fill]
            set tags [$data($w,grid) itemcget $data($w,$trow,$col) -tags]
            $data($w,grid) itemconfigure $data($w,$trow,$col) \
              -fill [$data($w,grid) itemcget $data($w,$brow,$col) -fill] \
              -tags [$data($w,grid) itemcget $data($w,$brow,$col) -tags]
            $data($w,grid) itemconfigure $data($w,$brow,$col) -fill $fill -tags $tags
          }
        }
      }
    }

    # Update the preview
    array set info [get_info $w]
    $data($w,preview) configure -data $info(dat) -maskdata $info(msk)

    # Generate the event
    event generate $w <<BitmapChanged>> -data [array get info]

  }

  ######################################################################
  # Rotates the image by 90 degrees.
  proc rotate {w} {

    variable data

    for {set i 0} {$i < $data($w,-height)} {incr i} { lappend rows $i }
    for {set i 0} {$i < $data($w,-width)}  {incr i} { lappend cols $i }

    # Copy the image to a source array and clear the destination
    foreach row $rows {
      set src_row [list]
      foreach col $cols {
        lappend src_row [list -fill [$data($w,grid) itemcget $data($w,$row,$col) -fill] -tags [$data($w,grid) itemcget $data($w,$row,$col) -tags]]
        $data($w,grid) itemconfigure $data($w,$row,$col) -fill "" -tags ""
      }
      lappend src $src_row
    }

    foreach col $cols src_row $rows {
      if {($col eq "") || ($src_row eq "")} {
        return
      }
      foreach row [lreverse $rows] src_col $cols {
        if {($row eq "") || ($src_col eq "")} {
          break
        }
        $data($w,grid) itemconfigure $data($w,$row,$col) {*}[lindex $src $src_row $src_col]
      }
    }

    # Update the preview
    array set info [get_info $w]
    $data($w,preview) configure -data $info(dat) -maskdata $info(msk)

    # Generate the event
    event generate $w <<BitmapChanged>> -data [array get info]

  }

}

if {0} {
  pack [bitmap::create .bm] -side left
  if {![catch { open images/sopen.bmp r } rc]} {
    set content [read $rc]
    close $rc
    bitmap::set_from_info .bm [list fg black bg white dat $content msk $content]
  }
}
