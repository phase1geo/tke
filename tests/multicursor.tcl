namespace eval multicursor {

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

    return $txt

  }

  ######################################################################
  # Common cleanup procedure.  If a fail message is provided, return an
  # error with the given error message.
  proc cleanup {{fail_msg ""}} {

    variable current_tab

    # Close the current tab
    gui::close_tab {} $current_tab -check 0

    # Output the fail message and cause a failure
    if {$fail_msg ne ""} {
      return -code error $fail_msg
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
    if {[$txt tag ranges _keywords] ne [list]} {
      cleanup "keyword initialization mismatched ([$txt tag ranges _keywords])"
    }

    multicursor::insert $txt.t "if \{\$a\} \{" indent::check_indent

    # Make sure that the mcursor is set to the correct position
    if {[$txt tag ranges mcursor] ne [list 2.9 2.10 3.9 3.10]} {
      cleanup "mcursor mismatched ([$txt tag ranges mcursor])"
    }
    if {[$txt get 2.0 end-1c] ne "if \{\$a\} \{ \nif \{\$a\} \{ "} {
      cleanup "Text did not match ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges _keywords] ne [list 2.0 2.2 3.0 3.2]} {
      cleanup "keyword mismatched ([$txt tag ranges _keywords])"
    }

    multicursor::insert $txt.t "\n" indent::newline

    if {[$txt tag ranges mcursor] ne [list 3.2 3.3 5.2 5.3]} {
      cleanup "mcursor mismatched after newline ([$txt tag ranges mcursor])"
    }
    if {[$txt tag ranges _keywords] ne [list 2.0 2.2 4.0 4.2]} {
      cleanup "keyword mismatched after newline ([$txt tag ranges _keywords])"
    }
    if {[$txt tag ranges _dString0] ne [list]} {
      cleanup "dstring0 mismatched after newline ([$txt tag ranges _dString0])"
    }
    if {[$txt tag ranges _dString1] ne [list]} {
      cleanup "dstring1 mismatched after newline ([$txt tag ranges _dString1])"
    }

    multicursor::insert $txt.t "puts \"b\"" indent::check_indent

    if {[$txt tag ranges mcursor] ne [list 3.10 3.11 5.10 5.11]} {
      cleanup "mcursor mismatched after string ([$txt tag ranges mcursor])"
    }
    if {[$txt tag ranges _keywords] ne [list 2.0 2.2 3.2 3.6 4.0 4.2 5.2 5.6]} {
      cleanup "keyword mismatched after string ([$txt tag ranges _keywords])"
    }
    if {[$txt tag ranges _dString0] ne [list 3.7 3.10]} {
      cleanup "dstring0 mismatched after string ([$txt tag ranges _dString0])"
    }
    if {[$txt tag ranges _dString1] ne [list 5.7 5.10]} {
      cleanup "dstring1 mismatched after string ([$txt tag ranges _dString1])"
    }

    multicursor::insert $txt.t "\n" indent::newline

    if {[$txt tag ranges mcursor] ne [list 4.2 4.3 7.2 7.3]} {
      cleanup "mcursor mismatched after 2nd newline ([$txt tag ranges mcursor])"
    }
    if {[$txt tag ranges _keywords] ne [list 2.0 2.2 3.2 3.6 5.0 5.2 6.2 6.6]} {
      cleanup "keyword mismatched after 2nd newline ([$txt tag ranges _keywords])"
    }
    if {[$txt tag ranges _dString0] ne [list 3.7 3.10]} {
      cleanup "dstring0 mismatched after string ([$txt tag ranges _dString0])"
    }
    if {[$txt tag ranges _dString1] ne [list 6.7 6.10]} {
      cleanup "dstring1 mismatched after string ([$txt tag ranges _dString1])"
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

    multicursor::adjust $txt.t -1c
    multicursor::adjust $txt.t -1c
    multicursor::adjust $txt.t -1c
    multicursor::adjust $txt.t -1c

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
    if {[$txt tag ranges _keywords] ne [list]} {
      cleanup "keywords found in text widget when none should be detected ([$txt tag ranges keywords])"
    }

    # Select the first s and the last fo
    $txt tag add sel 2.7 2.8 3.7 3.9

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
    if {[$txt tag ranges _keywords] ne [list 2.0 2.7 3.0 3.7]} {
      cleanup "keywords mismatch after deletion ([$txt tag ranges _keywords])"
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
    multicursor::delete $txt.t line

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
    multicursor::delete $txt.t word 1

    if {[$txt get 2.0 end-1c] ne " is good\n is not good"} {
      cleanup "text mismatched ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
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
    multicursor::delete $txt.t word 2

    if {[$txt get 2.0 end-1c] ne "is good\nis not good"} {
      cleanup "text mismatched ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
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

    multicursor::delete $txt.t word 3

    if {[$txt get 2.0 end-1c] ne "this \nnot good"} {
      cleanup "text mismatched ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.4 2.5 3.0 3.1]} {
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

  # Delete if the start of the text matches the given pattern.
  proc run_test12 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is this good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.0
    multicursor::add_cursor $txt.t 3.0

    multicursor::delete $txt.t pattern {^this}

    if {[$txt get 2.0 end-1c] ne " is this good\n is not good"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

  # Delete if text within the line matches the given pattern.
  proc run_test13 {} {

    # Get the text widget
    set txt [initialize]

    $txt insert end "\nthis is this good\nthis is not good"

    # Add the multicursors
    multicursor::add_cursor $txt.t 2.12
    multicursor::add_cursor $txt.t 3.2

    multicursor::delete $txt.t pattern {this$}

    if {[$txt get 2.0 end-1c] ne "this is  good\nthis is not good"} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.8 2.9 3.2 3.3]} {
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

    multicursor::delete $txt.t -1c

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

    multicursor::delete $txt.t +3c

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

    multicursor::delete $txt.t +3c

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

    multicursor::delete $txt.t +40c

    if {[$txt get 2.0 end-1c] ne " \n "} {
      cleanup "text mismatched after deletion ([$txt get 2.0 end-1c])"
    }
    if {[$txt tag ranges mcursor] ne [list 2.0 2.1 3.0 3.1]} {
      cleanup "mcursor mismatched after deletion ([$txt tag ranges mcursor])"
    }

    # Clean things up
    cleanup

  }

}
