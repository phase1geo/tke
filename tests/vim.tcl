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

  proc run_test8 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is good\n\nThis is great"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    foreach index [list 2.5 2.8 4.0 4.5 4.8 4.8] {
      vim::handle_w $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Next word was incorrect ([$txtt index insert])"
      }
    }

    foreach index [list 4.5 4.0 2.8 2.5 2.0 2.0] {
      vim::handle_b $txtt
      if {[$txtt index insert] ne $index} {
        cleanup "Previous word was incorrect ([$txtt index insert])"
      }
    }

    # Cleanup
    cleanup

  }

}
