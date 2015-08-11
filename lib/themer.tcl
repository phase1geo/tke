#!wish8.5

# TKE - Advanced Programmer's Editor
# Copyright (C) 2014  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:    themer.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/04/2013
# Brief:   Converts a *.tmTheme file to a *.tketheme file.
######################################################################

if {[file tail $argv0] eq "themer.tcl"} {

  set tke_dir [file dirname [file dirname [file normalize $argv0]]]

  package require msgcat

  source [file join $tke_dir lib utils.tcl]

}

namespace eval themer {

  variable theme_dir      [file join $::tke_dir data themes]
  variable tmtheme        ""
  variable write_callback ""

  array set widgets     {}
  array set all_scopes  {}
  array set orig_labels {}
  array set show_vars   {}
  array set labels      {}

  array set label_index {
    color      0
    tagpos     1
    scope      2
    show       3
    changed    4
  }

  array set scope_map {
    comment              comments
    keyword              keywords
    string               strings
    entity               punctuation
    entity.name.tag      punctuation
    punctuation          punctuation
    meta.preprocessor.c  precompile
    other.preprocessor.c precompile
    constant             numbers
    constant.numeric     numbers
    meta.tag             miscellaneous1
    support              miscellaneous1
    support.function     miscellaneous1
    support.type         miscellaneous1
    variable             miscellaneous2
    variable.other       miscellaneous2
    variable.parameter   miscellaneous2
    storage              miscellaneous3
    constant.other       miscellaneous3
  }

  array set base_labels {
    background        {""       ""            "" 1 0}
    foreground        {""       ""            "" 1 0}
    line_number       {""       ""            "" 1 0}
    warning_width     {""       ""            "" 1 0}
    difference_sub    {""       ""            "" 0 0}
    difference_add    {""       ""            "" 0 0}
    select_background {"blue"   ""            "" 0 0}
    select_foreground {"white"  ""            "" 0 0}
    border_highlight  {"yellow" ""            "" 1 0}
    cursor            {""       "-background" "" 1 0}
    keywords          {""       "-foreground" "" 1 0}
    comments          {""       "-foreground" "" 1 0}
    strings           {""       "-foreground" "" 1 0}
    numbers           {""       "-foreground" "" 1 0}
    punctuation       {""       "-foreground" "" 1 0}
    precompile        {""       "-foreground" "" 1 0}
    miscellaneous1    {""       "-foreground" "" 1 0}
    miscellaneous2    {""       "-foreground" "" 1 0}
    miscellaneous3    {""       "-foreground" "" 1 0}
  }

  # Add trace to the labels array
  trace variable themer::labels    w themer::handle_label_change
  trace variable themer::show_vars w themer::handle_show_vars_change

  #############################################################
  # Called whenever a menu item is selected in the scope menu.
  proc handle_label_change {name1 lbl op} {

    variable labels
    variable label_index
    variable widgets
    
    # Don't continue if the UI isn't built yet
    if {![info exists widgets(txt)]} {
      return
    }

    # Get the color from the label
    set color [lindex $labels($lbl) $label_index(color)]

    # Set the button and label
    $widgets(b:$lbl) configure -text [lindex $labels($lbl) $label_index(scope)]

    # Set the image
    if {$lbl eq "background"} {
      foreach {l info} [array get labels] {
        if {[set lcolor [lindex $info $label_index(color)]] ne ""} {
          set_button_image $l $lcolor
        }
      }
      foreach tlbl [list warning_width line_number] {
        if {[lindex $labels($tlbl) $label_index(changed)] == 0} {
          lset labels($tlbl) $label_index(color) [utils::auto_adjust_color $color 40]
        }
      }
      if {[lindex $labels(difference_sub) $label_index(changed)] == 0} {
        lset labels(difference_sub) $label_index(color) [utils::auto_mix_colors $color r 30]
      }
      if {[lindex $labels(difference_add) $label_index(changed)] == 0} {
        lset labels(difference_add) $label_index(color) [utils::auto_mix_colors $color g 30]
      }
    } else {
      set_button_image $lbl $color
    }

    # Highlight the sample textbox
    highlight

  }

