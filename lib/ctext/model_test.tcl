package require Thread

source model.tcl
source parsers.tcl

model::create [set txt "foo"]

if {[catch { open ../menus.tcl r } rc]} {
  puts "ERROR:  Unable to read parsers.tcl"
}

set contents [read $rc]
close $rc

lappend bracketlist $txt,config,matchChar,,curly  1
lappend bracketlist $txt,config,matchChar,,square 1
lappend bracketlist $txt,config,matchChar,,paren  1
lappend contextlist double any \" single any ' btick any `

puts [time { parsers::markers [thread::id] $txt $contents 1 $bracketlist \{ \} $contextlist }]
puts [time {
foreach char [split [string range $contents 1000 1300] {}] {
  parsers::markers [thread::id] $txt $char 1000 $bracketlist \{ \} $contextlist
}
}]
# model::debug_show $txt

# puts [time { set mismatched [model::get_mismatched $txt] }]
# puts "mismatched: $mismatched"

# Create the tree
if {0} {
model::create foo
model::debug_show foo

puts [time {model::insert foo {paren start 1.0 paren start 1.1 paren end 1.4 paren end 1.6 paren end 1.10} 0}]
model::debug_show foo

model::adjust_insert_indices foo 1.2 2.3
model::debug_show foo

model::insert foo {paren start 1.7 paren end 1.9} 0
model::debug_show foo

model::insert foo {paren start 1.8} 0
model::debug_show foo

model::insert foo {paren end 1.20 paren end 1.25} 0
model::debug_show foo
}
