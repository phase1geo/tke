# Name:    menus.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace containing menu functionality

namespace eval menus {

  variable profile_report [file join $::tke_home profiling_report.log]
  
  array set profiling_info {}
  
  #######################
  #  PUBLIC PROCEDURES  #
  #######################
  
  ######################################################################
  # Creates the main menu.
  proc create {} {
  
    # Load the menu bindings
    bindings::load
  
    set mb [menu .menubar -tearoff false]
    . configure -menu $mb
  
    # Add the file menu
    $mb add cascade -label [msgcat::mc "File"] -menu [menu $mb.file -tearoff false -postcommand "menus::file_posting $mb.file"] 
    add_file $mb.file
    
    # Add the edit menu
    $mb add cascade -label [msgcat::mc "Edit"] -menu [menu $mb.edit -tearoff false]
    add_edit $mb.edit
    
    # Add the find menu
    $mb add cascade -label [msgcat::mc "Find"] -menu [menu $mb.find -tearoff false]
    add_find $mb.find

    # Add the text menu
    $mb add cascade -label [msgcat::mc "Text"] -menu [menu $mb.text -tearoff false -postcommand "menus::text_posting $mb.text"]
    add_text $mb.text
    
    # Add the view menu
    $mb add cascade -label [msgcat::mc "View"] -menu [menu $mb.view -tearoff false]
    add_view $mb.view
      
    # Add the tools menu
    $mb add cascade -label [msgcat::mc "Tools"] -menu [menu $mb.tools -tearoff false -postcommand "menus::tools_posting $mb.tools"]
    add_tools $mb.tools
    
    # Add the plugins menu
    $mb add cascade -label [msgcat::mc "Plugins"] -menu [menu $mb.plugins -tearoff false]
    add_plugins $mb.plugins
    
    # Add the help menu
    $mb add cascade -label [msgcat::mc "Help"] -menu [menu $mb.help -tearoff false]
    add_help $mb.help

    # If we are running on Mac OS X, add the window menu with the windowlist package
    if {[tk windowingsystem] eq "aqua"} {

      # Add the window menu with the windowlist package
      windowlist::windowMenu $mb

      # Add the "About Tke" menu in the application menu
      set appl [menu $mb.apple -tearoff false]
      $mb add cascade -menu $appl
      $appl add command -label [msgcat::mc "About Tke"] -command gui::show_about
      $appl add separator

    }

  }
  
  ########################
  #  PRIVATE PROCEDURES  #
  ########################
  
  ######################################################################
  # Adds the file menu.
  proc add_file {mb} {
  
    $mb delete 0 end
  
    $mb add command -label [msgcat::mc "New"] -underline 0 -command "menus::new_command"
    launcher::register [msgcat::mc "Menu: New file"] menus::new_command
    
    $mb add command -label [msgcat::mc "Open File..."] -underline 0 -command "menus::open_command"
    launcher::register [msgcat::mc "Menu: Open file"] menus::open_command
    
    $mb add command -label [msgcat::mc "Open Directory..."] -underline 5 -command "menus::open_dir_command"
    launcher::register [msgcat::mc "Menu: Open directory"] menus::open_dir_command
    
    $mb add cascade -label [msgcat::mc "Open Recent"] -menu [menu $mb.recent -tearoff false -postcommand "menus::file_recent_posting $mb.recent"]
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Save"] -underline 0 -command "menus::save_command"
    launcher::register [msgcat::mc "Menu: Save file"] menus::save_command
    
    $mb add command -label [msgcat::mc "Save As..."] -underline 5 -command "menus::save_as_command"
    launcher::register [msgcat::mc "Menu: Save file as"] menus::save_as_command
    
    $mb add command -label [msgcat::mc "Save All"] -underline 6 -command "gui::save_all"
    launcher::register [msgcat::mc "Menu: Save all files"] gui::save_all
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Lock"] -underline 0 -command "menus::lock_command $mb"
    launcher::register [msgcat::mc "Menu: Lock file"] "menus::lock_command $mb"
    launcher::register [msgcat::mc "Menu: Unlock file"] "menus::unlock_command $mb"
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Close"] -underline 0 -command "menus::close_command"
    launcher::register [msgcat::mc "Menu: Close current tab"] menus::close_command
    
    $mb add command -label [msgcat::mc "Close All"] -underline 6 -command "menus::close_all_command"
    launcher::register [msgcat::mc "Menu: Close all tabs"] menus::close_all_command

    # Only add the quit menu to File if we are not running in aqua
    if {[tk windowingsystem] ne "aqua"} {
      $mb add separator
      $mb add command -label [msgcat::mc "Quit"] -underline 0 -command "menus::exit_command"
    }
    launcher::register [msgcat::mc "Menu: Quit application"] menus::exit_command

    # Apply the menu settings for the current menu
    bindings::apply $mb
  
  }
  
