# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
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
# Name:    thumbnail.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    6/30/2017
# Brief:   Displays a thumbnail of a given image.
######################################################################

# Import the image_resize procedure from the image resizer
source [file join $tke_dir lib ptwidgets1.2 common resize.tcl]

namespace eval thumbnail {

  ######################################################################
  # Displays the thumbnail image.  The value of x and y need to be the
  # root X/Y values.
  proc show {image_file x y} {

    # Figure out if we can display the file based on extension
    if {[lsearch [list .gif .png] [file extension $image_file]] == -1} {
      return
    }

    # Make it a windowless panel
    if {[tk windowingsystem] eq "aqua"} {
      toplevel .thumbwin; ::tk::unsupported::MacWindowStyle style .thumbwin help none
      set focus [focus]
    } else {
      toplevel .thumbwin
      wm overrideredirect .thumbwin 1
    }

    wm attributes   .thumbwin -topmost 1
    wm positionfrom .thumbwin program
    wm withdraw     .thumbwin

    # Create the thumbnail
    image create photo original -file $image_file
    image create photo thumbnail

    # Perform the resize of the image
    ::image_scale original 64 64 thumbnail

    # Delete the original image
    image delete original

    # Add the image to the window
    pack [label .thumbwin.l -image thumbnail]

    wm geometry  .thumbwin +$x+[expr $y - 32]
    update idletasks
    wm deiconify .thumbwin
    raise        .thumbwin

    if {([tk windowingsystem] eq "aqua") && ($focus ne "")} {
      after idle [list focus -force $focus]
    }

  }

  ######################################################################
  # Hide the currently displayed thumbnail image.
  proc hide {} {

    if {[winfo exists .thumbwin]} {
      destroy .thumbwin
      image delete thumbnail
    }

  }

}
