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
# Name:    remote.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/10/2016
# Brief:   Namespace that provides FTP/SFTP interface support.
######################################################################

namespace eval remote {

  variable password
  variable contents
  variable initialized    0
  variable current_server ""
  variable current_fname  ""

  array set widgets     {}
  array set groups      {}
  array set connections {}
  array set opened      {}
  array set current_dir {}
  array set dir_hist    {}
  
  set remote_file [file join $::tke_home remote.tkedat]

  ######################################################################
  # Initialize the remote namespace.
  proc initialize {} {

    variable initialized

    if {!$initialized} {

      # Create images
      theme::register_image remote_connecting bitmap ttk_style background \
        {msgcat::mc "Image used in remote file selector to indicate that a connection is being opened."} \
        -file     [file join $::tke_dir lib images connecting.bmp] \
        -maskfile [file join $::tke_dir lib images connecting.bmp] \
        -foreground 1

      theme::register_image remote_connected bitmap ttk_style background \
        {msgcat::mc "Image used in remote file selector to indicate that a connection is opened."} \
        -file     [file join $::tke_dir lib images connected.bmp] \
        -maskfile [file join $::tke_dir lib images connected.bmp] \
        -foreground 1

      theme::register_image remote_directory bitmap ttk_style background \
        {msgcat::mc "Image used in remote file selector to indicate a folder."} \
        -file     [file join $::tke_dir lib images right.bmp] \
        -maskfile [file join $::tke_dir lib images right.bmp] \
        -foreground 2

      theme::register_image remote_file bitmap ttk_style background \
        {msgcat::mc "Image used in remote file selector to indicate a file."} \
        -file     [file join $::tke_dir lib images blank.bmp] \
        -maskfile [file join $::tke_dir lib images blank.bmp] \
        -foreground 2

      set initialized 1

    }

  }

