switch -glob $tcl_platform(os) {
  *Win*   -
  CYG*    { load -lazy ./model.dll }
  Darwin  { load -lazy ./model.dylib }
  default { load -lazy ./model.so }
}

# Create model itself
set m [model m]

puts -nonewline "setmarker time: "
puts [time { $m setmarker 5 "foobar" }]

puts -nonewline "setmarker time: "
puts [time { $m setmarker 1 "barfoo" }]

puts -nonewline "setmarker time: "
puts [time { $m setmarker 11 "bubba" }]

puts -nonewline "guttercreate time: "
puts [time { $m guttercreate foo {a {-symbol a} b {-symbol b}} }]

puts -nonewline "guttercreate time: "
puts [time { $m guttercreate bar {c {-symbol c} d {-symbol d}} }]

puts -nonewline "gutterset time: "
puts [time { $m gutterset foo {a {1 2 3} b {4 5}} }]

puts -nonewline "render time: "
puts [time { set render [$m renderlinemap 1 10] }]

puts "render: "
set i 1
foreach line $render {
  puts [format "%-7d %s" $i $line]
  incr i
}

$m -delete
