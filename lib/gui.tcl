# Name:    gui.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Contains all of the main GUI elements for the editor and
#          their behavior.

namespace eval gui {

  variable curr_id       0
  variable filenames     {}
  variable nb_index      0
  variable nb_current    ""
  variable geometry_file [file join $::tke_home geometry.dat]
  variable search_counts {}

  array set widgets {}
  
  #######################
  #  PUBLIC PROCEDURES  #
  #######################
  
  ######################################################################
  # Create the main GUI interface.
  proc create {} {
  
    variable widgets
    
    # Load the geometry information
    load_geometry
    
    wm title . "tke"
    # FIXME: wm iconphoto FOOBAR
    
    # Create the panedwindow
    set widgets(pw) [ttk::panedwindow .pw -orient horizontal]
    
    # Add the file tree
    set widgets(fview) [ttk::frame $widgets(pw).ff]
    
    # Add the file tree elements
    set widgets(filetl) \
      [tablelist::tablelist $widgets(fview).tl -columns {0 {}} -showlabels 0 -exportselection 0 \
        -treecolumn 0 \
        -xscrollcommand "utils::set_scrollbar $widgets(fview).hb" \
        -yscrollcommand "utils::set_scrollbar $widgets(fview).vb"]
    ttk::scrollbar $widgets(fview).vb -orient vertical   -command "$widgets(filetl) yview"
    ttk::scrollbar $widgets(fview).hb -orient horizontal -command "$widgets(filetl) xview"
    
    $widgets(filetl) columnconfigure 0 -name files -editable 0
    
    grid rowconfigure    $widgets(fview) 0 -weight 1
    grid columnconfigure $widgets(fview) 0 -weight 1
    grid $widgets(fview).tl -row 0 -column 0 -sticky news
    grid $widgets(fview).vb -row 0 -column 1 -sticky ns
    grid $widgets(fview).hb -row 0 -column 2 -sticky ew
    
    # Create editor notebook
    $widgets(pw) add [set widgets(nb) [ttk::notebook .nb]]

    bind $widgets(nb) <<NotebookTabChanged>> { focus [gui::current_txt].t }
    bind $widgets(nb) <ButtonPress-1>        { gui::tab_move_start %W %x %y }
    bind $widgets(nb) <B1-Motion>            { gui::tab_move_motion %W %x %y }
    bind $widgets(nb) <ButtonRelease-1>      { gui::tab_move_end %W %x %y }
    bind $widgets(nb) <Button-3> {
      if {[%W index @%x,%y] eq [%W index current]} {
        if {[llength [%W tabs]] > 1} {
          $gui::widgets(menu) entryconfigure 1 -state normal
        } else {
          $gui::widgets(menu) entryconfigure 1 -state disabled
        }
        tk_popup $gui::widgets(menu) %X %Y
      }
    }

    # Create tab popup
    set widgets(menu) [menu .nb.popupMenu -tearoff 0]
    $widgets(menu) add command -label "Close Tab" -command {
      gui::close_current
    }
    $widgets(menu) add command -label "Close Other Tab(s)" -command {
      gui::close_others
    }
    $widgets(menu) add command -label "Close All Tabs" -command {
      gui::close_all
    }
    
    # Pack the notebook
    pack $widgets(nb) -fill both -expand yes
    
    # Add the menu bar
    menus::create
    
    # If the user attempts to close the window via the window manager, treat
    # it as an exit request from the menu system.
    wm protocol . WM_DELETE_WINDOW {
      menus::exit_command
    }
  
  }
  
  ######################################################################
  # Handles a tab move start event.
  proc tab_move_start {W x y} {
  
    variable nb_current
    variable last_x
  
    if {[set tabid [$W index @$x,$y]] ne ""} {
      set nb_current $tabid
      set last_x     $x
    } else {
      set nb_current ""
    }
  
  }
  
  ######################################################################
  # Handles a tab move motion.
  proc tab_move_motion {W x y} {
    
    variable nb_current
    variable last_x
    variable filenames
    
    if {[set tabid [$W index @$x,$y]] ne ""} {
      if {($nb_current ne "") && \
          ((($nb_current > $tabid) && ($x < $last_x)) || \
           (($nb_current < $tabid) && ($x > $last_x)))} {
        set tab       [lindex [$W tabs] $nb_current]
        set title     [$W tab $nb_current -text]
        set fname     [lindex $filenames $nb_current]
        set filenames [lreplace $filenames $nb_current $nb_current]
        $W forget $nb_current
        $W insert [expr {($tabid == [$W index end]) ? "end" : $tabid}] $tab -text $title
        $W select $tabid
        set filenames  [linsert $filenames $tabid $fname]
        set nb_current $tabid
      }
      set last_x $x
    }
    
  }
  
