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
  # Called whenever the General/SyncDirectory value changes.
  proc sync_changed {} {

    variable data
    variable sync_local
    variable last_directory

    # Get the new sync directory value
    set sync_dir   $data(SyncDirectory)
    set sync_items $data(SyncItems)

    if {$sync_dir ne ""} {
      create_sync_dir $data(SyncDirectory) $data(SyncItems)
    } else {
      remove_sync_dir $last_directory
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
  # Performs a file transfer, removing any items that are in the target
  # directory that will be moved.  This is used when importing/exporting
  # settings data (use the create_sync_dir) method to perform a file sync.
  proc file_transfer {from_dir to_dir items} {

    # Get the list of files/directories to transfer based on the items
    foreach {type nspace name} [get_sync_items] {
      if {[lsearch $items $type] != -1} {
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
    ttk::button .syncwin.f.b -style BButton -text [format "%s..." [msgcat::mc "Browse"]] -command [list sync::browse_directory]

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

    # Initialize the UI
    load_file

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
  proc browse_directory {} {

    variable data
    variable widgets

    # Get the directory from the user
    if {[set dir [tk_chooseDirectory -parent .syncwin -initialdir $data(SyncDirectory)]] ne ""} {

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

    toplevel            .swizwin
    wm title            .swizwin [format "%s / %s %s" [msgcat::mc "Import"] [msgcat::mc "Sync"] [msgcat::mc "Settings"]]
    wm resizable        .swizwin 0 0
    wm overrideredirect .swizwin 1

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

      # Get the directory to import/sync
      set dir [tk_chooseDirectory -parent . -title [format "%s %s" [msgcat::mc "Choose TKE Settings Directory to"] $labels($type)

      if {$dir ne ""} {
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

  }

  ######################################################################
  # Writes the synchronization file.
  proc write_file {} {

    variable data

    [ns tkedat]::write [file join $::tke_home sync.tkedat] [array get data]

  }

  ######################################################################
  # Sets up the sync settings.
  proc sync_setup {} {

    [ns gui]::add_buffer end [msgcat::mc "Sync Setup"] [list [ns sync]::save_buffer_contents] -lang tkeData

  }

  ######################################################################
  # Called when the synchronization text file is saved.
  proc save_buffer_contents {file_index} {

    variable data
    variable last_directory

    # Save the last directory
    set last_directory $data(SyncDirectory)

    # Get the current buffer
    set txt [[ns gui]::current_txt {}]

    # Get the buffer contents
    array set data [[ns tkedat]::parse [[ns gui]::scrub_text $txt] 0]

    # Write the file
    write_file
    # Indicate that values may have changed

    sync_changed

  }

}
