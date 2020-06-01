#! /usr/bin/env tclsh

#####################################################################

# Runs commands on files. Bound to editors, file managers etc.
# Scripted by Alex Plotnikov.

#####################################################################

# Test cases:

  # run doctest in console to view all debugging "puts"

  #% doctest 1
  #% exec tclsh /home/apl/PG/github/e_menu/e_menu.tcl z5=~ "s0=PROJECT" "x0=EDITOR" "x1=THEME" "x2=SUBJ" b=firefox PD=~/.tke d=~/.tke s1=~/.tke "F=*" f=/home/apl/PG/Tcl-Tk/projects/mulster/mulster.tcl md=~/.tke/plugins/e_menu/menus m=menu.mnu fs=8 w=30 o=0 c=0 s=selected g=+0+30
  #> doctest

  #-% doctest 2
  #-% exec lxterminal -e tclsh /home/apl/PG/github/e_menu/e_menu.tcl z5=~ "s0=PROJECT" "x0=EDITOR" "x1=THEME" "x2=SUBJ" b=firefox PD=~/.tke d=~/.tke s1=~/.tke "F=*" md=~/.tke/plugins/e_menu/menus m=side.mnu o=1 c=4 fs=8 s=selected g=+200+100 &
  # ------ no result is waited here ------
  #-> doctest

#####################################################################

namespace eval ::em {
  variable e_menu_version "e_menu v2.0.2"
  variable exedir [file normalize [file dirname [info script]]]
  variable srcdir [file join $::em::exedir src]
}

if {[catch {source [file join $::em::srcdir e_help.tcl]} e]} {
  set ::em::srcdir [file join [pwd] src]
  if {[catch {source [file join $::em::srcdir e_help.tcl]} e2]} {
    puts "$e\n\n$e2\n\nPossibly, there is an error in e_help.tcl"
    exit
  }
}

# use "d message1 message2 ..." to show debug messages
# at worst, uncomment the next line to use "bb message1 message2 ..."
# catch {source ~/PG/bb.tcl}

# *******************************************************************
# customized block

set ::lin_console "src/run_pause.sh"   ;# (for Linux)
set ::win_console "src/run_pause.bat"  ;# (for Windows)

set ::ncolor 0 ;# default color scheme

# *******************************************************************
# internal trifles:
#   M - message
#   Q - question
#   T - terminal's command
#   S - OS command/program
#   IF - conditional execution
#   EXIT - close menu

proc M {args} {
  set msg ""; foreach a $args {append msg "$a "}
  ::em::em_message $msg ok Info -centerme 0 -ontop $::em::ontop
}
proc Q {ttl mes {typ okcancel} {icon warn} {defb OK} args} {
  return [set ::em::Q [::em::em_question $ttl $mes $typ $icon $defb {*}$args \
  -centerme 0 -ontop $::em::ontop]]
}
proc T {args} {
  set cc ""; foreach c $args {set cc "$cc$c "}
  ::em::shell_run "Nobutt" "S:" shell1 - "&" [string map {"\\n" "\r"} $cc]
}
proc S {incomm} {
  foreach comm [split [string map {\\n \n} $incomm] \n] {
    if {[set comm [string trim $comm]] ne ""} {
      set comm [string map {\\\\n \\n} $comm]
      set clst [split $comm]
      set com0 [lindex $clst 0]
      if {$com0 eq "cd"} {
        ::em::vip comm
      } elseif {[set com1 [auto_execok $com0]] ne ""} {
        exec $com1 {*}[lrange $clst 1 end] &
      } else {
        M Can't find $com0
      }
    }
  }
}
proc EXIT {} {::em::on_exit}

# *******************************************************************
# e_menu's procedures

namespace eval ::em {

