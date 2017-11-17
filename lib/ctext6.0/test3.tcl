switch -glob $tcl_platform(os) {
  *Win*   -
  CYG*    { load -lazy ./model.dll }
  Darwin  { load -lazy ./model.dylib }
  default { load -lazy ./model.so }
}

proc render {m first last} {

  puts -nonewline "render time: "
  puts [time { set render [$m renderlinemap $first $last] }]

  foreach line $render {
    puts $line
  }

}

# Create model itself
set m [model m]

puts -nonewline "setmarker time: "
puts [time { $m setmarker 5 "foobar" }]

puts -nonewline "setmarker time: "
puts [time { $m setmarker 1 "barfoo" }]

puts -nonewline "setmarker time: "
puts [time { $m setmarker 11 "bubba" }]

render $m 1 10

puts -nonewline "guttercreate time: "
puts [time { $m guttercreate foo {a {-symbol a} b {-symbol b}} }]

puts -nonewline "guttercreate time: "
puts [time { $m guttercreate bar {c {-symbol c} d {-symbol d}} }]

puts -nonewline "guttercreate time: "
puts [time { $m guttercreate goo {e {-symbol e -fg red -onclick clicky -onenter entery -onleave leavey} } }]

render $m 1 10

puts -nonewline "gutterconfigure time: "
puts -nonewline [time { set value [$m gutterconfigure bar "" ""] }]
puts ", value: $value"

puts -nonewline "gutterconfigure time: "
puts -nonewline [time { set value [$m gutterconfigure bar d ""] }]
puts ", value: $value"

puts -nonewline "guttercget time: "
puts -nonewline [time { set value [$m guttercget goo e -onclick] }]
puts ", value: $value"

puts -nonewline "gutterhide time: "
puts [time { $m gutterhide bar 1 }]

render $m 1 10

puts -nonewline "gutterhide time: "
puts [time { $m gutterhide bar 0 }]

render $m 1 10

puts -nonewline "gutterset time: "
puts [time { $m gutterset foo {a {1 2 3} b {4 5}} }]

puts -nonewline "gutterset time: "
puts [time { $m gutterset goo {e {12 13 14}} }]

render $m 1 20

puts -nonewline "insert time: "
puts [time { $m insert {4.0 6.0} }]

render $m 1 20

puts -nonewline "delete time: "
puts [time { $m delete {4.0 6.0} }]

render $m 1 20

$m insert {4.0 6.0}

puts -nonewline "replace time: "
puts [time { $m replace {4.0 6.0 5.0} }]

render $m 1 20

puts -nonewline "nochange time: "
puts [time { $m insert {4.0 4.2} }]

render $m 1 60

puts -nonewline "gutterset time: "
puts [time { $m gutterset bar {c {1 3 5 7 9 17} d {2 4 6 8 10 20}} }]

render $m 1 20

puts -nonewline "gutterdestroy time: "
puts [time { $m gutterdestroy foo }]

render $m 1 20

$m -delete
