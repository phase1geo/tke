package require Thread

source parsers.tcl
source model2.tcl

if {[catch { open ../menus.tcl r } rc]} {
  puts "ERROR:  Unable to read example.tcl"
}

set contents [read $rc]
close $rc

model::create foo
puts [time {parsers::markers [thread::id] foo 1.0 $contents {} {} {} {}}]
# puts [time {parsers::markers [thread::id] foo 3.1 "a" {} {} {} {}}]
puts [time { parsers::markers [thread::id] foo 1.0 $contents {} {} {} {} }]
model::destroy foo
