switch -glob $tcl_platform(os) {
  CYG*    { load -lazy ./model.dll }
  Darwin  { load -lazy ./model.dylib }
  default { load -lazy ./model.so }
}
  
# Add types to model
foreach type [list "bcomment" "lcomment" "double" "single" "btick" ""] {
  add_type $type 1
}
foreach type [list "curly" "escape"] {
  add_type $type 0
}

# Create model itself
set m [model]

# Add the element to the intermediate serial list
lappend items [list "bcomment" left [list 1 [list 1 2]] 1 ""]
lappend items [list "bcomment" right [list 1 [list 10 11]] 1 ""]
lappend items [list "bcomment" right [list 2 [list 10 11]] 1 ""]

lappend items [list "lcomment" left [list 3 [list 1 2]] 1 ""]
lappend items [list "lcomment" right [list 3 [list 10 11]] 1 ""]
lappend items [list "lcomment" left  [list 4 [list 2 3]] 1 ""]
lappend items [list "lcomment" right [list 4 [list 10 11]] 1 ""]

lappend items [list "escape" none [list 4 [list 1 1]] 1 ""]

lappend items [list "curly" left [list 5 [list 0 0]] 0 ""]
lappend items [list "curly" left [list 5 [list 3 3]] 0 ""]
lappend items [list "curly" right [list 5 [list 5 5]] 0 ""]
lappend items [list "curly" right [list 5 [list 10 10]] 0 ""]

# Update the model
puts [time {
$m update [list 1 0] [list 10 5] [lsort -dictionary -index 2 $items]
}]

puts -nonewline "mismatched: [$m mismatched], time: "
puts [time { $m mismatched }]

puts "serial: [$m showserial]"
puts "Tree:"
puts [$m showtree]

puts -nonewline "depth: [$m depth 1.0 curly], time: "
puts [time { $m depth 5.5 curly }]

puts -nonewline "matching pos (5.3): [$m matchindex 5.3], time: "
puts [time { $m matchindex 5.3 }]
puts "matching pos (5.10): [$m matchindex 5.10]"
puts "matching pos (5.1):  [$m matchindex 5.1]"
puts "matching pos (2.10): [$m matchindex 2.10]"

puts "5.10 escaped: [$m isescaped 5.10], 4.2 escaped: [$m isescaped 4.2], 4.1 escaped: [$m isescaped 4.1], 4.3 escaped: [$m isescaped 4.3]"

puts -nonewline "Inserting, time: "
puts [time { $m insert {5.0 5.5} }]
puts [$m showserial]

puts -nonewline "Deleting, time: "
puts [time { $m delete {5.0 5.5} }]
puts [$m showserial]

puts -nonewline "Inserting, time: "
puts [time { $m insert {5.0 6.5} }]
puts [$m showserial]

puts -nonewline "Replacing, time: "
puts [time { $m replace {5.0 6.5 5.5} }]
puts [$m showserial]

# Delete the model
$m -delete
