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

  variable current_panel     ""
  variable selected_session  ""
  variable selected_language ""
  variable mod_dict
  variable sym_dict
  variable enable_share
  variable share_changed

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
  # Make a checkbutton.
  proc make_cb {w msg varname} {

    pack [ttk::checkbutton $w -text [format " %s" $msg] -variable pref_ui::prefs($varname)] -fill x -padx 2 -pady 2

    # Register the widget for search
    register $w $msg $varname

    return $w

  }

  ######################################################################
  # Sets up the session submenu for the given
  proc populate_session_menu {language} {

    variable widgets

    # Delete the current menu
    $widgets(selsmenu) delete 0 end

    # Populate the selection menu
    $widgets(selsmenu) add radiobutton -label "None" -variable pref_ui::selected_session -value "None" -command [list pref_ui::select "None" $language]
    $widgets(selsmenu) add separator
    foreach name [sessions::get_names] {
      $widgets(selsmenu) add radiobutton -label $name -variable pref_ui::selected_session -value $name -command [list pref_ui::select $name $language]
    }

  }

  ######################################################################
  # Sets up a select submenu for the given menu information.
  proc populate_lang_menu {session} {

    variable widgets

    syntax::populate_syntax_menu $widgets(sellmenu) [list pref_ui::select $session] pref_ui::selected_language "All"

  }

  ######################################################################
  # Selects the given session language.
  proc select {session language {init 0}} {

    variable widgets
    variable prefs
    variable current_panel

    # Disable traces
    catch { trace remove variable pref_ui::prefs {*}[lindex [trace info variable pref_ui::prefs] 0] }

    # Update the menubuttons text
    $widgets(select_s) configure -text "Session: $session"
    $widgets(select_l) configure -text "Language: $language"

    # Update the language menu in case the user changed the session
    populate_session_menu $language
    populate_lang_menu    $session

    # Translate the session and language values
    if {$session eq "None"} {
      set session ""
    }
    if {$language eq "All"} {
      set language ""
    }

    # Setup the prefs
    array unset prefs
    array set prefs [preferences::get_loaded $session $language]

    # If we are only changing language information, remove the sidebar and just display the editor pane
    if {$language ne ""} {
      grid remove .prefwin.f.bf
      grid remove .prefwin.f.vsep

      # Don't bother to emulate an editor click if we are creating the window
      if {!$init} {
        pane_clicked editor
      }

      # Otherwise, make sure the entire UI is displayed.
    } else {
      grid .prefwin.f.bf
      grid .prefwin.f.vsep

      if {!$init} {
        if {$session eq ""} {
          pack $widgets(panes).general   -before $widgets(panes).appearance -fill both -padx 2 -pady 2
          pack $widgets(panes).snippets  -after $widgets(panes).view -fill both -padx 2 -pady 2
          pack $widgets(panes).shortcuts -fill both -padx 2 -pady 2
          pack $widgets(panes).advanced  -fill both -padx 2 -pady 2
          $widgets(frame).emmet.nb add $widgets(node_aliases)
          $widgets(frame).emmet.nb add $widgets(abbr_aliases)
          pane_clicked $current_panel
        } else {
          pack forget $widgets(panes).general
          pack forget $widgets(panes).snippets
          pack forget $widgets(panes).shortcuts
          pack forget $widgets(panes).advanced
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
      wm title     .prefwin "Preferences"
      wm transient .prefwin .
      wm protocol  .prefwin WM_DELETE_WINDOW [list pref_ui::destroy_window]
      wm withdraw  .prefwin

      ttk::frame .prefwin.sf
      set widgets(select_s) [ttk::menubutton        .prefwin.sf.sels -menu [set widgets(selsmenu) [menu .prefwin.sf.selectSessionMenu -tearoff 0]]]
      set widgets(select_l) [ttk::menubutton        .prefwin.sf.sell -menu [set widgets(sellmenu) [menu .prefwin.sf.selectLangMenu    -tearoff 0]]]
      set widgets(match_e)  [wmarkentry::wmarkentry .prefwin.sf.e    -width 20 -watermark "Search" -validate key -validatecommand [list pref_ui::perform_search %P]]

      # Initialize the syntax menu
      set selected_session  [expr {($session  eq "") ? "None" : $session}]
      set selected_language [expr {($language eq "") ? "All"  : $language}]
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
      set widgets(match_lb) [listbox .prefwin.f.mf.lb -relief flat -height 10 -yscrollcommand [list utils::set_yscrollbar .prefwin.f.mf.vb]]
      ttk::scrollbar .prefwin.f.mf.vb -orient vertical -command [list .pref.f.mf.matches yview]

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
      select $selected_session $selected_language 1

      # Create the list of panes
      set panes [list general appearance editor find sidebar view snippets emmet shortcuts advanced]

      # Create and pack each of the panes
      foreach pane $panes {
        pack [ttk::label $widgets(panes).$pane -compound left -image pref_$pane -text [string totitle $pane] -font {-size 14}] -fill x -padx 2 -pady 2
        bind $widgets(panes).$pane <Button-1> [list pref_ui::pane_clicked $pane]
        create_$pane [set widgets($pane) [ttk::frame $widgets(frame).$pane]]
      }

      # Allow the panel dimensions to be calculatable
      update

      # Get the requested panel dimensions
      foreach pane $panes {
        lappend heights [winfo reqheight $widgets($pane)]
        lappend widths  [winfo reqwidth  $widgets($pane)]
      }

      # Calculate the geometry
      set win_width  [expr [lindex [lsort -integer $widths]  end] + [winfo reqwidth  .prefwin.f.vsep] + [winfo reqwidth  $widgets(panes)]]
      set win_height [expr [lindex [lsort -integer $heights] end] + [winfo reqheight .prefwin.f.hsep] + [winfo reqheight .prefwin.sf]]

      # Set the minimum size of the window
      wm geometry  .prefwin ${win_width}x${win_height}
      wm resizable .prefwin 0 0

      # Emulate a click on the General panel
      if {$language ne ""} {
        pane_clicked editor
      } elseif {$session ne ""} {
        pack forget $widgets(panes).general
        pack forget $widgets(panes).shortcuts
        pack forget $widgets(panes).snippets
        pack forget $widgets(panes).advanced
        $widgets(frame).emmet.nb hide $widgets(node_aliases)
        $widgets(frame).emmet.nb hide $widgets(abbr_aliases)
        pane_clicked appearance
      } elseif {$panel ne ""} {
        pane_clicked $panel $tab
      } else {
        pane_clicked general
      }

      # Give the search panel the focus
      focus .prefwin.sf.e

      # Show the window
      wm deiconify .prefwin

      # Center the window in the editor window
      ::tk::PlaceWindow .prefwin widget .

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

    # Save any sharing changes (if necessary)
    save_share_changes

    # Kill the window
    destroy .prefwin

  }

  ######################################################################
  # Handles any changes to the preference array.
  proc handle_prefs_change {session language name1 name2 op} {

    variable prefs

    if {[winfo exists .prefwin]} {
      preferences::save_prefs $session $language [array get prefs]
    }

  }

  ######################################################################
  # Display the list of all matches in the dropdoxn listbox.
  proc show_matches {value} {

    variable widgets
    variable search
    variable selected_language

    if {$selected_language eq "All"} {
      set matches [array names search -regexp (?i).*$request.*::.]
    } else {
      set matches [array names search -regexp (?i).*$request.*::1]
    }

    foreach match $matches {
      lassign $search($match) win lbl tab1 tab2
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
      if {$selected_language eq "All"} {
        if {$selected_session eq "None"} {
          set matches [array names search -regexp (?i).*$value.*::a.*]
        } else {
          set matches [array names search -regexp (?i).*$value.*::.*b.*]
        }
      } else {
        set matches [array names search -regexp (?i).*$value.*::.*c]
      }
      foreach match $matches {
        lassign $search($match) win lbl tab1 tab2
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
    lassign $search($key) win lbl tab1 tab2

    # Select the pane containing the item
    pane_clicked [lindex [split $tab1 .] end]

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
    set insts [split $w .]
    set tabs  [list]
    lappend tabs .prefwin.f.bf.[lindex $insts 4]
    for {set i 3} {$i < [llength $insts]} {incr i} {
      set hier [join [lrange $insts 0 $i] .]
      if {[winfo class $hier] eq "TNotebook"} {
        lappend tabs [join [lrange $insts 0 [expr $i + 1]] .]
      }
    }

    lassign [split $var /] category var

    switch $category {
      General    { set tag a }
      Appearance { set tag ab }
      Editor     { set tag abc }
      Emmet      { set tag ab }
      Find       { set tag ab }
      Sidebar    { set tag ab }
      View       { set tag ab }
      Shortcuts  { set tag a }
      Advanced   { set tag a }
      default    { set tag "" }
    }

    set lang_only    [expr {($category eq "Editor") ? 1 : 0}]
    set search(${var}::$tag) [list $w $str {*}$tabs]

    if {$str ne ""} {
      set search(${str}::$tag) [list $w $str {*}$tabs]
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

    make_cb $a.epug [msgcat::mc "Edit preferences using GUI"]                        General/EditPreferencesUsingGUI
    make_cb $a.lls  [msgcat::mc "Automatically load last session on start"]          General/LoadLastSession
    make_cb $a.eolc [msgcat::mc "Exit the application after the last tab is closed"] General/ExitOnLastClose
    make_cb $a.acwd [msgcat::mc "Automatically set the current working directory to the current tabs directory"] General/AutoChangeWorkingDirectory

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

    pack $a.f -fill x -pady 10

    #################
    # VARIABLES TAB #
    #################

    $w.nb add [set b [ttk::frame $w.nb.b]] -text [set wstr [msgcat::mc "Variables"]]

    ttk::frame $b.f
    set widgets(var_table) [tablelist::tablelist $b.f.tl -columns {0 {Variable} 0 {Value}} \
      -stretch all -editselectedonly 1 -exportselection 0 -showseparators 1 \
      -height 25 \
      -editendcommand [list pref_ui::var_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $b.f.hb] \
      -yscrollcommand [list utils::set_yscrollbar $b.f.vb]]
    ttk::scrollbar $b.f.vb -orient vertical   -command [list $b.f.tl yview]
    ttk::scrollbar $b.f.hb -orient horizontal -command [list $b.f.tl xview]

    utils::tablelist_configure $widgets(var_table)

    $widgets(var_table) columnconfigure 0 -name var -editable 1 -stretchable 1
    $widgets(var_table) columnconfigure 1 -name val -editable 1 -stretchable 1

    bind $widgets(var_table) <<TablelistSelect>> [list pref_ui::handle_var_select]

    grid rowconfigure    $b.f 0 -weight 1
    grid columnconfigure $b.f 0 -weight 1
    grid $b.f.tl -row 0 -column 0 -sticky news
    grid $b.f.vb -row 0 -column 1 -sticky ns
    grid $b.f.hb -row 1 -column 0 -sticky ew

    register $widgets(var_table) $wstr General/Variables

    ttk::frame $b.bf
    set widgets(var_add) [ttk::button $b.bf.add -style BButton -text "Add"    -command [list pref_ui::add_variable]]
    set widgets(var_del) [ttk::button $b.bf.del -style BButton -text "Delete" -command [list pref_ui::del_variable] -state disabled]

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

    set widgets(lang_table) [tablelist::tablelist $c.tl -columns {0 Enabled 0 Language 0 Extensions} \
      -stretch all -exportselection 1 -showseparators 1 \
      -height 25 \
      -editendcommand [list pref_ui::lang_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $c.hb] \
      -yscrollcommand [list utils::set_yscrollbar $c.vb]]
    ttk::scrollbar $c.vb -orient vertical   -command [list $c.tl yview]
    ttk::scrollbar $c.hb -orient horizontal -command [list $c.tl xview]

    utils::tablelist_configure $widgets(lang_table)

    $widgets(lang_table) columnconfigure 0 -name enabled -editable 0 -resizable 0 -stretchable 0 -formatcommand [list pref_ui::empty_string]
    $widgets(lang_table) columnconfigure 1 -name lang    -editable 0 -resizable 0 -stretchable 0
    $widgets(lang_table) columnconfigure 2 -name exts    -editable 1 -resizable 1 -stretchable 1

    bind [$widgets(lang_table) bodytag] <Button-1> [list pref_ui::handle_lang_left_click %W %x %y]

    # Register the widget for search
    register $widgets(lang_table) $wstr General/DisabledLanguages
    register $widgets(lang_table) $wstr General/LanguagePatternOverrides

    grid rowconfigure    $c 0 -weight 1
    grid columnconfigure $c 0 -weight 1
    grid $c.tl -row 0 -column 0 -sticky news
    grid $c.vb -row 0 -column 1 -sticky ns
    grid $c.hb -row 1 -column 0 -sticky ew

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

    pack $e.sf -padx 2 -pady 4 -fill x
    pack $e.if -padx 2 -pady 4 -fill both

    # Initialize the sharing UI
    lassign [share::get_share_info] share_dir share_items
    set enable_share [expr {$share_dir ne ""}]
    set share_changed 0
    foreach {type value} $share_items {
      set pref_ui::share_$type $value
    }
    $widgets(share_entry) insert end $share_dir
    $widgets(share_entry) configure -state readonly

    ###############
    # UPDATES TAB #
    ###############

    $w.nb add [set d [ttk::frame $w.nb.d]] -text [set wstr [msgcat::mc "Updates"]]

    make_cb $d.ucos [msgcat::mc "Automatically check for updates on start"] General/UpdateCheckOnStart

    ttk::frame $d.f
    ttk::label $d.f.ul -text [format "%s: " [set wstr [msgcat::mc "Update using release type"]]]
    set widgets(upd_mb) [ttk::menubutton $d.f.umb -menu [menu $d.updMnu -tearoff 0]]

    if {![string match *Win* $::tcl_platform(os)]} {
      ttk::button $d.upd -style BButton -text [msgcat::mc "Check for Update"] -command [list menus::check_for_update]
    }

    $d.updMnu add radiobutton -label [msgcat::mc "Stable"]      -value "stable" -variable pref_ui::prefs(General/UpdateReleaseType) -command [list pref_ui::set_release_type]
    $d.updMnu add radiobutton -label [msgcat::mc "Development"] -value "devel"  -variable pref_ui::prefs(General/UpdateReleaseType) -command [list pref_ui::set_release_type]

    pack $d.f.ul  -side left -padx 2 -pady 2
    pack $d.f.umb -side left -padx 2 -pady 2
    pack $d.f     -fill x
    if {![string match *Win* $::tcl_platform(os)]} {
      pack $d.upd -padx 2 -pady 2
    }

    # Register the widget for search
    register $widgets(upd_mb) $wstr General/UpdateReleaseType

    # Initialize the release type menubutton text
    set_release_type

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
      set enabled    [expr [lsearch $dis_langs $lang] == -1]
      set extensions [syntax::get_extensions {} $lang]
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
        set lang           [$tbl cellcget $row,lang -text]
        set disabled_langs $prefs(General/DisabledLanguages)
        if {[$tbl cellcget $row,$col -text]} {
          $tbl cellconfigure $row,$col -text 0 -image pref_unchecked
          lappend $disabled_langs $lang
        } else {
          $tbl cellconfigure $row,$col -text 1 -image pref_checked
          set index [lsearch [set $disabled_langs] $lang]
          set $disabled_langs [lreplace [set $disabled_langs] $index $index]
        }
      }
    }

  }

  ######################################################################
  # Save the contents to the preference file.
  proc lang_edit_end_command {tbl row col value} {

    variable prefs

    set lang [$tbl cellcget $row,lang -text]
    set exts [syntax::get_extensions {} $lang]

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

    ttk::frame $w.tf
    ttk::label $w.tf.l -text [format "%s: " [set wstr [msgcat::mc "Theme"]]]
    set widgets(lang_theme) [ttk::menubutton $w.tf.mb -text $prefs(Appearance/Theme) -menu [menu $w.theme_mnu -tearoff 0]]

    # Register the widget for search
    register $widgets(lang_theme) $wstr Appearance/Theme

    pack $w.tf.l  -side left -padx 2 -pady 2
    pack $w.tf.mb -side left -padx 2 -pady 2 -fill x

    ttk::labelframe $w.cf -text [set wstr [msgcat::mc "Syntax Coloring"]]

    # Pack the colorizer frame
    set i 0
    set colorize $prefs(Appearance/Colorize)
    foreach type [lsort [array names colorizers]] {
      set colorizers($type) [expr {[lsearch $colorize $type] != -1}]
      grid [ttk::checkbutton $w.cf.$type -text " $type" -variable pref_ui::colorizers($type) -command [list pref_ui::set_colorizers]] -row [expr $i % 3] -column [expr $i / 3] -sticky news -padx 2 -pady 2
      incr i
    }

    # Register the widget
    register $w.cf.$type $wstr Appearance/Colorize

    # Create fonts frame
    ttk::labelframe $w.ff -text "Fonts"
    ttk::label  $w.ff.l0  -text [format "%s: " [msgcat::mc "Editor"]]
    ttk::label  $w.ff.f0  -text "AaBbCc0123" -font $prefs(Appearance/EditorFont)
    ttk::button $w.ff.b0  -style BButton -text [msgcat::mc "Choose"] -command [list pref_ui::set_font $w.ff.f0 "Select Editor Font" Appearance/EditorFont 1]
    ttk::label  $w.ff.l1  -text [format "%s: " [msgcat::mc "Command launcher entry"]]
    ttk::label  $w.ff.f1  -text "AaBbCc0123" -font $prefs(Appearance/CommandLauncherEntryFont)
    ttk::button $w.ff.b1  -style BButton -text [msgcat::mc "Choose"] -command [list pref_ui::set_font $w.ff.f1 "Select Command Launcher Entry Font" Appearance/CommandLauncherEntryFont 0]
    ttk::label  $w.ff.l2  -text [format "%s: " [msgcat::mc "Command launcher preview"]]
    ttk::label  $w.ff.f2  -text "AaBbCc0123" -font $prefs(Appearance/CommandLauncherPreviewFont)
    ttk::button $w.ff.b2  -style BButton -text [msgcat::mc "Choose"] -command [list pref_ui::set_font $w.ff.f2 "Select Command Launcher Preview Font" Appearance/CommandLauncherPreviewFont 0]

    # Register the widgets for search
    register $w.ff.b0 "" Appearance/EditorFont
    register $w.ff.b1 "" Appearance/CommandLauncherEntryFont
    register $w.ff.b2 "" Appearance/CommandLauncherPreviewFont

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
    pack $w.cf     -fill x -padx 2 -pady 4
    pack $w.ff     -fill x -padx 2 -pady 4

    make_cb $w.cl_pos [msgcat::mc "Remember last position of command launcher"] Appearance/CommandLauncherRememberLastPosition

    # Populate the themes menu
    foreach theme [themes::get_all_themes] {
      $w.theme_mnu add radiobutton -label $theme -variable pref_ui::prefs(Appearance/Theme) -value $theme -command [list pref_ui::set_theme $theme]
    }

  }

  ######################################################################
  # Set the theme to the given value and update UI state.
  proc set_theme {theme} {

    variable widgets

    $widgets(lang_theme) configure -text $theme

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

    ttk::label $w.wwl -text [format "%s: " [set wstr [msgcat::mc "Ruler column"]]]
    set widgets(editor_ww) [$widgets(sb) $w.wwsb {*}$widgets(sb_opts) -from 20 -to 150 -increment 5 -width 3 \
      -state readonly -command [list pref_ui::set_warning_width]]

    register $widgets(editor_ww) $wstr Editor/WarningWidth

    ttk::label $w.sptl -text [format "%s: " [set wstr [msgcat::mc "Spaces per tab"]]]
    set widgets(editor_spt) [$widgets(sb) $w.sptsb {*}$widgets(sb_opts) -from 1 -to 20 -width 3 \
      -state readonly -command [list pref_ui::set_spaces_per_tab]]

    register $widgets(editor_spt) $wstr Editor/SpacesPerTab

    ttk::label $w.isl -text [format "%s: " [set wstr [msgcat::mc "Indentation Spaces"]]]
    set widgets(editor_is) [$widgets(sb) $w.issb {*}$widgets(sb_opts) -from 1 -to 20 -width 3 \
      -state readonly -command [list pref_ui::set_indent_spaces]]

    register $widgets(editor_is) $wstr Editor/IndentSpaces

    ttk::label $w.mul -text [format "%s: " [set wstr [msgcat::mc "Maximum undo history (set to 0 for unlimited)"]]]
    set widgets(editor_mu) [$widgets(sb) $w.musb {*}$widgets(sb_opts) -from 0 -to 200 -increment 10 -width 3 \
      -state readonly -command [list pref_ui::set_max_undo]]

    register $widgets(editor_mu) $wstr Editor/MaxUndo

    ttk::label $w.chdl -text [format "%s: " [set wstr [msgcat::mc "Clipboard history depth"]]]
    set widgets(editor_chd) [$widgets(sb) $w.chdsb {*}$widgets(sb_opts) -from 1 -to 30 -width 3 \
      -state readonly -command [list pref_ui::set_clipboard_history]]

    register $widgets(editor_chd) $wstr Editor/ClipboardHistoryDepth

    ttk::label $w.vmll -text [format "%s: " [set wstr [msgcat::mc "Line count to find for Vim modeline information"]]]
    set widgets(editor_vml) [$widgets(sb) $w.vmlsb {*}$widgets(sb_opts) -from 0 -to 20 -width 3 \
    -state readonly -command [list pref_ui::set_vim_modelines]]

    register $widgets(editor_vml) $wstr Editor/VimModelines

    ttk::label $w.eoll -text [format "%s: " [set wstr [msgcat::mc "End-of-line character when saving"]]]
    set widgets(editor_eolmb) [ttk::menubutton $w.eolmb -menu [menu $w.eol -tearoff 0]]

    foreach {value desc} [list \
      auto [msgcat::mc "Use original EOL character from file"] \
      sys  [msgcat::mc "Use appropriate EOL character on system"] \
      cr   [msgcat::mc "Use single carriage return character"] \
      crlf [msgcat::mc "Use carriate return linefeed sequence"] \
      lf   [msgcat::mc "Use linefeed character"]] {
      $w.eol add radiobutton -label $desc -value $value -variable pref_ui::prefs(Editor/EndOfLineTranslation) -command [list pref_ui::set_eol_translation]
    }

    register $widgets(editor_eolmb) $wstr Editor/EndOfLineTranslation

    ttk::labelframe $w.mcf -text [set wstr [msgcat::mc "Auto-match Characters"]]
    ttk::checkbutton $w.mcf.sr -text [format " %s" [msgcat::mc "Square bracket"]] -variable pref_ui::match_chars(square) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.cu -text [format " %s" [msgcat::mc "Curly bracket"]]  -variable pref_ui::match_chars(curly)  -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.an -text [format " %s" [msgcat::mc "Angled bracket"]] -variable pref_ui::match_chars(angled) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.pa -text [format " %s" [msgcat::mc "Parenthesis"]]    -variable pref_ui::match_chars(paren)  -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.dq -text [format " %s" [msgcat::mc "Double-quote"]]   -variable pref_ui::match_chars(double) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.sq -text [format " %s" [msgcat::mc "Single-quote"]]   -variable pref_ui::match_chars(single) -command [list pref_ui::set_match_chars]
    ttk::checkbutton $w.mcf.bt -text [format " %s" [msgcat::mc "Backtick"]]       -variable pref_ui::match_chars(btick)  -command [list pref_ui::set_match_chars]

    register $w.mcf.sr $wstr Editor/AutoMatchChars

    grid $w.mcf.sr -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mcf.cu -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mcf.an -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mcf.pa -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $w.mcf.dq -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.mcf.sq -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $w.mcf.bt -row 1 -column 2 -sticky news -padx 2 -pady 2

    ttk::labelframe $w.scf -text [set wstr [msgcat::mc "Snippet Completion Characters"]]
    pack [ttk::checkbutton $w.scf.s -text [format " %s" [msgcat::mc "Space"]]  -variable pref_ui::snip_compl(space)  -command [list pref_ui::set_snip_compl]] -side left -padx 2 -pady 2
    pack [ttk::checkbutton $w.scf.t -text [format " %s" [msgcat::mc "Tab"]]    -variable pref_ui::snip_compl(tab)    -command [list pref_ui::set_snip_compl]] -side left -padx 2 -pady 2
    pack [ttk::checkbutton $w.scf.r -text [format " %s" [msgcat::mc "Return"]] -variable pref_ui::snip_compl(return) -command [list pref_ui::set_snip_compl]] -side left -padx 2 -pady 2

    register $w.scf.s $wstr Editor/SnippetCompleters

    ttk::frame $w.cf
    make_cb $w.cf.vm   [msgcat::mc "Enable Vim Mode"]                              Editor/VimMode
    make_cb $w.cf.eai  [msgcat::mc "Enable auto-indentation"]                      Editor/EnableAutoIndent
    make_cb $w.cf.hmc  [msgcat::mc "Automatically highlight matching bracket"]     Editor/HighlightMatchingChar
    make_cb $w.cf.hmmb [msgcat::mc "Automatically highlight mismatching brackets"] Editor/HighlightMismatchingChar
    make_cb $w.cf.rtw  [msgcat::mc "Remove trailing whitespace on save"]           Editor/RemoveTrailingWhitespace
    make_cb $w.cf.sfai [msgcat::mc "Format snippet indentation after insert"]      Editor/SnippetFormatAfterInsert
    make_cb $w.cf.rln  [msgcat::mc "Enable relative line numbering"]               Editor/RelativeLineNumbers

    grid columnconfigure $w 2 -weight 1
    grid columnconfigure $w 3 -weight 1
    grid $w.wwl   -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $w.wwsb  -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $w.sptl  -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.sptsb -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.isl   -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $w.issb  -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid $w.mul   -row 3 -column 0 -sticky news -padx 2 -pady 2
    grid $w.musb  -row 3 -column 1 -sticky news -padx 2 -pady 2
    grid $w.chdl  -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid $w.chdsb -row 4 -column 1 -sticky news -padx 2 -pady 2
    grid $w.vmll  -row 5 -column 0 -sticky news -padx 2 -pady 2
    grid $w.vmlsb -row 5 -column 1 -sticky news -padx 2 -pady 2
    grid $w.eoll  -row 6 -column 0 -sticky news -padx 2 -pady 2
    grid $w.eolmb -row 6 -column 1 -sticky news -padx 2 -pady 2  -columnspan 2
    grid $w.mcf   -row 7 -column 0 -sticky news -padx 2 -pady 10 -columnspan 4
    grid $w.scf   -row 8 -column 0 -sticky news -padx 2 -pady 10 -columnspan 4
    grid $w.cf    -row 9 -column 0 -sticky news -padx 2 -pady 2  -columnspan 4

    # Set the UI state to match preference
    $widgets(editor_ww)  set $prefs(Editor/WarningWidth)
    $widgets(editor_spt) set $prefs(Editor/SpacesPerTab)
    $widgets(editor_is)  set $prefs(Editor/IndentSpaces)
    $widgets(editor_mu)  set $prefs(Editor/MaxUndo)
    $widgets(editor_chd) set $prefs(Editor/ClipboardHistoryDepth)
    $widgets(editor_vml) set $prefs(Editor/VimModelines)

    foreach char [list square curly angled paren double single btick] {
      set match_chars($char) [expr {[lsearch $prefs(Editor/AutoMatchChars) $char] != -1}]
    }

    foreach char [list space tab return] {
      set snip_compl($char) [expr {[lsearch $prefs(Editor/SnippetCompleters) $char] != -1}]
    }

    set_eol_translation

  }

  ######################################################################
  # Sets the Editor/WarningWidth preference value.
  proc set_warning_width {} {

    variable widgets
    variable prefs

    set prefs(Editor/WarningWidth) [$widgets(editor_ww) get]

  }

  ######################################################################
  # Sets the Editor/SpacesPerTab preference value.
  proc set_spaces_per_tab {} {

    variable widgets
    variable prefs

    set prefs(Editor/SpacesPerTab) [$widgets(editor_spt) get]

  }

  ######################################################################
  # Sets the Editor/IndentSpaces preference value.
  proc set_indent_spaces {} {

    variable widgets
    variable prefs

    set prefs(Editor/IndentSpaces) [$widgets(editor_is) get]

  }

  ######################################################################
  # Sets the Editor/MaxUndo preference value.
  proc set_max_undo {} {

    variable widgets
    variable prefs

    set prefs(Editor/MaxUndo) [$widgets(editor_mu) get]

  }

  ######################################################################
  # Sets the Editor/VimModelines preference value.
  proc set_vim_modelines {} {

    variable widgets
    variable prefs

    set prefs(Editor/VimModelines) [$widgets(editor_vml) get]

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

  ######################################################################
  # Sets the Editor/ClipboardHistoryDepth preference value.
  proc set_clipboard_history {} {

    variable widgets
    variable prefs

    set prefs(Editor/ClipboardHistoryDepth) [$widgets(editor_chd) get]

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

    ttk::frame $a.cf
    make_cb $a.cf.aivp [msgcat::mc "Automatically insert vendor prefixes"] Emmet/CSSAutoInsertVendorPrefixes
    make_cb $a.cf.cs   [msgcat::mc "Use shortened colors"]                 Emmet/CSSColorShort
    make_cb $a.cf.fs   [msgcat::mc "Enable fuzzy search"]                  Emmet/CSSFuzzySearch

    ttk::label $a.ccl -text [format "%s: " [set wstr [msgcat::mc "Color value case"]]]
    set widgets(emmet_ccmb) [ttk::menubutton $a.ccmb -menu [menu $a.ccmb_mnu -tearoff 0]]

    foreach {value lbl} [list upper [msgcat::mc "Convert to uppercase"] \
    lower [msgcat::mc "Convert to lowercase"] \
    keep  [msgcat::mc "Retain case"]] {
      $a.ccmb_mnu add radiobutton -label $lbl -value $value -variable pref_ui::prefs(Emmet/CSSColorCase) -command [list pref_ui::set_css_color_case]
    }

    register $widgets(emmet_ccmb) $wstr Emmet/CSSColorCase

    ttk::label $a.dummy -text ""
    ttk::label $a.iul -text [format "%s: " [set wstr [msgcat::mc "Default unit for integer values"]]]
    ttk::entry $a.iue -textvariable pref_ui::prefs(Emmet/CSSIntUnit)

    register $a.iue $wstr Emmet/CSSIntUnit

    ttk::label $a.ful -text [format "%s: " [set wstr [msgcat::mc "Default unit for floating point values"]]]
    ttk::entry $a.fue -textvariable pref_ui::prefs(Emmet/CSSFloatUnit)

    register $a.fue $wstr Emmet/CSSFloatUnit

    ttk::label $a.vsl -text [format "%s: " [set wstr [msgcat::mc "Symbol between CSS property and value"]]]
    ttk::entry $a.vse -textvariable pref_ui::prefs(Emmet/CSSValueSeparator)

    register $a.vse $wstr Emmet/CSSValueSeparator

    ttk::label $a.pel -text [format "%s: " [set wstr [msgcat::mc "Symbol placed at end of CSS property"]]]
    ttk::entry $a.pee -textvariable pref_ui::prefs(Emmet/CSSPropertyEnd)

    register $a.pee $wstr Emmet/CSSPropertyEnd

    grid $a.cf    -row 0 -column 0 -sticky news -padx 2 -pady 2 -columnspan 3
    grid $a.dummy -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $a.ccl   -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $a.ccmb  -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid $a.iul   -row 3 -column 0 -sticky news -padx 2 -pady 2
    grid $a.iue   -row 3 -column 1 -sticky news -padx 2 -pady 2
    grid $a.ful   -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid $a.fue   -row 4 -column 1 -sticky news -padx 2 -pady 2
    grid $a.vsl   -row 5 -column 0 -sticky news -padx 2 -pady 2
    grid $a.vse   -row 5 -column 1 -sticky news -padx 2 -pady 2
    grid $a.pel   -row 6 -column 0 -sticky news -padx 2 -pady 2
    grid $a.pee   -row 6 -column 1 -sticky news -padx 2 -pady 2

    ##########
    # ADDONS #
    ##########

    $w.nb add [set b [ttk::frame $w.nb.af]] -text [msgcat::mc "Addons"]

    foreach {type var} [list Mozilla Emmet/CSSMozPropertiesAddon \
    MS      Emmet/CSSMSPropertiesAddon \
    Opera   Emmet/CSSOPropertiesAddon \
    Webkit  Emmet/CSSWebkitPropertiesAddon] {
      set ltype [string tolower $type]
      ttk::labelframe $b.$ltype -text [set wstr [format "$type %s" [msgcat::mc "Properties"]]]
      pack [tokenentry::tokenentry $b.$ltype.te -height 4 -tokenshape eased] -fill both -expand yes
      bind $b.$ltype.te <<TokenEntryModified>> [list pref_ui::set_properties_addon %W $var]
      pack $b.$ltype -fill x -padx 2 -pady 2
      $b.$ltype.te tokeninsert end $prefs($var)
      register $b.$ltype.te $wstr $var
    }

    ################
    # NODE ALIASES #
    ################

    $w.nb add [set widgets(node_aliases) [set c [ttk::frame $w.nb.nf]]] -text [set wstr [msgcat::mc "Node Aliases"]]

    ttk::frame $c.tf
    set widgets(emmet_na_tl) [tablelist::tablelist $c.tf.tl \
      -columns {0 {Alias} 0 {Node} 0 {Closing} 0 {Attributes}} \
      -exportselection 0 -editselectedonly 1 -stretch all \
      -editstartcommand [list pref_ui::emmet_na_edit_start_command] \
      -editendcommand   [list pref_ui::emmet_na_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $c.tf.hb] \
      -yscrollcommand [list utils::set_yscrollbar $c.tf.vb]]
    ttk::scrollbar $c.tf.vb -orient vertical   -command [list $widgets(emmet_na_tl) yview]
    ttk::scrollbar $c.tf.hb -orient horizontal -command [list $widgets(emmet_na_tl) xview]

    $widgets(emmet_na_tl) columnconfigure 0 -name alias  -editable 1 -stretchable 1 -resizable 1
    $widgets(emmet_na_tl) columnconfigure 1 -name name   -editable 1 -stretchable 1 -resizable 1
    $widgets(emmet_na_tl) columnconfigure 2 -name ending -editable 1 -stretchable 0 -resizable 1 \
      -editwindow ttk::menubutton
    $widgets(emmet_na_tl) columnconfigure 3 -name attrs  -editable 1 -stretchable 1 -resizable 1

    bind $widgets(emmet_na_tl) <<TablelistSelect>> [list pref_ui::handle_emmet_na_select]

    grid rowconfigure    $c.tf 0 -weight 1
    grid columnconfigure $c.tf 0 -weight 1
    grid $c.tf.tl -row 0 -column 0 -sticky news
    grid $c.tf.vb -row 0 -column 1 -sticky ns
    grid $c.tf.hb -row 1 -column 0 -sticky ew

    ttk::frame $c.bf
    ttk::button $c.bf.add -style BButton -text [msgcat::mc "Add"] -command [list pref_ui::emmet_na_add]
    set widgets(emmet_na_del) [ttk::button $c.bf.del -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::emmet_na_del] -state disabled]

    pack $c.bf.add -side left -padx 2 -pady 2
    pack $c.bf.del -side left -padx 2 -pady 2

    ttk::labelframe $c.lf -text [msgcat::mc "Preview"]
    frame $c.lf.f
    set widgets(emmet_na_preview) [ctext $c.lf.f.t -height 10 -state disabled \
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
    set widgets(emmet_aa_tl) [tablelist::tablelist $d.tf.tl -columns {0 {Alias} 0 {Value}} \
      -exportselection 0 -stretch all -editselectedonly 1 \
      -editendcommand [list pref_ui::emmet_aa_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $d.tf.hb] \
      -yscrollcommand [list utils::set_yscrollbar $d.tf.vb]]
    ttk::scrollbar $d.tf.vb -orient vertical   -command [list $d.tf.tl yview]
    ttk::scrollbar $d.tf.hb -orient horizontal -command [list $d.tf.tl xview]

    $widgets(emmet_aa_tl) columnconfigure 0 -name alias -editable 1 -resizable 1 -stretchable 0
    $widgets(emmet_aa_tl) columnconfigure 1 -name value -editable 1 -resizable 1 -stretchable 1

    bind $widgets(emmet_aa_tl) <<TablelistSelect>> [list pref_ui::handle_emmet_aa_select]

    grid rowconfigure    $d.tf 0 -weight 1
    grid columnconfigure $d.tf 0 -weight 1
    grid $d.tf.tl -row 0 -column 0 -sticky news
    grid $d.tf.vb -row 0 -column 1 -sticky ns
    grid $d.tf.hb -row 1 -column 0 -sticky ew

    ttk::frame $d.bf
    ttk::button $d.bf.add -style BButton -text [msgcat::mc "Add"] -command [list pref_ui::emmet_aa_add]
    set widgets(emmet_aa_del) [ttk::button $d.bf.del -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::emmet_aa_del] -state disabled]

    pack $d.bf.add -side left -padx 2 -pady 2
    pack $d.bf.del -side left -padx 2 -pady 2

    ttk::labelframe $d.lf -text [msgcat::mc "Preview"]
    frame $d.lf.f
    set widgets(emmet_aa_preview) [ctext $d.lf.f.t -height 10 -state disabled \
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
  # Updates the properties addon.
  proc set_properties_addon {w var} {

    variable prefs

    set prefs($var) [$w tokenget]

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

    ttk::label $w.mhl -text [format "%s: " [set wstr [msgcat::mc "Set Find History Depth"]]]
    set widgets(find_mh) [$widgets(sb) $w.mh {*}$widgets(sb_opts) -from 0 -to 100 -width 3 \
    -state readonly -command [list pref_ui::set_max_history]]

    register $widgets(find_mh) $wstr Find/MaxHistory

    ttk::label $w.cnl -text [format "%s: " [set wstr [msgcat::mc "Set Find in Files Line Context"]]]
    set widgets(find_cn) [$widgets(sb) $w.cn {*}$widgets(sb_opts) -from 0 -to 10 -width 3 \
    -state readonly -command [list pref_ui::set_context_num]]

    register $widgets(find_cn) $wstr Find/ContextNum

    ttk::label $w.jdl -text [format "%s: " [set wstr [msgcat::mc "Set Jump Distance"]]]
    set widgets(find_jd) [$widgets(sb) $w.jd {*}$widgets(sb_opts) -from 1 -to 20 -width 3 \
    -state readonly -command [list pref_ui::set_jump_distance]]

    register $widgets(find_jd) $wstr Find/JumpDistance

    grid $w.mhl -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $w.mh  -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $w.cnl -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $w.cn  -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.jdl -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $w.jd  -row 2 -column 1 -sticky news -padx 2 -pady 2

    # Initialize the widgets
    $widgets(find_mh) set $prefs(Find/MaxHistory)
    $widgets(find_cn) set $prefs(Find/ContextNum)
    $widgets(find_jd) set $prefs(Find/JumpDistance)

  }

  ######################################################################
  # Sets the MaxHistory preference value from the spinbox.
  proc set_max_history {} {

    variable widgets
    variable prefs

    set prefs(Find/MaxHistory) [$widgets(find_mh) get]

  }

  ######################################################################
  # Sets the ContextNum preference value from the spinbox.
  proc set_context_num {} {

    variable widgets
    variable prefs

    set prefs(Find/ContextNum) [$widgets(find_cn) get]

  }

  ######################################################################
  # Sets the JumpDistance preference value from the spinbox.
  proc set_jump_distance {} {

    variable widgets
    variable prefs

    set prefs(Find/JumpDistance) [$widgets(find_jd) get]

  }

  ###########
  # SIDEBAR #
  ###########

  ######################################################################
  # Creates the sidebar panel.
  proc create_sidebar {w} {

    variable widgets
    variable prefs

    ttk::notebook $w.nb

    $w.nb add [set a [ttk::frame $w.nb.a]] -text [msgcat::mc "Behaviors"]

    make_cb $a.rralc [msgcat::mc "Remove root directory after last sub-file is closed"] Sidebar/RemoveRootAfterLastClose
    make_cb $a.fat   [msgcat::mc "Show folders at top"] Sidebar/FoldersAtTop

    $w.nb add [set b [ttk::frame $w.nb.b]] -text [msgcat::mc "Hiding"]

    make_cb $b.ib [msgcat::mc "Hide binary files"] Sidebar/IgnoreBinaries

    ttk::labelframe $b.pf -text [set wstr [msgcat::mc "Hide Patterns"]]
    pack [set widgets(sb_patterns) [tokenentry::tokenentry $b.pf.te -height 6 -tokenshape eased]] -fill both -expand yes

    register $widgets(sb_patterns) $wstr Sidebar/IgnoreFilePatterns

    bind $widgets(sb_patterns) <<TokenEntryModified>> [list pref_ui::sidebar_pattern_changed]

    pack $b.pf -fill both -expand yes -padx 2 -pady 10

    pack $w.nb -fill both -expand yes

    # Insert the tokens
    $widgets(sb_patterns) tokeninsert end $prefs(Sidebar/IgnoreFilePatterns)

  }

  ######################################################################
  # Called whenever the pattern tokenentry widget is modified.
  proc sidebar_pattern_changed {} {

    variable widgets
    variable prefs

    set prefs(Sidebar/IgnoreFilePatterns) [$widgets(sb_patterns) tokenget]

  }

  ########
  # VIEW #
  ########

  ######################################################################
  # Creates the view panel.
  proc create_view {w} {

    variable widgets
    variable prefs

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
    pack [ttk::label   $w.of.l  -text [format "%s: " [set wstr [msgcat::mc "Recently opened history depth"]]]] -side left -padx 2 -pady 2
    pack [set widgets(view_sro) [$widgets(sb) $w.of.sb {*}$widgets(sb_opts) -from 0 -to 20 -width 2 \
    -state readonly -command [list pref_ui::set_show_recently_opened]]] -side left -padx 2 -pady 2

    register $widgets(view_sro) $wstr View/ShowRecentlyOpened

    pack $w.of -fill x -padx 2 -pady 10

    # Initialize the spinbox value
    $widgets(view_sro) set $prefs(View/ShowRecentlyOpened)

  }

  ######################################################################
  # Sets the View/ShowRecentlyOpened preference value
  proc set_show_recently_opened {} {

    variable widgets
    variable prefs

    set prefs(View/ShowRecentlyOpened) [$widgets(view_sro) get]

  }

  ############
  # SNIPPETS #
  ############

  ######################################################################
  # Create the snippets panel.
  proc create_snippets {w} {

    variable widgets

    ###############
    # TABLE FRAME #
    ###############

    set widgets(snippets_tf) [ttk::frame $w.tf]

    ttk::frame $w.tf.sf
    wmarkentry::wmarkentry $w.tf.sf.e -width 20 -watermark [msgcat::mc "Search Snippets"] \
      -validate key -validatecommand [list pref_ui::snippets_search %P]
    set widgets(snippets_lang) [ttk::menubutton $w.tf.sf.mb -text [msgcat::mc "Language"] \
      -menu [pref_ui::snippets_create_menu $w]]

    pack $w.tf.sf.e  -side left  -padx 2 -pady 2
    pack $w.tf.sf.mb -side right -padx 2 -pady 2

    ttk::frame $w.tf.tf
    set widgets(snippets_tl) [tablelist::tablelist $w.tf.tf.tl -columns {0 {Keyword} 0 {Snippet}} \
      -exportselection 0 -stretch all \
      -xscrollcommand [list utils::set_xscrollbar $w.tf.tf.hb] \
      -yscrollcommand [list utils::set_yscrollbar $w.tf.tf.vb]]
    ttk::scrollbar $w.tf.tf.vb -orient vertical   -command [list $w.tf.tf.tl yview]
    ttk::scrollbar $w.tf.tf.hb -orient horizontal -command [list $w.tf.tf.tl xview]

    utils::tablelist_configure $widgets(snippets_tl)

    $widgets(snippets_tl) columnconfigure 0 -name keyword -editable 0 -resizable 0 -stretchable 0
    $widgets(snippets_tl) columnconfigure 1 -name snippet -editable 0 -resizable 1 -stretchable 1 \
      -wrap 0 -maxwidth 50 -formatcommand pref_ui::snippets_format_snippet

    bind $widgets(snippets_tl)           <<TablelistSelect>> [list pref_ui::snippets_select]
    bind [$widgets(snippets_tl) bodytag] <Double-Button-1>   [list pref_ui::snippets_edit]

    grid rowconfigure    $w.tf.tf 0 -weight 1
    grid columnconfigure $w.tf.tf 0 -weight 1
    grid $w.tf.tf.tl -row 0 -column 0 -sticky news
    grid $w.tf.tf.vb -row 0 -column 1 -sticky ns
    grid $w.tf.tf.hb -row 1 -column 0 -sticky ew

    ttk::frame  $w.tf.bf
    ttk::button $w.tf.bf.add -style BButton -text [msgcat::mc "+"] -width 2 -command [list pref_ui::snippets_add]
    set widgets(snippets_del) [ttk::button $w.tf.bf.del -style BButton -text [msgcat::mc "-"] \
      -width 2 -command [list pref_ui::snippets_del] -state disabled]

    pack $w.tf.bf.add -side left -padx 2 -pady 2
    pack $w.tf.bf.del -side left -padx 2 -pady 2

    pack $w.tf.sf -fill x
    pack $w.tf.tf -fill both -expand yes
    pack $w.tf.bf -fill x

    ##############
    # EDIT FRAME #
    ##############

    set widgets(snippets_ef) [ttk::frame $w.ef]

    ttk::frame $w.ef.kf
    ttk::label $w.ef.kf.l -text [format "%s: " [msgcat::mc "Keyword"]]
    set widgets(snippets_keyword) [ttk::entry $w.ef.kf.e -validate key -validatecommand [list pref_ui::snippets_keyword_changed %P]]

    pack $w.ef.kf.l -side left -padx 2 -pady 2
    pack $w.ef.kf.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::labelframe $w.ef.tf -text [msgcat::mc "Snippet Text"]
    frame $w.ef.tf.tf
    set widgets(snippets_text) [ctext $w.ef.tf.tf.t -wrap none \
      -xscrollcommand [list $w.ef.tf.tf.hb set] -yscrollcommand [list $w.ef.tf.tf.vb set]]
    scroller::scroller $w.ef.tf.tf.vb -orient vertical   -autohide 1 -command [list $w.ef.tf.tf.t yview]
    scroller::scroller $w.ef.tf.tf.hb -orient horizontal -autohide 0 -command [list $w.ef.tf.tf.t xview]

    bind $widgets(snippets_text) <<Modified>> [list if {[pref_ui::snippets_text_changed]} break]

    theme::register_widget $widgets(snippets_text) syntax
    theme::register_widget $w.ef.tf.tf.vb text_scrollbar
    theme::register_widget $w.ef.tf.tf.hb text_scrollbar

    indent::add_bindings $widgets(snippets_text)

    grid rowconfigure    $w.ef.tf.tf 0 -weight 1
    grid columnconfigure $w.ef.tf.tf 0 -weight 1
    grid $w.ef.tf.tf.t  -row 0 -column 0 -sticky news
    grid $w.ef.tf.tf.vb -row 0 -column 1 -sticky ns
    grid $w.ef.tf.tf.hb -row 1 -column 0 -sticky ew

    pack $w.ef.tf.tf -fill both -expand yes

    ttk::frame  $w.ef.bf
    set widgets(snippets_ins)  [ttk::button $w.ef.bf.insert -style BButton -text [msgcat::mc "Insert"] -width 6 -command [list pref_ui::snippets_insert]]
    set widgets(snippets_save) [ttk::button $w.ef.bf.save -style BButton -text [msgcat::mc "Save"] \
      -width 6 -command [list pref_ui::snippets_save] -state disabled]
    ttk::button $w.ef.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command [list pref_ui::snippets_cancel]

    pack $w.ef.bf.insert -side left  -padx 2 -pady 2
    pack $w.ef.bf.cancel -side right -padx 2 -pady 2
    pack $w.ef.bf.save   -side right -padx 2 -pady 2

    pack $w.ef.kf -fill x
    pack $w.ef.tf -fill both -expand yes
    pack $w.ef.bf -fill x

    # Display the table frame
    pack $w.tf -fill both -expand yes

    # Setup the snippet insert menu
    set widgets(snippets_ins_menu) [menu $w.insPopup -tearoff 0]
    $widgets(snippets_ins_menu) add cascade -label [format "%s / %s" [msgcat::mc "Date"] [msgcat::mc "Time"]] -menu [menu $w.datePopup -tearoff 0]
    $widgets(snippets_ins_menu) add cascade -label [msgcat::mc "File"] -menu [menu $w.filePopup -tearoff 0]
    $widgets(snippets_ins_menu) add separator
    $widgets(snippets_ins_menu) add command -label [msgcat::mc "Selected Text"] -command [list pref_ui::snippets_insert_str "\$SELECTED_TEXT"]
    $widgets(snippets_ins_menu) add command -label [msgcat::mc "Clipboard"]     -command [list pref_ui::snippets_insert_str "\$CLIPBOARD"]
    $widgets(snippets_ins_menu) add separator
    $widgets(snippets_ins_menu) add command -label [msgcat::mc "Tab Stop"]      -command [list pref_ui::snippets_insert_str "\${1}"]
    $widgets(snippets_ins_menu) add command -label [msgcat::mc "Cursor"]        -command [list pref_ui::snippets_insert_str "\${0}"]

    # Setup the date/time submenu
    $w.datePopup add command -label "01/01/2001" -command [list pref_ui::snippets_insert_str "\$CURRENT_DATE"]
    $w.datePopup add command -label "01:01 PM"   -command [list pref_ui::snippets_insert_str "\$CURRENT_TIME"]
    $w.datePopup add separator
    $w.datePopup add command -label "Jan"        -command [list pref_ui::snippets_insert_str "\$CURRENT_MON"]
    $w.datePopup add command -label "January"    -command [list pref_ui::snippets_insert_str "\$CURRENT_MONTH"]
    $w.datePopup add command -label " 1"         -command [list pref_ui::snippets_insert_str "\$CURRENT_MON1"]
    $w.datePopup add command -label "01"         -command [list pref_ui::snippets_insert_str "\$CURRENT_MON2"]
    $w.datePopup add separator
    $w.datePopup add command -label "Mon"        -command [list pref_ui::snippets_insert_str "\$CURRENT_DAYN"]
    $w.datePopup add command -label "Monday"     -command [list pref_ui::snippets_insert_str "\$CURRENT_DAYNAME"]
    $w.datePopup add command -label "1"          -command [list pref_ui::snippets_insert_str "\$CURRENT_DAY1"]
    $w.datePopup add command -label "01"         -command [list pref_ui::snippets_insert_str "\$CURRENT_DAY2"]
    $w.datePopup add separator
    $w.datePopup add command -label "01"         -command [list pref_ui::snippets_insert_str "\$CURRENT_YEAR2"]
    $w.datePopup add command -label "2001"       -command [list pref_ui::snippets_insert_str "\$CURRENT_YEAR"]

    # Setup the file submenu
    $w.filePopup add command -label [msgcat::mc "Current Directory"]     -command [list pref_ui::snippets_insert_str "\$DIRECTORY"]
    $w.filePopup add command -label [msgcat::mc "Current File Pathname"] -command [list pref_ui::snippets_insert_str "\$FILEPATH"]
    $w.filePopup add command -label [msgcat::mc "Current Filename"]      -command [list pref_ui::snippets_insert_str "\$FILENAME"]
    $w.filePopup add separator
    $w.filePopup add command -label [msgcat::mc "Current Line"]          -command [list pref_ui::snippets_insert_str "\$CURRENT_LINE"]
    $w.filePopup add command -label [msgcat::mc "Current Word"]          -command [list pref_ui::snippets_insert_str "\$CURRENT_WORD"]
    $w.filePopup add separator
    $w.filePopup add command -label [msgcat::mc "Current Line Number"]   -command [list pref_ui::snippets_insert_str "\$LINE_NUMBER"]
    $w.filePopup add command -label [msgcat::mc "Current Line Column"]   -command [list pref_ui::snippets_insert_str "\$LINE_INDEX"]

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
    syntax::set_language $widgets(snippets_text) "HTML"

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
    syntax::populate_syntax_menu $widgets(snippets_lang_menu) pref_ui::snippets_set_language pref_ui::snip_data(lang) "All"

    return $widgets(snippets_lang_menu)

  }

  ######################################################################
  # Sets the current language.
  proc snippets_set_language {lang} {

    variable widgets

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
    foreach item [snippets::load_list $snip_data(lang)] {
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

    pack $w.sf.search -side left -padx 2 -pady 2

    ttk::frame $w.tf
    set widgets(shortcut_tl) [tablelist::tablelist $w.tf.tl -columns {0 {Menu Item} 0 {Shortcut}} \
      -height 20 -exportselection 0 -stretch all \
      -yscrollcommand [list $w.tf.vb set]]
    ttk::scrollbar $w.tf.vb -orient vertical -command [list $w.tf.tl yview]

    utils::tablelist_configure $widgets(shortcut_tl)

    $widgets(shortcut_tl) columnconfigure 0 -name label    -editable 0 -resizable 0 -stretchable 1
    $widgets(shortcut_tl) columnconfigure 1 -name shortcut -editable 0 -resizable 0 -stretchable 0 -formatcommand [list pref_ui::shortcut_format]

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

    grid rowconfigure    $w.tf 0 -weight 1
    grid columnconfigure $w.tf 0 -weight 1
    grid $w.tf.tl -row 0 -column 0 -sticky news
    grid $w.tf.vb -row 0 -column 1 -sticky ns
    grid $w.tf.sf -row 1 -column 0 -sticky ew -columnspan 2

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
  # Called whenever the modifier or symbol combobox change.  Handles the
  # state of the Update button and update the values available in the
  # combobox value lists.
  proc shortcut_changed {} {

    variable widgets

    # Make sure that the Update button is enabled
    if {([$widgets(shortcut_mod) get] ne "") && ([$widgets(shortcut_sym) get] ne "")} {
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

    # Iterate through the table finding partial matches
    foreach tl_shortcut [$widgets(shortcut_tl) getcolumn shortcut] {
      if {$tl_shortcut ne ""} {
        set tl_list [split $tl_shortcut -]
        set tl_mod  [lrange $tl_list 0 end-1]
        set tl_sym  [lindex $tl_list end]
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
      $widgets(shortcut_mod) set [join [lrange $value 0 3] ""]
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
        set mods [list Cmd Ctrl Alt Shift \
                       Ctrl-Cmd Alt-Cmd Shift-Cmd Ctrl-Shift Ctrl-Alt Shift-Alt \
                       Ctrl-Alt-Cmd Ctrl-Alt-Shift Ctrl-Shift-Cmd Alt-Shift-Cmd \
                       Ctrl-Alt-Shift-Cmd]
      }
      win32 -
      x11 {
        set mods [list Ctrl Alt Shift \
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
                       {;} \" \' < , > . {\?} / Up Down Left Right Space Tab]

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

    if {[set mod [$widgets(shortcut_mod) get]] ne ""} {
      set sym [$widgets(shortcut_sym) get]
      if {$mod ne ""} {
        if {[tk windowingsystem] eq "aqua"} {
          set value [list * * * * $sym]
          foreach elem [split $mod ""] {
            lset value {*}[bindings::accelerator_mapping $elem]
          }
          set value [join [string map {* {}} $value] -]
        } else {
          set value "$mod-$sym"
        }
      }
    }

    # Set the shortcut cell value
    $widgets(shortcut_tl) cellconfigure [$widgets(shortcut_tl) curselection],shortcut -text $value

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
      lassign [$widgets(shortcut_tl) get $i] mnu_path shortcut
      if {$shortcut ne ""} {
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
          $widgets(shortcut_tl) insert end \
          [list "${prefix}[$mnu entrycget $i -label]" [$mnu entrycget $i -accelerator]]
        }
      }
    }

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

    ttk::label $a.ugfl -text [format "%s: " [set wstr1 [msgcat::mc "User guide format"]]]
    set widgets(advanced_ugf) [ttk::menubutton $a.ugfmb -menu [menu $a.ugf_mnu -tearoff 0]]
    ttk::label $a.dmel -text [format "%s: " [set wstr2 [msgcat::mc "Default Markdown Export Extension"]]]
    set widgets(advanced_dme) [ttk::menubutton $a.dmemb -menu [menu $a.dme_mnu -tearoff 0]]

    register $widgets(advanced_ugf) $wstr1 Help/UserGuideFormat
    register $widgets(advanced_dme) $wstr2 General/DefaultMarkdownExportExtension

    foreach type [list pdf epub] {
      $a.ugf_mnu add radiobutton -label $type -value $type -variable pref_ui::prefs(Help/UserGuideFormat) -command [list pref_ui::set_user_guide_format]
    }

    foreach type [list html htm xhtml] {
      $a.dme_mnu add radiobutton -label $type -value $type -variable pref_ui::prefs(General/DefaultMarkdownExportExtension) -command [list pref_ui::set_default_markdown_export_ext]
    }

    grid $a.ugfl  -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $a.ugfmb -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $a.dmel  -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $a.dmemb -row 1 -column 1 -sticky news -padx 2 -pady 2

    ###############
    # DEVELOPMENT #
    ###############

    $w.nb add [set b [ttk::frame $w.nb.b]] -text [msgcat::mc "Development"]

    make_cb $b.dm  [msgcat::mc "Enable development mode"]            Debug/DevelopmentMode
    make_cb $b.sdl [msgcat::mc "Show diagnostic logfile at startup"] Debug/ShowDiagnosticLogfileAtStartup

    ttk::labelframe $b.df -text [set wstr [msgcat::mc "Logfile Directory"]]
    pack [set widgets(advanced_ld) [ttk::label $b.df.l]] -side left -fill x -padx 2 -pady 2
    pack [ttk::button $b.df.b -style BButton -text [format "%s..." [msgcat::mc "Browse"]] -command [list pref_ui::get_log_directory]] -side right -padx 2 -pady 2

    # Register the widget for search
    register $b.df.b $wstr Debug/LogDirectory

    pack $b.df -fill x -padx 2 -pady 10

    ttk::labelframe $b.pf -text [msgcat::mc "Profiler Options"]
    ttk::label $b.pf.prsl -text [format "%s: " [set wstr [msgcat::mc "Sorting Column"]]]
    set widgets(advanced_prs) [ttk::menubutton $b.pf.prsmb -text $prefs(Tools/ProfileReportSortby) -menu [menu $b.pf.prs_mnu -tearoff 0]]

    register $widgets(advanced_prs) $wstr Tools/ProfileReportSortby

    foreach lbl [list calls real cpu real_per_call cpu_per_call] {
      $b.pf.prs_mnu add radiobutton -label $lbl -value $lbl -variable pref_ui::prefs(Tools/ProfileReportSortby) -command [list pref_ui::set_profile_report_sortby]
    }

    ttk::label $b.pf.prol -text [format "%s: " [set wstr [msgcat::mc "Report Options"]]]
    set widgets(advanced_pro) [ttk::entry $b.pf.proe -validate key -validatecommand [list pref_ui::set_profile_report_options]]

    register $widgets(advanced_pro) $wstr Tools/ProfileReportOptions

    grid columnconfigure $b.pf 1 -weight 1
    grid $b.pf.prsl  -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $b.pf.prsmb -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $b.pf.prol  -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $b.pf.proe  -row 1 -column 1 -sticky news -padx 2 -pady 2

    pack $b.pf -fill x -padx 2 -pady 10

    ##############
    # NFS MOUNTS #
    ##############

    $w.nb add [set c [ttk::frame $w.nb.c]] -text [set wstr [format "NFS %s" [msgcat::mc "Mounts"]]]

    ttk::frame $c.f
    set widgets(advanced_tl) [tablelist::tablelist $c.f.tl -columns [list 0 [msgcat::mc "Host"] 0 [format "NFS %s" [msgcat::mc "Base Directory"]] 0 [msgcat::mc "Remote Base Directory"]] \
      -exportselection 0 -stretch all -editselectedonly 1 -showseparators 1 \
      -editendcommand [list pref_ui::nfs_edit_end_command] \
      -xscrollcommand [list utils::set_xscrollbar $c.f.hb] \
      -yscrollcommand [list utils::set_yscrollbar $c.f.vb]]
    ttk::scrollbar $c.f.vb -orient vertical   -command [list $c.f.tl yview]
    ttk::scrollbar $c.f.hb -orient horizontal -command [list $c.f.tl xview]

    register $widgets(advanced_tl) $wstr NFSMounts

    utils::tablelist_configure $widgets(advanced_tl)

    $widgets(advanced_tl) columnconfigure 0 -name host   -editable 1 -resizable 1 -stretchable 1
    $widgets(advanced_tl) columnconfigure 1 -name nfs    -editable 1 -resizable 1 -stretchable 1
    $widgets(advanced_tl) columnconfigure 2 -name remote -editable 1 -resizable 1 -stretchable 1

    bind $widgets(advanced_tl) <<TablelistSelect>> [list pref_ui::handle_nfs_select]

    grid rowconfigure    $c.f 0 -weight 1
    grid columnconfigure $c.f 0 -weight 1
    grid $c.f.tl -row 0 -column 0 -sticky news
    grid $c.f.vb -row 0 -column 1 -sticky ns
    grid $c.f.hb -row 1 -column 0 -sticky ew

    ttk::frame $c.bf
    set widgets(advanced_nfs_add) [ttk::button $c.bf.add -style BButton -text [msgcat::mc "Add"]    -command [list pref_ui::nfs_add]]
    set widgets(advanced_nfs_del) [ttk::button $c.bf.del -style BButton -text [msgcat::mc "Delete"] -command [list pref_ui::nfs_delete] -state disabled]

    pack $c.bf.add -side left -padx 2 -pady 2
    pack $c.bf.del -side left -padx 2 -pady 2

    pack $c.f  -fill both -expand yes
    pack $c.bf -fill x

    pack $w.nb -fill both -expand yes

    # Initialize the UI state
    set_user_guide_format
    set_default_markdown_export_ext
    set_profile_report_sortby

    $widgets(advanced_ld) configure -text $prefs(Debug/LogDirectory)
    $widgets(advanced_pro) insert end $prefs(Tools/ProfileReportOptions)

    foreach {host values} $prefs(NFSMounts) {
      lassign $values nfs_mount remote_mount
      $widgets(advanced_tl) insert end [list $host $nfs_mount $remote_mount]
    }

  }

  ######################################################################
  # Updates the UI state when the Help/UserGuideFormat preference value
  # changes.
  proc set_user_guide_format {} {

    variable widgets
    variable prefs

    $widgets(advanced_ugf) configure -text $prefs(Help/UserGuideFormat)

  }

  ######################################################################
  # Updates the UI state when the General/DefaultMarkdownExportExtension
  # preference value changes.
  proc set_default_markdown_export_ext {} {

    variable widgets
    variable prefs

    $widgets(advanced_dme) configure -text $prefs(General/DefaultMarkdownExportExtension)

  }

  ######################################################################
  # Gets a logfile directory from the user using a choose directory dialog
  # box.
  proc get_log_directory {} {

    variable widgets
    variable prefs

    if {[set dname [tk_chooseDirectory -parent .prefwin -title [msgcat::mc "Choose Logfile Directory"]]] ne ""} {
      $widgets(advanced_ld) configure -text $dname
      set prefs(Debug/LogDirectory) $dname
    }

  }

  ######################################################################
  # Updates the UI when the Tools/ProfileReportSortby preference item is set.
  proc set_profile_report_sortby {} {

    variable widgets
    variable prefs

    $widgets(advanced_prs) configure -text $prefs(Tools/ProfileReportSortby)

  }

  ######################################################################
  # Sets the profile report options to the value in the advanced_pro entry widget.
  proc set_profile_report_options {} {

    variable widgets
    variable prefs

    set prefs(Tools/ProfileReportOptions) [$widgets(advanced_pro) get]

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
