namespace eval sidebar {

  ######################################################################
  # Common diagnostic initialization procedure.  Returns the pathname
  # to the added text widget.
  proc initialize {} {

    variable base_dir

    # Set base directory
    file mkdir [set base_dir [file join $::tke_home sidebar_test]]

    # Create directory structure
    set file_system {
      {{bar} 0}
      {{bar good.tcl} 1}
      {{bar told.tcl} 1}
      {{moo} 0}
      {{moo nice.tcl} 1}
      {{glad.tcl} 1}
    }

    # Create the filesystem
    foreach item $file_system {
      lassign $item name type
      if {$type == 0} {
        file mkdir [file join $base_dir {*}$name]
      } elseif {![catch { open [file join $base_dir {*}$name] w } rc]} {
        close $rc
      }
    }

    # Clear the sidebar
    sidebar::clear

    # Add the base directory into the sidebar
    sidebar::add_directory $base_dir

  }

  ######################################################################
  # Common cleanup procedure.  If a fail message is provided, return an
  # error with the given error message.
  proc cleanup {{fail_msg ""}} {

    variable base_dir

    # Clear the sidebar
    sidebar::clear

    # Delete the base directory
    file delete -force $base_dir

    # Output error message
    if {$fail_msg ne ""} {
      return -code error $fail_msg
    }

  }

  proc run_test1 {} {

    # Initialize the GUI
    initialize

    set children [$sidebar::widgets(tl) children {}]

    if {[llength $children] != 1} {
      cleanup "Sidebar not loaded with the text directory"
    }

    set parent [lindex $children 0]

    if {[$sidebar::widgets(tl) item $parent -open] == 0} {
      cleanup "Loaded directory is not opened"
    }

    if {[sidebar::row_type $parent] ne "root"} {
      cleanup "Loaded directory is not a root directory ([sidebar::row_type $parent])"
    }

    if {[$sidebar::widgets(tl) item $parent -text] ne "sidebar_test"} {
      cleanup "Root directory name is incorrect ([$sidebar::widgets(tl) item $parent -text])"
    }

    set children [$sidebar::widgets(tl) children $parent]

    if {[llength $children] != 3} {
      cleanup "Number of displayed children are not correct ([llength [$sidebar::widgets(tl) children $parent]])"
    }

    set i 0
    foreach {name type opened} [list bar dir 0 moo dir 0 glad.tcl file 1] {
      if {[$sidebar::widgets(tl) item [lindex $children $i] -text] ne $name} {
        cleanup "Incorrect name (exp: $name, act: [$sidebar::widgets(tl) item [lindex $children $i] -text])"
      }
      if {[$sidebar::widgets(tl) item [lindex $children $i] -open] ne $opened} {
        cleanup "Incorrect open (exp: $opened, act: [$sidebar::widgets(tl) item [lindex $children $i] -open])"
      }
      if {[sidebar::row_type [lindex $children $i]] ne $type} {
        cleanup "Incorrect type (exp: $type, act: [sidebar::row_type [lindex $children $i]])"
      }
      incr i
    }

    # Clean up things
    cleanup

  }

  # Root directory (New File)
  proc run_test2 {} {

    # Initialize the UI
    initialize

    set parent [lindex [$sidebar::widgets(tl) children {}] 0]

    # Add the file to the given folder
    sidebar::add_file_to_folder $parent -testname "test.tcl"

    set children [$sidebar::widgets(tl) children $parent]

    if {[llength $children] != 4} {
      cleanup "New file was not added to sidebar ([llength $children])"
    }

    set found ""
    foreach child $children {
      if {[$sidebar::widgets(tl) item $child -text] eq " test.tcl"} {
        if {[$sidebar::widgets(tl) item $child -image] ne "sidebar_open"} {
          cleanup "Sidebar image is incorrect ([$sidebar::widgets(tl) item $child -image])"
        }
        set found $child
        break
      }
    }

    if {$found eq ""} {
      cleanup "Sidebar item was not found"
    }

    # Close the file
    sidebar::close_file $found

    if {[llength [$sidebar::widgets(tl) children $parent]] != 4} {
      cleanup "Closed file no longer exists in the sidebar ([llength [$sidebar::widgets(tl) children $parent]])"
    }
    if {[$sidebar::widgets(tl) item $found -image] ne ""} {
      cleanup "Closed image is incorrect ([$sidebar::widgets(tl) item $found -image])"
    }

    sidebar::delete_file $found -test 1

    if {[llength [$sidebar::widgets(tl) children $parent]] != 3} {
      cleanup "File was not removed from sidebar ([llength [$sidebar::widgets(tl) children $parent]])"
    }

    # Clean things up
    cleanup

  }

  proc run_test3 {} {

    # Initialize for test
    initialize

    set parent [lindex [$sidebar::widgets(tl) children {}] 0]

    sidebar::add_folder_to_folder $parent -testname "goober"

    set children [$sidebar::widgets(tl) children $parent]

    if {[llength $children] != 4} {
      cleanup "Directory was not added to sidebar ([llength $children]"
    }

    set found ""
    foreach child $children {
      if {[$sidebar::widgets(tl) item $child -text] eq "goober"} {
        if {[$sidebar::widgets(tl) item $child -open] == 1} {
          cleanup "Directory was incorrectly opened"
        }
        set found $child
        break
      }
    }

    if {$found eq ""} {
      cleanup "Directory was not found"
    }

    sidebar::delete_folder $found -test 1

    if {[llength [$sidebar::widgets(tl) children $parent]] != 3} {
      cleanup "Directory was not deleted ([llength [$sidebar::widgets(tl) children $found]])"
    }

    # Clean things up
    cleanup

  }

  proc run_test4 {} {

    # Initialize for test
    initialize

    set parent [lindex [$sidebar::widgets(tl) children {}] 0]

    sidebar::open_folder_files $parent

    set children [$sidebar::widgets(tl) children $parent]
    set found    [list]

    foreach child $children {
      if {[$sidebar::widgets(tl) item $child -image] eq "sidebar_open"} {
        if {[sidebar::get_info $child is_dir] == 1} {
          cleanup "Opened file was a directory"
        }
        lappend found $child
        break
      }
    }

    if {[llength $found] != 1} {
      cleanup "Not all files in directory were opened ([llength $found])"
    }

    sidebar::close_folder_files $parent

    set children [$sidebar::widgets(tl) children $parent]
    set found    [list]

    foreach child $children {
      if {[$sidebar::widgets(tl) item $child -image] eq "sidebar_open"} {
        cleanup "Found opened file in directory where we shouldn't have"
      }
    }

    # Clean things up
    cleanup

  }

}
