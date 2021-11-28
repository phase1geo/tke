# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2019  Trevor Williams (phase1geo@gmail.com)
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

  variable curr_id          0
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
  variable highlightcolor   ""
  variable auto_cwd         0
  variable numberwidth      4
  variable browse_dir       "last"
  variable synced_key       ""
  variable synced_txt       ""
  variable show_match_chars 0
  variable search_method    "regexp"
  variable fif_method       "regexp"
  variable panel_focus      ""

  array set widgets         {}
  array set tab_tip         {}
  array set line_sel_anchor {}
  array set txt_current     {}
  array set cursor_hist     {}
  array set synced          {}
  array set be_after_id     {}
  array set be_ignore       {}
  array set undo_count      {}

  #######################
  #  PUBLIC PROCEDURES  #
  #######################

  ######################################################################
  # Sets the title of the window to match the current file.
  proc set_title {} {

    # Get the current tab
    if {![catch { get_info {} current tabbar }] && ([llength [$tabbar tabs]] > 0)} {
      set tab_name [$tabbar tab current -text]
    } else {
      set tab_name ""
    }

    # Get the host name
    if {($::tcl_platform(os) eq "Darwin") && ([lindex [split $::tcl_platform(osVersion) .] 0] >= 16)} {
      set host ""
    } else {
      set host "[lindex [split [info hostname] .] 0]:"
    }

    if {[set session [sessions::current]] ne ""} {
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
      -foreground 2
    theme::register_image tab_readonly bitmap tabs -background \
      {msgcat::mc "Image used in tab to indicate that the tab's file is readonly."} \
      -file     [file join $::tke_dir lib images lock.bmp] \
      -maskfile [file join $::tke_dir lib images lock.bmp] \
      -foreground 2
    theme::register_image tab_diff bitmap tabs -background \
      {msgcat::mc "Image used in tab to indicate that the tab contains a difference view."} \
      -file     [file join $::tke_dir lib images diff.bmp] \
      -maskfile [file join $::tke_dir lib images diff.bmp] \
      -foreground 2
    theme::register_image tab_close bitmap tabs -background \
      {msgcat::mc "Image used in tab which, when clicked, closes the tab."} \
      -file     [file join $::tke_dir lib images close.bmp] \
      -maskfile [file join $::tke_dir lib images close.bmp] \
      -foreground 2
    theme::register_image tab_activeclose bitmap tabs -background \
      {msgcat::mc "Images used in tab which will be displayed when the mouse enters the close button area"} \
      -file     [file join $::tke_dir lib images active_close.bmp] \
      -maskfile [file join $::tke_dir lib images active_close.bmp] \
      -foreground 2

    # Create close button for forms
    theme::register_image form_close bitmap ttk_style background \
      {msgcat::mc "Image displayed in fill-in forms which closes the form UI.  Used in forms such as search, search/replace, and find in files."} \
      -file     [file join $::tke_dir lib images close.bmp] \
      -maskfile [file join $::tke_dir lib images close.bmp] \
      -foreground 2

    # Create next/previous button for search
    theme::register_image search_next bitmap ttk_style background \
      {msgcat::mc "Image displayed in find field to search for next match."} \
      -file     [file join $::tke_dir lib images right.bmp] \
      -maskfile [file join $::tke_dir lib images right.bmp] \
      -foreground 2
    theme::register_image search_prev bitmap ttk_style background \
      {msgcat::mc "Image displayed in find field to search for previous match."} \
      -file     [file join $::tke_dir lib images left.bmp] \
      -maskfile [file join $::tke_dir lib images left.bmp] \
      -foreground 2

    # Create main logo image
    image create photo logo -file [file join $::tke_dir lib images tke_logo_64.gif]

    # Create menu images
    theme::register_image menu_lock bitmap menus -background \
      {msgcat::mc "Image used in tab menus to indicate that the file is locked."} \
      -file     [file join $::tke_dir lib images lock.bmp] \
      -maskfile [file join $::tke_dir lib images lock.bmp] \
      -foreground black
    theme::register_image menu_readonly bitmap menus -background \
      {msgcat::mc "Image used in tab menus to indicate that the file is readonly."} \
      -file     [file join $::tke_dir lib images lock.bmp] \
      -maskfile [file join $::tke_dir lib images lock.bmp] \
      -foreground black
    theme::register_image menu_diff bitmap menus -background \
      {msgcat::mc "Image used in tab menus to indicate that the file is associated with a difference view."} \
      -file     [file join $::tke_dir lib images diff.bmp] \
      -maskfile [file join $::tke_dir lib images diff.bmp] \
      -foreground black
    theme::register_image menu_check bitmap menus -background \
      {msgcat::mc "Image used in the menus to indicate that a menu item is selected."} \
      -file     [file join $::tke_dir lib images menu_check.bmp] \
      -maskfile [file join $::tke_dir lib images menu_check.bmp] \
      -foreground black
    theme::register_image menu_nocheck bitmap menus -background \
      {msgcat::mc "Image used in the menus to indicate that a menu item is not selected."} \
      -file     [file join $::tke_dir lib images menu_nocheck.bmp] \
      -maskfile [file join $::tke_dir lib images menu_nocheck.bmp] \
      -foreground black

    # Create preference images
    theme::register_image pref_checked photo ttk_style background \
      {msgcat::mc "Image used in the preferences window to indicate that a table item is selected."} \
      -file [file join $::tke_dir lib images checked.gif]
    theme::register_image pref_unchecked photo ttk_style background \
      {msgcat::mc "Image used in the preferences window to indicate that a table item is deselected."} \
      -file [file join $::tke_dir lib images unchecked.gif]
    theme::register_image pref_check photo ttk_style background \
      {msgcat::mc "Image used in the preferences window to indicate that something is true."} \
      -file [file join $::tke_dir lib images check.gif]
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
      {msgcat::mc "Image used in the preferences window in the Shortcuts tab."} \
      -file [file join $::tke_dir lib images shortcut.gif]
    theme::register_image pref_plugins photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Plugins tab."} \
      -file [file join $::tke_dir lib images plugins.gif]
    theme::register_image pref_documentation photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Documentation tab."} \
      -file [file join $::tke_dir lib images documentation.gif]
    theme::register_image pref_advanced photo ttk_style background \
      {msgcat::mc "Image used in the preferences window in the Advanced tab."} \
      -file [file join $::tke_dir lib images advanced.gif]

  }

  ######################################################################
  # Create the main GUI interface.
  proc create {} {

    variable widgets
    variable search_method
    variable fif_method

    # Set the application icon photo
    wm iconphoto . [image create photo -file [file join $::tke_dir lib images tke_logo_128.gif]]
    wm geometry  . 800x600

    # Create images
    create_images

    # Create the panedwindow
    set widgets(pw) [ttk::panedwindow .pw -orient horizontal]

    # Add the sidebar
    set widgets(sb) [sidebar::create $widgets(pw).sb]

    # Create panedwindow (to support split pane view)
    $widgets(pw) add [ttk::frame $widgets(pw).tf]

    # Create the notebook panedwindow
    set widgets(nb_pw) [ttk::panedwindow $widgets(pw).tf.nbpw -orient horizontal]

    # Add notebook
    add_notebook

    # Pack the notebook panedwindow
    pack $widgets(nb_pw) -fill both -expand yes

    # Create the find_in_files widget
    set max_width          [expr [msgcat::mcmax "Regexp" "Glob" "Exact"] + 1]
    set widgets(fif)       [ttk::frame .fif]
    ttk::label $widgets(fif).lf -text [format "%s: " [msgcat::mc "Find"]]
    set widgets(fif_find)  [ttk::entry $widgets(fif).ef]
    set widgets(fif_type)  [ttk::button $widgets(fif).type -style BButton -width $max_width -command [list gui::handle_menu_popup $widgets(fif).type .fif.typeMenu]]
    set widgets(fif_case)  [ttk::checkbutton $widgets(fif).case -text "Aa" -variable gui::case_sensitive]
    ttk::label $widgets(fif).li -text [format "%s: " [msgcat::mc "In"]]
    set widgets(fif_in)    [tokenentry::tokenentry $widgets(fif).ti -font [$widgets(fif_find) cget -font] \
      -tokenshape square -highlightthickness 2 -highlightbackground white -highlightcolor white]
    set widgets(fif_save)  [ttk::checkbutton $widgets(fif).save -text [msgcat::mc "Save"] \
      -variable gui::saved -command [list search::update_save fif]]
    set widgets(fif_close) [ttk::label $widgets(fif).close -image form_close]

    # Create the search type menu
    set type_menu [menu $widgets(fif).typeMenu -tearoff 0]
    $type_menu add radiobutton -label [msgcat::mc "Regexp"] -variable gui::fif_method -value "regexp" -command [list $widgets(fif_type) configure -text [msgcat::mc "Regexp"]]
    $type_menu add radiobutton -label [msgcat::mc "Glob"]   -variable gui::fif_method -value "glob"   -command [list $widgets(fif_type) configure -text [msgcat::mc "Glob"]]
    $type_menu add radiobutton -label [msgcat::mc "Exact"]  -variable gui::fif_method -value "exact"  -command [list $widgets(fif_type) configure -text [msgcat::mc "Exact"]]

    tooltip::tooltip $widgets(fif_case) [msgcat::mc "Case sensitivity"]

    bind $widgets(fif_find)          <Return>    [list gui::check_fif_for_return]
    bind [$widgets(fif_in) entrytag] <Return>    { if {[gui::check_fif_for_return]} break }
    bind $widgets(fif_case)          <Return>    [list gui::check_fif_for_return]
    bind $widgets(fif_save)          <Return>    [list gui::check_fif_for_return]
    bind $widgets(fif_find)          <Escape>    [list set gui::user_exit_status 0]
    bind [$widgets(fif_in) entrytag] <Escape>    [list set gui::user_exit_status 0]
    bind $widgets(fif_case)          <Escape>    [list set gui::user_exit_status 0]
    bind $widgets(fif_save)          <Escape>    [list set gui::user_exit_status 0]
    bind $widgets(fif_close)         <Button-1>  [list set gui::user_exit_status 0]
    bind $widgets(fif_find)          <Up>        "search::traverse_history fif  1; break"
    bind $widgets(fif_find)          <Down>      "search::traverse_history fif -1; break"
    bind $widgets(fif_close)         <Key-space> [list set gui::user_exit_status 0]

    # Make the fif_in field a drop target
    make_drop_target $widgets(fif_in) tokenentry -types {files dirs}

    grid columnconfigure $widgets(fif) 1 -weight 1
    grid $widgets(fif).lf    -row 0 -column 0 -sticky ew -pady 2
    grid $widgets(fif).ef    -row 0 -column 1 -sticky ew -pady 2
    grid $widgets(fif).type  -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $widgets(fif).case  -row 0 -column 3 -sticky news -padx 2 -pady 2
    grid $widgets(fif).close -row 0 -column 4 -sticky news -padx 2 -pady 2
    grid $widgets(fif).li    -row 1 -column 0 -sticky ew -pady 2
    grid $widgets(fif).ti    -row 1 -column 1 -sticky ew -pady 2
    grid $widgets(fif).save  -row 1 -column 3 -sticky news -padx 2 -pady 2 -columnspan 2

    # Create the documentation search bar
    set widgets(doc) [ttk::frame .doc]
    ttk::label       $widgets(doc).l1f   -text [format "%s: " [msgcat::mc "Search"]]
    ttk::menubutton  $widgets(doc).mb    -menu [menu .doc.docPopup -tearoff 0]
    ttk::label       $widgets(doc).l2f   -text [format "%s: " [msgcat::mc "for"]]
    ttk::entry       $widgets(doc).e
    ttk::checkbutton $widgets(doc).save  -text [msgcat::mc "Save"] -variable gui::saved \
      -command [list search::update_save docsearch]
    ttk::label       $widgets(doc).close -image form_close

    bind $widgets(doc).e     <Return>    [list set gui::user_exit_status 1]
    bind $widgets(doc).e     <Escape>    [list set gui::user_exit_status 0]
    bind $widgets(doc).e     <Up>        "search::traverse_history docsearch  1; break"
    bind $widgets(doc).e     <Down>      "search::traverse_history docsearch -1; break"
    bind $widgets(doc).mb    <Return>    [list set gui::user_exit_status 1]
    bind $widgets(doc).mb    <Escape>    [list set gui::user_exit_status 0]
    bind $widgets(doc).save  <Return>    [list set gui::user_exit_status 1]
    bind $widgets(doc).save  <Escape>    [list set gui::user_exit_status 0]
    bind $widgets(doc).close <Button-1>  [list set gui::user_exit_status 0]
    bind $widgets(doc).close <Key-space> [list set gui::user_exit_status 0]

    pack $widgets(doc).l1f   -side left -padx 2 -pady 2
    pack $widgets(doc).mb    -side left -padx 2 -pady 2
    pack $widgets(doc).l2f   -side left -padx 2 -pady 2
    pack $widgets(doc).e     -side left -padx 2 -pady 2 -fill x -expand yes
    pack $widgets(doc).save  -side left -padx 2 -pady 2
    pack $widgets(doc).close -side left -padx 2 -pady 2

    # Create the information bar
    set widgets(info)        [ttk::frame .if]
    set widgets(info_state)  [ttk::label .if.l1]
    ttk::separator .if.s1 -orient vertical
    set widgets(info_msg)    [ttk::label .if.l2]
    ttk::separator .if.s2 -orient vertical
    set widgets(info_encode) [ttk::button .if.enc -style BButton -command [list gui::handle_menu_popup .if.enc [gui::create_encoding_menu .if.enc]]]
    ttk::separator .if.s3 -orient vertical
    set widgets(info_indent) [ttk::button .if.ind -style BButton -command [list gui::handle_menu_popup .if.ind [indent::create_menu .if.ind]]]
    ttk::separator .if.s4 -orient vertical
    set widgets(info_syntax) [ttk::button .if.syn -style BButton -command [list gui::handle_menu_popup .if.syn [syntax::create_menu .if.syn]]]
    ttk::label     .if.sp -text " "

    $widgets(info_encode) configure -state disabled
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
    pack .if.enc -side right -padx 2 -pady 2
    pack .if.s4  -side right -padx 2 -pady 10 -fill y

    # Create the configurable response widget
    set widgets(ursp)       [ttk::frame .rf]
    set widgets(ursp_label) [ttk::label .rf.l]
    set widgets(ursp_entry) [ttk::entry .rf.e]
    ttk::label .rf.close -image form_close

    bind $widgets(ursp_entry) <Return>    [list set gui::user_exit_status 1]
    bind $widgets(ursp_entry) <Escape>    [list set gui::user_exit_status 0]
    bind .rf.close            <Button-1>  [list set gui::user_exit_status 0]
    bind .rf.close            <Key-space> [list set gui::user_exit_status 0]

    # Make the user field a drag and drop target
    make_drop_target $widgets(ursp_entry) entry

    grid rowconfigure    .rf 0 -weight 1
    grid columnconfigure .rf 1 -weight 1
    grid $widgets(ursp_label) -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(ursp_entry) -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .rf.close            -row 0 -column 2 -sticky news -padx 2 -pady 2

    # Pack the notebook
    grid rowconfigure    . 0 -weight 1
    grid columnconfigure . 0 -weight 1
    grid $widgets(pw)   -row 0 -column 0 -sticky news
    grid $widgets(info) -row 1 -column 0 -sticky ew

    ttk::separator .sep -orient horizontal

    # Create tab popup
    set widgets(menu) [menu $widgets(nb_pw).popupMenu -tearoff 0 -postcommand gui::setup_tab_popup_menu]
    $widgets(menu) add command -label [msgcat::mc "Close Tab"]            -command [list gui::close_current]
    $widgets(menu) add command -label [msgcat::mc "Close All Other Tabs"] -command gui::close_others
    $widgets(menu) add command -label [msgcat::mc "Close All Tabs"]       -command gui::close_all
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Close Other Tabs In Pane"] -command gui::close_others_current_pane
    $widgets(menu) add command -label [msgcat::mc "Close All Tabs In Pane"]   -command gui::close_current_pane
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Hide Tab"]         -command [list gui::hide_current]
    $widgets(menu) add separator
    $widgets(menu) add checkbutton -label [msgcat::mc "Split View"] -onvalue 1 -offvalue 0 \
      -variable menus::show_split_pane -command [list gui::toggle_split_pane]
    $widgets(menu) add checkbutton -label [msgcat::mc "Bird's Eye View"] -onvalue 1 -offvalue 0 \
      -variable menus::show_birdseye -command [list gui::toggle_birdseye]
    $widgets(menu) add separator
    $widgets(menu) add checkbutton -label [msgcat::mc "Locked"] -onvalue 1 -offvalue 0 \
      -variable gui::file_locked    -command [list gui::set_current_file_lock_with_current]
    $widgets(menu) add checkbutton -label [msgcat::mc "Favorited"] -onvalue 1 -offvalue 0 \
      -variable gui::file_favorited -command [list gui::set_current_file_favorite_with_current]
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Show in Sidebar"]    -command gui::show_current_in_sidebar
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Move to Other Pane"] -command gui::move_to_pane

    # Add the menu to the themable widgets
    theme::register_widget $widgets(menu) menus
    theme::register_widget .doc.docPopup  menus

    # Add plugins to tab popup
    plugins::handle_tab_popup $widgets(menu)

    # Add the menu bar
    menus::create

    # Show the sidebar (if necessary)
    if {[preferences::get View/ShowSidebar]} {
      show_sidebar_view
    } else {
      hide_sidebar_view
    }

    # Show the console (if necessary)
    if {[preferences::get View/ShowConsole]} {
      show_console_view
    } else {
      # hide_console_view
    }

    # Show the tabbar (if necessary)
    if {[preferences::get View/ShowTabBar]} {
      show_tab_view
    } else {
      hide_tab_view
    }

    # Show the status bar (if necessary)
    if {[preferences::get View/ShowStatusBar]} {
      show_status_view
    } else {
      hide_status_view
    }

    # Save the initial state since this value can be modified from Vim
    set_matching_char [preferences::get Editor/HighlightMatchingChar]

    # Make sure that the browse directory is updated
    handle_browse_directory

    # Set the default search method
    if {![preferences::get Editor/VimMode]} {
      set search_method [preferences::get Find/DefaultMethod]
    }

    # Set the default Find in Files search method
    set fif_method [preferences::get Find/DefaultFIFMethod]

    # Add the available encodings to the command launcher
    foreach encname [encoding names] {
      launcher::register [format "%s: %s" [msgcat::mc "Encoding"] [string toupper $encname]] [list gui::set_current_encoding $encname]
    }

    # If the user attempts to close the window via the window manager, treat
    # it as an exit request from the menu system.
    wm protocol . WM_DELETE_WINDOW [list menus::exit_command]

    # Trace changes to the Appearance/Theme preference variable
    trace variable preferences::prefs(Editor/WarningWidth)                 w gui::handle_warning_width_change
    trace variable preferences::prefs(Editor/MaxUndo)                      w gui::handle_max_undo
    trace variable preferences::prefs(Editor/HighlightMatchingChar)        w gui::handle_matching_char
    trace variable preferences::prefs(Editor/HighlightMismatchingChar)     w gui::handle_bracket_audit
    trace variable preferences::prefs(Editor/RelativeLineNumbers)          w gui::handle_relative_line_numbers
    trace variable preferences::prefs(Editor/LineNumberAlignment)          w gui::handle_line_number_alignment
    trace variable preferences::prefs(View/AllowTabScrolling)              w gui::handle_allow_tab_scrolling
    trace variable preferences::prefs(Editor/VimMode)                      w gui::handle_vim_mode
    trace variable preferences::prefs(Appearance/EditorFont)               w gui::handle_editor_font
    trace variable preferences::prefs(General/AutoChangeWorkingDirectory)  w gui::handle_auto_cwd
    trace variable preferences::prefs(General/DefaultFileBrowserDirectory) w gui::handle_browse_directory
    trace variable preferences::prefs(View/ShowBirdsEyeView)               w gui::handle_show_birdseye
    trace variable preferences::prefs(View/BirdsEyeViewFontSize)           w gui::handle_birdseye_font_size
    trace variable preferences::prefs(View/BirdsEyeViewWidth)              w gui::handle_birdseye_width
    trace variable preferences::prefs(View/EnableCodeFolding)              w gui::handle_code_folding
    trace variable preferences::prefs(Appearance/CursorWidth)              w gui::handle_cursor_width
    trace variable preferences::prefs(Appearance/ExtraLineSpacing)         w gui::handle_extra_line_spacing

    # Create general UI bindings
    bind all <Control-plus>  [list gui::handle_font_change 1]
    bind all <Control-minus> [list gui::handle_font_change -1]

  }

  ######################################################################
  # Handles any menu popups that are needed in the information bar
  proc handle_menu_popup {w mnu} {

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
      $txt configure -warnwidth [preferences::get Editor/WarningWidth]
    }

  }

  ######################################################################
  # Handles any preference changes to the Editor/MaxUndo setting.
  proc handle_max_undo {name1 name2 op} {

    # Set the max_undo to the specified value
    foreach txt [get_all_texts] {
      $txt configure -maxundo [preferences::get Editor/MaxUndo]
    }

  }

  ######################################################################
  # Handles any preference changes to the Editor/HighlightMatchingChar setting.
  proc handle_matching_char {name1 name2 op} {

    set_matching_char [preferences::get Editor/HighlightMatchingChar]

  }

  ######################################################################
  # Sets the -matchchar value on all displayed text widgets.
  proc set_matching_char {value} {

    variable show_match_chars

    # Save this value because it can be changed from Vim
    set show_match_chars $value

    # Update all existing text widgets to the new value
    foreach txt [get_all_texts] {
      $txt configure -matchchar $value
    }

  }

  ######################################################################
  # Handles any preference changes to the Editor/HighlightMismatchingChar setting.
  proc handle_bracket_audit {name1 name2 op} {

    # Get the preference value
    set value [preferences::get Editor/HighlightMismatchingChar]

    # Set the -matchaudit option in each opened text widget to the given value
    foreach txt [get_all_texts] {
      $txt configure -matchaudit $value
    }

  }

  ######################################################################
  # Handles any changes to the Editor/RelativeLineNumbers preference
  # value.  Updates all text widgets to the given value.
  proc handle_relative_line_numbers {name1 name2 op} {

    set linemap_type [expr {[preferences::get Editor/RelativeLineNumbers] ? "relative" : "absolute"}]

    foreach txt [get_all_texts] {
      $txt configure -linemap_type $linemap_type
    }

  }

  ######################################################################
  # Handles any changes to the Editor/LineNumberAlignment preference value.
  # Updates all text widgets to the given value.
  proc handle_line_number_alignment {name1 name2 op} {

    set value [preferences::get Editor/LineNumberAlignment]

    foreach txt [get_all_texts] {
      $txt configure -linemap_align $value
    }

  }

  ######################################################################
  # Handles any changes to the View/AllowTabScrolling preference variable.
  proc handle_allow_tab_scrolling {name1 name2 op} {

    variable widgets

    foreach pane [$widgets(nb_pw) panes] {
      $pane.tbf.tb configure -mintabwidth [expr {[preferences::get View/AllowTabScrolling] ? [lindex [$pane.tbf.tb configure -mintabwidth] 3] : 1}]
    }

  }

  ######################################################################
  # Handles any changes to the Editor/VimMode preference variable.
  proc handle_vim_mode {name1 name2 op} {

    vim::set_vim_mode_all

  }

  ######################################################################
  # Updates all of the fonts in the text window to the given.
  proc handle_editor_font {name1 name2 op} {

    # Update the size of the editor_font
    font configure editor_font {*}[font configure TkFixedFont] {*}[preferences::get Appearance/EditorFont]

  }

  ######################################################################
  # Changes the value of the automatic change working directory variable
  # and updates the current working directory with the current file
  # information.
  proc handle_auto_cwd {name1 name2 op} {

    set_auto_cwd [preferences::get General/AutoChangeWorkingDirectory]

  }

  ######################################################################
  # Changes the value of the browse directory variable to match the value
  # specified in the preference file.
  proc handle_browse_directory {{name1 ""} {name2 ""} {op ""}} {

    variable browse_dir

    # Set the browse directory to the value
    set browse_dir [preferences::get General/DefaultFileBrowserDirectory]

    # Adjust browse_dir to be last if the browse directory type was an actual pathname and it
    # does not exist.
    if {([lsearch [list last buffer current] $browse_dir] == -1) && ![file isdirectory $browse_dir]} {
      set browse_dir "last"
    }

  }

  ######################################################################
  # Handle any preference changes to the birdseye view status.
  proc handle_show_birdseye {name1 name2 op} {

    if {[preferences::get View/ShowBirdsEyeView]} {
      foreach tab [files::get_tabs] {
        if {![winfo exists [get_info $tab tab txt2]]} {
          show_birdseye $tab
        }
      }
    } else {
      foreach tab [files::get_tabs] {
        if {![winfo exists [get_info $tab tab txt2]]} {
          hide_birdseye $tab
        }
      }
    }

  }

  ######################################################################
  # Handle any preference changes to the birdseye font size.
  proc handle_birdseye_font_size {name1 name2 op} {

    set font_size [preferences::get View/BirdsEyeViewFontSize]

    foreach txt [get_all_texts] {
      if {[string first "tf2" $txt] == -1} {
        if {[winfo exists [get_info $txt txt beye]]} {
          $beye configure -font "-size $font_size"
        }
      }
    }

  }

  ######################################################################
  # Handle any preference changes to the birdseye width.
  proc handle_birdseye_width {name1 name2 op} {

    set width [preferences::get View/BirdsEyeViewWidth]

    foreach txt [get_all_texts] {
      if {[string first "tf2" $txt] == -1} {
        if {[winfo exists [get_info $txt txt beye]]} {
          $beye configure -width $width
        }
      }
    }

  }

  ######################################################################
  # Handle any changes to the View/EnableCodeFolding preference value.
  proc handle_code_folding {name1 name2 op} {

    set enable [preferences::get View/EnableCodeFolding]

    foreach txt [get_all_texts] {
      folding::set_fold_enable $txt $enable
    }

  }

  ######################################################################
  # Handles any changes to the Appearance/CursorWidth preference value.
  proc handle_cursor_width {name1 name2 op} {

    set width [preferences::get Appearance/CursorWidth]

    foreach txt [get_all_texts] {
      if {![$txt cget -blockcursor]} {
        $txt configure -insertwidth $width
      }
    }

  }

  ######################################################################
  # Handles any changes to the Appearance/ExtraLineSpacing preference
  # value.
  proc handle_extra_line_spacing {name1 name2 op} {

    set spacing [preferences::get Appearance/ExtraLineSpacing]

    foreach txt [get_all_texts] {
      $txt configure -spacing2 $spacing -spacing3 $spacing
    }

  }

  ######################################################################
  # Sets the auto_cwd variable to the given boolean value.
  proc set_auto_cwd {value} {

    variable auto_cwd

    # Update the auto_cwd variable and if a file exists, update the current
    # working directory if auto_cwd is true.
    if {[set auto_cwd $value] && [files::get_file_num]} {

      # Get the current file information
      get_info {} current fname buffer diff

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
    variable file_locked
    variable file_favorited
    variable pw_current

    # Get the current information
    get_info {} current txt fname readonly lock diff tabbar remote buffer txt2 beye

    # Set the file_locked and file_favorited variable
    set file_locked    $lock
    set file_favorited [favorites::is_favorite $fname]

    # Set the state of the menu items
    if {[files::get_file_num] > 1} {
      $widgets(menu) entryconfigure [msgcat::mc "Close All Other Tabs"] -state normal
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Close All Other Tabs"] -state disabled
    }
    if {[llength [$widgets(nb_pw) panes]] == 2} {
      if {[llength [$tabbar tabs]] > 1} {
        $widgets(menu) entryconfigure [msgcat::mc "Close Other Tabs In Pane"] -state normal
      } else {
        $widgets(menu) entryconfigure [msgcat::mc "Close Other Tabs In Pane"] -state disabled
      }
      $widgets(menu) entryconfigure [msgcat::mc "Close All Tabs In Pane"] -state normal
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Close Other Tabs In Pane"] -state disabled
      $widgets(menu) entryconfigure [msgcat::mc "Close All Tabs In Pane"]   -state disabled
    }
    if {$diff} {
      $widgets(menu) entryconfigure [msgcat::mc "Hide Tab"] -state disabled
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Hide Tab"] -state normal
    }
    if {([llength [$tabbar tabs]] > 1) || ([llength [$widgets(nb_pw) panes]] > 1)} {
      $widgets(menu) entryconfigure [format "%s*" [msgcat::mc "Move"]] -state normal
    } else {
      $widgets(menu) entryconfigure [format "%s*" [msgcat::mc "Move"]] -state disabled
    }
    if {$readonly || $diff} {
      $widgets(menu) entryconfigure [msgcat::mc "Locked"] -state disabled
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Locked"] -state normal
    }
    if {![file exists $fname]} {
      $widgets(menu) entryconfigure [msgcat::mc "Favorited"]       -state disabled
      $widgets(menu) entryconfigure [msgcat::mc "Show in Sidebar"] -state disabled
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Show in Sidebar"] -state normal
      $widgets(menu) entryconfigure [msgcat::mc "Favorited"]       -state [expr {($diff || $buffer || ($remote ne "")) ? "disabled" : "normal"}]
    }

    # Make the split pane and bird's eye indicators look correct
    set menus::show_split_pane [winfo exists $txt2]
    set menus::show_birdseye   [winfo exists $beye]

    # Handle plugin states
    plugins::menu_state $widgets(menu) tab_popup

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

    if {[catch { tkcon show }]} {
      catch { console show }
    }

  }

  ######################################################################
  # Hides the console.
  proc hide_console_view {} {

    if {[catch { tkcon hide }]} {
      catch { console hide }
    }

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
  proc set_line_number_view {value} {

    # Show the line numbers in the current editor
    [current_txt] configure -linemap $value

  }

  ######################################################################
  # Sets the minimum line number width of the line gutter to the given
  # value.
  proc set_line_number_width {val} {

    variable numberwidth

    set numberwidth $val

    for {set i 0} {$i < [files::get_file_num]} {incr i} {
      [get_info $i fileindex txt] configure -linemap_minwidth $val
    }

  }

  ######################################################################
  # Updates the contents of the text within the tab as well as the
  # title bar information to match the given tab.
  proc update_tab {tab} {

    get_info $tab tab tabbar fname

    # Update the tab name
    $tabbar tab $tab -text " [file tail $fname]"

    # Update the title if necessary
    set_title

  }

  ######################################################################
  # Save the window geometry to the geometry.dat file.
  proc save_session {} {

    variable widgets
    variable last_opened

    puts "In save_session"

    # Gather content to save
    set content(Geometry)                [::window_geometry .]
    set content(Fullscreen)              [wm attributes . -fullscreen]
    set content(CurrentWorkingDirectory) [pwd]
    set content(Sidebar)                 [sidebar::save_session]
    set content(Launcher)                [launcher::save_session]

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
        get_info $tab tab paneindex txt fname save_cmd lock readonly diff sidebar buffer remember remote txt2 beye encode

        # If we need to forget this file, don't save it to the session
        if {!$remember || ($remote ne "")} {
          continue
        }

        set finfo(pane)        $paneindex
        set finfo(fname)       $fname
        set finfo(savecommand) $save_cmd
        set finfo(lock)        $lock
        set finfo(readonly)    $readonly
        set finfo(diff)        $diff
        set finfo(sidebar)     $sidebar
        set finfo(buffer)      $buffer
        set finfo(remember)    $remember
        set finfo(encode)      $encode

        # Save the tab as a current tab if it's not a buffer
        if {!$finfo(buffer) && !$current_set} {
          set current_tab $tabindex
          if {[$nb.tbf.tb select] eq $tab} {
            set current_set 1
          }
        }

        set finfo(tab)         $tabindex
        set finfo(language)    [syntax::get_language $txt]
        set finfo(indent)      [indent::get_indent_mode $txt]
        set finfo(modified)    0
        set finfo(cursor)      [$txt index insert]
        set finfo(xview)       [lindex [$txt xview] 0]
        set finfo(yview)       [lindex [$txt yview] 0]
        set finfo(beye)        [winfo exists $beye]
        set finfo(split)       [winfo exists $txt2]

        # Add markers
        set finfo(markers) [list]
        foreach {mname mtxt pos} [markers::get_markers $tab] {
          lappend finfo(markers) $mname [lindex [split $pos .] 0]
        }

        # Add diff data, if applicable
        if {$finfo(diff)} {
          set finfo(diffdata) [diff::get_session_data $txt]
        }
        lappend content(FileInfo) [array get finfo]

        incr tabindex

      }

      # Set the current tab for the pane (if one exists)
      puts "current_tab: $current_tab"
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
  proc load_session {info new} {

    variable widgets
    variable last_opened
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

    array set finfo {
      xview  0
      yview  0
      cursor ""
      beye   0
      split  0
    }

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

    # Load the session information into the launcher
    launcher::load_session $content(Launcher)

    # If we are loading a new TKE session, exit now since we don't want to load the rest
    if {$new} return

    # Load the session information into the sidebar
    sidebar::load_session $content(Sidebar)

    # Set the current working directory to the saved value
    if {[file exists $content(CurrentWorkingDirectory)]} {
      cd $content(CurrentWorkingDirectory)
    }

    # Put the list in order
    if {[llength $content(FileInfo)] > 0} {
      set ordered     [lrepeat 2 [lrepeat [llength $content(FileInfo)] ""]]
      set i           0
      foreach finfo_list $content(FileInfo) {
        array set finfo $finfo_list
        lset ordered $finfo(pane) $finfo(tab) $i
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
            set tab [add_file $finfo(tab) $finfo(fname) \
              -savecommand $finfo(savecommand) -lock $finfo(lock) -readonly $finfo(readonly) \
              -diff $finfo(diff) -sidebar $finfo(sidebar) -lazy 1 \
              -xview $finfo(xview) -yview $finfo(yview) -cursor $finfo(cursor) -lang $finfo(language)]
            get_info $tab tab txt
            if {[info exists finfo(indent)]} {
              indent::set_indent_mode $txt $finfo(indent)
            }
            if {[info exists finfo(encode)]} {
              set_encoding $tab $finfo(encode)
            }
            if {$finfo(diff) && [info exists finfo(diffdata)]} {
              diff::set_session_data $txt $finfo(diffdata)
            }
            if {$finfo(split)} {
              show_split_pane $tab
            }
            if {$finfo(beye)} {
              show_birdseye $tab
            }
            if {[info exists finfo(markers)]} {
              foreach {mname line} $finfo(markers) {
                markers::add $tab line $line $mname
              }
            }
          }
        }
      }
      if {$tab ne ""} {
        if {[catch { get_info [lindex $content(CurrentTabs) $pane] tabindex tabbar tab }]} {
          set_current_tab [get_info $pane paneindex tabbar] $tab
        } else {
          set_current_tab $tabbar $tab
        }
      }
    }

  }

  ######################################################################
  # Makes the next tab in the notebook viewable.
  proc next_tab {} {

    # Get the location information for the current tab in the current pane
    get_info {} current tabbar tabindex

    # If the new tab index is at the end, circle to the first tab
    if {[incr tabindex] == [$tabbar index end]} {
      set tabindex 0
    }

    # Select the next tab
    set_current_tab $tabbar [lindex [$tabbar tabs -shown] $tabindex]

  }

  ######################################################################
  # Makes the previous tab in the notebook viewable.
  proc previous_tab {} {

    # Get the location information for the current tab in the current pane
    get_info {} current tabbar tabindex

    # If the new tab index is at the less than 0, circle to the last tab
    if {[incr tabindex -1] == -1} {
      set tabindex [expr [$tabbar index end] - 1]
    }

    # Select the previous tab
    set_current_tab $tabbar [lindex [$tabbar tabs -shown] $tabindex]

  }

  ######################################################################
  # Makes the last viewed tab in the notebook viewable.
  proc last_tab {} {

    # Get the current tabbar
    get_info {} current tabbar

    # Select the last tab
    set_current_tab $tabbar [lindex [$tabbar tabs -shown] [$tabbar index last]]

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
      get_info {} current tabbar tab
      set_current_tab $tabbar $tab
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
  proc sync_birdseye_helper {tab top} {

    variable be_after_id

    # Get the current tab
    if {[winfo exists [get_info $tab tab beye]]} {
      $beye yview moveto $top
    }

    set be_after_id($tab) ""

  }

  ######################################################################
  # Sync the birdseye text widget.
  proc sync_birdseye {tab top} {

    variable be_after_id
    variable be_ignore

    # If bird's eye view is not enabled, exit immediately
    if {![info exists be_after_id($tab)]} {
      return
    }

    if {$be_after_id($tab) ne ""} {
      after cancel $be_after_id($tab)
    }

    if {$be_ignore($tab) == 0} {
      set be_after_id($tab) [after 50 [list gui::sync_birdseye_helper $tab $top]]
    }

    set be_ignore($tab) 0

  }

  ######################################################################
  # Sets the yview of the given text widget (called by the yscrollbar)
  # and adjusts the scroll of the other pane if sync scrolling is enabled.
  proc yview {tab txt args} {

    # Return the yview information
    if {[llength $args] == 0} {
      return [$txt yview]

    # Otherwise, set the yview given the arguments
    } else {
      $txt yview {*}$args
      sync_birdseye $tab [lindex $args 1]
      sync_scroll   $txt 0
    }

  }

  ######################################################################
  # Implements yscrollcommand for an editing buffer.  Adjusts the scrollbar
  # position and performs synchronized scrolling, if enabled.
  proc yscrollcommand {tab txt vb args} {

    # Set the vertical scrollbar position
    $vb set {*}$args

    # Set birdseye view
    sync_birdseye $tab [lindex $args 0]

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
  proc select_all {} {

    # Get the current text widget
    set txt [current_txt]

    # Set the selection to include everything
    $txt tag add sel 1.0 end

  }

  ######################################################################
  # Returns true if we have only a single tab that has not been modified
  # or named.
  proc untitled_check {} {

    variable widgets

    if {[files::get_file_num] == 1} {
      get_info {} current fname buffer txt
      if {($fname eq "Untitled") && $buffer && ([ctext::get_cleaned_content $txt first [list last -adjust "-1c"] {}] eq "")} {
        return 1
      }
    }

    return 0

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

    variable widgets
    variable pw_current
    variable undo_count

    # Handle options
    array set opts [list \
      -lock       0 \
      -readonly   0 \
      -sidebar    0 \
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
      if {($name ne "Untitled") && !$opts(-other)} {
        close_tab [get_info {} current tab] -keeptab 0
      }
    }

    # If the file is already loaded, display the tab
    if {($name ne "Untitled") && ([set file_index [files::get_index $name $opts(-remote) -buffer 1]] != -1)} {

      if {!$opts(-background)} {
        get_info $file_index fileindex tabbar tab
        set_current_tab $tabbar $tab
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
      get_info $pw_current paneindex tabbar

      # Get the current index
      set tab [insert_tab $tabbar $index $name -gutters $opts(-gutters) -tags $opts(-tags) -lang $opts(-lang)]

      # Create the file info structure
      files::add $name $tab \
        -save_cmd $save_command \
        -lock     $opts(-lock) \
        -readonly $opts(-readonly) \
        -sidebar  $opts(-sidebar) \
        -buffer   1 \
        -gutters  $opts(-gutters) \
        -tags     $opts(-tags) \
        -remote   $opts(-remote)

      # Get the current text widget
      get_info $tab tab txt tabbar

      # Change the tab text
      $tabbar tab $tab -text " [file tail $name]"

      # Add the file's directory to the sidebar and highlight it
      if {$opts(-sidebar)} {
        sidebar::add_directory [file normalize [file dirname $name]] -remote $opts(-remote)
        # sidebar::highlight_filename $name 0
      }

      # Make this tab the currently displayed tab
      if {!$opts(-background)} {
        set_current_tab $tabbar $tab
      }

      set undo_count($tab) 0

    }

    # Set the tab image for the current file
    set_tab_image $tab

    return $tab

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

    array set opts {
      -name    "Untitled"
      -save_as ""
    }
    array set opts $args

    # Add the buffer
    return [add_buffer $index $opts(-name) {eval files::save_new_file $opts(-save_as)} {*}$args]

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
      -cursor      1.0
      -xview       0
      -yview       0
      -lang        ""
    }
    array set opts $args

    # If have a single untitled tab in view, close it before adding the file
    if {[untitled_check] && !$opts(-other)} {
      close_tab [get_info {} current tab] -keeptab 0
    }

    # If the file is already loaded, display the tab
    if {[set file_index [files::get_index $fname $opts(-remote) -diff $opts(-diff)]] != -1} {

      # Get the tab associated with the given file index
      get_info $file_index fileindex tabbar tab

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
      get_info $pw_current paneindex tabbar

      # Add the tab to the editor frame
      set tab [insert_tab $tabbar $index $fname -diff $opts(-diff) -gutters $opts(-gutters) -tags $opts(-tags) -lang $opts(-lang)]

      # Create the file information
      files::add $fname $tab \
        -save_cmd $opts(-savecommand) \
        -lock     $opts(-lock) \
        -readonly $opts(-readonly) \
        -sidebar  $opts(-sidebar) \
        -buffer   0 \
        -gutters  $opts(-gutters) \
        -diff     $opts(-diff) \
        -tags     $opts(-tags) \
        -loaded   0 \
        -remember $opts(-remember) \
        -remote   $opts(-remote) \
        -xview    $opts(-xview) \
        -yview    $opts(-yview) \
        -cursor   $opts(-cursor)

      # Run any plugins that should run when a file is opened
      plugins::handle_on_open [expr [files::get_file_num] - 1]

    }

    # Add the file's directory to the sidebar and highlight it
    if {$opts(-sidebar)} {
      sidebar::add_directory [file dirname $fname] -remote $opts(-remote)
      sidebar::highlight_filename $fname [expr ($opts(-diff) * 2) + 1]
    }

    # Make this tab the currently displayed tab
    if {!$opts(-lazy)} {
      set_current_tab $tabbar $tab
    }

    # Set the tab image for the current file
    set_tab_image $tab

    return $tab

  }

  ######################################################################
  # Inserts the file information and sets the
  proc add_tab_content {tab} {

    variable undo_count

    # Get some of the file information
    get_info $tab tab tabbar txt fname diff loaded lock readonly xview yview cursor remember

    # Indicate that we are loading the tab
    $tabbar tab $tab -busy 1

    if {!$loaded && [files::get_file $tab contents]} {

      # If we are locked, make sure that we enable the text widget for insertion
      if {$lock || $readonly} {
        $txt configure -state normal
      }

      # Initialize the undo count
      set undo_count($tab) 0

      # Check the highlightable value
      check_highlightable $txt $contents

      # Insert the file contents
      $txt insert end $contents

      # Highlight text and add update code folds
      $txt see 1.0

      # Add any previous markers saved for this text widget
      markers::tagify $tab

      # Check brackets
      ctext::checkAllBrackets $txt

      # Change the text to unmodified
      $txt edit reset
      files::set_info $tab tab modified 0

      # Set the insertion mark to the first position
      ::tk::TextSetCursor $txt.t $cursor

      # Set the yview
      $txt xview moveto $xview
      $txt yview moveto $yview

      # Add the file to the list of recently opened files
      if {$remember} {
        add_to_recently_opened $fname
      }

      # Parse Vim modeline information, if needed
      vim::parse_modeline $txt

      # If a diff command was specified, run and parse it now
      if {$diff} {
        diff::show $txt
      }

      # If we are locked, make sure that we disable the text widget
      if {$lock || $readonly} {
        $txt configure -state disabled
      }

      # Update tab
      update_tab $tab

    }

    # Specify that we have completed loading the tab
    $tabbar tab $tab -busy 0

  }

  ######################################################################
  # Returns true if the given file contents should be highlighted.  We
  # make this decision by examining the length of each line.  If a line
  # exceeds a given length, we know this will cause problems with the
  # Tk text widget.
  proc check_highlightable {txt contents} {

    variable widgets

    set highlightable 1

    foreach line [split $contents \n] {
      if {[string length $line] > 8192} {
        set highlightable 0
        break;
      }
    }

    # Set the highlight value
    $txt configure -highlight $highlightable

    # Update the auto-indentation value
    indent::update_auto_indent $txt.t $widgets(info_indent)

  }

  ######################################################################
  # Add a list of files to the editor panel and raise the window to
  # make it visible.
  proc add_files_and_raise {host index args} {

    # Add the list of files to the editor panel.
    foreach fname [lreverse $args] {
      if {[file isdirectory $fname]} {
        sidebar::add_directory [files::normalize $host $fname] -select 1
      } elseif {![::check_file_for_import $fname]} {
        add_file $index [files::normalize $host $fname]
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

    variable undo_count

    # Get the file information
    get_info $file_index fileindex tabbar tab txt fname diff lock remote

    # If the editor is a difference view and is not updateable, stop now
    if {$diff && ![diff::updateable $txt]} {
      return
    }

    # Get the current insertion index
    set insert_index [$txt index insert]

    # Delete the text widget
    $txt configure -state normal
    $txt delete 1.0 end

    if {[files::get_file $tab contents]} {

      # Updat the highlightability attribute of the text widget
      check_highlightable $txt $contents

      # Read the file contents and insert them
      $txt insert end $contents

      # Change the tab text
      $tabbar tab $tab -text " [file tail $fname]"

      # Update the title bar (if necessary)
      set_title

      # Change the text to unmodified
      $txt edit reset
      set undo_count($txt) 0
      files::set_info $file_index fileindex modified 0

      # Set the insertion mark to the first position
      ::tk::TextSetCursor $txt.t $insert_index

      # If a diff command was specified, run and parse it now
      if {$diff} {
        diff::show $txt
      }

      # Allow plugins to be run on update
      plugins::handle_on_update $file_index

    }

    # If we are locked, set our state back to disabled
    if {$lock} {
      $txt configure -state disabled
    }

  }

  ######################################################################
  # Updates the currently displayed file.
  proc update_current {} {

    get_info {} current fileindex tab

    # Update the file
    update_file $fileindex



  }

  ######################################################################
  # Prompts the user for a file save name.  Returns the name of the selected
  # filename; otherwise, returns the empty string to indicate that no
  # filename was selected.
  proc prompt_for_save {} {

    # Get the directory of the current file
    set dirname [gui::get_browse_directory]

    # Get the list of save options
    set save_opts [list]
    if {[llength [set extensions [syntax::get_extensions]]] > 0} {
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
  # Sets the EOL translation setting for the current file to the given value.
  proc set_current_eol_translation {value} {

    # Get the file index of the current file
    files::set_info [get_info {} current fileindex] fileindex eol $value

  }

  ######################################################################
  # Sets the current text status modification value to the specified value
  # and updates the titlebar and tabbar
  proc set_current_modified {value} {

    # Get the current file information
    get_info {} current tabbar tab txt fname

    # Set the file modified status to the given value
    files::set_info $tab tab modified $value

    # Set the text widget status
    if {$value == 0} {
      $txt edit modified $value
    }

    # Update the current tab text
    $tabbar tab $tab -text [format "%s %s" [expr {$value ? " *" : ""}] [file tail $fname]]

    # Update the title
    set_title

  }

  ######################################################################
  # This is called whenever we undo/redo.  Checks to see if the current
  # buffer should be indicated as being not modified.
  proc check_for_modified {txtt} {

    variable undo_count

    get_info [winfo parent $txtt] txt tabbar tab fname

    if {$undo_count($tab) == [$txtt edit undocount]} {
      files::set_info $tab tab modified 0
      $txtt edit modified 0
      $tabbar tab $tab -text [format " %s" [file tail $fname]]
      set_title
    }

  }

  ######################################################################
  # Saves the current tab contents.  Returns 1 if the save was successful;
  # otherwise, returns a value of 0.
  proc save_current {args} {

    variable undo_count

    array set opts {
      -force   0
      -save_as ""
      -remote  ""
    }
    array set opts $args

    # Get current information
    get_info {} current tabbar tab txt fileindex fname buffer save_cmd diff buffer mtime sidebar lang

    # If the current file is a buffer and it has a save command, run the save command
    if {$buffer && ($save_cmd ne "")} {

      # Execute the save command.  If it errors or returns a value of 0, return immediately
      if {[catch { {*}$save_cmd $fileindex } rc]} {
        return 0
      } elseif {$rc == 0} {
        set_current_modified 0
        return 1
      }

      # Retrieve some values in case they changed in the save command
      get_info {} current fname buffer save_cmd

    }

    # Get the difference mode of the current file
    set matching_index -1

    # If a save_as name is specified, change the filename
    if {$opts(-save_as) ne ""} {

      # Add the file to the sidebar and indicate that it is opened
      sidebar::highlight_filename $fname [expr $diff * 2]
      set matching_index [files::get_index $opts(-save_as) $opts(-remote)]

      # Set the filename, remote tag indicator and set the tab attributes to match
      # the same as a file
      files::set_info $fileindex fileindex \
        fname [set fname [file normalize $opts(-save_as)]] \
        remote [set remote $opts(-remote)] \
        readonly 0 buffer 0 remember 1

      # Update the tab image to reflect that fact that we not readonly
      set_tab_image $tab

    # If the current file doesn't have a filename, allow the user to set it
    } elseif {$buffer || $diff} {

      if {[set sfile [prompt_for_save]] eq ""} {
        return 0
      } else {
        set matching_index [files::get_index $sfile ""]
        files::set_info $fileindex fileindex fname [set fname $sfile]
      }

    }

    # Run the on_save plugins
    plugins::handle_on_save $fileindex

    # If we need to do a force write, do it now
    set perms ""
    if {![save_prehandle $fname $opts(-save_as) $opts(-force) perms]} {
      return 0
    }

    # If the file already exists in one of the open tabs, close it now
    if {$matching_index != -1} {
      close_tab [files::get_info $matching_index fileindex tab] -keeptab 0 -check 0
    }

    # Save the file contents
    if {![files::set_file $tab [scrub_text $txt]]} {
      return 0
    }

    # If we need to do a force write, do it now
    if {![save_posthandle $fname $perms]} {
      return 0
    }

    # If the file doesn't have a timestamp, it's a new file so add and highlight it in the sidebar
    if {($mtime eq "") || ($opts(-save_as) ne "")} {

      # Add the filename to the most recently opened list
      add_to_recently_opened $fname

      # If it is okay to add the file to the sidebar, do it now
      if {$sidebar} {
        sidebar::insert_file [sidebar::add_directory [file dirname $fname] -remote $opts(-remote)] $fname $opts(-remote)
        sidebar::highlight_filename $fname [expr ($diff * 2) + 1]
      }

      # Syntax highlight the file
      syntax::set_language $txt [syntax::get_default_language $fname]

    }

    # If the information panel needs to be updated for this file, do it now
    sidebar::update_info_panel_for_file $fname $opts(-remote)

    # Set the modified state to 0
    set_current_modified 0
    set undo_count($tab) [$txt edit undocount]

    # If there is a save command, run it now
    if {$save_cmd ne ""} {
      eval {*}$save_cmd $fileindex

    # Otherwise, if the file type is TclPlugin, automatically reload the plugin
    } elseif {[lsearch [list PluginTcl PluginHeader] $lang] != -1} {
      plugins::reload
    }

    return 1

  }

  ######################################################################
  # Saves all of the opened tab contents (if necessary).  If a tab has
  # not been previously saved (a new file), that tab is made the current
  # tab and the save_current procedure is called.
  proc save_all {} {

    variable undo_count

    for {set i 0} {$i < [files::get_file_num]} {incr i} {

      # Get file information
      get_info $i fileindex tabbar tab txt fname modified diff save_cmd buffer

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
            $tabbar tab $tab -text " [file tail $fname]"

            # Change the text to unmodified
            $txt edit modified false
            set undo_count($tab) [$txt edit undocount]
            files::set_info $i fileindex modified 0

          # Save the current
          } else {

            set_current_tab $tabbar $tab
            save_current -force 1

          }

        # Perform a tab-only save
        } else {

          # Run the on_save plugins
          plugins::handle_on_save $i

          # Save the file contents
          if {![files::set_file $tab [scrub_text $txt]]} {
            continue
          }

          # Change the tab text
          $tabbar tab $tab -text " [file tail $fname]"

          # Change the text to unmodified
          $txt edit modified false
          set undo_count($tab) [$txt edit undocount]
          files::set_info $i fileindex modified 0

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
  proc close_check {tab force exiting} {

    # Get the tab information
    get_info $tab tab tabbar fname modified diff

    # If the file needs to be saved, do it now
    if {$modified && !$diff && !$force} {
      set fname [file tail $fname]
      set msg   [format "%s %s?" [msgcat::mc "Save"] $fname]
      set_current_tab $tabbar $tab
      if {[set answer [tk_messageBox -default yes -type [expr {$exiting ? {yesno} : {yesnocancel}}] -message $msg -title [msgcat::mc "Save request"]]] eq "yes"} {
        return [save_current -force $force]
      } elseif {$answer eq "cancel"} {
        return 0
      }
    }

    return 1

  }

  ######################################################################
  # Returns 1 if the tab is closable; otherwise, returns a value of 0.
  # Saves the tab if it needs to be saved.
  proc close_check_by_tabbar {w tab} {

    return [close_check $tab 0 0]

  }

  ######################################################################
  # Close the current tab.  If -force is set to 1, closes regardless of
  # modified state of text widget.  If -force is set to 0 and the text
  # widget is modified, the user will be questioned if they want to save
  # the contents of the file prior to closing the tab.
  proc close_current {args} {

    array set opts {
      -force   0
      -exiting 0
    }
    array set opts $args

    close_tab [get_info {} current tab] -force $opts(-force) -exiting $opts(-exiting)

  }


  ######################################################################
  # Closes the tab specified by "tab".  This is called by the tabbar when
  # the user clicks on the close button of a tab.
  proc close_tab_by_tabbar {w tab} {

    variable pw_current

    # Close the tab specified by tab (we don't need to check because the check
    # will have already been performed with the -checkcommand passed to the
    # tabbar.
    close_tab $tab -tabbar $w -check 0

    return 1

  }

  ######################################################################
  # Close the specified tab (do not ask the user about closing the tab).
  proc close_tab {tab args} {

    variable widgets
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

    # Get information
    get_info $tab tab pane tabbar tabindex txt txt2 fileindex fname diff

    # Figure out if the tab has txt2 opened
    set txt2_exists [winfo exists $txt2]

    # Perform save check on close
    if {$opts(-check)} {
      if {![close_check $tab $opts(-force) $opts(-exiting)]} {
        return
      }
    }

    # Unhighlight the file in the file browser (if the file was not a difference view)
    sidebar::highlight_filename $fname [expr $diff * 2]

    # Run the close event for this file
    plugins::handle_on_close $fileindex

    # Delete the file from files
    files::remove $tab

    # Remove the tab from the tabbar (unless this has already been done by the tabbar)
    if {$opts(-tabbar) eq ""} {
      $tabbar delete $tabindex
    } else {
      set tabbar     $opts(-tabbar)
      set pane       [winfo parent [winfo parent $tabbar]]
      set pw_current [lsearch [$widgets(nb_pw) panes] $pane]
    }

    # Delete the text frame
    catch { pack forget $tab }

    # Destroy the text frame
    destroy $tab

    # Clean up any code that is reliant on the text widget (if we are not exiting
    # the application) to avoid memory leaks
    if {!$opts(-exiting)} {
      cleanup_txt $txt
      if {$txt2_exists} {
        cleanup_txt $txt2
      }
    }

    # Display the current pane (if one exists)
    if {!$opts(-lazy) && ([set tab [$tabbar select]] ne "")} {
      set_current_tab $tabbar $tab
    }

    # If we have no more tabs and there is another pane, remove this pane
    if {([llength [$tabbar tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] > 1)} {
      $widgets(nb_pw) forget $pane
      set pw_current 0
      set tabbar     [get_info 0 paneindex tabbar]
    }

    # Add a new file if we have no more tabs, we are the only pane, and the preference
    # setting is to not close after the last tab is closed.
    if {([llength [$tabbar tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] == 1) && !$opts(-exiting)} {
      if {[preferences::get General/ExitOnLastClose] || $::cl_exit_on_close} {
        menus::exit_command
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

    set current_nb  [lindex [$widgets(nb_pw) panes] $pw_current]
    set current_tab [$current_nb.tbf.tb select]

    foreach nb [lreverse [$widgets(nb_pw) panes]] {
      foreach tab [lreverse [$nb.tbf.tb tabs]] {
        if {$tab ne $current_tab} {
          close_tab $tab -lazy 1
        }
      }
    }

    # Set the current tab
    get_info {} current tabbar tab
    set_current_tab $tabbar $tab

  }

  ######################################################################
  # Close all of the tabs.
  proc close_all {args} {

    variable widgets

    array set opts {
      -force   0
      -exiting 0
    }
    array set opts $args

    foreach nb [lreverse [$widgets(nb_pw) panes]] {
      foreach tab [lreverse [$nb.tbf.tb tabs]] {
        close_tab $tab -lazy 1 {*}$args
      }
    }

  }

  ######################################################################
  # Closes all other tabs within the current pane.
  proc close_others_current_pane {} {

    variable widgets
    variable pw_current

    set nb          [lindex [$widgets(nb_pw) panes] $pw_current]
    set current_tab [$nb.tbf.tb select]

    foreach tab [lreverse [$nb.tbf.tb tabs]] {
      if {$tab ne $current_tab} {
        close_tab $tab -lazy 1
      }
    }

    # Set the current tab
    get_info {} current tabbar tab
    set_current_tab $tabbar $tab

  }

  ######################################################################
  # Closes all tabs within the current pane.
  proc close_current_pane {} {

    variable widgets
    variable pw_current

    set nb [lindex [$widgets(nb_pw) panes] $pw_current]

    foreach tab [lreverse [$nb.tbf.tb tabs]] {
      close_tab $tab -lazy 1
    }

  }

  ######################################################################
  # Closes the tabs with the given file indices.
  proc close_files {indices} {

    if {[llength $indices] > 0} {

      # Perform a lazy close
      foreach index [lsort -decreasing $indices] {
        catch { close_tab [get_info $index fileindex tab] -lazy 1 }
      }

      # Set the current tab
      get_info {} current tabbar tab
      set_current_tab $tabbar $tab

    }

  }

  ######################################################################
  # Closes all of the opened files that exist within the given directories
  proc close_dir_files {dirs} {

    set set_current 0

    foreach dir $dirs {
      foreach index [lreverse [files::get_indices fname $dir*]] {
        close_tab [get_info $index fileindex tab] -lazy 1
        set set_current 1
      }
    }

    # Set the current tab if we have lost it
    if {$set_current} {
      get_info {} current tabbar tab
      set_current_tab $tabbar $tab
    }

  }

  ######################################################################
  # Hides the given tab.
  proc hide_tab {tab} {

    variable widgets

    # Get the current tabbar
    get_info $tab tab tabbar fname remote

    # Hide the tab
    $tabbar tab $tab -state hidden

    # Make sure the sidebar is updated properly
    sidebar::set_hide_state $fname $remote 1

    # Update ourselves to reflect the current tab show in the tabbar
    show_current_tab $tabbar

  }

  ######################################################################
  # Makes the given tab visible in the tabbar.
  proc show_tab {tab} {

    variable widgets

    # Get the current tabbar
    get_info $tab tab tabbar fname remote

    # Show the tab
    $tabbar tab $tab -state normal

    # Make sure the sidebar is updated properly
    sidebar::set_hide_state $fname $remote 0

    # Update ourselves to reflect the current tab show in the tabbar
    show_current_tab $tabbar

  }

  ######################################################################
  # Hides the current tab.
  proc hide_current {} {

    # Get the current tabbar and tab
    hide_tab [get_info {} current tab]

  }

  ######################################################################
  # Hides all of the files with the given filenames.  The parameter must
  # be a list with the following format:
  #   {filename remote}+
  proc hide_files {indices} {

    # Perform a lazy close
    foreach index [lsort -decreasing $indices] {
      hide_tab [get_info $index fileindex tab]
    }

  }

  ######################################################################
  # Hides all of the opened files.
  proc hide_all {} {

    foreach tab [files::get_tabs] {
      hide_tab $tab
    }

  }

  ######################################################################
  # Shows all of the files with the given filenames.  The parameter must
  # be a list with the following format:
  #   {filename remote}+
  proc show_files {indices} {

    # Make sure that all specified files are shown
    foreach index [lsort -decreasing $indices] {
      show_tab [get_info $index fileindex tab]
    }

  }

  ######################################################################
  # Shows all of the files.
  proc show_all {} {

    foreach tab [files::get_tabs] {
      show_tab $tab
    }

  }

  ######################################################################
  # Sorts all of the open tabs (in both panes, if both panes are visible)
  # by alphabetical order.
  proc sort_tabs {} {

    variable widgets

    foreach nb [$widgets(nb_pw) panes] {

      get_info $nb pane tabbar tab

      # Get the list of opened tabs
      set tabs [list]
      foreach atab [$tabbar tabs] {
        set fullname [$tabbar tab $atab -text]
        regexp {(\S+)$} $fullname -> name
        lappend tabs [list $name $fullname $atab]
        $tabbar delete $atab
      }

      # Sort the tabs by alphabetical order and move them
      foreach atab [lsort -index 0 $tabs] {
        lassign $atab name fullname tabid
        $tabbar insert end $tabid -text $fullname -emboss 0
      }

      # Reset the current tab
      $tabbar select $tab

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
    get_info {} current pane tabbar tab tabindex

    # Get the current title
    set title [$tabbar tab $tabindex -text]

    # Remove the tab from the tabbar
    $tabbar delete $tabindex

    # Remove the tab from the current pane
    catch { pack forget $tab }

    # Display the current pane (if one exists)
    if {[set ctab [$tabbar select]] ne ""} {
      set_current_tab $tabbar $ctab
      set pw_current [expr $pw_current ^ 1]
    } else {
      $widgets(nb_pw) forget $pane
      set pw_current 0
    }

    # Get the other tabbar
    get_info {} current tabbar

    # Make sure that tabbar is visible
    grid $tabbar

    # Add the new tab to the notebook in alphabetical order (if specified)
    if {[preferences::get View/OpenTabsAlphabetically]} {
      set added 0
      foreach t [$tabbar tabs] {
        if {[string compare $title [$tabbar tab $t -text]] == -1} {
          $tabbar insert $t $tab -text $title -emboss 0
          set added 1
          break
        }
      }
      if {$added == 0} {
        $tabbar insert end $tab -text $title -emboss 0
      }

    # Otherwise, add the tab in the specified location
    } else {
      $tabbar insert end $tab -text $title -emboss 0
    }

    # Now move the current tab from the previous current pane to the new current pane
    set_current_tab $tabbar $tab

    # Set the tab image for the moved file
    set_tab_image $tab

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
  proc undo {} {

    # Get the current textbox
    set txt [current_txt]

    # Perform the undo operation from Vim perspective
    vim::undo $txt.t

  }

  ######################################################################
  # Returns true if there is something in the undo buffer.
  proc undoable {} {

    # Get the current textbox
    set txt [current_txt]

    return [$txt edit undoable]

  }

  ######################################################################
  # This procedure performs an redo operation.
  proc redo {} {

    # Get the current textbox
    set txt [current_txt]

    # Perform the redo operation from Vim perspective
    vim::redo $txt.t

  }

  ######################################################################
  # Returns true if there is something in the redo buffer.
  proc redoable {} {

    # Get the current textbox
    set txt [current_txt]

    return [$txt edit redoable]

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

  ######################################################################
  # Returns true if text is currently selected in the current buffer.
  proc selected {} {

    if {([set txt [current_txt]] ne "") && \
        ([llength [$txt tag ranges sel]] > 0)} {
      return 1
    } else {
      return 0
    }

  }

  ##############################################################################
  # This procedure performs a text selection paste operation.  Returns 1 if the
  # paste operation was performed on the current text widget; otherwise, returns 0.
  proc paste {} {

    # Get the current text widget
    set txt [current_txt]

    # If the current txt widget has the focus, paste clipboard contents to it and record the
    # paste with the Vim namespace.
    if {[focus] eq "$txt.t"} {

      # Perform the paste
      $txt paste

      # Handle the Vim paste
      vim::handle_paste $txt

      return 1

    }

    return 0

  }

  ######################################################################
  # This procedure performs a paste operation, formatting the pasted text
  # to match the code that it is being pasted into.
  proc paste_and_format {} {

    if {![catch {clipboard get}]} {

      # Get the length of the clipboard text
      set cliplen [string length [clipboard get]]

      # Get the position of the insertion cursor
      set insertpos [[current_txt] index insert]

      # Perform the paste operation
      if {[paste]} {

        # Have the indent namespace format the clipboard contents
        indent::format_text [current_txt].t $insertpos "$insertpos+${cliplen}c"

      }

    }

  }

  ######################################################################
  # Returns true if there is something in the paste buffer and the current
  # editor is editable.
  proc pastable {} {

    return [expr {![catch {clipboard get} contents] && ($contents ne "") && [editable]}]

  }

  ######################################################################
  # Returns true if the current editor is editable.
  proc editable {} {

    return [expr {[[current_txt] cget -state] eq "normal"}]

  }

  ######################################################################
  # Formats either the selected text (if type is "selected") or the entire
  # file contents (if type is "all").
  proc format_text {} {

    # Get the file information
    get_info {} current txt fname lock readonly

    # Get the locked/readonly status
    set readonly [expr $lock || $readonly]

    # If the file is locked or readonly, set the state so that it can be modified
    if {$readonly} {
      $txt configure -state normal
    }

    # If any text is selected, format it
    if {[llength [set selected [$txt tag ranges sel]]] > 0} {
      foreach {endpos startpos} [lreverse [$txt tag ranges sel]] {
        indent::format_text $txt.t $startpos $endpos
      }

    # Otherwise, select the full file
    } else {
      indent::format_text $txt.t 1.0 end
    }

    # If the file is locked or readonly, clear the modified state and reset the text state
    # back to disabled
    if {$readonly} {

      # Clear the modified state
      set_current_modified 0

      # Reset the state
      $txt configure -state disabled

    }

  }

  ######################################################################
  # Updates the menubutton label for the given widget with the current
  # value of search_method.
  proc update_search_method {tab} {

    variable search_method

    switch $search_method {
      glob    { set lbl [msgcat::mc "Glob"] }
      exact   { set lbl [msgcat::mc "Exact"] }
      default { set lbl [msgcat::mc "Regexp"] }
    }

    # Update the labels
    $tab.sf.type      configure -text $lbl
    $tab.rf.opts.type configure -text $lbl

    # If the find field for the given search type is not an empty string, perform the
    # search with the new search method
    if {[winfo ismapped $tab.sf]} {
      search::find_resilient "next" "find"
    } elseif {[winfo ismapped $tab.rf]} {
      search::find_resilient "next" "replace"
    }

  }

  ######################################################################
  # Called whenever the user changes the search text.
  proc handle_search_change {tab value} {

    set state [expr {($value eq "") ? "disabled" : "normal"}]

    $tab.sf.prev configure -state $state
    $tab.sf.next configure -state $state

    return 1

  }

  ######################################################################
  # Called whenever the user changes the search text.
  proc handle_replace_change {tab value} {

    set state [expr {($value eq "") ? "disabled" : "normal"}]

    $tab.rf.act.prev configure -state $state
    $tab.rf.act.next configure -state $state
    $tab.rf.act.rep  configure -state $state
    $tab.rf.act.repa configure -state $state

    return 1

  }

  ######################################################################
  # Clears the search UI for find and find/replace.
  proc search_clear {} {

    # Get the current tab
    get_info {} current tab

    # Clear the find UI
    $tab.sf.e delete 0 end
    handle_search_change $tab ""

    # Clear the find/replace UI
    $tab.rf.fe delete 0 end
    $tab.rf.re delete 0 end
    handle_replace_change $tab ""

  }

  ######################################################################
  # Displays the search bar.
  proc search {{dir "next"}} {

    variable saved

    # Get the tab information
    get_info {} current tab txt

    # Update the search method menubutton label
    update_search_method $tab

    # Display the search bar and separator
    panel_forget $tab.rf
    panel_place  $tab.sf

    # Add bindings
    bind $tab.sf.e    <Return> [list search::find_start $dir]
    bind $tab.sf.case <Return> [list search::find_start $dir]
    bind $tab.sf.save <Return> [list search::find_start $dir]

    # Reset the saved indicator
    set saved 0

    # If a line or less is selected, populate the search bar with it
    if {([llength [set ranges [$txt tag ranges sel]]] == 2) && ([$txt count -lines {*}$ranges] == 0)} {
      $tab.sf.e delete 0 end
      $tab.sf.e insert end [$txt get {*}$ranges]
    } else {
      $tab.sf.e selection range 0 end
    }

    # Place the focus on the search bar
    focus $tab.sf.e

    # Set the unfocussed insertion cursor to hollow
    catch { $txt configure -insertunfocussed hollow }

  }

  ######################################################################
  # Performs the search operation.
  proc find_resilient {dir {type find}} {

    get_info {} current tab

    # Clear the selection of the search entry
    $tab.sf.e  selection clear
    $tab.rf.fe selection clear

    # Perform the search
    search::find_resilient $dir $type

  }

  ######################################################################
  # Closes the search widget.
  proc close_search {} {

    # Get the current text frame
    get_info {} current tab txt

    # Hide the search frame
    panel_forget $tab.sf

    # Put the focus on the text widget
    set_txt_focus [last_txt_focus]

    # Set the unfocussed insertion cursor to none
    catch { $txt configure -insertunfocussed none }

  }

  ######################################################################
  # Displays the search and replace bar.
  proc search_and_replace {} {

    variable saved

    # Get the tab information
    get_info {} current tab txt

    # Update the search method menubutton label
    update_search_method $tab

    # Display the search bar and separator
    panel_forget $tab.sf
    panel_place  $tab.rf

    # Reset the saved indicator
    set saved 0

    # If a line or less is selected, populate the find entry with it
    if {([llength [set ranges [$txt tag ranges sel]]] == 2) && ([$txt count -lines {*}$ranges] == 0)} {
      $tab.rf.fe delete 0 end
      $tab.rf.fe insert end [$txt get {*}$ranges]
    } else {
      $tab.rf.fe selection range 0 end
    }

    # Place the focus on the find entry field
    focus $tab.rf.fe

  }

  ######################################################################
  # Closes the search and replace bar.
  proc close_search_and_replace {} {

    # Get the current tab
    get_info {} current tab

    # Hide the search and replace bar
    panel_forget $tab.rf

    # Put the focus on the text widget
    set_txt_focus [last_txt_focus]

  }

  ######################################################################
  # Retrieves the current search information for the specified type.
  proc get_search_data {type} {

    variable widgets
    variable case_sensitive
    variable saved
    variable search_method

    # Get the current tab
    get_info {} current tab

    switch $type {
      "find"      { return [list find [$tab.sf.e get] method $search_method case $case_sensitive save $saved] }
      "replace"   { return [list find [$tab.rf.fe get] replace [$tab.rf.re get] method $search_method case $case_sensitive save $saved] }
      "fif"       { return [list find [$widgets(fif_find) get] in [$widgets(fif_in) tokenget] method $search_method case $case_sensitive save $saved] }
      "docsearch" { return [list find [$widgets(doc).e get] name [$widgets(doc).mb cget -text] save $saved] }
    }

  }

  ######################################################################
  # Sets the given search information in the current search widget based
  # on type.
  proc set_search_data {type data} {

    variable widgets
    variable case_sensitive
    variable saved
    variable search_method

    # Get the current tab
    get_info {} current tab

    array set data_array $data

    switch $type {
      "find" {
        set search_method  $data_array(method)
        set case_sensitive $data_array(case)
        set saved          $data_array(save)
        $tab.sf.e delete 0 end
        $tab.sf.e insert end $data_array(find)
        handle_search_change $tab $data_array(find)
      }
      "replace" {
        set search_method  $data_array(method)
        set case_sensitive $data_array(case)
        set saved          $data_array(save)
        $tab.rf.fe delete 0 end
        $tab.rf.re delete 0 end
        $tab.rf.fe insert end $data_array(find)
        $tab.rf.re insert end $data_array(replace)
        handle_replace_change $tab $data_array(find)
      }
      "fif" {
        set search_method  $data_array(method)
        set case_sensitive $data_array(case)
        set saved          $data_array(save)
        $widgets(fif_find) delete 0 end
        $widgets(fif_find) insert end $data_array(find)
        $widgets(fif_in) tokendelete 0 end
        $widgets(fif_in) tokeninsert end $data_array(in)
      }
      "docsearch" {
        set saved $data_array(save)
        $widgets(doc).mb configure -text [expr {($data_array(name) eq "") ? [[$widgets(doc).mb cget -menu] entrycget 0 -label] : $data_array(name)}]
        $widgets(doc).e  delete 0 end
        $widgets(doc).e  insert end $data_array(find)
      }
    }

  }

  ######################################################################
  # Sets the file lock to the specified value for the current file.
  proc set_tab_image {tab} {

    # Get the tab information
    get_info $tab tab tabbar txt diff readonly lock

    # Change the state of the text widget to match the lock value
    if {$diff} {
      $tabbar tab $tab -compound left -image tab_diff
      $txt configure -state disabled
    } elseif {$readonly} {
      $tabbar tab $tab -compound left -image tab_readonly
      $txt configure -state disabled
    } elseif {$lock} {
      $tabbar tab $tab -compound left -image tab_lock
      $txt configure -state disabled
    } else {
      $tabbar tab $tab -image ""
      $txt configure -state normal
    }

    return 1

  }

  ######################################################################
  # Sets the file lock to the specified value for the current file.
  proc set_current_file_lock {lock} {

    # Get the current tab information
    get_info {} current tab

    # Set the current lock status
    files::set_info $tab tab lock $lock

    # Set the tab image to match
    set_tab_image $tab

  }

  ######################################################################
  # Sets the file lock of the current editor with the value of the file_locked
  # local variable.
  proc set_current_file_lock_with_current {} {

    variable file_locked

    set_current_file_lock $file_locked

  }

  ######################################################################
  # Set or clear the favorite status of the current file.
  proc set_current_file_favorite {favorite} {

    # Get the current file name
    get_info {} current fname

    # Add or remove the file from the favorites list
    if {$favorite} {
      favorites::add $fname
    } else {
      favorites::remove $fname
    }

  }

  ######################################################################
  # Sets the file favorite of the current editor with the value of the
  # file_favorited local variable.
  proc set_current_file_favorite_with_current {} {

    variable file_favorited

    set_current_file_favorite $file_favorited

  }

  ######################################################################
  # Shows the current file in the sidebar.
  proc show_current_in_sidebar {} {

    get_info {} current fname remote

    # Display the file in the sidebar
    sidebar::view_file $fname $remote

  }

  ######################################################################
  # Sets the current information message to the given string.
  proc set_info_message {msg args} {

    variable widgets
    variable info_clear
    variable info_msgs

    array set opts {
      -clear_delay 3000
      -win         ""
    }
    array set opts $args

    if {[info exists widgets(info_msg)]} {

      if {$info_clear ne ""} {
        after cancel $info_clear
      }

      lassign [winfo rgb . [set foreground [utils::get_default_foreground]]] fr fg fb
      lassign [winfo rgb . [utils::get_default_background]] br bg bb
      $widgets(info_msg) configure -text $msg -foreground $foreground

      # Remember or clear the message for the window, if necessary
      if {$opts(-win) ne ""} {
        if {$msg eq ""} {
          unset -nocomplain info_msgs($opts(-win))
        } else {
          set info_msgs($opts(-win)) [list $msg $opts(-clear_delay)]
        }
      }

      # If the status bar is supposed to be hidden, show it now
      if {![winfo ismapped $widgets(info)]} {
        show_status_view
        set hide_info 1
      } else {
        set hide_info 0
      }

      # Call ourselves
      if {($opts(-clear_delay) > 0) && ([string trim $msg] ne "")} {
        set info_clear [after $opts(-clear_delay) \
                         [list gui::clear_info_message $hide_info \
                           [expr $fr >> 8] [expr $fg >> 8] [expr $fb >> 8] \
                           [expr $br >> 8] [expr $bg >> 8] [expr $bb >> 8] -win $opts(-win)]]
      }

    } else {

      puts $msg

    }

  }

  ######################################################################
  # Clears the info message.
  proc clear_info_message {hide_info fr fg fb br bg bb args} {

    variable widgets
    variable info_clear
    variable info_msgs

    array set opts {
      -fade_count 0
      -win        ""
    }
    array set opts $args

    if {$opts(-fade_count) == 10} {

      # Clear the text
      $widgets(info_msg) configure -text ""

      # Clear the message memory
      unset -nocomplain info_msgs($opts(-win))

      # Clear the info_clear variable
      set info_clear ""

      # If the status bar is supposed to be hidden, hide it now
      if {$hide_info} {
        hide_status_view
      }

    } else {

      # Calculate the color
      set color [format {#%02x%02x%02x} \
                  [expr $fr - ((($fr - $br) / 10) * $opts(-fade_count))] \
                  [expr $fg - ((($fg - $bg) / 10) * $opts(-fade_count))] \
                  [expr $fb - ((($fb - $bb) / 10) * $opts(-fade_count))]]

      # Set the foreground color to simulate the fade effect
      $widgets(info_msg) configure -foreground $color

      set info_clear [after 100 [list gui::clear_info_message $hide_info $fr $fg $fb $br $bg $bb -fade_count [incr opts(-fade_count)] -win $opts(-win)]]

    }

  }

  ######################################################################
  # Generates an error message parented by the main window.  Used to
  # unify the error message experience.
  proc set_error_message {msg {detail ""}} {

    tk_messageBox -parent . -icon error -title [msgcat::mc "Error"] -type ok -default ok -message $msg -detail $detail

  }

  ######################################################################
  # Sets the entire application UI state to either the normal or disabled
  # state which will allow the user to drag/drop information into the panel
  # without allowing the editor state to change.  This procedure is automatically
  # called by the panel_place and panel_forget procedures so it should
  # not need to be called directly by any other code.
  proc panel_set_ui_state {state} {

    variable widgets

    set markable [expr {($state eq "normal")}]

    # Disable the tabbars
    foreach pane [$widgets(nb_pw) panes] {
      get_info $pane pane tabbar txt txt2
      $tabbar configure -state $state
      $txt    configure -state $state -linemap_markable $markable
      if {[winfo exists $txt2]} {
        $txt2 configure -state $state -linemap_markable $markable
      }
    }

    # For good measure, we'll even disable the information bar items
    $widgets(info_encode) configure -state $state
    $widgets(info_indent) configure -state $state
    $widgets(info_syntax) configure -state $state

    # Disable the menubar
    menus::set_state $state

    # Disable the sidebar from executing
    sidebar::set_state [expr {($state eq "normal") ? "normal" : "viewonly"}]

  }

  ######################################################################
  # Places the panel in the window.
  proc panel_place {w} {

    variable widgets
    variable panel_focus

    if {[winfo parent $w] eq "."} {
      set top [winfo height $widgets(info)]
      set sep .sep
    } else {
      set top 0
      set sep [winfo parent $w].sep
    }

    set stop [winfo reqheight $sep]
    set wtop [winfo reqheight $w]

    # Place the separator
    place $sep -relwidth 1.0 -rely 1.0 -y [expr 0 - ($top + $stop)]
    raise $sep

    # Place the window and make sure that the window is raised above all others
    place $w -relwidth 1.0 -rely 1.0 -y [expr 0 - ($top + $stop + $wtop)]
    raise $w

    # Disable the UI
    # panel_set_ui_state disabled

    # Remember who has the focus
    set panel_focus [focus]

  }

  ######################################################################
  # Forget the pnael.
  proc panel_forget {w} {

    variable panel_focus

    if {[winfo parent $w] eq "."} {
      set sep .sep
    } else {
      set sep [winfo parent $w].sep
    }

    # Remove the given panels from display
    place forget $w
    place forget $sep

    # Enable the UI
    # panel_set_ui_state normal

    # Return the focus
    if {$panel_focus ne ""} {
      focus $panel_focus
      set panel_focus ""
    }

  }

  ######################################################################
  # Gets user input from the interface in a generic way.
  proc get_user_response {msg pvar args} {

    variable widgets

    array set opts {
      -allow_vars 0
      -selrange   {}
    }
    array set opts $args

    upvar $pvar var

    # Initialize the widget
    $widgets(ursp_label) configure -text $msg
    $widgets(ursp_entry) delete 0 end

    # If var contains a value, display it and select it
    if {$var ne ""} {
      $widgets(ursp_entry) insert end $var
      if {$opts(-selrange) ne ""} {
        $widgets(ursp_entry) selection range {*}$opts(-selrange)
      }
    }

    # Display the user input widget
    panel_place $widgets(ursp)

    # Wait for the ursp_entry widget to be closed
    focus $widgets(ursp_entry)
    tkwait variable gui::user_exit_status

    # Hide the user input widget
    panel_forget $widgets(ursp)

    # Get the user response value
    set var [$widgets(ursp_entry) get]

    # If variable substitutions are allowed, perform any substitutions
    if {$opts(-allow_vars)} {
      set var [utils::perform_substitutions $var]
    }

    return [set gui::user_exit_status]

  }

  ######################################################################
  # Returns file information for the given file index and attribute.
  # This is called by the get_file_info API command.
  proc get_file_info {index attr} {

    # Perform error detections
    if {($index < 0) || ($index >= [files::get_file_num])} {
      return -code error [msgcat::mc "File index is out of range"]
    }

    # Get the current text widget
    get_info $index fileindex txt remote

    switch $attr {
      "sb_index" {
        return [sidebar::get_index $index $remote]
      }
      "txt" {
        return $txt.t
      }
      "current" {
        return [expr {$txt eq [current_txt]}]
      }
      "vimmode" {
        return [vim::in_vim_mode $txt.t]
      }
      "lang" {
        return [syntax::get_language $txt]
      }
      default {
        return [files::get_info $index fileindex $attr]
      }
    }

  }

  ######################################################################
  # Retrieves the "find in file" inputs from the user.
  proc fif_get_input {prsp_list} {

    variable widgets
    variable fif_files
    variable fif_method
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
    set fif_files [sidebar::get_fif_files]
    $widgets(fif_in) configure -listvar gui::fif_files -matchmode regexp -matchindex 0 -matchdisplayindex 0

    switch $fif_method {
      "regexp" { $widgets(fif_type) configure -text [msgcat::mc "Regexp"] }
      "glob"   { $widgets(fif_type) configure -text [msgcat::mc "Glob"] }
      "exact"  { $widgets(fif_type) configure -text [msgcat::mc "Exact"] }
    }

    # Display the FIF widget
    panel_place $widgets(fif)

    # Wait for the panel to be exited
    focus $widgets(fif_find)
    tkwait variable gui::user_exit_status

    # Hide the widget
    panel_forget $widgets(fif)

    # Get the list of files/directories from the list of tokens
    set ins [list]
    foreach token [$widgets(fif_in) tokenget] {
      if {[set index [lsearch -index 0 $fif_files $token]] != -1} {
        lappend ins {*}[lindex $fif_files $index 1]
      } else {
        lappend ins [utils::perform_substitutions $token]
      }
    }

    # Gather the input to return
    set rsp_list [list find [$widgets(fif_find) get] in $ins method $fif_method case $case_sensitive save $saved]

    return [set gui::user_exit_status]

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

    if {[preferences::get General/UpdateReleaseType] eq "devel"} {
      set release_type "Development"
    } else {
      set release_type "Stable"
    }

    toplevel     .aboutwin
    wm title     .aboutwin ""
    wm transient .aboutwin .
    wm resizable .aboutwin 0 0

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

    bind .aboutwin.f.if.v2 <Enter>    [list %W configure -cursor [ttk::cursor link]]
    bind .aboutwin.f.if.v2 <Leave>    [list %W configure -cursor [ttk::cursor standard]]
    bind .aboutwin.f.if.v2 <Button-1> {
      destroy .aboutwin
      gui::add_file end [file join $::tke_dir LICENSE] -sidebar 0 -readonly 1
    }
    bind .aboutwin.f.if.v5 <Enter>    [list %W configure -cursor [ttk::cursor link]]
    bind .aboutwin.f.if.v5 <Leave>    [list %W configure -cursor [ttk::cursor standard]]
    bind .aboutwin.f.if.v5 <Button-1> [list utils::open_file_externally {mailto:phase1geo@gmail.com} 1]
    bind .aboutwin.f.if.v6 <Enter>    [list %W configure -cursor [ttk::cursor link]]
    bind .aboutwin.f.if.v6 <Leave>    [list %W configure -cursor [ttk::cursor standard]]
    bind .aboutwin.f.if.v6 <Button-1> [list utils::open_file_externally {https://twitter.com/TkeTextEditor} 1]
    bind .aboutwin.f.if.v7 <Enter>    [list %W configure -cursor [ttk::cursor link]]
    bind .aboutwin.f.if.v7 <Leave>    [list %W configure -cursor [ttk::cursor standard]]
    bind .aboutwin.f.if.v7 <Button-1> [list utils::open_file_externally {http://tke.sourceforge.net} 1]

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

    ttk::frame .aboutwin.f.cf
    ttk::label .aboutwin.f.cf.l -text [msgcat::mc "Credits"] -anchor center
    ttk::separator .aboutwin.f.cf.sep1 -orient horizontal
    # ttk::labelframe .aboutwin.f.cf -text [msgcat::mc "Credits"] -labelanchor n
    set txt [text .aboutwin.f.cf.t -wrap word -height 5 -relief flat -highlightthickness 0 \
      -font "TkDefaultFont" -width 80 \
      -background [utils::get_default_background] \
      -foreground [utils::get_default_foreground] \
      -yscrollcommand { utils::set_yscrollbar .aboutwin.f.cf.vb }]
    scroller::scroller .aboutwin.f.cf.vb -orient vertical -command { .aboutwin.f.cf.t yview }
    ttk::separator .aboutwin.f.cf.sep2 -orient horizontal

    # Register the widget for theming
    theme::register_widget .aboutwin.f.cf.vb misc_scrollbar

    grid rowconfigure    .aboutwin.f.cf 2 -weight 1
    grid columnconfigure .aboutwin.f.cf 0 -weight 1
    grid .aboutwin.f.cf.l    -row 0 -column 0 -sticky ew -columnspan 2 -padx 2 -pady 4
    grid .aboutwin.f.cf.sep1 -row 1 -column 0 -sticky ew -columnspan 2
    grid .aboutwin.f.cf.t    -row 2 -column 0 -sticky news
    grid .aboutwin.f.cf.vb   -row 2 -column 1 -sticky ns
    grid .aboutwin.f.cf.sep2 -row 3 -column 0 -sticky ew -columnspan 2

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
    ttk::label .aboutwin.f.copyright -text [format "%s %d-%d" [msgcat::mc "Copyright"] 2013 19]

    pack .aboutwin.f.logo      -padx 2 -pady 8 -anchor w
    pack .aboutwin.f.if        -padx 2 -pady 2
    pack .aboutwin.f.credits   -padx 2 -pady 2
    pack .aboutwin.f.copyright -padx 2 -pady 8

    pack .aboutwin.f -fill both -expand yes

    # Center the window in the editor window
    ::tk::PlaceWindow .aboutwin widget .

    # Add credit information
    $txt insert end "Special thanks to the following:\n\n"
    $txt insert end "\uff65 The " {} "filerunner" frlink " project for creating and sharing their FTP and SFTP codebase to make built-in remote file editing possible.\n\n" {}
    $txt insert end "\uff65 Dr. Casaba Nemethi for his full-featured " {} "tablelist" tllink " project.\n\n" {}
    $txt insert end "\uff65 Jean-Claude Wippler for his excellent webdav package.\n\n" {}

    $txt tag configure frlink -underline 1
    $txt tag bind frlink <Enter>    [list $txt configure -cursor [ttk::cursor link]]
    $txt tag bind frlink <Leave>    [list $txt configure -cursor [ttk::cursor standard]]
    $txt tag bind frlink <Button-1> [list utils::open_file_externally "http://filerunner.sourceforge.net"]

    $txt tag configure tllink -underline 1
    $txt tag bind tllink <Enter>    [list $txt configure -cursor [ttk::cursor link]]
    $txt tag bind tllink <Leave>    [list $txt configure -cursor [ttk::cursor standard]]
    $txt tag bind tllink <Button-1> [list utils::open_file_externally "http://www.nemethi.de"]

    # Make sure that the user cannot change the text.
    $txt configure -state disabled

    wm withdraw .aboutwin
    update

    set x [expr [winfo reqwidth .aboutwin.f.cf] + 4]
    # set x [expr max( [winfo reqwidth .aboutwin.f.logo], [winfo reqwidth .aboutwin.f.if], [winfo reqwidth .aboutwin.f.cf] ) + 4]
    set y [expr [winfo reqheight .aboutwin.f.logo] + [winfo reqheight .aboutwin.f.credits] + [winfo reqheight .aboutwin.f.copyright] + 40]
    incr y [winfo reqheight .aboutwin.f.if]
    wm geometry .aboutwin ${x}x${y}
    wm deiconify .aboutwin

  }

  ######################################################################
  # Displays the number insertion dialog box if we are currently in
  # multicursor mode.
  proc insert_numbers {txt} {

    if {[multicursor::enabled $txt]} {

      set var1 ""

      # Get the number string from the user
      if {[get_user_response [msgcat::mc "Starting number:"] var1]} {

        # Insert the numbers (if not successful, output an error to the user)
        if {![multicursor::insert_numbers $txt $var1]} {
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
  proc toggle_split_pane {} {

    get_info {} current tab txt2

    if {[winfo exists $txt2]} {
      hide_split_pane $tab
    } else {
      show_split_pane $tab
    }

  }

  ######################################################################
  # Toggles the bird's eye view panel for the current tab.
  proc toggle_birdseye {} {

    get_info {} current tab beye

    if {[winfo exists $beye]} {
      hide_birdseye $tab
    } else {
      show_birdseye $tab
    }

  }

  ######################################################################
  # Returns a list of all of the text widgets in the tool.
  proc get_all_texts {} {

    set txts [list]

    foreach tab [files::get_tabs] {
      get_info $tab tab txt txt2
      lappend txts $txt
      if {[winfo exists $txt2]} {
        lappend txts $txt2
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
  #   - current   (from_type only)
  #   - pane      (using in from implies the current pane)
  #   - paneindex (using in from implies the current pane index)
  #   - tabbar    (using in from implies the current tabbar)
  #   - tab
  #   - tabindex  (using in from implies the index of the tab in the current pane)
  #   - fileindex
  #   - txt
  #   - txt2
  #   - focus
  #   - beye
  #   - fname
  #   - lang
  #   - any key from file information (for to_types only)
  #
  # Throws an error if there were conversion issues.
  proc get_info {from from_type args} {

    variable widgets
    variable pw_current
    variable txt_current

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
        files::get_info $from fileindex tab
      }
      txt -
      txt2 {
        set tab [winfo parent [winfo parent [winfo parent $from]]]
      }
      beye {
        set tab [winfo parent $from]
      }
      fname {
        files::get_info $from fname tab
      }
    }

    if {$tab eq ""} {
      set paneindex $pw_current
    } else {
      set panes     [$widgets(nb_pw) panes]
      set paneindex [expr {(([llength $panes] == 1) || ([lsearch [[lindex $panes 0].tbf.tb tabs] $tab] != -1)) ? 0 : 1}]
    }

    set i 0
    foreach to_type $args {
      upvar $to_type type$i
      switch $to_type {
        pane {
          set type$i [lindex [$widgets(nb_pw) panes] $paneindex]
        }
        paneindex {
          set type$i $paneindex
        }
        tabbar {
          set type$i [lindex [$widgets(nb_pw) panes] $paneindex].tbf.tb
        }
        tab {
          if {$tab eq ""} {
            return -code error "Unable to get tab information"
          }
          set type$i $tab
        }
        tabindex {
          if {$tab eq ""} {
            return -code error "Unable to get tab index information"
          }
          set type$i [lsearch [[lindex [$widgets(nb_pw) panes] $paneindex].tbf.tb tabs] $tab]
        }
        txt {
          if {$tab eq ""} {
            return -code error "Unable to get txt information"
          }
          set type$i "$tab.pw.tf.txt"
        }
        txt2 {
          if {$tab eq ""} {
            return -code error "Unable to get txt2 information"
          }
          set type$i "$tab.pw.tf2.txt"
        }
        focus {
          if {($tab eq "") || ![info exists txt_current($tab)]} {
            return -code error "Unable to get focus information"
          }
          set type$i $txt_current($tab)
        }
        beye {
          if {$tab eq ""} {
            return -code error "Unable to get beye information"
          }
          set type$i "$tab.be"
        }
        lang {
          if {$tab eq ""} {
            return -code error "Unable to get lang information"
          }
          set type$i [syntax::get_language "$tab.pw.tf.txt"]
        }
        default {
          if {$tab eq ""} {
            return -code error "Unable to get $to_type information"
          }
          set type$i [files::get_info $tab tab $to_type]
        }
      }
      set retval [set type$i]
      incr i
    }

    return $retval

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
    tabbar::tabbar $nb.tbf.tb -closeimage tab_close -activecloseimage tab_activeclose \
      -command      [list gui::handle_tabbar_select] \
      -checkcommand [list gui::close_check_by_tabbar] \
      -closecommand [list gui::close_tab_by_tabbar]

    # Configure the tabbar
    $nb.tbf.tb configure {*}[theme::get_category_options tabs 1]

    grid rowconfigure    $nb.tbf 0 -weight 1
    grid columnconfigure $nb.tbf 0 -weight 1
    grid $nb.tbf.tb    -row 0 -column 0 -sticky news
    grid remove $nb.tbf.tb

    bind [$nb.tbf.tb scrollpath left]  <Button-$::right_click> [list gui::show_tabs $nb.tbf.tb left]
    bind [$nb.tbf.tb scrollpath right] <Button-$::right_click> [list gui::show_tabs $nb.tbf.tb right]

    # Create popup menu for extra tabs
    menu $nb.tbf.tb.mnu -tearoff 0

    ttk::frame $nb.tf

    pack $nb.tbf -fill x
    pack $nb.tf  -fill both -expand yes

    bind [$nb.tbf.tb btag] <ButtonPress-$::right_click> {
      if {[%W cget -state] eq "disabled"} {
        return
      }
      if {[info exists gui::tab_tip(%W)]} {
        unset gui::tab_tip(%W)
        tooltip::tooltip clear %W
        tooltip::hide
      }
      set pane            [winfo parent [winfo parent [winfo parent %W]]]
      set gui::pw_current [lsearch [$gui::widgets(nb_pw) panes] [winfo parent [winfo parent [winfo parent %W]]]]
      if {![catch { [winfo parent %W] select @%x,%y }]} {
        gui::set_current_tab [winfo parent %W] [[winfo parent %W] select]
        tk_popup $gui::widgets(menu) %X %Y
      }
    }

    # Handle tooltips
    bind [$nb.tbf.tb btag] <Motion> [list gui::handle_notebook_motion %W %x %y]

    # Register the tabbar and menu for theming
    theme::register_widget $nb.tbf.tb     tabs
    theme::register_widget $nb.tbf.tb.mnu menus

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
    get_info $tab tab fname remote

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

    if {[preferences::get View/OpenTabsAlphabetically] && ($index eq "end")} {

      set sorted_index 0

      if {![catch { get_info {} current tabbar }]} {
        foreach tab [$tabbar tabs] {
          regexp {(\S+)$} [$tabbar tab $tab -text] -> curr_title
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
    variable show_match_chars

    array set opts {
      -diff    0
      -gutters [list]
      -tags    [list]
      -lang    ""
    }
    array set opts $args

    # Get the scrollbar coloring information
    array set sb_opts [theme::get_category_options text_scrollbar 1]

    # Get the unique tab ID
    set id [incr curr_id]

    # Calculate the title name
    set title [file tail $fname]

    # Make the tabbar visible and the syntax menubutton enabled
    grid $tb
    $widgets(info_encode) configure -state normal
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
      -highlightcolor orange -warnwidth [preferences::get Editor/WarningWidth] \
      -maxundo [preferences::get Editor/MaxUndo] \
      -insertwidth [preferences::get Appearance/CursorWidth] \
      -spacing2 [preferences::get Appearance/ExtraLineSpacing] \
      -spacing3 [preferences::get Appearance/ExtraLineSpacing] \
      -diff_mode $opts(-diff) -matchchar $show_match_chars \
      -matchaudit [preferences::get Editor/HighlightMismatchingChar] \
      -linemap_mark_command [list gui::mark_command $tab] -linemap_mark_color orange \
      -linemap_relief flat -linemap_minwidth $numberwidth -linemap_separator 1 \
      -linemap_type [expr {[preferences::get Editor/RelativeLineNumbers] ? "relative" : "absolute"}] \
      -linemap_align [preferences::get Editor/LineNumberAlignment] \
      -xscrollcommand [list $tab.pw.tf.hb set] -yscrollcommand [list gui::yscrollcommand $tab $txt $tab.pw.tf.vb]
    scroller::scroller $tab.pw.tf.hb {*}[array get sb_opts] -orient horizontal -autohide 0 -command [list $txt xview]
    scroller::scroller $tab.pw.tf.vb {*}[array get sb_opts] -orient vertical   -autohide 1 -command [list gui::yview $tab $txt] \
      -markcommand1 [list markers::get_positions $tab] -markhide1 [expr [preferences::get View/ShowMarkerMap] ^ 1] \
      -markcommand2 [expr {$opts(-diff) ? [list diff::get_marks $txt] : ""}]

    # Update the widgets to match the current theme
    update_theme $txt

    # Register the widgets
    theme::register_widget $txt          syntax
    theme::register_widget $tab.pw.tf.vb text_scrollbar
    theme::register_widget $tab.pw.tf.hb text_scrollbar

    # Create the editor font if it does not currently exist
    if {[lsearch [font names] editor_font] == -1} {
      font create editor_font {*}[font configure TkFixedFont] {*}[preferences::get Appearance/EditorFont]
    }

    $txt configure -font editor_font

    bind Ctext  <<Modified>>          [list gui::text_changed %W %d]
    bind $txt.t <FocusIn>             [list +gui::handle_txt_focus %W]
    bind $txt.t <<CursorChanged>>     [list +gui::update_position $txt]
    bind $txt.l <ButtonPress-1>       [list gui::select_line %W %x %y]
    bind $txt.l <B1-Motion>           [list gui::select_lines %W %x %y]
    bind $txt.l <Shift-ButtonPress-1> [list gui::select_lines %W %x %y]
    bind $txt   <<Selection>>         [list gui::selection_changed $txt]
    bind $txt   <Motion>              [list gui::clear_tab_tooltip $tb]
    bind Text   <<Cut>>               ""
    bind Text   <<Copy>>              ""
    bind Text   <<Paste>>             ""
    bind Text   <Control-d>           ""
    bind Text   <Control-i>           ""

    # Move the all bindtag ahead of the Text bindtag
    set text_index  [lsearch [bindtags $txt.t] Ctext]
    set all_index   [lsearch [bindtags $txt.t] all]
    bindtags $txt.t [lreplace [bindtags $txt.t] $all_index $all_index]
    bindtags $txt.t [linsert  [bindtags $txt.t] $text_index all]

    grid rowconfigure    $tab.pw.tf 0 -weight 1
    grid columnconfigure $tab.pw.tf 0 -weight 1
    grid $tab.pw.tf.txt -row 0 -column 0 -sticky news
    grid $tab.pw.tf.vb  -row 0 -column 1 -sticky ns
    grid $tab.pw.tf.hb  -row 1 -column 0 -sticky ew

    # Create the Vim command bar
    vim::bind_command_entry $txt [entry $tab.ve]

    # Create the search type menu
    set type_menu [menu $tab.typeMenu -tearoff 0]
    set max_width [expr [msgcat::mcmax "Regexp" "Glob" "Exact"] + 1]
    $type_menu add radiobutton -label [msgcat::mc "Regexp"] -variable gui::search_method -value "regexp" -command [list gui::update_search_method $tab]
    $type_menu add radiobutton -label [msgcat::mc "Glob"]   -variable gui::search_method -value "glob"   -command [list gui::update_search_method $tab]
    $type_menu add radiobutton -label [msgcat::mc "Exact"]  -variable gui::search_method -value "exact"  -command [list gui::update_search_method $tab]

    # Create the search bar
    ttk::frame       $tab.sf
    ttk::label       $tab.sf.l1    -text [format "%s:" [msgcat::mc "Find"]]
    ttk::entry       $tab.sf.e     -validate key -validatecommand [list gui::handle_search_change $tab %P]
    ttk::button      $tab.sf.prev  -style BButton -image search_prev -command [list gui::find_resilient prev] -state disabled
    ttk::button      $tab.sf.next  -style BButton -image search_next -command [list gui::find_resilient next] -state disabled
    ttk::button      $tab.sf.type  -style BButton -width $max_width -command [list gui::handle_menu_popup $tab.sf.type $type_menu]
    ttk::checkbutton $tab.sf.case  -text " Aa" -variable gui::case_sensitive
    ttk::checkbutton $tab.sf.save  -text [format " %s" [msgcat::mc "Save"]] -variable gui::saved -command [list search::update_save find]
    ttk::label       $tab.sf.close -image form_close

    tooltip::tooltip $tab.sf.next  [msgcat::mc "Find next occurrence"]
    tooltip::tooltip $tab.sf.prev  [msgcat::mc "Find previous occurrence"]
    tooltip::tooltip $tab.sf.case  [msgcat::mc "Case sensitivity"]
    tooltip::tooltip $tab.sf.save  [msgcat::mc "Save this search"]

    pack $tab.sf.l1    -side left  -padx 4 -pady 2
    pack $tab.sf.e     -side left  -padx 4 -pady 2 -fill x -expand yes
    pack $tab.sf.close -side right -padx 4 -pady 2
    pack $tab.sf.save  -side right -padx 4 -pady 2
    pack $tab.sf.case  -side right -padx 4 -pady 2
    pack $tab.sf.type  -side right -padx 4 -pady 2
    pack $tab.sf.next  -side right -padx 4 -pady 2
    pack $tab.sf.prev  -side right -padx 4 -pady 2

    bind $tab.sf.e     <Escape>    [list gui::close_search]
    bind $tab.sf.case  <Escape>    [list gui::close_search]
    bind $tab.sf.save  <Escape>    [list gui::close_search]
    bind $tab.sf.type  <Escape>    [list gui::close_search]
    bind $tab.sf.next  <Escape>    [list gui::close_search]
    bind $tab.sf.prev  <Escape>    [list gui::close_search]
    bind $tab.sf.e     <Up>        "search::traverse_history find  1; break"
    bind $tab.sf.e     <Down>      "search::traverse_history find -1; break"
    bind $tab.sf.close <Button-1>  [list gui::close_search]
    bind $tab.sf.close <Key-space> [list gui::close_search]

    # Create the search/replace bar
    ttk::frame       $tab.rf
    ttk::label       $tab.rf.fl    -text [format "%s:" [msgcat::mc "Find"]]
    ttk::entry       $tab.rf.fe    -validate key -validatecommand [list gui::handle_replace_change $tab %P]
    ttk::label       $tab.rf.rl    -text [format "%s:" [msgcat::mc "Replace"]]
    ttk::entry       $tab.rf.re
    ttk::frame       $tab.rf.act
    ttk::button      $tab.rf.act.prev  -style BButton -image search_prev -command [list gui::find_resilient prev replace] -state disabled
    ttk::button      $tab.rf.act.next  -style BButton -image search_next -command [list gui::find_resilient next replace] -state disabled
    ttk::button      $tab.rf.act.rep   -style BButton -text [msgcat::mc "Replace"]     -command [list search::replace_one]     -state disabled
    ttk::button      $tab.rf.act.repa  -style BButton -text [msgcat::mc "Replace All"] -command [list search::replace_start 1] -state disabled
    ttk::frame       $tab.rf.opts
    ttk::button      $tab.rf.opts.type  -style BButton -width $max_width -command [list gui::handle_menu_popup $tab.rf.opts.type $type_menu]
    ttk::checkbutton $tab.rf.opts.case  -text " Aa" -variable gui::case_sensitive
    ttk::checkbutton $tab.rf.opts.save  -text [format " %s" [msgcat::mc "Save"]] -variable gui::saved \
      -command [list search::update_save replace]
    ttk::label       $tab.rf.close -image form_close
    ttk::separator   $tab.rf.sep   -orient horizontal

    tooltip::tooltip $tab.rf.act.next  [msgcat::mc "Find next occurrence"]
    tooltip::tooltip $tab.rf.act.prev  [msgcat::mc "Find previous occurrence"]
    tooltip::tooltip $tab.rf.opts.case [msgcat::mc "Case sensitivity"]
    tooltip::tooltip $tab.rf.opts.save [msgcat::mc "Save this search"]

    pack $tab.rf.act.prev -side left -padx 4
    pack $tab.rf.act.next -side left -padx 4
    pack $tab.rf.act.rep  -side left -padx 4
    pack $tab.rf.act.repa -side left -padx 4

    pack $tab.rf.opts.type -side left -padx 4
    pack $tab.rf.opts.case -side left -padx 4
    pack $tab.rf.opts.save -side right -padx 4

    grid columnconfigure $tab.rf 1 -weight 1
    grid $tab.rf.fl    -row 0 -column 0 -sticky news -padx 4 -pady 2
    grid $tab.rf.fe    -row 0 -column 1 -sticky news -padx 4 -pady 2
    grid $tab.rf.act   -row 0 -column 2 -sticky news -padx 4 -pady 2
    grid $tab.rf.close -row 0 -column 3 -sticky news -padx 4 -pady 2
    grid $tab.rf.rl    -row 1 -column 0 -sticky news -padx 4 -pady 2
    grid $tab.rf.re    -row 1 -column 1 -sticky news -padx 4 -pady 2
    grid $tab.rf.opts  -row 1 -column 2 -sticky news -padx 4 -pady 2
    grid $tab.rf.sep   -row 2 -column 0 -sticky news -column 4

    bind $tab.rf.fe        <Return>    [list search::replace_start]
    bind $tab.rf.re        <Return>    [list search::replace_start]
    bind $tab.rf.opts.type <Return>    [list search::replace_start]
    bind $tab.rf.opts.case <Return>    [list search::replace_start]
    bind $tab.rf.opts.save <Return>    [list search::replace_start]
    bind $tab.rf.fe        <Escape>    [list gui::close_search_and_replace]
    bind $tab.rf.re        <Escape>    [list gui::close_search_and_replace]
    bind $tab.rf.opts.type <Escape>    [list gui::close_search_and_replace]
    bind $tab.rf.opts.case <Escape>    [list gui::close_search_and_replace]
    bind $tab.rf.opts.save <Escape>    [list gui::close_search_and_replace]
    bind $tab.rf.act.prev  <Escape>    [list gui::close_search_and_replace]
    bind $tab.rf.act.next  <Escape>    [list gui::close_search_and_replace]
    bind $tab.rf.act.rep   <Escape>    [list gui::close_search_and_replace]
    bind $tab.rf.act.repa  <Escape>    [list gui::close_search_and_replace]
    bind $tab.rf.close     <Button-1>  [list gui::close_search_and_replace]
    bind $tab.rf.close     <Key-space> [list gui::close_search_and_replace]
    bind $tab.rf.fe        <Up>        "search::traverse_history replace  1; break"
    bind $tab.rf.fe        <Down>      "search::traverse_history replace -1; break"

    # Create the diff bar
    if {$opts(-diff)} {
      ttk::frame $tab.df
      pack [diff::create_diff_bar $txt $tab.df.df] -fill x
      pack [ttk::separator $tab.df.sep -orient horizontal] -fill x
    }

    grid rowconfigure    $tab 0 -weight 1
    grid columnconfigure $tab 0 -weight 1
    grid $tab.pw   -row 0 -column 0 -sticky news
    # grid $tab.sb   -row 0 -column 2 -sticky news
    if {$opts(-diff)} {
      grid $tab.df -row 1 -column 0 -sticky ew -columnspan 2
    }

    # grid remove $tab.sb

    # Separator
    ttk::separator $tab.sep -orient horizontal

    # Get the adjusted index
    set adjusted_index [$tb index $index]

    # Add the text bindings
    if {!$opts(-diff)} {
      # indent::add_bindings      $txt
      vim::set_vim_mode         $txt
      # multicursor::add_bindings $txt
      completer::add_bindings   $txt
    }
    select::add $txt $tab.sb
    plugins::handle_text_bindings $txt $opts(-tags)
    make_drop_target                   $txt text

    # Apply the appropriate syntax highlighting for the given extension
    syntax::set_language $txt [expr {($opts(-lang) eq "") ? [syntax::get_default_language $fname] : $opts(-lang)}]

    # Snippet bindings must go after syntax language setting
    if {!$opts(-diff)} {
      snippets::add_bindings $txt
      folding::initialize $txt
    }

    # Add any gutters
    foreach gutter $opts(-gutters) {
      $txt gutter create {*}$gutter
    }

    # Add the new tab to the notebook in alphabetical order (if specified) and if
    # the given index is "end"
    if {[preferences::get View/OpenTabsAlphabetically] && ($index eq "end")} {
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
    if {[preferences::get View/ShowBirdsEyeView]} {
      show_birdseye $tab
    }

    return $tab

  }

  ######################################################################
  # Adds a peer ctext widget to the current widget in the pane just below
  # the current pane.
  #
  # TBD - This is missing support for applied gutters!
  proc show_split_pane {tab} {

    variable show_match_chars

    # Get the current paned window
    get_info $tab tab tabbar txt txt2 diff

    # Get the paned window of the text widget
    set pw [winfo parent [winfo parent $txt]]

    # Get the scrollbar coloring information
    array set sb_opts [set scrollbar_opts [theme::get_category_options text_scrollbar 1]]

    # Create the editor frame
    $pw insert 0 [frame $pw.tf2 -background $sb_opts(-background)]
    ctext $txt2 -wrap none -undo 1 -autoseparators 1 -insertofftime 0 -font editor_font \
      -insertwidth [preferences::get Appearance/CursorWidth] \
      -spacing2 [preferences::get Appearance/ExtraLineSpacing] \
      -spacing3 [preferences::get Appearance/ExtraLineSpacing] \
      -highlightcolor orange -warnwidth [preferences::get Editor/WarningWidth] \
      -maxundo [preferences::get Editor/MaxUndo] -matchchar $show_match_chars \
      -matchaudit [preferences::get Editor/HighlightMismatchingChar] \
      -linemap [preferences::get View/ShowLineNumbers] -linemap_separator 1 \
      -linemap_mark_command [list gui::mark_command $tab] -linemap_mark_color orange -peer $txt \
      -linemap_align [preferences::get Editor/LineNumberAlignment] \
      -xscrollcommand "$pw.tf2.hb set" \
      -yscrollcommand "$pw.tf2.vb set"
    scroller::scroller $pw.tf2.hb {*}$scrollbar_opts -orient horizontal -autohide 0 -command "$txt2 xview"
    scroller::scroller $pw.tf2.vb {*}$scrollbar_opts -orient vertical   -autohide 1 -command "$txt2 yview" \
      -markcommand1 [list markers::get_positions $tab] -markhide1 [expr [preferences::get View/ShowMarkerMap] ^ 1] \
      -markcommand2 [expr {$diff ? [list diff::get_marks $txt] : ""}]

    # Update the widgets to match the current theme
    update_theme $txt2

    # Register the widgets
    theme::register_widget $txt2      syntax_split
    theme::register_widget $pw.tf2.vb text_scrollbar
    theme::register_widget $pw.tf2.hb text_scrollbar

    bind $txt2.t <FocusIn>             [list +gui::handle_txt_focus %W]
    bind $txt2.t <<CursorChanged>>     [list +gui::update_position $txt2]
    bind $txt2.l <ButtonPress-1>       [list gui::select_line %W %x %y]
    bind $txt2.l <B1-Motion>           [list gui::select_lines %W %x %y]
    bind $txt2.l <Shift-ButtonPress-1> [list gui::select_lines %W %x %y]
    bind $txt2   <<Selection>>         [list gui::selection_changed $txt2]
    bind $txt2   <Motion>              [list gui::clear_tab_tooltip $tabbar]

    # Move the all bindtag ahead of the Text bindtag
    set text_index   [lsearch [bindtags $txt2.t] Ctext]
    set all_index    [lsearch [bindtags $txt2.t] all]
    bindtags $txt2.t [lreplace [bindtags $txt2.t] $all_index $all_index]
    bindtags $txt2.t [linsert  [bindtags $txt2.t] $text_index all]

    grid rowconfigure    $pw.tf2 0 -weight 1
    grid columnconfigure $pw.tf2 0 -weight 1
    grid $pw.tf2.txt -row 0 -column 0 -sticky news
    grid $pw.tf2.vb  -row 0 -column 1 -sticky ns
    grid $pw.tf2.hb  -row 1 -column 0 -sticky ew

    # Associate the existing command entry field with this text widget
    vim::bind_command_entry $txt2 $tab.ve

    # Add the text bindings
    # indent::add_bindings          $txt2
    vim::set_vim_mode             $txt2
    # multicursor::add_bindings     $txt2
    completer::add_bindings       $txt2
    plugins::handle_text_bindings $txt2 {}
    make_drop_target              $txt2 text

    # Apply the appropriate syntax highlighting for the given extension
    syntax::set_language $txt2 [syntax::get_language $txt]

    # Snippet bindings must go after syntax language is set
    snippets::add_bindings $txt2

    # Apply code foldings
    folding::initialize $txt2

    # Give the text widget the focus
    set_txt_focus $txt2

  }

  ######################################################################
  # Called when the given text widget is destroyed.
  proc handle_destroy_txt {txt} {

    variable line_sel_anchor
    variable txt_current
    variable cursor_hist
    variable be_after_id
    variable be_ignore
    variable undo_count

    set tab [join [lrange [split $txt .] 0 end-3] .]

    catch { unset line_sel_anchor($txt.l) }
    catch { unset txt_current($tab) }
    catch { unset undo_count($tab) }
    catch { array unset cursor_hist $txt,* }

    # Only unset the bird's eye variables if we are destroying txt
    if {[lindex [split $txt .] end-1] eq "tf"} {
      catch { unset be_after_id($tab) }
      catch { unset be_ignore($tab) }
    }

  }

  ######################################################################
  # Removes the split pane
  proc hide_split_pane {tab} {

    # Get the current paned window
    get_info $tab tab txt
    set pw [winfo parent [winfo parent $txt]]

    # Delete the extra text widget
    $pw forget $pw.tf2

    # Destroy the extra text widget frame
    destroy $pw.tf2

    # Cleanup the text widget
    cleanup_txt $pw.tf2.txt

    # Set the focus back on the tf text widget
    set_txt_focus $pw.tf.txt

  }

  ######################################################################
  # Creates and displays the bird's eye viewer in the same editing buffer
  # as the specified text widget.
  proc show_birdseye {tab} {

    variable be_after_id
    variable be_ignore

    # Get the tab that contains the text widget
    get_info $tab tab txt beye

    if {![winfo exists $beye]} {

      # Calculate the background color
      set background [utils::auto_adjust_color [$txt cget -background] 25]

      # Create the bird's eye viewer
      $txt._t peer create $beye -width [preferences::get View/BirdsEyeViewWidth] -bd 0 \
        -highlightthickness 0 -font "-size [preferences::get View/BirdsEyeViewFontSize]" \
        -wrap none -cursor [ttk::cursor standard] \
        -background [$txt cget -background] -foreground [$txt cget -foreground] \
        -inactiveselectbackground $background -selectbackground $background

      # Add the bird's eye viewer to the tab's grid manager
      grid $beye -row 0 -column 1 -sticky ns

      # Setup bindings
      bind $beye <Enter>                         [list gui::handle_birdseye_enter %W $txt %m]
      bind $beye <Leave>                         [list gui::handle_birdseye_leave %W %m]
      bind $beye <ButtonPress-1>                 [list gui::handle_birdseye_left_press %W %x %y $tab $txt]
      bind $beye <B1-Motion>                     [list gui::handle_birdseye_motion     %W %x %y $tab $txt]
      bind $beye <Control-Button-1>              [list gui::handle_birdseye_control_left %W]
      bind $beye <Control-Button-$::right_click> [list gui::handle_birdseye_control_right %W]
      bind $beye <MouseWheel>                    [bind Text <MouseWheel>]
      bind $beye <Button-4>                      [bind Text <Button-4>]
      bind $beye <Button-5>                      [bind Text <Button-5>]

      set index [lsearch [bindtags $beye] "Text"]
      bindtags $beye [lreplace [bindtags $beye] $index $index]

      set be_after_id($tab) ""
      set be_ignore($tab)   0

      # Make sure that the bird's eye viewer is below any lower panel
      lower $beye

    }

  }

  ######################################################################
  # Highlights the currently displayed area in the text widget.
  proc highlight_birdseye {be txt} {

    # Get the start and end shown lines of the given text widget
    set startline [$txt index @0,0]
    set endline   [$txt index @0,[winfo height $txt]]

    # Set the selection
    $be tag remove sel 1.0 end
    $be tag add sel $startline $endline

  }

  ######################################################################
  # Handles the mouse entering the bird's eye view.  This will cause the
  # currently displayed text region to be selected in the bird's eye viewer.
  proc handle_birdseye_enter {be txt m} {

    variable be_show_after_id

    if {$m eq "NotifyNormal"} {

      # Highlight the shown text
      set be_show_after_id [after 300 [list gui::highlight_birdseye $be $txt]]

    }

  }

  ######################################################################
  # Handles the mouse leaving the bird's eye viewer.
  proc handle_birdseye_leave {be m} {

    variable be_show_after_id

    if {$m eq "NotifyNormal"} {

      # Cancel the bird's eye show activity if it is valid
      after cancel $be_show_after_id

      # Clear the selection
      $be tag remove sel 1.0 end

    }

  }

  ######################################################################
  # Handles a left button press event inside the bird's eye viewer.
  proc handle_birdseye_left_press {W x y tab txt} {

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
      set be_ignore($tab) 1

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
  proc handle_birdseye_motion {W x y tab txt} {

    variable be_last_y
    variable be_ignore

    if {($be_last_y ne "") && ($y != $be_last_y)} {

      # Get the current cursor
      set cursor          [$W index @$x,$y]
      set height          [winfo height $txt]
      set be_ignore($tab) 1

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
  proc hide_birdseye {tab} {

    variable be_after_id
    variable be_ignore

    # Get the tab that contains the bird's eye viewer
    get_info $tab tab beye

    if {[winfo exists $beye]} {

      # Cancel the scroll event if one is still set
      if {$be_after_id($tab) ne ""} {
        after cancel $be_after_id($tab)
      }

      # Remove the be_after_id
      unset be_after_id($tab)
      unset be_ignore($tab)

      # Remove the widget from the grid
      grid forget $beye

      # Destroy the bird's eye viewer
      destroy $beye

    }

  }

  ######################################################################
  # Adds the necessary bindings to make the given text/entry widget a drop
  # target for TkDND.  Type should be set to text or entry.
  proc make_drop_target {win type args} {

    array set opts {
      -types {files dirs text}
      -force 0
    }
    array set opts $args

    set types [list]
    if {[lsearch $opts(-types) *s]   != -1} { lappend types DND_Files }
    if {[lsearch $opts(-types) text] != -1} { lappend types DND_Text }

    # Make ourselves a drop target (if Tkdnd is available)
    catch {

      tkdnd::drop_target register $win $types

      bind $win <<DropEnter>>      [list gui::handle_drop_enter %W $type %a %b $opts(-force)]
      bind $win <<DropLeave>>      [list gui::handle_drop_leave %W $type]
      bind $win <<Drop:DND_Files>> [list gui::handle_drop %W $type %A %m 0 %D $opts(-types)]
      bind $win <<Drop:DND_Text>>  [list gui::handle_drop %W $type %A %m 1 %D $opts(-types)]

    }

  }

  ######################################################################
  # Front-end handler for the drop_enter method.
  proc handle_drop_enter {win type actions buttons force} {

    if {!$force && ([$win cget -state] ne "normal")} {
      return "refuse_drop"
    }

    if {[catch { handle_${type}_drop_enter $win $actions $buttons } rc] || ($rc == 0)} {
      return "refuse_drop"
    }

    return "link"

  }

  ######################################################################
  # Front-end handler for the drop method.
  proc handle_drop {win type actions modifiers dtype data types} {

    # If we are attempting to drop a file, check to see if it is the proper type
    if {$dtype == 0} {
      set tdata [list]
      set files [expr {[lsearch $types files] != -1}]
      set dirs  [expr {[lsearch $types dirs]  != -1}]
      foreach item $data {
        if {($files && [file isfile $item]) || ($dirs && [file isdirectory $item])} {
          lappend tdata $item
        }
      }
      set data $tdata
    }

    if {$data ne ""} {
      catch { handle_${type}_drop $win $actions $modifiers $dtype $data {*}[array get opts] }
    }

    catch { handle_${type}_drop_leave $win }

    return "link"

  }

  ######################################################################
  # Front-end handler for the drop leave method.
  proc handle_drop_leave {win type} {

    catch { handle_${type}_drop_leave $win }

  }

  ######################################################################
  # Handles a drag-and-drop enter/position event.  Draws UI to show that
  # the file drop request would be excepted or rejected.
  proc handle_text_drop_enter {txt actions buttons args} {

    get_info $txt txt readonly lock diff

    # If the file is readonly, refuse the drop
    if {$readonly || $lock || $diff} {
      return 0
    }

    # Make sure the text widget has the focus
    focus -force $txt.t

    # Set the highlight color to green
    ctext::set_border_color $txt green

    return 1

  }

  ######################################################################
  # Called when the user drags a droppable item over the given entry widget.
  proc handle_entry_drop_enter {win actions buttons args} {

    # Make sure that the text window has the focus
    focus -force $win

    # Cause the entry field to display that it can accept the data
    $win state alternate

    return 1

  }

  ######################################################################
  # Indicates that an item can be dropped in the tokentry.
  proc handle_tokenentry_drop_enter {win actions buttons args} {

    # Display the highlight color
    $win configure -highlightbackground green -highlightcolor green

    # Make sure the entry received focus
    focus -force $win

    return 1

  }

  ######################################################################
  # Handles a drop leave event.
  proc handle_text_drop_leave {txt} {

    # Set the highlight color to green
    ctext::set_border_color $txt white

  }

  ######################################################################
  # Handles a drag leave event.
  proc handle_entry_drop_leave {win} {

    $win state focus

  }

  ######################################################################
  # Handles a drag leave event.
  proc handle_tokenentry_drop_leave {win} {

    $win configure -highlightbackground white -highlightcolor white

  }

  ######################################################################
  # If the editing buffer has formatting support for links/images, adjusts
  # the supplied data to be formatted.
  proc format_dropped_data {txt pdata pcursor} {

    upvar $pdata   data
    upvar $pcursor cursor

    # Get the formatting information for the current editing buffer
    array set formatting [syntax::get_formatting $txt]

    # If the data is an image, adjust for an image if we can
    if {[lsearch [list .png .jpg .jpeg .gif .bmp .tiff .svg] [string tolower [file extension $data]]] != -1} {
      if {[info exists formatting(image)]} {
        set pattern [lindex $formatting(image) 1]
        set cursor  [string first \{TEXT\} $pattern]
        set data    [string map [list \{REF\} $data \{TEXT\} {}] $pattern]
      }

    # Otherwise, if the data looks like a URL reference, change the data to a
    # link if we can
    } elseif {[utils::is_url $data]} {
      if {[info exists formatting(link)]} {
        set pattern [lindex $formatting(link) 1]
        set cursor  [string first \{TEXT\} $pattern]
        set data    [string map [list \{REF\} $data \{TEXT\} {}] $pattern]
      }
    }

  }

  ######################################################################
  # Handles a drop event.  Adds the given files/directories to the sidebar.
  proc handle_text_drop {txt action modifier dtype data args} {

    gui::get_info $txt txt fileindex

    # If the data is text or the Alt key modifier is held during the drop, insert the data at the
    # current insertion point
    if {[plugins::handle_on_drop $fileindex $dtype $data]} {
      # Do nothing

    # If we are inserting text or the file name, do that now
    } elseif {$dtype} {

      set cursor 0

      # Attempt to format the data
      format_dropped_data $txt data cursor

      # Insert the data
      if {[multicursor::enabled $txt.t]} {
        multicursor::insert $txt.t $data
      } else {
        $txt insert cursor $data
      }

      # If we need to adjust the cursor(s) do it now.
      if {$cursor != 0} {
        # TBD
      }

    # Otherwise, insert the content of the file(s) after the insertion line
    } elseif {![::check_file_for_import $data] && ![utils::is_binary $data]} {
      set str "\n"
      foreach ifile $data {
        if {[file isfile $ifile]} {
          if {![catch { open $ifile r } rc]} {
            append str [read $rc]
            close $rc
          }
        }
      }
      if {[multicursor::enabled $txt.t]} {
        multicursor::insert $txt.t $str
      } else {
        $txt insert "insert lineend" $str
      }
    }

  }

  ######################################################################
  # Called if the user drops the given data into the entry field.  If the
  # data is text, insert the text at the current insertion point.  If the
  # data is a file, insert the filename at the current insertion point.
  proc handle_entry_drop {win action modifier dtype data args} {

    # We are not going to allow
    if {($dtype == 0) && ([llength $data] > 1)} {
      return
    }

    # Get the state before the drop
    set state [$win cget -state]

    # Allow the entry field to be modified and clear the field
    $win configure -state normal
    $win delete 0 end

    # Insert the information
    $win insert cursor {*}$data

    # Return the state of the entry field
    $win configure -state $state

  }

  ######################################################################
  # Called if the user drops the given data into the tokenentry field.
  proc handle_tokenentry_drop {win action modifier dtype data args} {

    # Insert the information
    $win tokeninsert end $data

  }

  ######################################################################
  # Handles a change to the current text widget.
  proc text_changed {txt data} {

    variable cursor_hist

    if {[$txt edit modified]} {

      # Get file information
      get_info $txt txt tabbar tab fileindex readonly

      if {!$readonly && ([lindex $data 2] ne "ignore")} {
        set_current_modified 1
      }

      # Clear the cursor history
      array unset cursor_hist $txt,*

    }

    # Update the folding gutter
    if {[lindex $data 2] ne "ignore"} {
      foreach {startpos endpos} [lindex $data 1] {
        folding::add_folds $txt $startpos $endpos
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
  # Selects the given line in the text widget.
  proc select_line {w x y} {

    variable line_sel_anchor

    # Get the parent window
    set txt [winfo parent $w]

    # Get the last line
    set fontwidth  [font measure [$txt cget -font] -displayof . "0"]
    set last_line  [lindex [split [$txt index end-1c] .] 0]
    set line_chars [expr ([$txt cget -linemap] ? max( [$txt cget -linemap_minwidth], [string length $last_line] ) : 1) + 1]

    # We will only select the line if we clicked in the line number area
    if {$x > ($fontwidth * $line_chars)} {
      return
    }

    # Get the current line from the line sidebar
    set index [$txt index @0,$y]

    # Select the corresponding line in the text widget
    $txt tag remove sel 1.0 end
    $txt tag add sel "$index linestart" "$index lineend"
    $txt mark set insert "$index lineend"

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

    # Get the last line
    set fontwidth  [font measure [$txt cget -font] -displayof . "0"]
    set last_line  [lindex [split [$txt index end-1c] .] 0]
    set line_chars [expr ([$txt cget -linemap] ? max( [$txt cget -linemap_minwidth], [string length $last_line] ) : 1) + 1]

    # We will only select the line if we clicked in the line number area
    if {$x > ($fontwidth * $line_chars)} {
      return
    }

    # Get the current line from the line sidebar
    set index [$txt index @$x,$y]

    # Remove the current selection
    $txt tag remove sel 1.0 end

    # If the anchor has not been set, set it now
    if {![info exists line_sel_anchor($w)]} {
      set line_sel_anchor($w) $index
    }

    # Add the selection between the anchor and this line, inclusive
    if {[$txt compare $index < $line_sel_anchor($w)]} {
      $txt tag add sel "$index linestart" "$line_sel_anchor($w) lineend"
      $txt mark set insert "$line_sel_anchor($w) lineend"
    } else {
      $txt tag add sel "$line_sel_anchor($w) linestart" "$index lineend"
      $txt mark set insert "$index lineend"
    }

  }

  ######################################################################
  # Make the specified tab the current tab.
  proc set_current_tab {tabbar tab} {

    variable widgets
    variable pw_current

    # Get the frame containing the text widget
    set tf [winfo parent [winfo parent $tabbar]].tf

    # If there is no tab being set, just delete the packed slave
    if {$tab eq ""} {
      if {[set slave [pack slaves $tf]] ne ""} {
        pack forget $slave
      }
      return
    }

    # Get the tab's file information
    get_info $tab tab fname remote

    # Make sure that the tab state is shown
    $tabbar tab $tab -state normal

    # Make sure the sidebar is updated properly
    sidebar::set_hide_state $fname $remote 0

    # Make the tab the selected tab in the tabbar
    $tabbar select $tab

    # Make sure that the tab's content is displayed
    show_current_tab $tabbar

  }

  ######################################################################
  # Causes the currently selected tab contents to be displayed to the
  # screen.  This procedure is called by the tabbar when the user releases
  # the mouse button so it is assumed that the tabbar and tab parameters
  # are always valid.
  proc show_current_tab {tabbar} {

    variable widgets
    variable pw_current
    variable auto_cwd

    # Get the frame containing the text widget
    set tf [winfo parent [winfo parent $tabbar]].tf

    # If the current tabbar contains no visible tabs, remove the editing frame
    if {[$tabbar select] eq ""} {
      if {[set slave [pack slaves $tf]] ne ""} {
        pack forget $slave
      }
      return
    }

    # Get the current information
    get_info $tabbar tabbar tab paneindex fname buffer diff

    # If nothing is changing, stop now
    if {($pw_current eq $paneindex) && ([pack slaves $tf] eq $tab)} {
      return
    }

    # Update the current panedwindow indicator
    set pw_current $paneindex

    # Add the tab content, if necessary
    add_tab_content $tab

    # Remove the current tab frame (if it exists)
    if {[set slave [pack slaves $tf]] ne ""} {
      pack forget $slave
    }

    # Display the tab frame
    pack [$tabbar select] -in $tf -fill both -expand yes

    # Update the pane synchronization status
    pane_sync_tab_change

    # Update the preferences
    preferences::update_prefs [sessions::current]

    # Reload the snippets to correspond to the current file
    snippets::reload_snippets

    # Update the encoding indicator
    update_encode_button

    # Update the indentation indicator
    indent::update_button $widgets(info_indent)

    # Set the syntax menubutton to the current language
    syntax::update_button $widgets(info_syntax)

    # If we are supposed to automatically change the working directory, do it now
    if {$auto_cwd && !$buffer && !$diff} {
      cd [file dirname $fname]
    }

    # Make sure that the title bar is updated
    set_title

    # Set the text focus
    set_txt_focus [last_txt_focus $tab]

  }

  ######################################################################
  # Handles a selection made by the user from the tabbar.
  proc handle_tabbar_select {tabbar args} {

    show_current_tab $tabbar

  }

  ######################################################################
  # Returns the current text widget pathname (or the empty string if
  # there is no current text widget).
  proc current_txt {} {

    if {[catch { get_info {} current focus } focus]} {
      return [expr {[catch { get_info {} current txt } txt] ? "" : $txt}]
    }

    return $focus

  }

  ######################################################################
  # Returns the current search entry pathname.
  proc current_search {} {

    get_info {} current tab

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
    if {[set vim_mode [expr {[select::in_select_mode $txt.t stype] ? "[string toupper $stype] SELECT MODE" : [vim::get_mode $txt]}]] ne ""} {
      if {$vim_mode eq "MULTIMOVE MODE"} {
        $widgets(info_state) configure -text [format "%s" $vim_mode]
      } else {
        $widgets(info_state) configure -text [format "%s, %s: %d, %s: %d" $vim_mode [msgcat::mc "Line"] $line [msgcat::mc "Column"] [expr $column + 1]]
      }
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
  proc get_symbol_list {} {

    variable lengths

    # Get current text widget
    set txt [current_txt]

    set proclist [list]
    foreach tag [$txt tag names] {
      if {[string range $tag 0 9] eq "__symbols:"} {
        if {[set type [string range $tag 10 end]] ne ""} {
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
  proc create_current_marker {} {

    # Get the current text widget
    get_info {} current tab txt

    # Get the current line
    set line [lindex [split [$txt index insert] .] 0]

    # Add the marker at the current line
    if {[set tag [ctext::linemapSetMark $txt $line]] ne ""} {
      if {[markers::add $tab tag $tag]} {
        update_tab_markers $tab
      } else {
        ctext::linemapClearMark $txt $line
      }
    }

  }

  ######################################################################
  # Removes all markers placed at the current line.
  proc remove_current_marker {} {

    # Get the current text widget
    get_info {} current tab txt

    # Get the current line number
    set line [lindex [split [$txt index insert] .] 0]

    # Remove all markers at the current line
    markers::delete_by_line $tab $line
    ctext::linemapClearMark $txt $line

    # Update the tab's marker view
    update_tab_markers $tab

  }

  ######################################################################
  # Remove all of the text markers for the given text widget.
  proc remove_txt_markers {txt} {

    get_info $txt txt tab

    foreach {name t line} [markers::get_markers $tab] {
      set line [lindex [split $line .] 0]
      markers::delete_by_name $tab $name
      ctext::linemapClearMark $txt $line
    }

    # Update the marker display
    update_tab_markers $tab

  }

  ######################################################################
  # Removes all of the markers associated with the current text widget.
  proc remove_current_markers {} {

    remove_txt_markers [current_txt]

  }

  ######################################################################
  # Removes all of the markers from the current editor.
  proc remove_all_markers {} {

    foreach txt [get_all_texts] {
      remove_txt_markers $txt
    }

  }

  ######################################################################
  # Returns the list of markers in the all text widgets, sorted in
  # alphabetical order..
  proc get_marker_list {} {

    # Create a list of marker names and index
    set markers [list]
    foreach {name tab pos} [markers::get_markers] {
      get_info $tab tab txt fname
      lappend markers [list "[file tail $fname] - $name" $txt $name]
    }

    return [lsort -index 0 -dictionary $markers]

  }

  ######################################################################
  # Jump to the given position in the current text widget.
  proc jump_to {pos} {

    jump_to_txt [current_txt] $pos

  }

  ######################################################################
  # Jump to the given position in the given text widget.
  proc jump_to_txt {txt pos} {

    # Change the current tab, if necessary
    get_info $txt txt tabbar tab
    set_current_tab $tabbar $tab

    # Make sure that the cursor is visible
    folding::show_line $txt.t [lindex [split $pos .] 0]

    # Make the line viewable
    ::tk::TextSetCursor $txt.t $pos

  }

  ######################################################################
  # Jumps to the specified text name.
  proc jump_to_marker {txt name} {

    # Change the current tab, if necessary
    get_info $txt txt tabbar tab
    set_current_tab $tabbar $tab

    # Get the marker position
    set pos [markers::get_index $tab $name]

    # Make sure that the cursor is visible
    folding::show_line $txt.t [lindex [split $pos .] 0]

    # Make the line viewable
    ::tk::TextSetCursor $txt.t $pos

  }

  ######################################################################
  # Finds the matching character for the one at the current insertion
  # marker.
  proc show_match_pair {} {

    # Get the current widget
    set txt [current_txt]

    # If we are escaped or in a comment/string, we should not match
    if {[$txt is escaped insert] || [$txt is incommentstring insert]} {
      return
    }

    # If the current character is a matchable character, change the
    # insertion cursor to the matching character.
    switch -- [$txt get insert] {
      "\{"    { set index [ctext::getMatchBracket $txt curlyR] }
      "\}"    { set index [ctext::getMatchBracket $txt curlyL] }
      "\["    { set index [ctext::getMatchBracket $txt squareR] }
      "\]"    { set index [ctext::getMatchBracket $txt squareL] }
      "\("    { set index [ctext::getMatchBracket $txt parenR] }
      "\)"    { set index [ctext::getMatchBracket $txt parenL] }
      "\<"    { set index [ctext::getMatchBracket $txt angledR] }
      "\>"    { set index [ctext::getMatchBracket $txt angledL] }
      "\""    { set index [find_match_char $txt "\"" [expr {([lsearch [$txt tag names insert-1c] __dQuote*] == -1) ? "-forwards" : "-backwards"}]] }
      "'"     { set index [find_match_char $txt "'"  [expr {([lsearch [$txt tag names insert-1c] __sQuote*] == -1) ? "-forwards" : "-backwards"}]] }
      "`"     { set index [find_match_char $txt "`"  [expr {([lsearch [$txt tag names insert-1c] __bQuote*] == -1) ? "-forwards" : "-backwards"}]]}
      default { set index [find_match_pair $txt {*}[lrange [syntax::get_indentation_expressions $txt] 0 1] -backwards] }
    }

    # Change the insertion cursor to the matching character
    if {($index ne "") && ($index != -1)} {
      ::tk::TextSetCursor $txt.t $index
    }

  }

  ######################################################################
  # Finds the matching bracket type and returns it's index if found;
  # otherwise, returns -1.
  proc find_match_pair {txt str1 str2 dir {startpos insert}} {

    if {[$txt is escaped $startpos] || [$txt is incommentstring $startpos]} {
      return -1
    }

    set search_re "[set str1]|[set str2]"
    set count     1
    set pos       [$txt index [expr {($dir eq "-forwards") ? "$startpos+1c" : $startpos}]]

    # Calculate the endpos
    if {[set incomstr [$txt is incommentstring $pos srange]]} {
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

      if {[$txt is escaped $found] || (!$incomstr && [$txt is incommentstring $found])} {
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
  # Returns the index of the matching character; otherwise, if one
  # is not found, returns -1.
  proc find_match_char {txt char dir {startpos insert}} {

    set last_found ""

    if {[$txt is escaped $startpos]} {
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

      if {[$txt is escaped $last_found]} {
        continue
      }

      return $last_found

    }

  }

  ######################################################################
  # Jumps the insertion cursor to the next/previous mismatching bracket
  # within the current text widget.
  proc goto_mismatch {dir args} {

    return [ctext::gotoBracketMismatch [current_txt] $dir {*}$args]

  }

  ######################################################################
  # Updates the scroller markers for the given tab.
  proc update_tab_markers {tab} {

    # Get the pathname of txt and txt2 from the given tab
    get_info $tab tab txt txt2

    # The txt widget will always exist, so update it now
    ctext::linemapUpdate $txt
    scroller::update_markers [winfo parent $txt].vb

    # If the split view widget exists, update it as well
    if {[winfo exists $txt2]} {
      ctext::linemapUpdate $txt2
      scroller::update_markers [winfo parent $txt2].vb
    }

  }

  ######################################################################
  # Handles a mark request when the line is clicked.
  proc mark_command {tab win type tag} {

    if {$type eq "marked"} {
      if {![markers::add $tab tag $tag]} {
        return 0
      }
    } else {
      markers::delete_by_tag $tab $tag
    }

    # Update the markers in the scrollbar
    update_tab_markers $tab

    return 1

  }

  ######################################################################
  # Displays all of the unhidden tabs.
  proc show_tabs {tb side} {

    # If the tabbar is disabled, don't show the tab menu
    if {[$tb cget -state] eq "disabled"} {
      return
    }

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
        -command [list gui::set_current_tab $tb $tab]
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

    indent::update_button $widgets(info_indent)

  }

  ######################################################################
  # Creates the encoding menu.
  proc create_encoding_menu {w} {

    variable widgets

    # Create the menubutton menu
    set mnu [menu ${w}Menu -tearoff 0]

    # If we are running in Aqua, don't perform the column break
    set dobreak [expr {[tk windowingsystem] ne "aqua"}]

    # Populate the menu with the available languages
    set i 0
    foreach enc [lsort -dictionary [encoding names]] {
      $mnu add radiobutton -label [string toupper $enc] -variable gui::current_encoding \
        -value $enc -command [list gui::set_current_encoding $enc] -columnbreak [expr (($i % 20) == 0) && $dobreak]
      incr i
    }

    # Register the menu
    theme::register_widget $mnu menus

    return $mnu

  }

  ######################################################################
  # Sets the encoding of the current buffer to the given value.
  proc set_current_encoding {value} {

    gui::get_info {} current tab fileindex

    # Set the encoding
    if {![set_encoding $tab $value]} {
      return
    }

    # Update the encode button
    update_encode_button

    # Update the file with the new encoding
    update_file $fileindex

    # Set the focus back to the text editor
    set_txt_focus [last_txt_focus]

  }

  ######################################################################
  # Sets the encoding of the given tab to the given value.
  proc set_encoding {tab value {setfocus 1}} {

    variable widgets

    # Get the current tab info
    get_info $tab tab fileindex encode

    # If the value did not change, do nothing
    if {$value eq $encode} {
      return 0
    }

    # Save the file encoding
    files::set_info $fileindex fileindex encode $value

    return 1

  }

  ######################################################################
  # This is called when the tab changes.  Our job is to update the label
  # on the encoding button to match the value for the file.
  proc update_encode_button {} {

    variable widgets
    variable current_encoding

    # Get the current encoding
    get_info {} current encode

    set current_encoding $encode

    # Update the encode button
    $widgets(info_encode) configure -text [string toupper $encode]

  }

  ######################################################################
  # Handles a text FocusIn event from the widget.
  proc handle_txt_focus {txtt} {

    variable widgets
    variable pw_current
    variable txt_current
    variable info_msgs

    # It is possible that getting the parent of txtt could cause errors, so just
    # silently catch them and move on
    catch {

      # Get the text information
      get_info [winfo parent $txtt] txt paneindex tab txt fileindex fname buffer diff
      set pw_current $paneindex

      # Set the line and row information
      update_position $txt

      # Check to see if the file has changed
      catch { files::check_file $fileindex }

      # Save the text widget
      set txt_current($tab) [winfo parent $txtt]

      # Update the informational message if one exists for the text widget
      if {[info exists info_msgs($txt)]} {
        set_info_message [lindex $info_msgs($txt) 0] -clear_delay [lindex $info_msgs($txt) 1] -win [winfo parent $txtt]
      } else {
        set_info_message "" -win [winfo parent $txtt]
      }

      # Remove the find or find/replace panels if we are told to do so
      if {[preferences::get Find/ClosePanelsOnTextFocus]} {
        panel_forget $tab.sf
        panel_forget $tab.rf
      }

      # Let the plugins know about the FocusIn event
      plugins::handle_on_focusin $tab

    }

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
  proc last_txt_focus {{tab ""}} {

    variable txt_current

    if {$tab eq ""} {
      return $txt_current([get_info {} current tab])
    } elseif {[info exists txt_current($tab)]} {
      return $txt_current($tab)
    } else {
      return [get_info $tab tab txt]
    }

  }

  ######################################################################
  # Scrubs the given text widget, returning the scrubbed text as a string
  # to be used for saving to a file.
  proc scrub_text {txt} {

    variable trailing_ws_re

    # Clear any snippet tabstops embedded in the text widget
    snippets::clear_tabstops $txt.t

    # Clean up the text from Vim
    set str [ctext::get_cleaned_content $txt first [list last -adjust "-1c"] {}]

    if {[preferences::get Editor/RemoveTrailingWhitespace]} {
      regsub -all -lineanchor -- $trailing_ws_re $str {} str
    }

    return $str

  }

  ######################################################################
  # Jumps to the next cursor as specified by direction.  Returns a boolean
  # value of true if a jump occurs (or can occur).
  proc jump_to_cursor {dir jump} {

    variable cursor_hist

    # Get the current text widget
    set txt [current_txt]

    # Get the index of the cursor in the cursor hist to use
    if {![info exists cursor_hist($txt,hist)]} {
      set cursor_hist($txt,hist) [list]
      set last                   ""
      set diff                   [preferences::get Find/JumpDistance]
      foreach cursor [$txt edit cursorhist] {
        set line [lindex [split $cursor .] 0]
        if {($last eq "") || (abs( $line - $last ) >= $diff)} {
          lappend cursor_hist($txt,hist) $cursor
          set last $line
        }
      }
      set cursor_hist($txt,index) [expr [llength $cursor_hist($txt,hist)] - 1]
    }

    if {$cursor_hist($txt,index) < 0} {
      return 0
    }

    set index [expr $cursor_hist($txt,index) + $dir]
    set size  [llength $cursor_hist($txt,hist)]

    # Get the cursor index
    if {$index < 0} {
      set index 0
    } elseif {$index >= $size} {
      set index [expr $size - 1]
    }

    # Jump to the given cursor position if it has changed
    if {$index != $cursor_hist($txt,index)} {
      if {$jump} {
        set cursor_hist($txt,index) $index
        ::tk::TextSetCursor $txt.t [lindex $cursor_hist($txt,hist) $index]
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # Jumps to the next difference in the specified direction.  Returns
  # a boolean value of true if a jump occurs (or can occur).
  proc jump_to_difference {dir jump} {

    # Get the current text widget
    set txt [current_txt]

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
  proc show_difference_line_change {show} {

    # Get the current information
    get_info {} current txt fname

    if {[$txt cget -diff_mode] && ![catch { $txt index sel.first } rc]} {
      if {$show} {
        diff::find_current_version $txt $fname [lindex [split $rc .] 0]
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

  ######################################################################
  # Check all of the namespaces for a procedure called "handle_destroy_txt".
  # When a namespace is found the the procedure, call it with the given
  # text widget.  This allows namespaces to clean up any state that is
  # dependent on the given text widget.
  proc cleanup_txt {txt} {

    foreach ns [namespace children ::] {
      if {[info procs ${ns}::handle_destroy_txt] ne ""} {
        eval ${ns}::handle_destroy_txt $txt
      }
    }

  }

  ######################################################################
  # Gets the documentation search URL and string.
  proc docsearch_get_input {docs prsplist args} {

    variable widgets
    variable saved

    upvar $prsplist rsplist

    array set opts {
      -str ""
      -url ""
    }
    array set opts $args

    # Clear the saved indicator
    set saved 0

    # Clear the entry field
    $widgets(doc).e delete 0 end

    # Initialize the text in the menubutton
    $widgets(doc).mb configure -text [lindex $docs 0 0]

    # Populate the documentation list
    [$widgets(doc).mb cget -menu] delete 0 end
    foreach item $docs {
      [$widgets(doc).mb cget -menu] add command -label [lindex $item 0] -command [list $widgets(doc).mb configure -text [lindex $item 0]]
    }

    # Initialize the widget
    if {$opts(-str) ne ""} {
      $widgets(doc).e insert end $opts(-str)
    }
    if {($opts(-url) ne "") && ([set name [lsearch -exact -inline -index 1 $docs $opts(-url)]] ne "")} {
      $widgets(doc).mb configure -text $name
    }

    # Display the user input widget
    panel_place $widgets(doc)

    # Wait for the panel to be done
    focus $widgets(doc).mb
    tkwait variable gui::user_exit_status

    # Hide the user input widget
    panel_forget $widgets(doc)

    set name    [$widgets(doc).mb cget -text]
    set url     [lindex [lsearch -exact -index 0 -inline $docs $name] 1]
    set rsplist [list str [$widgets(doc).e get] name $name url $url save $saved]

    return [set gui::user_exit_status]

  }

  ######################################################################
  # This procedure should be called whenever the theme changes.  Updates
  # the given text widget.
  proc update_theme {txt} {

    # Get the current syntax theme
    array set theme  [theme::get_syntax_colors]
    array set stheme [theme::get_category_options text_scrollbar 1]

    [winfo parent $txt] configure -background $stheme(-background)

    # Set the text background color to the current theme
    $txt configure -background $theme(background) -foreground $theme(foreground) \
      -selectbackground $theme(select_background) -selectforeground $theme(select_foreground) \
      -insertbackground $theme(foreground) -blockbackground $theme(cursor) \
      -highlightcolor $theme(border_highlight) \
      -linemapbg $theme(linemap) -linemapfg $theme(line_number) \
      -linemap_mark_color $theme(marker) -linemap_separator_color $theme(linemap_separator) \
      -warnwidth_bg $theme(warning_width) -relief flat \
      -diffaddbg $theme(difference_add) -diffsubbg $theme(difference_sub) \
      -matchchar_fg $theme(background) -matchchar_bg $theme(foreground) \
      -matchaudit_bg $theme(attention) -theme [array get theme]

    catch {

      # If the bird's eye view exists, update it
      get_info $txt txt beye

      if {[winfo exists $beye]} {

        # Calculate the background color
        set background [utils::auto_adjust_color [$txt cget -background] 25]

        # Create the bird's eye viewer
        $beye configure -background $theme(background) -foreground $theme(foreground) \
          -inactiveselectbackground $background -selectbackground $background

      }

    }

  }

}