  ######################################################################
  # Handles any changes to the show_vars variable.
  proc handle_show_vars_change {name1 lbl op} {

    # Highlight the sample textbox
    highlight

  }

  ######################################################################
  # Generates a valid RGB color.
  proc normalize_color {color} {

    if {[string index $color 0] eq "#"} {
      return [string range $color 0 6]
    } else {
      return $color
    }

  }

  ######################################################################
  # Sets the image for the type button.
  proc set_button_image {lbl color} {

    variable widgets
    variable labels
    variable label_index

    # Delete the current image
    if {[set img [$widgets(b:$lbl) cget -image]] ne ""} {
      image delete $img
    }

    # Create the image
    set img [image create bitmap -file [file join $::tke_dir lib images color.bmp] \
                                 -background [lindex $labels(background) $label_index(color)] -foreground $color]

    # Set the image
    $widgets(b:$lbl) configure -image $img

  }

  ######################################################################
  # Reads the given TextMate theme file and extracts the relevant information
  # for tke's needs.
  proc read_tmtheme {theme} {

    variable labels
    variable scope_map
    variable all_scopes
    variable tmtheme
    variable orig_labels
    variable widgets
    variable label_index

    set tmtheme $theme

    if {![catch { open $theme r } rc]} {

      # Read the contents of the file into 'content' and close the file
      set content [string map {\n { }} [read $rc]]
      close $rc

      array set depth {
        plist  0
        array  0
        dict   0
        key    0
        string 0
      }

      set scope       0
      set foreground  0
      set background  0
      set caret       0
      set scope_types ""

      while {[regexp {\s*([^<]*)\s*<(/?\w+)[^>]*>(.*)$} $content -> value element content]} {
        if {[string index $element 0] eq "/"} {
          set element [string range $element 1 end]
          switch $element {
            key {
              switch $value {
                scope      { set scope      1 }
                foreground { set foreground 1 }
                background { set background 1 }
                caret      { set caret      1 }
              }
            }
            string {
              if {$scope} {
                set scope       0
                set scope_types $value
              } elseif {$foreground} {
                set foreground 0
                set color      [normalize_color $value]
                if {$scope_types eq ""} {
                  lset labels(foreground) $label_index(color) $color
                  lset labels(foreground) $label_index(scope) "foreground"
                  set all_scopes(foreground) $color
                } else {
                  foreach scope_type [string map {, { }} $scope_types] {
                    if {[info exists scope_map($scope_type)]} {
                      set lbl $scope_map($scope_type)
                      lset labels($lbl) $label_index(color) $color
                      lset labels($lbl) $label_index(scope) $scope_type
                    }
                    set all_scopes($scope_type) $color
                  }
                }
              } elseif {$background} {
                set background 0
                set color      [normalize_color $value]
                if {$scope_types eq ""} {
                  lset labels(background)    $label_index(color) $color
                  lset labels(background)    $label_index(scope) "background"
                  lset labels(warning_width) $label_index(color) [utils::auto_adjust_color $color 40]
                  set all_scopes(background) $color
                }
              } elseif {$caret} {
                set caret 0
                set color [normalize_color $value]
                if {$scope_types eq ""} {
                  lset labels(cursor) $label_index(color) $color
                  lset labels(cursor) $label_index(scope) "cursor"
                  set all_scopes(cursor) $color
                }
              }
            }
          }
          incr depth($element) -1
        } else {
          incr depth($element)
        }
      }

    } elseif {[file tail $::argv0] eq "themer.tcl"} {

      puts [msgcat::mc "ERROR:  Unable to read %s" $theme]
      puts $rc
      exit 1

    }

    # Save the labels array to orig_labels
    array set orig_labels [array get labels]
    
  }

  ######################################################################
  # Reads the contents of the tketheme and stores the results
  proc read_tketheme {theme} {

    variable labels
    variable label_index
    variable orig_labels

    if {![catch { open $theme r } rc]} {

      # Read the contents from the file and close
      array set contents [read $rc]
      close $rc

      # Store the contents into the labels array
      foreach {lbl info} [array get labels] {
        if {[info exists contents($lbl)]} {
          lset labels($lbl) $label_index(color) $contents($lbl)
        }
      }

      # Save the labels array to orig_labels
      array set orig_labels [array get labels]

    } elseif {[file tail $::argv0] eq "themer.tcl"} {

      puts [msgcat::mc "ERROR:  Unable to read %s" $theme]
      puts $rc
      exit 1

    }

  }

