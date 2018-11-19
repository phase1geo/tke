# RCS: @(#) $Id: ctext.tcl,v 1.9 2011/04/18 19:49:48 andreas_kupries Exp $

package require Tk
package provide ctext 5.0

# Override the tk::TextSetCursor to add a <<CursorChanged>> event
rename ::tk::TextSetCursor ::tk::TextSetCursorOrig
proc ::tk::TextSetCursor {w pos args} {
  set ins [$w index insert]
  ::tk::TextSetCursorOrig $w $pos
  event generate $w <<CursorChanged>> -data [list $ins {*}$args]
}

namespace eval ctext {

  array set REs {
    words    {[^\s\(\{\[\}\]\)\.\t\n\r;:=\"'\|,<>]+}
    brackets {[][()\{\}<>]}
  }
  array set bracket_map  {\( parenL \) parenR \{ curlyL \} curlyR \[ squareL \] squareR < angledL > angledR}
  array set bracket_map2 {\( paren \) paren \{ curly \} curly \[ square \] square < angled > angled}
  array set data {}

  variable temporary {}
  variable right_click 3

  if {[tk windowingsystem] eq "aqua"} {
    set right_click 2
  }

  proc create {win args} {

    variable data
    variable right_click
    variable REs

    if {[llength $args] & 1} {
      return -code error "Invalid number of arguments given to ctext (uneven number after window) : $args"
    }

    frame $win -class Ctext ;# -padx 1 -pady 1

    set tmp [text .__ctextTemp]

    set data($win,config,-fg)                     [$tmp cget -foreground]
    set data($win,config,-bg)                     [$tmp cget -background]
    set data($win,config,-font)                   [$tmp cget -font]
    set data($win,config,-relief)                 [$tmp cget -relief]
    set data($win,config,-unhighlightcolor)       [$win cget -bg]
    destroy $tmp
    set data($win,config,-xscrollcommand)          ""
    set data($win,config,-yscrollcommand)          ""
    set data($win,config,-highlightcolor)          "yellow"
    set data($win,config,-linemap)                 1
    set data($win,config,-linemapfg)               $data($win,config,-fg)
    set data($win,config,-linemapbg)               $data($win,config,-bg)
    set data($win,config,-linemap_mark_command)    {}
    set data($win,config,-linemap_markable)        1
    set data($win,config,-linemap_mark_color)      orange
    set data($win,config,-linemap_cursor)          left_ptr
    set data($win,config,-linemap_relief)          $data($win,config,-relief)
    set data($win,config,-linemap_minwidth)        1
    set data($win,config,-linemap_type)            absolute
    set data($win,config,-linemap_align)           left
    set data($win,config,-linemap_separator)       auto
    set data($win,config,-linemap_separator_color) red
    set data($win,config,-highlight)               1
    set data($win,config,-lmargin)                 0
    set data($win,config,-warnwidth)               ""
    set data($win,config,-warnwidth_bg)            red
    set data($win,config,-casesensitive)           1
    set data($win,config,-escapes)                 1
    set data($win,config,-peer)                    ""
    set data($win,config,-undo)                    0
    set data($win,config,-maxundo)                 0
    set data($win,config,-autoseparators)          0
    set data($win,config,-diff_mode)               0
    set data($win,config,-diffsubbg)               "pink"
    set data($win,config,-diffaddbg)               "light green"
    set data($win,config,-folding)                 0
    set data($win,config,-delimiters)              $REs(words)
    set data($win,config,-matchchar)               0
    set data($win,config,-matchchar_bg)            $data($win,config,-fg)
    set data($win,config,-matchchar_fg)            $data($win,config,-bg)
    set data($win,config,-matchaudit)              0
    set data($win,config,-matchaudit_bg)           "red"
    set data($win,config,-theme)                   [list]
    set data($win,config,re_opts)                  ""
    set data($win,config,win)                      $win
    set data($win,config,modified)                 0
    set data($win,config,lastUpdate)               0
    set data($win,config,csl_array)                [list]
    set data($win,config,csl_markers)              [list]
    set data($win,config,csl_tag_pair)             [list]
    set data($win,config,csl_tags)                 [list]
    set data($win,config,langs)                    [list {}]
    set data($win,config,gutters)                  [list]
    set data($win,config,undo_hist)                [list]
    set data($win,config,undo_hist_size)           0
    set data($win,config,undo_sep_last)            -1
    set data($win,config,undo_sep_next)            -1
    set data($win,config,undo_sep_size)            0
    set data($win,config,undo_sep_count)           0
    set data($win,config,redo_hist)                [list]

    set data($win,config,ctextFlags) [list -xscrollcommand -yscrollcommand -linemap -linemapfg -linemapbg \
    -font -linemap_mark_command -highlight -warnwidth -warnwidth_bg -linemap_markable \
    -linemap_cursor -highlightcolor -folding -delimiters -matchchar -matchchar_bg -matchchar_fg -matchaudit -matchaudit_bg \
    -linemap_mark_color -linemap_relief -linemap_minwidth -linemap_type -linemap_align \
    -linemap_separator -linemap_separator_color -casesensitive -peer -theme \
    -undo -maxundo -autoseparators -diff_mode -diffsubbg -diffaddbg -escapes -spacing3 -lmargin]

    # Set args
    foreach {name value} $args {
      set data($win,config,$name) $value
    }

    set data($win,fontwidth)   [font measure $data($win,config,-font) -displayof . "0"]
    set data($win,fontdescent) [font metrics $data($win,config,-font) -displayof . -descent]

    foreach flag {foreground background} short {fg bg} {
      if {[info exists data($win,config,-$flag)] == 1} {
        set data($win,config,-$short) $data($win,config,-$flag)
        unset data($win,config,-$flag)
      }
    }

    # Now remove flags that will confuse text and those that need
    # modification:
    foreach arg $data($win,config,ctextFlags) {
      if {[set loc [lsearch $args $arg]] >= 0} {
        set args [lreplace $args $loc [expr {$loc + 1}]]
      }
    }

    # Initialize the starting linemap ID
    set data($win,linemap,id) 0

    canvas $win.l -relief $data($win,config,-relief) -bd 0 \
      -bg $data($win,config,-linemapbg) -takefocus 0 -highlightthickness 0
    frame $win.f -width 1 -bd 0 -relief flat -bg $data($win,config,-linemap_separator_color)

    set args [concat $args [list -yscrollcommand [list ctext::event:yscroll $win $data($win,config,-yscrollcommand)]] \
                           [list -xscrollcommand [list ctext::event:xscroll $win $data($win,config,-xscrollcommand)]]]

    if {$data($win,config,-peer) eq ""} {
      text $win.t -font $data($win,config,-font) -bd 0 -highlightthickness 0 {*}$args
    } else {
      $data($win,config,-peer)._t peer create $win.t -font $data($win,config,-font) -bd 0 -highlightthickness 0 {*}$args
    }

    frame $win.t.w -width 1 -bd 0 -relief flat -bg $data($win,config,-warnwidth_bg)

    if {$data($win,config,-warnwidth) ne ""} {
      place $win.t.w -x [expr $data($win,config,-lmargin) + [font measure [$win.t cget -font] -displayof . [string repeat "m" $data($win,config,-warnwidth)]]] -relheight 1.0
    }

    grid rowconfigure    $win 0 -weight 100
    grid columnconfigure $win 2 -weight 100
    grid $win.l -row 0 -column 0 -sticky ns
    grid $win.f -row 0 -column 1 -sticky ns
    grid $win.t -row 0 -column 2 -sticky news

    # Hide the linemap and separator if we are specified to do so
    if {!$data($win,config,-linemap) && !$data($win,config,-linemap_markable) && !$data($win,config,-folding)} {
      grid remove $win.l
      grid remove $win.f
    }

    # Add the layer tags
    $win.t tag configure _visibleH
    $win.t tag configure _visibleL
    $win.t tag configure _invisible
    $win.t tag lower _visibleH   sel
    $win.t tag lower _visibleL  _visibleH
    $win.t tag lower _invisible _visibleL

    # Add default classes
    $win.t tag configure __escape
    $win.t tag configure __prewhite
    $win.t tag configure rmargin
    $win.t tag configure lmargin
    $win.t tag lower __escape   _invisible
    $win.t tag lower __prewhite _invisible
    $win.t tag lower rmargin    _invisible
    $win.t tag lower lmargin    _invisible

    # If -matchchar is set, create the tag
    if {$data($win,config,-matchchar)} {
      $win.t tag configure matchchar -foreground $data($win,config,-matchchar_fg) -background $data($win,config,-matchchar_bg)
      $win.t tag lower matchchar sel
    }


    bind $win.t <Configure>           [list ctext::linemapUpdate $win]
    bind $win.t <<CursorChanged>>     [list ctext::linemapUpdate $win]
    bind $win.l <Button-$right_click> [list ctext::linemapToggleMark $win %x %y]
    bind $win.l <MouseWheel>          [list event generate $win.t <MouseWheel> -delta %D]
    bind $win.l <4>                   [list event generate $win.t <4>]
    bind $win.l <5>                   [list event generate $win.t <5>]
    bind $win.t <Destroy>             [list ctext::event:Destroy $win]

    bindtags $win.t [linsert [bindtags $win.t] 0 $win]

    return $win

  }

  proc event:xscroll {win clientData args} {

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
      set cwidth  [font measure [$win._t cget -font] -displayof . "m"]
      set missing [expr round( ($longest * $cwidth) * $first )]
    } else {
      set missing 0
    }

    # Adjust the warning width line, if one was requested
    set_warnwidth $win [expr 0 - $missing]

  }

  proc event:yscroll {win clientData args} {

    linemapUpdate $win

    if {$clientData == ""} {
      return
    }

    uplevel \#0 $clientData $args

  }

  proc event:Destroy {win} {

    variable data

    bgproc::killall ctext::*

    catch { rename $win {} }
    interp alias {} $win.t {}
    # clearHighlightClasses $win
    array unset data $win,*

  }

  # This stores the arg table within the config array for each instance.
  # It's used by the configure instance command.
  proc buildArgParseTable win {

    variable data

    set argTable [list]

    lappend argTable any -background {
      if {[catch { winfo rgb $win $value } res]} {
        return -code error $res
      }
      set data($win,config,-background) $value
      $win.t configure -bg $value
      update_linemap_separator $win
      break
    }

    lappend argTable any -linemap_separator {
      set data($win,config,-linemap_separator) $value
      update_linemap_separator $win
      break
    }

    lappend argTable any -linemap_separator_color {
      if {[catch {winfo rgb $win $value} res]} {
        return -code error $res
      }
      set data($win,config,-linemap_separator_color) $value
      $win.f configure -bg $value
      update_linemap_separator $win
      break
    }

    lappend argTable {1 true yes} -linemap {
      set data($win,config,-linemap) 1
      catch {
        grid $win.l
        grid $win.f
      }
      set update_linemap 1
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
        set update_linemap 1
      }
      break
    }

    lappend argTable any -linemap_mark_command {
      set data($win,config,-linemap_mark_command) $value
      break
    }

    lappend argTable {1 true yes} -folding {
      set data($win,config,-folding) 1
      catch {
        grid $win.l
        grid $win.f
      }
      set update_linemap 1
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
        set update_linemap 1
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
    }

    lappend argTable any -linemapfg {
      if {[catch {winfo rgb $win $value} res]} {
        return -code error $res
      }
      $win.l itemconfigure unmarked -fill $value
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
      $win._t config -font $value
      set data($win,config,-font) $value
      set data($win,fontwidth)    [font measure $value -displayof $win "0"]
      set data($win,fontdescent)  [font metrics $data($win,config,-font) -displayof $win -descent]
      set update_linemap 1
      set_warnwidth $win
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

    lappend argTable any -lmargin {
      if {[string is integer $value] && ($value >= 0)} {
        set data($win,config,-lmargin) $value
        set_warnwidth $win
        $win tag configure lmargin -lmargin1 $value -lmargin2 $value
      } else {
        return -code error "Error: -lmargin option must be an integer value greater or equal to zero"
      }
      break
    }

    lappend argTable any -warnwidth {
      set data($win,config,-warnwidth) $value
      set_warnwidth $win
      break
    }

    lappend argTable any -warnwidth_bg {
      if {[catch {winfo rgb $win $value} res]} {
        return -code error $res
      }
      set data($win,config,-warnwidth_bg) $value
      $win.t.w configure -bg $value
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

    lappend argTable any -linemap_mark_color {
      if {[catch {winfo rgb $win $value} res]} {
        return -code error $res
      }
      set data($win,config,-linemap_mark_color) $value
      set update_linemap 1
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
      set data($win,config,-linemap_minwidth) $value
      set update_linemap 1
      break
    }

    lappend argTable {absolute relative} -linemap_type {
      if {[lsearch [list absolute relative] $value] == -1} {
        return -code error "-linemap_type argument must be either 'absolute' or 'relative'"
      }
      set data($win,config,-linemap_type) $value
      set update_linemap 1
      break
    }

    lappend argTable {left right} -linemap_align {
      set data($win,config,-linemap_align) $value
      set update_linemap 1
      break;
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
      undo_manage $win
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

    lappend argTable {0 false no} -matchaudit {
      set data($win,config,-matchaudit) 0
      foreach type [list curly square paren angled] {
        catch { $win tag remove missing:$type 1.0 end }
      }
      break
    }

    lappend argTable {1 true yes} -matchaudit {
      set data($win,config,-matchaudit) 1
      checkAllBrackets $win
      break
    }

    lappend argTable {any} -matchaudit_bg {
      set data($win,config,-matchaudit_bg) $value
      foreach type [list curly square paren angled] {
        if {[lsearch [$win tag names] missing:$type] != -1} {
          $win tag configure missing:$type -background $value
          $win tag raise missing:$type _visibleH
        }
      }
      break
    }

    lappend argTable any -theme {
      set data($win,config,-theme) $value
      foreach key [array names data $win,classopts,*] {
        lassign [split $key ,] dummy1 dummy2 class
        applyClassTheme $win $class
      }
    }

    set data($win,config,argTable) $argTable

  }

  ######################################################################
  # Shows/hides the linemap separator depending on the value of linemap_separator.
  proc update_linemap_separator {win} {

    variable data

    # If the linemap is not being displayed, return now
    if {[lsearch [grid slaves $win] $win.l] == -1} {
      return
    }

    switch $data($win,config,-linemap_separator) {
      1   -
      yes -
      true {
        grid $win.f
      }
      auto {
        catch {
          set lm [winfo rgb $win $data($win,config,-linemapbg)]
          set bg [winfo rgb $win $data($win,config,-background)]
          if {$lm ne $bg} {
            grid $win.f
          } else {
            grid remove $win.f
          }
        }
      }
      default {
        grid remove $win.f
      }
    }

  }

  proc inCommentStringHelper {win index pattern} {

    set names [$win tag names $index]

    return [expr {[string map [list $pattern {}] $names] ne $names}]

  }

  proc inLineComment {win index} {

    return [inCommentStringHelper $win $index __comstr1l]

  }

  proc inBlockComment {win index} {

    return [inCommentStringHelper $win $index __comstr1c]

  }

  proc inComment {win index} {

    return [inCommentStringHelper $win $index __comstr1]

  }

  proc inBackTick {win index} {

    return [inCommentStringHelper $win $index __comstr0b]

  }

  proc inSingleQuote {win index} {

    return [inCommentStringHelper $win $index __comstr0s]

  }

  proc inDoubleQuote {win index} {

    return [inCommentStringHelper $win $index __comstr0d]

  }

  proc inTripleBackTick {win index} {

    return [inCommentStringHelper $win $index __comstr0B]

  }

  proc inTripleSingleQuote {win index} {

    return [inCommentStringHelper $win $index __comstr0S]

  }

  proc inTripleDoubleQuote {win index} {

    return [inCommentStringHelper $win $index __comstr0D]

  }

  proc inString {win index} {

    return [inCommentStringHelper $win $index __comstr0]

  }

  proc inCommentString {win index} {

    return [inCommentStringHelper $win $index __comstr]

  }

  proc inCommentStringRangeHelper {win index pattern prange} {

    if {[set curr_tag [lsearch -inline -glob [$win tag names $index] $pattern]] ne ""} {
      upvar 2 $prange range
      set range [$win tag prevrange $curr_tag $index+1c]
      return 1
    }

    return 0

  }

  proc inLineCommentRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr1l $prange]

  }

  proc inBlockCommentRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr1c* $prange]

  }

  proc inCommentRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr1* $prange]

  }

  proc commentCharRanges {win index} {

    if {[set curr_tag [lsearch -inline -glob [$win tag names $index] __comstr1*]] ne ""} {
      set range [$win tag prevrange $curr_tag $index+1c]
      if {[string index $curr_tag 9] eq "l"} {
        set start_tag [lsearch -inline -glob [$win tag names [lindex $range 0]] __lCommentStart:*]
        lappend ranges {*}[$win tag prevrange $start_tag [lindex $range 0]+1c] [lindex $range 1]
      } else {
        set start_tag [lsearch -inline -glob [$win tag names [lindex $range 0]]    __cCommentStart:*]
        set end_tag   [lsearch -inline -glob [$win tag names [lindex $range 1]-1c] __cCommentEnd:*]
        lappend ranges {*}[$win tag prevrange $start_tag [lindex $range 0]+1c]
        lappend ranges {*}[$win tag prevrange $end_tag [lindex $range 1]]
      }
      return $ranges
    }

    return [list]

  }

  proc inBackTickRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr0b* $prange]

  }

  proc inSingleQuoteRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr0s* $prange]

  }

  proc inDoubleQuoteRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr0d* $prange]

  }

  proc inTripleBackTickRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr0B* $prange]

  }

  proc inTripleSingleQuoteRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr0S* $prange]

  }

  proc inTripleDoubleQuoteRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr0D* $prange]

  }

  proc inStringRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr0* $prange]

  }

  proc inCommentStringRange {win index prange} {

    return [inCommentStringRangeHelper $win $index __comstr* $prange]

  }

  ######################################################################
  # Returns the text range for a bracketed block of text.
  proc inBlockRange {win type index prange} {

    upvar $prange range

    set range [list "" ""]

    # Search backwards
    if {[lsearch [$win._t tag names $index] __${type}L] == -1} {
      set startpos $index
    } else {
      set startpos "$index+1c"
    }

    if {[set left [getMatchBracket $win ${type}L $startpos]] ne ""} {
      set right [getMatchBracket $win ${type}R $left]
      if {($right eq "") || [$win._t compare $right < $index]} {
        return 0
      } else {
        set range [list [$win._t index $left] [$win._t index $right]]
        return 1
      }
    }

    return 0

  }

  proc handleFocusIn {win} {

    variable data

    __ctextJunk$win configure -bg $data($win,config,-highlightcolor)

  }

  proc handleFocusOut {win} {

    variable data

    __ctextJunk$win configure -bg $data($win,config,-unhighlightcolor)

  }

  proc set_border_color {win color} {

    __ctextJunk$win configure -bg $color

  }

  # Returns 1 if the character at the given index is escaped; otherwise, returns 0.
  proc isEscaped {win index} {

    set names [$win tag names $index-1c]

    return [expr {[string map {__escape {}} $names] ne $names}]

  }

  # Debugging procedure only
  proc undo_display {win} {

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

  proc undo_separator {win} {

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

      # Increment the separator count
      incr data($win,config,undo_sep_count)

    }

    # If the number of separators exceeds the maximum length, shorten the undo history list
    undo_manage $win

    # puts "END undo_separator"
    # undo_display $win

  }

  proc undo_manage {win} {

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

  proc undo_insert {win insert_pos str_len cursor} {

    variable data

    if {!$data($win,config,-undo)} {
      return
    }

    # puts "START undo_insert, insert_pos: $insert_pos, str_len: $str_len, cursor: $cursor"
    # undo_display $win

    set end_pos [$win index "$insert_pos+${str_len}c"]

    # Combine elements, if possible
    if {[llength $data($win,config,undo_hist)] > 0} {
      lassign [lindex $data($win,config,undo_hist) end] cmd val1 val2 hcursor sep
      if {$sep == 0} {
        if {($cmd eq "d") && ($val2 eq $insert_pos)} {
          lset data($win,config,undo_hist) end 2 $end_pos
          set data($win,config,redo_hist) [list]
          return
        }
      }
    }

    # Add to the undo history
    lappend data($win,config,undo_hist) [list d $insert_pos $end_pos $cursor 0]
    incr data($win,config,undo_hist_size)

    # Clear the redo history
    set data($win,config,redo_hist) [list]

    # puts "END undo_insert"
    # undo_display $win

  }

  proc undo_delete {win start_pos end_pos} {

    variable data

    if {!$data($win,config,-undo)} {
      return
    }

    # puts "START undo_delete, start_pos: $start_pos, end_pos: $end_pos"
    # undo_display $win

    set str [$win get $start_pos $end_pos]

    # Combine elements, if possible
    if {[llength $data($win,config,undo_hist)] > 0} {
      lassign [lindex $data($win,config,undo_hist) end] cmd val1 val2 cursor sep
      if {$sep == 0} {
        if {$cmd eq "i"} {
          if {$val1 eq $end_pos} {
            lset data($win,config,undo_hist) end 1 $start_pos
            lset data($win,config,undo_hist) end 2 "$str$val2"
            set data($win,config,redo_hist) [list]
            return
          } elseif {$val1 eq $start_pos} {
            lset data($win,config,undo_hist) end 2 "$val2$str"
            set data($win,config,redo_hist) [list]
            return
          }
        } elseif {($cmd eq "d") && ($val2 eq $end_pos)} {
          lset data($win,config,undo_hist) end 2 $start_pos
          lset data($win,config,redo_hist) [list]
          return
        }
      }
    }

    # Add to the undo history
    lappend data($win,config,undo_hist) [list i $start_pos $str [$win index insert] 0]
    incr data($win,config,undo_hist_size)

    # Clear the redo history
    set data($win,config,redo_hist) [list]

    # puts "END undo_delete"
    # undo_display $win

  }

  proc undo_get_cursor_hist {win} {

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

  proc undo {win} {

    variable data

    # puts "START undo"
    # undo_display $win

    if {[llength $data($win,config,undo_hist)] > 0} {

      set i           0
      set last_cursor 1.0
      set insert      0
      set ranges      [list]
      set do_tags     [list]
      set changed     ""

      foreach element [lreverse $data($win,config,undo_hist)] {

        lassign $element cmd val1 val2 cursor sep

        if {($i > 0) && $sep} {
          break
        }

        switch $cmd {
          i {
            $win._t insert $val1 $val2
            append changed $val2
            set val2 [$win index "$val1+[string length $val2]c"]
            comments_do_tag $win $val1 $val2 do_tags
            set_rmargin $win $val1 $val2
            lappend data($win,config,redo_hist) [list d $val1 $val2 $cursor $sep]
            set insert 1
          }
          d {
            set str [$win get $val1 $val2]
            append changed $str
            comments_chars_deleted $win $val1 $val2 do_tags
            $win._t delete $val1 $val2
            lappend data($win,config,redo_hist) [list i $val1 $str $cursor $sep]
          }
        }

        $win._t tag add hl [$win._t index "$val1 linestart"] [$win._t index "$val2 lineend"]

        set last_cursor $cursor

        incr i

      }

      # Get the list of affected lines that need to be re-highlighted
      set ranges [$win._t tag ranges hl]
      $win._t tag delete hl

      # Perform the highlight
      if {[llength $ranges] > 0} {
        if {[highlightAll $win $ranges $insert $do_tags]} {
          checkAllBrackets $win
        } else {
          checkAllBrackets $win $changed
        }
      }

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
      incr data($win,config,undo_sep_count) -1

      ::tk::TextSetCursor $win.t $last_cursor
      modified $win 1 [list undo $ranges ""]

    }

    # puts "END undo"
    # undo_display $win

  }

  proc redo {win} {

    variable data

    if {[llength $data($win,config,redo_hist)] > 0} {

      set i       0
      set insert  0
      set do_tags [list]
      set ranges  [list]
      set changed ""

      foreach element [lreverse $data($win,config,redo_hist)] {

        lassign $element cmd val1 val2 cursor sep

        switch $cmd {
          i {
            $win._t insert $val1 $val2
            append changed $val2
            set val2 [$win index "$val1+[string length $val2]c"]
            comments_do_tag $win.t $val1 $val2 do_tags
            set_rmargin $win $val1 $val2
            lappend data($win,config,undo_hist) [list d $val1 $val2 $cursor $sep]
            if {$cursor != $val2} {
              set cursor $val2
            }
            set insert 1
          }
          d {
            set str [$win get $val1 $val2]
            append changed $str
            comments_chars_deleted $win.t $val1 $val2 do_tags
            $win._t delete $val1 $val2
            lappend data($win,config,undo_hist) [list i $val1 $str $cursor $sep]
            if {$cursor != $val1} {
              set cursor $val1
            }
          }
        }

        $win._t tag add hl [$win._t index "$val1 linestart"] [$win._t index "$val2 lineend"]

        incr i

        if {$sep} {
          break
        }

      }

      # Get the list of affected lines that need to be re-highlighted
      set ranges [$win._t tag ranges hl]
      $win._t tag delete hl

      # Highlight the code
      if {[llength $ranges] > 0} {
        if {[highlightAll $win $ranges $insert $do_tags]} {
          checkAllBrackets $win
        } else {
          checkAllBrackets $win $changed
        }
      }

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
      incr data($win,config,undo_sep_count)

      ::tk::TextSetCursor $win.t $cursor
      modified $win 1 [list redo $ranges ""]

    }

  }

  proc getGutterTags {win pos} {

    set alltags [$win tag names $pos]
    set tags    [lsearch -inline -all -glob $alltags gutter:*]
    lappend tags {*}[lsearch -inline -all -glob $alltags lmark*]

    return $tags

  }

  ######################################################################
  # Move all gutter tags from the old column 0 of the given row to the new
  # column 0 character.
  proc handleInsertAt0 {win startpos datalen} {

    if {[lindex [split $startpos .] 1] == 0} {
      set endpos [$win index "$startpos+${datalen}c"]
      foreach tag [getGutterTags $win $endpos] {
        $win tag add $tag $startpos
        $win tag remove $tag $endpos
      }
    }

  }

  proc handleDeleteAt0Helper {win firstpos endpos} {

    foreach tag [getGutterTags $win $firstpos] {
      $win._t tag add $tag $endpos
    }

  }

  ######################################################################
  # Preserve gutter tags that will be deleted in column 0, moving them to
  # what will be the new column 0 after the deletion takes place.
  proc handleDeleteAt0 {win startpos endpos} {

    lassign [split $startpos .] startrow startcol
    lassign [split $endpos   .] endrow   endcol

    if {$startrow == $endrow} {
      if {$startcol == 0} {
        handleDeleteAt0Helper $win $startrow.0 $endpos
      }
    } elseif {$endcol != 0} {
      handleDeleteAt0Helper $win $endrow.0 $endpos
    }

  }

  ######################################################################
  # Called prior to the deletion of the text for a text replacement.
  proc handleReplaceDeleteAt0 {win startpos endpos} {

    lassign [split $startpos .] startrow startcol
    lassign [split $endpos   .] endrow   endcol

    if {$startrow == $endrow} {
      if {$startcol == 0} {
        return [list 0 [getGutterTags $win $startrow.0]]
      }
    } elseif {$endcol != 0} {
      return [list 1 [getGutterTags $win $endrow.0]]
    }

    return [list 0 [list]]

  }

  proc handleReplaceInsert {win startpos datalen tags} {

    if {[lindex $tags 0]} {
      set insertpos [$win._t index "$startpos+${datalen}c"]
    } else {
      set insertpos $startpos
    }

    foreach tag $tags {
      $win._t tag add $tag $insertpos
    }

  }

  proc instanceCmd {win cmd args} {

    variable data

    switch -glob -- $cmd {
      append      { return [command_append      $win {*}$args] }
      cget        { return [command_cget        $win {*}$args] }
      conf*       { return [command_configure   $win {*}$args] }
      copy        { return [command_copy        $win {*}$args] }
      cut         { return [command_cut         $win {*}$args] }
      delete      { return [command_delete      $win {*}$args] }
      diff        { return [command_diff        $win {*}$args] }
      edit        { return [command_edit        $win {*}$args] }
      fastdelete  { return [command_fastdelete  $win {*}$args] }
      fastinsert  { return [command_fastinsert  $win {*}$args] }
      fastreplace { return [command_fastreplace $win {*}$args] }
      gutter      { return [command_gutter      $win {*}$args] }
      highlight   { return [command_highlight   $win {*}$args] }
      insert      { return [command_insert      $win {*}$args] }
      is          { return [command_is          $win {*}$args] }
      replace     { return [command_replace     $win {*}$args] }
      paste       { return [command_paste       $win {*}$args] }
      peer        { return [command_peer        $win {*}$args] }
      syntax      { return [command_syntax      $win {*}$args] }
      tag         { return [command_tag         $win {*}$args] }
      language    { return [command_language    $win {*}$args] }
      default     { return [uplevel 1 [linsert $args 0 $win._t $cmd]] }
    }

  }

  proc command_append {win args} {

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

  proc command_cget {win args} {

    variable data

    set arg [lindex $args 0]

    foreach flag $data($win,config,ctextFlags) {
      if {[string match ${arg}* $flag]} {
        return [set data($win,config,$flag)]
      }
    }

    return [$win._t cget $arg]

  }

  proc command_configure {win args} {

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

    # Parse the argument list and process the value changes
    set update_linemap 0
    foreach {valueList flag cmd} $data($win,config,argTable) {
      if {[info exists flags($flag)]} {
        foreach valueToCheckFor $valueList {
          set value [set flags($flag)]
          if {[string equal "any" $valueToCheckFor]} $cmd \
          elseif {[string equal $valueToCheckFor [set flags($flag)]]} $cmd
        }
      }
    }

    # If we need to update the linemap, do it now
    if {$update_linemap} {
      linemapUpdate $win 1
    }

    if {[llength $args]} {
      uplevel 1 [linsert $args 0 $win._t configure]
    }

  }

  proc command_copy {win args} {

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

  proc command_cut {win args} {

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

  proc command_delete {win args} {

    variable data

    set moddata [list]
    if {[lindex $args 0] eq "-moddata"} {
      set args [lassign $args dummy moddata]
    }

    set startPos [$win._t index [lindex $args 0]]
    if {[llength $args] == 1} {
      set endPos [$win._t index $startPos+1c]
    } else {
      set endPos [$win._t index [lindex $args 1]]
    }
    set ranges   [list [$win._t index "$startPos linestart"] [$win._t index "$startPos lineend"]]
    set deldata  [$win._t get $startPos $endPos]
    set do_tags  [list]

    undo_delete            $win $startPos $endPos
    handleDeleteAt0        $win $startPos $endPos
    linemapCheckOnDelete   $win $startPos $endPos
    comments_chars_deleted $win $startPos $endPos do_tags

    $win._t delete $startPos $endPos

    if {[highlightAll $win $ranges 0 $do_tags]} {
      checkAllBrackets $win
    } else {
      checkAllBrackets $win $deldata
    }
    modified $win 1 [list delete $ranges $moddata]

    event generate $win.t <<CursorChanged>>

  }

  proc command_diff {win args} {

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
        $win._t tag lower diff:A:D:$fline _invisible
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
        $win._t tag lower diff:B:D:$fline _invisible
      }
    }
    linemapUpdate $win 1

  }

  proc command_fastdelete {win args} {

    variable data

    set moddata   [list]
    set do_update 1
    set do_undo   1
    while {[string index [lindex $args 0] 0] eq "-"} {
      switch [lindex $args 0] {
        "-moddata" { set args [lassign $args dummy moddata] }
        "-update"  { set args [lassign $args dummy do_update] }
        "-undo"    { set args [lassign $args dummy do_undo] }
      }
    }

    if {[llength $args] == 1} {
      set startPos [$win._t index [lindex $args 0]]
      set endPos   [$win._t index "$startPos+1c"]
      linemapCheckOnDelete $win $startPos
    } else {
      set startPos [$win._t index [lindex $args 0]]
      set endPos   [$win._t index [lindex $args 1]]
      linemapCheckOnDelete $win $startPos $endPos
    }

    if {$do_undo} {
      undo_delete $win $startPos $endPos
    }
    handleDeleteAt0 $win $startPos $endPos

    $win._t delete {*}$args

    if {$do_update} {
      modified $win 1 [list delete [list $startPos $endPos] $moddata]
      event generate $win.t <<CursorChanged>>
    }

  }

  proc command_fastinsert {win args} {

    variable data

    set moddata   [list]
    set do_update 1
    set do_undo   1
    while {[string index [lindex $args 0] 0] eq "-"} {
      switch [lindex $args 0] {
        "-moddata" { set args [lassign $args dummy moddata] }
        "-update"  { set args [lassign $args dummy do_update] }
        "-undo"    { set args [lassign $args dummy do_undo] }
      }
    }

    set startPos [$win._t index [lindex $args 0]]
    set chars    [string length [lindex $args 1]]
    set cursor   [$win._t index insert]

    $win._t insert {*}$args

    set endPos [$win._t index "$startPos+${chars}c"]

    if {$do_undo} {
      undo_insert $win $startPos $chars $cursor
    }
    handleInsertAt0 $win._t $startPos $chars
    set_rmargin     $win $startPos $endPos

    if {$do_update} {
      modified $win 1 [list insert [list $startPos $endPos] $moddata]
      event generate $win.t <<CursorChanged>>
    }

  }

  proc command_fastreplace {win args} {

    variable data

    if {[llength $args] < 3} {
      return -code error "please use at least 3 arguments to $win replace"
    }

    set moddata   [list]
    set do_update 1
    set do_undo   1
    while {[string index [lindex $args 0] 0] eq "-"} {
      switch [lindex $args 0] {
        "-moddata" { set args [lassign $args dummy moddata] }
        "-update"  { set args [lassign $args dummy do_update] }
        "-undo"    { set args [lassign $args dummy do_undo] }
      }
    }

    set startPos [$win._t index [lindex $args 0]]
    set endPos   [$win._t index [lindex $args 1]]
    set datlen   [string length [lindex $args 2]]
    set cursor   [$win._t index insert]

    if {$do_undo} {
      undo_delete $win $startPos $endPos
    }

    set tags [handleReplaceDeleteAt0 $win $startPos $endPos]

    # Perform the text replacement
    $win._t replace {*}$args

    handleReplaceInsert $win $startPos $datlen $tags
    set_rmargin         $win $startPos [$win._t index "$startPos+${datlen}c"]

    if {$do_undo} {
      undo_insert $win $startPos $datlen $cursor
    }

    if {$do_update} {
      modified $win 1 [list replace [list $startPos $endPos] $moddata]
      event generate $win.t <<CursorChanged>>
    }

  }

  proc command_highlight {win args} {

    variable data

    set moddata  [list]
    set insert   0
    set dotags   ""
    set modified 0
    set ranges   [list]

    while {[string index [lindex $args 0] 0] eq "-"} {
      switch [lindex $args 0] {
        "-moddata"  { set args [lassign $args dummy moddata] }
        "-insert"   { set args [lassign $args dummy insert] }
        "-dotags"   { set args [lassign $args dummy dotags] }
        "-modified" { set args [lassign $args dummy]; set modified 1 }
        default     {
          return -code error "Unknown option specified ([lindex $args 0])"
        }
      }
    }

    foreach {start end} $args {
      lappend ranges [$win._t index "$start linestart"] [$win._t index "$end lineend"]
    }

    highlightAll $win $ranges $insert $dotags
    modified $win $modified [list highlight $ranges $moddata]

  }

  proc command_insert {win args} {

    variable data

    if {[llength $args] < 2} {
      return -code error "please use at least 2 arguments to $win insert"
    }

    set moddata [list]
    if {[lindex $args 0] eq "-moddata"} {
      set args [lassign $args dummy moddata]
    }

    set insertPos [$win._t index [lindex $args 0]]
    set cursor    [$win._t index insert]
    set dat       ""
    set do_tags   [list]

    if {[lindex $args 0] eq "end"} {
      set lineStart [$win._t index "$insertPos-1c linestart"]
    } else {
      set lineStart [$win._t index "$insertPos linestart"]
    }

    # Gather the data
    foreach {chars taglist} [lrange $args 1 end] {
      append dat $chars
    }
    set datlen [string length $dat]

    # Add the embedded language tag to the arguments if taglists are present
    if {([llength $args] >= 3) && ([set lang [getLang $win $insertPos]] ne "")} {
      set tag_index 2
      foreach {chars taglist} [lrange $args 1 end] {
        lappend taglist __Lang:$lang
        lset args $tag_index $taglist
        incr tag_index 2
      }
    }

    $win._t insert {*}$args

    set lineEnd [$win._t index "${insertPos}+${datlen}c lineend"]

    undo_insert     $win $insertPos $datlen $cursor
    handleInsertAt0 $win._t $insertPos $datlen
    set_rmargin     $win $insertPos "$insertPos+${datlen}c"
    comments_do_tag $win $insertPos "$insertPos+${datlen}c" do_tags

    # Highlight text and bracket auditing
    if {[highlightAll $win [list $lineStart $lineEnd] 1 $do_tags]} {
      checkAllBrackets $win
    } else {
      checkAllBrackets $win $dat
    }
    modified $win 1 [list insert [list $lineStart $lineEnd] $moddata]

    event generate $win.t <<CursorChanged>>

  }

  # Answers questions about a given index
  proc command_is {win args} {

    if {[llength $args] < 2} {
      return -code error "Incorrect arguments passed to ctext is command"
    }

    lassign $args type extra index

    switch $type {
      escaped   { return [isEscaped $win [$win._t index $extra]] }
      firstchar {
        set index    [$win._t index $extra]
        set prewhite [$win._t tag prevrange __prewhite "$index+1c"]
        return [expr {($prewhite ne "") && [$win._t compare [lindex $prewhite 1] == "$index+1c"]}]
      }
      curly   -
      square  -
      paren   -
      angled  {
        if {[lsearch [list left right any] $extra] == -1} {
          set index [$win._t index $extra]
          set extra "any"
        } else {
          set index [$win._t index $index]
        }
        array set chars [list left L right R any *]
        return [expr [lsearch [$win._t tag names $index] __$type$chars($extra)] != -1]
      }
      double       -
      single       -
      btick        -
      tripledouble -
      triplesingle -
      triplebtick  {
        if {[lsearch [list left right any] $extra] == -1} {
          set index [$win._t index $extra]
          set extra "any"
        } else {
          set index [$win._t index $index]
        }
        array set chars [list double d single s btick b tripledouble D triplesingle S triplebtick B]
        return [isQuote $win $chars($type) $index $extra]
      }
      indent        -
      unindent      -
      reindent      -
      reindentStart {
        return [expr [lsearch [$win._t tag names $extra] __$type] != -1]
      }
      insquare -
      incurly  -
      inparen  -
      inangled {
        if {$index ne ""} {
          upvar 2 $index range
        }
        return [inBlockRange $win [string range $type 2 end] $extra range]
      }
      indouble        -
      insingle        -
      inbtick         -
      intripledouble  -
      intriplesingle  -
      intriplebtick   -
      inblockcomment  -
      inlinecomment   -
      incomment       -
      instring        -
      incommentstring {
        array set procs {
          indouble        DoubleQuote
          insingle        SingleQuote
          inbtick         BackTick
          intripledouble  TripleDoubleQuote
          intriplesingle  TripleSingleQuote
          intriplebtick   TripleBackTick
          inblockcomment  BlockComment
          inlinecomment   LineComment
          incomment       Comment
          instring        String
          incommentstring CommentString
        }
        if {$index ne ""} {
          upvar 2 $index range
          return [in$procs($type)Range $win [$win._t index $extra] range]
        } else {
          return [in$procs($type) $win [$win._t index $extra]]
        }
      }
      inclass         {
        if {$extra eq ""} {
          return -code error "Calling ctext is inclass without specifying a class name"
        }
        if {[lsearch -exact [$win._t tag names $extra] __$index] != -1} {
          set range [$win._t tag prevrange __$extra "[$win._t index $index]+1c"]
          return 1
        } else {
          return 0
        }
      }
      default {
        return -code error "Unsupported is command type specified"
      }
    }

  }

  proc isQuote {win char index side} {

    if {$side eq ""} {
      set side "any"
    } elseif {[lsearch [list left right any] $side] == -1} {
      return -code error "ctext 'is' command $type called with an illegal side value"
    }

    if {[lsearch [$win._t tag names $index] __${char}Quote*] != -1} {
      if {$side eq "any"} {
        return 1
      } else {
        set tag   [lsearch -inline [$win._t tag names $index] __comstr0${char}*]
        set range [$win._t tag prevrange $tag "$index+1c"]
        return [expr {($side eq "left") ? [$win._t compare [lindex $range 0] == $index] : [$win._t compare [lindex $range 1] == "$index+1c"]}]
      }
    }

    return 0

  }

  proc command_replace {win args} {

    variable data

    if {[llength $args] < 3} {
      return -code error "please use at least 3 arguments to $win replace"
    }

    set moddata [list]
    if {[lindex $args 0] eq "-moddata"} {
      set args [lassign $args dummy moddata]
    }

    set startPos [$win._t index [lindex $args 0]]
    set endPos   [$win._t index [lindex $args 1]]
    set dat      ""
    foreach {chars taglist} [lrange $args 2 end] {
      append dat $chars
    }
    set datlen   [string length $dat]
    set deldata  [$win._t get $startPos $endPos]
    set cursor   [$win._t index insert]
    set do_tags  [list]

    undo_delete            $win $startPos $endPos
    comments_chars_deleted $win $startPos $endPos do_tags
    set tags [handleReplaceDeleteAt0 $win $startPos $endPos]

    # Perform the text replacement
    $win._t replace {*}$args

    handleReplaceInsert $win $startPos $datlen $tags
    undo_insert $win $startPos $datlen $cursor

    set lineStart [$win._t index "$startPos linestart"]
    set lineEnd   [$win._t index "$startPos+[expr $datlen + 1]c lineend"]

    if {[llength $do_tags] == 0} {
      comments_do_tag $win $startPos "$startPos+${datlen}c" do_tags
    }
    set_rmargin $win $startPos "$startPos+${datlen}c"

    set comstr [highlightAll $win [list $lineStart $lineEnd] 1 $do_tags]
    if {$comstr == 2} {
      checkAllBrackets $win
    } elseif {$comstr == 1} {
      checkAllBrackets $win [$win._t get $startPos $lineEnd]
    } else {
      checkAllBrackets $win "$deldata$dat"
    }
    modified $win 1 [list replace [list $startPos $endPos] $moddata]

    event generate $win.t <<CursorChanged>>

  }

  proc command_paste {win args} {

    variable data

    set moddata [list]
    if {[lindex $args 0] eq "-moddata"} {
      set args [lassign $args dummy moddata]
    }

    set insertPos [$win._t index insert]
    set datalen   [string length [clipboard get]]

    tk_textPaste $win

    handleInsertAt0 $win._t $insertPos $datalen
    modified $win 1 [list insert [list $insertPos [$win._t index "$insertPos+${datalen}c"]] $moddata]
    event generate $win.t <<CursorChanged>>

  }

  proc command_peer {win args} {

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

  # This command helps process any syntax highlighting functionality of this widget.
  proc command_syntax {win args} {

    variable data

    set args [lassign $args subcmd]

    switch $subcmd {
      add              { $win._t tag add __[lindex $args 0] {*}[lrange $args 1 end] }
      addclass         { addHighlightClass             $win {*}$args }
      addwords         { addHighlightKeywords          $win {*}$args }
      addregexp        { addHighlightRegexp            $win {*}$args }
      addcharstart     { addHighlightWithOnlyCharStart $win {*}$args }
      addlinecomments  { addLineCommentPatterns        $win {*}$args }
      addblockcomments { addBlockCommentPatterns       $win {*}$args }
      addstrings       { addStringPatterns             $win {*}$args }
      addembedlang     { addEmbedLangPattern           $win {*}$args }
      search           { highlightSearch               $win {*}$args }
      delete           {
        switch [lindex $args 0] {
          class   -
          classes {
            foreach class [lrange $args 1 end] {
              deleteHighlightClass $win $class
            }
          }
          command  -
          commands {
            foreach command [lrange $args 1 end] {
              deleteHighlightCommand $win $command
            }
          }
          all {
            foreach class [getHighlightClasses $win] {
              deleteHighlightClass $win $class
            }
            deleteHighlightCommand $win *
          }
          default {
            return -code error "Unknown syntax delete specifier ([lindex $args 0])"
          }
        }
      }
      classes   { return [getHighlightClasses $win {*}$args] }
      clear     {
        switch [llength $args] {
          0 {
            foreach class [getHighlightClasses $win] {
              $win tag remove __$class 1.0 end
            }
          }
          1 {
            $win tag remove __[lindex $args 0] 1.0 end
          }
          2 {
            foreach class [getHighlightClasses $win] {
              $win tag remove __$class {*}$args
            }
          }
          3 {
            $win tag remove __[lindex $args 0] {*}[lrange $args 1 end]
          }
          default {
            return -code error "Invalid arguments passed to syntax clear command"
          }
        }
      }
      contains  { return [expr [lsearch [$win._t tag names [lindex $args 1]] __[lindex $args 0]] != -1] }
      nextrange { return [$win tag nextrange __[lindex $args 0] {*}[lrange $args 1 end]] }
      prevrange { return [$win tag prevrange __[lindex $args 0] {*}[lrange $args 1 end]] }
      ranges    { return [$win tag ranges __[lindex $args 0]] }
      highlight {
        set i 0
        while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }
        array set opts {
          -moddata  {}
          -insert   0
          -dotags   {}
          -modified 0
        }
        array set opts [lrange $args 0 [expr $i - 1]]
        set ranges [list]
        foreach {start end} [lrange $args $i end] {
          lappend ranges [$win._t index "$start linestart"] [$win._t index "$end lineend"]
        }
        highlightAll $win $ranges $opts(-insert) $opts(-dotags)
        modified $win $opts(-modified) [list highlight $ranges $opts(-moddata)]
      }
      configure { return [$win._t tag configure __[lindex $args 0] {*}[lrange $args 1 end]] }
      cget      { return [$win._t tag cget      __[lindex $args 0] {*}[lrange $args 1 end]] }
      default   {
        return -code error [format "%s ($subcmd)" [msgcat::mc "Unknown ctext syntax subcommand"]]
      }
    }

  }

  # We need to guarantee that embedded language tags are always listed as lowest
  # priority, so if someone calls the lower tag subcommand, we need to make sure
  # that it won't be placed lower than an embedded language tag.
  proc command_tag {win args} {

    variable range_cache

    set args [lassign $args subcmd]

    switch $subcmd {
      place {
        set args [lassign $args tag]
        if {[llength $args] == 0} {
          array set opts [$win._t tag configure $tag]
          if {$opts(-background) ne ""} {
            $win._t tag lower $tag _visibleH
          } elseif {($opts(-foreground) ne "") || ($opts(-font) ne "")} {
            $win._t tag lower $tag _visibleL
          } else {
            $win._t tag lower $tag _invisible
          }
        } else {
          switch [lindex $args 0] {
            visible1  { $win._t tag lower $tag _visibleH }
            visible2  { $win._t tag raise $tag _visibleL }
            visible3  { $win._t tag lower $tag _visibleL }
            visible4  { $win._t tag raise $tag _invisible }
            invisible { $win._t tag lower $tag _invisible }
            priority  { $win._t tag raise $tag _visibleH }
            default   { return -code error "Invalid tag place value ([lindex $args 0])" }
          }
        }
      }
      nextrange -
      prevrange {
        set args0        [set args1 [lassign $args tag]]
        set indent_tags  [list __indent __unindent __reindent __reindentStart]
        set bracket_tags [list __curlyL __curlyR __squareL __squareR __parenL __parenR __angledL __angledR]
        if {[string map [list $tag {}] $indent_tags] ne $indent_tags} {
          if {$subcmd eq "nextrange"} {
            lassign [$win._t tag nextrange ${tag}0 {*}$args0] s0 e0
            while {($s0 ne "") && ([inCommentString $win $s0] || [isEscaped $win $s0])} {
              lset args0 0 $e0
              lassign [$win._t tag nextrange ${tag}0 {*}$args0] s0 e0
            }
            lassign [$win._t tag nextrange ${tag}1 {*}$args1] s1 e1
            while {($s1 ne "") && ([inCommentString $win $s1] || [isEscaped $win $s1])} {
              lset args1 0 $e1
              lassign [$win._t tag nextrange ${tag}0 {*}$args1] s1 e1
            }
          } else {
            lassign [$win._t tag prevrange ${tag}0 {*}$args0] s0 e0
            while {($s0 ne "") && ([inCommentString $win $s0] || [isEscaped $win $s0])} {
              lset args0 0 $s0
              lassign [$win._t tag prevrange ${tag}0 {*}$args0] s0 e0
            }
            lassign [$win._t tag prevrange ${tag}1 {*}$args1] s1 e1
            while {($s1 ne "") && ([inCommentString $win $s1] || [isEscaped $win $s1])} {
              lset args1 0 $s1
              lassign [$win._t tag prevrange ${tag}0 {*}$args1] s1 e1
            }
          }
          if {$s0 eq ""} {
            if {$s1 eq ""} {
              return ""
            } else {
              return [list $s1 $e1]
            }
          } else {
            if {$s1 eq ""} {
              return [list $s0 $e0]
            } else {
              if {[$win._t compare $s0 [expr {($subcmd eq "nextrange") ? "<" : ">"}] $s1]} {
                return [list $s0 $e0]
              } else {
                return [list $s1 $e1]
              }
            }
          }
        } elseif {[string map [list $tag {}] $bracket_tags] ne $bracket_tags} {
          if {$subcmd eq "nextrange"} {
            lassign [$win._t tag nextrange $tag {*}$args0] s e
            while {($s ne "") && ([inCommentString $win $s] || ([isEscaped $win $s] && ([$win._t index "$s+1c"] eq $e)))} {
              lset args0 0 $e
              lassign [$win._t tag nextrange $tag {*}$args0] s e
            }
          } else {
            lassign [$win._t tag prevrange $tag {*}$args0] s e
            if {($s ne "") && ![inCommentString $win $s] && [isEscaped $win $s] && [$win._t compare "$s+1c" == [lindex $args0 0]]} {
              lassign [$win._t tag prevrange $tag $s {*}[lrange $args0 1 end]] s e
            }
            while {($s ne "") && ([inCommentString $win $s] || ([isEscaped $win $s] && ([$win._t index "$s+1c"] eq $e)))} {
              lset args0 0 $s
              lassign [$win._t tag prevrange $tag {*}$args0] s e
            }
          }
          if {$s eq ""} {
            return ""
          } elseif {[isEscaped $win $s]} {
            return [list [$win._t index "$s+1c"] $e]
          } else {
            return [list $s $e]
          }
        } else {
          return [$win._t tag $subcmd $tag {*}$args0]
        }
      }
      ranges {
        set tag          [lindex $args 0]
        set bracket_tags [list __curlyL __curlyR __squareL __squareR __parenL __parenR __angledL __angledR]
        if {[string map [list $tag {}] $bracket_tags] ne $bracket_tags} {
          if {![info exists range_cache($win,$tag)]} {
            set range_cache($win,$tag) [list]
            foreach {s e} [$win._t tag ranges $tag] {
              if {![inCommentString $win $s]} {
                if {![isEscaped $win $s] || ([set s [$win._t index "$s+1c"]] ne $e)} {
                  lappend range_cache($win,$tag) $s $e
                }
              }
            }
          }
          return $range_cache($win,$tag)
        } else {
          return [$win._t tag ranges $tag]
        }
      }
      default {
        return [$win._t tag $subcmd {*}$args]
      }
    }

  }

  proc command_edit {win args} {

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
        undo $win
      }
      redo {
        redo $win
      }
      undoable {
        return [expr $data($win,config,undo_hist_size) > 0]
      }
      redoable {
        return [expr [llength $data($win,config,redo_hist)] > 0]
      }
      separator {
        if {[llength $data($win,config,undo_hist)] > 0} {
          undo_separator $win
        }
      }
      undocount {
        return $data($win,config,undo_sep_count)
      }
      reset {
        set data($win,config,undo_hist)      [list]
        set data($win,config,undo_hist_size) 0
        set data($win,config,undo_sep_next)  -1
        set data($win,config,undo_sep_last)  -1
        set data($win,config,undo_sep_size)  0
        set data($win,config,undo_sep_count) 0
        set data($win,config,redo_hist)      [list]
        set data($win,config,modified)       false
      }
      cursorhist {
        return [undo_get_cursor_hist $win]
      }
      default {
        return [uplevel 1 [linsert $args 0 $win._t $cmd]]
      }
    }

  }

  proc command_gutter {win args} {

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
          if {[info exists sym_opts(-fg)]} {
            set data($win,gutterfg,$gutter_tag) $sym_opts(-fg)
          }
          if {[info exists sym_opts(-onenter)]} {
            $win.l bind $gutter_tag <Enter> [list ctext::execute_gutter_cmd $win %y $sym_opts(-onenter)]
          }
          if {[info exists sym_opts(-onleave)]} {
            $win.l bind $gutter_tag <Leave> [list ctext::execute_gutter_cmd $win %y $sym_opts(-onleave)]
          }
          if {[info exists sym_opts(-onclick)]} {
            $win.l bind $gutter_tag <Button-1> [list ctext::execute_gutter_cmd $win %y $sym_opts(-onclick)]
          }
          if {[info exists sym_opts(-onshiftclick)]} {
            $win.l bind $gutter_tag <Shift-Button-1> [list ctext::execute_gutter_cmd $win %y $sym_opts(-onshiftclick)]
          }
          if {[info exists sym_opts(-oncontrolclick)]} {
            $win.l bind $gutter_tag <Control-Button-1> [list ctext::execute_gutter_cmd $win %y $sym_opts(-oncontrolclick)]
          }
          lappend gutter_tags $gutter_tag
          array unset sym_opts
        }
        lappend data($win,config,gutters) [list $gutter_name $gutter_tags 0]
        linemapUpdate $win 1
      }
      destroy {
        set gutter_name [lindex $args 0]
        if {[set index [lsearch -index 0 $data($win,config,gutters) $gutter_name]] != -1} {
          $win._t tag delete {*}[lindex $data($win,config,gutters) $index 1]
          set data($win,config,gutters) [lreplace $data($win,config,gutters) $index $index]
          array unset data $win,gutterfg,gutter:$gutter_name:*
          linemapUpdate $win 1
        }
      }
      hide {
        set gutter_name [lindex $args 0]
        if {[set index [lsearch -index 0 $data($win,config,gutters) $gutter_name]] != -1} {
          if {[llength $args] == 1} {
            return [lindex $data($win,config,gutters) $index 2]
          } else {
            lset data($win,config,gutters) $index 2 [lindex $args 1]
            linemapUpdate $win 1
          }
        } elseif {[llength $args] == 1} {
          return -code error "Unable to find gutter name ($gutter_name)"
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
            array unset data $win,gutterfg,gutter:$gutter_name:$symname:*
            lset data($win,config,gutters) $gutter_index 1 $gutters
            set update_needed 1
          }
        }
        if {$update_needed} {
          linemapUpdate $win 1
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
          linemapUpdate $win 1
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
          linemapUpdate $win 1
        }
      }
      cget {
        lassign $args gutter_name sym_name opt
        if {[set index [lsearch -exact -index 0 $data($win,config,gutters) $gutter_name]] == -1} {
          return -code error "Unable to find gutter name ($gutter_name)"
        }
        if {[set gutter_tag [lsearch -inline -glob [lindex $data($win,config,gutters) $index 1] "gutter:$gutter_name:$sym_name:*"]] eq ""} {
          return -code error "Unknown symbol ($sym_name) specified"
        }
        switch $opt {
          -symbol         { return [lindex [split $gutter_tag :] 3] }
          -fg             { return [expr {[info exists data($win,gutterfg,$gutter_tag)] ? $data($win,gutterfg,$gutter_tag) : ""}] }
          -onenter        { return [lrange [$win.l bind $gutter_tag <Enter>] 0 end-1] }
          -onleave        { return [lrange [$win.l bind $gutter_tag <Leave>] 0 end-1] }
          -onclick        { return [lrange [$win.l bind $gutter_tag <Button-1>] 0 end-1] }
          -onshiftclick   { return [lrange [$win.l bind $gutter_tag <Shift-Button-1>] 0 end-1] }
          -oncontrolclick { return [lrange [$win.l bind $gutter_tag <Control-Button-1>] 0 end-1] }
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
            if {[info exists data($win,gutterfg,$gutter_tag)]} {
              lappend symopts -fg $data($win,gutterfg,$gutter_tag)
            }
            if {[set cmd [lrange [$win.l bind $gutter_tag <Enter>] 0 end-1]] ne ""} {
              lappend symopts -onenter $cmd
            }
            if {[set cmd [lrange [$win.l bind $gutter_tag <Leave>] 0 end-1]] ne ""} {
              lappend symopts -onleave $cmd
            }
            if {[set cmd [lrange [$win.l bind $gutter_tag <Button-1>] 0 end-1]] ne ""} {
              lappend symopts -onclick $cmd
            }
            if {[set cmd [lrange [$win.l bind $gutter_tag <Shift-Button-1>] 0 end-1]] ne ""} {
              lappend symopts -onshiftclick $cmd
            }
            if {[set cmd [lrange [$win.l bind $gutter_tag <Control-Button-1>] 0 end-1]] ne ""} {
              lappend symopts -oncontrolclick $cmd
            }
            lappend gutters $symname $symopts
          }
          return $gutters
        } else {
          set args          [lassign $args symname]
          set update_needed 0
          if {[set gutter_tag [lsearch -inline -glob [lindex $data($win,config,gutters) $index 1] "gutter:$gutter_name:$symname:*"]] eq ""} {
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
              -fg {
                if {$value ne ""} {
                  set data($win,gutterfg,$gutter_tag) $value
                } else {
                  array unset data $win,gutterfg,$gutter_tag
                }
                set update_needed 1
              }
              -onenter {
                $win.l bind $gutter_tag <Enter> [list ctext::execute_gutter_cmd $win %y $value]
              }
              -onleave {
                $win.l bind $gutter_tag <Leave> [list ctext::execute_gutter_cmd $win %y $value]
              }
              -onclick {
                $win.l bind $gutter_tag <Button-1> [list ctext::execute_gutter_cmd $win %y $value]
              }
              -onshiftclick {
                $win.l bind $gutter_tag <Shift-Button-1> [list ctext::execute_gutter_cmd $win %y $value]
              }
              -oncontrolclick {
                $win.l bind $gutter_tag <Control-Button-1> [list ctext::execute_gutter_cmd $win %y $value]
              }
              default {
                return -code error "Unknown gutter option ($opt) specified"
              }
            }
          }
          if {$update_needed} {
            linemapUpdate $win 1
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

  proc execute_gutter_cmd {win y cmd} {

    # Get the line of the text widget
    set line [lindex [split [$win.t index @0,$y] .] 0]

    # Execute the command
    uplevel #0 [list {*}$cmd $win $line]

  }

  proc getAutoMatchChars {win lang} {

    variable data

    set chars [list]

    foreach name [array names data $win,config,matchChar,$lang,*] {
      lappend chars [lindex [split $name ,] 4]
    }

    return $chars

  }

  proc setAutoMatchChars {win lang matchChars} {

    variable data

    # Clear the matchChars
    catch { array unset data $win,config,matchChar,$lang,* }

    # Remove the brackets
    foreach type [list curly square paren angled] {
      catch { $win._t tag delete missing:$type }
    }

    # Set the matchChars
    foreach matchChar $matchChars {
      set data($win,config,matchChar,$lang,$matchChar) 1
    }

    # Set the bracket auditing tags
    foreach matchChar [list curly square paren angled] {
      if {[info exists data($win,config,matchChar,$lang,$matchChar)]} {
        $win._t tag configure missing:$matchChar -background $data($win,config,-matchaudit_bg)
        $win._t tag raise missing:$matchChar _visibleH
      }
    }

  }

  proc matchBracket {win} {

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
    set lang [getLang $win $pos]

    switch -- [$win get $pos] {
      "\}" { matchPair  $win $lang $pos curlyL }
      "\{" { matchPair  $win $lang $pos curlyR }
      "\]" { matchPair  $win $lang $pos squareL }
      "\[" { matchPair  $win $lang $pos squareR }
      "\)" { matchPair  $win $lang $pos parenL }
      "\(" { matchPair  $win $lang $pos parenR }
      "\>" { matchPair  $win $lang $pos angledL }
      "\<" { matchPair  $win $lang $pos angledR }
      "\"" { matchQuote $win $lang $pos comstr0d double }
      "'"  { matchQuote $win $lang $pos comstr0s single }
      "`"  { matchQuote $win $lang $pos comstr0b btick }
    }

  }

  ######################################################################
  # Returns the index of the bracket type previous to the given index.
  proc getPrevBracket {win stype {index insert}} {

    lassign [$win tag prevrange __$stype $index] first last

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
  proc getNextBracket {win stype {index insert}} {

    lassign [$win tag prevrange __$stype "$index+1c"] first last

    if {($last ne "") && [$win compare "$index+1c" < $last]} {
      return [$win index "$index+1c"]
    } else {
      lassign [$win tag nextrange __$stype "$index+1c"] first last
      return $first
    }

  }

  ######################################################################
  # Returns the index of the matching bracket type where 'type' is the
  # type of bracket to find.  For example, if the current bracket is
  # a left square bracket, call this procedure as:
  #   getMatchBracket $txt squareR
  proc getMatchBracket {win stype {index insert}} {

    set count 1

    if {[string index $stype end] eq "R"} {

      set otype [string range $stype 0 end-1]L

      lassign [$win tag nextrange __$stype "$index+1c"] sfirst slast
      lassign [$win tag prevrange __$otype $index]      ofirst olast
      set ofirst "$index+1c"

      if {($olast eq "") || [$win compare $olast < $index]} {
        lassign [$win tag nextrange __$otype $index] dummy olast
      }

      while {($olast ne "") && ($slast ne "")} {
        if {[$win compare $slast < $olast]} {
          if {[incr count -[$win count -chars $sfirst $slast]] <= 0} {
            return "$slast-[expr 1 - $count]c"
          }
          lassign [$win tag nextrange __$stype "$slast+1c"] sfirst slast
        } else {
          incr count [$win count -chars $ofirst $olast]
          lassign [$win tag nextrange __$otype "$olast+1c"] ofirst olast
        }
      }

      while {$slast ne ""} {
        if {[incr count -[$win count -chars $sfirst $slast]] <= 0} {
          return "$slast-[expr 1 - $count]c"
        }
        lassign [$win tag nextrange __$stype "$slast+1c"] sfirst slast
      }

    } else {

      set otype [string range $stype 0 end-1]R

      lassign [$win tag prevrange __$stype $index] sfirst slast
      lassign [$win tag prevrange __$otype $index] ofirst olast

      if {($olast ne "") && [$win compare $olast >= $index]} {
        set olast $index
      }

      while {($ofirst ne "") && ($sfirst ne "")} {
        if {[$win compare $sfirst > $ofirst]} {
          if {[incr count -[$win count -chars $sfirst $slast]] <= 0} {
            return "$sfirst+[expr 0 - $count]c"
          }
          lassign [$win tag prevrange __$stype $sfirst] sfirst slast
        } else {
          incr count [$win count -chars $ofirst $olast]
          lassign [$win tag prevrange __$otype $ofirst] ofirst olast
        }
      }

      while {$sfirst ne ""} {
        if {[incr count -[$win count -chars $sfirst $slast]] <= 0} {
          return "$sfirst+[expr 0 - $count]c"
        }
        lassign [$win tag prevrange __$stype $sfirst] sfirst slast
      }

    }

    return ""

  }

  proc matchPair {win lang pos type} {

    variable data

    if {![info exists data($win,config,matchChar,$lang,[string range $type 0 end-1])] || \
         [inCommentString $win $pos]} {
      return
    }

    if {[set pos [getMatchBracket $win $type [$win index $pos]]] ne ""} {
      $win tag add matchchar $pos
    }

  }

  proc matchQuote {win lang pos tag type} {

    variable data

    if {![info exists data($win,config,matchChar,$lang,$type)]} {
      return
    }

    # Get the actual tag to check for
    set tag [lsearch -inline [$win tag names $pos] __$tag*]

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

  proc checkAllBrackets {win {str ""}} {

    variable data

    # If the mismcatching char option is cleared, don't continue
    if {!$data($win,config,-matchaudit)} {
      return
    }

    # We don't have support for bracket auditing in embedded languages as of yet
    set lang ""

    # If a string was supplied, only perform bracket check for brackets found in string
    if {$str ne ""} {
      if {[info exists data($win,config,matchChar,$lang,curly)]  && ([string map {\{ {} \} {} \\ {}} $str] ne $str)} { checkBracketType $win curly }
      if {[info exists data($win,config,matchChar,$lang,square)] && ([string map {\[ {} \] {} \\ {}} $str] ne $str)} { checkBracketType $win square }
      if {[info exists data($win,config,matchChar,$lang,paren)]  && ([string map {( {} ) {} \\ {}}   $str] ne $str)} { checkBracketType $win paren }
      if {[info exists data($win,config,matchChar,$lang,angled)] && ([string map {< {} > {} \\ {}}   $str] ne $str)} { checkBracketType $win angled }

    # Otherwise, check all of the brackets
    } else {
      foreach type [list square curly paren angled] {
        if {[info exists data($win,config,matchChar,$lang,$type)]} {
          checkBracketType $win $type
        }
      }
    }

  }

  proc checkBracketType {win stype} {

    variable data

    # Clear missing
    $win._t tag remove missing:$stype 1.0 end

    set count   0
    set other   ${stype}R
    set olist   [lassign [$win.t tag ranges __$other] ofirst olast]
    set missing [list]

    # Perform count for all code containing left stypes
    foreach {sfirst slast} [$win.t tag ranges __${stype}L] {
      while {($ofirst ne "") && [$win.t compare $sfirst > $ofirst]} {
        if {[incr count -[$win._t count -chars $ofirst $olast]] < 0} {
          lappend missing "$olast+${count}c" $olast
          set count 0
        }
        set olist [lassign $olist ofirst olast]
      }
      if {$count == 0} {
        set start $sfirst
      }
      incr count [$win._t count -chars $sfirst $slast]
    }

    # Perform count for all right types after the above code
    while {$ofirst ne ""} {
      if {[incr count -[$win._t count -chars $ofirst $olast]] < 0} {
        lappend missing "$olast+${count}c" $olast
        set count 0
      }
      set olist [lassign $olist ofirst olast]
    }

    # Highlight all brackets that are missing right stypes
    while {$count > 0} {
      lappend missing $start "$start+1c"
      set start [getNextBracket $win ${stype}L $start]
      incr count -1
    }

    # Highlight all brackets that are missing left stypes
    catch { $win._t tag add missing:$stype {*}$missing }

  }

  ######################################################################
  # Places the cursor on the next or previous mismatching bracket and
  # makes it visible in the editing window.  If the -check option is
  # set, returns 0 to indicate that the given option is invalid; otherwise,
  # returns 1.
  proc gotoBracketMismatch {win dir args} {

    variable data

    # If the current text buffer was not highlighted, do it now
    if {!$data($win,config,-matchaudit)} {
      return 0
    }

    array set opts {
      -check 0
    }
    array set opts $args

    # Find the previous/next index
    if {$dir eq "next"} {
      set index end
      foreach type [list square curly paren angled] {
        lassign [$win._t tag nextrange missing:$type "insert+1c"] first
        if {($first ne "") && [$win._t compare $first < $index]} {
          set index $first
        }
      }
    } else {
      set index 1.0
      foreach type [list square curly paren angled] {
        lassign [$win._t tag prevrange missing:$type insert] first
        if {($first ne "") && [$win._t compare $first > $index]} {
          set index $first
        }
      }
    }

    # Make sure that the current bracket is in view
    if {[lsearch [$win._t tag names $index] missing:*] != -1} {
      if {!$opts(-check)} {
        ::tk::TextSetCursor $win.t $index
        $win._t see $index
      }
      return 1
    }

    return 0

  }

  proc getLang {win index} {

    return [lindex [split [lindex [$win tag names $index] 0] =] 1]

  }

  proc clearCommentStringPatterns {win} {

    variable data

    array unset data $win,config,csl_patterns,*
    array unset data $win,csl_char_tags,*
    array unset data $win,lc_char_tags,*

    set data($win,config,csl_array)     [list]
    set data($win,config,csl_markers)   [list]
    set data($win,config,csl_tag_pair)  [list]
    set data($win,config,csl_tags)      [list]

  }

  proc addBlockCommentPatterns {win lang patterns} {

    variable data

    set start_patterns [list]
    set end_patterns   [list]

    foreach pattern $patterns {
      lappend start_patterns [lindex $pattern 0]
      lappend end_patterns   [lindex $pattern 1]
    }

    if {[llength $patterns] > 0} {
      lappend data($win,config,csl_patterns,$lang) __cCommentStart:$lang "" ([join $start_patterns |])
      lappend data($win,config,csl_patterns,$lang) __cCommentEnd:$lang   "" ([join $end_patterns   |])
    }

    array set tags [list __cCommentStart:${lang}0 1 __cCommentStart:${lang}1 1 __cCommentEnd:${lang}0 1 __cCommentEnd:${lang}1 1 __comstr1c0 1 __comstr1c1 1]

    if {[llength $patterns] > 0} {
      array set theme $data($win,config,-theme)
      $win tag configure __comstr1c0 -foreground $theme(comments)
      $win tag configure __comstr1c1 -foreground $theme(comments)
      $win tag lower __comstr1c0 _visibleH
      $win tag lower __comstr1c1 _visibleH
      foreach tag [list __cCommentStart:${lang}0 __cCommentStart:${lang}1 __cCommentEnd:${lang}0 __cCommentEnd:${lang}1] {
        $win tag configure $tag
        $win tag lower $tag _invisible
      }
      lappend data($win,config,csl_char_tags,$lang) __cCommentStart:$lang __cCommentEnd:$lang
      lappend data($win,config,csl_array)           {*}[array get tags]
      lappend data($win,config,csl_markers)         __cCommentStart:${lang}0 __cCommentStart:${lang}1 __cCommentEnd:${lang}0 __cCommentEnd:${lang}1
      lappend data($win,config,csl_tag_pair)        __cCommentStart:$lang __comstr1c
      lappend data($win,config,csl_tags)            __comstr1c0 __comstr1c1
    } else {
      catch { $win tag delete {*}[array names tags] }
    }

  }

  proc addLineCommentPatterns {win lang patterns} {

    variable data

    if {[llength $patterns] > 0} {
      lappend data($win,config,csl_patterns,$lang) __lCommentStart:$lang "" ([join $patterns |])
    }

    array set tags [list __lCommentStart:${lang}0 1 __lCommentStart:${lang}1 1 __comstr1l 1]

    if {[llength $patterns] > 0} {
      array set theme $data($win,config,-theme)
      $win tag configure __comstr1l -foreground $theme(comments)
      $win tag lower __comstr1l _visibleH
      foreach tag [list __lCommentStart:${lang}0 __lCommentStart:${lang}1] {
        $win tag configure $tag
        $win tag lower $tag _invisible
      }
      lappend data($win,config,lc_char_tags,$lang) __lCommentStart:$lang
      lappend data($win,config,csl_array)          {*}[array get tags]
      lappend data($win,config,csl_markers)        __lCommentStart:${lang}0 __lCommentStart:${lang}1
      lappend data($win,config,csl_tags)           __comstr1l
    } else {
      catch { $win tag delete {*}[array names tags] }
    }

  }

  proc addStringPatterns {win lang types} {

    variable data

    set csl_patterns [list]

    # Combine types
    array set type_array [list]
    foreach type $types { set type_array($type) 1 }
    foreach {val pat1 pat2} [list double (\") (\"\"\") single (') (''') btick (`) (```)] {
      set c [string index $val 0]
      if {[info exists type_array($val)]} {
        if {[info exists type_array(triple$val)]} {
          lappend csl_patterns "__${c}Quote:$lang" "__[string toupper $c]Quote:$lang" $pat1|$pat2
          unset type_array(triple$val)
        } else {
          lappend csl_patterns "__${c}Quote:$lang" "" $pat1
        }
        unset type_array($val)
      } elseif {[info exists type_array(triple$val)]} {
        lappend csl_patterns "__[string toupper $c]Quote:$lang" "" $pat2
        unset type_array(triple$val)
      }
    }
    foreach type [array names type_array] {
      lappend csl_patterns "__sQuote:$lang" "" $type
    }

    array set tags [list \
      __sQuote:${lang}0 1 __sQuote:${lang}1 1 \
      __SQuote:${lang}0 1 __SQuote:${lang}1 1 \
      __dQuote:${lang}0 1 __dQuote:${lang}1 1 \
      __DQuote:${lang}0 1 __DQuote:${lang}1 1 \
      __bQuote:${lang}0 1 __bQuote:${lang}1 1 \
      __BQuote:${lang}0 1 __BQuote:${lang}1 1 \
      __comstr0s0 1 __comstr0s1 1 \
      __comstr0S0 1 __comstr0S1 1 \
      __comstr0d0 1 __comstr0d1 1 \
      __comstr0D0 1 __comstr0D1 1 \
      __comstr0b0 1 __comstr0b1 1 \
      __comstr0B0 1 __comstr0B1 1 \
    ]

    array set comstr [list \
      __dQuote:$lang __comstr0d \
      __DQuote:$lang __comstr0D \
      __sQuote:$lang __comstr0s \
      __SQuote:$lang __comstr0S \
      __bQuote:$lang __comstr0b \
      __BQuote:$lang __comstr0B \
    ]

    if {[llength $types] > 0} {
      array set theme $data($win,config,-theme)
      foreach {tag1 tag2 pattern} $csl_patterns {
        foreach rb {0 1} {
          $win tag configure $comstr($tag1)$rb -foreground $theme(strings)
          $win tag configure $tag1$rb
          $win tag lower $comstr($tag1)$rb _visibleH
          $win tag lower $tag1$rb _invisible
          lappend data($win,config,csl_tags) $comstr($tag1)$rb
        }
        lappend data($win,config,csl_char_tags,$lang) $tag1
        if {$tag2 ne ""} {
          foreach rb {0 1} {
            $win tag configure $comstr($tag2)$rb -foreground $theme(strings)
            $win tag configure $tag2$rb
            $win tag lower $comstr($tag2)$rb _visibleH
            $win tag lower $tag2$rb _invisible
          }
          lappend data($win,config,csl_char_tags,$lang) $tag2
          lappend data($win,config,csl_tags)            $comstr($tag2)$rb
        }
      }
      lappend data($win,config,csl_patterns,$lang)  {*}$csl_patterns
      lappend data($win,config,csl_array)           {*}[array get tags]
      lappend data($win,config,csl_markers)         __dQuote:${lang}0 __dQuote:${lang}1 __DQuote:${lang}0 __DQuote:${lang}1 \
                                                    __sQuote:${lang}0 __sQuote:${lang}1 __SQuote:${lang}0 __SQuote:${lang}1 \
                                                    __bQuote:${lang}0 __bQuote:${lang}1 __BQuote:${lang}0 __BQuote:${lang}1
      lappend data($win,config,csl_tag_pair)        {*}[array get comstr]
    } else {
      catch { $win tag delete {*}[array names tags] }
    }

  }

  proc addEmbedLangPattern {win lang patterns} {

    variable data

    # Coallesce the start/end patterns
    foreach pattern $patterns {
      lassign $pattern spat epat
      lappend start_patterns $spat
      lappend end_patterns $epat
    }

    lappend data($win,config,csl_patterns,) __LangStart:$lang "" ([join $start_patterns |]) __LangEnd:$lang "" ([join $end_patterns |])
    lappend data($win,config,langs) $lang

    array set theme $data($win,config,-theme)

    $win tag configure __Lang:$lang
    $win tag lower     __Lang:$lang _invisible
    $win tag configure __Lang=$lang -background $theme(embedded)
    $win tag lower     __Lang=$lang _invisible

    lappend data($win,config,csl_char_tags,) __LangStart:$lang __LangEnd:$lang
    lappend data($win,config,csl_array)      __LangStart:${lang}0 1 __LangStart:${lang}1 1 __LangEnd:${lang}0 1 __LangEnd:${lang}1 1 __Lang:$lang 1
    lappend data($win,config,csl_markers)    __LangStart:${lang}0 __LangStart:${lang}1 __LangEnd:${lang}0 __LangEnd:${lang}1
    lappend data($win,config,csl_tag_pair)   __LangStart:$lang __Lang=$lang

  }

  proc highlightAll {win lineranges ins {do_tag ""}} {

    variable data
    variable range_cache

    array set csl_array $data($win,config,csl_array)

    # Delete all of the tags not associated with comments and strings that we created
    foreach tag [$win._t tag names] {
      if {([string range $tag 0 1] eq "__") && ![info exists csl_array($tag)]} {
        $win._t tag remove $tag {*}$lineranges
      }
    }

    # Clear the caches
    array unset range_cache $win,*

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

    # Tag escapes and prewhite characters
    foreach {linestart lineend} $ranges {
      escapes  $win $linestart $lineend
      prewhite $win $linestart $lineend
    }

    # If highlighting is not specified, stop here
    if {!$data($win,config,-highlight)} { return 0 }

    # Tag comments and strings
    set all [comments $win $ranges $do_tag]

    # Update the language backgrounds for embedded languages
    updateLangBackgrounds $win

    if {$all == 2} {
      foreach tag [$win._t tag names] {
        if {([string index $tag 0] eq "__") && ($tag ne "__escape") && ![info exists csl_array($tag)]} {
          $win._t tag remove $tag [lindex $lineranges 1] end
        }
      }
      highlight $win [lindex $lineranges 0] end $ins
    } else {
      foreach {linestart lineend} $ranges {
        highlight $win $linestart $lineend $ins
      }
    }

    if {$all} {
      event generate $win.t <<StringCommentChanged>>
    }

    return $all

  }

  proc getTagInRange {win tag start end} {

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

  proc comments_chars_deleted {win start end pdo_tags} {

    variable data

    upvar $pdo_tags do_tags

    foreach tag $data($win,config,csl_markers) {
      lassign [$win tag nextrange $tag $start] tag_start tag_end
      if {($tag_start ne "") && [$win compare $tag_start < $end]} {
        lappend do_tags $tag 1
        return
      }
    }

  }

  proc comments_do_tag {win start end pdo_tags} {

    upvar $pdo_tags do_tags

    if {($do_tags eq "") && [inLineComment $win $start] && ([string first \n [$win get $start $end]] != -1)} {
      lappend do_tags "stuff" 1
    }

  }

  proc comments {win ranges do_tags} {

    variable data

    array set tag_changed $do_tags
    set retval 0

    # Go through each language
    foreach lang $data($win,config,langs) {

      # If a csl_pattern does not exist for this language, go to the next language
      if {![info exists data($win,config,csl_patterns,$lang)]} continue

      # Get the ranges to check
      if {$lang eq ""} {
        set lranges [list 1.0 end]
      } else {
        set lranges [$win._t tag ranges "__Lang:$lang"]
      }

      # Perform highlighting for each range
      foreach {langstart langend} $lranges {

        # Go through each range
        foreach {start end} $ranges {

          if {[$win._t compare $start > $langend] || [$win._t compare $langstart > $end]} continue
          if {[$win._t compare $start <= $langstart]} { set pstart $langstart } else { set pstart $start }
          if {[$win._t compare $langend <= $end]}     { set pend   $langend   } else { set pend   $end }

          set lines    [split [$win._t get $pstart $pend] \n]
          set startrow [lindex [split $pstart .] 0]

          # First, tag all string/comment patterns found between start and end
          foreach {tag1 tag2 pattern} $data($win,config,csl_patterns,$lang) {
            array set indices [list ${tag1}0 {} ${tag1}1 {}]
            if {$tag2 ne ""} {
              array set indices [list ${tag2}0 {} ${tag2}1 {}]
            }
            set i   0
            set row $startrow
            foreach line $lines {
              set col 0
              while {[regexp -indices -start $col {*}$data($win,config,re_opts) -- $pattern $line -> sres tres]} {
                lassign $sres scol ecol
                set tag $tag1
                if {$scol == -1} {
                  lassign $tres scol ecol
                  set tag $tag2
                }
                set col [expr $ecol + 1]
                if {![isEscaped $win $row.$scol]} {
                  if {([string index $pattern 0] eq "^") && ([string index $tag 2] ne "L")} {
                    set match [string range $line $scol $ecol]
                    set diff  [expr [string length $match] - [string length [string trimleft $match]]]
                    lappend indices($tag[expr $i & 1]) $row.[expr $scol + $diff] $row.$col
                  } else {
                    lappend indices($tag[expr $i & 1]) $row.$scol $row.$col
                  }
                }
                incr i
              }
              incr row
            }
            foreach tag [array names indices] {
              if {$indices($tag) ne [getTagInRange $win $tag $pstart $pend]} {
                $win._t tag remove $tag $pstart $pend
                catch { $win._t tag add $tag {*}$indices($tag) }
                set tag_changed([string range $tag 0 end-1]) 1
              }
            }
            array unset indices
          }

        }

        # If we didn't find any comment/string characters that changed, no need to continue.
        if {[array size tag_changed] == 0} continue

        # Initialize tags
        array unset tags
        set char_tags [list]

        # Gather the list of comment ranges in the char_tags list
        foreach i {0 1} {
          if {[info exists data($win,config,lc_char_tags,$lang)]} {
            foreach char_tag $data($win,config,lc_char_tags,$lang) {
              set index $langstart
              while {([set char_end [lassign [$win tag nextrange $char_tag$i $index] char_start]] ne "") && [$win compare $char_end <= $langend]} {
                set lineend [$win index "$char_start lineend"]
                set index   $lineend
                lappend char_tags [list $char_start $char_end __lCommentStart:$lang] [list ${lineend}a "$lineend+1c" __lCommentEnd:$lang]
              }
            }
          }
          if {[info exists data($win,config,csl_char_tags,$lang)]} {
            foreach char_tag $data($win,config,csl_char_tags,$lang) {
              set index $langstart
              while {([set char_end [lassign [$win tag nextrange $char_tag$i $index] char_start]] ne "") && [$win compare $char_end <= $langend]} {
                lappend char_tags [list $char_start $char_end $char_tag]
                set index $char_end
              }
            }
          }
        }

        # Sort the char tags
        set char_tags [lsort -dictionary -index 0 $char_tags]

        # Create the tag lists
        set curr_lang       $lang
        set curr_lang_start ""
        set curr_char_tag   ""
        set rb              0
        array set tag_pairs $data($win,config,csl_tag_pair)
        foreach char_info $char_tags {
          lassign $char_info char_start char_end char_tag
          if {($curr_char_tag eq "") || [string match "__*End:$curr_lang" $curr_char_tag] || ($char_tag eq "__LangEnd:$curr_lang")} {
            if {[string range $char_tag 0 6] eq "__LangS"} {
              set curr_lang       [lindex [split $char_tag :] 1]
              set curr_lang_start $char_start
              set curr_char_tag   ""
            } elseif {$char_tag eq "__LangEnd:$curr_lang"} {
              if {[info exists tag_pairs($curr_char_tag)]} {
                lappend tags($tag_pairs($curr_char_tag)$rb) $curr_char_start $char_start
                set rb [expr $rb ^ 1]
              }
              if {$curr_lang_start ne ""} {
                lappend tags(__Lang:$curr_lang) $curr_lang_start $char_end
              }
              set curr_lang       ""
              set curr_lang_start ""
              set curr_char_tag   ""
            } elseif {[string match "*:$curr_lang" $char_tag]} {
              set curr_char_tag   $char_tag
              set curr_char_start $char_start
            }
          } elseif {$curr_char_tag eq "__lCommentStart:$curr_lang"} {
            if {$char_tag eq "__lCommentEnd:$curr_lang"} {
              lappend tags(__comstr1l) $curr_char_start $char_end
              set curr_char_tag ""
            }
          } elseif {$curr_char_tag eq "__cCommentStart:$curr_lang"} {
            if {$char_tag eq "__cCommentEnd:$curr_lang"} {
              lappend tags(__comstr1c$rb) $curr_char_start $char_end
              set curr_char_tag ""
              set rb [expr $rb ^ 1]
            }
          } elseif {$curr_char_tag eq "__dQuote:$curr_lang"} {
            if {$char_tag eq "__dQuote:$curr_lang"} {
              lappend tags(__comstr0d$rb) $curr_char_start $char_end
              set curr_char_tag ""
              set rb [expr $rb ^ 1]
            }
          } elseif {$curr_char_tag eq "__sQuote:$curr_lang"} {
            if {$char_tag eq "__sQuote:$curr_lang"} {
              lappend tags(__comstr0s$rb) $curr_char_start $char_end
              set curr_char_tag ""
              set rb [expr $rb ^ 1]
            }
          } elseif {$curr_char_tag eq "__bQuote:$curr_lang"} {
            if {$char_tag eq "__bQuote:$curr_lang"} {
              lappend tags(__comstr0b$rb) $curr_char_start $char_end
              set curr_char_tag ""
              set rb [expr $rb ^ 1]
            }
          } elseif {$curr_char_tag eq "__DQuote:$curr_lang"} {
            if {$char_tag eq "__DQuote:$curr_lang"} {
              lappend tags(__comstr0D$rb) $curr_char_start $char_end
              set curr_char_tag ""
              set rb [expr $rb ^ 1]
            }
          } elseif {$curr_char_tag eq "__SQuote:$curr_lang"} {
            if {$char_tag eq "__SQuote:$curr_lang"} {
              lappend tags(__comstr0S$rb) $curr_char_start $char_end
              set curr_char_tag ""
              set rb [expr $rb ^ 1]
            }
          } elseif {$curr_char_tag eq "__BQuote:$curr_lang"} {
            if {$char_tag eq "__BQuote:$curr_lang"} {
              lappend tags(__comstr0B$rb) $curr_char_start $char_end
              set curr_char_tag ""
              set rb [expr $rb ^ 1]
            }
          }
        }
        if {[info exists tag_pairs($curr_char_tag)]} {
          lappend tags($tag_pairs($curr_char_tag)$rb) $curr_char_start [expr {($lang eq "") ? "end" : "$langend linestart"}]
        }
        if {($curr_lang ne "") && ($lang eq "")} {
          lappend tags(__Lang:$curr_lang) $curr_lang_start end
        }

        # Delete old tags
        if {$lang eq ""} {
          foreach l $data($win,config,langs) {
            catch { $win._t tag remove __Lang:$l $langstart $langend }
          }
        }
        foreach tag $data($win,config,csl_tags) {
          catch { $win._t tag remove $tag $langstart $langend }
        }

        # Add new tags
        foreach tag [array names tags] {
          $win._t tag add $tag {*}$tags($tag)
        }

        # Calculate the return value
        set retval [expr (($retval == 2) || ([llength [array names tag_changed __Lang*:*]] > 0)) ? 2 : 1]

      }

      array unset tag_changed {*:$lang[01]}

    }

    return $retval

  }

  proc updateLangBackgrounds {win} {

    variable data

    foreach lang $data($win,config,langs) {
      set indices [list]
      foreach {start end} [$win._t tag ranges __Lang:$lang] {
        if {[$win compare "$start+1l linestart" < "$end linestart"]} {
          lappend indices "$start+1l linestart" "$end linestart"
        }
      }
      catch { $win._t tag remove __Lang=$lang 1.0 end }
      catch { $win._t tag add __Lang=$lang {*}$indices }
    }

  }

  proc setIndentation {twin lang indentations type} {

    variable data

    if {[llength $indentations] > 0} {
      set data($twin,config,indentation,$lang,$type) [join $indentations |]
      $twin tag configure __$type
      $twin tag lower __$type _invisible
    } else {
      catch { unset data($twin,config,indentation,$lang,$type) }
    }

  }

  proc escapes {win start end} {

    variable data

    if {$data($win,config,-escapes)} {
      foreach res [$win._t search -all -- "\\" $start $end] {
        if {[lsearch [$win._t tag names $res-1c] __escape] == -1} {
          $win._t tag add __escape $res
        }
      }
    }

  }

  # This procedure tags all of the whitespace from the beginning of a line.  This
  # must be called prior to invoking the indentation procedure.
  proc prewhite {win start end} {

    # Add prewhite tags
    set i       0
    set indices [list]
    foreach res [$win._t search -regexp -all -count lengths -- {^[ \t]*\S} $start $end] {
      lappend indices $res "$res+[lindex $lengths $i]c"
      incr i
    }

    catch { $win._t tag add __prewhite {*}$indices }

  }

  proc brackets {win start end lang ptags} {

    upvar $ptags tags

    variable data
    variable REs
    variable bracket_map

    array set ttags {}

    # Handle special character matching
    set row [lindex [split $start .] 0]
    foreach line [split [$win._t get $start $end] \n] {
      set col 0
      while {[regexp -indices -start $col -- $REs(brackets) $line res]} {
        set scol [lindex $res 0]
        set col  [expr $scol + 1]
        lappend ttags(__$bracket_map([string index $line $scol])) $row.$scol $row.$col
      }
      incr row
    }

    foreach tag [array names ttags] {
      if {[info exists data($win,config,matchChar,$lang,[string range $tag 2 end-1])]} {
        dict lappend tags $tag {*}$ttags($tag)
      }
    }

  }

  proc indentation {win start end lang ptags} {

    upvar $ptags tags

    variable data

    set lines    [split [$win._t get $start $end] \n]
    set startrow [lindex [split $start .] 0]

    # Add indentation
    foreach key [array names data $win,config,indentation,$lang,*] {
      set type [lindex [split $key ,] 4]
      set i    0
      set row  $startrow
      foreach line $lines {
        set col 0
        while {[regexp -indices -start $col -- $data($key) $line res]} {
          lassign $res scol ecol
          set col [expr $ecol + 1]
          dict lappend tags __$type[expr $i & 1] $row.$scol $row.$col
          incr i
        }
        incr row
      }
    }

  }

  proc words {win start end lang ins ptags} {

    upvar $ptags tags

    variable data

    set retval ""

    if {[llength [array names data $win,highlight,w*,$lang,*]] > 0} {

      set row [lindex [split $start .] 0]
      foreach line [split [$win._t get $start $end] \n] {
        set col 0
        while {[regexp -indices -start $col -- $data($win,config,-delimiters) $line res]} {
          lassign $res scol ecol
          set word [string range $line $scol $ecol]
          set col  [expr $ecol + 1]
          if {!$data($win,config,-casesensitive)} {
            set word [string tolower $word]
          }
          set firstOfWord [string index $word 0]
          if {[info exists data($win,highlight,wkeyword,class,$lang,$word)]} {
            dict lappend tags $data($win,highlight,wkeyword,class,$lang,$word) $row.$scol $row.$col
          } elseif {[info exists data($win,highlight,wcharstart,class,$lang,$firstOfWord)]} {
            dict lappend tags $data($win,highlight,wcharstart,class,$lang,$firstOfWord) $row.$scol $row.$col
          }
          if {[info exists data($win,highlight,wkeyword,command,$lang,$word)] && \
              ![catch { {*}$data($win,highlight,wkeyword,command,$lang,$word) $win $row $line [list 0 [list $scol $ecol]] $ins } retval] && ([llength $retval] == 3)} {
            dict lappend tags [lindex $retval 0] $row.[lindex $retval 1] $row.[expr [lindex $retval 2] + 1]
          } elseif {[info exists data($win,highlight,wcharstart,command,$lang,$firstOfWord)] && \
                    ![catch { {*}$data($win,highlight,wcharstart,command,$lang,$firstOfWord) $win $row $line [list 0 [list $scol $ecol]] $ins } retval] && ([llength $retval] == 3)} {
            dict lappend tags [lindex $retval 0] $row.[lindex $retval 1] $row.[expr [lindex $retval 2] + 1]
          }
        }
        incr row
      }

    }

  }

  proc regexps {win start end lang ins ptags} {

    variable data

    if {![info exists data($win,highlight,regexps,$lang)]} return

    upvar $ptags tags

    set lines    [split [$win._t get $start $end] \n]
    set startrow [lindex [split $start .] 0]

    # Handle regular expression matching
    foreach name $data($win,highlight,regexps,$lang) {
      lassign [split $name ,] dummy1 type dummy2 value
      lassign $data($win,highlight,$name) re re_opts immediate
      set i 0
      if {$type eq "class"} {
        foreach res [$win._t search -count lengths -regexp {*}$re_opts -all -nolinestop -- $re $start $end] {
          set wordEnd [$win._t index "$res + [lindex $lengths $i] chars"]
          dict lappend tags $value $res $wordEnd
          incr i
        }
      } else {
        array unset itags
        set row $startrow
        foreach line $lines {
          set col 0
          array unset var
          while {[regexp {*}$re_opts -indices -start $col -- $re $line var(0) var(1) var(2) var(3) var(4) var(5) var(6) var(7) var(8) var(9)] && ([lindex $var(0) 0] <= [lindex $var(0) 1])} {
            if {![catch { {*}$value $win $row $line [array get var] $ins } retval] && ([llength $retval] == 2)} {
              lassign $retval rtags goback
              if {([llength $rtags] % 3) == 0} {
                foreach {rtag rstart rend} $rtags {
                  if {[info exists data($win,classimmediate,$rtag)]} {
                    if {$data($win,classimmediate,$rtag)} {
                      lappend itags(__$rtag) $row.$rstart $row.[expr $rend + 1]
                    } else {
                      dict lappend tags __$rtag $row.$rstart $row.[expr $rend + 1]
                    }
                  }
                }
              }
              set col [expr {($goback ne "") ? $goback : ([lindex $var(0) 1] + 1)}]
            } else {
              set col [expr {[lindex $var(0) 1] + 1}]
            }
          }
          incr row
        }
        foreach tag [array names itags] {
          $win._t tag add $tag {*}$itags($tag)
        }
      }
    }

  }

  ######################################################################
  # Performs any active searches on the given text range.
  proc searches {win start end ptags} {

    upvar $ptags tags

    variable data

    foreach {key value} [array get data $win,highlight,searches,*] {

      set class [lindex [split $key ,] 3]
      lassign $value str opts

      # Perform the search now
      set i 0
      foreach res [$win._t search -count lengths {*}$opts -all -- $str $start $end] {
        dict lappend tags $class $res [$win._t index "$res + [lindex $lengths $i] chars"]
        incr i
      }

    }

  }

  ######################################################################
  # Create a fontname (if one does not already exist) and configure it
  # with the given modifiers.  Returns the list of options that should
  # be applied to the tag
  proc add_font_opts {win modifiers popts} {

    variable data

    upvar $popts opts

    if {[llength $modifiers] == 0} return

    array set font_opts [font configure [$win cget -font]]
    array set line_opts [list]
    array set tag_opts  [list]

    set lsize       ""
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

    lappend opts -font $fontname {*}[array get tag_opts] {*}[array get line_opts]

  }

  proc addHighlightKeywords {win type value keywords {lang ""}} {

    variable data

    if {$type eq "class"} {
      checkHighlightClass $win $value
      set value __$value
    }

    foreach word $keywords {
      set data($win,highlight,wkeyword,$type,$lang,$word) $value
    }

  }

  proc addHighlightRegexp {win type value re {lang ""}} {

    variable data

    if {$type eq "class"} {
      checkHighlightClass $win $value
      set value __$value
    }

    if {![info exists data($win,highlight,regexps,$lang)]} {
      set index 0
    } else {
      set index [llength $data($win,highlight,regexps,$lang)]
    }

    lappend data($win,highlight,regexps,$lang) "regexp,$type,$lang,$value,$index"

    set data($win,highlight,regexp,$type,$lang,$value,$index) [list $re $data($win,config,re_opts)]

  }

  # For things like $blah
  proc addHighlightWithOnlyCharStart {win type value char {lang ""}} {

    variable data

    if {$type eq "class"} {
      checkHighlightClass $win $value
      set value __$value
    }

    set data($win,highlight,wcharstart,$type,$lang,$char) $value

  }

  ######################################################################
  # Performs a search and highlights all matches.
  proc highlightSearch {win class str {opts ""}} {

    variable data

    # Add the highlight class
    addHighlightClass $win $class -fgtheme search -bgtheme search -priority high

    # Save the information
    set data($win,highlight,searches,__$class) [list $str $opts]

    # Perform the search now
    set i 0
    foreach res [$win._t search -count lengths {*}$opts -all -- $str 1.0 end] {
      lappend matches $res [$win._t index "$res + [lindex $lengths $i] chars"]
      incr i
    }

    catch { $win._t tag add __$class {*}$matches }

  }

  ######################################################################
  # Verifies that the specified class is valid for the given text widget.
  proc checkHighlightClass {win class} {

    variable data

    if {![info exists data($win,classopts,$class)]} {
      return -code error "Unspecified highlight class ($class) specified in [dict get [info frame -1] proc]"
    }

  }

  ######################################################################
  # Adds a highlight class with rendering information.
  proc addHighlightClass {win class args} {

    variable data
    variable right_click

    array set opts {
      -fgtheme   ""
      -bgtheme   ""
      -fontopts  ""
      -clickcmd  ""
      -priority  ""
      -immediate 0
    }
    array set opts $args

    # Configure the class tag and place it in the correct position in the tag stack
    $win._t tag configure __$class
    if {$opts(-priority) ne ""} {
      switch $opts(-priority) {
        1    { $win._t tag lower __$class _visibleH }
        2    { $win._t tag raise __$class _visibleL }
        3    { $win._t tag lower __$class _visibleL }
        4    { $win._t tag raise __$class _invisible }
        high { $win._t tag raise __$class _visibleH }
      }
    } elseif {$opts(-bgtheme) ne ""} {
      $win._t tag lower __$class _visibleL
    } elseif {($opts(-fgtheme) ne "") || ($opts(-fontopts) ne "")} {
      $win._t tag raise __$class _visibleL
    } else {
      $win._t tag lower __$class _invisible
    }

    # If there is a command associated with the class, bind it to the right-click button
    if {$opts(-clickcmd) ne ""} {
      $win._t tag bind __$class <Button-$right_click> [list ctext::handleClickCommand $win __$class $opts(-clickcmd)]
    }

    # Save the class name and options
    set data($win,classopts,$class)      [array get opts]
    set data($win,classimmediate,$class) $opts(-immediate)

    # Apply the class theming information
    applyClassTheme $win $class

  }

  ######################################################################
  # Call the given command on click.
  proc handleClickCommand {win tag command} {

    # Get the clicked text range
    lassign [$win._t tag prevrange $tag [$win._t index current+1c]] startpos endpos

    # Call the command
    uplevel #0 [list {*}$command $win $startpos $endpos]

  }

  ######################################################################
  # Updates the theming information for the given class.
  proc applyClassTheme {win class} {

    variable data

    array set opts   $data($win,classopts,$class)
    array set themes $data($win,config,-theme)

    set tag_opts [list]

    if {([set fgtheme $opts(-fgtheme)] ne "") && [info exists themes($fgtheme)]} {
      lappend tag_opts -foreground $themes($fgtheme)
    }

    if {([set bgtheme $opts(-bgtheme)] ne "") && [info exists themes($bgtheme)]} {
      lappend tag_opts -background $themes($bgtheme)
    }

    if {$opts(-fontopts) ne ""} {
      add_font_opts $win $opts(-fontopts) tag_opts
    }

    catch { $win._t tag configure __$class {*}$tag_opts }

  }

  ######################################################################
  # Removes the specified highlighting class from the widget.
  proc deleteHighlightClass {win class} {

    variable data

    foreach key [array names data $win,highlight,regexps,*] {
      foreach index [lreverse [lsearch -all $data($key) *regexp,class,*,$class,*]] {
        set data($key) [lreplace $data($key) $index $index]
      }
    }

    array unset data $win,highlight,*,class,__$class
    array unset data $win,highlight,searches,__$class
    array unset data $win,classopts,$class
    array unset data $win,classimmediate,$class

    $win._t tag delete __$class 1.0 end

  }

  ######################################################################
  # Deletes the given highlighting command from memory.
  proc deleteHighlightCommand {win command} {

    variable data

    array unset data $win,highlight,regexp,command,*,$command,*
    foreach key [array names data $win,highlight,regexps,*] {
      foreach index [lreverse [lsearch -all $data($key) regexp,command,*,$command,*]] {
        set data($key) [lreplace $data($key) $index $index]
      }
    }

    foreach type [list wkeyword wcharstart] {
      foreach key [array names data $win,highlight,$type,command,*] {
        if {[string match $data($key) $command]} {
          unset data($key)
        }
      }
    }

  }

  ######################################################################
  # Returns the highlight classes that are stored in the widget or at the
  # provided index (if specified).
  proc getHighlightClasses {win {index ""}} {

    variable data

    if {$index eq ""} {
      set classes [list]
      foreach class [array names data $win,classopts,*] {
        lappend classes [lindex [split $class ,] 2]
      }
    } else {
      foreach tag [$win._t tag names $index] {
        set t [string range $tag 2 end]
        if {[info exists data($win,classopts,$t)]} {
          lappend classes $t
        }
      }
    }

    return $classes

  }

  ######################################################################
  # Clears the highlight classes so that they can be freshly reapplied.
  proc clearHighlightClasses {win} {

    variable data

    array unset data $win,highlight,*

    # Delete the associated tags
    if {[winfo exists $win]} {
      foreach class [getHighlightClasses $win] {
        $win._t tag delete __$class
      }
    }

  }

  proc highlight {win start end ins} {

    variable data
    variable REs
    variable restart_from

    set twin "$win._t"
    set tags [dict create]

    foreach lang $data($win,config,langs) {

      # Get the ranges to check
      if {$lang eq ""} {
        set ranges [list 1.0 end]
      } else {
        set ranges [$twin tag ranges "__Lang=$lang"]
      }

      # Perform highlighting for each range
      foreach {langstart langend} $ranges {

        if {[$twin compare $start > $langend] || [$twin compare $langstart > $end]} continue
        if {[$twin compare $start <= $langstart]} { set pstart $langstart } else { set pstart $start }
        if {[$twin compare $langend <= $end]}     { set pend   $langend   } else { set pend   $end }

        brackets    $win $pstart $pend $lang tags
        indentation $win $pstart $pend $lang tags
        words       $win $pstart $pend $lang $ins tags
        regexps     $win $pstart $pend $lang $ins tags
        searches    $win $pstart $pend tags

      }

    }

    # Update the tags
    dict for {tag indices} $tags {
      $win._t tag add $tag {*}$indices
    }

  }

  # Called when the given lines are about to be deleted.  Allows the linemap_mark_command call to
  # be made when this occurs.
  proc linemapCheckOnDelete {win startpos {endpos ""}} {

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

  proc linemapToggleMark {win x y} {

    variable data

    if {!$data($win,config,-linemap_markable)} {
      return
    }

    set tline [lindex [split [set tmarkChar [$win.t index @0,$y]] .] 0]

    if {[set lmark [lsearch -inline -glob [$win.t tag names $tline.0] lmark*]] ne ""} {
      $win.t tag delete $lmark
      set type unmarked
    } else {
      set lmark "lmark[incr data($win,linemap,id)]"
      $win.t tag add $lmark $tmarkChar [$win.t index "$tmarkChar lineend"]
      set type marked
    }

    # Update the linemap
    linemapUpdate $win 1

    # Call the mark command, if one exists.  If it returns a value of 0, remove
    # the mark.
    set cmd $data($win,config,-linemap_mark_command)
    if {[string length $cmd] && ![uplevel #0 [linsert $cmd end $win $type $lmark]]} {
      $win.t tag delete $lmark
      linemapUpdate $win 1
    }

  }

  proc linemapSetMark {win line} {

    variable data

    if {[lsearch -inline -glob [$win.t tag names $line.0] lmark*] eq ""} {
      set lmark "lmark[incr data($win,linemap,id)]"
      $win.t tag add $lmark $line.0
      linemapUpdate $win 1
      return $lmark
    }

    return ""

  }

  proc linemapClearMark {win line} {

    if {[set lmark [lsearch -inline -glob [$win.t tag names $line.0] lmark*]] ne ""} {
      $win.t tag delete $lmark
      linemapUpdate $win 1
    }

  }

  proc linemapUpdateNeeded {win} {

    variable data

    set yview [$win yview]
    set lasty [lindex [$win dlineinfo end-1c] 1]

    if {[info exists data($win,yview)] && ($data($win,yview) eq $yview) && \
        [info exists data($win,lasty)] && ($data($win,lasty) eq $lasty)} {
      return 0
    }

    set data($win,yview) $yview
    set data($win,lasty) $lasty

    return 1

  }

  proc linemapUpdate {win {forceUpdate 0}} {

    variable data

    # Check to see if the current cursor is on a bracket and match it
    if {$data($win,config,-matchchar)} {
      matchBracket $win
    }

    # If there is no need to update, return now
    if {![winfo exists $win.l] || (![linemapUpdateNeeded $win] && !$forceUpdate)} {
      return
    }

    set first         [lindex [split [$win.t index @0,0] .] 0]
    set last          [lindex [split [$win.t index @0,[winfo height $win.t]] .] 0]
    set line_width    [string length [lindex [split [$win._t index end-1c] .] 0]]
    set linenum_width [expr max( $data($win,config,-linemap_minwidth), $line_width )]
    set gutter_width  [expr [llength [lsearch -index 2 -all -inline $data($win,config,gutters) 0]] + 1]

    if {[$win._t compare "@0,0 linestart" != @0,0]} {
      incr first
    }

    $win.l delete all

    if {$data($win,config,-diff_mode)} {
      linemapDiffUpdate $win $first $last $linenum_width
      set full_width [expr ($linenum_width * 2) + 1 + $gutter_width]
    } elseif {$data($win,config,-linemap)} {
      linemapLineUpdate $win $first $last $linenum_width
      set full_width [expr $linenum_width + $gutter_width]
    } elseif {$gutter_width > 0} {
      linemapGutterUpdate $win $first $last $linenum_width
      set full_width [expr $data($win,config,-linemap_markable) + $gutter_width]
    } elseif {$data($win,config,-linemap_markable)} {
      linemapMarkUpdate $win $first $last
      set full_width 1
    }

    # Resize the linemap window, if necessary
    if {[$win.l cget -width] != (($full_width * $data($win,fontwidth)) + 2)} {
      $win.l configure -width [expr ($full_width * $data($win,fontwidth)) + 2]
    }

  }

  proc linemapUpdateGutter {win ptags x y} {

    variable data

    upvar $ptags tags

    set index     0
    set fontwidth $data($win,fontwidth)
    set font      $data($win,config,-font)
    set fill      $data($win,config,-linemapfg)

    foreach gutter_data $data($win,config,gutters) {
      if {[lindex $gutter_data 2]} { continue }
      foreach gutter_tag [lsearch -inline -all -glob $tags gutter:[lindex $gutter_data 0]:*] {
        lassign [split $gutter_tag :] dummy dummy gutter_symname gutter_sym
        if {$gutter_sym ne ""} {
          set color [expr {[info exists data($win,gutterfg,$gutter_tag)] ? $data($win,gutterfg,$gutter_tag) : $fill}]
          $win.l create text [expr $x + ($index * $fontwidth)] $y -anchor sw -text $gutter_sym -fill $color -font $font -tags $gutter_tag
        }
      }
      incr index
    }

  }

  proc linemapDiffUpdate {win first last linenum_width} {

    variable data

    set normal  $data($win,config,-linemapfg)
    set lmark   $data($win,config,-linemap_mark_color)
    set font    $data($win,config,-font)
    set linebx  [expr (($linenum_width + 1) * $data($win,fontwidth)) + 1]
    set gutterx [expr $linebx + ((($linenum_width + 1) * $data($win,fontwidth)) + 1)]
    set descent $data($win,fontdescent)
    set fmt     [expr {($data($win,config,-linemap_align) eq "left") ? "%-*s %-*s" : "%*s %*s"}]

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
      lassign [$win._t dlineinfo $line.0] x y w h b
      set ltags  [$win._t tag names $line.0]
      set y      [expr $y + $b + $descent]
      set lineA  [expr {([lsearch -glob $ltags diff:A:S:*] != -1) ? [incr currline(A)] : ""}]
      set lineB  [expr {([lsearch -glob $ltags diff:B:S:*] != -1) ? [incr currline(B)] : ""}]
      set marked [expr {[lsearch -glob $ltags lmark*] != -1}]
      set fill   [expr {$marked ? $lmark : $normal}]
      $win.l create text 1 $y -anchor sw -text [format $fmt $linenum_width $lineA $linenum_width $lineB] -fill $fill -font $font
      linemapUpdateGutter $win ltags $gutterx $y
    }

  }

  proc linemapLineUpdate {win first last linenum_width} {

    variable data

    set abs     [expr {$data($win,config,-linemap_type) eq "absolute"}]
    set curr    [lindex [split [$win.t index insert] .] 0]
    set lmark   $data($win,config,-linemap_mark_color)
    set normal  $data($win,config,-linemapfg)
    set font    $data($win,config,-font)
    set gutterx [expr (($linenum_width + 1) * $data($win,fontwidth)) + 1]
    set descent $data($win,fontdescent)
    set fmt     [expr {($data($win,config,-linemap_align) eq "left") ? "%-*s" : "%*s"}]

    if {$abs} {
      set curr 0
    }

    for {set line $first} {$line <= $last} {incr line} {
      if {[$win._t count -displaychars $line.0 [expr $line + 1].0] == 0} { continue }
      lassign [$win._t dlineinfo $line.0] x y w h b
      set ltags   [$win.t tag names $line.0]
      set linenum [expr abs( $line - $curr )]
      set marked  [expr {[lsearch -glob $ltags lmark*] != -1}]
      set fill    [expr {$marked ? $lmark : $normal}]
      set y       [expr $y + $b + $descent]
      $win.l create text 1 $y -anchor sw -text [format $fmt $linenum_width $linenum] -fill $fill -font $font
      linemapUpdateGutter $win ltags $gutterx $y
    }

  }

  proc linemapGutterUpdate {win first last linenum_width} {

    variable data

    set gutterx [expr {$data($win,config,-linemap_markable) ? (($data($win,fontwidth) * 2) + 1) : 1}]
    set fill    $data($win,config,-linemap_mark_color)
    set font    $data($win,config,-font)
    set descent $data($win,fontdescent)

    for {set line $first} {$line <= $last} {incr line} {
      if {[$win._t count -displaychars $line.0 [expr $line + 1].0] == 0} { continue }
      lassign [$win._t dlineinfo $line.0] x y w h b
      set ltags [$win.t tag names $line.0]
      set y     [expr $y + $b + $descent]
      if {[lsearch -glob $ltags lmark*] != -1} {
        $win.l create text 1 $y -anchor sw -text "M" -fill $fill -font $font
      }
      linemapUpdateGutter $win ltags $gutterx $y
    }

  }

  proc linemapMarkUpdate {win first last} {

    variable data

    set fill    $data($win,config,-linemap_mark_color)
    set font    $data($win,config,-font)
    set descent $data($win,fontdescent)

    for {set line $first} {$line <= $last} {incr line} {
      if {[$win._t count -displaychars $line.0 [expr $line + 1].0] == 0} { continue }
      lassign [$win._t dlineinfo $line.0] x y w h b
      set ltags [$win.t tag names $line.0]
      set y     [expr $y + $b + $descent]
      if {[lsearch -glob $ltags lmark*] != -1} {
        $win.l create text 1 $y -anchor sw -text "M" -fill $fill -font $font
      }
    }

  }

  proc doConfigure {win} {

    # Update the linemap
    linemapUpdate $win

    # Update the rmargin
    adjust_rmargin $win

  }

  proc set_warnwidth {win {adjust 0}} {

    variable data

    if {$data($win,config,-warnwidth) eq ""} {
      place forget $win.t.w
      return
    }

    set lmargin $data($win,config,-lmargin)
    set cwidth  [font measure [$win._t cget -font] -displayof . m]
    set str     [string repeat "m" $data($win,config,-warnwidth)]
    set newx    [expr $lmargin + ($cwidth * $data($win,config,-warnwidth)) + $adjust]
    place configure $win.t.w -x $newx -relheight 1.0
    adjust_rmargin $win

  }

  proc set_rmargin {win startpos endpos} {

    $win tag add rmargin $startpos $endpos
    $win tag add lmargin $startpos $endpos

  }

  proc adjust_rmargin {win} {

    # If the warning width indicator is absent, remove rmargin and return
    if {[lsearch [place slaves $win.t] $win.t.w] == -1} {
      $win tag configure rmargin -rmargin ""
      return
    }

    # Calculate the rmargin value to use
    set rmargin [expr [winfo width $win.t] - [lindex [place configure $win.t.w -x] 4]]

    # Set the rmargin
    if {$rmargin > 0} {
      $win tag configure rmargin -rmargin $rmargin
    } else {
      $win tag configure rmargin -rmargin ""
    }

  }

  proc modified {win value {dat ""}} {

    variable data

    set data($win,config,modified) $value
    event generate $win <<Modified>> -data $dat

    return $value

  }

}

######################################################################
# Creates a ctext widget and initializes it for use based on the given
# settings.
proc ctext {win args} {

  set win [ctext::create $win {*}$args]

  rename $win __ctextJunk$win
  rename $win.t $win._t

  interp alias {} $win {} ctext::instanceCmd $win
  interp alias {} $win.t {} $win

  ctext::update_linemap_separator $win
  ctext::modified                 $win 0
  ctext::buildArgParseTable       $win
  ctext::adjust_rmargin           $win

  return $win

}

