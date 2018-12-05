namespace eval multicursor {

  ######################################################################
  # Common diagnostic initialization procedure.  Returns the pathname
  # to the added text widget.
  proc initialize {} {

    variable current_tab
    variable anchors

    # Add a new file
    set current_tab [gui::add_new_file end]

    # Clear the anchors array
    set anchors [list]

    # Get the text widget
    set txt [gui::get_info $current_tab tab txt]

    # Set the current syntax to Tcl
    syntax::set_language $txt Tcl

    # Make sure that the selection mode is "inclusive"
    vim::do_set_selection "inclusive"

    return $txt

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
        multicursor::handle_escape $txtt
        vim::handle_escape $txtt
      } else {
        set char [utils::sym2char $keysym]
        if {![vim::handle_any $txtt [utils::sym2code $keysym] $char $keysym]} {
          $txtt insert insert $char
        }
      }
    }

  }

  proc run_test1 {} {

    # Create a text widget
    set txt [initialize]

    $txt insert end "\n\n"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.0
    multicursor::add_cursor $txt.t 3.0

    # Set our Vim mode to edit
    vim::edit_mode $txt.t

    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
      cleanup "mcursor initialization mismatched ([$txt tag ranges mcursor])"
    }
    if {[$txt syntax ranges keywords] ne [list]} {
      cleanup "keyword initialization mismatched ([$txt syntax ranges keywords])"
    }

    multicursor::insert $txt.t "if \{\$a\} \{" indent::check_indent

    # Make sure that the mcursor is set to the correct position
    if {[$txt tag ranges mcursor] ne [list 2.9 2.10 3.9 3.10]} {
      cleanup "mcursor mismatched ([$txt tag ranges mcursor])"
    }
    if {[$txt get 2.0 end-1c] ne "if \{\$a\} \{ \nif \{\$a\} \{ "} {
      cleanup "Text did not match ([$txt get 2.0 end-1c])"
    }
    if {[$txt syntax ranges keywords] ne [list 2.0 2.2 3.0 3.2]} {
      cleanup "keyword mismatched ([$txt syntax ranges keywords])"
    }

    multicursor::insert $txt.t "\n" indent::newline

    if {[$txt tag ranges mcursor] ne [list 3.2 3.3 5.2 5.3]} {
      cleanup "mcursor mismatched after newline ([$txt tag ranges mcursor])"
    }
    if {[$txt syntax ranges keywords] ne [list 2.0 2.2 4.0 4.2]} {
      cleanup "keyword mismatched after newline ([$txt syntax ranges keywords])"
    }
    if {[$txt syntax ranges comstr0d0] ne [list]} {
      cleanup "dstring0 mismatched after newline ([$txt syntax ranges comstr0d0])"
    }
    if {[$txt syntax ranges comstr0d1] ne [list]} {
      cleanup "dstring1 mismatched after newline ([$txt syntax ranges comstr0d1])"
    }

    multicursor::insert $txt.t "puts \"b\"" indent::check_indent

    if {[$txt tag ranges mcursor] ne [list 3.10 3.11 5.10 5.11]} {
      cleanup "mcursor mismatched after string ([$txt tag ranges mcursor])"
    }
    if {[$txt syntax ranges keywords] ne [list 2.0 2.2 3.2 3.6 4.0 4.2 5.2 5.6]} {
      cleanup "keyword mismatched after string ([$txt syntax ranges keywords])"
    }
    if {[$txt syntax ranges comstr0d0] ne [list 3.7 3.10]} {
      cleanup "dstring0 mismatched after string ([$txt syntax ranges comstr0d0])"
    }
    if {[$txt syntax ranges comstr0d1] ne [list 5.7 5.10]} {
      cleanup "dstring1 mismatched after string ([$txt syntax ranges comstr0d1])"
    }

    multicursor::insert $txt.t "\n" indent::newline

    if {[$txt tag ranges mcursor] ne [list 4.2 4.3 7.2 7.3]} {
      cleanup "mcursor mismatched after 2nd newline ([$txt tag ranges mcursor])"
    }
    if {[$txt syntax ranges keywords] ne [list 2.0 2.2 3.2 3.6 5.0 5.2 6.2 6.6]} {
      cleanup "keyword mismatched after 2nd newline ([$txt syntax ranges keywords])"
    }
    if {[$txt syntax ranges comstr0d0] ne [list 3.7 3.10]} {
      cleanup "dstring0 mismatched after string ([$txt syntax ranges comstr0d0])"
    }
    if {[$txt syntax ranges comstr0d1] ne [list 6.7 6.10]} {
      cleanup "dstring1 mismatched after string ([$txt syntax ranges comstr0d1])"
    }

    multicursor::insert $txt.t "\}" indent::check_indent

    if {[$txt tag ranges mcursor] ne [list 4.1 4.2 7.1 7.2]} {
      cleanup "mcursor mismatched after unindent ([$txt tag ranges mcursor])"
    }

    # End the diagnostic
    cleanup

  }

  proc run_test2 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\n\n"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.0
    multicursor::add_cursor $txt.t 3.0

    # Set our Vim mode to edit
    vim::edit_mode $txt.t

    multicursor::insert $txt.t "hearing" indent::check_indent

    if {[$txt tag ranges mcursor] ne [list 2.7 2.8 3.7 3.8]} {
      cleanup "mcursor does not match expected ([$txt tag ranges mcursor])"
    }

    multicursor::move $txt.t [list left -num 4]

    if {[$txt tag ranges mcursor] ne [list 2.3 2.4 3.3 3.4]} {
      cleanup "mcursor mismatch after -3c adjust ([$txt tag ranges mcursor])"
    }

    multicursor::replace $txt.t "der" indent::check_indent

    if {[$txt tag ranges mcursor] ne [list 2.6 2.7 3.6 3.7]} {
      cleanup "mcursor mismatch after replace ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Delete the selected text
  proc run_test3 {} {

    # Get the text widget
    set txt [initialize]

    # Insert the text that we want to improve
    $txt insert end "\nlappends foobar 0\nlappendfo foobar 1"

    # Make sure that there are no keywords highlighted
    if {[$txt syntax ranges keywords] ne [list]} {
      cleanup "keywords found in text widget when none should be detected ([$txt syntax ranges keywords])"
    }

    # Select the first s and the last fo
    $txt tag add sel 2.7 2.8 3.7 3.9
    multicursor::handle_selection $txt.t

    # Verify that multicursors are set
    if {[$txt tag ranges mcursor] ne [list 2.7 2.8 3.7 3.8]} {
      cleanup "mcursor mismatch after selection ([$txt tag ranges mcursor])"
    }

    multicursor::delete $txt.t selected

    if {[$txt get 2.0 end-1c] ne "lappend foobar 0\nlappend foobar 1"} {
      cleanup "text does not match expected ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.7 2.8 3.7 3.8]} {
      cleanup "mcursor mismatch after deletion ([$txt tag ranges mcursor])"
    }
    if {[$txt syntax ranges keywords] ne [list 2.0 2.7 3.0 3.7]} {
      cleanup "keywords mismatch after deletion ([$txt syntax ranges keywords])"
    }

    # Clean things up
    cleanup

  }

  # Make sure that the mcursors are located in the correct position
  # if the selection is at the end of the current line.
  proc run_test4 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nline one\nline two"

    # Select the text at the end of the line
    $txt tag add sel 2.6 2.9 3.6 3.9
    multicursor::handle_selection $txt.t

    if {[$txt tag ranges mcursor] ne [list 2.6 2.7 3.6 3.7]} {
      cleanup "mcursor mismatched after selection ([$txt tag ranges mcursor])"
    }

    # Delete the current selection
    multicursor::delete $txt.t selected

    if {[$txt tag ranges mcursor] ne [list 2.5 2.6 3.5 3.6]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Make sure that if an entire line was selected, deleting the
  # selection causes the multicursor to be set at the beginnning
  # of the current line.
  proc run_test5 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nfirst line\nsecond line"

    $txt tag add sel 2.0 2.end 3.0 3.end
    multicursor::handle_selection $txt.t

    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
      cleanup "mcursor mismatched after selection ([$txt tag ranges mcursor])"
    }

    multicursor::delete $txt.t selected

    if {[$txt get 2.0 end-1c] ne " \n "} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Delete the entire line
  proc run_test6 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nfirst line\nsecond line"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.3
    multicursor::add_cursor $txt.t 3.2

    if {[$txt tag ranges mcursor] ne [list 2.3 2.4 3.2 3.3]} {
      cleanup "mcursor mismatched after cursor added ([$txt tag ranges mcursor])"
    }

    # Delete the current line
    multicursor::delete $txt.t linestart lineend

    if {[$txt get 2.0 end-1c] ne " \n "} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Delete a word
  proc run_test7 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.2
    multicursor::add_cursor $txt.t 3.0

    # Verify that only the first word is deleted
    multicursor::delete $txt.t [list wordend -adjust +1c]

    if {[$txt get 2.0 end-1c] ne "th is good\n is not good"} {
      cleanup "text mismatched ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.2 2.3 3.0 3.1]} {
      cleanup "mcursor mismatched ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Delete word plus whitespace
  proc run_test8 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.2
    multicursor::add_cursor $txt.t 3.0

    # Verify that the first word and the following whitespace is
    # deleted
    multicursor::delete $txt.t wordstart

    if {[$txt get 2.0 end-1c] ne "this good\nis not good"} {
      cleanup "text mismatched ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.2 2.3 3.0 3.1]} {
      cleanup "mcursor mismatched ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Delete multiple words and verify that we can't exceed the current line
  proc run_test9 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.6
    multicursor::add_cursor $txt.t 3.0

    multicursor::delete $txt.t [list wordend -num 2]

    if {[$txt get 2.0 end-1c] ne "this i\n not good"} {
      cleanup "text mismatched ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.5 2.6 3.0 3.1]} {
      cleanup "mcursor mismatched ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Delete the line from the start to the current cursor.
  proc run_test10 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.6
    multicursor::add_cursor $txt.t 3.3

    multicursor::delete $txt.t linestart

    if {[$txt get 2.0 end-1c] ne "s good\ns is not good"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup
  }

  # Delete the line from the current cursor to the end of the line.
  proc run_test11 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.6
    multicursor::add_cursor $txt.t 3.3

    multicursor::delete $txt.t lineend

    if {[$txt get 2.0 end-1c] ne "this i\nthi"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.5 2.6 3.2 3.3]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Delete # of chars prior to the cursor to the cursor.
  proc run_test14 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.5
    multicursor::add_cursor $txt.t 3.5

    multicursor::delete $txt.t [list char -dir prev]

    if {[$txt get 2.0 end-1c] ne "thisis good\nthisis not good"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.4 2.5 3.4 3.5]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Delete from the cursor to # of chars after the cursor.
  proc run_test15 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.0
    multicursor::add_cursor $txt.t 3.0

    multicursor::delete $txt.t [list char -dir next -num 3]

    if {[$txt get 2.0 end-1c] ne "s is good\ns is not good"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Set our Vim mode to edit
    vim::edit_mode $txt.t

    # Clean things up
    cleanup

  }

  # Verify that deletion cannot run past the end of the current line
  proc run_test16 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.10
    multicursor::add_cursor $txt.t 3.10

    multicursor::delete $txt.t [list right -num 3]

    if {[$txt get 2.0 end-1c] ne "this is go\nthis is noood"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.9 2.10 3.10 3.11]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  proc run_test17 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.0
    multicursor::add_cursor $txt.t 3.0

    multicursor::delete $txt.t [list right -num 40]

    if {[$txt get 2.0 end-1c] ne " \n "} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  ######################################################################
  # Performs a Vim multicursor movement test.
  proc do_test {txtt id cmdlist cursors} {

    enter $txtt $cmdlist

    # Create the full cursor to compare against
    set cursorlist [list]
    foreach cursor $cursors {
      lappend cursorlist $cursor [$txtt index $cursor+1c]
    }

    if {[$txtt tag ranges mcursor] ne $cursorlist} {
      cleanup "$id mcursor was not correct ([$txtt tag ranges mcursor], $cursorlist)"
    }
    if {[$txtt tag ranges sel] ne [list]} {
      cleanup "$id selection was not correct ([$txtt tag ranges sel])"
    }

  }

  ######################################################################
  # Perfoms a Vim multicursor selection test.
  proc do_sel_test {txtt id cmdlist cursors} {

    variable anchors

    # Get the current multicursors
    set mcursors [$txtt tag ranges mcursor]
    set i        0

    enter $txtt $cmdlist

    if {$anchors eq [list]} {
      set anchors [list]
      foreach {start end} $mcursors {
        lappend anchors $start
      }
    }

    foreach cursor $cursors {
      lappend mcursorlist $cursor [$txtt index $cursor+1c]
      if {[$txtt compare $cursor < [lindex $anchors $i]]} {
        lappend selectlist [$txtt index $cursor] [$txtt index [lindex $anchors $i]+1c]
      } else {
        lappend selectlist [lindex $anchors $i] [$txtt index $cursor+1c]
      }
      incr i
    }

    if {[$txtt tag ranges mcursor] ne $mcursorlist} {
      cleanup "$id mcursor was not correct ([$txtt tag ranges mcursor])"
    }
    if {[$txtt tag ranges sel] ne $selectlist} {
      cleanup "$id selection was not correct ([$txtt tag ranges sel], $selectlist)"
    }

  }

  # Move cursors to the right
  proc run_test19 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nThis is a good line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {s j s m} [list 2.0 3.0]
    do_test $txtt 1 l         [list 2.1 3.1]
    do_test $txtt 2 {1 2 l}   [list 2.13 3.13]
    do_test $txtt 3 l         [list 2.13 3.13]

    # Get out of multicursor mode
    do_test $txtt 4 Escape [list 2.13 3.13]
    do_test $txtt 5 Escape [list]

    $txtt mark set insert 2.0
    do_test     $txtt 6 {s j s m} [list 2.0 3.0]
    do_sel_test $txtt 7 {v l}     [list 2.1 3.1]
    do_sel_test $txtt 8 {1 2 l}   [list 2.13 3.13]
    do_sel_test $txtt 9 l         [list 2.13 3.13]

    do_test $txtt 10 Escape [list 2.13 3.13]
    do_test $txtt 11 Escape [list]

    # Cleanup
    cleanup

  }

  # Move cursors to the left
  proc run_test20 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nThis is a good line"
    $txtt mark set insert 2.13
    vim::adjust_insert $txtt

    enter $txtt {s j 5 l s m}

    do_test $txtt 0 h       [list 2.12 3.17]
    do_test $txtt 1 {2 h}   [list 2.10 3.15]
    do_test $txtt 2 {1 1 h} [list 2.10 3.15]
    do_test $txtt 3 {1 0 h} [list 2.0 3.5]

    # Get out of multicursor mode
    do_test $txtt 4 Escape [list 2.0 3.5]
    do_test $txtt 5 Escape [list]

    $txtt mark set insert 2.13
    do_test $txtt     6 {s j 5 l s m} [list 2.13 3.18]
    do_sel_test $txtt 7 {v h}         [list 2.12 3.17]
    do_sel_test $txtt 8 {1 2 h}       [list 2.0 3.5]
    do_sel_test $txtt 9 h             [list 2.0 3.5]

    do_test $txtt 10 Escape [list 2.0 3.5]
    do_test $txtt 11 Escape [list]

    # Cleanup
    cleanup

  }

  # Verify multicursor down
  proc run_test21 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end [string repeat "\nThis is a line" 10]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {s j s m} [list 2.0 3.0]
    do_test $txtt 1 j         [list 3.0 4.0]
    do_test $txtt 2 {2 j}     [list 5.0 6.0]
    do_test $txtt 3 {1 0 j}   [list 5.0 6.0]
    do_test $txtt 4 {5 j}     [list 10.0 11.0]
    do_test $txtt 5 j         [list 10.0 11.0]

    # Get out of multicursor mode
    do_test $txtt 6 Escape [list 10.0 11.0]
    do_test $txtt 7 Escape [list]

    $txtt mark set insert 2.0
    do_test $txtt     8 {s 5 j s m} [list 2.0 7.0]
    do_sel_test $txtt 9 {v j}       [list 3.0 8.0]
    do_sel_test $txtt 10 {3 j}      [list 6.0 11.0]
    do_sel_test $txtt 11 j          [list 6.0 11.0]

    do_test $txtt 12 Escape [list 6.0 11.0]
    do_test $txtt 13 Escape [list]

    # Cleanup
    cleanup

  }

  # Verify k Vim command
  proc run_test22 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end [string repeat "\nThis is a line" 10]
    $txtt mark set insert 10.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {s j s m} [list 10.0 11.0]
    do_test $txtt 1 k         [list 9.0 10.0]
    do_test $txtt 2 {2 k}     [list 7.0 8.0]
    do_test $txtt 3 {1 0 k}   [list 7.0 8.0]
    do_test $txtt 4 {6 k}     [list 1.0 2.0]
    do_test $txtt 5 k         [list 1.0 2.0]

    # Get out of multicursor mode
    do_test $txtt 6 Escape [list 1.0 2.0]
    do_test $txtt 7 Escape [list]

    $txtt mark set insert 11.0
    vim::adjust_insert $txtt

    do_test     $txtt 8  {s 6 k s m} [list 5.0 11.0]
    do_sel_test $txtt 9  {v k}       [list 4.0 10.0]
    do_sel_test $txtt 10 {3 k}       [list 1.0 7.0]
    do_sel_test $txtt 11 k           [list 1.0 7.0]

    do_test $txtt 12 Escape [list 1.0 7.0]
    do_test $txtt 13 Escape [list]

    # Cleanup
    cleanup

  }

  # Verify 0 Vim commands
  proc run_test23 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nThis is also a line"
    $txtt mark set insert 2.13
    vim::adjust_insert $txtt

    do_test $txtt 0 {s j 5 l s m} [list 2.13 3.18]
    do_test $txtt 1 0 [list 2.0 3.0]

    # Get out of multicursor mode
    do_test $txtt 2 Escape [list 2.0 3.0]
    do_test $txtt 3 Escape [list]

    $txtt mark set insert 2.13
    vim::adjust_insert $txtt

    do_test     $txtt 4 {s j 5 l s m} [list 2.13 3.18]
    do_sel_test $txtt 5 {v 0}         [list 2.0 3.0]

    do_test $txtt 6 Escape [list 2.0 3.0]
    do_test $txtt 7 Escape [list]

    # Cleanup
    cleanup

  }

  # Verify $ Vim command
  proc run_test24 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is a good line\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {s j s m} [list 2.0 3.0]
    do_test $txtt 1 dollar    [list 2.18 3.13]

    # Get out of multicursor mode
    do_test $txtt 2 Escape [list 2.18 3.13]
    do_test $txtt 3 Escape [list]

    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test     $txtt 4 {s j s m}  [list 2.0 3.0]
    do_sel_test $txtt 5 {v dollar} [list 2.18 3.13]

    do_test $txtt 6 Escape [list 2.18 3.13]
    do_test $txtt 7 Escape [list]

    # Cleanup
    cleanup

  }

  # Verify w and b Vim commands
  proc run_test25 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nThis is a really good line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {s j s m} [list 2.0 3.0]
    do_test $txtt 1 w         [list 2.5 3.5]
    do_test $txtt 2 {2 w}     [list 2.10 3.10]
    do_test $txtt 3 w         [list 3.0 3.17]
    do_test $txtt 4 {10 w}    [list 3.5 3.22]

    do_test $txtt 5 b         [list 3.0 3.17]
    do_test $txtt 6 {2 b}     [list 2.8 3.8]
    do_test $txtt 7 {4 b}     [list 1.0 2.8]

    do_test $txtt 8 Escape [list 1.0 2.8]
    do_test $txtt 9 Escape [list]

    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test     $txtt 10 {s j s m} [list 2.0 3.0]
    do_sel_test $txtt 11 {v w}     [list 2.5 3.5]
    do_sel_test $txtt 12 {2 w}     [list 2.10 3.10]
    do_sel_test $txtt 13 b         [list 2.8 3.8]
    do_sel_test $txtt 14 {2 b}     [list 2.0 3.0]
    do_sel_test $txtt 15 b         [list 1.0 2.10]

    do_test $txtt 16 Escape [list 1.0 2.10]
    do_test $txtt 17 Escape [list]

    # Cleanup
    cleanup

  }

  # Verify space and backspace Vim command
  proc run_test26 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nThis is a really good line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {s j s m}       [list 2.0 3.0]
    do_test $txtt 1 space           [list 2.1 3.1]
    do_test $txtt 2 {1 2 space}     [list 2.13 3.13]
    do_test $txtt 3 space           [list 3.0 3.14]

    do_test $txtt 4 BackSpace       [list 2.13 3.13]
    do_test $txtt 5 {1 2 BackSpace} [list 2.1 3.1]
    do_test $txtt 6 {1 0 BackSpace} [list 1.0 2.5]

    do_test $txtt 8 Escape [list 1.0 2.5]
    do_test $txtt 9 Escape [list]

    $txtt mark set insert 2.2
    vim::adjust_insert $txtt

    do_test     $txtt 10 {s j s m}       [list 2.2 3.2]
    do_sel_test $txtt 11 {v space}       [list 2.3 3.3]
    do_sel_test $txtt 12 {1 0 space}     [list 2.13 3.13]
    do_sel_test $txtt 13 space           [list 3.0 3.14]
    do_sel_test $txtt 14 BackSpace       [list 2.13 3.13]
    do_sel_test $txtt 15 {1 3 BackSpace} [list 2.0 3.0]
    do_sel_test $txtt 16 BackSpace       [list 1.0 2.13]

    do_test $txtt 17 Escape [list 1.0 2.13]
    do_test $txtt 18 Escape [list]

    # Cleanup
    cleanup

  }

  # Verify ^ Vim command
  proc run_test27 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\n This is a line\n  This is a line"
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 {s j s m}   [list 2.5 3.5]
    do_test $txtt 1 asciicircum [list 2.1 3.2]
    do_test $txtt 2 asciicircum [list 2.1 3.2]

    do_test $txtt 3 Escape [list 2.1 3.2]
    do_test $txtt 4 Escape [list]

    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt     5 {s j s m}       [list 2.5 3.5]
    do_sel_test $txtt 6 {v asciicircum} [list 2.1 3.2]

    do_test $txtt 7 Escape [list 2.1 3.2]
    do_test $txtt 8 Escape [list]

    # Cleanup
    cleanup

  }

  proc do_op_test {txtt id cmdlist value mcursor_list {mode "command"} {undo 1}} {

    set start_value    [$txtt get 1.0 end-1c]
    set start_mcursors [$txtt tag ranges mcursor]
    set mcursors       [list]
    foreach mcursor $mcursor_list {
      lappend mcursors $mcursor [$txtt index "$mcursor+1c"]
    }

    enter $txtt $cmdlist

    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id text does not match ([$txtt get 1.0 end-1c])"
    }
    if {[$txtt tag ranges mcursor] ne $mcursors} {
      cleanup "$id mcursors do not match ([$txtt tag ranges mcursor])"
    }
    if {$vim::mode($txtt) ne $mode} {
      cleanup "$id mode is incorrect ($vim::mode($txtt))"
    }
    if {$vim::operator($txtt) ne ""} {
      cleanup "$id operator is incorrect ($vim::operator($txtt))"
    }
    if {$vim::motion($txtt) ne ""} {
      cleanup "$id motion is incorrect ($vim::motion($txtt))"
    }

    if {$undo && ($mode ne "edit") && ([lindex $cmdlist 0] ne "y")} {

      enter $txtt {Escape u}

      if {[$txtt get 1.0 end-1c] ne $start_value} {
        cleanup "$id undo text does not match ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt tag ranges mcursor] ne ""} {
        cleanup "$id undo mcursors do not match ([$txtt tag ranges mcursor])"
      }

      # Restore mcursors
      $txtt tag add mcursor {*}$start_mcursors

    }

  }

  proc run_test40 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt mark set insert 2.0
    $txtt tag add mcursor 2.0 2.1 3.0 3.1
    vim::adjust_insert $txtt

    # Verify d deletion
    do_op_test $txtt 0 {d l} "\nhis is a line\nhis is a line" {2.0 3.0}

    # Verify x deletion
    do_op_test $txtt 1 {2 x} "\nis is a line\nis is a line" {2.0 3.0}

    # Verify Delete deletion
    do_op_test $txtt 2 {Delete} "\nhis is a line\nhis is a line" {2.0 3.0}

    # Verify c deletion
    do_op_test $txtt 3 {c w} "\n is a line\n is a line" {2.0 3.0} "edit"
    enter $txtt {Escape u}

    # Verify y yank
    clipboard clear
    $txtt tag remove mcursor 1.0 end
    $txtt tag add mcursor 2.0 2.1 3.0 3.1
    do_op_test $txtt 4 {y l} "\nThis is a line\nThis is a line" {2.0 3.0}

    # TBD - Multicursor yank is not fully supported yet
    if {[clipboard get] ne "T"} {
      cleanup "4 yank text is incorrect ([clipboard get])"
    }

    # Verify case toggle
    do_op_test $txtt 5 asciitilde "\nthis is a line\nthis is a line" {2.0 3.0}

    # Verify case toggle
    do_op_test $txtt 6 {g asciitilde v l} "\ntHis is a line\ntHis is a line" {2.0 3.0}

    # Verify lower case
    do_op_test $txtt 7 {g u l} "\nthis is a line\nthis is a line" {2.0 3.0}

    # Verify upper case
    do_op_test $txtt 8 {g U v l} "\nTHis is a line\nTHis is a line" {2.0 3.0}

    # Verify rot13
    do_op_test $txtt 9 {g question 4 l} "\nGuvf is a line\nGuvf is a line" {2.0 3.0}

    # Verify rshift
    do_op_test $txtt 10 {greater greater} "\n  This is a line\n  This is a line" {2.2 3.2}

    # Verify lshift
    $txtt insert 2.0 "  "
    $txtt insert 3.0 "  "
    $txtt edit separator
    do_op_test $txtt 11 {less less} "\nThis is a line\nThis is a line" {2.0 3.0}

    $txtt tag remove mcursor 1.0 end
    $txtt tag add mcursor 2.1 2.2 3.2 3.3

    # Verify X deletion
    do_op_test $txtt 13 {X} "\n This is a line\n This is a line" {2.0 3.1}

    # Cleanup
    cleanup

  }

}
