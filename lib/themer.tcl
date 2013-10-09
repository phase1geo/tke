#!wish8.5

######################################################################
# Name:    themer.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/04/2013
# Brief:   Converts a *.tmTheme file to a *.tketheme file.
######################################################################

if {[file tail $argv0] eq "themer.tcl"} {
  set tke_dir [file dirname [file dirname [file normalize $argv0]]]
}

namespace eval themer {
  
  variable theme_dir [file join $::tke_dir data themes]
  variable tmtheme   ""
   
  array set widgets     {}
  array set all_scopes  {}
  array set orig_labels {}
  
  array set label_index {
    color   0
    setable 1
    tagpos  2
    scope   3
  }
  
  array set scope_map {
    comment          comments
    keyword          keywords
    string           strings
    entity           punctuation
    punctuation      punctuation
    preprocessor     precompile
    preprocessor     precompile
    constant.numeric numbers
    variable.other   miscellaneous
    meta.tag         miscellaneous
  }
   
  array set labels {
    background       {""       1 ""            ""}
    foreground       {""       1 ""            ""}
    warnwidthcolor   {""       0 "-background" ""}
    selectbackground {"blue"   0 ""            ""}
    selectforeground {"white"  0 ""            ""}
    highlightcolor   {"yellow" 0 ""            ""}
    cursor           {""       1 "-background" ""}
    keywords         {""       1 "-foreground" ""}
    comments         {""       1 "-foreground" ""}
    strings          {""       1 "-foreground" ""}
    numbers          {""       1 "-foreground" ""}
    punctuation      {""       1 "-foreground" ""}
    precompile       {""       1 "-foreground" ""}
    miscellaneous    {""       1 "-foreground" ""}
  }
  
  # Add trace to the labels array
  trace add variable themer::labels w themer::handle_label_change 
  
  #############################################################
  # Called whenever a menu item is selected inthe scope menu.
  proc handle_label_change {name1 lbl op} {
  
    variable labels
    variable label_index
    variable widgets
    
    # If the label is setable by the user, update the buttons and labels
    if {[lindex $labels($lbl) $label_index(setable)]} {
      
      # Get the color from the label
      set color [lindex $labels($lbl) $label_index(color)]
       
      # Set the button and label
      $widgets(l:$name2) configure -foreground ""
      $widgets(b:$name2) configure -text [lindex $labels($lbl) $label_index(scope)]
       
      # Set the image
      if {$lbl eq "background"} {
        lset labels(warnwidthcolor) $label_index(color) [create_warn_width_color $color]
        foreach {l info} [array get labels] {
          if {[lindex $info $label_index(setable)] && ([set color [lindex $info $label_index(color)]] ne "")} {
            set_button_image $l $color
          }
        }
      } else {
        set_button_image $lbl $color
      }
    
    }
  
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
  # Converts an RGB value into an HSV value.
  proc rgb_to_hsv {r g b} {
   
    set sorted [lsort -real [list $r $g $b]]
    set temp [lindex $sorted 0]
    set v [lindex $sorted 2]
   
    set bottom [expr {$v-$temp}]
    if {$bottom == 0} {
      set h 0
      set s 0
      set v $v
    } else {
      if {$v == $r} {
        set top [expr {$g-$b}]
        if {$g >= $b} {
          set angle 0
        } else {
          set angle 360
        }
      } elseif {$v == $g} {
        set top [expr {$b-$r}]
        set angle 120
      } elseif {$v == $b} {
        set top [expr {$r-$g}]
        set angle 240
      }
      set h [expr { round( 60 * ( double($top) / $bottom ) + $angle ) }]
    }
   
    if {$v == 0} {
      set s 0
    } else {
      set s [expr { round( 255 - 255 * ( double($temp) / $v ) ) }]
    }
   
    return [list $h $s $v]
   
  }
   
  ######################################################################
  # Converts an HSV value into an RGB value.
  proc hsv_to_rgb {h s v} {
   
    set hi [expr { int( double($h) / 60 ) % 6 }]
    set f  [expr { double($h) / 60 - $hi }]
    set s  [expr { double($s)/255 }]
    set v  [expr { double($v)/255 }]
    set p  [expr { double($v) * (1 - $s) }]
    set q  [expr { double($v) * (1 - $f * $s) }]
    set t  [expr { double($v) * (1 - (1 - $f) * $s) }]
   
    switch -- $hi {
      0 {
        set r $v
        set g $t
        set b $p
      }
      1 {
        set r $q
        set g $v
        set b $p
      }
      2 {
        set r $p
        set g $v
        set b $t
      }
      3 {
        set r $p
        set g $q
        set b $v
      }
      4 {
        set r $t
        set g $p
        set b $v
      }
      5 {
        set r $v
        set g $p
        set b $q
      }
      default {
        error "Wrong hi value in hsv_to_rgb procedure! This should never happen!"
      }
    }
   
    set r [expr {round($r*255)}]
    set g [expr {round($g*255)}]
    set b [expr {round($b*255)}]
   
    return [list $r $g $b]
   
  }
   
  ######################################################################
  # Creates the warnwidthcolor color from the given background color
  # by darkening (if the HSV value is a lighter color) or lightening
  # (if the HSV value is a darker color) the color just a bit.
  proc create_warn_width_color {color} {
   
    # Convert the color to an HSV value
    foreach {r g b} [winfo rgb . $color] {}
    set hsv [rgb_to_hsv [expr $r >> 8] [expr $g >> 8] [expr $b >> 8]]
   
    # Lighten it if value is closer to black
    if {[lindex $hsv 2] < 0x80} {
      lset hsv 2 [expr [lindex $hsv 2] + 40]
   
    # Otherwise, darken the color to white
    } else {
      lset hsv 2 [expr [lindex $hsv 2] - 40]
    }
   
    # Convert the HSV value back to an RGB value
    set rgb [eval "hsv_to_rgb $hsv"]
   
    return [eval "format {#%02x%02x%02x} $rgb"]
   
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
                  lset labels(background)     $label_index(color) $color
                  lset labels(background)     $label_index(scope) "background"
                  lset labels(warnwidthcolor) $label_index(color) [create_warn_width_color $color]
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
      
    } else {
      
      puts "ERROR:  Unable to read $theme"
      puts $rc
      exit 1
      
    }
    
    # Save the labels array to orig_labels
    array set orig_labels [array get labels]
    
  }
   
