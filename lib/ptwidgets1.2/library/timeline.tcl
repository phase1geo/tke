######################################################################
# Name:    timeline.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    12/31/2013
# Brief:   Provides a timeline widget useful for viewing the history
#          of something.
######################################################################

package provide timeline 1.2

namespace eval timeline {
  
  array set data {}
  
  array set redraw_coords {
    w0 {[expr $width - ($padx + $linelen)] $y [expr $width - $padx] [incr y $thickness]}
    w1 {$padx $y [expr $padx + $linelen] [incr y $thickness]}
    n0 {$x [expr $height - ($pady + $linelen)] [incr x $thickness] [expr $height - $pady]}
    n1 {$x $pady [incr x $thickness] [expr $pady + $linelen]}
  }
    
  array set widget_options {
    -anchor                 {anchor                 Anchor}
    -background             {background             Background}
    -bg                     -background
    -borderwidth            {borderWidth            BorderWidth}
    -bd                     -borderwidth
    -command                {command                Command}
    -cursor                 {cursor                 Cursor}
    -curvelen               {curveLen               CurveLen}
    -events                 {events                 Events}
    -font                   {font                   Font}
    -fontcolor              {fontColor              Color}
    -format                 {format                 Format}
    -linelen                {lineLen                LineLen}
    -linecolor              {lineColor              Color}
    -linespacing            {lineSpacing            LineSpacing}
    -linethickness          {lineThickness          LineThickness}
    -orient                 {orient                 Orient}
    -padx                   {padX                   Pad}
    -pady                   {padY                   Pad}
    -relief                 {relief                 Relief}
    -scancommand            {scanCommand            Command}
    -selectcolor            {selectColor            Color}
    -selectmode             {selectMode             SelectMode}
    -state                  {state                  State}
    -takefocus              {takeFocus              TakeFocus}
    -zoom                   {zoom                   Zoom}
  }
  
  ######################################################################
  # Creates an instance of a timeline widget with the given pathname.
  proc timeline {w args} {
    
    variable data
    variable widget_options
    
    # Create the timeline widget
    frame  $w   -class TimeLine -relief flat -takefocus 0
    canvas $w.c -width 50  -highlightthickness 0 -relief flat -bg white -takefocus 1
    canvas $w.f -width 100 -highlightthickness 0 -relief flat -bg white -takefocus 0
    
    # If the carousel namespace hasn't been accessed, initialize some constants
    if {[array size data] == 0} {
      option add *TimeLine.anchor        "nw"            widgetDefault
      option add *TimeLine.background    "white"         widgetDefault
      option add *TimeLine.borderWidth   "0"             widgetDefault
      option add *TimeLine.command       ""              widgetDefault
      option add *TimeLine.cursor        ""              widgetDefault
      option add *TimeLine.curveLen      "100"           widgetDefault
      option add *TimeLine.events        ""              widgetDefault
      option add *TimeLine.font          "TkDefaultFont" widgetDefault
      option add *TimeLine.fontColor     "black"         widgetDefault
      option add *TimeLine.format        ""              widgetDefault
      option add *TimeLine.height        "400"           widgetDefault
      option add *TimeLine.lineLen       "10"            widgetDefault
      option add *TimeLine.lineColor     "black"         widgetDefault
      option add *TimeLine.lineSpacing   "8"             widgetDefault
      option add *TimeLine.lineThickness "2"             widgetDefault
      option add *TimeLine.orient        "vertical"      widgetDefault
      option add *TimeLine.padX          "5"             widgetDefault
      option add *TimeLine.padY          "5"             widgetDefault
      option add *TimeLine.relief        "flat"          widgetDefault
      option add *TimeLine.scanCommand   ""              widgetDefault
      option add *TimeLine.selectColor   "red"           widgetDefault
      option add *TimeLine.selectMode    "single"        widgetDefault
      option add *TimeLine.state         "normal"        widgetDefault
      option add *TimeLine.takeFocus     "1"             widgetDefault
      option add *TimeLine.width         "50"            widgetDefault
      option add *TimeLine.zoom          "4"             widgetDefault
    }
    
    # Initialize variables
    set data($w,events)    [list]
    set data($w,center)    ""
    set data($w,closest)   ""
    set data($w,idle)      ""
    set data($w,selection) [list]
    
    # Initialize the options array
    foreach opt [array names widget_options] {
      set data($w,options,$opt) [option get $w [lindex $widget_options($opt) 0] [lindex $widget_options($opt) 1]]
    }
    
    # Set the bindtags for the text and listbox widgets
    bindtags $w.c [linsert [bindtags $w.c] 1 [bodytag $w] TimeLineCanvas]
    
    # Add canvas bindings
    bind TimeLineCanvas <Motion> { timeline::handle_motion [winfo parent %W] %x %y }
    bind TimeLineCanvas <Leave>  { timeline::handle_leave  [winfo parent %W] %x %y }
    
    # Configure the widget
    eval "configure 1 $w $args"

    # Rename and alias the tokenentry window
    rename ::$w $w
    interp alias {} ::$w {} timeline::widget_cmd $w
    
    return $w
    
  }
  
