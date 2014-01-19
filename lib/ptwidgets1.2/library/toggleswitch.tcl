#===============================================================
# Main toggleswitch package module
#
# Copyright (c) 2011-2012  Trevor Williams (phase1geo@gmail.com)
#===============================================================

package provide toggleswitch 1.2

namespace eval toggleswitch {

  array set data {}
  
  array set widget_options {
    -borderwidth            {borderWidth            BorderWidth}
    -command                {command                Command}
    -cursor                 {cursor                 Cursor}
    -font                   {font                   Font}
    -offbackground          {offBackground          Background}
    -offforeground          {offForeground          Foreground}
    -offvalue               {offValue               Value}
    -onbackground           {onBackground           Background}
    -onforeground           {onForeground           Foreground}
    -onvalue                {onValue                Value}
    -relief                 {relief                 Relief}
    -state                  {state                  State}
    -takefocus              {takeFocus              TakeFocus}
    -variable               {variable               Variable}
  }

  ###########################################################################
  # Main procedure to create the on/off switch.
  proc toggleswitch {w args} {
  
    variable data
    variable widget_options
    
    # Create window
    frame $w     -class ToggleSwitch -takefocus 0
    frame $w.on  -relief sunken -takefocus 0
    frame $w.off -relief sunken -takefocus 0
    
    pack [ttk::label $w.on.l  -text " ON"  -width 4 -takefocus 0]  -fill both -expand yes
    pack [ttk::label $w.off.l -text " OFF" -width 4 -takefocus 0] -fill both -expand yes
    
    grid columnconfigure $w 0 -weight 1
    grid columnconfigure $w 1 -weight 1
    grid $w.on  -row 0 -column 0 -sticky news
    grid $w.off -row 0 -column 1 -sticky news
    
    # Create switch
    update
    ttk::frame $w.sw -relief raised -takefocus 1 -width [winfo reqwidth $w.on] -height [winfo reqheight $w.on]
    
    # Default in the off position
    place $w.sw -x 0 -y 0
    
    # Initialize options
    # Initialize default options
    if {[array size data] == 0} {
      option add *ToggleSwitch.offBackground        white         widgetDefault
      option add *ToggleSwitch.onBackground         blue          widgetDefault
      option add *ToggleSwitch.offForeground        grey          widgetDefault
      option add *ToggleSwitch.onForeground         white         widgetDefault
      option add *ToggleSwitch.borderWidth          1             widgetDefault
      option add *ToggleSwitch.command              ""            widgetDefault
      option add *ToggleSwitch.cursor               ""            widgetDefault
      option add *ToggleSwitch.font                 ""            widgetDefault
      option add *ToggleSwitch.height               18            widgetDefault
      option add *ToggleSwitch.offValue             0             widgetDefault
      option add *ToggleSwitch.onValue              1             widgetDefault
      option add *ToggleSwitch.relief               flat          widgetDefault
      option add *ToggleSwitch.state                normal        widgetDefault
      option add *ToggleSwitch.takeFocus            1             widgetDefault
      option add *ToggleSwitch.variable             ""            widgetDefault
      option add *ToggleSwitch.width                60            widgetDefault
    }

    # Initialize the options array
    foreach opt [array names widget_options] {
      set data($w,$opt) [option get $w [lindex $widget_options($opt) 0] [lindex $widget_options($opt) 1]]
    }
    
    # Set the default value to off (0)
    set data($w,value) 0

    # Add the bindings
    bind $w.on    <Button-1>        "toggleswitch::off $w"
    bind $w.on.l  <Button-1>        "toggleswitch::off $w"
    bind $w.off   <Button-1>        "toggleswitch::on $w"
    bind $w.off.l <Button-1>        "toggleswitch::on $w"
    bind $w.sw    <ButtonPress-1>   "toggleswitch::press $w %X"
    bind $w.sw    <B1-Motion>       "toggleswitch::slide $w %X"
    bind $w.sw    <ButtonRelease-1> "toggleswitch::release $w %X"
    bind $w.sw    <space>           "toggleswitch::toggle $w"
    bind $w.sw    <FocusOut>        "toggleswitch::focus_next $w"
    bind $w       <FocusIn>         "focus $w.sw"

    # Configure the widget
    eval "configure 1 $w $args"
    
    # Rename and alias the tokenentry window
    rename ::$w $w
    interp alias {} ::$w {} toggleswitch::widget_cmd $w
    
    return $w
    
  }
  
