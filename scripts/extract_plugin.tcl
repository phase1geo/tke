#!tclsh8.6

# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2019  Trevor Williams (phase1geo@gmail.com)
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

set tke_dir [file dirname [file dirname [file normalize $::argv0]]]

lappend auto_path [file normalize [file join $tke_dir lib]]

package require zipper
package require base64

source [file join $tke_dir lib tkedat.tcl]
source [file join $tke_dir lib plugmgr.tcl]

####################################################################
# Displays the items in the base directory to standard output.  This
# is done to help identify any optional/required files that are misnamed.
proc display_contents {base} {

  array set expected {
    header.tkedat 1
    main.tcl 1
    README 0
    screenshot.png 0
    overview.md 0
    release_notes.md 0
  }

  puts "base: $base"
  puts "  Plugin directory contents:"

  foreach item [glob -directory $base -tails *] {
    if {[info exists expected($item)]} {
      puts "    * $item"
      unset expected($item)
    } else {
      puts "      $item"
    }
  }

  puts ""

  if {[array size expected] > 0} {
    puts "  The following files are expected but not present:"
    foreach item [lsort [array names expected]] {
      if {$expected($item)} {
        puts "    ! $item"
      } else {
        puts "      $item"
      }
    }
    puts ""
  }

}

####################################################################
# Parses the the given header.tkedat file and returns an list in Tcl
# array form containing the contents of this file.
proc parse_header {base header} {

  if {[catch { tkedat::read $header } rc]} {
    fail $base "ERROR:  Unable to parse header.tkedat" $rc
  }

  return $rc

}

####################################################################
# Returns the generated HTML from the given Markdown file.
proc generate_html_from_md {base mdfile} {

  if {[catch { exec [file join $::tke_dir lib ptwidgets1.2 common Markdown_1.0.1 Markdown.pl] $mdfile } rc]} {
    fail $base "ERROR:  Unable to generated HTML from Markdown file ($mdfile)" $rc
  }

  return $rc

}

####################################################################
# Checks to see if the developer provided an overview.md file in the
# bundle.  If the overview file is found, return the HTML version
# of this file; otherwise, return the empty string.
proc check_overview {base} {

  # Check to see if the user provided an overview file
  set overview [file join $base overview.md]

  if {[file exists $overview]} {
    return [generate_html_from_md $base $overview]
  }

  return ""

}

####################################################################
# Checks to see if the user provided release notes.
proc check_release_notes {base} {

  set release_notes [file join $base release_notes.md]

  if {[file exists $release_notes]} {
    return [generate_html_from_md $base $release_notes]
  }

  return ""

}

####################################################################
# Checks to see if the developer provided a screenshot file.  If one
# is found, return the name of the screenshot file.
proc check_screenshot {base} {

  set imgfile [file join $base screenshot.png]

  if {[file exists $imgfile]} {
    return $imgfile
  }

  return ""

}

####################################################################
# Generate a text file that contains all of the text that needs to be
# updated in the website.
proc create_snippet_file {base odir header_list overview release_notes} {

  set snippets [file join $odir ${base}_snippets.txt]

  if {[catch { open $snippets w } rc]} {
    fail $base "ERROR:  Unable to create snippet file" $rc
  }

  array set header $header_list

  puts $rc "Name:"
  puts $rc "----------------------------------------"
  puts $rc "$base\n"

  puts $rc "Category:"
  puts $rc "----------------------------------------"
  puts $rc "$header(category)\n"

  puts $rc "Description:"
  puts $rc "----------------------------------------"
  puts $rc "<p>$header(description)</p>"
  if {$header(email) eq ""} {
    puts $rc "<p><b>Author:</b> $header(author)"
  } else {
    puts $rc "<p><b>Author:</b> <a href=\"mailto://$header(email)\">$header(author)</a>"
  }
  if {$header(website) ne ""} {
    puts $rc "<p><b>Website:</b> $header(website)"
  }
  puts $rc "<p><b>Version:</b> $header(version)</p>\n"

  if {$overview ne ""} {
    puts $rc "Overview:"
    puts $rc "----------------------------------------"
    puts $rc $overview
  }

  if {$release_notes ne ""} {
    puts $rc "Release Notes:"
    puts $rc "----------------------------------------"
    puts $rc $release_notes
  }

  close $rc

  puts "  Created $snippets"

}

####################################################################
# Create the HTML file that will be displayed on this plugin's
# available page.
proc create_available_file {odir overview screenshot} {

  if {![catch { open [file join $odir available.html] w } rc]} {

    puts $rc $overview

    if {$screenshot ne ""} {
      puts $rc "<hr>"
      puts $rc "<p><img src=\"data:image/png;base64, [base64::encode $screenshot]\"/></p>"
    }

    close $rc

  }

}

####################################################################
# Create the HTML file that will be displayed on this plugin's
# installed page.
proc create_installed_file {odir release_notes} {

  if {![catch { open [file join $odir installed.html] w } rc]} {

    puts $rc "<h4>Release Notes</h4>"
    puts $rc "<dl>$release_notes</dl>"

    close $rc

  }

}

####################################################################
# Exits the application, cleaning up anything generated from this
# script.
proc fail {base msg {detail {}}} {

  puts $msg

  if {$detail ne ""} {
    puts $detail
  }

  catch { file delete -force $base }

  exit 1

}

# Get the plugin file from the command-line and formulate the base directory
set plugz  [lindex $argv 0]
set odir   [expr {([lindex $argv 1] ne "") ? [lindex $argv 1] : [pwd]}]
set basez  [file rootname [file tail $plugz]]
set dbfile "plugins.tkedat"  ;# We will want to change this at some point

puts "plugz: $plugz, odir: $odir, basez: $basez, dbfile: $dbfile"

# Unzip the tarball
if {[zipper::unzip $plugz [pwd]] == 0} {

  puts "HERE A"

  puts ""

  # Display the contents of the plugin main directory
  display_contents $basez

  # Parse the header.tkedat file
  array set header [parse_header $basez [file join $basez header.tkedat]]

  # Displays the contents of the header file
  puts "  Header contents:"
  foreach name [lsort [array names header]] {
    if {[string first , $name] == -1} {
      puts "    $name: $header($name)"
    }
  }
  puts ""

  # Check to see if the developer provided an overview
  set overview [check_overview $basez]

  # Check to see if the developer provided release notes
  set release_notes [check_release_notes $basez]

  # Check to see if the developer provided a screenshot
  set screenshot [check_screenshot $basez]

  # Add the plugin via the plugin manager
  if {[catch { plugmgr::add_plugin $dbfile $header(name) {*}[array get header] release_notes $release_notes } rc]} {
    fail $basez "ERROR:  Unable to update plugin database" $rc
  }

  # Create file containing snippets of text to add to webpage
  create_snippet_file $basez $odir $rc $overview $release_notes

  # Setup the directory to upload to the server
  create_available_file [file join $odir $basez] $overview $screenshot
  create_installed_file [file join $odir $basez] $release_notes

  # Create the screenshot (if applicable)
  if {$screenshot ne ""} {
    set imgfile [file join $odir ${basez}_[file tail $screenshot]]
    file copy -force $screenshot $imgfile
    puts "  Created $imgfile"
  }

  # Delete the directory
  file delete -force $basez

}

