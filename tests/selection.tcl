namespace eval selection {

  ######################################################################
  # Common diagnostic initialization procedure.  Returns the pathname
  # to the added text widget.
  proc initialize {} {

    variable current_tab

    # Add a new file
    set current_tab [gui::add_new_file end]

    # Get the text widget
    set txt [gui::get_info $current_tab tab txt]

    # Set the current syntax to Tcl
    syntax::set_language $txt Tcl

    return $txt.t

  }

  ######################################################################
  # Common cleanup procedure.  If a fail message is provided, return an
  # error with the given error message.
  proc cleanup {{fail_msg ""}} {

    variable current_tab

    # Close the current tab
    gui::close_tab $current_tab -check 0

    # Output the fail message and cause a failure
    if {$fail_msg ne ""} {
      return -code error $fail_msg
    }

  }

  ######################################################################
  # Emulates a Vim keystroke.
  proc enter {txtt keysyms} {

    foreach keysym $keysyms {
      if {$keysym eq "Escape"} {
        vim::handle_escape $txtt
      } else {
        set char [utils::sym2char $keysym]
        if {![vim::handle_any $txtt [utils::sym2code $keysym] $char $keysym]} {
          $txtt insert insert $char
        }
      }
    }

  }

  proc do_test {txtt id cmdlist value sel {mode "command"}} {

    set cursor [$txtt index insert]

    enter $txtt $cmdlist

    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id text mismatched ([$txtt get 1.0 end-1c])"
    }
    if {[$txtt tag ranges sel] ne $sel} {
      cleanup "$id selection incorrect $cursor ([$txtt tag ranges sel])"
    }
    if {$vim::mode($txtt) ne $mode} {
      cleanup "$id mode incorrect ($vim::mode($txtt))"
    }
    if {$vim::operator($txtt) ne ""} {
      cleanup "$id operator incorrect ($vim::operator($txtt))"
    }
    if {$vim::motion($txtt) ne ""} {
      cleanup "$id motion incorrect ($vim::motion($txtt))"
    }

    if {($sel eq "") && ($mode eq "command") && ($cmdlist ne {y})} {
      enter $txtt u
    }

  }

  proc do_object_test {txtt id cmdlist value sel {mode "visual:char"}} {

    set cursor [$txtt index insert]

    do_test $txtt $id $cmdlist $value $sel $mode

    if {($mode eq "visual:char") && [$txtt index insert] ne [$txtt index "[lindex $sel 1]-1c"]} {
      cleanup "$id insertion cursor ([$txtt index insert])"
    }

    # Reset the insertion cursor
    $txtt mark set insert $cursor

  }

  # Baseline selection test
  proc run_test1 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 {l}     "\nThis is a line" {2.0 2.6} visual:char

    # Cleanup
    cleanup

  }

  # Verify an x deletion
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify using visual mode to select
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 x "\nis a line" {}

    # Verify using mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 x "\nis a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify an X deletion
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 X "\n " {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 X "\n " {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a d deletion
  proc run_test4 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 d "\nis a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 d "\nis a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a D deletion
  proc run_test5 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 D "\n " {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 D "\n " {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a Delete deletion
  proc run_test6 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 Delete "\nis a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 Delete "\nis a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a c deletion
  proc run_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 c "\nis a line" {} edit
    do_test $txtt 2 Escape "\nis a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 3 c "\nis a line" {} edit
    do_test $txtt 4 Escape "\nis a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a C deletion
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 14 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 15 C "\n" {} edit
    do_test $txtt 16 Escape "\n " {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 15 C "\n" {} edit
    do_test $txtt 16 Escape "\n " {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a y yank
  proc run_test9 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    clipboard clear
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 y "\nThis is a line" {}

    if {[clipboard get] ne "This "} {
      cleanup "1 yank clipboard was not correct ([clipboard get])"
    }

    # Verify mouse selection
    clipboard clear
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 y "\nThis is a line" {}

    if {[clipboard get] ne "This "} {
      cleanup "2 yank clipboard was not correct ([clipboard get])"
    }

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a ~ transform
  proc run_test10 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 asciitilde "\ntHIS is a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 1 asciitilde "\ntHIS is a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a g~ transform
  proc run_test11 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 {g asciitilde} "\ntHIS is a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 {g asciitilde} "\ntHIS is a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a gu transform
  proc run_test12 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 {g u} "\nthis is a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 {g u} "\nthis is a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a gU transform
  proc run_test13 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 {g U} "\nTHIS is a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 {g U} "\nTHIS is a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a g? transform
  proc run_test14 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 {g question} "\nGuvf is a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 {g question} "\nGuvf is a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a > transform
  proc run_test15 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nThis is a line"
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nThis is a line" {2.0 2.5} visual:char
    do_test $txtt 1 {greater} "\n  This is a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.0 2.5
    do_test $txtt 2 {greater} "\n  This is a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a < transform
  proc run_test16 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\n    This is a line"
    $txtt mark set insert 2.4
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\n    This is a line" {2.4 2.9} visual:char
    do_test $txtt 1 {less} "\n  This is a line" {}

    # Verify mouse selection
    $txtt tag add sel 2.4 2.9
    do_test $txtt 2 {less} "\n  This is a line" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify a = transform
  proc run_test17 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\nif {1} {\n    set a 1\n}"
    $txtt mark set insert 3.4
    vim::adjust_insert $txtt

    # Verify visual mode
    do_test $txtt 0 {v 4 l} "\nif {1} {\n    set a 1\n}" {3.4 3.9} visual:char
    do_test $txtt 1 {equal} "\nif {1} {\n  set a 1\n}" {}

    # Verify mouse selection
    $txtt tag add sel 3.4 3.9
    do_test $txtt 2 {equal} "\nif {1} {\n  set a 1\n}" {}

    # Verify non-Vim mode

    # Cleanup
    cleanup

  }

  # Verify iw/aw
  proc run_test18 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set value "\nThis.is a line."]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape 0 v i w}   $value {2.0 2.4}
    do_object_test $txtt 1 {Escape 0 V i w}   $value {2.0 2.4}
    do_object_test $txtt 2 {Escape 0 v 2 i w} $value {2.0 2.5}

    do_object_test $txtt 3 {Escape 0 v a w}   $value {2.0 2.4}

    do_object_test $txtt 4 {Escape 6 bar v a w}   $value {2.5 2.8}
    do_object_test $txtt 5 {Escape 6 bar V a w}   $value {2.5 2.8}
    do_object_test $txtt 6 {Escape 6 bar v 2 a w} $value {2.5 2.10}

    do_object_test $txtt 7 {Escape 1 2 bar v a w}   $value {2.9 2.14}

    # Cleanup
    cleanup

  }

  # Verify iW/aW
  proc run_test19 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set value "\nThis.is a line."]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape 0 v i W}   $value {2.0 2.7}
    do_object_test $txtt 1 {Escape 0 V i W}   $value {2.0 2.7}
    do_object_test $txtt 2 {Escape 0 v 2 i W} $value {2.0 2.8}

    do_object_test $txtt 3 {Escape 0 v a W}   $value {2.0 2.8}

    do_object_test $txtt 4 {Escape 8 bar v a W}   $value {2.7 2.9}
    do_object_test $txtt 5 {Escape 8 bar V a W}   $value {2.7 2.9}
    do_object_test $txtt 6 {Escape 8 bar v 2 a W} $value {2.7 2.15}

    do_object_test $txtt 7 {Escape 1 2 bar v a W} $value {2.9 2.15}

    # Cleanup
    cleanup

  }

  # Verify is/as
  proc run_test20 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set value "\nSentence 1.  Sentence 2?  Sentence 3!"]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape 0 v i s}   $value {2.0 2.11}
    do_object_test $txtt 1 {Escape 1 V i s}   $value {2.0 2.11}
    do_object_test $txtt 2 {Escape 2 v 2 i s} $value {2.0 2.24}

    do_object_test $txtt 3 {Escape 3 v a s}   $value {2.0 2.13}
    do_object_test $txtt 4 {Escape 4 V a s}   $value {2.0 2.13}
    do_object_test $txtt 5 {Escape 5 v 2 a s} $value {2.0 2.26}

    # Cleanup
    cleanup

  }

  # Verify ip/ap
  proc run_test21 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set value "\nThis is the first sentence.  This is the\nsecond.\n\nThis is the next paragraph.\n\nThis is the last."]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape 0 v i p}   $value {2.0 3.7}
    do_object_test $txtt 1 {Escape 1 V i p}   $value {2.0 3.7}
    do_object_test $txtt 2 {Escape 2 v 2 i p} $value {2.0 5.27}

    set value2 [join [lreplace [split $value \n] 3 3 " "] \n]

    do_object_test $txtt 3 {Escape 3 v a p}   $value2 {2.0 4.1}
    do_object_test $txtt 4 {Escape 4 V a p}   $value2 {2.0 4.1}

    set value2 [join [lreplace [split $value \n] 5 5 " "] \n]

    do_object_test $txtt 5 {Escape 5 v 2 a p} $value2 {2.0 6.1}

    # Cleanup
    cleanup

  }

  # Verify i[, i], a[, a] Vim commands
  proc run_test22 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set value "\nset this \[this is \[really great\]\]"]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape v i bracketleft}  $value {2.0 2.1}
    do_object_test $txtt 1 {Escape v i bracketright} $value {2.0 2.1}
    do_object_test $txtt 2 {Escape V i bracketleft}  $value {2.0 3.0} visual:line
    do_object_test $txtt 3 {Escape V i bracketright} $value {2.0 3.0} visual:line
    do_object_test $txtt 4 {Escape v a bracketleft}  $value {2.0 2.1}
    do_object_test $txtt 5 {Escape v a bracketright} $value {2.0 2.1}
    do_object_test $txtt 6 {Escape V a bracketleft}  $value {2.0 3.0} visual:line
    do_object_test $txtt 7 {Escape V a bracketright} $value {2.0 3.0} visual:line

    set seli  [list {2.10 2.32} {2.19 2.31}]
    set sela  [list {2.9 2.33}  {2.18 2.32}]
    set index 7

    foreach {ins sel} [list 2.9 0 2.10 0 2.18 1 2.19 1 2.31 1 2.32 0] {
      $txtt mark set insert $ins
      do_object_test $txtt [incr index] {Escape v i bracketleft}  $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape v i bracketright} $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape V i bracketleft}  $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape V i bracketright} $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape v a bracketleft}  $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape v a bracketright} $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape V a bracketleft}  $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape V a bracketright} $value [lindex $sela $sel]
    }

    $txtt mark set insert 2.19

    foreach i {2 3} {
      do_object_test $txtt [incr index] [linsert {Escape v i bracketleft}  $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape v i bracketright} $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape V i bracketleft}  $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape V i bracketright} $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape v a bracketleft}  $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape v a bracketright} $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape V a bracketleft}  $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape V a bracketright} $i 2] $value [lindex $sela 0]
    }

    # Cleanup
    cleanup

  }

  # Verify i{, i}, a{, a} Vim commands
  proc run_test23 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set value "\nset this {this is {really great}}"]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape v i braceleft}  $value {2.0 2.1}
    do_object_test $txtt 1 {Escape v i braceright} $value {2.0 2.1}
    do_object_test $txtt 2 {Escape V i braceleft}  $value {2.0 3.0} visual:line
    do_object_test $txtt 3 {Escape V i braceright} $value {2.0 3.0} visual:line
    do_object_test $txtt 4 {Escape v a braceleft}  $value {2.0 2.1}
    do_object_test $txtt 5 {Escape v a braceright} $value {2.0 2.1}
    do_object_test $txtt 6 {Escape V a braceleft}  $value {2.0 3.0} visual:line
    do_object_test $txtt 7 {Escape V a braceright} $value {2.0 3.0} visual:line

    set seli  [list {2.10 2.32} {2.19 2.31}]
    set sela  [list {2.9 2.33}  {2.18 2.32}]
    set index 7

    foreach {ins sel} [list 2.9 0 2.10 0 2.18 1 2.19 1 2.31 1 2.32 0] {
      $txtt mark set insert $ins
      do_object_test $txtt [incr index] {Escape v i braceleft}  $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape v i braceright} $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape V i braceleft}  $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape V i braceright} $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape v a braceleft}  $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape v a braceright} $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape V a braceleft}  $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape V a braceright} $value [lindex $sela $sel]
    }

    $txtt mark set insert 2.19

    foreach i {2 3} {
      do_object_test $txtt [incr index] [linsert {Escape v i braceleft}  $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape v i braceright} $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape V i braceleft}  $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape V i braceright} $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape v a braceleft}  $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape v a braceright} $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape V a braceleft}  $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape V a braceright} $i 2] $value [lindex $sela 0]
    }

    # Cleanup
    cleanup

  }

  # Verify i(, i), ib, a(, a), ab Vim commands
  proc run_test24 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set value "\nset this (this is (really great))"]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0  {Escape v i parenleft}  $value {2.0 2.1}
    do_object_test $txtt 1  {Escape v i parenright} $value {2.0 2.1}
    do_object_test $txtt 2  {Escape v i b}          $value {2.0 2.1}
    do_object_test $txtt 3  {Escape V i parenleft}  $value {2.0 3.0} visual:line
    do_object_test $txtt 4  {Escape V i parenright} $value {2.0 3.0} visual:line
    do_object_test $txtt 5  {Escape V i b}          $value {2.0 3.0} visual:line
    do_object_test $txtt 6  {Escape v a parenleft}  $value {2.0 2.1}
    do_object_test $txtt 7  {Escape v a parenright} $value {2.0 2.1}
    do_object_test $txtt 8  {Escape v a b}          $value {2.0 2.1}
    do_object_test $txtt 9  {Escape V a parenleft}  $value {2.0 3.0} visual:line
    do_object_test $txtt 10 {Escape V a parenright} $value {2.0 3.0} visual:line
    do_object_test $txtt 11 {Escape V a b}          $value {2.0 3.0} visual:line

    set seli  [list {2.10 2.32} {2.19 2.31}]
    set sela  [list {2.9 2.33}  {2.18 2.32}]
    set index 11

    foreach {ins sel} [list 2.9 0 2.10 0 2.18 1 2.19 1 2.31 1 2.32 0] {
      $txtt mark set insert $ins
      do_object_test $txtt [incr index] {Escape v i parenleft}  $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape v i parenright} $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape v i b}          $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape V i parenleft}  $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape V i parenright} $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape V i b}          $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape v a parenleft}  $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape v a parenright} $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape v a b}          $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape V a parenleft}  $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape V a parenright} $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape V a b}          $value [lindex $sela $sel]
    }

    $txtt mark set insert 2.19

    foreach i {2 3} {
      do_object_test $txtt [incr index] [linsert {Escape v i parenleft}  $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape v i parenright} $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape v i b}          $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape V i parenleft}  $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape V i parenright} $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape V i b}          $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape v a parenleft}  $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape v a parenright} $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape v a b}          $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape V a parenleft}  $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape V a parenright} $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape V a b}          $i 2] $value [lindex $sela 0]
    }

    # Cleanup
    cleanup

  }

  # Verify i<, i>, a<, a> Vim commands
  proc run_test25 {} {

    # Initialize
    set txtt [initialize]

    # Set the current syntax to Tcl
    syntax::set_language [winfo parent $txtt] HTML

    $txtt insert end [set value "\nset this <this is <really great>>"]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape v i less}    $value {2.0 2.1}
    do_object_test $txtt 1 {Escape v i greater} $value {2.0 2.1}
    do_object_test $txtt 2 {Escape V i less}    $value {2.0 3.0} visual:line
    do_object_test $txtt 3 {Escape V i greater} $value {2.0 3.0} visual:line
    do_object_test $txtt 4 {Escape v a less}    $value {2.0 2.1}
    do_object_test $txtt 5 {Escape v a greater} $value {2.0 2.1}
    do_object_test $txtt 6 {Escape V a less}    $value {2.0 3.0} visual:line
    do_object_test $txtt 7 {Escape V a greater} $value {2.0 3.0} visual:line

    set seli  [list {2.10 2.32} {2.19 2.31}]
    set sela  [list {2.9 2.33}  {2.18 2.32}]
    set index 7

    foreach {ins sel} [list 2.9 0 2.10 0 2.18 1 2.19 1 2.31 1 2.32 0] {
      $txtt mark set insert $ins
      do_object_test $txtt [incr index] {Escape v i less}    $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape v i greater} $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape V i less}    $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape V i greater} $value [lindex $seli $sel]
      do_object_test $txtt [incr index] {Escape v a less}    $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape v a greater} $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape V a less}    $value [lindex $sela $sel]
      do_object_test $txtt [incr index] {Escape V a greater} $value [lindex $sela $sel]
    }

    $txtt mark set insert 2.19

    foreach i {2 3} {
      do_object_test $txtt [incr index] [linsert {Escape v i less}    $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape v i greater} $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape V i less}    $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape V i greater} $i 2] $value [lindex $seli 0]
      do_object_test $txtt [incr index] [linsert {Escape v a less}    $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape v a greater} $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape V a less}    $i 2] $value [lindex $sela 0]
      do_object_test $txtt [incr index] [linsert {Escape V a greater} $i 2] $value [lindex $sela 0]
    }

    # Cleanup
    cleanup

  }

  # Verify i", a" Vim command
  proc run_test26 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [set value "\nset this \"good\""]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape v i quotedbl} $value {2.0 2.1}
    do_object_test $txtt 1 {Escape V i quotedbl} $value {2.0 3.0} "visual:line"
    do_object_test $txtt 2 {Escape v a quotedbl} $value {2.0 2.1}
    do_object_test $txtt 3 {Escape V a quotedbl} $value {2.0 3.0} "visual:line"

    set index 3

    foreach ins [list 2.9 2.10 2.14] {
      $txtt mark set insert $ins
      do_object_test $txtt [incr index] {Escape v i quotedbl} $value {2.10 2.14}
      do_object_test $txtt [incr index] {Escape V i quotedbl} $value {2.10 2.14}
      do_object_test $txtt [incr index] {Escape v a quotedbl} $value {2.9 2.15}
      do_object_test $txtt [incr index] {Escape V a quotedbl} $value {2.9 2.15}
    }

    # Cleanup
    cleanup

  }

  # Verify i', a' Vim command
  proc run_test27 {} {

    # Initialize
    set txtt [initialize]

    # Set the current syntax to Tcl
    syntax::set_language [winfo parent $txtt] JavaScript

    $txtt insert end [set value "\nset this 'good'"]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape v i quoteright} $value {2.0 2.1}
    do_object_test $txtt 1 {Escape V i quoteright} $value {2.0 3.0} "visual:line"
    do_object_test $txtt 2 {Escape v a quoteright} $value {2.0 2.1}
    do_object_test $txtt 3 {Escape V a quoteright} $value {2.0 3.0} "visual:line"

    set index 3

    foreach ins [list 2.9 2.10 2.14] {
      $txtt mark set insert $ins
      do_object_test $txtt [incr index] {Escape v i quoteright} $value {2.10 2.14}
      do_object_test $txtt [incr index] {Escape V i quoteright} $value {2.10 2.14}
      do_object_test $txtt [incr index] {Escape v a quoteright} $value {2.9 2.15}
      do_object_test $txtt [incr index] {Escape V a quoteright} $value {2.9 2.15}
    }

    # Cleanup
    cleanup

  }

  # Verify i`, a` Vim command
  proc run_test28 {} {

    # Initialize
    set txtt [initialize]

    # Set the current syntax to Tcl
    syntax::set_language [winfo parent $txtt] JavaScript

    $txtt insert end [set value "\nset this `good`"]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape v i quoteleft} $value {2.0 2.1}
    do_object_test $txtt 1 {Escape V i quoteleft} $value {2.0 3.0} "visual:line"
    do_object_test $txtt 2 {Escape v a quoteleft} $value {2.0 2.1}
    do_object_test $txtt 3 {Escape V a quoteleft} $value {2.0 3.0} "visual:line"

    set index 3

    foreach ins [list 2.9 2.10 2.14] {
      $txtt mark set insert $ins
      do_object_test $txtt [incr index] {Escape v i quoteleft} $value {2.10 2.14}
      do_object_test $txtt [incr index] {Escape V i quoteleft} $value {2.10 2.14}
      do_object_test $txtt [incr index] {Escape v a quoteleft} $value {2.9 2.15}
      do_object_test $txtt [incr index] {Escape V a quoteleft} $value {2.9 2.15}
    }

    # Cleanup
    cleanup

  }

  # Verify it/at Vim command
  proc run_test29 {} {

    # Initialize
    set txtt [initialize]

    syntax::set_language [winfo parent $txtt] HTML

    $txtt insert end [set value "\n <ul><li>List item</li>  </ul>"]
    $txtt mark set insert 2.0
    vim::adjust_insert $txtt

    do_object_test $txtt 0 {Escape v i t} $value {2.0 2.1}
    do_object_test $txtt 1 {Escape V i t} $value {2.0 3.0} visual:line
    do_object_test $txtt 2 {Escape v a t} $value {2.0 2.1}
    do_object_test $txtt 3 {Escape V a t} $value {2.0 3.0} visual:line

    set seli  [list {2.5 2.25} {2.9 2.18}]
    set sela  [list {2.1 2.30} {2.5 2.23}]
    set index -1

    foreach {ins i} [list 2.1 0 2.4 0 2.5 1 2.10 1 2.22 1 2.23 0 2.29 0] {
      $txtt mark set insert $ins
      do_object_test $txtt [incr index] {Escape v i t} $value [lindex $seli $i]
      do_object_test $txtt [incr index] {Escape V i t} $value [lindex $seli $i]
      do_object_test $txtt [incr index] {Escape v a t} $value [lindex $sela $i]
      do_object_test $txtt [incr index] {Escape V a t} $value [lindex $sela $i]
    }

    # Cleanup
    cleanup

  }

}