  ######################################################################
  # Creates an remote dialog box and returns the selected file.
  proc create {type {save_as ""}} {

    variable widgets
    variable current_server
    variable current_fname
    variable connections

    # Initialize the namespace
    initialize

    toplevel     .ftp
    wm title     .ftp [expr {($type eq "open") ? [msgcat::mc "Open Remote File"] : [msgcat::mc "Save File Remotely"]}]
    wm transient .ftp .
    wm geometry  .ftp 600x400
    wm withdraw  .ftp

    set widgets(pw) [ttk::panedwindow .ftp.pw -orient horizontal]

    ###########
    # SIDEBAR #
    ###########

    $widgets(pw) add [ttk::frame .ftp.pw.lf]

    ttk::frame .ftp.pw.lf.sf
    set widgets(sb) [tablelist::tablelist .ftp.pw.lf.sf.tl \
      -columns {0 {Connections} 0 {} 0 {}} -treecolumn 0 -exportselection 0 -relief flat \
      -selectmode single -movablerows 1 -labelrelief flat -highlightthickness 0 \
      -labelactivebackground [utils::get_default_background] \
      -labelbackground [utils::get_default_background] \
      -labelforeground [utils::get_default_foreground] \
      -labelactivebackground [utils::get_default_background] \
      -labelactiveforeground [utils::get_default_foreground] \
      -selectbackground [theme::get_value ttk_style active_color] \
      -selectforeground [utils::get_default_foreground] \
      -activestyle none \
      -acceptchildcommand [list remote::accept_child_command] \
      -background [utils::get_default_background] -foreground [utils::get_default_foreground] \
      -yscrollcommand [list utils::set_yscrollbar .ftp.pw.lf.sf.vb]]
    ttk::scrollbar .ftp.pw.lf.sf.vb -orient vertical   -command [list .ftp.pw.lf.sf.tl yview]

    $widgets(sb) columnconfigure 0 -name name     -editable 0 -resizable 1 -stretchable 1
    $widgets(sb) columnconfigure 1 -name settings -hide 1
    $widgets(sb) columnconfigure 2 -name passwd   -hide 1

    bind $widgets(sb)           <<TablelistSelect>>     [list remote::handle_sb_select]
    bind [$widgets(sb) bodytag] <Double-Button-1>       [list remote::handle_sb_double_click]
    bind [$widgets(sb) bodytag] <Button-$::right_click> [list remote::show_sidebar_menu %W %x %y %X %Y]
    bind $widgets(sb)           <<TablelistRowMoved>>   [list remote::handle_row_moved %d]

    grid rowconfigure    .ftp.pw.lf.sf 0 -weight 1
    grid columnconfigure .ftp.pw.lf.sf 0 -weight 1
    grid .ftp.pw.lf.sf.tl -row 0 -column 0 -sticky news
    grid .ftp.pw.lf.sf.vb -row 0 -column 1 -sticky ns

    ttk::frame  .ftp.pw.lf.bf
    set widgets(new_b) [ttk::button .ftp.pw.lf.bf.edit -style BButton -text "\u2795" -width 2 -command [list remote::show_new_menu]]

    pack .ftp.pw.lf.bf.edit -side left -padx 2 -pady 2

    pack .ftp.pw.lf.sf -fill both -expand yes
    pack .ftp.pw.lf.bf -fill x

    # Create contextual menus
    set widgets(new) [menu .ftp.newPopup -tearoff 0]
    $widgets(new) add command -label [msgcat::mc "New Group"]      -command [list remote::new_group]
    $widgets(new) add command -label [msgcat::mc "New Connection"] -command [list remote::new_connection]

    set widgets(group) [menu .ftp.groupPopup -tearoff 0 -postcommand [list remote::group_post]]
    $widgets(group) add command -label [msgcat::mc "New Connection"] -command [list remote::new_connection]
    $widgets(group) add separator
    $widgets(group) add command -label [msgcat::mc "Rename Group"]   -command [list remote::rename_group]
    $widgets(group) add command -label [msgcat::mc "Delete Group"]   -command [list remote::delete_group]

    set widgets(connection) [menu .ftp.connPopup -tearoff 0 -postcommand [list remote::connection_post]]
    $widgets(connection) add command -label [msgcat::mc "Open Connection"]   -command [list remote::open_connection]
    $widgets(connection) add command -label [msgcat::mc "Close Connection"]  -command [list remote::close_connection]
    $widgets(connection) add separator
    $widgets(connection) add command -label [msgcat::mc "Edit Connection"]   -command [list remote::edit_connection]
    $widgets(connection) add command -label [msgcat::mc "Test Connection"]   -command [list remote::test_connection]
    $widgets(connection) add separator
    $widgets(connection) add command -label [msgcat::mc "Delete Connection"] -command [list remote::delete_connection]

    ##########
    # VIEWER #
    ##########

    $widgets(pw) add [ttk::frame .ftp.pw.rf] -weight 1

    set widgets(viewer) [ttk::frame .ftp.pw.rf.vf]

    ttk::frame .ftp.pw.rf.vf.ff

    ttk::frame .ftp.pw.rf.vf.ff.mf
    set widgets(dir_back)    [ttk::button     .ftp.pw.rf.vf.ff.mf.back    -style BButton -text "\u276e" -command [list remote::handle_dir -1] -state disabled]
    set widgets(dir_forward) [ttk::button     .ftp.pw.rf.vf.ff.mf.forward -style BButton -text "\u276f" -command [list remote::handle_dir  1] -state disabled]
    set widgets(dir_mb)      [ttk::menubutton .ftp.pw.rf.vf.ff.mf.mb \
      -menu [set widgets(dir_menu) [menu .ftp.dirPopup -tearoff 0 -postcommand [list remote::handle_dir_mb_post]]] \
      -state disabled]

    pack $widgets(dir_back)    -side left -padx 2 -pady 2
    pack $widgets(dir_forward) -side left -padx 2 -pady 2
    pack $widgets(dir_mb)      -side left -padx 2 -pady 2 -fill x -expand yes

    set widgets(tl) [tablelist::tablelist .ftp.pw.rf.vf.ff.tl \
      -columns {0 {File System} 0 {}} -exportselection 0 \
      -selectmode [expr {($type eq "save") ? "browse" : "extended"}] \
      -xscrollcommand [list utils::set_xscrollbar .ftp.pw.rf.vf.ff.hb] \
      -yscrollcommand [list utils::set_yscrollbar .ftp.pw.rf.vf.ff.vb]]
    ttk::scrollbar .ftp.pw.rf.vf.ff.vb -orient vertical   -command [list .ftp.pw.rf.vf.ff.tl yview]
    ttk::scrollbar .ftp.pw.rf.vf.ff.hb -orient horizontal -command [list .ftp.pw.rf.vf.ff.tl xview]

    $widgets(tl) columnconfigure 0 -name fname -resizable 1 -stretchable 1 -editable 0 -formatcommand [list remote::format_name]
    $widgets(tl) columnconfigure 1 -name dir   -hide 1

    bind $widgets(tl)           <<TablelistSelect>> [list remote::handle_tl_select]
    bind [$widgets(tl) bodytag] <Double-Button-1>   [list remote::handle_tl_double_click]

    grid rowconfigure    .ftp.pw.rf.vf.ff 1 -weight 1
    grid columnconfigure .ftp.pw.rf.vf.ff 0 -weight 1
    grid .ftp.pw.rf.vf.ff.mf -row 0 -column 0 -sticky ew -columnspan 2
    grid .ftp.pw.rf.vf.ff.tl -row 1 -column 0 -sticky news
    grid .ftp.pw.rf.vf.ff.vb -row 1 -column 1 -sticky ns
    grid .ftp.pw.rf.vf.ff.hb -row 2 -column 0 -sticky ew

    ttk::frame .ftp.pw.rf.vf.sf
    ttk::label .ftp.pw.rf.vf.sf.l -text [format "%s: " [msgcat::mc "Name"]]
    set widgets(save_entry) [ttk::entry .ftp.pw.rf.vf.sf.e -validate key -validatecommand [list remote::handle_save_entry %P]]

    pack .ftp.pw.rf.vf.sf.l -side left -padx 2 -pady 2
    pack .ftp.pw.rf.vf.sf.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame  .ftp.pw.rf.vf.bf
    set widgets(folder) [ttk::button .ftp.pw.rf.vf.bf.folder -style BButton -text [msgcat::mc "New Folder"] \
      -command [list remote::handle_new_folder] -state disabled]
    set widgets(open) [ttk::button .ftp.pw.rf.vf.bf.ok -style BButton -text [msgcat::mc "Open"] \
      -width 6 -command [list remote::handle_open] -state disabled]
    ttk::button .ftp.pw.rf.vf.bf.cancel -style BButton -text [msgcat::mc "Cancel"] \
      -width 6 -command [list remote::handle_cancel]

    pack .ftp.pw.rf.vf.bf.cancel -side right -padx 2 -pady 2
    pack .ftp.pw.rf.vf.bf.ok     -side right -padx 2 -pady 2

    if {$type ne "open"} {
      pack .ftp.pw.rf.vf.bf.folder -side left -padx 2 -pady 2
      $widgets(open) configure -text [msgcat::mc "Save"]
    }

    pack .ftp.pw.rf.vf.ff -fill both -expand yes
    if {$type ne "open"} {
      pack .ftp.pw.rf.vf.sf -fill x
      $widgets(save_entry) insert end $save_as
      $widgets(save_entry) selection range 0 end
    }
    pack .ftp.pw.rf.vf.bf -fill x

    pack .ftp.pw.rf.vf -fill both -expand yes

    #####################
    # CONNECTION EDITOR #
    #####################

    set widgets(editor) [ttk::frame .ftp.ef]

    ttk::frame .ftp.ef.sf
    ttk::label .ftp.ef.sf.l0  -text [format "%s: " [msgcat::mc "Type"]]
    set widgets(edit_type)   [ttk::menubutton .ftp.ef.sf.mb0 -text "FTP" -menu [menu .ftp.typePopup -tearoff 0]]
    ttk::label .ftp.ef.sf.l1  -text [format "%s: " [msgcat::mc "Group"]]
    set widgets(edit_group)  [ttk::menubutton .ftp.ef.sf.mb1 -text ""    -menu [menu .ftp.egroupPopup -tearoff 0 -postcommand [list remote::populate_group_menu]]]
    ttk::label .ftp.ef.sf.l2  -text [format "%s: " [msgcat::mc "Name"]]
    set widgets(edit_name)   [ttk::entry .ftp.ef.sf.ne  -validate key -validatecommand [list remote::check_name %P]]
    ttk::label .ftp.ef.sf.l3  -text [format "%s: " [msgcat::mc "Server"]]
    set widgets(edit_server) [ttk::entry .ftp.ef.sf.se  -validate key -validatecommand [list remote::check_server %P]]
    ttk::label .ftp.ef.sf.l4  -text [format "%s: " [msgcat::mc "Username"]]
    set widgets(edit_user)   [ttk::entry .ftp.ef.sf.ue  -validate key -validatecommand [list remote::check_username %P]]
    ttk::label .ftp.ef.sf.l5  -text [format "%s (%s): " [msgcat::mc "Password"] [msgcat::mc "Optional"]]
    set widgets(edit_passwd) [ttk::entry .ftp.ef.sf.pe  -show *]
    ttk::label .ftp.ef.sf.l6  -text [format "%s: " [msgcat::mc "Port"]]
    set widgets(edit_port)   [ttk::entry .ftp.ef.sf.poe -validate key -validatecommand [list remote::check_port %P] -invalidcommand bell]
    ttk::label .ftp.ef.sf.l7  -text [format "%s (%s): " [msgcat::mc "Remote Directory"] [msgcat::mc "Optional"]]
    set widgets(edit_dir)    [ttk::entry .ftp.ef.sf.re -validate key -validatecommand [list remote::check_dir]]

    bind $widgets(edit_name)   <Return> [list .ftp.ef.bf.create invoke]
    bind $widgets(edit_server) <Return> [list .ftp.ef.bf.create invoke]
    bind $widgets(edit_user)   <Return> [list .ftp.ef.bf.create invoke]
    bind $widgets(edit_passwd) <Return> [list .ftp.ef.bf.create invoke]
    bind $widgets(edit_port)   <Return> [list .ftp.ef.bf.create invoke]
    bind $widgets(edit_dir)    <Return> [list .ftp.ef.bf.create invoke]

    grid rowconfigure    .ftp.ef.sf 8 -weight 1
    grid columnconfigure .ftp.ef.sf 1 -weight 1
    grid .ftp.ef.sf.l0  -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.mb0 -row 0 -column 1 -sticky w    -padx 2 -pady 2
    grid .ftp.ef.sf.l1  -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.mb1 -row 1 -column 1 -sticky w    -padx 2 -pady 2
    grid .ftp.ef.sf.l2  -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.ne  -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.l3  -row 3 -column 0 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.se  -row 3 -column 1 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.l4  -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.ue  -row 4 -column 1 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.l5  -row 5 -column 0 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.pe  -row 5 -column 1 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.l6  -row 6 -column 0 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.poe -row 6 -column 1 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.l7  -row 7 -column 0 -sticky news -padx 2 -pady 2
    grid .ftp.ef.sf.re  -row 7 -column 1 -sticky news -padx 2 -pady 2

    ttk::frame .ftp.ef.bf
    set widgets(edit_test)   [ttk::button .ftp.ef.bf.test -style BButton -text [msgcat::mc "Test"] \
      -width 6 -command [list remote::test_connection] -state disabled]
    set widgets(edit_msg)    [ttk::label  .ftp.ef.bf.msg]
    set widgets(edit_create) [ttk::button .ftp.ef.bf.create -style BButton -text [msgcat::mc "Create"] \
      -width 6 -command [list remote::update_connection] -state disabled]
    ttk::button .ftp.ef.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command {
      pack forget .ftp.ef
      pack .ftp.pw -fill both -expand yes
    }

    pack .ftp.ef.bf.test   -side left  -padx 2 -pady 2
    pack .ftp.ef.bf.msg    -side left  -padx 2 -pady 2
    pack .ftp.ef.bf.cancel -side right -padx 2 -pady 2
    pack .ftp.ef.bf.create -side right -padx 2 -pady 2

    pack .ftp.ef.sf -fill both -expand yes
    pack .ftp.ef.bf -fill x

    # Pack the main panedwindow
    pack .ftp.pw -fill both -expand yes

    # Update the UI
    update

    # Populate sidebar
    populate_sidebar

    # Set the current directory (if one exists)
    if {$current_server ne ""} {
      set_current_directory [lindex $connections($current_server) 1 5] 1
    }

    # Populate the type menubutton
    .ftp.typePopup add command -label "FTP"  -command {
      $remote::widgets(edit_type) configure -text "FTP"
      $remote::widgets(edit_port) delete 0 end
      $remote::widgets(edit_port) insert end 21
    }
    if {[info procs ::sFTPopen] ne ""} {
      .ftp.typePopup add command -label "SFTP" -command {
        $remote::widgets(edit_type) configure -text "SFTP"
        $remote::widgets(edit_port) delete 0 end
        $remote::widgets(edit_port) insert end 22
      }
    }

    # Center the window
    ::tk::PlaceWindow .ftp widget .

    # Display the window
    wm deiconify .ftp

    # Get the focus
    ::tk::SetFocusGrab .ftp $widgets(sb)

    # Wait for the window to close
    tkwait window .ftp

    # Restore the focus
    ::tk::RestoreFocusGrab .ftp $widgets(sb)

    return [list $current_server $current_fname]

  }

