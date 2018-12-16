# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
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
  variable select_id        ""
  variable sortby           "name"
  variable sortdir          "-increasing"
  variable spring_id        ""
  variable tkdnd_id         ""
  variable tkdnd_drag       0
  variable state            "normal"
  variable ipanel_id        ""

  array set widgets {}
  array set scan_id {
    up ""
    down ""
  }

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
  # Returns the current width of the sidebar.
  proc get_width {} {

    variable widgets

    return [expr [$widgets(tl) column #0 -width] - 4]

  }

  ######################################################################
  # Sets the state of the sidebar to the given value.  The legal values
  # are:  normal, disabled, viewonly.
  proc set_state {value} {

    variable widgets
    variable state

    switch $state {
      normal   -
      viewonly { $widgets(tl) state !disabled }
      disabled { $widgets(tl) state  disabled }
      default {
        return -code error "Attempting to set sidebar state to an unsupported value ($value)"
      }
    }

    set state $value

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

    theme::register_image sidebar_info_close bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar information panel for closing the panel"} \
      -file [file join $::tke_dir lib images close.bmp] \
      -maskfile [file join $::tke_dir lib images close.bmp] \
      -foreground 1

    theme::register_image sidebar_info_refresh bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar information panel for refreshing content"} \
      -file [file join $::tke_dir lib images refresh.bmp] \
      -maskfile [file join $::tke_dir lib images refresh.bmp] \
      -foreground 1

    theme::register_image sidebar_info_show bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar information panel for showing file in sidebar"} \
      -file [file join $::tke_dir lib images show.bmp] \
      -maskfile [file join $::tke_dir lib images show.bmp] \
      -foreground 1

    set fg [utils::get_default_foreground]
    set bg [utils::get_default_background]

    frame $w

    # Create the top-level frame
    set widgets(frame) [frame $w.tf -highlightthickness 1 -highlightbackground $bg -highlightcolor $bg]

    # Add the file tree elements
    ttk::frame $w.tf.tf -style SBFrame -padding {3 3 0 0}
    pack [set widgets(tl) \
      [ttk::treeview $w.tf.tf.tl -style SBTreeview -columns {name remote sortby} -displaycolumns {} \
        -show tree -yscrollcommand "utils::set_yscrollbar $w.tf.vb"]] -fill both -expand yes
    set widgets(sb)     [scroller::scroller $w.tf.vb -orient vertical -foreground $fg -background $bg -command [list $widgets(tl) yview]]
    set widgets(insert) [frame $widgets(tl).ins -background black -height 2]

    $widgets(tl) column #0 -width [preferences::get Sidebar/DefaultWidth] -minwidth 100

    set tkdnd_press_cmd  ""
    set tkdnd_motion_cmd ""

    # Make ourselves a drop target (if Tkdnd is available)
    catch {

      # Register ourselves as a drop target
      tkdnd::drop_target register $widgets(tl) DND_Files

      bind $widgets(tl) <<DropEnter>>    [list sidebar::handle_drop_enter_or_pos %W %X %Y %a %b]
      bind $widgets(tl) <<DropPosition>> [list sidebar::handle_drop_enter_or_pos %W %X %Y %a %b]
      bind $widgets(tl) <<DropLeave>>    [list sidebar::handle_drop_leave %W]
      bind $widgets(tl) <<Drop>>         [list sidebar::handle_drop %W %A %D]

      # Register ourselves as a drag source
      tkdnd::drag_source register $widgets(tl) DND_Files

      bind $widgets(tl) <<DragInitCmd>> [list sidebar::handle_drag_init %W]
      bind $widgets(tl) <<DragEndCmd>>  [list sidebar::handle_drag_end %W %A]

      # We need to handle some things differently since we do file moves in the sidebar
      set tkdnd_press_cmd  [bind TkDND_Drag1 <ButtonPress-1>]
      set tkdnd_motion_cmd [bind TkDND_Drag1 <B1-Motion>]

      # Remove the TkDND_Drag1 binding from the sidebar bindtags
      set index [lsearch [bindtags $widgets(tl)] TkDND_Drag1]
      bindtags $widgets(tl) [lreplace [bindtags $widgets(tl)] $index $index]

    }

    bind $widgets(tl) <<TreeviewSelect>>              [list sidebar::handle_selection]
    bind $widgets(tl) <<TreeviewOpen>>                [list sidebar::expand_directory]
    bind $widgets(tl) <<TreeviewClose>>               [list sidebar::collapse_directory]
    bind $widgets(tl) <ButtonPress-1>                 "if {\[sidebar::handle_left_press %W %x %y [list $tkdnd_press_cmd]\]} break"
    bind $widgets(tl) <ButtonRelease-1>               [list sidebar::handle_left_release %W %x %y]
    bind $widgets(tl) <Control-Button-1>              "sidebar::handle_control_left_click %W %x %y; break"
    bind $widgets(tl) <Control-Button-$::right_click> [list sidebar::handle_control_right_click %W %x %y]
    bind $widgets(tl) <Shift-ButtonPress-1>           [list sidebar::do_nothing]
    bind $widgets(tl) <Shift-ButtonRelease-1>         [list sidebar::do_nothing]
    bind $widgets(tl) <Button-$::right_click>         [list sidebar::handle_right_click %W %x %y]
    bind $widgets(tl) <Double-Button-1>               [list sidebar::handle_double_click %W %x %y]
    bind $widgets(tl) <Motion>                        [list sidebar::handle_motion %W %x %y]
    bind $widgets(tl) <B1-Motion>                     [list sidebar::handle_b1_motion %W %x %y $tkdnd_motion_cmd]
    bind $widgets(tl) <Control-Return>                [list sidebar::handle_control_return_space %W]
    bind $widgets(tl) <Control-Key-space>             [list sidebar::handle_control_return_space %W]
    bind $widgets(tl) <Escape>                        [list sidebar::handle_escape %W]
    bind $widgets(tl) <Return> {
      sidebar::handle_return_space %W
      break
    }
    bind $widgets(tl) <Key-space> {
      sidebar::handle_return_space %W
      break
    }
    bind $widgets(tl) <BackSpace> {
      sidebar::handle_backspace %W
      break
    }
    bind $widgets(tl) <Key>      [list sidebar::handle_any %K %A]
    bind $widgets(tl) <FocusIn>  [list sidebar::handle_focus_in]
    bind $widgets(tl) <FocusOut> [list sidebar::handle_focus_out]

    grid rowconfigure    $w.tf 0 -weight 1
    grid columnconfigure $w.tf 0 -weight 1
    grid $w.tf.tf -row 0 -column 0 -sticky news
    grid $w.tf.vb -row 0 -column 1 -sticky ns

    pack $w.tf -fill both -expand yes

    # Create sidebar info panel user interface
    set widgets(info)       [frame $w.if]
    set widgets(info,psep1) [ttk::separator $w.if.psep1]
    set widgets(info,panel) [ipanel::create $w.if.panel -closecmd sidebar::close_info_panel -showcmd sidebar::view_file]
    set widgets(info,psep2) [ttk::separator $w.if.psep2]

    bind $widgets(info,panel) <<ThemeChange>> [list sidebar::panel_theme_change %d]

    grid rowconfigure $widgets(info)    1 -weight 1
    grid columnconfigure $widgets(info) 0 -weight 1
    grid $widgets(info,psep1) -row 0 -column 0 -sticky ew
    grid $widgets(info,panel) -row 1 -column 0 -sticky news
    grid $widgets(info,psep2) -row 2 -column 0 -sticky ew

    # Create directory popup
    set widgets(menu)     [menu $w.popupMenu            -tearoff 0 -postcommand "sidebar::menu_post"]
    set widgets(sortmenu) [menu $w.popupMenu.sortbyMenu -tearoff 0 -postcommand "sidebar::sort_menu_post"]

    # Setup the sort menu
    setup_sort_menu

    # Register the sidebar and sidebar scrollbar for theming purposes
    theme::register_widget $widgets(tl)       sidebar
    theme::register_widget $widgets(sb)       sidebar_scrollbar
    theme::register_widget $widgets(menu)     menus
    theme::register_widget $widgets(sortmenu) menus

    # Handle traces
    trace variable preferences::prefs(Sidebar/IgnoreFilePatterns)  w sidebar::handle_ignore_files
    trace variable preferences::prefs(Sidebar/IgnoreBinaries)      w sidebar::handle_ignore_files
    trace variable preferences::prefs(Sidebar/InfoPanelAttributes) w sidebar::handle_info_panel_view
    trace variable preferences::prefs(Sidebar/InfoPanelFollowsSelection) w sidebar::handle_info_panel_follows

    return $w

  }

  ######################################################################
  # Does just what the name suggests.  Used by sidebar bindings.
  proc do_nothing {} {}

  ######################################################################
  # Called when the panel theme changes.  Takes care to show/hide the
  # information panel divider widgets based on colors.
  proc panel_theme_change {panel_color} {

    variable widgets

    array set ttk_opts     [theme::get_category_options ttk_style 1]
    array set sidebar_opts [theme::get_category_options sidebar   1]

    if {$panel_color eq $sidebar_opts(-background)} {
      grid $widgets(info,psep1)
    } else {
      grid remove $widgets(info,psep1)
    }

    if {$panel_color eq $ttk_opts(background)} {
      grid $widgets(info,psep2)
    } else {
      grid remove $widgets(info,psep2)
    }

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

    variable tkdnd_drag

    # If we are dragging from ourselves, don't change the highlight color
    if {$tkdnd_drag} {
      return "refuse_drop"
    }

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

    variable tkdnd_drag
    variable state

    # If we are dragging to ourselves, do nothing
    if {$tkdnd_drag} {
      set tkdnd_drag 0
      return
    }

    foreach fname $files {
      if {[file isdirectory $fname]} {
        add_directory $fname
      } elseif {($state eq "normal") && ![::check_file_for_import $fname]} {
        gui::add_file end $fname
      }
    }

    handle_drop_leave $tbl

    return "link"

  }

  ######################################################################
  # Perform the TkDND button-1 press event.
  proc tkdnd_press {cmd args} {

    variable tkdnd_id

    set tkdnd_id [after 1000 [list sidebar::tkdnd_call_press $cmd {*}$args]]

  }

  ######################################################################
  # Call the tkdnd press command.
  proc tkdnd_call_press {cmd args} {

    variable widgets

    set sel_fg [$widgets(tl) tag configure sel    -foreground]
    set sel_bg [$widgets(tl) tag configure sel    -background]
    set fg     [$widgets(tl) tag configure moveto -foreground]
    set bg     [$widgets(tl) tag configure moveto -background]

    # Blink the selection so the user knows when we can drag the selection
    $widgets(tl) tag configure sel -foreground $fg -background $bg

    after 100 [list sidebar::tkdnd_call_press2 $cmd $args $sel_fg $sel_bg]

  }

  ######################################################################
  # Call the tkdnd press command.
  proc tkdnd_call_press2 {cmd opts fg bg} {

    variable widgets
    variable tkdnd_id
    variable tkdnd_drag

    # Clear the ID
    set tkdnd_id   ""
    set tkdnd_drag 1

    $widgets(tl) tag configure sel -foreground $fg -background $bg

    # Execute the command
    uplevel #0 [list $cmd {*}$opts]

  }

  ######################################################################
  # Perform the TkDND button-1 motion event.
  proc tkdnd_motion {cmd args} {

    variable tkdnd_id

    # Cancel the button press event
    if {$tkdnd_id ne ""} {
      after cancel $tkdnd_id
      set tkdnd_id ""
    }

    # Execute the TkDND command
    uplevel #0 [list $cmd {*}$args]

  }

  ######################################################################
  # Perform the TkDND button-1 release.
  proc tkdnd_release {} {

    variable tkdnd_id

    # Cancel the button press event
    if {$tkdnd_id ne ""} {
      after cancel $tkdnd_id
      set tkdnd_id ""
    }

  }

  ######################################################################
  # Called when the user attempts to drag items from the sidebar.
  proc handle_drag_init {w} {

    # Figure out the file that the user has
    set files [list]
    foreach item [$w selection] {
      if {[$w set $item remote] eq ""} {
        lappend files [$w set $item name]
      }
    }

    return [list {copy move link} DND_Files $files]

  }

  ######################################################################
  # Handle the end of drag event, if the action was a move event, update
  # the sidebar state.
  proc handle_drag_end {w action} {

    variable tkdnd_drag

    # End the sidebar drag/drop tracking
    set tkdnd_drag 0

    # Update the directories containing the selected files
    foreach item [$w selection] {
      set dirs([file dirname [$w set $item name]]) [$w parent $item]
    }

    # Reload the unique directories
    foreach {dir item} [array get dirs] {
      expand_directory $item
    }

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
  # Returns a value of 1 if row1 is found before row2 in the treeview;
  # otherwise, returns a value of 0.
  proc row_before {row1 row2} {

    variable widgets

    return [row_before_helper $widgets(tl) $row1 $row2 {}]

  }

  ######################################################################
  # Helper procedure for the row_before procedure.
  proc row_before_helper {tl row1 row2 item} {

    if {$item eq $row1} { return 1 }
    if {$item eq $row2} { return 0 }

    foreach child [$tl children $item] {
      if {[set status [row_before_helper $tl $row1 $row2 $child]] != -1} {
        return $status
      }
    }

    return -1

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
  # Handles the contents of the sort popup menu prior to it being posted.
  proc sort_menu_post {} {

    variable widgets
    variable selection_anchor
    variable sortby
    variable sortdir

    if {[set sortby [$widgets(tl) set $selection_anchor sortby]] eq "manual"} {
      $widgets(sortmenu) entryconfigure [msgcat::mc "Increasing"] -state disabled
      $widgets(sortmenu) entryconfigure [msgcat::mc "Decreasing"] -state disabled
    } else {
      lassign [split $sortby :] sortby sortdir
      $widgets(sortmenu) entryconfigure [msgcat::mc "Increasing"] -state normal
      $widgets(sortmenu) entryconfigure [msgcat::mc "Decreasing"] -state normal
    }

  }

  ######################################################################
  # Return a list of menu states to use for directories.  The returned
  # list is:  <open_state> <close_state> <hide_state> <show_state>
  proc get_menu_states {rows} {

    variable widgets
    variable state

    set opened "disabled"
    set closed "disabled"
    set hide   "disabled"
    set show   "disabled"

    if {$state eq "normal"} {
      foreach row $rows {
        foreach child [$widgets(tl) children $row] {
          switch [$widgets(tl) item $child -image] {
            "sidebar_hidden" { set closed "normal"; set show "normal" }
            "sidebar_open"   { set closed "normal"; set hide "normal" }
            default          { set opened "normal" }
          }
        }
      }
    }

    return [list $opened $closed $hide $show]

  }

  ######################################################################
  # Sets up the popup menu to be suitable for the given directory.
  proc setup_dir_menu {rows} {

    variable widgets
    variable state

    set one_state     [expr {([llength $rows] == 1) ? "normal" : "disabled"}]
    set one_act_state [expr {($state eq "normal") ? $one_state : "disabled"}]
    set act_state     [expr {($state eq "normal") ? "normal" : "disabled"}]
    set fav_state     $one_act_state
    set sort_state    $one_act_state
    set first_row     [lindex $rows 0]
    set remote_found  0

    lassign [get_menu_states $rows] open_state close_state hide_state show_state

    foreach row $rows {
      if {[$widgets(tl) set $row remote] ne ""} {
        set fav_state    "disabled"
        set remote_found 1
        break
      }
    }
    foreach row $rows {
      if {[$widgets(tl) item $row -open] == 0} {
        set sort_state "disabled"
        break
      }
    }

    # Clear the menu
    $widgets(menu) delete 0 end

    $widgets(menu) add command -label [msgcat::mc "New File"]               -command [list sidebar::add_file_to_folder $first_row]     -state $one_act_state
    $widgets(menu) add command -label [msgcat::mc "New File From Template"] -command [list sidebar::add_file_from_template $first_row] -state $one_act_state
    $widgets(menu) add command -label [msgcat::mc "New Directory"]          -command [list sidebar::add_folder_to_folder $first_row]   -state $one_act_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Open Directory Files"]  -command [list sidebar::open_folder_files $rows]  -state $open_state
    $widgets(menu) add command -label [msgcat::mc "Close Directory Files"] -command [list sidebar::close_folder_files $rows] -state $close_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Hide Directory Files"]  -command [list sidebar::hide_folder_files $rows] -state $hide_state
    $widgets(menu) add command -label [msgcat::mc "Show Directory Files"]  -command [list sidebar::show_folder_files $rows] -state $show_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Copy Pathname"] -command [list sidebar::copy_pathname $first_row] -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Show Info"]     -command [list sidebar::update_info_panel $first_row] -state $one_state
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Rename"] -command [list sidebar::rename_folder $first_row] -state $one_act_state
    if {[preferences::get General/UseMoveToTrash] && !$remote_found} {
      $widgets(menu) add command -label [msgcat::mc "Move To Trash"] -command [list sidebar::move_to_trash $rows] -state $act_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Delete"] -command [list sidebar::delete_folder $rows] -state $act_state
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
    $widgets(menu) add separator

    $widgets(menu) add cascade -label [msgcat::mc "Sort"] -menu $widgets(sortmenu) -state $sort_state

    # Add plugins to sidebar directory popup
    plugins::handle_dir_popup $widgets(menu)

  }

  ######################################################################
  # Sets up the given menu for a root directory item.
  proc setup_root_menu {rows} {

    variable widgets
    variable state

    set one_state     [expr {([llength $rows] == 1) ? "normal" : "disabled"}]
    set one_act_state [expr {($state eq "normal") ? $one_state : "disabled"}]
    set act_state     [expr {($state eq "normal") ? "normal" : "disabled"}]
    set fav_state     $one_act_state
    set parent_state  $one_state
    set sort_state    $one_act_state
    set first_row     [lindex $rows 0]
    set remote_found  0

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
    foreach row $rows {
      if {[$widgets(tl) item $row -open] == 0} {
        set sort_state "disabled"
        break
      }
    }

    # Clear the menu
    $widgets(menu) delete 0 end

    $widgets(menu) add command -label [msgcat::mc "New File"]               -command [list sidebar::add_file_to_folder $first_row]     -state $one_act_state
    $widgets(menu) add command -label [msgcat::mc "New File From Template"] -command [list sidebar::add_file_from_template $first_row] -state $one_act_state
    $widgets(menu) add command -label [msgcat::mc "New Directory"]          -command [list sidebar::add_folder_to_folder $first_row]   -state $one_act_state
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
    $widgets(menu) add command -label [msgcat::mc "Show Info"]     -command [list sidebar::update_info_panel $first_row] -state $one_state
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Rename"] -command [list sidebar::rename_folder $first_row] -state $one_act_state
    if {[preferences::get General/UseMoveToTrash] && !$remote_found} {
      $widgets(menu) add command -label [msgcat::mc "Move To Trash"] -command [list sidebar::move_to_trash $rows] -state $act_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Delete"] -command [list sidebar::delete_folder $rows] -state $act_state
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
    $widgets(menu) add separator

    $widgets(menu) add cascade -label [msgcat::mc "Sort"] -menu $widgets(sortmenu) -state $sort_state

    # Add plugins to sidebar root popup
    plugins::handle_root_popup $widgets(menu)

  }

  ######################################################################
  # Sets up the file popup menu for the currently selected rows.
  proc setup_file_menu {rows} {

    variable widgets
    variable state

    set one_state     [expr {([llength $rows] == 1) ? "normal" : "disabled"}]
    set one_act_state [expr {($state eq "normal") ? $one_state : "disabled"}]
    set act_state     [expr {($state eq "normal") ? "normal" : "disabled"}]
    set hide_state    "disabled"
    set show_state    "disabled"
    set open_state    "disabled"
    set close_state   "disabled"
    set first_row     [lindex $rows 0]
    set diff_state    [expr {([$widgets(tl) set $first_row remote] eq "") ? $one_act_state : "disabled"}]
    set remote_found  0

    # Calculate the hide and show menu states
    if {$state eq "normal"} {
      foreach row $rows {
        switch [$widgets(tl) item $row -image] {
          "sidebar_hidden" { set close_state "normal"; set show_state "normal" }
          "sidebar_open"   { set close_state "normal"; set hide_state "normal" }
          default          { set open_state  "normal" }
        }
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

    $widgets(menu) add command -label [msgcat::mc "Copy Pathname"]   -command [list sidebar::copy_pathname $first_row]  -state $one_state
    $widgets(menu) add command -label [msgcat::mc "Show Difference"] -command [list sidebar::show_file_diff $first_row] -state $diff_state
    $widgets(menu) add command -label [msgcat::mc "Show Info"]       -command [list sidebar::update_info_panel $first_row] -state $one_state
    $widgets(menu) add separator

    $widgets(menu) add command -label [msgcat::mc "Rename"]    -command [list sidebar::rename_file $first_row]    -state $one_act_state
    $widgets(menu) add command -label [msgcat::mc "Duplicate"] -command [list sidebar::duplicate_file $first_row] -state $one_act_state
    if {[preferences::get General/UseMoveToTrash] && !$remote_found} {
      $widgets(menu) add command -label [msgcat::mc "Move To Trash"] -command [list sidebar::move_to_trash $rows] -state $act_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Delete"] -command [list sidebar::delete_file $rows] -state $act_state
    }
    $widgets(menu) add separator

    if {[favorites::is_favorite [$widgets(tl) set $first_row name]]} {
      $widgets(menu) add command -label [msgcat::mc "Unfavorite"] -command [list sidebar::unfavorite $first_row] -state $one_act_state
    } else {
      $widgets(menu) add command -label [msgcat::mc "Favorite"] -command [list sidebar::favorite $first_row] -state $one_act_state
    }

    # Add plugins to sidebar file popup
    plugins::handle_file_popup $widgets(menu)

  }

  ######################################################################
  # Setup the sortby menu that is associated with directories.
  proc setup_sort_menu {} {

    variable widgets

    $widgets(sortmenu) add radiobutton -label [msgcat::mc "By Name"]    -variable sidebar::sortby  -value "name"        -command [list sidebar::sort_updated]
    $widgets(sortmenu) add separator
    $widgets(sortmenu) add radiobutton -label [msgcat::mc "Increasing"] -variable sidebar::sortdir -value "-increasing" -command [list sidebar::sort_updated]
    $widgets(sortmenu) add radiobutton -label [msgcat::mc "Decreasing"] -variable sidebar::sortdir -value "-decreasing" -command [list sidebar::sort_updated]
    $widgets(sortmenu) add separator
    $widgets(sortmenu) add radiobutton -label [msgcat::mc "Manually"]   -variable sidebar::sortby  -value "manual"      -command [list sidebar::sort_updated]

  }

  ######################################################################
  # Called whenever the sort menu value is changed for one or more
  # directories.
  proc sort_updated {} {

    variable widgets
    variable sortby
    variable sortdir
    variable selection_anchor

    if {$sortby eq "manual"} {
      foreach row [$widgets(tl) selection] {
        $widgets(tl) set $row sortby $sortby
        update_directory $row
        write_sort_file $row 1
      }
    } else {
      foreach row [$widgets(tl) selection] {
        write_sort_file $row 0
        $widgets(tl) set $row sortby $sortby:$sortdir
        update_directory $row
      }
    }

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
      is_open    { return [$widgets(tl) item $index -open] }
      parent     { return [$widgets(tl) parent $index] }
      children   { return [$widgets(tl) children $index] }
      sortby     { return [lindex [split [$widgets(tl) set $index sortby] :] 0] }
      default    {
        return -code error "Illegal sidebar attribute specified ($attr)"
      }
    }

  }

  ######################################################################
  # Sets the sidebar item attribute to the given value.
  proc set_info {index attr value} {

    variable widgets

    switch $attr {
      open {
        if {[get_info $index is_dir] && ([$widgets(tl) item $index -open] != $value)} {
          if {$value} {
            expand_directory $index
          } else {
            collapse_directory $index
          }
        }
      }
      default {
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
            check_root_removal $widgets(tl) $row
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

    # Normalize the directory
    set dir [file normalize $dir]

    # If the directory is not remote, add it to the recently opened menu list
    if {$opts(-record) && ($opts(-remote) eq "")} {
      add_to_recently_opened $dir
    }

    # Search for the directory or an ancestor
    set last_tdir ""
    set tdir      $dir
    while {($tdir ne $last_tdir) && ([set found [$widgets(tl) tag has "$tdir,$opts(-remote)"]] eq "")} {
      set last_tdir $tdir
      set tdir [file dirname $tdir]
    }

    # If the directory was not found, insert the directory as a root directory
    if {$found eq ""} {
      set roots  [$widgets(tl) children {}]
      set sortby [get_default_sortby $dir]
      set parent [$widgets(tl) insert "" end -text [file tail $dir] -values [list $dir $opts(-remote) $sortby] -open 0 -tags [list d $dir,$opts(-remote)]]

    # Otherwise, add missing hierarchy to make directory visible
    } else {
      set parent $found
      foreach tdir [lrange [file split $dir] [llength [file split $tdir]] end] {
        set parent [add_subdirectory $parent $opts(-remote) $tdir]
      }
    }

    # Show the directory's contents (if they are not already displayed)
    if {($parent ne "") && [$widgets(tl) item $parent -open] == 0} {
      add_subdirectory $parent $opts(-remote)
    }

    # If we just inserted a root directory, check for other rooted directories
    # that may be children of this directory and merge them.
    if {$found eq ""} {

      # Remove any rooted directories that exist within this directory
      set dirlen [string length $dir]
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
        }
      }

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
    foreach name [order_files_dirs [$widgets(tl) set $parent name] $remote {*}[split [$widgets(tl) set $parent sortby] :]] {

      lassign $name fname dir

      if {$dir} {
        set sortby [get_default_sortby $fname]
        set child [$widgets(tl) insert $parent end -text [file tail $fname] -values [list $fname $remote $sortby] -open 0 -tags [list d $fname,$remote]]
        if {[file tail $fname] eq $fdir} {
          set frow $child
        }
      } else {
        if {($remote ne "") || ![ignore_file $fname]} {
          set key [$widgets(tl) insert $parent end -text [file tail $fname] -values [list $fname $remote ""] -open 1 -tags [list f $fname,$remote]]
          if {[files::is_opened $fname $remote]} {
            set_image $key sidebar_open
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
  proc order_files_dirs {dir remote sortby {sortdir -increasing}} {

    set items       [list]
    set show_hidden [preferences::get Sidebar/ShowHiddenFiles]

    if {$remote ne ""} {
      remote::dir_contents $remote $dir items
    } elseif {$::tcl_platform(platform) eq "windows"} {
      foreach fname [glob -nocomplain -directory $dir *] {
        if {$show_hidden || ([string index [file tail $fname] 0] ne ".")} {
          lappend items [list $fname [file isdirectory $fname]]
        }
      }
    } else {
      if {$show_hidden} {
        foreach fname [glob -nocomplain -directory $dir -types hidden *] {
          lappend items [list $fname [file isdirectory $fname]]
        }
      }
      foreach fname [glob -nocomplain -directory $dir *] {
        lappend items [list $fname [file isdirectory $fname]]
      }
    }

    # If a sortfile exists and is marked to be used, perform a manual sort
    if {($remote eq "") && ![catch { tkedat::read [file join $dir .tkesort] } rc]} {
      array set contents $rc
      if {![info exists contents(use)] || $contents(use) || ($sortby eq "manual")} {
        set new_items   [lrepeat [llength $contents(items)] ""]
        set extra_items [list]
        foreach item $items {
          set tail [file tail [lindex $item 0]]
          if {[set index [lsearch $contents(items) $tail]] != -1} {
            lset new_items $index $item
          } elseif {$tail ne ".tkesort"} {
            lappend extra_items $item
          }
        }
        if {[preferences::get Sidebar/ManualInsertNewAtTop]} {
          return [lmap item [concat $extra_items $new_items] {expr {($item ne "") ? $item : [continue]}}]
        } else {
          return [lmap item [concat $new_items $extra_items] {expr {($item ne "") ? $item : [continue]}}]
        }
      }
    }

    # If we are supposed to sort with folders at the top, return that listing
    if {[preferences::get Sidebar/FoldersAtTop]} {
      return [list {*}[lsort $sortdir -unique -index 0 [lsearch -inline -all -index 1 $items 1]] \
                   {*}[lsort $sortdir -unique -index 0 [lsearch -inline -all -index 1 $items 0]]]
    }

    return [lsort $sortdir -unique -index 0 $items]

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
  proc check_root_removal {w item} {

    # Get the root directory in the table
    while {[set parent [$w parent $item]] ne ""} {
      set item $parent
    }

    # If the user wants us to auto-remove when the open file count reaches 0,
    # remove it from the sidebar
    if {[preferences::get Sidebar/RemoveRootAfterLastClose] && ([files::num_opened [$w get $item name] [$w get $item remote]] == 0)} {
      $w delete $item
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
  proc collapse_directory {{row ""}} {

    variable widgets

    if {$row eq ""} {
      set row [$widgets(tl) focus]
    }

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
            return
          } elseif {$compare == -1} {
            $widgets(tl) insert $parent $i -text [file tail $fname] -image sidebar_open -open 1 -values [list $fname $remote ""] -tags [list f $fname,$remote]
            return
          }
        }
        incr i
      }

      # Insert the file at the end of the parent
      $widgets(tl) insert $parent end -text [file tail $fname] -image sidebar_open -open 1 -values [list $fname $remote ""] -tags [list f $fname,$remote]

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
      tooltip::tooltip clear $widgets(tl)
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

    variable widgets

    tooltip::tooltip clear $widgets(tl)

  }

  ######################################################################
  # Handle a selection change to the sidebar.
  proc handle_selection {} {

    variable widgets
    variable selection_anchor
    variable select_id

    if {$select_id != -1} {
      after cancel $select_id
      set select_id ""
    }

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

      # If the information panel should be updated, do it now
      update_info_panel_for_selection

    }

  }

  ######################################################################
  # Handles a left-click on the sidebar.
  proc handle_left_press {W x y tkdnd_cmd} {

    variable widgets
    variable mover

    if {[set row [$widgets(tl) identify item $x $y]] eq ""} {
      return 0
    }

    # Get the information that we need for moving the selections to
    # a new location
    set selected        [$widgets(tl) selection]
    set mover(start)    $row
    set mover(rows)     [expr {([lsearch $selected $row] == -1) ? $row : $selected}]
    set mover(detached) 0

    # If the user clicks on the disclosure triangle, let the treeview
    # handle the left press event
    switch -glob -- [$widgets(tl) identify element $x $y] {
      *.indicator -
      *.disclosure {
        return 0
      }
    }

    # If drag and drop is enabled, call our tkdnd_press method
    if {$tkdnd_cmd ne ""} {
      tkdnd_press {*}$tkdnd_cmd
    }

    # If the clicked row is not within the current selection
    return [expr {([llength $selected] > 1) && ([lsearch $selected $row] != -1)}]

  }

  ######################################################################
  # Handles a left-click button release event.  If we were doing a drag
  # and drop file move motion, move the files/folders to the new location.
  proc handle_left_release {W x y} {

    variable widgets
    variable mover
    variable tkdnd_drag

    # Release the drag and drop event, if we doing that
    tkdnd_release

    # If we are in a tkdnd_drag call, we have nothing more to do
    if {$tkdnd_drag} {
      return
    }

    # Cancel a pending spring and/or scan operation
    spring_cancel
    tree_scan_cancel up
    tree_scan_cancel down

    if {[set row [$widgets(tl) identify item $x $y]] eq ""} {
      return
    }

    # If we are moving rows, handle them now
    if {[info exists mover(detached)] && $mover(detached)} {

      $widgets(tl) configure -cursor ""

      if {[$widgets(tl) tag has moveto $row]} {

        set dir [$widgets(tl) set $row name]

        $widgets(tl) tag remove moveto $row

        if {[$widgets(tl) item $row -open] == 0} {
          foreach item $mover(rows) {
            if {[move_item $widgets(tl) $item $row]} {
              $widgets(tl) delete $item
            }
          }
        } else {
          foreach item $mover(rows) {
            if {[move_item $widgets(tl) $item $row]} {
              $widgets(tl) detach $item
              $widgets(tl) move $item $row end
              update_filenames $widgets(tl) $item $dir
            }
          }
          if {[$widgets(tl) set $row sortby] eq "manual"} {
            write_sort_file $row
          } else {
            update_directory $row
          }
        }

      } elseif {[winfo ismapped $widgets(insert)]} {

        lassign [$widgets(tl) bbox $row] bx by bw bh

        set parent    [$widgets(tl) parent $row]
        set parentdir [$widgets(tl) set $parent name]

        if {$by != [lindex [place configure $widgets(insert) -y] 4]} {
          set irow [$widgets(tl) next $row]
          if {[get_info $row is_dir]} {
            set parent    $row
            set parentdir [$widgets(tl) set $row name]
            set irow      [lindex [$widgets(tl) children $row] 0]
          }
        } else {
          set irow $row
        }

        # Remove the insertion bar
        place forget $widgets(insert)

        # Move the files in the file system and in the sidebar treeview
        foreach item [lreverse $mover(rows)] {
          if {$item ne $irow} {
            if {[move_item $widgets(tl) $item $parent]} {
              $widgets(tl) detach $item
              $widgets(tl) move $item $parent [expr {($irow eq "") ? "end" : [$widgets(tl) index $irow]}]
              update_filenames $widgets(tl) $item $parentdir
              set irow $item
            }
          }
        }

        # Specify that the directory should be sorted manually
        $widgets(tl) set $parent sortby "manual"

        # Create the sort file
        write_sort_file $parent

      }

    # If the file is currently in the notebook, make it the current tab
    } else {

      # Select the row if we did not move the selection
      if {[info exists mover(rows)] && ([lsearch $mover(rows) $row] != -1)} {
        $widgets(tl) selection set $row
      }

      if {[$widgets(tl) item $row -image] ne ""} {
        set fileindex [files::get_index [$widgets(tl) set $row name] [$widgets(tl) set $row remote]]
        gui::get_info $fileindex fileindex tabbar tab
        gui::set_current_tab $tabbar $tab
      }

    }

  }

  ######################################################################
  # Attempts to move the given item to the parent directory
  proc move_item {w item parent} {

    if {$parent eq [$w parent $item]} {

      return 1

    } else {

      set fname     [$w set $item name]
      set remote    [$w set $item remote]
      set parentdir [$w set $parent name]

      if {[get_info $item is_dir]} {
        if {![catch { files::move_folder $fname $remote $parentdir } rc]} {
          return 1
        }
      } else {
        if {![catch { files::move_file $fname $remote $parentdir } rc]} {
          return 1
        }
      }

    }

    return 0

  }

  ######################################################################
  # Counts the number of opened files in the given node tree.
  proc count_opened {w item} {

    set count [expr {[$w item $item -image] ne ""}]

    foreach child [$w children $item] {
      incr count [count_opened $w $child]
    }

    return $count

  }

  ######################################################################
  # Updates all of the filenames
  proc update_filenames {w item dir} {

    # Get the original name
    set old_name [$w set $item name]

    # Update the name of the item
    $w set $item name [set dir [file join $dir [file tail $old_name]]]

    # Update the children
    foreach child [$w children $item] {
      update_filenames $w $child $dir
    }

  }

  ######################################################################
  # Add the clicked row to the selection and make it the new selection anchor.
  proc handle_control_left_click {W x y} {

    variable widgets

    if {[set row [$widgets(tl) identify item $x $y]] eq ""} {
      return
    }

    $widgets(tl) selection add $row
    $widgets(tl) focus $row

  }

  ######################################################################
  # Handles a control right click on a sidebar item, displaying the information
  # panel.
  proc handle_control_right_click {W x y} {

    variable widgets

    if {[set row [$widgets(tl) identify item $x $y]] eq ""} {
      return
    }

    # Update the information panel
    update_info_panel $row

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
    variable select_id
    variable state

    if {$select_id ne ""} {
      after cancel $select_id
      set select_id ""
    }

    if {$state ne "normal"} {
      return
    }

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
    variable state

    # Get the selected rows
    set selected [$widgets(tl) selection]

    # Get the currently selected rows
    foreach row $selected {

      # Open the file in the viewer
      if {[$widgets(tl) tag has f $row]} {

        # Add the file
        if {$state eq "normal"} {
          gui::add_file end [$widgets(tl) set $row name] -remote [$widgets(tl) set $row remote]
        }

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
  # Handles the press of an escape key.
  proc handle_escape {W} {

    variable widgets
    variable mover

    if {$mover(detached)} {
      set mover(detached) 0
      set mover(start)    ""
      $widgets(tl) tag remove moveto
      place forget $widgets(insert)
    } else {
      pack forget $widgets(info)
    }

  }

  ######################################################################
  # Handles a BackSpace key in the sidebar.  Closes the currently selected
  # files if they are opened.
  proc handle_backspace {W} {

    variable widgets
    variable state

    if {$state ne "normal"} {
      return
    }

    # Close the currently selected rows
    close_file [$widgets(tl) selection]

  }

  ######################################################################
  # Handles a Control-Return or Control-Space event.
  proc handle_control_return_space {W} {

    variable widgets

    # Get the selected rows
    set selected [$widgets(tl) selection]

    # Update the information panel
    update_info_panel $selected

  }

  ######################################################################
  # Handles mouse motion in the sidebar, displaying tooltips over the
  # root directories to display the full pathname (and possibly remote
  # information as well).
  proc handle_motion {W x y} {

    variable widgets
    variable last_id
    variable after_id

    set id      [$W identify item $x $y]
    set lastId  $last_id
    set last_id $id

    if {$id ne $lastId} {
      after cancel $after_id
      if {$lastId ne ""} {
        hide_tooltip
      }
      if {$id ne ""} {
        set after_id [after 300 sidebar::show_tooltip $id]
      }
    }

  }

  ######################################################################
  # Returns 1 if the given id is within the currently selected rows.
  proc is_droppable {w id} {

    variable mover

    # If the file is remote or the target is not a file and the sortby type is not set to manual, we are not
    # droppable
    if {([$w set $id remote] ne "") || (![get_info $id is_dir] && ([$w set [$w parent $id] sortby] ne "manual"))} {
      return 0
    }

    # Check to see if the target is within anything this is currently selected
    while {($id ne "") && ([lsearch $mover(rows) $id] == -1)} {
      set id [$w parent $id]
    }

    return [expr {$id eq ""}]

  }

  ######################################################################
  # Handles button-1 motion events.  Causes selected files to be detached
  # so that they can be placed in a different location.
  proc handle_b1_motion {W x y tkdnd_cmd} {

    variable widgets
    variable mover
    variable spring_id
    variable tkdnd_drag

    # Call the tkdnd_motion procedure if the command is valid.
    if {$tkdnd_cmd ne ""} {
      tkdnd_motion {*}$tkdnd_cmd
    }

    # If we are in the middle of a tkdnd drag event, return immediately
    if {$tkdnd_drag} {
      return
    }

    # Get the current row
    if {[set id [$W identify item $x $y]] eq ""} {
      return
    }

    # If the current row exists within one of the selected files or the target
    # directory is a remote directory, don't allow the file/directory to be moved there.
    if {![is_droppable $widgets(tl) $id]} {
      $widgets(tl) tag remove moveto
      place forget $widgets(insert)
      spring_cancel
      return
    }

    lassign [$widgets(tl) bbox $id] bx by bw bh

    if {$mover(detached)} {
      if {([set first [$widgets(tl) identify item 0 0]] ne "") && ($first eq $id)} {
        tree_scan_start $widgets(tl) up
      } else {
        tree_scan_cancel up
      }
      if {([set last [$widgets(tl) identify item 0 [winfo height $widgets(tl)]]] ne "") && ($last eq $id)} {
        tree_scan_start $widgets(tl) down
      } else {
        tree_scan_cancel down
      }
      if {$by eq ""} {
        $widgets(tl) tag remove moveto
        place forget $widgets(insert)
        spring_cancel
      } elseif {$y < ($by + int($bh * 0.25))} {
        $widgets(tl) tag remove moveto
        place $widgets(insert) -y $by -width $bw
        spring_cancel
      } elseif {$y > ($by + int($bh * 0.75))} {
        $widgets(tl) tag remove moveto
        place $widgets(insert) -y [expr $by + $bh] -width $bw
        spring_cancel
      } elseif {[get_info $id is_dir]} {
        if {($spring_id eq "") && ![$widgets(tl) item $id -open] && [lsearch [$widgets(tl) item $id -tags] moveto] == -1} {
          set spring_id [after 1000 [list sidebar::spring_directory $id]]
        }
        $widgets(tl) tag add moveto $id
        place forget $widgets(insert)
      } else {
        $widgets(tl) tag remove moveto
        spring_cancel
      }
    } elseif {($mover(start) ne "") && ($id ne $mover(start))} {
      set mover(detached) 1
      $widgets(tl) configure -cursor [ttk::cursor move]
    }

  }

  ######################################################################
  # Start a tree scan.
  proc tree_scan_start {w dir} {

    variable scan_id

    if {$scan_id($dir) ne ""} {
      return
    }

    set scan_id($dir) [after 900 [list sidebar::tree_scan $w $dir [expr int(900 * 0.3)]]]

  }

  ######################################################################
  # Perform a tree scan operation.
  proc tree_scan {w dir {delay ""}} {

    variable scan_id

    switch $dir {
      up {
        set focus [$w identify item 0 0]
        if {[set up [$w prev $focus]] eq ""} {
          set focus [$w parent $focus]
        } else {
          while {[$w item $up -open] && [llength [$w children $up]]} {
            set up [lindex [$w children $up] end]
          }
          set focus $up
        }
      }
      down {
        set focus [$w identify item 0 [winfo height $w]]
        if {[$w item $focus -open] && [llength [$w children $focus]]} {
          set focus [lindex [$w children $focus] 0]
        } else {
          set up   $focus
          set down ""
          while {($up ne "") && ([set down [$w next $up]] eq "")} {
            set up [$w parent $up]
          }
          set focus $down
        }
      }
    }

    # If the next row was not found, exit
    if {$focus eq ""} {
      return
    }

    # Make sure that the given row is in view
    $w see $focus

    # Set the scan directory
    set scan_id($dir) [after [expr ($delay < 30) ? 30 : $delay] [list sidebar::tree_scan $w $dir [expr int($delay * 0.3)]]]

  }

  ######################################################################
  # Cancel the tree scan
  proc tree_scan_cancel {dir} {

    variable scan_id

    if {$scan_id($dir) ne ""} {
      after cancel $scan_id($dir)
      set scan_id($dir) ""
    }

  }

  ######################################################################
  # Perform a spring open.
  proc spring_directory {row} {

    variable spring_id

    # Clear the spring ID
    set spring_id ""

    # Open the directory
    expand_directory $row

  }

  ######################################################################
  # Cancel a spring operation.
  proc spring_cancel {} {

    variable spring_id

    if {$spring_id ne ""} {
      after cancel $spring_id
      set spring_id ""
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

    if {[ipanel::is_viewable $widgets(info,panel)]} {
      pack $widgets(info) -fill both
    }

  }

  ######################################################################
  # Handles the sidebar losing focus.
  proc handle_focus_out {} {

    variable widgets

    if {![preferences::get Sidebar/KeepInfoPanelVisible]} {
      pack forget $widgets(info)
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
    if {[set pathtype [file pathtype $fname]] eq "relative"} {
      set fname    [file join [$widgets(tl) set $row name] $fname]
    }

    # Get the remote status
    set remote [$widgets(tl) set $row remote]

    # Create the file
    if {$remote eq ""} {
      if {[catch { file mkdir [file dirname $fname] }]} {
        return
      }
      if {[catch { open $fname w } rc]} {
        return
      }
      close $rc
    } else {
      if {![remote::save_file $remote $fname " " modtime]} {
        return
      }
    }

    if {$pathtype eq "relative"} {

      # Expand the directory
      expand_directory $row

    }

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
    if {[set pathtype [file pathtype $dname]] eq "relative"} {
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

    if {$pathtype eq "relative"} {

      # Expand the directory
      expand_directory $row

      # Update the directory
      update_directory $row

    } else {

      # If we are absolute, add the directory to the sidebar
      $widgets(tl) selection set [add_directory $dname -remote $remote]

    }

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

    # Update the information panel
    update_info_panel

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

    # Update the information panel
    update_info_panel

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
      -text [file tail $dup_fname] -values [list $dup_fname $remote ""] -open 1 -tags [list f $dup_fname,$remote]]

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
  proc handle_info_panel_view {name1 name2 op} {

    update_info_panel

  }

  ######################################################################
  # Handles any changes to the info panel update preference option.
  proc handle_info_panel_follows {name1 name2 op} {

    update_info_panel_for_selection

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
  proc view_file {fname {remote ""}} {

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
  # In cases where we are updating the information panel whenever the
  # user changes the selection, we need to make sure the sidebar selection
  # can change without delay since updating file information can take a
  # moment.
  proc update_info_panel_for_selection {} {

    variable widgets
    variable ipanel_id

    if {![preferences::get Sidebar/InfoPanelFollowsSelection]} {
      return
    }

    if {$ipanel_id ne ""} {
      after cancel $ipanel_id
    }

    # Update the information panel
    set ipanel_id [after 500 [list sidebar::update_info_panel [$widgets(tl) selection]]]

  }

  ######################################################################
  # Updates the file information panel to match the current selections
  proc update_info_panel {{selected ""}} {

    variable widgets
    variable ipanel_id

    set ipanel_id ""

    if {[llength $selected] == 1} {
      ipanel::update $widgets(info,panel) [$widgets(tl) set [lindex $selected 0] name]
      pack $widgets(info) -fill both
      $widgets(tl) see [lindex $selected 0]
    } elseif {($selected eq "") && [winfo ismapped $widgets(info)]} {
      ipanel::update $widgets(info,panel)
    }

  }

  ######################################################################
  # If the information panel is open and displaying the given file,
  # update the information panel contents.
  proc update_info_panel_for_file {fname remote} {

    variable widgets

    # If the given file doesn't exist in the sidebar or the information panel
    # does not exist, return immediately.
    if {![winfo ismapped $widgets(info)] || ($remote ne "") || ([set index [get_index $fname $remote]] eq "")} {
      return
    }

    # If the given filename matches the update info panel, update the information
    # in the info panel.
    ipanel::update $widgets(info,panel)

  }

  ######################################################################
  # Closes the information panel.
  proc close_info_panel {fname} {

    variable widgets

    # Close the information panel content
    ipanel::close $widgets(info,panel)

    # Remove the panel from view
    pack forget $widgets(info)

  }

  ######################################################################
  # Writes the sorted contents of the given parent directory in the
  # sidebar to the parent's directory so that TKE will remember the
  # current sorting.
  proc write_sort_file {parent {use 1}} {

    variable widgets

    # Get the parent directory pathname
    set parentdir [$widgets(tl) set $parent name]

    # Gather the list of items in the parent
    set items [list]
    foreach child [$widgets(tl) children $parent] {
      lappend items [file tail [$widgets(tl) set $child name]]
    }

    # Write the file
    catch { tkedat::write [file join $parentdir .tkesort] [list items $items use $use] 0 }

  }

  ######################################################################
  # Gets the default sortby state for the given directory.
  proc get_default_sortby {dir} {

    variable widgets

    if {![catch { tkedat::read [file join $dir .tkesort] } rc]} {
      array set contents $rc
      if {![info exists contents(use)] || $contents(use)} {
        return "manual"
      }
    }

    return "name:-increasing"

  }

}
