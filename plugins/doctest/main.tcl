# This TKE plugin allows the user to test TCL scripts à la Python doctest.
# See README.md for details.

namespace eval doctest {

  variable TEST       "doctest"
  variable TEST_BEGIN "#% $TEST"
  variable TEST_END   "#> $TEST"
  variable TEST_COMMAND "#%"
  variable TEST_RESULT  "#>"
  variable NOTHING "\nNo\nNo"
  variable ntestedany
  variable HINT1 "\n
Make the doctest blocks as

  $doctest::TEST_BEGIN

  ...
  #% tested-command
  \[#% tested-command\]
  #> output of tested-command
  \[#> output of tested-command\]
  ...

  $doctest::TEST_END

See details in [api::get_plugin_source_directory]/README.md
"

  ###################################################################
  # Get line stripped of spaces and uppercased

  proc strip_upcase {st} {

    return [string trim [string toupper [string map {{ } _} $st]] { _}]

  }

  ###################################################################
  # Make string of args (1 2 3 ... be string of "1 2 3 ...")

  proc string_of_args {args} {

    set msg ""; foreach m $args {set msg "$msg $m"}
    return [string trim $msg " \{\}"]

  }

  ###################################################################
  # Show info message, e.g.: MES "Info title" $st == $BL_END \n\n ...

  proc MES {title args} {

    tk_messageBox -parent . -title $title \
      -type ok -default ok -message [string_of_args $args]

  }

  ###################################################################
  # Show error message, e.g.: ERR $st == $BL_END \n\n ...

  proc ERR {args} {

    api::show_error [string_of_args $args]

  }

  ###################################################################
  # Show debug message, e.g.: D $st == $BL_END \n\n ...

  proc D {args} {

    MES "Debug" $args

  }

  ###################################################################
  # Get current text command

  proc get_txt {} {

    set file_index [api::file::current_index]
    if {$file_index == -1} {
      return ""
    }
    return [api::file::get_info $file_index txt]

  }

  ###################################################################
  # Get line's contents

  proc get_line_contents {txt ind} {

    return [$txt get \
      [$txt index "$ind linestart"] [$txt index "$ind lineend"]]

  }

  ###################################################################
  # Get test blocks (TEST_BEGIN ... TEST_END)

  proc get_test_blocks {txt} {

    variable BL_BEGIN
    variable BL_END
    set err [catch {$txt tag ranges sel} sel]
    if {!$err && [llength $sel]==2} {
      lassign $sel start end
      # when-if 2 or more selected lines, use the selection as the test block
      if {[expr int($end) - int($start)]} {
        return [list 0 [list \
          [$txt index "$start linestart"] [$txt index "$end lineend"]] \
          " in selected text"]
      }
    }
    set test_blocks [list]
    set block_begins 0
    set ind 0
    foreach st [split [$txt get 1.0 end] \n] {
      incr ind
      if {[sourced_line $st] ne ""} continue   ;# skip sourced lines
      set st [strip_upcase $st]
      if {[string first $BL_BEGIN $st]==0} {
        if {$block_begins} {
          return [list 1 [list]]     ;# unpaired begins
        }
        lappend test_blocks "$ind.0 + 1 lines" ;# begin of block
        set block_begins 1
      } elseif {$st == $BL_END} {
        if {!$block_begins} {
          return [list 2 [list]]     ;# unpaired ends
        }
        lappend test_blocks "$ind.0 - 1 lines lineend"  ;# end of block
        set block_begins 0
      }
    }
    if {![llength $test_blocks]} {
      set test_blocks [list 1.0 end]
    } elseif {$block_begins} {
      lappend test_blocks end  ;# end of block
    }
    return [list 0 $test_blocks]

  }

  ###################################################################
  # Get line of command or command's waited result

  proc get_line {block type i prevcontinuedName} {

    upvar $prevcontinuedName prevcontinued
    variable NOTHING
    variable TEST_RESULT
    set st [lindex $block $i-1]
    set strimmed [string trimleft $st]
    set tpos [string first $type $strimmed]
    if {!$prevcontinued || $tpos == 0} {
      set st $strimmed
    } else {
      set st "$type $st"    ;# continuing from previous line
    }
    set prevcontinued [expr {[string index $st end] eq "\\"}]
    if {$prevcontinued && $type eq $TEST_RESULT} {
      set st [string range $st 0 end-1]
    }
    if {[set i [string first $type $st]] == 0} {
      return [string range $st [expr {[string length $type]+1}] end]
    }
    return $NOTHING

  }

  ###################################################################
  # Get command/result lines

  # :Input:
  #   - block  - current analized block of text
  #   - type - type of line (COMMAND or RESULT)
  #   - i1   - starting line to process
  #   - i2   - ending line to process
  # :Returns:
  #   - command/result lines
  #   - next line to process

  proc get_com_res {block type i1 i2} {

    variable TEST
    variable NOTHING
    variable TEST_COMMAND
    set comres $NOTHING
    set prevcontinued 0
    for {set i $i1; set res ""} {$i <= $i2} {incr i} {
      set line [string trim [get_line $block $type $i prevcontinued] " "]
      if {[string index $line 0] eq "\"" && [string index $line end] eq "\""} {
        set line [string range $line 1 end-1]
      }
      if {[string first $TEST $line]==0} {
        continue             ;# this may occur when block is selection
      }
      if {$line == $NOTHING} {
        break
      } else {
        if {$comres==$NOTHING} {
          set comres ""
        }
        if {$type eq $TEST_COMMAND && [string index $comres end] eq "\\"} {
          set comres "[string trimright [string range $comres 0 end-1]] "
        } elseif {$comres != ""} {
          set comres "$comres\n"
        }
        set comres "$comres$line"
      }
    }
    return [list $comres $i]

  }

  ###################################################################
  # Get commands' results

  proc get_commands {block i1 i2} {

    variable TEST_COMMAND
    return [get_com_res $block $TEST_COMMAND $i1 $i2]

  }

  ###################################################################
  # Get waited results

  proc get_results {block i1 i2} {

    variable TEST_RESULT
    return [get_com_res $block $TEST_RESULT $i1 $i2]

  }

  ###################################################################
  # Execute commands and compare their results to waited ones

  proc execute_and_check {block safe commands results} {

    set err ""
    set ok 0
    if {[catch {
        if {$safe} {
          set tmpi [interp create -safe]
        } else {
          set tmpi [interp create]
        }
        set res [interp eval $tmpi $block\n$commands]
        interp delete $tmpi
        if {$res eq $results} {
          set ok 1
        }
      } e]
    } {
      if {$e eq $results} {
        set ok 1
      }
      set res $e
    }
    return [list $ok $res]

  }

  ###################################################################
  # check if "doctest source" and return sourced name or ""

  proc sourced_line {line} {

    variable TEST_COMMAND
    return [regexp -nocase -inline \
        "^\\s*$TEST_COMMAND\\s+DOCTEST\\s+SOURCE\\s+" $line]

  }

  ###################################################################
  # check if the line is "doctest quote"

  proc is_quoted_line {line} {

    variable BL_BEGIN
    variable BL_END
    set st [strip_upcase $line]
    return [expr \
     {![string first $BL_BEGIN $st] || ![string first $BL_END $st]}]

  }

  ###################################################################
  # Test block of commands and their results

  proc do_block {txt begin end safe verbose} {

    variable NOTHING
    variable TEST_COMMAND
    variable ntestedany
    set block_ok -1
    # make the block of commands, including "sourced" files
    set i1 [expr {int([$txt index $begin])}]
    set i2 [expr {int([$txt index $end])}]
    set block [set blocktxt {}]
    for {set i $i1} {$i <= $i2} {incr i} {
      set line [get_line_contents $txt $i.0]
      set foundptn [sourced_line $line]
      if {[set sl [string length $foundptn]]} {
        set fn [string trim [string range $line $sl-2 end]]
        if {[catch {set ch [open $fn]}]} {
          ERR "PWD: [pwd]\n\"$fn\" not open by\n $line"
          return 0
        }
        foreach l [split [read $ch] \n] {
          # skip any possible #% doctest, #> doctest
          if {![is_quoted_line $l]} {
            lappend block $l
            append blocktxt $l \n
          }
        }
        close $ch
      } else {
        set st [strip_upcase $line]
        if {![is_quoted_line $line]} {
          lappend block $line
          append blocktxt $line \n
        }
      }
    }
    set i2 [llength $block]
    for {set i 1} {$i < $i2} {} {
      lassign [get_commands $block $i $i2] commands i ;# get commands
      if {$commands != "" && $commands != $NOTHING} {
        lassign [get_results $block $i $i2] results i ;# get waited results
        lassign [execute_and_check $blocktxt $safe $commands $results] ok res
        if {$results==$NOTHING} {
          # no result waited, for GUI tests
          set ok true
          set res ""
        } else {
          incr ntestedany
        }
        set coms "% $commands\n\n"
        if {$ok} {
          if {$verbose} {
            MES "DOCTEST" "${coms}> $res\n\nOK"
          }
          if {$block_ok==-1} {set block_ok 1}
        } else {
          if {$verbose} {
            ERR "DOCTEST\n\n${coms}GOT:\n\"$res\"
            \nWAITED:\n\"$results\"
            \nFAILED"
          }
          set block_ok 0
        }
      } else {
        incr i
      }
    }
    return $block_ok

  }

  proc do_blocks {txt blocks safe verbose forsel} {

    variable HINT1
    variable ntestedany
    set all_ok -1
    set ntested [set ntestedany 0]
    foreach {begin end} $blocks {
      set block_ok [do_block $txt $begin $end $safe $verbose]
      if {$block_ok!=-1} {
        incr ntested
        if {$block_ok==1 && $all_ok==-1} {
          set all_ok 1
        } elseif {$block_ok==0} {
          set all_ok 0
        }
      }
    }
    if {!$ntested} {
      ERR "Nothing to test$forsel.$HINT1"
    } elseif {!$verbose && $ntestedany} {
      if {$all_ok} {
        MES "DOCTEST" "Tested ${ntested} block(s):\n\nOK"
      } else {
        ERR "DOCTEST:\n\nTested ${ntested} block(s):\n\nFAILED"
      }
    }

  }

  #####################################################################
  #  DO procedures

  ###################################################################
  # Perform doctest

  proc do_doctest {safe verbose} {

    variable TEST_BEGIN
    variable TEST_END
    variable HINT1
    variable BL_BEGIN [strip_upcase $TEST_BEGIN]
    variable BL_END   [strip_upcase $TEST_END]
    set txt [get_txt]
    set forsel ""
    lassign [get_test_blocks $txt] error blocks forsel
    switch $error {
      0 { do_blocks $txt $blocks $safe $verbose $forsel}
      1 { ERR "Unpaired: $TEST_BEGIN$HINT1" }
      2 { ERR "Unpaired: $TEST_END$HINT1" }
      default {
        #other errors
      }
    }

  }

  ###################################################################
  # Insert doctest template before current line

  proc do_doctest_init {} {

    set txt [get_txt]
    if {$txt == ""} return
    set testinit "
  #% doctest

  #%
  #>

  #> doctest

"
    $txt insert "insert linestart" $testinit

  }

  ###################################################################
  # Procedures to register the plugin

  proc handle_state {} {

    if {"[get_txt]" == ""} {return 0}
    return 1

  }

}

#####################################################################
# Register plugin action

api::register doctest {

  {menu command {Doctest TCL/Doctest Safe} \
      {doctest::do_doctest 1 0}  doctest::handle_state}
  {menu command {Doctest TCL/Doctest Safe Verbose} \
      {doctest::do_doctest 1 1}  doctest::handle_state}
  {menu separator {Doctest TCL}}
  {menu command {Doctest TCL/Doctest Full} \
      {doctest::do_doctest 0 0}  doctest::handle_state}
  {menu command {Doctest TCL/Doctest Full Verbose} \
      {doctest::do_doctest 0 1}  doctest::handle_state}
  {menu separator {Doctest TCL}}
  {menu command {Doctest TCL/Doctest Init} \
      doctest::do_doctest_init  doctest::handle_state}

}

