######################################################################
# Name:    sidebar.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/03/2013
# Brief:   Handles the UI and related functionality associated with the
#          sidebar.
######################################################################

namespace eval sidebar {

  variable last_opened {}

  array set widgets {}
  array set images  {}

  ######################################################################
  # Returns a list containing information that the sidebar will save to the
  # session file.
  proc save_session {} {

    variable widgets
    variable last_opened

    set dirs [list]
    foreach child [$widgets(tl) childkeys root] {
      lappend dirs [list name [$widgets(tl) cellcget $child,name -text]]
    }

    return [list directories $dirs last_opened $last_opened]

  }

  ######################################################################
  # Loads the given information into the sidebar from the session file.
  proc load_session {data} {

    variable widgets
    variable last_opened

    # Get the session information
    array set content {
      directories {}
      last_opened {}
    }
    array set content $data

    # Add the last_opened directories to the saved list
    set last_opened $content(last_opened)

    # Add the session directories (if the sidebar is currently empty)
    if {[llength [$widgets(tl) childkeys root]] == 0} {
      foreach dir_list $content(directories) {
        array set dir $dir_list
        add_directory $dir(name)
      }
    }

  }

  ######################################################################
  # Adds the given directory to the list of most recently opened directories.
  proc add_to_recently_opened {sdir} {

    variable last_opened

    if {[set index [lsearch $last_opened $sdir]] != -1} {
      set last_opened [lreplace $last_opened $index $index]
    }

    set last_opened [lrange [list $sdir {*}$last_opened] 0 20]

  }

  ######################################################################
  # Returns the list of last opened directories.
  proc get_last_opened {} {

    variable last_opened

    return $last_opened

  }

  ######################################################################
  # Clears the last opened directory list.
  proc clear_last_opened {} {

    variable last_opened

    set last_opened [list]

  }

  ######################################################################
  # Creates the sidebar UI and initializes it.
  proc create {w} {

    variable widgets
    variable images

    # Create needed images
    set images(sopen) [image create bitmap -file [file join $::tke_dir lib images sopen.bmp] \
                                           -maskfile [file join $::tke_dir lib images sopen.bmp] \
                                           -foreground "gold"]

    set fg [utils::get_default_foreground]
    set bg [utils::get_default_background]

    # Create the top-level frame
    set widgets(frame) [ttk::frame $w]

    # Add the file tree elements
    set widgets(tl) \
      [tablelist::tablelist $w.tl -columns {0 {} 0 {}} -showlabels 0 -exportselection 0 \
        -treecolumn 0 -treestyle aqua -forceeditendcommand 1 -expandcommand sidebar::expand_directory \
        -relief flat -highlightthickness 1 -highlightbackground $bg -highlightcolor $bg \
        -foreground $fg -background $bg -selectmode extended \
        -selectforeground $bg -selectbackground $fg \
        -selectborderwidth 0 -activestyle none -width 30 \
        -tooltipaddcommand "sidebar::show_tooltip" \
        -tooltipdelcommand "sidebar::hide_tooltip" \
        -yscrollcommand    "utils::set_yscrollbar $w.vb"]
    set widgets(sb) [ttk::scrollbar $w.vb -orient vertical -command "$widgets(tl) yview"]

    $widgets(tl) columnconfigure 0 -name name   -editable 0 -formatcommand "sidebar::format_name"
    $widgets(tl) columnconfigure 1 -name ocount -editable 0 -hide 1

    bind $widgets(tl)           <<TablelistSelect>>     "sidebar::handle_selection"
    bind [$widgets(tl) bodytag] <Button-$::right_click> "sidebar::handle_right_click %W %x %y"
    bind [$widgets(tl) bodytag] <Double-Button-1>       "sidebar::handle_double_click %W %x %y"
    bind [$widgets(tl) bodytag] <Return>                "sidebar::handle_return %W"
    bind [$widgets(tl) bodytag] <FocusIn>               "sidebar::unhide_scrollbar"
    bind [$widgets(tl) bodytag] <FocusOut>              "sidebar::hide_scrollbar"
    bind $widgets(frame)        <Enter>                 "sidebar::unhide_scrollbar"
    bind $widgets(frame)        <Leave>                 "sidebar::hide_scrollbar"

    grid rowconfigure    $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid $w.tl -row 0 -column 0 -sticky news
    grid $w.vb -row 0 -column 1 -sticky ns

    # On application start, hide the scrollbar
    hide_scrollbar

    # Create directory popup
    set widgets(menu) [menu $w.popupMenu -tearoff 0 -postcommand "sidebar::menu_post"]

    # Make ourselves a drop target (if Tkdnd is available)
    catch {

      tkdnd::drop_target register $widgets(tl) DND_Files

      bind $widgets(tl) <<DropEnter>>    "sidebar::handle_drop_enter_or_pos %W %X %Y %a %b"
      bind $widgets(tl) <<DropPosition>> "sidebar::handle_drop_enter_or_pos %W %X %Y %a %b"
      bind $widgets(tl) <<DropLeave>>    "sidebar::handle_drop_leave %W"
      bind $widgets(tl) <<Drop>>         "sidebar::handle_drop %W %A %D"

    }

    # Handle traces
    trace variable preferences::prefs(Sidebar/IgnoreFilePatterns) w sidebar::handle_ignore_files
    trace variable preferences::prefs(Sidebar/IgnoreExecutables)  w sidebar::handle_ignore_files

    return $w

  }
  
