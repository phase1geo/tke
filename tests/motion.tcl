namespace eval motion {

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

  ######################################################################
  # Perform motion test.
  proc do_test {txtt id cmdlist cursor {dspace 0}} {

    enter $txtt $cmdlist

    if {[$txtt index insert] ne $cursor} {
      cleanup "$id insertion cursor is incorrect ([$txtt index insert])"
    }
    if {$vim::mode($txtt) ne "start"} {
      cleanup "$id mode is not start"
    }
    if {$dspace} {
      if {[lindex [split $cursor .] 1] != 0} {
        cleanup "$id dspace is expected when cursor is not 0"
      }
      if {[$txtt tag ranges dspace] ne [list $cursor [$txtt index "$cursor+1c"]]} {
        cleanup "$id dspace does not match expected ([$txtt tag ranges dspace])"
      }
    } else {
      if {[$txtt tag ranges dspace] ne [list]} {
        cleanup "$id dspace does not match expected ([$txtt tag ranges dspace])"
      }
    }

  }

  # Verify h Vim command
  proc run_test3 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\nthis is good"
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 h     2.4
    do_test $txtt 1 {2 h} 2.2

    # Verify that if we move by more characters than column 0, we don't move past column 0
    do_test $txtt 2 {5 h} 2.0

    # Verify that the cursor will not move to the left when we are in column 0
    do_test $txtt 3 h     2.0

    # Cleanup
    cleanup

  }

  # Verify l Vim command
  proc run_test4 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\nthis is not bad\nthis is cool"
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 l       2.6
    do_test $txtt 1 {2 l}   2.8

    # Verify that we don't advance past the end of the current line
    do_test $txtt 2 {2 0 l} 2.14

    # Verify that we don't move a single character
    do_test $txtt 3 l       2.14

    # Cleanup
    cleanup

  }

  # Verify k Vim command
  proc run_test5 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\ngood\n\nbad\nfoobar\nnice\nbetter"
    $txtt mark set insert 7.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {}    7.0
    do_test $txtt 1 k     6.0
    do_test $txtt 2 {2 k} 4.0
    do_test $txtt 3 k     3.0 1
    do_test $txtt 4 k     2.0

    # Attempt to move up by more than the number specified
    do_test $txtt 5 {5 k} 1.0 1
    do_test $txtt 6 k     1.0 1

    # Make sure current column is removed
    do_test $txtt 7 {G 4 bar} 7.3
    set i 0
    foreach index [list 6.3 5.3 4.2 3.0 2.3 1.0] {
      do_test $txtt [expr $i + 8] k $index [expr [lindex [split $index .] 1] == 0]
      incr i
    }

    # Cleanup
    cleanup

  }

  # Verify j Vim command
  proc run_test6 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\ngood\nbad\nfoobar\nnice\n\nbetter\n\n"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {}    2.0
    do_test $txtt 1 j     3.0
    do_test $txtt 2 {2 j} 5.0
    do_test $txtt 3 j     6.0 1
    do_test $txtt 4 j     7.0

    # Attempt to move up by more than the number specified
    do_test $txtt 5 {5 j} 9.0 1
    do_test $txtt 6 j     9.0 1

    # Make sure that the current column is removed
    do_test $txtt 7 {2 G 4 bar} 2.3
    set i 0
    foreach index [list 3.2 4.3 5.3 6.0 7.3 8.0] {
      do_test $txtt [expr $i + 8] j $index [expr [lindex [split $index .] 1] == 0]
    }

    # Cleanup
    cleanup

  }

  # Verify 0 and $ Vim command
  proc run_test7 {} {

    # Initialize the widgets
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nAnother line"
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    do_test $txtt 0 {}       2.5
    do_test $txtt 1 0        2.0
    do_test $txtt 2 {dollar} 2.13

    # Verify that using a number jumps to the next line down
    do_test $txtt 3 {2 G 6 bar} 2.5
    do_test $txtt 4 {2 dollar}  3.11

    # Cleanup
    cleanup

  }

  # Move w and b Vim commands
  proc run_test8 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\nThis is good\n\nThis is great"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Move forward by one word
    foreach {index dspace} [list 2.5 0 2.8 0 3.0 1 4.0 0 4.5 0 4.8 0 4.12 0 4.12 0] {
      do_test $txtt $i w $index $dspace
      incr i
    }

    # Move backward by one word
    foreach {index dspace} [list 4.8 0 4.5 0 4.0 0 2.8 0 2.5 0 2.0 0 1.0 1 1.0 1] {
      do_test $txtt $i b $index $dspace
      incr i
    }

    # Move forward by two words
    foreach {index dspace} [list 2.5 0 3.0 1 4.5 0 4.12 0 4.12 0] {
      do_test $txtt $i {2 w} $index $dspace
      incr i
    }

    # Move backward by two words
    foreach {index dspace} [list 4.5 0 2.8 0 2.0 0 1.0 1 1.0 1] {
      do_test $txtt $i {2 b} $index $dspace
      incr i
    }

    # Cleanup
    cleanup

  }

  # Verify Return and minus Vim commands
  proc run_test9 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\n apples\n\ngrapes\n      bananas\n  milk\n\n    soup"
    $txtt mark set insert 1.0
    vim::adjust_insert $txtt

    # Verify the current line firstword variety
    foreach {index dspace} [list 1.0 1 2.1 0 3.0 1 4.0 0 5.6 0 6.2 0 7.0 1 8.4 0] {
      do_test $txtt $i [list [lindex [split $index .] 0] G [expr int( rand() * 10 )] asciicircum] $index $dspace
      incr i
    }

    do_test $txtt $i {g g} 1.0 1
    incr i

    # Test nextfirst (one line at a time)
    foreach {index dspace} [list 2.1 0 3.0 1 4.0 0 5.6 0 6.2 0 7.0 1 8.4 0 8.4 0] {
      do_test $txtt $i Return $index $dspace
      incr i
    }

    # Test prevfirst (one line at a time)
    foreach {index dspace} [list 7.0 1 6.2 0 5.6 0 4.0 0 3.0 1 2.1 0 1.0 1 1.0 1] {
      do_test $txtt $i minus $index $dspace
      incr i
    }

    # Test nextfirst (two lines at a time)
    foreach {index dspace} [list 3.0 1 5.6 0 7.0 1 8.4 0] {
      do_test $txtt $i {2 Return} $index $dspace
      incr i
    }

    # Test prevfirst (two lines at a time)
    foreach {index dspace} [list 6.2 0 4.0 0 2.1 0 1.0 1] {
      do_test $txtt $i {2 minus} $index $dspace
      incr i
    }

    # Cleanup
    cleanup

  }

  # Verify space and BackSpace Vim command
  proc run_test10 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\ngood\n\ngreat"

    $txtt mark set insert 1.0
    vim::adjust_insert $txtt

    # Move forward through the document, one character at a time
    foreach {index dspace} [list 2.0 0 2.1 0 2.2 0 2.3 0 3.0 1 4.0 0 4.1 0 4.2 0 4.3 0 4.4 0 4.4 0] {
      do_test $txtt $i space $index $dspace
      incr i
    }

    # Move backward through the document, one character at a time
    foreach {index dspace} [list 4.3 0 4.2 0 4.1 0 4.0 0 3.0 1 2.3 0 2.2 0 2.1 0 2.0 0 1.0 1 1.0 1] {
      do_test $txtt $i BackSpace $index $dspace
      incr i
    }

    # Move forward 2 characters at a time
    foreach {index dspace} [list 2.1 0 2.3 0 4.0 0 4.2 0 4.4 0 4.4 0] {
      do_test $txtt $i {2 space} $index $dspace
      incr i
    }

    # Move backward through the document, one character at a time
    foreach {index dspace} [list 4.2 0 4.0 0 2.3 0 2.1 0 1.0 1 1.0 1] {
      do_test $txtt $i {2 BackSpace} $index $dspace
      incr i
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

    do_test $txtt 0 {} 10.0 1

    # Jump the cursor to the top of the screen
    do_test $txtt 1 H [$txtt index @0,0] 1

    # Jump to the middle
    do_test $txtt 2 M [$txtt index @0,[expr [winfo reqheight $txtt] / 2]] 1

    # Jump to the bottom
    do_test $txtt 3 L [$txtt index @0,[winfo reqheight $txtt]] 1

    # Jump to the first line
    do_test $txtt 4 {g g} 1.0 1

    # Jump to the last line
    do_test $txtt 5 G 101.0 1

    # Jump to a specific line
    do_test $txtt 6 {1 2 G} 12.0 1

    # Jump to a line percentage
    do_test $txtt 7 {2 0 percent} 21.0 1

    # Clean things up
    cleanup

  }

  # Verify f, t, F and T Vim motions
  proc run_test12 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is really strong\n\nBut I am stronger"

    # Attempt to find a character that does not exist
    do_test $txtt 0 {2 G 0 f x} 2.0

    # Search forward for the first l
    do_test $txtt 1 {0 f l} 2.11

    # Search forward for the second l
    do_test $txtt 2 {0 2 f l} 2.12

    # Search forward for the third l
    do_test $txtt 3 {0 3 f l} 2.0

    # Attempt to find a character that does not exist
    do_test $txtt 4 {0 t x} 2.0

    # Search forward for the first l
    do_test $txtt 5 {0 t l} 2.10

    # Search forward for the second l
    do_test $txtt 6 {0 2 t l} 2.11

    # Search forward for the third l
    do_test $txtt 7 {0 3 t l} 2.0

    # Attempt to find a character that does not exist
    do_test $txtt 8 {dollar F x} 2.20

    # Search forward for the first l
    do_test $txtt 9 {dollar F l} 2.12

    # Search forward for the second l
    do_test $txtt 10 {dollar 2 F l} 2.11

    # Search forward for the third l
    do_test $txtt 11 {dollar 3 F l} 2.20

    # Attempt to find a character that does not exist
    do_test $txtt 12 {dollar T x} 2.20

    # Search forward for the first l
    do_test $txtt 13 {dollar T l} 2.13

    # Search forward for the second l
    do_test $txtt 14 {dollar 2 T l} 2.12

    # Search forward for the third l
    do_test $txtt 15 {dollar 3 T l} 2.20

    # Clean things up
    cleanup

  }

  # Verify bar Vim command
  proc run_test13 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is something"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Move to a valid column
    do_test $txtt 0 {7 bar} 2.6

    # Move to column 0
    do_test $txtt 1 {1 bar} 2.0

    # Attempt to move to an invalidate column
    do_test $txtt 2 {2 0 bar} 2.16

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
    do_test $txtt 0 j      4.0
    do_test $txtt 1 k      2.0
    do_test $txtt 2 Down   4.0
    do_test $txtt 3 Up     2.0
    do_test $txtt 4 Return 4.0
    do_test $txtt 5 minus  2.0

    # Move left/right by char
    do_test $txtt 6 dollar 2.13
    do_test $txtt 7 space  4.0
    do_test $txtt 8 BackSpace 2.13

    # Move left/right by word
    do_test $txtt 9  w 4.0
    do_test $txtt 10 b 2.13

    # Cleanup
    cleanup

  }

  # Test left/right motion with elided text
  proc run_test15 {} {

    # Initialize
    set txtt [initialize].t

    # Insert a line that we will elide some text on
    $txtt insert end "\nNi*e **bold**\nGood"
    $txtt tag configure foobar -elide 1
    $txtt tag add foobar 2.5 2.7
    $txtt mark set insert 2.4
    vim::adjust_insert $txtt

    do_test $txtt 0 l 2.7
    do_test $txtt 1 h 2.4
    do_test $txtt 2 w 2.7
    do_test $txtt 3 b 2.3

    do_test $txtt 4 {l space} 2.7
    do_test $txtt 5 BackSpace 2.4

    do_test $txtt 6 {f asterisk} 2.11
    do_test $txtt 7 {F asterisk} 2.2
    do_test $txtt 8 {t asterisk} 2.10
    do_test $txtt 9 {T asterisk} 2.3

    $txtt tag add foobar 2.11 2.13
    $txtt mark set insert 2.10

    do_test $txtt 10 l 2.10
    do_test $txtt 11 w 3.0

    $txtt mark set insert 2.0

    do_test $txtt 12 dollar 2.10

    $txtt tag remove foobar 1.0 end
    $txtt tag add foobar 3.0 3.2
    $txtt mark set insert 3.3

    do_test $txtt 13 0 3.2
    do_test $txtt 14 b 2.12

    $txtt tag remove foobar 1.0 end
    $txtt tag add foobar 3.2 3.end
    $txtt mark set insert 2.7

    do_test $txtt 15 G 3.1

    $txtt tag remove foobar 1.0 end
    $txtt insert 1.0 "here"
    $txtt tag add foobar 1.0 1.1

    do_test $txtt 16 {g g} 1.2

    # Cleanup
    cleanup

  }

  # Test forward motion with character selection (inclusive selection mode)
  proc run_test16 {} {

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
  proc run_test17 {} {

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
  proc run_test18 {} {

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
  proc run_test19 {} {

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
  proc run_test20 {} {

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
  proc run_test21 {} {

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

  # Verify the period (.) Vim command
  proc tbd_test22 {} {

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