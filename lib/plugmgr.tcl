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
# Name:    plugmgr.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    12/06/2018
# Brief:   Namespace for the plugin manager.
######################################################################

namespace eval plugmgr {

  array set default_pdata {
    author        "Anonymous"
    email         ""
    website       ""
    version       "1.0"
    category      "Miscellaneous"
    description   ""
    release_notes ""
  }

  ######################################################################
  # Adds a single plugin to the plugin database file.  Returns the
  # data that is stored in the plugin entry.
  proc add_plugin {dbfile name args} {

    variable default_pdata

    # Store the important plugin values
    array set pdata [array get default_pdata]
    foreach {attr value} $args {
      if {[info exists pdata($attr)]} {
        set pdata($attr) $value
      }
    }

    if {[file exists $dbfile]} {

      # Read in the existing values
      if {[catch { tkedat::read $dbfile } rc]} {
        return -code error "Unable to read the given plugin database file"
      }

      array set data    $rc
      array set plugins $data(plugins)

    }

    set plugins($name) [array get pdata]
    set data(plugins)  [array get plugins]

    # Save the file
    if {[catch { tkedat::write $dbfile [array get data] } rc]} {
      return -code error "Unable to update the plugin database file"
    }

    return [array get pdata]

  }

  ######################################################################
  # Displays the popup window to allow the user to adjust plugin information
  # prior to exporting.
  proc export_win {plugdir} {

    set w [toplevel .pmewin]
    wm title     $w [msgcat::mc "Export Plugin"]
    wm transient $w .

    ttk::frame     $w.tf
    ttk::label     $w.tf.vl  -text [format "%s: " [msgcat::mc "Version"]]
    ttk::combobox  $w.tf.vcb
    ttk::label     $w.tf.rl  -text [format "%s: " [msgcat::mc "Release Notes"]]
    ttk::label     $w.tf.ol  -text [format "%s: " [msgcat::mc "Output Directory"]]
    ttk::entry     $w.tf.oe
    ttk::button    $w.tf.ob  -style BButton -text [msgcat::mc "Choose"] -command [list plugmgr::choose_output_dir $w]

    ttk::frame     $w.tf.tf
    text           $w.tf.tf.t  -wrap word -xscrollcommand [list $w.tf.tf.vb set] -yscrollcommand [list $w.tf.tf.hb set]
    ttk::scrollbar $w.tf.tf.vb -orient vertical   -command [list $w.tf.tf.t yview]
    ttk::scrollbar $w.tf.tf.hb -orient horizontal -command [list $w.tf.tf.t xview]

    grid rowconfigure    $w.tf.tf 0 -weight 1
    grid columnconfigure $w.tf.tf 0 -weight 1
    grid $w.tf.tf.t  -row 0 -column 0 -sticky news
    grid $w.tf.tf.vb -row 0 -column 1 -sticky ns

    grid rowconfigure $w.tf    1 -weight 1
    grid columnconfigure $w.tf 1 -weight 1
    grid $w.tf.vl  -row 0 -column 0 -sticky nw   -padx 2 -pady 2
    grid $w.tf.vcb -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $w.tf.rl  -row 1 -column 0 -sticky nw   -padx 2 -pady 2
    grid $w.tf.tf  -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.tf.ol  -row 2 -column 0 -sticky nw   -padx 2 -pady 2
    grid $w.tf.oe  -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid $w.tf.ob  -row 2 -column 2 -sticky news -padx 2 -pady 2

    ttk::separator $w.sep -orient horizontal

    set width [msgcat::mcmax "Export" "Cancel"]

    ttk::frame $w.bf
    ttk::button $w.bf.export -style BButton -text [msgcat::mc "Export"] -width $width -command [list plugmgr::export $w $plugdir] -state disabled
    ttk::button $w.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width $width -command [list destroy $w]

    pack $w.bf.cancel -side right -padx 2 -pady 2
    pack $w.bf.export -side right -padx 2 -pady 2

    pack $w.tf  -fill both -expand yes
    pack $w.sep -fill x
    pack $w.bf  -fill x

    # Get the field values to populate
    lassign [get_versions $plugdir] version next_versions
    set release_notes [get_release_notes $plugdir]

    # Populate fields
    $w.tf.vcb configure -values $next_versions
    $w.tf.vcb set $version
    $w.tf.tf.t insert end $release_notes
    $w.tf.oe insert end [preferences::get General/DefaultPluginExportDirectory]
    $w.tf.oe configure -state readonly

    # Set the focus on the version entry field
    focus $w.tf.vcb

  }

