# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:    parsers.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/18/2017
# Brief:   Contains text parsers that are used by the ctext 6.0 threaded
#          namespace.  This code is completely executed inside of a thread.
######################################################################$0

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
  # Allows thread code to send log messages to standard output.
  proc log {tid msg} {

    thread::send -async $tid [list ctext::thread_log [thread::id] $msg]

  }

  ######################################################################
  # Renders the given tag with the specified ranges.
  proc render {tid txt tag ranges restricted} {

    thread::send -async $tid [list ctext::render $txt $tag $ranges $restricted]

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
  proc keywords_startchars {tid txt str startrow wordslist startlist pattern nocase} {

    array set words  $wordslist
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
        if {[info exists words($txt,highlight,keyword,class,,$word)]} {
          lappend tags($words($txt,highlight,keyword,class,,$word)) $startrow.[lindex $indices 0] $startrow.$endpos
        } elseif {[info exists starts($txt,highlight,charstart,class,,$first)]} {
          lappend tags($starts($txt,highlight,charstart,class,,$first)) $startrow.[lindex $indices 0] $startrow.$endpos
        }
        set start $endpos
      }
      incr startrow
    }

    # Have the main application thread render the tag ranges
    foreach {tag ranges} [array get tags] {
      render $tid $txt $tag $ranges 0
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
    render $tid $txt $tag $ranges 0

  }

  ######################################################################
  # Parses the given string for a single regular expression which calls
  # a handling command for further processing.  Runs within a thread which
  # calls the main application thread to render the highlighting.
  proc regexp_command {tid txt str startrow pattern cmd ins} {

    array set tags [list]

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
          set start [expr {([lindex $retval 1] ne "") ? [lindex $retval 1] : ([lindex $var[0] 1] + 1)}]
        }
      }
      incr startrow
    }

    # Have the main application thread render the tag ranges
    foreach {tag ranges} [array get tags] {
      render $tid $txt $tag $ranges 0
    }

  }

  ######################################################################
  # Parses the given string for escape characters.  Runs within a thread
  # which calls the main application thread to render the tagging.
  proc escapes {txt str startrow ptags} {

    upvar $ptags tags

    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start "\\" $line indices]} {
        set endpos   [expr [lindex $indices 1] + 1]
        if {[lindex $ranges end] ne $startpos} {
          lappend tags [list escape none $startrow.[lindex $indices 0]]
        }
        set start $endpos
      }
      incr startrow
    }

  }

  ######################################################################
  # Tag all of the whitespace found at the beginning of each line.
  proc prewhite {tid txt str startrow} {

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
    render $tid $txt _prewhite $ranges 0

  }

  ######################################################################
  # Tag all of the comments, strings, and other contextual blocks.
  proc contexts {tid txt str startrow patterns ptags} {

    upvar $ptags tags

    foreach {tag side pattern} $patterns {
      foreach line [split $str \n] {
        set start 0
        while {[regexp -indices -start $start $pattern $line indices]} {
          set endpos [expr [lindex $indices 1] + 1]
          lappend tags [list $tag $side $startrow.[lindex $indices 0]]
          set start $endpos
        }
        incr startrow
      }
    }

  }

  ######################################################################
  # Tag all of the indentation characters for quick indentation handling.
  proc indentation {txt str startrow pattern type ptags} {

    upvar $ptags tags

    set side [expr {($type eq "indent") ? "left" : "right"}]

    # Parse the ranges
    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start $pattern $line indices]} {
        set endpos [expr [lindex $indices 1] + 1]
        lappend tags [list indent $side $startrow.[lindex $indices 0]]
        set start $endpos
      }
      incr startrow
    }

  }

  ######################################################################
  # Handles tagging brackets found within the text string.
  proc brackets {txt str startrow bracketlist ptags} {

    upvar $ptags tags

    variable REs
    variable bracket_map

    array set brackets $bracketlist

    # Parse the string
    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start $REs(brackets) $line indices]} {
        lassign $bracket_map([string index $line [lindex $indices 0]]) tag side
        set endpos [expr [lindex $indices 1] + 1]
        if {[info exists brackets($txt,config,matchChar,,$tag)]} {
          lappend tags [list $tag $side $startrow.[lindex $indices 0]]
        }
        set start $endpos
      }
      incr startrow
    }

  }

  ######################################################################
  # Parse all of the positional information in the given string.
  proc markers {tid txt insertpos str bracketlist indentpattern unindentpattern contextpatterns} {

    lassign [split $insertpos .] srow scol

    set tags   [list]
    set lines  [split $str \n]
    set endpos [join [list [expr $srow + ([llength $lines] - 1)] [expr $scol + ([string length [lindex $lines end]] - 1)]] .]

    array set patterns {
      \\     {escape  none}
      \"     {double  any}
      '      {single  any}
      `      {btick   any}
      \"\"\" {tdouble any}
      '''    {tsingle any}
      ```    {tbtick  any}
      \(     {paren   left}
      \)     {paren   right}
      \{     {curly   left}
      \}     {curly   right}
      \[     {square  left}
      \]     {square  right}
      <      {angled  left}
      >      {angled  right}
    }

    set pattern {\\|\"|'|`|\"\"\"|'''|```|\(|\)|\{|\}|\[|\]|<|>}

    # Parse the ranges
    foreach line [split $str \n] {
      set start 0
      while {[regexp -indices -start $start $pattern $line indices]} {
        set endpos [expr [lindex $indices 1] + 1]
        lappend tags [list {*}$patterns([string range $line {*}$indices]) $srow.[expr $scol + [lindex $indices 0]]]
        set start $endpos
      }
      incr startrow
      set scol 0
    }

    # Insert the positional information into the data model
    model::insert $txt $insertpos $endpos $tags

  }

}

