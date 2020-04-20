###########################################################################
#
# This script contains the APaveInput class that allows:
#   - to create input dialogs
#   - to view/edit text files
#
# Use for input dialogs:
#   package require apave
#   apave::APaveInput create pinp $win
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
#   apave::APaveInput create pinp $win
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

package provide apave 2.5

source [file join [file dirname [info script]] apavedialog.tcl]

namespace eval apave {
}

oo::class create apave::APaveInput {

  superclass apave::APaveDialog

  variable _pav
  variable _pdg
  variable _savedvv

  constructor {args} {
    set _savedvv [list]
    next {*}$args
  }

  destructor {
    my initInput
  }

  # initialize input
  # (clear variables made in previous session)
  method initInput {} {
    foreach {vn vv} $_savedvv {
      catch {unset $vn}
    }
    set _savedvv [list]
    set _pav(widgetopts) [list]
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
    lappend inopts [list fraM + T 1 98 "-st new $pady -rw 1"]
    set savedvv [list]
    foreach {name prompt valopts} $iopts {
      if {$name eq ""} continue
      lassign $prompt prompt gopts attrs
      set gopts "$pady $gopts"
      if {[set typ [string range $name 0 1]] eq "v_" || $typ eq "se"} {
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
      if {$typ ne "la"} {
        lappend inopts [list fraM.fra$name.labB$name - - - - "pack -side left -anchor w -padx 3" "-t \"$prompt\" -font \"-family $Mfont -size 10\""]
      }
      set vv [my varname $name]
      set ff [my fieldname $name]
      switch $typ {
        lb {
          set vlist {}
          foreach vo [lrange $valopts 1 end] {
            lappend vlist $vo
          }
          set $vv $vlist
          lappend attrs -lvar $vv
          if {[set vsel [lindex $valopts 0]] ni {"" "-"}} {
            lappend attrs -lbxsel $vsel
          }
          lappend inopts [list $ff - - - - \
            "pack -side left -expand 1 -fill both $gopts" $attrs]
          lappend inopts [list fraM.fra$name.sbv$name $ff L - - "pack -fill y"]
        }
        cb {
          if {![info exist $vv]} {catch {set $vv ""}}
          set vlist {}
          foreach vo [lrange $valopts 1 end] {
            lappend vlist $vo
          }
          lappend attrs -tvar $vv -values $vlist
          if {[set vsel [lindex $valopts 0]] ni {"" "-"}} {
            lappend attrs -cbxsel $vsel
          }
          lappend inopts [list $ff - - - - "pack -fill x $gopts" $attrs]
        }
        fc {
          if {![info exist $vv]} {catch {set $vv ""}}
          lappend inopts [list $ff - - - - "pack -fill x $gopts" "-tvar $vv -values \{$valopts\} $attrs"]
        }
        ra {
          if {![info exist $vv]} {catch {lassign $valopts $vv}}
          set padx 0
          foreach vo [lrange $valopts 1 end] {
            set name $name
            lappend inopts [list $ff[incr nnn] - - - - "pack -side left $gopts -padx $padx" "-var $vv -value \"$vo\" -t \"$vo\" $attrs"]
            set padx [expr {$padx ? 0 : 9}]
          }
        }
        te {
          if {![info exist $vv]} {set $vv [string map {\\n \n} $valopts]}
          if {[dict exist $attrs -state] && [dict get $attrs -state] eq "disabled"} \
          {
            # disabled text widget cannot be filled with a text, so we should
            # compensate this through a home-made attribute (-disabledtext)
            set disattr "-disabledtext \{[set $vv]\}"
          } elseif {[dict exist $attrs -readonly] && [dict get $attrs -readonly] || [dict exist $attrs -ro] && [dict get $attrs -ro]} {
            set disattr "-rotext \{[set $vv]\}"
            set attrs [my RemoveSomeOptions $attrs -readonly -ro]
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
            if {![info exist $vv]} {catch {lassign $valopts $vv}}
          }
        }
      }
      if {![info exist $vv]} {set $vv ""}
      lappend _savedvv $vv [set $vv]
    }
    if {![string match "*-focus *" $args]} {
      # find 1st entry/text to be focused
      foreach io $iopts {
        if {[set _ [string range [set n [lindex $io 0]] 0 1]] eq "en" || $_ in {te fc cb ra ch}} {
          set args "$args -focus *$n"
          break
        }
        if {$_ in {fi di fo cl}} { ;# choosers (file, dir, font, color)
          set args "$args -focus *ent$n"
          break
        }
      }
    }
    lassign [my parseOptionsFile 0 $args -titleOK OK -titleCANCEL Cancel] titles
    lassign $titles -> titleOK -> titleCANCEL
    if {$titleCANCEL eq ""} {
      set butCancel ""
    } else {
      set butCancel "butCANCEL $titleCANCEL 0"
    }
    set args [my RemoveSomeOptions $args -titleOK -titleCANCEL]
    set res [my Query $icon $ttl {} "butOK $titleOK 1 $butCancel" butOK \
      $inopts [my PrepArgs $args]]
    if {[lindex $res 0]!=1} {  ;# restore old values if OK not chosen
      foreach {vn vv} $_savedvv {
        set $vn $vv
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
    lassign [my parseOptionsFile 0 $args -rotext "" -readonly 1 -ro 1] options
    lassign $options -> rotext -> readonly -> ro
    set btns "Exit 0"  ;# by default 'view' mode
    set oper VIEW
    if {$rotext eq "" && (!$readonly || !$ro)} {
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
      TEXT -text 1 -w {100 80} -h 32 -size 12 {*}$tclr \
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
