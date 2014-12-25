#!wish8.5

######################################################################
# Name:    themer.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/04/2013
# Brief:   Converts a *.tmTheme file to a *.tketheme file.
######################################################################

if {[file tail $argv0] eq "themer.tcl"} {
  
  set tke_dir [file dirname [file dirname [file normalize $argv0]]]
  
  package require msgcat
  
  source [file join $tke_dir utils.tcl]
  
}

namespace eval themer {
  
  variable theme_dir      [file join $::tke_dir data themes]
  variable tmtheme        ""
  variable write_callback ""
   
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
    miscellaneous1   {""       1 "-foreground" ""}
    miscellaneous2   {""       1 "-foreground" ""}
    miscellaneous3   {""       1 "-foreground" ""}
  }
  
  # Add trace to the labels array
  trace variable themer::labels w themer::handle_label_change 
  
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
      $widgets(l:$lbl) configure -foreground ""
      $widgets(b:$lbl) configure -text [lindex $labels($lbl) $label_index(scope)]
       
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
  # Creates the warnwidthcolor color from the given background color
  # by darkening (if the HSV value is a lighter color) or lightening
  # (if the HSV value is a darker color) the color just a bit.
  proc create_warn_width_color {color} {
   
    # Convert the color to an HSV value
    foreach {r g b} [winfo rgb [get_win] $color] {}
    set hsv [utils::rgb_to_hsv [expr $r >> 8] [expr $g >> 8] [expr $b >> 8]]
   
    # Lighten it if value is closer to black
    if {[lindex $hsv 2] < 0x80} {
      lset hsv 2 [expr [lindex $hsv 2] + 40]
   
    # Otherwise, darken the color to white
    } else {
      lset hsv 2 [expr [lindex $hsv 2] - 40]
    }
   
    # Convert the HSV value back to an RGB value
    set rgb [utils::hsv_to_rgb {*}$hsv]
   
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
      $w.tf.lb insert end $theme
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
      return [file join $::tke_dir data themes $::theme_name]
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
        puts $rc [format "%-16s \"%s\"" $lbl [string tolower [lindex $labels($lbl) $label_index(color)]]]
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
    
    incr i
    foreach lbl [lsort [array names labels]] {
      
      if {[lindex $labels($lbl) $label_index(setable)]} {
      
        # Create the label and menubutton
        set widgets(l:$lbl) [ttk::label [get_path].tf.lf.l$lbl -text "[string totitle $lbl]:"]
        set widgets(b:$lbl) [ttk::label [get_path].tf.lf.b$lbl -anchor w -relief raised]
        
        bind $widgets(b:$lbl) <Button-1> "themer::show_menu $lbl"
      
        # Create menu
        set widgets(m:$lbl) [menu [get_path].tf.lf.b$lbl.mnu -tearoff 0]
        
        # Add custom command so that we don't get an error when parsing
        $widgets(m:$lbl) add command -label [msgcat::mc "Create custom"]
      
        # Add them to the grid
        grid $widgets(l:$lbl) -row $i -column 0 -sticky news -padx 2 -pady 2
        grid $widgets(b:$lbl) -row $i -column 1 -sticky news -padx 2 -pady 2
      
        incr i
        
      }
      
    }
    
    # Create the top-right frame
    ttk::labelframe [get_path].tf.rf -text "Sample Text"
    set widgets(txt) [text [get_path].tf.rf.txt -height 10 -width 40]
    
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
    $widgets(txt) tag add punctuation    4.14 4.19 5.10 5.11 5.15 5.16 6.10 6.11 6.21 6.22 6.26 6.28
    $widgets(txt) tag add warnwidthcolor 6.25 6.28
    $widgets(txt) tag add cursor         4.2 4.3
    
    # Disable the text widget
    $widgets(txt) configure -state disabled

    pack $widgets(txt) -fill both -expand yes

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
        destroy [themer::get_win]
      } else {
        set themer::tmtheme $orig_tmtheme
      }
    }]
    set widgets(action) [ttk::button [get_path].bf.import -text [msgcat::mc "Import"] -width $bwidth -command {
      if {[themer::write_tketheme]} {
        destroy [themer::get_win]
      }
    }]
    ttk::button [get_path].bf.cancel -text [msgcat::mc "Cancel"] -width $bwidth -command {
      destroy [themer::get_win]
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
    if {[set color [tk_chooseColor -initialcolor [lindex $labels($lbl) $label_index(color)] -parent [get_win] -title "Choose custom color"]] ne ""} {
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
    if {[set color [lindex $labels(foreground) $label_index(color)]] ne ""} {
      $widgets(txt) configure -foreground $color
    }
    if {[set color [lindex $labels(background) $label_index(color)]] ne ""} {
      $widgets(txt) configure -background $color
    }
    
    # Colorize the menubuttons and menus
    if {$tmtheme ne ""} {
      foreach {lbl info} [array get labels] {
        if {[lindex $info $label_index(setable)]} {
          set mnu $widgets(m:$lbl)
          if {[set color [lindex $labels(background) $label_index(color)]] ne ""} {
            $mnu configure -background $color
          }
          if {[set color [lindex $info $label_index(color)]] ne ""} {
            $mnu entryconfigure [msgcat::mc "Create custom"] -foreground $color
          }
          foreach scope [array names all_scopes] {
            catch { $mnu entryconfigure $scope -foreground $all_scopes($scope) }
          }
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
  
    variable widgets
    variable tmtheme
    variable all_scopes
    
    # Set the theme
    set tmtheme $theme
    
    # Create the UI
    create $callback
    
    # Initialize the widgets
    wm title [get_win] [msgcat::mc "Import TextMate Theme"]
    $widgets(action) configure -text [msgcat::mc "Import"]
    catch { pack $widgets(reset) -side left -padx 2 -pady 2 }
    
    # Set the label colors to red
    foreach l [array names widgets l:*] {
      $widgets($l) configure -foreground "red"
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
    
    variable widgets
    variable tmtheme
    variable all_scopes
    
    # Set the theme
    set tmtheme $theme
    
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
    
    variable labels
    variable widgets
    variable tmtheme
    variable label_index
    
    # Clear the theme
    set tmtheme ""
    
    # Create the UI
    create $callback
    
    # Initialize the widgets
    wm title [get_win] [msgcat::mc "Create New Theme"]
    $widgets(action) configure -text [msgcat::mc "Create"]
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
    lset labels(miscellaneous1)   $label_index(color) "pink"
    lset labels(miscellaneous2)   $label_index(color) "gold"
    lset labels(miscellaneous3)   $label_index(color) "copper"
    lset labels(warnwidthcolor)   $label_index(color) [create_warn_width_color "black"]

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

