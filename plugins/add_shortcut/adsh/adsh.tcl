######################################################################
#
# Making the list of shortcuts bound to TKE events.
#
######################################################################

package require Tk

namespace eval adsh {

  variable pavedir [file normalize [file dirname [info script]]]
  # definitions of PaveDialog and GetSetIni oo::classes
  source [file join $adsh::pavedir pavedialog.tcl]
  source [file join $adsh::pavedir obbit.tcl]
  source [file join $adsh::pavedir getsetini.tcl]

  variable version ""
  variable Win .adsh
  variable win $Win.fra
  variable pdlg {} Contents {} imorig {} imadd {}
  variable listBak {} getsetini {} messg {} lastid {} active 1 auto 0 sort 1
  variable notsaved 0 wassaved 0 ID {} Na {} No {} Typ {} listIt {} geometry ""
  variable notshow "Don't show again"
  variable ans_test 0
  variable ans_warn 0
  variable lastbak -1
  variable verbose 1
  variable doauto "-AUTO"
  variable dodisabled "-NO"
  variable flagEnabled "Y"  ;# "◉"
  variable flagDisabled "-" ;# "⦾"
  variable underline [string repeat "-" 80]

  variable inifile [file join $pavedir adsh_$::tcl_platform(platform).ini]
  variable fgColor "#364C64" ;# "#FC5F12"
  variable bgColor "#E5E4E3"
  variable fg $fgColor
  variable bg $bgColor
  variable fg2 black
  variable bg2 white
  variable fgS white
  variable bgS blue
  variable cc white
  variable EOL "|!|"

  # see also main.tcl as for typs
  variable typs [list MENU EVENT COMMAND MISC]