  variable menuttl "$::em::e_menu_version"
  variable thisapp emenuapp
  variable appname $::em::thisapp
  variable fs 9           ;# font size
  variable font1 "Sans" font2 "Mono"   ;# font of header & item
  variable viewed 40      ;# width of item (in characters)
  variable maxitems 64    ;# maximum of menu.txt items
  variable timeafter 10   ;# interval (in sec.) for updating times/dates
  variable offline false  ;# set true for offline help
  variable ratiomin "3/5"
  variable hotsall \
    "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,./"
  variable hotkeys $::em::hotsall
  variable workdir "" PD "" prjname "" prjdirlist [list]
  variable ornament 1  ;# 1 - header only; 2 - prompt only; 3 - both; 0 - none
  variable inttimer 1  ;# interval to check the timed tasks
  variable bd 1 b0 0 b1 1 b2 1 b3 1 b4 1
  variable incwidth 15
  variable wc 0
  variable tf 15
  variable tg 80x24+200+200
  variable om 1
  #---------------
  variable mute "*S*"
  variable begin 1 begtcl 3
  variable begsel $::em::begtcl
  #---------------
  variable editor ""
  variable percent2 ""
  variable commandA1 "" commandA2 ""
  #---------------
  variable seltd "" useltd "" qseltd "" dseltd "" sseltd "" pseltd ""
  variable ontop 0 dotop 0
  variable extraspaces "      " extras true
  variable ncmd 0
  variable lasti 1
  variable minwidth 0
  #---------------
  foreach ar {
  pars itnames bgcolr ar_s09 ar_u09 ar_i09 ar_geany ar_tformat ar_macros} {
    variable $ar; array set $ar [list]
  }
  #---------------
  variable itviewed 0
  variable geometry ""
  variable ischild 0
  variable menufile [list 0] menufilename "" menuoptions ""
  variable inherited ""
  variable autorun ""
  variable commands ""
  variable autohidden "" commhidden ""
  variable pause 0
  variable appN 0
  variable tasks {} taski {} ipos 0 TN 0
  variable isep 0
  variable start0 1
  variable prjset 0
  variable skipfocused 0
  variable cb ""
  variable basedir ""
  variable conti "\\" lconti 0
  variable filecontent {}
  variable truesel 0
  variable ln 0 cn 0 yn 0
  variable ismenuvars 0
  variable savelasti -1
  variable linuxconsole ""
  variable insteadCSlist [list] insteadCS 0
  variable source_addons true
  variable themecolors [list]
}
#=== source addons and call a function of these
proc ::em::addon {func args} {
  if {$::em::source_addons} {
    set ::em::source_addons false
    source [file join $::em::srcdir e_addon.tcl]
  }
  $func {*}$args
}
#=== set colors for dialogs
proc ::em::theming_pave {} {
  # ALL colors set as arguments of e_menu: fg=, bg=, fE=, bE=, fS=, bS=, cc=, ht=
  if {$::em::insteadCS} {
    if {$::em::themecolors eq [list]} {
      set ::em::themecolors [list $::em::clrfg $::em::clrbg $::em::clrfE \
        $::em::clrbE $::em::clrfS $::em::clrbS #182020 #dcdad5 \
        $::em::clrcc $::em::clrht $::em::clrhh $::em::clrfI $::em::clrbI]
      ::apave::themeObj themeWindow . {*}$::em::themecolors false
    }
    foreach clr $::em::themecolors {append thclr "-theme $clr "}
    return $thclr
  }
  return ""
}
#=== own message/question box
proc ::em::dialog_box {ttl mes {typ ok} {icon info} {defb OK} args} {
  return [::eh::dialog_box $ttl $mes $typ $icon $defb {*}$args {*}[::em::theming_pave]]
}
#=== own message box
proc ::em::em_message {mes {typ ok} {ttl "Info"} args} {
  if {[string match ERROR* [string trimleft $mes]]} {set ico err} {set ico info}
  ::em::dialog_box $ttl $mes $typ $ico OK {*}$args
}
#=== own question box
proc ::em::em_question {ttl mes {typ okcancel} {icon warn} {defb OK} args} {
  return [::em::dialog_box $ttl $mes $typ $icon $defb {*}$args]
}
#=== re-read and update menu after Ctrl+R
proc ::em::reread_menu {{ib ""}} {
  foreach w [winfo children .] {  ;# remove Tcl/Tk menu items
    destroy $w
  }
  initcomm
  initmenu
  if {$ib ne ""} {mouse_button $ib}
}
#=== check is there a header of menu
proc ::em::isheader {} {
  return [expr {$::em::ornament == 1 || $::em::ornament == 3} ? 1 : 0]
}
#=== get an item's color
proc ::em::color_button {i {fgbg "fg"}} {
  if {$fgbg eq "fg"} {
    if {$i > $::em::begsel} {
      set clr $::em::clrinaf ;# common item`
    } else {
      set clr $::em::clrhelp ;# HELP/EXEC/SHELL or submenu
    }
  } else {
    set clr $::em::clrinab
  }
  return $clr
}
#=== get a selected item's color
proc ::em::color_selected_button {i {fgbg "fg"}} {
  if {$fgbg eq "fg"} {
    if {[info exists ::em::clrfI]} {
      set clr $::em::clrfI   ;# fI= argument overrides CS color
    } else {
      set clr $::em::clractf
    }
  } else {
    if {[info exists ::em::clrbI]} {
      set clr $::em::clrbI  ;# bI= argument overrides CS color
    } else {
      set clr $::em::clractb
    }
  }
  return $clr
}
#=== get next button index
proc ::em::next_button {i} {
  if {$i>=$::em::ncmd} {set i $::em::begin}
  if {$i<$::em::begin} {set i [expr $::em::ncmd-1]}
  return $i
}
#=== get focused status of menu
proc ::em::isMenuFocused {} {
  return [expr {![winfo exists .frame] || [.frame cget -bg] ne $::em::clrgrey}]
}
#=== put i-th button in focus
proc ::em::focus_button {i {doit true}} {
  set leave [expr {$i<0}]
  set last $::em::lasti
  set i [next_button $i]
  if {![winfo exists .frame.fr$i.butt]} return
  if {![isMenuFocused]} {
    set fg [.frame.fr$i.butt cget -fg]
    set bg $::em::clrgrey
  } else {
    if {$::em::lasti >= $::em::begin && $::em::lasti < $::em::ncmd} {
      if {[winfo exists .frame.fr$::em::lasti.arr]} {
        .frame.fr$::em::lasti.arr configure -bg [color_button $::em::lasti bg]
      }
      if {[winfo exists .frame.fr$::em::lasti.butt]} {
        .frame.fr$::em::lasti.butt configure \
          -bg [color_button $::em::lasti bg] -fg [color_button $::em::lasti]
      }
      #if {$leave} return
    }
    set fg [color_selected_button $i]
    set bg [color_selected_button $i bg]
  }
  #if {$leave} return
  .frame.fr$i.butt configure -fg $fg -bg $bg \
    -activeforeground $fg -activebackground $bg
  if {[winfo exists .frame.fr$i.arr]} {
    .frame.fr$i.arr configure -bg $bg \
      -activeforeground $fg -activebackground $bg
  }
  set ::em::lasti $i
  if {$doit || $last != $::em::lasti} {focus .frame.fr$i.butt}
}
#=== move mouse to i-th button
proc ::em::mouse_button {i} {
  focus_button $i
  set i [next_button $i]
  if {![winfo exists .frame.fr$i.butt]} return
  lassign [split [winfo geom .frame] +] -> x1 y1
  lassign [split [winfo geom .frame.fr$i] +x] w - x2 y2
  lassign [split [winfo geom .frame.fr$i.butt] +x] - h x3 y3
  event generate . <Motion> -warp 1 -x [expr $x1+$x2+$x3+$w/2] \
    -y [expr $y1+$y2+$y3+$h-5]
}
#=== 'proc' all buttons
proc ::em::for_buttons {proc} {
  set ::em::isep 0
  for {set j $::em::begin} {$j < $::em::ncmd} {incr j} {
    uplevel 1 "set i $j; set b .frame.fr$j.butt; $proc"
  }
}
#=== get contents of s1 argument (s=,..)
proc ::em::get_seltd {s1} {
  return [lindex [array get ::em::pars $s1] 1]
}
#=== get a calling mode
proc ::em::silent_mode {amp} {
  set silent [string first $::em::mute " $amp"]
  if {$silent > 0} {
    set amp [string map [list $::em::mute ""] "$amp"]
  }
  return [list $amp $silent]
}
#=== read and write the menu file
proc ::em::read_menufile {} {
  set menudata [read [set ch [open $::em::menufilename]]]
  set menudata [split [string trimright $menudata "\n"] "\n"]
  close $ch
  return $menudata
}
proc ::em::write_menufile {menudata} {
  ::eh::write_file_untouched $::em::menufilename $menudata
}
#=== save options in the menu file (by default - current selected item)
proc ::em::save_options {{setopt "in="} {setval ""}} {
  if {$setopt eq "in="} {
    if {$::em::savelasti<0} return
    set setval $::em::lasti.$::em::begsel
  }
  set setval "$setopt$setval"
  set menudata [::em::read_menufile]
  set opt [set i [set ifnd1 [set ifndo 0]]]
  foreach line $menudata {
    if {$line eq {[OPTIONS]}} {
      set opt 1
      set ifndo [expr {$i+1}]
    } elseif {$opt} {
      if {[string match "${setopt}*" $line]} {
        set ifnd1 $i
        break
      }
    } elseif {$line eq {[MENU]} || $line eq {[HIDDEN]}} {
      set opt 0
    }
    incr i
  }
  if {$ifnd1} {
    set menudata [lreplace $menudata $ifnd1 $ifnd1 $setval]
  } else {
    if {$ifndo} {
      set menudata [linsert $menudata $ifndo $setval]
    } else {
      lappend menudata \n {[OPTIONS]}
      lappend menudata $setval
    }
  }
  ::em::write_menufile $menudata
}
#=== initialize values of menu's variables
proc ::em::init_menuvars {domenu options} {
  if {!($domenu && $options)} return
  set opt 0
  foreach line $::em::menufile {
    if {$line eq {[OPTIONS]}} {
      set opt 1
    } elseif {$opt && [run_Tcl_code $line true]} {
      # line of Tcl code - processed already
    } elseif {$opt && [string match "::?*=*" $line]} {
      set ::em::ismenuvars 1
      set ieq [string first "=" $line]
      set vname [string range $line 0 $ieq-1]
      set vvalue [string range $line $ieq+1 end]
      if {![info exists $vname]} {
        catch {
          set ::$vname ""
          ::em::prepr_pn vvalue
          set ::$vname $vvalue
        }
      }
    } elseif {$line eq {[MENU]} || $line eq {[HIDDEN]}} {
      set opt 0
    }
  }
}
#=== save values of menu's variables in the menu file
proc ::em::save_menuvars {} {
  set menudata [::em::read_menufile]
  set opt [set i 0]
  foreach line $menudata {
    if {$line eq {[OPTIONS]}} {
      set opt 1
    } elseif {$opt && [string match "::*=*" $line]} {
      lassign [regexp -inline "::(.+)=(.*)" $line] ==> vname vvalue
      catch {
        set newvalue [::eh::escape_specials [set ::$vname]]
        set ::$vname $newvalue
        if {[string first % $vvalue]<0} { ;# don't save for wildcarded
          lset menudata $i "::$vname=$newvalue"
        }
      }
    } elseif {$line eq {[MENU]} || $line eq {[HIDDEN]}} {
      set opt 0
    }
    incr i
  }
  if {$::em::ismenuvars} {::em::write_menufile $menudata}
}
#=== VIP commands need internal processing
proc ::em::vip {refcmd} {
  upvar $refcmd cmd
  if {[string first "%#" $cmd] == 0} {
    # writeable command:
    # get (possibly) saved version of the command
    if {[set cmd [::em::addon writeable_command $cmd]] eq ""} {
      return true ;# here 'cancelled' means 'processed'
    }
    return false
  }
  if {[string first "%P " $cmd] == 0} {
      # prepare the command for processing
    set cmd [string range $cmd 3 end]
    set cmd [string map {"\\n" "\n"} $cmd]
    if {[string first "\$::env(" $cmd]>=0} {
      catch {set cmd [subst $cmd]}
    }
  }
  set cd [string range $cmd 0 2]
  if {([::iswindows] && [string toupper $cd] eq "CD ") || $cd eq "cd "} {
    prepr_win cmd "M/"  ;# force converting
    if {[set cd [string trim [string range $cmd 3 end]]] ne "."} {
      catch {set cd [subst -nobackslashes -nocommands $cd]}
      catch {cd $cd}
    }
    return true
  }
  if {$cmd in {"%E" "%e"} || $cd in {"%E " "%e "}} {
    return [::em::addon edit [string range $cmd 3 end]] ;# editor
  }
  return false
}
#=== start autorun lists
proc ::em::run_a_ah {sub} {
  if {[string first "a=" $sub] >= 0} {
    run_auto [string range $sub 2 end]
  } elseif {[string first "ah=" $sub] >= 0} {
    run_autohidden [string range $sub 3 end]
  }
}
#=== parse modes of run
proc ::em::s_assign {refsel {trl 1}} {
  upvar $refsel sel
  set retlist [list]
  set tmp [string trimleft $sel]
  set qpos [expr {$::em::ornament>1 ? [string first ":" $tmp]+1 : 0}]
  if {[string first "?" $tmp] == $qpos} {   ;#?...? sets modes of run
    set prom [string range $tmp 0 [expr {$qpos-1}]]
    set sel [string range $tmp $qpos end]
    lassign {"" 0} el qac
    for {set i 1}  {$i < [string len $sel]} {incr i} {
      if {[set c [string range $sel $i $i]] eq "?" || $c eq " "} {
        if {$c eq " "} {
          set sel [string range $sel [expr $i+1] end]
          if {$trl} {set sel [string trimleft $sel]}
          lappend retlist -1
          set sel $prom$sel
          break
        } else {
          lappend retlist $el
          lassign {"" 1} el qac
        }
      } else {
        set el "$el$c"
      }
    }
  }
  return $retlist
}
#=== replace first %b with browser pathname
proc ::em::checkForWilds {rsel} {
  upvar $rsel sel
  switch -glob -- [string toupper $sel] {
    "%B *" {
      set sel "::eh::browse [list [string range $sel 3 end]]"
      if {![catch {{*}$sel} e]} {
        return [list true true]
      }
    }
    "%Q *" {
      catch {set sel [subst -nobackslashes -nocommands $sel]}
      set sel "Q [string range $sel 3 end]"
      if {![catch {{*}$sel} e]} {
        return [list true $e]
      }
    }
    "%M *" {
      catch {set sel [subst -nobackslashes -nocommands $sel]}
      set sel "M [string range $sel 3 end]"
      if {![catch {{*}$sel} e]} {
        return [list true true]
      }
    "%U *" {
      return true ;# not used now
      }
    }
  }
  return false
}
#=== replace first %t with terminal pathname
proc ::em::checkForShell {rsel} {
  upvar $rsel sel
  if {[string first "%t " $sel] == 0 || \
      [string first "%T " $sel] == 0 } {
    set sel "[string range $sel 3 end]"
    return true
  }
  return false
}
#=== call command in shell
proc ::em::shell0 {sel amp {silent -1}} {
  set ret true
  catch {set sel [subst -nobackslashes -nocommands $sel]}
  if {[string first "%IF " $sel] == 0} {
    if {![::em::addon IF $sel sel]} {return false}
  }
  if {[lindex [set _ [checkForWilds sel]] 0]} {
    return [lindex $_ 1]
  } elseif {[run_Tcl_code $sel]} {
    # processed
  } elseif {[::iswindows]} {
    if {[string trim "$sel"] eq ""} {return true}
    set composite "$::win_console $sel $amp"
    catch {
      # here we construct new .bat containing all lines of the command
      set lines "@echo off\n"
      append lines [string map {"\\n" "\n"} $sel] "\npause"
      set cho [open "$::win_console.bat" w]
      puts $cho $lines
      close $cho
      set composite "$::win_console.bat $amp"
    }
    if {[catch {exec {*}[auto_execok start] \
      cmd.exe /c {*}"$composite"} e]} {
      if {$silent < 0} {
        set ret false
      }
    }
  } else {
    if {[string trim "$sel"] eq ""} {return true}
    set lang [::eh::get_language]
    if {$::em::linuxconsole ne "" && [string first \\n $sel]<0} {
      set composite "$::lin_console $sel $amp"
      #set composite [string map [list \\n " ; "] $composite]
      exec -ignorestderr {*}$::em::linuxconsole -e {*}$composite
    } elseif {[set term [auto_execok lxterminal]] ne "" } {
      set sel [string map [list "\""  "\\\""] $sel]
      set composite "$::lin_console $sel $amp"
      exec -ignorestderr {*}$term --geometry=$::em::tg -e {*}$composite
    } elseif {[set term [auto_execok xterm]] ne "" } {
      set sel [::eh::escape_quotes $sel]
      set composite "$::lin_console $sel $amp"
      exec -ignorestderr {*}$term -fa "$lang" -fs $::em::tf \
      -geometry $::em::tg -bg white -fg black -title $sel -e {*}$composite
    } else {
      set ret false
      set e "Not found lxterminal nor xterm.\nInstall any."
    }
  }
  if {$silent < 0 && !$ret} {
    em_message "ERROR of running\n\n$sel\n\n$e"
  }
  return $ret
}
#=== run a code of Tcl
proc ::em::run_Tcl_code {sel {dosubst false}} {
  if {[string first "%C" $sel] == 0} {
    if {$dosubst} {prepr_pn sel}
    try {
      set sel [string range $sel 3 end]
      if {[string match "eval *" $sel]} {
        {*}$sel
      } else {
        eval $sel
      }
    }
    return true
  }
  return false
}
#=== run a program of sel
proc ::em::run0 {sel amp silent} {
  if {![vip sel]} {
    if {[lindex [set _ [checkForWilds sel]] 0]} {
      return [lindex $_ 1]
    } elseif {[run_Tcl_code $sel]} {
      # processed already
    } elseif {[string first "%I " $sel] == 0} {
      return [::em::addon input $sel]
    } elseif {[string first "%S " $sel] == 0} {
      S [string range $sel 3 end]
    } elseif {[string first "%IF " $sel] == 0} {
      return [::em::addon IF $sel]
    } elseif {[checkForShell sel]} {
      shell0 $sel $amp $silent
    } else {
      set comm "$sel $amp"
      if {[::iswindows]} {
        set comm "cmd.exe /c $comm"
      }
      catch {set comm [subst -nobackslashes -nocommands $comm]}
      if {[catch {exec {*}$comm} e]} {
        if {$silent < 0} {
          em_message "ERROR of running\n\n$sel\n\n$e"
          return false
        }
      }
    }
  }
  return true
}
#=== run a program of menu item
proc ::em::run1 {typ sel amp silent} {
  prepr_prog sel $typ  ;# prep
  prepr_idiotic sel 0
  catch {set sel [subst -nobackslashes -nocommands $sel]}
  return [run0 $sel $amp $silent]
}
#=== call command in shell
proc ::em::shell1 {typ sel amp silent} {
  prepr_prog sel $typ  ;# prep
  prepr_idiotic sel 0
  if {[vip sel]} {return true}
  if {[::iswindows] || $amp ne "&"} {focused_win false}
  set ret [shell0 $sel $amp $silent]
  if {[::iswindows] || $amp ne "&"} {focused_win true}
  return $ret
}
#=== update item name (with inc)
proc ::em::update_itname {it inc {pr ""}} {
  catch {
    if {$it > $::em::begsel} {
      set b .frame.fr$it.butt
      if {[$b cget -image] eq ""} {
        if {$::em::ornament > 1} {
          set ornam [$b cget -text]
          set ornam [string range $ornam 0 [string first ":" $ornam]]
        } else {set ornam ""}
        set itname $::em::itnames($it)
        if {$pr ne ""} {{*}$pr}
        prepr_09 itname ::em::ar_i09 "i" $inc  ;# incr N of runs
        prepr_idiotic itname 0
        $b configure -text [set comtitle $ornam$itname]
        tooltip::tooltip $b "$comtitle"
      }
    }
  }
}
#=== update all buttons
proc ::em::update_buttons {{pr ""}} {
  for_buttons {
    update_itname $i 0 $pr
  }
}
#=== update all buttons' names
proc ::em::update_buttons_pn {} {
  update_buttons "prepr_pn itname"
}
#=== update all buttons' date/time
proc ::em::update_buttons_dt {} {
  update_buttons_pn
  repeate_update_buttons  ;# and re-run itself
}
#=== update buttons with time/date
proc ::em::repeate_update_buttons {} {
  after [expr $::em::timeafter * 1000] ::em::update_buttons_dt
}
#=== run/shell
proc ::em::shell_run {from typ c1 s1 amp {inpsel ""}} {
  set cpwd [pwd]
  set inc 1
  set doexit 0
  if {$inpsel eq ""} {
    set inpsel [get_seltd $s1]
    lassign [silent_mode $amp] amp silent  ;# silent_mode - in 1st line
    lassign [s_assign inpsel] p1 p2
    if {$p1 ne ""} {
      if {$p2 eq ""} {
        set silent $p1
      } else {
        if {![::em::addon set_timed $from $p1 $typ $c1 $inpsel]} {return}
        set silent $p2
      }
    }
  } else {
    if {$amp eq "noamp"} {
      lassign {"" -1} amp silent
    } else {
      lassign {"&" -1} amp silent
    }
  }
  foreach seltd [split $inpsel "\n"] {
    if {[set r [string first "\r" $seltd]] > 0} {
      lassign [split $seltd "\r"] runp seltd
      if {[string first "::em::run" $runp] != -1} {
        set c1 "run1"
      } else {
        set c1 "shell1"
      }
      if {[string last "&$::em::mute" $runp]>0} {set amp &} {set amp ""}
      if {[string last "; exit$::em::mute" $runp$::em::mute] > 0} {
        set doexit 1
        set amp "&"
      }
    }
    prepr_09 seltd ::em::ar_i09 "i"   ;# set N of runs in command
    if {![ $c1 $typ "$seltd" $amp $silent ] || $doexit > 0} {
      set inc 0  ;# unsuccessful run
      break
    }
  }
  if {$doexit > 0} {::em::on_exit}
  if {$inc} {                        ;# all buttons texts may need to update
    update_itname $::em::lasti $inc  ;# because all may include %s1, %s2...
  }
  update_buttons_pn
  update idletasks
  catch {cd $cpwd}  ;# may be deleted by commands
}
#=== run commands before a submenu
proc ::em::before_callmenu {pars} {
  set cpwd [pwd]
  set menupos [string last "::em::callmenu" $pars]
  if {$menupos>0} {  ;# there are previous commands before callmenu
    set commands [string range $pars 0 $menupos-1]
    foreach com [split $commands \r] {
      set com [lindex [split $com \n] 0]
      if {$com ne ""} {
        if {![run0 $com "" 0]} {
          set pars ""
          break
        }
      }
    }
    set pars [string range $pars [string last \r $pars]+1 end]
  }
  catch {cd $cpwd}  ;# may be deleted by commands
  return $pars
}
#=== call a submenu
proc ::em::callmenu {typ s1 {amp ""} {from ""}} {
  save_options
  set pars [get_seltd $s1]
  set pars [before_callmenu $pars]
  if {$pars eq ""} return
  set cho ch=[expr {[string range $typ 0 1] ne "ME" || $::em::ontop}]
  set pars "$::em::inherited a= a0= a1= a2= ah= n= pa=0 $pars"
  set pars [string map [list "b=%b" "b=$::eh::my_browser"] $pars]
  if {[string match "ME*" $typ]} {
    lassign [regexp -inline {^.*([+].*[+].*)} [wm geometry .]] -> geo
  } else {
    set geo "+[expr 10+[winfo x .]]+[expr 15+[winfo y .]]"
  }
  set pars "$cho g=$geo $pars"
  if {$::em::ontop} {
    append pars " t=1"    ;# "ontop" means also "all menus stay on"
  } else {
    prepr_1 pars "cb" [::em::get_callback]    ;# %cb is callback of caller
  }
  if {$::apave::_CS_(MAXCS) > $::apave::_CS_(STDCS)} {
    append pars " \"cs=[lindex $::apave::_CS_(ALL) $::apave::_CS_(MAXCS)]\""
  }
  prepr_1 pars "in" [string range $s1 1 end]  ;# %in is menu's index
  set sel "tclsh \"$::argv0\""
  prepr_win sel "M/"  ;# force converting
  #if {[set windows [::iswindows]] || $amp ne "&"} {focused_win false}
  catch {exec {*}$sel {*}$pars $amp}
  #if {$windows || $amp ne "&"} {focused_win true}
 # ::em::addon repaintForWindows
}
#=== run "seltd" as a command
proc ::em::run {typ s1 {amp ""} {from ""}} {
  save_options
  shell_run $from $typ run1 $s1 $amp
}
#=== shell "seltd" as a command
proc ::em::shell {typ s1 {amp ""} {from ""}} {
  save_options
  shell_run $from $typ shell1 $s1 $amp
}
#=== run by button pressing
proc ::em::callmenu_button {typ s1 {amp ""}} {
  callmenu $typ $s1 $amp "button"
}
proc ::em::log {oper} {
  catch {puts "$::em::menuttl - $oper: $::em::lasti"}
}
proc ::em::run_button {typ s1 {amp ""}} {
  run $typ $s1 $amp "button"
  log Run
}
proc ::em::shell_button {typ s1 {amp ""}} {
  shell $typ $s1 $amp "button"
  log Shell
}
#=== browse a help page
proc ::em::browse_button {s1} {
  set help [lindex [get_seltd $s1] 0]  ;# 1st word is the page name
  ::eh::browse [::eh::html $help $::em::offline]
  set ::em::lasti 1
  ::em::save_options
  ::em::on_exit
}
#=== run a command after keypressing
proc ::em::pr_button {ib args} {
  mouse_button $ib
  set comm "$args"
  if {[set i [string first " " $comm]] > 2} {
    set comm "[string range $comm 0 [expr $i-1]]_button
                [string range $comm $i end]"
  }
  {*}$comm
  save_options
  if {[string first "?" "[.frame.fr$ib.butt cget -text]"]>-1} {
    reread_menu  ;# after dialogs, it's good to update items
  }
}
#=== get array index of i-th menu item
proc ::em::get_s1 {i hidden} {
  if {$hidden} {return "h$i"} {return "m$i"}
}
#=== prepare a callback of caller
proc ::em::get_callback {} {
  set cb "\{$::argv0\}"
  foreach a $::argv {
    append cb " $a"
  }
  return $cb
}
#=== get working (project's) dir
proc ::em::get_PD {} {
  if {[llength $::em::prjdirlist]>0} {
    # workdir got from a current file (if not passed, got a current dir)
    if {[catch {set ::em::workdir $::em::ar_geany(d)}] && \
        [catch {set ::em::workdir [file dirname $::em::ar_geany(f)]}]} {
      set ::em::workdir [pwd]
    }
    foreach wd $::em::prjdirlist {
      if {[string first [string toupper $wd] [string toupper $::em::workdir]]==0} {
        set ::em::workdir "$wd"
        break
      }
    }
  }
  if {![file isdirectory $::em::workdir]} {
    set ::em::workdir [pwd]
  }
  return $::em::workdir
}
proc ::em::get_P_ {} {
  return [::eh::get_underlined_name $::em::workdir]
}
#=== get contents of %f file (supposedly, there can be only one "%f" value)
proc ::em::read_f_file {} {
  if {$::em::filecontent=={} && [info exists ::em::ar_geany(f)]} {
    if {![file isfile $::em::ar_geany(f)] || \
    [file size $::em::ar_geany(f)]>1048576 || \
    [catch {set chan [open $::em::ar_geany(f)]}]} {
      set ::em::filecontent - ;# no content
      return 0
    }
    while {[gets $chan st]>=0} {
      lappend ::em::filecontent $st
    }
    close $chan
  }
  return [llength $::em::filecontent]
}
#=== get contents of #ARGS1: ..#ARGS99: line
proc ::em::get_AR {} {
  if {$::em::truesel && $::em::seltd ne ""} {
    ;# %s is preferrable for ARGS (ts= rules)
    return [string map {\n \\n \" \\\"} $::em::seltd]
  }
  if {[::em::read_f_file]} {
    set re "^#\[ \]?ARGS\[0-9\]+:\[ \]*(.*)"
    foreach st $::em::filecontent {
      if {[regexp $re $st]} {
        lassign [regexp -inline $re $st] => res
        return $res
      }
    }
  }
  return ""
}
#=== get contents of %l-th line of %f file
proc ::em::get_L {} {
  if {![catch {set p $::em::ar_geany(l)}] && \
       [string is digit $p] && $p>0 && $p<=[llength $::em::filecontent]} {
    return [lindex $::em::filecontent $p-1]
  }
  return ""
}
#=== Mr. Preprocessor of s0-9, u0-9
proc ::em::prepr_09 {refn refa t {inc 0}} {
  upvar $refn name
  upvar $refa arr
  for {set i 0} {$i<=9} {incr i} {
    set p "$t$i"
    set s "$p="
    if {[string first $p $name] != -1} {
      if {![catch {set sel $arr($s)} e]} {
        if {$t eq "i"} {
          incr sel $inc     ;# increment i1-i9 counters of runs
          set ${refa}($s) $sel
        }
        prepr_1 name $p $sel
      }
    }
  }
}
#=== get the current menu name
proc ::em::get_menuname {seltd} {
  if {$::em::basedir ne ""} {
    set seltd [file join $::em::basedir $seltd]
  }
  if {![file exists "$seltd"]} {
    set seltd [file join $::em::exedir $seltd]
  }
  return $seltd
}
#=== Mr. Preprocessor of %-wildcards
proc ::em::prepr_1 {refpn s ss} {
  upvar $refpn pn
  set pn [string map [list "%$s" $ss] $pn]
}
#=== Mr. Preprocessor of dates
proc ::em::prepr_dt {refpn} {
  upvar $refpn pn
  set oldpn $pn
  lassign [::eh::get_timedate] curtime curdate curdt curdw systime
  prepr_1 pn "t0" $curtime               ;# %t0 time
  prepr_1 pn "t1" $curdate               ;# %t1 date
  prepr_1 pn "t2" $curdt                 ;# %t2 date & time
  prepr_1 pn "t3" $curdw                 ;# %t3 week day
  foreach tw [array names ::em::ar_tformat] {
    set time [clock format $systime -format $::em::ar_tformat($tw)]
    prepr_1 pn "$tw" $time
  }
  return [expr {$oldpn ne $pn} ? 1 : 0]   ;# to update time in menu
}
#=== Mr. Preprocessor idiotic
proc ::em::prepr_idiotic {refpn start } {
  upvar $refpn pn
  set idiotic "~Fb^D~"
  if {$start} {
      # this must be done just before other preps:
    set pn [string map [list "%%" $idiotic] $pn]
    prepr_call pn
  } else {
      # this must be done just after other preps and before applying:
    set pn [string map [list $idiotic "%"] $pn]
    set pn [string map [list "%TN" $::em::TN] $pn]
    set pn [string map [list "%TI" $::em::ipos] $pn]
  }
}
#=== Mr. Preprocessor initial
proc ::em::prepr_init {refpn} {
  upvar $refpn pn
  prepr_idiotic pn 1
  prepr_1 pn "+"  $::em::pseltd ;# %+  is %s with " " as "+"
  prepr_1 pn "qq" $::em::qseltd ;# %qq is %s with quotes escaped
  prepr_1 pn "dd" $::em::dseltd ;# %dd is %s with special simbols deleted
  prepr_1 pn "ss" $::em::sseltd ;# %ss is %s trimmed
  prepr_09 pn ::em::ar_s09 "s"  ;# s1-s9 params
  prepr_09 pn ::em::ar_u09 "u"  ;# u1-u9 params underscored
  set delegator {}
  for {set i 1} {$i<=19} {incr i} {
    if {$i <= 9} {set d "s$i="} {set d "u[expr $i-10]="}
    lappend delegator $d
  }
  foreach d $delegator {             ;# delegating values:
    set i [string range $d 0 0]    ;# s0 -> s9 -> u0 -> u9
    catch {
      if {$i eq "s"} {
        set el $::em::ar_s09($d)
        prepr_09 el ::em::ar_s09 s
        prepr_09 el ::em::ar_u09 u
        set ::em::ar_s09($d) $el
      } else {
        set el $::em::ar_u09($d)
        prepr_09 el ::em::ar_s09 s
        prepr_09 el ::em::ar_u09 u
        set ::em::ar_u09($d) [string map [list " " "_"] $el]
      }
    }
  }
}
#=== initialization of selection (of %s wildcard)
proc ::em::init_swc {} {
  if {$::em::seltd ne "" || $::em::ln<=0 || $::em::cn<=0} {
    return  ;# selection is provided or ln=/cn= are not - nothing to do
  }
  if {[::em::read_f_file]} {     ;# get the selection as a word under caret
    set ln1 0                    ;# lines and columns are numerated from 1
    set ln2 [expr {*}$::em::ln - 1]
    set cn1 [expr {*}$::em::cn - 2]
    foreach st $::em::filecontent { ;# ~ KISS
      if {$ln1==$ln2} {
        for {set i $cn1} {$i>=0} {incr i -1} { ;# left part
          set c [string index $st $i]
          if {[string is wordchar $c]} {set ::em::seltd $c$::em::seltd} break
        }
        for {set i $cn1} {$i<[string len $st]} {} { ;# right part
          incr i
          set c [string index $st $i]
          if {[string is wordchar $c]} {set ::em::seltd $::em::seltd$c} break
        }
        break
      }
      incr ln1
    }
  }
}
#=== Mr. Preprocessor of 'prog'/'name'
proc ::em::prepr_pn {refpn {dt 0}} {
  upvar $refpn pn
  prepr_idiotic pn 1
  foreach gw [array names ::em::ar_geany] {
    prepr_1 pn $gw $::em::ar_geany($gw)
  }
  init_swc
  set PD [get_PD]
  if {$::em::prjname eq ""} {
    set ::em::prjname [::eh::get_underlined_name [file tail $PD]]
  }
  prepr_1 pn "PD" $PD                 ;# %PD is passed project's dir (PD=)
  prepr_1 pn "P_" [get_P_]            ;# ...underlined PD
  prepr_1 pn "PN" $::em::prjname      ;# %PN is passed dir's tail
  prepr_1 pn "N"  $::em::appN         ;# ID of menu application
  prepr_1 pn "mn" $::em::menufilename ;# %mn is the current menu
  prepr_1 pn "m"  $::em::exedir       ;# %m is e_menu.tcl dir
  prepr_1 pn "s"  $::em::seltd        ;# %s is a selected text
  prepr_1 pn "u"  $::em::useltd       ;# %u is %s underscored
  prepr_1 pn "lg" [::eh::get_language] ;# %lg is a locale (e.g. ru_RU.utf8)
  prepr_1 pn "AR" [get_AR]            ;# %AR is contents of #ARGS1: ..#ARGS99: line
  prepr_1 pn "L"  [get_L]             ;# %L is contents of %l-th line
  prepr_1 pn "TT" [::eh::get_tty $::em::linuxconsole] ;# %TT is a terminal
  set pndt [prepr_dt pn]
  if {$dt} {return $pndt} {return $pn}
}
#=== convert all Windows' "\" to Unix' "/"
proc ::em::prepr_win {refprog typ} {
  upvar $refprog prog
  if {[string last "/" $typ] > 0} {
    set prog [string map {"\\" "/"} $prog]
  }
}
#=== Mr. Preprocessor of 'prog'
proc ::em::prepr_prog {refprog typ} {
  upvar $refprog prog
  prepr_pn prog
  prepr_win prog $typ
}
#=== Mr. Preprocessor of 'name'
proc ::em::prepr_name {refname {aft 0}} {
  upvar $refname name
  return [prepr_pn name $aft]
}
#=== Mr. Preprocessor of 'call'
proc ::em::prepr_call {refname} { ;# this must be done for e_menu call line only
  upvar $refname name
  if {$::em::percent2 ne ""} {
    set name [string map [list $::em::percent2 "%"] $name]
  }
  prepr_1 name "PD" [get_PD]
  prepr_1 name "PN" $::em::prjname
  prepr_1 name "N" $::em::appN
}
#=== get menu item
proc ::em::menuit {line lt left {a 0}} {
  set i [string first $lt $line]
  if {$i < 0} {return ""}
  if {$left} {
    return [string range $line 0 [expr $i+($a)]]
  } else {
    return [string range $line [expr $i+[string length $lt]] end]
  }
}
#=== expand $macro (%M1, %MA ...) for $line marked with $lmark (R:, R/ ...)
proc ::em::expand_macro {lmark macro line} {
  set mc [string range $macro 0 2]  ;# $macro = %M1 arg1 %M1 arg2 ...
  if {![info exist ::em::ar_macros($mc)]} {
    set ::em::ar_macros($mc) {}
    foreach st $::em::menufile {
      set st [string trimleft $st]
      if {[string match $mc* $st]} {
        lappend ::em::ar_macros($mc) [string trimleft [string range $st 4 end]]
      }
    }
  }
  set pal [string map [list $mc \n] [lindex $::em::ar_macros($mc) 0]]
  set arl [string map [list $mc \n] [string range $macro 3 end]]
  set arglist [split "$arl " \n]
  set parlist [split "$pal " \n]
  if {[set n1 [llength $parlist]] != [set n2 [llength $arglist]]} {
    ::em::em_message "ERROR:\n\nMacro $mc parameters and arguments don't agree:\n  $n1 not equal $n2"
    return
  }
  set i1 [string first $lmark $line]
  set i2 [string first $lmark $line $i1+1]
  set lname [string range $line $i1+[string length $lmark] $i2-1]
  foreach line [lrange $::em::ar_macros($mc) 1 end] {
    if {[set i [string first ":" $line]]<0 && \
        [set i [string first "/" $line]]<0} {
      ::em::em_message "ERROR:\n\nMacro $mc error in line:\n  $line"
      return
    }
    set lmark [string range $line 0 $i]
    set line "$lmark$lname$lmark[string range $line $i+1 end]"
    foreach par $parlist arg $arglist {
      set par "\$[string trim $par]"
      if {$par ne "\$"} {
        set line [string map [list $par [string trim $arg]] $line]
      }
    }
    lappend ::em::menufile $line
  }
}
#=== check for and insert macro, if any
proc ::em::check_macro {line} {
  set line [string trimleft $line]
  set s1 "I:"
  if {[string first $s1 $line] != 0} {
    set s1 ""
    foreach marker {S: R: M: S/ R/ M/ SE: RE: ME: SE/ RE/ ME/ SW: RW: MW: SW/ RW/ MW/} {
      if {[string first $marker $line] == 0} {
        set s1 $marker
        break
      }
    }
  }
  if {$s1 ne ""} {
    #check for macro %M1..%M9, %Ma..%Mz, %MA..%MZ
    set im [expr {[string first $s1 $line 3]+[string length $s1]}]
    set s2 [string trimleft [string range $line $im end]]
    if {[regexp "^%M\[^ \] " $s2]} {
      ::em::expand_macro $s1 $s2 $line
      return
    }
  }
  lappend ::em::menufile $line
}
#=== read menu file
proc ::em::menuof {commands s1 domenu} {
  upvar $commands comms
  set seltd [get_seltd $s1]
  if {$domenu} {
	  if {$::em::ischild} {set ps "\u220e"} {set ps "\u23cf"}
    set ::em::menuttl "$ps [file rootname $seltd]"
    if {$::em::basedir eq ""} {
      set ::em::basedir [file join $::em::exedir menus]
    }
    set seltd [file normalize [get_menuname $seltd]]
    if {[catch {set chan [open "$seltd"]} e]} {
      ::em::addon create_template $seltd
      set ::em::start0 0  ;# no more messages
      return
    }
    set ::em::menufilename "$seltd"
    set ::em::menufile [list 0]
  }
  set prname "?"
  set iline $::em::begsel
  set doafter false
  set lappend "lappend comms"
  set ::em::commhidden {0}
  set hidden [set options [set ilmenu 0]]
  set separ ""
  while {1} {
    if {$domenu} {
      set doit 1
      set line ""
      while {1} { ;# lines ending with " \" or ::em::conti to be continued
        if {[gets $chan tmp] < 0} {set doit [string length $line]; break}
        if {[string range $tmp end end] eq "\\"} {
          append line [string range $tmp 0 end-1]
        } elseif {$::em::conti ne "\\" && $::em::conti ne "" && \
                 [string range $tmp end-$::em::lconti end]==$::em::conti} {
          append line $tmp
        } else {
          append line $tmp
          break
        }
      }
      if {$doit==0} break
      ::em::check_macro $line
    } else {
      incr ilmenu
      if {$ilmenu >= [llength $::em::menufile]} {break}
      set line [lindex $::em::menufile $ilmenu]
    }
    set line [set origline [string trimleft $line]]
    if {$line eq {[MENU]}} {
      ::em::init_menuvars $domenu $options
      set options [set hidden 0]
      continue
    }
    if {$line eq {[OPTIONS]}} {
      set options 1
      set hidden 0
      continue
    }
    if {$line eq {[HIDDEN]}} {
      ::em::init_menuvars $domenu $options
      set hidden 1
      set options 0
      set lappend "lappend ::em::commhidden"
    }
    if {$options} {
      if {[string match co=* $line]} {
        # co= affects the current reading of continued lines of menu
        set ::em::conti [string range $line 3 end]
        set ::em::lconti [expr {[string length $::em::conti] - 1}]
      } else {
        lappend ::em::menuoptions $line
      }
      continue
    }
    set typ [menuit $line ":" 1]
    if {[set l [string length $typ]] < 1 || $l > 3} {
      set typ [menuit $line "/" 1]
    }
    if {[set l [string length $typ]] < 1 || $l > 3} {
      set prname "?"
      continue
    }
    set line [menuit $line $typ 0]
    set name [menuit $line $typ 1 -1]
    set prog [string trimleft [menuit $line $typ 0]]
    prepr_init name
    # prepr_init prog  ;# v1.49: don't preprocess commands till their call
    prepr_win prog $typ
    catch {set name [subst $name]}  ;# any substitutions in names
    switch -- $typ {
      "I:" {   ;#internal (M, Q, S, T)
        prepr_pn prog
        set prom "RUN         "
        set runp "$prog"
      }
      "R/" -
      "R:"  {set prom "RUN         "
        set runp "::em::run $typ";   set amp "&$::em::mute"
      }
      "RE/" -
      "RE:"  {set prom "EXEC        "
        set runp "::em::run $typ"
        set amp "&$::em::mute"
        append amp "; ::em::on_exit 0"
      }
      "RW/" -
      "RW:" {set prom "RUN & WAIT  "
        set runp "::em::run $typ";   set amp "$::em::mute"
      }
      "S/" -
      "S:"  {set prom "SHELL       "
        set runp "::em::shell $typ"; set amp "&$::em::mute"
      }
      "SE/" -
      "SE:"  {set prom "SHELL       "
        set runp "::em::shell $typ"
        set amp "&$::em::mute"
        append amp "; ::em::on_exit 0"
      }
      "SW/" -
      "SW:" {set prom "SHELL & WAIT"
        set runp "::em::shell $typ"; set amp "$::em::mute"
      }
      "M/" -
      "M:"  {set prom "MENU        "
        set runp "::em::callmenu $typ"; set amp "&"
      }
      "MW/" -
      "MW:" {set prom "MENU & WAIT "
        set runp "::em::callmenu $typ"; set amp ""
      }
      "ME/" -
      "ME:" {set prom "MENU & EXIT "
        set runp "::em::callmenu $typ"; set amp "& ; ::em::on_exit 0"
      }
      default {
        set prname "?"
        continue
      }
    }
    set hot ""
    for {set fn 1} {$fn <= 12} {incr fn} {  ;# look up to F1-F12 hotkeys
      set s "F$fn "
      if {[set p [string first $s $name]] >= 0 &&
      [string trim [set s2 [string range $name 0 [incr $p -1]]]] eq ""} {
        incr p [expr [string len $s] -1]
        set name "$s2[string range $name $p end]"
        set hot [string trimright $s]
        break
      }
    }
    set origname $name
    if {$prname == $origname} {          ;# && $prtyp == $typ - no good, as
      set torun "$runp $s1 $amp"       ;# it doesn't unite R, E, S types
      set prog "$prprog\n$torun\r$prog"
    } else {
      if {[string trim $name "- "] eq ""} {    ;# is a separator?
        if {[string trim $name] eq "" && $::em::b0} {
          set separ "?[string trim $prog]?"    ;# yes, blank one
        } else {                               ;# ... or underlining
          set separ "?[expr {-[::apave::getN [string trim $prog] 1 1 33]}]?"
        }
        continue
      }
      if {$separ ne ""} {
        set name "$separ $name"  ;# insert separator into name
        set separ ""
      }
      set s1 [get_s1 [incr iline] $hidden]
      if {$typ eq "I:"} {
        set torun "$runp"  ;# internal command
      } else {
        set torun "$runp $s1 $amp"
      }
      if {$iline > $::em::maxitems} {
        em_message "Too much items in\n\n$seltd\n\n$::em::maxitems is maximum. \
                    Stopped at:\n\n$origline"
        exit
      }
      set prname $origname
      set ::em::itnames($iline) $origname   ;# - original item name
      if {[prepr_name name 1]} {
        set doafter true       ;# item names to be updated at intervals
      }
      if {$::em::ornament > 1} {
        {*}$lappend [list "$prom :$name" $torun $hot $typ]
      } else {
        {*}$lappend [list "$name" $torun $hot $typ]
      }
    }
    if {[string first $::em::extraspaces $prom]<0} {set ::em::extras false}
    set ::em::pars($s1) $prog
    set prprog $prog
  }
  if {$doafter} { ;# after N sec: check times/dates
    ::em::repeate_update_buttons
  }
  if {$domenu} {close $chan}
  ::em::init_menuvars $domenu $options
}
#=== prepare buttons' contents
proc ::em::prepare_buttons {refcommands} {
  upvar $refcommands commands
  if {$::em::itviewed <= 0} {
    for_buttons {
      set comm [lindex $commands $i]
      set name [lindex $comm 0]
      if {$::em::extras} {
        set name [string map [list $::em::extraspaces ""] $name]
        set comm [lreplace $comm 0 0 "$name"]
        set commands [lreplace $commands $i $i $comm]
      }
      set name [prepr_idiotic name 0]
      if {[set l [string length $name]] > $::em::itviewed}  {
        set ::em::itviewed $l
      }
    }
    if {$::em::itviewed < 5} {set ::em::itviewed $::em::viewed}
  }
  set ::em::font1a "\"[string trim $::em::font1 \"]\" $::em::fs"
  set ::em::font2a "\"[string trim $::em::font2 \"]\" $::em::fs"
  checkbutton .cb -text "On top" -variable ::em::ontop -fg $::em::clrhotk \
      -bg $::em::clrtitb -takefocus 0 -command {::em::addon staytop_toggle} \
      -font $::em::font1a
  grid [label .h0 -text [string repeat " " [expr $::em::itviewed -3]] \
      -bg $::em::clrinab] -row 0 -column 0 -sticky nsew
  grid .cb -row 0 -column 1 -sticky ne
  if {$::em::ncmd < 2} { ;# check the call string of e_menu
    if {$::em::start0} {puts "Run:\n tclsh e_menu.tcl \"s=%s\" m=menu"}
    exit
  }
  label .frame -bg $::em::clrinab -fg $::em::clrinab -state disabled \
    -takefocus 0
  if {[isheader]} {
    grid [label .h1 -text "Use arrow and space keys to take action" \
      -font $::em::font1a -fg $::em::clrhelp -bg $::em::clrinab -anchor s] \
      -columnspan 2 -sticky nsew
    grid [label .h2 -text "(or press hotkeys)\n" -font $::em::font1a \
      -fg $::em::clrhotk -bg $::em::clrinab -anchor n] -columnspan 2 -sticky nsew
  }
  tooltip::tooltip .cb "Press Ctrl+T to toggle"
  tooltip::tooltip delay 1000
  if {[isheader]} {set hlist {.h0 .h1 .h2}} {set hlist {.h0}}
  foreach l $hlist {
    bind $l <ButtonPress-1>   {::eh::mouse_drag 1 %x %y}
    bind $l <Motion>          {::eh::mouse_drag 2 %x %y}
    bind $l <ButtonRelease-1> {::eh::mouse_drag 3 %x %y}
  }
}
#=== repaint menu's items
proc ::em::repaint_menu {} {
  catch {
    ::em::initcolorscheme
    for_buttons {
      $b configure -fg [color_button $i] -bg [color_button $i bg] \
        -borderwidth $::em::bd -relief flat
      if {[winfo exists .frame.fr$i.arr]} {
        .frame.fr$i.arr configure -bg [color_button $i bg]
      }
    }
    ::em::focus_button $::em::lasti
  }
}
#=== shadow 'w' widget
proc ::em::shadow_win {w} {
  if {![catch {set ::em::bgcolr($w) [$w cget -bg]} e]} {
    if {[::apave::shadowAllowed]} {
      $w configure -bg $::em::clrgrey
    }
  }
}
#=== focus in/out
proc ::em::focused_win {focused} {
  set ::eh::mx [set ::eh::my 0]
  if {![::apave::shadowAllowed] || ($::em::skipfocused && [isMenuFocused])} {
    set ::em::skipfocused 0
    return
  }
  set ::em::skipfocused 0
  if {$focused && ![isMenuFocused]} {
    foreach wc [array names ::em::bgcolr] {
      if {[winfo exists $wc]} {
        if {![string match ".frame.fr*butt" $wc]} {
          catch {$wc configure -bg $::em::bgcolr($wc)}
        }
      }
    }
    ::tooltip::tooltip on
    set ::em::skipfocused 1  ;# to disable blinking FocusOut/FocusIn
    after idle ::em::repaint_menu  ;# important esp. for Windows
  } elseif {!$focused && [isMenuFocused]} {
    # only 2 generations of fathers & sons :(as nearly everywhere :(
    foreach w [winfo children .] {
      shadow_win $w
      foreach wc [winfo children $w] {
        shadow_win $wc
        foreach wc2 [winfo children $wc] {
          shadow_win $wc2
        }
      }
    }
    catch {.frame.fr$::em::lasti.butt configure -fg $::em::clrhotk}
    ::tooltip::tooltip off
    set ::eh::mx [set ::eh::my 0]
    update
  }
}
#=== prepare wildcards processing in menu items
proc ::em::prepare_wilds {per2} {
  if {[llength [array names ::em::ar_geany d]] != 1} { ;# it's obsolete
    set ::em::ar_geany(d) $::em::workdir             ;# (using %d as %PD)
  }
  if {$per2} {set ::em::percent2 "%"}    ;# reset the wild percent to %
  foreach _ {u p q d s} {prepr_pn ::em::${_}seltd}
  set ::em::useltd [string map {" " "_"} $::em::useltd]
  set ::em::pseltd [::eh::escape_links $::em::pseltd]
  set ::em::qseltd [::eh::escape_quotes $::em::qseltd]
  set ::em::dseltd [::eh::delete_specsyms $::em::dseltd]
  set ::em::sseltd [string trim $::em::sseltd]
}
#=== get pars
proc ::em::get_pars1 {s1 argc argv} {
  set ::em::pars($s1) ""
  for {set i $argc} {$i > 0} {} {
    incr i -1  ;# last option's value takes priority
    set s2 [string range [lindex $argv $i] 0 \
        [set l [expr [string len $s1]-1]]]
    if {$s1 == $s2} {
      set seltd [string range [lindex $argv $i] [expr $l+1] end]
      prepr_call seltd
      set ::em::pars($s1) $seltd
      return true
    }
  }
  return false
}
#=== get "project (working) directory"
proc ::em::initPD {seltd {doit 0}} {
  if {$::em::workdir eq "" || $doit} {
    if {[file isdirectory $seltd]} {
      set ::em::workdir $seltd
    } else {
      set ::em::workdir [pwd]
    }
    prepr_win ::em::workdir "M/"  ;# force converting
    catch {cd $::em::workdir}
  }
  if {[llength $::em::prjdirlist]==0 && [file isfile $seltd]} {
      # when PD is indeed a file with projects list
    set ch [open $seltd]
    foreach wd [split [read $ch] "\n"] {
      if {[string trim $wd] ne "" && ![string match "\#*" $wd]} {
        lappend ::em::prjdirlist $wd
      }
    }
    close $ch
  }
}
#=== initialize header of menu
proc ::em::init_header {s1 seltd} {
  set ::em::seltd [string map {\r "" \n ""} $::em::seltd]
  lassign [split $seltd \n] ::em::seltd ;# only 1st line (TF= for all)
  init_swc
  set ::em::useltd [set ::em::pseltd [set ::em::qseltd \
    [set ::em::dseltd [set ::em::sseltd $::em::seltd]]]]
  if {[isheader]} {
    lappend ::em::commands [list " HELP        \"$::em::seltd\"" \
        "::em::browse $s1"]
    if {[::iswindows]} {
      prepr_win seltd "M/"
      set ::em::pars($s1) $seltd
    }
    lappend ::em::commands [list " EXEC        \"$::em::seltd\"" \
        "::em::run RE: $s1 & ; ::em::on_exit"]
    lappend ::em::commands [list " SHELL       \"$::em::seltd\"" \
        "::em::shell RE: $s1 & ; ::em::on_exit"]
    set ::em::hotkeys "000$::em::hotsall"
  }
  set ::em::begsel [expr [llength $::em::commands] - 1]
}
#=== initialize main wildcards
proc ::em::prepare_main_wilds {{doit false}} {
  set from [file dirname $::em::ar_geany(f)]
  foreach {c attr} {d nativename D tail F tail e rootname x extension} {
    if {![info exists ::em::ar_geany($c)] || $::em::ar_geany($c) eq "" \
    || $doit} {
      set ::em::ar_geany($c) [file $attr $from]
    }
    if {$c eq "D"} {set from [file tail $::em::ar_geany(f)]}
  }
  set ::em::ar_geany(F_) [::eh::get_underlined_name $::em::ar_geany(F)]
}
#=== initialize ::em::commands from argv and menu
proc ::em::initcommands {lmc amc osm {domenu 0}} {
  set resetpercent2 0
  foreach s1 {a0= P= N= PD= PN= F= o= ln= cn= s= u= w= \
        qq= dd= ss= pa= ah= wi= += bd= b0= b1= b2= b3= b4= \
        f1= f2= fs= a1= a2= ed= tf= tg= md= wc= tt= \
        t0= t1= t2= t3= t4= t5= t6= t7= t8= t9= \
        s0= s1= s2= s3= s4= s5= s6= s7= s8= s9= \
        u0= u1= u2= u3= u4= u5= u6= u7= u8= u9= \
        i0= i1= i2= i3= i4= i5= i6= i7= i8= i9= \
        x0= x1= x2= x3= x4= x5= x6= x7= x8= x9= \
        y0= y1= y2= y3= y4= y5= y6= y7= y8= y9= \
        z0= z1= z2= z3= z4= z5= z6= z7= z8= z9= \
        a= d= e= f= p= l= h= b= cs= c= t= g= n= \
        fg= bg= fE= bE= fS= bS= fI= bI= cc= gr= ht= hh= rt= \
        m= om= ts= TF= yn= cb= in=} { ;# the processing order is important
    if {($s1 in {o= s= m=}) && !($s1 in $osm)} {
      continue
    }
    if {[get_pars1 $s1 $lmc $amc]} {
      set seltd [lindex [array get ::em::pars $s1] 1]
      if {!($s1 in {m= g= cb= in=})} {
        if {$s1 eq "s="} {
          set seltd [::eh::escape_specials $seltd]
        } elseif {$s1 in {f= d=}} {
          set seltd [string trim $seltd \'\"\`]  ;# for some FM peculiarities
        }
        set ::em::inherited "$::em::inherited \"$s1$seltd\""
      }
      set s01 [string range $s1 0 1]
      switch -- $s1 {
        P= {
          if {$seltd ne ""} {
            set ::em::percent2 $seltd  ;# set % substitution
          } else {
            set resetpercent2 1
          }   ;# must be reset to % after cycle
        }
        N= {set ::em::appN [::apave::getN $seltd 1]}
        PD= {
          set ::em::PD $seltd
          initPD $seltd
        }
        PN= {
          set ::em::prjname $seltd  ;# deliberately sets the project name
          set ::em::prjset 2
        }
        s= {::em::init_header $s1 $seltd}
        h= {
          set ::eh::hroot [file normalize $seltd]
          set ::em::offline true
        }
        m= {
          prepare_wilds $resetpercent2
          ::em::menuof ::em::commands $s1 $domenu
        }
        b= {set ::eh::my_browser $seltd}
        cs= {::apave::themeObj csAdd $seltd}
        c= {
          set ::ncolor [::apave::getN $seltd -1 -1 $::apave::_CS_(MAXCS)]
          ::em::initdefaultcolors
        }
        o= {set ::em::ornament [::apave::getN $seltd]}
        g= {
          lassign [split $seltd x+] w h x y
          if {$w ne "" && $x ne "" && $y ne ""} {
            set ::em::geometry ${w}x0+$x+$y  ;# h=0 to trim the menu height
          } else {
            set ::em::geometry $seltd
          }
        }
        u= {  ;# u=... overrides previous setting (in s=)
          set ::em::useltd [string map {" " "_"} $seltd]
        }
        t= {set ::em::dotop [::apave::getN $seltd] }
        s0= - s1= - s2= - s3= - s4= - s5= - s6= - s7= - s8= - s9=
        {
          set ::em::ar_s09($s1) $seltd
        }
        u0= - u1= - u2= - u3= - u4= - u5= - u6= - u7= - u8= - u9=
        {
          set ::em::ar_u09($s1) [string map {" " "_"} $seltd]
        }
        i0= - i1= - i2= - i3= - i4= - i5= - i6= - i7= - i8= - i9=
        {
          set ::em::ar_i09($s1) [::apave::getN $seltd]
        }
        w= {set ::em::itviewed [::apave::getN $seltd]}
        a= {set ::em::autorun $seltd}
        F= - f= - l= - p= - e= - d= {
          ;# d=, e=, f=, l=, p= are used as Geany wildcards
          lassign [split $seltd \n] seltd
          set ::em::ar_geany([string range $s1 0 0]) $seltd
        }
        n= {if {$seltd ne ""} {set ::em::menuttl $seltd}}
        ah= {set ::em::autohidden $seltd}
        a0= {if {$::em::start0} {run_tcl_commands seltd}}
        a1= {set ::em::commandA1 $seltd}
        a2= {set ::em::commandA2 $seltd}
        t0= {set ::eh::formtime $seltd }
        t1= {set ::eh::formdate $seltd }
        t2= {set ::eh::formdt   $seltd }
        t3= {set ::eh::formdw   $seltd }
        t4= - t5= - t6= - t7= - t8= -
        t9= {set ::em::ar_tformat([string range $s1 0 1]) $seltd}
        fs= {set ::em::fs [::apave::getN $seltd $::em::fs]}
        f1= {set ::em::font1 $seltd}
        f2= {set ::em::font2 $seltd}
        qq= {set ::em::qseltd [::eh::escape_quotes $seltd]}
        dd= {set ::em::dseltd [::eh::delete_specsyms $seltd]}
        ss= {set ::em::sseltd [string trim $seltd]}
        +=  {set ::em::pseltd [::eh::escape_links $seltd]}
        pa= {set ::em::pause [::apave::getN $seltd $::em::pause]}
        wc= - bd= - b0= - b1= - b2= - b3= - b4 {
          set ::em::$s01 [::apave::getN $seltd [set ::em::$s01]]
        }
        ed= {set ::em::editor $seltd}
        tg= - om= - cb= {set ::em::$s01 $seltd}
        md= {set ::em::basedir $seltd}
        tf= {set ::em::tf [::apave::getN $seltd $::em::tf]}
        in= {
          if {[set ip [string first . $seltd]]>0} {
            # get last item number and its HELP/EXEC/SHELL shift (begsel)
            set ::em::savelasti [::apave::getN [string range $seltd $ip+1 end] -1]
            if {$::em::savelasti>-1} {
              set ::em::lasti [::apave::getN [string range $seltd 0 $ip-1] 1]
              if {$::em::begsel==0} {
                incr ::em::lasti -$::em::savelasti  ;# header was, now is not
              } elseif {$::em::savelasti==0} {
                incr ::em::lasti $::em::begsel      ;# header was not, now is
              }
            }
          }
        }
        fg= - bg= - fE= - bE= - fS= - bS= - fI= - bI= - ht= - hh= - cc= - gr= {
          set ::em::clr$s01 $seltd
          if {[lsearch -glob $::em::insteadCSlist $s1*]<0} {
            lappend ::em::insteadCSlist $s1$seltd
          }
        }
        ts= {set ::em::truesel [::apave::getN $seltd]}
        ln= - cn= - yn= {set ::em::$s01 [::apave::getN $seltd]}
        rt= { ;# ratio "min.size / init.size"
          lassign [split $seltd /] i1 i2
          if {[string is integer $i1] &&[string is integer $i2] && \
              $i1!=0 && $i2!=0 && $i1/$i2<=1} {
            set ::em::ratiomin "$i1/$i2"
          }
        }
        tt= { ;# command for terminal (e.g. qterminal)
          set ::em::linuxconsole $seltd
        }
        default {
          if {$s1 in {TF=} || [string range $s1 0 0] in {x y z}} {
            ;# x* y* z* general substitutions
            set ::em::ar_geany([string map {"=" ""} $s1]) $seltd
          }
        }
      }
    }
  }
  # get %D (dir's tail) %F (file.ext), %e (file), %x (ext) wildcards from %f
  if {![info exists ::em::ar_geany(f)]} {
    set ::em::ar_geany(f) $::em::menufilename  ;# %f wildcard is a must
  }
  prepare_main_wilds
  prepare_wilds $resetpercent2
  set ::em::ncmd [llength $::em::commands]
  initPD [pwd]
}
#=== get a list of colors used by e_menu
proc ::em::colorlist {} {
  return [list clrtitf clrinaf clrtitb clrinab clrhelp \
    clractb clractf clrcurs clrgrey clrhotk fI bI]
}
#=== clear off default colors
proc ::em::unsetdefaultcolors {} {
    foreach c {fg bg fE bE fS bS fI bI ht hh cc gr} {catch {unset ::em::clr$c}}
}
#=== set default colors from color scheme
proc ::em::initcolorscheme {{nothemed false}} {
  if {$nothemed} unsetdefaultcolors
  set clrs [::em::colorlist]
  lassign [::apave::themeObj csGet $::ncolor] {*}$clrs
  foreach clr $clrs {set ::em::$clr [set $clr]}
  ::apave::themeObj basicFontSize $::em::fs
  ::apave::themeObj basicTextFont $::em::font1
  # set real colors, based on fg=, bg=, fS=, bS=, gr= arguments of e_menu
  if {[info exist ::em::clrfg]} {set ::em::clrinaf $::em::clrfg}
  if {[info exist ::em::clrbg]} {set ::em::clrinab $::em::clrbg}
  if {[info exist ::em::clrfE]} {set ::em::clrtitf $::em::clrfE}
  if {[info exist ::em::clrbE]} {set ::em::clrtitb $::em::clrbE}
  if {[info exist ::em::clrfS]} {set ::em::clractf $::em::clrfS}
  if {[info exist ::em::clrbS]} {set ::em::clractb $::em::clrbS}
  if {[info exist ::em::clrhh]} {set ::em::clrhelp $::em::clrhh}
  if {[info exist ::em::clrgr]} {set ::em::clrgrey $::em::clrgr}
  if {[info exist ::em::clrcc]} {set ::em::clrcurs $::em::clrcc}
  if {[info exist ::em::clrht]} {set ::em::clrhotk $::em::clrht}
  if {$fI ne ""} {set ::em::clrfI $fI}
  if {$bI ne ""} {set ::em::clrbI $bI}
  if {[winfo exist .frame]} {
    . configure -bg [.frame cget -bg]
  } else {
    . configure -bg $::em::clrinab
  }
}
#=== set default colors if not set by call of e_menu
proc ::em::initdefaultcolors {} {
  if {$::ncolor>=$::apave::_CS_(MINCS) && $::ncolor<=$::apave::_CS_(MAXCS)} {
    lassign [::apave::themeObj csSet $::ncolor] \
      ::em::clrfg ::em::clrbg ::em::clrfE ::em::clrbE \
      ::em::clrfS ::em::clrbS ::em::clrhh ::em::clrgr ::em::clrcc
  }
}
#=== prepend initialization
proc ::em::initcommhead {} {
  set ::em::begsel 0
  set ::em::hotkeys $::em::hotsall
  set ::em::inherited ""
  set ::em::commands {0}
}
#=== initialize commands
proc ::em::initcomm {} {
  initcommhead
  array unset ::em::ar_macros *
  array set ::em::ar_macros [list]
  set ::em::menuoptions {0}
  if {[lsearch $::argv "ch=1"]>=0} {set ::em::ischild 1}
  # external E_MENU_OPTIONS are in the beginning of ::argv (being default)
  # if "b=firefox", OR in the end (being preferrable) if "99 b=firefox"
  if {!($::em::ischild || [catch {set ext_opts $::env(E_MENU_OPTIONS)}])} {
    set inpos 0
    foreach opt [list {*}$ext_opts] {
      if [string is digit $opt] {set inpos $opt; continue}
      set ::argv [linsert $::argv $inpos $opt]
      incr inpos
      incr ::argc
    }
  }
  if {[lsearch -glob $::argv "s=*"]<0} {
    ;# if no s=selection, make it empty to hide HELP/EXEC/SHELL
    lappend ::argv s=
    incr ::argc
    if {[set io [lsearch -glob $::argv "o=*"]]<0} {
      lappend ::argv "o=0"
      incr ::argc
    } else {
      set o [string index [lindex $::argv $io] end]
      if {$o in {1 3}} {
        set ::argv [lreplace $::argv $io $io "o=0"]
      }
    }
  }
  initcommands $::argc $::argv {o= s= m=} 1
  if {[set lmc [llength $::em::menuoptions]] > 1} {
      # o=, s=, m= options define menu contents & are processed particularly
    initcommands $lmc $::em::menuoptions {o=}
    initcommhead
    if {$::em::om} {
      initcommands $::argc $::argv {s= m=}
      initcommands $lmc $::em::menuoptions {o=}
    } else {
      initcommands $lmc $::em::menuoptions " "
      initcommands $::argc $::argv {o= s= m=}
    }
  }
}
#=== initialize main properties
proc ::em::initmain {} {
  if {$::em::pause > 0} {after $::em::pause}  ;# pause before main inits
  if {$::em::appN > 0} {
    set ::em::appname $::em::thisapp$::em::appN     ;# set N of application
  } else {
    ;# otherwise try to find it
    for {set ::em::appN 1} {$::em::appN < 64} {incr ::em::appN} {
      set ::em::appname $::em::thisapp$::em::appN
      if {[catch {send -async $::em::appname {update idletasks}} e]} {
        break
      }
    }
  }
  tk appname $::em::appname
  set imgArr {iVBORw0KGgoAAAANSUhEUgAAAAoAAAAMCAYAAABbayygAAADAFBMVEUAAAD/AAAA/wD//wAAAP//
AP8A///////b29u2traSkpJtbW1JSUkkJCTbAAC2AACSAABtAABJAAAkAAAA2wAAtgAAkgAAbQAA
SQAAJADb2wC2tgCSkgBtbQBJSQAkJAAAANsAALYAAJIAAG0AAEkAACTbANu2ALaSAJJtAG1JAEkk
ACQA29sAtrYAkpIAbW0ASUkAJCT/29vbtra2kpKSbW1tSUlJJCT/trbbkpK2bW2SSUltJCT/kpLb
bW22SUmSJCT/bW3bSUm2JCT/SUnbJCT/JCTb/9u227aStpJtkm1JbUkkSSS2/7aS25Jttm1Jkkkk
bSSS/5Jt221JtkkkkiRt/21J20kktiRJ/0kk2yQk/yTb2/+2ttuSkrZtbZJJSW0kJEm2tv+Skttt
bbZJSZIkJG2Skv9tbdtJSbYkJJJtbf9JSdskJLZJSf8kJNskJP///9vb27a2tpKSkm1tbUlJSST/
/7bb25K2tm2SkkltbST//5Lb2222tkmSkiT//23b20m2tiT//0nb2yT//yT/2//bttu2kraSbZJt
SW1JJEn/tv/bktu2bbaSSZJtJG3/kv/bbdu2SbaSJJL/bf/bSdu2JLb/Sf/bJNv/JP/b//+229uS
trZtkpJJbW0kSUm2//+S29tttrZJkpIkbW2S//9t29tJtrYkkpJt//9J29sktrZJ//8k29sk////
27bbtpK2km2SbUltSSRJJAD/tpLbkm22bUmSSSRtJAD/ttvbkra2bZKSSW1tJElJACT/krbbbZK2
SW2SJEltACTbtv+2ktuSbbZtSZJJJG0kAEm2kv+SbdttSbZJJJIkAG222/+SttttkrZJbZIkSW0A
JEmStv9tkttJbbYkSZIAJG22/9uS27ZttpJJkm0kbUkASSSS/7Zt25JJtm0kkkkAbSTb/7a225KS
tm1tkklJbSQkSQC2/5KS221ttklJkiQkbQD/tgDbkgC2bQCSSQD/ALbbAJK2AG2SAEkAtv8AktsA
bbYASZIAAAAAAADPKgIEAAAAZUlEQVQY03XP0Q0AIQgD0GIcxWVwYFnGXXpfXBShiQnoiyJIgiRU
lV5nq+HInJMockFVLfEFxxglbnGjwi17JmIRyaFjD0n083Dv/ddmhrWWeN/jTWYGABd6ZqxQ+pkM
PbBCAPABKF9B+b41+J0AAAAASUVORK5CYII=}
  ::em::initcolorscheme
  set ::lin_console [file join $::em::exedir "$::lin_console"]
  set ::win_console [file join $::em::exedir "$::win_console"]
  set ::img [image create photo -data $imgArr]
  for {set i 0} {$i <=9} {incr i} {set ::em::ar_i09(i$i=) 1 }
  if {[set ::em::insteadCS [expr {[llength $::em::insteadCSlist]==12}]]} {
    ::em::theming_pave
    set ::ncolor [::apave::themeObj csCurrent]
    ::em::initcolorscheme
  }
}
#=== initialize hotkeys for popup menu etc.
proc ::em::inithotkeys {} {
  foreach {t e r d g p} {t e r d g p T E R D G P} {
    bind . <Control-$t> {.cb invoke}
    bind . <Control-$e> {::em::addon edit_menu}
    bind . <Control-$r> {::em::addon reread_init}
    bind . <Control-$d> {::em::addon destroy_emenus}
    bind . <Control-$p> {::em::addon change_PD}
  }
  bind . <Button-3>  {::em::addon popup %X %Y}
  bind . <F1> {::em::addon help}
  update
}
#=== make e_menu's menu
proc ::em::initmenu {} {
  inithotkeys
  prepare_buttons ::em::commands
  set capsbeg [expr {36 + $::em::begsel}]
  for_buttons {
    set hotkey [string range $::em::hotkeys $i $i]
    set comm [lindex $::em::commands $i]
    set prbutton "::em::pr_button $i [lindex $comm 1]"
    set prkeybutton [::eh::ctrl_alt_off $prbutton]  ;# for hotkeys without ctrl/alt
    set comtitle [string map {"\n" " "} [lindex $comm 0]]
    if {$i > $::em::begsel} {
      if {$i < ($::em::begsel+10)} {
        bind . <KP_$hotkey> "$prkeybutton"
      } elseif {($capsbeg-$i)>0} {
        bind . <KeyPress-[string toupper $hotkey]> "$prkeybutton"
      }
      bind . <KeyPress-$hotkey> "$prkeybutton"
      set t [string trim $comtitle]
      set hotk [lindex $comm 2]
      if {[string len $hotk] > 0} {
        bind . <$hotk> "$prbutton"
        set hotkey "$hotk, $hotkey"
      }
    } else {
      set hotkey ""
    }
    prepr_09 comtitle ::em::ar_i09 "i"
    prepr_idiotic comtitle 0
    lassign [s_assign comtitle 0] p1 p2
    if {$p2 ne ""} {
      set pady [::apave::getN $p1 0]
      if {$pady < 0} {
        grid [ttk::separator .frame.lu$i -orient horizontal] \
            -pady [expr -$pady-1] -sticky we \
            -column 0 -columnspan 2 -row [expr $i+$::em::isep]
      } else {
        grid [label .frame.lu$i -font "Sans 1" -fg $::em::clrinab \
            -bg $::em::clrinab] -pady $pady \
            -column 0 -columnspan 2 -row [expr $i+$::em::isep]
      }
      incr ::em::isep
    }
    ttk::frame .frame.fr$i
    if {[string first "M" [lindex $comm 3]] == 0} { ;# is menu?
      set img "-image $::img"     ;# yes, show arrow
      button .frame.fr$i.arr {*}$img -relief flat -overrelief flat \
        -highlightthickness $::em::b0 -bg [color_button $i bg] -command "$b invoke"
    } else {set img ""}
    button $b -text "$comtitle" -pady $::em::b1 -padx $::em::b2 -anchor w \
      -font $::em::font2a -width $::em::itviewed -borderwidth $::em::bd \
      -relief flat -overrelief flat -highlightthickness $::em::b0 \
      -fg [color_button $i] -bg [color_button $i bg] -command "$prbutton" \
      -activeforeground [color_selected_button $i] \
      -activebackground [color_selected_button $i bg]
    if {$img eq "" && \
    [string len $comtitle] > [expr $::em::itviewed * $::em::ratiomin]} \
      {tooltip::tooltip $b "$comtitle"}
    grid [label .frame.l$i -text $hotkey -font "$::em::font1a bold" -bg \
      $::em::clrinab -fg $::em::clrhotk] -column 0 -row [expr $i+$::em::isep] -sticky ew
    grid .frame.fr$i -column 1 -row  [expr $i+$::em::isep] -sticky ew \
        -pady $::em::b3 -padx $::em::b4
    pack $b -expand 1 -fill both -side left
    if {$img ne ""} {
      pack .frame.fr$i.arr -expand 1 -fill both
      bind .frame.fr$i.arr <Motion> "::em::focus_button $i"
      bind .frame.fr$i.arr <Enter> "::em::focus_button $i false"
      #bind .frame.fr$i.arr <Leave> "::em::focus_button -1 false"
    }
    bind $b <Motion>   "::em::focus_button $i"
    bind $b <Enter>    "::em::focus_button $i false"
    #bind $b <Leave>    "::em::focus_button -1 false"
    bind $b <Down>     "::em::mouse_button [expr $i+1]"
    bind $b <Tab>      "::em::mouse_button [expr $i+1]"
    bind $b <Up>       "::em::mouse_button [expr $i-1]"
    bind $b <Home>     "::em::mouse_button 99"
    bind $b <End>      "::em::mouse_button 0"
    bind $b <Prior>    "::em::mouse_button 99"
    bind $b <Next>     "::em::mouse_button 0"
    bind $b <Return>   "$prbutton"
    bind $b <KP_Enter> "$prbutton"
    if {$img ne ""} {bind $b <Right> "$prkeybutton"}
    if {[::iswindows]} {
      bind $b <Shift-Tab> "::em::mouse_button [expr $i-1]"
    } else {
      bind $b <ISO_Left_Tab> "::em::mouse_button [expr $i-1]"
    }
  }
  grid .frame -columnspan 2 -sticky ew
  grid columnconfigure . 0 -weight 1
  grid rowconfigure    . 0 -weight 0
  grid rowconfigure    . 1 -weight 1
  grid rowconfigure    . 2 -weight 1
  grid columnconfigure .frame 1 -weight 1
  update
  set isgeom [string len $::em::geometry]
  wm title . "${::em::menuttl}"
  if {$::em::start0==1} {
    if {!$isgeom} {
      wm geometry . $::em::geometry
    }
  }
  if {$::em::minwidth == 0} {
    set ::em::minwidth [expr [winfo width .] * $::em::ratiomin]
    set minheight [winfo height .]
  } else {
    set minheight [expr [winfo height .frame] +  [winfo height .cb] + 1]
  }
  wm minsize . $::em::minwidth $minheight
  if {$::em::start0} {
    wm geometry . [winfo width .]x${minheight}
    if {$::em::wc || [::iswindows] && $::em::start0==1} {
      ::eh::center_window . 0   ;# omitted in Linux as 'wish' is centered in it
    }
  }
}
#=== exit (end of e_menu)
proc ::em::on_exit {{really 1}} {
  if {!$really && $::em::ontop} return  ;# let a menu stay on top, if so decided
  if {$::em::cb ne ""} {    ;# callback the menu (i.e. the caller)
    set ::em::cb [string map {< = > =} $::em::cb]
    if {[catch {exec tclsh {*}$::em::cb "&"} e]} {d $e}
  }
  # remove temporary files, at closing a parent menu
  if {!$::em::ischild} {
    catch {file delete {*}[glob "[file dirname $::em::menufilename]/*.tmp~"]}
  }
  exit
}
#=== run Tcl commands passed in a1=, a2=
proc ::em::run_tcl_commands {icomm} {
  upvar $icomm comm
  if {$comm ne ""} {
    prepr_call comm
    eval $comm
    set comm ""
  }
}
#=== run i-th menu item
proc ::em::run_it {i {hidden 0}} {
  if {$hidden} {
    lassign [lindex $::em::commhidden $i] name torun hot typ
  } else {
    lassign [lindex $::em::commands $i] name torun hot typ
  }
  {*}$torun
}
#=== run auto list a=
proc ::em::run_auto {alist} {
  foreach task [split $alist ","] {
    for_buttons {
      if {$task == [string range $::em::hotkeys $i $i]} {
        $b configure -fg $::em::clrhotk
        run_it $i
      }
    }
  }
}
#=== run auto list ah=
proc ::em::run_autohidden {alist} {
  foreach task [split $alist ","] {   ;# task=1 (2,...,a,b...)
    set i [string first $task $::em::hotsall]  ;# hotsall="012..ab..."
    if {$i>0 && $i<=[llength $::em::commhidden]} {
      run_it $i true
    }
  }
}
#=== run tasks assigned in a= (by their hotkeys)
proc ::em::initauto {} {
  if {"${::em::commandA1}${::em::commandA2}" ne ""} {
    catch {wm geometry . $::em::geometry} ;# possible messages to be centered
  }
  run_tcl_commands ::em::commandA1    ;# exec the command as first init
  run_auto $::em::autorun
  run_autohidden $::em::autohidden
  run_tcl_commands ::em::commandA2    ;# exec the command as last init
  if {$::em::ischild} {
    bind . <Left> [::eh::ctrl_alt_off "::em::on_exit"]
    after 50 {focus -force . ; ::em::focus_button $::em::lasti}
  }
  if {$::em::lasti < $::em::begin} {set ::em::lasti $::em::begin}
  ::em::focus_button $::em::lasti
}
#=== begin inits
proc ::em::initbegin {} {
  encoding system "utf-8"
  option add *Menu.tearOff 1
  set e_menu_icon {iVBORw0KGgoAAAANSUhEUgAAAFwAAAB3CAMAAAC5WtefAAAC91BMVEUAAQAABQkHCQUECg0HDRAJ
DxEKEBIOExUTFxkVGRsRGxwVHh8ZIyMaKDcjKjAeLDElLDIiLzUnLjQjMTYkMjcmMzgoNjsrOT4s
Oj89Oz4rRF0sRV4wRkotRV8vSFEvR2E5R0wwSGI1Sk42SV4ySmQyTFU3TVE6TWM6T1M8T2Q2UWU9
UGU8UlY3UmY9U1dAU2g6VWlCVWo8V2tCWFw/WWJFWG0/Wm5FWl9HWW9CXGVIW3BCXXFGX2lKXXJL
XnREYmVAY3dNYHZaX2FJY2xCZnlQY3lEZ3pLaGtNZ3BSZXtXZXdNa25Ia35aaHpPbXBKbYFcanxN
b3dRb3FMb4NScHNdbH5fbX9Xb4pNdIFVc3Zgb4FPdoNicYNQd4RSdolYd3lSeYZbeXxmdYdce31V
fIpod4lreYtagIJte41agY5ufY9cg5FvfpBwf5FehZJghohygZNzgpRgiJViiZd1hJZki4xki5lm
jI53hphnjY9pj5F+ipdikp5pkZ6BjZqEj5xnl6Nvlpdwl6WGkp9rm6eLlqNwn5+Rlphvn6yNmKZw
oK1yoaFto7R0o6Nyo6+Qm6iRnap2pqV1prJvqLNyp7l8otCVoK5xqrWWoa90qrtyrLd7q6uYpLF4
rb+aprN2sLp/r698sLZ7sMKFq9qcqLWeqrd9s8V/tLmPr9mGtraBt8mmrraAusWJurqDvLupsbmT
tN2Gu8CGu86Fvr2atdmIvcKKv8Wutr+Kv9KLwdOFxMeKxMKGxdaMxsSzu8OIx8uPxdePyce2v8eS
y8q5wcmOzdG6w8uVz828xMyR0NST0dWV09fAyNCX1tnCy9PEzdWa2dyY29ic2t7Hz9eV3uDI0NjM
0dSb39uY4OLK0trO09ae4t6b4+XQ1dic5efR19me5+nY2tag6evV292i6uzX3N+j6+3Z3uGk7e/a
3+Lb4OOm7/Hc4uTe4+Xg5ejh5unj6evl6u3p7vHs8fTt8vXF//7v9ffw9vjy9/r4+vf3/P/6/Pn+
//xHxg7hAAAAiUlEQVRo3u3aQQqAIBAFUE/Qvu5/LDfeJKKgVRjGGOj7B3gbZfwDphyYlNewHPgW
FDg8Gi+1wEPw5SnwUyrwcfCg22K29MW9oXB4DS8fA3+FX8vdjbeuh3D4rLjZ8jPuDYXDdUVTsWtX
bD1GOHxW3GzRFeFwuK6oK6oWcLiuqCvC4SPgkX9EA7MDEZgCNv53DCQAAAAASUVORK5CYII=}
  ::apave::setAppIcon . $e_menu_icon
}
#=== end up inits
proc ::em::initend {} {
  bind . <FocusOut> {if {"%W" eq "."} {::em::focused_win false}}
  bind . <FocusIn>  {::em::focused_win true}
  bind . <Control-t> {.cb invoke}
  bind . <Escape> {
    if {$::em::yn && ![Q $::em::menuttl "Quit e_menu?" \
      yesno ques YES "-t 0 -a {-padx 50}"]} return
    ::em::on_exit
  }
  bind . <Control-Left>  {::em::addon win_width -1}
  bind . <Control-Right> {::em::addon win_width 1}
  wm protocol . WM_DELETE_WINDOW {::em::on_exit}
  if {$::em::dotop} {.cb invoke}
  after idle [list ::em::mouse_button $::em::lasti]
  wm geometry . $::em::geometry
  ::eh::checkgeometry
  if {[::iswindows]} {
    if {[wm attributes . -alpha] < 0.1} {wm attributes . -alpha 1.0}
  } else {
    catch {wm deiconify . ; raise .}
    catch {exec chmod a+x "$::lin_console"}
  }
  set ::em::start0 0
  ::apave::shadowAllowed true
}
::apave::initWM
::em::initbegin
::em::initdefaultcolors
::em::initcolorscheme
::em::initcomm
::em::initmain
::em::initmenu
::em::initauto
::em::initend
# *****************************   EOF   *****************************
############# getting an external CS to put into apave CSs:
# set cc [::apave::themeObj csCurrent]
# set ca [::apave::themeObj csMax]
# if {[catch {::em::em_message "[::apave::themeObj csGetName $cc]: $cc \
   of $ca:\n\n[::apave::themeObj csGet $ca]" ok "CS" -text 1 -w 99} e]} {M $e}
# *****************************   EOF   *****************************
