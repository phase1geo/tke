switch -glob $tcl_platform(os) {
  *Win*   -
  CYG*    { load -lazy ./model.dll }
  Darwin  { load -lazy ./model.dylib }
  default { load -lazy ./model.so }
}

proc undoable {m} {

  puts -nonewline "undoable time: "
  puts -nonewline [time { set value [$m undoable] }]
  puts ", value: $value"

  puts -nonewline "redoable time: "
  puts -nonewline [time { set value [$m redoable] }]
  puts ", value: $value"

}

set m [model m]

undoable $m

puts -nonewline "insert time: "
puts [time { $m insert {1.0 1.12} "This is good" 1.0 }]

undoable $m

puts -nonewline "undo time: "
puts -nonewline [time { set value [$m undo] }]
puts ", value: $value"

undoable $m

puts -nonewline "insert time: "
puts [time { $m insert {1.0 2.4} "This is\nnice" 1.0 }]

undoable $m

puts -nonewline "delete time: "
puts [time { $m delete {2.0 2.4} "nice" 1.12 }]

undoable $m

puts -nonewline "insert item: "
puts [time { $m insert {2.0 2.3} "fun" 1.8 }]

undoable $m

puts -nonewline "replace item: "
puts [time { $m replace {1.5 2.3 1.10} {"is\nfun"} "sucks" 2.3}]

undoable $m

puts -nonewline "undo time: "
puts -nonewline [time { set value [$m undo] }]
lassign $value cmds cursor
puts ", cmds: $cmds, cursor: $cursor"

puts -nonewline "redo time: "
puts -nonewline [time { set value [$m redo] }]
puts ", value: $value"

undoable $m

undoable $m

$m -delete

