#===============================================================
# Main tabbar package module
#
# Copyright (c) 2011-2014  Trevor Williams (phase1geo@gmail.com)
#===============================================================

package provide tabbar 1.2

namespace eval tabbar {

  array set data {}

  array set widget_options {
    -activebackground       {activeBackground       Background}
    -activeforeground       {activeForeground       Foreground}
    -anchor                 {anchor                 Anchor}
    -background             {background             Background}
    -bg                     -background
    -bordercolor            {borderColor            Color}
    -borderwidth            {borderWidth            BorderWidth}
    -bd                     -borderwidth
    -busy                   {busy                   Busy}
    -checkcommand           {checkCommand           Command}
    -close                  {close                  Close}
    -closecommand           {closeCommand           Command}
    -closeimage             {closeImage             Image}
    -closeshow              {closeShow              CloseShow}
    -command                {command                Command}
    -disabledforeground     {disabledForeground     DisabledForeground}
    -font                   {font                   Font}
    -foreground             {foreground             Foreground}
    -fg                     -foreground
    -height                 {height                 Height}
    -history                {history                History}
    -inactivebackground     {inactiveBackground     Background}
    -inactiveforeground     {inactiveForeground     Foreground}
    -margin                 {margin                 Margin}
    -maxtabwidth            {maxTabWidth            TabWidth}
    -mintabwidth            {minTabWidth            TabWidth}
    -padx                   {padX                   Pad}
    -pady                   {padY                   Pad}
    -relief                 {relief                 Relief}
    -state                  {state                  State}
    -takefocus              {takeFocus              TakeFocus}
    -width                  {width                  Width}
    -xscrollincrement       {xScrollIncrement       ScrollIncrement}
  }

  array set tab_options {
    -busy         0
    -compound     ""
    -emboss       1
    -image        ""
    -padx         3
    -pady         3
    -state        normal
    -text         ""
    -movable      1
  }

  ######################################################################
  # Creates a new instance of a tabbar including the main UI, option
  # setup, binding and initialization.
  proc tabbar {w args} {

    variable data
    variable widget_options

    # The widget will be a frame
    frame $w -class Tabbar -takefocus 0

    # The tab bar will be a canvas
    canvas $w.c  -bg grey90 -takefocus 1 -bd 0 -highlightthickness 0 -relief flat -confine 0
    label  $w.sl -text "\u276e" -bg grey80 -fg black -disabledforeground grey50 -padx 8 -state disabled -relief flat
    label  $w.sr -text "\u276f" -bg grey80 -fg black -disabledforeground grey50 -padx 8 -relief flat

    grid rowconfigure    $w 0 -weight 1
    grid columnconfigure $w 1 -weight 1
    grid $w.sl -row 0 -column 0 -sticky news
    grid $w.c  -row 0 -column 1 -sticky news
    grid $w.sr -row 0 -column 2 -sticky news

    grid remove $w.sl
    grid remove $w.sr

    bind $w.sl <Button-1> "tabbar::scroll_left  $w"
    bind $w.sr <Button-1> "tabbar::scroll_right $w"

    if {[array size data] == 0} {

      # Initialize default options
      option add *Tabbar.activeBackground    grey90    widgetDefault
      option add *Tabbar.activeForeground    black     widgetDefault
      option add *Tabbar.anchor              center    widgetDefault
      option add *Tabbar.background          grey90    widgetDefault
      option add *Tabbar.borderColor         grey50    widgetDefault
      option add *Tabbar.busy                "left"    widgetDefault
      option add *Tabbar.close               "right"   widgetDefault
      option add *Tabbar.closeImage          ""        widgetDefault
      option add *Tabbar.closeShow           "enter"   widgetDefault
      option add *Tabbar.command             ""        widgetDefault
      option add *Tabbar.disabledForeground  grey50    widgetDefault
      option add *Tabbar.foreground          black     widgetDefault
      option add *Tabbar.inactiveBackground  grey70    widgetDefault
      option add *Tabbar.inactiveForeground  black     widgetDefault
      option add *Tabbar.height              25        widgetDefault
      option add *Tabbar.history             1         widgetDefault
      option add *Tabbar.margin              0         widgetDefault
      option add *Tabbar.maxTabWidth         200       widgetDefault
      option add *Tabbar.minTabWidth         100       widgetDefault
      option add *Tabbar.relief              "flat"    widgetDefault
      option add *Tabbar.width               500       widgetDefault
      option add *Tabbar.xScrollIncrement    100       widgetDefault

    }

    # Create any images
    set imgdir [file join [DIR] library images]
    set data($w,image,close) [image create bitmap -file [file join $imgdir close.bmp] -maskfile [file join $imgdir close.bmp] -foreground black]
    set data($w,image,left)  [image create bitmap -file [file join $imgdir left.bmp]  -maskfile [file join $imgdir left.bmp]  -foreground black]
    set data($w,image,right) [image create bitmap -file [file join $imgdir right.bmp] -maskfile [file join $imgdir right.bmp] -foreground black]
    for {set i 1} {$i <= 8} {incr i} {
      set data($w,image,busy$i) [image create bitmap -file [file join $imgdir busy$i.bmp] -maskfile [file join $imgdir busy$i.bmp] -foreground black]
    }

    # Initialize variables
    set data($w,pages)       [list]
    set data($w,tab_order)   [list]
    set data($w,tab_width)   200
    set data($w,left_tab)    0
    set data($w,last_tab)    -1
    set data($w,current)     -1
    set data($w,history)     [list]
    set data($w,tags,canvas) "tabbar$w"

    # Initialize the options array
    foreach opt [array names widget_options] {
      set data($w,option,$opt) [option get $w [lindex $widget_options($opt) 0] [lindex $widget_options($opt) 1]]
    }

    # Set the bindtags for the text and listbox widgets
    bindtags $w.c [linsert [bindtags $w.c] 1 $data($w,tags,canvas) TabbarTabBar]

    # Setup bindings
    if {[llength [bind TabbarTabBar]] == 0} {

      bind TabbarTabBar <Configure>  { tabbar::redraw  [winfo parent %W] }
      bind TabbarTabBar <Destroy>    { tabbar::destroy [winfo parent %W] }
      bind TabbarTabBar <Leave>      { tabbar::handle_tabbar_leave  [winfo parent %W] %x %y }
      bind TabbarTabBar <Motion>     { tabbar::handle_tabbar_motion [winfo parent %W] %x %y }
      bind TabbarTabBar <MouseWheel> { tabbar::handle_tabbar_mousewheel [winfo parent %W] %D }
      bind TabbarTabBar <4>          { tabbar::handle_tabbar_mousewheel [winfo parent %W]  1 }
      bind TabbarTabBar <5>          { tabbar::handle_tabbar_mousewheel [winfo parent %W] -1 }

    }

    # Configure the widget
    configure 1 $w {*}$args

    # Rename and alias the tabbar window
    rename ::$w $w
    interp alias {} ::$w {} tabbar::widget_cmd $w

    return $w

  }

