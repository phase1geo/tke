#########################################################################
#
#  The add_shortcut plugin allows a user to add his/her own shortcuts
#  in addition to the existing TKE shortcuts. In particular, they can
#  be "localized" substitutions for Ctrl-C, Ctrl-X, Ctrl-V.
#  Or e.g. F3 for "find next".
#  See README.md for details of usage.
#
#########################################################################

namespace eval add_shortcut {

  # for debugging
#  proc d {args} {tk_messageBox -title "INFO" -icon info -message "$args"; return 1}

  variable listIt {}
  variable adshdir [file join [api::get_plugin_source_directory] adsh]
  variable datadir [api::get_plugin_data_directory]
  variable inifile [file join $datadir adsh_$::tcl_platform(platform).ini]
  variable version ""
  variable CURRENTVERSION [api::plugin::get_header_info version] ;# "1.2"

  source $adshdir/getsetini.tcl

  ######################################################################

  proc get_txt {} {

    set file_index [api::file::current_index]
    if {$file_index == -1} {
      return ""
    }
    return [api::file::get_info $file_index txt]

  }

  ######################################################################
  # show message with icon and title

  proc showMsg {icon ttl msg} {

    tk_messageBox -title "$ttl" -icon $icon -message "$msg"
    return

  }

  ######################################################################
  # pick a command/event/menu item out of its description
  # see also adsh.tcl as for getShortcutCommand

