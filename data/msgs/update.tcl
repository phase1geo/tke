#!tclsh8.5

proc usage {} {
  
  puts "tclsh8.5 update.tcl -- <options>"
  puts ""
  puts "Options:"
  puts "  -h  Display this usage information"
  puts "  -a  Update all existing translations automatically"
  
  exit
  
}

set i         0
set lang_args [list]

while {$i < $argc} {
  switch -exact -- [lindex $argv $i] {
    -h { usage }
    -a { lappend lang_args -auto }
  }
  incr i
}

set langs [list]
foreach msg [glob *.msg] {
  lappend langs [file rootname $msg]
}
  

exec wish8.5 [file join .. .. lib lang.tcl] {*}$lang_args {*}$langs
