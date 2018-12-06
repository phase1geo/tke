#!tclsh8.6

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

#########################################################################################
# Name:         extract_plugin.tcl
# Author:       Trevor Williams  (phase1geo@gmail.com)
# Date:         12/6/2018
# Description:  This script is for the purposes of updating the website plugin database
# Usage:        tclsh8.6 extract_plugin.tcl -- <tkeplugz_file>
#########################################################################################

lappend auto_path [file normalize [file join [file dirname $::argv0] .. lib]]

package require zipper

source [file join .. lib tkedat.tcl]

set plugz [lindex $argv 0]
set basez [file rootname [file tail $plugz]]

proc parse_header {header} {

  if {![catch { tkedat::read $header } rc]} {
    array set data $rc
  }

}

# Unzip the tarball
if {[zipper::unzip $plugz [pwd]] == 0} {

  parse_header [file join $basez header.tkedat]

}