  ######################################################################
  # Updates the state of the export button.
  proc handle_export_button_state {w {version ""}} {

    if {$version eq ""} {
      set version [$w.tf.vcb get]
    }

    set odir [$w.tf.oe get]

    if {[regexp {^\d+(\.\d+)+$} $version] && ($odir ne "")} {
      $w.bf.export configure -state normal
    } else {
      $w.bf.export configure -state disabled
    }

  }

  ######################################################################
  # If the given value is a valid version value, allow the Export button
  # to be clickable.
  proc check_version {w value} {

    handle_export_button_state $w $value

    return 1

  }

  ######################################################################
  # Allows the user to select an alternative output directory.
  proc choose_output_dir {w} {

    # Get the current output directory
    set initial_dir [$w.tf.oe get]

    if {$initial_dir eq ""} {
      if {[preferences::get General/DefaultPluginExportDirectory] ne ""} {
        set initial_dir [preferences::get General/DefaultPluginExportDirectory]
      } else {
        set initial_dir [gui::get_browse_directory]
      }
    }

    # Get the directory to save the file to
    if {[set odir [tk_chooseDirectory -parent $w -initialdir $initial_dir]] ne ""} {
      $w.tf.oe configure -state normal
      $w.tf.oe delete 0 end
      $w.tf.oe insert end $odir
      $w.tf.oe configure -state disabled
      handle_export_button_state $w
    }

  }

  ######################################################################
  # Get version information from the given plugin directory.
  proc get_versions {plugdir} {

    if {[catch { tkedat::read [file join $plugdir header.tkedat] } rc]} {
      return [list "1.0" {}]
    } else {
      array set header $rc
      set i       0
      set version [split $header(version) .]
      foreach num $version {
        if {$i == 0} {
          lappend next_versions "[expr $num + 1].0"
        } else {
          lappend next_versions [join [list {*}[lrange $version 0 [expr $i - 1]] [expr $num + 1]] .]
        }
        incr i
      }
      set next_versions [linsert $next_versions end-1 [join [list {*}$version 1] .]]
      return [list $header(version) [lreverse $next_versions]]
    }

  }

  ######################################################################
  # Get release notes from the given plugin directory.
  proc get_release_notes {plugdir} {

    if {[catch { open [file join $plugdir release_nodes.md] r } rc]} {
      return ""
    }

    set contents [read $rc]
    close $rc

    return $contents

  }

  ######################################################################
  # Update the version information.
  proc update_version {plugdir version} {

    set header [file join $plugdir header.tkedat]

    if {[catch { tkedat::read $header } rc]} {
      return -code error "Unable to read header.tkedat"
    }

    array set contents $rc

    if {$version ne $contents(version)} {
      set contents(version) $version
      if {[catch { tkedat::write $header [array get contents] } rc]} {
        return -code error "Unable to write header.tkedat"
      }
    }

  }

  ######################################################################
  # Updates the given release notes.
  proc update_release_notes {plugdir notes} {

    set release_notes [file join $plugdir release_notes.md]

    if {[catch { open $release_notes w } rc]} {
      return -code error "Unable to write release notes"
    }

    puts $rc $notes
    close $rc

  }

  ######################################################################
  # Takes the version number and the release notes and puts them into the
  # plugin directory and then perform the bundling process.
  proc export {w plugdir} {

    # Get the values from the interface
    set version       [$w.tf.vcb get]
    set release_notes [$w.tf.tf.t get 1.0 end-1c]
    set odir          [$w.tf.oe get]

    # Update the version information
    update_version $plugdir $version

    # Update the release notes
    update_release_notes $plugdir $release_notes

    # Create the plugin bundle
    plugins::export_plugin . [file tail $plugdir] $odir

    # Destroy the window
    destroy $w

  }

}
