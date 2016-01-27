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

  # Verify isEscaped functionality
  proc run_test4 {} {

    set txt [initialize]

    for {set i 1} {$i <= 8} {incr i} {
      $txt insert end "\n[string repeat \\ $i]word"
      if {[$txt get 2.$i end-1c] ne "word"} {
        cleanup "Test index is not correct ([$txt get 2.$i end-1c])"
      }
      if {[expr $i % 2] != [ctext::isEscaped $txt 2.$i]} {
        cleanup "escaped == $i not matching expected"
      }
      $txt delete 1.0 end
    }

    $txt insert end "\n\\ \\word"
    if {![ctext::isEscaped $txt 2.3]} {
      cleanup "split escapes are not being parsed properly"
    }

    cleanup

  }

  # Verify inDoubleQuote, inString and inCommentString functionality for double quotes
  proc run_test5 {} {

    set txt [initialize]
    syntax::set_language $txt "C++"

    $txt insert end "\nthis \"is a\" string"

    if {[$txt tag ranges _dString] ne [list 2.5 2.11]} {
      cleanup "tag does not match expected value"
    }

    foreach procedure [list inDoubleQuote inString inCommentString] {
      foreach {index expect} [list 2.0 0 2.4 0 2.5 1 2.6 1 2.9 1 2.10 1 2.11 0] {
        set range ""
        if {[ctext::$procedure $txt $index range] != $expect} {
          cleanup "$procedure: index $index did not match expected value ($expect)"
        } elseif {!$expect && ($range ne "")} {
          cleanup "$procedure: index $index returned a range when it should not have"
        } elseif {$expect && ($range ne [list 2.5 2.11])} {
          cleanup "$procedure: index $index returned a bad range ($range)"
        }
      }
    }

    cleanup

  }

  # Verify inSingleQuote, inString and inCommentString functionality for single quotes
  proc run_test6 {} {

    set txt [initialize]
    syntax::set_language $txt "C++"

    $txt insert end "\nthis 'is a' string"

    if {[$txt tag ranges _sString] ne [list 2.5 2.11]} {
      cleanup "tag does not match expected value"
    }

    foreach procedure [list inSingleQuote inString inCommentString] {
      foreach {index expect} [list 2.0 0 2.4 0 2.5 1 2.6 1 2.9 1 2.10 1 2.11 0] {
        set range ""
        if {[ctext::$procedure $txt $index range] != $expect} {
          cleanup "$procedure: index $index did not match expected value ($expect)"
        } elseif {!$expect && ($range ne "")} {
          cleanup "$procedure: index $index returned a range when it should not have"
        } elseif {$expect && ($range ne [list 2.5 2.11])} {
          cleanup "$procedure: index $index returned a bad range ($range)"
        }
      }
    }

    cleanup

  }

  # Verify inLineComment, inComment and inCommentString functionality for line comments
  proc run_test7 {} {

    set txt [initialize]
    syntax::set_language $txt "C++"

    $txt insert end "\nthis // is a line\ncomment"

    if {[$txt tag ranges _lComment] ne [list 2.5 2.17]} {
      cleanup "tag does not match expected value"
    }

    foreach procedure [list inLineComment inComment inCommentString] {
      foreach {index expect} [list 2.0 0 2.4 0 2.5 1 2.6 1 2.7 1 2.16 1 2.end 0 3.0 0] {
        set range ""
        if {[ctext::$procedure $txt $index range] != $expect} {
          cleanup "$procedure: index $index did not match expected value ($expect)"
        } elseif {!$expect && ($range ne "")} {
          cleanup "$procedure: index $index returned a range when it should not have"
        } elseif {$expect && ($range ne [list 2.5 2.17])} {
          cleanup "$procedure: index $index returned a bad range ($range)"
        }
      }
    }

    cleanup

  }

  # Verify inBlockComment, inComment and inCommentString functionality for block comments
  proc run_test8 {} {

    set txt [initialize]
    syntax::set_language $txt "C++"

    $txt insert end "\nthis /* is a block */ comment"

    if {[$txt tag ranges _cComment] ne [list 2.5 2.21]} {
      cleanup "tag does not match expected value ($range)"
    }

    foreach procedure [list inBlockComment inComment inCommentString] {
      foreach {index expect} [list 2.0 0 2.4 0 2.5 1 2.6 1 2.7 1 2.18 1 2.19 1 2.20 1 2.21 0] {
        set range ""
        if {[ctext::$procedure $txt $index range] != $expect} {
          cleanup "$procedure: index $index did not match expected value ($expect)"
        } elseif {!$expect && ($range ne "")} {
          cleanup "$procedure: index $index returned a range when it should not have"
        } elseif {$expect && ($range ne [list 2.5 2.21])} {
          cleanup "$procedure: index $index returned a bad range ($range)"
        }
      }
    }

    cleanup

  }

  # Verify inTripleQuote, inString and inCommentString functionality for triple quote
  proc run_test9 {} {

    set txt [initialize]
    syntax::set_language $txt "Python"

    $txt insert end "\nthis \"\"\"is a triple\"\"\" quote"

    if {[$txt tag ranges _tString] ne [list 2.5 2.22]} {
      cleanup "tag does not match expected value ($range)"
    }

    foreach procedure [list inTripleQuote inString inCommentString] {
      foreach {index expect} [list 2.0 0 2.4 0 2.5 1 2.6 1 2.7 1 2.8 1 2.18 1 2.19 1 2.20 1 2.21 1 2.22 0] {
        set range ""
        if {[ctext::$procedure $txt $index range] != $expect} {
          cleanup "$procedure: index $index did not match expected value ($expect)"
        } elseif {!$expect && ($range ne "")} {
          cleanup "$procedure: index $index returned a range when it should not have"
        } elseif {$expect && ($range ne [list 2.5 2.22])} {
          cleanup "$procedure: index $index returned a bad range ($range)"
        }
      }
    }

    cleanup

  }

}
