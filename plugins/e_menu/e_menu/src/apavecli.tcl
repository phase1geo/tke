#! /usr/bin/env tclsh
# tclsh ~/UTILS/pave/pavecli.tcl "" "TEST OF pavecli" \
    {    ent1  {"   Find: "} {"$::EN1 2 3"}    ent2  {"Replace: "} \
    {"$::EN2 $::EN4"}  labo {{} {-anchor w} {-t "\\nOptions:" -font \
    {-weight bold}}}  {}    radA  {{Match:   }} {{RE  } Exact "Glob" \
    {RE  }}    seh   {{} {} {}} {}    chb1  {{Match whole word only}} \
    {1}    chb2  {{Match case           }} {1}    seh2  {{} {} {}} {}  \
    v_    {{} {} {}} {}    cbx1  {{Where:   }} {{"in file"} {in file}  \
    {in session} {in directory}}    } -head "Enter data:" -weight bold \
    == EN1 EN2 V1 C1 C2 W1 > tmp.sh ; \
 if [ $? -eq 1 ]; then source tmp.sh; fi ; \
 rm tmp.sh ; \
 echo "EN1=$EN1, EN2=$EN2, V1=$V1, C1=$C1, C2=$C2, W1=$W1"
if {[catch {package require apave}]} {set ::apavedir [file dirname [info script]]
lappend auto_path $::apavedir
if {[catch {package require apave}]} {lset auto_path end $::apavedir/pave
package require apave}}
namespace eval apavecli {}
proc ::apavecli::input {args} {::apave::APaveInput create dialog
set cmd [subst -nocommands -novariables [string range $args 1 end-1]]
set dp [string last " ==" $cmd]
if {$dp<0} {set dp 999999}
set data [string range $cmd $dp+3 end]
set data [split [string trim $data]]
set cmd "dialog input [string range $cmd 0 $dp-1]"
set res [eval $cmd]
set r [lindex $res 0]
if {$r && $data ne ""} {set rind 0
puts "#!/bin/bash"
foreach res [lrange $res 1 end] {puts "export [lindex $data $rind]='$res'"
incr rind}}
return $r}
proc ::apavecli::run {} {apave::initWM
set res [::apavecli::input $::argv]
::apave::APaveInput destroy
exit $res}
::apavecli::run
#by trimmer