  ######################################################################
  # Formats the file/directory name in the table.
  proc format_name {value} {

    return [file tail $value]

  }

  ######################################################################
  # Returns true if the moved row can be placed as a child of the target_parent.
  proc accept_child_command {tbl target_parent src} {

    if {[$tbl parentkey $src] eq "root"} {
      return [expr {$target_parent eq "root"}]
    } elseif {[$tbl cellcget $src,name -image] eq ""} {
      return [expr {[$tbl parentkey $target_parent] eq "root"}]
    } else {
      return 0
    }

  }

  ######################################################################
  # Handles any sidebar row moves.
  proc handle_row_moved {data} {

    # Just save the current connections
    save_connections

  }

  ######################################################################
  # Handle any changes to the save entry.  Updates the state of the "Save"
  # button.
  proc handle_save_entry {value} {

    variable widgets
    variable current_server

    if {($value eq "") || ($current_server eq "")} {
      $widgets(open) configure -state disabled
    } else {
      $widgets(open) configure -state normal
    }

    return 1

  }

  ######################################################################
  # Handles a post of the group popup menu.
  proc group_post {} {

    variable widgets
    variable opened
    
    # Get the selected group
    set selected [$widgets(sb) curselection]
    
    # Get the group name
    set group [$widgets(sb) cellcget $selected,name -text]
    
    # Figure out if any connections are currently opened in this group
    set contains_opened [expr {[llength [array names opened $group,*]] > 0}]

    # We cannot delete the group if it is the only group or if there is at least one
    # opened connection in the group.
    if {([llength [$widgets(sb) childkeys root]] == 1) || $contains_opened} {
      $widgets(group) entryconfigure [msgcat::mc "Delete Group"] -state disabled
    } else {
      $widgets(group) entryconfigure [msgcat::mc "Delete Group"] -state normal
    }
    
    # We cannot rename the group if it has at least one opened connection
    if {$contains_opened} {
      $widgets(group) entryconfigure [msgcat::mc "Rename Group"] -state disabled
    } else {
      $widgets(group) entryconfigure [msgcat::mc "Rename Group"] -state normal
    }

  }

  ######################################################################
  # Handles the connection menu post and makes sure that the states are
  # correct for each of the menu items.
  proc connection_post {} {

    variable widgets
    variable opened

    # Get the currently selected item
    set selected [$widgets(sb) curselection]

    # Get the group name
    set group_name [$widgets(sb) cellcget [$widgets(sb) parentkey $selected],name -text]

    # Get the connection name
    set conn_name [$widgets(sb) cellcget $selected,name -text]

    # Adjust the state of the menu items
    if {[info exists opened($group_name,$conn_name)]} {
      $widgets(connection) entryconfigure [msgcat::mc "Open Connection"]   -state disabled
      $widgets(connection) entryconfigure [msgcat::mc "Close Connection"]  -state normal
      $widgets(connection) entryconfigure [msgcat::mc "Edit Connection"]   -state disabled
      $widgets(connection) entryconfigure [msgcat::mc "Test Connection"]   -state disabled
      $widgets(connection) entryconfigure [msgcat::mc "Delete Connection"] -state disabled
    } else {
      $widgets(connection) entryconfigure [msgcat::mc "Open Connection"]   -state normal
      $widgets(connection) entryconfigure [msgcat::mc "Close Connection"]  -state disabled
      $widgets(connection) entryconfigure [msgcat::mc "Edit Connection"]   -state normal
      $widgets(connection) entryconfigure [msgcat::mc "Test Connection"]   -state normal
      $widgets(connection) entryconfigure [msgcat::mc "Delete Connection"] -state normal
    }

  }


  ######################################################################
  # Tests the current connection settings and displays the result message
  # in the edit_msg label widget.
  proc test_connection {} {

    variable widgets

    # Get the field values
    set type   [$widgets(edit_type)   cget -text]
    set group  [$widgets(edit_group)  cget -text]
    set name   [$widgets(edit_name)   get]
    set server [$widgets(edit_server) get]
    set user   [$widgets(edit_user)   get]
    set passwd [$widgets(edit_passwd) get]
    set port   [$widgets(edit_port)   get]
    set dir    [$widgets(edit_dir)    get]

    # Clear the message field
    $widgets(edit_msg) configure -text ""
    update idletasks

    # Get a password from the user if it is not set
    if {$passwd eq ""} {
      if {[set passwd [get_password]] eq ""} {
        return
      }
    }

    # Open and initialize the connection
    switch $type {
      "FTP" {
        if {[set connection [::ftp::Open $server $user $passwd -port $port -timeout 60]] == -1} {
          $widgets(edit_msg) configure -text "Failed!"
        } else {
          ::ftp::Close $connection
          $widgets(edit_msg) configure -text "Passed!"
        }
      }
      "SFTP" {
        if {[::sFTPopen test $server $user $passwd $port 60] == -1} {
          $widgets(edit_msg) configure -text "Failed!"
        } else {
          ::sFTPclose test
          $widgets(edit_msg) configure -text "Passed!"
        }
      }
    }

  }