  ######################################################################
  # Called when the widget is destroyed.
  proc destroy {w} {

    variable data

    # If the data array is empty, destroy the images
    foreach {name value} [array get data $w,image,*] {
      image delete $value
    }

    # Delete all of the information associated with the window
    array unset data $w,*

  }

  ######################################################################
  # Scrolls one unit to the left.
  proc scroll_left {w} {

    variable data

    if {[winfo ismapped $w.sl] && ([$w.sl cget -state] eq "normal")} {

      # Update the left_tab value
      incr data($w,left_tab) -1

      # Move one unit to the left
      $w.c xview scroll -1 units

      # Update the state of the shift buttons
      update_shift_button_state $w

    }

  }

  ######################################################################
  # Scrolls one unit to the right.
  proc scroll_right {w} {

    variable data

    if {[winfo ismapped $w.sr] && ([$w.sr cget -state] eq "normal")} {

      # Move one unit to the right
      $w.c xview scroll 1 units

      # Set the left-most tab
      incr data($w,left_tab)

      # Update the state of the shift buttons
      update_shift_button_state $w

    }

  }

  ######################################################################
  # Animates a scroll to the left.
  proc animate_scroll_left {w} {

    variable data

    if {$data($w,scroll)} {

      # If we have reached the left-most tab, move over one
      if {[leftmost_tab $w] > 0} {

        # Scroll everything to the left by one tab
        scroll_left $w

        # Move the current tab
        set current_tab [tab_tag $w [page_index $w $data($w,moveto_index)]]
        $w.c move $current_tab [expr 0 - $data($w,option,-xscrollincrement)] 0

        # Get the tab tag of the tab to evaluate
        set other_index [expr $data($w,moveto_index) - 1]
        set other_tabid [tab_tag $w [page_index $w $other_index]]

        # Move the other tab
        lassign [$w.c coords [string range $other_tabid 1 end]] x0
        $w.c move $other_tabid [expr ($data($w,moveto_index) * $data($w,tab_width)) - $x0] 0

        # Update the order in the tab_order list
        set tmp                   [lindex   $data($w,tab_order) $other_index]
        set data($w,tab_order)    [lreplace $data($w,tab_order) $other_index $other_index]
        set data($w,tab_order)    [linsert  $data($w,tab_order) $data($w,moveto_index) $tmp]
        set data($w,moveto_index) $other_index

      # Otherwise, indicate that we are done scrolling
      } else {
        set data($w,scroll) 0
      }

      # Do this again in 0.5 seconds
      after 500 [list tabbar::animate_scroll_left $w]

    }

  }

  ######################################################################
  # Animates a scroll to the right.
  proc animate_scroll_right {w} {

    variable data

    if {$data($w,scroll)} {

      # If we have reached the right-most tab, move over one
      if {[rightmost_tab $w] < [llength $data($w,tab_order)]} {

        # Scroll everything to the right by one tab
        scroll_right $w

        # Move the current tab
        set current_tab [tab_tag $w [page_index $w $data($w,moveto_index)]]
        $w.c move $current_tab $data($w,option,-xscrollincrement) 0

        # Get the tab tag of the tab to evaluate
        set other_index [expr $data($w,moveto_index) + 1]
        set other_tabid [tab_tag $w [page_index $w $other_index]]

        # Move the other tab
        lassign [$w.c coords [string range $other_tabid 1 end]] x0
        $w.c move $other_tabid [expr ($data($w,moveto_index) * $data($w,tab_width)) - $x0] 0

        # Update the order in the tab_order list
        set tmp                   [lindex   $data($w,tab_order) $other_index]
        set data($w,tab_order)    [lreplace $data($w,tab_order) $other_index $other_index]
        set data($w,tab_order)    [linsert  $data($w,tab_order) $data($w,moveto_index) $tmp]
        set data($w,moveto_index) $other_index

      # Otherwise, indicate that we are done scrolling
      } else {
        set data($w,scroll) 0
      }

      # Do this again in 0.5 seconds
      after 500 [list tabbar::animate_scroll_right $w]

    }

  }

  ######################################################################
  # Handles a tabbar leave event.
  proc handle_tabbar_leave {w x y} {

    variable data

    if {($data($w,option,-closeshow) eq "enter") && \
        ($data($w,last_tab) != -1) && \
        (($x <= 0) || ($x >= [winfo width $w.c]) || ($y <= 0) || ($y >= [winfo height $w.c]))} {
      $w.c itemconfigure [close_tag $w [page_index $w $data($w,last_tab)]] -state hidden
      set data($w,last_tab) -1
    }

  }

  ######################################################################
  # Handles any mouse motions in the canvas.
  proc handle_tabbar_motion {w x y} {

    variable data

    if {$data($w,option,-closeshow) eq "enter"} {

      # Get the current tab index
      set tab_index [tab_index $w $x $y]

      if {$tab_index != $data($w,last_tab)} {
        if {$data($w,last_tab) != -1} {
          $w.c itemconfigure [close_tag $w [page_index $w $data($w,last_tab)]] -state hidden
        }
        if {$tab_index != -1} {
          $w.c itemconfigure [close_tag $w [page_index $w $tab_index]] -state normal
        }
        set data($w,last_tab) $tab_index
      }

    }

  }
  
  ######################################################################
  # Handles mousewheel events occurring within the tabbar.
  proc handle_tabbar_mousewheel {w d} {
    
    if {[tk windowingsystem] eq "win32"} {
      set d [expr int( pow( %d / -120, 3))]
    }
    
    if {$d == -1} {
      scroll_right $w
    } else {
      scroll_left $w
    }
    
  }

  ######################################################################
  # Animates busy for the given tab.
  proc animate_busy {w tab bid img_list} {

    variable data

    if {([$w.c gettags $bid] ne "") || ([$w.c gettags [set bid [busy_tag $w [index $w $tab]]]] ne "")} {
      
      # Get the next image to draw and rotate the image list
      set img_list [lassign $img_list img]
      lappend img_list $img

      # Draw the next busy image
      $w.c itemconfigure $bid -image $data($img)

      # Re-animate after a short time
      after 100 [list tabbar::animate_busy $w $tab $bid $img_list]

    }

  }

  ######################################################################
  # Returns the tag for the tab at the given page index.
  proc tab_tag {w page_index} {

    variable data

    return t[lindex $data($w,pages) $page_index 1 0]

  }

  ######################################################################
  # Returns the close tag at the given page index.
  proc close_tag {w page_index} {

    variable data

    return c[lindex $data($w,pages) $page_index 1 0]

  }

