package require Thread
package require Ttrace

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

proc find1_regexps {tpool txt str word_pattern startpos namelist nocase} {

  set jobids [list]
  set ranges [list]

  # Start a job for the words
  lappend jobids [tpool::post $tpool [format {
    proc dummy {value} { return $value }
    array set names %s
    set ranges    [list]
    set start     0
    set transform [expr {%d ? "string tolower" : "dummy"}]
    while {[regexp -indices -start $start %s %s indices]} {
      set word   [{*}$transform [string range %s {*}$indices]]
      set endpos [expr [lindex $indices 1] + 1]
      if {[info exists names($word)]} {
        lappend ranges "%s+[lindex $indices 0]c" "%s+${endpos}c"
      }
      set start $endpos
    }
    return $ranges
  } [list $namelist] $nocase [list $word_pattern] [list $str] [list $str] $startpos $startpos]]

  # Start a job for each regular expression
  foreach name $ctext::data($txt,highlight,regexps) {
    lassign $ctext::data($txt,highlight,$name) pattern re_opts
    lappend jobids [tpool::post $tpool [format {
      set ranges [list]
      set start  0
      while {[regexp -indices -start $start %s %s indices]} {
        set endpos [expr [lindex $indices 1] + 1]
        lappend ranges "%s+[lindex $indices 0]c" "%s+${endpos}c"
        set start $endpos
      }
      return $ranges
    } [list $pattern] [list $str] $startpos $startpos]]
  }

  # Wait for the jobs to complete
  while {[llength $jobids]} {
    foreach done [tpool::wait $tpool $jobids jobids] {
      lappend ranges {*}[tpool::get $tpool $done]
    }
  }

  return $ranges

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

proc run {} {

  gui::get_info {} current txt

  set pattern  $ctext::REs(words)
  set namelist [list]
  foreach item [array names ctext::data $txt,highlight,keyword,class,,*] {
    lappend namelist [lindex [split $item ,] 5] 1
  }

  set tpool [tpool::create -minworkers 5 -maxworkers 15]

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
    set ranges [find1_regexps $tpool $txt $str $pattern 1.0 $namelist 0]
  }]

  puts "1 ranges: [llength $ranges]"

  set ranges [list]
  puts [time {
    lappend ranges {*}[find2_words $txt $pattern 1.0 0]
    lappend ranges {*}[find2_regexps $txt 1.0]
  }]

  puts "2 ranges: [llength $ranges]"

  tpool::release $tpool

}
