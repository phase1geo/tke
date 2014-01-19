#===============================================================
# Main carousel package module
#
# Copyright (c) 2011-2012  Trevor Williams (phase1geo@gmail.com)
#===============================================================

package provide carousel 1.2

# Load the image_scale or resize command
load [file join [carousel::DIR] src ptwidgets12.dll] ptimage

namespace eval carousel {

  source [file join [carousel::DIR] common stacktrace.tcl]
  
  array set data {}
  
  array set widget_options {
    -animate                {animate                Animate}
    -background             {background             Background}
    -bg                     -background
    -borderwidth            {borderWidth            BorderWidth}
    -bd                     -borderwidth
    -cursor                 {cursor                 Cursor}
    -height                 {height                 Height}
    -padx                   {padX                   Pad}
    -pady                   {padY                   Pad}
    -perspective            {perspective            Perspective}
    -reflect                {reflect                Reflect}
    -reflectblur            {reflectBlur            ReflectBlur}
    -relief                 {relief                 Relief}
    -state                  {state                  State}
    -takefocus              {takeFocus              TakeFocus}
    -width                  {width                  Width}
    -xscrollcommand         {xScrollCommand         ScrollCommand}
  }
  
  array set image_options {
    -state         {}
    -image         {}
  }
  
  array set rectangle_options {
    -ratio                  1.0
    -dash                   {}
    -dashoffset             0
    -fill                   {}
    -offset                 0,0
    -outline                black
    -outlineoffset          0,0
    -outlinestipple         {}
    -stipple                {}
    -state                  {}
    -width                  1.0
  }
  
  array set oval_options {
    -ratio                  1.0
    -dash                   {}
    -dashoffset             0
    -fill                   {}
    -offset                 0,0
    -outline                black
    -outlineoffset          0,0
    -outlinestipple         {}
    -stipple                {}
    -state                  {}
    -width                  1.0
  }

  ###########################################################################
  # Main procedure which creates the given window and initializes it.
  proc carousel {w args} {

    variable data
    variable widget_options
    
    # The widget will be a frame
    frame $w -class Carousel -takefocus 0
    
    # Initially, we pack the frame with a canvas widget
    canvas $w.c -highlightthickness 0 -relief flat -bg white -takefocus 1

    # Pack the text widget
    grid rowconfigure    $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid $w.c -row 0 -column 0 -sticky news

    # If the carousel namespace hasn't been accessed, initialize some constants
    if {[array size data] == 0} {
    
      # Add default option values
      option add *Carousel.animate        "1"      widgetDefault
      option add *Carousel.reflect        "0.2"    widgetDefault
      option add *Carousel.reflectBlur    "0.5"    widgetDefault
      option add *Carousel.background     "black"  widgetDefault
      option add *Carousel.height         "200"    widgetDefault
      option add *Carousel.width          "400"    widgetDefault
      option add *Carousel.padX           "20"     widgetDefault
      option add *Carousel.padY           "20"     widgetDefault
      option add *Carousel.xScrollCommand ""       widgetDefault
      option add *Carousel.cursor         ""       widgetDefault
      option add *Carousel.perspective    "0"      widgetDefault
      option add *Carousel.relief         "flat"   widgetDefault
      option add *Carousel.state          "normal" widgetDefault
      option add *Carousel.takeFocus      "1"      widgetDefault
      
      # Compile some regular expressions for performance purposes
      set data(endmd) {^end\-([-+]?\d+)$}
      set data(endpd) {^end\+([-+]?\d+)$}
      set data(dpd)   {^([-+]?\d+)\+([-+]?\d+)$}
      set data(dmd)   {^([-+]?\d+)\-([-+]?\d+)$}
      set data(xy)    {^@(\d+),(\d+)$}
      set data(tag)   {^_carousel_(\d+)$}
      
    }
    
    # Initialize variables
    set data($w,current) -1
    set data($w,items)   [list]
    
    # Initialize the options array
    foreach opt [array names widget_options] {
      set data($w,options,$opt) [option get $w [lindex $widget_options($opt) 0] [lindex $widget_options($opt) 1]]
    }
    
    # Setup bindings
    bind $w.c <Configure> {
      [winfo parent %W] configure -width [winfo width %W] -height [winfo height %W]
    }
    bind $w <Destroy> {
      carousel::deallocate %W
    }
    bind $w <FocusIn> {
      focus %W.c
    }
    bind $w <Tab> {
      tk_focusNext %W
    }
    bind $w.c <Right> {
      [winfo parent %W] xview scroll 1 units
    }
    bind $w.c <Left> {
      [winfo parent %W] xview scroll -1 units
    }
    bind $w.c <Shift-Right> {
      [winfo parent %W] xview scroll 1 pages
    }
    bind $w.c <Shift-Left> {
      [winfo parent %W] xview scroll -1 pages
    }
    bind $w.c <Home> {
      carousel::set_current [winfo parent %W] 0 0
    }
    bind $w.c <End> {
      carousel::set_current [winfo parent %W] [carousel::getindex [winfo parent %W] end] 0
    }
    bind $w.c <MouseWheel> {
      [winfo parent %W] xview scroll [expr {-%D/120}] units
    }
    bind $w.c <Shift-MouseWheel> {
      [winfo parent %W] xview scroll [expr {-%D/120}] pages
    }
    bind $w.c <Button-4> {
      [winfo parent %W] xview scroll -1 units
    }
    bind $w.c <Button-5> {
      [winfo parent %W] xview scroll 1 units
    }
    bind $w.c <Shift-Button-4> {
      [winfo parent %W] xview scroll -1 pages
    }
    bind $w.c <Shift-Button-5> {
      [winfo parent %W] xview scroll 1 pages
    }
    
    # Configure the widget
    eval "configure 1 $w $args"

    # Rename and alias the tokenentry window
    rename ::$w $w
    interp alias {} ::$w {} carousel::widget_cmd $w

    return $w

  }
  
