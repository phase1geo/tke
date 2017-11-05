package require Thread
package require Ttrace

set tpool ""

proc dummy {value} {
  return $value
}

proc find1_words {str pattern startpos namelist nocase} {

  array set names $namelist

  set ranges    [list]
  set start     0
  set transform [expr {$nocase ? "string tolower" : "dummy"}]

  while {[regexp -indices -start $start $pattern $str indices]} {
    set word   [{*}$transform [string range $str {*}$indices]]
    set endpos [expr [lindex $indices 1] + 1]
    if {[info exists names($word)]} {
      lappend ranges "$startpos+[lindex $indices 0]c" "$startpos+${endpos}c"
    }
    set start $endpos
  }

  return $ranges

}

proc find1_regexps {tpool block txt str word_pattern startpos namelist startlist nocase ins} {

  set jobids [list]
  
  set startrow [lindex [split [.testwin.t index $startpos] .] 0]
  
  # Start a job for the words
  lappend jobids [tpool::post $tpool [format {
    proc dummy {value} { return $value }
    proc parse {tid str startrow namelist startlist pattern nocase} {
      array set names  $namelist
      array set starts $startlist
      array set tags   [list]
      set transform [expr {$nocase ? "string tolower" : "dummy"}]
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
      foreach tag [array names tags] {
        thread::send -async $tid [list add_tags $tag $tags($tag)]
      }
    }
    parse %s %s %s %s %s %s %d
  } [thread::id] [list $str] $startrow [list $namelist] [list $startlist] [list $word_pattern] $nocase]]

  # Start a job for each regular expression
  foreach name $ctext::data($txt,highlight,regexps) {
    lassign [split $name ,] dummy type lang value
    lassign $ctext::data($txt,highlight,$name) pattern re_opts
    if {$type eq "class"} {
      lappend jobids [tpool::post $tpool [format {
        proc parse {tid str startrow pattern tag} {
          set ranges [list]
          foreach line [split $str \n] {
            set start 0
            while {[regexp -indices -start $start $pattern $line indices]} {
              set endpos [expr [lindex $indices 1] + 1]
              lappend ranges $startrow.[lindex $indices 0] $startrow.$endpos
              set start $endpos
            }
            incr startrow
          }
          thread::send -async $tid [list add_tags $tag $ranges]
        }
        parse %s %s %s %s %s
      } [thread::id] [list $str] $startrow [list $pattern] $value]]
    } else {
      lappend jobids [tpool::post $tpool [format {
        proc parse {tid str startrow pattern cmd ins} {
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
          foreach tag [array names tags] {
            thread::send -async $tid [list add_tags $tag $tags($tag)]
          }
        }
        parse %s %s %s %s %s %d
      } [thread::id] [list $str] $startrow [list $pattern] [list $value] $ins]]
    }
  }
  
  # Wait for the jobs to complete
  if {$block} {
    while {[llength $jobids]} {
      tpool::wait $tpool $jobids jobids
    }
  }

}

proc find2_words {txt pattern startpos nocase} {

  set ranges    [list]
  set transform [expr {$nocase ? "string tolower" : "dummy"}]
  set i 0

  foreach res [$txt._t search -count lengths -regexp -all -- $pattern $startpos end] {
    set wordEnd [$txt._t index "$res + [lindex $lengths $i] chars"]
    set word    [{*}$transform [$txt._t get $res $wordEnd]]
    if {[info exists ctext::data($txt,highlight,keyword,class,,$word)]} {
      lappend ranges $res $wordEnd
    }
    incr i
  }

  return $ranges

}

proc find2_regexps {txt startpos} {

  set ranges [list]
  foreach name $ctext::data($txt,highlight,regexps) {
    lassign $ctext::data($txt,highlight,$name) pattern re_opts
    set i 0
    foreach res [$txt._t search -count lengths -regexp -all -- $pattern $startpos end] {
      set wordEnd [$txt._t index "$res + [lindex $lengths $i] chars"]
      lappend ranges $res $wordEnd
      incr i
    }
  }

  return $ranges

}

proc log {msg} {
  
  puts $msg
  
}

proc add_tags {tag ranges} {
  
  # puts "In add_tags, tag: $tag, [llength $ranges] ($ranges)"
  
  if {[llength $ranges] > 0} { 
    .testwin.t tag add $tag {*}$ranges
  }
  
}

