#!tclsh8.5

foreach msg [glob *.msg] {
  
  set lang [file rootname $msg]
  
  exec wish8.5 [file join .. .. lib lang.tcl] $lang
  
}
