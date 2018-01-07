######################################################################
# Name:    parsers.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/18/2017
# Brief:   Contains text parsers that are used by the ctext 6.0 threaded
#          namespace.  This code is completely executed inside of a thread.
######################################################################$0

package require struct::stack

namespace eval parsers {

  array set REs {
    words    {[^\s\(\{\[\}\]\)\.\t\n\r;:=\"'\|,<>]+}
    brackets {[][()\{\}<>]}
  }
  array set bracket_map {
    \( {paren left}
    \) {paren right}
    \{ {curly left}
    \} {curly right}
    \[ {square left}
    \] {square right}
    <  {angled left}
    >  {angled right}
  }

  ######################################################################
  # Renders the given tag with the specified ranges.
  proc render {txt tag ranges clear_all} {

    thread::send -async $ctext::utils::main_tid [list ctext::render $txt $tag $ranges $clear_all]

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
  proc keywords_startchars {txt str startrow wordslist startlist pattern case_sensitive} {

    array set words  $wordslist
    array set starts $startlist
    array set tags   [list]

    set transform [expr {$case_sensitive ? "nochange" : "string tolower"}]

    # Perform the parsing on a line basis
    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start $pattern $line indices]} {
        set word   [{*}$transform [string range $line {*}$indices]]
        set first  [string index $word 0]
        set endpos [expr [lindex $indices 1] + 1]
        if {[info exists words($txt,highlight,word,class,,$word)]} {
          lappend tags($words($txt,highlight,word,class,,$word)) $startrow.[lindex $indices 0] $startrow.$endpos
        } elseif {[info exists starts($txt,highlight,charstart,class,,$first)]} {
          lappend tags($starts($txt,highlight,charstart,class,,$first)) $startrow.[lindex $indices 0] $startrow.$endpos
        }
        set start $endpos
      }
      incr startrow
    }

    # Have the main application thread render the tag ranges
    foreach {tag ranges} [array get tags] {
      render $txt $tag $ranges 0
    }

  }

  ######################################################################
  # Parses the given string for a single regular expression which is
  # handled as a class.  Runs within a thread which calls the main
  # application thread to render the highlighting.
  proc regexp_class {txt str startrow pattern tag} {

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
    render $txt $tag $ranges 0

  }

  ######################################################################
  # Parses the given string for a single regular expression which calls
  # a handling command for further processing.  Runs within a thread which
  # calls the main application thread to render the highlighting.
  proc regexp_command {txt str startrow pattern cmd ins} {

    array set tags [list]

    # Perform the parsing on a line basis
    foreach line [split $str \n] {
      set start 0
      array unset var
      while {[regexp -indices -start $start $pattern $line var(0) var(1) var(2) var(3) var(4) var(5) var(6) var(7) var(8) var(9)]} {
        if {![catch { thread::send $ctext::utils::main_tid [list {*}$cmd $txt $startrow [list $line] [array get var] $ins] } retval] && ([llength $retval] == 2)} {
          foreach sub [lindex $retval 0] {
            if {[llength $sub] == 3} {
              lappend tags(_[lindex $sub 0]) $startrow.[lindex $sub 1] $startrow.[expr [lindex $sub 2] + 1]
            }
          }
          set start [expr {([lindex $retval 1] ne "") ? [lindex $retval 1] : ([lindex $var(0) 1] + 1)}]
        } else {
          set start [expr {[lindex $var(0) 1] + 1}]
        }
      }
      incr startrow
    }

    # Have the main application thread render the tag ranges
    foreach {tag ranges} [array get tags] {
      render $txt $tag $ranges 0
    }

  }

