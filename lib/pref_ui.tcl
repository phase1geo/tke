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
# Name:    pref_ui.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/14/2016
# Brief:   Contains namespace that displays preference UI.
######################################################################

namespace eval pref_ui {

  source [file join $::tke_dir lib ns.tcl]

  variable current_panel ""

  array set widgets     {}
  array set images      {}
  array set match_chars {}
  array set snip_compl  {}
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

  ######################################################################
  # Make a checkbutton.
  proc make_cb {w msg varname} {

    pack [ttk::checkbutton $w -text [format " %s" $msg] -variable [[ns preferences]::ref $varname]] -fill x -padx 2 -pady 2

    return $w

  }

  ######################################################################
  # Create the preferences window.
  proc create {} {

    variable widgets
    variable images

    if {![winfo exists .prefwin]} {

      toplevel     .prefwin
      wm title     .prefwin "User Preferences"
      wm transient .prefwin .
      wm minsize   .prefwin 600 400
      wm protocol  .prefwin WM_DELETE_WINDOW [list pref_ui::destroy_window]

      ttk::frame .prefwin.f
      set widgets(panes) [ttk::frame .prefwin.f.bf]
      ttk::separator .prefwin.f.sep -orient vertical
      set widgets(frame) [ttk::frame .prefwin.f.pf]

      grid rowconfigure    .prefwin.f 0 -weight 1
      grid columnconfigure .prefwin.f 2 -weight 1
      grid .prefwin.f.bf  -row 0 -column 0 -sticky news
      grid .prefwin.f.sep -row 0 -column 1 -sticky ns   -padx 15
      grid .prefwin.f.pf  -row 0 -column 2 -sticky news

      pack .prefwin.f -fill both -expand yes

      # Create images
      set images(checked)    [image create photo -file [file join $::tke_dir lib images checked.gif]]
      set images(unchecked)  [image create photo -file [file join $::tke_dir lib images unchecked.gif]]
      set images(general)    [image create photo -file [file join $::tke_dir lib images general.gif]]
      set images(appearance) [image create photo -file [file join $::tke_dir lib images appearance.gif]]
      set images(editor)     [image create photo -file [file join $::tke_dir lib images editor.gif]]
      set images(emmet)      [image create photo -file [file join $::tke_dir lib images emmet.gif]]
      set images(find)       [image create photo -file [file join $::tke_dir lib images find.gif]]
      set images(sidebar)    [image create photo -file [file join $::tke_dir lib images sidebar.gif]]
      set images(view)       [image create photo -file [file join $::tke_dir lib images view.gif]]
      set images(tools)      [image create photo -file [file join $::tke_dir lib images tools.gif]]
      set images(advanced)   [image create photo -file [file join $::tke_dir lib images advanced.gif]]

      foreach pane [list general appearance editor emmet find sidebar tools view advanced] {
        if {[info exists images($pane)]} {
          pack [ttk::label $widgets(panes).$pane -compound left -image $images($pane) -text [string totitle $pane] -font {-size 14}] -fill x -padx 2 -pady 2
        } else {
          pack [ttk::label $widgets(panes).$pane -text [string totitle $pane] -font {-size 14}] -fill x -padx 2 -pady 2
        }
        bind $widgets(panes).$pane <Button-1> [list pref_ui::pane_clicked $pane]
        create_$pane [set widgets($pane) [ttk::frame $widgets(frame).$pane]]
      }

      # Emulate a click on the General panel
      pane_clicked general

      # Trace on any changes to the preferences variable
      trace add variable [[ns preferences]::ref] write [list pref_ui::handle_prefs_change]

    }

  }


