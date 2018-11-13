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
# Name:    pref_ui.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/14/2016
# Brief:   Contains namespace that displays preference UI.
######################################################################

namespace eval pref_ui {

  variable current_panel     ""
  variable selected_session  ""
  variable selected_language ""
  variable mod_dict
  variable sym_dict
  variable enable_share
  variable share_changed
  variable initialize_callbacks {}

  array set widgets     {}
  array set match_chars {}
  array set snip_compl  {}
  array set snip_data   {}
  array set prefs       {}
  array set colorizers {
    keywords       0
    comments       0
    strings        0
    numbers        0
    punctuation    0
    precompile     0
    miscellaneous1 0
    miscellaneous2 0
    miscellaneous3 0
  }
  array set attributes {
    preview     0
    syntax      0
    filesize    0
    imagesize   0
    modified    0
    permissions 0
    owner       0
    group       0
    linecount   0
    wordcount   0
    charcount   0
    readtime    0
    md5         0
    sha1        0
    sha224      0
    sha256      0
    favorite    0
    version     0
  }

  if {[catch { ttk::spinbox .__tmp }]} {
    set bg               [utils::get_default_background]
    set fg               [utils::get_default_foreground]
    set widgets(sb)      "spinbox"
    set widgets(sb_opts) "-relief flat -buttondownrelief flat -buttonuprelief flat -background $bg -foreground $fg"
  } else {
    set widgets(sb)      "ttk::spinbox"
    set widgets(sb_opts) "-justify center"
    destroy .__tmp
  }

  ######################################################################
  # Register the given initialization callback.
  proc register_initialization {cmd} {

    variable initialize_callbacks

    lappend initialize_callbacks $cmd

  }

  ######################################################################
  # Initializes all of the widgets.
  proc initialize_widgets {} {

    variable initialize_callbacks

    foreach callback $initialize_callbacks {
      uplevel #0 $callback
    }

  }

  ######################################################################
  # Returns the grid row to insert the given widget into.  Also has the
  # side-effect of configuring the grid layout if we are the first child
  # to be placed.
  proc get_grid_row {w} {

    lassign [grid size [winfo parent $w]] col row

    # If we are the first row, configure the grid
    if {$row == 0} {
      grid columnconfigure [winfo parent $w] 3 -weight 1
    }

    return $row

  }

  ######################################################################
  # Make a horizontal spacer.
  proc make_spacer {w {grid 0}} {

    set win [ttk::label $w.spacer[llength [lsearch -all [winfo children $w] $w.spacer*]]]

    if {$grid} {
      grid $win -row [get_grid_row $win] -column 0 -sticky ew -columnspan 4
    } else {
      pack $win -fill x
    }

    return $win

  }

  ######################################################################
  # Make a checkbutton.
  proc make_cb {w msg varname {grid 0}} {

    # Create the widget
    ttk::checkbutton $w -text [format " %s" $msg] -variable pref_ui::prefs($varname)

    # Pack the widget
    if {$grid} {
      grid $w -row [get_grid_row $w] -column 0 -sticky ew -columnspan 4 -padx 2 -pady 2
    } else {
      pack $w -fill x -padx 2 -pady 2
    }

    # Register the widget for search
    register $w $msg $varname

    return $w

  }

  ######################################################################
  # Make a radiobutton.
  proc make_rb {w msg varname value {grid 0}} {

    # Create the widget
    ttk::radiobutton $w -text [format " %s" $msg] -variable pref_ui::prefs($varname) -value $value

    # Pack the widget
    if {$grid} {
      grid $w -row [get_grid_row $w] -column 0 -sticky ew -columnspan 4 -padx 2 -pady 2
    } else {
      pack $w -fill x -padx 2 -pady 2
    }

    # Register the widget for search
    register $w $msg $varname

    return $w

  }

  ######################################################################
  # Make a menubutton.
  proc make_mb {w msg varname values {grid 0}} {

    # Create and pack the widget
    if {$grid} {
      ttk::label ${w}l -text $msg
      set win [ttk::menubutton ${w}mb -textvariable pref_ui::prefs($varname) \
        -menu [set mnu [menu ${w}mbMenu -tearoff 0]]]
      set row [get_grid_row ${w}l]
      grid ${w}l  -row $row -column 0 -sticky news -padx 2 -pady 2
      grid ${w}mb -row $row -column 1 -sticky news -columnspan 2 -padx 2 -pady 2
    } else {
      pack [ttk::frame $w] -fill x
      pack [ttk::label $w.l -text $msg] -side left -padx 2 -pady 2
      pack [set win [ttk::menubutton $w.mb -textvariable pref_ui::prefs($varname) \
        -menu [set mnu [menu $w.mbMenu -tearoff 0]]]] -side left -padx 2 -pady 2
    }

    # Populate the menu
    init_mb $win $varname $values

    # Register the widget
    register $win $msg $varname

    return $win

  }

  ######################################################################
  # Initializes the menubutton's menu with the given set of values.
  proc init_mb {w varname values} {

    # Get the menu from the menubutton
    set mnu [$w cget -menu]

    # Clear the menu
    $mnu delete 0 end

    foreach value $values {
      $mnu add radiobutton -label $value -variable pref_ui::prefs($varname) -value $value
    }

  }

  ######################################################################
  # Make an entry.
  proc make_entry {w msg varname watermark {grid 0} {help ""}} {

    # Create the widget
    ttk::labelframe $w -text $msg
    pack [wmarkentry::wmarkentry $w.e -textvariable pref_ui::prefs($varname) -watermark $watermark] -fill x
    if {$help ne ""} {
      make_help $w $help
    }

    # Pack the widget
    if {$grid} {
      grid $w -row [get_grid_row $w] -column 0 -sticky news -columnspan 4 -padx 2 -pady 2
    } else {
      pack $w -fill x -padx 2 -pady 2
    }

    # Register the widget for search
    register $w.e $msg $varname

    return $w.e

  }

  ######################################################################
  # Make a tokenentry field.
  proc make_token {w msg varname watermark {grid 0} {help ""}} {

    # Create the widget
    ttk::labelframe $w -text $msg
    pack [tokenentry::tokenentry $w.te -tokenvar pref_ui::prefs($varname) \
      -watermark $watermark -tokenshape square] -fill x

    if {$help ne ""} {
      make_help $w $help
    }

    # Pack the widget
    if {$grid} {
      grid $w -row [get_grid_row $w] -column 0 -sticky news -columnspan 4 -padx 2 -pady 2
    } else {
      pack $w -fill x -padx 2 -pady 2
    }

    # Initialize the widget
    register_initialization [list pref_ui::init_token $w.te $varname]

    # Register the widget for search
    register $w.te $msg $varname

    return $w.te

  }

  ######################################################################
  # Initializes the given tokenentry widget.
  proc init_token {w varname} {

    $w tokendelete 0 end
    $w tokeninsert end $pref_ui::prefs($varname)

  }

  ######################################################################
  # Make a text field.
  proc make_text {w msg varname height {grid 0} {help ""}} {

    ttk::labelframe    $w -text $msg
    text               $w.t -height $height -borderwidth 0 -highlightthickness 0 \
      -xscrollcommand [list utils::set_xscrollbar $w.hb] -yscrollcommand [list utils::set_yscrollbar $w.vb]
    scroller::scroller $w.vb -orient vertical   -command [list $w.t yview]
    scroller::scroller $w.hb -orient horizontal -command [list $w.t xview]
    ttk::frame         $w.bf
    pack [ttk::button $w.bf.save -style BButton -text [msgcat::mc "Save"] -command [list pref_ui::text_save $w.t $varname] -state disabled] -side left -padx 2 -pady 2

    bind $w.t <<Modified>> [list pref_ui::text_modified $w]

    grid rowconfigure    $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid $w.t  -row 0 -column 0 -sticky news
    grid $w.vb -row 0 -column 1 -sticky ns
    grid $w.hb -row 1 -column 0 -sticky ew
    grid $w.bf -row 2 -column 0 -sticky ew

    if {$help ne ""} {
      make_help $w $help 1
    }

    # Register the widget for initialization
    register_initialization [list pref_ui::init_text $w.t $varname]

    if {$grid} {
      grid $w -row [get_grid_row $w] -column 0 -sticky news -columnspan 4 -padx 2 -pady 2
    } else {
      pack $w -fill both -expand yes -padx 2 -pady 2
    }

    # Register the widget for search
    register $w.t $msg $varname

    return $w.t

  }

  ######################################################################
  # Initializes the given text widget.
  proc init_text {w varname} {

    # Inser the text
    $w delete 1.0 end
    $w insert end $pref_ui::prefs($varname)

    # Set the edit status to false
    $w edit modified 0

    # Redisable the Save button
    [winfo parent $w].bf.save configure -state disabled

  }

  ######################################################################
  # Make the Save button visible.
  proc text_modified {w} {

    if {[$w.t edit modified]} {
      $w.bf.save configure -state normal
    }

  }

  ######################################################################
  # Causes the text to be saved.
  proc text_save {w varname} {

    # Clear the modified state
    $w edit modified 0

    # Disable the save button
    [winfo parent $w].bf.save configure -state disabled

    # Set the preferences
    set pref_ui::prefs($varname) [$w get 1.0 end-1c]

  }

  ######################################################################
  # Make a spinbox.
  proc make_sb {w msg varname from to inc {grid 0} {endmsg ""}} {

    variable widgets

    if {$grid} {
      ttk::label ${w}l -text [format "%s: " $msg]
      set win [$widgets(sb) ${w}sb {*}$widgets(sb_opts) -from $from -to $to -increment $inc \
        -width [string length $to] -state readonly -command [list pref_ui::handle_sb_change ${w}sb $varname]]
      set row [get_grid_row ${w}l]
      grid ${w}l  -row $row -column 0 -sticky news -padx 2 -pady 2
      grid ${w}sb -row $row -column 1 -sticky news -padx 2 -pady 2
      if {$endmsg ne ""} {
        grid [ttk::label ${w}l2 -text $endmsg] -row $row -column 2 -sticky news -padx 2 -pady 2
      }
    } else {
      pack [ttk::frame $w] -fill x
      pack [ttk::label $w.l -text [format "%s: " $msg]] -side left -padx 2 -pady 2
      pack [set win [$widgets(sb) $w.sb {*}$widgets(sb_opts) -from $from -to $to -increment $inc \
        -width [string length $to] -state readonly -command [list pref_ui::handle_sb_change $w.sb $varname]]] -side left -padx 2 -pady 2
      if {$endmsg ne ""} {
        pack [ttk::label $w.l2 -text $endmsg] -side left -padx 2 -pady 2
      }
    }

    # Add the widget to the initialize_callbacks array
    register_initialization [list pref_ui::init_sb $win $varname]

    # Register the widget
    register $win $msg $varname

    return $win

  }

  ######################################################################
  # Initializes the given spinbox widget.
  proc init_sb {w varname} {

    $w set $pref_ui::prefs($varname)

  }

  ######################################################################
  # Sets the current spinbox value.
  proc handle_sb_change {w varname} {

    set pref_ui::prefs($varname) [$w get]

  }

  ######################################################################
  # Create a color-picker widget.
  proc make_cp {w msg varname start_color {grid 0}} {

    # Create the bitmap containing the color
    set img [image create bitmap -file [file join $::tke_dir lib images color_box.bmp] -background $start_color -foreground black]

    # Create the widget
    if {$grid} {
      ttk::label ${w}l -text [format "%s: " $msg]
      set win [ttk::button ${w}b -style BButton -image $img -command [list pref_ui::change_cp ${w}b $varname]]
      set row [get_grid_row ${w}l]
      grid ${w}l -row $row -column 0 -sticky news -padx 2 -pady 2
      grid ${w}b -row $row -column 1 -sticky news -padx 2 -pady 2
    } else {
      pack [ttk::label $w] -fill x
      pack [ttk::label $w.l -text [format "%s: " $msg]] -side left -padx 2 -pady 2
      pack [set win [ttk::button $w.b -style BButton -image $img -command [list pref_ui::change_cp $w.b $varname]]] -side left -padx 2 -pady 2
    }

    # Add the widget to the initialize_callbacks array
    register_initialization [list pref_ui::init_cp $win $varname]

    # Register the widget
    register $win $msg $varname

    return $win

  }

  ######################################################################
  # Initializes the given color picker widget.
  proc init_cp {w varname} {

    [$w cget -image] configure -background $pref_ui::prefs($varname)

  }

  ######################################################################
  # Allows the user to change the color for the color picket widget.
  proc change_cp {w varname} {

    # Get the default color
    set color [tk_chooseColor -initialcolor [[$w cget -image] cget -background] -parent .prefwin -title [msgcat::mc "Choose Color"]]

    if {$color ne ""} {
      set pref_ui::prefs($varname) $color
      init_cp $w $varname
    }

  }

  ######################################################################
  # Make a file picker widget.
  proc make_fp {w msg varname type {type_args {}} {grid 0} {help ""}} {

    # Create the widget
    set frame [ttk::labelframe $w -text $msg]
    pack [set win [ttk::label $w.l]] -side left -fill x -padx 2 -pady 2
    pack [ttk::button $w.c -style BButton -text [msgcat::mc "Clear"]                   -command [list pref_ui::fp_clear  $w $varname]]                   -side right -padx 2 -pady 2
    pack [ttk::button $w.b -style BButton -text [format "%s..." [msgcat::mc "Browse"]] -command [list pref_ui::fp_browse $w $varname $type $type_args]] -side right -padx 2 -pady 2

    if {$help ne ""} {
      make_help $w $help
    }

    if {$grid} {
      grid $w -row [get_grid_row $w] -column 0 -sticky news -columnspan 4 -padx 2 -pady 2
    } else {
      pack $w -fill x -padx 2 -pady 2
    }

    # Add the widget to the initialize_callbacks array
    register_initialization [list pref_ui::init_fp $w $varname]

    # Register the widget
    register $win $msg $varname

    return $win

  }

  ######################################################################
  # Initializes the given file picker widget.
  proc init_fp {w varname} {

    $w.l configure -text $pref_ui::prefs($varname)

    if {$pref_ui::prefs($varname) eq ""} {
      $w.c configure -state disabled
    } else {
      $w.c configure -state normal
    }

  }

  ######################################################################
  # Opens the open/save/directory dialog window and updates the given
  # window if it is selected by the user.
  proc fp_browse {win varname type type_args} {

    array set type_args_array $type_args

    set type_args_array(-parent) .prefwin

    # Override the -initialdir value if the value was previously set
    if {[set value [$win.l cget -text]] ne ""} {
      set type_args_array(-initialdir) [file dirname $value]
    }

    switch $type {
      open {
        set type_args_array(-multiple) 0
        set ans [tk_getOpenFile {*}[array get type_args_array]]
      }
      save {
        set type_args_array(-initialfile) $value
        set ans [tk_getOpenFile {*}[array get type_args_array]]
      }
      default {
        set ans [tk_chooseDirectory {*}[array get type_args_array]]
      }
    }

    # Configure the label and set the preference value
    if {$ans ne ""} {
      set pref_ui::prefs($varname) $ans
      init_fp $win $varname
    }

  }

  ######################################################################
  # Clears the contents of the widget.
  proc fp_clear {win varname} {

    # Clear the preference value
    set pref_ui::prefs($varname) ""

    # Set the filepicker state
    init_fp $win $varname

  }

  ######################################################################
  # Creates a simple table widget that allows the user to add, delete
  # and edit table cells that contain text.
  proc make_table {w msg varname columns height {grid 0} {help ""}} {

    set tl_cols [list]
    set cols    [list]

    # Sort out the column information
    foreach column $columns {
      set args [lassign $column title]
      array set opts {
        -width    0
        -type     "text"
        -editable 1
        -value    ""
        -values   {}
      }
      array set opts $args
      lappend cols [array get opts]
      lappend tl_cols $opts(-width) $title
      array unset opts
    }

    ttk::labelframe $w -text $msg
    set win [tablelist::tablelist $w.tl -columns $tl_cols \
      -stretch all -editselectedonly 1 -exportselection 0 -showseparators 1 \
      -height $height -borderwidth 0 -highlightthickness 0 \
      -editstartcommand [list pref_ui::table_edit_start_command $varname $cols] \
      -editendcommand   [list pref_ui::table_edit_end_command $varname $cols] \
      -xscrollcommand   [list utils::set_xscrollbar $w.hb] \
      -yscrollcommand   [list utils::set_yscrollbar $w.vb]]
    scroller::scroller $w.vb -orient vertical   -command [list $w.tl yview]
    scroller::scroller $w.hb -orient horizontal -command [list $w.tl xview]
    ttk::frame $w.bf
    pack [ttk::button $w.bf.add -style BButton -text [msgcat::mc "Add"]    -command [list pref_ui::table_add $win $cols $varname]]              -side left -padx 2 -pady 2
    pack [ttk::button $w.bf.del -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::table_delete $win $varname] -state disabled] -side left -padx 2 -pady 2

    utils::tablelist_configure $win

    for {set i 0} {$i < [$win columncount]} {incr i} {
      array set opts [lindex $cols $i]
      switch $opts(-type) {
        text        { $win columnconfigure $i -editable $opts(-editable) -resizable 1 -stretchable 1 }
        checkbutton { $win columnconfigure $i -editable 0 -resizable 0 -stretchable 0 -formatcommand [list pref_ui::empty_string] }
        menubutton  { $win columnconfigure $i -editable 1 -resizable 0 -stretchable 1 -editwindow menubutton }
      }
    }

    bind $win <<TablelistSelect>>  [list pref_ui::table_selected $win]
    bind [$win bodytag] <Button-1> [list pref_ui::table_left_click %W $cols %x %y $varname]

