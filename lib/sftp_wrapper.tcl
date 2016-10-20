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
# Name:    sftp_wrapper.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/19/2016
# Brief:   Wrapper around the SFTP code from filerunner to allow it to
#          work without modification.
######################################################################

# Only provide SFTP support if Expect is installed/available
if {![catch { package require Expect }]} {

  ######################################################################
  # This procedure is called by the sftp.tcl procedures.  We will ignore
  # their parameters.
  proc ::frputs {args} {}

  ######################################################################
  # This procedure is used by the sftp code.
  proc ::Log {str} {}

  ######################################################################
  # Required by sftp
  proc ::_ {s {p1 ""} {p2 ""} {p3 ""} {p4 ""}} {

    return [::msgcat::mc $s $p1 $p2 $p3 $p4]

  }

  ######################################################################
  # Required by sftp.
  proc ::smart_dialog {win parent title lines args} {

    set ans [tk_messageBox -parent .ftp -title $title -message [lindex $lines 2] -detail [lindex $lines 1] -default yes -type yesno]

    return [expr {($ans eq "yes") ? 1 : 2}]

  }

  set ::glob(debug) 0
  set ::glob(os)    "Unix"  ;# TBD

  # Load the sftp code base
  source [file join $tke_dir lib sftp sftp.tcl]

}

