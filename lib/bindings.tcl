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
# Name:    bindings.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/12/2013
# Brief:   Handles menu bindings from configuration file
######################################################################

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
    load_file 0

  }

  ######################################################################
  # Saves the given shortcut information to the menu binding file.
  proc save {max shortcuts} {

    variable user_bindings_file

    if {![catch { open $user_bindings_file w } rc]} {

      set last_mnu ""

      foreach shortcut $shortcuts {
        set mnu_path [lindex $shortcut 0]
        set mnu      [lindex [split $mnu_path /] 0]
        if {$mnu ne $last_mnu} {
          if {$last_mnu ne ""} {
            puts $rc ""
          }
          puts $rc "# [string totitle $mnu] menu bindings"
          set last_mnu $mnu
        }
        puts $rc "{$mnu_path}[string repeat { } [expr $max - [string length $mnu_path]]]  [lindex $shortcut 1]"
      }

      # Close the file
      close $rc

      # Next, load the file
      load_file 1

    }

  }

  ######################################################################
  # Adds the global menu bindings file to the editor as a read-only file.
  proc view_global {} {

    variable base_bindings_file

    [ns gui]::add_file end $base_bindings_file -sidebar 0 -readonly 1

  }

  ######################################################################
  # Adds the user menu bindings file to the editor.
  proc edit_user {} {

    variable user_bindings_file

    [ns gui]::add_file end $user_bindings_file -sidebar 0 -savecommand [list [ns bindings]::load_file 0]

  }

  ########################
  #  PRIVATE PROCEDURES  #
  ########################

  ######################################################################
  # Polls on the bindings file in the tke home directory.  Whenever it
  # changes modification time, re-read the file and store it in the
  # menu_bindings array
  proc load_file {skip_base {dummy 0}} {

    variable base_bindings_file
    variable user_bindings_file
    variable menu_bindings

    # Remove the existing bindings
    remove_all_bindings

    if {!$skip_base} {
      if {[file exists $user_bindings_file]} {
        if {![catch { [ns tkedat]::read $base_bindings_file 0 } rc]} {
          array set menu_bindings $rc
        }
      } else {
        copy_default 0
      }
    }

    if {![catch { [ns tkedat]::read $user_bindings_file 0 } rc]} {
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

    foreach {mnu_path binding} [array get menu_bindings] {
      set menu_list [split $mnu_path /]
      if {![catch { [ns menus]::get_menu [lrange $menu_list 0 end-1] } mnu]} {
        if {![catch { $mnu index [msgcat::mc [lindex $menu_list end]] } menu_index] && ($menu_index ne "none")} {
          set value [list * * * * *]
          foreach elem [split $binding -] {
            lset value [lindex [accelerator_mapping $elem] 0] $elem
          }
          set binding [join [string map {* {}} $value] -]
          set bound_menus($mnu,$menu_index) $binding
          $mnu entryconfigure $menu_index -accelerator $binding
          bind all [accelerator_to_sequence $binding] "[ns menus]::invoke $mnu $menu_index; break"
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
    foreach {mnu_index binding} [array get bound_menus] {
      lassign [split $mnu_index ,] mnu index
      $mnu entryconfigure $index -accelerator ""
      bind all <$binding> ""
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
      Alt       "Mod2-"
      Cmd       "Mod1-"
      Super     "Mod1-"
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
      Space     "space"
    }

    # Create the sequence
    foreach value [split $accelerator -] {
      if {[info exists mapping($value)]} {
        append sequence $mapping($value)
      } elseif {$value eq "Shift"} {
        set shifted 1
      } else {
        if {[string length $value] == 1} {
          if {$shifted} {
            append sequence [string toupper $value]
          } else {
            append sequence [string tolower $value]
          }
        } else {
          append sequence $value
        }
      }
    }

    append sequence ">"

    return $sequence

  }

  ######################################################################
  # Maps the given value to the displayed.
  proc accelerator_mapping {value} {

    array set map {
      Ctrl,\u2303    0
      Alt,\u2325     1
      Shift,\u21e7   2
      Cmd,\u2318     3
      Up,\u2191      4
      Down,\u2193    4
      Left,\u2190    4
      Right,\u2192   4
    }

    if {[set key [array names map $value,*]] ne ""} {
      return [list $map($key) [lindex [split $key ,] 1]]
    } elseif {[set key [array names map *,$value]] ne ""} {
      return [list $map($key) [lindex [split $key ,] 0]]
    } elseif {[string length $value] == 2} {
      return [list 4 [string index $value 1]]
    } else {
      return [list 4 $value]
    }

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



