#! /usr/bin/env tclsh
#
# Calling help pages of Tcl/Tk from www.tcl.tk
#
# Use:
#   tclsh e_help.tcl package
# brings up www.tcl.tk/man/tcl8.6/TclCmd/package.htm
#
# You might create an offline version of Tcl/Tk help, and make it
# callable from this script.
#
# Local help is downloaded with wget:
# wget -r -k -l 2 -p --accept-regex=.+/man/tcl8\.6.+ https://www.tcl.tk/man/tcl8.6/
#
# *******************************************************************
# Scripted by Alex Plotnikov
# *******************************************************************

package require Tk
package require http
package require tls

set srcdir [file normalize [file dirname [info script]]]
lappend auto_path $::srcdir; package require apave

namespace eval eh {
  # your preferable browser:
  # can be set by b= parameter
  set my_browser ""

  # select one of these and comment others to call offline help
  set hroot "C:\\DOC\\www.tcl.tk\\man\\tcl8.6"        ;# offline help directory
  set hroot "$::env(HOME)/DOC/www.tcl.tk/man/tcl8.6"  ;# offline help directory

  set formtime %H:%M:%S            ;# time format
  set formdate %Y-%m-%d            ;# date format
  set formdt   %Y-%m-%d_%H:%M:%S   ;# date+time format
  set formdw   %A                  ;# day of week format

  set geany ""
}
# *******************************************************************
# common procedures
#====== debug messages (several params)
proc d {args} {message_box "$args"}

#====== debug messages (array passed by name)
proc a {a} {set m [array get $a]; d $m}

#====== to check if the platform is MS Windows
proc iswindows {} {
  return [expr {$::tcl_platform(platform) == "windows"} ? 1: 0]
}
#====== to get system time & date
proc get_timedate {} {
  set systime [clock seconds]
  set curtime [clock format $systime -format $::eh::formtime]
  set curdate [clock format $systime -format $::eh::formdate]
  set curdt   [clock format $systime -format $::eh::formdt]
  set curdw   [clock format $systime -format $::eh::formdw]
  return [list $curtime $curdate $curdt $curdw $systime]
}
#====== 'mes' message of 'typ' type
proc message_box {mes {typ ok} {ttl ""}} {
  if {[string length $ttl] == 0} {set ttl [wm title .]}
  set mes [string trimleft $mes "\{"]
  set mes [string trimright $mes "\}"]
  set ans [tk_messageBox -title $ttl -icon info -message "$mes" \
    -type $typ -parent .]
  return $ans
}
#====== ask 'mes', return true if OK pressed
proc question_box {ttl mes {typ okcancel}} {
  set ans [ message_box $mes $typ $ttl]
  return [expr {$ans eq "ok"} ? 1 : 0]
}
#====== to maximize 'win' window
proc zoom_window {win} {
  if {[iswindows]} {
    wm state $win zoomed
  } else {
    wm attributes $win -zoomed 1
  }
}
#====== to center window on screen
proc center_window {win {ornament 1} {winwidth 0} {winheight 0}} {
  # to center a window regarding taskbar(s) sizes
  #  center_window win     ;# if win window has borders and titlebar
  #  center_window win 0   ;# if win window isn't ornamented with those
  if {$ornament == 0} {
    lassign {0 0} left top
    set usewidth [winfo screenwidth .]   ;# it's straightforward
    set useheight [winfo screenheight .]
  } else {
    set tw ${win}_temp_               ;# temp window path
    catch {destroy $tw}               ;# clear out
    toplevel $tw                      ;# make a toplevel window
    wm attributes $tw -alpha 0.0      ;# make it be not visible
    zoom_window $tw                   ;# maximize the temp window
    update
    set usewidth [winfo width $tw]    ;# the window width and height define
    set useheight [winfo height $tw]  ;# a useful area for all other windows
    set twgeom [split "[wm geometry $tw]" +]
    set left [lindex $twgeom 1]       ;# all ornamented windows are shifted
    set top [lindex $twgeom 2]        ;# from left and top by these values
    destroy $tw
  }
  wm deiconify $win
  if {$winwidth > 0 && $winheight > 0} {
    wm geometry $win ${winwidth}x${winheight}  ;# geometry to set
  } else {
    set winwidth [eval winfo width $win]       ;# geometry is already set
    set winheight [eval winfo height $win]
  }
  set x [expr $left + ($usewidth - $winwidth) / 2]
  set y [expr $top + ($useheight - $winheight) / 2]
  wm geometry $win +$x+$y
  wm state . normal
  update
}
#====== to get number from str
proc getN {sn {defn 0} } {
  if {[catch {set n [expr "$sn"]} e] } { set n $defn }
  return $n
}
#====== borrowed from http://wiki.tcl.tk/557
proc invokeBrowser {url} {
  # open is the OS X equivalent to xdg-open on Linux, start is used on Windows
  set commands {xdg-open open start}
  foreach browser $commands {
    if {$browser eq "start"} {
      set command [list {*}[auto_execok start] {}]
    } else {
      set command [auto_execok $browser]
    }
    if {[string length $command]} {
      break
    }
  }
  if {[string length $command] == 0} {
    message_box "ERROR: couldn't find browser"
  }
  if {[catch {exec {*}$command $url &} error]} {
    message_box "ERROR: couldn't execute '$command':\n$error"
  }
}

