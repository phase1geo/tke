# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2019  Trevor Williams (phase1geo@gmail.com)
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
# Name:     logger.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     5/18/2015
# Version:  $Revision$
# Brief:    Contains namespace used for debug logging.
######################################################################

namespace eval logger {

  variable logdir ""
  variable logrc  ""

  ######################################################################
  # Called at application start to initialize the debug logfile.
  proc initialize {} {

    variable logdir
    variable logrc

    # Get the logfile directory
    if {[set logdir [preferences::get Debug/LogDirectory]] eq ""} {
      set logdir [file join $::tke_home logs]
    }

    # Get the native logfile name and create the directory if it does not already exist
    if {![file exists [set logdir [file normalize $logdir]]]} {
      file mkdir $logdir
    }

    # Create the logfile
    create_logfile $logdir

    # Keep an eye on the Debug/LogDirectory preference option
    trace variable preferences::prefs(Debug/LogDirectory) w logger::handle_logdir_change

  }

  ######################################################################
  # Returns a string containing the header information.
  proc get_header {} {

    set str ""
    append str "===================================================================================\n"
    append str "TKE Diagnostic Logfile\n"
    append str "===================================================================================\n"
    append str "Version:        $::version_major.$::version_minor.$::version_point ($::version_hgid)\n"
    append str "Tcl/Tk Version: [info patchlevel]\n"
    append str "Platform:       [array get ::tcl_platform]\n"
    append str "===================================================================================\n"
    append str "\n"

    return $str

  }

  ######################################################################
  # Creates and initializes the logfile
  proc create_logfile {dir} {

    variable logdir
    variable logrc

    set logdir $dir

    if {![catch { open [file join $logdir debug.[pid].log] w } rc]} {

      # Perform line buffering
      fconfigure $rc -buffering line

      set logrc $rc

    }

  }

  ######################################################################
  # Handles any changes to the Debug/LogDirectory preference option.
  proc handle_logdir_change {name1 name2 op} {

    variable logdir
    variable logrc

    # Get the preference directory value
    if {[set pref_dir [preferences::get Debug/LogDirectory]] eq ""} {
      set pref_dir [file join $::tke_home logs]
    }

    # Normalize the preference directory
    set pref_dir [file normalize $pref_dir]

    # If the directory exists and it differs from the original, close, move and re-open the logfile
    if {$logdir ne $pref_dir} {

      # Create the directory if it does not exist
      if {![file exists $pref_dir]} {
        file mkdir $pref_dir
      }

      # If the logfile was previously opened, close it, move it and re-open for appendment
      if {$logrc ne ""} {

        # Close the logfile
        close $logrc

        # Move the logfile
        file rename -force [file join $logdir debug.[pid].log] $pref_dir

        # Reopen the logfile
        if {![catch { open [file join $pref_dir debug.[pid].log] a } rc]} {
          fconfigure $rc -buffering line
          set logrc $rc
        }

        # Set the logfile directory name to the preference name
        set logdir $pref_dir

      # Otherwise, open the logfile in the new directory for writing
      } else {

        # Create the logfile
        create_logfile $pref_dir

      }

    }

  }

  ######################################################################
  # Outputs the given string to the logfile.  Returns true if string was
  # logged without error; otherwise, returns false.
  proc log {str} {

    variable logrc

    if {$logrc ne ""} {
      puts $logrc "[clock format [clock seconds]]:  $str"
      return 1
    }

    return 0

  }

  ######################################################################
  # Makes the debug log visible within tke.
  #
  # Arguments:
  #   -lazy (0|1)  If set to 1, loads the tab in the background.  Default is 0.
  proc view_log {args} {

    variable logdir
    variable logrc

    array set opts {
      -lazy 0
    }
    array set opts $args

    # Flush the output
    if {$logrc ne ""} {
      flush $logrc
    }

    # Add the file to the editor
    gui::add_file end [file join $logdir debug.[pid].log] -readonly 1 -sidebar 0 -lazy $opts(-lazy) -remember 0

    return 1

  }

  ######################################################################
  # Returns a string containing a truncated version of the logfile.
  proc get_log {{lines 100}} {

    variable logdir

    if {![catch { open [file join $logdir debug.[pid].log] r } rc]} {

      # Create the header
      set str [get_header]

      # Add the last "lines" lines of the file to the string
      append str [join [lrange [split [read $rc] \n] end-$lines end] \n]

      return $str

    }

    return ""

  }

  ######################################################################
  # Closes the logfile on application exit.
  proc on_exit {} {

    variable logdir
    variable logrc

    if {$logrc ne ""} {

      # Close the logfile
      close $logrc

      # Get the log filename
      set logfile [file join $logdir debug.[pid].log]

      # Delete the logfile if it's empty or if we are not doing TKE development
      if {([file size $logfile] == 0) || ![::tke_development]} {
        file delete -force [file join $logdir debug.[pid].log]
      }

    }

  }

}

######################################################################
# Create the bgerror procedure to handle all background errors.
proc bgerror {str} {

  # Log the error
  if {[logger::log $str]} {
    if {$str ne ""} {
      puts stderr $::errorInfo
    }
    logger::log $::errorInfo
  } elseif {$str ne ""} {
    puts stderr $str
    puts stderr $::errorInfo
  }

}
