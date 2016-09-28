set tke_dir  [file normalize [file join [pwd] ..]]
set tke_home [file normalize [file join ~ .tke]]

source startup.tcl
source utils.tcl
source sync.tcl

lassign [startup::create] type dir items

puts "type: $type, dir: $dir, items: $items"

destroy .