  ######################################################################
  # Handles a mouse motion event in the canvas which will cause the event
  # line closest to the cursor to magnify.
  proc handle_motion {w x y} {
    
    variable data
    
    # Save the last closest item
    set last_closest $data($w,closest)
    
    # Save the last center position
    set data($w,last) $data($w,center)
    
    # Get the event line that is closest to
    if {$data($w,options,-orient) eq "vertical"} {
      set data($w,center)  $y
      set data($w,closest) [$w.c find closest 0 $y]
    } else {
      set data($w,center)  $x
      set data($w,closest) [$w.c find closest $x 0]
    }
    
    # Redraw the widget
    redraw $w
    
    # If the user has specified a scan command, run it in the background
    if {($data($w,options,-scancommand) ne "") && ($last_closest ne $data($w,closest))} {
      if {$data($w,idle) ne ""} {
        after cancel $data($w,idle)
      }
      set data($w,idle) [after idle [list timeline::run_scancommand $w [lsearch $data($w,events) $data($w,closest)]]]
    }
    
  }
  
  ######################################################################
  # Runs the scancommand.
  proc run_scancommand {w index} {
    
    variable data
    
    # Clear the idle variable
    set data($w,idle) ""
    
    uplevel #0 [list $data($w,options,-scancommand) $w $index]
    
  }
  
  ######################################################################
  # Handles a mouse leave event from the canvas which will cause any
  # magnified event lines to return to their original positions.
  proc handle_leave {w x y} {
    
    variable data
    
    if {($x < 0) || ($x >= [$w.c cget -width]) || \
        ($y < 0) || ($y >= [$w.c cget -height])} {
    
      # Clear the center tracker
      set data($w,center) ""
      set data($w,last)   ""
    
      # Redraw the widget
      redraw $w
      
    }
    
  }
  
  ######################################################################
  # Calculates the amount of zoom for a line given its distance from
  # the center (mouse position).  Uses the cosine wave along with the
  # user provided line length and zoom amount to calculate.
  proc zoom_factor {w from_center} {
    
    variable data
    
    # Get the half value of the maximum line length
    set half_cl [expr $data($w,options,-curvelen) / 2]
    
    # Any pixel that is less than (half_cl / 2) from the center will have a degree
    # value between 180 and 540 (where 360 is 0 from center)
    if {[expr abs($from_center) < $half_cl]} {
      set degree [expr 360 + (($from_center / $half_cl.0) * 180)]
    } else {
      set degree 180
    }
    
    # Convert the degree to radians
    set radians [expr ($degree * 3.1415926535897931) / 180.0]
    
    return [expr (cos( $radians ) + 1) / 2]
    
  }
  
