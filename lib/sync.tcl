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

  variable sync_local [file join $::tke_home sync_dir]

  trace variable [ns preferences]::prefs(General/SyncDirectory) w [list sync::sync_changed]
  trace variable [ns preferences]::prefs(General/SyncItems)     w [list sync::sync_changed]

  ######################################################################
  # Called whenever the General/SyncDirectory value changes.
  proc sync_changed {name1 name2 op} {

    variable sync_local

    # Get the new sync directory value
    set sync_dir   [[ns preferences]::get General/SyncDirectory]
    set sync_items [[ns preferences]::get General/SyncItems]

    if {$sync_dir ne ""} {
      create_sync_dir $sync_dir $sync_items
    } else {
      remove_sync_dir $sync_dir
    }

    # We need to restart TKE to have the change take full effect
    # TBD

  }

  ######################################################################
  # Create the sync directory and copy the current items to it and create
  # symlinks, if necessary.
  proc create_sync_dir {sync_dir sync_items} {

    variable sync_local

    # Create the synchronization directory
    file mkdir $sync_dir

    # Copy the relevant files to the sync directory
    foreach {type nspace name} [get_sync_items] {
      foreach item [[ns $nspace]::get_sync_items] {
        set home_item [file join $::tke_home $item]
        set sync_item [file join $sync_dir $item]
        if {[file exists $home_item] && ![file exists $sync_item]]} {
          file copy -force $home_item $sync_dir
        }
      }
    }

    # Remove the sync directory link, if it exists
    file delete -force $sync_local

    # Create the sync_local link if we need to get our preferences from the
    # remote directory
    if {[lsearch $sync_items prefs] != -1} {
      file link -symbolic $sync_local $sync_dir
    }

  }

  ######################################################################
  # Copies the items from the sync directory to the local home directory
  # and removes the symlink to the sync directory (if it exists).
  proc remove_sync_dir {sync_dir} {

    variable sync_local

    # Copy the relevant files to the sync directory
    foreach {type nspace name} [get_sync_items] {
      foreach item [[ns $nspace]::get_sync_items] {
        set sync_item [file join $sync_dir $item]
        if {[file exists $sync_item]} {
          file copy -force $sync_item $::tke_home
        }
      }
    }

    # Remove the sync directory link, if it exists
    file delete -force $sync_local

  }

  ######################################################################
  # Returns the list of sync items.
  proc get_sync_items {} {

    return [list \
      emmet     emmet       [msgcat::mc "Emmet"] \
      favorites favorites   [msgcat::mc "Favorites"] \
      launcher  launcher    [msgcat::mc "Launcher"] \
      plugins   plugins     [msgcat::mc "Plugins"] \
      prefs     preferences [msgcat::mc "Preferences"] \
      sessions  sessions    [msgcat::mc "Sessions"] \
      snippets  snippets    [msgcat::mc "Snippets"] \
      templates templates   [msgcat::mc "Templates"] \
      themes    themes      [msgcat::mc "Themes"] \
    ]

  }

  ######################################################################
  # Returns the home directory pathname of the specified item type.
  proc get_tke_home {type} {

    variable sync_local
    variable use_sync

    # We need to special treat the preferences type special as we might not know the
    # values of sync_dir and sync_items.
    if {$type eq "prefs"} {
      set sync_exists [expr {[file exists $sync_local] && [file exists [file link $sync_local]]}]
      return [expr {$sync_exists ? $sync_local : $::tke_home}]

    # Otherwise, check the state of the type in the sync_items list and look for the
    # remote or local files based on that value.
    } else {
      set sync_dir   [[ns preferences]::get General/SyncDirectory]
      set sync_items [[ns preferences]::get General/SyncItems]
      return [expr {([file exists $sync_dir] && ([lsearch $sync_items $type] != -1)) ? $sync_dir : $::tke_home}]
    }

  }

}