  ######################################################################
  # Called prior to the file menu posting.
  proc file_posting {mb} {
  
    # Get the current readonly status
    if {[set file_index [gui::current_file]] != -1} {

      set readonly [gui::get_file_info $file_index readonly]
    
      # Get the current file lock status
      set file_lock [expr $readonly || [gui::get_file_info [gui::current_file] lock]]
    
      # Configure the Lock/Unlock menu item    
      if {$file_lock && ![catch "$mb index Lock" index]} {
        $mb entryconfigure $index -label [msgcat::mc "Unlock"] -state normal -command "menus::unlock_command $mb"
        if {$readonly} {
          $mb entryconfigure $index -state disabled
        }
      } elseif {!$file_lock && ![catch "$mb index Unlock" index]} {
        $mb entryconfigure $index -label [msgcat::mc "Lock"] -state normal -command "menus::lock_command $mb"
      }

      # Make sure that the file-specific items are enabled
      $mb entryconfigure [msgcat::mc "Save"]       -state normal
      $mb entryconfigure [msgcat::mc "Save As..."] -state normal
      $mb entryconfigure [msgcat::mc "Save All"]   -state normal
      $mb entryconfigure [msgcat::mc "Close"]      -state normal
      $mb entryconfigure [msgcat::mc "Close All"]  -state normal

    } else {

      # Disable file menu items associated with current tab (since one doesn't currently exist)
      $mb entryconfigure [msgcat::mc "Save"]       -state disabled
      $mb entryconfigure [msgcat::mc "Save As..."] -state disabled
      $mb entryconfigure [msgcat::mc "Save All"]   -state disabled
      $mb entryconfigure [msgcat::mc "Lock"]       -state disabled
      $mb entryconfigure [msgcat::mc "Close"]      -state disabled
      $mb entryconfigure [msgcat::mc "Close All"]  -state disabled

    }
    
    # Configure the Open Recent menu
    if {($preferences::prefs(View/ShowRecentlyOpened) == 0) || ([llength [gui::get_last_opened]] == 0)} {
      $mb entryconfigure [msgcat::mc "Open Recent"] -state disabled
    } else {
      $mb entryconfigure [msgcat::mc "Open Recent"] -state normal
    }

  }
  
  ######################################################################
  # Sets up the "Open Recent" menu item prior to it being posted.
  proc file_recent_posting {mb} {
  
    # Clear the menu
    $mb delete 0 end
    
    # Populate the menu with the filenames and a "Clear All" menu option
    foreach fname [lrange [gui::get_last_opened] 0 [expr $preferences::prefs(View/ShowRecentlyOpened) - 1]] {
      $mb add command -label [file tail $fname] -command "gui::add_file end $fname"
    }
    $mb add separator
    $mb add command -label [msgcat::mc "Clear All"] -command "gui::clear_last_opened"
    
  }
  
  ######################################################################
  # Called prior to the text menu posting.
  proc text_posting {mb} {
    
    if {[multicursor::enabled [gui::current_txt]]} {
      $mb entryconfigure [msgcat::mc "Align cursors"]      -state normal
      $mb entryconfigure [msgcat::mc "Insert enumeration"] -state normal
    } else {
      $mb entryconfigure [msgcat::mc "Align cursors"]      -state disabled
      $mb entryconfigure [msgcat::mc "Insert enumeration"] -state disabled
    }
    
  }
  
  ######################################################################
  # Called prior to the tools menu posting.
  proc tools_posting {mb} {
    
    variable profile_report
    
    if {[::tke_development]} {
      if {[file exists $profile_report]} {
        $mb entryconfigure [msgcat::mc "Show*Profiling*"] -state normal
      } else {
        $mb entryconfigure [msgcat::mc "Show*Profiling*"] -state disabled
      }
    }
    
  }
  
  ######################################################################
  # Implements the "create new file" command.
  proc new_command {} {
  
    gui::add_new_file end
  
  }
  
