namespace eval ctext {

  # Verify that when two strings are entered back-to-back and a character is inserted
  # in-between the strings, the character does not have the _dString tag applied to it.
  proc run_test1 {} {

    # Add a new Tcl file
    set tab [gui::add_new_file end]
    set txt [gui::get_info $tab tab txt]
    syntax::set_language $txt "Tcl"

    # Insert two strings
    $txt insert end "\n\"String 1\"\"String 2\""

    # Verify that all characters contain the _dString tag
    if {[$txt tag ranges _dString] ne [list 2.0 2.20]} {
      return -code error "Inserted strings are missing _dString tag"
    }

    # Now insert one character between the two strings
    $txt insert 2.10 "a"

    # Verify that the newly inserted character was not tagged with _dString
    if {[lsearch [$txt tag names 2.10] _dString] != -1} {
      return -code error "Inserted character marked with _dString tag"
    }

    # Close the tab
    gui::close_tab {} $tab -check 0

  }

}