  variable textTags [list [list "b" "-font {-family Helvetica -weight bold}"] \
                          [list "i" "-font {-family Helvetica -slant italic}"] \
                          [list "red" "-foreground $fgColor -background $bgColor"]]
  variable descs {
    {"" ""}

    {"MENU" "The <red><b> MENU </b></red> type allows you to assign any\
of TKE menu actions to a shortcut. For example:<i>
   MENU = Edit/Copy
   MENU = File/Save</i>
This typeof shortcut allows you to have several shortcuts bound to a menu\
entry. You may desire to have F2 aside with Ctrl+S to save files. You can\
assign only one MENU in this type. If you need several actions try MISC."}

    {"EVENT" "The <red><b> EVENT </b></red> type allows you to assign\
any of available Tk events to a shortcut. For example:<i>
   EVENT = <KeyPress-F2>
   EVENT = <<Copy>>
   EVENT = <<Paste>></i>
(See the Tcl/Tk documentation for the events.) \
You can assign only one EVENT in this type.\
If you need several actions try MISC."}

    {"COMMAND" "The <red><b> COMMAND </b></red> type allows you to assign\
any of external commands available in your OS. For example:<i>
 COMMAND = cd /home/me/projects
 COMMAND = git add *
 COMMAND = git commit -am \"On %d\"</i>
You can have several COMMANDs in this type. Also the following wildcards\
are available:
 %t0 - current time (hh:mm:ss)
 %t1 - current date (yyyy-mm-dd)
 %t2 - current date+time (yyyy-mm-dd_hh:mm:ss)
 %t3 - current day of week (e.g. Monday)
 %f  - full name of current edited file
 %n  - root name of current edited file
 %x  - extension of current edited file
 %d  - directory of current edited file
 %s  - current selection/word
 %t  - terminal
 %b  - browser
 %#! - 1st line of file (shebang)
 %IF..%THEN..%ELSE - conditional command, e.g.:
  COMMAND = %IF \"%x\"==\".html\" %THEN %b \"%f\"
  COMMAND = %IF \[string match *wish* \"%#!\"\] %THEN wish \"%f\""}

    {"MISC" "The <red><b> MISC </b></red> type allows you to assign\
several of previous types to a shortcut. See details in those types.
Example:<i>
   EVENT = <Control-percent>
   MENU = File/Save
   COMMAND = some_external_command</i>
You can use the # for comments."}
  }

  ######################################################################
  # make the namespace variables actual

  proc bringMeVars {} {

    uplevel 1 {
      variable version
      variable Win
      variable win
      variable pdlg
      variable fgColor
      variable bgColor
      variable EOL
      variable fg
      variable bg
      variable fg2
      variable bg2
      variable fgS
      variable bgS
      variable cc
      variable notsaved
      variable wassaved
      variable active
      variable auto
      variable sort
      variable doauto
      variable dodisabled
      variable flagEnabled
      variable flagDisabled
      variable underline
      variable lastid
      variable No
      variable Typ
      variable Contents
      variable ID
      variable Na
      variable imorig
      variable imadd
      variable listIt
      variable listBak
      variable geometry
      variable getsetini
      variable inifile
      variable typs
      variable textTags
      variable descs
      variable messg
      variable notshow
      variable ans_test
      variable ans_warn
      variable lastbak
      variable verbose
      set No [string trim $No]
      set Na [string trim $Na]
    }
    return

  }

  ######################################################################
  # for debugging

  proc d {args} {tk_messageBox -title "INFO" -icon info -message "$args"}

  proc mp {num} { ;# mark the code as passed
    if {![info exists ::stek]} {array set ::stek {}}
    if {![info exists ::stek($num)]} {set ::stek($num) 1; d $num}
  }

  ######################################################################
  # pick a command/event/menu item out of its description
  # (see also main.tcl as for getShortcutCommand)

  proc getShortcutCommand {name com} {

    if {[regexp -nocase "$name\\s*=\\s*" $com]} {
      set e [string trim [string range $com [expr [string first "=" $com]+1] end]]
      if {$e==""} {
        set e "None"
      }
      return $e
    }
    return ""

  }

  ######################################################################
  # while exiting, ask for saving changes if are

  proc doExit {{resName ""}} {

    bringMeVars
    if {!$notsaved \
    || [pdlg yesno warn "EXIT" "\nDiscard all changes?\n" NO]==1} {
      pdlg res $Win 0
    }
    return

  }

  ######################################################################

  proc setNotSaved {val} {

    bringMeVars
    if {[set notsaved $val]} {
      set st normal
    } else {
      set st disabled
    }
    $win.fra2.butApply configure -state $st
    $win.fra2.butOK configure -state $st

  }

  ######################################################################
  # save the current data

  proc saveData {} {

    bringMeVars
    set currgeom [wm geometry $Win]
    lassign [split $currgeom x+] w h x y
    lassign [split $geometry x+] w0 h0 x0 y0
    if {$y!="" && $y0!=""} {
      foreach c {w h x y} {
        eval if \[expr abs(\$${c}-\$${c}0)<30\] \{set $c \$${c}0\}
      }
    }
    set geometry ${w}x${h}+${x}+${y}
    set lastid [selectionOfTreeView]
    set fbak $inifile.[set lastbak [expr [incr lastbak] % 8]].bak
    getsetini setIni $inifile -list listIt -single sort \
        -single geometry -single ans_warn -single lastid -single lastbak -single version
    set listIt $listBak
    getsetini setIni $fbak -list listIt -single sort -single version
    if {$ans_warn<10} {
      set ans_warn [pdlg ok warn "TO DO" "\nThe old settings were backed up in:\
          \n\n<i>  $fbak</i>
          \nRestart TKE to have the changes active." -text 1 -tags textTags \
          -w [expr [string length $fbak]-9] -h 7 -ch "Don't show this warning again"]
    }
    set wassaved 1
    setNotSaved 0

  }

  ######################################################################
  # apply changes

  proc doApply {} {

    bringMeVars
    changeItem
    saveData
    after 100 focus $win.entOrig

  }

  ######################################################################
  # exit with saving data

  proc doSaveExit {} {

    bringMeVars
    set verbose 0
    changeItem
    pdlg res $Win 1

  }

  ######################################################################
  # seek a default browser and call it to view the url

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
      pdlg ok err "ERROR" "\nERROR: a browser not found\n"
    } else {
      catch {exec {*}$command $url &}
    }
    return

  }

  ######################################################################
  # show a hint/message in bottom of window

  proc doHint {msg {timo 0}} {

    bringMeVars
    if {$verbose} {
      $win.laBMess config -text "$msg"
      if {($msg!=$adsh::messg && $adsh::messg!="")==-1 || $msg==""} {
        return
      }
      if {$timo==0} {
        set timo [expr {[string length $msg] * 80}]
      }
      set adsh::messg [string trimright [string range $msg 0 end-1]]
      after $timo {
        adsh::doHint $adsh::messg 20
      }
    }

  }

  ######################################################################
  # return selection with escaped spaces

  proc escapedID {{id ""}} {

    return [string map {{ } {\ }} $id]

  }

  proc selectionOfTreeView {} {

    bringMeVars
    return [string trim [$win.tre1 selection] \{\}]

  }

  ######################################################################
  # get a text string of the Contents text field

  proc getContents {} {

    bringMeVars
    set Contents [string trimright [$win.texComm get 1.0 end]]
    set Contents [string map [list \n $EOL \" \\\" \} \\\} \{ \\\{] $Contents]
    return $Contents

  }

  ######################################################################
  # check a correctness of all entry fields
  # return 0 at errors

  proc checkEntries {} {

    bringMeVars
    if {[string trim $No]==""} {
      bell
      doHint "Fill the <Group Name> field..."
      focus $win.entOrig
      return 0
    }
    if {[string trim $Na]=="" \
    && ([string trim $ID]!="" || [string trim $Typ]!="")} {
      bell
      doHint "Fill the <Name> field..."
      focus $win.entName
      return 0
    }
    if {[string trim $Na]!=""} {
      if {[string trim $ID]==""} {
        bell
        doHint "Fill the <ID> field..."
        focus $win.entID
        return 0
      }
      if {[string trim $Typ]=="" || !($Typ in $typs)} {
        bell
        doHint "Select the <Type> from the list..."
        focus $win.cbxTyp
        return 0
      }
      set conts [getContents]
      if {$conts==""} {
        bell
        doHint "Fill the <Contents> field..."
        focus $win.texComm
        return 0
      }
      set nakedcom [string toupper [string map {" " ""} $conts]]
      if {"$Typ" eq "MISC"} {
        for {set i 1} {$i<[expr [llength $typs]-1]} {incr i} {
          if {[string first "[lindex $typs $i]=" $nakedcom] > -1} {
            return 1 ;# all checked
          }
        }
        bell
        doHint "<Contents> has no TYPE = [lrange $typs 1 end-1]..." 7000
        focus $win.texComm
        return 0
      } elseif {[string first "$Typ=" $nakedcom] < 0} {
        bell
        doHint "<Contents> has no $Typ = ..." 7000
        focus $win.texComm
        return 0
      }
    }
    return 1

  }

  ######################################################################
  # update Contents field while selecting a type from its combobox

  proc selectingCombo {} {

    bringMeVars
    set typ [$win.cbxTyp get]
    foreach d $descs {
      lassign $d t conts
      if {$t == $typ} {
        $win.texDesc configure -state normal
        pdlg displayTaggedText $win.texDesc conts $textTags
        $win.texDesc configure -state disabled
        set comm $typ
        if {$typ!=""} {
          if {$typ!="MISC"} {
            set comm "$typ = "
          } else {
            set comm [join [lrange $typs 1 end-1] [set _ " =\n"]]$_
          }
        }
        $win.texComm replace 1.0 end $comm
        break
      }
    }
    return

  }

  ######################################################################
  # update all entry fields after selecting a new treeview item

  proc selectTreeItem {} {

    bringMeVars
    set idfoc [$win.tre1 focus]
    if {$idfoc == ""} {
      set idfoc [selectionOfTreeView]
    }
    foreach it $listIt {
      lassign $it txt val id img node typ contents
      if {$id==$idfoc} {
        if {$node==""} {
          if {$No==$txt && $ID==$val} return
          set No $txt
          set Na [set ID [set Typ [set Contents ""]]]
        } else {
          if {$No==$node && $ID==$val} return
          set No $node
          set Na $txt
          set ID $val
          set Typ $typ
          set Contents $contents
        }
        lassign [unpackImgOpt $img] img d auto
        set active [expr {$d==$flagEnabled}]
        $win.entID selection range 0 end
        break
      }
    }
    selectingCombo
    $win.texComm replace 1.0 end [string map [list $EOL \n \\\" \" \\\} \} \\\{ \{] $Contents]
    return

  }

  ######################################################################
  # get ID of group ($txt) or item ($id) of treeview

  proc getID {txt id} {

    if {$id==""} {return $txt}
    return $id

  }

  ######################################################################
  # check if exists a group (top) for an item

  proc isTopItem {top} {

    bringMeVars
    foreach it $listIt {
      lassign $it txt val id img node
      if {$node=="" && $txt==$top} {
        return true
      }
    }
    return false

  }

  ######################################################################
  # find an item in the item list for the current entry fields

  proc findItem {{idfoc ""}} {

    bringMeVars
    set i 0
    foreach it $listIt {
      lassign $it txt val id img node typ contents
      if {$id == $idfoc || [getID $txt $id] == [getID $No $ID]} {
        return [list $i $txt $val $id $img $node $typ $contents]
      }
      incr i
    }
    return -1

  }

  ######################################################################
  # add a new item from the entry fields
  # or update the item (after query) if it exists

  proc addItem {} {

    bringMeVars
    if {[checkEntries]} {
      lassign [findItem] iis - - idadd
      if {$Na==""} {
        set id [set txt $No]
        set node [set val [set typ [set contents ""]]]
        set img $imorig
        if {[$win.tre1 exists "$id"]} {
          set iis 1
        }
      } else {
        set id $ID
        set txt $Na
        set node $No
        set val $ID
        set img $imadd
        set typ $Typ
        set contents [getContents]
      }
      if {$iis > -1} {
        if {[pdlg yesno warn "ADD" \
            "The $id item already exists.\nChange anyway?"]==1} {
          changeItem
        }
        return
      }
      if {$node != "" && ![isTopItem $node]} {
        addToList $node $node [packImgOpt $imorig $active]
      }
      set img [packImgOpt $img $active]
      addToList $id $txt $img $node $val $typ $contents
      showTree $id
      setNotSaved 1
    }
    return
  }

  ######################################################################
  # update the current item from the entry fields
  # or add a new one if it doesn't exist

  proc changeItem {} {

    bringMeVars
    if {[checkEntries]} {
      if {$Na==""} {
        # changing a parent and children
        lassign [$win.tre1 item [set it [selectionOfTreeView]] -values] und
        if {$und != $underline} {
          if {$verbose} {
            pdlg ok err "ERROR" "Parents aren't changed by their children:()"
          }
          return
        }
        set oldNo [$win.tre1 item $it -text]
        for {set i 0} {$i<[llength $listIt]} {incr i} {
          lassign [lindex $listIt $i] txt val id img node typ cont
          lassign [unpackImgOpt $img] img
          set img [packImgOpt $img $active]
          if {$txt==$oldNo && $node=="" || $node==$oldNo} {
            if {$node==""} {
              # change the group item
              set item [list $No {} $No $img]
            } else {
              # only change the group name of subitem & "active"
              set item [list $txt $val $id $img $No $typ $cont]
            }
            lset listIt $i $item
          }
        }
        set itfocus $No
      } else {
        set idfoc [selectionOfTreeView]
        lassign [findItem $idfoc] i txt - id img node typ contents
        set img [packImgOpt $img $active]
        if {$i > -1} {
          lset listIt $i [list $Na $ID $id $img $node $Typ [getContents]]
        } else {
          if {!$verbose || [pdlg yesno warn "CHANGE" \
              "Not found the $Na $ID.\nAdd anyway?"] == 1} {
            addItem
          }
        }
        set itfocus $ID
      }
      setNotSaved 1
      showTree $itfocus
    }
    return

  }

  ######################################################################
  # delete the current item of treeview

  proc deleteItem {} {

    bringMeVars
    set itd [checkSelection]
    if {$itd!="" && [pdlg yesno warn "DELETE" "Delete the item $itd?" NO]==1} {
      if {[$win.tre1 children $itd]!=""} {
        if {[pdlg yesno warn "DELETE" \
            "The group $itd has children.\nStill want to delete?" NO]!=1} {
          return
        }
      }
      catch {
        set itprev [set itfocus ""]
        set listnew {}
        foreach it $listIt {
          lassign $it txt val id img node
          if {$itd!=$id && $itd!=$node} {
            lappend listnew $it
          } elseif {$itfocus==""} {
            set itfocus $itprev
          }
          set itprev [getID $txt $id]
        }
        set listIt $listnew
        setNotSaved 1
        showTree $itfocus
      }
    }
    return

  }

  ######################################################################
  # test the correctness of Contents field as for EVENT
  # (by simulating its generation)

  proc test1 {contents {where ""}} {

    bringMeVars
    set contents [string map [list $EOL \n] $contents]
    foreach com [split $contents \n]  {
      if {[set ev [getShortcutCommand "EVENT" $com]]!=""} {
        label $win.l
        if {[catch { event generate $win.l $ev } er]} {
          destroy $win.l
          pdlg ok err "ERROR" "\nMistaken EVENT$where:\n$ev\n\n$er\n"
          return 1
        }
        destroy $win.l
      }
    }
    return 0

  }

  ######################################################################
  # test the correctness of current Contents and, after query, all

  proc testItem {} {

    bringMeVars
    if {[test1 [getContents]]} return
    if {$ans_test < 10} {
      set ans_test [pdlg yesno info "TEST" \
        "The current data are OK.\nContinue to test the whole list?" YES -ch $notshow]
      if {$ans_test!=1 && $ans_test!=11} return
    } elseif {$ans_test!=11} {
      pdlg ok info "TEST" "The current data are OK."
      return
    }
    foreach it $listIt {
      lassign $it txt val id img node typ contents
      if {$node!="" && [test1 $contents " in $txt $id"]} {
        return
      }
    }
    pdlg ok info "No errors" "All is OK.
      No EVENT errors were found
      in the whole list."

  }

  ######################################################################
  # check and get the currently selected item of treeview

  proc checkSelection {} {

    bringMeVars
    if {[selectionOfTreeView]==""} {
      catch {$win.tre1 selection set [lindex [$win.tre1 children {}] 0]}
      selectTreeItem
    }
    return [selectionOfTreeView]

  }

  ######################################################################
  # delete all treeview items

  proc deleteTree {} {

    bringMeVars
    foreach it [$win.tre1 children {}] {
      $win.tre1 delete "[escapedID $it]"
    }
    return

  }

  ######################################################################
  # set the focus on the treeview

  proc setFocus {id} {

    bringMeVars
    catch {
      set id [escapedID $id]
      $win.tre1 selection set "$id"
      $win.tre1 focus $id
      $win.tre1 see $id
    }

  }

  ######################################################################
  # sort the item list by group + item

  proc compIt {a b} {

    lassign $a txta - - - nodea
    lassign $b txtb - - - nodeb
    append nodea " "
    append nodeb " "
    return [string compare "$nodea$txta" "$nodeb$txtb"]

  }

  ######################################################################
  # put image attributes and options

  proc packImgOpt {attrs active} {

    lassign [unpackImgOpt $attrs] img
    if {!$adsh::active} {
      append img " $adsh::dodisabled"
    }
    if {$adsh::auto} {
      append img " $adsh::doauto"
    }
    return $img

  }

  ######################################################################
  # get image attributes and options

  proc unpackImgOpt {attrs} {

    bringMeVars
    if {[string first $dodisabled $attrs] > -1} {
      set a $flagDisabled
    } else {
      set a $flagEnabled
    }
    if {[set s [expr {[string first $doauto $attrs] > -1}]]} {
      set sf $flagEnabled
    } else {
      set sf $flagDisabled
    }
    return [list [string map [list $dodisabled "" $doauto ""] $attrs] $a $s $sf]

  }

  ######################################################################
  # process the toggling of "Sort" checkbox

  proc sortToggle {} {

    if {$adsh::sort} {
      showTree
      setNotSaved 1
    }
    return

  }

  ######################################################################
  # process the pressing "+" (expand) and "-" (collapse) of the treeview
  # precess Delete pressing to delete a current item

  proc pressingList {K s} {

    bringMeVars
    if {$K in {"plus" "KP_Add"}} {
      event generate $win.tre1 <KeyPress-Right>
    }
    if {$K in {"minus" "KP_Subtract"}} {
      event generate $win.tre1 <KeyPress-Left>
    }
    if {"$K" == "Delete"} {
      $win.fra.but$K invoke
      after 50 "focus $win.fra.butTest
        event generate $win.fra.butTest <Tab>"
    }

  }

  ######################################################################
  # process the confirming keys (Enter, Tab)
  # while for other keys - set the ID value

  proc pressingConfirm {K k s} {

    bringMeVars
    if {$k in {119 22} } {
      set ID ""
      $win.entID selection range 0 end
    } elseif {"$k"!="23"} {  ;# ignore Tab pressing
      set ID "$K/$k/$s"
      $win.entID selection range 0 end
    }
    return

  }

  ######################################################################
  # if Tab pressed on the Contents, select a next field

  proc tabPressOnText {K} {

    if {$K=="Tab"} {
      focus $adsh::win.chbActive
      return -code break
    }
    return

  }

  ######################################################################
  # show the tree items (and remove erroneous ones if there are)

  proc showTree {{itfocus ""}} {

    bringMeVars
    deleteTree
    if {$sort} {
      set listIt [lsort -dict -command compIt $listIt]
    }
    for {set i 0} {$i<[llength $listIt]} {incr i} {
      lassign [lindex $listIt $i] txt val id img node
      lassign [unpackImgOpt $img] img act - sf
      if {[catch {
          if {$node==""} {
            $win.tre1 insert {} end -id $id -text $txt {*}$img \
              -values [list $underline $act $sf]
          } else {
            $win.tre1 insert $node end -id $id -text $txt -values [list $val $act $sf] {*}$img
        }} e]} {
        pdlg ok err "ERROR" \
          "\nError of tree:\nnode=$node\nid=$id\ntxt=$txt\nval=$val\n\n$e\n" -text 1
        set listIt [lreplace $listIt $i $i]
      } elseif {$itfocus!=""} {
        if { ($node=="" && $No==$txt && $Na=="" && $ID=="") \
              || ($node!="" && $No==$node && $Na==$txt && $ID==$val) } {
          set itfocus $id
        }
      }
    }
    catch {setFocus $itfocus; selectTreeItem}
    checkSelection
    return

  }

  ######################################################################
  # append a new item to the end of item list

  proc addToList {id txt img {node ""} {val ""} {typ ""} {contents ""}} {

    lappend adsh::listIt [list $txt $val $id $img $node $typ $contents]
    return

  }

  ######################################################################
  # create new list of treeview items

  proc populateTree {} {

    bringMeVars
    foreach icon {orig add} {
      image create photo img$icon \
        -file [file join $adsh::pavedir sc$icon.png]
    }
    set listIt [list]
    set imorig "-image imgorig -open 1 -tag Orig"
    set imadd "-image imgadd -tag Add"
    # if no saved data, create some items (supposing we are Russians:)
    if {![getsetini getIni $inifile]} {
      addToList "<<Copy>>" "<<Copy>>" $imorig
      addToList "c/54/8196" Ctrl+Cyr_c $imadd "<<Copy>>" "c/54/8196" \
        "EVENT" "EVENT = <<Copy>>"
      addToList <<Cut>> "<<Cut>>" $imorig
      addToList "x/53/8196" Ctrl+Cyr_x $imadd "<<Cut>>" "x/53/8196" \
        "EVENT" "EVENT = <<Cut>>"
      addToList <<Paste>> "<<Paste>>" $imorig
      addToList "v/53/8196" Ctrl+Cyr_v $imadd "<<Paste>>" "v/53/8196" \
        "EVENT" "EVENT = <<Paste>>"
    }
    set listBak $listIt
    showTree
    $win.tre1 heading #0 -text "Name" -anchor center
    $win.tre1 heading #1 -text "ID" -anchor center
    $win.tre1 heading #2 -text "A" -anchor center
    $win.tre1 heading #3 -text "S" -anchor center
    $win.tre1 column #0 -width 200
    $win.tre1 column #1 -width 200
    $win.tre1 column #2 -width 32 -anchor center
    $win.tre1 column #3 -width 32 -anchor center
    $win.tre1 tag configure Orig -font "-family Times -size 12"
    $win.tre1 tag configure Add -font "-family Helvetica -size 10"
    checkSelection
    return

  }

  ######################################################################
  # initialize data for the dialog

  proc initDialog {} {

    bringMeVars
    GetSetIni create getsetini
    lassign $::argv version ini adsh::fg adsh::bg adsh::fg2 adsh::bg2 \
      adsh::fgS adsh::bgS adsh::cc
    if {$ini!=""} {
      set adsh::inifile $ini
    }

  }

  ######################################################################
  # layout the dialog and bind the events to its fields

  proc makeDialog {} {

    bringMeVars
    oo::define PaveMe {mixin ObjectTheming}
    PaveDialog create pdlg $Win
    pdlg makeWindow $win "Adding Shortcuts $version - $inifile"

    set fontbold "-font \"-family TkCaptionFont\" -foreground $fgColor -background $bgColor"
    pdlg window $win {
      {frAU - - 1 6   {-st new} {-relief groove -borderwidth 1}}
      {frAU.v_00 - - 1 1}
      {frAU.laB0 frAU.v_00 T 1 1 - {-t "This TKE plugin allows you to create the shortcuts bound to existing ones. Thus you can enable localized shortcuts."}}
      {frAU.laB1 frAU.laB0 T 1 1 - {-t "You can also make a miscellany that contains: event handler(s), menu invoker(s), command caller(s)."}}
      {frAU.laB2 frAU.laB1 T 1 1 - {-t "Press the shortcut in the ID field. Confirm your choice by pressing Enter / Return key."}}
      {frAU.v_0 frAU.laB2 T 1 1}
      {v_0 frAU T 1 6}
      {laB1 v_0 T 1 2 - {-t " Group info " $fontbold}}
      {laB2 laB1 T 1 1 {-st e} {-t "Name:"}}
      {entOrig laB2 L 1 1 {-st we -padx 5 -cw 3} {-tvar adsh::No}}
      {v_1 laB2 T 1 2}
      {laB3 v_1 T 1 1 - {-t " Shortcut info " $fontbold}}
      {laB4 laB3 T 1 1 {-st e} {-t "Name:"}}
      {entName laB4 L 1 1 {-st we -padx 5} {-tvar adsh::Na}}
      {laB5 laB4 T 1 1 {-st e} {-t "Shortcut ID:"}}
      {entID laB5 L 1 1 {-st we -padx 5} {-tvar adsh::ID -state readonly}}
      {v_2 laB5 T 1 1 {-pady 8}}
      {laB12 v_2 T 1 1 {-st e} {-t "Type:"}}
      {cbxTyp laB12 L 1 1 {-st w -padx 5 -cw 3} {-tvar adsh::Typ -width 10 -values {$typs} -state readonly}}
      {laB52 laB12 T 1 1 {-st en -rw 1} {-t "Contents:"}}
      {fraComm laB52 L 1 1 {-st nswe -padx 5} {}}
      {texComm - - 1 1 {pack -side left -expand 1 -fill both -in $win.fraComm} {-h 6 -w 50 -wrap word}}
      {sbvComm texComm L 1 1 {pack -in $win.fraComm}}
      {laB53 laB52 T 1 1 {-st en -rw 1} {-t "Description:"}}
      {fraDesc laB53 L 1 1 {-st nswe -padx 5} {}}
      {texDesc - - 1 1 {pack -side left -expand 1 -fill both -in $win.fraDesc} {-h 8 -w 50 -state disabled -wrap word -fg black -bg #d9d9d9}}
      {sbvDesc texDesc L 1 1 {pack -in $win.fraDesc}}
      {v_3 laB53 T 1 2}
      {laBSort v_3 T 1 1 - {-t " Options " $fontbold}}
      {frAOpt laBSort L 1 1 {-st nsew}}
      {chbActive - - 1 1 {-in $win.frAOpt} {-t " Active " -var adsh::active}}
      {chbAuto chbActive L 1 1 {-in $win.frAOpt} {-t " AutoStart " -var adsh::auto}}
      {chbSort chbAuto L 1 1 {-in $win.frAOpt} {-t " Sorted list " -var adsh::sort -com adsh::sortToggle}}
      {v_4 laBSort T 1 2 {-rsz 10} {}}
      {fra v_4 T 1 2 {-st e -padx 5} {-relief groove -borderwidth 1}}
      {fra.butInsert - - 1 1 {-st w} {-t "Add" -com adsh::addItem}}
      {fra.butChange fra.butInsert L 1 1 {-st w} {-t "Change" -com adsh::changeItem}}
      {fra.butDelete fra.butChange L 1 1 {-st w} {-t "Delete" -com adsh::deleteItem}}
      {fra.h_ fra.butDelete L 1 1 {-padx 10}}
      {fra.butTest fra.h_ L 1 1 {-st w} {-t "Test" -com adsh::testItem}}
      {fraTr laB1 L 14 3 {-st nsew}}
      {tre1 - - 1 1 {pack -side left -in $win.fraTr -expand 1  -fill both} {-columns "ID A S"}}
      {sbv tre1 L 1 1 {pack -in $win.fraTr}}
      {v__u fra T 1 6}
      {seh v__u T 1 6}
      {laBMess seh T 1 2 {-st w} "-foreground $adsh::cc -font \"-weight bold\""}
      {laBh_1 laBMess L 1 1 {-cw 1}}
      {fra2 laBh_1 L}
      {fra2.butApply - - 1 1 {} {-t "Apply" -com "adsh::doApply"}}
      {fra2.butOK fra2.butApply L 1 1 {} {-t "Save" -com "adsh::doSaveExit"}}
      {fra2.butCancel fra2.butOK L 1 1 {} {-t "Exit" -com "adsh::doExit"}}
    }
    pdlg themingWindow $win $fg $bg $fg2 $bg2 $fgS $bgS grey $bg2 $cc $cc
    return

  }

  ######################################################################
  # show the dialog with saved geometry

  proc runDialog {} {

    bringMeVars
    populateTree
    setNotSaved 0
    foreach l {frAU frAU.laB0 frAU.laB1 frAU.laB2 frAU.v_00 frAU.v_0 laB1 laB3 laBSort} {
      if {$fg != "" && [catch {$win.$l config -fg $fg; set fgOK 1}]} {}
      if {$bg != "" && [catch {$win.$l config -bg $bg; set bgOK 1}]} {}
    }
    if {[info exists fgOK] && [info exists bgOK]} {
      lset textTags 2 1 "-foreground $fg -background $bg"
    }
    catch { $win.tre1 focus [adsh::checkSelection] }
    bind $win.texComm <KeyPress> {adsh::tabPressOnText %K}
    bind $win.tre1 "<Enter>" {adsh::setFocus [adsh::checkSelection]}
    bind $win.tre1 "<<TreeviewSelect>>" {adsh::selectTreeItem}
    bind $win.tre1 "<KeyPress>" {adsh::pressingList %K %s}
    bind $win.entID "<KeyPress>" {adsh::pressingConfirm "%K" "%k" "%s"}
    bind $win.cbxTyp "<<ComboboxSelected>> " {adsh::selectingCombo}
    bind $win.chbActive "<Enter> " {adsh::doHint "Enables the current item."}
    bind $win.chbAuto "<Enter> " {adsh::doHint "Starts the item with TKE."}
    bind $win.chbSort "<Enter> " {adsh::doHint "Makes the item list sorted."}
    bind $win.fra.butInsert "<Enter> " {adsh::doHint "Inserts the new item."}
    bind $win.fra.butChange "<Enter> " {adsh::doHint "Changes the current item."}
    bind $win.fra.butDelete "<Enter> " {adsh::doHint "Deletes the item and its children."}
    bind $win.fra.butTest "<Enter> " {adsh::doHint "Tests if the EVENTs are correct."}
    if {$geometry==""} {
      set geometry +300+200
    }
    if {$lastid!=""} {
      setFocus $lastid
    }
    pdlg showModal $Win -focus $win.entOrig -onclose adsh::doExit -geometry $geometry -decor 1
    return

  }

  ######################################################################
  # after closing the dialog save its data if "Save" was choosen

  proc destroyDialog {} {

    bringMeVars
    set res [pdlg res $Win]
    if {$res} {
      saveData
    }
    PaveDialog destroy
    GetSetIni destroy
    return [expr max($wassaved,$res)]

  }

}

######################################################################
# main program, huh

if {$::tcl_platform(platform) == "windows"} {
  wm attributes . -alpha 0.0
} else {
  wm attributes . -type splash
  wm geometry . 0x0
}
ttk::style theme use clam
adsh::initDialog
adsh::makeDialog
adsh::runDialog
set res [adsh::destroyDialog]
exit $res

############################### EOF ##################################

