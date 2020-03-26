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
  proc do_test {txtt id cmdlist reg mode events} {

    enter $txtt $cmdlist

    if {$vim::recording(mode) ne $mode} {
      cleanup "$id recording mode is not record ($vim::recording(mode))"
    }
    if {$vim::recording(curr_reg) ne $reg} {
      cleanup "$id recording reg is incorrect ($vim::recording(curr_reg))"
    }
    set event_key [expr {($reg eq "") ? "events" : "$reg,events"}]
    if {$vim::recording($event_key) ne $events} {
      cleanup "$id recording reg ($reg) events is incorrect ($vim::recording($event_key))"
    }

  }

  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    do_test $txtt 0 {q a} a record {}
    do_test $txtt 1 {i n i c e Escape} a none {i n i c e Escape}
    do_test $txtt 2 {o g o o d Escape} a none {i n i c e Escape o g o o d Escape}
    do_test $txtt 3 {q} "" none {o g o o d Escape}

    do_test $txtt 4 {q q} q record {}
    do_test $txtt 5 {i g o Escape} q none {i g o Escape}
    do_test $txtt 6 {O n o Escape} q none {i g o Escape O n o Escape}
    do_test $txtt 7 {q} "" none {O n o Escape}

    do_test $txtt 8 {i f o o Escape} "" none {i f o o Escape}

    # Cleanup
    cleanup

  }

  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [string repeat "\nThis is a line" 6]
    $txtt cursor set 2.0

    do_test $txtt 0 {2 d d} "" none {d d}

    if {$vim::recording(num) != 2} {
      cleanup "0 recording num incorrect ($vim::recording(num))"
    }

    do_test $txtt 1 {3 d 2 l} "" none {d 2 l}

    if {$vim::recording(num) != 3} {
      cleanup "1 recording num incorrect ($vim::recording(num))"
    }

    # Cleanup
    cleanup

  }

}
