namespace eval change {

  variable current_tab

  ######################################################################
  # Outputs the given string such that blank space is shown
  proc ostr {str} {
    return [string map {\n .\n} $str]
  }

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
          $txtt insert cursor $char
        }
      }
    }

  }

  ######################################################################
  # Runs the given change test.
  proc do_test {txtt id cmdlist cursor value {undo 1}} {

    set start         [$txtt get 1.0 end-1c]
    set start_cursor  [$txtt index insert]
    set record_num    ""
    set record_events [list]

    clipboard clear
    clipboard append "FOOBAR"

    enter $txtt $cmdlist

    # Figure out the recording information
    foreach cmd $cmdlist {
      if {([llength $record_events] == 0) && [string is integer $cmd]} {
        append record_num $cmd
      } else {
        lappend record_events $cmd
      }
    }

    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id change did not work ([ostr [$txtt get 1.0 end-1c]])\n([ostr $value])"
    }
    switch [lindex $cmdlist 0] {
      "r"     {
        set mode    "command"
        set recmode "none"
      }
      "R"     {
        set mode    "replace_all"
        set recmode "record"
      }
      default {
        set mode    "edit"
        set recmode "record"
      }
    }
    if {$vim::mode($txtt) ne $mode} {
      cleanup "$id not in $mode mode ($vim::mode($txtt))"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id insertion cursor not correct ([$txtt index insert])"
    }
    if {[clipboard get] ne "FOOBAR"} {
      cleanup "$id clipboard was incorrect ([clipboard get])"
    }
    if {$vim::recording(mode) ne $recmode} {
      cleanup "$id recording mode is incorrect ($vim::recording(mode))"
    }
    if {$vim::recording(num) ne $record_num} {
      cleanup "$id recording num is incorrect ($vim::recording(num))"
    }
    if {$vim::recording(events) ne $record_events} {
      cleanup "$id recording events are incorrect ($vim::recording(events))"
    }

    enter $txtt Escape

    if {$undo} {
      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "$id undo did not work ([ostr [$txtt get 1.0 end-1c]])([ostr $start])"
      }
      if {[$txtt index insert] ne $start_cursor} {
        cleanup "$id undo insertion not correct ([$txtt index insert])"
      }
    }

  }

  # Verify r Vim command
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {r M} 2.0 "\nMhis is a line"

    # Cleanup
    cleanup

  }

  # Verify R Vim command
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {R M a r k} 2.4 "\nMark is a line\nThis is a line"

    # Cleanup
    cleanup

  }

  # Verify cc Vim command
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.5

    do_test $txtt 0 {c c} 2.0 "\n\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c c} $index 2] 2.0 "\n"
    }

    do_test $txtt 3 {c c} 2.0 "\n\nThis is a line" 0
    $txtt cursor set 3.1
    do_test $txtt 4 {c c} 3.0 "\n\n"

    # Cleanup
    cleanup

  }

  # Verify cl Vim command
  proc run_test4 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

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
  proc run_test5 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {c v l} 2.0 "\nis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c v l} $index 2] 2.0 "\ns is a line"
    }

    do_test $txtt 3 {c v l} 2.0 "\nis is a line" 0
    do_test $txtt 4 {c v l} 2.0 "\n is a line"

    do_test $txtt 5 {c V l} 2.0 "\n"

    # Cleanup
    cleanup

  }

  # Verify cw Vim command
  proc run_test6 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.1

    do_test $txtt 0 {c w} 2.1 "\nT is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c w} $index 2] 2.1 "\nT a line"
    }

    do_test $txtt 3 {c w} 2.1 "\nT is a line" 0
    do_test $txtt 4 {c w} 2.0 "\n is a line"

    # Cleanup
    cleanup

  }

  # Verify C Vim command
  proc run_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.3

    do_test $txtt 0 C 2.3 "\nThi\nThis is a line"

    do_test $txtt 1 C 2.3 "\nThi\nThis is a line" 0
    $txtt cursor set 3.1
    do_test $txtt 2 C 3.1 "\nThi\nT"

    # Cleanup
    cleanup

  }

  # Verify c$ command
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.5

    do_test $txtt 0 {c dollar} 2.5 "\nThis \nThis is a line\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c dollar} $index 2] 2.5 "\nThis \nThis is a line"
    }

    do_test $txtt 3 {c dollar} 2.5 "\nThis \nThis is a line\nThis is a line" 0
    $txtt cursor set 3.1
    do_test $txtt 4 {c dollar} 3.1 "\nThis \nT\nThis is a line"

    # Cleanup
    cleanup

  }

  # Verify c0 Vim command
  proc run_test9 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.8

    do_test $txtt 0 {c 0} 2.0 "\na line\nThis is a line"

    do_test $txtt 1 {c 0} 2.0 "\na line\nThis is a line" 0
    $txtt cursor set 3.1
    do_test $txtt 2 {c 0} 3.0 "\na line\nhis is a line"

    # Cleanup
    cleanup

  }

  # Verify c^ Vim command
  proc run_test10 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\n  This is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {c asciicircum} 2.0 "\nThis is a line\nThis is a line"
    $txtt cursor set 2.2
    do_test $txtt 1 {c asciicircum} 2.2 "\n  This is a line\nThis is a line" 0
    $txtt cursor set 2.8
    do_test $txtt 2 {c asciicircum} 2.2 "\n  s a line\nThis is a line"

    do_test $txtt 3 {c asciicircum} 2.2 "\n  s a line\nThis is a line" 0
    $txtt cursor set 3.1
    do_test $txtt 4 {c asciicircum} 3.0 "\n  s a line\nhis is a line"

    $txtt delete 1.0 end
    $txtt insert end "\n  \nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.1

    do_test $txtt 5 {c asciicircum} 2.1 "\n \nThis is a line"

    # Cleanup
    cleanup

  }

  # Verify cf Vim command
  proc run_test11 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.1

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
  proc run_test12 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.1

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
  proc run_test13 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.8

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
  proc run_test14 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.8

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
  proc run_test15 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.8

    do_test $txtt 0 {c h} 2.7 "\nThis isa line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c h} $index 2] 2.6 "\nThis ia line"
    }

    do_test $txtt 3 {c h} 2.7 "\nThis isa line" 0
    do_test $txtt 4 {c h} 2.5 "\nThis sa line"

    do_test $txtt 5 {c v h} 2.5 "\nThis a line"
    do_test $txtt 6 {c V h} 2.0 "\n"

    # Cleanup
    cleanup

  }

  # Verify ci\{ Vim command
  proc run_test17 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nset this {is good\\\}}"
    $txtt edit separator
    $txtt cursor set 2.12

    do_test $txtt 0 {c i braceleft} 2.10 "\nset this {}"

    # Cleanup
    cleanup

  }

  # Verify ci[ Vim command
  proc run_test18 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nset this \[is good\\\]\]"
    $txtt edit separator
    $txtt cursor set 2.12

    do_test $txtt 0 {c i bracketleft} 2.10 "\nset this \[\]"

    # Cleanup
    cleanup

  }

  # Verify ci( Vim command
  proc run_test19 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nset this (is good\\))"
    $txtt edit separator
    $txtt cursor set 2.12

    do_test $txtt 0 {c i parenleft} 2.10 "\nset this ()"

    # Cleanup
    cleanup

  }

  # Verify ci< Vim command
  proc run_test20 {} {

    # Initialize
    set txtt [initialize]

    syntax::set_language [winfo parent $txtt] "HTML"

    $txtt insert end "\nset this <is good\\>>"
    $txtt edit separator
    $txtt cursor set 2.12

    do_test $txtt 0 {c i less} 2.10 "\nset this <>"

    # Cleanup
    cleanup

  }

  # Verify cSpace Vim command
  proc run_test21 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {c space} 2.0 "\nhis is a line\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c space} $index 2] 2.0 "\nis is a line\nThis is a line"
    }

    $txtt cursor set 2.13
    do_test $txtt 3 {2 c space} 2.13 "\nThis is a linThis is a line"

    $txtt cursor set 2.2
    do_test $txtt 4 {c v space} 2.2 "\nTh is a line\nThis is a line"
    do_test $txtt 5 {c V space} 2.0 "\n\nThis is a line"

    # Cleanup
    cleanup

  }

  # Verify cBackSpace Vim command
  proc run_test22 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.5

    do_test $txtt 0 {c BackSpace} 2.4 "\nThisis a line\nThis is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {c BackSpace} $index 2] 2.3 "\nThiis a line\nThis is a line"
    }

    $txtt cursor set 3.1
    do_test $txtt 3 {3 c BackSpace} 2.13 "\nThis is a linhis is a line"

    do_test $txtt 4 {c v BackSpace} 3.0 "\nThis is a line\nis is a line"
    do_test $txtt 5 {c V BackSpace} 3.0 "\nThis is a line\n"

    # Cleanup
    cleanup

  }

  # Verify cn Vim command
  proc run_test23 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line 1000x"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {c n} 2.0 "\nThis is line 1000x" 0

    $txtt cursor set 2.13
    do_test $txtt 1 {c n} 2.13 "\nThis is line x"

    $txtt cursor set 2.14
    do_test $txtt 2 {c n} 2.14 "\nThis is line 1x"

    do_test $txtt 3 {c n} 2.14 "\nThis is line 1x" 0
    $txtt cursor set 2.13
    do_test $txtt 4 {c n} 2.13 "\nThis is line x"

    # Cleanup
    cleanup

  }

  # Verify cN Vim command
  proc run_test24 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line 1000x"
    $txtt edit separator
    $txtt cursor set 2.5

    do_test $txtt 0 {c N} 2.5 "\nThis is line 1000x" 0

    $txtt cursor set 2.17
    do_test $txtt 1 {c N} 2.13 "\nThis is line x"

    $txtt cursor set 2.16
    do_test $txtt 2 {c N} 2.13 "\nThis is line 0x"

    do_test $txtt 3 {c N} 2.13 "\nThis is line 0x" 0
    $txtt cursor set 2.14
    do_test $txtt 4 {c N} 2.13 "\nThis is line x"

    # Cleanup
    cleanup

  }

  # Verify cs Vim command
  proc run_test25 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line    x"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {c s} 2.0 "\nThis is line    x" 0

    $txtt cursor set 2.13
    do_test $txtt 1 {c s} 2.13 "\nThis is line x"

    do_test $txtt 2 {c s} 2.13 "\nThis is line x" 0
    $txtt cursor set 2.12
    do_test $txtt 3 {c s} 2.12 "\nThis is linex"

    $txtt delete 1.0 end
    $txtt insert end "\nThis is line    "
    $txtt edit separator
    $txtt cursor set 2.12

    do_test $txtt 4 {c s} 2.12 "\nThis is line"

    # Cleanup
    cleanup

  }

  # Verify cS Vim command
  proc run_test26 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line    x"
    $txtt edit separator
    $txtt cursor set 2.3

    do_test $txtt 0 {c S} 2.3 "\nThis is line    x" 0

    $txtt cursor set 2.15
    do_test $txtt 1 {c S} 2.12 "\nThis is line x"

    do_test $txtt 2 {c S} 2.12 "\nThis is line x" 0
    $txtt cursor set 2.13
    do_test $txtt 3 {c S} 2.12 "\nThis is linex"

    # Cleanup
    cleanup

  }

}
