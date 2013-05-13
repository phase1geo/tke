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
  
    # Load the menu bindings
    bindings::load
  
    set mb [menu .menubar -tearoff false]
    . configure -menu $mb
  
    # Add the file menu
    $mb add cascade -label "File" -menu [menu $mb.file -tearoff false] 
    add_file $mb.file
    
    # Add the edit menu
    $mb add cascade -label "Edit" -menu [menu $mb.edit -tearoff false]
    add_edit $mb.edit
      
    # Add the tools menu
    $mb add cascade -label "Tools" -menu [menu $mb.tools -tearoff false]
    add_tools $mb.tools
  
  }
  
  ########################
  #  PRIVATE PROCEDURES  #
  ########################
  
  ######################################################################
  # Adds the file menu.
  proc add_file {mb} {
  
    $mb delete 0 end
  
    $mb add command -label "New"        -underline 0 -command "menus::new_command"
    launcher::register "New file" menus::new_command
    
    $mb add command -label "Open..."    -underline 0 -command "menus::open_command"
    launcher::register "Open file" menus::open_command
    
    $mb add separator
    
    $mb add command -label "Save"       -underline 0 -command "menus::save_command"
    launcher::register "Save file" menus::save_command
    
    $mb add command -label "Save As..." -underline 5 -command "menus::save_as_command"
    launcher::register "Save file as" menus::save_as_command
    
    $mb add separator
    
    $mb add command -label "Close"      -underline 0 -command "menus::close_command"
    launcher::register "Close current tab" menus::close_command

    $mb add separator

    $mb add command -label "Quit tke"   -underline 0 -command "menus::exit_command"
    launcher::register "Quit tke" menus::exit_command

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
    
    # Add edit menu commands
    $mb add command -label "Undo" -underline 0 -command "gui::undo"
    launcher::register "Undo" gui::undo
    
    $mb add command -label "Redo" -underline 0 -command "gui::redo"
    launcher::register "Redo" gui::redo
    
    $mb add separator
    
    $mb add command -label "Cut"   -underline 0 -command "gui::cut"
    launcher::register "Cut selected text" gui::cut
    
    $mb add command -label "Copy"  -underline 1 -command "gui::copy"
    launcher::register "Copy selected text" gui::copy
    
    $mb add command -label "Paste" -underline 0 -command "gui::paste"
    launcher::register "Paste text from clipboard" gui::paste

    # Apply the menu settings for the edit menu
    bindings::apply $mb
  
  }
  
  ######################################################################
  # Adds the tools menu.
  proc add_tools {mb} {
  
    # Add tools menu commands
    $mb add command -label "Launcher" -underline 0 -command "launcher::launch"
   
    # Apply the menu bindings for the tools menu
    bindings::apply $mb
  
  }
  
}

