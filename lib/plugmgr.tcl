# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
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
# Name:    plugmgr.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    12/06/2018
# Brief:   Namespace for the plugin manager.
######################################################################

namespace eval plugmgr {

  array set default_pdata {
    author        "Anonymous"
    email         ""
    website       ""
    version       "1.0"
    category      "Miscellaneous"
    description   ""
    release_notes ""
  }

  ######################################################################
  # Adds a single plugin to the plugin database file.  Returns the
  # data that is stored in the plugin entry.
  proc add_plugin {dbfile name args} {

    variable default_pdata

    # Store the important plugin values
    array set pdata [array get default_pdata]
    foreach {attr value} $args {
      if {[info exists pdata($attr)]} {
        set pdata($attr) $value
      }
    }

    if {[file exists $dbfile]} {

      # Read in the existing values
      if {[catch { tkedat::read $dbfile } rc]} {
        return -code error "Unable to read the given plugin database file"
      }

      array set data    $rc
      array set plugins $data(plugins)

    }

    set plugins($name) [array get pdata]
    set data(plugins)  [array get plugins]

    # Save the file
    if {[catch { tkedat::write $dbfile [array get data] } rc]} {
      return -code error "Unable to update the plugin database file"
    }

    return [array get pdata]

  }

}