  ######################################################################
  # Generates a list of zoom factors and accumulated zoom factors.
  proc generate_zoom_factors {w} {
    
    variable data
    
    set data($w,zoom_factors) [list]
    set acc_zoom              0.0
    
    # Calculate the list of zoom factors and the accumulated zoom factor from center
    for {set i 0} {$i < [expr $data($w,options,-curvelen) / 2]} {incr i} {
      set zoom_factor [zoom_factor $w $i]
      puts "i: $i, zoom_factor: $zoom_factor"
      lappend data($w,zoom_factors) [list [expr $zoom_factor * $data($w,options,-zoom)] [set acc_zoom [expr ($i == 0) ? 0.0 : ($acc_zoom + $zoom_factor)]]]
    }
    
  }
  
  ######################################################################
  # Returns a list containing the line length and line thickness to use
  # when drawing.
  proc get_len_and_thickness {w pos plen pthick} {
    
    variable data
    
    upvar $plen   len
    upvar $pthick thickness
    
    # Calculate the the zoom factor
    if {[set diff [expr abs( $pos - $data($w,center) )]] >= [llength $data($w,zoom_factors)]} {
      set zoom_factor 0.0
    } else {
      set zoom_factor [lindex $data($w,zoom_factors) $diff 0]
    }
    
    # Calculate the line length
    set len [expr int( round( $zoom_factor * $data($w,options,-linelen) ) ) + $data($w,options,-linelen)]
    
    # Calculate the line thickness
    set thickness [expr int( round( $zoom_factor * $data($w,options,-linethickness) ) ) + $data($w,options,-linethickness)]
    
  }
  
  ######################################################################
  # Handles a click of line in the timeline.
  proc handle_clicked {w index} {
    
    variable data
    
    # Set the current line
    if {$data($w,options,-selectmode) eq "single"} {
      foreach select $data($w,selection) {
        selection_clear $w $select
      }
      selection_set $w $index
    } else {
      if {[lsearch $data($w,selection) $index] != -1} {
        selection_clear $w $index
      } else {
        selection_set $w $index
      }
    }
    
    # Run the -command procedure if it exists
    if {$data($w,options,-command) ne ""} {
      uplevel #0 [list $data($w,options,-command) $w $index]
    }
    
  }
  
  ######################################################################
  # Redraw the initial state of the widget in a vertical orientation.
  proc redraw_initial_vertical {w} {
    
    variable data
    variable redraw_coords
    
    # Set the variables
    set coords     $redraw_coords(w[expr [string first "w" $data($w,options,-anchor)] != -1])
    set padx       $data($w,options,-padx)
    set pady       $data($w,options,-pady)
    set linelen    $data($w,options,-linelen)
    set thickness  $data($w,options,-linethickness)
    set color      $data($w,options,-linecolor)
    set spacing    $data($w,options,-linespacing)
    set num_events [llength $data($w,options,-events)]
    
    # Create the dimensions of the timeline canvas
    set height [expr ($pady * 2) + (($num_events == 0) ? 0 : (($num_events * $thickness) + (($num_events - 1) * $spacing)))]
    set width  [expr ($data($w,options,-zoom) * $linelen) + $linelen + (2 * $padx)]
    $w.c configure -height $height -width $width
    
    # Create the dimensions of the date canvas
    if {$data($w,options,-format) ne ""} {
      $w.f create text 0 0 -tags date_string -text [clock format 977292000 -format $data($w,options,-format)]
      lassign [$w.f bbox date_string] x0 y0 x1 y1 
      $w.f delete date_string
      $w.f configure -height $height -width [expr ($x1 - $x0) + 5 + $padx]
      $w.c configure -width [incr width -$padx]
    }
    
    # Create the timeline
    set y $pady
    for {set i 0} {$i < $num_events} {incr i} {
      lappend data($w,events) [set id [$w.c create rectangle {*}[subst $coords] -tags line -width 0 -fill $color]]
      $w.c bind $id <Button-1> "timeline::handle_clicked $w $i"
      incr y $spacing
    }
      
  }
  
