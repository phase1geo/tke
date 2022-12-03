#! /usr/bin/env tclsh

set bundle {

//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// START
//

// Insert here your samples...
//
#  You can use // or # at 1st column to comment the samples.
#
##  You can use ## at 1st column to comment without uppercasing.
#
#  Note that comments may contain special characters "{}[]$\"
#  though "{" and "}" must be balanced.

//
// FINISH
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
}
if {$::argc} {if {[catch {set ch [open [set fname [lindex $::argv 0]]]
chan configure $ch -encoding utf-8
set bundle [read $ch]
close $ch
set show_bundle true
cd [file dirname $fname]
} e]} {puts "\nError:\n$e\n"}}
source [file join [file dirname $::argv0] "procs.tcl"]
exit
#by trimmer
