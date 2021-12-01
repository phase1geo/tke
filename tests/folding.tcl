namespace eval folding {

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

  # Verify the ability to change the code folding mode as well as be
  # able to detect which mode that we are currently in.
  proc run_test1 {} {

    # Create the text widget
    set txt [initialize]

    # Get the preference setting
    set pref [expr {[preferences::get View/EnableCodeFolding] ? "syntax" : "none"}]

    # Verify that the code folding mode matches the preference setting
    if {[folding::get_method $txt] ne $pref} {
      cleanup "Preference setting does not match text folding status"
    }

    if {$pref eq "syntax"} {

      foreach method [list manual indent syntax indent manual syntax] {

        switch $method {
          manual { $txt configure -indentmode OFF }
          indent { $txt configure -indentmode IND }
          syntax { $txt configure -indentmode IND+ }
        }

        # Verify that we are disabled
        if {[folding::get_method $txt] ne $method} {
          cleanup "Setting code folding method to $method failed"
        }

      }

    }

    # Clean everything up
    cleanup

  }

  # Test fold_state and ability to fold/unfold one or all lines.
  proc run_test2 {} {

    # Create the text widget
    set txt [initialize]

    # Insert text that will contain foldable text
    $txt insert end {
if {a} {
  set b 0
}

if {c} {
  set d 1
}}

    # Check to see that a fold only detected on the correct lines
    set opened_lines [list none open none end none open none end]

    for {set i 1} {$i <= 8} {incr i} {
      if {[folding::fold_state $txt $i] ne [lindex $opened_lines [expr $i - 1]]} {
        cleanup "Fold state on line $i did not match expected 1 ([folding::fold_state $txt $i])"
      }
    }

    # Close one of the opened folds
    folding::close_fold 1 $txt 6
    if {[folding::fold_state $txt 6] ne "close"} {
      cleanup "Fold state is not closed ([folding::fold_state $txt 6])"
    }

    # Open the closed fold
    folding::open_fold 1 $txt 6
    if {[folding::fold_state $txt 6] ne "open"} {
      cleanup "Fold state is not opened ([folding::fold_state $txt 6])"
    }

    # Close all foldable lines
    set closed_lines [list none close none end none close none end]

    folding::close_all_folds $txt

    for {set i 1} {$i <= 8} {incr i} {
      if {[folding::fold_state $txt $i] ne [lindex $closed_lines [expr $i - 1]]} {
        cleanup "Fold state on line $i did not match expected 2 ([folding::fold_state $txt $i])"
      }
    }

    # Open all folded lines
    folding::open_all_folds $txt

    for {set i 1} {$i <= 8} {incr i} {
      if {[folding::fold_state $txt $i] ne [lindex $opened_lines [expr $i - 1]]} {
        cleanup "Fold state on line $i did not match expected 3 ([folding::fold_state $txt $i])"
      }
    }

    # Clean everything up
    cleanup

  }

  # Test nested folds
  proc run_test3 {} {

    # Create the text widget
    set txt [initialize]

    # Insert code that contains a nested fold
    $txt insert end {
if {a} {
  if {b} {
    set c 0
  }
}}

    # Verify that the code folding states are correct
    set states [list none open open none end end]

    foreach order [list 0 1 0 2 0 3 2 3 1 3 0] {

      if {[expr $order & 1]} {
        if {[folding::fold_state $txt 2] eq "open"} {
          folding::close_fold 1 $txt 2
          lset states 1 close
        }
      } else {
        if {[folding::fold_state $txt 2] eq "close"} {
          folding::open_fold 1 $txt 2
          lset states 1 open
        }
      }

      if {[expr $order & 2]} {
        if {[folding::fold_state $txt 3] eq "open"} {
          folding::close_fold 1 $txt 3
          lset states 2 close
        }
      } else {
        if {[folding::fold_state $txt 3] eq "close"} {
          folding::open_fold 1 $txt 3
          lset states 2 open
        }
      }

      for {set i 1} {$i <= 6} {incr i} {
        if {[folding::fold_state $txt $i] ne [lindex $states [expr $i - 1]]} {
          cleanup "Fold state on line $i did not match expected, order: $order ([folding::fold_state $txt $i])"
        }
      }

    }

    # Clean things up
    cleanup

  }

  # Verify folding toggle
  proc run_test4 {} {

    # Create the text widget
    set txt [initialize]

    # Insert some text
    $txt insert end {
for {set i 0} {i < 10} {incr i} {
  puts i
}}

    if {[folding::fold_state $txt 2] ne "open"} {
      cleanup "Folding state of line 2 is not open ([folding::fold_state $txt 2])"
    }

    # Toggle the fold
    folding::toggle_fold $txt 2

    if {[folding::fold_state $txt 2] ne "close"} {
      cleanup "Folding state of line 2 is not close ([folding::fold_state $txt 2])"
    }

    # Toggle the fold again
    folding::toggle_fold $txt 2

    if {[folding::fold_state $txt 2] ne "open"} {
      cleanup "Folding state of line 2 is not open again ([folding::fold_state $txt 2])"
    }

    # Clean everything up
    cleanup

  }

  # Verify manual mode
  proc run_test5 {} {

    # Create the text widget
    set txt [initialize]

    for {set i 0} {$i < 5} {incr i} {
      $txt insert end "This is line $i\n"
    }

    for {set i 0} {$i < 5} {incr i} {
      if {[folding::fold_state $txt $i] ne "none"} {
        cleanup "Folding state of line $i is not none ([folding::fold_state $txt $i])"
      }
    }

    # Set the folding mode to manual
    $txt configure -indentmode OFF

    foreach type [list line range all] {

      # Select and fold some of the text
      $txt tag add sel 2.0 5.0
      folding::close_selected $txt

      if {[$txt tag ranges sel] ne ""} {
        cleanup "Selection was not removed ([$txt tag ranges sel])"
      }

      # Check the fold state of the current lines
      set states [list none close none none end]
      for {set i 0} {$i < 5} {incr i} {
        set line [expr $i + 1]
        if {[folding::fold_state $txt $line] ne [lindex $states $i]} {
          cleanup "Folding state of line $i is not [lindex $states $i] ([folding::fold_state $txt $line])"
        }
      }

      # Delete the fold
      switch $type {
        line  { folding::delete_fold $txt 2 }
        range { folding::delete_folds_in_range $txt 1 3 }
        all   { folding::delete_all_folds $txt }
      }

      # Verify that the folding has cleared
      for {set i 0} {$i < 5} {incr i} {
        if {[folding::fold_state $txt $i] ne "none"} {
          cleanup "Folding state of line $i is not none ([folding::fold_state $txt $i])"
        }
      }

      if {[$txt tag ranges __folded] ne [list]} {
        cleanup "Text is not hidden ([$txt tag ranges __folded])"
      }

    }

    # Clean things up
    cleanup

  }

  # Verify open methods
  proc run_test6 {} {

    # Create the text widget
    set txt [initialize]

    for {set i 0} {$i < 10} {incr i} {
      $txt insert end "This is line $i\n"
    }

    $txt configure -indentmode OFF
    folding::close_range $txt 7.0 9.0
    folding::close_range $txt 2.0 5.0

    set lines [list none close none none none end close none none end]
    for {set i 0} {$i < 10} {incr i} {
      set line [expr $i + 1]
      if {[folding::fold_state $txt $line] ne [lindex $lines $i]} {
        cleanup "Folding state of line $line is not expected ([folding::fold_state $txt $line])"
      }
    }

    foreach {index type} [list 0 line 0 line 1 range 1 range 0 all 0 all] {

      set x [expr ($index == 0) ? 1 : 6]

      switch $type {
        line {
          if {[lindex $lines $x] eq "close"} {
            folding::open_fold 1 $txt [expr ($index == 0) ? 2 : 7]
            lset lines $x open
          } else {
            folding::close_fold 1 $txt [expr ($index == 0) ? 2 : 7]
            lset lines $x close
          }
        }
        range {
          if {[lindex $lines $x] eq "close"} {
            folding::open_folds_in_range $txt [expr ($index == 0) ? 1 : 6] [expr ($index == 0) ? 3 : 8] 1
            lset lines $x open
          } else {
            folding::close_folds_in_range $txt [expr ($index == 0) ? 1 : 6] [expr ($index == 0) ? 3 : 8] 1
            lset lines $x close
          }
        }
        all {
          if {[lindex $lines $x] eq "close"} {
            folding::open_all_folds $txt
            lset lines 1 open
            lset lines 6 open
          } else {
            folding::close_all_folds $txt
            lset lines 1 close
            lset lines 6 close
          }
        }
      }

      for {set i 0} {$i < 10} {incr i} {
        set line [expr $i + 1]
        if {[folding::fold_state $txt $line] ne [lindex $lines $i]} {
          cleanup "Folding state of line $line is not expected ([folding::fold_state $txt $line])"
        }
      }

    }

    # Clean things up
    cleanup

  }

  # Verify jump functionality
  proc run_test7 {} {

    # Create the text widget
    set txt [initialize]

    for {set i 0} {$i < 10} {incr i} {
      $txt insert end "This is line $i\n"
    }

    $txt configure -indentmode OFF
    folding::close_range $txt 2.0 5.0
    folding::close_range $txt 7.0 9.0

    $txt mark set insert 1.0

    folding::jump_to $txt next

    if {[$txt index insert] ne 2.0} {
      cleanup "Insertion cursor incorrect A ([$txt index insert])"
    }

    folding::jump_to $txt next

    if {[$txt index insert] ne 7.0} {
      cleanup "Insertion cursor incorrect B ([$txt index insert])"
    }

    folding::jump_to $txt next

    if {[$txt index insert] ne 7.0} {
      cleanup "Insertion cursor incorrect C ([$txt index insert])"
    }

    folding::jump_to $txt prev

    if {[$txt index insert] ne 2.0} {
      cleanup "Insertion cursor incorrect D ([$txt index insert])"
    }

    folding::jump_to $txt prev

    if {[$txt index insert] ne 2.0} {
      cleanup "Insertion cursor incorrect E ([$txt index insert])"
    }

    folding::delete_all_folds $txt
    folding::jump_to $txt next

    if {[$txt index insert] ne 2.0} {
      cleanup "Insertion cursor incorrect F ([$txt index insert])"
    }

    # Clean things up
    cleanup

  }

  # Verify show cursor functionality
  proc run_test8 {} {

    # Create the text widget
    set txt [initialize]

    $txt configure -indentmode OFF

    for {set i 0} {$i < 10} {incr i} {
      $txt insert end "This is line $i\n"
    }

    $txt mark set insert 5.0
    folding::close_range $txt 2.0 9.0

    if {[$txt index insert] ne 5.0} {
      cleanup "Insertion cursor incorrect ([$txt index insert])"
    }
    if {[folding::fold_state $txt 2] ne "close"} {
      cleanup "Folding state is not closed ([folding::fold_state $txt 2])"
    }
    if {[lsearch [$txt tag names insert] __folded] == -1} {
      cleanup "Cursor is not hidden when it should be"
    }

    folding::show_line $txt 5

    if {[folding::fold_state $txt 2] ne "open"} {
      cleanup "Folding state is not opened ([folding::fold_state $txt 2])"
    }
    if {[lsearch [$txt tag names insert] __folded] != -1} {
      cleanup "Cursor is not shown when it should be"
    }

    # Clean things up
    cleanup

  }

  # Verify indentation code folding
  proc run_test9 {} {

    # Create text widget
    set txt [initialize]

    # Set the current syntax to Tcl
    syntax::set_language $txt None

    # Disable auto-indentation
    $txt configure -indentmode IND

    # Verify that the folding method is indent
    if {[folding::get_method $txt] ne "indent"} {
      cleanup "Folding method is not indent when it should be"
    }

    # Insert text
    $txt insert end {
This is a line
This is also a line
  Item 1
  Item 2
    Sub-item A
    Sub-item B
  Item 3

This is another line
  Item 4
This is the last line}

    set states [list none none open none open none none end none eopen none end]

    set i 1
    foreach state $states {
      if {[folding::fold_state $txt $i] ne [lindex $states [expr $i - 1]]} {
        cleanup "Fold state on line $i ([folding::fold_state $txt $i]) did not match expected 0 ([lindex $states [expr $i - 1]])"
      }
      incr i
    }

    set j 1
    foreach {line new_state fn} [list 3 close close 10 eclose close 10 eopen open 3 open open] {

      folding::${fn}_fold 1 $txt $line
      lset states [expr $line - 1] $new_state

      set i 1
      foreach state $states {
        if {[folding::fold_state $txt $i] ne [lindex $states [expr $i - 1]]} {
          cleanup "Fold state on line $i ([folding::fold_state $txt $i]) did not match expected $j ([lindex $states [expr $i - 1]])"
        }
        incr i
      }

      incr j

    }

    # Clean things up
    cleanup

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
  # Performs a folding test.
  proc do_test {txtt id cmdlist cursor folded} {

    enter $txtt $cmdlist

    if {[$txtt index insert] ne $cursor} {
      cleanup "$id insertion cursor is not correct ([$txtt index insert])"
    }
    if {[$txtt tag ranges sel] ne ""} {
      cleanup "$id selection is not correct ([$txtt tag ranges sel])"
    }
    if {$vim::mode($txtt) ne "command"} {
      cleanup "$id mode was not command"
    }
    if {$vim::operator($txtt) ne ""} {
      cleanup "$id operator was not cleared ($vim::operator($txtt))"
    }
    if {$vim::motion($txtt) ne ""} {
      cleanup "$id motion was not cleared ($vim::motion($txtt))"
    }

    check_folds $txtt $id $folded

  }

  ######################################################################
  # Checks the folded lines against the given list.
  proc check_folds {txtt id folded} {

    set folds [list]
    for {set i 0} {$i < [$txtt count -lines 1.0 end]} {incr i} {
      if {[lsearch [$txtt tag names $i.0] __folded] != -1} {
        lappend folds $i
      }
    }

    if {$folds ne $folded} {
      cleanup "$id folded lines are incorrect ($folds)"
    }

  }

  # Verify zf Vim command
  proc run_test10 {} {

    # Initialize
    set txtt [initialize].t

    # Put the folding mode into manual
    $txtt configure -indentmode OFF

    $txtt insert end "\nThis is line 2\nThis is line 3\nThis is line 4\nThis is line 5"
    $txtt mark set insert 2.0

    # Select line 3 and fold it with zf
    $txtt tag add sel 3.0 5.0
    do_test $txtt 0 {z f} 2.0 {4}

    # Verify that zd does not work when the cursor is not on the folded line
    do_test $txtt 1 {z d} 2.0 {4}

    # Undo the fold with zd
    $txtt mark set insert 3.0
    do_test $txtt 2 {z d} 3.0 {}

    do_test $txtt 3 {z f 2 j} 3.0 {4}
    do_test $txtt 4 {z d}     3.0 {}

    do_test $txtt 5 {2 z f j} 3.0 {4}
    do_test $txtt 6 {z d}     3.0 {}

    do_test $txtt 7 {z f 2 k} 1.0 {2 3}
    do_test $txtt 8 {z d}     1.0 {}

    do_test $txtt 9  {2 j 2 z f k} 1.0 {2 3}
    do_test $txtt 10 {z d}         1.0 {}

    # Cleanup
    cleanup

  }

  # Verify zF Vim command
  proc run_test11 {} {

    # Initialize
    set txtt [initialize].t

    # Put the folding mode into manual
    $txtt configure -indentmode OFF

    $txtt insert end "\nThis is line 2\nThis is line 3\nThis is line 4\nThis is line 5"
    $txtt mark set insert 2.0

    do_test $txtt 0 {z F} 2.0 {}

    do_test $txtt 1 {2 z F} 2.0 {3}
    do_test $txtt 2 {z d} 2.0 {}

    # Cleanup
    cleanup

  }

  # Verify zd and zD Vim commands
  proc run_test12 {} {

    # Initialize
    set txtt [initialize].t

    $txtt configure -indentmode OFF

    $txtt insert end "\nThis is line 2\nThis is line 3\nThis is line 4\nThis is line 5\nThis is line 6"
    $txtt mark set insert 3.0

    do_test $txtt 0 {2 z F}   3.0 {4}
    do_test $txtt 1 {k 3 z F} 2.0 {3 4 5}
    do_test $txtt 2 {z d}     2.0 {4}

    do_test $txtt 3 {3 z F} 2.0 {3 4 5}
    do_test $txtt 4 {z D}   2.0 {}

    # Cleanup
    cleanup

  }

  # Verify zE Vim command
  proc run_test13 {} {

    # Initialize
    set txtt [initialize].t

    $txtt configure -indentmode OFF

    $txtt insert end "\nThis is line 2\nThis is line 3\nThis is line 4\nThis is line 5\nThis is line 6\nThis is line 7\nThis is line 8"
    $txtt mark set insert 3.0

    do_test $txtt 0 {2 z F}     3.0 {4}
    do_test $txtt 1 {k 3 z F}   2.0 {3 4 5}
    do_test $txtt 2 {6 G 2 z F} 6.0 {3 4 5 7}
    do_test $txtt 3 {3 G z E} 3.0 {}

    do_test $txtt 4 {2 z F k 3 z F 6 G 2 z F} 6.0 {3 4 5 7}
    do_test $txtt 3 {g g z E}                 1.0 {}

    # Cleanup
    cleanup

  }

  # Verify zo, zO, zc, zC, za, zA Vim commands
  proc run_test14 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nif {1} {\n  if {1} {\n    if {1} {\n      set a 0\n    }\n  }\n}"
    $txtt mark set insert 2.0

    do_test $txtt 0 {}      2.0 {}
    do_test $txtt 1 {z c}   2.0 {3 4 5 6 7}
    do_test $txtt 2 {z o}   2.0 {}

    do_test $txtt 3 {2 z c} 2.0 {3 4 5 6 7}
    do_test $txtt 4 {z o}   2.0 {4 5 6}

    do_test $txtt 5 {3 z c} 2.0 {3 4 5 6 7}
    do_test $txtt 6 {2 z o} 2.0 {5}
    do_test $txtt 7 {3 z o} 2.0 {}

    do_test $txtt 8  {z C}   2.0 {3 4 5 6 7}
    do_test $txtt 9  {2 z o} 2.0 {5}
    do_test $txtt 10 {z C}   2.0 {3 4 5 6 7}
    do_test $txtt 11 {z O}   2.0 {}

    do_test $txtt 12 {z a}   2.0 {3 4 5 6 7}
    do_test $txtt 13 {z a}   2.0 {}

    do_test $txtt 14 {z C}   2.0 {3 4 5 6 7}
    do_test $txtt 15 {z a}   2.0 {4 5 6}
    do_test $txtt 16 {z a}   2.0 {3 4 5 6 7}
    do_test $txtt 17 {2 z a} 2.0 {5}
    do_test $txtt 16 {2 z a} 2.0 {3 4 5 6 7}

    do_test $txtt 17 {z A}   2.0 {}
    do_test $txtt 18 {z A}   2.0 {3 4 5 6 7}
    do_test $txtt 19 {z o}   2.0 {4 5 6}
    do_test $txtt 20 {2 z o} 2.0 {5}

    # Cleanup
    cleanup

  }

  # Verify zv Vim Command
  proc run_test15 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nif {1} {\n  if {1} {\n    set a 0\n  }\n  set b 0\n}"
    $txtt mark set insert 2.0

    do_test $txtt 0 {} 2.0 {}
    do_test $txtt 1 {z C} 2.0 {3 4 5 6}

    $txtt mark set insert 4.0
    do_test $txtt 2 {z v} 4.0 {}

    $txtt mark set insert 2.0
    do_test $txtt 3 {z C} 2.0 {3 4 5 6}
    $txtt mark set insert 6.0
    do_test $txtt 4 {z v} 6.0 {4}

    # Cleanup
    cleanup

  }

  # Verify zM and zR Vim commands
  proc run_test16 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nif {1} {\n  if {1} {\n    set a 0\n  }\n  set b 0\n}"
    $txtt mark set insert 1.0

    do_test $txtt 0 {}    1.0 {}
    do_test $txtt 1 {z M} 1.0 {3 4 5 6}

    $txtt mark set insert 2.0
    do_test $txtt 2 {z o} 2.0 {4}
    do_test $txtt 3 {z c} 2.0 {3 4 5 6}

    $txtt mark set insert 1.0
    do_test $txtt 4 {z R} 1.0 {}

    # Cleanup
    cleanup

  }

  # Verify zn, zN, zi and do_set_foldenable Vim commands
  proc run_test17 {} {

    # Initialize
    set txtt [initialize].t

    $txtt insert end "\nif {1} {\n  if {1} {\n    if {1} {\n      set e 0\n    }\n  }\n}"
    $txtt mark set insert 2.0

    do_test $txtt 0 {}    2.0 {}
    do_test $txtt 1 {z c} 2.0 {3 4 5 6 7}

    do_test $txtt 2 {z n} 2.0 {}
    if {[folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "1 Vim foldenable is set when it should be clear"
    }
    do_test $txtt 3 {z n} 2.0 {}
    if {[folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "2 Vim foldenable is set when it should be clear"
    }

    do_test $txtt 4 {z N} 2.0 {3 4 5 6 7}
    if {![folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "1 Vim foldenable is clear when it should be set"
    }
    do_test $txtt 5 {z N} 2.0 {3 4 5 6 7}
    if {![folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "2 Vim foldenable is clear when it should be set"
    }

    do_test $txtt 6 {z i} 2.0 {}
    if {[folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "3 Vim foldenable is set when it should be clear"
    }
    do_test $txtt 7 {z i} 2.0 {3 4 5 6 7}
    if {![folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "3 Vim foldenable is clear when it should be set"
    }

    vim::do_set_command [winfo parent $txtt] nofoldenable "" ""
    if {[folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "(nofoldenable) Fold enable was not correct"
    }
    check_folds $txtt 8 {}

    vim::do_set_command [winfo parent $txtt] foldenable "" ""
    if {![folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "(foldenable) Fold enable was not correct"
    }
    check_folds $txtt 9 {3 4 5 6 7}

    vim::do_set_command [winfo parent $txtt] nofen "" ""
    if {[folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "(nofen) Fold enable was not correct"
    }
    check_folds $txtt 8 {}

    vim::do_set_command [winfo parent $txtt] fen "" ""
    if {![folding::get_vim_foldenable [winfo parent $txtt]]} {
      cleanup "(fen) Fold enable was not correct"
    }
    check_folds $txtt 9 {3 4 5 6 7}
    # Cleanup
    cleanup

  }

  # Verify zj and zk Vim commands
  proc run_test18 {} {

    # Initialize
    set txtt [initialize].t

    foreach var [list a b c d e] {
      $txtt insert end "\nif {$var} {\n  set $var 0\n}"
    }
    $txtt mark set insert 2.0

    do_test $txtt 0 {}        2.0  {}
    do_test $txtt 1 {z c}     2.0  {3}
    do_test $txtt 2 {5 j z c} 8.0  {3 9}
    do_test $txtt 3 {5 j z c} 14.0 {3 9 15}

    do_test $txtt 4 {g g} 1.0  {3 9 15}
    do_test $txtt 5 {z j} 2.0  {3 9 15}
    do_test $txtt 6 {z j} 8.0  {3 9 15}
    do_test $txtt 7 {z j} 14.0 {3 9 15}
    do_test $txtt 8 {z j} 14.0 {3 9 15}

    do_test $txtt 10 {z k} 8.0  {3 9 15}
    do_test $txtt 11 {z k} 2.0  {3 9 15}
    do_test $txtt 12 {z k} 2.0  {3 9 15}

    do_test $txtt 13 {g g 2 z j} 8.0 {3 9 15}
    do_test $txtt 14 {2 z j}     8.0 {3 9 15}
    do_test $txtt 15 {G 3 z k}   2.0 {3 9 15}
    do_test $txtt 16 {2 z k}     2.0 {3 9 15}

    # Cleanup
    cleanup

  }

  }
