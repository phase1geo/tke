#!wish8.5

# Name:    tke.tcl
# Author:  Trevor Williams (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Tcl/Tk editor written in Tcl/Tk
# Usage:   tke [<options>] <file>*

set tke_dir [file dirname $argv0]

lappend auto_path $tke_dir

package require ctext
package require tablelist

source [file join $tke_dir utils.tcl]
source [file join $tke_dir gui.tcl]
source [file join $tke_dir menus.tcl]
source [file join $tke_dir launcher.tcl]
source [file join $tke_dir plugins.tcl]
source [file join $tke_dir snippets.tcl]

######################################################################
# Display the usage information to standard output and exits.
proc usage {} {

  puts "tke [<options>] <file>*"
  puts ""
  puts "Options:"
  puts "  -h   Displays usage information"
  puts "  -v   Displays version"
  
  exit

}

######################################################################
# Displays version information to standard output and exits.
proc version {} {

  puts "0.1"
  
  exit
  
}

######################################################################
# Parse the command-line options
proc parse_cmdline {argc argv} {

  set ::cl_files [list]
  
  set i 0
  while {$i < $argc} {
    switch -- [lindex $argv $i] {
      -h { usage }
      -v { version }
      default {
        lappend ::cl_files [lindex $argv $i]
      }
    }
    incr i
  }
  
}

# Parse the command-line options
parse_cmdline $argc $argv

# Load the plugins
plugins::load

# Load the launcher
launcher::load

# Load the snippets
snippets::load

# Create GUI
gui::create

# Populate the GUI with the command-line filelist (if specified)
if {[llength $cl_files] > 0} {
  foreach cl_file $cl_files {
    gui::add_file end $cl_file
  }
} else {
  gui::add_new_file end
}
