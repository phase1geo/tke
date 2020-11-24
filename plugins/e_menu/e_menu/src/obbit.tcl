# _______________________________________________________________________ #
package require Tk
namespace eval ::apave {variable _PU_opts
array set _PU_opts [list -NONE =NONE=]
variable ::apave::_CS_
array set ::apave::_CS_ [list]
variable ::apave::_C_
array set ::apave::_C_ [list]
set ::apave::_CS_(initall) 1
set ::apave::_CS_(initWM) 1
set ::apave::_CS_(textFont) [font configure "TkFixedFont" -family]
set ::apave::_CS_(!FG) #000000
set ::apave::_CS_(!BG) #c3c3c3
set ::apave::_CS_(expo,tfg1) "-"
set ::apave::_CS_(ALL) {
{MildDark #E8E8E8 #E7E7E7 #222A2F #2D435B #FEEFA8 #739bb9 black   #00ffff grey    #76b0c3 \
black #6d95b3  -  #3c546e black #b0b04c #002 #003 #004 #005 #006 #007}
{Inkpot #d3d3ff #AFC2FF #05050e #1E1E27 #a4a4e5 #8e8ecf black #ff9900 grey orange black #8585c6 - #292936 black #a2a23e #002 #003 #004 #005 #006 #007}
{Green         #E8E8E8 #EFEFEF #0F3F0A #274923 #FEEC9A #8fad98 black #E69800 grey #E69800 black #88a691 - #3e603a black #bebe5a #002 #003 #004 #005 #006 #007}
{Brown         #E8E8E8 #E7E7E7 #352927 #453528 #FEEC9A #b4a489 black #E69800 grey #E69800 black #ab9b80 - #524235 black #bebe5a #002 #003 #004 #005 #006 #007}
{Magenta       #E8E8E8 #F0E8E8 #2B1137 #4A2A4A #FEEC9A #b898b8 black #E69800 grey #E69800 black #ad8dad - #573757 black #cdcd69 #002 #003 #004 #005 #006 #007}
{Red           white   #CECECB #340202 #440702 #efef2a #df8d8d black red #440701 orange black #ba6868 - #440702 black #bebe5a #002 #003 #004 #005 #006 #007}
{Anti-Light1 #bebebe #bebebe #333333 #242424 #FEEFA8 #8d8d8d black #ff9900 grey #70C6C6 #000000 #636363 - #1c1c1c black #bebe5a #002 #003 #004 #005 #006 #007}
{Anti-Light2 #bebebe #bebebe #242424 #333333 #FEEFA8 #8d8d8d black  #ff9900 grey    #70C6C6 #000000 #636363 - #2b2b2b black #b0b04c #002 #003 #004 #005 #006 #007}
{Darcula #dedede #A1ACB6 #272727 #303030 #B09869 #2F5692 #EDC881 #ff9900 grey #f0a471 #EDC881 #1a417d - #444444 black #a2a23e #002 #003 #004 #005 #006 #007}
{Sleepy #daefd0 #D0D0D2 #3b4043 #2E3436 #CB956D #899498 black #ff9900 grey #B0B000 black #828d91 - #383E40 black #b0b04c #002 #003 #004 #005 #006 #007}
{Dark          #E0D9D9 #C4C4C4 #232323 #303030 #CCCC90 #aaaaaa black #E69800 grey #E69800 black #a2a2a2 - #424242 black #cdcd69 #002 #003 #004 #005 #006 #007}
{DarkGrey      #F0E8E8 #E7E7E7 #333333 #494949 #DCDC9B #bbbbbb black #E69800 grey #E69800 black #adadad - #595959 black #cdcd69 #002 #003 #004 #005 #006 #007}
{Sandy         #211D1C #27201F #FEFAEB #F7EEC5 #523A0A #cdbf9a #2f0a00 #802e00 grey    #933232 black #b9ab86 - #e4dbb2 #000000 #ffff3a #002 #003 #004 #005 #006 #007}
{African black black #ffe2a2 #ffffb4 brown #d3a876 #000000 red grey SaddleBrown #3b1516 #f9b777 - #ffffd0 #000000 #ffff00 #002 #003 #004 #005 #006 #007}
{Rosy          #2B122A #000000 #FFFFFF #F6E6E9 #570957 #C5ADC8 black #802e00 grey #870287 #000000 #C5ADC8 - #d6c6c9 #000000 #FBFB95 #002 #003 #004 #005 #006 #007}
{InverseGrey   #121212 #1A1A1A #c9cbcf #DADCE0 #302206 #777777 white #802e00 #DADCE1 #933232 #FFFFFF #6d6d6d - #c9cbcf #000000 #FBFB95 #002 #003 #004 #005 #006 #007}
{Grey          #000000 #0D0D0D #FFFFFF #DADCE0 #362607 #AFAFAF black #802e00 grey #933232 #000000 #AFAFAF - #caccd0 #000000 #FBFB95 #002 #003 #004 #005 #006 #007}
{Anti-Dark1 #2e3436 #2e3436 #F8F8F8 #dadad8 #362607 #AFAFAF black #802e00 grey #933232 #000000 #AFAFAF - #caccd0 #000000 #FBFB95 #002 #003 #004 #005 #006 #007}
{Anti-Dark2 #2e3436 #2e3436 #dadad8 #F8F8F8 #362607 #AFAFAF black #802e00 grey #933232 #000000 #AFAFAF - #e1e1df #000000 #FBFB95 #002 #003 #004 #005 #006 #007}
{Florid black darkgreen #dbffdb white brown #93e493 #0F2D0F #802e00 grey #802e00 black #8adb8a - #dff4df #000000 #FBFB96 #002 #003 #004 #005 #006 #007}
{LightGreen    #122B05 #091900 #edffed #DEF8DE #562222 #A8CCA8 black #802e00 grey #933232 #000000 #A8CCA8 - #c3ddc3 #000000 #FBFB96 #002 #003 #004 #005 #006 #007}
{InverseGreen  #122B05 #091900 #cce6c8 #DEF8DE #562222 #9cc09c black #802e00 #DEF8D1 #933232 black #98bc98 - #cce6cc #000000 #FBFB96 #002 #003 #004 #005 #006 #007}
{Khakish       #2e3436 #2e3436 #e1ffdd #cadfca #933232 #9dbb99 black #802e00 grey #AE5F02 #000000 #9cb694 - #bcdab8 #000000 #FBFB96 #002 #003 #004 #005 #006 #007}
{Blue          #08085D #030358 #FFFFFF #D2DEFA #562222 #9fb6e9 black #802e00 grey #933232 black #a5bcef - #b7c3df #000000 #FBFB96 #002 #003 #004 #005 #006 #007}
{Sky           #102433 #0A1D33 #D2EAF2 #AFDFEF #0D3239 #72b5c9 black #0052b9 grey #1261AD black #7bbed2 - #96c6d6 #000000 #FBFB95 #002 #003 #004 #005 #006 #007}
{TKE-SourceForge #141414 #151616 #ffffff #a3dcff #144d70 #528bae white #0052b9 grey #189898 white #4982a5 - #8ac3e6 #000000 #FBFB96 #002 #003 #004 #005 #006 #007}
{TKE-Juicy #000000 #000000 #f1f1f1 #dddddd #41312b #bfbfbf black #802e00 grey #933232 black #a9a9a9 - #d3d3d3 #000000 #FBFB96 #002 #003 #004 #005 #006 #007}
{TKE-FluidVision #000000 #000000 #f4f4f4 #cccccc #41312b #777777 white #802e00 grey #933232 white #6b6b6b - #BABABA #000000 #FBFB95 #002 #003 #004 #005 #006 #007}
{TKE-YellowStone #0000ff #00003c #fdf9d0 #d5d2af #00003c #d59d6f black #4A3706 grey #771d00 #00003c #e6ae80 - #DBD8B5 #000000 #fbfb74 #002 #003 #004 #005 #006 #007}
{TKE-TurnOfCentury #333333 #333333 #d6c4b6 #ae9f94 #333333 #d59d6f black #4A3706 grey #771d00 black #e6ae80 - #a5968b #000000 #eded89 #002 #003 #004 #005 #006 #007}
{TKE-Notebook #000000 #000000 #beb69d #96907c #000000 #d59d6f black #4A3706 grey #771d00 #000000 #e6ae80 - #85806E #000000 #eded89 #002 #003 #004 #005 #006 #007}
{TKE-IdleFingers #ffffff #ffffff #323232 #5a5a5a #ffffff #395472 white #ff9900 grey orange #ffffff #2d4866 - #4F4F4F black #cdcd69 #002 #003 #004 #005 #006 #007}
{TKE-Minimal #fcffe0 #ffffff #302d26 #5a5a5a #ffffff #395472 white #ff9900 grey orange #ffffff #2e4967 - #4F4F4F black #cdcd69 #002 #003 #004 #005 #006 #007}
{TKE-Monokai #f8f8f2 #f8f8f2 #272822 #4e5044 #f8f8f2 #8d8d8d black #ff959f grey orange black #777777 - #505147 black #cdcd69 #002 #003 #004 #005 #006 #007}
{TKE-LightVision #ffffff #ffffff #3C423C #515753 #ffc2a1 #8d8d8d black #ff959f grey orange black #777777 - #474D49 black #cdcd69 #002 #003 #004 #005 #006 #007}
{TKE-oscuro #f1f1f1 #f1f1f1 #344545 #526d6d #f1f1f1 #9eb9b9 black #ff959f grey orange black #94afaf - #475E5E black #cdcd69 #002 #003 #004 #005 #006 #007}
{TKE-StarLight #C0B6A8 #C0B6A8 #223859 #315181 #C0B6A8 #7292c2 black #00ffff grey orange black #7d9dcd - #2D4A75 black #bebe5a #002 #003 #004 #005 #006 #007}
{TKE-MildDark #d2d2d2 #ffffff #151616 #2D435B #ffbe00 #739bb9 black #00ffff grey #ffbb6d black #6c94b2 - #24384f black #bebe5a #002 #003 #004 #005 #006 #007}
{TKE-MildDark2 #b4b4b4 #ffffff #0d0e0e #24384f #ffbe00 #739bb9 black #00ffff grey #ffbb6d black #6890ae - #1B3048 black #bebe5a #002 #003 #004 #005 #006 #007}
{TKE-MildDark3 #e2e2e2 #f1f1f1 #000000 #1B3048 #ffbe00 #739bb9 black #00ffff grey #ffbb6d black #668eac - #12273f black #b0b04c #002 #003 #004 #005 #006 #007}
{TKE-RubyBlue #ffffff #ffffff #121e31 #213659 #ffffff #6d88a6 black #00ffff grey orange black #66819f - #1C2E4D black #b0b04c #002 #003 #004 #005 #006 #007}
{TKE-MadeOfCode #f8f8f8 #f8f8f8 #090a1b #00348c #f8f8f8 #5d91e9 black #00ffff grey orange black #578be3 - #002C78 black #b0b04c #002 #003 #004 #005 #006 #007}
{TKE-CoolGlow #e0e0e0 #e0e0e0 #06071d #0e1145 #e0e0e0 #7d8aee black #00ffff grey orange black #727fe3 - #171C73 black #b0b04c #002 #003 #004 #005 #006 #007}
{TKE-Quiverly #b6c1c1 #b6c1c1 #2b303b #333946 #fbffd7 #a1a7b4 black #ff9900 grey orange black #9197a4 - #414650 black #b0b04c #002 #003 #004 #005 #006 #007}
{TKE-Aurora #ececec #ececec #302e40 #4e4b68 #ececec #9b98b5 black #ff9900 grey orange black #8d8aa7 - #434259 black #bebe5a #002 #003 #004 #005 #006 #007}
{TKE-Choco #c3be98 #c3be98 #180c0c #402020 #c3be98 #664D4D white #ff9900 grey orange white #735a5a - #331A1A black #b0b04c #002 #003 #004 #005 #006 #007}
{TKE-AnatomyOfGrey #dfdfdf #ffffff #000000 #282828 #ffffff #8b8b8b black #ff9900 grey orange black #828282 - #363636 black #b0b04c #002 #003 #004 #005 #006 #007}
{TKE-Default white white black #282828 white blue white #ff9900 grey orange white #0000d3 - #383838 black #b0b04c #002 #003 #004 #005 #006 #007}
}
set ::apave::_CS_(NONCS) -2
set ::apave::_CS_(MINCS) -1
set ::apave::_CS_(STDCS) [expr {[llength $::apave::_CS_(ALL)] - 1}]
set ::apave::_CS_(MAXCS) $::apave::_CS_(STDCS)
set ::apave::_CS_(old) $::apave::_CS_(NONCS)
set ::apave::_CS_(defFont) [ttk::style lookup "." -font]
set ::apave::_CS_(def_FontSize) [font config $::apave::_CS_(defFont) -size]
set ::apave::_CS_(fs) $::apave::_CS_(def_FontSize)
set ::apave::_CS_(untouch) [list]}
proc ::iswindows {} {return [expr {$::tcl_platform(platform) eq "windows"} ? 1: 0]}
proc ::apave::initPOP {w} {bind $w <KeyPress> {if {"%K" eq "Menu"} {if {[winfo exists [set w [focus]]]} {event generate $w <Button-3> -rootx [winfo pointerx .] -rooty [winfo pointery .]}}}}
proc ::apave::initWM {args} {if {!$::apave::_CS_(initWM)} return
lassign [::apave::parseOptions $args -cursorwidth 2 -theme "clam" -buttonwidth -8 -buttonborder 1 -labelborder 0 -padding 1] cursorwidth theme buttonwidth buttonborder labelborder padding
set ::apave::_CS_(initWM) 0
set ::apave::_CS_(CURSORWIDTH) $cursorwidth
if {$::tcl_platform(platform) == "windows"} {wm attributes . -alpha 0.0
} else {wm withdraw .}
ttk::style map "." -selectforeground [list !focus $::apave::_CS_(!FG)] -selectbackground [list !focus $::apave::_CS_(!BG)]
try {ttk::style theme use $theme}
ttk::style configure TButton -anchor center -width $buttonwidth -relief raised -borderwidth $buttonborder -padding $padding
ttk::style configure TLabel -borderwidth $labelborder -padding $padding
ttk::style configure TMenubutton -width 0 -padding 0
initPOP .
return}
proc ::apave::cs_Non {} {return $::apave::_CS_(NONCS)}
proc ::apave::cs_Min {} {return $::apave::_CS_(MINCS)}
proc ::apave::cs_Max {} {return $::apave::_CS_(MAXCS)}
proc ::apave::getN {sn {defn 0} {min ""} {max ""}} {if {$sn eq "" || [catch {set sn [expr {$sn}]}]} {set sn $defn}
if {$max ne ""} {set sn [expr {min($max,$sn)}]}
if {$min ne ""} {set sn [expr {max($min,$sn)}]}
return $sn}
proc ::apave::parseOptionsFile {strict inpargs args} {variable _PU_opts
set actopts true
array set argarray "$args yes yes"
if {$strict==2} {set retlist $inpargs
} else {set retlist $args}
set retfile {}
for {set i 0} {$i < [llength $inpargs]} {incr i} {set parg [lindex $inpargs $i]
if {$actopts} {if {$parg=="--"} {set actopts false
} elseif {[catch {set defval $argarray($parg)}]} {if {$strict==1} {set actopts false
append retfile $parg " "
} else {incr i}
} else {if {$strict==2} {if {$defval == $_PU_opts(-NONE)} {set defval yes}
incr i
} else {if {$defval == $_PU_opts(-NONE)} {set defval yes
} else {set defval [lindex $inpargs [incr i]]}}
set ai [lsearch -exact $retlist $parg]
incr ai
set retlist [lreplace $retlist $ai $ai $defval]}
} else {append retfile $parg " "}}
return [list $retlist [string trimright $retfile]]}
proc ::apave::parseOptions {inpargs args} {lassign [::apave::parseOptionsFile 0 $inpargs {*}$args] tmp
foreach {nam val} $tmp {lappend retlist $val}
return $retlist}
proc ::apave::getOption {optname args} {lassign [::apave::parseOptions $args $optname ""] optvalue
return $optvalue}
proc ::apave::putOption {optname optvalue args} {
set optlist {}
set doadd true
foreach {a v} $args {if {$a eq $optname} {set v $optvalue
set doadd false}
lappend optlist $a $v}
if {$doadd} {lappend optlist $optname $optvalue}
return $optlist}
proc ::apave::removeOptions {options args} {foreach key $args {if {[set i [lsearch -exact $options $key]]>-1} {catch {set options [lreplace $options $i $i]
set options [lreplace $options $i $i]}
} elseif {[string first * $key]>=0 && [set i [lsearch -glob $options $key]]>-1} {set options [lreplace $options $i $i]}}
return $options}
proc ::apave::readTextFile {fileName {varName ""} {doErr 0}} {if {$varName ne ""} {upvar $varName fvar}
if {[catch {set chan [open $fileName]} e]} {if {$doErr} {error "\n readTextFile: can't open \"$fileName\"\n $e"}
set fvar ""
} else {chan configure $chan -encoding utf-8
set fvar [read $chan]
close $chan}
return $fvar}
proc ::apave::openDoc {url} {
set commands {xdg-open open start}
foreach opener $commands {if {$opener eq "start"} {set command [list {*}[auto_execok start] {}]
} else {set command [auto_execok $opener]}
if {[string length $command]} {break}}
if {[string length $command] == 0} {puts "ERROR: couldn't find any opener"}
if {[catch {exec {*}$command $url &} error]} {puts "ERROR: couldn't execute '$command':\n$error"}}
oo::class create ::apave::ObjectProperty {variable _OP_Properties
constructor {args} {array set _OP_Properties {}
if {[llength [self next]]} { next {*}$args }}
destructor {array unset _OP_Properties
if {[llength [self next]]} next}
method setProperty {name args} {switch [llength $args] {0 {return [my getProperty $name]}
1 {return [set _OP_Properties($name) $args]}}
puts -nonewline stderr "Wrong # args: should be \"[namespace current] setProperty propertyname ?value?\""
return -code error}
method getProperty {name {defvalue ""}} {if [info exists _OP_Properties($name)] {return $_OP_Properties($name)}
return $defvalue}}
oo::class create ::apave::ObjectTheming {mixin ::apave::ObjectProperty
constructor {args} {my InitCS
if {[llength [self next]]} { next {*}$args }}
destructor {if {[llength [self next]]} next}
method InitCS {} {if {$::apave::_CS_(initall)} {my basicFontSize 10
my ColorScheme
set ::apave::_CS_(initall) 0}
return}
method Create_Fonts {} {catch {font delete apaveFontMono}
catch {font delete apaveFontDef}
font create apaveFontMono -family $::apave::_CS_(textFont) -size $::apave::_CS_(fs)
font create apaveFontDef -family $::apave::_CS_(defFont) -size $::apave::_CS_(fs)}
method Main_Style {tfg1 tbg1 tfg2 tbg2 tfgS tbgS bclr tc fA bA bD} {my Create_Fonts
ttk::style configure "." -background        $tbg1 -foreground        $tfg1 -bordercolor       $bclr -darkcolor         $tbg1 -lightcolor        $tbg1 -troughcolor       $tc -arrowcolor        $tfg1 -selectbackground  $tbgS -selectforeground  $tfgS ;
ttk::style map "." -background       [list disabled $bD active $bA] -foreground       [list disabled grey active $fA]}
method ColorScheme {{ncolor ""}} {if {"$ncolor" eq "" || $ncolor<0} {set fW black
set bW #FBFB95
if {[info exists ::apave::_CS_(def_fg)]} {set fg $::apave::_CS_(def_fg)
set bg $::apave::_CS_(def_bg)
set fS $::apave::_CS_(def_fS)
set bS $::apave::_CS_(def_bS)
set bA $::apave::_CS_(def_bA)
} else {set ::apave::_CS_(index) $::apave::_CS_(NONCS)
lassign [::apave::parseOptions [ttk::style configure .] -foreground #000000 -background #d9d9d9 -troughcolor #c3c3c3] fg bg tc
set fS black
set bS #9cb0c6
lassign [::apave::parseOptions [ttk::style map . -background] disabled #d9d9d9 active #ececec] bD bA
lassign [::apave::parseOptions [ttk::style map . -foreground] disabled #a3a3a3] fD
lassign [::apave::parseOptions [ttk::style map . -selectbackground] !focus #9e9a91] bclr
set ::apave::_CS_(def_fg) $fg
set ::apave::_CS_(def_bg) $bg
set ::apave::_CS_(def_fS) $fS
set ::apave::_CS_(def_bS) $bS
set ::apave::_CS_(def_fD) $fD
set ::apave::_CS_(def_bD) $bD
set ::apave::_CS_(def_bA) $bA
set ::apave::_CS_(def_tc) $tc
set ::apave::_CS_(def_bclr) $bclr}
return [list default $fg    $fg     $bA    $bg     $fg     $bS     $fS    #802e00  grey   #4f6379 $fS $bS - $bg $fW $bW]}
return [lindex $::apave::_CS_(ALL) $ncolor]}
method basicFontSize {{fs 0}} {if {$fs} {return [set ::apave::_CS_(fs) $fs]
} else {return $::apave::_CS_(fs)}}
method basicTextFont {{textfont ""}} {if {$textfont ne ""} {return [set ::apave::_CS_(textFont) $textfont]
} else {return $::apave::_CS_(textFont)}}
method csFont {fontname} {if {[catch {set font [font configure $fontname]}]} {my Create_Fonts
set font [font configure $fontname]}
return $font}
method csFontMono {} {return [my csFont apaveFontMono]}
method csFontDef {} {return [my csFont apaveFontDef]}
method csDarkEdit {} {set cs [my csCurrent]
return [expr {$cs>-1 && $cs <12 || $cs>30}]}
method csExport {} {set theme ""
foreach arg {tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr args} {if {[catch {set a "$::apave::_CS_(expo,$arg)"}] || $a==""} {break}
append theme " $a"}
return $theme}
method csCurrent {} {return $::apave::_CS_(index)}
method csGetName {{ncolor 0}} {if {$ncolor < $::apave::_CS_(MINCS)} {return "Default"
} elseif {$ncolor == $::apave::_CS_(MINCS)} {return "Basic"}
return [lindex [my ColorScheme $ncolor] 0]}
method csGet {{ncolor ""}} {if {$ncolor eq ""} {set ncolor [my csCurrent]}
return [lrange [my ColorScheme $ncolor] 1 end]}
method csSet {{ncolor 0} {win .} args} {if {$ncolor eq ""} {lassign $args clrtitf clrinaf clrtitb clrinab clrhelp clractb clractf clrcurs clrgrey clrhotk tfgI tbgI fM bM
} else {foreach cs [list $ncolor $::apave::_CS_(MINCS)] {lassign [my csGet $cs] clrtitf clrinaf clrtitb clrinab clrhelp clractb clractf clrcurs clrgrey clrhotk tfgI tbgI fM bM
if {$clrtitf ne ""} break
set ncolor $cs}
set ::apave::_CS_(index) $ncolor}
set fg $clrinaf
set bg $clrinab
set fE $clrtitf
set bE $clrtitb
set fS $clractf
set bS $clractb
set hh $clrhelp
set gr $clrgrey
set cc $clrcurs
set ht $clrhotk
set grey #808080
if {$::apave::_CS_(old) != $ncolor || $args eq "-doit"} {set ::apave::_CS_(old) $ncolor
my themeWindow $win $fg $bg $fE $bE $fS $bS $grey $bg $cc $ht $hh $tfgI $tbgI $fM $bM
my UpdateColors
my initTooltip}
return [list $fg $bg $fE $bE $fS $bS $hh $gr $cc $ht $tfgI $tbgI $fM $bM]}
method csAdd {newcs {setnew true}} {if {[llength $newcs]<4} {set newcs [my ColorScheme]}
lassign $newcs name tfg2 tfg1 tbg2 tbg1 tfhh - - tcur grey bclr
set found $::apave::_CS_(NONCS)
for {set i $::apave::_CS_(MINCS)} {$i<=$::apave::_CS_(MAXCS)} {incr i} {lassign [my csGet $i] cfg2 cfg1 cbg2 cbg1 cfhh - - ccur
if {$cfg2==$tfg2 && $cfg1==$tfg1 && $cbg2==$tbg2 && $cbg1==$tbg1 && $cfhh==$tfhh && $ccur==$tcur} {set found $i
break}}
if {$found == $::apave::_CS_(MINCS) && [my csCurrent] == $::apave::_CS_(NONCS)} {set setnew false
} elseif {$found == $::apave::_CS_(NONCS)} {lappend ::apave::_CS_(ALL) $newcs
set found [incr ::apave::_CS_(MAXCS)]}
if {$setnew} {set ::apave::_CS_(index) [set ::apave::_CS_(old) $found]}
return [my csCurrent]}
method Ttk_style {oper ts opt val} {if {![catch {set oldval [ttk::style $oper $ts $opt]}]} {catch {ttk::style $oper $ts $opt $val}
if {$oldval=="" && $oper=="configure"} {switch -- $opt {-foreground - -background {set oldval [ttk::style $oper . $opt]}
-fieldbackground {set oldval white}
-insertcolor {set oldval black}}}}
return}
method themeWindow {win {tfg1 ""} {tbg1 ""} {tfg2 ""} {tbg2 ""} {tfgS ""}
{tbgS ""} {tfgD ""} {tbgD ""} {tcur ""} {bclr ""}
{thlp ""} {tfgI ""} {tbgI ""} {tfgM ""} {tbgM ""}
{isCS true} args} {if {$tfg1 eq "-"} return
if {!$isCS} {my csAdd [list CS-[expr {$::apave::_CS_(MAXCS)+1}] $tfg2 $tfg1 $tbg2 $tbg1 $thlp $tbgS $tfgS $tcur grey $bclr $tfgI $tbgI $tfgM $tbgM]}
if {$tfgI eq ""} {set tfgI $tfg2}
if {$tbgI eq ""} {set tbgI $tbg2}
if {$tfgM in {"" -}} {set tfgM $tfg1}
if {$tbgM eq ""} {set tbgM $tbg1}
my Main_Style $tfg1 $tbg1 $tfg2 $tbg2 $tfgS $tbgS $tfgD $tbg1 $tfg1 $tbg2 $tbg1
foreach arg {tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr thlp tfgI tbgI tfgM tbgM args} {if {$win eq "."} {set ::apave::_C_($win,$arg) [set $arg]}
set ::apave::_CS_(expo,$arg) [set $arg]}
foreach ts {TLabel TLabelframe.Label TButton TMenubutton TCheckbutton TScale TProgressbar TRadiobutton TScrollbar TSeparator TSizegrip TNotebook.Tab} {my Ttk_style configure $ts -font apaveFontDef
my Ttk_style configure $ts -foreground $tfg1
my Ttk_style configure $ts -background $tbg1
my Ttk_style map $ts -background [list pressed $tbg1 active $tbg2 alternate $tbg2 focus $tbg2 selected $tbg2]
my Ttk_style map $ts -foreground [list disabled $tfgD pressed $tfg1 active $tfg2 alternate $tfg2 focus $tfg2 selected $tfg2]
my Ttk_style map $ts -bordercolor [list focus $bclr pressed $bclr]
my Ttk_style map $ts -lightcolor [list focus $bclr]
my Ttk_style map $ts -darkcolor [list focus $bclr]
my Ttk_style configure $ts -fieldforeground $tfg2
my Ttk_style configure $ts -fieldbackground $tbg2}
my Ttk_style configure TMenu.Frame -foreground yellow
my Ttk_style configure TMenu.Frame -background green
foreach ts {TNotebook TPanedwindow TFrame} {my Ttk_style configure $ts -background $tbg1}
foreach ts {TNotebook.Tab} {my Ttk_style configure $ts -font apaveFontDef
my Ttk_style map $ts -foreground [list selected $tfgS active $tfg2]
my Ttk_style map $ts -background [list selected $tbgS active $tbg2]}
foreach ts {TEntry Treeview TSpinbox TCombobox TCombobox.Spinbox TProgressbar} {my Ttk_style configure $ts -font apaveFontDef
my Ttk_style configure $ts -selectforeground $tfgS
my Ttk_style configure $ts -selectbackground $tbgS
my Ttk_style configure $ts -font apaveFontDef
my Ttk_style map $ts -selectforeground [list !focus $::apave::_CS_(!FG)]
my Ttk_style map $ts -selectbackground [list !focus $::apave::_CS_(!BG)]
my Ttk_style configure $ts -fieldforeground $tfg2
my Ttk_style configure $ts -fieldbackground $tbg2
my Ttk_style configure $ts -insertcolor $tcur
my Ttk_style map $ts -bordercolor [list focus $bclr active $bclr]
my Ttk_style map $ts -lightcolor [list focus $bclr]
my Ttk_style map $ts -darkcolor [list focus $bclr]
my Ttk_style configure $ts -insertwidth $::apave::_CS_(CURSORWIDTH)
if {$ts=="TCombobox"} {my Ttk_style configure $ts -foreground $tfg1
my Ttk_style configure $ts -background $tbg1
my Ttk_style map $ts -foreground [list readonly $tfg1]
my Ttk_style map $ts -background [list {readonly focus} $tbg1]
my Ttk_style map $ts -fieldbackground [list readonly $tbg1]
my Ttk_style map $ts -background [list active $tbg2]
option add *TCombobox*Listbox.font apaveFontDef userDefault
foreach {i nam clr} {0 back tbg1 1 fore tfg1 2 selectBack tbgS 3 selectFore tfgS} {option add *TCombobox*Listbox.${nam}ground [set $clr] userDefault}
} else {my Ttk_style configure $ts -foreground $tfg2
my Ttk_style configure $ts -background $tbg2
my Ttk_style map $ts -foreground [list disabled $tfgD readonly $tfgD selected $tfgS]
my Ttk_style map $ts -background [list disabled $tbgD readonly $tbgD selected $tbgS]}}
foreach ts {TRadiobutton TCheckbutton} {ttk::style map $ts -background [list focus $tbg2 !focus $tbg1]}
foreach ts [my NonThemedWidgets button] {set ::apave::_C_($ts,0) 5
set ::apave::_C_($ts,1) "-background $tbg1"
set ::apave::_C_($ts,2) "-foreground $tfg1"
set ::apave::_C_($ts,3) "-activeforeground $tfg2"
set ::apave::_C_($ts,4) "-activebackground $tbg2"
set ::apave::_C_($ts,5) "-font apaveFontDef"
switch -- $ts {checkbutton - radiobutton {set ::apave::_C_($ts,0) 7
set ::apave::_C_($ts,6) "-selectcolor $tbg1"
set ::apave::_C_($ts,7) "-highlightbackground $tbg1"}
frame - scrollbar - tframe - tnotebook {set ::apave::_C_($ts,0) 1}
menu {set ::apave::_C_($ts,0) 6
set ::apave::_C_($ts,1) "-background $tbgM"
set ::apave::_C_($ts,3) "-activeforeground $tfgS"
set ::apave::_C_($ts,4) "-activebackground $tbgS"
set ::apave::_C_($ts,5) "-borderwidth 2"
set ::apave::_C_($ts,6) "-relief raised"}}}
foreach ts [my NonThemedWidgets entry] {set ::apave::_C_($ts,0) 2
set ::apave::_C_($ts,1) "-foreground $tfg2"
set ::apave::_C_($ts,2) "-background $tbg2"
switch -- $ts {tcombobox {set ::apave::_C_($ts,0) 7
set ::apave::_C_($ts,3) "-insertbackground $tcur"
set ::apave::_C_($ts,4) "-disabledforeground $tfgD"
set ::apave::_C_($ts,5) "-disabledbackground $tbgD"
set ::apave::_C_($ts,6) "-highlightcolor $bclr"
set ::apave::_C_($ts,7) "-font apaveFontDef"}
text - entry - tentry {set ::apave::_C_($ts,0) 10
set ::apave::_C_($ts,3) "-insertbackground $tcur"
set ::apave::_C_($ts,4) "-selectforeground $tfgS"
set ::apave::_C_($ts,5) "-selectbackground $tbgS"
set ::apave::_C_($ts,6) "-disabledforeground $tfgD"
set ::apave::_C_($ts,7) "-disabledbackground $tbgD"
set ::apave::_C_($ts,8) "-highlightcolor $bclr"
if {$ts eq "text"} {set ::apave::_C_($ts,9) "-font {[font configure apaveFontMono]}"
} else {set ::apave::_C_($ts,9) "-font {[font configure apaveFontDef]}"}
set ::apave::_C_($ts,10) "-insertwidth $::apave::_CS_(CURSORWIDTH)"}
spinbox - tspinbox - listbox - tablelist {set ::apave::_C_($ts,0) 11
set ::apave::_C_($ts,3) "-highlightcolor $bclr"
set ::apave::_C_($ts,4) "-insertbackground $tcur"
set ::apave::_C_($ts,5) "-buttonbackground $tbg2"
set ::apave::_C_($ts,6) "-selectforeground $::apave::_CS_(!FG)"
set ::apave::_C_($ts,7) "-selectbackground $::apave::_CS_(!BG)"
set ::apave::_C_($ts,8) "-disabledforeground $tfgD"
set ::apave::_C_($ts,9) "-disabledbackground $tbgD"
set ::apave::_C_($ts,10) "-font apaveFontDef"
set ::apave::_C_($ts,11) "-insertwidth $::apave::_CS_(CURSORWIDTH)"}}}
foreach ts {disabled} {set ::apave::_C_($ts,0) 4
set ::apave::_C_($ts,1) "-foreground $tfgD"
set ::apave::_C_($ts,2) "-background $tbgD"
set ::apave::_C_($ts,3) "-disabledforeground $tfgD"
set ::apave::_C_($ts,4) "-disabledbackground $tbgD"}
foreach ts {readonly} {set ::apave::_C_($ts,0) 2
set ::apave::_C_($ts,1) "-foreground $tfg1"
set ::apave::_C_($ts,2) "-background $tbg1"}
my themeNonThemed $win
foreach {typ v1 v2} $args {if {$typ=="-"} {set ind [incr ::apave::_C_($v1,0)]
set ::apave::_C_($v1,$ind) "$v2"
} else {my Ttk_style map $typ $v1 [list {*}$v2]}}
return}
method UpdateSelectAttrs {w} {if { [string first "-selectforeground" [bind $w "<FocusIn>"]] < 0} {set com "lassign \[::apave::parseOptions \[ttk::style configure .\]         -selectforeground $::apave::_CS_(!FG)         -selectbackground $::apave::_CS_(!BG)\] fS bS;"
bind $w <FocusIn> "+ $com $w configure         -selectforeground \$fS -selectbackground \$bS"
bind $w <FocusOut> "+ $w configure -selectforeground         $::apave::_CS_(!FG) -selectbackground $::apave::_CS_(!BG)"}
return}
method untouchWidgets {args} {foreach u $args {lappend ::apave::_CS_(untouch) $u}}
method themeNonThemed {win} {set wtypes [my NonThemedWidgets all]
foreach w1 [winfo children $win] {my themeNonThemed $w1
set ts [string tolower [winfo class $w1]]
set tch 1
foreach u $::apave::_CS_(untouch) {if {[string match $u $w1]} {set tch 0; break}}
if {$tch && [info exist ::apave::_C_($ts,0)] && [lsearch -exact $wtypes $ts]>-1} {set i 0
while {[incr i] <= $::apave::_C_($ts,0)} {lassign $::apave::_C_($ts,$i) opt val
catch {if {[string first __tooltip__.label $w1]<0} {$w1 configure $opt $val
switch -- [$w1 cget -state] {"disabled" {$w1 configure {*}[my NonTtkStyle $w1 1]}
"readonly" {$w1 configure {*}[my NonTtkStyle $w1 2]}}}
set nam3 [string range [my ownWName $w1] 0 2]
if {$nam3 in {lbx tbl flb enT spX tex}} {my UpdateSelectAttrs $w1}}}}}
return}
method NonThemedWidgets {selector} {switch -- $selector {entry {return [list tspinbox tcombobox tentry entry text listbox spinbox tablelist]}
button {return [list label button menu menubutton checkbutton radiobutton frame labelframe scale scrollbar]}}
return [list tspinbox tcombobox tentry entry text listbox spinbox label button menu menubutton checkbutton radiobutton frame labelframe scale scrollbar tablelist]}
method NonTtkTheme {win} {if {[info exists ::apave::_C_(.,tfg1)] &&
$::apave::_CS_(expo,tfg1) ne "-"} {my themeWindow $win $::apave::_C_(.,tfg1) $::apave::_C_(.,tbg1) $::apave::_C_(.,tfg2) $::apave::_C_(.,tbg2) $::apave::_C_(.,tfgS) $::apave::_C_(.,tbgS) $::apave::_C_(.,tfgD) $::apave::_C_(.,tbgD) $::apave::_C_(.,tcur) $::apave::_C_(.,bclr) $::apave::_C_(.,thlp) $::apave::_C_(.,tfgI) $::apave::_C_(.,tbgI) $::apave::_C_(.,tfgM) $::apave::_C_(.,tbgM) false {*}$::apave::_C_(.,args)}
return}
method NonTtkStyle {typ {dsbl 0}} {if {$dsbl} {set disopt ""
if {$dsbl==1 && [info exist ::apave::_C_(disabled,0)]} {set typ [string range [lindex [split $typ .] end] 0 2]
switch -- $typ {frA - lfR {append disopt " " $::apave::_C_(disabled,2)}
enT - spX {append disopt " " $::apave::_C_(disabled,1) " " $::apave::_C_(disabled,2) " " $::apave::_C_(disabled,3) " " $::apave::_C_(disabled,4)}
laB - tex - chB - raD - lbx - scA {append disopt " " $::apave::_C_(disabled,1) " " $::apave::_C_(disabled,2)}}
} elseif {$dsbl==2 && [info exist ::apave::_C_(readonly,0)]} {append disopt " " $::apave::_C_(readonly,1) " " $::apave::_C_(readonly,2) }
return $disopt}
set opts {-foreground -foreground -background -background}
lassign "" ts2 ts3 opts2 opts3
switch -- $typ {"buT" {set ts TButton}
"chB" {set ts TCheckbutton
lappend opts -background -selectcolor}
"enT" {set ts TEntry
set opts  {-foreground -foreground -fieldbackground -background \
-insertbackground -insertcolor}}
"tex" {set ts TEntry
set opts {-foreground -foreground -fieldbackground -background \
          -insertcolor -insertbackground \
          -selectforeground -selectforeground -selectbackground -selectbackground
}}
"frA" {set ts TFrame; set opts {-background -background}}
"laB" {set ts TLabel}
"lbx" {set ts TLabel}
"lfR" {set ts TLabelframe}
"raD" {set ts TRadiobutton}
"scA" {set ts TScale}
"sbH" -
"sbV" {set ts TScrollbar; set opts {-background -background}}
"spX" {set ts TSpinbox}
default {return ""}}
set att ""
for {set i 1} {$i<=3} {incr i} {if {$i>1} {set ts [set ts$i]
set opts [set opts$i]}
foreach {opt1 opt2} $opts {if {[catch {set val [ttk::style configure $ts $opt1]}]} {return $att}
if {$val==""} {catch { set val [ttk::style $oper . $opt2] }}
if {$val!=""} {append att " $opt2 $val"}}}
return $att}
method ThemePopup {mnu args} {if {[set last [$mnu index end]] ne "none"} {$mnu configure {*}$args
for {set i 0} {$i <= $last} {incr i} {switch -- [$mnu type $i] {"cascade" {my ThemePopup [$mnu entrycget $i -menu] {*}$args}
"command" {$mnu entryconfigure $i {*}$args}}}}}
method themePopup {mnu} {if {[my csCurrent] == $::apave::_CS_(NONCS)} return
lassign [my csGet] - fg - bg2 - bgS fgS - - - - - - bg
if {[my csCurrent] > $::apave::_CS_(STDCS)} {set bg $bg2}
my ThemePopup $mnu -foreground $fg -background $bg -activeforeground $fgS -activebackground $bgS}
method initTooltip {args} {if {[info commands ::baltip::configure] eq ""} {package require baltip}
lassign [lrange [my csGet] 14 15] fW bW
::baltip config -fg $fW -bg $bW -global yes
::baltip config {*}$args
return}}
#by trimmer