  ######################################################################
  # Displays a window showing all of the current themes.
  proc get_theme {} {

    # Initialize variables
    set w            ".thrwin"
    set ::theme_name ""

    # Create the window
    toplevel     $w
    wm title     $w [msgcat::mc "Select theme"]
    wm transient $w .
    wm resizable $w 0 0

    ttk::frame     $w.tf
    listbox        $w.tf.lb -height 8 -selectmode "single" -yscrollcommand "$w.tf.vb set"
    ttk::scrollbar $w.tf.vb -orient vertical -command "$w.tf.lb yview"

    grid rowconfigure    $w.tf 0 -weight 1
    grid columnconfigure $w.tf 0 -weight 1
    grid $w.tf.lb -row 0 -column 0 -sticky news
    grid $w.tf.vb -row 0 -column 1 -sticky ns

    # Figure out the width of the buttons
    set bwidth [msgcat::mcmax "OK" "Cancel"]

    ttk::frame  $w.bf
    ttk::button $w.bf.ok -text [msgcat::mc "OK"] -width $bwidth -command {
      set ::theme_name [.thrwin.tf.lb get [.thrwin.tf.lb curselection]]
      destroy .thrwin
    }
    ttk::button $w.bf.cancel -text [msgcat::mc "Cancel"] -width $bwidth -command {
      destroy .thrwin
    }

    pack $w.bf.cancel -side right -padx 2 -pady 2
    pack $w.bf.ok     -side right -padx 2 -pady 2

    pack $w.tf -fill x
    pack $w.bf -fill x

    bind $w.tf.lb <Return> {
      set ::theme_name [.thrwin.tf.lb get [.thrwin.tf.lb curselection]]
      destroy .thrwin
    }
    bind $w.tf.lb <Double-Button-1> {
      set ::theme_name [.thrwin.tf.lb get [.thrwin.tf.lb curselection]]
      destroy .thrwin
    }

    # Get the theme names
    foreach theme [lsort [glob -tails -directory [file join $::tke_dir data themes] *.tketheme]] {
      $w.tf.lb insert end [file rootname $theme]
    }
    $w.tf.lb selection set 0

    # Center the window and grab the focus
    ::tk::PlaceWindow $w widget .
    ::tk::SetFocusGrab $w $w

    # Put the focus on the listbox
    focus $w.tf.lb

    # Wait for the window to be closed
    tkwait window $w

    # Release the grab/focus
    ::tk::RestoreFocusGrab $w $w

    if {$::theme_name ne ""} {
      return [file join $::tke_dir data themes ${::theme_name}.tketheme]
    } else {
      return ""
    }

  }

  ######################################################################
  # Displays a window that gets the name of a theme file.
  proc get_save_name {} {

    # Initialize variables
    set w            "[get_path].swin"
    set ::theme_name ""

    # Create the window
    toplevel     $w
    wm title     $w [msgcat::mc "Enter theme name"]
    wm transient $w [get_win]
    wm resizable $w 0 0

    ttk::frame $w.tf
    ttk::label $w.tf.l -text [msgcat::mc "Name:"]
    ttk::entry $w.tf.e -validate key -invalidcommand bell -validatecommand {
      [themer::get_path].swin.bf.ok configure \
        -state [expr {([string length %P] eq "") ? "disabled" : "normal"}]
      return 1
    }

    pack $w.tf.l -side left -padx 2 -pady 2
    pack $w.tf.e -side left -fill x -padx 2 -pady 2

    set bwidth [msgcat::mcmax "OK" "Cancel"]

    ttk::frame  $w.bf
    ttk::button $w.bf.ok -text [msgcat::mc "OK"] -width $bwidth -state disabled -command {
      set top          [themer::get_path]
      set ::theme_name [$top.swin.tf.e get]
      destroy $top.swin
    }
    ttk::button $w.bf.cancel -text [msgcat::mc "Cancel"] -width $bwidth -command {
      destroy [themer::get_path].swin
    }

    pack $w.bf.cancel -side right -padx 2 -pady 2
    pack $w.bf.ok     -side right -padx 2 -pady 2

    pack $w.tf -fill x
    pack $w.bf -fill x

    bind $w.tf.e <Return> {
      set top [themer::get_path]
      if {[set ::theme_name [$top.swin.tf.e get]] ne ""} {
        destroy $top.swin
      }
    }

    # Center the window and grab the focus
    ::tk::PlaceWindow $w widget [get_win]
    ::tk::SetFocusGrab $w $w

    # Focus on the entry
    focus $w.tf.e

    # Wait for the window to be closed
    tkwait window $w

    # Release the grab/focus
    ::tk::RestoreFocusGrab $w $w

    if {$::theme_name ne ""} {
      return "[file tail [file rootname $::theme_name]].tketheme"
    } else {
      return ""
    }

  }

