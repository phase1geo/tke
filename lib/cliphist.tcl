namespace eval cliphist {

  variable cliphist_file   [file join $::tke_home cliphist.dat]
  variable history         {}
  variable history_maxsize 10

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
          append clipping $str
        } elseif {$in_history} {
          lappend history $clipping
          set in_history 0
        }
      }
      
    }

  }

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

  proc add_from_clipboard {str} {

    variable history
    variable history_maxsize

    # If the string doesn't exist in history, add it
    if {[set index [lsearch $history $str]] == -1} {

      # Append the string to the history file
      lappend history $str

      # Register the clipping to the launcher
      set name [string range [lindex [split $str \n] 0] 0 30]
      launcher::register_temp "!$name" [list cliphist::add_to_clipboard $str]

      # Trim the history to meet the maxsize requirement, if necessary
      if {[llength $history] > $history_max_size} {
        launcher::unregister "![string range [lindex [split [lindex $history 0] \n] 0] 0 30]"
        set history [lrange $history 1 end]
      }

    # Otherwise, move the current string to the beginning of the history
    } else {

      set history [linsert [lreplace $history $index $index] 0 $str]

    }

  }

  proc add_to_clipboard {str} {

    # Add the string to the clipboard
    clipboard::clear
    clipboard::append $str

    # Insert the string in the current text widget
    [gui::paste_and_format]

  }

}

