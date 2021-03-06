###########################################################################
#
# This script contains the APave class, sort of wrapper around the grid
# geometry manager.
#
# Use:
#    package require apave
#    ...
#    apave::APave create pave
#    catch {destroy .win}
#    pave makeWindow .win "TITLE"
#    pave window .win LISTW
#    pave showModal .win OPTIONS
#
# where:
#    TITLE - title of window
#    LISTW - list of widgets and their options
#    OPTIONS - geometry and other options of paved window
#
# LISTW's entries have the following structure:
#   {NAME NEIGHBOR POSN RSPAN CSPAN OPTGRID OPTWIDG}
#
# where:
#   NAME     - name of current widget that can begin with letters
#              defining the type of widget (see getWidgetType below)
#   NEIGHBOR - name of neighboring widget
#   POSN     - position of neighboring widget: T or L (top or left)
#   RSPAN    - rowspan of current widget
#   CSPAN    - columnspan of current widget
#   OPTGRID  - options of grid command
#   OPTWIDG  - options of widget's command
# If NAME begins with others letters than listed in getWidgetType below,
# the NAME widget should be created before calling "pave window" command.
#
# For example,
#   {ch2 ch1 T 1 5 {-st w} {-t "Match case" -var t::c2}}
# means the widget's options:
#   ch2 - name of current widget (checkbox)
#   ch1 - name of neighboring widget (checkbox)
#   T   - position of neighboring widget is TOP
#   1   - rowspan of current widget
#   5   - columnspan of current widget
#   {-st w} - option "-sticky" of grid command
#   {-t ...} - option "-text" of widget's (checkbox's) command
#
# See tests/test*.tcl files for the detailed examples of use.
#
###########################################################################

######################################################################
# for debugging
# proc d {args} {tk_messageBox -title "INFO" -icon info -message "$args"}

package require Tk
package require tablelist
package require widget::calendar
catch {package require tooltip} ;# optional (though necessary everywhere:)

namespace eval apave {

  variable apaveDir [file dirname [info script]]
  variable _AP_ICO { none "info" err warn ques no retry folder \
    OpenFile SaveFile font color font date help home undo redo run tools \
    "file" find search view edit config misc cut copy paste plus minus \
    add change delete double replace up down "exit" ok yes cancel }
  variable _AP_IMG
  array set _AP_IMG {}

  # Get a defined icon's image or list of icons
  proc iconImage {{icon ""}} {
    variable _AP_ICO
    if {$icon eq ""} {return $_AP_ICO}
    proc imagename {icon} {   # Get a defined icon's image name
      return _AP_IMG(img$icon)
    }
    variable apaveDir
    variable _AP_IMG
    if {[array size _AP_IMG] == 0} {
      # Make images of icons
      source [file join $apaveDir apaveimg.tcl]
      foreach ic $_AP_ICO {
        image create photo [imagename $ic] -data [set _AP_IMG($ic)]
      }
    }
    if {$icon ni $_AP_ICO} { set icon [lindex $_AP_ICO 0] }
    return [imagename $icon]
  }

  # Set application's icon
  proc setAppIcon {win {winicon ""}} {
    set appIcon ""
    if {$winicon ne ""} {
      if {[catch {set appIcon [image create photo -file $winicon]}]} {
        catch { set appIcon [image create photo -data $winicon] }
      }
    }
    if {$appIcon ne ""} { wm iconphoto $win $appIcon }
    return
  }

  # Initialize wish session
  proc initWM {} {
    if {$::tcl_platform(platform) == "windows"} {
      wm attributes . -alpha 0.0
    } else {
      wm withdraw .
    }
    try {ttk::style theme use clam}
    # configure separate widget types
    ttk::style configure TButton \
      -anchor center -width -8 -relief raised -borderwidth 1 -padding 1
    ttk::style configure TLabel -borderwidth 0 -padding 1
    return
  }
}

source [file join $apave::apaveDir obbit.tcl]