  proc getShortcutCommand {com} {

    set com [string map {\\\" \"} $com]
    if {[set p [string first "=" $com]] > -1} {
      set tp [string toupper [string trim [string range $com 0 $p-1]]]
      set ev [string trim [string range $com $p+1 end]]
      return [list $tp $ev]
    }
    return ""

  }

  ######################################################################
  # Get current word or selection

  # returns a list containing:
  # - selection/word
  # - starting position of selection/word or 0
  # - ending position of selection/word

  proc get_selection {} {

    set txt [get_txt]
    if {$txt == ""} {return [list "" 0 0]}
    set err [catch {$txt tag ranges sel} sel]
    if {!$err && [llength $sel]==2} {
      lassign $sel pos pos2           ;# single selection
      set sel [$txt get $pos $pos2]
    } else {
      if {$err || [string trim $sel]==""} {
        set pos  [$txt index "insert wordstart"]
        set pos2 [$txt index "insert wordend"]
        set sel [string trim [$txt get $pos $pos2]]
        if {![string is wordchar -strict $sel]} {
          # when cursor just at the right of word: take the word at the left
          # e.g. if "_" stands for cursor then "word_" means selecting "word"
          set pos  [$txt index "insert -1 char wordstart"]
          set pos2 [$txt index "insert -1 char wordend"]
          set sel [$txt get $pos $pos2]
        }
      } else {
        foreach {pos pos2} $sel {     ;# multiple selections: find current one
          if {[$txt compare $pos >= insert] ||
          [$txt compare $pos <= insert] && [$txt compare insert <= $pos2]} {
            break
          }
        }
        set sel [$txt get $pos $pos2]
      }
    }
    if {[string length $sel] == 0} {
      set pos 0
    }
    return [list $sel $pos $pos2]

  }

  ######################################################################
  # Check if the platform is MS Windows

  proc iswindows {} {

    return [expr {$::tcl_platform(platform) == "windows"} ? 1: 0]

  }

  ######################################################################
  # Normalize filename as for Windows

  proc fn {fname} {

    if {[iswindows]} {
      set fname [string map {/ \\\\} $fname]
    }
    return $fname

  }

  ######################################################################
  # get a console

  proc getConsole {} {

    variable adshdir
    if {[iswindows]} {
      return "cmd.exe /c \"[file join $adshdir run_pause.bat]\""
    }
    if {[catch {set lang "-fa [lindex [split $::env(LANG) .] 0].utf8"}]} {
      set lang ""
    }
    return "xterm $lang -fs 12 -geometry 90x24+300 -e \"[file join $adshdir run_pause.sh]\""

  }

  ######################################################################
  # get a default browser

  proc getBrowser {} {

    set commands {xdg-open open start}
    foreach browser $commands {
      if {$browser eq "start"} {
        set command [list {*}[auto_execok start] {}]
      } else {
        set command [auto_execok $browser]
      }
      if {[string length $command]} {
        return $command
      }
    }
    return "firefox"

  }

  ######################################################################
  # get shebang (1st line of buffer)

  proc getShebang {} {

    set txt [get_txt]
    if {$txt == ""} {return ""}
    set pos  [$txt index "1.0 linestart"]
    set pos2 [$txt index "1.0 lineend"]
    set res [string trim [$txt get $pos $pos2]]
    set res [string map [list \" "" \{ "" \} "" \[ "" \] ""] $res]
    return $res

  }

  ######################################################################
  # prepare a command (concerning the wildcars)

  proc prep1 {comm pr {repl ""}} {

    set abra "Ca!Da!Bra!"
    set comm [string map [list %% $abra] $comm]
    if {$pr=="end"} {
      return [string map [list $abra %] $comm]
    }
    set comm [string map [list $pr $repl] $comm]
    return [string map [list $abra %%] $comm]

  }

  proc prepComm {comm} {

    set dt [clock seconds]
    set comm [prep1 $comm %t0 [clock format $dt -format %H:%M:%S]]
    set comm [prep1 $comm %t1 [clock format $dt -format %Y-%m-%d]]
    set comm [prep1 $comm %t2 [clock format $dt -format %Y-%m-%d_%H:%M:%S]]
    set comm [prep1 $comm %t3 [clock format $dt -format %A]]
    set comm [prep1 $comm %t  [getConsole]]
    set comm [prep1 $comm %b  [getBrowser]]
    set comm [prep1 $comm %#! [getShebang]]
    lassign [get_selection] sel
    lassign [split $sel \n] s
    set comm [prep1 $comm %s $s]
    set file_index [api::file::current_index]
    if {$file_index != -1} {
      set file_name [fn [api::file::get_info $file_index fname]]
      set dir_name [fn [file dirname $file_name]]
      set comm [prep1 $comm %f $file_name]
      set comm [prep1 $comm %d $dir_name]
      set comm [prep1 $comm %x [file extension $file_name]]
      set comm [prep1 $comm %n [file rootname [file tail $file_name]]]
    }
    return [prep1 $comm end]

  }

  ######################################################################
  # process %IF wildcard

  proc IF {comm} {

    if {[string first "%IF " $comm]==0} {
      set comm [string range $comm 4 end]
      set pthen [string first " %THEN " $comm]
      set pelse [string first " %ELSE " $comm]
      if {$pthen > 0} {
        if {$pelse < 0} {set pelse 9999}
        set ifcond [string trim [string range $comm 0 $pthen-1]]
        if {[catch {set res [expr $ifcond]} e]} {
          showMsg error "ERROR" "ERROR: incorrect condition of IF:\n$ifcond\n\n($e)"
          return ""
        }
        set thencomm [string trim [string range $comm $pthen+6 $pelse-1]]
        set comm     [string trim [string range $comm $pelse+6 end]]
        if {$res} {
          set comm $thencomm
        }
      }
    }
    return $comm

  }

  ######################################################################
  # run 'vip' command
  proc vip {cmd} {

    set cd [string range $cmd 0 2]
    if { ([iswindows] && [string toupper $cd] == "CD ") || $cd == "cd " } {
      if {[set cd [string trim [string range $cmd 3 end]]] != "."} {
        catch {cd $cd}
      }
      return true
    }
    return false

  }

  ######################################################################
  # execute the function of shortcut

  proc runShortCut {contents} {

    set err ""
    set contents [string trim [string map {"|!|" \n} $contents] \{\}]
    foreach command [split $contents \n] {
      lassign [getShortcutCommand $command] typ comm
      set comm [prepComm $comm]
      if {[set comm [IF $comm]]!=""} {
        switch $typ {
          "MENU" { ;# call the TKE menu item
            if {![catch {api::menu::invoke $comm} err]} {
              set err ""
            }
          }
          "EVENT" { ;# generate the event for TKE
            if {![catch {event generate [focus] $comm} err]} {
              set err ""
            }
          }
          "COMMAND" { ;# run the external command
            if {![vip $comm]} {
              if {![catch {exec {*}$comm &} err]} {
                set err ""
              }
            }
          }
        }
      }
      if {$err!=""} {
        showMsg error "ERROR" "Error of calling $typ:\n\n$comm
            \n[string repeat = 24]
            \nreturned: $err\
            \n\n[string repeat = 24]
            \nCall \"Add shortcuts\" plugin to fix it."
        break
      }
    }
    return

  }

  ######################################################################
  # select those keypresses that are present in the shortcut list
  # and execute their commands

  proc pressProc {K k s} {

    variable listIt
    foreach it $listIt {
      lassign $it txt val id img node typ contents
      if {"$id" == "$K/$k/$s" && [string first "-NO" $img] < 0} {
        runShortCut $contents
        return
      }
    }
    return

  }

  ######################################################################
  # create ini file if absent

  proc make_inifile {} {

    variable version
    variable CURRENTVERSION
    variable adshdir
    variable inifile
    if {![file exists $inifile]} {
      catch {file mkdir [file dirname $inifile]}
      set from [file join $adshdir adsh_$::tcl_platform(platform).ini]
      if {[catch {file copy -force $from $inifile} e]} {
        if {$i} {
          api::show_error "\nCannot create:\n$inifile\n------------\n$e"
          return
        }
      }
      set version $CURRENTVERSION
    }

  }

  ######################################################################
  # two standard on_store/on_restore handlers

  # do_store does nothing
  proc do_store {index} {
    return
  }

  # do_restore loads the shortcuts data
  proc do_restore {index} {

    variable listIt
    variable adshdir
    variable inifile
    variable version
    make_inifile
    GetSetIni create getsetini
    getsetini getIni $inifile
    getsetini destroy
    return

  }

  ######################################################################
  # load the saved shortcuts and add the Keypress binding (only once)

  proc update_shortcuts {} {

    variable listIt
    if { [string first "add_shortcut" [bind all "<KeyPress>"]] < 0} {
      do_restore _
      # run the shortcuts assigned to autoload
      foreach it $listIt {
        lassign $it txt val id img node typ contents
        if {[string first "-AUTO" $img] > 0 && [string first "-NO" $img] < 0} {
          after 100 [list ::add_shortcut::runShortCut [list "$contents"]]
        }
      }
      bind all "<KeyPress>" {+ after idle \
        { ::add_shortcut::pressProc {%K} {%k} {%s} } }
    }
    return

  }

  ######################################################################
  # call the Adding shortcuts dialog

  proc do_add_shortcut {} {

    variable version
    variable CURRENTVERSION
    variable adshdir
    variable inifile
    do_restore _
    lassign [split $version .] v1 v2
    if {"$v1$v2"<15} {
      # total updating ini-file
      if {[tk_messageBox -title "Updating to version $CURRENTVERSION" \
        -icon warning -message "$inifile

would be replaced by a new file.
________________________________

The old file would be saved into

$inifile.bak" -type okcancel]=="ok"} {
        catch "file copy -force $inifile $inifile.bak"
        catch "file delete $inifile"
        do_restore _
      } else {
        return
      }
    }
    set fg [api::get_default_foreground]
    set bg [api::get_default_background]
    set fE "#aeaeae"
    catch {set fE [[get_txt] cget -foreground]}
    set bE #161717
    catch {set bE [[get_txt] cget -background]}
    set fS "fS=#ffffff"
    catch {set fS [[get_txt] cget -selectforeground]}
    set bS "bS=#0000ff"
    catch {set bS [[get_txt] cget -selectbackground]}
    set cc #888888
    catch {set cc [[get_txt] cget -insertbackground]}
    if {[catch { exec tclsh [file join $adshdir adsh.tcl] $CURRENTVERSION $inifile $fg $bg $fE $bE $fS $bS $cc &} e]} {
      # no actions taken here though
    }
    return

  }

  ######################################################################
  # while exposing itself the plugin should load the shortcuts

  proc handle_state {} {

    update_shortcuts
    return 1

  }

}

######################################################################
# register the plugin in TKE

api::register add_shortcut {
  {menu command {Add Shortcuts} \
      {add_shortcut::do_add_shortcut}  add_shortcut::handle_state}
  {on_reload add_shortcut::do_store add_shortcut::do_restore}
}