  ######################################################################
  # Opens a new file and adds a new tab for the file.
  proc open_command {} {
    
    # Get the directory of the current file
    set dirname [file dirname [gui::current_filename]]
    
    if {[set ofiles [tk_getOpenFile -parent . -initialdir $dirname -filetypes [syntax::get_filetypes] -defaultextension .tcl -multiple 1]] ne ""} {
      foreach ofile $ofiles {
        gui::add_file end $ofile
      }
    }
  
  }
  
  ######################################################################
  # Opens a directory in the sidebar.
  proc open_dir_command {} {
    
    # Get the directory of the current file
    set dirname [file dirname [gui::current_filename]]
    
    if {[set odir [tk_chooseDirectory -parent . -initialdir $dirname -mustexist 1]] ne ""} {
      sidebar::add_directory $odir
    }
    
  }
  
  ######################################################################
  # Saves the current tab file.
  proc save_command {} {
  
    if {[set sfile [gui::current_filename]] eq ""} {
      save_as_command
    } else {
      gui::save_current $sfile
    }
  
  }
  
  ######################################################################
  # Saves the current tab file as a new filename.
  proc save_as_command {} {
    
    # Get the directory of the current file
    set dirname [file dirname [gui::current_filename]]
  
    # Get some of the save options
    set save_opts [list]
    if {[llength [set extensions [syntax::get_extensions]]] > 0} {
      lappend save_opts -defaultextension [lindex $extensions 0]
    }
    
    if {[set sfile [tk_getSaveFile {*}$save_opts -title [msgcat::mc "Save As"] -parent . -initialdir $dirname]] ne ""} {
      gui::save_current $sfile
    }
  
  }
  
  ######################################################################
  # Locks the current file.
  proc lock_command {mb} {
  
    # Lock the current file
    if {[gui::set_current_file_lock 1]} {
    
      # Set the menu up to display the unlock file menu option
      $mb entryconfigure [msgcat::mc "Lock"] -label [msgcat::mc "Unlock"] -command "menus::unlock_command $mb"
      
    }
  
  }
  
  ######################################################################
  # Unlocks the current file.
  proc unlock_command {mb} {
  
    # Unlock the current file
    if {[gui::set_current_file_lock 0]} {
    
      # Set the menu up to display the lock file menu option
      $mb entryconfigure [msgcat::mc "Unlock"] -label [msgcat::mc "Lock"] -command "menus::lock_command $mb"
      
    }
  
  }
  
  ######################################################################
  # Closes the current tab.
  proc close_command {} {
  
    gui::close_current
  
  }

  ######################################################################
  # Closes all opened tabs.
  proc close_all_command {} {
    
    gui::close_all
    
  }
  
  ######################################################################
  # Exits the application.
  proc exit_command {} {
    
    # Close any open buffers
    gui::close_buffers
      
    # Save the session information
    gui::save_session
    
    # Close all of the tabs
    gui::close_all 1
    
    # Save the clipboard history
    cliphist::save
    
    # Handle on_quit plugins
    plugins::handle_on_quit

    # Turn off profiling (if it was turned on)
    if {[::tke_development]} {
      stop_profiling_command .menubar.tools 0
    }
    
    # Destroy the interface
    destroy .
    
  }
  
  ######################################################################
  # Adds the edit menu.
  proc add_edit {mb} {
    
    # Add edit menu commands
    $mb add command -label [msgcat::mc "Undo"] -underline 0 -command "gui::undo"
    launcher::register [msgcat::mc "Menu: Undo"] gui::undo
    
    $mb add command -label [msgcat::mc "Redo"] -underline 0 -command "gui::redo"
    launcher::register [msgcat::mc "Menu: Redo"] gui::redo
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Cut"] -underline 0 -command "gui::cut"
    launcher::register [msgcat::mc "Menu: Cut selected text"] gui::cut
    
    $mb add command -label [msgcat::mc "Copy"] -underline 1 -command "gui::copy"
    launcher::register [msgcat::mc "Menu: Copy selected text"] gui::copy
    
    $mb add command -label [msgcat::mc "Paste"] -underline 0 -command "gui::paste"
    launcher::register [msgcat::mc "Menu: Paste text from clipboard"] gui::paste
    
    $mb add command -label [msgcat::mc "Paste and Format"] -underline 10 -command "gui::paste_and_format"
    launcher::register [msgcat::mc "Menu: Paste and format text from clipboard"] gui::paste_and_format
    
    $mb add separator
    
    $mb add cascade -label [msgcat::mc "Format Text"] -menu [menu $mb.formatPopup -tearoff 0]
    
    # Create formatting menu
    $mb.formatPopup add command -label [msgcat::mc "Selected"] -command "gui::format selected"
    $mb.formatPopup add command -label [msgcat::mc "All"]      -command "gui::format all"

    #$mb add separator

    #$mb add command -label [msgcat::mc "Preferences..."] -underline 3 -command "FOOBAR"
    #launcher::register [msgcat::mc "FOOBAR"] FOOBAR

    # Apply the menu settings for the edit menu
    bindings::apply $mb
  
  }
  