  ######################################################################
  # Adds or updates the given connection.
  proc update_connection {} {

    variable widgets
    variable groups

    # Get the field values
    set type   [$widgets(edit_type)   cget -text]
    set group  [$widgets(edit_group)  cget -text]
    set name   [$widgets(edit_name)   get]
    set server [$widgets(edit_server) get]
    set user   [$widgets(edit_user)   get]
    set passwd [$widgets(edit_passwd) get]
    set port   [$widgets(edit_port)   get]
    set dir    [$widgets(edit_dir)    get]

    # Create the settings list
    set settings [list $type $server $user $passwd $port $dir]

    # Update the sidebar
    if {[$widgets(edit_create) cget -text] eq "Create"} {
      $widgets(sb) insertchild $groups($group) end [list $name $settings $passwd]
    } else {
      set selected      [$widgets(sb) curselection]
      set current_group [$widgets(sb) cellcget [$widgets(sb) parentkey $selected],name -text]
      set current_name  [$widgets(sb) cellcget $selected,name -text]
      if {$group ne $current_group} {
        $widgets(sb) delete $selected
        $widgets(sb) insertchild $groups($group) end [list $name $settings $passwd]
      } else {
        $widgets(sb) rowconfigure $selected -text [list $name $settings $passwd]
      }
    }

    # Write the connection information to file
    save_connections

    # Make the file table visible
    pack forget $widgets(editor)
    pack $widgets(pw) -fill both -expand yes

  }

  ######################################################################
  # Populates the group menu.
  proc populate_group_menu {} {

    variable widgets

    # Remove all items from the group popup menu
    .ftp.egroupPopup delete 0 end

    foreach group_key [$widgets(sb) childkeys root] {
      set group [$widgets(sb) cellcget $group_key,name -text]
      .ftp.egroupPopup add command -label $group -command [list remote::change_group $group]
    }

  }

  ######################################################################
  # Changes the group value of the group widget.
  proc change_group {value} {

    variable widgets

    # Update the group menubutton text
    $widgets(edit_group) configure -text $value

    # If the create button is Update, potentially update the button state
    if {[$widgets(edit_create) cget -text] eq "Update"} {
      if {([$widgets(edit_name) get] ne "") && \
          ([$widgets(edit_server) get] ne "") && \
          ([$widgets(edit_user)   get] ne "") && \
          ([$widgets(edit_passwd) get] ne "") && \
          ([$widgets(edit_port)   get] ne "")} {
        $widgets(edit_create) configure -state normal
        $widgets(edit_test)   configure -state normal
      } else {
        $widgets(edit_create) configure -state disabled
        $widgets(edit_test)   configure -state disabled
      }
    }

    $widgets(edit_msg) configure -text ""

  }

  ######################################################################
  # Checks the connection name and handles the state of the Create button.
  proc check_name {value} {

    variable widgets

    if {($value ne "") && \
        ([$widgets(edit_server) get] ne "") && \
        ([$widgets(edit_user)   get] ne "") && \
        ([$widgets(edit_port)   get] ne "")} {
      $widgets(edit_create) configure -state normal
      $widgets(edit_test)   configure -state normal
    } else {
      $widgets(edit_create) configure -state disabled
      $widgets(edit_test)   configure -state disabled
    }

    $widgets(edit_msg) configure -text ""

    return 1

  }

  ######################################################################
  # Checks the connection server and handles the state of the Create button.
  proc check_server {value} {

    variable widgets

    if {([$widgets(edit_name) get] ne "") && \
        ($value ne "") && \
        ([$widgets(edit_user) get] ne "") && \
        ([$widgets(edit_port) get] ne "")} {
      $widgets(edit_create) configure -state normal
      $widgets(edit_test)   configure -state normal
    } else {
      $widgets(edit_create) configure -state disabled
      $widgets(edit_test)   configure -state disabled
    }

    $widgets(edit_msg) configure -text ""

    return 1

  }

  ######################################################################
  # Checks the connection server and handles the state of the Create button.
  proc check_username {value} {

    variable widgets

    if {([$widgets(edit_name)   get] ne "") && \
        ([$widgets(edit_server) get] ne "") && \
        ($value ne "") && \
        ([$widgets(edit_port)   get] ne "")} {
      $widgets(edit_create) configure -state normal
      $widgets(edit_test)   configure -state normal
    } else {
      $widgets(edit_create) configure -state disabled
      $widgets(edit_test)   configure -state disabled
    }

    $widgets(edit_msg) configure -text ""

    return 1

  }

  ######################################################################
  # Checks the connection port and handles the state of the Create button.
  proc check_port {value} {

    variable widgets

    # If the value is not an integer, complain
    if {($value ne "") && ![string is integer $value]} {
      return 0
    }

    if {([$widgets(edit_name)   get] ne "") && \
        ([$widgets(edit_server) get] ne "") && \
        ([$widgets(edit_user)   get] ne "") && \
        ($value ne "")} {
      $widgets(edit_create) configure -state normal
      $widgets(edit_test)   configure -state normal
    } else {
      $widgets(edit_create) configure -state disabled
      $widgets(edit_test)   configure -state disabled
    }

    $widgets(edit_msg) configure -text ""

    return 1

  }

  ######################################################################
  # Updates the UI state when the user makes a modification to the
  # directory field.
  proc check_dir {} {

    variable widgets

    if {([$widgets(edit_name)   get] ne "") && \
        ([$widgets(edit_server) get] ne "") && \
        ([$widgets(edit_user)   get] ne "") && \
        ([$widgets(edit_port)   get] ne "")} {
      $widgets(edit_create) configure -state normal
      $widgets(edit_test)   configure -state normal
    } else {
      $widgets(edit_create) configure -state disabled
      $widgets(edit_test)   configure -state disabled
    }

    $widgets(edit_msg) configure -text ""

    return 1

  }

  ######################################################################
  # Handles a single select of the sidebar tablelist.
  proc handle_sb_select {} {

    variable widgets
    variable opened

    # Get the selection
    set selected [$widgets(sb) curselection]

    # We don't want to do anything when double-clicking a group
    if {[set parent [$widgets(sb) parentkey $selected]] eq "root"} {
      return
    }

    # Get the group name
    set group [$widgets(sb) cellcget $parent,name -text]

    # Get the remote name
    set name "$group,[$widgets(sb) cellcget $selected,name -text]"

    # If the connection is already opened, immediately display the directory contents
    if {[info exists opened($name)]} {
      # open_connection
    }

  }

  ######################################################################
  # Handles a selection of a connection.
  proc handle_sb_double_click {} {

    variable widgets

    # Get the selection
    set selected [$widgets(sb) curselection]

    # We don't want to do anything when double-clicking a group
    if {[set parent [$widgets(sb) parentkey $selected]] eq "root"} {
      return
    }

    # Open the connection of the selected row
    open_connection

  }

  ######################################################################
  # Shows the sidebar menu
  proc show_sidebar_menu {W x y X Y} {

    variable widgets

    foreach {tbl x y} [tablelist::convEventFields $W $x $y] {}

    set row [$tbl containing $y]
    if {$row == -1} {
      return
    }

    # Set the current selection
    $widgets(sb) selection clear 0 end
    $widgets(sb) selection set $row

    if {[$widgets(sb) parentkey $row] eq "root"} {
      set mnu $widgets(group)
    } else {
      set mnu $widgets(connection)
    }

    tk_popup $mnu $X $Y

  }

  ######################################################################
  # Displays the new menu.
  proc show_new_menu {} {

    variable widgets

    set menu_width  [winfo reqwidth  $widgets(new)]
    set menu_height [winfo reqheight $widgets(new)]
    set w_width     [winfo width $widgets(new_b)]
    set w_x         [winfo rootx $widgets(new_b)]
    set w_y         [winfo rooty $widgets(new_b)]

    set x $w_x
    set y [expr $w_y - ($menu_height + 4)]

    tk_popup $widgets(new) $x $y

  }

