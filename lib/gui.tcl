# Name:    gui.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Contains all of the main GUI elements for the editor and
#          their behavior.

namespace eval gui {

  source [file join $::tke_dir lib ns.tcl]

  variable curr_id          0
  variable files            {}
  variable pw_index         0
  variable pw_current       0
  variable nb_index         0
  variable nb_move          ""
  variable file_move        0
  variable session_file     [file join $::tke_home session.tkedat]
  variable lengths          {}
  variable user_exit_status ""
  variable file_locked      0
  variable file_favorited   0
  variable last_opened      [list]
  variable fif_files        [list]
  variable info_clear       ""
  variable trailing_ws_re   {[\ \t]+$}
  variable case_sensitive   1

  array set widgets         {}
  array set language        {}
  array set images          {}
  array set tab_tip         {}
  array set line_sel_anchor {}
  array set tab_current     {}
  array set txt_current     {}
  array set cursor_hist     {}

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
  }

  #######################
  #  PUBLIC PROCEDURES  #
  #######################

  ######################################################################
  # Returns the file index based on the given fname.  If the filename
  # was not found, return an index value of -1.
  proc get_file_index {fname} {

    variable files
    variable files_index

    return [lsearch -index $files_index(fname) $files $fname]

  }

  ######################################################################
  # Checks to see if the given file is newer than the file within the
  # editor.  If it is newer, prompt the user to update the file.
  proc check_file {index} {

    variable files
    variable files_index

    set fname [lindex $files $index $files_index(fname)]
    if {$fname ne ""} {
      set mtime [lindex $files $index $files_index(mtime)]
      if {[file exists $fname]} {
        file stat $fname stat
        if {$mtime != $stat(mtime)} {
          if {[lindex $files $index $files_index(modified)]} {
            set answer [tk_messageBox -parent . -icon question -message [msgcat::mc "Reload file?"] \
              -detail $fname -type yesno -default yes]
            if {$answer eq "yes"} {
              update_file $index
            }
          } else {
            update_file $index
          }
          lset files $index $files_index(mtime) $stat(mtime)
        }
      } elseif {$mtime ne ""} {
        set answer [tk_messageBox -parent . -icon question -message [msgcat::mc "Delete tab?"] \
          -detail $fname -type yesno -default yes]
        if {$answer eq "yes"} {
          close_tab [lindex $files $index $files_index(tab)]
        } else {
          lset files $index $files_index(mtime) ""
        }
      }
    }

  }

  ######################################################################
  # Polls every 10 seconds to see if any of the loaded files have been
  # updated since the last save.
  proc poll {} {

    variable files
    variable files_index

    # Check the modification of every file in the files list
    for {set i 0} {$i < [llength $files]} {incr i} {
      check_file $i
    }

    # Check again after 10 seconds
    after 10000 [ns gui]::poll

  }

  ######################################################################
  # Sets the title of the window to match the current file.
  proc set_title {} {

    # Get the current tab
    if {([set tb [current_tabbar]] ne "") && ([llength [$tb tabs]] > 0)} {
      set tab_name [$tb tab current -text]
    } else {
      set tab_name ""
    }

    wm title . "$tab_name \[[lindex [split [info hostname] .] 0]:[pwd]\]"

  }

  ######################################################################
  # Creates all images.
  proc create_images {} {

    variable images

    # Delete any previously created images that we will be recreating
    if {[array size images] > 0} {
      foreach name [list lock readonly diff close split global] {
        image delete $images($name)
      }
      foreach name [array names images mnu,*] {
        if {$images($name) ne ""} {
          image delete $images($name)
        }
      }
    }

    set foreground [utils::get_default_foreground]

    switch [preferences::get General/WindowTheme] {
      dark {
        set lock     $foreground
        set readonly grey70
        set diff     $foreground
        set images(global) [image create photo -file [file join $::tke_dir lib images global_dark.gif]]
      }
      default {
        set lock     $foreground
        set readonly grey30
        set diff     $foreground
        set images(global) [image create photo -file [file join $::tke_dir lib images global.gif]]
      }
    }

    set images(lock)     [image create bitmap -file     [file join $::tke_dir lib images lock.bmp] \
                                              -maskfile [file join $::tke_dir lib images lock.bmp] \
                                              -foreground $lock]
    set images(readonly) [image create bitmap -file     [file join $::tke_dir lib images lock.bmp] \
                                              -maskfile [file join $::tke_dir lib images lock.bmp] \
                                              -foreground $readonly]
    set images(diff)     [image create bitmap -file     [file join $::tke_dir lib images diff.bmp] \
                                              -maskfile [file join $::tke_dir lib images diff.bmp] \
                                              -foreground $diff]
    set images(close)    [image create bitmap -file     [file join $::tke_dir lib images close.bmp] \
                                              -maskfile [file join $::tke_dir lib images close.bmp] \
                                              -foreground $foreground]
    set images(split)    [image create bitmap -file     [file join $::tke_dir lib images split.bmp] \
                                              -maskfile [file join $::tke_dir lib images split.bmp] \
                                              -foreground $foreground]

    # Menu-readable versions of the tab icons
    foreach name [list lock readonly diff] {
      set ifile [lindex [$images($name) configure -file] 4]
      set images(mnu,$images($name)) [image create bitmap -file $ifile -maskfile $ifile -foreground black]
    }
    set images(mnu,) ""
    
  }

  ######################################################################
  # Create the main GUI interface.
  proc create {} {

    variable widgets
    variable images

    # Set the application icon photo
    wm iconphoto . [image create photo -file [file join $::tke_dir lib images tke_logo_128.gif]]

    # Create images
    create_images
    set images(logo) [image create photo -file [file join $::tke_dir lib images tke_logo_64.gif]]

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
    set widgets(fif)       [ttk::frame .fif]
    ttk::label $widgets(fif).lf -text "Find: "
    set widgets(fif_find)  [ttk::entry $widgets(fif).ef]
    set widgets(fif_case)  [ttk::checkbutton $widgets(fif).case -text "Aa" -variable gui::case_sensitive]
    ttk::label $widgets(fif).li -text "In: "
    set widgets(fif_in)    [tokenentry::tokenentry $widgets(fif).ti -font [$widgets(fif_find) cget -font]]
    set widgets(fif_close) [ttk::label $widgets(fif).close -image $images(close)]

    tooltip::tooltip $widgets(fif_case) "Case sensitivity"

    bind $widgets(fif_find) <Return> {
      if {([llength [$gui::widgets(fif_in) tokenget]] > 0) && \
          ([$gui::widgets(fif_find) get] ne "")} {
        set gui::user_exit_status 1
      }
    }
    bind $widgets(fif_find)          <Escape>    { set gui::user_exit_status 0 }
    bind [$widgets(fif_in) entrytag] <Return>    { if {[gui::check_fif_for_return]} break }
    bind [$widgets(fif_in) entrytag] <Escape>    { set gui::user_exit_status 0 }
    bind $widgets(fif_case)          <Escape>    { set gui::user_exit_status 0 }
    bind $widgets(fif_close)         <Button-1>  { set gui::user_exit_status 0 }
    bind $widgets(fif_close)         <Key-space> { set gui::user_exit_status 0 }

    grid columnconfigure $widgets(fif) 1 -weight 1
    grid $widgets(fif).lf    -row 0 -column 0 -sticky ew -pady 2
    grid $widgets(fif).ef    -row 0 -column 1 -sticky ew -pady 2
    grid $widgets(fif).case  -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $widgets(fif).close -row 0 -column 3 -sticky news -padx 2 -pady 2
    grid $widgets(fif).li    -row 1 -column 0 -sticky ew -pady 2
    grid $widgets(fif).ti    -row 1 -column 1 -sticky ew -pady 2 -columnspan 2

    # Create the information bar
    set widgets(info)        [ttk::frame .if]
    set widgets(info_state)  [ttk::label .if.l1]
    set widgets(info_msg)    [ttk::label .if.l2]
    set widgets(info_indent) [indent::create_menubutton .if.ind]
    set widgets(info_syntax) [syntax::create_menubutton .if.syn]

    $widgets(info_syntax) configure -state disabled

    pack .if.l1  -side left  -padx 2 -pady 2
    pack .if.l2  -side left  -padx 2 -pady 2
    pack .if.syn -side right -padx 2 -pady 2
    pack .if.ind -side right -padx 2 -pady 2

    # Create the configurable response widget
    set widgets(ursp)       [ttk::frame .rf]
    set widgets(ursp_label) [ttk::label .rf.l]
    set widgets(ursp_entry) [ttk::entry .rf.e]
    ttk::label .rf.close -image $images(close)

    bind $widgets(ursp_entry) <Return>    "set gui::user_exit_status 1"
    bind $widgets(ursp_entry) <Escape>    "set gui::user_exit_status 0"
    bind .rf.close            <Button-1>  "set gui::user_exit_status 0"
    bind .rf.close            <Key-space> "set gui::user_exit_status 0"

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
    set widgets(menu) [menu $widgets(nb_pw).popupMenu -tearoff 0 -postcommand gui::setup_tab_popup_menu]
    $widgets(menu) add command -label [msgcat::mc "Close Tab"] -command {
      gui::close_current {}
    }
    $widgets(menu) add command -label [msgcat::mc "Close Other Tab(s)"] -command {
      gui::close_others
    }
    $widgets(menu) add command -label [msgcat::mc "Close All Tabs"] -command {
      gui::close_all
    }
    $widgets(menu) add separator
    $widgets(menu) add checkbutton -label [msgcat::mc "Locked"] -onvalue 1 -offvalue 0 -variable gui::file_locked -command {
      gui::set_current_file_lock {} $gui::file_locked
    }
    $widgets(menu) add checkbutton -label [msgcat::mc "Favorited"] -onvalue 1 -offvalue 0 -variable gui::file_favorited -command {
      gui::set_current_file_favorite {} $gui::file_favorited
    }
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Show in Sidebar"] -command {
      gui::show_current_in_sidebar
    }
    $widgets(menu) add separator
    $widgets(menu) add command -label [msgcat::mc "Move to Other Pane"] -command {
      gui::move_to_pane
    }

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

    # If the user attempts to close the window via the window manager, treat
    # it as an exit request from the menu system.
    wm protocol . WM_DELETE_WINDOW {
      menus::exit_command
    }

    # Trace changes to the Appearance/Theme preference variable
    trace variable preferences::prefs(Editor/WarningWidth)       w gui::handle_warning_width_change
    trace variable preferences::prefs(Editor/MaxUndo)            w gui::handle_max_undo
    trace variable preferences::prefs(View/AllowTabScrolling)    w gui::handle_allow_tab_scrolling
    trace variable preferences::prefs(Tools/VimMode)             w gui::handle_vim_mode
    trace variable preferences::prefs(Appearance/EditorFontSize) w gui::handle_editor_font_size

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

    variable widgets

    # Set the warning width to the specified value
    foreach pane [$widgets(nb_pw) panes] {
      foreach tab [$pane.tbf.tb tabs] {
        foreach txt_pane [$tab.pw panes] {
          $txt_pane.txt configure -warnwidth [preferences::get Editor/WarningWidth]
        }
      }
    }

  }

  ######################################################################
  # Handles any preference changes to the Editor/MaxUndo setting.
  proc handle_max_undo {name1 name2 op} {

    variable widgets

    # Set the max_undo to the specified value
    foreach pane [$widgets(nb_pw) panes] {
      foreach tab [$pane.tbf.tb tabs] {
        foreach txt_pane [$tab.pw panes] {
          $txt_pane.txt configure -maxundo [preferences::get Editor/MaxUndo]
        }
      }
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
  # Handles any changes to the Tools/VimMode preference variable.
  proc handle_vim_mode {name1 name2 op} {

    vim::set_vim_mode_all

  }

  ######################################################################
  # Handles any changes to the General/WindowTheme preference value.
  proc handle_window_theme {theme} {

    variable widgets
    variable images

    if {[info exists widgets(nb_pw)]} {

      # Get the default background and foreground colors
      set bg  [utils::get_default_background]
      set fg  [utils::get_default_foreground]
      set abg [utils::auto_adjust_color $bg 30]

      # Store the readonly/lock status of each tab
      array set tab_status [list]
      foreach nb [$widgets(nb_pw) panes] {
        for {set i 0} {$i < [llength [$nb.tbf.tb tabs]]} {incr i} {
          if {[$nb.tbf.tb tab $i -image] eq $images(readonly)} {
            set tab_status($nb.tbf.tb,$i,readonly) 1
          } elseif {[$nb.tbf.tb tab $i -image] eq $images(lock)} {
            set tab_status($nb.tbf.tb,$i,lock) 1
          } elseif {[$nb.tbf.tb tab $i -image] eq $images(diff)} {
            set tab_status($nb.tbf.tb,$i,diff) 1
          }
        }
      }

      # Update all of the images
      create_images

      # Update the lock/readonly/diff images in the tabs
      foreach name [array names tab_status] {
        lassign [split $name ,] tb i type
        $tb tab $i -image $images($type)
      }

      # Update the find in file close button
      $widgets(fif_close) configure -image $images(close)
      # $widgets(fif_in)    configure -background $fg

      # Update all of the tabbars
      foreach nb [$widgets(nb_pw) panes] {
        $nb.tbf.tb    configure -background $bg -foreground $fg -activebackground $abg -inactivebackground $bg
        set tabs [$nb.tbf.tb tabs]
        foreach tab $tabs {
          $tab.pw.tf.split  configure -image $images(split)
          $tab.sf.close     configure -image $images(close)
          $tab.rf.close     configure -image $images(close)
          $tab.rf.glob      configure -image $images(global)
          if {[winfo exists $tab.pw.tf2.split]} {
            $tab.pw.tf2.split configure -image $images(close)
          }
        }
      }

      # We need to adjust the appearance of the diff map widgets (if they exist)
      diff::handle_window_theme $theme

    }

  }

  ######################################################################
  # Updates all of the font sizes in the text window to the given.
  proc handle_editor_font_size {name1 name2 op} {

    # Update the size of the editor_font
    font configure editor_font -size [preferences::get Appearance/EditorFontSize]

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

    return [expr {([llength [[current_tabbar] tabs]] > 1) || ([llength [$widgets(nb_pw) panes]] > 1)}]

  }

  ######################################################################
  # Sets up the tab popup menu.
  proc setup_tab_popup_menu {} {

    variable widgets
    variable files
    variable files_index
    variable file_locked
    variable file_favorited

    # Get the current file index
    set file_index [current_file]

    # Get the filename of the current file
    set fname [lindex $files $file_index $files_index(fname)]

    # Get the readonly variable
    set readonly [lindex $files $file_index $files_index(readonly)]

    # Set the file_locked variable
    set file_locked [expr $readonly || [lindex $files $file_index $files_index(lock)]]

    # Get the difference mode
    set diff_mode [lindex $files $file_index $files_index(diff)]

    # Set the file_favorited variable
    set file_favorited [favorites::is_favorite $fname]

    # Get the current tabbar
    set tb [current_tabbar]

    # Set the state of the menu items
    if {[llength [$tb tabs]] > 1} {
      $widgets(menu) entryconfigure [msgcat::mc "Close Other*"] -state normal
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Close Other*"] -state disabled
    }
    if {([llength [$tb tabs]] > 1) || ([llength [$widgets(nb_pw) panes]] > 1)} {
      $widgets(menu) entryconfigure [msgcat::mc "Move*"] -state normal
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Move*"] -state disabled
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
      $widgets(menu) entryconfigure [msgcat::mc "Favorited"]       -state [expr {$diff_mode ? "disabled" : "normal"}]
    }

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

  }

  ######################################################################
  # Hides the status view
  proc hide_status_view {} {

    variable widgets

    catch { grid remove $widgets(info) }

  }

  ######################################################################
  # Shows the line numbers.
  proc set_line_number_view {tid value} {

    # Show the line numbers in the current editor
    [current_txt $tid] configure -linemap $value

  }

  ######################################################################
  # Changes the given filename to the new filename in the file list and
  # updates the tab name to match the new name.
  proc change_filename {old_name new_name} {

    variable files
    variable files_index

    # If the given old_name exists in the file list, update it and
    # also update the tab name.
    if {[set index [lsearch -index $files_index(fname) $files $old_name]] != -1} {

      # Update the file information
      lset files $index $files_index(fname) $new_name

      # Update the tab name
      set tab [lindex $files $index $files_index(tab)]
      [lindex [pane_tb_index_from_tab $tab] 1] tab $tab -text [file tail $new_name]

      # Update the title if necessary
      set_title

    }

  }

  ######################################################################
  # Returns 1 if the given file exists in one of the notebooks.
  proc file_exists {fname} {

    variable files
    variable files_index

    # Attempt to find the file index for the given filename and check the diff bit
    foreach index [lsearch -all -index $files_index(fname) $files $fname] {
      if {[lindex $files $index $files_index(diff)] == 0} {
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Save the window geometry to the geometry.dat file.
  proc save_session {} {

    variable widgets
    variable session_file
    variable last_opened
    variable files
    variable files_index

    # Gather content to save
    set content(Geometry)                [wm geometry .]
    set content(CurrentWorkingDirectory) [pwd]
    set content(Sidebar)                 [sidebar::save_session]
    set content(Launcher)                [launcher::save_session]

    # Gather the current tab info
    foreach file $files {

      set tab [lindex $file $files_index(tab)]
      set txt [get_txt_from_tab $tab]
      lassign [pane_tb_index_from_tab $tab] pane tb tab_index

      set finfo(fname)       [lindex $file $files_index(fname)]
      set finfo(savecommand) [lindex $file $files_index(save_cmd)]
      set finfo(pane)        $pane
      set finfo(tab)         $tab_index
      set finfo(lock)        [lindex $file $files_index(lock)]
      set finfo(readonly)    [lindex $file $files_index(readonly)]
      set finfo(diff)        [lindex $file $files_index(diff)]
      set finfo(sidebar)     [lindex $file $files_index(sidebar)]
      set finfo(language)    [syntax::get_current_language $txt]
      set finfo(buffer)      [lindex $file $files_index(buffer)]
      set finfo(indent)      [indent::get_indent_mode $txt]
      set finfo(modified)    0

      lappend content(FileInfo) [array get finfo]

    }

    # Get the currently selected tabs
    foreach nb [$widgets(nb_pw) panes] {
      if {[set tab [$nb.tbf.tb select]] ne ""} {
        lappend content(CurrentTabs) [$nb.tbf.tb index $tab]
      }
    }

    # Get the last_opened list
    set content(LastOpened) $last_opened

    # Write the content to the save file
    catch { tkedat::write $session_file [array get content] }

  }

  ######################################################################
  # Loads the geometry information (if it exists) and changes the current
  # window geometry to match the read value.
  proc load_session {tid} {

    variable widgets
    variable session_file
    variable last_opened
    variable files
    variable files_index
    variable pw_current

    # Read the state file
    if {![catch { tkedat::read $session_file } rc]} {

      array set content [list \
        Geometry                [wm geometry .] \
        CurrentWorkingDirectory [pwd] \
        Sidebar                 [list] \
        Launcher                [list] \
        FileInfo                [list] \
        CurrentTabs             [list] \
        LastOpened              "" \
      ]

      array set content $rc

      # Put the state information into the rest of the GUI
      wm geometry . $content(Geometry)

      # Restore the "last_opened" list
      set last_opened $content(LastOpened)

      # Load the session information into the sidebar
      sidebar::load_session $content(Sidebar)

      # Load the session information into the launcher
      launcher::load_session $content(Launcher)

      # If we are supposed to load the last saved session, do it now
      if {[preferences::get General/LoadLastSession] && \
          ([llength $files] == 1) && \
          ([lindex $files 0 $files_index(fname)] eq "")} {

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
        }

        # If the second pane is necessary, create it now
        if {[llength $content(CurrentTabs)] == 2} {
          add_notebook
        }

        # Add the tabs (in order) to each of the panes and set the current tab in each pane
        for {set pane 0} {$pane < [llength $content(CurrentTabs)]} {incr pane} {
          set pw_current $pane
          set set_tab    1
          foreach index [lindex $ordered $pane] {
            if {$index ne ""} {
              array set finfo [lindex $content(FileInfo) $index]
              if {[file exists $finfo(fname)]} {
                add_file end $finfo(fname) \
                  -savecommand $finfo(savecommand) -lock $finfo(lock) -readonly $finfo(readonly) \
                  -diff $finfo(diff) -sidebar $finfo(sidebar)
                if {[syntax::get_current_language [current_txt {}]] ne $finfo(language)} {
                  syntax::set_language $finfo(language)
                }
                if {[info exists finfo(indent)]} {
                  set_current_indent_mode $tid $finfo(indent)
                }
              } else {
                set set_tab 0
              }
            }
          }
          if {$set_tab} {
            set_current_tab [lindex [[lindex [$widgets(nb_pw) panes] $pane].tbf.tb tabs] [lindex $content(CurrentTabs) $pane]]
          }
        }

      }

    }

  }

  ######################################################################
  # Makes the next tab in the notebook viewable.
  proc next_tab {} {

    variable pw_current
    variable tab_current

    # Get the location information for the current tab in the current pane
    lassign [pane_tb_index_from_tab $tab_current($pw_current)] pane tb tab_index

    # Get the tab index of the tab to the right of the currently selected tab
    set index [expr $tab_index + 1]

    # If the new tab index is at the end, circle to the first tab
    if {$index == [$tb index end]} {
      set index 0
    }

    # Select the next tab
    set_current_tab [lindex [$tb tabs] $index]

  }

  ######################################################################
  # Makes the previous tab in the notebook viewable.
  proc previous_tab {} {

    variable pw_current
    variable tab_current

    # Get the location information for the current tab in the current pane
    lassign [pane_tb_index_from_tab $tab_current($pw_current)] pane tb tab_index

    # Get the tab index of the tab to the left of the currently selected tab
    set index [expr $tab_index - 1]

    # If the new tab index is at the less than 0, circle to the last tab
    if {$index == -1} {
      set index [expr [$tb index end] - 1]
    }

    # Select the previous tab
    set_current_tab [lindex [$tb tabs] $index]

  }

  ######################################################################
  # Makes the last viewed tab in the notebook viewable.
  proc last_tab {} {

    variable pw_current
    variable tab_current

    lassign [pane_tb_index_from_tab $tab_current($pw_current)] pane tb

    # Select the last tab
    set_current_tab [lindex [$tb tabs] [$tb index last]]

  }

  ######################################################################
  # If more than one pane is displayed, sets the current pane to the other
  # pane.
  proc next_pane {} {

    variable widgets
    variable pw_current
    variable tab_current

    # If we have more than one pane, go to it
    if {[llength [$widgets(nb_pw) panes]] > 1} {
      set_current_tab $tab_current([expr $pw_current ^ 1])
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

    variable pw_current
    variable tab_current

    if {[info exists tab_current($pw_current)]} {
      return [llength [[lindex [pane_tb_index_from_tab $tab_current($pw_current)] 1] tabs]]
    } else {
      return 0
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
                  ([lindex $files 0 $files_index(fname)] eq "") && \
                  ([vim::get_cleaned_content [get_txt_from_tab [lindex [[lindex [$widgets(nb_pw) panes] 0].tbf.tb tabs] 0]]] eq "")}]

  }

  ######################################################################
  # Adds a new file to the editor pane.
  #
  # Several options are available:
  # -savecommand <command>  Optional command that is run when the file is saved.
  # -lock        <bool>     Initial lock setting.
  # -readonly    <bool>     Set if file should not be saveable.
  # -sidebar     <bool>     Specifies if file/directory should be added to the sidebar.
  # -buffer      <bool>     If true, treats contents as a temporary buffer.
  # -gutters     <list>     Creates a gutter in the editor.  The contents of list are as follows:
  #                           {name {{symbol_name {symbol_tag_options+}}+}}+
  #                         For a list of valid symbol_tag_options, see the options available for
  #                         tags in a text widget.
  proc add_new_file {index args} {

    variable files
    variable files_index
    variable pw_current

    # Handle options
    array set opts [list \
      -savecommand "" \
      -lock        0 \
      -readonly    0 \
      -sidebar     $::cl_sidebar \
      -buffer      0 \
      -gutters     [list] \
    ]
    array set opts $args

    # Perform untitled tab check
    if {[untitled_check]} {
      return
    }

    # Adjust the index (if necessary)
    set index [adjust_insert_tab_index $index "Untitled"]

    # Get the current index
    set w [insert_tab $index [msgcat::mc "Untitled"] 0 $opts(-gutters)]

    # Create the file info structure
    set file_info [lrepeat [array size files_index] ""]
    lset file_info $files_index(fname)    ""
    lset file_info $files_index(mtime)    ""
    lset file_info $files_index(save_cmd) $opts(-savecommand)
    lset file_info $files_index(tab)      $w
    lset file_info $files_index(lock)     $opts(-lock)
    lset file_info $files_index(readonly) $opts(-readonly)
    lset file_info $files_index(sidebar)  $opts(-sidebar)
    lset file_info $files_index(buffer)   $opts(-buffer)
    lset file_info $files_index(modified) 0
    lset file_info $files_index(gutters)  $opts(-gutters)
    lset file_info $files_index(diff)     0

    # Add the file information to the files list
    lappend files $file_info

    # Add the file's directory to the sidebar and highlight it
    if {$opts(-sidebar)} {
      sidebar::add_directory [pwd]
    }

    # Set the tab image for the current file
    set_current_tab_image {}

    # Run any plugins that need to be run when a file is opened
    plugins::handle_on_open [expr [llength $files] - 1]

  }

  ######################################################################
  # Creates a new tab for the given filename specified at the given index
  # tab position.
  #
  # Several options are available:
  # -savecommand <command>  Optional command that is run when the file is saved.
  # -lock        <bool>     Initial lock setting.
  # -readonly    <bool>     Set if file should not be saveable.
  # -sidebar     <bool>     Specifies if file/directory should be added to the sidebar.
  # -buffer      <bool>     If true, treats the text widget as a temporary buffer.
  # -gutters     <list>     Creates a gutter in the editor.  The contents of list are as follows:
  #                           {name {{symbol_name {symbol_tag_options+}}+}}+
  #                         For a list of valid symbol_tag_options, see the options available for
  #                         tags in a text widget.
  # -diff        <bool>     Specifies if we need to do a diff of the file.
  proc add_file {index fname args} {

    variable widgets
    variable files
    variable files_index
    variable pw_current
    variable tab_current
    variable last_opened

    # Handle arguments
    array set opts {
      -savecommand ""
      -lock        0
      -readonly    0
      -sidebar     1
      -buffer      0
      -gutters     {}
      -diff        0
    }
    array set opts $args

    # If have a single untitled tab in view, close it before adding the file
    if {[untitled_check]} {
      close_tab $tab_current($pw_current) 0 0
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

      set_current_tab [lindex $files $file_index $files_index(tab)]

    # Otherwise, load the file in a new tab
    } else {

      # Adjust the index (if necessary)
      set index [adjust_insert_tab_index $index [file tail $fname]]

      # Add the tab to the editor frame
      set w [insert_tab $index [file tail $fname] $opts(-diff) $opts(-gutters)]

      # Create the file information
      set file_info [lrepeat [array size files_index] ""]
      lset file_info $files_index(fname)    $fname
      lset file_info $files_index(mtime)    ""
      lset file_info $files_index(save_cmd) $opts(-savecommand)
      lset file_info $files_index(tab)      $w
      lset file_info $files_index(lock)     $opts(-lock)
      lset file_info $files_index(readonly) [expr $opts(-readonly) || $opts(-diff)]
      lset file_info $files_index(sidebar)  $opts(-sidebar)
      lset file_info $files_index(buffer)   $opts(-buffer)
      lset file_info $files_index(modified) 0
      lset file_info $files_index(gutters)  $opts(-gutters)
      lset file_info $files_index(diff)     $opts(-diff)

      if {![catch { open $fname r } rc]} {

        set txt [get_txt_from_tab $w]

        # Read the file contents and insert them
        $txt insert end [string range [read $rc] 0 end-1]

        # Close the file
        close $rc

        # Change the text to unmodified
        $txt edit reset

        # Set the insertion mark to the first position
        $txt mark set insert 1.0

        # Perform an insertion adjust, if necessary
        if {[vim::in_vim_mode $txt.t]} {
          vim::adjust_insert $txt.t
        }

        file stat $fname stat
        lset file_info $files_index(mtime) $stat(mtime)
        lappend files $file_info

        # Add the file to the list of recently opened files
        gui::add_to_recently_opened $fname

        # If a diff command was specified, run and parse it now
        if {$opts(-diff)} {
          diff::show $txt
          if {[[ns preferences]::get View/ShowDifferenceInOtherPane]} {
            move_to_pane
          }
        }

      } else {

        lappend files $file_info

      }

      # Change the tab text
      [current_tabbar] tab $w -text " [file tail $fname]"

    }

    # Add the file's directory to the sidebar and highlight it
    if {$opts(-sidebar)} {
      sidebar::add_directory [file dirname [file normalize $fname]]
      sidebar::highlight_filename $fname [expr ($opts(-diff) * 2) + 1]
    }

    # Set the tab image for the current file
    set_current_tab_image {}

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
      array set nfs_mounts [preferences::get NFSMounts]
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

    variable files
    variable files_index

    # Get the file information
    set file_info [lindex $files $file_index]

    # Get the current notebook.
    set tab [lindex $file_info $files_index(tab)]

    # Get the text widget at the given index
    set txt [get_txt_from_tab $tab]

    # Get the diff value
    set diff [lindex $file_info $files_index(diff)]

    # If the editor is a difference view and is not updateable, stop now
    if {$diff && ![diff::updateable $txt]} {
      return
    }

    # Get the current insertion index
    set insert_index [$txt index insert]

    # Delete the text widget
    $txt configure -state normal
    $txt delete 1.0 end

    if {![catch "open [lindex $file_info $files_index(fname)] r" rc]} {

      # Read the file contents and insert them
      $txt insert end [string range [read $rc] 0 end-1]

      # Close the file
      close $rc

      # Change the tab text
      lassign [pane_tb_index_from_tab $tab] pane tb tab_index
      $tb tab $tab -text " [file tail [lindex $file_info $files_index(fname)]]"

      # Update the title bar (if necessary)
      set_title

      # Change the text to unmodified
      $txt edit reset
      lset files $file_index $files_index(modified) 0

      # Set the insertion mark to the first position
      $txt mark set insert $insert_index
      if {[vim::in_vim_mode $txt.t]} {
        vim::adjust_insert $txt.t
      }

      # Make the insertion mark visible
      $txt see $insert_index

      # If a diff command was specified, run and parse it now
      if {$diff} {
        diff::show $txt
      }

      # Allow plugins to be run on update
      plugins::handle_on_update $file_index

    }

    # If we are locked, set our state back to disabled
    if {[lindex $file_info $files_index(lock)]} {
      $txt configure -state disabled
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
  proc save_current {tid {save_as ""}} {

    variable files
    variable files_index

    # Get the current tabbar
    set tb [current_tabbar]

    # Get the current file index
    set file_index [current_file]

    # Get the difference mode of the current file
    set diff [lindex $files $file_index $files_index(diff)]
    
    # If a save_as name is specified, change the filename
    if {$save_as ne ""} {
      sidebar::highlight_filename [lindex $files $file_index $files_index(fname)] [expr $diff * 2]
      lset files $file_index $files_index(fname) $save_as

    # If the current file doesn't have a filename, allow the user to set it
    } elseif {([lindex $files $file_index $files_index(fname)] eq "") || \
               [lindex $files $file_index $files_index(buffer)] || \
               $diff} {
      set save_opts [list]
      if {[llength [set extensions [syntax::get_extensions $tid]]] > 0} {
        lappend save_opts -defaultextension [lindex $extensions 0]
      }
      if {[set sfile [tk_getSaveFile {*}$save_opts -parent . -title [msgcat::mc "Save As"] -initialdir [pwd]]] eq ""} {
        return
      } else {
        lset files $file_index $files_index(fname) $sfile
      }
    }

    # Run the on_save plugins
    plugins::handle_on_save $file_index

    # Save the file contents
    if {[catch { open [lindex $files $file_index $files_index(fname)] w } rc]} {
      tk_messageBox -parent . -title "Error" -type ok -default ok -message "Unable to write file" -detail $rc
      return
    }

    # Write the file contents
    puts $rc [scrub_text [current_txt $tid]]
    close $rc

    # If the file doesn't have a timestamp, it's a new file so add and highlight it in the sidebar
    if {([lindex $files $file_index $files_index(mtime)] eq "") || ($save_as ne "")} {

      # Calculate the normalized filename
      set fname [file normalize [lindex $files $file_index $files_index(fname)]]

      # Add the filename to the most recently opened list
      add_to_recently_opened $fname

      # If it is okay to add the file to the sidebar, do it now
      if {[lindex $files $file_index $files_index(sidebar)]} {

        # Add the file's directory to the sidebar
        sidebar::add_directory [file dirname $fname]

        # Highlight the file in the sidebar
        sidebar::highlight_filename [lindex $files $file_index $files_index(fname)] [expr ($diff * 2) + 1]

      }

      # Syntax highlight the file
      syntax::set_language [syntax::get_default_language [lindex $files $file_index $files_index(fname)]]

    }

    # Update the timestamp
    file stat [lindex $files $file_index $files_index(fname)] stat
    lset files $file_index $files_index(mtime) $stat(mtime)

    # Change the tab text
    $tb tab current -text " [file tail [lindex $files $file_index $files_index(fname)]]"
    set_title

    # Change the text to unmodified
    [current_txt $tid] edit modified false
    lset files $file_index $files_index(modified) 0

    # If there is a save command, run it now
    if {[lindex $files $file_index $files_index(save_cmd)] ne ""} {
      eval [lindex $files $file_index $files_index(save_cmd)]
    }

  }

  ######################################################################
  # Saves all of the opened tab contents (if necessary).  If a tab has
  # not been previously saved (a new file), that tab is made the current
  # tab and the save_current procedure is called.
  proc save_all {} {

    variable files
    variable files_index

    for {set i 0} {$i < [llength $files]} {incr i} {

      # If the file needs to be saved, do it
      if { [lindex $files $i $files_index(modified)] && \
          ![lindex $files $i $files_index(buffer)]   && \
          ![lindex $files $i $files_index(diff)]} {

        set tab  [lindex $files $i $files_index(tab)]

        # If the file needs to be saved as a new filename, call the save_current
        # procedure
        if {[lindex $files $i $files_index(fname)] eq ""} {

          set_current_tab $tab
          save_current

        # Perform a tab-only save
        } else {

          # Get the text widget
          set txt [get_txt_from_tab $tab]

          # Run the on_save plugins
          plugins::handle_on_save $i

          # Save the file contents
          if {[catch { open [lindex $files $i $files_index(fname)] w } rc]} {
            continue
          }

          # Write the file contents
          puts $rc [vim::get_cleaned_content $txt]
          close $rc

          # Update the timestamp
          file stat [lindex $files $i $files_index(fname)] stat
          lset files $i $files_index(mtime) $stat(mtime)

          # Change the tab text
          [lindex [pane_tb_index_from_tab $tab] 1] tab $tab -text " [file tail [lindex $files $i $files_index(fname)]]"

          # Change the text to unmodified
          $txt edit modified false
          lset files $i $files_index(modified) 0

          # If there is a save command, run it now
          if {[lindex $files $i $files_index(save_cmd)] ne ""} {
            eval [lindex $files $i $files_index(save_cmd)]
          }
        }

      }

    }

    # Make sure that the title is consistent
    set_title

  }

  ######################################################################
  # Close the current tab.  If force is set to 1, closes regardless of
  # modified state of text widget.  If force is set to 0 and the text
  # widget is modified, the user will be questioned if they want to save
  # the contents of the file prior to closing the tab.
  proc close_current {tid {force 0} {exiting 0}} {

    variable pw_current
    variable files
    variable files_index

    # Get the current file index
    set file_index [current_file]

    # If the file needs to be saved, do it now
    if { [lindex $files $file_index $files_index(modified)] && \
        ![lindex $files $file_index $files_index(buffer)]  && \
        ![lindex $files $file_index $files_index(diff)]    && \
        !$force} {
      set fname [file tail [lindex $files $file_index $files_index(fname)]]
      if {$fname eq ""} {
        set fname "Untitled"
      }
      set msg "[msgcat::mc Save] $fname?"
      if {[set answer [tk_messageBox -default yes -type [expr {$exiting ? {yesno} : {yesnocancel}}] -message $msg -title [msgcat::mc "Save request"]]] eq "yes"} {
        save_current $tid
      } elseif {$answer eq "cancel"} {
        return
      }
    }

    # Close the current tab
    close_tab [[current_tabbar] select] $exiting

  }

  ######################################################################
  # Closes the tab specified by "tab".  This is called by the tabbar when
  # the user clicks on the close button of a tab.
  proc close_tab_by_tabbar {w tab} {

    variable widgets
    variable files
    variable files_index
    variable pw_current

    # Get the file index
    set index [get_file_index $tab]

    # Unhighlight the file in the file browser
    set diff [lindex $files $index $files_index(diff)]
    sidebar::highlight_filename [lindex $files $index $files_index(fname)] [expr $diff * 2]

    # Run the close event for this file
    plugins::handle_on_close $index

    # Delete the file from files
    set files [lreplace $files $index $index]

    # Remove the tab frame
    catch { pack forget $tab }

    # Display the current pane (if one exists)
    if {[set tab [$w select]] ne ""} {
      set_current_tab $tab
    }

    # If we have no more tabs and there is another pane, remove this pane
    if {([llength [$w tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] > 1)} {
      $widgets(nb_pw) forget $pw_current
      set pw_current 0
      set w          [lindex [$widgets(nb_pw) panes] 0].tbf.tb
    }

    # Add a new file if we have no more tabs, we are the only pane, and the preference
    # setting is to not close after the last tab is closed.
    if {([llength [$w tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] == 1)} {
      if {[preferences::get General/ExitOnLastClose]} {
        menus::exit_command
      } else {
        add_new_file end
      }
    }

  }

  ######################################################################
  # Close the specified tab (do not ask the user about closing the tab).
  proc close_tab {tab {exiting 0} {keep_tab 1}} {

    variable widgets
    variable files
    variable files_index
    variable pw_current

    # Get the notebook
    lassign [pane_tb_index_from_tab $tab] pane tb tab_index

    # Get the file index
    set index [get_file_index $tab]

    # Unhighlight the file in the file browser (if the file was not a difference view)
    set diff [lindex $files $index $files_index(diff)]
    sidebar::highlight_filename [lindex $files $index $files_index(fname)] [expr $diff * 2]

    # Run the close event for this file
    plugins::handle_on_close $index

    # Delete the file from files
    set files [lreplace $files $index $index]

    # Remove the tab from the tabbar
    $tb delete $tab_index

    # Delete the text frame
    catch { pack forget $tab }

    # Destroy the text frame
    destroy $tab

    # Display the current pane (if one exists)
    if {[set tab [$tb select]] ne ""} {
      set_current_tab $tab 0 $exiting
    }

    # If we have no more tabs and there is another pane, remove this pane
    if {([llength [$tb tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] > 1)} {
      $widgets(nb_pw) forget $pane
      set pw_current 0
      set tb         [lindex [$widgets(nb_pw) panes] 0].tbf.tb
    }

    # Add a new file if we have no more tabs, we are the only pane, and the preference
    # setting is to not close after the last tab is closed.
    if {([llength [$tb tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] == 1) && !$exiting} {
      if {[preferences::get General/ExitOnLastClose] || $::cl_exit_on_close} {
        menus::exit_command
      } elseif {$keep_tab} {
        add_new_file end
      }
    }

  }

  ######################################################################
  # Close all tabs but the current tab.
  proc close_others {} {

    variable widgets
    variable pw_current

    set current_pw [lindex [$widgets(nb_pw) panes] $pw_current]

    foreach nb [lreverse [$widgets(nb_pw) panes]] {
      foreach tab [lreverse [$nb.tbf.tb tabs]] {
        if {($nb ne $current_pw) || ($tab ne [$nb.tbf.tb select])} {
          set_current_tab $tab 0 1
          close_current {}
        }
      }
    }

  }

  ######################################################################
  # Close all of the tabs.
  proc close_all {{exiting 0}} {

    variable widgets

    foreach nb [lreverse [$widgets(nb_pw) panes]] {
      foreach tab [lreverse [$nb.tbf.tb tabs]] {
        set_current_tab $tab 0 1
        close_current {} 0 $exiting
      }
    }

  }

  ######################################################################
  # Closes the tab with the identified name (if it exists).
  proc close_file {fname} {

    variable files
    variable files_index

    if {[set index [lsearch -index $files_index(fname) $files $fname]] != -1} {
      close_tab [lindex $files $index $files_index(tab)]
    }

  }

  ######################################################################
  # Sorts all of the open tabs (in both panes, if both panes are visible)
  # by alphabetical order.
  proc sort_tabs {} {

    variable widgets
    variable files
    variable files_index

    foreach nb [$widgets(nb_pw) panes] {

      # Create the tabbar path
      set tb "$nb.tbf.tb"

      # Get the current tab
      set current_tab [$tb select]

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
    variable files
    variable files_index

    # Get the list of panes
    set panes [$widgets(nb_pw) panes]

    # If the other pane does not exist, add it
    if {[llength $panes] == 1} {
      add_notebook
      set panes [$widgets(nb_pw) panes]
    }

    # Get the relevant information from the current text widget
    set txt      [current_txt {}]
    set file     [lindex $files [current_file]]
    if {[set fname [current_filename]] eq ""} {
      set fname [msgcat::mc "Untitled"]
    }
    set content  [$txt get 1.0 end-1c]
    set insert   [$txt index insert]
    set select   [$txt tag ranges sel]
    set modified [lindex $file $files_index(modified)]
    set diff     [lindex $file $files_index(diff)]
    set language [syntax::get_current_language $txt]

    # Collect the gutter symbols
    array set symbols {}
    foreach gutter [lindex $file $files_index(gutters)] {
      set gutter_name [lindex $gutter 0]
      set symbols($gutter_name) [$txt gutter get $gutter_name]
    }

    # Delete the current tab
    close_current {} 1

    # Get the name of the other pane if it exists
    if {[llength [$widgets(nb_pw) panes]] == 2} {
      set pw_current [expr $pw_current ^ 1]
    }

    # Adjust the index (if necessary)
    set index [adjust_insert_tab_index end [file tail $fname]]

    # Create a new tab
    set w [insert_tab $index [file tail $fname] $diff [lindex $file $files_index(gutters)] $language]

    # Get the current text widget
    set txt [current_txt {}]

    # Update the file components to include position change information
    lset file $files_index(tab)      $w
    lset file $files_index(modified) 0
    lappend files $file

    if {$diff} {

      diff::show $txt 1

    } else {

      # Add the text, insertion marker and selection
      $txt insert end $content
      $txt mark set insert $insert

      # Add the gutter symbols
      foreach {name symbol_list} [array get symbols] {
        $txt gutter set $name {*}$symbol_list
      }

    }

    # Perform an insertion adjust, if necessary
    if {[vim::in_vim_mode $txt.t]} {
      vim::adjust_insert $txt.t
    }

    # Add the selection (if it exists)
    if {[llength $select] > 0} {
      $txt tag add sel {*}$select
    }

    # If the text widget was not in a modified state, force it to be so now
    if {!$modified} {
      $txt edit modified false
      [current_tabbar] tab current -text " [file tail $fname]"
      set_title
    }

    # Highlight the file in the sidebar
    sidebar::add_directory [file dirname [file normalize $fname]]
    sidebar::highlight_filename $fname [expr ($diff * 2) + 1]

    # Set the tab image for the moved file
    set_current_tab_image {}
      
  }

  ######################################################################
  # Performs an undo of the current tab.
  proc undo {tid} {

    # Get the current textbox
    set txt [current_txt $tid]

    # Perform the undo operation from Vim perspective
    vim::undo $txt.t

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
    vim::redo $txt.t

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
    cliphist::add_from_clipboard

  }

  ##############################################################################
  # This procedure performs a text selection copy operation.
  proc copy {tid} {

    # Perform the copy
    [current_txt $tid] copy

    # Add the clipboard contents to history
    cliphist::add_from_clipboard

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
      vim::handle_paste $txt

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
        indent::format_text [current_txt $tid].t $insertpos "$insertpos+${cliplen}c"

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
  proc format {tid type} {

    variable files
    variable files_index

    # Get the current text widget
    set txt [current_txt $tid]

    # Get the locked/readonly status
    set file_index [current_file]
    set readonly   [expr [lindex $files $file_index $files_index(lock)] || \
                         [lindex $files $file_index $files_index(readonly)]]

    # If the file is locked or readonly, set the state so that it can be modified
    if {$readonly} {
      $txt configure -state normal
    }

    if {$type eq "selected"} {
      foreach {endpos startpos} [lreverse [$txt tag ranges sel]] {
        indent::format_text $txt.t $startpos $endpos
      }
    } else {
      indent::format_text $txt.t 1.0 end
    }

    # If the file is locked or readonly, clear the modified state and reset the text state
    # back to disabled
    if {$readonly} {

      # Clear the modified state and reset the state
      $txt edit modified false
      $txt configure -state disabled

      # Change the tab text
      [current_tabbar] tab current -text " [file tail [lindex $files $file_index $files_index(fname)]]"
      set_title

      # Change the text to unmodified
      lset files $file_index $files_index(modified) 0

    }

  }

  ######################################################################
  # Displays the search bar.
  proc search {tid {dir "next"}} {

    variable pw_current
    variable tab_current

    # Get the current text widget
    set txt [current_txt $tid]

    # Get the current text frame
    set tab $tab_current($pw_current)

    # Update the search binding
    bind $tab.sf.e <Return> "[ns gui]::search_start {$tid} $dir"

    # Display the search bar and separator
    grid $tab.sf
    grid $tab.sep1

    # Clear the search entry
    $tab.sf.e delete 0 end

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

    variable pw_current
    variable tab_current

    # Get the current text frame
    set tab $tab_current($pw_current)

    # Hide the search frame
    grid remove $tab.sf
    grid remove $tab.sep1

    # Put the focus on the text widget
    set_txt_focus [last_txt_focus {}]

  }

  ######################################################################
  # Displays the search and replace bar.
  proc search_and_replace {} {

    variable pw_current
    variable tab_current

    # Get the current text frame
    set tab $tab_current($pw_current)

    # Display the search bar and separator
    grid $tab.rf
    grid $tab.sep1

    # Clear the search entry
    $tab.rf.fe delete 0 end
    $tab.rf.re delete 0 end

    # Place the focus on the find entry field
    focus $tab.rf.fe

  }

  ######################################################################
  # Closes the search and replace bar.
  proc close_search_and_replace {} {

    variable pw_current
    variable tab_current

    # Get the current text frame
    set tab $tab_current($pw_current)

    # Hide the search and replace bar
    grid remove $tab.rf
    grid remove $tab.sep1

    # Put the focus on the text widget
    set_txt_focus [last_txt_focus {}]

  }

  ######################################################################
  # Clears the current search text.
  proc clear_search {tid} {

    # Get the currently selected text widget
    set txt [current_txt $tid]

    # Clear the highlight class
    catch { ctext::deleteHighlightClass $txt search }

  }

  ######################################################################
  # Starts a text search
  proc search_start {tid {dir "next"}} {

    variable case_sensitive

    # If the user has specified a new search value, find all occurrences
    if {[set str [[current_search].e get]] ne ""} {

      # Escape any parenthesis in the regular expression
      set str [string map {{(} {\(} {)} {\)}} $str]

      # Test the regular expression, if it is invalid, let the user know
      if {[catch { regexp $str "" } rc]} {
        after 100 [list [ns gui]::set_info_message $rc]
        return
      }

      # Get the current text widget
      set txt [current_txt $tid]

      # Gather any search options
      set search_opts [list]
      if {!$case_sensitive} {
        lappend search_opts -nocase
      }

      # Clear the search highlight class
      clear_search $tid

      # Create a highlight class for the given search string
      ctext::addSearchClassForRegexp $txt search black yellow "" $str $search_opts

    }

    # Select the search term
    if {$dir eq "next"} {
      search_next $tid 0
    } else {
      search_prev $tid 0
    }

  }

  ######################################################################
  # Searches for the next occurrence of the search item.
  proc search_next {tid app} {

    set wrapped 0

    # Get the current text widget
    set txt [current_txt $tid]

    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }

    # Search the text widget from the current insertion cursor forward.
    lassign [$txt tag nextrange _search "insert+1c"] startpos endpos

    # We need to wrap on the search item
    if {$startpos eq ""} {
      lassign [$txt tag nextrange _search 1.0] startpos endpos
      set wrapped 1
    }

    # Select the next match
    if {$startpos ne ""} {
      if {![vim::in_vim_mode $txt.t]} {
        $txt tag add sel $startpos $endpos
      }
      $txt mark set insert $startpos
      $txt see insert
      if {$wrapped} {
        set_info_message "Search wrapped to beginning of file"
      }
    } else {
      set_info_message "No search results found"
    }

    # Closes the search interface
    close_search

  }

  ######################################################################
  # Searches for the previous occurrence of the search item.
  proc search_prev {tid app} {

    set wrapped 0

    # Get the current text widget
    set txt [current_txt $tid]

    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }

    # Search the text widget from the current insertion cursor forward.
    lassign [$txt tag prevrange _search insert] startpos endpos

    # We need to wrap on the search item
    if {$startpos eq ""} {
      lassign [$txt tag prevrange _search end] startpos endpos
      set wrapped 1
    }

    # Select the next match
    if {$startpos ne ""} {
      if {![vim::in_vim_mode $txt.t]} {
        $txt tag add sel $startpos $endpos
      }
      $txt mark set insert $startpos
      $txt see insert
      if {$wrapped} {
        set_info_message "Search wrapped to end of file"
      }
    } else {
      set_info_message "No search results found"
    }

    # Close the search interface
    close_search

  }

  ######################################################################
  # Searches for all of the occurrences and selects them all.
  proc search_all {tid} {

    # Get the current text widget
    set txt [current_txt $tid]

    # Clear the selection
    $txt tag remove sel 1.0 end

    # Add all matching search items to the selection
    $txt tag add sel {*}[$txt tag ranges _search]

    # Make the first line viewable
    catch {
      set firstpos [lindex [$txt tag ranges _search] 0]
      $txt mark set insert $firstpos
      $txt see $firstpos
    }

    # Close the search interface
    close_search

  }

  ######################################################################
  # Performs a search and replace operation based on the GUI element
  # settings.
  proc do_search_and_replace {tid} {

    variable pw_current
    variable tab_current
    variable case_sensitive

    # Get the current tab frame
    set tab $tab_current($pw_current)

    # Perform the search and replace
    do_raw_search_and_replace $tid 1.0 end [$tab.rf.fe get] [$tab.rf.re get] \
      !$case_sensitive [expr {[$tab.rf.glob cget -relief] eq "sunken"}]

    # Close the search and replace bar
    close_search_and_replace

  }

  ######################################################################
  # Performs a search and replace given the expression,
  proc do_raw_search_and_replace {tid sline eline search replace ignore_case all} {

    variable widgets
    variable lengths

    # Get the current text widget
    set txt [current_txt $tid]

    # Clear the selection
    $txt tag remove sel 1.0 end

    # Perform the string substitutions
    if {!$all} {
      set sline [$txt index "insert linestart"]
      set eline [$txt index "insert lineend"]
    }

    # Escape any parenthesis in the search string
    set search [string map {{(} {\(} {)} {\)}} $search]

    # Create regsub arguments
    set rs_args [list]
    if {$ignore_case} {
      lappend rs_args -nocase
    }

    # Replace the text and re-highlight the changes
    set indices [lreverse [$txt search -all -regexp -count [ns gui]::lengths {*}$rs_args -- $search $sline $eline]]
    set i       [expr [set num_indices [llength $indices]] - 1]
    foreach index $indices {
      $txt replace $index "$index+[lindex $lengths $i]c" $replace
      incr i -1
    }
    if {$num_indices > 0} {
      $txt see [lindex $indices 0]
      $txt mark set insert [lindex $indices 0]
      $txt highlight $sline $eline
    }
    set_info_message "$num_indices substitutions done"

    # Make sure that the insertion cursor is valid
    if {[[ns vim]::in_vim_mode $txt]} {
      [ns vim]::adjust_insert $txt
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
  proc set_current_tab_image {tid} {

    variable files
    variable files_index
    variable images

    # Get the current file index
    set file_index [current_file]

    # Change the state of the text widget to match the lock value
    if {[lindex $files $file_index $files_index(diff)]} {
      [current_tabbar]   tab current -compound left -image $images(diff)
      [current_txt $tid] configure -state disabled
    } elseif {[lindex $files $file_index $files_index(readonly)]} {
      [current_tabbar]   tab current -compound left -image $images(readonly)
      [current_txt $tid] configure -state disabled
    } elseif {[lindex $files $file_index $files_index(lock)]} {
      [current_tabbar]   tab current -compound left -image $images(lock)
      [current_txt $tid] configure -state disabled
    } else {
      [current_tabbar]   tab current -image ""
      [current_txt $tid] configure -state normal
    }

    return 1

  }

  ######################################################################
  # Sets the file lock to the specified value for the current file.
  proc set_current_file_lock {tid lock} {
    
    variable files
    variable files_index
    
    # Get the current file index
    set file_index [current_file]
    
    # Set the current lock status
    lset files $file_index $files_index(lock) $lock
    
    # Set the tab image to match
    set_current_tab_image $tid
    
  }

  ######################################################################
  # Set or clear the favorite status of the current file.
  proc set_current_file_favorite {tid favorite} {

    variable files
    variable files_index

    # Get the current file index
    set file_index [current_file]
    set fname      [lindex $files $file_index $files_index(fname)]

    # Add or remove the file from the favorites list
    if {$favorite} {
      favorites::add $fname
    } else {
      favorites::remove $fname
    }

  }

  ######################################################################
  # Sets auto-indent for the current editor to the given value.
  proc set_current_indent_mode {tid value} {

    # Set the auto-indent mode
    indent::set_indent_mode $value

  }

  ######################################################################
  # Shows the current file in the sidebar.
  proc show_current_in_sidebar {} {

    variable files
    variable files_index

    # Display the file in the sidebar
    sidebar::show_file [lindex $files [current_file] $files_index(fname)]

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
      lassign [winfo rgb . [set foreground [utils::get_default_foreground]]] fr fg fb
      lassign [winfo rgb . [utils::get_default_background]] br bg bb
      $widgets(info_msg) configure -text $msg -foreground $foreground
      set info_clear [after $clear_delay \
                       [list gui::clear_info_message \
                         [expr $fr >> 8] [expr $fg >> 8] [expr $fb >> 8] \
                         [expr $br >> 8] [expr $bg >> 8] [expr $bb >> 8]]]
    } else {
      puts $msg
    }

  }

  ######################################################################
  # Clears the info message.
  proc clear_info_message {fr fg fb br bg bb {fade_count 0}} {

    variable widgets
    variable info_clear

    if {$fade_count == 10} {

      # Clear the text
      $widgets(info_msg) configure -text ""

      # Clear the info_clear variable
      set info_clear ""

    } else {

      # Calculate the color
      set color [::format {#%02x%02x%02x} \
                  [expr $fr - ((($fr - $br) / 10) * $fade_count)] \
                  [expr $fg - ((($fg - $bg) / 10) * $fade_count)] \
                  [expr $fb - ((($fb - $bb) / 10) * $fade_count)]]

      # Set the foreground color to simulate the fade effect
      $widgets(info_msg) configure -foreground $color

      set info_clear [after 100 [list gui::clear_info_message $fr $fg $fb $br $bg $bb [incr fade_count]]]

    }

  }

  ######################################################################
  # Gets user input from the interface in a generic way.
  proc user_response_get {msg pvar {allow_vars 1}} {

    variable widgets

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

    # Wait for the ursp_entry widget to be visible and then grab it
    tkwait visibility $widgets(ursp_entry)
    grab $widgets(ursp_entry)

    # Wait for the widget to be closed
    vwait gui::user_exit_status

    # Reset the original focus and grab
    catch { focus $old_focus }
    catch { grab release $widgets(ursp_entry) }
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
      set var [utils::perform_substitutions $var]
    }

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
      return -code error [msgcat::mc "File index is out of range"]
    }
    if {$attr eq "sb_index"} {
      return [sidebar::get_index $index]
    } elseif {$attr eq "txt"} {
      return [get_txt_from_tab [lindex $files $index $files_index(tab)]]
    } elseif {$attr eq "current"} {
      return [expr {[get_txt_from_tab [lindex $files $index $files_index(tab)]] eq [current_txt {}]}]
    } elseif {![info exists files_index($attr)]} {
      return -code error [msgcat::mc "File attribute (%s) does not exist" $attr]
    }

    return [lindex $files $index $files_index($attr)]

  }

  ######################################################################
  # Retrieves the "find in file" inputs from the user.
  proc fif_get_input {prsp_list} {

    variable widgets
    variable fif_files
    variable case_sensitive

    upvar $prsp_list rsp_list

    # Reset the input widgets
    $widgets(fif_find) delete 0 end
    $widgets(fif_in)   delete 0 end

    # Populate the fif_in tokenentry menu
    set fif_files [sidebar::get_fif_files]
    $widgets(fif_in) configure -listvar gui::fif_files -matchmode regexp -matchindex 0 -matchdisplayindex 0

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

    vwait gui::user_exit_status

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
        lappend ins [utils::perform_substitutions $token]
      }
    }

    # Figure out any search options
    set egrep_opts [list]
    if {!$case_sensitive} {
      lappend egrep_opts -i
    }

    # Gather the input to return
    set rsp_list [list find [$widgets(fif_find) get] in $ins egrep_opts $egrep_opts]

    return $gui::user_exit_status

  }

  ######################################################################
  # Displays the help menu "About" window.
  proc show_about {} {

    variable images

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
    wm geometry  .aboutwin 300x250

    ttk::frame .aboutwin.f
    ttk::label .aboutwin.f.logo -compound left -image $images(logo) -text " tke" \
      -font [font create -family Helvetica -size 30 -weight bold]

    ttk::frame .aboutwin.f.if
    ttk::label .aboutwin.f.if.l0 -text [msgcat::mc "Developer:"]
    ttk::label .aboutwin.f.if.v0 -text "Trevor Williams"
    ttk::label .aboutwin.f.if.l1 -text [msgcat::mc "Email:"]
    ttk::label .aboutwin.f.if.v1 -text "phase1geo@gmail.com"
    ttk::label .aboutwin.f.if.l2 -text [msgcat::mc "Version:"]
    ttk::label .aboutwin.f.if.v2 -text $version_str
    ttk::label .aboutwin.f.if.l3 -text [msgcat::mc "Release Type:"]
    ttk::label .aboutwin.f.if.v3 -text $release_type
    ttk::label .aboutwin.f.if.l4 -text [msgcat::mc "Tcl/Tk Version:"]
    ttk::label .aboutwin.f.if.v4 -text [info patchlevel]

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

    ttk::label .aboutwin.f.copyright -text [msgcat::mc "Copyright %d-%d" 2013 15]

    pack .aboutwin.f.logo      -padx 2 -pady 8 -anchor w
    pack .aboutwin.f.if        -padx 2 -pady 2
    pack .aboutwin.f.copyright -padx 2 -pady 8

    pack .aboutwin.f -fill both -expand yes

    # Center the window in the editor window
    ::tk::PlaceWindow .aboutwin widget .

  }

  ######################################################################
  # Displays the number insertion dialog box if we are currently in
  # multicursor mode.
  proc insert_numbers {txt} {

    if {[multicursor::enabled $txt]} {

      set var1 ""

      # Get the number string from the user
      if {[user_response_get "Starting number:" var1]} {

        # Insert the numbers (if not successful, output an error to the user)
        if {![multicursor::insert_numbers $txt $var1]} {
          set_info_message "Unable to successfully parse number string"
        }

      }

    # Otherwise, display an error message to the user
    } else {
      set_info_message "Must be in multicursor mode to insert numbers"
    }

  }

  ######################################################################
  # Toggles the split pane for the current tab.
  proc toggle_split_pane {tid} {

    if {[llength [[current_txt $tid] peer names]] > 0} {
      hide_split_pane $tid
    } else {
      show_split_pane $tid
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
            lappend txts [get_txt2_from_tab $tab]
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
  # Gets the pane and notebook from the given tab.
  proc pane_tb_index_from_tab {tab} {

    variable widgets

    set pane 0
    foreach nb [$widgets(nb_pw) panes] {
      if {[set index [lsearch [$nb.tbf.tb tabs] $tab]] != -1} {
        return [list $pane $nb.tbf.tb $index]
      }
      incr pane
    }

    return -code error "Internal error:  pane_tb_index_from_tab called for non-existent tab ($tab)"

  }

  ######################################################################
  # Add notebook widget.
  proc add_notebook {} {

    variable widgets
    variable curr_notebook
    variable images

    # Create editor notebook
    $widgets(nb_pw) add [set nb [ttk::frame $widgets(nb_pw).nb[incr curr_notebook]]] -weight 1

    # Figure out colors to apply to notebook
    set bg  [utils::get_default_background]
    set fg  [utils::get_default_foreground]
    set abg [utils::auto_adjust_color $bg 30]

    # Add the tabbar frame
    ttk::frame $nb.tbf
    tabbar::tabbar $nb.tbf.tb -command "gui::set_current_tab_from_tb" -closecommand "gui::close_tab_by_tabbar" \
      -background $bg -foreground $fg -activebackground $abg -inactivebackground $bg

    grid rowconfigure    $nb.tbf 0 -weight 1
    grid columnconfigure $nb.tbf 0 -weight 1
    grid $nb.tbf.tb    -row 0 -column 0 -sticky news
    grid remove $nb.tbf.tb

    bind [$nb.tbf.tb scrollpath left]  <Button-$::right_click> "gui::show_tabs $nb.tbf.tb left"
    bind [$nb.tbf.tb scrollpath right] <Button-$::right_click> "gui::show_tabs $nb.tbf.tb right"

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
      set pane [winfo parent [winfo parent [winfo parent %W]]]
      set gui::pw_current [lsearch [$gui::widgets(nb_pw) panes] [winfo parent [winfo parent [winfo parent %W]]]]
      if {![catch "[winfo parent %W] select @%x,%y"]} {
        tk_popup $gui::widgets(menu) %X %Y
      }
    }

    # Handle tooltips
    bind [$nb.tbf.tb btag] <Motion> { gui::handle_notebook_motion [winfo parent %W] %x %y }

  }

  ######################################################################
  # Called when the user places the cursor over a notebook tab.
  proc handle_notebook_motion {W x y} {

    variable tab_tip
    variable tab_close
    variable images

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
    variable files
    variable files_index

    # Get the full pathname to the current file
    set fname [lindex $files [get_file_index $tab] $files_index(fname)]

    # Create the tooltip
    set tab_tip($W) $tab
    tooltip::tooltip $W $fname
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

      if {[set tb [current_tabbar]] ne ""} {
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
  proc insert_tab {index title diff gutters {initial_language ""}} {

    variable widgets
    variable curr_id
    variable language
    variable pw_current
    variable images
    variable case_sensitive

    # Get the unique tab ID
    set id [incr curr_id]

    # Get the current notebook
    set tb [current_tabbar]
    set nb [winfo parent [winfo parent $tb]]

    # Make the tabbar visible and the syntax menubutton enabled
    grid $tb
    $widgets(info_syntax) configure -state normal

    # Create the tab frame
    set tab_frame [ttk::frame $nb.$id]

    # Create the editor pane
    ttk::panedwindow $tab_frame.pw

    # Create tab frame name
    set txt $tab_frame.pw.tf.txt

    # Create the editor frame
    $tab_frame.pw add [ttk::frame $tab_frame.pw.tf]
    ctext $txt -wrap none -undo 1 -autoseparators 1 -insertofftime 0 \
      -highlightcolor yellow -warnwidth [preferences::get Editor/WarningWidth] \
      -maxundo [preferences::get Editor/MaxUndo] \
      -diff_mode $diff \
      -linemap [preferences::get View/ShowLineNumbers] \
      -linemap_mark_command gui::mark_command -linemap_select_bg orange \
      -linemap_relief flat -linemap_minwidth 4 \
      -xscrollcommand "utils::set_xscrollbar $tab_frame.pw.tf.hb" \
      -yscrollcommand "utils::set_yscrollbar $tab_frame.pw.tf.vb"
    ttk::button    $tab_frame.pw.tf.split -style BButton -image $images(split) -command "gui::toggle_split_pane {}"
    ttk::scrollbar $tab_frame.pw.tf.hb    -orient horizontal -command "$txt xview"
    if {$diff} {
      diff::map $tab_frame.pw.tf.vb $txt -command "$txt yview"
      $txt configure -yscrollcommand "$tab_frame.pw.tf.vb set"
    } else {
      ttk::scrollbar $tab_frame.pw.tf.vb -orient vertical   -command "$txt yview"
    }

    # Create the editor font if it does not currently exist
    if {[lsearch [font names] editor_font] == -1} {
      font create editor_font -family [font configure [$txt cget -font] -family] -size [preferences::get Appearance/EditorFontSize]
    }

    $txt configure -font editor_font

    bind Ctext  <<Modified>>                 "gui::text_changed %W"
    bind $txt.t <FocusIn>                    "+gui::set_current_tab_from_txt %W"
    bind $txt.l <ButtonPress-$::right_click> [bind $txt.l <ButtonPress-1>]
    bind $txt.l <ButtonPress-1>              "gui::select_line %W %y"
    bind $txt.l <B1-Motion>                  "gui::select_lines %W %y"
    bind $txt.l <Shift-ButtonPress-1>        "gui::select_lines %W %y"
    bind $txt   <<Selection>>                "gui::selection_changed $txt"
    bind $txt   <ButtonPress-1>              "after idle [list gui::update_position $txt]"
    bind $txt   <B1-Motion>                  "gui::update_position $txt"
    bind $txt   <KeyRelease>                 "gui::update_position $txt"
    bind $txt   <Motion>                     "gui::clear_tab_tooltip $tb"
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

    grid rowconfigure    $tab_frame.pw.tf 1 -weight 1
    grid columnconfigure $tab_frame.pw.tf 0 -weight 1
    grid $tab_frame.pw.tf.txt   -row 0 -column 0 -sticky news -rowspan 2
    if {!$diff} {
      grid $tab_frame.pw.tf.split -row 0 -column 1 -sticky news
    }
    grid $tab_frame.pw.tf.vb    -row 1 -column 1 -sticky ns
    grid $tab_frame.pw.tf.hb    -row 2 -column 0 -sticky ew

    # Create the Vim command bar
    vim::bind_command_entry $txt [entry $tab_frame.ve] {}

    # Create the search bar
    ttk::frame       $tab_frame.sf
    ttk::label       $tab_frame.sf.l1    -text [msgcat::mc "Find:"]
    ttk::entry       $tab_frame.sf.e
    ttk::checkbutton $tab_frame.sf.case  -text "Aa" -variable gui::case_sensitive
    ttk::label       $tab_frame.sf.close -image $images(close)

    tooltip::tooltip $tab_frame.sf.case "Case sensitivity"

    pack $tab_frame.sf.l1    -side left  -padx 2 -pady 2
    pack $tab_frame.sf.e     -side left  -padx 2 -pady 2 -fill x -expand yes
    pack $tab_frame.sf.close -side right -padx 2 -pady 2
    pack $tab_frame.sf.case  -side right -padx 2 -pady 2

    bind $tab_frame.sf.e     <Escape>    "gui::close_search"
    bind $tab_frame.sf.case  <Escape>    "gui::close_search"
    bind $tab_frame.sf.close <Button-1>  "gui::close_search"
    bind $tab_frame.sf.close <Key-space> "gui::close_search"

    # Create the search/replace bar
    ttk::frame       $tab_frame.rf
    ttk::label       $tab_frame.rf.fl    -text [msgcat::mc "Find:"]
    ttk::entry       $tab_frame.rf.fe
    ttk::label       $tab_frame.rf.rl    -text [msgcat::mc "Replace:"]
    ttk::entry       $tab_frame.rf.re
    ttk::checkbutton $tab_frame.rf.case  -text "Aa" -variable gui::case_sensitive
    ttk::label       $tab_frame.rf.glob  -image $images(global) -relief raised
    ttk::label       $tab_frame.rf.close -image $images(close)

    tooltip::tooltip $tab_frame.rf.case "Case sensitivity"
    tooltip::tooltip $tab_frame.rf.glob "Replace globally"

    pack $tab_frame.rf.fl    -side left -padx 2 -pady 2
    pack $tab_frame.rf.fe    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $tab_frame.rf.rl    -side left -padx 2 -pady 2
    pack $tab_frame.rf.re    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $tab_frame.rf.case  -side left -padx 2 -pady 2
    pack $tab_frame.rf.glob  -side left -padx 2 -pady 2
    pack $tab_frame.rf.close -side left -padx 2 -pady 2

    bind $tab_frame.rf.fe    <Return>    "gui::do_search_and_replace {}"
    bind $tab_frame.rf.re    <Return>    "gui::do_search_and_replace {}"
    bind $tab_frame.rf.glob  <Return>    "gui::do_search_and_replace {}"
    bind $tab_frame.rf.fe    <Escape>    "gui::close_search_and_replace"
    bind $tab_frame.rf.re    <Escape>    "gui::close_search_and_replace"
    bind $tab_frame.rf.case  <Escape>    "gui::close_search_and_replace"
    bind $tab_frame.rf.glob  <Button-1>  "gui::toggle_labelbutton %W"
    bind $tab_frame.rf.glob  <Key-space> "gui::toggle_labelbutton %W"
    bind $tab_frame.rf.glob  <Escape>    "gui::close_search_and_replace"
    bind $tab_frame.rf.close <Button-1>  "gui::close_search_and_replace"
    bind $tab_frame.rf.close <Key-space> "gui::close_search_and_replace"

    # Create the diff bar
    if {$diff} {
      diff::create_diff_bar $txt $tab_frame.df
      ttk::separator $tab_frame.sep2 -orient horizontal
    }

    # Create separator between search and information bar
    ttk::separator $tab_frame.sep1 -orient horizontal

    grid rowconfigure    $tab_frame 0 -weight 1
    grid columnconfigure $tab_frame 0 -weight 1
    grid $tab_frame.pw   -row 0 -column 0 -sticky news
    grid $tab_frame.ve   -row 1 -column 0 -sticky ew
    grid $tab_frame.sf   -row 2 -column 0 -sticky ew
    grid $tab_frame.rf   -row 3 -column 0 -sticky ew
    grid $tab_frame.sep1 -row 4 -column 0 -sticky ew
    if {$diff} {
      grid $tab_frame.df   -row 5 -column 0 -sticky ew
      grid $tab_frame.sep2 -row 6 -column 0 -sticky ew
    }

    # Hide the vim command entry, search bar, search/replace bar and search separator
    grid remove $tab_frame.ve
    grid remove $tab_frame.sf
    grid remove $tab_frame.rf
    grid remove $tab_frame.sep1

    # Get the adjusted index
    set adjusted_index [$tb index $index]

    # Add the text bindings
    indent::add_bindings          $txt
    multicursor::add_bindings     $txt
    snippets::add_bindings        $txt
    vim::set_vim_mode             $txt {}
    completer::add_bindings       $txt
    plugins::handle_text_bindings $txt

    # Apply the appropriate syntax highlighting for the given extension
    if {$initial_language eq ""} {
      syntax::initialize_language $txt [syntax::get_default_language $title]
    } else {
      syntax::initialize_language $txt $initial_language
    }

    # Add any gutters
    foreach gutter $gutters {
      $txt gutter create {*}$gutter
    }

    # Add the new tab to the notebook in alphabetical order (if specified) and if
    # the given index is "end"
    if {[preferences::get View/OpenTabsAlphabetically] && ($index eq "end")} {
      set added 0
      foreach t [$tb tabs] {
        if {[string compare " $title" [$tb tab $t -text]] == -1} {
          $tb insert $t $tab_frame -text " $title" -emboss 0
          set added 1
          break
        }
      }
      if {$added == 0} {
        $tb insert end $tab_frame -text " $title" -emboss 0
      }

    # Otherwise, add the tab in the specified location
    } else {
      $tb insert $index $tab_frame -text " $title" -emboss 0
    }

    # Make the new tab the current tab
    set_current_tab $tab_frame

    # Set the current language
    syntax::set_current_language {}

    # Give the text widget the focus
    set_txt_focus $txt

    return $tab_frame

  }

  ######################################################################
  # Adds a peer ctext widget to the current widget in the pane just below
  # the current pane.
  proc show_split_pane {tid} {

    variable images

    # Get the current paned window
    set txt  [current_txt $tid]
    set pw   [winfo parent [winfo parent $txt]]
    set tb   [winfo parent $pw]
    set txt2 $pw.tf2.txt

    # Create the editor frame
    $pw insert 0 [ttk::frame $pw.tf2]
    ctext $txt2 -wrap none -undo 1 -autoseparators 1 -insertofftime 0 -font editor_font \
      -highlightcolor yellow -warnwidth [preferences::get Editor/WarningWidth] \
      -maxundo [preferences::get Editor/MaxUndo] \
      -linemap [preferences::get View/ShowLineNumbers] \
      -linemap_mark_command [ns gui]::mark_command -linemap_select_bg orange -peer $txt \
      -xscrollcommand "utils::set_xscrollbar $pw.tf2.hb" \
      -yscrollcommand "utils::set_yscrollbar $pw.tf2.vb"
    ttk::label     $pw.tf2.split -image $images(close) -anchor center
    ttk::scrollbar $pw.tf2.vb    -orient vertical   -command "$txt2 yview"
    ttk::scrollbar $pw.tf2.hb    -orient horizontal -command "$txt2 xview"

    bind $txt2.t       <FocusIn>                    "+[ns gui]::set_current_tab_from_txt %W"
    bind $txt2.l       <ButtonPress-$::right_click> [bind $txt2.l <ButtonPress-1>]
    bind $txt2.l       <ButtonPress-1>              "[ns gui]::select_line %W %y"
    bind $txt2.l       <B1-Motion>                  "[ns gui]::select_lines %W %y"
    bind $txt2.l       <Shift-ButtonPress-1>        "[ns gui]::select_lines %W %y"
    bind $txt2         <<Selection>>                "[ns gui]::selection_changed $txt2"
    bind $txt2         <ButtonPress-1>              "after idle [list [ns gui]::update_position $txt2]"
    bind $txt2         <B1-Motion>                  "[ns gui]::update_position $txt2"
    bind $txt2         <KeyRelease>                 "[ns gui]::update_position $txt2"
    bind $txt2         <Motion>                     "[ns gui]::clear_tab_tooltip $tb"
    bind $pw.tf2.split <Button-1>                   "[ns gui]::toggle_split_pane {}"

    # Move the all bindtag ahead of the Text bindtag
    set text_index [lsearch [bindtags $txt2.t] Text]
    set all_index  [lsearch [bindtags $txt2.t] all]
    bindtags $txt2.t [lreplace [bindtags $txt2.t] $all_index $all_index]
    bindtags $txt2.t [linsert  [bindtags $txt2.t] $text_index all]

    grid rowconfigure    $pw.tf2 1 -weight 1
    grid columnconfigure $pw.tf2 0 -weight 1
    grid $pw.tf2.txt   -row 0 -column 0 -sticky news -rowspan 2
    grid $pw.tf2.split -row 0 -column 1 -sticky news
    grid $pw.tf2.vb    -row 1 -column 1 -sticky ns
    grid $pw.tf2.hb    -row 2 -column 0 -sticky ew

    # Associate the existing command entry field with this text widget
    [ns vim]::bind_command_entry $txt2 $tb.ve {}

    # Add the text bindings
    [ns indent]::add_bindings          $txt2
    [ns multicursor]::add_bindings     $txt2
    [ns snippets]::add_bindings        $txt2
    [ns vim]::set_vim_mode             $txt2 {}
    [ns completer]::add_bindings       $txt2
    [ns plugins]::handle_text_bindings $txt2

    # Apply the appropriate syntax highlighting for the given extension
    set language [[ns syntax]::get_current_language $txt]
    [ns syntax]::initialize_language $txt2 $language

    # Hide the split pane button in the other text frame
    grid remove $pw.tf.split

    # Set the current language
    [ns syntax]::set_language $language $txt2

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

    # Show the split pane widget in the other text widget frame
    grid $pw.tf.split

    # Set the focus back on the tf text widget
    set_txt_focus $pw.tf.txt

  }

  ######################################################################
  # Handles a change to the current text widget.
  proc text_changed {txt} {

    variable files
    variable files_index
    variable cursor_hist

    if {[$txt edit modified]} {

      # Get the tab path from the text path
      set tab [winfo parent [winfo parent [winfo parent $txt]]]

      # Get the file index for the given text widget
      set file_index [lsearch -index $files_index(tab) $files $tab]

      if {![catch { lindex $files $file_index $files_index(buffer) } rc] && ($rc == 0)} {

        # Save the modified state to the files list
        catch { lset files $file_index $files_index(modified) 1 }

        # Get the current notebook
        set tb [lindex [pane_tb_index_from_tab $tab] 1]

        # Change the look of the tab
        if {[string index [set name [string trimleft [$tb tab $tab -text]]] 0] ne "*"} {
          $tb tab $tab -text " * $name"
          set_title
        }

      }

      # Clear the cursor history
      array unset cursor_hist $txt,*

    }

  }

  ######################################################################
  # Handles a change to the current text widget selection.
  proc selection_changed {txt} {

    # Get the first range of selected text
    if {[set range [$txt tag nextrange sel 1.0]] ne ""} {

      # Get the current search entry field
      set sentry [current_search].e

      # Set the search frame
      $sentry delete 0 end
      $sentry insert end [$txt get {*}$range]

    }

  }

  ######################################################################
  # Selects the given line in the text widget.
  proc select_line {w y} {

    variable line_sel_anchor

    # Get the parent window
    set txt [winfo parent $w]

    # Get the current line from the line sidebar
    set index [$txt index @0,$y]

    # Select the corresponding line in the text widget
    $txt tag remove sel 1.0 end
    $txt tag add sel "$index linestart" "$index lineend"

    # Save the selected line to the anchor
    set line_sel_anchor($w) $index

  }

  ######################################################################
  # Selects all lines between the anchored line and the current line,
  # inclusive.
  proc select_lines {w y} {

    variable line_sel_anchor

    # Get the parent window
    set txt [winfo parent $w]

    # Get the current line from the line sidebar
    set index [$txt index @0,$y]

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
  proc set_current_tab {tab {skip_focus 0} {skip_check 0}} {

    variable widgets
    variable pw_current
    variable tab_current

    # Set the current pane and get the notebook ID
    lassign [pane_tb_index_from_tab $tab] pw_current tb

    # We only need to refresh if the tab was changed.
    if {![info exists tab_current($pw_current)] || ($tab_current($pw_current) ne $tab)} {

      # Set the current tab
      $tb select $tab

      # Set the current tab for the given notebook
      set tab_current($pw_current) $tab

      # Set the current tab
      $tb select $tab

      set tf [winfo parent [winfo parent $tb]].tf

      if {[set slave [pack slaves $tf]] ne ""} {
        pack forget $slave
      }
      pack [$tb select] -in $tf -fill both -expand yes

      # Update the preferences
      preferences::update_prefs

    }

    # Set the text widget
    set txt [last_txt_focus {} $tab]

    # Set the line and row information
    update_position $txt

    # Set the syntax menubutton to the current language
    syntax::update_menubutton $widgets(info_syntax)

    # Update the indentation indicator
    indent::update_menubutton $widgets(info_indent)

    # Set the application title bar
    set_title

    # Check to see if the file has changed
    if {!$skip_check} {
      catch { check_file [current_file] }
    }

    # Finally, set the focus to the text widget
    if {([focus] ne "$txt.t") && !$skip_focus} {
      set_txt_focus $txt
    }

  }

  ######################################################################
  # Sets the current tab information based on the given notebook.
  proc set_current_tab_from_tb {tb {frm ""}} {

    # Get the pane index
    if {[set tab [$tb select]] eq ""} {
      return
    }

    # Set the current tab
    set_current_tab $tab

  }

  ######################################################################
  # Sets the current tab information based on the given text widget.
  proc set_current_tab_from_txt {txt} {

    variable pw_current

    if {[winfo ismapped $txt]} {

      # Get the tab
      set tab [winfo parent [winfo parent [winfo parent [winfo parent $txt]]]]

      # Get the current tab
      set_current_tab $tab 1

      # Handle any on_focusin events
      plugins::handle_on_focusin $tab

    }

  }

  ######################################################################
  # Sets the current tab information based on the given filename.
  proc set_current_tab_from_fname {fname} {

    variable files
    variable files_index

    if {[set index [lsearch -index $files_index(fname) $files $fname]] != -1} {
      set_current_tab [lindex $files $index $files_index(tab)]
    }

  }

  ######################################################################
  # Returns the pathname to the current notebook.
  proc current_tabbar {} {

    variable widgets
    variable pw_current

    if {[llength [$widgets(nb_pw) panes]] == 0} {
      return ""
    } else {
      return "[lindex [$widgets(nb_pw) panes] $pw_current].tbf.tb"
    }

  }

  ######################################################################
  # Returns the current text widget pathname.
  proc current_txt {tid} {

    variable pw_current
    variable tab_current
    variable txt_current

    if {$tid eq ""} {
      if {![info exists tab_current($pw_current)]} {
        return ""
      } elseif {![info exists txt_current($tab_current($pw_current))]} {
        return [get_txt_from_tab $tab_current($pw_current)]
      } else {
        return $txt_current($tab_current($pw_current))
      }
    } else {
      return $tid
    }

  }

  ######################################################################
  # Returns the current search entry pathname.
  proc current_search {} {

    variable pw_current
    variable tab_current

    return "$tab_current($pw_current).sf"

  }

  ######################################################################
  # Gets the current index into the file list based on the current pane
  # and notebook tab.
  proc current_file {} {

    variable pw_current
    variable tab_current

    # Returns the file index
    if {![info exists tab_current($pw_current)]} {
      return -1
    } else {
      return [get_file_index $tab_current($pw_current)]
    }

  }

  ######################################################################
  # Returns the index of the file list that pertains to the given file.
  proc get_file_index {tab} {

    variable files
    variable files_index

    # Look for the file index
    if {[set index [lsearch -index $files_index(tab) $files $tab]] != -1} {
      return $index
    }

    # Throw an exception if we couldn't find the current file
    # (this is considered an unhittable case)
    return -code error [msgcat::mc "Unable to find current file (tab: %s)" $tab]

  }

  ######################################################################
  # Updates the current position information in the information bar based
  # on the current location of the insertion cursor.
  proc update_position {txt} {

    variable widgets

    # Get the current position of the insertion cursor
    lassign [split [$txt index insert] .] line column

    # Update the information widgets
    if {[set vim_mode [vim::get_mode $txt]] ne ""} {
      $widgets(info_state) configure -text [msgcat::mc "%s, Line: %d, Column: %d" $vim_mode $line [expr $column + 1]]
    } else {
      $widgets(info_state) configure -text [msgcat::mc "Line: %d, Column: %d" $line [expr $column + 1]]
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
    set_info_message [msgcat::mc "Total Lines: %d, Total Characters: %d" $lines $chars]

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
      if {![markers::add $txt $tag]} {
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
    markers::delete_by_line $txt $line
    ctext::linemapClearMark $txt $line

  }

  ######################################################################
  # Removes all of the markers from the current editor.
  proc remove_all_markers {tid} {

    # Get the current text widget
    set txt [current_txt $tid]

    foreach name [markers::get_all_names $txt] {
      set line [lindex [split [markers::get_index $txt $name] .] 0]
      markers::delete_by_name $txt $name
      ctext::linemapClearMark $txt $line
    }

  }

  ######################################################################
  # Returns the list of markers in the current text widget.
  proc get_marker_list {tid} {

    # Get the current text widget
    set txt [current_txt $tid]

    # Create a list of marker names and index
    set markers [list]
    foreach name [markers::get_all_names $txt] {
      lappend markers $name [markers::get_index $txt $name]
    }

    return $markers

  }

  ######################################################################
  # Jump to the given position.
  proc jump_to {tid pos} {

    # Get the current text widget
    set txt [current_txt $tid]

    # Set the current insertion marker and make it viewable.
    $txt mark set insert $pos
    $txt see $pos

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
      "\}"    { set index [find_match_brace $txt "\\\{" "\\\}" -backwards] }
      "\{"    { set index [find_match_brace $txt "\\\}" "\\\{" -forwards] }
      "\}"    { set index [find_match_brace $txt "\\\{" "\\\}" -backwards] }
      "\["    { set index [find_match_brace $txt "\\\]" "\\\[" -forwards] }
      "\]"    { set index [find_match_brace $txt "\\\[" "\\\]" -backwards] }
      "\("    { set index [find_match_brace $txt "\\\)" "\\\(" -forwards] }
      "\)"    { set index [find_match_brace $txt "\\\(" "\\\)" -backwards] }
      "\<"    { set index [find_match_brace $txt "\\\>" "\\\<" -forwards] }
      "\>"    { set index [find_match_brace $txt "\\\<" "\\\>" -backwards] }
      "\""    { set index [find_match_quote $txt] }
      default { set index [find_prev_indent $txt] }
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
  proc find_match_brace {txt str1 str2 dir} {

    if {[ctext::isEscaped $txt insert]} {
      return -1
    }

    set search_re "[set str1]|[set str2]"
    set count     1
    set pos       [$txt index [expr {($dir eq "-forwards") ? "insert+1c" : "insert"}]]

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
  proc find_match_quote {txt} {

    set end_quote  [$txt index insert]
    set last_found ""

    if {[ctext::isEscaped $txt $end_quote]} {
      return -1
    }

    if {[lsearch [$txt tag names $end_quote-1c] _dString] == -1} {
    # Figure out if we need to search forwards or backwards
      set dir   "-forwards"
      set start [$txt index "insert+1c"]
    } else {
      set dir   "-backwards"
      set start $end_quote
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
      if {$dir eq "-backwards"} {
        set start $start_quote
      } else {
        set start [$txt index "$start_quote+1c"]
      }

      if {[ctext::isEscaped $txt $last_found]} {
        continue
      }

      return $last_found

    }

  }

  ######################################################################
  # Gets the index of the previous indentation character based on the
  # location of the insert mark.
  proc find_prev_indent {txt} {
    
    set pos        [$txt index insert]
    set last_found ""
    
    lassign [syntax::get_indentation_expressions $txt] indent unindent
    
    if {($indent eq "") || [ctext::isEscaped $txt $pos]} {
      return -1
    }
    
    # Calculate the endpos
    if {[set incomstr [ctext::inCommentString $txt $pos srange]]} {
      set endpos [lindex $srange 0]
    } else {
      set endpos "1.0"
    }
    
    set search_re "([join $indent |])"
    
    while {1} {
      
      if {[set found [$txt search -backwards -regexp -- $search_re $pos $endpos]] eq ""} {
        return -1
      }

      set pos $found

      if {[ctext::isEscaped $txt $found] || (!$incomstr && [ctext::inCommentString $txt $found])} {
        continue
      }
      
      return $found
      
    }
    
  }
  
  ######################################################################
  # Handles a mark request when the line is clicked.
  proc mark_command {win type tag} {

    if {$type eq "marked"} {
      if {![markers::add $win $tag]} {
        ctext::linemapClearMark $win [lindex [split [$win index $tag.first] .] 0]
      }
    } else {
      markers::delete_by_tag $win $tag
    }

  }

  ######################################################################
  # Displays all of the unhidden tabs.
  proc show_tabs {tb side} {

    variable images
    
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
      if {[$tb tab $tab -state] ne "hidden"} {
        $mnu add command -compound left -image $images(mnu,[$tb tab $tab -image]) -label [$tb tab $tab -text] -command "gui::set_current_tab $tab"
      }
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
  # Sets the focus to the given ctext widget.
  proc set_txt_focus {txt} {

    variable txt_current

    # Set the focus
    focus $txt.t

    # Save the last text widget in focus
    set txt_current([winfo parent [winfo parent [winfo parent $txt]]]) $txt

  }

  ######################################################################
  # Returns the path to the ctext widget that last received focus.
  proc last_txt_focus {tid {tab ""}} {

    variable pw_current
    variable tab_current
    variable txt_current

    if {$tid eq ""} {
      if {$tab eq ""} {
        return $txt_current($tab_current($pw_current))
      } elseif {[info exists txt_current($tab)]} {
        return $txt_current($tab)
      } else {
        return [get_txt_from_tab $tab]
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

    # Clean up the text from Vim
    set str [vim::get_cleaned_content $txt]

    if {[preferences::get Editor/RemoveTrailingWhitespace]} {
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
    set diff   [preferences::get Find/JumpDistance]

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
          $txt mark set insert "$cursor linestart"
          $txt see insert
          if {[vim::in_vim_mode $txt.t]} {
            vim::adjust_insert $txt.t
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

    # Get the current text widget
    set txt [current_txt $tid]

    if {[$txt cget -diff_mode] && ![catch { $txt index sel.first } rc]} {
      if {$show} {
        diff::find_current_version $txt [current_filename] [lindex [split $rc .] 0]
      }
      return 1
    }

    return 0

  }

}

