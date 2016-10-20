set tke_dir     [file normalize [file join [pwd] ..]]
set tke_home    [file normalize [file join ~ .tke]]

if {[tk windowingsystem] eq "aqua"} {
  set right_click 2
} else {
  set right_click 3
}

lappend auto_path [pwd]

package require ftp
package require tablelist
package require wmarkentry

source remote.tcl
source utils.tcl
source tkedat.tcl

ttk::style theme use clam

wm attributes . -alpha 0.0

lassign [remote::create open] name fnames

puts "name: $name, fnames: $fnames"

if {$name ne ""} {
  foreach fname $fnames {
    if {[remote::get_file $name $fname ::contents]} {
      puts $contents
    } else {
      puts "No file downloaded"
    }
  }
}

exit

