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
  variable run_tests

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
  # Populates the test list.
  proc populate_testlist {} {

    variable data
    variable tests

    # Organize the test items
    set i 0
    foreach test $tests {
      lassign [string map {{::} { }} $test] dummy category name
      lappend test_array($category) $name
      incr i
    }

    # Add the test items to the tablelist
    foreach category [lsort [array names test_array]] {
      set node [$data(widgets,tbl) insertchild root end [list 1 [string totitle $category] 0 0 0 ""]]
      $data(widgets,tbl) cellconfigure $node,selected -image $data(images,checked)
      foreach test [lsort $test_array($category)] {
        set child [$data(widgets,tbl) insertchild $node end [list 1 $test 0 0 0 [join [list bist $category $test] ::]]]
        $data(widgets,tbl) cellconfigure $child,selected -image $data(images,checked)
      }
    }

  }

  ######################################################################
  # Runs the built-in self test.
  proc run {{loops 30}} {

    variable tests
    variable data
    variable run_tests

    # Specify that the regression should run
    set data(run) 1

    # Initialize a few things first
    initialize

    # Get the number of tests available to run
    set testslen [llength $run_tests]
    set err      0
    set pass     0
    set fail     0

    # Make sure that the results tab is displayed.
    $data(widgets,nb) select 1

    # Allow the BIST to dump output to the output text widget
    $data(widgets,output) configure -state normal
    $data(widgets,output) delete 1.0 end
    $data(widgets,output) configure -state disabled

    # Initialize the pass and fail widgets
    $data(widgets,total) configure -text $loops
    $data(widgets,pass)  configure -text 0
    $data(widgets,fail)  configure -text 0

    # Configure UI components
    $data(widgets,run)    configure -state disabled
    $data(widgets,cancel) configure -state normal

    update idletasks

    output "---------------------------------------------\n"
    output "RUNNING BIST - [clock format [clock seconds]]\n\n"

    for {set i 0} {$i < $loops} {incr i} {
      lassign [lindex $run_tests [expr int( rand() * $testslen )]] test row
      $data(widgets,tbl) cellconfigure $row,count -text [expr [$data(widgets,tbl) cellcget $row,count -text] + 1]
      output "Running $test...  "
      if {[catch { $test } rc]} {
        incr fail
        output "  FAILED ($rc)\n"
        $data(widgets,fail) configure -text $fail
        $data(widgets,tbl)  cellconfigure $row,fail -text [expr [$data(widgets,tbl) cellcget $row,fail -text] + 1]
      } else {
        incr pass
        output "  PASSED\n"
        $data(widgets,pass) configure -text $pass
        $data(widgets,tbl)  cellconfigure $row,pass -text [expr [$data(widgets,tbl) cellcget $row,pass -text] + 1]
      }

      # Allow any user events to be handled
      update

      # If the regression run has been cancelled, stop now
      if {!$data(run)} {
        break
      }
    }

    output "\nPASSED: $pass, FAILED: $fail\n\n"
    output "---------------------------------------------"

    # Configure UI components
    $data(widgets,run)    configure -state normal
    $data(widgets,cancel) configure -state disabled

    # Wrap things up
    finish

  }

  ######################################################################
  # Displays the given output to the BIST output widget.
  proc output {msg} {

    variable data

    $data(widgets,output) configure -state normal
    $data(widgets,output) insert end $msg
    $data(widgets,output) configure -state disabled

  }

  ######################################################################
  # Cancel the BIST diagnostic.
  proc cancel {} {

    variable data

    set data(run) 0

  }

  ######################################################################
  # Resets the state of the UI.
  proc reset {} {

    variable data

    for {set i 0} {$i < [$data(widgets,tbl) size]} {incr i} {
      $data(widgets,tbl) cellconfigure $i,count -text 0
      $data(widgets,tbl) cellconfigure $i,pass  -text 0
      $data(widgets,tbl) cellconfigure $i,fail  -text 0
    }

  }

  ######################################################################
  # Initialize the test environment.
  proc initialize {} {

    variable testdir
    variable data
    variable run_tests

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

    # Get the list of tests to run
    set run_tests [list]
    for {set i 0} {$i < [$data(widgets,tbl) size]} {incr i} {
      if {[$data(widgets,tbl) cellcget $i,selected -text]} {
        if {[set test [$data(widgets,tbl) cellcget $i,test -text]] ne ""} {
          lappend run_tests [list $test $i]
        }
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

    # Create images
    set data(images,unchecked) [image create photo -file [file join $::tke_dir lib images unchecked.gif]]
    set data(images,checked)   [image create photo -file [file join $::tke_dir lib images checked.gif]]

    # Create the window
    toplevel .bistwin
    wm title .bistwin "Built-In Self Test"

    # Create the main notebook
    set data(widgets,nb) [ttk::notebook .bistwin.nb]

    # Add the regression setup frame
    .bistwin.nb add [set sf [ttk::frame .bistwin.nb.sf]] -text "Setup"

    ttk::frame $sf.tf
    set data(widgets,tbl) [tablelist::tablelist $sf.tf.tl -columns {0 {} 0 {Name} 0 {Run Count} 0 {Pass Count} 0 {Fail Count} 0 {}} \
      -treecolumn 1 -exportselection 0 -stretch all \
      -xscrollcommand [list $sf.tf.hb set] \
      -yscrollcommand [list $sf.tf.vb set]]
    scroller::scroller $sf.tf.hb -orient horizontal -background white -foreground black -command [list $sf.tf.tl xview]
    scroller::scroller $sf.tf.vb -orient vertical   -background white -foreground black -command [list $sf.tf.tl yview]

    $sf.tf.tl columnconfigure 0 -name selected -editable 0 -resizable 0 -editwindow checkbutton -formatcommand [list bist::format_cell]
    $sf.tf.tl columnconfigure 1 -name name     -editable 0 -resizable 0
    $sf.tf.tl columnconfigure 2 -name count    -editable 0 -resizable 0
    $sf.tf.tl columnconfigure 3 -name pass     -editable 0 -resizable 0
    $sf.tf.tl columnconfigure 4 -name fail     -editable 0 -resizable 0
    $sf.tf.tl columnconfigure 5 -name test     -hide 1

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
    scroller::scroller $rf.of.hb -orient horizontal -background white -foreground black -command [list $rf.of.t xview]
    scroller::scroller $rf.of.vb -orient vertical   -background white -foreground black -command [list $rf.of.t yview]

    grid rowconfigure    $rf.of 0 -weight 1
    grid columnconfigure $rf.of 0 -weight 1
    grid $rf.of.t  -row 0 -column 0 -sticky news
    grid $rf.of.vb -row 0 -column 1 -sticky ns
    grid $rf.of.hb -row 1 -column 0 -sticky ew

    pack $rf.of -fill both -expand yes

    # Add the main button frame
    ttk::frame  .bistwin.bf
    set data(widgets,reset)  [ttk::button .bistwin.bf.reset -text "Reset"  -width 6 -command [list bist::reset]]
    set data(widgets,run)    [ttk::button .bistwin.bf.run   -text "Run"    -width 6 -command [list bist::run]]
    set data(widgets,cancel) [ttk::button .bistwin.bf.close -text "Cancel" -width 6 -command [list bist::cancel] -state disabled]

    # Pack the button frame
    ttk::label      .bistwin.bf.l0 -text "Total: "
    set data(widgets,total) [ttk::label .bistwin.bf.tot -text "" -width 4]
    ttk::label      .bistwin.bf.l1 -text "Passed: "
    set data(widgets,pass) [ttk::label .bistwin.bf.pass -text "" -width 4]
    ttk::label      .bistwin.bf.l2 -text "Failed: "
    set data(widgets,fail) [ttk::label .bistwin.bf.fail -text "" -width 4]

    pack .bistwin.bf.l0    -side left  -padx 2 -pady 2
    pack .bistwin.bf.tot   -side left  -padx 2 -pady 2
    pack .bistwin.bf.l1    -side left  -padx 2 -pady 2
    pack .bistwin.bf.pass  -side left  -padx 2 -pady 2
    pack .bistwin.bf.l2    -side left  -padx 2 -pady 2
    pack .bistwin.bf.fail  -side left  -padx 2 -pady 2
    pack .bistwin.bf.close -side right -padx 2 -pady 2
    pack .bistwin.bf.run   -side right -padx 2 -pady 2
    pack .bistwin.bf.reset -side right -padx 2 -pady 2

    # Pack the main UI elements
    pack .bistwin.nb -fill both -expand yes
    pack .bistwin.bf -fill x

    # Handle a window destruction
    bind .bistwin                     <Destroy>  [list bist::on_destroy %W]
    bind [$data(widgets,tbl) bodytag] <Button-1> [list bist::on_select %W %x %y]

    # Populates the testlist
    populate_testlist

  }

  ######################################################################
  # Called when the tablelist widget is clicked on.
  proc on_select {W x y} {

    variable data

    lassign [tablelist::convEventFields $W $x $y] ::tablelist::W ::tablelist::x ::tablelist::y
    lassign [split [$data(widgets,tbl) containingcell $::tablelist::x $::tablelist::y] ,] row col

    if {($row != -1) && ($col == 0)} {

      # Set the checkbutton accordingly
      if {[$data(widgets,tbl) cellcget $row,selected -text]} {
        $data(widgets,tbl) cellconfigure $row,selected -text [set value 0] -image [set img $data(images,unchecked)]
      } else {
        $data(widgets,tbl) cellconfigure $row,selected -text [set value 1] -image [set img $data(images,checked)]
      }

      # If the row is a category, make all of the children selections match the parent's value
      foreach child [$data(widgets,tbl) childkeys $row] {
        $data(widgets,tbl) cellconfigure $child,selected -text $value -image $img
      }

    }

  }

  ######################################################################
  # Called when the BIST window is destroyed.  Deletes images used by this
  # window.
  proc on_destroy {w} {

    variable data

    if {$w ne ".bistwin"} {
      return
    }

    # Delete the images
    image delete $data(images,checked) $data(images,unchecked)

  }

  ######################################################################
  # Handles displaying the given cell
  proc format_cell {value} {

    return ""

  }

}