  ###########################################################################
  # Deallocates all memory associated with this widget.
  proc deallocate {w} {
  
    variable data
    
    # Deallocate images
    foreach name [array names data $w,image*] {
      image delete $data($name)
    }
    
    # Unset all variables associated with this widget
    array unset data $w,*
  
  }
  
  ###########################################################################
  # Returns the width of the current item.
  proc get_current_width {w} {
  
    variable data
    
    set height $data($w,options,-height)
    set pady   $data($w,options,-pady)

    # Calculate the current icons width
    set width [expr $height - ($pady * 2)]
    
    return [expr ($width < 0) ? 0 : $width]
  
  }
  
  ###########################################################################
  # Returns the width of the other items in view.
  proc get_other_width {w} {
  
    return [expr [get_current_width $w] / 2]
  
  }
  
  ###########################################################################
  # Returns the X padding.
  proc get_padx {w} {
  
    set padx [expr int([get_other_width $w] * 0.25)]
    
    return [expr ($padx == 0) ? 1 : $padx]
  
  }
  
  ###########################################################################
  # Returns the number of items to display.
  proc get_displayed_items {w} {
  
    variable data
    
    set padx         [get_padx $w]
    set half_total   [expr $data($w,options,-width) / 2]
    set half_current [expr ([get_current_width $w] / 2) + $padx]
    set half_other   [expr ($half_total - $half_current) / $padx]
    
    return [expr ($half_other * 2) + 1]
  
  }

  ###########################################################################
  # Returns the angle of the image in radians.
  proc get_image_angle {w image_x image_y} {
  
    variable data
    
    set oth [expr abs(($data($w,options,-height) / 2) - $image_y)]
    set adj [expr abs(($data($w,options,-width)  / 2) - $image_x)]
    
    return [expr atan2( $oth, $adj )]
  
  }
  
  ###########################################################################
  # Returns the width of the item when viewed in perspective mode.
  proc get_perspective_width {w x y width} {
  
    return [expr int( $width * cos( [get_image_angle $w $x $y] ) )]
  
  }
  
  ###########################################################################
  # Returns the x,y points for the given perspective pairs.
  proc get_perspective_points {w x y width height anchor} {
    
    set angle [get_image_angle $w $x $y]
    set width [expr int( $width * cos($angle) )]
    
    if {$anchor eq "sw"} {
      set x2   $x
      set y2   $y
      set x3   [expr $x + $width]
      set y3   [expr $y - int( sin($angle) * $width )]
      set x0   $x
      set y0   [expr $y2 - $height]
      set x1   [expr $x + $width]
      set y1   [expr $y3 - $height]
      set yadj [expr $y0 - $y1]
    } else {
      set x2   [expr $x - $width]
      set y2   [expr $y - int( sin($angle) * $width )]
      set x3   $x
      set y3   $y
      set x0   $x2
      set y0   [expr $y2 - $height]
      set x1   $x
      set y1   [expr $y - $height]
      set yadj [expr $y1 - $y0]
    }
    
    return [list $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3 $yadj]
    
  }
  