  ######################################################################
  # Returns the image tag at the given page index.
  proc image_tag {w page_index} {

    variable data

    return i[lindex $data($w,pages) $page_index 1 0]

  }

  ######################################################################
  # Returns the text tag at the given page index.
  proc text_tag {w page_index} {

    variable data

    return x[lindex $data($w,pages) $page_index 1 0]

  }

  ######################################################################
  # Returns the busy tag at the given page index.
  proc busy_tag {w page_index} {

    variable data

    return bu[lindex $data($w,pages) $page_index 1 0]

  }

  ######################################################################
  # Returns the options for the tab at the given page index.
  proc tab_opts {w page_index} {

    variable data

    return [lindex $data($w,pages) $page_index 1 2]

  }

  ######################################################################
  # Returns the tab_order index from the x,y coordinate.
  proc tab_index {w x y} {

    variable data

    set tab_index [expr ($x / $data($w,tab_width)) + $data($w,left_tab)]

    if {($tab_index >= 0) && ($tab_index < [llength $data($w,tab_order)])} {
      return $tab_index
    } else {
      return -1
    }

  }

  ######################################################################
  # Converts a tab index into a page index.
  proc page_index {w tab_index} {

    variable data

    return [lindex $data($w,tab_order) $tab_index]

  }

  ######################################################################
  # Calculates the left-most tab.
  proc leftmost_tab {w} {

    variable data

    return $data($w,left_tab)

  }

  ######################################################################
  # Returns the right-most tab.
  proc rightmost_tab {w} {

    variable data

    return [expr $data($w,left_tab) + (([winfo width $w.c] / $data($w,tab_width)) - 1)]

  }

  ######################################################################
  # Handles a left click press event on a tab.
  proc handle_tab_left_click_press {w x y} {

    variable data

    # Get the index of the clicked tab
    if {[set tab_index [tab_index $w $x $y]] == -1} {
      return
    }

    # Get the page index
    set page_index [page_index $w $tab_index]

    # Get the close ID
    set close_id [close_tag $w $page_index]

    # If the current item is not the close button
    if {[lsearch [$w.c itemcget current -tags] $close_id] == -1} {

      # Start the move operation
      set data($w,moveto_index) $tab_index
      set data($w,last_x)       $x
      set data($w,moveto_stop)  0
      $w.c raise [tab_tag $w $page_index]

      # Make the current tab look current
      set data($w,last_current) $data($w,current)
      set data($w,current)      $page_index
      redraw $w

    } else {
      set data($w,moveto_index) ""
    }

  }

  ######################################################################
  # Handles a left press motion event of the mouse.
  proc handle_tab_b1_motion {w x y} {

    variable data

    # Get the width of the canvas
    set width [winfo width $w.c]

    # If we no longer have a moveto_index, return immediately
    if {$data($w,moveto_index) eq ""} {
      return
    }

    # Get the page index of the moveto_index
    set page_index [page_index $w $data($w,moveto_index)]

    # Get the tab options of the moveto_index
    array set tab_opts [tab_opts $w $page_index]

    # Get the index of the tab that we are crossing into
    if {(($data($w,last_x) <= 0) && ($x < 0)) || \
        (($data($w,last_x) >= $width) && ($x >= $width)) || \
        ($data($w,moveto_stop) == 1) ||
        ([set other_index [tab_index $w $x $y]] == -1) || \
        !$tab_opts(-movable)} {
      return
    }

    # Get the page index of the other tab
    set other_page_index [page_index $w $other_index]

    # Get the tab options of the other page
    array set other_tab_opts [tab_opts $w $other_page_index]

    # If the other tab is not movable, clear the moveto_index
    # and return immediately
    if {!$other_tab_opts(-movable)} {
      set data($w,moveto_stop) 1
      return
    }

    # Move the current tab
    set current_tab [tab_tag $w $page_index]
    $w.c move $current_tab [expr $x - $data($w,last_x)] 0

    # Move the lower tab
    if {($data($w,moveto_index) ne "") && \
        ((($data($w,moveto_index) > $other_index) && ($x < $data($w,last_x))) || \
         (($data($w,moveto_index) < $other_index) && ($x > $data($w,last_x))))} {

      # Get the tab tag of the tab to evaluate
      set other_tabid [tab_tag $w $other_page_index]

      # Move the other tab
      lassign [$w.c coords [string range $other_tabid 1 end]] x0
      $w.c move $other_tabid [expr ($data($w,moveto_index) * $data($w,tab_width)) - $x0] 0

      # Update the order in the tab_order list
      set tmp                   [lindex   $data($w,tab_order) $other_index]
      set data($w,tab_order)    [lreplace $data($w,tab_order) $other_index $other_index]
      set data($w,tab_order)    [linsert  $data($w,tab_order) $data($w,moveto_index) $tmp]
      set data($w,moveto_index) $other_index
      set data($w,last_current) -1

    }

    # If the tab moved is on the left or right edge of the canvas and more tabs exist, move
    # the canvas over by one unit
    if {$x <= 0} {
      set data($w,scroll) 1
      animate_scroll_left $w
    } elseif {$x >= $width} {
      set data($w,scroll) 1
      animate_scroll_right $w
    } else {
      set data($w,scroll) 0
    }

    # Save the last x value
    set data($w,last_x) $x

  }