  ######################################################################
  # Handles the end of a tab move.
  proc tab_move_end {W x y} {

    variable nb_current

    set nb_current ""

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
  # Adds a new file to the editor pane.
  proc add_new_file {index} {
  
    variable widgets
    variable filenames
    
    set filenames [linsert $filenames [$widgets(nb) index [insert_tab $index "Untitled"]] ""]
    
  }
  
  ######################################################################
  # Creates a new tab for the given filename specified at the given index
  # tab position.
  proc add_file {index fname} {
  
    variable widgets
    variable filenames
    
    # If the file is already loaded, display the tab
    if {[set file_index [lsearch $filenames $fname]] != -1} {
      
      $widgets(nb) select $file_index
      
    # Otherwise, load the file in a new tab
    } else {
  
      # Add the tab to the editor frame
      set w [insert_tab $index [file tail $fname]]
      
      if {![catch "open $fname r" rc]} {
    
        # Read the file contents and insert them
        $w.tf.txt insert end [string range [read $rc] 0 end-1]
      
        # Close the file
        close $rc
      
        # Highlight the text
        $w.tf.txt highlight 1.0 end
      
        # Change the text to unmodified
        $w.tf.txt edit modified false
        
        # Set the insertion mark to the first position
        $w.tf.txt mark set insert 1.0
      
      }
      
      # Insert the filenames
      set filenames [linsert $filenames [$widgets(nb) index $w] $fname]
      
      # Change the tab text
      $widgets(nb) tab [$widgets(nb) index $w] -text [file tail [lindex $filenames $index]]
      
    }

  }
  
  ######################################################################
  # Add a list of files to the editor panel and raise the window to
  # make it visible.
  proc add_files_and_raise {index args} {
  
    # Add the list of files to the editor panel.
    foreach fname [lreverse $args] {
      add_file $index [file normalize $fname]
    }
    
    # Raise ourselves
    raise_window
  
  }
  
  ######################################################################
  # Raise ourself to the top.
  proc raise_window {} {
  
    variable widgets
    
    # If the notebook widget doesn't exist this will cause an error to occur.
    if {$widgets(nb) ne ""} {
  
      wm withdraw  .
      wm deiconify .
      
    }
  
  }
  
  ######################################################################
  # Returns the filename of the current tab.
  proc current_filename {} {
  
    variable widgets
    variable filenames
    
    return [lindex $filenames [$widgets(nb) index current]]
  
  }
  
  ######################################################################
  # Saves the current tab filename.
  proc save_current {{save_as ""}} {
  
    variable widgets
    variable filenames
    
    # Get the index of the currently displayed tab
    set index [$widgets(nb) index current]
    
    # If a save_as name is specified, change the filename
    if {$save_as ne ""} {
      lset filenames $index $save_as
    
    # If the current file doesn't have a filename, allow the user to set it
    } elseif {[lindex $filenames $index] eq ""} {
      if {[set sfile [tk_getSaveFile -defaultextension .tcl -parent . -title "Save As" -initialdir [pwd]]] eq ""} {
        return
      } else {
        lset filenames $index $sfile
      }
    }
    
    # Save the file contents
    if {![catch "open [lindex $filenames $index] w" rc]} {
      puts $rc [[current_txt] get 1.0 end-1c]
      close $rc
    }
    
    # Change the tab text
    $widgets(nb) tab $index -text [file tail [lindex $filenames $index]]
    
    # Change the text to unmodified
    [current_txt] edit modified false
  
  }
  
  ######################################################################
  # Close the current tab.
  proc close_current {} {
  
    variable widgets
    variable filenames
    
    # If the file needs to be saved, do it now
    if {[[current_txt] edit modified]} {
      if {[set answer [tk_messageBox -default yes -type yesno -message "Save file?" -title "Save request"]] eq "yes"} {
        save_current
      }
    }
    
    # Get the index of the current tab
    set tab_index [$widgets(nb) index current]
    
    # Remove bindings
    indent::remove_bindings [current_txt]
    
    # Add a new file if we have no more tabs
    if {[llength [$widgets(nb) tabs]] == 1} {
      add_new_file end
    }

    # Delete the file from filenames
    set filenames [lreplace $filenames $tab_index $tab_index]
        
    # Remove the tab
    $widgets(nb) forget $tab_index
    
  }
  
  ######################################################################
  # Close all tabs but the current tab.
  proc close_others {} {
  
    variable widgets
    
    # Get the current tab
    set current [$widgets(nb) select]

    foreach tab [lreverse [$widgets(nb) tabs]] {
      if {$tab ne $current} {
        $widgets(nb) select $tab
        close_current
      }
    }

  }
  
  ######################################################################
  # Close all of the tabs.
  proc close_all {} {
  
    variable widgets
    
    foreach tab [lreverse [$widgets(nb) tabs]] {
      $widgets(nb) select $tab
      close_current
    }
  
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
    tk_textCut [current_txt]
  
  }
  
  ##############################################################################
  # This procedure performs a text selection copy operation.
  proc copy {} {
    
    # Perform the copy
    tk_textCopy [current_txt]
  
  }
  
  ##############################################################################
  # This procedure performs a text selection paste operation.
  proc paste {} {
  
    # Perform the paste
    tk_textPaste [current_txt]
 
  }
  
  ######################################################################
  # This procedure performs a paste operation, formatting the pasted text
  # to match the code that it is being pasted into.
  proc paste_and_format {} {
  
    # Have the indent namespace format the clipboard contents
    indent::format_clipboard [current_txt]
    
    # Perform the paste operation
    paste
  
  }
  
  ######################################################################
  # Displays the search bar.
  proc search {} {
    
    variable widgets
    
    # Get the current text frame
    set tab_frame [$widgets(nb) select]
    
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
    set tab_frame [$widgets(nb) select]
    
    # Hide the search frame
    grid remove $tab_frame.sf
    grid remove $tab_frame.sep
    
    # Put the focus on the text widget
    focus $tab_frame.tf.txt.t
     
  }
  
  ######################################################################
  # Displays the search and replace bar.
  proc search_and_replace {} {
    
  }
  
  ######################################################################
  # Searches for the next occurrence of the search item.
  proc search_next {app} {
    
    variable widgets
    variable search_counts

    # Get the current tab frame
    set tab_frame [$widgets(nb) select]
    
    # Get the current text widget
    set txt $tab_frame.tf.txt
    
    # Get the search text
    set value [$tab_frame.sf.e get]
    
    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }
    
    # Search the text widget from the current insertion cursor forward.
    if {[set match [$txt search -count gui::search_counts -- $value insert]] ne ""} {
      $txt tag add sel $match "$match+${search_counts}c"
      $txt mark set insert "$match+${search_counts}c"
      $txt see $match
    }
    
    # Closes the search interface
    close_search
    
  }
  