  ######################################################################
  # Redraw the initial state of the widget in a horizontal orientation.
  proc redraw_initial_horizontal {w} {
    
    variable data
    variable redraw_coords
    
    # Set the variables
    set coords     $redraw_coords(n[expr [string first "n" $data($w,options,-anchor)] != -1])
    set padx       $data($w,options,-padx)
    set pady       $data($w,options,-pady)
    set linelen    $data($w,options,-linelen)
    set thickness  $data($w,options,-linethickness)
    set color      $data($w,options,-linecolor)
    set spacing    $data($w,options,-linespacing)
    set num_events [llength $data($w,options,-events)]
    
    # Set the the dimensions of the timeline canvas
    set height [expr ($data($w,options,-zoom) * $linelen) + $linelen + ($pady * 2)]
    set width  [expr ($padx * 2) + (($num_events == 0) ? 0 : (($num_events * $thickness) + (($num_events - 1) * $spacing)))]
    set width  [expr $width + ($data($w,options,-curvelen) / 2)]
    $w.c configure -height $height -width $width
    
    # Set the dimensions of the date canvas
    if {$data($w,options,-format) ne ""} {
      $w.f create text 0 0 -tags date_string -text [clock format 977292000 -format $data($w,options,-format)]
      lassign [$w.f bbox date_string] x0 y0 x1 y1 
      $w.f delete date_string
      $w.f configure -height [expr ($y1 - $y0) + 5 + $pady] -width $width
      $w.c configure -height [incr height -$pady]
    }
    
    # Create the timeline
    set x [expr $data($w,options,-padx) + ($data($w,options,-curvelen) / 4)]
    for {set i 0} {$i < $num_events} {incr i} {
      set id [$w.c create rectangle {*}[subst $coords] -tags line -width 0 -fill $color]
      $w.c bind $id <Button-1> "timeline::handle_clicked $w $i"
      lappend data($w,events) $id
      incr x $spacing
    }
     
  }
  
  ######################################################################
  # Draws the widget in the initial state.
  proc redraw_initial {w} {
    
    variable data
    
    # Clear the canvases
    $w.c delete all
    $w.f delete all
    set data($w,events) [list]
     
    # Redraw the initial state of the widget
    redraw_initial_$data($w,options,-orient) $w
    
    # Add back the selections
    foreach selection $data($w,selection) {
      $w.c itemconfigure [lindex $data($w,events) $selection] -fill $data($w,options,-selectcolor)
    }
        
  }
  