  ######################################################################
  # Called whenever the user clicks on a panel label.
  proc pane_clicked {panel} {

    variable widgets

    set bg [$widgets(panes).$panel cget -background]
    set fg [$widgets(panes).$panel cget -foreground]

    # Clear all of the panel selection labels, if necessary
    if {$bg ne "blue"} {
      foreach p [winfo children $widgets(panes)] {
        $p configure -background $bg -foreground $fg
      }
    }

    # Set the color of the label to the given color
    $widgets(panes).$panel configure -background blue -foreground white

    # Show the panel
    show_panel $panel

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
  proc show_panel {panel} {

    variable widgets
    variable current_panel

    # Remove the current panel
    if {$current_panel ne ""} {
      pack forget $widgets($current_panel)
    }

    # Display the given panel
    pack $widgets($panel) -fill both

    set current_panel $panel

  }

  ######################################################################
  # Called when the preference window is destroyed.
  proc destroy_window {} {

    variable images

    # Destroy the images
    foreach {name img} [array get images] {
      image delete $img
    }

    # Kill the window
    destroy .prefwin

  }

  ######################################################################
  # Handles any changes to the preference array.
  proc handle_prefs_change {name1 name2 op} {

    if {[winfo exists .prefwin]} {
      # [ns preferences]::save_prefs
      puts "Saving prefs"
    }

  }

  ###########
  # GENERAL #
  ###########

  ######################################################################
  # Creates the general panel.
  proc create_general {w} {

    variable widgets

    set lls  [[ns preferences]::ref General/LoadLastSession]
    set eolc [[ns preferences]::ref General/ExitOnLastClose]
    set acwd [[ns preferences]::ref General/AutoChangeWorkingDirectory]
    set ucos [[ns preferences]::ref General/UpdateCheckOnStart]

    pack [ttk::notebook $w.nb] -fill both -expand yes

    $w.nb add [set a [ttk::frame $w.nb.a]] -text "General"

    make_cb $a.lls  [msgcat::mc "Automatically load last session on start"]          General/LoadLastSession
    make_cb $a.eolc [msgcat::mc "Exit the application after the last tab is closed"] General/ExitOnLastClose
    make_cb $a.acwd [msgcat::mc "Automatically set the current working directory to the current tabs directory"] General/AutoChangeWorkingDirectory
    make_cb $a.ucos [msgcat::mc "Automatically check for updates on start"]          General/UpdateCheckOnStart

    ttk::frame $a.f
    ttk::label $a.f.ul -text [format "%s: " [msgcat::mc "Update using release type"]]
    set widgets(upd_mb) [ttk::menubutton $a.f.umb -menu [menu $a.updMnu -tearoff 0]]

    $a.updMnu add command -label [msgcat::mc "Stable"]      -command [list pref_ui::set_release_type "stable"]
    $a.updMnu add command -label [msgcat::mc "Development"] -command [list pref_ui::set_release_type "devel"]

    # Set the current update release type value in the menubutton
    if {[[ns preferences]::get General/UpdateReleaseType] eq "stable"} {
      $widgets(upd_mb) configure -text "Stable"
    } else {
      $widgets(upd_mb) configure -text "Development"
    }

    ttk::label $a.f.dl -text [format "%s: " [msgcat::mc "Set default open/save browsing directory to"]]
    set widgets(browse_mb) [ttk::menubutton $a.f.dmb -menu [menu $a.browMnu -tearoff 0]]
    set widgets(browse_l)  [ttk::label $a.f.dir]

    $a.browMnu add command -label [msgcat::mc "Last accessed"]                    -command [list pref_ui::set_browse_dir "last"]
    $a.browMnu add command -label [msgcat::mc "Current editing buffer directory"] -command [list pref_ui::set_browse_dir "buffer"]
    $a.browMnu add command -label [msgcat::mc "Current working directory"]        -command [list pref_ui::set_browse_dir "current"]
    $a.browMnu add command -label [msgcat::mc "Use directory"]                    -command [list pref_ui::set_browse_dir "dir"]

    switch [[ns preferences]::get General/DefaultFileBrowserDirectory] {
      "last"    { $widgets(browse_mb) configure -text [msgcat::mc "Last"] }
      "buffer"  { $widgets(browse_mb) configure -text [msgcat::mc "Buffer"] }
      "current" { $widgets(browse_mb) configure -text [msgcat::mc "Current"] }
      default   {
        $widgets(browse_mb) configure -text [msgcat::mc "Directory"]
        $widgets(browse_l)  configure -text "     [[ns preferences]::get General/DefaultFileBrowserDirectory]"
      }
    }

    grid $a.f.ul  -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $a.f.umb -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $a.f.dl  -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $a.f.dmb -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $a.f.dir -row 2 -column 0 -sticky news -columnspan 2

    pack $a.f -fill x -pady 10

    $w.nb add [set b [ttk::frame $w.nb.b]] -text "Variables"

    ttk::frame $b.f
    set widgets(var_table) [tablelist::tablelist $b.f.tl -columns {0 {Variable} 0 {Value}} \
      -stretch all -editselectedonly 1 -exportselection 1 -showseparators 1 \
      -editendcommand [list pref_ui::var_edit_end_command] \
      -xscrollcommand [list $b.f.hb set] -yscrollcommand [list $b.f.vb set]]
    ttk::scrollbar $b.f.vb -orient vertical   -command [list $b.f.tl yview]
    ttk::scrollbar $b.f.hb -orient horizontal -command [list $b.f.tl xview]

    $widgets(var_table) columnconfigure 0 -name var -editable 1 -stretchable 1
    $widgets(var_table) columnconfigure 1 -name val -editable 1 -stretchable 1

    bind $widgets(var_table) <<TablelistSelect>> [list pref_ui::handle_var_select]

    grid rowconfigure    $b.f 0 -weight 1
    grid columnconfigure $b.f 0 -weight 1
    grid $b.f.tl -row 0 -column 0 -sticky news
    grid $b.f.vb -row 0 -column 1 -sticky ns
    grid $b.f.hb -row 1 -column 0 -sticky ew

    ttk::frame $b.bf
    set widgets(var_add) [ttk::button $b.bf.add -style BButton -text "Add"    -command [list pref_ui::add_variable]]
    set widgets(var_del) [ttk::button $b.bf.del -style BButton -text "Delete" -command [list pref_ui::del_variable] -state disabled]

    pack $b.bf.add -side left -padx 2 -pady 2
    pack $b.bf.del -side left -padx 2 -pady 2

    pack $b.f  -fill both -expand yes
    pack $b.bf -fill x

    # Populate the variable table
    foreach row [[ns preferences]::get General/Variables] {
      $widgets(var_table) insert end $row
    }

    $w.nb add [set c [ttk::frame $w.nb.c]] -text "Languages"

    set widgets(lang_table) [tablelist::tablelist $c.tl -columns {0 Enabled 0 Language 0 Extensions} \
      -stretch all -exportselection 1 -showseparators 1 \
      -editendcommand [list pref_ui::lang_edit_end_command] \
      -xscrollcommand [list $c.hb set] -yscrollcommand [list $c.vb set]]
    ttk::scrollbar $c.vb -orient vertical   -command [list $c.tl yview]
    ttk::scrollbar $c.hb -orient horizontal -command [list $c.tl xview]

    $widgets(lang_table) columnconfigure 0 -name enabled -editable 0 -resizable 0 -stretchable 0 -formatcommand [list pref_ui::empty_string]
    $widgets(lang_table) columnconfigure 1 -name lang    -editable 0 -resizable 0 -stretchable 0
    $widgets(lang_table) columnconfigure 2 -name exts    -editable 1 -resizable 1 -stretchable 1

    bind [$widgets(lang_table) bodytag] <Button-1> [list pref_ui::handle_lang_left_click %W %x %y]

    grid rowconfigure    $c 0 -weight 1
    grid columnconfigure $c 0 -weight 1
    grid $c.tl -row 0 -column 0 -sticky news
    grid $c.vb -row 0 -column 1 -sticky ns
    grid $c.hb -row 1 -column 0 -sticky ew

    # Populate the language table
    populate_lang_table

  }

  ######################################################################
  # Format command.
  proc empty_string {value} {

    return ""

  }

  ######################################################################
  # Sets the update release type to the specified value.
  proc set_release_type {value} {

    variable widgets

    if {$value eq "stable"} {
      $widgets(upd_mb) configure -text [msgcat::mc "Stable"]
    } else {
      $widgets(upd_mb) configure -text [msgcat::mc "Development"]
    }

    # Set the preference value
    set [[ns preferences]::ref General/UpdateReleaseType] $value

  }

  ######################################################################
  # Set the browse directory
  proc set_browse_dir {value} {

    variable widgets

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
    set [[ns preferences]::ref General/DefaultFileBrowserDirectory] $value

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

    if {([$tbl cellcget $row,var -text] ne "") && ([$tbl cellcget $row,val -text] ne "")} {
      after 1 [list pref_ui::gather_var_table]
    }

    return $value

  }

  ######################################################################
  # Gather the variable table values from the table and update the
  # preferences array.
  proc gather_var_table {} {

    variable widgets

    set values [list]

    for {set i 0} {$i < [$widgets(var_table) size]} {incr i} {
      lappend values [$widgets(var_table) get $i]
    }

    set [[ns preferences]::ref General/Variables] $values

  }

  ######################################################################
  # Populates the language table with information from syntax and the
  # preferences file.
  proc populate_lang_table {} {

    variable widgets
    variable images

    # Get the list of languages to disable
    set dis_langs [[ns preferences]::get General/DisabledLanguages]

    # Get the extension overrides
    array set orides [[ns preferences]::get General/LanguagePatternOverrides]

    # Add all of the languages
    foreach lang [lsort [[ns syntax]::get_all_languages]] {
      set enabled    [expr [lsearch $dis_langs $lang] == -1]
      set extensions [[ns syntax]::get_extensions {} $lang]
      if {[info exists orides($lang)]} {
        foreach ext $orides($lang) {
          if {[string index $ext 0] eq "+"} {
            lappend extensions [string range $ext 1 end]
          } elseif {[set index [lsearch $extensions [string range $ext 1 end]]] != -1} {
            set extensions [lreplace $extensions $index $index]
          }
        }
      }
      set row [$widgets(lang_table) insert end [list $enabled $lang $extensions]]
      if {$enabled} {
        $widgets(lang_table) cellconfigure $row,enabled -image $images(checked)
      } else {
        $widgets(lang_table) cellconfigure $row,enabled -image $images(unchecked)
      }
    }

  }

  ######################################################################
  # Handles any left-clicks on the language table.
  proc handle_lang_left_click {w x y} {

    variable images

    lassign [tablelist::convEventFields $w $x $y] tbl x y
    lassign [split [$tbl containingcell $x $y] ,] row col

    if {$row >= 0} {
      if {$col == 0} {
        set lang           [$tbl cellcget $row,lang -text]
        set disabled_langs [[ns preferences]::ref General/DisabledLanguages]
        if {[$tbl cellcget $row,$col -text]} {
          $tbl cellconfigure $row,$col -text 0 -image $images(unchecked)
          lappend $disabled_langs $lang
        } else {
          $tbl cellconfigure $row,$col -text 1 -image $images(checked)
          set index [lsearch [set $disabled_langs] $lang]
          set $disabled_langs [lreplace [set $disabled_langs] $index $index]
        }
      }
    }

  }

  ######################################################################
  # Save the contents to the preference file.
  proc lang_edit_end_command {tbl row col value} {

    set lang [$tbl cellcget $row,lang -text]
    set exts [[ns syntax]::get_extensions {} $lang]

    if {$value ne $exts} {
      set lang_oride [list]
      foreach ext $exts {
        if {[lsearch -exact $value $ext] == -1} {
          lappend lang_oride "-$ext"
        }
      }
      foreach val $value {
        if {[lsearch -exact $exts $val] == -1} {
          lappend lang_oride "+$val"
        }
      }
      array set pref_orides [[ns preferences]::get General/LanguagePatternOverrides]
      set pref_orides($lang) $lang_oride
      set [[ns preferences]::ref General/LanguagePatternOverrides] [array get pref_orides]
    }

    return $value

  }

  ##############
  # APPEARANCE #
  ##############

  ######################################################################
  # Creates the appearance panel.
  proc create_appearance {w} {

    variable widgets
    variable colorizers

    ttk::frame $w.tf
    ttk::label $w.tf.l -text [format "%s: " [msgcat::mc "Theme"]]
    set widgets(lang_theme) [ttk::menubutton $w.tf.mb -text [[ns preferences]::get Appearance/Theme] -menu [menu $w.theme_mnu -tearoff 0]]

    pack $w.tf.l  -side left -padx 2 -pady 2
    pack $w.tf.mb -side left -padx 2 -pady 2 -fill x

    ttk::labelframe $w.cf -text "Syntax Coloring"

    # Pack the colorizer frame
    set i 0
    set colorize [[ns preferences]::get Appearance/Colorize]
    foreach type [lsort [array names colorizers]] {
      set colorizers($type) [expr {[lsearch $colorize $type] != -1}]
      grid [ttk::checkbutton $w.cf.$type -text " $type" -variable pref_ui::colorizers($type) -command [list pref_ui::set_colorizers]] -row [expr $i % 3] -column [expr $i / 3] -sticky news -padx 2 -pady 2
      incr i
    }

    # Create fonts frame
    ttk::labelframe $w.ff -text "Fonts"
    ttk::label  $w.ff.l0  -text [format "%s: " [msgcat::mc "Editor"]]
    ttk::label  $w.ff.f0  -text "AaBbCc0123" -font [[ns preferences]::get Appearance/EditorFont]
    ttk::button $w.ff.b0  -style BButton -text [msgcat::mc "Choose"] -command [list pref_ui::set_font $w.ff.f0 "Select Editor Font" Appearance/EditorFont 1]
    ttk::label  $w.ff.l1  -text [format "%s: " [msgcat::mc "Command launcher entry"]]
    ttk::label  $w.ff.f1  -text "AaBbCc0123" -font [[ns preferences]::get Appearance/CommandLauncherEntryFont]
    ttk::button $w.ff.b1  -style BButton -text [msgcat::mc "Choose"] -command [list pref_ui::set_font $w.ff.f1 "Select Command Launcher Entry Font" Appearance/CommandLauncherEntryFont 0]
    ttk::label  $w.ff.l2  -text [format "%s: " [msgcat::mc "Command launcher preview"]]
    ttk::label  $w.ff.f2  -text "AaBbCc0123" -font [[ns preferences]::get Appearance/CommandLauncherPreviewFont]
    ttk::button $w.ff.b2  -style BButton -text [msgcat::mc "Choose"] -command [list pref_ui::set_font $w.ff.f2 "Select Command Launcher Preview Font" Appearance/CommandLauncherPreviewFont 0]

    grid columnconfigure $w.ff 1 -weight 1
    grid $w.ff.l0 -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $w.ff.f0 -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $w.ff.b0 -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $w.ff.l1 -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.ff.f1 -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.ff.b1 -row 1 -column 2 -sticky news -padx 2 -pady 2
    grid $w.ff.l2 -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $w.ff.f2 -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid $w.ff.b2 -row 2 -column 2 -sticky news -padx 2 -pady 2

    pack $w.tf     -fill x -padx 2 -pady 2
    pack $w.cf     -fill x -padx 2 -pady 2
    pack $w.ff     -fill x -padx 2 -pady 2

    make_cb $w.cl_pos [msgcat::mc "Remember last position of command launcher"] Appearance/CommandLauncherRememberLastPosition

    # Populate the themes menu
    foreach theme [themes::get_all_themes] {
      $w.theme_mnu add command -label $theme -command [list pref_ui::set_theme $theme]
    }

  }

  ######################################################################
  # Set the theme to the given value and update UI state.
  proc set_theme {theme} {

    variable widgets

    $widgets(lang_theme) configure -text $theme

    # Save the theme
    set [[ns preferences]::ref Appearance/Theme] $theme

  }

  ######################################################################
  # Update the Appearance/Colorize preference value to the selected
  # colorizer array.
  proc set_colorizers {} {

    variable colorizers

    # Get the list of selected colorizers
    set colorize [list]
    foreach {name value} [array get colorizers] {
      if {$value} {
        lappend colorize $name
      }
    }

    # Set the preference array
    set [[ns preferences]::ref Appearance/Colorize] [lsort $colorize]

  }

  ######################################################################
  # Sets the given font preference.
  proc set_font {lbl title varname mono} {

    set opts [list]
    if {$mono} {
      lappend opts -mono 1 -styles Regular
    }

    # Select the new font
    if {[set new_font [fontchooser -parent .prefwin -title $title -initialfont [$lbl cget -font] -effects 0 {*}$opts]] ne ""} {
      $lbl configure -font $new_font
      set [[ns preferences]::ref $varname] $new_font
    }

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

    ttk::label $w.wwl -text [format "%s: " [msgcat::mc "Ruler column"]]
    set widgets(editor_ww) [ttk::spinbox $w.wwsb -from 20 -to 150 -increment 5 -width 3 -state readonly -command [list pref_ui::set_warning_width]]
    ttk::label $w.sptl -text [format "%s: " [msgcat::mc "Spaces per tab"]]
    set widgets(editor_spt) [ttk::spinbox $w.sptsb -from 1 -to 20 -width 3 -state readonly -command [list pref_ui::set_spaces_per_tab]]
    ttk::label $w.isl -text [format "%s: " [msgcat::mc "Indentation Spaces"]]
    set widgets(editor_is) [ttk::spinbox $w.issb -from 1 -to 20 -width 3 -state readonly -command [list pref_ui::set_indent_spaces]]
    ttk::label $w.mul -text [format "%s: " [msgcat::mc "Maximum undo history (set to 0 for unlimited)"]]
    set widgets(editor_mu) [ttk::spinbox $w.musb -from 0 -to 200 -increment 10 -width 3 -state readonly -command [list pref_ui::set_max_undo]]
    ttk::label $w.vmll -text [format "%s: " [msgcat::mc "Line count to find for Vim modeline information"]]
    set widgets(editor_vml) [ttk::spinbox $w.vmlsb -from 0 -to 20 -width 3 -state readonly -command [list pref_ui::set_vim_modelines]]
    ttk::label $w.eoll -text [format "%s: " [msgcat::mc "End-of-line character when saving"]]
    set widgets(editor_eolmb) [ttk::menubutton $w.eolmb -menu [menu $w.eol -tearoff 0]]
    
    foreach {value desc} [list auto [msgcat::mc "Use original EOL character from file"] \
                               sys  [msgcat::mc "Use appropriate EOL character on system"] \
                               cr   [msgcat::mc "Use single carriage return character"] \
                               crlf [msgcat::mc "Use carriate return linefeed sequence"] \
                               lf   [msgcat::mc "Use linefeed character"]] {
      $w.eol add radiobutton -label $desc -value $value -variable [[ns preferences]::ref Editor/EndOfLineTranslation] -command [list pref_ui::set_eol_translation]
    }
    
    ttk::labelframe $w.mcf -text [msgcat::mc "Auto-match Characters"]
    ttk::checkbutton $w.mcf.sr -text [format " %s" [msgcat::mc "Square bracket"]] -variable pref_ui::match_chars(square) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.cu -text [format " %s" [msgcat::mc "Curly bracket"]]  -variable pref_ui::match_chars(curly)  -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.an -text [format " %s" [msgcat::mc "Angled bracket"]] -variable pref_ui::match_chars(angled) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.pa -text [format " %s" [msgcat::mc "Parenthesis"]]    -variable pref_ui::match_chars(paren)  -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.dq -text [format " %s" [msgcat::mc "Double-quote"]]   -variable pref_ui::match_chars(double) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.sq -text [format " %s" [msgcat::mc "Single-quote"]]   -variable pref_ui::match_chars(single) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.bt -text [format " %s" [msgcat::mc "Backtick"]]       -variable pref_ui::match_chars(btick)  -command [list pref_ui::set_match_chars]
    
    grid $w.mcf.sr -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mcf.cu -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mcf.an -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mcf.pa -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $w.mcf.dq -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.mcf.sq -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $w.mcf.bt -row 1 -column 2 -sticky news -padx 2 -pady 2
    
    ttk::labelframe $w.scf -text [msgcat::mc "Snippet Completion Characters"]
    pack [ttk::checkbutton $w.scf.s -text [format " %s" [msgcat::mc "Space"]]  -variable pref_ui::snip_compl(space)  -command [list pref_ui::set_snip_compl]] -side left -padx 2 -pady 2
    pack [ttk::checkbutton $w.scf.t -text [format " %s" [msgcat::mc "Tab"]]    -variable pref_ui::snip_compl(tab)    -command [list pref_ui::set_snip_compl]] -side left -padx 2 -pady 2
    pack [ttk::checkbutton $w.scf.r -text [format " %s" [msgcat::mc "Return"]] -variable pref_ui::snip_compl(return) -command [list pref_ui::set_snip_compl]] -side left -padx 2 -pady 2
    
    ttk::frame $w.cf
    make_cb $w.cf.eai  [msgcat::mc "Enable auto-indentation"]                 Editor/EnableAutoIndent
    make_cb $w.cf.hmc  [msgcat::mc "Highlight matching character"]            Editor/HighlightMatchingChar
    make_cb $w.cf.rtw  [msgcat::mc "Remove trailing whitespace on save"]      Editor/RemoveTrailingWhitespace
    make_cb $w.cf.sfai [msgcat::mc "Format snippet indentation after insert"] Editor/SnippetFormatAfterInsert
    make_cb $w.cf.rln  [msgcat::mc "Enable relative line numbering"]          Editor/RelativeLineNumbers
    
    grid columnconfigure $w 2 -weight 1
    grid $w.wwl   -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $w.wwsb  -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $w.sptl  -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.sptsb -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.isl   -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $w.issb  -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid $w.mul   -row 3 -column 0 -sticky news -padx 2 -pady 2
    grid $w.musb  -row 3 -column 1 -sticky news -padx 2 -pady 2
    grid $w.vmll  -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid $w.vmlsb -row 4 -column 1 -sticky news -padx 2 -pady 2
    grid $w.eoll  -row 5 -column 0 -sticky news -padx 2 -pady 2
    grid $w.eolmb -row 5 -column 1 -sticky news -padx 2 -pady 2
    grid $w.mcf   -row 6 -column 0 -sticky news -padx 2 -pady 10 -columnspan 3
    grid $w.scf   -row 7 -column 0 -sticky news -padx 2 -pady 10 -columnspan 3
    grid $w.cf    -row 8 -column 0 -sticky news -padx 2 -pady 2 -columnspan 3
    
    # Set the UI state to match preference
    $widgets(editor_ww)  set [[ns preferences]::get Editor/WarningWidth]
    $widgets(editor_spt) set [[ns preferences]::get Editor/SpacesPerTab]
    $widgets(editor_is)  set [[ns preferences]::get Editor/IndentSpaces]
    $widgets(editor_mu)  set [[ns preferences]::get Editor/MaxUndo]
    $widgets(editor_vml) set [[ns preferences]::get Editor/VimModelines]
    
    foreach char [list square curly angled paren double single btick] {
      set match_chars($char) [expr {[lsearch [[ns preferences]::get Editor/AutoMatchChars] $char] != -1}]
    }
    
    foreach char [list space tab return] {
      set snip_compl($char) [expr {[lsearch [[ns preferences]::get Editor/SnippetCompleters] $char] != -1}]
    }
    
    set_eol_translation

  }
  
  ######################################################################
  # Sets the Editor/WarningWidth preference value.
  proc set_warning_width {} {
    
    variable widgets
    
    set [[ns preferences]::ref Editor/WarningWidth] [$widgets(editor_ww) get]
  }
  
  ######################################################################
  # Sets the Editor/SpacesPerTab preference value.
  proc set_spaces_per_tab {} {
    
    variable widgets
    
    set [[ns preferences]::ref Editor/SpacesPerTab] [$widgets(editor_spt) get]
    
  }
  
  ######################################################################
  # Sets the Editor/IndentSpaces preference value.
  proc set_indent_spaces {} {
    
    variable widgets
    
    set [[ns preferences]::ref Editor/IndentSpaces] [$widgets(editor_is) get]
    
  }
  
  ######################################################################
  # Sets the Editor/MaxUndo preference value.
  proc set_max_undo {} {
    
    variable widgets
    
    set [[ns preferences]::ref Editor/MaxUndo] [$widgets(editor_mu) get]
    
  }
  
  ######################################################################
  # Sets the Editor/VimModelines preference value.
  proc set_vim_modelines {} {
    
    variable widgets
    
    set [[ns preferences]::ref Editor/VimModelines] [$widgets(editor_vml) get]
    
  }
  
  ######################################################################
  # Set the matching chars to the Editor/AutoMatchChars preference value.
  proc set_match_chars {} {
    
    variable match_chars
    
    set mchars [list]
    foreach char [list square curly angled paren double single btick] {
      if {$match_chars($char)} {
        lappend mchars $char
      }
    }
    
    set [[ns preferences]::ref Editor/AutoMatchChars] $mchars
    
  }
  
  ######################################################################
  # Set the snippet completers to the Editor/SnippetCompleters preference
  # value.
  proc set_snip_compl {} {
    
    variable snip_compl
    
    set schars [list]
    foreach char [list space tab return] {
      if {$snip_compl($char)} {
        lappend schars $char
      }
    }
    
    set [[ns preferences]::ref Editor/SnippetCompleters] $schars
    
  }

  ######################################################################
  # Sets the EOL translation menubutton text to the given value
  proc set_eol_translation {} {
    
    variable widgets
    
    $widgets(editor_eolmb) configure -text [[ns preferences]::get Editor/EndOfLineTranslation]
    
  }
  
  #########
  # EMMET #
  #########

  ######################################################################
  # Creates the Emmet panel.
  proc create_emmet {w} {

    variable widgets

    ttk::frame $w.cf
    make_cb $w.cf.aivp [msgcat::mc "Automatically insert vendor prefixes"] Emmet/CSSAutoInsertVendorPrefixes
    make_cb $w.cf.cs   [msgcat::mc "Use shortened colors"]                 Emmet/CSSColorShort
    make_cb $w.cf.fs   [msgcat::mc "Enable fuzzy search"]                  Emmet/CSSFuzzySearch   
    
    ttk::label $w.ccl -text [format "%s: " [msgcat::mc "Color value case"]]
    set widgets(emmet_ccmb) [ttk::menubutton $w.ccmb -menu [menu $w.ccmb_mnu -tearoff 0]]
    
    foreach {value lbl} [list upper [msgcat::mc "Convert to uppercase"] \
                              lower [msgcat::mc "Convert to lowercase"] \
                              keep  [msgcat::mc "Retail case"]] {
      $w.ccmb_mnu add radiobutton -label $lbl -value $value -variable [[ns preferences]::ref Emmet/CSSColorCase] -command [list pref_ui::set_css_color_case]
    }

    ttk::label $w.dummy -text ""
    ttk::label $w.iul -text [format "%s: " [msgcat::mc "Default unit for integer values"]]
    ttk::entry $w.iue -textvariable [[ns preferences]::ref Emmet/CSSIntUnit]
    ttk::label $w.ful -text [format "%s: " [msgcat::mc "Default unit for floating point values"]]
    ttk::entry $w.fue -textvariable [[ns preferences]::ref Emmet/CSSFloatUnit]
    
    # {Emmet/CSSMozPropertiesAddon} {}
    # {Emmet/CSSMSPropertiesAddon} {}
    # {Emmet/CSSOPropertiesAddon} {}
    # {Emmet/CSSWebkitPropertiesAddon} {}
    
    ttk::label $w.vsl -text [format "%s: " [msgcat::mc "Symbol between CSS property and value"]]
    ttk::entry $w.vse -textvariable [[ns preferences]::ref Emmet/CSSValueSeparator]
    ttk::label $w.pel -text [format "%s: " [msgcat::mc "Symbol placed at end of CSS property"]]
    ttk::entry $w.pee -textvariable [[ns preferences]::ref Emmet/CSSPropertyEnd]
    
    grid $w.cf    -row 0 -column 0 -sticky news -padx 2 -pady 2 -columnspan 3
    grid $w.dummy -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.ccl   -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $w.ccmb  -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid $w.iul   -row 3 -column 0 -sticky news -padx 2 -pady 2
    grid $w.iue   -row 3 -column 1 -sticky news -padx 2 -pady 2
    grid $w.ful   -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid $w.fue   -row 4 -column 1 -sticky news -padx 2 -pady 2
    grid $w.vsl   -row 5 -column 0 -sticky news -padx 2 -pady 2
    grid $w.vse   -row 5 -column 1 -sticky news -padx 2 -pady 2
    grid $w.pel   -row 6 -column 0 -sticky news -padx 2 -pady 2
    grid $w.pee   -row 6 -column 1 -sticky news -padx 2 -pady 2
    
    # Initialize the UI state
    set_css_color_case
    
  }
  
  ######################################################################
  # Update the UI state to match the value of Emmet/CSSColorCase.
  proc set_css_color_case {} {
    
    variable widgets
    
    $widgets(emmet_ccmb) configure -text [[ns preferences]::get Emmet/CSSColorCase]
    
  }

  ########
  # FIND #
  ########

  ######################################################################
  # Creates the find panel.
  proc create_find {w} {

    variable widgets

    ttk::label $w.mhl -text [format "%s: " [msgcat::mc "Set Find History Depth"]]
    set widgets(find_mh) [ttk::spinbox $w.mh -from 0 -to 100 -width 3 -state readonly -command [list pref_ui::set_max_history]]
    ttk::label $w.cnl -text [format "%s: " [msgcat::mc "Set Find in Files Line Context"]]
    set widgets(find_cn) [ttk::spinbox $w.cn -from 0 -to 10  -width 3 -state readonly -command [list pref_ui::set_context_num]]
    ttk::label $w.jdl -text [format "%s: " [msgcat::mc "Set Jump Distance"]]
    set widgets(find_jd) [ttk::spinbox $w.jd -from 1 -to 20  -width 3 -state readonly -command [list pref_ui::set_jump_distance]]

    grid $w.mhl -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mh  -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $w.cnl -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.cn  -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.jdl -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $w.jd  -row 2 -column 1 -sticky news -padx 2 -pady 2

    # Initialize the widgets
    $widgets(find_mh) set [[ns preferences]::get Find/MaxHistory]
    $widgets(find_cn) set [[ns preferences]::get Find/ContextNum]
    $widgets(find_jd) set [[ns preferences]::get Find/JumpDistance]

  }

  ######################################################################
  # Sets the MaxHistory preference value from the spinbox.
  proc set_max_history {} {

    variable widgets

    set [[ns preferences]::ref Find/MaxHistory] [$widgets(find_mh) get]

  }

  ######################################################################
  # Sets the ContextNum preference value from the spinbox.
  proc set_context_num {} {

    variable widgets

    set [[ns preferences]::ref Find/ContextNum] [$widgets(find_cn) get]

  }

  ######################################################################
  # Sets the JumpDistance preference value from the spinbox.
  proc set_jump_distance {} {

    variable widgets

    set [[ns preferences]::ref Find/JumpDistance] [$widgets(find_jd) get]

  }

  ###########
  # SIDEBAR #
  ###########

  ######################################################################
  # Creates the sidebar panel.
  proc create_sidebar {w} {

    variable widgets

    ttk::notebook $w.nb

    $w.nb add [set a [ttk::frame $w.nb.a]] -text "Behaviors"

    make_cb $a.rralc [msgcat::mc "Remove root directory after last sub-file is closed"] Sidebar/RemoveRootAfterLastClose
    make_cb $a.fat   [msgcat::mc "Show folders at top"] Sidebar/FoldersAtTop

    $w.nb add [set b [ttk::frame $w.nb.b]] -text "Hiding"

    make_cb $b.ib [msgcat::mc "Hide binary files"] Sidebar/IgnoreBinaries

    ttk::labelframe $b.pf -text "Hide Patterns"
    pack [set widgets(sb_patterns) [tokenentry::tokenentry $b.pf.te -height 6 -tokenshape eased]] -fill both -expand yes

    bind $widgets(sb_patterns) <<TokenEntryModified>> [list pref_ui::sidebar_pattern_changed]

    pack $b.pf -fill both -expand yes -padx 2 -pady 10

    pack $w.nb -fill both -expand yes

    # Insert the tokens
    $widgets(sb_patterns) tokeninsert end [[ns preferences]::get Sidebar/IgnoreFilePatterns]

  }

  ######################################################################
  # Called whenever the pattern tokenentry widget is modified.
  proc sidebar_pattern_changed {} {

    variable widgets

    set [[ns preferences]::ref Sidebar/IgnoreFilePatterns] [$widgets(sb_patterns) tokenget]

  }

  #########
  # TOOLS #
  #########

  ######################################################################
  # Creates the tools panel.
  proc create_tools {w} {

    variable widgets

    ttk::frame $w.cf
    make_cb $w.cf.vm [msgcat::mc "Enable Vim Mode"] Tools/VimMode
    
    ttk::label   $w.chdl -text [format "%s: " [msgcat::mc "Clipboard history depth"]]
    set widgets(tools_chd) [ttk::spinbox $w.chdsb -from 1 -to 30 -width 3 -state readonly -command [list pref_ui::set_clipboard_history]]
    
    grid $w.cf    -row 0 -column 0 -sticky news -padx 2 -pady 2 -columnspan 3
    grid $w.chdl  -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.chdsb -row 1 -column 1 -sticky news -padx 2 -pady 2
    
    $widgets(tools_chd) set [[ns preferences]::get Tools/ClipboardHistoryDepth]
    
  }
  
  ######################################################################
  # Sets the Tools/ClipboardHistoryDepth preference value.
  proc set_clipboard_history {} {
    
    variable widgets
    
    set [[ns preferences]::ref Tools/ClipboardHistoryDepth] [$widgets(tools_chd) get]
    
  }

  ########
  # VIEW #
  ########

  ######################################################################
  # Creates the view panel.
  proc create_view {w} {

    variable widgets

    make_cb $w.sm   [msgcat::mc "Show menubar"]                                     View/ShowMenubar
    make_cb $w.ss   [msgcat::mc "Show sidebar"]                                     View/ShowSidebar
    make_cb $w.sc   [msgcat::mc "Show console"]                                     View/ShowConsole
    make_cb $w.ssb  [msgcat::mc "Show status bar"]                                  View/ShowStatusBar
    make_cb $w.stb  [msgcat::mc "Show tab bar"]                                     View/ShowTabBar
    make_cb $w.sln  [msgcat::mc "Show line numbers"]                                View/ShowLineNumbers
    make_cb $w.smm  [msgcat::mc "Show marker map"]                                  View/ShowMarkerMap
    make_cb $w.sdio [msgcat::mc "Show difference file in other pane than original"] View/ShowDifferenceInOtherPane
    make_cb $w.sdvi [msgcat::mc "Show difference file version information"]         View/ShowDifferenceVersionInfo
    make_cb $w.sfif [msgcat::mc "Show 'Find in Files' result in other pane"]        View/ShowFindInFileResultsInOtherPane
    make_cb $w.ats  [msgcat::mc "Allow scrolling in tab bar"]                       View/AllowTabScrolling
    make_cb $w.ota  [msgcat::mc "Sort tabs alphabetically on open"]                 View/OpenTabsAlphabetically
    make_cb $w.ecf  [msgcat::mc "Enable code folding"]                              View/EnableCodeFolding

    ttk::frame $w.of
    pack [ttk::label   $w.of.l  -text [format "%s: " [msgcat::mc "Recently opened history depth"]]] -side left -padx 2 -pady 2
    pack [set widgets(view_sro) [ttk::spinbox $w.of.sb -from 0 -to 20 -width 2 -state readonly -command [list pref_ui::set_show_recently_opened]]] -side left -padx 2 -pady 2

    pack $w.of -fill x -padx 2 -pady 10

    # Initialize the spinbox value
    $widgets(view_sro) set [[ns preferences]::get View/ShowRecentlyOpened]

  }

  ######################################################################
  # Sets the View/ShowRecentlyOpened preference value
  proc set_show_recently_opened {} {

    variable widgets

    set [[ns preferences]::ref View/ShowRecentlyOpened] [$widgets(view_sro) get]

  }

  ############
  # ADVANCED #
  ############

  ######################################################################
  # Creates the advanced panel.
  proc create_advanced {w} {

    variable widgets

    # {NFSMounts}                  {}
    # {Debug/LogDirectory}         {}
    # {Debug/DevelopmentMode}      {0}
    # {Debug/ShowDiagnosticLogfileAtStartup} {0}
    # {Help/UserGuideFormat}       {pdf}

    ttk::labelframe $w.pf -text [msgcat::mc "Profiler Options"]
    # {Tools/ProfileReportSortby}  {calls}
    # {Tools/ProfileReportOptions} {}

  }

}
