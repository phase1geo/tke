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

  array set data {}

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
    variable data

    # Specify that the regression should run
    set data(run) 1

    # Initialize a few things first
    initialize

    # Get the number of tests available to run
    set testslen [llength $tests]
    set err      0
    set pass     0
    set fail     0

    # Allow the BIST to dump output to the output text widget
    $data(widgets,output) configure -state normal
    $data(widgets,output) delete 1.0 end

    # Initialize the pass and fail widgets
    $data(widgets,total) configure -text $loops
    $data(widgets,pass)  configure -text 0
    $data(widgets,fail)  configure -text 0

    # Configure UI components
    $data(widgets,run)    configure -state disabled
    $data(widgets,cancel) configure -state normal

    $data(widgets,output) insert end "---------------------------------------------\n"
    $data(widgets,output) insert end "RUNNING BIST - [clock format [clock seconds]]\n\n"

    for {set i 0} {$i < $loops} {incr i} {
      set test [lindex $tests [expr int( rand() * $testslen )]]
      $data(widgets,output) insert end "Running $test...  "
      if {[catch { $test } rc]} {
        incr fail
        $data(widgets,output) insert end "  FAILED ($rc)\n"
        $data(widgets,fail) configure -text $fail
      } else {
        incr pass
        $data(widgets,output) insert end "  PASSED\n"
        $data(widgets,pass) configure -text $pass
      }

      # If the regression run has been cancelled, stop now
      if {!$data(run)} {
        break
      }
    }

    $data(widgets,output) insert end "\nPASSED: $pass, FAILED: $fail\n\n"
    $data(widgets,output) insert end "---------------------------------------------"

    # Disable the text widget
    $data(widgets,output) configure -state disabled

    # Configure UI components
    $data(widgets,run)    configure -state normal
    $data(widgets,cancel) configure -state disabled

    # Wrap things up
    finish

  }

  ######################################################################
  # Cancel the BIST diagnostic.
  proc cancel {} {

    variable data

    set data(run) 0

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

  ######################################################################
  # GUI WINDOW CODE BELOW
  ######################################################################

  ######################################################################
  # Create the BIST UI.
  proc create {} {

    variable data

    # If the BIST window already exists, do nothing
    if {[winfo exists .bistwin]} {
      return
    }

    # Create the window
    toplevel .bistwin
    wm title .bistwin "Built-In Self Test"

    # Create the main notebook
    ttk::notebook .bistwin.nb

    # Add the regression setup frame
    .bistwin.nb add [set sf [ttk::frame .bistwin.nb.sf]] -text "Setup"

    ttk::frame $sf.tf
    set data(widgets,tbl) [tablelist::tablelist $sf.tf.tl -columns {0 {} 0 {Name} 0 {Run Count}} \
      -treecolumn 1 -exportselection 0 \
      -xscrollcommand [list $sf.tf.hb set] \
      -yscrollcommand [list $sf.tf.vb set]]
    scroller::scroller $sf.tf.hb -orient horizontal -command [list $sf.tf.tl xview]
    scroller::scroller $sf.tf.vb -orient vertical   -command [list $sf.tf.tl yview]

    $sf.tf.tl columnconfigure 0 -name selected
    $sf.tf.tl columnconfigure 1 -name name
    $sf.tf.tl columnconfigure 2 -name count

    grid rowconfigure    $sf.tf 0 -weight 1
    grid columnconfigure $sf.tf 0 -weight 1
    grid $sf.tf.tl -row 0 -column 0 -sticky news
    grid $sf.tf.vb -row 0 -column 1 -sticky ns
    grid $sf.tf.hb -row 1 -column 0 -sticky ew

    pack $sf.tf -fill both -expand yes

    # Add the results frame
    .bistwin.nb add [set rf [ttk::frame .bistwin.nb.rf]] -text "Results"

    ttk::labelframe $rf.of -text "Output"
    set data(widgets,output) [text $rf.of.t -state disabled -wrap none \
      -xscrollcommand [list $rf.of.hb set] \
      -yscrollcommand [list $rf.of.vb set]]
    scroller::scroller $rf.of.hb -orient horizontal -command [list $rf.of.t xview]
    scroller::scroller $rf.of.vb -orient vertical   -command [list $rf.of.t yview]

    grid rowconfigure    $rf.of 0 -weight 1
    grid columnconfigure $rf.of 0 -weight 1
    grid $rf.of.t  -row 0 -column 0 -sticky news
    grid $rf.of.vb -row 0 -column 1 -sticky ns
    grid $rf.of.hb -row 1 -column 0 -sticky ew

    ttk::labelframe $rf.rf
    ttk::label      $rf.rf.l0 -text "Total: "
    set data(widgets,total) [ttk::label $rf.rf.tot -text "" -width 4]
    ttk::label      $rf.rf.l1 -text "Passed: "
    set data(widgets,pass) [ttk::label $rf.rf.pass -text "" -width 4]
    ttk::label      $rf.rf.l2 -text "Failed: "
    set data(widgets,fail) [ttk::label $rf.rf.fail -text "" -width 4]

    pack $rf.rf.l0   -side left -padx 2 -pady 2
    pack $rf.rf.tot  -side left -padx 2 -pady 2
    pack $rf.rf.l1   -side left -padx 2 -pady 2
    pack $rf.rf.pass -side left -padx 2 -pady 2
    pack $rf.rf.l2   -side left -padx 2 -pady 2
    pack $rf.rf.fail -side left -padx 2 -pady 2

    pack $rf.of -fill both -expand yes
    pack $rf.rf -fill x

    # Add the main button frame
    ttk::frame  .bistwin.bf
    set data(widgets,run)    [ttk::button .bistwin.bf.run   -text "Run"    -width 6 -command [list bist::run]]
    set data(widgets,cancel) [ttk::button .bistwin.bf.close -text "Cancel" -width 6 -command [list bist::cancel]]

    # Pack the button frame
    pack .bistwin.bf.close -side right -padx 2 -pady 2
    pack .bistwin.bf.run   -side right -padx 2 -pady 2

    # Pack the main UI elements
    pack .bistwin.nb -fill both -expand yes
    pack .bistwin.bf -fill x

  }

}
