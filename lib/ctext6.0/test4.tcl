switch -glob $tcl_platform(os) {
  *Win*   -
  CYG*    { load -lazy ./model.dll }
  Darwin  { load -lazy ./model.dylib }
  default { load -lazy ./model.so }
}

set m [model m]

puts -nonewline "undoable time: "
puts -nonewline [time { set value [$m undoable] }]
puts ", value: $value"

puts -nonewline "redoable time: "
puts -nonewline [time { set value [$m redoable] }]
puts ", value: $value"

puts -nonewline "insert time: "
puts [time { $m insert 1.0 "This is good" 1.0 }]

$m -delete

