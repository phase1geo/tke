###########################################################################
package require Tk
namespace eval ::apave {;
variable cursorwidth 1
variable _Defaults [dict create bts {{} {}} but {{} {}} buT {{} {-width -20 -pady 1}} can {{} {}} chb {{} {}} chB {{} {-relief sunken -padx 6 -pady 2}} cbx {{} {}} fco {{} {}} ent {{} {}} enT {{} {-insertwidth $::apave::cursorwidth -insertofftime 250 -insertontime 750}} fil {{} {}} fis {{} {}} dir {{} {}} fon {{} {}} clr {{} {}} dat {{} {}} sta {{} {}} too {{} {}} fra {{} {}} ftx {{} {}} frA {{} {}} gut {{} {-width 0 -highlightthickness 1}} lab {{-sticky w} {}} laB {{-sticky w} {}} lfr {{} {}} lfR {{} {-relief groove}} lbx {{} {-activestyle none -exportselection 0 -selectmode browse}} flb {{} {}} meb {{} {}} meB {{} {}} nbk {{} {}} opc {{} {}} pan {{} {}} pro {{} {}} rad {{} {}} raD {{} {-padx 6 -pady 2}} sca {{} {-orient horizontal -takefocus 0}} scA {{} {-orient horizontal -takefocus 0}} sbh {{-sticky ew} {-orient horizontal -takefocus 0}} sbH {{-sticky ew} {-orient horizontal -takefocus 0}} sbv {{-sticky ns} {-orient vertical -takefocus 0}} sbV {{-sticky ns} {-orient vertical -takefocus 0}} scf {{} {}} seh {{-sticky ew} {-orient horizontal -takefocus 0}} sev {{-sticky ns} {-orient vertical -takefocus 0}} siz {{} {}} spx {{} {}} spX {{} {}} tbl {{} {-selectborderwidth 1 -highlightthickness 2 -labelcommand tablelist::sortByColumn -stretch all -showseparators 1}} tex {{} {-undo 1 -maxundo 0 -highlightthickness 2 -insertofftime 250 -insertontime 750 -insertwidth $::apave::cursorwidth -wrap word
-selborderwidth 1}} tre {{} {}} "h_" {{-sticky ew -csz 3 -padx 3} {}} "v_" {{-sticky ns -rsz 3 -pady 3} {}}]
variable apaveDir [file dirname [info script]]
variable _AP_ICO { none folder OpenFile SaveFile saveall print font color \
    date help home misc terminal run tools file find replace other view \
    categories actions config pin cut copy paste plus minus add delete \
    change diagram box trash double more undo redo up down previous next \
    previous2 next2 upload download tag tagoff tree lock light restricted \
    attach share mail www map umbrella gulls sound heart clock people info \
err warn ques retry yes no ok cancel exit }
variable _AP_IMG;  array set _AP_IMG [list]
variable _AP_VARS; array set _AP_VARS [list]
set _AP_VARS(.,SHADOW) 0
set _AP_VARS(.,MODALS) 0
set _AP_VARS(TIMW) [list]
set _AP_VARS(MODALWIN) [list]
set _AP_VARS(LINKFONT) [list -underline 1]
set _AP_VARS(INDENT) "  "
set _AP_VARS(KEY,CtrlD) [list Control-D Control-d]
set _AP_VARS(KEY,CtrlY) [list Control-Y Control-y]
set _AP_VARS(KEY,AltQ) [list Alt-Q Alt-q]
set _AP_VARS(KEY,AltW) [list Alt-W Alt-w]
variable _AP_VISITED;  array set _AP_VISITED [list]
set _AP_VISITED(ALL) [list]
variable UFF "\uFFFF"
variable _OBJ_ ""
variable MC_NS ""
proc WindowStatus {w name {val ""} {defval ""}} {variable _AP_VARS
if {$val eq ""} {if {[info exist _AP_VARS($w,$name)]} {return $_AP_VARS($w,$name)}
return $defval}
return [set _AP_VARS($w,$name) $val]}
proc IntStatus {w {name "status"} {val ""}} {set old [WindowStatus $w $name "" 0]
if {$val ne ""} {WindowStatus $w $name $val 1}
return $old}
proc shadowAllowed {{val ""} {w .}} {return [IntStatus $w SHADOW $val]}
proc infoWindow {{val ""} {w .} {modal no} {var ""} {regist no}} {variable _AP_VARS
if {$modal || $regist} {set info [list $w $var $modal]
set i [lsearch -exact $_AP_VARS(MODALWIN) $info]
if {$regist} {lappend _AP_VARS(MODALWIN) $info
} else {catch {set _AP_VARS(MODALWIN) [lreplace $_AP_VARS(MODALWIN) $i $i]}}
set res [IntStatus . MODALS $val]
} else {set res [IntStatus . MODALS]}
return $res}
proc infoFind {w modal} {variable _AP_VARS
foreach winfo [lrange $_AP_VARS(MODALWIN) 1 end] {incr i
lassign $winfo w1 var1 modal1
if {[winfo exists $w1]} {if {[string first $w $w1]==0 && $modal==$modal1} {return $w1}
} else {catch {set _AP_VARS(MODALWIN) [lreplace $_AP_VARS(MODALWIN) $i $i]}}}
return ""}
proc endWM {args} {variable _AP_VARS
if {[llength $args]} {return [expr {[info exists _AP_VARS(EOP)]}]}
while {1} {set i [expr {[llength $_AP_VARS(MODALWIN)] - 1}]
if {$i>0} {lassign [lindex $_AP_VARS(MODALWIN) $i] w var
if {[winfo exists $w]} {set $var 0}
catch {set _AP_VARS(MODALWIN) [lreplace $_AP_VARS(MODALWIN) $i $i]}
} else {break}}
set _AP_VARS(EOP) yes}
proc iconImage {{icon ""} {iconset "small"}} {variable _AP_IMG
variable _AP_ICO
if {$icon eq ""} {return $_AP_ICO}
proc imagename {icon} {   # Get a defined icon's image name
return _AP_IMG(img$icon)}
variable apaveDir
if {[array size _AP_IMG] == 0} {source [file join $apaveDir apaveimg.tcl]
if {$iconset ne "small"} {foreach ic $_AP_ICO {set _AP_IMG($ic-small) [set _AP_IMG($ic)]}
if {$iconset eq "middle"} {source [file join $apaveDir apaveimg2.tcl]
} else {source [file join $apaveDir apaveimg2.tcl]}}
foreach ic $_AP_ICO {if {[catch {image create photo [imagename $ic] -data [set _AP_IMG($ic)]}]} {image create photo [imagename $ic] -data [set _AP_IMG(none)]
} elseif {$iconset ne "small"} {image create photo [imagename $ic-small] -data [set _AP_IMG($ic-small)]}}}
if {$icon eq "-init"} {return $_AP_ICO}
if {$icon ni $_AP_ICO} {set icon [lindex $_AP_ICO 0]}
if {$iconset eq "small" && "_AP_IMG(img$icon-small)" in [image names]} {set icon $icon-small}
return [imagename $icon]}
proc iconData {{icon "info"} {iconset ""}} {variable _AP_IMG
iconImage -init
if {$iconset ne "" && "_AP_IMG(img$icon-$iconset)" in [image names]} {return [set _AP_IMG($icon-$iconset)]}
return [set _AP_IMG($icon)]}
proc setAppIcon {win {winicon ""}} {set appIcon ""
if {$winicon ne ""} {if {[catch {set appIcon [image create photo -data $winicon]}]} {catch {set appIcon [image create photo -file $winicon]}}}
if {$appIcon ne ""} {wm iconphoto $win -default $appIcon}}
proc eventOnText {w ev} {catch {::hl_tcl::my::MemPos $w}
event generate $w $ev}
proc getTextHotkeys {key} {variable _AP_VARS
if {![info exist _AP_VARS(KEY,$key)]} {return [list]}
set keys $_AP_VARS(KEY,$key)
if {[llength $keys]==1} {if {[set i [string last - $keys]]>0} {set lt [string range $keys $i+1 end]
if {[string length $lt]==1} {set keys "[string range $keys 0 $i][string toupper $lt]"
lappend keys "[string range $keys 0 $i][string tolower $lt]"}}}
return $keys}
proc setTextHotkeys {key value} {variable _AP_VARS
set _AP_VARS(KEY,$key) $value}
proc setTextIndent {len} {variable _AP_VARS
set _AP_VARS(INDENT) [string repeat " " $len]}
proc KeyAccelerator {acc} {set acc [lindex $acc 0]
return [string map {Control Ctrl - + bracketleft [ bracketright ]} $acc]}
proc obj {com args} {variable _OBJ_
if {$_OBJ_ eq ""} {set _OBJ_ [::apave::APaveInput new]}
if {[set exported [expr {$com eq "EXPORT"}]]} {set com [lindex $args 0]
set args [lrange $args 1 end]
oo::objdefine $_OBJ_ "export $com"}
set res [$_OBJ_ $com {*}$args]
if {$exported} {oo::objdefine $_OBJ_ "unexport $com"}
return $res}}
source [file join $::apave::apaveDir obbit.tcl]
oo::class create ::apave::APave {mixin ::apave::ObjectTheming
variable _pav
constructor {{cs -2} args} {array set _pav [list]
set _pav(ns) [namespace current]::
set _pav(lwidgets) [list]
set _pav(moveall) 0
set _pav(tonemoves) 1
set _pav(initialcolor) ""
set _pav(modalwin) "."
set _pav(fgbut) [ttk::style lookup TButton -foreground]
set _pav(bgbut) [ttk::style lookup TButton -background]
set _pav(fgtxt) [ttk::style lookup TEntry -foreground]
set _pav(prepost) [list]
set _pav(widgetopts) [list]
set _pav(edge) "@@"
if {$_pav(fgtxt) in {"black" "#000000"}} {set _pav(bgtxt) white
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
method checkXY {w h x y} {set scrw [expr [winfo screenwidth .] - 12]
set scrh [expr {[winfo screenheight .] - 36}]
if {($x + $w) > $scrw } {set x [expr {$scrw - $w}]}
if {($y + $h) > $scrh } {set y [expr {$scrh - $h}]}
return +$x+$y}
method CenteredXY {rw rh rx ry w h} {set x [expr {max(0, $rx + ($rw - $w) / 2)}]
set y [expr {max(0,$ry + ($rh - $h) / 2)}]
return [my checkXY $w $h $x $y]}
method ownWName {name} {return [lindex [split $name .] end]}
method parentWName {name} {return [string range $name 0 [string last . $name]-1]}
method themePopup {mnu} {return}
method NonTtkTheme {win} {return}
method NonTtkStyle {typ {dsbl 0}} {return}
method iconA {icon {iconset "small"}} {return "-image [::apave::iconImage $icon $iconset] -compound left"}
method configure {args} {foreach {optnam optval} $args { set _pav($optnam) $optval }
return}
method defaultAttrs {{typ ""} {opt ""} {atr ""}} {if {$typ eq ""} {return $::apave::_Defaults}
set def1 [subst [dict get $::apave::_Defaults $typ]]
if {"$opt$atr" eq ""} {return $def1}
lassign $def1 defopts defattrs
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
if {$varopt eq "-lvar"} {lassign [::apave::extractOptions attrs -values "" -ALL 0] iv a
if {[string is boolean -strict $a] && $a} {set all "ALL"}
lappend _pav(widgetopts) "-lbxname$all $wnamefull $vn"}
if {$rp ne ""} {if {$all ne ""} {set rp "0:end"}
lappend _pav(widgetopts) "-retpos $wnamefull $vn $rp"}}
if {$iv ne ""} { set $vn $iv }
return [::apave::removeOptions $attrs -retpos -inpval]}
method FCfieldValues {wnamefull attrs} {proc readFCO {fname} {if {$fname eq ""} {
set retval {{}}
} else {
set retval {}
foreach ln [split [::apave::readTextFile $fname "" 1] \n] {set ln [string map [list \\ \\\\ \{ \\\{ \} \\\}] $ln]
if {$ln ne {}} {lappend retval $ln}}}
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
if {[string match -nocase $ic1 $txt] || [string match -nocase but$ic1 $w] || ($ic2 ne "" && ( [string match -nocase but$ic2 $w] || [string match -nocase $ic2 $txt]))} {append attrs " [my iconA $ic1 small]"
break}}
return}
method widgetType {wnamefull options attrs} {set disabled [expr {[::apave::getOption -state {*}$attrs] eq {disabled}}]
set pack $options
set name [my ownWName $wnamefull]
set nam3 [string tolower [string index $name 0]][string range $name 1 2]
if {[string index $nam3 1] eq "_"} {set k [string range $nam3 0 1]} {set k $nam3}
lassign [dict get $::apave::_Defaults $k] defopts defattrs
set options "[subst $defopts] $options"
set attrs "[subst $defattrs] $attrs"
switch -glob -- $nam3 {bts {set widget ttk::frame
if {![info exists ::bartabs::NewBarID]} {package require bartabs}
set attrs "-bartabs {$attrs}"}
but {set widget ttk::button
my AddButtonIcon $name attrs}
buT {set widget button
my AddButtonIcon $name attrs}
can {set widget canvas}
chb {set widget ttk::checkbutton}
chB {set widget checkbutton}
cbx - fco {set widget ttk::combobox
if {$nam3 eq {fco}} {set attrs [my FCfieldValues $wnamefull $attrs]}
set attrs [my FCfieldAttrs $wnamefull $attrs -tvar]}
ent {set widget ttk::entry}
enT {set widget entry}
fil -
fis -
dir -
fon -
clr -
dat -
sta -
too -
fra {set widget ttk::frame}
frA {set widget frame
if {$disabled} {set attrs [::apave::removeOptions $attrs -state]}}
ftx {set widget ttk::labelframe}
gut {set widget canvas}
lab {set widget ttk::label
if {[::apave::extractOptions attrs -state normal] eq "disabled"} {set grey [lindex [my csGet] 8]
set attrs "-foreground $grey $attrs"}
lassign [::apave::parseOptions $attrs -link {} -style {} -font {}] cmd style font
if {$cmd ne {}} {set attrs "-linkcom {$cmd} $attrs"
set attrs [::apave::removeOptions $attrs -link]}
if {$style eq {} && $font eq {}} {set attrs "-font {$::apave::FONTMAIN} $attrs"
} elseif {$style ne {}} {set attrs [::apave::removeOptions $attrs -style]
set attrs "[ttk::style configure $style] $attrs"}}
laB {set widget label}
lfr {set widget ttk::labelframe}
lfR {set widget labelframe
if {$disabled} {set attrs [::apave::removeOptions $attrs -state]}}
lbx - flb {set widget listbox
if {$nam3 eq {flb}} {set attrs [my FCfieldValues $wnamefull $attrs]}
set attrs "[my FCfieldAttrs $wnamefull $attrs -lvar]"
set attrs "[my ListboxesAttrs $wnamefull $attrs]"
my AddPopupAttr $wnamefull attrs -entrypop 1}
meb {set widget ttk::menubutton}
meB {set widget menubutton}
nbk {set widget ttk::notebook
set attrs "-notebazook {$attrs}"}
opc {;
;

set widget {my tk_optionCascade}
set imax [expr {min(4,[llength $attrs])}]
for {set i 0} {$i<$imax} {incr i} {set atr [lindex $attrs $i]
if {$i!=1} {lset attrs $i \{$atr\}
} elseif {[llength $atr]==1 && [info exist $atr]} {lset attrs $i [set $atr]}}}
pan {set widget ttk::panedwindow
if {[string first -w $attrs]>-1 && [string first -h $attrs]>-1} {set attrs "-propagate {$options} $attrs"}}
pro {set widget ttk::progressbar}
rad {set widget ttk::radiobutton}
raD {set widget radiobutton}
sca {set widget ttk::scale}
scA {set widget scale}
sbh {set widget ttk::scrollbar}
sbH {set widget scrollbar}
sbv {set widget ttk::scrollbar}
sbV {set widget scrollbar}
scf {if {![namespace exists ::apave::sframe]} {namespace eval ::apave {source [file join $::apave::apaveDir sframe.tcl]}};

set widget {my scrolledFrame}}
seh {set widget ttk::separator}
sev {set widget ttk::separator}
siz {set widget ttk::sizegrip}
spx - spX {if {$nam3 eq {spx}} {set widget "ttk::spinbox"} {set widget "spinbox"}
lassign [::apave::parseOptions $attrs -command "" -from "" -to "" ] cmd from to
set attrs "-onReturn {$::apave::UFF{$cmd} {$from} {$to}$::apave::UFF} $attrs"}
tbl {package require tablelist
set widget tablelist::tablelist
set attrs "[my FCfieldAttrs $wnamefull $attrs -lvar]"
set attrs "[my ListboxesAttrs $wnamefull $attrs]"}
tex {set widget text
if {[::apave::getOption -textpop {*}$attrs] eq {}} {my AddPopupAttr $wnamefull attrs -textpop [expr {[::apave::getOption -rotext {*}$attrs] ne {}}] -- disabled}
lassign [::apave::parseOptions $attrs -ro {} -readonly {} -rotext {} -gutter {} -gutterwidth 5 -guttershift 6] r1 r2 r3 g1 g2 g3
set b1 [expr [string is boolean -strict $r1]]
set b2 [expr [string is boolean -strict $r2]]
if {($b1 && $r1) || ($b2 && $r2) || ($r3 ne {} && !($b1 && !$r1) && !($b2 && !$r2))} {set attrs "-takefocus 0 $attrs"}
set attrs [::apave::removeOptions $attrs -gutter -gutterwidth -guttershift]
if {$g1 ne {}} {set attrs "$attrs -gutter {-canvas $g1 -width $g2 -shift $g3}"}}
tre {set widget ttk::treeview}
h_* {set widget ttk::frame}
v_* {set widget ttk::frame}
default {set widget ""}}
set attrs [my GetMC $attrs]
if {$nam3 in {cbx ent enT fco spx spX}} {;
my AddPopupAttr $wnamefull attrs -entrypop 0 readonly disabled}
if {[string first "pack" [string trimleft $pack]]==0} {set options $pack}
set options [string trim $options]
set attrs   [list {*}$attrs]
return [list $widget $options $attrs $nam3 $disabled]}
method MC {msg} {set ::apave::_MC_TEXT_ [string trim $msg \{\}]
if {$::apave::MC_NS ne ""} {namespace eval $::apave::MC_NS {set ::apave::_MC_TEXT_ [msgcat::mc $::apave::_MC_TEXT_]}
} else {set ::apave::_MC_TEXT_ [msgcat::mc $::apave::_MC_TEXT_]}
return $::apave::_MC_TEXT_}
method GetMC {attrs} {lassign [::apave::extractOptions attrs -t "" -text ""] t text
if {$t ne "" || $text ne ""} {if {$text eq ""} {set text $t}
set attrs [dict set attrs -t [my MC $text]]}
return $attrs}
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
lassign [::apave::extractOptions mbopts -tip {} -tooltip {} -com {} -command {}] tip tip2 com com2
if {$tip eq {}} {set tip $tip2}
if {$com eq {}} {set com $com2}
if {$com ne {}} {lappend args -command $com}
ttk::menubutton $w -menu $w.m -text [set $vname] -style TMenuButtonWest {*}$mbopts
if {$tip ne {}} {set tip [my MC $tip]
catch {::baltip tip $w $tip}}
menu $w.m -tearoff 0
my OptionCascade_add $w.m $vname $items $precom {*}$args
trace var $vname w "$w config -text \"\[[self] optionCascadeText \${$vname}\]\" ;\#"
lappend ::apave::_AP_VARS(_TRACED_$w) $vname
return $w.m}
method OptionCascade_add {w vname argl precom args} {set n [set colbreak 0]
foreach arg $argl {if {$arg eq {--}} {$w add separator
} elseif {$arg eq {|}} {if {[tk windowingsystem] ne {aqua}} { set colbreak 1 }
continue
} elseif {[llength $arg] == 1} {set label [my optionCascadeText [join $arg]]
if {$precom eq {}} {
set adds {}
} else {set adds [eval {*}[string map [list \$ \\\$ \[ \\\[] [string map [list %a $label] $precom]]]}
$w add radiobutton -label $label -variable $vname {*}$args {*}$adds
} else {set child [menu $w.[incr n] -tearoff 0]
$w add cascade -label [lindex $arg 0] -menu $child
my OptionCascade_add $child $vname [lrange $arg 1 end] $precom {*}$args}
if $colbreak {$w entryconfigure end -columnbreak 1
set colbreak 0}}
return}
method scrolledFrame {w args} {lassign [::apave::extractOptions args -toplevel no -anchor center -mode both] tl anc mode
::apave::sframe new $w -toplevel $tl -anchor $anc -mode $mode
set path [::apave::sframe content $w]
return $path}
method ParentOpt {{w "."}} {if {$_pav(modalwin) eq "."} {set wpar $w} {set wpar $_pav(modalwin)}
return "-parent $wpar"}
method colorChooser {tvar args} {if {$_pav(initialcolor) eq "" && $::tcl_platform(platform) eq "unix"} {source [file join $::apave::apaveDir pickers color clrpick.tcl]}
if {[set _ [string trim [set $tvar]]] ne ""} {set ic $_
set _ [. cget -background]
if {[catch {. configure -background $ic}]} {set ic "#$ic"
if {[catch {. configure -background $ic}]} {set ic black}}
set _pav(initialcolor) $ic
. configure -background $_
} else {set _pav(initialcolor) black}
if {[catch {lassign [tk_chooseColor -moveall $_pav(moveall) -tonemoves $_pav(tonemoves) -initialcolor $_pav(initialcolor) {*}$args] res _pav(moveall) _pav(tonemoves)}]} {set res [tk_chooseColor -initialcolor $_pav(initialcolor) {*}$args]}
if {$res ne ""} {set _pav(initialcolor) [set $tvar $res]}
return $res}
method fontChooser {tvar args} {proc [namespace current]::applyFont {font} "
      set $tvar \[font actual \$font\]"
set font [set $tvar]
if {$font eq {}} {catch {font create fontchoose {*}$::apave::FONTMAIN}
} else {catch {font delete fontchoose}
catch {font create fontchoose {*}[font actual $font]}}
tk fontchooser configure -parent . -font fontchoose {*}[my ParentOpt] {*}$args -command [namespace current]::applyFont
set res [tk fontchooser show]
return $font}
method dateChooser {tvar args} {if {[info commands ::klnd::calendar] eq ""} {source [file join $::apave::apaveDir pickers klnd klnd.tcl]}
if {![catch {set ent [my [my ownWName [::apave::getOption -entry {*}$args]]]}]} {dict set args -entry $ent
set res [::klnd::calendar {*}$args -tvar $tvar -parent [winfo toplevel $ent]]
} else {set res [::klnd::calendar {*}$args -tvar $tvar]}
return $res}
method getWidChildren {wid treeName {init yes}} {upvar $treeName tree
if {$init} {set tree [list]}
foreach ch [winfo children $wid] {lappend tree $ch
my getWidChildren $ch $treeName no}}
method findWidPath {wid {mode "exact"} {visible yes}} {my getWidChildren . tree
if {$mode eq "exact"} {set i [lsearch -glob $tree "*.$wid"]
} else {set i [lsearch -glob $tree "*$wid*"]}
if {$i>-1} {return [lindex $tree $i]}
return ""}
method AuxSetChooserGeometry {vargeo parent widname} {set wchooser [lindex $parent 1].$widname
catch {lassign [set $vargeo] -> geom
if {[string match "*x*+*+*" $geom] && [::islinux]} {after idle "catch {wm geometry $wchooser $geom}"}}
return $wchooser}
method chooser {nchooser tvar args} {set isfilename 0
lassign [::apave::extractOptions args -ftxvar {} -tname {}] ftxvar tname
lassign [::apave::getProperty DirFilGeoVars] dirvar filvar
set vargeo [set dirgeo [set filgeo ""]]
set parent [my ParentOpt]
if {$dirvar ne {}} {set dirgeo [set $dirvar]}
if {$filvar ne {}} {set filgeo [set $filvar]}
if {$nchooser eq "ftx_OpenFile"} {set nchooser "tk_getOpenFile"}
set widname ""
set choosname $nchooser
if {$choosname in {"fontChooser" "colorChooser" "dateChooser"}} {set nchooser "my $choosname $tvar"
} elseif {$choosname in {"tk_getOpenFile" "tk_getSaveFile"}} {set vargeo $filvar
set widname [my AuxSetChooserGeometry $vargeo $parent __tk_filedialog]
if {[set fn [set $tvar]] eq ""} {set dn [pwd]} {set dn [file dirname $fn]}
set args "-initialfile \"$fn\" -initialdir \"$dn\" $parent $args"
incr isfilename
} elseif {$nchooser eq "tk_chooseDirectory"} {set vargeo $dirvar
set widname [my AuxSetChooserGeometry $vargeo $parent __tk_choosedir]
set args "-initialdir \"[set $tvar]\" $parent $args"
incr isfilename}
if {$::tcl_platform(platform) eq "unix" && $choosname ne "dateChooser"} {my themeExternal *.foc.* *f1.demo}
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
if {$vargeo ne {} && $widname ne {} && [::islinux]} {catch {set $vargeo [list $widname [wm geometry $widname]]}}
if {$tname ne {}} {set tname [my [my ownWName $tname]]
focus $tname
after idle [$tname selection range 0 end]}
return $res}
method fillGutter {txt {canvas ""} {width ""} {shift ""} args} {if {![winfo exists $txt]} return
if {$canvas eq ""} {event generate $txt <Configure>
return}
set oper [lindex $args 0 1]
if {![llength $args] || [lindex $args 0 4] eq "-elide" || $oper in {configure delete insert see yview}} {set i [$txt index @0,0]
set gcont [list]
while true {set dline [$txt dlineinfo $i]
if {[llength $dline] == 0} break
set height [lindex $dline 3]
set y [expr {[lindex $dline 1]}]
set linenum [format "%${width}d" [lindex [split $i "."] 0]]
set i [$txt index "$i +1 lines linestart"]
lappend gcont [list $y $linenum]}
lassign [my csGet] - - - bg - - - - fg
set cwidth [expr {$shift + [font measure apaveFontMono -displayof $txt [string repeat 0 $width]]}]
set newbg [expr {$bg ne [$canvas cget -background]}]
set newwidth [expr {$cwidth ne [$canvas cget -width]}]
set savedcont [namespace current]::gc$txt
if {![llength $args] || $newbg || $newwidth || ![info exists $savedcont] || $gcont != [set $savedcont]} {if {$newbg} {$canvas config -background $bg}
if {$newwidth} {$canvas config -width $cwidth}
$canvas delete all
foreach g $gcont {lassign $g y linenum
$canvas create text 2 $y -anchor nw -text $linenum -font apaveFontMono -fill $fg}
set $savedcont $gcont}}}
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
if {$filetypes ne {}} {set attrs1 [::apave::removeOptions $attrs1 -filetypes -takefocus]
lset args 6 $attrs1
append addattrs2 " -filetypes {$filetypes}"}
set an [set entname ""]
lassign [my LowercaseWidgetName $name] n
switch -glob -- [my ownWName $n] {"fil*" { set chooser "tk_getOpenFile" }
"fis*" { set chooser "tk_getSaveFile" }
"dir*" { set chooser "tk_chooseDirectory" }
"fon*" { set chooser "fontChooser" }
"dat*" { set chooser "dateChooser"; set entname "-entry " }
"ftx*" {set chooser [set view "ftx_OpenFile"]
if {$tvar ne "" && [info exist $tvar]} {append addattrs " -t {[set $tvar]}"}
set an tex
set txtnam [my Transname $an $name]}
"clr*" {set chooser "colorChooser"
lassign [::apave::extractOptions attrs1 -showcolor {}] showcolor
if {$showcolor eq {}} {set showcolor 1}
set showcolor [string is true -strict $showcolor]
set wpar "-parent $w"}
default {return $args}}
set inname [my MakeWidgetName $w $name $an]
set name $n
if {$view ne {}} {set tvname $inname
set inname [my WidgetNameFull $w $name]}
set tvar [set vv [set addopt ""]]
set attmp [list]
foreach {nam val} $attrs1 {if {$nam in {-title -parent -dateformat -weekday -modal -centerme}} {append addopt " $nam \{$val\}"
} else {lappend attmp $nam $val}}
set attrs1 $attmp
catch {array set a $attrs1; set tvar "-tvar [set vv $a(-tvar)]"}
catch {array set a $attrs1; set tvar "-tvar [set vv $a(-textvariable)]"}
if {$vv eq ""} {set vv [namespace current]::$name
set tvar "-tvar $vv"}
set ispack 0
if {![catch {set gm [lindex [lindex $lwidgets $i] 5]}]} {set ispack [expr [string first "pack" $gm]==0]}
if {$ispack} {set args [list $name - - - - "pack -expand 0 -fill x [string range $gm 5 end]" $addattrs]
} else {set args [list $name $neighbor $posofnei $rowspan $colspan "-st ew" $addattrs]}
lset lwidgets $i $args
if {$view ne {}} {append attrs1 " -callF2 $w.[my Transname buT $name]"
set tvar [::apave::getOption -tvar {*}$attrs1]
set attrs1 [::apave::removeOptions $attrs1 -tvar]
if {$tvar ne {} && [file exist [set $tvar]]} {set tcont [my SetContentVariable $tvar $tvname [my ownWName $name]]
set wpar "-ftxvar $tcont"
set $tcont [::apave::readTextFile [set $tvar]]
set attrs1 [::apave::putOption -rotext $tcont {*}$attrs1]}
set entf [list $txtnam - - - - "pack -side left -expand 1 -fill both -in $inname" "$attrs1"]
} else {set tname [my Transname Ent $name]
if {$entname ne ""} {append entname $tname}
append attrs1 " -callF2 {.ent .buT}"
append wpar " -tname $tname"
set entf [list $tname - - - - "pack -side left -expand 1 -fill x -in $inname" "$attrs1 $tvar"]}
set icon "folder"
foreach ic {OpenFile SaveFile font color date} {if {[string first $ic $chooser] >= 0} {set icon $ic; break}}
set com "[self] chooser $chooser \{$vv\} $addopt $wpar $addattrs2 $entname"
if {$view ne {}} {set anc n} {set anc center}
set butf [list [my Transname buT $name] - - - - "pack -side right -anchor $anc -in $inname -padx 2" "-com \{$com\} -compound none -image [::apave::iconImage $icon small] -font \{-weight bold -size 5\} -fg $_pav(fgbut) -bg $_pav(bgbut) $takefocus"]
if {$view ne {}} {set scrolh [list [my Transname sbh $name] $txtnam T - - "pack -in $inname" ""]
set scrolv [list [my Transname sbv $name] $txtnam L - - "pack -in $inname" ""]
set lwidgets [linsert $lwidgets [expr {$i+1}] $butf]
set lwidgets [linsert $lwidgets [expr {$i+2}] $entf]
set lwidgets [linsert $lwidgets [expr {$i+3}] $scrolv]
incr lwlen 3
set wrap [::apave::getOption -wrap {*}$attrs1]
if {$wrap eq "none"} {set lwidgets [linsert $lwidgets [expr {$i+4}] $scrolh]
incr lwlen}
} else {if {$chooser eq {colorChooser} && $showcolor} {set f0 [my Transname Lab $name]
set labf [list $f0 - - - - "pack -side right -in $inname -padx 2" "-t \{    \} -relief raised"]
lassign $entf f1 - - - - f2 f3
set com "[self] validateColorChoice $f0 $f1"
append f3 " -afteridle \"$com; bind \[string map \{.entclr .labclr\} %w\] <ButtonPress> \{eval \[string map \{.entclr .buTclr\} %w\] invoke\}\""
append f3 " -validate all -validatecommand \{$com\}"
set entf [list $f1 - - - - $f2 $f3]
set lwidgets [linsert $lwidgets [expr {$i+1}] $entf $butf $labf]
incr lwlen 3
} else {set lwidgets [linsert $lwidgets [expr {$i+1}] $entf $butf]
incr lwlen 2}}
return $args}
method validateColorChoice {lab ent} {set ent [my ownWName $ent]
set lab [my [my ownWName $lab]]
set val [[my $ent] get]
set tvar [[my $ent] cget -textvariable]
catch {$lab configure -background $val}
return yes}
method Replace_bar {r0 r1 r2 r3 args} {upvar 1 $r0 w $r1 i $r2 lwlen $r3 lwidgets
if {[catch {set winname [winfo toplevel $w]}]} {return $args}
lassign $args name neighbor posofnei rowspan colspan options1 attrs1
my MakeWidgetName $w $name
set name [lindex [my LowercaseWidgetName $name] 0]
set wpar ""
switch -glob -- [my ownWName $name] {men* {set typ menuBar}
too* {set typ toolBar}
sta* {set typ statusBar}
default {return $args}}
set attcur [list]
set namvar [list]
foreach {nam val} $attrs1 {if {$nam eq "-array"} {catch {set val [subst $val]}
set ind -1
foreach {v1 v2} $val {catch {set v1 [subst -nocommand -nobackslash $v1]}
catch {set v2 [subst -nocommand -nobackslash $v2]}
if {$name eq {menu}} {set v2 [list [my MC $v2]]}
lappend namvar [namespace current]::$typ[incr ind] $v1 $v2}
} else {lappend attcur $nam $val}}
if {$typ eq "menuBar"} {if {[set fillmenu [lindex $args 7]] ne ""} {after idle $fillmenu}
set args ""
} else {set ispack 0
if {![catch {set gm [lindex [lindex $lwidgets $i] 5]}]} {set ispack [expr [string first "pack" $gm]==0]}
if {$ispack} {set args [list $name - - - - "pack -expand 0 -fill x -side bottom [string range $gm 5 end]" $attcur]
} else {set args [list $name $neighbor $posofnei $rowspan $colspan "-st ew" $attcur]}
lset lwidgets $i $args}
set itmp $i
set k [set j [set j2 [set wasmenu 0]]]
foreach {nam v1 v2} $namvar {if {$v1 eq "h_"} {set ntmp [my Transname fra ${name}[incr j2]]
set wid1 [list $ntmp - - - - "pack -side left -in $w.$name -fill y"]
set wid2 [list $ntmp.[my ownWName [my Transname h_ $name$j]] - - - - "pack -fill y -expand 1 -padx $v2"]
} elseif {$v1 eq {sev}} {set ntmp [my Transname fra ${name}[incr j2]]
set wid1 [list $ntmp - - - - "pack -side left -in $w.$name -fill y"]
set wid2 [list $ntmp.[my ownWName [my Transname sev $name$j]] - - - - "pack -fill y -expand 1 -padx $v2"]
} elseif {$typ eq "statusBar"} {my NormalizeName name i lwidgets
set dattr [lrange $v1 1 end]
if {[::apave::extractOptions dattr -expand 0]} {set expand "-expand 1 -fill x"
} else {set expand ""}
set font " -font {[font actual TkSmallCaptionFont]}"
set wid1 [list .[my ownWName [my Transname Lab ${name}_[incr j]]] - - - - "pack -side left -in $w.$name" "-t {[lindex $v1 0]} $font $dattr"]
if {$::apave::_CS_(LABELBORDER)} {set relief sunken} {set relief flat}
set wid2 [list .[my ownWName [my Transname Lab $name$j]] - - - - "pack -side left $expand -in $w.$name" "-style TLabelSTD -relief $relief -w $v2 -t { } $font $dattr"]
} elseif {$typ eq "toolBar"} {set packreq ""
switch -nocase -glob -- $v1 {lab* - laB* {lassign $v2 txt packreq att
set v2 "-text {$txt} $att"}
opc* {lset v2 2 "[lindex $v2 2] -takefocus 0"}
spx* - chb* {set v2 "$v2 -takefocus 0"}
default {if {[string is lower [string index $v1 0]]} {set but buT
} else {set but BuT}
if {[string match _* $v1]} {set font [my boldTextFont 16]
lassign [my csGet] - fg - bg
set img "-font {$font} -foreground $fg -background $bg -width 2 -bd 0 -pady 0 -padx 2"
set v1 _untouch_$v1
} else {set img "-image $v1"}
set v2 "$img -command $v2 -relief flat -highlightthickness 0 -takefocus 0"
set v1 [my Transname $but _$v1]}}
set wid1 [list $name.$v1 - - - - "pack -side left $packreq" $v2]
if {[incr wasseh]==1} {;
set wid2 [list [my Transname seh $name$j] - - - - "pack -side top -fill x"]
} else {;
set lwidgets [linsert $lwidgets [incr itmp] $wid1]
continue}
} elseif {$typ eq "menuBar"} {;
if {[incr wasmenu]==1} {set menupath [my MakeWidgetName $winname $name]
menu $menupath -tearoff 0}
set menuitem [my MakeWidgetName $menupath $v1]
menu $menuitem -tearoff 0
set ampos [string first & [string trimleft $v2  \{]]
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
if {[string index $name2 0] ne "."} {set name2 [lindex [my LowercaseWidgetName $name2] 0]
set wname "$name2$name"
set name [lindex [my LowercaseWidgetName $name] 0]
set name "$name2$name"
break}}}
return [list $name $wname]}
method WidgetNameFull {w name {an {}}} {set wn [string trim [my parentWName $name].$an[my ownWName $name] .]
set wnamefull $w.$wn
if {[set i1 [string first .scf $wnamefull]]>0 && [set i2 [string first . $wnamefull $i1+1]]>0 && [string first .canvas.container.content. $wnamefull]<0} {set wend [string range $wnamefull $i2 end]
set wnamefull [string range $wnamefull 0 $i2]
append wnamefull canvas.container.content $wend}
return $wnamefull}
method MakeWidgetName {w name {an {}}} {set wnamefull [my WidgetNameFull $w $name $an]
set method [my ownWName $name]
set root1 [string index $method 0]
if {[string is upper $root1]} {lassign [my LowercaseWidgetName $wnamefull] wnamefull
oo::objdefine [self] "         method $method {} {return $wnamefull} ;         export $method"}
return [set ${_pav(ns)}PN::wn $wnamefull]}
method setTextBinds {wt} {if {[bind $wt <<Paste>>] eq ""} {set res "       bind $wt <<Paste>> {+ [self] pasteText $wt} ;      bind $wt <KP_Enter> {+ [self] onKeyTextM $wt %K %s} ;      bind $wt <Return> {+ [self] onKeyTextM $wt %K %s} ;      catch {bind $wt <braceright> {+ [self] onKeyTextM $wt %K}}"}
foreach k [::apave::getTextHotkeys CtrlD] {append res " ;      bind $wt <$k> {[self] doubleText $wt}"}
foreach k [::apave::getTextHotkeys CtrlY] {append res " ;      bind $wt <$k> {[self] deleteLine $wt}"}
append res " ;      bind $wt <Alt-Up> {[self] linesMove $wt -1} ;      bind $wt <Alt-Down> {[self] linesMove $wt +1} ;      bind $wt <Control-a> \"$wt tag add sel 1.0 end; break\""
return $res}
method AddPopupAttr {w attrsName atRO isRO args} {upvar 1 $attrsName attrs
lassign $args state state2
if {$state2 ne ""} {if {[::apave::getOption -state {*}$attrs] eq $state2} return
set isRO [expr {$isRO || [::apave::getOption -state {*}$attrs] eq $state}]}
if {$isRO} { append atRO "RO" }
append attrs " $atRO $w"
return}
method makePopup {w {isRO no} {istext no} {tearoff no} {addpop ""}} {set pop $w.popupMenu
catch {menu $pop -tearoff $tearoff}
$pop delete 0 end
if {$isRO} {$pop add command {*}[my iconA copy] -accelerator Ctrl+C -label "Copy" -command "event generate $w <<Copy>>"
if {$istext} {eval [my popupHighlightCommands $pop $w]
after idle [list [self] set_highlight_matches $w]}
} else {if {$istext} {$pop add command {*}[my iconA cut] -accelerator Ctrl+X -label "Cut" -command "::apave::eventOnText $w <<Cut>>"
$pop add command {*}[my iconA copy] -accelerator Ctrl+C -label "Copy" -command "::apave::eventOnText $w <<Copy>>"
$pop add command {*}[my iconA paste] -accelerator Ctrl+V -label "Paste" -command "::apave::eventOnText $w <<Paste>>"
$pop add separator
$pop add command {*}[my iconA undo] -accelerator Ctrl+Z -label "Undo" -command "::apave::eventOnText $w <<Undo>>"
$pop add command {*}[my iconA redo] -accelerator Ctrl+Shift+Z -label "Redo" -command "::apave::eventOnText $w <<Redo>>"
eval [my popupBlockCommands $pop $w]
eval [my popupHighlightCommands $pop $w]
if {$addpop ne ""} {lassign $addpop com par1 par2
eval [my $com $pop $w {*}$par1 {*}$par2]}
after idle [list [self] set_highlight_matches $w]
after idle [my setTextBinds $w]
} else {$pop add command {*}[my iconA cut] -accelerator Ctrl+X -label "Cut" -command "event generate $w <<Cut>>"
$pop add command {*}[my iconA copy] -accelerator Ctrl+C -label "Copy" -command "event generate $w <<Copy>>"
$pop add command {*}[my iconA paste] -accelerator Ctrl+V -label "Paste" -command "event generate $w <<Paste>>"}}
if {$istext} {$pop add separator
$pop add command {*}[my iconA none] -accelerator Ctrl+A -label "Select All" -command "$w tag add sel 1.0 end"
bind $w <Control-a> "$w tag add sel 1.0 end; break"}
bind $w <Button-3> "[self] themePopup $w.popupMenu; tk_popup $w.popupMenu %X %Y"
return}
method Pre {refattrs} {upvar 1 $refattrs attrs
set attrs_ret [set _pav(prepost) {}]
foreach {a v} $attrs {switch -- $a {-disabledtext - -rotext - -lbxsel - -cbxsel - -notebazook - -entrypop - -entrypopRO - -textpop - -textpopRO - -ListboxSel - -callF2 - -timeout - -bartabs - -onReturn - -linkcom - -selcombobox - -afteridle - -gutter - -propagate - -columnoptions - -selborderwidth -
-selected {set v2 [string trimleft $v "\{"]
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
set w $v
} elseif {[string length $v]>5} {my makePopup $w no yes no $v}
$w tag configure sel -borderwidth 1}
-notebazook {foreach {fr attr} $v {if {[string match "-tr*" $fr]} {if {[string is boolean -strict $attr] && $attr} {ttk::notebook::enableTraversal $w}
} elseif {[string match "-sel*" $fr]} {$w select $w.$attr
} elseif {![string match "#*" $fr]} {set attr [my GetMC $attr]
$w add [ttk::frame $w.$fr] {*}[subst $attr]}}}
-gutter {lassign [::apave::parseOptions $v -canvas Gut -width 5 -shift 6] canvas width shift
if {![winfo exists $canvas]} {set canvas [my $canvas]}
set bind [list [self] fillGutter $w $canvas $width $shift]
bind $w <Configure> $bind
if {[trace info execution $w] eq ""} {trace add execution $w leave $bind}}
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
-bartabs {after 10 [string map [list %w $w] $v]}
-afteridle {after idle [string map [list %w $w] $v]}
-propagate {if {[lindex $v 0] in {add pack}} {pack propagate $w 0
} else {grid propagate $w 0}}
-columnoptions {foreach {col opts} $v {$w column $col {*}$opts}}
-selborderwidth {$w tag configure sel -borderwidth $v}
-selcombobox {bind $w <<ComboboxSelected>> $v}
-selected {if {[string is true $v]} {after idle "$w selection range 0 end"}}}}
return}
method CleanUps {{wr ""}} {for {set i [llength $::apave::_AP_VISITED(ALL)]} {[incr i -1]>=0} {} {if {![winfo exists [lindex $::apave::_AP_VISITED(ALL) $i 0]]} {set ::apave::_AP_VISITED(ALL) [lreplace $::apave::_AP_VISITED(ALL) $i $i]}}
if {$wr ne ""} {for {set i [llength $::apave::_AP_VARS(TIMW)]} {[incr i -1]>=0} {} {set w [lindex $::apave::_AP_VARS(TIMW) $i]
if {[string first $wr $w]==0 && ![catch {baltip::hide $w}]} {set ::apave::_AP_VARS(TIMW) [lreplace $::apave::_AP_VARS(TIMW) $i $i]}}
foreach {lst vars} [array get ::apave::_AP_VARS "_TRACED_${wr}*"] {foreach v $vars {foreach t [trace info variable $v] {lassign $t o c
trace remove variable $v $o $c}}
set ::apave::_AP_VARS($lst) [list]}}}
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
} elseif {[info exists [set datavar [lindex $odata $idx-1]]]} {set png [list -data [set $datavar]]
} else {set png [list -data $odata]}
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
if {[set font [$w cget -font]] eq ""} {set font $::apave::FONTMAIN
} else {catch {set font [font actual $font]}}
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
if {$tt ne ""} {catch {::baltip tip $lab $tt}
lappend ::apave::_AP_VARS(TIMW) $lab}
if {$inv} {set ft $fg
set bt $bg
set fg $fg2
set bg $bg2
set fg2 $ft
set bg2 $bt}
my VisitedLab $lab $v $vz $fg $bg
bind $lab <Enter> "::apave::obj EXPORT HoverLab $lab {$v} yes $fg2 $bg2"
bind $lab <Leave> "::apave::obj EXPORT HoverLab $lab {$v} no $fg $bg"
bind $lab <Button-1> "::apave::obj EXPORT VisitedLab $lab {$v} yes $fg2 $bg2;$v"
if {$doadd} {lappend ::apave::_AP_VISITED(ALL) [list $lab $v $inv]}
return [list $fg $bg $fg2 $bg2]}
method leadingSpaces {line} {return [expr {[string length $line]-[string length [string trimleft $line]]}]}
method onKeyTextM {w K {s {}}} {set lindt [string length $::apave::_AP_VARS(INDENT)]
switch -exact $K {Return - KP_Enter {if {$s} return
set idx1 [$w index {insert linestart}]
set idx2 [$w index {insert lineend}]
set line [$w get $idx1 $idx2]
set nchars [my leadingSpaces $line]
set indent [string range $line 0 [expr {$nchars-1}]]
set ch [string index $line end]
set idx1 [$w index insert]
set idx2 [$w index "$idx1 +1 line"]
set st2 [$w get "$idx2 linestart" "$idx2 lineend"]
if {$indent ne {} || $ch eq "\{" || $K eq {KP_Enter} || $st2 ne {}} {set st1 [$w get "$idx1" "$idx1 lineend"]
if {[string index $st1 0] in [list \t { }]} {set n1 [my leadingSpaces $st1]
$w delete [$w index $idx1] [$w index "$idx1 +$n1 char"]
} elseif {$ch eq "\{" && $st1 eq {}} {if {$st2 eq {}} {append indent $::apave::_AP_VARS(INDENT) \n $indent "\}"
} else {append indent $::apave::_AP_VARS(INDENT)}
incr nchars $lindt
} elseif {$indent eq {} && $st2 ne {}} {if {[string trim $st2] eq "\}"} {set st2 "$::apave::_AP_VARS(INDENT)$st2"}
set nchars [my leadingSpaces $st2]
set indent [string range $st2 0 [expr {$nchars-1}]]}
$w insert [$w index $idx1] \n$indent
::tk::TextSetCursor $w [$w index "$idx2 linestart +$nchars char"]
return -code break}}
braceright {set idx1 [$w index "insert"]
set st [$w get "$idx1 linestart" "$idx1 lineend"]
if {[string trim $st] eq "" && [string length $st]>=$lindt} {$w delete "$idx1 lineend -$lindt char" "$idx1 lineend"}}}}
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
switch -glob -- $optnam {-lbxname* {if {[winfo exists $vn]} {lassign [$vn curselection] s1
if {$s1 eq {}} {set s1 0}
set w [string range $vn [string last . $vn]+1 end]
if {$optnam eq "-lbxnameALL"} {set $v1 [list $s1 [$vn get $s1] [set $v1]]
} else {set $v1 [$vn get $s1]}}}
-retpos {lassign [split $v2 :] p1 p2
set val1 [set $v1]
foreach aop2 $_pav(widgetopts) {lassign $aop2 optnam2 vn2 lst2
if {$optnam2 eq "-list" && $vn eq $vn2} {foreach val2 $lst2 {if {$val1 eq $val2} {set p1 0
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
if {[set tooltip [::apave::getOption -tooltip {*}$attrs]] ne "" ||
[set tooltip [::apave::getOption -tip {*}$attrs]] ne ""} {if {[set i [string first $_pav(edge) $tooltip]]>=0} {set tooltip [string range $tooltip 1 end-1]
set tattrs [string range $tooltip [incr i -1]+[string length $_pav(edge)] end]
set tooltip "{[string range $tooltip 0 $i-1]}"
} else {set tattrs ""}
set tooltip [my MC $tooltip]
lappend addcomms [list baltip::tip $wdg $tooltip {*}$tattrs]
lappend ::apave::_AP_VARS(TIMW) $wdg
set attrs [::apave::removeOptions $attrs -tooltip -tip]}
if {[::apave::getOption -ro {*}$attrs] ne "" || [::apave::getOption -readonly {*}$attrs] ne ""} {lassign [::apave::extractOptions attrs -ro 0 -readonly 0] ro readonly
lappend addcomms [list my readonlyWidget $wdg [expr $ro||$readonly]]}
if {[set wnext [::apave::getOption -tabnext {*}$attrs]] ne ""} {set wnext [string trim $wnext "\{\}"]
if {$wnext eq "0"} {set wnext $wdg}
after idle [list if "\[winfo exists $wdg\]" [list bind $wdg <Key> [list if {{%K} eq {Tab}} "[self] focusNext $w $wnext ; break" ] ] ]
set attrs [::apave::removeOptions $attrs -tabnext]}
return $addcomms}
method DefineWidgetKeys {wname widget} {if {[string first "STD" $wname]>0} return
if {($widget in {ttk::entry entry})} {bind $wname <Up> "$wname selection clear ;         if {{$::tcl_platform(platform)} eq {windows}} {          event generate $wname <Shift-Tab>
        } else {          event generate $wname <Key> -keysym ISO_Left_Tab
        }"
bind $wname <Down> "$wname selection clear ;         event generate $wname <Key> -keysym Tab"
} elseif {$widget in {ttk::button button ttk::checkbutton checkbutton ttk::radiobutton radiobutton "my tk_optionCascade"}} {foreach k {<Up> <Left>} {bind $wname $k [list if {$::tcl_platform(platform) eq "windows"} [list event generate $wname <Shift-Tab> ] else [list event generate $wname <Key> -keysym ISO_Left_Tab] ]}
foreach k {<Down> <Right>} {bind $wname $k [list event generate $wname <Key> -keysym Tab]}}
if {$widget in {ttk::button button ttk::checkbutton checkbutton ttk::radiobutton radiobutton}} {foreach k {<Return> <KP_Enter>} {bind $wname $k [list event generate $wname <Key> -keysym space]}}
if {$widget in {ttk::entry entry spinbox ttk::spinbox}} {foreach k {<Return> <KP_Enter>} {bind $wname $k "+ $wname selection clear ; event generate $wname <Key> -keysym Tab"}}}
method colorWindow {win} {if {[my apaveTheme]} {my csSet [my csCurrent] $win -doit
} else {my themeNonThemed $win}}
method Window {w inplists} {set lwidgets [list]
foreach lst $inplists {if {[string index [string index $lst 0] 0] ne "#"} {lappend lwidgets $lst}}
set lused [list]
set lwlen [llength $lwidgets]
for {set i 0} {$i < $lwlen} {} {set lst1 [lindex $lwidgets $i]
if {[my Replace_Tcl i lwlen lwidgets {*}$lst1] ne ""} {incr i}}
set lwlen [llength $lwidgets]
for {set i $lwlen} {$i} {incr i -1} {set lst1 [lindex $lwidgets $i]
lassign $lst1 name neighbor
lassign [my NormalizeName name i lwidgets] name wname
lassign [my NormalizeName neighbor i lwidgets] neighbor
set lst1 [lreplace $lst1 0 1 $wname $neighbor]
set lwidgets [lreplace $lwidgets $i $i $lst1]}
for {set i 0} {$i < $lwlen} {} {set lst1 [lindex $lwidgets $i]
set lst1 [my Replace_chooser w i lwlen lwidgets {*}$lst1]
if {[set lst1 [my Replace_bar w i lwlen lwidgets {*}$lst1]] eq ""} {incr i
continue}
lassign $lst1 name neighbor posofnei rowspan colspan options1 attrs1
set prevw $name
lassign [my NormalizeName name i lwidgets] name wname
set wname [my MakeWidgetName $w $wname]
if {$colspan eq {} || $colspan eq {-}} {set colspan 1
if {$rowspan eq {} || $rowspan eq {-}} {set rowspan 1}}
foreach ao {attrs options} {if {[catch {set $ao [uplevel 2 subst -nocommand -nobackslashes [list [set ${ao}1]]]}]} {set $ao [set ${ao}1]}}
lassign [my widgetType $wname $options $attrs] widget options attrs nam3 dsbl
if { !($widget eq "" || [winfo exists $widget])} {set attrs [my GetAttrs $attrs $nam3 $dsbl]
set attrs [my ExpandOptions $attrs]
if {$widget in {"ttk::scrollbar" "scrollbar"}} {set neighbor [lindex [my LowercaseWidgetName $neighbor] 0]
set wneigb [my WidgetNameFull $w $neighbor]
if {$posofnei eq "L"} {$wneigb config -yscrollcommand "$wname set"
set attrs "$attrs -com \\\{$wneigb yview\\\}"
append options " -side right -fill y"
} elseif {$posofnei eq "T"} {$wneigb config -xscrollcommand "$wname set"
set attrs "$attrs -com \\\{$wneigb xview\\\}"
append options " -side bottom -fill x"}
set options [string map [list %w $wneigb] $options]}
my Pre attrs
set addcomms [my AdditionalCommands $w $wname attrs]
eval $widget $wname {*}$attrs
my Post $wname $attrs
foreach acm $addcomms {{*}$acm}
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
if {$neighbor eq "+"} {set neighbor $prevw}
set neighbor [lindex [my LowercaseWidgetName $neighbor] 0]
set row -1
foreach cell $lused {lassign $cell uname urow ucol urowspan ucolspan
if {[lindex [my LowercaseWidgetName $uname] 0] eq $neighbor} {set col $ucol
set row $urow
if {$posofnei eq "T" || $posofnei eq ""} {incr row $urowspan
} elseif {$posofnei eq "L"} {incr col $ucolspan}}}}}
return $lwidgets}
method paveWindow {args} {set res [list]
set wmain [set wdia ""]
foreach {w lwidgets} $args {lappend res {*}[my Window $w $lwidgets]
lappend _pav(lwidgets) $lwidgets
if {[set ifnd [regexp -indices -inline {[.]dia\d+} $w]] ne ""} {set wdia [string range $w 0 [lindex $ifnd 0 1]]
} else {set wmain .[lindex [split $w .] 1]}}
if {[winfo exists $wdia]} {::apave::initPOP $wdia} elseif {[winfo exists $wmain]} {::apave::initPOP $wmain}
return $res}
method window {args} {return [uplevel 1 [list [self] paveWindow {*}$args]]}
method showWindow {win modal ontop var {minsize ""}} {::apave::infoWindow [expr {[::apave::infoWindow] + 1}] $win $modal $var yes
if {[::iswindows]} {if {[wm attributes $win -alpha] < 0.1} {wm attributes $win -alpha 1.0}
} else {catch {wm deiconify $win ; raise $win}}
if {$minsize eq ""} {set minsize [list [winfo width $win] [winfo height $win]]}
wm minsize $win {*}$minsize
bind $win <Configure> "[namespace current]::WinResize $win"
if {$ontop} {wm attributes $win -topmost 1}
if {$modal} {grab set $win
} elseif {[set wgr [grab current]] ne ""} {grab release $wgr}
if {![::iswindows]} {tkwait visibility $win}
tkwait variable $var
if {$modal} {grab release $win}
::apave::infoWindow [expr {[::apave::infoWindow] - 1}] $win $modal $var}
method showModal {win args} {set shal [::apave::shadowAllowed 0]
if {[::apave::getOption -themed {*}$args] in {{} {0}} && [my csCurrent] != [apave::cs_Non]} {my colorWindow $win}
::apave::setAppIcon $win
lassign  [my csGet] - - - bg
$win configure -bg $bg
set _pav(modalwin) $win
set root [winfo parent $win]
if {[set centerme [::apave::getOption -centerme {*}$args]] ne {}} {;
if {[winfo exist $centerme]} {set root $centerme}}
if {[set ontop [::apave::getOption -ontop {*}$args]] eq {}} {set ontop no
catch {set wpar [winfo parent $win]
set ontop [wm attributes $wpar -topmost]}}
if {[set modal [::apave::getOption -modal {*}$args]] eq {}} {set modal yes}
set minsize [::apave::getOption -minsize {*}$args]
set args [::apave::removeOptions $args -centerme -ontop -modal -minsize -themed]
array set opt [list -focus "" -onclose "" -geometry "" -decor 1 -root $root -resizable "" -variable "" -escape 1 {*}$args]
lassign [split [wm geometry $root] x+] rw rh rx ry
if {[winfo parent $win] ni {{} .}} {set opt(-decor) 0}
if {!$opt(-decor)} {wm transient $win $root}
if {$opt(-onclose) eq ""} {set opt(-onclose) [list set ${_pav(ns)}PN::AR($win) 0]
} else {set opt(-onclose) [list $opt(-onclose) ${_pav(ns)}PN::AR($win)]}
if {$opt(-resizable) ne ""} {wm resizable $win {*}$opt(-resizable)}
set opt(-onclose) "::apave::obj EXPORT CleanUps $win; $opt(-onclose)"
wm protocol $win WM_DELETE_WINDOW $opt(-onclose)
set inpgeom $opt(-geometry)
if {$inpgeom eq ""} {set opt(-geometry) [my CenteredXY $rw $rh $rx $ry [winfo reqwidth $win] [winfo reqheight $win]]
} elseif {[string first "pointer" $inpgeom]==0} {lassign [split $inpgeom+0+0 +] -> x y
set inpgeom +[expr {$x+[winfo pointerx .]}]+[expr {$y+[winfo pointery .]}]
set opt(-geometry) $inpgeom
} elseif {[string first "root" $inpgeom]==0} {set root .[string trimleft [string range $inpgeom 5 end] .]
set opt(-geometry) [set inpgeom ""]}
if {[set pp [string first + $opt(-geometry)]]>=0} {wm geometry $win [string range $opt(-geometry) $pp end]}
if {$opt(-focus) eq ""} {set opt(-focus) $win}
set ${_pav(ns)}PN::AR($win) "-"
if {$opt(-escape)} {bind $win <Escape> $opt(-onclose)}
update
set w [winfo width $win]
set h [winfo height $win]
if {$inpgeom eq ""} {if {($h/2-$ry-$rh/2)>30 && $root ne "."} {wm geometry $win [my CenteredXY $rw $rh $rx $ry $w $h]
} else {::tk::PlaceWindow $win widget $root}
} else {lassign [lrange [split $inpgeom +] end-1 end] x y
if {$x ne "" && $y ne "" && [string first x $inpgeom]<0} {set inpgeom [my checkXY $w $h $x $y]}
wm geometry $win $inpgeom}
if {[set var $opt(-variable)] eq ""} {set var ${_pav(ns)}PN::AR($win)}
after 50 [list if "\[winfo exist $opt(-focus)\]" "focus -force $opt(-focus)"]
my showWindow $win $modal $ontop $var $minsize
set res 0
catch {my GetOutputValues
set res [set [set _ ${_pav(ns)}PN::AR($win)]]}
::apave::shadowAllowed $shal
return $res}
method res {win {result "get"}} {if {$result eq "get"} {return [set ${_pav(ns)}PN::AR($win)]}
my CleanUps $win
return [set ${_pav(ns)}PN::AR($win) $result]}
method makeWindow {w ttl args} {my CleanUps
set w [set wtop [string trimright $w .]]
set withfr [expr {[set pp [string last . $w]]>0 && [string match "*.fra" $w]}]
if {$withfr} {set wtop [string range $w 0 $pp-1]}
catch {destroy $wtop}
toplevel $wtop {*}$args
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
if {$state eq "normal"} {::tk::TextSetCursor $w $pos
} else {$w configure -state $state}
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
} elseif {[string first "\</$tag\>" $line]==0} {if {$pos eq "0"} {error "\npaveme.tcl: mismatched \</$tag\> in line $irow.\n"}
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
catch {set lfont [font actual $lfont]}
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