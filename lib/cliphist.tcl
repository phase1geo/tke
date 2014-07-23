######################################################################
# Name:    cliphist.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    05/21/2013
# Brief:   Handles clipboard history.
######################################################################

namespace eval cliphist {

  source [file join $::tke_dir lib ns.tcl]

  variable cliphist_file [file join $::tke_home cliphist.dat]
  variable hist          {}
  variable hist_maxsize  10

  ######################################################################
  # Load the contents of the saved clipboard history.
  proc load {} {

    variable cliphist_file
    variable hist

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
          lappend hist $clipping
        }
      }
      
    }

  }

  ######################################################################
  # Saves the state of the clipboard history to a file.  This is called
  # prior to exiting the application.
  proc save {} {

    variable cliphist_file
    variable hist

    if {![catch "open $cliphist_file w" rc]} {
      foreach clipping $hist {
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

    variable hist
    variable hist_maxsize

    # Get the clipboard content
    set str [string map {\{ \\\{} [clipboard get]]

    if {[string trim $str] ne ""} {
          
      # If the string doesn't exist in history, add it
      if {[set index [lsearch -exact $hist $str]] == -1} {

        # Append the string to the history file
        lappend hist $str
      
        # Trim the history to meet the maxsize requirement, if necessary
        if {[llength $hist] > $hist_maxsize} {
          set hist [lrange $hist 1 end]
        }

      # Otherwise, move the current string to the beginning of the history
      } else {

        set hist [linsert [lreplace $hist $index $index] end $str]
          
      }
          
    }

  }
  
  ######################################################################
  # Adds the given string to the text widget.
  proc add_detail {str txt} {
    
    $txt insert end $str
    
  }

  ######################################################################
  # Adds the current string from the clipboard history list to the clipboard
  # and immediately adds the string to the current text widget, formatting
  # the text.
  proc add_to_clipboard {str} {

    # Add the string to the clipboard
    clipboard clear
    clipboard append [string map {\\\{ \{} $str]

    # Insert the string in the current text widget
    gui::paste_and_format {}

  }
  
  ######################################################################
  # Returns the clipboard history as a list of string pairs where the
  # first item is the value to use in the listbox while the second pair
  # should be used in the full detail.
  proc get_history {} {
    
    variable hist
            
    set items [list]
            
    foreach item [lreverse $hist] {
      set lines [split $item \n]
      set short [lindex $lines 0]
      if {[llength $lines] > 1} {
        append short "  ..."
      }
      lappend items [list [string map {\\\{ \{} $short] [string map {\\\{ \{} $item]]
    }
                    
    return $items
    
  }
  
  ######################################################################
  # Creates a launcher window that contains clipboard history with a preview.
  proc show_cliphist {} {
    
    variable hist
    
    # Add temporary registries to launcher
    set i 0
    foreach strs [get_history] {
      lassign $strs name str
      launcher::register_temp "`CLIPHIST:$name" [list cliphist::add_to_clipboard $str] $name $i [list cliphist::add_detail $str]
      incr i
    }
    
    # Display the launcher in CLIPHIST: mode
    launcher::launch "`CLIPHIST:" 1
    
  }
  
  ######################################################################
  # Debugging procedure.
  proc printable_hist {} {
    
    variable hist
    
    return [format {  -%s } [join $hist "\n  -"]]
    
  }
  
}

