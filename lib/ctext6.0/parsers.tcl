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
  proc render {tid txt tag ranges clear_all} {

    thread::send -async $tid [list ctext::render $txt $tag $ranges $clear_all]

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
  proc contexts {txt str startrow ptags} {

    upvar $ptags tags

    set patterns [tsv::get contexts $txt]
    set lines    [split $str \n]
    set found    0

    foreach {type side pattern ctx tag} $patterns {

      # If the pattern is the EOL character, just get our indices from the left side
      if {$pattern eq "\$"} {
        if {$found > 0} {
          set lrow 0
          foreach tag [lrange $tags end-[expr $found - 1] end] {
            lassign $tag type side pos dummy1 dummy2 ctx ttag
            if {[set row [lindex $pos 0]] == $lrow} { continue }
            set col [string length [lindex $lines [expr $row - 1]]]
            lappend tags [list $type right [list $row [list $col $col]] 1 {} $ctx $ttag]
            set lrow $row
          }
        }
        continue
      }

      set srow  $startrow
      set found 0
      foreach line $lines {
        set start 0
        while {[regexp -indices -start $start $pattern $line indices]} {
          set endpos [expr [lindex $indices 1] + 1]
          lappend tags [list $type $side [list $srow $indices] 1 {} $ctx $tag]
          set start $endpos
          incr found
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
          lappend tags [list indent $side [list $srow $indices] 0 {} $ctx]
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
          lappend tags [list $tag $side [list $srow $indices] 0 {} $ctx]
          set start $endpos
        }
        incr srow
      }
    }

  }

  ######################################################################
  # Store all file markers in a model for fast processing.
  proc markers {tpool tid txt str linestart lineend} {

    lassign [split $linestart .] srow scol

    set tags [list]

    # Find all marker characters in the inserted text
    escapes  $txt $str $srow tags
    contexts $txt $str $srow tags

    # If we have any escapes or contexts found in the given string, re-render the contexts
    if {[llength $tags] || [tsv::get changed $txt]} {
      tsv::set changed $txt 0
      # render_contexts $tid $txt [tsv::get serial $txt] $linestart $lineend $tags
      tpool::post $tpool [list parsers::render_contexts $tid $txt [tsv::get serial $txt] $linestart $lineend $tags]
    }

    # Add indentation and bracket markers to the tags list
    indentation $txt $str $srow tags
    brackets    $txt $str $srow tags

    # Update the model
    if {[model::update $tid $txt $linestart $lineend [lsort -dictionary -index 2 $tags]]} {
    
      # Highlight mismatching brackets
      render $tid $txt missing [model::get_mismatched $txt] 1
      
    }

  }

  ######################################################################
  # Handles rendering any contexts that we have (i.e., strings, comments,
  # embedded language blocks, etc.)
  proc render_contexts {tid txt serial linestart lineend tags} {

    # Get the list of context tags to render
    model::get_context_tags serial $linestart $lineend tags

    # Create the context stack structure
    ::struct::stack context

    context push ""
    lassign {"" 0 0} ltype lrow lcol

    # Create the non-overlapping ranges for each of the context tags
    array set ranges {}
    foreach tag $tags {
      lassign $tag   type side index dummy1 dummy2 ctx tag
      lassign $index row cols
      if {($type ne "escape") && (($ltype ne "escape") || ($lrow != $row) || ($lcol != ([lindex $cols 0] - 1)))} {
        set current [context peek]
        if {($current eq $ctx) && (($side eq "any") || ($side eq "left"))} {
          context push $type
          lappend ranges($tag) $row.[lindex $cols 0]
        } elseif {($current eq $type) && (($side eq "any") || ($side eq "right"))} {
          context pop
          lappend ranges($tag) $row.[expr [lindex $cols 1] + 1]
        } elseif {![info exists ranges($tag)]} {
          set ranges($tag) [list]
        }
      }
      lassign [list $type $row [lindex $cols 0]] ltype lrow lcol
    }

    # Render the tags
    foreach tag [array names ranges] {
      render $tid $txt $tag $ranges($tag) 1
    }

    # Destroy the stack
    context destroy

  }

}
