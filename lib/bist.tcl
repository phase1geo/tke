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

  # In case the UI is closed without running a regression...
  set data(done) 1

  ######################################################################
  # Populates the test list.
  proc refresh {args} {

    variable data
    variable tests

    # If the BIST window exists, we don't need to do anything
    if {![winfo exists .bistwin]} {
      return
    }

    # Get the list of selected diagnostics in the table
    set selected [get_selections]

    # Load all of the BIST files
    foreach bfile [glob -directory [file join $::tke_dir tests] *.tcl] {
      if {[catch { source $bfile } rc]} {
        puts $::errorInfo
      }
    }

    # Gather the list of tests to run
    set tests [list]
    foreach ns [namespace children] {
      lappend tests {*}[info procs ${ns}::run_test*]
    }

    # Organize the test items
    set i 0
    foreach test $tests {
      lassign [string map {{::} { }} $test] dummy category name
      lappend test_array($category) $name
      incr i
    }

    # Clear the tablelist
    $data(widgets,tbl) delete 0 end

    # Add the test items to the tablelist
    foreach category [lsort -dictionary [array names test_array]] {
      set node [$data(widgets,tbl) insertchild root end [list 1 $category 0 0 0 ""]]
      $data(widgets,tbl) rowconfigure $node -background grey
      $data(widgets,tbl) cellconfigure $node,selected -image $data(images,checked)
      foreach test [lsort -dictionary $test_array($category)] {
        set cmd   [join [list bist $category $test] ::]
        set child [$data(widgets,tbl) insertchild $node end [list 1 $test 0 0 0 $cmd]]
        $data(widgets,tbl) cellconfigure $child,selected -image $data(images,checked)
      }
    }

    # Collapse all tests
    $data(widgets,tbl) collapseall

    # Sets the given selections
    set_selections $selected

  }

  ######################################################################
  # Runs the built-in self test.
  proc run {} {

    variable tests
    variable data
    variable run_tests

    # Specify that the regression should run
    set data(run)  1
    set data(done) 0

    # Initialize a few things first
    initialize

    # Get the number of tests available to run
    set testslen [llength $run_tests]
    set err      0
    set pass     0
    set fail     0

    # Make sure that the results tab is displayed.
    $data(widgets,nb) select 2

    # Allow the BIST to dump output to the output text widget
    $data(widgets,output) configure -state normal
    $data(widgets,output) delete 1.0 end
    $data(widgets,output) configure -state disabled

    # Initialize the pass and fail widgets
    $data(widgets,pass)  configure -text 0
    $data(widgets,fail)  configure -text 0

    # Configure UI components
    $data(widgets,refresh) configure -state disabled
    $data(widgets,run)     configure -state disabled
    $data(widgets,cancel)  configure -state normal

    update idletasks

    output "---------------------------------------------\n"
    output "RUNNING BIST - [clock format [clock seconds]]\n\n"

    set start_time [clock milliseconds]

    if {$data(run_mode) eq "iter"} {
      $data(widgets,total) configure -text [$data(widgets,iters) get]
      set index 0
      for {set i 0} {$i < [$data(widgets,iters) get]} {incr i} {
        output "Iteration [format {%4d} [expr $i + 1]]:  "
        switch $data(iter_mode) {
          random {
            if {![run_test [expr int( rand() * $testslen )] pass fail err]} {
              break
            }
          }
          increment {
            if {![run_test $index pass fail err]} {
              break
            }
            set index [expr ($index + 1) % $testslen]
          }
          decrement {
            set index [expr ($index == 0) ? ($testslen - 1) : ($index - 1)]
            if {![run_test $index pass fail err]} {
              break
            }
          }
        }
      }
    } elseif {$data(run_mode) eq "loop"} {
      $data(widgets,total) configure -text [expr [$data(widgets,loops) get] * $testslen]
      for {set i 0} {$i < [$data(widgets,loops) get]} {incr i} {
        set tests [list]
        for {set j 0} {$j < $testslen} {incr j} {
          lappend tests $j
        }
        switch $data(loop_mode) {
          random {
            for {set j 0} {$j < $testslen} {incr j} {
              set rn  [expr int( rand() * $testslen )]
              set val [lindex $tests $rn]
              lset tests $rn [lindex $tests $j]
              lset tests $j  $val
            }
          }
          decrement {
            set tests [lreverse $tests]
          }
        }
        output "\nLoop [expr $i + 1]\n\n"
        for {set j 0} {$j < $testslen} {incr j} {
          output "Test [format {%4d} [expr $j + 1]]:  "
          if {![run_test [lindex $tests $j] pass fail err]} {
            break
          }
        }
        if {!$data(run)} {
          break
        }
      }
    }

    set stop_time [clock milliseconds]

    output "\nPASSED: $pass, FAILED: $fail\n\n"
    output "Runtime: [runtime_string [expr $stop_time - $start_time]]\n"
    output "---------------------------------------------"

    # Configure UI components
    $data(widgets,refresh) configure -state normal
    $data(widgets,run)     configure -state normal
    $data(widgets,cancel)  configure -state disabled

    # Wrap things up
    finish

  }

  ######################################################################
  # Run the given test in the run_tests array.
  proc run_test {index ppass pfail perr} {

    upvar $ppass pass
    upvar $pfail fail
    upvar $perr  err

    variable data
    variable run_tests

    # Get the row and text to run
    lassign [lindex $run_tests $index] test row

    # Get the row's parent
    set par [$data(widgets,tbl) parentkey $row]

    # Increment the count cell for both the child and parent
    $data(widgets,tbl) cellconfigure $row,count -text [expr [$data(widgets,tbl) cellcget $row,count -text] + 1]
    $data(widgets,tbl) cellconfigure $par,count -text [expr [$data(widgets,tbl) cellcget $par,count -text] + 1]

    output "Running [format {%-40s} $test...]  "

    # Run the diagnostic and track the pass/fail status in the table
    if {[catch { $test } rc]} {
      incr fail
      output "  FAILED ($rc)\n"
      $data(widgets,fail) configure -text $fail
      $data(widgets,tbl)  cellconfigure $row,fail -text [expr [$data(widgets,tbl) cellcget $row,fail -text] + 1]
      $data(widgets,tbl)  cellconfigure $par,fail -text [expr [$data(widgets,tbl) cellcget $par,fail -text] + 1]
    } else {
      incr pass
      output "  PASSED\n"
      $data(widgets,pass) configure -text $pass
      $data(widgets,tbl)  cellconfigure $row,pass -text [expr [$data(widgets,tbl) cellcget $row,pass -text] + 1]
      $data(widgets,tbl)  cellconfigure $par,pass -text [expr [$data(widgets,tbl) cellcget $par,pass -text] + 1]
    }

    # Allow any user events to be handled
    update

    # Specify if we should continue to run
    return $data(run)

  }

  ######################################################################
  # Returns the runtime string.
  proc runtime_string {ms} {

    set hours   [expr $ms / 3600000]
    set minutes [expr ($ms - ($hours * 3600000)) / 60000]
    set seconds [expr ($ms - ($hours * 3600000) - ($minutes * 60000)) / 1000.0]

    return "$hours hours, $minutes minutes, $seconds seconds"

  }

  ######################################################################
  # Displays the given output to the BIST output widget.
  proc output {msg} {

    variable data

    $data(widgets,output) configure -state normal
    $data(widgets,output) insert end $msg
    $data(widgets,output) configure -state disabled

    $data(widgets,output) see insert

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
    variable data

    # Delete the temporary test directory
    file delete -force $testdir

    # Save the run settings
    save_options

    # Specify that we are done
    set data(done) 1

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
      -borderwidth 0 -highlightthickness 0 \
      -selectbackground blue -selectforeground white \
      -xscrollcommand [list $sf.tf.hb set] -yscrollcommand [list $sf.tf.vb set]]
    scroller::scroller $sf.tf.hb -orient horizontal -background white -foreground black -command [list $sf.tf.tl xview]
    scroller::scroller $sf.tf.vb -orient vertical   -background white -foreground black -command [list $sf.tf.tl yview]

    $sf.tf.tl columnconfigure 0 -name selected -editable 0 -resizable 0 -editwindow checkbutton \
      -formatcommand [list bist::format_cell] -labelimage $data(images,unchecked) -labelcommand [list bist::label_clicked]
    $sf.tf.tl columnconfigure 1 -name name     -editable 0 -resizable 0 -formatcommand [list bist::format_cell]
    $sf.tf.tl columnconfigure 2 -name count    -editable 0 -resizable 0
    $sf.tf.tl columnconfigure 3 -name pass     -editable 0 -resizable 0
    $sf.tf.tl columnconfigure 4 -name fail     -editable 0 -resizable 0
    $sf.tf.tl columnconfigure 5 -name test     -hide 1

    bind [$data(widgets,tbl) bodytag] <Button-$::right_click> [list bist::handle_right_click %W %x %y %X %Y]

    grid rowconfigure    $sf.tf 0 -weight 1
    grid columnconfigure $sf.tf 0 -weight 1
    grid $sf.tf.tl -row 0 -column 0 -sticky news
    grid $sf.tf.vb -row 0 -column 1 -sticky ns
    grid $sf.tf.hb -row 1 -column 0 -sticky ew

    pack $sf.tf -fill both -expand yes

    # Add the options frame
    .bistwin.nb add [set of [ttk::frame .bistwin.nb.of]] -text "Options"

    ttk::radiobutton $of.lrb -text "Run loops" -variable bist::data(run_mode) -value "loop" -command {
      bist::set_state .bistwin.nb.of.if disabled
      bist::set_state .bistwin.nb.of.lf normal
    }

    ttk::frame      $of.lf
    ttk::label      $of.lf.lcl  -text "Loop count: "
    set data(widgets,loops) [ttk::spinbox $of.lf.lcsb -from 1 -to 1000 -increment 1.0]
    ttk::label      $of.lf.ltl  -text "Loop type: "
    ttk::menubutton $of.lf.ltmb -menu [menu .bistwin.ltPopup -tearoff 0]

    grid rowconfigure    $of.lf 5 -weight 1
    grid columnconfigure $of.lf 0 -minsize 20
    grid columnconfigure $of.lf 1 -minsize 150
    grid columnconfigure $of.lf 3 -weight 1
    grid $of.lf.lcl  -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $of.lf.lcsb -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $of.lf.ltl  -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $of.lf.ltmb -row 1 -column 2 -sticky news -padx 2 -pady 2

    ttk::radiobutton $of.irb -text "Run iterations" -variable bist::data(run_mode) -value "iter" -command {
      bist::set_state .bistwin.nb.of.lf disabled
      bist::set_state .bistwin.nb.of.if normal
    }

    ttk::frame      $of.if
    ttk::label      $of.if.icl  -text "Iteration count: "
    set data(widgets,iters) [ttk::spinbox $of.if.icsb -from 1 -to 1000 -increment 1.0]
    ttk::label      $of.if.itl  -text "Selection method: "
    ttk::menubutton $of.if.itmb -menu [menu .bistwin.itPopup -tearoff 0]

    grid rowconfigure    $of.if 5 -weight 1
    grid columnconfigure $of.if 0 -minsize 20
    grid columnconfigure $of.if 1 -minsize 150
    grid columnconfigure $of.if 3 -weight 1
    grid $of.if.icl  -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $of.if.icsb -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid $of.if.itl  -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $of.if.itmb -row 1 -column 2 -sticky news -padx 2 -pady 2

    pack $of.lrb -fill x -padx 2 -pady 2
    pack $of.lf  -fill x -padx 2 -pady 2
    pack $of.irb -fill x -padx 2 -pady 2
    pack $of.if  -fill x -padx 2 -pady 2

    # Create loop mode menu
    foreach {val lbl} {
      "random"    "Random"
      "increment" "Incrementing order"
      "decrement" "Decrementing order"
    } {
      set cmd [list bist::set_mode .bistwin.nb.of.lf.ltmb $lbl $val loop_mode]
      .bistwin.ltPopup add radiobutton -label $lbl -variable bist::data(loop_mode) -value $val -command $cmd
    }

    # Create iteration mode menu
    foreach {val lbl} {
      "random"    "Random"
      "increment" "Incrementing order"
      "decrement" "Decrementing order"
    } {
      set cmd [list bist::set_mode .bistwin.nb.of.if.itmb $lbl $val iter_mode]
      .bistwin.itPopup add radiobutton -label $lbl -variable bist::data(iter_mode) -value $val -command $cmd
    }

    # Initialize UI state
    set data(run_mode)  "iter"
    set data(loop_mode) "random"
    set data(iter_mode) "random"
    $data(widgets,loops) set 1
    $of.lf.ltmb configure -text "Random"
    $data(widgets,iters) set 50
    $of.if.itmb configure -text "Random"
    set_state $of.lf disabled

    # Add the results frame
    .bistwin.nb add [set rf [ttk::frame .bistwin.nb.rf]] -text "Results"

    ttk::labelframe $rf.of -text "Output"
    set data(widgets,output) [text $rf.of.t -state disabled -wrap none \
      -relief flat -borderwidth 0 -highlightthickness 0 \
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
    set data(widgets,refresh) [ttk::button .bistwin.bf.refresh -style BButton -text "Refresh" -width 7 -command [list bist::refresh]]
    set data(widgets,run)     [ttk::button .bistwin.bf.run     -style BButton -text "Run"     -width 7 -command [list bist::run]]
    set data(widgets,cancel)  [ttk::button .bistwin.bf.close   -style BButton -text "Cancel"  -width 7 -command [list bist::cancel] -state disabled]

    # Pack the button frame
    ttk::label      .bistwin.bf.l0 -text "Total: "
    set data(widgets,total) [ttk::label .bistwin.bf.tot -text "" -width 5]
    ttk::label      .bistwin.bf.l1 -text "Passed: "
    set data(widgets,pass) [ttk::label .bistwin.bf.pass -text "" -width 5]
    ttk::label      .bistwin.bf.l2 -text "Failed: "
    set data(widgets,fail) [ttk::label .bistwin.bf.fail -text "" -width 5]

    pack .bistwin.bf.l0      -side left  -padx 2 -pady 2
    pack .bistwin.bf.tot     -side left  -padx 2 -pady 2
    pack .bistwin.bf.l1      -side left  -padx 2 -pady 2
    pack .bistwin.bf.pass    -side left  -padx 2 -pady 2
    pack .bistwin.bf.l2      -side left  -padx 2 -pady 2
    pack .bistwin.bf.fail    -side left  -padx 2 -pady 2
    pack .bistwin.bf.close   -side right -padx 2 -pady 2
    pack .bistwin.bf.run     -side right -padx 2 -pady 2
    pack .bistwin.bf.refresh -side right -padx 2 -pady 2

    # Pack the main UI elements
    pack .bistwin.nb -fill both -expand yes
    pack .bistwin.bf -fill x

    # Handle a window destruction
    bind [$data(widgets,tbl) bodytag] <Button-1> [list bist::on_select %W %x %y]

    # Create testlist menus
    menu .bistwin.filePopup -tearoff 0
    .bistwin.filePopup add command -label "New Test File" -command [list bist::create_file]
    .bistwin.filePopup add command -label "New Test"      -command [list bist::create_test]
    .bistwin.filePopup add separator
    .bistwin.filePopup add command -label "Edit Test File" -command [list bist::edit_file]

    menu .bistwin.testPopup -tearoff 0
    .bistwin.testPopup add command -label "Edit Test"     -command [list bist::edit_test]

    # Handle the window close event
    wm protocol .bistwin WM_DELETE_WINDOW [list bist::on_destroy]

    # Populate the testlist
    refresh

    # Load the saved options (if any)
    load_options

  }

  ######################################################################
  # Displays the UI window to enter a test file.
  proc create_file {} {

    toplevel     .bistwin.namewin
    wm title     .bistwin.namewin "New Test Name"
    wm transient .bistwin.namewin .bistwin
    wm resizable .bistwin.namewin 0 0

    ttk::frame .bistwin.namewin.f
    ttk::label .bistwin.namewin.f.l -text "Name: "
    ttk::entry .bistwin.namewin.f.e -validate key -validatecommand [list bist::validate_file %P]

    pack .bistwin.namewin.f.l -side left -padx 2 -pady 2
    pack .bistwin.namewin.f.e -side left -padx 2 -pady 2 -fill x

    ttk::frame .bistwin.namewin.bf
    ttk::button .bistwin.namewin.bf.create -style BButton -text "Create" -width 6 -command {
      bist::generate_file [.bistwin.namewin.f.e get]
      destroy .bistwin.namewin
    } -state disabled
    ttk::button .bistwin.namewin.bf.cancel -style BButton -text "Cancel" -width 6 -command {
      destroy .bistwin.namewin
    }

    pack .bistwin.namewin.bf.cancel -side right -padx 2 -pady 2
    pack .bistwin.namewin.bf.create -side right -padx 2 -pady 2

    pack .bistwin.namewin.f  -fill x
    pack .bistwin.namewin.bf -fill x

    # Get the grab
    ::tk::SetFocusGrab .bistwin.namewin .bistwin.namewin.f.e

    # Wait for the window to be destroyed
    tkwait window .bistwin.namewin

    # Release the grab
    ::tk::RestoreFocusGrab .bistwin.namewin .bistwin.namewin.f.e

  }

  ######################################################################
  # Validates the given filename and sets the UI state accordingly.
  proc validate_file {value} {

    if {($value eq "") || [file exists [file join $::tke_dir tests $value.tcl]]} {
      .bistwin.namewin.bf.create configure -state disabled
    } else {
      .bistwin.namewin.bf.create configure -state normal
    }

    return 1
  }

  ######################################################################
  # Adds the given test file to the editor.
  proc add_test_file {name} {

    return [gui::add_file end [file join $::tke_dir tests $name.tcl] -sidebar 0 -remember 0 -savecommand [list bist::refresh]]

  }

  ######################################################################
  # Generates a test file.
  proc generate_file {name} {

    # Open a file for writing
    if {![catch { open [file join $::tke_dir tests $name.tcl] w } rc]} {

      puts $rc "namespace eval $name {"
      puts $rc ""
      puts $rc "  proc run_test1 {} {"
      puts $rc ""
      puts $rc "  }"
      puts $rc ""
      puts $rc "}"

      close $rc

    }

    # Add the file to the editor
    add_test_file $name

    # Save the file
    gui::save_current {}

  }

  ######################################################################
  # Create a new test
  proc create_test {} {

    variable data

    # Get the selected row
    set selected [$data(widgets,tbl) curselection]

    # Get the test name
    set test [$data(widgets,tbl) cellcget $selected,name -text]

    # Get the test name
    set row [lindex [$data(widgets,tbl) childkeys $selected] end]

    # Get the new test name
    if {[regexp {run_test(\d+)} [$data(widgets,tbl) cellcget $row,name -text] -> num]} {
      set name "run_test[expr $num + 1]"
    }

    # Add the file to the editor
    set tab [add_test_file $test]

    # Get the text widget from the tab
    set txt [gui::get_info $tab tab txt]

    # Get the position of the second to last right curly bracket
    lassign [lrange [$txt tag ranges _curlyR] end-3 end-2] startpos endpos

    # Insert the test
    $txt insert $endpos "\n\n  proc $name {} {\n    \n  }"
    ::tk::TextSetCursor $txt $endpos+4c

    # Save the file
    gui::save_current {}

  }

  ######################################################################
  # Edit the currently selected test file.
  proc edit_file {} {

    variable data

    # Get the selected row
    set selected [$data(widgets,tbl) curselection]

    # Get the diagnostic name
    set fname [$data(widgets,tbl) cellcget $selected,name -text]

    # Add the file to the editor
    set tab [add_test_file $fname]

  }

  ######################################################################
  # Place the test file into the editing buffer and place the cursor and
  # view at the start of the test.
  proc edit_test {} {

    variable data

    # Get the selected row
    set selected [$data(widgets,tbl) curselection]

    # Get the test name
    set tname [$data(widgets,tbl) cellcget $selected,name -text]

    # Get the diagnostic name
    set parent [$data(widgets,tbl) parentkey $selected]
    set fname  [$data(widgets,tbl) cellcget $parent,name -text]

    # Add the file to the editor
    set tab [add_test_file $fname]

    # Get the text widget from the tab
    set txt [gui::get_info $tab tab txt]

    # Find the test in the file
    if {[set index [$txt search -regexp -- "proc\\s+$tname\\M" 1.0]] ne ""} {
      ::tk::TextSetCursor $txt $index
    }

  }

  ######################################################################
  # Sets the current mode and update the UI state.
  proc set_mode {mb lbl val mode} {

    variable data

    # Update the menubutton
    $mb configure -text $lbl

    # Update the mode value
    set data($mode) $val

  }

  ######################################################################
  # Recursively sets the given widgets and all ancestors to the given state.
  proc set_state {w state} {

    # Set the current state
    if {[catch { $w state [expr {($state eq "normal") ? "!disabled" : "disabled"}] } ]} {
      catch { $w configure -state $state }
    }

    # Set the state of the child widgets
    foreach child [winfo children $w] {
      set_state $child $state
    }

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
  # Handles a right-click on the table.
  proc handle_right_click {W x y X Y} {

    variable data

    lassign [tablelist::convEventFields $W $x $y] ::tablelist::W ::tablelist::x ::tablelist::y
    set row [$data(widgets,tbl) containing $::tablelist::y]

    if {$row != -1} {

      # Set the selection to the current row
      $data(widgets,tbl) selection clear 0 end
      $data(widgets,tbl) selection set $row

      # Display the appropriate menu
      if {[$data(widgets,tbl) parentkey $row] eq "root"} {
        tk_popup .bistwin.filePopup $X $Y
      } else {
        tk_popup .bistwin.testPopup $X $Y
      }

    }

  }

  ######################################################################
  # Called when the BIST window is destroyed.  Deletes images used by this
  # window.
  proc on_destroy {} {

    variable data

    catch {

      # If the regression is running we cannot be quit
      if {!$data(done)} {

        # Cause the regression to stop
        set data(run) 0

        return

      }

      # Delete the images
      image delete $data(images,checked) $data(images,unchecked)

      # Saves the current options
      save_options

    }

    # Delete the window
    destroy .bistwin

  }

  ######################################################################
  # Handles displaying the given cell
  proc format_cell {value} {

    variable data

    lassign [$data(widgets,tbl) formatinfo] key row col

    switch [$data(widgets,tbl) columncget $col -name] {
      "selected" { return "" }
      "name"     { return [string totitle $value] }
    }

    return ""

  }

  ######################################################################
  # Saves the current set of options to a file.
  proc save_options {} {

    variable data

    # Get the values to save into an array
    set options(run_mode)  $data(run_mode)
    set options(loop_mode) $data(loop_mode)
    set options(iter_mode) $data(iter_mode)
    set options(loops)     [$data(widgets,loops) get]
    set options(iters)     [$data(widgets,iters) get]
    set options(selected)  [get_selections]

    # Write the options
    catch { tkedat::write [file join $::tke_home bist.tkedat] [array get options] 0 }

  }

  ######################################################################
  # Load the options from the option file.
  proc load_options {} {

    variable data

    if {![catch { tkedat::read [file join $::tke_home bist.tkedat] 0 } rc]} {

      array set options $rc

      # Update the UI
      set data(run_mode)  $options(run_mode)
      set data(loop_mode) $options(loop_mode)
      set data(iter_mode) $options(iter_mode)

      $data(widgets,loops) set $options(loops)
      $data(widgets,iters) set $options(iters)

      # Update UI state
      if {$data(run_mode) eq "loop"} {
        set_state .bistwin.nb.of.lf normal
        set_state .bistwin.nb.of.if disabled
      } else {
        set_state .bistwin.nb.of.lf disabled
        set_state .bistwin.nb.of.if normal
      }

      # Update menubuttons
      for {set i 0} {$i <= [.bistwin.ltPopup index end]} {incr i} {
        if {[.bistwin.ltPopup entrycget $i -value] eq $options(loop_mode)} {
          .bistwin.nb.of.lf.ltmb configure -text [.bistwin.ltPopup entrycget $i -label]
        }
      }
      for {set i 0} {$i <= [.bistwin.itPopup index end]} {incr i} {
        if {[.bistwin.itPopup entrycget $i -value] eq $options(iter_mode)} {
          .bistwin.nb.of.if.itmb configure -text [.bistwin.itPopup entrycget $i -label]
        }
      }

      # Set the selections
      set_selections $options(selected)

    }

  }

  ######################################################################
  # Returns a list containing the test names that are currently selected
  # in the selection table.
  proc get_selections {} {

    variable data

    set selected [list]

    # Get the selection information
    for {set i 0} {$i < [$data(widgets,tbl) size]} {incr i} {
      if {([$data(widgets,tbl) parentkey $i] ne "root") && [$data(widgets,tbl) cellcget $i,selected -text]} {
        lappend selected [$data(widgets,tbl) cellcget $i,test -text]
      }
    }

    return $selected

  }

  ######################################################################
  # Sets the selections in the table based on the given list.
  proc set_selections {selected} {

    variable data

    set test_row   -1
    set tsel_count 0

    for {set i 0} {$i < [$data(widgets,tbl) size]} {incr i} {
      if {[$data(widgets,tbl) parentkey $i] eq "root"} {
        if {$test_row != -1} {
          set sel [expr {[llength [$data(widgets,tbl) childkeys $test_row]] == $sel_count}]
          $data(widgets,tbl) cellconfigure $test_row,selected -text $sel -image [expr {$sel ? $data(images,checked) : $data(images,unchecked)}]
          incr tsel_count $sel
        }
        set test_row  $i
        set sel_count 0
      } else {
        set test [$data(widgets,tbl) cellcget $i,test -text]
        set sel  [expr {[lsearch $selected $test] != -1}]
        incr sel_count $sel
        $data(widgets,tbl) cellconfigure $i,selected -text $sel -image [expr {$sel ? $data(images,checked) : $data(images,unchecked)}]
      }
    }

    if {$sel_count != -1} {
      set sel [expr {[llength [$data(widgets,tbl) childkeys $test_row]] == $sel_count}]
      $data(widgets,tbl) cellconfigure $test_row,selected -text $sel -image [expr {$sel ? $data(images,checked) : $data(images,unchecked)}]
      incr tsel_count $sel
    }

    if {[llength [$data(widgets,tbl) childkeys root]] == $tsel_count} {
      $data(widgets,tbl) columnconfigure selected -labelimage $data(images,checked)
    } else {
      $data(widgets,tbl) columnconfigure selected -labelimage $data(images,unchecked)
    }

  }

  ######################################################################
  # Handles a left-click on the selected column image.
  proc label_clicked {tbl col} {

    variable data

    # Figure out the value of selected
    set sel [expr {[$data(widgets,tbl) columncget selected -labelimage] ne $data(images,checked)}]
    set img [expr {$sel ? $data(images,checked) : $data(images,unchecked)}]

    # Change the label image
    $data(widgets,tbl) columnconfigure selected -labelimage $img

    # Change the row images and values
    for {set i 0} {$i < [$data(widgets,tbl) size]} {incr i} {
      $data(widgets,tbl) cellconfigure $i,selected -text $sel -image $img
    }

  }

}