  ######################################################################
  # Allows the user to create a new group and inserts it into the sidebar.
  proc new_group {} {

    variable widgets
    variable value
    variable groups

    set value ""

    toplevel     .groupwin
    wm title     .groupwin [msgcat::mc "New Group"]
    wm resizable .groupwin 0 0
    wm transient .groupwin .ftp

    ttk::frame .groupwin.f
    ttk::label .groupwin.f.l -text [msgcat::mc "Group Name: "]
    ttk::entry .groupwin.f.e -validate key -validatecommand [list remote::validate_group %P]

    bind .groupwin.f.e <Return> [list .groupwin.bf.create invoke]

    pack .groupwin.f.l -side left -padx 2 -pady 2
    pack .groupwin.f.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame  .groupwin.bf
    ttk::button .groupwin.bf.create -style BButton -text [msgcat::mc "Create"] -width 6 -command {
      set remote::value [.groupwin.f.e get]
      destroy .groupwin
    } -state disabled
    ttk::button .groupwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command {
      set remote::value ""
      destroy .groupwin
    }

    pack .groupwin.bf.cancel -side right -padx 2 -pady 2
    pack .groupwin.bf.create -side right -padx 2 -pady 2

    pack .groupwin.f  -fill x -expand yes
    pack .groupwin.bf -fill x

    # Place the window in the middle of the FTP window
    update
    ::tk::PlaceWindow .groupwin widget .ftp

    # Get the focus/grab
    ::tk::SetFocusGrab .groupwin .groupwin.f.e

    # Wait for the window to close
    tkwait window .groupwin

    # Restore the focus/grab
    ::tk::RestoreFocusGrab .groupwin .groupwin.f.e

    # Add the group to the sidebar table
    if {$value ne ""} {
      set groups($value) [$widgets(sb) insertchild root end $value]
      $widgets(sb) selection clear 0 end
      $widgets(sb) selection set $groups($value)
    }

  }

  ######################################################################
  # Validates the group name entry value.
  proc validate_group {value} {

    if {$value eq ""} {
      .groupwin.bf.create configure -state disabled
    } else {
      .groupwin.bf.create configure -state normal
    }

    return 1

  }

  ######################################################################
  # Renames the currently selected group.
  proc rename_group {} {

    variable widgets
    variable value

    # Get the currently selected group
    set selected [$widgets(sb) curselection]
    set value    ""

    toplevel     .renwin
    wm title     .renwin [format "%s %s" [msgcat::mc "Rename Group"] [$widgets(sb) cellcget $selected,name -text]]
    wm resizable .renwin 0 0
    wm transient .renwin .ftp

    ttk::frame .renwin.f
    ttk::label .renwin.f.l -text [format "%s: " [msgcat::mc "Group Name"]]
    ttk::entry .renwin.f.e -validate key -validatecommand [list remote::validate_rename_group %P]

    bind .renwin.f.e <Return> [list .renwin.bf.ok invoke]

    pack .renwin.f.l -side left -padx 2 -pady 2
    pack .renwin.f.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame .renwin.bf
    ttk::button .renwin.bf.ok -style BButton -text [msgcat::mc "Rename"] -width 6 -command {
      set remote::value [.renwin.f.e get]
      destroy .renwin
    } -state disabled
    ttk::button .renwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command {
      set remote::value ""
      destroy .renwin
    }

    pack .renwin.bf.cancel -side right -padx 2 -pady 2
    pack .renwin.bf.ok     -side right -padx 2 -pady 2

    pack .renwin.f  -fill x -expand yes
    pack .renwin.bf -fill x

    # Place the window in the middle of the FTP window
    ::tk::PlaceWindow .renwin widget .ftp

    # Get the focus/grab
    ::tk::SetFocusGrab .renwin .renwin.f.e

    # Wait for the window to close
    tkwait window .renwin

    # Restore the focus/grab
    ::tk::RestoreFocusGrab .renwin .renwin.f.e

    # Add the group to the sidebar table
    if {$value ne ""} {
      $widgets(sb) cellconfigure $selected,name -text $value
      save_connections
    }

  }

  ######################################################################
  # Validate the group name in the group rename window.
  proc validate_rename_group {value} {

    variable widgets

    if {$value eq ""} {
      .renwin.bf.ok configure -state disabled
    } else {
      .renwin.bf.ok configure -state normal
    }

    return 1

  }

  ######################################################################
  # Deletes the currently selected group.
  proc delete_group {} {

    variable widgets

    # Verify that the user wants to delete the connection
    if {[tk_messageBox -parent .ftp -icon question -type yesno -default no -message [msgcat::mc "Delete group?"]] eq "no"} {
      return
    }

    # Get the currently selected group
    set selected [$widgets(sb) curselection]

    # Delete the group from the sidebar
    $widgets(sb) delete $selected

    # Save the connection information
    save_connections

  }

  ######################################################################
  # Clears the editor fields.
  proc clear_editor_fields {} {

    variable widgets

    $widgets(edit_type)   configure -text "FTP"
    $widgets(edit_name)   delete 0 end
    $widgets(edit_name)   configure -state normal
    $widgets(edit_server) delete 0 end
    $widgets(edit_user)   delete 0 end
    $widgets(edit_passwd) delete 0 end
    $widgets(edit_port)   delete 0 end
    $widgets(edit_dir)    delete 0 end
    $widgets(edit_msg)    configure -text ""

  }

  ######################################################################
  # Allows the user to create a new connection and inserts it into the sidebar.
  proc new_connection {} {

    variable widgets

    # Get the current selection and group name
    if {[set selected [$widgets(sb) curselection]] eq ""} {
      set group_name [$widgets(sb) cellcget [lindex [$widgets(sb) childkeys root] 0],name -text]
    } elseif {[$widgets(sb) parentkey $selected] eq "root"} {
      set group_name [$widgets(sb) cellcget $selected,name -text]
    } else {
      set group_name [$widgets(sb) cellcget [$widgets(sb) parentkey $selected],name -text]
    }

    # Clear out the editor fields
    clear_editor_fields

    # Setup field names
    $widgets(edit_type)  configure -text "FTP"
    $widgets(edit_group) configure -text $group_name
    $widgets(edit_port)  insert end 21

    # Set the create button text to Create
    $widgets(edit_create) configure -text "Create"

    # Make the editor pane visible
    pack forget $widgets(pw)
    pack $widgets(editor) -fill both -expand yes

  }

  ######################################################################
  # Open connection for the currently selected row in the sidebar.
  proc open_connection {} {

    variable widgets
    variable current_server
    variable images
    variable opened
    variable dir_hist
    variable dir_hist_index

    # Get the selection
    set selected [$widgets(sb) curselection]

    # Get the group name
    set parent [$widgets(sb) parentkey $selected]
    set group  [$widgets(sb) cellcget $parent,name -text]

    # Get the connection name to load
    set current_server "$group,[$widgets(sb) cellcget $selected,name -text]"

    # Get settings
    set settings [$widgets(sb) cellcget $selected,settings -text]

    if {[info exists opened($current_server)]} {

      # Set the current directory
      set_current_directory [lindex $settings 5] 1

      # Indicate that the we are connected
      $widgets(sb) cellconfigure $selected,name -image remote_connected

      # Make sure that the Open/Save button is enabled
      if {([$widgets(open) configure -text] eq [msgcat::mc "Open"]) || \
          ([$widgets(save_entry) get] ne "")} {
        $widgets(open) configure -state normal
      }

      # Enable the New Folder button
      $widgets(folder) configure -state normal

    } else {

      # Set the image to indicate that we are connecting
      $widgets(sb) cellconfigure $selected,name -image remote_connecting

      # Connect to the FTP server and add the directory
      if {[connect $current_server]} {

        # Clear the directory history
        set dir_hist($current_server)       [list]
        set dir_hist_index($current_server) 0

        # Display the current directory
        set_current_directory [lindex $settings 5] 1

        # Indicate that we have successfully connected to the server
        $widgets(sb) cellconfigure $selected,name -image remote_connected

        # Make sure that the Open/Save button is enabled
        if {([$widgets(open) configure -text] eq [msgcat::mc "Open"]) || \
            ([$widgets(save_entry) get] ne "")} {
          $widgets(open) configure -state normal
        }

        # Enable the New Folder button
        $widgets(folder) configure -state normal

      # If we fail to connect, clear the connecting icon
      } else {
        $widgets(sb) cellconfigure $selected,name -image ""
      }

    }

  }

