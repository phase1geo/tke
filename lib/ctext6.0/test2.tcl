switch -glob $tcl_platform(os) {
  CYG*    { load -lazy ./model.dll }
  Darwin  { load -lazy ./model.dylib }
  default { load -lazy ./model.so }
}
  
# Add types to model
set i 0
foreach type [list "bcomment" "lcomment" "double" "single" "btick" "" "curly"] {
  add_type $type $i
  incr i
}

# Create model itself
set m [model]

# Add the element to the intermediate serial list
lappend items [list "bcomment" left [list 1 [list 1 2]] 1 ""]
lappend items [list "bcomment" right [list 1 [list 10 11]] 1 ""]
lappend items [list "bcomment" right [list 2 [list 10 11]] 1 ""]

lappend items [list "lcomment" left [list 3 [list 1 2]] 1 ""]
lappend items [list "lcomment" right [list 3 [list 10 11]] 1 ""]
lappend items [list "lcomment" right [list 4 [list 10 11]] 1 ""]

lappend items [list "curly" left [list 5 [list 0 0]] 0 ""]
lappend items [list "curly" left [list 5 [list 3 3]] 0 ""]
lappend items [list "curly" right [list 5 [list 5 5]] 0 ""]
lappend items [list "curly" right [list 5 [list 10 10]] 0 ""]

# Update the model
puts [time {
$m update [list 1 0] [list 10 5] $items
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

# Delete the model
$m -delete
