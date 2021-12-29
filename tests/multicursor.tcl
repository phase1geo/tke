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
        vim::handle_escape $txtt
      } else {
        set char [utils::sym2char $keysym]
        if {![vim::handle_any $txtt [utils::sym2code $keysym] $char $keysym]} {
          $txtt insert cursor $char
        }
      }
    }

  }

  proc run_test1 {} {

    # Create a text widget
    set txt [initialize]

    $txt insert end "\n\n"

    # Add the multicursors
    $txt cursor add 2.0
    $txt cursor add 3.0

    # Set our Vim mode to edit
    vim::edit_mode $txt.t

    if {[$txt cursor get] ne [list 2.0 3.0]} {
      cleanup "mcursor initialization mismatched ([$txt cursor get])"
    }
    if {[$txt syntax ranges keywords] ne [list]} {
      cleanup "keyword initialization mismatched ([$txt syntax ranges keywords])"
    }

    $txt insert cursor "if \{\$a\} \{"

    # Make sure that the mcursor is set to the correct position
    if {[$txt cursor get] ne [list 2.9 3.9]} {
      cleanup "mcursor mismatched ([$txt cursor get])"
    }
    if {[$txt get 2.0 end-1c] ne "if \{\$a\} \{ \nif \{\$a\} \{ "} {
      cleanup "Text did not match ([$txt get 2.0 end-1c])"
    }
    if {[$txt syntax ranges keywords] ne [list 2.0 2.2 3.0 3.2]} {
      cleanup "keyword mismatched ([$txt syntax ranges keywords])"
    }

    $txt.t insert cursor "\n"

    if {[$txt cursor get] ne [list 3.2 5.2]} {
      cleanup "mcursor mismatched after newline ([$txt cursor get])"
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

    $txt.t insert cursor "puts \"b\""

    if {[$txt cursor get] ne [list 3.10 5.10]} {
      cleanup "mcursor mismatched after string ([$txt cursor get])"
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

    $txt.t insert cursor "\n"

    if {[$txt cursor get] ne [list 4.2 7.2]} {
      cleanup "mcursor mismatched after 2nd newline ([$txt cursor get])"
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

    $txt.t insert cursor "\}"

    if {[$txt cursor get] ne [list 4.1 7.1]} {
      cleanup "mcursor mismatched after unindent ([$txt cursor get])"
    }

    # End the diagnostic
    cleanup

  }

  proc run_test2 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\n\n"

    # Add the multicursors
    $txt cursor add 2.0
    $txt cursor add 3.0

    # Set our Vim mode to edit
    vim::edit_mode $txt.t

    $txt insert cursor "hearing"

    if {[$txt cursor get] ne [list 2.7 3.7]} {
      cleanup "mcursor does not match expected ([$txt cursor get])"
    }

    $txt cursor move [list left -num 4]

    if {[$txt cursor get] ne [list 2.3 3.3]} {
      cleanup "mcursor mismatch after -3c adjust ([$txt cursor get])"
    }

    $txt insert cursor "der"

    if {[$txt cursor get] ne [list 2.6 3.6]} {
      cleanup "mcursor mismatch after replace ([$txt cursor get])"
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

    # This isn't necessary in real world use but doesn't want to work in testing
    $txt cursor add 2.7 3.7

    # Verify that multicursors are set
    if {[$txt cursor get] ne [list 2.7 3.7]} {
      cleanup "mcursor mismatch after selection ([$txt cursor get])"
    }

    $txt delete

    if {[$txt get 2.0 end-1c] ne "lappend foobar 0\nlappend foobar 1"} {
      cleanup "text does not match expected ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.7 3.7]} {
      cleanup "mcursor mismatch after deletion ([$txt cursor get])"
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

    # This is not needed under normal usage but is required for testing
    $txt cursor add 2.6 3.6

    if {[$txt cursor get] ne [list 2.6 3.6]} {
      cleanup "mcursor mismatched after selection ([$txt cursor get])"
    }

    # Delete the current selection
    $txt delete

    if {[$txt cursor get] ne [list 2.5 3.5]} {
      cleanup "mcursor mismatched after deletion ([$txt cursor get])"
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

    # This is not needed under normal conditions but is required for testing
    $txt cursor add 2.0 3.0

    if {[$txt cursor get] ne [list 2.0 3.0]} {
      cleanup "mcursor mismatched after selection ([utils::ostr [$txt cursor get]])"
    }

    $txt delete

    if {[$txt get 2.0 end-1c] ne " \n "} {
      cleanup "text mismatched after deletion ([utils::ostr [$txt get 2.0 end-1c]])"
    }
    if {[$txt cursor get] ne [list 2.0 3.0]} {
      cleanup "mcursor mismatched after deletion ([$txt cursor get])"
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
    $txt cursor add 2.3 3.2

    if {[$txt cursor get] ne [list 2.3 3.2]} {
      cleanup "mcursor mismatched after cursor added ([$txt cursor get])"
    }

    # Delete the current line
    $txt delete linestart lineend

    if {[$txt get 2.0 end-1c] ne " \n "} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.0 3.0]} {
      cleanup "mcursor mismatched after deletion ([$txt cursor get])"
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
    $txt cursor add 2.2
    $txt cursor add 3.0

    # Verify that only the first word is deleted
    $txt delete wordend

    if {[$txt get 2.0 end-1c] ne "th is good\n is not good"} {
      cleanup "text mismatched ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.2 3.0]} {
      cleanup "mcursor mismatched ([$txt cursor get])"
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
    $txt cursor add 2.2
    $txt cursor add 3.0

    # Verify that the first word and the following whitespace is deleted
    $txt delete wordstart

    if {[$txt get 2.0 end-1c] ne "this good\nis not good"} {
      cleanup "text mismatched ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.2 3.0]} {
      cleanup "mcursor mismatched ([$txt cursor get])"
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
    $txt cursor add 2.6
    $txt cursor add 3.0

    $txt delete [list wordend -num 2 -exclusive 1]

    if {[$txt get 2.0 end-1c] ne "this is not good"} {
      cleanup "text mismatched ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.6]} {
      cleanup "mcursor mismatched ([$txt cursor get])"
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
    $txt cursor add 2.6
    $txt cursor add 3.3

    $txt delete linestart

    if {[$txt get 2.0 end-1c] ne "s good\ns is not good"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.0 3.0]} {
      cleanup "mcursor mismatched after deletion ([$txt cursor get])"
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
    $txt cursor add 2.6
    $txt cursor add 3.3

    $txt delete lineend

    if {[$txt get 2.0 end-1c] ne "this i\nthi"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.5 3.2]} {
      cleanup "mcursor mismatched after deletion ([$txt cursor get])"
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
    $txt cursor add 2.5
    $txt cursor add 3.5

    $txt delete [list char -dir prev]

    if {[$txt get 2.0 end-1c] ne "thisis good\nthisis not good"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.4 3.4]} {
      cleanup "mcursor mismatched after deletion ([$txt cursor get])"
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
    $txt cursor add 2.0
    $txt cursor add 3.0

    $txt delete [list char -dir next -num 3]

    if {[$txt get 2.0 end-1c] ne "s is good\ns is not good"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.0 3.0]} {
      cleanup "mcursor mismatched after deletion ([$txt cursor get])"
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
    $txt cursor add 2.10
    $txt cursor add 3.10

    $txt delete [list right -num 3]

    if {[$txt get 2.0 end-1c] ne "this is go\nthis is noood"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.9 3.10]} {
      cleanup "mcursor mismatched after deletion ([$txt cursor get])"
    }

    # Clean things up
    cleanup

  }

  proc run_test17 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is good\nthis is not good"

    # Add the multicursors
    $txt cursor add 2.0
    $txt cursor add 3.0

    $txt delete [list right -num 40]

    if {[$txt get 2.0 end-1c] ne " \n "} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt cursor get] ne [list 2.0 3.0]} {
      cleanup "mcursor mismatched after deletion ([$txt cursor get])"
    }

    # Clean things up
    cleanup

  }

  ######################################################################
  # Performs a Vim multicursor movement test.
  proc do_test {txtt id cmdlist cursors} {

    enter $txtt $cmdlist

    if {[$txtt cursor get] ne $cursors} {
      cleanup "$id mcursor was not correct ([$txtt cursor get], $cursors)"
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
    set mcursors [$txtt cursor get]
    set i        0

    enter $txtt $cmdlist

    if {$anchors eq [list]} {
      set anchors $mcursors
    }

    foreach cursor $cursors {
      if {[$txtt compare $cursor < [lindex $anchors $i]]} {
        lappend selectlist [$txtt index $cursor] [$txtt index [lindex $anchors $i]+1c]
      } else {
        lappend selectlist [lindex $anchors $i] [$txtt index $cursor+1c]
      }
      incr i
    }

    if {[$txtt cursor get] ne $cursors} {
      cleanup "$id mcursor was not correct ([$txtt cursor get])"
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
    $txtt cursor set 2.0

    do_test $txtt 0 {s j s m} [list 2.0 3.0]
    do_test $txtt 1 l         [list 2.1 3.1]
    do_test $txtt 2 {1 2 l}   [list 2.13 3.13]
    do_test $txtt 3 l         [list 2.13 3.13]

    # Get out of multicursor mode
    do_test $txtt 4 Escape [list 2.13 3.13]
    do_test $txtt 5 Escape [list]

    $txtt cursor set 2.0
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
    $txtt cursor set 2.13

    enter $txtt {s j 5 l s m}

    do_test $txtt 0 h       [list 2.12 3.17]
    do_test $txtt 1 {2 h}   [list 2.10 3.15]
    do_test $txtt 2 {1 1 h} [list 2.10 3.15]
    do_test $txtt 3 {1 0 h} [list 2.0 3.5]

    # Get out of multicursor mode
    do_test $txtt 4 Escape [list 2.0 3.5]
    do_test $txtt 5 Escape [list]

    $txtt cursor set 2.13
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
    $txtt cursor set 2.0

    do_test $txtt 0 {s j s m} [list 2.0 3.0]
    do_test $txtt 1 j         [list 3.0 4.0]
    do_test $txtt 2 {2 j}     [list 5.0 6.0]
    do_test $txtt 3 {1 0 j}   [list 5.0 6.0]
    do_test $txtt 4 {5 j}     [list 10.0 11.0]
    do_test $txtt 5 j         [list 10.0 11.0]

    # Get out of multicursor mode
    do_test $txtt 6 Escape [list 10.0 11.0]
    do_test $txtt 7 Escape [list]

    $txtt cursor set 2.0
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
    $txtt cursor set 10.0

    do_test $txtt 0 {s j s m} [list 10.0 11.0]
    do_test $txtt 1 k         [list 9.0 10.0]
    do_test $txtt 2 {2 k}     [list 7.0 8.0]
    do_test $txtt 3 {1 0 k}   [list 7.0 8.0]
    do_test $txtt 4 {6 k}     [list 1.0 2.0]
    do_test $txtt 5 k         [list 1.0 2.0]

    # Get out of multicursor mode
    do_test $txtt 6 Escape [list 1.0 2.0]
    do_test $txtt 7 Escape [list]

    $txtt cursor set 11.0

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
    $txtt cursor set 2.13

    do_test $txtt 0 {s j 5 l s m} [list 2.13 3.18]
    do_test $txtt 1 0 [list 2.0 3.0]

    # Get out of multicursor mode
    do_test $txtt 2 Escape [list 2.0 3.0]
    do_test $txtt 3 Escape [list]

    $txtt cursor set 2.13

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
    $txtt cursor set 2.0

    do_test $txtt 0 {s j s m} [list 2.0 3.0]
    do_test $txtt 1 dollar    [list 2.18 3.13]

    # Get out of multicursor mode
    do_test $txtt 2 Escape [list 2.18 3.13]
    do_test $txtt 3 Escape [list]

    $txtt cursor set 2.0

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
    $txtt cursor set 2.0

    do_test $txtt 0 {s j s m} [list 2.0 3.0]
    do_test $txtt 1 w         [list 2.5 3.5]
    do_test $txtt 2 {2 w}     [list 2.10 3.10]
    do_test $txtt 3 w         [list 3.0 3.17]
    do_test $txtt 4 {10 w}    [list 3.5 3.22]

    do_test $txtt 5 b         [list 3.0 3.17]
    do_test $txtt 6 {2 b}     [list 2.8 3.8]
    do_test $txtt 7 {4 b}     [list 2.8 3.8]

    do_test $txtt 8 Escape [list 2.8 3.8]
    do_test $txtt 9 Escape [list]

    $txtt cursor set 2.0

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
    $txtt cursor set 2.0

    do_test $txtt 0 {s j s m}       [list 2.0 3.0]
    do_test $txtt 1 space           [list 2.1 3.1]
    do_test $txtt 2 {1 2 space}     [list 2.13 3.13]
    do_test $txtt 3 space           [list 3.0 3.14]

    do_test $txtt 4 BackSpace       [list 2.13 3.13]
    do_test $txtt 5 {1 2 BackSpace} [list 2.1 3.1]
    do_test $txtt 6 {1 0 BackSpace} [list 2.1 3.1]

    do_test $txtt 8 Escape [list 2.1 3.1]
    do_test $txtt 9 Escape [list]

    $txtt cursor set 2.2

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
    $txtt cursor set 2.5

    do_test $txtt 0 {s j s m}   [list 2.5 3.5]
    do_test $txtt 1 asciicircum [list 2.1 3.2]
    do_test $txtt 2 asciicircum [list 2.1 3.2]

    do_test $txtt 3 Escape [list 2.1 3.2]
    do_test $txtt 4 Escape [list]

    $txtt cursor set 2.5

    do_test $txtt     5 {s j s m}       [list 2.5 3.5]
    do_sel_test $txtt 6 {v asciicircum} [list 2.1 3.2]

    do_test $txtt 7 Escape [list 2.1 3.2]
    do_test $txtt 8 Escape [list]

    # Cleanup
    cleanup

  }

  proc do_op_test {txtt id cmdlist value mcursors {mode "command"} {undo 1}} {

    set start_value    [$txtt get 1.0 end-1c]
    set start_mcursors [$txtt cursor get]

    enter $txtt $cmdlist

    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id text does not match ([utils::ostr [$txtt get 1.0 end-1c]])"
    }
    if {[$txtt cursor get] ne $mcursors} {
      cleanup "$id mcursors do not match ([$txtt cursor get])"
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
      if {[$txtt cursor get] ne ""} {
        cleanup "$id undo mcursors do not match ([$txtt cursor get])"
      }

      # Restore mcursors
      $txtt cursor add {*}$start_mcursors

    }

  }

  proc run_test40 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nThis is a line"
    $txtt edit separator
    $txtt cursor set 2.0
    $txtt cursor add 2.0 3.0

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
    $txtt cursor disable
    $txtt cursor add 2.0 3.0
    do_op_test $txtt 4 {y l} "\nThis is a line\nThis is a line" {2.0 3.0}

    # Multicursor yank is not fully supported yet
    if {[clipboard get] ne "T\nT"} {
      cleanup "4 yank text is incorrect ([clipboard get])"
    }

    puts "insert: [$txtt index insert]"

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
    $txtt insert -mcursor 0 2.0 "  "
    $txtt insert -mcursor 0 3.0 "  "
    $txtt edit separator
    do_op_test $txtt 11 {less less} "\nThis is a line\nThis is a line" {2.0 3.0}

    $txtt cursor disable
    $txtt cursor add 2.1 3.2

    # Verify X deletion
    puts [$txtt get 1.0 end-1c]
    puts [$txtt cursor get]
    do_op_test $txtt 13 {X} "\n This is a line\n This is a line" {2.0 3.1}

    # Cleanup
    cleanup

  }

}
