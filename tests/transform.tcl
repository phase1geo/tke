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
  proc do_test {txtt id cmdlist cursor value {undo 1}} {

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
      cleanup "$id cursor is not correct ([$txtt index insert])"
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

  # Verify g~~ Vim command
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThIs Is A lInE\ntHiS iS a LiNe"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g asciitilde asciitilde} 2.0 "\ntHiS iS a LiNe\ntHiS iS a LiNe"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g asciitilde asciitilde} $index 2] 2.0 "\ntHiS iS a LiNe\nThIs Is A lInE"
    }

    # Cleanup
    cleanup

  }

  # Verify guu Vim command
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE\nTHIS IS A LINE"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g u u} 2.0 "\nthis is a line\nTHIS IS A LINE"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g u u} $index 2] 2.0 "\nthis is a line\nthis is a line"
    }

    # Cleanup
    cleanup

  }

  # Verify gUU Vim command
  proc run_test4 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nthis is a line\nthis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g U U} 2.0 "\nTHIS IS A LINE\nthis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g U U} $index 2] 2.0 "\nTHIS IS A LINE\nTHIS IS A LINE"
    }

    # Cleanup
    cleanup

  }

  # Verify g~l Vim command
  proc run_test5 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g asciitilde l} 2.0 "\ntHIS IS A LINE\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g asciitilde l} $index 2] 2.0 "\nthIS IS A LINE\nThis is a line"
    }

    # Verify that the line does not wrap
    $txtt mark set insert 2.13
    do_test $txtt 4 {3 g asciitilde l} 2.13 "\nTHIS IS A LINe\nThis is a line"

    # Cleanup
    cleanup

  }

  # Verify gul Vim command
  proc run_test6 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE\nTHIS IS A LINE"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g u l} 2.0 "\ntHIS IS A LINE\nTHIS IS A LINE"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g u l} $index 2] 2.0 "\nthIS IS A LINE\nTHIS IS A LINE"
    }

    # Cleanup
    cleanup

  }

  # Verify gUl Vim command
  proc run_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nthis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g U l} 2.0 "\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g U l} $index 2] 2.0 "\nTHis is a line"
    }

    # Cleanup
    cleanup

  }

  # Verify g~h Vim command
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThIs Is A lInE\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.3
    vim::adjust_insert $txtt

    do_test $txtt 0 {g asciitilde h} 2.2 "\nThis Is A lInE\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g asciitilde h} $index 2] 2.1 "\nTHis Is A lInE\nThis is a line"
    }

    # Verify that the change doesn't line wrap
    $txtt mark set insert 3.1
    do_test $txtt 4 {3 g asciitilde h} 3.0 "\nThIs Is A lInE\nthis is a line"

    # Cleanup
    cleanup

  }

  # Verify guh Vim command
  proc run_test9 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE"
    $txtt edit separator
    $txtt mark set insert 2.3
    vim::adjust_insert $txtt

    do_test $txtt 0 {g u h} 2.2 "\nTHiS IS A LINE"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g u h} $index 2] 2.1 "\nThiS IS A LINE"
    }

    # Cleanup
    cleanup

  }

  # Verify gUh Vim command
  proc run_test10 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nthis is a line"
    $txtt edit separator
    $txtt mark set insert 2.3
    vim::adjust_insert $txtt

    do_test $txtt 0 {g U h} 2.2 "\nthIs is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g U h} $index 2] 2.1 "\ntHIs is a line"
    }

    # Cleanup
    cleanup

  }

  # Verify g~space Vim command
  proc run_test11 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThIs Is A lInE\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g asciitilde space} 2.0 "\nthIs Is A lInE\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g asciitilde space} $index 2] 2.0 "\ntHIs Is A lInE\nThis is a line"
    }

    # Verify that we line wrap
    $txtt mark set insert 2.13
    do_test $txtt 4 {3 g asciitilde space} 2.13 "\nThIs Is A lIne\nthis is a line"

    # Cleanup
    cleanup

  }

  # Verify guspace Vim command
  proc run_test12 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g u space} 2.0 "\ntHIS IS A LINE"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g u space} $index 2] 2.0 "\nthIS IS A LINE"
    }

    # Cleanup
    cleanup

  }

  # Verify gUspace Vim command
  proc run_test13 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nthis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g U space} 2.0 "\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g U space} $index 2] 2.0 "\nTHis is a line"
    }

    # Cleanup
    cleanup

  }

  # Verify g~BackSpace Vim command
  proc run_test14 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThIs Is A lInE\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.3
    vim::adjust_insert $txtt

    do_test $txtt 0 {g asciitilde BackSpace} 2.2 "\nThis Is A lInE\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g asciitilde BackSpace} $index 2] 2.1 "\nTHis Is A lInE\nThis is a line"
    }

    $txtt mark set insert 3.1
    do_test $txtt 4 {3 g asciitilde BackSpace} 2.13 "\nThIs Is A lIne\nthis is a line"

    # Cleanup
    cleanup

  }

  # Verify guBackSpace Vim command
  proc run_test15 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE"
    $txtt edit separator
    $txtt mark set insert 2.3
    vim::adjust_insert $txtt

    do_test $txtt 0 {g u BackSpace} 2.2 "\nTHiS IS A LINE"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g u BackSpace} $index 2] 2.1 "\nThiS IS A LINE"
    }

    # Cleanup
    cleanup

  }

  # Verify gUBackSpace Vim command
  proc run_test15 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nthis is a line"
    $txtt edit separator
    $txtt mark set insert 2.3
    vim::adjust_insert $txtt

    do_test $txtt 0 {g U BackSpace} 2.2 "\nthIs is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g U BackSpace} $index 2] 2.1 "\ntHIs is a line"
    }

    # Cleanup
    cleanup

  }

  # Verify g~f Vim command
  proc run_test16 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThIs Is A lInE\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g asciitilde f I} 2.0 "\ntHis Is A lInE\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g asciitilde f I} $index 2] 2.0 "\ntHiS is A lInE\nThis is a line"
    }

    do_test $txtt 4 {3 g asciitilde f s} 2.0 "\nThIs Is A lInE\nThis is a line" 0

    # Cleanup
    cleanup

  }

  # Verify guf Vim command
  proc run_test17 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g u f I} 2.0 "\nthiS IS A LINE"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g u f I} $index 2] 2.0 "\nthis iS A LINE"
    }

    # Cleanup
    cleanup

  }

  # Verify gUf Vim command
  proc run_test18 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nthis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g U f i} 2.0 "\nTHIs is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g U f i} $index 2] 2.0 "\nTHIS Is a line"
    }

    # Cleanup
    cleanup

  }

  # Verify g~t Vim command
  proc run_test19 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThIs Is A lInE\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g asciitilde t I} 2.0 "\ntHIs Is A lInE\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g asciitilde t I} $index 2] 2.0 "\ntHiS Is A lInE\nThis is a line"
    }

    do_test $txtt 4 {3 g asciitilde t s} 2.0 "\nThIs Is A lInE\nThis is a line" 0

    # Cleanup
    cleanup

  }

  # Verify gut Vim command
  proc run_test20 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g u t I} 2.0 "\nthIS IS A LINE"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g u t I} $index 2] 2.0 "\nthis IS A LINE"
    }

    # Cleanup
    cleanup

  }

  # Verify gUt Vim command
  proc run_test21 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nthis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {g U t i} 2.0 "\nTHis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g U t i} $index 2] 2.0 "\nTHIS is a line"
    }

    # Cleanup
    cleanup

  }

  # Verify g~F Vim command
  proc run_test22 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThIs Is A lInE\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.13
    vim::adjust_insert $txtt

    do_test $txtt 0 {g asciitilde F s} 2.6 "\nThIs IS a LiNE\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g asciitilde F s} $index 2] 2.3 "\nThIS iS a LiNE\nThis is a line"
    }

    $txtt mark set insert 3.1
    do_test $txtt 4 {g asciitilde F l} 3.1 "\nThIs Is A lInE\nThis is a line" 0

    # Cleanup
    cleanup

  }

  # Verify guF Vim command
  proc run_test23 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE"
    $txtt edit separator
    $txtt mark set insert 2.13
    vim::adjust_insert $txtt

    do_test $txtt 0 {g u F S} 2.6 "\nTHIS Is a linE"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g u F S} $index 2] 2.3 "\nTHIs is a linE"
    }

    # Cleanup
    cleanup

  }

  # Verify gUF Vim command
  proc run_test24 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nthis is a line"
    $txtt edit separator
    $txtt mark set insert 2.13
    vim::adjust_insert $txtt

    do_test $txtt 0 {g U F s} 2.6 "\nthis iS A LINe"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g U F s} $index 2] 2.3 "\nthiS IS A LINe"
    }

    # Cleanup
    cleanup

  }

  # Verify g~T Vim command
  proc run_test25 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThIs Is A lInE\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.13
    vim::adjust_insert $txtt

    do_test $txtt 0 {g asciitilde T s} 2.7 "\nThIs Is a LiNE\nThis is a line"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g asciitilde T s} $index 2] 2.4 "\nThIs iS a LiNE\nThis is a line"
    }

    $txtt mark set insert 3.1
    do_test $txtt 4 {g asciitilde F l} 3.1 "\nThIs Is A lInE\nThis is a line" 0

    # Cleanup
    cleanup

  }

  # Verify guT Vim command
  proc run_test26 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nTHIS IS A LINE"
    $txtt edit separator
    $txtt mark set insert 2.13
    vim::adjust_insert $txtt

    do_test $txtt 0 {g u T S} 2.7 "\nTHIS IS a linE"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g u T S} $index 2] 2.4 "\nTHIS is a linE"
    }

    # Cleanup
    cleanup

  }

  # Verify gUT Vim command
  proc run_test27 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nthis is a line"
    $txtt edit separator
    $txtt mark set insert 2.13
    vim::adjust_insert $txtt

    do_test $txtt 0 {g U T s} 2.7 "\nthis is A LINe"

    foreach index {0 2} {
      do_test $txtt [expr $index + 1] [linsert {g U T s} $index 2] 2.4 "\nthis IS A LINe"
    }

    # Cleanup
    cleanup

  }

}