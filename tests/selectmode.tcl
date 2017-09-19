namespace eval selectmode {

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
  # Emulates a keystroke.
  proc enter {txtt keysyms} {

    foreach keysym $keysyms {
      if {[lsearch [list Return Escape BackSpace Delete] $keysym] != -1} {
        select::handle_[string tolower $keysym] $txtt
      } else {
        select::handle_any $txtt $keysym
      }
    }

  }
  
  ######################################################################
  # Perform test and verifies different aspects of the selection mode.
  proc do_test {txtt id cmdlist sel anchor type {cursor ""}} {

    if {$cursor eq ""} {
      if {[llength $sel] > 0} {
        set cursor [expr {$anchor ? [lindex $sel 0] : [lindex $sel end]}]
      } else {
        set cursor [$txtt index insert]
      }
    }

    enter $txtt $cmdlist
    
    if {[$txtt tag ranges sel] ne $sel} {
      cleanup "$id selection incorrect ([$txtt tag ranges sel])"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id cursor incorrect ([$txtt index insert])"
    }
    if {$select::data($txtt,anchorend) ne $anchor} {
      cleanup "$id anchorend incorrect ($select::data($txtt,anchorend))"
    }
    if {$select::data($txtt,type) ne $type} {
      cleanup "$id type incorrect ($select::data($txtt,type))"
    }

  }
  
  proc run_test1 {} {
    
    # Initialize the text widget
    set txtt [initialize]
    
    $txtt insert end [set value "This is a line "]
    $txtt edit separator
    $txtt mark set insert 1.5
    vim::adjust_insert $txtt
    
    # Make sure that our starting state is correct
    if {[$txtt tag ranges sel] ne [list]} {
      cleanup "starting selection incorrect ([$txtt tag ranges sel])"
    }
    
    # Make sure that the first word is selected
    select::set_select_mode $txtt 1
    do_test $txtt 0 {}     {1.5 1.7} 0 word
    do_test $txtt 1 Escape {}        0 none
    
    if {$select::data($txtt,mode)} {
      cleanup "Escape did not cause mode to clear"
    }
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "Escape changed text"
    }
    
    # Make sure that the next word is selected
    select::set_select_mode $txtt 1
    do_test $txtt 2 {}     {1.8 1.9} 0 word
    do_test $txtt 3 Return {1.8 1.9} 0 word
    
    if {$select::data($txtt,mode)} {
      cleanup "Return did not cause mode to clear"
    }
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "Return changed text"
    }
    
    $txtt tag remove sel 1.0 end
    
    # Make sure that text is deleted
    select::set_select_mode $txtt 1
    do_test $txtt 4 {}     {1.10 1.14} 0 word
    do_test $txtt 5 Delete {}          0 none 1.10
    
    if {$select::data($txtt,mode)} {
      cleanup "Delete did not cause mode to clear"
    }
    if {[$txtt get 1.0 end-1c] ne "This is a  "} {
      cleanup "Delete did not cause text to be removed"
    }
    
    vim::undo $txtt
    
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "Undo did not work properly"
    }
    if {[$txtt index insert] ne "1.14"} {
      cleanup "Undo did not put cursor back properly ([$txtt index insert])"
    }
    
    # Make sure that text is deleted
    select::set_select_mode $txtt 1
    do_test $txtt 6 {}        {1.10 1.14} 0 word
    do_test $txtt 7 BackSpace {}          0 none 1.10
    
    if {$select::data($txtt,mode)} {
      cleanup "Backspace did not cause mode to clear"
    }
    if {[$txtt get 1.0 end-1c] ne "This is a  "} {
      cleanup "Backspace did not cause text to be removed"
    }
    
    vim::undo $txtt
    
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "Undo did not work properly"
    }
    if {[$txtt index insert] ne "1.14"} {
      cleanup "Undo did not put cursor back properly ([$txtt index insert])"
    }
    
    # Make sure that selection mode is correct when text is preselected
    $txtt tag add sel 1.0 1.4
    $txtt mark set insert 1.4
    select::set_select_mode $txtt 1
    do_test $txtt 8 {}     {1.0 1.4} 0 char
    do_test $txtt 9 Escape {}        0 none
    
    # Clean things up
    cleanup

  }
  
  proc run_test2 {} {
    
    # Initialize
    set txtt [initialize]
    
    # Clean things up
    cleanup
    
  }

}