  ######################################################################
  # Writes the TKE theme file to the theme directory.
  proc write_tketheme {} {

    variable theme_dir
    variable tmtheme
    variable labels
    variable label_index
    variable write_callback

    # If we don't have a theme name, get one
    if {$tmtheme eq ""} {
      if {[set tmtheme [get_save_name]] eq ""} {
        return 0
      }
    }

    # Get the basename of the tmtheme file
    set basename [file rootname [file tail $tmtheme]]

    if {![catch { open [file join $theme_dir $basename.tketheme] w } rc]} {

      foreach lbl [lsort [array names labels]] {
        puts $rc [format "%-17s \"%s\"" $lbl [string tolower [lindex $labels($lbl) $label_index(color)]]]
      }

      close $rc

      # If we have a write callback routine, call it now
      if {$write_callback ne ""} {
        uplevel #0 $write_callback
      }

    } elseif {[file tail $::argv0] eq "themer.tcl"} {

      puts [msgcat::mc "ERROR:  Unable to write %s" [file join $theme_dir $basename.tketheme]]
      puts $rc
      exit 1

    }

    return 1

  }

  ######################################################################
  # Creates the UI for the importer, automatically populating it with
  # the default values.
  proc create {{callback ""}} {

    variable widgets
    variable labels
    variable label_index
    variable all_scopes
    variable tmtheme
    variable write_callback
    variable show_vars

    # Set the write callback proc
    set write_callback $callback

    # Make it so that the window cannot be resized
    if {[file tail $::argv0] ne "themer.tcl"} {
      toplevel [get_win]
      wm transient [get_win] .
    }
    wm resizable [get_win] 0 0

    # Create top frame
    ttk::frame [get_path].tf

    # Create top-left frame
    ttk::frame [get_path].tf.lf

    # Add background color
    create_color_row background 0
    create_color_row foreground 1

    # Add separator
    ttk::separator [get_path].tf.lf.sep
    grid [get_path].tf.lf.sep -row 2 -column 0 -sticky ew -padx 2 -pady 2 -columnspan 2

    set i 3

    foreach lbl [lsort [array names labels]] {

      # Don't do anything with the background and foreground labels since we have already handled them
      if {[lsearch [list background foreground] $lbl] != -1} {
        continue
      }

      # Create the label and menubutton
      create_color_row $lbl $i

      incr i

    }

    # Create the top-right frame
    ttk::labelframe [get_path].tf.rf -text "Sample Text"
    set widgets(border) [frame [get_path].tf.rf.f     -padx 1 -pady 1]
    set widgets(gutter) [text  [get_path].tf.rf.f.gut   -relief flat -bd 0 -width 4  -height 10 -highlightthickness 0]
    set widgets(vr)     [frame [get_path].tf.rf.f.vr    -relief flat -bd 0 -width 1]
    set widgets(txt)    [text  [get_path].tf.rf.f.txt   -relief flat -bd 0 -width 40 -height 10 -highlightthickness 0]
    set widgets(warn)   [frame [get_path].tf.rf.f.txt.w -relief flat -bd 0 -width 1]

    # Insert line numbers into gutter
    for {set i 167} {$i < 197} {incr i} {
      $widgets(gutter) insert end "$i\n"
    }

    # Insert sample text
    $widgets(txt) insert end "#ifdef DFN\n"
    $widgets(txt) insert end "\n"
    $widgets(txt) insert end "  // Some sort of comment\n"
    $widgets(txt) insert end "  void foobar () {\n"
    $widgets(txt) insert end "    int a = 100;\n"
    $widgets(txt) insert end "    printf( \"a: %d\\n\", a );\n"
    $widgets(txt) insert end "  }\n"
    $widgets(txt) insert end "\n"
    $widgets(txt) insert end "#endif\n"

    # Tag the text widget
    $widgets(txt) tag add precompile     1.0 1.10 9.0 9.6
    $widgets(txt) tag add comments       3.2 3.25
    $widgets(txt) tag add keywords       4.2 4.6 5.4 5.7 6.4 6.10
    $widgets(txt) tag add numbers        5.12 5.15
    $widgets(txt) tag add strings        6.12 6.21
    $widgets(txt) tag add miscellaneous1 6.4 6.10
    $widgets(txt) tag add punctuation    4.14 4.19 5.10 5.11 5.15 5.16 6.10 6.11 6.21 6.22 6.25 6.27 7.2 7.3
    $widgets(txt) tag add cursor         4.2 4.3
    $widgets(txt) tag add subonly        1.0 10.0
    $widgets(txt) tag add addonly        1.0 10.0
    $widgets(txt) tag add sub            5.0 6.0
    $widgets(txt) tag add add            6.0 7.0
    $widgets(txt) tag add select         3.0 5.0

    # Disable the text widgets
    $widgets(gutter) configure -state disabled
    $widgets(txt)    configure -state disabled

    grid rowconfigure    [get_path].tf.rf.f 0 -weight 1
    grid columnconfigure [get_path].tf.rf.f 2 -weight 1
    grid $widgets(gutter) -row 0 -column 0 -sticky ns
    grid $widgets(vr)     -row 0 -column 1 -sticky ns
    grid $widgets(txt)    -row 0 -column 2 -sticky news

    place $widgets(warn) -x [font measure [$widgets(txt) cget -font] -displayof . [string repeat "m" 30]] -relheight 1.0
    
    pack [get_path].tf.rf.f -fill both -expand yes

    grid [get_path].tf.lf -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid [get_path].tf.rf -row 0 -column 1 -sticky news -padx 2 -pady 2

    set bwidth [msgcat::mcmax "Reset" "Save As" "Import" "Create" "Save" "Cancel"]

    # Create the button frame
    ttk::frame  [get_path].bf
    set widgets(reset) [ttk::button [get_path].bf.reset  -text [msgcat::mc "Reset"] -width $bwidth -command {
      array set themer::labels [array get themer::orig_labels]
      themer::highlight
    }]
    set widgets(saveas) [ttk::button [get_path].bf.saveas -text [msgcat::mc "Save As"] -width $bwidth -command {
      set orig_tmtheme    $themer::tmtheme
      set themer::tmtheme ""
      if {[themer::write_tketheme]} {
        themer::destroy_win
      } else {
        set themer::tmtheme $orig_tmtheme
      }
    }]
    set widgets(action) [ttk::button [get_path].bf.import -text [msgcat::mc "Import"] -width $bwidth -command {
      if {[themer::write_tketheme]} {
        themer::destroy_win
      }
    }]
    ttk::button [get_path].bf.cancel -text [msgcat::mc "Cancel"] -width $bwidth -command {
      themer::destroy_win
    }

    if {$tmtheme ne ""} {
      pack [get_path].bf.reset  -side left  -padx 2 -pady 2
    }

    pack [get_path].bf.cancel -side right -padx 2 -pady 2
    pack [get_path].bf.import -side right -padx 2 -pady 2

    pack [get_path].tf -fill both -expand yes
    pack [get_path].bf -fill x

    # If the window is coming from tke, center it in the window
    if {[file tail $::argv0] ne "themer.tcl"} {
      ::tk::PlaceWindow [get_win] widget .
    }

  }
  
