######################################################################
# Name:    cliphist.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    05/21/2013
# Brief:   Handles clipboard history.
######################################################################

namespace eval cliphist {

  source [file join $::tke_dir lib ns.tcl]

  variable cliphist_file   [file join $::tke_home cliphist.dat]
  variable history         {}
  variable history_maxsize 10

  ######################################################################
  # Load the contents of the saved clipboard history.
  proc load {} {

    variable cliphist_file
    variable history

    if {![catch "open $cliphist_file r" rc]} {

      # Read the contents of the file
      set contents [read $rc]
      close $rc

      # Parse the file
      set in_history 0
      foreach line [split $contents \n] {
        if {$line eq "clipping:"} {
          set in_history 1
          set clipping   ""
        } elseif {$in_history && [regexp {^\t(.*)$} $line -> str]} {
          append clipping "$str\n"
        } elseif {$in_history} {
          set clipping   [string range $clipping 0 end-1]
          set in_history 0
          lappend history $clipping
          set name [string range [lindex [split $clipping \n] 0] 0 30]
          launcher::register_temp "!$name" [list cliphist::add_to_clipboard $clipping] $name
        }
      }
      
    }

  }

  ######################################################################
  # Saves the state of the clipboard history to a file.  This is called
  # prior to exiting the application.
  proc save {} {

    variable cliphist_file
    variable history

    if {![catch "open $cliphist_file w" rc]} {
      foreach clipping $history {
        puts $rc "clipping:"
        foreach line [split $clipping \n] {
          puts $rc "\t$line"
        }
        puts $rc ""
      }
      close $rc
    }

  }

  ######################################################################
  # Adds the current clipboard contents to the clipboard history list.
  proc add_from_clipboard {} {

    variable history
    variable history_maxsize

    # Get the clipboard content
    set str [clipboard get]

    # If the string doesn't exist in history, add it
    if {[set index [lsearch $history $str]] == -1} {

      # Append the string to the history file
      lappend history $str

      # Register the clipping to the launcher
      set name [string range [lindex [split $str \n] 0] 0 30]
      launcher::register_temp "!$name" [list cliphist::add_to_clipboard $str] $name

      # Trim the history to meet the maxsize requirement, if necessary
      if {[llength $history] > $history_maxsize} {
        launcher::unregister "![string range [lindex [split [lindex $history 0] \n] 0] 0 30]"
        set history [lrange $history 1 end]
      }

    # Otherwise, move the current string to the beginning of the history
    } else {

      set history [linsert [lreplace $history $index $index] 0 $str]

    }

  }

  ######################################################################
  # Adds the current string from the clipboard history list to the clipboard
  # and immediately adds the string to the current text widget, formatting
  # the text.
  proc add_to_clipboard {str} {

    # Add the string to the clipboard
    clipboard clear
    clipboard append $str

    # Insert the string in the current text widget
    gui::paste_and_format {}

  }
  
}