  ######################################################################
  # Redraws the canvas widget contents.
  proc redraw {w} {
    
    variable data
    
    # Initialize variables
    set thickness  $data($w,options,-linethickness)
    set num_events [llength $data($w,options,-events)]
    set spacing    $data($w,options,-linespacing)
    
    # If a magnified event exists, adjust the drawing of the other values accordingly
    if {$data($w,center) eq ""} {
      
      # Generate the list of zoom factors
      generate_zoom_factors $w
        
      # Perform the redraw of the initial state
      redraw_initial $w
      
    } else {
      
      # Get the closest information
      set closest_index [lsearch $data($w,events) $data($w,closest)]
      lassign [$w.c coords $data($w,closest)] x0 y0 x1 y1
      
      if {$data($w,options,-orient) eq "vertical"} {
        
        set left  [expr [string first "w" $data($w,options,-anchor)] != -1]
        set width [$w.c cget -width]
        
        # Adjust y0
        if {$data($w,last) ne ""} {
          if {[set diff [expr abs( $data($w,last) - $data($w,center) )]] >= [llength $data($w,zoom_factors)]} {
            set zoom_factor 0.0
          } else {
            set zoom_factor [lindex $data($w,zoom_factors) $diff 1]
          }
          puts "diff: $diff, zoom_factor: $zoom_factor"
          set y0 [expr round( $y0 + (($data($w,last) - $data($w,center)) * $zoom_factor) )]
        }
      
        # Draw the center line
        set y0          [expr int( $y0 )]
        set center      [expr int( (($y1 - $y0) / 2) + $y0 )]
        get_len_and_thickness $w $center len thickness
        if {$left} {
          $w.c coords $data($w,closest) $data($w,options,-padx) $y0 [expr $data($w,options,-padx) + $len] [expr $y0 + $thickness]
        } else {
          $w.c coords $data($w,closest) [expr $width - ($data($w,options,-padx) + $len)] $y0 [expr $width - $data($w,options,-padx)] [expr $y0 + $thickness]
        }
         
        # Display the date if we have a format command
        if {$data($w,options,-format) ne ""} {
          set value [clock format [lindex $data($w,options,-events) $closest_index] -format $data($w,options,-format)]
          $w.f delete date_string
          set data($w,text) [$w.f create text 5 $y0 -tags date_string -text $value -anchor w -font $data($w,options,-font) -fill $data($w,options,-fontcolor)]
          lassign [$w.f bbox date_string] fx0 fy0 fx1 fy1
          if {$fy0 < $data($w,options,-pady)} {
            $w.f itemconfigure date_string -anchor nw
            $w.f coords date_string 5 $data($w,options,-pady)
          } elseif {$fy1 >= [$w.f cget -height]} {
            $w.f itemconfigure date_string -anchor sw
            $w.f coords date_string 5 [expr [$w.f cget -height] - $data($w,options,-pady)]
          }
        }
         
        if {$left} {
          
          # Draw the lines after the center line
          set y [expr $y0 + $thickness + $spacing]
          for {set i [expr $closest_index + 1]} {$i < $num_events} {incr i} {
            get_len_and_thickness $w $y len thickness
            $w.c coords [lindex $data($w,events) $i] $data($w,options,-padx) $y [expr $data($w,options,-padx) + $len] [incr y $thickness]
            incr y $spacing
          }
         
          # Draw the lines before the center line
          set y [expr $y0 - $spacing]
          for {set i [expr $closest_index - 1]} {$i >= 0} {incr i -1} {
            get_len_and_thickness $w $y len thickness
            $w.c coords [lindex $data($w,events) $i] $data($w,options,-padx) [expr $y - $thickness] [expr $data($w,options,-padx) + $len] $y 
            incr y [expr 0 - ($thickness + $spacing)]
          }
          
        } else {
          
          # Draw the lines after the center line
          set y [expr $y0 + $thickness + $spacing]
          for {set i [expr $closest_index + 1]} {$i < $num_events} {incr i} {
            get_len_and_thickness $w $y len thickness
            $w.c coords [lindex $data($w,events) $i] [expr $width - ($data($w,options,-padx) + $len)] $y [expr $width - $data($w,options,-padx)] [incr y $thickness]
            incr y $spacing
          }
          
          # Draw the lines before the center line
          set y [expr $y0 - $spacing]
          for {set i [expr $closest_index - 1]} {$i >= 0} {incr i -1} {
            get_len_and_thickness $w $y len thickness
            $w.c coords [lindex $data($w,events) $i] [expr $width - ($data($w,options,-padx) + $len)] [expr $y - $thickness] [expr $width - $data($w,options,-padx)] $y 
            incr y [expr 0 - ($thickness + $spacing)]
          }
          
        }
        
      } else {
        
        set top    [expr [string first "n" $data($w,options,-anchor)] != -1]
        set height [$w.c cget -height]
        
        # Draw the center line
        set x0     [expr int( $x0 )]
        set center [expr int( (($x1 - $x0) / 2) + $x0 )]
        set x0     [expr ($x0 >= $data($w,center)) ? $x0 : int( $x1 - $thickness )]
        get_len_and_thickness $w $center len thickness
        if {$top} {
          $w.c coords $data($w,closest) $x0 $data($w,options,-pady) [expr $x0 + $thickness] [expr $data($w,options,-pady) + $len]
        } else {
          $w.c coords $data($w,closest) $x0 [expr $height - ($data($w,options,-pady) + $len)] [expr $x0 + $thickness] [expr $height - $data($w,options,-pady)]
        }
        
        # Display the date if we have a format command
        if {$data($w,options,-format) ne ""} {
          set value [clock format [lindex $data($w,options,-events) $closest_index] -format $data($w,options,-format)]
          $w.f delete date_string
          set data($w,text) [$w.f create text $x0 5 -tags date_string -text $value -anchor n -font $data($w,options,-font) -fill $data($w,options,-fontcolor)]
          lassign [$w.f bbox date_string] fx0 fy0 fx1 fy1
          if {$fx0 < $data($w,options,-padx)} {
            $w.f itemconfigure date_string -anchor nw
            $w.f coords date_string $data($w,options,-padx) 5
          } elseif {$fx1 >= [$w.f cget -width]} {
            $w.f itemconfigure date_string -anchor ne 
            $w.f coords date_string [expr [$w.f cget -width] - $data($w,options,-padx)] 5
          }
        }
        
        if {$top} {
        
          # Draw the lines after the center line
          set x [expr $x0 + $thickness + $spacing]
          for {set i [expr $closest_index + 1]} {$i < $num_events} {incr i} {
            get_len_and_thickness $w $x len thickness
            $w.c coords [lindex $data($w,events) $i] $x $data($w,options,-pady) [incr x $thickness] [expr $data($w,options,-pady) + $len]
            incr x $spacing
          }
        
          # Draw the lines before the center line
          set x [expr $x0 - $spacing]
          for {set i [expr $closest_index - 1]} {$i >= 0} {incr i -1} {
            get_len_and_thickness $w $x len thickness
            $w.c coords [lindex $data($w,events) $i] [expr $x - $thickness] $data($w,options,-pady) $x [expr $data($w,options,-pady) + $len]
            incr x [expr 0 - ($thickness + $spacing)]
          }
          
        } else {
          
          # Draw the lines after the center line
          set x [expr $x0 + $thickness + $spacing]
          for {set i [expr $closest_index + 1]} {$i < $num_events} {incr i} {
            get_len_and_thickness $w $x len thickness
            $w.c coords [lindex $data($w,events) $i] $x [expr $height - ($data($w,options,-pady) + $len)] [incr x $thickness] [expr $height - $data($w,options,-pady)]
            incr x $spacing
          }
        
          # Draw the lines before the center line
          set x [expr $x0 - $spacing]
          for {set i [expr $closest_index - 1]} {$i >= 0} {incr i -1} {
            get_len_and_thickness $w $x len thickness
            $w.c coords [lindex $data($w,events) $i] [expr $x - $thickness] [expr $height - ($data($w,options,-pady) + $len)] $x [expr $height - $data($w,options,-pady)]
            incr x [expr 0 - ($thickness + $spacing)]
          }
          
        }
        
      }
      
    }
    
  }
  