  ###########################################################################
  # Scales the image to the given height and width.
  proc scale_image {w img x y width name reflect anchor pyadj} {
  
    upvar $pyadj yadj
    
    variable data
    
    set old_width  [image width $img]
    set old_height [image height $img]
    
    if {$old_width < $old_height} {
      set height $width
      set width  [expr int( ($old_width / $old_height.0) * $width )]
    } else {
      set height [expr int( ($old_height / $old_width.0) * $width )]
    }
    
    # Create and save the image
    if {![info exists data($name)] || ($width != [image width $data($name)])} {
      if {[info exists data($name)]} {
        image delete $data($name)
      }
      set data($name) [image create photo]
      if {$data($w,options,-perspective) && ($anchor ne "s")} {
        lassign [get_perspective_points $w $x $y $width $height $anchor] x0 y0 x1 y1 x2 y2 x3 y3 yadj
        if {$reflect > 0} {
          set img2 [image create photo]
          image_scale $img $old_width $old_height $img2 1 $data($w,options,-background) $reflect
          image_transform $img2 $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3 $data($name) 0
          image delete $img2
          if {$data($w,options,-reflectblur) > 0} {
            effect::blur $data($name) $data($w,options,-reflectblur)
          }
        } else {
          image_transform $img $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3 $data($name) 0
        }
      } else {
        if {$reflect > 0} {
          image_scale $img $width $height $data($name) 1 $data($w,options,-background) $reflect
          if {$data($w,options,-reflectblur) > 0} {
            effect::blur $data($name) $data($w,options,-reflectblur)
          }
        } else {
          image_scale $img $width $height $data($name) 0
        }
      }
    }
        
    return $data($name)
  
  }
  
  ###########################################################################
  # Calculates the reflection color for the given color.
  proc get_reflection_color {w color} {
  
    variable data
  
    set reflect $data($w,options,-reflect)
    
    foreach {br bg bb} [winfo rgb $w.c $data($w,options,-background)] {break}
    foreach {nr ng nb} [winfo rgb $w.c $color] {break}
    
    set r [expr int(($nr < $br) ? ($br - (($br - $nr) * $reflect)) : ($br + (($nr - $br) * $reflect)))]
    set g [expr int(($ng < $bg) ? ($bg - (($bg - $ng) * $reflect)) : ($bg + (($ng - $bg) * $reflect)))]
    set b [expr int(($nb < $bb) ? ($bb - (($bb - $nb) * $reflect)) : ($bb + (($nb - $bb) * $reflect)))]
    
    return [format "#%04x%04x%04x" $r $g $b]
    
  }

  ###########################################################################
  # Creates the item at the given index and returns its canvas ID.
  proc draw_item {w index x y size anchor} {
  
    variable data
    
    set item [lindex $data($w,items) $index]
    set type [lindex $item 0]
    
    array set opts [lindex $item 1]
    
    if {$opts(-state) ne "hidden"} {
    
      # Add a tag for this item
      set opts(-tags) "_carousel_$index"
      
      # Make the state normal
      set opts(-state) "normal"
      
      # Get the reflection value
      set reflect $data($w,options,-reflect)

      # Set default for the y-adjust value
      set yadj 0
    
      # Create the new item
      switch $type {
        image {
          set img $opts(-image)
          if {$reflect > 0} {
            set key "$w,image[expr $data($w,current) == $index]1,$opts(-image)"
            set opts(-image) [scale_image $w $img $x $y $size $key $reflect $anchor yadj]
            set id [$w.c create $type $x [expr ($y - $yadj) + 1] -anchor [string map {s n} $anchor] {*}[array get opts]]
            $w.c lower $id
          }
          set key "$w,image[expr $data($w,current) == $index]0,$opts(-image)"
          set opts(-image) [scale_image $w $img $x $y $size $key 0 $anchor yadj]
          return [$w.c create $type $x $y -anchor $anchor {*}[array get opts]]
        }
        oval -
        rectangle {
          set width  [expr ($opts(-ratio) < 1) ? ($opts(-ratio) * $size)       : $size]
          set height [expr ($opts(-ratio) > 1) ? ((1 / $opts(-ratio)) * $size) : $size]
          unset opts(-ratio)
          if {$data($w,options,-perspective) && ($type eq "rectangle") && ($anchor ne "s")} {
            lassign [get_perspective_points $w $x $y $width $height $anchor] x0 y0 x1 y1 x2 y2 x3 y3 yadj
            set id [$w.c create polygon $x0 $y0 $x1 $y1 $x3 $y3 $x2 $y2 {*}[array get opts]]
            if {$reflect > 0} {
              set opts(-fill)    [get_reflection_color $w [expr {($opts(-fill)    ne "") ? $opts(-fill)    : $data($w,options,-background)}]]
              set opts(-outline) [get_reflection_color $w [expr {($opts(-outline) ne "") ? $opts(-outline) : "black"}]]
              set rid [$w.c create polygon $x0 [expr $y0 + $height + 1] $x1 [expr $y1 + $height + 1] $x3 [expr $y3 + $height + 1] $x2 [expr $y2 + $height + 1] {*}[array get opts]]
              $w.c lower $rid
            }
          } else {
            if {$data($w,options,-perspective) && ($type eq "oval") && ($anchor ne "s")} {
              set width [get_perspective_width $w $x $y $width]
            }
            switch $anchor {
              s {
                set x1 [expr $x - ($width / 2)]
                set x2 [expr $x1 + $width]
              }
              sw {
                set x1 $x
                set x2 [expr $x + $width]
              }
              se {
                set x1 [expr $x - $width]
                set x2 $x
              }
            }
            set id [$w.c create $type $x1 [expr $y - $height] $x2 $y {*}[array get opts]]
            if {$reflect > 0} {
              set opts(-fill)    [get_reflection_color $w [expr {($opts(-fill)    ne "") ? $opts(-fill)    : $data($w,options,-background)}]]
              set opts(-outline) [get_reflection_color $w [expr {($opts(-outline) ne "") ? $opts(-outline) : "black"}]]
              set rid [$w.c create $type $x1 [expr ($y - $yadj) + 1] $x2 [expr $y + $height + 1] {*}[array get opts]]
              $w.c lower $rid
            }
          }
          return $id
        }
        default {
          return -code error "Illegal item at index $index ([lindex $item 0])"
        }
      }
      
    }
    
    return ""
    
  }
  
