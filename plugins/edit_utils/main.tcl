# This TKE plugin allows the user:
# 1) Delete the current line or the lines of selection.
# 2) Duplicate the current line or the selection.
# 3) Indent/unindent the current line or the lines of selection.
# 4) Normalize the indention of Tcl script or selection.
# 5) Comment/uncomment the TCL coded line or the lines of selection.

# Plugin namespace
namespace eval edit_utils {

  variable commmark  "#? "
  variable bracemark "${commmark}TODO "

  ###################################################################
  # Get current text command

  proc get_txt {} {

    set file_index [api::file::current_index]
    if {$file_index == -1} {
      return ""
    }
    return [api::file::get_info $file_index txt]

  }

  ###################################################################
  # Display the text widget

  proc update_txt {txt} {

    api::reset_text_focus $txt
    return

  }

  ###################################################################
  # Get line's positions

  proc get_line {txt ind} {

    set linestart [$txt index "$ind linestart"]
    set lineend   [expr {$linestart + 1.0}]
    return [list $linestart $lineend]

  }

  ###################################################################
  # Get current line's positions

  proc get_current_line {txt} {

    return [get_line $txt insert]

  }

  ###################################################################
  # Get line's contents

  proc get_line_contents {txt ind} {

    return [$txt get \
      [$txt index "$ind linestart"] [$txt index "$ind lineend"]]

  }

  ###################################################################
  # Get text to process (current line or selection)

  proc text_todo {{i_start "insert linestart"} {i_end "insert lineend"}} {

    set txt [get_txt]
    if {$txt == ""} {return [list]}
    set start [$txt index $i_start]
    set end [$txt index $i_end]
    set err [catch {$txt tag ranges sel} sel]
    if {$err || [llength $sel]==0} {
      set sel [list $start $end]  ;# current line only
    }
    return $sel

  }

  ###################################################################
  # Delete line

  proc delete_line {txt ind} {

    lassign [get_line $txt $ind] linestart lineend
    $txt delete $linestart $lineend
    return

  }

  ###################################################################
  # Delete current line/ lines of selection

  proc do_delete_lines {} {

    set txt [get_txt]
    if {$txt == ""} return
    foreach {i1 i2} [text_todo] {  # process each selection
      for {set i [expr int($i2)]} {$i >= [expr int($i1)]} {incr i -1} {
        delete_line $txt $i.0
      }
    }
    update_txt $txt
    return

  }

