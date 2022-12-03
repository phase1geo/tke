# _______________________________________________________________________ #
package provide baltip 1.0.6
package require Tk
namespace eval ::baltip {namespace export configure cget tip update hide repaint
namespace ensemble create
namespace eval my {variable ttdata; array set ttdata [list]
set ttdata(on) yes
set ttdata(per10) 1600
set ttdata(fade) 300
set ttdata(pause) 600
set ttdata(fg) black
set ttdata(bg) #FBFB95
set ttdata(bd) 1
set ttdata(padx) 4
set ttdata(pady) 3
set ttdata(padding) 0
set ttdata(alpha) 1.0
set ttdata(bell) no
set ttdata(font) [font actual TkTooltipFont]
set ttdata(under) -16}}
proc ::baltip::configure {args} {variable my::ttdata
set force no
set index -1
set geometry [set tag ""]
set global [expr {[dict exists $args -global] && [dict get $args -global]}]
foreach {n v} $args {set n1 [string range $n 1 end]
switch -glob -- $n {-per10 - -fade - -pause - -fg - -bg - -bd - -alpha - -text - -on - -padx - -pady - -padding - -bell - -under - -font {set my::ttdata($n1) $v}
-force - -geometry - -index - -tag - -global {set $n1 $v}
default {return -code error "invalid option \"$n\""}}
if {$global && ($n ne "-global" || [llength $args]==2)} {foreach k [array names my::ttdata -glob on,*] {set w [lindex [split $k ,] 1]
set my::ttdata($n1,$w) $v}}}
return [list $force $geometry $index $tag]}
proc ::baltip::cget {args} {variable my::ttdata
if {![llength $args]} {lappend args -on -per10 -fade -pause -fg -bg -bd -padx -pady -padding -font -alpha -text -index -tag -bell -under}
set res [list]
foreach n $args {set n [string range $n 1 end]
if {[info exists my::ttdata($n)]} {lappend res -$n $my::ttdata($n)}}
return $res}
proc ::baltip::tip {w text args} {variable my::ttdata
array unset my::ttdata winGEO*
if {[winfo exists $w] || $w eq ""} {set arrsaved [array get my::ttdata]
set optvals [::baltip::my::CGet {*}$args]
lassign $optvals forced geo index ttag
set optvals [lrange $optvals 4 end]
set my::ttdata(optvals,$w) [dict set optvals -text $text]
set my::ttdata(on,$w) [expr {[string length $text]}]
set my::ttdata(global,$w) no
if {$text ne ""} {if {$forced || $geo ne ""} {::baltip::my::Show $w $text yes $geo $optvals}
if {$geo ne ""} {array set my::ttdata $arrsaved
} else {set tags [bindtags $w]
if {[lsearch -exact $tags "Tooltip$w"] == -1} {bindtags $w [linsert $tags end "Tooltip$w"]}
bind Tooltip$w <Any-Leave>    [list ::baltip::hide $w]
bind Tooltip$w <Any-KeyPress> [list ::baltip::hide $w]
bind Tooltip$w <Any-Button>   [list ::baltip::hide $w]
if {$index>-1} {set my::ttdata($w,$index) $text
set my::ttdata(LASTMITEM) ""
bind $w <<MenuSelect>> [list + ::baltip::my::MenuTip $w %W $optvals]
} elseif {$ttag ne ""} {set my::ttdata($w,$ttag) "$text"
$w tag bind $ttag <Enter> [list + ::baltip::my::TagTip $w $ttag $optvals]
foreach event {Leave KeyPress Button} {$w tag bind $ttag <$event> [list + ::baltip::my::TagTip $w]}
} else {bind Tooltip$w <Enter> [list ::baltip::my::Show %W $text no $geo $optvals]}}}}}
proc ::baltip::update {w text args} {variable my::ttdata
set my::ttdata(text,$w) $text
foreach {k v} $args {set my::ttdata([string range $k 1 end],$w) $v}}
proc ::baltip::hide {{w ""}} {return [expr {![catch {destroy $w.w__BALTIP}]}]}
proc ::baltip::repaint {w args} {variable my::ttdata
if {[winfo exists $w] && [info exists my::ttdata(optvals,$w)] && [dict exists $my::ttdata(optvals,$w) -text]} {set optvals $my::ttdata(optvals,$w)
lappend optvals {*}$args
catch {after cancel $my::ttdata(after)}
set my::ttdata(after) [after idle [list ::baltip::my::Show $w [dict get $my::ttdata(optvals,$w) -text] yes {} $optvals]]}}
proc ::baltip::my::CGet {args} {variable ttdata
set saved [array get ttdata]
set res [::baltip::configure {*}$args]
lappend res {*}[::baltip::cget]
array set ttdata $saved
return $res}
proc ::baltip::my::ShowWindow {win} {variable ttdata
if {![winfo exists $win] || ![info exists ttdata(winGEO,$win)]} return
set geo $ttdata(winGEO,$win)
set under $ttdata(winUNDER,$win)
set w [winfo parent $win]
set px [winfo pointerx .]
set py [winfo pointery .]
set width [winfo reqwidth $win.label]
set height [winfo reqheight $win.label]
set ady 0
if {[catch {set wheight [winfo height $w]}]} {set wheight 0
} else {for {set i 0} {$i<$wheight} {incr i} {incr py
incr ady
if {![string match $w [winfo containing $px $py]]} break}}
if {$geo eq {}} {set x [expr {max(1,$px - round($width / 2.0))}]
set y [expr {$under>=0 ? ($py + $under) : ($py - $under - $ady)}]
} else {lassign [split $geo +] -> x y
set x [expr [string map "W $width" $x]]
set y [expr [string map "H $height" $y]]}
set scrw [winfo screenwidth .]
set scrh [winfo screenheight .]
if {($x + $width) > $scrw}  {set x [expr {$scrw - $width - 1}]}
if {($y + $height) > $scrh} {set y [expr {$py - $height - 16}]}
wm geometry $win [join  "$width x $height + $x + $y" {}]
catch {wm deiconify $win ; raise $win}}
proc ::baltip::my::Show {w text force geo optvals} {variable ttdata
if {$w ne "" && ![winfo exists $w]} return
set win $w.w__BALTIP
catch {::apave::obj untouchWidgets $win.label}
set px [winfo pointerx .]
set py [winfo pointery .]
if {$geo ne ""} {array set data $optvals
} elseif {$ttdata(global,$w)} {array set data [::baltip::cget]
} else {array set data $optvals
foreach k [array names ttdata -glob *,$w] {set n1 [lindex [split $k ,] 0]
if {$n1 eq "text"} {set text $ttdata($k)
} else {set data(-$n1) $ttdata($k)}}}
if {!$force && $geo eq "" && [winfo class $w] ne "Menu" && ([winfo exists $win] || ![info exists ttdata(on,$w)] || !$ttdata(on,$w) || ![string match $w [winfo containing $px $py]])} {return}
::baltip::hide $w
set icount [string length [string trim $text]]
if {!$icount || (!$ttdata(on) && !$data(-on))} return
lappend ttdata(REGISTERED) $w
foreach wold [lrange $ttdata(REGISTERED) 0 end-1] {::baltip::hide $wold}
if {$data(-fg) eq "" || $data(-bg) eq ""} {set data(-fg) black
set data(-bg) #FBFB95}
toplevel $win -bg $data(-bg) -class Tooltip$w
catch {wm withdraw $win}
wm overrideredirect $win 1
wm attributes $win -topmost 1
pack [label $win.label -text $text -justify left -relief solid -bd $data(-bd) -bg $data(-bg) -fg $data(-fg) -font $data(-font) -padx $data(-padx) -pady $data(-pady)] -padx $data(-padding) -pady $data(-padding)
bindtags $win "Tooltip$win"
bind $win <Any-Enter>  [list ::baltip::hide $w]
bind Tooltip$win <Any-Enter>  [list ::baltip::hide $w]
bind Tooltip$win <Any-Button> [list ::baltip::hide $w]
set aint 20
set fint [expr {int($data(-fade)/$aint)}]
set icount [expr {int($data(-per10)/$aint*$icount/10.0)}]
set icount [expr {max(1000/$aint+1,$icount)}]
set ttdata(winGEO,$win) $geo
set ttdata(winUNDER,$win) $data(-under)
if {$icount} {if {$geo eq ""} {catch {wm attributes $win -alpha $data(-alpha)}
} else {Fade $win $aint [expr {round(1.0*$data(-pause)/$aint)}] 0 Un $data(-alpha) 1 $geo}
if {$force} {Fade $win $aint $fint $icount {} $data(-alpha) 1 $geo
} else {catch {after cancel $ttdata(after)}
set ttdata(after) [after $data(-pause) [list ::baltip::my::Fade $win $aint $fint $icount {} $data(-alpha) 1 $geo]]}
} else {catch {after cancel $ttdata(after)}
set ttdata(after) [after $data(-pause) [list ::baltip::my::ShowWindow $win]]}
if {$data(-bell)} [list after [expr {$data(-pause)/4}] bell]
array unset data}
proc ::baltip::my::Fade {w aint fint icount Un alpha show geo {geos ""}} {variable ttdata
update
if {[winfo exists $w]} {catch {after cancel $ttdata(after)}
set ttdata(after) [after idle [list after $aint [list ::baltip::my::${Un}FadeNext $w $aint $fint $icount $alpha $show $geo $geos]]]}}
proc ::baltip::my::FadeNext {w aint fint icount alpha show geo {geos ""}} {incr icount -1
if {$show} {ShowWindow $w}
set show 0
if {![winfo exists $w]} return
lassign [split [wm geometry $w] +] -> X Y
if {$geos ne "" && $geos ne "+$X+$Y"} return
if {$fint<=0} {set fint 10}
if {[catch {set al [expr {min($alpha,($fint+$icount*1.5)/$fint)}]}]} {set al 0}
if {$icount<0} {if {$al>0} {if {[catch {wm attributes $w -alpha $al}]} {set al 0}}
if {$al<=0 || ![winfo exists $w]} {catch {destroy $w}
return}
} elseif {$al>0 && $geo eq ""} {catch {wm attributes $w -alpha $al}}
Fade $w $aint $fint $icount {} $alpha $show $geo +$X+$Y}
proc ::baltip::my::UnFadeNext {w aint fint icount alpha show geo {geos ""}} {incr icount
set al [expr {min($alpha,$icount*1.5/$fint)}]
if {$al<$alpha && [catch {wm attributes $w -alpha $al}]} {set al 1}
if {$show} {ShowWindow $w
set show 0}
if {[winfo exists $w] && $al<$alpha} {Fade $w $aint $fint $icount Un $alpha 0 $geo}}
proc ::baltip::my::MenuTip {w wt optvals} {variable ttdata
::baltip::hide $w
set index [$wt index active]
set mit "$w/$index"
if {$index eq "none"} return
if {[info exists ttdata($w,$index)] && ([::baltip::hide $w] || ![info exists ttdata(LASTMITEM)] || $ttdata(LASTMITEM) ne $mit)} {set text $ttdata($w,$index)
::baltip::my::Show $w $text no {} $optvals}
set ttdata(LASTMITEM) $mit}
proc ::baltip::my::TagTip {w {tag ""} {optvals ""}} {variable ttdata
::baltip::hide $w
if {$tag eq ""} return
::baltip::my::Show $w $ttdata($w,$tag) no {} $optvals}
#by trimmer
