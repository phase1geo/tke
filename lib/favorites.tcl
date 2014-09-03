######################################################################
# Name:    favorites.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    07/17/2014
# Brief:   Handles functionality associated with favorite files/directories.
######################################################################

namespace eval favorites {
  
  variable favorites_file [file join $::tke_home favorites.dat]
  variable items
  
  ######################################################################
  # Loads the favorite information file into memory.
  proc load {} {
    
    variable favorites_file
    variable items
    
    set items [list]
    
    if {![catch { open $favorites_file r } rc]} {
      set items [::read $rc]
      close $rc
    }
    
    # Add a normalized
    for {set i 0} {$i < [llength $items]} {incr i} {
      lset items $i 2 [gui::normalize {*}[lrange [lindex $items $i] 0 1]]
    }
    
  }
  
  ######################################################################
  # Stores the favorite information back out to the file.
  proc store {} {
    
    variable favorites_file
    variable items
    
    if {![catch { open $favorites_file w } rc]} {
      foreach item $items {
        puts $rc [list [list {*}[lrange $item 0 1] ""]]
      }
      close $rc
    }
    
  }
  
  ######################################################################
  # Adds a file to the list of favorites.
  proc add {fname} {
    
    variable items
    
    # Only add the file if it currently does not exist
    if {[lsearch -index 2 $items $fname] == -1} {
      lappend items [list [info hostname] $fname [gui::normalize [info hostname] $fname]]
      store
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # Removes the given filename from the list of favorites.
  proc remove {fname} {
    
    variable items
    
    # Only remove the file if it currently exists in the list
    if {[set index [lsearch -index 2 $items $fname]] != -1} {
      set items [lreplace $items $index $index]
      store
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # Returns the normalized filenames based on the current host.
  proc get_list {} {
    
    variable items
    
    set item_list [list]
    
    foreach item $items {
      lappend item_list [lindex $item 2]
    }
    
    return [lsort $item_list]
    
  }
  
  ######################################################################
  # Returns 1 if the given filename is marked as a favorite.
  proc is_favorite {fname} {
    
    variable items
    
    return [expr [lsearch -index 2 $items $fname] != -1]
    
  }
  
  ######################################################################
  # Displays the launcher with favorited files/directories.
  proc launcher {} {
    
    # Add favorites to launcher
    foreach item [get_list] {
      if {[file isdirectory $item]} {
        launcher::register_temp "`FAVORITE:$item" "sidebar::add_directory $item" $item
      } else {
        launcher::register_temp "`FAVORITE:$item" "gui::add_file end $item" $item
      }
    }
    
    # Display the launcher in FAVORITE: mode
    launcher::launch "`FAVORITE:"
    
    # Unregister the favorites
    foreach item [get_list] {
      launcher::unregister "`FAVORITE:$item"
    }
    
  }
  
}