  ######################################################################
  # Clears the sidebar of all content.  This is primarily called when
  # we are switching sessions.
  proc clear {} {
    
    variable widgets
    
    $widgets(tl) delete 0 end
    
  }

  ######################################################################
  # Handles a drag-and-drop enter/position event.  Draws UI to show that
  # the file drop request would be excepted or rejected.
  proc handle_drop_enter_or_pos {tbl rootx rooty actions buttons} {

    $tbl configure -highlightbackground green

    return "link"

  }

  ######################################################################
  # Handles a drop leave event.
  proc handle_drop_leave {tbl} {

    $tbl configure -highlightbackground [utils::get_default_background]

  }

  ######################################################################
  # Handles a drop event.  Adds the given files/directories to the sidebar.
  proc handle_drop {tbl action files} {

    foreach fname $files {
      if {[file isdirectory $fname]} {
        add_directory $fname
      } else {
        gui::add_file end $fname
      }
    }

    handle_drop_leave $tbl

    return "link"

  }

  ######################################################################
  # Hides the given scrollbar.
  proc hide_scrollbar {} {

    variable widgets

    # Set the yscrollcommand to the normal kind
    $widgets(tl) configure -yscrollcommand "$widgets(sb) set"

    # Hide the sidebar
    grid remove $widgets(sb)

  }

  ######################################################################
  # Unhides the given scrollbar (if it needs to be displayed).
  proc unhide_scrollbar {} {

    variable widgets

    # Set the yscrollcommand to the auto-hide version
    $widgets(tl) configure -yscrollcommand "utils::set_yscrollbar $widgets(sb)"

    # Run the set_yscrollbar command
    if {[llength [set sb_get [$widgets(sb) get]]] == 2} {
      utils::set_yscrollbar $widgets(sb) {*}$sb_get
    }

  }

  ######################################################################
  # Returns "root", "dir" or "file" to indicate what type of item is
  # specified at the given row in the sidebar table.
  proc row_type {row} {

    variable widgets

    if {[$widgets(tl) parentkey $row] eq "root"} {
      return "root"
    } elseif {[file isdirectory [$widgets(tl) cellcget $row,name -text]]} {
      return "dir"
    } else {
      return "file"
    }

  }

  ######################################################################
  # Handles the contents of the sidebar popup menu prior to it being posted.
  proc menu_post {} {

    variable widgets

    # Get the current index
    switch [row_type anchor] {
      "root" { setup_root_menu [$widgets(tl) curselection] }
      "dir"  { setup_dir_menu  [$widgets(tl) curselection] }
      "file" { setup_file_menu [$widgets(tl) curselection] }
    }

  }

  ######################################################################
  # Sets up the popup menu to be suitable for the given directory.
  proc setup_dir_menu {rows} {

    variable widgets

    set one_state [expr {([llength $rows] == 1) ? "normal" : "disabled"}]
    set first_row [lindex $rows 0]

    # Clear the menu
    $widgets(menu) delete 0 end

    $widgets(menu) add command -label [msgcat::mc "New File"]      -command [list sidebar::add_file_to_folder $first_row]   -state $one_state
    $widgets(menu) add command -label [msgcat::mc "New Directory"] -command [list sidebar::add_folder_to_folder $first_row] -state $one_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Open Directory Files"]  -command [list sidebar::open_folder_files $rows]
    $widgets(menu) add command -label [msgcat::mc "Close Directory Files"] -command [list sidebar::close_folder_files $rows]
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Copy Pathname"] -command [list sidebar::copy_pathname $first_row] -state $one_state
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Rename"] -command [list sidebar::rename_folder $first_row] -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Delete"] -command [list sidebar::delete_folder $first_row] -state $one_state
    $widgets(menu) add separator

