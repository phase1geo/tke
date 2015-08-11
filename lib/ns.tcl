# TKE - Advanced Programmer's Editor
# Copyright (C) 2014  Trevor Williams (phase1geo@gmail.com)
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
# Name:     ns.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     6/7/2014
# Version:  $Revision$
# Brief:    Contains namespace-handling function.
######################################################################

proc ns {name} {

  if {[namespace parent] eq "::"} {
    return "::$name"
  } else {
    return "[namespace parent]::$name"
  }
  
}
