set tke_dir  [file normalize [file join [pwd] ..]]
set tke_home [file normalize [file join ~ .tke]]

lappend auto_path [pwd]

package require ftp
package require tablelist
package require Expect

source ftper.tcl
source utils.tcl

ttk::style theme use clam

puts "File to open: [ftper::create_open]"

exit

