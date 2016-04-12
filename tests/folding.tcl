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
    gui::close_tab {} $current_tab -check 0

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
    set pref [preferences::get View/CodeFoldingMethod]

    # Verify that the code folding mode matches the preference setting
    if {[folding::get_method $txt] ne $pref} {
      cleanup "Preference setting does not match text folding status"
    }
    
    foreach method [list none manual syntax manual none syntax none] {

      # Disable code folding
      folding::set_fold_method $txt $method

      # Verify that we are disabled
      if {[folding::get_method $txt] ne $method} {
        cleanup "Setting code folding method to $method failed"
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
    $txt insert end "\n"
    $txt insert end "if {a} {\n"
    $txt insert end "  set b 0\n"
    $txt insert end "}\n"
    $txt insert end "\n"
    $txt insert end "if {c} {\n"
    $txt insert end "  set d 1\n"
    $txt insert end "}"

    # Enable code folding
    folding::add_folds $txt 1.0 end

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
    $txt insert end "\n"
    $txt insert end "if {a} {\n"
    $txt insert end "  if {b} {\n"
    $txt insert end "    set c 0\n"
    $txt insert end "  }\n"
    $txt insert end "}\n"

    # Make sure that syntax folding is enabled
    folding::add_folds $txt 1.0 end

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
    $txt insert end "\n"
    $txt insert end "for {set i 0} {i < 10} {incr i} {\n"
    $txt insert end "  puts i\n"
    $txt insert end "}\n"

    # Enable code folding
    folding::add_folds $txt 1.0 end

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
    folding::set_fold_method $txt manual
    
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
      
      if {[$txt tag ranges _folded] ne [list]} {
        cleanup "Text is not hidden ([$txt tag ranges _folded])"
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
    
    folding::set_fold_method $txt manual
    folding::close_range $txt 7.0 9.0
    folding::close_range $txt 2.0 5.0
    
    set lines [list none close none none end none close none end none]
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
    
    folding::set_fold_method $txt manual
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
    
    if {[$txt index insert] ne 2.0} {
      cleanup "Insertion cursor incorrect C ([$txt index insert])"
    }
    
    folding::jump_to $txt prev
    
    if {[$txt index insert] ne 7.0} {
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
    
    for {set i 0} {$i < 10} {incr i} {
      $txt insert end "This is line $i\n"
    }
    
    folding::set_fold_method $txt manual
    
    $txt mark set insert 5.0
    folding::close_range $txt 2.0 9.0
    
    if {[$txt index insert] ne 5.0} {
      cleanup "Insertion cursor incorrect ([$txt index insert])"
    } 
    if {[folding::fold_state $txt 2] ne "close"} {
      cleanup "Folding state is not closed ([folding::fold_state $txt 2])"
    }
    if {[lsearch [$txt tag names insert] _folded] == -1} {
      cleanup "Cursor is not hidden when it should be"
    }
    
    folding::show_line $txt 5
    
    if {[folding::fold_state $txt 2] ne "open"} {
      cleanup "Folding state is not opened ([folding::fold_state $txt 2])"
    }
    if {[lsearch [$txt tag names insert] _folded] != -1} {
      cleanup "Cursor is not shown when it should be"
    }
        
    # Clean things up
    cleanup
    
  }
  
}