  ######################################################################
  # Checks to make sure that all colors needed were found in the TextMate
  # theme file.
  proc check_colors {} {
    
    variable labels
    
    set missing 0
    
    foreach {key value} [array get labels] {
      if {$value eq ""} {
        puts "ERROR:  Could not find color $key"
        set missing 1
      }
    }
    
    if {$missing} {
      exit 1
    }
    
  }
   
  ######################################################################
  # Writes the TKE theme file to the theme directory.
  proc write_tketheme {} {
    
    variable theme_dir
    variable tmtheme
    variable labels
    
    # If we don't have a theme name, get one
    if {$tmtheme eq ""} {
      if {[set tmtheme [tk_getSaveFile -parent . -initialdir [pwd] -defaultextension ".tketheme"]] eq ""} {
        return
      }
    }
    
    # Get the basename of the tmtheme file
    set basename [file rootname [file tail $tmtheme]]
    
    if {![catch { open [file join $theme_dir $basename.tketheme] w } rc]} {
      
      foreach {key value} [array get labels] {
        puts $rc [format "%-16s \"%s\"" $key [string tolower $value]]
      }
      
      close $rc
      
    } else {
      
      puts "ERROR:  Unable to write [file join $theme_dir $basename.tketheme]"
      puts $rc
      exit 1
      
    }
    
  }
  
  ######################################################################
  # Creates the UI for the importer, automatically populating it with
  # the default values.
  proc create {} {
    
    variable widgets
    variable labels
    variable label_index
    variable all_scopes
    variable tmtheme
    
    ttk::frame .tf
    
    # Create left frame
    ttk::frame .tf.lf
    
    incr i
    foreach lbl [lsort [array names labels]] {
      
      if {[lindex $labels($lbl) $label_index(setable)]} {
      
        # Create the label and menubutton
        set widgets(l:$lbl) [ttk::label .tf.lf.l$lbl -text [string totitle $lbl]]
        set widgets(b:$lbl) [ttk::label .tf.lf.b$lbl -compound left -anchor w -relief raised]
        
        bind $widgets(b:$lbl) <Button-1> "themer::show_menu $lbl"
      
        # Create menu
        set widgets(m:$lbl) [menu .tf.lf.b$lbl.mnu -tearoff 0]
      
        # Add them to the grid
        grid $widgets(l:$lbl) -row $i -column 0 -sticky news -padx 2 -pady 2
        grid $widgets(b:$lbl) -row $i -column 1 -sticky news -padx 2 -pady 2
      
        incr i
        
      }
      
    }
    
    # Create the right frame
    ttk::frame .tf.rf
    set widgets(txt) [text .tf.rf.txt -height 10 -width 40]
    
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
    $widgets(txt) tag add miscellaneous  6.4 6.10
    $widgets(txt) tag add punctuation    4.14 4.19 5.10 5.11 5.15 5.16 6.10 6.11 6.21 6.22 6.26 6.28
    $widgets(txt) tag add warnwidthcolor 6.25 6.28
    $widgets(txt) tag add cursor         4.2 4.3
    
    # Disable the text widget
    $widgets(txt) configure -state disabled

    pack $widgets(txt)

    grid .tf.lf -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid .tf.rf -row 0 -column 1 -sticky news -padx 2 -pady 2
    
    # Create the button frame
    ttk::frame  .bf
    set widgets(reset) [ttk::button .bf.reset  -text "Reset"  -width 6 -command {
      array set themer::labels [array get themer::orig_labels]
      themer::highlight
    }]
    set widgets(action) [ttk::button .bf.import -text "Import" -width 6 -command {
      themer::write_tketheme
      destroy .
    }]
    ttk::button .bf.cancel -text "Cancel" -width 6 -command {
      destroy .
    }
    
    if {$tmtheme ne ""} {
      pack .bf.reset  -side left  -padx 2 -pady 2
    }
    
    pack .bf.cancel -side right -padx 2 -pady 2
    pack .bf.import -side right -padx 2 -pady 2
    
    pack .tf -fill both -expand yes
    pack .bf -fill x
      
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
 
  }
  
