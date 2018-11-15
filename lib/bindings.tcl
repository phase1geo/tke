# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
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

  variable base_bindings_file [file join $::tke_dir data bindings menu_bindings.[tk windowingsystem].tkedat]
  variable user_bindings_file [file join $::tke_home menu_bindings.[tk windowingsystem].tkedat]
  variable reversed_loaded    0

  array set menu_bindings {}
  array set reversed_translations {}

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
  # If a user bindings file exists, remove it and perform a load.
  proc use_default {} {

    variable user_bindings_file

    # If a user binding file exists, do the following
    if {[file exists $user_bindings_file]} {

      # Remove the file
      file delete -force $user_bindings_file

      # Reload the bindings
      load_file 0

    }

  }

  ######################################################################
  # Saves the given shortcut information to the menu binding file.
  proc save {max shortcuts} {

    variable user_bindings_file

    # Make sure the the reversed translations are loaded
    load_reversed_translations

    if {![catch { open $user_bindings_file w } rc]} {

      set last_mnu ""

      foreach shortcut $shortcuts {
        set mnu_path [translate_to_en [lindex $shortcut 0]]
        set mnu      [lindex [split $mnu_path /] 0]
        if {$mnu ne $last_mnu} {
          if {$last_mnu ne ""} {
            puts $rc ""
          }
          puts $rc "# [string totitle $mnu] menu bindings"
          set last_mnu $mnu
        }
        puts -nonewline $rc "{$mnu_path}[string repeat { } [expr $max - [string length $mnu_path]]]  "
        if {[lindex $shortcut 1] eq ""} {
          puts $rc "{}"
        } else {
          puts $rc [lindex $shortcut 1]
        }
      }

      # Close the file
      close $rc

      # Next, load the file
      load_file 1

    }

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

    # Read in the base bindings file.  Copy it to the user bindings file, if one does not exist.
    if {!$skip_base} {
      if {[file exists $user_bindings_file]} {
        if {![catch { tkedat::read $base_bindings_file 0 } rc]} {
          array set menu_bindings $rc
          array set reversed      [lreverse $rc]
        }
      } else {
        file copy -force $base_bindings_file $::tke_home
      }
    }

    # Read in the user bindings file.
    if {![catch { tkedat::read $user_bindings_file 0 } rc]} {

      # This block of code removes and default menu bindings that are in use by the user.
      foreach {mnu binding} $rc {
        if {[info exists reversed($binding)]} {
          catch { unset menu_bindings($reversed($binding)) }
        }
        set menu_bindings($mnu) $binding
      }

      # Apply the bindings to the UI
      apply_all_bindings

    } else {

      # Remove all menu bindings if we were unable to read the user bindings file (this file should exist)
      array unset menu_bindings

    }

  }

  ######################################################################
  # This must be called prior to saving shortcut changes.  It must read
  # the translation file and create a hash table so that we can convert
  # a translated string back to an English string (we will store English
  # menus to the bindings file to keep things working if the translation
  # is changed).
  proc load_reversed_translations {} {

    variable reversed_translations
    variable reversed_loaded

    # If we have already reversed the translations, don't continue
    if {$reversed_loaded > 0} {
      return
    }

    # Get the list of translations that we support
    set langs [glob -directory [file join $::tke_dir data msgs] -tails *.msg]

    # Figure out which language file is being used
    set lang_file ""
    foreach locale [msgcat::mcpreferences] {
      if {[lsearch $langs $locale.msg] != -1} {
        set lang_file $locale.msg
      }
    }

    # Indicate that we are loaded
    set reversed_loaded 1

    # If we didn't find a translation file, the strings are going to be in English anyways
    # so just return
    if {$lang_file eq ""} {
      return
    }

    # We will remap the msgcat::mcmset procedure and create a new version of the command
    rename ::msgcat::mcmset ::msgcat::mcmset_orig
    proc ::msgcat::mcmset {lang translations} {
      array set bindings::reversed_translations [lreverse $translations]
    }
    source -encoding utf-8 [file join $::tke_dir data msgs $lang_file]
    rename ::msgcat::mcmset      ""
    rename ::msgcat::mcmset_orig ::msgcat::mcmset

  }

  ######################################################################
  # Translates the given menu path into the english version.
  proc translate_to_en {mnu_path} {

    variable reversed_translations

    set new_mnu_path [list]

    foreach part [split $mnu_path /] {
      set suffix ""
      if {[string range $part end-2 end] eq "..."} {
        set part   [string range $part 0 end-3]
        set suffix "..."
      }
      if {[info exists reversed_translations($part)]} {
        lappend new_mnu_path $reversed_translations($part)$suffix
      } else {
        lappend new_mnu_path $part$suffix
      }
    }

    return [join $new_mnu_path /]

  }

  ######################################################################
  # Applies the current bindings from the configuration file.
  proc apply_all_bindings {} {

    variable menu_bindings
    variable bound_menus

    array unset bound_menus

    foreach {mnu_path binding} [array get menu_bindings] {
      if {$binding eq ""} {
        continue
      }
      set menu_list [split $mnu_path /]
      if {![catch { menus::get_menu [lrange $menu_list 0 end-1] } mnu]} {
        if {![catch { menus::get_menu_index $mnu [lindex $menu_list end] } menu_index] && ($menu_index ne "none")} {
          set value [list "" "" "" "" ""]
          if {[string range $binding end-1 end] eq "--"} {
            set binding [string range $binding 0 end-2]
            lset value 4 "-"
          }
          foreach elem [split $binding -] {
            lset value [lindex [accelerator_mapping $elem] 0] $elem
          }
          set binding [join [concat {*}$value] -]
          set bound_menus($mnu,$menu_index) $binding
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
    foreach {mnu_index binding} [array get bound_menus] {
      lassign [split $mnu_index ,] mnu index
      $mnu entryconfigure $index -accelerator ""
      bind all <$binding> ""
    }

    # Delete the menu_bindings array
    array unset menu_bindings

  }

  ######################################################################
  # Returns 1 if the given menu contains an empty menu binding.
  proc is_cleared {mnu} {

    variable menu_bindings

    return [expr {[info exists menu_bindings($mnu)] && ($menu_bindings($mnu) eq "")}]

  }

  ######################################################################
  # Convert the Tcl binding to an appropriate accelerator.
  proc accelerator_to_sequence {accelerator} {

    set sequence    "<"
    set append_dash 0
    set shift       0
    set alt         0

    # Create character to keysym mapping
    array set mapping {
      Ctrl      "Control-"
      Alt       "Alt-"
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
      &         "ampersand"
      Space     "space"
    }

    array set shift_mapping {
      1 "exclam"
      2 "at"
      3 "numbersign"
      4 "dollar"
      5 "percent"
      6 "asciicircum"
      7 "ampersand"
      8 "asterisk"
      9 "parenleft"
      0 "parenright"
      - "underscore"
      = "plus"
      \[ "bracketleft"
      \] "bracketright"
      \\ "bar"
      ;  "colon"
      '  "quotedbl"
      ,  "less"
      .  "greater"
      /  "question"
    }

    # I don't believe there are any Alt key mappings on other platforms
    array set alt_mapping {}

    # If we are on a Mac, adjust the mapping
    if {[tk windowingsystem] eq "aqua"} {
      unset mapping(Alt)
      array set alt_mapping {
        1  "exclamdown"
        3  "sterling"
        4  "cent"
        6  "section"
        7  "paragraph"
        9  "ordfeminine"
        0  "masculine"
        r  "registered"
        y  "yen"
        o  "oslash"
        p  "Amacron"
        \\ "guillemotleft"
        a  "aring"
        s  "ssharp"
        g  "copyright"
        l  "notsign"
        ,  "ae"
        c  "ccedilla"
        m  "mu"
        /  "division"
        *  "degree"
        (  "periodcentered"
        +  "plusminus"
        E  "acute"
        Y  "Aacute"
        U  "diaeresis"
        I  "Ccircumflex"
        O  "Ooblique"
        |  "guillemotright"
        A  "Aring"
        S  "Iacute"
        D  "Icircumflex"
        F  "Idiaresis"
        G  "Ubreve"
        H  "Oacute"
        J  "Ocircumflex"
        L  "Ograve"
        :  "Uacute"
        \" "AE"
        z  "cedilla"
        C  "Ccedilla"
        M  "Acircumflex"
        <  "macron"
        >  "Gcircumflex"
        ?  "questuondown"
      }
    }

    # If the sequence detail is the minus key, this will cause problems with the parser so
    # remove it and append it at the end of the sequence.
    if {[string range $accelerator end-1 end] eq "--"} {
      set append_dash 1
      set accelerator [string range $accelerator 0 end-2]
    }

    # Create the sequence
    foreach value [split $accelerator -] {
      if {$alt && !$shift && [info exists alt_mapping([string tolower $value])]} {
        append sequence $alt_mapping([string tolower $value])
      } elseif {$alt && $shift && [info exists alt_mapping([string toupper $value])]} {
        append sequence $alt_mapping([string toupper $value])
      } elseif {$shift && [info exists shift_mapping($value)]} {
        append sequence $shift_mapping($value)
      } elseif {[info exists mapping($value)]} {
        append sequence $mapping($value)
      } elseif {$value eq "Shift"} {
        append sequence "Shift-"
        set shift 1
      } elseif {$value eq "Alt"} {
        set alt 1
      } elseif {[string length $value] == 1} {
        if {$alt} {
          append sequence "Mod2-"
        }
        append sequence [string tolower $value]
      } else {
        append sequence $value
      }
    }

    if {$append_dash} {
      append sequence "minus"
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

    # Special-case the asterisk character
    if {($value eq "*") || ($value eq "?")} {
      return [list 4 $value]
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

}