oo::class create apave::APave {

  mixin apave::ObjectProperty apave::ObjectTheming apave::ObjectUtils

  variable _pav

  constructor {args} {

    # keep the 'important' data of Pave object in array
    array set _pav {}
    set _pav(ns) [namespace current]::
    set _pav(moveall) 0
    set _pav(tonemoves) 1
    set _pav(initialcolor) black
    set _pav(clnddate) ""
    set _pav(modalwin) "."
    set _pav(fgbut) [ttk::style lookup TButton -foreground]
    set _pav(bgbut) [ttk::style lookup TButton -background]
    set _pav(fgtxt) [ttk::style lookup TEntry -foreground]
    set _pav(prepost) {}
    set _pav(widgetopts) {}
    set _pav(edge) "/@"
    if {$_pav(fgtxt)=="black" || $_pav(fgtxt)=="#000000"} {
      set _pav(bgtxt) white
    } else {
      set _pav(bgtxt) [ttk::style lookup TEntry -background]
    }
    # namespace in object namespace for safety of its 'most important' data
    namespace eval ${_pav(ns)}PN {}
    array set ${_pav(ns)}PN::AR {}

    # This trick with 'proc' inside an object is discussed at
    # https://stackoverflow.com/questions/54804964/proc-in-tcl-ooclass
    #
    # See also: https://wiki.tcl-lang.org/page/listbox+selection

    proc ListboxSelect {W} {

      selection clear -displayof $W
      selection own -command {} $W
      selection handle -type UTF8_STRING \
        $W [list [namespace current]::ListboxHandle $W]
      selection handle \
        $W [list [namespace current]::ListboxHandle $W]
      return
    }

    proc ListboxHandle {W offset maxChars} {

      set list {}
      foreach index [$W curselection] { lappend list [$W get $index] }
      set text [join $list \n]
      return [string range $text $offset [expr {$offset+$maxChars-1}]]
    }

    proc WinResize {win} {

      # restrict the window's sizes (fixing Tk's issue with a menubar)
      if {[lindex [$win configure -menu] 4] ne ""} {
        lassign [split [wm geometry $win] x+] w y
        lassign [wm minsize $win] wmin ymin
        if {$w<$wmin && $y<$ymin} {
          set corrgeom ${wmin}x${ymin}
        } elseif {$w<$wmin} {
          set corrgeom ${wmin}x${y}
        } elseif {$y<$ymin} {
          set corrgeom ${w}x${ymin}
        } else {
          return
        }
        wm geometry $win $corrgeom
      }
      return
    }

    if {[llength [self next]]} { next {*}$args }
    return
  }

  #########################################################################
  #
  # Check the platform

  method iswindows {} {

    return [expr {$::tcl_platform(platform) == "windows"} ? 1: 0]
  }

  #########################################################################
  #
  # Configure the apave object (all of _pav array may be changed)
  # E.g., pobj configure edge "@@"

  method configure {args} {

    foreach {optnam optval} $args { set _pav($optnam) $optval }
    return
  }

  #########################################################################
  #
  # Get the coordinates of centered window (against its parent)

  method CenteredXY {rw rh rx ry w h} {

    set x [expr {max(0, $rx + ($rw - $w) / 2)}]
    set y [expr {max(0,$ry + ($rh - $h) / 2)}]
    # check for left/right edge of screen (accounting decors)
    set scrw [expr [winfo screenwidth .] - 12]
    set scrh [expr {[winfo screenheight .] - 36}]
    if {($x + $w) > $scrw } {
      set x [expr {$scrw - $w}]
    }
    if {($y + $h) > $scrh } {
      set y [expr {$scrh - $h}]
    }
    return +$x+$y
  }

  #########################################################################
  #
  # Get root name of widget's name

  method rootwname {name} {

    return [lindex [split $name .] end]
  }

  #########################################################################
  #
  # Theme for non-ttk widgets (to be redefined in descendants/mixins)

  method NonTtkTheme {win} {

    return
  }

  #########################################################################
  #
  # Style for non-ttk widgets (to be redefined in descendants/mixins)

  method NonTtkStyle {typ {dsbl 0}} {

    return ""
  }

  #########################################################################
  #
  # Get icon attributes for buttons, menus etc.

  method IconA {icon} {

    return "-image [apave::iconImage $icon] -compound left"
  }

  #########################################################################
  #
  # Some options may be cut down, so we must expand them

  method ExpandOptions {options} {

    set options [string map {
      " -st "   " -sticky "
      " -com "  " -command "
      " -t "    " -text "
      " -w "    " -width "
      " -h "    " -height "
      " -var "  " -variable "
      " -tvar " " -textvariable "
      " -lvar " " -listvariable "
    } " $options"]
    return $options
  }

  #########################################################################
  #
  # Fill the non-standard attributes of file content widget.
  #
  # wnamefull is a widget name
  # attrs is a list of all attributes
  #
  # $varopt option means a variable option (e.g. tvar, lvar)
  # -inpval option means an initial value of the field
  # -retpos option has p1:p2 format (e.g. 0:10) to cut a substring
  #         from returned value

  method FCfieldAttrs {wnamefull attrs varopt} {

    lassign [my parseOptionsFile 0 $attrs \
      $varopt "" -retpos "" -inpval ""] tmp
    lassign $tmp - vn - rp - iv
    if {[string first "-state disabled" $attrs]<0} {
      if {$varopt eq "-lvar"} {
        lappend _pav(widgetopts) "-lbxname $wnamefull $vn"
        set iv [my getOption -values {*}$attrs]
        set attrs [my RemoveSomeOptions $attrs -values]
      }
      if {$rp ne ""} {
        lappend _pav(widgetopts) "-retpos $wnamefull $vn $rp"
      }
    }
    if {$iv ne ""} { set $vn $iv }
    return [my RemoveSomeOptions $attrs -retpos -inpval]
  }

  #########################################################################
  #
  # Fill the file content widget's values

  method FCfieldValues {wnamefull attrs} {

    proc readFCO {fname} {

      # Reads a file's content.
      # Returns a list of (non-empty) lines of the file.
      if {$fname eq ""} {
        set retval {{}}
      } else {
        set retval {}
        foreach ln [split [my readTextFile $fname "" 1] \n] {
          if {$ln ne {}} {lappend retval $ln}
        }
      }
      return $retval
    }

    proc contFCO {fline opts edge args} {

      # Given a file's line and options,
      # cuts a substring from the line.
      lassign [my parseOptionsFile 1 $opts {*}$args] opts
      lassign $opts - - - div1 - div2 - pos - len - ret
      set ldv1 [string length $div1]
      set ldv2 [string length $div2]
      set i1 [expr {[string first $div1 $fline]+$ldv1}]
      set i2 [expr {[string first $div2 $fline]-1}]
      if {$ldv1 && $ldv2} {
        if {$i1<0 || $i2<0} {return $edge}
        set retval [string range $fline $i1 $i2]
      } elseif {$ldv1} {
        if {$i1<0} {return $edge}
        set retval [string range $fline $i1 end]
      } elseif {$ldv2} {
        if {$i2<0} {return $edge}
        set retval [string range $fline 0 $i2]
      } elseif {$pos ne {} && $len ne {}} {
        set retval [string range $fline $pos $pos+[incr len -1]]
      } elseif {$pos ne {}} {
        set retval [string range $fline $pos end]
      } elseif {$len ne {}} {
        set retval [string range $fline 0 $len-1]
      } else {
        set retval $fline
      }
      return [list $retval $ret]
    }

    set edge $_pav(edge)
    set ldv1 [string length $edge]
    set filecontents {}
    set optionlists {}
    set tplvalues ""
    set retpos ""
    set values [my getOption -values {*}$attrs]
    if {[string first $edge $values]<0} { ;# if 1 file, edge
      set values "$edge$values$edge"      ;# may be omitted
    }
    # get: files' contents, files' options, template line
    set lopts "-list {} -div1 {} -div2 {} -pos {} -len {} -ret 0"
    while {1} {
      set i1 [string first $edge $values]
      set i2 [string first $edge $values $i1+1]
      if {$i1>=0 && $i2>=0} {
        incr i1 $ldv1
        append tplvalues [string range $values 0 $i1-1]
        set fdata [string range $values $i1 $i2-1]
        lassign [my parseOptionsFile 1 $fdata {*}$lopts] fopts fname
        lappend filecontents [readFCO $fname]
        lappend optionlists $fopts
        set values [string range $values $i2+$ldv1 end]
      } else {
        append tplvalues $values
        break
      }
    }
    # fill the combobox lines, using files' contents and options
    if {[set leno [llength $optionlists]]} {
      set newvalues ""
      set ilin 0
      lassign $filecontents firstFCO
      foreach fline $firstFCO { ;# lines of first file for a base
        set line ""
        set tplline $tplvalues
        for {set io 0} {$io<$leno} {incr io} {
          set opts [lindex $optionlists $io]
          if {$ilin==0} {  ;# 1st cycle: add items from -list option
            lassign $opts - list1  ;# -list option goes first
            if {[llength $list1]} {
              foreach l1 $list1 {append newvalues "\{$l1\} "}
              lappend _pav(widgetopts) "-list $wnamefull [list $list1]"
            }
          }
          set i1 [string first $edge $tplline]
          if {$i1>=0} {
            lassign [contFCO $fline $opts $edge {*}$lopts] retline ret
            if {$ret ne "0" && $retline ne $edge && \
            [string first $edge $line]<0} {
              set p1 [expr {[string length $line]+$i1}]
              if {$io<($leno-1)} {
                set p2 [expr {$p1+[string length $retline]-1}]
              } else {
                set p2 end
              }
              set retpos "-retpos $p1:$p2"
            }
            append line [string range $tplline 0 $i1-1] $retline
            set tplline [string range $tplline $i1+$ldv1 end]
          } else {
            break
          }
          set fline [lindex [lindex $filecontents $io+1] $ilin]
        }
        if {[string first $edge $line]<0} {
          # put only valid lines into the list of values
          append newvalues "\{$line$tplline\} "
        }
        incr ilin
      }
      # replace old 'values' attribute with the new 'values'
      lassign [my parseOptionsFile 2 $attrs -values \
        [string trimright $newvalues]] attrs
    }
    return "$attrs $retpos"
  }

  #########################################################################
  #
  # Append selection attributes for listboxes
  #
  # See also:
  #   1. https://wiki.tcl-lang.org/page/listbox+selection
  #   2. https://stackoverflow.com, the question:
  #        the-tablelist-curselection-goes-at-calling-the-directory-dialog

  method ListboxesAttrs {w attrs} {

    if {"-exportselection" ni $attrs} {
      append attrs " -ListboxSel $w -selectmode extended -exportselection 0"
    }
    return $attrs
  }

  #########################################################################
  #
  # Get the button's icon based on its text and name (e.g. butOK)

  method AddButtonIcon {w attrsName} {

    upvar 1 $attrsName attrs
    set txt [my getOption -t {*}$attrs]
    if {$txt eq ""} { set txt [my getOption -text {*}$attrs] }
    set im ""
    set icolist [list {exit abort} {exit close} \
      {SaveFile save} {OpenFile open}]
    # ok, yes, cancel, apply buttons should be at the end of list
    # as their texts can be renamed (e.g. "Help" in e_menu's "About")
    lappend icolist {*}[apave::iconImage] {yes apply}
    foreach icon $icolist {
      lassign $icon ic1 ic2
      # text of button is of highest priority at defining its icon
      if {[string match -nocase $ic1 $txt] || \
          [string match -nocase but$ic1 $w] || \
          ($ic2 ne "" && ( \
          [string match -nocase but$ic2 $w] || \
          [string match -nocase $ic2 $txt]))} {
        append attrs " [my IconA $ic1]"
        break
      }
    }
    return
  }

  #########################################################################
  #
  # Get the widget type based on 2 initial letters of its name

  method GetWidgetType {wnamefull options attrs} {

    set disabled 0
    catch {
      array set a [list {*}$attrs]
      set disabled [expr {$a(-state)=="disabled"}]
    }
    set pack $options
    set name [my rootwname $wnamefull]
    set nam3 [string tolower [string index $name 0]][string range $name 1 2]
    switch -glob -- $nam3 {
      "but" {
        set widget "ttk::button"
        my AddButtonIcon $name attrs
      }
      "buT" {
        set widget "button"
        my AddButtonIcon $name attrs
        }
      "can" {set widget "canvas"}
      "chb" {set widget "ttk::checkbutton"}
      "chB" {set widget "checkbutton"}
      "cbx" - "fco" {
        set widget "ttk::combobox"
        if {$nam3 eq "fco"} {  ;# file content combobox
          set attrs [my FCfieldValues $wnamefull $attrs]
        }
        set attrs [my FCfieldAttrs $wnamefull $attrs -tvar]
      }
      "ent" {set widget "ttk::entry"}
      "enT" {set widget "entry"}
      "fil" -
      "fis" -
      "dir" -
      "fon" -
      "clr" -
      "dat" -
      "sta" -
      "too" -
      "fra" {
        # + frame for choosers (of file, directory, color, font, date)
        # and bars
        set widget "ttk::frame"
      }
      "ftx" {set widget "ttk::labelframe"}
      "frA" {
        set widget "frame"
        if {$disabled} {set attrs [my RemoveSomeOptions $attrs -state]}
      }
      "lab" {set widget "ttk::label"; set options "-st w $options"}
      "laB" {set widget "label";      set options "-st w $options"}
      "lfr" {set widget "ttk::labelframe"}
      "lfR" {
        set widget "labelframe"
        if {$disabled} {set attrs [my RemoveSomeOptions $attrs -state]}
        set attrs "-relief ridge -fg maroon $attrs"
      }
      "lbx" - "flb" {
        set widget "listbox"
        if {$nam3 eq "flb"} {  ;# file content listbox
          set attrs [my FCfieldValues $wnamefull $attrs]
        }
        set attrs "[my FCfieldAttrs $wnamefull $attrs -lvar]"
        set attrs "[my ListboxesAttrs $wnamefull $attrs]"
        my AddPopupAttr $wnamefull attrs -entrypop 1
      }
      "meb" {set widget "ttk::menubutton"}
      "meB" {set widget "menubutton"}
      "not" {set widget "ttk::notebook"}
      "pan" {set widget "ttk::panedwindow"}
      "pro" {set widget "ttk::progressbar"}
      "rad" {set widget "ttk::radiobutton"}
      "raD" {set widget "radiobutton"}
      "sca" {set widget "ttk::scale"}
      "scA" {set widget "scale"}
      "sbh" {
        set widget "ttk::scrollbar";
        set options "-st ew $options"
        set attrs "-orient horizontal -takefocus 0 $attrs"
      }
      "sbH" {
        set widget "scrollbar"
        set options "-st ew $options"
        set attrs "-orient horizontal -takefocus 0 $attrs"
      }
      "sbv" {
        set widget "ttk::scrollbar"
        set options "-st ns $options"
        set attrs "-orient vertical -takefocus 0 $attrs"
      }
      "sbV" {
        set widget "scrollbar"
        set options "-st ns $options"
        set attrs "-orient vertical -takefocus 0 $attrs"
      }
      "seh" { ;# horizontal separator
        set widget "ttk::separator"
        set options "-st ew $options"
        set attrs "-orient horizontal $attrs"
      }
      "sev" { ;# vertical separator
        set widget "ttk::separator"
        set options "-st ns $options"
        set attrs "-orient vertical $attrs"
      }
      "siz" {set widget "ttk::sizegrip"}
      "spx" {set widget "ttk::spinbox"}
      "spX" {set widget "spinbox"}
      "tbl" { ;# tablelist
        set widget "tablelist::tablelist"
        set attrs "-labelcommand tablelist::sortByColumn -stretch all $attrs"
        set attrs "[my ListboxesAttrs $wnamefull $attrs]"
      }
      "tex" {                       ;# Tk 8.6.7 restored "-undo 0"
        set widget "text"           ;# of text widget by default
        set attrs "-undo 1 $attrs" ;# undo is enabled
        if {[my getOption -textpop {*}$attrs] eq ""} {
          my AddPopupAttr $wnamefull attrs -textpop \
            [expr {[my getOption -rotext {*}$attrs] ne ""}] -- disabled
        }
      }
      "tre" {set widget "ttk::treeview"}
      "h_*" { ;# horizontal spacer
        set widget "ttk::frame"
        set options "-st ew -csz 3 -padx 3 $options"
      }
      "v_*" { ;# vertical spacer
        set widget "ttk::frame"
        set options "-st ns -rsz 3 -pady 3 $options"
      }
      default {set widget ""}
    }
    if {$nam3 in {cbx ent enT fco spx spX}} {
      ;# entry-like widgets need their popup menu
      my AddPopupAttr $wnamefull attrs -entrypop 0 readonly disabled
    }
    if {[string first "pack" [string trimleft $pack]]==0} {
      set options $pack
    }
    set options [string trim $options]
    set attrs   [string trim $attrs]
    return [list $widget $options $attrs $nam3 $disabled]
  }

  #########################################################################
  #
  # Get -weight/-minsize options for row/column
  # They are set in grid options as "-rw <int>", "-cw <int>"

  method GetOptions {w options row rowspan col colspan} {

    set opts ""
    foreach {opt val} [list {*}$options] {
      switch -- $opt {
        -rw  { my SpanConfig $w row $row $rowspan -weight $val }
        -cw  { my SpanConfig $w column $col $colspan -weight $val }
        -rsz { my SpanConfig $w row $row $rowspan -minsize $val}
        -csz { my SpanConfig $w column $col $colspan -minsize $val }
        default {append opts " $opt $val"}
      }
    }
    # Get other grid options
    return [my ExpandOptions $opts]
  }

  #########################################################################
  #
  # Expand attributes' values

  method GetAttrs {options nam3 disabled} {

    set opts [list]
    foreach {opt val} [list {*}$options] {
      switch -- $opt {
        -t - -text {
          ;# these options need translating \\n to \n
          set val [subst  -nocommands -novariables $val]
        }
      }
      lappend opts $opt \{$val\}
    }
    if {$disabled} {
      append opts [my NonTtkStyle $nam3 1]
    }
    return $opts
  }

  method SpanConfig {w rcnam rc rcspan opt val} {

    for {set i $rc} {$i < ($rc + $rcspan)} {incr i} {
      eval [grid ${rcnam}configure $w $i $opt $val]
    }
    return
  }

  #########################################################################
  # Parent option for choosers

  method ParentOpt {} {

    if {$_pav(modalwin)=="."} {set wpar $w} {set wpar $_pav(modalwin)}
    return "-parent $wpar"
  }

  #########################################################################
  # Color chooser

  method colorChooser {tvar args} {

    if {[set _ [string trim [set $tvar]]] ne ""} {
      set _pav(initialcolor) $_
    }
    if {[catch {lassign [tk_chooseColor -moveall $_pav(moveall) \
    -tonemoves $_pav(tonemoves) -initialcolor $_pav(initialcolor) {*}$args] \
    res _pav(moveall) _pav(tonemoves)}]} {
      set res [tk_chooseColor -initialcolor $_pav(initialcolor) {*}$args]
    }
    if {$res ne ""} {
      set _pav(initialcolor) [set $tvar $res]
    }
    return $res
  }

  #########################################################################
  # Font chooser

  method fontChooser {tvar args} {

    proc [namespace current]::applyFont {font} "
      set $tvar \[font actual \$font\]"
    set font [set $tvar]
    if {$font==""} {
      catch {font create fontchoose {*}[font actual TkDefaultFont]}
    } else {
      catch {font delete fontchoose}
      catch {font create fontchoose {*}[font actual $font]}
    }
    tk fontchooser configure -parent . -font fontchoose {*}[my ParentOpt] \
      {*}$args -command [namespace current]::applyFont
    set res [tk fontchooser show]
    return $font
  }

  #########################################################################
  # Date chooser (calendar widget)

  method dateChooser {tvar args} {

    set df %d.%m.%Y
    array set a $args
    set ttl "Date"
    if [info exists a(-title)] {set ttl "$a(-title)"}
    catch {
      set df $a(-dateformat)
      set _pav(clnddate) [set $tvar]
    }
    if {$_pav(clnddate)==""} {
      set _pav(clnddate) [clock format [clock seconds] -format $df]
    }
    set wcal [set wmain [set ${_pav(ns)}PN::wn]].dateWidChooser
    catch {destroy $wcal}
    wm title [toplevel $wcal] $ttl
    lassign [split [winfo geometry $_pav(modalwin)] x+] rw rh rx ry
    wm geometry $wcal [my CenteredXY $rw $rh $rx $ry 220 150]
    wm protocol $wcal WM_DELETE_WINDOW [list set ${_pav(ns)}datechoosen ""]
    bind $wcal <Escape> [list set ${_pav(ns)}datechoosen ""]
    set ${_pav(ns)}datechoosen ""
    widget::calendar $wcal.c -dateformat $df -enablecmdonkey 0 -command \
      [list set ${_pav(ns)}datechoosen] -textvariable ${_pav(ns)}_pav(clnddate)
    pack $wcal.c -fill both -expand 0
    after idle [list focus $wcal]
    vwait ${_pav(ns)}datechoosen
    update idle
    destroy $wcal
    if {[set ${_pav(ns)}datechoosen]==""} {
      set _pav(clnddate) [set $tvar]
    }
    return $_pav(clnddate)
  }

  #########################################################################
  #
  # Chooser (for all available types)

  method chooser {nchooser tvar args} {

    set isfilename 0
    set ftxvar [my getOption -ftxvar {*}$args]
    set args [my RemoveSomeOptions $args -ftxvar]
    if {$nchooser eq "ftx_OpenFile"} {
      set nchooser "tk_getOpenFile"
    }
    if {$nchooser=="fontChooser" || $nchooser=="colorChooser" \
    ||  $nchooser=="dateChooser" } {
      set nchooser "my $nchooser $tvar"
    } elseif {$nchooser=="tk_getOpenFile" || $nchooser=="tk_getSaveFile"} {
      if {[set fn [set $tvar]]==""} {set dn [pwd]} {set dn [file dirname $fn]}
      set args "-initialfile \"$fn\" -initialdir \"$dn\" [my ParentOpt] $args"
      incr isfilename
    } elseif {$nchooser=="tk_chooseDirectory"} {
      set args "-initialdir \"[set $tvar]\" [my ParentOpt] $args"
      incr isfilename
    }
    set res [{*}$nchooser {*}$args]
    if {"$res" ne "" && "$tvar" ne ""} {
      if {$isfilename} {
        lassign [my SplitContentVariable $ftxvar] -> txtnam wid
        if {[info exist $ftxvar] && \
        [file exist [set res [file nativename $res]]]} {
          set $ftxvar [my readTextFile $res]
          if {[winfo exist $txtnam]} {
            my readonlyWidget $txtnam false
            my displayTaggedText $txtnam $ftxvar
            my readonlyWidget $txtnam true
            set wid [string range $txtnam \
             0 [string last . $txtnam]]$wid
            $wid configure -text "$res"
            ::tk::TextSetCursor $txtnam 1.0
            update
          }
        }
      }
      set $tvar $res
    }
    return $res
  }

  #########################################################################
  #
  # Transfrom 'name' by adding 'typ'

  method Transname {typ name} {

    if {[set pp [string last . $name]]>-1} {
      set name [string range $name 0 $pp]$typ[string range $name $pp+1 end]
    } else {
      set name $typ$name
    }
    return $name
  }

  #########################################################################
  #
  # Set/get text content variable

  method SetContentVariable {tvar txtnam name} {

    return [set _pav(textcont,$tvar) $tvar*$txtnam*$name]
  }

  method GetContentVariable {tvar} {

    return $_pav(textcont,$tvar)
  }

  method SplitContentVariable {ftxvar} {

    return [split $ftxvar *]
  }

  # Get text content
  method getTextContent {tvar} {

    lassign [my SplitContentVariable [my GetContentVariable $tvar]] \
      -> txtnam wid
    return [string trimright [$txtnam get 1.0 end]]
  }

  #########################################################################
  #
  # Choosers should contain 2 fields: entry + button
  # Here every chooser is replaced with these two widgets

  method Replace_chooser {r0 r1 r2 r3 args} {

    upvar 1 $r0 w $r1 i $r2 lwlen $r3 lwidgets
    lassign $args name neighbor posofnei rowspan colspan options1 attrs1
    lassign "" wpar view addattrs addattrs2
    set tvar [my getOption -tvar {*}$attrs1]
    set filetypes [my getOption -filetypes {*}$attrs1]
    if {$filetypes ne ""} {
      set attrs1 [my RemoveSomeOptions $attrs1 -filetypes]
      lset args 6 $attrs1
      append addattrs2 " -filetypes {$filetypes}"
    }
    set an ""
    lassign [my LowercaseWidgetName $name] n
    switch -glob -- [my rootwname $n] {
      "fil*" { set chooser "tk_getOpenFile" }
      "fis*" { set chooser "tk_getSaveFile" }
      "dir*" { set chooser "tk_chooseDirectory" }
      "fon*" { set chooser "fontChooser" }
      "dat*" { set chooser "dateChooser" }
      "ftx*" {
        set chooser [set view "ftx_OpenFile"]
        if {$tvar ne "" && [info exist $tvar]} {
          append addattrs " -t [set $tvar]"
        }
        set an "tex"
      }
      "clr*" { set chooser "colorChooser"
        set wpar "-parent $w" ;# specific for color chooser (gets parent of $w)
      }
      default {
        return $args
      }
    }
    my MakeWidgetName $w $name $an
    set name $n
    set tvar [set vv [set addopt ""]]
    set attmp [list]
    foreach {nam val} $attrs1 {
      if {$nam=="-title" || $nam=="-dateformat"} {
        append addopt " $nam \{$val\}"
      } else {
        lappend attmp $nam $val
      }
    }
    set attrs1 $attmp
    catch {array set a $attrs1; set tvar "-tvar [set vv $a(-tvar)]"}
    catch {array set a $attrs1; set tvar "-tvar [set vv $a(-textvariable)]"}
    if {$vv==""} {
      set vv [namespace current]::$name
      set tvar "-tvar $vv"
    }
    # make a frame in the widget list
    set ispack 0
    if {![catch {set gm [lindex [lindex $lwidgets $i] 5]}]} {
      set ispack [expr [string first "pack" $gm]==0]
    }
    if {$ispack} {
      set args [list $name - - - - "pack -expand 0 -fill x [string range $gm 5 end]" $addattrs]
    } else {
      set args [list $name $neighbor $posofnei $rowspan $colspan "-st ew" $addattrs]
    }
    lset lwidgets $i $args
    if {$view ne ""} {
      set txtnam [my Transname tex $name]
      set tvar [my getOption -tvar {*}$attrs1]
      set attrs1 [my RemoveSomeOptions $attrs1 -tvar]
      if {$tvar ne "" && [file exist [set $tvar]]} {
        set tcont [my SetContentVariable $tvar $w.$txtnam $name]
        set wpar "-ftxvar $tcont"
        set $tcont [my readTextFile [set $tvar]]
        set attrs1 [my putOption -rotext $tcont {*}$attrs1]
      }
      set entf [list $txtnam - - - - "pack -side left -expand 1 -fill both -in $w.$name" "$attrs1"]
    } else {
      set entf [list [my Transname ent $name] - - - - "pack -side left -expand 1 -fill x -in $w.$name" "$attrs1 $tvar"]
    }
    set icon "folder"
    foreach ic {OpenFile SaveFile font color date} {
      if {[string first $ic $chooser] >= 0} {set icon $ic; break}
    }
    set com "[self] chooser $chooser \{$vv\} $addopt $wpar $addattrs2"
    set butf [list [my Transname buT $name] - - - - "pack -side right -anchor n -in $w.$name -padx 1" "-com \{$com\} -compound none -image [apave::iconImage $icon] -font \{-weight bold -size 5\} -fg $_pav(fgbut) -bg $_pav(bgbut)"]
    if {$view ne ""} {
      set scrolh [list [my Transname sbh $name] $txtnam T - - "pack -in $w.$name" ""]
      set scrolv [list [my Transname sbv $name] $txtnam L - - "pack -in $w.$name" ""]
      set lwidgets [linsert $lwidgets [expr {$i+1}] $butf]
      set lwidgets [linsert $lwidgets [expr {$i+2}] $entf]
      set lwidgets [linsert $lwidgets [expr {$i+3}] $scrolv]
      incr lwlen 3
      set wrap [my getOption -wrap {*}$attrs1]
      if {$wrap eq "none"} {
        set lwidgets [linsert $lwidgets [expr {$i+4}] $scrolh]
        incr lwlen
      }
    } else {
      set lwidgets [linsert $lwidgets [expr {$i+1}] $entf $butf]
      incr lwlen 2
    }
    return $args
  }

  #########################################################################
  #
  # Bar widgets should contain N fields of appropriate type

  method Replace_bar {r0 r1 r2 r3 args} {

    upvar 1 $r0 w $r1 i $r2 lwlen $r3 lwidgets
    lassign $args name neighbor posofnei rowspan colspan options1 attrs1
    set wpar ""
    switch -glob -- [my rootwname $name] {
      "men*" - "Men*" { set typ menuBar }
      "too*" - "Too*" { set typ toolBar }
      "sta*" - "Sta*" { set typ statusBar }
      default {
        return $args
      }
    }
    set winname [winfo toplevel $w]
    set attcur [list]
    set namvar [list]
    # get array of pairs (e.g. image-command for toolbar)
    foreach {nam val} $attrs1 {
      if {$nam=="-array"} {
        set ind -1
        foreach {v1 v2} $val {
          lappend namvar [namespace current]::$typ[incr ind] $v1 $v2
        }
      } else {
        lappend attcur $nam $val
      }
    }
    # make a frame in the widget list
    if {$typ=="menuBar"} {
      set args ""
    } else {
      set ispack 0
      if {![catch {set gm [lindex [lindex $lwidgets $i] 5]}]} {
        set ispack [expr [string first "pack" $gm]==0]
      }
      if {$ispack} {
        set args [list $name - - - - "pack -expand 0 -fill x -side bottom [string range $gm 5 end]" $attcur]
      } else {
        set args [list $name $neighbor $posofnei $rowspan $colspan "-st ew" $attcur]
      }
      lset lwidgets $i $args
    }
    set itmp $i
    set k [set j [set j2 [set wasmenu 0]]]
    foreach {nam v1 v2} $namvar {
      if {[incr k 3]==[llength $namvar]} {
        set expand "-expand 1 -fill x"
      } else {
        set expand ""
      }
      if {$v1=="h_"} {  ;# horisontal space
        set ntmp [my Transname fra ${name}[incr j2]]
        set wid1 [list $ntmp - - - - "pack -side left -in $w.$name -fill y"]
        set wid2 [list $ntmp.[my Transname h_ $name$j] - - - - "pack -fill y -expand 1 -padx $v2"]
      } elseif {$v1=="sev"} {   ;# vertical separator
        set ntmp [my Transname fra ${name}[incr j2]]
        set wid1 [list $ntmp - - - - "pack -side left -in $w.$name -fill y"]
        set wid2 [list $ntmp.[my Transname sev $name$j] - - - - "pack -fill y -expand 1 -padx $v2"]
      } elseif {$typ=="statusBar"} {  ;# statusbar
        set wid1 [list $name.[my Transname Lab ${name}_[incr j]] - - - - "pack -side left" "-t [lindex $v1 0]"]
        set wid2 [list [my Transname Lab $name$j] - - - - "pack -side left -in $w.$name $expand" "-relief sunken -w $v2 [lrange $v1 1 end]"]
      } elseif {$typ=="toolBar"} {  ;# toolbar
        if {[string is lower [string index $v1 0]]} {
          set but buT
        } else {
          set but BuT
        }
        set wid1 [list $name.[my Transname $but _$v1] - - - - "pack -side left" "-image $v1 -command $v2 -relief flat -takefocus 0"]
        if {[incr wasseh]==1} {
          set wid2 [list [my Transname seh $name$j] - - - - "pack -side top -expand 1 -fill x"]
        } else {
          set lwidgets [linsert $lwidgets [incr itmp] $wid1]
          continue
        }
      } elseif {$typ=="menuBar"} {
        ;# menubar: making it here; filling it outside of 'pave window'
        if {[incr wasmenu]==1} {
          set menupath [my MakeWidgetName $winname $name]
          menu $menupath -tearoff 0
        }
        set menuitem [my MakeWidgetName $menupath $v1]
        menu $menuitem -tearoff 0
        set ampos [string first & $v2]
        set v2 [string map {& ""} $v2]
        $menupath add cascade -label [lindex $v2 0] {*}[lrange $v2 1 end] -menu $menuitem -underline $ampos
        continue
      } else {
        error "\npaveme.tcl: erroneous \"$v1\" for \"$nam\"\n"
      }
      set lwidgets [linsert $lwidgets [incr itmp] $wid1 $wid2]
      incr itmp
    }
    if {$wasmenu} {
      $winname configure -menu $menupath
    }
    incr lwlen [expr {$itmp - $i}]
    return $args
  }

  #########################################################################
  #
  # Make the widget name lowercased

  method LowercaseWidgetName {name} {

    set root [my rootwname $name]
    return [list [string range $name 0 [string last . $name]][string tolower \
      [string index $root 0]][string range $root 1 end] $root]
  }

  #########################################################################
  #
  # Get the real name of widget from .name
  # .name means "child of some previous" and should be normalized
  # e.g.  parent: fra.fra ..... child: .but => normalized: fra.fra.but

  method NormalizeName {refname refi reflwidgets} {

    upvar $refname name $refi i $reflwidgets lwidgets
    set wname $name
    if {[string index $name 0]=="."} {
      for {set i2 [expr {$i-1}]} {$i2 >=0} {incr i2 -1} {
        lassign [lindex $lwidgets $i2] name2
        if {[string index $name2 0] ne "."} {
          set wname "$name2$name"
          lassign [my LowercaseWidgetName $name] name
          set name "$name2$name"
          break
        }
      }
    }
    return [list $name $wname]
  }

  #########################################################################
  #
  # Make an exported method named after root widget, if it's uppercased,
  # e.g. fra1.fra2.fra3.Entry1 -> method Entry1 {...}

  method MakeWidgetName {w name {an {}}} {

    set root1 [string index [my rootwname $name] 0]
    if {[string is upper $root1]} {
      lassign [my LowercaseWidgetName $name] name method
      if {[catch {info object definition [self] $method}]} {
        oo::objdefine [self] "
          method $method {} {return $w.$an$name}
          export $method"
      }
    }
    return [set ${_pav(ns)}PN::wn $w.$name]
  }

  #########################################################################
  # add the attribute to call a popup menu for an editable widget

  method AddPopupAttr {w attrsName atRO isRO args} {

    upvar 1 $attrsName attrs
    lassign $args state state2
    if {$state2 ne ""} {
      if {[my getOption -state {*}$attrs] eq $state2} return
      set isRO [expr {$isRO || [my getOption -state {*}$attrs] eq $state}]
    }
    if {$isRO} { append atRO "RO" }
    append attrs " $atRO $w"
    return
  }

  #########################################################################
  # make a popup menu for an editable widget

  method makePopup {w {isRO false} {istext false} {tearoff false}} {

    set pop $w.popupMenu
    catch {
      menu $pop -tearoff $tearoff
    }
    $pop delete 0 end
    if {$isRO} {
      $pop add command {*}[my IconA copy] -accelerator Ctrl+C -label "Copy" \
            -command "event generate $w <<Copy>>"
    } else {
      $pop add command {*}[my IconA cut] -accelerator Ctrl+X -label "Cut" \
            -command "event generate $w <<Cut>>"
      $pop add command {*}[my IconA copy] -accelerator Ctrl+C -label "Copy" \
            -command "event generate $w <<Copy>>"
      $pop add command {*}[my IconA paste] -accelerator Ctrl+V -label "Paste" \
            -command "event generate $w <<Paste>>"
      if {$istext} {
        $pop add separator
        $pop add command {*}[my IconA undo] -accelerator Ctrl+Z -label "Undo" \
              -command "event generate $w <<Undo>>"
        $pop add command {*}[my IconA redo] -accelerator Ctrl+Shift+Z -label "Redo" \
              -command "event generate $w <<Redo>>"
      }
    }
    if {$istext} {
      $pop add separator
      $pop add command {*}[my IconA none] -accelerator Ctrl+A -label "Select All" \
        -command "$w tag add sel 1.0 end"
    }
    bind $w <Button-3> [list tk_popup $w.popupMenu %X %Y]
    return
  }

  #########################################################################
  #
  # Pre actions for the text widget and similar
  # which all require some actions before and after their creation e.g.:
  #   the text widget's text cannot be filled if disabled
  #   so, we must act this way:
  #     1) call Pre - to get a text of widget
  #     2) create the widget
  #     3) call Post - to enable, then fill it with a text, then disable it
  # It's only possible with Pre and Post methods.

  method Pre {refattrs} {

    upvar 1 $refattrs attrs
    set attrs_ret [set _pav(prepost) {}]
    foreach {a v} $attrs {
      switch -- $a {
        -disabledtext - -rotext - -lbxsel - -cbxsel - \
        -entrypop - -entrypopRO - -textpop - -textpopRO - -ListboxSel {
          # attributes specific to apave, processed below in "Post"
          lappend _pav(prepost) [list $a [string trim $v {\{\}}]]
        }
        default {
          lappend attrs_ret $a $v
        }
      }
    }
    set attrs $attrs_ret
    return
  }

  #########################################################################
  #
  # Post processing actions (for comments, refer to "Pre" above)

  method Post {w attrs} {

    foreach pp $_pav(prepost) {
      lassign $pp a v
      switch -- $a {
        -disabledtext {
          $w configure -state normal
          my displayTaggedText $w v {}
          $w configure -state disabled
          my readonlyWidget $w false
        }
        -rotext {
          if {[info exist v]} {
            if {[info exist $v]} {
              my displayTaggedText $w $v {}
            } else {
              my displayTaggedText $w v {}
            }
          }
          my readonlyWidget $w true
        }
        -lbxsel {
          set v [lsearch -glob [$w get 0 end] "$v*"]
          if {$v>=0} {
            $w selection set $v
            $w yview $v
            $w activate $v
          }
        }
        -cbxsel {
          set cbl [$w cget -values]
          set v [lsearch -glob $cbl "$v*"]
          if {$v>=0} { $w set [lindex $cbl $v] }
        }
        -ListboxSel {
          bind $v <<ListboxSelect>> [list [namespace current]::ListboxSelect %W]
        }
        -entrypop - -entrypopRO {
          if {[winfo exists $v]} {
            my makePopup $v [expr {$a eq "-entrypopRO"}]
          }
        }
        -textpop - -textpopRO {
          if {[winfo exists $v]} {
            my makePopup $v [expr {$a eq "-textpopRO"}] true
          }
        }
      }
    }
    return
  }

  #########################################################################
  #
  # Switch on/off a widget's readonly state - for text widget
  # See also: https://wiki.tcl-lang.org/page/Read-only+text+widget

  method readonlyWidget {w {on true}} {

    if {$on && [info commands $w] ne "" && \
    [info commands ::$w.internal] eq ""} {
      rename $w ::$w.internal
      proc ::$w {args} "
          switch -exact -- \[lindex \$args 0\] \{
              insert \{\}
              delete \{\}
              replace \{\}
              default \{
                  return \[eval ::$w.internal \$args\]
              \}
          \}"
    } elseif {!$on && [info commands ::$w.internal] ne ""} {
      rename ::$w ""
      rename ::$w.internal ::$w
    }
    my makePopup $w $on true
    return
  }

  #########################################################################
  #
  # Some i/o widgets require a special method
  # of getting their returned values

  method GetOutputValues {} {

    foreach aop $_pav(widgetopts) {
      lassign $aop optnam vn v1 v2
      switch -- $optnam {
        -lbxname { ;# to get a listbox's value, its methods are used
          lassign [$vn curselection] s1
          if {$s1 eq {}} {set s1 0}
          set $v1 [$vn get $s1]
        }
        -retpos { ;# a range to cut from -tvar/-lvar variable
          lassign [split $v2 :] p1 p2
          set val1 [set $v1]
          # there may be -list option for this widget
          # then if the value is from the list, it's fully returned
          foreach aop2 $_pav(widgetopts) {
            lassign $aop2 optnam2 vn2 lst2
            if {$optnam2=="-list" && $vn==$vn2} {
              foreach val2 $lst2 {
                if {$val1 == $val2} {
                  set p1 0
                  set p2 end
                  break
                }
              }
              break
            }
          }
          set $v1 [string range $val1 $p1 $p2]
        }
      }
    }
    return
  }

  #########################################################################
  #
  # Set focus on a widget (possibly, assigned with [my Widget])

  method setFocus {wnext} {

    focus [subst $wnext]
    return
  }

  #########################################################################
  #
  # Get additional commands (for non-standard attributes)

  method AdditionalCommands {w attrsName} {

    upvar $attrsName attrs
    set addcomms {}
    if {[set tooltip [my getOption -tooltip {*}$attrs]] ne ""} {
      lappend addcomms [list tooltip::tooltip $w $tooltip]
      set attrs [my RemoveSomeOptions $attrs -tooltip]
    }
    if {[my getOption -ro {*}$attrs] ne "" || \
    [my getOption -readonly {*}$attrs] ne ""} {
      lassign [my parseOptionsFile 0 $attrs -ro 0 -readonly 0] tmp
      lassign $tmp - ro - readonly
      lappend addcomms [list my readonlyWidget $w [expr $ro||$readonly]]
      set attrs [my RemoveSomeOptions $attrs -ro -readonly]
    }
    if {[set wnext [my getOption -tabnext {*}$attrs]] ne ""} {
      after idle [list bind $w <Key> \
        [list if {{%K} == {Tab}} "[self] setFocus $wnext ; break" ]]
      set attrs [my RemoveSomeOptions $attrs -tabnext]
    }
    return $addcomms
  }

  #########################################################################
  #
  # Pave the window with widgets

  method Window {w inplists} {

    set lwidgets [list]
    # comments be skipped
    foreach lst $inplists {
      if {[string index [string index $lst 0] 0] ne "#"} {
        lappend lwidgets $lst
      }
    }
    set lused {}
    set lwlen [llength $lwidgets]
    for {set i 0} {$i < $lwlen} {} {
      # List of widgets contains data per widget:
      #   widget's name,
      #   neighbor widget, position of neighbor (T, L),
      #   widget's rowspan and columnspan (both optional),
      #   grid options, widget's attributes (both optional)
      set lst1 [lindex $lwidgets $i]
      set lst1 [my Replace_chooser w i lwlen lwidgets {*}$lst1]
      if {[set lst1 [my Replace_bar w i lwlen lwidgets {*}$lst1]]==""} {
        incr i
        continue
      }
      lassign $lst1 name neighbor posofnei rowspan colspan \
        options1 attrs1 add1 comm1
      set prevw $name
      lassign [my NormalizeName name i lwidgets] name wname
      lassign [my NormalizeName neighbor i lwidgets] neighbor
      set wname [my MakeWidgetName $w $wname]
      if {$colspan=={} || $colspan=={-}} {
        set colspan 1
        if {$rowspan=={} || $rowspan=={-}} {
          set rowspan 1
        }
      }
      set options [uplevel 2 subst -nocomm -nobackslashes [list $options1]]
      set attrs [uplevel 2 subst -nocomm -nobackslashes [list $attrs1]]
      lassign [my GetWidgetType $wname $options $attrs] \
        widget options attrs nam3 dsbl
      # The type of widget (if defined) means its creation
      # (if not defined, it was created after "makewindow" call
      # and before "window" call)
      if { !($widget == "" || [winfo exists $widget])} {
        set attrs [my GetAttrs $attrs $nam3 $dsbl]
        set attrs [string map {\" \\\"} [my ExpandOptions $attrs]]
        # for scrollbars - set up the scrolling commands
        if {$widget in {"ttk::scrollbar" "scrollbar"}} {
          if {$posofnei=="L"} {
            $w.$neighbor config -yscrollcommand "$w.$name set"
            set attrs "$attrs -com \\\{$w.$neighbor yview\\\}"
            append options " -side right -fill y -after $w.$neighbor"
          } elseif {$posofnei=="T"} {
            $w.$neighbor config -xscrollcommand "$w.$name set"
            set attrs "$attrs -com \\\{$w.$neighbor xview\\\}"
            append options " -side bottom -fill x -before $w.$neighbor"
          }
        }
        #% doctest 1
        #%   set a "123 \\\\\\\\ 45"
        #%   eval append b {*}$a
        #%   set b
        #>   123\45
        #> doctest
        my Pre attrs
        set addcomms [my AdditionalCommands $wname attrs]
        eval $widget $wname {*}$attrs
        my Post $wname $attrs
        foreach acm $addcomms { eval {*}$acm }
        # for buttons and entries - set up the hotkeys (Up/Down etc.)
        if {($widget in {"ttk::entry" "entry"}) && \
        [string first "STD" $wname]==-1} {
          # STD in $w or $name prevents it:
          bind $wname <Up> [list \
            if {$::tcl_platform(platform) == "windows"} [list \
              event generate $wname <Shift-Tab> \
            ] else [list \
              event generate $wname <Key> -keysym ISO_Left_Tab] \
            ]
          foreach k {<Down> <Return> <KP_Enter>} {
            bind $wname $k \
              [list event generate $wname <Key> -keysym Tab]
          }
        }
        if {$widget in {ttk::button button ttk::checkbutton checkbutton \
                        ttk::radiobutton radiobutton}} {
          foreach k {<Up> <Left>} {
            bind $wname $k [list \
              if {$::tcl_platform(platform) == "windows"} [list \
                event generate $wname <Shift-Tab> \
              ] else [list \
                event generate $wname <Key> -keysym ISO_Left_Tab] \
              ]
          }
          foreach k {<Down> <Right>} {
            bind $wname $k \
              [list event generate $wname <Key> -keysym Tab]
          }
          foreach k {<Return> <KP_Enter>} {
            bind $wname $k \
            [list event generate $wname <Key> -keysym space]
          }
        }
      }
      if {$neighbor eq "-" || $row < 0} {
        set row [set col 0]
      }
      # check for simple creation of widget (without pack/grid)
      if {$neighbor ne "#"} {
        set options [my GetOptions $w $options $row $rowspan $col $colspan]
        set pack [string trim $options]
        if {$add1 ne ""} {
          set comm "[winfo parent $wname] add $wname [string range $add1 4 end]"
          {*}$comm
        } elseif {[string first "pack" $pack]==0} {
          pack $wname {*}[string range $pack 5 end]
        } else {
          grid $wname -row $row -column $col -rowspan $rowspan \
             -columnspan $colspan -padx 1 -pady 1 {*}$options
        }
      }
      if {$comm1 ne ""} {
        set comm1 [string map [list ~. $wname. "~ " "$wname "] $comm1]
        {*}$comm1
      }
      lappend lused [list $name $row $col $rowspan $colspan]
      if {[incr i] < $lwlen} {
        lassign [lindex $lwidgets $i] name neighbor posofnei
        if {$neighbor=="+"} {
          set neighbor $prevw
        }
        set row -1
        foreach cell $lused {
          lassign $cell uname urow ucol urowspan ucolspan
          if {$uname eq $neighbor} {
            set col $ucol
            set row $urow
            if {$posofnei == "T" || $posofnei == ""} {
              incr row $urowspan
            } elseif {$posofnei == "L"} {
              incr col $ucolspan
            }
          }
        }
      }
    }
    return $lwidgets
  }

  # Process "win & list-of-widgets" pairs
  method window {args} {

    set res [list]
    foreach {w lwidgets} $args {
      lappend res {*}[my Window $w $lwidgets]
    }
    return $res
  }

  #########################################################################
  #
  # Show a window as modal
  # win - window's name
  # args - attributes of window set with pairs "-name value":
  #  -focus NAME sets the name of focused widget
  #  -onclose PROC sets the name of procedure being called
  #                at closing window by [X]; the procedure gets
  #                the variable name that can be changed to 0
  #                in order to close the window indeed
  #  -geometry GEOMETRY sets the geometry of window
  #  -decor DECOR sets the decorative buttons of window (if DECOR=1)

  method showModal {win args} {

    my NonTtkTheme $win
    apave::setAppIcon $win
    if {[my iswindows]} { ;# maybe nice to hide all windows manipulations
      wm attributes $win -alpha 0.0
    } else {
      wm withdraw $win
    }
    set _pav(modalwin) $win
    set root [winfo parent $win]
    if {[set ontop [string first "-ontop " $args]]>-1} {
      catch {set ontop [expr [string index $args [expr $ontop+7]]]}
      set args [my RemoveSomeOptions $args -ontop]
    }
    array set opt \
      [list -focus "" -onclose "" -geometry "" -decor 0 -root $root {*}$args]
    lassign [split [winfo geometry $root] x+] rw rh rx ry
    if {! $opt(-decor)} {
      wm transient $win $root
    }
    if {$opt(-onclose) == ""} {
      set opt(-onclose) [list set ${_pav(ns)}PN::AR($win) 0]
    } else {
      set opt(-onclose) [list $opt(-onclose) ${_pav(ns)}PN::AR($win)]
    }
    wm protocol $win WM_DELETE_WINDOW $opt(-onclose)
    # get the window's geometry from its requested sizes
    set inpgeom $opt(-geometry)
    if {$inpgeom == ""} {
      # this is for less blinking:
      set opt(-geometry) [my CenteredXY $rw $rh $rx $ry \
        [winfo reqwidth $win] [winfo reqheight $win]]
    }
    if {[set pp [string first + $opt(-geometry)]]>=0} {
      wm geometry $win [string range $opt(-geometry) $pp end]
    }
    grab set $win
    if {$opt(-focus) == ""} {
      set opt(-focus) $win
    }
    set ${_pav(ns)}PN::AR($win) "-"
    bind $win <Escape> $opt(-onclose)
    update
    if {[my iswindows]} {
      if {[wm attributes $win -alpha] < 0.1} {wm attributes $win -alpha 1.0}
    } else {
      catch {wm deiconify $win ; raise $win}
    }
    wm minsize $win [set w [winfo width $win]] [set h [winfo height $win]]
    bind $win <Configure> "[namespace current]::WinResize $win"
    if {$inpgeom == ""} {  ;# final geometrizing with actual sizes
      if {$root == "."} {
        ::tk::PlaceWindow $win widget $root
      } else {
        # this is for less blinking:
        wm geometry $win [my CenteredXY $rw $rh $rx $ry $w $h]
      }
    } else {
      wm geometry $win $inpgeom
    }
    if {$ontop>0} {
      wm attributes $win -topmost 1
    }
    after 50 [list if "\[winfo exist $opt(-focus)\]" "focus -force $opt(-focus)"]
    tkwait variable ${_pav(ns)}PN::AR($win)
    grab release $win
    my GetOutputValues
    return [set [set _ ${_pav(ns)}PN::AR($win)]]
  }

  #########################################################################
  #
  # This method is useful to get/set the variable for vwait command

  method res {win {r "get"}} {

    if {$r == "get"} {
      return [set ${_pav(ns)}PN::AR($win)]
    }
    set ${_pav(ns)}PN::AR($win) $r
    return
  }

  #########################################################################
  #
  # Create a toplevel window with $w name and $ttl title
  # If $w matches "*.fra" then ttk::frame is created with name $w

  method makeWindow {w ttl} {

    set w [set wtop [string trimright $w .]]
    set withfr [expr {[set pp [string last . $w]]>0 && \
      [string match "*.fra" $w]}]
    if {$withfr} {
      set wtop [string range $w 0 $pp-1]
    }
    catch {destroy $wtop}
    toplevel $wtop
    if {$withfr} {
      pack [ttk::frame $w] -expand 1 -fill both
    }
    wm title $wtop $ttl
    return $wtop
  }

  #########################################################################
  #
  # Set the text widget's contents

  method displayText {w conts} {

    if { [set state [$w cget -state]] ne "normal"} {
      $w configure -state normal
    }
    $w replace 1.0 end $conts
    $w edit reset
    if { $state ne "normal" } { $w configure -state $state }
    return
  }

  #########################################################################
  #
  # Get the tag positions in the contsName text and display it in w text
  # widget. The lines in contsName are divided by \n. The tags in tags
  # variable are "pure" ones i.e. for <b>..</b> the tags list contains "b".
  # Also the tags list contains the tagging options (-font etc.).
  # The contsName is a varname of contents variable.

  method displayTaggedText {w contsName {tags ""}} {

    upvar $contsName conts
    if {$tags eq ""} {
      my displayText $w $conts
      return
    }
    if { [set state [$w cget -state]] ne "normal"} {
      $w configure -state normal
    }
    set taglist [set tagpos [set taglen [list]]]
    foreach tagi $tags {
      lassign $tagi tag
      lappend tagpos 0
      lappend taglen [string length $tag]
    }
    set tLen [llength $tags]
    set disptext ""
    set irow 1
    foreach line [split $conts \n] {
      if {$irow > 1} {
        append disptext \n
      }
      set newline ""
      while 1 {
        set p [string first \< $line]
        if {$p < 0} {
          break
        }
        append newline [string range $line 0 $p-1]
        set line [string range $line $p end]
        set i 0
        set nrnc $irow.[string length $newline]
        foreach tagi $tags pos $tagpos len $taglen {
          lassign $tagi tag
          if {[string first "\<$tag\>" $line]==0} {
            if {$pos ne "0"} {
              error "\npaveme.tcl: mismatched \<$tag\> in line $irow.\n"
            }
            lset tagpos $i $nrnc
            set line [string range $line $len+2 end]
            break
          } elseif {[string first "\</$tag\>" $line]==0} {
            if {$pos == "0"} {
              error "\npaveme.tcl: mismatched \</$tag\> in line $irow.\n"
            }
            lappend taglist [list $i $pos $nrnc]
            lset tagpos $i 0
            set line [string range $line $len+3 end]
            break
          }
          incr i
        }
        if {$i == $tLen} {
          # tag not found after "<" - shift by 1 character
          append newline [string index $line 0]
          set line [string range $line 1 end]
        }
      }
      append disptext $newline $line
      incr irow
    }
    $w replace 1.0 end $disptext
    foreach tagi $tags {
      lassign $tagi tag opts
      $w tag config $tag {*}$opts
    }
    foreach tagli $taglist {
      lassign $tagli i p1 p2
      lassign [lindex $tags $i] tag opts
      $w tag add $tag $p1 $p2
    }
    $w edit reset
    if { $state ne "normal" } { $w configure -state $state }
    return
  }

}