  ######################################################################
  # Add the find menu.
  proc add_find {mb} {
    
    # Add find menu commands
    $mb add command -label [msgcat::mc "Find"] -underline 0 -command "gui::search"
    launcher::register [msgcat::mc "Menu: Find"] gui::search
    
    $mb add command -label [msgcat::mc "Find and Replace"] -underline 9 -command "gui::search_and_replace"
    launcher::register [msgcat::mc "Menu: Find and Replace"] gui::search_and_replace
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Select next occurrence"] -underline 7 -command "gui::search_next 0"
    launcher::register [msgcat::mc "Menu: Find next occurrence"] "gui::search_next 0"
    
    $mb add command -label [msgcat::mc "Select previous occurrence"] -underline 7 -command "gui::search_previous 0"
    launcher::register [msgcat::mc "Menu: Find previous occurrence"] "gui::search_previous 0"
    
    $mb add command -label [msgcat::mc "Append next occurrence"] -underline 1 -command "gui::search_next 1"
    launcher::register [msgcat::mc "Menu: Append next occurrence"] "gui::search_next 1"
    
    $mb add command -label [msgcat::mc "Select all occurrences"] -underline 7 -command "gui::search_all"
    launcher::register [msgcat::mc "Menu: Select all occurrences"] "gui::search_all"
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Find matching pair"] -underline 5 -command "gui::show_match_pair"
    launcher::register [msgcat::mc "Menu: Find matching character pair"] "gui::show_match_pair"
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Find in files"] -underline 5 -command "menus::find_in_files"
    launcher::register [msgcat::mc "Menu: Find in files"] "menus::find_in_files"
    
    # Apply the menu settings for the find menu
    bindings::apply $mb
    
  }
  
  ######################################################################
  # Performs an egrep-like search in a user-specified list of files/directories.
  proc find_in_files {} {
    
    set rsp_list [list]
    
    # Display the find UI to the user and get input
    if {[gui::fif_get_input rsp_list]} {
    
      array set rsp $rsp_list
      
      # Convert directories into files
      array set files {}
      foreach file $rsp(in) {
        if {[file isdirectory $file]} {
          foreach sfile [glob -directory $file -types {f r} *] {
            set files($sfile) 1
          }
        } else {
          set files($file) 1
        }
      }
      
      # Perform egrep operation (test)
      bgproc::system find_in_files "egrep -a -H -C$preferences::prefs(Find/ContextNum) -n $rsp(egrep_opts) -s $rsp(find) [lsort [array names files]]" -killable 1 \
        -callback "menus::find_in_files_callback [list $rsp(find)] [array size files]"
      
    }
    
  }
  
  ######################################################################
  # Called when the egrep operation has completed.
  proc find_in_files_callback {find_expr num_files err data} {
    
    variable txt_cursor
    
    # Add the file to the viewer
    gui::add_file end Results -sidebar 0 -buffer 1
      
    # Add bindings to allow one-click file opening
    set txt [gui::current_txt]
      
    # Get the last index of the text widget
    set last_line [$txt index end]
    
    # Insert a starting mark
    $txt insert end "----\n"
    
    if {!$err || ($num_files == 0)} {
      
      # Save the text cursor
      set txt_cursor [$txt cget -cursor]
    
      # Append the results to the text widget
      $txt insert end [find_in_files_format $data]
      
      # Highlight and bind the matches
      $txt tag configure fif -underline 1 -borderwidth 1 -relief raised -foreground black -background yellow
      set i 0
      foreach index [$txt search -regexp -all -count find_counts -- $find_expr $last_line] {
        $txt tag add fif $index "$index + [lindex $find_counts $i]c"
        $txt tag bind fif <Enter>           { %W configure -cursor hand2 }
        $txt tag bind fif <Leave>           { %W configure -cursor $menus::txt_cursor }
        $txt tag bind fif <ButtonRelease-1> { menus::find_in_files_handle_click %W %x %y }
        incr i
      }
      
    } else {
      
      $txt insert end "ERROR: $data\n\n\n"
      
    }
      
    # Adjust the Vim insert cursor
    vim::adjust_insert $txt.t
      
    # Make sure that the beginning of the inserted text is in view
    $txt see end
    $txt mark set insert $last_line
    $txt see $last_line
      
  }
  
