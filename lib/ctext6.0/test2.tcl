load -lazy ./model.so

# Add types to model
set i 0
foreach type [list "bcomment" "lcomment" "double" "single" "btick" ""] {
  add_type $type $i
  incr i
}

# Create serial used for appending
set s [serial]

# Create model itself
set m [model]

# Add the element to the intermediate serial list
lappend items [list "bcomment" 1 [list 1 [list 1 2]] 1 ""]
lappend items [list "bcomment" 2 [list 1 [list 10 11]] 1 ""]
lappend items [list "bcomment" 2 [list 2 [list 10 11]] 1 ""]

$s append $items

# Update the model
puts [time {
$m update [list 1 0] [list 10 5] $s
}]

puts "mismatched: [$m mismatched]"
