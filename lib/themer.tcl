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

  array set widgets     {}
  array set all_scopes  {}
  array set show_vars   {}

  array set data [list theme_dir [file join $::tke_home themes]]

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
  # Returns the given color based on the embeddable color string.
  proc get_color {value} {

    switch [llength [set values [split $value ,]]] {
      0 { return #ffffff }
      1 { return [lindex $values 0] }
      2 { return [utils::auto_adjust_color [lindex $values 0] [lindex $values 1] manual] }
      3 { return [utils::auto_mix_colors   [lindex $values 0] [lindex $values 1] [lindex $values 2]] }
    }

  }

  ######################################################################
  # Sets the given table cell color.
  proc set_cell_color {row color_str {color ""}} {

    variable data

    # Get the color
    if {$color eq ""} {
      set color [get_color $color_str]
    }

    # Set the cell
    $data(widgets,cat) cellconfigure $row,value -text $color_str \
      -background $color -foreground [utils::get_complementary_mono_color $color]

  }

  ######################################################################
  # Displays the theme editor with the specified theme information.
  proc edit_theme {theme} {

    variable data

    # Get the list of themes
    load_themes

    # Read the specified theme
    theme::read_tketheme $data(files,$theme)

    # Initialize the themer
    initialize

    # Save the current theme
    set_current_theme_to $theme

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
  # Applies the current settings to the current TKE session.
  proc apply_theme {} {

    variable data

    # Apply the updates to the theme
    theme::update_theme

    # Clear the preview button
    $data(widgets,preview) state disabled

  }

  ######################################################################
  # Sets the current theme to the given value and updates the editor
  # title bar.
  proc set_current_theme_to {theme {check 1}} {

    variable data

    # First, check to see if the current theme needs to be saved
    if {$check && [theme_needs_saving]} {
      switch [tk_messageBox -parent .thmwin -icon question -message [msgcat::mc "Save theme changes?"] -detail [msgcat::mc "The current theme has unsaved changes"] -type yesnocancel -default yes] {
        yes    { save_current_theme }
        cancel { return 0 }
      }
    }

    # Set the variable value
    set data(curr_theme) $theme

    # Update the title bar
    wm title .thmwin [msgcat::mc "Theme Editor - %s" $theme]

    return 1

  }

  ######################################################################
  # This should be called whenever the current theme has been modified.
  proc set_theme_modified {} {

    variable data

    # Make the preview button pressable
    $data(widgets,preview) state !disabled

    # Update the title bar
    wm title .thmwin [msgcat::mc "Theme Editor * %s" $data(curr_theme)]

  }

  ######################################################################
  # Returns true if the current theme needs to be saved; otherwise, returns 0.
  proc theme_needs_saving {} {

    return [expr {[string first "*" [wm title .thmwin]] != -1}]

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
        -yscrollcommand { .thmwin.pw.lf.vb set } \
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

      # Get the width of all buttons
      set bwidth [msgcat::mcmax "Open" "Save" "Create" "Save" "Cancel" "Preview" "Done" "Import" "Export"]

      # Create the button frame
      set data(widgets,bf)      [ttk::frame .thmwin.bf]
      set data(widgets,open)    [ttk::button .thmwin.bf.open    -style BButton -text [msgcat::mc "Open"]    -width $bwidth -command [list themer::start_open_frame]]
      set data(widgets,preview) [ttk::button .thmwin.bf.preview -style BButton -text [msgcat::mc "Preview"] -width $bwidth -command [list themer::apply_theme]]
      set data(widgets,save)    [ttk::button .thmwin.bf.save    -style BButton -text [msgcat::mc "Save"]    -width $bwidth -command [list themer::start_save_frame]]

      bind $data(widgets,save) <Button-$::right_click> [list themer::save_current_theme]

      grid columnconfigure .thmwin.bf 0 -weight 1
      grid columnconfigure .thmwin.bf 1 -weight 1
      grid columnconfigure .thmwin.bf 2 -weight 1
      grid $data(widgets,open)    -row 0 -column 0 -sticky w  -padx 2 -pady 2
      grid $data(widgets,preview) -row 0 -column 1 -sticky ns -padx 2 -pady 2
      grid $data(widgets,save)    -row 0 -column 2 -sticky e  -padx 2 -pady 2

      # Create the open frame
      set data(widgets,of)      [ttk::frame .thmwin.of]
      ttk::button .thmwin.of.import -style BButton -text [msgcat::mc "Import"] -width $bwidth -command [list themer::import]
      menu .thmwin.of.mnu -tearoff 0 -postcommand [list themer::add_menu_themes .thmwin.of.mnu]
      set data(widgets,open_mb) [ttk::menubutton .thmwin.of.mb -direction above -text [msgcat::mc "Choose Theme"] -menu .thmwin.of.mnu]
      ttk::button .thmwin.of.close -style BButton -text [msgcat::mc "Done"] -width $bwidth -command [list themer::end_open_frame]

      grid columnconfigure .thmwin.of 0 -weight 1
      grid columnconfigure .thmwin.of 1 -weight 1
      grid columnconfigure .thmwin.of 2 -weight 1
      grid .thmwin.of.import -row 0 -column 0 -sticky w  -padx 2 -pady 2
      grid .thmwin.of.mb     -row 0 -column 1 -sticky ns -padx 2 -pady 2
      grid .thmwin.of.close  -row 0 -column 2 -sticky e  -padx 2 -pady 2

      # Create the save frame
      set data(widgets,wf)      [ttk::frame .thmwin.wf]
      ttk::button .thmwin.wf.export -style BButton -text [msgcat::mc "Export"] -width $bwidth -command [list themer::export]
      if {[::tke_development]} {
        ttk::label .thmwin.wf.l1 -text [msgcat::mc "Save in:"]
        set mb_width              [expr [msgcat::mcmax "User Directory" "Installation Directory"] - 5]
        set data(widgets,save_mb) [ttk::menubutton .thmwin.wf.mb -width $mb_width -menu [menu .thmwin.wf.mb_menu -tearoff 0]]
        .thmwin.wf.mb_menu add command -label [msgcat::mc "User Directory"]         -command [list themer::save_to_directory "user"]
        .thmwin.wf.mb_menu add command -label [msgcat::mc "Installation Directory"] -command [list themer::save_to_directory "install"]
      }
      ttk::label .thmwin.wf.l2 -text [msgcat::mc "   Save Name:"]
      set data(widgets,save_cb) [ttk::combobox .thmwin.wf.cb -width 30 -postcommand [list themer::add_combobox_themes .thmwin.wf.cb]]
      ttk::button .thmwin.wf.save   -style BButton -text [msgcat::mc "Save"]   -width $bwidth -command [list themer::save_theme]
      ttk::button .thmwin.wf.cancel -style BButton -text [msgcat::mc "Cancel"] -width $bwidth -command [list themer::end_save_frame]

      pack .thmwin.wf.cancel -side right -padx 2 -pady 2
      pack .thmwin.wf.save   -side right -padx 2 -pady 2
      pack .thmwin.wf.cb     -side right -padx 2 -pady 2
      pack .thmwin.wf.l2     -side right -padx 2 -pady 2
      pack .thmwin.wf.export -side left  -padx 2 -pady 2

      if {[::tke_development]} {
        pack .thmwin.wf.mb -side right -padx 2 -pady 2
        pack .thmwin.wf.l1 -side right -padx 2 -pady 2
      }

      pack .thmwin.sf -fill x
      pack .thmwin.pw -fill both -expand yes
      pack .thmwin.bf -fill x

      # Disable buttons
      $data(widgets,preview) state disabled

      # Create the detail panels
      create_detail_relief
      create_detail_number
      create_detail_color
      create_detail_image
      create_detail_treestyle

    }

  }

  ######################################################################
  # Sets the save directory type.
  proc save_to_directory {type} {

    variable data

    set data(save_directory) $type

    if {[info exists data(widgets,save_mb)]} {
      switch $type {
        user    { set lbl [msgcat::mc "User Directory"] }
        install { set lbl [msgcat::mc "Installation Directory"] }
      }
      $data(widgets,save_mb) configure -text $lbl
    }

  }

  ######################################################################
  # Called whenever the theme editor window is closed.
  proc close_window {} {

    variable data

    # Save the theme if it needs saving and the user agrees to it
    if {[theme_needs_saving]} {
      if {[tk_messageBox -parent .thmwin -icon question -message [msgcat::mc "Save theme changes?"] -detail [msgcat::mc "The current theme has unsaved changes"] -type yesno -default yes] eq "yes"} {
        save_current_theme
      }
    }

    # Cause the original theme to be reloaded in the UI
    # TBD - themes::reload

    # Delete the swatch images
    foreach swatch [winfo children $data(widgets,sf)] {
      lappend images [$swatch.b cget -image]
    }
    image delete {*}$images

    # Delete the data array
    array unset data *,*
    unset data(swatch_index)

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

    # Set the save to directory status
    if {([file dirname $data(files,$data(curr_theme))] eq $data(theme_dir)) || ![::tke_development]} {
      save_to_directory "user"
    } else {
      save_to_directory "install"
    }

  }

  ######################################################################
  # Saves the current theme using selected name.
  proc save_theme {} {

    variable data

    # Get the theme name from the combobox
    set theme_name [$data(widgets,save_cb) get]

    if {$data(save_directory) eq "user"} {
      set theme_file [set data(files,$theme_name) [file join $data(theme_dir) $theme_name.tketheme]]
    } else {
      set theme_file [file join $::tke_dir data themes $theme_name.tketheme]
      if {![info exists data(files,$theme_name)]} {
        set data(files,$theme_name) $theme_file
      }
    }

    # Write the theme to disk
    catch { theme::write_tketheme $theme_file }

    # Save the current theme
    set_current_theme_to $theme_name 0

    # End the save frame
    end_save_frame

  }

  ######################################################################
  # Performs a save of the current theme to disk.
  proc save_current_theme {} {

    variable data

    # Get the current theme file
    set theme_file $data(files,$data(curr_theme))

    # Write the theme to disk
    catch { theme::write_tketheme $theme_file }

    # Indicate that the theme was saved
    set_current_theme_to $data(curr_theme) 0

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

    set parent [$data(widgets,cat) parentkey $row]
    set opt    [$data(widgets,cat) cellcget $row,opt -text]
    set cat    [$data(widgets,cat) cellcget $row,category -text]

    if {($parent eq "root") || ($cat eq "images")} {
      return ""
    } elseif {[theme::get_type $cat $opt] eq "color"} {
      return [get_color $value]
    } else {
      return $value
    }

  }

  ######################################################################
  # Handles a change to the category selection.
  proc handle_category_selection {} {

    variable data

    # Clear the details frame
    catch { pack forget {*}[pack slaves $data(widgets,df)] }

    # Get the currently selected row
    if {([set row [$data(widgets,cat) curselection]] ne "") && ([set parent [$data(widgets,cat) parentkey $row]] ne "root")} {

      # Get the row values
      set data(row)      $row
      set data(opt)      [$data(widgets,cat) cellcget $row,opt      -text]
      set data(category) [$data(widgets,cat) cellcget $row,category -text]
      set value          [$data(widgets,cat) cellcget $row,value    -text]

      lassign [theme::get_type $data(category) $data(opt)] type values

      # Remove the selection from the color cell
      $data(widgets,cat) cellselection clear $row,value

      switch $type {
        image {
          switch [llength $value] {
            4 { detail_show_image photo $value }
            6 { detail_show_image mono  $value }
            8 { detail_show_image dual  $value }
          }
        }
        relief {
          detail_show_relief $value $values
        }
        number {
          detail_show_number [string totitle [string range $data(opt) 1 end]] $value {*}$values
        }
        treestyle {
          detail_show_treestyle $value
        }
        color {
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
    if {[set_current_theme_to $theme]} {

      # Reads the contents of the given theme
      theme::read_tketheme $data(files,$theme)

      # Display the theme contents in the UI
      initialize

      # Apply the theme
      apply_theme

      # Set the menubutton text to the selected theme
      $data(widgets,open_mb) configure -text [file rootname [file tail $theme]]

    }

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

  }

  ######################################################################
  # Creates the relief detail panel.
  proc create_detail_relief {} {

    variable data

    # Create the frame
    set data(widgets,relief) [ttk::frame $data(widgets,df).rf]

    # Create the relief widgets
    ttk::label $data(widgets,relief).l -text [msgcat::mc "Relief: "]
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
    set data(widgets,number_lbl) [ttk::label $data(widgets,number).l -text [msgcat::mc "Value: "]]
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
    ttk::menubutton $data(widgets,color).mb -text [msgcat::mc "Change Base Color"] -menu $data(widgets,color).base_mnu

    # Create the modification frames
    ttk::labelframe $data(widgets,color).mod -text [msgcat::mc "Modifications"]
    grid [ttk::radiobutton $data(widgets,color).mod.lnone -text [msgcat::mc "None"] -value none -variable themer::data(mod) -command [list themer::color_mod_changed none]] -row 0 -column 0 -sticky w -padx 2 -pady 2
    set i 1
    foreach mod [list [msgcat::mc "light"] r g b] {
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
  # Create the image detail panel.
  proc create_detail_image {} {

    variable data

    set data(widgets,image) [ttk::frame $data(widgets,df).if]

    # Create and pack the image selection menubutton
    pack [set data(widgets,image_mb) [ttk::menubutton $data(widgets,df).if.mb -menu [menu $data(widgets,image).mnu -tearoff 0]]] -padx 2 -pady 2

    # Populate the menu
    $data(widgets,image).mnu add radiobutton -label [msgcat::mc "One-Color Bitmap"] -value mono  -variable themer::data(image_type) -command [list themer::show_image_frame mono]
    $data(widgets,image).mnu add radiobutton -label [msgcat::mc "Two-Color Bitmap"] -value dual  -variable themer::data(image_type) -command [list themer::show_image_frame dual]
    $data(widgets,image).mnu add radiobutton -label [msgcat::mc "GIF Photo"]        -value photo -variable themer::data(image_type) -command [list themer::show_image_frame photo]

    # Create mono frame
    set data(widgets,image_mf) [ttk::frame $data(widgets,image).mf]
    pack [set data(widgets,image_mf_bm) [bitmap::create $data(widgets,image_mf).bm mono]] -padx 2 -pady 2
    pack [ttk::button $data(widgets,image_mf).di -text [msgcat::mc "Import BMP Data"] -command [list bitmap::import $data(widgets,image_mf_bm) 3]] -padx 2 -pady 2 -fill x -expand yes

    bind $data(widgets,image_mf_bm) <<BitmapChanged>> [list themer::handle_bitmap_changed %d]

    # Create dual frame
    set data(widgets,image_df) [ttk::frame $data(widgets,image).df]
    pack [set data(widgets,image_df_bm) [bitmap::create $data(widgets,image_df).bm dual]] -padx 2 -pady 2
    pack [ttk::button $data(widgets,image_df).di -text [msgcat::mc "Import BMP Data"] -command [list bitmap::import $data(widgets,image_df_bm) 1]] -padx 2 -pady 2 -fill x -expand yes
    pack [ttk::button $data(widgets,image_df).mi -text [msgcat::mc "Import BMP Mask"] -command [list bitmap::import $data(widgets,image_df_bm) 2]] -padx 2 -pady 2 -fill x -expand yes

    bind $data(widgets,image_df_bm) <<BitmapChanged>> [list themer::handle_bitmap_changed %d]

    # Create photo frame
    set data(widgets,image_pf) [ttk::frame $data(widgets,image).pf]
    pack [set data(widgets,image_pf_preview) [ttk::label      $data(widgets,image).pf.img -image [image create photo]]]                          -padx 2 -pady 2 -fill x -expand yes
    pack [set data(widgets,image_pf_mb_dir)  [ttk::menubutton $data(widgets,image).pf.mb1 -menu [menu $data(widgets,image).pf.mnu1 -tearoff 0]]] -padx 2 -pady 2 -fill x -expand yes
    pack [set data(widgets,image_pf_mb_file) [ttk::menubutton $data(widgets,image).pf.mb2 -menu [menu $data(widgets,image).pf.mnu2 -tearoff 0]]] -padx 2 -pady 2 -fill x -expand yes

    # Populate the photo menus
    $data(widgets,image).pf.mnu1 add command -label [msgcat::mc "Installation Directory"] -command [list themer::image_photo_dir install *.gif]
    $data(widgets,image).pf.mnu1 add command -label [msgcat::mc "User Directory"]         -command [list themer::image_photo_dir user    *.gif]
    $data(widgets,image).pf.mnu1 add separator
    $data(widgets,image).pf.mnu1 add command -label [msgcat::mc "Custom Directory"]       -command [list themer::image_photo_dir custom  *.gif]

  }

  ######################################################################
  # Gets all of the GIF photos from
  proc image_photo_dir {type pattern} {

    variable data

    switch $type {
      install {
        set dir     [file join $::tke_dir lib images]
        set dirname [msgcat::mc "Installation Directory"]
      }
      user    {
        set dir     [file join $::tke_home themes images]
        set dirname [msgcat::mc "User Directory"]
      }
      custom  {
        if {[set dir [tk_chooseDirectory -parent .thmwin]] eq ""} {
          return
        }
        set dirname $dir
      }
    }

    # Set the menubutton text
    $data(widgets,image_pf_mb_dir) configure -text $dirname

    set mnu $data(widgets,image).pf.mnu2

    # Delete any previous images
    if {[set last [$mnu index last]] ne "none"} {
      for {set i 0} {$i <= $last} {incr i} {
        image delete [$mnu entrycget $i -image]
      }
    }

    # Get all of the files in the directory that match the given file pattern
    $mnu delete 0 end
    foreach fname [glob -nocomplain -directory $dir $pattern] {
      set img [image create photo -file $fname]
      $mnu add command -label $fname -image $img -command [list themer::set_photo_image $img]
    }

  }

  ######################################################################
  # Displays the given image in the photo preview window.
  proc set_photo_image {img} {

    variable data

    $data(widgets,image_pf_mb_file) configure -image $img

  }

  ######################################################################
  # Called whenever the user updates the bitmap widget.
  proc handle_bitmap_changed {bm_data} {

    variable data

    # Set the tablelist data
    theme::set_themer_category_table_row $data(widgets,cat) $data(row) $bm_data

    # Specify that the apply button should be enabled
    set_theme_modified

  }

  ######################################################################
  # Creates the treestyle detail frame.
  proc create_detail_treestyle {} {

    variable data

    # Create the tree style detail frame
    set data(widgets,treestyle) [ttk::frame $data(widgets,df).tf]

    # Create the treestyle widgets
    ttk::label $data(widgets,treestyle).l -text [msgcat::mc "Tree Style: "]
    set data(widgets,treestyle_mb) [ttk::menubutton $data(widgets,treestyle).mb -menu [set data(widgets,treestyle_menu) [menu $data(widgets,treestyle).menu -tearoff 0]]]

    # Create treestyles list
    # Add the treestyle options
    foreach treestyle [list adwaita ambiance aqua baghira bicolor1 bicolor2 bicolor3 bicolor4 classic1 \
                            classic2 classic3 classic4 dust dustSand gtk klearlooks mate mint newWave \
                            oxygen1 oxygen2 phase plain1 plain2 plain3 plain4 plastik plastique radiance \
                            ubuntu ubuntu2 vistaAero vistaClassic win7Aero win7Classic winnative winxpBlue \
                            winxpOlive winxpSilver yuyo] {
      $data(widgets,treestyle_menu) add command -label $treestyle -command [list themer::set_treestyle $treestyle]
    }

    # Pack the widgets
    pack $data(widgets,treestyle).l  -side left -padx 2 -pady 2
    pack $data(widgets,treestyle).mb -side left -padx 2 -pady 2

  }

  ######################################################################
  # Updates the category tablelist.
  proc set_treestyle {treestyle} {

    variable data

    # Update the menubutton text
    $data(widgets,treestyle_mb) configure -text $treestyle

    # Update the category table
    $data(widgets,cat) cellconfigure $data(row),value -text $treestyle

    # Specify that the apply button should be enabled
    set_theme_modified

  }

  ######################################################################
  # Called before the base color menu is posted.  Updates itself with
  # the current list of swatch colors.
  proc post_base_color_menu {mnu} {

    variable data

    # Clear the menu
    $mnu delete 0 end

    # Add the "Custom..." menu item
    $mnu add command -label [msgcat::mc "Custom..."] -command [list themer::choose_custom_base_color]

    # Add each swatch colors to the menu, if available
    if {[theme::swatch_do length] > 0} {
      $mnu add separator
      $mnu add command -label [msgcat::mc "Swatch Colors"] -state disabled
      foreach color [theme::swatch_do get] {
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
    if {$mod eq "none"} {
      theme::meta_do delete $data(category),$data(opt)
    } else {
      theme::meta_do set $data(category),$data(opt) $value
    }

    # Update the table row
    theme::set_themer_category_table_row $data(widgets,cat) $data(row) $value $new_color

    # Specify that the apply button should be enabled
    set_theme_modified

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

    # Update the configuration table
    theme::set_themer_category_table_row $data(widgets,cat) $data(row) $value

    # Enable the apply button
    set_theme_modified

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

    # Update the configuration table
    theme::set_themer_category_table_row $data(widgets,cat) $data(row) $value

    # Enable the apply button
    set_theme_modified

  }

  ######################################################################
  # Show the color panel.
  proc detail_show_color {value} {

    variable data

    # Add the color panel
    pack $data(widgets,color) -fill both -expand yes

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
    $data(widgets,color_canvas) configure -background [theme::get_value syntax background]
    $data(widgets,color_canvas) itemconfigure $data(widgets,color_base) -fill $base_color

    # Get all of the color values
    lassign [utils::get_color_values $base_color] base(light) base(r) base(g) base(b)

    # Set the from/to values in the scales and entries
    foreach mod [list light r g b] {
      $data(widgets,color_${mod}_scale) configure -from [expr 0 - $base($mod)] -to [expr 255 - $base($mod)]
      $data(widgets,color_${mod}_entry) configure -from [expr 0 - $base($mod)] -to [expr 255 - $base($mod)]
      $data(widgets,color_${mod}_scale) set [expr {($mod eq $data(mod)) ? $set_value : $base($mod)}]
      $data(widgets,color_${mod}_entry) set [expr {($mod eq $data(mod)) ? $set_value : $base($mod)}]
    }

  }

  ######################################################################
  # Displays the given image type in the detail image frame.
  proc show_image_frame {type {value ""}} {

    variable data

    puts "In show_image_frame, type: $type, value: $value"

    set orig_value $value

    # Unpack any children in the image frame
    catch { pack forget {*}[pack slaves $data(widgets,image)] }

    # Get the value from the table if we dont have it
    if {$value eq ""} {
      set value [$data(widgets,cat) cellcget $data(row),value -text]
    }

    pack $data(widgets,image_mb) -padx 2 -pady 2

    switch $type {
      mono {
        $data(widgets,image_mb)    configure -text [msgcat::mc "One-Color Bitmap"]
        $data(widgets,image_mf_bm) configure -swatches [theme::swatch_do get]
        bitmap::set_from_info $data(widgets,image_mf_bm) $value
        pack $data(widgets,image_mf) -padx 2 -pady 2
        if {$orig_value eq ""} {
          handle_bitmap_changed [bitmap::get_info $data(widgets,image_mf_bm)]
        }
      }
      dual {
        $data(widgets,image_mb)    configure -text [msgcat::mc "Two-Color Bitmap"]
        $data(widgets,image_df_bm) configure -swatches [theme::swatch_do get]
        bitmap::set_from_info $data(widgets,image_df_bm) $value
        pack $data(widgets,image_df) -padx 2 -pady 2
        if {$orig_value eq ""} {
          handle_bitmap_changed [bitmap::get_info $data(widgets,image_df_bm)]
        }
      }
      photo {
        array set value_array $value
        $data(widgets,image_mb) configure -text [msgcat::mc "GIF Photo"]
        switch $value_array(dir) {
          install { set fname [file join $::tke_dir lib images $value_array(file)] }
          user    { set fname [file join $::tke_home themes images $value_array(file)] }
          default { set fname [file join $value_array(dir) $value_array(file)] }
        }
        image delete [$data(widgets,image_pf_preview) cget -image]
        $data(widgets,image_pf_preview) configure -image [image create photo -file $fname]
        pack $data(widgets,image_pf) -padx 2 -pady 2
      }
    }

    # Set the image type
    set data(image_type) $type

  }

  ######################################################################
  # Displays the bitmap detail window and populates it with the given
  # information.
  proc detail_show_image {type value} {

    variable data

    # Show the image panel
    pack $data(widgets,image)

    # Display the appropriate image detail frame
    show_image_frame $type $value

  }

  ######################################################################
  # Displays the treestyle detail frame.
  proc detail_show_treestyle {value} {

    variable data

    # Display the treestyle frame
    pack $data(widgets,treestyle)

    # Set the menubutton
    $data(widgets,treestyle_mb) configure -text $value

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
    foreach color [theme::swatch_do get] {
      add_swatch $color
    }

    # Clear the table
    $data(widgets,cat) delete 0 end

    # Insert categories
    theme::populate_themer_category_table $data(widgets,cat)

  }

  ######################################################################
  # Adds a new swatch color.
  proc add_swatch {{color ""}} {

    variable data

    set orig_color $color

    # Get the color from the user
    if {$color eq ""} {
      set choose_color_opts [list]
      if {[set select [$data(widgets,cat) curselection]] ne ""} {
        if {[theme::get_type [$data(widgets,cat) cellcget $select,category -text] [$data(widgets,cat) cellcget $select,opt -text]] eq "color"} {
          lappend choose_color_opts -initialcolor [$data(widgets,cat) cellcget $select,value -background]
        }
      }
      if {[set color [tk_chooseColor -parent .thmwin {*}$choose_color_opts]] eq ""} {
        return
      }
    }

    # Create button
    set index  [incr data(swatch_index)]
    set col    [theme::swatch_do length]
    set ifile  [file join $::tke_dir lib images square32.bmp]
    set img    [image create bitmap -file $ifile -maskfile $ifile -foreground $color]
    set frm    $data(widgets,sf).f$index

    # Move the plus button up if the swatch is no longer going to be empty
    if {$col == 0} {
      pack $data(widgets,plus_text)
    }

    # Create widgets
    pack [ttk::frame $frm] -before $data(widgets,plus) -side left -padx 2 -pady 2
    pack [ttk::button $frm.b -style BButton -image $img -command [list themer::edit_swatch $index]]
    pack [ttk::label  $frm.l -text $color]

    # Add binding to delete swatch
    bind $frm.b <ButtonRelease-$::right_click> [list themer::delete_swatch $index]

    # Insert the value into the swatch list
    if {$orig_color eq ""} {
      theme::swatch_do append $color
    }

    # If the number of swatch elements exceeds 6, remove the plus button
    if {[theme::swatch_do length] == 6} {
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
    set orig_color [theme::swatch_do index $pos]

    # Get the new color from the user
    if {[set color [tk_chooseColor -initialcolor $orig_color -parent .thmwin]] eq ""} {
      return
    }

    # Change the widgets
    [$data(widgets,sf).f$index.b cget -image] configure -foreground $color
    $data(widgets,sf).f$index.l configure -text $color

    # Change the swatch value
    theme::swatch_do set $pos $color

    # Change table values
    for {set i 0} {$i < [$data(widgets,cat) size]} {incr i} {
      if {[set category [$data(widgets,cat) cellcget $i,category -text]] ne ""} {
        if {[theme::get_type $category [$data(widgets,cat) cellcget $i,opt -text]] eq "color"} {
          set value [split [$data(widgets,cat) cellcget $i,value -text] ,]
          if {([llength $value] > 1) && ([lindex $value 0] eq $orig_color)} {
            lset value 0 $color
            set_cell_color $i [join $value ,] $color
          }
        }
      }
    }

  }

  ######################################################################
  # Deletes the given swatch after confirming from the user.
  proc delete_swatch {index {force 0}} {

    variable data

    # Confirm from the user
    if {!$force && [tk_messageBox -parent .thmwin -message [msgcat::mc "Delete swatch?"] -default no -type yesno] eq "no"} {
      return
    }

    # Get position
    set pos [lsearch [pack slaves $data(widgets,sf)] $data(widgets,sf).f$index]

    # Delete image
    image delete [$data(widgets,sf).f$index.b cget -image]

    # Destroy the widgets
    destroy $data(widgets,sf).f$index

    # Add the plus button if the number of packed elements is 6
    switch [theme::swatch_do length] {
      6 { pack $data(widgets,plus) -side left -padx 2 -pady 2 }
      1 { pack forget $data(widgets,plus_text) }
    }

    # Delete the swatch value from the list
    if {!$force} {
      theme::swatch_do delete $pos
    }

    # Make table colors dependent on this color independent
    for {set i 0} {$i < [$data(widgets,cat) size]} {incr i} {
      if {[set category [$data(widgets,cat) cellcget $i,category -text]] ne ""} {
        if {[theme::get_type $category [$data(widgets,cat) cellcget $i,opt -text]] eq "color"} {
          switch [llength [set values [split [$data(widgets,cat) cellcget $i,value -text] ,]]] {
            2 {
              set color [utils::auto_adjust_color [lindex $values 0] [lindex $values 1] manual]
              $data(widgets,cat) cellconfigure $i,value -text $color
            }
            3 {
              set color [utils::auto_mix_colors [lindex $values 0] [lindex $values 1] [lindex $values 2]]
              $data(widgets,cat) cellconfigure $i,value -text $color
            }
          }
        }
      }
    }

  }

  ######################################################################
  # Imports a TextMate or TKE theme file after prompting user to import
  # a file.
  proc import {} {

    variable data

    # Get the theme file to import
    if {[set theme [tk_getOpenFile -parent .thmwin -title [msgcat::mc "Import Theme File"] -filetypes {{{TKE Theme} {.tketheme}} {{TextMate Theme} {.tmtheme}}}]] ne ""} {
      switch -exact [string tolower [file extension $theme]] {
        .tketheme { import_tke $theme }
        .tmtheme  { import_tm  $theme }
        default   {}
      }
    }

  }

  ######################################################################
  # Imports the given TextMate theme and displays the result in the UI.
  proc import_tm {theme} {

    variable data

    # Set the theme
    if {[set_current_theme_to [file rootname [file tail $theme]]]} {

      # Read the theme
      if {[catch { theme::read_tmtheme $theme } rc]} {
        tk_messageBox -parent .thmwin -icon error -message [msgcat::mc "Import Error"] -detail $rc -default ok -type ok
        return
      }

      # Initialize the themer
      initialize

      # Apply the theme to the UI
      apply_theme

    }

  }

  ######################################################################
  # Imports the given tke theme and displays the result in the UI.
  proc import_tke {theme} {

    variable data

    # Set the theme
    if {[set_current_theme_to [file rootname [file tail $theme]]]} {

      # Read the theme
      if {[catch { theme::read_tketheme $theme } rc]} {
        tk_messageBox -parent .thmwin -icon error -message [msgcat::mc "Import Error"] -detail $rc -default ok -type ok
        return
      }

      # Initialize the themer
      initialize

      # Apply the theme to the UI
      apply_theme

    }

  }

  ######################################################################
  # Exports the current theme information to a tketheme file on the
  # filesystem.
  proc export {} {

    if {[set fname [tk_getSaveFile -confirmoverwrite 1 -defaultextension .tketheme -parent .thmwin -title [msgcat::mc "Export theme"]]] ne ""} {
      if {[catch { theme::write_tketheme $fname } rc]} {
        tk_messageBox -parent .thmwin -icon error -message [msgcat::mc "Export Error"] -detail $rc -default ok -type ok
      }
    }

  }

}

