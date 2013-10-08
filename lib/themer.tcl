#!wish8.5

######################################################################
# Name:    themer.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/04/2013
# Brief:   Converts a *.tmTheme file to a *.tketheme file.
######################################################################

set tke_dir [file dirname [file dirname [file normalize $argv0]]]

namespace eval themer {
  
  variable theme_dir [file join $::tke_dir data themes]
  variable tmtheme   ""
   
  array set widgets     {}
  array set all_scopes  {}
  array set orig_colors {}
  
  array set scopes {
    comment        comments
    keyword        keywords
    string         strings
    entity         punctuation
    punctuation    punctuation
    preprocessor   precompile
    preprocessor   precompile
    constant       numbers
    variable.other miscellaneous
    meta.tag       miscellaneous
  }
   
  array set colors {
    background       ""
    foreground       ""
    warnwidthcolor   ""
    selectbackground "blue"
    selectforeground "white"
    highlightcolor   "yellow"
    cursor           ""
    keywords         ""
    comments         ""
    strings          ""
    numbers          ""
    punctuation      ""
    precompile       ""
    miscellaneous    ""
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
      lset hsv 2 [expr [lindex $hsv 2] + 25]
   
    # Otherwise, darken the color to white
    } else {
      lset hsv 2 [expr [lindex $hsv 2] - 25]
    }
   
    # Convert the HSV value back to an RGB value
    set rgb [eval "hsv_to_rgb $hsv"]
   
    return [eval "format {#%02x%02x%02x} $rgb"]
   
  }
   
  ######################################################################
  # Reads the given TextMate theme file and extracts the relevant information
  # for tke's needs.
  proc read_tmtheme {theme} {
    
    variable colors
    variable scopes
    variable all_scopes
    variable tmtheme
    variable orig_colors
    
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
                if {$scope_types eq ""} {
                  set colors(foreground)     [normalize_color $value]
                  set all_scopes(foreground) [normalize_color $value]
                } else {
                  foreach scope_type [string map {, { }} $scope_types] {
                    if {[info exists scopes($scope_type)]} {
                      set color $scopes($scope_type)
                      set colors($color) [normalize_color $value]
                    }
                    set all_scopes($scope_type) [normalize_color $value]
                  }
                }
              } elseif {$background} {
                set background 0
                if {$scope_types eq ""} {
                  set colors(background)     [normalize_color $value]
                  set colors(warnwidthcolor) [create_warn_width_color [normalize_color $value]]
                  set all_scopes(background) [normalize_color $value]
                }
              } elseif {$caret} {
                set caret 0
                if {$scope_types eq ""} {
                  set colors(cursor)     [normalize_color $value]
                  set all_scopes(cursor) [normalize_color $value]
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
    
    # Save the colors array to orig_colors
    array set orig_colors [array get colors]
    
  }
   
  ######################################################################
  # Checks to make sure that all colors needed were found in the TextMate
  # theme file.
  proc check_colors {} {
    
    variable colors
    
    set missing 0
    
    foreach {key value} [array get colors] {
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
    variable colors
    
    # Get the basename of the tmtheme file
    set basename [file rootname [file tail $tmtheme]]
    
    if {![catch { open [file join $theme_dir $basename.tketheme] w } rc]} {
      
      foreach {key value} [array get colors] {
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
    variable colors
    variable all_scopes
    variable tmtheme
    
    ttk::frame .tf
    
    # Create left frame
    ttk::frame .tf.lf
    
    set i 0
    foreach color [list background foreground cursor precompile comments keywords punctuation numbers strings miscellaneous] {
      
      # Create the label and menubutton
      ttk::label .tf.lf.l$color  -text $color
      set widgets(mb:$color) [ttk::menubutton .tf.lf.mb$color -menu .tf.lf.mb$color.mnu]
      
      # Create menu
      menu .tf.lf.mb$color.mnu -tearoff 0
      
      .tf.lf.mb$color.mnu add command -label "Create custom" -command "themer::create_custom_color $color"
      .tf.lf.mb$color.mnu add separator
      
      set j 2
      foreach scope [lsort [array names all_scopes]] {
        .tf.lf.mb$color.mnu add command -label $scope -columnbreak [expr ($j % 40) == 39] \
                                        -command "themer::handle_menu_select $color $scope"
        incr j
      }
      
      # Add them to the grid
      grid .tf.lf.l$color  -row $i -column 0 -sticky news -padx 2 -pady 2
      grid .tf.lf.mb$color -row $i -column 1 -sticky news -padx 2 -pady 2
      
      incr i
      
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
    $widgets(txt) tag add precompile     1.0 1.10 10.0 10.6
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

    # Perform the highlight based on the current colors
    highlight
    
    grid .tf.lf -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid .tf.rf -row 0 -column 1 -sticky news -padx 2 -pady 2
    
    # Create the button frame
    ttk::frame  .bf
    ttk::button .bf.reset  -text "Reset"  -width 6 -command {
      array set themer::colors [array get themer::orig_colors]
      themer::highlight
    }
    ttk::button .bf.import -text "Import" -width 6 -command {
      themer::write_tketheme
      destroy .
    }
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
  
  #############################################################
  # Called whenever a menu item is selected inthe scope menu.
  proc handle_menu_select {type scope} {
  
    variable colors
    variable all_scopes
    variable widgets
    
    # Set the menubutton
    $widgets(mb:$type) configure -text $scope
  
    # Set the current color to the givens cope
    set colors($type) $all_scopes($scope)
    
    # Highlight the sample textbox
    highlight
  
  }
  
  ######################################################################
  # Allows the user to create a custom color.
  proc create_custom_color {type} {
    
    variable colors
    
    if {[set color [tk_chooseColor -initialcolor $colors($type) -parent . -title "Choose custom color"]] ne ""} {
      set colors($type) $color
      highlight
    }
    
  }
 
  ######################################################################
  # Perform the highlight on the text widget based on the current colors.
  proc highlight {} {
    
    variable widgets
    variable colors
    variable all_scopes
    
    # Colorize all of the foreground tags and the menu
    foreach color [list precompile comments keywords punctuation numbers strings miscellaneous] {
      $widgets(txt) tag configure $color -foreground $colors($color)
    }
    
    # Colorize all of the background tags
    foreach color [list warnwidthcolor cursor] {
      $widgets(txt) tag configure $color -background $colors($color)    
    }
    
    # Colorize the text widget itself
    $widgets(txt) configure -foreground $colors(foreground) -background $colors(background)
    
    # Colorize the menubuttons and menus
    foreach color [list background foreground cursor precompile comments keywords punctuation numbers strings miscellaneous] {
      set mnu .tf.lf.mb$color.mnu
      $mnu configure -background $colors(background)
      $mnu entryconfigure "Create custom" -foreground $colors($color)
      foreach scope [array names all_scopes] {
        $mnu entryconfigure $scope -foreground $all_scopes($scope)
      }
    }

    
  }
  
}

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

# If the theme file was not specified, display the usage information
# and exit.
if {![info exists tmtheme]} {
  usage
}

# Read the contents of the TextMate theme file (its in XML format)
themer::read_tmtheme $tmtheme

# Create the UI
themer::create

# Set the theme to clam
ttk::style theme use clam

