package require Thread

source parsers.tcl
source model2.tcl

if {[catch { open ../menus.tcl r } rc]} {
  puts "ERROR:  Unable to read example.tcl"
}

set contents [read $rc]
close $rc

model::create foo
puts [time {parsers::markers [thread::id] foo 1.0 $contents {} {} {} {}} 1]
flush stdout
puts [time {
foreach char [split [string range $contents 1000 1300] {}] {
  puts -nonewline "Inserting $char time: "
  puts [time { parsers::markers [thread::id] foo 1000.0 $char {} {} {} {} }]
}
}]
# puts [time {parsers::markers [thread::id] foo 3.1 "a" {} {} {} {}}]
# puts [time { parsers::markers [thread::id] foo 1.0 $contents {} {} {} {} }]
model::destroy foo
