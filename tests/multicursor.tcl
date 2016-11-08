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

}
