namespace eval emmet {

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
  
  # Verify that the child operator works correctly.
  proc run_test1 {} {

    set txt [initialize]
    
    $txt insert end "\nnav>ul>li"
    $txt mark set insert end-1c
    
    emmet::expand_abbreviation {}
    
    set actual [$txt get 2.0 end-1c]
    set expect \
{<nav>
  <ul>
    <li></li>
  </ul>
</nav>}
    
    if {$actual ne $expect} {
      cleanup "nav>ul>li did not expand properly ($actual)"
    }
  
    cleanup
    
  }

}