    grid rowconfigure    $w 1 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid $w.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$w.tl cornerpath] -row 0 -column 1 -sticky news
    grid $w.vb              -row 1 -column 1 -sticky ns
    grid $w.hb              -row 2 -column 0 -sticky ew
    grid $w.bf              -row 3 -column 0 -sticky ew -columnspan 2

    if {$help ne ""} {
      make_help $w $help 1
    }

    if {$grid} {
      grid $w -row [get_grid_row $w] -column 0 -sticky news -columnspan 4 -padx 2 -pady 2
    } else {
      pack $w -fill both -expand yes -padx 2 -pady 2
    }

    # Add the widget to the initialize_callbacks array
    register_initialization [list pref_ui::init_table $win $varname $cols]

    # Register the widget
    register $win $msg $varname

    return $win

  }

  ######################################################################
  # Initialize the table
  proc init_table {w varname cols} {

    # Clear the table
    $w delete 0 end

    # Insert the contents into the table
    foreach row $pref_ui::prefs($varname) {
      $w insert end $row
    }

    # Set checkbutton images, if necessary
    set column 0
    foreach col $cols {
      array set opts $col
      if {$opts(-type) eq "checkbutton"} {
        for {set i 0} {$i < [$w size]} {incr i} {
          $w cellconfigure $i,$column -image [expr {[$w cellcget $i,$column -text] ? "pref_checked" : "pref_unchecked"}]
        }
      }
      incr column
    }

  }

  ######################################################################
  # Adds a new entry to the table and makes the first cell editable.
  proc table_add {w cols varname} {

    set index 0
    set ccols [list]

    # Get the list of values to insert
    foreach col $cols {
      array set opts $col
      lappend values $opts(-value)
      if {$opts(-type) eq "checkbutton"} {
        lappend ccols $index
      }
      incr index
    }

    # Add the entry to the table at the end
    set row [$w insert end $values]

    # Make all of the checkboxes look right
    foreach ccol $ccols {
      $w cellconfigure $row,$ccol -image [expr {[$w cellcget $row,$ccol -text] ? "pref_checked" : "pref_unchecked"}]
    }

    # Make the first cell editable and in view
    $w see $row
    $w editcell $row,0

    # Save the contents to a file in case nothing is edited
    set pref_ui::prefs($varname) [$w get 0 end]

  }

  ######################################################################
  # Deletes the currently selected table row.
  proc table_delete {w varname} {

    # Delete the currently selected row
    $w delete [$w curselection]

    # Disable the delete button
    [winfo parent $w].bf.del configure -state disabled

    # Save the preferences
    set pref_ui::prefs($varname) [$w get 0 end]

  }

  ######################################################################
  # Called when the table is selected.
  proc table_selected {w} {

    [winfo parent $w].bf.del configure -state normal

  }

  ######################################################################
  # Handles a left click on the table.
  proc table_left_clicked {w cols x y varname} {

    lassign [tablelist::convEventFields $w $x $y] tbl x y
    lassign [split [$tbl containingcell $x $y] ,] row col

    if {$row >= 0} {
      array set opts [lindex $cols $col]
      if {$opts(-type) eq "checkbutton"} {
        if {[$tbl cellcget $row,$col -text]} {
          $tbl cellconfigure $row,$col -text 0 -image pref_unchecked
        } else {
          $tbl cellconfigure $row,$col -text 1 -image pref_checked
        }
        set pref_ui::prefs($varname) [$tbl get 0 end]
      }
    }

  }

  ######################################################################
  # Called when a table cell is going to start being edited.
  proc table_edit_start_command {varname cols w row col value} {

    array set opts [lindex $cols $col]

    switch $opts(-type) {
      menubutton {
        set mnu [[$w editwinpath] cget -menu]
        foreach value $opts(-values) {
          $mnu add radiobutton -label $value
        }
      }
    }

    return $value

  }

  ######################################################################
  # Called when a table cell has been edited.
  proc table_edit_end_command {varname cols w row col value} {

    # Get the table contents
    set contents [$w get 0 end]
    lset contents $row $col $value

    # Save the changes to the preferences
    set pref_ui::prefs($varname) $contents

    return $value

  }

  ######################################################################
  # Creates a documentation widget.  This displays textual help information
  # to describe a particular option or otherwise provide helpful information
  # to the user.
  proc make_help {w msg {grid 0}} {

    set win [ttk::frame $w.help[llength [lsearch -all [winfo children $w] $w.help*]]]
    pack [ttk::label $win.t -text "   "]                              -side left -padx 2 -pady 2
    pack [ttk::label $win.l -style HLabel -wraplength 500 -text $msg] -side left -padx 2 -pady 2

    if {$grid} {
      grid $win -row [get_grid_row $win] -column 0 -sticky news -columnspan 4 -padx 2 -pady 2
    } else {
      pack $win -fill x
    }

    return $win

  }

  ######################################################################
  # Sets up the session submenu for the given
  proc populate_session_menu {language} {

    variable widgets
    variable selected_session

    # Delete the current menu
    $widgets(selsmenu) delete 0 end

    # Populate the selection menu
    $widgets(selsmenu) add radiobutton -label [msgcat::mc "None"] -variable pref_ui::selected_session -value [msgcat::mc "None"] -command [list pref_ui::select $selected_session $language [msgcat::mc "None"] $language]
    $widgets(selsmenu) add separator
    foreach name [sessions::get_names] {
      $widgets(selsmenu) add radiobutton -label $name -variable pref_ui::selected_session -value $name -command [list pref_ui::select $selected_session $language $name $language]
    }

  }

  ######################################################################
  # Sets up a select submenu for the given menu information.
  proc populate_lang_menu {session} {

    variable widgets
    variable selected_language

    syntax::populate_syntax_menu $widgets(sellmenu) [list pref_ui::select $session $selected_language $session] pref_ui::selected_language [msgcat::mc "All"] [syntax::get_all_languages]

  }

  ######################################################################
  # Selects the given session language.
  proc select {prev_session prev_language session language {init 0}} {

    variable widgets
    variable prefs
    variable current_panel

    # Disable traces
    catch { trace remove variable pref_ui::prefs {*}[lindex [trace info variable pref_ui::prefs] 0] } rc

    # Check for any changes that we might want to save to another set of preferences
    if {!$init} {
      check_on_close $prev_session $prev_language
    }

    # Update the menubuttons text
    $widgets(select_s) configure -text [format "%s: %s" [msgcat::mc "Session"] $session]
    $widgets(select_l) configure -text [format "%s: %s" [msgcat::mc "Language"] $language]

    # Update the language menu in case the user changed the session
    populate_session_menu $language
    populate_lang_menu    $session

    # Update the snippets table
    if {!$init} {
      snippets_set_language $language
    }

    # Translate the session and language values
    if {$session eq [msgcat::mc "None"]} {
      set session ""
    }
    if {$language eq [msgcat::mc "All"]} {
      set language ""
    }

    # Setup the prefs
    array unset prefs
    array set prefs [preferences::get_loaded $session $language]

    # Initialize the widgets
    if {!$init} {
      initialize_widgets
    }

    # Remove all listed panels
    foreach panel [pack slaves $widgets(panes)] {
      pack forget $panel
    }

    # If we are only changing language information, remove the sidebar and just display the editor pane
    if {$language ne ""} {

      # Display the editor and snippets panes
      if {!$init} {
        if {$session eq ""} {
          foreach panel [list editor snippets documentation] {
            pack $widgets(panes).$panel -fill both -padx 2 -pady 2
          }
          if {($current_panel ne "editor") && ($current_panel ne "snippets") && ($current_panel ne "documentation")} {
            pane_clicked editor
          }
        } else {
          pack $widgets(panes).editor -fill both -padx 2 -pady 2
          pane_clicked editor
        }
        pack forget $widgets(snippets_lang_frame)
      }

      # Otherwise, make sure the entire UI is displayed.
    } else {

      if {!$init} {
        if {$session eq ""} {
          foreach panel [list general appearance editor find sidebar view snippets emmet shortcuts plugins advanced] {
            pack $widgets(panes).$panel -fill both -padx 2 -pady 2
          }
          $widgets(frame).emmet.nb add $widgets(node_aliases)
          $widgets(frame).emmet.nb add $widgets(abbr_aliases)
          pane_clicked $current_panel
        } else {
          foreach panel [list appearance editor find sidebar view emmet] {
            pack $widgets(panes).$panel -fill both -padx 2 -pady 2
          }
          $widgets(frame).emmet.nb hide $widgets(node_aliases)
          $widgets(frame).emmet.nb hide $widgets(abbr_aliases)
          if {($current_panel eq "general")   || \
              ($current_panel eq "snippets")  || \
              ($current_panel eq "shortcuts") || \
              ($current_panel eq "advanced")} {
            pane_clicked appearance
          } else {
            pane_clicked $current_panel
          }
        }
        pack $widgets(snippets_lang_frame) -side right -padx 2 -pady 2
      }

    }

    # Trace on any changes to the preferences variable
    trace add variable pref_ui::prefs write [list pref_ui::handle_prefs_change $session $language]

  }

  ######################################################################
  # Create the preferences window.
  proc create {session language {panel ""} {tab ""}} {

    variable widgets
    variable prefs
    variable selected_session
    variable selected_language

    if {![winfo exists .prefwin]} {

      toplevel     .prefwin
      wm title     .prefwin [msgcat::mc "Preferences"]
      wm transient .prefwin .
      wm protocol  .prefwin WM_DELETE_WINDOW [list pref_ui::destroy_window]
      wm withdraw  .prefwin

      ttk::frame .prefwin.sf
      set widgets(select_s) [ttk::menubutton        .prefwin.sf.sels -menu [set widgets(selsmenu) [menu .prefwin.sf.selectSessionMenu -tearoff 0]]]
      set widgets(select_l) [ttk::menubutton        .prefwin.sf.sell -menu [set widgets(sellmenu) [menu .prefwin.sf.selectLangMenu    -tearoff 0]]]
      set widgets(match_e)  [wmarkentry::wmarkentry .prefwin.sf.e    -width 30 -watermark "Search" -validate key -validatecommand [list pref_ui::perform_search %P]]

      # Initialize the syntax menu
      set selected_session  [expr {($session  eq "") ? [msgcat::mc "None"] : $session}]
      set selected_language [expr {($language eq "") ? [msgcat::mc "All"]  : $language}]
      populate_session_menu $selected_language
      populate_lang_menu $selected_session

      place $widgets(select_s) -relx 0    -rely 0 -relwidth 0.25
      place $widgets(select_l) -relx 0.25 -rely 0 -relwidth 0.25
      pack $widgets(match_e) -side right -padx 2 -pady 2

      ttk::frame     .prefwin.f
      ttk::separator .prefwin.f.hsep -orient horizontal
      set widgets(panes) [ttk::frame .prefwin.f.bf]
      ttk::separator .prefwin.f.vsep -orient vertical
      set widgets(frame) [ttk::frame .prefwin.f.pf]

      set widgets(match_f)  [ttk::frame .prefwin.f.mf]
      set widgets(match_lb) [listbox .prefwin.f.mf.lb -relief flat -height 10 \
        -borderwidth 0 -highlightthickness 0 \
        -yscrollcommand [list utils::set_yscrollbar .prefwin.f.mf.vb]]
      scroller::scroller .prefwin.f.mf.vb -orient vertical -command [list .prefwin.f.mf.lb yview]

      bind [.prefwin.sf.e entrytag] <Return> [list pref_ui::search_select]
      bind [.prefwin.sf.e entrytag] <Escape> [list pref_ui::search_clear]
      bind [.prefwin.sf.e entrytag] <Up>     "::tk::ListboxUpDown $widgets(match_lb) -1; break"
      bind [.prefwin.sf.e entrytag] <Down>   "::tk::ListboxUpDown $widgets(match_lb)  1; break"

      grid rowconfigure    .prefwin.f.mf 0 -weight 1
      grid columnconfigure .prefwin.f.mf 0 -weight 1
      grid .prefwin.f.mf.lb -row 0 -column 0 -sticky news
      grid .prefwin.f.mf.vb -row 0 -column 1 -sticky ns

      grid rowconfigure    .prefwin.f 1 -weight 1
      grid columnconfigure .prefwin.f 2 -weight 1
      grid .prefwin.f.hsep -row 0 -column 0 -sticky ew -columnspan 3
      grid .prefwin.f.bf   -row 1 -column 0 -sticky news
      grid .prefwin.f.vsep -row 1 -column 1 -sticky ns   -padx 15
      grid .prefwin.f.pf   -row 1 -column 2 -sticky news

      pack .prefwin.sf -fill x
      pack .prefwin.f  -fill both -expand yes

      # Select the given session/language information
      select "" "" $selected_session $selected_language 1

      # Create the list of panes
      set panes [list general appearance editor find sidebar view snippets emmet shortcuts plugins documentation advanced]

      # Create and pack each of the panes
      foreach pane $panes {
        ttk::label $widgets(panes).$pane -compound left -image pref_$pane -text [string totitle $pane] -font {-size 14}
        bind $widgets(panes).$pane <Button-1> [list pref_ui::pane_clicked $pane]
        create_$pane [set widgets($pane) [ttk::frame $widgets(frame).$pane]]
      }

      # Initialize widget values
      initialize_widgets

      # Allow the panel dimensions to be calculatable
      update

      # Get the requested panel dimensions
      foreach pane $panes {
        lappend pheights [winfo reqheight $widgets($pane)]
        lappend pwidths  [winfo reqwidth  $widgets($pane)]
        lappend lwidths  [winfo reqwidth  $widgets(panes).$pane]
      }

      # Calculate the geometry
      set win_width  [expr [lindex [lsort -integer $pwidths]  end] + [winfo reqwidth  .prefwin.f.vsep] + [lindex [lsort -integer $lwidths] end]]
      set win_height [expr [lindex [lsort -integer $pheights] end] + [winfo reqheight .prefwin.f.hsep] + [winfo reqheight .prefwin.sf]]
      set win_x      [expr [winfo rootx .] + (([winfo width  .] - $win_width) / 2)]
      set win_y      [expr [winfo rooty .] + (([winfo height .] - $win_height) / 2)]

      # Set the minimum size of the window and center it on the main window
      wm geometry  .prefwin ${win_width}x${win_height}+${win_x}+${win_y}
      wm resizable .prefwin 0 0

      # Emulate a click on the General panel
      if {$language ne ""} {
        if {$session eq ""} {
          foreach item [list editor snippets] {
            pack $widgets(panes).$item -fill both -padx 2 -pady 2
          }
        } else {
          pack $widgets(panes).editor -fill both -padx 2 -pady 2
        }
        if {$panel ne ""} {
          pane_clicked $panel $tab
        } else {
          pane_clicked editor
        }
      } elseif {$session ne ""} {
        foreach item [list appearance editor find sidebar view emmet] {
          pack $widgets(panes).$item -fill both -padx 2 -pady 2
        }
        $widgets(frame).emmet.nb hide $widgets(node_aliases)
        $widgets(frame).emmet.nb hide $widgets(abbr_aliases)
        pane_clicked appearance
      } else {
        foreach item [list general appearance editor find sidebar view snippets emmet shortcuts plugins advanced] {
          pack $widgets(panes).$item -fill both -padx 2 -pady 2
        }
        if {$panel ne ""} {
          pane_clicked $panel $tab
        } else {
          pane_clicked general
        }
      }

      # Give the search panel the focus
      focus .prefwin.sf.e

      # Show the window
      wm deiconify .prefwin

    }

  }


  ######################################################################
  # Called whenever the user clicks on a panel label.
  proc pane_clicked {panel {tab ""}} {

    variable widgets

    # Delete the search text
    $widgets(match_e) delete 0 end

    # Remove the results frame
    catch { place forget $widgets(match_f) }

    # Clear all of the panel selection labels, if necessary
    foreach p [winfo children $widgets(panes)] {
      $p state !active
    }

    # Set the color of the label to the given color
    $widgets(panes).$panel state active

    # Show the panel
    show_panel $panel $tab

  }

  ######################################################################
  # Displays the selected panel in the listbox.
  proc show_selected_panel {} {

    variable widgets

    set selected [$widgets(bar) selection]
    set panel    [string tolower [$widgets(bar) item $selected -text]]

    show_panel $panel

  }

  ######################################################################
  # Shows the given panel in the window.
  proc show_panel {panel {tab ""}} {

    variable widgets
    variable current_panel

    # Remove the current panel
    if {$current_panel ne ""} {
      pack forget $widgets($current_panel)
    }

    # Display the given panel
    pack $widgets($panel) -fill both -expand yes

    # Save the current panel
    set current_panel $panel

    # If a tab is presented, find the tab and display it
    if {($tab ne "") && [winfo exists $widgets($panel).nb]} {
      foreach tab_id [$widgets($panel).nb tabs] {
        if {[string tolower [$widgets($panel).nb tab $tab_id -text]] eq [string tolower $tab]} {
          $widgets($panel).nb select $tab_id
          break
        }
      }
    }

  }

  ######################################################################
  # Called when the preference window is destroyed.
  proc destroy_window {} {

    variable selected_session
    variable selected_language

    # Save any sharing changes (if necessary)
    save_share_changes

    # Check the state of the preferences and, if necessary, ask the user to
    # apply the changes to other preferences
    check_on_close $selected_session $selected_language

    # Kill the window
    destroy .prefwin

  }

  ######################################################################
  # Checks to see if any of the changes could be saved to other preference
  # types.  If so, prompts the user to cross save those values that changed.
  proc check_on_close {session language} {

    variable changes

    # If we are changing language preferences, there are no changes or we are specified
    # to not prompt the user, do nothing
    if {($language ne [msgcat::mc "All"]) || ([array size changes] == 0) || !$pref_ui::prefs(General/PromptCrossSessionSave)} {
      return
    }

    if {$session eq [msgcat::mc "None"]} {

      if {[sessions::current] ne ""} {

        set detail [msgcat::mc "You have changed global preferences which will not be visible because you are currently within a named session."]
        set answer [tk_messageBox -parent .prefwin -icon question -type yesno -message [msgcat::mc "Save changes to current session?"] -detail $detail]

        if {$answer eq "yes"} {
          preferences::save_prefs "" "" [array get changes]
        }

      }

    } else {

      set detail [msgcat::mc "You have changed the current session's preferences which will not be applied globally."]
      set answer [tk_messageBox -parent .prefwin -icon question -type yesno -message [msgcat::mc "Save changes to global preferences?"] -detail $detail]

      if {$answer eq "yes"} {
        preferences::save_prefs [sessions::current] "" [array get changes]
      }

    }

    # Clear the changes
    array unset changes

  }

  ######################################################################
  # Handles any changes to the preference array.
  proc handle_prefs_change {session language name1 name2 op} {

    variable widgets
    variable prefs
    variable changes

    if {[winfo exists .prefwin]} {

      # Track the preferences change
      set changes($name2) $prefs($name2)
      array unset changes General/*
      array unset changes Help/*
      array unset changes Debug/*
      array unset changes Tools/Profile*

      # Save the preferences
      preferences::save_prefs $session $language [array get prefs]

      # Refresh any UI state after the preferences update
      init_mb $widgets(appear_theme) Appearance/Theme [themes::get_visible_themes]

    }

  }

  ######################################################################
  # Display the list of all matches in the dropdown listbox.
  proc show_matches {value} {

    variable widgets
    variable search
    variable selected_language

    if {$selected_language eq [msgcat::mc "All"]} {
      set matches [array names search -regexp (?i).*$request.*::.]
    } else {
      set matches [array names search -regexp (?i).*$request.*::1]
    }

    foreach match $matches {
      lassign $search($match) win lbl plugin tab1 tab2
      set tabs1($tab1) [list $win $lbl]
      if {$tab2 ne ""} {
        set tabs2($tab2) [list $win $lbl]
      }
    }

  }

  ######################################################################
  # Searches the preference window for the given item.
  proc perform_search {value} {

    variable widgets
    variable search
    variable selected_session
    variable selected_language

    set matches [list]

    array set tabs1 [list]

    # Get the list of matches
    if {$value ne ""} {
      if {$selected_language eq [msgcat::mc "All"]} {
        if {$selected_session eq [msgcat::mc "None"]} {
          set matches [array names search -regexp (?i).*$value.*::a.*]
        } else {
          set matches [array names search -regexp (?i).*$value.*::.*b.*]
        }
      } else {
        set matches [array names search -regexp (?i).*$value.*::.*c]
      }
      foreach match $matches {
        lassign $search($match) win lbl plugin tab1 tab2
        set tabs1($tab1) [list $win $lbl]
      }
    }

    # Display the matches
    if {[set match_len [llength $matches]] > 0} {
      $widgets(match_lb) delete 0 end
      foreach match $matches {
        $widgets(match_lb) insert end [lindex [split $match ::] 0]
      }
      $widgets(match_lb) configure -height [expr (($match_len) > 10) ? 10 : $match_len]
      place $widgets(match_f) -relx 0.5 -relwidth 0.5 -rely 0.0
    } else {
      catch { place forget $widgets(match_f) }
    }

    foreach p [winfo children $widgets(panes)] {
      $p state !active
    }

    # Display the tab if there is only one match
    foreach tab [array names tabs1] {
      $tab state active
    }

    # Select the first item in the list
    $widgets(match_lb) see 0
    $widgets(match_lb) selection clear 0 end
    $widgets(match_lb) selection set 0
    $widgets(match_lb) selection anchor 0
    $widgets(match_lb) activate 0

    return 1

  }

  ######################################################################
  # Selects the text in the entry.
  proc search_select {} {

    variable widgets
    variable search

    # Get the selected item
    set selected_value [$widgets(match_lb) get active]

    # Get the information from the matching element
    set key [lindex [array names search ${selected_value}::*] 0]
    lassign $search($key) win lbl plugin tab1 tab2

    # Select the pane containing the item
    pane_clicked [lindex [split $tab1 .] end]

    # If the matched item is within a plugin preference pane, put the pane into view
    if {$plugin ne ""} {
      handle_plugins_change $plugin
    }

    # If the element exists within a notebook tab, display it
    if {$tab2 ne ""} {
      [winfo parent $tab2] select $tab2
    }

    # Select the match text
    $widgets(match_e) selection range 0 end

    # Remove the results frame
    catch { place forget $widgets(match_f) }

    # Give the focus to the matching element
    focus $win

  }

  ######################################################################
  # Clear the search text.
  proc search_clear {} {

    variable widgets
    variable current_panel

    # Delete the search text
    $widgets(match_e) delete 0 end

    # Remove the results frame
    catch { place forget $widgets(match_f) }

    # Make sure that the current tab is selected
    pane_clicked $current_panel

  }

  ######################################################################
  # Registers a search item
  proc register {w str var} {

    variable search

    # Figure out which notebooks
    set insts  [split $w .]
    set tabs   [list]
    set plugin [expr {([lindex $insts 4] eq "plugins") ? [lindex $insts 6] : ""}]
    lappend tabs .prefwin.f.bf.[lindex $insts 4]
    for {set i 3} {$i < [llength $insts]} {incr i} {
      set hier [join [lrange $insts 0 $i] .]
      if {[winfo class $hier] eq "TNotebook"} {
        lappend tabs [join [lrange $insts 0 [expr $i + 1]] .]
      }
    }

    lassign [split $var /] category var

    switch $category {
      General       { set tag a }
      Appearance    { set tag ab }
      Editor        { set tag abc }
      Emmet         { set tag ab }
      Find          { set tag ab }
      Sidebar       { set tag ab }
      View          { set tag ab }
      Shortcuts     { set tag a }
      Plugins       { set tag a }
      Documentation { set tag c }
      Advanced      { set tag a }
      default       { set tag "" }
    }

    set lang_only    [expr {($category eq "Editor") ? 1 : 0}]
    set search(${var}::$tag) [list $w $str $plugin {*}$tabs]

    if {$str ne ""} {
      set search(${str}::$tag) [list $w $str $plugin {*}$tabs]
    }

  }

  ###########
  # GENERAL #
  ###########

  ######################################################################
  # Creates the general panel.
  proc create_general {w} {

    variable widgets
    variable prefs
    variable enable_share
    variable share_changed

    pack [ttk::notebook $w.nb] -fill both -expand yes

    ###############
    # GENERAL TAB #
    ###############

    $w.nb add [set a [ttk::frame $w.nb.a]] -text [msgcat::mc "General"]

    make_cb $a.lls  [msgcat::mc "Automatically load last session on start"]                                      General/LoadLastSession
    make_cb $a.eolc [msgcat::mc "Exit the application after the last tab is closed"]                             General/ExitOnLastClose
    make_cb $a.acwd [msgcat::mc "Automatically set the current working directory to the current tabs directory"] General/AutoChangeWorkingDirectory
    make_cb $a.umtt [msgcat::mc "Show Move To Trash for local files/directories instead of Delete"]              General/UseMoveToTrash
    make_cb $a.pcs  [msgcat::mc "Prompt user to save preference changes in global or named session"]             General/PromptCrossSessionSave

    make_spacer $a

    ttk::frame $a.f
    ttk::label $a.f.dl -text [format "%s: " [set wstr [msgcat::mc "Set default open/save browsing directory to"]]]
    set widgets(browse_mb) [ttk::menubutton $a.f.dmb -menu [menu $a.browMnu -tearoff 0]]
    set widgets(browse_l)  [ttk::label $a.f.dir]

    $a.browMnu add command -label [msgcat::mc "Last accessed"]                    -command [list pref_ui::set_browse_dir "last"]
    $a.browMnu add command -label [msgcat::mc "Current editing buffer directory"] -command [list pref_ui::set_browse_dir "buffer"]
    $a.browMnu add command -label [msgcat::mc "Current working directory"]        -command [list pref_ui::set_browse_dir "current"]
    $a.browMnu add command -label [msgcat::mc "Use directory"]                    -command [list pref_ui::set_browse_dir "dir"]

    # Register the widget for search
    register $widgets(browse_mb) $wstr General/DefaultFileBrowserDirectory

    switch $prefs(General/DefaultFileBrowserDirectory) {
      "last"    { $widgets(browse_mb) configure -text [msgcat::mc "Last"] }
      "buffer"  { $widgets(browse_mb) configure -text [msgcat::mc "Buffer"] }
      "current" { $widgets(browse_mb) configure -text [msgcat::mc "Current"] }
      default   {
        $widgets(browse_mb) configure -text [msgcat::mc "Directory"]
        $widgets(browse_l)  configure -text "     $prefs(General/DefaultFileBrowserDirectory)"
      }
    }

    grid $a.f.dl  -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $a.f.dmb -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $a.f.dir -row 2 -column 0 -sticky news -columnspan 2

    pack $a.f -fill x -padx 2 -pady 2

    #################
    # VARIABLES TAB #
    #################

    $w.nb add [set b [ttk::frame $w.nb.b]] -text [set wstr [msgcat::mc "Variables"]]

    ttk::frame $b.f
    set widgets(var_table) [tablelist::tablelist $b.f.tl \
      -columns [list 0 [msgcat::mc "Variable"] 0 [msgcat::mc "Value"]] \
      -stretch all -editselectedonly 1 -exportselection 0 -showseparators 1 \
      -borderwidth 0 -highlightthickness 0 \
      -height 25 \
      -editendcommand [list pref_ui::var_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $b.f.hb] \
      -yscrollcommand [list utils::set_yscrollbar $b.f.vb]]
    scroller::scroller $b.f.vb -orient vertical   -command [list $b.f.tl yview]
    scroller::scroller $b.f.hb -orient horizontal -command [list $b.f.tl xview]

    utils::tablelist_configure $widgets(var_table)

    $widgets(var_table) columnconfigure 0 -name var -editable 1 -stretchable 1
    $widgets(var_table) columnconfigure 1 -name val -editable 1 -stretchable 1

    bind $widgets(var_table) <<TablelistSelect>> [list pref_ui::handle_var_select]

    grid rowconfigure    $b.f 1 -weight 1
    grid columnconfigure $b.f 0 -weight 1
    grid $b.f.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$b.f.tl cornerpath] -row 0 -column 1 -sticky news
    grid $b.f.vb              -row 1 -column 1 -sticky ns
    grid $b.f.hb              -row 2 -column 0 -sticky ew

    register $widgets(var_table) $wstr General/Variables

    ttk::frame $b.bf
    set widgets(var_add) [ttk::button $b.bf.add -style BButton -text [msgcat::mc "Add"]    -command [list pref_ui::add_variable]]
    set widgets(var_del) [ttk::button $b.bf.del -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::del_variable] -state disabled]

    pack $b.bf.add -side left -padx 2 -pady 2
    pack $b.bf.del -side left -padx 2 -pady 2

    pack $b.f  -fill both -expand yes
    pack $b.bf -fill x

    # Populate the variable table
    foreach row $prefs(General/Variables) {
      $widgets(var_table) insert end $row
    }

    #################
    # LANGUAGES TAB #
    #################

    $w.nb add [set c [ttk::frame $w.nb.c]] -text [set wstr [msgcat::mc "Languages"]]

    set widgets(lang_table) [tablelist::tablelist $c.tl \
      -columns [list 0 [msgcat::mc "Enabled"] 0 [msgcat::mc "Language"] 0 [msgcat::mc "Extensions"]] \
      -stretch all -exportselection 1 -showseparators 1 \
      -height 25 -borderwidth 0 -highlightthickness 0 \
      -editendcommand [list pref_ui::lang_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $c.hb] \
      -yscrollcommand [list utils::set_yscrollbar $c.vb]]
    scroller::scroller $c.vb -orient vertical   -command [list $c.tl yview]
    scroller::scroller $c.hb -orient horizontal -command [list $c.tl xview]

    utils::tablelist_configure $widgets(lang_table)

    $widgets(lang_table) columnconfigure 0 -name enabled -editable 0 -resizable 0 -stretchable 0 -formatcommand [list pref_ui::empty_string]
    $widgets(lang_table) columnconfigure 1 -name lang    -editable 0 -resizable 0 -stretchable 0
    $widgets(lang_table) columnconfigure 2 -name exts    -editable 1 -resizable 1 -stretchable 1

    bind [$widgets(lang_table) bodytag] <Button-1> [list pref_ui::handle_lang_left_click %W %x %y]

    # Register the widget for search
    register $widgets(lang_table) $wstr General/DisabledLanguages
    register $widgets(lang_table) $wstr General/LanguagePatternOverrides

    grid rowconfigure    $c 1 -weight 1
    grid columnconfigure $c 0 -weight 1
    grid $c.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$c.tl cornerpath] -row 0 -column 1 -sticky news
    grid $c.vb              -row 1 -column 1 -sticky ns
    grid $c.hb              -row 2 -column 0 -sticky ew

    # Populate the language table
    populate_lang_table

    ###############
    # SHARING TAB #
    ###############

    $w.nb add [set e [ttk::frame $w.nb.e]] -text [msgcat::mc "Sharing"]

    ttk::frame $e.sf
    set widgets(share_enable) [ttk::checkbutton $e.sf.cb -text [format " %s: " [set wstr [msgcat::mc "Directory"]]] -variable pref_ui::enable_share -command [list pref_ui::handle_share_directory]]
    set widgets(share_entry)  [ttk::entry       $e.sf.e]

    register $widgets(share_enable) $wstr General/ShareDirectory

    pack $e.sf.cb -side left -padx 2 -pady 2
    pack $e.sf.e  -side left -padx 2 -pady 2 -fill x -expand yes

    set widgets(share_items) [ttk::labelframe $e.if -text [set wstr [msgcat::mc "Sharing Items"]]]
    foreach {type nspace name} [share::get_share_items] {
      pack [ttk::checkbutton $e.if.$type -text [format " %s" $name] -variable pref_ui::share_$type -command [list pref_ui::handle_share_change]] -fill x -padx 2 -pady 2
    }

    register $widgets(share_items) $wstr General/ShareItems

    ttk::button $e.export -text [msgcat::mc "Export Settings"] -command [list share::create_export .prefwin]

    pack $e.sf -padx 2 -pady 4 -fill x
    make_spacer $e
    pack $e.if -padx 2 -pady 4 -fill both
    make_spacer $e
    pack $e.export

    # Initialize the sharing UI
    lassign [share::get_share_info] share_dir share_items
    set enable_share [expr {$share_dir ne ""}]
    set share_changed 0
    foreach {type value} $share_items {
      set pref_ui::share_$type $value
    }
    $widgets(share_entry) insert end $share_dir
    $widgets(share_entry) configure -state readonly

    # The updates tab is not valid for Windows
    if {![string match *Win* $::tcl_platform(os)]} {

      ###############
      # UPDATES TAB #
      ###############

      $w.nb add [set d [ttk::frame $w.nb.d]] -text [set wstr [msgcat::mc "Updates"]]

      make_cb $d.ucos [msgcat::mc "Automatically check for updates on start"] General/UpdateCheckOnStart

      ttk::frame $d.f
      ttk::label $d.f.ul -text [format "%s: " [set wstr [msgcat::mc "Update using release type"]]]
      set widgets(upd_mb) [ttk::menubutton $d.f.umb -menu [menu $d.updMnu -tearoff 0]]

      $d.updMnu add radiobutton -label [msgcat::mc "Stable"]      -value "stable" -variable pref_ui::prefs(General/UpdateReleaseType) -command [list pref_ui::set_release_type]
      $d.updMnu add radiobutton -label [msgcat::mc "Development"] -value "devel"  -variable pref_ui::prefs(General/UpdateReleaseType) -command [list pref_ui::set_release_type]

      ttk::button $d.upd -style BButton -text [msgcat::mc "Check for Update"] -command [list menus::check_for_update]

      pack $d.f.ul  -side left -padx 2 -pady 2
      pack $d.f.umb -side left -padx 2 -pady 2
      pack $d.f     -fill x
      pack $d.upd -padx 2 -pady 2

      # Register the widget for search
      register $widgets(upd_mb) $wstr General/UpdateReleaseType

      # Initialize the release type menubutton text
      set_release_type

    }

  }

  ######################################################################
  # Format command.
  proc empty_string {value} {

    return ""

  }

  ######################################################################
  # Sets the update release type to the specified value.
  proc set_release_type {} {

    variable widgets
    variable prefs

    if {$prefs(General/UpdateReleaseType) eq "stable"} {
      $widgets(upd_mb) configure -text [msgcat::mc "Stable"]
    } else {
      $widgets(upd_mb) configure -text [msgcat::mc "Development"]
    }

  }

  ######################################################################
  # Set the browse directory
  proc set_browse_dir {value} {

    variable widgets
    variable prefs

    # Clear the browser label text
    $widgets(browse_l) configure -text ""

    switch $value {
      "last" {
        $widgets(browse_mb) configure -text [msgcat::mc "Last"]
      }
      "buffer" {
        $widgets(browse_mb) configure -text [msgcat::mc "Buffer"]
      }
      "current" {
        $widgets(browse_mb) configure -text [msgcat::mc "Current"]
      }
      default {
        if {[set dir [tk_chooseDirectory -parent .prefwin -title [msgcat::mc "Select default browsing directory"]]] ne ""} {
          $widgets(browse_mb) configure -text [msgcat::mc "Directory"]
          $widgets(browse_l)  configure -text "     $dir"
          set value $dir
        }
      }
    }

    # Update the preference value
    set prefs(General/DefaultFileBrowserDirectory) $value

  }

  ######################################################################
  # When a row is selected, set the delete button state to normal.
  proc handle_var_select {} {

    variable widgets

    # Enable the delete button
    if {[$widgets(var_table) curselection] eq ""} {
      $widgets(var_del) configure -state disabled
    } else {
      $widgets(var_del) configure -state normal
    }

  }

  ######################################################################
  # Adds a variable to the end of the variable table.
  proc add_variable {} {

    variable widgets

    # Clear the selection and disable the delete button
    $widgets(var_table) selection clear 0 end
    $widgets(var_del)   configure -state disabled

    # Add the new variable line
    set row [$widgets(var_table) insert end [list "" ""]]

    # Make the first entry to be editable
    $widgets(var_table) editcell $row,var

  }

  ######################################################################
  # Deletes the currently selected variable from the variable table.
  proc del_variable {} {

    variable widgets

    set selected [$widgets(var_table) curselection]

    # Delete the row
    $widgets(var_table) delete $selected

    # Disable the delete button
    $widgets(var_del) configure -state disabled

    # Update the General/Variable array value
    gather_var_table

  }

  ######################################################################
  # Called after the user has edited the variable table cell.
  proc var_edit_end_command {tbl row col value} {

    after 1 [list pref_ui::gather_var_table]

    return $value

  }

  ######################################################################
  # Gather the variable table values from the table and update the
  # preferences array.
  proc gather_var_table {} {

    variable widgets
    variable prefs

    set values [list]

    for {set i 0} {$i < [$widgets(var_table) size]} {incr i} {
      if {([set var [$widgets(var_table) cellcget $i,var -text]] ne "") && \
      ([set val [$widgets(var_table) cellcget $i,val -text]] ne "")} {
        lappend values [list $var $val]
      } else {
        return
      }
    }

    set prefs(General/Variables) $values

  }

  ######################################################################
  # Populates the language table with information from syntax and the
  # preferences file.
  proc populate_lang_table {} {

    variable widgets
    variable prefs

    # Get the list of languages to disable
    set dis_langs $prefs(General/DisabledLanguages)

    # Get the extension overrides
    array set orides $prefs(General/LanguagePatternOverrides)

    # Add all of the languages
    foreach lang [lsort [syntax::get_all_languages]] {
      set enabled  [expr [lsearch $dis_langs $lang] == -1]
      set patterns [syntax::get_file_patterns $lang]
      if {[info exists orides($lang)]} {
        foreach pattern $orides($lang) {
          if {[string index $pattern 0] eq "+"} {
            lappend patterns [string range $pattern 1 end]
          } elseif {[set index [lsearch -exact $patterns [string range $pattern 1 end]]] != -1} {
            set patterns [lreplace $patterns $index $index]
          }
        }
      }
      set row [$widgets(lang_table) insert end [list $enabled $lang $patterns]]
      if {$enabled} {
        $widgets(lang_table) cellconfigure $row,enabled -image pref_checked
      } else {
        $widgets(lang_table) cellconfigure $row,enabled -image pref_unchecked
      }
    }

  }

  ######################################################################
  # Handles any left-clicks on the language table.
  proc handle_lang_left_click {w x y} {

    variable prefs

    lassign [tablelist::convEventFields $w $x $y] tbl x y
    lassign [split [$tbl containingcell $x $y] ,] row col

    if {$row >= 0} {
      if {$col == 0} {
        set lang [$tbl cellcget $row,lang -text]
        if {[$tbl cellcget $row,$col -text]} {
          $tbl cellconfigure $row,$col -text 0 -image pref_unchecked
          lappend prefs(General/DisabledLanguages) $lang
        } else {
          $tbl cellconfigure $row,$col -text 1 -image pref_checked
          set index [lsearch $prefs(General/DisabledLanguages) $lang]
          set prefs(General/DisabledLanguages) [lreplace $prefs(General/DisabledLanguages) $index $index]
        }
      }
    }

  }

  ######################################################################
  # Save the contents to the preference file.
  proc lang_edit_end_command {tbl row col value} {

    variable prefs

    set lang     [$tbl cellcget $row,lang -text]
    set patterns [syntax::get_file_patterns $lang]

    set lang_oride [list]
    foreach pattern $patterns {
      if {[lsearch -exact $value $pattern] == -1} {
        lappend lang_oride "-$pattern"
      }
    }
    foreach val $value {
      if {[lsearch -exact $patterns $val] == -1} {
        lappend lang_oride "+$val"
      }
    }
    array set pref_orides $prefs(General/LanguagePatternOverrides)
    if {[llength $lang_oride] == 0} {
      unset pref_orides($lang)
    } else {
      set pref_orides($lang) $lang_oride
    }
    set prefs(General/LanguagePatternOverrides) [array get pref_orides]

    return $value

  }

  ######################################################################
  # Handles any changes to the share directory checkbutton.
  proc handle_share_directory {} {

    variable widgets
    variable enable_share

    if {$enable_share} {
      if {[set share_dir [tk_chooseDirectory -parent .prefwin -title [msgcat::mc "Select Settings Sharing Directory"]]] eq ""} {
        set enable_share 0
      } else {
        $widgets(share_entry) configure -state normal
        $widgets(share_entry) delete 0 end
        $widgets(share_entry) insert end $share_dir
        $widgets(share_entry) configure -state readonly
        handle_share_change
      }
    } else {
      $widgets(share_entry) configure -state normal
      $widgets(share_entry) delete 0 end
      $widgets(share_entry) configure -state readonly
      handle_share_change
    }

  }

  ######################################################################
  # Called whenever a share value changes.
  proc handle_share_change {} {

    variable share_changed

    set share_changed 1

  }

  ######################################################################
  # Handles any changes to the sharing item checkbuttons.
  proc save_share_changes {} {

    variable widgets
    variable share_changed

    if {$share_changed} {

      # Gather the items
      set items [list]
      foreach {type nspace name} [share::get_share_items] {
        if {[set pref_ui::share_$type]} {
          lappend items $type
        }
      }

      # Save the changes
      share::save_changes [$widgets(share_entry) get] $items

    }

  }

  ##############
  # APPEARANCE #
  ##############

  ######################################################################
  # Creates the appearance panel.
  proc create_appearance {w} {

    variable widgets
    variable colorizers
    variable prefs

    pack [ttk::notebook $w.nb] -fill both -expand yes

    ###########
    # GENERAL #
    ###########

    $w.nb add [set a [ttk::frame $w.nb.a]] -text [msgcat::mc "General"]

    ttk::frame $a.f
    set widgets(appear_theme) [make_mb $a.f.th [msgcat::mc "Default theme"] Appearance/Theme [themes::get_visible_themes] 1]
    make_sb $a.f.icw [msgcat::mc "Insertion cursor width"]          Appearance/CursorWidth      1  5 1 1
    make_sb $a.f.els [msgcat::mc "Additional space between lines"]  Appearance/ExtraLineSpacing 0 10 1 1

    ttk::labelframe $a.cf -text [set wstr [msgcat::mc "Syntax Coloring"]]

    # Pack the colorizer frame
    set i 0
    set colorize $prefs(Appearance/Colorize)
    foreach type [lsort [array names colorizers]] {
      set colorizers($type) [expr {[lsearch $colorize $type] != -1}]
      grid [ttk::checkbutton $a.cf.$type -text " $type" -variable pref_ui::colorizers($type) -command [list pref_ui::set_colorizers]] -row [expr $i % 3] -column [expr $i / 3] -sticky news -padx 2 -pady 2
      incr i
    }

    # Register the widget
    register $a.cf.$type $wstr Appearance/Colorize

    # Create fonts frame
    ttk::labelframe $a.ff -text [msgcat::mc "Fonts"]
    ttk::label  $a.ff.l0  -text [format "%s: " [msgcat::mc "Editor"]]
    ttk::label  $a.ff.f0  -text "AaBbCc0123" -font $prefs(Appearance/EditorFont)
    ttk::button $a.ff.b0  -style BButton -text [msgcat::mc "Choose"] -command [list pref_ui::set_font $a.ff.f0 [msgcat::mc "Select Editor Font"] Appearance/EditorFont 1]
    ttk::label  $a.ff.l1  -text [format "%s: " [msgcat::mc "Command launcher entry"]]
    ttk::label  $a.ff.f1  -text "AaBbCc0123" -font $prefs(Appearance/CommandLauncherEntryFont)
    ttk::button $a.ff.b1  -style BButton -text [msgcat::mc "Choose"] -command [list pref_ui::set_font $a.ff.f1 [msgcat::mc "Select Command Launcher Entry Font"] Appearance/CommandLauncherEntryFont 0]
    ttk::label  $a.ff.l2  -text [format "%s: " [msgcat::mc "Command launcher preview"]]
    ttk::label  $a.ff.f2  -text "AaBbCc0123" -font $prefs(Appearance/CommandLauncherPreviewFont)
    ttk::button $a.ff.b2  -style BButton -text [msgcat::mc "Choose"] -command [list pref_ui::set_font $a.ff.f2 [msgcat::mc "Select Command Launcher Preview Font"] Appearance/CommandLauncherPreviewFont 0]

    # Register the widgets for search
    register $a.ff.b0 "" Appearance/EditorFont
    register $a.ff.b1 "" Appearance/CommandLauncherEntryFont
    register $a.ff.b2 "" Appearance/CommandLauncherPreviewFont

    grid columnconfigure $a.ff 1 -weight 1
    grid $a.ff.l0 -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $a.ff.f0 -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $a.ff.b0 -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $a.ff.l1 -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $a.ff.f1 -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $a.ff.b1 -row 1 -column 2 -sticky news -padx 2 -pady 2
    grid $a.ff.l2 -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $a.ff.f2 -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid $a.ff.b2 -row 2 -column 2 -sticky news -padx 2 -pady 2

    pack $a.f  -fill x -padx 2 -pady 2
    make_spacer $a
    pack $a.cf -fill x -padx 2 -pady 4
    make_spacer $a
    pack $a.ff -fill x -padx 2 -pady 4

    make_spacer $a
    make_cb $a.cl_pos [msgcat::mc "Remember last position of command launcher"] Appearance/CommandLauncherRememberLastPosition

    ##########
    # THEMES #
    ##########

    $w.nb add [set b [ttk::frame $w.nb.b]] -text [msgcat::mc "Manage Themes"]

    ttk::frame $b.tf
    set widgets(themes_tl) [tablelist::tablelist $b.tf.tl \
      -columns [list 0 [msgcat::mc "Name"] 0 [msgcat::mc "Visible"] center 0 [msgcat::mc "Imported"] center 0 [msgcat::mc "Creator"] 0 [msgcat::mc "Date"]] \
      -exportselection 0 -stretch all -borderwidth 0 -highlightthickness 0 \
      -labelcommand tablelist::sortByColumn \
      -xscrollcommand [list utils::set_xscrollbar $b.tf.hb] \
      -yscrollcommand [list utils::set_yscrollbar $b.tf.vb]]
    scroller::scroller $b.tf.vb -orient vertical   -command [list $b.tf.tl yview]
    scroller::scroller $b.tf.hb -orient horizontal -command [list $b.tf.tl xview]

    utils::tablelist_configure $b.tf.tl

    $widgets(themes_tl) columnconfigure 0 -name name     -editable 0
    $widgets(themes_tl) columnconfigure 1 -name visible  -editable 0 -stretchable 0 -resizable 0 -formatcommand [list pref_ui::themes_format_visible]
    $widgets(themes_tl) columnconfigure 2 -name imported -editable 0 -stretchable 0 -resizable 0 -formatcommand [list pref_ui::themes_format_imported]
    $widgets(themes_tl) columnconfigure 3 -name creator  -editable 0
    $widgets(themes_tl) columnconfigure 4 -name date     -editable 0 -formatcommand [list pref_ui::themes_format_date]

    bind $widgets(themes_tl)           <<TablelistSelect>> [list pref_ui::themes_selected]
    bind [$widgets(themes_tl) bodytag] <Button-1>          [list pref_ui::themes_left_click %W %x %y]

    grid rowconfigure    $b.tf 1 -weight 1
    grid columnconfigure $b.tf 0 -weight 1
    grid $b.tf.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$b.tf.tl cornerpath] -row 0 -column 1 -sticky news
    grid $b.tf.vb              -row 1 -column 1 -sticky ns
    grid $b.tf.hb              -row 2 -column 0 -sticky ew

    ttk::frame  $b.bf
    ttk::button $b.bf.add  -style BButton -text [msgcat::mc "Add"]  -command [list pref_ui::themes_add]
    set widgets(themes_del)  [ttk::button $b.bf.del  -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::themes_delete] -state disabled]
    set widgets(themes_edit) [ttk::button $b.bf.edit -style BButton -text [msgcat::mc "Edit"]   -command [list pref_ui::themes_edit] -state disabled]
    ttk::button $b.bf.more -style BButton -text [format "%s..." [msgcat::mc "Get More Themes"]] -command [list pref_ui::themes_get_more]

    pack $b.bf.add  -side left  -padx 2 -pady 2
    pack $b.bf.del  -side left  -padx 2 -pady 2
    pack $b.bf.edit -side left  -padx 2 -pady 2
    pack $b.bf.more -side right -padx 2 -pady 2

    pack $b.tf -fill both -expand yes
    pack $b.bf -fill x

    # Register the Appearance/HiddenThemes preference
    register $widgets(themes_tl) [msgcat::mc "Manage theme visibility"] Appearance/HiddenThemes

    # Populate the themes table
    themes_populate_table

  }

  ######################################################################
  # Update the Appearance/Colorize preference value to the selected
  # colorizer array.
  proc set_colorizers {} {

    variable colorizers
    variable prefs

    # Get the list of selected colorizers
    set colorize [list]
    foreach {name value} [array get colorizers] {
      if {$value} {
        lappend colorize $name
      }
    }

    # Set the preference array
    set prefs(Appearance/Colorize) [lsort $colorize]

  }

  ######################################################################
  # Sets the given font preference.
  proc set_font {lbl title varname mono} {

    variable prefs

    set opts [list]
    if {$mono} {
      lappend opts -mono 1 -styles Regular
    }

    # Select the new font
    if {[set new_font [fontchooser -parent .prefwin -title $title -initialfont [$lbl cget -font] -effects 0 {*}$opts]] ne ""} {
      $lbl configure -font $new_font
      set prefs($varname) $new_font
    }

  }

  ######################################################################
  # Displays the visibility value.
  proc themes_format_visible {value} {

    return ""

  }

  ######################################################################
  # Displays the imported value.
  proc themes_format_imported {value} {

    return ""

  }

  ######################################################################
  # Displays the version value.
  proc themes_format_date {value} {

    if {$value ne ""} {
      return [clock format $value -format "%D"]
    }

    return ""

  }

  ######################################################################
  # Populates the themes table with the list of existing themes.
  proc themes_populate_table {} {

    variable widgets

    # If the preference window is not currently being shown, return immediately
    if {![info exists widgets(themes_tl)] || ![winfo exists $widgets(themes_tl)]} {
      return
    }

    # Clear the table
    $widgets(themes_tl) delete 0 end

    # Add the current themes to the table
    foreach name [themes::get_all_themes] {
      set visible  [expr [lsearch [themes::get_visible_themes] $name] != -1]
      set imported [themes::get_imported $name]
      array set attrs [themes::get_attributions $name]
      set row [$widgets(themes_tl) insert end [list $name $visible $imported $attrs(creator) $attrs(date)]]
      if {$visible} {
        $widgets(themes_tl) cellconfigure $row,visible -image pref_checked
      } else {
        $widgets(themes_tl) cellconfigure $row,visible -image pref_unchecked
      }
      if {$imported} {
        $widgets(themes_tl) cellconfigure $row,imported -image pref_check
      }
    }

    # Make sure that the state of the disable button is disabled since nothing will be selected
    $widgets(themes_del) configure -state disabled

  }

  ######################################################################
  # Called whenever the selection state of the themes table changes.
  proc themes_selected {} {

    variable widgets

    # Update the state of the deletion button
    if {([set selected [$widgets(themes_tl) curselection]] eq "") || \
        ([$widgets(themes_tl) cellcget $selected,imported -text] == 0) || \
        ([$widgets(themes_tl) cellcget $selected,name -text] eq [theme::get_current_theme])} {
      $widgets(themes_del) configure -state disabled
    } else {
      $widgets(themes_del) configure -state normal
    }

    # Update the state of the edit button
    if {$selected eq ""} {
      $widgets(themes_edit) configure -state disabled
    } else {
      $widgets(themes_edit) configure -state normal
    }

  }

  ######################################################################
  # Handles a left-click on the themes table.  If the user clicked on the
  # visibility cell, toggle the image value and update the HiddenThemes
  # preference.
  proc themes_left_click {W x y} {

    variable prefs

    lassign [tablelist::convEventFields $W $x $y] tbl x y
    lassign [split [$tbl containingcell $x $y] ,] row col

    if {$row != -1} {
      if {[$tbl columncget $col -name] eq "visible"} {
        set name  [$tbl cellcget $row,name    -text]
        set value [$tbl cellcget $row,visible -text]
        if {$value} {
          $tbl cellconfigure $row,visible -text 0 -image pref_unchecked
          lappend prefs(Appearance/HiddenThemes) $name
        } else {
          $tbl cellconfigure $row,visible -text 1 -image pref_checked
          if {[set index [lsearch -exact $prefs(Appearance/HiddenThemes) $name]] != -1} {
            set prefs(Appearance/HiddenThemes) [lreplace $prefs(Appearance/HiddenThemes) $index $index]
          }
        }
      }
    }

  }

  ######################################################################
  # Adds a new theme from the file system, importing it if necessary.
  proc themes_add {} {

    # Allow the user to select a theme to import
    if {[themer::import .prefwin]} {

      # Update the themes table
      themes_populate_table

    }

  }

  ######################################################################
  # Removes a theme from the file system.
  proc themes_delete {} {

    variable widgets
    variable prefs

    # Get the currently selected theme
    set selected [$widgets(themes_tl) curselection]
    set name     [$widgets(themes_tl) cellcget $selected,name -text]

    # Confirm with the user
    if {[tk_messageBox -parent .prefwin -type yesno -default no -message [format "%s %s %s?" [msgcat::mc "Delete"] $name [msgcat::mc "theme"]]] eq "no"} {
      return
    }

    # Delete the theme
    themes::delete_theme $name

    # Remove the theme from the hidden list so that we don't confuse the user if they reload the
    # theme.
    if {[set index [lsearch -exact $prefs(Appearance/HiddenThemes) $name]] != -1} {
      set prefs(Appearance/HiddentThemes) [lreplace $prefs(Appearance/HiddenThemes) $index $index]
    }

    # Update the themes table
    themes_populate_table

  }

  ######################################################################
  # Edits the selected theme.
  proc themes_edit {} {

    variable widgets

    # Get the selected theme
    set selected [$widgets(themes_tl) curselection]

    # Make sure that the theme editor is opened
    themer::preview_theme [$widgets(themes_tl) cellcget $selected,name -text]

  }

  ######################################################################
  # Sends the user to the themes webpage to find/download more themes.
  proc themes_get_more {} {

    utils::open_file_externally "http://tke.sourceforge.net/themes.html"

  }

  ##########
  # EDITOR #
  ##########

  ######################################################################
  # Creates the editor panel.
  proc create_editor {w} {

    variable widgets
    variable match_chars
    variable snip_compl
    variable prefs

    ttk::frame $w.sf
    make_sb $w.sf.ww  [msgcat::mc "Ruler column"]                                  Editor/WarningWidth          20 150  5 1
    make_sb $w.sf.spt [msgcat::mc "Spaces per tab"]                                Editor/SpacesPerTab           1  20  1 1
    make_sb $w.sf.is  [msgcat::mc "Indentation spaces"]                            Editor/IndentSpaces           1  20  1 1
    make_sb $w.sf.mu  [msgcat::mc "Maximum undo history (set to 0 for unlimited)"] Editor/MaxUndo                0 200 10 1
    make_sb $w.sf.chd [msgcat::mc "Clipboard history depth"]                       Editor/ClipboardHistoryDepth  1  30  1 1
    make_sb $w.sf.vml [msgcat::mc "Line count to find Vim modeline information"]   Editor/VimModelines           0  20  1 1

    ttk::label $w.sf.eoll -text [format "%s: " [set wstr [msgcat::mc "End-of-line character when saving"]]]
    set widgets(editor_eolmb) [ttk::menubutton $w.sf.eolmb -menu [menu $w.sf.eol -tearoff 0]]

    make_mb $w.sf.lna [msgcat::mc "Line number alignment"] Editor/LineNumberAlignment [list left right] 1

    foreach {value desc} [list \
      auto [msgcat::mc "Use original EOL character from file"] \
      sys  [msgcat::mc "Use appropriate EOL character on system"] \
      cr   [msgcat::mc "Use single carriage return character"] \
      crlf [msgcat::mc "Use carriate return linefeed sequence"] \
      lf   [msgcat::mc "Use linefeed character"]] {
      $w.sf.eol add radiobutton -label $desc -value $value -variable pref_ui::prefs(Editor/EndOfLineTranslation) -command [list pref_ui::set_eol_translation]
    }

    register $widgets(editor_eolmb) $wstr Editor/EndOfLineTranslation

    grid $w.sf.eoll  -row 7 -column 0 -sticky news -padx 2 -pady 2
    grid $w.sf.eolmb -row 7 -column 1 -sticky news -padx 2 -pady 2

    ttk::labelframe $w.mcf -text [set wstr [msgcat::mc "Auto-match Characters"]]
    ttk::checkbutton $w.mcf.sr -text [format " %s" [msgcat::mc "Square bracket"]] -variable pref_ui::match_chars(square) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.cu -text [format " %s" [msgcat::mc "Curly bracket"]]  -variable pref_ui::match_chars(curly)  -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.an -text [format " %s" [msgcat::mc "Angled bracket"]] -variable pref_ui::match_chars(angled) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.pa -text [format " %s" [msgcat::mc "Parenthesis"]]    -variable pref_ui::match_chars(paren)  -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.dq -text [format " %s" [msgcat::mc "Double-quote"]]   -variable pref_ui::match_chars(double) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.sq -text [format " %s" [msgcat::mc "Single-quote"]]   -variable pref_ui::match_chars(single) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.bt -text [format " %s" [msgcat::mc "Backtick"]]       -variable pref_ui::match_chars(btick)  -command [list pref_ui::set_match_chars]

    register $w.mcf.sr $wstr Editor/AutoMatchChars

    grid columnconfigure $w.mcf 1 -weight 1
    grid columnconfigure $w.mcf 3 -weight 1
    grid columnconfigure $w.mcf 5 -weight 1
    grid $w.mcf.sr -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mcf.cu -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $w.mcf.an -row 0 -column 4 -sticky news -padx 2 -pady 2
    grid $w.mcf.pa -row 0 -column 6 -sticky news -padx 2 -pady 2
    grid $w.mcf.dq -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mcf.sq -row 1 -column 2 -sticky news -padx 2 -pady 2
    grid $w.mcf.bt -row 1 -column 4 -sticky news -padx 2 -pady 2

    ttk::frame $w.cf
    make_cb $w.cf.vm   [msgcat::mc "Enable Vim Mode"]                              Editor/VimMode
    make_cb $w.cf.eai  [msgcat::mc "Enable auto-indentation"]                      Editor/EnableAutoIndent
    make_cb $w.cf.hmc  [msgcat::mc "Automatically highlight matching bracket"]     Editor/HighlightMatchingChar
    make_cb $w.cf.hmmb [msgcat::mc "Automatically highlight mismatching brackets"] Editor/HighlightMismatchingChar
    make_cb $w.cf.rtw  [msgcat::mc "Remove trailing whitespace on save"]           Editor/RemoveTrailingWhitespace
    make_cb $w.cf.rln  [msgcat::mc "Enable relative line numbering"]               Editor/RelativeLineNumbers

    pack $w.sf  -fill x -padx 2 -pady 2
    make_spacer $w
    pack $w.mcf -fill x -padx 2 -pady 2
    make_spacer $w
    pack $w.cf  -fill x -padx 2 -pady 2

    # Set the UI state to match preference
    foreach char [list square curly angled paren double single btick] {
      set match_chars($char) [expr {[lsearch $prefs(Editor/AutoMatchChars) $char] != -1}]
    }

    foreach char [list space tab return] {
      set snip_compl($char) [expr {[lsearch $prefs(Editor/SnippetCompleters) $char] != -1}]
    }

    set_eol_translation

  }

  ######################################################################
  # Set the matching chars to the Editor/AutoMatchChars preference value.
  proc set_match_chars {} {

    variable match_chars
    variable prefs

    set mchars [list]
    foreach char [list square curly angled paren double single btick] {
      if {$match_chars($char)} {
        lappend mchars $char
      }
    }

    set prefs(Editor/AutoMatchChars) $mchars

  }

  ######################################################################
  # Set the snippet completers to the Editor/SnippetCompleters preference
  # value.
  proc set_snip_compl {} {

    variable snip_compl
    variable prefs

    set schars [list]
    foreach char [list space tab return] {
      if {$snip_compl($char)} {
        lappend schars $char
      }
    }

    set prefs(Editor/SnippetCompleters) $schars

  }

  ######################################################################
  # Sets the EOL translation menubutton text to the given value
  proc set_eol_translation {} {

    variable widgets
    variable prefs

    $widgets(editor_eolmb) configure -text $prefs(Editor/EndOfLineTranslation)

  }

  #########
  # EMMET #
  #########

  ######################################################################
  # Creates the Emmet panel.
  proc create_emmet {w} {

    variable widgets
    variable prefs

    ttk::notebook $w.nb

    ###########
    # GENERAL #
    ###########

    $w.nb add [set a [ttk::frame $w.nb.gf]] -text [msgcat::mc "General"]

    make_cb $a.aivp [msgcat::mc "Automatically insert vendor prefixes"] Emmet/CSSAutoInsertVendorPrefixes
    make_cb $a.cs   [msgcat::mc "Use shortened colors"]                 Emmet/CSSColorShort
    make_cb $a.fs   [msgcat::mc "Enable fuzzy search"]                  Emmet/CSSFuzzySearch

    make_spacer $a

    ttk::frame $a.of
    ttk::label $a.of.ccl -text [format "%s: " [set wstr [msgcat::mc "Color value case"]]]
    set widgets(emmet_ccmb) [ttk::menubutton $a.of.ccmb -menu [menu $a.of.ccmb_mnu -tearoff 0]]

    foreach {value lbl} [list upper [msgcat::mc "Convert to uppercase"] \
                              lower [msgcat::mc "Convert to lowercase"] \
                              keep  [msgcat::mc "Retain case"]] {
      $a.of.ccmb_mnu add radiobutton -label $lbl -value $value -variable pref_ui::prefs(Emmet/CSSColorCase) -command [list pref_ui::set_css_color_case]
    }

    register $widgets(emmet_ccmb) $wstr Emmet/CSSColorCase

    pack $a.of.ccl  -side left -padx 2 -pady 2
    pack $a.of.ccmb -side left -padx 2 -pady 2
    pack $a.of      -fill x

    make_spacer $a
    make_entry $a.iu [msgcat::mc "Default unit for integer values"]        Emmet/CSSIntUnit        ""
    make_entry $a.fu [msgcat::mc "Default unit for floating point values"] Emmet/CSSFloatUnit      ""
    make_entry $a.vs [msgcat::mc "Symbol between CSS property and value"]  Emmet/CSSValueSeparator ""
    make_entry $a.pe [msgcat::mc "Symbol placed at end of CSS property"]   Emmet/CSSPropertyEnd    ""

    ##########
    # ADDONS #
    ##########

    $w.nb add [set b [ttk::frame $w.nb.af]] -text [msgcat::mc "Addons"]

    foreach {type var} {
      Mozilla Emmet/CSSMozPropertiesAddon \
      MS      Emmet/CSSMSPropertiesAddon \
      Opera   Emmet/CSSOPropertiesAddon \
      Webkit  Emmet/CSSWebkitPropertiesAddon} {
      make_token $b.[string tolower $type] [format "$type %s" [msgcat::mc "Properties"]] $var ""
    }

    ################
    # NODE ALIASES #
    ################

    $w.nb add [set widgets(node_aliases) [set c [ttk::frame $w.nb.nf]]] -text [set wstr [msgcat::mc "Node Aliases"]]

    ttk::frame $c.tf
    set widgets(emmet_na_tl) [tablelist::tablelist $c.tf.tl \
      -columns [list 0 [msgcat::mc "Alias"] 0 [msgcat::mc "Node"] 0 [msgcat::mc "Closing"] 0 [msgcat::mc "Attributes"]] \
      -exportselection 0 -editselectedonly 1 -stretch all \
      -borderwidth 0 -highlightthickness 0 \
      -editstartcommand [list pref_ui::emmet_na_edit_start_command] \
      -editendcommand   [list pref_ui::emmet_na_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $c.tf.hb] \
      -yscrollcommand [list utils::set_yscrollbar $c.tf.vb]]
    scroller::scroller $c.tf.vb -orient vertical   -command [list $widgets(emmet_na_tl) yview]
    scroller::scroller $c.tf.hb -orient horizontal -command [list $widgets(emmet_na_tl) xview]

    $widgets(emmet_na_tl) columnconfigure 0 -name alias  -editable 1 -stretchable 1 -resizable 1
    $widgets(emmet_na_tl) columnconfigure 1 -name name   -editable 1 -stretchable 1 -resizable 1
    $widgets(emmet_na_tl) columnconfigure 2 -name ending -editable 1 -stretchable 0 -resizable 1 \
      -editwindow ttk::menubutton
    $widgets(emmet_na_tl) columnconfigure 3 -name attrs  -editable 1 -stretchable 1 -resizable 1

    bind $widgets(emmet_na_tl) <<TablelistSelect>> [list pref_ui::handle_emmet_na_select]

    grid rowconfigure    $c.tf 1 -weight 1
    grid columnconfigure $c.tf 0 -weight 1
    grid $c.tf.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$c.tf.tl cornerpath] -row 0 -column 1 -sticky news
    grid $c.tf.vb              -row 1 -column 1 -sticky ns
    grid $c.tf.hb              -row 2 -column 0 -sticky ew

    ttk::frame $c.bf
    ttk::button $c.bf.add -style BButton -text [msgcat::mc "Add"] -command [list pref_ui::emmet_na_add]
    set widgets(emmet_na_del) [ttk::button $c.bf.del -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::emmet_na_del] -state disabled]

    pack $c.bf.add -side left -padx 2 -pady 2
    pack $c.bf.del -side left -padx 2 -pady 2

    ttk::labelframe $c.lf -text [msgcat::mc "Preview"]
    frame $c.lf.f
    set widgets(emmet_na_preview) [ctext $c.lf.f.t -height 10 -state disabled \
      -theme [theme::get_syntax_colors] \
      -xscrollcommand [list $c.lf.f.hb set] -yscrollcommand [list $c.lf.f.vb set]]
    scroller::scroller $c.lf.f.vb -orient vertical   -autohide 1 -command [list $c.lf.f.t yview]
    scroller::scroller $c.lf.f.hb -orient horizontal -autohide 0 -command [list $c.lf.f.t xview]

    theme::register_widget $widgets(emmet_na_preview) syntax
    theme::register_widget $c.lf.f.vb text_scrollbar
    theme::register_widget $c.lf.f.hb text_scrollbar

    indent::add_bindings $widgets(emmet_na_preview)
    syntax::set_language $widgets(emmet_na_preview) "HTML"

    # This is needed to keep the modified event from being handled by the editing buffers
    bind $widgets(emmet_na_preview) <<Modified>> "break"

    grid rowconfigure    $c.lf.f 0 -weight 1
    grid columnconfigure $c.lf.f 0 -weight 1
    grid $c.lf.f.t  -row 0 -column 0 -sticky news
    grid $c.lf.f.vb -row 0 -column 1 -sticky ns
    grid $c.lf.f.hb -row 1 -column 0 -sticky ew

    pack $c.lf.f -fill both -expand yes

    pack $c.tf -padx 2 -pady 2 -fill both -expand yes
    pack $c.bf -padx 2 -pady 2 -fill x
    pack [ttk::separator $c.sep -orient horizontal] -padx 2 -pady 2 -fill x -expand yes
    pack $c.lf -padx 2 -pady 2 -fill x

    register $c.tf.tl $wstr Emmet/NodeAliases

    ########################
    # ABBREVIATION ALIASES #
    ########################

    $w.nb add [set widgets(abbr_aliases) [set d [ttk::frame $w.nb.vf]]] -text [set wstr [msgcat::mc "Abbreviation Aliases"]]

    ttk::frame $d.tf
    set widgets(emmet_aa_tl) [tablelist::tablelist $d.tf.tl \
      -columns [list 0 [msgcat::mc "Alias"] 0 [msgcat::mc "Value"]] \
      -exportselection 0 -stretch all -editselectedonly 1 \
      -borderwidth 0 -highlightthickness 0 \
      -editendcommand [list pref_ui::emmet_aa_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $d.tf.hb] \
      -yscrollcommand [list utils::set_yscrollbar $d.tf.vb]]
    scroller::scroller $d.tf.vb -orient vertical   -command [list $d.tf.tl yview]
    scroller::scroller $d.tf.hb -orient horizontal -command [list $d.tf.tl xview]

    $widgets(emmet_aa_tl) columnconfigure 0 -name alias -editable 1 -resizable 1 -stretchable 0
    $widgets(emmet_aa_tl) columnconfigure 1 -name value -editable 1 -resizable 1 -stretchable 1

    bind $widgets(emmet_aa_tl) <<TablelistSelect>> [list pref_ui::handle_emmet_aa_select]

    grid rowconfigure    $d.tf 1 -weight 1
    grid columnconfigure $d.tf 0 -weight 1
    grid $d.tf.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$d.tf.tl cornerpath] -row 0 -column 1 -sticky news
    grid $d.tf.vb              -row 1 -column 1 -sticky ns
    grid $d.tf.hb              -row 2 -column 0 -sticky ew

    ttk::frame $d.bf
    ttk::button $d.bf.add -style BButton -text [msgcat::mc "Add"] -command [list pref_ui::emmet_aa_add]
    set widgets(emmet_aa_del) [ttk::button $d.bf.del -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::emmet_aa_del] -state disabled]

    pack $d.bf.add -side left -padx 2 -pady 2
    pack $d.bf.del -side left -padx 2 -pady 2

    ttk::labelframe $d.lf -text [msgcat::mc "Preview"]
    frame $d.lf.f
    set widgets(emmet_aa_preview) [ctext $d.lf.f.t -height 10 -state disabled \
      -theme [theme::get_syntax_colors] \
      -xscrollcommand [list $d.lf.f.hb set] -yscrollcommand [list $d.lf.f.vb set]]
    scroller::scroller $d.lf.f.vb -orient vertical   -autohide 1 -command [list $d.lf.f.t yview]
    scroller::scroller $d.lf.f.hb -orient horizontal -autohide 0 -command [list $d.lf.f.t xview]

    theme::register_widget $widgets(emmet_aa_preview) syntax
    theme::register_widget $d.lf.f.vb text_scrollbar
    theme::register_widget $d.lf.f.hb text_scrollbar

    indent::add_bindings $widgets(emmet_aa_preview)
    syntax::set_language $widgets(emmet_aa_preview) "HTML"

    # This is needed to keep the modified event from being handled by the editing buffers
    bind $widgets(emmet_aa_preview) <<Modified>> "break"

    grid rowconfigure    $d.lf.f 0 -weight 1
    grid columnconfigure $d.lf.f 0 -weight 1
    grid $d.lf.f.t  -row 0 -column 0 -sticky news
    grid $d.lf.f.vb -row 0 -column 1 -sticky ns
    grid $d.lf.f.hb -row 1 -column 0 -sticky ew

    pack $d.lf.f -fill both -expand yes

    pack $d.tf -padx 2 -pady 2 -fill both -expand yes
    pack $d.bf -padx 2 -pady 2 -fill x
    pack [ttk::separator $d.sep -orient horizontal] -padx 2 -pady 2 -fill x -expand yes
    pack $d.lf -padx 2 -pady 2 -fill x

    register $d.tf.tl $wstr Emmet/AbbreviationAliases

    pack $w.nb -fill both -expand yes

    # Initialize the UI state
    set_css_color_case
    set_aliases

  }

  ######################################################################
  # Update the UI state to match the value of Emmet/CSSColorCase.
  proc set_css_color_case {} {

    variable widgets
    variable prefs

    $widgets(emmet_ccmb) configure -text $prefs(Emmet/CSSColorCase)

  }

  ######################################################################
  # Adds the Emmet aliases information to the UI.
  proc set_aliases {} {

    variable widgets

    # Retrieve the aliases from the Emmet namespace
    array set aliases [emmet::get_aliases]

    array set endings {
      0 <x/>
      1 <x></x>
      2 None
    }

    # Add the node aliases
    array set node_aliases $aliases(node_aliases)
    foreach alias [lsort [array names node_aliases]] {
      lassign $node_aliases($alias) name ending attrs
      set attr_value [list]
      foreach {attr value} $attrs {
        lappend attr_value "$attr=\"$value\""
      }
      $widgets(emmet_na_tl) insert end [list $alias $name $endings($ending) [join $attr_value]]
    }

    # Add the abbreviation aliases
    array set abbr_aliases $aliases(abbreviation_aliases)
    foreach alias [lsort [array names abbr_aliases]] {
      $widgets(emmet_aa_tl) insert end [list $alias $abbr_aliases($alias)]
    }


  }
  ######################################################################
  # Called when a cell is started to be edited.
  proc emmet_na_edit_start_command {tbl row col value} {

    if {[$tbl columncget $col -name] eq "ending"} {
      set w   [$tbl editwinpath]
      set mnu [$w cget -menu]
      $mnu delete 0 end
      foreach type [list <x/> <x></x> None] {
        $mnu add radiobutton -label $type
      }
    }

    return $value

  }

  ######################################################################
  # Called when a cell has completed being edited.
  proc emmet_na_edit_end_command {tbl row col value} {

    # Get the row contents
    lassign [$tbl rowcget $row -text] alias name ending attrs

    set curr_alias $alias

    # Replace the equality sign in the attrs list with a space
    set attrs [string map {= { }} $attrs]

    array set endings {
      <x/>    0
      <x></x> 1
      None    2
    }

    switch [$tbl columncget $col -name] {
      alias  { set alias  $value }
      name   { set name   $value }
      ending { set ending $value }
      attrs  { set attrs  [string map {= { }} $value] }
    }

    # Save the alias if it's worth saving
    if {$name ne ""} {
      emmet::update_alias node_aliases $curr_alias $alias [list $name $endings($ending) $attrs]
    }

    # Display the generated code
    emmet_na_show_preview $alias

    return $value

  }

  ######################################################################
  # Show the given string value in the preview text.
  proc emmet_na_show_preview {alias} {

    variable widgets

    $widgets(emmet_na_preview) configure -state normal
    $widgets(emmet_na_preview) delete 1.0 end

    # Get the alias data
    lassign [emmet::lookup_node_alias $alias] name ending attrs

    if {$name ne ""} {

      # Construct the node
      set str "<$name"
      foreach {attr value} $attrs {
        append str " $attr=\"$value\""
      }
      switch $ending {
        0 { append str " />" }
        1 { append str "></$name>" }
        2 { append str ">" }
      }

      set index 1
      while {[regexp {(.*?)\{\|(.*?)\}(.*)$} $str -> before value after]} {
        if {$value eq ""} {
          set str "$before\$$index$after"
        } else {
          set str "$before\${$index:$value}$after"
        }
        incr index
      }

      # Insert the resulting string as a snippet
      snippets::insert_snippet $widgets(emmet_na_preview).t $str -traverse 0

    }

    $widgets(emmet_na_preview) configure -state disabled

  }

  ######################################################################
  # Handles a change to the abbreviation table selection.
  proc handle_emmet_na_select {} {

    variable widgets

    # Get the current selection
    set selected [$widgets(emmet_na_tl) curselection]

    if {$selected ne ""} {
      $widgets(emmet_na_del) configure -state normal
    } else {
      $widgets(emmet_na_del) configure -state disabled
    }

    # Update the preview
    emmet_na_show_preview [$widgets(emmet_na_tl) cellcget $selected,alias -text]

  }

  ######################################################################
  # Adds a new row to the abbreviation alias table.
  proc emmet_na_add {} {

    variable widgets

    # Add a new row to the table
    set row [$widgets(emmet_na_tl) insert end [list "" "" <x></x> ""]]

    # Make the first entry to be editable
    $widgets(emmet_na_tl) editcell $row,alias

  }

  ######################################################################
  # Deletes the currently selected row
  proc emmet_na_del {} {

    variable widgets

    # Get the currently selected row
    set selected [$widgets(emmet_na_tl) curselection]

    # Get the aliased name
    set alias_name [$widgets(emmet_na_tl) cellcget $selected,alias -text]

    # Delete the item
    $widgets(emmet_na_tl) delete $selected

    # Set the state of the delete button to disabled
    $widgets(emmet_na_del) configure -state disabled

    # Save the deletion
    emmet::update_alias node_aliases $alias_name "" ""

  }

  ######################################################################
  # Show the given string value in the preview text.
  proc emmet_aa_show_preview {str} {

    variable widgets

    set retval 0

    $widgets(emmet_aa_preview) configure -state normal
    $widgets(emmet_aa_preview) delete 1.0 end

    if {![catch { ::parse_emmet $str "" } str]} {
      snippets::insert_snippet $widgets(emmet_aa_preview).t $str -traverse 0
      set retval 1
    }

    $widgets(emmet_aa_preview) configure -state disabled

    return $retval

  }

  ######################################################################
  # Handles any changes to column editing in the Emmet abbreviation table.
  proc emmet_aa_edit_end_command {tbl row col value} {

    variable widgets

    switch [$tbl columncget $col -name] {
      alias {
        set alias_value [$tbl cellcget $row,value -text]
        if {![catch { ::parse_emmet $alias_value "" }]} {
          emmet::update_alias abbreviation_aliases [$tbl cellcget $row,$col -text] $value $alias_value
        }
      }
      value {
        set alias_name [$tbl cellcget $row,alias -text]
        if {[emmet_aa_show_preview $value] && ($alias_name ne "")} {
          emmet::update_alias abbreviation_aliases $alias_name $alias_name $value
        }
      }
    }

    return $value

  }

  ######################################################################
  # Handles a change to the abbreviation table selection.
  proc handle_emmet_aa_select {} {

    variable widgets

    # Get the current selection
    set selected [$widgets(emmet_aa_tl) curselection]

    if {$selected ne ""} {
      $widgets(emmet_aa_del) configure -state normal
    } else {
      $widgets(emmet_aa_del) configure -state disabled
    }

    # Update the preview
    emmet_aa_show_preview [$widgets(emmet_aa_tl) cellcget $selected,value -text]

  }

  ######################################################################
  # Adds a new row to the abbreviation alias table.
  proc emmet_aa_add {} {

    variable widgets

    # Add a new row to the table
    set row [$widgets(emmet_aa_tl) insert end [list "" ""]]

    # Make the first entry to be editable
    $widgets(emmet_aa_tl) editcell $row,alias

  }

  ######################################################################
  # Deletes the currently selected row
  proc emmet_aa_del {} {

    variable widgets

    # Get the currently selected row
    set selected [$widgets(emmet_aa_tl) curselection]

    # Get the aliased name
    set alias_name [$widgets(emmet_aa_tl) cellcget $selected,alias -text]

    # Delete the item
    $widgets(emmet_aa_tl) delete $selected

    # Set the state of the delete button to disabled
    $widgets(emmet_aa_del) configure -state disabled

    # Save the deletion
    emmet::update_alias abbreviation_aliases $alias_name "" ""

  }

  ########
  # FIND #
  ########

  ######################################################################
  # Creates the find panel.
  proc create_find {w} {

    variable widgets
    variable prefs

    make_sb $w.mh  [msgcat::mc "Set find history depth"]         Find/MaxHistory   0 100 10 1
    make_sb $w.cn  [msgcat::mc "Set Find in Files line context"] Find/ContextNum   0  10  1 1
    make_sb $w.jd  [msgcat::mc "Set jump distance"]              Find/JumpDistance 1  20  1 1
    make_mb $w.dsm [msgcat::mc "Default search method"]          Find/DefaultMethod {regexp glob exact} 1

  }

  ###########
  # SIDEBAR #
  ###########

  ######################################################################
  # Creates the sidebar panel.
  proc create_sidebar {w} {

    variable widgets
    variable prefs
    variable attributes

    ttk::notebook $w.nb

    #################
    # BEHAVIORS TAB #
    #################

    $w.nb add [set a [ttk::frame $w.nb.a]] -text [msgcat::mc "Behaviors"]

    make_cb $a.rralc [msgcat::mc "Remove root directory after last sub-file is closed"] Sidebar/RemoveRootAfterLastClose
    make_cb $a.fat   [msgcat::mc "Show folders at top"] Sidebar/FoldersAtTop
    make_cb $a.nat   [msgcat::mc "Insert unsorted files at the top of a manually sorted directory"] Sidebar/ManualInsertNewAtTop
    make_spacer $a
    make_sb $a.kst   [msgcat::mc "Append characters to search string if entered within"] Sidebar/KeySearchTimeout 100 3000 100 0 [msgcat::mc "milliseconds"]

    ##############
    # HIDING TAB #
    ##############

    $w.nb add [set b [ttk::frame $w.nb.b]] -text [msgcat::mc "Hiding"]

    make_cb     $b.shf [msgcat::mc "Show hidden files"] Sidebar/ShowHiddenFiles
    make_cb     $b.ib  [msgcat::mc "Hide binary files"] Sidebar/IgnoreBinaries
    make_spacer $b
    set win [make_token $b.hp [msgcat::mc "Hide Patterns"] Sidebar/IgnoreFilePatterns ""]
    $win configure -height 6

    ##################
    # INFO PANEL TAB #
    ##################

    $w.nb add [set c [ttk::frame $w.nb.c]] -text [set wstr [msgcat::mc "Info Panel"]]

    make_cb $c.kfiv [msgcat::mc "Keep information panel visible when sidebar doesn't have focus"] Sidebar/KeepInfoPanelVisible
    make_cb $c. [msgcat::mc "Update information panel whenever the sidebar selection changes"] Sidebar/InfoPanelFollowsSelection
    make_spacer $c
    make_sb $c.rtwpm [msgcat::mc "Reading time words per minute"] Sidebar/InfoPanelReadingTimeWordsPerMinute 100 400 5
    make_spacer $c

    ttk::labelframe $c.if -text [set wstr [msgcat::mc "Displayed Information"]]

    grid columnconfigure $c.if 1 -weight 1
    grid columnconfigure $c.if 3 -weight 1
    grid columnconfigure $c.if 5 -weight 1

    # Pack the colorizer frame
    set attrs $prefs(Sidebar/InfoPanelAttributes)
    set i     0
    foreach attr [lsort [array names attributes]] {
      set attributes($attr) [expr {[lsearch $attrs $attr] != -1}]
      set row [expr $i % 4]
      set col [expr ($i / 4) * 2]
      grid [ttk::checkbutton $c.if.$attr -text " $attr" -variable pref_ui::attributes($attr) -command [list pref_ui::set_attributes]] -row $row -column $col -sticky news -padx 2 -pady 2
      incr i
    }

    # Register the widget
    register $c.if.$attr $wstr Sidebar/InfoPanelAttributes

    pack $w.nb.c.if -fill x -padx 2 -pady 2

    pack $w.nb -fill both -expand yes

  }

  ######################################################################
  # Sets the displayed file information attributes preference item.
  proc set_attributes {} {

    variable attributes
    variable prefs

    set attrs [list]
    foreach {attr value} [array get attributes] {
      if {$value} {
        lappend attrs $attr
      }
    }

    set prefs(Sidebar/InfoPanelAttributes) [lsort $attrs]

  }

  ########
  # VIEW #
  ########

  ######################################################################
  # Creates the view panel.
  proc create_view {w} {

    make_cb $w.sm   [msgcat::mc "Show menubar"]                                     View/ShowMenubar
    make_cb $w.ss   [msgcat::mc "Show sidebar"]                                     View/ShowSidebar
    make_cb $w.ssb  [msgcat::mc "Show status bar"]                                  View/ShowStatusBar
    make_cb $w.stb  [msgcat::mc "Show tab bar"]                                     View/ShowTabBar
    make_cb $w.sln  [msgcat::mc "Show line numbers"]                                View/ShowLineNumbers
    make_cb $w.smm  [msgcat::mc "Show marker map"]                                  View/ShowMarkerMap
    make_cb $w.sbe  [msgcat::mc "Show bird's eye view"]                             View/ShowBirdsEyeView
    make_cb $w.sdio [msgcat::mc "Show difference file in other pane than original"] View/ShowDifferenceInOtherPane
    make_cb $w.sdvi [msgcat::mc "Show difference file version information"]         View/ShowDifferenceVersionInfo
    make_cb $w.sfif [msgcat::mc "Show 'Find in Files' result in other pane"]        View/ShowFindInFileResultsInOtherPane
    make_cb $w.ats  [msgcat::mc "Allow scrolling in tab bar"]                       View/AllowTabScrolling
    make_cb $w.ota  [msgcat::mc "Sort tabs alphabetically on open"]                 View/OpenTabsAlphabetically
    make_cb $w.ecf  [msgcat::mc "Enable code folding"]                              View/EnableCodeFolding
    make_cb $w.sls  [msgcat::mc "Show language submenu"]                            View/ShowLanguagesSubmenu

    make_spacer $w

    ttk::frame $w.sf
    make_sb $w.sf.sro  [msgcat::mc "Recently opened history depth"] View/ShowRecentlyOpened    0 20 1 1
    make_sb $w.sf.befs [msgcat::mc "Bird's Eye View Font Size"]     View/BirdsEyeViewFontSize  1  2 1 1
    make_sb $w.sf.bew  [msgcat::mc "Bird's Eye View Width"]         View/BirdsEyeViewWidth    30 80 5 1
    make_mb $w.sf.elw  [msgcat::mc "Line Wrapping Default"]         View/EnableLineWrapping   [list syntax enable disable] 1
    pack $w.sf -fill x -pady 8

  }

  ############
  # SNIPPETS #
  ############

  ######################################################################
  # Create the snippets panel.
  proc create_snippets {w} {

    variable widgets
    variable selected_language

    ttk::notebook $w.nb

    ###############
    # TABLE FRAME #
    ###############

    $w.nb add [ttk::frame $w.sf] -text [msgcat::mc "Snippets"]

    set widgets(snippets_tf) [ttk::frame $w.sf.tf]

    ttk::frame $w.sf.tf.sf
    wmarkentry::wmarkentry $w.sf.tf.sf.e -width 20 -watermark [msgcat::mc "Search Snippets"] \
      -validate key -validatecommand [list pref_ui::snippets_search %P]

    set widgets(snippets_lang_frame) [ttk::frame $w.sf.tf.sf.lf]
    ttk::label $w.sf.tf.sf.lf.l -text [msgcat::mc "Language"]
    set widgets(snippets_lang) [ttk::menubutton $w.sf.tf.sf.lf.mb -text [msgcat::mc "Language"] \
      -menu [pref_ui::snippets_create_menu $w]]

    pack $w.sf.tf.sf.lf.l  -side left -padx 2 -pady 2
    pack $w.sf.tf.sf.lf.mb -side left -padx 2 -pady 2

    pack $w.sf.tf.sf.e  -side left  -padx 2 -pady 2
    pack $w.sf.tf.sf.lf -side right -padx 2 -pady 2

    ttk::frame $w.sf.tf.tf
    set widgets(snippets_tl) [tablelist::tablelist $w.sf.tf.tf.tl \
      -columns [list 0 [msgcat::mc "Keyword"] 0 [msgcat::mc "Snippet"]] \
      -exportselection 0 -stretch all -borderwidth 0 -highlightthickness 0 \
      -xscrollcommand [list utils::set_xscrollbar $w.sf.tf.tf.hb] \
      -yscrollcommand [list utils::set_yscrollbar $w.sf.tf.tf.vb]]
    scroller::scroller $w.sf.tf.tf.vb -orient vertical   -command [list $w.sf.tf.tf.tl yview]
    scroller::scroller $w.sf.tf.tf.hb -orient horizontal -command [list $w.sf.tf.tf.tl xview]

    utils::tablelist_configure $widgets(snippets_tl)

    $widgets(snippets_tl) columnconfigure 0 -name keyword -editable 0 -resizable 0 -stretchable 0
    $widgets(snippets_tl) columnconfigure 1 -name snippet -editable 0 -resizable 1 -stretchable 1 \
      -wrap 0 -maxwidth 50 -formatcommand pref_ui::snippets_format_snippet

    bind $widgets(snippets_tl)           <<TablelistSelect>> [list pref_ui::snippets_select]
    bind [$widgets(snippets_tl) bodytag] <Double-Button-1>   [list pref_ui::snippets_edit]

    grid rowconfigure    $w.sf.tf.tf 1 -weight 1
    grid columnconfigure $w.sf.tf.tf 0 -weight 1
    grid $w.sf.tf.tf.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$w.sf.tf.tf.tl cornerpath] -row 0 -column 1 -sticky news
    grid $w.sf.tf.tf.vb              -row 1 -column 1 -sticky ns
    grid $w.sf.tf.tf.hb              -row 2 -column 0 -sticky ew

    ttk::frame  $w.sf.tf.bf
    ttk::button $w.sf.tf.bf.add -style BButton -text [msgcat::mc "Add"] -command [list pref_ui::snippets_add]
    set widgets(snippets_del) [ttk::button $w.sf.tf.bf.del -style BButton -text [msgcat::mc "Delete"] \
      -command [list pref_ui::snippets_del] -state disabled]

    pack $w.sf.tf.bf.add -side left -padx 2 -pady 2
    pack $w.sf.tf.bf.del -side left -padx 2 -pady 2

    pack $w.sf.tf.sf -fill x
    pack $w.sf.tf.tf -fill both -expand yes
    pack $w.sf.tf.bf -fill x

    ##############
    # EDIT FRAME #
    ##############

    set widgets(snippets_ef) [ttk::frame $w.sf.ef]

    ttk::frame $w.sf.ef.kf
    ttk::label $w.sf.ef.kf.l -text [format "%s: " [msgcat::mc "Keyword"]]
    set widgets(snippets_keyword) [ttk::entry $w.sf.ef.kf.e -validate key -validatecommand [list pref_ui::snippets_keyword_changed %P]]

    pack $w.sf.ef.kf.l -side left -padx 2 -pady 2
    pack $w.sf.ef.kf.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::labelframe $w.sf.ef.tf -text [msgcat::mc "Snippet Text"]
    frame $w.sf.ef.tf.tf
    set widgets(snippets_text) [ctext $w.sf.ef.tf.tf.t -wrap none \
      -theme [theme::get_syntax_colors] \
      -xscrollcommand [list $w.sf.ef.tf.tf.hb set] -yscrollcommand [list $w.sf.ef.tf.tf.vb set]]
    scroller::scroller $w.sf.ef.tf.tf.vb -orient vertical   -autohide 1 -command [list $w.sf.ef.tf.tf.t yview]
    scroller::scroller $w.sf.ef.tf.tf.hb -orient horizontal -autohide 0 -command [list $w.sf.ef.tf.tf.t xview]

    bind $widgets(snippets_text) <<Modified>> [list if {[pref_ui::snippets_text_changed]} break]

    theme::register_widget $widgets(snippets_text) syntax
    theme::register_widget $w.sf.ef.tf.tf.vb text_scrollbar
    theme::register_widget $w.sf.ef.tf.tf.hb text_scrollbar

    indent::add_bindings $widgets(snippets_text)

    set modifier [expr {([tk windowingsystem] eq "aqua") ? "Command" : "Control"}]

    bind $widgets(snippets_text) <$modifier-c> {
      %W copy
      break
    }
    bind $widgets(snippets_text) <$modifier-x> {
      %W cut
      break
    }
    bind $widgets(snippets_text) <$modifier-v> {
      %W paste
      break
    }

    grid rowconfigure    $w.sf.ef.tf.tf 0 -weight 1
    grid columnconfigure $w.sf.ef.tf.tf 0 -weight 1
    grid $w.sf.ef.tf.tf.t  -row 0 -column 0 -sticky news
    grid $w.sf.ef.tf.tf.vb -row 0 -column 1 -sticky ns
    grid $w.sf.ef.tf.tf.hb -row 1 -column 0 -sticky ew

    pack $w.sf.ef.tf.tf -fill both -expand yes

    ttk::frame  $w.sf.ef.bf
    set widgets(snippets_ins)  [ttk::button $w.sf.ef.bf.insert -style BButton -text [msgcat::mc "Insert"] -width 6 -command [list pref_ui::snippets_insert]]
    set widgets(snippets_save) [ttk::button $w.sf.ef.bf.save -style BButton -text [msgcat::mc "Save"] \
      -width 6 -command [list pref_ui::snippets_save] -state disabled]
    ttk::button $w.sf.ef.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command [list pref_ui::snippets_cancel]

    pack $w.sf.ef.bf.insert -side left  -padx 2 -pady 2
    pack $w.sf.ef.bf.cancel -side right -padx 2 -pady 2
    pack $w.sf.ef.bf.save   -side right -padx 2 -pady 2

    pack $w.sf.ef.kf -fill x
    pack $w.sf.ef.tf -fill both -expand yes
    pack $w.sf.ef.bf -fill x

    # Display the table frame
    pack $w.sf.tf -fill both -expand yes

    # Setup the snippet insert menu
    set widgets(snippets_ins_menu) [menu $w.sf.insPopup -tearoff 0]
    $widgets(snippets_ins_menu) add cascade -label [format "%s / %s" [msgcat::mc "Date"] [msgcat::mc "Time"]] -menu [menu $w.sf.datePopup -tearoff 0]
    $widgets(snippets_ins_menu) add cascade -label [msgcat::mc "File"] -menu [menu $w.sf.filePopup -tearoff 0]
    $widgets(snippets_ins_menu) add separator
    $widgets(snippets_ins_menu) add command -label [msgcat::mc "Selected Text"]     -command [list pref_ui::snippets_insert_str "\$SELECTED_TEXT"]
    $widgets(snippets_ins_menu) add command -label [msgcat::mc "Clipboard"]         -command [list pref_ui::snippets_insert_str "\$CLIPBOARD"]
    $widgets(snippets_ins_menu) add command -label [msgcat::mc "Clipboard History"] -command [list pref_ui::snippets_insert_str "\$CLIPHIST\[1\]"]
    $widgets(snippets_ins_menu) add separator
    $widgets(snippets_ins_menu) add command -label [msgcat::mc "Tab Stop"]          -command [list pref_ui::snippets_insert_str "\${1}"]
    $widgets(snippets_ins_menu) add command -label [msgcat::mc "Cursor"]            -command [list pref_ui::snippets_insert_str "\${0}"]

    # Setup the date/time submenu
    $w.sf.datePopup add command -label "01/13/2001" -command [list pref_ui::snippets_insert_str "\$CURRENT_DATE"]
    $w.sf.datePopup add command -label "2001/01/13" -command [list pref_ui::snippets_insert_str "\$CURRENT_DATE2"]
    $w.sf.datePopup add command -label "01:01 PM"   -command [list pref_ui::snippets_insert_str "\$CURRENT_TIME"]
    $w.sf.datePopup add separator
    $w.sf.datePopup add command -label "Jan"        -command [list pref_ui::snippets_insert_str "\$CURRENT_MON"]
    $w.sf.datePopup add command -label "January"    -command [list pref_ui::snippets_insert_str "\$CURRENT_MONTH"]
    $w.sf.datePopup add command -label " 1"         -command [list pref_ui::snippets_insert_str "\$CURRENT_MON1"]
    $w.sf.datePopup add command -label "01"         -command [list pref_ui::snippets_insert_str "\$CURRENT_MON2"]
    $w.sf.datePopup add separator
    $w.sf.datePopup add command -label "Mon"        -command [list pref_ui::snippets_insert_str "\$CURRENT_DAYN"]
    $w.sf.datePopup add command -label "Monday"     -command [list pref_ui::snippets_insert_str "\$CURRENT_DAYNAME"]
    $w.sf.datePopup add command -label "1"          -command [list pref_ui::snippets_insert_str "\$CURRENT_DAY1"]
    $w.sf.datePopup add command -label "01"         -command [list pref_ui::snippets_insert_str "\$CURRENT_DAY2"]
    $w.sf.datePopup add separator
    $w.sf.datePopup add command -label "01"         -command [list pref_ui::snippets_insert_str "\$CURRENT_YEAR2"]
    $w.sf.datePopup add command -label "2001"       -command [list pref_ui::snippets_insert_str "\$CURRENT_YEAR"]

    # Setup the file submenu
    $w.sf.filePopup add command -label [msgcat::mc "Current Directory"]     -command [list pref_ui::snippets_insert_str "\$DIRECTORY"]
    $w.sf.filePopup add command -label [msgcat::mc "Current File Pathname"] -command [list pref_ui::snippets_insert_str "\$FILEPATH"]
    $w.sf.filePopup add command -label [msgcat::mc "Current Filename"]      -command [list pref_ui::snippets_insert_str "\$FILENAME"]
    $w.sf.filePopup add separator
    $w.sf.filePopup add command -label [msgcat::mc "Current Line"]          -command [list pref_ui::snippets_insert_str "\$CURRENT_LINE"]
    $w.sf.filePopup add command -label [msgcat::mc "Current Word"]          -command [list pref_ui::snippets_insert_str "\$CURRENT_WORD"]
    $w.sf.filePopup add separator
    $w.sf.filePopup add command -label [msgcat::mc "Current Line Number"]   -command [list pref_ui::snippets_insert_str "\$LINE_NUMBER"]
    $w.sf.filePopup add command -label [msgcat::mc "Current Line Column"]   -command [list pref_ui::snippets_insert_str "\$LINE_INDEX"]

    # Populate the snippets table
    snippets_set_language $selected_language

    ##################
    # COMPLETERS TAB #
    ##################

    $w.nb add [ttk::frame $w.nb.opt] -text [msgcat::mc "Options"]

    ttk::labelframe $w.nb.opt.scf -text [set wstr [msgcat::mc "Snippet Completion Characters"]]
    pack [ttk::checkbutton $w.nb.opt.scf.s -text [format " %s" [msgcat::mc "Space"]]  -variable pref_ui::snip_compl(space)  -command [list pref_ui::set_snip_compl]] -fill x -padx 2 -pady 2
    pack [ttk::checkbutton $w.nb.opt.scf.t -text [format " %s" [msgcat::mc "Tab"]]    -variable pref_ui::snip_compl(tab)    -command [list pref_ui::set_snip_compl]] -fill x -padx 2 -pady 2
    pack [ttk::checkbutton $w.nb.opt.scf.r -text [format " %s" [msgcat::mc "Return"]] -variable pref_ui::snip_compl(return) -command [list pref_ui::set_snip_compl]] -fill x -padx 2 -pady 2

    register $w.nb.opt.scf.s $wstr Editor/SnippetCompleters

    pack $w.nb.opt.scf -fill x -padx 2 -pady 2

    make_spacer $w.nb.opt
    make_cb $w.nb.opt.sfai [msgcat::mc "Format snippet indentation after insert"] Editor/SnippetFormatAfterInsert

    pack $w.nb -fill both -expand yes

  }

  ######################################################################
  # Format the given snippet
  proc snippets_format_snippet {value} {

    set lines [split $value \n]

    if {[llength $lines] <= 4} {
      return [join $lines \n]
    } else {
      return [join [concat [lrange $lines 0 2] ...] \n]
    }

  }

  ######################################################################
  # Performs real-time search of the snippet table.
  proc snippets_search {value} {

    variable widgets

    if {$value eq ""} {
      for {set i 0} {$i < [$widgets(snippets_tl) size]} {incr i} {
        $widgets(snippets_tl) rowconfigure $i -hide 0
      }
    } else {
      for {set i 0} {$i < [$widgets(snippets_tl) size]} {incr i} {
        if {[string match -nocase "*$value*" [$widgets(snippets_tl) cellcget $i,keyword -text]] || \
            [string match -nocase "*$value*" [$widgets(snippets_tl) cellcget $i,snippet -text]]} {
          $widgets(snippets_tl) rowconfigure $i -hide 0
        } else {
          $widgets(snippets_tl) rowconfigure $i -hide 1
        }
      }
    }

    return 1

  }

  ######################################################################
  # Handles a change of selection in the snippets table.  Basically, this
  # just causes the delete button to be enabled.
  proc snippets_select {} {

    variable widgets

    if {[$widgets(snippets_tl) curselection] eq ""} {
      $widgets(snippets_del) configure -state disabled
    } else {
      $widgets(snippets_del) configure -state normal
    }

  }

  ######################################################################
  # Adds a new snippet.
  proc snippets_add {} {

    variable widgets
    variable snip_data

    # Indicate that the current type of snippet editing is an add
    set snip_data(edit_type) "add"

    # Set the selected syntax
    syntax::set_language $widgets(snippets_text) $snip_data(lang)

    # Display the editing frame
    pack forget $widgets(snippets_tf)
    pack $widgets(snippets_ef) -fill both -expand yes

    # Place the focus on the keyword entry field
    focus $widgets(snippets_keyword)

  }

  ######################################################################
  # Edits the currently selected snippet in the table.
  proc snippets_edit {} {

    variable widgets
    variable snip_data

    # Get the currently selected row
    set selected [$widgets(snippets_tl) curselection]

    # Indicate that the current type of snippet editing is an edit
    set snip_data(edit_type) "edit"
    set snip_data(edit_row)  $selected

    # Display the editing frame
    pack forget $widgets(snippets_tf)
    pack $widgets(snippets_ef) -fill both -expand yes

    # Insert the widget information in the entry and text fields
    $widgets(snippets_keyword) insert end [$widgets(snippets_tl) cellcget $selected,keyword -text]
    $widgets(snippets_text)    insert end [$widgets(snippets_tl) cellcget $selected,snippet -text]

    # Disable the save button
    $widgets(snippets_save) configure -state disabled

    # Place the focus on the text widget
    focus $widgets(snippets_text).t

  }

  ######################################################################
  # Deletes the currently selected row in the table and performs a save
  # operation.
  proc snippets_del {} {

    variable widgets

    # Get the currently selected row
    set selected [$widgets(snippets_tl) curselection]

    # Get the snippet keyword
    set keyword [$widgets(snippets_tl) cellcget $selected,keyword -text]

    # Ask the user if they really want to delete the entry
    set ans [tk_messageBox -parent .prefwin -type okcancel -default cancel -icon question \
      -message [format "%s %s" [msgcat::mc "Delete snippet"] $keyword]]

    if {$ans eq "ok"} {
      $widgets(snippets_tl) delete $selected
      snippets_save_table
    }

  }

  ######################################################################
  # Create the language menu.
  proc snippets_create_menu {w} {

    variable widgets

    # Create the menu
    set widgets(snippets_lang_menu) [menu $w.langPopup -tearoff 0]

    # Populate the menu
    syntax::populate_syntax_menu $widgets(snippets_lang_menu) pref_ui::snippets_set_language pref_ui::snip_data(lang) "All" [syntax::get_all_languages]

    return $widgets(snippets_lang_menu)

  }

  ######################################################################
  # Sets the current language.
  proc snippets_set_language {lang} {

    variable widgets
    variable snip_data

    # Save the snippets data
    set snip_data(lang) $lang

    # Update the language menubutton text
    $widgets(snippets_lang) configure -text $lang

    # Set language of text widget
    syntax::set_language $widgets(snippets_text) $lang

    # Loads the snippet tabl
    snippets_load_table $lang

  }

  ######################################################################
  # Loads the current language into the snippets table.
  proc snippets_load_table {lang} {

    variable widgets
    variable snip_data

    # Clear the table
    $widgets(snippets_tl) delete 0 end

    # Get the snippets list and add it to the table.
    foreach item [snippets::load_list $lang] {
      $widgets(snippets_tl) insert end $item
    }

  }

  ######################################################################
  # Saves the current snippets table to file.
  proc snippets_save_table {} {

    variable widgets
    variable snip_data

    snippets::save_list [$widgets(snippets_tl) get 0 end] $snip_data(lang)

  }

  ######################################################################
  # Called when the snippet keyword entry value changes.
  proc snippets_keyword_changed {value} {

    variable widgets

    if {([$widgets(snippets_text) get 1.0 end-1c] ne "") && ($value ne "")} {
      $widgets(snippets_save) configure -state normal
    } else {
      $widgets(snippets_save) configure -state disabled
    }

    return 1

  }

  ######################################################################
  # Called when the snippet text widget changed.
  proc snippets_text_changed {} {

    variable widgets

    if {([$widgets(snippets_text) get 1.0 end-1c] ne "") &&
        ([$widgets(snippets_keyword) get] ne "")} {
      $widgets(snippets_save) configure -state normal
    } else {
      $widgets(snippets_save) configure -state disabled
    }

    return 1

  }

  ######################################################################
  # Displays the insert menu.
  proc snippets_insert {} {

    variable widgets

    set menu_width  [winfo reqwidth  $widgets(snippets_ins_menu)]
    set menu_height [winfo reqheight $widgets(snippets_ins_menu)]
    set w_width     [winfo width $widgets(snippets_ins)]
    set w_x         [winfo rootx $widgets(snippets_ins)]
    set w_y         [winfo rooty $widgets(snippets_ins)]

    set x $w_x
    set y [expr $w_y - ($menu_height + 4)]

    tk_popup $widgets(snippets_ins_menu) $x $y

  }

  ######################################################################
  # Inserts the given string into the snippets text widget.
  proc snippets_insert_str {str} {

    variable widgets

    # Insert the string
    $widgets(snippets_text) insert insert $str

    # Give the text widget focus.
    focus $widgets(snippets_text).t

  }

  ######################################################################
  # Save the snippet information to the table and then perform a table save.
  proc snippets_save {} {

    variable widgets
    variable snip_data

    # Get the frame contents
    set keyword [$widgets(snippets_keyword) get]
    set content [gui::scrub_text $widgets(snippets_text)]

    # Add/modify to the table
    switch $snip_data(edit_type) {
      "add"  { $widgets(snippets_tl) insert end [list $keyword $content] }
      "edit" { $widgets(snippets_tl) rowconfigure $snip_data(edit_row) -text [list $keyword $content] }
    }

    # Save the table
    snippets_save_table

    # Clear the fields
    $widgets(snippets_keyword) delete 0 end
    $widgets(snippets_text)    delete 1.0 end
    $widgets(snippets_save)    configure -state disabled

    # Display the table frame
    pack forget $widgets(snippets_ef)
    pack $widgets(snippets_tf) -fill both -expand yes

  }

  ######################################################################
  # Cancels the snippet editing process and displays the snippet table.
  proc snippets_cancel {} {

    variable widgets

    # Clear the fields
    $widgets(snippets_keyword) delete 0 end
    $widgets(snippets_text)    delete 1.0 end
    $widgets(snippets_save)    configure -state disabled

    # Display the table frame
    pack forget $widgets(snippets_ef)
    pack $widgets(snippets_tf) -fill both -expand yes

  }

  #############
  # SHORTCUTS #
  #############

  ######################################################################
  # Create the shortcuts panel.
  proc create_shortcuts {w} {

    variable widgets
    variable prefs

    if {[tk windowingsystem] eq "aqua"} {
      set mod_width 6
    } else {
      set mod_width 20
    }

    ttk::frame $w.sf
    wmarkentry::wmarkentry $w.sf.search -width 20 -watermark [msgcat::mc "Search Shortcuts"] \
      -validate key -validatecommand [list pref_ui::shortcut_search %P]
    ttk::button $w.sf.revert -style BButton -text [msgcat::mc "Use Default"] -command [list pref_ui::shortcut_use_default]

    pack $w.sf.search -side left  -padx 2 -pady 2
    pack $w.sf.revert -side right -padx 2 -pady 2

    ttk::frame $w.tf
    set widgets(shortcut_tl) [tablelist::tablelist $w.tf.tl \
      -columns [list 0 [msgcat::mc "Menu Item"] 0 [msgcat::mc "Shortcut"] 0 {}] \
      -height 20 -exportselection 0 -stretch all -borderwidth 0 -highlightthickness 0 \
      -yscrollcommand [list $w.tf.vb set]]
    scroller::scroller $w.tf.vb -orient vertical -command [list $w.tf.tl yview]

    utils::tablelist_configure $widgets(shortcut_tl)

    $widgets(shortcut_tl) columnconfigure 0 -name label    -editable 0 -resizable 0 -stretchable 1
    $widgets(shortcut_tl) columnconfigure 1 -name shortcut -editable 0 -resizable 0 -stretchable 0 -formatcommand [list pref_ui::shortcut_format]
    $widgets(shortcut_tl) columnconfigure 2 -name clear    -hide 1

    bind $widgets(shortcut_tl) <<TablelistSelect>> [list pref_ui::shortcut_table_select]

    set widgets(shortcut_frame) [ttk::frame $w.tf.sf]
    ttk::label  $w.tf.sf.l -text [format "%s: " [msgcat::mc "Shortcut"]]
    set widgets(shortcut_mod)    [ttk::combobox $w.tf.sf.mod -width $mod_width -height 5 -state readonly]
    set widgets(shortcut_sym)    [ttk::combobox $w.tf.sf.sym -width 5          -height 5 -state readonly]
    set widgets(shortcut_clear)  [ttk::button $w.tf.sf.clear  -style BButton -text [msgcat::mc "Clear"] -width 6 -command [list pref_ui::shortcut_clear]]
    set widgets(shortcut_update) [ttk::button $w.tf.sf.update -style BButton -text [msgcat::mc "Set"]   -width 6 -state disabled -command [list pref_ui::shortcut_update]]
    ttk::button $w.tf.sf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command [list pref_ui::shortcut_cancel]

    bind $widgets(shortcut_mod) <<ComboboxSelected>> [list pref_ui::shortcut_changed]
    bind $widgets(shortcut_sym) <<ComboboxSelected>> [list pref_ui::shortcut_changed]

    pack $w.tf.sf.l      -side left -padx 2 -pady 2
    pack $w.tf.sf.mod    -side left -padx 2 -pady 2
    pack $w.tf.sf.sym    -side left -padx 2 -pady 2
    pack $w.tf.sf.cancel -side right -padx 2 -pady 2
    pack $w.tf.sf.update -side right -padx 2 -pady 2
    pack $w.tf.sf.clear  -side right -padx 2 -pady 2

    grid rowconfigure    $w.tf 1 -weight 1
    grid columnconfigure $w.tf 0 -weight 1
    grid $w.tf.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$w.tf.tl cornerpath] -row 0 -column 1 -sticky news
    grid $w.tf.vb              -row 1 -column 1 -sticky ns
    grid $w.tf.sf              -row 2 -column 0 -sticky ew -columnspan 2

    # Hide the shortcut frame
    grid remove $w.tf.sf

    pack $w.sf -fill x
    pack $w.tf -fill both -expand yes -padx 2 -pady 2

    # Register the option for search
    register $widgets(shortcut_tl) [msgcat::mc "Menu bindings"] Shortcuts
    register $widgets(shortcut_tl) [msgcat::mc "Shortcuts"]     Shortcuts

    # Populate the table
    populate_shortcut_table .menubar

  }

  ######################################################################
  # Performs a real-time search of the given value.
  proc shortcut_search {value} {

    variable widgets

    if {$value eq ""} {
      for {set i 0} {$i < [$widgets(shortcut_tl) size]} {incr i} {
        $widgets(shortcut_tl) rowconfigure $i -hide 0
      }
    } else {
      for {set i 0} {$i < [$widgets(shortcut_tl) size]} {incr i} {
        if {[string match -nocase *$value* [$widgets(shortcut_tl) cellcget $i,label -text]]} {
          $widgets(shortcut_tl) rowconfigure $i -hide 0
        } else {
          $widgets(shortcut_tl) rowconfigure $i -hide 1
        }
      }
    }

    return 1

  }

  ######################################################################
  # Checks with the user to verify that they want to revert to using the
  # default menu bindings.  If the answer was yes,
  proc shortcut_use_default {} {

    variable widgets

    set msg    [msgcat::mc "Delete user bindings and use default?"]
    set detail [msgcat::mc "This operation cannot be reversed."]

    # Get confirmation from the user
    set ans [tk_messageBox -parent .prefwin -icon question -type yesno -default yes -message $msg -detail $detail]

    if {$ans eq "yes"} {

      # Clear the shortcut editor (in case its visible)
      shortcut_cancel

      # Revert the bindings and set them up using the new values
      bindings::use_default

      # Clear the shortcut table
      $widgets(shortcut_tl) delete 0 end

      # Re-populate the shortcut table with the updated values
      populate_shortcut_table .menubar

    }

  }

  ######################################################################
  # Returns true if the current symbol displayed in the symbol widget is
  # a function key.
  proc shortcut_sym_is_funckey {} {

    variable widgets

    return [regexp {^F\d+$} [$widgets(shortcut_sym) get]]

  }

  ######################################################################
  # Called whenever the modifier or symbol combobox change.  Handles the
  # state of the Update button and update the values available in the
  # combobox value lists.
  proc shortcut_changed {} {

    variable widgets

    # Get the widget contents
    set mod [$widgets(shortcut_mod) get]
    set sym [$widgets(shortcut_sym) get]

    # Make sure that the Update button is enabled
    if {(($mod ne "") && ($sym ne "")) || [shortcut_sym_is_funckey]} {
      $widgets(shortcut_update) configure -state normal
    }

    # Update the modifier and symbol lists after checking for matches
    shortcut_check_matches

  }

  ######################################################################
  # Check the current value in the comboboxes and compares them against
  # the values in the table.  Updates the combobox value lists with the
  # available values that will not cause a mismatch to occur.
  proc shortcut_check_matches {} {

    variable widgets
    variable mod_dict
    variable sym_dict

    # Get the current modifier
    if {[tk windowingsystem] eq "aqua"} {
      set curr_mod [list]
      foreach elem [split [$widgets(shortcut_mod) get] ""] {
        lappend curr_mod [lindex [bindings::accelerator_mapping $elem] 1]
      }
    } else {
      set curr_mod [split [$widgets(shortcut_mod) get] -]
    }

    # Get the current symbol
    set curr_sym [$widgets(shortcut_sym) get]

    # Create dictionaries from the mod_dict and sym_dict dictionaries
    set mods [dict create {*}[dict get $mod_dict]]
    set syms [dict create {*}[dict get $sym_dict]]

    # If the symbol widget is not displaying a function key, remove the empty space modifier
    if {![shortcut_sym_is_funckey]} {
      catch { dict unset mods {} }
    }

    # If we are on macOS, we need to remove dead keys and other keys that
    # would cause problems
    if {[tk windowingsystem] eq "aqua"} {
      if {[lsearch [list E I U Up Down Left Right] $curr_sym] != -1} {
        catch { dict unset mods Alt }
      }
      if {$curr_mod eq "Alt"} {
        catch { dict unset syms E I U Up Down Left Right }
      }
    }

    # Iterate through the table finding partial matches
    foreach tl_shortcut [$widgets(shortcut_tl) getcolumn shortcut] {
      if {$tl_shortcut ne ""} {
        if {[string range $tl_shortcut end-1 end] eq "--"} {
          set tl_list [split [string range $tl_shortcut 0 end-2] -]
          lappend tl_list "-"
        } else {
          set tl_list [split $tl_shortcut -]
        }
        if {[llength $tl_list] == 1} {
          set tl_mod ""
        } else {
          set tl_mod [lrange $tl_list 0 end-1]
        }
        set tl_sym [lindex $tl_list end]
        if {$curr_mod eq $tl_mod} {
          catch { dict unset syms $tl_sym }
        }
        if {$curr_sym eq $tl_sym} {
          catch { dict unset mods $tl_mod }
        }
      }
    }

    # Set the widgets
    $widgets(shortcut_mod) configure -values [dict values $mods]
    $widgets(shortcut_sym) configure -values [dict values $syms]

  }

  ######################################################################
  # Edits the named shortcut item
  proc shortcut_edit_item {mnu lbl} {

    variable widgets

    set mnu_path ""
    while {$mnu ne ".menubar"} {
      set parent_mnu [winfo parent $mnu]
      for {set i 0} {$i <= [$parent_mnu index end]} {incr i} {
        if {([$parent_mnu type $i] eq "cascade") && ([$parent_mnu entrycget $i -menu] eq $mnu)} {
          set mnu_path "[$parent_mnu entrycget $i -label]/$mnu_path"
          break
        }
      }
      set mnu $parent_mnu
    }

    # Create the full label based on the menu and label name
    set lbl "$mnu_path$lbl"

    # Search the table for the matching menu item (if none is found return)
    if {[set row [$widgets(shortcut_tl) searchcolumn label $lbl]] == -1} {
      return
    }

    # Select the row in the tabl
    $widgets(shortcut_tl) selection clear 0 end
    $widgets(shortcut_tl) selection set   $row
    $widgets(shortcut_tl) see $row

    # Initiate the table selection
    shortcut_table_select

  }

  ######################################################################
  # Handles a selection of the shortcut table.
  proc shortcut_table_select {} {

    variable widgets

    # Get the current selection
    set selected [$widgets(shortcut_tl) curselection]

    if {$selected eq ""} {

      # Hide the shortcut frame
      grid remove $widgets(shortcut_frame)

    } else {

      # Get the current shortcut menu from the table
      set shortcut [$widgets(shortcut_tl) cellcget $selected,shortcut -text]
      set value    [list "" "" "" "" ""]

      # If the shortcut contains the minus key, pull it off and adjust the rest of the shortcut string
      if {[string range $shortcut end-1 end] eq "--"} {
        lset value 4 "-"
        set shortcut [string range $shortcut 0 end-2]
      }

      # Setup the value list
      if {[tk windowingsystem] eq "aqua"} {
        foreach elem [split $shortcut -] {
          lset value {*}[bindings::accelerator_mapping $elem]
        }
      } else {
        foreach elem [split $shortcut -] {
          lset value [lindex [bindings::accelerator_mapping $elem] 0] $elem
        }
      }

      # Set the current modifier and symbol
      if {[tk windowingsystem] eq "aqua"} {
        $widgets(shortcut_mod) set [join [lrange $value 0 3] ""]
      } else {
        $widgets(shortcut_mod) set [join [concat {*}[lrange $value 0 3]] "-"]
      }
      $widgets(shortcut_sym) set [lindex $value 4]

      # Make sure the Clear button state is set correctly
      if {$shortcut eq ""} {
        $widgets(shortcut_clear) configure -state disabled
      } else {
        $widgets(shortcut_clear) configure -state normal
      }

      # Disable the Update button
      $widgets(shortcut_update) configure -state disabled

      # Update the modifier and symbol lists after checking for matches
      shortcut_check_matches

      # Display the shortcut frame
      grid $widgets(shortcut_frame)

      # Set the focus on the modifier
      focus $widgets(shortcut_mod)

    }

  }

  ######################################################################
  # Called prior to posting the modifier menu.
  proc shortcut_create_modifiers {} {

    variable widgets
    variable mod_dict

    set mod_dict [dict create]

    switch [tk windowingsystem] {
      aqua {
        set mods [list {} Cmd Ctrl Alt \
                       Ctrl-Cmd Alt-Cmd Shift-Cmd Ctrl-Shift Ctrl-Alt Shift-Alt \
                       Ctrl-Alt-Cmd Ctrl-Alt-Shift Ctrl-Shift-Cmd Alt-Shift-Cmd \
                       Ctrl-Alt-Shift-Cmd]
      }
      win32 -
      x11 {
        set mods [list {} Ctrl Alt \
                       Shift-Ctrl Ctrl-Alt Shift-Alt \
                       Shift-Ctrl-Alt]
      }
    }

    if {[tk windowingsystem] eq "aqua"} {
      foreach mod $mods {
        set value [list "" "" "" ""]
        foreach elem [split $mod -] {
          lset value {*}[bindings::accelerator_mapping $elem]
        }
        dict set mod_dict $mod [join $value ""]
      }
    } else {
      foreach mod $mods {
        dict set mod_dict $mod $mod
      }
    }

  }

  ######################################################################
  # Called prior to posting the symbol menu.
  proc shortcut_create_symbols {} {

    variable widgets
    variable sym_dict

    set sym_dict [dict create]
    set syms     [list A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 \
                       4 5 6 7 8 9 ~ ! @ \# \$ % ^ & {\*} ( ) _ + ` - = \{ \} \[ \] | \\ : \
                       {;} \" \' < , > . {\?} / Up Down Left Right Space Tab \
                       F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12]

    if {[tk windowingsystem] eq "aqua"} {
      foreach sym $syms {
        dict set sym_dict $sym [lindex [bindings::accelerator_mapping $sym] 1]
      }
    } else {
      foreach sym $syms {
        dict set sym_dict $sym $sym
      }
    }

  }

  ######################################################################
  # Clears the shortcut values and saves the change.
  proc shortcut_clear {} {

    variable widgets

    # Get the currently selected row
    set selected [$widgets(shortcut_tl) curselection]

    # Set the shortcut cell value
    $widgets(shortcut_tl) cellconfigure $selected,shortcut -text ""
    $widgets(shortcut_tl) cellconfigure $selected,clear    -text 1

    # Save the table to the menu binding file
    shortcut_save

    # Close the shortcut after clearing
    shortcut_cancel

  }

  ######################################################################
  # Updates the shortcut table with the current value in the editor.
  # Hides the shortcut editor frame after the update occurs.
  proc shortcut_update {} {

    variable widgets

    set value ""
    set sym   [$widgets(shortcut_sym) get]

    if {[set mod [$widgets(shortcut_mod) get]] ne ""} {
      if {$mod ne ""} {
        if {[tk windowingsystem] eq "aqua"} {
          set value [list "" "" "" "" ""]
          foreach elem [list {*}[split $mod ""] $sym] {
            lset value {*}[bindings::accelerator_mapping $elem]
          }
          set value [join [concat {*}$value] -]
        } else {
          set value "$mod-$sym"
        }
      }
    } else {
      set value $sym
    }

    # Get the currently selected shortcut
    set selected [$widgets(shortcut_tl) curselection]

    # Set the shortcut cell value
    $widgets(shortcut_tl) cellconfigure $selected,shortcut -text $value
    $widgets(shortcut_tl) cellconfigure $selected,clear    -text 0

    # Save the table to the menu binding file
    shortcut_save

    # Close the editor
    shortcut_cancel

  }

  ######################################################################
  # Saves the shortcut table to the menu binding file.
  proc shortcut_save {} {

    variable widgets

    set rows [list]
    set max  0

    # Get the table rows to save
    for {set i 0} {$i < [$widgets(shortcut_tl) size]} {incr i} {
      lassign [$widgets(shortcut_tl) get $i] mnu_path shortcut cleared
      if {($shortcut ne "") || $cleared} {
        if {[set mnu_len [string length $mnu_path]] > $max} {
          set max $mnu_len
        }
        lappend rows [list $mnu_path $shortcut]
      }
    }

    # Save the given bindings to the menu bindings file
    bindings::save $max $rows

  }

  ######################################################################
  # Closes the shortcut editor frame.
  proc shortcut_cancel {} {

    variable widgets

    # Remove the shortcut editor frame
    grid remove $widgets(shortcut_frame)

    # Clear the table selection
    $widgets(shortcut_tl) selection clear 0 end

  }

  ######################################################################
  # Formats the shortcut value in the shortcut table.
  proc shortcut_format {value} {

    if {[tk windowingsystem] eq "aqua"} {
      set new_value [list "" "" "" "" ""]
      if {[string range $value end-1 end] eq "--"} {
        lset new_value 4 "-"
        set value [string range $value 0 end-2]
      }
      foreach elem [split $value -] {
        lset new_value {*}[bindings::accelerator_mapping $elem]
      }
      set value [join $new_value ""]
    }

    return $value

  }

  ######################################################################
  # Recursively adds all menu commands, checkbuttons and radiobuttons to
  # the shortcut table.
  proc populate_shortcut_table {mnu {prefix ""}} {

    variable widgets

    # If there are no elements return
    if {[set last [$mnu index end]] eq "none"} {
      return
    }

    for {set i 0} {$i <= $last} {incr i} {
      switch [$mnu type $i] {
        cascade {
          populate_shortcut_table [$mnu entrycget $i -menu] "${prefix}[$mnu entrycget $i -label]/"
        }
        command -
        checkbutton -
        radiobutton {
          set name "${prefix}[$mnu entrycget $i -label]"
          $widgets(shortcut_tl) insert end [list $name [$mnu entrycget $i -accelerator] [bindings::is_cleared $name]]
        }
      }
    }

  }

  ###########
  # PLUGINS #
  ###########

  ######################################################################
  # Creates the plugins panel.
  proc create_plugins {w} {

    variable widgets
    variable prefs

    set widgets(plugins_mb)    [ttk::menubutton $w.mb -text [msgcat::mc "Select a plugin"] -menu [menu $w.pluginsMenu -tearoff 0]]
    set widgets(plugins_frame) [ttk::frame $w.pf]

    pack $widgets(plugins_mb)    -padx 2 -pady 2
    pack $widgets(plugins_frame) -fill both -expand yes -padx 2 -pady 2

    # Create the plugin frames
    foreach plugin [plugins::handle_on_pref_ui $widgets(plugins_frame)] {
      $w.pluginsMenu add command -label $plugin -command [list pref_ui::handle_plugins_change $plugin]
    }

  }

  ######################################################################
  # Handles a change to the currently selected plugin.  Changes the text
  # in the menubutton and displays the plugin's preference frame.
  proc handle_plugins_change {plugin} {

    variable widgets

    # Change the menubutton text
    $widgets(plugins_mb) configure -text $plugin

    # Remove any packed slaves in the plugins frame
    catch { pack forget {*}[pack slaves $widgets(plugins_frame)] }

    # Pack the selected frame
    pack $widgets(plugins_frame).$plugin -fill both -expand yes

  }

  #################
  # DOCUMENTATION #
  #################

  ######################################################################
  # Creates the documentation preference panel, populates and initializes it.
  proc create_documentation {w} {

    variable widgets
    variable prefs

    ttk::frame $w.tf
    set widgets(doc,table) [tablelist::tablelist $w.tf.tl \
      -columns [list 0 [msgcat::mc "Name"] 0 URL] \
      -exportselection 0 -stretch all -editselectedonly 1 \
      -borderwidth 0 -highlightthickness 0 \
      -movablerows 1 -movecursor [ttk::cursor move] -selectmode single \
      -yscrollcommand [list utils::set_yscrollbar $w.tf.vb]]
    scroller::scroller $w.tf.vb -orient vertical -command [list $w.tf.tl yview]

    utils::tablelist_configure $w.tf.tl

    $w.tf.tl columnconfigure 0 -name name -editable 1 -resizable 1 -stretchable 1
    $w.tf.tl columnconfigure 1 -name url  -editable 1 -resizable 1 -stretchable 1

    bind $w.tf.tl <<TablelistSelect>>      [list pref_ui::documentation_selected]
    bind $w.tf.tl <<TablelistCellUpdated>> [list pref_ui::documentation_save]
    bind $w.tf.tl <<TablelistRowMoved>>    [list pref_ui::documentation_save]

    grid rowconfigure    $w.tf 1 -weight 1
    grid columnconfigure $w.tf 0 -weight 1
    grid $w.tf.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$w.tf.tl cornerpath] -row 0 -column 1 -sticky news
    grid $w.tf.vb              -row 1 -column 1 -sticky ns

    ttk::frame  $w.bf
    ttk::button $w.bf.add -style BButton -text [msgcat::mc "Add"] -command [list pref_ui::documentation_add]
    set widgets(doc,delete) [ttk::button $w.bf.del  -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::documentation_delete] -state disabled]
    set widgets(doc,test)   [ttk::button $w.bf.test -style BButton -text [msgcat::mc "Test"]   -command [list pref_ui::documentation_test]   -state disabled]

    pack $w.bf.add  -side left -padx 2 -pady 2
    pack $w.bf.del  -side left -padx 2 -pady 2
    pack $w.bf.test -side right -padx 2 -pady 2

    pack $w.tf -fill both -expand yes
    pack $w.bf -fill x

    # Register the table
    register $w.tf.tl [msgcat::mc "Language Documentation"] Documentation/References

    # Initialize the table on initialization
    register_initialization pref_ui::documentation_populate

  }

  ######################################################################
  # Called whenever a documentation row is selected in the table.
  proc documentation_selected {} {

    variable widgets

    if {[set selected [$widgets(doc,table) curselection]] ne ""} {
      $widgets(doc,delete) configure -state normal
      $widgets(doc,test)   configure -state normal
    } else {
      $widgets(doc,delete) configure -state disabled
      $widgets(doc,test)   configure -state disabled
    }

  }

  ######################################################################
  # Adds a documentation row to the table.
  proc documentation_add {} {

    variable widgets

    toplevel     .prefwin.docwin
    wm title     .prefwin.docwin [format "%s URL" [msgcat::mc "Add Language Reference"]]
    wm transient .prefwin.docwin .prefwin
    wm resizable .prefwin.docwin 0 0

    ttk::frame .prefwin.docwin.f
    ttk::label .prefwin.docwin.f.ul  -text "URL: "
    ttk::entry .prefwin.docwin.f.url -validate key -validatecommand [list pref_ui::docwin_validate %P] -width 60

    bind .prefwin.docwin.f.url <Return> [list .prefwin.docwin.bf.ok invoke]

    pack .prefwin.docwin.f.ul  -side left -padx 2 -pady 2
    pack .prefwin.docwin.f.url -side left -padx 2 -pady 2

    ttk::frame  .prefwin.docwin.bf
    ttk::button .prefwin.docwin.bf.ok -style BButton -text [msgcat::mc "Add"] -width 6 -command {
      set url  [.prefwin.docwin.f.url get]
      set name [pref_ui::docwin_get_title $url]
      set row  [$pref_ui::widgets(doc,table) insert end [list $name $url]]
      $pref_ui::widgets(doc,table) see $row
      $pref_ui::widgets(doc,table) selection clear 0 end
      $pref_ui::widgets(doc,table) selection set $row
      $pref_ui::widgets(doc,delete) configure -state normal
      $pref_ui::widgets(doc,test)   configure -state normal
      after idle [list pref_ui::documentation_save]
      destroy .prefwin.docwin
    } -state disabled
    ttk::button .prefwin.docwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command {
      destroy .prefwin.docwin
    }

    pack .prefwin.docwin.bf.cancel -side right -padx 2 -pady 2
    pack .prefwin.docwin.bf.ok     -side right -padx 2 -pady 2

    pack .prefwin.docwin.f  -fill both -expand yes
    pack .prefwin.docwin.bf -fill x

    # Place the window in the middle of the preference window
    ::tk::PlaceWindow .prefwin.docwin widget .prefwin

    # Get the grab and focus
    ::tk::SetFocusGrab .prefwin.docwin .prefwin.docwin.f.url

    # Wait for the window to be closed
    tkwait window .prefwin.docwin

    # Restore the focus and grab
    ::tk::RestoreFocusGrab .prefwin.docwin .prefwin.docwin.f.url

  }

  ######################################################################
  # Validates the given entry field value along with the other value and
  # control the state of the Add button.
  proc docwin_validate {value} {

    variable widgets

    if {$value ne ""} {
      .prefwin.docwin.bf.ok configure -state active
    } else {
      .prefwin.docwin.bf.ok configure -state disabled
    }

    return 1

  }

  ######################################################################
  # Downloads the webpage and returns the title tag found in the HTML response.
  proc docwin_get_title {url} {

    # If the URL contains a {query} substring, replace it with "foobar"
    set url [string map {\{query\} foobar} $url]

    # Set the default value of title
    set title [msgcat::mc "Unknown"]

    # Attempt to open the URL
    if {[catch { http::geturl $url } token]} {
      return $title
    }

    # Check the return status
    if {([http::status $token] eq "ok") && ([http::ncode $token] == 200)} {
      set content [http::data $token]
      regexp -nocase {<title>(.*?)</title>} $content -> title
    }

    # Cleanup the token
    http::cleanup $token

    return $title

  }

  ######################################################################
  # Deletes the currently selected row in the table.
  proc documentation_delete {} {

    variable widgets
    variable prefs

    # Get the currently selected row
    set selected [$widgets(doc,table) curselection]

    # Delete the row in the table
    $widgets(doc,table) delete $selected

    # Delete the preference value
    set prefs(Documentation/References) [lreplace $prefs(Documentation/References) $selected $selected]

    # Set the delete/test button state to invalid
    $widgets(doc,delete) configure -state disabled
    $widgets(doc,test)   configure -state disabled

  }

  ######################################################################
  # Displays the given URL in a web browser.
  proc documentation_test {} {

    variable widgets

    # Get the currently selected row
    set selected [$widgets(doc,table) curselection]

    # Get the URL to display
    if {[set url [$widgets(doc,table) cellcget $selected,url -text]] ne ""} {
      utils::open_file_externally $url 0
    }

  }

  ######################################################################
  # Populates the given documentation table with the list of current results.
  proc documentation_populate {} {

    variable widgets
    variable prefs

    # Clear the table
    $widgets(doc,table) delete 0 end

    # Populate the table
    foreach pref $prefs(Documentation/References) {
      $widgets(doc,table) insert end $pref
    }

  }

  ######################################################################
  # Saves the contents of the current state of the documentation table.
  proc documentation_save {} {

    variable widgets
    variable prefs

    set references [list]
    for {set i 0} {$i < [$widgets(doc,table) size]} {incr i} {
      lappend references [list [$widgets(doc,table) cellcget $i,name -text] [$widgets(doc,table) cellcget $i,url -text]]
    }

    # Set the Documentation/References preference variable with the list of values
    set prefs(Documentation/References) $references

  }

  ############
  # ADVANCED #
  ############

  ######################################################################
  # Creates the advanced panel.
  proc create_advanced {w} {

    variable widgets
    variable prefs

    ttk::notebook $w.nb

    ###########
    # GENERAL #
    ###########

    $w.nb add [set a [ttk::frame $w.nb.a]] -text [msgcat::mc "General"]

    make_mb $a.dme  [msgcat::mc "Default Markdown Export Extension"] General/DefaultMarkdownExportExtension [list html htm xhtml] 1
    make_spacer $a 1
    make_fp $a.dted [msgcat::mc "Default Theme Export Directory"] General/DefaultThemeExportDirectory dir {} 1

    ###############
    # DEVELOPMENT #
    ###############

    $w.nb add [set b [ttk::frame $w.nb.b]] -text [msgcat::mc "Development"]

    make_cb $b.dm  [msgcat::mc "Enable development mode"]            Debug/DevelopmentMode
    make_cb $b.sdl [msgcat::mc "Show diagnostic logfile at startup"] Debug/ShowDiagnosticLogfileAtStartup
    make_cb $b.sc  [msgcat::mc "Show Tcl console at startup"]        View/ShowConsole
    make_spacer $b

    make_fp $b.ld [msgcat::mc "Logfile Directory"] Debug/LogDirectory dir [list -title [msgcat::mc "Choose Logfile Directory"]]

    make_spacer $b

    ttk::labelframe $b.pf -text [msgcat::mc "Profiler Options"]
    make_mb     $b.pf.prs [msgcat::mc "Sorting Column"] Tools/ProfileReportSortby [list calls real cpu real_per_call cpu_per_call]
    make_spacer $b.pf
    make_entry  $b.pf.pro [msgcat::mc "Report Options"] Tools/ProfileReportOptions ""
    pack $b.pf -fill x -padx 2 -pady 10

    ##############
    # NFS MOUNTS #
    ##############

    $w.nb add [set c [ttk::frame $w.nb.c]] -text [set wstr [format "NFS %s" [msgcat::mc "Mounts"]]]

    ttk::frame $c.f
    set widgets(advanced_tl) [tablelist::tablelist $c.f.tl \
      -columns [list 0 [msgcat::mc "Host"] 0 [format "NFS %s" [msgcat::mc "Base Directory"]] 0 [msgcat::mc "Remote Base Directory"]] \
      -exportselection 0 -stretch all -editselectedonly 1 -showseparators 1 \
      -borderwidth 0 -highlightthickness 0 \
      -editendcommand [list pref_ui::nfs_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $c.f.hb] \
      -yscrollcommand [list utils::set_yscrollbar $c.f.vb]]
    scroller::scroller $c.f.vb -orient vertical   -command [list $c.f.tl yview]
    scroller::scroller $c.f.hb -orient horizontal -command [list $c.f.tl xview]

    register $widgets(advanced_tl) $wstr NFSMounts

    utils::tablelist_configure $widgets(advanced_tl)

    $widgets(advanced_tl) columnconfigure 0 -name host   -editable 1 -resizable 1 -stretchable 1
    $widgets(advanced_tl) columnconfigure 1 -name nfs    -editable 1 -resizable 1 -stretchable 1
    $widgets(advanced_tl) columnconfigure 2 -name remote -editable 1 -resizable 1 -stretchable 1

    bind $widgets(advanced_tl) <<TablelistSelect>> [list pref_ui::handle_nfs_select]

    grid rowconfigure    $c.f 1 -weight 1
    grid columnconfigure $c.f 0 -weight 1
    grid $c.f.tl              -row 0 -column 0 -sticky news -rowspan 2
    grid [$c.f.tl cornerpath] -row 0 -column 1 -sticky news
    grid $c.f.vb              -row 1 -column 1 -sticky ns
    grid $c.f.hb              -row 2 -column 0 -sticky ew

    ttk::frame $c.bf
    set widgets(advanced_nfs_add) [ttk::button $c.bf.add -style BButton -text [msgcat::mc "Add"]    -command [list pref_ui::nfs_add]]
    set widgets(advanced_nfs_del) [ttk::button $c.bf.del -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::nfs_delete] -state disabled]

    pack $c.bf.add -side left -padx 2 -pady 2
    pack $c.bf.del -side left -padx 2 -pady 2

    pack $c.f  -fill both -expand yes
    pack $c.bf -fill x

    pack $w.nb -fill both -expand yes

    # Initialize widget values
    foreach {host values} $prefs(NFSMounts) {
      lassign $values nfs_mount remote_mount
      $widgets(advanced_tl) insert end [list $host $nfs_mount $remote_mount]
    }

  }

  ######################################################################
  # Sets the NFSMounts preference value to match the current state of the
  # table.
  proc set_nfs_mounts {} {

    variable widgets
    variable prefs

    set values [list]

    for {set i 0} {$i < [$widgets(advanced_tl) size]} {incr i} {
      lassign [$widgets(advanced_tl) get $i] host nfs remote
      if {($host ne "") && ($nfs ne "") && ($remote ne "")} {
        lappend values $host [list $nfs $remote]
      } else {
        return
      }
    }

    set prefs(NFSMounts) $values

  }

  ######################################################################
  # Called when the tablelist cell is done being edited.
  proc nfs_edit_end_command {tbl row col value} {

    after 1 [list pref_ui::set_nfs_mounts]

    return $value

  }

  ######################################################################
  # Adds a new line to the NFSMount table, selects it and forces it into
  # edit mode.
  proc nfs_add {} {

    variable widgets

    # Insert the blank row into the table
    set row [$widgets(advanced_tl) insert end [list "" "" ""]]

    # Clear any selections and make the first cell editable
    $widgets(advanced_tl) selection clear 0 end
    $widgets(advanced_tl) editcell $row,host

    # Disable the delete button
    $widgets(advanced_nfs_del) configure -state disabled

  }

  ######################################################################
  # Deletes the currently selected table row.
  proc nfs_delete {} {

    variable widgets

    # Delete the current selection
    $widgets(advanced_tl) delete [$widgets(advanced_tl) curselection]

    # Disable the delete button
    $widgets(advanced_nfs_del) configure -state disabled

    # Update the NFSMounts preference value
    set_nfs_mounts

  }

  ######################################################################
  # Handles any changes in the selection of the NFSMounts table.
  proc handle_nfs_select {} {

    variable widgets

    if {[$widgets(advanced_tl) curselection] ne ""} {
      $widgets(advanced_nfs_del) configure -state normal
    } else {
      $widgets(advanced_nfs_del) configure -state disabled
    }

  }

  # Create the modifiers and symbols
  shortcut_create_modifiers
  shortcut_create_symbols

}
