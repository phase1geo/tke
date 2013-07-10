# Name:    gui.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Contains all of the main GUI elements for the editor and
#          their behavior.
 
namespace eval gui {
 
  variable curr_id          0
  variable files            {}
  variable pw_index         0
  variable pw_current       0
  variable nb_index         0
  variable nb_move          ""
  variable file_move        0
  variable geometry_file    [file join $::tke_home geometry.dat]
  variable search_counts    {}
  variable sar_global       1
  variable lengths          {}
  variable user_exit_status ""
  
  array set widgets  {}
  array set language {}

  array set files_index {
    fname    0
    mtime    1
    save_cmd 2
    pane     3
    tab      4
  }
  
  #######################
  #  PUBLIC PROCEDURES  #
  #######################
  
  ######################################################################
  # Polls every 10 seconds to see if any of the loaded files have been
  # updated since the last save.
  proc poll {} {

    variable files
    variable files_index

    # Check the modification of every file in the files list
    for {set i 0} {$i < [llength $files]} {incr i} {
      set fname [lindex $files $i $files_index(fname)]
      if {$fname ne ""} {
        set mtime [lindex $files $i $files_index(mtime)]
        if {[file exists $fname]} {
          file stat $fname stat
          if {$mtime != $stat(mtime)} {
            set answer [tk_messageBox -parent . -icon question -message "Reload file?" \
              -detail $fname -type yesno -default yes]
            if {$answer eq "yes"} {
              update_file $i
            }
            lset files $i $files_index(mtime) $stat(mtime)
          }
        } elseif {$mtime ne ""} {
          set answer [tk_messageBox -parent . -icon question -message "Delete tab?" \
            -detail $fname -type yesno -default yes]
          if {$answer eq "yes"} {
            close_tab $i
          }
        }
      }
    }

    # Check again after 10 seconds
    after 10000 gui::poll

  }

  ######################################################################
  # Create the main GUI interface.
  proc create {} {
  
    variable widgets
    
    # Load the geometry information
    load_geometry
    
    wm title . "tke \[[lindex [split [info hostname] .] 0]:[pwd]\]"
    # FIXME: wm iconphoto FOOBAR
    
    # Create the panedwindow
    set widgets(pw) [ttk::panedwindow .pw -orient horizontal]
    
    # Add the file tree
    set widgets(fview) [ttk::frame $widgets(pw).ff]
    
    # Add the file tree elements
    set widgets(filetl) \
      [tablelist::tablelist $widgets(fview).tl -columns {0 {} 0 {}} -showlabels 0 -exportselection 0 \
        -treecolumn 0 -forceeditendcommand 1 -expandcommand gui::expand_directory \
        -editstartcommand "gui::filetl_edit_start_command" \
        -editendcommand   "gui::filetl_edit_end_command" \
        -xscrollcommand "utils::set_scrollbar $widgets(fview).hb" \
        -yscrollcommand "utils::set_scrollbar $widgets(fview).vb"]
    ttk::scrollbar $widgets(fview).vb -orient vertical   -command "$widgets(filetl) yview"
    ttk::scrollbar $widgets(fview).hb -orient horizontal -command "$widgets(filetl) xview"
    
    $widgets(filetl) columnconfigure 0 -name files    -editable 0
    $widgets(filetl) columnconfigure 1 -name filepath -editable 0 -hide 1
      
    bind $widgets(filetl) <<TablelistSelect>>         "gui::handle_filetl_selection"
    bind [$widgets(filetl) bodytag] <Button-3>        "gui::handle_filetl_right_click %W %x %y"
    bind [$widgets(filetl) bodytag] <Double-Button-1> "gui::handle_filetl_double_click %W %x %y"
      
    grid rowconfigure    $widgets(fview) 0 -weight 1
    grid columnconfigure $widgets(fview) 0 -weight 1
    grid $widgets(fview).tl -row 0 -column 0 -sticky news
    grid $widgets(fview).vb -row 0 -column 1 -sticky ns
    grid $widgets(fview).hb -row 1 -column 0 -sticky ew
      
    # Create panedwindow (to support split pane view)
    $widgets(pw) add [ttk::frame $widgets(pw).tf]
      
    # Create the notebook panedwindow
    set widgets(nb_pw) [ttk::panedwindow $widgets(pw).tf.nbpw -orient horizontal]
      
    # Add notebook
    add_notebook
    
    # Pack the notebook panedwindow
    pack $widgets(nb_pw) -fill both -expand yes

    # Create the information bar
    set widgets(info)        [ttk::frame .if]
    set widgets(info_label)  [ttk::label .if.l]
    set widgets(info_syntax) [syntax::create_menubutton .if.syn]
   
    pack .if.l   -side left  -padx 2 -pady 2
    pack .if.syn -side right -padx 2 -pady 2
     
    # Create the configurable response widget
    set widgets(ursp)       [ttk::frame  .rf]
    set widgets(ursp_label) [ttk::label  .rf.l]
    set widgets(ursp_entry) [ttk::entry  .rf.e]
    
    bind $widgets(ursp_entry) <Return> "set gui::user_exit_status 1"
    bind $widgets(ursp_entry) <Escape> "set gui::user_exit_status 0"
      
    grid rowconfigure    .rf 0 -weight 1
    grid columnconfigure .rf 1 -weight 1
    grid $widgets(ursp_label) -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(ursp_entry) -row 0 -column 1 -sticky news -padx 2 -pady 2
     
    # Pack the notebook
    grid rowconfigure    . 0 -weight 1
    grid columnconfigure . 0 -weight 1
    grid $widgets(pw)   -row 0 -column 0 -sticky news
    grid $widgets(ursp) -row 1 -column 0 -sticky ew
    grid $widgets(info) -row 2 -column 0 -sticky ew
    
    grid remove $widgets(ursp)

    # Create tab popup
    set widgets(menu) [menu $widgets(nb_pw).popupMenu -tearoff 0]
    $widgets(menu) add command -label "Close Tab" -command {
      gui::close_current
    }
    $widgets(menu) add command -label "Close Other Tab(s)" -command {
      gui::close_others
    }
    $widgets(menu) add command -label "Close All Tabs" -command {
      gui::close_all
    }
    $widgets(menu) add separator
    $widgets(menu) add command -label "Move to Other Pane" -command {
      gui::move_to_pane
    }
    
    # Create directory popup
    set widgets(dirmenu) [menu $widgets(fview).dirPopupMenu -tearoff 0]
    $widgets(dirmenu) add command -label "New File" -command {
      gui::add_folder_file
    }
    $widgets(dirmenu) add command -label "New Directory" -command {
      gui::add_folder
    }
    $widgets(dirmenu) add separator
    $widgets(dirmenu) add command -label "Rename Directory" -command {
      gui::rename_folder
    }
    $widgets(dirmenu) add command -label "Delete Directory" -command {
      gui::delete_folder
    }
    $widgets(dirmenu) add separator
    $widgets(dirmenu) add command -label "Remove from Sidebar" -command {
      gui::remove_folder_from_sidebar
    }
    $widgets(dirmenu) add command -label "Remove Parent from Sidebar" -command {
      gui::remove_parent_from_sidebar
    }
    
    # Create a root directory popup
    set widgets(rootmenu) [menu $widgets(fview).rootPopupMenu -tearoff 0]
    $widgets(rootmenu) add command -label "New File" -command {
      gui::add_folder_file
    }
    $widgets(rootmenu) add command -label "New Directory" -command {
      gui::add_folder
    }
    $widgets(rootmenu) add separator
    $widgets(rootmenu) add command -label "Rename Directory" -command {
      gui::rename_folder
    }
    $widgets(rootmenu) add command -label "Delete Directory" -command {
      gui::delete_folder
    }
    $widgets(rootmenu) add separator
    $widgets(rootmenu) add command -label "Remove from Sidebar" -command {
      gui::remove_folder_from_sidebar
    } 
    $widgets(rootmenu) add command -label "Add parent directory" -command {
      gui::add_parent_directory
    }
    
    # Create file popup
    set widgets(filemenu) [menu $widgets(fview).filePopupMenu -tearoff 0]
    $widgets(filemenu) add command -label "Open" -command {
      gui::open_file
    }
    $widgets(filemenu) add command -label "Rename File" -command {
      gui::rename_file
    }
    $widgets(filemenu) add command -label "Duplicate File" -command {
      gui::duplicate_file
    }
    $widgets(filemenu) add separator
    $widgets(filemenu) add command -label "Delete File" -command {
      gui::delete_file
    }
    
    # Add the menu bar
    menus::create
    
    # Show the sidebar (if necessary)
    change_sidebar_view
    
    # If the user attempts to close the window via the window manager, treat
    # it as an exit request from the menu system.
    wm protocol . WM_DELETE_WINDOW {
      menus::exit_command
    }

    # Start polling on the files
    poll
  
  }
  
