###########################################################################
#
# This script contains the APaveDialog class that provides a batch of
# standard dialogs with advanced features.
#
# Use:
#   package require apave
#   ...
#   catch {pdlg destroy}
#   apave::APaveDialog create pdlg win
#   pdlg DIALOG ARGS
# where:
#   DIALOG stands for the following dialog types:
#     ok
#     okcancel
#     yesno
#     yesnocancel
#     retrycancel
#     abortretrycancel
#     misc
#   ARGS stands for the arguments of dialog:
#     icon title message (optional checkbox message) (optional geometry) \
#                   (optional -text 1)
#
# Examples of dialog calls:
#   pdlg ok info "OK title" "Ask for OK" -ch "Once only" -g "+300+100"
#   pdlg okcancel info "OC title" "Ask for OK" OK
#   pdlg yesno info "YN title" "Ask for YES" YES
#   pdlg yesnocancel info "YNC title" "Ask for YES" YES -ch "Show once"
#   pdlg retrycancel info "RC title" "Ask for RETRY" RETRY
#   pdlg abortretrycancel info "ARC title" "Ask for RETRY" RETRY
#   pdlg misc info "MSC title" "Ask for HELLO" {Hello 1 "Bye baby" 2} 1
#
# See test_pavedialog.tcl for the detailed examples of use.
#
# for debugging
# proc d {args} {tk_messageBox -title "INFO" -icon info -message "$args"}
###########################################################################

package require Tk

source [file join [file dirname [info script]] apave.tcl]

namespace eval apave {
  source [file join [file dirname [info script]] apaveimg.tcl]
}


