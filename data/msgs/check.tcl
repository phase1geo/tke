#!tclsh8.5

set rc [open [lindex $argv 0] r]

foreach line [split [read $rc] \n] {
  if {[expr ([string length $line] - [string length [string map {{"} {}} $line]]) % 2]} {
    puts "Mismatching line: $line"
  }
}

close $rc
