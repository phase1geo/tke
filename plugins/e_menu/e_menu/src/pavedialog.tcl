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

    # dialogs are bound to "$win" window e.g. ".mywin", default "" means .
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

    catch "destroy $pWindow.pavedlg"
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
    return [my Query $icon $ttl $msg {butOK OK 1} butOK {*}$args]
  }

  method okcancel {icon ttl msg {defb OK} args} {
    return [my Query $icon $ttl $msg \
      {butOK OK 1 butCANCEL Cancel 0} but$defb {*}$args]
  }

  method yesno {icon ttl msg {defb YES} args} {
    return [my Query $icon $ttl $msg \
      {butYES Yes 1 butNO No 2} but$defb {*}$args]
  }

  method yesnocancel {icon ttl msg {defb YES} args} {
    return [my Query $icon $ttl $msg \
      {butYES Yes 1 butNO No 2 butCANCEL Cancel 0} but$defb {*}$args]
  }

  method retrycancel {icon ttl msg {defb RETRY} args} {
    return [my Query $icon $ttl $msg \
      {butRETRY Retry 1 butCANCEL Cancel 0} but$defb {*}$args]
  }

  method abortretrycancel {icon ttl msg {defb RETRY} args} {
    return [my Query $icon $ttl $msg \
      {butABORT Abort 1 butRETRY Retry 2 butCANCEL \
      Cancel 0} but$defb {*}$args]
  }

  method misc {icon ttl msg butts {defb ""} args} {
    # butts is a list of pairs "title of button" "number/ID of button"
    foreach {nam num} $butts {
      lappend pave_msc_bttns but$num "$nam" $num
      if {$defb==""} {
        set defb $num
      }
    }
    return [my Query $icon $ttl $msg $pave_msc_bttns but$defb {*}$args]
  }

  #########################################################################
  # Append the <buttons> buttons to the <inplist> list
  # from the <pos> position of <neighbor> cell
  # and set its resulting values in <win> window.

  method appendButtons {win inplist buttons neighbor pos} {

    upvar $inplist widlist
    set defb1 ""
    foreach {but txt res} $buttons {
      if {$defb1==""} {
        set defb1 $but
      }
      lappend widlist [list $but $neighbor $pos 1 1 "-st we" \
        "-t \"$txt\" -com \"${nsd}my res $win $res\""]
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
  # Optional arguments:
  #   args:
  #     -checkbox text (-ch text) - makes the checkbox's text visible
  #     -geometry +x+y (-g +x+y)  - sets the geometry of dialog
  #     -color cval    (-c cval)  - sets the color of message
  #     -family... -size... etc. options of label widget
  # If "geometry" argument was passed (even "") the Query procedure
  # returns a list with chosen button's number and new geometry.
  # Otherwise it returns only chosen button's number.

  method Query {icon ttl msg buttons defb args} {

    if {[winfo exists $pWindow.pavedlg]} {
      return 0
    }
    # remember the focus (to restore it after closing the dialog)
    set oldfocused [focus]
    # get the options of dialog:
    #  - checkbox text (if given, enable the checkbox)
    #  - geometry of dialog window
    #  - color of labels
    set optsLabel [set chmsg [set geometry [set optsMisc [set optsState ""]]]]
    set optsTags 0
    set optsFont "-font \"-family Sans"
    set root ""
    set wasgeo [set textmode 0]
    foreach {opt val} $args {
      switch $opt {
        -ch -
        -checkbox { set chmsg $val}
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
        -root {set root " -root $val"}
        default {append optsFont " $opt $val"}
      }
    }
    append optsFont "\""
    # add the icon to the layout
    set widlist [list [list laBimg - - 99 1 \
      "-st n -pady 7" "-image ${nsd}paveD::img$icon"]]
    # add the upper (before the message) blank frame
    lappend widlist [list h_1 laBimg L 1 1 "-pady 3"]
    set prevw "h_1"
    set prevp "T"
    # add the message lines
    set il [set maxl 0]
    foreach m [split $msg \n] {
      set m [string map {$ \$ \" \'\'} $m]
      if {[set ml [string length $m]] > $maxl} {
        set maxl $ml
      }
      incr il
      if {!$textmode} {
        lappend widlist [list laB$il $prevw $prevp 1 7 \
          "-st w -rw 1" "-t \"$m \" $optsLabel $optsFont"]
      }
      set prevw laB$il
      set prevp T
    }
    if {$textmode} {
      set maxl [expr min($maxl,20)]
      set maxl [expr max($maxl,2)]
      if {[info exists charheight]} {set il $charheight}
      if {[info exists charwidth]} {set maxl $charwidth}
      lappend widlist {fraM h_1 T 10 7 "-st nswe -pady 3 -rw 1"}
      lappend widlist {texM - - 1 7 {pack -side left -expand 1 -fill both -in $pWindow.pavedlg.fraM} \
        {-h $il -w $maxl $optsFont $optsMisc -wrap word}}
      lappend widlist {sbv texM L 1 1 {pack -in $pWindow.pavedlg.fraM}}
      set prevw fraM
    }
    # add the lower (after the message) blank frame
    lappend widlist [list h_2 $prevw T 1 1 "-st w -pady 3"]
    # underline the message
    lappend widlist [list seh laBimg T 1 99]
    # add left frames and checkbox (before buttons)
    lappend widlist [list h_3 seh T 1 1]
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
    set defb1 [my appendButtons $pWindow.pavedlg widlist $buttons h__ L]
    # display the dialog's window
    set ${nsd}paveD::ch 0
    my makeWindow $pWindow.pavedlg $ttl
    my window $pWindow.pavedlg $widlist
    set focusnow $pWindow.pavedlg.$defb
    if {$textmode} {
      if {!$optsTags} {set tags [list]}
      my displayTaggedText $pWindow.pavedlg.texM msg $tags
      if {$optsState==""} {
        set optsState "-state disabled"  ;# by default
      }
      if {$defb == "butTEXT"} {
        if {$optsState == "-state normal"} {
          set focusnow $pWindow.pavedlg.texM
          ::tk::TextSetCursor $focusnow 1.0
        } else {
          set focusnow $pWindow.pavedlg.$defb1
        }
      }
      $pWindow.pavedlg.texM configure {*}$optsState
    }
    my showModal $pWindow.pavedlg -focus $focusnow -geometry $geometry {*}$root
    set pdgeometry [winfo geometry $pWindow.pavedlg]
    if {$textmode && $optsState == "-state normal"} {
      set textmode " [$pWindow.pavedlg.texM get 1.0 end]"
    } else {
      set textmode ""
    }
    destroy $pWindow.pavedlg
    # the dialog's result is defined by "pave res" + checkbox's value
    set res [my res $pWindow.pavedlg]
    if {$res && [set ${nsd}paveD::ch]} {
      incr res 10
    }
    # pause a bit and restore the old focus
    if {[winfo exists $oldfocused]} {
      after 50 [list focus $oldfocused]
    } elseif {[winfo exists $pWindow]} {
      after 50 [list focus $pWindow]
    }
    if {$wasgeo} {
      lassign [split $pdgeometry x+] w h x y
      if {abs($x-$gx)<30} {set x $gx}
      if {abs($y-$gy)<30} {set y $gy}
      return [list $res ${w}x${h}+${x}+${y} $textmode]
    }
    return $res$textmode

  }

}

