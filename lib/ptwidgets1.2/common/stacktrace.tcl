##########################################################################
# Useful process for debugging.
proc stacktrace {} {

  set stack "Stack trace:\n"
  for {set i 1} {$i < [info level]} {incr i} {
    set lvl [info level -$i]
    set pname [lindex $lvl 0]
    if {[namespace which -command $pname] eq ""} {
      for {set j [expr $i + 1]} {$j < [info level]} {incr j} {
        if {[namespace which -command [lindex [info level -$j] 0]] ne ""} {
          set pname "[namespace qualifiers [lindex [info level -$j] 0]]::$pname"
          break
        }
      }
    }
    append stack [string repeat " " $i]$pname
    foreach value [lrange $lvl 1 end] arg [info args $pname] {
      if {$value eq ""} {
        info default $pname $arg value
      }
      append stack " $arg='$value'"
    }
    append stack \n
  }

  return $stack

}
