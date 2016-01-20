namespace eval vim {

  # Verify tab stop setting and getting
  proc run_test1 {} {

    # Get the current tabbar
    lassign [gui::get_info {} current {tabbar tab}] tb orig_tab
    set tf [winfo parent [winfo parent $tb]].tf

    # Add a new file to the tab bar
    set tab [gui::add_new_file end]

    # Get the text widget
    set txtt [gui::get_info $tab tab txt].t

    # Get the current tabstop
    set orig_tabstop [indent::get_tabstop $txtt]

    # Set the tabstop
    indent::set_tabstop $txtt 20

    # Get the current tabstop
    if {[indent::get_tabstop $txtt] != 20} {
      return -code error "Tabstop not set to the correct value"
    }

    # Verify that the text widget -tabs value is correct
    if {[$txtt cget -tabs] ne [list [expr 20 * [font measure [$txtt cget -font] 0]] left]} {
      return -code error "Text widget -tabs value is not set correctly"
    }

    # Set the tabstop to the original value
    indent::set_tabstop $txtt $orig_tabstop

    # Get the current tabstop
    if {[indent::get_tabstop $txtt] != $orig_tabstop} {
      return -code error "Tabstop not set to the correct value"
    }

    # Verify that the text widget -tabs value is correct
    if {[$txtt cget -tabs] ne [list [expr $orig_tabstop * [font measure [$txtt cget -font] 0]] left]} {
      return -code error "Text widget -tabs value is not set correctly"
    }

    # Close the tab
    gui::close_tab {} $tab

  }

}
