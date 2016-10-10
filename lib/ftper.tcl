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

  array set widgets {}

  ######################################################################
  # Creates an FTP open dialog box and returns the selected file.
  proc create_open {} {

    variable widgets

    toplevel     .ftpo
    wm title     .ftpo [msgcat::mc "Open File via FTP"]
    wm transient .ftpo .

    ttk::frame .ftpo.ff
    set widgets(open_tl) [tablelist::tablelist .ftpo.ff.tl \
      -columns {0 {Name}} -treecolumn 0 -exportselection 0 \
      -xscrollcommand [list utils::set_xscrollbar .ftpo.ff.hb] \
      -yscrollcommand [list utils::set_yscrollbar .ftpo.ff.vb]]
    ttk::scrollbar .ftpo.ff.vb -orient vertical   -command [list .ftpo.ff.tl yview]
    ttk::scrollbar .ftpo.ff.hb -orient horizontal -command [list .ftpo.ff.tl xview]

    grid rowconfigure    .ftpo.ff 0 -weight 1
    grid columnconfigure .ftpo.ff 0 -weight 1
    grid .ftpo.ff.tl -row 0 -column 0 -sticky news
    grid .ftpo.ff.vb -row 0 -column 1 -sticky ns
    grid .ftpo.ff.hb -row 1 -column 0 -sticky ew

    ttk::frame  .ftpo.bf
    set widgets(open_open) [ttk::button .ftpo.bf.ok -text [msgcat::mc "Open"] -width 6 -command [list ftper::open] -state disabled]
    ttk::button .ftpo.bf.cancel -text [msgcat::mc "Cancel"] -width 6 -command [list ftper::open_cancel]

    pack .ftpo.bf.cancel -side right -padx 2 -pady 2
    pack .ftpo.bf.ok     -side right -padx 2 -pady 2

    pack .ftpo.ff -fill both -expand yes
    pack .ftpo.bf -fill x

    # Get the focus
    ::tk::SetFocusGrab .ftpo .ftpo.ff.tl

    # Wait for the window to close
    tkwait window .ftpo

    # Restore the focus
    ::tk::RestoreFocusGrab .ftpo .ftpo.ff.tl

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
  proc disconnect {} {

    variable data

    if {$data(connection) ne ""} {
      ::ftp::Close $data(connection)
      set data(connection) ""
    }

  }

}

