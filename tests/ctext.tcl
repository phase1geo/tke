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

    # Set the language to None to disable syntax highlighting
    syntax::set_language $txt "None"

    # Insert a string
    $txt insert end "\n\"This is a string\""

    # Verify that the string is tagged
    if {[$txt tag ranges _dString] ne [list 2.0 2.18]} {
      cleanup "String was not properly tagged"
    }

    # Verify that a character within the string is considered to be in a string
    if {![ctext::isCommentString $txt 1.5]} {
      cleanup "character 5 is not considered to be within a string"
    }

  }

}
