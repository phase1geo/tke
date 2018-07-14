# This TKE plugin allows the user:
# 1) Delete the current line or the lines of selection.
# 2) Duplicate the current line or the selection.
# 3) Indent/unindent the current line or the lines of selection.
# 4) Comment/uncomment the TCL coded line or the lines of selection.

# Plugin namespace
namespace eval edit_utils {

  variable commmark  "#? "
  variable bracemark "${commmark}TODO "

  #====== Get current text command

  proc get_txt {} {

    set file_index [api::file::current_index]
    if {$file_index == -1} {
        return ""
    }
    return [api::file::get_info $file_index txt]

  }

  #====== Get line's positions

  proc get_line {txt ind} {

    set linestart [$txt index "$ind linestart"]
    set lineend   [expr {$linestart + 1.0}]
    return [list $linestart $lineend]

  }

  #====== Get current line's positions

  proc get_current_line {txt} {

    return [get_line $txt insert]

  }

  #====== Get line's contents

  proc get_line_contents {txt ind} {

    return [$txt get \
      [$txt index "$ind linestart"] [$txt index "$ind lineend"]]

  }

  #====== Get text to process (current line or selection)

  proc text_to_process {} {

    set txt [get_txt]
    if {$txt == ""} {return [list]}
    set start [$txt index "insert linestart"]
    set end [$txt index "insert lineend"]
    set err [catch {$txt tag ranges sel} sel]
    if {$err || [llength $sel]==0} {
      set sel [list $start $end]  ;# current line only
    }
    return $sel

  }

  #====== Delete line

  proc delete_line {txt ind} {

    lassign [get_line $txt $ind] linestart lineend
    $txt delete $linestart $lineend

  }

  #====== Delete current line/ lines of selection

  proc do_delete_lines {} {

    set txt [get_txt]
    if {$txt == ""} return
    foreach {i1 i2} [text_to_process] {  # process each selection
      for {set i [expr int($i2)]} {$i >= [expr int($i1)]} {incr i -1} {
        delete_line $txt $i.0
      }
    }

  }

  #====== Duplicate current line/ selection

  proc do_double_line {} {

    set txt [get_txt]
    if {$txt == ""} return
    set err [catch {$txt tag ranges sel} sel]
    if {!$err && [llength $sel]==2} {
      lassign $sel pos pos2
      set pos3 "insert"  ;# single selection
    } else {
      lassign [get_current_line $txt] pos pos2  ;# current line
      set pos3 $pos2
    }
    set duptext [$txt get $pos $pos2]
    $txt insert $pos3 $duptext

  }

  #% doctest

  #====== Calculate new position after indent/unindent

  # Problem: we can't use [$txt index "$ind - $cn chars"] because
  # after unindent $ind may point to non-existing trailing position,
  # so we must calculate new position manually.
  # Input parameters should be in numeric form, e.g. ind=123.25 cn=4
  # otherwise calc_index returns input parameters as "$ind $cn"

  #% calc_index 123.25 4
  #> 123.29
  #% calc_index 123.4 25
  #> 123.29
  #% calc_index 123.25 -4
  #> 123.21
  #% calc_index 123.2 -4
  #> 123.0
  #% calc_index insert "-4 chars"
  #> insert -4 chars

  proc calc_index {ind cn} {

    if {[catch {
      set i [string first . $ind]
      set dec [string range $ind [incr i] end]
      set dec [expr {max(0,$dec+($cn))}]
      set res [expr int($ind)].$dec
    }]} {
      set res "$ind $cn"
    }
    return $res

  }
  #> doctest

  #====== Get new selection start for line (after indent/unindent)

  proc new_selstart {txt ind oldlen} {

    set newlen [string length [get_line_contents $txt $ind]]
    set inc [expr $newlen - $oldlen]
    set newstart [calc_index $ind $inc]
    set oldstart [$txt index "$ind linestart"]
    if {[$txt index "$newstart linestart"] != $oldstart} {
      set newstart $oldstart  ;# unindent sticked into line start
    }
    return $newstart

  }

  #====== Indent line/ selected text

  proc do_indent_lines {inc} {

    set txt [get_txt]
    if {$txt == ""} return
    set start [$txt index "insert linestart"]
    set end [$txt index "insert lineend"]
    set err [catch {$txt tag ranges sel} sel]
    if {$err} {
      set sel [list]
    }
    # selections' info: positions and lengths of 1st and last lines
    set selinfo [list]
    foreach {i1 i2} $sel {
      set s1 [get_line_contents $txt $i1]
      set s2 [get_line_contents $txt $i2]
      lappend selinfo $i1 $i2 [string length $s1] [string length $s2]
    }
    if {$inc} {
      api::edit::indent $txt $start $end
    } else {
      api::edit::unindent $txt $start $end
    }
    # restore selections in their new locations
    foreach {i1 i2 o1 o2} $selinfo {
      set p1 [new_selstart $txt $i1 $o1]
      set p2 [new_selstart $txt $i2 $o2]
      $txt tag add sel $p1 $p2
    }

  }

