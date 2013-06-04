# Name:    bindings.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/12/2013
# Brief:   Handles menu bindings from configuration file

namespace eval bindings {

  variable bindings_file [file join $::tke_home menu_bindings.dat]

  array set menus         {}
  array set menu_bindings {}
  
  #######################
  #  PUBLIC PROCEDURES  #
  #######################
  
  ######################################################################
  # Loads the bindings information
  proc load {} {
  
    variable bindings_file
    
    # If the bindings file does not exist, copy the one from the "data"
    # directory to the tke_home directory.
    if {![file exists $bindings_file]} {
      copy_default
    }
  
    # Load the menu bindings file
    load_file
    
    # Add our launcher commands
    launcher::register "Menu Bindings: Edit menu bindings" \
      [list gui::add_file end $bindings_file bindings::load_file]
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
  
    variable bindings_file
    variable menu_bindings
    variable menus
    
    if {[file exists $bindings_file]} {
      if {![catch "open $bindings_file r" rc]} {
        remove_all_bindings
        array set menu_bindings [read $rc]
        close $rc
        foreach mnu [array names menus] {
          apply $mnu
        }
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
  proc copy_default {} {
  
    variable bindings_file
    
    # Copy the default bindings to the tke home directory
    file copy -force [file join [file dirname $::tke_dir] data [file tail $bindings_file]] $::tke_home
    
    # Load the file
    load_file
    
  }

}



