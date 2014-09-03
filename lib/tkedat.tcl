######################################################################
# Name:    tkedat.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    08/08/2013
# Brief:   Namespace for reading .tkedat files.
######################################################################

namespace eval tkedat {

  source [file join $::tke_dir lib ns.tcl]

  variable bcount 0

  ######################################################################
  # Counts the number of curly brackets found in the given string.
  proc bracket_count {line line_num start_col} {

    variable bcount

    puts "In bracket_count, line: $line, line_num: $line_num, start_col: $start_col"

    while {[regexp -indices -start $start_col {([\{\}])(.*)$} $line -> char]} {
      if {[string index $line [lindex $char 0]] eq "\{"} {
      	puts "Found \{ at [lindex $char 0]"
        incr bcount
      } else {
      	puts "Found \} at [lindex $char 0]"
        if {$bcount == 0} {
          return -code error "Bad tkedat format (line: $line_num, col: [lindex $char 0])"
        }
        incr bcount -1
      }
      set start_col [expr [lindex $char 0] + 1]
    }

    return $bcount

  }

  ######################################################################
  # Reads the given tkedat file, stripping/storing comments and verifying
  # that no Tcl commands are called.
  proc read {fname {include_comments 1}} {
    
    array set contents [list]
    
    if {![catch { open $fname r } rc]} {
      
      set comments [list]
      set value_ip 0
      set linenum  1
      
      foreach line [split [::read $rc] \n] {
        
        if {!$value_ip && [regexp {^\s*#(.*)$} $line -> comment]} {

          lappend comments $comment

        } elseif {!$value_ip && [regexp -indices {^\s*(\{[^\}]*\}|\S+)\s+(\{.*)$} $line -> key value]} {

          set key [string map {\{ {} \} {}} [string range $line {*}$key]]
          
          if {[bracket_count $line $linenum [lindex $value 0]] == 0} {
          	set contents($key) [string range [string trim [string range $line {*}$value]] 1 end-1]
            if {[regexp {\[.*\]} $contents($key)]} {
              unset contents($key)
            } elseif {$include_comments} {
              set contents($key,comment) $comments
            }
            set comments [list]
          } else {
          	set contents($key) [string range [string range $line {*}$value] 1 end]
            set value_ip 1
          }

        } elseif {!$value_ip && [regexp {^\s*(\{[^\}]*\}|\S+)\s+(\S+)$} $line -> key value]} {

          set key [string map {\{ {} \} {}} $key]
          set contents($key) [string trim $value]
          
          if {[regexp {\[.*\]} $contents($key)]} {
            unset contents($key)
          } elseif {$include_comments} {
            set contents($key,comment) $comments
          }
          set comments [list]

        } elseif {$value_ip} {

          if {[bracket_count $line $linenum 0] == 0} {
            append contents($key) " [string range [string trim $line] 0 end-1]"
            if {[regexp {\[.*\]} $contents($key)]} {
              unset contents($key)
            } elseif {$include_comments} {
              set contents($key,comment) $comments
            }
            set comments [list]
            set value_ip 0
          } else {
          	if {$include_comments} {
              append contents($key) "$line\n"
            } else {
              append contents($key) " [string trim $line]"
            }
          }

        }
        
        incr linenum

      }
      
      close $rc
      
    } else {
      
      return -code error [msgcat::mc "Unable to open %s for reading" $fname]
      
    }

    puts "--------------------------------------------------"
    puts "PARSED CONTENTS:"
    foreach key [lsort [array names contents]] {
      puts "  $key: $contents($key)"
    }

    return [array get contents]
    
  }
  
  ######################################################################
  # Writes the given array to the given tkedat file, adding the comments
  # back to the file.
  proc write {fname contents} {

    if {![catch { open $fname w } rc]} {

      array set content $contents
      
      foreach name [lsort [array names content]] {
        if {![regexp {,comment$} $name]} {
          if {[info exists content($name,comment)]} {
            foreach comment $content($name,comment) {
              puts $rc "# $comment"
            }
          }
          puts $rc "{$name} {$content($name)}\n"
        }
      }
      
      close $rc
      
    } else {
      
      return -code error [msgcat::mc "Unable to open %s for writing" $fname]
      
    }
    
  }
  
}
