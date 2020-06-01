###########################################################################
#
# This script contains the APaveInput class that allows:
#   - to create input dialogs
#   - to view/edit text files
#
# Use for input dialogs:
#   package require apave
#   ::apave::APaveInput create pinp $win
#   pinp input $icon $ttl $iopts $args
# where:
#   win     - window's path
#   icon    - window's icon ("" or "-" means 'no icon')
#   ttl     - title of window
#   iopts   - list of input options:
#     - name of field
#     - prompt (and possibly gridopts, widopts) of field
#     - options for value of field
#   args - APaveDialog options
#
# Use for editing files:
#   package require apave
#   ::apave::APaveInput create pinp $win
#   pinp editfile $fname $fg $bg $cc $prepost $args
# where:
#   fname - name of edited file
#   fg, bg, cc - colors of background, foreground and cursor
#   prepost - optional command (or "") to be executed before editing
#   args - optional arguments of text widget
#
# See test_pavedialog.tcl for the detailed examples of use.
#
###########################################################################

package require Tk

package provide apave 2.9b4

source [file join [file dirname [info script]] apavedialog.tcl]

namespace eval ::apave {
}

oo::class create ::apave::APaveInput {

  superclass ::apave::APaveDialog

  variable _pav
  variable _pdg
  variable _savedvv

  constructor {args} {

    set _savedvv [list]
    if {[llength [self next]]} { next {*}$args }
  }

  destructor {

    my initInput
    unset _savedvv
    if {[llength [self next]]} next
  }

  # initialize input
  # (clear variables made in previous session)
  method initInput {} {

    foreach {vn vv} $_savedvv {
      catch {unset $vn}
    }
    set _savedvv [list]
    set _pav(widgetopts) [list]
    return
  }

  # return variables made and filled in previous session
  # as a list of elements {varname varvalue}
  # where varname is of form: [namespace current]::var$widgetname
  method varInput {} {

    return $_savedvv
  }

  # return variables' values
  method valueInput {} {

    set _values {}
    foreach {vnam -} [my varInput] {
      lappend _values [set $vnam]
    }
    return $_values
  }

  # input dialog
  # (layout a set of common widgets: entry, checkbox, radiobuttons etc.)
  method input {icon ttl iopts args} {

    if {$iopts ne {}} {
      my initInput  ;# clear away all internal vars
    }
    set pady "-pady 2"
    if {[set focusopt [my getOption -focus {*}$args]] ne ""} {
      set focusopt "-focus $focusopt"
    }
    lappend inopts [list fraM + T 1 98 "-st nsew $pady -rw 1"]
    set savedvv [list]
    foreach {name prompt valopts} $iopts {
      if {$name eq ""} continue
      lassign $prompt prompt gopts attrs
      set gopts "$pady $gopts"
      set typ [string tolower [string range $name 0 1]]
      if {$typ eq "v_" || $typ eq "se"} {
        lappend inopts [list fraM.$name - - - - "pack -fill x $gopts"]
        continue
      }
      set tvar "-tvar"
      switch -- $typ {
        ch { set tvar "-var" }
        sp { set gopts "$gopts -expand 0 -side left"}
      }
      if {[string match "*Mono*" "[font families]"]} {
        set Mfont "Mono"
      } else {
        set Mfont "Courier"
      }
      if {$typ in {lb te tb}} {  ;# the widgets sized vertically
        lappend inopts [list fraM.fra$name - - - - "pack -expand 1 -fill both"]
      } else {
        lappend inopts [list fraM.fra$name - - - - "pack -fill x"]
      }
      set vv [my varname $name]
      set ff [my fieldname $name]
      if {$typ ne "la"} {
        if {$focusopt eq ""} {
          if {$typ in {fi di cl fo da}} {
            set _ en*$name  ;# 'entry-like mega-widgets'
          } elseif {$typ eq "ft"} {
            set _ te*$name  ;# ftx - 'text-like mega-widget'
          } else {
            set _ $name
          }
          set focusopt "-focus $_" 
        }
        if {$typ in {lb tb te}} {set anc nw} {set anc w}
        lappend inopts [list fraM.fra$name.labB$name - - - - \
          "pack -side left -anchor $anc -padx 3" \
          "-t \"$prompt\" -font \"-family $Mfont -size 10\""]
      }
      # for most widgets:
      #   1st item of 'valopts' list is the current value
      #   2nd and the rest of 'valopts' are a list of values
      if {$typ ni {fc te la}} {
        # curr.value can be set with a variable, so 'subst' is applied
        set vsel [lindex $valopts 0]
        catch {set vsel [subst -nocommands -noback $vsel]}
        set vlist [lrange $valopts 1 end]
      }
      if {[set msgLab [my getOption -msgLab {*}$attrs]] ne ""} {
        set attrs [my removeOptions $attrs -msgLab]
      }
      # define a current widget's info
      switch -- $typ {
        lb - tb {
          set $vv $vlist
          lappend attrs -lvar $vv
          if {$vsel ni {"" "-"}} {
            lappend attrs -lbxsel $vsel
          }
          lappend inopts [list $ff - - - - \
            "pack -side left -expand 1 -fill both $gopts" $attrs]
          lappend inopts [list fraM.fra$name.sbv$name $ff L - - "pack -fill y"]
        }
        cb {
          if {![info exist $vv]} {catch {set $vv ""}}
          lappend attrs -tvar $vv -values $vlist
          if {$vsel ni {"" "-"}} {
            lappend attrs -cbxsel $vsel
          }
          lappend inopts [list $ff - - - - "pack -fill x $gopts" $attrs]
        }
        fc {
          if {![info exist $vv]} {catch {set $vv ""}}
          lappend inopts [list $ff - - - - "pack -fill x $gopts" "-tvar $vv -values \{$valopts\} $attrs"]
        }
        op {
          set $vv $vsel
          lappend inopts [list $ff - - - - "pack -fill x $gopts" "$vv $vlist"]
        }
        ra {
          if {![info exist $vv]} {catch {set $vv $vsel}}
          set padx 0
          foreach vo $vlist {
            set name $name
            lappend inopts [list $ff[incr nnn] - - - - "pack -side left $gopts -padx $padx" "-var $vv -value \"$vo\" -t \"$vo\" $attrs"]
            set padx [expr {$padx ? 0 : 9}]
          }
        }
        te {
          if {![info exist $vv]} {set $vv [string map {\\n \n \\t \t} $valopts]}
          if {[dict exist $attrs -state] && [dict get $attrs -state] eq "disabled"} \
          {
            # disabled text widget cannot be filled with a text, so we should
            # compensate this through a home-made attribute (-disabledtext)
            set disattr "-disabledtext \{[set $vv]\}"
          } elseif {[dict exist $attrs -readonly] && [dict get $attrs -readonly] || [dict exist $attrs -ro] && [dict get $attrs -ro]} {
            set disattr "-rotext \{[set $vv]\}"
            set attrs [my removeOptions $attrs -readonly -ro]
          } else {
            set disattr ""
          }
          lappend inopts [list $ff - - - - "pack -side left -expand 1 -fill both $gopts" "$attrs $disattr"]
          lappend inopts [list fraM.fra$name.sbv$name $ff L - - "pack -fill y"]
        }
        la {
          if {$prompt ne ""} { set prompt "-t \"$prompt\" " } ;# prompt as -text
          lappend inopts [list $ff - - - - "pack $gopts" "$prompt$attrs"]
          continue
        }
        default {
          lappend inopts [list $ff - - - - "pack -side right -expand 1 -fill x $gopts" "$tvar $vv $attrs"]
          if {$vv ne ""} {
            if {![info exist $vv]} {catch {set $vv $vsel}}
          }
        }
      }
      if {$msgLab ne ""} {
        lassign $msgLab lab msg
        set lab [my parentwname [lindex $inopts end 0]].$lab
        if {$msg ne ""} {set msg "-t {$msg}"}
        lappend inopts [list $lab - - - - "pack -side right -expand 1 -fill x" $msg]
      }
      if {![info exist $vv]} {set $vv ""}
      lappend _savedvv $vv [set $vv]
    }
    lassign [my parseOptions $args -titleOK OK -titleCANCEL Cancel \
      -centerme ""] titleOK titleCANCEL centerme
    if {$titleCANCEL eq ""} {
      set butCancel ""
    } else {
      set butCancel "butCANCEL $titleCANCEL 0"
    }
    if {$centerme eq ""} {
      set centerme "-centerme 1"
    } else {
      set centerme "-centerme $centerme"
    }
    set args [my removeOptions $args -titleOK -titleCANCEL -centerme]
    lappend args {*}$focusopt
    set res [my Query $icon $ttl {} "butOK $titleOK 1 $butCancel" butOK \
      $inopts [my PrepArgs $args] "" {*}$centerme]
    if {[lindex $res 0]!=1} {  ;# restore old values if OK not chosen
      foreach {vn vv} $_savedvv {
        # tk_optionCascade (destroyed now) was tracing its variable => catch
        catch {set $vn $vv}
      }
    }
    return $res
  }

  # view/edit a file
  method vieweditFile {fname {prepost ""} args} {

    return [my editfile $fname "" "" "" $prepost {*}$args]
  }

  # edit/view a file with a set of main colors
  method editfile {fname fg bg cc {prepost ""} args} {

    if {$fname eq ""} {
      return false
    }
    set newfile 0
    set filetxt ""
    if {[catch {set filetxt [read [set ch [open $fname]]]}]} {
      if {[catch {close [open $fname w]} err]} {
        puts "ERROR: couldn't create '$fname':\n$err"
        return false
      }
      set newfile 1
    } else {
      close $ch
    }
    lassign [my parseOptions $args -rotext "" -readonly 1 -ro 1] \
      rotext readonly ro
    set btns "Exit 0"  ;# by default 'view' mode
    set oper VIEW
    if {$rotext eq "" || !$readonly || !$ro} {
      set btns "Save 1 Cancel 0"
      set oper EDIT
    }
    if {$fg eq ""} {
      set tclr ""
    } else {
      set tclr "-fg $fg -bg $bg -cc $cc"
    }
    if {$prepost eq ""} {set aa ""} {set aa [$prepost filetxt]}
    set res [my misc "" "$oper FILE: $fname" "$filetxt" $btns \
      TEXT -text 1 -w {100 80} -h 32 {*}$tclr \
      -post $prepost {*}$aa {*}$args]
    set data [string range $res 2 end]
    if {[set res [string index $res 0]] eq "1"} {
      set data [string range $data [string first " " $data]+1 end]
      set data [string trimright $data]
      set ch [open $fname w]
      foreach line [split $data \n] {
        puts $ch [string trimright $line] ;# end spaces conflict with co= arg
      }
      close $ch
    } elseif {$newfile} {
      file delete $fname
    }
    return $res
  }

}
