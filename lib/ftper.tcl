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

namespace eval ftper {

  variable password

  array set widgets     {}
  array set connections {}
  array set data        {}

  ######################################################################
  # Creates an FTP open dialog box and returns the selected file.
  proc create_open {} {

    variable widgets
    variable data

    toplevel     .ftpo
    wm title     .ftpo [msgcat::mc "Open File via FTP"]
    wm transient .ftpo .
    wm geometry  .ftpo 600x400

    set widgets(pw) [ttk::panedwindow .ftpo.pw -orient horizontal]

    ###########
    # SIDEBAR #
    ###########

    $widgets(pw) add [ttk::frame .ftpo.pw.lf]

    ttk::frame .ftpo.pw.lf.sf
    set widgets(open_lb) [listbox .ftpo.pw.lf.sf.lb \
      -relief flat \
      -background [utils::get_default_background] -foreground [utils::get_default_foreground] \
      -xscrollcommand [list utils::set_xscrollbar .ftpo.pw.lf.sf.hb] \
      -yscrollcommand [list utils::set_yscrollbar .ftpo.pw.lf.sf.vb]]
    ttk::scrollbar .ftpo.pw.lf.sf.vb -orient vertical   -command [list .ftpo.pw.lf.sf.lb yview]
    ttk::scrollbar .ftpo.pw.lf.sf.hb -orient horizontal -command [list .ftpo.pw.lf.sf.lb xview]

    bind $widgets(open_lb) <<ListboxSelect>> [list ftper::handle_open_lb_select]

    grid rowconfigure     .ftpo.pw.lf.sf 0 -weight 1
    grid columnconfigure .ftpo.pw.lf.sf 0 -weight 1
    grid .ftpo.pw.lf.sf.lb -row 0 -column 0 -sticky news
    grid .ftpo.pw.lf.sf.vb -row 0 -column 1 -sticky ns
    grid .ftpo.pw.lf.sf.hb -row 1 -column 0 -sticky ew

    ttk::frame  .ftpo.pw.lf.bf
    ttk::button .ftpo.pw.lf.bf.edit -text [msgcat::mc "Edit"] -command [list ftper::edit_sidebar]

    pack .ftpo.pw.lf.bf.edit -side left -padx 2 -pady 2

    pack .ftpo.pw.lf.sf -fill both -expand yes
    pack .ftpo.pw.lf.bf -fill x

    ##########
    # VIEWER #
    ##########

    $widgets(pw) add [ttk::frame .ftpo.pw.rf] -weight 1

    ttk::frame .ftpo.pw.rf.ff
    set widgets(open_tl) [tablelist::tablelist .ftpo.pw.rf.ff.tl \
      -columns {0 {Name}} -treecolumn 0 -exportselection 0 \
      -xscrollcommand [list utils::set_xscrollbar .ftpo.pw.rf.ff.hb] \
      -yscrollcommand [list utils::set_yscrollbar .ftpo.pw.rf.ff.vb]]
    ttk::scrollbar .ftpo.pw.rf.ff.vb -orient vertical   -command [list .ftpo.pw.rf.ff.tl yview]
    ttk::scrollbar .ftpo.pw.rf.ff.hb -orient horizontal -command [list .ftpo.pw.rf.ff.tl xview]

    $widgets(open_tl) columnconfigure 0 -name fname -resizable 1 -stretchable 1 -editable 0

    bind $widgets(open_tl) <<TablelistSelect>> [list ftper::handle_open_tl_select]

    grid rowconfigure    .ftpo.pw.rf.ff 0 -weight 1
    grid columnconfigure .ftpo.pw.rf.ff 0 -weight 1
    grid .ftpo.pw.rf.ff.tl -row 0 -column 0 -sticky news
    grid .ftpo.pw.rf.ff.vb -row 0 -column 1 -sticky ns
    grid .ftpo.pw.rf.ff.hb -row 1 -column 0 -sticky ew

    ttk::frame  .ftpo.pw.rf.bf
    set widgets(open_open) [ttk::button .ftpo.pw.rf.bf.ok -text [msgcat::mc "Open"] \
      -width 6 -command [list ftper::open] -state disabled]
    ttk::button .ftpo.pw.rf.bf.cancel -text [msgcat::mc "Cancel"] -width 6 -command [list ftper::open_cancel]

    pack .ftpo.pw.rf.bf.cancel -side right -padx 2 -pady 2
    pack .ftpo.pw.rf.bf.ok     -side right -padx 2 -pady 2

    pack .ftpo.pw.rf.ff -fill both -expand yes
    pack .ftpo.pw.rf.bf -fill x

    pack .ftpo.pw -fill both -expand yes

    # Populate sidebar
    populate_sidebar

    # Get the focus
    ::tk::SetFocusGrab .ftpo .ftpo.pw.rf.ff.tl

    # Wait for the window to close
    tkwait window .ftpo

    # Restore the focus
    ::tk::RestoreFocusGrab .ftpo .ftpo.pw.rf.ff.tl

    return $data(open_fname)

  }

