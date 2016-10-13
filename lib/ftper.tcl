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
# Name:    ftper.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/10/2016
# Brief:   Namespace that provides an FTP interface.
######################################################################

if {0} {
# Load the chilkat library (provides SFTP support)
switch -glob $tcl_platform(os) {
  Darwin { load [file join $::tke_dir lib chilkat macos chilkat.dylib] }
  Linux* {
    if {$tcl_platform(pointerSize) == 4} {
      load [file join $::tke_dir lib chilkat linux32 chilkat.so]
    } else {
      load [file join $::tke_dir lib chilkat linux64 chilkat.so]
    }
  }
}
}

namespace eval ftper {

  variable password
  variable connection -1
  variable contents

  array set widgets     {}
  array set data        {}
  array set groups      {}
  array set connections {}

  ######################################################################
  # Creates an FTP dialog box and returns the selected file.
  proc create {type} {

    variable widgets
    variable data

    toplevel     .ftp
    wm title     .ftp [expr {($type eq "open") ? [msgcat::mc "Open File"] : [msgcat::mc "Save File"]}]
    wm transient .ftp .
    wm geometry  .ftp 600x400

    set widgets(pw) [ttk::panedwindow .ftp.pw -orient horizontal]

    ###########
    # SIDEBAR #
    ###########

    $widgets(pw) add [ttk::frame .ftp.pw.lf]

    ttk::frame .ftp.pw.lf.sf
    set widgets(sb) [tablelist::tablelist .ftp.pw.lf.sf.tl \
      -columns {0 {Connections} 0 {} 0 {}} -treecolumn 0 -exportselection 0 -relief flat \
      -selectmode single -movablerows 1 -labelrelief flat \
      -labelactivebackground [utils::get_default_background] \
      -labelbackground [utils::get_default_background] \
      -labelforeground [utils::get_default_foreground] \
      -selectbackground [theme::get_value ttk_style active_color] \
      -acceptchildcommand [list ftper::accept_child_command] \
      -background [utils::get_default_background] -foreground [utils::get_default_foreground] \
      -xscrollcommand [list utils::set_xscrollbar .ftp.pw.lf.sf.hb] \
      -yscrollcommand [list utils::set_yscrollbar .ftp.pw.lf.sf.vb]]
    ttk::scrollbar .ftp.pw.lf.sf.vb -orient vertical   -command [list .ftp.pw.lf.sf.tl yview]
    ttk::scrollbar .ftp.pw.lf.sf.hb -orient horizontal -command [list .ftp.pw.lf.sf.tl xview]

    $widgets(sb) columnconfigure 0 -name name     -editable 0 -resizable 1 -stretchable 1
    $widgets(sb) columnconfigure 1 -name settings -hide 1
    $widgets(sb) columnconfigure 2 -name passwd   -hide 1

    bind [$widgets(sb) bodytag] <Double-Button-1>       [list ftper::handle_sb_select]
    bind [$widgets(sb) bodytag] <Button-$::right_click> [list ftper::show_sidebar_menu %W %x %y %X %Y]
    bind $widgets(sb)           <<TablelistRowMoved>>   [list ftper::handle_row_moved %d]

    grid rowconfigure    .ftp.pw.lf.sf 0 -weight 1
    grid columnconfigure .ftp.pw.lf.sf 0 -weight 1
    grid .ftp.pw.lf.sf.tl -row 0 -column 0 -sticky news
    grid .ftp.pw.lf.sf.vb -row 0 -column 1 -sticky ns
    grid .ftp.pw.lf.sf.hb -row 1 -column 0 -sticky ew

    ttk::frame  .ftp.pw.lf.bf
    set widgets(new_b) [ttk::button .ftp.pw.lf.bf.edit -style BButton -text "+" -width 1 -command [list ftper::show_new_menu]]

    pack .ftp.pw.lf.bf.edit -side left -padx 2 -pady 2

    pack .ftp.pw.lf.sf -fill both -expand yes
    pack .ftp.pw.lf.bf -fill x

    # Create contextual menus
    set widgets(new) [menu .ftp.newPopup -tearoff 0]
    $widgets(new) add command -label [msgcat::mc "New Group"]      -command [list ftper::new_group]
    $widgets(new) add command -label [msgcat::mc "New Connection"] -command [list ftper::new_connection]

    set widgets(group) [menu .ftp.groupPopup -tearoff 0 -postcommand [list ftper::group_post]]
    $widgets(group) add command -label [msgcat::mc "New Connection"] -command [list ftper::new_connection]
    $widgets(group) add separator
    $widgets(group) add command -label [msgcat::mc "Rename Group"]   -command [list ftper::rename_group]
    $widgets(group) add command -label [msgcat::mc "Delete Group"]   -command [list ftper::delete_group]

    set widgets(connection) [menu .ftp.connPopup -tearoff 0]
    $widgets(connection) add command -label [msgcat::mc "Open Connection"]   -command [list ftper::handle_sb_select]
    $widgets(connection) add separator
    $widgets(connection) add command -label [msgcat::mc "Edit Connection"]   -command [list ftper::edit_connection]
    $widgets(connection) add separator
    $widgets(connection) add command -label [msgcat::mc "Delete Connection"] -command [list ftper::delete_connection]

    ##########
    # VIEWER #
    ##########

    $widgets(pw) add [ttk::frame .ftp.pw.rf] -weight 1

    set widgets(viewer) [ttk::frame .ftp.pw.rf.vf]

    ttk::frame .ftp.pw.rf.vf.ff
    set widgets(tl) [tablelist::tablelist .ftp.pw.rf.vf.ff.tl \
      -columns {0 {File System}} -treecolumn 0 -exportselection 0 \
      -selectmode [expr {($type eq "save") ? "browse" : "extended"}] \
      -expandcommand  [list ftper::handle_table_expand] \
      -xscrollcommand [list utils::set_xscrollbar .ftp.pw.rf.vf.ff.hb] \
      -yscrollcommand [list utils::set_yscrollbar .ftp.pw.rf.vf.ff.vb]]
    ttk::scrollbar .ftp.pw.rf.vf.ff.vb -orient vertical   -command [list .ftp.pw.rf.vf.ff.tl yview]
    ttk::scrollbar .ftp.pw.rf.vf.ff.hb -orient horizontal -command [list .ftp.pw.rf.vf.ff.tl xview]

    $widgets(tl) columnconfigure 0 -name fname -resizable 1 -stretchable 1 -editable 0 -formatcommand [list ftper::format_name]

    bind $widgets(tl) <<TablelistSelect>> [list ftper::handle_tl_select]

    grid rowconfigure    .ftp.pw.rf.vf.ff 0 -weight 1
    grid columnconfigure .ftp.pw.rf.vf.ff 0 -weight 1
    grid .ftp.pw.rf.vf.ff.tl -row 0 -column 0 -sticky news
    grid .ftp.pw.rf.vf.ff.vb -row 0 -column 1 -sticky ns
    grid .ftp.pw.rf.vf.ff.hb -row 1 -column 0 -sticky ew

    ttk::frame  .ftp.pw.rf.vf.bf
    set widgets(folder) [ttk::button .ftp.pw.rf.vf.bf.folder -style BButton -text [msgcat::mc "New Folder"] \
      -command [list ftper::handle_new_folder]]
    set widgets(open) [ttk::button .ftp.pw.rf.vf.bf.ok -style BButton -text [msgcat::mc "Open"] \
      -width 6 -command [list ftper::handle_open] -state disabled]
    ttk::button .ftp.pw.rf.vf.bf.cancel -style BButton -text [msgcat::mc "Cancel"] \
      -width 6 -command [list ftper::handle_cancel]

    pack .ftp.pw.rf.vf.bf.cancel -side right -padx 2 -pady 2
    pack .ftp.pw.rf.vf.bf.ok     -side right -padx 2 -pady 2

    if {$type ne "open"} {
      pack .ftp.pw.rf.vf.bf.folder -side left -padx 2 -pady 2
    }

    pack .ftp.pw.rf.vf.ff -fill both -expand yes
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
    set widgets(edit_group)  [ttk::menubutton .ftp.ef.sf.mb1 -text ""    -menu [menu .ftp.egroupPopup -tearoff 0 -postcommand [list ftper::populate_group_menu]]]
    ttk::label .ftp.ef.sf.l2  -text [format "%s: " [msgcat::mc "Name"]]
    set widgets(edit_name)   [ttk::entry .ftp.ef.sf.ne  -validate key -validatecommand [list ftper::check_name %P]]
    ttk::label .ftp.ef.sf.l3  -text [format "%s: " [msgcat::mc "Server"]]
    set widgets(edit_server) [ttk::entry .ftp.ef.sf.se  -validate key -validatecommand [list ftper::check_server %P]]
    ttk::label .ftp.ef.sf.l4  -text [format "%s: " [msgcat::mc "Username"]]
    set widgets(edit_user)   [ttk::entry .ftp.ef.sf.ue  -validate key -validatecommand [list ftper::check_username %P]]
    ttk::label .ftp.ef.sf.l5  -text [format "%s (%s): " [msgcat::mc "Password"] [msgcat::mc "Optional"]]
    set widgets(edit_passwd) [ttk::entry .ftp.ef.sf.pe  -show *]
    ttk::label .ftp.ef.sf.l6  -text [format "%s: " [msgcat::mc "Port"]]
    set widgets(edit_port)   [ttk::entry .ftp.ef.sf.poe -validate key -validatecommand [list ftper::check_port %P] -invalidcommand bell]
    ttk::label .ftp.ef.sf.l7  -text [format "%s: " [msgcat::mc "Remote Directory"]]
    set widgets(edit_dir)    [ttk::entry .ftp.ef.sf.re  -validate key -validatecommand [list ftper::check_directory %P]]

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
      -width 6 -command [list ftper::test_connection] -state disabled]
    set widgets(edit_msg)    [ttk::label  .ftp.ef.bf.msg]
    set widgets(edit_create) [ttk::button .ftp.ef.bf.create -style BButton -text [msgcat::mc "Create"] \
      -width 6 -command [list ftper::update_connection] -state disabled]
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