oo::class create apave::APaveDialog {

  superclass apave::APave

  variable _pdg

  constructor {{win ""} args} {
    # keep the 'important' data of APaveDialog object in array
    array set _pdg {}
    # dialogs are bound to "$win" window e.g. ".mywin.fra", default "" means .
    set _pdg(win) $win
    set _pdg(ns) [namespace current]::
    # namespace in object namespace for safety of its 'most important' data
    namespace eval ${_pdg(ns)}PD {}
    foreach icon {err info warn ques} {
      image create photo ${_pdg(ns)}PD::img$icon -data [set apave::img_$icon]
    }
    if {[llength [self next]]} { next {*}$args }
  }

  destructor {

    catch "namespace delete ${_pdg(ns)}PD"
    if {[llength [self next]]} { next {*}$args }

  }

  #########################################################################
  #
  # Standard dialogs:
  #  ok               - dialog with button OK
  #  okcancel         - dialog with buttons OK, Cancel
  #  yesno            - dialog with buttons YES, NO
  #  yesnocancel      - dialog with buttons YES, NO, CANCEL
  #  retrycancel      - dialog with buttons RETRY, CANCEL
  #  abortretrycancel - dialog with buttons ABORT, RETRY, CANCEL
  #  misc             - dialog with miscellaneous buttons
  #
  # Called as:
  #   dialog icon ttl msg ?defb? ?args?
  #
  # Mandatory arguments of dialogs:
  #   icon   - icon name (info, warn, err, ques)
  #   ttl    - title
  #   msg    - message
  # Optional arguments:
  #   defb - default button (OK, YES, NO, CANCEL, RETRY, ABORT)
  #   args:
  #     -checkbox text (-ch text) - makes the checkbox's text visible
  #     -geometry +x+y (-g +x+y)  - sets the geometry of dialog
  #     -color cval    (-c cval)  - sets the color of message
  #     -family... -size... etc. options of label widget
  #     -text 1 - sets the text widget to show a message

  method PrepArgs {args} {
    # make a list of args
    foreach a $args { lappend res $a }
    return $res
  }

  method ok {icon ttl msg args} {
    return [my Query $icon $ttl $msg {butOK OK 1} butOK {} [my PrepArgs $args]]
  }

  method okcancel {icon ttl msg {defb OK} args} {
    return [my Query $icon $ttl $msg \
      {butOK OK 1 butCANCEL Cancel 0} but$defb {} [my PrepArgs $args]]
  }

  method yesno {icon ttl msg {defb YES} args} {
    return [my Query $icon $ttl $msg \
      {butYES Yes 1 butNO No 0} but$defb {} [my PrepArgs $args]]
  }

  method yesnocancel {icon ttl msg {defb YES} args} {
    return [my Query $icon $ttl $msg \
      {butYES Yes 1 butNO No 2 butCANCEL Cancel 0} but$defb {} [my PrepArgs $args]]
  }

  method retrycancel {icon ttl msg {defb RETRY} args} {
    return [my Query $icon $ttl $msg \
      {butRETRY Retry 1 butCANCEL Cancel 0} but$defb {} [my PrepArgs $args]]
  }

  method abortretrycancel {icon ttl msg {defb RETRY} args} {
    return [my Query $icon $ttl $msg \
      {butABORT Abort 1 butRETRY Retry 2 butCANCEL \
      Cancel 0} but$defb {} [my PrepArgs $args]]
  }

  method misc {icon ttl msg butts {defb ""} args} {
    # butts is a list of pairs "title of button" "number/ID of button"
    foreach {nam num} $butts {
      lappend apave_msc_bttns but$num "$nam" $num
      if {$defb==""} {
        set defb $num
      }
    }
    return [my Query $icon $ttl $msg $apave_msc_bttns but$defb {} [my PrepArgs $args]]
  }

  #########################################################################

  # Get a value of _pdg(name)
  method Pdg {name} {
    return $_pdg($name)
  }

  #########################################################################

  # Get a field name
  method fieldname {name} {
    return fraM.fra$name.$name
  }

  # Get variable name associated with a field name
  method varname {name} {
    return [namespace current]::var$name
  }

  # Get values of entries passed (or set) in -tvar
  method vals {lwidgets} {
    set res [set vars [list]]
    foreach wl $lwidgets {
      set vv [my varname [my rootwname [lindex $wl 0]]]
      set attrs [lindex $wl 6]
      foreach t {-var -tvar} {
        # for widgets with a common variable (e.g. radiobuttons):
        if {[set p [string first "$t " $attrs]]>-1} {
          array set a $attrs
          set vv $a($t)
        }
      }
      if {[info exist $vv] && [lsearch $vars $vv]==-1} {
        lappend res [set $vv]
        lappend vars $vv
      }
    }
    return $res
  }

  # 1. Set contents of text fields (after creating them)
  # 2. Get contents of text fields (before exiting)
  method setgettexts {oper w iopts lwidgets} {
    if {$iopts==""} return
    foreach widg $lwidgets {
      set wname [lindex $widg 0]
      set name [my rootwname $wname]
      if {[string range $name 0 1]=="te"} {
        set vv [my varname $name]
        if {$oper=="set"} {
          $w.$wname replace 1.0 end [set $vv]
        } else {
          set $vv [string trimright [$w.$wname get 1.0 end]]
        }
      }
    }
  }

  #########################################################################
  # Append the <buttons> buttons to the <inplist> list
  # from the <pos> position of <neighbor> cell
  # and set its resulting values

  method appendButtons {inplist buttons neighbor pos} {

    upvar $inplist widlist
    set defb1 [set defb2 ""]
    foreach {but txt res} $buttons {
      if {$defb1==""} {
        set defb1 $but
      } elseif {$defb2==""} {
        set defb2 $but
      }
      lappend widlist [list $but $neighbor $pos 1 1 "-st we" \
        "-t \"$txt\" -com \"${_pdg(ns)}my res $_pdg(win).dia $res\""]
      set neighbor $but
      set pos L
    }
    set _pdg(defb1) $_pdg(win).dia.fra.$defb1
    set _pdg(defb2) $_pdg(win).dia.fra.$defb2
  }

  ###################################################################
  # Get line's positions

  method GetLine {txt ind} {

    set linestart [$txt index "$ind linestart"]
    set lineend   [expr {$linestart + 1.0}]
    return [list $linestart $lineend]
  }

  #########################################################################
  # Double a current line or a selection

  method DoubleText {{dobreak 1}} {

    set txt [my TexM]
    set err [catch {$txt tag ranges sel} sel]
    if {!$err && [llength $sel]==2} {
      lassign $sel pos pos2
      set pos3 "insert"  ;# single selection
    } else {
      lassign [my GetLine $txt insert] pos pos2  ;# current line
      set pos3 $pos2
    }
    set duptext [$txt get $pos $pos2]
    $txt insert $pos3 $duptext
    if {$dobreak} {return -code break}
  }

  #########################################################################
  # Delete a current line

  method DeleteLine {{dobreak 1}} {

    set txt [my TexM]
    lassign [my GetLine $txt insert] linestart lineend
    $txt delete $linestart $lineend
    if {$dobreak} {return -code break}
  }

  #########################################################################
  # Move a current line or lines of selection up/down

  method LinesMove {to {dobreak 1}} {

    proc NewRow {ind rn} {
      set i [string first . $ind]
      set row [string range $ind 0 $i-1]
      return [incr row $rn][string range $ind $i end]
    }
    set txt [my TexM]
    set err [catch {$txt tag ranges sel} sel]
    lassign [$txt index insert] pos  ;# position of caret
    if {[set issel [expr {!$err && [llength $sel]==2}]]} {
      lassign $sel pos1 pos2         ;# selection's start & end
      set l1 [expr {int($pos1)}]
      set l2 [expr {int($pos2)}]
      set lfrom [expr {$to>0 ? $l2+1 : $l1-1}]
      set lto   [expr {$to>0 ? $l1-1 : $l2-1}]
    } else {
      set lcurr [expr {int($pos)}]
      set lfrom [expr {$to>0 ? $lcurr+1 : $lcurr-1}]
      set lto   [expr {$to>0 ? $lcurr-1 : $lcurr-1}]
    }
    set lend [expr {int([$txt index end])}]
    if {$lfrom>0 && $lfrom<$lend} {
      incr lto
      lassign [my GetLine $txt $lfrom.0] linestart lineend
      set duptext [$txt get $linestart $lineend]
      $txt delete $linestart $lineend
      $txt insert $lto.0 $duptext
      ::tk::TextSetCursor $txt [NewRow $pos $to]
      if {$issel} {
        $txt tag add sel [NewRow $pos1 $to] [NewRow $pos2 $to]
      }
      if {$dobreak} {return -code break}
    }
  }

  #########################################################################
  # Initialize the search in the text (ctrlf=1 when called by Ctrl+F)

  method InitFindInText { {ctrlf 0} } {

    set txt [my TexM]
    if {$ctrlf} {  ;# Ctrl+F moves cursor 1 char ahead
      ::tk::TextSetCursor $txt [$txt index "insert -1 char"]
    }
    if {[set ${_pdg(ns)}PD::fnd] eq ""} {
      if {![catch {$txt tag ranges sel} seltxt]} {
        if {[set forword [expr {$seltxt eq ""}]]} {
          set pos  [$txt index "insert wordstart"]
          set pos2 [$txt index "insert wordend"]
          set seltxt [string trim [$txt get $pos $pos2]]
          if {![string is wordchar -strict $seltxt]} {
            # when cursor just at the right of word: take the word at the left
            set pos  [$txt index "insert -1 char wordstart"]
            set pos2 [$txt index "insert -1 char wordend"]
          }
        } else {
          lassign $seltxt pos pos2
        }
        catch {
          set seltxt [$txt get $pos $pos2]
          if {[set sttrim [string trim $seltxt]] ne ""} {
            if {$forword} {set seltxt $sttrim}
            set ${_pdg(ns)}PD::fnd $seltxt
          }
        }
      }
    }
  }

  #########################################################################
  # Find string in text (donext=1 means 'from current position')

  method FindInText {{donext 0}} {

    set txt [my TexM]
    set sel [set ${_pdg(ns)}PD::fnd]
    if {$donext} {
      set pos [$txt index "[$txt index insert] + 1 chars"]
      set pos [$txt search -- $sel $pos end]
    } else {
      set pos ""
    }
    if {![string length "$pos"]} {
      set pos [$txt search -- $sel 1.0 end]
    }
    if {[string length "$pos"]} {
      ::tk::TextSetCursor $txt $pos
      $txt tag add sel $pos [$txt index "$pos + [string length $sel] chars"]
      focus $txt
    } else {
      bell -nice
    }
  }

  #########################################################################
  # Make a query (or simple message) and get the user's response.
  # Mandatory arguments:
  #   icon    - icon name (info, warn, ques, err)
  #   ttl     - title
  #   msg     - message
  #   buttons - list of triples "button name, text, result"
  #   defb    - default button (OK, YES, NO, CANCEL, RETRY, ABORT)
  #   inopts  - options for input dialog
  # Optional arguments:
  #   args:
  #     -checkbox text (-ch text) - makes the checkbox's text visible
  #     -geometry +x+y (-g +x+y)  - sets the geometry of dialog
  #     -color cval    (-c cval)  - sets the color of message
  #     -family... -size... etc. options of label widget
  # If "geometry" argument was passed (even "") the Query procedure
  # returns a list with chosen button's number and new geometry.
  # Otherwise it returns only chosen button's number.

  method Query {icon ttl msg buttons defb inopts argov {precom ""}} {

    if {[winfo exists $_pdg(win).dia]} {
      return 0
    }
    # remember the focus (to restore it after closing the dialog)
    set oldfocused [focus]
    set newfocused ""
    # get the options of dialog:
    #  - checkbox text (if given, enable the checkbox)
    #  - geometry of dialog window
    #  - color of labels
    lassign "" chmsg geometry optsLabel optsMisc optsFont optsFontM \
               rotext root head optsHead hsz binds postcom
    set optsTags 0
    set wasgeo [set textmode [set ontop 0]]
    set readonly [set hidefind 1]
    set curpos "1.0"
    set cc ""
    set themecolors ""
    set ${_pdg(ns)}PD::ch 0
    foreach {opt val} {*}$argov {
      if {$opt in {-c -color -fg -bg -fgS -bgS -cc -hfg -hbg}} {
        # take colors by their theme names
        if {[info exist $val]} {set val [set $val]}
      }
      switch $opt {
        -H -
        -head {
          set head [string map {$ \$ \" \'\'} $val]
        }
        -ch -
        -checkbox {set chmsg "$val"}
        -g -
        -geometry {
          set geometry $val
          set wasgeo 1
          lassign [split $geometry +] - gx gy
        }
        -c -
        -color {append optsLabel " -foreground {$val}"}
        -t -
        -text {set textmode $val}
        -tags {
          set optsTags 1
          upvar 2 $val tags
        }
        -ro -
        -readonly {set readonly [set hidefind $val]}
        -rotext {set hidefind 0; set rotext $val}
        -w -
        -width {set charwidth $val}
        -h -
        -height {set charheight $val}
        -fg {append optsMisc " -foreground {$val}"}
        -bg {append optsMisc " -background {$val}"}
        -fgS {append optsMisc " -selectforeground {$val}"}
        -bgS {append optsMisc " -selectbackground {$val}"}
        -cc {append optsMisc " -insertbackground {$val}"}
        -root {set root " -root $val"}
        -pos {set curpos "$val"}
        -hfg {append optsHead " -foreground {$val}"}
        -hbg {append optsHead " -background {$val}"}
        -hsz {append hsz " -size $val"}
        -focus {set newfocused "$val"}
        -theme {append themecolors " {$val}"}
        -ontop {set ontop 1}
        -post {set postcom $val}
        default {
          append optsFont " $opt $val"
          if {$opt!="-family"} {
            append optsFontM " $opt $val"
          }
        }
      }
    }
    set optsFont [string trim $optsFont]
    set optsHeadFont $optsFont
    if {$optsFont != ""} {
      if {[string first "-size " $optsFont]<0} {
        append optsFont " -size 12"
      }
      if {[string first "-size " $optsFontM]<0} {
        append optsFontM " -size 12"
      }
      if {[string first "-family " $optsFont]>=0} {
        set optsFont "-font \"$optsFont"
      } else {
        set optsFont "-font \"-family Helvetica $optsFont"
      }
      set optsFontM "-font \"-family Mono $optsFontM\""
      append optsFont "\""
    } else {
      set optsFont "-font \"-size 12\""
      set optsFontM "-font \"-size 12\""
    }
    # layout: add the icon
    if {$icon!="" && $icon!="-"} {
      set widlist [list [list labBimg - - 99 1 \
      "-st n -pady 7" "-image ${_pdg(ns)}PD::img$icon"]]
      set prevl labBimg
    } else {
      set widlist [list [list labimg - - 99 1]]
      set prevl labimg ;# this trick would hide the prevw at all
    }
    set prevw labBimg
    if {$head!=""} {
      # set the dialog's heading (-head option)
      if {$optsHeadFont!="" || $hsz!=""} {
        set optsHeadFont [string trim "$optsHeadFont $hsz"]
        set optsHeadFont "-font \"$optsHeadFont\""
      }
      set optsFont ""
      set prevp "L"
      set head [string map {\\n \n} $head]
      foreach lh [split $head "\n"] {
        set labh "labheading[incr il]"
        lappend widlist [list $labh $prevw $prevp 1 99 "-st we" \
          "-t \"$lh\" $optsHeadFont $optsHead"]
        set prevw [set prevh $labh]
        set prevp "T"
      }
    } else {
      # add the upper (before the message) blank frame
      lappend widlist [list h_1 $prevw L 1 1 "-pady 3"]
      set prevw [set prevh h_1]
      set prevp "T"
    }
    # add the message lines
    set il [set maxw 0]
    if {$readonly} {
      # only for messaging (not for editing):
      set msg [string map {\\n \n} $msg]
    }
    foreach m [split $msg \n] {
      set m [string map {$ \$ \" \'\'} $m]
      if {[set mw [string length $m]] > $maxw} {
        set maxw $mw
      }
      incr il
      if {!$textmode} {
        lappend widlist [list labB$il $prevw $prevp 1 7 \
          "-st w -rw 1" "-t \"$m \" $optsLabel $optsFont"]
      }
      set prevw labB$il
      set prevp T
    }
    if {$inopts!=""} {
      # here are widgets for input (in fraM frame)
      set io0 [lindex $inopts 0]
      lset io0 1 $prevh
      lset inopts 0 $io0
      foreach io $inopts {
        lappend widlist $io
      }
      set prevw fraM
    } elseif {$textmode} {
      # here is text widget (in fraM frame)
      proc vallimits {val lowlimit isset limits} {
        set val [expr {max($val,$lowlimit)}]
        if {$isset} {
          upvar $limits lim
          lassign $lim l1 l2
          set val [expr {min($val,$l1)}] ;# forced low
          if {$l2 ne ""} {set val [expr {max($val,$l2)}]} ;# forced high
        }
        return $val
      }
      set il [vallimits $il 1 [info exists charheight] charheight]
      set maxw [vallimits $maxw 20 [info exists charwidth] charwidth]
      rename vallimits ""
      lappend widlist [list fraM $prevh T 10 7 "-st nswe -pady 3 -rw 1"]
      lappend widlist {TexM - - 1 7 {pack -side left -expand 1 -fill both -in \
        $_pdg(win).dia.fra.fraM} {-h $il -w $maxw $optsFontM $optsMisc -wrap word}}
      lappend widlist {sbv texM L 1 1 {pack -in $_pdg(win).dia.fra.fraM}}
      set prevw fraM
    }
    # add the lower (after the message) blank frame
    lappend widlist [list h_2 $prevw T 1 1 "-pady 0 -ipady 0 -csz 0"]
    # underline the message
    lappend widlist [list seh $prevl T 1 99 "-st ew"]
    # add left frames and checkbox (before buttons)
    lappend widlist [list h_3 seh T 1 1 "-pady 0 -ipady 0 -csz 0"]
    if {$chmsg == ""} {
      if {$textmode} {
        if {![info exists ${_pdg(ns)}PD::fnd]} {
          set ${_pdg(ns)}PD::fnd ""
        }
        if {!$hidefind} {
          lappend widlist [list labfnd h_3 L 1 1 "-st e" "-t {Find:}"]
          lappend widlist [list Entfind labfnd L 1 1 \
            "-st ew -cw 1" "-tvar ${_pdg(ns)}PD::fnd -w 10"]
          lappend widlist [list labfnd2 Entfind L 1 1 "-cw 2" "-t {}"]
          lappend widlist [list h__ labfnd2 L 1 1]
        } else {
          lappend widlist [list h__ h_3 L 1 4 "-cw 1"]
        }
        set binds \
          "bind \[[self] Entfind\] <Return> {[self] FindInText}
           bind \[[self] Entfind\] <KP_Enter> {[self] FindInText}
           bind \[[self] Entfind\] <FocusIn> {\[[self] Entfind\] selection range 0 end}
           bind $_pdg(win).dia <F3> {[self] FindInText 1}
           bind $_pdg(win).dia <Control-f> \"[self] InitFindInText 1; focus \[[self] Entfind\]\"
           bind $_pdg(win).dia <Control-F> \"[self] InitFindInText 1; focus \[[self] Entfind\]\"
           bind \[[self] TexM\] <Button-3> \{
             tk_popup \[[self] TexM\].popupMenu %X %Y \}
           set pop \[[self] TexM\].popupMenu"
        if {$readonly} {
          append binds "
            menu \$pop
             \$pop add command -accelerator Ctrl+C -label \"Copy\" \\
              -command \"event generate \[[self] TexM\] <<Copy>>\"
             \$pop add separator
             \$pop add command -accelerator Ctrl+F -label \"Find first\" \\
              -command \"[self] InitFindInText; focus \[[self] Entfind\]\"
             \$pop add command -accelerator F3 -label \"Find next\" \\
              -command \"[self] FindInText 1\"
             \$pop add separator
             \$pop add command -accelerator Esc -label \"Exit\" \\
              -command \"\[[self] Pdg defb1\] invoke\"
          "
        } else {
          # make bindings and popup menu for text widget
          append binds "
            bind \[[self] TexM\] <Control-d> {[self] DoubleText}
            bind \[[self] TexM\] <Control-D> {[self] DoubleText}
            bind \[[self] TexM\] <Control-y> {[self] DeleteLine}
            bind \[[self] TexM\] <Control-Y> {[self] DeleteLine}
            bind \[[self] TexM\] <Alt-Up>    {[self] LinesMove -1}
            bind \[[self] TexM\] <Alt-Down>  {[self] LinesMove +1}
            menu \$pop
             \$pop add command -accelerator Ctrl+X -label \"Cut\" \\
              -command \"event generate \[[self] TexM\] <<Cut>>\"
             \$pop add command -accelerator Ctrl+C -label \"Copy\" \\
              -command \"event generate \[[self] TexM\] <<Copy>>\"
             \$pop add command -accelerator Ctrl+V -label \"Paste\" \\
              -command \"event generate \[[self] TexM\] <<Paste>>\"
             \$pop add separator
             \$pop add command -accelerator Ctrl+D -label \"Double line(s)\" \\
              -command \"[self] DoubleText 0\"
             \$pop add command -accelerator Ctrl+Y -label \"Delete a line\" \\
              -command \"[self] DeleteLine 0\"
             \$pop add command -accelerator Alt+Up -label \"Line(s) up\" \\
              -command \"[self] LinesMove -1 0\"
             \$pop add command -accelerator Alt+Down -label \"Line(s) down\" \\
              -command \"[self] LinesMove +1 0\"
             \$pop add separator
             \$pop add command -accelerator Ctrl+F -label \"Find first\" \\
              -command \"[self] InitFindInText; focus \[[self] Entfind\]\"
             \$pop add command -accelerator F3 -label \"Find next\" \\
              -command \"[self] FindInText 1\"
             \$pop add separator
             \$pop add command -accelerator Ctrl+W -label \"Save and exit\" \\
              -command \"\[[self] Pdg defb1\] invoke\"
            "
          oo::objdefine [self] export DoubleText DeleteLine LinesMove
        }
        oo::objdefine [self] export FindInText InitFindInText Pdg
      } else {
        lappend widlist [list h__ h_3 L 1 4 "-cw 1"]
      }
    } else {
      lappend widlist [list chb h_3 L 1 1 \
        "-st w" "-t {$chmsg} -var ${_pdg(ns)}PD::ch"]
      lappend widlist [list h_ chb L 1 1]
      lappend widlist [list sev h_ L 1 1 "-st nse -cw 1"]
      lappend widlist [list h__ sev L 1 1]
    }
    # add the buttons
    my appendButtons widlist $buttons h__ L
    # make & display the dialog's window
    set wtop [my makeWindow $_pdg(win).dia.fra $ttl]
    set widlist [my window $_pdg(win).dia.fra $widlist]
    if {$precom!=""} {
      {*}$precom  ;# actions before showModal
    }
    if {$themecolors!=""} {
      # themed colors are set as sequentional '-theme' args
      if {[llength $themecolors]==2} {
        # when only 2 main fb/bg colors are set (esp. for TKE)
        lassign [my parseOptionsFile 0 $optsMisc -foreground black \
          -background white -selectforeground black \
          -selectbackground gray -insertbackground black] restcolors
        # the rest colors should be added, namely:
        #   tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr
        foreach rci {0 1 2 3 3 1 4 4} {
          lappend themecolors [lindex $restcolors [expr {$rci*2+1}]]
        }
      }
      catch {
        my themingWindow $_pdg(win).dia {*}$themecolors
      }
    }
    # after creating widgets - show dialog texts if any
    my setgettexts set $_pdg(win).dia.fra $inopts $widlist
    set focusnow $_pdg(win).dia.fra.$defb
    if {$textmode} {
      if {!$optsTags} {set tags [list]}
      my displayTaggedText [my TexM] msg $tags
      [my TexM] edit reset
      if {$defb == "butTEXT"} {
        if {$readonly} {
          set focusnow [my Pdg defb1]
        } else {
          set focusnow [my TexM]
          catch "::tk::TextSetCursor $focusnow $curpos"
          foreach k {w W} \
            {catch "bind $focusnow <Control-$k> {[my Pdg defb1] invoke; break}"}
        }
      }
      if {$readonly} {
        rename "::[my TexM]" "::[my TexM].internal"
        proc "::[my TexM]" {args} "
            switch -exact -- \[lindex \$args 0\] \{
                insert \{\}
                delete \{\}
                replace \{\}
                default \{
                    return \[eval ::[my TexM].internal \$args\]
                \}
            \}"
      }
    }
    if {$newfocused!=""} {
      foreach w $widlist {
        lassign $w widname
        if {[string match $newfocused $widname]} {
          set focusnow $_pdg(win).dia.fra.$widname
        }
      }
    }
    catch "$binds"
    my showModal $_pdg(win).dia \
      -focus $focusnow -geometry $geometry {*}$root -ontop $ontop
    oo::objdefine [self] unexport FindInText InitFindInText DoubleText DeleteLine Pdg
    set pdgeometry [winfo geometry $_pdg(win).dia]
    # the dialog's result is defined by "pave res" + checkbox's value
    set res [my res $_pdg(win).dia]
    if {$res && [set ${_pdg(ns)}PD::ch]} {
      incr res 10
    }
    if {$textmode && !$readonly} {
      set focusnow [my TexM]
      set textcont [$focusnow get 1.0 end]
      if {$res && $postcom!=""} {
        {*}$postcom textcont [my TexM] ;# actions after showModal
      }
      set textcont " [$focusnow index insert] $textcont"
    } else {
      set textcont ""
    }
    if {$res && $inopts!=""} {
      my setgettexts get $_pdg(win).dia.fra $inopts $widlist
      set inopts " [my vals $widlist]"
    } else {
      set inopts ""
    }
    if {$textmode && $rotext ne ""} {
      set $rotext [string trimright [[my TexM] get 1.0 end]]
    }
    destroy $_pdg(win).dia
    # pause a bit and restore the old focus
    if {[winfo exists $oldfocused]} {
      after 50 [list focus $oldfocused]
    } else {
      after 50 list focus .
    }
    if {$wasgeo} {
      lassign [split $pdgeometry x+] w h x y
      if {abs($x-$gx)<30} {set x $gx}
      if {abs($y-$gy)<30} {set y $gy}
      return [list $res ${w}x${h}+${x}+${y} $textcont [string trim $inopts]]
    }
    return "$res$textcont$inopts"

  }

}