  ######################################################################
  # Allows the user to create a custom color.
  proc create_custom_color {lbl} {
    
    variable labels
    variable label_index
    
    # Set the color to the chosen color
    if {[set color [tk_chooseColor -initialcolor [lindex $labels($lbl) $label_index(color)] -parent . -title "Choose custom color"]] ne ""} {
      lset labels($lbl) $label_index(color) $color
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
    
    # Colorize all of the foreground tags and the menu
    foreach {lbl info} [array get labels] {
      if {[set pos [lindex $info $label_index(tagpos)]] ne ""} {
        $widgets(txt) tag configure $lbl $pos [lindex $info $label_index(color)]
      }
    }
    
    # Colorize the text widget itself
    $widgets(txt) configure -foreground [lindex $labels(foreground) $label_index(color)] \
                            -background [lindex $labels(background) $label_index(color)]
    
    # Colorize the menubuttons and menus
    if {$tmtheme ne ""} {
      foreach {lbl info} [array get labels] {
        if {[lindex $info $label_index(setable)]} {
          set mnu .tf.lf.b$lbl.mnu
          $mnu configure -background [lindex $labels(background) $label_index(color)]
          $mnu entryconfigure "Create custom" -foreground [lindex $info $label_index(color)]
          foreach scope [array names all_scopes] {
            $mnu entryconfigure $scope -foreground $all_scopes($scope)
          }
        }
      }
    }

  }
  
  ######################################################################
  # Imports the given theme and upd
  proc import_tm {theme} {
  
    variable widgets
    variable tmtheme
    variable all_scopes
    
    # Set the theme
    set tmtheme $tmtheme
    
    # Create the UI
    create
    
    # Initialize the widgets
    wm title . "Import TextMate Theme"
    $widgets(action) configure -text "Import"
    catch { pack $widgets(reset) -side left -padx 2 -pady 2 }
    
    # Set the label colors to red
    foreach l [array names widgets l:*] {
      $widgets($l) configure -foreground "red"
    }
    
    # Read the theme
    read_tmtheme $theme
    
    # Update the menus
    foreach mnu [array names widgets m:*] {
      
      set lbl [lindex [split $mnu :] 1]
      
      # Clear the menu
      $widgets($mnu) delete 0 end
      
      # Add the custom menu
      $widgets($mnu) add command -label "Create custom" -command "themer::create_custom_color $lbl"
      $widgets($mnu) add separator
    
      # Add the scopes to the menu
      set i 2
      foreach scope [lsort [array names all_scopes]] {
        $widgets($mnu) add command -label $scope -columnbreak [expr ($i % 40) == 39] \
          -command "themer::handle_menu_select $lbl $scope"
        incr i
      }
      
    }
    
    # Perform the highlight based on the current colors
    highlight
    
  }
  
  ######################################################################
  # Allows the user to create a new theme.
  proc create_new {} {
    
    variable labels
    variable widgets
    variable tmtheme
    variable label_index
    
    # Clear the theme
    set tmtheme ""
    
    # Create the UI
    create
    
    # Initialize the widgets
    wm title . "Create New Theme"
    $widgets(action) configure -text "Create"
    catch { pack forget $widgets(reset) }
    
    # Initialize the labels array
    lset labels(background)       $label_index(color) "black"
    lset labels(foreground)       $label_index(color) "white"
    lset labels(selectbackground) $label_index(color) "blue"
    lset labels(selectforeground) $label_index(color) "white"
    lset labels(highlightcolor)   $label_index(color) "yellow"
    lset labels(cursor)           $label_index(color) "grey"
    lset labels(keywords)         $label_index(color) "red"
    lset labels(comments)         $label_index(color) "blue"
    lset labels(strings)          $label_index(color) "green"
    lset labels(numbers)          $label_index(color) "orange"
    lset labels(punctuation)      $label_index(color) "white"
    lset labels(precompile)       $label_index(color) "yellow"
    lset labels(miscellaneous)    $label_index(color) "pink"
    lset labels(warnwidthcolor)   $label_index(color) [create_warn_width_color "black"]

  }

}

if {[file tail $argv0] eq "themer.tcl"} {

  ######################################################################
  # Displays usage message if this script is being executed from the
  # command-line.
  proc usage {} {
  
    puts "Usage:  themer (-h | <tmTheme file>)"
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
      default { set tmtheme [lindex $argv $i] }
    }
    incr i
  }

  # Set the theme to clam
  ttk::style theme use clam

  if {[info exists tmtheme]} {
    themer::import_tm $tmtheme
  } else {
    themer::create_new
  }
  
}