    # Populate sidebar
    populate_sidebar

    # Populate the type menubutton
    .ftp.typePopup add command -label "FTP" -command [list $widgets(edit_type) configure -text "FTP"]

    # Get the focus
    ::tk::SetFocusGrab .ftp .ftp.pw.rf.ff.tl

    # Wait for the window to close
    tkwait window .ftp

    # Restore the focus
    ::tk::RestoreFocusGrab .ftp .ftp.pw.rf.ff.tl

    return [list $data(name) $data(fname)]

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
    } else {
      return [expr {[$tbl parentkey $target_parent] eq "root"}]
    }

  }

  ######################################################################
  # Handles any sidebar row moves.
  proc handle_row_moved {data} {

    # Just save the current connections
    save_connections

  }

  ######################################################################
  # Handles a post of the group popup menu.
  proc group_post {} {

    variable widgets

    if {[llength [$widgets(sb) childkeys root]] == 1} {
      $widgets(group) entryconfigure [msgcat::mc "Delete Group"] -state disabled
    } else {
      $widgets(group) entryconfigure [msgcat::mc "Delete Group"] -state normal
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

    # Get a password from the user if it is not set
    if {$passwd eq ""} {
      if {[set passwd [get_password]] eq ""} {
        return
      }
    }

    # Open and initialize the connection
    if {$type eq "FTP"} {
      if {[set connection [::ftp::Open $server $user $passwd -port $port -timeout 2]] == -1} {
        $widgets(edit_msg) configure -text "Failed!"
      } else {
        ::ftp::Close $connection
        $widgets(edit_msg) configure -text "Passed!"
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
      .ftp.egroupPopup add command -label $group -command [list ftper::change_group $group]
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
          ([$widgets(edit_port)   get] ne "") && \
          ([$widgets(edit_dir)    get] ne "")} {
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
        ([$widgets(edit_port)   get] ne "") && \
        ([$widgets(edit_dir)    get] ne "")} {
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
        ([$widgets(edit_port) get] ne "") && \
        ([$widgets(edit_dir)  get] ne "")} {
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
        ([$widgets(edit_port)   get] ne "") && \
        ([$widgets(edit_dir)    get] ne "")} {
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
        ($value ne "") && \
        ([$widgets(edit_dir)    get] ne "")} {
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
  # Checks the connection directory and handles the state of the Create button.
  proc check_directory {value} {

    variable widgets

    if {([$widgets(edit_name)   get] ne "") && \
        ([$widgets(edit_server) get] ne "") && \
        ([$widgets(edit_user)   get] ne "") && \
        ([$widgets(edit_port)   get] ne "") && \
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
  # Handles a selection of a connection.
  proc handle_sb_select {} {

    variable widgets
    variable data
    variable connection

    # Get the selection
    set selected [$widgets(sb) curselection]

    # We don't want to do anything when double-clicking a group
    if {[set parent [$widgets(sb) parentkey $selected]] eq "root"} {
      return
    }

    # Get the group name
    set group [$widgets(sb) cellcget $parent,name -text]

    # Get the connection name to load
    set data(name) "$group,[$widgets(sb) cellcget $selected,name -text]"

    # Get settings
    set settings [$widgets(sb) cellcget $selected,settings -text]

    # Connect to the FTP server and add the directory
    if {[set connection [connect $data(name)]] != -1} {
      add_directory $connection $widgets(tl) root [lindex $settings 5]
    }

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
    ttk::entry .groupwin.f.e -validate key -validatecommand [list ftper::validate_group %P]

    bind .groupwin.f.e <Return> [list .groupwin.bf.create invoke]

    pack .groupwin.f.l -side left -padx 2 -pady 2
    pack .groupwin.f.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame  .groupwin.bf
    ttk::button .groupwin.bf.create -style BButton -text [msgcat::mc "Create"] -width 6 -command {
      set ftper::value [.groupwin.f.e get]
      destroy .groupwin
    } -state disabled
    ttk::button .groupwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command {
      set ftper::value ""
      destroy .groupwin
    }

    pack .groupwin.bf.cancel -side right -padx 2 -pady 2
    pack .groupwin.bf.create -side right -padx 2 -pady 2

    pack .groupwin.f  -fill x -expand yes
    pack .groupwin.bf -fill x

    # Place the window in the middle of the FTP window
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
    ttk::entry .renwin.f.e -validate key -validatecommand [list ftper::validate_rename_group %P]

    bind .renwin.f.e <Return> [list .renwin.bf.ok invoke]

    pack .renwin.f.l -side left -padx 2 -pady 2
    pack .renwin.f.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame .renwin.bf
    ttk::button .renwin.bf.ok -style BButton -text [msgcat::mc "Rename"] -width 6 -command {
      set ftper::value [.renwin.f.e get]
      destroy .renwin
    } -state disabled
    ttk::button .renwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command {
      set ftper::value ""
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
  # Handles a selection of a file in the file viewer.
  proc handle_tl_select {} {

    variable widgets

    $widgets(open) configure -state normal

  }

  ######################################################################
  # Handles a table directory expansion.
  proc handle_table_expand {tbl row} {

    variable connection

    add_directory $connection $tbl $row [$tbl cellcget $row,fname -text]

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
    ttk::entry .ftppass.f.e -validate key -validatecommand [list ftper::check_password %P] -textvariable ftper::password -show * -width 30

    bind .ftppass.f.e <Return> [list .ftppass.bf.ok invoke]

    pack .ftppass.f.l -side left -padx 2 -pady 2
    pack .ftppass.f.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame  .ftppass.bf
    ttk::button .ftppass.bf.ok     -style BButton -text [msgcat::mc "OK"]     -width 6 -command [list ftper::password_ok] -state disabled
    ttk::button .ftppass.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command [list ftper::password_cancel]

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
    variable connection

    toplevel     .foldwin
    wm title     .foldwin [msgcat::mc "Create New Folder"]
    wm resizable .foldwin 0 0
    wm transient .foldwin .ftp

    ttk::frame .foldwin.f
    ttk::label .foldwin.f.l -text [format "%s: " [msgcat::mc "Folder Name"]]
    ttk::entry .foldwin.f.e -validate key -validatecommand [list ftper::check_folder_name %P]

    bind .foldwin.f.e <Return> [list .foldwin.bf.ok invoke]

    pack .foldwin.f.l -side left -padx 2 -pady 2
    pack .foldwin.f.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame .foldwin.bf
    ttk::button .foldwin.bf.ok -style BButton -text [msgcat::mc "Create"] -width 6 -command {
      set ftper::value [.foldwin.f.e get]
      destroy .foldwin
    } -state disabled
    ttk::button .foldwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width 6 -command {
      set ftper::value ""
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

    # Get the currently selected item
    set selected [$widgets(tl) curselection]

    # Insert the new directory, if it is successfully made within FTP
    if {$selected eq ""} {
      set new_folder [file join [lindex $connections($connection) 5] $value]
      if {[make_directory $connection $new_folder]} {
        $widgets(tl) insert root end $new_folder
      }
    } elseif {[llength [$widgets(tl) childkeys $selected]] > 0} {
      set new_folder [file join [$widgets(tl) cellcget $selected,fname -text] $value]
      if {[make_directory $connection $new_folder]} {
        $widgets(tl) insert $selected end $new_folder
      }
    } else {
      set new_folder [file join [file dirname [$widgets(tl) cellcget $selected,fname -text]] $value]
      if {[make_directory $connection $new_folder]} {
        $widgets(tl) insert [$widgets(tl) parentkey $selected] end $new_folder
      }
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
    variable data

    # Get the currently selected item
    set selected [$widgets(tl) curselection]

    # Get the filename
    set data(fname) [list]
    foreach select $selected {
      lappend data(fname) [$widgets(tl) cellcget $select,fname -text]
    }

    # Kill the window
    destroy .ftp

  }

  ######################################################################
  # Cancels the open operation.
  proc handle_cancel {} {

    variable data
    variable connection

    # Indicate that no file was chosen
    set data(name)  ""
    set data(fname) ""

    # Disconnect the connection
    if {$connection != -1} {
      disconnect $connection
    }

    # Close the window
    destroy .ftp

  }

  ######################################################################
  # Adds a new directory to the given table.
  proc add_directory {connection tbl parent directory} {

    # Delete the children of the given parent in the table
    $tbl delete [$tbl childkeys $parent]

    # Add the new directory
    foreach finfo [::ftp::List $connection $directory] {
      set dir   [expr {([string index [lindex $finfo 0] 0] eq "d") ? 1 : 0}]
      set fname "[lrange $finfo 8 end]"
      if {[string index $fname 0] eq "."} {
        continue
      }
      set row   [$tbl insertchild $parent end [file join $directory $fname]]
      if {$dir} {
        $tbl insertchild $row end [list]
        $tbl collapse $row
      }
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

    if {![info exists connections($name)]} {
      return -code error "Connection does not exist ($name)"
    }

    lassign $connections($name) key type server user passwd port startdir

    set connection -1

    # Get a password from the user if it is not set
    if {$passwd eq ""} {
      if {[set passwd [get_password]] eq ""} {
        return -1
      }
      lset connections($name) 3 $passwd
      if {[info exists widgets(sb)] && [winfo exists $widgets(sb)]} {
        $widgets(sb) cellconfigure $key,passwd -text $passwd
      }
    }

    # Open and initialize the connection
    if {$type eq "FTP"} {
      if {[set connection [::ftp::Open $server $user $passwd -port $port -timeout 2]] == -1} {
        tk_messageBox -parent .ftp -icon error -type ok -default ok \
          -message [msgcat::mc "Unable to connect to FTP server"] -detail "Server: $server\nUser: $user\nPort: $port"
        return -1
      }
    }

    return $connection

  }

  ######################################################################
  # Disconnects from the given FTP server.
  proc disconnect {connection} {

    if {$connection != -1} {
      ::ftp::Close $connection
    }

  }

  ######################################################################
  # Get the file contents of the given filename using the given connection
  # name if the remote file is newer than the given modtime.  Returns 1
  # if the file was retrieved without error; otherwise, returns 0.
  proc get_file {name fname pcontents pmodtime {mtime 0}} {

    upvar $pcontents contents
    upvar $pmodtime  modtime

    set retval 0

    if {[set connection [connect $name]] != -1} {
      if {[set modtime [::ftp::ModTime $connection $fname]] > $mtime} {
        ::ftp::Get $connection $fname -variable $pcontents
        set retval 1
      }
      disconnect $connection
    }

    return $retval

  }

  ######################################################################
  # Saves the given file contents to the given filename.  Returns 1 if
  # the file was saved successfully; otherwise, returns 0.
  proc save_file {name fname contents pmodtime} {

    upvar $pmodtime modtime

    if {[set connection [connect $name]] != -1} {
      ::ftp::Put $connection -data $contents $fname
      set modtime [::ftp::ModTime $connection $fname]
      disconnect $connection
      return 1
    }

    return 0

  }

  ######################################################################
  # Creates the given directory on the remote end.
  proc make_directory {name dirname} {

    if {[set connection [connect $name]] == -1} {
      tk_messageBox -parent .ftp -icon error -type ok -default ok -message [msgcat::mc "Unable to create directory remotely"] -detail $dirname
      return 0
    }

    # Make the directory remotely
    ::ftp::MkDir $connection $dirname

    # Disconnect from the FTP server
    disconnect $connection

    return 1

  }

  ######################################################################
  # Loads the FTP connections file.
  proc load_connections {} {

    variable widgets
    variable groups
    variable connections

    # Clear the table
    $widgets(sb) delete 0 end

    if {![catch { tkedat::read [file join $::tke_home ftp.tkedat] 0 } rc]} {
      array set data $rc
      foreach key [lsort -dictionary [array names data]] {
        lassign [split $key ,] num group name
        if {![info exists groups($group)]} {
          set groups($group) [$widgets(sb) insertchild root end $group]
        }
        set row [$widgets(sb) insertchild $groups($group) end [list $name $data($key) [lindex $data($key) 3]]]
        set connections($group,$name) [list $row {*}$data($key)]
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
    catch { tkedat::write [file join $::tke_home ftp.tkedat] $data 0 }

  }

}

