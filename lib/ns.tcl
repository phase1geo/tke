# Name:     ns.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     6/7/2014
# Version:  $Revision$
# Brief:    Contains namespace-handling function.

proc ns {name} {

  if {[namespace parent] eq "::"} {
    return "::$name"
  } else {
    return "[namespace parent]::$name"
  }
  
}