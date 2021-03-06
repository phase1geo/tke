namespace eval remote {

  ######################################################################
  # Common diagnostic initialization procedure.  Returns the pathname
  # to the added text widget.
  proc initialize {} {

    variable base_dir
    variable remote

    # Load the connection information
    remote::quick_load_connections

    # Create connection name
    set remote "Home,localhost"

    # Set base directory
    if {[remote::connect $remote] == 0} {
      return -code error "Unable to connect to remote server"
    }

    # Create base directory
    if {![remote::make_directory $remote [set base_dir [file join $::tke_home remote_test]]]} {
      return -code error "Unable to create base directory on remote server"
    }

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
        if {![remote::make_directory $remote [file join $base_dir {*}$name]]} {
          return -code error "Unable to create directory on remote server"
        }
      } elseif {![remote::save_file $remote [file join $base_dir {*}$name] "" modtime]} {
        return -code error "Unable to touch file on server"
      }
    }

    # Clear the sidebar
    sidebar::clear

    # Add the base directory into the sidebar
    sidebar::add_directory $base_dir -remote $remote

  }

  ######################################################################
  # Common cleanup procedure.  If a fail message is provided, return an
  # error with the given error message.
  proc cleanup {{fail_msg ""}} {

    variable base_dir
    variable remote

    # Clear the sidebar
    sidebar::clear

    # Delete the base directory
    remote::remove_directories $remote $base_dir -force 1

    # Disconnect
    remote::disconnect $remote

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

    if {[$sidebar::widgets(tl) item $parent -text] ne "remote_test"} {
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

  proc run_test5 {} {

    # Initialize for test
    initialize

    set parent [lindex [$sidebar::widgets(tl) children {}] 0]

    # Copy the pathname of the current row
    sidebar::copy_pathname $parent

    if {[clipboard get] ne [file join $::tke_home remote_test]} {
      cleanup "Pathname was incorrect ([clipboard get])"
    }

    # Clean things up
    cleanup

  }

  proc run_test6 {} {

    # Initialize for test
    initialize

    set parent [lindex [$sidebar::widgets(tl) children {}] 0]

    if {[$sidebar::widgets(tl) item $parent -text] ne "remote_test"} {
      cleanup "Original tree node does not exist ([$sidebar::widgets(tl) item $parent -text])"
    }

    # Perform the folder rename
    sidebar::rename_folder $parent -testname [file join $::tke_home remote_test2]

    if {[file exists [file join $::tke_home remote_test]]} {
      file rename -force [file join $::tke_home remote_test2] [file join $::tke_home remote_test]
      cleanup "The remote_test directory still exists after the rename"
    }

    if {![file exists [file join $::tke_home remote_test2]]} {
      file rename -force [file join $::tke_home remote_test2] [file join $::tke_home remote_test]
      cleanup "The remote_test2 directory was not created"
    }

    # Make sure that remote_test2 was moved and not just created
    if {![file exists [file join $::tke_home remote_test2 glad.tcl]]} {
      file rename -force [file join $::tke_home remote_test2] [file join $::tke_home remote_test]
      cleanup "The remote_test2 directory was not moved"
    }

    # Make sure the directory was removed
    if {[$sidebar::widgets(tl) exists $parent]} {
      file rename -force [file join $::tke_home remote_test2] [file join $::tke_home remote_test]
      cleanup "Original tree node still exists"
    }

    set parent [$sidebar::widgets(tl) children {}]

    # Make sure that only one new node exists in root
    if {[llength $parent] != 1} {
      file rename -force [file join $::tke_home remote_test2] [file join $::tke_home remote_test]
      cleanup "More than one node exists in the root ([llength $parent])"
    }

    if {[$sidebar::widgets(tl) item [lindex $parent 0] -text] ne "remote_test2"} {
      file rename -force [file join $::tke_home remote_test2] [file join $::tke_home remote_test]
      cleanup "Tree node does not exist ([$sidebar::widgets(tl) item [lindex $parent 0] -text]"
    }

    file rename -force [file join $::tke_home remote_test2] [file join $::tke_home remote_test]

    # Clean things up
    cleanup

  }

  proc run_test7 {} {

    # Initialize for test
    initialize

    set parent [lindex [$sidebar::widgets(tl) children {}] 0]

    sidebar::remove_folder $parent

    if {[llength [$sidebar::widgets(tl) children {}]] != 0} {
      cleanup "Folder was not removed ([llength [$sidebar::widgets(tl) children {}]])"
    }

    # Clean things up
    cleanup

  }

  proc run_test8 {} {

    variable remote

    # Initialize for test
    initialize

    set parent [lindex [$sidebar::widgets(tl) children {}] 0]

    sidebar::add_parent_directory $parent

    set children [$sidebar::widgets(tl) children {}]

    if {[llength $children] != 1} {
      cleanup "More than one child belongs to root ([llength $children])"
    }

    if {[$sidebar::widgets(tl) item [lindex $children 0] -text] ne [file tail $::tke_home]} {
      cleanup "Parent directory is not displayed in root ([$sidebar::widgets(tl) item [lindex $children 0] -text])"
    }

    set children [$sidebar::widgets(tl) children [lindex $children 0]]

    set items [list]
    remote::dir_contents $remote $::tke_home items

    if {[llength $children] != [llength $items]} {
      cleanup "Parent directory contains incorrect number of items ([llength $children])"
    }

    set found 0
    foreach child $children {
      if {[$sidebar::widgets(tl) item $child -text] eq "remote_test"} {
        set found 1
        break
      }
    }

    if {!$found} {
      cleanup "Unable to find child directory"
    }

    # Clean things up
    cleanup

  }

  proc run_test9 {} {

    variable base_dir

    # Initialize
    initialize

    set parent [$sidebar::widgets(tl) children {}]

    # Create a new directory
    file mkdir [file join $base_dir blah]

    if {[llength [$sidebar::widgets(tl) children $parent]] != 3} {
      cleanup "Sidebar contains the incorrect number of children ([llength [$sidebar::widgets(tl) children $parent]])"
    }

    sidebar::refresh_directory_files $parent

    if {[llength [$sidebar::widgets(tl) children $parent]] != 4} {
      cleanup "Sidebar does not contain the correct number of children after refresh ([llength [$sidebar::widgets(tl) children $parent]])"
    }

    # Clean things up
    cleanup

  }

  proc run_test10 {} {

    variable base_dir

    # Initialize
    initialize

    set parent [lindex [$sidebar::widgets(tl) children {}] 0]

    set found ""
    foreach child [$sidebar::widgets(tl) children $parent] {
      if {[$sidebar::widgets(tl) set $child name] eq [file join $base_dir moo]} {
        set found $child
        break
      }
    }

    # Make sure that the child is correct
    if {$found eq ""} {
      cleanup "Value returned from get_index is empty"
    }

    sidebar::remove_parent_folder $found

    set children [$sidebar::widgets(tl) children {}]

    if {[llength $children] != 1} {
      cleanup "The child directory did not become the only parent ([llength $children])"
    }

    if {[$sidebar::widgets(tl) item [lindex $children 0] -text] ne "moo"} {
      cleanup "Child directory did not become the parent ([$sidebar::widgets(tl) item [lindex $children 0] -text])"
    }

    # Clean things up
    cleanup

  }

  # Verify file open/close
  proc run_test11 {} {

    variable base_dir
    variable remote

    # Initialize
    initialize

    set row [sidebar::get_index [file join $base_dir glad.tcl] $remote]

    if {$row eq ""} {
      cleanup "File was not found"
    }

    sidebar::open_file $row

    if {[$sidebar::widgets(tl) item $row -image] ne "sidebar_open"} {
      cleanup "File was not opened in sidebar ([$sidebar::widgets(tl) item $row -image])"
    }

    if {[sidebar::get_info $row file_index] == -1} {
      cleanup "File was not opened in editor"
    }

    sidebar::close_file $row

    if {[$sidebar::widgets(tl) item $row -image] ne ""} {
      cleanup "File was not closed in sidebar ([$sidebar::widgets(tl) item $row -image])"
    }

    if {[sidebar::get_info $row file_index] != -1} {
      cleanup "File was not closed in editor"
    }

    # Clean things up
    cleanup

  }

  proc run_test12 {} {

    variable base_dir
    variable remote

    # Initialize
    initialize

    set row [sidebar::get_index [file join $base_dir glad.tcl] $remote]

    sidebar::rename_file $row -testname [file join $base_dir bald.tcl]

    if {[sidebar::get_index [file join $base_dir glad.tcl] $remote] ne ""} {
      cleanup "glad.tcl was not removed from sidebar"
    }

    if {[sidebar::get_index [file join $base_dir bald.tcl] $remote] eq ""} {
      cleanup "bald.tcl was not found in sidebar"
    }

    if {[file exists [file join $base_dir glad.tcl]]} {
      cleanup "glad.tcl was found in the directory"
    }

    if {![file exists [file join $base_dir bald.tcl]]} {
      cleanup "bald.tcl was not found in the directory"
    }

    # Clean things up
    cleanup

  }

  proc run_test13 {} {

    variable base_dir
    variable remote

    # Initialize
    initialize

    set parent [lindex [$sidebar::widgets(tl) children {}] 0]
    set row    [sidebar::get_index [file join $base_dir glad.tcl] $remote]

    sidebar::duplicate_file $row

    if {[llength [$sidebar::widgets(tl) children $parent]] != 4} {
      cleanup "Duplicated file was not created ([llength [$sidebar::widgets(tl) children $parent]])"
    }

    if {[set first [sidebar::get_index [file join $base_dir "glad Copy.tcl"] $remote]] eq ""} {
      cleanup "glad Copy.tcl was not created in sidebar"
    }

    if {![file exists [file join $base_dir "glad Copy.tcl"]]} {
      cleanup "glad Copy.tcl was not created in file system"
    }

    sidebar::duplicate_file $row

    if {[llength [$sidebar::widgets(tl) children $parent]] != 5} {
      cleanup "Second duplicate file was not created ([llength [$sidebar::widgets(tl) children $parent]])"
    }

    if {[set second [sidebar::get_index [file join $base_dir "glad Copy 2.tcl"] $remote]] eq ""} {
      cleanup "glad Copy 2.tcl was not created in sidebar"
    }

    if {![file exists [file join $base_dir "glad Copy 2.tcl"]]} {
      cleanup "glad Copy 2.tcl was not created in file system"
    }

    sidebar::delete_file [list $first $second] -test 1

    if {[llength [$sidebar::widgets(tl) children $parent]] != 3} {
      cleanup "Copied files were not deleted ([llength [$sidebar::widgets(tl) children $parent]])"
    }

    if {[sidebar::get_index [file join $base_dir "glad Copy.tcl"] $remote] ne ""} {
      cleanup "glad Copy.tcl was not deleted in sidebar"
    }

    if {[file exists [file join $base_dir "glad Copy.tcl"]]} {
      cleanup "glad Copy.tcl was not deleted in file system"
    }

    if {[sidebar::get_index [file join $base_dir "glad Copy.tcl 2"] $remote] ne ""} {
      cleanup "glad Copy 2.tcl was not deleted in sidebar"
    }

    if {[file exists [file join $base_dir "glad Copy 2.tcl"]]} {
      cleanup "glad Copy 2.tcl was not deleted in file system"
    }

    # Clean things up
    cleanup

  }

  proc run_test14 {} {

    variable base_dir
    variable remote

    # Initialize the environment
    initialize

    # Get the contents of the glad.tcl file
    if {![remote::get_file $remote [file join $base_dir glad.tcl] contents modtime]} {
      cleanup "Unable to retrieve glad.tcl"
    }

    if {$contents ne "\n"} {
      cleanup "glad.tcl file contents do not match ($contents)"
    }

    if {![remote::save_file $remote [file join $base_dir glad.tcl] "New file" modtime]} {
      cleanup "Unable to write glad.tcl to remove server"
    }

    if {![remote::get_file $remote [file join $base_dir glad.tcl] contents modtime]} {
      cleanup "Unable to get glad.tcl after write"
    }

    if {$contents ne "New file\n"} {
      cleanup "File content mismatch ($contents)"
    }

    # Clean things up
    cleanup

  }

}
