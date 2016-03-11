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

  # Verify the ability to enable and disable code folding as well as be
  # able to detect which mode that we are currently in.
  proc run_test1 {} {

    # Create the text widget
    set txt [initialize]

    # Get the preference setting
    set pref [preferences::get View/EnableCodeFolding]

    # Verify that the code folding mode matches the preference setting
    if {[folding::enabled $txt] != $pref} {
      cleanup "Preference setting does not match text folding status"
    }

    # Change the code folding setting
    if {$pref} {

      # Disable code folding
      folding::disable_folding $txt

      # Verify that we are disabled
      if {[folding::enabled $txt]} {
        cleanup "Disabling code folding failed"
      }

      # Re-enable code folding
      folding::enable_folding $txt

      # Verify that we are enabled
      if {![folding::enabled $txt]} {
        cleanup "Enabling code folding failed"
      }

    } else {

      # Enable code folding
      folding::enable_folding $txt

      # Verify that we are enabled
      if {![folding::enabled $txt]} {
        cleanup "Enabling code folding failed"
      }

      # Disable code folding
      folding::disable_folding $txt

      # Verify that we are disabled
      if {[folding::enabled $txt]} {
        cleanup "Disabling code folding failed"
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
    folding::enable_folding $txt

    # Check to see that a fold only detected on the correct lines
    set opened_lines [list none open none end none open none end]

    for {set i 1} {$i <= 8} {incr i} {
      if {[folding::fold_state $txt $i] ne [lindex $opened_lines [expr $i - 1]]} {
        cleanup "Fold state on line $i did not match expected ([folding::fold_state $txt $i])"
      }
    }

    # Close one of the opened folds
    folding::close_fold $txt 6
    if {[folding::fold_state $txt 6] ne "close"} {
      cleanup "Fold state is not closed ([folding::fold_state $txt 6])"
    }

    # Open the closed fold
    folding::open_fold $txt 6
    if {[folding::fold_state $txt 6] ne "open"} {
      cleanup "Fold state is not opened ([folding::fold_state $txt 6])"
    }

    # Close all foldable lines
    set closed_lines [list none close none end none close none end]

    folding::close_all_folds $txt

    for {set i 1} {$i <= 8} {incr i} {
      if {[folding::fold_state $txt $i] ne [lindex $closed_lines [expr $i - 1]]} {
        cleanup "Fold state on line $i did not match expected ([folding::fold_state $txt $i])"
      }
    }

    # Open all folded lines
    folding::open_all_folds $txt

    for {set i 1} {$i <= 8} {incr i} {
      if {[folding::fold_state $txt $i] ne [lindex $opened_lines [expr $i - 1]]} {
        cleanup "Fold state on line $i did not match expected ([folding::fold_state $txt $i])"
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

    # Make sure that folding is enabled
    folding::enable_folding $txt

    # Verify that the code folding states are correct
    set states [list none open open none end end]

    foreach order [list 0 1 0 2 0 3 2 3 1 3 0] {

      if {[expr $order & 1]} {
        if {[folding::fold_state $txt 2] eq "open"} {
          folding::close_fold $txt 2
          lset states 1 close
        }
      } else {
        if {[folding::fold_state $txt 2] eq "close"} {
          folding::open_fold $txt 2
          lset states 1 open
        }
      }

      if {[expr $order & 2]} {
        if {[folding::fold_state $txt 3] eq "open"} {
          folding::close_fold $txt 3
          lset states 2 close
        }
      } else {
        if {[folding::fold_state $txt 3] eq "close"} {
          folding::open_fold $txt 3
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
    folding::enable_folding $txt

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

}
