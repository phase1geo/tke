# by george peter Staplin
# See also the README for a list of contributors
# RCS: @(#) $Id: ctext.tcl,v 1.9 2011/04/18 19:49:48 andreas_kupries Exp $

package require Tk
package require Thread
package provide ctext 6.0

source [file join [file dirname [info script]] utils.tcl]
source [file join [file dirname [info script]] model.tcl]
source [file join [file dirname [info script]] parsers.tcl]

set utils::main_tid [thread::id]

# Override the tk::TextSetCursor to add a <<CursorChanged>> event
rename ::tk::TextSetCursor ::tk::TextSetCursorOrig
proc ::tk::TextSetCursor {w pos args} {
  set ins [$w index insert]
  ::tk::TextSetCursorOrig $w $pos
  event generate $w <<CursorChanged>> -data [list $ins {*}$args]
}

namespace eval ctext {

  array set data {}

  variable right_click 3
  variable this_dir    ""
  variable tpool       ""

  if {[tk windowingsystem] eq "aqua"} {
    set right_click 2
  }

  # We need to set this while we are sourcing the file
  set this_dir [file dirname [file normalize [info script]]]

  ######################################################################
  # Initialize the namespace for threading.
  proc initialize {{min 5} {max 15}} {

    variable tpool
    variable this_dir

    if {$tpool eq ""} {

      # Create the syntax highlighting pool
      set tpool [tpool::create -minworkers $min -maxworkers $max -initcmd [format {
        source [file join %s utils.tcl]
        source [file join %s parsers.tcl]
        source [file join %s model.tcl]
        set utils::main_tid %s
      } $this_dir $this_dir $this_dir [thread::id]]]

    }

  }

  ######################################################################
  # This needs to be called prior to exiting the appliction.
  proc destroy {} {

    variable tpool

    # Release the thread pool
    tpool::release $tpool

  }

