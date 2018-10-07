#! /usr/bin/env tclsh
#
# Running context menu's commands
#   e.g. calling Tcl/Tk help pages from www.tcl.tk
#
# For details see readme.md.
# *******************************************************************
# Scripted by Alex Plotnikov
# *******************************************************************

package require Tk
package require tooltip
#~ catch {package require tkdnd}  ;# optional package (still not working in e_menu)

set menudir [file normalize [file dirname $::argv0]]
source [file join $::menudir "src" "e_help.tcl"]
set thisapp e_menu_by_aplsimple
set appname $thisapp

# *******************************************************************
# customized block

set offline false   ;# set true for offline help

set lin_console "src/run_pause.sh"   ;# (for Linux)
set win_console "src/run_pause.bat"  ;# (for Windows)

set ncolor 0        ;# index of color scheme
set colorschemes {
   { #FFFFFF #FEEFA8 #566052 #4D554A #FFFFFF #94A58E #000000  #FFA500 grey}
   { #FFFFFF #FEEC9A #212121 #262626 #C5C5C5 #575757 #FFFD38  #9C2727 grey}
   { #000000 #3D2B06 #F6FCEC #EAF5D7 #0E280E #B9C4A6 #000000  #9C2727 grey}
   { #000000 #2B1E05 #BFFFBF #CFFFCF #0E280E #89CA89 #000000  #9C2727 #C7FFC7}
   { #000000 #2B1E05 #AAD3FA #9BCCFB #070757 #6DA3D9 #000000  #9C2727 grey}
   { white   white   red     red     yellow  white   black    yellow  magenta}
   { #FFFFFF #FEEC9A #3E534B #3B4F47 #FFFFFF #323935 #FFFD38  #FFA500 grey}
   { #FFFFFF #FEEC9A #402E03 #302202 #FFFFFF #DEDBAA #000000  #E34E00 grey}
   { #FFFFFF #FEEC9A #240836 #160124 #FFFFFF #DEDBAA #000000  #C24300 grey}
   { #FFFFFF #FEEC9A #002E00 #002600 #FFFFFF #DEDBAA #000000  #C24300 grey}
   { #000000 #2B1E05 #FCDEE3 #FCDEE3 #570957 #623864 #FFFFFF  #9C2727 grey}
   { #000000 #2B1E05 #C2C5CC #C2C5CC #1C1C5C #797880 #F0F0F0  #693F05 grey}
   { #000000 #2B1E05 #BFFFBF #CFFFCF #0E280E #89CA89 #000000  #9C2727 grey}
} ;# = text1  text2  header  items   itemsHL selbg   selfg    hot     greyed
   # ::colr ::colr0 ::colr1 ::colr2 ::colr2h ::colr3 ::colr4 ::colrhot ::colrgrey

set fs 12                     ;# font size
set font1 "Liberation Sans"   ;# font of header
set font2 "Liberation Mono"   ;# font of item

set viewed 40      ;# width of item (in characters)
set maxitems 45    ;# maximum of menu.txt items
set timeafter 5    ;# interval (in sec.) for updating times/dates

# *******************************************************************
# internal trifles: D - message, Q - question, S - console

# called in I: menu item, $ escaped as \$, CLI commands devided with \n, e.g.:
# I: Xterm in "%PD" I: D run bash in %PD; if {[Q BASH "Want to bash?"]} {cd "%PD"; S bash}
# I: Xterm in "%PD" (mute) I: cd "%PD"; S bash
# I: Console commands I: S dir \n echo \$PWD \n date

proc D {args} {::em::message_box "$args"}
proc Q {ttl mes {typ okcancel}} { return [::question_box $ttl $mes $typ] }
proc S {args} {
    set cc ""; foreach c $args {set cc "$cc$c "}
    ::em::shell_run "Nobutt" "S:" shell1 - "noamp" [string map {"\\n" "\r"} $cc]
}
proc EXIT {} {::em::on_exit}

# *******************************************************************
# e_menu's procedures

namespace eval em {

set ratiomin "3/5"
set hotsall "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
set hotkeys $hotsall
set workdir [pwd]
set prjname [file tail [pwd]]
set ornament 1  ;# 1 - header only; 2 - prompt only; 3 - both; 0 - none
set inttimer 1  ;# interval to check the timed tasks
set widthi 300
set bd 1
set b1 1
set b2 1
set b3 1
set b4 1
set incwidth 15
set wc 0
set tf 15
set tg 80x32+300+100
set om 1
#---------------
set mute "*S*"
set begin 1
set begtcl 3
set begsel $begtcl
#---------------
set editor ""
set percent2 ""
set commandA1 ""
set commandA2 ""
set minwidth 10
#---------------
set seltd ""
set useltd ""
set qseltd ""
set dseltd ""
set pseltd ""
set ontop 0
set dotop 0
set extraspaces "      "
set extras true
set ncmd 0
set lasti 1
set minwidth 0
array set pars {}
array set itnames {}
array set bgcolr {}
array set arr_s09 {}
array set arr_u09 {}
array set arr_i09 {}
array set arr_geany {}
array set arr_tformat {}
set itviewed 0
set geometry ""
set ischild 0
set menuttl ""
set menufilename ''
set inherited ""
set autorun ""
set commands ""
set menuoptions ""
set menufile {0}
set autohidden ""
set commhidden ""
set pause 0
set appN 0
set tasks {}
set taski {}
set mx 0
set my 0
set isep 0
set start0 1
set ipos 0
set TN 0
set prjset 0
set skipfocused 0
set cb ""
                    ;#====== own message box
proc message_box {mes {typ ok} {ttl ""}} {
    set colr [. cget -bg]
    ::message_box $mes $typ $ttl
    . configure -bg $colr
    update
}
                    ;#====== own question box
proc question_box {ttl mes {typ okcancel}} {
    set colr [. cget -bg]
    set rv [::question_box $ttl $mes $typ]
    . configure -bg $colr
    update
    return $rv
}
                    #====== to incr/decr window width
proc win_width {inc} {
    set inc [expr $inc*$::em::incwidth]
    lassign [split [wm geometry .] +x] newwidth height
    incr newwidth $inc
    if { $newwidth > $::em::minwidth || $inc > 0} {
        wm geometry . ${newwidth}x${height} }
}
                    #====== to re-read and update menu after Ctrl+R
proc reread_menu {} {
    #~ foreach w {.h0 .h1 .h2 .frame} {
        #~ catch {tkdnd::drop_target unregister $w *} }
    foreach w [winfo children .] {  ;# remove Tcl/Tk menu items
        destroy $w
    }
    initcomm
    initmenu
    focus_button $::em::begin
}
                    #====== to reread and autorun
proc reread_init {} {
    reread_menu
    initauto
}
                    #====== to check is there a header of menu
proc isheader {} {
    return [expr {$::em::ornament == 1 || $::em::ornament == 3} ? 1 : 0]
}
                    #====== to get an item color
proc color_button {i} {
    if {$i > $::em::begsel && [.frame.butt$i cget -image] == "" } {
        return $::colr0   ;# common item
    }
    return $::colr2h  ;# HELP/EXEC/SHELL or submenu
}
                    #====== to put i-th button in focus
proc focus_button {i} {
    if {$i>=$::em::ncmd} {set i $::em::begin}
    if {$i<$::em::begin} {set i [expr $::em::ncmd-1]}
    if {[.frame cget -bg] == $::colrgrey} {
        .frame.butt$i configure -bg $::colrgrey
    } else {
        if {$::em::lasti >= $::em::begin && $::em::lasti < $::em::ncmd} {
            .frame.butt$::em::lasti configure \
                -bg $::colr2 -fg [color_button $::em::lasti]
        }
        .frame.butt$i configure -bg $::colr3 -fg $::colr4
    }
    set ::em::lasti $i
    update idletasks
    focus .frame.butt$i
}
                    #====== to highlight a button (focused)
proc highlight_button {ib} {
    if {[.frame cget -bg] != $::colrgrey} {
        foreach w [winfo children .frame] {
            if {[string first ".frame.butt" $w] == 0} {
                set i [string trim $w ".frame.butt"]
                if {$i == $ib} {
                    $w configure -bg $::colr3 -fg $::colr4
                } else {
                    $w configure -bg $::colr2 -fg \
                        [color_button $i]
                }
            }
        }
    }
}
                    #====== 'proc' all buttons
proc for_buttons {proc} {
    set ::em::isep 0
    for {set j $::em::begin} {$j < $::em::ncmd} {incr j} {
        uplevel 1 "set i $j; set b .frame.butt$j; $proc" }
}
                    #====== to get contents of s1 argument (s=,..)
proc get_seltd { s1 } {
    return [lindex [array get ::em::pars $s1] 1]
}
                    #====== to get a calling mode
proc silent_mode {amp} {
    set silent [string first $::em::mute " $amp"]
    if {$silent > 0} {
        set amp [string map [list $::em::mute ""] "$amp"]
    }
    return [list $amp $silent]
}
                    #====== to edit file(s)
proc edit {fname} {
    if {$::em::editor == ""} {
        return [::edit_file $fname]
    } else {
        if {[catch {exec $::em::editor {*}$fname &} e]} {
            message_box "ERROR: couldn't call $::em::editor'\n
to edit $fname.\n\nCurrent directory is [pwd]\n\nMaybe $::em::editor\n is worth including in PATH?"
            return false
        }
    }
    return true
}
                    #====== VIP commands need internal processing
proc vip {cmd} {
    prepr_win cmd "M/"  ;# force converting
    set cd [string range $cmd 0 2]
    if { ([::iswindows] && [string toupper $cd] == "CD ") || $cd == "cd " } {
        if {[set cd [string trim [string range $cmd 3 end]]] != "."} {cd $cd}
        return true
    }
    if {$cd == "%E " || $cd == "%e "} { ;# edit file
        return [::em::edit [string range $cmd 2 end]]
    }
    return false
}
                    #====== to escape double quotes
proc escape_quotes {sel mto} {
    if {![::iswindows]} {
        set sel [string map [list "\"" $mto] $sel]
    }
    return $sel
}
                    #====== to prepare "search links" for browser
proc escape_links {sel} {
    return [string map [list " " "+"] $sel]
}
                    #====== to delete specials & underscore spaces
proc delete_specsyms {sel {und "_"} } {
    return [string map [list \
        "\"" ""  "\%" ""  "\$" ""  "\}" ""  "\{" "" \
        "\]" ""  "\[" ""  "\>" ""  "\<" ""  "\*" ""  " " $und] $sel]
}
                    #====== to time task
proc ttask {oper ind {inf 0} {typ 0} {c1 0} {sel 0} {tsec 0} {ipos 0} {iN 0}
    {started 0}} {

    set task [list $inf $typ $c1 $sel]
    set it [list [expr [clock seconds] + abs(int($tsec))] $ipos $iN]
    switch $oper {
        "add"   {
                set i [lsearch $::em::tasks $task]
                if {$i >= 0} {return [list $i 0]}  ;# already exists, no new adding
                lappend ::em::tasks $task
                lappend ::em::taski $it
                set started [start_timed [expr {[llength $::em::tasks] - 1}]]
                }
        "upd"   {
                set ::em::tasks [lreplace $::em::tasks $ind $ind $task]
                set ::em::taski [lreplace $::em::taski $ind $ind $it]
                }
        "del"   {
                set ::em::tasks [lreplace $::em::tasks $ind $ind]
                set ::em::taski [lreplace $::em::taski $ind $ind]
                }
    }
    return [list $ind $started]
}
                    #====== to start autorun lists
proc run_a_ah {sub} {
    if {[string first "a=" $sub] >= 0} {
        run_auto [string range $sub 2 end]
    } elseif {[string first "ah=" $sub] >= 0} {
        run_autohidden [string range $sub 3 end] }
}
                    #====== to start subtask(s)
proc start_sub {ind istart ipos sub typ c1 sel} {
    set ::em::ipos $ipos
    if {$ipos == 0 || $sub==""} {
        shell_run "Nobutt" $typ $c1 - "&" $sel  ;# this task is current menu item
        if {$ind == $istart} {return true}  ;# safeguard from double start
    } else {
        run_a_ah $sub
    }
    return false
}
                    #====== to get subtask info
proc get_subtask { linf ipos } {
    return [split [lindex $linf $ipos] ":"]
}
                    #====== to start timed task(s)
proc start_timed { {istart -1} } {
    set istarted 0
    for {set repeat 1} {$repeat} {} {
        set repeat 0
        set ind 0
        foreach tti $::em::taski { ;# values in sec
            lassign $tti isec ipos iN
            lassign [lindex $::em::tasks $ind] inf typ c1 sel
            if {$ipos==0} {
                incr iN
            }
            set ::em::TN $iN
            set csec [clock seconds]
            if {$csec >= $isec} {
                # check for subtask e.g. -45*60/-15*60:ah=2,3/.../0
                set inf [string trim $inf /]
                set linf [split $inf /]   ;# subtasks are devided with "/"
                set ll [llength $linf]    ;# ipos is position of current subtask
                lassign [get_subtask $linf $ipos] isec sub ;# current subtask
                if {[start_sub $ind $istart $ipos $sub $typ $c1 $sel]} {
                    set istarted 1
                }
                if {[incr ipos] >= $ll} {
                    set ipos 0
                    lassign [get_subtask $linf $ipos] isec sub ;# 1st subtask
                } else {  ;# process subtask
                    lassign [get_subtask $linf $ipos] isec sub ;# new subtask
                    if {[string first "TN=" $isec]==0} {
                        if {$iN >= [::getN [string range $isec 3 end]]} {
                            run_a_ah $sub
                            ttask "del" $ind  ;# end of task if TN of cycles
                            set repeat 1      ;# are completed
                            break
                        }
                        if {[incr ipos] >= $ll} {
                            set ipos 0
                            set isec "0"
                        } else {
                            lassign [get_subtask $linf $ipos] isec sub
                        }
                    } else {  ;# if interval>0, run now
                        if {$isec != "" && [string range $isec 0 0]!="-"} {
                            if {[start_sub $ind $istart $ipos $sub $typ $c1 $sel]} {
                                set istarted 1
                            }
                        }
                    }
                }
                # update the current task
                ttask "upd" $ind $inf $typ $c1 $sel $isec $ipos $iN
            }
            incr ind
        }
    }
    after [expr $::em::inttimer * 1000] ::em::start_timed
    return $istarted
}
                    #====== push/pop timed task
proc set_timed { from inf typ c1 inpsel} {
    set ::em::TN 1
    lassign [split $inf /] timer
    set timer [::getN $timer]
    if {$timer == 0} {return 1}  ;# run once
    if {$timer>0} {set startnow 1} {set startnow 0}
    lassign [ttask "add" -1 $inf $typ $c1 $inpsel $timer] ind started
    if {$from == "button" && $ind >= 0} {
        if {[question_box "Stop timed task" "Stop the task\n\n\
        [.frame.butt$::em::lasti cget -text] ?"]} {
            ttask "del" $ind
        }
        return false
    }
    return [expr !$started && $startnow]  ;# true if start now, repeat after
}
                    #====== to parse modes of run
proc s_assign {refsel {trl 1}} {
    upvar $refsel sel
    set retlist {}
    set tmp [string trimleft $sel]
    if {[string first "?" $tmp] == 0} {   ;#?...? sets modes of run
        set sel $tmp
        lassign { "" 0 } el qac
        for {set i 1}  {$i < [string len $sel]} {incr i} {
            if {[set c [string range $sel $i $i]]=="?" || $c==" "} {
                if {$c==" "} {
                    set sel [string range $sel [expr $i+1] end]
                    if {$trl} { set sel [string trimleft $sel] }
                    lappend retlist -1
                    break
                } else {
                    lappend retlist $el
                    lassign { "" 1 } el qac
                }
            } else {
                    set el "$el$c"
            }
        }
    }
    return $retlist
}
                    #====== to run a program of sel
proc run0 {sel amp silent} {
    if {![vip $sel]} {
        if {[string first "%q " $sel] == 0 ||
        [string first "%Q " $sel] == 0} {
            set sel "Q [string range $sel 3 end]"
            return [{*}$sel]
        } elseif {[string first "%D " $sel] == 0} {
            set sel "D [string range $sel 3 end]"
            if {[catch [{*}$sel] e]} {
                D $e
                return false
            }
        } elseif {[string first "%S " $sel] == 0} {
            set sel "S [string range $sel 3 end]"
            if {[catch [{*}$sel] e]} {
                D $e
                return false
            }
        } elseif {[string first "%b " $sel] == 0 ||
            [string first "%B " $sel] == 0} {
            set sel "::eh::browse [list [string range $sel 3 end]]"
            {*}$sel
        } else {
            set sel "$sel $amp"
            if { [catch {exec {*}$sel} e] } {
                if {$silent < 0} {
                    message_box "ERROR of running\n\n$sel\n\n$e"
                    return false
                }
            }
        }
    }
    return true
}
                    #====== to run a program of menu item
proc run1 {typ sel amp silent} {
    prepr_prog sel $typ  ;# prep
    prepr_idiotic sel 0
    return [run0 $sel $amp $silent]
}
                    #====== to call command in shell
proc shell1 {typ sel amp silent} {
    prepr_prog sel $typ  ;# prep
    prepr_idiotic sel 0
    if {[vip $sel]} {return true}
    if {[iswindows] || $amp!="&"} {focused_win false}
    set ret true
    if {[::iswindows]} {
        set composite "$::win_console $sel $amp"
        if { [catch { exec {*}[auto_execok start] \
          cmd.exe /c {*}"$composite" } e] } {
            if {$silent < 0} {
                message_box "ERROR of running\n\n$composite\n\n$e"
                set ret false
            }
        }
    } else {
        set lang "[lindex [split $::env(LANG) .] 0].utf8"  ;# = ru_RU.utf8
        set sel [escape_quotes $sel "\\\""]
        set composite "$::lin_console $sel $amp"
        if { [catch { exec xterm -fa "$lang" -fs $::em::tf \
          -geometry $::em::tg -bg white -fg black -title $sel \
          -e {*}$composite  } e] } {
            if {$silent < 0} {
                message_box "ERROR of running\n\n$sel\n\n$e"
                set ret false
            }
        }
    }
    if {[iswindows] || $amp!="&"} {focused_win true}
    return $ret
}
                    #====== to update item name (with inc)
proc update_itname {it inc {pr ""}} {
    if {$it > $::em::begsel} {
        set b .frame.butt$it
        if {[$b cget -image]==""} {
            if {$::em::ornament > 1} {
                set ornam [$b cget -text]
                set ornam [string range $ornam 0 [string first ":" $ornam]]
            } else {set ornam ""}
            set itname $::em::itnames($it)
            if {$pr !=""} { {*}$pr }
            prepr_09 itname ::em::arr_i09 "i" $inc  ;# incr N of runs
            prepr_idiotic itname 0
            $b configure -text $ornam$itname
        }
    }
}
                    #====== to update all buttons
proc update_buttons { {pr ""} } {
    for_buttons {
        update_itname $i 0 $pr
    }
}
                    #====== to update all buttons' names
proc update_buttons_pn {} {
    update_buttons "prepr_pn itname"
}
                    #====== to update all buttons' date/time
proc update_buttons_dt {} {
    update_buttons_pn
    repeate_update_buttons  ;# and re-run itself
}
                    #====== to update buttons with time/date
proc repeate_update_buttons {} {
    after [expr $::timeafter * 1000] ::em::update_buttons_dt
}
                    #====== to run/shell
proc shell_run { from typ c1 s1 amp {inpsel ""} } {
    set cpwd [pwd]
    set inc 1
    set doexit 0
    if {$inpsel == ""} {
        set inpsel [get_seltd $s1]
        lassign [silent_mode $amp] amp silent  ;# silent_mode - in 1st line
        lassign [s_assign inpsel] p1 p2
        if {$p1 != ""} {
            if {$p2==""} {
                set silent $p1
            } else {
                if {![set_timed $from $p1 $typ $c1 $inpsel]} {return}
                set silent $p2
            }
        }
    } else {
        if {$amp=="noamp"} {
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
        prepr_09 seltd ::em::arr_i09 "i"   ;# set N of runs in command
        if {![ $c1 $typ "$seltd" $amp $silent ] || $doexit > 0} {
            set inc 0  ;# unsuccessful run
            break
        }
    }
    if {$doexit > 0} {::em::on_exit}
    if {$inc} {                          ;# all buttons texts may need to update
        update_itname $::em::lasti $inc  ;# because all may include %s1, %s2...
    }
    update_buttons_pn
    update idletasks
    cd $cpwd
}
                    #====== to run commands before a submenu
proc before_callmenu {pars} {
    set cpwd [pwd]
    set menupos [string last "::em::callmenu" $pars]
    if {$menupos>0} {  ;# there are previous commands before callmenu
        set commands [string range $pars 0 $menupos-1]
        foreach com [split $commands \r] {
            set com [lindex [split $com \n] 0]
            if {$com!=""} {
                if {![run0 $com "" 0]} {
                    set pars ""
                    break
                }
            }
        }
        set pars [string range $pars [string last \r $pars]+1 end]
    }
    cd $cpwd
    return $pars
}
                    #====== to call a submenu
proc callmenu { typ s1 {amp ""} {from ""}} {
    set pars [get_seltd $s1]
    set pars [before_callmenu $pars]
    if {$pars==""} return
    set pars "$::em::inherited a= a1= a2= ah= n= $pars"
    set pars [string map [list "b=%b" "b=$::eh::my_browser"] $pars]
    set pars "ch=1 g=+[expr 10+[winfo x .]]+[expr 15+[winfo y .]] $pars"
    prepr_1 pars "cb" [::em::get_callback]      ;# %cb is callback of caller
    prepr_1 pars "in" [string range $s1 1 end]  ;# %in is menu's index
    set sel "wish $::argv0"
    prepr_win sel "M/"  ;# force converting
    if {[iswindows] || $amp!="&"} {focused_win false}
    if { [catch {exec {*}$sel {*}$pars $amp} e] } { }
    if {[iswindows] || $amp!="&"} {focused_win true}
}
                    #====== to run "seltd" as a command
proc run { typ s1 {amp ""} {from ""} } {
    shell_run $from $typ run1 $s1 $amp
}
                    #====== to shell "seltd" as a command
proc shell { typ s1 {amp ""} {from ""} } {
    shell_run $from $typ shell1 $s1 $amp
}
                    #====== to run by button pressing
proc callmenu_button { typ s1 {amp ""} } {
    callmenu $typ $s1 $amp "button"
}
proc run_button { typ s1 {amp ""} } {
    run $typ $s1 $amp "button"
}
proc shell_button { typ s1 {amp ""} } {
    shell $typ $s1 $amp "button"
}
                    #====== to browse a help page
proc browse_button { s1 } {
    set help [lindex [get_seltd $s1] 0]  ;# 1st word is the page name
    ::eh::browse [eh::html $help $::offline]
    ::em::on_exit
}
                    #====== to run a command after keypressing
proc pr_button {ib args} {
    set comm "$args"
    if {[set i [string first " " $comm]] > 2} {
        set comm "[string range $comm 0 [expr $i-1]]_button
            [string range $comm $i end]" }
    {*}$comm
    highlight_button $ib
    focus_button $ib
}
                    #====== to get array index of i-th menu item
proc get_s1 {i hidden} {
    if {$hidden} {return "h$i"} {return "m$i"}
}
                    #====== to prepare a callback of caller
proc get_callback {} {
    set cb $::argv0
    foreach a $::argv {
        append cb " $a"
    }
    return $cb
}
                    #====== to run i-th menu item
proc run_it {i {hidden 0}} {
    if {$hidden} {
        lassign [lindex $::em::commhidden $i] name torun hot typ
    } else {
        lassign [lindex $::em::commands $i] name torun hot typ}
    {*}$torun
}
                    #====== Mr. Preprocessor of s0-9, u0-9
proc prepr_09 {refn refa t {inc 0}} {
    upvar $refn name
    upvar $refa arr
    for {set i 0} {$i<=9} {incr i} {
        set p "$t$i"
        set s "$p="
        if {[string first $p $name] != -1} {
            if {![catch {set sel $arr($s)} e]} {
                if {$t=="i"} {
                    incr sel $inc     ;# increment i1-i9 counters of runs
                    set ${refa}($s) $sel
                }
                prepr_1 name $p $sel
            }
        }
    }
}
                    #====== Mr. Preprocessor of %-wildcards
proc prepr_1 {refpn s ss} {
    upvar $refpn pn
    set pn [string map [list "%$s" $ss] $pn]
}
                    #====== Mr. Preprocessor of dates
proc prepr_dt {refpn} {
    upvar $refpn pn
    set oldpn $pn
    lassign [::get_timedate] curtime curdate curdt curdw systime
    prepr_1 pn "t0" $curtime               ;# %t0 time
    prepr_1 pn "t1" $curdate               ;# %t1 date
    prepr_1 pn "t2" $curdt                 ;# %t2 date & time
    prepr_1 pn "t3" $curdw                 ;# %t3 week day
    foreach tw [array names ::em::arr_tformat] {
        set time [clock format $systime -format $::em::arr_tformat($tw)]
        prepr_1 pn "$tw" $time
    }
    return [expr {$oldpn != $pn} ? 1 : 0]   ;# to update time in menu
}
                    #====== Mr. Preprocessor idiotic
proc prepr_idiotic {refpn start } {
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
                    #====== Mr. Preprocessor initial
proc prepr_init {refpn} {
    upvar $refpn pn
    prepr_idiotic pn 1
    prepr_09 pn ::em::arr_s09 "s"  ;# s1-s9 params
    prepr_09 pn ::em::arr_u09 "u"  ;# u1-u9 params underscored
    set delegator {}
    for {set i 1} {$i<=19} {incr i} {
        if {$i <= 9} {set d "s$i="} {set d "u[expr $i-10]="}
        lappend delegator $d
    }
    foreach d $delegator {             ;# delegating values:
        set i [string range $d 0 0]    ;# s0 -> s9 -> u0 -> u9
        catch {
            if {$i=="s"} {
                set el $::em::arr_s09($d)
                prepr_09 el ::em::arr_s09 s
                prepr_09 el ::em::arr_u09 u
                set ::em::arr_s09($d) $el
            } else {
                set el $::em::arr_u09($d)
                prepr_09 el ::em::arr_s09 s
                prepr_09 el ::em::arr_u09 u
                set ::em::arr_u09($d) [string map [list " " "_"] $el]
            }
        }
    }
    prepr_1 pn "+"  $::em::pseltd ;# %+  is %s with " " as "+"
    prepr_1 pn "qq" $::em::qseltd ;# %qq is %s with quotes escaped
    prepr_1 pn "dd" $::em::dseltd ;# %dd is %s with specs deleted
}
                    #====== Mr. Preprocessor of 'prog'/'name'
proc prepr_pn {refpn {dt 0}} {
    upvar $refpn pn
    prepr_idiotic pn 1
    foreach gw [array names ::em::arr_geany] {  ;# Geany's wildcards
        prepr_1 pn $gw $::em::arr_geany($gw)
    }
    prepr_1 pn "PD" $::em::workdir  ;# %PD is passed dir (PD=...)
    prepr_1 pn "PN" $::em::prjname  ;# %PN is passed dir's tail
    prepr_1 pn "N" $::em::appN      ;# ID of menu application
    prepr_1 pn "m" $::menudir       ;# %m is e_menu.tcl dir
    prepr_1 pn "s" $::em::seltd     ;# %s is a selected text
    prepr_1 pn "u" $::em::useltd    ;# %u is %s underscored
    set pndt [prepr_dt pn]
    if {$dt} { return $pndt } { return $pn }
}
                    #====== to convert all Windows' "\" to Unix' "/"
proc prepr_win {refprog typ} {
    upvar $refprog prog
    if {[string last "/" $typ] > 0} {
        set prog [string map {"\\" "/"} $prog]
    }
}
                    #====== Mr. Preprocessor of 'prog'
proc prepr_prog {refprog typ} {
    upvar $refprog prog
    prepr_pn prog
    prepr_win prog $typ
}
                    #====== Mr. Preprocessor of 'name'
proc prepr_name {refname {aft 0}} {
    upvar $refname name
    return [prepr_pn name $aft]
}
                    #====== Mr. Preprocessor of 'call'
proc prepr_call {refname} { ;# this must be done for e_menu call line only
    upvar $refname name
    if {$::em::percent2 != ""} {
        set name [string map [list $::em::percent2 "%"] $name]
    }
   prepr_1 name "PD" $::em::workdir
   prepr_1 name "PN" $::em::prjname
   prepr_1 name "N" $::em::appN
}
                    #====== to get menu item
proc menuit {line lt left {a 0}} {
    set i [string first $lt $line]
    if {$i < 0} {return ""}
    if {$left} {
        return [string range $line 0 [expr $i+($a)]]
    } else {
        return [string range $line [expr $i+[string length $lt]] end]
    }
}
                    #====== to create file.mnu template
proc create_template {fname} {
    if { ![catch {set chan [open "$fname" "w"]} e] } {
        set dir [file dirname $fname]
        if {[file tail $dir] == $::em::prjname} {
            set menu "$::em::prjname/nam3.mnu"
        } else {
            set menu [file join $dir "nam3.mnu"]
        }
        puts $chan "R: nam1 R: prog\n\nS: nam2 S: comm\n\nM: nam3 M: m=$menu"
        close $chan
    }
}
                    #====== to read menu file
proc menuof { commands s1 domenu} {
    upvar $commands comms
    set seltd [get_seltd $s1]
    if {$domenu} {
        set ::em::menuttl \
            "[string map {"\\" "/"} [file tail $seltd]] - E_menu"
        if {![file exists "$seltd"]} {
            set seltd [file join $::menudir "$seltd"]
        }
        set seltd [file normalize $seltd]
        if { [catch {set chan [open "$seltd"]} e] } {
            if {$::em::editor == ""} {set e "Geany IDE"} {set e $::em::editor}
            if {[question_box "Menu isn't open" \
            "ERROR of opening\n$seltd\n\nCreate it in $e?"]} {
                ::em::create_template $seltd
                ::em::edit $seltd
            }
            set ::em::start0 0  ;# no more messages
            return
        }
        set ::em::menufilename "$seltd"
        set ::em::menufile {0}
    }
    set prname "?"
    set iline $::em::begsel
    set doafter false
    set lappend "lappend comms"
    set ::em::commhidden {0}
    set hidden 0
    set options 0
    set ilmenu 0
    set separ ""
    while {1} {
        if {$domenu} {
            if {[gets $chan line] < 0} {break}
            lappend ::em::menufile $line
        } else {
            incr ilmenu
            if {$ilmenu >= [llength $::em::menufile]} {break}
            set line [lindex $::em::menufile $ilmenu]
        }
        set line [string trimleft $line]
        if {$line == "\[OPTIONS\]"} {
            set options 1
            set hidden 0
            continue
        }
        if {$line == "\[HIDDEN\]"} {
            set hidden 1
            set options 0
            set lappend "lappend ::em::commhidden"}
        if {$options} {
            lappend ::em::menuoptions $line
            continue
        }
        set typ [menuit $line ":" 1]
        if {[set l [string length $typ]] < 1 || $l > 3} {
            set typ [menuit $line "/" 1]
        }
        if {[set l [string length $typ]] < 1 || $l > 3} {
            set prname "?"
            continue}
        set line [menuit $line $typ 0]
        set name [menuit $line $typ 1 -1]
        set prog [string trimleft [menuit $line $typ 0]]
        set origprog $prog
        prepr_init name
        prepr_init prog
        prepr_win prog $typ
        switch $typ {
            "I:" {   ;#internal (D, Q, S, Tcl commands)
                    prepr_pn prog
                    set prom "RUN         "
                    set runp "$prog" }
            "R/" -
            "R:"  { set prom "RUN         "
                    set runp "::em::run $typ";   set amp "&$::em::mute" }
            "RE/" -
            "RE:"  { set prom "EXEC        "
                    set runp "::em::run $typ";   set amp "&$::em::mute ; ::em::on_exit" }
            "RW/" -
            "RW:" { set prom "RUN & WAIT  "
                    set runp "::em::run $typ";   set amp "$::em::mute" }
            "S/" -
            "S:"  { set prom "SHELL       "
                    set runp "::em::shell $typ"; set amp "&$::em::mute" }
            "SE/" -
            "SE:"  { set prom "SHELL       "
                    set runp "::em::shell $typ"; set amp "&$::em::mute ; ::em::on_exit" }
            "SW/" -
            "SW:" { set prom "SHELL & WAIT"
                    set runp "::em::shell $typ"; set amp "$::em::mute" }
            "M/" -
            "M:"  { set prom "MENU        "
                    set runp "::em::callmenu $typ"; set amp "&" }
            "MW/" -
            "MW:" { set prom "MENU & WAIT "
                    set runp "::em::callmenu $typ"; set amp "" }
            "ME/" -
            "ME:" { set prom "MENU & EXIT "
                    set runp "::em::callmenu $typ"; set amp "& ; ::em::on_exit" }
            default {
                set prname "?"
                continue}
        }
        set hot ""
        for {set fn 1} {$fn <= 12} {incr fn} {  ;# look up to F1-F12 hotkeys
            set s "F$fn "
            if {[set p [string first $s $name]] >= 0 &&
            [string trim [set s2 [string range $name 0 [incr $p -1]]]] == ""} {
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
            if {[string trim $name "- "] == ""} {      ;# is a separator?
                if {[string trim $name] == ""} {
                    set separ "?[string trim $prog]?"  ;# yes, blank one
                } else {                               ;# ... or underlining
                    set separ "?[expr -[::getN [string trim $prog]]]?"
                }
                continue
            }
            if {$separ != ""} {
                set name "$separ $name"  ;# insert separator into name
                set separ ""
            }
            set s1 [get_s1 [incr iline] $hidden]
            if {$typ=="I:"} { set torun "$runp"  ;# internal command
                } else {      set torun "$runp $s1 $amp" }
            if {$iline > $::maxitems} {
                message_box "Too much menu items in:\n\n$seltd
                \n[expr $iline-1] is maximum."
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
                {*}$lappend [list "$name" $torun $hot $typ]}
        }
        if {[string first $::em::extraspaces $prom]<0} {set ::em::extras false}
        set ::em::pars($s1) $prog
        set prprog $prog
    }
    if {$doafter} { ;# after N sec: check times/dates
        ::em::repeate_update_buttons
    }
    if {$domenu} {close $chan}
}
                    #====== to prepare buttons' contents
proc prepare_buttons {refcommands} {
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
        if {$::em::itviewed < 5} {set ::em::itviewed $::viewed}
    }
    set tip " Press Ctrl+E to edit the menu\n Press Ctrl+R to re-read\n\
        Press Ctrl+D to clear off"
    set ::em::font1 "\"[string trim $::font1 \"]\" $::fs"
    set ::em::font2 "\"[string trim $::font2 \"]\" $::fs"
    checkbutton .cb -text "On top" -variable ::em::ontop -fg $::colrhot \
        -bg $::colr1 -takefocus 0 -command {::em::staytop_toggle}
    grid [label .h0 -text [string repeat " " [expr $::em::itviewed -3]] \
        -bg $::colr1] -row 0 -column 0 -sticky nsew
    tooltip::tooltip .h0 $tip
    grid .cb -row 0 -column 1 -sticky ne
    check_real_call  ;# the above grid is 'hidden'
    text .frame -bg $::colr2 -fg $::colr2 -state disabled -takefocus 0 -cursor arrow
    if {[isheader]} {
        grid [label .h1 -text "Use arrow and space keys to take action" \
            -font $::em::font1 -fg $::colr -bg $::colr1 -anchor s] -columnspan 2 -sticky nsew
        grid [label .h2 -text "(or press hotkeys)\n" -font $::em::font1 \
            -fg $::colrhot -bg $::colr1 -anchor n] -columnspan 2 -sticky nsew
    }
    tooltip::tooltip .cb "Press Ctrl+T to toggle"
    if {[isheader]} {
        tooltip::tooltip .h1 $tip
        tooltip::tooltip .h2 $tip
    }
    tooltip::tooltip delay 1000
    if {[isheader]} {set hlist {.h0 .h1 .h2}} {set hlist {.h0}}
    foreach l $hlist {
        bind $l <ButtonPress-1>   { ::em::mouse_drag 1 %x %y }
        bind $l <Motion>          { ::em::mouse_drag 2 %x %y }
        bind $l <ButtonRelease-1> { ::em::mouse_drag 3 %x %y }
    }
    #~ catch {
        #~ foreach w [list {*}$hlist .frame] {
            #~ tkdnd::drop_target register $w *
            #~ bind $w <<Drop:DND_Files>> { ::em::dropping %D %A }
            #~ bind $w <<Drop:DND_Text>> { ::em::dropping %D %A }
        #~ }
    #~ }
}
                    #~ #====== to process dropping file(s) / url(s)
#~ proc dropping {flist retv} {
    #~ foreach f $flist {
        #~ if {[catch {exec wish e_entry.tcl $f $::fs} e]} {
            #~ d $e
        #~ }
    #~ }
    #~ focus -force .
    #~ focus_button $::em::lasti
    #~ return $retv
#~ }
                    #====== to toggle 'stay on top' mode
proc staytop_toggle {} {
    if {$::em::ncmd > [expr $::em::begsel+1]} {
        set ::em::begin [expr {$::em::begin == 1} ? ($::em::begsel+1) : 1]
        set ::em::start0 1
        reread_menu
        set ::em::start0 0
    }
    wm attributes . -topmost $::em::ontop
}
                    #====== to shadow 'w' widget
proc shadow_win {w} {
    if {![catch {set ::em::bgcolr($w) [$w cget -bg]} e]} {
        $w configure -bg $::colrgrey}
}
                    #====== to focus in/out
proc focused_win {focused} {
    if {$::em::skipfocused} {
        set ::em::skipfocused 0
        return
    }
    if {$focused} {
        foreach wc [array names ::em::bgcolr] {
            if {[winfo exists $wc]} {
                if {[string first ".frame.butt" $wc] < 0} {
                    catch { $wc configure -bg $::em::bgcolr($wc) }
                }
            }
            highlight_button $::em::lasti
            . configure -bg $::colr1
            ::tooltip::tooltip on
        }
    } else {
        foreach w [winfo children .] {
            shadow_win $w
            foreach wc [winfo children $w] {
                shadow_win $wc
            }
        }
        . configure -bg $::colrgrey
        ::tooltip::tooltip off
        lassign {0 0} ::em::mx ::em::my
    }
    update
}
                    #====== to try and check if 'app' destroyed
proc destroyed {app} {
    return [expr ![catch {send -async $app {destroy .}} e]]
}
                    #====== to destroy all e_menu apps
proc destroy_emenus {} {
    if {![question_box "Clearance - $::appname" "\nDestroy all\ne_menu applications?\n"]} {
        return }
    for {set i 0} {$i < 3} {incr i} {
        for {set nap 1} {$nap <= 64} {incr nap} {
            set app ${::thisapp}$nap
            if {$nap != $::em::appN} { destroyed $app }
        }
    }
    if {$::em::ischild || $::em::geometry == ""} {
        destroy .  ;# do not kill self if am a parent app with geometry passed
    }
}
                    #====== to off ctrl/alt modificators of keystrokes
proc ctrl_alt_off {cmd} {
    if {[iswindows]} {
        return "if \{%s == 8\} \{$cmd\}"
    } else {
        return "if \{\[expr %s&14\] == 0\} \{$cmd\}"
    }
}
                    #====== to drag window by snatching header
proc mouse_drag {mode x y} {
    switch $mode {
      1 { lassign [list $x $y] ::em::mx ::em::my }
      2 -
      3 { if {$::em::mx>0 && $::em::my>0} {
            lassign [split [wm geometry .] x+] w h wx wy
            wm geometry . +[expr $wx+$x-$::em::mx]+[expr $wy+$y-$::em::my]
            if {$mode==3} {lassign {0 0} ::em::mx ::em::my } }
        }
    }
}
                    #====== to check the call string of e_menu
proc check_real_call {} {
    if {$::em::ncmd < 2} {
        if {$::em::start0} {
::message_box "Run this with\n\nwish e_menu.tcl \"s=%s\" \[m=menu\]\n
as a context command\n(see readme.md for details)." }
        exit
    }
}
                    #====== to prepare wildcards processing in menu items
proc prepare_wilds {per2} {
    if {[llength [array names ::em::arr_geany d]] != 1} { ;# it's obsolete
        set ::em::arr_geany(d) $::em::workdir             ;# (using %d as %PD)
    }
    if {$per2} { set ::em::percent2 "%" }    ;# reset the wild percent to %
    prepr_pn ::em::useltd
    prepr_pn ::em::pseltd
    prepr_pn ::em::qseltd
    prepr_pn ::em::dseltd
    set ::em::useltd [string map {" " "_"} $::em::useltd]
    set ::em::pseltd [escape_links $::em::pseltd]
    set ::em::qseltd [escape_quotes $::em::qseltd "\\\""]
    set ::em::dseltd [delete_specsyms $::em::dseltd]
}
                    #====== to get pars
proc get_pars1 {s1 argc argv} {
    set ::em::pars($s1) ""
    for {set i 0} {$i < $argc} {incr i} {
        set s2 [string range [lindex $argv $i] 0 \
            [set l [expr [string len $s1]-1]]]
        if {$s1 == $s2} {
            set seltd [string range [lindex $argv $i] [expr $l+1] end]
            prepr_call seltd
            set ::em::pars($s1) $seltd
        }
    }
}
                    #====== to initialize ::em::commands from argv and menu
proc initcommands { lmc amc osm {domenu 0} } {
    set resetpercent2 0
    foreach s1 { a0= P= N= PD= PN= o= s= \
    u= w= qq= dd= pa= ah= wi= += bd= b1= b2= b3= b4= \
    f1= f2= fs= ch= a1= a2= ed= tf= tg= \
    t0= t1= t2= t3= t4= t5= t6= t7= t8= t9= \
    s0= s1= s2= s3= s4= s5= s6= s7= s8= s9= \
    u0= u1= u2= u3= u4= u5= u6= u7= u8= u9= \
    i0= i1= i2= i3= i4= i5= i6= i7= i8= i9= \
    x0= x1= x2= x3= x4= x5= x6= x7= x8= x9= \
    y0= y1= y2= y3= y4= y5= y6= y7= y8= y9= \
    z0= z1= z2= z3= z4= z5= z6= z7= z8= z9= \
    a= d= e= f= p= l= h= b= c= t= g= n= m= om= \
    cb= in=} { ;# the processing order is important
        if {[string first $s1 "o= s= m="]>=0 && [string first $s1 $osm]<0} {
            continue
        }
        get_pars1 $s1 $lmc $amc
        if {[string length $::em::pars($s1)] > 0} {
            set seltd [lindex [array get ::em::pars $s1] 1]
            if {[string first $s1 "m= g= cb= in="] < 0} {
                set ::em::inherited "$::em::inherited \"$s1$seltd\""
            }
            switch $s1 {
                P= { if {$seltd !=""} {
                        set ::em::percent2 $seltd  ;# set % substitution
                    } else {
                        set resetpercent2 1}   ;# must be reset to % after cycle
                   }
                N= { set ::em::appN [::getN $seltd 1]}
                PD= { set ::em::workdir $seltd;
                     prepr_win ::em::workdir "M/"  ;# force converting
                     if {!$::em::prjset} {
                        set ::em::prjname [file tail $::em::workdir] }
                     catch {cd $::em::workdir}
                    }
                PN= { set ::em::prjname $seltd
                      set ::em::prjset 2 }
                s= {if {[isheader]} {
                        lappend ::em::commands [list " HELP        \"$seltd\"" \
                        "::em::browse $s1"]
                        if {[iswindows]} {
                            prepr_win seltd "M/"
                            set ::em::pars($s1) $seltd
                        }
                        lappend ::em::commands [list " EXEC        \"$seltd\"" \
                        "::em::run RE: $s1 & ; ::em::on_exit"]
                        lappend ::em::commands [list " SHELL       \"$seltd\"" \
                        "::em::shell RE: $s1 & ; ::em::on_exit"]
                        set ::em::hotkeys "000$::em::hotsall"
                    }
                    set ::em::seltd [set ::em::useltd [set ::em::pseltd [
                        set ::em::qseltd [set ::em::dseltd $seltd]]]]
                    set ::em::begsel [expr [llength $::em::commands] - 1]
                   }
                h= {set ::eh::hroot $seltd
                    set ::offline true
                   }
                m= {prepare_wilds $resetpercent2
                    ::em::menuof ::em::commands $s1 $domenu }
                b= {set ::eh::my_browser $seltd}
                c= {set ::ncolor [::getN $seltd]}
                o= {set ::em::ornament [::getN $seltd]}
                g= {set ::em::geometry $seltd }
                u= {  ;# u=... overrides previous setting (in s=)
                    set ::em::useltd [string map {" " "_"} $seltd]
                   }
                t= {set ::em::dotop [::getN $seltd]}
                s0= - s1= - s2= - s3= - s4= - s5= - s6= - s7= - s8= - s9=
                   { set ::em::arr_s09($s1) $seltd }
                u0= - u1= - u2= - u3= - u4= - u5= - u6= - u7= - u8= - u9=
                   { set ::em::arr_u09($s1) [string map {" " "_"} $seltd] }
                i0= - i1= - i2= - i3= - i4= - i5= - i6= - i7= - i8= - i9=
                   { set ::em::arr_i09($s1) [::getN $seltd] }
                w= { set ::em::itviewed [::getN $seltd]}
                a= { set ::em::autorun $seltd}
                f= - l= - p= - e= -
                d= { ;# d=, e=, f=, l=, p= are used as Geany wildcards
                    set ::em::arr_geany([string range $s1 0 0]) $seltd}
                n= { set ::em::menuttl $seltd }
                wi= { set ::em::widthi [::getN $seltd $::em::widthi]
                      if {$::em::widthi > $::em::itviewed} {
                          set ::em::widthi [expr $::em::itviewed - 1]} }
                ah= { set ::em::autohidden $seltd}
                a0= { if {$::em::start0} { run_tcl_commands seltd } }
                a1= { set ::em::commandA1 $seltd}
                a2= { set ::em::commandA2 $seltd}
                ch= { set ::em::ischild 1 }
                t0= { set ::eh::formtime $seltd }
                t1= { set ::eh::formdate $seltd }
                t2= { set ::eh::formdt   $seltd }
                t3= { set ::eh::formdw   $seltd }
                t4= - t5= - t6= - t7= - t8= -
                t9= { set ::em::arr_tformat([string range $s1 0 1]) $seltd}
                fs= { set ::fs [::getN $seltd $::fs]}
                f1= { set ::font1 $seltd}
                f2= { set ::font2 $seltd}
                qq= { set ::em::qseltd [escape_quotes $seltd "\\\""] }
                dd= { set ::em::dseltd [delete_specsyms $seltd] }
                +=  { set ::em::pseltd [escape_links $seltd] }
                pa= { set ::em::pause [::getN $seltd ::em::pause] }
                wc= { set ::em::wc [::getN $seltd ::em::wc] }
                bd= { set ::em::bd [::getN $seltd $::em::bd]}
                b1= { set ::em::b1 [::getN $seltd $::em::b1]}
                b2= { set ::em::b2 [::getN $seltd $::em::b2]}
                b3= { set ::em::b3 [::getN $seltd $::em::b3]}
                b4= { set ::em::b4 [::getN $seltd $::em::b4]}
                ed= { set ::em::editor $seltd}
                tg= { set ::em::tg $seltd}
                tf= { set ::em::tf [::getN $seltd $::em::tf]}
                om= { set ::em::om $seltd}
                cb= { set ::em::cb $seltd}
                in= { set ::em::lasti $seltd}
                default {
                    if {[set s [string range $s1 0 0]] == "x" ||
                    $s == "y" || $s == "z"} {  ;# x* y* z* general substitutions
                        set ::em::arr_geany([string map {"=" ""} $s1]) $seltd
                    }
                }
            }
        }
    }
    prepare_wilds $resetpercent2
    set ::em::ncmd [llength $::em::commands]
}
                    #====== to prepend initialization
proc initcommhead {} {
    set ::em::begsel 0
    set ::em::hotkeys $::em::hotsall
    set ::em::inherited ""
    set ::em::commands {0}
}
                    #====== to initialize commands
proc initcomm {} {
    initcommhead
    set ::em::menuoptions {0}
    initcommands $::argc $::argv "o= s= m=" 1
    if {[set lmc [llength $::em::menuoptions]] > 1} {
        # o=, s=, m= options define menu contents & are processed particularly
        initcommands $lmc $::em::menuoptions "o="
        initcommhead
        if {$::em::om} {
            initcommands $::argc $::argv "s= m="
            initcommands $lmc $::em::menuoptions "o="
        } else {
            initcommands $lmc $::em::menuoptions " "
            initcommands $::argc $::argv "o= s= m="
        }
    }
}
                    #====== to initialize main properties
proc initmain {} {
    if {$::em::pause > 0} { after $::em::pause }  ;# pause before main inits
    if {$::em::appN > 0} {
        set ::appname ${::thisapp}$::em::appN     ;# set N of application
    } else {                                      ;# otherwise try to find it
        for {set ::em::appN 1} {$::em::appN < 64} {incr ::em::appN} {
            set ::appname ${::thisapp}$::em::appN
            if {[catch {send -async $::appname {update idletasks}} e]} {
                break
            }
        }
    }
    tk appname $::appname
    set ::lin_console [file join $::menudir "$::lin_console"]
    set ::win_console [file join $::menudir "$::win_console"]
    set ::img [image create photo  \
        -file [file join $::menudir "src" "rarrow.png"]]
    for {set i 0} {$i <=9} {incr i} {set ::em::arr_i09(i$i=) 1 }
    lassign [lindex $::colorschemes $::ncolor] \
        ::colr ::colr0 ::colr1 ::colr2 ::colr2h ::colr3 ::colr4 ::colrhot ::colrgrey
    . configure -bg $::colr1
}
                    #====== to make e_menu's menu
proc initmenu {} {
    prepare_buttons ::em::commands
    for_buttons {
        set hotkey [string range $::em::hotkeys $i $i]
        set comm [lindex $::em::commands $i]
        set prbutton "::em::pr_button $i [lindex $comm 1]"
        set prkeybutton [ctrl_alt_off $prbutton]  ;# for hotkeys without ctrl/alt
        set comtitle [string map {"\n" " "} [lindex $comm 0]]
        if {$i > $::em::begsel} {
            if {$i < 10} { bind . <KP_$hotkey> "$prkeybutton" }
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
        prepr_09 comtitle ::em::arr_i09 "i"
        prepr_idiotic comtitle 0
        lassign [s_assign comtitle 0] p1 p2
        if {$p2!=""} {
            set pady [::getN $p1 0]
            set ::em::itnames($i) $comtitle
            if {$pady < 0} {
                grid [ttk::separator .frame.lu$i -orient horizontal] \
                    -pady [expr -$pady-1] -sticky we \
                    -column 0 -columnspan 2 -row [expr $i+$::em::isep]
            } else {
                grid [label .frame.lu$i -font "Sans 1" -fg $::colr2 \
                    -bg $::colr2] -pady $pady \
                    -column 0 -columnspan 2 -row [expr $i+$::em::isep]
            }
            incr ::em::isep
        }
        if {[string first "M" [lindex $comm 3]] == 0} { ;# is menu?
            set img "-image $::img -compound right"     ;# yes, show arrow
            set comtitle [string range \
                $comtitle[string repeat " " 300] 0 [expr $::em::widthi-2]]
        } else {set img ""}
        button $b -text "$comtitle" -pady $::em::b1 -padx $::em::b2 -anchor w \
            -font $::em::font2 -width $::em::itviewed -bd $::em::bd  {*}$img \
            -relief raised -overrelief raised -bg $::colr2 -command "$prbutton" \
            -cursor arrow
        $b configure -fg [color_button $i]
        if {$img == "" && [string len $comtitle] >
        [expr $::em::itviewed * $::em::ratiomin]} {
            tooltip::tooltip $b "$comtitle" }
        grid [label .frame.l$i -text $hotkey -font "$::em::font1 bold" -bg \
            $::colr2 -fg $::colrhot] -column 0 -row [expr $i+$::em::isep] -sticky ew
        grid $b -column 1 -row  [expr $i+$::em::isep] -sticky ew \
            -pady $::em::b3 -padx $::em::b4
        bind $b <Enter>           "::em::focus_button $i"
        bind $b <Down>            "::em::focus_button [expr $i+1]"
        bind $b <Tab>             "::em::focus_button [expr $i+1]"
        bind $b <Up>              "::em::focus_button [expr $i-1]"
        bind $b <Home>            "::em::focus_button 99"
        bind $b <End>             "::em::focus_button 0"
        bind $b <Prior>           "::em::focus_button 99"
        bind $b <Next>            "::em::focus_button 0"
        bind $b <Return>          "$prbutton"
        bind $b <KP_Enter>        "$prbutton"
        if {$img!=""} { bind $b <Right> "$prkeybutton" }
        if {[iswindows]} {
            bind $b <Shift-Tab> "::em::focus_button [expr $i-1]"
        } else {
            bind $b <ISO_Left_Tab> "::em::focus_button [expr $i-1]"
        }
    }
    grid .frame -columnspan 2 -sticky ew
    grid columnconfigure . 0 -weight 1
    grid rowconfigure    . 0 -weight 0
    grid rowconfigure    . 1 -weight 1
    grid rowconfigure    . 2 -weight 1
    grid columnconfigure .frame 1 -weight 1
    option add *Menu.tearOff 0
    menu .popupMenu
    .popupMenu add command -accelerator Ctrl+T -label "Toggle \"On top\"" \
        -command {.cb invoke}
    .popupMenu add separator
    .popupMenu add command -accelerator Ctrl+E -label "Edit the menu" \
        -command ::em::edit_menu
    .popupMenu add command -accelerator Ctrl+R -label "Reread the menu" \
        -command ::em::reread_init
    .popupMenu add command -accelerator Ctrl+D -label "Destroy other menus" \
        -command ::em::destroy_emenus
    .popupMenu add command -label "Show the menu's geometry" \
        -command ::em::show_menu_geometry
    .popupMenu add separator
    .popupMenu add command -accelerator Ctrl+> -label "Increase the menu's width" \
        -command {::em::win_width 1}
    .popupMenu add command -accelerator Ctrl+< -label "Decrease the menu's width" \
        -command  {::em::win_width -1}
    .popupMenu add separator
    .popupMenu add command -accelerator F1 -label "Help" -command ::em::help
    bind . <Control-t> {.cb invoke}
    bind . <Control-e> {::em::edit_menu}
    bind . <Control-r> {::em::reread_init}
    bind . <Control-d> {::em::destroy_emenus}

    update
    set isgeom [string len $::em::geometry]
    wm title . "${::em::menuttl}"
    if {$::em::start0} {
        if {![iswindows] || !$isgeom} {
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
        if {[iswindows] && $isgeom} {
            wm geometry . $::em::geometry
        } elseif {$::em::wc || [iswindows]} { ;# this can be omitted in Linux
            center_window . 0 }               ;# as 'wish' is centered in it
    }
}
                    #====== to edit current menu
proc edit_menu {} {
    if {[::em::edit $::em::menufilename]} {
        if {$::em::ischild} {
            ::em::on_exit
        } else {
            ::em::focus_button $::em::lasti
        }
    }
}
                    #====== to help
proc help {} {
    ::eh::browse "http://aplsimple.ucoz.ru/e_menu/e_menu.html"
}
                    #====== to show the menu's geometry
proc show_menu_geometry {} {
    D "\nWxH+X+Y = [wm geometry .]"
}
                    #====== to exit (end of e_menu)
proc on_exit {} {
    if {$::em::cb!=""} {
        # callback the menu (i.e. the caller)
        if { [catch {exec tclsh {*}$::em::cb "&"} e] } { d $e }
    }
    exit
}
                    #====== to run Tcl commands passed in a1=, a2=
proc run_tcl_commands {icomm} {
    upvar $icomm comm
    if {[string length $] > 0} {
        prepr_call comm
        set c [subst {$comm}]
        set c "[subst $c]"
        set c [subst {$c}]
        {*}$c
    }
    set comm ""
}
                    #====== to run auto list a=
proc run_auto {alist} {
    foreach task [split $alist ","] {
        for_buttons {
            if {$task == [string range $::em::hotkeys $i $i]} {
                $b configure -fg $::colrhot
                run_it $i
            }
        }
    }
}
                    #====== to run auto list ah=
proc run_autohidden {alist} {
    foreach task [split $alist ","] {   ;# task=1 (2,...,a,b...)
        set taskpos [string first $task $::em::hotsall]  ;# hotsall="012..ab..."
        set i $taskpos
        foreach hiddenitem $::em::commhidden {
            if {[incr taskpos -1] == 0} {
                run_it $i true
            }
        }
    }
}
                    #====== to show the menu window
proc show_menu {} {
    if {$::em::ischild} {
        bind . <Left> [ctrl_alt_off "::em::on_exit"]
        after 100 {focus -force . ; ::em::focus_button $::em::lasti}
    }
    if {$::em::lasti < $::em::begin} { set ::em::lasti $::em::begin }
    ::em::focus_button $::em::lasti
}
                    #====== to run tasks assigned in a= (by their hotkeys)
proc initauto {} {
    run_tcl_commands ::em::commandA1    ;# exec the command as first init
    run_auto $::em::autorun
    run_autohidden $::em::autohidden
    run_tcl_commands ::em::commandA2    ;# exec the command as last init
    show_menu
}
                    #====== to begin inits
proc initbegin {} {
    if {[iswindows]} {         ;# maybe nice to hide all windows manipulations
        wm attributes . -alpha 0.0
    } else {
        wm iconify .
    }
    update idletasks
    encoding system "utf-8"
    bind . <F1> {::em::help}
    catch {
        set ::em::prjname $::env(E_MENU_PN)
        set ::em::prjset 1  ;# 1st (2nd would be in PN=)
        }
}
                    #====== to end up inits
proc initend {} {
    bind . <FocusOut> { if {"%W" =="."} {::em::focused_win false} }
    bind . <FocusIn>  { if {"%W" =="."} {::em::focused_win true} }
    bind . <Control-t> {.cb invoke}
    bind . <Control-e> {::em::edit_menu}
    bind . <Control-r> {::em::reread_init}
    bind . <Control-d> {::em::destroy_emenus}
    bind . <Button-3> {
        set ::em::skipfocused 1
        tk_popup .popupMenu %X %Y
    }
    bind . <Escape> {::em::on_exit}
    wm protocol . WM_DELETE_WINDOW {::em::on_exit}
    bind . <Control-Left>  {::em::win_width -1}
    bind . <Control-Right> {::em::win_width 1}
    if {$::em::dotop} {.cb invoke}
    set ::em::start0 0
    ::em::focus_button $::em::lasti
    if {[iswindows]} {
        if {[wm attributes . -alpha] < 0.1} {wm attributes . -alpha 1.0}
    } else {
        wm deiconify .
    }
    update idletasks
}
}
::em::initbegin
::em::initcomm
::em::initmain
::em::initmenu
::em::initauto
::em::initend
# *****************************   EOF   *****************************

