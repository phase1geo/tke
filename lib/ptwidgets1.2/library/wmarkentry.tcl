#===============================================================
# Main wmarkentry package module
#
# Copyright (c) 2011-2012  Trevor Williams (phase1geo@gmail.com)
#===============================================================

package provide wmarkentry 1.2

namespace eval wmarkentry {

  array set options {}
  array set state   {}
  array set textvar {}

  array set entry_options {
    -background          1
    -bg                  1
    -borderwidth         1
    -bd                  1
    -cursor              1
    -disabledbackground  1
    -disabledforeground  1
    -exportselection     1
    -font                1
    -highlightbackground 1
    -highlightcolor      1
    -highlightthickness  1
    -insertbackground    1
    -insertborderwidth   1
    -insertofftime       1
    -insertontime        1
    -insertwidth         1
    -invalidcommand      1
    -invcmd              1
    -justify             1
    -readonlybackground  1
    -relief              1
    -selectbackground    1
    -selectborderwidth   1
    -selectforeground    1
    -state               1
    -takefocus           1
    -validate            1
    -validatecommand     1
    -vcmd                1
    -width               1
    -xscrollcommand      1
  }

  array set widget_options {
    -background             {background             Background}
    -bg                     -background
    -borderwidth            {borderWidth            BorderWidth}
    -bd                     -borderwidth
    -cursor                 {cursor                 Cursor}
    -disabledbackground     {disabledBackground     DisabledBackground}
    -disabledforeground     {disabledForeground     DisabledForeground}
    -exportselection        {exportSelection        ExportSelection}
    -font                   {font                   Font}
    -foreground             {foreground             Foreground}
    -fg                     -foreground
    -highlightbackground    {highlightBackground    HighlightBackground}
    -highlightcolor         {highlightColor         HighlightColor}
    -highlightthickness     {highlightThickness     HighlightThickness}
    -insertbackground       {insertBackground       InsertBackground}
    -insertborderwidth      {insertBorderWidth      InsertBorderWidth}
    -insertofftime          {insertOffTime          InsertOffTime}
    -insertontime           {insertOnTime           InsertOnTime}
    -insertwidth            {insertWidth            InsertWidth}
    -invalidcommand         {invalidCommand         InvalidCommand}
    -invcmd                 -invalidcommand
    -justify                {justify                Justify}
    -readonlybackground     {readonlyBackground     ReadonlyBackground}
    -relief                 {relief                 Relief}
    -selectbackground       {selectBackground       Background}
    -selectborderwidth      {selectBorderWidth      BorderWidth}
    -selectforeground       {selectForeground       Foreground}
    -show                   {show                   Show}
    -state                  {state                  State}
    -takefocus              {takeFocus              TakeFocus}
    -textvariable           {textVariable           Variable}
    -validate               {validate               Validate}
    -validatecommand        {validateCommand        ValidateCommand}
    -vcmd                   -validatecommand
    -watermark              {watermark              Watermark}
    -watermarkforeground    {watermarkForeground    Foreground}
    -width                  {width                  Width}
    -xscrollcommand         {xScrollCommand         ScrollCommand}
  }

