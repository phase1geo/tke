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

  # Test forward motion with character selection (inclusive selection mode)
  proc run_test3 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to inclusive
    vim::do_set_selection "inclusive"

    $txtt insert end "\nThis is so so good\n\nThis is great"
    $txtt mark set insert 2.0

    enter $txtt v
    if {[$txtt tag ranges sel] ne [list 2.0 2.1]} {
      cleanup "Character selection did not work ([$txtt tag ranges sel])"
    }

    enter $txtt l
    if {[$txtt tag ranges sel] ne [list 2.0 2.2]} {
      cleanup "Right one did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {2 l}
    if {[$txtt tag ranges sel] ne [list 2.0 2.4]} {
      cleanup "Right two did not work ([$txtt tag ranges sel])"
    }

    enter $txtt space
    if {[$txtt tag ranges sel] ne [list 2.0 2.5]} {
      cleanup "Space one did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {2 space}
    if {[$txtt tag ranges sel] ne [list 2.0 2.7]} {
      cleanup "Space two did not work ([$txtt tag ranges sel])"
    }

    enter $txtt w
    if {[$txtt tag ranges sel] ne [list 2.0 2.9]} {
      cleanup "One w did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {2 w}
    if {[$txtt tag ranges sel] ne [list 2.0 2.15]} {
      cleanup "Two w did not work ([$txtt tag ranges sel])"
    }

    enter $txtt dollar
    if {[$txtt tag ranges sel] ne [list 2.0 2.18]} {
      cleanup "Dollar did not work ([$txtt tag ranges sel])"
    }

    enter $txtt 0
    if {[$txtt tag ranges sel] ne [list 2.0 2.1]} {
      cleanup "Zero did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {5 bar}
    if {[$txtt tag ranges sel] ne [list 2.0 2.5]} {
      cleanup "Bar did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {f g}
    if {[$txtt tag ranges sel] ne [list 2.0 2.15]} {
      cleanup "One fg did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {0 t g}
    if {[$txtt tag ranges sel] ne [list 2.0 2.14]} {
      cleanup "One tg did not work ([$txtt tag ranges sel])"
    }

    enter $txtt j
    if {[$txtt tag ranges sel] ne [list 2.0 3.1]} {
      cleanup "One j did not work ([$txtt tag ranges sel])"
    }

    enter $txtt Return
    if {[$txtt tag ranges sel] ne [list 2.0 4.1]} {
      cleanup "One return did not work ([$txtt tag ranges sel])"
    }

    # Cleanup
    cleanup

  }

  # Test backword motion with character selection (inclusive selection mode)
  proc run_test4 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to inclusive
    vim::do_set_selection "inclusive"

    $txtt insert end "\nThis is so so good\n\nThis is great"
    $txtt mark set insert 2.10

    enter $txtt v
    if {[$txtt tag ranges sel] ne [list 2.10 2.11]} {
      cleanup "Character selection did not work ([$txtt tag ranges sel])"
    }

    enter $txtt h
    if {[$txtt tag ranges sel] ne [list 2.9 2.11]} {
      cleanup "One h did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {2 h}
    if {[$txtt tag ranges sel] ne [list 2.7 2.11]} {
      cleanup "Two h did not work ([$txtt tag ranges sel])"
    }

    enter $txtt b
    if {[$txtt tag ranges sel] ne [list 2.5 2.11]} {
      cleanup "One b did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {1 1 bar 2 b}
    if {[$txtt tag ranges sel] ne [list 2.5 2.11]} {
      cleanup "Two b did not work ([$txtt tag ranges sel])"
    }

    enter $txtt BackSpace
    if {[$txtt tag ranges sel] ne [list 2.4 2.11]} {
      cleanup "Backspace did not work ([$txtt tag ranges sel])"
    }

    enter $txtt asciicircum
    if {[$txtt tag ranges sel] ne [list 2.0 2.11]} {
      cleanup "Caret did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {1 1 bar 0}
    if {[$txtt tag ranges sel] ne [list 2.0 2.11]} {
      cleanup "0 did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {9 bar}
    if {[$txtt tag ranges sel] ne [list 2.8 2.11]} {
      cleanup "bar did not work ([$txtt tag ranges sel])"
    }

    enter $txtt minus
    if {[$txtt tag ranges sel] ne [list 1.0 2.11]} {
      cleanup "minus did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {Escape 4 G v}
    if {[$txtt tag ranges sel] ne [list 4.0 4.1]} {
      cleanup "Moving cursor to last line did not work ([$txtt tag ranges sel])"
    }

    enter $txtt k
    if {[$txtt tag ranges sel] ne [list 3.0 4.1]} {
      cleanup "One k did not work ([$txtt tag ranges sel])"
    }

    enter $txtt k
    if {[$txtt tag ranges sel] ne [list 2.0 4.1]} {
      cleanup "Another k did not work ([$txtt tag ranges sel])"
    }

    # Cleanup
    cleanup

  }

  # Test forward motion with character selection (exclusive selection mode)
  proc run_test5 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to exclusive
    vim::do_set_selection "exclusive"

    $txtt insert end "\nThis is so so good\n\nThis is great"
    $txtt mark set insert 2.0

    enter $txtt v
    if {[$txtt tag ranges sel] ne [list]} {
      cleanup "Character selection did not work ([$txtt tag ranges sel])"
    }

    enter $txtt l
    if {[$txtt tag ranges sel] ne [list 2.0 2.1]} {
      cleanup "Right one did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {2 l}
    if {[$txtt tag ranges sel] ne [list 2.0 2.3]} {
      cleanup "Right two did not work ([$txtt tag ranges sel])"
    }

    enter $txtt space
    if {[$txtt tag ranges sel] ne [list 2.0 2.4]} {
      cleanup "Space one did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {2 space}
    if {[$txtt tag ranges sel] ne [list 2.0 2.6]} {
      cleanup "Space two did not work ([$txtt tag ranges sel])"
    }

    enter $txtt w
    if {[$txtt tag ranges sel] ne [list 2.0 2.8]} {
      cleanup "One w did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {2 w}
    if {[$txtt tag ranges sel] ne [list 2.0 2.14]} {
      cleanup "Two w did not work ([$txtt tag ranges sel])"
    }

    enter $txtt dollar
    if {[$txtt tag ranges sel] ne [list 2.0 2.17]} {
      cleanup "Dollar did not work ([$txtt tag ranges sel])"
    }

    enter $txtt 0
    if {[$txtt tag ranges sel] ne [list]} {
      cleanup "Zero did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {5 bar}
    if {[$txtt tag ranges sel] ne [list 2.0 2.4]} {
      cleanup "Bar did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {f g}
    if {[$txtt tag ranges sel] ne [list 2.0 2.14]} {
      cleanup "One fg did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {0 t g}
    if {[$txtt tag ranges sel] ne [list 2.0 2.13]} {
      cleanup "One tg did not work ([$txtt tag ranges sel])"
    }

    enter $txtt j
    if {[$txtt tag ranges sel] ne [list 2.0 3.0]} {
      cleanup "One j did not work ([$txtt tag ranges sel])"
    }

    enter $txtt Return
    if {[$txtt tag ranges sel] ne [list 2.0 4.0]} {
      cleanup "One return did not work ([$txtt tag ranges sel])"
    }
    # Cleanup
    cleanup

  }

  # Test backward motion with character selection (exclusive selection mode)
  proc run_test6 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to exclusive
    vim::do_set_selection "exclusive"

    $txtt insert end "\nThis is so so good\n\nThis is great"
    $txtt mark set insert 2.10

    enter $txtt v
    if {[$txtt tag ranges sel] ne [list]} {
      cleanup "Character selection did not work ([$txtt tag ranges sel])"
    }

    enter $txtt h
    if {[$txtt tag ranges sel] ne [list 2.9 2.10]} {
      cleanup "One h did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {2 h}
    if {[$txtt tag ranges sel] ne [list 2.7 2.10]} {
      cleanup "Two h did not work ([$txtt tag ranges sel])"
    }

    enter $txtt b
    if {[$txtt tag ranges sel] ne [list 2.5 2.10]} {
      cleanup "One b did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {1 1 bar 2 b}
    if {[$txtt tag ranges sel] ne [list 2.5 2.10]} {
      cleanup "Two b did not work ([$txtt tag ranges sel])"
    }

    enter $txtt BackSpace
    if {[$txtt tag ranges sel] ne [list 2.4 2.10]} {
      cleanup "Backspace did not work ([$txtt tag ranges sel])"
    }

    enter $txtt asciicircum
    if {[$txtt tag ranges sel] ne [list 2.0 2.10]} {
      cleanup "Caret did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {1 2 bar 0}
    if {[$txtt tag ranges sel] ne [list 2.0 2.10]} {
      cleanup "0 did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {9 bar}
    if {[$txtt tag ranges sel] ne [list 2.8 2.10]} {
      cleanup "bar did not work ([$txtt tag ranges sel])"
    }

    enter $txtt minus
    if {[$txtt tag ranges sel] ne [list 1.0 2.10]} {
      cleanup "minus did not work ([$txtt tag ranges sel])"
    }

    enter $txtt {Escape 4 G v}
    if {[$txtt tag ranges sel] ne [list]} {
      cleanup "Moving cursor to last line did not work ([$txtt tag ranges sel])"
    }

    enter $txtt k
    if {[$txtt tag ranges sel] ne [list 3.0 4.0]} {
      cleanup "One k did not work ([$txtt tag ranges sel])"
    }

    enter $txtt k
    if {[$txtt tag ranges sel] ne [list 2.0 4.0]} {
      cleanup "Another k did not work ([$txtt tag ranges sel])"
    }

    # Cleanup
    cleanup

  }

  # Verify line selection (both inclusive and exclusive since it should not matter)
  proc run_test7 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end [string repeat "\n  This is good" 100]

    foreach seltype [list inclusive exclusive] {

      # Set mode to inclusive
      vim::do_set_selection $seltype
      $txtt mark set insert 10.0

      enter $txtt V
      if {[$txtt tag ranges sel] ne [list 10.0 10.14]} {
        cleanup "Line selection mode did not work ([$txtt tag ranges sel])"
      }

      enter $txtt j
      if {[$txtt tag ranges sel] ne [list 10.0 11.14]} {
        cleanup "One j did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {2 j}
      if {[$txtt tag ranges sel] ne [list 10.0 13.14]} {
        cleanup "Two j did not work ([$txtt tag ranges sel])"
      }

      enter $txtt Return
      if {[$txtt tag ranges sel] ne [list 10.0 14.14]} {
        cleanup "One return did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {2 Return}
      if {[$txtt tag ranges sel] ne [list 10.0 16.14]} {
        cleanup "Two return did not work ([$txtt tag ranges sel])"
      }

      enter $txtt w
      if {[$txtt tag ranges sel] ne [list 10.0 16.14]} {
        cleanup "One w did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {2 w}
      if {[$txtt tag ranges sel] ne [list 10.0 17.14]} {
        cleanup "Two w did not work ([$txtt tag ranges sel])"
      }

      enter $txtt b
      if {[$txtt tag ranges sel] ne [list 10.0 16.14]} {
        cleanup "One b did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {1 0 l}
      if {[$txtt tag ranges sel] ne [list 10.0 16.14]} {
        cleanup "One l did not work ([$txtt tag ranges sel])"
      }

      enter $txtt space
      if {[$txtt tag ranges sel] ne [list 10.0 17.14]} {
        cleanup "One space did not work ([$txtt tag ranges sel])"
      }

      enter $txtt BackSpace
      if {[$txtt tag ranges sel] ne [list 10.0 16.14]} {
        cleanup "One backspace did not work ([$txtt tag ranges sel])"
      }

      enter $txtt BackSpace
      if {[$txtt tag ranges sel] ne [list 10.0 16.14]} {
        cleanup "Another backspace did not work ([$txtt tag ranges sel])"
      }

      enter $txtt space
      if {[$txtt tag ranges sel] ne [list 10.0 16.14]} {
        cleanup "Another space did not work ([$txtt tag ranges sel])"
      }

      enter $txtt minus
      if {[$txtt tag ranges sel] ne [list 10.0 15.14]} {
        cleanup "One minus did not work ([$txtt tag ranges sel])"
      }
      if {[$txtt index insert] ne "15.2"} {
        cleanup "One minus had bad insert ([$txtt index insert])"
      }

      enter $txtt {f T}
      if {[$txtt tag ranges sel] ne [list 10.0 15.14]} {
        cleanup "One fT did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {t T}
      if {[$txtt tag ranges sel] ne [list 10.0 15.14]} {
        cleanup "One tT did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {T T}
      if {[$txtt tag ranges sel] ne [list 10.0 15.14]} {
        cleanup "One TT did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {F T}
      if {[$txtt tag ranges sel] ne [list 10.0 15.14]} {
        cleanup "One FT did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {g g}
      if {[$txtt tag ranges sel] ne [list 1.0 10.14]} {
        cleanup "One gg did not work ([$txtt tag ranges sel])"
      }

      enter $txtt G
      if {[$txtt tag ranges sel] ne [list 10.0 101.14]} {
        cleanup "One G did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {2 0 G}
      if {[$txtt tag ranges sel] ne [list 10.0 20.14]} {
        cleanup "One 20G did not work ([$txtt tag ranges sel])"
      }

      enter $txtt {Escape Escape}

    }

    # Cleanup
    cleanup

  }

  # Verify indent, unindent, shiftwidth and indent formatting
  proc run_test8 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is good\n\nThis is good too"
    $txtt mark set insert 2.0

    vim::do_set_shiftwidth 2

    enter $txtt {greater greater}
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n\nThis is good too"} {
      cleanup "Right shift failed ([$txtt get 1.0 end-1c])"
    }

    enter $txtt {2 greater greater}
    if {[$txtt get 1.0 end-1c] ne "\n    This is good\n  \nThis is good too"} {
      cleanup "Right shift 2 failed ([$txtt get 1.0 end-1c])"
    }

    vim::do_set_shiftwidth 4

    enter $txtt {3 greater greater}
    if {[$txtt get 1.0 end-1c] ne "\n        This is good\n      \n    This is good too"} {
      cleanup "Right shift 3 failed ([$txtt get 1.0 end-1c])"
    }

    enter $txtt {less less}
    if {[$txtt get 1.0 end-1c] ne "\n    This is good\n      \n    This is good too"} {
      cleanup "Left shift failed ([$txtt get 1.0 end-1c])"
    }

    vim::do_set_shiftwidth 2

    enter $txtt {2 less less}
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \n    This is good too"} {
      cleanup "Left shift 2 failed ([$txtt get 1.0 end-1c])"
    }

    enter $txtt {2 j equal equal}
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \n  This is good too"} {
      cleanup "Equal failed ([$txtt get 1.0 end-1c])"
    }

    $txtt insert end "\n      This is cool"
    enter $txtt {less less}
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \nThis is good too\n      This is cool"} {
      cleanup "Text adjustment failed ([$txtt get 1.0 end-1c])"
    }

    enter $txtt {2 equal equal}
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \n  This is good too\n  This is cool"} {
      cleanup "Equal 2 failed ([$txtt get 1.0 end-1c])"
    }

    $txtt insert end "\nThis is wacky\n    Not this though"
    $txtt tag add sel 5.0 8.0

    enter $txtt equal
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \n  This is good too\n  This is cool\n  This is wacky\n  Not this though"} {
      cleanup "Selected equal failed ([$txtt get 1.0 end-1c])"
    }

    # Cleanup
    cleanup

  }

  proc do_ml_test {txt id options} {

    vim::parse_modeline $txt



  }

  # Verify modelines are ignored when modelines is not set
  proc run_test9 {} {

    # Initialize
    set txt [initialize]

    $txt insert end "# vim:set shiftwidth=4: "

    vim::do_set_modeline 0
    do_ml_test $txt 0


    # Cleanup
    cleanup

  }

  # Verify the period (.) Vim command
  proc tbd_test9 {} {

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
