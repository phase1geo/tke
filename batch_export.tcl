#!wish8.6

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
# Name:         batch_export.tcl
# Author:       Trevor Williams (phase1geo@gmail.com)
# Date:         10/7/2017
# Description:  Batch exports all downloadable themes.
######################################################################

set tke_home [file join ~ .tke]

lappend auto_path [file join [pwd] lib zipper]

package require zipper
package require msgcat

source [file join lib tkedat.tcl]
source [file join lib share.tcl]
source [file join lib themes.tcl]
source [file join lib theme.tcl]

# Create namespaces to satisfy the share::initialize function
foreach {a ns b} [share::get_share_items] {
  if {$ns ne "themes"} {
    namespace eval $ns {
      proc share_changed {dir} {}
    }
  }
}

# Load the sharing settings
share::initialize

puts "Getting themes from [themes::get_user_directory]\n"

# Create the themes directory
set output_dir [file join ~ Desktop UpdatedThemes]

file mkdir $output_dir

# Load the theme files
set themes [list]
foreach item [glob -nocomplain -directory [themes::get_user_directory] -types d *] {
  if {[file exists [file join $item [file tail $item].tketheme]]} {
    lappend themes [file join $item [file tail $item].tketheme]
  }
}

# Load each theme and then export it
foreach theme $themes {

  # Initialize some variables
  set name    [file rootname [file tail $theme]]
  set license [file join $theme LICENSE]

  # Load the theme
  theme::read_tketheme $theme

  # Export the theme to the output directory
  array set attrs [list creator "" website "" version ""]
  array set attrs [theme::get_attributions]

  puts "Exporting $name ([expr $attrs(version) + 1])"

  themes::export . $name $output_dir $attrs(creator) $attrs(website) $license

}

exit