  ######################################################################
  # Shows/Hides the sidebar viewer.
  proc change_sidebar_view {} {
    
    variable widgets
    
    if {$preferences::prefs(Tools/ViewSidebar)} {
      $widgets(pw) insert 0 $widgets(fview)
    } else {
      catch { $widgets(pw) forget $widgets(fview) }
    }
    
  }
  
  ######################################################################
  # Returns the filepath of the given row in the table.
  proc get_filepath {row} {
    
    variable widgets
    
    # Start with the filepath of the current row
    set filepath [$widgets(filetl) cellcget $row,filepath -text]
    
    while {[set row [$widgets(filetl) parentkey $row]] ne "root"} {
      set filepath [file join [$widgets(filetl) cellcget $row,filepath -text] $filepath]
    }
    
    return $filepath
    
  }
  
  ######################################################################
  # Handle a selection change to the sidebar.
  proc handle_filetl_selection {} {
    
    variable widgets
    variable files
    variable files_index
    
    # Get the current selection
    set selected [$widgets(filetl) curselection]
    
    # If the file is currently in the notebook, make it the current tab
    if {[$widgets(filetl) cellcget $selected,files -background] eq "yellow"} {
      set index [lsearch -index $files_index(fname) $files [get_filepath $selected]]
      set_current_tab [lindex $files $index $files_index(pane)] [lindex $files $index $files_index(tab)]
    }
    
  }
  
  ######################################################################
  # Handles right click from the filetl table.
  proc handle_filetl_right_click {W x y} {
    
    variable widgets
    
    foreach {tablelist::W tablelist::x tablelist::y} [tablelist::convEventFields $W $x $y] {}
    foreach {row col} [split [$widgets(filetl) containingcell $tablelist::x $tablelist::y] ,] {}

    if {$row != -1} {
      $widgets(filetl) selection clear 0 end
      $widgets(filetl) selection set $row
      handle_filetl_selection
      if {([$widgets(filetl) parentkey $row] eq "root") && ([file dirname [get_filepath $row]] ne "")} {
        set mnu $widgets(rootmenu)
      } elseif {[file isdirectory [get_filepath $row]] > 0} {
        set mnu $widgets(dirmenu)
      } else {
        set mnu $widgets(filemenu)
      }
      tk_popup $mnu [expr [winfo rootx $W] + $x] [expr [winfo rooty $W] + $y]
    }
    
  }
  
  ######################################################################
  # Begins the edit process.
  proc filetl_edit_start_command {tbl row col value} {
    
    return $value
    
  }
  
