#===============================================================
# Common tokenframe module.
#
# This module is used by both the tokenentry and tokensearch widgets.
# It is responsible for creating the various token frame images used
# to construct the graphical portions of the token.
#
# Copyright (c) 2011-2012  Trevor Williams (phase1geo@gmail.com)
#===============================================================

namespace eval tokenframe {

  ##########################################################################
  # Creates the left side of the token frame as a bitmap string.
  proc create_left {shape height} {

    set bitmap "#define left_width 8\n#define left_height $height\nstatic char left_bits\[\] = \{\n"

    switch $shape {
      pill   { append bitmap "0xc0, 0xf0, 0x38, 0x0c, 0x06, 0x06, 0x03, 0x03, " }
      tag    { append bitmap "0xe0, 0xf0, 0x18, 0x0c, 0x06, 0x03, 0x03, 0x03, " }
      square { append bitmap "0xff, 0xff, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, " }
      eased  { append bitmap "0xfe, 0xff, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, " }
      ticket { append bitmap "0xf0, 0xf0, 0x18, 0x0c, 0x07, 0x03, 0x03, 0x03, " }
    }

    for {set i 0} {$i < [expr $height - 16]} {incr i} {
      append bitmap "0x03, "
    }

    switch $shape {
      pill   { append bitmap "0x03, 0x03, 0x06, 0x06, 0x0c, 0x38, 0xf0, 0xc0\};" }
      tag    { append bitmap "0x03, 0x03, 0x03, 0x06, 0x0c, 0x18, 0xf0, 0xe0\};" }
      square { append bitmap "0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0xff, 0xff\};" }
      eased  { append bitmap "0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0xff, 0xfe\};" }
      ticket { append bitmap "0x03, 0x03, 0x03, 0x07, 0x0c, 0x18, 0xf0, 0xf0\};" }
    }

    return $bitmap

  }

  ##########################################################################
  # Creates the left side mask of the token frame as a bitmap string.
  proc create_left_mask {shape height} {

    set bitmap "#define left_mask_width 8\n#define left_mask_height $height\nstatic char left_mask_bits\[\] = \{\n"

    switch $shape {
      pill   { append bitmap "0xff, 0xff, 0x3f, 0x0f, 0x07, 0x07, 0x03, 0x03, " }
      tag    { append bitmap "0xff, 0xff, 0x1f, 0x0f, 0x07, 0x03, 0x03, 0x03, " }
      square { append bitmap "0xff, 0xff, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, " }
      eased  { append bitmap "0xff, 0xff, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, " }
      ticket { append bitmap "0xff, 0xff, 0x1f, 0x0f, 0x07, 0x03, 0x03, 0x03, " }
    }

    for {set i 0} {$i < [expr $height - 16]} {incr i} {
      append bitmap "0x03, "
    }

    switch $shape {
      pill   { append bitmap "0x03, 0x03, 0x07, 0x07, 0x0f, 0x3f, 0xff, 0xff\};" }
      tag    { append bitmap "0x03, 0x03, 0x03, 0x07, 0x0f, 0x1f, 0xff, 0xff\};" }
      square { append bitmap "0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0xff, 0xff\};" }
      eased  { append bitmap "0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0xff, 0xff\};" }
      ticket { append bitmap "0x03, 0x03, 0x03, 0x07, 0x0f, 0x1f, 0xff, 0xff\};" }
    }

    return $bitmap

  }

  ##########################################################################
  # Creates the middle of the token frame as a bitmap string.
  proc create_middle {width height} {

    set bitmap "#define middle_width $width\n#define middle_height $height\nstatic char middle_bits\[\] = {\n"
    set values [list "0x00" "0x01" "0x03" "0x07" "0x0f" "0x1f" "0x3f" "0x7f" "0xff"]

    for {set row 0} {$row < $height} {incr row} {
      if {($row < 2) || ($row > [expr $height - 3])} {
        set i 0
        while {$i < [expr $width - 8]} {
          append bitmap "0xff, "
          incr i 8
        }
        append bitmap "[lindex $values [expr $width - $i]], "
      } else {
        for {set i 0} {$i < $width} {incr i 8} {
          append bitmap "0x00, "
        }
      }
    }

    set bitmap "[string range $bitmap 0 end-2]};"

    return $bitmap

  }