  ###########################################################################
  # Calculates and returns the radius to use for this display.
  proc set_radius {w} {

    variable data
    
    # Calculate the usable space
    set pi     3.1415926535897931
    set height [expr ($data($w,options,-height) - ($data($w,options,-pady) * 2)) / 2]
    set width  [expr ($data($w,options,-width) / 2) + $height]
    
    # Make sure that the height is never 0
    set height [expr ($height == 0) ? 1 : $height]
    
    set data($w,radius) [expr $width / sin( $pi - (atan2($width,$height) * 2) )]
  
  }
  
  ###########################################################################
  # Returns the Y coordinates based on the given distance from the center
  # bottom of the display.
  proc get_y {w distance} {
  
    variable data
    
    # Get the radius
    set radius $data($w,radius)

    # Calculate the y pixel point where the arc crosses the given distance point
    return [expr $data($w,options,-height) - (int($radius - sqrt( ($radius * $radius) - ($distance * $distance) )) + $data($w,options,-pady))]
    
  }
  
  ###########################################################################
  # Draw the current element.
  proc draw_current {w dir} {
  
    variable data
    
    set width [get_current_width $w]
    set item  [lindex $data($w,items) $data($w,current)]
    
    set x [expr $data($w,options,-width) / 2]
    set y [expr $data($w,options,-height) - $data($w,options,-pady)]
    
    if {$data($w,options,-animate)} {
      if {$dir < 0} {
        incr x 11
      } elseif {$dir > 0} {
        incr x -11
      }
    }
    
    if {[set id [draw_item $w $data($w,current) $x $y $width s]] ne ""} {
    
      array set opts [lindex $item 1]
      
      if {($data($w,options,-state) ne "disabled") && ($opts(-state) ne "disabled")} {
      
        # Bind the current item with user-defined bindings
        foreach binding [lindex $data($w,items) $data($w,current) 2] {
          $w.c bind $id [lindex $binding 0] [lindex $binding 1]
        }
        
      }
      
    }
    
  }
  
  ###########################################################################
  # Draws the icons to the left of the current icon.
  proc draw_left {w max_items dir} {
  
    variable data
    
    set width [get_other_width $w]
    set padx  [get_padx $w]
    set items [expr ($data($w,current) < $max_items) ? $data($w,current) : $max_items]
    set right [expr ($data($w,options,-width) / 2) - (([get_current_width $w] / 2) + $padx)]
    
    for {set i 1} {$i <= $items} {incr i} {
    
      set index [expr $data($w,current) - $i]
      set item  [lindex $data($w,items) $index]
      set x     [expr $right - $width]
      set y     [get_y $w [expr ($data($w,options,-width) / 2) - $x]]
      
      if {[set id [draw_item $w $index $x $y $width sw]] ne ""} {
        
        # Adjust the right offset
        set right [expr $right - $padx]
      
        # Lower this item
        $w.c lower $id
      
        # Bind the element so that it becomes the current item
        $w.c bind $id <Button-1> "carousel::set_current $w $index 1"
        
      }
      
    }
    
    return $items
    
  }
  
  ###########################################################################
  # Draws the icons to the right of the current icon.
  proc draw_right {w max_items dir} {
  
    variable data
    
    set width  [get_other_width $w]
    set padx   [get_padx $w]
    set ritems [expr [llength $data($w,items)] - ($data($w,current) + 1)]
    set items  [expr ($ritems < $max_items) ? $ritems : $max_items]
    set left   [expr ($data($w,options,-width) / 2) + ([get_current_width $w] / 2) + $padx]

    for {set i 1} {$i <= $items} {incr i} {
    
      set index [expr $data($w,current) + $i]
      set item  [lindex $data($w,items) $index]
      set x     [expr $left + $width]
      set y     [get_y $w [expr $x - ($data($w,options,-width) / 2)]]
      
      if {[set id [draw_item $w $index $x $y $width se]] ne ""} {
        
        # Adjust the left offset
        set left [expr $left + $padx]
      
        # Lower this item
        $w.c lower $id
      
        # Bind the element so that it becomes the current item
        $w.c bind $id <Button-1> "carousel::set_current $w $index 1"
        
      }
      
    }
    
    return $items
  
  }
  
