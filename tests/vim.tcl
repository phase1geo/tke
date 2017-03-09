namespace eval vim {

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
          $txtt insert insert $char
        }
      }
    }

  }

  # Verify tab stop setting and getting
  proc run_test1 {} {

    # Initialize the test
    set txtt [initialize].t

    # Get the current tabstop
    set orig_tabstop [indent::get_tabstop $txtt]

    # Set the tabstop
    indent::set_tabstop $txtt 20

    # Get the current tabstop
    if {[indent::get_tabstop $txtt] != 20} {
      cleanup "Tabstop not set to the correct value"
    }

    # Verify that the text widget -tabs value is correct
    if {[$txtt cget -tabs] ne [list [expr 20 * [font measure [$txtt cget -font] 0]] left]} {
      cleanup "Text widget -tabs value is not set correctly"
    }

    # Set the tabstop to the original value
    indent::set_tabstop $txtt $orig_tabstop

    # Get the current tabstop
    if {[indent::get_tabstop $txtt] != $orig_tabstop} {
      cleanup "Tabstop not set to the correct value"
    }

    # Verify that the text widget -tabs value is correct
    if {[$txtt cget -tabs] ne [list [expr $orig_tabstop * [font measure [$txtt cget -font] 0]] left]} {
      cleanup "Text widget -tabs value is not set correctly"
    }

    # Cleanup
    cleanup

  }

  # Verify browsedir Vim option
  proc run_test2 {} {

    # Initialize the text
    set txtt [initialize].t

    foreach type [list last buffer current directory] {

      # Set the browse directory
      if {$type ne "directory"} {
        gui::set_browse_directory $type
      } else {
        gui::set_browse_directory "foobar"
      }

      # Verify that the browse directory is correct
      set dir [gui::get_browse_directory]

      switch $type {
        last      { set expect "" }
        buffer    { set expect "." }
        current   { set expect [pwd] }
        directory { set expect "foobar" }
      }

      if {$dir ne $expect} {
        cleanup "Browse directory type: $type, not expected ($dir)"
      }

    }

    # Cleanup
    cleanup

  }

  # Test the h command
  proc run_test3 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\nthis is good"

    # Move one character to the left
    $txtt mark set insert 2.5
    vim::handle_h $txtt

    if {[$txtt index insert] ne "2.4"} {
      cleanup "Cursor did not move one character to the left ([$txtt index insert])"
    }

    # Verify that we can move by more than one character
    set vim::number($txtt) 2
    vim::handle_h $txtt

    if {[$txtt index insert] ne "2.2"} {
      cleanup "Cursor did not move two characters to the left ([$txtt index insert])"
    }

    # Verify that if we move by more characters than column 0, we don't move past column 0
    set vim::number($txtt) 5
    vim::handle_h $txtt

    if {[$txtt index insert] ne "2.0"} {
      cleanup "Cursor did not stop at column 0 ([$txtt index insert])"
    }

    # Verify that the cursor will not move to the left when we are in column 0
    set vim::number($txtt) ""
    vim::handle_h $txtt

    if {[$txtt index insert] ne "2.0"} {
      cleanup "Cursor moved from column 0 ([$txtt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Verify moving the cursor to the right
  proc run_test4 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\nthis is not bad\nthis is cool"

    # Verify that we can move one cursor to the right
    $txtt mark set insert 2.5
    vim::handle_l $txtt

    if {[$txtt index insert] ne "2.6"} {
      cleanup "Cursor did not move one character to the right ([$txtt index insert])"
    }

    # Verify that we can move more than one character to the right
    set vim::number($txtt) 2
    vim::handle_l $txtt

    if {[$txtt index insert] ne "2.8"} {
      cleanup "Cursor did not move two characters to the right ([$txtt index insert])"
    }

    # Verify that we don't advance past the end of the current line
    set vim::number($txtt) 20
    vim::handle_l $txtt

    if {[$txtt index insert] ne "2.14"} {
      cleanup "Cursor moved past the end of the line ([$txtt index insert])"
    }

    # Verify that we don't move a single character
    set vim::number($txtt) ""
    vim::handle_l $txtt

    if {[$txtt index insert] ne "2.14"} {
      cleanup "Cursor moved past the end of the line ([$txtt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Verify that we can move the cursor up
  proc run_test5 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\ngood\n\nbad\nfoobar\nnice\nbetter"
    $txtt mark set insert 7.0
    vim::adjust_insert $txtt

    if {[$txtt tag ranges dspace] ne [list]} {
      cleanup "The dspace tag was found when it should not be A ([$txtt tag ranges dspace])"
    }

    # Move up by one line
    vim::handle_k $txtt

    if {[$txtt index insert] ne "6.0"} {
      cleanup "Cursor did not move up by one line ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list]} {
      cleanup "The dspace tag was found when it should not be B ([$txtt tag ranges dspace])"
    }

    # Move up by more than one line
    set vim::number($txtt) 2
    vim::handle_k $txtt

    if {[$txtt index insert] ne "4.0"} {
      cleanup "Cursor did not move up by two lines ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list]} {
      cleanup "The dspace tag was found when it should not be C ([$txtt tag ranges dspace])"
    }

    # Move up by one line and verify that a dspace is created
    set vim::number($txtt) ""
    vim::handle_k $txtt

    if {[$txtt index insert] ne "3.0"} {
      cleanup "Cursor did not move up by one line ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list 3.0 3.1]} {
      cleanup "The dspace tag was not found when it should be A ([$txtt tag ranges dspace])"
    }

    # Move up by one more line and verify that dspace is removed
    vim::handle_k $txtt

    if {[$txtt index insert] ne "2.0"} {
      cleanup "Cursor did not move up by one line ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list]} {
      cleanup "The dspace tag was found when it should not be C ([$txtt tag ranges dspace])"
    }

    # Attempt to move up by more than the number specified
    set vim::number($txtt) 5
    vim::handle_k $txtt

    if {[$txtt index insert] ne "1.0"} {
      cleanup "Cursor did not stop at 1.0 ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list 1.0 1.1]} {
      cleanup "The dspace tag was not found when it should be B ([$txtt tag ranges dspace])"
    }

    set vim::number($txtt) ""
    vim::handle_k $txtt

    if {[$txtt index insert] ne "1.0"} {
      cleanup "Cursor did not stop at 1.0 ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list 1.0 1.1]} {
      cleanup "The dspace tag was not found when it should be C ([$txtt tag ranges dspace])"
    }

    # Finally, let's move the cursor up by one character all the way through and verify
    # the column is correct.
    $txtt mark set insert 7.3
    set vim::column($txtt) ""
    vim::adjust_insert $txtt

    if {[$txtt index insert] ne 7.3} {
      cleanup "Starting cursor position is not 7.3 ([$txtt index insert])"
    }

    foreach index [list 6.3 5.3 4.2 3.0 2.3 1.0] {
      vim::handle_k $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Cursor is at incorrect column (expect: $index, actual: [$txtt index insert])"
      }
    }

    # Cleanup
    cleanup

  }

  # Verify J motion
  proc run_test6 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\ngood\nbad\nfoobar\nnice\n\nbetter\n\n"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    if {[$txtt tag ranges dspace] ne [list]} {
      cleanup "The dspace tag was found when it should not be A ([$txtt tag ranges dspace])"
    }

    # Move down down one line
    vim::handle_j $txtt

    if {[$txtt index insert] ne "3.0"} {
      cleanup "Cursor did not move down by one line A ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list]} {
      cleanup "The dspace tag was found when it should not be B ([$txtt tag ranges dspace])"
    }

    # Move down by more than one line
    set vim::number($txtt) 2
    vim::handle_j $txtt

    if {[$txtt index insert] ne "5.0"} {
      cleanup "Cursor did not move down by two lines ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list]} {
      cleanup "The dspace tag was found when it should not be C ([$txtt tag ranges dspace])"
    }

    # Move down by one line and verify that a dspace is created
    set vim::number($txtt) ""
    vim::handle_j $txtt

    if {[$txtt index insert] ne "6.0"} {
      cleanup "Cursor did not move down by one line B ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list 6.0 6.1]} {
      cleanup "The dspace tag was not found when it should be A ([$txtt tag ranges dspace])"
    }

    # Move up by one more line and verify that dspace is removed
    vim::handle_j $txtt

    if {[$txtt index insert] ne "7.0"} {
      cleanup "Cursor did not move down by one line C ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list]} {
      cleanup "The dspace tag was found when it should not be C ([$txtt tag ranges dspace])"
    }

    # Attempt to move up by more than the number specified
    set vim::number($txtt) 5
    vim::handle_j $txtt

    if {[$txtt index insert] ne "9.0"} {
      cleanup "Cursor did not stop at 9.0 ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list 9.0 9.1]} {
      cleanup "The dspace tag was not found when it should be B ([$txtt tag ranges dspace])"
    }

    set vim::number($txtt) ""
    vim::handle_j $txtt

    if {[$txtt index insert] ne "9.0"} {
      cleanup "Cursor did not stop at 9.0 ([$txtt index insert])"
    }
    if {[$txtt tag ranges dspace] ne [list 9.0 9.1]} {
      cleanup "The dspace tag was not found when it should be C ([$txtt tag ranges dspace])"
    }

    # Finally, let's move the cursor up by one character all the way through and verify
    # the column is correct.
    $txtt mark set insert 2.3
    set vim::column($txtt) ""
    vim::adjust_insert $txtt

    if {[$txtt index insert] ne 2.3} {
      cleanup "Starting cursor position is not 2.3 ([$txtt index insert])"
    }

    foreach index [list 3.2 4.3 5.3 6.0 7.3 8.0] {
      vim::handle_j $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Cursor is at incorrect column (expect: $index, actual: [$txtt index insert])"
      }
    }

    # Cleanup
    cleanup

  }

  # Verify beginning/end of line motion
  proc run_test7 {} {

    # Initialize the widgets
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nAnother line"

    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    if {[$txtt index insert] ne "2.5"} {
      cleanup "Insertion cursor did not start at 2.5"
    }

    # Jump to the beginning of the line
    vim::handle_number $txtt 0

    if {[$txtt index insert] ne "2.0"} {
      cleanup "Insertion cursor did not jump to the beginning of the line ([$txtt index insert])"
    }

    # Jump to the end of the line
    vim::handle_dollar $txtt

    if {[$txtt index insert] ne "2.13"} {
      cleanup "Insertion cursor did not jump to the end of the line ([$txtt index insert])"
    }

    # Verify that using a number jumps to the next line down
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    set vim::number($txtt) 2
    vim::handle_dollar $txtt

    if {[$txtt index insert] ne "3.11"} {
      cleanup "Insertion cursor did not stay on the same line, end ([$txtt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Move forward/backward by words
  proc run_test8 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is good\n\nThis is great"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Move forward by one word
    foreach index [list 2.5 2.8 3.0 4.0 4.5 4.8 4.12 4.12] {
      vim::handle_w $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Next word was incorrect ([$txtt index insert])"
      }
    }

    # Move backward by one word
    foreach index [list 4.8 4.5 4.0 2.8 2.5 2.0 1.0 1.0] {
      vim::handle_b $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Previous word was incorrect ([$txtt index insert])"
      }
    }

    # Move forward by two words
    set vim::number($txtt) 2
    foreach index [list 2.5 3.0 4.5 4.12 4.12] {
      vim::handle_w $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Next word was incorrect ([$txtt index insert])"
      }
    }

    # Move backward by two words
    foreach index [list 4.5 2.8 2.0 1.0 1.0] {
      vim::handle_b $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Previous word was incorrect ([$txtt index insert])"
      }
    }

    # Cleanup
    cleanup

  }

  # Verify firstword motion
  proc run_test9 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\n apples\n\ngrapes\n      bananas\n  milk\n\n    soup"

    # Verify the current line firstword variety
    foreach index [list 1.0 2.1 3.0 4.0 5.6 6.2 7.0 8.4] {
      $txtt mark set insert "$index linestart"
      vim::adjust_insert $txtt
      set vim::number($txtt) [expr int( rand() * 10 )]   ;# Make sure that the number doesn't matter
      vim::handle_asciicircum $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Current firstword is at incorrect position ([$txtt index insert])"
      }
    }

    $txtt mark set insert 1.0
    vim::adjust_insert $txtt
    set vim::number($txtt) ""

    # Test nextfirst (one line at a time)
    foreach index [list 2.1 3.0 4.0 5.6 6.2 7.0 8.4 8.4] {
      vim::handle_Return $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Next firstword is at incorrect position ([$txtt index insert])"
      }
    }

    # Test prevfirst (one line at a time)
    foreach index [list 7.0 6.2 5.6 4.0 3.0 2.1 1.0 1.0] {
      vim::handle_minus $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Previous firstword is at incorrect position ([$txtt index insert])"
      }
    }

    set vim::number($txtt) 2

    # Test nextfirst (two lines at a time)
    foreach index [list 3.0 5.6 7.0 8.4] {
      vim::handle_Return $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Next firstword is at incorrect position ([$txtt index insert])"
      }
    }

    # Test prevfirst (two lines at a time)
    foreach index [list 6.2 4.0 2.1 1.0] {
      vim::handle_minus $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Previous firstword is at incorrect position ([$txtt index insert])"
      }
    }

    # Cleanup
    cleanup

  }

  # Next/previous character motion
  proc run_test10 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\ngood\n\ngreat"

    $txtt mark set insert 1.0
    vim::adjust_insert $txtt

    # Move forward through the document, one character at a time
    foreach index [list 2.0 2.1 2.2 2.3 3.0 4.0 4.1 4.2 4.3 4.4 4.4] {
      vim::handle_space $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Moving one character forward did not work properly ([$txtt index insert], $index)"
      }
    }

    # Move backward through the document, one character at a time
    foreach index [list 4.3 4.2 4.1 4.0 3.0 2.3 2.2 2.1 2.0 1.0 1.0] {
      vim::handle_BackSpace $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Moving one character backward did not work properly ([$txtt index insert])"
      }
    }

    # Move forward 2 characters at a time
    set vim::number($txtt) 2
    foreach index [list 2.1 2.3 4.0 4.2 4.4 4.4] {
      vim::handle_space $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Moving two characters forward did not work properly ([$txtt index insert])"
      }
    }

    # Move backward through the document, one character at a time
    foreach index [list 4.2 4.0 2.3 2.1 1.0 1.0] {
      vim::handle_BackSpace $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Moving two characters backward did not work properly ([$txtt index insert])"
      }
    }

    # Clean things up
    cleanup

  }

  # Verify top, middle, bottom of screen
  proc run_test11 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end [string repeat "\n" 100]

    $txtt mark set insert 10.0
    vim::adjust_insert $txtt

    if {[$txtt index insert] ne "10.0"} {
      cleanup "Starting insertion point was incorrect ([$txtt index insert])"
    }

    # Jump the cursor to the top of the screen
    vim::handle_H $txtt
    if {[$txtt index insert] ne [$txtt index @0,0]} {
      cleanup "Top index was incorrect ([$txtt index insert])"
    }

    # Jump to the middle
    vim::handle_M $txtt
    if {[$txtt index insert] ne [$txtt index @0,[expr [winfo reqheight $txtt] / 2]]} {
      cleanup "Middle index was incorrect ([$txtt index insert])"
    }

    # Jump to the bottom
    vim::handle_L $txtt
    if {[$txtt index insert] ne [$txtt index @0,[winfo reqheight $txtt]]} {
      cleanup "Bottom index was incorrect ([$txtt index insert])"
    }

    # Jump to the first line
    vim::handle_g $txtt
    vim::handle_g $txtt
    if {[$txtt index insert] ne "1.0"} {
      cleanup "Top of file was incorrect ([$txtt index insert])"
    }

    # Jump to the last line
    vim::handle_G $txtt
    if {[$txtt index insert] ne "101.0"} {
      cleanup "Bottom of file was incorrect ([$txtt index insert])"
    }

    # Jump to a specific line
    set vim::number($txtt) 12
    vim::handle_G $txtt
    if {[$txtt index insert] ne "12.0"} {
      cleanup "Jumping to a specific line was incorrect ([$txtt index insert])"
    }

    # Jump to a line percentage
    set vim::number($txtt) 20
    vim::handle_percent $txtt
    if {[$txtt index insert] ne "21.0"} {
      cleanup "Jumping to a percentage of the file was incorrect ([$txtt index insert])"
    }

    # Clean things up
    cleanup

  }

  # Character search motion
  proc run_test12 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is really strong\n\nBut I am stronger"

    # Attempt to find a character that does not exist
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt
    vim::handle_f $txtt
    vim::handle_any $txtt 120 x x
    if {[$txtt index insert] ne "2.0"} {
      cleanup "We should not have found anything with f ([$txtt index insert])"
    }

    # Search forward for the first l
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt
    vim::handle_f $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.11"} {
      cleanup "Search for next l is incorrect f ([$txtt index insert])"
    }

    # Search forward for the second l
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt
    vim::handle_number $txtt 2
    vim::handle_f $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.12"} {
      cleanup "Search for second l is incorrect f ([$txtt index insert])"
    }

    # Search forward for the third l
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt
    vim::handle_number $txtt 3
    vim::handle_f $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.0"} {
      cleanup "Search for third l is incorrect f ([$txtt index insert])"
    }

    # Attempt to find a character that does not exist
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt
    vim::handle_t $txtt
    vim::handle_any $txtt 120 x x
    if {[$txtt index insert] ne "2.0"} {
      cleanup "We should not have found anything with t ([$txtt index insert])"
    }

    # Search forward for the first l
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt
    vim::handle_t $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.10"} {
      cleanup "Search for next l is incorrect t ([$txtt index insert])"
    }

    # Search forward for the second l
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt
    vim::handle_number $txtt 2
    vim::handle_t $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.11"} {
      cleanup "Search for second l is incorrect t ([$txtt index insert])"
    }

    # Search forward for the third l
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt
    vim::handle_number $txtt 3
    vim::handle_t $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.0"} {
      cleanup "Search for third l is incorrect t ([$txtt index insert])"
    }

    # Attempt to find a character that does not exist
    $txtt mark set insert 2.end
    vim::adjust_insert $txtt
    vim::handle_F $txtt
    vim::handle_any $txtt 120 x x
    if {[$txtt index insert] ne "2.20"} {
      cleanup "We should not have found anything with F ([$txtt index insert])"
    }

    # Search forward for the first l
    $txtt mark set insert 2.end
    vim::adjust_insert $txtt
    vim::handle_F $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.12"} {
      cleanup "Search for next l is incorrect F ([$txtt index insert])"
    }

    # Search forward for the second l
    $txtt mark set insert 2.end
    vim::adjust_insert $txtt
    vim::handle_number $txtt 2
    vim::handle_F $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.11"} {
      cleanup "Search for second l is incorrect F ([$txtt index insert])"
    }

    # Search forward for the third l
    $txtt mark set insert 2.end
    vim::adjust_insert $txtt
    vim::handle_number $txtt 3
    vim::handle_F $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.20"} {
      cleanup "Search for third l is incorrect F ([$txtt index insert])"
    }

    # Attempt to find a character that does not exist
    $txtt mark set insert 2.end
    vim::adjust_insert $txtt
    vim::handle_T $txtt
    vim::handle_any $txtt 120 x x
    if {[$txtt index insert] ne "2.20"} {
      cleanup "We should not have found anything with T ([$txtt index insert])"
    }

    # Search forward for the first l
    $txtt mark set insert 2.end
    vim::adjust_insert $txtt
    vim::handle_T $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.13"} {
      cleanup "Search for next l is incorrect T ([$txtt index insert])"
    }

    # Search forward for the second l
    $txtt mark set insert 2.end
    vim::adjust_insert $txtt
    vim::handle_number $txtt 2
    vim::handle_T $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.12"} {
      cleanup "Search for second l is incorrect T ([$txtt index insert])"
    }

    # Search forward for the third l
    $txtt mark set insert 2.end
    vim::adjust_insert $txtt
    vim::handle_number $txtt 3
    vim::handle_T $txtt
    vim::handle_any $txtt 108 l l
    if {[$txtt index insert] ne "2.20"} {
      cleanup "Search for third l is incorrect T ([$txtt index insert])"
    }

    # Clean things up
    cleanup

  }

  # Verify the bar command
  proc run_test13 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is something"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Move to a valid column
    vim::handle_number $txtt 7
    vim::handle_any $txtt 124 | bar
    if {[$txtt index insert] ne "2.6"} {
      cleanup "Move to column 7 did not work ([$txtt index insert])"
    }

    # Move to column 0
    vim::handle_number $txtt 1
    vim::handle_any $txtt 124 | bar
    if {[$txtt index insert] ne "2.0"} {
      cleanup "Move to column 0 did not work ([$txtt index insert])"
    }

    # Attempt to move to an invalidate column
    vim::handle_number $txtt 2
    vim::handle_number $txtt 0
    vim::handle_any $txtt 124 | bar
    if {[$txtt index insert] ne "2.16"} {
      cleanup "Move to column which exceeds line did not move to end of line ([$txtt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Verify up/down motions over elided text
  proc run_test14 {} {

    # Initialize
    set txtt [initialize].t

    # Insert a line that we can code fold
    $txtt insert end "\nif {\$foocar} {\n  set c 0\n}\n# Another comment"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Close the fold
    folding::close_all_folds [winfo parent $txtt]

    # Move up/down
    vim::handle_j $txtt
    if {[$txtt index insert] ne "4.0"} {
      cleanup "Move j over ellided text did not work properly ([$txtt index insert])"
    }

    vim::handle_k $txtt
    if {[$txtt index insert] ne "2.0"} {
      cleanup "Move k over ellided text did not work properly ([$txtt index insert])"
    }

    vim::handle_Down $txtt
    if {[$txtt index insert] ne "4.0"} {
      cleanup "Move down over ellided text did not work properly ([$txtt index insert])"
    }

    vim::handle_Up $txtt
    if {[$txtt index insert] ne "2.0"} {
      cleanup "Move up over ellided text did not work properly ([$txtt index insert])"
    }

    vim::handle_Return $txtt
    if {[$txtt index insert] ne "4.0"} {
      cleanup "Move return over ellided text did not work ([$txtt index insert])"
    }

    vim::handle_minus $txtt
    if {[$txtt index insert] ne "2.0"} {
      cleanup "Move minus over ellided text did not work ([$txtt index insert])"
    }

    # Move left/right by char
    vim::handle_dollar $txtt
    if {[$txtt index insert] ne "2.13"} {
      cleanup "Move to end of line did not work ([$txtt index insert])"
    }

    vim::handle_space $txtt
    if {[$txtt index insert] ne "4.0"} {
      cleanup "Move next char over ellided text did not work ([$txtt index insert])"
    }

    vim::handle_BackSpace $txtt
    if {[$txtt index insert] ne "2.13"} {
      cleanup "Move previous char over ellided text did not work ([$txtt index insert])"
    }

    # Move left/right by word
    vim::handle_w $txtt
    if {[$txtt index insert] ne "4.0"} {
      cleanup "Move next word over ellided text did not work ([$txtt index insert])"
    }

    vim::handle_b $txtt
    if {[$txtt index insert] ne "2.13"} {
      cleanup "Move previous word over ellided text did not work ([$txtt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Test left/right motion with elided text
  proc run_test15 {} {

    # Initialize
    set txtt [initialize].t

    # Set the current language to Markdown so that we will have meta characters
    syntax::set_current_language "Markdown"

    # Hide meta characters
    syntax::set_meta_visibility [winfo parent $txtt] 0

    # Insert a line that we can code fold
    $txtt insert end "\nNice **bold** text"
    $txtt mark set insert 2.4

    vim::handle_l $txtt
    if {[$txtt index insert] ne "2.7"} {
      cleanup "One l did not work ([$txtt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Test motion with character selection (inclusive selection mode)
  proc run_test16 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to inclusive
    vim::do_set_selection "inclusive"

    $txtt insert end "\nThis is so so good\n\nThis is great"
    $txtt mark set insert 2.0

    vim::handle_v $txtt
    if {[$txtt tag ranges sel] ne [list 2.0 2.1]} {
      cleanup "Character selection did not work ([$txtt tag ranges sel])"
    }

    vim::handle_any $txtt 108 l l
    if {[$txtt tag ranges sel] ne [list 2.0 2.2]} {
      cleanup "Right one did not work ([$txtt tag ranges sel])"
    }

    vim::handle_number $txtt 2
    vim::handle_any $txtt 108 l l
    if {[$txtt tag ranges sel] ne [list 2.0 2.4]} {
      cleanup "Right two did not work ([$txtt tag ranges sel])"
    }

    vim::handle_any $txtt 32 " " space
    if {[$txtt tag ranges sel] ne [list 2.0 2.5]} {
      cleanup "Space one did not work ([$txtt tag ranges sel])"
    }

    vim::handle_number $txtt 2
    vim::handle_any $txtt 32 " " space
    if {[$txtt tag ranges sel] ne [list 2.0 2.7]} {
      cleanup "Space two did not work ([$txtt tag ranges sel])"
    }

    vim::handle_any $txtt 119 w w
    if {[$txtt tag ranges sel] ne [list 2.0 2.9]} {
      cleanup "One w did not work ([$txtt tag ranges sel])"
    }

    vim::handle_number $txtt 2
    vim::handle_any $txtt 119 w w
    if {[$txtt tag ranges sel] ne [list 2.0 2.15]} {
      cleanup "Two w did not work ([$txtt tag ranges sel])"
    }

    vim::handle_any $txtt 36 \$ dollar
    if {[$txtt tag ranges sel] ne [list 2.0 2.18]} {
      cleanup "Dollar did not work ([$txtt tag ranges sel])"
    }

    vim::handle_any $txtt 48 0 0
    if {[$txtt tag ranges sel] ne [list 2.0 2.1]} {
      cleanup "Zero did not work ([$txtt tag ranges sel])"
    }

    vim::handle_any $txtt 106 j j
    if {[$txtt tag ranges sel] ne [list 2.0 3.1]} {
      cleanup "One j did not work ([$txtt tag ranges sel])"
    }

    vim::handle_any $txtt [utils::sym2code Return] \n Return
    if {[$txtt tag ranges sel] ne [list 2.0 4.1]} {
      cleanup "One return did not work ([$txtt tag ranges sel])"
    }

    # Cleanup
    cleanup

  }

  # Test motion with character selection (exclusive selection mode)
  proc run_test17 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to exclusive
    vim::do_set_selection "exclusive"

    $txtt insert end "\nThis is good\n\nThis is great"
    $txtt mark set insert 2.0

    vim::handle_v $txtt
    if {[$txtt tag ranges sel] ne [list]} {
      cleanup "Character selection did not work ([$txtt tag ranges sel])"
    }

    vim::handle_l $txtt
    if {[$txtt tag ranges sel] ne [list 2.0 2.1]} {
      cleanup "Right one did not work ([$txtt tag ranges sel])"
    }

    # Cleanup
    cleanup

  }

  # Verify the period (.) Vim command
  proc run_test18 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\n\n"
    $txtt mark set insert 1.0
    vim::adjust_insert $txtt

    # Put the buffer into insertion mode
    enter $txtt i

    set str "`1234567890-=qwertyuiop\[\]\\asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP\{\}|ASDFGHJKL:\"ZXCVBNM<>? "

    # Insert every printable character
    foreach char [split $str {}] {
      set keysym  [utils::string_to_keysym $char]
      set keycode [utils::sym2code $keysym]
      if {![vim::handle_any $txtt $keycode $char $keysym]} {
        $txtt insert insert $char
      }
    }

    # Get out of insertion mode
    enter $txtt Escape

    if {[$txtt get 1.0 1.end] ne $str} {
      cleanup "Initial insertion did not work ([$txtt get 1.0 1.end])"
    }

    # Move the cursor to line to and repeat with the . key
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Repeat the last insert
    enter $txtt period
    if {[$txtt get 2.0 2.end] ne $str} {
      cleanup "Repeat did not work ([$txtt get 2.0 2.end])"
    }

    # Cleanup
    cleanup

  }

}
