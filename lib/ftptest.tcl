set tke_dir     [file normalize [file join [pwd] ..]]
set tke_home    [file normalize [file join ~ .tke]]
set right_click 2

lappend auto_path [pwd]

package require ftp
package require tablelist
package require wmarkentry

source ftper.tcl
source utils.tcl
source tkedat.tcl

ttk::style theme use clam

wm attributes . -alpha 0.0

lassign [ftper::create_open] name fname

puts "name: $name, fname: $fname"

if {$name ne ""} {
  if {[ftper::get_file $name $fname ::contents]} {
    puts $contents
  } else {
    puts "No file downloaded"
  }
}

exit

