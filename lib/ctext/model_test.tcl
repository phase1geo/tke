source model.tcl

puts "HERE B"

# Create the tree
model::create foo
puts "HERE A"
model::debug_show foo

model::insert foo {paren start 1.0 paren start 1.1 paren end 1.4 paren end 1.6}

model::debug_show foo
