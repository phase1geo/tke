# Name:    gui.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Contains all of the main GUI elements for the editor

namespace eval gui {

  variable curr_id    0
  variable filenames  {}
  variable nb_index   0
  variable nb_current ""

  array set widgets {}
  
  #######################
  #  PUBLIC PROCEDURES  #
  #######################
  
  ######################################################################
  # Create the main GUI interface.
  proc create {} {
  
    variable widgets
    
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

    bind $widgets(nb) <ButtonPress-1> {
      if {[set tabid [%W index @%x,%y]] ne ""} {
        set gui::nb_current $tabid
        set gui::last_x     %x
      } else {
        set gui::nb_current ""
      }
    }
    bind $widgets(nb) <B1-Motion> {
      if {[set tabid [%W index @%x,%y]] ne ""} {
        if {($gui::nb_current ne "") && \
            ((($gui::nb_current > $tabid) && (%x < $gui::last_x)) || \
             (($gui::nb_current < $tabid) && (%x > $gui::last_x)))} {
          set tab   [lindex [%W tabs] $gui::nb_current]
          set title [%W tab $gui::nb_current -text]
          %W forget $gui::nb_current
          %W insert $tabid $tab -text $title
          %W select $tabid
          set gui::nb_current $tabid
        }
        set gui::last_x %x
      }
    }
    bind $widgets(nb) <ButtonRelease-1> {
      set gui::nb_current ""
    }
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
  
    # Add the tab to the editor frame
    set w [insert_tab $index [file tail $fname]]
      
    if {![catch "open $fname r" rc]} {
    
      # Read the file contents and insert them
      $w.tf.txt insert end [read $rc]
      
      # Close the file
      close $rc
      
      # Highlight the text
      $w.tf.txt highlight 1.0 end
      
      # Change the text to unmodified
      $w.tf.txt edit modified false
      
    }
      
    # Insert the filenames
    set filenames [linsert $filenames [$widgets(nb) index $w] $fname]
      
    # Change the tab text
    $widgets(nb) tab [$widgets(nb) index $w] -text [file tail [lindex $filenames $index]]

  }
  
  ######################################################################
  # Add a list of files to the editor panel and raise the window to
  # make it visible.
  proc add_files_and_raise {index args} {
  
    # Add the list of files to the editor panel.
    foreach fname [lreverse $args] {
      add_file $index $fname
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
    
    # If the file needs to be saved, do it now
    if {[[current_txt] edit modified]} {
      if {[set answer [tk_messageBox -default yes -type yesno -message "Save file?" -title "Save request"]] eq "yes"} {
        save_current
      }
    }
    
    # Remove bindings
    indent::remove_bindings [current_txt]
    
    # Add a new file if we have no more tabs
    if {[llength [$widgets(nb) tabs]] == 1} {
      add_new_file end
    }
    
    # Remove the tab
    $widgets(nb) forget current
    
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
    $txt edit undo
  
    # Attempt to undo again to see if the undo button should be disabled
    if {![catch "$txt edit undo"]} {
      $txt edit redo
    }
  
  }
  
  ######################################################################
  # This procedure performs an redo operation.
  proc redo {} {
  
    variable widgets
    
    # Get the current textbox
    set txt [current_txt]
    
    # Perform the redo operation
    $txt edit redo
  
    # Attempt to redo again to see if the redo button should be disabled
    if {![catch "$txt edit redo"]} {
      $txt edit undo
    }
    
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
    
    bind $tab_frame.tf.txt <<Modified>> "gui::text_changed %W"
    
    grid rowconfigure    $tab_frame.tf 0 -weight 1
    grid columnconfigure $tab_frame.tf 0 -weight 1
    grid $tab_frame.tf.txt -row 0 -column 0 -sticky news
    grid $tab_frame.tf.vb  -row 0 -column 1 -sticky ns
    grid $tab_frame.tf.hb  -row 1 -column 0 -sticky ew
    
    # Create the information bar
    ttk::frame $tab_frame.if
    pack [ttk::label $tab_frame.if.ll1 -text "Line:"]   -side left -padx 2 -pady 2
    pack [ttk::label $tab_frame.if.ll2 -text 1]         -side left -padx 2 -pady 2
    pack [ttk::label $tab_frame.if.cl1 -text "Column:"] -side left -padx 2 -pady 2
    pack [ttk::label $tab_frame.if.cl2 -text 0]         -side left -padx 2 -pady 2
    
    pack $tab_frame.tf -fill both -expand yes
    pack $tab_frame.if -fill x
    
    # Add the text bindings
    indent::add_bindings $tab_frame.tf.txt
    
    # Add the new tab to the notebook
    $widgets(nb) insert $index $tab_frame -text $title
    
    # Make the new tab the current tab
    # $widgets(nb) select $index
    
    # Give the text widget the focus
    after idle [focus $tab_frame.tf.txt]
    
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
                      
    set control [list proc uplevel namespace while for foreach if else elseif switch default return]
  
    # Create the ctext widget
    ctext $w -wrap none -background black -foreground white -insertbackground white {*}$args
    
    # Apply the syntax highlighting rules
    ctext::addHighlightClass                  $w widgets        "purple"            $widgets
    ctext::addHighlightClass                  $w flags          "orange"            $flags
    ctext::addHighlightClass                  $w stackControl   "red"               $control
    ctext::addHighlightClassWithOnlyCharStart $w vars           "mediumspringgreen" "\$"
    ctext::addHighlightClass                  $w variable_funcs "gold"              {set global variable unset list array}
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
  # Returns the current text widget pathname.
  proc current_txt {} {
  
    variable widgets
    
    return "[$widgets(nb) select].tf.txt"
    
  }
  
}
