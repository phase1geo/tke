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

    # Clear recording information
    set vim::recording(num)    ""
    set vim::recording(events) [list]

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
  # Perform the yank test (reusable code)
  proc do_test {txtt id cmdlist cursor cb} {

    # The text should never change so just record it
    set start         [$txtt get 1.0 end-1c]
    set record_num    ""
    set record_events [list]

    # Make sure that the clipboard contents are cleared
    clipboard clear

    foreach cmd $cmdlist {
      if {([llength $record_events] == 0) && [string is integer $cmd]} {
        append record_num $cmd
      } else {
        lappend record_events $cmd
      }
    }

    if {$record_events eq {y}} {
      set record_events {}
    }

    enter $txtt $cmdlist
    if {[$txtt get 1.0 end-1c] ne $start} {
      cleanup "$id yank changed text ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "command"} {
      cleanup "$id not in command mode"
    }
    if {$vim::operator($txtt) ne ""} {
      cleanup "$id operator not cleared ($vim::operator($txtt))"
    }
    if {$vim::motion($txtt) ne ""} {
      cleanup "$id operator not cleared ($vim::motion($txtt))"
    }
    if {$vim::recording(mode) ne "none"} {
      cleanup "$id recording mode is not none ($vim::recording(mode))"
    }
    if {$vim::recording(num) ne $record_num} {
      cleanup "$id recording num is incorrect ($vim::recording(num))"
    }
    if {$vim::recording(events) ne $record_events} {
      cleanup "$id recording events are incorrect ($vim::recording(events))"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id yank changed cursor ([$txtt index insert])"
    }
    if {[catch {clipboard get} contents]} {
      if {$cb ne ""} {
        cleanup "$id clipboard not correct ($contents)"
      }
    } elseif {$contents ne $cb} {
      cleanup "$id clipboard not correct ($contents)"
    }

  }

  # Verify yy Vim command
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.5

    do_test $txtt 0 {y y} 2.5 "This is a line\n"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {y y} $index 2] 2.5 "This is a line\nThis is a line\n"
    }

    # Cleanup
    cleanup

  }

  # Verify yl Vim command
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt cursor set 2.0

    do_test $txtt 0 {y l} 2.0 "T"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {y l} $index 2] 2.0 "Th"
    }

    do_test $txtt 3 {y v l} 2.0 "Th"
    do_test $txtt 4 {y V l} 2.0 "This is a line"

    # Make sure that we don't get the end of line
    $txtt cursor set 2.13
    do_test $txtt 5 {3 y l} 2.13 "e"

    # Cleanup
    cleanup

  }

  # Verify yh Vim command
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.8

    do_test $txtt 0 {y h} 2.7 " "

    foreach index {0 1} {
      $txtt cursor set 2.8
      do_test $txtt [expr $index + 1] [linsert {y h} $index 2] 2.6 "s "
    }

    do_test $txtt 3 {y v h} 2.5 "is"
    do_test $txtt 4 {y V h} 2.4 "This is a line"

    # Make sure that the cursor does not line wrap
    $txtt cursor set 3.0
    do_test $txtt 5 {3 y h} 3.0 ""

    # Cleanup
    cleanup

  }

  # Verify ySpace Vim command
  proc run_test4 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.13

    # Do a simple one character yank
    do_test $txtt 0 {y space} 2.13 "e"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {y space} $index 2] 2.13 "e\n"
    }

    do_test $txtt 3 {y v space} 2.13 "e\n"
    do_test $txtt 4 {y V space} 2.13 "This is a line"

    # Verify that yank does not wrap
    do_test $txtt 5 {3 y space} 2.13 "e\nT"

    # Cleanup
    cleanup

  }

  # Verify yBackspace Vim command
  proc run_test5 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.8

    do_test $txtt 0 {y BackSpace} 2.7 " "

    foreach index {0 1} {
      $txtt cursor set 2.8
      do_test $txtt [expr $index + 1] [linsert {y BackSpace} $index 2] 2.6 "s "
    }

    do_test $txtt 3 {y v BackSpace} 2.5 "is"
    do_test $txtt 4 {y V BackSpace} 2.4 "This is a line"

    $txtt cursor set 3.1
    do_test $txtt 5 {3 y BackSpace} 2.13 "e\nT"

    # Cleanup
    cleanup

  }

  # Verify yw Vim command
  proc run_test6 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.0

    do_test $txtt 0 {y w} 2.0 "This "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {y w} $index 2] 2.0 "This is "
    }

    do_test $txtt 3 {5 y w} 2.0 "This is a line\nThis "

    # Cleanup
    cleanup

  }

  # Verify yf Vim command
  proc run_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.0

    do_test $txtt 0 {y f l} 2.0 "This is a l"

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {y f i} $index 2] 2.0 "This i"
    }

    # Make sure the command does not line wrap
    do_test $txtt 3 {2 y f l} 2.0 ""

    # Cleanup
    cleanup

  }

  # Verify yt Vim command
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.0

    do_test $txtt 0 {y t l} 2.0 "This is a "

    foreach index {0 1} {
      do_test $txtt [expr $index + 1] [linsert {y t i} $index 2] 2.0 "This "
    }

    # Make sure the command does not line wrap
    do_test $txtt 3 {2 y t l} 2.0 ""

    # Cleanup
    cleanup

  }

  # Verify yF Vim command
  proc run_test9 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.8

    do_test $txtt 0 {y F i} 2.5 "is "

    foreach index {0 1} {
      $txtt cursor set 2.8
      do_test $txtt [expr $index + 1] [linsert {y F i} $index 2] 2.2 "is is "
    }

    # Make sure the command does not line wrap
    $txtt cursor set 3.8
    do_test $txtt 3 {3 y F i} 3.8 ""

    # Cleanup
    cleanup

  }

  # Verify yT Vim command
  proc run_test10 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.8

    do_test $txtt 0 {y T i} 2.6 "s "

    foreach index {0 1} {
      $txtt cursor set 2.8
      do_test $txtt [expr $index + 1] [linsert {y T i} $index 2] 2.3 "s is "
    }

    # Make sure the command does not line wrap
    $txtt cursor set 3.8
    do_test $txtt 3 {y T l} 3.8 ""

    # Cleanup
    cleanup

  }

  # Perform yank in visual mode
  proc run_test11 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt cursor set 2.8

    enter $txtt {v l}
    do_test $txtt 0 y 2.8 "a "

    enter $txtt V
    do_test $txtt 1 y 2.0 "This is a line\n"

    # Cleanup
    cleanup

  }

  proc do_paste_test {txtt id cmdlist cursor value {undo 1}} {

    set cb            [clipboard get]
    set prevalue      [$txtt get 1.0 end-1c]
    set precursor     [$txtt index insert]
    set record_num    ""
    set record_events [list]

    foreach cmd $cmdlist {
      if {([llength $record_events] == 0) && [string is integer $cmd]} {
        append record_num $cmd
      } else {
        lappend record_events $cmd
      }
    }

    enter $txtt $cmdlist

    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id paste text is not correct ([$txtt get 1.0 end-1c])"
    }
    if {[clipboard get] ne $cb} {
      cleanup "$id clipboard content is not correct ([clipboard get])"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id cursor is not correct ([$txtt index insert])"
    }
    if {$vim::mode($txtt) ne "command"} {
      cleanup "$id mode is not command"
    }
    if {$vim::operator($txtt) ne ""} {
      cleanup "$id operator is not cleared ($vim::mode($txtt))"
    }
    if {$vim::motion($txtt) ne ""} {
      cleanup "$id motion is not cleared ($vim::motion($txtt))"
    }
    if {$vim::recording(mode) ne "none"} {
      cleanup "$id recording mode is not none ($vim::recording(mode))"
    }
    if {$vim::recording(num) ne $record_num} {
      cleanup "$id recording num is incorrect ($vim::recording(num))"
    }
    if {$vim::recording(events) ne $record_events} {
      cleanup "$id recording events are incorrect ($vim::recording(events))"
    }

    if {$undo} {

      enter $txtt u

      if {[$txtt get 1.0 end-1c] ne $prevalue} {
        cleanup "$id undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne $precursor} {
        cleanup "$id undo cursor is not correct ([$txtt index insert])"
      }

    }

  }

  # Perform p Vim command
  proc run_test40 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0

    # Verify pasting characters that are less than a line
    clipboard clear
    clipboard append "This is a line"

    do_paste_test $txtt 0 p     2.14 "\nTThis is a linehis is a line"
    do_paste_test $txtt 1 {2 p} 2.28 "\nTThis is a lineThis is a linehis is a line"
    do_paste_test $txtt 2 P     2.13 "\nThis is a lineThis is a line"
    do_paste_test $txtt 3 {2 P} 2.27 "\nThis is a lineThis is a lineThis is a line"

    # Verify pasting strings that contain newlines
    clipboard clear
    clipboard append "  This is a line\n"

    $txtt configure -indentmode OFF

    do_paste_test $txtt 4 p     3.2 "\nThis is a line\n  This is a line"
    do_paste_test $txtt 5 {2 p} 3.2 "\nThis is a line\n  This is a line\n  This is a line"
    do_paste_test $txtt 6 P     2.2 "\n  This is a line\nThis is a line"
    do_paste_test $txtt 7 {2 P} 2.2 "\n  This is a line\n  This is a line\nThis is a line"

    # Cleanup
    cleanup

  }

}
