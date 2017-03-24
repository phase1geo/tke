namespace eval delete {

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
  # Runs the given deletion test.
  proc do_test {txtt id cmdlist cursor value {undo 1}} {

    set start        [$txtt get 1.0 end-1c]
    set start_cursor [$txtt index insert]

    enter $txtt $cmdlist
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id delete did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "start"} {
      cleanup "$id not in mode start"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id cursor incorrect ([$txtt index insert])"
    }

    if {$undo} {
      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne $start_cursor} {
        cleanup "undo cursor not correct ([$txtt index insert])"
      }
    }

  }

  # Verify deletion
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 x 2.0 "\nhis is a line"
    do_test $txtt 1 {2 x} 2.0 "\nis is a line"

    do_test $txtt 2 x 2.0 "\nhis is a line" 0
    do_test $txtt 3 x 2.0 "\nis is a line"

    # Cleanup
    cleanup

  }

  # Verify dd Vim command
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 {d d} 2.0 "\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d d} $index 2] 1.0 " "
    }

    do_test $txtt 3 {d d} 2.0 "\nThis is a line" 0
    do_test $txtt 4 {d d} 1.0 " "

    # Cleanup
    cleanup

  }

  # Verify dl Vim command
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {d l} 2.0 "\nhis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d l} $index 2] 2.0 "\nis is a line"
    }

    do_test $txtt 3 {d l} 2.0 "\nhis is a line" 0
    do_test $txtt 4 {d l} 2.0 "\nis is a line"

    # Cleanup
    cleanup

  }

  # Verify dvl Vim command
  proc run_test4 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {d v l} 2.0 "\nis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d v l} $index 2] 2.0 "\ns is a line"
    }

    do_test $txtt 3 {d v l} 2.0 "\nis is a line" 0
    do_test $txtt 4 {d v l} 2.0 "\n is a line"

    # Cleanup
    cleanup

  }

  # Verify dw Vim command
  proc run_test5 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.1
    vim::adjust_insert $txtt

    do_test $txtt 0 {d w} 2.1 "\nTis a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d w} $index 2] 2.1 "\nTa line"
    }

    do_test $txtt 3 {d w} 2.1 "\nTis a line" 0
    do_test $txtt 4 {d w} 2.1 "\nTa line"

    # Cleanup
    cleanup

  }

  # Verify d$ command
  proc run_test6 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line\nThis is a line\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 {d dollar} 2.4 "\nThis \nThis is a line\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d dollar} $index 2] 2.4 "\nThis \nThis is a line"
    }

    do_test $txtt 3 {d dollar} 2.4 "\nThis \nThis is a line\nThis is a line" 0
    $txtt mark set insert 3.0
    do_test $txtt 4 {d dollar} 3.0 "\nThis \n \nThis is a line"

    # Cleanup
    cleanup

  }

  # Verify d^ Vim command
  proc run_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {d asciicircum} 2.0 "\na line"

    # Cleanup
    cleanup

  }

  # Verify df Vim command
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.1
    vim::adjust_insert $txtt

    do_test $txtt 0 {d f l} 2.1 "\nTine"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d f i} $index 2] 2.1 "\nTs a line"
    }

    do_test $txtt 3 {d f i} 2.1 "\nTs is a line" 0
    do_test $txtt 4 {d f i} 2.1 "\nTs a line"

    # Cleanup
    cleanup

  }

  # Verify dt Vim command
  proc run_test9 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.1
    vim::adjust_insert $txtt

    do_test $txtt 0 {d t l} 2.1 "\nTline"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d t i} $index 2] 2.1 "\nTis a line"
    }

    do_test $txtt 3 {d t i} 2.1 "\nTis is a line" 0
    do_test $txtt 4 {d t i} 2.1 "\nTis a line"

    # Cleanup
    cleanup

  }

  # Verify dF Vim command
  proc run_test10 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {d F i} 2.5 "\nThis a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d F i} $index 2] 2.2 "\nTha line"
    }

    do_test $txtt 3 {d F i} 2.5 "\nThis a line" 0
    do_test $txtt 4 {d F i} 2.2 "\nTha line"

    # Cleanup
    cleanup

  }

  # Verify dT Vim command
  proc run_test11 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {d T i} 2.6 "\nThis ia line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d T i} $index 2] 2.3 "\nThia line"
    }

    do_test $txtt 3 {d T i} 2.6 "\nThis ia line" 0
    $txtt mark set insert 2.5
    do_test $txtt 4 {d T i} 2.3 "\nThiia line"

    # Cleanup
    cleanup

  }

  # Verify dh did not work
  proc run_test12 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {d h} 2.7 "\nThis isa line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d h} $index 2] 2.6 "\nThis ia line"
    }

    do_test $txtt 3 {d h} 2.7 "\nThis isa line" 0
    do_test $txtt 4 {d h} 2.6 "\nThis ia line"

    # Cleanup
    cleanup

  }

}
