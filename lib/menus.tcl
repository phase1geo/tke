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
    
    # Add the find menu
    $mb add cascade -label "Find" -menu [menu $mb.find -tearoff false]
    add_find $mb.find

    # Add the text menu
    $mb add cascade -label "Text" -menu [menu $mb.text -tearoff false]
    add_text $mb.text
      
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
    launcher::register "Menu: New file" menus::new_command
    
    $mb add command -label "Open..."    -underline 0 -command "menus::open_command"
    launcher::register "Menu: Open file" menus::open_command
    
    $mb add separator
    
    $mb add command -label "Save"       -underline 0 -command "menus::save_command"
    launcher::register "Menu: Save file" menus::save_command
    
    $mb add command -label "Save As..." -underline 5 -command "menus::save_as_command"
    launcher::register "Menu: Save file as" menus::save_as_command
    
    $mb add separator
    
    $mb add command -label "Close"      -underline 0 -command "menus::close_command"
    launcher::register "Menu: Close current tab" menus::close_command

    $mb add separator

    $mb add command -label "Quit tke"   -underline 0 -command "menus::exit_command"
    launcher::register "Menu: Quit tke" menus::exit_command

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
    
    # Save the window geometry
    gui::save_geometry

    # Save the clipboard history
    cliphist::save
  
    # Destroy the interface
    destroy .

  }
  
  ######################################################################
  # Adds the edit menu.
  proc add_edit {mb} {
    
    # Add edit menu commands
    $mb add command -label "Undo" -underline 0 -command "gui::undo"
    launcher::register "Menu: Undo" gui::undo
    
    $mb add command -label "Redo" -underline 0 -command "gui::redo"
    launcher::register "Menu: Redo" gui::redo
    
    $mb add separator
    
    $mb add command -label "Cut"   -underline 0 -command "gui::cut"
    launcher::register "Menu: Cut selected text" gui::cut
    
    $mb add command -label "Copy"  -underline 1 -command "gui::copy"
    launcher::register "Menu: Copy selected text" gui::copy
    
    $mb add command -label "Paste" -underline 0 -command "gui::paste"
    launcher::register "Menu: Paste text from clipboard" gui::paste
    
    $mb add command -label "Paste and Format" -underline 10 -command "gui::paste_and_format"
    launcher::register "Menu: Paste and format text from clipboard" gui::paste_and_format

    #$mb add separator

    #$mb add command -label "Preferences..." -underline 3 -command "FOOBAR"
    #launcher::register "FOOBAR" FOOBAR

    # Apply the menu settings for the edit menu
    bindings::apply $mb
  
  }
  
  ######################################################################
  # Add the find menu.
  proc add_find {mb} {
    
    # Add find menu commands
    $mb add command -label "Find" -underline 0 -command "gui::search"
    launcher::register "Menu: Find" gui::search
    
    $mb add command -label "Find and Replace" -underline 9 -command "gui::search_and_replace"
    launcher::register "Menu: Find and Replace" gui::search_and_replace
    
    $mb add separator
    
    $mb add command -label "Select next occurrence" -underline 7 -command "gui::search_next 0"
    launcher::register "Menu: Find next occurrence" "gui::search_next 0"
    
    $mb add command -label "Select previous occurrence" -underline 7 -command "gui::search_previous 0"
    launcher::register "Menu: Find previous occurrence" "gui::search_previous 0"
    
    $mb add command -label "Append next occurrence" -underline 1 -command "gui::search_next 1"
    launcher::register "Menu: Append next occurrence" "gui::search_next 1"
    
    $mb add command -label "Select all occurrences" -underline 7 -command "gui::search_all"
    launcher::register "Menu: Select all occurrences" "gui::search_all"
    
    # Apply the menu settings for the find menu
    bindings::apply $mb
    
  }
  
  ######################################################################
  # Adds the text menu commands.
  proc add_text {mb} {

    $mb add command -label "Comment" -underline 0 -command "texttools::comment"
    launcher::register "Menu: Comment selected text" "texttools::comment"

    $mb add command -label "Uncomment" -underline 0 -command "texttools::uncomment"
    launcher::register "Menu: Uncomment selected text" "texttools::uncomment"
    
    # Apply the menu settings for the text menu
    bindings::apply $mb

  }

  ######################################################################
  # Adds the tools menu commands.
  proc add_tools {mb} {
  
    # Add tools menu commands
    $mb add command -label "Launcher" -underline 0 -command "launcher::launch"
    
    $mb add separator
    
    $mb add checkbutton -label "Vim Mode" -underline 0 -variable preferences::prefs(Tools/VimMode) -command "vim::set_vim_mode"
    launcher::register "Menu: Enable Vim mode"  "set preferences::prefs(Tools/VimMode) 1; vim::set_vim_mode"
    launcher::register "Menu: Disable Vim mode" "set preferences::prefs(Tools/VimMode) 0; vim::set_vim_mode"
    
    $mb add separator
    
    $mb add command -label "Restart tke" -underline 0 -command "menus::restart_command"
    launcher::register "Menu: Restart tke" "menus::restart_command"
   
    # Apply the menu bindings for the tools menu
    bindings::apply $mb
  
  }
  
  ######################################################################
  # Restart the GUI.
  proc restart_command {} {
  
    # Get the list of filenames to start
    set filenames [gui::get_actual_filenames]
    
    # Execute the restart command
    exec [info nameofexecutable] [file join $::tke_dir restart.tcl] [info nameofexecutable] [file join $::tke_dir tke.tcl] {*}$filenames &
  
  }
  
}