  ######################################################################
  # Clears the selected lines.
  proc selection_clear {w first {last ""}} {
    
    variable data
    
    # If last was not specified, set it to the same count as first
    if {$last eq ""} {
      set last $first
    }
    
    # Change selections to their color to the normal line color and delete
    # them from the selections list.
    set i $first
    foreach event [lrange $data($w,events) $first $last] {
      if {[set index [lsearch $data($w,selection) $i]] != -1} {
        $w.c itemconfigure $event -tags line -fill $data($w,options,-linecolor)
        set data($w,selection) [lreplace $data($w,selection) $index $index]
      }
      incr i
    }
    
  }
  
  ######################################################################
  # Allows the program code to select an event to show as the current
  # event.
  proc selection_set {w first {last ""}} {
    
    variable data
    
    # If more than one line was specified while in single mode, use only the first line
    # in the list.
    if {($last eq "") || (($data($w,options,-selectmode) eq "single") && ($last ne ""))} {
      set last $first
    }
    
    set i $first
    foreach event [lrange $data($w,events) $first $last] {
      
      # Only add lines that have not already been added
      if {[lsearch $data($w,selection) $i] == -1} {
        
        # Add the line to the selection
        lappend data($w,selection) $i
      
        # Change the color of the given index to the current color
        $w.c itemconfigure $event -tags selection -fill $data($w,options,-selectcolor)
        
      }
      
      incr i
      
    }
    
  }
  
