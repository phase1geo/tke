namespace eval formatting {

  variable current_tab

  ######################################################################
  # Initialization procedure.
  proc initialize {{lang MultiMarkdown}} {

    variable current_tab

    # Add a new file
    set current_tab [gui::add_new_file end]

    # Get the text widget
    set txt [gui::get_info $current_tab tab txt]

    # Set the current syntax to Tcl
    syntax::set_language $txt $lang

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

  # Verify formatting for MultiMarkdown
  proc run_test1 {} {

    # Initialize
    set txt [initialize MultiMarkdown]

    set types {
      {bold      ** **}
      {italics     _ _}
      {underline     \{++ ++\} }
      {strikethrough \{-- --\} }
      {highlight     \{== ==\} }
      {superscript ^ ^}
      {subscript   ~ ~}
      {code        ` `}
      {header1 # {}}
      {header2 ## {}}
      {header3 ### {}}
      {header4 #### {}}
      {header5 ##### {}}
      {header6 ###### {}}
      {unordered * {}}
      {checkbox  {[ ]} {}}
    }

    # Verify all types when text is selected
    foreach type $types {

      $txt delete 1.0 end
      $txt insert end "Make this formatted but not the rest"
      $txt tag add sel 1.5 1.19
      edit::format $txt.t [lindex $type 0]

      if {[lindex $type 2] eq ""} {
        if {[$txt get 1.0 end-1c] ne "[lindex $type 1] Make this formatted but not the rest"} {
          cleanup "A Type [lindex $type 0] did not match expected ([$txt get 1.0 end-1c])"
        }
      } else {
        if {[$txt get 1.0 end-1c] ne "Make [lindex $type 1]this formatted[lindex $type 2] but not the rest"} {
          cleanup "B Type [lindex $type 0] did not match expected ([$txt get 1.0 end-1c])"
        }
      }

    }

    # Verify all types when text is not selected
    foreach type $types {

      $txt delete 1.0 end
      $txt insert end "Make this formatted but not the rest"
      $txt cursor set 1.10
      edit::format $txt.t [lindex $type 0]

      if {[lindex $type 2] eq ""} {
        if {[$txt get 1.0 end-1c] ne "[lindex $type 1] Make this formatted but not the rest"} {
          cleanup "C Type [lindex $type 0] did not match expected ([$txt get 1.0 end-1c])"
        }
      } else {
        if {[$txt get 1.0 end-1c] ne "Make this [lindex $type 1]formatted[lindex $type 2] but not the rest"} {
          cleanup "D Type [lindex $type 0] did not match expected ([$txt get 1.0 end-1c])"
        }
      }

    }

    # Clean things up
    cleanup

  }

}
