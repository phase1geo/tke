###########################################################################
#
# This script contains the PaveDialog class that provides a batch of
# standard dialogs with advanced features.
#
# Use:
#   source pavedialog.tcl
#   ...
#   catch {pdlg destroy}
#   PaveDialog create pdlg win
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
#     input
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
###########################################################################

package require Tk

source [file join [file dirname [info script]] paveme.tcl]

oo::class create PaveDialog {

  superclass PaveMe

  variable pWindow
  variable nsd

  constructor {{win ""} {pavedir ""}} {

    # dialogs are bound to "$win" window e.g. ".mywin.fra", default "" means .
    set pWindow $win
    set nsd [namespace current]::
    namespace eval ${nsd}paveD {}  ;# made in oo::
    if {$pavedir==""} {
      set pavedir [file normalize [file dirname [info script]]]
    }
    foreach icon {err info warn ques} {
      image create photo ${nsd}paveD::img$icon \
        -file [file join $pavedir $icon.png]
    }
    next

  }

  destructor {

    catch "destroy $pWindow.dia"
    catch "namespace delete ${nsd}paveD"

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
  #  input            - dialog with miscellaneous widgets to input data
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

  method ok {icon ttl msg args} {
    return [my Query $icon $ttl $msg {butOK OK 1} butOK {} {*}$args]
  }

  method okcancel {icon ttl msg {defb OK} args} {
    return [my Query $icon $ttl $msg \
      {butOK OK 1 butCANCEL Cancel 0} but$defb {} {*}$args]
  }

  method yesno {icon ttl msg {defb YES} args} {
    return [my Query $icon $ttl $msg \
      {butYES Yes 1 butNO No 2} but$defb {} {*}$args]
  }

  method yesnocancel {icon ttl msg {defb YES} args} {
    return [my Query $icon $ttl $msg \
      {butYES Yes 1 butNO No 2 butCANCEL Cancel 0} but$defb {} {*}$args]
  }

  method retrycancel {icon ttl msg {defb RETRY} args} {
    return [my Query $icon $ttl $msg \
      {butRETRY Retry 1 butCANCEL Cancel 0} but$defb {} {*}$args]
  }

  method abortretrycancel {icon ttl msg {defb RETRY} args} {
    return [my Query $icon $ttl $msg \
      {butABORT Abort 1 butRETRY Retry 2 butCANCEL \
      Cancel 0} but$defb {} {*}$args]
  }

  method misc {icon ttl msg butts {defb ""} args} {
    # butts is a list of pairs "title of button" "number/ID of button"
    foreach {nam num} $butts {
      lappend pave_msc_bttns but$num "$nam" $num
      if {$defb==""} {
        set defb $num
      }
    }
    return [my Query $icon $ttl $msg $pave_msc_bttns but$defb {} {*}$args]
  }

  method input {icon ttl iopts args} {
    # iopts is a list of input options:
    #  - name of field
    #  - prompt (and possibly gridopts, widopts) of field
    #  - options for value of field
    set pady "-pady 2"
    lappend inopts [list fraM + T 1 98 "-st new $pady -rw 1"]
    foreach {name prompt valopts} [list {*}$iopts] {
      lassign $prompt prompt gopts attrs
      set gopts "$pady $gopts"
      if {[set typ [string range $name 0 1]]=="h_" || $typ=="se"} {
        lappend inopts [list fraM.$name - - - - "pack -fill x $gopts"]
        continue
      }
      set tvar "-tvar"
      switch $typ {
        ch { set tvar "-var" }
        sp { set gopts "$gopts -expand 0 -side left"}
      }

      if {[string match "*Mono*" "[font families]"]} {
        set Mfont "Mono"
      } else {
        set Mfont "Courier"
      }
      lappend inopts [list fraM.fra$name - - - - "pack -expand 1 -fill both"]
      lappend inopts [list fraM.fra$name.labB$name - - - - "pack -side left -anchor nw -padx 3" "-t \"$prompt\" -font \"-family $Mfont -size 10\""]
      set vv [my varname $name]
      set ff [my fieldname $name]
      switch $typ {
        cb {
          if {![info exist $vv]} {lassign $valopts $vv}
          foreach vo [lrange $valopts 1 end] {
            lappend vlist $vo
          }
          lappend inopts [list $ff - - - - "pack -fill x $gopts" "-tvar $vv -value \{\{$vlist\}\} $attrs"]
        }
        ra {
          if {![info exist $vv]} {lassign $valopts $vv}
          set padx 0
          foreach vo [lrange $valopts 1 end] {
            set name $name
            lappend inopts [list $ff[incr nnn] - - - - "pack -side left $gopts -padx $padx" "-var $vv -value \"$vo\" -t \"$vo\" $attrs"]
            set padx [expr {$padx ? 0 : 9}]
          }
        }
        te {
          if {![info exist $vv]} {set $vv [string map {\\n \n} $valopts]}
          lappend inopts [list $ff - - - - "pack -side left -expand 1 -fill both $gopts" "$attrs"]
          lappend inopts [list fraM.fra$name.sbv$name $ff L - - "pack -fill y"]
        }
        default {
          lappend inopts [list $ff - - - - "pack -side right -expand 1 -fill x $gopts" "$tvar $vv $attrs"]
          if {$vv!=""} {
            if {![info exist $vv]} {lassign $valopts $vv}
          }
        }
      }
      if {![info exist $vv]} {set $vv ""}
    }
    if {![string match "*-focus *" $args]} {
      # find 1st entry/text to be focused
      foreach io $iopts {
        if {[set _ [string range [set n [lindex $io 0]] 0 1]]=="en" || $_=="te"} {
          set args "$args -focus *$n"
          break
        }
        if {$_=="fi" || $_=="di" || $_=="fo" || $_=="cl"} {
          set args "$args -focus *ent$n"
          break
        }
      }
    }
    return [my Query $icon $ttl {} {butOK OK 1 butCANCEL Cancel 0} butOK \
      $inopts {*}$args]
  }

  #########################################################################
  #
  # Methods for input dialog:

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
    set defb1 ""
    foreach {but txt res} $buttons {
      if {$defb1==""} {
        set defb1 $but
      }
      lappend widlist [list $but $neighbor $pos 1 1 "-st we" \
        "-t \"$txt\" -com \"${nsd}my res $pWindow.dia $res\""]
      set neighbor $but
      set pos L
    }
    return $defb1

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

  method Query {icon ttl msg buttons defb inopts args} {

    if {[winfo exists $pWindow.dia]} {
      return 0
    }
    # remember the focus (to restore it after closing the dialog)
    set oldfocused [focus]
    set newfocused ""
    # get the options of dialog:
    #  - checkbox text (if given, enable the checkbox)
    #  - geometry of dialog window
    #  - color of labels
    set chmsg [set geometry [set optsLabel [set optsMisc [set optsState ""]]]]
    set root [set head [set optsHead [set hsz ""]]]
    set optsTags 0
    set optsFont [set optsFontMono ""]
    set wasgeo [set textmode 0]
    set curpos "1.0"
    set cc ""
    foreach {opt val} $args {
      switch $opt {
        -H -
        -head {set head [string map {$ \$ \" \'\'} $val]}
        -ch -
        -checkbox {set chmsg $val}
        -g -
        -geometry {
          set geometry $val
          set wasgeo 1
          lassign [split $geometry +] - gx gy
        }
        -c -
        -color {append optsLabel " -foreground $val"}
        -t -
        -text {set textmode 1}
        -tags {
          set optsTags 1
          upvar 2 $val tags
        }
        -ro -
        -readonly {
          if {$val} {
            set optsState "-state disabled"
          } else {
            set optsState "-state normal"
          }
        }
        -w -
        -width {set charwidth $val}
        -h -
        -height {set charheight $val}
        -fg {append optsMisc " -foreground $val"}
        -bg {append optsMisc " -background $val"}
        -cc {set cc "$val"}
        -root {set root " -root $val"}
        -pos {set curpos "$val"}
        -hfg {append optsHead " -foreground $val"}
        -hbg {append optsHead " -background $val"}
        -hsz {append hsz " -size $val"}
        -focus {set newfocused "$val"}
        default {
          append optsFont " $opt $val"
          if {$opt!="-family"} {
            append optsFontMono " $opt $val"
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
      if {[string first "-size " $optsFontMono]<0} {
        append optsFontMono " -size 12"
      }
      if {[string first "-family " $optsFont]>=0} {
        set optsFont "-font \"$optsFont"
      } else {
        set optsFont "-font \"-family Helvetica $optsFont"
      }
      set optsFontMono "-font \"-family Mono $optsFontMono\""
      append optsFont "\""
    } else {
      set optsFont "-font \"-size 12\""
      set optsFontMono "-font \"-size 12\""
    }
    # add the icon to the layout
    if {$icon!=""} {
      set widlist [list [list labBimg - - 99 1 \
      "-st n -pady 7" "-image ${nsd}paveD::img$icon"]]
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
    set il [set maxl 0]
    foreach m [split $msg \n] {
      set m [string map {$ \$ \" \'\'} $m]
      if {[set ml [string length $m]] > $maxl} {
        set maxl $ml
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
      set maxl [expr min($maxl,20)]
      set maxl [expr max($maxl,2)]
      if {[info exists charheight]} {set il $charheight}
      if {[info exists charwidth]} {set maxl $charwidth}
      lappend widlist [list fraM $prevh T 10 7 "-st nswe -pady 3 -rw 1"]
      lappend widlist {texM - - 1 7 {pack -side left -expand 1 -fill both -in \
        $pWindow.dia.fra.fraM} {-h $il -w $maxl $optsFontMono $optsMisc -wrap word}}
      lappend widlist {sbv texM L 1 1 {pack -in $pWindow.dia.fra.fraM}}
      set prevw fraM
    }
    # add the lower (after the message) blank frame
    lappend widlist [list h_2 $prevw T 1 1 "-pady 0 -ipady 0 -csz 0"]
    # underline the message
    lappend widlist [list seh $prevl T 1 99 "-st ew"]
    # add left frames and checkbox (before buttons)
    lappend widlist [list h_3 seh T 1 1 "-pady 0 -ipady 0 -csz 0"]
    if {$chmsg == ""} {
      lappend widlist [list h__ h_3 L 1 4 "-cw 1"]
    } else {
      lappend widlist [list chb h_3 L 1 1 "-st w" "-t \"$chmsg\" \
        -variable ${nsd}paveD::ch"]
      lappend widlist [list h_ chb L 1 1]
      lappend widlist [list sev h_ L 1 1 "-st nse -cw 1"]
      lappend widlist [list h__ sev L 1 1]
    }
    # add the buttons
    set defb1 [my appendButtons widlist $buttons h__ L]
    # display the dialog's window
    set ${nsd}paveD::ch 0
    set wtop [my makeWindow $pWindow.dia.fra $ttl]
    set widlist [my window $pWindow.dia.fra $widlist]
    # after creating widgets - show dialog texts if any
    my setgettexts set $pWindow.dia.fra $inopts $widlist
    set focusnow $pWindow.dia.fra.$defb
    if {$textmode} {
      if {!$optsTags} {set tags [list]}
      my displayTaggedText $pWindow.dia.fra.texM msg $tags
      if {$optsState==""} {
        set optsState "-state disabled"  ;# by default
      }
      if {$defb == "butTEXT"} {
        if {$optsState == "-state normal"} {
          set focusnow $pWindow.dia.fra.texM
          catch "::tk::TextSetCursor $focusnow $curpos"
          catch "bind $focusnow <Control-w> {$pWindow.dia.fra.$defb1 invoke}"
        } else {
          set focusnow $pWindow.dia.fra.$defb1
        }
      }
      if {$cc!=""} {
        append optsState " -insertbackground $cc"
      }
      $pWindow.dia.fra.texM configure {*}$optsState
    }
    if {$newfocused!=""} {
      foreach w $widlist {
        lassign $w widname
        if {[string match $newfocused $widname]} {
          set focusnow $pWindow.dia.fra.$widname
        }
      }
    }
    my showModal $pWindow.dia -focus $focusnow -geometry $geometry {*}$root
    set pdgeometry [winfo geometry $pWindow.dia.fra]
    if {$textmode && [string first "-state normal" $optsState]>=0} {
      set textmode " [$focusnow index insert] [$focusnow get 1.0 end]"
    } else {
      set textmode ""
    }
    # the dialog's result is defined by "pave res" + checkbox's value
    set res [my res $pWindow.dia]
    if {$res && [set ${nsd}paveD::ch]} {
      incr res 10
    }
    if {$res && $inopts!=""} {
      my setgettexts get $pWindow.dia.fra $inopts $widlist
      set inopts " [my vals $widlist]"
    } else {
      set inopts ""
    }
    destroy $pWindow.dia
    # pause a bit and restore the old focus
    if {[winfo exists $oldfocused]} {
      after 50 [list focus $oldfocused]
    } elseif {[winfo exists $pWindow.dia]} {
      after 50 [list focus $pWindow.dia]
    }
    if {$wasgeo} {
      lassign [split $pdgeometry x+] w h x y
      if {abs($x-$gx)<30} {set x $gx}
      if {abs($y-$gy)<30} {set y $gy}
      return [list $res ${w}x${h}+${x}+${y} $textmode $inopts]
    }
    return "$res$textmode$inopts"

  }

}

