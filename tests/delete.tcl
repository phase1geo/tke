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
        cleanup "$id undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne $start_cursor} {
        cleanup "$id undo cursor not correct ([$txtt index insert])"
      }
    }

  }

  # Verify x Vim command
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

    do_test $txtt 5 {d V l} 2.0 "\n "

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

  # Verify d0 Vim command
  proc run_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\n  This is a line"
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {d 0} 2.0 "\ns a line"

    # Cleanup
    cleanup

  }

  # Verify d^ Vim command
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\n  This is a line\n This is a line"
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    do_test $txtt 0 {d asciicircum} 2.2 "\n  s a line\n This is a line"

    do_test $txtt 1 {d asciicircum} 2.2 "\n  s a line\n This is a line" 0
    $txtt mark set insert 3.7
    do_test $txtt 2 {d asciicircum} 3.1 "\n  s a line\n s a line"

    # Cleanup
    cleanup

  }

  # Verify df Vim command
  proc run_test9 {} {

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
  proc run_test10 {} {

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
  proc run_test11 {} {

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
  proc run_test12 {} {

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

  # Verify dh Vim command
  proc run_test13 {} {

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

    do_test $txtt 3 {d v h} 2.7 "\nThis is line"
    do_test $txtt 4 {d V h} 2.0 "\n "

    do_test $txtt 5 {d h} 2.7 "\nThis isa line" 0
    do_test $txtt 6 {d h} 2.6 "\nThis ia line"

    # Cleanup
    cleanup

  }

  # Verify dSpace Vim command
  proc run_test14 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {d space} 2.0 "\nhis is a line\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d space} $index 2] 2.0 "\nis is a line\nThis is a line"
    }

    $txtt mark set insert 2.13
    do_test $txtt 3 {2 d space} 2.13 "\nThis is a linThis is a line"

    $txtt mark set insert 2.2
    do_test $txtt 4 {d v space} 2.2 "\nTh is a line\nThis is a line"
    do_test $txtt 5 {d V space} 2.0 "\n \nThis is a line"

    # Cleanup
    cleanup

  }

  # Verify dBackSpace Vim command
  proc run_test15 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 {d BackSpace} 2.4 "\nThisis a line\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d BackSpace} $index 2] 2.3 "\nThiis a line\nThis is a line"
    }

    $txtt mark set insert 3.1
    do_test $txtt 3 {3 d BackSpace} 2.13 "\nThis is a linhis is a line"

    do_test $txtt 4 {d v BackSpace} 3.0 "\nThis is a line\nis is a line"
    do_test $txtt 5 {d V BackSpace} 3.0 "\nThis is a line\n "

    # Cleanup
    cleanup

  }

  # Verify dn Vim command
  proc run_test16 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line 1000x"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {d n} 2.0 "\nThis is line 1000x" 0

    $txtt mark set insert 2.13
    do_test $txtt 1 {d n} 2.13 "\nThis is line x"

    $txtt mark set insert 2.14
    do_test $txtt 2 {d n} 2.14 "\nThis is line 1x"

    do_test $txtt 3 {d n} 2.14 "\nThis is line 1x" 0
    $txtt mark set insert 2.13
    do_test $txtt 4 {d n} 2.13 "\nThis is line x"

    # Cleanup
    cleanup

  }

  # Verify dN Vim command
  proc run_test17 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line 1000x"
    $txtt edit separator
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 {d N} 2.5 "\nThis is line 1000x" 0

    $txtt mark set insert 2.17
    do_test $txtt 1 {d N} 2.13 "\nThis is line x"

    $txtt mark set insert 2.16
    do_test $txtt 2 {d N} 2.13 "\nThis is line 0x"

    do_test $txtt 3 {d N} 2.13 "\nThis is line 0x" 0
    $txtt mark set insert 2.14
    do_test $txtt 4 {d N} 2.13 "\nThis is line x"

    # Cleanup
    cleanup

  }

  # Verify ds Vim command
  proc run_test18 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line    x"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {d s} 2.0 "\nThis is line    x" 0

    $txtt mark set insert 2.13
    do_test $txtt 1 {d s} 2.13 "\nThis is line x"

    do_test $txtt 2 {d s} 2.13 "\nThis is line x" 0
    $txtt mark set insert 2.12
    do_test $txtt 3 {d s} 2.12 "\nThis is linex"

    $txtt delete 1.0 end
    $txtt insert end "\nThis is line    "
    $txtt edit separator
    $txtt mark set insert 2.12
    vim::adjust_insert $txtt

    do_test $txtt 4 {d s} 2.11 "\nThis is line"

    # Cleanup
    cleanup

  }

  # Verify dS Vim command
  proc run_test19 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line    x"
    $txtt edit separator
    $txtt mark set insert 2.3
    vim::adjust_insert $txtt

    do_test $txtt 0 {d S} 2.3 "\nThis is line    x" 0

    $txtt mark set insert 2.15
    do_test $txtt 1 {d S} 2.12 "\nThis is line x"

    do_test $txtt 2 {d S} 2.12 "\nThis is line x" 0
    $txtt mark set insert 2.13
    do_test $txtt 3 {d S} 2.12 "\nThis is linex"

    # Cleanup
    cleanup

  }

}
