# Name:    bindings.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/12/2013
# Brief:   Handles menu bindings from configuration file

namespace eval bindings {

  variable base_bindings_file [file join [file dirname $::tke_dir] data menu_bindings.tkedat]
  variable user_bindings_file [file join $::tke_home menu_bindings.tkedat]

  array set menus         {}
  array set menu_bindings {}
  
  #######################
  #  PUBLIC PROCEDURES  #
  #######################
  
  ######################################################################
  # Loads the bindings information
  proc load {} {
  
    variable base_bindings_file
    variable user_bindings_file
    
    # Load the menu bindings file
    load_file
    
    # Add our launcher commands
    launcher::register "Menu Bindings: Edit user menu bindings" \
      [list gui::add_file end $user_bindings_file -sidebar 0 -savecommand bindings::load_file]
    launcher::register "Menu Bindings: View global menu bindings" \
      [list gui::add_file end $base_bindings_file -sidebar 0 -readonly 1]
    launcher::register "Menu Bindings: Use default menu bindings" "bindings::copy_default"
    launcher::register "Menu Bindings: Reload menu bindings" "bindings::load_file"

  
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
    variable menus
    
    if {[file exists $user_bindings_file]} {
      remove_all_bindings
      if {![catch "tkedat::read $base_bindings_file" rc]} {
        array set menu_bindings $rc
      }
    } else {
      remove_all_bindings
      copy_default 0
    }
    
    if {![catch "tkedat::read $user_bindings_file" rc]} {
      array set menu_bindings $rc
      foreach mnu [array names menus] {
        apply $mnu
      }
    } else {
      array unset menu_bindings
    }
    
  }

  ######################################################################
  # Applies the current bindings from the configuration file.
  proc apply {mnu} {

    variable menu_bindings
    variable menus
    
    # Add the menu to the list of menus
    set menus($mnu) 1
    
    # Iterate through the menu items
    for {set i 0} {$i <= [$mnu index end]} {incr i} {
      set type [$mnu type $i]
      if {($type eq "command") || ($type eq "checkbutton")} {
        set label [$mnu entrycget $i -label]
        if {[info exists menu_bindings($mnu/$label)]} {
          $mnu entryconfigure $i -accelerator $menu_bindings($mnu/$label)
          bind all [accelerator_to_sequence $menu_bindings($mnu/$label)] "$mnu invoke $i; break"
        }
      }
    }
  
  }
  
  ######################################################################
  # Removes all of the menu bindings.
  proc remove_all_bindings {} {
  
    variable menus
    variable menu_bindings
    
    foreach mnu [array names menus] {
      for {set i 0} {$i <= [$mnu index end]} {incr i} {
        if {[$mnu type $i] eq "command"} {
          set label [$mnu entrycget $i -label]
          if {[info exists menu_bindings($mnu/$label)]} {
            $mnu entryconfigure $i -accelerator ""
            bind all <$menu_bindings($mnu/$label)> ""
          }
        }
      }
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