  ###########################################################################
  # Handles animation sequence.
  proc animate {w dir {count 0}} {
  
    variable data
    
    if {$count < 7} {
    
      # Move the current over by 1 pixels
      if {$dir < 0} {
        $w.c move "_carousel_$data($w,current)" [expr ($count > 3) ? -1 : -2] 0
      } else {
        $w.c move "_carousel_$data($w,current)" [expr ($count > 3) ? 1 : 2] 0
      }
      
      # Reschedule the animation
      set data($w,animate_id) [after 50 [list carousel::animate $w $dir [incr count]]]
      
    }
  
  }
  
  ###########################################################################
  # Redraws the canvas.
  proc redraw {w {dir 0}} {
  
    variable data
    
    # Delete everything
    $w.c delete all
    
    # If there are no elements, don't draw anything
    if {$data($w,current) == -1} {
      return
    }
    
    # Get the maximum number of side items
    set side_items [expr ($data($w,displayed) - 1) / 2]
    
    # Draw the current item
    draw_current $w $dir
    draw_left  $w $side_items $dir
    draw_right $w $side_items $dir
    
    # If we need to animate, perform the animation sequence
    if {$data($w,options,-animate) && ($dir != 0)} {
      if {[info exists data($w,animate_id)]} {
        after cancel $data($w,animate_id)
      }
      set data($w,animate_id) [after 50 [list carousel::animate $w $dir]]
    }
    
    # Figure out the first and last values for the xscrollcommand
    set total [llength $data($w,items)]
    set first [expr $data($w,current) / $total.0]
    set last  [expr ($data($w,current) + 1) / $total.0]
    
    # Call the xscrollcommand
    if {$data($w,options,-xscrollcommand) ne ""} {
      eval "$data($w,options,-xscrollcommand) $first $last"
    }
  
  }
  
  ###########################################################################
  # Performs an animated redraw from a given index to another index.
  proc animated_redraw {w count increment} {
  
    variable data
    
    if {$count > 0} {

      # Set the current index
      incr data($w,current) $increment
    
      # Perform the redraw
      redraw $w [expr ($count == 1) ? (($increment < 0) ? 1 : -1) : 0]
    
      # Reschedule the animation
      set data($w,animate_id) [after 50 [list carousel::animated_redraw $w [expr $count - 1] $increment]]
      
    }
    
  }
  
  ###########################################################################
  # Returns the index of the item that should be the next current (skipping
  # hidden items).
  proc find_next_current {w index} {
    
    variable data
    
    set num_items [llength $data($w,items)]
    
    # First, attempt to find an item between index and the end of the list
    for {set i [expr $index + 1]} {$i < $num_items} {incr i} {
      array set opts [lindex $data($w,items) $i 1]
      if {$opts(-state) ne "hidden"} {
        return $i
      }
    }
    
    # Otherwise, attempt to find an item between index and the start of the list
    for {set i [expr $index - 1]} {$i >= 0} {incr i -1} {
      array set opts [lindex $data($w,items) $i 1]
      if {$opts(-state) ne "hidden"} {
        return $i
      }
    }
    
    # Otherwise, we can't find any so set current to -1
    return -1
    
  }
  
  ###########################################################################
  # Sets the given index to be the current item.
  proc set_current {w index deny_hidden} {
  
    variable data
    
    # Get the number of items in the items list
    set items [llength $data($w,items)]

    if {($index >= 0) && ($index < $items)} {
    
      # Get the previous current value (for animation purposes)
      set prev_current $data($w,current)
    
      # If the given index is hidden, find the next index to display
      array set opts [lindex $data($w,items) $index 1]
      if {$opts(-state) eq "hidden"} {
        if {$deny_hidden} {
          return -code error "Attempting to set current index ($index) to hidden item"
        } else {
          set index [find_next_current $w $index]
        }
      }
    
      # Set current
      set data($w,current) $index
    
      # Calculate the direction that the list is going to move (-1 is left, 1 is right)
      set dir [expr $prev_current - $data($w,current)]
    
      # Redraw the item
      if {$dir != 0} {
        if {$data($w,options,-animate) && 0} {
          if {[info exists data($w,animate_id)]} {
            after cancel $data($w,animate_id)
          }
          set data($w,current) $prev_current
          animated_redraw $w [expr abs($dir)] [expr ($dir < 0) ? 1 : -1]
        } else {
          redraw $w $dir
        }
      }
    
      # Generate the CarouselCurrentChanged event
      event generate $w <<CarouselCurrentChanged>>
      
    }

  }

