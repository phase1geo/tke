switch -glob $tcl_platform(os) {
  CYG*    { load -lazy ./model.dll }
  default { load -lazy ./model.so }
}
  
# Add types to model
set i 0
foreach type [list "bcomment" "lcomment" "double" "single" "btick" "" "curly"] {
  add_type $type $i
  incr i
}

# Create serial used for appending
set s [serial]

# Create model itself
set m [model]

# Add the element to the intermediate serial list
lappend items [list "bcomment" left [list 1 [list 1 2]] 1 ""]
lappend items [list "bcomment" right [list 1 [list 10 11]] 1 ""]
lappend items [list "bcomment" right [list 2 [list 10 11]] 1 ""]

$s append $items

set items [list]
lappend items [list "lcomment" left [list 3 [list 1 2]] 1 ""]
lappend items [list "lcomment" right [list 3 [list 10 11]] 1 ""]
lappend items [list "lcomment" right [list 4 [list 10 11]] 1 ""]

$s append $items

set items [list]
lappend items [list "curly" left [list 5 [list 0 0]] 0 ""]
lappend items [list "curly" left [list 5 [list 3 3]] 0 ""]
lappend items [list "curly" right [list 5 [list 5 5]] 0 ""]
lappend items [list "curly" right [list 5 [list 10 10]] 0 ""]

$s append $items

# Update the model
puts [time {
$m update [list 1 0] [list 10 5] $s
}]

puts -nonewline "mismatched: [$m mismatched], time: "
puts [time { $m mismatched }]

puts "serial: [$m showserial]"
puts "Tree:"
puts [$m showtree]

# Delete the serial
$s -delete

# Delete the model
$m -delete
