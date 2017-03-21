namespace eval change {

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

    return $txt.t

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

  # Verify cc Vim command
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    enter $txtt {c c}
    if {[$txtt get 1.0 end-1c] ne "\n\nThis is a line"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.0"} {
      cleanup "1 insertion cursor not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.5"} {
        cleanup "undo insertion not correct ([$txtt get 1.0 end-1c])"
      }

      enter $txtt [linsert {c c} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\n"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.0"} {
        cleanup "2 insertion cursor not correct ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    cleanup

  }

  # Verify cl Vim command
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    enter $txtt {c l}
    if {[$txtt get 1.0 end-1c] ne "\nhis is a line"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.0"} {
      cleanup "1 cursor not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "Undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.0"} {
        cleanup "Undo cursor incorrect ([$txtt index insert])"
      }

      enter $txtt [linsert {c l} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\nis is a line"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.0"} {
        cleanup "2 insertion cursor not correct ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    # Cleanup
    cleanup

  }

  # Verify cvl Vim command
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    enter $txtt {c v l}
    if {[$txtt get 1.0 end-1c] ne "\nis is a line"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.0"} {
      cleanup "1 insertion cursor is not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.0"} {
        cleanup "undo insertion cursor not correct ([$txtt index insert])"
      }

      enter $txtt [linsert {c v l} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\ns is a line"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.0"} {
        cleanup "2 cursor not correct ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    # Cleanup
    cleanup

  }

  # Verify cw Vim command
  proc run_test4 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.1
    vim::adjust_insert $txtt

    enter $txtt {c w}
    if {[$txtt get 1.0 end-1c] ne "\nT is a line"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.1"} {
      cleanup "1 insertion cursor not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "Undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.1"} {
        cleanup "Undo cursor did not work ([$txtt index insert])"
      }

      enter $txtt [linsert {c w} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\nT a line"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.1"} {
        cleanup "2 cursor not correct ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    # Cleanup
    cleanup

  }

  # Verify c$ command
  proc tbd_test5 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line\nThis is a line\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.5
    vim::adjust_insert $txtt

    enter $txtt {c dollar}
    if {[$txtt get 1.0 end-1c] ne "\nThis \nThis is a line\nThis is a line"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.5"} {
      cleanup "1 cursor not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.5"} {
        cleanup "undo cursor did not work ([$txtt index insert])"
      }

      enter $txtt [linsert {c dollar} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\nThis \nThis is a line"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.5"} {
        cleanup "2 cursor not correct ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    # Cleanup
    cleanup

  }

  # Verify c^ Vim command
  proc tbd_test6 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    enter $txtt {c asciicircum}
    if {[$txtt get 1.0 end-1c] ne "\na line"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.0"} {
      cleanup "1 cursor not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    enter $txtt u
    if {[$txtt get 1.0 end-1c] ne $start} {
      cleanup "undo did not work ([$txtt get 1.0 end-1c])"
    }
    if {[$txtt index insert] ne "2.8"} {
      cleanup "undo cursor not correct ([$txtt index insert])"
    }

    # Cleanup
    cleanup

  }

  # Verify cf Vim command
  proc run_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.1
    vim::adjust_insert $txtt

    enter $txtt {c f l}
    if {[$txtt get 1.0 end-1c] ne "\nTine"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.1"} {
      cleanup "1 cursor did not work ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.1"} {
        cleanup "undo cursor did not work ([$txtt index insert])"
      }

      enter $txtt [linsert {c f i} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\nTs a line"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.1"} {
        cleanup "2 cursor did not work ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    # Cleanup
    cleanup

  }

  # Verify ct Vim command
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.1
    vim::adjust_insert $txtt

    enter $txtt {c t l}
    if {[$txtt get 1.0 end-1c] ne "\nTline"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.1"} {
      cleanup "1 cursor did not work ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.1"} {
        cleanup "undo cursor not correct ([$txtt get 1.0 end-1c])"
      }

      enter $txtt [linsert {c t i} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\nTis a line"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.1"} {
        cleanup "2 cursor did not work ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    # Cleanup
    cleanup

  }

  # Verify cF Vim command
  proc run_test9 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    enter $txtt {c F i}
    if {[$txtt get 1.0 end-1c] ne "\nThis a line"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.5"} {
      cleanup "1 cursor not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not change ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.8"} {
        cleanup "undo cursor did not change ([$txtt index insert])"
      }

      enter $txtt [linsert {c F i} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\nTha line"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.2"} {
        cleanup "2 cursor not correct ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    # Cleanup
    cleanup

  }

  # Verify cT Vim command
  proc run_test10 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    enter $txtt {c T i}
    if {[$txtt get 1.0 end-1c] ne "\nThis ia line"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.6"} {
      cleanup "1 cursor not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.8"} {
        cleanup "undo cursor did not work ([$txtt index insert])"
      }

      enter $txtt [linsert {c T i} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\nThia line"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.3"} {
        cleanup "2 cursor not correct ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    # Cleanup
    cleanup

  }

  # Verify ch did not work
  proc run_test11 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set start "\nThis is a line"]
    $txtt edit separator
    $txtt mark set insert 2.8
    vim::adjust_insert $txtt

    enter $txtt {c h}
    if {[$txtt get 1.0 end-1c] ne "\nThis isa line"} {
      cleanup "1 change did not work ([$txtt get 1.0 end-1c])"
    }
    if {$vim::mode($txtt) ne "edit"} {
      cleanup "1 not in edit mode"
    }
    if {[$txtt index insert] ne "2.7"} {
      cleanup "1 insertion cursor not correct ([$txtt index insert])"
    }
    enter $txtt Escape

    foreach index {0 1} {

      enter $txtt u
      if {[$txtt get 1.0 end-1c] ne $start} {
        cleanup "undo did not work ([$txtt get 1.0 end-1c])"
      }
      if {[$txtt index insert] ne "2.8"} {
        cleanup "undo cursor is not correct ([$txtt index insert])"
      }

      enter $txtt [linsert {c h} $index 2]
      if {[$txtt get 1.0 end-1c] ne "\nThis ia line"} {
        cleanup "2 change did not work ([$txtt get 1.0 end-1c])"
      }
      if {$vim::mode($txtt) ne "edit"} {
        cleanup "2 not in edit mode"
      }
      if {[$txtt index insert] ne "2.6"} {
        cleanup "2 insertion cursor not correct ([$txtt index insert])"
      }
      enter $txtt Escape

    }

    # Cleanup
    cleanup

  }

}