  ######################################################################
  # Closes the currently opened connection
  proc close_connection {} {

    variable widgets
    variable opened
    variable dir_hist
    variable dir_hist_index
    variable current_server

    # Get the currently selected connection
    set selected [$widgets(sb) curselection]

    # Get the group name
    set group_name [$widgets(sb) cellcget [$widgets(sb) parentkey $selected],name -text]

    # Get the connection name
    set conn_name [$widgets(sb) cellcget $selected,name -text]

    # Disconnect, if necessary
    sidebar::disconnect_by_name "$group_name,$conn_name"
    disconnect "$group_name,$conn_name"

    # Clear the icon
    $widgets(sb) cellconfigure $selected,name -image ""

    # Clear the table
    $widgets(tl) delete 0 end

    # Clear the directory history
    catch { unset dir_hist($current_server) }
    catch { unset dir_hist_index($current_server) }

    set current_server ""

    # Make sure that the Open/Save button is disabled
    $widgets(open) configure -state disabled

    # Disable the New Folder button
    $widgets(folder) configure -state disabled

    # Make sure that the directory widgets are disabled
    $widgets(dir_back)    configure -state disabled
    $widgets(dir_forward) configure -state disabled
    $widgets(dir_mb)      configure -text "" -state disabled

  }

  ######################################################################
  # Edits the currently selected connection information.
  proc edit_connection {} {

    variable widgets

    # Get the currently selected connection
    set selected [$widgets(sb) curselection]

    # Get the group name
    set group_name [$widgets(sb) cellcget [$widgets(sb) parentkey $selected],name -text]

    # Get the connection name
    set conn_name [$widgets(sb) cellcget $selected,name -text]

    # Get the settings
    set settings [$widgets(sb) cellcget $selected,settings -text]

    # Clear the editor fields
    clear_editor_fields

    # Insert field values
    $widgets(edit_type)   configure -text [lindex $settings 0]
    $widgets(edit_group)  configure -text $group_name
    $widgets(edit_name)   insert end $conn_name
    $widgets(edit_server) insert end [lindex $settings 1]
    $widgets(edit_user)   insert end [lindex $settings 2]
    $widgets(edit_passwd) insert end [lindex $settings 3]
    $widgets(edit_port)   insert end [lindex $settings 4]
    $widgets(edit_dir)    insert end [lindex $settings 5]

    # Set the create button text to Update
    $widgets(edit_create) configure -text "Update" -state disabled

    # Make the editor pane visible
    pack forget $widgets(pw)
    pack $widgets(editor) -fill both -expand yes

  }

  ######################################################################
  # Deletes the current connection.
  proc delete_connection {} {

    variable widgets

    # Verify that the user wants to delete the connection
    if {[tk_messageBox -parent .ftp -icon question -type yesno -default no -message [msgcat::mc "Delete connection?"]] eq "no"} {
      return
    }

    # Get the currently selected item
    set selected [$widgets(sb) curselection]

    # Delete the connection from the table
    $widgets(sb) delete $selected

    # Save the connections information to file
    save_connections

  }

  ######################################################################
  # Validates the group name entry value.
  proc validate_group {value} {

    if {$value eq ""} {
      .groupwin.bf.create configure -state disabled
    } else {
      .groupwin.bf.create configure -state normal
    }

    return 1

  }

  #####################
  # VIEWER PROCEDURES #
  #####################

  ######################################################################
  # Handles a click on the directory back/forward buttons.
  proc handle_dir {dir} {

    variable widgets
    variable dir_hist
    variable dir_hist_index
    variable current_server

    incr dir_hist_index($current_server) $dir

    if {$dir_hist_index($current_server) == 0} {
      $widgets(dir_back) configure -state disabled
    } else {
      $widgets(dir_back) configure -state normal
    }

    if {[expr ($dir_hist_index($current_server) + 1) == [llength $dir_hist($current_server)]]} {
      $widgets(dir_forward) configure -state disabled
    } else {
      $widgets(dir_forward) configure -state normal
    }

    # Set the current directory
    set_current_directory [lindex $dir_hist($current_server) $dir_hist_index($current_server)] 0

  }

  ######################################################################
  # Handles a post event of the directory popup menu.
  proc handle_dir_mb_post {} {

    variable widgets
    variable current_server
    variable current_dir

    # Get the directory list
    set dir_list [file split $current_dir($current_server)]

    # Clear the menu
    $widgets(dir_menu) delete 0 end

    for {set i 0} {$i < [llength $dir_list]} {incr i} {
      set dir [file join {*}[lrange $dir_list 0 $i]]
      $widgets(dir_menu) add command -label $dir -command [list remote::set_current_directory $dir 1]
    }

  }

  ######################################################################
  # Handles a selection of a file in the file viewer.
  proc handle_tl_select {} {

    variable widgets

    # Get the currently selected row
    set selected [$widgets(tl) curselection]

    # If the selected item is a file
    if {([$widgets(open) cget -text] eq "Open") || \
        ([$widgets(tl) cellcget $selected,dir -text] == 0)} {

      # Populate the save entry field
      $widgets(save_entry) delete 0 end
      $widgets(save_entry) insert end [file tail [$widgets(tl) cellcget $selected,fname -text]]

      if {[$widgets(save_entry) get] ne ""} {
        $widgets(open) configure -state normal
      } else {
        $widgets(open) configure -state disabled
      }

    }

  }

  ######################################################################
  # Handles a double-click in the file browser.
  proc handle_tl_double_click {} {

    variable widgets

    # Get the current selection
    set selected [$widgets(tl) curselection]

    if {[$widgets(tl) cellcget $selected,dir -text] == 0} {

      handle_tl_select
      handle_open

    } else {

      set_current_directory [$widgets(tl) cellcget $selected,fname -text] 1

    }

  }

  ######################################################################
  # Handles a click on the sidebar Edit button.
  proc edit_sidebar {} {

    pref_ui::create "" "" general ftp

  }

  ######################################################################
  # Populates the sidebar with connection information.
  proc populate_sidebar {} {

    variable widgets
    variable groups

    # Clear variables
    array unset groups

    # Read the contents of the FTP file and load them into the sidebar table
    load_connections

    # Select the first item in the table
    $widgets(sb) selection set 0

  }

  ######################################################################
  # Get the connection password from the user.
  proc get_password {} {

    variable password

    set password ""

    toplevel     .ftppass
    wm title     .ftppass [msgcat::mc "Enter Password"]
    wm transient .ftppass .ftp

    ttk::frame .ftppass.f
    ttk::label .ftppass.f.l -text [msgcat::mc "Password: "]
    ttk::entry .ftppass.f.e -validate key -validatecommand [list remote::check_password %P] -textvariable remote::password -show * -width 30

    bind .ftppass.f.e <Return> [list .ftppass.bf.ok invoke]

    pack .ftppass.f.l -side left -padx 2 -pady 2
    pack .ftppass.f.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame  .ftppass.bf
    ttk::button .ftppass.bf.ok     -style BButton -text [msgcat::mc "OK"]     -width 6 -command [list remote::password_ok] -state disabled
    ttk::button .ftppass.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command [list remote::password_cancel]

    pack .ftppass.bf.cancel -side right -padx 2 -pady 2
    pack .ftppass.bf.ok     -side right -padx 2 -pady 2

    pack .ftppass.f  -fill x -expand yes
    pack .ftppass.bf -fill x

    # Center the password window
    ::tk::PlaceWindow .ftppass widget .ftp

    # Get the focus/grab
    ::tk::SetFocusGrab .ftppass .ftppass.f.e

    # Wait for the window to close
    tkwait window .ftppass

    # Restore the focus/grab
    ::tk::RestoreFocusGrab .ftppass .ftppass.f.e

    return $password

  }

