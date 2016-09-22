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

    # Save the last directory
    set last_directory $data(SyncDirectory)

    # Save the changes
    set data(SyncDirectory) $sync_dir
    set data(SyncItems)     $sync_items

    if {$sync_dir ne ""} {
      create_sync_dir $data(SyncDirectory) $data(SyncItems)
    } elseif {$last_directory ne ""} {
      file_transfer $last_directory $::tke_home $data(SyncItems)
    }

    # Write the file contents
    write_file

    # Indicate that the sync directories have changed
    sync_changed

  }

  ######################################################################
  # Update all namespaces with the updated sync information.
  proc sync_changed {} {

    variable data

    # Indicate the new directory to all sync items
    foreach {type nspace name} [get_sync_items] {
      [ns $nspace]::sync_changed [expr {([lsearch $data(SyncItems) $type] != -1) ? $data(SyncDirectory) : $::tke_home}]
    }

  }

  ######################################################################
  # Create the sync directory and copy the current items to it and create
  # symlinks, if necessary.
  proc create_sync_dir {sync_dir sync_items} {

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

  }

  ######################################################################
  # Performs a file transfer, removing any items that are in the target
  # directory that will be moved.  This is used when importing/exporting
  # settings data (use the create_sync_dir) method to perform a file sync.
  proc file_transfer {from_dir to_dir sync_items} {

    # Get the list of files/directories to transfer based on the items
    foreach {type nspace name} [get_sync_items] {
      if {[lsearch $sync_items $type] != -1} {
        foreach item [[ns $nspace]::get_sync_items] {
          if {[file exists [set fname [file join $from_dir $item]]]} {
            set tname [file join $to_dir $item]
            if {[file exists $tname] && [file isdirectory $tname]} {
              file delete -force $tname
            }
            file copy -force $fname $to_dir
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
  # Displays the import/export window (based on the type argument)
  proc import_export {win_type} {

    variable widgets
    variable data
    variable items

    array set labels [list \
      import [msgcat::mc "Import"] \
      export [msgcat::mc "Export"] \
    ]

    toplevel     .syncwin
    wm title     .syncwin [format "%s %s" $labels($win_type) [msgcat::mc "Settings Data"]]
    wm resizable .syncwin 0 0
    wm transient .syncwin .

    ttk::frame  .syncwin.f
    ttk::label  .syncwin.f.l -text [format "%s: " [msgcat::mc "Directory"]]
    set widgets(directory) [ttk::entry .syncwin.f.e -state readonly]
    ttk::button .syncwin.f.b -style BButton -text [format "%s..." [msgcat::mc "Browse"]] -command [list sync::browse_directory $win_type]

    pack .syncwin.f.l -side left  -padx 2 -pady 2
    pack .syncwin.f.e -side left  -padx 2 -pady 2 -fill x -expand yes
    pack .syncwin.f.b -side right -padx 2 -pady 2

    ttk::labelframe .syncwin.lf -text [format "%s %s" [msgcat::mc "Settings to"] $labels($win_type)]
    set i       0
    set columns 3
    foreach {type nspace name} [get_sync_items] {
      grid [ttk::checkbutton .syncwin.lf.$type -text $name -variable sync::items($type) -command [list sync::handle_do_state]] -row [expr $i % $columns] -column [expr $i / $columns] -sticky news -padx 2 -pady 2
      incr i
    }

    ttk::frame  .syncwin.bf
    set widgets(do) [ttk::button .syncwin.bf.do -style BButton -text $labels($win_type) -width 6 -command [list sync::do_import_export $win_type]]
    ttk::button .syncwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command [list sync::do_cancel]

    pack .syncwin.bf.cancel -side right -padx 2 -pady 2
    pack .syncwin.bf.do     -side right -padx 2 -pady 2

    pack .syncwin.f  -fill x
    pack .syncwin.lf -fill both -expand yes
    pack .syncwin.bf -fill x

    if {$data(SyncDirectory) ne ""} {
      .syncwin.f.e configure -state normal
      .syncwin.f.e insert end $data(SyncDirectory)
      .syncwin.f.e configure -state readonly
    }

    if {$win_type eq "import"} {
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
  proc browse_directory {win_type} {

    variable data
    variable widgets

    # Create additional choose directory options
    set opts [list]
    if {$win_type eq "import"} {
      lappend opts -mustexist 1
    }

    # Get the directory from the user
    if {[set dir [tk_chooseDirectory -parent .syncwin -initialdir $data(SyncDirectory) {*}$opts]] ne ""} {

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
  proc do_import_export {win_type} {

    variable widgets
    variable items

    # Copy the relevant files to transfer
    set item_list [list]
    foreach {type nspace name} [get_sync_items] {
      if {$items($type)} {
        lappend item_list $type
      }
    }

    # Get the sync directory
    set sync_dir [$widgets(directory) get]

    # Figure out the from and to directories based on type
    if {$win_type eq "import"} {
      set from_dir $sync_dir
      set to_dir   $::tke_home
    } else {
      set from_dir $::tke_home
      set to_dir   $sync_dir
    }

    # Perform the file transfer
    file_transfer $from_dir $to_dir $item_list

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

    if {[file exists [file join $::tke_home sync.tkedat]]} {
      load_file
    } else {
      import_sync_wizard
    }

  }

  ######################################################################
  # Displays the import/sync wizard which will be displayed if TKE is
  # started and a sync.tkedat file is not found in the user's home directory.
  proc import_sync_wizard {} {

    variable items

    toplevel     .swizwin
    wm title     .swizwin [format "TKE %s / %s %s" [msgcat::mc "Import"] [msgcat::mc "Sync"] [msgcat::mc "Settings"]]
    wm resizable .swizwin 0 0
    wm protocol  .swizwin WM_DELETE_WINDOW {
      # Do nothing
    }

    ttk::frame      .swizwin.f
    ttk::labelframe .swizwin.f.lf -text [msgcat::mc "Settings to Import/Sync"]
    set i 0
    foreach {type nspace name} [get_sync_items] {
      set items($type) 1
      grid [ttk::checkbutton .swizwin.f.lf.$type -text $name -variable sync::items($type)] -row $i -column 0 -sticky news -padx 2 -pady 2
      incr i
    }

    pack .swizwin.f.lf -fill both -expand yes -padx 2 -pady 2

    ttk::frame  .swizwin.bf
    ttk::button .swizwin.bf.import -text [msgcat::mc "Import"] -command [list sync::wizard_do import]
    ttk::button .swizwin.bf.sync   -text [msgcat::mc "Sync"]   -command [list sync::wizard_do sync]
    ttk::button .swizwin.bf.skip   -text [msgcat::mc "Skip"]   -command [list sync::wizard_do skip]

    pack .swizwin.bf.skip   -side right -padx 2 -pady 2
    pack .swizwin.bf.sync   -side right -padx 2 -pady 2
    pack .swizwin.bf.import -side right -padx 2 -pady 2

    pack .swizwin.f  -fill both -expand yes
    pack .swizwin.bf -fill x

    # Get the user focus and grab
    ::tk::SetFocusGrab .swizwin .swizwin.bf.sync

    update

    set screenwidth  [winfo screenwidth  .swizwin]
    set screenheight [winfo screenheight .swizwin]
    set width        [winfo width        .swizwin]
    set height       [winfo height       .swizwin]

    # Place the window in the middle of the screen
    wm geometry .swizwin +[expr ($screenwidth / 2) - ($width / 2)]+[expr ($screenheight / 2) - ($width / 2)]

    # Wait for the window to be closed
    tkwait window .swizwin

    # Restore the user focus and grab
    ::tk::RestoreFocusGrab .swizwin .swizwin.bf.sync

  }

  ######################################################################
  # Performs wizard action of the specified type.
  proc wizard_do {type} {

    variable data
    variable items

    # Destroy the wizard window
    destroy .swizwin

    if {($type eq "import") || ($type eq "sync")} {

      array get labels [list import [msgcat::mc "Import"] sync [msgcat::mc "Sync"]]

      set opts [list]
      if {$type eq "import"} {
        set title [msgcat::mc "Select TKE settings directory to import"]
        lappend opts -mustexist 1
      } else {
        set title [msgcat::mc "Select TKE settings directory for sync"]
      }

      # Get the directory to import/sync
      if {[set dir [tk_chooseDirectory -parent . -title $title {*}$opts]] ne ""} {
        set data(SyncDirectory) [expr {($type eq "import") ? "" : $dir}]
        set data(SyncItems)     [list]
        foreach {type nspace name} [get_sync_items] {
          if {$items($type)} {
            lappend data(SyncItems) $type
          }
        }
      }

      if {$type eq "import"} {
        file_transfer $dir $::tke_home $data(SyncItems)
      } else {
        create_sync_dir $data(SyncDirectory) $data(SyncItems)
      }

    } else {

      set data(SyncDirectory) ""
      set data(SyncItems)     [list]

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
  # Sets up the sync settings.
  proc sync_setup {} {

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