  ###########################################################################
  # Changes focus to the next window after w.
  proc focus_next {w} {

    # Change the focus
    focus [tk_focusNext $w.sw]

  }

  ###########################################################################
  # Procedure called when the user clicks on the off position.  Moves the
  # switch frame to display the on label.
  proc on {w {from_program 0}} {

    variable data
    
    if {($from_program == 1) || ($data($w,-state) eq "normal")} {
    
      # Move the switch frame to display the on position
      place $w.sw -x [winfo reqwidth $w.on] -y 0
    
      # Set the current value to the value of -onvalue
      set data($w,value) 1
    
      # Set the global variable, if it is set
      if {$data($w,-variable) ne ""} {
        upvar #0 $data($w,-variable) var
        set var $data($w,-onvalue)
      }
    
      # If a command is specified, execute it now
      if {$data($w,-command) ne ""} {
        eval "$data($w,-command)"
      }
      
    }
    
  }
  
  ###########################################################################
  # Procedure called when the user clicks on the on position.  Moves the
  # switch frame to display the off label.
  proc off {w {from_program 0}} {
  
    variable data
    
    if {($from_program == 1) || ($data($w,-state) eq "normal")} {
    
      # Move the switch frame to display the off position
      place $w.sw -x 0 -y 0
    
      # Set the current value to the value of -offvalue
      set data($w,value) 0
    
      # Set the global variable, if it is set
      if {$data($w,-variable) ne ""} {
        upvar #0 $data($w,-variable) var
        set var $data($w,-offvalue)
      }
    
      # If a command is specified, execute it now
      if {$data($w,-command) ne ""} {
        eval "$data($w,-command)"
      }
      
    }
    
  }
  
  ###########################################################################
  # Procedure called when the left button is pressed.  Records the position
  # of the cursor within switch frame.
  proc press {w x} {
  
    variable data
    
    set data($w,switchx) [expr $x - [winfo rootx $w.sw]]
  
  }
  
  ###########################################################################
  # Procedure called when the mouse cursor is moved when the left-button is
  # pressed.  Moves the switch frame to match the motion of the mouse while
  # keeping the switch frame within the bounds of the switch.
  proc slide {w x} {
  
    variable data
    
    if {$data($w,-state) eq "normal"} {
    
      set next_x [expr ($x - $data($w,switchx)) - [winfo rootx $w]]
    
      if {$next_x < 0} {
        set next_x 0
      } elseif {[expr $next_x + [winfo width $w.sw]] > [winfo width $w]} {
        set next_x [expr [winfo width $w] - [winfo width $w.sw]]
      }
    
      place $w.sw -x $next_x -y 0
    
    }
    
  }
  
  ###########################################################################
  # Procedure called when the left-button is released.  Causes the switch
  # frame to go to either the on or off position based on the location of
  # of the switch frame.
  proc release {w x} {
  
    variable data
    
    if {$data($w,-state) eq "normal"} {
    
      set next_x [expr ($x - $data($w,switchx)) - [winfo rootx $w]]
    
      if {$next_x < [expr [winfo width $w.sw] / 2]} {
        off $w
      } else {
        on $w
      }
      
    }
    
  }
  
  ###########################################################################
  # Procedure to handle all of the user command requests.
  proc widget_cmd {w args} {
  
    if {[llength $args] == 0} {
      return -code error "toggleswitch widget called without a command"
    }

    set cmd  [lindex $args 0]
    set opts [lrange $args 1 end]

    switch $cmd {
      configure { return [eval "toggleswitch::configure 0 $w $opts"] }
      cget      { return [eval "toggleswitch::cget $w $opts"] }
      switchoff { eval "toggleswitch::switchoff $w $opts" }
      invoke    { eval "toggleswitch::invoke $w $opts" }
      switchon  { eval "toggleswitch::switchon $w $opts" }
      toggle    { eval "toggleswitch::toggle $w $opts" }
      default   { return -code error "Unknown toggleswitch command ($cmd)" }
    }
    
  }
  
