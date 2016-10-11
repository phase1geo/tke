set tke_dir  [file normalize [file join [pwd] ..]]
set tke_home [file normalize [file join ~ .tke]]

lappend auto_path [pwd]

package require ftp
package require tablelist
# package require Expect

source ftper.tcl
source utils.tcl

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

