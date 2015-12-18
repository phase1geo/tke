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

namespace eval bist {

  ######################################################################
  # Runs the built-in self test.
  proc run {{loops 10}} {

    # Get the number of tests available to run
    set tests    [lsearch -inline -all [info procs] run_test*]
    set testslen [llength $tests]

    for {set i 0} {$i < $loops} {incr i} {
      eval [lindex $tests [expr int( rand() * $testslen )]]
    }

  }

  proc run_test1 {} {

    puts "In run_test1"

  }

  proc run_test2 {} {

    puts "In run_test2"

  }

  proc run_test3 {} {

    puts "In run_test3"

  }

  proc run_test4 {} {

    puts "In run_test4"

  }

  proc run_test5 {} {

    puts "In run_test5"

  }

}
