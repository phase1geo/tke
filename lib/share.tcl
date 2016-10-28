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
# Name:    share.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    9/14/2016
# Brief:   Namespace that handles settings sharing.
######################################################################

namespace eval share {

  source [file join $::tke_dir lib ns.tcl]

  variable last_directory ""
  variable last_items     [list]

  array set data    {}
  array set widgets {}
  array set items   {}

  ######################################################################
  # Returns the list of sharing items.  The following is a description
  # of each item.
  #   - Referred nickname
  #   - Namespace
  #   - Displayed name in GUI
  proc get_share_items {} {

    return [list \
      emmet     emmet       [msgcat::mc "Emmet"] \
      favorites favorites   [msgcat::mc "Favorites"] \
      launcher  launcher    [msgcat::mc "Launcher"] \
      plugins   plugins     [msgcat::mc "Plugins"] \
      prefs     preferences [msgcat::mc "Preferences"] \
      remote    remote      [msgcat::mc "Remote Connections"] \
      sessions  sessions    [msgcat::mc "Sessions"] \
      snippets  snippets    [msgcat::mc "Snippets"] \
      templates templates   [msgcat::mc "Templates"] \
      themes    themes      [msgcat::mc "Themes"] \
    ]

  }

  ######################################################################
  # Called by the whenever sharing items are changed.
  proc save_changes {share_dir share_items} {

    variable data
    variable last_directory
    variable last_items

    # Save the last directory
    set last_directory $data(ShareDirectory)
    set last_items     $data(ShareItems)

    # Save the changes
    set data(ShareDirectory) $share_dir
    set data(ShareItems)     $share_items

    # Indicate that the share information have changed
    share_changed

    # If the directory changed but was previously pointing at a remote directory,
    # transfer all of the information that was being stored in the remote directory
    # to the home directory
    if {$last_directory ne ""} {
      file_transfer $last_directory $::tke_home $last_items
    }

    # If we are using a remote directory, create the directory and share the files
    # to that directory.
    if {$share_dir ne ""} {
      create_share_dir $data(ShareDirectory) $data(ShareItems)
    }

    # Write the file contents
    write_file

  }

  ######################################################################
  # Update all namespaces with the updated sharing information.
  proc share_changed {} {

    variable data

    # Indicate the new directory to all sharing items
    if {$data(ShareDirectory) ne ""} {
      foreach {type nspace name} [get_share_items] {
        [ns $nspace]::share_changed [expr {([lsearch $data(ShareItems) $type] != -1) ? $data(ShareDirectory) : $::tke_home}]
      }
    } else {
      foreach {type nspace name} [get_share_items] {
        [ns $nspace]::share_changed $::tke_home
      }
    }

  }

  ######################################################################
  # Create the share directory and copy the current items to it and create
  # symlinks, if necessary.
  proc create_share_dir {share_dir share_items} {

    variable last_items

    # Create the sharing directory
    file mkdir $share_dir

    foreach {type nspace name} [get_share_items] {

      # Copy the relevant files to the share directory
      if {[lsearch $share_items $type] != -1} {
        foreach item [[ns $nspace]::get_share_items $::tke_home] {
          set home_item  [file join $::tke_home $item]
          set share_item [file join $share_dir $item]
          if {[file exists $home_item] && ![file exists $share_item]} {
            file copy -force $home_item $share_dir
          }
        }

      # Otherwise, copy relevant items to home directory if we used to get the items from the share directory
      } elseif {([lsearch $share_items $type] == -1) && ([lsearch $last_items $type] != -1)} {
        foreach item [[ns $nspace]::get_share_items $share_dir] {
          set home_item  [file join $::tke_home $item]
          set share_item [file join $share_dir $item]
          if {[file exists $share_item]} {
            if {[file exists $home_item] && [file isdirectory $home_item]} {
              file delete -force $tname
            }
            file copy -force $share_item $::tke_home
          }
        }
      }

    }

  }

