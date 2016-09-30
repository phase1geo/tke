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

  variable sync_local     [file join $::tke_home sync_dir]
  variable last_directory ""
  variable last_items     [list]

  array set data    {}
  array set widgets {}
  array set items   {}

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
  # Called by the whenever sync items are changed.
  proc save_changes {sync_dir sync_items} {

    variable data
    variable last_directory
    variable last_items

    # Save the last directory
    set last_directory $data(SyncDirectory)
    set last_items     $data(SyncItems)

    # Save the changes
    set data(SyncDirectory) $sync_dir
    set data(SyncItems)     $sync_items

    # Indicate that the sync directories have changed
    sync_changed

    # If the directory changed but was previously pointing at a remote directory,
    # transfer all of the information that was being stored in the remote directory
    # to the home directory
    if {$last_directory ne ""} {
      file_transfer $last_directory $::tke_home $last_items
    }

    # If we are using a remote directory, create the directory and sync the files
    # to that directory.
    if {$sync_dir ne ""} {
      create_sync_dir $data(SyncDirectory) $data(SyncItems)
    }

    # Write the file contents
    write_file

  }

  ######################################################################
  # Update all namespaces with the updated sync information.
  proc sync_changed {} {

    variable data

    # Indicate the new directory to all sync items
    if {$data(SyncDirectory) ne ""} {
      foreach {type nspace name} [get_sync_items] {
        [ns $nspace]::sync_changed [expr {([lsearch $data(SyncItems) $type] != -1) ? $data(SyncDirectory) : $::tke_home}]
      }
    } else {
      foreach {type nspace name} [get_sync_items] {
        [ns $nspace]::sync_changed $::tke_home
      }
    }

  }

  ######################################################################
  # Create the sync directory and copy the current items to it and create
  # symlinks, if necessary.
  proc create_sync_dir {sync_dir sync_items} {

    variable last_items

    # Create the synchronization directory
    file mkdir $sync_dir

    foreach {type nspace name} [get_sync_items] {

      # Copy the relevant files to the sync directory
      if {[lsearch $sync_items $type] != -1} {
        foreach item [[ns $nspace]::get_sync_items $::tke_home] {
          set home_item [file join $::tke_home $item]
          set sync_item [file join $sync_dir $item]
          if {[file exists $home_item] && ![file exists $sync_item]} {
            file copy -force $home_item $sync_dir
          }
        }

      # Otherwise, copy relevant items to home directory if we used to get the items from the sync directory
      } elseif {([lsearch $sync_items $type] == -1) && ([lsearch $last_items $type] != -1)} {
        foreach item [[ns $nspace]::get_sync_items $sync_dir] {
          set home_item [file join $::tke_home $item]
          set sync_item [file join $sync_dir $item]
          if {[file exists $sync_item]} {
            if {[file exists $home_item] && [file isdirectory $home_item]} {
              file delete -force $tname
            }
            file copy -force $sync_item $::tke_home
          }
        }
      }

    }

  }

  ######################################################################
  # Performs a file transfer, removing any items that are in the target
  # directory that will be moved.  This is used when importing/exporting
  # settings data (use the create_sync_dir) method to perform a file sync.
  proc file_transfer {from_dir to_dir sync_items} {

    variable data

    # Get the list of files/directories to transfer based on the items
    foreach {type nspace name} [get_sync_items] {
      set fdir [expr {(($from_dir eq "") || (($from_dir eq $data(SyncDirectory)) && ([lsearch $data(SyncItems) $type] == -1))) ? $::tke_home : $from_dir}]
      set tdir [expr {(($to_dir   eq "") || (($to_dir   eq $data(SyncDirectory)) && ([lsearch $data(SyncItems) $type] == -1))) ? $::tke_home : $to_dir}]
      if {[lsearch $sync_items $type] != -1} {
        foreach item [[ns $nspace]::get_sync_items $fdir] {
          if {[file exists [set fname [file join $fdir $item]]]} {
            set tname [file join $tdir $item]
            if {[file exists $tname] && [file isdirectory $tname]} {
              file delete -force $tname
            }
            file copy -force $fname $tdir
          }
        }
      }
    }

  }

  ######################################################################
  # Returns the sync information.
  proc get_sync_info {} {

    variable data

    # Gather the sync items
    set items [list]
    foreach {type nspace name} [get_sync_items] {
      lappend items $type [expr [lsearch $data(SyncItems) $type] != -1]
    }

    return [list $data(SyncDirectory) $items]

  }

  ######################################################################
  # Displays the export window
  proc create_export {} {

    variable widgets
    variable data
    variable items

    toplevel     .syncwin
    wm title     .syncwin [msgcat::mc "Export Settings Data"]
    wm resizable .syncwin 0 0
    wm transient .syncwin .

    ttk::frame  .syncwin.f
    ttk::label  .syncwin.f.l -text [format "%s: " [msgcat::mc "Directory"]]
    set widgets(directory) [ttk::entry .syncwin.f.e -width 40 -state readonly]
    ttk::button .syncwin.f.b -style BButton -text [format "%s..." [msgcat::mc "Browse"]] -command [list sync::browse_directory]

    pack .syncwin.f.l -side left  -padx 2 -pady 2
    pack .syncwin.f.e -side left  -padx 2 -pady 2 -fill x -expand yes
    pack .syncwin.f.b -side right -padx 2 -pady 2

    ttk::frame      .syncwin.lf
    ttk::labelframe .syncwin.lf.f -text [msgcat::mc "Settings to export"]
    set i       0
    set columns 3
    foreach {type nspace name} [get_sync_items] {
      set items($type) 1
      grid [ttk::checkbutton .syncwin.lf.f.$type -text $name -variable sync::items($type) -command [list sync::handle_do_state]] -row [expr $i % $columns] -column [expr $i / $columns] -sticky news -padx 2 -pady 2
      incr i
    }

    pack .syncwin.lf.f -side left -padx 20 -pady 2

    ttk::frame  .syncwin.bf
    set widgets(do) [ttk::button .syncwin.bf.do -style BButton -text [msgcat::mc "Export"] -width 6 -command [list sync::do_export]]
    ttk::button .syncwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command [list sync::do_cancel]

    pack .syncwin.bf.cancel -side right -padx 2 -pady 2
    pack .syncwin.bf.do     -side right -padx 2 -pady 2

    pack .syncwin.f  -fill x
    pack .syncwin.lf -fill both -expand yes
    pack .syncwin.bf -fill x

    # Handle the state of the do button
    handle_do_state

    # Grab the focus
    ::tk::SetFocusGrab .syncwin .syncwin.f.b

    # Center the window
    ::tk::PlaceWindow .syncwin widget .

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
    if {[set dir [tk_chooseDirectory -parent .syncwin -initialdir [pwd]]] ne ""} {

      # Insert the directory
      $widgets(directory) configure -state normal
      $widgets(directory) delete 0 end
      $widgets(directory) insert end $dir
      $widgets(directory) configure -state readonly

      # Update the do button state
      handle_do_state

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
  proc do_export {} {

    variable widgets
    variable items
    variable data

    # Copy the relevant files to transfer
    set item_list [list]
    foreach {type nspace name} [get_sync_items] {
      if {$items($type)} {
        lappend item_list $type
      }
    }

    # Get the sync directory
    set to_dir [$widgets(directory) get]

    # Perform the file transfer
    if {$data(SyncDirectory) ne $to_dir} {
      file_transfer $data(SyncDirectory) $to_dir $item_list
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
  # Called on tool startup.  If the sync file does not exist in the home
  # directory, call the sync wizard to help the user setup a valid sync
  # file.
  proc initialize {} {

    variable data

    if {[file exists [file join $::tke_home sync.tkedat]]} {
      load_file
    } elseif {[llength [glob -nocomplain -directory $::tke_home *]] > 0} {
      set data(SyncDirectory) ""
      set data(SyncItems)     [list]
      write_file
    } else {
      import_sync_wizard
    }

  }

  ######################################################################
  # Displays the import/sync wizard which will be displayed if TKE is
  # started and a sync.tkedat file is not found in the user's home directory.
  proc import_sync_wizard {} {

    variable data
    variable items

    # Show the user startup
    lassign [startup::create] action dirname item_list

    array set items $item_list

    # Setup the sync directory
    set data(SyncDirectory) [expr {($action eq "share") ? $dirname : ""}]

    # Setup the sync items list
    set data(SyncItems) [list]

    if {$action ne "local"} {
      foreach {type nspace name} [get_sync_items] {
        if {$items($type)} {
          lappend data(SyncItems) $type
        }
      }
    }

    # Indicate that the sync directories have changed
    sync_changed

    # Perform the action
    switch $action {
      copy  { file_transfer $dirname $::tke_home $data(SyncItems) }
      share { create_sync_dir $data(SyncDirectory) $data(SyncItems) }
    }

    # Create the sync.tkedat file
    write_file

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

    # Update all affected namespaces
    sync_changed

  }

  ######################################################################
  # Writes the synchronization file.
  proc write_file {} {

    variable data

    [ns tkedat]::write [file join $::tke_home sync.tkedat] [array get data] 0

  }

  ######################################################################
  # Sets up the sync settings for editing in a buffer.
  proc edit_setup {} {

    variable data

    # Create the buffer
    [ns gui]::add_buffer end [msgcat::mc "Sync Setup"] [list [ns sync]::save_buffer_contents] -lang tkeData

    # Get the newly added buffer
    set txt [[ns gui]::current_txt {}]

    # Get the contents from the base sync file
    if {![catch { [ns tkedat]::read [file join $::tke_dir data sync.tkedat] } rc]} {
      array set contents $rc
    }

    foreach opt [list SyncDirectory SyncItems] {
      set contents($opt) $data($opt)
    }

    # Formulate the file
    set str ""
    foreach key [lsort [array names contents *,comment]] {
      set opt [lindex [split $key ,] 0]
      foreach comment $contents($key) {
        append str "#$comment\n"
      }
      append str "\n{$opt} {$contents($opt)}\n\n"
    }

    # Insert the string
    $txt insert -moddata ignore end $str

  }

  ######################################################################
  # Called when the synchronization text file is saved.
  proc save_buffer_contents {file_index} {

    # Get the current buffer
    set txt [[ns gui]::current_txt {}]

    # Get the buffer contents
    array set data [[ns tkedat]::parse [[ns gui]::scrub_text $txt] 0]

    # Indicate that values may have changed
    save_changes $data(SyncDirectory) $data(SyncItems)

    return 0

  }

}
