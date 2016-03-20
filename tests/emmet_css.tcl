namespace eval emmet_css {

  ######################################################################
  # Common diagnostic initialization procedure.  Returns the pathname
  # to the added text widget.
  proc initialize {} {

    variable current_tab

    # Add a new file
    set current_tab [gui::add_new_file end]

    # Get the text widget
    set txt [gui::get_info $current_tab tab txt]

    # Set the current syntax to CSS
    syntax::set_language $txt CSS

    return $txt

  }

  ######################################################################
  # Common cleanup procedure.  If a fail message is provided, return an
  # error with the given error message.
  proc cleanup {{fail_msg ""}} {

    variable current_tab

    # Close the current tab
    gui::close_tab {} $current_tab -check 0

    # Output the fail message and cause a failure
    if {$fail_msg ne ""} {
      return -code error $fail_msg
    }

  }

  proc run_test1 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nm10"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {margin: 10px;}

    if {$actual ne $expect} {
      cleanup "m10 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test2 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nm10p20e30x"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {margin: 10% 20em 30ex;}

    if {$actual ne $expect} {
      cleanup "m10p20e30x did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test3 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nm1.5"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {margin: 1.5em;}

    if {$actual ne $expect} {
      cleanup "m1.5 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test4 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nm1.5ex"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {margin: 1.5ex;}

    if {$actual ne $expect} {
      cleanup "m1.5ex did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test5 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nm10foo"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {margin: 10foo;}

    if {$actual ne $expect} {
      cleanup "m10foo did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test6 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nw100p"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {width: 100%;}

    if {$actual ne $expect} {
      cleanup "w100p did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test7 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nc#3"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {color: #333333;}

    if {$actual ne $expect} {
      cleanup "c#3 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test8 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nc#e0"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {color: #e0e0e0;}

    if {$actual ne $expect} {
      cleanup "c#e0 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test9 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nc#fc0"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {color: #ffcc00;}

    if {$actual ne $expect} {
      cleanup "c#fc0 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test10 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nbd5#0s"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {border: 5px #000000 solid;}

    if {$actual ne $expect} {
      cleanup "bd5#0 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test11 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nlh2"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {line-height: 2;}

    if {$actual ne $expect} {
      cleanup "lh2 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test12 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\nfw400"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {font-weight: 400;}

    if {$actual ne $expect} {
      cleanup "fw400 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test13 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\np!+m10e!"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{padding: !important;
margin: 10em !important;}

    if {$actual ne $expect} {
      cleanup "p!+m10e! did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test14 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\n-trf"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{-webkit-transform: ;
-moz-transform: $1;
-ms-transform: $1;
-o-transform: $1;
transform: $1;}

    if {$actual ne $expect} {
      cleanup "-trf did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test15 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\n-wm-trf"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{-webkit-transform: ;
-moz-transform: $1;
transform: $1;}

    if {$actual ne $expect} {
      cleanup "-wm-trf did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test16 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\ntal:a"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect \
{-ms-text-align-last: auto;
text-align-last: auto;}

    if {$actual ne $expect} {
      cleanup "tal:a did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test17 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\noh"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {overflow: hidden;}

    if {$actual ne $expect} {
      cleanup "oh did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test18 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\novh"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {overflow: hidden;}

    if {$actual ne $expect} {
      cleanup "ovh did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test19 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\n10"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {10px}

    if {$actual ne $expect} {
      cleanup "10 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

  proc run_test20 {} {

    # Create the text widget
    set txt [initialize]

    $txt insert end "\n#3"
    $txt mark set insert end-1c

    emmet::expand_abbreviation {}

    set actual [$txt get 2.0 end-1c]
    set expect {#333333}

    if {$actual ne $expect} {
      cleanup "#3 did not expand properly ($actual)"
    }

    # Clean everything up
    cleanup

  }

}
