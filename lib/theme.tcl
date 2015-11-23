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
# Name:    theme.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/04/2013
# Brief:   Handles the current theme.
######################################################################

namespace eval theme {

  source [file join $::tke_dir lib ns.tcl]

  variable colorizers {keywords comments strings numbers punctuation precompile miscellaneous1 miscellaneous2 miscellaneous3}

  array set fields {
    type    0
    default 1
    value   2
    changed 3
  }

  variable category_titles [list \
    syntax            [msgcat::mc "Syntax Colors"] \
    ttk_style         [msgcat::mc "ttk Widget Colors"] \
    menus             [msgcat::mc "Menu Options"] \
    tabs              [msgcat::mc "Tab Options"] \
    text_scrollbar    [msgcat::mc "Text Scrollbar Options"] \
    sidebar           [msgcat::mc "Sidebar Options"] \
    sidebar_scrollbar [msgcat::mc "Sidebar Scrollbar Options"] \
    images            [msgcat::mc "Images"] \
  ]

  array set orig_data {
    ttk_style,disabledfg          {color {#999999} {} {0}}
    ttk_style,frame               {color {0} {} {0}}
    ttk_style,lightframe          {color {2} {} {0}}
    ttk_style,dark                {color {#cfcdc8} {} {0}}
    ttk_style,darker              {color {#bab5ab} {} {0}}
    ttk_style,darkest             {color {#9e9a91} {} {0}}
    ttk_style,lighter             {color {1} {} {0}}
    ttk_style,lightest            {color {1} {} {0}}
    ttk_style,selectbg            {color {#4a6984} {} {0}}
    ttk_style,selectfg            {color {#ffffff} {} {0}}
    menus,-background             {color {white} {} {0}}
    menus,-foreground             {color {black} {} {0}}
    menus,-relief                 {{relief {raised sunken flat ridge solid groove}} {flat} {} {0}}
    tabs,-background              {color {2} {} {0}}
    tabs,-foreground              {color {1} {} {0}}
    tabs,-activebackground        {color {0} {} {0}}
    tabs,-inactivebackground      {color {2} {} {0}}
    tabs,-relief                  {{relief {flat raised}} {flat} {} {0}}
    text_scrollbar,-background    {color {0} {} {0}}
    text_scrollbar,-foreground    {color {2} {} {0}}
    text_scrollbar,-thickness     {{number {5 20}} {15} {} {0}}
    syntax,background             {color {black} {} {0}}
    syntax,border_highlight       {color {black} {} {0}}
    syntax,comments               {color {white} {} {0}}
    syntax,cursor                 {color {grey} {} {0}}
    syntax,difference_add         {color {dark green} {} {0}}
    syntax,difference_sub         {color {dark red} {} {0}}
    syntax,foreground             {color {white} {} {0}}
    syntax,highlighter            {color {yellow} {} {0}}
    syntax,keywords               {color {white} {} {0}}
    syntax,line_number            {color {grey} {} {0}}
    syntax,meta                   {color {grey} {} {0}}
    syntax,miscellaneous1         {color {white} {} {0}}
    syntax,miscellaneous2         {color {white} {} {0}}
    syntax,miscellaneous3         {color {white} {} {0}}
    syntax,numbers                {color {white} {} {0}}
    syntax,precompile             {color {white} {} {0}}
    syntax,punctuation            {color {white} {} {0}}
    syntax,select_background      {color {blue} {} {0}}
    syntax,select_foreground      {color {white} {} {0}}
    syntax,strings                {color {grey} {} {0}}
    syntax,warning_width          {color {grey} {} {0}}
    sidebar,-foreground           {color {0} {} {0}}
    sidebar,-background           {color {1} {} {0}}
    sidebar,-selectbackground     {color {2} {} {0}}
    sidebar,-selectforeground     {color {1} {} {0}}
    sidebar,-highlightbackground  {color {1} {} {0}}
    sidebar,-highlightcolor       {color {1} {} {0}}
    sidebar,-treestyle            {treestyle {aqua} {} {0}}
    sidebar_scrollbar,-background {color {1} {} {0}}
    sidebar_scrollbar,-foreground {color {2} {} {0}}
    sidebar_scrollbar,-thickness  {{number {5 20}} {15} {} {0}}
  }

  array set tm_scope_map {
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

  array set data          {}
  array set widgets       {}
  array set syntax        {}
  array set basecolor_map {}

  # Initialize the widgets array
  foreach {category dummy} $category_titles {
    set widgets($category) [list]
  }

  ######################################################################
  # Registers the given widget as the given type.
  proc register_widget {w type} {

    variable widgets

    if {![info exists widgets($type)]} {
      return -code error "Called theme::register_widget with unknown type ($type)"
    }

    # Add the widget to the type list
    lappend widgets($type) $w

    # Configure the widget's theme information
    catch { $w configure {*}[get_category_options $type 1] }

    # Create a binding on the widget's Destroy event to unregister it
    bind $w <Destroy> [list theme::unregister_widget $w $type]

  }

  ######################################################################
  # Returns the color to use for the given image.
  proc get_image_color {value} {

    variable orig_data
    variable fields

    if {[string is integer $value]} {
      set values [list [lindex $orig_data(syntax,background) $fields(default)] \
                       [lindex $orig_data(syntax,foreground) $fields(default)] \
                       [lindex $orig_data(syntax,warning_width) $fields(default)]]
      return [lindex $values $value]
    }

    return $value

  }

  ######################################################################
  # Creates the given image and adds it to the orig_data array.
  proc register_image {name type bgcat bgopt args} {

    variable orig_data

    array set opts     $args
    array set img_info [list basecolor $bgcat,$bgopt]

    # Transform the background/foreground colors, if necessary
    if {[info exists opts(-background)]} {
      set opts(-background) [get_image_color $opts(-background)]
    }
    if {[info exists opts(-foreground)]} {
      set opts(-foreground) [get_image_color $opts(-foreground)]
    }

    # First, create the image
    image create $type $name {*}[array get opts]

    # Discern the image information
    switch $type {
      bitmap {
        if {[info exists opts(-file)]} {
          if {![catch { open $opts(-file) r } rc]} {
            set img_info(dat) [read $rc]
            close $rc
          }
        } else {
          set img_info(dat) $opts(-data)
        }
        if {[info exists opts(-maskfile)]} {
          if {![catch { open $opts(-maskfile) r } rc]} {
            set img_info(msk) [read $rc]
            close $rc
          }
        } elseif {[info exists opts(-maskdata)]} {
          set img_info(msk) $opts(-maskdata)
        }
        if {[info exists opts(-background)]} {
          set img_info(bg) $opts(-background)
        }
        if {[info exists opts(-foreground)]} {
          set img_info(fg) $opts(-foreground)
        }
      }
      photo {
        if {[info exists opts(-file)]} {
          set img_info(dir)  "install"
          set img_info(file) [file tail $opts(-file)]
        } else {
          return -code error "photo image type only supports -file option"
        }
      }
    }

    # Add the image information to the orig_data structure
    set orig_data(images,$name) [list image [array get img_info] [list] 0]

  }

  ######################################################################
  # Unregisters the given widget of the given type.
  proc unregister_widget {w type} {

    variable widgets

    if {![info exists widgets($type)]} {
      return -code error "Called theme::register_widget with unknown type ($type)"
    }

    if {[set index [lsearch $widgets($type) $w]] != -1} {
      set widgets($type) [lreplace $widgets($type) $index $index]
    }

  }

  ######################################################################
  # Loads the given theme file.
  proc load_theme {theme_file} {

    variable data

    # Read the TKE theme file contents and store them in the data array
    read_tketheme $theme_file

    # If the theme currently does not exist, create the ttk theme
    if {[lsearch [ttk::style theme names] $data(name)] == -1} {
      create_ttk_theme $data(name)
    }

    # Set the ttk theme
    ttk::style theme use $data(name)

    # Update all UI widgets
    update_theme

  }

  ######################################################################
  # Reads the contents of the tketheme and stores the results
  proc read_tketheme {theme_file} {

    variable data
    variable fields
    variable orig_data

    # Open the tketheme file
    if {[catch { open $theme_file r } rc]} {
      return -code error [msgcat::mc "ERROR:  Unable to read %s" $theme_file]
    }

    # Read the contents from the file and close
    array set contents [read $rc]
    close $rc

    # Make things backwards compatible
    if {![info exists contents(syntax,background)]} {
      set bg  $contents(background)
      set fg  $contents(foreground)
      set abg [[ns utils]::auto_adjust_color $contents(background) 40]
      set contents(syntax) [array get contents]
      set contents(swatch) [list $bg $fg $abg]
    }

    # Copy the original data structure into the current data structure
    array unset data
    array set data [array get orig_data]

    # Load the swatch and extra data
    set data(swatch) $contents(swatch)
    set data(name)   [file rootname [file tail $theme_file]]
    set data(fname)  $theme_file

    # Load the categories
    foreach key [array names orig_data] {
      if {[info exists contents($key)]} {
        lset data($key) $fields(value) $contents($key)
      } else {
        set default_value [lindex $data($key) $fields(default)]
        switch [lindex $data($key) $fields(type)] {
          color {
            lset data($key) $fields(value) [expr {[string is integer $default_value] ? [lindex $data(swatch) $default_value] : $default_value}]
          }
          image {
            array set value $default_value
            unset -nocomplain value(basecolor)
            lset data($key) $fields(value) [array get value]
            array unset value
          }
          default {
            lset data($key) $fields(value) $default_value
          }
        }
      }
      lset data($key) $fields(changed) 1
    }

  }

  ######################################################################
  # Writes the current theme data to the given file.
  proc write_tketheme {theme_file} {

    variable data
    variable fields

    if {[catch { open $theme_file w } rc]} {
      return -code error [msgcat::mc "ERROR:  Unable to write %s" $theme_file]
    }

    puts $rc "swatch {$data(swatch)}"
    foreach key [lsort [array names data *,*]] {
      puts $rc "$key {[lindex $data($key) $fields(value)]}"
    }

    close $rc

  }

  ######################################################################
  # Reads the given TextMate theme file and extracts the relevant information
  # for tke's needs.
  proc read_tmtheme {theme_file} {

    variable data
    variable orig_data
    variable fields
    variable scope_map

    # Open the file
    if {[catch { open $theme_file r } rc]} {
      return -code error [msgcat::mc "ERROR:  Unable to read %s" $theme]
    }

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

    array set labels [get_category_options syntax 1]

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
                set labels(foreground) $color
              } else {
                foreach scope_type [string map {, { }} $scope_types] {
                  if {[info exists scope_map($scope_type)]} {
                    set labels($scope_map($scope_type)) $color
                  }
                }
              }
            } elseif {$background} {
              set background 0
              set color      [normalize_color $value]
              if {$scope_types eq ""} {
                set labels(background)    $color
                set labels(warning_width) [utils::auto_adjust_color $color 40]
                set labels(meta)          [utils::auto_adjust_color $color 40]
              }
            } elseif {$caret} {
              set caret 0
              set color [normalize_color $value]
              if {$scope_types eq ""} {
                set labels(cursor) $color
              }
            }
          }
        }
        incr depth($element) -1
      } else {
        incr depth($element)
      }
    }

    array unset data
    array set data [array get orig_data]

    # Let's take a stab at good defaults
    lset data(ttk_style,disabledfg)          $fields(value) #999999
    lset data(ttk_style,frame)               $fields(value) $labels(background)
    lset data(ttk_style,lightframe)          $fields(value) $labels(warning_width)
    lset data(ttk_style,window)              $fields(value) $labels(background)
    lset data(ttk_style,dark)                $fields(value) #cfcdc8
    lset data(ttk_style,darker)              $fields(value) #bab5ab
    lset data(ttk_style,darkest)             $fields(value) #9e9a91
    lset data(ttk_style,lighter)             $fields(value) $labels(foreground)
    lset data(ttk_style,lightest)            $fields(value) $labels(foreground)
    lset data(ttk_style,selectbg)            $fields(value) #4a6984
    lset data(ttk_style,selectfg)            $fields(value) #ffffff
    lset data(ttk_style,window)              $fields(value) $labels(background)
    lset data(menus,-background)             $fields(value) $labels(background)
    lset data(menus,-foreground)             $fields(value) $labels(foreground)
    lset data(tabs,-background)              $fields(value) $labels(warning_width)
    lset data(tabs,-foreground)              $fields(value) $labels(foreground)
    lset data(tabs,-activebackground)        $fields(value) $labels(background)
    lset data(tabs,-inactivebackground)      $fields(value) $labels(background)
    lset data(text_scrollbar,-background)    $fields(value) $labels(background)
    lset data(text_scrollbar,-foreground)    $fields(value) $labels(warning_width)
    lset data(sidebar,-foreground)           $fields(value) $labels(background)
    lset data(sidebar,-background)           $fields(value) $labels(foreground)
    lset data(sidebar,-selectbackground)     $fields(value) $labels(warning_width)
    lset data(sidebar,-selectforeground)     $fields(value) $labels(foreground)
    lset data(sidebar,-highlightbackground)  $fields(value) $labels(foreground)
    lset data(sidebar,-highlightcolor)       $fields(value) $labels(foreground)
    lset data(sidebar_scrollbar,-background) $fields(value) $labels(foreground)
    lset data(sidebar_scrollbar,-foreground) $fields(value) $labels(warning_width)

    # Setup a default swatch and clear the meta data
    set data(swatch) [list $labels(background) $labels(warning_width) $labels(foreground)]

  }

  ######################################################################
  # Exports the current theme into the specified output directory.
  # Returns 1 if the exporting of information is successful; otherwise,
  # returns 0.
  proc export {odir} {

    variable data
    variable fields

    # Get a copy of the data to write
    array set export_data [array get data]

    # Check to see if there are any photos that need to copied to the
    # output directory
    foreach key [array names data images,*] {
      array set value_array [lindex $data($key) $fields(value)]
      if {[info exists value_array(dir)] && ($value_array(dir) ne "install")} {
        if {$value_array(dir) eq "user"} {
          set dir [file join $::tke_home themes $data(name)]
        } else {
          set dir $value_array(dir)
          set value_array(dir) "user"
          lset export_data($key) $fields(value) [array get value_array]
        }
        if {[catch { file copy -force [file join $dir $value_array(file)] $odir }]} {
          return 0
        }
      }
    }

    # Open the theme file for writing
    if {[catch { open [file join $odir $data(name).tketheme] w } rc]} {
      return 0
    }

    # Write the contents
    puts $rc "swatch {$export_data(swatch)}"
    foreach key [lsort [array names export_data *,*]] {
      puts $rc "$key {[lindex $export_data($key) $fields(value)]}"
    }

    # Close the file
    close $rc

    return 1

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
  # Converts the given imaged
  proc convert_image {value name} {

    array set value_array $value

    # Get the type of image to create from the value
    set value_type [expr {[info exists value_array(dat)] ? "bitmap" : "photo"}]

    # If the image exists but is the wrong type, delete it
    if {[lsearch [image names] $name] != -1} {
      if {$value_type ne [image type $name]} {
        image delete $name
        image create $value_type $name
      }
    } else {
      image create $value_type $name
    }

    # Configure the image
    if {$value_type eq "bitmap"} {
      foreach {field opt} [list dat -data bg -background fg -foreground msk -maskdata] {
        if {[info exists value_array($field)] && ($value_array($field) ne "")} {
          lappend opts $opt $value_array($field)
        }
      }
      $name configure {*}$opts
    } else {
      switch $value_array(dir) {
        install { $name configure -file [file join $::tke_dir lib images $value_array(file)] }
        user    { $name configure -file [file join $::tke_home themes images $value_array(file)] }
        default { $name configure -file [file join $value_array(dir) $value_array(file)] }
      }
    }

    return $name

  }

  ######################################################################
  # Populates the themer category table with the stored theme information.
  proc populate_themer_category_table {tbl} {

    variable data
    variable fields
    variable category_titles
    variable basecolor_map

    # Make sure the basecolor_map is empty
    catch { array unset basecolor_map }

    # Clear the table
    $tbl delete 0 end

    # Insert the needed rows in the table
    foreach {category title} $category_titles {
      set parent [$tbl insertchild root end [list $title {} {}]]
      foreach name [lsort [array names data $category,*]] {
        set opt [lindex [split $name ,] 1]
        set row [$tbl insertchild $parent end [list $opt [lindex $data($name) $fields(value)] $category]]
        switch [lindex $data($name) $fields(type)] {
          image {
            array set default_value [lindex $data($name) $fields(default)]
            $tbl cellconfigure $row,value \
              -image      [convert_image [lindex $data($name) $fields(value)] $opt] \
              -background [lindex $data($default_value(basecolor)) $fields(value)]
            lappend basecolor_map($default_value(basecolor)) $row
          }
          color {
            set color [lindex $data($name) $fields(value)]
            $tbl cellconfigure $row,value \
              -background $color \
              -foreground [utils::get_complementary_mono_color $color]
          }
        }
      }
    }

  }

  ######################################################################
  # Updates the themer category table row.
  proc set_themer_category_table_row {tbl row value} {

    variable data
    variable fields
    variable basecolor_map

    # Get the category and option values
    set cat [$tbl cellcget $row,category -text]
    set opt [$tbl cellcget $row,opt      -text]

    # Update the tablelist
    $tbl cellconfigure $row,value -text $value

    # Further modify the tablelist cell based on the type
    switch [lindex $data($cat,$opt) $fields(type)] {
      image {
        array set default_value [lindex $data($cat,$opt) $fields(default)]
        $tbl cellconfigure $row,value \
          -image      [convert_image $value $opt] \
          -background [lindex $data($default_value(basecolor)) $fields(value)]
      }
      color {
        $tbl cellconfigure $row,value -background $value -foreground [utils::get_complementary_mono_color $value]
        if {[info exists basecolor_map($cat,$opt)]} {
          foreach img_row $basecolor_map($cat,$opt) {
            $tbl cellconfigure $img_row,value -background $value
          }
        }
      }
    }

    # Update the theme data
    lset data($cat,$opt) $fields(value)   $value
    lset data($cat,$opt) $fields(changed) 1

  }

  ######################################################################
  # Returns a key/pair list containing the syntax colors to use for all
  # text widgets.  Called by the syntax namespace when setting the
  # language.
  proc get_syntax_colors {} {

    variable syntax

    return [array get syntax]

  }

  ######################################################################
  # Returns the name of the current theme.
  proc get_current_theme {} {

    variable data

    return $data(name)

  }

  ######################################################################
  # Updates the current theme.
  proc update_theme {} {

    variable widgets

    # Update the widgets
    foreach category [array names widgets] {
      update_$category
    }

  }

  ######################################################################
  # Updates the syntax data for all text widgets.
  proc update_syntax {} {

    variable widgets
    variable syntax
    variable colorizers

    # Get the given syntax information
    array set syntax [get_category_options syntax 1]

    # Remove theme values that aren't in the Appearance/Colorize array
    foreach name [::struct::set difference $colorizers [[ns preferences]::get Appearance/Colorize]] {
      set syntax($name) ""
    }

    # Update all of the syntax
    foreach txt $widgets(syntax) {
      [ns syntax]::set_language [[ns syntax]::get_current_language $txt] $txt 1
    }

  }

  ######################################################################
  # Updates the given tab bar.
  proc update_tabs {} {

    update_widget tabs

  }

  ######################################################################
  # Update
  proc update_text_scrollbar {} {

    update_widget text_scrollbar

  }

  ######################################################################
  # Updates the menus.
  proc update_menus {} {

    variable widgets

    update_menu_helper $widgets(menus) [get_category_options menus]

  }

  ######################################################################
  # Updates the sidebar with the given theme settings.
  proc update_sidebar {} {

    update_widget sidebar

  }

  ######################################################################
  # Updates the given sidebar scrollbar widget.
  proc update_sidebar_scrollbar {} {

    update_widget sidebar_scrollbar

  }

  ######################################################################
  # Updates the images with the given settings.
  proc update_images {} {

    variable data
    variable fields

    # Convert all of the images
    foreach name [array names data images,*] {
      if {[lindex $data($name) $fields(changed)]} {
        convert_image [lindex $data($name) $fields(value)] [lindex [split $name ,] 1]
        lset data($name) $fields(changed) 0
      }
    }

  }

  ######################################################################
  # Recursively sets the given menu's submenus to match the specified options.
  proc update_menu_helper {mnu opts} {

    $mnu configure {*}$opts

    if {[set last [$mnu index end]] ne "none"} {
      for {set i 0} {$i <= $last} {incr i} {
        if {[$mnu type $i] eq "cascade"} {
          update_menu_helper [$mnu entrycget $i -menu] $opts
        }
      }
    }

  }


  ######################################################################
  # Configures the given ttk name with the updated colors.
  proc update_ttk_style {} {

    variable data

    # Get the name of the ttk style currently in use
    set name [ttk::style theme use]

    # Get the ttk style option/value pairs
    array set opts [get_category_options ttk_style 1]

    # Configure the theme
    ttk::style theme settings $name {

      # Configure the application
      ttk::style configure "." \
        -background        $opts(frame) \
        -foreground        $opts(lighter) \
        -bordercolor       $opts(darkest) \
        -darkcolor         $opts(dark) \
        -troughcolor       $opts(darker) \
        -arrowcolor        $opts(lighter) \
        -selectbackground  $opts(selectbg) \
        -selectforeground  $opts(selectfg) \
        -selectborderwidth 0 \
        -font              TkDefaultFont
      ttk::style map "." \
        -background       [list disabled $opts(frame) \
                                active   $opts(lighter)] \
        -foreground       [list disabled $opts(disabledfg)] \
        -selectbackground [list !focus   $opts(darkest)] \
        -selectforeground [list !focus   white]

      # Configure TButton widgets
      ttk::style configure TButton \
        -anchor center -width -11 -padding 5 -relief raised -background $opts(frame) -foreground $opts(lighter)
      ttk::style map TButton \
        -background  [list disabled  $opts(lighter) \
                           pressed   $opts(darker) \
                           active    $opts(lightframe)] \
        -lightcolor  [list pressed   $opts(darker)] \
        -darkcolor   [list pressed   $opts(darker)] \
        -bordercolor [list alternate "#000000"]

      # Configure BButton widgets
      ttk::style configure BButton \
        -anchor center -padding 2 -relief flat -background $opts(frame) -foreground $opts(lighter)
      ttk::style map BButton \
        -background  [list disabled  $opts(frame) \
                           pressed   $opts(darker) \
                           active    $opts(lightframe)] \
        -lightcolor  [list pressed   $opts(darker)] \
        -darkcolor   [list pressed   $opts(darker)] \
        -bordercolor [list alternate "#000000"]

      # Configure ttk::menubutton widgets
      ttk::style configure TMenubutton \
        -width 0 -padding 0 -relief flat -background $opts(frame) -foreground $opts(lighter)
      ttk::style map TMenubutton \
        -background  [list disabled  $opts(frame) \
                           pressed   $opts(lightframe) \
                           active    $opts(lightframe)] \
        -lightcolor  [list pressed   $opts(darker)] \
        -darkcolor   [list pressed   $opts(darker)] \
        -bordercolor [list alternate "#000000"]

      # Configure ttk::radiobutton widgets
      ttk::style configure TRadiobutton \
        -width 0 -padding 0 -relief flat -background $opts(frame) -foreground $opts(lighter)
      ttk::style map TRadiobutton \
        -background  [list disabled $opts(frame) \
                           active   $opts(lightframe)]

      # Configure ttk::entry widgets
      ttk::style configure TEntry -padding 1 -insertwidth 1 -foreground black
      ttk::style map TEntry \
        -background  [list readonly $opts(frame)] \
        -foreground  [list readonly $opts(lighter)] \
        -bordercolor [list focus    $opts(selectbg)] \
        -lightcolor  [list focus    "#6f9dc6"] \
        -darkcolor   [list focus    "#6f9dc6"]

      # Configure ttk::scrollbar widgets
      ttk::style configure TScrollbar \
        -relief flat -troughcolor $opts(lightframe)
      ttk::style map TScrollbar \
        -background  [list disabled $opts(frame) \
                           active   $opts(frame)]

      # Configure ttk::labelframe widgets
      ttk::style configure TLabelframe \
        -labeloutside true -labelmargins {0 0 0 4} -borderwidth 2 -relief raised

      # Configure ttk::spinbox widgets
      ttk::style configure TSpinbox \
        -relief flat -padding 2 -background $opts(frame) -foreground $opts(lighter) -fieldbackground $opts(frame)

      # Configure ttk::checkbutton widgets
      ttk::style configure TCheckbutton \
        -relief flat -padding 2 -background $opts(frame) -foreground $opts(lighter)
      ttk::style map TCheckbutton \
        -background  [list disabled  $opts(lighter) \
                           pressed   $opts(darker) \
                           active    $opts(lightframe)] \
        -lightcolor  [list pressed   $opts(darker)] \
        -darkcolor   [list pressed   $opts(darker)] \
        -bordercolor [list alternate "#000000"]

      # Configure ttk::combobox widgets
      ttk::style configure TCombobox \
        -relief flat -background $opts(frame) -foreground $opts(frame)
      ttk::style map TCombobox \
        -background [list disabled  $opts(lighter) \
                          pressed   $opts(darker) \
                          active    $opts(lightframe)]

      # Configure panedwindow sash widgets
      ttk::style configure Sash -sashthickness 5 -gripcount 10

    }

  }

  ######################################################################
  # Shared procedure used to configure all widgets of the given type.
  proc update_widget {type} {

    variable widgets

    # Get the options
    set opts [get_category_options $type]

    # Configure all widgets of the given type
    foreach w $widgets($type) {
      $w configure {*}$opts
    }

  }

  ######################################################################
  # Returns the category widget options for the given category.
  proc get_category_options {category {all 0}} {

    variable data
    variable fields

    set opts [list]

    # Get the list of options to pass to sidebar tablelist
    foreach name [array names data $category,*] {
      if {$all || [lindex $data($name) $fields(changed)]} {
        lappend opts [lindex [split $name ,] 1] [lindex $data($name) $fields(value)]
        lset data($name) $fields(changed) 0
      }
    }

    return $opts

  }

  ######################################################################
  # Returns the list of swatches for this theme.
  proc swatch_do {action args} {

    variable data

    switch $action {
      get     { return $data(swatch) }
      set     { lset data(swatch) [lindex $args 0] [lindex $args 1] }
      append  { lappend data(swatch) {*}$args }
      delete  { set data(swatch) [lreplace $data(swatch) [lindex $args 0] [lindex $args 0]] }
      length  { return [llength $data(swatch)] }
      index   { return [lindex $data(swatch) [lindex $args 0]] }
      default { return -code error "Unknown swatch action" }
    }

  }

  ######################################################################
  # Returns the meta information for the theme.
  proc meta_do {action category opt args} {

    variable data

    # Create the lookup key
    set key meta,$category,$opt

    switch $action {
      exists { return [info exists data($key)] }
      get    { return $data($key) }
      set    { set data($key) $args }
      delete { unset -nocomplain data($key) }
    }

  }

  ######################################################################
  # Returns the value for the given category option.
  proc get_value {category opt} {

    variable data
    variable fields

    if {![info exists data($category,$opt)]} {
      return -code error "Unknown category/option specified ($category $opt)"
    }

    return [lindex $data($category,$opt) $fields(value)]

  }

  ######################################################################
  # Returns the type for the given category option.
  proc get_type {category opt} {

    variable data
    variable fields

    if {![info exists data($category,$opt)]} {
      return -code error "Unknown category/option specified ($category $opt)"
    }

    return [lindex $data($category,$opt) $fields(type)]

  }

  ######################################################################
  # Initializes the themes list.
  proc create_ttk_theme {name} {

    # Add a few styles to the default (light) theme
    ttk::style theme settings clam {

      # BButton
      ttk::style configure BButton [ttk::style configure TButton]
      ttk::style configure BButton -anchor center -padding 2 -relief flat
      ttk::style map       BButton [ttk::style map TButton]
      ttk::style layout    BButton [ttk::style layout TButton]

    }

    # Create the theme
    ttk::style theme create $name -parent clam

  }

}
