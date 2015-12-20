namespace eval general {

  # Verify that adding a new file and closing the new file works properly
  proc run_test1 {} {

    # Get the current tabbar
    lassign [gui::get_info {} current {tabbar tab}] tb orig_tab
    set tf [winfo parent [winfo parent $tb]].tf

    # Add a new file to the tab bar
    set tab [gui::add_new_file end]

    # Make sure the tab was added to the current tabbar
    if {[gui::get_info $tab tab tabbar] ne $tb} {
      return -code error "New tab was added to the wrong tabbar"
    }

    # Check to make sure that the tab was added to the tabbar
    if {[lsearch [$tb tabs] $tab] == -1} {
      return -code error "New tab was not created"
    }

    # Make sure that the currently displayed tab frame is the new one
    if {[lsearch [pack slaves $tf] $tab] == -1} {
      return -code error "Tab frame was not displayed"
    }

    # Close the tab
    gui::close_tab {} $tab

    # Check to make sure that the tab was removed from the tabbar
    if {[lsearch [$tb tabs] $tab] != -1} {
      return -code error "New tab was not closed"
    }

    # Make sure that the current tab is the same as the one before the new addition
    if {[gui::get_info {} current tab] ne $orig_tab} {
      return -code error "Original tab was not restored properly"
    }

    return 1

  }

  # Verify that adding an existing file (in a non-lazy manner) works properly
  proc run_test2 {} {

    # Get the current tabbar
    lassign [gui::get_info {} current {tabbar tab}] tb orig_tab
    set tf [winfo parent [winfo parent $tb]].tf

    # Add a new file to the tab bar
    set tab [gui::add_file end [file join $bist::testdir test1.txt]]

    # Make sure the tab was added to the current tabbar
    if {[gui::get_info $tab tab tabbar] ne $tb} {
      return -code error "New tab was added to the wrong tabbar"
    }

    # Check to make sure that the tab was added to the tabbar
    if {[lsearch [$tb tabs] $tab] == -1} {
      return -code error "New tab was not created"
    }

    # Make sure that the currently displayed tab frame is the new one
    if {[lsearch [pack slaves $tf] $tab] == -1} {
      return -code error "Tab frame was not displayed"
    }

    # Close the tab
    gui::close_tab {} $tab

    # Check to make sure that the tab was removed from the tabbar
    if {[lsearch [$tb tabs] $tab] != -1} {
      return -code error "New tab was not closed"
    }

    # Make sure that the current tab is the same as the one before the new addition
    if {[gui::get_info {} current tab] ne $orig_tab} {
      return -code error "Original tab was not restored properly"
    }

    return 1

  }

  # Verify that adding an existing file (using -lazy) works properly
  proc run_test3 {} {

    # Get the current tabbar
    lassign [gui::get_info {} current {tabbar tab}] tb orig_tab
    set tf [winfo parent [winfo parent $tb]].tf

    # Add a new file to the tab bar
    set tab [gui::add_file end [file join $bist::testdir test1.txt]]

    # Make sure the tab was added to the current tabbar
    if {[gui::get_info $tab tab tabbar] ne $tb} {
      return -code error "New tab was added to the wrong tabbar"
    }

    # Check to make sure that the tab was added to the tabbar
    if {[lsearch [$tb tabs] $tab] == -1} {
      return -code error "New tab was not created"
    }

    # Make sure that the currently displayed tab frame is the new one
    if {[lsearch [pack slaves $tf] $tab] != -1} {
      return -code error "Tab frame was not displayed"
    }

    # Make sure that the current tab is the same as the one before the new addition
    if {[gui::get_info {} current tab] ne $orig_tab} {
      return -code error "Original tab was not restored properly"
    }

    # Close the tab
    gui::close_tab {} $tab

    # Check to make sure that the tab was removed from the tabbar
    if {[lsearch [$tb tabs] $tab] != -1} {
      return -code error "New tab was not closed"
    }

    # Make sure that the current tab is the same as the one before the new addition
    if {[gui::get_info {} current tab] ne $orig_tab} {
      return -code error "Original tab was not restored properly"
    }
    return 1

  }

}
