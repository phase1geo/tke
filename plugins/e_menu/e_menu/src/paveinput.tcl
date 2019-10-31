###########################################################################
#
# This script contains the PaveInput class that allows:
#   - to create input dialogs
#   - to edit text files
#
# Use for input dialogs:
#   source paveinput.tcl
#   PaveInput create pinp $win $pavedir
#   pinp input $icon $ttl $iopts $args
# where:
#   win     - window's path
#   pavedir - source directory of pave
#   icon    - window's icon ("" or "-" means 'no icon')
#   ttl     - title of window
#   iopts   - list of input options:
#     - name of field
#     - prompt (and possibly gridopts, widopts) of field
#     - options for value of field
#   args - PaveDialog options
#
# Use for editing files:
#   source paveinput.tcl
#   PaveInput create pinp $win $pavedir
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

source [file join [file dirname [info script]] pavedialog.tcl]

oo::class create PaveInput {

  superclass PaveDialog

  method input {icon ttl iopts args} {

    set pady "-pady 2"
    lappend inopts [list fraM + T 1 98 "-st new $pady -rw 1"]
    set savedvv [list]
    foreach {name prompt valopts} $iopts {
      lassign $prompt prompt gopts attrs
      set gopts "$pady $gopts"
      if {[set typ [string range $name 0 1]]=="v_" || $typ=="se"} {
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
      if {$typ!="la"} {
        lappend inopts [list fraM.fra$name.labB$name - - - - "pack -side left -anchor w -padx 3" "-t \"$prompt\" -font \"-family $Mfont -size 10\""]
      }
      set vv [my varname $name]
      set ff [my fieldname $name]
      switch $typ {
        cb {
          if {![info exist $vv]} {catch {set $vv ""}}
          set vlist {}
          foreach vo [lrange $valopts 1 end] {
            lappend vlist $vo
          }
          lappend inopts [list $ff - - - - "pack -fill x $gopts" "-tvar $vv -values \{$vlist\} $attrs"]
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
          if {[dict exist $attrs -state] && [dict get $attrs -state]=="disabled"} \
          {
            # disabled text widget cannot be filled with a text, so we should
            # compensate this through a home-made attribute (-disabledtext)
            set disattr "-disabledtext \{[set $vv]\}"
          } else {
            set disattr ""
          }
          lappend inopts [list $ff - - - - "pack -side left -expand 1 -fill both $gopts" "$attrs $disattr"]
          lappend inopts [list fraM.fra$name.sbv$name $ff L - - "pack -fill y"]
        }
        la {
          lappend inopts [list $ff - - - - "pack $gopts" "$attrs"]
          continue
        }
        default {
          lappend inopts [list $ff - - - - "pack -side right -expand 1 -fill x $gopts" "$tvar $vv $attrs"]
          if {$vv!=""} {
            if {![info exist $vv]} {catch {lassign $valopts $vv}}
          }
        }
      }
      if {![info exist $vv]} {set $vv ""}
      lappend savedvv $vv [set $vv]
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
    set res [my Query $icon $ttl {} {butOK OK 1 butCANCEL Cancel 0} butOK \
      $inopts [my PrepArgs $args]]
    if {[lindex $res 0]!=1} {  ;# restore old values if OK not chosen
      foreach {vn vv} $savedvv {
        set $vn $vv
      }
    }
    return $res
  }

  # edit a file
  method editfile {fname fg bg cc {prepost ""} args} {
    if {$fname==""} {
      return false
    }
    set newfile 0
    if {[catch {set data [read [set ch [open $fname]]]}]} {
      if {[catch {close [open $fname w]} err]} {
        puts "ERROR: couldn't create '$fname':\n$err"
        return false
      }
      set newfile 1
      set data ""
    } else {
      close $ch
    }
    if {$prepost==""} {set aa ""} {set aa [$prepost data]}
    set res [my misc "" "EDIT FILE: $fname" "$data" {Save 1 Cancel 0} \
      TEXT -text 1 -ro 0 -w {100 80} -h 32 -fg $fg -bg $bg -cc $cc -size 12 \
      -post $prepost {*}$aa {*}$args]
    set data [string range $res 2 end]
    if {[set res [string index $res 0]]=="1"} {
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
