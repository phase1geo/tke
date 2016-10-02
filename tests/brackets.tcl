namespace eval brackets {

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

  proc run_test1 {} {

    # Create the editing buffer
    set txt [initialize]

    foreach test_type [list curly square paren angled] {

      array unset missing

      $txt delete 1.0 end
      $txt insert end "\n"

      if {$test_type eq "angled"} {
        syntax::set_language $txt HTML
      }

      switch $test_type {
        curly  { $txt insert end "if \{\{ \{foobar\}" }
        square { $txt insert end "if \[\[ \[foobar\]" }
        paren  { $txt insert end "if (( (foobar)" }
        angled { $txt insert end "if << <foobar>" }
      }

      # Highlight mismatching brackets
      completer::check_all_brackets $txt.t -force 1

      foreach type [list square curly paren angled] {
        set ranges [$txt tag ranges missing:$type]
        if {$test_type eq $type} {
          if {$ranges ne [list 2.3 2.5]} {
            cleanup "$type bracket not highlighted as expected ($ranges)"
          }
        } else {
          if {$ranges ne [list]} {
            cleanup "$type bracket not null as expected ($ranges)"
          }
        }
      }

    }

    # Clean up the editing buffer
    cleanup

  }

  proc run_test2 {} {

    # Create the editing buffer
    set txt [initialize]

    foreach test_type [list curly square paren angled] {

      array unset missing

      $txt delete 1.0 end
      $txt insert end "\n"

      if {$test_type eq "angled"} {
        syntax::set_language $txt HTML
      }

      switch $test_type {
        curly  { $txt insert end "if \{foobar\} \}\}" }
        square { $txt insert end "if \[foobar\] \]\]" }
        paren  { $txt insert end "if (foobar) ))" }
        angled { $txt insert end "if <foobar> >>" }
      }

      # Highlight mismatching brackets
      completer::check_all_brackets $txt.t -force 1

      foreach type [list square curly paren angled] {
        set ranges [$txt tag ranges missing:$type]
        if {$test_type eq $type} {
          if {$ranges ne [list 2.12 2.14]} {
            cleanup "$type bracket not highlighted as expected ($ranges)"
          }
        } else {
          if {$ranges ne [list]} {
            cleanup "$type bracket not null as expected ($ranges)"
          }
        }
      }

    }

    # Clean up the editing buffer
    cleanup

  }

  proc run_test3 {} {

    # Create the editing buffer
    set txt [initialize]

    foreach test_type [list curly square paren angled] {

      array unset missing

      $txt delete 1.0 end
      $txt insert end "\n"

      if {$test_type eq "angled"} {
        syntax::set_language $txt HTML
      }

      switch $test_type {
        curly  { $txt insert end "if \{foobar\} \{\{\}" }
        square { $txt insert end "if \[foobar\] \[\[\]" }
        paren  { $txt insert end "if (foobar) (()" }
        angled { $txt insert end "if <foobar> <<>" }
      }

      # Highlight mismatching brackets
      completer::check_all_brackets $txt.t -force 1

      foreach type [list square curly paren angled] {
        set ranges [$txt tag ranges missing:$type]
        if {$test_type eq $type} {
          if {$ranges ne [list 2.12 2.13]} {
            cleanup "$type bracket not highlighted as expected ($ranges)"
          }
        } else {
          if {$ranges ne [list]} {
            cleanup "$type bracket not null as expected ($ranges)"
          }
        }
      }

    }

    # Clean up the editing buffer
    cleanup

  }

}