  ######################################################################
  # Parses the given string for escape characters.  Runs within a thread
  # which calls the main application thread to render the tagging.
  proc escapes {txt str startrow ptags} {

    upvar $ptags tags

    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start {\\} $line indices]} {
        set endpos [expr [lindex $indices 1] + 1]
        lassign [lindex $tags end] t d i
        if {([lindex $i 0] == $startrow) && ([lindex $i 1 0] == ([lindex $indices 0] - 1))} {
          set tags [lreplace $tags end end]
        } else {
          lappend tags [list escape none [list $startrow $indices] 1 {}]
        }
        set start $endpos
      }
      incr startrow
    }

  }

  ######################################################################
  # Tag all of the whitespace found at the beginning of each line.
  proc prewhite {txt str startrow} {

    set ranges [list]

    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start {^[ \t]*\S} $line indices]} {
        set endpos [expr [lindex $indices 1] + 1]
        lappend ranges $startrow.[lindex $indices 0] $startrow.$endpos
        set start $endpos
      }
      incr startrow
    }

    # Have the main application thread render the tag ranges
    thread::send -async $ctext::utils::main_tid [list ctext::render_prewhite $txt $ranges]

  }

  ######################################################################
  # Tag all of the comments, strings, and other contextual blocks.
  proc contexts {txt str startrow ptags} {

    upvar $ptags tags

    set patterns [tsv::get contexts $txt]
    set lines    [split $str \n]
    set found    0

    foreach {type side pattern once ctx} $patterns {

      # If the pattern is the EOL character, just get our indices from the left side
      if {$pattern eq "\$"} {
        if {$found > 0} {
          set lrow 0
          foreach tag [lrange $tags end-[expr $found - 1] end] {
            lassign $tag type side pos dummy1 dummy2 ctx
            if {[set row [lindex $pos 0]] == $lrow} { continue }
            set col [string length [lindex $lines [expr $row - $startrow]]]
            lappend tags [list $type right [list $row [list $col $col]] 1 $ctx]
            set lrow $row
          }
        }
        continue
      }

      set srow  $startrow
      set found 0
      set trim  [expr {[string index $pattern 0] eq "^"}]
      foreach line $lines {
        set start 0
        while {[regexp -indices -start $start $pattern $line indices]} {
          set endpos [expr [lindex $indices 1] + 1]
          if {$trim} {
            set str  [string range $line {*}$indices]
            set diff [expr [string length $str] - [string length [string trimleft $str]]]
            lset indices 0 [expr [lindex $indices 0] + $diff]
          }
          lappend tags [list $type $side [list $srow $indices] 1 $ctx]
          set start $endpos
          incr found
          if {$once} {
            break
          }
        }
        incr srow
      }

    }

  }

  ######################################################################
  # Tag all of the indentation characters for quick indentation handling.
  proc indentation {txt str startrow ptags} {

    upvar $ptags tags

    # Parse the ranges
    foreach {tag side pattern ctx} [tsv::get indents $txt] {
      set srow $startrow
      foreach line [split $str \n] {
        set start 0
        while {[regexp -indices -start $start $pattern $line indices]} {
          set endpos [expr [lindex $indices 1] + 1]
          lappend tags [list $tag $side [list $srow $indices] 0 $ctx]
          set start $endpos
        }
        incr srow
      }
    }

  }

  ######################################################################
  # Handles tagging brackets found within the text string.
  proc brackets {txt str startrow ptags} {

    upvar $ptags tags

    foreach {tag side pattern ctx} [tsv::get brackets $txt] {
      set srow $startrow
      foreach line [split $str \n] {
        set start 0
        while {[regexp -indices -start $start $pattern $line indices]} {
          set endpos [expr [lindex $indices 1] + 1]
          lappend tags [list $tag $side [list $srow $indices] 0 $ctx]
          set start $endpos
        }
        incr srow
      }
    }

  }

  ######################################################################
  # Store all file markers in a model for fast processing.
  proc markers {txt str linestart lineend} {

    lassign [split $linestart .] srow scol

    set tags [list]

    # Find all marker characters in the inserted text
    escapes  $txt $str $srow tags
    contexts $txt $str $srow tags

    # If we have any escapes or contexts found in the given string, re-render the contexts
    thread::send -async $ctext::utils::main_tid [list ctext::model::render_contexts $txt $linestart $lineend $tags]

    # Add indentation and bracket markers to the tags list
    indentation $txt $str $srow tags
    brackets    $txt $str $srow tags

    # Update the model
    thread::send -async $ctext::utils::main_tid [list ctext::model::update $txt $linestart $lineend [lsort -dictionary -index 2 $tags]]

  }

  ######################################################################
  # Highlights the mismatched brackets.
  proc render_mismatched {win} {

    render $win _missing [ctext::model::get_mismatched $win] 1

  }

  ######################################################################
  # Highlights the matching character.
  proc render_match_char {win tindex} {

    # Get the matching character
    if {[ctext::model::get_match_char $win tindex]} {
      render $win _matchchar $tindex 0
    }

  }

}
