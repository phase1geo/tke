#!tclsh8.5

foreach msg [glob *.msg] {
  
  set lang [file rootname $msg]
  
  exec wish85 [file join .. .. lib lang.tcl] $lang
  
}