  ###################################################################
  # Duplicate current line/ selection

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
    update_txt $txt
    return

  }

  #% doctest

  ###################################################################
  # Calculate new position after indent/unindent

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
      }]
    } { set res "$ind $cn" }
    return $res

  }
  #> doctest

  ###################################################################
  # Get new selection start for line (after indent/unindent)

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

  ###################################################################
  # borrowed from http://wiki.tcl.tk/15731

  proc count {string char} {
    set count 0
    while {[set idx [string first $char $string]]>=0} {
      set backslashes 0
      set nidx $idx
      while {[string equal [string index $string [incr nidx -1]] \\]} {
        incr backslashes
      }
      if {$backslashes % 2 == 0} {
        incr count
      }
      set string [string range $string [incr idx] end]
    }
    return $count
  }

  ###################################################################
  # Reformat the code

  proc reformat {tclcode {pad 2}} {

    set lines [split $tclcode \n]
    set out ""
    set nquot 0   ;# count of quotes
    set ncont 0   ;# count of continued strings
    set line [lindex $lines 0]
    set indent [expr {([string length $line]-[string length [string trimleft $line \ \t]])/$pad}]
    set padst [string repeat " " $pad]
    foreach orig $lines {
      incr lineindex
      if {$lineindex>1} {append out \n}
      set newline [string trim $orig]
      if {$newline==""} continue
      set is_quoted $nquot
      set is_continued $ncont
      if {[string index $orig end] eq "\\"} {
        incr ncont
      } else {
        set ncont 0
      }
      if { [string index $newline 0]=="#" } {
        set line $orig   ;# don't touch comments
      } else {
        set npad [expr {$indent * $pad}]
        set line [string repeat $padst $indent]$newline
        set ns [set nl [set nr [set body 0]]]
        for {set i 0; set n [string length $newline]} {$i<$n} {incr i} {
          set ch [string index $newline $i]
          if {$ch=="\\"} {
            set ns [expr {[incr ns] % 2}]
          } elseif {!$ns} {
            if {$ch=="\""} {
              set nquot [expr {[incr nquot] % 2}]
            } elseif {!$nquot} {
              switch $ch {
                "\{" {
                  if {[string range $newline $i $i+2]=="\{\"\}"} {
                    # quote in braces - correct (though tricky)
                    incr i 2
                  } else {
                    incr nl
                    set body -1
                  }
                }
                "\}" {
                  incr nr
                  set body 0
                }
              }
            }
          } else {
            set ns 0
          }
        }
        set nbbraces [expr {$nl - $nr}]
        incr totalbraces $nbbraces
        if {$totalbraces<0} {
          api::show_error "\nLine $lineindex: unbalanced braces!\n"
          return ""
        }
        incr indent $nbbraces
        if {$nbbraces==0} { set nbbraces $body }
        if {$is_quoted || $is_continued} {
          set line $orig     ;# don't touch quoted and continued strings
        } else {
          set np [expr {- $nbbraces * $pad}]
          if {$np>$npad} { ;# for safety too
            set np $npad
          }
          set line [string range $line $np end]
        }
      }
      append out $line
    }
    return $out
  }

  ###################################################################
  # Get indent shift width

  proc get_shiftwidth {txt} {

    set txt [get_txt]
    if {$txt == ""} {
      return 0
    }
    foreach {i1 i2} [text_todo 1.0 end] {  ;# process all
      for {set i [expr int($i1)]} {$i <= [expr int($i2)]} {incr i} {
        set line [get_line_contents $txt $i.0]
        set linetrimmed [string trimleft $line]
        if {[string index $linetrimmed 0] != "#" &&  $linetrimmed != ""} {
          set ind [expr {[string length $line] - [string length $linetrimmed]}]
          if {$ind > 0} {
            return $ind   ;# first indented line would set the indentation
          }
        }
      }
    }
    return 2
  }

  ###################################################################
  # Normalize indention

  proc normalize_indention {txt sel} {

    set indent [get_shiftwidth $txt]
    if {$indent} {
      if {$sel == ""} {
        set i1 1.0
        set i2 "end -1 chars"
      } else {
        lassign [list {*}$sel] i1 i2
        set i1 [expr int($i1)].0
        set i2 [expr int($i2)].end
      }
      set contents [$txt get $i1 $i2]
      set contents [reformat $contents $indent]
      if {$contents != ""} {
        if {$sel == "" && [tk_messageBox -default yes -type yesno \
        -message "You are going to normalize\nthe indention of the whole\
        \n\n[file tail [api::file::get_info [api::file::current_index] fname]]\
        \n\nwith indent = $indent" -title "Total indentation"] ne "yes"} {
          return
        }
        $txt replace $i1 $i2 $contents
      }
    }
    return
  }

  ###################################################################
  # Indent line/ selected text

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
    switch $inc {
      0 {api::edit::unindent $txt $start $end}
      1 {api::edit::indent $txt $start $end}
      2 {normalize_indention $txt $sel}
    }
    # restore selections in their new locations
    foreach {i1 i2 o1 o2} $selinfo {
      set p1 [new_selstart $txt $i1 $o1]
      set p2 [new_selstart $txt $i2 $o2]
      $txt tag add sel $p1 $p2
    }
    update_txt $txt
    return

  }

  ###################################################################
  # Check if string is commented

  proc is_commented {st} {

    variable commmark
    return [expr [string first $commmark $st] == 0]

  }

  ###################################################################
  # Move cursor to next line

  proc move_to_next_line {txt} {

    api::edit::move_cursor $txt \
      left -startpos "insert + 1 lines linestart" -num 0
    return

  }

  ###################################################################
  # Move cursor to next commented line if possible

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

  ###################################################################
  # Comment Tcl code (with checking for {} parity)

  proc do_comment_tcl {} {

    variable commmark
    variable bracemark
    set txt [get_txt]
    if {$txt == ""} return
    set linelist [text_todo]   ;# process each selection
    foreach {i1 i2} $linelist {
      set lefts [set rights 0]
      set beg [expr int($i1)]
      set end [expr int($i2)]
      for {set i $end} {$i >= $beg} {incr i -1} {
        set st [get_line_contents $txt $i.0]
        if {![is_commented $st] && \
        ($st!="" || ($i != $end && $i != $beg))} {
          set l [count $st "\{"]
          set r [count $st "\}"]
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
    update_txt $txt
    return

  }

  ###################################################################
  # Uncomment Tcl code (commented by previous procedure)

  proc do_uncomment_tcl {} {

    variable commmark
    variable bracemark
    set txt [get_txt]
    if {$txt == ""} return
    set chars "[string length $commmark] chars"
    set linelist [text_todo]    ;# process each selection
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
    update_txt $txt
    return

  }

  ###################################################################
  # Run selection as TCL to get its result.
  # The result is inserted at the cursor position.

  proc do_run_tcl {} {

    set txt [get_txt]
    if {$txt == ""} return
    set err [catch {$txt tag ranges sel} sel]
    if {!$err && [llength $sel]==2} {
      lassign $sel pos pos2  ;# single selection
    } else {
      lassign [get_current_line $txt] pos pos2  ;# current line
    }
    set comm [$txt get $pos $pos2]
    if {[catch {eval $comm} e]} {
      tk_messageBox -parent . -title ERROR -type ok -default ok \
        -message "While executing:\n\n$comm\n\ngot the error:\n\n$e"
    } elseif {$e!=""} {
      $txt insert insert $e
    } else {
      tk_messageBox -parent . -title INFO -type ok -default ok \
        -message "Select some Tcl command(s)\nand run this menu item.
          \nIf no selection available, a current line would be the command to run.
          \nThe result shows at the cursor.
          \n------------ \
          \nJust now, you've gotten an EMPTY result."
    }
    if {0} {
      # testing on the commands below:
      calc_index 123.25 4  ;#===> 123.29
      set a 123123
      set b [expr $a/7.]   ;#===> 17589.0
      set c ""             ;#===> EMPTY
    }
  }

  ###################################################################
  # Procedures to register the plugin

  proc handle_state {} {

    if {"[get_txt]" == ""} {return 0}
    return 1

  }

}

#####################################################################
# Register plugin action

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
  {menu command {Edit Utils/Normalize Indentation} \
    {edit_utils::do_indent_lines 2}  edit_utils::handle_state}
  {menu separator {Edit Utils}}
  {menu command {Edit Utils/Comment TCL} \
    edit_utils::do_comment_tcl  edit_utils::handle_state}
  {menu command {Edit Utils/Uncomment TCL} \
    edit_utils::do_uncomment_tcl  edit_utils::handle_state}
  {menu command {Edit Utils/Run selection as TCL for its result} \
    edit_utils::do_run_tcl  edit_utils::handle_state}
}

