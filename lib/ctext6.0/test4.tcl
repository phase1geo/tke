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

$m -delete