  ######################################################################
  # Searches for the previous occurrence of the search item.
  proc search_previous {app} {
    
    variable widgets
    variable search_counts
    
    # Get the current tab frame
    set tab_frame [$widgets(nb) select]
    
    # Get the current text widget
    set txt $tab_frame.tf.txt
    
    # Get the search text
    set value [$tab_frame.sf.e get]
    
    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }
   
    # Search the text widget from the current insertion cursor forward.
    if {[set match [$txt search -backwards -count gui::search_counts -- $value insert-[string length $value]c]] ne ""} {
      $txt tag add sel $match "$match+${search_counts}c"
      $txt mark set insert "$match+${search_counts}c"
      $txt see $match
    }
    
    # Close the search interface
    close_search
    
  }
  
  ######################################################################
  # Searches for all of the occurrences and selects them all.
  proc search_all {} {
    
    variable widgets
    variable search_counts
    
    # Get the current tab frame
    set tab_frame [$widgets(nb) select]
    
    # Get the current text widget
    set txt $tab_frame.tf.txt
    
    # Get the search text
    set value [$tab_frame.sf.e get]
    
    # Clear the selection
    $txt tag remove sel 1.0 end
    
    # Search the entire text
    set i 0
    set matches [$txt search -count gui::search_counts -all -- $value 1.0]
    foreach match $matches {
      $txt tag add sel $match "$match+[lindex $search_counts $i]c"
      incr i
    }

    # Make the first line viewable
    catch {
      $txt mark set insert "[lindex $matches 0]+[lindex $search_counts 0]c"
      $txt see [lindex $matches 0]
    }
    
    # Close the search interface
    close_search
    
  }
  
  ######################################################################
  # Returns the list of stored filenames.
  proc get_actual_filenames {} {
  
    variable filenames
    
    set actual_filenames [list]
    
    foreach filename $filenames {
      if {$filename ne ""} {
        lappend actual_filenames $filename
      }
    }
    
    return $actual_filenames
    
  }
  
  ########################
  #  PRIVATE PROCEDURES  #
  ########################
 
  ######################################################################
  # Inserts a new tab into the editor tab notebook.
  proc insert_tab {index title} {
  
    variable widgets
    variable curr_id
    
    # Get the unique tab ID
    set id [incr curr_id]
    
    # Create the tab frame
    set tab_frame [ttk::frame $widgets(nb).$id]
    
    # Create the editor frame
    ttk::frame $tab_frame.tf
    create_ctext $tab_frame.tf.txt -undo 1 \
      -xscrollcommand "utils::set_scrollbar $tab_frame.tf.hb" \
      -yscrollcommand "utils::set_scrollbar $tab_frame.tf.vb"
    ttk::scrollbar $tab_frame.tf.vb -orient vertical   -command "$tab_frame.tf.txt yview"
    ttk::scrollbar $tab_frame.tf.hb -orient horizontal -command "$tab_frame.tf.txt xview"
    
    bind $tab_frame.tf.txt <<Modified>>    "gui::text_changed %W"
    bind $tab_frame.tf.txt <<Selection>>   "gui::selection_changed %W"
    bind $tab_frame.tf.txt <ButtonPress-1> "after idle [list gui::update_position $tab_frame]"
    bind $tab_frame.tf.txt <B1-Motion>     "gui::update_position $tab_frame"
    bind $tab_frame.tf.txt <KeyRelease>    "gui::update_position $tab_frame"
    bind Text <<Cut>>     ""
    bind Text <<Copy>>    ""
    bind Text <<Paste>>   ""
    bind Text <Control-d> ""
    
    grid rowconfigure    $tab_frame.tf 0 -weight 1
    grid columnconfigure $tab_frame.tf 0 -weight 1
    grid $tab_frame.tf.txt -row 0 -column 0 -sticky news
    grid $tab_frame.tf.vb  -row 0 -column 1 -sticky ns
    grid $tab_frame.tf.hb  -row 1 -column 0 -sticky ew
    
    # Create the search bar
    ttk::frame     $tab_frame.sf
    ttk::label     $tab_frame.sf.l1 -text "Find:"
    ttk::entry     $tab_frame.sf.e
    
    pack $tab_frame.sf.l1  -side left -padx 2 -pady 2
    pack $tab_frame.sf.e   -side left -padx 2 -pady 2 -fill x
    
    bind $tab_frame.sf.e <Return> "gui::search_next 0"
    bind $tab_frame.sf.e <Escape> "gui::close_search"
    
    # Create separator between search and information bar
    ttk::separator $tab_frame.sep -orient horizontal
    
    # Create the information bar
    ttk::frame $tab_frame.if
    pack [ttk::label $tab_frame.if.ll1 -text "Line:"]   -side left -padx 2 -pady 2
    pack [ttk::label $tab_frame.if.ll2 -text 1]         -side left -padx 2 -pady 2
    pack [ttk::label $tab_frame.if.cl1 -text "Column:"] -side left -padx 2 -pady 2
    pack [ttk::label $tab_frame.if.cl2 -text 0]         -side left -padx 2 -pady 2
    
    grid rowconfigure    $tab_frame 0 -weight 1
    grid columnconfigure $tab_frame 0 -weight 1
    grid $tab_frame.tf  -row 0 -column 0 -sticky news
    grid $tab_frame.sf  -row 1 -column 0 -sticky ew
    grid $tab_frame.sep -row 2 -column 0 -sticky ew
    grid $tab_frame.if  -row 3 -column 0 -sticky ew
    
    # Hide the search bar and search separator
    grid remove $tab_frame.sf
    grid remove $tab_frame.sep
    
    # Add the text bindings
    indent::add_bindings $tab_frame.tf.txt
    multicursor::add_bindings $tab_frame.tf.txt
    
    # Get the adjusted index
    set adjusted_index [$widgets(nb) index $index]
    
    # Add the new tab to the notebook
    $widgets(nb) insert $index $tab_frame -text $title
    
    # Make the new tab the current tab
    $widgets(nb) select $adjusted_index
    
    # Give the text widget the focus
    focus $tab_frame.tf.txt.t
    
    return $tab_frame
    
  }
 
  ##############################################################################
  # Creates a ctext widget and configures it for Tcl/Tk syntax highlighting.  Returns
  # the widget path.
  proc create_ctext {w args} {
  
    set widgets [list ctext button label text frame toplevel scrollbar checkbutton canvas \
                      listbox menu menubar menubutton radiobutton scale entry message \
                      tk_chooseDir tk_getSaveFile tk_getOpenFile tk_chooseColor tk_optionMenu \
                      ttk::button ttk::checkbutton ttk::combobox ttk::entry ttk::frame ttk::label \
                      ttk::labelframe ttk::menubutton ttk::notebook ttk::panedwindow \
                      ttk::progressbar ttk::radiobutton ttk::scale ttk::scrollbar ttk::separator \
                      ttk::sizegrip ttk::treeview]
  
    set flags   [list -text -command -yscrollcommand -xscrollcommand -background -foreground -fg \
                      -bg -highlightbackground -y -x -highlightcolor -relief -width -height -wrap \
                      -font -fill -side -outline -style -insertwidth  -textvariable -activebackground \
                      -activeforeground -insertbackground -anchor -orient -troughcolor -nonewline \
                      -expand -type -message -title -offset -in -after -yscroll -xscroll -forward \
                      -regexp -count -exact -padx -ipadx -filetypes -all -from -to -label -value \
                      -variable -regexp -backwards -forwards -bd -pady -ipady -state -row -column \
                      -cursor -highlightcolors -linemap -menu -tearoff -displayof -cursor -underline \
                      -tags -tag -weight -sticky -rowspan -columnspan]
                      
    set control [list proc uplevel namespace while for foreach if else elseif switch default return catch exec exit]
  
    # Create the ctext widget
    ctext $w -wrap none -background black -foreground white -insertbackground white {*}$args
    
    # Apply the syntax highlighting rules
    ctext::addHighlightClass                  $w widgets        "purple"            $widgets
    ctext::addHighlightClass                  $w flags          "orange"            $flags
    ctext::addHighlightClass                  $w stackControl   "red"               $control
    ctext::addHighlightClassWithOnlyCharStart $w vars           "mediumspringgreen" "\$"
    ctext::addHighlightClass                  $w variable_funcs "gold"              {set global variable unset list array incr}
    ctext::addHighlightClassForSpecialChars   $w brackets       "green"             {[]{}}
    ctext::addHighlightClassForRegexp         $w paths          "lightblue"         {\.[a-zA-Z0-9\_\-]+}
    ctext::addHighlightClassForRegexp         $w strings        "pink"              {\"[^\"]*\"}
    ctext::addHighlightClassForRegexp         $w comments       "grey"              {#[^\n\r]*}
    ctext::addHighlightClassForRegexp         $w fixme          "yellow"            {FIXME}
  
    return $w
  
  }
  
  ######################################################################
  # Handles a change to the current text widget.
  proc text_changed {txt} {
  
    variable widgets
  
    if {[$txt edit modified]} {
      
      # Change the look of the tab
      if {[string index [set name [$widgets(nb) tab current -text]] 0] ne "*"} {
        $widgets(nb) tab current -text "* $name"
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
  # Returns the current text widget pathname.
  proc current_txt {} {
  
    variable widgets
    
    return "[$widgets(nb) select].tf.txt"
    
  }
  
  ######################################################################
  # Returns the current search entry pathname.
  proc current_search {} {
    
    variable widgets
    
    return "[$widgets(nb) select].sf.e"
    
  }
  
  ######################################################################
  # Updates the current position information in the information bar based
  # on the current location of the insertion cursor.
  proc update_position {w} {
  
    variable widgets
    
    # Get the current position of the insertion cursor
    lassign [split [$w.tf.txt index insert] .] line column
    
    # Update the information widgets
    $w.if.ll2 configure -text $line
    $w.if.cl2 configure -text [expr $column + 1]
  
  }
  
}