  #-------------------------------------------------------------------------
  
  ###########################################################################
  # Procedure handles the configuration command.
  proc configure {initialize w args} {
  
    variable widget_options
    variable data
    
    if {([llength $args] == 0) && !$initialize} {
    
      set results [list]
      
      foreach opt [lsort [array names widget_options]] {
        if {[llength $widget_options($opt)] == 2} {
          set opt_name    [lindex $widget_options($opt) 0]
          set opt_class   [lindex $widget_options($opt) 1]
          set opt_default [option get $w $opt_name $opt_class]
          if {[info exists data($w,$opt)]} {
            lappend results [list $opt $opt_name $opt_class $opt_default $data($w,$opt)]
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
        if {[info exists data($w,$opt)]} {
          return [list $opt $opt_name $opt_class $opt_default $data($w,$opt)]
        } else {
          return [list $opt $opt_name $opt_class $opt_default ""]
        }
      }
      
      return -code error "ToggleSwitch configuration option [lindex $args 0] does not exist"
    
    } else {

      # Parse the arguments
      foreach {name value} $args {
        if {[info exists data($w,$name)]} {
          set data($w,$name) $value
        } else {
          return -code error "Illegal option given to the toggleswitch configure command ($name)"
        }
      }
      
      # Set the current value
      if {$data($w,-variable) ne ""} {
        upvar #0 $data($w,-variable) var
        if {$var eq $data($w,-onvalue)} {
          set data($w,value) 1
          on $w 1
        } else {
          set data($w,value) 0
          off $w 1
        }
      }
      
      # Update the widget states
      if {$data($w,-state) eq "normal"} {
        $w.on    configure -background $data($w,-onbackground)
        $w.on.l  configure -background $data($w,-onbackground) -foreground $data($w,-onforeground)
        $w.off   configure -background $data($w,-offbackground)
        $w.off.l configure -background $data($w,-offbackground) -foreground $data($w,-offforeground)
      } else {
        $w.on    configure -background grey
        $w.on.l  configure -background grey  -foreground white
        $w.off   configure -background white
        $w.off.l configure -background white -foreground grey
      }
      
      # Set the cursor
      $w configure -cursor $data($w,-cursor)

    }

  }
  
  ###########################################################################
  # Procedure that handles the cget command.
  proc cget {w args} {
  
    variable data

    if {[llength $args] != 1} {
      return -code error "Incorrect number of parameters given to the toggleswitch cget command"
    }

    if {[info exists data($w,[lindex $args 0])]} {
      return $data($w,[lindex $args 0])
    } else {
      return -code error "Illegal option given to the toggleswitch cget command ([lindex $args 0])"
    }

  }
  
  ###########################################################################
  # Procedure which turns the switch to the off position.
  proc switchoff {w args} {
  
    variable data
    
    if {[llength $args] != 0} {
      return -code error "Incorrect number of parameters given to the toggleswitch::switchoff command"
    }
    
    # Switch to the off position
    off $w 1
  
  }
  
  ###########################################################################
  # Procedure which invokes the widget.
  proc invoke {w args} {
  
    variable data
    
    if {[llength $args] != 0} {
      return -code error "Incorrect number of parameters given to the toggleswitch::invoke command"
    }
    
    if {$data($w,value)} {
      on $w 1
    } else {
      off $w 1
    }
  
  }
  
  ###########################################################################
  # Procedure which turns the switch to the on position.
  proc switchon {w args} {
    
    variable data
    
    if {[llength $args] != 0} {
      return -code error "Incorrect number of parameters given to the toggleswitch::switchon command"
    }
    
    # Switch to the on position
    on $w 1
  
  }
  
  ###########################################################################
  # Procedure which toggles the current value of the switch.
  proc toggle {w args} {
  
    variable data
    
    if {[llength $args] != 0} {
      return -code error "Incorrect number of parameters given to the toggleswitch::toggle command"
    }
    
    if {$data($w,value)} {
      off $w 1
    } else {
      on $w 1
    }
  
  }

}
