###########################################################################
#     icon title message (optional checkbox message) (optional geometry) \
#                   (optional -text 1)
package require Tk
source [file join [file dirname [info script]] apave.tcl]
namespace eval ::apave {}
oo::class create ::apave::APaveDialog {superclass ::apave::APave
variable _pdg
constructor {{win ""} args} {array set _pdg {}
set _pdg(win) $win
set _pdg(ns) [namespace current]::
namespace eval ${_pdg(ns)}PD {}
proc exitEditor {resExit} {upvar $resExit res
if {[[my TexM] edit modified]} {set w [set [namespace current]::_pdg(win)]
set pdlg [::apave::APaveDialog new $w.dia]
set r [$pdlg misc warn "Save text?" "\n Save changes made to the text? \n" {Save 1 "Don't save " Close Cancel 0} 1 -focusback [my TexM] -centerme $w]
if {$r==1} {set res 1
} elseif {$r eq "Close"} {set res 0}
$pdlg destroy
} else {set res 0}
return}
if {[llength [self next]]} { next {*}$args }}
destructor {catch {namespace delete ${_pdg(ns)}PD}
array unset _pdg
if {[llength [self next]]} next}
method PrepArgs {args} {foreach a $args { lappend res $a }
return $res}
method ok {icon ttl msg args} {return [my Query $icon $ttl $msg {ButOK OK 1} ButOK {} [my PrepArgs $args]]}
method okcancel {icon ttl msg {defb OK} args} {return [my Query $icon $ttl $msg {ButOK OK 1 ButCANCEL Cancel 0} But$defb {} [my PrepArgs $args]]}
method yesno {icon ttl msg {defb YES} args} {return [my Query $icon $ttl $msg {ButYES Yes 1 ButNO No 0} But$defb {} [my PrepArgs $args]]}
method yesnocancel {icon ttl msg {defb YES} args} {return [my Query $icon $ttl $msg {ButYES Yes 1 ButNO No 2 ButCANCEL Cancel 0} But$defb {} [my PrepArgs $args]]}
method retrycancel {icon ttl msg {defb RETRY} args} {return [my Query $icon $ttl $msg {ButRETRY Retry 1 ButCANCEL Cancel 0} But$defb {} [my PrepArgs $args]]}
method abortretrycancel {icon ttl msg {defb RETRY} args} {return [my Query $icon $ttl $msg {ButABORT Abort 1 ButRETRY Retry 2 ButCANCEL Cancel 0} But$defb {} [my PrepArgs $args]]}
method misc {icon ttl msg butts {defb ""} args} {foreach {nam num} $butts {lappend apave_msc_bttns But$num "$nam" $num
if {$defb eq ""} {set defb $num}}
return [my Query $icon $ttl $msg $apave_msc_bttns But$defb {} [my PrepArgs $args]]}
method Pdg {name} {return $_pdg($name)}
method FieldName {name} {return fraM.fra$name.$name}
method VarName {name} {return [namespace current]::var$name}
method GetVarsValues {lwidgets} {set res [set vars [list]]
foreach wl $lwidgets {set vv [my VarName [my ownWName [lindex $wl 0]]]
set attrs [lindex $wl 6]
foreach t {-var -tvar} {if {[set p [string first "$t " $attrs]]>-1} {array set a $attrs
set vv $a($t)}}
if {[info exist $vv] && [lsearch $vars $vv]==-1} {lappend res [set $vv]
lappend vars $vv}}
return $res}
method SetGetTexts {oper w iopts lwidgets} {if {$iopts eq ""} return
foreach widg $lwidgets {set wname [lindex $widg 0]
set name [my ownWName $wname]
if {[string range $name 0 1] eq "te"} {set vv [my VarName $name]
if {$oper eq "set"} {my displayText $w.$wname [set $vv]
} else {set $vv [string trimright [$w.$wname get 1.0 end]]}}}
return}
method AppendButtons {widlistName buttons neighbor pos defb timeout} {upvar $widlistName widlist
set defb1 [set defb2 ""]
foreach {but txt res} $buttons {if {$defb1 eq ""} {set defb1 $but
} elseif {$defb2 eq ""} {set defb2 $but}
if {[set _ [string first "::" $txt]]>-1} {set tt " -tooltip {[string range $txt $_+2 end]}"
set txt [string range $txt 0 $_-1]
} else {set tt ""}
if {$timeout ne "" && ($defb eq $but || $defb eq "")} {set tmo "-timeout {$timeout}"
} else {set tmo ""}
lappend widlist [list $but $neighbor $pos 1 1 "-st we" "-t \"$txt\" -com \"${_pdg(ns)}my res $_pdg(win).dia $res\"$tt $tmo"]
set neighbor $but
set pos L}
lassign [my LowercaseWidgetName $_pdg(win).dia.fra.$defb1] _pdg(defb1)
lassign [my LowercaseWidgetName $_pdg(win).dia.fra.$defb2] _pdg(defb2)
return}
method GetLinePosition {txt ind} {set linestart [$txt index "$ind linestart"]
set lineend   [expr {$linestart + 1.0}]
return [list $linestart $lineend]}
method pasteText {} {set txt [my TexM]
set err [catch {$txt tag ranges sel} sel]
if {!$err && [llength $sel]==2} {lassign $sel pos pos2
$txt delete $pos $pos2}}
method doubleText {{dobreak 1}} {set txt [my TexM]
set err [catch {$txt tag ranges sel} sel]
if {!$err && [llength $sel]==2} {lassign $sel pos pos2
set pos3 "insert"
} else {lassign [my GetLinePosition $txt insert] pos pos2
set pos3 $pos2}
set duptext [$txt get $pos $pos2]
$txt insert $pos3 $duptext
if {$dobreak} {return -code break}
return}
method deleteLine {{dobreak 1}} {set txt [my TexM]
lassign [my GetLinePosition $txt insert] linestart lineend
$txt delete $linestart $lineend
if {$dobreak} {return -code break}
return}
method linesMove {to {dobreak 1}} {proc NewRow {ind rn} {set i [string first . $ind]
set row [string range $ind 0 $i-1]
return [incr row $rn][string range $ind $i end]}
set txt [my TexM]
set err [catch {$txt tag ranges sel} sel]
lassign [$txt index insert] pos
if {[set issel [expr {!$err && [llength $sel]==2}]]} {lassign $sel pos1 pos2
set l1 [expr {int($pos1)}]
set l2 [expr {int($pos2)}]
set lfrom [expr {$to>0 ? $l2+1 : $l1-1}]
set lto   [expr {$to>0 ? $l1-1 : $l2-1}]
} else {set lcurr [expr {int($pos)}]
set lfrom [expr {$to>0 ? $lcurr+1 : $lcurr-1}]
set lto   [expr {$to>0 ? $lcurr-1 : $lcurr-1}]}
set lend [expr {int([$txt index end])}]
if {$lfrom>0 && $lfrom<$lend} {incr lto
lassign [my GetLinePosition $txt $lfrom.0] linestart lineend
set duptext [$txt get $linestart $lineend]
$txt delete $linestart $lineend
$txt insert $lto.0 $duptext
::tk::TextSetCursor $txt [NewRow $pos $to]
if {$issel} {$txt tag add sel [NewRow $pos1 $to] [NewRow $pos2 $to]}
if {$dobreak} {return -code break}}
return}
method InitFindInText { {ctrlf 0} } {set txt [my TexM]
if {$ctrlf} {::tk::TextSetCursor $txt [$txt index "insert -1 char"]}
set seltxt ""
set selected [catch {$txt tag ranges sel} seltxt]
if {[set ${_pdg(ns)}PD::fnd] eq "" || $seltxt ne ""} {if {!$selected} {if {[set forword [expr {$seltxt eq ""}]]} {set pos  [$txt index "insert wordstart"]
set pos2 [$txt index "insert wordend"]
set seltxt [string trim [$txt get $pos $pos2]]
if {![string is wordchar -strict $seltxt]} {set pos  [$txt index "insert -1 char wordstart"]
set pos2 [$txt index "insert -1 char wordend"]}
} else {lassign $seltxt pos pos2}
catch {set seltxt [$txt get $pos $pos2]
if {[set sttrim [string trim $seltxt]] ne ""} {if {$forword} {set seltxt $sttrim}
set ${_pdg(ns)}PD::fnd $seltxt}}}}
return}
method FindInText {{donext 0}} {set txt [my TexM]
set sel [set ${_pdg(ns)}PD::fnd]
if {$donext} {set pos [$txt index "[$txt index insert] + 1 chars"]
set pos [$txt search -- $sel $pos end]
} else {set pos ""}
if {![string length "$pos"]} {set pos [$txt search -- $sel 1.0 end]}
if {[string length "$pos"]} {::tk::TextSetCursor $txt $pos
$txt tag add sel $pos [$txt index "$pos + [string length $sel] chars"]
focus $txt
} else {bell -nice}
return}
method Query {icon ttl msg buttons defb inopts argdia {precom ""} args} {if {[winfo exists $_pdg(win).dia]} {puts "$_pdg(win).dia already exists: select other root window"
return 0}
set focusback [focus]
set focusmatch ""
lassign "" chmsg geometry optsLabel optsMisc optsFont optsFontM rotext root head optsHead hsz binds postcom onclose timeout
set tags ""
set wasgeo [set textmode [set ontop 0]]
set cc [set themecolors [set optsGrid ""]]
set readonly [set hidefind 1]
set curpos "1.0"
set ${_pdg(ns)}PD::ch 0
foreach {opt val} {*}$argdia {if {$opt in {-c -color -fg -bg -fgS -bgS -cc -hfg -hbg}} {if {[info exist $val]} {set val [set $val]}}
switch -- $opt {-H - -head {set head [string map {$ \$ \" \'\'} $val]}
-ch - -checkbox {set chmsg "$val"}
-g - -geometry {set geometry $val
set wasgeo 1
lassign [split $geometry +] - gx gy}
-c - -color {append optsLabel " -foreground {$val}"}
-a {append optsGrid " $val" }
-centerme {lappend args -centerme $val}
-t - -text {set textmode $val}
-tags {upvar 2 $val _tags
set tags $_tags}
-ro - -readonly {set readonly [set hidefind $val]}
-rotext {set hidefind 0; set rotext $val}
-w - -width {set charwidth $val}
-h - -height {set charheight $val}
-fg {append optsMisc " -foreground {$val}"}
-bg {append optsMisc " -background {$val}"}
-fgS {append optsMisc " -selectforeground {$val}"}
-bgS {append optsMisc " -selectbackground {$val}"}
-cc {append optsMisc " -insertbackground {$val}"}
-myown {append optsMisc " -myown {$val}"}
-root {set root " -root $val"}
-pos {set curpos "$val"}
-hfg {append optsHead " -foreground {$val}"}
-hbg {append optsHead " -background {$val}"}
-hsz {append hsz " -size $val"}
-focus {set focusmatch "$val"}
-theme {append themecolors " {$val}"}
-ontop {set ontop 1}
-post {set postcom $val}
-focusback {set focusback $val}
-timeout {set timeout $val}
default {append optsFont " $opt $val"
if {$opt ne "-family"} {append optsFontM " $opt $val"}}}}
set optsFont [string trim $optsFont]
set optsHeadFont $optsFont
set fs [my basicFontSize]
set textfont "-font \"-family {[my basicTextFont]}"
if {$optsFont ne ""} {if {[string first "-size " $optsFont]<0} {append optsFont " -size $fs"}
if {[string first "-size " $optsFontM]<0} {append optsFontM " -size $fs"}
if {[string first "-family " $optsFont]>=0} {set optsFont "-font \"$optsFont"
} else {set optsFont "-font \"-family Helvetica $optsFont"}
set optsFontM "$textfont $optsFontM\""
append optsFont "\""
} else {set optsFont "-font \"-size $fs\""
set optsFontM "$textfont -size $fs\""}
if {$icon ni {"" "-"}} {set widlist [list [list labBimg - - 99 1 "-st n -pady 7" "-image [::apave::iconImage $icon]"]]
set prevl labBimg
} else {set widlist [list [list labimg - - 99 1]]
set prevl labimg}
set prevw labBimg
if {$head ne ""} {if {$optsHeadFont ne "" || $hsz ne ""} {set optsHeadFont [string trim "$optsHeadFont $hsz"]
set optsHeadFont "-font \"$optsHeadFont\""}
set optsFont ""
set prevp "L"
set head [string map {\\n \n} $head]
foreach lh [split $head "\n"] {set labh "labheading[incr il]"
lappend widlist [list $labh $prevw $prevp 1 99 "-st we" "-t \"$lh\" $optsHeadFont $optsHead"]
set prevw [set prevh $labh]
set prevp "T"}
} else {lappend widlist [list h_1 $prevw L 1 1 "-pady 3"]
set prevw [set prevh h_1]
set prevp "T"}
set il [set maxw 0]
if {$readonly} {set msg [string map {\\n \n} $msg]}
foreach m [split $msg \n] {set m [string map {$ \$ \" \'\'} $m]
if {[set mw [string length $m]] > $maxw} {set maxw $mw}
incr il
if {!$textmode} {lappend widlist [list Lab$il $prevw $prevp 1 7 "-st w -rw 1 $optsGrid" "-t \"$m \" $optsLabel $optsFont"]}
set prevw Lab$il
set prevp T}
if {$inopts ne ""} {set io0 [lindex $inopts 0]
lset io0 1 $prevh
lset inopts 0 $io0
foreach io $inopts {lappend widlist $io}
set prevw fraM
} elseif {$textmode} {proc vallimits {val lowlimit isset limits} {set val [expr {max($val,$lowlimit)}]
if {$isset} {upvar $limits lim
lassign $lim l1 l2
set val [expr {min($val,$l1)}]
if {$l2 ne ""} {set val [expr {max($val,$l2)}]}}
return $val}
set il [vallimits $il 1 [info exists charheight] charheight]
incr maxw
set maxw [vallimits $maxw 20 [info exists charwidth] charwidth]
rename vallimits ""
lappend widlist [list fraM $prevh T 10 7 "-st nswe -pady 3 -rw 1"]
lappend widlist [list TexM - - 1 7 {pack -side left -expand 1 -fill both -in $_pdg(win).dia.fra.fraM} [list -h $il -w $maxw {*}$optsFontM {*}$optsMisc -wrap word -textpop 0 -tabnext $_pdg(win).dia.fra.[lindex $buttons 0]]]
lappend widlist {sbv texM L 1 1 {pack -in $_pdg(win).dia.fra.fraM}}
set prevw fraM}
lappend widlist [list h_2 $prevw T 1 1 "-pady 0 -ipady 0 -csz 0"]
lappend widlist [list seh $prevl T 1 99 "-st ew"]
lappend widlist [list h_3 seh T 1 1 "-pady 0 -ipady 0 -csz 0"]
if {$textmode} {set wt "\[[self] TexM\]"
set binds "set pop $wt.popupMenu
        bind $wt <Button-3> \{[self] themePopup $wt.popupMenu; tk_popup $wt.popupMenu %X %Y \}"
if {$readonly || $hidefind || $chmsg ne ""} {append binds "
          menu \$pop
           \$pop add command [my IconA copy] -accelerator Ctrl+C -label \"Copy\" \            -command \"event generate $wt <<Copy>>\""
if {$hidefind || $chmsg ne ""} {append binds "
            \$pop configure -tearoff 0
            \$pop add separator
            \$pop add command [my IconA none] -accelerator Ctrl+A \            -label \"Select All\" -command \"$wt tag add sel 1.0 end\"
             bind $wt <Control-a> \"$wt tag add sel 1.0 end; break\""}}}
if {$chmsg eq ""} {if {$textmode} {if {![info exists ${_pdg(ns)}PD::fnd]} {set ${_pdg(ns)}PD::fnd ""}
set noIMG "[my IconA none]"
if {$hidefind} {lappend widlist [list h__ h_3 L 1 4 "-cw 1"]
} else {lappend widlist [list labfnd h_3 L 1 1 "-st e" "-t {Find:}"]
lappend widlist [list Entfind labfnd L 1 1 "-st ew -cw 1" "-tvar ${_pdg(ns)}PD::fnd -w 10"]
lappend widlist [list labfnd2 Entfind L 1 1 "-cw 2" "-t {}"]
lappend widlist [list h__ labfnd2 L 1 1]
append binds "
            bind \[[self] Entfind\] <Return> {[self] FindInText}
            bind \[[self] Entfind\] <KP_Enter> {[self] FindInText}
            bind \[[self] Entfind\] <FocusIn> {\[[self] Entfind\] selection range 0 end}
            bind $_pdg(win).dia <F3> {[self] FindInText 1}
            bind $_pdg(win).dia <Control-f> \"[self] InitFindInText 1; focus \[[self] Entfind\]; break\"
            bind $_pdg(win).dia <Control-F> \"[self] InitFindInText 1; focus \[[self] Entfind\]; break\""}
if {$readonly} {if {!$hidefind} {append binds "
             \$pop add separator
             \$pop add command [my IconA find] -accelerator Ctrl+F -label \             \"Find first\" -command \"[self] InitFindInText; focus \[[self] Entfind\]\"
             \$pop add command $noIMG -accelerator F3 -label \"Find next\" \              -command \"[self] FindInText 1\"
             \$pop add separator
             \$pop add command [my IconA exit] -accelerator Esc -label \"Exit\" \              -command \"\[[self] Pdg defb1\] invoke\"
            "}
} else {append binds "
            bind $wt <<Paste>> {+ [self] pasteText}
            bind $wt <Control-d> {[self] doubleText}
            bind $wt <Control-D> {[self] doubleText}
            bind $wt <Control-y> {[self] deleteLine}
            bind $wt <Control-Y> {[self] deleteLine}
            bind $wt <Alt-Up>    {[self] linesMove -1}
            bind $wt <Alt-Down>  {[self] linesMove +1}
            menu \$pop
             \$pop add command [my IconA cut] -accelerator Ctrl+X -label \"Cut\" \              -command \"event generate $wt <<Cut>>\"
             \$pop add command [my IconA copy] -accelerator Ctrl+C -label \"Copy\" \              -command \"event generate $wt <<Copy>>\"
             \$pop add command [my IconA paste] -accelerator Ctrl+V -label \"Paste\" \              -command \"event generate $wt <<Paste>>\"
             \$pop add separator
             \$pop add command [my IconA double] -accelerator Ctrl+D -label \"Double selection\" \              -command \"[self] doubleText 0\"
             \$pop add command [my IconA delete] -accelerator Ctrl+Y -label \"Delete line\" \              -command \"[self] deleteLine 0\"
             \$pop add command [my IconA up] -accelerator Alt+Up -label \"Line(s) up\" \              -command \"[self] linesMove -1 0\"
             \$pop add command [my IconA down] -accelerator Alt+Down -label \"Line(s) down\" \              -command \"[self] linesMove +1 0\"
             \$pop add separator
             \$pop add command [my IconA find] -accelerator Ctrl+F -label \"Find first\" \              -command \"[self] InitFindInText; focus \[[self] Entfind\]\"
             \$pop add command $noIMG -accelerator F3 -label \"Find next\" \              -command \"[self] FindInText 1\"
             \$pop add separator
             \$pop add command [my IconA SaveFile] -accelerator Ctrl+W \             -label \"Save and exit\" -command \"\[[self] Pdg defb1\] invoke\"
            "}
lappend args -onclose [namespace current]::exitEditor
oo::objdefine [self] export FindInText InitFindInText Pdg
} else {lappend widlist [list h__ h_3 L 1 4 "-cw 1"]}
} else {lappend widlist [list chb h_3 L 1 1 "-st w" "-t {$chmsg} -var ${_pdg(ns)}PD::ch"]
lappend widlist [list h_ chb L 1 1]
lappend widlist [list sev h_ L 1 1 "-st nse -cw 1"]
lappend widlist [list h__ sev L 1 1]}
my AppendButtons widlist $buttons h__ L $defb $timeout
set wtop [my makeWindow $_pdg(win).dia.fra $ttl]
set widlist [my paveWindow $_pdg(win).dia.fra $widlist]
if {$precom ne ""} {{*}$precom}
if {$themecolors ne ""} {if {[llength $themecolors]==2} {lassign [::apave::parseOptions $optsMisc -foreground black -background white -selectforeground black -selectbackground gray -insertbackground black] v0 v1 v2 v3 v4
lappend themecolors $v0 $v1 $v2 $v3 $v3 $v1 $v4 $v4 $v3 $v2 $v3 $v0 $v1}
catch {my themeWindow $_pdg(win).dia {*}$themecolors false}}
my SetGetTexts set $_pdg(win).dia.fra $inopts $widlist
lassign [my LowercaseWidgetName $_pdg(win).dia.fra.$defb] focusnow
if {$textmode} {my displayTaggedText [my TexM] msg $tags
if {$defb eq "ButTEXT"} {if {$readonly} {lassign [my LowercaseWidgetName [my Pdg defb1]] focusnow
} else {set focusnow [my TexM]
catch "::tk::TextSetCursor $focusnow $curpos"
foreach k {w W} {catch "bind $focusnow <Control-$k> {[my Pdg defb1] invoke; break}"}}}
if {$readonly} {my readonlyWidget ::[my TexM] true false}}
if {$focusmatch ne ""} {foreach w $widlist {lassign $w widname
lassign [my LowercaseWidgetName $widname] wn rn
if {[string match $focusmatch $rn]} {lassign [my LowercaseWidgetName $_pdg(win).dia.fra.$wn] focusnow
break}}}
catch "$binds"
set args [::apave::removeOptions $args -focus]
my showModal $_pdg(win).dia -themed [string length $themecolors] -focus $focusnow -geometry $geometry {*}$root -ontop $ontop {*}$args
oo::objdefine [self] unexport FindInText InitFindInText Pdg
set pdgeometry [winfo geometry $_pdg(win).dia]
set res [set result [my res $_pdg(win).dia]]
set chv [set ${_pdg(ns)}PD::ch]
if { [string is integer $res] } {if {$res && $chv} { incr result 10 }
} else {set res [expr {$result ne "" ? 1 : 0}]
if {$res && $chv} { append result 10 }}
if {$textmode && !$readonly} {set focusnow [my TexM]
set textcont [$focusnow get 1.0 end]
if {$res && $postcom ne ""} {{*}$postcom textcont [my TexM]}
set textcont " [$focusnow index insert] $textcont"
} else {set textcont ""}
if {$res && $inopts ne ""} {my SetGetTexts get $_pdg(win).dia.fra $inopts $widlist
set inopts " [my GetVarsValues $widlist]"
} else {set inopts ""}
if {$textmode && $rotext ne ""} {set $rotext [string trimright [[my TexM] get 1.0 end]]}
destroy $_pdg(win).dia
update
if {$focusback ne "" && [winfo exists $focusback]} {set w ".[lindex [split $focusback .] 1]"
after 50 [list if "\[winfo exist $focusback\]" "focus -force $focusback" elseif "\[winfo exist $w\]" "focus $w"]
} else {after 50 list focus .}
if {$wasgeo} {lassign [split $pdgeometry x+] w h x y
if {abs($x-$gx)<30} {set x $gx}
if {abs($y-$gy)<30} {set y $gy}
return [list $result ${w}x${h}+${x}+${y} $textcont [string trim $inopts]]}
return "$result$textcont$inopts"}}
#by trimmer