  ######################################################################
  # Creates and initializes the widget.
  proc create {win args} {

    variable data
    variable right_click
    variable tpool

    # Make sure that we are initialized if we have not been already
    initialize

    if {[llength $args] & 1} {
      return -code error "Invalid number of arguments given to ctext (uneven number after window) : $args"
    }

    frame $win -class Ctext

    set tmp [text .__ctextTemp]

    set data($win,config,-fg)                     [$tmp cget -foreground]
    set data($win,config,-bg)                     [$tmp cget -background]
    set data($win,config,-font)                   [$tmp cget -font]
    set data($win,config,-relief)                 [$tmp cget -relief]
    set data($win,config,-unhighlightcolor)       [$win cget -bg]
    ::destroy $tmp
    set data($win,config,-xscrollcommand)         ""
    set data($win,config,-yscrollcommand)         ""
    set data($win,config,-highlightcolor)         "yellow"
    set data($win,config,-linemap)                1
    set data($win,config,-linemapfg)              $data($win,config,-fg)
    set data($win,config,-linemapbg)              $data($win,config,-bg)
    set data($win,config,-linemap_mark_command)   {}
    set data($win,config,-linemap_markable)       1
    set data($win,config,-linemap_mark_color)     orange
    set data($win,config,-linemap_cursor)         left_ptr
    set data($win,config,-linemap_relief)         $data($win,config,-relief)
    set data($win,config,-linemap_minwidth)       1
    set data($win,config,-linemap_type)           absolute
    set data($win,config,-highlight)              1
    set data($win,config,-lmargin)                0
    set data($win,config,-warnwidth)              ""
    set data($win,config,-warnwidth_bg)           red
    set data($win,config,-casesensitive)          1
    set data($win,config,-escapes)                1
    set data($win,config,-peer)                   ""
    set data($win,config,-undo)                   0
    set data($win,config,-maxundo)                0
    set data($win,config,-autoseparators)         0
    set data($win,config,-diff_mode)              0
    set data($win,config,-diffsubbg)              "pink"
    set data($win,config,-diffaddbg)              "light green"
    set data($win,config,-folding)                0
    set data($win,config,-delimiters)             {[^\s\(\{\[\}\]\)\.\t\n\r;:=\"'\|,<>]+}
    set data($win,config,-matchchar)              0
    set data($win,config,-matchchar_bg)           $data($win,config,-fg)
    set data($win,config,-matchchar_fg)           $data($win,config,-bg)
    set data($win,config,-matchaudit)             0
    set data($win,config,-matchaudit_bg)          "red"
    set data($win,config,-foldstate)              "none"  ;# none, manual, indent and syntax supported
    set data($win,config,re_opts)                 ""
    set data($win,config,win)                     $win
    set data($win,config,modified)                0
    set data($win,config,lastUpdate)              0
    set data($win,config,csl_patterns)            [list]
    set data($win,config,csl_char_tags)           [list]
    set data($win,config,lc_char_tags)            [list]
    set data($win,config,csl_tags)                [list]
    set data($win,config,csl_array)               [list]
    set data($win,config,csl_tag_pair)            [list]
    set data($win,config,langs)                   [list {}]
    set data($win,config,gutters)                 [list]
    set data($win,config,redo_hist)               [list]

    set data($win,config,ctextFlags) {
      -xscrollcommand -yscrollcommand -linemap -linemapfg -linemapbg -font -linemap_mark_command
      -highlight -warnwidth -warnwidth_bg -linemap_markable -linemap_cursor -highlightcolor -folding
      -delimiters -matchchar -matchchar_bg -matchchar_fg -matchaudit -matchaudit_bg -linemap_mark_color
      -linemap_relief -linemap_minwidth -linemap_type -casesensitive -peer -undo -maxundo
      -autoseparators -diff_mode -diffsubbg -diffaddbg -escapes -spacing3 -lmargin -foldstate
    }

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

    # Now remove flags that will confuse text and those that need modification:
    foreach arg $data($win,config,ctextFlags) {
      if {[set loc [lsearch $args $arg]] >= 0} {
        set args [lreplace $args $loc [expr {$loc + 1}]]
      }
    }

    # Initialize the starting linemap ID
    set data($win,linemap,id) 0

    canvas $win.l -relief $data($win,config,-relief) -bd 0 \
      -bg $data($win,config,-linemapbg) -takefocus 0 -highlightthickness 0
    frame  $win.f -width 1 -bd 0 -relief flat -bg $data($win,config,-warnwidth_bg)

    set args [list {*}$args -yscrollcommand [list ctext::event:yscroll $win $data($win,config,-yscrollcommand)] \
                            -xscrollcommand [list ctext::event:xscroll $win $data($win,config,-xscrollcommand)]]

    if {$data($win,config,-peer) eq ""} {
      text $win.t -font $data($win,config,-font) -bd 0 -highlightthickness 0 {*}$args
    } else {
      $data($win,config,-peer)._t peer create $win.t -font $data($win,config,-font) -bd 0 -highlightthickness 0 {*}$args
    }

    frame $win.t.w -width 1 -bd 0 -relief flat -bg $data($win,config,-warnwidth_bg)

    if {$data($win,config,-warnwidth) ne ""} {
      set sample [string repeat "m" $data($win,config,-warnwidth)]
      set x      [expr $data($win,config,-lmargin) + [font measure [$win.t cget -font] -displayof . $sample]]
      place $win.t.w -x $x -relheight 1.0
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

    # If -matchchar is set, create the tag
    if {$data($win,config,-matchchar)} {
      $win.t tag configure matchchar -foreground $data($win,config,-matchchar_fg) -background $data($win,config,-matchchar_bg)
    }
    if {$data($win,config,-matchaudit)} {
      $win.t tag configure missing -background $data($win,config,-matchaudit_bg)
    }

    # Initialize shared memory
    tsv::set contexts $win [list]
    tsv::set brackets $win [list]
    tsv::set indents  $win [list]

    # Create the model
    model::create $win

    bind $win.t <Configure>           [list ctext::linemapUpdate $win]
    bind $win.t <<CursorChanged>>     [list ctext::linemapUpdate $win 1]
    bind $win.l <Button-$right_click> [list ctext::linemapToggleMark $win %x %y]
    bind $win.l <MouseWheel>          [list event generate $win.t <MouseWheel> -delta %D]
    bind $win.l <4>                   [list event generate $win.t <4>]
    bind $win.l <5>                   [list event generate $win.t <5>]
    bind $win   <Destroy>             [list ctext::event:Destroy $win %W]

    bindtags $win.t [linsert [bindtags $win.t] 0 $win]

    return $win

  }

  ######################################################################
  # Perform xscrolling.
  proc event:xscroll {win clientData args} {

    variable data

    if {$clientData == ""} {
      return
    }

    uplevel #0 $clientData $args

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

      # Adjust the rmargin
      adjust_rmargin $win

    }

  }

  ######################################################################
  # Performs yscrolling.
  proc event:yscroll {win clientData args} {

    linemapUpdate $win

    if {$clientData == ""} {
      return
    }

    uplevel #0 $clientData $args

  }

  ######################################################################
  # Called when the widget is destroyed.
  proc event:Destroy {win dWin} {

    variable data

    if {![string equal $win $dWin]} {
      return
    }

    catch { rename $win {} }
    interp alias {} $win.t {}

    clearHighlightClasses $win

    array unset data $win,config,*

  }

  ######################################################################
  # This stores the arg table within the config array for each instance.
  # It's used by the configure instance command.
  proc buildArgParseTable {win} {

    variable data

    set argTable [list]

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
        if {$data($win,config,-warnwidth) ne ""} {
          set newx [expr $data($win,config,-lmargin) + [font measure [$win.t cget -font] -displayof . [string repeat "m" $data($win,config,-warnwidth)]]]
          place $win.t.w -x $newx -relheight 1.0
          adjust_rmargin $win
          $win tag configure lmargin -lmargin1 $value -lmargin2 $value
        }
      } else {
        return -code error "Error: -lmargin option must be an integer value greater or equal to zero"
      }
      break
    }

    lappend argTable any -warnwidth {
      set data($win,config,-warnwidth) $value
      if {$value eq ""} {
        place forget $win.t.w
      } else {
        set newx [expr $data($win,config,-lmargin) + [font measure [$win.t cget -font] -displayof . [string repeat "m" $value]]]
        place $win.t.w -x $newx -relheight 1.0
        adjust_rmargin $win
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

    lappend argTable {any} -linemap_type {
      if {[lsearch [list absolute relative] $value] == -1} {
        return -code error "-linemap_type argument must be either 'absolute' or 'relative'"
      }
      set data($win,config,-linemap_type) $value
      set update_linemap 1
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
      model::set_max_undo $win $value
      break
    }

    lappend argTable {0 false no} -autoseparators {
      set data($win,config,-autoseparators) 0
      model::auto_separate $win 0
      break
    }

    lappend argTable {1 true yes} -autoseparators {
      set data($win,config,-autoseparators) 1
      model::auto_separate $win 1
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
      $win tag configure matchchar -foreground $data($win,config,-matchchar_fg)
      break
    }

    lappend argTable {any} -matchchar_bg {
      set data($win,config,-matchchar_bg) $value
      $win tag configure matchchar -background $data($win,config,-matchchar_bg)
      break
    }

    lappend argTable {0 false no} -matchaudit {
      set data($win,config,-matchaudit) 0
      catch { $win tag remove missing 1.0 end }
      break
    }

    lappend argTable {1 true yes} -matchaudit {
      set data($win,config,-matchaudit) 1
      $win tag configure missing -background $data($win,config,-matchaudit_bg)
      parsers::render_mismatched $win
      break
    }

    lappend argTable {any} -matchaudit_bg {
      set data($win,config,-matchaudit_bg) $value
      if {[lsearch [$win tag names] missing] != -1} {
        $win tag configure missing -background $value
      }
      break
    }

    lappend argTable {any} -foldstate {
      array set states {none 0 manual 1 indent 1 syntax 1}
      if {![info exists states($value)]} {
        return -code error "Illegal -foldstate value set ($value)"
      }
      if {$states($data($win,config,-foldstate)) != $states($value)} {
        if {$states($value)} {
          enable_folding $win
        } else {
          disable_folding $win
        }
      }
      set data($win,config,-foldstate) $value
    }

    set data($win,config,argTable) $argTable

  }

  ######################################################################
  proc inCommentStringHelper {win index pattern} {

    set names [$win tag names $index]

    return [expr {[string map [list $pattern {}] $names] ne $names}]

  }

  ######################################################################
  proc inLineComment {win index} {

    return [inCommentStringHelper $win $index _comstr1l]

  }

  ######################################################################
  proc inBlockComment {win index} {

    return [inCommentStringHelper $win $index _comstr1c]

  }

  ######################################################################
  proc inComment {win index} {

    return [inCommentStringHelper $win $index _comstr1]

  }

  ######################################################################
  proc inBackTick {win index} {

    return [inCommentStringHelper $win $index _comstr0b]

  }

  ######################################################################
  proc inSingleQuote {win index} {

    return [inCommentStringHelper $win $index _comstr0s]

  }

  ######################################################################
  proc inDoubleQuote {win index} {

    return [inCommentStringHelper $win $index _comstr0d]

  }

  ######################################################################
  proc inString {win index} {

    return [inCommentStringHelper $win $index _comstr0]

  }

  ######################################################################
  proc inCommentString {win index} {

    return [inCommentStringHelper $win $index _comstr]

  }

  ######################################################################
  proc inCommentStringRangeHelper {win index pattern prange} {

    if {[set curr_tag [lsearch -inline -glob [$win tag names $index] $pattern]] ne ""} {
      upvar 2 $prange range
      set range [$win tag prevrange $curr_tag $index+1c]
      return 1
    }

    return 0

  }

  ######################################################################
  proc inLineCommentRange {win index prange} {

    return [inCommentStringRangeHelper $win $index _comstr1l $prange]

  }

  ######################################################################
  proc inBlockCommentRange {win index prange} {

    return [inCommentStringRangeHelper $win $index _comstr1c* $prange]

  }

  ######################################################################
  proc inCommentRange {win index prange} {

    return [inCommentStringRangeHelper $win $index _comstr1* $prange]

  }

  ######################################################################
  proc commentCharRanges {win index} {

    if {[set curr_tag [lsearch -inline -glob [$win tag names $index] _comstr1*]] ne ""} {
      set range [$win tag prevrange $curr_tag $index+1c]
      if {[string index $curr_tag 8] eq "l"} {
        set start_tag [lsearch -inline -glob [$win tag names [lindex $range 0]] _lCommentStart:*]
        lappend ranges {*}[$win tag prevrange $start_tag [lindex $range 0]+1c] [lindex $range 1]
      } else {
        set start_tag [lsearch -inline -glob [$win tag names [lindex $range 0]]    _cCommentStart:*]
        set end_tag   [lsearch -inline -glob [$win tag names [lindex $range 1]-1c] _cCommentEnd:*]
        lappend ranges {*}[$win tag prevrange $start_tag [lindex $range 0]+1c]
        lappend ranges {*}[$win tag prevrange $end_tag [lindex $range 1]]
      }
      return $ranges
    }

    return [list]

  }

  ######################################################################
  proc inBackTickRange {win index prange} {

    return [inCommentStringRangeHelper $win $index _comstr0b* $prange]

  }

  ######################################################################
  proc inSingleQuoteRange {win index prange} {

    return [inCommentStringRangeHelper $win $index _comstr0s* $prange]

  }

  ######################################################################
  proc inDoubleQuoteRange {win index prange} {

    return [inCommentStringRangeHelper $win $index _comstr0d* $prange]

  }

  ######################################################################
  proc inStringRange {win index prange} {

    return [inCommentStringRangeHelper $win $index _comstr0* $prange]

  }

  ######################################################################
  proc inCommentStringRange {win index prange} {

    return [inCommentStringRangeHelper $win $index _comstr* $prange]

  }

  ######################################################################
  proc handleFocusIn {win} {

    variable data

    __ctextJunk$win configure -bg $data($win,config,-highlightcolor)

  }

  ######################################################################
  proc handleFocusOut {win} {

    variable data

    __ctextJunk$win configure -bg $data($win,config,-unhighlightcolor)

  }

  ######################################################################
  proc set_border_color {win color} {

    __ctextJunk$win configure -bg $color

  }

  ######################################################################
  # Returns 1 if the character at the given index is escaped; otherwise, returns 0.
  proc isEscaped {win index} {

    return [model::is_escaped $win $index]

  }

  ######################################################################
  # Returns a Tcl list containing the indices of all comment markers
  # in the specified ranges.
  proc getCommentMarkers {win ranges} {

    return [model::get_comment_markers $win $ranges]

  }

  ######################################################################
  # Performs a single undo operation from the undo buffer and adjusts the
  # buffers accordingly.
  proc undo {win} {

    lassign [model::undo $win] cmds cursor

    # Get the undo information and execute the returned commands
    foreach cmd $cmds {
      $win._t {*}$cmd
    }

    # Get the lines that have changed
    set ranges [$win._t tag ranges hl]
    $win._t tag delete hl

    # Highlight text and bracket auditing
    highlightAll $win $ranges 0 0

    # Set the cursor and let other know that the text widget was modified
    ::tk::TextSetCursor $win.t $cursor
    modified $win 1 [list undo $ranges ""]

  }

  ######################################################################
  # Performs a single redo operation, adjusting the contents of the undo
  # and redo buffers accordingly.
  proc redo {win} {

    variable data

    lassign [model::redo $win] cmds cursor

    # Get the undo information and execute the returned commands
    foreach cmd $cmds {
      $win._t {*}$cmd
    }

    # Get the lines that have changed
    set ranges [$win._t tag ranges hl]
    $win._t tag delete hl

    # Highlight text and bracket auditing
    highlightAll $win $ranges 0 0

    # Set the cursor and let other know that the text widget was modified
    ::tk::TextSetCursor $win.t $cursor
    modified $win 1 [list redo $ranges ""]

  }

  ######################################################################
  # This procedure is the main command handler when the ctext widget is
  # used as a command.  This basically just calls the associated command
  # procedure and returns its result to the caller.
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
      gutter      { return [command_gutter      $win {*}$args] }
      highlight   { return [command_highlight   $win {*}$args] }
      insert      { return [command_insert      $win {*}$args] }
      is          { return [command_is          $win {*}$args] }
      marker      { return [command_marker      $win {*}$args] }
      mcursor     { return [command_mcursor     $win {*}$args] }
      replace     { return [command_replace     $win {*}$args] }
      paste       { return [command_paste       $win {*}$args] }
      peer        { return [command_peer        $win {*}$args] }
      tag         { return [command_tag         $win {*}$args] }
      default     { return [uplevel 1 [linsert $args 0 $win._t $cmd]] }
    }

  }

