set tke_dir [file normalize [file join [pwd] ..]]

source startup.tcl
source utils.tcl

lassign [startup::create] type dir

puts "type: $type, dir: $dir"

destroy .