  ######################################################################
  # Formats the raw egrep data to make it more readable.
  proc find_in_files_format {data} {
    
    set results         ""
    set file_results    [list]
    set last_linenum    ""
    set first_separator 1
    array set indices   {}
    array set fnames    {}
    set index           0
    set matches         0
    
    foreach line [split $data \n] {
      if {[regexp {^(.*?)([:-])(\d+)[:-](.*)$} $line -> fname type linenum content]} {
        set first_separator 1
        if {![info exists fnames($fname)]} {
          set fnames($fname) 1
          if {[llength $file_results] > 0} {
            if {[string trim [lindex $file_results end]] eq "..."} {
              set file_results [lrange $file_results 0 end-1]
            }
            append results "[join $file_results \n]\n\n"
            set file_results [list]
          }
          lappend file_results "  [file normalize $fname]:\n"
          set last_linenum ""
          array unset indices
        }
        if {$type eq ":"} {
          if {($last_linenum eq "") || ($linenum > $last_linenum)} {
            lappend file_results [format "    %6d: %s" $linenum $content]
            set indices($linenum) $index
            set last_linenum $linenum
            incr index
          } else {
            lset file_results $indices($linenum) [string replace [lindex $file_results $indices($linenum)] 11 11 ":"]
          }
          incr matches
        } else {
          if {($last_linenum eq "") || ($linenum > $last_linenum)} {
            lappend file_results [format "    %6d  %s" $linenum $content]
            set indices($linenum) $index
            set last_linenum $linenum
            incr index
          }
        }
      } elseif {[string trim $line] eq "--"} {
        if {$first_separator} {
          set first_separator 0
        } else {
          lappend file_results "    ..."
        }
      } 
    }
    
    # Append the last files information to the results string
    append results "[join $file_results \n]\n\n"
    
    return "Found $matches [expr {($matches != 1) ? {matches} : {match}}] in [array size fnames] [expr {([array size fnames] != 1) ? {files} : {file}}]\n\n$results"
    
  }
  
  ######################################################################
  # Handles a left-click on a matched pattern in the given text widget.
  # Causes the matching file to be opened and we jump to the matching line.
  proc find_in_files_handle_click {W x y} {
    
    # Get the index of the clicked line
    set index [$W index @$x,$y]
    
    # Get the line number from the beginning of the line
    regexp {^\s*(\d+)} [$W get "$index linestart" $index] -> linenum
    
    # Get the filename of the line that is clicked
    set findex [$W search -regexp -backwards -count fif_count -- {^\s*/.*:$} $index]
    set fname  [$W get $findex "$findex+[expr $fif_count - 1]c"]
    
    # Add the file to the file viewer (if necessary)
    gui::add_file end [string trim $fname]
    
    # Jump to the line and set the cursor to the beginning of the line
    set txt [gui::current_txt]
    $txt see $linenum.0
    $txt mark set insert $linenum.0
    
  }
  
  ######################################################################
  # Adds the text menu commands.
  proc add_text {mb} {

    $mb add command -label [msgcat::mc "Comment"] -underline 0 -command "texttools::comment"
    launcher::register [msgcat::mc "Menu: Comment selected text"] "texttools::comment"

    $mb add command -label [msgcat::mc "Uncomment"] -underline 0 -command "texttools::uncomment"
    launcher::register [msgcat::mc "Menu: Uncomment selected text"] "texttools::uncomment"
    
    $mb add command -label [msgcat::mc "Indent"] -underline 0 -command "texttools::indent"
    launcher::register [msgcat::mc "Menu: Indent selected text"] "texttools::indent"
    
    $mb add command -label [msgcat::mc "Unindent"] -underline 1 -command "texttools::unindent"
    launcher::register [msgcat::mc "Menu: Unindent selected text"] "texttools::unindent"
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Align cursors"] -underline 0 -command "texttools::align"
    launcher::register [msgcat::mc "Menu: Align cursors"] "texttools::align"
    
    $mb add command -label [msgcat::mc "Insert enumeration"] -underline 7 -command "texttools::insert_enumeration"
    launcher::register [msgcat::mc "Menu: Insert enumeration"] "texttools::insert_enumeration"
    
    # Apply the menu settings for the text menu
    bindings::apply $mb

  }
  
