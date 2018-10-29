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

  ######################################################################
  # Performs modeline test with the given options.
  proc do_ml_test {txt id options} {

    set opts(lang)       [gui::get_info {} current lang]
    set opts(fileformat) [gui::get_info {} current eol]
    set opts(foldenable) [expr [$txt gutter hide folding] ^ 1]

    array set opts $options

    # puts "do_ml_test - ([string trim [$txt get 1.0 end-1c]])"

    vim::parse_modeline $txt

    if {$opts(lang) ne [gui::get_info {} current lang]} {
      cleanup "$id syntax not expected ([gui::get_info {} current lang])"
    }
    if {$opts(fileformat) ne [gui::get_info {} current eol]} {
      cleanup "$id fileformat not expected ([gui::get_info {} current eol])"
    }
    if {$opts(foldenable) ne [expr [$txt gutter hide folding] ^ 1]} {
      cleanup "$id foldenable not expected ([expr [$txt gutter hide folding] ^ 1])"
    }

  }

  # Verify modelines are ignored when modelines is not set
  proc run_test9 {} {

    # Initialize
    set txt       [initialize]
    set modelines $vim::modelines

    $txt insert end "# vim:set syntax=c: "

    vim::do_set_modeline 0
    do_ml_test $txt 0 {}

    vim::do_set_modeline  1
    vim::do_set_modelines 0
    do_ml_test $txt "0A" {}

    vim::do_set_modelines $modelines
    do_ml_test $txt 1 {lang C}

    $txt delete 1.0 end
    $txt insert end "# vim:set syntax=perl: "
    do_ml_test $txt 2 {lang Perl}

    $txt delete 1.0 end
    $txt insert end "# vi:se syntax=tcl fileformat=dos: syntax=c"
    do_ml_test $txt 3 {lang Tcl fileformat crlf}

    $txt delete 1.0 end
    $txt insert end "# vim6:set nofen syntax=perl: "
    do_ml_test $txt 4 {lang Perl foldenable 0}

    $txt delete 1.0 end
    $txt insert end "# vim<4: set fen: "
    do_ml_test $txt 5 {foldenable 1}

    $txt delete 1.0 end
    $txt insert end "# vim>10:nofen:syntax=tcl ff=mac"
    do_ml_test $txt 6 {foldenable 0 lang Tcl fileformat cr}

    $txt delete 1.0 end
    $txt insert end "vim=9: set   syntax=c : nice"
    do_ml_test $txt 7 {lang C}

    $txt delete 1.0 end
    $txt insert end " ex:ff=unix:fen"
    do_ml_test $txt 8 {fileformat lf foldenable 1}

    # Verify that modelines at the bottom of the file work
    $txt delete 1.0 end
    $txt insert end [string repeat "\n" $modelines]
    $txt insert end " vim:set syntax=perl :"
    do_ml_test $txt 9 {lang Perl}

    $txt delete 1.0 end
    $txt insert end [string repeat "\n" [expr $modelines - 1]]
    $txt insert end "// vi:nofen"
    $txt insert end [string repeat "\n" $modelines]
    do_ml_test $txt 10 {foldenable 0}

    $txt delete 1.0 end
    $txt insert end [string repeat "\n" $modelines]
    $txt insert end "/* vim:set foldenable: */"
    $txt insert end [string repeat "\n" [expr $modelines - 1]]
    do_ml_test $txt 11 {foldenable 1}

    # ERROR CASES

    # Place line outside of the modelines setting
    $txt delete 1.0 end
    $txt insert end [string repeat "\n" $modelines]
    $txt insert end "# vim:set syntax=tcl: "
    $txt insert end [string repeat "\n" $modelines]
    do_ml_test $txt 20 {}

    $txt delete 1.0 end
    $txt insert end "vi\\:set syntax=tcl: "
    do_ml_test $txt 21 {}

    # This case doesn't work exactly right, but we'll let it slide
    $txt delete 1.0 end
    $txt insert end "vim:set syntax=tcl\\: "
    do_ml_test $txt 22 {lang None}

    vim::do_set_syntax tcl
    if {[gui::get_info {} current lang] ne "Tcl"} {
      cleanup "Unable to set language from None to Tcl with do_set_syntax tcl"
    }

    $txt delete 1.0 end
    $txt insert end "ex:syntax=tcl,fen:"
    do_ml_test $txt 23 {lang None}

    vim::do_set_syntax tcl
    $txt delete 1.0 end
    $txt insert end "ex:syntax=bubba"
    do_ml_test $txt 24 {lang None}

    # This case should technically not allow the syntax to be set due to the extra
    # characters after the modeline text.
    $txt delete 1.0 end
    $txt insert end "/* vim:syntax=tcl */"
    do_ml_test $txt 25 {lang Tcl}

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
