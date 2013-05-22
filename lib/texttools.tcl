namespace eval texttools {

  proc comment {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    foreach {endpos startpos} [lreverse $selected] {
      set i 0
      foreach line [split [$txt get $startpos $endpos] \n] {
        if {$i == 0} {
          $txt insert $startpos "# "
        } else {
          $txt insert "$startpos+${i}l linestart" "# "
        }
        incr i
      }
    }

  }

  proc uncomment {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    foreach {endpos startpos} [lreverse $selected] {
      set i 0
      foreach line [split [$txt get $startpos $endpos] \n] {
        if {[regexp {^(([^#]*)#\s?)} $line -> full prev]} {
          if {$i == 0} {
            set delstart [$txt index "$startpos+[string length $prev]c"]
          } else {
            set linestart [$txt index "$startpos+${i}l linestart"]
            set delstart  [$txt index "$linestart+[string length $prev]c"]
          }
          $txt delete $delstart "$delstart+[expr [string length $full] - [string length $prev]]c"
        }
        incr i
      }
    }

  }

}

