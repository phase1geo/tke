lappend auto_path ".."

package require specl

tk appname TestApp

ttk::button .b -text "Check for update" -command {
  if {[catch "specl::check_for_update" rc]} {
    puts "ERROR: $rc"
  }
}

pack .b