  ######################################################################
  # Ends the edit process.
  proc filetl_edit_end_command {tbl row col value} {
    
    variable widgets
    variable files
    variable files_index
    
    # Change the cell so that it can't be edited directory
    $tbl cellconfigure $row,$col -editable 0
    
    # Get the current pathname
    set old_filepath [get_filepath $row]
    
    # Create the new pathname
    set new_filepath [file join [file dirname $old_filepath] $value]
    
    # Place the new value in the filepath cell
    if {[$tbl parentkey $row] eq "root"} {
      $tbl cellconfigure $row,filepath -text $new_filepath
    } else {
      $tbl cellconfigure $row,filepath -text $value
    }
    
    # If this is a directory, update the filepath cell content
    if {[file isdirectory $old_filepath]} {
      $tbl cellconfigure $row,filepath -text $value
      
    # Otherwise, update the files list, if necessary
    } elseif {[$tbl cellcget $row,$col -background] eq "yellow"} {
      set index [lsearch -index 0 $files $old_filepath]
      lset files $index $files_index(fname) $new_filepath
      [lindex $widgets(nb_pw) [lindex $files $index $files_index(pane)] tab [lindex $files $index $files_index(tab)] \
        -text [file tail $value]
    }
    
    # Perform the rename operation
    file rename -force $old_filepath $new_filepath

    return $value

  }
  
  ######################################################################
  # Handles double-click from the filetl table.
  proc handle_filetl_double_click {W x y} {
    
    variable widgets
    
    foreach {tablelist::W tablelist::x tablelist::y} [tablelist::convEventFields $W $x $y] {}
    foreach {row col} [split [$widgets(filetl) containingcell $tablelist::x $tablelist::y] ,] {}

    if {($row != -1) && [file isfile [get_filepath $row]]} {
      $widgets(filetl) selection clear 0 end
      $widgets(filetl) selection set $row
      open_file  
    }

  }
  
  ######################################################################
  # Adds a new file to the currently selected folder.
  proc add_folder_file {} {
    
    variable widgets
    
    # Get the currently selected row
    set selected [$widgets(filetl) curselection]
    
    # Get the directory pathname
    set dirpath [get_filepath $selected]
    
    # Expand the directory
    $widgets(filetl) expand $selected -partly
    
    # Add a new file to the directory
    set key [$widgets(filetl) insertchild $selected 0 [list "Untitled" "Untitled"]]
    
    # Highlight the file in the file browser
    $widgets(filetl) cellconfigure $key,files -background "yellow"
    
    # Create the file
    exec touch [set file [file join $dirpath "Untitled"]]
    
    # Create an empty file
    add_file end $file
    
    # Make the new file editable
    rename_file $key
    
  }
  
  ######################################################################
  # Adds a new folder to the currently selected folder.
  proc add_folder {} {
    
    variable widgets
    
    # Get the currently selected row
    set selected [$widgets(filetl) curselection]
    
    # Get the directory pathname
    set dirpath [get_filepath $selected]
    
    # Expand the directory
    $widgets(filetl) expand $selected -partly
    
    # Add a new folder to the directory
    set key [$widgets(filetl) insertchild $selected 0 [list "Folder" "Folder"]]
    
    # Create the directory
    file mkdir [file join $dirpath "Folder"]
    
    # Allow the user to rename the folder
    rename_folder $key
    
  }
  
  ######################################################################
  # Allows the user to rename the currently selected folder.
  proc rename_folder {{row ""}} {
    
    variable widgets
    
    # Get the currently selected row
    if {$row eq ""} {
      set row [$widgets(filetl) curselection]
    }
    
    # Make the row editable
    $widgets(filetl) cellconfigure $row,files -editable 1
    $widgets(filetl) editcell $row,files
    
  }
  
  ######################################################################
  # Allows the user to delete the currently selected folder.
  proc delete_folder {} {
    
    variable widgets
    
    if {[tk_messageBox -parent . -type yesno -default yes -message "Delete directory?"] eq "yes"} {
      
      # Get the currently selected row
      set selected [$widgets(filetl) curselection]
      
      # Get the directory pathname
      set dirpath [get_filepath $selected]
      
      # Remove the directory from the file browser
      $widgets(filetl) delete $selected
      
      # Delete the folder
      file delete -force $dirpath
      
    }
 
  }
  
  ######################################################################
  # Removes the selected folder from the sidebar.
  proc remove_folder_from_sidebar {} {
    
    variable widgets
    
    # Get the currently selected row
    set selected [$widgets(filetl) curselection]
    
    # Delete the row and its children
    $widgets(filetl) delete $selected
    
  }
  
  ######################################################################
  # Removes the parent(s) of the currently selected folder from the sidebar.
  proc remove_parent_from_sidebar {} {
    
    variable widgets
    
    # Get the currently selected row
    set selected [$widgets(filetl) curselection]
    
    # Find the child index of the ancestor of the root
    set child $selected
    while {1} {
      if {[set parent [$widgets(filetl) parentkey $child]] eq "root"} {
        break
      }
      set child $parent
    }
    
    # Put the full pathname in the filepath cell
    $widgets(filetl) cellconfigure $selected,filepath -text [get_filepath $selected]

    # Move the currently selected row to root
    $widgets(filetl) move $selected root [$widgets(filetl) childindex $child]
    
    # Delete the child tree
    $widgets(filetl) delete $child
    
  }
 
  ######################################################################
  # Opens the currently selected file in the notebook.
  proc open_file {} {
    
    variable widgets
    
    # Get the current selection
    set selected [$widgets(filetl) curselection]
    
    # Get the filename of the currently selected row
    set fname [get_filepath $selected]
    
    # Add the file to the notebook
    add_file end $fname
    
  }
  
  ######################################################################
  # Allow the user to rename the currently selected file in the file
  # browser.
  proc rename_file {{row ""}} {
    
    variable widgets
    
    # Get the current selection
    if {$row eq ""} {
      set row [$widgets(filetl) curselection]
    }
    
    # Make the row editable
    $widgets(filetl) cellconfigure $row,files -editable 1
    $widgets(filetl) editcell $row,files
    
  }
  
  ######################################################################
  # Creates a duplicate of the currently selected file, adds it to the
  # sidebard and allows the user to modify its name.
  proc duplicate_file {} {
    
    variable widgets
    
    # Get the current selection
    set row [$widgets(filetl) curselection]
    
    # Get the filename of the current selection
    set fname [get_filepath $row]
    
    # Create the default name of the duplicate file
    set dup_fname "[file rootname $fname] Copy[file extension $fname]"
    set num       1
    while {[file exists $dup_fname]} {
      set dup_fname "[file rootname $fname] Copy [incr num][file extension $fname]"
    }
    
    # Copy the file to create the duplicate
    file copy $fname $dup_fname
    
    # Add the file to the sidebar (just below the currently selected line)
    set new_row [$widgets(filetl) insertchild [$widgets(filetl) parentkey $row] [expr [$widgets(filetl) childindex $row] + 1] \
      [list [file tail $dup_fname] [file tail $dup_fname]]]
    
    # Make the new row editable
    $widgets(filetl) cellconfigure $new_row,files -editable 1
    $widgets(filetl) editcell      $new_row,files
    
  }
  
  ######################################################################
  # Deletes the currently selected file.
  proc delete_file {} {
    
    variable widgets
    variable files
    
    # Get confirmation from the user
    if {[tk_messageBox -parent . -type yesno -default yes -message "Delete file?"] eq "yes"} {
    
      # Get the current selection
      set selected [$widgets(filetl) curselection]
    
      # Get the full pathname
      set fname [get_filepath $selected]
    
      # Close the tab if the file is currently in the notebook
      if {[$widgets(filetl) cellcget $selected,files -background] eq "yellow"} {
        set index [lsearch -index 0 $files $fname]
        close_tab [lindex $files $index 3] [lindex $files $index 4]
      }
      
      # Delete the row in the table
      $widgets(filetl) delete $selected
    
      # Delete the file
      file delete -force $fname
      
    }
    
  }

  ######################################################################
  # Handles a tab move start event.
  proc tab_move_start {W x y} {
  
    variable pw_current
    variable nb_move
    variable file_move
    variable last_x
  
    if {[set tabid [$W index @$x,$y]] ne ""} {
      set nb_move   $tabid
      set file_move [get_file_index $pw_current $tabid]
      set last_x    $x
    } else {
      set nb_move ""
    }
  
  }
  
  ######################################################################
  # Handles a tab move motion.
  proc tab_move_motion {W x y} {
    
    variable pw_current
    variable nb_move
    variable file_move
    variable last_x
    variable files
    variable files_index
    
    if {[set tabid [$W index @$x,$y]] ne ""} {
      if {($nb_move ne "") && \
          ((($nb_move > $tabid) && ($x < $last_x)) || \
           (($nb_move < $tabid) && ($x > $last_x)))} {
        set tab   [lindex [$W tabs] $nb_move]
        set title [$W tab $nb_move -text]
        $W forget $nb_move
        $W insert [expr {($tabid == [$W index end]) ? "end" : $tabid}] $tab -text $title
        $W select $tabid
        set file_indices [lsearch -all -index $files_index(pane) $files $pw_current]
        if {$nb_move > $tabid} {
          foreach index $file_indices {
            set tab [lindex $files $index $files_index(tab)]
            if {($tab < $nb_move) && ($tab >= $tabid)} {
              lset files $index $files_index(tab) [expr $tab + 1]
            }
          }
        } else {
          foreach index $file_indices {
            set tab [lindex $files $index $files_index(tab)]
            if {($tab <= $tabid) && ($tab > $nb_move)} {
              lset files $index $files_index(tab) [expr $tab - 1]
            }
          }
        }
        lset files $file_move $files_index(tab) $tabid
        set nb_move $tabid
      }
      set last_x $x
    }
    
  }
  
  ######################################################################
  # Handles the end of a tab move.
  proc tab_move_end {W x y} {
 
    variable nb_move

    set nb_move ""

  }

  ######################################################################
  # Save the window geometry to the geometry.dat file.
  proc save_geometry {} {
    
    variable geometry_file
    
    if {![catch "open $geometry_file w" rc]} {
      puts $rc [wm geometry .]
      close $rc
    }
    
  }
  
  ######################################################################
  # Loads the geometry information (if it exists) and changes the current
  # window geometry to match the read value.
  proc load_geometry {} {
    
    variable geometry_file
    
    if {![catch "open $geometry_file r" rc]} {
      wm geometry . [string trim [read $rc]]
      close $rc
    }
    
  }
  
  ######################################################################
  # Makes the next tab in the notebook viewable.
  proc next_tab {} {
  
    variable widgets
    variable pw_current

    # Get the current notebook
    set nb [lindex $widgets(nb_pw) $pw_current]
    
    set index [expr [$nb index current] + 1]
    
    # If the new tab index is at the end, circle to the first tab
    if {$index == [$nb index end]} {
      set index 0
    }
    
    # Select the next tab
    $nb select $index
    
  }
  
  ######################################################################
  # Makes the previous tab in the notebook viewable.
  proc previous_tab {} {
  
    variable widgets
    variable pw_current

    # Get the current notebook
    set nb [lindex $widgets(nb_pw) $pw_current]
    
    # Get the current index
    set index [expr [$nb index current] - 1]
    
    # If the new tab index is at the less than 0, circle to the last tab
    if {$index == -1} {
      set index [expr [$nb index end] - 1]
    }
    
    # Select the previous tab
    $nb select $index
    
  }
  
  ######################################################################
  # Adds the parent directory to the sidebar of the currently selected
  # row.
  proc add_parent_directory {} {
    
    variable widgets
    
    # Get the currently selected row
    set selected [$widgets(filetl) curselection]
    
    # Add the parent directory to the sidebar
    add_directory [file dirname [get_filepath $selected]]
    
  }
  
  ######################################################################
  # Adds the given directory which displays within the file browser.
  proc add_directory {dir} {

    variable widgets
    
    # Get the length of the directory
    set dirlen [string length $dir]
    
    # Initialize the bgproc updater
    bgproc::update 1
    
    # Check to see if the directory root has already been added
    foreach child [$widgets(filetl) childkeys root] {
      set filepath [$widgets(filetl) cellcget $child,filepath -text]
      set complen  [string length $filepath]
      if {[string compare -length $complen $filepath $dir] == 0} {
        foreach name [file split [string range $dir $complen end]] {
          foreach grandchild [$widgets(filetl) childkeys $child] {
            if {[$widgets(filetl) cellcget $grandchild,files -text] eq $name} {
              set child $grandchild
              break
            }
          }
        }
        $widgets(filetl) expand $child -partly
        update_directory $child
        return
      } elseif {[string compare -length $dirlen $filepath $dir] == 0} {
        add_subdirectory root $dir $child
        return
      }
    }
    
    # Recursively add directories to the sidebar
    add_subdirectory root $dir

  }

  ######################################################################
  # Recursively adds the current directory and all subdirectories and files
  # found within it to the sidebar.
  proc add_subdirectory {parent dir {movekey ""}} {
    
    variable widgets
    variable files
    variable files_index
    
    if {[file exists $dir]} {
    
      # Add the directory to the sidebar
      if {$parent eq "root"} {
        set parent [$widgets(filetl) insertchild $parent end [list [file tail $dir] $dir]]
      }

      # Add all of the stuff within this directory
      foreach name [lsort [glob -nocomplain -directory $dir *]] {
        if {[file isdirectory $name]} {
          if {($movekey ne "") && ([get_filepath $movekey] eq $name)} {
            $widgets(filetl) move $movekey $parent end
          } else {
            set child [$widgets(filetl) insertchild $parent end [list [file tail $name] [file tail $name]]]
            $widgets(filetl) collapse $child
          }
        } else {
          set key [$widgets(filetl) insertchild $parent end [list [file tail $name] [file tail $name]]]
          if {[lsearch -index $files_index(fname) $files $name] != -1} {
            $widgets(filetl) cellconfigure $key,files -background yellow
          }
        }
        bgproc::update
      }
    
    }
    
  }
  
  ######################################################################
  # Expands the currently selected directory.
  proc expand_directory {tbl row} {
    
    # Clean the subdirectory
    foreach child [$tbl childkeys $row] {
      $tbl delete $child
    }

    # Add the missing subdirectory
    add_subdirectory $row [get_filepath $row]
    
  }
  
  ######################################################################
  # Update the given directory to include (or uninclude) new file
  # information.
  proc update_directory {parent} {
    
    variable widgets
    
    # Get the directory contents
    set dir_files [lassign [lsort [glob -nocomplain -tails -directory [get_filepath $parent] *]] dir_file]
    
    foreach child [$widgets(filetl) childkeys $parent] {
      set tl_file [$widgets(filetl) cellcget $child,files -text]
      set compare [string compare $tl_file $dir_file]
      if {$compare == -1} {
        $widgets(filetl) delete $child
      } else {
        while {1} {
          if {$compare == 1} {
            $widgets(filetl) insertchild $parent [$widgets(filetl) childindex $child] [list $dir_file $dir_file]
          }
          set dir_files [lassign $dir_files dir_file]
          if {$compare == 0} { break }
          set compare [string compare $tl_file $dir_file]
        }
      }
    }
        
  }
  
  ######################################################################
  # Highlights (or dehighlights) the given filename in the file system
  # sidebar.
  proc highlight_filename {fname highlight} {
    
    variable widgets
    
    for {set i 0} {$i < [$widgets(filetl) size]} {incr i} {
      if {[get_filepath $i] eq $fname} {
        if {$highlight} {
          $widgets(filetl) cellconfigure $i,files -background yellow
        } else {
          $widgets(filetl) cellconfigure $i,files -background white
        }
        return
      }
    }
    
  }
  
  ######################################################################
  # Adjusts the tab indices when a new tab is inserted into a pane.
  proc adjust_tabs_for_insert {index} {
  
    # Move the tabs in the current pane to make room
    if {$index ne "end"} {
      foreach file_index [lsearch -all -index $files_index(pane) $files $pw_current] {
        if {[set tab [lindex $files $file_index $files_index(tab)]] >= $index} {
          lset files $file_index $files_index(tab) [expr $tab + 1]
        }
      }
    }
    
  }
  
  ######################################################################
  # Adds a new file to the editor pane.
  proc add_new_file {index} {
  
    variable widgets
    variable files
    variable files_index
    variable pw_current
    
    # Adjust the tab indices
    adjust_tabs_for_insert $index
    
    # Get the current index
    set w [insert_tab $index "Untitled"]
    
    # Create the file info structure
    set file_info [lrepeat [array size files_index] ""]
    lset file_info $files_index(fname)    ""
    lset file_info $files_index(mtime)    ""
    lset file_info $files_index(save_cmd) ""
    lset file_info $files_index(pane)     $pw_current
    lset file_info $files_index(tab)      [[current_notebook] index $w]
 
    # Add the file information to the files list
    lappend files $file_info
    
    # Add the current directory
    add_directory [file normalize [pwd]]
    
    # Run any plugins that need to be run when a file is opened
    plugins::handle_on_open [expr [llength $files] - 1]
    
  }
  
  ######################################################################
  # Creates a new tab for the given filename specified at the given index
  # tab position.
  proc add_file {index fname {save_command ""}} {
  
    variable widgets
    variable files
    variable files_index
    variable pw_current

    # Get the current notebook
    set nb [current_notebook]
    
    # If the file is already loaded, display the tab
    if {[set file_index [lsearch -index $files_index(fname) $files $fname]] != -1} {
      
      $nb select [lindex $files $file_index $files_index(tab)]
      
    # Otherwise, load the file in a new tab
    } else {
    
      # Adjust tab indices
      adjust_tabs_for_insert $index
  
      # Add the tab to the editor frame
      set w [insert_tab $index [file tail $fname]]
      
      # Get the nb_index
      set nb_index [$nb index $w]
      
      # Create the file information
      set file_info [lrepeat [array size files_index] ""]
      lset file_info $files_index(fname)    $fname
      lset file_info $files_index(mtime)    ""
      lset file_info $files_index(save_cmd) $save_command
      lset file_info $files_index(pane)     $pw_current
      lset file_info $files_index(tab)      $nb_index

      if {![catch "open $fname r" rc]} {
    
        # Read the file contents and insert them
        $w.tf.txt insert end [string range [read $rc] 0 end-1]
      
        # Close the file
        close $rc
      
        # Change the text to unmodified
        $w.tf.txt edit modified false
        
        # Set the insertion mark to the first position
        $w.tf.txt mark set insert 1.0
        
        # Perform an insertion adjust, if necessary
        vim::adjust_insert $w.tf.txt.t
      
        file stat $fname stat
        lset file_info $files_index(mtime) $stat(mtime)
        lappend files $file_info
 
      } else {
 
        lappend files $file_info
 
      }
 
      # Change the tab text
      $nb tab $nb_index -text [file tail $fname]
      
    }
    
    # Add the file's directory to the sidebar
    add_directory [file dirname [file normalize $fname]]
    
    # Highlight the file in the sidebar
    highlight_filename $fname 1
    
    # Run any plugins that should run when a file is opened
    plugins::handle_on_open [expr [llength $files] - 1]
 
  }
  
  ######################################################################
  # Normalizes the given filename and resolves any NFS mount information if
  # the specified host is not the current host.
  proc normalize {host fname} {
    
    # Perform a normalization of the file
    set fname [file normalize $fname]
    
    # If the host does not match our host, handle the NFS mount normalization
    if {$host ne [info hostname]} {
      array set nfs_mounts $preferences::prefs(NFSMounts)
      if {[info exists nfs_mounts($host)]} {
        lassign $nfs_mounts($host) mount_dir shortcut
        set shortcut_len [string length $shortcut]
        if {[string equal -length $shortcut_len $shortcut $fname]} {
          set fname [string replace $fname 0 [expr $shortcut_len - 1] $mount_dir]
        }
      }
    }
    
    return $fname
    
  }
  
  ######################################################################
  # Add a list of files to the editor panel and raise the window to
  # make it visible.
  proc add_files_and_raise {host index args} {
  
    # Add the list of files to the editor panel.
    foreach fname [lreverse $args] {
      add_file $index [normalize $host $fname]
    }
    
    # Raise ourselves
    raise_window
  
  }
  
  ######################################################################
  # Raise ourself to the top.
  proc raise_window {} {
  
    variable widgets
    
    # If the notebook widget doesn't exist this will cause an error to occur.
    if {$widgets(nb_pw) ne ""} {
  
      wm withdraw  .
      wm deiconify .
      
    }
  
  }
  
  ######################################################################
  # Update the file located at the given notebook index.
  proc update_file {file_index} {

    variable widgets
    variable files
    variable files_index

    # Get the file information
    set file_info [lindex $files $file_index]
    
    # Get the current notebook.
    set nb [lindex [$widgets(nb_pw) panes] [lindex $file_info $files_index(pane)]]

    # Get the text widget at the given index
    set txt "[lindex [$nb tabs] [lindex $file_info $files_index(tab)]].tf.txt"

    # Get the current insertion index
    set insert_index [$txt index insert]

    # Delete the text widget
    $txt delete 1.0 end

    if {![catch "open [lindex $file_info $files_index(fname)] r" rc]} {
    
      # Read the file contents and insert them
      $txt insert end [string range [read $rc] 0 end-1]
      
      # Close the file
      close $rc
      
      # Change the tab text
      $nb tab [lindex $file_info $files_index(tab)] -text [file tail [lindex $file_info $files_index(fname)]]
            
      # Change the text to unmodified
      $txt edit modified false
        
      # Set the insertion mark to the first position
      $txt mark set insert $insert_index

      # Make the insertion mark visible
      $txt see $insert_index
      
    }

  }
  
  ######################################################################
  # Updates the currently displayed file.
  proc update_current {} {
    
    update_file [current_file]
    
  }

  ######################################################################
  # Returns the filename of the current tab.
  proc current_filename {} {
  
    variable files
    variable files_index
        
    return [lindex $files [current_file] $files_index(fname)]
  
  }
  
  ######################################################################
  # Saves the current tab filename.
  proc save_current {{save_as ""}} {
  
    variable widgets
    variable files
    variable files_index
    
    # Get the current notebook
    set nb [current_notebook]
        
    # Get the current file index
    set file_index [current_file]
    
    # If a save_as name is specified, change the filename
    if {$save_as ne ""} {
      lset files $file_index $files_index(fname) $save_as
    
    # If the current file doesn't have a filename, allow the user to set it
    } elseif {[lindex $files $file_index $files_index(fname)] eq ""} {
      if {[set sfile [tk_getSaveFile -defaultextension .tcl -parent . -title "Save As" -initialdir [pwd]]] eq ""} {
        return
      } else {
        lset files $file_index $files_index(fname) $sfile
      }
    }
    
    # Save the file contents
    if {[catch "open [lindex $files $file_index 0] w" rc]} {
      tk_messageBox -parent . -title "Error" -type ok -default ok -message "Unable to write file" -detail $rc
      return
    }
    
    # Write the file contents
    puts $rc [vim::get_cleaned_content [current_txt]]
    close $rc
 
    # If the file doesn't have a timestamp, it's a new file so add and highlight it in the sidebar
    if {[lindex $files $file_index $files_index(mtime)] eq ""} {
      
      # Add the file's directory to the sidebar
      add_directory [file dirname [file normalize [lindex $files $file_index $files_index(fname)]]]
    
      # Highlight the file in the sidebar
      highlight_filename [lindex $files $file_index $files_index(fname)] 1
      
    }

    # Update the timestamp
    file stat [lindex $files $file_index $files_index(fname)] stat
    lset files $file_index $files_index(mtime) $stat(mtime)
    
    # Change the tab text
    $nb tab current -text [file tail [lindex $files $file_index $files_index(fname)]]
    
    # Change the text to unmodified
    [current_txt] edit modified false

    # If there is a save command, run it now
    if {[lindex $files $file_index $files_index(save_cmd)] ne ""} {
      eval [lindex $files $file_index $files_index(save_cmd)]
    }
  
  }
  
  ######################################################################
  # Close the current tab.  If force is set to 1, closes regardless of
  # modified state of text widget.  If force is set to 0 and the text
  # widget is modified, the user will be questioned if they want to save
  # the contents of the file prior to closing the tab.
  proc close_current {{force 0}} {
  
    variable widgets
    variable pw_current
    
    # If the file needs to be saved, do it now
    if {[[current_txt] edit modified] && !$force} {
      if {[set answer [tk_messageBox -default yes -type yesno -message "Save file?" -title "Save request"]] eq "yes"} {
        save_current
      }
    }

    # Close the current tab
    close_tab $pw_current [[current_notebook] index current]
    
  }
  
  ######################################################################
  # Close the specified tab (do not ask the user about closing the tab).
  proc close_tab {pw_index nb_index} {

    variable widgets
    variable files
    variable files_index
    
    # Get the notebook
    set nb [lindex [$widgets(nb_pw) panes] $pw_index]
    
    # Get the indexed text widget 
    set tab_frame [lindex [$nb tabs] $nb_index]
    set txt       "$tab_frame.tf.txt"
    
    # Remove bindings
    indent::remove_bindings $txt
    
    # Add a new file if we have no more tabs and we are the only pane
    if {([llength [$nb tabs]] == 1) && ([llength [$widgets(nb_pw) panes]] == 1)} {
      add_new_file end
    }
    
    # Get the file index
    set index [lsearch -index $files_index(tab) [lsearch -inline -all -index $files_index(pane) $files $pw_index] $nb_index]
    
    # Unhighlight the file in the file browser
    highlight_filename [lindex $files $index $files_index(fname)] 0
    
    # Run the close event for this file
    plugins::handle_on_close $index
    
    # Delete the file from files
    set files [lreplace $files $index $index]
    
    # Remove the tab
    $nb forget $nb_index
    # destroy $tab_frame
    
    # Renumber any tabs after this tab
    foreach tab_index [lsearch -all -index $files_index(pane) $files $pw_index] {
      if {[set tab [lindex $files $tab_index $files_index(tab)]] > $nb_index} {
        lset files $tab_index $files_index(tab) [expr $tab - 1]
      }
    }
        
    # If we have no more tabs and there is another pane, remove this pane
    if {([llength [$nb tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] > 1)} {
      $widgets(nb_pw) forget $pw_index
      # destroy $nb
    }
    
  }

  ######################################################################
  # Close all tabs but the current tab.
  proc close_others {} {
  
    variable widgets
    variable pw_current
    
    set current_pw [lindex [$widgets(nb_pw) panes] $pw_current]

    foreach nb [lreverse [$widgets(nb_pw) panes]] {    
      foreach tab [lreverse [$nb tabs]] {
        if {($nb ne $current_pw) || ($tab ne [$nb select])} {
          $nb select $tab
          close_current
        }
      }
    }

  }
  
  ######################################################################
  # Close all of the tabs.
  proc close_all {} {
  
    variable widgets
        
    foreach nb [lreverse [$widgets(nb_pw) panes]] {
      foreach tab [lreverse [$nb tabs]] {
        $nb select $tab
        close_current
      }
    }
  
  }
  
  ######################################################################
  # Moves the current notebook tab to the other notebook pane.  If the
  # other notebook pane is not displayed, create it and display it.
  proc move_to_pane {} {
    
    variable widgets
    variable pw_current
    variable files
    variable files_index
    
    # Get the list of panes
    set panes [$widgets(nb_pw) panes]
    
    # If the other pane does not exist, add it
    if {[llength $panes] == 1} {
      add_notebook
      set panes [$widgets(nb_pw) panes]
    }
    
    # Get the title and text from the current text widget
    set txt      [current_txt]
    set file     [lindex $files [current_file]]
    set fname    [current_filename]
    set content  [$txt get 1.0 end-1c]
    set insert   [$txt index insert]
    set select   [$txt tag ranges sel]
    set modified [$txt edit modified]
    
    # Delete the current tab
    close_current 1

    # Get the name of the other pane
    set pw_current [expr $pw_current ^ 1]

    # Create a new tab
    insert_tab end [file tail $fname]
        
    # Update the file components to include position change information
    lset file $files_index(pane) $pw_current
    lset file $files_index(tab)  [[current_notebook] index current]
    lappend files $file
        
    # Add the text, insertion marker and selection
    set txt [current_txt]
    $txt insert end $content
    $txt mark set insert $insert
    
    # Perform an insertion adjust, if necessary
    vim::adjust_insert $txt.t
        
    # Add the selection (if it exists)
    if {[llength $select] > 0} {
      $txt tag add sel {*}select
    }
    
    # If the text widget was not in a modified state, force it to be so now
    if {!$modified} {
      $txt edit modified false
      [current_notebook] tab current -text [file tail $fname]
    }
    
    # Highlight the file in the sidebar
    highlight_filename $fname 1
    
  }
  
  ######################################################################
  # Performs an undo of the current tab.
  proc undo {} {
  
    variable widgets
    
    # Get the current textbox
    set txt [current_txt]
    
    # Perform the undo operation
    catch { $txt edit undo }
  
  }
  
  ######################################################################
  # This procedure performs an redo operation.
  proc redo {} {
  
    variable widgets
    
    # Get the current textbox
    set txt [current_txt]
    
    # Perform the redo operation
    catch { $txt edit redo }
    
  }
  
  ######################################################################
  # Cuts the currently selected text.
  proc cut {} {
    
    # Perform the cut
    [current_txt] cut
 
    # Add the clipboard contents to history
    cliphist::add_from_clipboard
  
  }
  
  ##############################################################################
  # This procedure performs a text selection copy operation.
  proc copy {} {
    
    # Perform the copy
    [current_txt] copy
  
    # Add the clipboard contents to history
    cliphist::add_from_clipboard
  
  }
  
  ##############################################################################
  # This procedure performs a text selection paste operation.
  proc paste {} {
  
    # Perform the paste
    [current_txt] paste
 
  }
  
  ######################################################################
  # This procedure performs a paste operation, formatting the pasted text
  # to match the code that it is being pasted into.
  proc paste_and_format {} {
  
    # Get the length of the clipboard text
    set cliplen [string length [clipboard get]]
 
    # Get the position of the insertion cursor
    set insertpos [[current_txt] index insert]
 
    # Perform the paste operation
    paste
  
    # Have the indent namespace format the clipboard contents
    indent::format_text [current_txt].t $insertpos "$insertpos+${cliplen}c"
    
  }
  
  ######################################################################
  # Formats either the selected text (if type is "selected") or the entire
  # file contents (if type is "all").
  proc format {type} {
    
    # Get the current text widget
    set txt [current_txt]
    
    if {$type eq "selected"} {
      foreach {endpos startpos} [lreverse [$txt tag ranges sel]] { 
        indent::format_text $txt.t $startpos $endpos
      }
    } else {
      indent::format_text $txt.t 1.0 end
    }
    
  }
  
  ######################################################################
  # Displays the search bar.
  proc search {{dir "next"}} {
    
    variable widgets
    
    # Get the current text frame
    set tab_frame [[current_notebook] select]
    
    # Update the search binding
    bind $tab_frame.sf.e <Return> "gui::search_start $dir"
 
    # Display the search bar and separator
    grid $tab_frame.sf
    grid $tab_frame.sep
    
    # Clear the search entry
    $tab_frame.sf.e delete 0 end
    
    # Place the focus on the search bar
    focus $tab_frame.sf.e
   
  }
  
  ######################################################################
  # Closes the search widget.
  proc close_search {} {
    
    variable widgets
    
    # Get the current text frame
    set tab_frame [[current_notebook] select]
    
    # Hide the search frame
    grid remove $tab_frame.sf
    grid remove $tab_frame.sep
    
    # Put the focus on the text widget
    focus $tab_frame.tf.txt.t
     
  }
  
  ######################################################################
  # Displays the search and replace bar.
  proc search_and_replace {} {

    variable widgets

    # Get the current text frame
    set tab_frame [[current_notebook] select]

    # Display the search bar and separator
    grid $tab_frame.rf
    grid $tab_frame.sep

    # Clear the search entry
    $tab_frame.rf.fe delete 0 end
    $tab_frame.rf.re delete 0 end

    # Place the focus on the find entry field
    focus $tab_frame.rf.fe
    
  }
  
  ######################################################################
  # Closes the search and replace bar.
  proc close_search_and_replace {} {

    variable widgets

    # Get the current text frame
    set tab_frame [[current_notebook] select]

    # Hide the search and replace bar
    grid remove $tab_frame.rf
    grid remove $tab_frame.sep

    # Puts the focus on the text widget
    focus $tab_frame.tf.txt.t

  }

  ######################################################################
  # Starts a text search
  proc search_start {{dir "next"}} {

    variable search_counts
    
    # If the user has specified a new search value, find all occurrences
    if {[set str [[current_search] get]] ne ""} {
    
      # Get the current text widget
      set txt [current_txt]

      # Delete the search tag
      $txt tag delete search

      # Search the entire text
      set i 0
      foreach match [$txt search -count gui::search_counts -all -- $str 1.0] {
        $txt tag add search $match "$match+[lindex $search_counts $i]c"
        incr i
      }

      # Change the color of the items that match the search criteria
      $txt tag configure search -background yellow -foreground black

      # Make the search tag lower in priority than the selection tag
      $txt tag lower search sel

    }
 
    # Select the search term
    if {$dir eq "next"} {
      search_next 0
    } else {
      search_prev 0
    }

  }
 
  ######################################################################
  # Searches for the next occurrence of the search item.
  proc search_next {app} {
    
    variable widgets
    variable search_counts
    variable search_index
 
    # Get the current text widget
    set txt [current_txt]
    
    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }
    
    # Search the text widget from the current insertion cursor forward.
    lassign [$txt tag nextrange search "insert+1c"] startpos endpos

    # We need to wrap on the search item
    if {$startpos eq ""} {
      lassign [$txt tag nextrange search 1.0] startpos endpos
    }

    # Select the next match
    if {$startpos ne ""} {
      $txt tag add sel $startpos $endpos
      $txt mark set insert $startpos
      $txt see insert
    }
    
    # Closes the search interface
    close_search
    
  }
  
  ######################################################################
  # Searches for the previous occurrence of the search item.
  proc search_prev {app} {
    
    variable widgets
    variable search_counts
    variable search_text
    
    # Get the current text widget
    set txt [current_txt]
    
    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }
   
    # Search the text widget from the current insertion cursor forward.
    lassign [$txt tag prevrange search insert] startpos endpos

    # We need to wrap on the search item
    if {$startpos eq ""} {
      lassign [$txt tag prevrange search end] startpos endpos
    }

    # Select the next match
    if {$startpos ne ""} {
      $txt tag add sel $startpos $endpos
      $txt mark set insert $startpos
      $txt see insert
    }

    # Close the search interface
    close_search
    
  }
  
