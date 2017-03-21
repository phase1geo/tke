namespace eval yank {

  ######################################################################
  # Common diagnostic initialization procedure.  Returns the pathname
  # to the added text widget.
  proc initialize {} {

    variable current_tab

    # Add a new file
    set current_tab [gui::add_new_file end]

    # Get the text widget
    set txt [gui::get_info $current_tab tab txt]

    # Set the current syntax to Tcl
    syntax::set_language $txt Tcl

    return $txt.t

  }

  ######################################################################
  # Common cleanup procedure.  If a fail message is provided, return an
  # error with the given error message.
  proc cleanup {{fail_msg ""}} {

    variable current_tab

    # Close the current tab
    gui::close_tab $current_tab -check 0

    # Output the fail message and cause a failure
    if {$fail_msg ne ""} {
      return -code error $fail_msg
    }

  }

  ######################################################################
  # Emulates a Vim keystroke.
  proc enter {txtt keysyms} {

    foreach keysym $keysyms {
      if {$keysym eq "Escape"} {
        vim::handle_escape $txtt
      } else {
        set char [utils::sym2char $keysym]
        if {![vim::handle_any $txtt [utils::sym2code $keysym] $char $keysym]} {
          $txtt insert insert $char
        }
      }
    }

  }

  # Verify yy Vim command
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line\nThis is a line"]
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    enter $txtt {y y}


    foreach index {0 1} {

      clipboard clear

      enter $txtt [linsert {y y} $index 2]
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "2 yank changed text ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "start"} {
        cleanup "2 not in start mode"
      }
      if {[$txtt index insert] ne "2.5"} {
        cleanup "2 yank changed cursor ([$txtt index insert])"
      }
      if {[clipboard get] ne "This is a line\nThis is a line\n"} {
        cleanup "2 clipboard not correct ([clipboard get])"
      }

    }

    # Cleanup
    cleanup

  }

  # yl, yh, yf, yt, yF, yT, yw, yspace, yBackSpace

}
