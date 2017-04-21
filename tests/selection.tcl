namespace eval selection {

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

  proc do_test {txtt id cmdlist value sel {mode "command"}} {

    enter $txtt $cmdlist

    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id text mismatched ([$txtt get 1.0 end-1c])"
    }
    if {[$txtt tag ranges sel] ne $sel} {
      cleanup "$id selection found ([$txtt tag ranges sel])"
    }
    if {$vim::mode($txtt) ne $mode} {
      cleanup "$id mode incorrect ($vim::mode($txtt))"
    }

    if {$sel eq ""} {
      enter $txtt u
    }

  }

  # Verify selection and operators in visual mode
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 {l}     "\nThis is a line" {2.0 2.6} visual:char

    # Verify an x deletion
    do_test $txtt 2 x "\ns a line" {}

    # Verify an X deletion
    do_test $txtt 3 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 4 X "\nis a line" {}

    # Verify a d deletion
    do_test $txtt 5 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 6 d "\nis a line" {}

    # Cleanup
    cleanup


  }

}
