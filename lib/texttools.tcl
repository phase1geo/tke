######################################################################
# Name:    texttools.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    05/21/2013
# Brief:   Namespace containing procedures to manipulate text in the
#          current text widget.
######################################################################

namespace eval texttools {

  ######################################################################
  # Comments out the currently selected text.
  proc comment {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    # Get the comment syntax
    lassign [syntax::get_comments $txt] icomment lcomments bcomments

    # Insert comment lines/blocks
    foreach {endpos startpos} [lreverse $selected] {
      if {[llength $icomment] == 1} {
        set i 0
        foreach line [split [$txt get $startpos $endpos] \n] {
          if {$i == 0} {
            $txt insert $startpos "[lindex $icomment 0]"
            $txt tag add sel $startpos "$startpos lineend"
          } else {
            $txt insert "$startpos+${i}l linestart" "[lindex $icomment 0]"
          }
          incr i
        }
      } else {
        $txt insert $endpos   "[lindex $icomment 1]"
        $txt insert $startpos "[lindex $icomment 0]"
        if {[lindex [split $startpos .] 0] == [lindex [split $endpos .] 0]} {
          set endpos "$endpos+[expr [string length [lindex $icomment 0]] + [string length [lindex $icomment 1]]]c"
        } else {
          set endpos "$endpos+[string length [lindex $icomment 1]]c"
        }
        $txt tag add sel $startpos $endpos
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Uncomments out the currently selected text in the current text
  # widget.
  proc uncomment {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    # Get the comment syntax
    lassign [syntax::get_comments $txt] icomment lcomments bcomments

    # Get the comment syntax to remove
    if {[llength $icomment] == 1} {
      set comment [join $lcomments |]
    } else {
      set comment [join [eval concat $bcomments] |]
    }

    # Strip out comment syntax
    foreach {endpos startpos} [lreverse $selected] {
      set linestart $startpos
      foreach line [split [$txt get $startpos $endpos] \n] {
        while {[regexp -indices -- ".*($comment)" $line -> com]} {
          set delstart [$txt index "$linestart+[lindex $com 0]c"]
          set delend   [$txt index "$linestart+[expr [lindex $com 1] + 1]c"]
          $txt delete $delstart $delend
          set line [string replace $line {*}$com]
        }
        set linestart [$txt index "$linestart+1l linestart"]
        incr i
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Indents the selected text of the current text widget by one
  # indentation level.
  proc indent {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    foreach {endpos startpos} [lreverse $selected] {
      while {[$txt index "$startpos linestart"] <= [$txt index "$endpos linestart"]} {
        $txt insert "$startpos linestart" "  "
        set startpos [$txt index "$startpos linestart+1l"]
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Unindents the selected text of the current text widget by one
  # indentation level.
  proc unindent {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    foreach {endpos startpos} [lreverse $selected] {
      while {[$txt index "$startpos linestart"] <= [$txt index "$endpos linestart"]} {
        if {[regexp {^  } [$txt get "$startpos linestart" "$startpos lineend"]]} {
          $txt delete "$startpos linestart" "$startpos linestart+2c"
        }
        set startpos [$txt index "$startpos linestart+1l"]
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Aligns the current cursors.
  proc align {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Align multicursors
    multicursor::align $txt

  }

  ######################################################################
  # Inserts an enumeration when in multicursor mode.
  proc insert_enumeration {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Perform the insertion
    gui::insert_numbers $txt

  }

}

