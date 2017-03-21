namespace eval transform {

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

  ######################################################################
  # Perform the yank test (reusable code)
  proc do_test {txtt id cmdlist cursor value} {

    # Record the initial text so that we can verify undo
    set start        [$txtt get 1.0 end-1c]
    set start_cursor [$txtt index insert]

    enter $txtt $cmdlist
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id transform is not correct ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "start"} {
      cleanup "$id not in start mode"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id transform did not change cursor ([$txtt index insert])"
    }

    enter $txtt u
    if {[$txtt get 1.0 end-1c] ne $start} {
      cleanup "$id undo did not work ([$txtt get 1.0 end-1c])"
    }
    if {[$txtt index insert] ne $start_cursor} {
      cleanup "$id undo cursor not correct ([$txtt index insert])"
    }

  }

  # Verify ~ Vim command
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {asciitilde} 2.1 "\nthis is a line"
    do_test $txtt 1 {2 asciitilde} 2.2 "\ntHis is a line"

    # Cleanup
    cleanup

  }

}
