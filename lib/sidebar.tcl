# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2017  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:    sidebar.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/03/2013
# Brief:   Handles the UI and related functionality associated with the
#          sidebar.
######################################################################

namespace eval sidebar {

  variable last_opened      {}
  variable selection_anchor ""
  variable last_id          ""
  variable after_id         ""
  variable jump_str         ""
  variable jump_after_id    ""
  variable show_file_info   1

  array set widgets {}

  ######################################################################
  # Returns a list containing information that the sidebar will save to the
  # session file.
  proc save_session {} {

    variable widgets
    variable last_opened

    set dirs [list]
    foreach child [$widgets(tl) children ""] {
      if {[$widgets(tl) set $child remote] eq ""} {
        lappend dirs [list name [$widgets(tl) set $child name]]
      }
    }

    return [list directories $dirs last_opened $last_opened opened_dirs [get_opened_dirs]]

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
      opened_dirs {}
    }
    array set content $data

    # Add the last_opened directories to the saved list
    set last_opened $content(last_opened)

    # Add the session directories (if the sidebar is currently empty)
    if {[llength [$widgets(tl) children ""]] == 0} {
      foreach dir_list $content(directories) {
        array set dir $dir_list
        add_directory $dir(name)
      }
    }

    # Make sure all of the appropriate directories are opened
    foreach name $content(opened_dirs) {
      if {[set row [$widgets(tl) tag has $name,]] ne ""} {
        expand_directory $row
      }
    }

  }

  ######################################################################
  # Returns a list containing
  proc get_opened_dirs {} {

    variable widgets

    set dirs [list]

    foreach dir [$widgets(tl) tag has d] {
      if {([$widgets(tl) set $dir remote] eq "") && [$widgets(tl) item $dir -open]} {
        lappend dirs [$widgets(tl) set $dir name]
      }
    }

    return $dirs

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

    # Create needed images
    theme::register_image sidebar_open bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar to indicate that a file is currently opened in an editing buffer."} \
      -file [file join $::tke_dir lib images sopen.bmp] \
      -maskfile [file join $::tke_dir lib images smask.bmp] \
      -foreground gold -background black

    theme::register_image sidebar_hidden bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar to indicate that a file is currently opened but hidden"} \
      -file [file join $::tke_dir lib images sopen.bmp] \
      -maskfile [file join $::tke_dir lib images smask.bmp] \
      -foreground white -background black

    theme::register_image sidebar_file bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar to indicate a file"} \
      -file [file join $::tke_dir lib images blank10.bmp] \
      -maskfile [file join $::tke_dir lib images blank10.bmp] \
      -foreground 1

    theme::register_image sidebar_expanded bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar to indicate a directory that is showing its contents"} \
      -file [file join $::tke_dir lib images down10.bmp] \
      -maskfile [file join $::tke_dir lib images down10.bmp] \
      -foreground 1

    theme::register_image sidebar_collapsed bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar to indicate a directory that is collapsed"} \
      -file [file join $::tke_dir lib images right10.bmp] \
      -maskfile [file join $::tke_dir lib images right10.bmp] \
      -foreground 1

    theme::register_image sidebar_expanded_sel bitmap sidebar -selectbackground \
      {msgcat::mc "Image displayed in sidebar to indicate a selected directory that is expanded"} \
      -file [file join $::tke_dir lib images down10.bmp] \
      -maskfile [file join $::tke_dir lib images down10.bmp] \
      -foreground 2

    theme::register_image sidebar_collapsed_sel bitmap sidebar -selectbackground \
      {msgcat::mc "Image displayed in sidebar to indicate a selected directory that is collapsed"} \
      -file [file join $::tke_dir lib images right10.bmp] \
      -maskfile [file join $::tke_dir lib images right10.bmp] \
      -foreground 2

    set fg [utils::get_default_foreground]
    set bg [utils::get_default_background]

    frame $w

    # Create the top-level frame
    set widgets(frame) [frame $w.tf -highlightthickness 1 -highlightbackground $bg -highlightcolor $bg]

    # Add the file tree elements
    ttk::frame $w.tf.tf -style SBFrame -padding {3 3 0 0}
    pack [set widgets(tl) \
      [ttk::treeview $w.tf.tf.tl -style SBTreeview -columns {name ocount remote} -displaycolumns {} \
        -show tree -yscrollcommand "utils::set_yscrollbar $w.tf.vb"]] -fill both -expand yes
    set widgets(sb) [scroller::scroller $w.tf.vb -orient vertical -foreground $fg -background $bg -command [list $widgets(tl) yview]]

    $widgets(tl) column #0 -width 300

    bind $widgets(tl) <<TreeviewSelect>>      [list sidebar::handle_selection]
    bind $widgets(tl) <<TreeviewOpen>>        [list sidebar::expand_directory]
    bind $widgets(tl) <<TreeviewClose>>       [list sidebar::collapse]
    bind $widgets(tl) <Button-1>              [list sidebar::handle_left_click %W %x %y]
    bind $widgets(tl) <Button-$::right_click> [list sidebar::handle_right_click %W %x %y]
    bind $widgets(tl) <Double-Button-1>       [list sidebar::handle_double_click %W %x %y]
    bind $widgets(tl) <Motion>                [list sidebar::handle_motion %W %x %y]
    bind $widgets(tl) <Return> {
      sidebar::handle_return_space %W
      break
    }
    bind $widgets(tl) <Key-space> {
      sidebar::handle_return_space %W
      break
    }
    bind $widgets(tl) <Key>      [list sidebar::handle_any %K %A]
    bind $widgets(tl) <FocusIn>  [list sidebar::handle_focus_in]
    bind $widgets(tl) <FocusOut> [list sidebar::handle_focus_out]

    grid rowconfigure    $w.tf 0 -weight 1
    grid columnconfigure $w.tf 0 -weight 1
    grid $w.tf.tf -row 0 -column 0 -sticky news
    grid $w.tf.vb -row 0 -column 1 -sticky ns

    # Create file info images
    image create photo  photo_preview
    image create bitmap bitmap_preview

    # Create file info panel
    set widgets(info,f)       [frame $w.if]
    ttk::separator            $w.if.sep1 -orient horizontal
    set widgets(info,v,image) [label $w.if.preview]
    set widgets(info,f,1)     [frame $w.if.f1]
    set widgets(info,v,name)  [label $w.if.name]
    set widgets(info,v,type)  [label $w.if.type]
    set widgets(info,f,2)     [frame $w.if.f2]
    set widgets(info,l,ver)   [label $w.if.l1 -text [format "%s:" [msgcat::mc "Version"]]]
    set widgets(info,v,ver)   [label $w.if.version]
    set widgets(info,l,mod)   [label $w.if.l2  -text [format "%s:" [msgcat::mc "Modified"]]]
    set widgets(info,v,mod)   [label $w.if.modified]
    set widgets(psep)         [ttk::separator $w.if.sep2 -orient horizontal]

    grid rowconfigure    $w.if 3 -weight 1
    grid columnconfigure $w.if 1 -weight 1
    grid $w.if.sep1     -row 0 -column 0 -columnspan 2 -sticky ew
    grid $w.if.preview  -row 1 -column 0 -rowspan 3 -padx 2 -pady 2 ;# -sticky news
    grid $w.if.name     -row 1 -column 1 -sticky w ;# -columnspan 2 ;# -sticky ew
    grid $w.if.type     -row 2 -column 1 -sticky w ;# -columnspan 2 ;# -sticky ew
    ;# grid $w.if.f1       -row 3 -column 1
    ;# grid $w.if.f2       -row 5 -column 0 -pady 2
    grid $w.if.l1       -row 4 -column 0 -sticky e
    grid $w.if.version  -row 4 -column 1 -sticky w
    grid $w.if.l2       -row 5 -column 0 -sticky e
    grid $w.if.modified -row 5 -column 1 -sticky w
    grid $w.if.sep2     -row 6 -column 0 -sticky ew -columnspan 2

    # Insert any file information plugin information
    insert_file_info_plugins

    pack $w.tf -fill both -expand yes

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

    # Register the sidebar and sidebar scrollbar for theming purposes
    theme::register_widget $widgets(tl) sidebar
    theme::register_widget $widgets(sb) sidebar_scrollbar

    # Handle traces
    trace variable preferences::prefs(Sidebar/IgnoreFilePatterns) w sidebar::handle_ignore_files
    trace variable preferences::prefs(Sidebar/IgnoreBinaries)     w sidebar::handle_ignore_files
    trace variable preferences::prefs(View/ShowFileInfo)          w sidebar::handle_file_info_view

    return $w

  }

  ######################################################################
  # Inserts the file information plugin labels into the file information panel.
  proc insert_file_info_plugins {} {

    variable widgets

    set w $widgets(info,f)

    # Remove any existing plugins
    foreach name [array names widgets info,l,plug*] {
      lassign [split $name ,] dummy1 dummy2 pname
      grid forget $widgets(info,l,$pname) $widgets(info,v,$pname)
      destroy $widgets(info,l,$pname) $widgets(info,v,$pname)
    }

    # Forget the previous plugin widgets
    array unset widgets info,*,plug*

    # Figure out which row we should start inserting
    set row [expr [lindex [grid size $w] 1] - 1]

    # Get the colors
    set lfgcolor [$widgets(info,l,mod) cget -foreground]
    set lbgcolor [$widgets(info,l,mod) cget -background]
    set vfgcolor [$widgets(info,v,mod) cget -foreground]
    set vbgcolor [$widgets(info,v,mod) cget -background]

    # Get any file information plugin entries
    foreach {index title} [plugins::get_file_info_titles] {

      # Create the widgets
      set widgets(info,l,plug$index) [label $w.pl$index -text "$title:" -foreground $lfgcolor -background $lbgcolor]
      set widgets(info,v,plug$index) [label $w.pv$index -foreground $vfgcolor -background $vbgcolor]

      # Insert them into the grid
      grid $w.pl$index -row $row -column 0 -sticky e
      grid $w.pv$index -row $row -column 1 -sticky w
      incr row

    }

    # Adjust the row of the last separator
    grid $widgets(psep) -row $row

    # Finally, call handle_selection in case we need to update the values in the file information panel
    handle_selection

  }

  ######################################################################
  # Sets the row's image and adjusts the text to provide a gap between
  # the image and the text.
  proc set_image {row img} {

    variable widgets

    # Get the item's name
    set name [string trim [$widgets(tl) item $row -text]]

    if {$img eq ""} {
      $widgets(tl) item $row -image $img -text $name
    } else {
      $widgets(tl) item $row -image $img -text " $name"
    }

  }

  ######################################################################
  # Clears the sidebar of all content.  This is primarily called when
  # we are switching sessions.
  proc clear {} {

    variable widgets

    $widgets(tl) delete [$widgets(tl) children {}]

  }

  ######################################################################
  # Handles a drag-and-drop enter/position event.  Draws UI to show that
  # the file drop request would be excepted or rejected.
  proc handle_drop_enter_or_pos {tbl rootx rooty actions buttons} {

    array set opts [theme::get_category_options sidebar 1]

    [winfo parent [winfo parent $tbl]] configure -highlightbackground $opts(-dropcolor)

    return "link"

  }

  ######################################################################
  # Handles a drop leave event.
  proc handle_drop_leave {tbl} {

    array set opts [theme::get_category_options sidebar 1]

    [winfo parent [winfo parent $tbl]] configure -highlightbackground $opts(-highlightbackground)

  }

  ######################################################################
  # Handles a drop event.  Adds the given files/directories to the sidebar.
  proc handle_drop {tbl action files} {

    foreach fname $files {
      if {[file isdirectory $fname]} {
        add_directory $fname
      } elseif {![::check_file_for_import $fname]} {
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

    if {[$widgets(tl) parent $row] eq ""} {
      return "root"
    } elseif {[$widgets(tl) tag has d $row]} {
      return "dir"
    } else {
      return "file"
    }

  }

  ######################################################################
  # Handles the contents of the sidebar popup menu prior to it being posted.
  proc menu_post {} {

    variable widgets
    variable selection_anchor

    # Get the current index
    switch [row_type $selection_anchor] {
      "root" { setup_root_menu [$widgets(tl) selection] }
      "dir"  { setup_dir_menu  [$widgets(tl) selection] }
      "file" { setup_file_menu [$widgets(tl) selection] }
    }

  }

  ######################################################################
  # Return a list of menu states to use for directories.  The returned
  # list is:  <open_state> <close_state> <hide_state> <show_state>
  proc get_menu_states {rows} {

    variable widgets

    set opened "disabled"
    set closed "disabled"
    set hide   "disabled"
    set show   "disabled"

    foreach row $rows {
      foreach child [$widgets(tl) children $row] {
        switch [$widgets(tl) item $child -image] {
          "sidebar_hidden" { set closed "normal"; set show "normal" }
          "sidebar_open"   { set closed "normal"; set hide "normal" }
          default          { set opened "normal" }
        }
      }
    }

    return [list $opened $closed $hide $show]

  }

  ######################################################################
  # Sets up the popup menu to be suitable for the given directory.
  proc setup_dir_menu {rows} {

    variable widgets

    set one_state    [expr {([llength $rows] == 1) ? "normal" : "disabled"}]
    set fav_state    $one_state
    set first_row    [lindex $rows 0]
    set remote_found 0

    lassign [get_menu_states $rows] open_state close_state hide_state show_state

    foreach row $rows {
      if {[$widgets(tl) set $row remote] ne ""} {
        set fav_state    "disabled"
        set remote_found 1
        break
      }
    }

    # Clear the menu
    $widgets(menu) delete 0 end

    $widgets(menu) add command -label [msgcat::mc "New File"]               -command [list sidebar::add_file_to_folder $first_row]     -state $one_state
    $widgets(menu) add command -label [msgcat::mc "New File From Template"] -command [list sidebar::add_file_from_template $first_row] -state $one_state
    $widgets(menu) add command -label [msgcat::mc "New Directory"]          -command [list sidebar::add_folder_to_folder $first_row]   -state $one_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Open Directory Files"]  -command [list sidebar::open_folder_files $rows]  -state $open_state
    $widgets(menu) add command -label [msgcat::mc "Close Directory Files"] -command [list sidebar::close_folder_files $rows] -state $close_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Hide Directory Files"]  -command [list sidebar::hide_folder_files $rows] -state $hide_state
    $widgets(menu) add command -label [msgcat::mc "Show Directory Files"]  -command [list sidebar::show_folder_files $rows] -state $show_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Copy Pathname"] -command [list sidebar::copy_pathname $first_row] -state $one_state
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Rename"] -command [list sidebar::rename_folder $first_row] -state $one_state
    if {[preferences::get General/UseMoveToTrash] && !$remote_found} {
      $widgets(menu) add command -label [msgcat::mc "Move To Trash"] -command [list sidebar::move_to_trash $rows]
    } else {
      $widgets(menu) add command -label [msgcat::mc "Delete"] -command [list sidebar::delete_folder $rows]
    }
    $widgets(menu) add separator

    if {[favorites::is_favorite [$widgets(tl) set $first_row name]]} {
      $widgets(menu) add command -label [msgcat::mc "Unfavorite"] -command [list sidebar::unfavorite $first_row] -state $fav_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Favorite"] -command [list sidebar::favorite $first_row] -state $fav_state
    }
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Remove from Sidebar"]        -command [list sidebar::remove_folder $rows]
    $widgets(menu) add command -label [msgcat::mc "Remove Parent from Sidebar"] -command [list sidebar::remove_parent_folder $first_row] -state $one_state
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Make Current Working Directory"] -command [list sidebar::set_current_working_directory $first_row] -state $fav_state
    $widgets(menu) add command -label [msgcat::mc "Refresh Directory Files"]        -command [list sidebar::refresh_directory_files $rows]

    # Add plugins to sidebar directory popup
    plugins::handle_dir_popup $widgets(menu)

  }

  ######################################################################
  # Sets up the given menu for a root directory item.
  proc setup_root_menu {rows} {

    variable widgets

    set one_state    [expr {([llength $rows] == 1) ? "normal" : "disabled"}]
    set fav_state    $one_state
    set parent_state $one_state
    set first_row    [lindex $rows 0]
    set remote_found 0

    lassign [get_menu_states $rows] open_state close_state hide_state show_state

    foreach row $rows {
      if {[$widgets(tl) set $row remote] ne ""} {
        set fav_state    "disabled"
        set remote_found 1
        break
      }
    }
    foreach row $rows {
      if {[file tail [$widgets(tl) set $row name]] eq ""} {
        set parent_state "disabled"
        break
      }
    }

    # Clear the menu
    $widgets(menu) delete 0 end

    $widgets(menu) add command -label [msgcat::mc "New File"]               -command [list sidebar::add_file_to_folder $first_row]     -state $one_state
    $widgets(menu) add command -label [msgcat::mc "New File From Template"] -command [list sidebar::add_file_from_template $first_row] -state $one_state
    $widgets(menu) add command -label [msgcat::mc "New Directory"]          -command [list sidebar::add_folder_to_folder $first_row]   -state $one_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Open Directory Files"]  -command [list sidebar::open_folder_files $rows]  -state $open_state
    $widgets(menu) add command -label [msgcat::mc "Close Directory Files"] -command [list sidebar::close_folder_files $rows] -state $close_state
    $widgets(menu) add separator

    if {$remote_found} {
      $widgets(menu) add command -label [msgcat::mc "Disconnect From Server"] -command [list sidebar::disconnect $rows]
      $widgets(menu) add separator
    }

    $widgets(menu) add command -label [msgcat::mc "Hide Directory Files"]  -command [list sidebar::hide_folder_files $rows] -state $hide_state
    $widgets(menu) add command -label [msgcat::mc "Show Directory Files"]  -command [list sidebar::show_folder_files $rows] -state $show_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Copy Pathname"] -command [list sidebar::copy_pathname $first_row] -state $one_state
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Rename"] -command [list sidebar::rename_folder $first_row] -state $one_state
    if {[preferences::get General/UseMoveToTrash] && !$remote_found} {
      $widgets(menu) add command -label [msgcat::mc "Move To Trash"] -command [list sidebar::move_to_trash $rows]
    } else {
      $widgets(menu) add command -label [msgcat::mc "Delete"] -command [list sidebar::delete_folder $rows]
    }
    $widgets(menu) add separator

    if {[favorites::is_favorite [$widgets(tl) set $first_row name]]} {
      $widgets(menu) add command -label [msgcat::mc "Unfavorite"] -command [list sidebar::unfavorite $first_row] -state $fav_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Favorite"] -command [list sidebar::favorite $first_row] -state $fav_state
    }
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Remove from Sidebar"]  -command [list sidebar::remove_folder $rows]
    $widgets(menu) add command -label [msgcat::mc "Add Parent Directory"] -command [list sidebar::add_parent_directory $first_row] -state $parent_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Make Current Working Directory"] -command [list sidebar::set_current_working_directory $first_row] -state $fav_state
    $widgets(menu) add command -label [msgcat::mc "Refresh Directory Files"]        -command [list sidebar::refresh_directory_files $rows]

    # Add plugins to sidebar root popup
    plugins::handle_root_popup $widgets(menu)

  }

  ######################################################################
  # Sets up the file popup menu for the currently selected rows.
  proc setup_file_menu {rows} {

    variable widgets

    set one_state    [expr {([llength $rows] == 1) ? "normal" : "disabled"}]
    set hide_state   "disabled"
    set show_state   "disabled"
    set open_state   "disabled"
    set close_state  "disabled"
    set first_row    [lindex $rows 0]
    set diff_state   [expr {([$widgets(tl) set $first_row remote] eq "") ? $one_state : "disabled"}]
    set remote_found 0

    # Calculate the hide and show menu states
    foreach row $rows {
      switch [$widgets(tl) item $row -image] {
        "sidebar_hidden" { set close_state "normal"; set show_state "normal" }
        "sidebar_open"   { set close_state "normal"; set hide_state "normal" }
        default          { set open_state  "normal" }
      }
    }

    foreach row $rows {
      if {[$widgets(tl) set $row remote] ne ""} {
        set remote_found 1
        break
      }
    }

    # Delete the menu contents
    $widgets(menu) delete 0 end

    # Create file popup
    $widgets(menu) add command -label [msgcat::mc "Open"]  -command [list sidebar::open_file $rows]  -state $open_state
    $widgets(menu) add command -label [msgcat::mc "Close"] -command [list sidebar::close_file $rows] -state $close_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Hide"] -command [list sidebar::hide_file $rows] -state $hide_state
    $widgets(menu) add command -label [msgcat::mc "Show"] -command [list sidebar::show_file $rows] -state $show_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Show Difference"] -command [list sidebar::show_file_diff $first_row] -state $diff_state
    $widgets(menu) add command -label [msgcat::mc "Copy Pathname"]   -command [list sidebar::copy_pathname $first_row]  -state $one_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Rename"]    -command [list sidebar::rename_file $first_row]    -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Duplicate"] -command [list sidebar::duplicate_file $first_row] -state $one_state
    if {[preferences::get General/UseMoveToTrash] && !$remote_found} {
      $widgets(menu) add command -label [msgcat::mc "Move To Trash"] -command [list sidebar::move_to_trash $rows]
    } else {
      $widgets(menu) add command -label [msgcat::mc "Delete"] -command [list sidebar::delete_file $rows]
    }
    $widgets(menu) add separator

    if {[favorites::is_favorite [$widgets(tl) set $first_row name]]} {
      $widgets(menu) add command -label [msgcat::mc "Unfavorite"] -command [list sidebar::unfavorite $first_row] -state $one_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Favorite"] -command [list sidebar::favorite $first_row] -state $one_state
    }

    # Add plugins to sidebar file popup
    plugins::handle_file_popup $widgets(menu)

  }

  ######################################################################
  # Returns the sidebar index of the given filename.  If the filename
  # was not found in the sidebar, return the empty string.
  proc get_index {fname remote} {

    variable widgets

    return [$widgets(tl) tag has $fname,$remote]

  }

  ######################################################################
  # Returns the indices of the current selections.  If nothing is currently
  # selected, returns an empty string.
  proc get_selected_indices {} {

    variable widgets

    # Get the current selection
    return [$widgets(tl) selection]

  }

  ######################################################################
  # Returns the information specified by attr for the file at the given
  # sidebar index.
  proc get_info {index attr} {

    variable widgets

    switch $attr {
      fname      { return [$widgets(tl) set $index name] }
      file_index { return [files::get_index [$widgets(tl) set $index name] [$widgets(tl) set $index remote]] }
      is_dir     { return [$widgets(tl) tag has d $index] }
      default    {
        return -code error "Illegal sidebar attribute specified ($attr)"
      }
    }

  }

  ######################################################################
  # Sets the hide state of the given file to the given value.
  proc set_hide_state {fname remote value} {

    variable widgets

    # Get the associated index (return immediately if it is not found)
    if {[set index [get_index $fname $remote]] eq ""} {
      return
    }

    if {$value} {
      set_image $index sidebar_hidden
    } else {
      set_image $index sidebar_open
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

    foreach row [$widgets(tl) tag has f] {
      if {[$widgets(tl) set $row name] eq $fname} {
        set highlighted [expr {[$widgets(tl) item $row -image] ne ""}]
        switch $highlight_mode {
          0 { set_image $row "" }
          1 { set_image $row sidebar_open }
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
        return
      }
    }

  }

  ######################################################################
  # Adds the given directory which displays within the file browser.
  proc add_directory {dir args} {

    variable widgets

    array set opts {
      -remote ""
      -record 1
    }
    array set opts $args

    # If the directory is not remote, add it to the recently opened menu list
    if {$opts(-record) && ($opts(-remote) eq "")} {
      add_to_recently_opened $dir
    }

    # Search for the directory or an ancestor
    set last_tdir ""
    set tdir      $dir
    while {($tdir ne $last_tdir) && ([set found [$widgets(tl) tag has "$tdir,$opts(-remote)"]] eq "")} {
      set last_tdir $tdir
      set tdir      [file dirname $tdir]
    }

    # If the directory was not found, insert the directory as a root directory
    if {$found eq ""} {
      set roots  [$widgets(tl) children {}]
      set parent [$widgets(tl) insert "" end -text [file tail $dir] -values [list $dir 0 $opts(-remote)] -open 0 -tags [list d $dir,$opts(-remote)]]

    # Otherwise, add missing hierarchy to make directory visible
    } else {
      set parent $found
      foreach tdir [lrange [file split $dir] [llength [file split $tdir]] end] {
        set parent [add_subdirectory $parent $opts(-remote) $tdir]
      }
    }

    # Show the directory's contents (if they are not already displayed)
    if {[$widgets(tl) item $parent -open] == 0} {
      add_subdirectory $parent $opts(-remote)
    }

    # If we just inserted a root directory, check for other rooted directories
    # that may be children of this directory and merge them.
    if {$found eq ""} {

      # Remove any rooted directories that exist within this directory
      set dirlen [string length $dir]
      set ocount [$widgets(tl) set $parent ocount]
      foreach root $roots {
        set remote [$widgets(tl) set $root remote]
        set name   [$widgets(tl) set $root name]
        if {($remote eq $opts(-remote)) && ([string compare -length $dirlen $name $dir] == 0)} {
          $widgets(tl) detach $root
          set row   [add_directory $name -remote $remote -record 0]
          set prow  [$widgets(tl) parent $row]
          set index [$widgets(tl) index $row]
          $widgets(tl) delete $row
          $widgets(tl) move $root $prow $index
          incr ocount [$widgets(tl) set $root ocount]
        }
      }

      # Set the ocount
      $widgets(tl) set $parent ocount $ocount

    }

    # Make sure that the directory is visible
    set row $parent
    while {$row ne ""} {
      $widgets(tl) item $row -open 1
      set row [$widgets(tl) parent $row]
    }

    return $parent

  }

  ######################################################################
  # Recursively adds the current directory and all subdirectories and files
  # found within it to the sidebar.
  proc add_subdirectory {parent remote {fdir ""}} {

    variable widgets

    set frow ""

    # Clean the subdirectory
    $widgets(tl) delete [$widgets(tl) children $parent]

    # Get the folder contents and sort them
    foreach name [order_files_dirs [$widgets(tl) set $parent name] $remote] {

      lassign $name fname dir

      if {$dir} {
        set child [$widgets(tl) insert $parent end -text [file tail $fname] -values [list $fname 0 $remote] -open 0 -tags [list d $fname,$remote]]
        if {[file tail $fname] eq $fdir} {
          set frow $child
        }
      } else {
        if {($remote ne "") || ![ignore_file $fname]} {
          set key [$widgets(tl) insert $parent end -text [file tail $fname] -values [list $fname 0 $remote] -open 1 -tags [list f $fname,$remote]]
          if {[files::is_opened $fname $remote]} {
            set_image $key sidebar_open
            update_root_count $key 1
          }
        }
      }

    }

    return $frow

  }

  ######################################################################
  # Figure out if the given file should be ignored.
  proc ignore_file {fname {ignore_if_binary 0}} {

    # Ignore the file if it matches any of the ignore patterns
    foreach pattern [preferences::get Sidebar/IgnoreFilePatterns] {
      if {[string match $pattern $fname]} {
        return 1
      }
    }

    # If the file is a binary file, ignore it
    if {($ignore_if_binary || [preferences::get Sidebar/IgnoreBinaries]) && [utils::is_binary $fname]} {
      return 1
    }

    return 0

  }

  ######################################################################
  # Gathers the given directory's contents and handles directory/file
  # ordering issues.
  proc order_files_dirs {dir remote} {

    set items [list]

    if {$remote ne ""} {
      remote::dir_contents $remote $dir items
    } else {
      foreach fname [glob -nocomplain -directory $dir *] {
        lappend items [list $fname [file isdirectory $fname]]
      }
    }

    if {[preferences::get Sidebar/FoldersAtTop]} {
      return [list {*}[lsort -unique -index 0 [lsearch -inline -all -index 1 $items 1]] {*}[lsort -unique -index 0 [lsearch -inline -all -index 1 $items 0]]]
    } else {
      return [lsort -unique -index 0 $items]
    }

  }

  ######################################################################
  # Recursively updates the given directory (if the child directories
  # are already expanded.
  proc update_directory_recursively {parent} {

    variable widgets

    # If the parent is not root, update the directory
    if {$parent ne ""} {
      update_directory $parent
    }

    # Update the child directories that are expanded
    foreach child [$widgets(tl) children $parent] {
      if {[$widgets(tl) item $child -open]} {
        update_directory_recursively $child
      }
    }

  }

  ######################################################################
  # Update the given directory to include (or uninclude) new file
  # information.
  proc update_directory {parent} {

    variable widgets

    # Get the remote indicator of the parent
    set remote [$widgets(tl) set $parent remote]

    # Get the list of opened subdirectories
    set opened [list]
    foreach child [$widgets(tl) children $parent] {
      if {[$widgets(tl) item $child -open]} {
        lappend opened $child [$widgets(tl) set $child name]
        $widgets(tl) detach $child
      }
    }

    # Update the parent directory contents
    add_subdirectory $parent $remote

    # Replace any exist directories in the update directory with the opened
    foreach {item dname} $opened {
      if {[set old_item [$widgets(tl) tag has $dname,$remote]] ne ""} {
        $widgets(tl) move $item $parent [$widgets(tl) index $old_item]
        $widgets(tl) delete $old_item
      }
    }

  }

  ######################################################################
  # Finds the root directory of the given descendent and updates its
  # value +/- the value.
  proc update_root_count {descendant value} {

    variable widgets

    # Get the root directory in the table
    while {[set parent [$widgets(tl) parent $descendant]] ne ""} {
      set descendant $parent
    }

    # Increment/decrement the descendant row by the given value
    set ocount [expr [$widgets(tl) set $descendant ocount] + $value]
    $widgets(tl) set $descendant ocount $ocount

    # If the user wants us to auto-remove when the open file count reaches 0,
    # remove it from the sidebar
    if {[preferences::get Sidebar/RemoveRootAfterLastClose] && ($ocount == 0)} {
      $widgets(tl) delete $descendant
    }

  }

  ######################################################################
  # Expands the currently selected directory.
  proc expand_directory {{row ""}} {

    variable widgets

    if {$row eq ""} {
      set row [$widgets(tl) focus]
    }

    # Add the missing subdirectory
    add_subdirectory $row [$widgets(tl) set $row remote]

    # Make sure that the row is opened
    $widgets(tl) item $row -open 1

  }

  ######################################################################
  # Called when a row is collapsed in the table.
  proc collapse {} {

    variable widgets

    # Get the row
    set row [$widgets(tl) focus]

    # If the row contains a file, make sure that the state remains open
    if {[$widgets(tl) tag has f $row]} {
      $widgets(tl) item $row -open 1
    }

  }

  ######################################################################
  # Inserts the given file into the sidebar under the given parent.
  proc insert_file {parent fname remote} {

    variable widgets

    # Check to see if the file is an ignored file
    if {![ignore_file $fname]} {

      # Compare the children of the parent to the given fname
      set i 0
      foreach child [$widgets(tl) children $parent] {
        if {[$widgets(tl) tag has f $child]} {
          set compare [string compare $fname [$widgets(tl) set $child name]]
          if {$compare == 0} {
            set_image $child sidebar_open
            update_root_count $child 1
            return
          } elseif {$compare == -1} {
            set node [$widgets(tl) insert $parent $i -text [file tail $fname] -image sidebar_open -open 1 -values [list $fname 0 $remote] -tags [list f $fname,$remote]]
            update_root_count $node 1
            return
          }
        }
        incr i
      }

      # Insert the file at the end of the parent
      set node [$widgets(tl) insert $parent end -text [file tail $fname] -image sidebar_open -open 1 -values [list $fname 0 $remote] -tags [list f $fname,$remote]]
      update_root_count $node 1

    }

  }

  ######################################################################
  # Displays a tooltip for each root row.
  proc show_tooltip {row} {

    variable widgets

    if {($row ne "") && ([$widgets(tl) parent $row] eq "")} {
      set dirname [$widgets(tl) set $row name]
      if {[set remote [$widgets(tl) set $row remote]] ne ""} {
        tooltip::tooltip $widgets(tl) "$dirname ([lindex [split $remote ,] 1])"
      } else {
        tooltip::tooltip $widgets(tl) $dirname
      }
      event generate $widgets(tl) <Enter>
    } else {
      tooltip::tooltip clear
    }

  }

  ######################################################################
  # Displays the thumbnail for the given row, if possible.
  proc show_thumbnail {row x y} {

    # OBSOLETE - We are disabling this functionality
    return

    variable widgets

    if {$row ne ""} {
      set x [expr [winfo rootx $widgets(tl)] + [winfo width $widgets(tl)]]
      set y [expr [winfo rooty $widgets(tl)] + $y]
      thumbnail::show [$widgets(tl) set $row name] $x $y
    } else {
      thumbnail::hide
    }

  }

  ######################################################################
  # Hides the tooltip associated with the root row.
  proc hide_tooltip {} {

    tooltip::tooltip clear

  }

  ######################################################################
  # Handle a selection change to the sidebar.
  proc handle_selection {} {

    variable widgets
    variable selection_anchor

    # Clear the selection
    $widgets(tl) tag remove sel

    # Get the current selection
    if {[llength [set selected [$widgets(tl) selection]]]} {

      # If we have only one thing selected, set the selection anchor to be it
      if {[llength $selected] == 1} {
        set selection_anchor [lindex $selected 0]
      }

      # Make sure that all of the selections matches the same type (root, dir, file)
      set anchor_type [row_type $selection_anchor]
      foreach row $selected {
        if {[row_type $row] ne $anchor_type} {
          $widgets(tl) selection remove $row
        }
      }

      # Colorize the selected items to be selected
      $widgets(tl) tag add sel [$widgets(tl) selection]

      # Update the file information panel
      update_file_info $selected

    }

  }

  ######################################################################
  # Handles a left-click on the sidebar.
  proc handle_left_click {W x y} {

    variable widgets

    if {[set row [$widgets(tl) identify item $x $y]] eq ""} {
      return
    }

    # If the file is currently in the notebook, make it the current tab
    if {([llength $row] == 1) && ([$widgets(tl) item $row -image] ne "")} {
      set fileindex [files::get_index [$widgets(tl) set $row name] [$widgets(tl) set $row remote]]
      gui::get_info $fileindex fileindex tabbar tab
      gui::set_current_tab $tabbar $tab
    }

  }

  ######################################################################
  # Handles right click from the sidebar table.
  proc handle_right_click {W x y} {

    variable widgets
    variable selection_anchor

    # If nothing is currently selected, select the row under the cursor
    if {[llength [$widgets(tl) selection]] == 0} {

      if {[set row [$widgets(tl) identify item $x $y]] eq ""} {
        return
      }

      # Set the selection to the right-clicked element
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

    if {[set row [$widgets(tl) identify item $x $y]] eq ""} {
      return
    }

    if {[$widgets(tl) tag has f $row]} {

      # Select the file
      $widgets(tl) selection set $row

      # Open the file in the viewer
      gui::add_file end [$widgets(tl) set $row name] -remote [$widgets(tl) set $row remote]

    }

  }

  ######################################################################
  # Handles a press of the return key when the sidebar has the focus.
  proc handle_return_space {W} {

    variable widgets

    # Get the currently selected rows
    foreach row [$widgets(tl) selection] {

      # Open the file in the viewer
      if {[$widgets(tl) tag has f $row]} {
        gui::add_file end [$widgets(tl) set $row name] -remote [$widgets(tl) set $row remote]

      # Otherwise, toggle the open status
      } else {
        if {[$widgets(tl) item $row -open]} {
          $widgets(tl) item $row -open 0
        } else {
          expand_directory $row
        }
      }

    }

  }

  ######################################################################
  # Handles mouse motion in the sidebar, displaying tooltips over the
  # root directories to display the full pathname (and possibly remote
  # information as well).
  proc handle_motion {W x y} {

    variable widgets
    variable last_id
    variable after_id

    set id      [$W identify row $x $y]
    set lastId  $last_id
    set last_id $id

    if {$id ne $lastId} {
      after cancel $after_id
      if {$lastId ne ""} {
        hide_tooltip
        thumbnail::hide
      }
      if {$id ne ""} {
        set after_id [after 300 sidebar::show_tooltip $id; sidebar::show_thumbnail $id $x $y]
      }
    }

  }

  ######################################################################
  # Handles any key binding which is used for search purposes within the
  # sidebar.
  proc handle_any {keysym char} {

    variable widgets
    variable jump_str
    variable jump_after_id

    if {[string is control $char] || ([set selected [lindex [$widgets(tl) selection] 0]] eq "")} {
      return
    }

    # Stop the jump string from being cleared
    if {$jump_after_id ne ""} {
      after cancel $jump_after_id
      set jump_after_id ""
    }

    # Add to the jump string
    append jump_str $char

    # Get the parent directory to search
    set parent [expr {([get_info $selected is_dir] && [$widgets(tl) item $selected -open]) ? $selected : [$widgets(tl) parent $selected]}]

    # Perform the search within the table
    foreach row [$widgets(tl) children $parent] {
      if {[string match -nocase $jump_str* [string trim [$widgets(tl) item $row -text]]]} {
        $widgets(tl) focus $row
        $widgets(tl) selection set $row
        $widgets(tl) see $row
        break
      }
    }

    # Clear the jump string after a given amount of time
    set jump_after_id [after [preferences::get Sidebar/KeySearchTimeout] {
      set sidebar::jump_str      ""
      set sidebar::jump_after_id ""
    }]

  }

  ######################################################################
  # Handles the sidebar gaining focus.
  proc handle_focus_in {} {

    variable widgets
    variable show_file_info

    set selected [$widgets(tl) selection]

    if {$show_file_info && ([llength $selected] == 1) && [file isfile [$widgets(tl) set [lindex $selected 0] name]]} {
      pack $widgets(info,f) -fill both
    }

  }

  ######################################################################
  # Handles the sidebar losing focus.
  proc handle_focus_out {} {

    variable widgets

    if {![preferences::get View/KeepFileInfoVisible]} {
      pack forget $widgets(info,f)
    }

  }

  ######################################################################
  # Copies the given row's file/folder pathname to the clipboard.
  proc copy_pathname {row} {

    variable widgets

    # Set the clipboard to the currentl selection
    clipboard clear
    clipboard append [$widgets(tl) set $row name]

    # Add the clipboard contents to history
    cliphist::add_from_clipboard

  }

  ######################################################################
  # Adds a new file to the given folder.
  proc add_file_to_folder {row args} {

    variable widgets

    array set opts {
      -testname ""
    }
    array set opts $args

    if {$opts(-testname) eq ""} {

      # Get the new filename from the user
      set fname ""
      if {![gui::get_user_response [msgcat::mc "File Name:"] fname -allow_vars 1]} {
        return
      }

    } else {
      set fname $opts(-testname)
    }

    # Normalize the pathname
    if {[file pathtype $fname] eq "relative"} {
      set fname [file join [$widgets(tl) set $row name] $fname]
    }

    # Get the remote status
    set remote [$widgets(tl) set $row remote]

    # Create the file
    if {$remote eq ""} {
      if {[catch { open $fname w } rc]} {
        return
      }
      close $rc
    } else {
      if {![remote::save_file $remote $fname " " modtime]} {
        return
      }
    }

    # Expand the directory
    expand_directory $row

    # Create an empty file
    gui::add_file end $fname -remote $remote

  }

  ######################################################################
  # Prompts the user for a name which will be placed in the selected
  # directory, then prompts the user to select a template, and finally
  # inserts the file into the editing buffer and performs any snippet
  # transformations.
  proc add_file_from_template {row} {

    variable widgets

    # Add the file
    if {![catch { templates::show_templates load_rel [$widgets(tl) set $row name] -remote [$widgets(tl) set $row remote] }]} {

      # Expand the directory
      expand_directory $row

    }

  }

  ######################################################################
  # Adds a new folder to the specified folder.
  proc add_folder_to_folder {row args} {

    variable widgets

    array set opts {
      -testname ""
    }
    array set opts $args

    if {$opts(-testname) eq ""} {

      # Get the directory name from the user
      set dname ""
      if {![gui::get_user_response [msgcat::mc "Directory Name:"] dname -allow_vars 1]} {
        return
      }

    } else {
      set dname $opts(-testname)
    }

    # Normalize the pathname
    if {[file pathtype $dname] eq "relative"} {
      set dname [file join [$widgets(tl) set $row name] $dname]
    }

    # Get the remote status
    set remote [$widgets(tl) set $row remote]

    # Create the directory
    if {$remote eq ""} {
      if {[catch { file mkdir $dname }]} {
        return
      }
    } else {
      if {![remote::make_directory $remote $dname]} {
        return
      }
    }

    # Expand the directory
    expand_directory $row

    # Update the directory
    update_directory $row

  }

  ######################################################################
  # Opens all of the files in the current directory.
  proc open_folder_files {rows} {

    variable widgets

    set tab ""

    foreach row $rows {

      # Open all of the children that are not already opened
      foreach child [$widgets(tl) children $row] {
        set name [$widgets(tl) set $child name]
        if {([$widgets(tl) item $child -image] eq "") && [$widgets(tl) tag has f $child]} {
          set tab [gui::add_file end $name -lazy 1 -remote [$widgets(tl) set $child remote]]
        }
      }

    }

    # Display the current tab
    if {$tab ne ""} {
      gui::set_current_tab [gui::get_info $tab tab tabbar] $tab
    }

  }

  ######################################################################
  # Close all of the open files in the current directory.
  proc close_folder_files {rows} {

    variable widgets

    set indices [list]

    # Gather all of the opened file names
    foreach row $rows {
      foreach child [$widgets(tl) children $row] {
        if {[$widgets(tl) item $child -image] ne ""} {
          lappend indices [files::get_index [$widgets(tl) set $child name] [$widgets(tl) set $child remote]]
        }
      }
    }

    # Close all of the files
    gui::close_files $indices

  }

  ######################################################################
  # Closes any opened files within a directory, disconnects from the
  # server and removes the directory from the sidebar.
  proc disconnect {rows} {

    variable widgets

    foreach row $rows {
      if {[set remote [$widgets(tl) set $row remote]] ne ""} {
        close_folder_files $row
        remote::disconnect $remote
        $widgets(tl) delete $row
      }
    }

  }

  ######################################################################
  # Disconnects by remote name.
  proc disconnect_by_name {remote} {

    variable widgets

    foreach child [$widgets(tl) children ""] {
      if {[$widgets(tl) set $child remote] eq $remote} {
        disconnect $child
        return
      }
    }

  }

  ######################################################################
  # Hide all of the open files in the current directory.
  proc hide_folder_files {rows} {

    variable widgets

    set indices [list]

    # Gather all of the opened file names
    foreach row $rows {
      foreach child [$widgets(tl) children $row] {
        if {[$widgets(tl) item $child -image] ne ""} {
          lappend indices [files::get_index [$widgets(tl) set $child name] [$widgets(tl) set $child remote]]
        }
      }
    }

    # Hide all of the files
    gui::hide_files $indices

  }

  ######################################################################
  # Show all of the open files in the current directory.
  proc show_folder_files {rows} {

    variable widgets

    set indices [list]

    # Gather all of the opened file names
    foreach row $rows {
      foreach child [$widgets(tl) children $row] {
        if {[$widgets(tl) item $child -image] ne ""} {
          lappend indices [files::get_index [$widgets(tl) set $child name] [$widgets(tl) set $child remote]]
        }
      }
    }

    # Show all of the files
    gui::show_files $indices

  }

  ######################################################################
  # Allows the user to rename the currently selected folder.
  proc rename_folder {row args} {

    variable widgets

    array set opts {
      -testname ""
    }
    array set opts $args

    # Get the current name
    set old_dname [set dname [$widgets(tl) set $row name]]

    # Get the new name from the user
    if {($opts(-testname) ne "") || [gui::get_user_response [msgcat::mc "Folder Name:"] dname -allow_vars 1 -selrange {0 end}]} {

      # Make the fname match the testname option if it was set
      if {$opts(-testname) ne ""} {
        set dname $opts(-testname)
      }

      # If the value of the cell hasn't changed or is empty, do nothing else.
      if {($old_dname eq $dname) || ($dname eq "")} {
        return
      }

      # Get the remote status
      set remote [$widgets(tl) set $row remote]

      # Rename the folder
      set dname [files::rename_folder $old_dname $dname $remote]

      # Delete the old directory
      $widgets(tl) delete $row

      # Add the file directory
      update_directory [add_directory $dname -remote $remote]

    }

  }

  ######################################################################
  # Allows the user to delete the folder at the given row.
  proc delete_folder {rows args} {

    variable widgets

    array set opts {
      -test 0
    }
    array set opts $args

    if {[llength $rows] == 1} {
      set question [msgcat::mc "Delete directory?"]
    } else {
      set question [msgcat::mc "Delete directories?"]
    }

    if {$opts(-test) || ([tk_messageBox -parent . -type yesno -default yes -message $question] eq "yes")} {

      foreach row [lreverse $rows] {

        # Get the directory pathname
        set dirpath [$widgets(tl) set $row name]

        # Get the remote value
        set remote [$widgets(tl) set $row remote]

        # Delete the folder
        files::delete_folder $dirpath $remote

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
    favorites::add [$widgets(tl) set $row name]

  }

  ######################################################################
  # Causes the given folder/file to become a non-favorite.
  proc unfavorite {row} {

    variable widgets

    # Remove the folder from the favorites list
    favorites::remove [$widgets(tl) set $row name]

  }

  ######################################################################
  # Removes the specified folder rows from the sidebar.
  proc remove_folder {rows} {

    variable widgets

    # Delete the row and its children
    $widgets(tl) delete $rows

  }

  ######################################################################
  # Removes the parent(s) of the specified folder from the sidebar.
  proc remove_parent_folder {row} {

    variable widgets

    # Find the child index of the ancestor of the root
    set child $row
    while {[set parent [$widgets(tl) parent $child]] ne ""} {
      set child $parent
    }

    # Move the row to root
    $widgets(tl) move $row "" [$widgets(tl) index $child]

    # Delete the child tree
    $widgets(tl) delete $child

  }

  ######################################################################
  # Sets the currently selected directory to the working directory.
  proc set_current_working_directory {row} {

    variable widgets

    # Set the current working directory to the selected pathname
    cd [$widgets(tl) set $row name]

    # Update the UI
    gui::set_title

  }

  ######################################################################
  # Refreshes the specified directory contents.
  proc refresh_directory_files {rows} {

    variable widgets

    foreach row [lreverse $rows] {
      expand_directory $row
    }

  }

  ######################################################################
  # Adds the parent directory to the sidebar of the currently selected
  # row.
  proc add_parent_directory {row} {

    variable widgets

    # Get the remote value of the selected row
    set dname  [file dirname [$widgets(tl) set $row name]]
    set remote [$widgets(tl) set $row remote]

    # Add the parent directory to the sidebar
    add_directory $dname -remote $remote

  }

  ######################################################################
  # Opens the currently selected file in the notebook.
  proc open_file {rows} {

    variable widgets

    set tab ""

    # Add the files to the notebook
    foreach row $rows {
      set tab [gui::add_file end [$widgets(tl) set $row name] -lazy 1 -remote [$widgets(tl) set $row remote]]
    }

    # Make the last tab visible
    if {$tab ne ""} {
      gui::set_current_tab [gui::get_info $tab tab tabbar] $tab
    }

  }

  ######################################################################
  # Opens the file difference view for the specified file.
  proc show_file_diff {row} {

    variable widgets

    # Add the file to the notebook in difference view
    gui::add_file end [$widgets(tl) set $row name] -diff 1 -other [preferences::get View/ShowDifferenceInOtherPane]

  }

  ######################################################################
  # Closes the specified file in the notebook.
  proc close_file {rows} {

    variable widgets

    set indices [list]

    # Gather all of the opened filenames
    foreach row $rows {
      if {[$widgets(tl) item $row -image] ne ""} {
        lappend indices [files::get_index [$widgets(tl) set $row name] [$widgets(tl) set $row remote]]
      }
    }

    # Close the tab at the current location
    gui::close_files $indices

  }

  ######################################################################
  # Hides the specified files.
  proc hide_file {rows} {

    variable widgets

    set indices [list]

    # Gather all of the opened filenames
    foreach row $rows {
      if {[$widgets(tl) item $row -image] ne ""} {
        lappend indices [files::get_index [$widgets(tl) set $row name] [$widgets(tl) set $row remote]]
      }
    }

    # Hide the tab at the current location
    gui::hide_files $indices

  }

  ######################################################################
  # Shows the files at the given row.
  proc show_file {rows} {

    variable widgets

    set indices [list]

    # Gather all the opened filenames
    foreach row $rows {
      if {[$widgets(tl) item $row -image] ne ""} {
        lappend indices [files::get_index [$widgets(tl) set $row name] [$widgets(tl) set $row remote]]
      }
    }

    # Show the tabs with the given filenames
    gui::show_files $indices

  }

  ######################################################################
  # Allow the user to rename the currently selected file in the file
  # browser.
  proc rename_file {row args} {

    variable widgets

    array set opts {
      -testname ""
    }
    array set opts $args

    # Get the current name
    set old_name [set new_name [$widgets(tl) set $row name]]
    set selrange [utils::basename_range $new_name]

    # Get the remote status
    set remote [$widgets(tl) set $row remote]

    # Get the new name from the user
    if {($opts(-testname) ne "") || [gui::get_user_response [msgcat::mc "File Name:"] new_name -allow_vars 1 -selrange $selrange]} {

      if {$opts(-testname) ne ""} {
        set new_name $opts(-testname)
      }

      # If the value of the cell hasn't changed or is empty, do nothing else.
      if {($old_name eq $new_name) || ($new_name eq "")} {
        return
      }

      if {[catch { files::rename_file $old_name $new_name $remote } new_name]} {
        gui::set_error_message [msgcat::mc "Unable to rename file"] $new_name
        return
      }

      # Add the file directory
      update_directory [add_directory [file dirname $new_name] -remote $remote]

      # Update the old directory, if necessary
      if {[$widgets(tl) exists $row] && ([file dirname $old_name] ne [file dirname $new_name])} {
        update_directory [$widgets(tl) parent $row]
      }

    }

  }

  ######################################################################
  # Creates a duplicate of the specified file, adds it to the
  # sideband and allows the user to modify its name.
  proc duplicate_file {row} {

    variable widgets

    # Get the filename of the current selection
    set fname [$widgets(tl) set $row name]

    # Get the remote indicator
    set remote [$widgets(tl) set $row remote]

    # Create the default name of the duplicate file
    if {[catch { files::duplicate_file $fname $remote } dup_fname]} {
      gui::set_error_message [msgcat::mc "Unable to duplicate file"] $dup_fname
      return
    }

    # Add the file to the sidebar just below the row
    set new_row [$widgets(tl) insert [$widgets(tl) parent $row] [expr [$widgets(tl) index $row] + 1] \
      -text [file tail $dup_fname] -values [list $dup_fname 0 $remote] -open 1 -tags [list f $dup_fname,$remote]]

  }

  ######################################################################
  # Moves the given files/folders to the trash.
  proc move_to_trash {rows} {

    variable widgets

    set status 1
    set fnames [list]
    set isdir  0

    foreach row [lreverse $rows] {

      # Get the full pathname
      set fname [$widgets(tl) set $row name]
      set isdir [file isdirectory $fname]

      # Move the file to the trash
      if {[catch { files::move_to_trash $fname $isdir } rc]} {
        continue
      }

      # Delete the row in the table
      $widgets(tl) delete $row

    }

  }

  ######################################################################
  # Deletes the specified file.
  proc delete_file {rows args} {

    variable widgets

    array set opts {
      -test 0
    }
    array set opts $args

    if {[llength $rows] == 1} {
      set question [msgcat::mc "Delete file?"]
    } else {
      set question [msgcat::mc "Delete files?"]
    }

    # Get confirmation from the user
    if {$opts(-test) || ([tk_messageBox -parent . -type yesno -default yes -message $question] eq "yes")} {

      foreach row [lreverse $rows] {

        # Get the full pathname and remote status
        set fname  [$widgets(tl) set $row name]
        set remote [$widgets(tl) set $row remote]

        # Delete the file
        if {[catch { files::delete_file $fname $remote } rc]} {
          continue
        }

        # Delete the row in the table
        $widgets(tl) delete $row

      }

    }

  }

  ######################################################################
  # Handle any changes to the ignore file patterns/executables preference variables.
  proc handle_ignore_files {name1 name2 op} {

    # Update all of the top-level directories
    update_directory_recursively ""

  }

  ######################################################################
  # Handles the file information view option.
  proc handle_file_info_view {name1 name2 op} {

    set_file_info_view [preferences::get View/ShowFileInfo]

  }

  ######################################################################
  # Sets the file information view value and updates the UI state.
  proc set_file_info_view {value} {

    variable widgets
    variable show_file_info

    # Save the state of the View/ShowFileInfo preference option
    set show_file_info $value

    # Update the file info widget
    update_file_info [$widgets(tl) selection]

  }

  ######################################################################
  # Returns the list of files that are currently visible.
  proc get_shown_files {} {

    variable widgets

    set files [list]

    foreach row [$widgets(tl) tag has f] {
      lappend files [list [$widgets(tl) set $row name] $row]
    }

    return $files

  }

  ######################################################################
  # Returns a list of files specifically for use in the "find in files"
  # function.
  proc get_fif_files {} {

    variable widgets

    set fif_files [list]
    set odirs     [list]
    set ofiles    [list]

    # Gather the lists of files, opened files and opened directories
    foreach row [$widgets(tl) tag has d] {
      if {[$widgets(tl) set $row remote] eq ""} {
        set name [$widgets(tl) set $row name]
        if {[$widgets(tl) item $row -open] || ([$widgets(tl) parent $row] eq "")} {
          lappend odirs $name
        }
        lappend fif_files [list $name $name]
      }
    }
    foreach row [$widgets(tl) tag has f] {
      if {[$widgets(tl) set $row remote] eq ""} {
        set name [$widgets(tl) set $row name]
        if {[$widgets(tl) item $row -image] ne ""} {
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
  # Shows the given filename in the sidebar browser.  Adds parent
  # directory if the file does not exist in the sidebar.
  proc view_file {fname remote} {

    variable widgets

    # Find the item.  If it is not found, add its directory.
    if {[set found [$widgets(tl) tag has $fname,$remote]] eq ""} {
      add_directory [file dirname $fname] -remote $remote
      set found [$widgets(tl) tag has $fname,$remote]
    }

    # Put the file into view
    $widgets(tl) selection set $found
    $widgets(tl) see $found

  }

  ######################################################################
  # If value is set to 1, the sidebar will be transformed into a draggable
  # mode of operation.  If value is set to 0, the sidebar will return to
  # normal mode of operation.
  proc set_draggable {value} {

    variable widgets

    $widgets(tl) configure -customdragsource $value

  }

  ######################################################################
  # Updates the file information panel to match the current selections
  proc update_file_info {selected} {

    variable widgets
    variable show_file_info

    if {([llength $selected] == 1) && $show_file_info} {

      set fname [$widgets(tl) set [lindex $selected 0] name]

      if {[file isfile $fname]} {

        pack $widgets(info,f) -fill both

        # Get the file information
        file stat $fname finfo

        # Get the syntax information
        set syntax [syntax::get_default_language $fname]

        # Get the name and version to display
        set name    [file tail $fname]
        set cvs     [diff::get_default_cvs $fname]
        set version [diff::${cvs}::get_current_version $fname]

        # Figure out if we can display the file based on extension
        if {([file extension $fname] eq ".bmp") && ![catch { image create bitmap -file $fname } orig]} {
          grid $widgets(info,v,image)
          bitmap_preview configure -file $fname -foreground [utils::get_default_foreground]
          update_file_info_image $orig bitmap_preview name syntax
        } elseif {![catch { image create photo -file $fname } orig]} {
          grid $widgets(info,v,image)
          photo_preview blank
          ::image_scale $orig 64 64 photo_preview
          update_file_info_image $orig photo_preview name syntax
        } else {
          grid remove $widgets(info,v,image)
          if {[utils::is_binary $fname]} {
            set syntax "Binary"
          }
        }

        $widgets(info,v,name) configure -text $name
        $widgets(info,v,type) configure -text "$syntax - [utils::get_file_size $fname]"
        $widgets(info,v,ver)  configure -text $version
        $widgets(info,v,mod)  configure -text [clock format $finfo(mtime)]

        # Remove the version entry if it is not valid
        if {$version eq ""} {
          grid remove $widgets(info,l,ver) $widgets(info,v,ver)
        } else {
          grid $widgets(info,l,ver) $widgets(info,v,ver)
        }

        # Insert plugin values
        foreach {index value} [plugins::handle_file_info_values $fname] {
          $widgets(info,v,plug$index) configure -text $value
          if {$value eq ""} {
            grid remove $widgets(info,l,plug$index) $widgets(info,v,plug$index)
          } else {
            grid $widgets(info,l,plug$index) $widgets(info,v,plug$index)
          }
        }

        # Make sure that the sidebar item can be seen
        $widgets(tl) see $selected

      } else {

        pack forget $widgets(info,f)

      }

    } else {

      pack forget $widgets(info,f)

    }

  }

  ######################################################################
  # Updates the file information image and related information.
  proc update_file_info_image {orig image pname psyntax} {

    variable widgets

    upvar $pname   name
    upvar $psyntax syntax

    # Update the image
    $widgets(info,v,image) configure -image $image

    # Calculate the syntax and name values
    set syntax "Unsupported"
    append name " ([image width $orig] x [image height $orig])"

    # Delete the original image
    image delete $orig

  }

  ######################################################################
  # Update the information panel widgets with the given theme information.
  proc update_theme {title_fgcolor value_fgcolor bgcolor default_bgcolor} {

    variable widgets

    # Colorize the frame widgets
    foreach w [array names widgets info,f*] {
      $widgets($w) configure -background $bgcolor
    }

    # Colorize the title labels
    foreach w [array names widgets info,l,*] {
      $widgets($w) configure -foreground $title_fgcolor -background $bgcolor
    }

    # Colorize the value labels
    foreach w [array names widgets info,v,*] {
      $widgets($w) configure -foreground $value_fgcolor -background $bgcolor
    }

    # If the background color of the information frame does not match the default
    # background color, remove the final separator to cleanup the UI appearance;
    # otherwise, make sure that it is there.
    if {$bgcolor ne $default_bgcolor} {
      grid remove $widgets(psep)
    } else {
      grid $widgets(psep)
    }

  }

}
