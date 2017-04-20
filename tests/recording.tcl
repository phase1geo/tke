namespace eval recording {

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
  # Execute a Vim test.
  proc do_test {txtt id cmdlist reg events} {

    enter $txtt $cmdlist

    if {$cmdlist eq {q}} {
      set mode "none"
    } else {
      set mode "record"
    }

    if {$vim::recording(mode) ne $mode} {
      cleanup "$id recording mode is not record ($vim::recording(mode))"
    }
    if {$vim::recording(curr_reg) ne $reg} {
      cleanup "$id recording reg is incorrect ($vim::recording(curr_reg))"
    }
    if {$vim::recording($reg,events) ne $events} {
      cleanup "$id recording reg $reg events is incorrect ($vim::recording($reg,events))"
    }

  }

  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    do_test $txtt 0 {q a} a {}
    do_test $txtt 1 {i n i c e Escape} a {}
    do_test $txtt 2 {o g o o d Escape} a {}
    do_test $txtt 3 {q} a {i n i c e Escape o g o o d Escape}

    # Cleanup
    cleanup

  }

}