  ######################################################################
  # Checks to make sure that all of the options are valid.
  proc check_options {w} {
    
    variable data
    
    # Check -orient
    if {[lsearch {vertical horizontal} $data($w,options,-orient)] == -1} {
      return -code error "Bad timeline -orient value"
    }
    
    # Check -anchor
    if {(($data($w,options,-orient) eq "vertical")   && ([lsearch {nw w sw ne e se} $data($w,options,-anchor)] == -1)) ||
        (($data($w,options,-orient) eq "horizontal") && ([lsearch {nw n ne sw s se} $data($w,options,-anchor)] == -1))} {
      return -code error "Bad timeline -anchor value"
    }
    
  }
  
  ######################################################################
  # Handles all of the public widget command parsing.
  proc widget_cmd {w args} {
    
    if {[llength $args] == 0} {
      return -code error "timeline widget $w called without a command"
    }
    
    set cmd  [lindex $args 0]
    set opts [lrange $args 1 end]
    
    switch $cmd {
      bodytag      { return [eval "timeline::bodytag $w"] }
      cget         { return [eval "timeline::cget $w $opts"] }
      configure    { return [eval "timeline::configure 0 $w $opts"] }
      curselection { return [eval "timeline::curselection $w $opts"] }
      selection    { return [eval "timeline::selection $w $opts"] }
      default      { return -code error "Unknown carousel command ($cmd)" }
    }
    
  }
  
  ######################################################################
  #  USER COMMANDS
  ######################################################################
  
  ###########################################################################
  # Returns the name of the bind tag associated with the given widget.
  proc bodytag {w} {
    
    return "body$w"
    
  }
  
  ######################################################################
  # Returns the value of the specified configuration option.
  proc cget {w args} {
    
    variable data
    variable widget_options
    
    if {[llength $args] != 1} {
      return -code error "Incorrect number of parameters given to the timeline::cget command"
    }
    
    if {[set name [lindex $args 0]] eq "-bg"} {
      set name "-background"
    }
    
    if {[info exists widget_options($name)]} {
      return $data($w,options,$name)
    } else {
      return -code error "Illegal option given to the timeline::cget command ([lindex $args 0])"
    }
    
  }
  
  ######################################################################
  # Returns the configuration values for the given widget or allows the
  # user to change the value of a configuration option.
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
      