  ###########################################################################
  # Converts the given index value to an indexed value.
  proc getindex {w index} {
    
    variable data
    
    set items [llength $data($w,items)]
    
    # Set current
    if {$index eq "current"} {
      return $data($w,current)
    } elseif {$index eq "end"} {
      return [expr $items - 1]
    } elseif {[string is integer $index]} {
    } elseif {[regexp $data(endmd) $index -> num]} {
      set index [expr $items - ($num + 1)]
    } elseif {[regexp $data(endpd) $index -> num]} {
      set index [expr $items + ($num - 1)]
    } elseif {[regexp $data(dpd) $index -> num1 num2]} {
      set index [expr $num1 + $num2]
    } elseif {[regexp $data(dmd) $index -> num1 num2]} {
      set index [expr $num1 - $num2]
    } elseif {[regexp $data(xy) $index -> x y]} {
      if {[regexp $data(tag) [$w.c gettags [$w.c find closest $x $y]] -> num]} {
        set index $num
      } else {
        return -code error "non-existent item at coordinate ($x,$y)"
      }
    } else {
      return -code error "illegal index specified ($index)"
    }
    
    return [expr {($index < 0) ? 0 : (($index >= $items) ? ($items - 1) : $index)}]
    
  }
  
  ###########################################################################
  # Handles all commands.
  proc widget_cmd {w args} {
    
    if {[llength $args] == 0} {
      return -code error "carousel widget called without a command"
    }

    set cmd  [lindex $args 0]
    set opts [lrange $args 1 end]

    switch $cmd {
      bind          { return [eval "carousel::binditem $w $opts"] }
      cget          { return [eval "carousel::cget $w $opts"] }
      configure     { eval "carousel::configure 0 $w $opts" }
      delete        { eval "carousel::delete $w $opts" }
      index         { return [eval "carousel::index $w $opts"] }
      insert        { eval "carousel::insert $w $opts" }
      itemcget      { return [eval "carousel::itemcget $w $opts"] }
      itemconfigure { eval "carousel::itemconfigure $w $opts" }
      setcurrent    { eval "carousel::setcurrent $w $opts" }
      size          { return [eval "carousel::size $w $opts"] }
      xview         { return [eval "carousel::xview $w $opts"] }
      default       { return -code error "Unknown carousel command ($cmd)" }
    }

  }
  
  ###########################################################################
  # USER COMMANDS
  ###########################################################################

  ###########################################################################
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
          if {[info exists data($w,options,$opt)]} {
            lappend results [list $opt $opt_name $opt_class $opt_default $data($w,options,$opt)]
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
        if {[info exists data($w,options,$opt)]} {
          return [list $opt $opt_name $opt_class $opt_default $data($w,options,$opt)]
        } else {
          return [list $opt $opt_name $opt_class $opt_default ""]
        }
      }
      