  ######################################################################
  # Handles a left click release event on the tab close button.
  proc handle_tab_left_click_release {w x y} {

    variable data

    if {$data($w,moveto_index) eq ""} {

      # Get the page index
      set page_index [index $w @$x,$y]

      # Get the page to delete
      set page [lindex $data($w,pages) $page_index 0]

      # Check to see if the close is okay
      if {$data($w,option,-checkcommand) ne ""} {
        if {![uplevel #0 $data($w,option,-checkcommand) $w $page]} {
          return
        }
      }

      # Delete the tab
      delete $w $page_index

      # Show the close button if the mouse is over a tab
      if {$data($w,option,-closeshow) eq "enter"} {
        if {[set tab_index [tab_index $w $x $y]] != -1} {
          $w.c itemconfigure [close_tag $w [page_index $w $tab_index]] -state normal
        }
        set data($w,last_tab) $tab_index
      }

      # Run the close command if one was specified
      if {$data($w,option,-closecommand) ne ""} {
        uplevel #0 $data($w,option,-closecommand) $w $page
      }

    } else {

      # Get the page index from the moveto_index
      set page_index [page_index $w $data($w,moveto_index)]

      # Set the current tag
      set data($w,current) $data($w,moveto_index)

      # Get the tab tag
      set tab_tag [tab_tag $w $page_index]

      # Move tab to the current position
      lassign [$w.c coords [string range $tab_tag 1 end]] x0
      $w.c move $tab_tag [expr ($data($w,tab_width) * $data($w,moveto_index)) - $x0] 0

      # Move the page in the pages index
      set page           [lindex   $data($w,pages) $page_index]
      set data($w,pages) [lreplace $data($w,pages) $page_index $page_index]
      set data($w,pages) [linsert  $data($w,pages) $data($w,moveto_index) $page]

      # Update the tab order to match
      update_tab_order $w

      # Select the current tab
      set data($w,current) $data($w,last_current)
      select $w $data($w,moveto_index)

      # Clear the moveto_index
      set data($w,moveto_index) ""
      set data($w,moveto_stop)  0

    }

  }

  ######################################################################
  # Creates a new tab in the tab bar at the given position.
  proc add_tab {w index args} {

    variable data
    variable tab_options

    set resizable [list]

    set bg $data($w,option,-background)
    set bc $data($w,option,-bordercolor)

    array set opts [array get tab_options]
    array set opts $args

    set x0 [expr $index * ($data($w,tab_width) + $data($w,option,-margin))]
    set y0 [expr $data($w,option,-height) / 2]
    set x1 [expr $x0 + $data($w,tab_width)]

    # Create the tab rectangle
    switch $data($w,option,-relief) {
      raised {
        set id  [$w.c create rectangle $x0 0 $x1 $data($w,option,-height) -fill white -outline $bc]
        set fid [$w.c create rectangle [expr $x0 + 2] 2 [expr $x1 - 1] $data($w,option,-height) -fill $bg -outline $bg -tags [list t$id f$id]]
      }
      flat {
        set id  [$w.c create rectangle $x0 0 $x1 $data($w,option,-height) -fill $bc -outline $bc]
        set fid [$w.c create rectangle $x0 0 [expr $x1 - 1] $data($w,option,-height) -fill $bg -outline $bg -tags [list t$id f$id]]
      }
    }
    $w.c itemconfigure $id -tags [list tab b$id t$id]

    incr x0  $opts(-padx)
    incr x1 -$opts(-padx)

    # If the tab has a close button, create it now
    set cid ""
    if {$data($w,option,-close) ne ""} {
      if {[set closeimage $data($w,option,-closeimage)] eq ""} {
        set closeimage $data($w,image,close)
      }
      if {$data($w,option,-close) eq "left"} {
        set cid [$w.c create image $x0 $y0 -anchor w -image $closeimage -tags [list t$id c$id]]
        incr x0 [expr [image width $closeimage] + $opts(-padx)]
      } else {
        lappend resizable [set cid [$w.c create image [incr x1 [expr 0 - ([image width $closeimage] + $opts(-padx))]] $y0 -anchor w -image $closeimage -tags [list t$id c$id]]]
        incr x1 -$opts(-padx)
      }
      if {$data($w,option,-closeshow) eq "enter"} {
        $w.c itemconfigure $cid -state hidden
      }
    }

    # If the tab will need to indicate busy, draw it
    if {$opts(-busy)} {
      if {$data($w,option,-busy) eq "left"} {
        $w.c create image $x0 $y0 -anchor w -image $data($w,image,busy1) -tags [list bu$id t$id]
        incr x0 [expr [image width $data($w,image,busy1)] + $opts(-padx)]
      } else {
        lappend resizable [$w.c create image [incr x1 [expr 0 - ([image width $data($w,image,busy1)] + $opts(-padx))]] $y0 -anchor w -image $data($w,image,busy1) -tags [list bu$id t$id]]
        incr x1 -$opts(-padx)
      }
    }

    # Add the text and/or image
    if {($opts(-compound) ne "") && ($opts(-image) ne "")} {
      if {$opts(-compound) eq "left"} {
        $w.c create image [incr x0 $opts(-padx)] $y0 -anchor w -image $opts(-image) -tags [list i$id t$id]
        incr x0 [expr [image width $opts(-image)] + $opts(-padx)]
        lappend resizable [$w.c create text $x1 $y0 -anchor e -text $opts(-text) -fill $data($w,option,-foreground) -tags [list x$id t$id]]
      } else {
        lappend resizable [$w.c create image [incr x1 [expr 0 - ([image width $opts(-image)] + $opts(-padx))]] $y0 -anchor w -image $opts(-image) -tags [list i$id t$id]]
        incr x1 -$opts(-padx)
        lappend resizable [$w.c create text $x1 $y0 -anchor e -text $opts(-text) -fill $data($w,option,-foreground) -tags [list x$id t$id]]
      }
    } elseif {$opts(-image) ne ""} {
      $w.c create image [incr x0 $opts(-padx)] $y0 -anchor w -image $opts(-image) -tags [list i$id t$id]
    } else {
      lappend resizable [$w.c create text $x1 $y0 -anchor e -text $opts(-text) -fill $data($w,option,-foreground) -tags [list x$id t$id]]
    }

    # If we need to emboss the text (and we have text to emboss), do it now
    if {$opts(-emboss) && (($opts(-image) eq "") || ($opts(-compound) ne ""))} {
      # $w.c create text [expr $x1 - 1] [expr $y0 - 1] -anchor e -text $txt -fill black -tags [list et$id t$id]
      lappend resizable [$w.c create text [expr $x1 + 1] [expr $y0 + 1] -anchor e -text $opts(-text) -fill white -tags [list eb$id t$id]]
      $w.c raise x$id
    }

    # Resize the text (if it exists)
    resize_text $w $id [array get opts]

    # Add bindings
    $w.c bind t$id <ButtonPress-1>   "tabbar::handle_tab_left_click_press   $w %x %y"
    $w.c bind t$id <ButtonRelease-1> "tabbar::handle_tab_left_click_release $w %x %y"
    $w.c bind t$id <B1-Motion>       "tabbar::handle_tab_b1_motion          $w %x %y"

    return [list $id $resizable [array get opts]]

  }

  ######################################################################
  # If any of the tabs need to be completely redrawn, do it now.
  proc redraw_tab {w page_index} {

    variable data

    # Get the tab options
    array set opts [tab_opts $w $page_index]

    # Delete all of the tab components
    $w.c delete [tab_tag $w $page_index]

    # Re-add the tab
    if {$opts(-state) ne "hidden"} {
      lset data($w,pages) $page_index 1 [add_tab $w $page_index {*}[tab_opts $w $page_index]]
    }

  }

  ######################################################################
  # Redraws the specified tab when a tab configuration value changes.
  proc redraw_all_tabs {w force} {

    variable data

    # If any global options that should cause the entire canvas to be redrawn is needed, do it now
    for {set page_index 0} {$page_index < [llength $data($w,pages)]} {incr page_index} {
      redraw_tab $w $page_index
    }

    # Do a final redraw
    redraw $w $force

  }

  ######################################################################
  # Checks to see if the tab needs to be redrawn and does it (if needed).
  proc check_tab_for_redraw {w page_index orig_opts_list} {

    array set orig_opts $orig_opts_list
    array set opts      [tab_opts $w $page_index]

    # If we are hiding/unhiding a tab, redraw everything
    if {(($orig_opts(-state) eq "hidden") || ($opts(-state) eq "hidden")) && ($orig_opts(-state) ne $opts(-state))} {
      redraw_all_tabs $w 1
      return
    }

    # If there are any options that changed that require us to redraw ourself, do it now
    foreach opt [list -emboss -compound -image -padx -pady -busy] {
      if {$orig_opts($opt) ne $opts($opt)} {
        redraw_tab $w $page_index
        redraw $w
        return
      }
    }

    set resize_needed 0
    set text_tag      [text_tag $w $page_index]

    # If the text changed, change it
    if {$orig_opts(-text) ne $opts(-text)} {
      $w.c itemconfigure $text_tag -text $opts(-text)
      set resize_needed 1
    }

    # Resize the text, if needed
    if {$resize_needed} {
      resize_text $w [string range $text_tag 1 end] [array get opts]
    }

  }

  ######################################################################
  # Checks the global options for changes that can cause tab redrawing
  # to occur and do it (if necessary).
  proc check_all_for_redraw {w orig_opts_list} {

    variable data

    array set orig_opts $orig_opts_list

    # If any options have changed that will require a complete redraw, do it now
    foreach opt [list -busy -close -closeimage -closeshow -font -state -padx -pady -height -margin -anchor \
                      -activebackground -activeforeground -inactivebackground -inactiveforeground] {
      if {$orig_opts($w,option,$opt) ne $data($w,option,$opt)} {
        redraw_all_tabs $w 0
        return
      }
    }

    if {$orig_opts($w,option,-bordercolor) ne $data($w,option,-bordercolor)} {
      foreach page $data($w,pages) {
        $w.c itemconfigure b[lindex $page 1 0] -outline $data($w,option,-bordercolor)
      }
    }

    if {$orig_opts($w,option,-foreground) ne $data($w,option,-foreground)} {
      foreach page $data($w,pages) {
        # $w.c itemconfigure x[lindex $page 1 0] -fill $data($w,option,-foreground)
        $w.c itemconfigure c[lindex $page 1 0] -image $data($w,image,close)
      }
    }

  }

  ######################################################################
  # Creates a text field that fits within the text space of the given tab.
  proc resize_text {w tabid opts_list} {

    variable data

    if {[$w.c gettags [set tid x$tabid]] ne ""} {

      array set opts $opts_list

      # Figure out how much space we have for the text
      set text_width [expr $data($w,tab_width) - ($opts(-padx) * 2)]
      foreach tag [$w.c find withtag t$tabid] {
        switch [$w.c type $tag] {
          "image" {
            incr text_width [expr 0 - ([image width [$w.c itemcget $tag -image]] + 1 + $opts(-padx))]
            incr negatives
          }
        }
      }

      # Resize the text
      $w.c itemconfigure $tid -text $opts(-text)
      lassign [$w.c bbox $tid] x0 y0 x1 y1

      # If the text exceeds the available test area, snip the text
      if {($x1 - $x0) > $text_width} {
        $w.c insert $tid end "..."
        while {(($x1 - $x0) > $text_width) && ([$w.c itemcget $tid -text] ne "...")} {
          $w.c dchars $tid [expr [string length [$w.c itemcget $tid -text]] - 4]
          lassign [$w.c bbox $tid] x0 y0 x1 y1
        }
        if {[$w.c itemcget $tid -text] eq "..."} {
          $w.c itemconfigure $tid -text ""
        }
      }

      # If we have an embossed element, resize its text as well
      if {$opts(-emboss)} {
        $w.c itemconfigure eb$tabid -text [$w.c itemcget $tid -text]
      }

    }

  }

  ######################################################################
  # Update the tab order to match the shown tabs.
  proc update_tab_order {w} {

    variable data

    set data($w,tab_order) [list]

    set i 0
    foreach page $data($w,pages) {
      array set opts [lindex $page 1 2]
      if {$opts(-state) ne "hidden"} {
        lappend data($w,tab_order) $i
      }
      incr i
    }

  }

  ######################################################################
  # Updates the state of the shift buttons to match the current drawn
  # state of the widget.
  proc update_shift_button_state {w} {

    variable data

    # Set the left-most tab and if it set to 0, disable this button
    if {[leftmost_tab $w] == 0} {
      $w.sl configure -state disabled
    } else {
      $w.sl configure -state normal
    }

    # If the number of tabs shown in the current view
    if {[rightmost_tab $w] >= [expr [llength $data($w,tab_order)] - 1]} {
      $w.sr configure -state disabled
    } else {
      $w.sr configure -state normal
    }

  }

  ######################################################################
  # Redraw the tabbar.
  proc redraw {w {force 0}} {

    variable data

    # Get the current width of the tabbar
    set nb_width [winfo width $w]

    # Get the current width of the tabs
    set tab_width $data($w,tab_width)

    # Get the number of tabs to display
    set num_tabs [llength $data($w,tab_order)]

    # Set the tab width to the desired value
    set data($w,tab_width) [expr $nb_width / (($num_tabs == 0) ? 1 : $num_tabs)]

    # If the tabs can be larger than the maximum width, set their size to the maximum size
    if {($data($w,option,-maxtabwidth) > 0) && ($data($w,tab_width) > $data($w,option,-maxtabwidth))} {
      set data($w,tab_width) $data($w,option,-maxtabwidth)

    # If the tab becomes smaller than the minimum width, set it to the minimum value
    } elseif {$data($w,tab_width) < $data($w,option,-mintabwidth)} {
      set data($w,tab_width) $data($w,option,-mintabwidth)
    }

    # If the tab widths changed, resize all of the tabs
    if {($tab_width != $data($w,tab_width)) || $force} {

      for {set i [expr [llength $data($w,tab_order)] - 1]} {$i >= 0} {incr i -1} {

        # Get the current page
        set page [lindex $data($w,pages) [lindex $data($w,tab_order) $i]]

        # Adjust the size of the tab box
        set tabid [lindex $page 1 0]
        lassign [$w.c coords $tabid] tx0 ty0 tx1 ty1
        switch $data($w,option,-relief) {
          raised {
            $w.c coords $tabid $tx0 $ty0 [expr $tx0 + $data($w,tab_width)] $ty1
            $w.c coords f$tabid [expr $tx0 + 2] [expr $ty0 + 2] [expr ($tx0 + $data($w,tab_width)) - 1] $ty1
          }
          flat {
            $w.c coords $tabid $tx0 $ty0 [expr $tx0 + $data($w,tab_width)] $ty1
            $w.c coords f$tabid [expr $tx0 + 1] $ty0 [expr ($tx0 + $data($w,tab_width)) - 1] $ty1
          }
        }

        # Figure out how much we need to move in the x direction
        set xamount [expr $data($w,tab_width) - $tab_width]

        # Move the resizable components of the tab
        foreach resizable [lindex $page 1 1] {
          $w.c move $resizable $xamount 0
        }

        # Adjust the text
        resize_text $w $tabid [lindex $page 1 2]

        # Move the tab to its proper position
        $w.c move t$tabid [expr ($i * ($data($w,tab_width) + $data($w,option,-margin))) - $tx0] 0

      }

    }

    # Display the tabs so that they represent the current state (if the current state has changed)
    foreach page_index $data($w,tab_order) {
      set tabid [lindex $data($w,pages) $page_index 1 0]
      $w.c itemconfigure c$tabid -image $data($w,image,close)
      array set opts [lindex $data($w,pages) $page_index 1 2]
      if {$page_index == $data($w,current)} {
        $w.c itemconfigure f$tabid -fill $data($w,option,-activebackground) -outline $data($w,option,-activebackground)
        $w.c itemconfigure x$tabid -fill $data($w,option,-activeforeground)
        if {$data($w,option,-closeshow) eq "current"} {
          $w.c itemconfigure c$tabid -state normal
        }
      } else {
        $w.c itemconfigure f$tabid -fill $data($w,option,-inactivebackground) -outline $data($w,option,-inactivebackground)
        $w.c itemconfigure x$tabid -fill $data($w,option,-inactiveforeground)
        if {$data($w,option,-closeshow) eq "current"} {
          $w.c itemconfigure c$tabid -state hidden
        }
      }
    }

    # If the tab bar exceeds the width of the canvas, add the scroll buttons
    if {($data($w,tab_width) * [llength $data($w,tab_order)]) > $nb_width } {

      # Check to see if the shift buttons are not mapped yet
      set gen_event [expr ![winfo ismapped $w.sl]]

      # Display the shift left/right buttons
      grid $w.sl
      grid $w.sr

      if {$data($w,left_tab) > 0} {

        # Make sure that the left tab is set
        set tabs_displayable [expr $nb_width / $data($w,tab_width)]
        set shift_right      [expr ([llength $data($w,tab_order)] - $data($w,left_tab)) - $tabs_displayable]

        # If a left shift is required set the left_tab and move the canvas
        if {$shift_right < 0} {
          incr data($w,left_tab) $shift_right
          $w.c xview scroll $shift_right units
        }

      }

      # Update the state of the shift buttons
      update_shift_button_state $w

      # Generate event (if necessary)
      if {$gen_event} {
        event generate $w <<TabbarScrollEnabled>>
      }

    # Otherwise, if the scroll buttons are visible, remove them
    } else {

      # Check to see if the shift buttons are currently mapped
      set gen_event [winfo ismapped $w.sl]

      # Remove the shift buttons from the view
      grid remove $w.sl
      grid remove $w.sr

      # Make sure that we are left-aligned
      if {[set shift_left $data($w,left_tab)] > 0} {
        set data($w,left_tab) 0
        $w.c xview scroll [expr 0 - $shift_left] units
      }

      # Generate event
      if {$gen_event} {
        event generate $w <<TabbarScrollDisabled>>
      }

    }

  }

  ######################################################################
  # Make the current tab viewable if it currently is not.
  proc make_current_viewable {w} {

    variable data

    # If the current tab is unknown, don't do anything
    if {$data($w,current) == -1} {
      return
    }

    # If the current tab is to the left of the left-most tab, scroll
    # the canvas to the right until the current tab is in view.
    if {$data($w,current) < [set left_tab [leftmost_tab $w]]} {

      # Scroll to the new position
      $w.c xview scroll [set shift [expr $data($w,current) - $left_tab]] units

      # Adjust the left tab
      incr data($w,left_tab) $shift

      # Update the button state
      update_shift_button_state $w

    # If the current tab is to the right of the right-most tab, scroll
    # the canvas to the left until the current tab is in view.
    } elseif {$data($w,current) > [set right_tab [rightmost_tab $w]]} {

      # Scroll to the new position
      $w.c xview scroll [set shift [expr $data($w,current) - $right_tab]] units

      # Adjust the left tab
      incr data($w,left_tab) $shift

      # Update the button state
      update_shift_button_state $w

    }

  }

  ######################################################################
  # When a tab is going to be deleted or is being hidden, the tab is
  # scrubbed from the history list.
  proc clean_history {w first_index last_index} {

    variable data

    if {$data($w,option,-history)} {
      for {set i $first_index} {$i <= $last_index} {incr i} {
        foreach hindex [lreverse [lsearch -all $data($w,history) [lindex $data($w,pages) $i 0]]] {
          set data($w,history) [lreplace $data($w,history) $hindex $hindex]
        }
      }
    }

  }

  ######################################################################
  # In the event that we lose the current tab, this procedure will be
  # called to set the current tab to a new value based on history or a
  # default.
  proc set_current {w} {

    variable data

    # If we are storing tab history, get the previously current tab
    if {$data($w,option,-history) && ([llength $data($w,history)] > 0)} {

      set data($w,current) [lsearch -index 0 $data($w,pages) [lindex $data($w,history) end]]

    # If we were unable to find a tab from history, use the tab previous
    # to the current one
    } else {

      for {set i [expr $data($w,current) - 1]} {$i >= 0} {incr i -1} {
        array set opts [lindex $data($w,pages) $i 1 2]
        if {$opts(-state) ne "hidden"} {
          set data($w,current) $i
          return
        }
      }

      for {set i $data($w,current)} {$i < [llength $data($w,pages)]} {incr i} {
        array set opts [lindex $data($w,pages) $i 1 2]
        if {$opts(-state) ne "hidden"} {
          set data($w,current) $i
          return
        }
      }

      set data($w,current) -1

    }

  }

  ######################################################################
  # Handles all commands associated with this widget.
  proc widget_cmd {w args} {

    if {[llength $args] == 0} {
      return -code error "tabbar widget called without a command"
    }

    set cmd  [lindex $args 0]
    set opts [lrange $args 1 end]

    switch $cmd {
      btag       { return [tabbar::btag $w {*}$opts] }
      cget       { return [tabbar::cget $w {*}$opts] }
      configure  { return [tabbar::configure 0 $w {*}$opts] }
      delete     { tabbar::delete $w {*}$opts }
      index      { return [tabbar::index $w {*}$opts] }
      insert     { return [tabbar::insert $w {*}$opts] }
      scrolled   { return [tabbar::scrolled $w {*}$opts] }
      scrollpath { return [tabbar::scrollpath $w {*}$opts] }
      select     { tabbar::select $w {*}$opts }
      tab        { return [tabbar::tab $w {*}$opts] }
      tabs       { return [tabbar::tabs $w {*}$opts] }
      xview      { return [tabbar::xview $w {*}$opts] }
      default    { return -code error "Unknown tabbar command ($cmd)" }
    }

  }

  ######################################################################
  # Main configuration routine.
  proc configure {initialize w args} {

    variable data
    variable widget_options

    if {([llength $args] == 0) && !$initialize} {

      set results [list]

      foreach opt [lsort [array names widget_options]] {
        if {[llength $widget_options($opt)] == 2} {
          set opt_name    [lindex $widget_options($opt) 0]
          set opt_class   [lindex $widget_options($opt) 1]
          set opt_default [option get $w $opt_name $opt_class]
          if {[info exists data($w,option,$opt)]} {
            lappend results [list $opt $opt_name $opt_class $opt_default $data($w,option,$opt)]
          } else {
            lappend results [list $opt $opt_name $opt_class $opt_default ""]
          }
        }
      }

      return $results

    } elseif {([llength $args] == 1) && !$initialize} {

      set opt [lindex $args 0]

      if {[info exists widget_options($opt)]} {
        if {[llength $widget_options($opt)] == 1} {
          set opt [lindex $widget_options($opt) 0]
        }
        set opt_name    [lindex $widget_options($opt) 0]
        set opt_class   [lindex $widget_options($opt) 1]
        set opt_default [option get $w $opt_name $opt_class]
        if {[info exists data($w,option,$opt)]} {
          return [list $opt $opt_name $opt_class $opt_default $data($w,option,$opt)]
        } else {
          return [list $opt $opt_name $opt_class $opt_default ""]
        }
      }

      return -code error "tabbar::configuration option [lindex $args 0] does not exist"

    } else {

      # Save the original contents
      array set orig_options [array get data $w,option,*]

      # Parse the arguments
      foreach {name value} $args {
        if {[info exists data($w,option,$name)]} {
          set data($w,option,$name) $value
        } else {
          return -code error "Illegal option given to the tabbar::configure command ($name)"
        }
      }

      # If the foreground has changed, update the images
      if {$orig_options($w,option,-foreground) ne $data($w,option,-foreground)} {
        foreach name [array names data $w,image,*] {
          $data($name) configure -foreground $data($w,option,-foreground)
        }
      }

      # Update the GUI widgets
      $w    configure -width $data($w,option,-width) -height $data($w,option,-height) -relief $data($w,option,-relief)
      $w.c  configure -bg $data($w,option,-background) -xscrollincrement $data($w,option,-xscrollincrement) \
        -height $data($w,option,-height)
      $w.sl configure -bg $data($w,option,-background) -fg $data($w,option,-foreground) -relief flat \
        -disabledforeground $data($w,option,-disabledforeground)
      $w.sr configure -bg $data($w,option,-background) -fg $data($w,option,-foreground) -relief flat \
        -disabledforeground $data($w,option,-disabledforeground)

      # Check the options for redraw candidates
      check_all_for_redraw $w [array get orig_options]

      # Redraw the widget to match the new configuration
      redraw $w

    }

  }

  ######################################################################
  # Gets configuration option value(s).
  proc cget {w args} {

    variable data

    # Verify the argument list is valid
    if {[llength $args] != 1} {
      return -code error "Incorrect number of parameters given to the tabbar::cget command"
    }

    if {[info exists data($w,option,[lindex $args 0])]} {
      return $data($w,option,[lindex $args 0])
    } else {
      return -code error "Illegal options given to the tabbar::cget command ([lindex $args 0])"
    }

  }

  ######################################################################
  # Returns the name of the tabbar tag.
  proc btag {w} {

    variable data

    return $data($w,tags,canvas)

  }

  ######################################################################
  # Allows the user to get or set tab options.
  proc tab {w args} {

    variable data
    variable tab_options

    if {[llength $args] < 2} {
      return -code error "Incorrect number of parameters given to the tabbar::tab command"
    }

    set index [index $w [lindex $args 0]]

    # Get the page based on the index
    if {($index >= 0) && ($index < [llength $data($w,pages)])} {
      set page [lindex $data($w,pages) $index]
    } else {
      return ""
    }

    if {[llength $args] == 2} {

      array set opts [lindex $page 1 2]
      if {[info exists opts([lindex $args 1])]} {
        return $opts([lindex $args 1])
      } else {
        return ""
      }

    } else {

      # Write the tab options
      array set opts [set orig_opts [lindex $page 1 2]]
      foreach {opt value} [lrange $args 1 end] {
        if {[info exists tab_options($opt)]} {
          set opts($opt) $value
        }
      }
      lset data($w,pages) $index 1 2 [array get opts]

      # If we are changing the state to hidden, clean up the history and
      # change the current tab (if the specified index is the current tab)
      array set oopts $orig_opts
      if {($opts(-state) eq "hidden") && ($oopts(-state) ne "hidden")} {
        clean_history $w $index $index
        if {$index == $data($w,current)} {
          set_current $w
        }
      }

      # Update the tab order
      update_tab_order $w

      # Redraw the tab in the canvas if needed
      check_tab_for_redraw $w $index $orig_opts

      # Make sure that the tab is in view
      make_current_viewable $w

      # If -busy was set when it previously was not set, start the tab's busy animation
      if {$opts(-busy) && !$oopts(-busy)} {
        animate_busy $w [lindex $data($w,pages) $index 0] [busy_tag $w $index] [lsort -dictionary [array names data $w,image,busy*]]
      }

    }

  }

  ######################################################################
  # Returns the pages contained in the tabbar.
  proc tabs {w args} {

    variable data

    set pages [list]

    switch [llength $args] {
      0 {
        foreach page $data($w,pages) {
          lappend pages [lindex $page 0]
        }
        return $pages
      }
      1 {
        if {[lindex $args 0] eq "-shown"} {
          foreach page $data($w,pages) {
            array set opts [lindex $page 1 2]
            if {$opts(-state) ne "hidden"} {
              lappend pages [lindex $page 0]
            }
          }
          return $pages
        }
      }
    }

    return -code error "Incorrect parameters given to the tabbar::tabs command"

  }

  ######################################################################
  # Returns the numerical index given the index value.
  proc index {w args} {

    variable data

    # Verify the arguments
    if {[llength $args] != 1} {
      return -code error "Incorrect number of parameters given to the tabbar::index command"
    }

    set tabid [lindex $args 0]

    if {[string is integer $tabid]} {
      return $tabid
    } elseif {$tabid eq "end"} {
      return [llength $data($w,pages)]
    } elseif {$tabid eq "current"} {
      return $data($w,current)
    } elseif {$tabid eq "last"} {
      return [lsearch -index 0 $data($w,pages) [lindex $data($w,history) end]]
    } elseif {[winfo exists $tabid]} {
      return [lsearch -index 0 $data($w,pages) $tabid]
    } elseif {[regexp {^@(\d+),(\d+)$} $tabid -> x y]} {
      if {[set tab_index [tab_index $w $x $y]] == -1} {
        return -1
      } else {
        return [lindex $data($w,tab_order) $tab_index]
      }
    } else {
      return -1
    }

  }

  ######################################################################
  # Inserts a new tab at the given index.
  proc insert {w args} {

    variable data

    # Verify the arguments values
    if {[llength $args] < 2} {
      return -code error "Incorrect number of parameters given to the tabbar::insert command"
    }

    set index [lindex $args 0]
    set page  [lindex $args 1]
    set opts  [lrange $args 2 end]

    # Adjust the index
    if {$index eq "end"} {
      set index [llength $data($w,pages)]
    } else {
      set index [index $w $index]
    }

    # Figure out if the tab will become the current tab or not
    set make_current [expr [llength $data($w,pages)] == 0]

    # Insert the tab into the given set of pages
    set data($w,pages) [linsert $data($w,pages) $index [list $page [add_tab $w $index {*}$opts]]]

    # Make the currently added tab the current tab
    if {$make_current} {
      set data($w,current) $index
    } elseif {$index <= $data($w,current)} {
      incr data($w,current)
    }

    # Update the tab order
    update_tab_order $w

    # Draw the tab in the canvas
    redraw $w 1

    if {$make_current} {

      # Make sure that the tab is in view
      make_current_viewable $w

    }

  }

  ######################################################################
  # Deletes a tab at the given index.
  proc delete {w args} {

    variable data

    switch [llength $args] {

      1 {

        # Get the index of the tab to remove
        set index [index $w [lindex $args 0]]

        # Clean up the history buffer
        clean_history $w $index $index

        # Delete the tab from the canvas
        $w.c delete t[lindex $data($w,pages) $index 1 0]

        # If we are deleting the last_tab, clear it
        if {$index < $data($w,last_tab)} {
          incr data($w,last_tab) -1
        } elseif {$index == $data($w,last_tab)} {
          set data($w,last_tab) -1
        }

        # Delete the page from the list
        set data($w,pages) [lreplace $data($w,pages) $index $index]

        # If current was deleted, reassign current
        if {$index == $data($w,current)} {
          set_current $w

        # Otherwise, if we deleted tabs before current, decrement current
        } elseif {$index < $data($w,current)} {
          incr data($w,current) -1
        }

        # Update the tab order
        update_tab_order $w

        # Redraw the tabbar
        redraw $w 1

        # Make sure that the tab is in view
        make_current_viewable $w

      }

      2 {

        # Get the index range of the tabs to remove
        set first_index [index $w [lindex $args 0]]
        set last_index  [index $w [lindex $args 1]]

        # Clean up the history buffer
        clean_history $w $first_index $last_index

        # Delete the tabs from the canvas
        for {set i $first_index} {$i <= $last_index} {incr i} {

          $w.c delete t[lindex $data($w,pages) $i 1 0]

          # If we are deleting the last_tab, clear it
          if {$index < $data($w,last_tab)} {
            incr data($w,last_tab) -1
          } elseif {$index == $data($w,last_tab)} {
            set data($w,last_tab) -1
          }

        }

        # Delete the pages from the list
        set data($w,pages) [lreplace $data($w,pages) $first_index $last_index]

        # If current was deleted, reassign current
        if {($first_index <= $data($w,current)) && ($data($w,current) <= $last_index)} {
          set_current $w

        # Otherwise, if we deleted tabs before current, decrement current
        } elseif {$first_index < $data($w,current)} {
          set data($w,current) [expr $data($w,current) - (($last_index - $first_index) + 1)]
        }

        # Update the tab order
        update_tab_order $w

        # Redraw the tabbar
        redraw $w 1

        # Make sure that the tab is in view
        make_current_viewable $w

      }

      default {
        return -code error "Incorrect number of parameters given to the tabbar::delete command"
      }

    }

  }

  ######################################################################
  # Returns true if the widget is currently in the scrolled state; otherwise,
  # returns false.
  proc scrolled {w args} {

    return [expr [lsearch [grid slaves $w] $w.sl] != -1]

  }

  ######################################################################
  # Selects a tab (making it the new current tab)
  proc select {w args} {

    variable data

    # Verify the arguments
    switch [llength $args] {

      0 {
        return [expr {($data($w,current) == -1) ? "" : [lindex $data($w,pages) $data($w,current) 0]}]
      }

      1 {

        # Get the specified index
        set index [index $w [lindex $args 0]]

        # Set the current tab if it has changed
        if {$index != $data($w,current)} {

          # If we are recording history, update it now
          if {$data($w,option,-history) && ($index != -1)} {
            lappend data($w,history) [lindex $data($w,pages) $data($w,current) 0]

          # Otherwise, just save the last page to history
          } else {
            set data($w,history) [lindex $data($w,pages) $data($w,current) 0]
          }

          # Set the current index
          set data($w,current) $index

          # Update the tabbar
          redraw $w

          # Make sure that the tab is in view
          make_current_viewable $w

          # If the user has specified a command to run for the selection, run it now
          if {$data($w,option,-command) ne ""} {
            uplevel #0 $data($w,option,-command) $w [lindex $data($w,pages) $index 0]
          }

        # Otherwise, make the selected tab viewable
        } else {

          make_current_viewable $w

        }

      }

      default {
        return -code error "Incorrect number of parameter given to the tabbar::select command"
      }

    }

  }

  ######################################################################
  # Returns xview information of the tabbar and allows the xview to be
  # manipulated by the user.
  proc xview {w args} {

    variable data

    switch [llength $args] {

      0 {
        return [$w.c xview]
      }

      default {
        set args [lassign $args subcmd]
        if {$subcmd eq "scroll"} {
          if {[llength $args] != 1} {
            return -code error "Incorrect number of parameters given to the tabbar::xview scroll command"
          }
          set units [lindex $args 0]
          if {$units < 0} {
            for {set i 0} {$i < [expr abs($units)]} {incr i} {
              scroll_left $w
            }
          } else {
            for {set i 0} {$i < $units} {incr i} {
              scroll_right $w
            }
          }
        } elseif {$subcmd eq "shown"} {
          return [list [leftmost_tab $w] [rightmost_tab $w]]
        } else {
          return -code error "Incorrect number of parameters given to the tabbar::xivew command"
        }
      }

    }

  }

  ######################################################################
  # Returns the path of the left or right scroll widget.
  proc scrollpath {w args} {

    # Verify the arguments values
    if {[llength $args] != 1} {
      return -code error "Incorrect number of parameters given to the tabbar::scrollpath command"
    }

    set type [lindex $args 0]

    switch $type {
      "left"  { return $w.sl }
      "right" { return $w.sr }
    }

    return -code error "Bad argument value sent to tabbar::scrollpath command ($type)"

  }

}
