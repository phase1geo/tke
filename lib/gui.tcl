# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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
# Name:    gui.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Contains all of the main GUI elements for the editor and
#          their behavior.
######################################################################

namespace eval gui {

  source [file join $::tke_dir lib ns.tcl]

  variable curr_id          0
  variable files            {}
  variable pw_index         0
  variable pw_current       0
  variable nb_index         0
  variable nb_move          ""
  variable file_move        0
  variable lengths          {}
  variable user_exit_status ""
  variable file_locked      0
  variable file_favorited   0
  variable last_opened      [list]
  variable fif_files        [list]
  variable info_clear       ""
  variable trailing_ws_re   {[\ ]+$}
  variable case_sensitive   1
  variable saved            0
  variable replace_all      1
  variable highlightcolor   ""
  variable auto_cwd         0
  variable numberwidth      4
  variable show_match_char  0
  variable browse_dir       "last"
  variable synced_key       ""
  variable synced_txt       ""

  array set widgets         {}
  array set language        {}
  array set tab_tip         {}
  array set line_sel_anchor {}
  array set txt_current     {}
  array set tab_current     {}
  array set cursor_hist     {}
  array set synced          {}
  array set be_after_id     {}
  array set be_ignore       {}

  array set files_index {
    fname    0
    mtime    1
    save_cmd 2
    tab      3
    lock     4
    readonly 5
    sidebar  6
    modified 7
    buffer   8
    gutters  9
    diff     10
    tags     11
    loaded   12
    eol      13
    remember 14
    remote   15
  }

  #######################
  #  PUBLIC PROCEDURES  #
  #######################

  ######################################################################
  # Returns the number of opened files.
  proc get_file_num {} {

    variable files

    return [llength $files]

  }

  ######################################################################
  # Returns the list of opened files.
  proc get_fnames {} {

    variable files
    variable files_index

    set fnames [list]

    foreach f $files {
      lappend fnames [lindex $f $files_index(fname)]
    }

    return $fnames

  }

  ######################################################################
  # Returns 1 if the given filename exists (either locally or remotely).
  proc file_exists {fname} {

    if {[set remote [get_info $fname fname remote]] eq ""} {
      return [file exists $fname]
    } else {
      return [[ns remote]::file_exists $remote $fname]
    }

  }

  ######################################################################
  # Returns the modification time of the given file (either locally or
  # remotely).
  proc modtime {fname} {

    set remote [get_info $fname fname remote]

    if {$remote eq ""} {
      file stat $fname stat
      return $stat(mtime)
    } else {
      return [[ns remote]::get_mtime $remote $fname]
    }

  }

  ######################################################################
  # Checks to see if the given file is newer than the file within the
  # editor.  If it is newer, prompt the user to update the file.
  proc check_file {index} {

    variable files
    variable files_index

    # Get the file information
    lassign [get_info $index fileindex {tab fname mtime modified}] tab fname mtime modified

    if {$fname ne ""} {
      if {[file_exists $fname]} {
        set file_mtime [modtime $fname]
        if {$mtime != $file_mtime} {
          if {$modified} {
            set answer [tk_messageBox -parent . -icon question -message [msgcat::mc "Reload file?"] \
              -detail $fname -type yesno -default yes]
            if {$answer eq "yes"} {
              update_file $index
            }
          } else {
            update_file $index
          }
          lset files $index $files_index(mtime) $file_mtime
        }
      } elseif {$mtime ne ""} {
        set answer [tk_messageBox -parent . -icon question -message [msgcat::mc "Delete tab?"] \
          -detail $fname -type yesno -default yes]
        if {$answer eq "yes"} {
          close_tab {} $tab -check 0
        } else {
          lset files $index $files_index(mtime) ""
        }
      }
    }

  }

  ######################################################################
  # Sets the title of the window to match the current file.
  proc set_title {} {

    # Get the current tab
    if {![catch { get_info {} current tabbar } tb] && ([llength [$tb tabs]] > 0)} {
      set tab_name [$tb tab current -text]
    } else {
      set tab_name ""
    }

    # Get the host name
    if {($::tcl_platform(os) eq "Darwin") && ([lindex [split $::tcl_platform(osVersion) .] 0] >= 16)} {
      set host ""
    } else {
      set host "[lindex [split [info hostname] .] 0]:"
    }

    if {[set session [[ns sessions]::current]] ne ""} {
      wm title . "$tab_name ($session) \[${host}[pwd]\]"
    } else {
      wm title . "$tab_name \[${host}[pwd]\]"
    }

  }

  ######################################################################
  # Sets the default file browser directory pathname.
  proc set_browse_directory {bsdir} {

    variable browse_dir

    set browse_dir $bsdir

  }

  ######################################################################
  # Returns the file browser directory path.
  proc get_browse_directory {} {

    variable browse_dir

    switch $browse_dir {
      last    { return "" }
      buffer  { return [file dirname [get_info {} current fname]] }
      current { return [pwd] }
      default { return $browse_dir }
    }

  }

  ######################################################################
  # Creates all images.
  proc create_images {} {

    # Create tab images
    theme::register_image tab_lock bitmap tabs -background \
      {msgcat::mc "Image used in tab to indicate that the tab’s file is locked."} \
      -file     [file join $::tke_dir lib images lock.bmp] \
      -maskfile [file join $::tke_dir lib images lock.bmp] \
      -foreground 1
    theme::register_image tab_readonly bitmap tabs -background \
      {msgcat::mc "Image used in tab to indicate that the tab's file is readonly."} \
      -file     [file join $::tke_dir lib images lock.bmp] \
      -maskfile [file join $::tke_dir lib images lock.bmp] \
      -foreground 1
    theme::register_image tab_diff bitmap tabs -background \
      {msgcat::mc "Image used in tab to indicate that the tab contains a difference view."} \
      -file     [file join $::tke_dir lib images diff.bmp] \
      -maskfile [file join $::tke_dir lib images diff.bmp] \
      -foreground 1
    theme::register_image tab_close bitmap tabs -background \
      {msgcat::mc "Image used in tab which, when clicked, closes the tab."} \
      -file     [file join $::tke_dir lib images close.bmp] \
      -maskfile [file join $::tke_dir lib images close.bmp] \
      -foreground 1

    # Create close button for forms
    theme::register_image form_close bitmap ttk_style background \
      {msgcat::mc "Image displayed in fill-in forms which closes the form UI.  Used in forms such as search, search/replace, and find in files."} \
      -file     [file join $::tke_dir lib images close.bmp] \
      -maskfile [file join $::tke_dir lib images close.bmp] \
      -foreground 1

    # Create main logo image
    image create photo logo -file [file join $::tke_dir lib images tke_logo_64.gif]

    # Create menu images
    theme::register_image menu_lock bitmap menus -background \
      {msgcat::mc "Image used in tab menus to indicate that the file is locked."} \
      -file     [file join $::tke_dir lib images lock.bmp] \
      -maskfile [file join $::tke_dir lib images lock.bmp] \
      -foreground 1
    theme::register_image menu_readonly bitmap menus -background \
      {msgcat::mc "Image used in tab menus to indicate that the file is readonly."} \
      -file     [file join $::tke_dir lib images lock.bmp] \
      -maskfile [file join $::tke_dir lib images lock.bmp] \
      -foreground 1
    theme::register_image menu_diff bitmap menus -background \
      {msgcat::mc "Image used in tab menus to indicate that the file is associated with a difference view."} \
      -file     [file join $::tke_dir lib images diff.bmp] \
      -maskfile [file join $::tke_dir lib images diff.bmp] \
      -foreground 1

    # Create preference images
    theme::register_image pref_checked photo ttk_style background \
      {msgcat::mc "Image used in the preferences window to indicate that a table item is selected."} \
      -file [file join $::tke_dir lib images checked.gif]
    theme::register_image pref_unchecked photo ttk_style background \
      {msgcat::mc "Image used in the preferences window to indicate that a table item is deselected."} \
      -file [file join $::tke_dir lib images unchecked.gif]
    theme::register_image pref_general photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the General tab."} \
      -file [file join $::tke_dir lib images general.gif]
    theme::register_image pref_appearance photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Appearance tab."} \
      -file [file join $::tke_dir lib images appearance.gif]
    theme::register_image pref_editor photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Editor tab."} \
      -file [file join $::tke_dir lib images editor.gif]
    theme::register_image pref_emmet photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Emmet tab."} \
      -file [file join $::tke_dir lib images emmet.gif]
    theme::register_image pref_find photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Find tab."} \
      -file [file join $::tke_dir lib images find.gif]
    theme::register_image pref_sidebar photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Sidebar tab."} \
      -file [file join $::tke_dir lib images sidebar.gif]
    theme::register_image pref_view photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the View tab."} \
      -file [file join $::tke_dir lib images view.gif]
    theme::register_image pref_snippets photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Snippets tab."} \
      -file [file join $::tke_dir lib images snippets.gif]
    theme::register_image pref_shortcuts photo ttk_style background \
      {msgcat::mc "Image used in the shortcuts window in the Shortcuts tab."} \
      -file [file join $::tke_dir lib images shortcut.gif]
    theme::register_image pref_advanced photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Advanced tab."} \
      -file [file join $::tke_dir lib images advanced.gif]

  }

  ######################################################################
  # Create the main GUI interface.
  proc create {} {

    variable widgets

    # Set the application icon photo
    wm iconphoto . [image create photo -file [file join $::tke_dir lib images tke_logo_128.gif]]
    wm geometry  . 800x600

    # Create images
    create_images

    # Create the panedwindow
    set widgets(pw) [ttk::panedwindow .pw -orient horizontal]

    # Add the sidebar
    set widgets(sb) [[ns sidebar]::create $widgets(pw).sb]

    # Create panedwindow (to support split pane view)
    $widgets(pw) add [ttk::frame $widgets(pw).tf]

    # Create the notebook panedwindow
    set widgets(nb_pw) [ttk::panedwindow $widgets(pw).tf.nbpw -orient horizontal]

    # Add notebook
    add_notebook

    # Pack the notebook panedwindow
    pack $widgets(nb_pw) -fill both -expand yes

    # Create the find_in_files widget
    set widgets(fif)       [ttk::frame .fif]
    ttk::label $widgets(fif).lf -text "Find: "
    set widgets(fif_find)  [ttk::entry $widgets(fif).ef]
    set widgets(fif_case)  [ttk::checkbutton $widgets(fif).case -text "Aa" -variable [ns gui]::case_sensitive]
    ttk::label $widgets(fif).li -text "In: "
    set widgets(fif_in)    [tokenentry::tokenentry $widgets(fif).ti -font [$widgets(fif_find) cget -font] -tokenshape square]
    set widgets(fif_save)  [ttk::checkbutton $widgets(fif).save -text [msgcat::mc "Save"] \
      -variable [ns gui]::saved -command "[ns search]::update_save fif"]
    set widgets(fif_close) [ttk::label $widgets(fif).close -image form_close]

    tooltip::tooltip $widgets(fif_case) [msgcat::mc "Case sensitivity"]

    bind $widgets(fif_find)          <Return>    "[ns gui]::check_fif_for_return"
    bind [$widgets(fif_in) entrytag] <Return>    { if {[gui::check_fif_for_return]} break }
    bind $widgets(fif_case)          <Return>    "[ns gui]::check_fif_for_return"
    bind $widgets(fif_save)          <Return>    "[ns gui]::check_fif_for_return"
    bind $widgets(fif_find)          <Escape>    "set [ns gui]::user_exit_status 0"
    bind [$widgets(fif_in) entrytag] <Escape>    "set [ns gui]::user_exit_status 0"
    bind $widgets(fif_case)          <Escape>    "set [ns gui]::user_exit_status 0"
    bind $widgets(fif_save)          <Escape>    "set [ns gui]::user_exit_status 0"
    bind $widgets(fif_close)         <Button-1>  "set [ns gui]::user_exit_status 0"
    bind $widgets(fif_find)          <Up>        "[ns search]::traverse_history fif  1"
    bind $widgets(fif_find)          <Down>      "[ns search]::traverse_history fif -1"
    bind $widgets(fif_close)         <Key-space> "set [ns gui]::user_exit_status 0"

    grid columnconfigure $widgets(fif) 1 -weight 1
    grid $widgets(fif).lf    -row 0 -column 0 -sticky ew -pady 2
    grid $widgets(fif).ef    -row 0 -column 1 -sticky ew -pady 2
    grid $widgets(fif).case  -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $widgets(fif).close -row 0 -column 3 -sticky news -padx 2 -pady 2
    grid $widgets(fif).li    -row 1 -column 0 -sticky ew -pady 2
    grid $widgets(fif).ti    -row 1 -column 1 -sticky ew -pady 2
    grid $widgets(fif).save  -row 1 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2

    # Create the information bar
    set widgets(info)        [ttk::frame .if]
    set widgets(info_state)  [ttk::label .if.l1]
    ttk::separator .if.s1 -orient vertical
    set widgets(info_msg)    [ttk::label .if.l2]
    ttk::separator .if.s2 -orient vertical
    set widgets(info_indent) [ttk::button .if.ind -style BButton -command [list [ns gui]::handle_info_menu_popup .if.ind [[ns indent]::create_menu .if.ind]]]
    ttk::separator .if.s3 -orient vertical
    set widgets(info_syntax) [ttk::button .if.syn -style BButton -command [list [ns gui]::handle_info_menu_popup .if.syn [[ns syntax]::create_menu .if.syn]]]
    ttk::label     .if.sp -text " "

    $widgets(info_indent) configure -state disabled
    $widgets(info_syntax) configure -state disabled

    pack .if.l1  -side left  -padx 2 -pady 2
    pack .if.s1  -side left  -padx 2 -pady 10 -fill y
    pack .if.l2  -side left  -padx 2 -pady 2
    pack .if.sp  -side right -padx 2 -pady 2
    pack .if.syn -side right -padx 2 -pady 2
    pack .if.s3  -side right -padx 2 -pady 10 -fill y
    pack .if.ind -side right -padx 2 -pady 2
    pack .if.s2  -side right -padx 2 -pady 10 -fill y

    # Create the configurable response widget
    set widgets(ursp)       [ttk::frame .rf]
    set widgets(ursp_label) [ttk::label .rf.l]
    set widgets(ursp_entry) [ttk::entry .rf.e]
    ttk::label .rf.close -image form_close

    bind $widgets(ursp_entry) <Return>    "set [ns gui]::user_exit_status 1"
    bind $widgets(ursp_entry) <Escape>    "set [ns gui]::user_exit_status 0"
    bind .rf.close            <Button-1>  "set [ns gui]::user_exit_status 0"
    bind .rf.close            <Key-space> "set [ns gui]::user_exit_status 0"

    grid rowconfigure    .rf 0 -weight 1
    grid columnconfigure .rf 1 -weight 1
    grid $widgets(ursp_label) -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(ursp_entry) -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .rf.close            -row 0 -column 2 -sticky news -padx 2 -pady 2

    # Pack the notebook
    grid rowconfigure    . 0 -weight 1
    grid columnconfigure . 0 -weight 1
    grid $widgets(pw)   -row 0 -column 0 -sticky news
    grid $widgets(ursp) -row 1 -column 0 -sticky ew
    grid $widgets(fif)  -row 2 -column 0 -sticky ew
    grid $widgets(info) -row 3 -column 0 -sticky ew

    grid remove $widgets(ursp)
    grid remove $widgets(fif)

    # Create tab popup
    set widgets(menu) [menu $widgets(nb_pw).popupMenu -tearoff 0 -postcommand [ns gui]::setup_tab_popup_menu]
    $widgets(menu) add command -label [msgcat::mc "Close Tab"]        -command [list [ns gui]::close_current {}]
    $widgets(menu) add command -label [msgcat::mc "Close Other Tabs"] -command [ns gui]::close_others
    $widgets(menu) add command -label [msgcat::mc "Close All Tabs"]   -command [ns gui]::close_all
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Hide Tab"]         -command [list [ns gui]::hide_current {}]
    $widgets(menu) add separator
    $widgets(menu) add checkbutton -label [msgcat::mc "Split View"] -onvalue 1 -offvalue 0 \
      -variable [ns menus]::show_split_pane -command [list [ns gui]::toggle_split_pane {}]
    $widgets(menu) add checkbutton -label [msgcat::mc "Bird's Eye View"] -onvalue 1 -offvalue 0 \
      -variable [ns menus]::show_birdseye -command [list [ns gui]::toggle_birdseye {}]
    $widgets(menu) add separator
    $widgets(menu) add checkbutton -label [msgcat::mc "Locked"] -onvalue 1 -offvalue 0 \
      -variable [ns gui]::file_locked    -command [list [ns gui]::set_current_file_lock_with_current {}]
    $widgets(menu) add checkbutton -label [msgcat::mc "Favorited"] -onvalue 1 -offvalue 0 \
      -variable [ns gui]::file_favorited -command [list [ns gui]::set_current_file_favorite_with_current {}]
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Show in Sidebar"]    -command [ns gui]::show_current_in_sidebar
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Move to Other Pane"] -command [ns gui]::move_to_pane

    # Add plugins to tab popup
    [ns plugins]::handle_tab_popup $widgets(menu)

    # Add the menu bar
    [ns menus]::create

    # Show the sidebar (if necessary)
    if {[[ns preferences]::get View/ShowSidebar]} {
      show_sidebar_view
    } else {
      hide_sidebar_view
    }

    # Show the console (if necessary)
    if {[[ns preferences]::get View/ShowConsole]} {
      show_console_view
    } else {
      # hide_console_view
    }

    # Show the tabbar (if necessary)
    if {[[ns preferences]::get View/ShowTabBar]} {
      show_tab_view
    } else {
      hide_tab_view
    }

    # Show the status bar (if necessary)
    if {[[ns preferences]::get View/ShowStatusBar]} {
      show_status_view
    } else {
      hide_status_view
    }

    # Set the matchchar value
    set_matching_char [[ns preferences]::get Editor/HighlightMatchingChar]

    # If the user attempts to close the window via the window manager, treat
    # it as an exit request from the menu system.
    wm protocol . WM_DELETE_WINDOW [list [ns menus]::exit_command]

    # Trace changes to the Appearance/Theme preference variable
    trace variable [ns preferences]::prefs(Editor/WarningWidth)                 w [ns gui]::handle_warning_width_change
    trace variable [ns preferences]::prefs(Editor/MaxUndo)                      w [ns gui]::handle_max_undo
    trace variable [ns preferences]::prefs(Editor/HighlightMatchingChar)        w [ns gui]::handle_matching_char
    trace variable [ns preferences]::prefs(View/AllowTabScrolling)              w [ns gui]::handle_allow_tab_scrolling
    trace variable [ns preferences]::prefs(Editor/VimMode)                      w [ns gui]::handle_vim_mode
    trace variable [ns preferences]::prefs(Appearance/EditorFont)               w [ns gui]::handle_editor_font
    trace variable [ns preferences]::prefs(General/AutoChangeWorkingDirectory)  w [ns gui]::handle_auto_cwd
    trace variable [ns preferences]::prefs(General/DefaultFileBrowserDirectory) w [ns gui]::handle_browse_directory
    trace variable [ns preferences]::prefs(View/ShowBirdsEyeView)               w [ns gui]::handle_show_birdseye
    trace variable [ns preferences]::prefs(View/BirdsEyeViewFontSize)           w [ns gui]::handle_birdseye_font_size
    trace variable [ns preferences]::prefs(View/BirdsEyeViewWidth)              w [ns gui]::handle_birdseye_width

    # Create general UI bindings
    bind all <Control-plus>  "[ns gui]::handle_font_change 1"
    bind all <Control-minus> "[ns gui]::handle_font_change -1"

  }

  ######################################################################
  # Handles any menu popups that are needed in the information bar
  proc handle_info_menu_popup {w mnu} {

    set menu_width  [winfo reqwidth $mnu]
    set menu_height [winfo reqheight $mnu]
    set w_width     [winfo width $w]
    set w_x         [winfo rootx $w]
    set w_y         [winfo rooty $w]

    set x [expr ($w_x + $w_width) - $menu_width]
    set y [expr $w_y - ($menu_height + 4)]

    tk_popup $mnu $x $y

  }