  ######################################################################
  # Searches for all of the occurrences and selects them all.
  proc search_all {} {
    
    variable widgets
    variable search_counts
    variable search_text
    
    # Get the current text widget
    set txt [current_txt]
    
    # Clear the selection
    $txt tag remove sel 1.0 end
    
    # Add all matching search items to the selection
    $txt tag add sel {*}[$txt tag ranges search]
 
    # Make the first line viewable
    catch {
      set firstpos [lindex [$txt tag ranges search] 0]
      $txt mark set insert $firstpos
      $txt see $firstpos
    }
    
    # Close the search interface
    close_search
    
  }

  ######################################################################
  # Performs a search and replace operation based on the GUI element
  # settings.
  proc do_search_and_replace {} {

    variable widgets
    variable sar_global

    # Get the current tab frame
    set tab_frame [[current_notebook] select]

    # Perform the search and replace
    do_raw_search_and_replace 1.0 end [$tab_frame.rf.fe get] [$tab_frame.rf.re get] $sar_global

    # Close the search and replace bar
    close_search_and_replace

  }

  ######################################################################
  # Performs a search and replace given the expression, 
  proc do_raw_search_and_replace {sline eline search replace glob} {

    # Get the current text widget
    set txt [current_txt]

    # Clear the selection
    $txt tag remove sel 1.0 end

    # Perform the string substitutions
    if {!$glob} {
      set sline [$txt index "insert linestart"]
      set eline [$txt index "insert lineend"]
    }

    # Replace the text and re-highlight the changes
    $txt replace $sline $eline [regsub -all $search [$txt get $sline "$eline-1c"] $replace]
    $txt highlight $sline $eline

    # Make sure that the insertion cursor is valid
    vim::adjust_insert $txt

  }
  
