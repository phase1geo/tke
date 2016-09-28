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
  array set items   {}
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
    initialize

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
    foreach window [list welcome share advanced directory finish] {
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
  # Initializes the startup namespace.
  proc initialize {} {

    variable items

    # Create the images
    create_images

    # Initialize the items list
    foreach {type nspace name} [sync::get_sync_items] {
      set items($type) 1
    }

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

    # Create a button for the advanced settings
    make_button $widgets(share) $locs(left_x) 300 [format "%s..." [msgcat::mc "Advanced Settings"]] [list startup::show_panel advanced]

    # Create the button bar
    make_button $widgets(share) 500 $locs(button_y) [msgcat::mc "Back"] [list startup::show_panel welcome]
    make_button $widgets(share) 580 $locs(button_y) [msgcat::mc "Next"] \
      [list if {$startup::type eq "local"} { startup::show_panel finish } else { startup::show_panel directory }]

  }

  ######################################################################
  # Creates the advanced options for settings.
  proc create_advanced {} {

    variable widgets
    variable locs

    # Create the sync item checkbuttons
    set y 100
    foreach {type nspace name} [sync::get_sync_items] {
      make_checkbutton $widgets(advanced) $locs(left_x) $y $name startup::items($type) {}
      set y [expr $y + 25]
    }

    # Create the button bar
    make_button $widgets(advanced) 500 $locs(button_y) [msgcat::mc "Back"] [list startup::show_panel share]
    make_button $widgets(advanced) 580 $locs(button_y) [msgcat::mc "Done"] [list startup::show_panel directory]

  }

  ######################################################################
  # Creates the directory browse panel.
  proc create_directory {} {

    variable widgets
    variable locs

    # Create the button bar
    make_button $widgets(directory) 500 $locs(button_y) [msgcat::mc "Back"] [list startup::show_panel share]
    make_button $widgets(directory) 580 $locs(button_y) [msgcat::mc "Next"] [list startup::show_panel finish]

  }

  ######################################################################
  # Create the finish window.
  proc create_finish {} {

    variable widgets
    variable locs

    # Create the button bar
    make_button $widgets(finish) 500 $locs(button_y) [msgcat::mc "Back"] \
      [list if {$startup::type eq "local"} { startup::show_panel share } else { startup::show_panel directory }]
    make_button $widgets(finish) 580 $locs(button_y) [msgcat::mc "Finish"] [list destroy .wizwin]

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

    # Create the radiobutton
    set cid1 [$c create oval $x $y [expr $x + $csize] [expr $y + $csize] -outline black -fill white]
    set cid  [$c create oval [expr $x + 2] [expr $y + 2] [expr $x + $csize - 2] [expr $y + $csize - 2] -outline white -fill white]
    set tid  [$c create text [expr $x + $csize + 10] [expr $y - 2] -text $txt -anchor nw]

    $c bind $cid <Button-1> [list startup::toggle_radiobutton $c $cid $var $value $command 1]

    set rbs($var,$value) [list $cid $command]

    # Make the radiobutton look selected
    if {[set $var] eq $value} {
      $c itemconfigure $cid -fill black
    }

    trace add variable $var write [list startup::handle_rb_var_change $c]

  }

  ######################################################################
  # Handles any changes to the radiobutton variable.
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

  ######################################################################
  # Create the checkbutton.
  proc make_checkbutton {c x y txt var command} {

    set ssize 10

    # Create the checkbutton
    set sid1 [$c create rectangle $x $y [expr $x + $ssize] [expr $y + $ssize] -outline black -fill white]
    set sid  [$c create rectangle [expr $x + 2] [expr $y + 2] [expr $x + $ssize - 2] [expr $y + $ssize -2] -outline white -fill white]
    set tid  [$c create text [expr $x + $ssize + 10] [expr $y - 2] -text $txt -anchor nw]

    $c bind $sid <Button-1> [list startup::toggle_checkbutton $c $sid $var $command 1]

    # Make the checkbutton look selected
    if {[set $var]} {
      $c itemconfigure $sid -fill black
    }

    trace add variable $var write [list startup::handle_cb_var_change $c $sid $command]

  }

  ######################################################################
  # Handles any changes to the checkbutton variable.
  proc handle_cb_var_change {c sid command name1 name2 op} {

    toggle_checkbutton $c $sid $name1 $command 0

  }

  ######################################################################
  # Changes the state of the checkbutton.
  proc toggle_checkbutton {c id var command setvar} {

    puts "In toggle_checkbutton, var: $var, value: [set $var]"

    # Set the state of the widget
    if {$setvar} {
      upvar #0 $var v
      set v [expr $v ^ 1]
    }

    puts "HERE C"
    $c itemconfigure $id -fill [expr {[set $var] ? "black" : "white"}]
    puts "HERE C"

    # Execute the command
    if {$command ne ""} {
      uplevel #0 $command
    }

  }

}

