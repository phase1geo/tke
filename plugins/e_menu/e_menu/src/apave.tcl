###########################################################################
package require Tk
namespace eval ::apave {;
variable _Defaults [dict create "bts" {{} {}} "but" {{} {}} "buT" {{} {-width -20 -pady 1}} "can" {{} {}} "chb" {{} {}} "chB" {{} {-relief sunken -padx 6 -pady 2}} "cbx" {{} {}} "fco" {{} {}} "ent" {{} {}} "enT" {{} {-insertwidth 0.6m}} "fil" {{} {}} "fis" {{} {}} "dir" {{} {}} "fon" {{} {}} "clr" {{} {}} "dat" {{} {}} "sta" {{} {}} "too" {{} {}} "fra" {{} {}} "ftx" {{} {}} "frA" {{} {}} "lab" {{-sticky w} {}} "laB" {{-sticky w} {}} "lfr" {{} {}} "lfR" {{} {-relief groove}} "lbx" {{} {}} "flb" {{} {}} "meb" {{} {}} "meB" {{} {}} "nbk" {{} {}} "opc" {{} {}} "pan" {{} {}} "pro" {{} {}} "rad" {{} {}} "raD" {{} {-padx 6 -pady 2}} "sca" {{} {-orient horizontal}} "scA" {{} {-orient horizontal}} "sbh" {{-sticky ew} {-orient horizontal -takefocus 0}} "sbH" {{-sticky ew} {-orient horizontal -takefocus 0}} "sbv" {{-sticky ns} {-orient vertical -takefocus 0}} "sbV" {{-sticky ns} {-orient vertical -takefocus 0}} "seh" {{-sticky ew} {-orient horizontal}} "sev" {{-sticky ns} {-orient vertical}} "siz" {{} {}} "spx" {{} {}} "spX" {{} {}} "tbl" {{} {-selectborderwidth 1 -highlightthickness 2 -labelcommand tablelist::sortByColumn -stretch all -showseparators 1}} "tex" {{} {-undo 1 -maxundo 0 -highlightthickness 2 -insertwidth 0.6m}} "tre" {{} {}} "h_" {{-sticky ew -csz 3 -padx 3} {}} "v_" {{-sticky ns -rsz 3 -pady 3} {}}]
variable apaveDir [file dirname [info script]]
variable _AP_ICO { none folder OpenFile SaveFile font color date help home \
    undo redo run tools file find search replace view edit config misc \
    cut copy paste plus minus add change delete double up down info \
err warn ques no retry ok yes cancel exit }
variable _AP_IMG;  array set _AP_IMG [list]
variable _AP_VARS; array set _AP_VARS [list]
set _AP_VARS(.,SHADOW) 0
set _AP_VARS(.,MODALS) 0
set _AP_VARS(TIMW) [list]
set _AP_VARS(LINKFONT) [list -underline 1]
variable _AP_VISITED;  array set _AP_VISITED [list]
set _AP_VISITED(ALL) [list]
variable UFF "\uFFFF"
proc WindowStatus {w name {val ""} {defval ""}} {variable _AP_VARS
if {$val eq ""} {if {[info exist _AP_VARS($w,$name)]} {return $_AP_VARS($w,$name)}
return $defval}
return [set _AP_VARS($w,$name) $val]}
proc IntStatus {w {name "status"} {val ""}} {set old [WindowStatus $w $name "" 0]
if {$val ne ""} {WindowStatus $w $name $val 1}
return $old}
proc shadowAllowed {{val ""} {w .}} {return [IntStatus $w SHADOW $val]}
proc modalsOpen {{val ""} {w .}} {return [IntStatus $w MODALS $val]}
proc iconImage {{icon ""}} {variable _AP_IMG
variable _AP_ICO
if {$icon eq ""} {return $_AP_ICO}
proc imagename {icon} {   # Get a defined icon's image name
return _AP_IMG(img$icon)}
variable apaveDir
if {[array size _AP_IMG] == 0} {source [file join $apaveDir apaveimg.tcl]
foreach ic $_AP_ICO {if {[catch {image create photo [imagename $ic] -data [set _AP_IMG($ic)]}]} {image create photo [imagename $ic] -data [set _AP_IMG(none)]}}}
if {$icon eq "-init"} return
if {$icon ni $_AP_ICO} { set icon [lindex $_AP_ICO 0] }
return [imagename $icon]}
proc iconData {{icon "info"}} {variable _AP_IMG
iconImage -init
return [set _AP_IMG($icon)]}
proc setAppIcon {win {winicon ""}} {set appIcon ""
if {$winicon ne ""} {if {[catch {set appIcon [image create photo -data $winicon]}]} {catch { set appIcon [image create photo -file $winicon] }}}
if {$appIcon ne ""} { wm iconphoto $win $appIcon }
return}
proc paveObj {com args} {set pobj [::apave::APaveInput new]
if {[set exported [expr {$com eq "EXPORT"}]]} {set com [lindex $args 0]
set args [lrange $args 1 end]
oo::objdefine $pobj "export $com"}
set res [$pobj $com {*}$args]
if {$exported} {oo::objdefine $pobj "unexport $com"}
$pobj destroy
return $res}}
source [file join $::apave::apaveDir obbit.tcl]
oo::class create ::apave::APave {mixin ::apave::ObjectTheming
variable _pav
constructor {{cs -2} args} {array set _pav [list]
set _pav(ns) [namespace current]::
set _pav(lwidgets) [list]
set _pav(moveall) 0
set _pav(tonemoves) 1
set _pav(initialcolor) black
set _pav(clnddate) ""
set _pav(modalwin) "."
set _pav(fgbut) [ttk::style lookup TButton -foreground]
set _pav(bgbut) [ttk::style lookup TButton -background]
set _pav(fgtxt) [ttk::style lookup TEntry -foreground]
set _pav(prepost) [list]
set _pav(widgetopts) [list]
set _pav(edge) "@@"
if {$_pav(fgtxt)=="black" || $_pav(fgtxt)=="#000000"} {set _pav(bgtxt) white
} else {set _pav(bgtxt) [ttk::style lookup TEntry -background]}
namespace eval ${_pav(ns)}PN {}
array set ${_pav(ns)}PN::AR {}
if {$cs>=-1} {my csSet $cs} {my initTooltip}
proc ListboxHandle {W offset maxChars} {
set list {}
foreach index [$W curselection] { lappend list [$W get $index] }
set text [join $list \n]
return [string range $text $offset [expr {$offset+$maxChars-1}]]}
proc ListboxSelect {W} {selection clear -displayof $W
selection own -command {} $W
selection handle -type UTF8_STRING $W [list [namespace current]::ListboxHandle $W]
selection handle $W [list [namespace current]::ListboxHandle $W]
return}
proc WinResize {win} {if {[lindex [$win configure -menu] 4] ne ""} {lassign [split [wm geometry $win] x+] w y
lassign [wm minsize $win] wmin ymin
if {$w<$wmin && $y<$ymin} {set corrgeom ${wmin}x${ymin}
} elseif {$w<$wmin} {set corrgeom ${wmin}x${y}
} elseif {$y<$ymin} {set corrgeom ${w}x${ymin}
} else {return}
wm geometry $win $corrgeom}
return}
if {[llength [self next]]} { next {*}$args }
return}
destructor {array unset ${_pav(ns)}PN::AR
namespace delete ${_pav(ns)}PN
array unset _pav
if {[llength [self next]]} next}
method CenteredXY {rw rh rx ry w h} {set x [expr {max(0, $rx + ($rw - $w) / 2)}]
set y [expr {max(0,$ry + ($rh - $h) / 2)}]
set scrw [expr [winfo screenwidth .] - 12]
set scrh [expr {[winfo screenheight .] - 36}]
if {($x + $w) > $scrw } {set x [expr {$scrw - $w}]}
if {($y + $h) > $scrh } {set y [expr {$scrh - $h}]}
return +$x+$y}
method ownWName {name} {return [lindex [split $name .] end]}
method parentWName {name} {return [string range $name 0 [string last . $name]-1]}
method themePopup {mnu} {return}
method NonTtkTheme {win} {return}
method NonTtkStyle {typ {dsbl 0}} {return}
method iconA {icon} {return "-image [::apave::iconImage $icon] -compound left"}
method configure {args} {foreach {optnam optval} $args { set _pav($optnam) $optval }
return}
method setDefaultAttrs {typ opt atr} {lassign [dict get $::apave::_Defaults $typ] defopts defattrs
set newval [list "$defopts $opt" "$defattrs $atr"]
dict set ::apave::_Defaults $typ $newval
return $newval}
method ExpandOptions {options} {set options [string map {" -st " " -sticky "
" -com " " -command "
" -t " " -text "
" -w " " -width "
" -h " " -height "
" -var " " -variable "
" -tvar " " -textvariable "
" -lvar " " -listvariable "
" -ro " " -readonly "
} " $options"]
return $options}
method FCfieldAttrs {wnamefull attrs varopt} {lassign [::apave::parseOptions $attrs $varopt "" -retpos "" -inpval ""] vn rp iv
if {[string first "-state disabled" $attrs]<0 && $vn ne ""} {set all ""
if {$varopt eq "-lvar"} {lassign [::apave::parseOptions $attrs -values "" -ALL 0] iv a
if {[string is boolean -strict $a] && $a} {set all "ALL"}
set attrs [::apave::removeOptions $attrs -values -ALL]
lappend _pav(widgetopts) "-lbxname$all $wnamefull $vn"}
if {$rp ne ""} {if {$all ne ""} {set rp "0:end"}
lappend _pav(widgetopts) "-retpos $wnamefull $vn $rp"}}
if {$iv ne ""} { set $vn $iv }
return [::apave::removeOptions $attrs -retpos -inpval]}
method FCfieldValues {wnamefull attrs} {proc readFCO {fname} {if {$fname eq ""} {
set retval {{}}
} else {
set retval {}
foreach ln [split [::apave::readTextFile $fname "" 1] \n] {if {$ln ne {}} {lappend retval $ln}}}
return $retval}
proc contFCO {fline opts edge args} {lassign [::apave::parseOptionsFile 1 $opts {*}$args] opts
lassign $opts - - - div1 - div2 - pos - len - RE - ret
set ldv1 [string length $div1]
set ldv2 [string length $div2]
set i1 [expr {[string first $div1 $fline]+$ldv1}]
set i2 [expr {[string first $div2 $fline]-1}]
set filterfile yes
if {$ldv1 && $ldv2} {if {$i1<0 || $i2<0} {return $edge}
set retval [string range $fline $i1 $i2]
} elseif {$ldv1} {if {$i1<0} {return $edge}
set retval [string range $fline $i1 end]
} elseif {$ldv2} {if {$i2<0} {return $edge}
set retval [string range $fline 0 $i2]
} elseif {$pos ne {} && $len ne {}} {set retval [string range $fline $pos $pos+[incr len -1]]
} elseif {$pos ne {}} {set retval [string range $fline $pos end]
} elseif {$len ne {}} {set retval [string range $fline 0 $len-1]
} elseif {$RE ne {}} {set retval [regexp -inline $RE $fline]
if {[llength $retval]>1} {foreach r [lrange $retval 1 end] {append retval_tmp $r}
set retval $retval_tmp
} else {set retval [lindex $retval 0]}
} else {set retval $fline
set filterfile no}
if {$retval eq "" && $filterfile} {return $edge}
set retval [string map [list "\}" "\\\}"  "\{" "\\\{"] $retval]
return [list $retval $ret]}
set edge $_pav(edge)
set ldv1 [string length $edge]
set filecontents {}
set optionlists {}
set tplvalues ""
set retpos ""
set values [::apave::getOption -values {*}$attrs]
if {[string first $edge $values]<0} {set values "$edge$values$edge"}
set lopts "-list {} -div1 {} -div2 {} -pos {} -len {} -RE {} -ret 0"
while {1} {set i1 [string first $edge $values]
set i2 [string first $edge $values $i1+1]
if {$i1>=0 && $i2>=0} {incr i1 $ldv1
append tplvalues [string range $values 0 $i1-1]
set fdata [string range $values $i1 $i2-1]
lassign [::apave::parseOptionsFile 1 $fdata {*}$lopts] fopts fname
lappend filecontents [readFCO $fname]
lappend optionlists $fopts
set values [string range $values $i2+$ldv1 end]
} else {append tplvalues $values
break}}
if {[set leno [llength $optionlists]]} {set newvalues ""
set ilin 0
lassign $filecontents firstFCO
foreach fline $firstFCO {set line ""
set tplline $tplvalues
for {set io 0} {$io<$leno} {incr io} {set opts [lindex $optionlists $io]
if {$ilin==0} {lassign $opts - list1
if {[llength $list1]} {foreach l1 $list1 {append newvalues "\{$l1\} "}
lappend _pav(widgetopts) "-list $wnamefull [list $list1]"}}
set i1 [string first $edge $tplline]
if {$i1>=0} {lassign [contFCO $fline $opts $edge {*}$lopts] retline ret
if {$ret ne "0" && $retline ne $edge && [string first $edge $line]<0} {set p1 [expr {[string length $line]+$i1}]
if {$io<($leno-1)} {set p2 [expr {$p1+[string length $retline]-1}]
} else {set p2 end}
set retpos "-retpos $p1:$p2"}
append line [string range $tplline 0 $i1-1] $retline
set tplline [string range $tplline $i1+$ldv1 end]
} else {break}
set fline [lindex [lindex $filecontents $io+1] $ilin]}
if {[string first $edge $line]<0} {append newvalues "\{$line$tplline\} "}
incr ilin}
lassign [::apave::parseOptionsFile 2 $attrs -values [string trimright $newvalues]] attrs}
return "$attrs $retpos"}
method ListboxesAttrs {w attrs} {if {"-exportselection" ni $attrs} {append attrs " -ListboxSel $w -selectmode extended -exportselection 0"}
return $attrs}
method timeoutButton {w tmo lbl {lbltext ""}} {if {$tmo>0} {catch {set lbl [my $lbl]}
if {[winfo exist $lbl]} {if {$lbltext eq ""} {set lbltext [$lbl cget -text]
lappend ::apave::_AP_VARS(TIMW) $w}
$lbl configure -text "$lbltext $tmo sec. "}
incr tmo -1
after 1000 [list if "\[info commands [self]\] ne {}" "[self] checkTimeoutButton $w $tmo $lbl {$lbltext}"]
return}
if {[winfo exist $w]} {$w invoke}
return}
method checkTimeoutButton {w tmo lbl {lbltext ""}} {if {[winfo exists $lbl]} {if {[focus] in [list $w ""]} {if {$w in $::apave::_AP_VARS(TIMW)} {my timeoutButton $w $tmo $lbl $lbltext}
} else {$lbl configure -text $lbltext}}}
method AddButtonIcon {w attrsName} {upvar 1 $attrsName attrs
set txt [::apave::getOption -t {*}$attrs]
if {$txt eq ""} { set txt [::apave::getOption -text {*}$attrs] }
set im ""
set icolist [list {exit abort} {exit close} {SaveFile save} {OpenFile open}]
lappend icolist {*}[::apave::iconImage] {yes apply}
foreach icon $icolist {lassign $icon ic1 ic2
if {[string match -nocase $ic1 $txt] || [string match -nocase but$ic1 $w] || ($ic2 ne "" && ( [string match -nocase but$ic2 $w] || [string match -nocase $ic2 $txt]))} {append attrs " [my iconA $ic1]"
break}}
return}
method widgetType {wnamefull options attrs} {set disabled [expr {[::apave::getOption -state {*}$attrs] eq "disabled"}]
set pack $options
set name [my ownWName $wnamefull]
set nam3 [string tolower [string index $name 0]][string range $name 1 2]
if {[string index $nam3 1] eq "_"} {set k [string range $nam3 0 1]} {set k $nam3}
lassign [dict get $::apave::_Defaults $k] defopts defattrs
set options "[subst $defopts] $options"
set attrs "[subst $defattrs] $attrs"
switch -glob -- $nam3 {"bts" {package require bartabs
set attrs "-bartabs {$attrs}"
set widget "ttk::frame"}
"but" {set widget "ttk::button"
my AddButtonIcon $name attrs}
"buT" {set widget "button"
my AddButtonIcon $name attrs}
"can" {set widget "canvas"}
"chb" {set widget "ttk::checkbutton"}
"chB" {set widget "checkbutton"}
"cbx" - "fco" {set widget "ttk::combobox"
if {$nam3 eq "fco"} {set attrs [my FCfieldValues $wnamefull $attrs]}
set attrs [my FCfieldAttrs $wnamefull $attrs -tvar]}
"ent" {set widget "ttk::entry"}
"enT" {set widget "entry"}
"fil" -
"fis" -
"dir" -
"fon" -
"clr" -
"dat" -
"sta" -
"too" -
"fra" {set widget "ttk::frame"}
"ftx" {set widget "ttk::labelframe"}
"frA" {set widget "frame"
if {$disabled} {set attrs [::apave::removeOptions $attrs -state]}}
"lab" {set widget "ttk::label"
if {[::apave::parseOptions $attrs -state normal] eq "disabled"} {set attrs "-foreground grey $attrs"
set attrs [::apave::removeOptions $attrs -state]}
if {[set cmd [::apave::getOption -link {*}$attrs]] ne ""} {set attrs "-linkcom {$cmd} $attrs"
set attrs [::apave::removeOptions $attrs -link]}}
"laB" {set widget "label"}
"lfr" {set widget "ttk::labelframe"}
"lfR" {set widget "labelframe"
if {$disabled} {set attrs [::apave::removeOptions $attrs -state]}}
"lbx" - "flb" {set widget "listbox"
if {$nam3 eq "flb"} {set attrs [my FCfieldValues $wnamefull $attrs]}
set attrs "[my FCfieldAttrs $wnamefull $attrs -lvar]"
set attrs "[my ListboxesAttrs $wnamefull $attrs]"
my AddPopupAttr $wnamefull attrs -entrypop 1}
"meb" {set widget "ttk::menubutton"}
"meB" {set widget "menubutton"}
"nbk" {set widget "ttk::notebook"
set attrs "-notebazook {$attrs}"}
"opc" {;
;
set widget "my tk_optionCascade"
set imax [expr {min(4,[llength $attrs])}]
for {set i 0} {$i<$imax} {incr i} {set atr [lindex $attrs $i]
if {$i!=1} {lset attrs $i \{$atr\}
} elseif {[llength $atr]==1 && [info exist $atr]} {lset attrs $i [set $atr]}}}
"pan" {set widget "ttk::panedwindow"}
"pro" {set widget "ttk::progressbar"}
"rad" {set widget "ttk::radiobutton"}
"raD" {set widget "radiobutton"}
"sca" {set widget "ttk::scale"}
"scA" {set widget "scale"}
"sbh" {set widget "ttk::scrollbar"}
"sbH" {set widget "scrollbar"}
"sbv" {set widget "ttk::scrollbar"}
"sbV" {set widget "scrollbar"}
"seh" {set widget "ttk::separator"}
"sev" {set widget "ttk::separator"}
"siz" {set widget "ttk::sizegrip"}
"spx" - "spX" {if {$nam3 eq "spx"} {set widget "ttk::spinbox"} {set widget "spinbox"}
lassign [::apave::parseOptions $attrs -command "" -from "" -to "" ] cmd from to
set attrs "-onReturn {$::apave::UFF{$cmd} {$from} {$to}$::apave::UFF} $attrs"}
"tbl" {package require tablelist
set widget "tablelist::tablelist"
set attrs "[my FCfieldAttrs $wnamefull $attrs -lvar]"
set attrs "[my ListboxesAttrs $wnamefull $attrs]"}
"tex" {set widget "text"
if {[::apave::getOption -textpop {*}$attrs] eq ""} {my AddPopupAttr $wnamefull attrs -textpop [expr {[::apave::getOption -rotext {*}$attrs] ne ""}] -- disabled}
lassign [::apave::parseOptions $attrs -ro "" -readonly "" -rotext ""] r1 r2 r3
set b1 [expr [string is boolean -strict $r1]]
set b2 [expr [string is boolean -strict $r2]]
if {($b1 && $r1) || ($b2 && $r2) || ($r3 ne "" && !($b1 && !$r1) && !($b2 && !$r2))} {set attrs "-takefocus 0 $attrs"}}
"tre" {set widget "ttk::treeview"}
"h_*" {set widget "ttk::frame"}
"v_*" {set widget "ttk::frame"}
default {set widget ""}}
if {$nam3 in {cbx ent enT fco spx spX}} {;
my AddPopupAttr $wnamefull attrs -entrypop 0 readonly disabled}
if {[string first "pack" [string trimleft $pack]]==0} {set options $pack}
set options [string trim $options]
set attrs   [list {*}$attrs]
return [list $widget $options $attrs $nam3 $disabled]}
method SpanConfig {w rcnam rc rcspan opt val} {for {set i $rc} {$i < ($rc + $rcspan)} {incr i} {eval [grid ${rcnam}configure $w $i $opt $val]}
return}
method GetIntOptions {w options row rowspan col colspan} {set opts ""
foreach {opt val} [list {*}$options] {switch -- $opt {-rw  {my SpanConfig $w row $row $rowspan -weight $val}
-cw  {my SpanConfig $w column $col $colspan -weight $val}
-rsz {my SpanConfig $w row $row $rowspan -minsize $val}
-csz {my SpanConfig $w column $col $colspan -minsize $val}
-ro  {my SpanConfig $w column $col $colspan -readonly $val}
default {append opts " $opt $val"}}}
return [my ExpandOptions $opts]}
method GetAttrs {options {nam3 ""} {disabled 0} } {set opts [list]
foreach {opt val} [list {*}$options] {switch -- $opt {-t - -text {;
set val [string map [list \\n \n \\t \t] $val]
set opt -text}
-st {set opt -sticky}
-com {set opt -command}
-w {set opt -width}
-h {set opt -height}
-var {set opt -variable}
-tvar {set opt -textvariable}
-lvar {set opt -listvariable}
-ro {set opt -readonly}}
lappend opts $opt \{$val\}}
if {$disabled} {append opts [my NonTtkStyle $nam3 1]}
return $opts}
method optionCascadeText {it} {if {[string match "\{*\}" $it]} {set it [string range $it 1 end-1]}
return $it}
method tk_optionCascade {w vname items {mbopts ""} {precom ""} args} {if {![info exists $vname]} {set it [lindex $items 0]
while {[llength $it]>1} {set it [lindex $it 0]}
set it [my optionCascadeText $it]
set $vname $it}
ttk::menubutton $w -menu $w.m -text [set $vname] {*}$mbopts
menu $w.m -tearoff 0
my OptionCascade_add $w.m $vname $items $precom {*}$args
trace var $vname w "$w config -text \"\[[self] optionCascadeText \${$vname}\]\" ;\#"
return $w.m}
method OptionCascade_add {w vname argl precom args} {set n [set colbreak 0]
foreach arg $argl {if {$arg eq "--"} {$w add separator
} elseif {$arg eq "|"} {if {[tk windowingsystem] ne "aqua"} { set colbreak 1 }
continue
} elseif {[llength $arg] == 1} {set label [my optionCascadeText [join $arg]]
if {$precom eq ""} {set adds ""
} else {set adds [eval {*}[string map [list %a $label] $precom]]}
$w add radiobutton -label $label -variable $vname {*}$args {*}$adds
} else {set child [menu $w.[incr n] -tearoff 0]
$w add cascade -label [lindex $arg 0] -menu $child
my OptionCascade_add $child $vname [lrange $arg 1 end] $precom {*}$args}
if $colbreak {$w entryconfigure end -columnbreak 1
set colbreak 0}}
return}
method ParentOpt {{w "."}} {if {$_pav(modalwin) eq "."} {set wpar $w} {set wpar $_pav(modalwin)}
return "-parent $wpar"}
method colorChooser {tvar args} {if {[set _ [string trim [set $tvar]]] ne ""} {set _pav(initialcolor) $_
} else {set _pav(initialcolor) black}
if {[catch {lassign [tk_chooseColor -moveall $_pav(moveall) -tonemoves $_pav(tonemoves) -initialcolor $_pav(initialcolor) {*}$args] res _pav(moveall) _pav(tonemoves)}]} {set res [tk_chooseColor -initialcolor $_pav(initialcolor) {*}$args]}
if {$res ne ""} {set _pav(initialcolor) [set $tvar $res]}
return $res}
method fontChooser {tvar args} {proc [namespace current]::applyFont {font} "
      set $tvar \[font actual \$font\]"
set font [set $tvar]
if {$font==""} {catch {font create fontchoose {*}[font actual TkDefaultFont]}
} else {catch {font delete fontchoose}
catch {font create fontchoose {*}[font actual $font]}}
tk fontchooser configure -parent . -font fontchoose {*}[my ParentOpt] {*}$args -command [namespace current]::applyFont
set res [tk fontchooser show]
return $font}
method dateChooser {tvar args} {set df %d.%m.%Y
array set a $args
set ttl "Date"
if [info exists a(-title)] {set ttl "$a(-title)"}
catch {set df $a(-dateformat)
set _pav(clnddate) [set $tvar]}
if {$_pav(clnddate)==""} {set _pav(clnddate) [clock format [clock seconds] -format $df]}
set wcal [set wmain [set ${_pav(ns)}PN::wn]].dateWidChooser
catch {destroy $wcal}
wm title [toplevel $wcal] $ttl
lassign [split [winfo geometry $_pav(modalwin)] x+] rw rh rx ry
wm geometry $wcal [my CenteredXY $rw $rh $rx $ry 220 150]
wm protocol $wcal WM_DELETE_WINDOW [list set ${_pav(ns)}datechoosen ""]
bind $wcal <Escape> [list set ${_pav(ns)}datechoosen ""]
set ${_pav(ns)}datechoosen ""
package require widget::calendar
widget::calendar $wcal.c -dateformat $df -enablecmdonkey 0 -command [list set ${_pav(ns)}datechoosen] -textvariable ${_pav(ns)}_pav(clnddate)
pack $wcal.c -fill both -expand 0
after idle [list focus $wcal]
vwait ${_pav(ns)}datechoosen
update idle
destroy $wcal
if {[set ${_pav(ns)}datechoosen]==""} {set _pav(clnddate) [set $tvar]}
return $_pav(clnddate)}
method chooser {nchooser tvar args} {set isfilename 0
set ftxvar [::apave::getOption -ftxvar {*}$args]
set args [::apave::removeOptions $args -ftxvar]
if {$nchooser eq "ftx_OpenFile"} {set nchooser "tk_getOpenFile"}
if {$nchooser=="fontChooser" || $nchooser=="colorChooser" ||  $nchooser=="dateChooser" } {set nchooser "my $nchooser $tvar"
} elseif {$nchooser=="tk_getOpenFile" || $nchooser=="tk_getSaveFile"} {if {[set fn [set $tvar]]==""} {set dn [pwd]} {set dn [file dirname $fn]}
set args "-initialfile \"$fn\" -initialdir \"$dn\" [my ParentOpt] $args"
incr isfilename
} elseif {$nchooser=="tk_chooseDirectory"} {set args "-initialdir \"[set $tvar]\" [my ParentOpt] $args"
incr isfilename}
set res [{*}$nchooser {*}$args]
if {"$res" ne "" && "$tvar" ne ""} {if {$isfilename} {lassign [my SplitContentVariable $ftxvar] -> txtnam wid
if {[info exist $ftxvar] && [file exist [set res [file nativename $res]]]} {set $ftxvar [::apave::readTextFile $res]
if {[winfo exist $txtnam]} {my readonlyWidget $txtnam no
my displayTaggedText $txtnam $ftxvar
my readonlyWidget $txtnam yes
set wid [string range $txtnam 0 [string last . $txtnam]]$wid
$wid configure -text "$res"
::tk::TextSetCursor $txtnam 1.0
update}}}
set $tvar $res}
return $res}
method Transname {typ name} {if {[set pp [string last . $name]]>-1} {set name [string range $name 0 $pp]$typ[string range $name $pp+1 end]
} else {set name $typ$name}
return $name}
method SetContentVariable {tvar txtnam name} {return [set _pav(textcont,$tvar) $tvar*$txtnam*$name]}
method GetContentVariable {tvar} {return $_pav(textcont,$tvar)}
method SplitContentVariable {ftxvar} {return [split $ftxvar *]}
method getTextContent {tvar} {lassign [my SplitContentVariable [my GetContentVariable $tvar]] -> txtnam wid
return [string trimright [$txtnam get 1.0 end]]}
method Replace_Tcl {r1 r2 r3 args} {upvar 1 $r1 _ii $r2 _lwlen $r3 _lwidgets
lassign $args _name _code
if {[my ownWName $_name] ne "tcl"} {return $args}
proc lwins {lwName i w} {upvar 2 $lwName lw
set lw [linsert $lw $i $w]}
set _lwidgets [lreplace $_lwidgets $_ii $_ii]
set _inext [expr {$_ii-1}]
eval [string map {%C {lwins $r3 [incr _inext] }} $_code]
return ""}
method Replace_chooser {r0 r1 r2 r3 args} {upvar 1 $r0 w $r1 i $r2 lwlen $r3 lwidgets
lassign $args name neighbor posofnei rowspan colspan options1 attrs1
lassign "" wpar view addattrs addattrs2
set tvar [::apave::getOption -tvar {*}$attrs1]
set filetypes [::apave::getOption -filetypes {*}$attrs1]
set takefocus "-takefocus [::apave::parseOptions $attrs1 -takefocus 0]"
if {$filetypes ne ""} {set attrs1 [::apave::removeOptions $attrs1 -filetypes -takefocus]
lset args 6 $attrs1
append addattrs2 " -filetypes {$filetypes}"}
set an ""
lassign [my LowercaseWidgetName $name] n
switch -glob -- [my ownWName $n] {"fil*" { set chooser "tk_getOpenFile" }
"fis*" { set chooser "tk_getSaveFile" }
"dir*" { set chooser "tk_chooseDirectory" }
"fon*" { set chooser "fontChooser" }
"dat*" { set chooser "dateChooser" }
"ftx*" {set chooser [set view "ftx_OpenFile"]
if {$tvar ne "" && [info exist $tvar]} {append addattrs " -t {[set $tvar]}"}
set an "tex"}
"clr*" { set chooser "colorChooser"
set wpar "-parent $w"}
default {return $args}}
my MakeWidgetName $w $name $an
set name $n
set tvar [set vv [set addopt ""]]
set attmp [list]
foreach {nam val} $attrs1 {if {$nam=="-title" || $nam=="-dateformat"} {append addopt " $nam \{$val\}"
} else {lappend attmp $nam $val}}
set attrs1 $attmp
catch {array set a $attrs1; set tvar "-tvar [set vv $a(-tvar)]"}
catch {array set a $attrs1; set tvar "-tvar [set vv $a(-textvariable)]"}
if {$vv==""} {set vv [namespace current]::$name
set tvar "-tvar $vv"}
set ispack 0
if {![catch {set gm [lindex [lindex $lwidgets $i] 5]}]} {set ispack [expr [string first "pack" $gm]==0]}
if {$ispack} {set args [list $name - - - - "pack -expand 0 -fill x [string range $gm 5 end]" $addattrs]
} else {set args [list $name $neighbor $posofnei $rowspan $colspan "-st ew" $addattrs]}
lset lwidgets $i $args
if {$view ne ""} {append attrs1 " -callF2 $w.[my Transname buT $name]"
set txtnam [my Transname tex $name]
set tvar [::apave::getOption -tvar {*}$attrs1]
set attrs1 [::apave::removeOptions $attrs1 -tvar]
if {$tvar ne "" && [file exist [set $tvar]]} {set tcont [my SetContentVariable $tvar $w.$txtnam $name]
set wpar "-ftxvar $tcont"
set $tcont [::apave::readTextFile [set $tvar]]
set attrs1 [::apave::putOption -rotext $tcont {*}$attrs1]}
set entf [list $txtnam - - - - "pack -side left -expand 1 -fill both -in $w.$name" "$attrs1"]
} else {append attrs1 " -callF2 {.ent .buT}"
set entf [list [my Transname ent $name] - - - - "pack -side left -expand 1 -fill x -in $w.$name" "$attrs1 $tvar"]}
set icon "folder"
foreach ic {OpenFile SaveFile font color date} {if {[string first $ic $chooser] >= 0} {set icon $ic; break}}
set com "[self] chooser $chooser \{$vv\} $addopt $wpar $addattrs2"
set butf [list [my Transname buT $name] - - - - "pack -side right -anchor n -in $w.$name -padx 1" "-com \{$com\} -compound none -image [::apave::iconImage $icon] -font \{-weight bold -size 5\} -fg $_pav(fgbut) -bg $_pav(bgbut) $takefocus"]
if {$view ne ""} {set scrolh [list [my Transname sbh $name] $txtnam T - - "pack -in $w.$name" ""]
set scrolv [list [my Transname sbv $name] $txtnam L - - "pack -in $w.$name" ""]
set lwidgets [linsert $lwidgets [expr {$i+1}] $butf]
set lwidgets [linsert $lwidgets [expr {$i+2}] $entf]
set lwidgets [linsert $lwidgets [expr {$i+3}] $scrolv]
incr lwlen 3
set wrap [::apave::getOption -wrap {*}$attrs1]
if {$wrap eq "none"} {set lwidgets [linsert $lwidgets [expr {$i+4}] $scrolh]
incr lwlen}
} else {set lwidgets [linsert $lwidgets [expr {$i+1}] $entf $butf]
incr lwlen 2}
return $args}
method Replace_bar {r0 r1 r2 r3 args} {upvar 1 $r0 w $r1 i $r2 lwlen $r3 lwidgets
lassign $args name neighbor posofnei rowspan colspan options1 attrs1
set wpar ""
switch -glob -- [my ownWName $name] {"men*" - "Men*" { set typ menuBar }
"too*" - "Too*" { set typ toolBar }
"sta*" - "Sta*" { set typ statusBar }
default {return $args}}
set winname [winfo toplevel $w]
set attcur [list]
set namvar [list]
foreach {nam val} $attrs1 {if {$nam=="-array"} {catch {set val [subst $val]}
set ind -1
foreach {v1 v2} $val {lappend namvar [namespace current]::$typ[incr ind] $v1 $v2}
} else {lappend attcur $nam $val}}
if {$typ=="menuBar"} {set args ""
} else {set ispack 0
if {![catch {set gm [lindex [lindex $lwidgets $i] 5]}]} {set ispack [expr [string first "pack" $gm]==0]}
if {$ispack} {set args [list $name - - - - "pack -expand 0 -fill x -side bottom [string range $gm 5 end]" $attcur]
} else {set args [list $name $neighbor $posofnei $rowspan $colspan "-st ew" $attcur]}
lset lwidgets $i $args}
set itmp $i
set k [set j [set j2 [set wasmenu 0]]]
foreach {nam v1 v2} $namvar {if {[incr k 3]==[llength $namvar]} {set expand "-expand 1 -fill x"
} else {set expand ""}
if {$v1=="h_"} {set ntmp [my Transname fra ${name}[incr j2]]
set wid1 [list $ntmp - - - - "pack -side left -in $w.$name -fill y"]
set wid2 [list $ntmp.[my Transname h_ $name$j] - - - - "pack -fill y -expand 1 -padx $v2"]
} elseif {$v1=="sev"} {set ntmp [my Transname fra ${name}[incr j2]]
set wid1 [list $ntmp - - - - "pack -side left -in $w.$name -fill y"]
set wid2 [list $ntmp.[my Transname sev $name$j] - - - - "pack -fill y -expand 1 -padx $v2"]
} elseif {$typ=="statusBar"} {my NormalizeName name i lwidgets
set wid1 [list .[my ownWName [my Transname Lab ${name}_[incr j]]] - - - - "pack -side left -in $w.$name" "-t [lindex $v1 0]"]
set wid2 [list .[my ownWName [my Transname Lab $name$j]] - - - - "pack -side left $expand -in $w.$name" "-relief sunken -w $v2 [lrange $v1 1 end]"]
} elseif {$typ=="toolBar"} {switch -nocase -glob -- $v1 {opc* {lset v2 2 "[lindex $v2 2] -takefocus 0"
set wid1 [list $name.$v1 - - - - "pack -side left" "$v2"]}
spx* - chb* {set v2 "$v2 -takefocus 0"
set wid1 [list $name.$v1 - - - - "pack -side left" "$v2"]}
default {if {[string is lower [string index $v1 0]]} {set but buT
} else {set but BuT}
set v2 "-image $v1 -command $v2 -relief flat -highlightthickness 0 -takefocus 0"
set v1 [my Transname $but _$v1]}}
set wid1 [list $name.$v1 - - - - "pack -side left" $v2]
if {[incr wasseh]==1} {set wid2 [list [my Transname seh $name$j] - - - - "pack -side top -fill x"]
} else {set lwidgets [linsert $lwidgets [incr itmp] $wid1]
continue}
} elseif {$typ=="menuBar"} {;
if {[incr wasmenu]==1} {set menupath [my MakeWidgetName $winname $name]
menu $menupath -tearoff 0}
set menuitem [my MakeWidgetName $menupath $v1]
menu $menuitem -tearoff 0
set ampos [string first & $v2]
set v2 [string map {& ""} $v2]
$menupath add cascade -label [lindex $v2 0] {*}[lrange $v2 1 end] -menu $menuitem -underline $ampos
continue
} else {error "\npaveme.tcl: erroneous \"$v1\" for \"$nam\"\n"}
set lwidgets [linsert $lwidgets [incr itmp] $wid1 $wid2]
incr itmp}
if {$wasmenu} {$winname configure -menu $menupath}
incr lwlen [expr {$itmp - $i}]
return $args}
method LowercaseWidgetName {name} {set root [my ownWName $name]
return [list [string range $name 0 [string last . $name]][string tolower [string index $root 0]][string range $root 1 end] $root]}
method NormalizeName {refname refi reflwidgets} {upvar $refname name $refi i $reflwidgets lwidgets
set wname $name
if {[string index $name 0]=="."} {for {set i2 [expr {$i-1}]} {$i2 >=0} {incr i2 -1} {lassign [lindex $lwidgets $i2] name2
if {[string index $name2 0] ne "."} {set wname "$name2$name"
lassign [my LowercaseWidgetName $name] name
set name "$name2$name"
break}}}
return [list $name $wname]}
method MakeWidgetName {w name {an {}}} {set root1 [string index [my ownWName $name] 0]
if {[string is upper $root1]} {lassign [my LowercaseWidgetName $name] name method
if {[catch {info object definition [self] $method}]} {oo::objdefine [self] "
          method $method {} {return $w.$an$name}
          export $method"}}
return [set ${_pav(ns)}PN::wn $w.$name]}
method SetTextBinds {wt} {if {[bind $wt <<Paste>>] eq ""} {set res "
      bind $wt <<Paste>> {+ [self] pasteText $wt}
      bind $wt <KeyPress> {+ [self] onKeyTextM $wt %K}"}
append res "
      bind $wt <Control-d> {[self] doubleText $wt}
      bind $wt <Control-D> {[self] doubleText $wt}
      bind $wt <Control-y> {[self] deleteLine $wt}
      bind $wt <Control-Y> {[self] deleteLine $wt}
      bind $wt <Alt-Up> {[self] linesMove $wt -1}
      bind $wt <Alt-Down> {[self] linesMove $wt +1}
      bind $wt <Control-a> \"$wt tag add sel 1.0 end; break\""
return $res}
method AddPopupAttr {w attrsName atRO isRO args} {upvar 1 $attrsName attrs
lassign $args state state2
if {$state2 ne ""} {if {[::apave::getOption -state {*}$attrs] eq $state2} return
set isRO [expr {$isRO || [::apave::getOption -state {*}$attrs] eq $state}]}
if {$isRO} { append atRO "RO" }
append attrs " $atRO $w"
return}
method makePopup {w {isRO no} {istext no} {tearoff no}} {set pop $w.popupMenu
catch {menu $pop -tearoff $tearoff}
$pop delete 0 end
if {$isRO} {$pop add command {*}[my iconA copy] -accelerator Ctrl+C -label "Copy" -command "event generate $w <<Copy>>"
} else {$pop add command {*}[my iconA cut] -accelerator Ctrl+X -label "Cut" -command "event generate $w <<Cut>>"
$pop add command {*}[my iconA copy] -accelerator Ctrl+C -label "Copy" -command "event generate $w <<Copy>>"
$pop add command {*}[my iconA paste] -accelerator Ctrl+V -label "Paste" -command "event generate $w <<Paste>>"
if {$istext} {$pop add separator
$pop add command {*}[my iconA undo] -accelerator Ctrl+Z -label "Undo" -command "event generate $w <<Undo>>"
$pop add command {*}[my iconA redo] -accelerator Ctrl+Shift+Z -label "Redo" -command "event generate $w <<Redo>>"
after idle [my SetTextBinds $w]}}
if {$istext} {$pop add separator
$pop add command {*}[my iconA none] -accelerator Ctrl+A -label "Select All" -command "$w tag add sel 1.0 end"
bind $w <Control-a> "$w tag add sel 1.0 end; break"}
bind $w <Button-3> "[self] themePopup $w.popupMenu; tk_popup $w.popupMenu %X %Y"
return}
method Pre {refattrs} {upvar 1 $refattrs attrs
set attrs_ret [set _pav(prepost) {}]
foreach {a v} $attrs {switch -- $a {-disabledtext - -rotext - -lbxsel - -cbxsel - -notebazook - -entrypop - -entrypopRO - -textpop - -textpopRO - -ListboxSel - -callF2 - -timeout - -bartabs - -onReturn - -linkcom - -afteridle {set v2 [string trimleft $v "\{"]
set v2 [string range $v2 0 end-[expr {[string length $v]-[string length $v2]}]]
lappend _pav(prepost) [list $a $v2]}
-myown {lappend _pav(prepost) [list $a [subst $v]]}
default {lappend attrs_ret $a $v}}}
set attrs $attrs_ret
return}
method Post {w attrs} {foreach pp $_pav(prepost) {lassign $pp a v
set v [string trim $v $::apave::UFF]
switch -- $a {-disabledtext {$w configure -state normal
my displayTaggedText $w v {}
$w configure -state disabled
my readonlyWidget $w no}
-rotext {if {[info exist v]} {if {[info exist $v]} {my displayTaggedText $w $v {}
} else {my displayTaggedText $w v {}}}
my readonlyWidget $w yes}
-lbxsel {set v [lsearch -glob [$w get 0 end] "$v*"]
if {$v>=0} {$w selection set $v
$w yview $v
$w activate $v}
my UpdateSelectAttrs $w}
-cbxsel {set cbl [$w cget -values]
set v [lsearch -glob $cbl "$v*"]
if {$v>=0} { $w set [lindex $cbl $v] }}
-ListboxSel {bind $v <<ListboxSelect>> [list [namespace current]::ListboxSelect %W]}
-entrypop - -entrypopRO {if {[winfo exists $v]} {my makePopup $v [expr {$a eq "-entrypopRO"}]}}
-textpop - -textpopRO {if {[winfo exists $v]} {set ro [expr {$a eq "-textpopRO"}]
my makePopup $v $ro yes
$v tag configure sel -borderwidth 1}}
-notebazook {foreach {fr attr} $v {if {[string match "-tr*" $fr]} {if {[string is boolean -strict $attr] && $attr} {ttk::notebook::enableTraversal $w}
} elseif {[string match "-sel*" $fr]} {$w select $w.$attr
} elseif {![string match "#*" $fr]} {$w add [ttk::frame $w.$fr] {*}[subst $attr]}}}
-onReturn {lassign $v cmd from to
if {[set tvar [$w cget -textvariable]] ne ""} {if {$from ne ""} {set cmd "if {\$$tvar < $from} {set $tvar $from}; $cmd"}
if {$to ne ""} {set cmd "if {\$$tvar >$to} {set $tvar $to}; $cmd"}}
foreach k {<Return> <KP_Enter>} {if {$v ne ""} {bind $w $k $cmd}}}
-linkcom {lassign [my csGet] fg fg2 bg bg2
my makeLabelLinked $w $v $fg $bg $fg2 $bg2 yes yes}
-callF2 {if {[llength $v]==1} {set w2 $v} {set w2 [string map $v $w]}
if {[string first $w2 [bind $w "<F2>"]] < 0} {bind $w <F2> [list + $w2 invoke]}}
-timeout {lassign $v timo lbl
after idle [list [self] timeoutButton $w $timo $lbl]}
-myown {eval {*}[string map [list %w $w] $v]}
-bartabs {after 50 [string map [list %w $w] $v]}
-afteridle {after idle [string map [list %w $w] $v]}}}
return}
method CleanUps {{wr ""}} {for {set i [llength $::apave::_AP_VISITED(ALL)]} {[incr i -1]>=0} {} {if {![winfo exists [lindex $::apave::_AP_VISITED(ALL) $i 0]]} {set ::apave::_AP_VISITED(ALL) [lreplace $::apave::_AP_VISITED(ALL) $i $i]}}
if {$wr ne ""} {for {set i [llength $::apave::_AP_VARS(TIMW)]} {[incr i -1]>=0} {} {set w [lindex $::apave::_AP_VARS(TIMW) $i]
if {[string first $wr $w]==0 && ![catch {baltip::hide $w}]} {set ::apave::_AP_VARS(TIMW) [lreplace $::apave::_AP_VARS(TIMW) $i $i]}}}}
method UpdateColors {} {lassign [my csGet] fg fg2 bg bg2 - - - - - fg3
my CleanUps
foreach lw $::apave::_AP_VISITED(ALL) {lassign $lw w v inv
lassign [my makeLabelLinked $w $v $fg $bg $fg2 $bg2 no $inv] fg0 bg0
if {[info exists ::apave::_AP_VISITED(FG,$w)]} {set fg0 $fg3
set ::apave::_AP_VISITED(FG,$w) $fg3}
$w configure -foreground $fg0 -background $bg0}}
method initLinkFont {args} {if {[set ll [llength $args]]} {if {$ll%2} {set ::apave::_AP_VARS(LINKFONT) [list]
} else {set ::apave::_AP_VARS(LINKFONT) $args}}
return $::apave::_AP_VARS(LINKFONT)}
method labelFlashing {w1 w2 first args} {if {![winfo exists $w1]} return
if {$first} {lassign [::apave::parseOptions $args -file "" -data "" -label "" -incr 0.01 -pause 3.0 -after 10 -squeeze "" -static 0] ofile odata olabel oincr opause oafter osqueeze ostatic
if {$osqueeze ne ""} {set osqueeze "-subsample $osqueeze"}
array set ::t::AR {}
lassign {0 -2 0 1} idx incev waitev direv
} else {lassign $args ofile odata olabel oincr opause oafter osqueeze ostatic idx incev waitev direv}
set llf [llength $ofile]
set lld [llength $odata]
if {[set llen [expr {max($llf,$lld)}]]==0} return
incr incev $direv
set alphaev [expr {$oincr*$incev}]
if {$alphaev>=1} {set alpha 1.0
if {[incr waitev -1]<0} {set direv -1}
} elseif {$alphaev<0} {set alpha 0.0
set idx [expr {$idx%$llen+1}]
set direv 1
set incev 0
set waitev [expr {int($opause/$oincr)}]
} else {set alpha $alphaev}
if {$llf} {set png [list -file [lindex $ofile $idx-1]]
} else {set png [list -data [set [lindex $odata $idx-1]]]}
set NS [namespace current]
if {$ostatic} {image create photo ${NS}::ImgT$w1 {*}$png
$w1 configure -image ${NS}::ImgT$w1
} else {image create photo ${NS}::ImgT$w1 {*}$png -format "png -alpha $alpha"
image create photo ${NS}::Img$w1
${NS}::Img$w1 copy ${NS}::ImgT$w1 {*}$osqueeze
$w1 configure -image ${NS}::Img$w1}
if {$w2 ne ""} {if {$alphaev<0.33 && !$ostatic} {set fg [$w1 cget -background]
} else {if {[info exists ::apave::_AP_VISITED(FG,$w2)]} {set fg $::apave::_AP_VISITED(FG,$w2)
} else {set fg [$w1 cget -foreground]}}
$w2 configure -text [lindex $olabel $idx-1] -foreground $fg}
after $oafter [list [self] labelFlashing $w1 $w2 0 $ofile $odata $olabel $oincr $opause $oafter $osqueeze $ostatic $idx $incev $waitev $direv]}
method VisitedLab {w cmd {on ""} {fg ""} {bg ""}} {set styl [ttk::style configure TLabel]
if {$fg eq ""} {lassign [my csGet] - fg - bg}
set vst [string map {" " "_"} $cmd]
if {$on eq ""} {set on [expr {[info exists ::apave::_AP_VISITED($vst)]}]}
if {$on} {set fg [lindex [my csGet] 9]
set ::apave::_AP_VISITED($vst) 1
set ::apave::_AP_VISITED(FG,$w) $fg
foreach lw $::apave::_AP_VISITED(ALL) {lassign $lw w2 cmd2
if {[winfo exists $w2] && $cmd eq $cmd2} {$w2 configure -foreground $fg -background $bg
set ::apave::_AP_VISITED(FG,$w2) $fg}}}
$w configure -foreground $fg -background $bg
if {[set font [$w cget -font]] eq ""} {set font [font configure TkDefaultFont]
} else {catch {set font [font configure $font]}}
foreach {o v} [my initLinkFont] {dict set font $o $v}
set font [dict set font -size [my basicFontSize]]
$w configure -font $font}
method HoverLab {w cmd on {fg ""} {bg ""}} {if {$on} {if {$fg eq ""} {lassign [my csGet] fg - bg}
$w configure -background $bg
} else {my VisitedLab $w $cmd "" $fg $bg}
return}
method makeLabelLinked {lab v fg bg fg2 bg2 {doadd yes} {inv no} } {set txt [$lab cget -text]
lassign [split [string map [list $_pav(edge) $::apave::UFF] $v] $::apave::UFF] v tt vz
set tt [string map [list %l $txt] $tt]
set v [string map [list %l $txt %t $tt] $v]
if {$tt ne ""} {::baltip tip $lab $tt
lappend ::apave::_AP_VARS(TIMW) $lab}
if {$inv} {set ft $fg
set bt $bg
set fg $fg2
set bg $bg2
set fg2 $ft
set bg2 $bt}
my VisitedLab $lab $v $vz $fg $bg
bind $lab <Enter> "::apave::paveObj EXPORT HoverLab $lab {$v} yes $fg2 $bg2"
bind $lab <Leave> "::apave::paveObj EXPORT HoverLab $lab {$v} no $fg $bg"
bind $lab <Button-1> "::apave::paveObj EXPORT VisitedLab $lab {$v} yes $fg2 $bg2;$v"
if {$doadd} {lappend ::apave::_AP_VISITED(ALL) [list $lab $v $inv]}
return [list $fg $bg $fg2 $bg2]}
method onKeyTextM {w K} {if {$K eq "Return"} {set idx1 [$w index "insert linestart"]
set idx2 [$w index "insert lineend"]
set line [$w get $idx1 $idx2]
set indent [string repeat " " [expr {[string length $line]-[string length [string trimleft $line]]}]]
if {$indent ne ""} {after idle [list $w insert [$w index "$idx1 +1 line"] $indent]}}}
method TextCommandForChange {w com on {com2 ""}} {set newcom $w.internal
if {!$on} {if {[info commands ::$newcom] ne ""} {rename ::$w ""
rename ::$newcom ::$w}
} elseif {[info commands ::$newcom] eq ""} {rename $w ::$newcom
if {$com eq ""} {proc ::$w {args} "
          switch -exact -- \[lindex \$args 0\] \{              insert \{\}
              delete \{\}
              replace \{\}
              default \{                  return \[eval ::$newcom \$args\]
              \}
          \}"
} else {proc ::$w {args} "
          set _res_of_TextCommandForChange \[eval ::$newcom \$args\]
          switch -exact -- \[lindex \$args 0\] \{              insert \{$com\}
              delete \{$com\}
              replace \{$com\}
          \}
          return \$_res_of_TextCommandForChange"}}
if {$com2 ne ""} {{*}$com2}}
method readonlyWidget {w {on yes} {popup yes}} {my TextCommandForChange $w "" $on
if {$popup} {my makePopup $w $on yes}
return}
method GetOutputValues {} {foreach aop $_pav(widgetopts) {lassign $aop optnam vn v1 v2
switch -glob -- $optnam {-lbxname* {lassign [$vn curselection] s1
if {$s1 eq {}} {set s1 0}
set w [string range $vn [string last . $vn]+1 end]
if {$optnam eq "-lbxnameALL"} {set $v1 [list $s1 [$vn get $s1] [set $v1]]
} else {set $v1 [$vn get $s1]}}
-retpos {lassign [split $v2 :] p1 p2
set val1 [set $v1]
foreach aop2 $_pav(widgetopts) {lassign $aop2 optnam2 vn2 lst2
if {$optnam2=="-list" && $vn==$vn2} {foreach val2 $lst2 {if {$val1 == $val2} {set p1 0
set p2 end
break}}
break}}
set $v1 [string range $val1 $p1 $p2]}}}
return}
method focusNext {w wnext {wnext0 ""}} {if {$wnext eq ""} return
if {[winfo exist $wnext]} {focus $wnext
return}
set ws $wnext
if {$wnext0 eq ""} {catch {set wnext [subst $wnext]}
if {![string match "my *" $wnext]} {catch {set wnext [my [my ownWName $wnext]]}}
my focusNext $w $wnext $wnext
} else {set wnext $wnext0}
foreach wn [winfo children $w] {my focusNext $wn $wnext $wnext0
if {[string match "*.$wnext" $wn] || [string match "*.$ws" $wn]} {focus $wn
return}}
return}
method AdditionalCommands {w wdg attrsName} {upvar $attrsName attrs
set addcomms {}
if {[set tooltip [::apave::getOption -tooltip {*}$attrs]] ne ""} {if {[set i [string first $_pav(edge) $tooltip]]>=0} {set tooltip [string range $tooltip 1 end-1]
set tattrs [string range $tooltip [incr i -1]+[string length $_pav(edge)] end]
set tooltip "{[string range $tooltip 0 $i-1]}"
} else {set tattrs ""}
lappend addcomms [list baltip::tip $wdg $tooltip {*}$tattrs]
lappend ::apave::_AP_VARS(TIMW) $wdg
set attrs [::apave::removeOptions $attrs -tooltip]}
if {[::apave::getOption -ro {*}$attrs] ne "" || [::apave::getOption -readonly {*}$attrs] ne ""} {lassign [::apave::parseOptions $attrs -ro 0 -readonly 0] ro readonly
lappend addcomms [list my readonlyWidget $wdg [expr $ro||$readonly]]
set attrs [::apave::removeOptions $attrs -ro -readonly]}
if {[set wnext [::apave::getOption -tabnext {*}$attrs]] ne ""} {set wnext [string trim $wnext "\{\}"]
if {$wnext eq "0"} {set wnext $wdg}
after idle [list if "\[winfo exists $wdg\]" [list bind $wdg <Key> [list if {{%K} == {Tab}} "[self] focusNext $w $wnext ; break" ] ] ]
set attrs [::apave::removeOptions $attrs -tabnext]}
return $addcomms}
method DefineWidgetKeys {wname widget} {if {[string first "STD" $wname]>0} return
if {($widget in {ttk::entry entry})} {bind $wname <Up> [list if {$::tcl_platform(platform) == "windows"} [list event generate $wname <Shift-Tab> ] else [list event generate $wname <Key> -keysym ISO_Left_Tab] ]
bind $wname <Down> [list event generate $wname <Key> -keysym Tab]}
if {$widget in {ttk::button button ttk::checkbutton checkbutton ttk::radiobutton radiobutton "my tk_optionCascade"}} {foreach k {<Up> <Left>} {bind $wname $k [list if {$::tcl_platform(platform) == "windows"} [list event generate $wname <Shift-Tab> ] else [list event generate $wname <Key> -keysym ISO_Left_Tab] ]}
foreach k {<Down> <Right>} {bind $wname $k [list event generate $wname <Key> -keysym Tab]}}
if {$widget in {ttk::button button ttk::checkbutton checkbutton ttk::radiobutton radiobutton}} {foreach k {<Return> <KP_Enter>} {bind $wname $k [list event generate $wname <Key> -keysym space]}}
if {$widget in {ttk::entry entry spinbox ttk::spinbox}} {foreach k {<Return> <KP_Enter>} {bind $wname $k [list + event generate $wname <Key> -keysym Tab]}}}
method Window {w inplists} {set lwidgets [list]
foreach lst $inplists {if {[string index [string index $lst 0] 0] ne "#"} {lappend lwidgets $lst}}
set lused [list]
set lwlen [llength $lwidgets]
for {set i 0} {$i < $lwlen} {} {set lst1 [lindex $lwidgets $i]
if {[my Replace_Tcl i lwlen lwidgets {*}$lst1] ne ""} {incr i}}
set lwlen [llength $lwidgets]
for {set i 0} {$i < $lwlen} {} {set lst1 [lindex $lwidgets $i]
set lst1 [my Replace_chooser w i lwlen lwidgets {*}$lst1]
if {[set lst1 [my Replace_bar w i lwlen lwidgets {*}$lst1]] eq ""} {incr i
continue}
lassign $lst1 name neighbor posofnei rowspan colspan options1 attrs1
set prevw $name
lassign [my NormalizeName name i lwidgets] name wname
lassign [my NormalizeName neighbor i lwidgets] neighbor
set wname [my MakeWidgetName $w $wname]
if {$colspan=={} || $colspan=={-}} {set colspan 1
if {$rowspan=={} || $rowspan=={-}} {set rowspan 1}}
set options [uplevel 2 subst -nocommand -nobackslashes [list $options1]]
set attrs [uplevel 2 subst -nocommand -nobackslashes [list $attrs1]]
lassign [my widgetType $wname $options $attrs] widget options attrs nam3 dsbl
if { !($widget == "" || [winfo exists $widget])} {set attrs [my GetAttrs $attrs $nam3 $dsbl]
set attrs [my ExpandOptions $attrs]
if {$widget in {"ttk::scrollbar" "scrollbar"}} {set neighbor [lindex [my LowercaseWidgetName $neighbor] 0]
if {$posofnei=="L"} {$w.$neighbor config -yscrollcommand "$wname set"
set attrs "$attrs -com \\\{$w.$neighbor yview\\\}"
append options " -side right -fill y -after $w.$neighbor"
} elseif {$posofnei=="T"} {$w.$neighbor config -xscrollcommand "$wname set"
set attrs "$attrs -com \\\{$w.$neighbor xview\\\}"
append options " -side bottom -fill x -before $w.$neighbor"}}
my Pre attrs
set addcomms [my AdditionalCommands $w $wname attrs]
eval $widget $wname {*}$attrs
my Post $wname $attrs
foreach acm $addcomms { eval {*}$acm }
my DefineWidgetKeys $wname $widget}
if {$neighbor eq "-" || $row < 0} {set row [set col 0]}
if {$neighbor ne "#"} {set options [my GetIntOptions $w $options $row $rowspan $col $colspan]
set pack [string trim $options]
if {[string first "add" $pack]==0} {set comm "[winfo parent $wname] add $wname [string range $pack 4 end]"
{*}$comm
} elseif {[string first "pack" $pack]==0} {set opts [string trim [string range $pack 5 end]]
if {[string first "forget" $opts]==0} {pack forget {*}[string range $opts 6 end]
} else {pack $wname {*}$opts}
} else {grid $wname -row $row -column $col -rowspan $rowspan -columnspan $colspan -padx 1 -pady 1 {*}$options}}
lappend lused [list $name $row $col $rowspan $colspan]
if {[incr i] < $lwlen} {lassign [lindex $lwidgets $i] name neighbor posofnei
if {$neighbor=="+"} {set neighbor $prevw}
set neighbor [lindex [my LowercaseWidgetName $neighbor] 0]
set row -1
foreach cell $lused {lassign $cell uname urow ucol urowspan ucolspan
if {[lindex [my LowercaseWidgetName $uname] 0] eq $neighbor} {set col $ucol
set row $urow
if {$posofnei == "T" || $posofnei == ""} {incr row $urowspan
} elseif {$posofnei == "L"} {incr col $ucolspan}}}}}
return $lwidgets}
method paveWindow {args} {set res [list]
set wmain [set wdia ""]
foreach {w lwidgets} $args {lappend res {*}[my Window $w $lwidgets]
lappend _pav(lwidgets) $lwidgets
if {[string match *.dia $w]} {set wdia $w
} elseif {[set _ [string first .dia. $w]]>0} {set wdia [string range $w 0 $_+3]
} else {set wmain .[lindex [split $w .] 1]}}
if {[winfo exists $wdia]} {::apave::initPOP $wdia} elseif {[winfo exists $wmain]} {::apave::initPOP $wmain}
return $res}
method window {args} {return [uplevel 1 [list [self] paveWindow {*}$args]]}
method showModal {win args} {set shal [::apave::shadowAllowed 0]
if {[::apave::getOption -themed {*}$args] in {"" "0"} && [my csCurrent] != [apave::cs_Non]} {my csSet [my csCurrent] $win -doit}
::apave::setAppIcon $win
lassign  [my csGet] - - - bg
$win configure -bg $bg
set _pav(modalwin) $win
set root [winfo parent $win]
if {[set centerme [::apave::getOption -centerme {*}$args]] ne {}} {;
if {[winfo exist $centerme]} {set root $centerme}}
if {[set ontop [::apave::getOption -ontop {*}$args]] eq {}} {set ontop no}
if {[set modal [::apave::getOption -modal {*}$args]] eq {}} {set modal yes}
set args [::apave::removeOptions $args -centerme -ontop -modal]
array set opt [list -focus "" -onclose "" -geometry "" -decor 0 -root $root {*}$args]
lassign [split [wm geometry $root] x+] rw rh rx ry
if {! $opt(-decor)} {wm transient $win $root}
if {$opt(-onclose) == ""} {set opt(-onclose) [list set ${_pav(ns)}PN::AR($win) 0]
} else {set opt(-onclose) [list $opt(-onclose) ${_pav(ns)}PN::AR($win)]}
set opt(-onclose) "::apave::paveObj EXPORT CleanUps $win; $opt(-onclose)"
wm protocol $win WM_DELETE_WINDOW $opt(-onclose)
set inpgeom $opt(-geometry)
if {$inpgeom == ""} {set opt(-geometry) [my CenteredXY $rw $rh $rx $ry [winfo reqwidth $win] [winfo reqheight $win]]}
if {[set pp [string first + $opt(-geometry)]]>=0} {wm geometry $win [string range $opt(-geometry) $pp end]}
if {$opt(-focus) == ""} {set opt(-focus) $win}
set ${_pav(ns)}PN::AR($win) "-"
bind $win <Escape> $opt(-onclose)
update
if {$inpgeom == ""} {set w [winfo width $win]
set h [winfo height $win]
if {($h/2-$ry-$rh/2)>30 && $root != "."} {wm geometry $win [my CenteredXY $rw $rh $rx $ry $w $h]
} else {::tk::PlaceWindow $win widget $root}
} else {wm geometry $win $inpgeom}
if {[::iswindows]} {if {[wm attributes $win -alpha] < 0.1} {wm attributes $win -alpha 1.0}
} else {catch {wm deiconify $win ; raise $win}}
wm minsize $win [set w [winfo width $win]] [set h [winfo height $win]]
bind $win <Configure> "[namespace current]::WinResize $win"
if {$ontop} {wm attributes $win -topmost 1}
after 50 [list if "\[winfo exist $opt(-focus)\]" "focus -force $opt(-focus)"]
::apave::modalsOpen [expr {[::apave::modalsOpen] + 1}]
if {![::iswindows]} {tkwait visibility $win}
if {$modal} {grab set $win}
tkwait variable ${_pav(ns)}PN::AR($win)
if {$modal} {grab release $win}
::apave::modalsOpen [expr {[::apave::modalsOpen] - 1}]
my GetOutputValues
::apave::shadowAllowed $shal
return [set [set _ ${_pav(ns)}PN::AR($win)]]}
method res {win {result "get"}} {if {[winfo exists $win.dia]} {set win $win.dia}
if {$result == "get"} {return [set ${_pav(ns)}PN::AR($win)]}
my CleanUps $win
return [set ${_pav(ns)}PN::AR($win) $result]}
method makeWindow {w ttl} {my CleanUps
set w [set wtop [string trimright $w .]]
set withfr [expr {[set pp [string last . $w]]>0 && [string match "*.fra" $w]}]
if {$withfr} {set wtop [string range $w 0 $pp-1]}
catch {destroy $wtop}
toplevel $wtop
if {[::iswindows]} {wm attributes $wtop -alpha 0.0
} else {wm withdraw $wtop}
if {$withfr} {pack [ttk::frame $w] -expand 1 -fill both}
wm title $wtop $ttl
return $wtop}
method textLink {w idx} {if {[info exists ::apave::__TEXTLINKS__($w)]} {return [lindex $::apave::__TEXTLINKS__($w) $idx]}
return ""}
method displayText {w conts {pos 1.0}} {if { [set state [$w cget -state]] ne "normal"} {$w configure -state normal}
$w replace 1.0 end $conts
$w edit reset; $w edit modified no
::tk::TextSetCursor $w $pos
if { $state ne "normal" } { $w configure -state $state }
return}
method displayTaggedText {w contsName {tags ""}} {upvar $contsName conts
if {$tags eq ""} {my displayText $w $conts
return}
if { [set state [$w cget -state]] ne "normal"} {$w configure -state normal}
set taglist [set tagpos [set taglen [list]]]
foreach tagi $tags {lassign $tagi tag
lappend tagpos 0
lappend taglen [string length $tag]}
set tLen [llength $tags]
set disptext ""
set irow 1
foreach line [split $conts \n] {if {$irow > 1} {append disptext \n}
set newline ""
while 1 {set p [string first \< $line]
if {$p < 0} {break}
append newline [string range $line 0 $p-1]
set line [string range $line $p end]
set i 0
set nrnc $irow.[string length $newline]
foreach tagi $tags pos $tagpos len $taglen {lassign $tagi tag
if {[string first "\<$tag\>" $line]==0} {if {$pos ne "0"} {error "\npaveme.tcl: mismatched \<$tag\> in line $irow.\n"}
lset tagpos $i $nrnc
set line [string range $line $len+2 end]
break
} elseif {[string first "\</$tag\>" $line]==0} {if {$pos == "0"} {error "\npaveme.tcl: mismatched \</$tag\> in line $irow.\n"}
lappend taglist [list $i $pos $nrnc]
lset tagpos $i 0
set line [string range $line $len+3 end]
break}
incr i}
if {$i == $tLen} {append newline [string index $line 0]
set line [string range $line 1 end]}}
append disptext $newline $line
incr irow}
$w replace 1.0 end $disptext
foreach tagi $tags {lassign $tagi tag opts
if {![string match "link*" $tag]} {$w tag config $tag {*}$opts}}
lassign [my csGet] fg fg2 bg bg2
set lfont [$w cget -font]
catch {set lfont [font configure $lfont]}
foreach {o v} [my initLinkFont] {dict set lfont $o $v}
set ::apave::__TEXTLINKS__($w) [list]
for {set it [llength $taglist]} {[incr it -1]>=0} {} {set tagli [lindex $taglist $it]
lassign $tagli i p1 p2
lassign [lindex $tags $i] tag opts
if {[string match "link*" $tag] && [set ist [lsearch -exact -index 0 $tags $tag]]>=0} {set txt [$w get $p1 $p2]
set lab ${w}l[incr ::apave::__linklab__]
ttk::label $lab -text $txt -font $lfont -foreground $fg -background $bg
set ::apave::__TEXTLINKS__($w) [linsert $::apave::__TEXTLINKS__($w) 0 $lab]
$w delete $p1 $p2
$w window create $p1 -window $lab
set v [lindex $tags $ist 1]
my makeLabelLinked $lab $v $fg $bg $fg2 $bg2
} else {$w tag add $tag $p1 $p2}}
$w edit reset; $w edit modified no
if { $state ne "normal" } { $w configure -state $state }
return}}
#by trimmer
