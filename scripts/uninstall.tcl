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

######################################################################
# Name:         uninstall.tcl
# Author:       Trevor Williams (phase1geo@gmail.com)
# Date:         5/26/2014
# Description:  Handles the uninstallation of TKE.
######################################################################

# We will read the tke.desktop file to get the installation directory
proc get_install_dir {} {

  if {![catch { open [file join / usr share applications tke.desktop] r } rc]} {

    # Read the contents of the .desktop file
    set contents [read $rc]
    close $rc

    # Parse the contents for the icon line
    foreach line [split $contents \n] {
      if {[regexp {^Icon=(.*).lib.tke.lib.images.tke_logo.svg$} $line -> dir]} {
        return $dir
      }
    }

  }

  return ""

}

set install_dir [get_install_dir]

while {$install_dir eq ""} {

  # Get the installation directory from the user
  puts -nonewline "\nEnter root installation directory (or Control-C to quit): "
  flush stdout
  set install_dir [file normalize [gets stdin]]

  if {![file exists [file join $install_dir bin tke]]} {
    puts "\nERROR:  The specified installation directory ($install_dir) does not contain files\n"
    set install_dir ""
    continue
  }

}

puts "install_dir: $install_dir"

# Delete the individual files
set desktop     [file join / usr share applications tke.desktop]
set mime        [file join / usr share mime packages tke.xml]
set theme_svg   [file join / usr share icons hicolor scalable mimetypes application-x-tkethemz.svg]
set plugin_svg  [file join / usr share icons hicolor scalable mimetypes application-x-tkeplugz.svg]
set appdata     [file join / usr share appdata tke.appdata.xml]
set libdir      [file join $install_dir lib tke]
set bin         [file join $install_dir bin tke]

foreach item [list $desktop $mime $theme_svg $plugin_svg $appdata $libdir $bin] {
  if {[file exists $item]} {
    puts -nonewline "Deleting $item...  "
    if {[catch { file delete -force $item } rc]} {
      puts "FAILED"
      exit 1
    }
    puts "DONE"
  }
}

# Exit the application
exit

