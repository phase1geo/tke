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

source [file join $::tke_dir lib bitmap.tcl]

namespace eval themer {

  variable tmtheme        ""

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

  array set data {
    cat,meta   {}
    cat,swatch {}
    cat,ttk_style {
      disabledfg "#999999"
      frame      "#4e5044"
      lightframe "#666959"
      window     "#4e5044"
      dark       "#cfcdc8"
      darker     "#bab5ab"
      darkest    "#9e9a91"
      lighter    "#f8f8f2"
      lightest   "#f8f8f2"
      selectbg   "#4a6984"
      selectfg   "#ffffff"
    }
    cat,menus {
      -relief flat
    }
    cat,tabs {
      -background         "#4e5044"
      -foreground         "#f8f8f2"
      -activebackground   "#272822"
      -inactivebackground "#4e5044"
      -relief             "flat"
    }
    cat,text_scrollbar {
      -background "#272822"
      -foreground "#4e5044"
      -thickness  15
    }
    cat,syntax {
      background        "#272822"
      border_highlight  "gold"
      comments          "#75715e"
      cursor            "#f8f8f0"
      difference_add    "#274622"
      difference_sub    "#452822"
      foreground        "#f8f8f2"
      highlighter       "yellow"
      keywords          "#f92672"
      line_number       "#4e5044"
      meta              "#4e5044"
      miscellaneous1    "#66d9ef"
      miscellaneous2    "#fd971f"
      miscellaneous3    "#f92672"
      numbers           "#ae81ff"
      precompile        "#d0d0ff"
      punctuation       "#f92672"
      select_background "blue"
      select_foreground "white"
      strings           "#e6db74"
      warning_width     "#4e5044"
    }
    cat,sidebar {
      -foreground          "#f8f8f2"
      -background          "#4e5044"
      -selectbackground    "#272822"
      -selectforeground    "#f8f8f2"
      -highlightbackground "#4e5044"
      -highlightcolor      "#4e5044"
    }
    cat,sidebar_scrollbar {
      -background      "#4e5044"
      -foreground      "#f8f8f2"
      -thickness       15
    }
  }

  set data(theme_dir) [file join $::tke_home themes]

  if {[catch { ttk::spinbox .__tmp }]} {
    set bg                [utils::get_default_background]
    set fg                [utils::get_default_foreground]
    set data(sb)          "spinbox"
    set data(sb_opts)     "-relief flat -buttondownrelief flat -buttonuprelief flat -background $bg -foreground $fg"
    set data(sb_normal)   "configure -state normal"
    set data(sb_disabled) "configure -state disabled"
  } else {
    set data(sb)          "ttk::spinbox"
    set data(sb_opts)     ""
    set data(sb_normal)   "state !disabled"
    set data(sb_disabled) "state disabled"
    destroy .__tmp
  }

