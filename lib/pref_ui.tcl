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

    }

    $widgets(bar) selection set 0
    show_panel general

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

    $w.nb add [set c [ttk::frame $w.nb.c]] -text "Language Overrides"

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
