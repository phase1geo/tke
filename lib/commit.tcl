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
# Name:    commit.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    9/12/2013
######################################################################

# Read the contents of the version file to get the dot version
source "version.tcl"

# Get the global ID and local ID
set id [exec hg id -n]

if {[catch "open version.tcl w" rc]} {
  error $rc
  exit 1
} else {
  puts $rc "set version_major \"$version_major\""
  puts $rc "set version_minor \"$version_minor\""
  puts $rc "set version_point \"$version_point\""
  puts $rc "set version_hgid  \"[string range $id 0 end-1]\""
  close $rc
}