  ######################################################################
  # Handles a selection of a connection.
  proc handle_open_lb_select {} {

    variable widgets
    variable connections

    # Get the selection
    set selected [$widgets(open_lb) curselection]

    # Get the connection information
    lassign $connections([$widgets(open_lb) get $selected]) server user passwd startdir

    if {$passwd eq ""} {
      set passwd [get_password]
    }

    # Connect to the FTP server
    connect $server $user $passwd $startdir $widgets(open_tl)

  }

  ######################################################################
  # Handles a selection of a file in the file viewer.
  proc handle_open_tl_select {} {

    variable widgets

    $widgets(open_open) configure -state normal

  }

  ######################################################################
  # Handles a click on the sidebar Edit button.
  proc edit_sidebar {} {

    # TODO - Open preferences to FTP manager

  }

  ######################################################################
  # Populates the sidebar with connection information.
  proc populate_sidebar {} {

    variable widgets
    variable connections

    # Read the contents of the FTP file
    load_file

    # Set the listbox values
    $widgets(open_lb) delete 0 end

    foreach name [array names connections] {
      $widgets(open_lb) insert end $name
    }

  }

  ######################################################################
  # Get the connection password from the user.
  proc get_password {} {

    variable password

    set password ""

    toplevel     .ftppass
    wm title     .ftppass [msgcat::mc "Enter Password"]
    wm transient .ftppass .ftpo

    ttk::frame .ftppass.f
    ttk::label .ftppass.f.l -text [msgcat::mc "Password: "]
    ttk::entry .ftppass.f.e -validate key -validatecmd [list ftper::check_password %P] -textvariable ftper::password -show 0 -width 30

    bind .ftppass.f.e <Return> [list .ftppass.bf.ok invoke]

    pack .ftppass.f.l -side left -padx 2 -pady 2
    pack .ftppass.f.e -side left -padx 2 -pady 2 -fill x -expand yes

    ttk::frame .ftppass.bf
    ttk::frame .ftppass.bf.ok     -text [msgcat::mc "OK"]     -width 6 -command [list ftper::password_ok] -state disabled
    ttk::frame .ftppass.bf.cancel -text [msgcat::mc "Cancel"] -width 6 -command [list ftper::password_cancel]

    pack .ftppass.bf.cancel -side right -padx 2 -pady 2
    pack .ftppass.bf.ok     -side right -padx 2 -pady 2

    pack .ftppass.f  -fill x -expand yes
    pack .ftppass.bf -fill x

    # Center the password window
    ::tk::PlaceWindow .ftppass widget .ftpo

    # Get the focus/grab
    ::tk::SetFocusGrab .ftppass .ftppass.e

    # Wait for the window to close
    tkwait window .ftppass

    # Restore the focus/grab
    ::tk::RestoreFocusGrab .ftppass .ftppass.e

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
  # Opens the given file.
  proc open {} {

    variable widgets
    variable data

    # Get the currently selected item
    set selected [$widgets(open_tl) curselection]

    # Get the filename
    set data(open_fname) [$widgets(open_tl) cellcget $selected,fname -text]

    # Kill the window
    destroy .ftpo

  }

  ######################################################################
  # Cancels the open operation.
  proc open_cancel {} {

    variable data

    # Indicate that no file was chosen
    set data(open_fname) ""

    # Disconnect the connection
    # TODO

    # Close the window
    destroy .ftpo

  }

  ######################################################################
  # Connects to the given FTP server and loads the contents of the given
  # start directory into the open dialog table.
  proc connect {server user passwd startdir tbl} {

    variable data

    # Open the connection
    if {[set connection [::ftp::Open $server $user $passwd]] >= 0} {
      set data($server,$user,connection) $connection
    }

    # Clear the table
    $tbl delete 0 end

    # Get the contents of the start directory
    if {[::ftp::Cd $data($server,$user,connection) $startdir]} {
      foreach fname [::ftp::NList $data($server,$user,connection)] {
        $tbl insert end [list $fname]
      }
    }

  }

  ######################################################################
  # Disconnects from the given FTP server.
  proc disconnect {server user} {

    variable data

    if {$data($server,$user,connection) ne ""} {
      ::ftp::Close $data($server,$user,connection)
      set data($server,$user,connection) ""
    }

  }

  ######################################################################
  # Loads the FTP connections file.
  proc load_file {} {

    variable connections

    set fname [file join $::tke_home ftp.tkedat]

    if {![catch { tkedat::read $fname } rc]} {
      array set connections $rc
    }

  }

  ######################################################################
  # Saves the connections to a file
  proc save_file {} {

    variable connections

    set fname [file join $::tke_home ftp.tkedat]

    catch { tkedat::write $fname [array get connections] }

  }

  set connections(Development) [list frs.sourceforge.net phase1geo,tke "" /home/project-web/tke/htdocs/releases]

}