proc start {} {
  
  global tpool
  global namelist
  global startlist
  
  if {$tpool eq ""} {
    set tpool [tpool::create -minworkers 5 -maxworkers 15]
  }

  # Create UI
  if {![winfo exists .testwin]} {
    toplevel .testwin
    text .testwin.t -xscrollcommand ".testwin.hb set" -yscrollcommand ".testwin.vb set"
    ttk::scrollbar .testwin.vb -orient vertical   -command ".testwin.t yview"
    ttk::scrollbar .testwin.hb -orient horizontal -command ".testwin.t xview"
    grid rowconfigure    .testwin 0 -weight 1
    grid columnconfigure .testwin 0 -weight 1
    grid .testwin.t  -row 0 -column 0 -sticky news
    grid .testwin.vb -row 0 -column 1 -sticky ns
    grid .testwin.hb -row 1 -column 0 -sticky ew
  } else {
    .testwin.t delete 1.0 end
  }
  
  gui::get_info {} current txt
  
  .testwin.t configure -background [$txt cget -background] -foreground [$txt cget -foreground]
  
  bind .testwin.t <Key> {
    if {([string compare -length 5 %K "Shift"]   == 0) || \
        ([string compare -length 7 %K "Control"] == 0) || \
        ([string compare -length 3 %K "Alt"]     == 0) || \
        ("%K" eq "??")} {
      return
    }
    after idle [list ::highlight %W 1]
  }
  bind .testwin.t <BackSpace> {
    after idle [list ::highlight %W 0]
  }
  bind .testwin.t <Delete> {
    after idle [list ::highlight %W 0]
  }
  
  bind .testwin.t <Control-v> {
    %W insert insert [clipboard get]
    ::highlight %W 1 1.0 end-1c
  }
  
  # Configure the highlighted tags
  foreach class [array names ctext::data $txt,classes,*] {
    lassign [split $class ,] d1 d2 tag
    .testwin.t tag configure $tag -background [$txt tag cget $tag -background] -foreground [$txt tag cget $tag -foreground]
  }

  # Gather the namelist
  set namelist [list]
  foreach item [array names ctext::data $txt,highlight,keyword,class,,*] {
    lappend namelist [lindex [split $item ,] 5] $ctext::data($item)
  }
  
  # Gather the startlist
  set startlist [list]
  foreach item [array names ctext::data $txt,highlight,charstart,class,,*] {
    lappend startlist [lindex [split $item ,] 5] $ctext::data($item)
  }
  
}

proc highlight {win ins {startpos "insert linestart"} {endpos "insert lineend"}} {
  
  global tpool
  global namelist
  global startlist
  
  set str      [$win get $startpos $endpos]
  set pattern  $ctext::REs(words)
  
  gui::get_info {} current txt
  
  # Clear the tags
  foreach tag [lsearch -inline -all [.testwin.t tag names] _*] {
    .testwin.t tag remove $tag $startpos $endpos
  }
  
  puts -nonewline "startpos: $startpos, endpos: $endpos, time: "
  puts [time {
  find1_regexps $tpool 1 $txt $str $pattern $startpos $namelist $startlist 0 $ins
  }]
  
}

proc run {} {

  gui::get_info {} current txt

  set pattern  $ctext::REs(words)
  set namelist [list]
  foreach item [array names ctext::data $txt,highlight,keyword,class,,*] {
    lappend namelist [lindex [split $item ,] 5] $ctext::data($item)
  }
  set startlist [list]

  puts [time {
    set str [$txt get 1.0 end-1c]
    find1_words $str $pattern 1.0 $namelist 0
  }]

  puts [time {
    find2_words $txt $pattern 1.0 0
  }]

  set ranges [list]
  puts [time {
    set str [$txt get 1.0 end-1c]
    set ranges [find1_regexps $tpool 0 $txt $str $pattern 1.0 $namelist $startlist 0 1]
  }]

  puts "1 ranges: [llength $ranges]"

  set ranges [list]
  puts [time {
    lappend ranges {*}[find2_words $txt $pattern 1.0 0]
    lappend ranges {*}[find2_regexps $txt 1.0]
  }]

  puts "2 ranges: [llength $ranges]"

}
