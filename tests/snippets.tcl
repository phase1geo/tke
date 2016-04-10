namespace eval snippets {

  ######################################################################
  # Initializes the diagnostic and returns the pathname of the added
  # text widget.
  proc initialize {} {

    variable current_tab

    # Add a new tab
    set current_tab [gui::add_new_file end]

    # Get the current text widget
    set txt [gui::get_info $current_tab tab txt]

    # Set the language to Tcl
    syntax::set_language $txt "Tcl"

    return $txt

  }

  ######################################################################
  # Handles diagnostic cleanup and fails if there is a valid fail message.
  proc cleanup {{fail_msg ""}} {

    variable current_tab

    # Close the tab
    gui::close_tab {} $current_tab -check 0

    # If there was a fail message, exit with a failure
    if {$fail_msg ne ""} {
      return -code error $fail_msg
    }

  }
  
  # Verify a plain text snippet
  proc run_test1 {} {
    
    # Get the text widget
    set txt [initialize]
    
    set str {
      {This is a string}
      {This is a string}
    }
    
    # Insert the given snippet
    snippets::insert_snippet $txt.t [lindex $str 0]
    
    if {[$txt get 1.0 end-1c] ne [lindex $str 1]} {
      cleanup "Snippet did not expand properly ([$txt get 1.0 end-1c])"
    }
      
    # Clean things up
    cleanup

  }
  
  # Verify a variable insert
  proc run_test2 {} {
    
    # Get the text widget
    set txt [initialize]
    
    # Insert the given snippet
    snippets::insert_snippet $txt.t {$CURRENT_DATE}
    
    if {[$txt get 1.0 end-1c] ne [clock format [clock seconds] -format "%m/%d/%Y"]} {
      cleanup "Snippet did not expand properly"
    }
    
    # Clean things up
    cleanup
    
  }
  
  # Verify a conditional variable
  proc run_test3 {} {
    
    # Get the text widget
    set txt [initialize]
    
    # Insert the given snippet
    snippets::insert_snippet $txt.t {${SELECTED_TEXT:no selected text}}
    
    if {[$txt get 1.0 end-1c] ne "no selected text"} {
      cleanup "Snippet did not expand properly ([$txt get 1.0 end-1c])"
    }
    
    # Clean things up
    cleanup
    
  }

  # Verify selections
  proc run_test4 {} {
    
    # Get the text widget
    set txt [initialize]
    
    # Remove the dspace
    vim::remove_dspace $txt
    
    # Insert some text and select it
    $txt insert end "Some text"
    $txt tag add sel 1.0 1.end
    
    # Insert the given snippet
    snippets::insert_snippet $txt.t {$SELECTED_TEXT}
    
    if {[$txt get 1.0 end-1c] ne "Some textSome text"} {
      cleanup "Snippet did not expand properly ([$txt get 1.0 end-1c])"
    }
    
    # Clean things up
    cleanup
    
  }
  
  # Verify script output
  proc run_test5 {} {
    
    # Get the text widget
    set txt [initialize]
    
    # Insert the given snippet
    snippets::insert_snippet $txt.t {Some `echo text`}
    
    if {[$txt get 1.0 end-1c] ne "Some text"} {
      cleanup "Snippet did not expand properly"
    }
    
    # Clean things up
    cleanup
    
  }
  
  # Verify $0 tabstop
  proc run_test6 {} {
    
    # Get the text widget
    set txt [initialize]
    
    # Insert the given snippet
    snippets::insert_snippet $txt.t {This $0 good}
    
    if {[$txt get 1.0 end-1c] ne {This  good}} {
      cleanup "Snippet did not expand properly ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne 1.5} {
      cleanup "Insertion cursor is not on expected index"
    }
    
    # Clean things up
    cleanup
    
  }
  
  # Verify non-0 tabstop
  proc run_test7 {} {
    
    # Get the text widget
    set txt [initialize]
    
    # Insert the given snippet
    snippets::insert_snippet $txt.t {This $1 good}
    
    if {[$txt get 1.0 end-1c] ne {This  good$0}} {
      cleanup "Snippet did not expand properly ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "1.5"} {
      cleanup "Insertion cursor is not on expected index"
    }
    
    # Clean things up
    cleanup
    
  }
  
  # Verify a non-0 tabstop with a default value
  proc run_test8 {} {
    
    # Get the text widget
    set txt [initialize]
    
    # Insert the given snippet
    snippets::insert_snippet $txt.t {This ${1:is} good}
    
    if {[$txt get 1.0 end-1c] ne {This is good$0}} {
      cleanup "Snippet did not expand properly ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "1.7"} {
      cleanup "Insertion cursor is not on expected index"
    }
    
    snippets::handle_tab $txt.t
    
    if {[$txt get 1.0 end-1c] ne {This is good}} {
      cleanup "Traversal caused inserted text to change unexpectedly"
    }
    if {[$txt index insert] ne "1.12"} {
      cleanup "Insertion cursor is not on expected new index"
    }
    
    # Clean things up
    cleanup
    
  }
    
  # Verify embedded tabstops
  proc run_test9 {} {
    
    # Get the text widget
    set txt [initialize]
    
    # Insert the given snippet
    snippets::insert_snippet $txt.t {This ${1:is ${2:very}} good}
    
    if {[$txt get 1.0 end-1c] ne {This is very good$0}} {
      cleanup "Snippet did not expand properly ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "1.12"} {
      cleanup "Initial insertion cursor is not on expected index ([$txt index insert])"
    }
    if {[$txt tag ranges sel] ne "1.5 1.12"} {
      cleanup "Initial selection is not expected ([$txt tag ranges sel])"
    }
    
    snippets::handle_tab $txt.t
    
    if {[$txt get 1.0 end-1c] ne {This is very good$0}} {
      cleanup "First traversal caused inserted text to change ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "1.12"} {
      cleanup "Second insertion cursor is not on expected index ([$txt index insert])"
    }
    if {[$txt tag ranges sel] ne "1.8 1.12"} {
      cleanup "Second selection is not expected ([$txt tag ranges sel])"
    }
    
    snippets::handle_tab $txt.t
    
    if {[$txt get 1.0 end-1c] ne {This is very good}} {
      cleanup "Second traversal caused inserted text to change ([$txt get 1.0 end-1c])"
    }
    if {[$txt index insert] ne "1.17"} {
      cleanup "Third insertion cursor is not on expected index ([$txt index insert])"
    }
    if {[$txt tag ranges sel] ne ""} {
      cleanup "Third selection is not expected ([$txt tag ranges sel])"
    }
    
    # Clean things up
    cleanup
    
  }
  
}