  ######################################################################
  # Called to destroy the window
  proc destroy_win {} {
    
    variable widgets
    
    # Clear the widgets namespace
    array unset widgets
    
    # Destroy the window
    destroy [get_win]
    
  }

  ######################################################################
  # Creates a row in the color selection sidebar.
  proc create_color_row {lbl row} {

    variable widgets
    variable show_vars
    variable labels
    variable label_index

    if {($lbl eq "background") || ($lbl eq "foreground") || ($lbl eq "select_foreground")} {
      set widgets(l:$lbl) [ttk::label [get_path].tf.lf.l$lbl -text "     [convert_label $lbl]:"]
    } else {
      set widgets(l:$lbl) [ttk::checkbutton [get_path].tf.lf.l$lbl -text " [convert_label $lbl]:" -variable themer::show_vars($lbl)]
      set show_vars($lbl) [lindex $labels($lbl) $label_index(show)]
    }

    set widgets(b:$lbl) [ttk::label [get_path].tf.lf.b$lbl -anchor w -relief raised]

    bind $widgets(b:$lbl) <Button-1> "themer::show_menu $lbl"
    
    # Create menu
    set widgets(m:$lbl) [menu [get_path].tf.lf.b$lbl.mnu -tearoff 0]

    # Add custom command so that we don't get an error when parsing
    $widgets(m:$lbl) add command -label [msgcat::mc "Create custom"] -command "themer::create_custom_color $lbl"
 
    # Add them to the grid
    grid $widgets(l:$lbl) -row $row -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(b:$lbl) -row $row -column 1 -sticky news -padx 2 -pady 2

  }

