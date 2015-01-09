# By George Peter Staplin
# See also the README for a list of contributors
# RCS: @(#) $Id: ctext.tcl,v 1.9 2011/04/18 19:49:48 andreas_kupries Exp $

package require Tk
package provide ctext 4.0

namespace eval ctext {
  array set REs {
    words  {([^\s\(\{\[\}\]\)\.\t\n\r;:=\"'\|,<>]+)}
  }
}

#win is used as a unique token to create arrays for each ctext instance
proc ctext::getAr {win suffix name} {
  set arName __ctext[set win][set suffix]
  uplevel [list upvar \#0 $arName $name]
  return $arName
}

proc ctext {win args} {
  if {[llength $args] & 1} {
    return -code error \
    "invalid number of arguments given to ctext (uneven number after window) : $args"
  }

  frame $win -class Ctext -padx 1 -pady 1

  set tmp [text .__ctextTemp]

  ctext::getAr $win config ar

  set ar(-fg)                    [$tmp cget -foreground]
  set ar(-bg)                    [$tmp cget -background]
  set ar(-font)                  [$tmp cget -font]
  set ar(-relief)                [$tmp cget -relief]
  set ar(-unhighlightcolor)      [$win cget -bg]
  destroy $tmp
  set ar(-xscrollcommand)        ""
  set ar(-yscrollcommand)        ""
  set ar(-highlightcolor)        "yellow"
  set ar(-linemap)               1
  set ar(-linemapfg)             $ar(-fg)
  set ar(-linemapbg)             $ar(-bg)
  set ar(-linemap_mark_command)  {}
  set ar(-linemap_markable)      1
  set ar(-linemap_show_current)  1
  set ar(-linemap_select_fg)     black
  set ar(-linemap_select_bg)     yellow
  set ar(-linemap_cursor)        left_ptr
  set ar(-linemap_relief)        $ar(-relief)
  set ar(-linemap_minwidth)      1
  set ar(-highlight)             1
  set ar(-warnwidth)             ""
  set ar(-warnwidth_bg)          red
  set ar(-casesensitive)         1
  set ar(-peer)                  ""
  set ar(re_opts)                ""
  set ar(win)                    $win
  set ar(modified)               0
  set ar(commentsAfterId)        ""
  set ar(blinkAfterId)           ""
  set ar(lastUpdate)             0
  set ar(block_comment_patterns) [list]
  set ar(string_patterns)        [list]
  set ar(line_comment_patterns)  [list]
  set ar(comment_re)             ""
  set ar(gutters)                [list]
  set ar(matchChar,curly)        1
  set ar(matchChar,square)       1
  set ar(matchChar,paren)        1
  set ar(matchChar,angled)       1
  set ar(matchChar,double)       1

  set ar(ctextFlags) [list -xscrollcommand -yscrollcommand -linemap -linemapfg -linemapbg \
  -font -linemap_mark_command -highlight -warnwidth -warnwidth_bg -linemap_markable \
  -linemap_show_current -linemap_cursor -highlightcolor \
  -linemap_select_fg -linemap_select_bg -linemap_relief -linemap_minwidth -casesensitive -peer]

  array set ar $args

  foreach flag {foreground background} short {fg bg} {
    if {[info exists ar(-$flag)] == 1} {
      set ar(-$short) $ar(-$flag)
      unset ar(-$flag)
    }
  }

  # Now remove flags that will confuse text and those that need
  # modification:
  foreach arg $ar(ctextFlags) {
    if {[set loc [lsearch $args $arg]] >= 0} {
      set args [lreplace $args $loc [expr {$loc + 1}]]
    }
  }

  # Initialize the starting linemap ID
  ctext::getAr $win linemap linemapAr
  set linemapAr(id) 0

  text $win.l -font $ar(-font) -width $ar(-linemap_minwidth) -height 1 \
    -relief $ar(-relief) -bd 0 -fg $ar(-linemapfg) -cursor $ar(-linemap_cursor) \
    -bg $ar(-linemapbg) -takefocus 0 -highlightthickness 0 -wrap none
  frame $win.f -width 1 -bd 0 -relief flat -bg $ar(-warnwidth_bg)

  set topWin [winfo toplevel $win]
  bindtags $win.l [list $win.l $topWin all]

  if {$ar(-linemap) == 1} {
    grid $win.l -sticky ns -row 0 -column 0
    grid $win.f -sticky ns -row 0 -column 1
  }

  set args [concat $args [list -yscrollcommand [list ctext::event:yscroll $win $ar(-yscrollcommand)]] \
                         [list -xscrollcommand [list ctext::event:xscroll $win $ar(-xscrollcommand)]]]

  #escape $win, because it could have a space
  if {$ar(-peer) eq ""} {
    text $win.t -font $ar(-font) -bd 0 -highlightthickness 0 {*}$args
  } else {
    # TBD - We should probably verify that -peer is a ctext widget path
    $ar(-peer)._t peer create $win.t -font $ar(-font) -bd 0 -highlightthickness 0 {*}$args
  }

  frame $win.t.w -width 1 -bd 0 -relief flat -bg $ar(-warnwidth_bg)

  if {$ar(-warnwidth) ne ""} {
    place $win.t.w -x [font measure [$win.t cget -font] -displayof . [string repeat "m" $ar(-warnwidth)]] -relheight 1.0
  }

  grid $win.t -row 0 -column 2 -sticky news
  grid rowconfigure    $win 0 -weight 100
  grid columnconfigure $win 2 -weight 100

  bind $win.t <Configure>         [list ctext::linemapUpdate $win]
  bind $win.l <ButtonPress-1>     [list ctext::linemapToggleMark $win %y]
  bind $win.t <KeyRelease-Return> [list ctext::linemapUpdate $win]
  bind $win.t <FocusIn>           [list ctext::handleFocusIn $win]
  bind $win.t <FocusOut>          [list ctext::handleFocusOut $win]
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

  if {$clientData == ""} {
    return
  }

  uplevel \#0 $clientData $args

  ctext::getAr $win config configAr

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

  # Width is calculated by multiplying the longest line with the length of a single character
  set newx [expr ($configAr(-warnwidth) * 7) - $missing]

  # Move the vertical bar
  place $win.t.w -x $newx -relheight 1.0

}

proc ctext::event:yscroll {win clientData args} {
  
  ctext::linemapUpdate $win

  if {$clientData == ""} {
    return
  }
  
  uplevel \#0 $clientData $args
  
}

proc ctext::event:Destroy {win dWin} {
  
  if {![string equal $win $dWin]} {
    return
  }

  ctext::getAr $win config configAr

  catch {after cancel $configAr(commentsAfterId)}
  catch {after cancel $configAr(blinkAfterId)}

  bgproc::killall ctext::*

  catch { rename $win {} }
  interp alias {} $win.t {}
  ctext::clearHighlightClasses $win
  array unset [ctext::getAr $win config ar]
    
}

# This stores the arg table within the config array for each instance.
# It's used by the configure instance command.
proc ctext::buildArgParseTable win {
    
  set argTable [list]

  lappend argTable any -linemap_mark_command {
    set configAr(-linemap_mark_command) $value
    break
  }

  lappend argTable {1 true yes} -linemap {
    grid $self.l -sticky ns -row 0 -column 0
    grid columnconfigure $self 0 \
    -minsize [winfo reqwidth $self.l]
    set configAr(-linemap) 1
    break
  }

  lappend argTable {0 false no} -linemap {
    grid forget $self.l
    grid columnconfigure $self 0 -minsize 0
    set configAr(-linemap) 0
    break
  }

  lappend argTable any -xscrollcommand {
    set cmd [list $self._t config -xscrollcommand \
    [list ctext::event:xscroll $self $value]]

    if {[catch $cmd res]} {
      return $res
    }
    set configAr(-xscrollcommand) $value
    break
  }

  lappend argTable any -yscrollcommand {
    set cmd [list $self._t config -yscrollcommand \
    [list ctext::event:yscroll $self $value]]

    if {[catch $cmd res]} {
      return $res
    }
    set configAr(-yscrollcommand) $value
    break
  }

  lappend argTable any -linemapfg {
    if {[catch {winfo rgb $self $value} res]} {
      return -code error $res
    }
    $self.l config -fg $value
    set configAr(-linemapfg) $value
    break
  }

  lappend argTable any -linemapbg {
    if {[catch {winfo rgb $self $value} res]} {
      return -code error $res
    }
    $self.l config -bg $value
    set configAr(-linemapbg) $value
    break
  }

  lappend argTable any -linemap_relief {
    if {[catch {$self.l config -relief $value} res]} {
      return -code error $res
    }
    set configAr(-linemap_relief) $value
    break
  }

  lappend argTable any -font {
    if {[catch {$self.l config -font $value} res]} {
      return -code error $res
    }
    $self._t config -font $value
    set configAr(-font) $value
    break
  }

  lappend argTable {0 false no} -highlight {
    set configAr(-highlight) 0
    break
  }

  lappend argTable {1 true yes} -highlight {
    set configAr(-highlight) 1
    break
  }

  lappend argTable any -warnwidth {
    set configAr(-warnwidth) $value
    if {$value eq ""} {
      place forget $self.t.w
    } else {
      place $self.t.w -x [font measure [$self.t cget -font] -displayof . [string repeat "m" $value]] -relheight 1.0
    }
    break
  }

  lappend argTable any -warnwidth_bg {
    if {[catch {winfo rgb $self $value} res]} {
      return -code error $res
    }
    set configAr(-warnwidth_bg) $value
    $self.t.w configure -bg $value
    $self.f   configure -bg $value
    break
  }

  lappend argTable any -highlightcolor {
    if {[catch {winfo rgb $self $value} res]} {
      return -code error $res
    }
    set configAr(-highlightcolor) $value
    break
  }

  lappend argTable {0 false no} -linemap_markable {
    set configAr(-linemap_markable) 0
    break
  }

  lappend argTable {1 true yes} -linemap_markable {
    set configAr(-linemap_markable) 1
    break
  }

  lappend argTable {0 false no} -linemap_show_current {
    set configAr(-linemap_show_current) 0
    break
  }

  lappend argTable {1 true yes} -linemap_show_current {
    set configAr(-linemap_show_current) 1
    break
  }

  lappend argTable any -linemap_select_fg {
    if {[catch {winfo rgb $self $value} res]} {
      return -code error $res
    }
    set configAr(-linemap_select_fg) $value
    $self.l tag configure lmark -foreground $value
    break
  }

  lappend argTable any -linemap_select_bg {
    if {[catch {winfo rgb $self $value} res]} {
      return -code error $res
    }
    set configAr(-linemap_select_bg) $value
    $self.l tag configure lmark -background $value
    break
  }

  lappend argTable {0 false no} -casesensitive {
    set configAr(-casesensitive) 0
    set configAr(re_opts) "-nocase"
    break
  }

  lappend argTable {1 true yes} -casesensitive {
    set configAr(-casesensitive) 1
    set configAr(re_opts) ""
    break
  }

  lappend argTable {any} -linemap_minwidth {
    if {![string is integer $value]} {
      return -code error "-linemap_minwidth argument must be an integer value"
    }
    if {[$self.l cget -width] < $value} {
      $self.l configure -width $value
    }
    set configAr(-linemap_minwidth) $value
    break
  }

  ctext::getAr $win config ar
  set ar(argTable) $argTable
}

proc ctext::setCommentRE {win} {

  ctext::getAr $win config configAr

  set commentRE {\\}
  array set chars {}

  set patterns [concat [eval concat $configAr(block_comment_patterns)] $configAr(line_comment_patterns) $configAr(string_patterns)]

  if {[llength $patterns] > 0} {
    append commentRE "|" [join $patterns |]
  }

  set bcomments [list]
  set ecomments [list]
  foreach block $configAr(block_comment_patterns) {
    lappend bcomments [lindex $block 0]
    lappend ecomments [lindex $block 1]
  }

  set configAr(comment_re)  $commentRE
  set configAr(bcomment_re) [join $bcomments |]
  set configAr(ecomment_re) [join $ecomments |]
  set configAr(lcomment_re) [join $configAr(line_comment_patterns) |]

}

proc ctext::inCommentString {win index} {
  set prev_in [expr [lsearch -regexp [$win tag names $index-1c] {_([cl]Comment|[sdt]String)}] != -1]
  set curr_in [expr [lsearch -regexp [$win tag names $index]    {_([cl]Comment|[sdt]String)}] != -1]
  return [expr $curr_in && $prev_in]
}

proc ctext::commentsAfterIdle {win start end block} {
  
  ctext::getAr $win config configAr

#   if {"" eq $configAr(commentsAfterId)} {
#     set configAr(commentsAfterId) [after idle \
#     [list ctext::comments $win $start $end $block [set afterTriggered 1]]]
#   } 
  
  ctext::comments $win $start $end $block
  
}

proc ctext::highlight {win lineStart lineEnd} {

  highlightAfterIdle $win [$win index $lineStart] [$win index $lineEnd]

}

proc ctext::highlightAfterIdle {win lineStart lineEnd} {

  ctext::getAr $win config configAr

  # If highlighting has been disabled, return immediately
  if {!$configAr(-highlight)} {
    return
  }

  # Set the lineChanged tag on all lines to highlight
#   set currRow [lindex [split $lineStart .] 0]
#   set lastRow [lindex [split $lineEnd .] 0]
#   while {1} {
#     $win tag add lineChanged $currRow.0 $currRow.end
#     if {[incr currRow] > $lastRow} {
#       break
#     }
#   }
 
  # Perform the highlight in the background
  ctext::doHighlight $win $lineStart $lineEnd
  # bgproc::command ctext::highlightAfterIdle$win "ctext::doHighlight $win" -cancelable 1

}

proc ctext::handleFocusIn {win} {

  ctext::getAr $win config configAr

  __ctextJunk$win configure -bg $configAr(-highlightcolor)

}

proc ctext::handleFocusOut {win} {

  ctext::getAr $win config configAr

  __ctextJunk$win configure -bg $configAr(-unhighlightcolor)

}

# Returns 1 if the character at the given index is escaped; otherwise, returns 0.
proc ctext::isEscaped {win index} {

  if {[regexp {^(\\*)} [string reverse [$win get "$index linestart" $index]] -> escapes]} {
    return [expr [string length $escapes] % 2]
  }

  return 0

}

proc ctext::instanceCmd {self cmd args} {

  #slightly different than the RE used in ctext::comments
  ctext::getAr $self config configAr

  # Create comment RE
  set commentRE $configAr(comment_re)

  switch -glob -- $cmd {
    append {
      if {[catch {$self._t get sel.first sel.last} data] == 0} {
        clipboard append -displayof $self $data
      }
    }

    cget {
      set arg [lindex $args 0]
      ctext::getAr $self config configAr

      foreach flag $configAr(ctextFlags) {
        if {[string match ${arg}* $flag]} {
          return [set configAr($flag)]
        }
      }
      return [$self._t cget $arg]
    }

    conf* {
      ctext::getAr $self config configAr

      if {0 == [llength $args]} {
        set res [$self._t configure]
        foreach opt [list -xscrollcommand* -yscrollcommand*] {
          set del [lsearch -glob $res $opt]
          set res [lreplace $res $del $del]
        }
        foreach flag $configAr(ctextFlags) {
          lappend res [list $flag [set configAr($flag)]]
        }
        return $res
      }

      array set flags {}
      foreach flag $configAr(ctextFlags) {
        set loc [lsearch $args $flag]
        if {$loc < 0} {
          continue
        }

        if {[llength $args] <= ($loc + 1)} {
          #.t config -flag
          return [set configAr($flag)]
        }

        set flagArg [lindex $args [expr {$loc + 1}]]
        set args [lreplace $args $loc [expr {$loc + 1}]]
        set flags($flag) $flagArg
      }

      foreach {valueList flag cmd} $configAr(argTable) {
        if {[info exists flags($flag)]} {
          foreach valueToCheckFor $valueList {
            set value [set flags($flag)]
            if {[string equal "any" $valueToCheckFor]} $cmd \
            elseif {[string equal $valueToCheckFor [set flags($flag)]]} $cmd
          }
        }
      }

      if {[llength $args]} {
        #we take care of configure without args at the top of this branch
        uplevel 1 [linsert $args 0 $self._t configure]
      }
    }

    copy {
      tk_textCopy $self
    }

    cut {
      if {[catch {$self.t get sel.first sel.last} data] == 0} {
        clipboard clear -displayof $self.t
        clipboard append -displayof $self.t $data
        $self delete [$self.t index sel.first] [$self.t index sel.last]
        ctext::modified $self 1
      }
    }

    delete {
      #delete n.n ?n.n

      set argsLength [llength $args]

      #first deal with delete n.n
      if {$argsLength == 1} {
        set deletePos [lindex $args 0]
        set prevChar [$self._t get $deletePos]

        $self._t delete $deletePos
        set char [$self._t get $deletePos]

        set prevSpace [ctext::findPreviousSpace $self._t $deletePos]
        set nextSpace [ctext::findNextSpace $self._t $deletePos]

        set lineStart [$self._t index "$deletePos linestart"]
        set lineEnd [$self._t index "$deletePos + 1 chars lineend"]

        #This pattern was used in 3.1.  We may want to investigate using it again
        #eventually to reduce flicker.  It caused a bug with some patterns.
        #if {[string equal $prevChar "#"] || [string equal $char "#"]} {
        #	set removeStart $lineStart
        #	set removeEnd $lineEnd
        #} else {
        #	set removeStart $prevSpace
        #	set removeEnd $nextSpace
        #}
        set removeStart $lineStart
        set removeEnd $lineEnd

        foreach tag [$self._t tag names] {
          if {![regexp {^_([lc]Comment|[sdt]String)$} $tag] && ([string index $tag 0] eq "_")} {
            $self._t tag remove $tag $removeStart $removeEnd
          }
        }

        set checkStr "$prevChar[set char]"

        ctext::commentsAfterIdle $self $lineStart $lineEnd [regexp {*}$configAr(re_opts) -- $commentRE $checkStr]
        ctext::highlightAfterIdle $self $lineStart $lineEnd
        ctext::linemapUpdate $self
      } elseif {$argsLength == 2} {
        #now deal with delete n.n ?n.n?
        set deleteStartPos [lindex $args 0]
        set deleteEndPos [lindex $args 1]

        set data [$self._t get $deleteStartPos $deleteEndPos]

        set lineStart [$self._t index "$deleteStartPos linestart"]
        set lineEnd [$self._t index "$deleteEndPos + 1 chars lineend"]
        eval \$self._t delete $args

        foreach tag [$self._t tag names] {
          if {![regexp {^_([lc]Comment|[sdt]String)$} $tag] && ([string index $tag 0] eq "_")} {
            $self._t tag remove $tag $lineStart $lineEnd
          }
        }

        ctext::commentsAfterIdle $self $lineStart $lineEnd [regexp {*}$configAr(re_opts) -- $commentRE $data]
        ctext::highlightAfterIdle $self $lineStart $lineEnd
        if {[string first "\n" $data] >= 0} {
          ctext::linemapUpdate $self
        }
      } else {
        return -code error "invalid argument(s) sent to $self delete: $args"
      }
      ctext::modified $self 1
    }

    fastdelete {
      eval \$self._t delete $args
      ctext::modified $self 1
      ctext::linemapUpdate $self
    }

    fastinsert {
      eval \$self._t insert $args
      ctext::modified $self 1
      ctext::linemapUpdate $self
    }

    highlight {
      set lineStart [lindex $args 0]
      set lineEnd   [lindex $args 1]
      foreach tag [$self._t tag names] {
        if {![regexp {^_([lc]Comment|[sdt]String)$} $tag] && ([string index $tag 0] eq "_")} {
          $self._t tag remove $tag $lineStart $lineEnd
        }
      }
      ctext::highlight $self $lineStart $lineEnd
      ctext::comments $self $lineStart $lineEnd 1
    }

    insert {
      if {[llength $args] < 2} {
        return -code error "please use at least 2 arguments to $self insert"
      }

      set insertPos [$self._t index [lindex $args 0]]
      set prevChar [$self._t get "$insertPos - 1 chars"]
      set nextChar [$self._t get $insertPos]
      if {[lindex $args 0] eq "end"} {
        set lineStart [$self._t index "$insertPos-1c linestart"]
      } else {
        set lineStart [$self._t index "$insertPos linestart"]
      }
      set prevSpace [ctext::findPreviousSpace $self._t ${insertPos}-1c]
      set data [lindex $args 1]
      set datalen [string length $data]
      eval \$self._t insert $args

      set nextSpace [ctext::findNextSpace $self._t "${insertPos}+${datalen}c"]
      set lineEnd [$self._t index "${insertPos}+${datalen}c lineend"]

      if {[$self._t compare $prevSpace < $lineStart]} {
        set prevSpace $lineStart
      }

      if {[$self._t compare $nextSpace > $lineEnd]} {
        set nextSpace $lineEnd
      }

      foreach tag [$self._t tag names] {
        if {![regexp {^_([lc]Comment|[sdt]String)$} $tag] && ([string index $tag 0] eq "_")} {
          $self._t tag remove $tag $prevSpace $nextSpace
        }
      }

      set REData [$self._t get $prevSpace $nextSpace]

      ctext::commentsAfterIdle $self $lineStart $lineEnd [regexp {*}$configAr(re_opts) -- $commentRE $REData]
      ctext::highlightAfterIdle $self $lineStart $lineEnd

      switch -- $data {
        "\}" {
          if {$configAr(matchChar,curly)} {
            ctext::matchPair $self "\\\{" "\\\}"
          }
        }
        "\]" {
          if {$configAr(matchChar,square)} {
            ctext::matchPair $self "\\\[" "\\\]"
          }
        }
        "\)" {
          if {$configAr(matchChar,paren)} {
            ctext::matchPair $self "\\(" "\\)"
          }
        }
        "\>" {
          if {$configAr(matchChar,angled)} {
            ctext::matchPair $self "\\<" "\\>"
          }
        }
        "\"" {
          if {$configAr(matchChar,double)} {
            ctext::matchQuote $self
          }
        }
      }
      ctext::modified $self 1
      ctext::linemapUpdate $self
    }

    paste {
      tk_textPaste $self
      ctext::modified $self 1
    }

    peer {
      switch [lindex $args 0] {
        names {
          set names [list]
          foreach name [$self._t peer names] {
            lappend names [winfo parent $name]
          }
          return $names
        }
        default {
          return -code error "unknown peer subcommand: [lindex $args 0]"
        }
      }
    }

    edit {
      set subCmd [lindex $args 0]
      set argsLength [llength $args]

      ctext::getAr $self config ar

      if {"modified" == $subCmd} {
        if {$argsLength == 1} {
          return $ar(modified)
        } elseif {$argsLength == 2} {
          set value [lindex $args 1]
          set ar(modified) $value
        } else {
          return -code error "invalid arg(s) to $self edit modified: $args"
        }
      } else {
        #Tk 8.4 has other edit subcommands that I don't want to emulate.
        return [uplevel 1 [linsert $args 0 $self._t $cmd]]
      }
    }

    gutter {
      set args [lassign $args subcmd]
      switch -glob $subcmd {
        create {
          set value_list  [lassign $args gutter_name]
          set gutter_tags [list]
          ctext::getAr $self config ar
          foreach {name opts} $value_list {
            array set sym_opts $opts
            set sym        [expr {[info exists sym_opts(-symbol)] ? $sym_opts(-symbol) : ""}]
            set gutter_tag "gutter:$gutter_name:$name:$sym"
            if {[info exists sym_opts(-fg)]} {
              $self.l tag configure $gutter_tag -foreground $sym_opts(-fg)
            }
            if {[info exists sym_opts(-onenter)]} {
              $self.l tag bind $gutter_tag <Enter> "$sym_opts(-onenter) $self"
            }
            if {[info exists sym_opts(-onleave)]} {
              $self.l tag bind $gutter_tag <Leave> "$sym_opts(-onleave) $self"
            }
            if {[info exists sym_opts(-onclick)]} {
              $self.l tag bind $gutter_tag <Button-1> "$sym_opts(-onclick) $self"
            }
            lappend gutter_tags $gutter_tag
            array unset sym_opts
          }
          lappend ar(gutters) [list $gutter_name $gutter_tags]
          ctext::linemapUpdate $self
        }
        destroy {
          set gutter_name    [lindex $args 0]
          ctext::getAr $self config ar
          if {[set index [lsearch -index 0 $ar(gutters) $gutter_name]] != -1} {
            $self._t tag delete {*}[lindex $ar(gutters) $index 1]
            set ar(gutters) [lreplace $ar(gutters) $index $index]
            ctext::linemapUpdate $self
          }
        }
        del* {
          lassign $args gutter_name sym_list
          set update_needed 0
          ctext::getAr $self config ar
          if {[set gutter_index [lsearch -index 0 $ar(gutters) $gutter_name]] == -1} {
            return -code error "Unable to find gutter name ($gutter_name)"
          }
          foreach symname $sym_list {
            set gutters [lindex $ar(gutters) $gutter_index 1]
            if {[set index [lsearch -glob $gutters "gutter:$gutter_name:$symname:*"]] != -1} {
              $self._t tag delete [lindex $gutters $index]
              set gutters [lreplace $gutters $index $index]
              lset ar(gutters) $gutter_index 1 $gutters
              set update_needed 1
            }
          }
          if {$update_needed} {
            ctext::linemapUpdate $self
          }
        }
        set {
          set args [lassign $args gutter_name]
          set update_needed 0
          ctext::getAr $self config ar
          if {[set gutter_index [lsearch -index 0 $ar(gutters) $gutter_name]] != -1} {
            foreach {name line_nums} $args {
              if {[set gutter_tag [lsearch -inline -glob [lindex $ar(gutters) $gutter_index 1] gutter:$gutter_name:$name:*]] != -1} {
                foreach line_num $line_nums {
                  if {[set curr_tag [lsearch -inline -glob [$self._t tag names $line_num.0] gutter:$gutter_name:*]] ne ""} {
                    if {$curr_tag ne $gutter_tag} {
                      $self._t tag delete $curr_tag
                      $self._t tag add $gutter_tag $line_num.0 $line_num.1
                      set update_needed 1
                    }
                  } else {
                    $self._t tag add $gutter_tag $line_num.0 $line_num.1
                    set update_needed 1
                  }
                }
              }
            }
          }
          if {$update_needed} {
            ctext::linemapUpdate $self
          }
        }
        get {
          set gutter_name [lindex $args 0]
          set symbols     [list]
          ctext::getAr $self config ar
          if {[set gutter_index [lsearch -index 0 $ar(gutters) $gutter_name]] != -1} {
            foreach gutter_tag [lindex $ar(gutters) $gutter_index 1] {
              set lines [list]
              foreach {first last} [$self._t tag ranges $gutter_tag] {
                lappend lines [lindex [split $first .] 0]
              }
              lappend symbols [lindex [split $gutter_tag :] 2] $lines
            }
          }
          return $symbols
        }
        clear {
          set last [lassign $args gutter_name first]
          ctext::getAr $self config ar
          if {[set gutter_index [lsearch -index 0 $ar(gutters) $gutter_name]] != -1} {
            if {$last eq ""} {
              foreach gutter_tag [lindex $ar(gutters) $gutter_index 1] {
                $self._t tag remove $gutter_tag $first.0
              }
            } else {
              foreach gutter_tag [lindex $ar(gutters) $gutter_index 1] {
                $self._t tag remove $gutter_tag $first.0 $last.1
              }
            }
            ctext::linemapUpdate $self
          }
        }
        cget {
          lassign $args gutter_name sym_name opt
          ctext::getAr $self config ar
          if {[set index [lsearch -exact -index 0 $ar(gutters) $gutter_name]] == -1} {
            return -code error "Unable to find gutter name ($gutter_name)"
          }
          if {[set gutter_tag [lsearch -inline -glob [lindex $ar(gutters) $index 1] "gutter:$gutter_name:$sym_name:*"]] == -1} {
            return -code error "Unknown symbol ($sym_name) specified"
          }
          switch $opt {
            -symbol  { return [lindex [split $gutter_tag :] 3] }
            -fg      { return [$self.l tag cget $gutter_tag -foreground] }
            -onenter { return [lrange [$self.l tag bind $gutter_tag <Enter>] 0 end-1] }
            -onleave { return [lrange [$self.l tag bind $gutter_tag <Leave>] 0 end-1] }
            -onclick { return [lrange [$self.l tag bind $gutter_tag <Button-1>] 0 end-1] }
            default  {
              return -code error "Unknown gutter option ($opt) specified"
            }
          }
        }
        conf* {
          set args [lassign $args gutter_name]
          ctext::getAr $self config ar
          if {[set index [lsearch -exact -index 0 $ar(gutters) $gutter_name]] == -1} {
            return -code error "Unable to find gutter name ($gutter_name)"
          }
          if {[llength $args] < 2} {
            if {[llength $args] == 0} {
              set match_tag "gutter:$gutter_name:*"
            } else {
              set match_tag "gutter:$gutter_name:[lindex $args 0]:*"
            }
            foreach gutter_tag [lsearch -inline -all -glob [lindex $ar(gutters) $index 1] $match_tag] {
              lassign [split $gutter_tag :] dummy1 dummy2 symname sym
              set symopts [list]
              if {$sym ne ""} {
                lappend symopts -symbol $sym
              }
              if {[set fg [$self.l tag cget $gutter_tag -foreground]] ne ""} {
                lappend symopts -fg $fg
              }
              if {[set cmd [lrange [$self.l tag bind $gutter_tag <Enter>] 0 end-1]] ne ""} {
                lappend symopts -onenter $cmd
              }
              if {[set cmd [lrange [$self.l tag bind $gutter_tag <Leave>] 0 end-1]] ne ""} {
                lappend symopts -onleave $cmd
              }
              if {[set cmd [lrange [$self.l tag bind $gutter_tag <Button-1>] 0 end-1]] ne ""} {
                lappend symopts -onclick $cmd
              }
              lappend gutters $symname $symopts
            }
            return $gutters
          } else {
            set args          [lassign $args symname]
            set update_needed 0
            if {[set gutter_tag [lsearch -inline -glob [lindex $ar(gutters) $index 1] "gutter:$gutter_name:$symname:*"]] == -1} {
              return -code error "Unable to find gutter symbol name ($symname)"
            }
            foreach {opt value} $args {
              switch -glob $opt {
                -sym* {
                  set ranges [$self._t tag ranges $gutter_tag]
                  set opts   [$self._t tag configure $gutter_tag]
                  $self._t tag delete $gutter_tag
                  set gutter_tag "gutter:$gutter_name:$symname:$value"
                  $self._t tag configure $gutter_tag {*}$opts
                  $self._t tag add       $gutter_tag {*}$ranges
                  set update_needed 1
                }
                -fg {
                  $self.l tag configure $gutter_tag -foreground $value
                }
                -onenter {
                  $self.l tag bind $gutter_tag <Enter> $value
                }
                -onleave {
                  $self.l tag bind $gutter_tag <Leave> $value
                }
                -onclick {
                  $self.l tag bind $gutter_tag <Button-1> $value
                }
                default {
                  return -code error "Unknown gutter option ($opt) specified"
                }
              }
            }
            if {$update_needed} {
              ctext::linemapUpdate $self
            }
          }
        }
        names {
          ctext::getAr $self config ar
          set names [list]
          foreach gutter $ar(gutters) {
            lappend names [lindex $gutter 0]
          }
          return $names
        }
      }
    }

    default {
      return [uplevel 1 [linsert $args 0 $self._t $cmd]]
    }

  }

}

proc ctext::setAutoMatchChars {win matchChars} {
  
  ctext::getAr $win config configAr
  
  # Clear the matchChars
  foreach name [array names configAr matchChar,*] {
    set configAr($name) 0
  }
  
  # Set the matchChars
  foreach matchChar $matchChars {
    set configAr(matchChar,$matchChar) 1
  }
  
}

proc ctext::tag:blink {win count {afterTriggered 0}} {
  if {$count & 1} {
    $win tag configure __ctext_blink \
    -foreground [$win cget -bg] -background [$win cget -fg]
  } else {
    $win tag configure __ctext_blink \
    -foreground [$win cget -fg] -background [$win cget -bg]
  }

  ctext::getAr $win config configAr
  if {$afterTriggered} {
    set configAr(blinkAfterId) ""
  }

  if {$count == 4} {
    $win tag delete __ctext_blink 1.0 end
    return
  }

  incr count
  if {"" eq $configAr(blinkAfterId)} {
    set configAr(blinkAfterId) [after 50 \
    [list ctext::tag:blink $win $count [set afterTriggered 1]]]
  }
}

proc ctext::matchPair {win str1 str2} {

  if {[isEscaped $win "insert-1c"]} {
    return
  }

  set searchRE "[set str1]|[set str2]"
  set count 1

  set pos [$win index "insert - 1 chars"]
  set endPair $pos
  set lastFound ""
  while 1 {
    set found [$win search -backwards -regexp $searchRE $pos]

    if {$found == "" || [$win compare $found > $pos]} {
      return
    }

    if {$lastFound != "" && [$win compare $found == $lastFound]} {
      #The search wrapped and found the previous search
      return
    }

    set lastFound $found
    set char [$win get $found]
    set prevChar [$win get "$found - 1 chars"]
    set pos $found

    if {[isEscaped $win $found]} {
      continue
    } elseif {[string equal $char [subst $str2]]} {
      incr count
    } elseif {[string equal $char [subst $str1]]} {
      incr count -1
      if {$count == 0} {
        set startPair $found
        break
      }
    } else {
      # This shouldn't happen.  I may in the future make it
      # return -code error
      puts stderr "ctext seems to have encountered a bug in ctext::matchPair"
      return
    }
  }

  $win tag add __ctext_blink $startPair
  $win tag add __ctext_blink $endPair
  ctext::tag:blink $win 0
}

proc ctext::matchQuote {win} {
  set endQuote [$win index insert]
  set start [$win index "insert - 1 chars"]

  # The quote really isn't the end if it is escaped or if the previous
  # character had a string tag associated with it.
  if {[isEscaped $win $start] || ([lsearch [$win tag names $start] "_dString"] == -1)} {
    return
  }

  set lastFound ""
  while 1 {
    set startQuote [$win search -backwards \" $start]
    if {$startQuote == "" || [$win compare $startQuote > $start]} {
      #The search found nothing or it wrapped.
      return
    }

    if {$lastFound != "" && [$win compare $lastFound == $startQuote]} {
      #We found the character we found before, so it wrapped.
      return
    }
    set lastFound $startQuote
    set start [$win index "$startQuote - 1 chars"]
    set prevChar [$win get $start]

    if {[isEscaped $win $start]} {
      continue
    }
    break
  }

  if {[$win compare $endQuote == $startQuote]} {
    #probably just \"
    return
  }

  $win tag add __ctext_blink $startQuote $endQuote
  ctext::tag:blink $win 0
}

proc ctext::setBlockCommentPatterns {win patterns {color "khaki"}} {
  ctext::getAr $win config configAr
  set configAr(block_comment_patterns) $patterns
  if {[llength $patterns] > 0} {
    $win tag configure _cComment -foreground $color
  } else {
    catch { $win tag delete _cComment }
  }
  setCommentRE $win
}

proc ctext::setLineCommentPatterns {win patterns {color "khaki"}} {
  ctext::getAr $win config configAr
  set configAr(line_comment_patterns) $patterns
  if {[llength $patterns] > 0} {
    $win tag configure _lComment -foreground $color
  } else {
    catch { $win tag delete _lComment }
  }
  setCommentRE $win
}

proc ctext::setStringPatterns {win patterns {color "green"}} {
  ctext::getAr $win config configAr
  set configAr(string_patterns) $patterns
  if {[llength $patterns] > 0} {
    $win tag configure _sString -foreground $color
    $win tag configure _dString -foreground $color
    $win tag configure _tString -foreground $color
  } else {
    catch { $win tag delete _sString }
    catch { $win tag delete _dString }
    catch { $win tag delete _tString }
  }
  setCommentRE $win
}

proc ctext::comments {win start end blocks {afterTriggered 0}} {

  ctext::getAr $win config configAr

  if {$afterTriggered} {
    set configAr(commentsAfterId) ""
  }

  set strings        [llength $configAr(string_patterns)]
  set block_comments [llength $configAr(block_comment_patterns)]
  set line_comments  [llength $configAr(line_comment_patterns)]

  if {$blocks && [expr ($strings + $block_comments + $line_comments) > 0]} {

    set dStr ""
    set sStr ""
    set tStr ""
    set lCom ""
    set cCom ""

    # Update the indices based on previous text
    # commentsGetPrevious $win $start cCom lCom sStr dStr tStr

    # Parse the new text between start and end
    # commentsParse $win $start end cCom lCom sStr dStr tStr
    commentsParse $win 1.0 end cCom lCom sStr dStr tStr

  # Otherwise, look for just the single line comments
  } elseif {$line_comments > 0} {

    set commentRE "([join $configAr(line_comment_patterns) |])"
    append commentRE {[^\n\r]*}

    set lcomment [list]

    # Handle single line comments in the given range
    set i 0
    foreach index [$win search -all -count lengths -regexp {*}$configAr(re_opts) -- $commentRE $start $end] {
      if {![isEscaped $win $index]} {
        lappend lcomment $index "$index+[lindex $lengths $i]c"
      }
      incr i
    }

    # If we need to raise the lComment, do it now
    if {[llength $lcomment] > 0 } {
      $win tag add _lComment {*}$lcomment
      $win tag raise _lComment
    }

  }

}

proc ctext::commentsGetPrevious {win index pcCom plCom psStr pdStr ptStr} {

  upvar $pcCom cCom
  upvar $plCom lCom
  upvar $psStr sStr
  upvar $pdStr dStr
  upvar $ptStr tStr

  # Figure out if we are in a comment or string currently
  if {[set prev_index [$win index "$index-1c"]] ne [$win index $index]} {
    foreach tag [$win tag names $prev_index] {
      switch $tag {
        "_cComment" { lassign [$win tag prevrange $tag $index] cCom }
        "_lComment" { lassign [$win tag prevrange $tag $index] lCom }
        "_sString"  { lassign [$win tag prevrange $tag $index] sStr }
        "_dString"  { lassign [$win tag prevrange $tag $index] dStr }
        "_tString"  { lassign [$win tag prevrange $tag $index] tStr }
      }
    }
  }

}

proc ctext::commentsParse {win start end pcCom plCom psStr pdStr ptStr} {

  upvar $pcCom cCom
  upvar $plCom lCom
  upvar $psStr sStr
  upvar $pdStr dStr
  upvar $ptStr tStr

  ctext::getAr $win config configAr

  set lcomment ""
  set ccomment ""
  set sstring  ""
  set dstring  ""
  set tstring  ""

  set indices     [$win search -all -overlap -count lengths -regexp {*}$configAr(re_opts) -- $configAr(comment_re) $start $end]
  set num_indices [llength $indices]
  for {set i 0} {$i < $num_indices} {incr i} {

    set index [lindex $indices $i]
    set str   [$win get $index "$index+[lindex $lengths $i]c"]

    # Only handle the comment if it is not escaped
    if {![isEscaped $win $index]} {

      # Found a double-quote character
      if {$str == "\""} {
        commentsParseDStringEnd $win $index indices $num_indices lengths i dstring

      # Found a single-quote character
      } elseif {$str == "'"} {
        commentsParseSStringEnd $win $index indices $num_indices lengths i sstring

      # Found a triple-double-quote character string
      } elseif {$str == "\"\"\""} {
        commentsParseTStringEnd $win $index indices $num_indices lengths i tstring

      # Found a single line comment
      } elseif {($configAr(lcomment_re) ne "") && [regexp {*}$configAr(re_opts) -- $configAr(lcomment_re) $str]} {
        commentsParseLCommentEnd $win $index indices $num_indices i lcomment

      # Found a starting block comment string
      } elseif {($configAr(bcomment_re) ne "") && [regexp {*}$configAr(re_opts) -- $configAr(bcomment_re) $str]} {
        commentsParseCCommentEnd $win $index indices $num_indices $configAr(re_opts) $configAr(ecomment_re) lengths i ccomment
      }

    }

  }

  # Delete old, add new and re-raise tags
  $win tag remove _lComment $start $end
  if {[llength $lcomment] > 0} {
    $win tag add _lComment {*}$lcomment
    $win tag raise _lComment
  }
  $win tag remove _cComment $start $end
  if {[llength $ccomment] > 0} {
    $win tag add _cComment {*}$ccomment
    $win tag raise _cComment
  }
  $win tag remove _sString  $start $end
  if {[llength $sstring] > 0} {
    $win tag add _sString {*}$sstring
    $win tag raise _sString
  }
  $win tag remove _dString  $start $end
  if {[llength $dstring] > 0} {
    $win tag add _dString {*}$dstring
    $win tag raise _dString
  }
  $win tag remove _tString  $start $end
  if {[llength $tstring] > 0} {
    $win tag add _tString {*}$tstring
    $win tag raise _tString
  }

}

proc ctext::commentsParseSStringEnd {win index pindices num_indices plengths pi psstring} {

  upvar $pindices indices
  upvar $plengths lengths
  upvar $pi       i
  upvar $psstring sstring

  lappend sstring $index end

  for {incr i} {$i < $num_indices} {incr i} {
    set index [lindex $indices $i]
    if {![isEscaped $win $index]} {
      set str [$win get $index "$index+[lindex $lengths $i]c"]
      if {$str == "'"} {
        lset sstring end "$index+1c"
        break
      }
    }
  }

}

proc ctext::commentsParseDStringEnd {win index pindices num_indices plengths pi pdstring} {

  upvar $pindices indices
  upvar $plengths lengths
  upvar $pi       i
  upvar $pdstring dstring

  lappend dstring $index end

  for {incr i} {$i < $num_indices} {incr i} {
    set index [lindex $indices $i]
    if {![isEscaped $win $index]} {
      set str [$win get $index "$index+[lindex $lengths $i]c"]
      if {$str == "\""} {
        lset dstring end "$index+1c"
        break
      }
    }
  }

}

proc ctext::commentsParseTStringEnd {win index pindices num_indices plengths pi ptstring} {

  upvar $pindices indices
  upvar $plengths lengths
  upvar $pi       i
  upvar $ptstring tstring

  lappend tstring $index end

  for {incr i} {$i < $num_indices} {incr i} {
    set index [lindex $indices $i]
    if {![isEscaped $win $index]} {
      set str [$win get $index "$index+[lindex $lengths $i]c"]
      if {$str == "\"\"\""} {
        lset tstring end "$index+3c"
        break
      }
    }
  }

}

proc ctext::commentsParseLCommentEnd {win index pindices num_indices pi plcomment} {

  upvar $pindices  indices
  upvar $pi        i
  upvar $plcomment lcomment

  lappend lcomment $index "$index lineend"

  for {incr i} {$i < $num_indices} {incr i} {
    set nxt_index [lindex $indices $i]
    if {[$win compare $nxt_index > "$index lineend"]} {
      incr i -1
      break
    }
  }

}

proc ctext::commentsParseCCommentEnd {win index pindices num_indices re_opts ecomment_re plengths pi pccomment} {

  upvar $pindices  indices
  upvar $plengths  lengths
  upvar $pi        i
  upvar $pccomment ccomment

  lappend ccomment $index end

  for {incr i} {$i < $num_indices} {incr i} {
    set index [lindex $indices $i]
    if {![isEscaped $win $index]} {
      set str [$win get $index "$index+[lindex $lengths $i]c"]
      if {[regexp {*}$re_opts -- $ecomment_re $str]} {
        lset ccomment end "$index+[string length $str]c"
        break
      }
    }
  }

}

proc ctext::add_font_opt {win class modifiers popts} {
  
  upvar $popts opts

  if {[llength $modifiers] > 0} {
    
    array set font_opts [font configure [$win cget -font]]

    ctext::getAr $win highlight ar

    set lsize     0
    set click     0
    set name_list [list 0 0 0 0]

    foreach modifier $modifiers {
      switch $modifier {
        "bold"       { set font_opts(-weight)     "bold";   lset name_list 0 1 }
        "italics"    { set font_opts(-slant)      "italic"; lset name_list 1 1 }
        "underline"  { set font_opts(-underline)  1;        lset name_list 2 1 }
        "overstrike" { set font_opts(-overstrike) 1;        lset name_list 3 1 }
        "h6"         { set font_opts(-size) [expr $font_opts(-size) + 1]; set lsize 6 }
        "h5"         { set font_opts(-size) [expr $font_opts(-size) + 2]; set lsize 5 }
        "h4"         { set font_opts(-size) [expr $font_opts(-size) + 3]; set lsize 4 }
        "h3"         { set font_opts(-size) [expr $font_opts(-size) + 4]; set lsize 3 }
        "h2"         { set font_opts(-size) [expr $font_opts(-size) + 5]; set lsize 2 }
        "h1"         { set font_opts(-size) [expr $font_opts(-size) + 6]; set lsize 1 }
        "click"      { set click 1 }
      }
    }

    set fontname ctext-[join $name_list ""]$lsize
    if {[lsearch [font names] $fontname] == -1} {
      font create $fontname {*}[array get font_opts]
    }

    if {$lsize} {
      set ar(lsize,$class) "lsize$lsize"
      $win.l tag configure $ar(lsize,$class) -font $fontname
    }

    lappend opts -font $fontname
    
    if {$click} {
      set ar(click,$class) $opts
    }
    
  }
  
}

proc ctext::addHighlightClass {win class fgcolor {bgcolor ""} {font_opts ""}} {
  
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
  }
            
  ctext::getAr $win classes classesAr
  set classesAr(_$class) 1
            
}
                
proc ctext::addHighlightKeywords {win keywords type value} {
            
  ctext::getAr $win highlight ar
            
  if {$type eq "class"} {
    set value _$value
  }

  foreach word $keywords {
    set ar(keyword,$type,$word) $value
  }
 
}

proc ctext::addHighlightRegexp {win re type value} {
  
  ctext::getAr $win highlight ar
  ctext::getAr $win config    configAr
            
  if {$type eq "class"} {
    set value _$value
  }

  lappend ar(regexps) "regexp,$type,$value"
  
  set ar(regexp,$type,$value) [list $re $configAr(re_opts)]

}

# For things like $blah
proc ctext::addHighlightWithOnlyCharStart {win char type value} {
  
  ctext::getAr $win highlight ar
            
  if {$type eq "class"} {
    set value _$value
  }

  set ar(charstart,$type,$char) $value

}

proc ctext::addSearchClass {win class fgcolor bgcolor modifiers str} {
  
  addHighlightClass $win $class $fgcolor $bgcolor $modifiers
              
  ctext::getAr $win highlight ar
  
  set ar(searchword,class,$str) _$class
  
  # Perform the search
  set i 0
  foreach res [$win._t search -count lengths -all -- $str 1.0 end] {
    set wordEnd [$win._t index "$res + [lindex $lengths $i] chars"]
    $win._t tag add _$class $res $wordEnd
    incr i
  }
  
}

proc ctext::addSearchClassForRegexp {win class fgcolor bgcolor modifiers re {re_opts ""}} {
  
  addHighlightClass $win $class $fgcolor $bgcolor $modifiers

  ctext::getAr $win highlight ar
  ctext::getAr $win config    configAr
                
  if {$re_opts ne ""} {
    set re_opts $configAr(re_opts)
  }

  set ar(searchregexp,class,_$class) [list $re $re_opts]

  # Perform the search
  set i 0
  foreach res [$win._t search -count lengths -regexp -all {*}$re_opts -- $re 1.0 end] {
    set wordEnd [$win._t index "$res + [lindex $lengths $i] chars"]
    $win._t tag add _$class $res $wordEnd
    incr i
  }

}

proc ctext::deleteHighlightClass {win classToDelete} {
  
  ctext::getAr $win highlight ar
  ctext::getAr $win classes   classesAr

  if {![info exists classesAr(_$classToDelete)]} {
    return -code error "$classToDelete doesn't exist"
  }
  
  if {[set index [lsearch $ar(regexps) regexp,class,_$classToDelete]] != -1} {
    set ar(regexps) [lreplace $ar(regexps) $index $index]
  }

  array unset ar *,class,_$classToDelete
  unset classesAr(_$classToDelete)
                
  $win tag delete _$classToDelete 1.0 end
  
}

proc ctext::getHighlightClasses win {
  
  ctext::getAr $win classes classesAr

  set classes [list]
  foreach class [array names classesAr] {
    lappend classes [string range $class 1 end]
  }

  return $classes
  
}

proc ctext::findNextChar {win index char} {
  set i [$win index "$index + 1 chars"]
  set lineend [$win index "$i lineend"]
  while 1 {
    set ch [$win get $i]
    if {[$win compare $i >= $lineend]} {
      return ""
    }
    if {$ch == $char} {
      return $i
    }
    set i [$win index "$i + 1 chars"]
  }
}

proc ctext::findNextSpace {win index} {
  set i [$win index $index]
  set lineStart [$win index "$i linestart"]
  set lineEnd [$win index "$i lineend"]
  #Sometimes the lineend fails (I don't know why), so add 1 and try again.
  if {[$win compare $lineEnd == $lineStart]} {
    set lineEnd [$win index "$i + 1 chars lineend"]
  }

  while {1} {
    set ch [$win get $i]

    if {[$win compare $i >= $lineEnd]} {
      set i $lineEnd
      break
    }

    if {[string is space $ch]} {
      break
    }
    set i [$win index "$i + 1 chars"]
  }
  return $i
}

proc ctext::findPreviousSpace {win index} {
  set i [$win index $index]
  set lineStart [$win index "$i linestart"]
  while {1} {
    set ch [$win get $i]

    if {[$win compare $i <= $lineStart]} {
      set i $lineStart
      break
    }

    if {[string is space $ch]} {
      break
    }

    set i [$win index "$i - 1 chars"]
  }
  return $i
}

proc ctext::clearHighlightClasses {win} {
                
  ctext::getAr $win highlight ar
  array unset ar

  ctext::getAr $win classes ar
  array unset ar

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

  ctext::getAr $win highlight ar
  
  # Add the tag and possible binding
  if {[info exists ar(click,$class)]} {
    set tag _$class[incr ar(click_index)]
    $win tag add       $tag $startpos $endpos
    $win tag configure $tag {*}$ar(click,$class)
    $win tag bind      $tag <Button-3> $cmd
  } else {
    $win tag add _$class $startpos $endpos
  }
  
  # Add the lsize
  if {[info exists ar(lsize,$class)]} {
    set startline [lindex [split $startpos .] 0]
    set endline   [lindex [split $startpos .] 0]
    for {set line $startline} {$line <= $endline} {incr line} {
      $win tag add $ar(lsize,$class) $line.0
    }
    linemapUpdate $win
  }

}

proc ctext::doHighlight {win start end} {

  variable REs
  variable restart_from

  if {![winfo exists $win]} {
    return
  }

  ctext::getAr $win config configAr

  if {!$configAr(-highlight)} {
    return
  }

  # Get the highlights and delete the tag
  # set linesChanged [$win tag ranges lineChanged]
  # $win tag delete lineChanged

  ctext::getAr $win classes   classesAr
  ctext::getAr $win highlight highlightAr

  set twin "$win._t"
 
  # Handle word-based matching
  set i 0
  foreach res [$twin search -count lengths -regexp {*}$configAr(re_opts) -all -- $REs(words) $start $end] {
    set wordEnd      [$twin index "$res + [lindex $lengths $i] chars"]
    set word         [$twin get $res $wordEnd]
    set firstOfWord  [string index $word 0]
    if {[info exists highlightAr(keyword,class,$word)]} {
      $twin tag add $highlightAr(keyword,class,$word) $res $wordEnd
    } elseif {[info exists highlightAr(charstart,class,$firstOfWord)]} {
      $twin tag add $highlightAr(charstart,class,$firstOfWord) $res $wordEnd
    }
    if {[info exists highlightAr(keyword,command,$word)] && \
        ![catch { {*}$highlightAr(keyword,command,$word) $win $res $wordEnd } retval] && ([llength $retval] == 4)} {
      handle_tag $win {*}$retval
    } elseif {[info exists highlightAr(charstart,command,$firstOfWord)] && \
              ![catch { {*}$highlightAr(charstart,command,$firstOfWord) $win $res $wordEnd } retval] && ([llength $retval] == 4)} {
      handle_tag $win {*}$retval
    }
    if {[info exists highlightAr(searchword,class,$word)]} {
      $twin tag add $highlightAr(searchword,class,$word) $res $wordEnd
    } elseif {[info exists highlightAr(searchword,command,$word)] && \
              ![catch { {*}$highlightAr(searchword,command,$word) $win $res $wordEnd } retval] && ([llength $retval] == 4)} {
      handle_tag $win {*}$retval
    }
    incr i
  }

  # Handle regular expression matching
  if {[info exists highlightAr(regexps)]} {
    foreach name $highlightAr(regexps) {
      lassign [split $name ,] dummy type value
      lassign $highlightAr($name) re re_opts
      set i 0
      if {$type eq "class"} {
        foreach res [$twin search -count lengths -regexp {*}$re_opts -all -- $re $start $end] {
          set wordEnd [$twin index "$res + [lindex $lengths $i] chars"]
          $twin tag add $value $res $wordEnd
          incr i
        }  
      } else {
        set indices [$twin search -count lengths -regexp {*}$re_opts -all -- $re $start $end]
        while {[llength $indices]} {
          set indices [lassign $indices res]
          set wordEnd [$twin index "$res + [lindex $lengths $i] chars"]
          incr i
          if {![catch { {*}$value $win $res $wordEnd } retval] && ([llength $retval] == 2)} {
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

proc ctext::linemapToggleMark {win y} {

  ctext::getAr $win config configAr

  if {!$configAr(-linemap_markable)} {
    return
  }

  ctext::getAr $win linemap linemapAr

  set lline [lindex [split [set lmarkChar [$win.l index @0,$y]] .] 0]
  set tline [lindex [split [set tmarkChar [$win.t index @0,$y]] .] 0]

  if {[set lmark [lsearch -inline -glob [$win.t tag names $tline.0] lmark*]] ne ""} {
    #It's already marked, so unmark it.
    $win.l tag remove lmark $lline.0 $lline.end
    $win.t tag delete $lmark
    ctext::linemapUpdate $win
    set type unmarked
  } else {
    set lmark "lmark[incr linemapAr(id)]"
    #This means that the line isn't toggled, so toggle it.
    $win.t tag add $lmark $tmarkChar [$win.t index "$tmarkChar lineend"]
    $win.l tag add lmark $lmarkChar [$win.l index "$lmarkChar lineend"]
    $win.l tag configure lmark -foreground $configAr(-linemap_select_fg) \
      -background $configAr(-linemap_select_bg)
    set type marked
  }

  if {[string length $configAr(-linemap_mark_command)]} {
    uplevel #0 [linsert $configAr(-linemap_mark_command) end $win $type $lmark]
  }

}

proc ctext::linemapSetMark {win line} {

  if {[lsearch -inline -glob [$win.t tag names $line.0] lmark*] eq ""} {
    ctext::getAr $win config configAr
    ctext::getAr $win linemap linemapAr
    set lmark "lmark[incr linemapAr(id)]"
    $win.t tag add $lmark $line.0 [$win.t index "$line.0 lineend"]
    $win.l tag add lmark $line.0 [$win.l index "$line.0 lineend"]
    $win.l tag configure lmark -foreground $configAr(-linemap_select_fg) \
      -background $configAr(-linemap_select_bg)
  }

}

proc ctext::linemapClearMark {win line} {

  if {[set lmark [lsearch -inline -glob [$win.t tag names $line.0] lmark*]] ne ""} {
    $win.t tag delete $lmark
    $win.l tag remove lmark $line.0 $line.end
    ctext::linemapUpdate $win
  }

}

#args is here because -yscrollcommand may call it
proc ctext::linemapUpdate {win args} {

  if {[winfo exists $win.l] != 1} {
    return
  }

  ctext::getAr $win config configAr

  set first_line    [lindex [split [$win.t index @0,0] .] 0]
  set last_line     [lindex [split [$win.t index @0,[winfo height $win.t]] .] 0]
  set line_width    [string length [lindex [split [$win._t index end-1c] .] 0]]
  set linenum_width [expr ($configAr(-linemap_minwidth) > $line_width) ? $configAr(-linemap_minwidth) : $line_width]
  set gutter_width  [expr ([llength $configAr(gutters)] > 0) ? ([llength $configAr(gutters)] + 1) : 0]
  set full_width    [expr $linenum_width + $gutter_width]
  set lmark_pos     [expr ($gutter_width * 2) + 1]
  set lsize_pos     [expr ($gutter_width * 2) + 3]

  $win.l delete 1.0 end

  for {set line $first_line} {$line <= $last_line} {incr line} {
    if {$gutter_width > 0} {
      set line_content [concat [lrepeat $gutter_width " " [list]] [format "%-*s" $linenum_width $line] [list] "0" [list] "\n"]
    } else {
      set line_content [list [format "%-*s" $linenum_width $line] [list] "0" [list] "\n"]
    }
    set ltags [$win.t tag names $line.0]
    if {[lsearch -glob $ltags lmark*] != -1} {
      lset line_content $lmark_pos lmark]
    }
    if {[set lsizes [lsearch -inline -glob -all $ltags lsize*]] ne ""} {
      lset line_content $lsize_pos [lindex [lsort $lsizes] 0]
    }
    foreach gutter_tag [lsearch -inline -all -glob [$win._t tag names $line.0] gutter:*] {
      lassign [split $gutter_tag :] dummy gutter_name gutter_symname gutter_sym
      if {$gutter_sym ne ""} {
        set gutter_index [expr [lsearch -index 0 $configAr(gutters) $gutter_name] * 2]
        set line_content [lreplace $line_content $gutter_index [expr $gutter_index + 1] $gutter_sym $gutter_tag]
      }
    }
    $win.l insert end {*}$line_content
  }

  linemapUpdateOffset $win $first_line $last_line

  # Resize the linemap window, if necessary
  if {[$win.l cget -width] != $full_width} {
    $win.l configure -width $full_width
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

    # return in case the line numbers text widget is not up to
    # date
    if {[catch {
      set lystart [lindex [$win.l bbox $lline.0] 1]
    }]} {
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

proc ctext::modified {win value} {
  ctext::getAr $win config ar
  set ar(modified) $value
  event generate $win <<Modified>>
  return $value
}
