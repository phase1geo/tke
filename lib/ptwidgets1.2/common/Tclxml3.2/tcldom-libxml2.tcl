# impl.tcl --
#
#	Support script for libxml2 implementation.
#
# Std disclaimer
#
# $Id: //sn4/tools/lib/tkdv2/Tclxml3.2/tcldom-libxml2.tcl#1 $

namespace eval ::dom {
    variable strictDOM 1
}

proc dom::libxml2::parse {xml args} {

    array set options {
	-keep normal
	-retainpath /*
    }
    array set options $args

    if {[catch {eval ::xml::parser -parser libxml2 [array get options]} parser]} {
	return -code error "unable to create XML parser due to \"$parser\""
    }

    if {[catch {$parser parse $xml} msg]} {
	return -code error $msg
    }

    set doc [$parser get document]
    set dom [dom::libxml2::adoptdocument $doc]
    $parser free

    return $dom
}
proc dom::parse {xml args} {
    return [eval ::dom::libxml2::parse [list $xml] $args]
}