  ######################################################################
  # Checks the given password and sets the OK button state accordingly.
  proc check_password {value} {

    if {$value eq ""} {
      .ftppass.bf.ok configure -state disabled
    } else {
      .ftppass.bf.ok configure -state normal
    }

    return 1

  }

  ######################################################################
  # Handles an OK click in the password window.
  proc password_ok {} {

    destroy .ftppass

  }

  ######################################################################
  # Handles a Cancel click in the password window.
  proc password_cancel {} {

    variable password

    set password ""

    destroy .ftppass

  }

  ######################################################################
  # Handles a click on the New Folder button.
  proc handle_new_folder {} {

    variable widgets
    variable value
    variable current_dir
    variable current_server

    toplevel     .foldwin
    wm title     .foldwin [msgcat::mc "Create New Folder"]
    wm resizable .foldwin 0 0
    wm transient .foldwin .ftp

    ttk::frame .foldwin.f
    ttk::label .foldwin.f.l -text [format "%s: " [msgcat::mc "Folder Name"]]
    ttk::entry .foldwin.f.e -validate key -validatecommand [list remote::check_folder_name %P]

    bind .foldwin.f.e <Return> [list .foldwin.bf.ok invoke]

    pack .foldwin.f.l -side left -padx 2 -pady 2
    pack .foldwin.f.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame .foldwin.bf
    ttk::button .foldwin.bf.ok -style BButton -text [msgcat::mc "Create"] -width 6 -command {
      set remote::value [.foldwin.f.e get]
      destroy .foldwin
    } -state disabled
    ttk::button .foldwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command {
      set remote::value ""
      destroy .foldwin
    }

    pack .foldwin.bf.cancel -side right -padx 2 -pady 2
    pack .foldwin.bf.ok     -side right -padx 2 -pady 2

    pack .foldwin.f  -fill x -expand yes
    pack .foldwin.bf -fill x

    # Center the window
    ::tk::PlaceWindow .foldwin widget .ftp

    # Get the grab/focus
    ::tk::SetFocusGrab .foldwin .foldwin.f.e

    # Wait for the window to close
    tkwait window .foldwin

    # Restore the grab/focus
    ::tk::RestoreFocusGrab .foldwin .foldwin.f.e

    # Get the name of the folder to create
    set new_folder [file join $current_dir($current_server) $value]

    # Insert the new directory, if it is successfully made within FTP
    if {[make_directory $current_server $new_folder]} {
      set_current_directory $new_folder 1
    }

  }

  ######################################################################
  # Checks the folder name and updates the UI appropriately.
  proc check_folder_name {value} {

    if {$value eq ""} {
      .foldwin.bf.ok configure -state disabled
    } else {
      .foldwin.bf.ok configure -state normal
    }

    return 1

  }

  ######################################################################
  # Opens the given file.
  proc handle_open {} {

    variable widgets
    variable current_server
    variable current_dir
    variable current_fname

    # Get the currently selected item
    set selected [$widgets(tl) curselection]

    # Get the filename(s)
    if {[$widgets(open) cget -text] eq "Open"} {
      set current_fname [list]
      foreach select $selected {
        lappend current_fname [list [$widgets(tl) cellcget $select,fname -text] [$widgets(tl) cellcget $select,dir -text]]
      }
    } else {
      set current_fname [file join $current_dir($current_server) [$widgets(save_entry) get]]
    }

    # Kill the window
    destroy .ftp

  }

  ######################################################################
  # Cancels the open operation.
  proc handle_cancel {} {

    variable current_fname

    # Indicate that no file was chosen
    set current_fname  ""

    # Close the window
    destroy .ftp

  }

  ######################################################################
  # Adds a new directory to the given table.
  proc set_current_directory {directory update_hist} {

    variable widgets
    variable current_server
    variable current_dir
    variable dir_hist
    variable dir_hist_index

    # If the directory is empty, get the current directory
    if {$directory eq ""} {
      set directory [::FTP_PWD $current_server]
    }

    # Delete the children of the given parent in the table
    $widgets(tl) delete 0 end

    # Add the new directory
    set items [list]
    if {[dir_contents $current_server $directory items]} {
      foreach fname [lsort -index 0 [lsearch -all -inline -index 1 $items 1]] {
        set row [$widgets(tl) insert end $fname]
        $widgets(tl) cellconfigure $row,fname -image remote_directory
      }
      foreach fname [lsort -index 0 [lsearch -all -inline -index 1 $items 0]] {
        set row [$widgets(tl) insert end $fname]
        $widgets(tl) cellconfigure $row,fname -image remote_file
      }
    } else {
      puts "ERROR:  Unable to find dir_contents for dir: $directory ($name)"
    }

    # Sets the current directory to the provided value
    set current_dir($current_server) $directory

    # Update the state/text of the menubutton
    $widgets(dir_mb) configure -text $directory -state normal

    # Update the directory history
    if {$update_hist} {
      catch { set dir_hist($current_server) [lreplace $dir_hist($current_server) [expr $dir_hist_index($current_server) + 1] end] }
      lappend dir_hist($current_server) $directory
      set dir_hist_index($current_server) [expr [llength $dir_hist($current_server)] - 1]
      if {[llength $dir_hist($current_server)] == 1} {
        $widgets(dir_back) configure -state disabled
      } else {
        $widgets(dir_back) configure -state normal
      }
      $widgets(dir_forward) configure -state disabled
    }

  }

  ###########
  # FTP API #
  ###########

  ######################################################################
  # Connects to the given FTP server and loads the contents of the given
  # start directory into the open dialog table.
  #
  # Value of type is either ftp or sftp
  proc connect {name} {

    variable widgets
    variable connections
    variable opened

    if {![info exists connections($name)]} {
      return -code error "Connection does not exist ($name)"
    }

    lassign $connections($name) key type server user passwd port startdir

    # Get a password from the user if it is not set
    if {$passwd eq ""} {
      if {[set passwd [get_password]] eq ""} {
        return 0
      }
      lset connections($name) 3 $passwd
      if {[info exists widgets(sb)] && [winfo exists $widgets(sb)]} {
        $widgets(sb) cellconfigure $key,passwd -text $passwd
      }
    }

    # Open and initialize the connection
    switch $type {
      "FTP" -
      "SFTP" {
        if {[catch { ::FTP_OpenSession $name [expr {($type eq "FTP") ? "" : "s"}] $server:$port $user $passwd $server "" } rc]} {
          tk_messageBox -parent .ftp -type ok -default ok -icon error \
            -message [format "%s $type %s $server" [msgcat::mc "Unable to connect to"] [msgcat::mc "server"]] -detail $rc
          return 0
        } elseif {$startdir ne ""} {
          if {[catch { ::FTP_CD $name $startdir } rc]} {
            tk_messageBox -parent .ftp -type ok -default ok -icon error \
              -message [format "%s $type %s $server" [msgcat::mc "Unable to connect to"] [msgcat::mc "server"]] -detail $rc
            disconnect $name
          } elseif {$rc == 1} {
            set opened($name) 1
            return 1
          } else {
            return 0
          }
        } else {
          set opened($name) 1
          return 1
        }
      }
    }

    return 0

  }