  ######################################################################
  # If called with no arguments, appends the currently selected text to
  # the clipboard.  If called with a single index argument, appends the
  # character at the given position to the clipboard.  If called with
  # two arguments, appends the text range to the clipboard.
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

  ######################################################################
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

  ######################################################################
  # Configures the widget.
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

  ######################################################################
  # If text is currently selected, clears the clipboard and adds the selected
  # text to the clipboard; otherwise, clears the clipboard and adds the contents
  # of the current line to the clipboard.
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

  ######################################################################
  # If text is currently selected, clears the clipboard, adds the selected
  # text to the clipboard and deletes the selected text.  If no text is
  # selected, performs the same procedure with the contents of the current
  # line.
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

  ######################################################################
  # Deletes one or more ranges of text and performs syntax highlighting.
  proc command_delete {win args} {

    variable data
    variable tpool

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -moddata   {}
      -highlight 0
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    set ranges [list]

    if {[set cursors [$win._t tag ranges mcursor]] ne ""} {
      foreach {endPos startPos} [lreverse $cursors] {
        lappend strs   [$win._t get $startPos $endPos]
        lappend starts $startPos
        lappend ends   $endPos
        $win._t delete $startPos $endPos
        lappend ranges $startPos $endPos
      }
    } else {
      lassign [lrange $args $i end] startPos endPos
      set cursors  [$win._t index insert]
      set startPos [$win._t index $startPos]
      if {$endPos eq ""} {
        set endPos [$win._t index "$startPos+1c"]
      } else {
        set endPos [$win._t index $endPos]
      }
      lappend strs   [$win._t get $startPos $endPos]
      lappend starts $startPos
      lappend ends   $endPos
      $win._t delete $startPos $endPos
      lappend ranges $startPos $endPos
    }

    # Cause the model to handle the deletion
    model::delete $win $ranges $strs [$win index insert] $data($win,config,-linemap_mark_command)

    # Update the undo information
    set ids [tpool::post $tpool [list ctext::undo_delete $win $startPos $endPos $strs]]

    while {[llength $ids]} {
      tpool::wait $tpool $ids ids
    }

    if {$opts(-highlight)} {
      highlightAll $win $ranges 0 1
    }

    modified     $win 1 [list delete $ranges $opts(-moddata)]
    event generate $win.t <<CursorChanged>>

  }

