namespace eval parsers {
  
  ######################################################################
  # Allows thread code to send log messages to standard output.
  proc log {id msg} {
    
    thread::send -async $id [list ctext::log $id $msg] 
    
  }
  
  ######################################################################
  # Renders the given tag with the specified ranges.
  proc render {tid txt tag ranges} {
    
    thread::send -async $tid [list ctext::render $txt $tag $ranges]
    
  }
  
  ######################################################################
  # This is used by parsers to handle case manipulation when no case
  # change should occur.
  proc nochange {value} {
    
    return $value
    
  }
  
  ######################################################################
  # Parses the given string for keywords and names that start with a
  # given character.  Runs within a thread which calls the main application
  # thread to render the highlighting.
  proc keywords_startchars {tid txt str startrow namelist startlist pattern nocase} {
    
    array set names  $namelist
    array set starts $startlist
    array set tags   [list]
    
    set transform [expr {$nocase ? "string tolower" : "nochange"}]
    
    # Perform the parsing on a line basis
    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start $pattern $line indices]} {
        set word   [{*}$transform [string range $line {*}$indices]]
        set first  [string index $word 0]
        set endpos [expr [lindex $indices 1] + 1]
        if {[info exists names($word)]} {
          lappend tags($names($word)) $startrow.[lindex $indices 0] $startrow.$endpos
        } elseif {[info exists starts($first)]} {
          lappend tags($starts($first)) $startrow.[lindex $indices 0] $startrow.$endpos
        }
        set start $endpos
      }
      incr startrow
    }
    
    # Have the main application thread render the tag ranges
    foreach {tag ranges} [array get tags] {
      render $tid $txt $tag $ranges
    }
    
  }
  
  ######################################################################
  # Parses the given string for a single regular expression which is
  # handled as a class.  Runs within a thread which calls the main
  # application thread to render the highlighting.
  proc regexp_class {tid txt str startrow pattern tag} {
    
    set ranges [list]
    
    # Perform the parsing on a line basis
    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start $pattern $line indices]} {
        set endpos [expr [lindex $indices 1] + 1]
        lappend ranges $startrow.[lindex $indices 0] $startrow.$endpos
        set start $endpos
      }
      incr startrow
    }
    
    # Have the main application thread render the tag ranges
    render $tid $txt $tag $ranges
    
  }
  
  ######################################################################
  # Parses the given string for a single regular expression which calls
  # a handling command for further processing.  Runs within a thread which
  # calls the main application thread to render the highlighting.
  proc regexp_command {tid txt str startrow pattern cmd ins} {
    
    # Perform the parsing on a line basis
    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start $pattern $line var(0) dummy var(1) var(2) var(3) var(4) var(5) var(6) var(7) var(8) var(9)]} {
        if {![catch { {*}$cmd [list $line] [array get var] [list] $ins } retval] && ([llength $retval] == 2)} {
          foreach sub [lindex $retval 0] {
            if {([llength $sub] == 4) && ([set ret [handle_tag $win {*}$sub]] ne "")} {
              lappend tags([lindex $ret 0]) $startrow.[lindex $ret 1] $startrow.[lindex $ret 2]
            }
          }
          if {[set restart_from [lindex $retval 1]] ne ""} {
            set start $restart_from
          } else {
            set start [expr [lindex $var(0) 1] + 1]
          }
        }
      }
      incr startrow
    }
    
    # Have the main application thread render the tag ranges
    foreach {tag ranges} [array get tags] {
      render $tid $txt $tag $ranges
    }
    
  }
  
}

