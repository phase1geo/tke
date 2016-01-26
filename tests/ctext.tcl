namespace eval ctext {

  variable current_tab

  ######################################################################
  # Initializes the diagnostic and returns the pathname of the added
  # text widget.
  proc initialize {} {

    variable current_tab

    # Add a new tab
    set current_tab [gui::add_new_file end]

    # Get the current text widget
    set txt [gui::get_info $current_tab tab txt]

    # Set the language to Tcl
    syntax::set_language $txt "Tcl"

    return $txt

  }

  ######################################################################
  # Handles diagnostic cleanup and fails if there is a valid fail message.
  proc cleanup {{fail_msg ""}} {

    variable current_tab

    # Close the tab
    gui::close_tab {} $current_tab -check 0

    # If there was a fail message, exit with a failure
    if {$fail_msg ne ""} {
      return -code error $fail_msg
    }

  }

  # Verify that when two strings are entered back-to-back and a character is inserted
  # in-between the strings, the character does not have the _dString tag applied to it.
  proc run_test1 {} {

    # Initialize the test
    set txt [initialize]

    # Insert two strings
    $txt insert end "\n\"String 1\"\"String 2\""

    # Verify that all characters contain the _dString tag
    if {[$txt tag ranges _dString] ne [list 2.0 2.20]} {
      cleanup "Inserted strings are missing _dString tag"
    }

    # Now insert one character between the two strings
    $txt insert 2.10 "a"

    # Verify that the newly inserted character was not tagged with _dString
    if {[lsearch [$txt tag names 2.10] _dString] != -1} {
      cleanup "Inserted character marked with _dString tag"
    }

    # Cleanup the simulator
    cleanup

  }

  # Verify that strings are tagged even if syntax highlighting is disabled
  proc run_test2 {} {

    # Initialize the test
    set txt [initialize]

    # Turn of syntax highlighting
    $txt configure -highlight 0

    # Insert a string
    $txt insert end "\n\"This is a string\""

    # Verify that the string is tagged
    if {[$txt tag ranges _dString] ne [list 2.0 2.18]} {
      cleanup "String was not properly tagged"
    }

    # Verify that a character within the string is considered to be in a string
    if {![ctext::inCommentString $txt 2.5]} {
      cleanup "Character 5 is not considered to be within a string"
    }

    # Cleanup the test
    cleanup

  }

  # Verify that bracket tagging occurs even if syntax highlighting is disabled.
  proc run_test3 {} {

    # Initialize the test
    set txt [initialize]

    # Turn of syntax highlighting
    $txt configure -highlight 0

    # Insert a string with a bracket
    $txt insert end "\nset foobar \[barfoo\]"

    # Verify that the brackets are tagged
    if {([$txt tag ranges _squareL] ne [list 2.11 2.12]) ||
        ([$txt tag ranges _squareR] ne [list 2.18 2.19])} {
      cleanup "Brackets were not properly tagged"
    }

    # Cleanup the test
    cleanup

  }

}
