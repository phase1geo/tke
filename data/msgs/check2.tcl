#!tclsh

set title ""
set under "\n[string repeat "=" 60]\n"
set find 1
set etal  {}
set etal2 {}
set f1 ""
set f2 ""

proc putsit {line {ind ""}} {
  if {$::find==1} {
    lappend ::etal $line
    puts $ind$line
  } elseif {$::find==2} {
    lappend ::etal2 $line
  }
  return
}

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

foreach f [glob ??.msg] {
  if {$find==1} {
    set f1 $f
    puts $under
    puts "2nd step - find new lines against $f1"
    puts $under
  } elseif {$find==2} {
    set f2 $f
  }
  set rc [open $f r]
  puts "FILE: $f"
  puts ""
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
  puts "-----------------------------------------------------\n"
  incr find
}

puts $under
puts "3rd step - find new lines of $f1 against $f2"
puts $under
set ::title "New line of $f1 "
set err 0
foreach line $etal {
  incr err [compit $line etal2]
}
if {!$err} {
  puts "$::title - not found"
}
puts ""