  ######################################################################
  # Returns the value of the given color
  proc get_color_values {color} {

    lassign [winfo rgb . $color] r g b
    lassign [utils::rgb_to_hsv [set r [expr $r >> 8]] [set g [expr $g >> 8]] [set b [expr $b >> 8]]] hue saturation value

    return [list $value $r $g $b]

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
  # Displays the theme editor with the specified theme information.
  proc edit_theme {theme} {

    variable data

    # Save the current theme
    set data(curr_theme) $theme

    # Get the list of themes
    load_themes

    # Read the specified theme
    read_tketheme $data(files,$theme)

    # Initialize the themer
    initialize

  }

  ######################################################################
  # Loads the contents of the themes directories.
  proc load_themes {} {

    variable data

    # Clear the themes
    array unset data files,*

    # Load the tke_dir theme files
    foreach tdir [list [file join $::tke_dir data themes] [file join $::tke_home themes]] {
      foreach theme [glob -nocomplain -directory $tdir *.tketheme] {
        set data(files,[file rootname [file tail $theme]]) $theme
      }
    }

  }

  ######################################################################
  # Reads the given TextMate theme file and extracts the relevant information
  # for tke's needs.
  proc read_tmtheme {theme} {

    variable data
    variable labels
    variable scope_map
    variable all_scopes
    variable tmtheme
    variable orig_labels
    variable widgets
    variable label_index

    set tmtheme $theme

    # Open the file
    if {[catch { open $theme r } rc]} {
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

    # Save the labels array to orig_labels
    array set orig_labels [array get labels]

  }

  ######################################################################
  # Reads the contents of the tketheme and stores the results
  proc read_tketheme {theme} {

    variable data

    # Open the tketheme file
    if {[catch { open $theme r } rc]} {
      return -code error [msgcat::mc "ERROR:  Unable to read %s" $theme]
    }

    # Read the contents from the file and close
    array set contents [read $rc]
    close $rc

    # Make things backwards compatible
    if {![info exists contents(syntax)]} {
      set bg  $contents(background)
      set fg  $contents(foreground)
      set abg [utils::auto_adjust_color $contents(background) 40]
      set contents(syntax) [array get contents]
      set contents(meta)   [list]
      set contents(swatch) [list $bg $abg $fg]
      set contents(ttk_style) [list \
        disabledfg #999999 \
        frame      $bg \
        lightframe $abg \
        window     $bg \
        dark       #cfcdc8 \
        darker     #bab5ab \
        darkest    #9e9a91 \
        lighter    $fg \
        lightest   $fg \
        selectbg   #4a6984 \
        selectfg   #ffffff \
      ]
      set contents(menus) [list -relief flat]
      set contents(tabs)  [list \
        -background         $abg \
        -foreground         $fg \
        -activebackground   $bg \
        -inactivebackground $abg \
        -relief             flat \
      ]
      set contents(text_scrollbar) [list \
        -background $bg \
        -foreground $abg \
        -thickness  15 \
      ]
      set contents(sidebar) [list \
        -foreground          $bg \
        -background          $fg \
        -selectbackground    $abg \
        -selectforeground    $fg \
        -highlightbackground $fg \
        -highlightcolor      $fg \
      ]
      set contents(sidebar_scrollbar) [list \
        -background $fg \
        -foreground $abg \
        -thickness  15 \
      ]
    }

    # Load the categories
    foreach category [array names data cat,*] {
      lassign [split $category ,] dummy cat
      if {[info exists contents($cat)]} {
        set data($category) $contents($cat)
      }
    }

  }

  ######################################################################
  # Writes the TKE theme file to the theme directory.
  proc write_tketheme {theme} {

    variable data

    # Create the directory if it does not exist
    file mkdir [file dirname $theme]

    # Open the file for writing
    if {[catch { open $theme w } rc]} {
      return -code error [msgcat::mc "ERROR:  Unable to write %s" $theme]
    }

    # Output the categories
    foreach category [array names data cat,*] {
      lassign [split $category ,] dummy cat
      puts $rc "$cat \{"
      foreach {name value} $data($category) {
        if {$value eq ""} {
          puts $rc "  $name #ffffff"
        } else {
          puts $rc "  $name $value"
        }
      }
      puts $rc "\}\n"
    }

    # Close the file
    close $rc

    # Get the basename of the theme
    set theme_name [file rootname [file tail $theme]]

    # Add the file to the theme list
    set data(files,$theme_name) $theme

    # Reload the themes
    themes::reload $theme_name

    return 1

  }

  ######################################################################
  # Applies the current settings to the current TKE session.
  proc apply_theme {} {

    variable data

    # Get the current theme from themes
    set basename [themes::get_current_theme]

    # Create the user theme directory if it does not exist
    file mkdir $data(theme_dir)

    # Save off the theme file to a temporary file
    file rename -force $data(files,$basename) [file join $data(theme_dir) $basename.orig]

    # Write the theme and reload it
    catch { themer::write_tketheme $data(files,$data(curr_theme)) } rc

    # Restore the original file, if it exists
    file rename -force [file join $data(theme_dir) $basename.orig] $data(files,$basename)

    # Clear the apply button
    $data(widgets,apply) state disabled

  }

  ######################################################################
  # Creates the UI for the importer, automatically populating it with
  # the default values.
  proc create {} {

    variable data

    if {![info exists data(image,plus)]} {
      set name [file join $::tke_dir lib images plus.bmp]
      set data(image,plus) [image create bitmap -file $name -maskfile $name -foreground grey]
    }

    if {![winfo exists .thmwin]} {

      toplevel .thmwin
      wm title .thmwin [msgcat::mc "Theme Editor"]
      wm geometry .thmwin 800x600
      wm protocol .thmwin WM_DELETE_WINDOW [list themer::close_window]

      # Add the swatch panel
      set data(widgets,sf)   [ttk::labelframe .thmwin.sf -text [msgcat::mc "Swatch"]]
      pack [set data(widgets,plus) [ttk::frame .thmwin.sf.plus]] -side left -padx 2 -pady 2
      pack [ttk::button .thmwin.sf.plus.b -style BButton -image $data(image,plus) -command [list themer::add_swatch]]
      set data(widgets,plus_text) [ttk::label  .thmwin.sf.plus.l -text ""]

      ttk::panedwindow .thmwin.pw -orient horizontal

      # Add the categories panel
      .thmwin.pw add [ttk::labelframe .thmwin.pw.lf -text [msgcat::mc "Categories"]]
      set data(widgets,cat) [tablelist::tablelist .thmwin.pw.lf.tbl \
        -columns {0 Options 0 Value 0 {}} -treecolumn 0 -exportselection 0 -width 0 \
        -yscrollcommand { utils::set_yscrollbar .thmwin.pw.lf.vb } \
      ]
      ttk::scrollbar .thmwin.pw.lf.vb -orient vertical -command { .thmwin.pw.lf.tbl yview }

      $data(widgets,cat) columnconfigure 0 -name opt
      $data(widgets,cat) columnconfigure 1 -name value    -formatcommand [list themer::format_category_value]
      $data(widgets,cat) columnconfigure 2 -name category -hide 1

      bind $data(widgets,cat) <<TablelistSelect>> [list themer::handle_category_selection]

      grid rowconfigure    .thmwin.pw.lf 0 -weight 1
      grid columnconfigure .thmwin.pw.lf 0 -weight 1
      grid .thmwin.pw.lf.tbl -row 0 -column 0 -sticky news
      grid .thmwin.pw.lf.vb  -row 0 -column 1 -sticky ns

      # Add the right paned window
      .thmwin.pw add [set data(widgets,df) [ttk::labelframe .thmwin.pw.rf -text [msgcat::mc "Details"]]] -weight 1

      set bwidth [msgcat::mcmax "Open" "Save" "Import" "Create" "Save" "Cancel" "Apply" "Done"]

      # Create the button frame
      set data(widgets,bf)     [ttk::frame .thmwin.bf]
      set data(widgets,open)   [ttk::button .thmwin.bf.open   -style BButton -text [msgcat::mc "Open"]   -width $bwidth -command [list themer::start_open_frame]]
      set data(widgets,import) [ttk::button .thmwin.bf.import -style BButton -text [msgcat::mc "Import"] -width $bwidth -command [list themer::import]]
      set data(widgets,apply)  [ttk::button .thmwin.bf.apply  -style BButton -text [msgcat::mc "Apply"]  -width $bwidth -command [list themer::apply_theme]]
      set data(widgets,save)   [ttk::button .thmwin.bf.save   -style BButton -text [msgcat::mc "Save"]   -width $bwidth -command [list themer::start_save_frame]]
      set data(widgets,cancel) [ttk::button .thmwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width $bwidth -command [list themer::close_window]]

      pack $data(widgets,open)   -side left  -padx 2 -pady 2
      pack $data(widgets,import) -side left  -padx 2 -pady 2
      pack $data(widgets,cancel) -side right -padx 2 -pady 2
      pack $data(widgets,save)   -side right -padx 2 -pady 2
      pack $data(widgets,apply)  -side right -padx 2 -pady 2

      # Create the open frame
      set data(widgets,of) [ttk::frame .thmwin.of]
      ttk::frame .thmwin.of.lf
      menu .thmwin.of.mnu -tearoff 0 -postcommand [list themer::add_menu_themes .thmwin.of.mnu]
      set data(widgets,open_mb) [ttk::menubutton .thmwin.of.mb -direction above -text [msgcat::mc "Choose Theme"] -menu .thmwin.of.mnu]
      ttk::button .thmwin.of.close -style BButton -text [msgcat::mc "Done"] -width $bwidth -command [list themer::end_open_frame]

      grid columnconfigure .thmwin.of 0 -weight 1
      grid columnconfigure .thmwin.of 1 -weight 1
      grid columnconfigure .thmwin.of 2 -weight 1
      grid .thmwin.of.lf    -row 0 -column 0 -sticky news -padx 2 -pady 2
      grid .thmwin.of.mb    -row 0 -column 1 -sticky ns   -padx 2 -pady 2
      grid .thmwin.of.close -row 0 -column 2 -sticky e    -padx 2 -pady 2

      # Create the save frame
      set data(widgets,wf)      [ttk::frame .thmwin.wf]
      set data(widgets,save_cb) [ttk::combobox .thmwin.wf.cb -width 30 -postcommand [list themer::add_combobox_themes .thmwin.wf.cb]]
      ttk::button .thmwin.wf.save   -style BButton -text [msgcat::mc "Save"]   -width $bwidth -command [list themer::save_theme]
      ttk::button .thmwin.wf.cancel -style BButton -text [msgcat::mc "Cancel"] -width $bwidth -command [list themer::end_save_frame]

      pack .thmwin.wf.cancel -side right -padx 2 -pady 2
      pack .thmwin.wf.save   -side right -padx 2 -pady 2
      pack .thmwin.wf.cb     -side right -padx 2 -pady 2

      pack .thmwin.sf -fill x
      pack .thmwin.pw -fill both -expand yes
      pack .thmwin.bf -fill x

      # Disable buttons
      $data(widgets,apply) state disabled

      # Create the detail panels
      create_detail_relief
      create_detail_number
      create_detail_color
      create_detail_bitmap

    }

  }

  ######################################################################
  # Called whenever the theme editor window is closed.
  proc close_window {} {

    variable data

    # Cause the original theme to be reloaded in the UI
    themes::reload

    # Delete the swatch images
    foreach swatch [winfo children $data(widgets,sf)] {
      lappend images [$swatch.b cget -image]
    }
    image delete {*}$images

    # Delete the data array
    array unset data *,*

    # Destroy the window
    destroy .thmwin

  }

  ######################################################################
  # Closes the button frame and displays the open frame.
  proc start_open_frame {} {

    variable data

    pack forget $data(widgets,bf)
    pack $data(widgets,of) -fill x

  }

  ######################################################################
  # Closes the open frame and redisplays the button frame.
  proc end_open_frame {} {

    variable data

    pack forget $data(widgets,of)
    pack $data(widgets,bf) -fill x

  }

  ######################################################################
  # Closes the button frame and displays the save frame.
  proc start_save_frame {} {

    variable data

    # Display the save panel
    pack forget $data(widgets,bf)
    pack $data(widgets,wf) -fill x

    # Set the combobox data to the current theme name
    $data(widgets,save_cb) set $data(curr_theme)

  }

  ######################################################################
  # Saves the current theme using selected name.
  proc save_theme {} {

    variable data

    # Get the theme name from the combobox
    set theme_name [$data(widgets,save_cb) get]

    if {![info exists data(files,$theme_name)]} {
      set data(files,$theme_name) [file join $data(theme_dir) $theme_name.tketheme]
    }

    # Write the theme to disk
    catch { write_tketheme $data(files,$theme_name) }

    # Save the current theme
    set data(curr_theme) $theme_name

    # End the save frame
    end_save_frame

  }

  ######################################################################
  # Closes the save frame and redisplays the button frame.
  proc end_save_frame {} {

    variable data

    # Redisplay the button frame
    pack forget $data(widgets,wf)
    pack $data(widgets,bf) -fill x

  }

  ######################################################################
  # Formats the category value.
  proc format_category_value {value} {

    variable data

    lassign [$data(widgets,cat) formatinfo] key row col

    # Attempt to convert the value into a color and display the color in the background of the cell
    if {![catch {
      switch [llength [set values [split $value ,]]] {
        0 { set color #ffffff }
        1 { set color [lindex $values 0] }
        2 { set color [utils::auto_adjust_color [lindex $values 0] [lindex $values 1] manual] }
        3 { set color [utils::auto_mix_colors   [lindex $values 0] [lindex $values 1] [lindex $values 2]] }
      }
      lassign [get_color_values $color] val
      $data(widgets,cat) cellconfigure $row,$col -background $color -foreground [expr {($val < 128) ? "white" : "black"}]
    }]} {
      return $color
    }

    return $value

  }

  ######################################################################
  # Handles a change to the category selection.
  proc handle_category_selection {} {

    variable data

    # Clear the details frame
    catch { pack forget {*}[pack slaves $data(widgets,df)] }

    # Get the currently selected row
    if {([set row [$data(widgets,cat) curselection]] ne "") && ([$data(widgets,cat) parentkey $row] ne "root")} {

      # Get the row values
      set data(row)      $row
      set data(opt)      [$data(widgets,cat) cellcget $row,opt      -text]
      set data(category) [$data(widgets,cat) cellcget $row,category -text]
      set value          [$data(widgets,cat) cellcget $row,value    -text]

      # Remove the selection from the color cell
      $data(widgets,cat) cellselection clear $row,value

      switch -exact -- $data(opt) {
        -relief {
          if {$data(category) eq "tabs"} {
            detail_show_relief $value [list flat raised]
          } else {
            detail_show_relief $value [list raised sunken flat ridge solid groove]
          }
        }
        -thickness {
          detail_show_number "Thickness" $value 5 20
        }
        -bitmap {
          detail_show_bitmap $value
        }
        default {
          detail_show_color $value
        }
      }

    }

  }

  ######################################################################
  # Adds the available themes to the given menu.
  proc add_menu_themes {mnu} {

    variable data

    # Clear the menu
    $mnu delete 0 end

    # Add all available themes (in alphabetical order) to the menu
    foreach theme [lsort [array names data files,*]] {
      set theme_name [lindex [split $theme ,] 1]
      $mnu add command -label $theme_name -command [list themer::preview_theme $theme_name]
    }

  }

  ######################################################################
  # Previews the given theme.
  proc preview_theme {theme} {

    variable data

    # Save the current theme
    set data(curr_theme) $theme

    # Reads the contents of the given theme
    read_tketheme $data(files,$theme)

    # Display the theme contents in the UI
    initialize

    # Apply the theme
    apply_theme

    # Set the menubutton text to the selected theme
    $data(widgets,open_mb) configure -text [file rootname [file tail $theme]]

  }

  ######################################################################
  # Add the available themes to the combobox.
  proc add_combobox_themes {cb} {

    variable data

    # Get the list of theme names
    set values [list]
    foreach theme [lsort [array names data files,*]] {
      lappend values [lindex [split $theme ,] 1]
    }

    # Set the combobox list to the list of theme values
    $data(widgets,save_cb) configure -values $values

    # Clear the combobox editing area
    $data(widgets,save_cb) set ""

  }

  ######################################################################
  # Creates the relief detail panel.
  proc create_detail_relief {} {

    variable data

    # Create the frame
    set data(widgets,relief) [ttk::frame $data(widgets,df).rf]

    # Create the relief widgets
    ttk::label $data(widgets,relief).l -text "Relief: "
    set data(widgets,relief_mb) [ttk::menubutton $data(widgets,relief).mb -menu [set data(widgets,relief_menu) [menu $data(widgets,relief).menu -tearoff 0]]]

    # Pack the widgets
    pack $data(widgets,relief).l  -side left -padx 2 -pady 2
    pack $data(widgets,relief).mb -side left -padx 2 -pady 2

  }

  ######################################################################
  # Creates the number detail panel.
  proc create_detail_number {} {

    variable data

    # Create the frame
    set data(widgets,number) [ttk::frame $data(widgets,df).nf]

    # Create the widgets
    set data(widgets,number_lbl) [ttk::label $data(widgets,number).l -text "Value"]
    set data(widgets,number_sb)  [ttk::spinbox $data(widgets,number).sb -command [list themer::handle_number_change]]

    # Pack the widgets
    pack $data(widgets,number).l  -side left -padx 2 -pady 2
    pack $data(widgets,number).sb -side left -padx 2 -pady 2

  }

  ######################################################################
  # Creates the color detail panel.
  proc create_detail_color {} {

    variable data

    # Create the frame
    set data(widgets,color) [ttk::frame $data(widgets,df).cf]

    # Create the canvas
    set data(widgets,color_canvas) [canvas $data(widgets,color).c -relief flat -width 60 -height 40]
    set data(widgets,color_base)   [$data(widgets,color_canvas) create rectangle 15 5 48 36 -width 0]
    set data(widgets,color_mod)    [$data(widgets,color_canvas) create rectangle 31 5 48 36 -width 0]

    # Create color modification menubutton
    menu $data(widgets,color).base_mnu -tearoff 0 -postcommand [list themer::post_base_color_menu $data(widgets,color).base_mnu]
    ttk::menubutton $data(widgets,color).mb -text "Change Base Color" -menu $data(widgets,color).base_mnu

    # Create the modification frames
    ttk::labelframe $data(widgets,color).mod -text "Modifications"
    grid [ttk::radiobutton $data(widgets,color).mod.lnone -text "None" -value none -variable themer::data(mod) -command [list themer::color_mod_changed none]] -row 0 -column 0 -sticky w -padx 2 -pady 2
    set i 1
    foreach mod [list light r g b] {
      grid [ttk::radiobutton $data(widgets,color).mod.l$mod -text "[string totitle $mod]:" -value $mod -variable themer::data(mod) -command [list themer::color_mod_changed $mod]] -row $i -column 0 -sticky w -padx 2 -pady 2
      grid [set data(widgets,color_${mod}_scale) [ttk::scale $data(widgets,color).mod.s$mod -orient horizontal -from 0 -to 255 -command [list themer::detail_scale_change $mod]]] -row $i -column 1 -padx 2 -pady 2
      grid [set data(widgets,color_${mod}_entry) [$data(sb)  $data(widgets,color).mod.e$mod {*}$data(sb_opts) -width 3 -from 0 -to 255 -command [list themer::detail_spinbox_change $mod]]] -row $i -column 2 -padx 2 -pady 2
      $data(widgets,color_${mod}_scale) state disabled
      $data(widgets,color_${mod}_entry) {*}$data(sb_disabled)
      incr i
    }

    pack $data(widgets,color_canvas) -pady 5
    pack $data(widgets,color).mb     -pady 2
    pack $data(widgets,color).mod    -pady 2

  }

  ######################################################################
  # Create the bitmap detail panel.
  proc create_detail_bitmap {} {

    variable data

    set data(widgets,bitmap) [bitmap::create $data(widgets,df).bf]

  }

  ######################################################################
  # Called before the base color menu is posted.  Updates itself with
  # the current list of swatch colors.
  proc post_base_color_menu {mnu} {

    variable data

    # Clear the menu
    $mnu delete 0 end

    # Add the "Custom..." menu item
    $mnu add command -label "Custom..." -command [list themer::choose_custom_base_color]

    # Add each swatch colors to the menu, if available
    if {[llength $data(cat,swatch)] > 0} {
      $mnu add separator
      $mnu add command -label "Swatch Colors" -state disabled
      foreach color $data(cat,swatch) {
        $mnu add command -label $color -command [list themer::set_base_color $color]
      }
    }

  }

  ######################################################################
  # Calls up the color picker and, if a color is chosen, update the UI.
  proc choose_custom_base_color {} {

    variable data

    # Get the current base color
    set orig_color [$data(widgets,color_canvas) itemcget $data(widgets,color_base) -fill]

    # Get the color from the user
    if {[set color [tk_chooseColor -initialcolor $orig_color -parent .thmwin]] eq ""} {
      return
    }

    # Set the color in the UI
    set_base_color $color

  }

  ######################################################################
  # Called when a new base color is selected, updates the UI.
  proc set_base_color {color} {

    variable data

    # Set the base color to the given color
    $data(widgets,color_canvas) itemconfigure $data(widgets,color_base) -fill $color

    # Apply any modifications
    detail_update_color $data(mod)

  }

  ######################################################################
  # Handles any changes to the color modification radiobutton status.
  proc color_mod_changed {new_mod} {

    variable data

    # Disable all entries
    foreach mod [list light r g b] {
      $data(widgets,color_${mod}_scale) state disabled
      $data(widgets,color_${mod}_entry) {*}$data(sb_disabled)
    }

    # If the type is not none, allow it to be configured
    if {$new_mod ne "none"} {
      $data(widgets,color_${new_mod}_scale) state !disabled
      $data(widgets,color_${new_mod}_entry) {*}$data(sb_normal)
    }

    # Update the color details
    detail_update_color $new_mod

  }

  ######################################################################
  # Handles any changes to the scaling.
  proc detail_scale_change {mod value} {

    variable data

    # Insert the value in the spinbox
    $data(widgets,color_${mod}_entry) delete 0 end
    $data(widgets,color_${mod}_entry) insert end [expr int( $value )]

    # Update the UI
    detail_update_color $mod

  }

  ######################################################################
  # Validate the detail entry fields.
  proc detail_spinbox_change {mod} {

    variable data

    # Get the current spinbox value
    set value [$data(widgets,color_${mod}_entry) get]

    # Set the scale value
    $data(widgets,color_${mod}_scale) configure -value [expr {($value eq "") ? 0 : $value}]

    # Update the UI
    detail_update_color $mod

  }

  ######################################################################
  # Updates the various color attributes given the modification setting.
  proc detail_update_color {mod} {

    variable data

    # Get the base color
    set base_color [$data(widgets,color_canvas) itemcget $data(widgets,color_base) -fill]

    # Get the entry value
    set diff [expr {($mod ne "none") ? [$data(widgets,color_${mod}_entry) get] : 0}]

    # Calculate the value
    switch $mod {
      none {
        set new_color $base_color
        set value     $base_color
      }
      light {
        set new_color [utils::auto_adjust_color $base_color $diff manual]
        set value     $base_color,$diff
      }
      default {
        set new_color [utils::auto_mix_colors $base_color $mod $diff]
        set value     $base_color,$mod,$diff
      }
    }

    # Update the color UI
    $data(widgets,color_canvas) itemconfigure $data(widgets,color_mod) -fill $new_color
    $data(widgets,color_canvas) raise         $data(widgets,color_mod)

    # Update the data value
    array set meta $data(cat,meta)
    if {$mod eq "none"} {
      unset -nocomplain meta($data(category),$data(opt))
    } else {
      set meta($data(category),$data(opt)) $value
    }
    set data(cat,meta) [array get meta]

    # Update the data array
    array set temp $data(cat,$data(category))
    set temp($data(opt)) $new_color
    set data(cat,$data(category)) [array get temp]

    # Set the category table
    $data(widgets,cat) cellconfigure $data(row),value -text $value

    # Specify that the apply button should be enabled
    $data(widgets,apply) state !disabled

  }

  ######################################################################
  # Show the relief panel.
  proc detail_show_relief {value values} {

    variable data

    # Add the relief panel
    pack $data(widgets,relief) -fill both -expand yes

    # Delete the menu contents
    $data(widgets,relief_menu) delete 0 end

    # Add the values
    foreach val $values {
      $data(widgets,relief_menu) add command -label $val -command [list themer::handle_relief_change $val]
    }

    # Set the detail
    $data(widgets,relief_mb) configure -text $value

  }

  ######################################################################
  # Handles any changes to the relief widget.
  proc handle_relief_change {value} {

    variable data

    # Update the data array
    array set temp $data(cat,$data(category))
    set temp($data(opt)) $value
    set data(cat,$data(category)) [array get temp]

    # Update the configuration table
    $data(widgets,cat) cellconfigure $data(row),value -text $value

    # Enable the apply button
    $data(widgets,apply) state !disabled

  }

  ######################################################################
  # Displays the number selection panel.
  proc detail_show_number {lbl value min max} {

    variable data

    # Add the number panel
    pack $data(widgets,number) -fill both -expand yes

    # Create the range of values
    for {set i $min} {$i <= $max} {incr i} {
      lappend values $i
    }

    # Configure the label
    $data(widgets,number_lbl) configure -text "$lbl:"

    # Configure the spinbox
    $data(widgets,number_sb) configure -values $values -width [string length $max]

    # Set the current value in the spinbox
    $data(widgets,number_sb) set $value

  }

  ######################################################################
  # Handles any changes to the number value.
  proc handle_number_change {} {

    variable data

    # Get the spinbox value
    set value [$data(widgets,number_sb) get]

    # Update the data array
    array set temp $data(cat,$data(category))
    set temp($data(opt)) $value
    set data(cat,$data(category)) [array get temp]

    # Update the configuration table
    $data(widgets,cat) cellconfigure $data(row),value -text $value

    # Enable the apply button
    $data(widgets,apply) state !disabled

  }

  ######################################################################
  # Show the color panel.
  proc detail_show_color {value} {

    variable data

    # Add the color panel
    pack $data(widgets,color) -fill both -expand yes

    # Get the syntax
    array set syntax $data(cat,syntax)

    # Parse the value
    switch [llength [set values [split $value ,]]] {
      1 {
        set base_color [lindex $values 0]
        set data(mod)  "none"
      }
      2 {
        lassign $values base_color set_value
        set data(mod)  "light"
      }
      3 {
        lassign $values base_color data(mod) set_value
      }
    }

    # Colorize the widgets
    $data(widgets,color_canvas) configure -background $syntax(background)
    $data(widgets,color_canvas) itemconfigure $data(widgets,color_base) -fill $base_color

    # Get all of the color values
    lassign [get_color_values $base_color] base(light) base(r) base(g) base(b)

    # Set the from/to values in the scales and entries
    foreach mod [list light r g b] {
      $data(widgets,color_${mod}_scale) configure -from [expr 0 - $base($mod)] -to [expr 255 - $base($mod)]
      $data(widgets,color_${mod}_entry) configure -from [expr 0 - $base($mod)] -to [expr 255 - $base($mod)]
      $data(widgets,color_${mod}_scale) set [expr {($mod eq $data(mod)) ? $set_value : $base($mod)}]
      $data(widgets,color_${mod}_entry) set [expr {($mod eq $data(mod)) ? $set_value : $base($mod)}]
    }

    # Fool the UI into thinking that the modified value changed
    # color_mod_changed $data(mod)

  }

  ######################################################################
  # Displays the bitmap detail window and populates it with the given
  # information.
  proc detail_show_bitmap {value} {

    variable data

    # Add the bitmap panel
    pack $data(widgets,bitmap)

    # Set the bitmap information
    bitmap::set_from_info $data(widgets,bitmap) $value

  }

  ######################################################################
  # Creates and initializes the UI.
  proc initialize {} {

    variable data

    # Create the UI
    create

    # Delete any existing swatches
    if {[info exists data(swatch_index)]} {
      for {set i 1} {$i <= $data(swatch_index)} {incr i} {
        delete_swatch $i 1
      }
      set data(swatch_index) 0
    }

    # Insert the swatches
    foreach color $data(cat,swatch) {
      add_swatch $color
    }

    # Clear the table
    $data(widgets,cat) delete 0 end

    # Insert categories
    foreach {category title} [list syntax "Syntax Colors" ttk_style "ttk Widget Colors" menus "Menu Options" \
                                   tabs "Tab Options" text_scrollbar "Text Scrollbar Options" \
                                   sidebar "Sidebar Options" sidebar_scrollbar "Sidebar Scrollbar Options"] {
      set parent [$data(widgets,cat) insertchild root end [list $title {} {}]]
      array set opts $data(cat,$category)
      foreach opt [lsort [array names opts]] {
        $data(widgets,cat) insertchild $parent end [list $opt $opts($opt) $category]
      }
      array unset opts
    }

  }

  ######################################################################
  # Adds a new swatch color.
  proc add_swatch {{color ""}} {

    variable data

    # Get the color from the user
    if {$color eq ""} {
      if {[set color [tk_chooseColor -parent .thmwin]] eq ""} {
        return
      }
    }

    # Create button
    set index [incr data(swatch_index)]
    set col   [llength $data(cat,swatch)]
    set ifile [file join $::tke_dir lib images square32.bmp]
    set img   [image create bitmap -file $ifile -maskfile $ifile -foreground $color]
    set frm   $data(widgets,sf).f$index

    # Move the plus button up if the swatch is no longer going to be empty
    if {$col == 0} {
      pack $data(widgets,plus_text)
    }

    # Create widgets
    pack [ttk::frame $frm] -before $data(widgets,plus) -side left -padx 2 -pady 2
    pack [ttk::button $frm.b -style BButton -image $img -command [list themer::edit_swatch $index]]
    pack [ttk::label  $frm.l -text $color]

    # Add binding to delete swatch
    bind $frm.b <Button-$::right_click> [list themer::delete_swatch $index]

    # Insert the value into the swatch list
    if {$color eq ""} {
      lappend data(cat,swatch) $color
    }

    # If the number of swatch elements exceeds 6, remove the plus button
    if {[llength $data(cat,swatch)] == 6} {
      pack forget $data(widgets,plus)
    }

  }

  ######################################################################
  # Edit the color of the swatch.
  proc edit_swatch {index} {

    variable data

    # Get the index
    set pos [lsearch [pack slaves $data(widgets,sf)] $data(widgets,sf).f$index]

    # Get the original color
    set orig_color [lindex $data(cat,swatch) $pos]

    # Get the new color from the user
    if {[set color [tk_chooseColor -initialcolor $orig_color -parent .thmwin]] eq ""} {
      return
    }

    # Change the widgets
    [$data(widgets,sf).f$index.b cget -image] configure -foreground $color
    $data(widgets,sf).f$index.l configure -text $color

    # Change the swatch value
    lset data(cat,swatch) $pos $color

  }

  ######################################################################
  # Deletes the given swatch after confirming from the user.
  proc delete_swatch {index {force 0}} {

    variable data

    # Confirm from the user
    if {!$force && [tk_messageBox -parent .thmwin -message "Delete swatch?" -default no -type yesno] eq "no"} {
      return
    }

    # Get position
    set pos [lsearch [pack slaves $data(widgets,sf)] $data(widgets,sf).f$index]

    # Delete image
    image delete [$data(widgets,sf).f$index.b cget -image]

    # Destroy the widgets
    destroy $data(widgets,sf).f$index

    # Add the plus button if the number of packed elements is 6
    switch [llength $data(cat,swatch)] {
      6 { pack $data(widgets,plus) -side left -padx 2 -pady 2 }
      1 { pack forget $data(widgets,plus_text) }
    }

    # Delete the swatch value from the list
    if {!$force} {
      set data(cat,swatch) [lreplace $data(cat,swatch) $pos $pos]
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
  # Imports a TextMate or TKE theme file after prompting user to import
  # a file.
  proc import {} {

    variable data

    # Get the theme file to import:w
    if {[set theme [tk_getOpenFile -parent .thmwin -title "Import Theme File" -filetypes {{{TKE Theme} {.tketheme}} {{TextMate Theme} {.tmtheme}}}]] ne ""} {
      switch [file extension $theme] {
        tketheme { import_tke $theme }
        tmtheme  { import_tm  $theme }
        default  {}
      }
    }

  }

  ######################################################################
  # Imports the given TextMate theme and displays the result in the UI.
  proc import_tm {theme} {

    variable labels
    variable widgets
    variable tmtheme
    variable all_scopes

    # Set the theme
    set tmtheme $theme

    # Create the UI
    create

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
  proc import_tke {theme} {

    variable labels
    variable widgets
    variable tmtheme
    variable all_scopes

    # Set the theme
    set tmtheme $theme

    # Create the UI
    create

    # Initialize UI
    wm title [get_win] [msgcat::mc "Edit theme"]
    $widgets(action) configure -text [msgcat::mc "Save"]
    catch { pack $widgets(reset) -side left -padx 2 -pady 2 }
    catch { pack $widgets(saveas) -side right -padx 2 -pady 2 }

    # Read the theme
    read_tketheme $theme

  }

}

