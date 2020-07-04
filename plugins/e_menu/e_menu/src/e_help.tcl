#! /usr/bin/env tclsh
package require Tk
package require http
catch {package require tls}
if {![namespace exists apave]} {source [file join [file normalize [file dirname [info script]]] apaveinput.tcl]}
namespace eval ::eh {variable my_browser ""
variable hroot "$::env(HOME)/DOC/www.tcl.tk/man/tcl8.6"
variable formtime %H:%M:%S
variable formdate %Y-%m-%d
variable formdt   %Y-%m-%d_%H:%M:%S
variable formdw   %A
variable mx 0 my 0
variable reginit 1
variable solo [expr {[info exist ::argv0] && [file normalize $::argv0] eq [file normalize [info script]]} ? 1 : 0]}
proc ddd {args} {set msg ""; foreach l $args {append msg " $l\n"}
::apave::paveObj ok info DEBUG $msg -text 1 -h 10 -centerme .}
proc a {a} {set m [array get $a]; d $m}
proc ::eh::dialog_box {ttl mes {typ ok} {icon info} {defb OK} args} {set pdlg [::apave::APaveDialog new]
set opts [list -t 1 -w 80]
lappend opts {*}$args
switch -glob -- $typ {okcancel - yesno - yesnocancel {if {$defb eq "OK" && $typ ne "okcancel" } {set defb YES}
set ans [$pdlg $typ $icon $ttl \n$mes\n $defb {*}$opts]}
default {set ans [$pdlg ok $icon $ttl \n$mes\n {*}$opts]}}
$pdlg destroy
return $ans}
proc ::eh::message_box {mes {typ ok} {ttl ""}} {if {[string length $ttl] == 0} {set ttl [wm title .]}
set mes [string trimleft $mes "\{"]
set mes [string trimright $mes "\}"]
set ans [tk_messageBox -title $ttl -icon info -message "$mes" -type $typ -parent .]
return $ans}
proc ::eh::get_tty {inconsole} {if {$inconsole ne ""} {set tty $inconsole} elseif {[::iswindows]} {set tty "cmd.exe /K"} elseif {[auto_execok lxterminal] ne ""} {set tty lxterminal} else {set tty xterm}
return $tty}
proc ::eh::get_timedate {} {set systime [clock seconds]
set curtime [clock format $systime -format $::eh::formtime]
set curdate [clock format $systime -format $::eh::formdate]
set curdt   [clock format $systime -format $::eh::formdt]
set curdw   [clock format $systime -format $::eh::formdw]
return [list $curtime $curdate $curdt $curdw $systime]}
proc ::eh::get_language {} {if {[catch {set lang "[lindex [split $::env(LANG) .] 0].utf8"}]} {return ""}
return $lang}
proc ::eh::zoom_window {win} {if {[::iswindows]} {wm state $win zoomed
} else {wm attributes $win -zoomed 1}}
proc ::eh::center_window {win {ornament 1} {winwidth 0} {winheight 0}} {if {$ornament == 0} {lassign {0 0} left top
set usewidth [winfo screenwidth .]
set useheight [winfo screenheight .]
} else {set tw ${win}_temp_
catch {destroy $tw}
toplevel $tw
wm attributes $tw -alpha 0.0
zoom_window $tw
update
set usewidth [winfo width $tw]
set useheight [winfo height $tw]
set twgeom [split "[wm geometry $tw]" +]
set left [lindex $twgeom 1]
set top [lindex $twgeom 2]
destroy $tw}
wm deiconify $win
if {$winwidth > 0 && $winheight > 0} {wm geometry $win ${winwidth}x${winheight}
} else {set winwidth [eval winfo width $win]
set winheight [eval winfo height $win]}
set x [expr $left + ($usewidth - $winwidth) / 2]
set y [expr $top + ($useheight - $winheight) / 2]
wm geometry $win +$x+$y
wm state . normal
update}
proc ::eh::checkgeometry {} {set scrw [expr [winfo screenwidth .] - 12]
set scrh [expr {[winfo screenheight .] - 36}]
lassign [split [wm geometry .] x+] w h x y
set necessary 0
if {($x + $w) > $scrw } {set x [expr {$scrw - $w}]
set necessary 1}
if {($y + $h) > $scrh } {set y [expr {$scrh - $h}]
set necessary 1}
if {$necessary} {wm geometry . ${w}x${h}+${x}+${y}}}
proc ::eh::ctrl_alt_off {cmd} {if {[::iswindows]} {return "if \{%s == 8\} \{$cmd\}"
} else {return "if \{\[expr %s&14\] == 0\} \{$cmd\}"}}
proc ::eh::destroyed {app} {return [expr ![catch {send -async $app {destroy .}} e]]}
proc ::eh::mouse_drag {win mode x y} {switch -- $mode {1 { lassign [list $x $y] ::eh::mx ::eh::my }
2 -
3 {if {$::eh::mx>0 && $::eh::my>0} {lassign [split [wm geometry $win] x+] w h wx wy
wm geometry $win +[expr $wx+$x-$::eh::mx]+[expr $wy+$y-$::eh::my]
if {$mode==3} {lassign {0 0} ::eh::mx ::eh::my }}}}}
proc ::eh::fileAttributes {fname {attrs "-"} {atime ""} {mtime ""} } {if {$attrs eq "-"} {set attrs [file attributes $fname]
return [list $attrs [file atime $fname] [file mtime $fname]]}
file atime $fname $atime
file mtime $fname $mtime}
proc ::eh::write_file_untouched {fname data} {lassign [::eh::fileAttributes $fname] f_attrs f_atime f_mtime
set ch [open $fname w]
foreach line $data { puts $ch "$line" }
close $ch
::eh::fileAttributes $fname $f_attrs $f_atime $f_mtime}
proc ::eh::escape_quotes {sel} {if {![::iswindows]} {set sel [string map [list "\"" "\\\""] $sel]}
return $sel}
proc ::eh::escape_specials {sel} {return [string map [ list \" \\\" "\n" "\\n" "\\" "\\\\" "\$" "\\\$" "\}" "\\\}"  "\{" "\\\{"  "\]" "\\\]"  "\[" "\\\[" ] $sel]}
proc ::eh::escape_links {sel} {return [string map [list " " "+"] $sel]}
proc ::eh::delete_specsyms {sel {und "_"} } {return [string map [list "\"" ""  "\%" ""  "\$" ""  "\}" ""  "\{" "" "\]" ""  "\[" ""  "\>" ""  "\<" ""  "\*" ""  " " $und] $sel]}
proc ::eh::get_underlined_name {name} {return [string map {/ _ \\ _ { } _ . _} $name]}
proc ::eh::lexists {url} {if {$::eh::reginit} {set ::eh::reginit 0
::http::register https 443 ::tls::socket}
if {[catch {set token [::http::geturl $url]} e]} {if {$::eh::solo} {grid [label .l -text ""]}
message_box "ERROR: couldn't connect to:\n\n$url\n\n$e"
return 0}
if {$::eh::solo} { exit }
if {[string first "<title>URL Not Found" [::http::data $token]] < 0} {return 1
} else {return 0}}
proc ::eh::links_exist {h1 h2 h3} {if {[lexists "$h1"]} {return "$h1"
} elseif {[lexists "$h2"]} {return "$h2"
} elseif {[lexists "$h3"]} {return "$h3"
} else {return ""}}
proc ::eh::local { {help ""} } {set l1 [string toupper [string range "$help" 0 0]]
if {[string first "http" "$::eh::hroot"]==0} {set http true
set ext "htm"
} else {set http false
set ext "htm"}
set help [string tolower $help]
set h1 "$::eh::hroot/TclCmd/$help.$ext"
set h2 "$::eh::hroot/TkCmd/$help.$ext"
set h3 "$::eh::hroot/Keywords/$l1.$ext"
if {$http} {set link [links_exist $h1 $h2 $h3]
if {[string length $link] > 0} {return "$link"}
} else {if {[file exists $h1]} {return "file://$h1"
} elseif {[file exists $h2]} {return "file://$h2"
} elseif {[file exists $h3]} {return "file://$h3"}
set h1 "$::eh::hroot/TclCmd/contents.$ext"}
return "$h1"}
proc ::eh::html { {help ""} {local 0}} {if {$local} {return [local "$help"]}
set l1 [string toupper [string range "$help" 0 0]]
set h1 "https://www.tcl.tk/man/tcl8.6/TclCmd/$help.htm"
set h2 "https://www.tcl.tk/man/tcl8.6/TkCmd/$help.htm"
set h3 "https://www.tcl.tk/man/tcl8.6/Keywords/$l1.htm"
set link [links_exist $h1 $h2 $h3]
if {[string length $link] == 0} {return [local "$help"]}
return $link}
proc ::eh::invokeBrowser {url} {
set commands {xdg-open open start}
foreach browser $commands {if {$browser eq "start"} {set command [list {*}[auto_execok start] {}]
} else {set command [auto_execok $browser]}
if {[string length $command]} {break}}
if {[string length $command] == 0} {message_box "ERROR: couldn't find browser"}
if {[catch {exec {*}$command $url &} error]} {message_box "ERROR: couldn't execute '$command':\n$error"}}
proc ::eh::browse { {help ""} } {if {$::eh::my_browser ne ""} {exec ${::eh::my_browser} "$help" &
} else {invokeBrowser "$help"}}
if {$::eh::solo} {if {$argc > 0} {if {[lindex $::argv 0] eq "-local"} {set page [::eh::local [lindex $::argv 1]]
} else {set page [::eh::html [lindex $::argv 0]]}
::eh::browse "$page"
} else {puts "\nRun:

  tclsh e_help.tcl \[-local\] page

to get Tcl/Tk help page:

  TclCmd/page.htm or
  TkCmd/page.htm or
  Keywords/P.htm\n"}
exit}
#by trimmer
