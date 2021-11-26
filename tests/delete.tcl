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
          $txtt insert cursor $char
        }
      }
    }

  }

  ######################################################################
  # Runs the given deletion test.
  proc do_test {txtt id cmdlist cursor value cb {undo 1}} {

    set start         [$txtt get 1.0 end-1c]
    set start_cursor  [$txtt index insert]
    set record_num    ""
    set record_events [list]

    clipboard clear
    clipboard append "FOOBAR"

    foreach cmd $cmdlist {
      if {([llength $record_events] == 0) && [string is integer $cmd]} {
        append record_num $cmd
      } else {
        lappend record_events $cmd
      }
    }

    enter $txtt $cmdlist
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id delete did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "command"} {
      cleanup "$id not in mode command ($vim::mode($txtt))"
    }
    if {$vim::operator($txtt) ne ""} {
      cleanup "$id operator not cleared ($vim::operator($txtt))"
    }
    if {$vim::motion($txtt) ne ""} {
      cleanup "$id motion not cleared ($vim::mode($txtt))"
    }
    if {$vim::recording(mode) ne "none"} {
      cleanup "$id recording mode is not none ($vim::recording(mode))"
    }
    if {$vim::recording(num) != $record_num} {
      cleanup "$id recording num is incorrect ($vim::recording(num))"
    }
    if {$vim::recording(events) ne $record_events} {
      cleanup "$id recording events are incorrect ($vim::recording(events))"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id cursor incorrect ([$txtt index insert])"
    }
    if {$cb eq ""} {
      if {[clipboard get] ne "FOOBAR"} {
        cleanup "$id clipboard was incorrect after deletion ([clipboard get])"
      }
    } elseif {[clipboard get] ne $cb} {
      cleanup "$id clipboard was incorrect after deletion ([clipboard get])"
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

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 x 2.0 "\nhis is a line" "T"
    do_test $txtt 1 {2 x} 2.0 "\nis is a line" "Th"

    do_test $txtt 2 x 2.0 "\nhis is a line" "T" 0
    do_test $txtt 3 x 2.0 "\nis is a line" "h"

    # Cleanup
    cleanup

  }

  # Verify Delete Vim command
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 Delete 2.0 "\nhis is a line" "T"
    do_test $txtt 1 {2 Delete} 2.0 "\nis is a line" "Th"

    do_test $txtt 2 Delete 2.0 "\nhis is a line" "T" 0
    do_test $txtt 3 Delete 2.0 "\nis is a line" "h"

    # Cleanup
    cleanup

  }

  # Verify X Vim command
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.3

    do_test $txtt 0 X 2.2 "\nThs is a line" "i"
    do_test $txtt 1 {2 X} 2.1 "\nTs is a line" "hi"

    do_test $txtt 2 X 2.2 "\nThs is a line" "i" 0
    do_test $txtt 3 X 2.1 "\nTs is a line" "h"

    # Cleanup
    cleanup

  }

  # Verify D Vim command
  proc run_test4 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.3

    do_test $txtt 0 D 2.2 "\nThi\nThis is a line\nThis is a line" "s is a line"
    do_test $txtt 1 {2 D} 2.2 "\nThi\nThis is a line" "s is a line\nThis is a line"

    do_test $txtt 2 D 2.2 "\nThi\nThis is a line\nThis is a line" "s is a line" 0
    do_test $txtt 3 D 2.1 "\nTh\nThis is a line\nThis is a line" "i"

  }

  # Verify dd Vim command
  proc run_test5 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line\nThis is a line"]
    $txtt edit separator
    $txtt cursor set 2.5

    do_test $txtt 0 {d d} 2.0 "\nThis is a line" "This is a line\n"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d d} $index 2] 1.0 " " "This is a line\nThis is a line\n"
    }

    do_test $txtt 3 {d d} 2.0 "\nThis is a line" "This is a line\n" 0
    do_test $txtt 4 {d d} 1.0 " " "This is a line\n"

    # Cleanup
    cleanup

  }

  # Verify dl Vim command
  proc run_test6 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {d l} 2.0 "\nhis is a line" "T"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d l} $index 2] 2.0 "\nis is a line" "Th"
    }

    do_test $txtt 3 {d l} 2.0 "\nhis is a line" "T" 0
    do_test $txtt 4 {d l} 2.0 "\nis is a line" "h"

    # Cleanup
    cleanup

  }

  # Verify dvl Vim command
  proc run_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {d v l} 2.0 "\nis is a line" "Th"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d v l} $index 2] 2.0 "\ns is a line" "Thi"
    }

    do_test $txtt 3 {d v l} 2.0 "\nis is a line" "Th" 0
    do_test $txtt 4 {d v l} 2.0 "\n is a line" "is"

    do_test $txtt 5 {d V l} 2.0 "\n " "is is a line"

    # Cleanup
    cleanup

  }

  # Verify dh Vim command
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt cursor set 2.8

    do_test $txtt 0 {d h} 2.7 "\nThis isa line" " "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d h} $index 2] 2.6 "\nThis ia line" "s "
    }

    do_test $txtt 3 {d v h} 2.7 "\nThis is line" " a"
    do_test $txtt 4 {d V h} 2.0 "\n " "This is a line"

    do_test $txtt 5 {d h} 2.7 "\nThis isa line" " " 0
    do_test $txtt 6 {d h} 2.6 "\nThis ia line" "s"

    # Cleanup
    cleanup

  }

  # Verify dj Vim command
  proc run_test9 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.2

    do_test $txtt 0 {d j} 2.2 "\nThis is a line\nThis is a line" "is is a line\nTh"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d j} $index 2] 2.2 "\nThis is a line" "is is a line\nThis is a line\nTh"
    }

    do_test $txtt 3 {d j} 2.2 "\nThis is a line\nThis is a line" "is is a line\nTh" 0
    do_test $txtt 4 {d j} 2.2 "\nThis is a line" "is is a line\nTh"

    # Cleanup
    cleanup

  }

  # Verify dk Vim command
  proc run_test10 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 4.2

    do_test $txtt 0 {d k} 3.2 "\nThis is a line\nThis is a line" "is is a line\nTh"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d k} $index 2] 2.2 "\nThis is a line" "is is a line\nThis is a line\nTh"
    }

    do_test $txtt 3 {d k} 3.2 "\nThis is a line\nThis is a line" "is is a line\nTh" 0
    do_test $txtt 4 {d k} 2.2 "\nThis is a line" "is is a line\nTh"

    # Cleanup
    cleanup

  }

  # Verify dw Vim command
  proc run_test11 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis... is a line"
    $txtt edit separator
    $txtt cursor set 2.1

    do_test $txtt 0 {d w} 2.1 "\nT... is a line" "his"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d w} $index 2] 2.1 "\nTis a line" "his... "
    }

    do_test $txtt 3 {d w} 2.1 "\nT... is a line" "his" 0
    do_test $txtt 4 {d w} 2.1 "\nTis a line" "... "

    # Cleanup
    cleanup

  }

  # Verify dW Vim command
  proc run_test12 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis... is a line"
    $txtt edit separator
    $txtt cursor set 2.1

    do_test $txtt 0 {d W} 2.1 "\nTis a line" "his... "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d W} $index 2] 2.1 "\nTa line" "his... is "
    }

    do_test $txtt 3 {d W} 2.1 "\nTis a line" "his... " 0
    do_test $txtt 4 {d W} 2.1 "\nTa line" "is "

    # Cleanup
    cleanup

  }

  # Verify db Vim command
  proc run_test13 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis... is a line"
    $txtt edit separator
    $txtt cursor set 2.8

    do_test $txtt 0 {d b} 2.4 "\nThisis a line" "... "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d b} $index 2] 2.0 "\nis a line" "This... "
    }

    do_test $txtt 3 {d b} 2.4 "\nThisis a line" "... " 0
    do_test $txtt 4 {d b} 2.0 "\nis a line" "This"

    # Cleanup
    cleanup

  }

  # Verify dB Vim command
  proc run_test14 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis... is a line"
    $txtt edit separator
    $txtt cursor set 2.11

    do_test $txtt 0 {d B} 2.8 "\nThis... a line" "is "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d B} $index 2] 2.0 "\na line" "This... is "
    }

    do_test $txtt 3 {d B} 2.8 "\nThis... a line" "is " 0
    do_test $txtt 4 {d B} 2.0 "\na line" "This... "

    # Cleanup
    cleanup

  }

  # Verify de Vim command
  proc run_test15 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis... is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {d e} 2.0 "\n... is a line" "This"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d e} $index 2] 2.0 "\n is a line" "This..."
    }

    do_test $txtt 3 {d e} 2.0 "\n... is a line" "This" 0
    do_test $txtt 4 {d e} 2.0 "\n is a line" "..."

    # Cleanup
    cleanup

  }

  # Verify dE Vim command
  proc run_test16 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis... is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {d E} 2.0 "\n is a line" "This..."

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d E} $index 2] 2.0 "\n a line" "This... is"
    }

    do_test $txtt 3 {d E} 2.0 "\n is a line" "This..." 0
    do_test $txtt 4 {d E} 2.0 "\n a line" " is"

    # Cleanup
    cleanup

  }

  # Verify dge Vim command
  proc run_test17 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is... a line"
    $txtt edit separator
    $txtt cursor set 2.11

    do_test $txtt 0 {d g e} 2.9 "\nThis is.. line" ". a"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d g e} $index 2] 2.6 "\nThis i line" "s... a"
    }

    do_test $txtt 3 {d g e} 2.9 "\nThis is.. line" ". a" 0
    do_test $txtt 4 {d g e} 2.8 "\nThis is.line" ". "

    # Cleanup
    cleanup

  }

  # Verify dgE Vim command
  proc run_test18 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is... a line"
    $txtt edit separator
    $txtt cursor set 2.11

    do_test $txtt 0 {d g E} 2.9 "\nThis is.. line" ". a"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d g E} $index 2] 2.3 "\nThi line" "s is... a"
    }

    do_test $txtt 3 {d g E} 2.9 "\nThis is.. line" ". a" 0
    do_test $txtt 4 {d g E} 2.8 "\nThis is.line" ". "

    # Cleanup
    cleanup

  }

  # Verify d$ command
  proc run_test19 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line\nThis is a line\nThis is a line"]
    $txtt edit separator
    $txtt cursor set 2.5

    do_test $txtt 0 {d dollar} 2.4 "\nThis \nThis is a line\nThis is a line" "is a line"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d dollar} $index 2] 2.4 "\nThis \nThis is a line" "is a line\nThis is a line"
    }

    do_test $txtt 3 {d dollar} 2.4 "\nThis \nThis is a line\nThis is a line" "is a line" 0
    $txtt cursor set 3.0
    do_test $txtt 4 {d dollar} 3.0 "\nThis \n \nThis is a line" "This is a line"

    # Cleanup
    cleanup

  }

  # Verify d0 Vim command
  proc run_test20 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\n  This is a line"
    $txtt edit separator
    $txtt cursor set 2.8

    do_test $txtt 0 {d 0} 2.0 "\ns a line" "  This i"

    # Cleanup
    cleanup

  }

  # Verify d^ Vim command
  proc run_test21 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\n  This is a line\n This is a line"
    $txtt edit separator
    $txtt cursor set 2.8

    do_test $txtt 0 {d asciicircum} 2.2 "\n  s a line\n This is a line" "This i"

    do_test $txtt 1 {d asciicircum} 2.2 "\n  s a line\n This is a line" "This i" 0
    $txtt cursor set 3.0
    do_test $txtt 2 {d asciicircum} 3.0 "\n  s a line\nThis is a line" " "

    # Cleanup
    cleanup

  }

  # Verify df Vim command
  proc run_test22 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt cursor set 2.1

    do_test $txtt 0 {d f l} 2.1 "\nTine" "his is a l"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d f i} $index 2] 2.1 "\nTs a line" "his i"
    }

    do_test $txtt 3 {d f i} 2.1 "\nTs is a line" "hi" 0
    do_test $txtt 4 {d f i} 2.1 "\nTs a line" "s i"

    # Cleanup
    cleanup

  }

  # Verify dt Vim command
  proc run_test23 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt cursor set 2.1

    do_test $txtt 0 {d t l} 2.1 "\nTline" "his is a "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d t i} $index 2] 2.1 "\nTis a line" "his "
    }

    do_test $txtt 3 {d t i} 2.1 "\nTis is a line" "h" 0
    do_test $txtt 4 {d t i} 2.1 "\nTis a line" "is "

    # Cleanup
    cleanup

  }

  # Verify dF Vim command
  proc run_test24 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt cursor set 2.8

    do_test $txtt 0 {d F i} 2.5 "\nThis a line" "is "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d F i} $index 2] 2.2 "\nTha line" "is is "
    }

    do_test $txtt 3 {d F i} 2.5 "\nThis a line" "is " 0
    do_test $txtt 4 {d F i} 2.2 "\nTha line" "is "

    # Cleanup
    cleanup

  }

  # Verify dT Vim command
  proc run_test25 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt cursor set 2.8

    do_test $txtt 0 {d T i} 2.6 "\nThis ia line" "s "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d T i} $index 2] 2.3 "\nThia line" "s is "
    }

    do_test $txtt 3 {d T i} 2.6 "\nThis ia line" "s " 0
    $txtt cursor set 2.5
    do_test $txtt 4 {d T i} 2.3 "\nThiia line" "s "

    # Cleanup
    cleanup

  }

  # Verify dSpace Vim command
  proc run_test26 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {d space} 2.0 "\nhis is a line\nThis is a line" "T"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d space} $index 2] 2.0 "\nis is a line\nThis is a line" "Th"
    }

    $txtt cursor set 2.13
    do_test $txtt 3 {2 d space} 2.13 "\nThis is a linThis is a line" "e\n"

    $txtt cursor set 2.2
    do_test $txtt 4 {d v space} 2.2 "\nTh is a line\nThis is a line" "is"
    do_test $txtt 5 {d V space} 2.0 "\n \nThis is a line" "This is a line"

    # Cleanup
    cleanup

  }

  # Verify dBackSpace Vim command
  proc run_test27 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.5

    do_test $txtt 0 {d BackSpace} 2.4 "\nThisis a line\nThis is a line" " "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {d BackSpace} $index 2] 2.3 "\nThiis a line\nThis is a line" "s "
    }

    $txtt cursor set 3.1
    do_test $txtt 3 {3 d BackSpace} 2.13 "\nThis is a linhis is a line" "e\nT"

    do_test $txtt 4 {d v BackSpace} 3.0 "\nThis is a line\nis is a line" "Th"
    do_test $txtt 5 {d V BackSpace} 3.0 "\nThis is a line\n " "This is a line"

    # Cleanup
    cleanup

  }

  # Verify dn Vim command
  proc run_test28 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line 1000x"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {d n} 2.0 "\nThis is line 1000x" "" 0

    $txtt cursor set 2.13
    do_test $txtt 1 {d n} 2.13 "\nThis is line x" "1000"

    $txtt cursor set 2.14
    do_test $txtt 2 {d n} 2.14 "\nThis is line 1x" "000"

    do_test $txtt 3 {d n} 2.14 "\nThis is line 1x" "000" 0
    $txtt cursor set 2.13
    do_test $txtt 4 {d n} 2.13 "\nThis is line x" "1"

    # Cleanup
    cleanup

  }

  # Verify dN Vim command
  proc run_test29 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line 1000x"
    $txtt edit separator
    $txtt cursor set 2.5

    do_test $txtt 0 {d N} 2.5 "\nThis is line 1000x" "" 0

    $txtt cursor set 2.17
    do_test $txtt 1 {d N} 2.13 "\nThis is line x" "1000"

    $txtt cursor set 2.16
    do_test $txtt 2 {d N} 2.13 "\nThis is line 0x" "100"

    do_test $txtt 3 {d N} 2.13 "\nThis is line 0x" "100" 0
    $txtt cursor set 2.14
    do_test $txtt 4 {d N} 2.13 "\nThis is line x" "0"

    # Cleanup
    cleanup

  }

  # Verify ds Vim command
  proc run_test30 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line    x"
    $txtt edit separator
    $txtt cursor set 2.0

    do_test $txtt 0 {d s} 2.0 "\nThis is line    x" "" 0

    $txtt cursor set 2.13
    do_test $txtt 1 {d s} 2.13 "\nThis is line x" ""

    do_test $txtt 2 {d s} 2.13 "\nThis is line x" "" 0
    $txtt cursor set 2.12
    do_test $txtt 3 {d s} 2.12 "\nThis is linex" ""

    $txtt delete 1.0 end
    $txtt insert end "\nThis is line    "
    $txtt edit separator
    $txtt cursor set 2.12

    do_test $txtt 4 {d s} 2.11 "\nThis is line" ""

    # Cleanup
    cleanup

  }

  # Verify dS Vim command
  proc run_test31 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is line    x"
    $txtt edit separator
    $txtt cursor set 2.3

    do_test $txtt 0 {d S} 2.3 "\nThis is line    x" "" 0

    $txtt cursor set 2.15
    do_test $txtt 1 {d S} 2.12 "\nThis is line x" ""

    do_test $txtt 2 {d S} 2.12 "\nThis is line x" "" 0
    $txtt cursor set 2.13
    do_test $txtt 3 {d S} 2.12 "\nThis is linex" ""

    # Cleanup
    cleanup

  }

}
