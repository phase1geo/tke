namespace eval find {

  variable current_tab

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
  # Run a Vim test.
  proc do_test {txtt id cmdlist data tags cursor} {

    set str [$txtt get 1.0 end-1c]

    enter $txtt $cmdlist

    if {([lsearch $cmdlist slash] != -1) || ([lsearch $cmdlist question] != -1)} {
      gui::set_search_data "find" $data
      eval [bind [gui::current_search] <Return>]
    }

    if {[$txtt get 1.0 end-1c] ne $str} {
      cleanup "$id text changed ([$txtt get 1.0 end-1c])"
    }
    if {[$txtt tag ranges _search] ne $tags} {
      cleanup "$id search tags incorrect ([$txtt tag ranges _search])"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id insertion cursor incorrect ([$txtt index insert])"
    }

  }

  # Verify / Vim search command
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line.\nThis is a line.\nThis is a line."
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {slash} {"line" 1 0} {2.10 2.14 3.10 3.14 4.10 4.14} {2.10}

    do_test $txtt 1 {n} {} {2.10 2.14 3.10 3.14 4.10 4.14} {3.10}
    do_test $txtt 2 {n} {} {2.10 2.14 3.10 3.14 4.10 4.14} {4.10}
    do_test $txtt 3 {n} {} {2.10 2.14 3.10 3.14 4.10 4.14} {2.10}

    do_test $txtt 4 {N} {} {2.10 2.14 3.10 3.14 4.10 4.14} {4.10}
    do_test $txtt 5 {N} {} {2.10 2.14 3.10 3.14 4.10 4.14} {3.10}
    do_test $txtt 6 {N} {} {2.10 2.14 3.10 3.14 4.10 4.14} {2.10}

    # Cleanup
    cleanup

  }

  # Verify ? Vim search command
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line.\nThis is a line.\nThis is a line."
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {question} {"this" 0 0} {2.0 2.4 3.0 3.4 4.0 4.4} {4.0}

    do_test $txtt 1 {n} {} {2.0 2.4 3.0 3.4 4.0 4.4} {3.0}
    do_test $txtt 2 {n} {} {2.0 2.4 3.0 3.4 4.0 4.4} {2.0}
    do_test $txtt 3 {n} {} {2.0 2.4 3.0 3.4 4.0 4.4} {4.0}

    do_test $txtt 4 {N} {} {2.0 2.4 3.0 3.4 4.0 4.4} {2.0}
    do_test $txtt 5 {N} {} {2.0 2.4 3.0 3.4 4.0 4.4} {3.0}
    do_test $txtt 6 {N} {} {2.0 2.4 3.0 3.4 4.0 4.4} {4.0}

    # Cleanup
    cleanup

  }

  # Verify * Vim search
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line.\nThis is a line.\nThis is a line."
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 {asterisk} {} {2.5 2.7 3.5 3.7 4.5 4.7} {2.5}

    do_test $txtt 1 {n} {} {2.5 2.7 3.5 3.7 4.5 4.7} {3.5}
    do_test $txtt 2 {n} {} {2.5 2.7 3.5 3.7 4.5 4.7} {4.5}
    do_test $txtt 3 {n} {} {2.5 2.7 3.5 3.7 4.5 4.7} {2.5}

    do_test $txtt 4 {N} {} {2.5 2.7 3.5 3.7 4.5 4.7} {4.5}
    do_test $txtt 5 {N} {} {2.5 2.7 3.5 3.7 4.5 4.7} {3.5}
    do_test $txtt 6 {N} {} {2.5 2.7 3.5 3.7 4.5 4.7} {2.5}

    # Cleanup
    cleanup

  }

}
