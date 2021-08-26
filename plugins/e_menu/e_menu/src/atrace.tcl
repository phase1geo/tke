#! /usr/bin/env tclsh
proc traceFile {mode fname excl} {puts "[string totitle $mode] \"$fname\" with $excl excluded."
set chan [open $fname]
set input [read $chan]
close $chan
set RE {^\s*(proc|method)\s+([[:alnum:]_:]+)\s.+}
set prep "puts \"|---> "
set output ""
foreach line [split $input \n] {switch $mode {"trace" {if {$output ne ""} {append output \n}
append output $line
if {[regexp $RE $line -> type title] && $title ni $excl} {append output \n $prep "$type $title" \"}}
"untrace" {if {![string match "$prep*" $line]} {if {$output ne ""} {append output \n}
append output $line}}}}
set chan [open $fname w]
puts -nonewline $chan $output
close $chan
puts Done.}
lassign $::argv mode fname
set excl [lrange $argv 2 end]
if {$::argc<2 || ![file exists $fname] || $mode ni {untrace trace}} {puts "
  The atrace.tcl sets/unsets tracing puts to/from a Tcl script.

  Synapsis:
    tclsh atrace.tcl 'mode' 'file.tcl' ?excllist?
  where:
    'mode'     - 'trace' or 'untrace'
    'file.tcl' - an existing Tcl file's name
    'excllist' - list of procs/methods untouched by atrace.tcl
  The 'file.tcl' is updated on the disk.
  Example:
    tclsh atrace.tcl apave.tcl trace ::\$w My
  "
exit}
traceFile $mode $fname $excl
exit
#by trimmer
