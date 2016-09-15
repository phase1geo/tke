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
# Name:    sync.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    9/14/2016
# Brief:   Namespace that handles settings sync.
######################################################################

namespace eval sync {

  source [file join $::tke_dir lib ns.tcl]

  variable last_sync_dir   "none"
  variable last_sync_items "none"
  variable sync_local      [file join $::tke_home sync_dir]
  variable use_sync        [file join $::tke_home use_sync]

  trace variable [ns preferences]::prefs(General/SyncDirectory) w [list sync::sync_changed]
  trace variable [ns preferences]::prefs(General/SyncItems)     w [list sync::sync_changed]

  ######################################################################
  # Called whenever the General/SyncDirectory value changes.
  proc sync_changed {name1 name2 op} {

    variable last_sync_dir
    variable last_sync_items
    variable sync_local
    variable use_sync

    # Get the new sync directory value
    set sync_dir   [[ns preferences]::get General/SyncDirectory]
    set sync_items [[ns preferences]::get General/SyncItems]

    if {$sync_dir ne ""} {
      create_sync_dir $sync_dir
      if {[lsearch $sync_items prefs] != -1} {
        if {[catch { open $use_sync w } rc]} {
          close $rc
        }
      } else {
        file delete -force $use_sync
      }
    } elseif {[file exists $sync_local]} {
      file delete -force [file link $sync_local] $use_sync
    }

    # Save the values
    set last_sync_dir   $sync_dir
    set last_sync_items $sync_items

  }

  ######################################################################
  # Create the sync directory and copy the current items to it and create
  # symlinks, if necessary.
  proc create_sync_dir {sync_dir} {

    variable sync_local

    # Create the synchronization directory
    file mkdir $sync_dir

    # Remove the sync directory if it exists and points at a different sync
    # directory and create the new symlink.
    if {[file exists $sync_local]} {
      if {[file link $sync_local] ne $sync_dir} {
        file delete -force $sync_local
        file link -symbolic $sync_local $sync_dir
      } else {
        return
      }
    } else {
      file link -symbolic $sync_local $sync_dir
    }

    # Copy the relevant files to the sync directory
    foreach {type nspace name} [get_sync_items] {
      foreach item [[ns $nspace]::get_sync_items] {
        if {[file exists $item]} {
          file copy -force [file join $::tke_home $item] $sync_dir
        }
      }
    }

  }

  ######################################################################
  # Returns the list of sync items.
  proc get_sync_items {} {

    return [list \
      prefs    preferences [msgcat::mc "Preferences"] \
      launcher launcher    [msgcat::mc "Launcher"] \
      plugins  plugins     [msgcat::mc "Plugins"] \
      sessions sessions    [msgcat::mc "Sessions"] \
      snippets snippets    [msgcat::mc "Snippets"] \
      themes   themes      [msgcat::mc "Themes"] \
    ]

  }

  ######################################################################
  # Returns the home directory pathname of the specified item type.
  proc get_tke_home {type} {

    variable sync_local
    variable use_sync

    # Determine if the sync directory is valid and connected to
    set sync_exists [expr {[file exists $sync_local] && [file exists [file link $sync_local]]}]

    if {$type eq "prefs"} {
      return [expr {($sync_exists && [file exists $use_sync]) ? $sync_local : $::tke_home}]
    } elseif {[lsearch [[ns preferences]::get General/SyncItems] $type] != -1} {
      return [expr {$sync_exists ? $sync_local : $::tke_home}]
    } else {
      return $::tke_home
    }

  }

}
