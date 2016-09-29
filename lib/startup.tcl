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
  variable directory     ""

  array set widgets {}
  array set images  {}
  array set rbs     {}
  array set items   {}
  array set locs {
    header_y 50
    help_y   100
    first_y  125
    second_y 200
    button_y 455
    header_x 240
    left_x   250
    help_x   270
    right_x  610
    back_x   500
    next_x   570
  }
  array set colors {
    help grey50
  }

  ######################################################################
  # Creates the startup wizard window.
  proc create {} {

    variable widgets
    variable images
    variable current_panel
    variable type
    variable directory
    variable items

    # Create the images
    initialize

    toplevel     .wizwin
    wm title     .wizwin [format "TKE %s" [msgcat::mc "Welcome"]]
    wm geometry  .wizwin 640x480
    wm resizable .wizwin 0 0
    wm transient .wizwin .
    wm protocol  .wizwin WM_DELETE_WINDOW {
      # Do nothing
    }
    wm withdraw  .wizwin

    # Add the tabs
    foreach window [list welcome settings copy share directory finish] {
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

    return [list $type $directory [array get items]]

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

    # Header
    make_header $widgets(welcome) $locs(header_x) $locs(header_y) [format "%s TKE!" [msgcat::mc "Welcome To"]]

    # Add text
    make_text $widgets(welcome) $locs(header_x) $locs(first_y) \
      [msgcat::mc "Thanks for using TKE, the advanced programmer's editor.  Since this is a new installation of TKE, let's help you get things set up. \\n \\n Click 'Next' below to get things going."]

    # Create Next button
    make_button $widgets(welcome) $locs(next_x) $locs(button_y) [msgcat::mc "Next"] [list startup::show_panel settings]

  }

  ######################################################################
  # Create the import/share window.
  proc create_settings {} {

    variable widgets
    variable locs
    variable colors

    # Header
    make_header $widgets(settings) $locs(header_x) $locs(header_y) [msgcat::mc "Settings Options"]

    # Create a button for the advanced settings
    set id [make_button $widgets(settings) $locs(left_x) 400 [msgcat::mc "Customize Settings"] { startup::show_panel $startup::type }]
    $widgets(settings) itemconfigure $id -state hidden

    # Create the radiobutton
    make_radiobutton $widgets(settings) $locs(left_x) [expr $locs(first_y) + 0]   [msgcat::mc "Create settings locally"]      startup::type local [list $widgets(settings) itemconfigure $id -state hidden]
    make_radiobutton $widgets(settings) $locs(left_x) [expr $locs(first_y) + 65]  [msgcat::mc "Copy settings from directory"] startup::type copy  [list $widgets(settings) itemconfigure $id -state normal]
    make_radiobutton $widgets(settings) $locs(left_x) [expr $locs(first_y) + 145] [msgcat::mc "Use shared settings"]          startup::type share [list $widgets(settings) itemconfigure $id -state normal]

    # Create help text
    make_text $widgets(settings) $locs(help_x) [expr $locs(first_y) + 20] \
      [msgcat::mc "Creates new settings information and places it in your home directory"] $colors(help)
    make_text $widgets(settings) $locs(help_x) [expr $locs(first_y) + 85] \
      [msgcat::mc "Copies settings data from an existing directory to your home directory.  Click 'Customize Settings' below to customize which settings data will be copied."] $colors(help)
    make_text $widgets(settings) $locs(help_x) [expr $locs(first_y) + 165] \
      [msgcat::mc "Shares settings data from a new or existing directory (ex., iCloud Drive, Google Drive, Dropbox, etc.).  Any changes made to settings data will be available to other sharers.  Click 'Customize Settings' below to customize which settings data will be shared."] $colors(help)

    # Create the button bar
    make_button $widgets(settings) $locs(back_x) $locs(button_y) [msgcat::mc "Back"] [list startup::show_panel welcome]
    make_button $widgets(settings) $locs(next_x) $locs(button_y) [msgcat::mc "Next"] \
      [list if {$startup::type eq "local"} { startup::show_panel finish } else { startup::do_directory }]

  }

  foreach ptype [list copy share] {

    ######################################################################
    # Creates the advanced options for settings.
    proc create_$ptype [list [list type $ptype]] {

      variable widgets
      variable locs

      array set labels [list \
        copy  [list [msgcat::mc "Copy"]  [msgcat::mc "Items that are selected will be copied to your local home directory. Items that are not selected will be created in your home directory."]] \
        share [list [msgcat::mc "Share"] [msgcat::mc "Items that are selected will be shared with other computers. Items that are not selected will be stored locally and will not be shared."]] \
      ]

      # Header
      make_header $widgets($type) $locs(header_x) $locs(header_y) [format "%s %s" [msgcat::mc "Settings To"] [lindex $labels($type) 0]]

      # Create help
      make_text $widgets($type) $locs(header_x) $locs(first_y) [lindex $labels($type) 1]

      # Create the sync item checkbuttons
      set y $locs(second_y)
      foreach {itype nspace name} [sync::get_sync_items] {
        make_checkbutton $widgets($type) $locs(left_x) $y $name startup::items($itype) {}
        set y [expr $y + 25]
      }

      # Create the button bar
      make_button $widgets($type) $locs(next_x) $locs(button_y) [msgcat::mc "Back"] [list startup::show_panel settings]

    }

  }

  ######################################################################
  # Creates the directory browse panel.
  proc create_directory {} {

    variable widgets
    variable locs

    # Header
    make_header $widgets(directory) $locs(header_x) $locs(header_y) [msgcat::mc "Select Directory"]

    # Directory
    make_text $widgets(directory) $locs(header_x) $locs(first_y) [format "%s:" [msgcat::mc "Directory"]]
    entry $widgets(directory).dir_entry -width 40 -state readonly -readonlybackground white -foreground black -relief flat
    $widgets(directory) create window [expr $locs(header_x) + 10] [expr $locs(first_y) + 20] -anchor nw -window $widgets(directory).dir_entry

    make_button $widgets(directory) $locs(header_x) 200 [msgcat::mc "Change Directory"] [list startup::set_directory]

    # Create the button bar
    make_button $widgets(directory) $locs(back_x) $locs(button_y) [msgcat::mc "Back"] [list startup::show_panel settings]
    make_button $widgets(directory) $locs(next_x) $locs(button_y) [msgcat::mc "Next"] [list startup::show_panel finish]

  }

  ######################################################################
  # Create the finish window.
  proc create_finish {} {

    variable widgets
    variable locs

    # Header
    make_header $widgets(finish) $locs(header_x) $locs(header_y) [format "%s!" [msgcat::mc "Setup Complete"]]

    # Display text
    make_text $widgets(finish) $locs(header_x) $locs(first_y) \
      [msgcat::mc "If you need would like to change your settings location and/or data, you can do so within the Edit/Settings/Setup... menu."]

    # Create the button bar
    make_button $widgets(finish) $locs(back_x) $locs(button_y) [msgcat::mc "Back"] \
      [list if {$startup::type eq "local"} { startup::show_panel settings } else { startup::show_panel directory }]
    make_button $widgets(finish) $locs(next_x) $locs(button_y) [msgcat::mc "Finish"] [list destroy .wizwin]

  }

  ######################################################################
  # Sets the directory.
  proc set_directory {} {

    variable widgets
    variable directory
    variable type

    set initialdir [expr {($directory eq "") ? [file normalize ~] : $directory}]
    set mustexist  [expr {($type eq "copy") ? 1 : 0}]
    set directory  [tk_chooseDirectory -parent .wizwin -title [msgcat::mc "Select Settings Directory"] -initialdir $initialdir -mustexist $mustexist]

    if {$directory ne ""} {
      $widgets(directory).dir_entry configure -state normal
      $widgets(directory).dir_entry delete 0 end
      $widgets(directory).dir_entry insert end $directory
      $widgets(directory).dir_entry configure -state readonly
    }

  }

  ######################################################################
  # Called when we hit the 'Next' button in the settings panel.  Immediately
  proc do_directory {} {

    variable widgets
    variable directory
    variable type

    show_panel directory

    if {$directory eq ""} {

      # Attempt to set the directory
      set_directory

      # If the directory was not set, go back to settings
      if {$directory eq ""} {
        show_panel settings
      } else {
        # show_panel finish
      }
    }

  }

  ###########
  # WIDGETS #
  ###########

  ######################################################################
  # Creates a header
  proc make_header {c x y txt} {

    set id [$c create text $x $y -anchor nw -font "-size 24" -text $txt -fill black]

    return $id

  }

  ######################################################################
  # Creates a text widget that automatically wraps.
  proc make_text {c x y txt {color black}} {

    variable locs

    set id [$c create text $x $y -anchor nw -text "" -fill $color]

    # Create wrapped text
    set lines      [list]
    set text_width [expr $locs(right_x) - $x]

    set line ""
    foreach word $txt {
      if {([font measure [$c itemcget $id -font] "$line $word"] < $text_width) && \
          ($word ne "\n")} {
        append line " $word"
      } else {
        lappend lines [string trim $line]
        set line $word
      }
    }

    if {$line ne ""} {
      lappend lines [string trim $line]
    }

    $c itemconfigure $id -text [join $lines "\n"]

    return $id

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

    set csize 11

    # Create the radiobutton
    set cid1 [$c create oval $x $y [expr $x + $csize] [expr $y + $csize] -outline black -fill white]
    set cid  [$c create oval [expr $x + 2] [expr $y + 2] [expr $x + $csize - 2] [expr $y + $csize - 2] -outline white -fill white]
    set tid  [$c create text [expr $x + $csize + 10] [expr $y - 2] -text $txt -anchor nw]

    $c bind $cid1 <Button-1> [list set $var $value]
    $c bind $cid  <Button-1> [list set $var $value]
    $c bind $tid  <Button-1> [list set $var $value]

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

    if {$name2 ne ""} {
      toggle_radiobutton $c $cid $name1($name2) [set $name1($name2)] $command
    } else {
      toggle_radiobutton $c $cid $name1 [set $name1] $command
    }

  }

  ######################################################################
  # Toggles the radiobutton.
  proc toggle_radiobutton {c id var value command} {

    variable rbs

    # Clear the radiobuttons
    foreach key [array name rbs $var,*] {
      $c itemconfigure [lindex $rbs($key) 0] -fill white
    }

    # Make the item
    $c itemconfigure $id -fill black

    # Execute the command
    if {$command ne ""} {
      uplevel #0 $command
    }

  }

  ######################################################################
  # Create the checkbutton.
  proc make_checkbutton {c x y txt var command} {

    set ssize 11

    # Create the checkbutton
    set sid1 [$c create rectangle $x $y [expr $x + $ssize] [expr $y + $ssize] -outline black -fill white]
    set sid2 [$c create rectangle [expr $x + 2] [expr $y + 2] [expr $x + $ssize - 2] [expr $y + $ssize -2] -outline white -fill white]
    set tid  [$c create text [expr $x + $ssize + 10] [expr $y - 2] -text $txt -anchor nw]

    $c bind $sid1 <Button-1> [list startup::toggle_value $var]
    $c bind $sid2 <Button-1> [list startup::toggle_value $var]
    $c bind $tid  <Button-1> [list startup::toggle_value $var]

    # Make the checkbutton look selected
    if {[set $var]} {
      $c itemconfigure $sid2 -fill black
    }

    trace add variable $var write [list startup::handle_cb_var_change $c $sid2 $command]

  }

  ######################################################################
  # Toggles the given value
  proc toggle_value {var} {

    set $var [expr [set $var] ^ 1]

  }

  ######################################################################
  # Handles any changes to the checkbutton variable.
  proc handle_cb_var_change {c sid command name1 name2 op} {

    if {$name2 ne ""} {
      toggle_checkbutton $c $sid "$name1\($name2\)" $command
    } else {
      toggle_checkbutton $c $sid $name1 $command
    }

  }

  ######################################################################
  # Changes the state of the checkbutton.
  proc toggle_checkbutton {c id var command} {

    set color [expr {[set $var] ? "black" : "white"}]

    $c itemconfigure $id -fill $color

    # Execute the command
    if {$command ne ""} {
      uplevel #0 $command
    }

  }

}

