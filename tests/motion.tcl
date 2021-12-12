namespace eval motion {

  variable current_tab

  ######################################################################
  # Outputs the given string such that blank space is shown
  proc ostr {str} {
    return [string map {\n .\n} $str]
  }

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

    # Make sure these are cleared
    set vim::recording(num)    ""
    set vim::recording(events) [list]

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
          $txtt insert cursor $char
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
    if {$vim::mode($txtt) ne "command"} {
      cleanup "$id mode is not command ($vim::mode($txtt))"
    }
    if {$vim::operator($txtt) ne ""} {
      cleanup "$id operator is not empty string ($vim::operator($txtt))"
    }
    if {$vim::motion($txtt) ne ""} {
      cleanup "$id motion is not empty string ($vim::motion($txtt))"
    }
    if {$vim::recording(mode) ne "none"} {
      cleanup "$id recording mode is incorrect ($vim::recording(mode))"
    }
    if {$vim::recording(num) ne ""} {
      cleanup "$id recording num is incorrect ($vim::recording(num))"
    }
    if {$vim::recording(events) ne {}} {
      cleanup "$id recording events are incorrect ($vim::recording(events))"
    }
    if {$dspace} {
      if {[lindex [split $cursor .] 1] != 0} {
        cleanup "$id dspace is expected when cursor is not 0"
      }
      if {[$txtt tag ranges _dspace] ne [list $cursor [$txtt index "$cursor+1c"]]} {
        cleanup "$id dspace does not match expected ([$txtt tag ranges _dspace])"
      }
    } else {
      if {[$txtt tag ranges _dspace] ne [list]} {
        cleanup "$id dspace does not match expected ([$txtt tag ranges _dspace])"
      }
    }

  }

  # Verify h and Left Vim commands
  proc run_test3 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\nthis is good"
    $txtt cursor set 2.5

    do_test $txtt 0 h     2.4
    do_test $txtt 1 {2 h} 2.2

    # Verify that if we move by more characters than column 0, we don't move past column 0
    do_test $txtt 2 {5 h} 2.0

    # Verify that the cursor will not move to the left when we are in column 0
    do_test $txtt 3 h     2.0

    $txtt cursor set 2.5

    do_test $txtt 4 Left     2.4
    do_test $txtt 5 {2 Left} 2.2
    do_test $txtt 6 {5 Left} 2.0
    do_test $txtt 7 Left     2.0

    # Cleanup
    cleanup

  }

  # Verify l and Right Vim commands
  proc run_test4 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\nthis is not bad\nthis is cool"
    $txtt cursor set 2.5

    do_test $txtt 0 l       2.6
    do_test $txtt 1 {2 l}   2.8

    # Verify that we don't advance past the end of the current line
    do_test $txtt 2 {2 0 l} 2.14

    # Verify that we don't move a single character
    do_test $txtt 3 l       2.14

    $txtt cursor set 2.5

    do_test $txtt 4 Right       2.6
    do_test $txtt 5 {2 Right}   2.8
    do_test $txtt 6 {2 0 Right} 2.14
    do_test $txtt 7 Right       2.14

    # Cleanup
    cleanup

  }

  # Verify k and Up Vim commands
  proc run_test5 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\ngood\n\nbad\nfoobar\nnice\nbetter"
    $txtt cursor set 7.0

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

    $txtt cursor set 7.0

    do_test $txtt 20 Up     6.0
    do_test $txtt 21 {2 Up} 4.0
    do_test $txtt 22 Up     3.0 1
    do_test $txtt 23 Up     2.0
    do_test $txtt 24 {5 Up} 1.0 1
    do_test $txtt 25 Up     1.0 1

    # Cleanup
    cleanup

  }

  # Verify j and Down Vim command
  proc run_test6 {} {

    # Initialize the text
    set txtt [initialize].t

    $txtt insert end "\ngood\nbad\nfoobar\nnice\n\nbetter\n\n"
    $txtt cursor set 2.0

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

    $txtt cursor set 2.0

    do_test $txtt 20 Down     3.0
    do_test $txtt 21 {2 Down} 5.0
    do_test $txtt 22 Down     6.0 1
    do_test $txtt 23 Down     7.0
    do_test $txtt 24 {5 Down} 9.0 1
    do_test $txtt 25 Down     9.0 1

    # Cleanup
    cleanup

  }

  # Verify 0 and $ Vim command
  proc run_test7 {} {

    # Initialize the widgets
    set txtt [initialize].t

    $txtt insert end "\nThis is a line\nAnother line"
    $txtt cursor set 2.5

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
    $txtt cursor set 2.0

    # Move forward by one word
    foreach {index dspace} [list 2.5 0 2.8 0 3.0 1 4.0 0 4.5 0 4.8 0 4.12 0 4.12 0] {
      do_test $txtt $i w $index $dspace
      incr i
    }

    # Move backward by one word
    foreach {index dspace} [list 4.8 0 4.5 0 4.0 0 3.0 1 2.8 0 2.5 0 2.0 0 1.0 1 1.0 1] {
      do_test $txtt $i b $index $dspace
      incr i
    }

    # Move forward by two words
    foreach {index dspace} [list 2.5 0 3.0 1 4.5 0 4.12 0 4.12 0] {
      do_test $txtt $i {2 w} $index $dspace
      incr i
    }

    # Move backward by two words
    foreach {index dspace} [list 4.5 0 3.0 1 2.5 0 1.0 1 1.0 1] {
      do_test $txtt $i {2 b} $index $dspace
      incr i
    }

    # Cleanup
    cleanup

  }

  # Move W and B Vim commands
  proc run_test9 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\nThis... is good\n\nThis... is great"
    $txtt cursor set 2.0

    # Move forward by one WORD (0-6)
    foreach {index dspace} [list 2.8 0 2.11 0 3.0 1 4.0 0 4.8 0 4.11 0 4.11 0] {
      do_test $txtt $i W $index $dspace
      incr i
    }

    # Move backward by one WORD (7-13)
    foreach {index dspace} [list 4.8 0 4.0 0 3.0 1 2.11 0 2.8 0 2.0 0 2.0 0] {
      do_test $txtt $i B $index $dspace
      incr i
    }

    # Move forward by two WORDs
    foreach {index dspace} [list 2.11 0 4.0 0 4.11 0 4.11 0] {
      do_test $txtt $i {2 W} $index $dspace
      incr i
    }

    # Move backward by two WORDs
    foreach {index dspace} [list 4.0 0 2.11 0 2.0 0 2.0 0] {
      do_test $txtt $i {2 B} $index $dspace
      incr i
    }

    # Cleanup
    cleanup

  }

  # Verify e and ge Vim commands.
  proc run_test10 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\nThis is good\n\n\nThis is good"
    $txtt cursor set 1.0

    foreach {index dspace} [list 2.3 0 2.6 0 2.11 0 5.3 0 5.6 0 5.11 0 5.11 0] {
      do_test $txtt $i e $index $dspace
      incr i
    }

    foreach {index dspace} [list 5.6 0 5.3 0 4.0 1 3.0 1 2.11 0 2.6 0 2.3 0 1.0 1 1.0 1] {
      do_test $txtt $i {g e} $index $dspace
      incr i
    }

    foreach {index dspace} [list 2.6 0 5.3 0 5.11 0 5.11 0] {
      do_test $txtt $i {2 e} $index $dspace
      incr i
    }

    foreach {index dspace} [list 5.3 0 3.0 1 2.6 0 1.0 1 1.0 1] {
      do_test $txtt $i {2 g e} $index $dspace
      incr i
    }

    # Cleanup
    cleanup

  }

  # Verify E and gE Vim commands.
  proc run_test11 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\nThis... is good\n\n\nThis... is great"
    $txtt cursor set 1.0

    # 0-8
    foreach {index dspace} [list 2.6 0 2.9 0 2.14 0 3.0 1 4.0 1 5.6 0 5.9 0 5.15 0 5.15 0] {
      do_test $txtt $i E $index $dspace
      incr i
    }

    # 9-16
    foreach {index dspace} [list 5.9 0 5.6 0 4.0 1 3.0 1 2.14 0 2.9 0 2.6 0 2.6 0] {
      do_test $txtt $i {g E} $index $dspace
      incr i
    }

    $txtt cursor set 2.0

    # 17-21
    foreach {index dspace} [list 2.9 0 3.0 1 5.6 0 5.15 0 5.15 0] {
      do_test $txtt $i {2 E} $index $dspace
      incr i
    }

    # 22-25
    foreach {index dspace} [list 5.6 0 3.0 1 2.9 0 2.9 0] {
      do_test $txtt $i {2 g E} $index $dspace
      incr i
    }

    # Cleanup
    cleanup

  }

  # Verify Return and minus Vim commands
  proc run_test12 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\n apples\n\ngrapes\n      bananas\n  milk\n\n    soup"
    $txtt cursor set 1.0

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
  proc run_test13 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\ngood\n\ngreat"
    $txtt cursor set 1.0

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
  proc run_test14 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end [string repeat "\n" 100]
    $txtt cursor set 10.0

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
  proc run_test15 {} {

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
  proc run_test16 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is something"
    $txtt cursor set 2.0

    # Move to a valid column
    do_test $txtt 0 {7 bar} 2.6

    # Move to column 0
    do_test $txtt 1 {1 bar} 2.0

    # Attempt to move to an invalidate column
    do_test $txtt 2 {2 0 bar} 2.16

    # Cleanup
    cleanup

  }

  # Verify ( and ) Vim command
  proc run_test17 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\nThis is something. This is something else.\n\nThis is great.\nThis is not."
    $txtt cursor set 1.0

    foreach {index dspace} [list 2.0 0 2.19 0 4.0 0 5.0 0 5.11 0 5.11 0] {
      do_test $txtt $i parenright $index $dspace
      incr i
    }

    foreach {index dspace} [list 5.0 0 4.0 0 2.19 0 2.0 0 1.0 1 1.0 1] {
      do_test $txtt $i parenleft $index $dspace
      incr i
    }

    foreach {index dspace} [list 2.19 0 5.0 0 5.11 0 5.11 0] {
      do_test $txtt $i {2 parenright} $index $dspace
      incr i
    }

    foreach {index dspace} [list 4.0 0 2.0 0 1.0 1 1.0 1] {
      do_test $txtt $i {2 parenleft} $index $dspace
      incr i
    }

    # Cleanup
    cleanup

  }

  # Verify { and } Vim commands
  proc run_test18 {} {

    # Initialize
    set txtt [initialize].t
    set i    0

    $txtt insert end "\nThis is the first paragraph.\nThis is still a part of the first paragraph.\n\n\nAnother paragraph.\n\nLast paragraph"
    $txtt cursor set 1.0

    # 0 - 4
    foreach {index dspace} [list 2.0 0 6.0 0 8.0 0 8.13 0 8.13 0] {
      do_test $txtt $i braceright $index $dspace
      incr i
    }

    # 5 - 9
    foreach {index dspace} [list 8.0 0 6.0 0 2.0 0 1.0 1 1.0 1] {
      do_test $txtt $i braceleft $index $dspace
      incr i
    }

    # 10 - 12
    foreach {index dspace} [list 6.0 0 8.13 0 8.13 0] {
      do_test $txtt $i {2 braceright} $index $dspace
      incr i
    }

    # 13 - 15
    foreach {index dspace} [list 6.0 0 1.0 1 1.0 1] {
      do_test $txtt $i {2 braceleft} $index $dspace
      incr i
    }

    # Cleanup
    cleanup

  }

  # Verify up/down motions over elided text
  proc run_test30 {} {

    # Initialize
    set txtt [initialize].t

    # Insert a line that we can code fold
    $txtt insert end "\nif {\$foocar} {\n  set c 0\n}\n# Another comment"
    $txtt cursor set 2.0

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
  proc run_test31 {} {

    # Initialize
    set txtt [initialize].t

    # Insert a line that we will elide some text on
    $txtt insert end "\nNi*e **bold**\nGood"
    $txtt tag configure foobar -elide 1
    $txtt tag add foobar 2.5 2.7
    $txtt cursor set 2.4

    do_test $txtt 0 l      2.7
    do_test $txtt 1 h      2.4
    do_test $txtt 20 Right 2.7
    do_test $txtt 21 Left  2.4
    do_test $txtt 2 w      2.7
    do_test $txtt 3 b      2.3

    do_test $txtt 4 {l space} 2.7
    do_test $txtt 5 BackSpace 2.4

    do_test $txtt 6 {f asterisk} 2.11
    do_test $txtt 7 {F asterisk} 2.2
    do_test $txtt 8 {t asterisk} 2.10
    do_test $txtt 9 {T asterisk} 2.3

    $txtt tag add foobar 2.11 2.13
    $txtt cursor set 2.10

    do_test $txtt 10 l 2.10
    do_test $txtt 11 w 3.0

    $txtt cursor set 2.0

    do_test $txtt 12 dollar 2.10

    $txtt tag remove foobar 1.0 end
    $txtt tag add foobar 3.0 3.2
    $txtt cursor set 3.3

    do_test $txtt 13 0 3.2
    do_test $txtt 14 b 2.11

    $txtt tag remove foobar 1.0 end
    $txtt tag add foobar 3.2 3.end
    $txtt cursor set 2.7

    do_test $txtt 15 G 3.0

    $txtt tag remove foobar 1.0 end
    $txtt insert 1.0 "here"
    $txtt tag add foobar 1.0 1.1

    do_test $txtt 16 {g g} 1.2

    # Cleanup
    cleanup

  }

  ######################################################################
  # Perform a motion selection test.
  proc do_sel_test {txtt id cmdlist sel} {

    enter $txtt $cmdlist

    if {[$txtt tag ranges sel] ne $sel} {
      cleanup "$id selection incorrect ([$txtt tag ranges sel])"
    }

  }

  # Test forward motion with character selection (inclusive selection mode)
  proc run_test60 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to inclusive
    vim::do_set_selection "inclusive"

    $txtt insert end "\nThis is so so good.\n\nThis is great."
    $txtt cursor set 2.0

    do_sel_test $txtt 0 v         {2.0 2.1}
    do_sel_test $txtt 1 l         {2.0 2.2}
    do_sel_test $txtt 2 {2 l}     {2.0 2.4}

    do_sel_test $txtt 3 {space}   {2.0 2.5}
    do_sel_test $txtt 4 {2 space} {2.0 2.7}

    do_sel_test $txtt 5 w         {2.0 2.9}
    do_sel_test $txtt 6 {2 w}     {2.0 2.15}

    do_sel_test $txtt 7 dollar    {2.0 2.19}
    do_sel_test $txtt 8 0         {2.0 2.1}
    do_sel_test $txtt 9 {5 bar}   {2.0 2.5}

    do_sel_test $txtt 10 {f g}    {2.0 2.15}
    do_sel_test $txtt 11 {0 t g}  {2.0 2.14}

    do_sel_test $txtt 12 j        {2.0 3.1}
    do_sel_test $txtt 13 Return   {2.0 4.1}
    do_sel_test $txtt 14 Right    {2.0 4.2}

    do_sel_test $txtt 15 {2 G}    {2.0 2.1}
    do_sel_test $txtt 16 Down     {2.0 3.1}
    do_sel_test $txtt 17 G        {2.0 4.1}

    do_sel_test $txtt 18 {2 G}            {2.0 2.1}
    do_sel_test $txtt 19 e                {2.0 2.4}
    do_sel_test $txtt 20 {g underscore}   {2.0 2.19}
    do_sel_test $txtt 21 {2 g underscore} {2.0 3.1}

    do_sel_test $txtt 22 {2 G parenright} {2.0 4.1}
    # do_sel_test $txtt 23 {2 G M}          {2.0 4.14}
    # do_sel_test $txtt 24 {2 G L}          {2.0 4.14}

    # Cleanup
    cleanup

  }

  # Test backword motion with character selection (inclusive selection mode)
  proc run_test61 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to inclusive
    vim::do_set_selection "inclusive"

    $txtt insert end "\nThis is so so good.\n\nThis is great."
    $txtt cursor set 2.10

    do_sel_test $txtt 0 v             {2.10 2.11}
    do_sel_test $txtt 1 h             {2.9 2.11}
    do_sel_test $txtt 2 {2 h}         {2.7 2.11}
    do_sel_test $txtt 3 b             {2.5 2.11}
    do_sel_test $txtt 4 Left          {2.4 2.11}
    do_sel_test $txtt 5 {1 1 bar 2 b} {2.5 2.11}
    do_sel_test $txtt 6 BackSpace     {2.4 2.11}
    do_sel_test $txtt 7 asciicircum   {2.0 2.11}
    do_sel_test $txtt 8 {1 1 bar 0}   {2.0 2.11}
    do_sel_test $txtt 9 {9 bar}       {2.8 2.11}
    do_sel_test $txtt 10 minus        {1.0 2.11}

    do_sel_test $txtt 11 {Escape 4 G v} {4.0 4.1}
    do_sel_test $txtt 12 k              {3.0 4.1}
    do_sel_test $txtt 13 Up             {2.0 4.1}

    do_sel_test $txtt 14 {4 G}          {4.0 4.1}
    do_sel_test $txtt 15 {g e}          {3.0 4.1}
    do_sel_test $txtt 16 {g g}          {1.0 4.1}

    # do_sel_test $txtt 17 {4 G}          {4.0 4.1}
    # do_sel_test $txtt 18 H              {1.0 4.1}

    do_sel_test $txtt 19 {2 G 1 1 bar}  {2.10 4.1}
    do_sel_test $txtt 20 {F s}          {2.8 4.1}
    do_sel_test $txtt 21 {T s}          {2.7 4.1}
    do_sel_test $txtt 22 parenleft      {2.0 4.1}

    # Cleanup
    cleanup

  }

  # Test forward motion with character selection (exclusive selection mode)
  proc run_test62 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to exclusive
    vim::do_set_selection "exclusive"

    $txtt insert end "\nThis is so so good.\n\nThis is great."
    $txtt cursor set 2.0

    do_sel_test $txtt 0 v         {}
    do_sel_test $txtt 1 l         {2.0 2.1}
    do_sel_test $txtt 2 {2 l}     {2.0 2.3}
    do_sel_test $txtt 3 space     {2.0 2.4}
    do_sel_test $txtt 4 {2 space} {2.0 2.6}
    do_sel_test $txtt 5 w         {2.0 2.8}
    do_sel_test $txtt 6 {2 w}     {2.0 2.14}
    do_sel_test $txtt 7 dollar    {2.0 2.18}
    do_sel_test $txtt 8 0         {}
    do_sel_test $txtt 9 {5 bar}   {2.0 2.4}
    do_sel_test $txtt 10 {f g}    {2.0 2.14}
    do_sel_test $txtt 11 {0 t g}  {2.0 2.13}
    do_sel_test $txtt 12 j        {2.0 3.0}
    do_sel_test $txtt 13 Return   {2.0 4.0}
    do_sel_test $txtt 14 Right    {2.0 4.1}

    do_sel_test $txtt 15 {2 G}    {}
    do_sel_test $txtt 16 Down     {2.0 3.0}
    do_sel_test $txtt 17 G        {2.0 4.0}

    do_sel_test $txtt 18 {2 G}            {}
    do_sel_test $txtt 19 e                {2.0 2.3}
    do_sel_test $txtt 20 {g underscore}   {2.0 2.18}
    do_sel_test $txtt 21 {2 g underscore} {2.0 3.0}

    do_sel_test $txtt 22 {2 G parenright} {2.0 4.0}
    # do_sel_test $txtt 23 {2 G M}          {2.0 4.13}
    # do_sel_test $txtt 24 {2 G L}          {2.0 4.13}

    # Cleanup
    cleanup

  }

  # Test backward motion with character selection (exclusive selection mode)
  proc run_test63 {} {

    # Initialize
    set txtt [initialize].t

    # Set the selection mode to exclusive
    vim::do_set_selection "exclusive"

    $txtt insert end "\nThis is so so good.\n\nThis is great."
    $txtt cursor set 2.10

    do_sel_test $txtt 0 v             {}
    do_sel_test $txtt 1 h             {2.9 2.10}
    do_sel_test $txtt 2 {2 h}         {2.7 2.10}
    do_sel_test $txtt 3 b             {2.5 2.10}
    do_sel_test $txtt 4 Left          {2.4 2.10}

    do_sel_test $txtt 5 {1 1 bar 2 b} {2.5 2.10}
    do_sel_test $txtt 6 BackSpace     {2.4 2.10}
    do_sel_test $txtt 7 asciicircum   {2.0 2.10}
    do_sel_test $txtt 8 {1 2 bar 0}   {2.0 2.10}
    do_sel_test $txtt 9 {9 bar}       {2.8 2.10}
    do_sel_test $txtt 10 minus         {1.0 2.10}

    do_sel_test $txtt 11 {Escape 4 G v} {}
    do_sel_test $txtt 12 k              {3.0 4.0}
    do_sel_test $txtt 13 Up             {2.0 4.0}

    do_sel_test $txtt 14 {4 G}          {}
    do_sel_test $txtt 15 {g e}          {3.0 4.0}
    do_sel_test $txtt 16 {g g}          {1.0 4.0}

    # do_sel_test $txtt 17 {4 G}          {4.0 4.1}
    # do_sel_test $txtt 18 H              {1.0 4.1}

    do_sel_test $txtt 19 {2 G 1 1 bar}  {2.10 4.0}
    do_sel_test $txtt 20 {F s}          {2.8 4.0}
    do_sel_test $txtt 21 {T s}          {2.7 4.0}
    do_sel_test $txtt 22 parenleft      {2.0 4.0}

    # Cleanup
    cleanup

  }

  # Verify line selection (both inclusive and exclusive since it should not matter)
  proc run_test64 {} {

    # Initialize
    set txtt  [initialize].t
    set index 0

    $txtt insert end [string repeat "\n  This is good" 100]

    foreach seltype [list inclusive exclusive] {

      # Set mode to inclusive
      vim::do_set_selection $seltype
      $txtt cursor set 10.0

      do_sel_test $txtt [expr ($index * 30) + 0]  V          {10.0 11.0}
      do_sel_test $txtt [expr ($index * 30) + 1]  j          {10.0 11.14}
      do_sel_test $txtt [expr ($index * 30) + 2]  {2 j}      {10.0 13.14}
      do_sel_test $txtt [expr ($index * 30) + 3]  Return     {10.0 14.14}
      do_sel_test $txtt [expr ($index * 30) + 4]  {2 Return} {10.0 16.14}
      do_sel_test $txtt [expr ($index * 30) + 5]  w          {10.0 16.14}
      do_sel_test $txtt [expr ($index * 30) + 6]  {2 w}      {10.0 17.14}
      do_sel_test $txtt [expr ($index * 30) + 7]  b          {10.0 16.14}
      do_sel_test $txtt [expr ($index * 30) + 8]  {1 0 l}    {10.0 16.14}
      do_sel_test $txtt [expr ($index * 30) + 9]  space      {10.0 17.14}
      do_sel_test $txtt [expr ($index * 30) + 10] BackSpace  {10.0 16.14}
      do_sel_test $txtt [expr ($index * 30) + 11] BackSpace  {10.0 16.14}
      do_sel_test $txtt [expr ($index * 30) + 12] space      {10.0 16.14}
      do_sel_test $txtt [expr ($index * 30) + 13] minus      {10.0 15.14}

      if {[$txtt index insert] ne "15.2"} {
        cleanup "One minus had bad insert ([$txtt index insert])"
      }

      do_sel_test $txtt [expr ($index * 30) + 14] {f T}      {10.0 15.14}
      do_sel_test $txtt [expr ($index * 30) + 15] {t T}      {10.0 15.14}
      do_sel_test $txtt [expr ($index * 30) + 16] {T T}      {10.0 15.14}
      do_sel_test $txtt [expr ($index * 30) + 17] {F T}      {10.0 15.14}
      do_sel_test $txtt [expr ($index * 30) + 18] {g g}      {1.0 10.14}
      do_sel_test $txtt [expr ($index * 30) + 19] G          {10.0 101.14}
      do_sel_test $txtt [expr ($index * 30) + 20] {2 0 G}    {10.0 20.14}

      enter $txtt {Escape Escape}

      incr index

    }

    # Cleanup
    cleanup

  }

  # Verify indent, unindent, shiftwidth and indent formatting
  proc run_test100 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nThis is good\n\nThis is good too"
    $txtt cursor set 2.0

    vim::do_set_shiftwidth 2

    enter $txtt {greater greater}
    if {[$txtt index insert] ne 2.2} {
      cleanup "0 Insertion cursor is not correct ([$txtt index insert])"
    }
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n\nThis is good too"} {
      cleanup "0 rshift not correct ([ostr [$txtt get 1.0 end-1c]])"
    }

    enter $txtt {2 greater greater}
    if {[$txtt index insert] ne 2.4} {
      cleanup "1 Insertion cursor is not correct ([$txtt index insert])"
    }
    if {[$txtt get 1.0 end-1c] ne "\n    This is good\n  \nThis is good too"} {
      cleanup "1 rshift not correct ([ostr [$txtt get 1.0 end-1c]])"
    }

    vim::do_set_shiftwidth 4

    enter $txtt {3 greater greater}
    if {[$txtt get 1.0 end-1c] ne "\n        This is good\n      \n    This is good too"} {
      cleanup "Right shift 3 failed ([ostr [$txtt get 1.0 end-1c]])"
    }

    enter $txtt {less less}
    if {[$txtt get 1.0 end-1c] ne "\n    This is good\n      \n    This is good too"} {
      cleanup "Left shift failed ([ostr [$txtt get 1.0 end-1c]])"
    }

    vim::do_set_shiftwidth 2

    enter $txtt {2 less less}
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \n    This is good too"} {
      cleanup "Left shift 2 failed ([ostr [$txtt get 1.0 end-1c]])"
    }

    enter $txtt {2 j equal equal}
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \n  This is good too"} {
      cleanup "Equal failed ([ostr [$txtt get 1.0 end-1c]])"
    }

    $txtt insert end "\n      This is cool"
    enter $txtt {less less}
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \nThis is good too\n      This is cool"} {
      cleanup "Text adjustment failed ([ostr [$txtt get 1.0 end-1c]])"
    }

    enter $txtt {2 equal equal}
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \n  This is good too\n  This is cool"} {
      cleanup "Equal 2 failed ([ostr [$txtt get 1.0 end-1c]])"
    }

    $txtt insert end "\nThis is wacky\n    Not this though"
    $txtt tag add sel 5.0 8.0

    enter $txtt equal
    if {[$txtt get 1.0 end-1c] ne "\n  This is good\n    \n  This is good too\n  This is cool\n  This is wacky\n  Not this though"} {
      cleanup "Selected equal failed ([ostr [$txtt get 1.0 end-1c]])"
    }

    # Cleanup
    cleanup

  }

}