  ######################################################################
  # Adds the view menu commands.
  proc add_view {mb} {
  
    $mb add checkbutton -label [msgcat::mc "View Sidebar"] -underline 5 -variable preferences::prefs(View/ShowSidebar) -command "gui::change_sidebar_view"
    launcher::register [msgcat::mc "Menu: Show sidebar"] "set preferences::prefs(View/ShowSidebar) 1; gui::change_sidebar_view"
    launcher::register [msgcat::mc "Menu: Hide sidebar"] "set preferences::prefs(View/ShowSidebar) 0; gui::change_sidebar_view"
    
    if {![catch "console hide"]} {
      $mb add checkbutton -label [msgcat::mc "View Console"] -underline 5 -variable preferences::prefs(View/ShowConsole) -command "gui::change_console_view"
      launcher::register [msgcat::mc "Menu: Show console"] "set preferences::prefs(View/ShowConsole) 1; gui::change_console_view"
      launcher::register [msgcat::mc "Menu: Hide console"] "set preferences::prefs(View/ShowConsole) 0; gui::change_console_view"
    }
    
    $mb add checkbutton -label [msgcat::mc "View Status Bar"] -underline 6 -variable preferences::prefs(View/ShowStatus) -command "gui::change_status_view"
    launcher::register [msgcat::mc "Menu: Show status bar"] "set preferences::prefs(View/ShowStatus) 1; gui::change_status_view"
    launcher::register [msgcat::mc "Menu: Hide status bar"] "set preferences::prefs(View/ShowStatus) 0; gui::change_status_view"
    
    $mb add separator
    
    $mb add command -label [msgcat::mc "Sort Tabs"] -underline 5 -command "gui::sort_tabs"
    launcher::register [msgcat::mc "Menu: Sort tabs"] "gui::sort_tabs"
    
    $mb add separator
    
    $mb add cascade -label [msgcat::mc "Set Syntax"] -underline 9 -menu [syntax::create_menu $mb.syntaxMenu]
    
    # Apply the menu settings for the current menu
    bindings::apply $mb
  
  }

  ######################################################################
  # Adds the tools menu commands.
  proc add_tools {mb} {
  
    # Add tools menu commands
    $mb add command -label [msgcat::mc "Launcher"] -underline 0 -command "launcher::launch"
    
    $mb add cascade -label [msgcat::mc "Theme Creator"] -underline 0 -menu [menu $mb.themer -tearoff 0]
    
    $mb.themer add command -label [msgcat::mc "Create new..."] -underline 0 -command "themer::create_new"
    launcher::register [msgcat::mc "Menu: Create new theme"] "themer::create_new"
    
    $mb.themer add command -label [msgcat::mc "Edit..."] -underline 0 -command "menus::edit_tke_command"
    launcher::register [msgcat::mc "Menu: Edit Tke theme"] "menus::edit_tke_command"
    
    $mb.themer add command -label [msgcat::mc "Import TextMate theme..."] -underline 0 -command "menus::import_tm_command"
    launcher::register [msgcat::mc "Menu: Import TextMate theme"] "menus::import_tm_command"
    
    $mb add separator
    
    $mb add checkbutton -label [msgcat::mc "Vim Mode"] -underline 0 -variable preferences::prefs(Tools/VimMode) -command "vim::set_vim_mode_all"
    launcher::register [msgcat::mc "Menu: Enable Vim mode"]  "set preferences::prefs(Tools/VimMode) 1; vim::set_vim_mode_all"
    launcher::register [msgcat::mc "Menu: Disable Vim mode"] "set preferences::prefs(Tools/VimMode) 0; vim::set_vim_mode_all"
    
    # Add development tools
    if {[::tke_development]} {
      
      $mb add separator
       
      $mb add command -label [msgcat::mc "Start Profiling"] -underline 0 -command "menus::start_profiling_command $mb"
      launcher::register [msgcat::mc "Menu: Start profiling"] "menus::start_profiling_command $mb"
       
      $mb add command -label [msgcat::mc "Stop Profiling"] -underline 1 -command "menus::stop_profiling_command $mb 1" -state disabled
      launcher::register [msgcat::mc "Menu: Stop profiling"] "menus::stop_profiling_command $mb 1"
       
      $mb add command -label [msgcat::mc "Show Last Profiling Report"] -underline 1 -command "menus::show_last_profiling_report"
      launcher::register [msgcat::mc "Menu: Show last profiling report"] "menus::show_last_profiling_report"
      
      $mb add separator
      
      $mb add command -label [msgcat::mc "Restart tke"] -underline 0 -command "menus::restart_command"
      launcher::register [msgcat::mc "Menu: Restart tke"] "menus::restart_command"
      
    }
   
    # Apply the menu bindings for the tools menu
    bindings::apply $mb
  
  }
  
