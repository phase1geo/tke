#!tclsh

######################################################################
#
# This untidy script checks the *.msg files for:
#  - mismatching quotes
#  - absence/presence of lines against each other
#
# Call:
#   cd data/msgs
#   tclsh ./check2.tcl
# or, if you want to get all English messages,
#   tclsh ./check2.tcl 1
#
######################################################################

set displayfile [expr $::argc>0]
set title ""
set under "\n[string repeat "=" 60]\n"
set under2 "\n[string repeat "-" 60]\n"
set etal  {}
set etal2 {}
set f1 ""
set f2 ""

# output "line" (to a list and, optionally, to stdout)
proc putsit {line {ind ""} {out 1}} {
  if {$line!="\}"} {
    if {$::find==1} {
      lappend ::etal $line
      if {$out && $::displayfile} {
        puts $ind$line
      }
    } elseif {$::find==2} {
      lappend ::etal2 $line
    }
  }
  return
}

# check if "line" is present in "ieta" list
proc compit {line ieta} {
  if {[string first "#" $line]!=0 \
  && [string first "msg" $line]!=0 && $::find>1} {
    upvar $ieta etal
    foreach let $etal {
      if {$let==$line} {return 0}
    }
    puts "$::title : $line"
    return 1
  }
  return 0
}

# 1st step of checks: for mismatching quotes
puts $under
puts "1st step - find mismatching \{\"\}"
puts $under
foreach f [glob ??.msg] {
  set rc [open $f r]
  puts -nonewline $f
  set err 0
  foreach line [split [read $rc] \n] {
    if {[expr ([string length $line] - [string length \
    [string map {\" {}} $line]]) % 2]} {
      if {!$err} {puts ""}
      puts "  - Mismatching line: $line"
      set err 1
    }
  }
  close $rc
  if {!$err} {puts "  - no mismatching \{\"\}"}
}

# 2nd step of checks: for new lines against "file found first"
set find 1
foreach f [glob ??.msg] {
  if {$find==1} {
    set f1 $f
    puts ""
    puts $under
    puts "2nd step - find new lines of all against $f1"
    puts $under
  } elseif {$find==2} {
    set f2 $f
  }
  set rc [open $f r]
  puts "FILE: $f"
  set msg 0
  set ::title "New line of $f "
  foreach line [split [read $rc] \n] {
    set line [string trim $line]
    if {$line==""} continue
    if {[string first "msg" $line]==0} {
      putsit $line
      set msg [set eng 1]
    } elseif {[string first "\}" $line]==0} {
      putsit $line
      set msg 0
    } else {
      if {$msg} {
        if {$eng} {
          putsit $line "  "
          compit $line etal
        }
        set eng [expr !$eng]
      } else {
        putsit $line
      }
    }
  }
  close $rc
  puts $under2
  incr find
}

# 3rd step of checks: for new lines of "file found first" against all
puts ""
puts $under
puts "3rd step - find new lines of $f1 against all"
puts $under
set find 1
foreach f [glob ??.msg] {
  if {$find>1} {
    puts $under2
    puts "FILE: $f"
    set ::title "New line of $f1 against $f"
    set etal2 {}
    set err [set msg 0]
    set rc [open $f r]
    set find 2 ;# to save lines in etal2 list
    foreach line [split [read $rc] \n] {
      set line [string trim $line]
      if {$line==""} continue
      if {[string first "msg" $line]==0} {
        set msg [set eng 1]
      } elseif {[string first "\}" $line]==0} {
        set msg 0
      } else {
        if {$msg} {
          if {$eng} {
            putsit $line "" 0
          }
          set eng [expr !$eng]
        }
      }
    }
    foreach line $etal {
      incr err [compit $line etal2]
    }
    close $rc
#?     if {!$err} {
#?       puts "$::title - not found"
#?     }
#?     puts ""
  }
  incr find
}
puts $under