  ######################################################################
  # Returns the list of stored filenames.
  proc get_actual_filenames {} {
  
    variable files
    variable files_index
    
    set actual_filenames [list]
    
    foreach finfo $files {
      if {[set fname [lindex $finfo $files_index(fname)]] ne ""} {
        lappend actual_filenames $fname
      }
    }
    
    return $actual_filenames
    
  }
  
  ######################################################################
  # Sets the current information message to the given string.
  proc set_info_message {msg} {
  
    variable widgets
    
    $widgets(info_label) configure -text $msg
    
  }
  
  ######################################################################
  # Gets user input from the interface in a generic way.
  proc user_response_get {msg pvar} {
    
    variable widgets
    
    # Create a reference to the storage variable
    upvar $pvar var
    
    # Initialize the widget
    $widgets(ursp_label) configure -text $msg
    $widgets(ursp_entry) delete 0 end
    
    # Display the user input widget
    grid $widgets(ursp)
    
    # Get current focus and grab
    set old_focus [focus]
    set old_grab  [grab current $widgets(ursp)]
    if {$old_grab ne ""} {
      set grab_status [grab status $old_grab]
    }
    
    # Set focus to the ursp_entry widget
    focus $widgets(ursp_entry)
    
    # Wait for the widget to be closed
    vwait gui::user_exit_status
    
    # Reset the original focus and grab
    catch { focus $old_focus }
    if {$old_grab ne ""} {
      if {$grab_status ne "global"} {
        grab $old_grab
      } else {
        grab -global $old_grab
      }
    }
    
    # Hide the user input widget
    grid remove $widgets(ursp)
    
    # Get the user response value
    set var [$widgets(ursp_entry) get]
    
    return $gui::user_exit_status
    
  }
  
