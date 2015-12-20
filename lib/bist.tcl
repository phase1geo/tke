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
# Name:    commit.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    9/12/2013
# Brief:   Contains namespace that runs a built-in self test.
######################################################################

# If the bist namespace already exists, delete it
namespace delete bist

namespace eval bist {

  ######################################################################
  # Runs the built-in self test.
  proc run {{loops 10}} {

    # Get the number of tests available to run
    set tests    [lsearch -inline -all [info procs] run_test*]
    set testslen [llength $tests]
    set err      0
    set pass     0
    set fail     0

    puts "---------------------------------------------"
    puts "RUNNING BIST - [clock format [clock seconds]]\n"

    for {set i 0} {$i < $loops} {incr i} {
      set test [lindex $tests [expr int( rand() * $testslen )]]
      puts -nonewline "Running $test...  "
      if {[catch { $test } rc]} {
        puts "  FAILED ($rc)"
        incr fail
      } else {
        puts "  PASSED"
        incr pass
      }
    }

    puts "\nPASSED: $pass, FAILED: $fail\n"
    puts "---------------------------------------------"

  }

  proc run_test1 {} {

    # Add a new file to the tab bar
    set tab [gui::add_new_file end]

    # Check to see that the tab exists in the tabbar
    set tb [gui::get_info $tab tab tabbar]

    puts "tabs: [$tb tabs], tab: $tab"

    # Check to make sure that the tab was added to the tabbar
    if {[lsearch [$tb tabs] $tab] == -1} {
      return -code error "New tab was not created"
    }

    # Close the tab
    gui::close_tab $tab

    # Check to make sure that the tab was removed from the tabbar
    if {[lsearch [$tb tabs] $tab] != -1} {
      return -code error "New tab was not closed"
    }

    return 1

  }

  proc run_test2 {} {

    return 1

  }

  proc run_test3 {} {

    return 0

  }

  proc run_test4 {} {

    return -code error "Blah"

  }

  proc run_test5 {} {

    return 1

  }

}
