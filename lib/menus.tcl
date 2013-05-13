# Name:    menus.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace containing menu functionality

namespace eval menus {

  #######################
  #  PUBLIC PROCEDURES  #
  #######################

  ######################################################################
  # Creates the main menu.
  proc create {} {
  
    set mb [menu .menubar -tearoff false]
    . configure -menu $mb
  
    # Add the file menu
    $mb add cascade -label "File" \
      -menu [menu $mb.file -tearoff false -postcommand "menus::add_file $mb.file"]
    
    # Add the edit menu
    $mb add cascade -label "Edit" \
      -menu [menu $mb.edit -tearoff false -postcommand "menus::add_edit $mb.edit"]
  
  }
  
  ########################
  #  PRIVATE PROCEDURES  #
  ########################
  
  ######################################################################
  # Adds the file menu.
  proc add_file {mb} {
  
    $mb delete 0 end
  
    $mb add command -label "New"        -underline 0 -command "menus::new_command"
    $mb add command -label "Open..."    -underline 0 -command "menus::open_command"
    $mb add separator
    $mb add command -label "Save"       -underline 0 -command "menus::save_command"
    $mb add command -label "Save As..." -underline 5 -command "menus::save_as_command"
    $mb add separator
    $mb add command -label "Close"      -underline 0 -command "menus::close_command"
    $mb add separator
    $mb add command -label "Quit tke"   -underline 0 -command "menus::exit_command"

    # Apply the menu settings for the current menu
    bindings::apply $mb
  
  }
  
  ######################################################################
  # Implements the "create new file" command.
  proc new_command {} {
  
    gui::add_new_file end
  
  }
  
  ######################################################################
  # Opens a new file and adds a new tab for the file.
  proc open_command {} {
  
    if {[set ofiles [tk_getOpenFile -parent . -initialdir [pwd] -defaultextension .tcl -multiple 1]] ne ""} {
      foreach ofile $ofiles {
        gui::add_file end $ofile
      }
    }
  
  }
  
  ######################################################################
  # Saves the current tab file.
  proc save_command {} {
  
    if {[set sfile [gui::current_filename]] eq ""} {
      save_as_command
    } else {
      gui::save_current $sfile
    }
  
  }
  
  ######################################################################
  # Saves the current tab file as a new filename.
  proc save_as_command {} {
  
    if {[set sfile [tk_getSaveFile -defaultextension .tcl -title "Save As" -parent . -initialdir [pwd]]] ne ""} {
      gui::save_current $sfile
    }
  
  }
  
  ######################################################################
  # Closes the current tab.
  proc close_command {} {
  
    gui::close_current
  
  }
  
  ######################################################################
  # Exits the application.
  proc exit_command {} {
  
    # Close all of the tabs
    gui::close_all
  
    # Destroy the interface
    destroy .

  }
  
  ######################################################################
  # Adds the edit menu.
  proc add_edit {mb} {
  
    # Delete all of the menu items
    $mb delete 0 end
    
    # Add edit menu commands
    $mb add command -label "Undo" -underline 0 -command "gui::undo"
    $mb add command -label "Redo" -underline 0 -command "gui::redo"
    $mb add separator
    $mb add command -label "Cut"   -underline 0 -command "gui::cut"
    $mb add command -label "Copy"  -underline 1 -command "gui::copy"
    $mb add command -label "Paste" -underline 0 -command "gui::paste"

    # Apply the menu settings for the edit menu
    bindings::apply $mb
  
  }
  
}

