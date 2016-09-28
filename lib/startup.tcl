# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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
# Name:    startup.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    09/27/2016
# Brief:   Namespace containing code to handle the startup wizard.
######################################################################

namespace eval startup {

  variable current_panel ""
  variable type          "local"

  array set widgets {}
  array set images  {}
  array set rbs     {}
  array set locs {
    button_y 455
    left_x   300
  }

  ######################################################################
  # Creates the startup wizard window.
  proc create {} {

    variable widgets
    variable images
    variable current_panel
    variable type

    # Create the images
    create_images

    toplevel     .wizwin
    wm title     .wizwin [msgcat::mc "Welcome"]
    wm geometry  .wizwin 640x480
    wm resizable .wizwin 0 0
    wm transient .wizwin .
    wm protocol  .wizwin WM_DELETE_WINDOW {
      # Do nothing
    }
    wm withdraw  .wizwin

    # Add the tabs
    foreach window [list welcome share finish] {
      set widgets($window) [canvas .wizwin.$window -highlightthickness 0 -relief flat -background white -width 640 -height 480]
      $widgets($window) lower [$widgets($window) create image 0 0 -anchor nw -image $images(bg)]
      create_$window
    }

    # Pack the first window
    show_panel welcome

    # Allow the window sizes to be calculatable
    update

    # Place the window in the middle of the screen
    wm geometry .wizwin +[expr ([winfo screenwidth .wizwin] / 2) - 320]+[expr ([winfo screenheight .wizwin] / 2) - 240]

    # Display the window
    wm deiconify .wizwin

    # Wait for the window to be destroyed
    tkwait window .wizwin

    # Destroy the images
    destroy_images

    return [list $type ""]

  }

  ######################################################################
  # Create the images
  proc create_images {} {

    variable images

    set images(bg) [image create photo -file [file join $::tke_dir lib images startup.gif]]

  }

  ######################################################################
  # Deletes the images.
  proc destroy_images {} {

    variable images

    foreach {name img} [array get images] {
      image delete $img
    }

  }

  ######################################################################
  # Shows the given panel name.
  proc show_panel {type} {

    variable widgets
    variable current_panel

    if {$current_panel ne ""} {
      pack forget $widgets($current_panel)
    }

    pack $widgets($type) -fill both -expand yes

    set current_panel $type

  }

  ######################################################################
  # Create the welcome window.
  proc create_welcome {} {

    variable widgets
    variable locs

    # Create Next button
    make_button $widgets(welcome) 580 $locs(button_y) [msgcat::mc "Next"] [list startup::show_panel share]

  }

  ######################################################################
  # Create the import/share window.
  proc create_share {} {

    variable widgets
    variable locs

    # Create the radiobutton
    make_radiobutton $widgets(share) $locs(left_x) 100 [msgcat::mc "Create settings locally"]       startup::type local {}
    make_radiobutton $widgets(share) $locs(left_x) 150 [msgcat::mc "Copy settings from directory"]  startup::type copy  {}
    make_radiobutton $widgets(share) $locs(left_x) 200 [msgcat::mc "Share settings from directory"] startup::type share {}

    # Create the button bar
    make_button $widgets(share) 500 $locs(button_y) [msgcat::mc "Back"] [list startup::show_panel welcome]
    make_button $widgets(share) 580 $locs(button_y) [msgcat::mc "Next"] [list startup::show_panel finish]

  }

  ######################################################################
  # Create the finish window.
  proc create_finish {} {

    variable widgets
    variable locs

    # Create the button bar
    make_button $widgets(finish) 500 $locs(button_y) [msgcat::mc "Back"] [list startup::show_panel share]
    make_button $widgets(finish) 580 $locs(button_y) [msgcat::mc "Done"] [list destroy .wizwin]

  }

  ######################################################################
  # Creates a button.
  proc make_button {c x y txt command} {

    # Create the button
    set id [$c create text $x $y -anchor nw -font "-underline 1" -text $txt -fill black]

    # Create bindings
    $c bind $id <Button-1> $command
    $c bind $id <Enter>    [list $c itemconfigure $id -fill blue]
    $c bind $id <Leave>    [list $c itemconfigure $id -fill black]

    return $id

  }

  ######################################################################
  # Creates a radiobutton.
  proc make_radiobutton {c x y txt var value command} {

    variable rbs

    set csize 10

    # Create the checkbutton
    set cid1 [$c create oval $x $y [expr $x + $csize] [expr $y + $csize] -outline black -fill white]
    set cid  [$c create oval [expr $x + 2] [expr $y + 2] [expr $x + $csize - 2] [expr $y + $csize - 2] -outline white -fill white]
    set tid  [$c create text [expr $x + $csize + 10] [expr $y - 2] -text $txt -anchor nw]

    # $c bind $cid <Enter>    [list $c itemconfigure $cid -fill grey]
    # $c bind $cid <Leave>    [list $c itemconfigure $cid -fill white]
    $c bind $cid <Button-1> [list startup::toggle_radiobutton $c $cid $var $value $command 1]

    set rbs($var,$value) [list $cid $command]

    # Make the radiobutton look selected
    if {[set $var] eq $value} {
      $c itemconfigure $cid -fill black
    }

    trace add variable $var write [list startup::handle_rb_var_change $c]

  }

  ######################################################################
  # Handles any changes to the
  proc handle_rb_var_change {c name1 name2 op} {

    variable rbs

    lassign $rbs($name1,[set $name1]) cid command

    toggle_radiobutton $c $cid $name1 [set $name1] $command 0

  }

  ######################################################################
  # Toggles the radiobutton.
  proc toggle_radiobutton {c id var value command setvar} {

    variable rbs

    # Clear the radiobuttons
    foreach key [array name rbs $var,*] {
      $c itemconfigure [lindex $rbs($key) 0] -fill white
    }

    # Make the item
    $c itemconfigure $id -fill black

    # Update the variable to the given value
    if {$setvar} {
      set $var $value
    }

    # Execute the command
    if {$command ne ""} {
      uplevel #0 $command
    }

  }

}