  ######################################################################
  # Returns file information for the given file index and attribute.
  # This is called by the get_file_info API command.
  proc get_file_info {index attr} {
    
    variable files
    variable files_index
    
    # Perform error detections
    if {($index < 0) || ($index >= [llength $files])} {
      return -code error "File index is out of range"
    }
    if {![info exists files_index($attr)]} {
      return -code error "File attribute ($attr) does not exist"
    }
    
    return [lindex $files $index $files_index($attr)]
    
  }

  ########################
  #  PRIVATE PROCEDURES  #
  ########################
 
  ######################################################################
  # Add notebook widget.
  proc add_notebook {} {
    
    variable widgets
    variable curr_notebook
    
    # Create editor notebook
    $widgets(nb_pw) add [set nb [ttk::notebook $widgets(nb_pw).nb[incr curr_notebook]]] -weight 1

    bind $nb <<NotebookTabChanged>> { gui::set_current_tab_from_nb %W }
    bind $nb <ButtonPress-1>        { gui::tab_move_start %W %x %y }
    bind $nb <B1-Motion>            { gui::tab_move_motion %W %x %y }
    bind $nb <ButtonRelease-1>      { gui::tab_move_end %W %x %y }
    bind $nb <Button-3> {
      if {[%W index @%x,%y] eq [%W index current]} {
        if {[llength [%W tabs]] > 1} {
          $gui::widgets(menu) entryconfigure 1 -state normal
        } else {
          $gui::widgets(menu) entryconfigure 1 -state disabled
        }
        if {([llength [%W tabs]] > 1) || ([llength [$gui::widgets(nb_pw) panes]] > 1)} {
          $gui::widgets(menu) entryconfigure 4 -state normal
        } else {
          $gui::widgets(menu) entryconfigure 4 -state disabled
        }
        tk_popup $gui::widgets(menu) %X %Y
      }
    }
    
  }
   
