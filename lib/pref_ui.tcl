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

  array set widgets {}

  ######################################################################
  # Create the preferences window.
  proc create {} {

    variable widgets

    if {![winfo exists .prefwin]} {

      toplevel     .prefwin
      wm title     .prefwin "User Preferences"
      wm transient .prefwin .
      wm minsize   .prefwin 600 400

      ttk::frame .prefwin.bf
      set widgets(bar) [listbox .prefwin.bf.lb -relief flat]

      pack $widgets(bar) -fill both -expand yes

      bind $widgets(bar) <<ListboxSelect>> [list pref_ui::show_selected_panel]

      set widgets(frame) [ttk::frame .prefwin.pf]

      grid rowconfigure    .prefwin 0 -weight 1
      grid columnconfigure .prefwin 1 -weight 1
      grid .prefwin.bf -row 0 -column 0 -sticky news
      grid .prefwin.pf -row 0 -column 1 -sticky news

      foreach pane [list general appearance editor emmet find sidebar tools view] {
        $widgets(bar) insert end [string totitle $pane]
        create_$pane [set widgets($pane) [ttk::frame $widgets(frame).$pane]]
      }

      $widgets(bar) selection set 0
      show_panel general

      trace add variable [[ns preferences]::ref] write [list pref_ui::handle_prefs_change]

    }

  }

  ######################################################################
  # Handles any changes to the preference array.
  proc handle_prefs_change {name1 name2 op} {

    if {[winfo exists .prefwin]} {
      # [ns preferences]::save_prefs
      puts "Saving prefs"
    }

  }

  ######################################################################
  # Creates the general panel.
  proc create_general {w} {

    variable widgets

    set lls  [[ns preferences]::ref General/LoadLastSession]
    set eolc [[ns preferences]::ref General/ExitOnLastClose]
    set ucos [[ns preferences]::ref General/UpdateCheckOnStart]
    set acwd [[ns preferences]::ref General/AutoChangeWorkingDirectory]

    # LoadLastSession - check
    # ExitOnLastClose - check
    # UpdateCheckOnStart - check
    # AutoChangeWorkingDirectory - check
    # UpdateReleaseType  - menubutton {stable devel}
    # DefaultFileBrowsingDirectory - menubutton {last, buffer, current, directory entry}
    # Variables       - list
    # LanguagePatternOverrides - list {language +/- overrides}

    pack [ttk::notebook $w.nb] -fill both -expand yes

    $w.nb add [set a [ttk::frame $w.nb.a]] -text "General"

    pack [ttk::checkbutton $a.lls  -text "Automatically load last session on start" -variable $lls] -fill x
    pack [ttk::checkbutton $a.eolc -text "Exit the application after the last tab is closed" -variable $eolc] -fill x
    pack [ttk::checkbutton $a.ucos -text "Automatically check for updates on start" -variable $ucos] -fill x
    pack [ttk::checkbutton $a.acwd -text "Automatically set the current working directory to the current tabs directory" -variable $acwd] -fill x

    $w.nb add [set b [ttk::frame $w.nb.b]] -text "Variables"

    ttk::frame $b.f
    set widgets(var_table) [tablelist::tablelist $b.f.tl -columns {0 {Variable} 0 {Value}} \
      -stretch all -editselectedonly 1 -exportselection 1 \
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

    $w.nb add [set c [ttk::frame $w.nb.c]] -text "Language Overrides"

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
  # Creates the appearance panel.
  proc create_appearance {w} {

    variable widgets

    pack [ttk::label $w.tbd -text "Appearance"]

  }

  ######################################################################
  # Creates the editor panel.
  proc create_editor {w} {

    variable widgets

    pack [ttk::label $w.tbd -text "Editor"]

  }

  ######################################################################
  # Creates the Emmet panel.
  proc create_emmet {w} {

    variable widgets

    pack [ttk::label $w.tbd -text "Emmet"]

  }

  ######################################################################
  # Creates the find panel.
  proc create_find {w} {

    variable widgets

    pack [ttk::label $w.tbd -text "Find"]

  }

  ######################################################################
  # Creates the sidebar panel.
  proc create_sidebar {w} {

    variable widgets

    pack [ttk::label $w.tbd -text "Sidebar"]

  }

  ######################################################################
  # Creates the tools panel.
  proc create_tools {w} {

    variable widgets

    pack [ttk::label $w.tbd -text "Tools"]

  }

  ######################################################################
  # Creates the view panel.
  proc create_view {w} {

    variable widgets

    pack [ttk::label $w.tbd -text "View"]

  }

  ######################################################################
  # Displays the selected panel in the listbox.
  proc show_selected_panel {} {

    variable widgets

    set selected [$widgets(bar) curselection]
    set panel    [string tolower [$widgets(bar) get $selected]]

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

}