  ######################################################################
  # Replaces underscores with spaces and converts everything to title case.
  proc convert_label {name} {

    set str ""
    foreach part [split $name _] {
      append str "[string totitle $part] "
    }

    return [string trimright $str]

  }

  ######################################################################
  # Displays the menu for the given color type.
  proc show_menu {lbl} {
 
    variable widgets
    variable tmtheme
 
    # If we are dealing with a theme, display the menu
    if {$tmtheme ne ""} {
 
      tk_popup $widgets(m:$lbl) \
        [winfo rootx $widgets(b:$lbl)] \
        [expr [winfo rooty $widgets(b:$lbl)] + [winfo reqheight $widgets(b:$lbl)]]
 
    # Otherwise, if we are creating a new, just launch the color chooser
    } else {
 
      create_custom_color $lbl
 
    }
 
  }
 
  #############################################################
  # Called whenever a menu item is selected inthe scope menu.
  proc handle_menu_select {lbl scope} {

    variable labels
    variable label_index
    variable all_scopes

    # Set the current color to the given scope
    lset labels($lbl) $label_index(color) $all_scopes($scope)
    lset labels($lbl) $label_index(scope) $scope

  }

  ######################################################################
  # Allows the user to create a custom color.
  proc create_custom_color {lbl} {

    variable labels
    variable label_index

    # Set the color to the chosen color
    if {[set color [tk_chooseColor -initialcolor [lindex $labels($lbl) $label_index(color)] -parent [get_win] -title [convert_label $lbl]]] ne ""} {
      lset labels($lbl) $label_index(color)   $color
      lset labels($lbl) $label_index(changed) 1
    }

  }

