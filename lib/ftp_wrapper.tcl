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

######################################################################
# This procedure is called by the sftp.tcl procedures.  We will ignore
# their parameters.
proc ::frputs {args} {
  return
  set m {}
  foreach ar  $args {
    if {[string index $ar end] == " " } {
      set m [set m][string range $ar 0 end-1]
    } elseif { ! [catch "uplevel \"info exists $ar\" " ro] &&  $ro } {
      set m "[set m]$ar=[uplevel "set $ar"]< "
    } else {
      set m "[set m]$ar=<unset> "
    }
  }
  regsub -all {\n} $m {\\n} m
  regsub -all {\r} $m {\\r} m
  regsub -all {\t} $m {\\t} m
  puts "frputs: [set m]"
  flush stdout
}

######################################################################
# This procedure is used by the sftp code.
proc ::Log {str} {
  # puts "Log: $str"
}

######################################################################
# This procedure is used by the sftp code.
proc ::LogStatusOnly {str} {
  if {[::tke_development]} {
    puts "LogStatusOnly: $str"
  }
}

######################################################################
# This procedure is used by the ftp_control code.
proc ::LogSilent {str} {
  # puts "LogSilent: $str"
}

######################################################################
# Required by ftp_control.
proc PopWarn { warn } {

  logger::log $warn

}

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

######################################################################
# Returns the current time in milliseconds.  Required by ftp_control.tcl
proc ClockMilliSeconds {} {

  return [clock milliseconds]

}

set ::glob(debug)                  0
set ::glob(ftp,debug)              0
set ::glob(os)                     [expr {($::tcl_platform(platform) eq "unix") ? "Unix" : "Windows"}]
set ::glob(abortcmd)               0
set ::config(ftp,timeout)          60
set ::config(ftp,cache,maxentries) 0  ;# Effectively turn off caching
set ::ftp(cache)                   [list]

# Load the sftp code base only if we have Expect
if {![catch { package require Expect }]} {
  source [file join $tke_dir lib remote sftp.tcl]
}

# Load the FTP and FTP control files
source [file join $tke_dir lib remote ftp.tcl]
source [file join $tke_dir lib remote ftp_control.tcl]