    if {[favorites::is_favorite [$widgets(tl) cellcget $first_row,name -text]]} {
      $widgets(menu) add command -label [msgcat::mc "Unfavorite"] -command [list sidebar::unfavorite $first_row] -state $one_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Favorite"] -command [list sidebar::favorite $first_row] -state $one_state
    }
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Remove from Sidebar"]        -command [list sidebar::remove_folder $rows]
    $widgets(menu) add command -label [msgcat::mc "Remove Parent from Sidebar"] -command [list sidebar::remove_parent_folder $first_row] -state $one_state
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Make Current Working Directory"] -command [list sidebar::set_current_working_directory $first_row] -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Refresh Directory Files"]        -command [list sidebar::refresh_directory_files $rows]

    # Add plugins to sidebar directory popup
    plugins::handle_dir_popup $widgets(menu)

  }

  ######################################################################
  # Sets up the given menu for a root directory item.
  proc setup_root_menu {rows} {

    variable widgets

    set one_state [expr {([llength $rows] == 1) ? "normal" : "disabled"}]
    set first_row [lindex $rows 0]

    # Clear the menu
    $widgets(menu) delete 0 end

    $widgets(menu) add command -label [msgcat::mc "New File"]      -command [list sidebar::add_file_to_folder $first_row]   -state $one_state
    $widgets(menu) add command -label [msgcat::mc "New Directory"] -command [list sidebar::add_folder_to_folder $first_row] -state $one_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Open Directory Files"]  -command [list sidebar::open_folder_files $rows]
    $widgets(menu) add command -label [msgcat::mc "Close Directory Files"] -command [list sidebar::close_folder_files $rows]
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Copy Pathname"] -command [list sidebar::copy_pathname $first_row] -state $one_state
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Rename"] -command [list sidebar::rename_folder $first_row] -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Delete"] -command [list sidebar::delete_folder $first_row] -state $one_state
    $widgets(menu) add separator

    if {[favorites::is_favorite [$widgets(tl) cellcget $first_row,name -text]]} {
      $widgets(menu) add command -label [msgcat::mc "Unfavorite"] -command [list sidebar::unfavorite $first_row] -state $one_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Favorite"] -command [list sidebar::favorite $first_row] -state $one_state
    }
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Remove from Sidebar"]  -command [list sidebar::remove_folder $rows]
    $widgets(menu) add command -label [msgcat::mc "Add Parent Directory"] -command [list sidebar::add_parent_directory $first_row] -state $one_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Make Current Working Directory"] -command [list sidebar::set_current_working_directory $first_row] -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Refresh Directory Files"]        -command [list sidebar::refresh_directory_files $rows]

    # Add plugins to sidebar root popup
    plugins::handle_root_popup $widgets(menu)

  }

  ######################################################################
  # Sets up the file popup menu for the currently selected rows.
  proc setup_file_menu {rows} {

    variable widgets

    set one_state [expr {([llength $rows] == 1) ? "normal" : "disabled"}]
    set first_row [lindex $rows 0]

    # Delete the menu contents
    $widgets(menu) delete 0 end

    # Create file popup
    $widgets(menu) add command -label [msgcat::mc "Open"] -command [list sidebar::open_file $rows]
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Close"] -command [list sidebar::close_file $rows]
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Show Difference"] -command [list sidebar::show_file_diff $first_row] -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Copy Pathname"]   -command [list sidebar::copy_pathname $first_row]  -state $one_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Rename"]    -command [list sidebar::rename_file $first_row]    -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Duplicate"] -command [list sidebar::duplicate_file $first_row] -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Delete"]    -command [list sidebar::delete_file $first_row]    -state $one_state
    $widgets(menu) add separator

    if {[favorites::is_favorite [$widgets(tl) cellcget $first_row,name -text]]} {
      $widgets(menu) add command -label [msgcat::mc "Unfavorite"] -command [list sidebar::unfavorite $first_row] -state $one_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Favorite"] -command [list sidebar::favorite $first_row] -state $one_state
    }

    # Add plugins to sidebar file popup
    plugins::handle_file_popup $widgets(menu)

  }

  ######################################################################
  # Returns the sidebar index of the given filename.  If the filename
  # was not found in the sidebar, return a value of -1.
  proc get_index {fname} {

    variable widgets

    return [$widgets(tl) searchcolumn name $fname -descend -exact]

  }

  ######################################################################
  # Returns the indices of the current selections.  If nothing is currently
  # selected, returns an empty string.
  proc get_selected_indices {} {

    variable widgets

    # Get the current selection
    return [$widgets(tl) curselection]

  }

  ######################################################################
  # Returns the information specified by attr for the file at the given
  # sidebar index.
  proc get_info {index attr} {

    variable widgets

    switch $attr {
      fname      { return [$widgets(tl) cellcget $index,name -text] }
      file_index { return [gui::get_file_index [$widgets(tl) cellcget $index,name -text]]}
      default    {
        return -code error "Illegal sidebar attribute specified ($attr)"
      }
    }

  }

  ######################################################################
  # Highlights, dehighlights or must modifies the root count for the given
  # filename in the file system sidebar.
  #   highlight_mode:
  #     - 0: dehighlight
  #     - 1: highlight
  #     - 2: don't change highlight but decrement root count
  #     - 3: don't change highlight but increment root count
  proc highlight_filename {fname highlight_mode} {

    variable widgets
    variable images

    # Find the main directory containing the file
    if {[set row [$widgets(tl) searchcolumn name $fname -descend -exact]] != -1} {
      set highlighted [expr {[$widgets(tl) cellcget $row,name -image] eq $images(sopen)}]
      switch $highlight_mode {
        0 { $widgets(tl) cellconfigure $row,name -image "" }
        1 { $widgets(tl) cellconfigure $row,name -image $images(sopen) }
      }
      if {[expr ($highlight_mode % 2) == 0]} {
        if {$highlighted || ($highlight_mode == 2)} {
          update_root_count $row -1
        }
      } else {
        if {!$highlighted || ($highlight_mode == 3)} {
          update_root_count $row 1
        }
      }
    }

  }

  ######################################################################
  # Adds the given directory which displays within the file browser.
  proc add_directory {dir {parent root}} {

    variable widgets

    # Get some needed information
    if {$parent eq "root"} {
      add_to_recently_opened $dir
      set dir_tail [file tail $dir]
      set dir_path $dir
    } else {
      set parent_dir [$widgets(tl) cellcget $parent,name -text]
      set dir_tail   [lindex [file split $dir] [llength [file split $parent_dir]]]
      set dir_path   [file join $parent_dir $dir_tail]
      if {![$widgets(tl) isexpanded $parent]} {
        $widgets(tl) expand $parent -partly
      }
    }

    # If we have hit the end of the path, return the parent
    if {$dir_tail eq ""} {
      return $parent
    }

    # Search for a match in the parent directory
    set i     0
    set index end
    foreach child [$widgets(tl) childkeys $parent] {
      set name [$widgets(tl) cellcget $child,name -text]
      if {[string compare -length [string length $name] $dir $name] == 0} {
        return [add_directory $dir $child]
      }
      if {($index eq "end") && ([string compare $dir_tail [file tail $name]] < 1)} {
        set index $i
      }
      incr i
    }

    # If no match was found, add it at the ordered index
    set parent [$widgets(tl) insertchild $parent $index [list $dir_path 0]]

    # Add the directory contents
    add_subdirectory $parent

    return $parent

  }

  ######################################################################
  # Recursively adds the current directory and all subdirectories and files
  # found within it to the sidebar.
  proc add_subdirectory {parent} {

    variable widgets
    variable images

    # Get the directory path
    set dir [$widgets(tl) cellcget $parent,name -text]

    # Get the folder contents and sort them
    foreach name [order_files_dirs [glob -nocomplain -directory $dir *]] {

      if {[file isdirectory $name]} {
        set child [$widgets(tl) insertchild $parent end [list $name 0]]
        $widgets(tl) collapse $child
      } else {
        if {![ignore_file $name]} {
          set key [$widgets(tl) insertchild $parent end [list $name 0]]
          if {[gui::file_exists $name]} {
            $widgets(tl) cellconfigure $key,name -image $images(sopen)
            update_root_count $key 1
          }
        }
      }

    }

  }

  ######################################################################
  # Figure out if the given file should be ignored.
  proc ignore_file {fname} {

    # If the file is a binary file, ignore it
    if {[lsearch [fileutil::fileType $fname] "binary"] != -1} {
      return 1
    }

    # Ignore the file if we are told to ignore executables and the file is an executable
    if {[preferences::get Sidebar/IgnoreExecutables] && [file isfile $fname] && [file executable $fname]} {
      return 1
    }

    # Ignore the file if it matches any of the ignore patterns
    foreach pattern [preferences::get Sidebar/IgnoreFilePatterns] {
      if {[string match $pattern $fname]} {
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Handles directory/file ordering issues
  proc order_files_dirs {contents} {

    set contents [lsort -unique $contents]

    # If we need to show the folders at the top, handle this
    if {[preferences::get Sidebar/FoldersAtTop]} {
      set tmp_dirs  [list]
      set tmp_files [list]
      foreach name $contents {
        if {[file isdirectory $name]} {
          lappend tmp_dirs $name
        } else {
          lappend tmp_files $name
        }
      }
      set contents [concat $tmp_dirs $tmp_files]
    }

    return $contents

  }



  ######################################################################
  # Recursively updates the given directory (if the child directories
  # are already expanded.
  proc update_directory_recursively {parent} {

    variable widgets

    # If the parent is not root, update the directory
    if {$parent ne "root"} {
      update_directory $parent
    }

    # Update the child directories that are not expanded
    foreach child [$widgets(tl) childkeys $parent] {
      if {[$widgets(tl) isexpanded $child]} {
        update_directory_recursively $child
      }
    }

  }

  ######################################################################
  # Update the given directory to include (or uninclude) new file
  # information.
  proc update_directory {parent} {

    variable widgets
    variable images

    # Get the directory contents (removing anything that matches the
    # ignored file patterns)
    set dir_files [list]
    foreach dir_file [glob -nocomplain -directory [$widgets(tl) cellcget $parent,name -text] *] {
      if {![ignore_file $dir_file]} {
        lappend dir_files $dir_file
      }
    }

    set dir_files [lassign [order_files_dirs $dir_files] dir_file]
    foreach child [$widgets(tl) childkeys $parent] {
      set tl_file [$widgets(tl) cellcget $child,name -text]
      set compare [string compare $tl_file $dir_file]
      if {($compare == -1) || ($dir_file eq "")} {
        $widgets(tl) delete $child
      } else {
        while {1} {
          if {$compare == 1} {
            set node [$widgets(tl) insertchild $parent [$widgets(tl) childindex $child] [list $dir_file 0]]
            if {[file isdirectory $dir_file]} {
              $widgets(tl) collapse $node
            } elseif {[gui::file_exists $dir_file]} {
              $widgets(tl) cellconfigure $node,name -image $images(sopen)
            }
          }
          set dir_files [lassign $dir_files dir_file]
          if {($compare == 0) || ($dir_file eq "")} { break }
          set compare [string compare $tl_file $dir_file]
        }
      }
    }

  }

  ######################################################################
  # Formats the name such that the full pathname is reduced to the tail
  # of the pathname.
  proc format_name {value} {

    return [file tail $value]

  }

  ######################################################################
  # Finds the root directory of the given descendent and updates its
  # value +/- the value.
  proc update_root_count {descendant value} {

    variable widgets

    # Get the root directory in the table
    while {[set parent [$widgets(tl) parentkey $descendant]] ne "root"} {
      set descendant $parent
    }

    # Increment/decrement the descendant row by the given value
    set ocount [expr [$widgets(tl) cellcget $descendant,ocount -text] + $value]
    $widgets(tl) cellconfigure $descendant,ocount -text $ocount

    # If the user wants us to auto-remove when the open file count reaches 0,
    # remove it from the sidebar
    if {[preferences::get Sidebar/RemoveRootAfterLastClose] && ($ocount == 0)} {
      $widgets(tl) delete $descendant
    }

  }

  ######################################################################
  # Expands the currently selected directory.
  proc expand_directory {tbl row} {

    # Clean the subdirectory
    $tbl delete [$tbl childkeys $row]

    # Add the missing subdirectory
    add_subdirectory $row

  }

  ######################################################################
  # Displays a tooltip for each root row.
  proc show_tooltip {tbl row col} {

    if {($row >= 0) && ([$tbl parentkey $row] eq "root")} {
      tooltip::tooltip $tbl [$tbl cellcget $row,name -text]
    } else {
      tooltip::tooltip clear
    }

  }

  ######################################################################
  # Hides the tooltip associated with the root row.
  proc hide_tooltip {tbl} {

    tooltip::tooltip clear

  }

  ######################################################################
  # Handle a selection change to the sidebar.
  proc handle_selection {} {

    variable widgets
    variable images

    # Get the current selection
    if {[llength [set selected [$widgets(tl) curselection]]]} {

      # Make sure that all of the selections matches the same type (root, dir, file)
      set anchor_type [row_type anchor]
      foreach row $selected {
        if {[row_type $row] ne $anchor_type} {
          $widgets(tl) selection clear $row
        }
      }

      # If the file is currently in the notebook, make it the current tab
      if {([llength $selected] == 1) && ([$widgets(tl) cellcget $selected,name -image] eq $images(sopen))} {
        gui::set_current_tab_from_fname [$widgets(tl) cellcget $selected,name -text]
      }

    }

  }

  ######################################################################
  # Handles right click from the sidebar table.
  proc handle_right_click {W x y} {

    variable widgets

    # If nothing is currently selected, select the row under the cursor
    if {[llength [$widgets(tl) curselection]] == 0} {

      lassign [tablelist::convEventFields $W $x $y] W x y
      lassign [split [$widgets(tl) containingcell $x $y] ,] row col

      if {$row == -1} {
        return
      }

      # Set the selection to the right-clicked element
      $widgets(tl) selection clear 0 end
      $widgets(tl) selection set $row
      handle_selection

    }

    # Display the menu
    tk_popup $widgets(menu) [expr [winfo rootx $W] + $x] [expr [winfo rooty $W] + $y]

  }

  ######################################################################
  # Handles double-click from the sidebar table.
  proc handle_double_click {W x y} {

    variable widgets

    lassign [tablelist::convEventFields $W $x $y] W x y
    lassign [split [$widgets(tl) containingcell $x $y] ,] row col

    if {$row != -1} {

      if {[file isfile [$widgets(tl) cellcget $row,name -text]]} {

        # Select the file
        $widgets(tl) selection clear 0 end
        $widgets(tl) selection set $row

        # Open the file in the viewer
        gui::add_file end [$widgets(tl) cellcget $row,name -text]

      } else {

        if {[$widgets(tl) isexpanded $row]} {
          $widgets(tl) collapse $row
        } else {
          $widgets(tl) expand $row
        }

      }

    }

  }

  ######################################################################
  # Handles a press of the return key when the sidebar has the focus.
  proc handle_return {W} {

    variable widgets

    # Get the currently selected rows
    foreach row [$widgets(tl) curselection] {

      if {[file isfile [$widgets(tl) cellcget $row,name -text]]} {

        # Open the file in the viewer
        gui::add_file end [$widgets(tl) cellcget $row,name -text]

      } else {

        if {[$widgets(tl) isexpanded $row]} {
          $widgets(tl) collapse $row
        } else {
          $widgets(tl) expand $row
        }
      }

    }

  }


  ######################################################################
  # Copies the given row's file/folder pathname to the clipboard.
  proc copy_pathname {row} {

    variable widgets

    # Set the clipboard to the currentl selection
    clipboard clear
    clipboard append [$widgets(tl) cellcget $row,name -text]

    # Add the clipboard contents to history
    cliphist::add_from_clipboard

  }

  ######################################################################
  # Adds a new file to the given folder.
  proc add_file_to_folder {row} {

    variable widgets

    # Get the new filename from the user
    set fname ""
    if {![gui::get_user_response [msgcat::mc "File Name:"] fname]} {
      return
    }

    # Normalize the pathname
    if {[file pathtype $fname] eq "relative"} {
      set fname [file normalize [file join [$widgets(tl) cellcget $row,name -text] $fname]]
    }

    # Create the file
    if {![catch { open $fname w } rc]} {

      # Close the file
      close $rc

      # Expand the directory
      $widgets(tl) expand $row -partly

      # Create an empty file
      gui::add_file end $fname

    }

  }

  ######################################################################
  # Adds a new folder to the specified folder.
  proc add_folder_to_folder {row} {

    variable widgets

    # Get the directory name from the user
    set dname ""
    if {![gui::get_user_response [msgcat::mc "Directory Name:"] dname]} {
      return
    }

    # Normalize the pathname
    if {[file pathtype $dname] eq "relative"} {
      set dname [file normalize [file join [$widgets(tl) cellcget $row,name -text] $dname]]
    }

    # Create the directory
    if {![catch { file mkdir $dname }]} {

      # Expand the directory
      $widgets(tl) expand $row -partly

      # Update the directory
      update_directory $row

    }

  }

  ######################################################################
  # Opens all of the files in the current directory.
  proc open_folder_files {rows} {

    variable widgets
    variable images

    foreach row $rows {

      # Open all of the children that are not already opened
      foreach child [$widgets(tl) childkeys $row] {
        set name [$widgets(tl) cellcget $child,name -text]
        if {([$widgets(tl) cellcget $child,name -image] ne $images(sopen)) && [file isfile $name]} {
          gui::add_file end $name
        }
      }

    }

  }

  ######################################################################
  # Close all of the open files in the current directory.
  proc close_folder_files {rows} {

    variable widgets
    variable images

    foreach row $rows {

      # Close all of the opened children
      foreach child [$widgets(tl) childkeys $row] {
        if {[$widgets(tl) cellcget $child,name -image] eq $images(sopen)} {
          gui::close_file [$widgets(tl) cellcget $child,name -text]
        }
      }

    }

  }

  ######################################################################
  # Allows the user to rename the currently selected folder.
  proc rename_folder {row} {

    variable widgets
    variable images

    # Get the current name
    set old_name [set fname [$widgets(tl) cellcget $row,name -text]]

    # Get the new name from the user
    if {[gui::get_user_response [msgcat::mc "Folder Name:"] fname]} {

      # If the value of the cell hasn't changed or is empty, do nothing else.
      if {($old_name eq $fname) || ($fname eq "")} {
        return
      }

      # Normalize the folder
      set fname [file normalize $fname]

      # Allow any plugins to handle the rename
      plugins::handle_on_rename $old_name $fname

      # Perform the rename operation
      if {![catch { file rename -force $old_name $fname } rc]} {

        # If this is a displayed file, update the file information
        gui::change_folder $old_name $fname

        # Delete the old directory
        $widgets(tl) delete $row

        # Add the file directory
        update_directory [add_directory $fname]

      }

    }

  }

  ######################################################################
  # Allows the user to delete the folder at the given row.
  proc delete_folder {row} {

    variable widgets

    if {[tk_messageBox -parent . -type yesno -default yes -message [msgcat::mc "Delete directory?"]] eq "yes"} {

      # Get the directory pathname
      set dirpath [$widgets(tl) cellcget $row,name -text]

      # Allow any plugins to handle the rename
      plugins::handle_on_delete $dirpath

      # Delete the folder
      if {![catch { file delete -force $dirpath }]} {

        # Remove the directory from the file browser
        $widgets(tl) delete $row

      }

    }

  }

  ######################################################################
  # Causes the given folder/file to become a favorite.
  proc favorite {row} {

    variable widgets

    # Set the folder to be a favorite
    favorites::add [$widgets(tl) cellcget $row,name -text]

  }

  ######################################################################
  # Causes the given folder/file to become a non-favorite.
  proc unfavorite {row} {

    variable widgets

    # Remove the folder from the favorites list
    favorites::remove [$widgets(tl) cellcget $row,name -text]

  }

  ######################################################################
  # Removes the specified folder rows from the sidebar.
  proc remove_folder {rows} {

    variable widgets

    foreach row [lreverse $rows] {

      # Delete the row and its children
      $widgets(tl) delete $row

    }

  }

  ######################################################################
  # Removes the parent(s) of the specified folder from the sidebar.
  proc remove_parent_folder {row} {

    variable widgets

    # Find the child index of the ancestor of the root
    set child $row
    while {[set parent [$widgets(tl) parentkey $child]] ne "root"} {
      set child $parent
    }

    # Move the row to root
    $widgets(tl) move $row root [$widgets(tl) childindex $child]

    # Delete the child tree
    $widgets(tl) delete $child

  }

  ######################################################################
  # Sets the currently selected directory to the working directory.
  proc set_current_working_directory {row} {

    variable widgets

    # Set the current working directory to the selected pathname
    cd [$widgets(tl) cellcget $row,name -text]

    # Update the UI
    gui::set_title

  }

  ######################################################################
  # Refreshes the specified directory contents.
  proc refresh_directory_files {rows} {

    variable widgets

    foreach row [lreverse $rows] {

      # Do a directory expansion
      expand_directory $widgets(tl) $row

    }

  }

  ######################################################################
  # Adds the parent directory to the sidebar of the currently selected
  # row.
  proc add_parent_directory {row} {

    variable widgets

    # Get the list of all root children
    set children [$widgets(tl) childkeys root]

    # Add the parent directory to the sidebar
    set parent [add_directory [file dirname [$widgets(tl) cellcget $row,name -text]]]

    # Find/move children
    set ocount 0
    foreach child $children {
      if {[set match [$widgets(tl) searchcolumn name [$widgets(tl) cellcget $child,name -text] -parent $parent -exact]] != -1} {
        set index [$widgets(tl) childindex $match]
        $widgets(tl) delete $match
        $widgets(tl) move $child $parent $index
        incr ocount [$widgets(tl) cellcget $child,ocount -text]
      }
    }

    # Set the ocount value of the new parent directory
    $widgets(tl) cellconfigure $parent,ocount -text $ocount

  }

  ######################################################################
  # Opens the currently selected file in the notebook.
  proc open_file {rows} {

    variable widgets

    foreach row $rows {

      # Add the file to the notebook
      gui::add_file end [$widgets(tl) cellcget $row,name -text]

    }

  }

  ######################################################################
  # Opens the file difference view for the specified file.
  proc show_file_diff {row} {

    variable widgets

    # Add the file to the notebook in difference view
    gui::add_file end [$widgets(tl) cellcget $row,name -text] -diff 1 -other [[ns preferences]::get View/ShowDifferenceInOtherPane]

  }

  ######################################################################
  # Closes the specified file in the notebook.
  proc close_file {rows} {

    variable widgets
    variable images

    foreach row $rows {

      # If the current file is selected, close it
      if {[$widgets(tl) cellcget $row,name -image] eq $images(sopen)} {

        # Close the tab at the current location
        gui::close_file [$widgets(tl) cellcget $row,name -text]

      }

    }

  }

  ######################################################################
  # Allow the user to rename the currently selected file in the file
  # browser.
  proc rename_file {row} {

    variable widgets
    variable images

    # Get the current name
    set old_name [set fname [$widgets(tl) cellcget $row,name -text]]

    # Get the new name from the user
    if {[gui::get_user_response [msgcat::mc "File Name:"] fname]} {

      # If the value of the cell hasn't changed or is empty, do nothing else.
      if {($old_name eq $fname) || ($fname eq "")} {
        return
      }

      # Normalize the filename
      set fname [file normalize $fname]

      # Allow any plugins to handle the rename
      plugins::handle_on_rename $old_name $fname

      # Perform the rename operation
      if {![catch { file rename -force $old_name $fname }]} {

        # Update the file information (if necessary)
        gui::change_filename $old_name $fname

        # Add the file directory
        update_directory [add_directory [file dirname $fname]]

        # Update the old directory
        after idle [list sidebar::update_directory [$widgets(tl) parentkey $row]]

      }

    }

  }

  ######################################################################
  # Creates a duplicate of the specified file, adds it to the
  # sideband and allows the user to modify its name.
  proc duplicate_file {row} {

    variable widgets

    # Get the filename of the current selection
    set fname [$widgets(tl) cellcget $row,name -text]

    # Create the default name of the duplicate file
    set dup_fname "[file rootname $fname] Copy[file extension $fname]"
    set num       1
    while {[file exists $dup_fname]} {
      set dup_fname "[file rootname $fname] Copy [incr num][file extension $fname]"
    }

    # Copy the file to create the duplicate
    if {![catch { file copy $fname $dup_fname } rc]} {

      # Add the file to the sidebar (just below the currently selected line)
      set new_row [$widgets(tl) insertchild \
        [$widgets(tl) parentkey $row] [expr [$widgets(tl) childindex $row] + 1] \
        [list $dup_fname 0]]

      # Allow any plugins to handle the rename
      plugins::handle_on_duplicate $fname $dup_fname

    }

  }

  ######################################################################
  # Deletes the specified file.
  proc delete_file {row} {

    variable widgets
    variable images

    # Get confirmation from the user
    if {[tk_messageBox -parent . -type yesno -default yes -message [msgcat::mc "Delete file?"]] eq "yes"} {

      # Get the full pathname
      set fname [$widgets(tl) cellcget $row,name -text]

      # Allow any plugins to handle the rename
      plugins::handle_on_delete $fname

      # Delete the file
      if {![catch { file delete -force $fname }]} {

        # Get the background color before we delete the row
        set bg [$widgets(tl) cellcget $row,name -image]

        # Delete the row in the table
        $widgets(tl) delete $row

        # Close the tab if the file is currently in the notebook
        if {$bg eq $images(sopen)} {
          gui::close_file $fname
        }

      }

    }

  }

  ######################################################################
  # Handle any changes to the ignore file patterns/executables preference variables.
  proc handle_ignore_files {name1 name2 op} {

    # Update all of the top-level directories
    update_directory_recursively root

  }

  ######################################################################
  # Handle any changes to the General/WindowTheme preference variable.
  proc handle_window_theme {theme} {

    variable widgets

    set fg  [utils::get_default_foreground]
    set bg  [utils::get_default_background]
    set abg [utils::auto_adjust_color $bg 30]

    # Configure the tablelist widget
    if {[info exists widgets(tl)]} {
      $widgets(tl) configure -foreground $fg -background $bg -selectbackground $abg -selectforeground $fg \
        -highlightbackground $bg -highlightcolor $bg
    }

  }

  ######################################################################
  # Returns a list of files specifically for use in the "find in files"
  # function.
  proc get_fif_files {} {

    variable widgets
    variable images

    set fif_files [list]
    set odirs     [list]
    set ofiles    [list]

    # Gather the lists of files, opened files and opened directories
    for {set i 0} {$i < [$widgets(tl) size]} {incr i} {
      set name [$widgets(tl) cellcget $i,name -text]
      if {[file isdirectory $name]} {
        if {[$widgets(tl) isexpanded $i] || ([$widgets(tl) parentkey $i] eq "root")} {
          lappend odirs $name
        }
        lappend fif_files [list $name $name]
      } else {
        if {[$widgets(tl) cellcget $i,name -image] eq $images(sopen)} {
          lappend ofiles $name
        }
        lappend fif_files [list $name $name]
      }
    }

    # Add the favorites list
    foreach favorite [favorites::get_list] {
      if {[lsearch -index 1 $fif_files $favorite] == -1} {
        lappend fif_files [list $favorite $favorite]
      }
    }

    # Add the Opened files/directories
    if {[llength $ofiles] > 0} {
      lappend fif_files [list {Opened Files} $ofiles]
    }
    if {[llength $odirs] > 0} {
      lappend fif_files [list {Opened Directories} $odirs]
    }
    lappend fif_files [list {Current Directory} [pwd]]

    return [lsort -index 0 $fif_files]

  }

  ######################################################################
  # Recursively expands the tablelist to show the given filename.
  proc show_file_helper {parent fdir} {

    variable widgets

    foreach child [$widgets(tl) childkeys $parent] {
      set dir [$widgets(tl) cellcget $child,name -text]
      if {[string compare -length [string length $dir] $fdir $dir] == 0} {
        $widgets(tl) expand $child -partly
        if {$fdir ne $dir} {
          show_file_helper $child $fdir
        }
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Shows the given filename in the sidebar browser.  Adds parent
  # directory if the file does not exist in the sidebar.
  proc show_file {fname} {

    variable widgets

    # Show the file in the sidebar
    if {![show_file_helper root [file dirname $fname]]} {
      add_directory [file dirname $fname]
    }

    # Put the file into view
    if {[set row [$widgets(tl) searchcolumn name $fname -descend -exact]] != -1} {
      $widgets(tl) selection clear 0 end
      $widgets(tl) selection set $row
      $widgets(tl) see $row
    }

  }

  ######################################################################
  # If value is set to 1, the sidebar will be transformed into a draggable
  # mode of operation.  If value is set to 0, the sidebar will return to
  # normal mode of operation.
  proc set_draggable {value} {

    variable widgets

    $widgets(tl) configure -customdragsource $value

  }

}