  ######################################################################
  # Perform the highlight on the text widget based on the current labels.
  proc highlight {} {

    variable widgets
    variable labels
    variable label_index
    variable all_scopes
    variable tmtheme
    variable show_vars

    # Skip if the widgets do not yet exist
    if {![info exists widgets(txt)]} {
      return
    }

    # Create a temporary frame to get its default color
    frame .__tmp
    set bdcolor [.__tmp cget -background]
    destroy .__tmp
    
    # Get the background color
    set bgcolor [lindex $labels(background) $label_index(color)]
    
    # Colorize the border
    if {[set color [lindex $labels(border_highlight) $label_index(color)]] ne ""} {
      $widgets(border) configure -background [expr {$show_vars(border_highlight) ? $color : $bdcolor}]
    }

    # Colorize the gutter
    if {[set color [lindex $labels(line_number) $label_index(color)]] ne ""} {
      $widgets(gutter) configure -foreground [expr {$show_vars(line_number) ? $color : $bgcolor}]
    }

    # Colorize all of the foreground tags and the menu
    foreach {lbl info} [array get labels] {
      if {[set pos [lindex $info $label_index(tagpos)]] ne ""} {
        $widgets(txt) tag configure $lbl $pos [expr {$show_vars($lbl) ? [lindex $info $label_index(color)] : ""}]
      }
    }

    # Colorize the text widget itself
    if {[set color [lindex $labels(foreground) $label_index(color)]] ne ""} {
      $widgets(txt) configure -foreground $color
    }
    if {[set color [lindex $labels(background) $label_index(color)]] ne ""} {
      $widgets(gutter) configure -background $color
      $widgets(txt)    configure -background $color
    }

    # Colorize the vr and warn frames
    if {[set color [lindex $labels(warning_width) $label_index(color)]] ne ""} {
      $widgets(vr)   configure -background [expr {$show_vars(warning_width) ? $color : $bgcolor}]
      $widgets(warn) configure -background [expr {$show_vars(warning_width) ? $color : $bgcolor}]
    }

    # Colorize the difference backgrounds
    if {[set color [lindex $labels(difference_sub) $label_index(color)]] ne ""} {
      $widgets(txt) tag configure sub     -background ""
      $widgets(txt) tag configure subonly -background ""
      if {$show_vars(difference_sub)} {
        $widgets(txt) tag configure [expr {$show_vars(difference_add) ? "sub" : "subonly"}] -background $color
      }
    }
    if {[set color [lindex $labels(difference_add) $label_index(color)]] ne ""} {
      $widgets(txt) tag configure add     -background ""
      $widgets(txt) tag configure addonly -background ""
      if {$show_vars(difference_add)} {
        $widgets(txt) tag configure [expr {$show_vars(difference_sub) ? "add" : "addonly"}] -background $color
      }
    }

    # Colorize the selection
    if {[set color [lindex $labels(select_background) $label_index(color)]] ne ""} {
      $widgets(txt) tag configure select -background [expr {$show_vars(select_background) ? $color : ""}] \
        -foreground [expr {$show_vars(select_background) ? [lindex $labels(select_foreground) $label_index(color)] : ""}]
    }

    # Colorize the menubuttons and menus
    if {$tmtheme ne ""} {
      foreach {lbl info} [array get labels] {
        set mnu $widgets(m:$lbl)
        foreach scope [array names all_scopes] {
          catch { $mnu entryconfigure $scope -foreground $all_scopes($scope) }
        }
      }
    }

  }

  ######################################################################
  # Returns the name of the top-level window.
  proc get_win {} {

    return [expr {([file tail $::argv0] eq "themer.tcl") ? "." : ".thwin"}]

  }

  ######################################################################
  # Returns the path of the top-level window.
  proc get_path {} {

    return [expr {([file tail $::argv0] eq "themer.tcl") ? "" : ".thwin"}]

  }

  ######################################################################
  # Imports the given TextMate theme and displays the result in the UI.
  proc import_tm {theme {callback ""}} {

    variable base_labels
    variable labels
    variable widgets
    variable tmtheme
    variable all_scopes

    # Set the theme
    set tmtheme $theme

    # Initialize the labels array
    array set labels [array get base_labels]
    
    # Create the UI
    create $callback

    # Initialize the widgets
    wm title [get_win] [msgcat::mc "Import TextMate Theme"]
    $widgets(action) configure -text [msgcat::mc "Import"]
    catch { pack $widgets(reset) -side left -padx 2 -pady 2 }

    # Set the label colors to red
    foreach l [array names widgets l:*] {
      $widgets(b:[lindex [split $l :] 1]) configure -compound left
    }

    # Read the theme
    read_tmtheme $theme

    # Update the menus
    foreach mnu [array names widgets m:*] {

      set lbl [lindex [split $mnu :] 1]

      # Clear the menu
      $widgets($mnu) delete 0 end

      # Add the custom menu
      $widgets($mnu) add command -label [msgcat::mc "Create custom"] -command "themer::create_custom_color $lbl"
      $widgets($mnu) add separator

      # Add the scopes to the menu
      set i 2
      foreach scope [lsort [array names all_scopes]] {
        $widgets($mnu) add command -label $scope -columnbreak [expr ($i % 40) == 39] \
          -command "themer::handle_menu_select $lbl $scope"
        incr i
      }

    }

  }

