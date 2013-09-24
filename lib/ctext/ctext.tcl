# By George Peter Staplin
# See also the README for a list of contributors
# RCS: @(#) $Id: ctext.tcl,v 1.9 2011/04/18 19:49:48 andreas_kupries Exp $

package require Tk
package provide ctext 3.3

namespace eval ctext {
  array set REs {
    words  {([^\s\(\{\[\}\]\)\.\t\n\r;\"'\|,]+)}
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
  
  frame $win -class Ctext
  
  set tmp [text .__ctextTemp]
  
  ctext::getAr $win config ar
  
  set ar(-fg) [$tmp cget -foreground]
  set ar(-bg) [$tmp cget -background]
  set ar(-font) [$tmp cget -font]
  set ar(-relief) [$tmp cget -relief]
  destroy $tmp
  set ar(-yscrollcommand) ""
  set ar(-linemap) 1
  set ar(-linemapfg) $ar(-fg)
  set ar(-linemapbg) $ar(-bg)
  set ar(-linemap_mark_command) {}
  set ar(-linemap_markable) 1
  set ar(-linemap_select_fg) black
  set ar(-linemap_select_bg) yellow
  set ar(-linemap_cursor) left_ptr
  set ar(-highlight) 1
  set ar(-warnwidth) ""
  set ar(-warnwidth_bg) red
  set ar(win) $win
  set ar(modified) 0
  set ar(commentsAfterId) ""
  set ar(blinkAfterId) ""
  set ar(lastUpdate) 0
  set ar(block_comment_patterns) [list]
  set ar(string_patterns)        [list]
  set ar(line_comment_patterns)  [list]
  
  set ar(ctextFlags) [list -yscrollcommand -linemap -linemapfg -linemapbg \
  -font -linemap_mark_command -highlight -warnwidth -warnwidth_bg -linemap_markable -linemap_cursor \
  -linemap_select_fg \
  -linemap_select_bg]
  
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
  
  text $win.l -font $ar(-font) -width 1 -height 1 \
    -relief $ar(-relief) -fg $ar(-linemapfg) -cursor $ar(-linemap_cursor) \
    -bg $ar(-linemapbg) -takefocus 0
  
  set topWin [winfo toplevel $win]
  bindtags $win.l [list $win.l $topWin all]
  
  if {$ar(-linemap) == 1} {
    grid $win.l -sticky ns -row 0 -column 0
  }
  
  set args [concat $args [list -yscrollcommand \
    [list ctext::event:yscroll $win $ar(-yscrollcommand)]]]
  
  #escape $win, because it could have a space
  eval text \$win.t -font \$ar(-font) $args
  
  grid $win.t -row 0 -column 1 -sticky news
  grid rowconfigure $win 0 -weight 100
  grid columnconfigure $win 1 -weight 100
  
  bind $win.t <Configure> [list ctext::linemapUpdate $win]
  bind $win.l <ButtonPress-1> [list ctext::linemapToggleMark $win %y]
  bind $win.t <KeyRelease-Return> [list ctext::linemapUpdate $win]
  rename $win __ctextJunk$win
  rename $win.t $win._t
  
  bind $win <Destroy> [list ctext::event:Destroy $win %W]
  bindtags $win.t [linsert [bindtags $win.t] 0 $win]
  
  interp alias {} $win {} ctext::instanceCmd $win
  interp alias {} $win.t {} $win
  
  # If the user wants C comments they should call
  # ctext::enableComments
  ctext::disableComments $win
  ctext::modified $win 0
  ctext::buildArgParseTable $win
  
  return $win
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
  
  catch {rename $win {}}
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
    ctext::warnWidthUpdate $self 1.0 [$self._t index end]
    break
  }
  
  lappend argTable any -warnwidth_bg {
    if {[catch {winfo rgb $self $value} res]} {
      return -code error $res
    }
    set configAr(-warnwidth_bg) $value
    ctext::warnWidthUpdate $self 1.0 [$self._t index end]
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
  
  ctext::getAr $win config ar
  set ar(argTable) $argTable
}

proc ctext::getCommentRE {win} {
  
  ctext::getAr $win config configAr
  
  set commentRE {\\}
  if {[llength $configAr(block_comment_patterns)] > 0} {
    append commentRE "|[join [concat $configAr(block_comment_patterns)] |]"
  }
  if {[llength $configAr(line_comment_patterns)] > 0} {
    append commentRE "|[join $configAr(line_comment_patterns) |]"
  }
  if {[llength $configAr(string_patterns)] > 0} {
    append commentRE "|[join $configAr(string_patterns) |]"
  }
  
  puts "In getCommentRE: $commentRE"
  
  return $commentRE
  
}

proc ctext::commentsAfterIdle {win start end block} {
  ctext::getAr $win config configAr
  
  if {"" eq $configAr(commentsAfterId)} {
    set configAr(commentsAfterId) [after idle \
    [list ctext::comments $win $start $end $block [set afterTriggered 1]]]
  }
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
  set currRow [lindex [split $lineStart .] 0]
  set lastRow [lindex [split $lineEnd .] 0]
  while {1} {
    $win tag add lineChanged $currRow.0 $currRow.end
    if {[incr currRow] > $lastRow} {
      break
    }
  }

  # Perform the highlight in the background
  bgproc::command ctext::highlightAfterIdle "ctext::doHighlight $win" -cancelable 1
  
}

proc ctext::instanceCmd {self cmd args} {
  #slightly different than the RE used in ctext::comments
  ctext::getAr $self config configAr
  
  # Create comment RE
  set commentRE [getCommentRE $self]
  
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
        set del [lsearch -glob $res -yscrollcommand*]
        set res [lreplace $res $del $del]
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
          if {([string equal $tag "_cComment"] != 1) && \
              ([string equal $tag "_string"] != 1) && \
              ([string index $tag 0] eq "_")} {
            $self._t tag remove $tag $removeStart $removeEnd
          }
        }
        
        set checkStr "$prevChar[set char]"
        
        ctext::commentsAfterIdle $self $lineStart $lineEnd [regexp $commentRE $checkStr]
        ctext::highlightAfterIdle $self $lineStart $lineEnd
        ctext::warnWidthUpdate $self $lineStart $lineEnd
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
          if {([string equal $tag "_cComment"] != 1) && \
              ([string equal $tag "_string"] != 1) && \
              ([string index $tag 0] eq "_")} {
            $self._t tag remove $tag $lineStart $lineEnd
          }
        }
        
        ctext::commentsAfterIdle $self $lineStart $lineEnd [regexp $commentRE $data]
        ctext::highlightAfterIdle $self $lineStart $lineEnd
        ctext::warnWidthUpdate $self $lineStart $lineEnd
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
      if {[llength $args] == 1} {
        ctext::warnWidthUpdate $self [$self._t index [lindex $args 0]] [$self._t index [lindex $args 0]]
      } else {
        ctext::warnWidthUpdate $self [$self._t index [lindex $args 0]] [$self._t index [lindex $args 1]]
      }
      ctext::linemapUpdate $self
    }
    
    fastinsert {
      eval \$self._t insert $args
      ctext::modified $self 1
      ctext::warnWidthUpdate $self 1.0 [$self._t index end]
      ctext::linemapUpdate $self
    }
    
    highlight {
      set lineStart [lindex $args 0]
      set lineEnd   [lindex $args 1]
      foreach tag [$self._t tag names] {
        if {([string equal $tag "_cComment"] != 1) && \
            ([string equal $tag "_string"] != 1) && \
            ([string index $tag 0] eq "_")} {
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
      if {$insertPos eq "end"} {
        set lineStart [$self._t index "$insertPos-1c linestart"]
      } else {
        set lineStart [$self._t index "$insertPos linestart"]
      }
      set prevSpace [ctext::findPreviousSpace $self._t ${insertPos}-1c]
      set data [lindex $args 1]
      set datalen [string length $data]
      eval \$self._t insert $args
      
      set nextSpace [ctext::findNextSpace $self._t insert]
      set lineEnd [$self._t index "insert+${datalen}c lineend"]
      
      if {[$self._t compare $prevSpace < $lineStart]} {
        set prevSpace $lineStart
      }
      
      if {[$self._t compare $nextSpace > $lineEnd]} {
        set nextSpace $lineEnd
      }
      
      foreach tag [$self._t tag names] {
        if {([string equal $tag "_cComment"] != 1) && \
            ([string equal $tag "_string"] != 1) && \
            ([string index $tag 0] eq "_")} {
          $self._t tag remove $tag $prevSpace $nextSpace
        }
      }
      
      set REData $prevChar
      append REData $data
      append REData $nextChar
      
      ctext::commentsAfterIdle $self $lineStart $lineEnd [regexp $commentRE $REData]
      ctext::highlightAfterIdle $self $lineStart $lineEnd
      ctext::warnWidthUpdate $self $lineStart $lineEnd
      
      switch -- $data {
        "\}" {
          ctext::matchPair $self "\\\{" "\\\}" "\\"
        }
        "\]" {
          ctext::matchPair $self "\\\[" "\\\]" "\\"
        }
        "\)" {
          ctext::matchPair $self "\\(" "\\)" ""
        }
        "\"" {
          ctext::matchQuote $self
        }
      }
      ctext::modified $self 1
      ctext::linemapUpdate $self
    }
    
    paste {
      tk_textPaste $self
      ctext::modified $self 1
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
    
    default {
      return [uplevel 1 [linsert $args 0 $self._t $cmd]]
    }
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

proc ctext::matchPair {win str1 str2 escape} {
  set prevChar [$win get "insert - 2 chars"]
  
  if {[string equal $prevChar $escape]} {
    #The char that we thought might be the end is actually escaped.
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
    
    if {[string equal $prevChar $escape]} {
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
  
  if {[$win get "$start - 1 chars"] == "\\"} {
    #the quote really isn't the end
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
    
    if {$prevChar == "\\"} {
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

proc ctext::addBlockCommentPatterns {win patterns {color "khaki"}} {
  ctext::getAr $win config configAr
  set ar(block_comment_patterns) $patterns
  $win tag configure _cComment -foreground $color
}

proc ctext::addLineCommentPatterns {win patterns {color "khaki"}} {
  ctext::getAr $win config configAr
  set ar(line_comment_patterns) $patterns
  $win tag configure _lComment -foreground $color
}

proc ctext::addStringPatterns {win patterns {color "green"}} {
  ctext::getAr $win config configAr
  set ar(string_patterns) $patterns
  $win tag configure _string -foreground $color
}

proc ctext::comments {win start end blocks {afterTriggered 0}} {

  ctext::getAr $win config configAr
  
  if {$afterTriggered} {
    set configAr(commentsAfterId) ""
  }
  
  set commentRE [join $configAr(line_comment_patterns) |]
  append commentRE {[^\n\r]*}
    
  # Handle single line comments in the given range
  set i 0
  foreach index [$win search -all -count lengths -regexp -- $commentRE $start $end] {
    $win tag add _lComment $index "$index+[lindex $lengths $i]c"
    $win tag raise _lComment
    incr i
  }
  
  set strings        [llength $configAr(string_patterns)]
  set block_comments [llength $configAr(block_comment_patterns)]
  set line_comments  [llength $configAr(line_comments)]

  if {$blocks && [expr ($strings + $block_comments + $line_comments) > 0]} {
    
    set commentRE      [getCommentRE $win]
    set double_index   ""
    set single_index   ""
    set lcomment_index ""
    set bcomment_index ""
     
    $win tag remove _cComment 1.0 end
    $win tag remove _string   1.0 end
     
    set i 0
    foreach index [$win search -all -count lengths -regexp -- $commentRE 1.0 end] {
      
      set endIndex [$win index "$index + [lindex $lengths $i] chars"]
      set str      [$win get $index $endIndex]
      
      # If the line comment index is set and the index is greater that the end of its line,
      # clear the line comment.
      if {($lcomment_index ne "") && [$win compare $index > "$lcomment_index lineend"]} {
        set lcomment_index ""
      }
      
      # Found a double-quote character
      if {($str == "\"") && ($lcomment_index eq "") && ($bcomment_index eq "") && ($single_index eq "")} {
        if {$double_index ne ""} {
          $win tag remove _string "$index+1c" end
          set double_index ""
        } else {
          $win tag add _string $index end
          $win tag raise _string
          set double_index $index
        }
        
      # Found a single-quote character
      } elseif {($str == "'") && ($lcomment_index eq "") && ($bcomment_index eq "") && ($double_index eq "")} {
        if {$single_index ne ""} {
          $win tag remove "$index+1c" end
          set single_index ""
        } else {
          $win tag add _string $index end
          $win tag raise _string
          set single_index $index
        }
        
      # Found a single line comment
      } elseif {[lsearch -exact $configAr(line_comment_patterns) $str] != -1} {
        if {($bcomment_index eq "") && ($double_index eq "") && ($single_index eq "")} {
          set lcomment_index $index
        } else {
          $win tag remove _lComment $index "$index lineend"
        }
        
      # Found a starting block comment string
      } elseif {([lsearch -exact -index 0 $configAr(block_comment_patterns) $str] != -1) && \
                ($lcomment_index eq "") && ($double_index eq "") && ($single_index eq "")} {
        if {$bcomment_index eq ""} {
          $win tag add _cComment $index end
          $win tag raise _cComment
          set bcomment_index $index
        }
        
      # Found an ending block comment string
      } elseif {([lsearch -exact -index 1 $configAr(block_comment_patterns) $str] != -1) && \
                ($lcomment_index eq "") && ($double_index eq "") && ($single_index eq "")} {
        if {$bcomment_index ne ""} {
          $win tag remove _cComment "$index+[string length $str]c" end
          set bcomment_index ""
        }
      }
      
      incr i
      
    }
  }
  
}

proc ctext::addHighlightClass {win class color keywords} {
  set ref [ctext::getAr $win highlight ar]
  
  set color_opts [expr {($color eq "") ? [list] : [list -foreground $color]}]
  foreach word $keywords {
    set ar($word) [list _$class $color_opts]
  }
  $win tag configure _$class
  
  ctext::getAr $win classes classesAr
  set classesAr(_$class) [list $ref $keywords]
}

proc ctext::addHighlightClassForRegexp {win class color re} {
  set ref [ctext::getAr $win highlightRegexp ar]
  
  set color_opts [expr {($color eq "") ? [list] : [list -foreground $color]}]
  set ar(_$class) [list $re $color_opts]
  
  $win tag configure _$class
  
  ctext::getAr $win classes classesAr
  set classesAr(_$class) [list $ref _$class]
}

#For things like $blah
proc ctext::addHighlightClassWithOnlyCharStart {win class color char} {
  set ref [ctext::getAr $win highlightCharStart ar]
  
  set color_opts [expr {($color eq "") ? [list] : [list -foreground $color]}]
  set ar($char) [list _$class $color_opts]
  
  $win tag configure _$class
  
  ctext::getAr $win classes classesAr
  set classesAr(_$class) [list $ref $char]
}

proc ctext::addSearchClassForRegexp {win class fgcolor bgcolor re} {
  set ref [ctext::getAr $win highlightRegexp ar]
  
  set ar(_$class) [list $re [list -foreground $fgcolor -background $bgcolor]]
  
  ctext::getAr $win classes classesAr
  set classesAr(_$class) [list $ref _$class]
  
  # Perform the search
  set i 0
  foreach res [$win._t search -count lengths -regexp -all -- $re 1.0 end] {
    set wordEnd [$win._t index "$res + [lindex $lengths $i] chars"]
    $win._t tag add _$class $res $wordEnd
    incr i
  }
  $win._t tag configure _$class -foreground $fgcolor -background $bgcolor
  
}

proc ctext::deleteHighlightClass {win classToDelete} {
  ctext::getAr $win classes classesAr
  
  if {![info exists classesAr(_$classToDelete)]} {
    return -code error "$classToDelete doesn't exist"
  }
  
  foreach {ref keyList} [set classesAr(_$classToDelete)] {
    upvar #0 $ref refAr
    foreach key $keyList {
      if {![info exists refAr($key)]} {
        continue
      }
      unset refAr($key)
    }
  }
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
  #no need to catch, because array unset doesn't complain
  #puts [array exists ::ctext::highlight$win]
  
  ctext::getAr $win highlight ar
  array unset ar
  
  ctext::getAr $win highlightRegexp ar
  array unset ar
  
  ctext::getAr $win highlightCharStart ar
  array unset ar
  
  ctext::getAr $win classes ar
  array unset ar

  # Delete the associated tags
  foreach tag [$win tag names] {
    if {[string index $tag 0] eq "_"} {
      $win tag delete $tag
    }
  }
}

#This is a proc designed to be overwritten by the user.
#It can be used to update a cursor or animation while
#the text is being highlighted.
proc ctext::update {win} {
  
}

proc ctext::doHighlight {win} {

  variable REs
  
  ctext::getAr $win config configAr
  
  if {!$configAr(-highlight)} {
    return
  }
  
  # Get the highlights and delete the tag
  set linesChanged [$win tag ranges lineChanged]
  $win tag delete lineChanged
  
  ctext::getAr $win highlight highlightAr
  ctext::getAr $win highlightRegexp highlightRegexpAr
  ctext::getAr $win highlightCharStart highlightCharStartAr
  
  set twin "$win._t"

  set total_keywords 0 
  set total_regexps  0
    
  foreach {start end} $linesChanged {
    
    append end " lineend"
  
    set keywords [time {
    set i 0
    foreach res [$twin search -count lengths -regexp -all -- $REs(words) $start $end] {
      set wordEnd [$twin index "$res + [lindex $lengths $i] chars"]
      set word    [$twin get $res $wordEnd]
      if {[info exists highlightAr($word)]} {
        lassign $highlightAr($word) tagClass colors
        $twin tag add $tagClass $res $wordEnd
        set tagged($tagClass) $colors
      } elseif {[info exists highlightCharStartAr([set firstOfWord [string index $word 0]])]} {
        lassign $highlightCharStartAr($firstOfWord) tagClass colors
        $twin tag add $tagClass $res $wordEnd
        set tagged($tagClass) $colors
      }
      incr i
    }
    }]
    
    set regexps [time {
    foreach {tagClass tagInfo} [array get highlightRegexpAr] {
      lassign $tagInfo re colors
      set i 0
      foreach res [$twin search -count lengths -regexp -all -- $re $start $end] {
        set wordEnd [$twin index "$res + [lindex $lengths $i] chars"]
        $twin tag add $tagClass $res $wordEnd
        set tagged($tagClass) $colors
        incr i
      }
    }
    }]

    incr total_keywords [lindex $keywords 0]
    incr total_regexps  [lindex $regexps 0]
    
  }

  # puts "total_keywords: $total_keywords, total_regexps: $total_regexps"
  
  # Finally, colorize the tags
  foreach {tagClass colors} [array get tagged] {
    $twin tag configure $tagClass {*}$colors
  }
    
}

proc ctext::linemapToggleMark {win y} {
  
  ctext::getAr $win config configAr
  
  if {!$configAr(-linemap_markable)} {
    return
  }
  
  ctext::getAr $win linemap linemapAr
  
  set markChar [$win.l index @0,$y]
  set line     [lindex [split $markChar .] 0]
  
  if {[set lmark [lsearch -inline -glob [$win.t tag names $line.0] lmark*]] ne ""} {
    #It's already marked, so unmark it.
    $win.l tag remove lmark $line.0 $line.end
    $win.t tag delete $lmark
    ctext::linemapUpdate $win
    set type unmarked
  } else {
    set lmark "lmark[incr linemapAr(id)]"
    #This means that the line isn't toggled, so toggle it.
    $win.t tag add $lmark $markChar [$win.t index "$markChar lineend"]
    $win.l tag add lmark $markChar [$win.l index "$markChar lineend"]
    $win.l tag configure lmark -foreground $configAr(-linemap_select_fg) \
      -background $configAr(-linemap_select_bg)
    set type marked
  }
  
  if {[string length $configAr(-linemap_mark_command)]} {
    uplevel #0 [linsert $configAr(-linemap_mark_command) end $win $type $lmark]
  }
  
}

proc ctext::linemapSetMark {win line} {
  
  if {[lsearch -inline -glob [$win.t tag names "$line linestart"] lmark*] eq ""} {
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
  
  if {[set lmark [lsearch -inline -glob [$win.t tag names "$line linestart"] lmark*]] ne ""} {
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
  
  set pixel 0
  set lastLine {}
  set lineList [list]
  set fontMetrics [font metrics [$win._t cget -font]]
  set incrBy [expr {1 + ([lindex $fontMetrics 5] / 2)}]
  
  while {$pixel < [winfo height $win.l]} {
    set idx [$win._t index @0,$pixel]
    if {$idx != $lastLine} {
      set line [lindex [split $idx .] 0]
      set lastLine $idx
      lappend lineList $line
    }
    incr pixel $incrBy
  }
  
  $win.l delete 1.0 end
  set lastLine {}
  foreach line $lineList {
    if {$line == $lastLine} {
      $win.l insert end "\n"
    } else {
      if {[lsearch -glob [$win.t tag names $line.0] lmark*] != -1} {
        $win.l insert end "$line\n" lmark
      } else {
        $win.l insert end "$line\n"
      }
    }
    set lastLine $line
  }
  if {[llength $lineList] > 0} {
    linemapUpdateOffset $win $lineList
  }
  set endrow [lindex [split [$win._t index end-1c] .] 0]
  $win.l configure -width [string length $endrow]
}

# Updates the warning width, if specified
proc ctext::warnWidthUpdate {win start end} {

  ctext::getAr $win config configAr
  
  # If the warning width has not been specified, skip this step
  if {$configAr(-warnwidth) eq ""} {
    $win._t tag delete warnWidth
    return
  }
  
  # Check the width of each line and
  set currRow [lindex [split $start .] 0]
  set lastRow [lindex [split $end .] 0]
  while {1} {
    $win._t tag remove warnWidth $currRow.0 $currRow.end
    $win._t tag add warnWidth $currRow.$configAr(-warnwidth) $currRow.end
    if {[incr currRow] > $lastRow} {
      break
    }
  }
  
  # Configure the background to a new color
  $win._t tag configure warnWidth -background $configAr(-warnwidth_bg)
  $win._t tag lower warnWidth
  
}

# Starting with Tk 8.5 the text widget allows smooth scrolling; this
# code calculates the offset for the line numbering text widget and
# scrolls by the specified amount of pixels

if {![catch {
  package require Tk 8.5
}]} {
  proc ctext::linemapUpdateOffset {win lineList} {
    # reset view for line numbering widget
    $win.l yview 0.0
    
    # find the first line that is visible and calculate the
    # corresponding line in the line numbers widget
    set lline 1
    foreach line $lineList {
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