# *******************************************************************
# e_help's procedures

namespace eval eh {

  set reginit 1
  set solo [expr {$::argv0==[info script]} ? 1 : 0]

  #====== check if link exists
  proc lexists {url} {
    if {$::eh::reginit} {
      set ::eh::reginit 0
      ::http::register https 443 ::tls::socket
    }
    if {[catch {set token [::http::geturl $url]} e]} {
      if {$::eh::solo} {
      grid [label .l -text ""]}  ;# hide wish
      message_box "ERROR: couldn't connect to:\n\n$url\n\n$e"
      return 0
    }
    if {$::eh::solo} { exit }
    if {[string first "<title>URL Not Found" [::http::data $token]] < 0} {
      return 1
    } else {
      return 0
    }
  }
  #====== check if links exist
  proc links_exist {h1 h2 h3} {
    if {[lexists "$h1"]} {
      return "$h1"            ;# Tcl commands help
    } elseif {[lexists "$h2"]} {
      return "$h2"            ;# Tk commands help
    } elseif {[lexists "$h3"]} {
      return "$h3"            ;# Tcl/Tk keywords help (by first letter)
    } else {
      return ""
    }
  }
  #====== offline help
  proc local { {help ""} } {
    set l1 [string toupper [string range "$help" 0 0]]
    if {[string first "http" "$::eh::hroot"]==0} {
      set http true
      set ext "htm"
    } else {
      set http false
      set ext "htm"  ;# this extention was returned by wget, change if need
    }
    set help [string tolower $help]
    set h1 "$::eh::hroot/TclCmd/$help.$ext"
    set h2 "$::eh::hroot/TkCmd/$help.$ext"
    set h3 "$::eh::hroot/Keywords/$l1.$ext"
    if {$http} {
      set link [links_exist $h1 $h2 $h3]
      if {[string length $link] > 0} {
        return "$link"             ;# try local help pages
      }
    } else {
      if {[file exists $h1]} {
        return "file://$h1"        ;# view Tcl commands help
      } elseif {[file exists $h2]} {
        return "file://$h2"        ;# view Tk commands help
      } elseif {[file exists $h3]} {
        return "file://$h3"        ;# view Keywords help (by first letter)
      }
      set h1 "$::eh::hroot/TclCmd/contents.$ext" ;# Tcl index, if nothing found
    }
    return "$h1"
  }
  #====== online help, change links if need
  proc html { {help ""} {local 0}} {
    if {$local} {
      return [eh::local "$help"]
    }
    set l1 [string toupper [string range "$help" 0 0]]
    set h1 "https://www.tcl.tk/man/tcl8.6/TclCmd/$help.htm"   ;# Tcl
    set h2 "https://www.tcl.tk/man/tcl8.6/TkCmd/$help.htm"    ;# Tk
    set h3 "https://www.tcl.tk/man/tcl8.6/Keywords/$l1.htm"   ;# keywords A-Z
    set link [links_exist $h1 $h2 $h3]
    if {[string length $link] == 0} {
      return [eh::local "$help"]       ;# try local help pages
    }
    return $link
  }
  #====== to call browser
  proc browse { {help ""} } {
    if {$::eh::my_browser != ""} {
      exec ${::eh::my_browser} "$help" &
    } else {
      ::invokeBrowser "$help"
    }
  }
}
# *******************************************************************

if {$::eh::solo} {
  if {$argc > 0} {
    if {[lindex $::argv 0] eq "-local"} {
      set page [eh::local [lindex $::argv 1]]
    } else {
      set page [eh::html [lindex $::argv 0]]
    }
    eh::browse "$page"
  } else {
    grid [label .l -text " "]  ;# wish underlied
    message_box "
Call Tcl/Tk help page with\n
\n   tclsh e_help.tcl \[-local\] page\n
\nand you'll get
\n   TclCmd/page.htm or
\n   TkCmd/page.htm or
\n   Keywords/P.htm
\nin your browser.
    "
  }
  exit
}
# *****************************   EOF   *****************************
