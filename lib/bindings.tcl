# Name:    bindings.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/12/2013
# Brief:   Handles menu bindings from configuration file

namespace eval bindings {

  source [file join $::tke_dir lib ns.tcl]
  
  variable base_bindings_file [file join $::tke_dir data bindings menu_bindings.[tk windowingsystem].tkedat]
  variable user_bindings_file [file join $::tke_home menu_bindings.[tk windowingsystem].tkedat]

  array set menu_bindings {}
  
  #######################
  #  PUBLIC PROCEDURES  #
  #######################
  
  ######################################################################
  # Loads the bindings information
  proc load {} {
  
    # Load the menu bindings file
    load_file
    
  }
  
  ######################################################################
  # Adds the global menu bindings file to the editor as a read-only file.
  proc view_global {} {
    
    variable base_bindings_file
    
    gui::add_file end $base_bindings_file -sidebar 0 -readonly 1
    
  }
  
  ######################################################################
  # Adds the user menu bindings file to the editor.
  proc edit_user {} {
    
    variable user_bindings_file
    
    gui::add_file end $user_bindings_file -sidebar 0 -savecommand bindings::load_file
    
  }
  
  ########################
  #  PRIVATE PROCEDURES  #
  ########################
  
  ######################################################################
  # Polls on the bindings file in the tke home directory.  Whenever it
  # changes modification time, re-read the file and store it in the
  # menu_bindings array
  proc load_file {} {
  
    variable base_bindings_file
    variable user_bindings_file
    variable menu_bindings
    
    if {[file exists $user_bindings_file]} {
      remove_all_bindings
      if {![catch { tkedat::read $base_bindings_file 0 } rc]} {
        array set menu_bindings $rc
      }
    } else {
      remove_all_bindings
      copy_default 0
    }
    
    if {![catch { tkedat::read $user_bindings_file 0 } rc]} {
      array set menu_bindings $rc
      apply_all_bindings
    } else {
      array unset menu_bindings
    }
    
  }

  ######################################################################
  # Applies the current bindings from the configuration file.
  proc apply_all_bindings {} {

    variable menu_bindings
    variable bound_menus
    
    array unset bound_menus
    
    foreach {mnu binding} [array get menu_bindings] {
      set menu_list [split $mnu /]
      if {![catch { menus::get_menu [lrange $menu_list 0 end-1] } mnu]} {
        if {![catch { $mnu index [msgcat::mc [lindex $menu_list end]] } menu_index] && ($menu_index ne "none")} {
          set bound_menus($mnu) [list $menu_index $binding]
          $mnu entryconfigure $menu_index -accelerator $binding
          bind all [accelerator_to_sequence $binding] "menus::invoke $mnu $menu_index; break"
        }
      }
    }
    
  }
  
  ######################################################################
  # Removes all of the menu bindings.
  proc remove_all_bindings {} {
  
    variable menu_bindings
    variable bound_menus
    
    # Delete all of the accelerators and bindings
    foreach {mnu data} [array get bound_menus] {
      $mnu entryconfigure [lindex $data 0] -accelerator ""
      bind all <[lindex $data 1]> ""
    }
   
    # Delete the menu_bindings array
    array unset menu_bindings
    
  }
  
  ######################################################################
  # Convert the Tcl binding to an appropriate accelerator.
  proc accelerator_to_sequence {accelerator} {
    
    set sequence "<"
    set shifted  0
    
    # Create character to keysym mapping
    array set mapping {
      Ctrl      "Control-"
      Alt       "Alt-"
      !         "exclam"
      \"        "quotedbl"
      \#        "numbersign"
      \$        "dollar"
      %         "percent"
      '         "quoteright"
      (         "parenleft"
      )         "parenright"
      *         "asterisk"
      +         "plus"
      ,         "comma"
      -         "minus"
      .         "period"
      /         "slash"
      :         "colon"
      ;         "semicolon"
      <         "less"
      =         "equal"
      >         "greater"
      ?         "question"
      @         "at"
      \[        "bracketleft"
      \\        "backslash"
      \]        "bracketright"
      ^         "asciicircum"
      _         "underscore"
      `         "quoteleft"
      \{        "braceleft"
      |         "bar"
      \}        "braceright"
      ~         "asciitilde"
    }
    
    # If we are on a Mac, convert the Cmd string to the Command string
    if {[tk windowingsystem] eq "aqua"} {
      array set mapping {
        Cmd   "Command-"
        Super "Command-"
      }
    } else {
      array set mapping {
        Cmd   "Command-"
        Super "Meta-"
      }
    }
    
    # Create the sequence
    foreach value [split $accelerator -] {
      if {[info exists mapping($value)]} {
        append sequence $mapping($value)
      } elseif {$value eq "Shift"} {
        set shifted 1
      } else {
        if {$shifted} {
          append sequence [string toupper $value]
        } else {
          append sequence [string tolower $value]
        }
      }
    }
    
    append sequence ">"

    return $sequence
    
  }
  
  ######################################################################
  # Copies the default settings to the user's .tke directory.
  proc copy_default {{load 1}} {
  
    variable base_bindings_file
    
    # Copy the default bindings to the tke home directory
    file copy -force $base_bindings_file $::tke_home
    
    # Load the file
    if {$load} {
      load_file
    }
    
  }

}



