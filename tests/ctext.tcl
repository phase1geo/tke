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
    if {[$txt tag ranges _dString0] ne [list 2.0 2.10]} {
      cleanup "Inserted strings are missing _dString0 tag"
    }
    if {[$txt tag ranges _dString1] ne [list 2.10 2.20]} {
      cleanup "Inserted strings are missing _dString1 tag"
    }

    # Now insert one character between the two strings
    $txt insert 2.10 "a"

    # Verify that the newly inserted character was not tagged with _dString
    if {[lsearch -glob [$txt tag names 2.10] _dString*] != -1} {
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
    if {[$txt tag ranges _dString0] ne [list 2.0 2.18]} {
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

    if {[$txt tag ranges _dString0] ne [list 2.5 2.11]} {
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

    if {[$txt tag ranges _sString0] ne [list 2.5 2.11]} {
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

    if {[$txt tag ranges _lComment] ne [list 2.5 3.0]} {
      cleanup "tag does not match expected value ([$txt tag ranges _lComment])"
    }

    foreach procedure [list inLineComment inComment inCommentString] {
      foreach {index expect} [list 2.0 0 2.4 0 2.5 1 2.6 1 2.7 1 2.16 1 2.end 1 3.0 0] {
        set range ""
        if {[ctext::$procedure $txt $index range] != $expect} {
          cleanup "$procedure: index $index did not match expected value ($expect)"
        } elseif {!$expect && ($range ne "")} {
          cleanup "$procedure: index $index returned a range when it should not have"
        } elseif {$expect && ($range ne [list 2.5 3.0])} {
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

    if {[$txt tag ranges _cComment0] ne [list 2.5 2.21]} {
      cleanup "cComment0 tag does not match expected value"
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

  # Verify the clipboard append command
  proc run_test10 {} {

    set txt [initialize]

    $txt insert end "\nthis should be pasted"

    clipboard clear

    $txt append 2.0 2.4
    if {[clipboard get] ne "this"} {
      cleanup "multi-character append failed"
    }
    $txt append 2.4
    if {[clipboard get] ne "this "} {
      cleanup "single character append failed"
    }
    $txt append
    if {[clipboard get] ne "this "} {
      cleanup "bad selection append failed"
    }
    $txt tag add sel 2.5 2.11
    $txt append
    if {[clipboard get] ne "this should"} {
      cleanup "selection append failed"
    }

    cleanup

  }

  # Verify the cget and configure commands
  proc run_test11 {} {

    set txt [initialize]

    # Verify cget for ctext-specific options
    if {![$txt cget -highlight]} {
      cleanup "cget -highlight did not return a value of 1"
    }
    $txt configure -highlight 0
    if {[$txt cget -highlight]} {
      cleanup "cget -highlight returned a value of 1 after being set to 0"
    }
    $txt configure -highlight 1
    if {![$txt cget -highlight]} {
      cleanup "cget -highlight returned a value of 0 after being set to 1"
    }

    # Verify cget for text options
    if {[$txt cget -relief] ne "flat"} {
      cleanup "cget -relief did not return a value of flat ([$txt cget -relief])"
    }
    $txt configure -relief "raised"
    if {[$txt cget -relief] ne "raised"} {
      cleanup "cget -relief did not return a value of raised after being set to it"
    }
    $txt configure -relief "flat"
    if {[$txt cget -relief] ne "flat"} {
      cleanup "cget -relief did not return a value of flat after being set to it"
    }

    cleanup

  }

  # Verify other flavors of configure
  proc run_test12 {} {

    set txt  [initialize]
    set opts [$txt configure]
    set len  [llength $opts]

    if {$len != 71} {
      cleanup "Missing options from configure return with no options ($len)"
    }

    # Verify option that belongs to ctext only
    set index [lsearch -index 0 $opts -autoseparators]
    if {$index == -1} {
      cleanup "Missing -autoseparators option from configure return"
    }
    if {[lindex $opts $index] ne [list -autoseparators 0]} {
      cleanup "Miscompare on -autoseparators return value"
    }
    if {[$txt configure -autoseparators] ne [list -autoseparators 0]} {
      cleanup "Miscompare on configure -autoseparators return value"
    }

    # Verify option t hat belongs to text
    set index [lsearch -index 0 $opts -relief]
    if {$index == -1} {
      cleanup "Missing -relief option from configure return"
    }
    foreach {i value} [list 0 -relief 1 relief 2 Relief 4 flat] {
      if {[lindex $opts $index $i] ne $value} {
        cleanup "Miscompare on -relief $i return value ([lindex $opts $index $i])"
      }
    }
    foreach {i value} [list 0 -relief 1 relief 2 Relief 4 flat] {
      if {[lindex [$txt configure -relief] $i] ne $value} {
        cleanup "Miscompare on configure -relief $i return value ([$txt configure -relief])"
      }
    }

    cleanup

  }

  # Verify the copy command
  proc run_test13 {} {

    set txt [initialize]

    clipboard append -displayof $txt "foobar"

    # Perform copy operation without selection
    $txt insert end "\nThis is a really good line"
    $txt mark set insert 2.2
    $txt copy
    if {[clipboard get -displayof $txt] ne "This is a really good line\n"} {
      cleanup "Copy operation failed when no selection occurs ([clipboard get -displayof $txt])"
    }
    if {[$txt get 2.0 2.end] ne "This is a really good line"} {
      cleanup "Copy operation without selection changed the text ([$txt get 2.0 2.end])"
    }

    clipboard append -displayof $txt "foobar"

    # Perform copy operation with selection
    $txt tag add sel 2.0 2.4
    $txt copy
    if {[clipboard get -displayof $txt] ne "This"} {
      cleanup "Copy operation failed with selection ([clipboard get -displayof $txt])"
    }
    if {[$txt get 2.0 2.end] ne "This is a really good line"} {
      cleanup "Copy operation without selection changed the text ([$txt get 2.0 2.end])"
    }

    cleanup

  }

  # Verify the cut command
  proc run_test14 {} {

    set txt [initialize]

    clipboard append -displayof $txt "foobar"

    # Perform cut operation without selection
    $txt insert end "\nThis is a really good line\nAnd this is good too"
    $txt mark set insert 2.2
    $txt cut
    if {[clipboard get -displayof $txt] ne "This is a really good line\n"} {
      cleanup "Cut operation failed when no selection occurs ([clipboard get -displayof $txt])"
    }
    if {[$txt get 2.0 2.end] ne "And this is good too"} {
      cleanup "Cut operation without selection changed the text ([$txt get 2.0 2.end])"
    }

    clipboard append -displayof $txt "foobar"

    # Perform cut operation with selection
    $txt delete 1.0 end
    $txt insert end "\nThis is a really good line\nAnd this is good too"
    $txt tag add sel 2.0 2.4
    $txt cut
    if {[clipboard get -displayof $txt] ne "This"} {
      cleanup "Cut operation failed with selection ([clipboard get -displayof $txt])"
    }
    if {[$txt get 2.0 2.end] ne " is a really good line"} {
      cleanup "Cut operation without selection changed the text ([$txt get 2.0 2.end])"
    }

    cleanup

  }

  # Verify the delete command
  proc run_test15 {} {

    set txt [initialize]

    $txt insert end "\nset foobar \"good\""

    if {[$txt tag ranges _keywords] ne [list 2.0 2.3]} {
      cleanup "set keyword was not tagged"
    }
    if {[$txt tag ranges _dString0] ne [list 2.11 2.17]} {
      cleanup "string was not tagged"
    }
    $txt delete 2.0
    if {[$txt tag ranges _keywords] ne [list]} {
      cleanup "set keyword was still tagged after character deleted"
    }
    if {[$txt get 2.0 2.end] ne "et foobar \"good\""} {
      cleanup "text content not correct after s removal"
    }
    $txt delete 2.10
    if {[$txt tag ranges _dString0] ne [list 2.14 3.0]} {
      cleanup "string was still tagged after quote deleted"
    }
    if {[$txt get 2.0 2.end] ne "et foobar good\""} {
      cleanup "text content not correct after quote removal"
    }
    $txt delete 1.0 end
    if {[$txt get 1.0 end-1c] ne ""} {
      cleanup "text not removed"
    }
    if {[$txt tag ranges _dString0] ne [list]} {
      cleanup "string still exists after wiping the text"
    }

    $txt insert end "\nset foobar \"good\""

    $txt delete 2.2 2.5
    if {[$txt get 2.0 2.end] ne "seoobar \"good\""} {
      cleanup "text content not correct after set removal"
    }
    if {[$txt tag ranges _keywords] ne [list]} {
      cleanup "set keyword tag still exists after deleting a portion of it"
    }

    $txt delete 1.0 end
    $txt insert end "\nset this \\\\{is good}"

    if {[$txt tag ranges _curlyL] ne [list 2.11 2.12]} {
      cleanup "left curly bracket tag is missing"
    }
    if {[$txt tag ranges _curlyR] ne [list 2.19 2.20]} {
      cleanup "right curly bracket tag is missing"
    }
    if {[$txt tag ranges _escape] ne [list 2.9 2.10]} {
      cleanup "escape character tag is missing"
    }

    $txt delete 2.9
    if {[$txt tag ranges _escape] ne [list 2.9 2.10]} {
      cleanup "escape character tag is missing after deletion"
    }
    if {[$txt tag ranges _curlyL] ne [list]} {
      cleanup "left curly bracket tag still exists"
    }

    $txt delete 2.9
    if {[$txt tag ranges _escape] ne [list]} {
      cleanup "escape character exists when it was deleted"
    }
    if {[$txt tag ranges _curlyL] ne [list 2.9 2.10]} {
      cleanup "left curly bracket is missing even though it is not escaped"
    }

    $txt delete 2.9
    if {[$txt tag ranges _curlyL] ne [list]} {
      cleanup "left curly bracket tag exists after it has been deleted"
    }

    cleanup

  }

  # Verify the fastdelete command
  proc run_test16 {} {

    set txt [initialize]

    $txt insert end "\nThis is some text"

    if {[$txt get 2.0 2.end] ne "This is some text"} {
      cleanup "Default text does not match expected"
    }

    $txt fastdelete 2.0
    if {[$txt get 2.0 2.end] ne "his is some text"} {
      cleanup "Single character deletion did not work"
    }

    $txt fastdelete 2.0 2.2
    if {[$txt get 2.0 2.end] ne "s is some text"} {
      cleanup "Character range deletion did not work"
    }

    cleanup

  }

  # Verify the fastinsert command
  proc run_test17 {} {

    set txt [initialize]

    $txt fastinsert end "\nset foobar \\\\{now}"

    if {[$txt tag ranges _keywords] ne [list]} {
      cleanup "keyword tags exist for fast insert"
    }
    if {[$txt tag ranges _escape] ne [list]} {
      cleanup "escape tags exist for fast insert"
    }
    if {[$txt tag ranges _curlyL] ne [list]} {
      cleanup "curly bracket tags exist for fast insert"
    }
    if {[$txt get 2.0 2.end] ne "set foobar \\\\{now}"} {
      cleanup "fast insertion did not insert text correctly"
    }

    cleanup

  }

  # Verify the highlight command
  proc run_test18 {} {

    set txt [initialize]

    foreach {startpos endpos} [list 2.2 2.5 1.0 2.0 1.0 end] {

      $txt delete 1.0 end
      $txt fastinsert end "\nset foobar \[list \"nice\" \"\\\\\"\]"

      if {([$txt tag ranges _keywords] ne [list]) || \
          ([$txt tag ranges _squareL]  ne [list]) || \
          ([$txt tag ranges _dString0] ne [list]) || \
          ([$txt tag ranges _dString1] ne [list]) || \
          ([$txt tag ranges _escape]   ne [list])} {
        cleanup "fastinsert text contained tags"
      }

      $txt highlight $startpos $endpos

      if {[$txt tag ranges _keywords] ne [list 2.0 2.3 2.12 2.16]} {
        cleanup "keyword not tagged after being highlighted"
      }
      if {[$txt tag ranges _squareL] ne [list 2.11 2.12]} {
        cleanup "square bracket not tagged after being highlighted"
      }
      if {[$txt tag ranges _dString0] ne [list 2.17 2.23]} {
        cleanup "dquote0 not tagged after being highlighted"
      }
      if {[$txt tag ranges _dString1] ne [list 2.24 2.28]} {
        cleanup "dquote1 not tagged after being highlighted"
      }
      if {[$txt tag ranges _escape] ne [list 2.25 2.26]} {
        cleanup "escape not tagged after being highlighted"
      }

    }

    cleanup

  }

  # Verify the insert command
  proc run_test19 {} {

    set txt [initialize]

    $txt insert end "\nset foobar \\\\{now}"

    if {[$txt tag ranges _keywords] ne [list 2.0 2.3]} {
      cleanup "keyword tags exist for insert"
    }
    if {[$txt tag ranges _escape] ne [list 2.11 2.12]} {
      cleanup "escape tags exist for insert"
    }
    if {[$txt tag ranges _curlyL] ne [list 2.13 2.14]} {
      cleanup "curly bracket tags exist for insert"
    }
    if {[$txt get 2.0 2.end] ne "set foobar \\\\{now}"} {
      cleanup "text not inserted correctly"
    }

    cleanup

  }

  # Verify the replace command
  proc run_test20 {} {

    set txt [initialize]

    $txt insert end "\nset foobar \\\\{now}"

    if {[$txt tag ranges _keywords] ne [list 2.0 2.3]} {
      cleanup "keyword tags incorrect for insert"
    }
    if {[$txt tag ranges _escape] ne [list 2.11 2.12]} {
      cleanup "escape tags incorrect for insert"
    }
    if {[$txt tag ranges _curlyL] ne [list 2.13 2.14]} {
      cleanup "curly bracket tags incorrect for insert"
    }
    if {[$txt get 2.0 2.end] ne "set foobar \\\\{now}"} {
      cleanup "text not inserted correctly"
    }

    $txt replace 2.4 2.10 "goo"

    if {[$txt tag ranges _keywords] ne [list 2.0 2.3]} {
      cleanup "keyword tags incorrect for replace"
    }
    if {[$txt tag ranges _escape] ne [list 2.8 2.9]} {
      cleanup "escape tags incorrect for replace"
    }
    if {[$txt tag ranges _curlyL] ne [list 2.10 2.11]} {
      cleanup "curly bracket tags incorrect for replace"
    }
    if {[$txt get 2.0 2.end] ne "set goo \\\\{now}"} {
      cleanup "text not replaced correctly"
    }

    $txt replace 1.0 end "\nproc something {{parm \"buddy\"}} {}"

    if {[$txt tag ranges _keywords] ne [list 2.0 2.4]} {
      cleanup "keyword tags incorrect for replace"
    }
    if {[$txt tag ranges _escape] ne [list]} {
      cleanup "escape tags exist for replace"
    }
    if {[$txt tag ranges _curlyL] ne [list 2.15 2.17 2.32 2.33]} {
      cleanup "curly bracket tags incorrect for replace"
    }
    if {[$txt tag ranges _dString0] ne [list 2.22 2.29]} {
      cleanup "string tags incorrect for replace"
    }
    if {[$txt get 2.0 2.end] ne "proc something {{parm \"buddy\"}} {}"} {
      cleanup "text not replaced correctly"
    }

    cleanup

  }

  proc run_test21 {} {

    set txt [initialize]

    clipboard clear
    clipboard append "\nset foobar \"good\""

    vim::remove_dspace $txt

    $txt paste

    # TBD - The extra space after the sentence is our dspace character (I believe) and should
    #       not be there.
    if {[$txt get 2.0 2.end] ne "set foobar \"good\""} {
      cleanup "text not pasted properly"
    }
    if {[$txt tag ranges _keywords] ne [list 2.0 2.3]} {
      cleanup "keywords not tagged after a paste operation"
    }
    if {[$txt tag ranges _dString0] ne [list 2.11 2.17]} {
      cleanup "string not tagged after a paste operation"
    }

    cleanup

  }

}