  ######################################################################
  # Imports the given tke theme and displays the result in the UI.
  proc import_tke {theme {callback ""}} {

    variable base_labels
    variable labels
    variable widgets
    variable tmtheme
    variable all_scopes

    # Set the theme
    set tmtheme $theme

    # Initialize the labels array
    array set labels [array get base_labels]
    
    # Create the UI
    create $callback

    # Initialize UI
    wm title [get_win] [msgcat::mc "Edit theme"]
    $widgets(action) configure -text [msgcat::mc "Save"]
    catch { pack $widgets(reset) -side left -padx 2 -pady 2 }
    catch { pack $widgets(saveas) -side right -padx 2 -pady 2 }

    # Read the theme
    read_tketheme $theme

  }

  ######################################################################
  # Allows the user to create a new theme.
  proc create_new {{callback ""}} {

    variable base_labels
    variable labels
    variable widgets
    variable tmtheme
    variable label_index

    # Clear the theme
    set tmtheme ""

    # Initialize the labels array
    array set labels [array get base_labels]
    
    # Create the UI
    create $callback

    # Initialize the widgets
    wm title [get_win] [msgcat::mc "Create New Theme"]
    $widgets(action) configure -text [msgcat::mc "Create"]
    catch { pack forget $widgets(reset) }

    # Initialize the labels array
    lset labels(background)        $label_index(color) "black"
    lset labels(foreground)        $label_index(color) "white"
    lset labels(select_background) $label_index(color) "blue"
    lset labels(select_foreground) $label_index(color) "white"
    lset labels(border_highlight)  $label_index(color) "yellow"
    lset labels(cursor)            $label_index(color) "grey"
    lset labels(keywords)          $label_index(color) "red"
    lset labels(comments)          $label_index(color) "blue"
    lset labels(strings)           $label_index(color) "green"
    lset labels(numbers)           $label_index(color) "orange"
    lset labels(punctuation)       $label_index(color) "white"
    lset labels(precompile)        $label_index(color) "yellow"
    lset labels(miscellaneous1)    $label_index(color) "pink"
    lset labels(miscellaneous2)    $label_index(color) "gold"
    lset labels(miscellaneous3)    $label_index(color) "green"
    lset labels(line_number)       $label_index(color) [utils::auto_adjust_color "black" 40]
    lset labels(warning_width)     $label_index(color) [utils::auto_adjust_color "black" 40]
    lset labels(difference_sub)    $label_index(color) [utils::auto_mix_colors "black" r 30]
    lset labels(difference_add)    $label_index(color) [utils::auto_mix_colors "black" g 30]

  }

}

if {[file tail $argv0] eq "themer.tcl"} {

  ######################################################################
  # Displays usage message if this script is being executed from the
  # command-line.
  proc usage {} {

    puts "Usage:  themer (-h | <tmTheme file> | <tkeTheme file>)"
    puts ""
    puts "Options:"
    puts "  -h  Displays this help information"
    puts ""

    exit

  }

  # Parse the command-line options
  set i 0
  while {$i < $argc} {
    switch [lindex $argv $i] {
      -h      { usage }
      default { set theme [lindex $argv $i] }
    }
    incr i
  }

  # Set the theme to clam
  ttk::style theme use clam

  if {[info exists theme]} {
    set ext [string tolower [file extension $theme]]
    switch -exact -- $ext {
      .tmtheme  { themer::import_tm $theme }
      .tketheme { themer::import_tke $theme }
      default   {
        puts [msgcat::mc "Error:  Theme is not a supported theme"]
        usage
      }
    }
  } else {
    themer::create_new
  }

}

