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
  variable session_file     [file join $::tke_home session.tkedat]
  variable lengths          {}
  variable user_exit_status ""
  variable file_locked      0
  variable last_opened      [list]
  variable fif_files        [list]
  
  array set widgets    {}
  array set language   {}
  array set images     {}
  array set tab_tip    {}
  array set redo_count {}

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
  }
  
  #######################
  #  PUBLIC PROCEDURES  #
  #######################
  
  ######################################################################
  # Polls every 10 seconds to see if any of the loaded files have been
  # updated since the last save.
  proc poll {} {

    variable pw_current
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
            if {[lindex $files $i $files_index(modified)]} {
              set answer [tk_messageBox -parent . -icon question -message [msgcat::mc "Reload file?"] \
                -detail $fname -type yesno -default yes]
              if {$answer eq "yes"} {
                update_file $i
              }
            } else {
              update_file $i
            }
            lset files $i $files_index(mtime) $stat(mtime)
          }
        } elseif {$mtime ne ""} {
          set answer [tk_messageBox -parent . -icon question -message [msgcat::mc "Delete tab?"] \
            -detail $fname -type yesno -default yes]
          if {$answer eq "yes"} {
            close_tab [lindex $files $i $files_index(tab)]
          }
        }
      }
    }

    # Check again after 10 seconds
    after 10000 gui::poll

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
  # Create the main GUI interface.
  proc create {} {
  
    variable widgets
    variable images
    
    # Set the application icon photo
    wm iconphoto . [image create photo -file [file join $::tke_dir lib images tke_logo_128.gif]]
    
    # Create images
    set images(lock)     [image create bitmap -file     [file join $::tke_dir lib images lock.bmp] \
                                              -maskfile [file join $::tke_dir lib images lock.bmp] \
                                              -foreground grey10]
    set images(readonly) [image create bitmap -file     [file join $::tke_dir lib images lock.bmp] \
                                              -maskfile [file join $::tke_dir lib images lock.bmp] \
                                              -foreground grey30]
    set images(close)    [image create bitmap -file     [file join $::tke_dir lib images close.bmp] \
                                              -maskfile [file join $::tke_dir lib images close.bmp] \
                                              -foreground grey10]
    set images(logo)     [image create photo  -file     [file join $::tke_dir lib images tke_logo_64.gif]]
    set images(global)   [image create photo  -file     [file join $::tke_dir lib images global.gif]]
    set images(down)     [image create bitmap -file     [file join $::tke_dir lib images down.bmp] \
                                              -maskfile [file join $::tke_dir lib images down.bmp]]
    
    # Create the panedwindow
    set widgets(pw) [ttk::panedwindow .pw -orient horizontal]
    
    # Add the sidebar
    set widgets(sb) [sidebar::create $widgets(pw).sb]
      
    # Create panedwindow (to support split pane view)
    $widgets(pw) add [ttk::frame $widgets(pw).tf]
      
    # Create the notebook panedwindow
    set widgets(nb_pw) [ttk::panedwindow $widgets(pw).tf.nbpw -orient $preferences::prefs(View/PaneOrientation)]
      
    # Add notebook
    add_notebook
    
    # Pack the notebook panedwindow
    pack $widgets(nb_pw) -fill both -expand yes
    
    # Create the find_in_files widget
    set widgets(fif)      [ttk::frame .fif]
    ttk::label $widgets(fif).lf -text "Find: "
    set widgets(fif_find) [ttk::entry $widgets(fif).ef]
    set widgets(fif_case) [ttk::label $widgets(fif).case -text "Aa" -relief raised]
    ttk::label $widgets(fif).li -text "In: "
    set widgets(fif_in)   [tokenentry::tokenentry $widgets(fif).ti -font [$widgets(fif_find) cget -font]]
    ttk::label $widgets(fif).close -image $images(close)
    
    tooltip::tooltip $widgets(fif_case) "Case sensitivity"
    
    bind $widgets(fif_find) <Return> {
      if {([llength [$gui::widgets(fif_in) tokenget]] > 0) && \
          ([$gui::widgets(fif_find) get] ne "")} {
        set gui::user_exit_status 1
      }
    }
    bind $widgets(fif_find) <Escape> "set gui::user_exit_status 0"
    bind [$widgets(fif_in) entrytag] <Return> {
      if {([llength [$gui::widgets(fif_in) tokenget]] > 0) && \
          ([$gui::widgets(fif_in) entryget] eq "") && \
          ([$gui::widgets(fif_find) get] ne "")} {
        set gui::user_exit_status 1
        break
      }
    }
    bind $widgets(fif_in)    <Escape>    "set gui::user_exit_status 0"
    bind $widgets(fif_case)  <Button-1>  "gui::toggle_labelbutton %W"
    bind $widgets(fif_case)  <Key-space> "gui::toggle_labelbutton %W"
    bind $widgets(fif_case)  <Escape>    "set gui::user_exit_status 0"
    bind $widgets(fif).close <Button-1>  "set gui::user_exit_status 0"
    bind $widgets(fif).close <Key-space> "set gui::user_exit_status 0"
      
    grid columnconfigure $widgets(fif) 1 -weight 1
    grid $widgets(fif).lf    -row 0 -column 0 -sticky ew -pady 2
    grid $widgets(fif).ef    -row 0 -column 1 -sticky ew -pady 2
    grid $widgets(fif).case  -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $widgets(fif).close -row 0 -column 3 -sticky news -padx 2 -pady 2
    grid $widgets(fif).li    -row 1 -column 0 -sticky ew -pady 2
    grid $widgets(fif).ti    -row 1 -column 1 -sticky ew -pady 2 -columnspan 2

    # Create the information bar
    set widgets(info)        [ttk::frame .if]
    set widgets(info_label)  [ttk::label .if.l]
    set widgets(info_syntax) [syntax::create_menubutton .if.syn]
    
    $widgets(info_syntax) configure -state disabled
   
    pack .if.l   -side left  -padx 2 -pady 2
    pack .if.syn -side right -padx 2 -pady 2
     
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
      gui::close_current
    }
    $widgets(menu) add command -label [msgcat::mc "Close Other Tab(s)"] -command {
      gui::close_others
    }
    $widgets(menu) add command -label [msgcat::mc "Close All Tabs"] -command {
      gui::close_all
    }
    $widgets(menu) add separator
    $widgets(menu) add checkbutton -label [msgcat::mc "Locked"] -onvalue 1 -offvalue 0 -variable gui::file_locked -command {
      gui::set_current_file_lock $gui::file_locked
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
    change_sidebar_view
    
    # Show the console (if necessary)
    change_console_view
    
    # Show the status bar (if necessary)
    change_status_view

    # If the user attempts to close the window via the window manager, treat
    # it as an exit request from the menu system.
    wm protocol . WM_DELETE_WINDOW {
      menus::exit_command
    }
    
    # Start polling on the files
    poll
  
    # Trace changes to the Appearance/Theme preference variable
    trace variable preferences::prefs(Editor/WarningWidth)        w gui::handle_warning_width_change
    trace variable preferences::prefs(View/HideTabs)              w gui::handle_hide_tabs_change    

  }
  
  ######################################################################
  # Handles any preference changes to the Editor/WarningWidth setting.
  proc handle_warning_width_change {name1 name2 op} {
    
    variable widgets
    
    # Set the warning width to the specified value
    foreach pane [$widgets(nb_pw) panes] {
      foreach tab [$pane tabs] {
        $tab.tf.txt configure -warnwidth $preferences::prefs(Editor/WarningWidth)
      }
    }
    
  }
    
  ######################################################################
  # Handles any changes to the View/HideTabs preference variable.
  proc handle_hide_tabs_change {name1 name2 op} {
    
    variable widgets
    
    # TBD
        
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
  # Sets up the tab popup menu.
  proc setup_tab_popup_menu {} {
  
    variable widgets
    variable files
    variable files_index
    variable file_locked
    
    # Get the current file index
    set file_index [current_file]
    
    # Get the readonly variable
    set readonly [lindex $files $file_index $files_index(readonly)]

    # Set the file_locked variable
    set file_locked [expr $readonly || [lindex $files $file_index $files_index(lock)]]
    
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
    if {$readonly} {
      $widgets(menu) entryconfigure [msgcat::mc "Locked"] -state disabled
    } else {
      $widgets(menu) entryconfigure [msgcat::mc "Locked"] -state normal
    }
  
  }
  
  ######################################################################
  # Shows/Hides the sidebar viewer.
  proc change_sidebar_view {} {
    
    variable widgets
    
    if {$preferences::prefs(View/ShowSidebar)} {
      $widgets(pw) insert 0 $widgets(sb)
    } else {
      catch { $widgets(pw) forget $widgets(sb) }
    }
    
  }
  
  ######################################################################
  # Shows/Hides the console.
  proc change_console_view {} {
    
    catch {
      if {$preferences::prefs(View/ShowConsole)} {
        console show
      } else {
        console hide
      }
    }
    
  }
  
  ######################################################################
  # Shows/Hides the status bar.
  proc change_status_view {} {
    
    variable widgets
    
    catch {
      if {$preferences::prefs(View/ShowStatus)} {
        grid $widgets(info)
      } else {
        grid remove $widgets(info)
      }
    }
    
  }
  
  ######################################################################
  # Changes the pane orientation.
  proc change_pane_orientation {} {
  
    variable widgets
    
    $widgets(nb_pw) configure -orient $preferences::prefs(View/PaneOrientation)
  
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
    
    return [expr {[lsearch -index $files_index(fname) $files $fname] != -1}]
    
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
    
    # Gather the current tab info
    foreach file $files {
    
      set tab [lindex $file $files_index(tab)]
      set txt "$tab.tf.txt" 
      lassign [pane_tb_index_from_tab $tab] pane tb tab_index
      
      set finfo(fname)       [lindex $file $files_index(fname)]
      set finfo(savecommand) [lindex $file $files_index(save_cmd)]
      set finfo(pane)        $pane
      set finfo(tab)         $tab_index
      set finfo(lock)        [lindex $file $files_index(lock)]
      set finfo(readonly)    [lindex $file $files_index(readonly)]
      set finfo(sidebar)     [lindex $file $files_index(sidebar)]
      set finfo(language)    [syntax::get_current_language $txt]
      set finfo(buffer)      [lindex $file $files_index(buffer)]
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
  proc load_session {} {
    
    variable widgets
    variable session_file
    variable last_opened
    variable files
    variable files_index
    variable pw_current
    
    # Read the state file
    if {![catch "tkedat::read $session_file" rc]} {

      array set content $rc
    
      # Put the state information into the rest of the GUI
      wm geometry . $content(Geometry)
      
      # If we are supposed to load the last saved session, do it now
      if {$preferences::prefs(General/LoadLastSession) && \
          ([llength $files] == 1) && \
          ([lindex $files 0 $files_index(fname)] eq "") && \
          [info exists content(FileInfo)]} {
      
        # Set the current working directory to the saved value
        if {[file exists $content(CurrentWorkingDirectory)]} {
          cd $content(CurrentWorkingDirectory)
        }

        # Put the list in order
        set ordered     [lrepeat 2 [lrepeat [llength $content(FileInfo)] ""]]
        set second_pane 0
        set i           0
        foreach finfo_list $content(FileInfo) {
          array set finfo $finfo_list
          lset ordered $finfo(pane) $finfo(tab) $i
          set second_pane [expr $finfo(pane) == 2]
          incr i
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
                  -sidebar $finfo(sidebar)
                if {[syntax::get_current_language [current_txt]] ne $finfo(language)} {
                  syntax::set_language $finfo(language)
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
      
      # Restore the "last_opened" list
      set last_opened $content(LastOpened)
      
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
    
    set last_opened [lrange [concat $fname $last_opened] 0 20]
    
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
  # Returns true if we have only a single tab that has not been modified
  # or named.
  proc untitled_check {} {
    
    variable widgets
    variable files
    variable files_index

    # If we have no more tabs and there is another pane, remove this pane
    return [expr {([llength $files] == 1) && \
                  ([lindex $files 0 $files_index(fname)] eq "") && \
                  ([vim::get_cleaned_content "[lindex [[lindex [$widgets(nb_pw) panes] 0].tbf.tb tabs] 0].tf.txt"] eq "")}]
      
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
    ]
    array set opts $args
    
    # Perform untitled tab check
    if {[untitled_check]} {
      return
    }
    
    # Adjust the index (if necessary)
    set index [adjust_insert_tab_index $index "Untitled"]
    
    # Get the current index
    set w [insert_tab $index [msgcat::mc "Untitled"]]
    
    # Create the file info structure
    set file_info [lrepeat [array size files_index] ""]
    lset file_info $files_index(fname)    ""
    lset file_info $files_index(mtime)    ""
    lset file_info $files_index(save_cmd) $opts(-savecommand)
    lset file_info $files_index(tab)      $w
    lset file_info $files_index(lock)     0
    lset file_info $files_index(readonly) $opts(-readonly)
    lset file_info $files_index(sidebar)  $opts(-sidebar)
    lset file_info $files_index(buffer)   $opts(-buffer)
    lset file_info $files_index(modified) 0
 
    # Add the file information to the files list
    lappend files $file_info

    # Add the file's directory to the sidebar and highlight it
    if {$opts(-sidebar)} {
      sidebar::add_directory [pwd]
    }
        
    # Sets the file lock to the specified value
    set_current_file_lock $opts(-lock)
    
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
    }
    array set opts $args

    # If have a single untitled tab in view, close it before adding the file
    if {[untitled_check]} {
      close_tab $tab_current($pw_current) 0 0
    }
    
    # If the file is already loaded, display the tab
    if {[set file_index [lsearch -index $files_index(fname) $files $fname]] != -1} {
      
      set_current_tab [lindex $files $file_index $files_index(tab)]
      
    # Otherwise, load the file in a new tab
    } else {
    
      # Adjust the index (if necessary)
      set index [adjust_insert_tab_index $index [file tail $fname]]
    
      # Add the tab to the editor frame
      set w [insert_tab $index [file tail $fname]]
      
      # Create the file information
      set file_info [lrepeat [array size files_index] ""]
      lset file_info $files_index(fname)    $fname
      lset file_info $files_index(mtime)    ""
      lset file_info $files_index(save_cmd) $opts(-savecommand)
      lset file_info $files_index(tab)      $w
      lset file_info $files_index(lock)     0
      lset file_info $files_index(readonly) $opts(-readonly)
      lset file_info $files_index(sidebar)  $opts(-sidebar)
      lset file_info $files_index(buffer)   $opts(-buffer)
      lset file_info $files_index(modified) 0

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
        
        # Add the file to the list of recently opened files
        gui::add_to_recently_opened $fname
 
      } else {
 
        lappend files $file_info
 
      }
 
      # Change the tab text
      [current_tabbar] tab $w -text " [file tail $fname]"
      
    }
    
    # Add the file's directory to the sidebar and highlight it
    if {$opts(-sidebar)} {
      sidebar::add_directory [file dirname [file normalize $fname]]
      sidebar::highlight_filename $fname 1
    }
    
    # Sets the file lock to the specified value
    set_current_file_lock $opts(-lock)
    
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

    variable files
    variable files_index

    # Get the file information
    set file_info [lindex $files $file_index]
    
    # Get the current notebook.
    set tab [lindex $file_info $files_index(tab)]

    # Get the text widget at the given index
    set txt "$tab.tf.txt"

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
      $txt edit modified false
      lset files $file_index $files_index(modified) 0
        
      # Set the insertion mark to the first position
      $txt mark set insert $insert_index
      vim::adjust_insert $txt.t

      # Make the insertion mark visible
      $txt see $insert_index
      
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
  proc save_current {{save_as ""}} {
  
    variable files
    variable files_index
    
    # Get the current tabbar
    set tb [current_tabbar]
        
    # Get the current file index
    set file_index [current_file]
    
    # If a save_as name is specified, change the filename
    if {$save_as ne ""} {
      lset files $file_index $files_index(fname) $save_as
    
    # If the current file doesn't have a filename, allow the user to set it
    } elseif {([lindex $files $file_index $files_index(fname)] eq "") || \
               [lindex $files $file_index $files_index(buffer)]} {
      set save_opts [list]
      if {[llength [set extensions [syntax::get_extensions]]] > 0} {
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
    if {[catch "open [lindex $files $file_index $files_index(fname)] w" rc]} {
      tk_messageBox -parent . -title "Error" -type ok -default ok -message "Unable to write file" -detail $rc
      return
    }
    
    # Write the file contents
    puts $rc [vim::get_cleaned_content [current_txt]]
    close $rc
 
    # If the file doesn't have a timestamp, it's a new file so add and highlight it in the sidebar
    if {([lindex $files $file_index $files_index(mtime)] eq "") || ($save_as ne "")} {
    
      # Calculate the normalized filename
      set fname [file normalize [lindex $files $file_index $files_index(fname)]]
      
      # Add the filename to the most recently opened list
      add_to_recently_opened $fname
      
      # Add the file's directory to the sidebar
      sidebar::add_directory [file dirname $fname]
    
      # Highlight the file in the sidebar
      sidebar::highlight_filename [lindex $files $file_index $files_index(fname)] 1
      
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
    [current_txt] edit modified false
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
      if {[lindex $files $i $files_index(modified)] && ![lindex $files $i $files_index(buffer)]} {
        
        set tab  [lindex $files $i $files_index(tab)]
        
        # If the file needs to be saved as a new filename, call the save_current
        # procedure
        if {[lindex $files $i $files_index(fname)] eq ""} {
          
          set_current_tab $tab
          save_current
          
        # Perform a tab-only save
        } else {
          
          # Get the text widget
          set txt "$tab.tf.txt"
          
          # Run the on_save plugins
          plugins::handle_on_save $i
          
          # Save the file contents
          if {[catch "open [lindex $files $i $files_index(fname)] w" rc]} {
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
  proc close_current {{force 0} {exiting 0}} {
  
    variable pw_current
    variable files
    variable files_index
    
    # Get the current file index
    set file_index [current_file]
    
    # If the file needs to be saved, do it now
    if {[lindex $files $file_index $files_index(modified)] && \
        ![lindex $files $file_index $files_index(buffer)] && \
        !$force} {
      set fname [file tail [lindex $files $file_index $files_index(fname)]]
      if {$fname eq ""} {
        set fname "Untitled"
      }
      set msg "[msgcat::mc Save] $fname?"
      if {[set answer [tk_messageBox -default yes -type yesnocancel -message $msg -title [msgcat::mc "Save request"]]] eq "yes"} {
        save_current
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
    
    # Get the indexed text widget 
    set txt "$tab.tf.txt"
    
    # Get the file index
    set index [get_file_index $tab]

    # Unhighlight the file in the file browser
    sidebar::highlight_filename [lindex $files $index $files_index(fname)] 0
    
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
      $widgets(nb_pw) forget $pane
      set pw_current 0
    }
    
    # Add a new file if we have no more tabs, we are the only pane, and the preference
    # setting is to not close after the last tab is closed.
    if {([llength [$w tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] == 1)} {
      if {$preferences::prefs(General/ExitOnLastClose)} {
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
    
    # Get the indexed text widget 
    set txt "$tab.tf.txt"
    
    # Get the file index
    set index [get_file_index $tab]

    # Unhighlight the file in the file browser
    sidebar::highlight_filename [lindex $files $index $files_index(fname)] 0
    
    # Run the close event for this file
    plugins::handle_on_close $index
    
    # Delete the file from files
    set files [lreplace $files $index $index]
    
    # Remove the tab from the tabbar
    $tb delete $tab_index

    # Delete the text frame
    catch { pack forget $tab }
    
    # Display the current pane (if one exists)
    if {[set tab [$tb select]] ne ""} {
      set_current_tab $tab
    }

    # If we have no more tabs and there is another pane, remove this pane
    if {([llength [$tb tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] > 1)} {
      $widgets(nb_pw) forget $pane
      set pw_current 0
    }
    
    # Add a new file if we have no more tabs, we are the only pane, and the preference
    # setting is to not close after the last tab is closed.
    if {([llength [$tb tabs]] == 0) && ([llength [$widgets(nb_pw) panes]] == 1) && !$exiting} {
      if {$preferences::prefs(General/ExitOnLastClose)} {
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
          set_current_tab $tab
          close_current
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
        set_current_tab $tab
        close_current 0 $exiting
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
  # Closes all buffers.
  proc close_buffers {} {
    
    variable files
    variable files_index
    
    foreach index [lsearch -all -index $files_index(buffer) $files 1] {
      close_tab [lindex $files $index $files_index(tab)] 1
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
    
    # Get the title, text and language from the current text widget
    set txt      [current_txt]
    set file     [lindex $files [current_file]]
    if {[set fname [current_filename]] eq ""} {
      set fname [msgcat::mc "Untitled"]
    }
    set content  [$txt get 1.0 end-1c]
    set insert   [$txt index insert]
    set select   [$txt tag ranges sel]
    set modified [lindex $file $files_index(modified)]
    set language [syntax::get_current_language $txt]
    
    # Delete the current tab
    close_current 1

    # Get the name of the other pane if it exists
    if {[llength [$widgets(nb_pw) panes]] == 2} {
      set pw_current [expr $pw_current ^ 1]
    }

    # Adjust the index (if necessary)
    set index [adjust_insert_tab_index end [file tail $fname]]
    
    # Create a new tab
    set w [insert_tab $index [file tail $fname] $language]
        
    # Update the file components to include position change information
    lset file $files_index(tab)      $w
    lset file $files_index(modified) 0
    lappend files $file
    
    # Add the text, insertion marker and selection
    set txt [current_txt]
    $txt insert end $content
    $txt mark set insert $insert
    
    # Perform an insertion adjust, if necessary
    vim::adjust_insert $txt.t
        
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
    sidebar::highlight_filename $fname 1
    
  }
  
  ######################################################################
  # Performs an undo of the current tab.
  proc undo {} {
  
    variable redo_count
    
    # Get the current textbox
    set txt [current_txt]
    
    # Perform the undo operation
    catch { $txt edit undo }
    
    # Increment the redo stack count
    incr redo_count($txt)
  
  }
  
  ######################################################################
  # Returns true if there is something in the undo buffer.
  proc undoable {} {
    
    variable files
    variable files_index
    
    if {[set index [current_file]] != -1} {
      return [lindex $files $index $files_index(modified)]
    } else {
      return 0
    }
    
  }
  
  ######################################################################
  # This procedure performs an redo operation.
  proc redo {} {
  
    # Get the current textbox
    set txt [current_txt]
    
    # Perform the redo operation
    catch { $txt edit redo }
    
  }
  
  ######################################################################
  # Returns true if there is something in the redo buffer.
  proc redoable {} {
    
    variable redo_count
    
    if {([set txt [current_txt]] ne "") && \
        [info exists redo_count($txt)] && \
        ($redo_count($txt) > 0)} {
      return 1
    } else {
      return 0
    }
    
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
  # This procedure performs a text selection paste operation.
  proc paste {} {
  
    # Perform the paste
    [current_txt] paste
 
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
      paste
  
      # Have the indent namespace format the clipboard contents
      indent::format_text [current_txt].t $insertpos "$insertpos+${cliplen}c"
      
    }
    
  }
  
  ######################################################################
  # Returns true if there is something in the paste buffer.
  proc pastable {} {
    
    return [expr {![catch {clipboard get} contents] && ($contents ne "")}]
    
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
    
    variable pw_current
    variable tab_current
    
    # Get the current text frame
    set tab $tab_current($pw_current)
    
    # Update the search binding
    bind $tab.sf.e <Return> "gui::search_start $dir"
 
    # Display the search bar and separator
    grid $tab.sf
    grid $tab.sep
    
    # Clear the search entry
    $tab.sf.e delete 0 end
    
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
    grid remove $tab.sep
    
    # Put the focus on the text widget
    focus $tab.tf.txt.t
     
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
    grid $tab.sep

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
    grid remove $tab.sep

    # Put the focus on the text widget
    focus $tab.tf.txt.t

  }

  ######################################################################
  # Starts a text search
  proc search_start {{dir "next"}} {

    # If the user has specified a new search value, find all occurrences
    if {[set str [[current_search].e get]] ne ""} {
      
      # Escape any parenthesis in the regular expression
      set str [string map {{(} {\(} {)} {\)}} $str]
      
      # Test the regular expression, if it is invalid, let the user know
      if {[catch { regexp $str "" } rc]} {
        after 100 [list gui::set_info_message $rc]
        return
      }
    
      # Get the current text widget
      set txt [current_txt]
      
      # Gather any search options
      set search_opts [list]
      if {[[current_search].case cget -relief] eq "raised"} {
        lappend search_opts -nocase
      }

      # Clear the search highlight class
      catch { ctext::deleteHighlightClass $txt search }

      # Create a highlight class for the given search string
      ctext::addSearchClassForRegexp $txt search black yellow $str $search_opts
      
      # Make the search tag lower in priority than the selection tag
      # but higher in priority than the warnWidth tag
      $txt tag lower _search sel
      $txt tag raise _search warnWidth

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
    
    variable search_index
 
    # Get the current text widget
    set txt [current_txt]
    
    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }
    
    # Search the text widget from the current insertion cursor forward.
    lassign [$txt tag nextrange _search "insert+1c"] startpos endpos

    # We need to wrap on the search item
    if {$startpos eq ""} {
      lassign [$txt tag nextrange _search 1.0] startpos endpos
    }

    # Select the next match
    if {$startpos ne ""} {
      if {![vim::in_vim_mode $txt.t]} {
        $txt tag add sel $startpos $endpos
      }
      $txt mark set insert $startpos
      $txt see insert
    }
    
    # Closes the search interface
    close_search
    
  }
  
  ######################################################################
  # Searches for the previous occurrence of the search item.
  proc search_prev {app} {
    
    # Get the current text widget
    set txt [current_txt]
    
    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }
   
    # Search the text widget from the current insertion cursor forward.
    lassign [$txt tag prevrange _search insert] startpos endpos

    # We need to wrap on the search item
    if {$startpos eq ""} {
      lassign [$txt tag prevrange _search end] startpos endpos
    }

    # Select the next match
    if {$startpos ne ""} {
      if {![vim::in_vim_mode $txt.t]} {
        $txt tag add sel $startpos $endpos
      }
      $txt mark set insert $startpos
      $txt see insert
    }

    # Close the search interface
    close_search
    
  }
  
  ######################################################################
  # Searches for all of the occurrences and selects them all.
  proc search_all {} {
    
    # Get the current text widget
    set txt [current_txt]
    
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
  proc do_search_and_replace {} {

    variable pw_current
    variable tab_current

    # Get the current tab frame
    set tab $tab_current($pw_current)

    # Perform the search and replace
    do_raw_search_and_replace 1.0 end [$tab.rf.fe get] [$tab.rf.re get] \
      [expr {[$tab.rf.case cget -relief] eq "raised"}] \
      [expr {[$tab.rf.glob cget -relief] eq "sunken"}]

    # Close the search and replace bar
    close_search_and_replace

  }

  ######################################################################
  # Performs a search and replace given the expression, 
  proc do_raw_search_and_replace {sline eline search replace ignore_case all} {

    # Get the current text widget
    set txt [current_txt]

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
    $txt replace $sline $eline [regsub -all {*}$rs_args $search [$txt get $sline "$eline-1c"] $replace]
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
  # Sets the file lock to the specified value for the current file.
  proc set_current_file_lock {lock} {
  
    variable files
    variable files_index
    variable images
    
    # Get the current file index
    set file_index [current_file]
    
    # Set the current lock status
    lset files $file_index $files_index(lock) $lock 
    
    # Change the state of the text widget to match the lock value
    if {[lindex $files $file_index $files_index(readonly)]} {
      [current_tabbar] tab current -compound left -image $images(readonly)
      [current_txt]    configure -state disabled
    } elseif {$lock} {
      [current_tabbar] tab current -compound left -image $images(lock)
      [current_txt]    configure -state disabled
    } else {
      [current_tabbar] tab current -image ""
      [current_txt]    configure -state normal
    }
    
    return 1
  
  }
  
  ######################################################################
  # Sets the current information message to the given string.
  proc set_info_message {msg} {
  
    variable widgets
    
    if {[info exists widgets(info_label)]} {
      $widgets(info_label) configure -text $msg
    } else {
      puts $msg
    }
    
  }
  
  ######################################################################
  # Gets user input from the interface in a generic way.
  proc user_response_get {msg pvar {allow_vars 1}} {
    
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
    if {![info exists files_index($attr)]} {
      return -code error [msgcat::mc "File attribute (%s) does not exist" $attr]
    }
    
    return [lindex $files $index $files_index($attr)]
    
  }
  
  ######################################################################
  # Retrieves the "find in file" inputs from the user.
  proc fif_get_input {prsp_list} {
    
    variable widgets
    variable fif_files
    
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
    if {[$widgets(fif_case) cget -relief] eq "raised"} {
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
  
    toplevel     .aboutwin
    wm title     .aboutwin ""
    wm transient .aboutwin .
    wm resizable .aboutwin 0 0
  
    ttk::label .aboutwin.logo -compound left -image $images(logo) -text " tke" \
      -font [font create -family Helvetica -size 30 -weight bold]
  
    ttk::frame .aboutwin.if
    ttk::label .aboutwin.if.l0 -text [msgcat::mc "Developer:"]
    ttk::label .aboutwin.if.v0 -text "Trevor Williams"
    ttk::label .aboutwin.if.l1 -text [msgcat::mc "Email:"]
    ttk::label .aboutwin.if.v1 -text "phase1geo@gmail.com"
    ttk::label .aboutwin.if.l2 -text [msgcat::mc "Version:"]
    ttk::label .aboutwin.if.v2 -text "$::version_major.$::version_minor ($::version_hgid)"
  
    grid .aboutwin.if.l0 -row 0 -column 0 -sticky news
    grid .aboutwin.if.v0 -row 0 -column 1 -sticky news
    grid .aboutwin.if.l1 -row 1 -column 0 -sticky news
    grid .aboutwin.if.v1 -row 1 -column 1 -sticky news
    grid .aboutwin.if.l2 -row 2 -column 0 -sticky news
    grid .aboutwin.if.v2 -row 2 -column 1 -sticky news
  
    ttk::label .aboutwin.copyright -text [msgcat::mc "Copyright %d" 2013]
  
    pack .aboutwin.logo      -padx 2 -pady 8 -anchor w
    pack .aboutwin.if        -padx 2 -pady 2
    pack .aboutwin.copyright -padx 2 -pady 8
    
  }
  
  ######################################################################
  # Displays the number insertion dialog box if we are currently in
  # multicursor mode.
  proc insert_numbers {txt} {
    
    if {[multicursor::enabled $txt]} {
      
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
    
    # Add the tabbar frame
    ttk::frame $nb.tbf
    tabbar::tabbar $nb.tbf.tb -command "gui::set_current_tab_from_tb" -closecommand "gui::close_tab_by_tabbar"
    ttk::label $nb.tbf.extra -image $images(down) -padding {4 4 4 4}
    
    grid rowconfigure    $nb.tbf 0 -weight 1
    grid columnconfigure $nb.tbf 0 -weight 1
    grid $nb.tbf.tb    -row 0 -column 0 -sticky news
    grid $nb.tbf.extra -row 0 -column 1 -sticky news    
    grid remove $nb.tbf.tb
    grid remove $nb.tbf.extra

    bind $nb.tbf.extra <Button-1> "gui::show_tabs $nb"

    # Create popup menu for extra tabs
    menu $nb.tbf.extra.mnu -tearoff 0
    
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
    bind [$nb.tbf.tb btag] <ButtonRelease-$::right_click> {
      set gui::pw_current [lsearch [$gui::widgets(nb_pw) panes] [winfo parent [winfo parent [winfo parent %W]]]]
      if {![catch "[winfo parent %W] select @%x,%y"]} {
        focus [gui::current_txt].t
      }
    }
    
    bind $nb.tbf.tb <<TabbarScrollEnabled>>  "grid $nb.tbf.extra"
    bind $nb.tbf.tb <<TabbarScrollDisabled>> "grid remove $nb.tbf.extra"
    
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
    
    if {$preferences::prefs(View/OpenTabsAlphabetically) && ($index eq "end")} {
      
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
  proc insert_tab {index title {initial_language ""}} {
  
    variable widgets
    variable curr_id
    variable language
    variable pw_current
    variable images
        
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
    
    # Create the editor frame
    ttk::frame $tab_frame.tf
    ctext $tab_frame.tf.txt -wrap none -undo 1 -autoseparators 1 -insertofftime 0 \
      -highlightcolor yellow -warnwidth $preferences::prefs(Editor/WarningWidth) \
      -linemap_mark_command gui::mark_command -linemap_select_bg orange \
      -xscrollcommand "utils::set_xscrollbar $tab_frame.tf.hb" \
      -yscrollcommand "utils::set_yscrollbar $tab_frame.tf.vb"
    ttk::scrollbar $tab_frame.tf.vb -orient vertical   -command "$tab_frame.tf.txt yview"
    ttk::scrollbar $tab_frame.tf.hb -orient horizontal -command "$tab_frame.tf.txt xview"
    
    bind Ctext               <<Modified>>    "gui::text_changed %W"
    bind $tab_frame.tf.txt.t <FocusIn>       "gui::set_current_tab_from_txt %W"
    bind $tab_frame.tf.txt   <<Selection>>   "gui::selection_changed %W"
    bind $tab_frame.tf.txt   <ButtonPress-1> "after idle [list gui::update_position $tab_frame]"
    bind $tab_frame.tf.txt   <B1-Motion>     "gui::update_position $tab_frame"
    bind $tab_frame.tf.txt   <KeyRelease>    "gui::update_position $tab_frame"
    bind $tab_frame.tf.txt   <Motion>        "gui::clear_tab_tooltip $tb"
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
    ttk::label $tab_frame.sf.l1    -text [msgcat::mc "Find:"]
    ttk::entry $tab_frame.sf.e
    ttk::label $tab_frame.sf.case  -text "Aa" -relief raised
    ttk::label $tab_frame.sf.close -image $images(close)
    
    tooltip::tooltip $tab_frame.sf.case "Case sensitivity"
    
    pack $tab_frame.sf.l1    -side left  -padx 2 -pady 2
    pack $tab_frame.sf.e     -side left  -padx 2 -pady 2 -fill x -expand yes
    pack $tab_frame.sf.close -side right -padx 2 -pady 2
    pack $tab_frame.sf.case  -side right -padx 2 -pady 2
    
    bind $tab_frame.sf.e     <Escape>    "gui::close_search"
    bind $tab_frame.sf.case  <Button-1>  "gui::toggle_labelbutton %W"
    bind $tab_frame.sf.case  <Key-space> "gui::toggle_labelbutton %W"
    bind $tab_frame.sf.case  <Escape>    "gui::close_search"
    bind $tab_frame.sf.close <Button-1>  "gui::close_search"
    bind $tab_frame.sf.close <Key-space> "gui::close_search"
 
    # Create the search/replace bar
    ttk::frame $tab_frame.rf
    ttk::label $tab_frame.rf.fl    -text [msgcat::mc "Find:"]
    ttk::entry $tab_frame.rf.fe
    ttk::label $tab_frame.rf.rl    -text [msgcat::mc "Replace:"]
    ttk::entry $tab_frame.rf.re
    ttk::label $tab_frame.rf.case  -text "Aa" -relief raised
    ttk::label $tab_frame.rf.glob  -image $images(global) -relief raised
    ttk::label $tab_frame.rf.close -image $images(close)
    
    tooltip::tooltip $tab_frame.rf.case "Case sensitivity"
    tooltip::tooltip $tab_frame.rf.glob "Replace globally"
 
    pack $tab_frame.rf.fl    -side left -padx 2 -pady 2
    pack $tab_frame.rf.fe    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $tab_frame.rf.rl    -side left -padx 2 -pady 2
    pack $tab_frame.rf.re    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $tab_frame.rf.case  -side left -padx 2 -pady 2
    pack $tab_frame.rf.glob  -side left -padx 2 -pady 2
    pack $tab_frame.rf.close -side left -padx 2 -pady 2
 
    bind $tab_frame.rf.fe    <Return>    "gui::do_search_and_replace"
    bind $tab_frame.rf.re    <Return>    "gui::do_search_and_replace"
    bind $tab_frame.rf.glob  <Return>    "gui::do_search_and_replace"
    bind $tab_frame.rf.fe    <Escape>    "gui::close_search_and_replace"
    bind $tab_frame.rf.re    <Escape>    "gui::close_search_and_replace"
    bind $tab_frame.rf.case  <Button-1>  "gui::toggle_labelbutton %W"
    bind $tab_frame.rf.case  <Key-space> "gui::toggle_labelbutton %W"
    bind $tab_frame.rf.case  <Escape>    "gui::close_search_and_replace"
    bind $tab_frame.rf.glob  <Button-1>  "gui::toggle_labelbutton %W"
    bind $tab_frame.rf.glob  <Key-space> "gui::toggle_labelbutton %W"
    bind $tab_frame.rf.glob  <Escape>    "gui::close_search_and_replace"
    bind $tab_frame.rf.close <Button-1>  "gui::close_search_and_replace"
    bind $tab_frame.rf.close <Key-space> "gui::close_search_and_replace"
    
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
    set adjusted_index [$tb index $index]
    
    # Add the text bindings
    indent::add_bindings      $tab_frame.tf.txt
    multicursor::add_bindings $tab_frame.tf.txt
    snippets::add_bindings    $tab_frame.tf.txt
    vim::set_vim_mode         $tab_frame.tf.txt
        
    # Apply the appropriate syntax highlighting for the given extension
    if {$initial_language eq ""} {
      syntax::initialize_language $tab_frame.tf.txt [syntax::get_default_language $title]
    } else {
      syntax::initialize_language $tab_frame.tf.txt $initial_language
    }

    # Add the new tab to the notebook in alphabetical order (if specified) and if
    # the given index is "end"
    if {$preferences::prefs(View/OpenTabsAlphabetically) && ($index eq "end")} {
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
    syntax::set_current_language

    # Give the text widget the focus
    focus $tab_frame.tf.txt.t
    
    return $tab_frame
    
  }
 
  ######################################################################
  # Handles a change to the current text widget.
  proc text_changed {txt} {
  
    variable files
    variable files_index
    variable redo_count
        
    if {[$txt edit modified]} {
      
      # Get the tab path from the text path
      set tab [winfo parent [winfo parent $txt]]
      
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
      
      # Clear the redo_count value
      set redo_count($txt) 0
      
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
  # Make the specified tab the current tab.
  proc set_current_tab {tab {skip_focus 0}} {

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
      
    }
    
    # Set the text widget
    set txt "$tab.tf.txt"
    
    # Set the line and row information
    lassign [split [$txt index insert] .] row col
    $widgets(info_label) configure -text [msgcat::mc "Line: %d, Column: %d" $row $col]
    
    # Set the syntax menubutton to the current language
    syntax::update_menubutton $widgets(info_syntax)
    
    # Set the application title bar
    set_title

    # Finally, set the focus to the text widget
    if {([focus] ne "$txt.t") && !$skip_focus} {
      focus $txt.t       
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
      set tab [winfo parent [winfo parent [winfo parent $txt]]]
    
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
  proc current_txt {} {
  
    variable pw_current
    variable tab_current

    if {![info exists tab_current($pw_current)]} {
      return ""
    } else {
      return "$tab_current($pw_current).tf.txt"
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
  proc update_position {w} {
  
    variable widgets
    
    # Get the current position of the insertion cursor
    lassign [split [$w.tf.txt index insert] .] line column
    
    # Update the information widgets
    $widgets(info_label) configure -text [msgcat::mc "Line: %d, Column: %d" $line [expr $column + 1]]
  
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
  # Returns the list of markers in the current text widget.
  proc get_marker_list {} {
    
    # Get the current text widget
    set txt [current_txt]
    
    # Create a list of marker names and index
    set markers [list]
    foreach name [markers::get_all_names $txt] {
      lappend markers $name [markers::get_index $txt $name]
    }
    
    return $markers
    
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
  proc show_tabs {nb} {

    set tb    $nb.tbf.tb
    set extra $nb.tbf.extra
    set mnu   $extra.mnu

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
        $mnu add command -label [$tb tab $tab -text] -command "gui::set_current_tab $tab"
      } 
      incr i
    }

    # Display the menu
    tk_popup $mnu [expr ([winfo rootx $extra] + [winfo reqwidth $extra]) - [winfo reqwidth $mnu]] \
                  [expr [winfo rooty $extra] + [winfo reqheight $extra]]

  }

}
 