  ###########################################################################
  # Main procedure which creates the given window and initializes it.
  proc wmarkentry {w args} {

    variable options
    variable widget_options
    variable state

    # Create the frame
    frame $w -class WMarkEntry -relief flat -takefocus 0

    # Initially, we pack the frame with a text widget
    entry $w.e -highlightthickness 0 -relief flat -bg white -takefocus 1

    # Set the bind tags to include a user tag and the WMarkEntryEntry tag
    bindtags $w.e [linsert [bindtags $w.e] 1 [entrytag $w] WMarkEntryEntry]

    # Pack the text widget
    pack $w.e -side left -fill both -expand yes

    # Initialize default options
    if {[array size options] == 0} {
      foreach opt [array names widget_options] {
        if {![catch "$w.e configure $opt" rc]} {
          if {[llength $widget_options($opt)] != 1} {
            if {$opt eq "-background"} {
              set default_value "white"
            } elseif {$opt eq "-relief"} {
              set default_value "flat"
            } else {
              set default_value [lindex $rc 4]
            }
            option add *WMarkEntry.[lindex $rc 1] $default_value
          }
        }
      }
      option add *WMarkEntry.watermark           ""
      option add *WMarkEntry.watermarkForeground "light gray"
      option add *WMarkEntry.show                ""
    }

    # Initialize variables
    set state($w) "empty"

    # Initialize the options array
    foreach opt [array names widget_options] {
      if {[llength $widget_options($opt)] != 1} {
        set options($w,$opt) [option get $w [lindex $widget_options($opt) 0] [lindex $widget_options($opt) 1]]
      }
    }

    # Setup bindings
    if {[llength [bind WMarkEntryEntry]] == 0} {

      bind $w <FocusIn>       {
        wmarkentry::focus_in %W
      }
      bind WMarkEntryEntry <Left>          {
  	if {[wmarkentry::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind WMarkEntryEntry <Right>         {
        if {[wmarkentry::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind WMarkEntryEntry <Down>          {
        if {[wmarkentry::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind WMarkEntryEntry <Up>            {
        if {[wmarkentry::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind WMarkEntryEntry <Button-1>      {
        if {[wmarkentry::handle_text_movement [winfo parent %W]]} {
          %W icursor 0
          focus %W
          break
        }
      }
      bind WMarkEntryEntry <B1-Motion>     {
        if {[wmarkentry::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind WMarkEntryEntry <B1-Leave>      {
        if {[wmarkentry::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind WMarkEntryEntry <Control-k>     {
        if {$wmarkentry::state([winfo parent %W]) eq "empty"} {
          break
        } else {
          wmarkentry::handle_state [winfo parent %W] 0
        }
      }
      bind WMarkEntryEntry <Control-a>     {
        if {$wmarkentry::state([winfo parent %W]) eq "empty"} {
          break
        }
      }
      bind WMarkEntryEntry <Control-A> {
        if {$wmarkentry::state([winfo parent %W]) eq "empty"} {
          break
        }
      }
      bind WMarkEntryEntry <End>           {
        if {$wmarkentry::state([winfo parent %W]) eq "empty"} {
          break
        }
      }
      bind WMarkEntryEntry <Control-e>     {
        if {$wmarkentry::state([winfo parent %W]) eq "empty"} {
          break
        }
      }
      bind WMarkEntryEntry <Control-E>     {
        if {$wmarkentry::state([winfo parent %W]) eq "empty"} {
          break
        }
      }
      bind WMarkEntryEntry <<PasteSelection>> {
        if {[wmarkentry::paste_selection [winfo parent %W]]} {
          break
        }
      }
      bind WMarkEntryEntry <Any-KeyPress>     {
        wmarkentry::keypress [winfo parent %W] %A
      }

    }

    # Configure the widget
    eval "configure 1 $w $args"

    # Rename and alias the wmarkentry window
    rename ::$w $w
    interp alias {} ::$w {} wmarkentry::widget_cmd $w

    return $w

  }

  ###########################################################################
  # Handles a FocusIn event on the widget.
  proc focus_in {w} {

    variable options
    variable state

    # If the widget is disabled, don't continue
    if {$state($w) eq "disabled"} {
      return
    }

    # Set the focus to the text field
    focus $w.e

  }

  ###########################################################################
  # This procedure is called whenever the user presses a key in the text box.
  proc keypress {w c} {

    # Update the current state
    if {($c eq "") || ($c eq "\b") || ($c eq "\t") || ($c eq "\n") || ($c eq "\r")} {
      handle_state $w 0
    } else {
      handle_state $w 1
    }

  }

  ###########################################################################
  # This procedure is called whenever the user performs a paste selection event
  # on the widget.
  proc paste_selection {w} {

    if {[catch "tk::GetSelection $w PRIMARY"]} {
      return 1
    } else {
      handle_state $w 1
    }

    return 0

  }

  ###########################################################################
  # Handles any sort of movement of the insertion cursor or selection within
  # the entry widget.
  proc handle_text_movement {w} {

    variable state

    # If we are empty, always set the insertion cursor to 1.0
    if {$state($w) eq "empty"} {
      $w.e icursor 0
      $w.e selection clear
      focus $w.e
      return 1
    }

    return 0

  }

  ###########################################################################
  # Handles a Control-x binding on the given widget.
  proc handle_cut {w} {

    if {![$w.e selection present]} {
      clipboard clear
      clipboard append [$w.txt get]
      $w.e delete 0 end
      handle_state $w 1
    } else {
      clipboard clear
      clipboard append [string range [$w.e get] [$w.e index sel.first] [$w.e index sel.last]]
      $w.e delete sel.first sel.last
      handle_state $w 1
    }

  }

  ###########################################################################
  # Handles a Control-c binding on the given widget.
  proc handle_copy {w} {

    if {![$w.e selection present]} {
      clipboard clear
      clipboard append [$w.e get]
    } else {
      clipboard clear
      clipboard append [string range [$w.e get] [$w.e index sel.first] [$w.e index sel.last]]
    }

  }

  ###########################################################################
  # Handles a Control-v binding on the given widget.
  proc handle_paste {w} {

    # Handle the current state
    handle_state $w 1

    # Insert the clipboard text
    $w.e insert insert [clipboard get]

  }

  ###########################################################################
  # Handles the current state of the widget (empty/non-empty) and handles
  # any watermark display (or removal of the display).
  proc handle_state {w keyed} {

    variable state
    variable options

    # If we are in the empty state
    if {$state($w) eq "empty"} {

      $w.e delete 0 end

      if {$keyed} {
        set state($w) "non-empty"
        $w.e configure -foreground $options($w,-foreground) -show $options($w,-show)
      } else {
        $w.e configure -foreground $options($w,-watermarkforeground)
        $w.e insert end $options($w,-watermark)
        $w.e icursor 0
      }

    # Otherwise, we are in the not-empty state
    } elseif {$state($w) eq "non-empty"} {

      # If the widget is empty, set the state to empty and fill it with the
      # empty string.
      after idle [list wmarkentry::handle_non_empty_state $w]

    }

  }

  ###########################################################################
  # Handles the non-empty state of the widget.
  proc handle_non_empty_state {w} {

    variable state
    variable options

    if {[string trim [$w.e get]] eq ""} {
      set state($w) "empty"
      $w.e configure -foreground $options($w,-watermarkforeground) -show ""
      $w.e insert end $options($w,-watermark)
      $w.e icursor 0
    }

  }

  ###########################################################################
  # Handles a specified textvariable read/write request.
  proc handle_textvariable {w name1 name2 op} {

    variable options

    if {$options($w,-textvariable) eq $name1} {
      upvar #0 $options($w,-textvariable) textvar
      if {$op eq "write"} {
        delete $w 0 end
        insert $w end $textvar
      } elseif {$op eq "read"} {
        set textvar [get $w]
      }
    }

  }

  ######################################################################
  # Validation command wrapper.
  proc validate_command {w cmd} {

    variable state

    if {$state($w) eq "empty"} {
      return 1
    }

    return [{*}$cmd]

  }

  ###########################################################################
  # Handles all commands.
  proc widget_cmd {w args} {

    if {[llength $args] == 0} {
      return -code error "wmarkentry widget called without a command"
    }

    set cmd  [lindex $args 0]
    set opts [lrange $args 1 end]

    switch $cmd {
      entrytag  { return [eval "wmarkentry::entrytag $w"] }
      configure { return [eval "wmarkentry::configure 0 $w $opts"] }
      cget      { return [eval "wmarkentry::cget $w $opts"] }
      insert    { return [eval "wmarkentry::insert $w $opts"] }
      delete    { return [eval "wmarkentry::delete $w $opts"] }
      get       { return [eval "wmarkentry::get $w"] }
      selection { return [eval "wmarkentry::selection $w $opts"] }
      icursor   { return [eval "wmarkentry::icursor $w $opts"] }
      index     { return [eval "wmarkentry::index $w $opts"] }
      default   { return [eval "$w.e $cmd $opts"] }
    }

  }

  ###########################################################################
  # USER COMMANDS
  ###########################################################################

  ###########################################################################
  # Returns the name of the bind tag associated with the given widget.
  proc entrytag {w} {

    return "entry$w"

  }

  ###########################################################################
  # Main configuration routine.
  proc configure {initialize w args} {

    variable options
    variable entry_options
    variable widget_options
    variable state

    if {([llength $args] == 0) && !$initialize} {

      set results [list]

      foreach opt [lsort [array names widget_options]] {
        if {[llength $widget_options($opt)] == 2} {
          set opt_name    [lindex $widget_options($opt) 0]
          set opt_class   [lindex $widget_options($opt) 1]
          set opt_default [option get $w $opt_name $opt_class]
          if {[info exists entry_options($opt)]} {
            lappend results [list $opt $opt_name $opt_class $opt_default [$w.e cget $opt]]
          } elseif {[info exists options($w,$opt)]} {
            lappend results [list $opt $opt_name $opt_class $opt_default $options($w,$opt)]
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
        if {[info exists entry_options($opt)]} {
          return [list $opt $opt_name $opt_class $opt_default [$w.e cget $opt]]
        } elseif {[info exists options($w,$opt)]} {
          return [list $opt $opt_name $opt_class $opt_default $options($w,$opt)]
        } else {
          return [list $opt $opt_name $opt_class $opt_default ""]
        }
      }

      return -code error "WMarkEntry configuration option [lindex $args 0] does not exist"

    } else {

      # Save the original contents
      array set orig_options [array get options]

      # Parse the arguments
      foreach {name value} $args {
        if {$name eq "-fg"} {
          set name "-foreground"
        } elseif {($name eq "-vcmd") || ($name eq "-validatecommand")} {
          set value [list wmarkentry::validate_command $w $value]
        }
        if {[info exists entry_options($name)]} {
          $w.e configure $name $value
        } elseif {[info exists options($w,$name)]} {
          set options($w,$name) $value
        } else {
          return -code error "Illegal option given to the wmarkentry configure command ($name)"
        }
      }

      # Handle the textvariable option, if it was specified
      if {$orig_options($w,-textvariable) ne $options($w,-textvariable)} {
        catch "trace remove variable $orig_options($w,-textvariable) {write read} {wmarkentry::handle_textvariable $w}"
        if {$options($w,-textvariable) ne ""} {
          trace add variable $options($w,-textvariable) {write read} "wmarkentry::handle_textvariable $w"
          handle_textvariable $w $options($w,-textvariable) "" write
        }
      }

      # Make sure that the state is handled correctly
      handle_state $w 0

    }

  }

  ###########################################################################
  # Gets configuration option value(s).
  proc cget {w args} {

    variable options
    variable entry_options

    if {[llength $args] != 1} {
      return -code error "Incorrect number of parameters given to the wmarkentry cget command"
    }

    if {[set name [lindex $args 0]] eq "-fg"} {
      set name "-foreground"
    }

    if {[info exists entry_options($name)]} {
      return [$w.e cget $name]
    } elseif {[info exists options($w,$name)]} {
      return $options($w,$name)
    } else {
      return -code error "Illegal option given to the wmarkentry cget command ([lindex $args 0])"
    }

  }

  ###########################################################################
  # Wrapper around the entry insert command.  Handles any needed changes to the
  # watermark.
  proc insert {w args} {

    # If the user is inserted a non-empty string of data, make sure the state
    # is handled properly.
    if {[lindex $args 1] ne ""} {
      handle_state $w 1
    } else {
      handle_state $w 0
    }

    return [eval "$w.e insert $args"]

  }

  ###########################################################################
  # Wrapper around the entry delete command.  Handles any needed changes to the
  # watermark.
  proc delete {w args} {

    # Perform the deletion command
    set retval [eval "$w.e delete $args"]

    # Handle any needed state changes
    handle_state $w 0

  }

  ###########################################################################
  # Wrapper around the entry get command.  Handles the case where the state is
  # empty (returns empty string).
  proc get {w} {

    variable state

    if {$state($w) eq "empty"} {
      return ""
    } else {
      return [$w.e get]
    }

  }

  ###########################################################################
  # Wrapper around the entry selection command.  Handles any needed changes
  # to the watermark.
  proc selection {w args} {

    variable state

    switch [lindex $args 0] {
      adjust  {
        if {$state($w) eq "empty"} {
          return [$w.e selection adjust 0]
        } else {
          return [eval "$w.e selection $args"]
        }
      }
      clear   {
        return [eval "$w.e selection $args"]
      }
      from    {
        if {$state($w) eq "empty"} {
          return [$w.e selection from 0]
        } else {
          return [eval "$w.e selection $args"]
        }
      }
      present {
        if {$state($w) eq "empty"} {
          return 0
        } else {
          return [eval "$w.e selection present"]
        }
      }
      range   {
        if {$state($w) ne "empty"} {
          eval "$w.e selection $args"
        }
      }
      to      {
        if {$state($w) eq "empty"} {
          return [$w.e selection to 0]
        } else {
          return [eval "$w.e selection $args"]
        }
      }
    }

  }

  ###########################################################################
  # Wrapper around the entry icursor command.  Handles any needed changes
  # to the watermark.
  proc icursor {w args} {

    variable state

    if {$state($w) eq "empty"} {
      return [$w.e icursor 0]
    } else {
      return [eval "$w.e icursor $args"]
    }

  }

  ###########################################################################
  # Wrapper around the entry index command.
  proc index {w args} {

    variable state

    if {($state($w) eq "empty") && ([lindex $args 0] eq "end")} {
      return 0
    } else {
      return [eval "$w.e index $args"]
    }

  }

  namespace export *

}
