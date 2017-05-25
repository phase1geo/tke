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

    enter $txtt $cmdlist

    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "$id text mismatched ([$txtt get 1.0 end-1c])"
    }
    if {[$txtt tag ranges sel] ne $sel} {
      cleanup "$id selection found ([$txtt tag ranges sel])"
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

    do_test $txtt 0 {Escape 0 v i w}   $value {2.0 2.4}  visual:char
    do_test $txtt 1 {Escape 0 V i w}   $value {2.0 2.4}  visual:char
    do_test $txtt 2 {Escape 0 v 2 i w} $value {2.0 2.5}  visual:char

    do_test $txtt 3 {Escape 0 v a w}   $value {2.0 2.4}  visual:char

    do_test $txtt 4 {Escape 6 bar v a w}   $value {2.5 2.8}  visual:char
    do_test $txtt 5 {Escape 6 bar V a w}   $value {2.5 2.8}  visual:char
    do_test $txtt 6 {Escape 6 bar v 2 a w} $value {2.5 2.10} visual:char

    do_test $txtt 7 {Escape 1 2 bar v a w}   $value {2.9 2.14} visual:char

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

    do_test $txtt 0 {Escape 0 v i W}   $value {2.0 2.7}  visual:char
    do_test $txtt 1 {Escape 0 V i W}   $value {2.0 2.7}  visual:char
    do_test $txtt 2 {Escape 0 v 2 i W} $value {2.0 2.9}  visual:char

    do_test $txtt 3 {Escape 0 v a W}   $value {2.0 2.8}  visual:char

    do_test $txtt 4 {Escape 8 bar v a W}   $value {2.8 2.9}  visual:char
    do_test $txtt 5 {Escape 8 bar V a W}   $value {2.8 2.9}  visual:char
    do_test $txtt 6 {Escape 8 bar v 2 a W} $value {2.8 2.15} visual:char

    do_test $txtt 7 {Escape 1 2 bar v a W} $value {2.9 2.15} visual:char

    # Cleanup
    cleanup

  }

}