      return -code error "Carousel configuration option [lindex $args 0] does not exist"
    
    } else {
    
      # Save the original contents
      array set orig_options [array get data $w,options,*]

      # Parse the arguments
      foreach {name value} $args {
        if {[info exists data($w,options,$name)]} {
          set data($w,options,$name) $value
        } else {
          return -code error "Illegal option given to the carousel configure command ($name)"
        }
      }
      
      # Configure the widget with options that do not require a redraw
      $w.c configure -relief $data($w,options,-relief) -takefocus $data($w,options,-width) \
                     -cursor $data($w,options,-cursor)

      # Configure the widget with options that require a redraw
      if {($orig_options($w,options,-background) ne $data($w,options,-background)) || \
          ($orig_options($w,options,-height)     ne $data($w,options,-height)) || \
          ($orig_options($w,options,-width)      ne $data($w,options,-width))  || \
          $initialize} {

        # Update the GUI widgets
        $w.c configure -bg $data($w,options,-background) -height $data($w,options,-height) \
                       -width $data($w,options,-width)
      
        # Calculate the number of items to display
        set data($w,displayed) [get_displayed_items $w]
      
        # Re-calculate the radius
        set_radius $w
      
        # Redraw
        redraw $w
        
      }
      
    }

  }

  ###########################################################################
  # Gets configuration option value(s).
  proc cget {w args} {

    variable data
    
    # Check arguments
    if {[llength $args] != 1} {
      return -code error "Incorrect number of parameters given to the carousel cget command"
    }
    
    set name [lindex $args 0]

    if {[info exists data($w,options,$name)]} {
      return $data($w,options,$name)
    } else {
      return -code error "Illegal option given to the carousel cget command ([lindex $args 0])"
    }

  }
  
  ###########################################################################
  # Adds a new item to the carousel at the given index.
  proc insert {w args} {
  
    variable data
    variable image_options
    variable rectangle_options
    variable oval_options
    
    # Check the arguments
    if {[llength $args] < 2} {
      return -code error "carousel::insert called with illegal number of arguments"
    }
    
    set index    [lindex $args 0]
    set cfgindex $index
    set type     [lindex $args 1]
    
    # Adjust the insertion index, if necessary
    if {$index eq "current"} {
      set index $data($w,current)
      
    # Otherwise, generate the configuration index
    } elseif {[catch {getindex $w $index} cfgindex]} {
      return -code error "carousel::insert, $cfgindex"
    }
    
    # Add the item to the items list
    switch $type {
      image {
        variable image_options
        array set item_opts [array get image_options]
      }
      rectangle {
        variable rectangle_options
        array set item_opts [array get rectangle_options]
      }
      oval {
        variable oval_options
        array set item_opts [array get oval_options]
      }
      default {
        return -code error "Unsupported item type in carousel::insert ($type)"
      }
    }
    
    # Add the item
    set data($w,items) [linsert $data($w,items) $index [list $type [array get item_opts] [list]]]
    
    # Configure the item
    itemconfigure $w $index {*}[lrange $args 2 end]
    
    # If the type is an image, make sure that the -image option is set
    if {($type eq "image") && ([itemcget $w $index -image] eq "")} {
      return -code error "carousel::insert called for image type but no -image value is set"
    }
    
    # If we don't have a current item, set it to the first item
    if {$data($w,current) == -1} {
      set data($w,current) 0
    } elseif {$index <= $data($w,current)} {
      incr data($w,current)
    }

    # Re-draw the items
    redraw $w
    
    return [getindex $w $index]
    
  }
  
  ###########################################################################
  # Adds a binding to an existing item.
  proc binditem {w args} {
  
    variable data
    
    # Check to make sure that we have an index
    if {[llength $args] == 0} {
      return -code error "carousel::bind called with illegal number of arguments"
    }

    # Get the index value
    if {[catch {getindex $w [lindex $args 0]} index]} {
      return -code error "carousel::bind, $index"
    }
    
    set arg_len [llength [lrange $args 1 end]]
    set item    [lindex $data($w,items) $index]
    
    if {$item eq ""} {
      return -code error "Attempting to bind an invalid index ([lindex $args 0]) in carousel::bind" 
    }
    
    if {$arg_len == 0} {
      return [lindex $item 2]
    } elseif {$arg_len == 1} {
      if {[set found_index [lsearch -index 0 [lindex $item 2] [lindex $args 1]]] != -1} {
        return [lindex $item 2 $found_index 1]
      }
      return ""
    } elseif {$arg_len == 2} {
      if {[set found_index [lsearch -index 0 [lindex $item 2] [lindex $args 1]]] != -1} {
        if {[lindex $args 2] eq ""} {
          lset data($w,items) $index 2 [lreplace [lindex $item 2] $found_index $found_index]
        } else {
          lset data($w,items) $index 2 $found_index 1 [lindex $args 2]
        }
      } else {
        set bindings [lindex $item 2]
        lappend bindings [list [lindex $args 1] [lindex $args 2]]
        lset data($w,items) $index 2 $bindings
      }
      redraw $w
      return ""
    } else {
      return -code error "carousel::bind called with illegal number of arguments"
    }  
  
  }
  
  ###########################################################################
  # Deletes one or more items to the carousel in the given index range.
  proc delete {w args} {
  
    variable data
    
    # Check the arguments
    if {[llength $args] == 1} {
      if {[catch {getindex $w [lindex $args 0]} first]} {
        return -code error "carousel::delete, $first"
      } else {
        set last $first
      }
    } elseif {[llength $args] == 2} {
      if {[catch {getindex $w [lindex $args 0]} first]} {
        return -code error "carousel::delete, $first"
      }
      if {[catch {getindex $w [lindex $args 1]} last]} {
        return -code error "carousel::delete, $last"
      }
    } else {
      return -code error "Illegal number of options to carousel::delete"
    }
  
    # Delete the item from the list
    set data($w,items) [lreplace $data($w,items) $first $last]
    set last_item      [expr [llength $data($w,items)] - 1]
    
    # Re-draw the items
    if {$last_item < $data($w,current)} {
      set data($w,current) $last_item
      redraw $w 1
    } elseif {$last < $data($w,current)} {
      set data($w,current) [expr $data($w,current) - (($last - $first) + 1)]
      redraw $w
    } else {
      redraw $w -1
    }
  
  }
  
  ###########################################################################
  # Returns the numeric index for the given index value.
  proc index {w args} {
  
    # Check the arguments
    if {[llength $args] != 1} {
      return -code error "Illegal number of options to carousel::index"
    }
  
    if {[catch {getindex $w [lindex $args 0]} index]} {
      return -code error "carousel::index, $index"
    } else {
      return $index
    }
    
  }
  
  ###########################################################################
  # Sets the current item to the specified index.
  proc setcurrent {w args} {
  
    # Check the arguments
    if {[llength $args] != 1} {
      return -code error "Illegal number of options to carousel::setcurrent"
    }
    
    # Sets the current ID
    if {[catch {set_current $w [getindex $w [lindex $args 0]] 1} rc]} {
      return -code error "carousel::setcurrent, $rc"
    }
    
  }
  
  ###########################################################################
  # Configures a given item in the item list.
  proc itemconfigure {w args} {
  
    variable data
    variable image_options
    variable rectangle_options
    variable oval_options
    
    # Check the arguments
    if {[llength $args] < 1} {
      return -code error "Illegal number of options to carousel::itemconfigure"
    }
    
    # Adjust the index, if necessary
    if {[catch {getindex $w [lindex $args 0]} index]} {
      return -code error "carousel::itemconfigure, $index"
    }
    
    set args [lrange $args 1 end]
    
    # Get the option list for the specified item
    array set item_options [array get [lindex $data($w,items) $index 0]_options]
    array set item_opts    [lindex $data($w,items) $index 1]
    
    switch [set arg_len [llength $args]] {
    
      0 {
        set results [list]
        foreach opt [lsort [array names item_options]] {
          set opt_name    [list]
          set opt_class   [list]
          set opt_default $item_options($opt)
          if {[info exists item_opts($opt)]} {
            lappend results [list $opt $opt_name $opt_class $opt_default $item_opts($opt)]
          } else {
            lappend results [list $opt $opt_name $opt_class $opt_default ""]
          } 
        }
        return $results
      }
      
      1 {
        set opt [lindex $args 0]      
        if {[info exists item_options($opt)]} {
          set opt_name    [list]
          set opt_class   [list]
          set opt_default $item_options($opt)
          if {[info exists item_opts($opt)]} {
            return [list $opt $opt_name $opt_class $opt_default $item_opts($opt)]
          } else {
            return [list $opt $opt_name $opt_class $opt_default ""]
          }
        }
        return -code error "carousel::itemconfigure option [lindex $args 0] does not exist for index $index"
      }
      
      default {
        if {[expr $arg_len % 2] != 0} {
          return -code error "carousel::itemconfigure called with an odd number of arguments"
        }
        foreach {name value} $args {
          if {[info exists item_opts($name)]} {
            set item_opts($name) $value
          } else {
            return -code error "Illegal option given to the carousel::itemconfigure command ($name) for index $index"
          }
        }
        lset data($w,items) $index 1 [array get item_opts]
        if {($index == $data($w,current)) && ($item_opts(-state) eq "hidden")} {
          set_current $w $index 0
        } else {
          redraw $w
        }
        return ""
      }
      
    }
  
  }
  
  ###########################################################################
  # Retrieves a configured value for the the given item.
  proc itemcget {w args} {
  
    variable data
    
    # Check the arguments
    if {[llength $args] != 2} {
      return -code error "Illegal number of options to carousel::itemcget"
    }
    
    # Adjust the index value, if necessary
    if {[catch {getindex $w [lindex $args 0]} index]} {
      return -code error "carousel::itemcget, $index"
    }
    
    set opt [lindex $args 1]
    
    array set opts [lindex $data($w,items) $index 1]
    
    if {[info exists opts($opt)]} {
      return $opts($opt)
    } else {
      return ""
    }
  
  }
  
  ###########################################################################
  # Returns the number of elements in the carousel.
  proc size {w args} {
  
    variable data
    
    # Check the arguments
    if {[llength $args] != 0} {
      return -code error "Illegal number of options to carousel::size"
    }
    
    return [llength $data($w,items)]
  
  }
  
  ###########################################################################
  # Handles the xview call to adjust the current view.
  proc xview {w args} {
  
    variable data
    
    # Check the arguments
    set arg_len [llength $args]
    
    # If this is just the xview command, return the list
    if {$arg_len == 0} {
      set total_items [llength $data($w,items)]
      if {$total_items == 0} {
        set off_left  0.0
        set off_right 0.0
      } else {
        set off_left  [expr $data($w,current) / $total_items.0]
        set off_right [expr ($total_items - ($data($w,current) + 1)) / $total_items.0]
      }
      return [list $off_left $off_right]
    
    # Otherwise, if this is the moveto command, handle it 
    } elseif {[lindex $args 0] eq "moveto"} {
      if {$arg_len != 2} {
        return -code error "Illegal number of options to the carousel::xview moveto command"
      }
      set_current $w [getindex $w [expr int([llength $data($w,items)] * [lindex $args 1])]] 0
      
    # Otherwise, if this is the scroll command, handle it
    } elseif {[lindex $args 0] eq "scroll"} {
      if {$arg_len != 3} {
        return -code error "Illegal number of options to the carousel::xview scroll command"
      }
      set number [lindex $args 1]
      if {![string is integer $number]} {
        return -code error "Invalid number value specified for carousel::xview scroll command"
      }
      set items  [llength $data($w,items)]
      switch [lindex $args 2] {
        units {
          set index [expr $data($w,current) + $number]
        }
        pages {
          set index [expr $data($w,current) + ($number * $data($w,displayed))]
        }
        default {
          return -code error "carousel::xview scroll called with unknown what value ([lindex $args 2])"
        }
      }
      if {$index < 0} {
        set index 0
      } elseif {$index >= $items} {
        set index [expr $items - 1]
      }
      set_current $w $index 0
    
    # Otherwise, indicate that we have an error
    } else {
      return -code error "Illegal subcommand given to carousel::xview"
    }
    
  }

}
