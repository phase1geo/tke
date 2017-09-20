namespace eval selectmode {

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
  # Emulates a keystroke.
  proc enter {txtt keysyms} {

    foreach keysym $keysyms {
      if {[lsearch [list Return Escape BackSpace Delete] $keysym] != -1} {
        select::handle_[string tolower $keysym] $txtt
      } else {
        select::handle_any $txtt $keysym
      }
    }

  }

  ######################################################################
  # Perform test and verifies different aspects of the selection mode.
  proc do_test {txtt id cmdlist sel anchor type {cursor ""}} {

    if {$cursor eq ""} {
      if {[llength $sel] > 0} {
        set index  [expr {$anchor ? 0 : "end"}]
        set cursor [lindex $sel $index]
      } else {
        set cursor [$txtt index insert]
      }
    }

    enter $txtt $cmdlist

    if {[$txtt tag ranges sel] ne $sel} {
      cleanup "$id selection incorrect ([$txtt tag ranges sel])"
    }
    if {[$txtt index insert] ne $cursor} {
      cleanup "$id cursor incorrect ([$txtt index insert])"
    }
    if {$select::data($txtt,anchorend) ne $anchor} {
      cleanup "$id anchorend incorrect ($select::data($txtt,anchorend))"
    }
    if {$select::data($txtt,type) ne $type} {
      cleanup "$id type incorrect ($select::data($txtt,type))"
    }

  }

  proc run_test1 {} {

    # Initialize the text widget
    set txtt [initialize]

    $txtt insert end [set value "This is a line "]
    $txtt edit separator
    vim::adjust_insert $txtt
    $txtt mark set insert 1.5

    # Make sure that our starting state is correct
    if {[$txtt tag ranges sel] ne [list]} {
      cleanup "starting selection incorrect ([$txtt tag ranges sel])"
    }

    # Make sure that the first word is selected
    select::set_select_mode $txtt 1
    do_test $txtt 0 {}     {1.5 1.7} 0 word
    do_test $txtt 1 Escape {}        0 none

    if {$select::data($txtt,mode)} {
      cleanup "Escape did not cause mode to clear"
    }
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "Escape changed text"
    }

    # Make sure that the next word is selected
    select::set_select_mode $txtt 1
    do_test $txtt 2 {}     {1.5 1.7} 0 word
    do_test $txtt 3 Return {1.5 1.7} 0 word

    if {$select::data($txtt,mode)} {
      cleanup "Return did not cause mode to clear"
    }
    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "Return changed text"
    }

    $txtt tag remove sel 1.0 end

    # Make sure that text is deleted
    select::set_select_mode $txtt 1
    do_test $txtt 4 {}     {1.5 1.7} 0 word
    do_test $txtt 5 Delete {}        0 none 1.5

    if {$select::data($txtt,mode)} {
      cleanup "Delete did not cause mode to clear"
    }
    if {[$txtt get 1.0 end-1c] ne "This  a line "} {
      cleanup "Delete did not cause text to be removed ([$txtt get 1.0 end-1c])"
    }

    vim::undo $txtt

    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "A Undo did not work properly"
    }
    if {[$txtt index insert] ne "1.7"} {
      cleanup "A Undo did not put cursor back properly ([$txtt index insert])"
    }

    # Make sure that text is deleted
    select::set_select_mode $txtt 1
    do_test $txtt 6 {}        {1.5 1.7} 0 word
    do_test $txtt 7 BackSpace {}        0 none 1.5

    if {$select::data($txtt,mode)} {
      cleanup "Backspace did not cause mode to clear"
    }
    if {[$txtt get 1.0 end-1c] ne "This  a line "} {
      cleanup "Backspace did not cause text to be removed"
    }

    vim::undo $txtt

    if {[$txtt get 1.0 end-1c] ne $value} {
      cleanup "B Undo did not work properly"
    }
    if {[$txtt index insert] ne "1.7"} {
      cleanup "B Undo did not put cursor back properly ([$txtt index insert])"
    }

    # Make sure that selection mode is correct when text is preselected
    $txtt tag add sel 1.0 1.4
    $txtt mark set insert 1.4
    select::set_select_mode $txtt 1
    do_test $txtt 8 {}     {1.0 1.4} 0 char
    do_test $txtt 9 Escape {}        0 none

    # Clean things up
    cleanup

  }

  # Verify that we can switch between selection modes with the proper
  # selection value.
  proc run_test2 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "This is a single\nline.  Is (this)\ninteresting?"
    vim::adjust_insert $txtt
    $txtt mark set insert 1.5

    # Enable selection mode
    select::set_select_mode $txtt 1

    do_test $txtt 0  {} {1.5 1.7}  0 word
    do_test $txtt 1  c  {1.5 1.7}  0 char
    do_test $txtt 2  w  {1.5 1.7}  0 word
    do_test $txtt 3  E  {1.5 1.16} 0 lineto
    do_test $txtt 4  w  {1.5 1.16} 0 word
    do_test $txtt 5  E  {1.5 1.16} 0 lineto
    do_test $txtt 6  c  {1.5 1.16} 0 char
    do_test $txtt 7  e  {1.0 1.16} 0 line
    do_test $txtt 8  E  {1.0 1.16} 0 lineto
    do_test $txtt 9  e  {1.0 1.16} 0 line
    do_test $txtt 10 w  {1.0 1.16} 0 word
    do_test $txtt 11 e  {1.0 1.16} 0 line
    do_test $txtt 12 c  {1.0 1.16} 0 char
    do_test $txtt 13 s  {1.0 2.7}  0 sentence
    do_test $txtt 14 w  {1.0 2.7}  0 word
    do_test $txtt 15 s  {1.0 2.7}  0 sentence
    do_test $txtt 16 c  {1.0 2.7}  0 char
    do_test $txtt 17 E  {1.0 2.16} 0 lineto
    do_test $txtt 18 p  {1.0 3.12} 0 paragraph
    do_test $txtt 19 s  {1.0 3.12} 0 sentence
    do_test $txtt 20 p  {1.0 3.12} 0 paragraph
    do_test $txtt 21 e  {1.0 3.12} 0 line
    do_test $txtt 22 p  {1.0 3.12} 0 paragraph
    do_test $txtt 23 w  {1.0 3.12} 0 word
    do_test $txtt 24 p  {1.0 3.12} 0 paragraph
    do_test $txtt 25 c  {1.0 3.12} 0 char

    do_test $txtt 26 Escape {} 0 none

    $txtt mark set insert 2.12

    select::set_select_mode $txtt 1

    do_test $txtt 27 parenleft {2.11 2.15} 0 paren
    do_test $txtt 28 i         {2.10 2.16} 0 paren
    do_test $txtt 29 i         {2.11 2.15} 0 paren
    do_test $txtt 30 a         {2.11 2.15} 1 paren
    do_test $txtt 31 E         {2.0 2.15}  1 lineto
    do_test $txtt 32 e         {2.0 2.16}  1 line

    # Clean things up
    cleanup

  }

  # Verify character selection anchor and motion
  proc run_test3 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [join [lrepeat 5 "This is a line."] \n]
    vim::adjust_insert $txtt
    $txtt mark set insert 1.5

    select::set_select_mode $txtt 1

    do_test $txtt 0  c     {1.5 1.7}  0 char
    do_test $txtt 1  l     {1.5 1.8}  0 char
    do_test $txtt 2  {2 l} {1.5 1.10} 0 char
    do_test $txtt 3  {6 l} {1.5 2.0}  0 char
    do_test $txtt 4  j     {1.5 3.0}  0 char
    do_test $txtt 5  {2 j} {1.5 5.0}  0 char
    do_test $txtt 6  h     {1.5 4.15} 0 char
    do_test $txtt 7  {2 h} {1.5 4.13} 0 char
    do_test $txtt 9  k     {1.5 3.13} 0 char
    do_test $txtt 10 {2 k} {1.5 1.13} 0 char
    do_test $txtt 11 Escape {} 0 none

    $txtt mark set insert 5.10
    select::set_select_mode $txtt 1

    do_test $txtt 12 c     {5.10 5.14} 0 char
    do_test $txtt 13 a     {5.10 5.14} 1 char
    do_test $txtt 14 h     {5.9 5.14}  1 char
    do_test $txtt 15 {2 h} {5.7 5.14}  1 char
    do_test $txtt 16 k     {4.7 5.14}  1 char
    do_test $txtt 17 {2 k} {2.7 5.14}  1 char
    do_test $txtt 18 l     {2.8 5.14}  1 char
    do_test $txtt 19 {2 l} {2.10 5.14} 1 char
    do_test $txtt 20 j     {3.10 5.14} 1 char
    do_test $txtt 21 {2 j} {5.10 5.14} 1 char
    do_test $txtt 22 {1 1 h} {4.15 5.14} 1 char
    do_test $txtt 23 Escape {} 1 none

    $txtt mark set insert 1.5
    select::set_select_mode $txtt 1

    do_test $txtt 25 c     {1.5 1.7}  0 char
    do_test $txtt 26 L     {1.6 1.8}  0 char
    do_test $txtt 27 {2 L} {1.8 1.10} 0 char
    do_test $txtt 28 J     {2.8 2.10} 0 char
    do_test $txtt 29 {2 J} {4.8 4.10} 0 char
    do_test $txtt 30 H     {4.7 4.9}  0 char
    do_test $txtt 31 {2 H} {4.5 4.7}  0 char
    do_test $txtt 32 K     {3.5 3.7}  0 char
    do_test $txtt 33 {2 K} {1.5 1.7}  0 char
    do_test $txtt 34 a     {1.5 1.7}  1 char
    do_test $txtt 35 L     {1.6 1.8}  1 char
    do_test $txtt 36 J     {2.6 2.8}  1 char
    do_test $txtt 37 H     {2.5 2.7}  1 char
    do_test $txtt 38 K     {1.5 1.7}  1 char
    do_test $txtt 39 Escape {} 1 none

    # Clean things up
    cleanup

  }

  # Verify word select mode
  proc run_test4 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [join [lrepeat 4 "This is a good line."] \n]
    vim::adjust_insert $txtt
    $txtt mark set insert 1.0

    select::set_select_mode $txtt 1

    do_test $txtt 0  {}    {1.0 1.4}   0 word
    do_test $txtt 1  l     {1.0 1.7}   0 word
    do_test $txtt 2  {2 l} {1.0 1.14}  0 word
    do_test $txtt 3  {4 l} {1.0 2.7}   0 word
    do_test $txtt 4  h     {1.0 2.4}   0 word
    do_test $txtt 5  {2 h} {1.0 1.19}  0 word
    do_test $txtt 6  {3 h} {1.0 1.7}   0 word
    do_test $txtt 7  L     {1.5 1.9}   0 word
    do_test $txtt 8  {2 L} {1.10 1.19} 0 word
    do_test $txtt 9  H     {1.8 1.14}  0 word
    do_test $txtt 10 {2 H} {1.0 1.7}   0 word
    do_test $txtt 11 {3 L} {1.10 1.19} 0 word
    do_test $txtt 12 a     {1.10 1.19} 1 word
    do_test $txtt 13 l     {1.15 1.19} 1 word
    do_test $txtt 14 h     {1.10 1.19} 1 word
    do_test $txtt 15 {2 h} {1.5 1.19}  1 word
    do_test $txtt 16 {3 l} {1.15 1.19} 1 word
    do_test $txtt 17 H     {1.10 1.14} 1 word
    do_test $txtt 18 {2 H} {1.5 1.7}   1 word
    do_test $txtt 19 L     {1.8 1.9}   1 word
    do_test $txtt 20 {2 L} {1.15 1.19} 1 word
    do_test $txtt 21 Escape {} 1 none

    # Clean things up
    cleanup

  }

  # Verify lineto selection mode
  proc run_test5 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [join [lrepeat 4 "This is a line."] \n]
    vim::adjust_insert $txtt
    $txtt mark set insert 1.5

    select::set_select_mode $txtt 1

    do_test $txtt 0 {}    {1.5 1.7}  0 word
    do_test $txtt 1 E     {1.5 1.15} 0 lineto
    do_test $txtt 2 j     {1.5 2.15} 0 lineto
    do_test $txtt 3 {2 j} {1.5 4.15} 0 lineto
    do_test $txtt 4 k     {1.5 3.15} 0 lineto
    do_test $txtt 5 {2 k} {1.5 1.15} 0 lineto
    do_test $txtt 6 J     {2.5 2.15} 0 lineto
    do_test $txtt 7 {2 J} {4.5 4.15} 0 lineto
    do_test $txtt 8 K     {3.5 3.15} 0 lineto
    do_test $txtt 9 {2 K} {1.5 1.15} 0 lineto
    do_test $txtt 10 Escape {} 0 none

    $txtt mark set insert 4.5
    select::set_select_mode $txtt 1

    do_test $txtt 11 a     {4.5 4.7} 1 word
    do_test $txtt 12 E     {4.0 4.7} 1 lineto
    do_test $txtt 13 k     {3.0 4.7} 1 lineto
    do_test $txtt 14 {2 k} {1.0 4.7} 1 lineto
    do_test $txtt 15 j     {2.0 4.7} 1 lineto
    do_test $txtt 16 {2 j} {4.0 4.7} 1 lineto
    do_test $txtt 17 K     {3.0 3.7} 1 lineto
    do_test $txtt 18 {2 K} {1.0 1.7} 1 lineto
    do_test $txtt 19 J     {2.0 2.7} 1 lineto
    do_test $txtt 20 {2 J} {4.0 4.7} 1 lineto
    do_test $txtt 21 Escape {} 1 none

    # Clean things up
    cleanup

  }

  # Verify line selection mode
  proc run_test6 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end [join [lrepeat 4 "This is a line."] \n]
    vim::adjust_insert $txtt
    $txtt mark set insert 1.5

    select::set_select_mode $txtt 1

    do_test $txtt 0 {}    {1.5 1.7}  0 word
    do_test $txtt 1 e     {1.0 1.15} 0 line
    do_test $txtt 2 j     {1.0 2.15} 0 line
    do_test $txtt 3 {2 j} {1.0 4.15} 0 line
    do_test $txtt 4 k     {1.0 3.15} 0 line
    do_test $txtt 5 {2 k} {1.0 1.15} 0 line
    do_test $txtt 6 J     {2.0 2.15} 0 line
    do_test $txtt 7 {2 J} {4.0 4.15} 0 line
    do_test $txtt 8 K     {3.0 3.15} 0 line
    do_test $txtt 9 {2 K} {1.0 1.15} 0 line
    do_test $txtt 10 Escape {} 0 none

    $txtt mark set insert 4.5
    select::set_select_mode $txtt 1

    do_test $txtt 11 a     {4.5 4.7}  1 word
    do_test $txtt 12 e     {4.0 4.15} 1 line
    do_test $txtt 13 k     {3.0 4.15} 1 line
    do_test $txtt 14 {2 k} {1.0 4.15} 1 line
    do_test $txtt 15 j     {2.0 4.15} 1 line
    do_test $txtt 16 {2 j} {4.0 4.15} 1 line
    do_test $txtt 17 K     {3.0 3.15} 1 line
    do_test $txtt 18 {2 K} {1.0 1.15} 1 line
    do_test $txtt 19 J     {2.0 2.15} 1 line
    do_test $txtt 20 {2 J} {4.0 4.15} 1 line
    do_test $txtt 21 Escape {} 1 none

    # Clean things up
    cleanup

  }

  # Verify sentence selection mode.
  proc run_test7 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "This is good.  This is fine.  This is okay.  This is nice."
    vim::adjust_insert $txtt
    $txtt mark set insert 1.0

    select::set_select_mode $txtt 1

    do_test $txtt 0 {}    {1.0 1.4}   0 word
    do_test $txtt 1 s     {1.0 1.15}  0 sentence
    do_test $txtt 2 l     {1.0 1.30}  0 sentence
    do_test $txtt 3 {2 l} {1.0 1.58}  0 sentence
    do_test $txtt 4 h     {1.0 1.45}  0 sentence
    do_test $txtt 5 {2 h} {1.0 1.15}  0 sentence
    do_test $txtt 6 L     {1.15 1.30} 0 sentence
    do_test $txtt 7 {2 L} {1.45 1.58} 0 sentence
    do_test $txtt 8 H     {1.30 1.45} 0 sentence
    do_test $txtt 9 {2 H} {1.0 1.15}  0 sentence
    do_test $txtt 10 Escape {} 0 none

    $txtt mark set insert 1.45
    select::set_select_mode $txtt 1

    do_test $txtt 11 w     {1.45 1.49} 0 word
    do_test $txtt 12 a     {1.45 1.49} 1 word
    do_test $txtt 13 s     {1.45 1.58} 1 sentence
    do_test $txtt 14 h     {1.30 1.58} 1 sentence
    do_test $txtt 15 {2 h} {1.0 1.58}  1 sentence
    do_test $txtt 16 l     {1.15 1.58} 1 sentence
    do_test $txtt 17 {2 l} {1.45 1.58} 1 sentence
    do_test $txtt 18 H     {1.30 1.45} 1 sentence
    do_test $txtt 19 {2 H} {1.0 1.15}  1 sentence
    do_test $txtt 20 L     {1.15 1.30} 1 sentence
    do_test $txtt 21 {2 L} {1.45 1.58} 1 sentence
    do_test $txtt 22 Escape {} 1 none

    # Clean things up
    cleanup

  }

  # Verify paragraph selection mode.
  proc run_test8 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "This is\ngood.  A.\n\nThis is\nnice.  B.\n\nThis is\nokay.  C.\n\nThis is\nfine.  D."
    vim::adjust_insert $txtt
    $txtt mark set insert 1.5

    select::set_select_mode $txtt 1

    do_test $txtt 0 {}    {1.5 1.7}   0 word
    do_test $txtt 1 p     {1.0 4.0}   0 paragraph
    do_test $txtt 2 l     {1.0 7.0}   0 paragraph
    do_test $txtt 3 {2 l} {1.0 11.9}  0 paragraph
    do_test $txtt 4 h     {1.0 10.0}  0 paragraph
    do_test $txtt 5 {2 h} {1.0 4.0}   0 paragraph
    do_test $txtt 6 L     {4.0 7.0}   0 paragraph
    do_test $txtt 7 {2 L} {10.0 11.9} 0 paragraph
    do_test $txtt 8 H     {7.0 10.0}  0 paragraph
    do_test $txtt 9 {2 H} {1.0 4.0}   0 paragraph
    do_test $txtt 10 Escape {} 0 none

    $txtt mark set insert 11.0
    select::set_select_mode $txtt 1

    do_test $txtt 11 {}    {11.0 11.4} 0 word
    do_test $txtt 12 a     {11.0 11.4} 1 word
    do_test $txtt 13 p     {10.0 11.9} 1 paragraph
    do_test $txtt 14 h     {7.0 11.9}  1 paragraph
    do_test $txtt 15 {2 h} {1.0 11.9}  1 paragraph
    do_test $txtt 16 l     {4.0 11.9}  1 paragraph
    do_test $txtt 17 {2 l} {10.0 11.9} 1 paragraph
    do_test $txtt 18 H     {7.0 10.0}  1 paragraph
    do_test $txtt 19 {2 H} {1.0 4.0}   1 paragraph
    do_test $txtt 20 L     {4.0 7.0}   1 paragraph
    do_test $txtt 21 {2 L} {10.0 11.9} 1 paragraph
    do_test $txtt 22 Escape {} 1 none

    # Clean things up
    cleanup

  }

  # Verify curly bracket
  proc run_test9 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "{this is a {curly} bracket}"
    vim::adjust_insert $txtt

    $txtt mark set insert 1.2
    select::set_select_mode $txtt 1

    do_test $txtt 0 {}        {1.0 1.5}  0 word
    do_test $txtt 1 braceleft {1.1 1.26} 0 curly
    do_test $txtt 2 i         {1.0 1.27} 0 curly
    do_test $txtt 3 i         {1.1 1.26} 0 curly
    do_test $txtt 4 a         {1.1 1.26} 1 curly
    do_test $txtt 5 i         {1.0 1.27} 1 curly
    do_test $txtt 6 i         {1.1 1.26} 1 curly
    do_test $txtt 7 Escape {} 1 none

    $txtt mark set insert 1.13
    select::set_select_mode $txtt 1

    do_test $txtt 8  braceleft {1.12 1.17} 0 curly
    do_test $txtt 9  i         {1.11 1.18} 0 curly
    do_test $txtt 10 i         {1.12 1.17} 0 curly
    do_test $txtt 11 Escape {} 0 none

    # Clean things up
    cleanup

  }

  # Verify square bracket
  proc run_test10 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "\[this is a \[square\] bracket\]"
    vim::adjust_insert $txtt

    $txtt mark set insert 1.2
    select::set_select_mode $txtt 1

    do_test $txtt 0 {}          {1.0 1.5}  0 word
    do_test $txtt 1 bracketleft {1.1 1.27} 0 square
    do_test $txtt 2 i           {1.0 1.28} 0 square
    do_test $txtt 3 i           {1.1 1.27} 0 square
    do_test $txtt 4 a           {1.1 1.27} 1 square
    do_test $txtt 5 i           {1.0 1.28} 1 square
    do_test $txtt 6 i           {1.1 1.27} 1 square
    do_test $txtt 7 Escape {} 1 none

    $txtt mark set insert 1.13
    select::set_select_mode $txtt 1

    do_test $txtt 8  bracketleft {1.12 1.18} 0 square
    do_test $txtt 9  i           {1.11 1.19} 0 square
    do_test $txtt 10 i           {1.12 1.18} 0 square
    do_test $txtt 11 Escape {} 0 none

    # $txtt insert end "this is a 'single' quote\n"
    # $txtt insert end "this is a `backtick` quote"

    # Clean things up
    cleanup

  }

  # Verify parenthesis selection mode
  proc run_test11 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "(this is a (paren) bracket)"
    vim::adjust_insert $txtt

    $txtt mark set insert 1.2
    select::set_select_mode $txtt 1

    do_test $txtt 0 {}        {1.0 1.5}  0 word
    do_test $txtt 1 parenleft {1.1 1.26} 0 paren
    do_test $txtt 2 i         {1.0 1.27} 0 paren
    do_test $txtt 3 i         {1.1 1.26} 0 paren
    do_test $txtt 4 a         {1.1 1.26} 1 paren
    do_test $txtt 5 i         {1.0 1.27} 1 paren
    do_test $txtt 6 i         {1.1 1.26} 1 paren
    do_test $txtt 7 Escape {} 1 none

    $txtt mark set insert 1.13
    select::set_select_mode $txtt 1

    do_test $txtt 8  parenleft {1.12 1.17} 0 paren
    do_test $txtt 9  i         {1.11 1.18} 0 paren
    do_test $txtt 10 i         {1.12 1.17} 0 paren
    do_test $txtt 11 Escape {} 0 none

    # Clean things up
    cleanup

  }

  # Verify angled bracket selection mode
  proc run_test12 {} {

    # Initialize
    set txtt [initialize]

    syntax::set_language [winfo parent $txtt] HTML

    $txtt insert end "<this is an <angled> bracket>"
    vim::adjust_insert $txtt

    $txtt mark set insert 1.2
    select::set_select_mode $txtt 1

    do_test $txtt 0 {}   {1.0 1.5}  0 word
    do_test $txtt 1 less {1.1 1.28} 0 angled
    do_test $txtt 2 i    {1.0 1.29} 0 angled
    do_test $txtt 3 i    {1.1 1.28} 0 angled
    do_test $txtt 4 a    {1.1 1.28} 1 angled
    do_test $txtt 5 i    {1.0 1.29} 1 angled
    do_test $txtt 6 i    {1.1 1.28} 1 angled
    do_test $txtt 7 Escape {} 1 none

    $txtt mark set insert 1.13
    select::set_select_mode $txtt 1

    do_test $txtt 8  less {1.13 1.19} 0 angled
    do_test $txtt 9  i    {1.12 1.20} 0 angled
    do_test $txtt 10 i    {1.13 1.19} 0 angled
    do_test $txtt 11 Escape {} 0 none

    # Clean things up
    cleanup

  }

  # Verify double-quote selection mode
  proc run_test13 {} {

    # Initialize
    set txtt [initialize]

    $txtt insert end "this is a \"double quote\" thing"
    vim::adjust_insert $txtt

    $txtt mark set insert 1.12
    select::set_select_mode $txtt 1

    do_test $txtt 0 {}       {1.11 1.17} 0 word
    do_test $txtt 1 quotedbl {1.11 1.23} 0 double
    do_test $txtt 2 i        {1.10 1.24} 0 double
    do_test $txtt 3 i        {1.11 1.23} 0 double
    do_test $txtt 4 a        {1.11 1.23} 1 double
    do_test $txtt 5 i        {1.10 1.24} 1 double
    do_test $txtt 6 i        {1.11 1.23} 1 double
    do_test $txtt 7 Escape {} 1 none

    # Clean things up
    cleanup

  }

  # Verify single quote selection mode
  proc run_test14 {} {

    # Initialize
    set txtt [initialize]

    syntax::set_language [winfo parent $txtt] "JavaScript"

    $txtt insert end "this is a 'single quote' thing"
    vim::adjust_insert $txtt

    $txtt mark set insert 1.12
    select::set_select_mode $txtt 1

    do_test $txtt 0 {}         {1.11 1.17} 0 word
    do_test $txtt 1 quoteright {1.11 1.23} 0 single
    do_test $txtt 2 i          {1.10 1.24} 0 single
    do_test $txtt 3 i          {1.11 1.23} 0 single
    do_test $txtt 4 a          {1.11 1.23} 1 single
    do_test $txtt 5 i          {1.10 1.24} 1 single
    do_test $txtt 6 i          {1.11 1.23} 1 single
    do_test $txtt 7 Escape {} 1 none

    # Clean things up
    cleanup

  }

  # Verify backtick selection mode
  proc run_test15 {} {

    # Initialize
    set txtt [initialize]

    syntax::set_language [winfo parent $txtt] "JavaScript"

    $txtt insert end "this is a `back tick` thing"
    vim::adjust_insert $txtt

    $txtt mark set insert 1.12
    select::set_select_mode $txtt 1

    do_test $txtt 0 {}        {1.11 1.15} 0 word
    do_test $txtt 1 quoteleft {1.11 1.20} 0 btick
    do_test $txtt 2 i         {1.10 1.21} 0 btick
    do_test $txtt 3 i         {1.11 1.20} 0 btick
    do_test $txtt 4 a         {1.11 1.20} 1 btick
    do_test $txtt 5 i         {1.10 1.21} 1 btick
    do_test $txtt 6 i         {1.11 1.20} 1 btick
    do_test $txtt 7 Escape {} 1 none

    # Clean things up
    cleanup

  }

  # Verify block selection mode
  proc run_test16 {} {

    # Initialize
    set txtt [initialize]

    # Clean things up
    cleanup

  }

  # Verify node selection mode
  proc run_test17 {} {

    # Initialize
    set txtt [initialize]

    # Clean things up
    cleanup

  }

}