      return -code error "Timeline configuration option [lindex $args 0] does not exist"
      
    } else {
      
      # Save the original contents
      array set orig_options [array get data $w,options,*]
      
      # Parse the arguments
      foreach {name value} $args {
        if {(($name eq "-orient") || ($name eq "-anchor") || ($name eq "-format")) && !$initialize} {
          return -code error "Timeline $name option cannot be changed after initialization" 
        } elseif {[info exists data($w,options,$name)]} {
          set data($w,options,$name) $value
        } else {
          return -code error "Illegal option given to the timeline configure command ($name)"
        }
      }
      
      # Validate the options
      check_options $w
      
      # Configure the frame
      $w configure -relief $data($w,options,-relief) -bd $data($w,options,-borderwidth) \
        -bg $data($w,options,-background)
      
      # Configure the widget with options that do not require a redraw
      $w.c configure -takefocus $data($w,options,-takefocus) \
        -cursor $data($w,options,-cursor)
      
      # Sort out the widget placement based on the initial option values
      if {$initialize} {
        if {$data($w,options,-orient) eq "vertical"} {
          set left [expr [string first "w" $data($w,options,-anchor)] != -1]
          if {[string first "n" $data($w,options,-anchor)] != -1} {
            grid rowconfigure $w 2 -weight 1
          } elseif {[string first "s" $data($w,options,-anchor)] != -1} {
            grid rowconfigure $w 0 -weight 1
          } else {
            grid rowconfigure $w 0 -weight 1
            grid rowconfigure $w 2 -weight 1
          }
          grid rowconfigure $w 1 -weight 1
          grid $w.c -row 1 -column [expr $left ? 0 : 1] -sticky ns
          if {$data($w,options,-format) ne ""} {
            grid $w.f -row 1 -column [expr $left ? 1 : 0] -sticky ns
          }
        } else {
          set top [expr [string first "n" $data($w,options,-anchor)] != -1]
          if {[string first "w" $data($w,options,-anchor)] != -1} {
            grid columnconfigure $w 2 -weight 1
          } elseif {[string first "e" $data($w,options,-anchor)] != -1} {
            grid columnconfigure $w 0 -weight 1
          } else {
            grid columnconfigure $w 0 -weight 1
            grid columnconfigure $w 2 -weight 1
          }
          grid $w.c -row [expr $top ? 0 : 1] -column 1 -sticky ew
          if {$data($w,options,-format) ne ""} {
            grid $w.f -row [expr $top ? 1 : 0] -column 1 -sticky ew
          }
        } 
      }
      
      # Configure the canvases
      $w.c configure -bg $data($w,options,-background)
      $w.f configure -bg $data($w,options,-background)
        
      # Configure the line canvas items
      if {$orig_options($w,options,-linecolor) ne $data($w,options,-linecolor)} {
        $w.c itemconfigure line -fill $data($w,options,-linecolor)
      }
      if {$orig_options($w,options,-selectcolor) ne $data($w,options,-selectcolor)} {
        $w.c itemconfigure selection -fill $data($w,options,-selectcolor)
      }
      
      # Configure the font canvas items
      if {$orig_options($w,options,-fontcolor) ne $data($w,options,-fontcolor)} {
        $w.f itemconfigure date_string -fill $data($w,options,-fontcolor)
      }
      
      # Perform the initial draw if we are initializing
      if {$initialize || ($data($w,closest) eq "")} {
        redraw $w
      }
      
    }
    
  }
  
  ######################################################################
  # Handles the curselection command.
  proc curselection {w args} {
    
    variable data
    
    # Check the arguments
    if {[llength $args] != 0} {
      return -code error "Incorrect number of parameters given to the timeline::curselection command"
    }
    
    return [lsort $data($w,selection)]
    
  }

  ######################################################################
  # Handles the selection command.
  proc selection {w args} {
    
    variable data
    
    if {[set arglen [llength $args]] == 0} {
      return -code error "No subcommand was specified for the timeline::selection command"
    }
    
    switch [lindex $args 0] {
      clear {
        if {($arglen != 2) && ($arglen != 3)} {
          return -code error "Incorrect number of parameters given to the timeline::selection clear command"
        }
        selection_clear $w {*}[lrange $args 1 end]
      }
      includes {
        if {$arglen != 2} {
          return -code error "Incorrect number of parameters given to the timeline::selection includes command"
        }
        return [expr [lsearch $data($w,selection) [lindex $args 1]] != -1]
      }
      set {
        if {($arglen != 2) && ($arglen != 3)} {
          return -code error "Incorrect number of parameters given to the timeline::selection set command"
        }
        selection_set $w {*}[lrange $args 1 end]
      }
    }
    
  }
  
}
