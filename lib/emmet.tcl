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
# Name:    emmet.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    02/24/2016
# Brief:   Namespace containing Emmet-related functionality.
######################################################################

source [file join $::tke_dir lib emmet_parser.tcl]
source [file join $::tke_dir lib emmet_css.tcl]

namespace eval emmet {

  source [file join $::tke_dir lib ns.tcl]

  variable custom_file
  variable customizations

  array set data {
    tag      {(.*)(<\/?[\w:-]+(?:\s+[\w:-]+(?:\s*=\s*(?:(?:".*?")|(?:'.*?')|[^>\s]+))?)*\s*(\/?)>)}
    brackets {(.*?)(\[.*?\]|\{.*?\})}
    space    {(.*?)(\s+)}
  }

  # Create the custom filename
  set custom_file [file join $::tke_home emmet.tkedat]

  ######################################################################
  # Initializes Emmet aliases.
  proc load {} {

    variable custom_file

    # If the user has a custom alias file, read it in now.
    if {[file exists $custom_file]} {
      load_custom_aliases
    }

  }

  ######################################################################
  # Returns a three element list containing the snippet text, starting and ending
  # position of that text.
  proc get_snippet_text_pos {tid} {

    variable data

    # Get the current text widget
    set txt [[ns gui]::current_txt $tid]

    # Get the current line and column numbers
    lassign [split [$txt index insert] .] line endcol

    # Get the current line
    set str [$txt get "insert linestart" insert]

    # Get the prespace of the current line
    regexp {^([ \t]*)} $str -> prespace

    # If we have a tag, ignore all text prior to it
    set startcol [expr {[regexp $data(tag) $str match] ? [string length $match] : 0}]

    # Gather the positions of any square or curly brackets in the left-over area
    foreach key [list brackets space] {
      set pos($key) [list]
      set col       $startcol
      while {[regexp -start $col -- $data($key) $str match pre]} {
        lappend pos($key) [expr $col + [string length $pre]] [expr $col + [string length $match]]
        set col [lindex $pos($key) end]
      }
    }

    # See if there is a space which does not exist within a square or curly brace
    foreach {endpos startpos} [lreverse $pos(space)] {
      if {[expr [lsearch [lsort -integer [concat $pos(brackets) $endpos]] $endpos] % 2] == 0} {
        return [list [string range $str $endpos end] $line.$endpos $line.$endcol $prespace]
      }
    }

    return [list [string range $str $startcol end] $line.$startcol $line.$endcol $prespace]

  }

  ######################################################################
  # Parses the current Emmet snippet found in the current editing buffer.
  # Returns a three element list containing the generated code, the
  # starting index of the snippet and the ending index of the snippet.
  proc expand_abbreviation {tid} {

    set txt [[ns gui]::current_txt $tid]

    # Get the language of the current insertion cursor
    if {[set lang [ctext::get_lang $txt insert]] eq ""} {
      set lang [[ns syntax]::get_language $txt]
    }

    # If the current language is CSS, translate the abbreviation as such
    if {$lang eq "CSS"} {

      # Get the abbreviation text, translate it and insert it back into the text
      if {[regexp {(\S+)$} [$txt get "insert linestart" insert] -> abbr]} {
        if {![catch { [ns emmet_css]::parse $abbr } str]} {
          [ns snippets]::insert_snippet_into_current $tid $str -delrange [list "insert-[string length $abbr]c" insert]
        }
      }

    } else {

      # Find the snippet text
      lassign [get_snippet_text_pos $tid] str startpos endpos prespace

      # Parse the snippet and if no error, insert the resulting string
      if {![catch { ::parse_emmet $str $prespace } str]} {
        [ns snippets]::insert_snippet_into_current $tid $str -delrange [list $startpos $endpos]
      }

    }

  }

  ######################################################################
  # Display the custom abbreviation file in an editing buffer.
  proc edit_abbreviations {} {

    variable custom_file

    # Copy the Emmet customization file from the TKE installation directory to the
    # user's home directory.
    if {![file exists $custom_file]} {
      file copy [file join $::tke_dir data emmet.tkedat] $custom_file
    }

    # Add the file to the editor
    [ns gui]::add_file end $custom_file \
      -savecommand [list [ns emmet]::load_custom_aliases] \
      -sidebar 0

  }

  ######################################################################
  # Handles any save operations to the Emmet customization file.
  proc load_custom_aliases {args} {

    variable custom_file
    variable customizations

    # Read in the emmet customizations
    if {![catch { [ns tkedat]::read $custom_file 1 } rc]} {

      array unset customizations

      # Save the customization information
      array set customizations $rc

    }

  }

  ######################################################################
  # Updates the given alias value.
  proc update_alias {type curr_alias new_alias value} {

    variable customizations
    variable custom_file

    # Get the affected aliases and store it in an array
    array set aliases $customizations($type)

    # Remove the old alias information if the curr_alias value does not match the new_alias value
    if {$curr_alias ne $new_alias} {
      catch { unset aliases($curr_alias) }
    }

    if {$new_alias ne ""} {
      set aliases($new_alias) $value
    }

    # Store the aliases list back into the customization array
    set customizations($type) [array get aliases]

    # Write the customization value to file
    catch { [ns tkedat]::write $custom_file [array get customizations] 1 [list node_aliases array abbreviation_aliases array] }

  }

  ######################################################################
  # Returns the alias value associated with the given alias name.  If
  # no alias was found, returns the empty string.
  proc lookup_alias_helper {type alias} {

    variable customizations

    if {[info exists customizations($type)]} {
      array set aliases $customizations($type)
      if {[info exists aliases($alias)]} {
        return $aliases($alias)
      }
    }

    return ""

  }

  ######################################################################
  # Perform a lookup of a customized node alias and returns its value,
  # if found.  If not found, returns the empty string.
  proc lookup_node_alias {alias} {

    return [lookup_alias_helper node_aliases $alias]

  }

  ######################################################################
  # Perform a lookup of a customized abbreviation alias and returns its value,
  # if found.  If not found, returns the empty string.
  proc lookup_abbr_alias {alias} {

    return [lookup_alias_helper abbreviation_aliases $alias]

  }

  ######################################################################
  # Get the alias information.
  proc get_aliases {} {

    variable customizations

    return [array get customizations]

  }

  ######################################################################
  # Returns a list of files/directories used by the Emmet namespace for
  # importing/exporting purposes.
  proc get_share_items {dir} {

    return [list emmet.tkedat]

  }

  ######################################################################
  # Called when the share directory changes.
  proc share_changed {dir} {

    variable custom_file

    set custom_file [file join $dir emmet.tkedat]

  }

}

