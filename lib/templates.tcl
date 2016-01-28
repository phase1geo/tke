# TKE - Advanced Programmer's Editor
# Copyright (C) 2014  Trevor Williams (phase1geo@gmail.com)
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
# Name:    templates.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    12/24/2015
# Brief:   Namespace handling file templates.
######################################################################

namespace eval templates {

  source [file join $::tke_dir lib ns.tcl]

  array set data {}

  ######################################################################
  # Loads the contents of the templates directory.
  proc preload {} {

    variable data

    # Clear the data array
    catch { array unset data }

    # Create the template directory
    set data(templates_dir) [file join $::tke_home templates]
    set data(templates)     [glob -nocomplain -tails -directory $data(templates_dir) *]

  }

  ######################################################################
  # Loads the contents of the specified template into a new buffer and
  # perform the snippet insertion.
  proc load {name fname} {

    variable data

    # Open the template file for reading
    if {[catch { open [get_pathname $name] r } rc]} {
      return -code error "Unable to read template $name"
    }

    # Get the template contents
    set contents [read $rc]
    close $rc

    # Add the buffer
    set txt [[ns gui]::get_info [[ns gui]::add_new_file end -name $fname] tab txt]

    # Insert the content as a snippet
    [ns snippets]::insert_snippet $txt.t $contents

    # Take the extension of the template file (if there is one) and set the
    # current syntax highlighting to it
    [ns syntax]::set_language $txt [[ns syntax]::get_default_language $name]

  }

  ######################################################################
  # Opens a TK save dialog box to specify the filename to save.
  proc load_abs {name args} {

    # Get the filename from the user
    if {[set fname [tk_getSaveFile -parent . -confirmoverwrite 1 -title "New Filepath"]] ne ""} {
      load $name $fname
    }

  }

  ######################################################################
  # Displays the user input field to get the basename of the file to
  # create.
  proc load_rel {name args} {

    set fname ""

    if {[[ns gui]::get_user_response "File Name:" fname]} {

      # Normalize the pathname
      if {[file pathtype $fname] eq "relative"} {
        set fname [file normalize [file join [lindex $args 0] $fname]]
      }

      # Load the template
      load $name $fname

    }

  }

  ######################################################################
  # Allows the user to edit the template.
  proc edit {name args} {

    variable data

    # Add the file for editing (but don't display the other themes in the sidebar
    [ns gui]::add_file end [get_pathname $name] -sidebar 0

  }

  ######################################################################
  # Allows the user to specify the name of the template to save.
  proc save_as {} {

    variable data

    set name ""

    # Get the template name from the user
    if {[[ns gui]::get_user_response [format "%s:" [msgcat::mc "Template Name"]] name 0]} {

      # Create the templates directory if it does not exist
      file mkdir $data(templates_dir)

      # Open the file for writing
      if {[catch { open [get_pathname $name] w } rc]} {
        return -code error "Unable to open template $name for writing"
      }

      # Write the file contents
      puts $rc [[ns gui]::scrub_text [gui::current_txt {}]]
      close $rc

      # Add the file to our list if it does not already exist
      if {[lsearch $data(templates) $name] == -1} {
        lappend data(templates) $name
      }

      # Specify that the file was saved in the information bar
      [ns gui]::set_info_message [format "%s $name %s" [msgcat::mc "Template"] [msgcat::mc "saved"]]

    }

  }

  ######################################################################
  # Deletes the given template.
  proc delete {name args} {

    variable data

    # Delete the file
    if {[catch { file delete -force [get_pathname $name] } rc]} {
      delete -code error "Unable to delete template"
    }

    # Remove the template from the list
    if {[set index [lsearch $data(templates) $name]] != -1} {
      set data(templates) [lreplace $data(templates) $index $index]
    }

    # Specify that the file was deleted in the information bar
    [ns gui]::set_info_message [format "%s $name %s" [msgcat::mc "Template"] [msgcat::mc "deleted"]]

  }

  ######################################################################
  # Returns true if we have at least one template available.
  proc valid {} {

    variable data

    return [expr [llength $data(templates)] > 0]

  }

  ######################################################################
  # Returns the full pathname of the given template name.
  proc get_pathname {name} {

    variable data

    return [file join $data(templates_dir) $name]

  }

  ######################################################################
  # Displays the templates in the command launcher.  If one is selected,
  # performs the specified command based on type.
  #
  # Legal values for cmd_type are:
  #   - load_abs
  #   - load_rel
  #   - edit
  #   - delete
  proc show_templates {cmd_type args} {

    variable data

    # Add temporary registries to launcher
    set i 0
    foreach name [lsort $data(templates)] {
      launcher::register_temp "`TEMPLATE:$name" [list [ns templates]::$cmd_type $name {*}$args] $name $i [list [ns templates]::add_detail $name]
      incr i
    }

    # Display the launcher in SNIPPET: mode
    launcher::launch "`TEMPLATE:" 1

  }

  ######################################################################
  # Returns the contents of the given file.
  proc add_detail {name txt} {

    if {[catch { open [get_pathname $name] r } rc]} {
      return ""
    }

    $txt insert end [read $rc]
    close $rc

  }

}
