# _______________________________________________________________________ #
package require Tk
namespace eval ::apave {set ::apave::FGMAIN #000000
set ::apave::BGMAIN #d9d9d9
set ::apave::FONTMAIN [font actual TkDefaultFont]
set ::apave::FONTMAINBOLD [list {*}$::apave::FONTMAIN -weight bold]
variable _PU_opts;       array set _PU_opts [list -NONE =NONE=]
variable _AP_Properties; array set _AP_Properties [list]
set _PU_opts(_ERROR_) {}
set _PU_opts(_EOL_) {}
set _PU_opts(_LOGFILE_) {}
variable _CS_
array set _CS_ [list]
variable _C_
array set _C_ [list]
variable _MC_
array set _MC_ [list]
set ::apave::_CS_(ALL) {
{{ 0: AzureLight} "#050b0d" #050b0d #e9e9e7 #ebebe9 #002aaa #1b9ae9 #fff #444 grey #007fff #000 #AFAFAF - #e1e1df #000 #FBFB95 #e2e2e0 #ad0000 #004 #005 #006 #007}
{{ 1: ForestLight} "#050b0d" #050b0d #fafaf8 #efefed #004000 #A8CCA8 #000 #444 grey #217346 #000 #AFAFAF - #e5ffe5 #000 #FBFB95 #e2e2e0 #ad0000 #004 #005 #006 #007}
{{ 2: SunValleyLight} "#050b0d" #050b0d #e9e9e7 #ebebe9 #00469f #5586fe #fff #444 grey #005fb8 #000 #AFAFAF - #e1e1df #000 #FBFB95 #e2e2e0 #ad0000 #004 #005 #006 #007}
{{ 3: Grey1} "#050b0d" #050b0d #F8F8F8 #dadad8 #5c1616 #AFAFAF #000 #444 grey #933232 #000 #AFAFAF - #caccd0 #000 #FBFB95 #e0e0d8 #a20000 #004 #005 #006 #007}
{{ 4: Grey2} "#050b0d" #050b0d #e9e9e7 #F8F8F8 #5c1616 #AFAFAF #000 #444 grey #933232 #000 #AFAFAF - #e1e1df #000 #FBFB95 #d5d5d3 #a20000 #004 #005 #006 #007}
{{ 5: Rosy} "#2B122A" #000 #FFFFFF #F6E6E9 #570957 #C5ADC8 #000 #444 grey #870287 #000 #C5ADC8 - #e3d3d6 #000 #FBFB95 #e5e3e1 #a20000 #004 #005 #006 #007}
{{ 6: Clay} "#000" #000 #fdf4ed #ded3cc #500a0a #bcaea2 #000 #444 grey #843500 #fff #9a8f83 - #d5c9c1 #000 #FBFB95 #e1dfde #a20000 #004 #005 #006 #007}
{{ 7: Dawn} "#08085D" #030358 #FFFFFF #e3f9f9 #562222 #a3dce5 #000 #444 grey #933232 #000 #99d2db - #d3e9e9 #000 #FBFB96 #dbe9ed #a20000 #004 #005 #006 #007}
{{ 8: Sky} "#102433" #0A1D33 #d0fdff #bdf6ff #562222 #95ced7 #000 #444 grey #933232 #000 #9fd8e1 - #b1eaf3 #000 #FBFB95 #c0e9ef #a20000 #004 #005 #006 #007}
{{ 9: Celestial} "#141414" #151616 #d1ffff #a9e2f8 #562222 #82bbd1 #000 #444 grey #933232 #000 #7fb8ce - #9dd6f9 #000 #FBFB96 #b6e4e4 #a20000 #004 #005 #006 #007}
{{10: Florid} "#000" #004000 #e4fce4 #fff #5c1616 #93e493 #0F2D0F #444 grey #802e00 #004000 #a7f8a7 - #eefdee #000 #FBFB96 #d7e6d7 #a20000 #004 #005 #006 #007}
{{11: LightGreen} "#122B05" #091900 #edffed #DEF8DE #562222 #A8CCA8 #000 #444 grey #933232 #000 #A8CCA8 - #d0ead0 #000 #FBFB96 #dee9de #a20000 #004 #005 #006 #007}
{{12: InverseGreen} "#122B05" #091900 #cce6c8 #DEF8DE #562222 #9cc09c #000 #444 grey #933232 #000 #b5d9b5 - #cce6cc #000 #FBFB96 #bed8ba #a20000 #004 #005 #006 #007}
{{13: GreenPeace} "#001000" #001000 #e1ffdd #cadfca #562222 #9dbb99 #000 #444 grey #933232 #000 #9cb694 - #c1dfbd #000 #FBFB96 #d2e1d2 #a20000 #004 #005 #006 #007}
{{14: African} "#000" #000 #fff #ffffe7 #460000 #ffd797 #000 #6f2509 #7e7e7e #771d00 #000 #e6ae80 - #fffff9 #000 #eded89 #ededd5 #a20000 #004 #005 #006 #007}
{{15: African1} "#000" #000 #f5f5dd #f2ebd2 #460000 #ffc48a #000 #6f2509 #7e7e7e #771d00 #000 #e6ae80 - #fffce3 #000 #eded89 #e3e3cb #a20000 #004 #005 #006 #007}
{{16: African2} "#000" #000 #ffffe4 #eae7c0 #500a0a #eaac7a #000 #6f2509 grey #771d00 #00003c #e6ae80 - #f4f0ca #000 #fbfb74 #e7e7cb #a20000 #004 #005 #006 #007}
{{17: African3} "#000" #000 #fdf9d0 #d5d2af #500a0a #d59d6f #000 #6f2509 grey #771d00 #00003c #e6ae80 - #dedbb8 #000 #fbfb74 #e5e5cc #c10000 #004 #005 #006 #007}
{{18: Yellowstone} "#00002f" #00003c #ffffd1 #cfcdb1 #591c0e #c89160 #000 #444 grey #771d00 #3b1516 #cfab86 - #c2c0a4 #000 #ffff45 #e6e6bb #a30000 #004 #005 #006 #007}
{{19: Notebook} "#000" #000 #e9e1c8 #c2bca8 #460000 #d59d6f #000 #444 #7e7e7e #771d00 #000 #c09c77 - #d0cab6 #000 #eded89 #dad2b9 #a20000 #004 #005 #006 #007}
{{20: Notebook1} "#000" #000 #dad2b9 #b5af9b #460000 #d59d6f #000 #444 #707070 #771d00 #000 #ba9671 - #c5bfab #000 #eded89 #ccc4ab #a20000 #004 #005 #006 #007}
{{21: Notebook2} "#000" #000 #cdc5ac #a6a08c #460000 #d59d6f #000 #444 #606060 #771d00 #000 #cfab86 - #b4ae9a #000 #eded89 #c1b9a0 #980000 #004 #005 #006 #007}
{{22: Notebook3} "#000" #000 #beb69d #96907c #460000 #d59d6f #000 #444 #505050 #771d00 #000 #cfab86 - #a6a08c #000 #eded89 #b2aa91 #7b1010 #004 #005 #006 #007}
{{23: Darcula} "#ececec" #c7c7c7 #272727 #323232 #e98f1c #2F5692 #e1e1e1 #f4f49f grey #d18d3f #EDC881 #1e4581 - #444444 #000 #a2a23e #343434 #f28787 #004 #005 #006 #007}
{{24: AzureDark} "#ececec" #c7c7c7 #272727 #393939 #28a7ff #007fff #FFF #f4f49f grey #007fff #EDC881 #006ded - #444444 #000 #a2a23e #404040 #ff95ff #004 #005 #006 #007}
{{25: ForestDark} "#ececec" #c7c7c7 #272727 #393939 #5aac7f #217346 #FFF #f4f49f grey #009200 #EDC881 #0a5c2f - #444444 #000 #a2a23e #404040 #ff9595 #004 #005 #006 #007}
{{26: SunValleyDark} "#dfdfdf" #dddddd #131313 #252525 #38a9e0 #2f60d8 #FFF #f4f49f #6f6f6f #57c8ff #fff #2051c9 - #2d2d2d #000 #a2a23e #2a2a2a #ff95ff #004 #005 #006 #007}
{{27: Dark} "#F0E8E8" #E7E7E7 #272727 #323232 #de9e5e #707070 #000 #f4f49f grey #eda95b #000 #767676 - #454545 #000 #cdcd69 #2e2e2e #ffabab #004 #005 #006 #007}
{{28: Dark1} "#E0D9D9" #C4C4C4 #212121 #292929 #de9e5e #6c6c6c #000 #f4f49f #606060 #eda95b #000 #767676 - #363636 #000 #cdcd69 #292929 #ffabab #004 #005 #006 #007}
{{29: Dark2} "#bebebe" #bebebe #1f1f1f #262626 #de9e5e #6b6b6b #000 #f4f49f #616161 #eda95b #000 #767676 - #2b2b2b #000 #b0b04c #262626 #ffabab #004 #005 #006 #007}
{{30: Dark3} "#bebebe" #bebebe #0a0a0a #232323 #de9e5e #6a6a6a #000 #f4f49f #616161 #eda95b #000 #767676 - #1c1c1c #000 #bebe5a #131313 #ffabab #004 #005 #006 #007}
{{31: Oscuro} "#f1f1f1" #f1f1f1 #344545 #526d6d #f1b479 #728d8d #fff #f4f49f #afafaf #cc994a #000 #94afaf - #4f6666 #000 #cdcd69 #3d4e4e #ffbcbc #004 #005 #006 #007}
{{32: Oscuro1} "#f1f1f1" #f1f1f1 #2a3b3b #466161 #e5a565 #6c8787 #fff #f4f49f #a2a2a2 #c99647 #000 #8ba6a6 - #4a6161 #000 #cdcd69 #354646 #ffbcbc #004 #005 #006 #007}
{{33: Oscuro2} "#f1f1f1" #f1f1f1 #223333 #3e5959 #de9e5e #668181 #fff #f4f49f #a2a2a2 #c69344 #000 #819c9c - #3f5656 #000 #cdcd69 #2b3c3c #ffbcbc #004 #005 #006 #007}
{{34: Oscuro3} "#f1f1f1" #f1f1f1 #192a2a #355050 #de9e5e #5c7777 #fff #f4f49f #9e9e9e #c28f40 #000 #779292 - #364d4d #000 #cdcd69 #223333 #ffbcbc #004 #005 #006 #007}
{{35: MildDark} "#d2d2d2" #fff #222323 #384e66 #2ccaca #4b7391 #fff #00ffff #939393 #43e1e1 #000 #668eac - #394d64 #000 #bebe5a #2b2c2c #ffa2a2 #004 #005 #006 #007}
{{36: MildDark1} "#d2d2d2" #fff #151616 #2D435B #2ac8c8 #436b89 #fff #00ffff grey #36d4d4 #000 #668eac - #2e4259 #000 #bebe5a #1f2020 #ffb0b0 #004 #005 #006 #007}
{{37: MildDark2} "#b4b4b4" #fff #0d0e0e #24384f #28c6c6 #3e6684 #fff #00ffff #757575 #33d1d1 #000 #668eac - #253a52 #000 #bebe5a #161717 #ffaeae #004 #005 #006 #007}
{{38: MildDark3} "#e2e2e2" #f1f1f1 #000 #1B3048 #27c5c5 #375f7d #fff #00ffff #6c6c6c #31d0d0 #000 #668eac - #192e46 #000 #b0b04c #0f0f0f #ffafaf #004 #005 #006 #007}
{{39: Inkpot} "#d3d3ff" #AFC2FF #16161f #1E1E27 #de9e5e #6767a8 #000 #f4f49f #6e6e6e #ffbb6d #000 #8585c6 - #292936 #000 #a2a23e #202029 #ffa5a5 #004 #005 #006 #007}
{{40: Quiverly} "#cdd8d8" #cdd8d8 #2b303b #333946 #de9e5e #6f7582 #000 #f4f49f #757575 #eda95b #000 #9197a4 - #414650 #000 #b0b04c #323742 #ffabab #004 #005 #006 #007}
{{41: Monokai} "#f8f8f2" #f8f8f2 #353630 #4e5044 #f1b479 #707070 #000 #f4f49f #9a9a9a #ffbb6d #000 #777777 - #46473d #000 #cdcd69 #3c3d37 #ffabab #004 #005 #006 #007}
{{42: Desert} "#fff" #fff #47382d #5a4b40 #f1b479 #78695e #000 #f4f49f #a2a2a2 #ffbb6d #000 #7f7065 - #55463b #000 #eded89 #503f34 #ffabab #004 #005 #006 #007}
{{43: Magenta} "#E8E8E8" #F0E8E8 #381e44 #4A2A4A #f1b479 #846484 #000 #f4f49f grey #ffbb6d #000 #ad8dad - #573757 #000 #cdcd69 #42284e #ffabab #004 #005 #006 #007}
{{44: Red} "#fff" #e9e9e6 #340202 #440702 #f1b479 #b05e5e #000 #f4f49f #828282 #ffbb6d #000 #ba6868 - #3e0100 #000 #bebe5a #461414 #ffc1c1 #004 #005 #006 #007}
{{45: Chocolate} "#d6d1ab" #d6d1ab #251919 #402020 #de9e5e #664D4D #fff #f4f49f #828282 #c3984a #fff #583f3f - #361d1d #000 #b0b04c #2d2121 #ffb7b7 #004 #005 #006 #007}
{{46: Dusk} "#ececec" #ececec #1a1f21 #262b2d #f1b479 #6b7072 #000 #f4f49f #585d5f #ffbb6d #000 #6b7072 - #363b3d #000 #9e9e3a #23282a #ffabab #004 #005 #006 #007}
{{47: TKE Default} "#dbdbdb" #dbdbdb #000 #282828 #de9e5e #0a0acc #fff #f4f49f #6a6a6a #bd9244 #fff #0000d3 - #383838 #000 #b0b04c #0d0e0e #ffabab #004 #005 #006 #007}
}
set ::apave::_CS_(initall) 1
set ::apave::_CS_(initWM) 1
set ::apave::_CS_(!FG) #000000
set ::apave::_CS_(!BG) #b7b7b7
set ::apave::_CS_(expo,tfg1) "-"
set ::apave::_CS_(defFont) [font actual TkDefaultFont -family]
set ::apave::_CS_(textFont) [font actual TkFixedFont -family]
set ::apave::_CS_(fs) [font actual TkDefaultFont -size]
set ::apave::_CS_(untouch) [list]
set ::apave::_CS_(STDCS) [expr {[llength $::apave::_CS_(ALL)] - 1}]
set ::apave::_CS_(NONCS) -2
set ::apave::_CS_(MINCS) -1
set ::apave::_CS_(old) $::apave::_CS_(NONCS)
set ::apave::_CS_(TONED) [list -2 no]
set ::apave::_CS_(LABELBORDER) 0
namespace eval ::tk { ; # just to get localized messages
foreach m {&Abort &Cancel &Copy Cu&t &Delete E&xit &Filter &Ignore &No OK Open P&aste &Quit &Retry &Save "Save As" &Yes Close "To clipboard" Zoom Size} {set m2 [string map {"&" ""} $m]
set ::apave::_MC_($m2) [string map {"&" ""} [msgcat::mc $m]]}}}
proc ::iswindows {} {return [expr {$::tcl_platform(platform) eq "windows"} ? 1: 0]}
proc ::islinux {} {return [expr {$::tcl_platform(platform) eq "unix"} ? 1: 0]}
proc ::apave::mc {msg} {variable _MC_
if {[info exists _MC_($msg)]} {return $_MC_($msg)}
return $msg}
proc ::apave::initPOP {w} {bind $w <KeyPress> {if {"%K" eq "Menu"} {if {[winfo exists [set w [focus]]]} {event generate $w <Button-3> -rootx [winfo pointerx .] -rooty [winfo pointery .]}}}}
proc ::apave::initStyles {} {::apave::obj create_Fonts
ttk::style configure TButtonWest {*}[ttk::style configure TButton]
ttk::style configure TButtonWest -anchor w -font $::apave::FONTMAIN
ttk::style map       TButtonWest {*}[ttk::style map TButton]
ttk::style layout    TButtonWest [ttk::style layout TButton]
ttk::style configure TButtonBold {*}[ttk::style configure TButton]
ttk::style configure TButtonBold -font $::apave::FONTMAINBOLD
ttk::style map       TButtonBold {*}[ttk::style map TButton]
ttk::style layout    TButtonBold [ttk::style layout TButton]
ttk::style configure TButtonWestBold {*}[ttk::style configure TButton]
ttk::style configure TButtonWestBold -anchor w -font $::apave::FONTMAINBOLD
ttk::style map       TButtonWestBold {*}[ttk::style map TButton]
ttk::style layout    TButtonWestBold [ttk::style layout TButton]
ttk::style configure TMenuButtonWest {*}[ttk::style configure TMenubutton]
ttk::style configure TMenuButtonWest -anchor w -font $::apave::FONTMAIN -relief raised
ttk::style map       TMenuButtonWest {*}[ttk::style map TMenubutton]
ttk::style layout    TMenuButtonWest [ttk::style layout TMenubutton]}
proc ::apave::initStylesFS {args} {::apave::obj create_Fonts
set font  "$::apave::FONTMAIN $args"
set fontB "$::apave::FONTMAINBOLD $args"
ttk::style configure TLabelFS {*}[ttk::style configure TLabel]
ttk::style configure TLabelFS -font $font
ttk::style map       TLabelFS {*}[ttk::style map TLabel]
ttk::style layout    TLabelFS [ttk::style layout TLabel]
ttk::style configure TCheckbuttonFS {*}[ttk::style configure TCheckbutton]
ttk::style configure TCheckbuttonFS -font $font
ttk::style map       TCheckbuttonFS {*}[ttk::style map TCheckbutton]
ttk::style layout    TCheckbuttonFS [ttk::style layout TCheckbutton]
ttk::style configure TComboboxFS {*}[ttk::style configure TCombobox]
ttk::style configure TComboboxFS -font $font
ttk::style map       TComboboxFS {*}[ttk::style map TCombobox]
ttk::style layout    TComboboxFS [ttk::style layout TCombobox]
ttk::style configure TRadiobuttonFS {*}[ttk::style configure TRadiobutton]
ttk::style configure TRadiobuttonFS -font $font
ttk::style map       TRadiobuttonFS {*}[ttk::style map TRadiobutton]
ttk::style layout    TRadiobuttonFS [ttk::style layout TRadiobutton]
ttk::style configure TButtonWestFS {*}[ttk::style configure TButton]
ttk::style configure TButtonWestFS -anchor w -font $font
ttk::style map       TButtonWestFS {*}[ttk::style map TButton]
ttk::style layout    TButtonWestFS [ttk::style layout TButton]
ttk::style configure TButtonBoldFS {*}[ttk::style configure TButton]
ttk::style configure TButtonBoldFS -font $fontB
ttk::style map       TButtonBoldFS {*}[ttk::style map TButton]
ttk::style layout    TButtonBoldFS [ttk::style layout TButton]
ttk::style configure TButtonWestBoldFS {*}[ttk::style configure TButton]
ttk::style configure TButtonWestBoldFS -anchor w -font $fontB
ttk::style map       TButtonWestBoldFS {*}[ttk::style map TButton]
ttk::style layout    TButtonWestBoldFS [ttk::style layout TButton]}
proc ::apave::initWM {args} {if {!$::apave::_CS_(initWM)} return
lassign [::apave::parseOptions $args -cursorwidth $::apave::cursorwidth -theme {clam} -buttonwidth -8 -buttonborder 1 -labelborder 0 -padding 1] cursorwidth theme buttonwidth buttonborder labelborder padding
set ::apave::_CS_(initWM) 0
set ::apave::_CS_(CURSORWIDTH) $cursorwidth
set ::apave::_CS_(LABELBORDER) $labelborder
wm withdraw .
if {$::tcl_platform(platform) eq {windows}} {wm attributes . -alpha 0.0}
set tfg1 $::apave::_CS_(!FG)
set tbg1 $::apave::_CS_(!BG)
if {$theme ne {}} {catch {ttk::style theme use $theme}}
ttk::style map . -selectforeground [list !focus $tfg1 {focus active} $tfg1] -selectbackground [list !focus $tbg1 {focus active} $tbg1]
ttk::style configure . -selectforeground	$tfg1 -selectbackground	$tbg1
ttk::style configure TButton -anchor center -width $buttonwidth -relief raised -borderwidth $buttonborder -padding $padding
ttk::style configure TMenubutton -width 0 -padding 0
ttk::style configure TLabelSTD {*}[ttk::style configure TLabel]
ttk::style configure TLabelSTD -anchor w
ttk::style map       TLabelSTD {*}[ttk::style map TLabel]
ttk::style layout    TLabelSTD [ttk::style layout TLabel]
ttk::style configure TLabel -borderwidth $labelborder -padding $padding
set twfg [ttk::style map Treeview -foreground]
set twfg [::apave::putOption selected $tfg1 {*}$twfg]
set twbg [ttk::style map Treeview -background]
set twbg [::apave::putOption selected $tbg1 {*}$twbg]
ttk::style map Treeview -foreground $twfg
ttk::style map Treeview -background $twbg
ttk::style map TCombobox -fieldforeground [list {active focus} $tfg1 readonly $tfg1 disabled grey]
ttk::style map TCombobox -fieldbackground [list {active focus} $tbg1 {readonly focus} $tbg1 {readonly !focus} white]
initPOP .
initStyles
return}
proc ::apave::cs_Non {} {return $::apave::_CS_(NONCS)}
proc ::apave::cs_Min {} {return $::apave::_CS_(MINCS)}
proc ::apave::cs_Max {} {return [expr {[llength $::apave::_CS_(ALL)] - 1}]}
proc ::apave::cs_MaxBasic {} {return $::apave::_CS_(STDCS)}
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
if {$actopts} {if {$parg eq "--"} {set actopts false
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
proc ::apave::parseOptions {opts args} {lassign [::apave::parseOptionsFile 0 $opts {*}$args] tmp
foreach {nam val} $tmp {lappend retlist $val}
return $retlist}
proc ::apave::extractOptions {optsVar args} {upvar 1 $optsVar opts
set retlist [::apave::parseOptions $opts {*}$args]
foreach {o v} $args {set opts [::apave::removeOptions $opts $o]}
return $retlist}
proc ::apave::getOption {optname args} {set optvalue [lindex [::apave::parseOptions $args $optname ""] 0]
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
proc ::apave::error {{fileName ""}} {variable _PU_opts
if {$fileName eq ""} {return $_PU_opts(_ERROR_)}
return "Error of access to\n\"$fileName\"\n\n$_PU_opts(_ERROR_)"}
proc ::apave::textsplit {textcont} {return [split [string map [list \r\n \n \r \n] $textcont] \n]}
proc ::apave::textEOL {{EOL "-"}} {variable _PU_opts
if {$EOL eq "-"} {return $_PU_opts(_EOL_)}
if {$EOL eq "translation"} {if {$_PU_opts(_EOL_) eq ""} {return ""}
return "-translation $_PU_opts(_EOL_)"}
set _PU_opts(_EOL_) [string trim [string tolower $EOL]]}
proc ::apave::textChanConfigure {channel} {chan configure $channel -encoding utf-8
chan configure $channel {*}[::apave::textEOL translation]}
proc ::apave::logName {fname} {variable _PU_opts;
set _PU_opts(_LOGFILE_) $fname}
proc ::apave::logMessage {msg} {variable _PU_opts;
if {$_PU_opts(_LOGFILE_) eq {}} return
set chan [open $_PU_opts(_LOGFILE_) a]
set dt [clock format [clock seconds] -format {%d%b'%y %T}]
set msg "$dt $msg"
foreach i {-4 -3 -2 -1} {catch {lassign [info level $i] p1 p2
if {$p1 eq {my}} {append p1 " $p2"}
append msg " / $p1"}}
puts $chan $msg
close $chan
puts "$_PU_opts(_LOGFILE_) - $msg"}
proc ::apave::readTextFile {fileName {varName ""} {doErr 0}} {variable _PU_opts
if {$varName ne {}} {upvar $varName fvar}
if {[catch {set chan [open $fileName]} _PU_opts(_ERROR_)]} {if {$doErr} {error [::apave::error $fileName]}
set fvar {}
} else {::apave::textChanConfigure $chan
set fvar [read $chan]
close $chan
logMessage "read $fileName"}
return $fvar}
proc ::apave::writeTextFile {fileName {varName ""} {doErr 0}} {variable _PU_opts
if {$varName ne ""} {upvar $varName contents
} else {set contents ""}
if {[catch {set chan [open $fileName w]} _PU_opts(_ERROR_)]} {if {$doErr} {error [::apave::error $fileName]}
set res no
} else {::apave::textChanConfigure $chan
puts -nonewline $chan $contents
close $chan
logMessage "write $fileName"
set res yes}
return $res}
proc ::apave::openDoc {url} {
set commands {xdg-open open start}
foreach opener $commands {if {$opener eq "start"} {set command [list {*}[auto_execok start] {}]
} else {set command [auto_execok $opener]}
if {[string length $command]} {break}}
if {[string length $command] == 0} {puts "ERROR: couldn't find any opener"}
set url [string trimright $url]
if {[string match "* &" $url]} {set url [string range $url 0 end-2]}
set url [string trim $url]
if {[catch {exec {*}$command $url &} error]} {puts "ERROR: couldn't execute '$command':\n$error"}}
proc ::apave::setProperty {name args} {variable _AP_Properties
switch [llength $args] {0 {return [getProperty $name]}
1 {return [set _AP_Properties($name) [lindex $args 0]]}}
puts -nonewline stderr "Wrong # args: should be \"::apave::setProperty propertyname ?value?\""
return -code error}
proc ::apave::getProperty {name {defvalue ""}} {variable _AP_Properties
if {[info exists _AP_Properties($name)]} {return $_AP_Properties($name)}
return $defvalue}
proc ::apave::countChar {str ch} {set icnt 0
while {[set idx [string first $ch $str]] >= 0} {set backslashes 0
set nidx $idx
while {[string equal [string index $str [incr nidx -1]] \\]} {incr backslashes}
if {$backslashes % 2 == 0} { incr icnt }
set str [string range $str [incr idx] end]}
return $icnt}
oo::class create ::apave::ObjectProperty {variable _OP_Properties
constructor {args} {array set _OP_Properties {}
if {[llength [self next]]} { next {*}$args }}
destructor {array unset _OP_Properties
if {[llength [self next]]} next}
method setProperty {name args} {switch [llength $args] {0 {return [my getProperty $name]}
1 {return [set _OP_Properties($name) [lindex $args 0]]}}
puts -nonewline stderr "Wrong # args: should be \"[namespace current] setProperty propertyname ?value?\""
return -code error}
method getProperty {name {defvalue ""}} {if {[info exists _OP_Properties($name)]} {return $_OP_Properties($name)}
return $defvalue}}
oo::class create ::apave::ObjectTheming {mixin ::apave::ObjectProperty
constructor {args} {my InitCS
if {[llength [self next]]} { next {*}$args }}
destructor {if {[llength [self next]]} next}
method InitCS {} {if {$::apave::_CS_(initall)} {my basicFontSize 10
my basicTextFont $::apave::_CS_(textFont)
my ColorScheme
my untouchWidgets *_untouch_*
set ::apave::_CS_(initall) 0}
return}
method create_FontsType {type args} {set name1 apaveFontDefTyped$type
set name2 apaveFontMonoTyped$type
catch {font delete $name1}
catch {font delete $name2}
font create $name1 -family $::apave::_CS_(defFont) -size $::apave::_CS_(fs) {*}$args
font create $name2 -family $::apave::_CS_(textFont) -size $::apave::_CS_(fs) {*}$args
return [list $name1 $name2]}
method create_Fonts {} {catch {font delete apaveFontMono}
catch {font delete apaveFontDef}
catch {font delete apaveFontMonoBold}
catch {font delete apaveFontDefBold}
font create apaveFontMono -family $::apave::_CS_(textFont) -size $::apave::_CS_(fs)
font create apaveFontDef -family $::apave::_CS_(defFont) -size $::apave::_CS_(fs)
font create apaveFontMonoBold  {*}[my boldTextFont]
font create apaveFontDefBold {*}[my boldDefFont]
set ::apave::FONTMAIN "[font actual apaveFontDef]"
set ::apave::FONTMAINBOLD "[font actual apaveFontDefBold]"}
method Main_Style {tfg1 tbg1 tfg2 tbg2 tfgS tbgS bclr tc fA bA bD} {my create_Fonts
ttk::style configure "." -background        $tbg1 -foreground        $tfg1 -bordercolor       $bclr -darkcolor         $tbg1 -lightcolor        $tbg1 -troughcolor       $tc -arrowcolor        $tfg1 -selectbackground  $tbgS -selectforeground  $tfgS ;
ttk::style map "." -background       [list disabled $bD active $bA] -foreground       [list disabled grey active $fA]}
method ColorScheme {{ncolor ""}} {if {"$ncolor" eq "" || $ncolor<0} {set fW black
set bW #FBFB95
set bg2 #d8d8d8
if {[info exists ::apave::_CS_(def_fg)]} {if {$ncolor == $::apave::_CS_(NONCS)} {set bg2 #e5e5e5}
set fg $::apave::_CS_(def_fg)
set fg2 #2b3f55
set bg $::apave::_CS_(def_bg)
set fS $::apave::_CS_(def_fS)
set bS $::apave::_CS_(def_bS)
set bA $::apave::_CS_(def_bA)
} else {set ::apave::_CS_(index) $::apave::_CS_(NONCS)
lassign [::apave::parseOptions [ttk::style configure .] -foreground #000000 -background #d9d9d9 -troughcolor #c3c3c3] fg bg tc
set fS $::apave::_CS_(!FG)
set bS $::apave::_CS_(!BG)
lassign [::apave::parseOptions [ttk::style map . -background] disabled #d9d9d9 active #ececec] bD bA
if {$bA eq {#ececec}} {set bA #ffffff}
lassign [::apave::parseOptions [ttk::style map . -foreground] disabled #a3a3a3] fD
lassign [::apave::parseOptions [ttk::style map . -selectbackground] !focus #9e9a91] bclr
set ::apave::_CS_(def_fg) [set fg2 $fg]
set ::apave::_CS_(def_bg) $bg
set ::apave::_CS_(def_fS) $fS
set ::apave::_CS_(def_bS) $bS
set ::apave::_CS_(def_fD) $fD
set ::apave::_CS_(def_bD) $bD
set ::apave::_CS_(def_bA) $bA
set ::apave::_CS_(def_tc) $tc
set ::apave::_CS_(def_bclr) $bclr}
return [list default $fg    $fg     $bA    $bg     $fg2    $bS     $fS    #444  grey   #4f6379 $fS $bS - $bg $fW $bW $bg2]}
return [lindex $::apave::_CS_(ALL) $ncolor]}
method basicFontSize {{fs 0} {ds 0}} {if {$fs} {return [set ::apave::_CS_(fs) [expr {$fs + $ds}]]
} else {return [expr {$::apave::_CS_(fs) + $ds}]}}
method basicDefFont {{deffont ""}} {if {$deffont ne ""} {return [set ::apave::_CS_(defFont) $deffont]
} else {return $::apave::_CS_(defFont)}}
method boldDefFont {{fs 0}} {if {$fs == 0} {set fs [my basicFontSize]}
set bf [font actual basicDefFont]
return [dict replace $bf -family [my basicDefFont] -weight bold -size $fs]}
method basicTextFont {{textfont ""}} {if {$textfont ne ""} {return [set ::apave::_CS_(textFont) $textfont]
} else {return $::apave::_CS_(textFont)}}
method boldTextFont {{fs 0}} {if {$fs == 0} {set fs [expr {2+[my basicFontSize]}]}
set bf [font actual TkFixedFont]
return [dict replace $bf -family [my basicTextFont] -weight bold -size $fs]}
method csFont {fontname} {if {[catch {set font [font configure $fontname]}]} {my create_Fonts
set font [font configure $fontname]}
return $font}
method csFontMono {} {return [my csFont apaveFontMono]}
method csFontDef {} {return [my csFont apaveFontDef]}
method csDarkEdit {{cs -3}} {if {$cs eq -3} {set cs [my csCurrent]}
lassign $::apave::_CS_(TONED) csbasic cstoned
if {$cs==$cstoned} {set cs $csbasic}
return [expr {$cs>22}]}
method csExport {} {set theme ""
foreach arg {tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr args} {if {[catch {set a "$::apave::_CS_(expo,$arg)"}] || $a==""} {break}
append theme " $a"}
return $theme}
method csCurrent {} {return $::apave::_CS_(index)}
method csGetName {{ncolor 0}} {if {$ncolor < $::apave::_CS_(MINCS)} {return "Default"
} elseif {$ncolor == $::apave::_CS_(MINCS)} {return "-1: Basic"}
return [lindex [my ColorScheme $ncolor] 0]}
method csGet {{ncolor ""}} {if {$ncolor eq ""} {set ncolor [my csCurrent]}
return [lrange [my ColorScheme $ncolor] 1 end]}
method csSet {{ncolor 0} {win .} args} {if {$ncolor == -2} return
if {$ncolor eq {}} {lassign $args clrtitf clrinaf clrtitb clrinab clrhelp clractb clractf clrcurs clrgrey clrhotk tfgI tbgI fM bM tfgW tbgW tHL2 res3 res4 res5 res6 res7
} else {foreach cs [list $ncolor $::apave::_CS_(MINCS)] {lassign [my csGet $cs] clrtitf clrinaf clrtitb clrinab clrhelp clractb clractf clrcurs clrgrey clrhotk tfgI tbgI fM bM tfgW tbgW tHL2 res3 res4 res5 res6 res7
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
set grey $gr
if {$::apave::_CS_(old) != $ncolor || $args eq "-doit"} {set ::apave::_CS_(old) $ncolor
my themeWindow $win [list $fg $bg $fE $bE $fS $bS $grey $bg $cc $ht $hh $tfgI $tbgI $fM $bM $tfgW $tbgW $tHL2 $res3 $res4 $res5 $res6 $res7]
my UpdateColors
my initTooltip}
set ::apave::FGMAIN $fg
set ::apave::BGMAIN $bg
return [list $fg $bg $fE $bE $fS $bS $hh $grey $cc $ht $tfgI $tbgI $fM $bM $tfgW $tbgW $tHL2 $res3 $res4 $res5 $res6 $res7]}
method csAdd {newcs {setnew true}} {if {[llength $newcs]<4} {set newcs [my ColorScheme]}
lassign $newcs name tfg2 tfg1 tbg2 tbg1 tfhh - - tcur grey bclr
set found $::apave::_CS_(NONCS)
set maxcs [::apave::cs_Max]
for {set i $::apave::_CS_(MINCS)} {$i<=$maxcs} {incr i} {lassign [my csGet $i] cfg2 cfg1 cbg2 cbg1 cfhh - - ccur
if {$cfg2 eq $tfg2 && $cfg1 eq $tfg1 && $cbg2 eq $tbg2 && $cbg1 eq $tbg1 && $cfhh eq $tfhh && $ccur eq $tcur} {set found $i
break}}
if {$found == $::apave::_CS_(MINCS) && [my csCurrent] == $::apave::_CS_(NONCS)} {set setnew false
} elseif {$found == $::apave::_CS_(NONCS)} {lappend ::apave::_CS_(ALL) $newcs
set found [expr {$maxcs+1}]}
if {$setnew} {set ::apave::_CS_(index) [set ::apave::_CS_(old) $found]}
return [my csCurrent]}
method csDeleteExternal {} {set ::apave::_CS_(ALL) [lreplace $::apave::_CS_(ALL) 48 end]}
method csToned {cs hue} {if {$cs <= $::apave::_CS_(NONCS) || $cs > $::apave::_CS_(STDCS)} {return no}
my csDeleteExternal
set CS [my csGet $cs]
set mainc [my csMainColors]
set hue [expr {(100.0+$hue)/100.0}]
foreach i [my csMapTheme] {set color [lindex $CS $i]
if {$i in $mainc} {set color [string map {black #000000 white #ffffff grey #808080 red #ff0000 yellow #ffff00 orange #ffa500 #000 #000000 #fff #ffffff} $color]
scan $color "#%2x%2x%2x" R G B
foreach valname {R G B} {set val [expr {int([set $valname]*$hue)}]
set $valname [expr {max(min($val,255),0)}]}
set color [format "#%02x%02x%02x" $R $G $B]}
lappend TWargs $color}
my themeWindow . $TWargs no
set ::apave::_CS_(TONED) [list $cs [my csCurrent]]
return yes}
method Ttk_style {oper ts opt val} {if {![catch {set oldval [ttk::style $oper $ts $opt]}]} {catch {ttk::style $oper $ts $opt $val}
if {$oldval eq "" && $oper eq "configure"} {switch -- $opt {-foreground - -background {set oldval [ttk::style $oper . $opt]}
-fieldbackground {set oldval white}
-insertcolor {set oldval black}}}}
return}
method csMainColors {} {return [list 0 1 2 3 5 13 16]}
method csMapTheme {} {return [list 1 3 0 2 6 5 8 3 7 9 4 10 11 1 13 14 15 16 17 18 19 20 21]}
method apaveTheme {{theme {}}} {if {$theme eq {}} {set theme [ttk::style theme use]}
return [expr {$theme in {clam alt classic default awdark awlight}}]}
method themeWindow {win {clrs ""} {isCS true} args} {lassign $clrs tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr thlp tfgI tbgI tfgM tbgM twfg twbg tHL2 res3 res4 res5 res6 res7
if {$tfg1 eq "-"} return
if {!$isCS} {my csAdd [list CS-[expr {[::apave::cs_Max]+1}] $tfg2 $tfg1 $tbg2 $tbg1 $thlp $tbgS $tfgS $tcur $tfgD $bclr $tfgI $tbgI $tfgM $tbgM $twfg $twbg $tHL2 $res3 $res4 $res5 $res6 $res7]}
if {$tfgI eq ""} {set tfgI $tfg2}
if {$tbgI eq ""} {set tbgI $tbg2}
if {$tfgM in {"" -}} {set tfgM $tfg1}
if {$tbgM eq ""} {set tbgM $tbg1}
my Main_Style $tfg1 $tbg1 $tfg2 $tbg2 $tfgS $tbgS $tfgD $tbg1 $tfg1 $tbg2 $tbg1
foreach arg {tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr thlp tfgI tbgI tfgM tbgM twfg twbg tHL2 res3 res4 res5 res6 res7 args} {if {$win eq "."} {set ::apave::_C_($win,$arg) [set $arg]}
set ::apave::_CS_(expo,$arg) [set $arg]}
set fontdef [font actual apaveFontDef]
foreach ts {TLabel TLabelframe.Label TButton TCheckbutton TProgressbar TRadiobutton TNotebook.Tab} {my Ttk_style configure $ts -font $fontdef
my Ttk_style configure $ts -foreground $tfg1
my Ttk_style configure $ts -background $tbg1
my Ttk_style map $ts -background [list pressed $tbg1 active $tbg2 alternate $tbg2 focus $tbg2 selected $tbg2]
my Ttk_style map $ts -foreground [list disabled $tfgD pressed $bclr active $tfg2 alternate $tfg2 focus $tfg2 selected $tfg1]
my Ttk_style map $ts -bordercolor [list focus $bclr pressed $bclr]
my Ttk_style map $ts -lightcolor [list focus $bclr]
my Ttk_style map $ts -darkcolor [list focus $bclr]}
foreach ts {TNotebook TFrame} {my Ttk_style configure $ts -background $tbg1}
foreach ts {TNotebook.Tab} {my Ttk_style configure $ts -font $fontdef
if {[my apaveTheme]} {my Ttk_style map $ts -foreground [list selected $tfgS active $tfg2]}
my Ttk_style map $ts -background [list selected $tbgS {active disabled} $tbg1 active $tbg2]}
foreach ts {TEntry Treeview TSpinbox TCombobox TCombobox.Spinbox TMatchbox TNotebook.Tab TScrollbar TScale} {my Ttk_style map $ts -lightcolor [list focus $bclr active $bclr]
my Ttk_style map $ts -darkcolor [list focus $bclr active $bclr]}
if {[set cs [my csCurrent]]<20} {ttk::style conf TSeparator -background #a2a2a2
} elseif {$cs<23} {ttk::style conf TSeparator -background #656565
} elseif {$cs<28} {ttk::style conf TSeparator -background #3c3c3c
} elseif {$cs>35 && $cs<39} {ttk::style conf TSeparator -background #313131
} elseif {$cs==43 || $cs>44} {ttk::style conf TSeparator -background #2e2e2e}
foreach ts {TEntry Treeview TSpinbox TCombobox TCombobox.Spinbox TMatchbox} {my Ttk_style configure $ts -font $fontdef
my Ttk_style configure $ts -selectforeground $tfgS
my Ttk_style configure $ts -selectbackground $tbgS
my Ttk_style map $ts -selectforeground [list !focus $::apave::_CS_(!FG)]
my Ttk_style map $ts -selectbackground [list !focus $::apave::_CS_(!BG)]
my Ttk_style configure $ts -fieldforeground $tfg2
my Ttk_style configure $ts -fieldbackground $tbg2
my Ttk_style configure $ts -insertcolor $tcur
my Ttk_style map $ts -bordercolor [list focus $bclr active $bclr]
my Ttk_style configure $ts -insertwidth $::apave::_CS_(CURSORWIDTH)
if {$ts eq "TCombobox"} {my Ttk_style configure $ts -foreground $tfg1
my Ttk_style configure $ts -background $tbg1
my Ttk_style map $ts -foreground [list {readonly focus} $tfg2 {active focus} $tfg2]
my Ttk_style map $ts -background [list {readonly focus} $tbg2 {active focus} $tbg2]
my Ttk_style map $ts -fieldforeground [list {active focus} $tfg2 readonly $tfg2 disabled $tfgD]
my Ttk_style map $ts -fieldbackground [list {active focus} $tbg2 {readonly focus} $tbg2 {readonly !focus} $tbg1 disabled $tbgD]
} else {my Ttk_style configure $ts -foreground $tfg2
my Ttk_style configure $ts -background $tbg2
my Ttk_style map $ts -foreground [list readonly $tfgD disabled $tfgD selected $tfgS]
my Ttk_style map $ts -background [list readonly $tbgD disabled $tbgD selected $tbgS]
my Ttk_style map $ts -fieldforeground [list readonly $tfgD disabled $tfgD]
my Ttk_style map $ts -fieldbackground [list readonly $tbgD disabled $tbgD]}}
option add *Listbox.font $fontdef
option add *Menu.font $fontdef
my Ttk_style configure TMenubutton -foreground $tfgM
my Ttk_style configure TMenubutton -background $tbgM
foreach {nam clr} {back tbg1 fore tfg1 selectBack tbgS selectFore tfgS} {option add *Listbox.${nam}ground [set $clr]}
foreach {nam clr} {back tbgM fore tfgM selectBack tbgS selectFore tfgS} {option add *Menu.${nam}ground [set $clr]}
foreach ts {TRadiobutton TCheckbutton} {ttk::style map $ts -background [list focus $tbg2 !focus $tbg1]}
foreach ts [my NonThemedWidgets button] {set ::apave::_C_($ts,0) 6
set ::apave::_C_($ts,1) "-background $tbg1"
set ::apave::_C_($ts,2) "-foreground $tfg1"
set ::apave::_C_($ts,3) "-activeforeground $tfg2"
set ::apave::_C_($ts,4) "-activebackground $tbg2"
set ::apave::_C_($ts,5) "-font {$fontdef}"
set ::apave::_C_($ts,6) "-highlightbackground $tfgD"
switch -- $ts {checkbutton - radiobutton {set ::apave::_C_($ts,0) 8
set ::apave::_C_($ts,7) "-selectcolor $tbg1"
set ::apave::_C_($ts,8) "-highlightbackground $tbg1"}
frame - scrollbar - scale - tframe - tnotebook {set ::apave::_C_($ts,0) 8
set ::apave::_C_($ts,4) "-activebackground $bclr"
set ::apave::_C_($ts,7) "-troughcolor $tbg1"
set ::apave::_C_($ts,8) "-elementborderwidth 2"}
menu {set ::apave::_C_($ts,0) 9
set ::apave::_C_($ts,1) "-background $tbgM"
set ::apave::_C_($ts,3) "-activeforeground $tfgS"
set ::apave::_C_($ts,4) "-activebackground $tbgS"
set ::apave::_C_($ts,5) "-borderwidth 2"
set ::apave::_C_($ts,7) "-relief raised"
set ::apave::_C_($ts,8) "-disabledforeground $tfgD"
set ::apave::_C_($ts,9) "-font {$fontdef}"}
canvas {set ::apave::_C_($ts,1) "-background $tbg2"}}}
foreach ts [my NonThemedWidgets entry] {set ::apave::_C_($ts,0) 3
set ::apave::_C_($ts,1) "-foreground $tfg2"
set ::apave::_C_($ts,2) "-background $tbg2"
set ::apave::_C_($ts,3) "-highlightbackground $tfgD"
switch -- $ts {tcombobox - tmatchbox {set ::apave::_C_($ts,0) 8
set ::apave::_C_($ts,4) "-disabledforeground $tfgD"
set ::apave::_C_($ts,5) "-disabledbackground $tbgD"
set ::apave::_C_($ts,6) "-highlightcolor $bclr"
set ::apave::_C_($ts,7) "-font {$fontdef}"
set ::apave::_C_($ts,8) "-insertbackground $tcur"}
text - entry - tentry {set ::apave::_C_($ts,0) 11
set ::apave::_C_($ts,4) "-selectforeground $tfgS"
set ::apave::_C_($ts,5) "-selectbackground $tbgS"
set ::apave::_C_($ts,6) "-disabledforeground $tfgD"
set ::apave::_C_($ts,7) "-disabledbackground $tbgD"
set ::apave::_C_($ts,8) "-highlightcolor $bclr"
if {$ts eq "text"} {set ::apave::_C_($ts,9) "-font {[font actual apaveFontMono]}"
} else {set ::apave::_C_($ts,9) "-font {$fontdef}"}
set ::apave::_C_($ts,10) "-insertwidth $::apave::_CS_(CURSORWIDTH)"
set ::apave::_C_($ts,11) "-insertbackground $tcur"}
spinbox - tspinbox - listbox - tablelist {set ::apave::_C_($ts,0) 12
set ::apave::_C_($ts,4) "-insertbackground $tcur"
set ::apave::_C_($ts,5) "-buttonbackground $tbg2"
set ::apave::_C_($ts,6) "-selectforeground $::apave::_CS_(!FG)"
set ::apave::_C_($ts,7) "-selectbackground $::apave::_CS_(!BG)"
set ::apave::_C_($ts,8) "-disabledforeground $tfgD"
set ::apave::_C_($ts,9) "-disabledbackground $tbgD"
set ::apave::_C_($ts,10) "-font {$fontdef}"
set ::apave::_C_($ts,11) "-insertwidth $::apave::_CS_(CURSORWIDTH)"
set ::apave::_C_($ts,12) "-highlightcolor $bclr"}}}
foreach ts {disabled} {set ::apave::_C_($ts,0) 4
set ::apave::_C_($ts,1) "-foreground $tfgD"
set ::apave::_C_($ts,2) "-background $tbgD"
set ::apave::_C_($ts,3) "-disabledforeground $tfgD"
set ::apave::_C_($ts,4) "-disabledbackground $tbgD"}
foreach ts {readonly} {set ::apave::_C_($ts,0) 2
set ::apave::_C_($ts,1) "-foreground $tfg1"
set ::apave::_C_($ts,2) "-background $tbg1"}
my themeNonThemed $win
foreach {typ v1 v2} $args {if {$typ eq "-"} {set ind [incr ::apave::_C_($v1,0)]
set ::apave::_C_($v1,$ind) "$v2"
} else {my Ttk_style map $typ $v1 [list {*}$v2]}}
::apave::initStyles
my ThemeChoosers
catch {::bartabs::drawAll}
return}
method UpdateSelectAttrs {w} {if { [string first "-selectforeground" [bind $w "<FocusIn>"]] < 0} {set com "lassign \[::apave::parseOptions \[ttk::style configure .\]         -selectforeground $::apave::_CS_(!FG)         -selectbackground $::apave::_CS_(!BG)\] fS bS;"
bind $w <FocusIn> "+ $com $w configure         -selectforeground \$fS -selectbackground \$bS"
bind $w <FocusOut> "+ $w configure -selectforeground         $::apave::_CS_(!FG) -selectbackground $::apave::_CS_(!BG)"}
return}
method untouchWidgets {args} {if {[llength $args]==0} {return $::apave::_CS_(untouch)}
foreach u $args {if {[lsearch -exact $::apave::_CS_(untouch) $u]==-1} {lappend ::apave::_CS_(untouch) $u}}}
method themeNonThemed {win} {set wtypes [my NonThemedWidgets all]
foreach w1 [winfo children $win] {my themeNonThemed $w1
set ts [string tolower [winfo class $w1]]
set tch 1
foreach u $::apave::_CS_(untouch) {if {[string match $u $w1]} {set tch 0; break}}
if {$tch && [info exist ::apave::_C_($ts,0)] && [lsearch -exact $wtypes $ts]>-1} {set i 0
while {[incr i] <= $::apave::_C_($ts,0)} {lassign $::apave::_C_($ts,$i) opt val
catch {if {[string first __tooltip__.label $w1]<0} {$w1 configure $opt $val
switch -- [$w1 cget -state] {disabled {$w1 configure {*}[my NonTtkStyle $w1 1]}
readonly {$w1 configure {*}[my NonTtkStyle $w1 2]}}}
set nam3 [string range [my ownWName $w1] 0 2]
if {$nam3 in {lbx tbl flb enT spX tex}} {my UpdateSelectAttrs $w1}}}}}
return}
method NonThemedWidgets {selector} {switch -- $selector {entry {return [list tspinbox tcombobox tentry entry text listbox spinbox tablelist tmatchbox]}
button {return [list label button menu menubutton checkbutton radiobutton frame labelframe scale scrollbar canvas]}}
return [list tspinbox tcombobox tentry entry text listbox spinbox label button menu menubutton checkbutton radiobutton frame labelframe scale scrollbar canvas tablelist tmatchbox]}
method NonTtkTheme {win} {if {[info exists ::apave::_C_(.,tfg1)] &&
$::apave::_CS_(expo,tfg1) ne "-"} {my themeWindow $win [list $::apave::_C_(.,tfg1) $::apave::_C_(.,tbg1) $::apave::_C_(.,tfg2) $::apave::_C_(.,tbg2) $::apave::_C_(.,tfgS) $::apave::_C_(.,tbgS) $::apave::_C_(.,tfgD) $::apave::_C_(.,tbgD) $::apave::_C_(.,tcur) $::apave::_C_(.,bclr) $::apave::_C_(.,thlp) $::apave::_C_(.,tfgI) $::apave::_C_(.,tbgI) $::apave::_C_(.,tfgM) $::apave::_C_(.,tbgM) $::apave::_C_(.,twfg) $::apave::_C_(.,twbg) $::apave::_C_(.,tHL2)] false {*}$::apave::_C_(.,args)}
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
if {$val eq ""} {catch { set val [ttk::style $oper . $opt2] }}
if {$val ne ""} {append att " $opt2 $val"}}}
return $att}
method ThemePopup {mnu args} {if {[set last [$mnu index end]] ne "none"} {$mnu configure {*}$args
for {set i 0} {$i <= $last} {incr i} {switch -- [$mnu type $i] {"cascade" {my ThemePopup [$mnu entrycget $i -menu] {*}$args}
"command" {$mnu entryconfigure $i {*}$args}}}}}
method themePopup {mnu} {if {[my csCurrent] == $::apave::_CS_(NONCS)} return
lassign [my csGet] - fg - bg2 - bgS fgS - tfgD - - - - bg
if {$bg eq ""} {set bg $bg2}
set opts "-foreground $fg -background $bg -activeforeground $fgS       -activebackground $bgS -font {[font actual apaveFontDef]}"
if {[catch {my ThemePopup $mnu {*}$opts -disabledforeground $tfgD}]} {my ThemePopup $mnu {*}$opts}}
method initTooltip {args} {if {[info commands ::baltip::configure] eq ""} {package require baltip}
lassign [lrange [my csGet] 14 15] fW bW
::baltip config -fg $fW -bg $bW -global yes
::baltip config {*}$args
return}
method ThemeChoosers {} {if {[info commands ::apave::_TK_TOPLEVEL] ne ""} return
rename ::toplevel ::apave::_TK_TOPLEVEL
proc ::toplevel {args} {set res [eval ::apave::_TK_TOPLEVEL $args]
set w [lindex $args 0]
rename $w ::apave::_W_TOPLEVEL$w
proc ::$w {args} "         set cs \[::apave::obj csCurrent\] ;        if {{configure -menu} eq \$args} {set args {configure}} ;        if {\$cs>-2 && \[string first {configure} \$args\]==0} {           lassign \[::apave::obj csGet \$cs\] fg - bg ;          lappend args -background \$bg         } ;        return \[eval ::apave::_W_TOPLEVEL$w \$args\]
      "
return $res}
rename ::canvas ::apave::_TK_CANVAS
proc ::canvas {args} {set res [eval ::apave::_TK_CANVAS $args]
set w [lindex $args 0]
if {[string match "*cHull.canvas" $w]} {rename $w ::apave::_W_CANVAS$w
proc ::$w {args} "           set cs \[::apave::obj csCurrent\] ;          lassign \[::apave::obj csGet \$cs\] fg - bg ;          if {\$cs>-2} {             if {\[string first {create text} \$args\]==0 ||             \[string first {itemconfigure} \$args\]==0 &&             \[string first {-fill black} \$args\]>0} {               dict set args -fill \$fg ;              dict set args -font apaveFontDef             }           }  ;          ::apave::_W_CANVAS$w configure -bg \$bg ;          return \[eval ::apave::_W_CANVAS$w \$args\]
        "}
return $res}}
method themeExternal {args} {if {[set cs [my csCurrent]] != -2} {foreach untw $args {my untouchWidgets $untw}
after idle [list [self] csSet $cs . -doit]}}}
#by trimmer
