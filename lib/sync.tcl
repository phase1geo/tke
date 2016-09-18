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

  array set data    {}
  array set widgets {}
  array set items   {}

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
    # [ns menus]::restart_command

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

    # Copy the relevant files from the sync directory
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

  ######################################################################
  # Displays the import/export window (based on the type argument)
  proc import_export {type} {

    variable widgets
    variable data
    variable items

    array set labels [list \
      import [msgcat::mc "Import"] \
      export [msgcat::mc "Export"] \
    ]

    toplevel     .syncwin
    wm title     .syncwin [format "%s %s" $labels($type) [msgcat::mc "Settings Data"]]
    wm resizable .syncwin 0 0
    wm transient .syncwin .

    ttk::frame  .syncwin.f
    ttk::label  .syncwin.f.l -text [format "%s: " [msgcat::mc "Directory"]]
    set widgets(directory) [ttk::entry .syncwin.f.e -state readonly]
    ttk::button .syncwin.f.b -style BButton -text [format "%s..." [msgcat::mc "Browse"]] -command [list sync::browse_directory]

    pack .syncwin.f.l -side left  -padx 2 -pady 2
    pack .syncwin.f.e -side left  -padx 2 -pady 2 -fill x -expand yes
    pack .syncwin.f.b -side right -padx 2 -pady 2

    ttk::labelframe .syncwin.lf -text [format "%s %s" [msgcat::mc "Items to"] $labels($type)]
    foreach {type nspace name} [get_sync_items] {
      pack [ttk::checkbutton .syncwin.lf.$item -text $name -variable sync::items($type) -command [list sync::handle_do_state]
    }

    ttk::frame  .syncwin.bf
    set widgets(do) [ttk::button .syncwin.bf.do -text $labels($type) -width 6 -command [list sync::do_import_export $type]]
    ttk::button .syncwin.bf.cancel -text [msgcat::mc "Cancel"] -width 6 -command [list sync::do_cancel]

    pack .syncwin.bf.cancel -side right -padx 2 -pady 2
    pack .syncwin.bf.do     -side right -padx 2 -pady 2

    pack .syncwin.f  -fill x
    pack .syncwin.lf -fill both -expand yes
    pack .syncwin.bf -fill x

    # Initialize the UI
    load_file

    if {$data(SyncDirectory) ne ""} {
      .syncwin.f.e configure -state normal
      .syncwin.f.e insert end $data(SyncDirectory)
      .syncwin.f.e configure -state readonly
    }

    if {$type eq "import"} {
      foreach {type nspace name} [get_sync_items] {
        set items($type) [expr {[lsearch $data(SyncItems) $type] != -1}]
      }
    } else {
      foreach {type nspace name} [get_sync_items] {
        set items($type) 1
      }
    }

    # Handle the state of the do button
    handle_do_state

    # Grab the focus
    ::tk::SetFocusGrab .syncwin .syncwin.f.b

    # Wait for the window to close
    tkwait window .syncwin

    # Restore the grab and focus
    ::tk::RestoreFocusGrab .syncwin .syncwin.f.b

  }

  ######################################################################
  # Allows the user to use the file browser to select a directory to
  # import/export to.
  proc browse_directory {} {

    variable data
    variable widgets

    # Get the directory from the user
    if {[set dir [tk_chooseDirectory -parent .syncwin -initialdir $data(SyncDirectory)]] ne ""} {
      $widgets(directory) configure -state normal
      $widgets(directory) delete 0 end
      $widgets(directory) insert end $dir
      $widgets(directory) configure -state readonly
    }

  }

  ######################################################################
  # Handles the state of the import/export button in the import/export
  # window.
  proc handle_do_state {} {

    variable widgets
    variable items

    # Disable the button by default
    $widgets(do) configure -state disabled

    if {[$widgets(directory) get] ne ""} {
      foreach {type nspace name} [get_sync_items] {
        if {$items($type)} {
          $widgets(do) configure -state normal
          return
        }
      }
    }

  }

  ######################################################################
  # Perform the import/export operation.
  proc do_import_export {type} {

    variable widgets
    variable items

    # Copy the relevant files to transfer
    set item_list [list]
    foreach {type nspace name} [get_sync_items] {
      if {$items($type)} {
        lappend item_list {*}[[ns $nspace]::get_sync_items]
      }
    }

    # Get the sync directory
    set sync_dir [$widgets(directory) get]

    # Figure out the from and to directories based on type
    if {$type eq "import"} {
      set from_dir $sync_dir
      set to_dir   $::tke_home
    } else {
      set from_dir $::tke_home
      set to_dir   $sync_dir
    }

    # Perform the file transfer
    foreach item $item_list {
      if {[file exists [set fname [file join $from_dir $item]]} {
        set tname [file join $to_dir $item]
        if {[file exists $tname] && [file isdirectory $tname]} {
          file delete -force $tname
        }
        file copy -force $fname $to_dir
      }
    }

    # Close the sync window
    destroy .syncwin

  }

  ######################################################################
  # Cancels the sync window.
  proc do_cancel {} {

    # Close the sync window
    destroy .syncwin

  }

  ######################################################################
  # Load the synchronization file.
  proc load_file {} {

    variable data

    # Initialize the sync information
    set data(SyncDirectory) ""
    set data(SyncItems)     [list emmet launcher plugins prefs sessions snippets templates themes]

    # Read in the sync data from the file
    if {![catch { [ns tkedat]::read [file join $::tke_home sync.tkedat] } rc]} {
      array set data $rc
    }

  }

  ######################################################################
  # Writes the synchronization file.
  proc write_file {} {

    variable data

    [ns tkedat]::write [file join $::tke_home sync.tkedat] [array get data]

  }

}