  ##########################################################################
  # Creates an image which contains an arrow along with a upper and lower
  # border.
  proc create_arrow {height} {

    set bitmap "#define arrow_width 7\n#define arrow_height $height\nstatic char arrow_bits\[\] = {\n0x7f, 0x7f, "

    for {set i 0} {$i < [expr $height - 10]} {incr i} {
      if {$i == [expr ($height - 10) / 2]} {
        append bitmap "0x3e, 0x22, 0x14, 0x14, 0x08, 0x08, "
      }
      append bitmap "0x00, "
    }

    append bitmap "0x7f, 0x7f};"

    return $bitmap

  }

  ##########################################################################
  # Creates a mask image for the arrow image.
  proc create_arrow_mask {height} {

    set bitmap "#define arrow_width 7\n#define arrow_height $height\nstatic char arrow_bits\[\] = {\n0x7f, 0x7f, "

    for {set i 0} {$i < [expr $height - 10]} {incr i} {
      if {$i == [expr ($height - 10) / 2]} {
        append bitmap "0x3e, 0x3e, 0x1c, 0x1c, 0x08, 0x08, "
      }
      append bitmap "0x00, "
    }

    append bitmap "0x7f, 0x7f};"

    return $bitmap

  }

  ##########################################################################
  # Creates the right side of the token frame as a bitmap string.
  proc create_right {shape height} {

    set bitmap "#define right_width 8\n#define right_height $height\nstatic char right_bits\[\] = \{\n"

    switch $shape {
      pill   { append bitmap "0x03, 0x0f, 0x1c, 0x30, 0x60, 0x60, 0xc0, 0xc0, " }
      tag    { append bitmap "0x07, 0x0f, 0x18, 0x30, 0x60, 0xc0, 0xc0, 0xc0, " }
      square { append bitmap "0xff, 0xff, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, " }
      eased  { append bitmap "0x7f, 0xff, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, " }
      ticket { append bitmap "0x0f, 0x0f, 0x18, 0x30, 0xe0, 0xc0, 0xc0, 0xc0, " }
    }

    for {set i 0} {$i < [expr $height - 16]} {incr i} {
      append bitmap "0xc0, "
    }

    switch $shape {
      pill   { append bitmap "0xc0, 0xc0, 0x60, 0x60, 0x30, 0x1c, 0x0f, 0x03\};" }
      tag    { append bitmap "0xc0, 0xc0, 0xc0, 0x60, 0x30, 0x18, 0x0f, 0x07\};" }
      square { append bitmap "0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xff, 0xff\};" }
      eased  { append bitmap "0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xff, 0x7f\};" }
      ticket { append bitmap "0xc0, 0xc0, 0xc0, 0xe0, 0x30, 0x18, 0x0f, 0x0f\};" }
    }

    return $bitmap

  }

  ##########################################################################
  # Creates the right side mask of the token frame as a bitmap string.
  proc create_right_mask {shape height} {

    set bitmap "#define right_mask_width 8\n#define right_mask_height $height\nstatic char right_mask_bits\[\] = \{\n"

    switch $shape {
      pill   { append bitmap "0xff, 0xff, 0xfc, 0xf0, 0xe0, 0xe0, 0xc0, 0xc0, " }
      tag    { append bitmap "0xff, 0xff, 0xf8, 0xf0, 0xe0, 0xc0, 0xc0, 0xc0, " }
      square { append bitmap "0xff, 0xff, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, " }
      eased  { append bitmap "0xff, 0xff, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, " }
      ticket { append bitmap "0xff, 0xff, 0xf8, 0xf0, 0xe0, 0xc0, 0xc0, 0xc0, " }
    }

    for {set i 0} {$i < [expr $height - 16]} {incr i} {
      append bitmap "0xc0, "
    }

    switch $shape {
      pill   { append bitmap "0xc0, 0xc0, 0xe0, 0xe0, 0xf0, 0xfc, 0xff, 0xff\};" }
      tag    { append bitmap "0xc0, 0xc0, 0xc0, 0xe0, 0xf0, 0xf8, 0xff, 0xff\};" }
      square { append bitmap "0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xff, 0xff\};" }
      eased  { append bitmap "0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xff, 0xff\};" }
      ticket { append bitmap "0xc0, 0xc0, 0xc0, 0xe0, 0xf0, 0xf8, 0xff, 0xff\};" }
    }

    return $bitmap

  }

}