  ######################################################################
  # Returns 1 if a return key event should cause the find in files search
  # to begin.
  proc check_fif_for_return {} {

    variable widgets
    variable user_exit_status

    if {([llength [$widgets(fif_in) tokenget]] > 0) && \
        ([$widgets(fif_in) entryget] eq "") && \
        ([$widgets(fif_find) get] ne "")} {
      set user_exit_status 1
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles any preference changes to the Editor/WarningWidth setting.
  proc handle_warning_width_change {name1 name2 op} {

    # Set the warning width to the specified value
    foreach txt [get_all_texts] {
      $txt configure -warnwidth [[ns preferences]::get Editor/WarningWidth]
    }

  }

  ######################################################################
  # Handles any preference changes to the Editor/MaxUndo setting.
  proc handle_max_undo {name1 name2 op} {

    # Set the max_undo to the specified value
    foreach txt [get_all_texts] {
      $txt configure -maxundo [[ns preferences]::get Editor/MaxUndo]
    }

  }

  ######################################################################
  # Handles any preference changes to the Editor/HighlightMatchingChar setting.
  proc handle_matching_char {name1 name2 op} {

    set_matching_char [[ns preferences]::get Editor/HighlightMatchingChar]

  }

  ######################################################################
  # Sets the -matchchar value on all displayed text widgets.
  proc set_matching_char {value} {

    variable show_match_char

    # Save the show_match_char value
    set show_match_char $value

    # Update all existing text widgets to the new value
    foreach txt [get_all_texts] {
      $txt configure -matchchar $value
    }

  }

  ######################################################################
  # Handles any changes to the View/AllowTabScrolling preference variable.
  proc handle_allow_tab_scrolling {name1 name2 op} {

    variable widgets

    foreach pane [$widgets(nb_pw) panes] {
      $pane.tbf.tb configure -mintabwidth [expr {[[ns preferences]::get View/AllowTabScrolling] ? [lindex [$pane.tbf.tb configure -mintabwidth] 3] : 1}]
    }

  }

  ######################################################################
  # Handles any changes to the Editor/VimMode preference variable.
  proc handle_vim_mode {name1 name2 op} {

    [ns vim]::set_vim_mode_all

  }

  ######################################################################
  # Updates all of the fonts in the text window to the given.
  proc handle_editor_font {name1 name2 op} {

    # Update the size of the editor_font
    font configure editor_font {*}[font configure TkFixedFont] {*}[[ns preferences]::get Appearance/EditorFont]

  }

  ######################################################################
  # Changes the value of the automatic change working directory variable
  # and updates the current working directory with the current file
  # information.
  proc handle_auto_cwd {name1 name2 op} {

    set_auto_cwd [[ns preferences]::get General/AutoChangeWorkingDirectory]

  }

  ######################################################################
  # Changes the value of the browse directory variable to match the value
  # specified in the preference file.
  proc handle_browse_directory {name1 name2 op} {

    variable browse_dir

    # Set the browse directory to the value
    set browse_dir [[ns preferences]::get General/DefaultFileBrowserDirectory]

    # Adjust browse_dir to be last if the browse directory type was an actual pathname and it
    # does not exist.
    if {([lsearch [list last buffer current] $browse_dir] == -1) && ![file isdirectory $browse_dir]} {
      set browse_dir "last"
    }

  }

  ######################################################################
  # Handle any preference changes to the birdseye view status.
  proc handle_show_birdseye {name1 name2 op} {

    if {[[ns preferences]::get View/ShowBirdsEyeView]} {
      foreach txt [get_all_texts] {
        if {[string first "tf2" $txt] == -1} {
          show_birdseye $txt
        }
      }
    } else {
      foreach txt [get_all_texts] {
        if {[string first "tf2" $txt] == -1} {
          hide_birdseye $txt
        }
      }
    }

  }

  ######################################################################
  # Handle any preference changes to the birdseye font size.
  proc handle_birdseye_font_size {name1 name2 op} {

    set font_size [[ns preferences]::get View/BirdsEyeViewFontSize]

    foreach txt [get_all_texts] {
      if {[string first "tf2" $txt] == -1} {
        set tab [get_info $txt txt tab]
        if {[winfo exists $tab.be]} {
          $tab.be configure -font "-size $font_size"
        }
      }
    }

  }

  ######################################################################
  # Handle any preference changes to the birdseye width.
  proc handle_birdseye_width {name1 name2 op} {

    set width [[ns preferences]::get View/BirdsEyeViewWidth]

    foreach txt [get_all_texts] {
      if {[string first "tf2" $txt] == -1} {
        set tab [get_info $txt txt tab]
        if {[winfo exists $tab.be]} {
          $tab.be configure -width $width
        }
      }
    }

  }

  ######################################################################
  # Sets the auto_cwd variable to the given boolean value.
  proc set_auto_cwd {value} {

    variable auto_cwd
    variable files

    # Update the auto_cwd variable and if a file exists, update the current
    # working directory if auto_cwd is true.
    if {[set auto_cwd $value] && [llength $files]} {

      # Get the current file information
      lassign [get_info {} current {fname buffer diff}] fname buffer diff

      # If the current file is neither a buffer nor a difference view, update
      # the current working directory and title bar.
      if {!$buffer && !$diff} {
        cd [file dirname $fname]
        set_title
      }

    }

  }

  ######################################################################
  # Toggles the specified labelbutton.
  proc toggle_labelbutton {w} {

    if {[$w cget -relief] eq "raised"} {
      $w configure -relief sunken
    } else {
      $w configure -relief raised
    }

  }

  ######################################################################
  # Returns 1 if the current buffer can be moved to the other pane.
  proc movable_to_other_pane {} {

    variable widgets

    return [expr {([llength [[get_info {} current tabbar] tabs]] > 1) || ([llength [$widgets(nb_pw) panes]] > 1)}]

  }

  ######################################################################
  # Sets up the tab popup menu.
  proc setup_tab_popup_menu {} {

    variable widgets
    variable files
    variable files_index
    variable file_locked
    variable file_favorited

    # Get the current information
    lassign [get_info {} current {fileindex txt fname readonly lock diff tabbar remote buffer}] file_index txt fname readonly file_locked diff_mode tb remote buffer

    # Set the file_favorited variable
    set file_favorited [[ns favorites]::is_favorite $fname]

    # Set the state of the menu items
    if {[llength [$tb tabs]] > 1} {
      $widgets(menu) entryconfigure [msgcat::mc "Close Other*"] -state normal
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Close Other*"] -state disabled
    }
    if {$diff_mode} {
      $widgets(menu) entryconfigure [msgcat::mc "Hide Tab"] -state disabled
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Hide Tab"] -state normal
    }
    if {([llength [$tb tabs]] > 1) || ([llength [$widgets(nb_pw) panes]] > 1)} {
      $widgets(menu) entryconfigure [format "%s*" [msgcat::mc "Move"]] -state normal
    } else {
      $widgets(menu) entryconfigure [format "%s*" [msgcat::mc "Move"]] -state disabled
    }
    if {$readonly || $diff_mode} {
      $widgets(menu) entryconfigure [msgcat::mc "Locked"] -state disabled
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Locked"] -state normal
    }
    if {$fname eq ""} {
      $widgets(menu) entryconfigure [msgcat::mc "Favorited"]       -state disabled
      $widgets(menu) entryconfigure [msgcat::mc "Show in Sidebar"] -state disabled
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Show in Sidebar"] -state normal
      $widgets(menu) entryconfigure [msgcat::mc "Favorited"]       -state [expr {($diff_mode || $buffer || ($remote ne "")) ? "disabled" : "normal"}]
    }

    # Make the split pane and bird's eye indicators look correct
    switch [llength [$txt peer names]] {
      0 {
        set [ns menus]::show_split_pane 0
        set [ns menus]::show_birdseye   0
      }
      1 {
        if {[lsearch [$txt peer names] *tf2*] != -1} {
          set [ns menus]::show_split_pane 1
          set [ns menus]::show_birdseye   0
        } else {
          set [ns menus]::show_split_pane 0
          set [ns menus]::show_birdseye   1
        }
      }
      default {
        set [ns menus]::show_split_pane 1
        set [ns menus]::show_birdseye   1
      }
    }

    # Handle plugin states
    [ns plugins]::menu_state $widgets(menu) tab_popup

  }

  ######################################################################
  # Shows the sidebar viewer.
  proc show_sidebar_view {} {

    variable widgets

    $widgets(pw) insert 0 $widgets(sb)

  }

  ######################################################################
  # Hides the sidebar viewer.
  proc hide_sidebar_view {} {

    variable widgets

    catch { $widgets(pw) forget $widgets(sb) }

  }

  ######################################################################
  # Shows the console.
  proc show_console_view {} {

    catch { console show }

  }

  ######################################################################
  # Hides the console.
  proc hide_console_view {} {

    catch { console hide }

  }

  ######################################################################
  # Shows the tab bar.
  proc show_tab_view {} {

    variable widgets

    foreach nb [$widgets(nb_pw) panes] {
      if {[lsearch [pack slaves $nb] $nb.tbf] == -1} {
        pack $nb.tbf -before $nb.tf -fill x
      }
    }

  }

  ######################################################################
  # Hides the tab bar.
  proc hide_tab_view {} {

    variable widgets

    foreach nb [$widgets(nb_pw) panes] {
      if {[lsearch [pack slaves $nb] $nb.tbf] != -1} {
        pack forget $nb.tbf
      }
    }

  }

  ######################################################################
  # Shows the status bar.
  proc show_status_view {} {

    variable widgets

    catch { grid $widgets(info) }

    update idletasks

  }

  ######################################################################
  # Hides the status view
  proc hide_status_view {} {

    variable widgets

    catch { grid remove $widgets(info) }

    update idletasks

  }

  ######################################################################
  # Shows the line numbers.
  proc set_line_number_view {tid value} {

    # Show the line numbers in the current editor
    [current_txt $tid] configure -linemap $value

  }

  ######################################################################
  # Sets the minimum line number width of the line gutter to the given
  # value.
  proc set_line_number_width {tid val} {

    variable files
    variable files_index
    variable numberwidth

    set numberwidth $val

    for {set i 0} {$i < [llength $files]} {incr i} {
      [get_info [lindex $files $i $files_index(tab)] tab txt] configure -linemap_minwidth $val
    }

  }

  ######################################################################
  # Changes the given filename to the new filename in the file list and
  # updates the tab name to match the new name.
  proc change_filename {old_name new_name} {

    variable files
    variable files_index

    # Get information from old_name and if it exists, update it and update the tab name.
    if {![catch { lassign [get_info $old_name fname {tabbar tab fileindex}] tb tab index }] && ($index != -1)} {

      # Update the file information
      lset files $index $files_index(fname) $new_name

      # Update the tab name
      $tb tab $tab -text [file tail $new_name]

      # Update the title if necessary
      set_title

    }

  }

  ######################################################################
  # Changes all files that exist in the old directory and renames them
  # to the new directory.
  proc change_folder {old_name new_name} {

    variable files
    variable files_index

    foreach index [lsearch -all -index $files_index(fname) $files $old_name*] {
      set old_fname [lindex $files $index $files_index(fname)]
      lset files $index $files_index(fname) "$new_name[string range $old_fname [string length $old_name] end]"
    }

  }

  ######################################################################
  # Returns 1 if the given file exists in one of the notebooks.
  proc file_exists_in_nb {fname remote} {

    variable files
    variable files_index

    # Attempt to find the file index for the given filename and check the diff bit
    foreach index [lsearch -all -index $files_index(fname) $files $fname] {
      if {([lindex $files $index $files_index(diff)] == 0) && \
          ([lindex $files $index $files_index(remote)] eq $remote)} {
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Save the window geometry to the geometry.dat file.
  proc save_session {} {

    variable widgets
    variable last_opened
    variable files
    variable files_index

    # Gather content to save
    set content(Geometry)                [::window_geometry .]
    set content(Fullscreen)              [wm attributes . -fullscreen]
    set content(CurrentWorkingDirectory) [pwd]
    set content(Sidebar)                 [[ns sidebar]::save_session]
    set content(Launcher)                [[ns launcher]::save_session]

    # Calculate the zoomed state
    switch [tk windowingsystem] {
      x11 {
        set content(Zoomed) [wm attributes . -zoomed]
      }
      default {
        set content(Zoomed) [expr {[wm state .] eq "zoomed"}]
      }
    }

    foreach nb [$widgets(nb_pw) panes] {

      set tabindex    0
      set current_tab ""
      set current_set 0

      foreach tab [$nb.tbf.tb tabs] {

        # Get the file tab information
        lassign [get_info $tab tab {paneindex txt fname save_cmd lock readonly diff sidebar buffer remember remote}] \
          finfo(pane) txt finfo(fname) finfo(savecommand) finfo(lock) finfo(readonly) finfo(diff) finfo(sidebar) \
          finfo(buffer) finfo(remember) remote

        # If we need to forget this file, don't save it to the session
        if {!$finfo(remember) || ($remote ne "")} {
          continue
        }

        # Save the tab as a current tab if it's not a buffer
        if {!$finfo(buffer) && !$current_set} {
          set current_tab $tabindex
          if {[$nb.tbf.tb select] eq $tab} {
            set current_set 1
          }
        }

        set finfo(tab)         $tabindex
        set finfo(language)    [[ns syntax]::get_language $txt]
        set finfo(indent)      [[ns indent]::get_indent_mode $txt]
        set finfo(modified)    0
        set finfo(cursor)      [$txt index insert]
        set finfo(yview)       [$txt index @0,0]

        # Add markers
        set finfo(markers) [list]
        foreach {mname mtxt pos} [[ns markers]::get_markers $txt] {
          lappend finfo(markers) $mname [lindex [split $pos .] 0]
        }

        # Add diff data, if applicable
        if {$finfo(diff)} {
          set finfo(diffdata) [[ns diff]::get_session_data $txt]
        }
        lappend content(FileInfo) [array get finfo]

        incr tabindex

      }

      # Set the current tab for the pane (if one exists)
      if {$current_tab ne ""} {
        lappend content(CurrentTabs) $current_tab
      }

    }

    # Get the last_opened list
    set content(LastOpened) $last_opened

    # Return the content array
    return [array get content]

  }

  ######################################################################
  # Loads the geometry information (if it exists) and changes the current
  # window geometry to match the read value.
  proc load_session {tid info} {

    variable widgets
    variable last_opened
    variable files
    variable files_index
    variable pw_current

    array set content [list \
      Geometry                [wm geometry .] \
      CurrentWorkingDirectory [pwd] \
      Sidebar                 [list] \
      Launcher                [list] \
      FileInfo                [list] \
      CurrentTabs             [list] \
      LastOpened              "" \
    ]

    array set content $info

    # Put the state information into the rest of the GUI
    if {[info exists content(Fullscreen)] && $content(Fullscreen)} {
      wm attributes . -fullscreen 1
    } else {
      wm geometry . $content(Geometry)
      if {[info exists content(Zoomed)] && $content(Zoomed)} {
        switch [tk windowingsystem] {
          x11     { wm attributes . -zoomed 1 }
          default { wm state . zoomed }
        }
      }
    }

    # Restore the "last_opened" list
    set last_opened $content(LastOpened)

    # Load the session information into the sidebar
    [ns sidebar]::load_session $content(Sidebar)

    # Load the session information into the launcher
    [ns launcher]::load_session $content(Launcher)

    # Set the current working directory to the saved value
    if {[file exists $content(CurrentWorkingDirectory)]} {
      cd $content(CurrentWorkingDirectory)
    }

    # Put the list in order
    if {[llength $content(FileInfo)] > 0} {
      set ordered     [lrepeat 2 [lrepeat [llength $content(FileInfo)] ""]]
      set second_pane 0
      set i           0
      foreach finfo_list $content(FileInfo) {
        array set finfo $finfo_list
        lset ordered $finfo(pane) $finfo(tab) $i
        set second_pane [expr $finfo(pane) == 2]
        incr i
      }
    } else {
      set ordered [list "" ""]
    }

    # If the second pane is necessary, create it now
    if {[llength $content(CurrentTabs)] == 2} {
      add_notebook
    }

    # Add the tabs (in order) to each of the panes and set the current tab in each pane
    for {set pane 0} {$pane < [llength $content(CurrentTabs)]} {incr pane} {
      set pw_current $pane
      set tab        ""
      foreach index [lindex $ordered $pane] {
        if {$index ne ""} {
          array set finfo [lindex $content(FileInfo) $index]
          if {[file exists $finfo(fname)]} {
            set tab [add_file end $finfo(fname) \
              -savecommand $finfo(savecommand) -lock $finfo(lock) -readonly $finfo(readonly) \
              -diff $finfo(diff) -sidebar $finfo(sidebar) -lazy 1]
            set txt [get_txt_from_tab $tab]
            if {[[ns syntax]::get_language $txt] ne $finfo(language)} {
              [ns syntax]::set_language $txt $finfo(language)
            }
            if {[info exists finfo(indent)]} {
              [ns indent]::set_indent_mode $tid $finfo(indent)
            }
            if {$finfo(diff) && [info exists finfo(diffdata)]} {
              [ns diff]::set_session_data $txt $finfo(diffdata)
            }
            if {[info exists finfo(cursor)]} {
              ::tk::TextSetCursor $txt.t $finfo(cursor)
            }
            if {[info exists finfo(yview)]} {
              $txt yview $finfo(yview)
            }
            if {[info exists finfo(markers)]} {
              foreach {mname line} $finfo(markers) {
                if {[set tag [ctext::linemapSetMark $txt $line]] ne ""} {
                  [ns markers]::add $txt $tag $mname
                }
              }
            }
          }
        }
      }
      if {$tab ne ""} {
        if {[catch { set_current_tab {*}[get_info [lindex $content(CurrentTabs) $pane] tabindex {tabbar tab}] }]} {
          set_current_tab [get_info $pane paneindex tabbar] $tab
        }
      }
    }

  }

  ######################################################################
  # Makes the next tab in the notebook viewable.
  proc next_tab {} {

    # Get the location information for the current tab in the current pane
    lassign [get_info {} current {tabbar tabindex}] tb index

    # If the new tab index is at the end, circle to the first tab
    if {[incr index] == [$tb index end]} {
      set index 0
    }

    # Select the next tab
    set_current_tab $tb [lindex [$tb tabs -shown] $index]

  }

  ######################################################################
  # Makes the previous tab in the notebook viewable.
  proc previous_tab {} {

    # Get the location information for the current tab in the current pane
    lassign [get_info {} current {tabbar tabindex}] tb index

    # If the new tab index is at the less than 0, circle to the last tab
    if {[incr index -1] == -1} {
      set index [expr [$tb index end] - 1]
    }

    # Select the previous tab
    set_current_tab $tb [lindex [$tb tabs -shown] $index]

  }

  ######################################################################
  # Makes the last viewed tab in the notebook viewable.
  proc last_tab {} {

    # Get the current tabbar
    set tb [get_info {} current tabbar]

    # Select the last tab
    set_current_tab $tb [lindex [$tb tabs -shown] [$tb index last]]

  }

  ######################################################################
  # If more than one pane is displayed, sets the current pane to the other
  # pane.
  proc next_pane {} {

    variable widgets
    variable pw_current

    # If we have more than one pane, go to it
    if {[llength [$widgets(nb_pw) panes]] > 1} {
      set pw_current [expr $pw_current ^ 1]
      set_current_tab {*}[get_info {} current {tabbar tab}]
    }

  }

  ######################################################################
  # Returns the number of panes.
  proc panes {} {

    variable widgets

    return [llength [$widgets(nb_pw) panes]]

  }

  ######################################################################
  # Returns the number of tabs in the current pane.
  proc tabs_in_pane {} {

    return [llength [[get_info {} current tabbar] tabs]]

  }

  ######################################################################
  # Aligns the current insertion cursors in both panes to the same Y
  # pixel value.
  proc align_panes {} {

    align_lines [get_info 0 paneindex txt] [get_info 1 paneindex txt] insert insert 1

  }

  ######################################################################
  # This is called by set_current_tab to update the pane sync state.
  proc pane_sync_tab_change {} {

    variable synced
    variable synced_key

    # Unselect the current key
    if {$synced_key ne ""} {
      catch {
        [winfo parent [lindex $synced_key 0]].vb configure -usealt 0
        [winfo parent [lindex $synced_key 1]].vb configure -usealt 0
      }
      menus::set_pane_sync_indicator 0
      set synced_key ""
    }

    # Set the new pair
    catch {

      # Get the current text widgets
      set txt1 [get_info 0 paneindex txt]
      set txt2 [get_info 1 paneindex txt]

      # Create the synced key
      set key "$txt1 $txt2"

      if {[info exists synced($key)]} {

        menus::set_pane_sync_indicator 1

        set synced_key $key

        [winfo parent $txt1].vb configure -usealt 1
        [winfo parent $txt2].vb configure -usealt 1

      }

    }

  }

  ######################################################################
  # Tracks the two displayed text widgets, keeping their views in line
  # sync with each other.  If initialize is set, we will capture the
  # top lines.
  proc set_pane_sync {value} {

    variable synced
    variable synced_key

    # Get the displayed text widgets
    set txt1 [get_info 0 paneindex txt]
    set txt2 [get_info 1 paneindex txt]

    # Set the menu indicator to the given value
    menus::set_pane_sync_indicator $value

    if {$value} {

      # Record the synced_key (if this value is the empty string, we are not currently synced)
      set synced_key "$txt1 $txt2"

      # Record the text widgets that we are sync'ing
      set synced($synced_key) [list [$txt1 index @0,0] [$txt2 index @0,0]]

      # Set the scrollbar colors to indicate that we are synced
      [winfo parent $txt1].vb configure -usealt 1
      [winfo parent $txt2].vb configure -usealt 1

    } else {

      # Return the scrollbar colors to their normal colors
      [winfo parent [lindex $synced_key 0]].vb configure -usealt 0
      [winfo parent [lindex $synced_key 1]].vb configure -usealt 0

      # Delete the synced recording
      unset synced($synced_key)

      # Clear the synced key
      set synced_key ""

    }

  }

  ######################################################################
  # Called whenever one of the synced text widgets yview changes.  Causes
  # the other text widget to stay in sync.
  proc sync_scroll {txt yscroll} {

    variable synced
    variable synced_key
    variable synced_count
    variable synced_txt

    # If we are not currently synced, return now
    if {($synced_key eq "") || (($synced_txt ne $txt) && ($synced_txt ne ""))} {
      set synced_txt ""
      return
    }

    set top [$txt index @0,0]
    lassign $synced_key          txt0 txt1
    lassign $synced($synced_key) top0 top1

    if {$txt eq $txt0} {
      set line_diff [$txt count -lines $top0 $top]
      align_lines $txt0 $txt1 $top [$txt1 index "$top1+${line_diff}l"] 0
    } else {
      set line_diff [$txt count -lines $top1 $top]
      align_lines $txt1 $txt0 $top [$txt0 index "$top0+${line_diff}l"] 0
    }

    set synced_txt $txt

  }

  ######################################################################
  # Sync the birdseye text widget.
  proc sync_birdseye_helper {txt top} {

    variable be_after_id

    # Get the current tab
    set tab [get_info $txt txt tab]

    if {[winfo exists $tab.be]} {
      $tab.be yview moveto $top
    }

    set be_after_id($txt) ""

  }

  ######################################################################
  # Sync the birdseye text widget.
  proc sync_birdseye {txt top} {

    variable be_after_id
    variable be_ignore

    if {$be_after_id($txt) ne ""} {
      after cancel $be_after_id($txt)
    }

    if {$be_ignore($txt) == 0} {
      set be_after_id($txt) [after 50 [list [ns gui]::sync_birdseye_helper $txt $top]]
    }

    set be_ignore($txt) 0

  }

  ######################################################################
  # Sets the yview of the given text widget (called by the yscrollbar)
  # and adjusts the scroll of the other pane if sync scrolling is enabled.
  proc yview {txt args} {

    # Return the yview information
    if {[llength $args] == 0} {
      return [$txt yview]

    # Otherwise, set the yview given the arguments
    } else {
      $txt yview {*}$args
      sync_birdseye $txt [lindex $args 1]
      sync_scroll   $txt 0
    }

  }

  ######################################################################
  # Implements yscrollcommand for an editing buffer.  Adjusts the scrollbar
  # position and performs synchronized scrolling, if enabled.
  proc yscrollcommand {txt vb args} {

    # Set the vertical scrollbar position
    $vb set {*}$args

    # Set birdseye view
    sync_birdseye $txt [lindex $args 0]

    # Perform sync scrolling, if necessary
    sync_scroll $txt 1

  }

  ######################################################################
  # Aligns the given lines.
  proc align_lines {txt1 txt2 line1 line2 adjust_txt1} {

    if {[set bbox1 [$txt1 bbox $line1]] eq ""} {
      $txt1 see $line1
      set bbox1 [$txt1 bbox $line1]
    }
    if {[set bbox2 [$txt2 bbox $line2]] eq ""} {
      $txt2 see $line2
      set bbox2 [$txt2 bbox $line2]
    }

    # Attempt to line up the right pane to the left pane
    $txt2 yview scroll [expr [lindex $bbox2 1] - [lindex $bbox1 1]] pixels

    # Check to see if the two are aligned, if not then attempt to align the left line to the right
    if {$adjust_txt1} {
      if {[lindex $bbox1 1] != [lindex [$txt2 bbox $line2] 1]} {
        $txt1 yview scroll [expr [lindex $bbox1 1] - [lindex $bbox2 1]] pixels
      }
    }

  }

  ######################################################################
  # Adds the given filename to the list of most recently opened files.
  proc add_to_recently_opened {fname} {

    variable last_opened

    if {[set index [lsearch $last_opened $fname]] != -1} {
      set last_opened [lreplace $last_opened $index $index]
    }

    set last_opened [lrange [list $fname {*}$last_opened] 0 20]

  }

  ######################################################################
  # Returns the last_opened list contents.
  proc get_last_opened {} {

    variable last_opened

    return $last_opened

  }

  ######################################################################
  # Clears the last_opened list contents.
  proc clear_last_opened {} {

    variable last_opened

    set last_opened [list]

  }

  ######################################################################
  # Selects all of the text in the current text widget.
  proc select_all {tid} {

    # Get the current text widget
    set txt [current_txt $tid]

    # Set the selection to include everything
    $txt tag add sel 1.0 end

  }

  ######################################################################
  # Returns true if we have only a single tab that has not been modified
  # or named.
  proc untitled_check {} {

    variable widgets
    variable files
    variable files_index

    # If we have no more tabs and there is another pane, remove this pane
    return [expr {([llength $files] == 1) && \
                  ([lindex $files 0 $files_index(fname)] eq "Untitled") && \
                  [lindex $files 0 $files_index(buffer)] && \
                  ([[ns vim]::get_cleaned_content [get_txt_from_tab [lindex [[lindex [$widgets(nb_pw) panes] 0].tbf.tb tabs] 0]]] eq "")}]

  }

  ######################################################################
  # Adds a new buffer to the editor pane.  Buffers require a save command
  # (executed when the buffer is saved).  Buffers do not save to nor read
  # from files.  Returns the path to the inserted tab.
  #
  # Several options are available:
  # -lock       <bool>     Initial lock setting.
  # -readonly   <bool>     Set if file should not be saveable.
  # -gutters    <list>     Creates a gutter in the editor.  The contents of list are as follows:
  #                          {name {{symbol_name {symbol_tag_options+}}+}}+
  #                        For a list of valid symbol_tag_options, see the options available for
  #                        tags in a text widget.
  # -other      <bool>     If true, adds the file to the other pane.
  # -tags       <list>     List of plugin btags that will only get applied to this text widget.
  # -lang       <language> Specifies the language to use for syntax highlighting.
  # -background <bool>     If true, keeps the current tab displayed.
  # -remote     <name>     If specified, specifies that the buffer should be saved to the given
  #                        remote server name.
  proc add_buffer {index name save_command args} {

    variable files
    variable files_index
    variable pw_current

    # Handle options
    array set opts [list \
      -lock       0 \
      -readonly   0 \
      -gutters    [list] \
      -other      0 \
      -tags       [list] \
      -lang       "" \
      -background 0 \
      -remote     ""
    ]
    array set opts $args

    # Perform untitled tab check
    if {[untitled_check]} {
      if {$name eq "Untitled"} {
        return
      } else {
        close_tab {} [get_info {} current tab] -keeptab 0
      }
    }

    # Check to see if the file is already loaded
    set file_index -1
    if {$name ne "Untitled"} {
      foreach findex [lsearch -all -index $files_index(fname) $files $name] {
        if {[lindex $files $findex $files_index(buffer)]} {
          set file_index $findex
          break
        }
      }
    }

    # If the file is already loaded, display the tab
    if {$file_index != -1} {

      if {!$opts(-background)} {
        lassign [get_info $file_index fileindex {tabbar tab}] tb w
        set_current_tab $tb $w
      }

    } else {

      if {$opts(-other)} {

        # If the other pane does not exist, add it
        if {[llength [$widgets(nb_pw) panes]] == 1} {
          add_notebook
        }

        # Set the current pane to the other one
        set pw_current [expr $pw_current ^ 1]

      }

      # Adjust the index (if necessary)
      set index [adjust_insert_tab_index $index $name]

      # Get the tabbar
      set tb [get_info $pw_current paneindex tabbar]

      # Get the current index
      set w [insert_tab $tb $index $name -gutters $opts(-gutters) -tags $opts(-tags) -lang $opts(-lang)]

      # Create the file info structure
      set file_info [lrepeat [array size files_index] ""]
      lset file_info $files_index(fname)    $name
      lset file_info $files_index(mtime)    ""
      lset file_info $files_index(save_cmd) $save_command
      lset file_info $files_index(tab)      $w
      lset file_info $files_index(lock)     $opts(-lock)
      lset file_info $files_index(readonly) $opts(-readonly)
      lset file_info $files_index(sidebar)  0
      lset file_info $files_index(buffer)   1
      lset file_info $files_index(modified) 0
      lset file_info $files_index(gutters)  $opts(-gutters)
      lset file_info $files_index(diff)     0
      lset file_info $files_index(tags)     $opts(-tags)
      lset file_info $files_index(loaded)   1
      lset file_info $files_index(eol)      [get_eol_translation ""]
      lset file_info $files_index(remember) 0
      lset file_info $files_index(remote)   $opts(-remote)

      # Add the file information to the files list
      lappend files $file_info

      # Get the current text widget
      lassign [get_info $w tab {txt tabbar}] txt tb

      # Perform an insertion adjust, if necessary
      if {[[ns vim]::in_vim_mode $txt.t]} {
        [ns vim]::adjust_insert $txt.t
      }

      # Change the tab text
      $tb tab $w -text " [file tail $name]"

      # Make this tab the currently displayed tab
      if {!$opts(-background)} {
        set_current_tab $tb $w
      }

    }

    # Set the tab image for the current file
    set_tab_image $w

    return $w

  }

  ######################################################################
  # Adds a new file to the editor pane.
  #
  # Several options are available:
  # -lock        <bool>     Initial lock setting.
  # -readonly    <bool>     Set if file should not be saveable.
  # -sidebar     <bool>     Specifies if file/directory should be added to the sidebar.
  # -gutters     <list>     Creates a gutter in the editor.  The contents of list are as follows:
  #                           {name {{symbol_name {symbol_tag_options+}}+}}+
  #                         For a list of valid symbol_tag_options, see the options available for
  #                         tags in a text widget.
  # -other       <bool>     If true, adds the file to the other pane.
  # -tags        <list>     List of plugin btags that will only get applied to this text widget.
  # -name        <path>     Starting name of file (the file doesn't currently exist).
  proc add_new_file {index args} {

    variable files
    variable files_index

    array set opts {
      -sidebar 0
      -name    "Untitled"
    }
    array set opts $args

    # Add the buffer
    set tab [add_buffer $index $opts(-name) {eval [ns gui]::save_new_file $opts(-save_as)} {*}$args]

    # If the sidebar option was set to 1, set it now
    if {$opts(-sidebar)} {
      if {[set index [lsearch -index $files_index(tab) $files $tab]] != -1} {
        lset files $index $files_index(sidebar) 1
      }
    }

    return $tab

  }

  ######################################################################
  # Save command for new files.  Changes buffer into a normal file
  # if the file was actually saved.
  proc save_new_file {save_as file_index} {

    variable files
    variable files_index

    # Set the buffer state to 0 and clear the save command
    if {($save_as ne "") || ([lindex $files $file_index $files_index(fname)] ne "Untitled")} {
      lset files $file_index $files_index(buffer)   0
      lset files $file_index $files_index(save_cmd) ""
      lset files $file_index $files_index(remember) 1
      return 1
    } elseif {[set save_as [prompt_for_save {}]] ne ""} {
      lset files $file_index $files_index(buffer)   0
      lset files $file_index $files_index(save_cmd) ""
      lset files $file_index $files_index(fname)    $save_as
      lset files $file_index $files_index(remember) 1
      return 1
    }

    return -code error "New file was not saved"

  }

  ######################################################################
  # Creates a new tab for the given filename specified at the given index
  # tab position.  Returns the path to the inserted tab.
  #
  # Several options are available:
  # -savecommand <command>  Optional command that is run when the file is saved.
  # -lock        <bool>     Initial lock setting.
  # -readonly    <bool>     Set if file should not be saveable.
  # -sidebar     <bool>     Specifies if file/directory should be added to the sidebar.
  # -gutters     <list>     Creates a gutter in the editor.  The contents of list are as follows:
  #                           {name {{symbol_name {symbol_tag_options+}}+}}+
  #                         For a list of valid symbol_tag_options, see the options available for
  #                         tags in a text widget.
  # -diff        <bool>     Specifies if we need to do a diff of the file.
  # -other       <bool>     If true, adds the file to the other editing pane.
  # -tags        <list>     List of plugin btags that will only attach to this text widget.
  # -remote      <name>     Name of remote connection associated with the file.
  proc add_file {index fname args} {

    variable widgets
    variable files
    variable files_index
    variable pw_current
    variable last_opened

    # Handle arguments
    array set opts {
      -savecommand ""
      -lock        0
      -readonly    0
      -sidebar     1
      -gutters     {}
      -diff        0
      -other       0
      -tags        {}
      -lazy        0
      -remember    1
      -remote      ""
    }
    array set opts $args

    # If have a single untitled tab in view, close it before adding the file
    if {[untitled_check]} {
      close_tab {} [get_info {} current tab] -keeptab 0
    }

    # Check to see if the file is already loaded
    set file_index -1
    foreach findex [lsearch -all -index $files_index(fname) $files $fname] {
      if {[lindex $files $findex $files_index(diff)] == $opts(-diff)} {
        set file_index $findex
        break
      }
    }

    # If the file is already loaded, display the tab
    if {$file_index != -1} {

      # Get the tab associated with the given file index
      lassign [get_info $file_index fileindex {tabbar tab}] tb w

    # Otherwise, load the file in a new tab
    } else {

      if {$opts(-other)} {

        # If the other pane does not exist, add it
        if {[llength [$widgets(nb_pw) panes]] == 1} {
          add_notebook
        }

        # Set the current pane to the other one
        set pw_current [expr $pw_current ^ 1]

      }

      # Adjust the index (if necessary)
      set index [adjust_insert_tab_index $index [file tail $fname]]

      # Get the tabbar
      set tb [get_info $pw_current paneindex tabbar]

      # Add the tab to the editor frame
      set w [insert_tab $tb $index $fname -diff $opts(-diff) -gutters $opts(-gutters) -tags $opts(-tags)]

      # Create the file information
      set file_info [lrepeat [array size files_index] ""]
      lset file_info $files_index(fname)    $fname
      lset file_info $files_index(mtime)    ""
      lset file_info $files_index(save_cmd) $opts(-savecommand)
      lset file_info $files_index(tab)      $w
      lset file_info $files_index(lock)     $opts(-lock)
      lset file_info $files_index(readonly) [expr $opts(-readonly) || $opts(-diff)]
      lset file_info $files_index(sidebar)  $opts(-sidebar)
      lset file_info $files_index(buffer)   0
      lset file_info $files_index(modified) 0
      lset file_info $files_index(gutters)  $opts(-gutters)
      lset file_info $files_index(diff)     $opts(-diff)
      lset file_info $files_index(tags)     $opts(-tags)
      lset file_info $files_index(loaded)   0
      lset file_info $files_index(eol)      [get_eol_translation [expr {($opts(-remote) ne "") ? "" : $fname}]]
      lset file_info $files_index(remember) $opts(-remember)
      lset file_info $files_index(remote)   $opts(-remote)
      lappend files $file_info

      # Run any plugins that should run when a file is opened
      [ns plugins]::handle_on_open [expr [llength $files] - 1]

    }

    # Add the file's directory to the sidebar and highlight it
    if {$opts(-sidebar)} {
      [ns sidebar]::add_directory [file dirname $fname] -remote $opts(-remote)
      [ns sidebar]::highlight_filename $fname [expr ($opts(-diff) * 2) + 1]
    }

    # Make this tab the currently displayed tab
    if {!$opts(-lazy)} {
      set_current_tab $tb $w
    }

    # Set the tab image for the current file
    set_tab_image $w

    return $w

  }

  ######################################################################
  # Inserts the file information and sets the
  proc add_tab_content {tab} {

    variable files
    variable files_index

    # Get some of the file information
    lassign [get_info $tab tab {fileindex txt tabbar tab fname loaded diff remote}] file_index txt tb tab fname loaded diff remote

    # Only add the tab content if it has not been done
    if {!$loaded} {

      # Specify that this tab is loaded
      lset files $file_index $files_index(loaded) 1

      set okay 0

      # Get the file contents
      if {$remote ne ""} {
        $tb tab $tab -busy 1
        set okay [[ns remote]::get_file $remote $fname contents modtime]
        $tb tab $tab -busy 0
      } elseif {![catch { open $fname r } rc]} {
        set contents [string range [read $rc] 0 end-1]
        set okay     1
        close $rc
      }

      if {$okay} {

        # Delete any dspace characters
        [ns vim]::remove_dspace $txt

        # Read the file contents and insert them
        $txt fastinsert end $contents

        # Highlight text and add update code folds
        $txt highlight 1.0 end
        $txt see 1.0

        # Check brackets
        [ns completer]::check_all_brackets $txt.t

        # Change the text to unmodified
        $txt edit reset
        lset files $file_index $files_index(modified) 0

        # Set the insertion mark to the first position
        ::tk::TextSetCursor $txt.t 1.0

        # Perform an insertion adjust, if necessary
        if {[[ns vim]::in_vim_mode $txt.t]} {
          [ns vim]::adjust_insert $txt.t
        }

        if {[lindex $files $file_index $files_index(remote)] eq ""} {
          file stat $fname stat
          lset files $file_index $files_index(mtime) $stat(mtime)
        } else {
          lset files $file_index $files_index(mtime) $modtime
        }

        # Add the file to the list of recently opened files
        add_to_recently_opened $fname

        # Parse Vim modeline information, if needed
        [ns vim]::parse_modeline $txt

        # If a diff command was specified, run and parse it now
        if {$diff} {
          [ns diff]::show $txt
        }

      }

      # Change the tab text
      $tb tab $tab -text " [file tail $fname]"

    }

  }

  ######################################################################
  # Normalizes the given filename and resolves any NFS mount information if
  # the specified host is not the current host.
  proc normalize {host fname} {

    # Perform a normalization of the file
    set fname [file normalize $fname]

    # If the host does not match our host, handle the NFS mount normalization
    if {$host ne [info hostname]} {
      array set nfs_mounts [[ns preferences]::get NFSMounts]
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
      if {[file isdirectory $fname]} {
        [ns sidebar]::add_directory [normalize $host $fname]
      } else {
        add_file $index [normalize $host $fname]
      }
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

    variable files
    variable files_index

    # Get the file information
    lassign [get_info $file_index fileindex {tabbar tab txt fname diff lock remote}] tb tab txt fname diff lock remote

    # If the editor is a difference view and is not updateable, stop now
    if {$diff && ![[ns diff]::updateable $txt]} {
      return
    }

    # Get the current insertion index
    set insert_index [$txt index insert]

    # Delete the text widget
    $txt configure -state normal
    $txt delete 1.0 end

    set okay 0

    # Read the contents of the file
    if {$remote ne ""} {
      set okay [[ns remote]::get_file $remote $fname contents modtime]
    } elseif {![catch { open $fname r } rc]} {
      set contents [string range [read $rc] 0 end-1]
      set okay     1
      close $rc
    }

    if {$okay} {

      # Read the file contents and insert them
      $txt insert end $contents

      # Change the tab text
      $tb tab $tab -text " [file tail $fname]"

      # Update the title bar (if necessary)
      set_title

      # Change the text to unmodified
      $txt edit reset
      lset files $file_index $files_index(modified) 0

      # Set the insertion mark to the first position
      ::tk::TextSetCursor $txt.t $insert_index
      if {[[ns vim]::in_vim_mode $txt.t]} {
        [ns vim]::adjust_insert $txt.t
      }

      # If a diff command was specified, run and parse it now
      if {$diff} {
        [ns diff]::show $txt
      }

      # Allow plugins to be run on update
      [ns plugins]::handle_on_update $file_index

    }

    # If we are locked, set our state back to disabled
    if {$lock} {
      $txt configure -state disabled
    }

  }

  ######################################################################
  # Updates the currently displayed file.
  proc update_current {} {

    update_file [get_info {} current fileindex]

  }

  ######################################################################
  # Prompts the user for a file save name.  Returns the name of the selected
  # filename; otherwise, returns the empty string to indicate that no
  # filename was selected.
  proc prompt_for_save {tid} {

    # Get the directory of the current file
    set dirname [gui::get_browse_directory]

    # Get the list of save options
    set save_opts [list]
    if {[llength [set extensions [[ns syntax]::get_extensions $tid]]] > 0} {
      lappend save_opts -defaultextension [lindex $extensions 0]
    }

    # Get the save file from the user
    return [tk_getSaveFile {*}$save_opts -parent . -title [msgcat::mc "Save As"] -initialdir $dirname]

  }

  ######################################################################
  # Performs a forced pre-save operation for the given filename.
  proc save_prehandle {fname save_as force pperms} {

    upvar $pperms perms

    set perms ""

    if {[file exists $fname]} {
      if {$save_as eq ""} {
        if {![file writable $fname]} {
          if {$force} {
            set perms [file attributes $fname -permissions]
            if {[catch { file attributes $fname -permissions 700 } rc]} {
              set_info_message [msgcat::mc "No write permissions.  Use '!' to force write."]
              return 0
            }
          } else {
            set_info_message [msgcat::mc "No write permissions.  Use '!' to force write."]
            return 0
          }
        }
      } elseif {!$force} {
        set_info_message [msgcat::mc "File already exists.  Use '!' to force an overwrite"]
        return 0
      }
    }

    return 1

  }

  ######################################################################
  # Performs a forced post-save operation for the given filename.
  proc save_posthandle {fname perms} {

    if {$perms ne ""} {
      catch { file attributes $fname -permissions $perms }
    }

    return 1

  }

  ######################################################################
  # Returns the index of the index that matches the given filename.  If
  # no entry matches, returns -1.
  proc find_matching_file_index {fname remote} {

    variable files
    variable files_index

    # Get the indices that match the given filename
    set file_indices   [lsearch -all -index $files_index(fname)  $files $fname]
    set diff_indices   [lsearch -all -index $files_index(diff)   $files 0]
    set remote_indices [lsearch -all -index $files_index(remote) $files $remote]

    set matching_index [::struct::set intersect $file_indices $diff_indices $remote_indices]

    if {[llength $matching_index] == 0} {
      return -1
    } else {
      return $matching_index
    }

  }

  ######################################################################
  # Returns the EOL translation to use for the given file.
  proc get_eol_translation {fname} {

    variable files
    variable files_index

    set type [expr {($fname eq "") ? "sys" : [[ns preferences]::get Editor/EndOfLineTranslation]}]

    switch $type {
      auto    { return [utils::get_eol_char $fname] }
      sys     { return [expr {($::tcl_platform(platform) eq "windows") ? "crlf" : "lf"}] }
      default { return $type }
    }

  }

  ######################################################################
  # Sets the EOL translation setting for the current file to the given value.
  proc set_current_eol_translation {value} {

    variable files
    variable files_index

    # Get the file index of the current file
    set index [get_info {} current fileindex]

    # Set the EOL translation setting
    lset files $index $files_index(eol) $value

  }

  ######################################################################
  # Sets the current text status modification value to the specified value
  # and updates the titlebar and tabbar
  proc set_current_modified {value} {

    variable files
    variable files_index

    # Get the current file information
    lassign [get_info {} current {tabbar fileindex txt fname}] tb file_index txt fname

    # Set the file modified status to the given value
    lset files $file_index $files_index(modified) $value

    # Set the text widget status
    $txt edit modified $value

    # Update the current tab text
    $tb tab current -text [format "%s %s" [expr {$value ? " *" : ""}] [file tail $fname]]

    # Update the title
    set_title

  }

  ######################################################################
  # Saves the current tab contents.  Returns 1 if the save was successful;
  # otherwise, returns a value of 0.
  proc save_current {tid args} {

    variable files
    variable files_index

    array set opts {
      -force   0
      -save_as ""
      -remote  ""
    }
    array set opts $args

    # Get current information
    lassign [get_info {} current {tabbar txt fileindex buffer save_cmd diff buffer}] tb txt file_index buffer save_cmd diff buffer

    # If the current file is a buffer and it has a save command, run the save command
    if {$buffer && ($save_cmd ne "")} {

      # Execute the save command.  If it errors or returns a value of 0, return immediately
      if {[catch { {*}$save_cmd $file_index } rc]} {

        return 0

      } elseif {$rc == 0} {

        # Change the tab text
        $tb tab current -text " [file tail [lindex $files $file_index $files_index(fname)]]"
        set_title

        # Change the text to unmodified
        $txt edit modified false
        lset files $file_index $files_index(modified) 0

        return 1

      }

    }

    # Get the difference mode of the current file
    set matching_index -1

    # If a save_as name is specified, change the filename
    if {$opts(-save_as) ne ""} {
      [ns sidebar]::highlight_filename [lindex $files $file_index $files_index(fname)] [expr $diff * 2]
      set matching_index [find_matching_file_index $opts(-save_as) $opts(-remote)]
      lset files $file_index $files_index(fname)  $opts(-save_as)
      lset files $file_index $files_index(remote) $opts(-remote)

    # If the current file doesn't have a filename, allow the user to set it
    } elseif {[lindex $files $file_index $files_index(buffer)] || $diff} {
      if {[set sfile [prompt_for_save $tid]] eq ""} {
        return 0
      } else {
        set matching_index [find_matching_file_index $sfile ""]
        lset files $file_index $files_index(fname) $sfile
      }
    }

    # Make is easier to refer to the filename
    set fname [lindex $files $file_index $files_index(fname)]

    # Run the on_save plugins
    [ns plugins]::handle_on_save $file_index

    # If we need to do a force write, do it now
    set perms ""
    if {![save_prehandle $fname $opts(-save_as) $opts(-force) perms]} {
      return 0
    }

    # If the file already exists in one of the open tabs, close it now
    if {$matching_index != -1} {
      close_tab $tid [lindex $files $matching_index $files_index(tab)] -keeptab 0 -check 0
    }

    # Save the file contents
    if {[lindex $files $file_index $files_index(remote)] ne ""} {

      if {![[ns remote]::save_file [lindex $files $file_index $files_index(remote)] [lindex $files $file_index $files_index(fname)] [scrub_text $txt] modtime]} {
        set_error_message [msgcat::mc "Unable to write remote file"] ""
        return 0
      }

    } else {

      if {[catch { open [lindex $files $file_index $files_index(fname)] w } rc]} {
        set_error_message [msgcat::mc "Unable to write file"] $rc
        return 0
      }

      # Write the file contents
      catch { fconfigure $rc -translation [lindex $files $file_index $files_index(eol)] }
      puts $rc [scrub_text $txt]
      close $rc

    }

    # If we need to do a force write, do it now
    if {![save_posthandle $fname $perms]} {
      return 0
    }

    # If the file doesn't have a timestamp, it's a new file so add and highlight it in the sidebar
    if {([lindex $files $file_index $files_index(mtime)] eq "") || ($opts(-save_as) ne "")} {

      # Calculate the normalized filename
      set fname [file normalize [lindex $files $file_index $files_index(fname)]]

      # Add the filename to the most recently opened list
      add_to_recently_opened $fname

      # If it is okay to add the file to the sidebar, do it now
      if {[lindex $files $file_index $files_index(sidebar)]} {

        # Add the file's directory to the sidebar
        [ns sidebar]::insert_file [[ns sidebar]::add_directory [file dirname $fname] -remote $opts(-remote)] $fname $opts(-remote)

        # Highlight the file in the sidebar
        [ns sidebar]::highlight_filename [lindex $files $file_index $files_index(fname)] [expr ($diff * 2) + 1]

      }

      # Syntax highlight the file
      [ns syntax]::set_language $txt [syntax::get_default_language [lindex $files $file_index $files_index(fname)]]

    }

    # Update the timestamp
    if {[lindex $files $file_index $files_index(remote)] eq ""} {
      file stat [lindex $files $file_index $files_index(fname)] stat
      lset files $file_index $files_index(mtime) $stat(mtime)
    } else {
      lset files $file_index $files_index(mtime) $modtime
    }

    # Change the tab text
    $tb tab current -text " [file tail [lindex $files $file_index $files_index(fname)]]"
    set_title

    # Change the text to unmodified
    $txt edit modified false
    lset files $file_index $files_index(modified) 0

    # If there is a save command, run it now
    if {[set save_cmd [lindex $files $file_index $files_index(save_cmd)]] ne ""} {
      eval {*}$save_cmd $file_index
    }

    return 1

  }

  ######################################################################
  # Saves all of the opened tab contents (if necessary).  If a tab has
  # not been previously saved (a new file), that tab is made the current
  # tab and the save_current procedure is called.
  proc save_all {} {

    variable files
    variable files_index

    for {set i 0} {$i < [llength $files]} {incr i} {

      # Get file information
      lassign [get_info $i fileindex {tabbar tab txt fname modified diff save_cmd buffer}] tb tab txt fname modified diff save_cmd buffer

      # If the file needs to be saved, do it
      if {$modified && !$diff} {

        # If the file needs to be saved as a new filename, call the save_current
        # procedure
        if {$buffer && ($save_cmd ne "")} {

          # Run the save command and if it ran successfully,
          if {[catch { {*}$save_cmd $i } rc]} {

            continue

          } elseif {$rc == 0} {

            # Change the tab text
            $tb tab $tab -text " [file tail $fname]"

            # Change the text to unmodified
            $txt edit modified false
            lset files $i $files_index(modified) 0

          # Save the current
          } else {

            set_current_tab $tb $tab -skip_check 1
            save_current {} -force 1

          }

        # Perform a tab-only save
        } else {

          # Run the on_save plugins
          [ns plugins]::handle_on_save $i

          # Save the file contents
          if {[catch { open $fname w } rc]} {
            continue
          }

          # Write the file contents
          catch { fconfigure $rc -translation [lindex $files $i $files_index(eol)] }
          puts $rc [scrub_text $txt]
          close $rc

          # Update the timestamp
          file stat $fname stat
          lset files $i $files_index(mtime) $stat(mtime)

          # Change the tab text
          $tb tab $tab -text " [file tail $fname]"

          # Change the text to unmodified
          $txt edit modified false
          lset files $i $files_index(modified) 0

          # If there is a save command, run it now
          if {$save_cmd ne ""} {
            eval {*}$save_cmd $i
          }
        }

      }

    }

    # Make sure that the title is consistent
    set_title

  }

  ######################################################################
  # Returns 1 if the tab is closable; otherwise, returns a value of 0.
  # Saves the tab if it needs to be saved.
  proc close_check {tid tab force exiting} {

    variable files
    variable files_index

    # Get the tab information
    lassign [get_info $tab tab {tabbar fname modified diff}] tb fname modified diff

    # If the file needs to be saved, do it now
    if {$modified && !$diff && !$force} {
      set fname [file tail $fname]
      set msg   [format "%s %s?" [msgcat::mc "Save"] $fname]
      set_current_tab $tb $tab
      if {[set answer [tk_messageBox -default yes -type [expr {$exiting ? {yesno} : {yesnocancel}}] -message $msg -title [msgcat::mc "Save request"]]] eq "yes"} {
        return [save_current $tid -force $force]
      } elseif {$answer eq "cancel"} {
        return 0
      }
    }

    return 1

  }

  ######################################################################
  # Returns 1 if the tab is closable; otherwise, returns a value of 0.
  # Saves the tab if it needs to be saved.
  proc close_check_by_tabbar {tid w tab} {

    return [close_check $tid $tab 0 0]

  }

  ######################################################################
  # Close the current tab.  If force is set to 1, closes regardless of
  # modified state of text widget.  If force is set to 0 and the text
  # widget is modified, the user will be questioned if they want to save
  # the contents of the file prior to closing the tab.
  proc close_current {tid {force 0} {exiting 0}} {

    close_tab $tid [get_info {} current tab] -force $force -exiting $exiting

  }


  ######################################################################
  # Closes the tab specified by "tab".  This is called by the tabbar when
  # the user clicks on the close button of a tab.
  proc close_tab_by_tabbar {w tab} {

    # Close the tab specified by tab (we don't need to check because the check
    # will have already been performed with the -checkcommand passed to the
    # tabbar.
    close_tab {} $tab -tabbar $w -check 0

    return 1

  }

  ######################################################################
  # Close the specified tab (do not ask the user about closing the tab).
  proc close_tab {tid tab args} {

    variable widgets
    variable files
    variable pw_current

    array set opts {
      -exiting 0
      -keeptab 1
      -lazy    0
      -force   0
      -check   1
      -tabbar  ""
    }
    array set opts $args

    # Get the tab information (we need to get the pane and tabbar information
    if {$opts(-tabbar) ne ""} {
      set pane [winfo parent [winfo parent $opts(-tabbar)]]
      set tb   $opts(-tabbar)
      lassign [get_info $tab tab {fileindex fname diff}] index fname diff
    } else {
      lassign [get_info $tab tab {pane tabbar tabindex fileindex fname diff}] pane tb tab_index index fname diff
    }

    # Perform save check on close
    if {$opts(-check)} {
      close_check $tid $tab $opts(-force) $opts(-exiting)
    }

    # Unhighlight the file in the file browser (if the file was not a difference view)
    [ns sidebar]::highlight_filename $fname [expr $diff * 2]

    # Run the close event for this file
    [ns plugins]::handle_on_close $index

    # Delete the file from files
    set files [lreplace $files $index $index]

    # Remove the tab from the tabbar (unless this has already been done by the tabbar)
    if {$opts(-tabbar) eq ""} {
      $tb delete $tab_index
    }

    # Delete the text frame
    catch { pack forget $tab }

    # Destroy the text frame
    destroy $tab

    # Display the current pane (if one exists)
    if {!$opts(-lazy) && ([set tab [$tb select]] ne "")} {
      set_current_tab $tb $tab
    }

    # If we have no more tabs and there is another pane, remove this pane
    if {([llength [$tb tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] > 1)} {
      $widgets(nb_pw) forget $pane
      set pw_current 0
      set tb         [get_info 0 paneindex tabbar]
    }

    # Add a new file if we have no more tabs, we are the only pane, and the preference
    # setting is to not close after the last tab is closed.
    if {([llength [$tb tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] == 1) && !$opts(-exiting)} {
      if {[[ns preferences]::get General/ExitOnLastClose] || $::cl_exit_on_close} {
        [ns menus]::exit_command
      } elseif {$opts(-keeptab)} {
        add_new_file end
      }
    }

  }

  ######################################################################
  # Close all tabs but the current tab.
  proc close_others {} {

    variable widgets
    variable pw_current

    set current_pw [get_info $pw_current paneindex pane]

    foreach nb [lreverse [$widgets(nb_pw) panes]] {
      foreach tab [lreverse [$nb.tbf.tb tabs]] {
        if {($nb ne $current_pw) || ($tab ne [$nb.tbf.tb select])} {
          close_tab {} $tab -lazy 1
        }
      }
    }

    # Set the current tab
    set_current_tab {*}[get_info {} current {tabbar tab}]

  }

  ######################################################################
  # Close all of the tabs.
  proc close_all {{force 0} {exiting 0}} {

    variable widgets

    foreach nb [lreverse [$widgets(nb_pw) panes]] {
      foreach tab [lreverse [$nb.tbf.tb tabs]] {
        close_tab {} $tab -force $force -exiting $exiting -lazy 1
      }
    }

  }

  ######################################################################
  # Closes the tab with the identified name (if it exists).
  proc close_files {fnames} {

    if {[llength $fnames] > 0} {

      # Perform a lazy close
      foreach fname $fnames {
        catch { close_tab {} [get_info $fname fname tab] -lazy 1 }
      }

      # Set the current tab
      set_current_tab {*}[get_info {} current {tabbar tab}]

    }

  }

  ######################################################################
  # Closes all of the opened files that exist within the given directories
  proc close_dir_files {dirs} {

    variable files
    variable files_index

    set set_current 0

    foreach dir $dirs {
      foreach index [lreverse [lsearch -all -index $files_index(fname) $files $dir*]] {
        close_tab {} [get_info $index fileindex tab] -lazy 1
        set set_current 1
      }
    }

    # Set the current tab if we have lost it
    if {$set_current} {
      set_current_tab {*}[get_info {} current {tabbar tab}]
    }

  }

  ######################################################################
  # Hides the given tab.
  proc hide_tab {tab args} {

    variable widgets

    array set opts {
      -lazy 0
    }
    array set opts $args

    # Get the current tabbar
    lassign [get_info $tab tab {tabbar fname remote}] tb fname remote

    # Hide the tab
    $tb tab $tab -state hidden

    if {!$opts(-lazy)} {
      set_current_tab $tb [$tb select] -changed 1
    }

    # Make sure the sidebar is updated properly
    [ns sidebar]::set_hide_state $fname $remote 1

    return $tb

  }

  ######################################################################
  # Shows the given tab.
  proc show_tab {tab args} {

    variable widgets

    array set opts {
      -lazy 0
    }
    array set opts $args

    # Get the current tabbar
    lassign [get_info $tab tab {tabbar fname remote}] tb fname remote

    # Show the tab
    $tb tab $tab -state normal

    if {!$opts(-lazy)} {
      set_current_tab $tb [$tb select] -changed 1
    }

    # Make sure the sidebar is updated properly
    [ns sidebar]::set_hide_state $fname $remote 0

    return $tb

  }

  ######################################################################
  # Hides the current tab.
  proc hide_current {tid} {

    # Get the current tabbar and tab
    hide_tab [get_info {} current tab]

  }

  ######################################################################
  # Hides all of the files with the given filenames.
  proc hide_files {fnames} {

    if {[llength $fnames] > 0} {

      # Perform a lazy close
      foreach fname $fnames {
        set tbs([hide_tab [get_info $fname fname tab] -lazy 1]) 1
      }

      # Set the current tab
      foreach tb [array names tbs] {
        set_current_tab $tb [$tb select] -changed 1
      }

    }

  }

  ######################################################################
  # Hides all of the opened files.
  proc hide_all {} {

    hide_files [get_fnames]

  }

  ######################################################################
  # Shows all of the files with the given filenames.
  proc show_files {fnames} {

    if {[llength $fnames] > 0} {

      # Perform a lazy show
      foreach fname $fnames {
        set tbs([show_tab [get_info $fname fname tab] -lazy 1]) 1
      }

      # Set the current tab
      foreach tb [array names tbs] {
        set_current_tab $tb [$tb select] -changed 1
      }

    }

  }

  ######################################################################
  # Shows all of the files.
  proc show_all {} {

    show_files [get_fnames]

  }

  ######################################################################
  # Sorts all of the open tabs (in both panes, if both panes are visible)
  # by alphabetical order.
  proc sort_tabs {} {

    variable widgets
    variable files
    variable files_index

    foreach nb [$widgets(nb_pw) panes] {

      lassign [get_info $nb pane {tabbar tab}] tb current_tab

      # Get the list of opened tabs
      set tabs [list]
      foreach tab [$tb tabs] {
        set fullname [$tb tab $tab -text]
        regexp {(\S+)$} $fullname -> name
        lappend tabs [list $name $fullname $tab [lsearch -index $files_index(tab) $files $tab]]
        $tb delete $tab
      }

      # Sort the tabs by alphabetical order and move them
      foreach tab [lsort -index 0 $tabs] {
        lassign $tab name fullname tabid index
        $tb insert end $tabid -text $fullname -emboss 0
      }

      # Reset the current tab
      $tb select $current_tab

    }

  }

  ######################################################################
  # Moves the current notebook tab to the other notebook pane.  If the
  # other notebook pane is not displayed, create it and display it.
  proc move_to_pane {} {

    variable widgets
    variable pw_current

    # Get the list of panes
    set panes [$widgets(nb_pw) panes]

    # If the other pane does not exist, add it
    if {[llength $panes] == 1} {
      add_notebook
      set panes [$widgets(nb_pw) panes]
    }

    # Get information
    lassign [get_info {} current {pane tabbar tab tabindex}] pane tb current_tab tab_index

    # Get the current title
    set title [$tb tab $tab_index -text]

    # Remove the tab from the tabbar
    $tb delete $tab_index

    # Remove the tab from the current pane
    catch { pack forget $current_tab }

    # Display the current pane (if one exists)
    if {[set tab [$tb select]] ne ""} {
      set_current_tab $tb $tab
      set pw_current [expr $pw_current ^ 1]
    } else {
      $widgets(nb_pw) forget $pane
      set pw_current 0
    }

    # Get the other tabbar
    set tb [get_info {} current tabbar]

    # Make sure that tabbar is visible
    grid $tb

    # Add the new tab to the notebook in alphabetical order (if specified)
    if {[[ns preferences]::get View/OpenTabsAlphabetically]} {
      set added 0
      foreach t [$tb tabs] {
        if {[string compare $title [$tb tab $t -text]] == -1} {
          $tb insert $t $current_tab -text $title -emboss 0
          set added 1
          break
        }
      }
      if {$added == 0} {
        $tb insert end $current_tab -text $title -emboss 0
      }

    # Otherwise, add the tab in the specified location
    } else {
      $tb insert end $current_tab -text $title -emboss 0
    }

    # Now move the current tab from the previous current pane to the new current pane
    set_current_tab $tb $current_tab -skip_focus 1 -skip_check 1

    # Set the tab image for the moved file
    set_tab_image $current_tab

  }

  ######################################################################
  # Merges both panes into one.
  proc merge_panes {} {

    variable widgets
    variable pw_current

    while {[llength [$widgets(nb_pw) panes]] == 2} {

      # Make the second pane the current pane
      set pw_current 1

      # Move the pane
      move_to_pane

    }

  }

  ######################################################################
  # Performs an undo of the current tab.
  proc undo {tid} {

    # Get the current textbox
    set txt [current_txt $tid]

    # Perform the undo operation from Vim perspective
    [ns vim]::undo $txt.t

  }

  ######################################################################
  # Returns true if there is something in the undo buffer.
  proc undoable {tid} {

    # Get the current textbox
    set txt [current_txt $tid]

    return [$txt edit undoable]

  }

  ######################################################################
  # This procedure performs an redo operation.
  proc redo {tid} {

    # Get the current textbox
    set txt [current_txt $tid]

    # Perform the redo operation from Vim perspective
    [ns vim]::redo $txt.t

  }

  ######################################################################
  # Returns true if there is something in the redo buffer.
  proc redoable {tid} {

    # Get the current textbox
    set txt [current_txt $tid]

    return [$txt edit redoable]

  }

  ######################################################################
  # Cuts the currently selected text.
  proc cut {tid} {

    # Perform the cut
    [current_txt $tid] cut

    # Add the clipboard contents to history
    [ns cliphist]::add_from_clipboard

  }

  ##############################################################################
  # This procedure performs a text selection copy operation.
  proc copy {tid} {

    # Perform the copy
    [current_txt $tid] copy

    # Add the clipboard contents to history
    [ns cliphist]::add_from_clipboard

  }

  ######################################################################
  # Returns true if text is currently selected in the current buffer.
  proc selected {tid} {

    if {([set txt [current_txt $tid]] ne "") && \
        ([llength [$txt tag ranges sel]] > 0)} {
      return 1
    } else {
      return 0
    }

  }

  ##############################################################################
  # This procedure performs a text selection paste operation.  Returns 1 if the
  # paste operation was performed on the current text widget; otherwise, returns 0.
  proc paste {tid} {

    # Get the current text widget
    set txt [current_txt $tid]

    # If the current txt widget has the focus, paste clipboard contents to it and record the
    # paste with the Vim namespace.
    if {[focus] eq "$txt.t"} {

      # Perform the paste
      $txt paste

      # Handle the Vim paste
      [ns vim]::handle_paste $txt

      return 1

    }

    return 0

  }

  ######################################################################
  # This procedure performs a paste operation, formatting the pasted text
  # to match the code that it is being pasted into.
  proc paste_and_format {tid} {

    if {![catch {clipboard get}]} {

      # Get the length of the clipboard text
      set cliplen [string length [clipboard get]]

      # Get the position of the insertion cursor
      set insertpos [[current_txt $tid] index insert]

      # Perform the paste operation
      if {[paste $tid]} {

        # Have the indent namespace format the clipboard contents
        [ns indent]::format_text [current_txt $tid].t $insertpos "$insertpos+${cliplen}c"

      }

    }

  }

  ######################################################################
  # Returns true if there is something in the paste buffer and the current
  # editor is editable.
  proc pastable {tid} {

    return [expr {![catch {clipboard get} contents] && ($contents ne "") && [editable $tid]}]

  }

  ######################################################################
  # Returns true if the current editor is editable.
  proc editable {tid} {

    return [expr {[[current_txt $tid] cget -state] eq "normal"}]

  }

  ######################################################################
  # Formats either the selected text (if type is "selected") or the entire
  # file contents (if type is "all").
  proc format_text {tid} {

    variable files
    variable files_index

    # Get the file information
    lassign [get_info {} current {tabbar txt fileindex fname lock readonly}] tb txt file_index fname lock readonly

    # Get the locked/readonly status
    set readonly [expr $lock || $readonly]

    # If the file is locked or readonly, set the state so that it can be modified
    if {$readonly} {
      $txt configure -state normal
    }

    # If any text is selected, format it
    if {[llength [set selected [$txt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse [$txt tag ranges sel]] {
        [ns indent]::format_text $txt.t $startpos $endpos
      }

    # Otherwise, select the full file
    } else {
      [ns indent]::format_text $txt.t 1.0 end
    }

    # If the file is locked or readonly, clear the modified state and reset the text state
    # back to disabled
    if {$readonly} {

      # Clear the modified state and reset the state
      $txt edit modified false
      $txt configure -state disabled

      # Change the tab text
      $tb tab current -text " [file tail $fname]"
      set_title

      # Change the text to unmodified
      lset files $file_index $files_index(modified) 0

    }

  }

  ######################################################################
  # Displays the search bar.
  proc search {tid {dir "next"}} {

    variable saved

    # Get the tab information
    lassign [get_info {} current {tab txt}] tab txt

    # Display the search bar and separator
    grid $tab.sf
    grid $tab.sep1

    # Add bindings
    bind $tab.sf.e    <Return> [list [ns search]::find_start $tid $dir]
    bind $tab.sf.e    <Return> [list [ns search]::find_start $tid $dir]
    bind $tab.sf.case <Return> [list [ns search]::find_start $tid $dir]
    bind $tab.sf.save <Return> [list [ns search]::find_start $tid $dir]

    # Clear the search entry
    $tab.sf.e delete 0 end

    # Reset the saved indicator
    set saved 0

    # If a line or less is selected, populate the search bar with it
    if {([llength [set ranges [$txt tag ranges sel]]] == 2) && ([$txt count -lines {*}$ranges] == 0)} {
      $tab.sf.e insert end [$txt get {*}$ranges]
    }

    # Place the focus on the search bar
    focus $tab.sf.e

  }

  ######################################################################
  # Closes the search widget.
  proc close_search {} {

    # Get the current text frame
    set tab [get_info {} current tab]

    # Hide the search frame
    grid remove $tab.sf
    grid remove $tab.sep1

    # Put the focus on the text widget
    set_txt_focus [last_txt_focus {}]

  }

  ######################################################################
  # Displays the search and replace bar.
  proc search_and_replace {} {

    variable saved

    # Get the tab information
    lassign [get_info {} current {tab txt}] tab txt

    # Display the search bar and separator
    grid $tab.rf
    grid $tab.sep1

    # Clear the search entry
    $tab.rf.fe delete 0 end
    $tab.rf.re delete 0 end

    # Reset the saved indicator
    set saved 0

    # If a line or less is selected, populate the find entry with it
    if {([llength [set ranges [$txt tag ranges sel]]] == 2) && ([$txt count -lines {*}$ranges] == 0)} {
      $tab.rf.fe insert end [$txt get {*}$ranges]
    }

    # Place the focus on the find entry field
    focus $tab.rf.fe

  }

  ######################################################################
  # Closes the search and replace bar.
  proc close_search_and_replace {} {

    # Get the current tab
    set tab [get_info {} current tab]

    # Hide the search and replace bar
    grid remove $tab.rf
    grid remove $tab.sep1

    # Put the focus on the text widget
    set_txt_focus [last_txt_focus {}]

  }

  ######################################################################
  # Retrieves the current search information for the specified type.
  proc get_search_data {type} {

    variable widgets
    variable case_sensitive
    variable replace_all
    variable saved

    # Get the current tab
    set tab [get_info {} current tab]

    switch $type {
      "find"    { return [list [$tab.sf.e get] $case_sensitive $saved] }
      "replace" { return [list [$tab.rf.fe get] [$tab.rf.re get] $case_sensitive $replace_all $saved] }
      "fif"     { return [list [$widgets(fif_find) get] [$widgets(fif_in) tokenget] $case_sensitive $saved] }
    }

  }

  ######################################################################
  # Sets the given search information in the current search widget based
  # on type.
  proc set_search_data {type data} {

    variable widgets
    variable case_sensitive
    variable replace_all
    variable saved

    # Get the current tab
    set tab [get_info {} current tab]

    switch $type {
      "find" {
        lassign $data str case_sensitive saved
        $tab.sf.e delete 0 end
        $tab.sf.e insert end $str
      }
      "replace" {
        lassign $data find replace case_sensitive replace_all saved
        $tab.rf.fe delete 0 end
        $tab.rf.re delete 0 end
        $tab.rf.fe insert end $find
        $tab.rf.re insert end $replace
      }
      "fif" {
        lassign $data find in case_sensitive saved
        $widgets(fif_find) delete 0 end
        $widgets(fif_find) insert end $find
        $widgets(fif_in) tokendelete 0 end
        $widgets(fif_in) tokeninsert end $in
      }
    }

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
  # Sets the file lock to the specified value for the current file.
  proc set_tab_image {tab} {

    variable files
    variable files_index

    # Get the tab information
    lassign [get_info $tab tab {tabbar txt diff readonly lock}] tb txt diff readonly lock

    # Change the state of the text widget to match the lock value
    if {$diff} {
      $tb  tab $tab -compound left -image tab_diff
      $txt configure -state disabled
    } elseif {$readonly} {
      $tb  tab $tab -compound left -image tab_readonly
      $txt configure -state disabled
    } elseif {$lock} {
      $tb  tab $tab -compound left -image tab_lock
      $txt configure -state disabled
    } else {
      $tb  tab $tab -image ""
      $txt configure -state normal
    }

    return 1

  }

  ######################################################################
  # Sets the file lock to the specified value for the current file.
  proc set_current_file_lock {tid lock} {

    variable files
    variable files_index

    # Get the current tab information
    lassign [get_info {} current {tab fileindex}] tab file_index

    # Set the current lock status
    lset files $file_index $files_index(lock) $lock

    # Set the tab image to match
    set_tab_image $tab

  }

  ######################################################################
  # Sets the file lock of the current editor with the value of the file_locked
  # local variable.
  proc set_current_file_lock_with_current {tid} {

    variable file_locked

    set_current_file_lock $tid $file_locked

  }

  ######################################################################
  # Set or clear the favorite status of the current file.
  proc set_current_file_favorite {tid favorite} {

    # Get the current file name
    set fname [get_info {} current fname]

    # Add or remove the file from the favorites list
    if {$favorite} {
      [ns favorites]::add $fname
    } else {
      [ns favorites]::remove $fname
    }

  }

  ######################################################################
  # Sets the file favorite of the current editor with the value of the
  # file_favorited local variable.
  proc set_current_file_favorite_with_current {tid} {

    variable file_favorited

    set_current_file_favorite $tid $file_favorited

  }

  ######################################################################
  # Shows the current file in the sidebar.
  proc show_current_in_sidebar {} {

    lassign [get_info {} current {fname remote}] fname remote

    # Display the file in the sidebar
    [ns sidebar]::view_file $fname $remote

  }

  ######################################################################
  # Sets the current information message to the given string.
  proc set_info_message {msg {clear_delay 3000}} {

    variable widgets
    variable info_clear

    if {[info exists widgets(info_msg)]} {

      if {$info_clear ne ""} {
        after cancel $info_clear
      }

      lassign [winfo rgb . [set foreground [[ns utils]::get_default_foreground]]] fr fg fb
      lassign [winfo rgb . [[ns utils]::get_default_background]] br bg bb
      $widgets(info_msg) configure -text $msg -foreground $foreground

      # If the status bar is supposed to be hidden, show it now
      if {![winfo ismapped $widgets(info)]} {
        show_status_view
        set hide_info 1
      } else {
        set hide_info 0
      }

      # Call ourselves
      set info_clear [after $clear_delay \
                       [list [ns gui]::clear_info_message $hide_info \
                         [expr $fr >> 8] [expr $fg >> 8] [expr $fb >> 8] \
                         [expr $br >> 8] [expr $bg >> 8] [expr $bb >> 8]]]

    } else {

      puts $msg

    }

  }

  ######################################################################
  # Clears the info message.
  proc clear_info_message {hide_info fr fg fb br bg bb {fade_count 0}} {

    variable widgets
    variable info_clear

    if {$fade_count == 10} {

      # Clear the text
      $widgets(info_msg) configure -text ""

      # Clear the info_clear variable
      set info_clear ""

      # If the status bar is supposed to be hidden, hide it now
      if {$hide_info} {
        hide_status_view
      }

    } else {

      # Calculate the color
      set color [format {#%02x%02x%02x} \
                  [expr $fr - ((($fr - $br) / 10) * $fade_count)] \
                  [expr $fg - ((($fg - $bg) / 10) * $fade_count)] \
                  [expr $fb - ((($fb - $bb) / 10) * $fade_count)]]

      # Set the foreground color to simulate the fade effect
      $widgets(info_msg) configure -foreground $color

      set info_clear [after 100 [list [ns gui]::clear_info_message $hide_info $fr $fg $fb $br $bg $bb [incr fade_count]]]

    }

  }

  ######################################################################
  # Generates an error message parented by the main window.  Used to
  # unify the error message experience.
  proc set_error_message {msg {detail ""}} {

    tk_messageBox -parent . -icon error -title [msgcat::mc "Error"] -type ok -default ok -message $msg -detail $detail

  }

  ######################################################################
  # Gets user input from the interface in a generic way.
  proc get_user_response {msg pvar {allow_vars 1}} {

    variable widgets

    upvar $pvar var

    # Initialize the widget
    $widgets(ursp_label) configure -text $msg
    $widgets(ursp_entry) delete 0 end

    # If var contains a value, display it and select it
    if {$var ne ""} {
      $widgets(ursp_entry) insert end $var
      $widgets(ursp_entry) selection range 0 end
    }

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

    # Wait for the ursp_entry widget to be visible and then grab it
    tkwait visibility $widgets(ursp)
    grab $widgets(ursp)

    # Wait for the widget to be closed
    vwait [ns gui]::user_exit_status

    # Reset the original focus and grab
    catch { focus $old_focus }
    catch { grab release $widgets(ursp) }
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

    # If variable substitutions are allowed, perform any substitutions
    if {$allow_vars} {
      set var [[ns utils]::perform_substitutions $var]
    }

    return [set [ns gui]::user_exit_status]

  }

  ######################################################################
  # Returns file information for the given file index and attribute.
  # This is called by the get_file_info API command.
  proc get_file_info {index attr} {

    variable files
    variable files_index

    # Perform error detections
    if {($index < 0) || ($index >= [llength $files])} {
      return -code error [msgcat::mc "File index is out of range"]
    }

    # Get the current text widget
    lassign [get_info $index fileindex {txt remote}] txt remote

    switch $attr {
      "sb_index" {
        return [[ns sidebar]::get_index $index $remote]
      }
      "txt" {
        return $txt.t
      }
      "current" {
        return [expr {$txt eq [current_txt {}]}]
      }
      "vimmode" {
        return [[ns vim]::in_vim_mode $txt.t]
      }
      "lang" {
        return [[ns syntax]::get_language $txt]
      }
      default {
        if {![info exists files_index($attr)]} {
          return -code error [format "%s (%s)" [msgcat::mc "File attribute does not exist"] $attr]
        }
      }
    }

    return [lindex $files $index $files_index($attr)]

  }

  ######################################################################
  # Retrieves the "find in file" inputs from the user.
  proc fif_get_input {prsp_list} {

    variable widgets
    variable fif_files
    variable case_sensitive
    variable saved

    upvar $prsp_list rsp_list

    # Initialize variables
    set case_sensitive 1
    set saved          0

    # Reset the input widgets
    $widgets(fif_find) delete 0 end
    $widgets(fif_in)   delete 0 end

    # Populate the fif_in tokenentry menu
    set fif_files [[ns sidebar]::get_fif_files]
    $widgets(fif_in) configure -listvar [ns gui]::fif_files -matchmode regexp -matchindex 0 -matchdisplayindex 0

    # Display the FIF widget
    grid $widgets(fif)

    # Get current focus and grab
    set old_focus [focus]
    set old_grab  [grab current $widgets(fif)]
    if {$old_grab ne ""} {
      set grab_status [grab status $old_grab]
    }

    # Set focus to the ursp_entry widget
    focus $widgets(fif_find)

    # Wait for the fif frame to be visible and then grab it
    tkwait visibility $widgets(fif)
    grab $widgets(fif)

    vwait [ns gui]::user_exit_status

    # Reset the original focus and grab
    catch { focus $old_focus }
    catch { grab release $widgets(fif) }
    if {$old_grab ne ""} {
      if {$grab_status ne "global"} {
        grab $old_grab
      } else {
        grab -global $old_grab
      }
    }

    # Hide the widget
    grid remove $widgets(fif)

    # Get the list of files/directories from the list of tokens
    set ins [list]
    foreach token [$widgets(fif_in) tokenget] {
      if {[set index [lsearch -index 0 $fif_files $token]] != -1} {
        lappend ins {*}[lindex $fif_files $index 1]
      } else {
        lappend ins [[ns utils]::perform_substitutions $token]
      }
    }

    # Gather the input to return
    set rsp_list [list find [$widgets(fif_find) get] in $ins case_sensitive $case_sensitive save $saved]

    return [set [ns gui]::user_exit_status]

  }

  ######################################################################
  # Displays the help menu "About" window.
  proc show_about {} {

    # Generate the version string
    if {$::version_point == 0} {
      set version_str "$::version_major.$::version_minor ($::version_hgid)"
    } else {
      set version_str "$::version_major.$::version_minor.$::version_point ($::version_hgid)"
    }

    if {[[ns preferences]::get General/UpdateReleaseType] eq "devel"} {
      set release_type "Development"
    } else {
      set release_type "Stable"
    }

    toplevel     .aboutwin
    wm title     .aboutwin ""
    wm transient .aboutwin .
    wm resizable .aboutwin 0 0
    wm geometry  .aboutwin 370x370

    ttk::frame .aboutwin.f
    ttk::label .aboutwin.f.logo -compound left -image logo -text " TKE" \
      -font [font create -family Helvetica -size 30 -weight bold]

    ttk::frame .aboutwin.f.if
    ttk::label .aboutwin.f.if.l0 -text [format "%s:" [msgcat::mc "Version"]]
    ttk::label .aboutwin.f.if.v0 -text $version_str
    ttk::label .aboutwin.f.if.l1 -text [format "%s:" [msgcat::mc "Release Type"]]
    ttk::label .aboutwin.f.if.v1 -text $release_type
    ttk::label .aboutwin.f.if.l2 -text [format "%s:" [msgcat::mc "License"]]
    ttk::label .aboutwin.f.if.v2 -text "GPL 2.0"
    ttk::label .aboutwin.f.if.l3 -text [format "%s:" [msgcat::mc "Tcl/Tk Version"]]
    ttk::label .aboutwin.f.if.v3 -text [info patchlevel]
    ttk::label .aboutwin.f.if.l4 -text [format "\n%s:" [msgcat::mc "Developer"]]
    ttk::label .aboutwin.f.if.v4 -text "\nTrevor Williams"
    ttk::label .aboutwin.f.if.l5 -text [format "%s:" [msgcat::mc "Email"]]
    ttk::label .aboutwin.f.if.v5 -text "phase1geo@gmail.com"
    ttk::label .aboutwin.f.if.l6 -text "Twitter:"
    ttk::label .aboutwin.f.if.v6 -text "@TkeTextEditor"
    ttk::label .aboutwin.f.if.l7 -text "Website:"
    ttk::label .aboutwin.f.if.v7 -text "http://tke.sourceforge.net"

    bind .aboutwin.f.if.v2 <Enter>    "%W configure -cursor [ttk::cursor link]"
    bind .aboutwin.f.if.v2 <Leave>    "%W configure -cursor [ttk::cursor standard]"
    bind .aboutwin.f.if.v2 <Button-1> {
      destroy .aboutwin
      gui::add_file end [file join $::tke_dir LICENSE] -sidebar 0 -readonly 1
    }
    bind .aboutwin.f.if.v5 <Enter>    "%W configure -cursor [ttk::cursor link]"
    bind .aboutwin.f.if.v5 <Leave>    "%W configure -cursor [ttk::cursor standard]"
    bind .aboutwin.f.if.v5 <Button-1> "[ns utils]::open_file_externally {mailto:phase1geo@gmail.com} 1"
    bind .aboutwin.f.if.v6 <Enter>    "%W configure -cursor [ttk::cursor link]"
    bind .aboutwin.f.if.v6 <Leave>    "%W configure -cursor [ttk::cursor standard]"
    bind .aboutwin.f.if.v6 <Button-1> "[ns utils]::open_file_externally {https://twitter.com/TkeTextEditor} 1"
    bind .aboutwin.f.if.v7 <Enter>    "%W configure -cursor [ttk::cursor link]"
    bind .aboutwin.f.if.v7 <Leave>    "%W configure -cursor [ttk::cursor standard]"
    bind .aboutwin.f.if.v7 <Button-1> "[ns utils]::open_file_externally {http://tke.sourceforge.net} 1"

    grid .aboutwin.f.if.l0 -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.v0 -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.l1 -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.v1 -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.l2 -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.v2 -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.l3 -row 3 -column 0 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.v3 -row 3 -column 1 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.l4 -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.v4 -row 4 -column 1 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.l5 -row 5 -column 0 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.v5 -row 5 -column 1 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.l6 -row 6 -column 0 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.v6 -row 6 -column 1 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.l7 -row 7 -column 0 -sticky news -padx 2 -pady 2
    grid .aboutwin.f.if.v7 -row 7 -column 1 -sticky news -padx 2 -pady 2

    ttk::labelframe .aboutwin.f.cf -text [msgcat::mc "Credits"] -labelanchor n
    set txt [text .aboutwin.f.cf.t -wrap word -height 5 -relief flat \
      -background [utils::get_default_background] \
      -foreground [utils::get_default_foreground] \
      -yscrollcommand { utils::set_yscrollbar .aboutwin.f.cf.vb }]
    ttk::scrollbar .aboutwin.f.cf.vb -orient vertical -command { .aboutwin.f.cf.t yview }

    grid rowconfigure    .aboutwin.f.cf 0 -weight 1
    grid columnconfigure .aboutwin.f.cf 0 -weight 1
    grid .aboutwin.f.cf.t  -row 0 -column 0 -sticky news
    grid .aboutwin.f.cf.vb -row 0 -column 1 -sticky ns

    ttk::button .aboutwin.f.credits -style BButton -text [msgcat::mc "Credits"] -command {
      if {[.aboutwin.f.credits cget -text] eq [msgcat::mc "Credits"]} {
        pack forget .aboutwin.f.if
        pack .aboutwin.f.cf -after .aboutwin.f.logo -padx 2 -pady 2 -fill both -expand yes
        .aboutwin.f.credits configure -text [msgcat::mc "Back"]
      } else {
        pack forget .aboutwin.f.cf
        pack .aboutwin.f.if -after .aboutwin.f.logo -padx 2 -pady 2
        .aboutwin.f.credits configure -text [msgcat::mc "Credits"]
      }
    }
    ttk::label  .aboutwin.f.copyright -text [format "%s %d-%d" [msgcat::mc "Copyright"] 2013 16]

    pack .aboutwin.f.logo      -padx 2 -pady 8 -anchor w
    pack .aboutwin.f.if        -padx 2 -pady 2
    pack .aboutwin.f.credits   -padx 2 -pady 2
    pack .aboutwin.f.copyright -padx 2 -pady 8

    pack .aboutwin.f -fill both -expand yes

    # Center the window in the editor window
    ::tk::PlaceWindow .aboutwin widget .

    # Add credit information
    $txt insert end "Special thanks to the following:\n\n"
    $txt insert end "\uff65 The " {} "filerunner" frlink " project for creating and sharing their FTP and SFTP codebase to make built-in remote file editing possible." {}

    $txt tag configure frlink -underline 1
    $txt tag bind frlink <Enter>    [list $txt configure -cursor [ttk::cursor link]]
    $txt tag bind frlink <Leave>    [list $txt configure -cursor [ttk::cursor standard]]
    $txt tag bind frlink <Button-1> [list utils::open_file_externally "http://filerunner.sourceforge.net"]

  }

  ######################################################################
  # Displays the number insertion dialog box if we are currently in
  # multicursor mode.
  proc insert_numbers {txt} {

    if {[[ns multicursor]::enabled $txt]} {

      set var1 ""

      # Get the number string from the user
      if {[get_user_response [msgcat::mc "Starting number:"] var1]} {

        # Insert the numbers (if not successful, output an error to the user)
        if {![[ns multicursor]::insert_numbers $txt $var1]} {
          set_info_message [msgcat::mc "Unable to successfully parse number string"]
        }

      }

    # Otherwise, display an error message to the user
    } else {
      set_info_message [msgcat::mc "Must be in multicursor mode to insert numbers"]
    }

  }

  ######################################################################
  # Toggles the split pane for the current tab.
  proc toggle_split_pane {tid} {

    if {[lsearch [[current_txt $tid] peer names] *tf2*] != -1} {
      hide_split_pane $tid
    } else {
      show_split_pane $tid
    }

  }

  ######################################################################
  # Toggles the bird's eye view panel for the current tab.
  proc toggle_birdseye {tid} {

    set txt   [current_txt $tid]
    set peers [$txt peer names]

    if {([llength $peers] == 2) || (([llength $peers] == 1) && ([lsearch $peers *tf2*] == -1))} {
      hide_birdseye $txt
    } else {
      show_birdseye $txt
    }

  }

  ######################################################################
  # Returns a list of all of the text widgets in the tool.
  proc get_all_texts {} {

    variable widgets

    set txts [list]

    if {[info exists widgets(nb_pw)]} {

      foreach nb [$widgets(nb_pw) panes] {
        foreach tab [$nb.tbf.tb tabs] {
          lappend txts [get_txt_from_tab $tab]
          if {[winfo exists [get_txt2_from_tab $tab]]} {
            lappend txts [get_txt2_from_tab $tab] {}
          }
        }
      }

    }

    return $txts

  }

  ########################
  #  PRIVATE PROCEDURES  #
  ########################

  ######################################################################
  # Gets the various pieces of tos information from the given from.
  # The valid values for from and tos (list) is the following:
  #
  #   - current   (from_type only, from must be the tid)
  #   - pane      (using in from implies the current pane)
  #   - paneindex (using in from implies the current pane index)
  #   - tabbar    (using in from implies the current tabbar)
  #   - tab
  #   - tabindex  (using in from implies the index of the tab in the current pane)
  #   - fileindex
  #   - txt
  #   - txt2
  #   - fname
  #   - lang
  #   - any key from files_index (for to_types only)
  #
  # Throws an error if there were conversion issues.
  proc get_info {from from_type to_types} {

    variable widgets
    variable files
    variable files_index
    variable pw_current

    # Convert from to a tab
    switch $from_type {
      current {
        set tab [[lindex [$widgets(nb_pw) panes] $pw_current].tbf.tb select]
      }
      pane   {
        set tab [$from.tbf.tb select]
      }
      paneindex {
        set tab [[lindex [$widgets(nb_pw) panes] $from].tbf.tb select]
      }
      tabbar {
        set tab [$from select]
      }
      tab    {
        set tab $from
      }
      tabindex {
        set tab [lindex [[lindex [$widgets(nb_pw) panes] $pw_current].tbf.tb tabs] $from]
      }
      fileindex {
        set tab [lindex $files $from $files_index(tab)]
      }
      txt -
      txt2 {
        set tab [winfo parent [winfo parent [winfo parent $from]]]
      }
      fname {
        if {[set index [lsearch -index $files_index(fname) $files $from]] == -1} {
          puts [utils::stacktrace]
          return -code error "Unable to find filename"
        }
        set tab [lindex $files $index $files_index(tab)]
      }
    }

    if {$tab eq ""} {
      set paneindex $pw_current
    } else {
      set panes     [$widgets(nb_pw) panes]
      set paneindex [expr {(([llength $panes] == 1) || ([lsearch [[lindex $panes 0].tbf.tb tabs] $tab] != -1)) ? 0 : 1}]
    }

    set fileindex [lsearch -index $files_index(tab) $files $tab]
    set tos       [list]

    foreach to_type $to_types {
      switch $to_type {
        pane {
          lappend tos [lindex [$widgets(nb_pw) panes] $paneindex]
        }
        paneindex {
          lappend tos $paneindex
        }
        tabbar {
          lappend tos [lindex [$widgets(nb_pw) panes] $paneindex].tbf.tb
        }
        tab {
          if {$tab eq ""} {
            return -code error "Unable to get tab information"
          }
          lappend tos $tab
        }
        tabindex {
          if {$tab eq ""} {
            return -code error "Unable to get tab index information"
          }
          lappend tos [lsearch [[lindex [$widgets(nb_pw) panes] $paneindex].tbf.tb tabs] $tab]
        }
        fileindex {
          lappend tos $fileindex
        }
        txt {
          if {$tab eq ""} {
            return -code error "Unable to get txt information"
          }
          lappend tos "$tab.pw.tf.txt"
        }
        txt2 {
          if {$tab eq ""} {
            return -code error "Unable to get txt2 information"
          }
          lappend tos "$tab.pw.tf2.txt"
        }
        lang {
          if {$tab eq ""} {
            return -code error "Unable to get lang information"
          }
          lappend tos [syntax::get_language "$tab.pw.tf.txt"]
        }
        default {
          if {$tab eq ""} {
            return -code error "Unable to get $to_type information"
          }
          lappend tos [lindex $files $fileindex $files_index($to_type)]
        }
      }
    }

    return $tos

  }

  ######################################################################
  # Add notebook widget.
  proc add_notebook {} {

    variable widgets
    variable curr_notebook

    # Create editor notebook
    $widgets(nb_pw) add [set nb [ttk::frame $widgets(nb_pw).nb[incr curr_notebook]]] -weight 1

    # Add the tabbar frame
    ttk::frame $nb.tbf
    tabbar::tabbar $nb.tbf.tb -command "[ns gui]::handle_tabbar_select" \
      -closeimage tab_close \
      -checkcommand "[ns gui]::close_check_by_tabbar {}" \
      -closecommand "[ns gui]::close_tab_by_tabbar"

    # Configure the tabbar
    $nb.tbf.tb configure {*}[[ns theme]::get_category_options tabs 1]

    grid rowconfigure    $nb.tbf 0 -weight 1
    grid columnconfigure $nb.tbf 0 -weight 1
    grid $nb.tbf.tb    -row 0 -column 0 -sticky news
    grid remove $nb.tbf.tb

    bind [$nb.tbf.tb scrollpath left]  <Button-$::right_click> "[ns gui]::show_tabs $nb.tbf.tb left"
    bind [$nb.tbf.tb scrollpath right] <Button-$::right_click> "[ns gui]::show_tabs $nb.tbf.tb right"

    # Create popup menu for extra tabs
    menu $nb.tbf.tb.mnu -tearoff 0

    ttk::frame $nb.tf

    pack $nb.tbf -fill x
    pack $nb.tf  -fill both -expand yes

    bind [$nb.tbf.tb btag] <ButtonPress-$::right_click> {
      if {[info exists gui::tab_tip(%W)]} {
        unset gui::tab_tip(%W)
        tooltip::tooltip clear %W
        tooltip::hide
      }
      set pane            [winfo parent [winfo parent [winfo parent %W]]]
      set gui::pw_current [lsearch [$gui::widgets(nb_pw) panes] [winfo parent [winfo parent [winfo parent %W]]]]
      if {![catch "[winfo parent %W] select @%x,%y"]} {
        tk_popup $gui::widgets(menu) %X %Y
      }
    }

    # Handle tooltips
    bind [$nb.tbf.tb btag] <Motion> [list [ns gui]::handle_notebook_motion %W %x %y]

    # Register the tabbar for theming
    theme::register_widget $nb.tbf.tb tabs

  }

  ######################################################################
  # Called when the user places the cursor over a notebook tab.
  proc handle_notebook_motion {W x y} {

    variable tab_tip
    variable tab_close

    # Adjust W
    set W [winfo parent $W]

    # If the tab is one of the left or right shift tabs, exit now
    if {[set tab_index [$W index @$x,$y]] == -1} {
      return
    }

    set tab [lindex [$W tabs] $tab_index]

    # Handle tooltip
    if {![info exists tab_tip($W)]} {
      set_tab_tooltip $W $tab
    } elseif {$tab_tip($W) ne $tab} {
      clear_tab_tooltip $W
      set_tab_tooltip $W $tab
    } else {
      clear_tab_tooltip $W
    }

  }

  ######################################################################
  # Sets a tooltip for the specified tab.
  proc set_tab_tooltip {W tab} {

    variable tab_tip

    # Get the full pathname to the current file
    lassign [get_info $tab tab {fname remote}] fname remote

    # Figure out what to display
    if {$remote eq ""} {
      set tip $fname
    } else {
      set remote [join [lassign [split $remote ,] group] ,]
      set tip    "$fname ($remote)"
    }

    # Create the tooltip
    set tab_tip($W) $tab
    tooltip::tooltip $W $tip
    event generate $W <Enter>

  }

  ######################################################################
  # Clears the tooltip for the specified tab.
  proc clear_tab_tooltip {W} {

    variable tab_tip

    unset -nocomplain tab_tip($W)
    tooltip::tooltip clear $W
    tooltip::hide

  }

  ######################################################################
  # Adjusts the given index (if necessary) such that the tab will be
  # inserted into the current notebook in alphabetical order.
  proc adjust_insert_tab_index {index title} {

    if {[[ns preferences]::get View/OpenTabsAlphabetically] && ($index eq "end")} {

      set sorted_index 0

      if {![catch { get_info {} current tabbar } tb]} {
        foreach tab [$tb tabs] {
          regexp {(\S+)$} [$tb tab $tab -text] -> curr_title
          if {[string compare $title $curr_title] == -1} {
            return $sorted_index
          }
          incr sorted_index
        }
      }

    }

    return $index

  }

  ######################################################################
  # Inserts a new tab into the editor tab notebook.
  # Options:
  #   -diff (0 | 1)         Specifies if this tab is a difference view.  Default is 0.
  #   -gutters list         Specifies a list of gutters to add to the ctext gutter area
  #   -tags    list         Specifies a list of text binding tags
  #   -lang    language     Specifies initial language parsing of buffer.  Default is to determine based on title.
  proc insert_tab {tb index fname args} {

    variable widgets
    variable curr_id
    variable language
    variable case_sensitive
    variable numberwidth
    variable show_match_char

    array set opts {
      -diff    0
      -gutters [list]
      -tags    [list]
      -lang    ""
    }
    array set opts $args

    # Get the scrollbar coloring information
    array set sb_opts [set scrollbar_opts [[ns theme]::get_category_options text_scrollbar 1]]

    # Get the unique tab ID
    set id [incr curr_id]

    # Calculate the title name
    set title [file tail $fname]

    # Get the current notebook
    set nb [get_info $tb tabbar pane]

    # Make the tabbar visible and the syntax menubutton enabled
    grid $tb
    $widgets(info_indent) configure -state normal
    $widgets(info_syntax) configure -state normal

    # Create the tab frame
    set tab [ttk::frame .tab$id]

    # Create the editor pane
    ttk::panedwindow $tab.pw

    # Create tab frame name
    set txt $tab.pw.tf.txt

    # Create the editor frame
    $tab.pw add [frame $tab.pw.tf -background $sb_opts(-background)]
    ctext $txt -wrap none -undo 1 -autoseparators 1 -insertofftime 0 \
      -highlightcolor orange -warnwidth [[ns preferences]::get Editor/WarningWidth] \
      -maxundo [[ns preferences]::get Editor/MaxUndo] \
      -diff_mode $opts(-diff) -matchchar $show_match_char \
      -linemap_mark_command [ns gui]::mark_command -linemap_select_bg orange \
      -linemap_relief flat -linemap_minwidth $numberwidth \
      -linemap_type [expr {[[ns preferences]::get Editor/RelativeLineNumbers] ? "relative" : "absolute"}] \
      -xscrollcommand [list $tab.pw.tf.hb set] -yscrollcommand [list [ns gui]::yscrollcommand $txt $tab.pw.tf.vb]
    scroller::scroller $tab.pw.tf.hb {*}$scrollbar_opts -orient horizontal -autohide 0 -command [list $txt xview]
    scroller::scroller $tab.pw.tf.vb {*}$scrollbar_opts -orient vertical   -autohide 1 -command [list [ns gui]::yview $txt] \
      -markcommand1 [list [ns markers]::get_positions $txt] -markhide1 [expr [[ns preferences]::get View/ShowMarkerMap] ^ 1] \
      -markcommand2 [expr {$opts(-diff) ? [list [ns diff]::get_marks $txt] : ""}]

    # Register the widgets
    [ns theme]::register_widget $txt          syntax
    [ns theme]::register_widget $tab.pw.tf.vb text_scrollbar
    [ns theme]::register_widget $tab.pw.tf.hb text_scrollbar

    # Create the editor font if it does not currently exist
    if {[lsearch [font names] editor_font] == -1} {
      font create editor_font {*}[font configure TkFixedFont] {*}[[ns preferences]::get Appearance/EditorFont]
    }

    $txt configure -font editor_font

    bind Ctext  <<Modified>>                 "[ns gui]::text_changed %W %d"
    bind $txt.t <FocusIn>                    "+[ns gui]::handle_txt_focus %W"
    bind $txt.t <<CursorChanged>>            "+[ns gui]::update_position $txt"
    bind $txt.l <ButtonPress-$::right_click> [bind $txt.l <ButtonPress-1>]
    bind $txt.l <ButtonPress-1>              "[ns gui]::select_line %W %x %y"
    bind $txt.l <B1-Motion>                  "[ns gui]::select_lines %W %x %y"
    bind $txt.l <Shift-ButtonPress-1>        "[ns gui]::select_lines %W %x %y"
    bind $txt   <<Selection>>                "[ns gui]::selection_changed $txt"
    bind $txt   <Motion>                     "[ns gui]::clear_tab_tooltip $tb"
    bind Text   <<Cut>>                      ""
    bind Text   <<Copy>>                     ""
    bind Text   <<Paste>>                    ""
    bind Text   <Control-d>                  ""
    bind Text   <Control-i>                  ""

    # Move the all bindtag ahead of the Text bindtag
    set text_index [lsearch [bindtags $txt.t] Text]
    set all_index  [lsearch [bindtags $txt.t] all]
    bindtags $txt.t [lreplace [bindtags $txt.t] $all_index $all_index]
    bindtags $txt.t [linsert  [bindtags $txt.t] $text_index all]

    grid rowconfigure    $tab.pw.tf 0 -weight 1
    grid columnconfigure $tab.pw.tf 0 -weight 1
    grid $tab.pw.tf.txt -row 0 -column 0 -sticky news
    grid $tab.pw.tf.vb  -row 0 -column 1 -sticky ns
    grid $tab.pw.tf.hb  -row 1 -column 0 -sticky ew

    # Create the Vim command bar
    [ns vim]::bind_command_entry $txt [entry $tab.ve] {}

    # Create the search bar
    ttk::frame       $tab.sf
    ttk::label       $tab.sf.l1    -text [format "%s:" [msgcat::mc "Find"]]
    ttk::entry       $tab.sf.e
    ttk::checkbutton $tab.sf.case  -text "Aa"   -variable [ns gui]::case_sensitive
    ttk::checkbutton $tab.sf.save  -text "Save" -variable [ns gui]::saved -command "[ns search]::update_save find"
    ttk::label       $tab.sf.close -image form_close

    tooltip::tooltip $tab.sf.case "Case sensitivity"

    pack $tab.sf.l1    -side left  -padx 2 -pady 2
    pack $tab.sf.e     -side left  -padx 2 -pady 2 -fill x -expand yes
    pack $tab.sf.close -side right -padx 2 -pady 2
    pack $tab.sf.save  -side right -padx 2 -pady 2
    pack $tab.sf.case  -side right -padx 2 -pady 2

    bind $tab.sf.e     <Escape>    "[ns gui]::close_search"
    bind $tab.sf.case  <Escape>    "[ns gui]::close_search"
    bind $tab.sf.save  <Escape>    "[ns gui]::close_search"
    bind $tab.sf.e     <Up>        "[ns search]::traverse_history find  1"
    bind $tab.sf.e     <Down>      "[ns search]::traverse_history find -1"
    bind $tab.sf.close <Button-1>  "[ns gui]::close_search"
    bind $tab.sf.close <Key-space> "[ns gui]::close_search"

    # Create the search/replace bar
    ttk::frame       $tab.rf
    ttk::label       $tab.rf.fl    -text [format "%s:" [msgcat::mc "Find"]]
    ttk::entry       $tab.rf.fe
    ttk::label       $tab.rf.rl    -text [format "%s:" [msgcat::mc "Replace"]]
    ttk::entry       $tab.rf.re
    ttk::checkbutton $tab.rf.case  -text "Aa"   -variable [ns gui]::case_sensitive
    ttk::checkbutton $tab.rf.glob  -text [msgcat::mc "All"]  -variable [ns gui]::replace_all
    ttk::checkbutton $tab.rf.save  -text [msgcat::mc "Save"] -variable [ns gui]::saved \
      -command "[ns search]::update_save replace"
    ttk::label       $tab.rf.close -image form_close

    pack $tab.rf.fl    -side left -padx 2 -pady 2
    pack $tab.rf.fe    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $tab.rf.rl    -side left -padx 2 -pady 2
    pack $tab.rf.re    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $tab.rf.case  -side left -padx 2 -pady 2
    pack $tab.rf.glob  -side left -padx 2 -pady 2
    pack $tab.rf.save  -side left -padx 2 -pady 2
    pack $tab.rf.close -side left -padx 2 -pady 2

    bind $tab.rf.fe    <Return>    [list [ns search]::replace_start {}]
    bind $tab.rf.re    <Return>    [list [ns search]::replace_start {}]
    bind $tab.rf.case  <Return>    [list [ns search]::replace_start {}]
    bind $tab.rf.glob  <Return>    [list [ns search]::replace_start {}]
    bind $tab.rf.save  <Return>    [list [ns search]::replace_start {}]
    bind $tab.rf.fe    <Escape>    "[ns gui]::close_search_and_replace"
    bind $tab.rf.re    <Escape>    "[ns gui]::close_search_and_replace"
    bind $tab.rf.case  <Escape>    "[ns gui]::close_search_and_replace"
    bind $tab.rf.glob  <Escape>    "[ns gui]::close_search_and_replace"
    bind $tab.rf.save  <Escape>    "[ns gui]::close_search_and_replace"
    bind $tab.rf.close <Button-1>  "[ns gui]::close_search_and_replace"
    bind $tab.rf.close <Key-space> "[ns gui]::close_search_and_replace"
    bind $tab.rf.fe    <Up>        "[ns search]::traverse_history replace  1"
    bind $tab.rf.fe    <Down>      "[ns search]::traverse_history replace -1"

    # Create the diff bar
    if {$opts(-diff)} {
      [ns diff]::create_diff_bar $txt $tab.df
      ttk::separator $tab.sep2 -orient horizontal
    }

    # Create separator between search and information bar
    ttk::separator $tab.sep1 -orient horizontal

    grid rowconfigure    $tab 0 -weight 1
    grid columnconfigure $tab 0 -weight 1
    grid $tab.pw   -row 0 -column 0 -sticky news
    grid $tab.ve   -row 1 -column 0 -sticky ew -columnspan 2
    grid $tab.sf   -row 2 -column 0 -sticky ew -columnspan 2
    grid $tab.rf   -row 3 -column 0 -sticky ew -columnspan 2
    grid $tab.sep1 -row 4 -column 0 -sticky ew -columnspan 2
    if {$opts(-diff)} {
      grid $tab.df   -row 5 -column 0 -sticky ew -columnspan 2
      grid $tab.sep2 -row 6 -column 0 -sticky ew -columnspan 2
    }

    # Hide the vim command entry, search bar, search/replace bar and search separator
    grid remove $tab.ve
    grid remove $tab.sf
    grid remove $tab.rf
    grid remove $tab.sep1

    # Get the adjusted index
    set adjusted_index [$tb index $index]

    # Add the text bindings
    [ns indent]::add_bindings          $txt
    [ns multicursor]::add_bindings     $txt
    [ns vim]::set_vim_mode             $txt {}
    [ns completer]::add_bindings       $txt
    [ns plugins]::handle_text_bindings $txt $opts(-tags)
    make_drop_target                   $txt

    # Apply the appropriate syntax highlighting for the given extension
    [ns syntax]::set_language $txt [expr {($opts(-lang) eq "") ? [[ns syntax]::get_default_language $fname] : $opts(-lang)}]

    # Snippet bindings must go after syntax language setting
    [ns snippets]::add_bindings $txt

    # Apply code foldings
    [ns folding]::initialize $txt

    # Add any gutters
    foreach gutter $opts(-gutters) {
      $txt gutter create {*}$gutter
    }

    # Add the new tab to the notebook in alphabetical order (if specified) and if
    # the given index is "end"
    if {[[ns preferences]::get View/OpenTabsAlphabetically] && ($index eq "end")} {
      set added 0
      foreach t [$tb tabs] {
        if {[string compare " $title" [$tb tab $t -text]] == -1} {
          $tb insert $t $tab -text " $title" -emboss 0
          set added 1
          break
        }
      }
      if {$added == 0} {
        $tb insert end $tab -text " $title" -emboss 0
      }

    # Otherwise, add the tab in the specified location
    } else {
      $tb insert $index $tab -text " $title" -emboss 0
    }

    # Display the bird's eye viewer
    if {[[ns preferences]::get View/ShowBirdsEyeView]} {
      show_birdseye $txt
    }

    return $tab

  }

  ######################################################################
  # Adds a peer ctext widget to the current widget in the pane just below
  # the current pane.
  #
  # TBD - This is missing support for applied gutters!
  proc show_split_pane {tid} {

    variable show_match_char

    # Get the current paned window
    lassign [get_info {} current {tabbar tab txt txt2 diff}] tb tab txt txt2 diff

    # Get the paned window of the text widget
    set pw [winfo parent [winfo parent $txt]]

    # Get the scrollbar coloring information
    array set sb_opts [set scrollbar_opts [[ns theme]::get_category_options text_scrollbar 1]]

    # Create the editor frame
    $pw insert 0 [frame $pw.tf2 -background $sb_opts(-background)]
    ctext $txt2 -wrap none -undo 1 -autoseparators 1 -insertofftime 0 -font editor_font \
      -highlightcolor orange -warnwidth [[ns preferences]::get Editor/WarningWidth] \
      -maxundo [[ns preferences]::get Editor/MaxUndo] -matchchar $show_match_char \
      -linemap [[ns preferences]::get View/ShowLineNumbers] \
      -linemap_mark_command [ns gui]::mark_command -linemap_select_bg orange -peer $txt \
      -xscrollcommand "$pw.tf2.hb set" \
      -yscrollcommand "$pw.tf2.vb set"
    scroller::scroller $pw.tf2.hb {*}$scrollbar_opts -orient horizontal -autohide 0 -command "$txt2 xview"
    scroller::scroller $pw.tf2.vb {*}$scrollbar_opts -orient vertical   -autohide 1 -command "$txt2 yview" \
      -markcommand1 [list [ns markers]::get_positions $txt] -markhide1 [expr [[ns preferences]::get View/ShowMarkerMap] ^ 1] \
      -markcommand2 [expr {$diff ? [list [ns diff]::get_marks $txt] : ""}]

    bind $txt2.t <FocusIn>                    "+[ns gui]::handle_txt_focus %W"
    bind $txt2.t <<CursorChanged>>            "+[ns gui]::update_position $txt2"
    bind $txt2.l <ButtonPress-$::right_click> [bind $txt2.l <ButtonPress-1>]
    bind $txt2.l <ButtonPress-1>              "[ns gui]::select_line %W %x %y"
    bind $txt2.l <B1-Motion>                  "[ns gui]::select_lines %W %x %y"
    bind $txt2.l <Shift-ButtonPress-1>        "[ns gui]::select_lines %W %x %y"
    bind $txt2   <<Selection>>                "[ns gui]::selection_changed $txt2"
    bind $txt2   <Motion>                     "[ns gui]::clear_tab_tooltip $tb"

    # Move the all bindtag ahead of the Text bindtag
    set text_index [lsearch [bindtags $txt2.t] Text]
    set all_index  [lsearch [bindtags $txt2.t] all]
    bindtags $txt2.t [lreplace [bindtags $txt2.t] $all_index $all_index]
    bindtags $txt2.t [linsert  [bindtags $txt2.t] $text_index all]

    grid rowconfigure    $pw.tf2 0 -weight 1
    grid columnconfigure $pw.tf2 0 -weight 1
    grid $pw.tf2.txt -row 0 -column 0 -sticky news
    grid $pw.tf2.vb  -row 0 -column 1 -sticky ns
    grid $pw.tf2.hb  -row 1 -column 0 -sticky ew

    # Associate the existing command entry field with this text widget
    [ns vim]::bind_command_entry $txt2 $tab.ve {}

    # Add the text bindings
    [ns indent]::add_bindings          $txt2
    [ns multicursor]::add_bindings     $txt2
    [ns vim]::set_vim_mode             $txt2 {}
    [ns completer]::add_bindings       $txt2
    [ns plugins]::handle_text_bindings $txt2 {}  ;# TBD - add tags
    make_drop_target                   $txt2

    # Apply the appropriate syntax highlighting for the given extension
    [ns syntax]::set_language $txt2 [[ns syntax]::get_language $txt]

    # Snippet bindings must go after syntax language is set
    [ns snippets]::add_bindings $txt2

    # Apply code foldings
    [ns folding]::initialize $txt2

    # Give the text widget the focus
    set_txt_focus $txt2

  }

  ######################################################################
  # Removes the split pane
  proc hide_split_pane {tid} {

    # Get the current paned window
    set txt [current_txt $tid]
    set pw  [winfo parent [winfo parent $txt]]

    # Delete the extra text widget
    $pw forget $pw.tf2

    # Destroy the extra text widget frame
    destroy $pw.tf2

    # Set the focus back on the tf text widget
    set_txt_focus $pw.tf.txt

  }

  ######################################################################
  # Creates and displays the bird's eye viewer in the same editing buffer
  # as the specified text widget.
  proc show_birdseye {txt} {

    variable be_after_id
    variable be_ignore

    # Get the tab that contains the text widget
    set tab [get_info $txt txt tab]

    if {![winfo exists $tab.be]} {

      # Create the bird's eye viewer
      $txt._t peer create $tab.be -width [[ns preferences]::get View/BirdsEyeViewWidth] -bd 0 \
        -highlightthickness 0 -font "-size [[ns preferences]::get View/BirdsEyeViewFontSize]" \
        -wrap none -cursor [ttk::cursor standard] -state disabled \
        -background [$txt cget -background] -foreground [$txt cget -foreground] \
        -inactiveselectbackground [[ns utils]::auto_adjust_color [$txt cget -background] 25]

      # Add the bird's eye viewer to the tab's grid manager
      grid $tab.be -row 0 -column 1 -sticky ns

      # Setup bindings
      bind $tab.be <Enter>                         [list [ns gui]::handle_birdseye_enter %W $txt]
      bind $tab.be <Leave>                         [list [ns gui]::handle_birdseye_leave %W]
      bind $tab.be <ButtonPress-1>                 "if {\[[ns gui]::handle_birdseye_left_press %W %x %y $txt\]} { break }"
      bind $tab.be <B1-Motion>                     "if {\[[ns gui]::handle_birdseye_motion     %W %x %y $txt\]} { break }"
      bind $tab.be <Control-Button-1>              [list [ns gui]::handle_birdseye_control_left %W]
      bind $tab.be <Control-Button-$::right_click> [list [ns gui]::handle_birdseye_control_right %W]

      set be_after_id($txt) ""
      set be_ignore($txt)   0

    }

  }

  ######################################################################
  # Highlights the currently displayed area in the text widget.
  proc highlight_birdseye {be txt} {

    puts "In highlight_birdseye, be: $be, txt: $txt"

    # Get the start and end shown lines of the given text widget
    set startline [$txt index @0,0]
    set endline   [$txt index @0,[winfo height $txt]]

    puts "  startline: $startline, endline: $endline"

    # Set the selection
    $be tag remove sel 1.0 end
    $be tag add sel $startline $endline

  }

  ######################################################################
  # Handles the mouse entering the bird's eye view.  This will cause the
  # currently displayed text region to be selected in the bird's eye viewer.
  proc handle_birdseye_enter {be txt} {

    highlight_birdseye $be $txt

  }

  ######################################################################
  # Handles the mouse leaving the bird's eye viewer.
  proc handle_birdseye_leave {be} {

    # Clear the selection
    $be tag remove sel 1.0 end

  }

  ######################################################################
  # Handles a left button press event inside the bird's eye viewer.
  proc handle_birdseye_left_press {W x y txt} {

    variable be_last_y
    variable be_ignore

    set cursor [$W index @$x,$y]

    lassign [$W tag ranges sel] selstart selend

    # If we clicked on the selection, start a motion event
    if {[$W compare $selstart <= $cursor] && [$W compare $selend >= $cursor]} {
      set be_last_y $y

    # Otherwise, jump the view to the given location
    } else {

      set be_last_y       ""
      set height          [winfo height $txt]
      set be_ignore($txt) 1

      # TBD - We will want to make sure that the cursor line is centered vertically
      $txt see $cursor
      $txt yview scroll [expr [lindex [$txt bbox $cursor] 1] - ($height / 2)] pixels

      # Highlight the bird's eye viewer
      highlight_birdseye $W $txt

    }

    return 1

  }

  ######################################################################
  # Handles a left button motion event inside the bird's eye viewer.
  proc handle_birdseye_motion {W x y txt} {

    variable be_last_y
    variable be_ignore

    if {($be_last_y ne "") && ($y != $be_last_y)} {

      # Get the current cursor
      set cursor          [$W index @$x,$y]
      set height          [winfo height $txt]
      set be_ignore($txt) 1

      # TBD - We will want to make sure that the cursor line is centered vertically
      $txt see $cursor
      $txt yview scroll [expr [lindex [$txt bbox $cursor] 1] - ($height / 2)] pixels

      # Highlight the bird's eye viewer to match the text widget
      highlight_birdseye $W $txt

    }

    return 1

  }

  ######################################################################
  # Handles a control left-click event in the birdseye.
  proc handle_birdseye_control_left {W} {

    $W yview scroll -1 pages

  }

  ######################################################################
  # Handles a control right-click event in the birdseye.
  proc handle_birdseye_control_right {W} {

    $W yview scroll 1 pages

  }

  ######################################################################
  # Hides the bird's eye viewer associated with the given text widget.
  proc hide_birdseye {txt} {

    variable be_after_id
    variable be_ignore

    # Get the tab that contains the bird's eye viewer
    set tab [get_info $txt txt tab]

    if {[winfo exists $tab.be]} {

      # Cancel the scroll event if one is still set
      if {$be_after_id($txt) ne ""} {
        after cancel $be_after_id($txt)
      }

      # Remove the be_after_id
      unset be_after_id($txt)
      unset be_ignore($txt)

      # Remove the widget from the grid
      grid forget $tab.be

      # Destroy the bird's eye viewer
      destroy $tab.be

    }

  }

  ######################################################################
  # Adds the necessary bindings to make the given text widget a drop
  # target for TkDND.
  proc make_drop_target {txt} {

    # Make ourselves a drop target (if Tkdnd is available)
    catch {

      tkdnd::drop_target register $txt [list DND_Files DND_Text]

      bind $txt <<DropEnter>>      "[ns gui]::handle_drop_enter_or_pos %W %X %Y %a %b"
      bind $txt <<DropPosition>>   "[ns gui]::handle_drop_enter_or_pos %W %X %Y %a %b"
      bind $txt <<DropLeave>>      "[ns gui]::handle_drop_leave %W"
      bind $txt <<Drop:DND_Files>> "[ns gui]::handle_drop %W %A %m 0 %D"
      bind $txt <<Drop:DND_Text>>  "[ns gui]::handle_drop %W %A %m 1 %D"

    }

  }

  ######################################################################
  # Handles a drag-and-drop enter/position event.  Draws UI to show that
  # the file drop request would be excepted or rejected.
  proc handle_drop_enter_or_pos {txt rootx rooty actions buttons} {

    variable files
    variable files_index

    lassign [get_info {} current {readonly lock diff}] readonly lock diff

    # If the file is readonly, refuse the drop
    if {$readonly || $lock || $diff} {
      return "refuse_drop"
    }

    # Make sure the text widget has the focus
    focus -force $txt.t

    # Set the highlight color to green
    ctext::set_border_color $txt green

    # Move the insertion point to the location of rootx/y
    set x [expr $rootx - [winfo rootx $txt.t]]
    set y [expr $rooty - [winfo rooty $txt.t]]
    ::tk::TextSetCursor $txt.t @$x,$y
    [ns vim]::adjust_insert $txt.t

    return "link"

  }

  ######################################################################
  # Handles a drop leave event.
  proc handle_drop_leave {txt} {

    # Set the highlight color to green
    ctext::set_border_color $txt white

  }

  ######################################################################
  # Handles a drop event.  Adds the given files/directories to the sidebar.
  proc handle_drop {txt action modifier type data} {

    # If the data is text or the Alt key modifier is held during the drop, insert the data at the
    # current insertion point
    if {$type || ($modifier eq "alt")} {
      $txt insert insert $data

    # Otherwise, insert the content of the file(s) after the insertion line
    } else {
      set str "\n"
      foreach ifile $data {
        if {[file isfile $ifile]} {
          if {![catch { open $ifile r } rc]} {
            append str [read $rc]
            close $rc
          }
        }
      }
      $txt insert "insert lineend" $str
    }

    # Indicate that the drop event has completed
    handle_drop_leave $txt

    return "link"

  }

  ######################################################################
  # Handles a change to the current text widget.
  proc text_changed {txt data} {

    variable files
    variable files_index
    variable cursor_hist

    if {[$txt edit modified]} {

      # Get file information
      lassign [get_info $txt txt {tabbar tab fileindex readonly}] tb tab file_index readonly

      if {!$readonly && ([lindex $data 2] ne "ignore")} {

        # Save the modified state to the files list
        lset files $file_index $files_index(modified) 1

        # Change the look of the tab
        if {[string index [set name [string trimleft [$tb tab $tab -text]]] 0] ne "*"} {
          $tb tab $tab -text " * $name"
          set_title
        }

      }

      # Clear the cursor history
      array unset cursor_hist $txt,*

    }

    # Update the folding gutter
    if {[lindex $data 2] ne "ignore"} {
      [ns folding]::add_folds $txt {*}[lrange [lindex $data 1] 0 1]
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
  # Selects the given line in the text widget.
  proc select_line {w x y} {

    variable line_sel_anchor

    # Get the parent window
    set txt [winfo parent $w]

    # Get the current line from the line sidebar
    set index [$txt index @$x,$y]

    # We will only select the line if we clicked in the line number area
    if {[expr [lindex [split $index .] 1] >= ([$w cget -width] - [llength [$txt gutter names]])]} {
      return
    }

    # Select the corresponding line in the text widget
    $txt tag remove sel 1.0 end
    $txt tag add sel "$index linestart" "$index lineend"

    # Save the selected line to the anchor
    set line_sel_anchor($w) $index

  }

  ######################################################################
  # Selects all lines between the anchored line and the current line,
  # inclusive.
  proc select_lines {w x y} {

    variable line_sel_anchor

    # Get the parent window
    set txt [winfo parent $w]

    # Get the current line from the line sidebar
    set index [$txt index @$x,$y]

    # We will only select the line if we clicked in the line number area
    if {[expr [lindex [split $index .] 1] >= ([$w cget -width] - [llength [$txt gutter names]])]} {
      return
    }

    # Remove the current selection
    $txt tag remove sel 1.0 end

    # If the anchor has not been set, set it now
    if {![info exists line_sel_anchor($w)]} {
      set line_sel_anchor($w) $index
    }

    # Add the selection between the anchor and this line, inclusive
    if {[$txt compare $index < $line_sel_anchor($w)]} {
      $txt tag add sel "$index linestart" "$line_sel_anchor($w) lineend"
    } else {
      $txt tag add sel "$line_sel_anchor($w) linestart" "$index lineend"
    }

  }

  ######################################################################
  # Returns the main text widget from the given tab.
  proc get_txt_from_tab {tab} {

    return "$tab.pw.tf.txt"

  }

  ######################################################################
  # Returns the secondary text widget from the given tab.
  proc get_txt2_from_tab {tab} {

    return "$tab.pw.tf2.txt"

  }

  ######################################################################
  # Make the specified tab the current tab.
  # Options:
  #   w
  #        Item to base the current tab on (defined by the -type option)
  #   -changed (0 | 1)
  #        Set to true by the tabbar selection command.
  #   -skip_focus (0 | 1)
  #        Specifies if we should set the focus on the text widget.
  #        Default is 0
  proc set_current_tab {tb tab args} {

    variable widgets
    variable pw_current
    variable tab_current
    variable files
    variable files_index

    array set opts {
      -changed    0
      -skip_focus 0
    }
    array set opts $args

    # Get the frame containing the text widget
    set tf [winfo parent [winfo parent $tb]].tf

    # If there is no tab being set, just delete the packed slave
    if {$tab eq ""} {
      if {[set slave [pack slaves $tf]] ne ""} {
        pack forget $slave
      }
      return
    }

    # Get the current information
    lassign [get_info $tab tab {paneindex fileindex}] pw_current file_index

    # If the proc is not being called by the tabbar and the tab is different than the tabbar's current
    # tab, just call the tabbar select with the tab.  It will call this proc itself.  This is an
    # optimization that should eliminate running unnecessary code in this procedure.
    if {!$opts(-changed) && ([$tb select] ne $tab)} {
      show_tab $tab
      $tb select $tab
      return
    }

    if {$opts(-changed) || ([pack slaves $tf] eq "")} {

      # Add the tab content, if necessary
      add_tab_content $tab

      # Display the tab frame
      if {[set slave [pack slaves $tf]] ne ""} {
        pack forget $slave
      }
      pack [$tb select] -in $tf -fill both -expand yes

      # Update the pane synchronization status
      pane_sync_tab_change

      # Update the preferences
      [ns preferences]::update_prefs [[ns sessions]::current]

      # Reload the snippets to correspond to the current file
      [ns snippets]::reload_snippets {}

    }

    # Set the text focus
    if {!$opts(-skip_focus)} {
      set_txt_focus [last_txt_focus {} $tab]
    }

  }

  ######################################################################
  # Handles a selection made by the user from the tabbar.
  proc handle_tabbar_select {tabbar args} {

    set_current_tab $tabbar [get_info $tabbar tabbar tab] -changed 1

  }

  ######################################################################
  # Returns the current text widget pathname (or the empty string if
  # there is no current text widget).
  proc current_txt {tid} {

    if {$tid eq ""} {
      return [expr {[catch { get_info {} current txt } txt] ? "" : $txt}]
    } else {
      return $tid
    }

  }

  ######################################################################
  # Returns the current search entry pathname.
  proc current_search {} {

    set tab [get_info {} current tab]

    return $tab.sf.e

  }

  ######################################################################
  # Updates the current position information in the information bar based
  # on the current location of the insertion cursor.
  proc update_position {txt} {

    variable widgets

    # Get the current position of the insertion cursor
    lassign [split [$txt index insert] .] line column

    # Update the information widgets
    if {[set vim_mode [[ns vim]::get_mode $txt]] ne ""} {
      $widgets(info_state) configure -text [format "%s, %s: %d, %s: %d" $vim_mode [msgcat::mc "Line"] $line [msgcat::mc "Column"] [expr $column + 1]]
    } else {
      $widgets(info_state) configure -text [format "%s: %d, %s: %d" [msgcat::mc "Line"] $line [msgcat::mc "Column"] [expr $column + 1]]
    }

  }

  ######################################################################
  # Display the file count information in the status bar.
  proc display_file_counts {txt} {

    variable widgets

    # Get the current position of the insertion cursor
    lassign [split [$txt index insert] .] line column

    # Get the total line count
    set lines [$txt count -lines 1.0 end]

    # Get the total character count
    set chars [$txt count -chars 1.0 end]

    # Update the information widget
    set_info_message [format "%s: %d, %s: %d" [msgcat::mc "Total Lines"] $lines [msgcat::mc "Total Characters"] $chars]

  }

  ######################################################################
  # Returns the list of procs in the current text widget.  Uses the _procs
  # highlighting to tag to quickly find procs in the widget.
  proc get_symbol_list {tid} {

    variable lengths

    # Get current text widget
    set txt [current_txt $tid]

    set proclist [list]
    foreach tag [$txt tag names] {
      if {[string range $tag 0 8] eq "_symbols:"} {
        if {[set type [string range $tag 9 end]] ne ""} {
          append type ": "
        }
        foreach {startpos endpos} [$txt tag ranges $tag] {
          lappend proclist "$type[$txt get $startpos $endpos]" $startpos
        }
      }
    }

    return $proclist

  }

  ######################################################################
  # Create a marker at the current insertion cursor line of the current
  # editor.
  proc create_current_marker {tid} {

    # Get the current text widget
    set txt [current_txt $tid]

    # Get the current line
    set line [lindex [split [$txt index insert] .] 0]

    # Add the marker at the current line
    if {[set tag [ctext::linemapSetMark $txt $line]] ne ""} {
      if {[[ns markers]::add $txt $tag]} {
        [ns scroller]::update_markers [winfo parent $txt].vb
      } else {
        ctext::linemapClearMark $txt $line
      }
    }

  }

  ######################################################################
  # Removes all markers placed at the current line.
  proc remove_current_marker {tid} {

    # Get the current text widget
    set txt [current_txt $tid]

    # Get the current line number
    set line [lindex [split [$txt index insert] .] 0]

    # Remove all markers at the current line
    [ns markers]::delete_by_line $txt $line
    ctext::linemapClearMark $txt $line
    [ns scroller]::update_markers [winfo parent $txt].vb

  }

  ######################################################################
  # Removes all of the markers from the current editor.
  proc remove_all_markers {tid} {

    # Get the current text widget
    set txt [current_txt $tid]

    foreach name [[ns markers]::get_all_names $txt] {
      set line [lindex [split [[ns markers]::get_index $txt $name] .] 0]
      [ns markers]::delete_by_name $txt $name
      ctext::linemapClearMark $txt $line
    }
    [ns scroller]::update_markers [winfo parent $txt].vb

  }

  ######################################################################
  # Returns the list of markers in the current text widget.
  proc get_marker_list {} {

    variable files
    variable files_index

    # Create a list of marker names and index
    set markers [list]
    foreach {name txt line} [[ns markers]::get_markers] {
      set fname [get_info $txt txt fname]
      lappend markers [list "[file tail $fname] - $name" $txt $line]
    }

    return [lsort -index 0 -dictionary $markers]

  }

  ######################################################################
  # Jump to the given position in the current text widget.
  proc jump_to {tid pos} {

    jump_to_txt [current_txt $tid] $pos

  }

  ######################################################################
  # Jump to the given position in the given text widget.
  proc jump_to_txt {txt pos} {

    # Change the current tab, if necessary
    set_current_tab {*}[get_info $txt txt {tabbar tab}]

    # Make sure that the cursor is visible
    [ns folding]::show_line $txt.t [lindex [split $pos .] 0]

    # Make the line viewable
    ::tk::TextSetCursor $txt.t $pos

    # Adjust the insert
    [ns vim]::adjust_insert $txt.t

  }

  ######################################################################
  # Finds the matching character for the one at the current insertion
  # marker.
  proc show_match_pair {tid} {

    # Get the current widget
    set txt [current_txt $tid]

    # If the current character is a matchable character, change the
    # insertion cursor to the matching character.
    switch -- [$txt get insert] {
      "\{"    { set index [ctext::get_match_bracket $txt curlyR] }
      "\}"    { set index [ctext::get_match_bracket $txt curlyL] }
      "\["    { set index [ctext::get_match_bracket $txt squareR] }
      "\]"    { set index [ctext::get_match_bracket $txt squareL] }
      "\("    { set index [ctext::get_match_bracket $txt parenR] }
      "\)"    { set index [ctext::get_match_bracket $txt parenL] }
      "\<"    { set index [ctext::get_match_bracket $txt angledR] }
      "\>"    { set index [ctext::get_match_bracket $txt angledL] }
      "\""    { set index [find_match_char $txt "\"" [expr {([lsearch [$txt tag names insert-1c] _dString*] == -1) ? "-forwards" : "-backwards"}]] }
      "'"     { set index [find_match_char $txt "'"  [expr {([lsearch [$txt tag names insert-1c] _sString*] == -1) ? "-forwards" : "-backwards"}]] }
      "`"     { set index [find_match_char $txt "`"  [expr {([lsearch [$txt tag names insert-1c] _bString*] == -1) ? "-forwards" : "-backwards"}]]}
      default { set index [find_match_pair $txt {*}[lrange [[ns syntax]::get_indentation_expressions $txt] 0 1] -backwards] }
    }

    # Change the insertion cursor to the matching character
    if {$index != -1} {
      ::tk::TextSetCursor $txt.t $index
    }

  }

  ######################################################################
  # Finds the matching bracket type and returns it's index if found;
  # otherwise, returns -1.
  proc find_match_pair {txt str1 str2 dir {startpos insert}} {

    if {[ctext::isEscaped $txt $startpos]} {
      return -1
    }

    set search_re "[set str1]|[set str2]"
    set count     1
    set pos       [$txt index [expr {($dir eq "-forwards") ? "$startpos+1c" : $startpos}]]

    # Calculate the endpos
    if {[set incomstr [ctext::inCommentString $txt $pos srange]]} {
      if {$dir eq "-forwards"} {
        set endpos [lindex $srange 1]
      } else {
        set endpos [lindex $srange 0]
      }
    } else {
      if {$dir eq "-forwards"} {
        set endpos "end"
      } else {
        set endpos "1.0"
      }
    }

    while {1} {

      if {[set found [$txt search $dir -regexp -- $search_re $pos $endpos]] eq ""} {
        return -1
      }

      set char [$txt get $found]
      if {$dir eq "-forwards"} {
        set pos "$found+1c"
      } else {
        set pos $found
      }

      if {[ctext::isEscaped $txt $found] || (!$incomstr && [ctext::inCommentString $txt $found])} {
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
  proc find_match_char {txt char dir {startpos insert}} {

    set last_found ""

    if {[ctext::isEscaped $txt $startpos]} {
      return -1
    }

    if {$dir eq "-forwards"} {
      set startpos [$txt index "$startpos+1c"]
      set endpos   "end"
    } else {
      set endpos   "1.0"
    }

    while {1} {

      if {[set found [$txt search $dir $char $startpos $endpos]] eq ""} {
        return -1
      }

      set last_found $found
      set startpos   [expr {($dir eq "-backwards") ? $found : [$txt index "$found+1c"]}]

      if {[ctext::isEscaped $txt $last_found]} {
        continue
      }

      return $last_found

    }

  }

  ######################################################################
  # Handles a mark request when the line is clicked.
  proc mark_command {win type tag} {

    if {$type eq "marked"} {
      if {![[ns markers]::add $win $tag]} {
        return 0
      }
    } else {
      [ns markers]::delete_by_tag $win $tag
    }

    # Update the markers in the scrollbar
    [ns scroller]::update_markers [winfo parent $win].vb

    return 1

  }

  ######################################################################
  # Displays all of the unhidden tabs.
  proc show_tabs {tb side} {

    set mnu $tb.mnu

    # Get the shown tabs
    set shown [$tb xview shown]
    lset shown 1 [expr [lindex $shown 1] + 1]

    # Clear the menu
    $mnu delete 0 end

    set i 0
    foreach tab [$tb tabs] {
      if {[lindex $shown 0] == $i} {
        if {$i > 0} {
          $mnu add separator
        }
        set shown [lassign $shown tmp]
      }
      set tab_image [$tb tab $tab -image]
      set img       [expr {($tab_image ne "") ? "menu_[string range $tab_image 4 end]" : ""}]
      $mnu add command -compound left -image $img -label [$tb tab $tab -text] \
        -command [list [ns gui]::set_current_tab $tb $tab]
      incr i
    }

    # Figure out where to display the menu
    if {$side eq "right"} {
      set x [expr ([winfo rootx $tb] + [winfo width $tb]) - [winfo reqwidth $mnu]]
    } else {
      set x [winfo rootx $tb]
    }
    set y [expr [winfo rooty $tb] + [winfo height $tb]]

    # Display the menu
    tk_popup $mnu $x $y

  }

  ######################################################################
  # This is called by the indent namespace to update the indentation
  # widget when the indent value changes internally (due to changing
  # the current language.
  proc update_indent_button {} {

    variable widgets

    [ns indent]::update_button $widgets(info_indent)

  }

  ######################################################################
  # Handles a text FocusIn event from the widget.
  proc handle_txt_focus {txtt} {

    variable widgets
    variable pw_current
    variable txt_current
    variable auto_cwd

    # Get the text information
    lassign [get_info [winfo parent $txtt] txt {paneindex tab txt fileindex fname buffer diff}] pw_current tab txt file_index fname buffer diff

    # Set the line and row information
    update_position $txt

    # Update the indentation indicator
    [ns indent]::update_button $widgets(info_indent)

    # Set the syntax menubutton to the current language
    [ns syntax]::update_button $widgets(info_syntax)

    # If we are supposed to automatically change the working directory, do it now
    if {$auto_cwd && !$buffer && !$diff} {
      cd [file dirname $fname]
    }

    # Set the application title bar
    set_title

    # Check to see if the file has changed
    catch { check_file $file_index }

    # Save the text widget
    set txt_current($tab) [winfo parent $txtt]

    # Let the plugins know about the FocusIn event
    [ns plugins]::handle_on_focusin $tab

  }

  ######################################################################
  # Sets the focus to the given ctext widget.
  proc set_txt_focus {txt} {

    variable txt_current

    # Set the focus
    focus $txt.t

    # Save the last text widget in focus
    set txt_current([get_info $txt txt tab]) $txt

  }

  ######################################################################
  # Returns the path to the ctext widget that last received focus.
  proc last_txt_focus {tid {tab ""}} {

    variable txt_current

    if {$tid eq ""} {
      if {$tab eq ""} {
        return $txt_current([get_info {} current tab])
      } elseif {[info exists txt_current($tab)]} {
        return $txt_current($tab)
      } else {
        return [get_info $tab tab txt]
      }
    } else {
      return $tid
    }

  }

  ######################################################################
  # Scrubs the given text widget, returning the scrubbed text as a string
  # to be used for saving to a file.
  proc scrub_text {txt} {

    variable trailing_ws_re

    # Clear any snippet tabstops embedded in the text widget
    [ns snippets]::clear_tabstops $txt.t

    # Clean up the text from Vim
    set str [[ns vim]::get_cleaned_content $txt]

    if {[[ns preferences]::get Editor/RemoveTrailingWhitespace]} {
      regsub -all -lineanchor -- $trailing_ws_re $str {} str
    }

    return $str

  }

  ######################################################################
  # Jumps to the next cursor as specified by direction.  Returns a boolean
  # value of true if a jump occurs (or can occur).
  proc jump_to_cursor {tid dir jump} {

    variable cursor_hist

    # Get the current text widget
    set txt [current_txt $tid]

    # Get the index of the cursor in the cursor hist to use
    if {![info exists cursor_hist($txt,hist)]} {
      set cursor_hist($txt,hist)  [$txt edit cursorhist]
      set cursor_hist($txt,index) [llength $cursor_hist($txt,hist)]
    }

    set index  $cursor_hist($txt,index)
    set length [llength $cursor_hist($txt,hist)]
    set diff   [[ns preferences]::get Find/JumpDistance]

    if {$index == $length} {
      set last_line [lindex [split [$txt index insert] .] 0]
    } else {
      set last_line [lindex [split [lindex $cursor_hist($txt,hist) $index] .] 0]
    }

    # Get the cursor index
    while {([incr index $dir] >= 0) && ($index < $length)} {
      set cursor     [lindex $cursor_hist($txt,hist) $index]
      set index_line [lindex [split $cursor .] 0]
      if {[expr abs( $index_line - $last_line ) >= $diff]} {
        if {$jump} {
          set cursor_hist($txt,index) $index
          ::tk::TextSetCursor $txt.t "$cursor linestart"
          if {[[ns vim]::in_vim_mode $txt.t]} {
            [ns vim]::adjust_insert $txt.t
          }
        }
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Jumps to the next difference in the specified direction.  Returns
  # a boolean value of true if a jump occurs (or can occur).
  proc jump_to_difference {tid dir jump} {

    # Get the current text widget
    set txt [current_txt $tid]

    # Get the list of ranges
    if {[$txt cget -diff_mode] && ([llength [set ranges [$txt diff ranges both]]] > 0)} {

      if {$jump} {

        # Get the list of difference ranges
        if {$dir == 1} {
          set index [$txt index @0,[winfo height $txt]]
          foreach {start end} $ranges {
            if {[$txt compare $start > $index]} {
              $txt see $start
              return 1
            }
          }
          $txt see [lindex $ranges 0]
        } else {
          set index [$txt index @0,0]
          foreach {end start} [lreverse $ranges] {
            if {[$txt compare $start < $index]} {
              $txt see $start
              return 1
            }
          }
          $txt see [lindex $ranges end-1]
        }

      }

      return 1

    }

    return 0

  }

  ######################################################################
  # Finds the last version that caused the currently selected line to be
  # changed.  Returns true if this can be accomplished; otherwise, returns
  # false.
  proc show_difference_line_change {tid show} {

    # Get the current information
    lassign [get_info {} current {txt fname}] txt fname

    if {[$txt cget -diff_mode] && ![catch { $txt index sel.first } rc]} {
      if {$show} {
        [ns diff]::find_current_version $txt $fname [lindex [split $rc .] 0]
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a font size change event on the widget that the mouse cursor
  # is currently hovering over.
  proc handle_font_change {dir} {

    # Get the current cursor position
    lassign [winfo pointerxy .] x y

    # Get the window containing x and y
    set win [winfo containing $x $y]

    # Get the class of the given window
    switch [winfo class $win] {
      "Text" -
      "Listbox" {
        array set f [font actual [$win cget -font]]
        set f(-size) [expr ($f(-size) < 0) ? ($f(-size) - $dir) : ($f(-size) + $dir)]
        $win configure -font [array get f]
      }
    }

  }

  ######################################################################
  # Change the current working directory to the specified direction and
  # update the title bar.
  proc change_working_directory {dir} {

    # Change the current working directory to dir
    cd $dir

    # Update the title
    set_title

  }

}