  ######################################################################
  # Inserts a new tab into the editor tab notebook.
  proc insert_tab {index title} {
  
    variable widgets
    variable curr_id
    variable language
    variable pw_current
        
    # Get the unique tab ID
    set id [incr curr_id]
    
    # Get the current notebook
    set nb [current_notebook]
    
    # Create the tab frame
    set tab_frame [ttk::frame $nb.$id]
    
    # Create the editor frame
    ttk::frame $tab_frame.tf
    ctext $tab_frame.tf.txt -wrap none -undo 1 -autoseparators 1 -insertofftime 0 \
      -highlightcolor yellow \
      -xscrollcommand "utils::set_scrollbar $tab_frame.tf.hb" \
      -yscrollcommand "utils::set_scrollbar $tab_frame.tf.vb"
    ttk::scrollbar $tab_frame.tf.vb -orient vertical   -command "$tab_frame.tf.txt yview"
    ttk::scrollbar $tab_frame.tf.hb -orient horizontal -command "$tab_frame.tf.txt xview"
    
    bind Ctext               <<Modified>>    "gui::text_changed %W"
    bind $tab_frame.tf.txt.t <FocusIn>       "gui::set_current_tab_from_txt %W"
    bind $tab_frame.tf.txt   <<Selection>>   "gui::selection_changed %W"
    bind $tab_frame.tf.txt   <ButtonPress-1> "after idle [list gui::update_position $tab_frame]"
    bind $tab_frame.tf.txt   <B1-Motion>     "gui::update_position $tab_frame"
    bind $tab_frame.tf.txt   <KeyRelease>    "gui::update_position $tab_frame"
    bind Text                <<Cut>>         ""
    bind Text                <<Copy>>        ""
    bind Text                <<Paste>>       ""
    bind Text                <Control-d>     ""
    bind Text                <Control-i>     ""
    
    # Move the all bindtag ahead of the Text bindtag
    set text_index [lsearch [bindtags $tab_frame.tf.txt.t] Text]
    set all_index  [lsearch [bindtags $tab_frame.tf.txt.t] all]
    bindtags $tab_frame.tf.txt.t [lreplace [bindtags $tab_frame.tf.txt.t] $all_index $all_index]
    bindtags $tab_frame.tf.txt.t [linsert  [bindtags $tab_frame.tf.txt.t] $text_index all]
    
    grid rowconfigure    $tab_frame.tf 0 -weight 1
    grid columnconfigure $tab_frame.tf 0 -weight 1
    grid $tab_frame.tf.txt -row 0 -column 0 -sticky news
    grid $tab_frame.tf.vb  -row 0 -column 1 -sticky ns
    grid $tab_frame.tf.hb  -row 1 -column 0 -sticky ew
    
    # Create the Vim command bar
    vim::bind_command_entry $tab_frame.tf.txt \
      [entry $tab_frame.ve -background black -foreground white -insertbackground white \
        -font [$tab_frame.tf.txt cget -font]]
    
    # Create the search bar
    ttk::frame $tab_frame.sf
    ttk::label $tab_frame.sf.l1 -text "Find:"
    ttk::entry $tab_frame.sf.e
    
    pack $tab_frame.sf.l1 -side left -padx 2 -pady 2
    pack $tab_frame.sf.e  -side left -padx 2 -pady 2 -fill x
    
    bind $tab_frame.sf.e <Escape> "gui::close_search"
 
    # Create the search/replace bar
    ttk::frame       $tab_frame.rf
    ttk::label       $tab_frame.rf.fl   -text "Find:"
    ttk::entry       $tab_frame.rf.fe
    ttk::label       $tab_frame.rf.rl   -text "Replace:"
    ttk::entry       $tab_frame.rf.re
    ttk::checkbutton $tab_frame.rf.glob -text "Global" -variable gui::sar_global
 
    pack $tab_frame.rf.fl   -side left -padx 2 -pady 2
    pack $tab_frame.rf.fe   -side left -padx 2 -pady 2
    pack $tab_frame.rf.rl   -side left -padx 2 -pady 2
    pack $tab_frame.rf.re   -side left -padx 2 -pady 2
    pack $tab_frame.rf.glob -side left -padx 2 -pady 2
 
    bind $tab_frame.rf.fe   <Return> "gui::do_search_and_replace"
    bind $tab_frame.rf.re   <Return> "gui::do_search_and_replace"
    bind $tab_frame.rf.glob <Return> "gui::do_search_and_replace"
    bind $tab_frame.rf.fe   <Escape> "gui::close_search_and_replace"
    bind $tab_frame.rf.re   <Escape> "gui::close_search_and_replace"
    bind $tab_frame.rf.glob <Escape> "gui::close_search_and_replace"
    
    # Create separator between search and information bar
    ttk::separator $tab_frame.sep -orient horizontal
    
    grid rowconfigure    $tab_frame 0 -weight 1
    grid columnconfigure $tab_frame 0 -weight 1
    grid $tab_frame.tf  -row 0 -column 0 -sticky news
    grid $tab_frame.ve  -row 1 -column 0 -sticky ew
    grid $tab_frame.sf  -row 2 -column 0 -sticky ew
    grid $tab_frame.rf  -row 3 -column 0 -sticky ew
    grid $tab_frame.sep -row 4 -column 0 -sticky ew
    
    # Hide the vim command entry, search bar, search/replace bar and search separator
    grid remove $tab_frame.ve
    grid remove $tab_frame.sf
    grid remove $tab_frame.rf
    grid remove $tab_frame.sep
    
    # Get the adjusted index
    set adjusted_index [$nb index $index]
    
    # Add the new tab to the notebook
    $nb insert $index $tab_frame -text $title
    
    # Add the text bindings
    indent::add_bindings      $tab_frame.tf.txt
    multicursor::add_bindings $tab_frame.tf.txt
    snippets::add_bindings    $tab_frame.tf.txt
    vim::set_vim_mode         $tab_frame.tf.txt
        
    # Apply the appropriate syntax highlighting for the given extension
    syntax::initialize_language $tab_frame.tf.txt $title

    # Make the new tab the current tab
    set_current_tab $pw_current $adjusted_index
    
    # Set the current language
    syntax::set_current_language

    # Give the text widget the focus
    focus $tab_frame.tf.txt.t
    
    return $tab_frame
    
  }
 