  ######################################################################
  # Allows external code to program difference information for rendering
  # purposes.
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
    linemapUpdate $win 1

  }

  ######################################################################
  # Performs text highlighting on the given ranges.
  proc command_highlight {win args} {

    variable data

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -moddata  {}
      -insert   0
      -modified 0
      -block    1
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    set ranges [list]
    foreach {start end} [lrange $args $i end] {
      lappend ranges [$win._t index "$start linestart"] [$win._t index "$end lineend"]
    }

    highlightAll $win $ranges $opts(-insert) $opts(-block)
    modified     $win $opts(-modified) [list highlight $ranges $opts(-moddata)]

  }

  ######################################################################
  # Inserts text at the given cursor or at multicursors (if set) and
  # performs highlighting on that text.  Additionally, updates the undo
  # buffer.
  proc command_insert {win args} {

    variable data
    variable tpool

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -moddata   {}
      -highlight 1
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    lassign [lrange $args $i end] insertPos content tags

    set ranges  [list]
    set chars   [string length $content]
    set tags    [list {*}$tags lmargin rmargin]
    set cursor  [$win._t index insert]

    # Insert the text
    if {[set cursors [$win._t tag ranges mcursor]] ne ""} {
      foreach {endPos startPos} [lreverse $cursors] {
        $win._t insert $startPos $content $tags
        lappend ranges  $startPos [$win._t index "$startPos+${chars}c"]
      }
    } else {
      if {$insertPos eq "end"} {
        set insPos [$win._t index $insertPos-1c]
      } else {
        set insPos [$win._t index $insertPos]
      }
      $win._t insert $insertPos $content $tags
      lappend ranges  $insPos [$win._t index "$insPos+${chars}c"]
    }

    # Update the model
    model::insert $win $ranges $content $cursor

    # Highlight text and bracket auditing
    if {$opts(-highlight)} {
      highlightAll $win $ranges 1 1
    }

    modified       $win 1 [list insert $ranges $opts(-moddata)]
    event generate $win.t <<CursorChanged>>

  }

  ######################################################################
  # Allows code to examine the contents of a given index.
  proc command_is {win args} {

    lassign $args type index

    set index [$win._t index $index]

    switch $type {
      escaped { return [model::is_escaped $win $index] }
      curly   { return [model::is_index $win curly   $index] }
      square  { return [model::is_index $win square  $index] }
      paren   { return [model::is_index $win paren   $index] }
      angled  { return [model::is_index $win angled  $index] }
      double  { return [model::is_index $win double  $index] }
      single  { return [model::is_index $win single  $index] }
      btick   { return [model::is_index $win btick   $index] }
      tdouble { return [model::is_index $win tdouble $index] }
      tsingle { return [model::is_index $win tsingle $index] }
      tbtick  { return [model::is_index $win tbtick  $index] }
      default { return -code error "Unsupported is type ($type) specified" }
    }

  }

  ######################################################################
  # Allows the users to interact with the linemap bookmarks.
  proc command_marker {win args} {

    variable data

    switch [lindex $args 0] {
      set     { linemapSetMark $win {*}$args] }
      getname { return [model::get_marker_name $win [lindex $args 1]] }
      getline { return [model::get_marker_line $win [lindex $args 1]] }
      clear   { linemapClearMark $win [lindex $args 1] }
      default {
        return -code error "Illegal ctext marker command ([lindex $args 0])"
      }
    }

  }

  ######################################################################
  # Allows the users to interact with multicursor support within the widget.
  proc command_mcursor {win args} {

    variable data

    switch [lindex $args 0] {
      add {
        foreach index [lrange $args 1 end] {
          $win._t tag add mcursor $index
        }
      }
      remove {
        $win._t tag remove mcursor {*}[lrange $args 1 end]
      }
      default {
        return -code error "Illegal ctext mcursor command ([lindex $args 0])"
      }
    }

  }

  ######################################################################
  # Performs a text replace for a single or multiple cursors, performing
  # syntax highlighting and other functions.
  proc command_replace {win args} {

    variable data

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -moddata   {}
      -highlight 1
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    lassign [lrange $args $i end] startPos endPos content tags

    set ranges [list]
    set cursor [$win._t index insert]
    set chars  [string length $content]

    # Insert the text
    if {[set cursors [$win._t tag ranges mcursor]] ne ""} {
      foreach {endPos startPos} [lreverse $cursors] {
        lappend strs [$win._t get $startPos $endPos]
        $win._t replace $startPos $endPos $content $tags
        lappend ranges  $startPos $endPos [$win._t index "$startPos+${chars}c"]
      }
    } else {
      set startPos [$win._t index $startPos]
      set endPos   [$win._t index $endPos]
      lappend strs [$win._t get $startPos $endPos]
      $win._t replace $startPos $endPos $content $tags
      lappend ranges  $startPos $endPos [$win._t index "$insPos+${chars}c"]
    }

    # Update the model
    model::replace $win $ranges $strs $content $cursor $data($win,config,-linemap_mark_command)

    # Highlight text and bracket auditing
    if {$opts(-highlight)} {
      highlightAll $win $ranges 1 1
    }
    modified     $win 1 [list replace $ranges $opts(-moddata)]
    event generate $win.t <<CursorChanged>>
  }

  ######################################################################
  # Handles a paste operation.
  proc command_paste {win args} {

    variable data

    set moddata [list]
    if {[lindex $args 0] eq "-moddata"} {
      set args [lassign $args dummy moddata]
    }

    set insertPos [$win._t index insert]
    set content   [clipboard get]
    set datalen   [string length $content]

    # model::insert $win $ranges $content $cursor
    # undo_insert $win $insertPos $datalen [$win._t index insert]

    tk_textPaste $win

    # handleInsertAt0 $win._t $insertPos $datalen
    modified $win 1 [list insert [list $insertPos [$win._t index "$insertPos+${datalen}c"]] $moddata]
    event generate $win.t <<CursorChanged>>

  }

  ######################################################################
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

  ######################################################################
  # We need to guarantee that embedded language tags are always listed as lowest
  # priority, so if someone calls the lower tag subcommand, we need to make sure
  # that it won't be placed lower than an embedded language tag.
  proc command_tag {win args} {

    variable range_cache

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
        set args0        [set args1 [lassign $args subcmd tag]]
        set indent_tags  [list _indent _unindent _reindent _reindentStart]
        set bracket_tags [list _curlyL _curlyR _squareL _squareR _parenL _parenR _angledL _angledR]
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
        set tag          [lindex $args 1]
        set bracket_tags [list _curlyL _curlyR _squareL _squareR _parenL _parenR _angledL _angledR]
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
        return [$win._t tag {*}$args]
      }
    }

  }

  ######################################################################
  # Performs the edit command.
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
        return [model::undoable $win]
      }
      redoable {
        return [model::redoable $win]
      }
      separator {
        model::add_separator $win
      }
      reset {
        model::undo_reset $win
        set data($win,config,modified) false
      }
      cursorhist {
        return [model::cursor_history $win]
      }
      default {
        return [uplevel 1 [linsert $args 0 $win._t $cmd]]
      }
    }

  }

  ######################################################################
  # Process the gutter command.
  proc command_gutter {win args} {

    variable data

    set args [lassign $args subcmd]
    switch -glob $subcmd {
      create {
        model::guttercreate $win {*}$args
        linemapUpdate $win 1
      }
      destroy {
        model::gutterdestroy $win {*}$args
        linemapUpdate $win 1
      }
      hide {
        if {[llength $args] == 1} {
          return [model::gutterhide $win {*}$args]
        } else {
          model::gutterhide $win {*}$args
          linemapUpdate $win 1
        }
      }
      del* {
        model::gutterdelete $win {*}$args
        linemapUpdate $win 1
      }
      set {
        model::gutterset $win [lindex $args 0] [lrange $args 1 end]
        linemapUpdate $win 1
      }
      unset {
        model::gutterunset $win {*}$args
        linemapUpdate $win 1
      }
      get {
        return [model::gutterget $win {*}$args]
      }
      cget {
        return [model::guttercget $win {*}$args]
      }
      conf* {
        if {[llength $args] < 2} {
          return [model::gutterconfigure $win {*}$args]
        } else {
          model::gutterconfigure $win {*}$args
          linemapUpdate $win 1
        }
      }
      names {
        return [model::gutternames $win]
      }
    }

  }

  ######################################################################
  proc getAutoMatchChars {win lang} {

    variable data

    set chars [list]

    foreach name [array names data $win,config,matchChar,$lang,*] {
      lappend chars [lindex [split $name ,] 4]
    }

    return $chars

  }

  ######################################################################
  proc setAutoMatchChars {win lang matchChars} {

    variable data

    # Clear the matchChars
    catch { array unset data $win,config,matchChar,$lang,* }

    # Remove the brackets
    catch { $win._t tag delete missing }

    # Set the matchChars
    foreach matchChar $matchChars {
      set data($win,config,matchChar,$lang,$matchChar) 1
    }

    # Set the bracket auditing tags
    $win._t tag configure missing -background $data($win,config,-matchaudit_bg)

  }

  ######################################################################
  # Checks to see if the current character contains a matching bracket
  # and highlights the matching bracket.
  proc matchBracket {win} {

    variable data

    # Clear the matchchar tag
    catch { $win._t tag remove matchchar 1.0 end }

    # If we are in block cursor mode, use the previous character
    if {![$win cget -blockcursor] && [$win compare insert != "insert linestart"]} {
      set pos [$win._t index "insert-1c"]
    } else {
      set pos [$win._t index insert]
    }

    # Render the matching character
    parsers::render_match_char $win $pos

  }

  ######################################################################
  # Returns the index of the bracket type previous to the given index.
  proc getPrevBracket {win stype {index insert}} {

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
  proc getNextBracket {win stype {index insert}} {

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
  #   getMatchBracket $txt squareR
  proc getMatchBracket {win stype {index insert}} {

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

  ######################################################################
  # Returns the language the is being represented at the given index.
  # If the primary language is being used, the empty string is returned.
  proc getLang {win index} {

    return [lindex [split [lindex [$win tag names $index] 0] =] 1]

  }

  ######################################################################
  # Adds the given context patterns for parsing purposes.  If the patterns
  # list is empty, deletes the given context tags.
  proc setContextPatterns {win type tag lang patterns {fg "grey"} {bg ""}} {

    variable data

    if {[llength $patterns] > 0} {

      # Get the context tags
      set tags [tsv::get contexts $win]

      array set strings {
        double  \"
        single  '
        btick   `
        tdouble \"\"\"
        tsingle '''
        tbtick  ```
      }

      # Add the tag patterns
      set i [llength $tags]
      foreach pattern $patterns {
        if {[llength $pattern] == 1} {
          if {[info exists strings([lindex $pattern 0])]} {
            lappend tags $type:$i any $strings([lindex $pattern 0]) $lang
          } else {
            lappend tags $type:$i any [lindex $pattern 0] $lang
          }
        } else {
          lappend tags $type:$i left  [lindex $pattern 0] $lang
          lappend tags $type:$i right [lindex $pattern 1] $lang
        }
        model::add_types $win $type:$i _$tag
        incr i
      }

      # Save the context data
      tsv::set contexts $win $tags

      # Handle the comment colorization
      $win tag configure _$tag -foreground $fg -background $bg
      $win tag lower     _$tag sel

    } else {

      catch { $win tag delete _$tag }

    }

  }

  ######################################################################
  # Adds the given indentation patterns for parsing purposes.
  proc setIndentation {win lang patterns} {

    # Get the indentation tags
    set tags [tsv::get indents $win]

    set i [llength $tags]
    foreach pattern $patterns {
      if {[lsearch [list curly paren square angled] $pattern] == -1} {
        lappend tags indent:$i left  [lindex $pattern 0] $lang
        lappend tags indent:$i right [lindex $pattern 1] $lang
        model::add_types $win indent:$i
        incr i
      }
    }

    # Save the context data
    tsv::set indents $win $tags

  }

  ######################################################################
  # Adds the given brackets for parsing purposes.
  proc setBrackets {win lang types {fg "green"} {bg ""}} {

    array set btag_types {
      curly  {curly  left {\{} "%s" curly  right {\}} "%s"}
      square {square left {\[} "%s" square right {\]} "%s"}
      paren  {paren  left {\(} "%s" paren  right {\)} "%s"}
      angled {angled left <    "%s" angled right >    "%s"}
    }
    array set ctag_types {
      double  {double  any {\"}     "%s"}
      single  {single  any '        "%s"}
      btick   {btick   any `        "%s"}
      tdouble {tdouble any {\"\"\"} "%s"}
      tsingle {tsingle any '''      "%s"}
      tbtick  {tbtick  any ```      "%s"}
    }

    # Get the brackets
    set ctags [tsv::get contexts $win]
    set btags [tsv::get brackets $win]

    foreach type $types {
      if {[info exists btag_types($type)]} {
        lappend btags {*}[format $btag_types($type) $lang $lang]
        model::add_types $win $type
      } elseif {[info exists ctag_types($type)]} {
        lappend ctags {*}[format $ctag_types($type) $lang]
        $win._t tag configure _string -foreground $fg -background $bg
        $win._t tag lower     _string sel
        model::add_types $win $type _string
      }
    }

    # Save the brackets
    tsv::set brackets $win $btags
    tsv::set contexts $win $ctags

  }

  ######################################################################
  # Main procedure used for performing all necessary syntax tagging and
  # highlighting.  This 'ins' parameter should be set to 1 if we are being
  # called after inserting the text that is being highlighted; otherwise, it
  # should be set to 0.  The 'block' parameter causes this call to wait for
  # all syntax highlighting to be applied prior to returning.  The 'do_tag'
  # list should be derived from the list of tags that were deleted that
  # would cause us to re-evaluate the comment parser.  This highlight
  # procedure can automatically highlight one or more ranges of text.
  proc highlightAll {win lineranges ins block} {

    variable data
    variable range_cache

    # If we don't have any lineranges, return
    if {$lineranges eq ""} {
      return
    }

    # Delete all of the tags not associated with comments and strings that we created
    foreach tag [$win._t tag names] {
      if {[string index $tag 0] eq "_"} {
        $win._t tag remove $tag {*}$lineranges
      }
    }

    highlight $win $lineranges $ins $block

    event generate $win.t <<StringCommentChanged>>

  }

  ######################################################################
  # Returns the indices of the given tag that are found within the given
  # text range.
  proc getTagInRange {win tag start end} {

    set indices [list]

    while {[set tag_end [lassign [$win tag nextrange $tag $start $end] tag_start]] ne ""} {
      lappend indices $tag_start $tag_end
      set start $tag_end
    }

    return $indices

  }

  ######################################################################
  proc add_font_opt {win class modifiers popts} {

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

      lappend opts -font $fontname {*}[array get tag_opts] {*}[array get line_opts]

      if {$click} {
        set data($win,highlight,click,$class) $opts
      }

    }

  }

  ######################################################################
  proc addHighlightClass {win class fgcolor {bgcolor ""} {font_opts ""}} {

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

  ######################################################################
  proc addHighlightKeywords {win keywords type value {lang ""}} {

    variable data

    if {$type eq "class"} {
      set value _$value
    }

    foreach word $keywords {
      set data($win,highlight,keyword,$type,$lang,$word) $value
    }

  }

  ######################################################################
  proc addHighlightRegexp {win re type value {lang ""}} {

    variable data

    if {$type eq "class"} {
      set value _$value
    }

    lappend data($win,highlight,regexps) "regexp,$type,$lang,$value"

    set data($win,highlight,regexp,$type,$lang,$value) [list $re $data($win,config,re_opts)]

  }

  ######################################################################
  # For things like $blah
  proc addHighlightWithOnlyCharStart {win char type value {lang ""}} {

    variable data

    if {$type eq "class"} {
      set value _$value
    }

    set data($win,highlight,charstart,$type,$lang,$char) $value

  }

  ######################################################################
  proc addSearchClass {win class fgcolor bgcolor modifiers str} {

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

  ######################################################################
  proc addSearchClassForRegexp {win class fgcolor bgcolor modifiers re {re_opts ""}} {

    variable data

    addHighlightClass $win $class $fgcolor $bgcolor $modifiers

    if {$re_opts eq ""} {
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

  ######################################################################
  proc deleteHighlightClass {win classToDelete} {

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

  ######################################################################
  proc getHighlightClasses {win} {

    variable data

    set classes [list]
    foreach class [array names data $win,classes,*] {
      lappend classes [string range [lindex [split $class ,] 2] 1 end]
    }

    return $classes

  }

  ######################################################################
  proc clearHighlightClasses {win} {

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

  ######################################################################
  # Helper procedure that allows us to generate debug messages from within
  # the threads.
  proc thread_log {id nl msg} {

    if {$nl} {
      puts "$id: $msg"
    } else {
      puts -nonewline "$id: $msg"
    }

  }

  ######################################################################
  # Renders the given tag with the specified ranges in the given widget.
  proc render {win tag ranges clear_all} {

    # puts "In render, tag: $tag, ranges: $ranges, clear_all: $clear_all"

    if {$clear_all} {
      $win._t tag remove $tag 1.0 end
    }

    if {[set num [llength $ranges]]} {
      if {($num % 2) == 1} {
        $win._t tag add $tag {*}$ranges end
      } else {
        $win._t tag add $tag {*}$ranges
      }
    }

  }

  ######################################################################
  proc handle_tag {win class startpos endpos cmd} {

    variable data
    variable right_click

    # Add the tag and possible binding
    if {[info exists data($win,highlight,click,$class)]} {
      set tag _$class[incr data($win,highlight,click_index)]
      $win tag add       $tag $startpos $endpos
      $win tag configure $tag {*}$data($win,highlight,click,$class)
      $win tag bind      $tag <Button-$right_click> [list {*}$cmd $tag]
      return ""
    }

    return [list _$class $startpos $endpos]

  }

  ######################################################################
  # Performs all of the syntax highlighting.
  proc highlight {win ranges ins {block 1}} {

    variable data
    variable tpool

    if {![winfo exists $win] || !$data($win,config,-highlight) || ($ranges eq "")} {
      return
    }

    # We need to handle multiple ranges here
    lassign $ranges start end

    set jobids    [list]
    set linestart [$win._t index "$start linestart"]
    set lineend   [$win._t index "$end lineend"]
    set startrow  [lindex [split $linestart .] 0]
    set str       [$win._t get $linestart $lineend]
    set namelist  [array get data $win,highlight,keyword,class,,*]
    set startlist [array get data $win,highlight,charstart,class,,*]

    # Perform bracket parsing
    lappend jobids [tpool::post $tpool \
      [list parsers::markers $win $str $linestart $lineend] \
    ]

    # Mark the prewhite space
    lappend jobids [tpool::post $tpool \
      [list parsers::prewhite $win $str $startrow] \
    ]

    # Perform keyword/startchars parsing
    lappend jobids [tpool::post $tpool \
      [list parsers::keywords_startchars $win $str $startrow $namelist $startlist $data($win,config,-delimiters) $data($win,config,-casesensitive)] \
    ]

    # Handle regular expression parsing
    if {[info exists data($win,highlight,regexps)]} {
      foreach name $data($win,highlight,regexps) {
        lassign [split $name ,] dummy type lang value
        lassign $data($win,highlight,$name) re re_opts
        if {$type eq "class"} {
          lappend jobids [tpool::post $tpool \
            [list parsers::regexp_class $win $str $startrow $re $value] \
          ]
        } else {
          # TBD - Need to add command
          lappend jobids [tpool::post $tpool \
            [list parsers::regexp_command $win $str $startrow $re $value $ins] \
          ]
        }
      }
    }

    # If we need to block for some reason, do it here
    if {$block} {
      while {[llength $jobids]} {
        tpool::wait $tpool $jobids jobids
      }
    }

  }

  ######################################################################
  # Toggles the bookmark indicator in the linemap.
  proc linemapToggleMark {win x y} {

    variable data

    if {!$data($win,config,-linemap_markable)} {
      return
    }

    set row [lindex [split [$win._t index @0,$y] .] 0]

    # Toggle the bookmark
    if {[model::get_marker_name $win $row] eq ""} {
      set lmark "lmark[incr data($win,linemap,id)]"
      model::set_marker $win $row $lmark
      set type marked
    } else {
      set lmark ""
      model::set_marker $win $row $lmark
      set type unmarked
    }

    # Update the linemap
    linemapUpdate $win 1

    # Call the mark command, if one exists.  If it returns a value of 0, remove the mark.
    set cmd $data($win,config,-linemap_mark_command)
    if {[string length $cmd] && ![uplevel #0 [linsert $cmd end $win $type $lmark]]} {
      model::set_marker $win $row ""
      linemapUpdate $win 1
    }

  }

  ######################################################################
  # Sets the bookmark for the given line to an automatic name or the
  # provided name.
  proc linemapSetMark {win line {name ""}} {

    variable data

    # If the user did not provide a name, create one
    if {$name eq ""} {
      set name "lmark[incr data($win,linemap,id)]"
    }

    # Set the marker and update the linemap
    model::set_marker $win $line $name
    linemapUpdate $win 1

    return $name

  }

  ######################################################################
  # Clears the linemap marker if it is set.
  proc linemapClearMark {win line} {

    # Clear the marker and update the linemap
    model::set_marker $win $line ""
    linemapUpdate $win 1

  }

  ######################################################################
  # Indicates the a linemap update is needed based on text changes.
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

  ######################################################################
  # Updates the linemap area to match the text widget.
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

    set first         [lindex [split [$win._t index @0,0] .] 0]
    set last          [lindex [split [$win._t index @0,[winfo height $win.t]] .] 0]
    set line_width    [string length [lindex [split [$win._t index end-1c] .] 0]]
    set linenum       $data($win,config,-linemap)
    set linenum_width [expr $linenum ? max( $data($win,config,-linemap_minwidth), $line_width ) : 1]
    set gutterx       [expr ($linenum_width * $data($win,fontwidth)) + 1]
    set marker        $data($win,config,-linemap_mark_color)
    set normal        $data($win,config,-linemapfg)
    set font          $data($win,config,-font)
    set fontwidth     $data($win,fontwidth)
    set descent       $data($win,fontdescent)
    set full_width    $gutterx
    set y             1
    set colormap      [list %m $marker %n $normal]
    set ins           [lindex [split [$win._t index insert] .] 0]

    # If we are displaying absolute line numbers, set the insertion row to 0
    if {$data($win,config,-linemap_type) eq "absolute"} {
      set ins 0
    }

    # Clear the canvas
    $win.l delete all

    # Draw the linemap
    foreach line [string map $colormap [model::render_linemap $win $first $last]] {
      lassign $line lnum fill gutters
      if {[$win._t count -displaychars $lnum.0 [expr $lnum + 1].0] == 0} { continue }
      lassign [$win._t dlineinfo $lnum.0] x y w h b
      set x $gutterx
      set y [expr $y + $b + $descent]
      if {$linenum} {
        $win.l create text 1 $y -anchor sw -text [expr abs( $lnum - $ins )] -fill $fill -font $font
      } elseif {$fill == $marker} {
        $win.l create text 1 $y -anchor sw -text "M" -fill $fill -font $font
      }
      foreach gutter $gutters {
        lassign $gutter sym fill bindings
        set item [$win.l create text $x $y -anchor sw -text $sym -fill $fill -font $font]
        foreach {event command} $bindings {
          $win.l bind $item <$event> [list uplevel #0 [list {*}$command $win $lnum]]
        }
        set full_width [incr x $fontwidth]
      }
    }

    # Resize the linemap window, if necessary
    if {[$win.l cget -width] != [incr full_width]} {
      $win.l configure -width $full_width
    }

  }

  ######################################################################
  proc doConfigure {win} {

    # Update the linemap
    linemapUpdate $win

    # Update the rmargin
    adjust_rmargin $win

  }

  ######################################################################
  proc set_rmargin {win startpos endpos} {

    $win tag add rmargin $startpos $endpos
    $win tag add lmargin $startpos $endpos

  }

  ######################################################################
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

  ######################################################################
  # Called whenever the contents of the associated text widget change,
  # allowing external code listening to the widget's <<Modified>> event
  # to be invoked.
  proc modified {win value {dat ""}} {

    variable data

    set data($win,config,modified) $value
    event generate $win <<Modified>> -data $dat

    return $value

  }

  ######################################################################
  # Called when the -foldstate variable is set to a non-"none" value.
  proc enable_folding {win} {

    variable data

    set open_color  "white"
    set close_color "blue"

    $win gutter create folding \
      open   [list -symbol \u25be -fg $open_color  -onclick [list ctext::close_fold 1] -onshiftclick [list ctext::close_fold 0]] \
      close  [list -symbol \u25b8 -fg $close_color -onclick [list ctext::open_fold  1] -onshiftclick [list ctext::open_fold  0]] \
      eopen  [list -symbol \u25be -fg $open_color  -onclick [list ctext::close_fold 1] -onshiftclick [list ctext::close_fold 0]] \
      eclose [list -symbol \u25b8 -fg $close_color -onclick [list ctext::open_fold  1] -onshiftclick [list ctext::open_fold  0]] \
      end    [list -symbol \u221f -fg $open_color]

    # Configure the _folded tag to hide code
    $win._t tag configure _folded -elide 1

    # Add the fold information to the gutter
    # TBD

  }

  ######################################################################
  # Called when the -foldstate variable is set to a "none" value.
  proc disable_folding {win} {

    # Remove all folded text
    $win._t tag remove _folded 1.0 end

    # Remove the gutter
    $win gutter destroy folding

  }

  ######################################################################
  # Opens a folded line, showing its contents.
  proc open_fold {depth win line} {

    variable data

    array set map {
      close  open
      open   open
      eclose eopen
      eopen  eopen
    }

    # Get the fold range
    lassign [get_fold_range $win $line [expr ($depth == 0) ? 100000 : $depth]] startpos endpos belows aboves closed

    # Adjust the linemap folding symbols
    foreach tline [concat $belows $aboves] {
      set type [$win gutter get folding $line]
      $win gutter clear folding $tline
      $win gutter set folding $map($type) $tline
    }

    # Remove the folded tag
    $win._t tag remove _folded $startpos $endpos

    # Close all of the previous folds
    if {$depth > 0} {
      foreach tline [::struct::set intersect $aboves $closed] {
        close_fold 1 $win $tline
      }
    }

    # Update the linemap
    linemapUpdate $win

    return $endpos

  }

  ######################################################################
  # Closes a folded line, hiding its contents.
  proc close_fold {depth win line} {

    array set map {
      open   close
      close  close
      eopen  eclose
      eclose eclose
    }

    # Get the fold range
    lassign [get_fold_range $win $line [expr ($depth == 0) ? 100000 : $depth]] startpos endpos belows

    # Add the folded tag
    $win._t tag add _folded $startpos $endpos

    # Replace the open/eopen symbol with the close/eclose symbol
    foreach line $belows {
      set type [$win gutter get folding $line]
      $win gutter clear folding $line
      $win gutter set folding $map($type) $line
    }

    return $endpos

  }

  ######################################################################
  # Returns the folding information for the given line.
  proc get_fold_range {win line depth} {

    variable data

    if {$data($win,config,-foldstate) eq "indent"} {
      return [get_fold_range_indent $win $line $depth]
    } else {
      return [get_fold_range_other $win $line $depth]
    }

  }

  ######################################################################
  # Returns the folding information for the given line when we are in
  # indent folding state.
  proc get_fold_range_indent {win line depth} {

    set count  0
    set aboves [list]
    set belows [list]
    set closed [list]

    set start_chars [$win._t count -chars {*}[$win._t tag nextrange _prewhite $line.0]]
    set next_line   $line.0
    set final       [lindex [split [$win._t index end] .] 0].0
    set all_chars   [list]

    while {[set range [$win._t tag nextrange _prewhite $next_line]] ne ""} {
      set chars [$win._t count -chars {*}$range]
      set tline [lindex [split [lindex $range 0] .] 0]
      set state [fold_state $win $tline]
      if {($state eq "close") || ($state eq "eclose")} {
        lappend closed $tline
      }
      if {($chars > $start_chars) || ($all_chars eq [list])} {
        if {($state ne "none") && ($state ne "end")} {
          lappend all_chars [list $tline $chars]
        }
      } else {
        set final $tline.0
        break
      }
      set next_line [lindex $range 1]
    }

    set last $start_chars
    foreach {tline chars} [concat {*}[lsort -integer -index 1 $all_chars]] {
      incr count [expr $chars != $last]
      if {$count < $depth} {
        lappend belows $tline
      } else {
        lappend aboves $tline
      }
      set last $chars
    }

    return [list [expr $line + 1].0 $final $belows $aboves $closed]

  }

  ######################################################################
  # Returns the folding information for the given line when we are in
  # indent folding state.
  proc get_fold_range_other {win line depth} {

    # Get the information from the linemap model (this should be much faster than processing
    # this information ourselves
    lassign [model::get_fold_info $win $line $depth] startline endline belows aboves closed

    if {$endline eq ""} {
      set endline "end"
    } else {
      append endline ".0"
    }

    return [list [expr $startline + 1].0 $endline $belows $aboves $closed]

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

  ctext::modified           $win 0
  ctext::buildArgParseTable $win
  ctext::adjust_rmargin     $win

  return $win

}
