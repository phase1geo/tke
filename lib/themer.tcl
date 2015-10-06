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

namespace eval themer {

  variable theme_dir      [file join $::tke_home themes]
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
    highlighter       {"yellow" ""            "" 0 0}
    meta              {""       "-foreground" "" 0 0}
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
                  lset labels(meta)          $label_index(color) [utils::auto_adjust_color $color 40]
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

    variable data

    # Open the tketheme file
    if {![catch { open $theme r } rc]} {
      return -code error [msgcat::mc "ERROR:  Unable to read %s" $theme]
    }

    # Read the contents from the file and close
    array set contents [read $rc]
    close $rc

    # Load the categories
    foreach category [list meta swatch ttk_style menus tabs text_scrollbar syntax sidebar sidebar_scrollbar] {
      if {[info exists contents(meta)]} {
        array set data($category) $contents($category)
      } else {
        array set data($category) [list]
      }
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
    variable data

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

    variable data

    if {![info exists data(plus)]} {
      set plus_file  [file join images plus.gif]
      set data(plus) [image create photo -file $plus_file]
    }

    if {![winfo exists .thmwin]} {

      toplevel .thmwin
      wm title .thmwin [msgcat::mc "Theme Editor"]

      ttk::labelframe .thmwin.sf -text [msgcat::mc "Swatch"]
      for {set i 0} {$i < 5} {incr i} {
        pack [ttk::button .thmwin.sf.b$i -style BButton -image $data(plus)] -side left -padx 2 -pady 2
      }

      ttk::panedwindow .thmwin.pw -orient horizontal

      # Add the categories panel
      .thmwin.pw add [ttk::labelframe .thmwin.pw.lf -text [msgcat::mc "Categories"]]
      set data(widgets,cat) [tablelist::tablelist .thmwin.pw.lf.tbl -columns {0 Options} -exportselection 0 -yscrollcommand { utils::set_yscrollbar .thmwin.pw.lf.vb }]
      ttk::scrollbar .thmwin.pw.lf.vb -orient vertical -command { .thmwin.pw.lf.tbl yview }

      grid rowconfigure    .thmwin.pw.lf 0 -weight 1
      grid columnconfigure .thmwin.pw.lf 0 -weight 1
      grid .thmwin.pw.lf.tbl -row 0 -column 0 -sticky news
      grid .thmwin.pw.lf.vb  -row 0 -column 1 -sticky ns

      # Add the right paned window
      .thmwin.pw add [ttk::labelframe .thmwin.pw.rf -text [msgcat::mc "Details"]] -weight 1

      set bwidth [msgcat::mcmax "Reset" "Save As" "Import" "Create" "Save" "Cancel"]

      # Create the button frame
      ttk::frame  .thmwin.bf
      set data(widgets,reset) [ttk::button .thmwin.bf.reset  -text [msgcat::mc "Reset"] -width $bwidth -command {
        array set themer::labels [array get themer::orig_labels]
        themer::highlight
      }]
      set data(widgets,saveas) [ttk::button .thmwin.bf.saveas -text [msgcat::mc "Save As"] -width $bwidth -command {
        set orig_tmtheme    $themer::tmtheme
        set themer::tmtheme ""
        if {[themer::write_tketheme]} {
          destroy .thmwin
        } else {
          set themer::tmtheme $orig_tmtheme
        }
      }]
      set data(widgets,action) [ttk::button .thmwin.bf.import -text [msgcat::mc "Import"] -width $bwidth -command {
        if {[themer::write_tketheme]} {
          destroy .thmwin
        }
      }]
      ttk::button .thmwin.bf.cancel -text [msgcat::mc "Cancel"] -width $bwidth -command {
        destroy .thmwin
      }

      # pack .thmwin.bf.reset  -side left  -padx 2 -pady 2
      pack .thmwin.bf.cancel -side right -padx 2 -pady 2
      pack .thmwin.bf.import -side right -padx 2 -pady 2

      pack .thmwin.sf -fill x
      pack .thmwin.pw -fill both -expand yes
      pack .thmwin.bf -fill x

    }

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
    lset labels(highlighter)       $label_index(color) "yellow"
    lset labels(line_number)       $label_index(color) [utils::auto_adjust_color "black" 40]
    lset labels(warning_width)     $label_index(color) [utils::auto_adjust_color "black" 40]
    lset labels(meta)              $label_index(color) [utils::auto_adjust_color "black" 40]
    lset labels(difference_sub)    $label_index(color) [utils::auto_mix_colors "black" r 30]
    lset labels(difference_add)    $label_index(color) [utils::auto_mix_colors "black" g 30]

  }

}

