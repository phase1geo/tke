# By George Peter Staplin
# See also the README for a list of contributors
# RCS: @(#) $Id: ctext.tcl,v 1.9 2011/04/18 19:49:48 andreas_kupries Exp $

package require Tk
package provide ctext 5.0

namespace eval ctext {
  array set REs {
    words    {[^\s\(\{\[\}\]\)\.\t\n\r;:=\"'\|,<>]+}
    brackets {[][()\{\}<>]}
  }
  array set bracket_map  {\( parenL \) parenR \{ curlyL \} curlyR \[ squareL \] squareR < angledL > angledR}
  array set bracket_map2 {\( paren \) paren \{ curly \} curly \[ square \] square < angled > angled}
  array set data {}
  variable temporary {}
}

# Override the tk::TextSetCursor to add a <<CursorChanged>> event
rename ::tk::TextSetCursor ::tk::TextSetCursorOrig
proc ::tk::TextSetCursor {w pos args} {
  set ins [$w index insert]
  ::tk::TextSetCursorOrig $w $pos
  event generate $w <<CursorChanged>> -data [list $ins {*}$args]
}

proc ctext {win args} {

  if {[llength $args] & 1} {
    return -code error \
    "invalid number of arguments given to ctext (uneven number after window) : $args"
  }

  frame $win -class Ctext ;# -padx 1 -pady 1

  set tmp [text .__ctextTemp]

  set ctext::data($win,config,-fg)                     [$tmp cget -foreground]
  set ctext::data($win,config,-bg)                     [$tmp cget -background]
  set ctext::data($win,config,-font)                   [$tmp cget -font]
  set ctext::data($win,config,-relief)                 [$tmp cget -relief]
  set ctext::data($win,config,-unhighlightcolor)       [$win cget -bg]
  destroy $tmp
  set ctext::data($win,config,-xscrollcommand)         ""
  set ctext::data($win,config,-yscrollcommand)         ""
  set ctext::data($win,config,-highlightcolor)         "yellow"
  set ctext::data($win,config,-linemap)                1
  set ctext::data($win,config,-linemapfg)              $ctext::data($win,config,-fg)
  set ctext::data($win,config,-linemapbg)              $ctext::data($win,config,-bg)
  set ctext::data($win,config,-linemap_mark_command)   {}
  set ctext::data($win,config,-linemap_markable)       1
  set ctext::data($win,config,-linemap_select_fg)      black
  set ctext::data($win,config,-linemap_select_bg)      yellow
  set ctext::data($win,config,-linemap_cursor)         left_ptr
  set ctext::data($win,config,-linemap_relief)         $ctext::data($win,config,-relief)
  set ctext::data($win,config,-linemap_minwidth)       1
  set ctext::data($win,config,-linemap_type)           absolute
  set ctext::data($win,config,-highlight)              1
  set ctext::data($win,config,-warnwidth)              ""
  set ctext::data($win,config,-warnwidth_bg)           red
  set ctext::data($win,config,-casesensitive)          1
  set ctext::data($win,config,-escapes)                1
  set ctext::data($win,config,-peer)                   ""
  set ctext::data($win,config,-undo)                   0
  set ctext::data($win,config,-maxundo)                0
  set ctext::data($win,config,-autoseparators)         0
  set ctext::data($win,config,-diff_mode)              0
  set ctext::data($win,config,-diffsubbg)              "pink"
  set ctext::data($win,config,-diffaddbg)              "light green"
  set ctext::data($win,config,-folding)                0
  set ctext::data($win,config,-delimiters)             $ctext::REs(words)
  set ctext::data($win,config,-matchchar)              0
  set ctext::data($win,config,-matchchar_bg)           $ctext::data($win,config,-fg)
  set ctext::data($win,config,-matchchar_fg)           $ctext::data($win,config,-bg)
  set ctext::data($win,config,re_opts)                 ""
  set ctext::data($win,config,win)                     $win
  set ctext::data($win,config,modified)                0
  set ctext::data($win,config,lastUpdate)              0
  set ctext::data($win,config,csl_patterns)            [list]
  set ctext::data($win,config,csl_char_tags)           [list]
  set ctext::data($win,config,lc_char_tags)            [list]
  set ctext::data($win,config,csl_tags)                [list]
  set ctext::data($win,config,csl_array)               [list]
  set ctext::data($win,config,csl_tag_pair)            [list]
  set ctext::data($win,config,langs)                   [list {}]
  set ctext::data($win,config,gutters)                 [list]
  set ctext::data($win,config,undo_hist)               [list]
  set ctext::data($win,config,undo_hist_size)          0
  set ctext::data($win,config,undo_sep_last)           -1
  set ctext::data($win,config,undo_sep_next)           -1
  set ctext::data($win,config,undo_sep_size)           0
  set ctext::data($win,config,redo_hist)               [list]

  set ctext::data($win,config,ctextFlags) [list -xscrollcommand -yscrollcommand -linemap -linemapfg -linemapbg \
  -font -linemap_mark_command -highlight -warnwidth -warnwidth_bg -linemap_markable \
  -linemap_cursor -highlightcolor -folding -delimiters -matchchar -matchchar_bg -matchchar_fg \
  -linemap_select_fg -linemap_select_bg -linemap_relief -linemap_minwidth -linemap_type -casesensitive -peer \
  -undo -maxundo -autoseparators -diff_mode -diffsubbg -diffaddbg -escapes -spacing3]

  # Set args
  foreach {name value} $args {
    set ctext::data($win,config,$name) $value
  }

  foreach flag {foreground background} short {fg bg} {
    if {[info exists ctext::data($win,config,-$flag)] == 1} {
      set ctext::data($win,config,-$short) $ctext::data($win,config,-$flag)
      unset ctext::data($win,config,-$flag)
    }
  }

  # Now remove flags that will confuse text and those that need
  # modification:
  foreach arg $ctext::data($win,config,ctextFlags) {
    if {[set loc [lsearch $args $arg]] >= 0} {
      set args [lreplace $args $loc [expr {$loc + 1}]]
    }
  }

  # Initialize the starting linemap ID
  set ctext::data($win,linemap,id) 0

  text $win.l -font $ctext::data($win,config,-font) -width $ctext::data($win,config,-linemap_minwidth) -height 1 \
    -relief $ctext::data($win,config,-relief) -bd 0 -fg $ctext::data($win,config,-linemapfg) -cursor $ctext::data($win,config,-linemap_cursor) \
    -bg $ctext::data($win,config,-linemapbg) -takefocus 0 -highlightthickness 0 -wrap none
  frame $win.f -width 1 -bd 0 -relief flat -bg $ctext::data($win,config,-warnwidth_bg)

  set topWin [winfo toplevel $win]
  bindtags $win.l [list $win.l $topWin all]

  set args [concat $args [list -yscrollcommand [list ctext::event:yscroll $win $ctext::data($win,config,-yscrollcommand)]] \
                         [list -xscrollcommand [list ctext::event:xscroll $win $ctext::data($win,config,-xscrollcommand)]]]

  #escape $win, because it could have a space
  if {$ctext::data($win,config,-peer) eq ""} {
    text $win.t -font $ctext::data($win,config,-font) -bd 0 -highlightthickness 0 {*}$args
  } else {
    # TBD - We should probably verify that -peer is a ctext widget path
    $ctext::data($win,config,-peer)._t peer create $win.t -font $ctext::data($win,config,-font) -bd 0 -highlightthickness 0 {*}$args
  }

  frame $win.t.w -width 1 -bd 0 -relief flat -bg $ctext::data($win,config,-warnwidth_bg)

  if {$ctext::data($win,config,-warnwidth) ne ""} {
    place $win.t.w -x [font measure [$win.t cget -font] -displayof . [string repeat "m" $ctext::data($win,config,-warnwidth)]] -relheight 1.0
  }

  grid rowconfigure    $win 0 -weight 100
  grid columnconfigure $win 2 -weight 100
  grid $win.l -row 0 -column 0 -sticky ns
  grid $win.f -row 0 -column 1 -sticky ns
  grid $win.t -row 0 -column 2 -sticky news

  # Hide the linemap and separator if we are specified to do so
  if {!$ctext::data($win,config,-linemap) && !$ctext::data($win,config,-linemap_markable) && !$ctext::data($win,config,-folding)} {
    grid remove $win.l
    grid remove $win.f
  }

  # If -matchchar is set, create the tag
  if {$ctext::data($win,config,-matchchar)} {
    $win.t tag configure matchchar -foreground $ctext::data($win,config,-matchchar_fg) -background $ctext::data($win,config,-matchchar_bg)
  }

  bind $win.t <Configure>       [list ctext::linemapUpdate $win]
  bind $win.t <<CursorChanged>> [list ctext::linemapUpdate $win %D]
  bind $win.l <ButtonPress-1>   [list ctext::linemapToggleMark $win %y]
  bind $win.l <MouseWheel>      [list event generate $win.t <MouseWheel> -delta %D]
  bind $win.l <4>               [list event generate $win.t <4>]
  bind $win.l <5>               [list event generate $win.t <5>]
  rename $win __ctextJunk$win
  rename $win.t $win._t

  bind $win <Destroy> [list ctext::event:Destroy $win %W]
  bindtags $win.t [linsert [bindtags $win.t] 0 $win]

  interp alias {} $win {} ctext::instanceCmd $win
  interp alias {} $win.t {} $win

  ctext::modified $win 0
  ctext::buildArgParseTable $win

  return $win

}

proc ctext::event:xscroll {win clientData args} {

  variable data

  if {$clientData == ""} {
    return
  }

  uplevel \#0 $clientData $args

  lassign $args first last

  if {$first > 0} {
    set first_line [lindex [split [$win.t index @0,0] .] 0]
    set last_line  [lindex [split [$win.t index @0,[winfo height $win.t]] .] 0]
    set longest    0
    for {set i $first_line} {$i <= $last_line} {incr i} {
      if {[set len [lindex [split [$win.t index $i.end] .] 1]] > $longest} {
        set longest $len
      }
    }
    set missing [expr round( ($longest * 7) * $first )]
  } else {
    set missing 0
  }

  # Adjust the warning width line, if one was requested
  if {$data($win,config,-warnwidth) ne ""} {

    # Width is calculated by multiplying the longest line with the length of a single character
    set newx [expr ($data($win,config,-warnwidth) * 7) - $missing]

    # Move the vertical bar
    place $win.t.w -x $newx -relheight 1.0

  }

}

proc ctext::event:yscroll {win clientData args} {

  ctext::linemapUpdate $win

  if {$clientData == ""} {
    return
  }

  uplevel \#0 $clientData $args

}

proc ctext::event:Destroy {win dWin} {

  variable data

  if {![string equal $win $dWin]} {
    return
  }

  bgproc::killall ctext::*

  catch { rename $win {} }
  interp alias {} $win.t {}
  ctext::clearHighlightClasses $win
  array unset data $win,config,*

}

# This stores the arg table within the config array for each instance.
# It's used by the configure instance command.
proc ctext::buildArgParseTable win {

  variable data

  set argTable [list]

  lappend argTable any -linemap_mark_command {
    set data($win,config,-linemap_mark_command) $value
    break
  }

  lappend argTable {1 true yes} -linemap {
    set data($win,config,-linemap) 1
    catch {
      grid $win.l
      grid $win.f
    }
    ctext::linemapUpdate $win
    break
  }

  lappend argTable {0 false no} -linemap {
    set data($win,config,-linemap) 0
    if {([llength $data($win,config,gutters)] == 0) && !$data($win,config,-linemap_markable) && !$data($win,config,-folding)} {
      catch {
        grid remove $win.l
        grid remove $win.f
      }
    } else {
      ctext::linemapUpdate $win
    }
    break
  }

  lappend argTable {1 true yes} -folding {
    set data($win,config,-folding) 1
    catch {
      grid $win.l
      grid $win.f
    }
    ctext::linemapUpdate $win
    break
  }

  lappend argTable {0 false no} -folding {
    set data($win,config,-folding) 0
    if {([llength $data($win,config,gutters)] == 0) && !$data($win,config,-linemap_markable) && !$data($win,config,-linemap)} {
      catch {
        grid remove $win.l
        grid remove $win.f
      }
    } else {
      ctext::linemapUpdate $win
    }
    break
  }

  lappend argTable any -xscrollcommand {
    set cmd [list $win._t config -xscrollcommand [list ctext::event:xscroll $win $value]]
    if {[catch $cmd res]} {
      return $res
    }
    set data($win,config,-xscrollcommand) $value
    break
  }

  lappend argTable any -yscrollcommand {
    set cmd [list $win._t config -yscrollcommand [list ctext::event:yscroll $win $value]]
    if {[catch $cmd res]} {
      return $res
    }
    set data($win,config,-yscrollcommand) $value
    break
  }

  lappend argTable any -spacing3 {
    if {[catch { $win._t config -spacing3 $value } res]} {
      return $res
    }
    if {[catch { $win.l config -spacing3 $value } res]} {
      return $res
    }
  }

  lappend argTable any -linemapfg {
    if {[catch {winfo rgb $win $value} res]} {
      return -code error $res
    }
    $win.l config -fg $value
    set data($win,config,-linemapfg) $value
    break
  }

  lappend argTable any -linemapbg {
    if {[catch {winfo rgb $win $value} res]} {
      return -code error $res
    }
    $win.l config -bg $value
    set data($win,config,-linemapbg) $value
    break
  }

  lappend argTable any -linemap_relief {
    if {[catch {$win.l config -relief $value} res]} {
      return -code error $res
    }
    set data($win,config,-linemap_relief) $value
    break
  }

  lappend argTable any -font {
    if {[catch {$win.l config -font $value} res]} {
      return -code error $res
    }
    $win._t config -font $value
    set data($win,config,-font) $value
    break
  }

  lappend argTable {0 false no} -highlight {
    set data($win,config,-highlight) 0
    break
  }

  lappend argTable {1 true yes} -highlight {
    set data($win,config,-highlight) 1
    break
  }

  lappend argTable any -warnwidth {
    set data($win,config,-warnwidth) $value
    if {$value eq ""} {
      place forget $win.t.w
    } else {
      place $win.t.w -x [font measure [$win.t cget -font] -displayof . [string repeat "m" $value]] -relheight 1.0
    }
    break
  }

  lappend argTable any -warnwidth_bg {
    if {[catch {winfo rgb $win $value} res]} {
      return -code error $res
    }
    set data($win,config,-warnwidth_bg) $value
    $win.t.w configure -bg $value
    $win.f   configure -bg $value
    break
  }

  lappend argTable any -highlightcolor {
    if {[catch {winfo rgb $win $value} res]} {
      return -code error $res
    }
    set data($win,config,-highlightcolor) $value
    break
  }

  lappend argTable {0 false no} -linemap_markable {
    set data($win,config,-linemap_markable) 0
    break
  }

  lappend argTable {1 true yes} -linemap_markable {
    set data($win,config,-linemap_markable) 1
    break
  }

  lappend argTable any -linemap_select_fg {
    if {[catch {winfo rgb $win $value} res]} {
      return -code error $res
    }
    set data($win,config,-linemap_select_fg) $value
    $win.l tag configure lmark -foreground $value
    break
  }

  lappend argTable any -linemap_select_bg {
    if {[catch {winfo rgb $win $value} res]} {
      return -code error $res
    }
    set data($win,config,-linemap_select_bg) $value
    $win.l tag configure lmark -background $value
    break
  }

  lappend argTable {0 false no} -casesensitive {
    set data($win,config,-casesensitive) 0
    set data($win,config,re_opts) "-nocase"
    break
  }

  lappend argTable {1 true yes} -casesensitive {
    set data($win,config,-casesensitive) 1
    set data($win,config,re_opts) ""
    break
  }

  lappend argTable {0 false no} -escapes {
    set data($win,config,-escapes) 0
    break
  }

  lappend argTable {1 true yes} -escapes {
    set data($win,config,-escapes) 1
    break
  }

  lappend argTable {any} -linemap_minwidth {
    if {![string is integer $value]} {
      return -code error "-linemap_minwidth argument must be an integer value"
    }
    if {[$win.l cget -width] < $value} {
      $win.l configure -width $value
    }
    set data($win,config,-linemap_minwidth) $value
    break
  }

  lappend argTable {any} -linemap_type {
    if {[lsearch [list absolute relative] $value] == -1} {
      return -code error "-linemap_type argument must be either 'absolute' or 'relative'"
    }
    set data($win,config,-linemap_type) $value
    ctext::linemapUpdate $win
    break
  }

  lappend argTable {0 false no} -undo {
    set data($win,config,-undo) 0
    break
  }

  lappend argTable {1 true yes} -undo {
    set data($win,config,-undo) 1
    break
  }

  lappend argTable {any} -maxundo {
    if {![string is integer $value]} {
      return -code error "-maxundo argument must be an integer value"
    }
    set data($win,config,-maxundo) $value
    ctext::undo_manage $win
    break
  }

  lappend argTable {0 false no} -autoseparators {
    set data($win,config,-autoseparators) 0
    break
  }

  lappend argTable {1 true yes} -autoseparators {
    set data($win,config,-autoseparators) 1
    break
  }

  lappend argTable {any} -diffsubbg {
    set data($win,config,-diffsubbg) $value
    foreach tag [lsearch -inline -all -glob [$win._t tag names] diff:B:D:*] {
      $win._t tag configure $tag -background $value
    }
    break
  }

  lappend argTable {any} -diffaddbg {
    set data($win,config,-diffaddbg) $value
    foreach tag [lsearch -inline -all -glob [$win._t tag names] diff:A:D:*] {
      $win._t tag configure $tag -background $value
    }
    break
  }

  lappend argTable {any} -delimiters {
    set data($win,config,-delimiters) $value
    break
  }

  lappend argTable {0 false no} -matchchar {
    set data($win,config,-matchchar) 0
    catch { $win tag delete matchchar }
    break
  }

  lappend argTable {1 true yes} -matchchar {
    set data($win,config,-matchchar) 1
    $win tag configure matchchar -foreground $data($win,config,-matchchar_fg) -background $data($win,config,-matchchar_bg)
    break
  }

  lappend argTable {any} -matchchar_fg {
    set data($win,config,-matchchar_fg) $value
    $win tag configure matchchar -foreground $data($win,config,-matchchar_fg) -background $data($win,config,-matchchar_bg)
    break
  }

  lappend argTable {any} -matchchar_bg {
    set data($win,config,-matchchar_bg) $value
    $win tag configure matchchar -foreground $data($win,config,-matchchar_fg) -background $data($win,config,-matchchar_bg)
    break
  }

  set data($win,config,argTable) $argTable

}

proc ctext::setCommentRE {win} {

  variable data

  set patterns [list]

  foreach {tag pattern} $data($win,config,csl_patterns) {
    lappend patterns $pattern
  }

  set data($win,config,csl_re) [join $patterns |]

}

proc ctext::inCommentStringHelper {win index pattern prange} {

  if {[set curr_tag [lsearch -inline -regexp [$win tag names $index] $pattern]] ne ""} {
    if {$prange ne ""} {
      upvar 2 $prange range
      set range [$win tag prevrange $curr_tag $index+1c]
    }
    return 1
  }

  return 0

}

proc ctext::inLineComment {win index {prange ""}} {

  return [inCommentStringHelper $win $index {_lComment$} $prange]

}

proc ctext::inBlockComment {win index {prange ""}} {

  return [inCommentStringHelper $win $index {_cComment\d$} $prange]

}

proc ctext::inComment {win index {prange ""}} {

  return [inCommentStringHelper $win $index {_[cl]Comment\d?$} $prange]

}

proc ctext::inBackTick {win index {prange ""}} {

  return [inCommentStringHelper $win $index {_bString\d} $prange]

}

proc ctext::inSingleQuote {win index {prange ""}} {

  return [inCommentStringHelper $win $index {_sString\d} $prange]

}

proc ctext::inDoubleQuote {win index {prange ""}} {

  return [inCommentStringHelper $win $index {_dString\d} $prange]

}

proc ctext::inString {win index {prange ""}} {

  return [inCommentStringHelper $win $index {_[sdb]String\d} $prange]

}

proc ctext::inCommentString {win index {prange ""}} {

  return [inCommentStringHelper $win $index {_([cl]Comment\d?$|[sdb]String\d)} $prange]

}

proc ctext::highlight {win lineStart lineEnd ins} {

  variable data

  # If highlighting has been disabled, return immediately
  if {!$data($win,config,-highlight)} {
    return
  }

  # Perform the highlight in the background
  ctext::doHighlight $win $lineStart $lineEnd $ins

}

proc ctext::handleFocusIn {win} {

  variable data

  __ctextJunk$win configure -bg $data($win,config,-highlightcolor)

}

proc ctext::handleFocusOut {win} {

  variable data

  __ctextJunk$win configure -bg $data($win,config,-unhighlightcolor)

}

proc ctext::set_border_color {win color} {

  __ctextJunk$win configure -bg $color

}

# Returns 1 if the character at the given index is escaped; otherwise, returns 0.
proc ctext::isEscaped {win index} {

  return [expr {[lsearch [$win tag names $index-1c] _escape] != -1}]

}

# Debugging procedure only
proc ctext::undo_display {win} {

  variable data

  puts "Undo History (size: $data($win,config,undo_hist_size), sep_size: $data($win,config,undo_sep_size)):"

  for {set i 0} {$i < $data($win,config,undo_hist_size)} {incr i} {
    puts -nonewline "  [lindex $data($win,config,undo_hist) $i] "
    if {$data($win,config,undo_sep_next) == $i} {
      puts -nonewline " sep_next"
    }
    if {$data($win,config,undo_sep_last) == $i} {
      puts -nonewline " sep_last"
    }
    puts ""
  }

}

proc ctext::undo_separator {win} {

  variable data

  # puts "START undo_separator"
  # undo_display $win

  # If a separator is being added (and it was not already added), add it
  if {![lindex $data($win,config,undo_hist) end 4]} {

    # Set the separator
    lset data($win,config,undo_hist) end 4 -1

    # Get the last index of the undo history list
    set last_index [expr $data($win,config,undo_hist_size) - 1]

    # Add the separator
    if {$data($win,config,undo_sep_next) == -1} {
      set data($win,config,undo_sep_next) $last_index
    } else {
      lset data($win,config,undo_hist) $data($win,config,undo_sep_last) 4 [expr $last_index - $data($win,config,undo_sep_last)]
    }

    # Set the last separator index
    set data($win,config,undo_sep_last) $last_index

    # Increment the separator size
    incr data($win,config,undo_sep_size)

  }

  # If the number of separators exceeds the maximum length, shorten the undo history list
  ctext::undo_manage $win

  # puts "END undo_separator"
  # undo_display $win

}

proc ctext::undo_manage {win} {

  variable data

  # If we need to make the undo history list shorter
  if {($data($win,config,-maxundo) > 0) && ([set to_remove [expr $data($win,config,undo_sep_size) - $data($win,config,-maxundo)]] > 0)} {

    # Get the separators to remove
    set index $data($win,config,undo_sep_next)
    for {set i 1} {$i < $to_remove} {incr i} {
      incr index [lindex $data($win,config,undo_hist) $index 4]
    }

    # Set the next separator index
    set data($win,config,undo_sep_next) [expr [lindex $data($win,config,undo_hist) $index 4] - 1]

    # Reset the last separator index
    set data($win,config,undo_sep_last) [expr $data($win,config,undo_sep_last) - ($index + 1)]

    # Set the separator size
    incr data($win,config,undo_sep_size) [expr 0 - $to_remove]

    # Shorten the undo history list
    set data($win,config,undo_hist) [lreplace $data($win,config,undo_hist) 0 $index]

    # Set the undo history size
    incr data($win,config,undo_hist_size) [expr 0 - ($index + 1)]

  }

}

proc ctext::undo_insert {win insert_pos str_len cursor} {

  variable data

  if {!$data($win,config,-undo)} {
    return
  }

  set end_pos [$win index "$insert_pos+${str_len}c"]

  # Combine elements, if possible
  if {[llength $data($win,config,undo_hist)] > 0} {
    lassign [lindex $data($win,config,undo_hist) end] cmd val1 val2 hcursor sep
    if {$sep == 0} {
      if {($cmd eq "d") && ($val2 == $insert_pos)} {
        lset data($win,config,undo_hist) end 2 $end_pos
        set data($win,config,redo_hist) [list]
        return
      }
      if {$data($win,config,-autoseparators)} {
        ctext::undo_separator $win
      }
    }
  }

  # Add to the undo history
  lappend data($win,config,undo_hist) [list d $insert_pos $end_pos $cursor 0]
  incr data($win,config,undo_hist_size)

  # Clear the redo history
  set data($win,config,redo_hist) [list]

}

proc ctext::undo_delete {win start_pos end_pos} {

  variable data

  if {!$data($win,config,-undo)} {
    return
  }

  set str [$win get $start_pos $end_pos]

  # Combine elements, if possible
  if {[llength $data($win,config,undo_hist)] > 0} {
    lassign [lindex $data($win,config,undo_hist) end] cmd val1 val2 cursor sep
    if {$sep == 0} {
      if {$cmd eq "i"} {
        if {$val1 == $end_pos} {
          lset data($win,config,undo_hist) end 1 $start_pos
          lset data($win,config,undo_hist) end 2 "$str$val2"
          set data($win,config,redo_hist) [list]
          return
        } elseif {$val1 == $start_pos} {
          lset data($win,config,undo_hist) end 2 "$val2$str"
          set data($win,config,redo_hist) [list]
          return
        }
      } elseif {($cmd eq "d") && ($val2 == $end_pos)} {
        lset data($win,config,undo_hist) end 2 $start_pos
        lset data($win,config,redo_hist) [list]
        return
      }
      if {$data($win,config,-autoseparators)} {
        ctext::undo_separator $win
      }
    }
  }

  # Add to the undo history
  lappend data($win,config,undo_hist) [list i $start_pos $str [$win index insert] 0]
  incr data($win,config,undo_hist_size)

  # Clear the redo history
  set data($win,config,redo_hist) [list]

}

proc ctext::undo_get_cursor_hist {win} {

  variable data

  set cursors [list]

  if {[set index $data($win,config,undo_sep_next)] != -1} {

    set sep 0

    while {$sep != -1} {
      lassign [lindex $data($win,config,undo_hist) $index] cmd val1 val2 cursor sep
      lappend cursors $cursor
      incr index $sep
    }

  }

  return $cursors

}

proc ctext::undo {win} {

  variable data

  # puts "START undo"
  # undo_display $win

  if {[llength $data($win,config,undo_hist)] > 0} {

    set i           0
    set last_cursor 1.0
    set insert      0
    set ranges      [list]
    set do_tags     [list]

    foreach element [lreverse $data($win,config,undo_hist)] {

      lassign $element cmd val1 val2 cursor sep

      if {($i > 0) && $sep} {
        break
      }

      switch $cmd {
        i {
          $win._t insert $val1 $val2
          comments_do_tag $win $val1 "$val1+[string length val2]c" do_tags
          set val2 [$win index "$val1+[string length $val2]c"]
          lappend data($win,config,redo_hist) [list d $val1 $val2 $cursor $sep]
          set insert 1
        }
        d {
          set str [$win get $val1 $val2]
          comments_chars_deleted $win $val1 $val2 do_tags
          $win._t delete $val1 $val2
          lappend data($win,config,redo_hist) [list i $val1 $str $cursor $sep]
        }
      }

      lappend ranges [$win._t index "$val1 linestart"] [$win._t index "$val2 lineend"]

      set last_cursor $cursor

      incr i

    }

    # Perform the highlight
    $win highlight -insert $insert -dotags $do_tags {*}$ranges

    set data($win,config,undo_hist) [lreplace $data($win,config,undo_hist) end-[expr $i - 1] end]
    incr data($win,config,undo_hist_size) [expr 0 - $i]

    # Set the last sep of the undo_hist list to -1 to indicate the end of the list
    if {$data($win,config,undo_hist_size) > 0} {
      lset data($win,config,undo_hist) end 4 -1
    }

    # Update undo separator info
    set data($win,config,undo_sep_next) [expr ($data($win,config,undo_hist_size) == 0) ? -1 : $data($win,config,undo_sep_next)]
    set data($win,config,undo_sep_last) [expr $data($win,config,undo_hist_size) - 1]
    incr data($win,config,undo_sep_size) -1

    ::tk::TextSetCursor $win._t $last_cursor
    ctext::modified $win 1

  }

  # puts "END undo"
  # undo_display $win

}

proc ctext::redo {win} {

  variable data

  if {[llength $data($win,config,redo_hist)] > 0} {

    set i       0
    set insert  0
    set do_tags [list]
    set ranges  [list]

    foreach element [lreverse $data($win,config,redo_hist)] {

      lassign $element cmd val1 val2 cursor sep

      switch $cmd {
        i {
          $win._t insert $val1 $val2
          comments_do_tag $win.t $val1 "$val1+[string length val2]c" do_tags
          set val2 [$win index "$val1+[string length $val2]c"]
          lappend data($win,config,undo_hist) [list d $val1 $val2 $cursor $sep]
          if {$cursor != $val2} {
            set cursor $val2
          }
          set insert 1
        }
        d {
          set str [$win get $val1 $val2]
          comments_chars_deleted $win.t $val1 $val2 do_tags
          $win._t delete $val1 $val2
          lappend data($win,config,undo_hist) [list i $val1 $str $cursor $sep]
          if {$cursor != $val1} {
            set cursor $val1
          }
        }
      }

      lappend ranges [$win._t index "$val1 linestart"] [$win._t index "$val2 lineend"]

      incr i

      if {$sep} {
        break
      }

    }

    # Highlight the code
    $win highlight -insert $insert -dotag $do_tags {*}$ranges

    set data($win,config,redo_hist) [lreplace $data($win,config,redo_hist) end-[expr $i - 1] end]

    # Set the sep field of the last separator field to match the number of elements added to
    # the undo_hist list.
    if {$data($win,config,undo_sep_last) >= 0} {
      lset data($win,config,undo_hist) $data($win,config,undo_sep_last) 4 $i
    }

    # Update undo separator structures
    incr data($win,config,undo_hist_size) $i
    set data($win,config,undo_sep_next) [expr ($data($win,config,undo_sep_next) == -1) ? [expr $data($win,config,undo_hist_size) - 1] : $data($win,config,undo_sep_next)]
    set data($win,config,undo_sep_last) [expr $data($win,config,undo_hist_size) - 1]
    incr data($win,config,undo_sep_size)

    ::tk::TextSetCursor $win._t $cursor
    ctext::modified $win 1

  }

}

proc ctext::handleInsertAt0 {win startpos datalen} {

  if {[lindex [split $startpos .] 1] == 0} {

    set endpos  [$win index "$startpos+${datalen}c"]
    set alltags [$win tag names $endpos]
    set tags    [lsearch -inline -all -glob $alltags gutter:*]
    lappend tags {*}[lsearch -inline -all -glob $alltags lmark*]

    foreach tag $tags {
      $win tag add $tag $startpos
      $win tag remove $tag $endpos
    }

  }

}

proc ctext::instanceCmd {win cmd args} {

  variable data

  switch -glob -- $cmd {
    append      { return [ctext::command_append      $win {*}$args] }
    cget        { return [ctext::command_cget        $win {*}$args] }
    conf*       { return [ctext::command_configure   $win {*}$args] }
    copy        { return [ctext::command_copy        $win {*}$args] }
    cut         { return [ctext::command_cut         $win {*}$args] }
    delete      { return [ctext::command_delete      $win {*}$args] }
    diff        { return [ctext::command_diff        $win {*}$args] }
    edit        { return [ctext::command_edit        $win {*}$args] }
    fastdelete  { return [ctext::command_fastdelete  $win {*}$args] }
    fastinsert  { return [ctext::command_fastinsert  $win {*}$args] }
    fastreplace { return [ctext::command_fastreplace $win {*}$args] }
    gutter      { return [ctext::command_gutter      $win {*}$args] }
    highlight   { return [ctext::command_highlight   $win {*}$args] }
    insert      { return [ctext::command_insert      $win {*}$args] }
    replace     { return [ctext::command_replace     $win {*}$args] }
    paste       { return [ctext::command_paste       $win {*}$args] }
    peer        { return [ctext::command_peer        $win {*}$args] }
    tag         { return [ctext::command_tag         $win {*}$args] }
    language    { return [ctext::command_language    $win {*}$args] }
    default     { return [uplevel 1 [linsert $args 0 $win._t $cmd]] }
  }

}

proc ctext::command_append {win args} {

  variable data

  switch [llength $args] {
    1 -
    2 {
      catch { clipboard append -displayof $win [$win._t get {*}$args] }
    }
    default {
      catch { clipboard append -displayof $win [$win._t get sel.first sel.last] }
    }
  }

}

proc ctext::command_cget {win args} {

  variable data

  set arg [lindex $args 0]

  foreach flag $data($win,config,ctextFlags) {
    if {[string match ${arg}* $flag]} {
      return [set data($win,config,$flag)]
    }
  }

  return [$win._t cget $arg]

}

proc ctext::command_configure {win args} {

  variable data

  if {[llength $args] == 0} {
    set res [$win._t configure]
    foreach opt [list -xscrollcommand* -yscrollcommand* -autoseparators*] {
      set del [lsearch -glob $res $opt]
      set res [lreplace $res $del $del]
    }
    foreach flag $data($win,config,ctextFlags) {
      lappend res [list $flag [set data($win,config,$flag)]]
    }
    return $res
  }

  array set flags {}
  foreach flag $data($win,config,ctextFlags) {
    set loc [lsearch $args $flag]
    if {$loc < 0} {
      continue
    }

    if {[llength $args] <= ($loc + 1)} {
      return [list $flag [set data($win,config,$flag)]]
    }

    set flagArg [lindex $args [expr {$loc + 1}]]
    set args [lreplace $args $loc [expr {$loc + 1}]]
    set flags($flag) $flagArg
  }

  foreach {valueList flag cmd} $data($win,config,argTable) {
    if {[info exists flags($flag)]} {
      foreach valueToCheckFor $valueList {
        set value [set flags($flag)]
        if {[string equal "any" $valueToCheckFor]} $cmd \
        elseif {[string equal $valueToCheckFor [set flags($flag)]]} $cmd
      }
    }
  }

  if {[llength $args]} {
    uplevel 1 [linsert $args 0 $win._t configure]
  }

}

proc ctext::command_copy {win args} {

  variable data

  # Get the start and end indices
  if {![catch {$win.t index sel.first} start_index]} {
    set end_index [$win.t index sel.last]
  } else {
    set start_index [$win.t index "insert linestart"]
    set end_index   [$win.t index "insert+1l linestart"]
  }

  # Clear and copy the data to the clipboard
  clipboard clear  -displayof $win.t
  clipboard append -displayof $win.t [$win.t get $start_index $end_index]

}

proc ctext::command_cut {win args} {

  variable data

  # Get the start and end indices
  if {![catch {$win.t index sel.first} start_index]} {
    set end_index [$win.t index sel.last]
  } else {
    set start_index [$win.t index "insert linestart"]
    set end_index   [$win.t index "insert+1l linestart"]
  }

  # Clear and copy the data to the clipboard
  clipboard clear  -displayof $win.t
  clipboard append -displayof $win.t [$win.t get $start_index $end_index]

  # Delete the text
  $win delete $start_index $end_index

}

proc ctext::command_delete {win args} {

  variable data

  set moddata [list]
  if {[lindex $args 0] eq "-moddata"} {
    set args [lassign $args dummy moddata]
  }

  switch [llength $args] {
    1 {
      set deleteStartPos [$win._t index [lindex $args 0]]
      set deleteEndPos   [$win._t index "$deleteStartPos+1c"]
    }
    2 {
      set deleteStartPos [$win._t index [lindex $args 0]]
      set deleteEndPos   [$win._t index [lindex $args 1]]
    }
    default {
      return -code error "invalid argument(s) sent to $win delete: $args"
    }
  }

  set lineStart [$win._t index "$deleteStartPos linestart"]
  set lineEnd   [$win._t index "$deleteEndPos + 1 chars lineend"]
  set do_tags   [list]

  ctext::undo_delete            $win $deleteStartPos $deleteEndPos
  ctext::linemapCheckOnDelete   $win $deleteStartPos $deleteEndPos
  ctext::comments_chars_deleted $win $deleteStartPos $deleteEndPos do_tags

  # Delete the text
  $win._t delete $deleteStartPos $deleteEndPos

  ctext::highlightAll $win [list $lineStart $lineEnd] 0 $do_tags
  ctext::modified     $win 1 [list delete [list $lineStart $lineEnd] $moddata]

  event generate $win.t <<CursorChanged>>

}

proc ctext::command_diff {win args} {

  variable data

  set args [lassign $args subcmd]
  if {!$data($win,config,-diff_mode)} {
    return -code error "diff $subcmd called when -diff_mode is false"
  }
  switch -glob $subcmd {
    add {
      if {[llength $args] != 2} {
        return -code error "diff add takes two arguments:  startline linecount"
      }

      lassign $args tline count

      # Get the current diff:A tag
      set tag [lsearch -inline -glob [$win._t tag names $tline.0] diff:A:*]

      # Get the beginning and ending position
      lassign [$win._t tag ranges $tag] start_pos end_pos

      # Get the line number embedded in the tag
      set fline [expr [lindex [split $tag :] 3] + [$win._t count -lines $start_pos $tline.0]]

      # Replace the diff:B tag
      $win._t tag remove $tag $tline.0 $end_pos

      # Add new tags
      set pos [$win._t index "$tline.0+${count}l linestart"]
      $win._t tag add diff:A:D:$fline $tline.0 $pos
      $win._t tag add diff:A:S:$fline $pos $end_pos

      # Colorize the *D* tag
      $win._t tag configure diff:A:D:$fline -background $data($win,config,-diffaddbg)
      $win._t tag lower diff:A:D:$fline
    }
    line {
      if {[llength $args] != 2} {
        return -code error "diff line takes two arguments:  txtline type"
      }
      if {[set type_index [lsearch [list add sub] [lindex $args 1]]] == -1} {
        return -code error "diff line second argument must be add or sub"
      }
      set tag [lsearch -inline -glob [$win._t tag names [lindex $args 0].0] diff:[lindex [list B A] $type_index]:*]
      lassign [split $tag :] dummy index type line
      if {$type eq "S"} {
        incr line [$win._t count -lines [lindex [$win._t tag ranges $tag] 0] [lindex $args 0].0]
      }
      return $line
    }
    ranges {
      if {[llength $args] != 1} {
        return -code error "diff ranges takes one argument:  type"
      }
      if {[lsearch [list add sub both] [lindex $args 0]] == -1} {
        return -code error "diff ranges argument must be add, sub or both"
      }
      set ranges [list]
      if {[lsearch [list add both] [lindex $args 0]] != -1} {
        foreach tag [lsearch -inline -all -glob [$win._t tag names] diff:A:D:*] {
          lappend ranges {*}[$win._t tag ranges $tag]
        }
      }
      if {[lsearch [list sub both] [lindex $args 0]] != -1} {
        foreach tag [lsearch -inline -all -glob [$win._t tag names] diff:B:D:*] {
          lappend ranges {*}[$win._t tag ranges $tag]
        }
      }
      return [lsort -dictionary $ranges]
    }
    reset {
      foreach name [lsearch -inline -all -glob [$win._t tag names] diff:*] {
        lassign [split $name :] dummy which type
        if {($which eq "B") && ($type eq "D") && ([llength [set ranges [$win._t tag ranges $name]]] > 0)} {
          $win._t delete {*}$ranges
        }
        $win._t tag delete $name
      }
      $win._t tag add diff:A:S:1 1.0 end
      $win._t tag add diff:B:S:1 1.0 end
    }
    sub {
      if {[llength $args] != 3} {
        return -code error "diff sub takes three arguments:  startline linecount str"
      }

      lassign $args tline count str

      # Get the current diff: tags
      set tagA [lsearch -inline -glob [$win._t tag names $tline.0] diff:A:*]
      set tagB [lsearch -inline -glob [$win._t tag names $tline.0] diff:B:*]

      # Get the beginning and ending positions
      lassign [$win._t tag ranges $tagA] start_posA end_posA
      lassign [$win._t tag ranges $tagB] start_posB end_posB

      # Get the line number embedded in the tag
      set fline [expr [lindex [split $tagB :] 3] + [$win._t count -lines $start_posB $tline.0]]

      # Remove the diff: tags
      $win._t tag remove $tagA $start_posA $end_posA
      $win._t tag remove $tagB $start_posB $end_posB

      # Calculate the end position of the change
      set pos [$win._t index "$tline.0+${count}l linestart"]

      # Insert the string and highlight it
      $win._t insert $tline.0 $str
      $win highlight -insert 1 $tline.0 $pos

      # Add the tags
      $win._t tag add $tagA $start_posA [$win._t index "$end_posA+${count}l linestart"]
      $win._t tag add $tagB $start_posB $tline.0
      $win._t tag add diff:B:D:$fline $tline.0 $pos
      $win._t tag add diff:B:S:$fline $pos [$win._t index "$end_posB+${count}l linestart"]

      # Colorize the *D* tag
      $win._t tag configure diff:B:D:$fline -background $data($win,config,-diffsubbg)
      $win._t tag lower diff:B:D:$fline
    }
  }
  ctext::linemapUpdate $win

}

proc ctext::command_fastdelete {win args} {

  variable data

  set moddata   [list]
  set do_update 1
  while {[string index [lindex $args 0] 0] eq "-"} {
    switch [lindex $args 0] {
      "-moddata" { set args [lassign $args dummy moddata] }
      "-update"  { set args [lassign $args dummy do_update] }
    }
  }

  if {[llength $args] == 1} {
    set startPos [$win._t index [lindex $args 0]]
    set endPos   [$win._t index "$startPos+1c"]
    ctext::linemapCheckOnDelete $win $startPos
  } else {
    set startPos [$win._t index [lindex $args 0]]
    set endPos   [$win._t index [lindex $args 1]]
    ctext::linemapCheckOnDelete $win $startPos $endPos
  }

  ctext::undo_delete $win $startPos $endPos

  $win._t delete {*}$args

  if {$do_update} {
    ctext::modified $win 1 [list delete [list $startPos $endPos] $moddata]
    event generate $win.t <<CursorChanged>>
  }

}

proc ctext::command_fastinsert {win args} {

  variable data

  set moddata   [list]
  set do_update 1
  while {[string index [lindex $args 0] 0] eq "-"} {
    switch [lindex $args 0] {
      "-moddata" { set args [lassign $args dummy moddata] }
      "-update"  { set args [lassign $args dummy do_update] }
    }
  }

  set startPos [$win._t index [lindex $args 0]]
  set chars    [string length [lindex $args 1]]
  set endPos   [$win._t index "$startPos+${chars}c"]

  $win._t insert {*}$args

  ctext::undo_insert     $win $startPos $chars [$win._t index insert]
  ctext::handleInsertAt0 $win._t $startPos $chars

  if {$do_update} {
    ctext::modified $win 1 [list insert [list $startPos $endPos] $moddata]
    event generate $win.t <<CursorChanged>>
  }

}

proc ctext::command_fastreplace {win args} {

  variable data

  if {[llength $args] < 3} {
    return -code error "please use at least 3 arguments to $win replace"
  }

  set moddata   [list]
  set do_update 1
  while {[string index [lindex $args 0] 0] eq "-"} {
    switch [lindex $args 0] {
      "-moddata" { set args [lassign $args dummy moddata] }
      "-update"  { set args [lassign $args dummy do_update] }
    }
  }

  set startPos  [$win._t index [lindex $args 0]]
  set endPos    [$win._t index [lindex $args 1]]
  set datlen    [string length [lindex $args 2]]
  set lineStart [$win._t index "$startPos linestart"]
  set lineEnd   [$win._t index "$startPos+[expr $datlen + 1]c lineend"]

  ctext::undo_delete $win $startPos $endPos

  # Perform the text replacement
  $win._t replace {*}$args

  ctext::undo_insert $win $startPos $datlen [$win._t index insert]

  if {$do_update} {
    ctext::modified $win 1 [list delete [list $startPos $endPos] $moddata]
    ctext::modified $win 1 [list insert [list $lineStart $lineEnd] $moddata]
    event generate $win.t <<CursorChanged>>
  }

}

proc ctext::command_highlight {win args} {

  variable data

  set moddata    [list]
  set insert     0
  set dotags     ""
  set lineranges [list]

  while {[string index [lindex $args 0] 0] eq "-"} {
    switch [lindex $args 0] {
      "-moddata" { set args [lassign $args dummy moddata] }
      "-insert"  { set args [lassign $args dummy insert] }
      "-dotags"  { set args [lassign $args dummy dotags] }
      default    {
        return -code error "Unknown option specified ([lindex $args 0])"
      }
    }
  }

  foreach {start end} $args {
    lappend lineranges [$win._t index "$start linestart"] [$win._t index "$end lineend"]
  }

  ctext::highlightAll $win $lineranges $insert $dotags
  ctext::modified     $win 0 [list highlight $lineranges $moddata]

}

proc ctext::command_insert {win args} {

  variable data

  if {[llength $args] < 2} {
    return -code error "please use at least 2 arguments to $win insert"
  }

  set moddata [list]
  if {[lindex $args 0] eq "-moddata"} {
    set args [lassign $args dummy moddata]
  }

  set insertPos [$win._t index [lindex $args 0]]
  set nextChar  [$win._t get $insertPos]
  if {[lindex $args 0] eq "end"} {
    set lineStart [$win._t index "$insertPos-1c linestart"]
  } else {
    set lineStart [$win._t index "$insertPos linestart"]
  }

  # Gather the data
  set dat ""
  foreach {chars taglist} [lrange $args 1 end] {
    append dat $chars
  }

  # Add the embedded language tag to the arguments if taglists are present
  if {([llength $args] >= 3) && ([set lang [get_lang $win $insertPos]] ne "")} {
    set tag_index 2
    foreach {chars taglist} [lrange $args 1 end] {
      lappend taglist _Lang:$lang
      lset args $tag_index $taglist
      incr tag_index 2
    }
  }

  set datlen [string length $dat]
  set cursor [$win._t index insert]

  $win._t insert {*}$args

  ctext::undo_insert $win $insertPos $datlen $cursor
  ctext::handleInsertAt0 $win._t $insertPos $datlen

  set lineEnd [$win._t index "${insertPos}+${datlen}c lineend"]
  set lines   [$win._t count -lines $lineStart $lineEnd]
  set do_tags [list]

  ctext::comments_do_tag $win $insertPos "$insertPos+${datlen}c" do_tags
  ctext::highlightAll    $win [list $lineStart $lineEnd] 1 $do_tags
  ctext::modified        $win 1 [list insert [list $lineStart $lineEnd] $moddata]

  event generate $win.t <<CursorChanged>>

}

proc ctext::command_replace {win args} {

  variable data

  if {[llength $args] < 3} {
    return -code error "please use at least 3 arguments to $win replace"
  }

  set moddata [list]
  if {[lindex $args 0] eq "-moddata"} {
    set args [lassign $args dummy moddata]
  }

  set startPos    [$win._t index [lindex $args 0]]
  set endPos      [$win._t index [lindex $args 1]]
  set dat         ""
  foreach {chars taglist} [lrange $args 2 end] {
    append dat $chars
  }
  set datlen      [string length $dat]
  set cursor      [$win._t index insert]
  set deleteChars [$win._t count -chars $startPos $endPos]
  set deleteLines [$win._t count -lines $startPos $endPos]
  set do_tags     [list]

  ctext::undo_delete            $win $startPos $endPos
  ctext::comments_chars_deleted $win $startPos $endPos do_tags

  # Perform the text replacement
  $win._t replace {*}$args

  ctext::undo_insert $win $startPos $datlen $cursor

  set lineStart   [$win._t index "$startPos linestart"]
  set lineEnd     [$win._t index "$startPos+[expr $datlen + 1]c lineend"]
  set insertLines [$win._t count -lines $lineStart $lineEnd]

  if {[llength $do_tags] == 0} {
    ctext::comments_do_tag $win $startPos "$startPos+${datlen}c" do_tags
  }

  ctext::highlightAll $win [list $lineStart $lineEnd] 1 $do_tags
  ctext::modified     $win 1 [list delete [list $startPos $endPos] $moddata]
  ctext::modified     $win 1 [list insert [list $lineStart $lineEnd] $moddata]

  event generate $win.t <<CursorChanged>>

}

proc ctext::command_paste {win args} {

  variable data

  set moddata [list]
  if {[lindex $args 0] eq "-moddata"} {
    set args [lassign $args dummy moddata]
  }

  set insertPos [$win._t index insert]
  set datalen   [string length [clipboard get]]

  ctext::undo_insert $win $insertPos $datalen [$win._t index insert]

  tk_textPaste $win

  ctext::handleInsertAt0 $win._t $insertPos $datalen
  ctext::modified $win 1 [list insert [list $insertPos [$win._t index "$insertPos+${datalen}c"]] $moddata]
  event generate $win.t <<CursorChanged>>

}

proc ctext::command_peer {win args} {

  variable data

  switch [lindex $args 0] {
    names {
      set names [list]
      foreach name [$win._t peer names] {
        lappend names [winfo parent $name]
      }
      return $names
    }
    default {
      return -code error "unknown peer subcommand: [lindex $args 0]"
    }
  }

}

# We need to guarantee that embedded language tags are always listed as lowest
# priority, so if someone calls the lower tag subcommand, we need to make sure
# that it won't be placed lower than an embedded language tag.
proc ctext::command_tag {win args} {

  switch [lindex $args 0] {
    lower {
      set args [lassign $args subcmd tag]
      if {($tag ne "") && ([string range $tag 0 5] eq "_Lang=")} {
        $win._t tag lower $tag {*}$args
      } elseif {[string range $tag 0 5] eq "_Lang:"} {
        if {[set lowest [lindex [lsearch -inline -all -glob [$win._t tag names] _Lang=*] end]] ne ""} {
          $win._t tag raise $tag $lowest
        } else {
          $win._t tag lower $tag {*}$args
        }
      } else {
        set lowest [lindex [lsearch -inline -all -glob [$win._t tag names] _Lang:*] end]
        if {($lowest ne "") && (([llength $args] == 0) || ($lowest eq [lindex $args 0]))} {
          $win._t tag raise $tag $lowest
        } else {
          $win._t tag lower $tag {*}$args
        }
      }
      return
    }
    raise {
      set args [lassign $args subcmd tag]
      if {($tag ne "") && ([string range $tag 0 5] ne "_Lang:")} {
        $win._t tag raise $tag {*}$args
      }
      return
    }
    nextrange -
    prevrange {
      set args [lassign $args subcmd tag]
      if {($tag eq "_indent") || ($tag eq "_unindent") || ($tag eq "_reindent") || ($tag eq "_reindentStart")} {
        lassign [$win._t tag $subcmd ${tag}0 {*}$args] s0 e0
        lassign [$win._t tag $subcmd ${tag}1 {*}$args] s1 e1
        if {$s0 eq ""} {
          if {$s1 eq ""} {
            return ""
          } else {
            return [list $s1 $e1]
          }
        } else {
          if {$s1 eq ""} {
            return [list $s0 $e0]
          } elseif {$subcmd eq "nextrange"} {
            if {[$win._t compare $s0 < $s1]} {
              return [list $s0 $e0]
            } else {
              return [list $s1 $e1]
            }
          } else {
            if {[$win._t compare $s0 > $s1]} {
              return [list $s0 $e0]
            } else {
              return [list $s1 $e1]
            }
          }
        }
      } else {
        return [$win._t tag $subcmd $tag {*}$args]
      }
    }
    default {
      return [$win._t tag {*}$args]
    }
  }

}

proc ctext::command_edit {win args} {

  variable data

  switch [lindex $args 0] {
    modified {
      switch [llength $args] {
        1 {
          return $data($win,config,modified)
        }
        2 {
          set value [lindex $args 1]
          set data($win,config,modified) $value
        }
        default {
          return -code error "invalid arg(s) to $win edit modified: $args"
        }
      }
    }
    undo {
      ctext::undo $win
    }
    redo {
      ctext::redo $win
    }
    undoable {
      return [expr $data($win,config,undo_hist_size) > 0]
    }
    redoable {
      return [expr [llength $data($win,config,redo_hist)] > 0]
    }
    separator {
      if {[llength $data($win,config,undo_hist)] > 0} {
        ctext::undo_separator $win
      }
    }
    reset {
      set data($win,config,undo_hist)      [list]
      set data($win,config,undo_hist_size) 0
      set data($win,config,undo_sep_next)  -1
      set data($win,config,undo_sep_last)  -1
      set data($win,config,undo_sep_size)  0
      set data($win,config,redo_hist)      [list]
      set data($win,config,modified)       false
    }
    cursorhist {
      return [ctext::undo_get_cursor_hist $win]
    }
    default {
      return [uplevel 1 [linsert $args 0 $win._t $cmd]]
    }
  }

}

proc ctext::command_gutter {win args} {

  variable data

  set args [lassign $args subcmd]
  switch -glob $subcmd {
    create {
      set value_list  [lassign $args gutter_name]
      set gutter_tags [list]
      foreach {name opts} $value_list {
        array set sym_opts $opts
        set sym        [expr {[info exists sym_opts(-symbol)] ? $sym_opts(-symbol) : ""}]
        set gutter_tag "gutter:$gutter_name:$name:$sym"
        if {[info exists sym_opts(-bg)]} {
          $win.l tag configure $gutter_tag -background $sym_opts(-bg)
        }
        if {[info exists sym_opts(-fg)]} {
          $win.l tag configure $gutter_tag -foreground $sym_opts(-fg)
        }
        if {[info exists sym_opts(-onenter)]} {
          $win.l tag bind $gutter_tag <Enter> [list ctext::execute_gutter_cmd $win %y $sym_opts(-onenter)]
        }
        if {[info exists sym_opts(-onleave)]} {
          $win.l tag bind $gutter_tag <Leave> [list ctext::execute_gutter_cmd $win %y $sym_opts(-onleave)]
        }
        if {[info exists sym_opts(-onclick)]} {
          $win.l tag bind $gutter_tag <Button-1> [list ctext::execute_gutter_cmd $win %y $sym_opts(-onclick)]
        }
        if {[info exists sym_opts(-onshiftclick)]} {
          $win.l tag bind $gutter_tag <Shift-Button-1> [list ctext::execute_gutter_cmd $win %y $sym_opts(-onshiftclick)]
        }
        if {[info exists sym_opts(-oncontrolclick)]} {
          $win.l tag bind $gutter_tag <Control-Button-1> [list ctext::execute_gutter_cmd $win %y $sym_opts(-oncontrolclick)]
        }
        lappend gutter_tags $gutter_tag
        array unset sym_opts
      }
      lappend data($win,config,gutters) [list $gutter_name $gutter_tags]
      ctext::linemapUpdate $win
    }
    destroy {
      set gutter_name    [lindex $args 0]
      if {[set index [lsearch -index 0 $data($win,config,gutters) $gutter_name]] != -1} {
        $win._t tag delete {*}[lindex $data($win,config,gutters) $index 1]
        set data($win,config,gutters) [lreplace $data($win,config,gutters) $index $index]
        ctext::linemapUpdate $win
      }
    }
    del* {
      lassign $args gutter_name sym_list
      set update_needed 0
      if {[set gutter_index [lsearch -index 0 $data($win,config,gutters) $gutter_name]] == -1} {
        return -code error "Unable to find gutter name ($gutter_name)"
      }
      foreach symname $sym_list {
        set gutters [lindex $data($win,config,gutters) $gutter_index 1]
        if {[set index [lsearch -glob $gutters "gutter:$gutter_name:$symname:*"]] != -1} {
          $win._t tag delete [lindex $gutters $index]
          set gutters [lreplace $gutters $index $index]
          lset data($win,config,gutters) $gutter_index 1 $gutters
          set update_needed 1
        }
      }
      if {$update_needed} {
        ctext::linemapUpdate $win
      }
    }
    set {
      set args [lassign $args gutter_name]
      set update_needed 0
      if {[set gutter_index [lsearch -index 0 $data($win,config,gutters) $gutter_name]] != -1} {
        foreach {name line_nums} $args {
          if {[set gutter_tag [lsearch -inline -glob [lindex $data($win,config,gutters) $gutter_index 1] gutter:$gutter_name:$name:*]] ne ""} {
            foreach line_num $line_nums {
              if {[set curr_tag [lsearch -inline -glob [$win._t tag names $line_num.0] gutter:$gutter_name:*]] ne ""} {
                if {$curr_tag ne $gutter_tag} {
                  $win._t tag delete $curr_tag
                  $win._t tag add $gutter_tag $line_num.0
                  set update_needed 1
                }
              } else {
                $win._t tag add $gutter_tag $line_num.0
                set update_needed 1
              }
            }
          }
        }
      }
      if {$update_needed} {
        ctext::linemapUpdate $win
      }
    }
    get {
      if {[llength $args] == 1} {
        set gutter_name [lindex $args 0]
        set symbols     [list]
        if {[set gutter_index [lsearch -index 0 $data($win,config,gutters) $gutter_name]] != -1} {
          foreach gutter_tag [lindex $data($win,config,gutters) $gutter_index 1] {
            set lines [list]
            foreach {first last} [$win._t tag ranges $gutter_tag] {
              lappend lines [lindex [split $first .] 0]
            }
            lappend symbols [lindex [split $gutter_tag :] 2] $lines
          }
        }
        return $symbols
      } elseif {[llength $args] == 2} {
        set gutter_name [lindex $args 0]
        if {[string is integer [lindex $args 1]]} {
          set line_num [lindex $args 1]
          if {[set tag [lsearch -inline -glob [$win._t tag names $line_num.0] gutter:$gutter_name:*]] ne ""} {
            return [lindex [split $tag :] 2]
          } else {
            return ""
          }
        } else {
          set lines [list]
          if {[set tag [lsearch -inline -glob [$win._t tag names] gutter:$gutter_name:[lindex $args 1]:*]] ne ""} {
            foreach {first last} [$win._t tag ranges $tag] {
              lappend lines [lindex [split $first .] 0]
            }
          }
          return $lines
        }
      }
    }
    clear {
      set last [lassign $args gutter_name first]
      if {[set gutter_index [lsearch -index 0 $data($win,config,gutters) $gutter_name]] != -1} {
        if {$last eq ""} {
          foreach gutter_tag [lindex $data($win,config,gutters) $gutter_index 1] {
            $win._t tag remove $gutter_tag $first.0
          }
        } else {
          foreach gutter_tag [lindex $data($win,config,gutters) $gutter_index 1] {
            $win._t tag remove $gutter_tag $first.0 [$win._t index $last.0+1c]
          }
        }
        ctext::linemapUpdate $win
      }
    }
    cget {
      lassign $args gutter_name sym_name opt
      if {[set index [lsearch -exact -index 0 $data($win,config,gutters) $gutter_name]] == -1} {
        return -code error "Unable to find gutter name ($gutter_name)"
      }
      if {[set gutter_tag [lsearch -inline -glob [lindex $data($win,config,gutters) $index 1] "gutter:$gutter_name:$sym_name:*"]] == -1} {
        return -code error "Unknown symbol ($sym_name) specified"
      }
      switch $opt {
        -symbol         { return [lindex [split $gutter_tag :] 3] }
        -bg             { return [$win.l tag cget $gutter_tag -background] }
        -fg             { return [$win.l tag cget $gutter_tag -foreground] }
        -onenter        { return [lrange [$win.l tag bind $gutter_tag <Enter>] 0 end-1] }
        -onleave        { return [lrange [$win.l tag bind $gutter_tag <Leave>] 0 end-1] }
        -onclick        { return [lrange [$win.l tag bind $gutter_tag <Button-1>] 0 end-1] }
        -onshiftclick   { return [lrange [$win.l tag bind $gutter_tag <Shift-Button-1>] 0 end-1] }
        -oncontrolclick { return [lrange [$win.l tag bind $gutter_tag <Control-Button-1>] 0 end-1] }
        default         {
          return -code error "Unknown gutter option ($opt) specified"
        }
      }
    }
    conf* {
      set args [lassign $args gutter_name]
      if {[set index [lsearch -exact -index 0 $data($win,config,gutters) $gutter_name]] == -1} {
        return -code error "Unable to find gutter name ($gutter_name)"
      }
      if {[llength $args] < 2} {
        if {[llength $args] == 0} {
          set match_tag "gutter:$gutter_name:*"
        } else {
          set match_tag "gutter:$gutter_name:[lindex $args 0]:*"
        }
        foreach gutter_tag [lsearch -inline -all -glob [lindex $data($win,config,gutters) $index 1] $match_tag] {
          lassign [split $gutter_tag :] dummy1 dummy2 symname sym
          set symopts [list]
          if {$sym ne ""} {
            lappend symopts -symbol $sym
          }
          if {[set bg [$win.l tag cget $gutter_tag -background]] ne ""} {
            lappend symopts -bg $bg
          }
          if {[set fg [$win.l tag cget $gutter_tag -foreground]] ne ""} {
            lappend symopts -fg $fg
          }
          if {[set cmd [lrange [$win.l tag bind $gutter_tag <Enter>] 0 end-1]] ne ""} {
            lappend symopts -onenter $cmd
          }
          if {[set cmd [lrange [$win.l tag bind $gutter_tag <Leave>] 0 end-1]] ne ""} {
            lappend symopts -onleave $cmd
          }
          if {[set cmd [lrange [$win.l tag bind $gutter_tag <Button-1>] 0 end-1]] ne ""} {
            lappend symopts -onclick $cmd
          }
          if {[set cmd [lrange [$win.l tag bind $gutter_tag <Shift-Button-1>] 0 end-1]] ne ""} {
            lappend symopts -onshiftclick $cmd
          }
          if {[set cmd [lrange [$win.l tag bind $gutter_tag <Control-Button-1>] 0 end-1]] ne ""} {
            lappend symopts -oncontrolclick $cmd
          }
          lappend gutters $symname $symopts
        }
        return $gutters
      } else {
        set args          [lassign $args symname]
        set update_needed 0
        if {[set gutter_tag [lsearch -inline -glob [lindex $data($win,config,gutters) $index 1] "gutter:$gutter_name:$symname:*"]] == -1} {
          return -code error "Unable to find gutter symbol name ($symname)"
        }
        foreach {opt value} $args {
          switch -glob $opt {
            -sym* {
              set ranges [$win._t tag ranges $gutter_tag]
              set opts   [$win._t tag configure $gutter_tag]
              $win._t tag delete $gutter_tag
              set gutter_tag "gutter:$gutter_name:$symname:$value"
              $win._t tag configure $gutter_tag {*}$opts
              $win._t tag add       $gutter_tag {*}$ranges
              set update_needed 1
            }
            -bg {
              $win.l tag configure $gutter_tag -background $value
            }
            -fg {
              $win.l tag configure $gutter_tag -foreground $value
            }
            -onenter {
              $win.l tag bind $gutter_tag <Enter> [list ctext::execute_gutter_cmd $win %y $value]
            }
            -onleave {
              $win.l tag bind $gutter_tag <Leave> [list ctext::execute_gutter_cmd $win %y $value]
            }
            -onclick {
              $win.l tag bind $gutter_tag <Button-1> [list ctext::execute_gutter_cmd $win %y $value]
            }
            -onshiftclick {
              $win.l tag bind $gutter_tag <Shift-Button-1> [list ctext::execute_gutter_cmd $win %y $value]
            }
            -oncontrolclick {
              $win.l tag bind $gutter_tag <Control-Button-1> [list ctext::execute_gutter_cmd $win %y $value]
            }
            default {
              return -code error "Unknown gutter option ($opt) specified"
            }
          }
        }
        if {$update_needed} {
          ctext::linemapUpdate $win
        }
      }
    }
    names {
      set names [list]
      foreach gutter $data($win,config,gutters) {
        lappend names [lindex $gutter 0]
      }
      return $names
    }
  }

}

proc ctext::execute_gutter_cmd {win y cmd} {

  # Get the line of the text widget
  set line [lindex [split [$win.t index @0,$y] .] 0]

  # Execute the command
  uplevel #0 [list {*}$cmd $win $line]

}

proc ctext::getAutoMatchChars {win lang} {

  variable data

  set chars [list]

  foreach name [array names data $win,config,matchChar,$lang,*] {
    lappend chars [lindex [split $name ,] 4]
  }

  return $chars

}

proc ctext::setAutoMatchChars {win lang matchChars} {

  variable data

  # Clear the matchChars
  catch { array unset data $win,config,matchChar,$lang,* }

  # Set the matchChars
  foreach matchChar $matchChars {
    set data($win,config,matchChar,$lang,$matchChar) 1
  }

}

proc ctext::matchBracket {win} {

  variable data

  # Remove the match cursor
  catch { $win tag remove matchchar 1.0 end }

  # If we are in block cursor mode, use the previous character
  if {![$win cget -blockcursor] && [$win compare insert != "insert linestart"]} {
    set pos "insert-1c"
  } else {
    set pos insert
  }

  # If the current character is escaped, ignore the character
  if {[isEscaped $win $pos]} {
    return
  }

  # Get the current language
  set lang [ctext::get_lang $win $pos]

  switch -- [$win get $pos] {
    "\}" { ctext::matchPair  $win $lang $pos curlyL }
    "\{" { ctext::matchPair  $win $lang $pos curlyR }
    "\]" { ctext::matchPair  $win $lang $pos squareL }
    "\[" { ctext::matchPair  $win $lang $pos squareR }
    "\)" { ctext::matchPair  $win $lang $pos parenL }
    "\(" { ctext::matchPair  $win $lang $pos parenR }
    "\>" { ctext::matchPair  $win $lang $pos angledL }
    "\<" { ctext::matchPair  $win $lang $pos angledR }
    "\"" { ctext::matchQuote $win $lang $pos dString double }
    "'"  { ctext::matchQuote $win $lang $pos sString single }
    "`"  { ctext::matchQuote $win $lang $pos bString btick }
  }

}

######################################################################
# Returns the index of the bracket type previous to the given index.
proc ctext::get_prev_bracket {win stype {index insert}} {

  lassign [$win tag prevrange _$stype $index] first last

  if {$last eq ""} {
    return ""
  } elseif {[$win compare $last < $index]} {
    return [$win index "$last-1c"]
  } else {
    return [$win index "$index-1c"]
  }

}

######################################################################
# Returns the index of the bracket type after the given index.
proc ctext::get_next_bracket {win stype {index insert}} {

  lassign [$win tag prevrange _$stype "$index+1c"] first last

  if {($last ne "") && [$win compare "$index+1c" < $last]} {
    return [$win index "$index+1c"]
  } else {
    lassign [$win tag nextrange _$stype "$index+1c"] first last
    return $first
  }

}

######################################################################
# Returns the index of the matching bracket type where 'type' is the
# type of bracket to find.  For example, if the current bracket is
# a left square bracket, call this procedure as:
#   ctext::get_match_bracket $txt squareR
proc ctext::get_match_bracket {win stype {index insert}} {

  set count 1

  if {[string index $stype end] eq "R"} {

    set otype [string range $stype 0 end-1]L

    lassign [$win tag nextrange _$stype "$index+1c"] sfirst slast
    lassign [$win tag prevrange _$otype $index]      ofirst olast
    set ofirst "$index+1c"

    if {($olast eq "") || [$win compare $olast < $index]} {
      lassign [$win tag nextrange _$otype $index] dummy olast
    }

    while {($olast ne "") && ($slast ne "")} {
      if {[$win compare $slast < $olast]} {
        if {[incr count -[$win count -chars $sfirst $slast]] <= 0} {
          return "$slast-[expr 1 - $count]c"
        }
        lassign [$win tag nextrange _$stype "$slast+1c"] sfirst slast
      } else {
        incr count [$win count -chars $ofirst $olast]
        lassign [$win tag nextrange _$otype "$olast+1c"] ofirst olast
      }
    }

    while {$slast ne ""} {
      if {[incr count -[$win count -chars $sfirst $slast]] <= 0} {
        return "$slast-[expr 1 - $count]c"
      }
      lassign [$win tag nextrange _$stype "$slast+1c"] sfirst slast
    }

  } else {

    set otype [string range $stype 0 end-1]R

    lassign [$win tag prevrange _$stype $index] sfirst slast
    lassign [$win tag prevrange _$otype $index] ofirst olast

    if {($olast ne "") && [$win compare $olast >= $index]} {
      set olast $index
    }

    while {($ofirst ne "") && ($sfirst ne "")} {
      if {[$win compare $sfirst > $ofirst]} {
        if {[incr count -[$win count -chars $sfirst $slast]] <= 0} {
          return "$sfirst+[expr 0 - $count]c"
        }
        lassign [$win tag prevrange _$stype $sfirst] sfirst slast
      } else {
        incr count [$win count -chars $ofirst $olast]
        lassign [$win tag prevrange _$otype $ofirst] ofirst olast
      }
    }

    while {$sfirst ne ""} {
      if {[incr count -[$win count -chars $sfirst $slast]] <= 0} {
        return "$sfirst+[expr 0 - $count]c"
      }
      lassign [$win tag prevrange _$stype $sfirst] sfirst slast
    }

  }

  return ""

}

proc ctext::matchPair {win lang pos type} {

  variable data

  if {![info exists data($win,config,matchChar,$lang,[string range $type 0 end-1])] || \
       [inCommentString $win $pos]} {
    return
  }

  if {[set pos [get_match_bracket $win $type [$win index $pos]]] ne ""} {
    $win tag add matchchar $pos
  }

}

proc ctext::matchQuote {win lang pos tag type} {

  variable data

  if {![info exists data($win,config,matchChar,$lang,$type)]} {
    return
  }

  # Get the actual tag to check for
  set tag [lsearch -inline [$win tag names $pos] _$tag*]

  lassign [$win tag nextrange $tag $pos] first last

  if {$first eq [$win index $pos]} {
    if {[$win compare $last != end]} {
      $win tag add matchchar "$last-1c"
    }
  } else {
    lassign [$win tag prevrange $tag $pos] first last
    if {$first ne ""} {
      $win tag add matchchar $first
    }
  }

}

proc ctext::get_lang {win index} {

  return [lindex [split [lindex [$win tag names $index] 0] =] 1]

}

proc ctext::clearCommentStringPatterns {win} {

  variable data

  set data($win,config,csl_patterns)  [list]
  set data($win,config,csl_char_tags) [list]
  set data($win,config,lc_char_tags)  [list]
  set data($win,config,csl_tags)      [list]
  set data($win,config,csl_array)     [list]
  set data($win,config,csl_tag_pair)  [list]

}

proc ctext::setBlockCommentPatterns {win lang patterns {color "khaki"}} {

  variable data

  set start_patterns [list]
  set end_patterns   [list]

  foreach pattern $patterns {
    lappend start_patterns [lindex $pattern 0]
    lappend end_patterns   [lindex $pattern 1]
  }

  if {[llength $patterns] > 0} {
    lappend data($win,config,csl_patterns) _cCommentStart:$lang [join $start_patterns |]
    lappend data($win,config,csl_patterns) _cCommentEnd:$lang   [join $end_patterns   |]
  }

  array set tags [list _cCommentStart:${lang}0 1 _cCommentStart:${lang}1 1 _cCommentEnd:${lang}0 1 _cCommentEnd:${lang}1 1 _cComment0 1 _cComment1 1]

  if {[llength $patterns] > 0} {
    $win tag configure _cComment0 -foreground $color
    $win tag configure _cComment1 -foreground $color
    lappend data($win,config,csl_char_tags) _cCommentStart:$lang _cCommentEnd:$lang
    lappend data($win,config,csl_tags)      _cComment0 _cComment1
    lappend data($win,config,csl_array)     {*}[array get tags]
    lappend data($win,config,csl_tag_pair)  _cCommentStart:$lang _cComment
  } else {
    catch { $win tag delete {*}[array names tags] }
  }

  setCommentRE $win

}

proc ctext::setLineCommentPatterns {win lang patterns {color "khaki"}} {

  variable data

  if {[llength $patterns] > 0} {
    lappend data($win,config,csl_patterns) _lCommentStart:$lang [join $patterns |]
  }

  array set tags [list _lCommentStart:${lang}0 1 _lCommentStart:${lang}1 1 _lComment 1]

  if {[llength $patterns] > 0} {
    $win tag configure _lComment -foreground $color
    lappend data($win,config,lc_char_tags) _lCommentStart:$lang
    lappend data($win,config,csl_tags)     _lComment
    lappend data($win,config,csl_array)    {*}[array get tags]
  } else {
    catch { $win tag delete {*}[array names tags] }
  }

  setCommentRE $win

}

proc ctext::setStringPatterns {win lang patterns {color "green"}} {

  variable data

  foreach pattern $patterns {
    switch $pattern {
      \"      { lappend data($win,config,csl_patterns) "_dQuote:$lang" $pattern }
      `       { lappend data($win,config,csl_patterns) "_bQuote:$lang" $pattern }
      default { lappend data($win,config,csl_patterns) "_sQuote:$lang" $pattern }
    }
  }

  array set tags [list \
    _sQuote:${lang}0 1 _sQuote:${lang}1 1 \
    _dQuote:${lang}0 1 _dQuote:${lang}1 1 \
    _bQuote:${lang}0 1 _bQuote:${lang}1 1 \
    _sString0 1 _sString1 1 \
    _dString0 1 _dString1 1 \
    _bString0 1 _bString1 1 \
  ]

  if {[llength $patterns] > 0} {
    foreach tag [list _sString0 _sString1 _dString0 _dString1 _bString0 _bString1] {
      $win tag configure $tag -foreground $color
    }
    lappend data($win,config,csl_char_tags) _sQuote:$lang _dQuote:$lang _bQuote:$lang
    lappend data($win,config,csl_tags)      _sString0 _sString1 _dString0 _dString1 _bString0 _bString1
    lappend data($win,config,csl_array)     {*}[array get tags]
    lappend data($win,config,csl_tag_pair)  _sQuote:$lang _sString _dQuote:$lang _dString _bQuote:$lang _bString
  } else {
    catch { $win tag delete {*}[array names tags] }
  }

  setCommentRE $win

}

proc ctext::setEmbedLangPattern {win lang start_pattern end_pattern {color ""}} {

  variable data

  lappend data($win,config,csl_patterns) _LangStart:$lang $start_pattern _LangEnd:$lang $end_pattern
  lappend data($win,config,langs) $lang

  if {$color ne ""} {
    $win tag configure _Lang:$lang
    $win tag lower     _Lang:$lang
    $win tag configure _Lang=$lang -background $color
    $win tag lower     _Lang=$lang
  }

  lappend data($win,config,csl_char_tags) _LangStart:$lang _LangEnd:$lang
  lappend data($win,config,csl_tags)      _Lang:$lang
  lappend data($win,config,csl_array)     _LangStart:${lang}0 1 _LangStart:${lang}1 1 _LangEnd:${lang}0 1 _LangEnd:${lang}1 1 _Lang:$lang 1
  lappend data($win,config,csl_tag_pair)  _LangStart:$lang _Lang=$lang

  setCommentRE $win

}

proc ctext::highlightAll {win lineranges ins {do_tag ""}} {

  variable data

  array set csl_array $data($win,config,csl_array)

  foreach tag [$win._t tag names] {
    if {([string index $tag 0] eq "_") && ![info exists csl_array($tag)]} {
      $win._t tag remove $tag {*}$lineranges
    }
  }

  # Group the ranges to remove as much regular expression text searching as possible
  set ranges    [list]
  set laststart [lindex $lineranges 0]
  set lastend   [lindex $lineranges 1]
  foreach {linestart lineend} [lrange $lineranges 2 end] {
    if {[$win count -lines $lastend $linestart] > 10} {
      lappend ranges $laststart $lastend
      set laststart $linestart
    }
    set lastend $lineend
  }
  lappend ranges $laststart $lastend

  foreach {linestart lineend} $ranges {
    ctext::escapes $win $linestart $lineend
  }
  set all [ctext::comments $win $ranges $do_tag]
  ctext::updateLangBackgrounds $win

  if {$all} {
    foreach tag [$win._t tag names] {
      if {([string index $tag 0] eq "_") && ($tag ne "_escape") && ![info exists csl_array($tag)]} {
        $win._t tag remove $tag [lindex $lineranges 1] end
      }
    }
    ctext::brackets    $win [lindex $lineranges 0] end
    ctext::indentation $win [lindex $lineranges 0] end
    ctext::highlight   $win [lindex $lineranges 0] end $ins
  } else {
    foreach {linestart lineend} $ranges {
      ctext::brackets    $win $linestart $lineend
      ctext::indentation $win $linestart $lineend
      ctext::highlight   $win $linestart $lineend $ins
    }
  }

}

proc ctext::get_tag_in_range {win tag start end} {

  set indices [list]

  while {1} {
    lassign [$win tag nextrange $tag $start] tag_start tag_end
    if {($tag_start ne "") && [$win compare $tag_start < $end]} {
      lappend indices $tag_start $tag_end
    } else {
      break
    }
    set start $tag_end
  }

  return $indices

}

proc ctext::comments_chars_deleted {win start end pdo_tags} {

  variable data

  upvar $pdo_tags do_tags

  foreach {tag dummy} $data($win,config,csl_array) {
    lassign [$win tag nextrange $tag $start] tag_start tag_end
    if {($tag_start ne "") && [$win compare $tag_start < $end]} {
      lappend do_tags $tag
      return
    }
  }

}

proc ctext::comments_do_tag {win start end pdo_tags} {

  upvar $pdo_tags do_tags

  if {($do_tags eq "") && [inLineComment $win $start] && ([string first \n [$win get $start $end]] != -1)} {
    lappend do_tags "stuff"
  }

}

proc ctext::comments {win ranges do_tags} {

  variable data

  array set tag_changed [list]

  foreach do_tag $do_tags {
    set tag_changed($do_tag) 1
  }

  # First, tag all string/comment patterns found between start and end
  foreach {tag pattern} $data($win,config,csl_patterns) {
    foreach {start end} $ranges {
      array set indices {0 {} 1 {}}
      set i 0
      foreach index [$win search -all -count lengths -regexp {*}$data($win,config,re_opts) -- $pattern $start $end] {
        if {![isEscaped $win $index]} {
          set end_index [$win index "$index+[lindex $lengths $i]c"]
          if {([string index $pattern 0] eq "^") && ([string index $tag 1] ne "L")} {
            set match [$win get $index $end_index]
            set diff  [expr [string length $match] - [string length [string trimleft $match]]]
            lappend indices([expr $i & 1]) [$win index "$index+${diff}c"] $end_index
          } else {
            lappend indices([expr $i & 1]) $index $end_index
          }
        }
        incr i
      }
      foreach j {0 1} {
        if {$indices($j) ne [ctext::get_tag_in_range $win $tag$j $start $end]} {
          $win tag remove $tag$j $start $end
          catch { $win tag add $tag$j {*}$indices($j) }
          set tag_changed($tag) 1
        }
      }
    }
  }

  # If we didn't find any comment/string characters that changed, no need to continue.
  if {[array size tag_changed] == 0} { return 0 }

  # Initialize tags
  foreach tag $data($win,config,csl_tags) {
    set tags($tag) [list]
  }
  set char_tags [list]

  # Gather the list of comment ranges in the char_tags list
  foreach i {0 1} {
    foreach char_tag $data($win,config,lc_char_tags) {
      set lang [lindex [split $char_tag :] 1]
      foreach {char_start char_end} [$win tag ranges $char_tag$i] {
        set lineend [$win index "$char_start lineend"]
        lappend char_tags [list $char_start $char_end _lCommentStart:$lang] [list $lineend "$lineend+1c" _lCommentEnd:$lang]
      }
    }
    foreach char_tag $data($win,config,csl_char_tags) {
      foreach {char_start char_end} [$win tag ranges $char_tag$i] {
        lappend char_tags [list $char_start $char_end $char_tag]
      }
    }
  }

  # Sort the char tags
  set char_tags [lsort -dictionary -index 0 $char_tags]

  # Create the tag lists
  set curr_lang       ""
  set curr_lang_start ""
  set curr_char_tag   ""
  set rb              0
  array set tag_pairs $data($win,config,csl_tag_pair)
  foreach char_info $char_tags {
    lassign $char_info char_start char_end char_tag
    if {($curr_char_tag eq "") || [string match "_*End:$curr_lang" $curr_char_tag] || ($char_tag eq "_LangEnd:$curr_lang")} {
      if {[string range $char_tag 0 5] eq "_LangS"} {
        set curr_lang       [lindex [split $char_tag :] 1]
        set curr_lang_start $char_start
        set curr_char_tag   ""
      } elseif {$char_tag eq "_LangEnd:$curr_lang"} {
        if {[info exists tag_pairs($curr_char_tag)]} {
          lappend tags($tag_pairs($curr_char_tag)$rb) $curr_char_start $char_start
          set rb [expr $rb ^ 1]
        }
        if {$curr_lang_start ne ""} {
          lappend tags(_Lang:$curr_lang) $curr_lang_start $char_end
        }
        set curr_lang       ""
        set curr_lang_start ""
        set curr_char_tag   ""
      } elseif {[string match "*:$curr_lang" $char_tag]} {
        set curr_char_tag   $char_tag
        set curr_char_start $char_start
      }
    } elseif {$curr_char_tag eq "_lCommentStart:$curr_lang"} {
      if {$char_tag eq "_lCommentEnd:$curr_lang"} {
        lappend tags(_lComment) $curr_char_start $char_end
        set curr_char_tag ""
      }
    } elseif {$curr_char_tag eq "_cCommentStart:$curr_lang"} {
      if {$char_tag eq "_cCommentEnd:$curr_lang"} {
        lappend tags(_cComment$rb) $curr_char_start $char_end
        set curr_char_tag ""
        set rb [expr $rb ^ 1]
      }
    } elseif {$curr_char_tag eq "_dQuote:$curr_lang"} {
      if {$char_tag eq "_dQuote:$curr_lang"} {
        lappend tags(_dString$rb) $curr_char_start $char_end
        set curr_char_tag ""
        set rb [expr $rb ^ 1]
      }
    } elseif {$curr_char_tag eq "_sQuote:$curr_lang"} {
      if {$char_tag eq "_sQuote:$curr_lang"} {
        lappend tags(_sString$rb) $curr_char_start $char_end
        set curr_char_tag ""
        set rb [expr $rb ^ 1]
      }
    } elseif {$curr_char_tag eq "_bQuote:$curr_lang"} {
      if {$char_tag eq "_bQuote:$curr_lang"} {
        lappend tags(_bString$rb) $curr_char_start $char_end
        set curr_char_tag ""
        set rb [expr $rb ^ 1]
      }
    }
  }
  if {[info exists tag_pairs($curr_char_tag)]} {
    lappend tags($tag_pairs($curr_char_tag)$rb) $curr_char_start end
  }
  if {$curr_lang ne ""} {
    lappend tags(_Lang:$curr_lang) $curr_lang_start end
  }

  # Delete old, add new and re-raise tags
  foreach tag [array names tags] {
    $win tag remove $tag 1.0 end
    if {[llength $tags($tag)] > 0} {
      $win tag add   $tag {*}$tags($tag)
      $win tag raise $tag
    }
  }

  # Indicate the the string/comment status may have changed for anyone interested
  event generate $win.t <<StringCommentChanged>>

  return [expr {[llength [array names tag_changed _Lang*:*]] > 0}]

}

proc ctext::updateLangBackgrounds {win} {

  variable data

  foreach tag [lsearch -inline -all -glob $data($win,config,csl_tags) _Lang:*] {
    set indices [list]
    foreach {start end} [$win tag ranges $tag] {
      lappend indices "$start+1l linestart" "$end linestart"
    }
    if {[llength $indices] > 0} {
      $win tag add [string map {: =} $tag] {*}$indices
    }
  }

}

proc ctext::setIndentation {twin lang indentations type} {

  variable data

  if {[llength $indentations] > 0} {
    set data($twin,config,indentation,$lang,$type) [join $indentations |]
  } else {
    catch { unset data($twin,config,indentation,$lang,$type) }
  }

}

proc ctext::escapes {twin start end} {

  variable data

  if {$data($twin,config,-escapes)} {
    foreach res [$twin search -all -- "\\" $start $end] {
      if {[lsearch [$twin tag names $res-1c] _escape] == -1} {
        $twin tag add _escape $res
      }
    }
  }

}

proc ctext::brackets {twin start end} {

  variable data
  variable REs
  variable bracket_map
  variable bracket_map2

  # Handle special character matching
  foreach res [$twin search -regexp -all -- $REs(brackets) $start $end] {
    if {![inCommentString $twin $res] && \
        ![isEscaped $twin $res] && \
        [info exists data($twin,config,matchChar,[get_lang $twin $res],$bracket_map2([set char [$twin get $res]]))]} {
      $twin tag add _$bracket_map($char) $res
    }
  }

}

proc ctext::indentation {twin start end} {

  variable data

  # Add prewhite tags
  set i 0
  foreach res [$twin search -regexp -all -count lengths -- {^[ \t]*\S} $start $end] {
    $twin tag add _prewhite $res "$res+[lindex $lengths $i]c"
    incr i
  }

  # Add indentation
  foreach key [array names data $twin,config,indentation,*,*] {
    set elems [split $key ,]
    set lang  [lindex $elems 3]
    set type  [lindex $elems 4]
    set i     0
    array set indices {0 {} 1 {}}
    foreach res [$twin search -regexp -all -count lengths -- $data($key) $start $end] {
      if {![inCommentString $twin $res] && ![isEscaped $twin $res] && ([get_lang $twin $res] eq $lang)} {
        lappend indices([expr $i & 1]) $res "$res+[lindex $lengths $i]c"
      }
      incr i
    }
    foreach i {0 1} {
      catch { $twin tag add _$type$i {*}$indices($i) }
    }
  }

}

proc ctext::add_font_opt {win class modifiers popts} {

  variable data

  upvar $popts opts

  if {[llength $modifiers] > 0} {

    array set font_opts [font configure [$win cget -font]]
    array set line_opts [list]
    array set tag_opts  [list]

    set lsize       ""
    set click       0
    set superscript 0
    set subscript   0
    set name_list   [list 0 0 0 0 0 0]

    foreach modifier $modifiers {
      switch $modifier {
        "bold"        { set font_opts(-weight)    "bold";   lset name_list 0 1 }
        "italics"     { set font_opts(-slant)     "italic"; lset name_list 1 1 }
        "underline"   { set font_opts(-underline) 1;        lset name_list 2 1 }
        "overstrike"  { set tag_opts(-overstrike) 1;        lset name_list 3 1 }
        "h6"          { set font_opts(-size) [expr $font_opts(-size) + 1]; set lsize "6" }
        "h5"          { set font_opts(-size) [expr $font_opts(-size) + 2]; set lsize "5" }
        "h4"          { set font_opts(-size) [expr $font_opts(-size) + 3]; set lsize "4" }
        "h3"          { set font_opts(-size) [expr $font_opts(-size) + 4]; set lsize "3" }
        "h2"          { set font_opts(-size) [expr $font_opts(-size) + 5]; set lsize "2" }
        "h1"          { set font_opts(-size) [expr $font_opts(-size) + 6]; set lsize "1" }
        "click"       { set click 1 }
        "superscript" {
          set lsize              "super"
          set size               [expr $font_opts(-size) - 2]
          set font_opts(-size)   $size
          set line_opts(-offset) [expr $size / 2]
          lset name_list 4 1
        }
        "subscript"   {
          set lsize              "sub"
          set size               [expr $font_opts(-size) - 2]
          set font_opts(-size)   $size
          set line_opts(-offset) [expr 0 - ($size / 2)]
          lset name_list 5 1
        }
      }
    }

    set fontname ctext-[join $name_list ""]$lsize
    if {[lsearch [font names] $fontname] == -1} {
      font create $fontname {*}[array get font_opts]
    }

    if {$lsize ne ""} {
      set data($win,highlight,lsize,$class) "lsize$lsize"
      $win.l tag configure $data($win,highlight,lsize,$class) {*}[array get line_opts] -font $fontname
    }

    lappend opts -font $fontname {*}[array get tag_opts] {*}[array get line_opts]

    if {$click} {
      set data($win,highlight,click,$class) $opts
    }

  }

}

proc ctext::addHighlightClass {win class fgcolor {bgcolor ""} {font_opts ""}} {

  variable data

  set opts [list]

  if {$fgcolor ne ""} {
    lappend opts -foreground $fgcolor
  }
  if {$bgcolor ne ""} {
    lappend opts -background $bgcolor
  }
  if {$font_opts ne ""} {
    add_font_opt $win $class $font_opts opts
  }

  if {[llength $opts] > 0} {
    $win tag configure _$class {*}$opts
    $win tag lower _$class sel
  }

  set data($win,classes,_$class) 1

}

proc ctext::addHighlightKeywords {win keywords type value {lang ""}} {

  variable data

  if {$type eq "class"} {
    set value _$value
  }

  foreach word $keywords {
    set data($win,highlight,keyword,$type,$lang,$word) $value
  }

}

proc ctext::addHighlightRegexp {win re type value {lang ""}} {

  variable data

  if {$type eq "class"} {
    set value _$value
  }

  lappend data($win,highlight,regexps) "regexp,$type,$lang,$value"

  set data($win,highlight,regexp,$type,$lang,$value) [list $re $data($win,config,re_opts)]

}

# For things like $blah
proc ctext::addHighlightWithOnlyCharStart {win char type value {lang ""}} {

  variable data

  if {$type eq "class"} {
    set value _$value
  }

  set data($win,highlight,charstart,$type,$lang,$char) $value

}

proc ctext::addSearchClass {win class fgcolor bgcolor modifiers str} {

  variable data

  addHighlightClass $win $class $fgcolor $bgcolor $modifiers

  set data($win,highlight,searchword,class,$str) _$class

  # Perform the search
  set i 0
  foreach res [$win._t search -count lengths -all -- $str 1.0 end] {
    set wordEnd [$win._t index "$res + [lindex $lengths $i] chars"]
    $win._t tag add _$class $res $wordEnd
    incr i
  }

}

proc ctext::addSearchClassForRegexp {win class fgcolor bgcolor modifiers re {re_opts ""}} {

  variable data

  addHighlightClass $win $class $fgcolor $bgcolor $modifiers

  if {$re_opts ne ""} {
    set re_opts $data($win,config,re_opts)
  }

  lappend data($win,highlight,regexps) "searchregexp,class,,_$class"

  set data($win,highlight,searchregexp,class,,_$class) [list $re $re_opts]

  # Perform the search
  set i 0
  foreach res [$win._t search -count lengths -regexp -all {*}$re_opts -- $re 1.0 end] {
    set wordEnd [$win._t index "$res + [lindex $lengths $i] chars"]
    $win._t tag add _$class $res $wordEnd
    incr i
  }

}

proc ctext::deleteHighlightClass {win classToDelete} {

  variable data

  if {![info exists data($win,classes,_$classToDelete)]} {
    return -code error "$classToDelete doesn't exist"
  }

  if {[set index [lsearch -glob $data($win,highlight,regexps) *regexp,class,*,_$classToDelete]] != -1} {
    set data($win,highlight,regexps) [lreplace $data($win,highlight,regexps) $index $index]
  }

  array unset data $win,highlight,*,class,_$classToDelete
  unset data($win,classes,_$classToDelete)

  $win tag delete _$classToDelete 1.0 end

}

proc ctext::getHighlightClasses win {

  variable data

  set classes [list]
  foreach class [array names data $win,classes,*] {
    lappend classes [string range [lindex [split $class ,] 2] 1 end]
  }

  return $classes

}

proc ctext::clearHighlightClasses {win} {

  variable data

  array unset data $win,highlight,*
  array unset data $win,classes,*

  # Delete the associated tags
  if {[winfo exists $win]} {
    foreach tag [$win tag names] {
      if {[string index $tag 0] eq "_"} {
        $win tag delete $tag
      }
    }
  }

}

proc ctext::handle_tag {win class startpos endpos cmd} {

  variable data

  # Add the tag and possible binding
  if {[info exists data($win,highlight,click,$class)]} {
    set tag _$class[incr data($win,highlight,click_index)]
    $win tag add      $tag $startpos $endpos
    $win tag configure $tag {*}$data($win,highlight,click,$class)
    $win tag bind     $tag <Button-3> $cmd
  } else {
    $win tag add _$class $startpos $endpos
  }

  # Add the lsize
  if {[info exists data($win,highlight,lsize,$class)]} {
    set startline [lindex [split $startpos .] 0]
    set endline   [lindex [split $startpos .] 0]
    for {set line $startline} {$line <= $endline} {incr line} {
      $win tag add $data($win,highlight,lsize,$class) $line.0
    }
    linemapUpdate $win
  }

}

proc ctext::doHighlight {win start end ins} {

  variable data
  variable REs
  variable restart_from

  if {![winfo exists $win]} {
    return
  }

  if {!$data($win,config,-highlight)} {
    return
  }

  set twin "$win._t"
  array set tags [list]

  # Handle word-based matching
  set i 0
  foreach res [$twin search -count lengths -regexp {*}$data($win,config,re_opts) -all -- $data($win,config,-delimiters) $start $end] {
    set wordEnd [$twin index "$res + [lindex $lengths $i] chars"]
    set word    [$twin get $res $wordEnd]
    set lang    [lindex [split [lindex [$twin tag names $res] 0] =] 1]
    if {!$ctext::data($win,config,-casesensitive)} {
      set word [string tolower $word]
    }
    set firstOfWord [string index $word 0]
    if {[info exists data($win,highlight,keyword,class,$lang,$word)]} {
      lappend tags($data($win,highlight,keyword,class,$lang,$word)) $res $wordEnd
    } elseif {[info exists data($win,highlight,charstart,class,$lang,$firstOfWord)]} {
      lappend tags($data($win,highlight,charstart,class,$lang,$firstOfWord)) $res $wordEnd
    }
    if {[info exists data($win,highlight,keyword,command,$lang,$word)] && \
        ![catch { {*}$data($win,highlight,keyword,command,$lang,$word) $win $res $wordEnd $ins } retval] && ([llength $retval] == 4)} {
      handle_tag $win {*}$retval
    } elseif {[info exists data($win,highlight,charstart,command,$lang,$firstOfWord)] && \
              ![catch { {*}$data($win,highlight,charstart,command,$lang,$firstOfWord) $win $res $wordEnd $ins } retval] && ([llength $retval] == 4)} {
      handle_tag $win {*}$retval
    }
    if {[info exists data($win,highlight,searchword,class,$word)]} {
      $twin tag add $data($win,highlight,searchword,class,$word) $res $wordEnd
    } elseif {[info exists data($win,highlight,searchword,command,$word)] && \
              ![catch { {*}$data($win,highlight,searchword,command,$word) $win $res $wordEnd $ins } retval] && ([llength $retval] == 4)} {
      handle_tag $win {*}$retval
    }
    incr i
  }

  # Handle regular expression matching
  if {[info exists data($win,highlight,regexps)]} {
    foreach name $data($win,highlight,regexps) {
      lassign [split $name ,] dummy type lang value
      lassign $data($win,highlight,$name) re re_opts
      set i 0
      if {$type eq "class"} {
        foreach res [$twin search -count lengths -regexp {*}$re_opts -all -- $re $start $end] {
          if {$lang eq [lindex [split [lindex [$twin tag names $res] 0] =] 1]} {
            set wordEnd [$twin index "$res + [lindex $lengths $i] chars"]
            lappend tags($value) $res $wordEnd
          }
          incr i
        }
      } else {
        set indices [$twin search -count lengths -regexp {*}$re_opts -all -- $re $start $end]
        while {[llength $indices]} {
          set indices [lassign $indices res]
          set wordEnd [$twin index "$res + [lindex $lengths $i] chars"]
          incr i
          if {$lang eq [lindex [split [lindex [$twin tag names $res] 0] =] 1]} {
            if {![catch { {*}$value $win $res $wordEnd $ins } retval] && ([llength $retval] == 2)} {
              foreach sub [lindex $retval 0] {
                if {[llength $sub] == 4} {
                  handle_tag $win {*}$sub
                }
              }
              if {[set restart_from [lindex $retval 1]] ne ""} {
                set i       0
                set indices [$twin search -count lengths -regexp {*}$re_opts -all -- $re $restart_from $end]
              }
            }
          }
        }
      }
    }
  }

  # Add the tags
  foreach tag [array names tags] {
    $twin tag add $tag {*}$tags($tag)
  }

}

# Called when the given lines are about to be deleted.  Allows the linemap_mark_command call to
# be made when this occurs.
proc ctext::linemapCheckOnDelete {win startpos {endpos ""}} {

  variable data

  if {$data($win,config,-linemap_mark_command) ne ""} {

    if {$endpos eq ""} {
      set endpos $startpos
    }

    if {[lindex [split $startpos .] 1] == 0} {
      if {[set lmark [lsearch -inline -glob [$win._t tag names $startpos] lmark*]] ne ""} {
        uplevel #0 [list {*}$data($win,config,-linemap_mark_command) $win unmarked $lmark]
      }
    }

    while {[$win._t compare [set startpos [$win._t index "$startpos+1l linestart"]] < $endpos]} {
      if {[set lmark [lsearch -inline -glob [$win._t tag names $startpos] lmark*]] ne ""} {
        uplevel #0 [list {*}$data($win,config,-linemap_mark_command) $win unmarked $lmark]
      }
    }

  }

}

proc ctext::linemapToggleMark {win y} {

  variable data

  if {!$data($win,config,-linemap_markable)} {
    return
  }

  set lline [lindex [split [set lmarkChar [$win.l index @0,$y]] .] 0]
  set tline [lindex [split [set tmarkChar [$win.t index @0,$y]] .] 0]

  if {[set lmark [lsearch -inline -glob [$win.t tag names $tline.0] lmark*]] ne ""} {
    #It's already marked, so unmark it.
    $win.l tag remove lmark $lline.0
    $win.t tag delete $lmark
    ctext::linemapUpdate $win
    set type unmarked
  } else {
    set lmark "lmark[incr data($win,linemap,id)]"
    #This means that the line isn't toggled, so toggle it.
    $win.t tag add $lmark $tmarkChar [$win.t index "$tmarkChar lineend"]
    $win.l tag add lmark $lmarkChar [$win.l index "$lmarkChar lineend"]
    $win.l tag configure lmark -foreground $data($win,config,-linemap_select_fg) \
      -background $data($win,config,-linemap_select_bg)
    set type marked
  }

  # Call the mark command, if one exists.  If it returns a value of 0, remove
  # the mark.
  if {[string length $data($win,config,-linemap_mark_command)]} {
    if {![uplevel #0 [linsert $data($win,config,-linemap_mark_command) end $win $type $lmark]]} {
      $win.t tag delete $lmark
      $win.l tag remove lmark $lline.0
      ctext::linemapUpdate $win
    }
  }

}

proc ctext::linemapSetMark {win line} {

  variable data

  if {[lsearch -inline -glob [$win.t tag names $line.0] lmark*] eq ""} {
    set lmark "lmark[incr data($win,linemap,id)]"
    $win.t tag add $lmark $line.0
    $win.l tag add lmark $line.0
    $win.l tag configure lmark -foreground $data($win,config,-linemap_select_fg) \
      -background $data($win,config,-linemap_select_bg)
    return $lmark
  }

  return ""

}

proc ctext::linemapClearMark {win line} {

  if {[set lmark [lsearch -inline -glob [$win.t tag names $line.0] lmark*]] ne ""} {
    $win.t tag delete $lmark
    $win.l tag remove lmark $line.0
    ctext::linemapUpdate $win
  }

}

#args is here because -yscrollcommand may call it
proc ctext::linemapUpdate {win {old_pos ""}} {

  variable data

  # Check to see if the current cursor is on a bracket and match it
  if {$data($win,config,-matchchar)} {
    ctext::matchBracket $win
  }

  if {![winfo exists $win.l] || \
      (($old_pos ne "") && ([lindex [split [$win._t index insert] .] 0] eq [lindex [split $old_pos .] 0]))} {
    return
  }

  set first_line    [lindex [split [$win.t index @0,0] .] 0]
  set last_line     [lindex [split [$win.t index @0,[winfo height $win.t]] .] 0]
  set line_width    [string length [lindex [split [$win._t index end-1c] .] 0]]
  set linenum_width [expr max( $data($win,config,-linemap_minwidth), $line_width )]
  set gutter_width  [llength $data($win,config,gutters)]

  if {$gutter_width > 0} {
    set gutter_items [lrepeat $gutter_width " " [list]]
  } else {
    set gutter_items ""
  }

  $win.l delete 1.0 end

  if {$data($win,config,-diff_mode)} {
    linemapDiffUpdate $win $first_line $last_line $linenum_width $gutter_items
    set full_width [expr ($linenum_width * 2) + 1 + $gutter_width]
  } elseif {$data($win,config,-linemap)} {
    linemapLineUpdate $win $first_line $last_line $linenum_width $gutter_items
    set full_width [expr $linenum_width + $gutter_width]
  } elseif {$gutter_width > 0} {
    linemapGutterUpdate $win $first_line $last_line $linenum_width $gutter_items
    set full_width [expr $data($win,config,-linemap_markable) + $gutter_width]
  } elseif {$data($win,config,-linemap_markable)} {
    linemapMarkUpdate $win $first_line $last_line
    set full_width $gutter_width
  }

  linemapUpdateOffset $win $first_line $last_line

  # Resize the linemap window, if necessary
  if {[$win.l cget -width] != $full_width} {
    $win.l configure -width $full_width
  }

}

proc ctext::linemapDiffUpdate {win first last linenum_width gutter_items} {

  variable data

  set lsize_pos [expr 2 + [llength $gutter_items] + 1]

  # Calculate the starting line numbers for both files
  array set currline {A 0 B 0}
  foreach diff_tag [lsearch -inline -all -glob [$win.t tag names $first.0] diff:*] {
    lassign [split $diff_tag :] dummy index type start
    set currline($index) [expr $start - 1]
    if {$type eq "S"} {
      incr currline($index) [$win count -lines [lindex [$win tag ranges $diff_tag] 0] $first.0]
    }
  }

  for {set line $first} {$line <= $last} {incr line} {
    if {[$win._t count -displaychars $line.0 [expr $line + 1].0] == 0} { continue }
    set ltags [$win.t tag names $line.0]
    set lineA ""
    if {[lsearch -glob $ltags diff:A:S:*] != -1} {
      set lineA [incr currline(A)]
    }
    set lineB ""
    if {[lsearch -glob $ltags diff:B:S:*] != -1} {
      set lineB [incr currline(B)]
    }
    set line_content [list [format "%-*s %-*s" $linenum_width $lineA $linenum_width $lineB] [list] {*}$gutter_items "0" [list] "\n"]
    if {[lsearch -glob $ltags lmark*] != -1} {
      lset line_content 1 lmark
    }
    if {[set lsizes [lsearch -inline -glob -all $ltags lsize*]] ne ""} {
      lset line_content $lsize_pos [lindex [lsort $lsizes] 0]
    }
    foreach gutter_tag [lsearch -inline -all -glob $ltags gutter:*] {
      lassign [split $gutter_tag :] dummy gutter_name gutter_symname gutter_sym
      if {$gutter_sym ne ""} {
        set gutter_index [expr ([lsearch -index 0 $data($win,config,gutters) $gutter_name] * 2) + 2]
        lset line_content $gutter_index            $gutter_sym
        lset line_content [expr $gutter_index + 1] $gutter_tag
      }
    }
    $win.l insert end {*}$line_content
  }

}

proc ctext::linemapLineUpdate {win first last linenum_width gutter_items} {

  variable data

  set abs       [expr {$data($win,config,-linemap_type) eq "absolute"}]
  set curr      [lindex [split [$win.t index insert] .] 0]
  set lsize_pos [expr 2 + [llength $gutter_items] + 1]

  for {set line $first} {$line <= $last} {incr line} {
    if {[$win._t count -displaychars $line.0 [expr $line + 1].0] == 0} { continue }
    set ltags        [$win.t tag names $line.0]
    set linenum      [expr $abs ? $line : abs( $line - $curr )]
    set line_content [list [format "%-*s" $linenum_width $linenum] [list] {*}$gutter_items "0" [list] "\n"]
    if {[lsearch -glob $ltags lmark*] != -1} {
      lset line_content 1 lmark
    }
    if {[set lsizes [lsearch -inline -glob -all $ltags lsize*]] ne ""} {
      lset line_content $lsize_pos [lindex [lsort $lsizes] 0]
    }
    foreach gutter_tag [lsearch -inline -all -glob $ltags gutter:*] {
      lassign [split $gutter_tag :] dummy gutter_name gutter_symname gutter_sym
      if {$gutter_sym ne ""} {
        set gutter_index [expr ([lsearch -index 0 $data($win,config,gutters) $gutter_name] * 2) + 2]
        lset line_content $gutter_index            $gutter_sym
        lset line_content [expr $gutter_index + 1] $gutter_tag
      }
    }
    $win.l insert end {*}$line_content
  }

}

proc ctext::linemapGutterUpdate {win first last linenum_width gutter_items} {

  variable data

  if {$data($win,config,-linemap_markable)} {
    set line_template [list " " [list] {*}$gutter_items "0" [list] "\n"]
    set line_items    2
  } else {
    set line_template [list {*}$gutter_items "0" [list] "\n"]
    set line_items    0
  }

  set lsize_pos [expr [llength $gutter_items] + $line_items + 1]

  for {set line $first} {$line <= $last} {incr line} {
    if {[$win._t count -displaychars $line.0 [expr $line + 1].0] == 0} { continue }
    set ltags [$win.t tag names $line.0]
    set line_content [list " " [list] {*}$gutter_items "0" [list] "\n"]
    if {[lsearch -glob $ltags lmark*] != -1} {
      lset line_content 1 lmark
    }
    if {[set lsizes [lsearch -inline -glob -all $ltags lsize*]] ne ""} {
      lset line_content $lsize_pos [lindex [lsort $lsizes] 0]
    }
    foreach gutter_tag [lsearch -inline -all -glob $ltags gutter:*] {
      lassign [split $gutter_tag :] dummy gutter_name gutter_symname gutter_sym
      if {$gutter_sym ne ""} {
        set gutter_index [expr ([lsearch -index 0 $data($win,config,gutters) $gutter_name] * 2) + $line_items]
        lset line_content $gutter_index            $gutter_sym
        lset line_content [expr $gutter_index + 1] $gutter_tag
      }
    }
    $win.l insert end {*}$line_content
  }

}

proc ctext::linemapMarkUpdate {win first last} {

  for {set line $first} {$line <= $last} {incr line} {
    if {[$win._t count -displaychars $line.0 [expr $line + 1].0] == 0} { continue }
    set ltags        [$win.t tag names $line.0]
    set line_content [list " " [list] "0" [list] "\n"]
    if {[lsearch -glob $ltags lmark*] != -1} {
      lset line_content 1 lmark
    }
    if {[set lsizes [lsearch -inline -glob -all $ltags lsize*]] ne ""} {
      lset line_content 3 [lindex [lsort $lsizes] 0]
    }
    $win.l insert end {*}$line_content
  }

}

# Starting with Tk 8.5 the text widget allows smooth scrolling; this
# code calculates the offset for the line numbering text widget and
# scrolls by the specified amount of pixels

if {![catch {
  package require Tk 8.5
}]} {
  proc ctext::linemapUpdateOffset {win first_line last_line} {
    # reset view for line numbering widget
    $win.l yview 0.0

    # find the first line that is visible and calculate the
    # corresponding line in the line numbers widget
    set lline 1
    for {set line $first_line} {$line <= $last_line} {incr line} {
      set tystart [lindex [$win.t bbox $line.0] 1]
      if {$tystart != ""} {
        break
      }
      incr lline
    }

    # return in case the line numbers text widget is not up-to-date
    if {[catch { set lystart [lindex [$win.l bbox $lline.0] 1] }]} {
      return
    }

    # return in case the bbox for any of the lines returned an
    # empty value
    if {($tystart == "") || ($lystart == "")} {
      return
    }

    # calculate the offset and then scroll by specified number of
    # pixels
    set offset [expr {$lystart - $tystart}]
    $win.l yview scroll $offset pixels
  }
}  else  {
  # Do not try to perform smooth scrolling if Tk is 8.4 or less.
  proc ctext::linemapUpdateOffset {args} {}
}

proc ctext::modified {win value {dat ""}} {

  variable data

  set data($win,config,modified) $value
  event generate $win <<Modified>> -data $dat

  return $value

}
