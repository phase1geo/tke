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
catch { namespace delete bist }

namespace eval bist {

  variable testdir
  variable tests

  # Load all of the BIST files
  foreach bfile [glob -directory [file join $::tke_dir tests] *.tcl] {
    source $bfile
  }

  # Gather the list of tests to run
  foreach ns [namespace children] {
    lappend tests {*}[info procs ${ns}::run_test*]
  }

  ######################################################################
  # Runs the built-in self test.
  proc run {{loops 10}} {

    variable tests

    # Initialize a few things first
    initialize

    # Get the number of tests available to run
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

    # Wrap things up
    finish

  }

  ######################################################################
  # Initialize the test environment.
  proc initialize {} {

    variable testdir

    # Create the test directory pathname
    set testdir [file join $::tke_home bist]

    # Delete the test directory if it still exists
    file delete -force $testdir

    # Create the test directory
    file mkdir $testdir

    # Add files to the test directory
    for {set i 0} {$i < 5} {incr i} {
      if {![catch { open [file join $testdir test$i.txt] w} rc]} {
        puts $rc "This is test $i"
        close $rc
      }
    }

  }

  ######################################################################
  # Wraps up the run.
  proc finish {} {

    variable testdir

    file delete -force $testdir

  }

}
