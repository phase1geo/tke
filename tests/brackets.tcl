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
    gui::close_tab $current_tab -check 0

    set ::done 1

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
        syntax::set_language $txt Gherkin
      }

      switch $test_type {
        curly  { $txt insert end "if \{\{ \{foobar\}" }
        square { $txt insert end "if \[\[ \[foobar\]" }
        paren  { $txt insert end "if (( (foobar)" }
        angled { $txt insert end "if << <foobar>" }
      }

      set ::done 0

      # Allow some time for the highlight to occur
      after 1000 [format {

        set ranges [%s._t tag ranges _missing]

        if {$ranges ne [list 2.3 2.5]} {
          bist::brackets::cleanup "%s bracket not highlighted as expected ($ranges)"
        }

        set ::done 1

      } $txt $test_type]

      vwait ::done

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
        syntax::set_language $txt Gherkin
      }

      switch $test_type {
        curly  { $txt insert end "if \{foobar\} \}\}" }
        square { $txt insert end "if \[foobar\] \]\]" }
        paren  { $txt insert end "if (foobar) ))" }
        angled { $txt insert end "if <foobar> >>" }
      }

      set ::done 0

      after 1000 [format {

        set ranges [%s._t tag ranges _missing]

        if {$ranges ne [list 2.12 2.14]} {
          bist::brackets::cleanup "%s bracket not highlighted as expected ($ranges)"
        }

        set ::done 1

      } $txt $test_type]

      vwait ::done

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
        syntax::set_language $txt Gherkin
      }

      switch $test_type {
        curly  { $txt insert end "if \{foobar\} \{\{\}" }
        square { $txt insert end "if \[foobar\] \[\[\]" }
        paren  { $txt insert end "if (foobar) (()" }
        angled { $txt insert end "if <foobar> <<>" }
      }

      set ::done 0

      after 1000 [format {

        set ranges [%s._t tag ranges _missing]

        if {$ranges ne [list 2.12 2.13]} {
          bist::brackets::cleanup "%s bracket not highlighted as expected ($ranges)"
        }

        set ::done 1
 
      } $txt $test_type]

      vwait ::done

    }

    # Clean up the editing buffer
    cleanup

  }

}