  ######################################################################
  # Allows the user to select one of the Tke themes to edit and calls
  # up the theme editor.
  proc edit_tke_command {} {
    
    # Attempt to get the name of an available theme
    if {[set name [themer::get_theme]] ne ""} {
      
      # Call the themer importer for the given tke file
      themer::import_tke $name
      
    }
    
  }
  
  ######################################################################
  # Allows the user to select an existing TextMate theme to import and
  # calls the theme importer.
  proc import_tm_command {} {
    
    # Open a TextMate theme
    if {[set name [tk_getOpenFile -filetypes {{TextMate {.tmTheme .tmtheme}}} -initialdir [pwd] -parent . -title "Select TextMate theme"]] ne ""} {
      
      # Call the themer importer for the given TextMate file
      themer::import_tm $name
      
    }
    
  }
  
  ######################################################################
  # Starts the procedure profiling.
  proc start_profiling_command {mb} {
   
    if {[$mb entrycget [msgcat::mc "Start Profiling"] -state] eq "normal"} {
      
      # Turn on procedure profiling
      profile {*}$preferences::prefs(Tools/ProfileReportOptions) on
      
      # Indicate that profiling mode is on
      $mb entryconfigure [msgcat::mc "Start Profiling"] -state disabled
      $mb entryconfigure [msgcat::mc "Stop Profiling"]  -state normal
      
      # Indicate that profiling has started in the information bar
      gui::set_info_message [msgcat::mc "Profiling started"]
      
    }
    
  }
  
  ######################################################################
  # Stops the profiling process, generates a report and displays the
  # report file to a new editor tab.
  proc stop_profiling_command {mb show_report} {
    
    variable profile_report
    variable profiling_info
    
    if {[$mb entrycget [msgcat::mc "Stop Profiling"] -state] eq "normal"} {
      
      # Turn off procedure profiling
      profile off profiling_info
      
      # Generate a report file
      generate_profile_report
      # set sortby $preferences::prefs(Tools/ProfileReportSortby)
      # profrep profiling_info $sortby $profile_report "Profiling Information Sorted by $sortby"
      
      # Indicate that profiling has completed
      gui::set_info_message [msgcat::mc "Profiling stopped"]
      
      # Add the report to the tab list
      if {$show_report} {
        show_last_profiling_report
      }
      
      # Indicate that profiling mode is off
      $mb entryconfigure [msgcat::mc "Stop Profiling"] -state disabled
      $mb entryconfigure [msgcat::mc "Start Profiling"] -state normal
      
    }
    
  }
  
  ######################################################################
  # Displays the last profiling report.
  proc show_last_profiling_report {} {
    
    variable profile_report
    
    # If the profiling report exists, display it
    if {[file exists $profile_report]} {
      gui::add_file end $profile_report -lock 1
    }
    
  }
  
