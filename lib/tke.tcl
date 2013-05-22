#!wish8.5

# Name:    tke.tcl
# Author:  Trevor Williams (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Tcl/Tk editor written in Tcl/Tk
# Usage:   tke [<options>] <file>*

set tke_dir  [file dirname $argv0]
set tke_home [file join ~ .tke]

set auto_path [concat $tke_dir $auto_path]

package require Tclx
package require ctext
package require tablelist

source [file join $tke_dir utils.tcl]
source [file join $tke_dir preferences.tcl]
source [file join $tke_dir gui.tcl]
source [file join $tke_dir indent.tcl]
source [file join $tke_dir menus.tcl]
source [file join $tke_dir launcher.tcl]
source [file join $tke_dir plugins.tcl]
source [file join $tke_dir snippets.tcl]
source [file join $tke_dir bindings.tcl]
source [file join $tke_dir bgproc.tcl]
source [file join $tke_dir multicursor.tcl]
source [file join $tke_dir cliphist.tcl]
source [file join $tke_dir texttools.tcl]
source [file join $tke_dir vim.tcl]

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
      -h       { usage }
      -v       { version }
      default {
        lappend ::cl_files [lindex $argv $i]
      }
    }
    incr i
  }
  
}

######################################################################
# Handles an interrupt or terminate signal
proc handle_signal {} {

  # FIXME: Die gracefully
  
  # Kill the GUI
  destroy .
  
  # Exit the application
  exit

}

# Set signal handlers
signal trap TERM handle_signal
signal trap INT  handle_signal

# Parse the command-line options
parse_cmdline $argc $argv

# Attempt to add files or raise the existing application
if {[llength $cl_files] > 0} {
  if {![catch "send tke.tcl gui::add_files_and_raise end $cl_files" rc]} {
    destroy .
    exit
  } elseif {[regexp {X server} $rc]} {
    puts $rc
  }
} else {
  if {![catch "send tke.tcl gui::raise_window" rc]} {
    destroy .
    exit
  } elseif {[regexp {X server} $rc]} {
    puts $rc
  }
}

# Create the ~/.tke directory if it doesn't already exist
if {![file exists $tke_home]} {
  mkdir $tke_home
}

# Load the preferences
preferences::load

# Load the plugins
plugins::load

# Load the snippets
snippets::load

# Load the clipboard history
cliphist::load

# Set the tk style to clam
ttk::style theme use clam

# Create GUI
gui::create

# Populate the GUI with the command-line filelist (if specified)
if {[llength $cl_files] > 0} {
  foreach cl_file $cl_files {
    gui::add_file end [file normalize $cl_file]
  }
} else {
  gui::add_new_file end
}




