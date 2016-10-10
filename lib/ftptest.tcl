set tke_dir  [file normalize [file join [pwd] ..]]
set tke_home [file normalize [file join ~ .tke]]

package require ftp
package require tablelist

source ftper.tcl
source utils.tcl

ftper::create_open

console show
