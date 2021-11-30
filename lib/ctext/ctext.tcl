# RCS: @(#) $Id: ctext.tcl,v 1.9 2011/04/18 19:49:48 andreas_kup Exp $

package require Tk
package provide ctext 5.0

# Override the tk::TextSetCursor to add a <<CursorChanged>> event
rename ::tk::TextSetCursor ::tk::TextSetCursorOrig
proc ::tk::TextSetCursor {w pos args} {
  set ins [$w index insert]
  ::tk::TextSetCursorOrig $w $pos
  event generate $w <<CursorChanged>> -data [list $ins {*}$args]
}

# Override the tk::TextButton1 to add a <<CursorChanged>> event
rename ::tk::TextButton1 ::tk::TextSetButton1Orig
proc ::tk::TextButton1 {w x y args} {
  set ins [$w index insert]
  ::tk::TextSetButton1Orig $w $x $y
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
  array set tag_other_map {"100" "001" "001" "100"}
  array set tag_dir_map   {"100" "next" "001" "prev"}
  array set tag_index_map {"100" 1 "001" 0}

  variable temporary {}
  variable alt_key     Alt
  variable right_click 3
  variable rot13_map {
    a n b o c p d q e r f s g t h u i v j w k x l y m z n a o b p c q d r e s f t g u h v i w j x k y l z m
    A N B O C P D Q E R F S G T H U I V J W K X L Y M Z N A O B P C Q D R E S F T G U H V I W J X K Y L Z M
  }

  if {[tk windowingsystem] eq "aqua"} {
    set alt_key     Mod2
    set right_click 2
  }

  proc create {win args} {

    variable data
    variable right_click
    variable alt_key
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
    set data($win,config,-insertwidth)            [$tmp cget -insertwidth]
    set data($win,config,-insertbackground)       [$tmp cget -insertbackground]
    set data($win,config,-blockbackground)        [$tmp cget -insertbackground]
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
    set data($win,config,-undo)                    1
    set data($win,config,-maxundo)                 0
    set data($win,config,-autoseparators)          1
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
    set data($win,config,-hidemeta)                0
    set data($win,config,-shiftwidth)              2
    set data($win,config,-tabstop)                 2
    set data($win,config,-blockcursor)             0
    set data($win,config,-multimove)               0
    set data($win,config,-indentmode)              "IND+"    ;# Valid values are OFF, IND and IND+
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
    set data($win,undo,undobuf)                    [list]
    set data($win,undo,redobuf)                    [list]
    set data($win,config,linemap_cmd_ip)           0
    set data($win,config,meta_classes)             [list]

    set data($win,config,ctextFlags) [list -xscrollcommand -yscrollcommand -linemap -linemapfg -linemapbg \
    -font -linemap_mark_command -highlight -warnwidth -warnwidth_bg -linemap_markable \
    -linemap_cursor -highlightcolor -folding -delimiters -matchchar -matchchar_bg -matchchar_fg -matchaudit \
    -matchaudit_bg -linemap_mark_color -linemap_relief -linemap_minwidth -linemap_type -linemap_align \
    -linemap_separator -linemap_separator_color -casesensitive -peer -theme -hidemeta \
    -undo -maxundo -autoseparators -diff_mode -diffsubbg -diffaddbg -escapes -spacing3 -lmargin \
    -blockcursor -blockbackground -multimove -insertwidth -insertbackground -shiftwidth -tabstop -indentmode]

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
    $win.t tag configure _mcursor -underline 1

    bind Ctext  <Configure>                    [list ctext::doConfigure $win]
    bind Ctext  <<CursorChanged>>              [list ctext::linemapUpdate $win]
    bind $win.l <Button-$right_click>          [list ctext::linemapToggleMark $win %x %y]
    bind $win.l <MouseWheel>                   [list event generate $win.t <MouseWheel> -delta %D]
    bind $win.l <4>                            [list event generate $win.t <4>]
    bind $win.l <5>                            [list event generate $win.t <5>]
    bind Ctext  <Destroy>                      [list ctext::event:Destroy $win]
    bind Ctext  <<Selection>>                  [list ctext::event:Selection $win]
    bind Ctext  <<Copy>>                       [list ctext::event:Copy $win]
    bind Ctext  <<Cut>>                        [list ctext::event:Cut $win]
    bind Ctext  <<Paste>>                      [list ctext::event:Paste $win]
    bind Ctext  <<Undo>>                       [list ctext::undo $win]
    bind Ctext  <<Redo>>                       [list ctext::redo $win]
    bind Ctext  <Escape>                       [list ctext::event:Escape $win]
    bind Ctext  <Key-Up>                       [list ctext::event:KeyUp $win]
    bind Ctext  <Key-Down>                     [list ctext::event:KeyDown $win]
    bind Ctext  <Key-Left>                     [list ctext::event:KeyLeft $win]
    bind Ctext  <Key-Right>                    [list ctext::event:KeyRight $win]
    bind Ctext  <Key-Home>                     [list ctext::event:KeyHome $win]
    bind Ctext  <Key-End>                      [list ctext::event:KeyEnd $win]
    bind Ctext  <Key-Delete>                   [list ctext::event:Delete $win]
    bind Ctext  <Key-BackSpace>                [list ctext::event:Backspace $win]
    bind Ctext  <Return>                       [list ctext::event:Return $win]
    bind Ctext  <Key>                          [list ctext::event:KeyPress $win %A]
    bind Ctext  <Button-1>                     [list $win cursor disable]
    bind Ctext  <$alt_key-Button-1>            [list $win cursor add @%x,%y]
    bind Ctext  <$alt_key-Button-$right_click> [list $win cursor addcolumn @%x,%y]

    foreach mod [list Shift Control $alt_key Command] {
      foreach key [list Up Down Left Right Home End] {
        bind Ctext <${mod}-Key-${key}> [list ctext::event:keyevent]
      }
    }

    bindtags $win.t [linsert [bindtags $win.t] 1 Ctext]
    bindtags $win.t [linsert [bindtags $win.t] 0 $win]

    return $win

  }

  proc event:keyevent {} {}

  ######################################################################
  # Handles a horizontal scroll event.
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

  ######################################################################
  # Handles a vertical scroll event.
  proc event:yscroll {win clientData args} {

    linemapUpdate $win

    if {$clientData == ""} {
      return
    }

    uplevel \#0 $clientData $args

  }

  ######################################################################
  # Called when the widget is destroyed.
  proc event:Destroy {win} {

    variable data

    # Remove data
    catch { rename $win {} }
    # interp alias {} $win.t {}
    array unset data $win,*

  }

  ######################################################################
  # Handles a selection of the widget in multicursor mode.
  proc event:Selection {win} {

    variable data

    if {[llength [set sel [$win._t tag ranges sel]]] > 2} {
      clear_mcursors $win
      foreach {start end} $sel {
        set_mcursor $win $start
      }
    }

  }

  ######################################################################
  # Handles a press of the Escape key.
  proc event:Escape {win} {

    $win cursor disable

  }

  ######################################################################
  # Moves cursor(s) up by one line.
  proc event:KeyUp {win} {

    $win cursor move up

    return -code break

  }

  ######################################################################
  # Moves cursor(s) down by one line.
  proc event:KeyDown {win} {

    $win cursor move down

    return -code break

  }

  ######################################################################
  # Moves cursor(s) left by one character.
  proc event:KeyLeft {win} {

    $win cursor move left

    return -code break

  }

  ######################################################################
  # Moves cursor(s) right by one character.
  proc event:KeyRight {win} {

    $win cursor move right

    return -code break

  }

  ######################################################################
  # Moves cursor(s) to the beginning of its current line.
  proc event:KeyHome {win} {

    $win cursor move linestart

    return -code break

  }

  ######################################################################
  # Moves cursor(s) to the end of its current line.
  proc event:KeyEnd {win} {

    $win cursor move lineend

    return -code break

  }

  ######################################################################
  # Handles a press of the Delete key.
  proc event:Delete {win} {

    if {[$win._t cget -state] eq "disabled"} {
      return
    }

    if {[set selected [$win._t tag ranges sel]] ne ""} {
      foreach {epos spos} [lreverse $selected] {
        $win delete -highlight 0 -mcursor 0 $spos $epos
      }
      $win syntax highlight {*}$selected
    } else {
      $win delete insert [list dchar -dir next]
    }

    return -code break

  }

  ######################################################################
  # Handles a press of a BackSpace key.
  proc event:Backspace {win} {

    if {[$win._t cget -state] eq "disabled"} {
      return
    }

    if {[set selected [$win._t tag ranges sel]] ne ""} {
      foreach {epos spos} [lreverse $selected] {
        $win delete -highlight 0 $spos $epos
      }
      $win syntax highlight {*}$selected
    } else {
      $win delete [list dchar -dir prev] insert
    }

    return -code break

  }

  ######################################################################
  # Handles a press of the Return key.
  proc event:Return {win} {

    if {[$win._t cget -state] eq "disabled"} {
      return
    }

    if {[$win._t tag ranges sel] ne ""} {
      $win replace selstart selend "\n"
    } else {
      $win insert cursor "\n"
    }

    return -code break

  }

  ######################################################################
  # Handles a keypress of the given character.
  proc event:KeyPress {win char} {

    if {($char eq "") || ([$win._t cget -state] eq "disabled")} {
      return
    }
     
    if {[$win._t tag ranges sel] ne ""} {
      $win replace selstart selend $char
    } else {
      $win insert cursor $char
    }

    return -code break

  }

  ######################################################################
  # Handles the copy virtual event.
  proc event:Copy {win} {

    $win copy

    return -code break

  }

  ######################################################################
  # Handles the cut virtual event.
  proc event:Cut {win} {

    $win cut

    return -code break

  }

  ######################################################################
  # Handles the paste virtual event.
  proc event:Paste {win} {

    $win paste

    return -code break

  }

  ######################################################################
  # Returns true if the given window exists.
  proc winExists {win} {

    variable data

    return [info exists data($win,config,-font)]

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

    lappend argTable {1 true yes} -blockcursor {
      set data($win,config,-blockcursor) 1
      if {[$win._t compare "insert linestart" == "insert lineend"]} {
        $win._t insert insert " " _dspace
        $win._t mark set insert "insert linestart"
      }
      update_cursor $win
    }

    lappend argTable {0 false no} -blockcursor {
      set data($win,config,-blockcursor) 0
      if {[$win._t tag ranges _mcursor] eq ""} {
        catch { $win._t delete {*}[$win._t tag ranges _dspace] }
      }
      update_cursor $win
    }

    lappend argTable any -insertbackground {
      if {[catch { winfo rgb $win $value } res]} {
        return -code error $res
      }
      set data($win,config,-insertbackground) $value
      update_cursor $win
    }

    lappend argTable any -blockbackground {
      if {[catch { winfo rgb $win $value } res]} {
        return -code error $res
      }
      set data($win,config,-blockbackground) $value
      update_cursor $win
    }

    lappend argTable {1 true yes} -multimove {
      set data($win,config,-multimove) 1
      update_cursor $win
    }

    lappend argTable {0 false no} -multimove {
      set data($win,config,-multimove) 0
      update_cursor $win
    }

    lappend argTable any -insertwidth {
      if {![string is integer $value] || ($value < 0)} {
        return -code error "ctext -insertwidth value must be an positive integer value"
      }
      set data($win,config,-insertwidth) $value
      update_cursor $win
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

    lappend argTable {0 false no} -hidemeta {
      set data($win,config,-hidemeta) 0
      updateMetaChars $win
      break
    }

    lappend argTable {1 true yes} -hidemeta {
      set data($win,config,-hidemeta) 1
      updateMetaChars $win
      break
    }

    lappend argTable {any} -shiftwidth {
      if {![string is integer $value]} {
        return -code error "Shiftwidth set to a non-integer value"
      }
      set data($win,config,-shiftwidth) $value
    }

    lappend argTable {any} -tabstop {
      if {![string is integer $value]} {
        return -code error "Tabstop set to a non-integer value"
      }
      set data($win,config,-tabstop) $value
      $win._t configure -tabs [list [expr $value * [font measure [$win._t cget -font] 0]] left]
    }

    lappend argTable {any} -indentmode {
      if {[lsearch {OFF IND IND+} $value] == -1} {
        return -code error "Indent mode is not OFF, IND or IND+"
      }
      set data($win,config,-indentmode) $value
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

  ######################################################################
  # Adjusts the start and end indices such that start is less than or
  # equal to end.
  proc adjust_start_end {win pstart pend} {
    upvar $pstart startpos
    upvar $pend   endpos
    if {[$win._t compare $endpos < $startpos]} {
      lassign [list $endpos $startpos] startpos endpos
    }
  }

  ######################################################################
  # UNDO/REDO FUNCTIONALITY
  ######################################################################
  
  ######################################################################
  # Displays the given undo/redo buffer to standard output (used for
  # debugging purposes only).
  proc undo_display {win buf} {

    variable data

    puts "[string toupper $buf] Buffer"
    puts "---------------------------"

    foreach group $data($win,undo,${buf}buf) {
      foreach change $group {
        lassign $change type spos epos str cursor mcursor
        puts "    $type $spos $epos $cursor $mcursor"
        puts "      .[string map [list "\n" ".\n      ."] $str]."
      }
      puts "  =="
    }

    if {($buf eq "undo") && [info exists data($win,undo,uncommitted)]} {
      puts "  UNCOMMITTED"
      foreach change $data($win,undo,uncommitted) {
        lassign $change type spos epos str cursor mcursor
        puts "    $type $spos $epos $cursor $mcursor"
        puts "      .[string map [list "\n" ".\n      ."] $str]."
      }
    }

  }

  ######################################################################
  # Merges the given change into the last uncommitted change if there is
  # compatibility.
  proc undo_merge {win change} {

    variable data

    lassign [lindex $data($win,undo,uncommitted) end] utype uspos uepos ustr ucursor umcursor
    lassign $change                                   ctype cspos cepos cstr ccursor cmcursor

    if {$utype eq "i"} {
      if {$ctype eq "i"} {
        lassign [split $uepos .] urow ucol
        lassign [split $cspos .] crow ccol
        if {($uepos eq $cspos) || ((($urow + 1) == $crow) && ($ccol == 0) && ([string index $ustr end] eq "\n"))} {
          append ustr $cstr
          lset data($win,undo,uncommitted) end [list i $uspos $cepos $ustr $ucursor $umcursor]
          return 1
        }
      } elseif {($uepos eq $cepos) && [$win._t compare $uspos < $cspos]} {
        lassign [split $uspos .] urow ucol
        set ustr   [string range $ustr 0 end-[string length $cstr]]
        set ulines [split $ustr \n]
        incr urow  [set unum [expr [llength $ulines] - 1]]
        set ucol   [expr (($unum > 0) ? 0 : $ucol) + [string length [lindex $ulines end]]]
        lset data($win,undo,uncommitted) end [list i $uspos $urow.$ucol $ustr $ucursor $umcursor]
        return 1
      }
    } else {
      if {$ctype eq "i"} {
        if {$uspos eq $cspos} {
          lappend data($win,undo,uncommitted) $change
          return 1
        }
      } elseif {$uspos eq $cepos} {
        lset data($win,undo,uncommitted) end [list d $cspos $uepos [string cat $cstr $ustr] $ucursor $umcursor]
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Adds the given change to the undo buffer.
  proc undo_add_change {win change stop_separate} {

    variable data

    # If we don't have a current change group, create it
    if {![info exists data($win,undo,uncommitted)]} {
      lappend data($win,undo,uncommitted) $change
      set data($win,undo,redobuf) [list]

    # Attempt to merge -- if unsuccessful, add it to the back
    } elseif {![undo_merge $win $change]} {
      if {$data($win,config,-autoseparators) && !$stop_separate} {
        lappend data($win,undo,undobuf) $data($win,undo,uncommitted)
        unset data($win,undo,uncommitted)
      }
      lappend data($win,undo,uncommitted) $change
    }

  }

  ######################################################################
  # Adds the given insertion undo information to the undo buffer.
  proc undo_insert {win ranges str cursor} {

    variable data

    if {!$data($win,config,-undo)} {
      return
    }

    set mcursor [expr [llength $ranges] > 2]

    undo_add_change $win [list i {*}[lrange $ranges 0 1] $str $cursor $mcursor] 0

    # Handle multiple cursors if we have any
    foreach {spos epos} [lrange $ranges 2 end] {
      undo_add_change $win [list i $spos $epos $str $cursor $mcursor] 1
    }

  }

  ######################################################################
  # Adds the given insertion list undo information to the undo buffer.
  proc undo_insertlist {win ranges strs cursor} {

    variable data

    if {!$data($win,config,-undo)} {
      return
    }

    set mcursor [expr [llength $ranges] > 2]

    undo_add_change $win [list i {*}[lrange $ranges 0 1] [lindex $strs 0] $cursor $mcursor] 0

    foreach {spos epos} [lrange $ranges 2 end] str [lrange $strs 1 end] {
      undo_add_change $win [list i $spos $epos $str $cursor $mcursor] 1
    }

  }

  ######################################################################
  # Adds the given delete undo information to the undo buffer.
  proc undo_delete {win ranges strs cursor} {

    variable data

    if {!$data($win,config,-undo)} {
      return
    }

    set mcursor [expr [llength $ranges] > 2]

    undo_add_change $win [list d {*}[lrange $ranges 0 1] [lindex $strs 0] $cursor $mcursor] 0

    foreach {spos epos} [lrange $ranges 2 end] str [lrange $strs 1 end] {
      undo_add_change $win [list d $spos $epos $str $cursor $mcursor] 1
    }

  }

  ######################################################################
  # Adds the given replace undo information to the undo buffer.
  proc undo_replace {win ranges dstrs istr cursor} {

    variable data

    if {!$data($win,config,-undo)} {
      return
    }

    set mcursor [expr [llength $ranges] > 3]

    undo_add_change $win [list d [lindex $ranges 0] [lindex $ranges 1] [lindex $dstrs 0] $cursor $mcursor] 0
    undo_add_change $win [list i [lindex $ranges 0] [lindex $ranges 2] $istr $cursor $mcursor] 1

    foreach {spos eposd eposi} [lrange $ranges 3 end] dstr [lrange $dstrs 1 end] {
      undo_add_change $win [list d $spos $eposd $dstr $cursor $mcursor] 1
      undo_add_change $win [list i $spos $eposi $istr $cursor $mcursor] 1
    }

  }

  ######################################################################
  # Adds the given replace undo information to the undo buffer.
  proc undo_replacelist {win ranges dstrs istrs cursor} {

    variable data

    if {!$data($win,config,-undo)} {
      return
    }

    set mcursor [expr [llength $ranges] > 3]

    undo_add_change $win [list d [lindex $ranges 0] [lindex $ranges 1] [lindex $dstrs 0] $cursor $mcursor] 0
    undo_add_change $win [list i [lindex $ranges 0] [lindex $ranges 2] [lindex $istrs 0] $cursor $mcursor] 1

    foreach {spos eposd eposi} [lrange $ranges 3 end] dstr [lrange $dstrs 1 end] istr [lrange $istrs 1 end] {
      undo_add_change $win [list d $spos $eposd $dstr $cursor $mcursor] 1
      undo_add_change $win [list i $spos $eposi $istr $cursor $mcursor] 1
    }

  }
  ######################################################################
  # Adds a separator to the undo buffer if valid to do so.
  proc undo_add_separator {win} {

    variable data

    if {[info exists data($win,undo,uncommitted)]} {
      lappend data($win,undo,undobuf) $data($win,undo,uncommitted)
      unset data($win,undo,uncommitted)
    }

  }

  ######################################################################
  # Returns the list of cursor positions that are stored in the undo buffer.
  proc undo_get_cursor_hist {win} {

    variable data

    set cursors [list]

    foreach group [lreverse $data($win,undo,undobuf)] {
      foreach change [lreverse $group] {
        lappend cursors [lindex $change 4]
      }
    }

    return $cursors

  }

  ######################################################################
  # Performs an undo/redo operation for all changes within the same
  # change group.
  proc undo_action {win from to} {

    variable data

    # If we have uncommitted changes, commit them now
    undo_add_separator $win

    # If there is something in the undo buffer, undo one change group
    if {[llength $data($win,undo,${from}buf)] > 0} {

      # Get the last change group
      set last        [lindex $data($win,undo,${from}buf) end]
      set tochanges   [list]
      set changed     ""
      set insert      0
      set last_cursor 1.0
      set do_tags     [list]

      array set inv [list i d d i]

      foreach change [lreverse $last] {
        lassign $change type spos epos str cursor mcursor
        if {$type eq "i"} {
          append changed $str
          comments_chars_deleted $win $spos $epos do_tags
          $win._t delete $spos $epos
          $win._t tag add hl "$spos linestart" "$spos lineend"
        } else {
          $win._t insert $spos $str
          $win._t tag add hl "$spos linestart" "$epos lineend"
          append changed $str
          comments_do_tag $win [list $spos $epos] do_tags
          set_rmargin $win $spos $epos
          set insert 1
        }
        lappend tochanges [list $inv($type) $spos $epos $str $cursor $mcursor]
        set last_cursor $cursor
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

      # Push the undo buffer changes to the redo buffer
      lappend data($win,undo,${to}buf) $tochanges

      # Pop the undo buffer
      set data($win,undo,${from}buf) [lreplace $data($win,undo,${from}buf) end end]

      # Update the cursor and indicate the the buffer has changed
      ::tk::TextSetCursor $win.t $last_cursor
      modified $win 1 [list $from $ranges ""]

    }

  }

  ######################################################################
  # Performs an undo for a single change group.
  proc undo {win} {

    undo_action $win undo redo

  }

  ######################################################################
  # Performs a redo for a single change group.
  proc redo {win} {

    undo_action $win redo undo

  }

  ######################################################################
  # GUTTER-RELATED FUNCTIONALITY
  ######################################################################

  ######################################################################
  # Returns the current list of gutter tags.
  proc getGutterTags {win pos} {

    set alltags [$win tag names $pos]
    set tags    [lsearch -inline -all -glob $alltags gutter:*]
    lappend tags {*}[lsearch -inline -all -glob $alltags lmark*]

    return $tags

  }

  ######################################################################
  # Move all gutter tags from the old column 0 of the given row to the new
  # column 0 character.
  proc handleInsertAt0 {win startpos endpos} {

    if {[lindex [split $startpos .] 1] == 0} {
      foreach tag [getGutterTags $win $endpos] {
        $win._t tag add $tag $startpos
        $win._t tag remove $tag $endpos
      }
    }

  }

  ######################################################################
  # Move gutter tags when tagged text is deleted.
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

  proc handleReplaceInsert {win startpos endpos tags} {

    if {[lindex $tags 0]} {
      set insertpos $endpos
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
      cursor      { return [command_cursor      $win {*}$args] }
      cut         { return [command_cut         $win {*}$args] }
      delete      { return [command_delete      $win {*}$args] }
      diff        { return [command_diff        $win {*}$args] }
      edit        { return [command_edit        $win {*}$args] }
      gutter      { return [command_gutter      $win {*}$args] }
      indent      { return [command_indent      $win {*}$args] }
      index       { return [command_index       $win {*}$args] }
      insert      { return [command_insert      $win {*}$args] }
      insertlist  { return [command_insertlist  $win {*}$args] }
      is          { return [command_is          $win {*}$args] }
      replace     { return [command_replace     $win {*}$args] }
      replacelist { return [command_replacelist $win {*}$args] }
      paste       { return [command_paste       $win {*}$args] }
      peer        { return [command_peer        $win {*}$args] }
      syntax      { return [command_syntax      $win {*}$args] }
      tag         { return [command_tag         $win {*}$args] }
      transform   { return [command_transform   $win {*}$args] }
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

    if {$arg ne "-tabs"} {
      foreach flag $data($win,config,ctextFlags) {
        if {[string match ${arg}* $flag]} {
          return [set data($win,config,$flag)]
        }
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

  ######################################################################
  # Copy the multicursor positions for future paste operations.
  proc copy_mcursors {win} {

    variable data

    # Current index
    set selected [$win._t tag ranges sel]
    set current  $start

    # Initialize copy cursor information
    set data($win,copy_offsets) [list]
    set data($win,copy_value)   [$win._t get {*}$selected]

    # Get the mcursor offsets from start
    while {[set index [$win._t tag nextrange _mcursor $current $end]] ne ""} {
      lappend data($win,copy_offsets) [$win._t count -chars $start [lindex $index 0]]
      set current [$win._t index "[lindex $index 0]+1c"]
    }

  }

  ######################################################################
  # If text is currently selected, clears the clipboard and adds the
  # selected text to the clipboard; otherwise, clears the clipboard and
  # adds the contents of the current line to the clipboard.
  proc do_copy {win args} {

    variable data

    # Handle the arguments
    switch [llength $args] {
      0 {
        set sposargs [list linestart -num 0]
        set eposargs [list linestart -num 1]
      }
      1 {
        set sposargs cursor
        set eposargs [lindex $args 0]
      }
      2 {
        set sposargs [lindex $args 0]
        set eposargs [lindex $args 1]
      }
      default {
        return -code error "Illegal argument list to copy/cut command ($args)"
      }
    }

    # Clear the clipboard
    clipboard clear -display $win.t

    # Collect the text ranges to get
    if {[set ranges [$win._t tag ranges sel]] eq ""} {
      set cursors [expr {[$win cursor enabled] ? [$win cursor get] : [$win._t index insert]}]
      foreach cursor $cursors {
        set startpos [$win index {*}$sposargs -startpos $cursor]
        set endpos   [$win index {*}$eposargs -startpos $cursor]
        adjust_start_end $win startpos endpos
        if {[lindex $ranges end] ne $endpos} {
          lappend ranges $startpos $endpos
        }
      }
    }

    # If there is nothing to copy, return immediately
    if {[llength $ranges] == 0} {
      return
    }

    # Collect the text and cursor information
    set contents                [list]
    set charpos                 0
    set data($win,copy_offsets) [list]
    set orig_ranges             $ranges
    while {$ranges ne ""} {
      set ranges [lassign $ranges startpos endpos]
      set str [$win._t get $startpos $endpos]
      if {($ranges ne "") && ([string index $str end] eq "\n")} {
        set str [string range $str 0 end-1]
      }
      set curpos $startpos
      while {[set index [$win._t tag nextrange _mcursor $curpos $endpos]] ne ""} {
        lappend data($win,copy_offsets) [expr $charpos + [$win._t count -chars $startpos [lindex $index 0]]]
        set curpos "[lindex $index 0]+1c"
      }
      incr charpos [expr [string length $str] + 1]
      lappend contents $str
    }

    # Get the contents of the clipboard
    clipboard append -displayof $win.t [set data($win,copy_value) [join $contents \n]]

    return $orig_ranges

  }

  ######################################################################
  # Performs a copy to clipboard operation.
  proc command_copy {win args} {

    do_copy $win {*}$args

  }

  ######################################################################
  # Allows the users to interact with multicursor support within the widget.
  proc command_cursor {win args} {

    variable data

    switch [lindex $args 0] {
      add {
        foreach index [lrange $args 1 end] {
          set_mcursor $win [set index [$win index {*}$index]]
          set data($win,mcursor_anchor) $index
        }
        update_cursor $win
      }
      addcolumn {
        if {[llength $args] != 2} {
          return -code error "Incorrect number of arguments to ctext mcursor addcolumn"
        }
        if {[info exists data($win,mcursor_anchor)]} {
          set index [$win index {*}[lindex $args 1]]
          lassign [split $data($win,mcursor_anchor) .] anchor_row col
          set row [lindex [split $index .] 0]
          if {$row < $anchor_row} {
            for {set i [expr $anchor_row - 1]} {$i >= $row} {incr i -1} {
              set_mcursor $win $i.$col
            }
          } else {
            for {set i [expr $anchor_row + 1]} {$i <= $row} {incr i} {
              set_mcursor $win $i.$col
            }
          }
          set data($win,mcursor_anchor) $index
        }
      }
      enabled {
        return [expr {[$win._t tag ranges _mcursor] ne ""}]
      }
      disable {
        clear_mcursors $win
        unset -nocomplain data($win,mcursor_anchor)
        update_cursor $win
      }
      set {
        if {([llength [lindex $args 1]] == 1) || \
            ([info procs getindex_[lindex $args 1 0]] ne "") || \
            ([lsearch [list linestart lineend display wordstart wordend] [lindex $args 1 1]] != -1)} {
          set_cursor $win [$win index {*}[lindex $args 1]]
        } else {
          clear_mcursors $win
          foreach index [lindex $args 1] {
            set_mcursor $win [$win index {*}$index]
            set data($win,mcursor_anchor) $index
          }
        }
        update_cursor $win
      }
      num {
        return [expr [llength [$win._t tag ranges _mcursor]] / 2]
      }
      get {
        set indices [list]
        foreach {startpos endpos} [$win._t tag ranges _mcursor] {
          lappend indices $startpos
        }
        return $indices
      }
      remove {
        foreach index [lrange $args 1 end] {
          clear_mcursor $win [$win index {*}$index]
        }
        update_cursor $win
      }
      move {
        if {[llength $args] != 2} {
          return -code error "Incorrect number of arguments to ctext cursor move command"
        }
        if {[info procs getindex_[lindex $args 1 0]] eq ""} {
          return -code error "ctext cursor move command must be called with a relative index"
        }
        if {([set mcursors [$win._t tag ranges _mcursor]] ne "") && $data($win,config,-multimove)} {
          clear_mcursors $win
          foreach {startpos endpos} $mcursors {
            set_mcursor $win [$win index {*}[lindex $args 1] -startpos $startpos] $startpos
            set data($win,mcursor_anchor) $startpos
          }
          return 1
        } else {
          set_cursor $win [$win index {*}[lindex $args 1]]
          return 0
        }
      }
      align {
        if {[set mcursor [$win._t tag ranges _mcursor]] ne ""} {
          array set opts {
            -text 1
          }
          array set opts [lrange $args 1 end]
          if {$opts(-text)} {
            align_with_text $win
          } else {
            align $win
          }
        }
      }
      default {
        return -code error "Illegal ctext mcursor command ([lindex $args 0])"
      }
    }

  }

  ######################################################################
  # If text is currently selected, clears the clipboard, adds the selected
  # text to the clipboard and deletes the selected text.  If no text is
  # selected, performs the same procedure with the contents of the current
  # line.
  proc command_cut {win args} {

    variable data

    # Perform the copy
    set ranges [do_copy $win {*}$args]

    # Delete the text
    foreach {endpos startpos} [lreverse $ranges] {
      $win delete -mcursor 0 $startpos $endpos
    }

  }

  ######################################################################
  # Helper method for commands like deletion, replacement and transform
  # which calculate the ranges to modify, start specification, end
  # specification and whether multicursors should be added/modified.
  #
  # Returns a list with the specified contents:
  #   - starting index specification
  #   - ending index specification
  #   - set multicursor after edit
  #   - cursor ranges
  proc get_delete_replace_info {win mcursor cursor startspec endspec} {

    # Figure out the ranges to delete
    if {[set ranges [$win._t tag ranges sel]] ne ""} {
      return [list cursor [list selend -dir next] [expr [llength $ranges] > 2] $ranges]
    } else {
      if {$startspec eq ""} { set startspec cursor }
      if {$endspec   eq ""} { set endspec [list char -num 1] }
      if {$mcursor && ([set ranges [$win._t tag ranges _mcursor]] ne "")} {
        return [list $startspec $endspec 1 $ranges]
      } else {
        return [list $startspec $endspec 0 [list $cursor $cursor+1c]]
      }
    }

  }

  ######################################################################
  # Deletes one or more ranges of text and performs syntax highlighting.
  proc command_delete {win args} {

    variable data

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -moddata   {}
      -highlight 1
      -mcursor   1
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    set delranges   [list]
    set ranges      [list]
    set do_tags     [list]
    set cursor      [$win._t index insert]
    set set_mcursor 0

    lassign [lrange $args $i end] startspec endspec
    lassign [get_delete_replace_info $win $opts(-mcursor) $cursor $startspec $endspec] startspec endspec set_mcursor delranges

    foreach {endpos startpos} [lreverse $delranges] {
      set startpos [$win index {*}$startspec -startpos $startpos]
      set endpos   [$win index {*}$endspec   -startpos $startpos]
      adjust_start_end $win startpos endpos
      lappend strs [$win._t get $startpos $endpos]
      handleDeleteAt0        $win $startpos $endpos
      linemapCheckOnDelete   $win $startpos $endpos
      comments_chars_deleted $win $startpos $endpos do_tags
      $win._t delete $startpos $endpos
      if {$set_mcursor} {
        if {[$win._t compare $startpos == "$startpos lineend"] && [$win._t compare $startpos != "$startpos linestart"]} {
          $win._t tag add _mcursor $startpos-1c
        } else {
          $win._t tag add _mcursor $startpos
        }
      }
      lappend ranges $startpos $endpos
    }

    undo_delete $win $ranges $strs $cursor

    if {$opts(-highlight)} {

      if {[highlightAll $win $ranges 0 $do_tags]} {
        checkAllBrackets $win
      } else {
        checkAllBrackets $win [string cat {*}$strs]
      }

      foreach {epos spos} [lreverse $ranges] {
        indent_backspace $win $spos
      }

    }

    modified $win 1 [list delete $ranges $opts(-moddata)]
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

  ######################################################################
  # Conforms the indentation of the specified range to match the indentation
  # of the preceeding text.
  #
  # Usage:  $txt indent options subcmd ?start_index end_index?
  # 
  # Options:
  #   -moddata        Data sent with modified event generated from this command
  #   -mcursor (0|1)  If set, performs indentation for each range relative to the
  #                       multiple cursor locations; otherwise, performs on
  #                       range relative to insertion cursor
  #
  # Subcommands:
  #   left        Shifts the text to the left (shift controlled by the -shiftwidth config value)
  #   right       Shifts the text to the right (shift controlled by the -shiftwidth config value)
  #   auto        Shifts all lines to conform indentation to code context.
  #
  # Parameters:
  #   start_index    Start of text range to indent relative to a cursor.  Any
  #                      valid index specification that the index command will allow.
  #   end_index      End of text range to indent relative to a cursor.  Any valid
  #                      index specification that the index command will allow.
  proc command_indent {win args} {

    variable data

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -moddata {}
      -mcursor 1
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    set sspec first
    set espec last
    lassign [lrange $args $i end] subcmd sspec espec

    if {[lsearch {right left auto} $subcmd] == -1} {
      return -code error "Invalid ctext indent subcommand ($subcmd)"
    }

    set ranges      [list]
    set undo_append 0
    set cursor      [$win._t index insert]

    lassign [get_delete_replace_info $win $opts(-mcursor) $cursor $sspec $espec] sspec espec set_mcursor delranges

    foreach {epos spos} [lreverse $delranges] {
      indent_shift_$subcmd $win [$win index {*}$sspec -startpos $spos] [$win index {*}$espec -startpos $spos] $set_mcursor ranges undo_append
    }

    # Create a separator
    undo_add_separator $win

    # Let everyone know about the change
    modified $win 1 [list indent $ranges $opts(-moddata)]
    event generate $win.t <<CursorChanged>>

  }

  ######################################################################
  # Returns the index associated with the given value.
  proc command_index {win args} {

    if {[set procs [info procs getindex_[lindex $args 0]]] ne ""} {

      array set opts {
        -startpos    "insert"
        -adjust      ""
        -forceadjust ""
      }
      array set opts [lrange $args 1 end]

      set startpos [$win index {*}$opts(-startpos)]
      set index    [[lindex $procs 0] $win $startpos [lrange $args 1 end]]

      if {$opts(-forceadjust) ne ""} {
        return [$win._t index "$index$opts(-forceadjust)"]
      } elseif {[$win._t compare $index != $startpos] && ($opts(-adjust) ne "")} {
        return [$win._t index "$index$opts(-adjust)"]
      } else {
        return [$win._t index $index]
      }

    } else {

      set index [join $args]
      regexp {^(.*)-(startpos|adjust|forceadjust)} $index -> index

      if {![catch { $win._t index $index } rc]} {
        return $rc
      } else {
        puts "NEED TO CATCH THIS CASE!"
        puts "args: $args"
        puts [utils::stacktrace]  ;# TEMPORARY
        puts $rc
        return 1.0
      }

    }

  }

  ######################################################################
  # Inserts text at the given cursor or at multicursors (if set) and
  # performs highlighting on that text.  Additionally, updates the undo
  # buffer.
  proc command_insert {win args} {

    variable data

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -moddata   {}
      -highlight 1
      -mcursor   1
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    # Get the number of characters being inserted and adjust the tags
    set chars 0
    set items [list]
    set dat   ""
    foreach {content tags} [lassign [lrange $args $i end] insertPos] {
      incr chars [string length $content]
      lappend items $content [list {*}$tags lmargin rmargin __Lang:]
      append dat $content
    }

    set ranges  [list]
    set cursor  [$win._t index insert]
    set do_tags [list]

    # Insert the text
    if {$opts(-mcursor) && ([$win._t tag ranges _mcursor] ne "")} {
      set start 1.0
      while {[set range [$win._t tag nextrange _mcursor $start]] ne [list]} {
        set startPos [string map [list "cursor" [lindex $range 0]] $insertPos]
        $win._t insert $startPos {*}[string map [list __Lang: [getLangTag $win $startPos]] $items]
        set endPos [$win._t index "$startPos+${chars}c"]
        set start  [$win._t index $endPos+1c]
        handleInsertAt0 $win $startPos $endPos
        lappend ranges $startPos $endPos
      }
    } else {
      if {$insertPos eq "end"} {
        set insPos [$win._t index $insertPos-1c]
      } else {
        set insPos [set insertPos [$win index {*}$insertPos]]
      }
      $win._t insert $insertPos {*}[string map [list __Lang: [getLangTag $win $insertPos]] $items]
      set endPos [$win._t index "$insPos+${chars}c"]
      handleInsertAt0 $win $insertPos $endPos
      lappend ranges $insPos $endPos
    }

    # Delete any dspace characters
    catch { $win._t delete {*}[$win._t tag ranges _dspace] }

    undo_insert     $win $ranges $dat $cursor
    comments_do_tag $win $ranges do_tags

    if {$opts(-highlight)} {

      # Highlight text and bracket auditing
      if {[highlightAll $win $ranges 1 $do_tags]} {
        checkAllBrackets $win
      } else {
        checkAllBrackets $win $dat
      }

      # Handle the indentation
      if {[string index $dat end] eq "\n"} {
        foreach {epos spos} [lreverse $ranges] {
          indent_newline $win $epos
        }
      } else {
        foreach {epos spos} [lreverse $ranges] {
          indent_check_indent $win $epos
        }
      }

    }

    modified $win 1 [list insert $ranges $opts(-moddata)]
    event generate $win.t <<CursorChanged>>

  }

  ######################################################################
  # Inserts different strings at each multicursor location.
  proc command_insertlist {win args} {

    variable data

    if {[$win._t tag ranges _mcursor] ne ""} {

      set i 0
      while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

      array set opts {
        -moddata   {}
        -highlight 1
      }
      array set opts [lrange $args 0 [expr $i - 1]]

      lassign [lrange $args $i end] contents

      set ranges  [list]
      set strs    [list]
      set do_tags [list]
      set cursor  [$win._t index insert]
      set start   1.0
      set cindex  0

      while {[set range [$win._t tag nextrange _mcursor $start]] ne ""} {
        set startPos [lindex $range 0]
        set content  [lindex $contents $cindex]
        lassign $content str tags
        if {[set lang [getLang $win $startPos]] ne ""} {
          $win._t insert $startPos $str [list {*}$tags lmargin rmargin $lang]
        } else {
          $win._t insert $startPos $str [list {*}$tags lmargin rmargin]
        }
        set endPos [$win._t index "$startPos+[string length $str]c"]
        set start  [$win._t index $endPos+1c]
        incr cindex
        handleInsertAt0 $win $startPos $endPos
        lappend ranges $startPos $endPos
        lappend strs   $str
      }

      # Delete any dspace characters
      catch { $win._t delete {*}[$win._t tag ranges _dspace] }

      undo_insertlist $win $ranges $strs $cursor
      comments_do_tag $win $ranges do_tags

      if {$opts(-highlight)} {

        # Highlight text and bracket auditing
        if {[highlightAll $win $ranges 1 $do_tags]} {
          checkAllBrackets $win
        } else {
          checkAllBrackets $win [string cat {*}$strs]
        }

        # Handle the indentation
        foreach {epos spos} [lreverse $ranges] str [lreverse $strs] {
          if {[string index $str end] eq "\n"} {
            indent_newline $win $epos
          } else {
            indent_check_indent $win $epos
          }
        }

      }

      modified $win 1 [list insert $ranges $opts(-moddata)]
      event generate $win.t <<CursorChanged>>

    }

  }

  ######################################################################
  # Answers questions about a given index
  proc command_is {win args} {

    if {[llength $args] < 2} {
      return -code error "Incorrect arguments passed to ctext is command"
    }

    lassign $args type extra index

    switch $type {
      escaped   { return [isEscaped $win [$win index {*}$extra]] }
      selected  { return [expr [lsearch [$win._t tag names [$win index {*}$extra]] sel] != -1] }
      firstchar {
        set index    [$win index {*}$extra]
        set prewhite [$win._t tag prevrange __prewhite "$index+1c"]
        return [expr {($prewhite ne "") && [$win._t compare [lindex $prewhite 1] == "$index+1c"]}]
      }
      linestart -
      lineend {
        set index [$win index {*}$extra]
        return [$win._t compare $index == "$index $type"]
      }
      curly   -
      square  -
      paren   -
      angled  {
        if {[lsearch [list left right any] $extra] == -1} {
          set index [$win index {*}$extra]
          set extra "any"
        } else {
          set index [$win index {*}$index]
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
          set index [$win index {*}$extra]
          set extra "any"
        } else {
          set index [$win index {*}$index]
        }
        array set chars [list double d single s btick b tripledouble D triplesingle S triplebtick B]
        return [isQuote $win $chars($type) $index $extra]
      }
      indent        -
      unindent      -
      reindent      -
      reindentStart {
        return [expr [lsearch [$win._t tag names [$win index {*}$extra]] __$type] != -1]
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
          return [in$procs($type)Range $win [$win index {*}$extra] range]
        } else {
          return [in$procs($type) $win [$win index {*}$extra]]
        }
      }
      inclass         {
        if {$extra eq ""} {
          return -code error "Calling ctext is inclass without specifying a class name"
        }
        if {[lsearch -exact [$win._t tag names [$win index {*}$extra]] __$index] != -1} {
          set range [$win._t tag prevrange __$extra "[$win index {*}$index]+1c"]
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

  ######################################################################
  # Replaces the specified text range with the given string.
  proc command_replace {win args} {

    variable data

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -moddata   {}
      -highlight 1
      -mcursor   1
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    # Get the number of characters being inserted and adjust the tags
    set chars 0
    set items [list]
    set dat   ""
    foreach {content tags} [lassign [lrange $args $i end] startspec endspec] {
      incr chars [string length $content]
      lappend items $content [list {*}$tags lmargin rmargin __Lang:]
      append dat $content
    }

    set uranges [list]
    set rranges [list]
    set do_tags [list]
    set cursor  [$win._t index insert]

    lassign [get_delete_replace_info $win $opts(-mcursor) $cursor $startspec $endspec] startspec endspec set_mcursor delranges

    foreach {endpos startpos} [lreverse $delranges] {
      set startpos [$win index {*}$startspec -startpos $startpos]
      set endpos   [$win index {*}$endspec   -startpos $startpos]
      adjust_start_end $win startpos endpos
      lappend dstrs [$win._t get $startpos $endpos]
      lappend istrs $dat
      comments_chars_deleted $win $startpos $endpos do_tags
      set t [handleReplaceDeleteAt0 $win $startpos $endpos]
      $win._t replace $startpos $endpos {*}[string map [list __Lang: [getLangTag $win $startpos]] $items]
      set new_endpos  [$win._t index "$startpos+${chars}c"]
      handleReplaceInsert $win $startpos $endpos $t
      lappend uranges $startpos $endpos $new_endpos
      lappend rranges $startpos $new_endpos
    }

    undo_replace    $win $uranges $dstrs $istrs $cursor
    comments_do_tag $win $rranges do_tags

    if {$opts(-highlight)} {

      # Highlight text and bracket auditing
      switch [highlightAll $win $rranges 1 $do_tags] {
        2       { checkAllBrackets $win }
        1       { checkAllBrackets $win [$win._t get $startpos $endpos] }
        default { checkAllBrackets $win [string cat {*}$dstrs {*}$istrs] }
      }

      # Handle the indentation
      if {[string index $dat end] eq "\n"} {
        foreach {epos spos} [lreverse $rranges] {
          indent_newline $win $epos
        }
      } else {
        foreach {epos spos} [lreverse $rranges] {
          indent_check_indent $win $epos
        }
      }

    }

    modified $win 1 [list replace $rranges $opts(-moddata)]
    event generate $win.t <<CursorChanged>>

  }

  ######################################################################
  # Replaces text at each multicursor location with each string/tag in the
  # given list.
  proc command_replacelist {win args} {

    variable data

    if {[$win._t tag ranges _mcursor] ne ""} {

      set i 0
      while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

      array set opts {
        -moddata   {}
        -highlight 1
      }
      array set opts [lrange $args 0 [expr $i - 1]]

      lassign [lrange $args $i end] endSpec contents

      set uranges [list]
      set rranges [list]
      set dstrs   [list]
      set istrs   [list]
      set do_tags [list]
      set cursor  [$win._t index insert]
      set start   1.0
      set cindex  0

      while {[set range [$win._t tag nextrange _mcursor $start]] ne ""} {
        set startPos [lindex $range 0]
        lassign [lindex $contents $cindex] str tags
        set endPos     [$win index {*}$endSpec -startpos $startPos]
        lappend dstrs [$win._t get $startPos $endPos]
        lappend istrs $str
        comments_chars_deleted $win $startPos $endPos do_tags
        set t [handleReplaceDeleteAt0 $win $startPos $endPos]
        $win._t replace $startPos $endPos $str [list {*}$tags lmargin rmargin [getLangTag $win $startPos]]
        set new_endpos [$win._t index "$startPos+[string length $str]c"]
        set start      [$win._t index $new_endpos+1c]
        incr cindex
        handleReplaceInsert $win $startPos $endPos $t
        lappend uranges $startPos $endPos $new_endpos
        lappend rranges $startPos $new_endpos
      }

      undo_replacelist $win $uranges $dstrs $istrs $cursor
      comments_do_tag $win $rranges do_tags

      if {$opts(-highlight)} {

        # Highlight text and bracket auditing
        switch [highlightAll $win $rranges 1 $do_tags] {
          2       { checkAllBrackets $win }
          1       { checkAllBrackets $win [$win._t get $startPos $endPos] }
          default { checkAllBrackets $win [string cat {*}$dstrs {*}$istrs] }
        }

        # Handle the indentation
        foreach {epos spos} [lreverse $ranges] str [lreverse $istrs] {
          if {[string index $str end] eq "\n"} {
            indent_newline $win $epos
          } else {
            indent_check_indent $win $epos
          }
        }

      }

      modified $win 1 [list replace $rranges $opts(-moddata)]
      event generate $win.t <<CursorChanged>>

    }

  }

  ######################################################################
  # Handles a paste operation.  If the -post option is set to "\b", the
  # clipboard will remove the last character.
  proc command_paste {win args} {

    variable data

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -pre  ""
      -post ""
      -num  1
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    lassign [lrange $args $i end] insertpos

    if {$insertpos eq ""} {
      set insertpos "insert"
    }

    # Get the contents of the clipboard
    set clip [clipboard get]

    # If we need to remove the last character, do that now
    if {[string index $opts(-post) 0] eq "\b"} {
      set opts(-post) [string range $opts(-post) 1 end]
      set clip [string range $clip 0 end-1]
    }

    # Formulate the text to paste
    set clip [string repeat "$opts(-pre)$clip$opts(-post)" $opts(-num)]

    if {[set cursors [llength [$win._t tag ranges _mcursor]]] > 0} {

      set lines [split [string trim $clip] \n]

      # If the number of mcursors match the number of lines, do a list insert
      if {$cursors == [llength $lines]} {
        command_insertlist $win {*}[array get opts] $lines
      } else {
        command_insert $win {*}[array get opts] $insertpos $clip
      }

    } else {

      # Insert the clipboard contents at the given insertion cursor
      command_insert $win {*}[array get opts] $insertpos $clip

      # Add the multicursors if we copied the multicursors
      if {[info exists data($win,copy_value)] && ($data($win,copy_value) eq $clip)} {
        foreach offset $data($win,copy_offsets) {
          $win._t tag add _mcursor "$insertpos+${offset}c"
        }
      }

    }

  }

  ######################################################################
  # Supports the text peer names command, making sure that the returned
  # name does not contain any hidden path information.
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
  # This command helps process any syntax highlighting functionality of
  # this widget.
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
      classes     { return [getHighlightClasses $win {*}$args] }
      metaclasses { return $data($win,config,meta_classes) }
      clear       {
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
        set ranges [lrange $args $i end]
        highlightAll $win [lrange $args $i end] $opts(-insert) $opts(-dotags)
        modified $win $opts(-modified) [list highlight $ranges $opts(-moddata)]
      }
      configure { return [$win._t tag configure __[lindex $args 0] {*}[lrange $args 1 end]] }
      cget      { return [$win._t tag cget      __[lindex $args 0] {*}[lrange $args 1 end]] }
      default   {
        return -code error [format "%s ($subcmd)" [msgcat::mc "Unknown ctext syntax subcommand"]]
      }
    }

  }

  #####################################################################
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

  ######################################################################
  # Toggles the case of each character in the passed string.
  proc transform_toggle_case {str} {

    set newstr ""

    foreach char [split $str {}] {
      append newstr [expr {[string is lower $char] ? [string toupper $char] : [string tolower $char]}]
    }

    return $newstr

  }

  ######################################################################
  # Converts the case to title case.
  proc transform_title_case {str} {

    set start 0
    while {[regexp -indices -start $start -- {\w+} $str word]} {
      lassign $word s e
      set str   [string replace $str $s $e [string totitle [string range $str $s $e]]]
      set start [expr $e + 1]
    }

    return $str

  }

  ######################################################################
  # Converts the given string to lower case.
  proc transform_lower_case {str} {

    return [string tolower $str]

  }

  ######################################################################
  # Converts the given string to upper case.
  proc transform_upper_case {str} {

    return [string toupper $str]

  }

  ######################################################################
  # Converts the text to rot13.
  proc transform_rot13 {str} {

    variable rot13_map

    return [string map $rot13_map $str]

  }

  ######################################################################
  # Performs a text transformation on the given text range.
  proc command_transform {win args} {

    variable data

    set i 0
    while {[string index [lindex $args $i] 0] eq "-"} { incr i 2 }

    array set opts {
      -moddata   {}
      -highlight 1
      -mcursor   1
    }
    array set opts [lrange $args 0 [expr $i - 1]]

    lassign [lrange $args $i end] startspec endspec cmd tags

    set uranges [list]
    set rranges [list]
    set do_tags [list]
    set cursor  [$win._t index insert]

    lassign [get_delete_replace_info $win $opts(-mcursor) $cursor $startspec $endspec] startspec endspec set_mcursor delranges

    foreach {endpos startpos} [lreverse $delranges] {
      set startpos [$win index {*}$startspec -startpos $startpos]
      set endpos   [$win index {*}$endspec   -startpos $startpos]
      set old_str  [$win._t get $startpos $endpos]
      set new_str  [transform_$cmd $old_str]
      lappend dstrs $old_str
      lappend istrs $new_str
      comments_chars_deleted $win $startpos $endpos do_tags
      set t [handleReplaceDeleteAt0 $win $startpos $endpos]
      $win._t replace $startpos $endpos $new_str [list {*}$tags rmargin lmargin [getLangTag $win $startpos]]
      set new_endpos [$win._t index "$startpos+[string length $new_str]c"]
      handleReplaceInsert $win $startpos $endpos $t
      lappend uranges $startpos $endpos $new_endpos
      lappend rranges $startpos $new_endpos
    }

    undo_replacelist $win $uranges $dstrs $istrs $cursor
    comments_do_tag $win $rranges do_tags

    if {$opts(-highlight)} {
      switch [highlightAll $win $rranges 1 $do_tags] {
        2       { checkAllBrackets $win }
        1       { checkAllBrackets $win [$win._t get $startpos $endpos] }
        default { checkAllBrackets $win [string cat {*}$dstrs {*}$istrs] }
      }
    }

    modified $win 1 [list transform $rranges $opts(-moddata)]
    event generate $win.t <<CursorChanged>>

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
      canundo  -
      undoable {
        return [expr [llength $data($win,undo,undobuf)] > 0]
      }
      canredo  -
      redoable {
        return [expr [llength $data($win,undo,redobuf)] > 0]
      }
      separator {
        undo_add_separator $win
      }
      undocount {
        return [expr [llength $data($win,undo,undobuf)] + [info exists data($win,undo,uncommitted)]]
      }
      reset {
        unset -nocomplain data($win,undo,uncommitted)
        set data($win,undo,undobuf)    [list]
        set data($win,undo,redobuf)    [list]
        set data($win,config,modified) false
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
    if {!$data($win,config,-blockcursor) && [$win._t compare insert != "insert linestart"]} {
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

    lassign [$win._t tag prevrange __$stype $index] first last

    if {$last eq ""} {
      return ""
    } elseif {[$win compare $last < $index]} {
      return [$win._t index "$last-1c"]
    } else {
      return [$win._t index "$index-1c"]
    }

  }

  ######################################################################
  # Returns the index of the bracket type after the given index.
  proc getNextBracket {win stype {index insert}} {

    lassign [$win tag prevrange __$stype "$index+1c"] first last

    if {($last ne "") && [$win compare "$index+1c" < $last]} {
      return [$win._t index "$index+1c"]
    } else {
      lassign [$win._t tag nextrange __$stype "$index+1c"] first last
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

    if {[set pos [getMatchBracket $win $type [$win._t index $pos]]] ne ""} {
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

  proc getLangTag {win index} {

    set lang [getLang $win $index]

    return [expr {($lang eq "") ? "" : "$lang"}]

  }

  proc clearCommentStringPatterns {win} {

    variable data

    array unset data $win,config,csl_patterns,*
    array unset data $win,config,csl_char_tags,*
    array unset data $win,config,lc_char_tags,*

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

    $win tag configure $lang
    $win tag lower     $lang _invisible
    $win tag configure __Lang=$lang -background $theme(embedded)
    $win tag lower     __Lang=$lang _invisible

    lappend data($win,config,csl_char_tags,) __LangStart:$lang __LangEnd:$lang
    lappend data($win,config,csl_array)      __LangStart:${lang}0 1 __LangStart:${lang}1 1 __LangEnd:${lang}0 1 __LangEnd:${lang}1 1 $lang 1
    lappend data($win,config,csl_markers)    __LangStart:${lang}0 __LangStart:${lang}1 __LangEnd:${lang}0 __LangEnd:${lang}1
    lappend data($win,config,csl_tag_pair)   __LangStart:$lang __Lang=$lang

  }

  proc highlightAll {win ranges ins {do_tag ""}} {

    variable data
    variable range_cache

    array set csl_array $data($win,config,csl_array)

    set lineranges [list]
    foreach {start end} $ranges {
      lappend lineranges [$win._t index "$start linestart"] [$win._t index "$end lineend"]
    }

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

  proc comments_do_tag {win ranges pdo_tags} {

    upvar $pdo_tags do_tags

    if {$do_tags eq ""} {
      foreach {start end} $ranges {
        if {[inLineComment $win $start] && ([string first \n [$win get $start $end]] != -1)} {
          lappend do_tags "stuff" 1
          break
        }
      }
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
        set lranges [$win._t tag ranges "$lang"]
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
                set lineend [$win._t index "$char_start lineend"]
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
                lappend tags($curr_lang) $curr_lang_start $char_end
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
          lappend tags($curr_lang) $curr_lang_start end
        }

        # Delete old tags
        if {$lang eq ""} {
          foreach l $data($win,config,langs) {
            catch { $win._t tag remove $l $langstart $langend }
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
      foreach {start end} [$win._t tag ranges $lang] {
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
  # Updates the visibility of the characters marked as meta.
  proc updateMetaChars {win} {

    variable data

    set value $data($win,config,-hidemeta)

    foreach tag $data($win,config,meta_classes) {
      $win._t tag configure __$tag -elide $value
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
      -meta      0
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

    if {$opts(-meta)} {
      lappend data($win,config,meta_classes) $class
      $win._t tag configure __$class -elide $data($win,config,-hidemeta)
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

    array unset data $win,highlight,regexp,class,*,__$class,*
    foreach key [array names data $win,highlight,regexps,*] {
      foreach index [lreverse [lsearch -all $data($key) *regexp,class,*,__$class,*]] {
        set data($key) [lreplace $data($key) $index $index]
      }
    }

    foreach type [list wkeyword wcharstart] {
      foreach key [array names data $win,highlight,$type,class,*] {
        if {[string match $data($key) __$class]} {
          unset data($key)
        }
      }
    }

    if {[set index [lsearch $data($win,config,meta_classes) $class]] != -1} {
      set data($win,config,meta_classes) [lreplace $data($win,config,meta_classes) $index $index]
    }

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

    # If the linemap is not markable or the linemap command is in progress, ignore
    # further attempts to toggle the mark.
    if {!$data($win,config,-linemap_markable) || $data($win,config,linemap_cmd_ip)} {
      return
    }

    set tline [lindex [split [set tmarkChar [$win.t index @0,$y]] .] 0]

    # If the line is empty, we can't mark the line so just return now
    if {[$win._t compare "$tline.0 linestart" == "$tline.0 lineend"]} {
      return
    }

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

    # Indicate that the linemap command is in progress
    set data($win,config,linemap_cmd_ip) 1

    # Call the mark command, if one exists.  If it returns a value of 0, remove
    # the mark.
    set cmd $data($win,config,-linemap_mark_command)
    if {[string length $cmd] && ![uplevel #0 [linsert $cmd end $win $type $lmark]]} {
      $win.t tag delete $lmark
      linemapUpdate $win 1
    }

    # Indicate that the linemap command is no longer in progress
    set data($win,config,linemap_cmd_ip) 0

  }

  proc linemapSetMark {win line} {

    variable data

    if {[$win._t compare "$line.0 linestart" != "$line.0 lineend"] && [lsearch -inline -glob [$win.t tag names $line.0] lmark*] eq ""} {
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

    # If this window no longer exists, exist immediately
    if {![winExists $win]} return

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

  ######################################################################
  #                          CURSOR HANDLING                           #
  ######################################################################

  ######################################################################
  # Set the current mode to multicursor move mode.
  proc update_cursor {win} {

    variable data

    if {([$win._t tag ranges _mcursor] eq "") || ($data($win,config,-multimove) == 0)} {

      # Make the insertion cursor come back
      $win._t configure -blockcursor $data($win,config,-blockcursor) \
                        -insertwidth $data($win,config,-insertwidth)

      # Set the insertion background
      if {$data($win,config,-blockcursor)} {
        $win._t configure -insertbackground $data($win,config,-blockbackground)
      } else {
        $win._t configure -insertbackground $data($win,config,-insertbackground)
      }

      # Remove the background color
      $win._t tag configure _mcursor -background ""

    } else {

      # Effectively make the insertion cursor disappear
      $win._t configure -blockcursor 0 -insertwidth 0

      # Make the multicursors look like the normal cursor
      $win._t tag configure _mcursor -background $data($win,config,-blockbackground)

    }

  }

  ######################################################################
  # Returns true if the given text editor is currently in "block cursor"
  # mode.
  proc is_block_cursor {win} {

    return [expr {[$win._t cget -blockcursor] || ([$win._t tag ranges _mcursor] ne "")}]

  }

  ######################################################################
  # Sets the insertion cursor location.
  proc set_cursor {win index args} {

    # Grab the original insertion point
    set ins [$win._t index insert]

    # If the past insertion point was a dspace and not an mcursor, clear it
    set tags [$win._t tag names $ins]
    if {([lsearch $tags _dspace] != -1) && ([lsearch $tags _mcursor] == -1)} {
      $win._t delete $ins
    }

    # Clear the selection
    $win._t tag remove sel 1.0 end

    # Set the new insertion point
    $win._t mark set insert $index
    $win._t see $index

    # If we are in block cursor mode, make sure the insertion cursor doesn't look stupid
    if {![is_block_cursor $win]} {
      return
    }

    if {[$win._t compare "$index linestart" == "$index lineend"]} {
      $win._t insert $index " " _dspace
      $win._t mark set insert $index

    # If our cursor is going to fall of the end of the line, move it back by one character
    } elseif {[$win._t compare $index == "$index lineend"]} {
      $win._t mark set insert "$index-1 display chars"
    }

    # Make sure that the linemap is updated appropriately
    linemapUpdate $win

    # Let the world know of the cursor change
    event generate $win.t <<CursorChanged>> -data [list $ins {*}$args]

  }

  ######################################################################
  # Sets a single multicursor indicator at the given index, adjusting
  # cursor as necessary so that it looks correct.
  proc set_mcursor {win index {prev_index ""}} {

    # If the current line contains nothing, add a dummy space so the
    # mcursor doesn't look dumb.
    if {[$win._t compare "$index linestart" == "$index lineend"]} {
      $win._t insert $index " " [list _dspace _mcursor]

    # Make sure that lineend is never the insertion point
    } elseif {[$win._t compare $index == "$index lineend"]} {
      $win._t tag add _mcursor "$index-1 display chars"

    # Otherwise, just tag the given index
    } else {
      $win._t tag add _mcursor $index
    }

    # If the new cursor is going off screen and it was previously in view,
    # make it viewable
    if {($prev_index ne "") && ([$win._t bbox $prev_index] ne "") && ([$win._t bbox $index] eq "")} {
      $win._t see $index
    }

  }

  ######################################################################
  # Clears a single mcursor from the editing buffer, deleting any dspace
  # characters.
  proc clear_mcursor {win index} {

    variable data

    # If the index lands on a dspace that is not the block insertion cursor, delete
    # the index.
    if {([lsearch [$win._t tag names $index] _dspace] != -1) && \
        (!$data($win,config,-blockcursor) || [$win._t compare $index != insert])} {
      $win._t delete $index

    # Otherwise, just remove the mcursor indicator
    } else {
      $win._t tag remove _mcursor $index
    }

  }

  ######################################################################
  # Clears all of the mcursors in the editing buffer.
  proc clear_mcursors {win} {

    foreach {startpos endpos} [$win._t tag ranges _mcursor] {
      clear_mcursor $win $startpos
    }

  }

  ######################################################################
  # Adjust the insertion marker so that it never is allowed to sit on
  # the lineend spot.
  proc adjust_cursors {win} {

    variable mode

    # If we are not running in block cursor mode, don't continue
    if {![is_block_cursor $win]} {
      return
    }

    # Remove any existing dspace characters
    remove_dspace $win

    # If the current line contains nothing, add a dummy space so that the
    # block cursor doesn't look dumb.
    if {[$win._t compare "insert linestart" == "insert lineend"]} {
      $win._t insert insert " " _dspace
      $win._t mark set insert "insert-1c"

    # Make sure that lineend is never the insertion point
    } elseif {[$win._t compare insert == "insert lineend"]} {
      $win._t mark set insert "insert-1 display chars"
    }

  }

  ######################################################################
  # Removes dspace characters.
  proc remove_dspace {win} {

    set mcursors [lmap {startpos endpos} [$win._t tag ranges _mcursor] {list $startpos $endpos}]

    foreach {startpos endpos} [$win._t tag ranges _dspace] {
      if {[lsearch -index 0 $mcursors $startpos] == -1} {
        $win._t delete $startpos $endpos
      }
    }

  }

  ######################################################################
  # Removes the dspace tag from the current index (if it is set).
  proc cleanup_dspace {win} {

    $win._t tag remove _dspace insert

  }

  ######################################################################
  # Returns the contents of the given text widget without the injected
  # dspaces.
  proc get_cleaned_content {win startpos endpos opts} {

    set str      ""
    set startpos [$win index {*}$startpos]
    set endpos   [$win index {*}$endpos]

    # Remove any dspace characters
    while {[set epos [lassign [$win._t tag nextrange _dspace $startpos $endpos] spos]] ne ""} {
      append str [$win._t get {*}$opts $startpos $spos]
      set startpos $epos
      if {$startpos eq $endpos} {
        return "$str\n"
      }
    }

    append str [$win._t get {*}$opts $startpos $endpos]

    return $str

  }

  ######################################################################
  # INDICES TRANSFORMATIONS                                            #
  ######################################################################

  ######################################################################
  # Returns the starting cursor position without modification.
  proc getindex_cursor {win startpos optlist} {

    return $startpos

  }

  ######################################################################
  # Transforms a left index specification into a text index.
  proc getindex_left {win startpos optlist} {

    array set opts {
      -num 1
    }
    array set opts $optlist

    if {[$win._t compare "$startpos display linestart" > "$startpos-$opts(-num) display chars"]} {
      return "$startpos display linestart"
    } else {
      return "$startpos-$opts(-num) display chars"
    }

  }

  ######################################################################
  # Transforms a right index specification into a text index.
  proc getindex_right {win startpos optlist} {

    array set opts {
      -num      1
      -allowend 0
    }
    array set opts $optlist

    if {[lsearch [$win._t tag names $startpos] _dspace] != -1} {
      return $startpos
    } elseif {[$win._t compare "$startpos display lineend" < "$startpos+$opts(-num) display chars"] && !$opts(-allowend)} {
      return "$startpos display lineend"
    } else {
      return "$startpos+$opts(-num) display chars"
    }

  }

  ######################################################################
  # Transforms an up index specification into a text index.
  proc getindex_up {win startpos optlist} {

    array set opts {
      -num    1
      -column ""
    }
    array set opts $optlist

    # If the user has specified a column variable, store the current column in that variable
    if {$opts(-column) ne ""} {
      if {[set col [set $opts(-column)]] eq ""} {
        set $opts(-column) [set col [lindex [split $startpos .] 1]]
      }
    } else {
      set col [lindex [split $startpos .] 1]
    }

    set index $startpos

    for {set i 0} {$i < $opts(-num)} {incr i} {
      set index [$win._t index "$index linestart-1 display lines"]
    }

    return [lindex [split $index .] 0].$col

  }

  ######################################################################
  # Transforms a down index specification into a text index.
  proc getindex_down {win startpos optlist} {

    array set opts {
      -num    1
      -column ""
    }
    array set opts $optlist

    if {$opts(-column) ne ""} {
      if {[set col [set $opts(-column)]] eq ""} {
        set $opts(-column) [set col [lindex [split $startpos .] 1]]
      }
    } else {
      set col [lindex [split $startpos .] 1]
    }

    set index $startpos

    for {set i 0} {$i < $opts(-num)} {incr i} {
      if {[$win._t compare [set index [$win._t index "$index lineend+1 display lines"]] == end]} {
        set index [$win._t index "end-1c"]
        break
      }
    }

    return [lindex [split $index .] 0].$col

  }

  ######################################################################
  # Transforms a first character specification into a text index.
  proc getindex_first {win startpos optlist} {

    if {[$win._t get -displaychars 1.0] eq ""} {
      return "1.0+1 display chars"
    } else {
      return "1.0"
    }

  }

  ######################################################################
  # Transforms a last character specification into a text index.
  proc getindex_last {win startpos optlist} {

    return "end"

  }

  ######################################################################
  # Transforms a character specification into a text index.
  proc getindex_char {win startpos optlist} {

    array set opts {
      -num 1
      -dir "next"
    }
    array set opts $optlist

    set num $opts(-num)

    if {$opts(-dir) eq "next"} {

      while {($num > 0) && [$win._t compare $startpos < end-2c]} {
        if {[set line_chars [$win._t count -displaychars $startpos "$startpos lineend"]] == 0} {
          set startpos [$win._t index "$startpos+1 display lines"]
          set startpos "$startpos linestart"
          incr num -1
        } elseif {$line_chars <= $num} {
          set startpos [$win._t index "$startpos+1 display lines"]
          set startpos "$startpos linestart"
          incr num -$line_chars
        } else {
          set startpos "$startpos+$num display chars"
          set num 0
        }
      }

      return $startpos

    } else {

      set first 1
      while {($num > 0) && [$win._t compare $startpos > 1.0]} {
        if {([set line_chars [$win._t count -displaychars "$startpos linestart" $startpos]] == 0) && !$first} {
          if {[incr num -1] > 0} {
            set startpos [$win._t index "$startpos-1 display lines"]
            set startpos "$startpos lineend"
          }
        } elseif {$line_chars < $num} {
          set startpos [$win._t index "$startpos-1 display lines"]
          set startpos "$startpos lineend"
          incr num -$line_chars
        } else {
          set startpos "$startpos-$num display chars"
          set num 0
        }
        set first 0
      }

      return $startpos

    }

  }

  ######################################################################
  # Transforms a displayed character specification into a text index.
  proc getindex_dchar {win startpos optlist} {

    array set opts {
      -num 1
      -dir "next"
    }
    array set opts $optlist

    if {$opts(-dir) eq "next"} {
      return "$startpos+$opts(-num) display chars"
    } else {
      return "$startpos-$opts(-num) display chars"
    }

  }

  ######################################################################
  # Transforms an appendable character specification into a text index.
  proc getindex_achar {win startpos optlist} {

    variable data

    array set opts {
      -num 1
      -dir "next"
    }
    array set opts $optlist

    lassign [split $startpos .] lnum col

    if {$opts(-dir) eq "next"} {
      set col   [expr $col + $opts(-num)]
      lassign [split [$win._t index "$startpos lineend"] .] last_lnum last_col
      if {$col >= $last_col} {
        set wspace [string repeat " " [expr $col - $last_col]]
        if {$wspace ne ""} {
          $win insert -mcursor 0 -highlight 0 "$startpos lineend" $wspace
        }
        if {$data($win,config,-blockcursor)} {
          $win._t insert "$startpos lineend" " " _dspace
        }
      }
      return $lnum.$col
    } else {
      set col   [expr $col - $opts(-num)]
      return [expr {($col < 0) ? $lnum.0 : $lnum.$col}]
    }

  }

  ######################################################################
  # Transforms a findchar specification to a text index.
  # Options:
  #   -num       int        Chooses the index of the num'th found character.
  #   -dir       next/prev  Specifies the direction to search for from the startpos position.
  #   -char      char       Specifies the character to find.
  #   -exclusive bool       If true, returns the found index position + 1 character closer to the startpos;
  #                         otherwise, returns the index of the found character.
  # If no matching character can be found, returns the index of the insertion character.
  # Searching is limited to the current line only.
  proc getindex_findchar {win startpos optlist} {

    array set opts {
      -num       1
      -dir       "next"
      -char      ""
      -exclusive 0
    }
    array set opts $optlist

    # Perform the character search
    if {$opts(-dir) eq "next"} {
      set indices [$win._t search -all -- $opts(-char) "$startpos+1c" "$startpos lineend"]
      if {[set index [lindex $indices [expr $opts(-num) - 1]]] eq ""} {
        return "insert"
      } elseif {$opts(-exclusive)} {
        return "$index-1c"
      }
    } else {
      set indices [$win._t search -all -- $opts(-char) "$startpos linestart" insert]
      if {[set index [lindex $indices end-[expr $opts(-num) - 1]]] eq ""} {
        return "insert"
      } elseif {$opts(-exclusive)} {
        return "$index+1c"
      }
    }

    return $index

  }

  ######################################################################
  # Returns the index of the matching character; otherwise, if one
  # is not found, returns -1.
  proc find_match_char {win char dir startpos} {

    set last_found ""

    if {[$win is escaped $startpos]} {
      return -1
    }

    if {$dir eq "-forwards"} {
      set startpos [$win._t index "$startpos+1c"]
      set endpos   "end"
    } else {
      set endpos   "1.0"
    }

    while {1} {

      if {[set found [$win._t search $dir $char $startpos $endpos]] eq ""} {
        return -1
      }

      set last_found $found
      set startpos   [expr {($dir eq "-backwards") ? $found : [$win._t index "$found+1c"]}]

      if {[$win is escaped $last_found]} {
        continue
      }

      return $last_found

    }

  }

  ######################################################################
  # TBD
  proc getindex_betweenchar {win startpos optlist} {

    array set opts {
      -char ""
      -dir  "next"
    }
    array set opts $optlist

    array set pairs {
      \{ {\\\} L}
      \} {\\\{ R}
      \( {\\\) L}
      \) {\\\( R}
      \[ {\\\] L}
      \] {\\\[ R}
      <  {> L}
      >  {< R}
    }

    # Get the matching character
    if {[info exists pairs($char)]} {
      if {[lindex $pairs($char) 1] eq "R"} {
        if {$dir eq "prev"} {
          set index [gui::find_match_pair $win._t [lindex $pairs($char) 0] \\$char -backwards]
        } else {
          set index [gui::find_match_pair $win._t \\$char [lindex $pairs($char) 0] -forwards]
        }
      } else {
        if {$dir eq "prev"} {
          set index [gui::find_match_pair $win._t \\$char [lindex $pairs($char) 0] -backwards]
        } else {
          set index [gui::find_match_pair $win._t [lindex $pairs($char) 0] \\$char -forwards]
        }
      }
    } else {
      if {$dir eq "prev"} {
        set index [find_match_char $win $char -backwards $startpos]
      } else {
        set index [find_match_char $win $char -forwards  $startpos]
      }
    }

    if {$index == -1} {
      return [expr {($dir eq "prev") ? 1.0 : "end-1c"}]
    } else {
      return [expr {($dir eq "prev") ? "$index+1c" : $index}]
    }

  }

  ######################################################################
  # Transforms the firstchar specification into a text index.
  proc getindex_firstchar {win startpos optlist} {

    array set opts {
      -num 0
    }
    array set opts $optlist

    if {[$win._t compare [set index [$win._t index "$startpos+$opts(-num) display lines"]] == end]} {
      set index [$win._t index "$index-1 display lines"]
    }

    if {[lsearch [$win._t tag names "$index linestart"] __prewhite] != -1} {
      return [lindex [$win._t tag nextrange __prewhite "$index linestart"] 1]-1c
    } else {
      return "$index lineend"
    }

  }

  ######################################################################
  # Transforms the lastchar specification into a text index.
  proc getindex_lastchar {win startpos optlist} {

    array set opts {
      -num 0
    }
    array set opts $optlist

    if {[$win._t compare [set index [$win._t index "$startpos+$opts(-num) display lines"]] == end]} {
      set index [$win._t index "$index-1 display lines"]
    }

    return "[lindex [split $line .] 0].0+[string length [string trimright [$win._t get $line.0 $line.end]]]c"

  }

  ######################################################################
  # Transforms a wordstart specification into a text index.
  proc getindex_wordstart {win startpos optlist} {

    array set opts {
      -num       1
      -dir       "next"
      -exclusive 0
    }
    array set opts $optlist

    set start $startpos
    set num   $opts(-num)

    lassign [split $start .] curr_row curr_col

    if {$opts(-dir) eq "next"} {

      while {1} {

        set line [$win._t get -displaychars $curr_row.0 $curr_row.end]

        while {1} {
          set char [string index $line $curr_col]
          if {[set isword [string is wordchar $char]] && [regexp -indices -start $curr_col -- {\W} $line index]} {
            set curr_col [lindex $index 1]
          } elseif {[set isspace [string is space $char]] && [regexp -indices -start $curr_col -- {\S} $line index]} {
            set curr_col [lindex $index 1]
          } elseif {!$isword && !$isspace && [regexp -indices -start $curr_col -- {[\w\s]} $line index]} {
            set curr_col [lindex $index 1]
          } else {
            break
          }
          if {![string is space [string index $line $curr_col]] && ([incr num -1] == 0)} {
            return [$win._t index "$curr_row.0 + $curr_col display chars"]
          }
        }

        lassign [split [$win._t index "$curr_row.end + 1 display chars"] .] curr_row curr_col

        if {![$win._t compare $curr_row.$curr_col < end]} {
          return [$win._t index "end-1 display chars"]
        } elseif {(![string is space [$win._t index $curr_row.$curr_col]] || [$win._t compare $curr_row.0 == $curr_row.end]) && ([incr num -1] == 0)} {
          return [$win._t index "$curr_row.0 + $curr_col display chars"]
        }

      }

    } else {

      while {1} {

        set line [$win._t get -displaychars $curr_row.0 $curr_row.$curr_col]

        while {1} {
          if {[regexp -indices -- {(\w+|\s+|[^\w\s]+)$} [string range $line 0 [expr $curr_col - 1]] index]} {
            set curr_col [lindex $index 0]
          } else {
            break
          }
          if {![string is space [string index $line $curr_col]] && ([incr num -1] == 0)} {
            return [$win._t index "$curr_row.0 + $curr_col display chars"]
          }
        }

        lassign [split [$win._t index "$curr_row.0 - 1 display chars"] .] curr_row curr_col

        if {![$win._t compare $curr_row.$curr_col > 1.0]} {
          return "1.0"
        } elseif {(![string is space [string index $line $curr_col]] || ($curr_col == 0)) && ([incr num -1] == 0)} {
          return [$win._t index "$curr_row.0 + $curr_col display chars"]
        }

      }

    }

  }

  ######################################################################
  # Transforms a wordend specification into a text index.
  proc getindex_wordend {win startpos optlist} {

    array set opts {
      -num       1
      -dir       "next"
      -exclusive 0
    }
    array set opts $optlist

    set start $startpos
    set num   $opts(-num)

    lassign [split $start .] curr_row curr_col

    if {$opts(-dir) eq "next"} {

      while {1} {

        set line [$win._t get -displaychars $curr_row.0 $curr_row.end]

        while {1} {
          if {[regexp -indices -start [expr $curr_col + 1] -- {(\w+|\s+|[^\w\s]+)} $line index]} {
            set curr_col [lindex $index 1]
          } else {
            break
          }
          if {![string is space [string index $line $curr_col]] && ([incr num -1] == 0)} {
            return [$win._t index "$curr_row.0 + $curr_col display chars"]
          }
        }

        lassign [split [$win._t index "$curr_row.end + 1 display chars"] .] curr_row curr_col

        if {![$win._t compare $curr_row.$curr_col < end]} {
          return [$win._t index "end-1 display chars"]
        }

      }

    } else {

      while {1} {

        set line [$win._t get -displaychars $curr_row.0 $curr_row.end]

        while {1} {
          set char [string index $line $curr_col]
          if {[set isword [string is wordchar $char]] && [regexp -indices -- {\W\w*$} [string range $line 0 $curr_col] index]} {
            set curr_col [lindex $index 0]
          } elseif {[set isspace [string is space $char]] && [regexp -indices -- {\S\s*$} [string range $line 0 $curr_col] index]} {
            set curr_col [lindex $index 0]
          } elseif {!$isword && !$isspace && [regexp -indices -- {[\w\s][^\w\s]*$} [string range $line 0 $curr_col] index]} {
            set curr_col [lindex $index 0]
          } else {
            break
          }
          if {![string is space [string index $line $curr_col]] && ([incr num -1] == 0)} {
            return [$win._t index "$curr_row.0 + $curr_col display chars"]
          }
        }

        lassign [split [$win._t index "$curr_row.0 - 1 display chars"] .] curr_row curr_col

        if {![$win._t compare $curr_row.$curr_col > 1.0]} {
          return "1.0"
        } elseif {![string is space [$win._t index $curr_row.$curr_col]] && ([incr num -1] == 0)} {
          return [$win._t index "$curr_row.0 + $curr_col display chars"]
        }

      }

    }

  }

  ######################################################################
  # Transforms a WORDstart specification into a text index.
  proc getindex_WORDstart {win startpos optlist} {

    array set opts {
      -num 1
      -dir "next"
    }
    array set opts $optlist

    set num $opts(-num)

    if {$opts(-dir) eq "next"} {
      set diropt "-forwards"
      set start  $startpos
      set endpos "end"
      set suffix "+1c"
    } else {
      set diropt "-backwards"
      set start  $startpos-1c
      set endpos "1.0"
      set suffix ""
    }

    while {[set index [$win._t search $diropt -regexp -- {\s\S|\n\n} $start $endpos]] ne ""} {
      if {[incr num -1] == 0} {
        return [$win._t index $index+1c]
      }
      set start "$index$suffix"
    }

    return $startpos


  }

  ######################################################################
  # Transforms a WORDend specification into a text index.
  proc getindex_WORDend {win startpos optlist} {

    array set opts {
      -num 1
      -dir "next"
    }
    array set opts $optlist

    set num $opts(-num)

    if {$opts(-dir) eq "next"} {
      set diropt "-forwards"
      set start  "$startpos+1c"
      set endpos "end"
      set suffix "+1c"
    } else {
      set diropt "-backwards"
      set start  $startpos
      set endpos "1.0"
      set suffix ""
    }

    while {[set index [$win._t search $diropt -regexp -- {\S\s|\n\n} $start $endpos]] ne ""} {
      if {[$win._t get $index] eq "\n"} {
        if {[incr num -1] == 0} {
          return [$win._t index $index+1c]
        }
      } else {
        if {[incr num -1] == 0} {
          return [$win._t index $index]
        }
      }
      set start "$index$suffix"
    }

    return $startpos

  }

  ######################################################################
  # Transforms a column specification into a text index.
  proc getindex_column {win startpos optlist} {

    array set opts {
      -num 1
    }
    array set opts $optlist

    return [lindex [split $startpos .] 0].[expr $opts(-num) - 1]

  }

  ######################################################################
  # Transforms a linenum specification into a text index.
  proc getindex_linenum {win startpos optlist} {

    array set opts {
      -num 1
    }
    array set opts $optlist

    return [$win index firstchar -num 0 -startpos $opts(-num).0]

  }

  ######################################################################
  # Transforms a linestart specification into a text index.
  proc getindex_linestart {win startpos optlist} {

    array set opts {
      -num 0
    }
    array set opts $optlist

    # set index [$win._t index "$startpos+$opts(-num) display lines linestart"]
    return [$win._t index "$startpos linestart +$opts(-num) display lines"]

  }

  ######################################################################
  # Transforms a lineend specification into a text index.
  proc getindex_lineend {win startpos optlist} {

    array set opts {
      -num 0
    }
    array set opts $optlist

    return [$win._t index "$startpos+$opts(-num) display lines lineend"]

  }

  ######################################################################
  # Transforms a dispstart specification into a text index.
  proc getindex_dispstart {win startpos optlist} {

    return "@0,[lindex [$win._t bbox $startpos] 1]"

  }

  ######################################################################
  # Transforms a dispmid specification into a text index.
  proc getindex_dispmid {win startpos optlist} {

    return "@[expr [winfo width $win] / 2],[lindex [$win._t bbox $startpos] 1]"

  }

  ######################################################################
  # Transforms a dispend specification into a text index.
  proc getindex_dispend {win startpos optlist} {

    return "@[winfo width $win],[lindex [$win._t bbox $startpos] 0]"

  }

  ######################################################################
  # Transforms a sentence specification into a text index.
  proc getindex_sentence {win startpos optlist} {

    array set opts {
      -num 1
      -dir "next"
    }
    array set opts $optlist

    # Search for the end of the previous sentence
    set pattern  {[.!?][]\)\"']*\s+\S}
    set index    [$win._t search -backwards -count lengths -regexp -- $pattern $startpos 1.0]
    set beginpos "1.0"
    set endpos   "end-1c"
    set num      $opts(-num)

    # If the startpos is within a comment block and the found index lies outside of that
    # block, set the sentence starting point on the first non-whitespace character within the
    # comment block.
    if {[set comment [ctext::commentCharRanges $win $startpos]] ne ""} {
      lassign [lrange $comment 1 2] beginpos endpos
      if {($index ne "") && [$win._t compare $index < [lindex $comment 1]]} {
        set index ""
      }

    # If the end of the found sentence is within a comment block, set the beginning position
    # to the end of that comment and clear the index.
    } elseif {($index ne "") && ([set comment [ctext::commentCharRanges $win $index]] ne "")} {
      set beginpos [lindex $comment end]
      set index    ""
    }

    if {$opts(-dir) eq "next"} {

      # non-whitespace character in the file and if it is after the startpos,
      # return the index.
      if {($index eq "") && ([set index [$win._t search -forwards -count lengths -regexp -- {\S} $beginpos $endpos]] ne "")} {
        if {[$win._t compare $index > $startpos] && ([incr num -1] == 0)} {
          return $index
        }
        set index ""
      }

      # If the insertion cursor is just before the beginning of the sentence.
      if {($index ne "") && [$win._t compare $startpos < "$index+[expr [lindex $lengths 0] - 1]c"]} {
        set startpos $index
      }

      while {[set index [$win._t search -forwards -count lengths -regexp -- $pattern $startpos $endpos]] ne ""} {
        set startpos [$win._t index "$index+[expr [lindex $lengths 0] - 1]c"]
        if {[incr num -1] == 0} {
          return $startpos
        }
      }

      return $endpos

    } else {

      # If the insertion cursor is between sentences, adjust the starting position
      if {($index ne "") && [$win._t compare $startpos <= "$index+[expr [lindex $lengths 0] - 1]c"]} {
        set startpos $index
      }

      while {[set index [$win._t search -backwards -count lengths -regexp -- $pattern $startpos-1c $beginpos]] ne ""} {
        set startpos $index
        if {[incr num -1] == 0} {
          return [$win._t index "$index+[expr [lindex $lengths 0] - 1]c"]
        }
      }

      if {([incr num -1] == 0) && \
          ([set index [$win._t search -forwards -regexp -- {\S} $beginpos $endpos]] ne "") && \
          ([$win._t compare $index < $startpos])} {
        return $index
      } else {
        return $beginpos
      }

    }

  }

  ######################################################################
  # Transforms a paragraph specification into a text index.
  proc getindex_paragraph {win startpos optlist} {

    array set opts {
      -num 1
      -dir "next"
    }
    array set opts $optlist

    set start $startpos
    set num   $opts(-num)

    if {$opts(-dir) eq "next"} {

      set nl 0
      while {[$win._t compare $start < end-1c]} {
        if {([$win._t get "$start linestart" "$start lineend"] eq "") || \
            ([lsearch [$win._t tag names $start] _dspace] != -1)} {
          set nl 1
        } elseif {$nl && ([incr num -1] == 0)} {
          return "$start linestart"
        } else {
          set nl 0
        }
        set start [$win._t index "$start+1 display lines"]
      }

      return [$win._t index end-1c]

    } else {

      set last_start "end"

      # If the start position is in the first column adjust the starting
      # line to the line above to avoid matching ourselves
      if {[$win._t compare $start == "$start linestart"]} {
        set last_start $start
        set start      [$win._t index "$start-1 display lines"]
      }

      set nl 1
      while {[$win._t compare $start < $last_start]} {
        if {([$win._t get "$start linestart" "$start lineend"] ne "") && \
            ([lsearch [$win._t tag names $start] _dspace] == -1)} {
          set nl 0
        } elseif {!$nl && ([incr num -1] == 0)} {
          return [$win._t index "$start+1 display lines linestart"]
        } else {
          set nl 1
        }
        set last_start $start
        set start      [$win._t index "$start-1 display lines"]
      }

      if {(([$win._t get "$start linestart" "$start lineend"] eq "") || \
           ([lsearch [$win._t tag names $start] _dspace] != -1)) && !$nl && \
          ([incr num -1] == 0)} {
        return [$win._t index "$start+1 display lines linestart"]
      } else {
        return 1.0
      }

    }

  }

  ######################################################################
  # Transforms a screentop specification into a text index.
  proc getindex_screentop {win startpos optlist} {

    return "@0,0"

  }

  ######################################################################
  # Transforms a screenmid specification into a text index.
  proc getindex_screenmid {win startpos optlist} {

    return "@0,[expr [winfo height $win] / 2]"

  }

  ######################################################################
  # Transforms a screenbot specification into a text index.
  proc getindex_screenbot {win startpos optlist} {

    return "@0,[winfo height $win]"

  }

  ######################################################################
  # Transforms a numberstart specification into a text index.
  proc getindex_numberstart {win startpos optlist} {

    set pattern {([0-9]+|0x[0-9a-fA-F]+|[0-9]+\.[0-9]*)$}

    if {[regexp $pattern [$win._t get "$startpos linestart" $startpos] match]} {
      return "$startpos-[string length $match]c"
    }

    return $startpos

  }

  ######################################################################
  # Transforms a numberend specification into a text index.
  proc getindex_numberend {win startpos optlist} {

    set pattern {^([0-9]+|0x[0-9a-fA-F]+|[0-9]*\.[0-9]+)}

    if {[regexp $pattern [$win._t get $startpos "$startpos lineend"] match]} {
      return "$startpos+[expr [string length $match] - 1]c"
    }

    return $startpos

  }

  ######################################################################
  # Transforms a spacestart specification into a text index.
  proc getindex_spacestart {win startpos optlist} {

    set pattern {[ \t]+$}

    if {[regexp $pattern [$win._t get "$startpos linestart" $startpos] match]} {
      return "$startpos-[string length $match]c"
    }

    return $startpos

  }

  ######################################################################
  # Transforms a spaceend specification into a text index.
  proc getindex_spaceend {win startpos optlist} {

    set pattern {^[ \t]+}

    if {[regexp $pattern [$win._t get $startpos "$startpos lineend"] match]} {
      set index "$startpos+[expr [string length $match] - 1]c"
    }

  }

  ######################################################################
  # Transforms a tagstart specification into a text index (i.e., <title>).
  # Options:
  #   -num       int       Specifies the number of tagstarts to search outwards from the starting position (must be 1 or more).
  #   -exclusive bool      If true provides the index of the last character of the tag; otherwise, returns the index of the
  #                        first character position.
  proc getindex_tagstart {win startpos optlist} {

    array set opts {
      -num       1
      -exclusive 0
    }
    array set opts $optlist

    set start $startpos
    set num   $opts(-num)

    while {[set ranges [get_node_range $win -startpos $start]] ne ""} {
      if {[incr num -1] == 0} {
        return [expr {$opts(-exclusive) ? [lindex $ranges 1] : [lindex $ranges 0]}]
      } else {
        set start [$win._t index "[lindex $ranges 0]-1c"]
      }
    }

  }

  ######################################################################
  # Transforms a tagend specification into a text index (i.e., </title>).
  #   -num       int       Specifies the number of tagstarts to search outwards from the starting position (must be 1 or more).
  #   -exclusive bool      If true provides the index of the last character of the tag; otherwise, returns the index of the
  #                        first character position.
  proc getindex_tagend {win startpos optlist} {

    array set opts {
      -num       1
      -exclusive 0
    }
    array set opts $optlist

    set start $startpos
    set num   $opts(-num)

    while {[set ranges [get_node_range $win -startpos $start]] ne ""} {
      if {[incr num -1] == 0} {
        return [expr {$opts(-exclusive) ? [lindex $ranges 2] : [lindex $ranges 3]}]
      } else {
        set start [$win._t index "[lindex $ranges 0]-1c"]
      }
    }

  }

  ######################################################################
  # Returns the next or previous starting position for selected text.
  proc getindex_selstart {win startpos optlist} {

    array set opts {
      -dir "prev"
    }
    array set opts $optlist

    if {$opts(-dir) eq "prev"} {
      set range [$win._t tag prevrange sel $startpos]
    } else {
      set range [$win._t tag nextrange sel $startpos]
    }

    return [lindex $range 0]

  }

  ######################################################################
  # Returns the next or previous starting position for selected text.
  proc getindex_selend {win startpos optlist} {

    array set opts {
      -dir "prev"
    }
    array set opts $optlist

    if {$opts(-dir) eq "prev"} {
      set range [$win._t tag prevrange sel $startpos]
    } else {
      set range [$win._t tag nextrange sel $startpos]
    }

    return [lindex $range 1]

  }

  ######################################################################
  # Returns the character range for the current node based on the given
  # outer type.
  proc get_node_range {win args} {

    variable data
    variable tag_other_map
    variable tag_dir_map
    variable tag_index_map

    array set opts {
      -startpos insert
    }
    array set opts $args

    # Check to see if the starting position is within a tag and if it is
    # not, find the tags surrounding the starting position.
    if {[set itag [inside_tag $win -startpos $opts(-startpos) -allow010 1]] eq ""} {
      return [get_node_range_within $win -startpos $opts(-startpos)]
    } elseif {[lindex $itag 3] eq "010"} {
      return ""
    }

    lassign $itag start end name type

    # If we are on a starting tag, look for the ending tag
    set retval [list $start $end]
    set others 0
    while {1} {
      if {[set retval [get_tag $win -dir $tag_dir_map($type) -name $name -type $tag_other_map($type) -start [lindex $retval $tag_index_map($type)]]] eq ""} {
        return ""
      }
      if {[incr others [llength [lsearch -all [lindex $retval 4] $name,$type]]] == 0} {
        switch $type {
          "100" { return [list $start $end {*}[lrange $retval 0 1]] }
          "001" { return [list {*}[lrange $retval 0 1] $start $end] }
          default { return -code error "Error finding node range" }
        }
      }
      incr others -1
    }

  }

  ######################################################################
  # If the insertion cursor is currently inside of a tag element, returns
  # the tag information; otherwise, returns the empty string
  proc inside_tag {win args} {

    array set opts {
      -startpos insert
      -allow010 0
    }
    array set opts $args

    set retval [get_tag $win -dir prev -start "$opts(-startpos)+1c"]

    if {($retval ne "") && [$win compare $opts(-startpos) < [lindex $retval 1]] && (([lindex $retval 3] ne "010") || $opts(-allow010))} {
      return $retval
    }

    return ""

  }

  ######################################################################
  # Assumes that the insertion cursor is somewhere between a start and end
  # tag.
  proc get_node_range_within {win args} {

    array set opts {
      -startpos insert
    }
    array set opts $args

    # Find the beginning tag that we are currently inside of
    set retval [list $opts(-startpos)]
    set count  0

    while {1} {
      if {[set retval [get_tag $win -dir prev -type 100 -start [lindex $retval 0]]] eq ""} {
        return ""
      }
      if {[incr count [expr [llength [lsearch -all [lindex $retval 4] *,100]] - [llength [lsearch -all [lindex $retval 4] *,001]]]] == 0} {
        set start_range [lrange $retval 0 1]
        set range_name  [lindex $retval 2]
        break
      }
      incr count
    }

    # Find the ending tag based on the beginning tag
    set retval [list {} $opts(-startpos)]
    set count 0

    while {1} {
      if {[set retval [get_tag $win -dir next -type 001 -name $range_name -start [lindex $retval 1]]] eq ""} {
        return ""
      }
      if {[incr count [llength [lsearch -all [lindex $retval 4] $range_name,100]]] == 0} {
        return [list {*}$start_range {*}[lrange $retval 0 1]]
      }
      incr count -1
    }

  }

  ######################################################################
  # Gets the tag that begins before the current insertion cursor.  The
  # value of -dir must be "next or "prev".  The value of -type must be
  # "100" (start), "001" (end), "010" (both) or "*" (any).  The value of
  # name is the tag name to search for (if specified).
  #
  # Returns a list of 6 elements if a tag was found that matches:
  #  - starting tag position
  #  - ending tag position
  #  - tag name
  #  - type of tag found (10=start, 01=end or 11=both)
  #  - number of starting tags encountered that did not match
  #  - number of ending tags encountered that did not match
  proc get_tag {win args} {

    array set opts {
      -dir   "next"
      -type  "*"
      -name  "*"
      -start "insert"
    }
    array set opts $args

    # Initialize counts
    set missed [list]

    # Get the tag
    if {$opts(-dir) eq "prev"} {
      if {[set start [lindex [$win syntax prevrange angledL $opts(-start)] 0]] eq ""} {
        return ""
      } elseif {[set end [lindex [$win syntax nextrange angledR $start] 1]] eq ""} {
        return ""
      }
    } else {
      if {[set end [lindex [$win syntax nextrange angledR $opts(-start)] 1]] eq ""} {
        return ""
      } elseif {[set start [lindex [$win syntax prevrange angledL $end] 0]] eq ""} {
        return ""
      }
    }

    while {1} {

      # Get the tag elements
      if {[$win get "$start+1c"] eq "/"} {
        set found_type "001"
        set found_name [regexp -inline -- {[a-zA-Z0-9_:-]+} [$win get "$start+2c" "$end-1c"]]
      } else {
        if {[$win get "$end-2c"] eq "/"} {
          set found_type "010"
          set found_name [regexp -inline -- {[a-zA-Z0-9_:-]+} [$win get "$start+1c" "$end-2c"]]
        } else {
          set found_type "100"
          set found_name [regexp -inline -- {[a-zA-Z0-9_:-]+} [$win get "$start+1c" "$end-1c"]]
        }
      }

      # If we have found what we are looking for, return now
      if {[string match $opts(-type) $found_type] && [string match $opts(-name) $found_name]} {
        return [list $start $end $found_name $found_type $missed]
      }

      # Update counts
      lappend missed "$found_name,$found_type"

      # Otherwise, get the next tag
      if {$opts(-dir) eq "prev"} {
        if {[set end [lindex [$win syntax prevrange angledR $start] 1]] eq ""} {
          return ""
        } elseif {[set start [lindex [$win syntax prevrange angledL $end] 0]] eq ""} {
          return ""
        }
      } else {
        if {[set start [lindex [$win syntax nextrange angledL $end] 0]] eq ""} {
          return ""
        } elseif {[set end [lindex [$win syntax nextrange angledR $start] 1]] eq ""} {
          return ""
        }
      }

    }

  }

  ######################################################################
  # Returns the outer range of the given node range value as a list.
  proc get_outer {node_range} {

    if {$node_range ne ""} {
      return [list [lindex $node_range 0] [lindex $node_range 3]]
    }

    return ""

  }

  ######################################################################
  # Returns the inner range of the given node range value as a list.
  proc get_inner {node_range} {

    if {$node_range ne ""} {
      return [lrange $node_range 1 2]
    }

    return ""

  }

  ######################################################################
  # INDENTATION                                                        #
  ######################################################################
  
  ######################################################################
  # Returns true if the reindent symbol is not the first in the parent statement.
  proc indent_check_reindent_for_unindent {win index} {

    if {[set spos [lindex [$win tag prevrange __reindentStart $index] 0]] ne ""} {

      # If the starting reindent is also an indent, return 1
      if {[lsearch [$win._t tag names $spos] __indent*] != -1} {
        return 2
      }

      # Get the starting position of the previous reindent string
      set rpos [lindex [$win tag prevrange __reindent $index] 0]

      if {($rpos ne "") && [$win._t compare $rpos > $spos]} {

        # Find the indent symbol that is just before the reindentStart symbol
        while {([lassign [$win tag prevrange __indent $index] ipos] ne "") && [$win._t compare $ipos > $spos]} {
          set index $ipos
        }

        return [$win._t compare $index < $rpos]

      }

    }

    return 0

  }

  ######################################################################
  # Checks the given text prior to the insertion marker to see if it
  # matches the unindent expressions.  Increment/decrement
  # accordingly.
  proc indent_check_indent {win index} {

    variable data

    # If the auto-indent feature was disabled, we are in vim start mode, or
    # the current language doesn't have an indent expression, quit now
    if {$data($win,config,-indentmode) ne "IND+"} {
      return $index
    }

    # If the current line contains an unindent expression, is not within a comment or string,
    # and is preceded in the line by only whitespace, replace the whitespace with the proper
    # indentation whitespace.
    if {([set endpos [lassign [$win tag prevrange __unindent $index] startpos]] ne "") && \
        [$win._t compare $endpos >= $index]} {

      if {[string trim [set space [$win._t get "$index linestart" $startpos]]] eq ""} {

        # Find the matching indentation index
        if {[set tindex [indent_get_match_indent $win $startpos]] ne ""} {
          set indent_space [indent_get_start_of_line $win $tindex]
        } else {
          set indent_space [indent_get_start_of_line $win $index]
        }

        # Replace the whitespace with the appropriate amount of indentation space
        if {$indent_space ne $space} {
          $win replace -highlight 0 -mcursor 0 "$index linestart" $startpos $indent_space
          set offset [expr [lindex [split $index .] 1] + ([string length $indent_space] - [lindex [split $startpos .] 1])]
          return [$win._t index "$index linestart+${offset}c"]
        }

      }

    } elseif {(([set endpos [lassign [$win tag prevrange __reindent $index] startpos]] ne "") && \
                [$win._t compare $endpos == $index]) && \
              [set type [indent_check_reindent_for_unindent $win $startpos]]} {

      if {[string trim [set space [$win._t get "$index linestart" $startpos]]] eq ""} {

        if {$type == 1} {

          # Get the starting whitespace of the previous line
          set indent_space [indent_get_start_of_line $win [$win._t index "$index-1l lineend"]]

          # Check to see if the previous line contained a reindent
          if {[$win._t compare "$index-1l linestart" > [lindex [$win tag prevrange __reindent "$index linestart"] 0]]} {
            set indent_space [string range $indent_space $data($win,config,-shiftwidth) end]
          }

        } else {

          # Set the indentation space to the same as the reindentStart line
          set indent_space [indent_get_start_of_line $win [lindex [$win tag prevrange __reindentStart $index] 0]]

        }

        # Replace the whitespace with the appropriate amount of indentation space
        if {$indent_space ne $space} {
          $win replace -highlight 0 -mcursor 0 "$index linestart" $startpos $indent_space
          set offset [expr [lindex [split $index .] 1] + ([string length $indent_space] - [lindex [split $startpos .] 1])]
          return [$win._t index "$index linestart+${offset}c"]
        }

      }

    }

    return $index

  }

  ######################################################################
  # Returns 1 if the given line contains an indentation.
  proc indent_line_contains_indentation {win index} {

    # Ignore whitespace
    if {[lsearch [$win._t tag names "$index linestart"] __prewhite] == -1} {
      if {[set range [$win._t tag prevrange __prewhite "$index lineend"]] ne ""} {
        set index [$win._t index "[lindex $range 1] lineend"]
      } else {
        set index 1.0
      }
    }

    # Check to see if the current line contains an indentation symbol towards the end of the line
    if {[lassign [$win tag prevrange __indent $index "$index linestart"] ipos] ne ""} {
      return [expr {([lassign [$win tag prevrange __unindent $index] upos] eq "") || [$win._t compare $ipos > $upos]}]
    }

    # Returns true if we have a reindent symbol in the current line
    return [expr {[lassign [$win tag prevrange __reindent $index "$index linestart"] ipos] ne ""}]

  }

  ######################################################################
  # Get the matching indentation marker.
  proc indent_get_match_indent {win index} {

    set count 1

    lassign [$win tag prevrange __indent   $index] sfirst slast
    lassign [$win tag prevrange __unindent $index] ofirst olast

    if {($olast ne "") && [$win._t compare $olast >= $index]} {
      set olast $index
    }

    while {($ofirst ne "") && ($sfirst ne "")} {
      if {[$win._t compare $sfirst > $ofirst]} {
        if {[incr count -1] == 0} {
          return $sfirst
        }
        lassign [$win tag prevrange __indent $sfirst] sfirst slast
      } else {
        incr count
        lassign [$win tag prevrange __unindent $ofirst] ofirst olast
      }
    }

    while {$sfirst ne ""} {
      if {[incr count -1] == 0} {
        return $sfirst
      }
      lassign [$win tag prevrange __indent $sfirst] sfirst slast
    }

    return ""

  }

  ######################################################################
  # Returns the whitespace found at the beginning of the specified logical
  # line.
  proc indent_get_start_of_line {win index} {

    # Ignore whitespace
    if {[lsearch [$win._t tag names "$index linestart"] __prewhite] == -1} {
      if {[set range [$win._t tag prevrange __prewhite "$index lineend"]] ne ""} {
        set index [$win._t index "[lindex $range 1] lineend"]
      } else {
        set index 1.0
      }
    }

    # Find an ending bracket on the current line
    set win_type       "none"
    set startpos(none) "$index linestart"
    foreach type [list curlyR parenR squareR angledR] {
      if {([lassign [$win._t tag prevrange __$type $index] startpos($type)] ne "") && \
          [$win._t compare $startpos($type) >= "$index linestart"] && \
          [$win._t compare $startpos($type) >= $startpos($win_type)]} {
        set win_type $type
      }
    }

    # If we could not find a right bracket, we have found the line that we are looking for
    if {$win_type eq "none"} {
      if {[lsearch [$win._t tag names "$index linestart"] __prewhite] != -1} {
        return [string range [$win._t get {*}[$win._t tag nextrange __prewhite "$index linestart"]] 0 end-1]
      } else {
        return ""
      }

    # Otherwise, jump the insertion cursor to the line containing the matching bracket and
    # do the search again.
    } else {
      array set other_type [list curlyR curlyL parenR parenL squareR squareL angledR angledL]
      if {[set match_index [getMatchBracket $win $other_type($win_type) $startpos($win_type)]] ne ""} {
        return [indent_get_start_of_line $win $match_index]
      } elseif {[lsearch [$win._t tag names "$index linestart"] __prewhite] != -1} {
        return [string range [$win._t get {*}[$win._t tag nextrange __prewhite "$index linestart"]] 0 end-1]
      } else {
        return ""
      }
    }

  }

  ######################################################################
  # Handles a newline character.  Returns the character position of the
  # first line of non-space text.
  proc indent_newline {win index} {

    variable data

    # If the auto-indent feature was disabled, we are in vim start mode,
    # or the current language doesn't have an indent expression, quit now
    if {$data($win,config,-indentmode) eq "OFF"} {
      if {$data($win,config,-autoseparators)} {
        undo_add_separator $win
      }
      return $index
    }

    # If we do not need smart indentation, use the previous space
    if {$data($win,config,-indentmode) eq "IND"} {

      set indent_space [indent_get_previous_indent_space $win $index]

    # Otherwise, do smart indentation
    } else {

      # Get the current indentation level
      set indent_space [indent_get_start_of_line $win [$win._t index "$index-1l lineend"]]

      # If the previous line indicates an indentation is required,
      if {[indent_line_contains_indentation $win "$index-1l lineend"]} {
        append indent_space [string repeat " " $data($win,config,-shiftwidth)]
      }

    }

    # Create an index to restore the insertion cursor, if necessary
    set restore_insert ""

    # Remove any leading whitespace and update indentation level
    # (if the first non-whitespace char is a closing bracket)
    if {[lsearch [$win._t tag names "$index linestart"] __prewhite] != -1} {

      lassign [$win._t tag nextrange __prewhite "$index linestart"] startpos endpos

      # If the first non-whitespace characters match an unindent pattern,
      # lessen the indentation by one
      if {[lsearch [$win._t tag names "$endpos-1c"] __unindent*] != -1} {
        $win insert -highlight 0 -update 0 insert "$indent_space\n"
        set startpos [$win._t index $startpos+1l]
        set endpos   [$win._t index $endpos+1l]
        set restore_insert [$win._t index insert-1c]
        if {$data($win,config,-indentmode) eq "IND+"} {
          set indent_space [string range $indent_space $data($win,config,-shiftwidth) end]
        }

      # Otherwise, if the first non-whitepace characters match a reindent pattern, lessen the
      # indentation by one
      } elseif {([lsearch [$win._t tag names "$endpos-1c"] __reindent*] != -1) && [indent_check_reindent_for_unindent $win [lindex [$win tag prevrange __reindent $endpos] 0]]} {
        if {$data($win,config,-indentmode) eq "IND+"} {
          set indent_space [string range $indent_space $data($win,config,-shiftwidth) end]
        }
      }

      # See if we are deleting a multicursor
      set mcursor [lsearch [$win._t tag names $index] "mcursor"]

      # Delete the whitespace
      $win delete -highlight 0 -mcursor 0 $startpos "$endpos-1c"

      # If the newline was from a multicursor, we need to re-add the tag since we have deleted it
      if {$mcursor != -1} {
        $win._t tag add mcursor $index
      }

    }

    # Insert leading whitespace to match current indentation level
    if {$indent_space ne ""} {
      $win insert -highlight 0 -mcursor 0 "$index linestart" $indent_space
    }

    # If we need to restore the insertion cursor, do it now
    if {$restore_insert ne ""} {
      ::tk::TextSetCursor $win $restore_insert
    }

    # If autoseparators are called for, add it now
    if {$data($win,config,-autoseparators)} {
      undo_add_separator $win
    }

    return [$win._t index "$index+[string length $indent_space]c"]

  }

  ######################################################################
  # Handles the backspace key.  If we are
  proc indent_backspace {win index} {

    variable data

    # If the auto-indent feature was disabled, we are in vim start mode, or
    # the current language doesn't have an indent expression, quit now
    if {$data($win,config,-indentmode) eq "OFF"} {
      return $index
    }

    # Figure out the leading space
    set space ""
    if {[set endpos [lassign [$win._t tag prevrange __prewhite $index "$index linestart"] startpos]] ne ""} {
      if {[$win._t compare $endpos == "$index+1c"]} {
        set space [$win._t get $startpos $index]
      } else {
        return $index
      }
    } else {
      set space [$win._t get "$index linestart" "$index lineend"]
    }

    # If the leading whitespace only consists of spaces, attempt to delete to the previous tab
    if {([string map {{ } {}} $space] eq "")} {

      # Calculate the new indentation
      set shiftwidth   $data($win,config,-shiftwidth)
      set tab_count    [expr [string length $space] / $shiftwidth]
      set indent_space [string repeat " " [expr $tab_count * $shiftwidth]]

      # Replace the whitespace with the appropriate amount of indentation space
      if {$indent_space ne $space} {
        $win replace -highlight 0 -mcursor 0 "$index linestart" $index $indent_space
        set offset [string length $indent_space]
        return [$win._t index "$index linestart+${offset}c"]
      }

    }

    return $index

  }

  ######################################################################
  # Returns the whitespace of the previous (non-empty) line of text.
  proc indent_get_previous_indent_space {win index} {

    variable data

    if {($data($win,config,-indentmode) eq "OFF") || ([lindex [split $index .] 0] == 1)} {
      return 0
    }

    if {[set range [$win._t tag prevrange __prewhite "$index-1l lineend"]] ne ""} {
      return [string range [$win._t get {*}$range] 0 end-1]
    } else {
      return ""
    }

  }

  ######################################################################
  # This procedure counts the number of tags in the given range.
  proc indent_get_tag_count {win tag start end} {

    variable data

    # Initialize the indent_level
    set count 0

    # Count all tags that are not within comments or are escaped
    while {[set range [$win._t tag nextrange __$tag $start $end]] ne ""} {
      incr count
      set start [lindex $range 1]
    }

    return $count

  }

  ######################################################################
  # Indents the given text lines one shiftwidth to the right (indent).
  proc indent_shift_right {win startpos endpos mcursor pranges pundo_append} {

    upvar $pranges      ranges
    upvar $pundo_append undo_append

    variable data

    # Get the indent spacing
    set shiftwidth $data($win,config,-shiftwidth)
    set indent_str [string repeat " " $shiftwidth]
    set startpos   [$win._t index "$startpos linestart"]
    set endpos     [$win._t index "$endpos linestart"]
    set cursor     [$win._t index insert]

    while {[$win._t compare $startpos <= $endpos]} {
      $win._t insert $startpos $indent_str [list lmargin rmargin __prewhite [getLangTag $win $startpos]]
      set epos [$win._t index "$startpos+${shiftwidth}c"]
      handleInsertAt0 $win $startpos $epos
      undo_add_change $win [list i $startpos $epos $indent_str $cursor $mcursor] $undo_append
      set undo_append 1
      lappend ranges $startpos $epos
      set startpos    [$win._t index "$startpos linestart+1l"]
    }

  }

  ######################################################################
  # Indents the given text lines one shiftwidth to the left (unindent).
  proc indent_shift_left {win startpos endpos mcursor pranges pundo_append} {

    upvar $pranges      ranges
    upvar $pundo_append undo_append

    variable data

    # Get the indent spacing
    set shiftwidth   $data($win,config,-shiftwidth)
    set unindent_str [string repeat " " $shiftwidth]
    set lastchar     [expr $shiftwidth - 1]
    set startpos     [$win._t index "$startpos linestart"]
    set endpos       [$win._t index "$endpos linestart"]
    set cursor       [$win._t index insert]

    while {[$win._t compare $startpos <= $endpos]} {
      set epos [$win._t index "$startpos+${shiftwidth}c"]
      if {[$win._t get $startpos $epos] eq $unindent_str} {
        handleDeleteAt0      $win $startpos $epos
        linemapCheckOnDelete $win $startpos $epos
        $win._t delete "$startpos linestart" $epos
        undo_add_change $win [list d $startpos $epos $unindent_str $cursor $mcursor] $undo_append
        lappend ranges $startpos $epos
        set undo_append 1
      }
      set startpos [$win._t index "$startpos linestart+1l"]
    }

  }

  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc indent_shift_auto {win startpos endpos mcursor pranges pundo_append} {

    upvar $pranges      ranges
    upvar $pundo_append undo_append

    variable data

    # If we are the first line containing non-whitespace, preserve the indentation
    if {([$win._t tag prevrange __prewhite "$startpos linestart"] eq "") || \
        ([string trim [$win._t get "$startpos linestart" $startpos]] ne "")} {
      set curpos [$win._t index "$startpos+1l linestart"]
    } else {
      set curpos [$win._t index "$startpos linestart"]
    }

    set endpos       [$win._t index $endpos]
    set indent_space ""
    set shiftwidth   $data($win,config,-shiftwidth)
    set cursor       [$win._t index insert]

    while {[$win._t compare $curpos < $endpos]} {

      if {$curpos ne "1.0"} {

        # If the current line contains an unindent expression, is not within a comment or string,
        # and is preceded in the line by only whitespace, replace the whitespace with the proper
        # indentation whitespace.
        if {[set epos [lassign [$win tag nextrange __unindent $curpos "$curpos lineend"] spos]] ne ""} {
          if {[set tindex [indent_get_match_indent $win $spos]] ne ""} {
            if {[$win._t compare "$tindex linestart" == "$spos linestart"]} {
              set indent_space [indent_get_start_of_line $win "$tindex-1l lineend"]
              if {[indent_line_contains_indentation $win "$tindex-1l lineend"]} {
                append indent_space [string repeat " " $shiftwidth]
              }
            } else {
              set indent_space [indent_get_start_of_line $win $tindex]
            }
          } else {
            set indent_space [indent_get_start_of_line $win $epos]
          }

        } elseif {([set epos [lassign [$win tag nextrange __reindent $curpos "$curpos lineend"] spos]] ne "") && [indent_check_reindent_for_unindent $win $spos]} {
          set indent_space [indent_get_start_of_line $win [$win._t index "$curpos-1l lineend"]]
          if {[string trim [$win._t get "$curpos linestart" $spos]] eq ""} {
            if {[$win._t compare "$curpos-1l linestart" > [lindex [$win tag prevrange __reindent "$curpos linestart"] 1]]} {
              set indent_space [string range $indent_space $shiftwidth end]
            }
          }

        } else {
          set indent_space [indent_get_start_of_line $win [$win._t index "$curpos-1l lineend"]]
          if {[indent_line_contains_indentation $win "$curpos-1l lineend"]} {
            append indent_space [string repeat " " $shiftwidth]
          }
        }

      }

      # Remove any leading whitespace and update indentation level
      # (if the first non-whitespace char is a closing bracket)
      set whitespace ""
      if {[lsearch [$win._t tag names $curpos] __prewhite] != -1} {
        set whitespace [string range [$win._t get {*}[$win._t tag nextrange __prewhite $curpos]] 0 end-1]
      }

      # Replace the leading whitespace with the calculated amount of indentation space
      if {$whitespace ne $indent_space} {
        set epos [$win._t index "$curpos+[string length $whitespace]c"]
        set t [handleReplaceDeleteAt0 $win $curpos $epos]
        $win._t replace $curpos $epos $indent_space [list lmargin rmargin __prewhite [getLangTag $win $curpos]]
        handleReplaceInsert $win $curpos $epos $t
        undo_add_change $win [list d $curpos $epos $whitespace $cursor $mcursor] $undo_append
        undo_add_change $win [list i $curpos [$win._t index "$curpos+[string length $indent_space]c"] $indent_space $cursor $mcursor] 1
        set undo_append 1
      }

      # Adjust the startpos
      set curpos [$win._t index "$curpos+1l linestart"]

    }

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

