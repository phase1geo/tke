namespace eval change {

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

  proc do_test {txtt id cmdlist cursor value {undo 1}} {

    set start        [$txtt get 1.0 end-1c]
    set start_cursor [$txtt index insert]

    enter $txtt $cmdlist
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "$id not in edit mode"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id insertion cursor not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    if {$undo} {
      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne $start_cursor} {
        cleanup "undo insertion not correct ([$txtt get 1.0 end-1c])"
      }
    }

  }

  # Verify cc Vim command
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 {c c} 2.0 "\n\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c c} $index 2] 2.0 "\n"
    }

    do_test $txtt 3 {c c} 2.0 "\n\nThis is a line" 0
    $txtt mark set insert 3.1
    do_test $txtt 4 {c c} 3.0 "\n\n"

    # Cleanup
    cleanup

  }

  # Verify cl Vim command
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {c l} 2.0 "\nhis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c l} $index 2] 2.0 "\nis is a line"
    }

    do_test $txtt 3 {c l} 2.0 "\nhis is a line" 0
    do_test $txtt 4 {c l} 2.0 "\nis is a line"

    # Cleanup
    cleanup

  }

  # Verify cvl Vim command
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {c v l} 2.0 "\nis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c v l} $index 2] 2.0 "\ns is a line"
    }

    do_test $txtt 3 {c v l} 2.0 "\nis is a line" 0
    do_test $txtt 4 {c v l} 2.0 "\n is a line"

    # Cleanup
    cleanup

  }

  # Verify cw Vim command
  proc run_test4 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.1
    vim::adjust_insert $txtt

    do_test $txtt 0 {c w} 2.1 "\nT is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c w} $index 2] 2.1 "\nT a line"
    }

    do_test $txtt 3 {c w} 2.1 "\nT is a line" 0
    do_test $txtt 4 {c w} 2.0 "\n is a line"

    # Cleanup
    cleanup

  }

  proc run_test5 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.3
    vim::adjust_insert $txtt

    do_test $txtt 0 C 2.3 "\nThi\nThis is a line"

    do_test $txtt 1 C 2.3 "\nThi\nThis is a line" 0
    $txtt mark set insert 3.1
    do_test $txtt 2 C 3.1 "\nThi\nT"

    # Cleanup
    cleanup

  }

  # Verify c$ command
  proc tbd_test6 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 {c dollar} 2.5 "\nThis \nThis is a line\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c dollar} $index 2] 2.5 "\nThis \nThis is a line"
    }

    do_test $txtt 3 {c dollar} 2.5 "\nThis \nThis is a line\nThis is a line" 0
    $txtt mark set insert 3.1
    do_test $txtt 4 {c dollar} 3.1 "\nThis \nT\nThis is a line"

    # Cleanup
    cleanup

  }

  # Verify c^ Vim command
  proc tbd_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {c asciicircum} 2.0 "\na line\nThis is a line"

    do_test $txtt 1 {c asciicircum} 2.0 "\na line\nThis is a line" 0
    $txtt mark set insert 3.1
    do_test $txtt 2 {c asciicircum} 3.0 "\na line\nhis is a line"

    # Cleanup
    cleanup

  }

  # Verify cf Vim command
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.1
    vim::adjust_insert $txtt

    do_test $txtt 0 {c f i} 2.1 "\nTs is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c f i} $index 2] 2.1 "\nTs a line"
    }

    do_test $txtt 3 {c f i} 2.1 "\nTs is a line" 0
    do_test $txtt 4 {c f i} 2.0 "\ns a line"

    # Cleanup
    cleanup

  }

  # Verify ct Vim command
  proc run_test9 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.1
    vim::adjust_insert $txtt

    do_test $txtt 0 {c t l} 2.1 "\nTline"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c t i} $index 2] 2.1 "\nTis a line"
    }

    do_test $txtt 3 {c t i} 2.1 "\nTis is a line" 0
    do_test $txtt 4 {c t i} 2.0 "\nis is a line"

    # Cleanup
    cleanup

  }

  # Verify cF Vim command
  proc run_test10 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {c F i} 2.5 "\nThis a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c F i} $index 2] 2.2 "\nTha line"
    }

    do_test $txtt 3 {c F i} 2.5 "\nThis a line" 0
    do_test $txtt 4 {c F i} 2.2 "\nTh a line"

    # Cleanup
    cleanup

  }

  # Verify cT Vim command
  proc run_test11 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {c T i} 2.6 "\nThis ia line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c T i} $index 2] 2.3 "\nThia line"
    }

    do_test $txtt 3 {c T i} 2.6 "\nThis ia line" 0
    do_test $txtt 4 {c T i} 2.3 "\nThiia line"

    # Cleanup
    cleanup

  }

  # Verify ch Vim command
  proc run_test12 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {c h} 2.7 "\nThis isa line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c h} $index 2] 2.6 "\nThis ia line"
    }

    do_test $txtt 3 {c h} 2.7 "\nThis isa line" 0
    do_test $txtt 4 {c h} 2.5 "\nThis sa line"

    # Cleanup
    cleanup

  }

  # Verify ci Vim command
  proc run_test13 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis \\is a line"
    $txtt edit separator
    $txtt mark set insert 2.4
    vim::adjust_insert $txtt

    do_test $txtt 0 {c i i} 2.3 "\nThiine"

    # Cleanup
    cleanup

  }

  # Verify ci\{ Vim command
  proc run_test14 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nset this {is good\\\}}"
    $txtt edit separator
    $txtt mark set insert 2.12
    vim::adjust_insert $txtt

    do_test $txtt 0 {c i braceleft} 2.10 "\nset this {}"

    # Cleanup
    cleanup

  }

  # Verify ci[ Vim command
  proc run_test15 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nset this \[is good\\\]\]"
    $txtt edit separator
    $txtt mark set insert 2.12
    vim::adjust_insert $txtt

    do_test $txtt 0 {c i bracketleft} 2.10 "\nset this \[\]"

    # Cleanup
    cleanup

  }

  # Verify ci( Vim command
  proc run_test16 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nset this (is good\\))"
    $txtt edit separator
    $txtt mark set insert 2.12
    vim::adjust_insert $txtt

    do_test $txtt 0 {c i parenleft} 2.10 "\nset this ()"

    # Cleanup
    cleanup

  }

  # Verify ci< Vim command
  proc run_test17 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nset this <is good\\>>"
    $txtt edit separator
    $txtt mark set insert 2.12
    vim::adjust_insert $txtt

    do_test $txtt 0 {c i less} 2.10 "\nset this <>"

    # Cleanup
    cleanup

  }

}