  ######################################################################
  # Disconnects from the given FTP server.
  proc disconnect {name} {

    variable connections
    variable opened

    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        if {[info exists opened($name)]} {
          ::FTP_CloseSession $name
          unset opened($name)
        }
      }
    }

  }

  ######################################################################
  # Called on application exit.  Disconnects all opened connections.
  proc disconnect_all {} {

    variable opened

    foreach name [array names opened] {
      disconnect $name
    }

  }
  
  ######################################################################
  # Returns the matching filename line in the given listing of files within
  # a directory.
  proc find_fname {listing fname} {
    
    set match_expr [string repeat {\S+\s+} 8]
    
    return [lsearch -inline -regexp $listing "^\s*$match_expr$fname\$"]
    
  }

  ######################################################################
  # Returns 1 if the file exists on the server.
  proc file_exists {name fname} {

    variable connections

    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        if {![catch { ::FTP_CD $name [file dirname $fname] } rc]} {
          if {![catch { ::FTP_List $name 0 } rc] rc} {
            return [expr {[find_fname $rc [file tail $fname]] ne ""}]
          } else {
            logger::log $rc
          }
        } else {
          logger::log $rc
        }
      }
    }

    return 0

  }

  ######################################################################
  # Returns the modification time of the given file on the server.
  proc get_mtime {name fname} {

    variable connections

    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        if {![catch { ::FTP_CD $name [file dirname $fname] } rc]} {
          if {![catch { ::FTP_List $name 0 } rc]} {
            if {[set file_out [find_fname $rc [file tail $fname]]] ne ""} {
              return [clock scan [join [lrange $file_out 5 7]]]
            }
          } else {
            logger::log $rc
          }
        } else {
          logger::log $rc
        }
      }
    }

    return 0

  }

  ######################################################################
  # Returns a list of two items such that the first list is a listing
  # of directories in the given directory and the second list is a listing
  # of files in the given directory.
  proc dir_contents {name dirname pitems} {

    variable connections

    upvar $pitems items

    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        if {![catch { ::FTP_CD $name $dirname } rc]} {
          if {![catch { ::FTP_List $name 0 } rc]} {
            foreach item $rc {
              set fname [file join $dirname [lrange $item 8 end]]
              set dir   [expr {[::FTP_IsDir $name $fname] eq $fname}]
              lappend items [list $fname $dir]
            }
            return 1
          } else {
            logger::log $rc
          }
        } else {
          logger::log $rc
        }
      }
    }

    return 0

  }

  ######################################################################
  # Get the file contents of the given filename using the given connection
  # name if the remote file is newer than the given modtime.  Returns 1
  # if the file was retrieved without error; otherwise, returns 0.
  proc get_file {name fname pcontents pmodtime} {

    variable connections

    upvar $pcontents contents
    upvar $pmodtime  modtime

    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        set local   [file join $::tke_home sftp_get.tmp]
        set modtime [get_mtime $name $fname]
        if {![catch { ::FTP_GetFile $name $fname $local 0 } rc]} {
          if {![catch { open $local r } rc]} {
            set contents [read $rc]
            close $rc
            file delete -force $local
            return 1
          } else {
            logger::log $rc
          }
        } else {
          logger::log $rc
        }
      }
    }

    return 0

  }

  ######################################################################
  # Saves the given file contents to the given filename.  Returns 1 if
  # the file was saved successfully; otherwise, returns 0.
  proc save_file {name fname contents pmodtime} {

    variable connections

    upvar $pmodtime modtime

    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        set local [file join $::tke_home sftp_put.tmp]
        if {![catch { open $local w } rc]} {
          puts $rc $contents
          close $rc
          if {![catch { ::FTP_PutFile $name $local $fname [file size $local] } rc]} {
            set modtime [get_mtime $name $fname]
            file delete -force $local
            return 1
          } else {
            logger::log $rc
            file delete -force $local
          }
        } else {
          logger::log $rc
        }
      }
    }

    return 0

  }

  ######################################################################
  # Creates the given directory on the remote end.
  proc make_directory {name dirname} {

    variable connections

    # Make the directory remotely
    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        if {![catch { ::FTP_MkDir $name $dirname } rc]} {
          return 1
        } else {
          logger::log $rc
        }
      }
    }

    return 0

  }

  ######################################################################
  # Removes one or more directories on the server.
  proc remove_directories {name dirnames} {

    variable connections

    # Delete the list of directories
    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        foreach dirname $dirnames {
          if {[catch { ::FTP_RmDir $name $dirname } rc]} {
            logger::log $rc
          }
        }
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Rename the given file name.
  proc rename_file {name curr_fname new_fname} {

    variable connections

    # Change the current directory
    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        if {![catch { ::FTP_Rename $name $curr_fname $new_fname } rc]} {
          return 1
        } else {
          logger::log $rc
        }
      }
    }

    return 0

  }

  ######################################################################
  # Duplicates a given filename.
  proc duplicate_file {name fname new_fname} {

    variable connections
    variable contents

    # Duplicate the file
    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        set local [file join $::tke_home sftp_dup.tmp]
        if {![catch { ::FTP_GetFile $name $fname $local 0 } rc]} {
          if {![catch { ::FTP_PutFile $name $local $new_fname [file size $local] } rc]} {
            file delete -force $local
            return 1
          } else {
            logger::log $rc
            file delete -force $local
          }
        } else {
          logger::log $rc
        }
      }
    }

    return 0

  }

  ######################################################################
  # Removes one or more files on the server.
  proc remove_files {name fnames} {

    variable connections

    # Delete the list of directories
    switch [lindex $connections($name) 1] {
      "FTP" -
      "SFTP" {
        foreach fname $fnames {
          if {[catch { ::FTP_Delete $name $fname } rc]} {
            logger::log $rc
          }
        }
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Loads the FTP connections file.
  proc load_connections {} {

    variable widgets
    variable groups
    variable connections
    variable opened
    variable remote_file

    # Clear the connections
    array unset connections

    # Clear the table
    $widgets(sb) delete 0 end

    if {![catch { tkedat::read $remote_file 0 } rc]} {
      array set data $rc
      foreach key [lsort -dictionary [array names data]] {
        lassign [split $key ,] num group name
        if {![info exists groups($group)]} {
          set groups($group) [$widgets(sb) insertchild root end $group]
        }
        set row [$widgets(sb) insertchild $groups($group) end [list $name $data($key) [lindex $data($key) 3]]]
        set connections($group,$name) [list $row {*}$data($key)]
        if {[info exists opened($group,$name)]} {
          $widgets(sb) cellconfigure $row,name -image remote_connected
        }
      }
    }

    # If the table is empty, make sure that at least one group exists
    if {[$widgets(sb) size] == 0} {
      set groups(Group) [$widgets(sb) insertchild root end "Group"]
    }

  }

  ######################################################################
  # Saves the connections to a file
  proc save_connections {} {

    variable widgets
    variable connections
    variable remote_file

    array unset connections

    # Gather the data to save from the table
    set num 0
    foreach group_key [$widgets(sb) childkeys root] {
      set group [$widgets(sb) cellcget $group_key,name -text]
      foreach conn_key [$widgets(sb) childkeys $group_key] {
        set name     [$widgets(sb) cellcget $conn_key,name     -text]
        set settings [$widgets(sb) cellcget $conn_key,settings -text]
        lappend data "$num,$group,$name" $settings
        set connections($group,$name) [list $conn_key {*}[lreplace $settings 3 3 [$widgets(sb) cellcget $conn_key,passwd -text]]]
        incr num
      }
    }

    # Write the information to file
    catch { tkedat::write $remote_file $data 0 }

  }
  
  ######################################################################
  # Returns the list of files in the TKE home directory to copy.
  proc get_share_items {dir} {

    return [list remote.tkedat]

  }

  ######################################################################
  # Called whenever the share directory changes.
  proc share_changed {dir} {

    variable remote_file

    set remote_file [file join $dir remote.tkedat]

  }

}