  #====== Get counts of "{" and "}" in string

  proc get_braces_count {st} {

    set spec [set left_c [set right_c 0]]
    for {set i 0} {$i < [string length $st]} {incr i} {
      set c [string index $st $i]
      switch $c {
        "\\" {
             set $spec [expr {!$spec}]
             }
        "\{" {
             if {!$spec} {incr left_c}
             set spec 0
             }
        "\}" {
             if {!$spec} {incr right_c}
             set spec 0
             }
        default {set spec 0}
      }
    }
    return [list $left_c $right_c]

  }

  #====== Check if string is commented

  proc is_commented {st} {

    variable commmark
    return [expr [string first $commmark $st] == 0]

  }

  #====== Move cursor to next line

  proc move_to_next_line {txt} {

    api::edit::move_cursor $txt \
      left -startpos "insert + 1 lines linestart" -num 0

  }

  #====== Move cursor to next commented line if possible

  proc move_to_next_comm1 {txt line} {

    set i1 [$txt index "$line linestart"]
    set st [get_line_contents $txt $i1]
    if {[is_commented $st]} {
      api::edit::move_cursor $txt left -startpos $i1 -num 0
      return 1
    }
    return 0

  }

  proc move_to_next_comment {txt} {

    if {![move_to_next_comm1 $txt [$txt index "insert + 1 lines"]]} {
      return [move_to_next_comm1 $txt [$txt index "insert - 1 lines"]]
    }
    return 1

  }

  #====== Comment Tcl code (with checking for {} parity)

  proc do_comment_tcl {} {

    variable commmark
    variable bracemark
    set txt [get_txt]
    if {$txt == ""} return
    set linelist [text_to_process]   ;# process each selection
    foreach {i1 i2} $linelist {
      set lefts [set rights 0]
      for {set i [expr int($i2)]} {$i >= [expr int($i1)]} {incr i -1} {
        set st [get_line_contents $txt $i.0]
        if {![is_commented $st]} {  # an old comment => nothing to do
          lassign [get_braces_count $st] l r
          incr lefts $l
          incr rights $r
          $txt insert $i.0 $commmark
        }
      }
      if {$lefts > $rights} {
          $txt insert [$txt index "$i2 lineend"] \
            \n${bracemark}[string repeat "\}" [expr {$lefts - $rights}]]
      } elseif {$rights > $lefts} {
          $txt insert [$txt index "$i1 linestart"] \
            ${bracemark}[string repeat "\{" [expr {$rights - $lefts}]]\n
      }
    }
    move_to_next_line $txt

  }

  #====== Uncomment Tcl code (commented by previous procedure)

  proc do_uncomment_tcl {} {

    variable commmark
    variable bracemark
    set txt [get_txt]
    if {$txt == ""} return
    set chars "[string length $commmark] chars"
    set linelist [text_to_process]    ;# process each selection
    foreach {i1 i2} $linelist {
      set lefts [set rights 0]
      for {set i [expr int($i2)]} {$i >= [expr int($i1)]} {incr i -1} {
        set st [get_line_contents $txt $i.0]
        if {[string first $bracemark $st] == 0} {
          $txt delete $i.0 [expr $i+1].0
        } elseif {[string first $commmark $st] == 0} {
          $txt delete $i.0 "$i.0 + $chars"
        }
      }
    }
    # move to next comment if possible
    lassign $linelist i1
    if {[$txt index "insert linestart"] == [$txt index "$i1 linestart"]} {
      if {![move_to_next_comment $txt]} {
        move_to_next_line $txt
      }
    }

  }

  #====== Procedures to register the plugin

  proc handle_state {} {

    if {"[get_txt]" == ""} {return 0}
    return 1

  }

}

#====== Register plugin action

api::register edit_utils {
  {menu command {Edit Utils/Delete Line} \
      edit_utils::do_delete_lines  edit_utils::handle_state}
  {menu command {Edit Utils/Duplicate Selection} \
      edit_utils::do_double_line  edit_utils::handle_state}
  {menu separator {Edit Utils}}
  {menu command {Edit Utils/Indent Selection} \
      {edit_utils::do_indent_lines 1}  edit_utils::handle_state}
  {menu command {Edit Utils/Unindent Selection} \
      {edit_utils::do_indent_lines 0}  edit_utils::handle_state}
  {menu separator {Edit Utils}}
  {menu command {Edit Utils/Comment TCL} \
      edit_utils::do_comment_tcl  edit_utils::handle_state}
  {menu command {Edit Utils/Uncomment TCL} \
      edit_utils::do_uncomment_tcl  edit_utils::handle_state}

}