  ######################################################################
  # Handles a change to the current text widget.
  proc text_changed {txt} {
  
    variable widgets
        
    if {[$txt edit modified]} {
      
      # Get the tab path from the text path
      set tab [winfo parent [winfo parent $txt]]
      
      # Get the current notebook
      set nb [current_notebook]
      
      # Change the look of the tab
      if {[string index [set name [$nb tab $tab -text]] 0] ne "*"} {
        $nb tab $tab -text "* $name"
      }
    
    }
  
  }
  
  ######################################################################
  # Handles a change to the current text widget selection.
  proc selection_changed {txt} {
    
    # Get the first range of selected text
    if {[set range [$txt tag nextrange sel 1.0]] ne ""} {
      
      # Get the current search entry field
      set sentry [current_search]
      
      # Set the search frame
      $sentry delete 0 end
      $sentry insert end [$txt get {*}$range]
      
    }
    
  }
 
  ######################################################################
  # Make the specified pane/tab the current tab.
  proc set_current_tab {pane tab} {

    variable widgets
    variable pw_current
    
    # Set the current pane
    set pw_current $pane
    
    # Set the current tab
    [current_notebook] select $tab
    
    # Set the line and row information
    lassign [split [[current_txt] index insert] .] row col
    $widgets(info_label) configure -text "Line: $row, Column: $col"

    # Finally, set the focus to the text widget
    focus [current_txt].t       

  }
  
  ######################################################################
  # Sets the current tab information based on the given notebook.
  proc set_current_tab_from_nb {nb} {
    
    variable widgets
    
    # Get the pane index
    if {[set pane [lsearch [$widgets(nb_pw) panes] $nb]] == -1} {
      return
    }
    
    # Get the tab index
    set tab [$nb index current]
    
    # Set the current tab
    set_current_tab $pane $tab
    
  }
  
  ######################################################################
  # Sets the current tab information based on the given text widget.
  proc set_current_tab_from_txt {txt} {
    
    set tab [winfo parent [winfo parent [winfo parent $txt]]]
        
    # Get the tab from the text widget's notebook
    set_current_tab_from_nb [winfo parent $tab]
    
    # Handle any on_focusin events
    plugins::handle_on_focusin $tab
    
  }
  
  ######################################################################
  # Returns the pathname to the current notebook.
  proc current_notebook {} {
  
    variable widgets
    variable pw_current
    
    return [lindex [$widgets(nb_pw) panes] $pw_current]
  
  }

  ######################################################################
  # Returns the current text widget pathname.
  proc current_txt {} {
  
    variable widgets
    variable pw_current
    
    return "[[current_notebook] select].tf.txt"
    
  }
  
  ######################################################################
  # Returns the current search entry pathname.
  proc current_search {} {
    
    variable widgets
    variable pw_current
    
    return "[[current_notebook] select].sf.e"
    
  }
  
  ######################################################################
  # Returns the index of the file list that pertains to the given file.
  proc get_file_index {pane tab} {

    variable files
    variable files_index

    # Look for the file index
    set index 0
    foreach file_info $files {
      if {([lindex $file_info $files_index(pane)] eq $pane) && \
          ([lindex $file_info $files_index(tab)]  eq $tab)} {
        return $index
      }
      incr index
    }

    # Throw an exception if we couldn't find the current file
    # (this is considered an unhittable case)
    return -code error "Unable to find current file (pane: $pane, tab: $tab)"
    
  }

  ######################################################################
  # Gets the current index into the file list based on the current pane
  # and notebook tab.
  proc current_file {} {
  
    variable pw_current

    # Returns the file index
    return [get_file_index $pw_current [[current_notebook] index current]]
    
  }
  
  ######################################################################
  # Updates the current position information in the information bar based
  # on the current location of the insertion cursor.
  proc update_position {w} {
  
    variable widgets
    
    # Get the current position of the insertion cursor
    lassign [split [$w.tf.txt index insert] .] line column
    
    # Update the information widgets
    $widgets(info_label) configure -text "Line: $line, Column: [expr $column + 1]"
  
  }
  
  ######################################################################
  # Returns the list of procs in the current text widget.  Uses the _procs
  # highlighting to tag to quickly find procs in the widget.
  proc get_symbol_list {} {
    
    variable lengths
    
    # Get current text widget
    set txt [current_txt]
    
    set proclist [list]
    set lengths  [list]
    foreach {startpos endpos} [$txt tag ranges _symbols] {
      if {[set pos [$txt search -regexp -count gui::lengths -- {\S+} $endpos]] eq ""} {
        break
      }
      lappend proclist [$txt get $pos "$pos+${gui::lengths}c"] $pos
    }
    
    return $proclist
    
  }
  
  ######################################################################
  # Jump to the given position.
  proc jump_to {pos} {
    
    # Get the current text widget
    set txt [current_txt]
    
    # Set the current insertion marker and make it viewable.
    $txt mark set insert $pos
    $txt see $pos
    
  }
  
  ######################################################################
  # Finds the matching character for the one at the current insertion
  # marker.
  proc show_match_pair {} {
  
    # Get the current widget
    set txt [current_txt]
    
    # If the current character is a matchable character, change the
    # insertion cursor to the matching character.
    switch -- [$txt get insert] {
      "\{" { set index [find_match_brace $txt "\\\}" "\\\{" "\\" -forwards] }
      "\}" { set index [find_match_brace $txt "\\\{" "\\\}" "\\" -backwards] }
      "\[" { set index [find_match_brace $txt "\\\]" "\\\[" "\\" -forwards] }
      "\]" { set index [find_match_brace $txt "\\\[" "\\\]" "\\" -backwards] }
      "\(" { set index [find_match_brace $txt "\\\)" "\\\(" ""   -forwards] }
      "\)" { set index [find_match_brace $txt "\\\(" "\\\)" ""   -backwards] }
      "\"" { set index [find_match_quote $txt] }
    }
      
    # Change the insertion cursor to the matching character
    if {$index != -1} {
      $txt mark set insert $index
      $txt see insert
    }
      
  }
  
  ######################################################################
  # Finds the matching bracket type and returns it's index if found;
  # otherwise, returns -1.
  proc find_match_brace {txt str1 str2 escape dir} {
  
    set prev_char [$txt get "insert-2c"]
    
    if {[string equal $prev_char $escape]} {
      return -1
    }
    
    set search_re  "[set str1]|[set str2]"
    set count      1
    set pos        [$txt index [expr {($dir eq "-forwards") ? "insert+1c" : "insert"}]]
    set last_found ""
    
    while {1} {
      
      set found [$txt search $dir -regexp $search_re $pos]
      
      if {($found eq "") || \
          (($dir eq "-forwards")  && [$txt compare $found < $pos]) || \
          (($dir eq "-backwards") && [$txt compare $found > $pos]) || \
          (($last_found ne "") && [$txt compare $found == $last_found])} {
        return -1
      }
      
      set last_found $found
      set char       [$txt get $found]
      set prev_char  [$txt get "$found-1c"]
      if {$dir eq "-forwards"} {
        set pos "$found+1c"
      } else {
        set pos "$found"
      }
      
      if {[string equal $prev_char $escape]} {
        continue
      } elseif {[string equal $char [subst $str2]]} {
        incr count
      } elseif {[string equal $char [subst $str1]]} {
        incr count -1
        if {$count == 0} {
          return $found
        }
      }
      
    }    
    
  }
 
  ######################################################################
  # Returns the index of the matching quotation mark; otherwise, if one
  # is not found, returns -1.
  proc find_match_quote {txt} {
    
    set end_quote  [$txt index insert]
    set start      [$txt index "insert-1c"]
    set last_found ""
  
    if {[$txt get "$start-1c"] eq "\\"} {
      return
    }
    
    # Figure out if we need to search forwards or backwards
    if {[lsearch [$txt tag names $start] _strings] == -1} {
      set dir   "-forwards"
      set start [$txt index "insert+1c"]
    } else {
      set dir   "-backwards"
    }
    
    while {1} {
      
      set start_quote [$txt search $dir \" $start]
      
      if {($start_quote eq "") || \
          (($dir eq "-backwards") && [$txt compare $start_quote > $start]) || \
          (($dir eq "-forwards")  && [$txt compare $start_quote < $start]) || \
          (($last_found ne "") && [$txt compare $last_found == $start_quote])} {
        return -1
      }
      
      set last_found $start_quote
      set start      [$txt index "$start_quote-1c"]
      set prev_char  [$txt get $start]
      
      if {$prev_char eq "\\"} {
        continue
      }
      
      return $last_found
      
    }
  
  }
  
}
 