  ######################################################################
  # Generates a profiling report.
  proc generate_profile_report {} {
  
    variable profile_report
    variable profiling_info
    
    # Recollect the data
    set info_list [list]
    foreach info [array names profiling_info] {
    
      set name [lindex $info 0]
      
      # If the name matches anything that we don't want to profile,
      # skip to the next iteration now
      if {[regexp {^(((::)?(tk::|tcl::|ttk::|tablelist::|mwutil::))|<global>|::\w+$)} $name]} {
        continue
      }
      
      set calls [lindex $profiling_info($info) 0]
      set real  [lindex $profiling_info($info) 1]
      set cpu   [lindex $profiling_info($info) 2]
      
      if {[set index [lsearch -index 0 $info_list [lindex $info 0]]] == -1} {
        lappend info_list [list [lindex $info 0] $calls $real $cpu 0.0 0.0]
      } else {
        set info_entry [lindex $info_list $index]
        lset info_list $index 1 [expr [lindex $info_entry 1] + $calls]
        lset info_list $index 2 [expr [lindex $info_entry 2] + $real]
        lset info_list $index 3 [expr [lindex $info_entry 3] + $cpu]
      }
      
    }
    
    # Calculate the real/call and cpu/call values
    for {set i 0} {$i < [llength $info_list]} {incr i} {
      set info_entry [lindex $info_list $i]
      if {[lindex $info_entry 1] > 0} {
        lset info_list $i 4 [expr [lindex $info_entry 2].0 / [lindex $info_entry 1]]
        lset info_list $i 5 [expr [lindex $info_entry 3].0 / [lindex $info_entry 1]]
      }
    }
    
    # Sort the information
    switch $preferences::prefs(Tools/ProfileReportSortby) {
      "calls"         { set info_list [lsort -decreasing -integer -index 1 $info_list] }
      "real"          { set info_list [lsort -decreasing -integer -index 2 $info_list] }
      "cpu"           { set info_list [lsort -decreasing -integer -index 3 $info_list] }
      "real_per_call" { set info_list [lsort -decreasing -real -index 4 $info_list] }
      "cpu_per_call"  { set info_list [lsort -decreasing -real -index 5 $info_list] }
      default         { set info_list [lsort -index 0 $info_list] }
    }
    
    # Create the report file
    if {![catch "open $profile_report w" rc]} {
      
      puts $rc "=============================================================================================================="
      puts $rc [msgcat::mc "                                  Profiling Report Sorted By (%s)" $preferences::prefs(Tools/ProfileReportSortby)]
      puts $rc "=============================================================================================================="
      puts $rc [format "%-50s  %10s  %10s  %10s  %10s  %10s" "Procedure" "Calls" "Real" "CPU" "Real/Calls" "CPU/Calls"]
      puts $rc "=============================================================================================================="
      
      foreach info $info_list {
        puts $rc [format "%-50s  %10d  %10d  %10d  %10.3f  %10.3f" {*}$info]
      }
      
      close $rc
      
    }
    
  }
  
  ######################################################################
  # Restart the GUI.
  proc restart_command {} {
  
    # Get the list of filenames to start
    set filenames [gui::get_actual_filenames]
    
    # Execute the restart command
    exec [info nameofexecutable] [file join $::tke_dir restart.tcl] [info nameofexecutable] [file join $::tke_dir tke.tcl] {*}$filenames &
  
  }
  
  ######################################################################
  # Add the plugins menu commands.
  proc add_plugins {mb} {
  
    # Add plugins menu commands
    $mb add command -label [msgcat::mc "Install..."] -underline 0 -command "plugins::install"
    launcher::register [msgcat::mc "Menu: Install plugin"] "plugins::install"
    
    $mb add command -label [msgcat::mc "Uninstall..."] -underline 0 -command "plugins::uninstall"
    launcher::register [msgcat::mc "Menu: Uninstall plugin"] "plugins::uninstall"
    
    $mb add command -label [msgcat::mc "Reload"] -underline 0 -command "plugins::reload"
    launcher::register [msgcat::mc "Menu: Reload all plugins"] "plugins::reload"
    
    if {[::tke_development]} {
      
      $mb add separator
      $mb add command -label [msgcat::mc "Create..."] -underline 0 -command "plugins::create_new_plugin"
      launcher::register [msgcat::mc "Menu: Create new plugin"] "plugins::create_new_plugin"
      
    }
    
    # Allow the plugin architecture to add menu items
    plugins::handle_plugin_menu $mb
    
  }
  
  ######################################################################
  # Adds the help menu commands.
  proc add_help {mb} {
    
    if {[tk windowingsystem] ne "aqua"} {
      $mb add command -label [msgcat::mc "About tke"] -underline 0 -command "gui::show_about"
    }
    launcher::register [msgcat::mc "Menu: About tke"] "gui::show_about"
    
  }
  
}