  ######################################################################
  # Performs a file transfer, removing any items that are in the target
  # directory that will be moved.  This is used when importing/exporting
  # settings data (use the create_share_dir) method to perform a file share.
  proc file_transfer {from_dir to_dir share_items} {

    variable data

    # Get the list of files/directories to transfer based on the items
    foreach {type nspace name} [get_share_items] {
      set fdir [expr {(($from_dir eq "") || (($from_dir eq $data(ShareDirectory)) && ([lsearch $data(ShareItems) $type] == -1))) ? $::tke_home : $from_dir}]
      set tdir [expr {(($to_dir   eq "") || (($to_dir   eq $data(ShareDirectory)) && ([lsearch $data(ShareItems) $type] == -1))) ? $::tke_home : $to_dir}]
      if {[lsearch $share_items $type] != -1} {
        foreach item [[ns $nspace]::get_share_items $fdir] {
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
  # Returns the sharing information.
  proc get_share_info {} {

    variable data

    # Gather the share items
    set items [list]
    foreach {type nspace name} [get_share_items] {
      lappend items $type [expr [lsearch $data(ShareItems) $type] != -1]
    }

    return [list $data(ShareDirectory) $items]

  }

  ######################################################################
  # Displays the export window
  proc create_export {} {

    variable widgets
    variable data
    variable items

    toplevel     .sharewin
    wm title     .sharewin [msgcat::mc "Export Settings Data"]
    wm resizable .sharewin 0 0
    wm transient .sharewin .

    ttk::frame  .sharewin.f
    ttk::label  .sharewin.f.l -text [format "%s: " [msgcat::mc "Directory"]]
    set widgets(directory) [ttk::entry .sharewin.f.e -width 40 -state readonly]
    ttk::button .sharewin.f.b -style BButton -text [format "%s..." [msgcat::mc "Browse"]] -command [list share::browse_directory]

    pack .sharewin.f.l -side left  -padx 2 -pady 2
    pack .sharewin.f.e -side left  -padx 2 -pady 2 -fill x -expand yes
    pack .sharewin.f.b -side right -padx 2 -pady 2

    ttk::frame      .sharewin.lf
    ttk::labelframe .sharewin.lf.f -text [msgcat::mc "Settings to export"]
    set i       0
    set columns 3
    foreach {type nspace name} [get_share_items] {
      set items($type) 1
      grid [ttk::checkbutton .sharewin.lf.f.$type -text $name -variable share::items($type) -command [list share::handle_do_state]] -row [expr $i % $columns] -column [expr $i / $columns] -sticky news -padx 2 -pady 2
      incr i
    }

    pack .sharewin.lf.f -side left -padx 20 -pady 2

    ttk::frame  .sharewin.bf
    set widgets(do) [ttk::button .sharewin.bf.do -style BButton -text [msgcat::mc "Export"] -width 6 -command [list share::do_export]]
    ttk::button .sharewin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command [list share::do_cancel]

    pack .sharewin.bf.cancel -side right -padx 2 -pady 2
    pack .sharewin.bf.do     -side right -padx 2 -pady 2

    pack .sharewin.f  -fill x
    pack .sharewin.lf -fill both -expand yes
    pack .sharewin.bf -fill x

    # Handle the state of the do button
    handle_do_state

    # Grab the focus
    ::tk::SetFocusGrab .sharewin .sharewin.f.b

    # Center the window
    ::tk::PlaceWindow .sharewin widget .

    # Wait for the window to close
    tkwait window .sharewin

    # Restore the grab and focus
    ::tk::RestoreFocusGrab .sharewin .sharewin.f.b

  }

  ######################################################################
  # Allows the user to use the file browser to select a directory to
  # import/export to.
  proc browse_directory {} {

    variable data
    variable widgets

    # Get the directory from the user
    if {[set dir [tk_chooseDirectory -parent .sharewin -initialdir [pwd]]] ne ""} {

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
      foreach {type nspace name} [get_share_items] {
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
    foreach {type nspace name} [get_share_items] {
      if {$items($type)} {
        lappend item_list $type
      }
    }

    # Get the share directory
    set to_dir [$widgets(directory) get]

    # Perform the file transfer
    if {$data(ShareDirectory) ne $to_dir} {
      file_transfer $data(ShareDirectory) $to_dir $item_list
    }

    # Close the share window
    destroy .sharewin

  }

  ######################################################################
  # Cancels the share window.
  proc do_cancel {} {

    # Close the share window
    destroy .sharewin

  }

  ######################################################################
  # Called on tool startup.  If the share file does not exist in the home
  # directory, call the share wizard to help the user setup a valid share
  # file.
  proc initialize {} {

    variable data

    if {[file exists [file join $::tke_home share.tkedat]]} {
      load_file
    } elseif {[llength [glob -nocomplain -directory $::tke_home *]] > 0} {
      set data(ShareDirectory) ""
      set data(ShareItems)     [list]
      write_file
    } else {
      import_share_wizard
    }

  }

  ######################################################################
  # Displays the import/share wizard which will be displayed if TKE is
  # started and a share.tkedat file is not found in the user's home directory.
  proc import_share_wizard {} {

    variable data
    variable items

    # Show the user startup
    lassign [startup::create] action dirname item_list

    array set items $item_list

    # Setup the share directory
    set data(ShareDirectory) [expr {($action eq "share") ? $dirname : ""}]

    # Setup the share items list
    set data(ShareItems) [list]

    if {$action ne "local"} {
      foreach {type nspace name} [get_share_items] {
        if {$items($type)} {
          lappend data(ShareItems) $type
        }
      }
    }

    # Indicate that the share directory have changed
    share_changed

    # Perform the action
    switch $action {
      copy  { file_transfer $dirname $::tke_home $data(ShareItems) }
      share { create_share_dir $data(ShareDirectory) $data(ShareItems) }
    }

    # Create the share.tkedat file
    write_file

  }

  ######################################################################
  # Load the sharing file.
  proc load_file {} {

    variable data

    # Initialize the share information
    set data(ShareDirectory) ""
    set data(ShareItems)     [list emmet launcher plugins prefs remote sessions snippets templates themes]

    # Read in the share data from the file
    if {![catch { [ns tkedat]::read [file join $::tke_home share.tkedat] } rc]} {
      array set data $rc
    }

    # Update all affected namespaces
    share_changed

  }

  ######################################################################
  # Writes the sharing file.
  proc write_file {} {

    variable data

    [ns tkedat]::write [file join $::tke_home share.tkedat] [array get data] 0

  }

  ######################################################################
  # Sets up the share settings for editing in a buffer.
  proc edit_setup {} {

    variable data

    # Create the buffer
    [ns gui]::add_buffer end [msgcat::mc "Sharing Setup"] [list [ns share]::save_buffer_contents] -lang tkeData

    # Get the newly added buffer
    set txt [[ns gui]::current_txt {}]

    # Get the contents from the base sharing file
    if {![catch { [ns tkedat]::read [file join $::tke_dir data share.tkedat] } rc]} {
      array set contents $rc
    }

    foreach opt [list ShareDirectory ShareItems] {
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
  # Called when the sharing text file is saved.
  proc save_buffer_contents {file_index} {

    # Get the current buffer
    set txt [[ns gui]::current_txt {}]

    # Get the buffer contents
    array set data [[ns tkedat]::parse [[ns gui]::scrub_text $txt] 0]

    # Indicate that values may have changed
    save_changes $data(ShareDirectory) $data(ShareItems)

    return 0

  }

}
