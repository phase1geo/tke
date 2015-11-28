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
# Brief:   Allows the user to customize, create, export and import themes.
######################################################################

source [file join $::tke_dir lib bitmap.tcl]

namespace eval themer {

  array set data {
    max_swatches 8
  }

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

    return $color

  }

  ######################################################################
  # Displays the theme editor with the specified theme information.
  proc edit_current_theme {} {

    variable data

    # Get the current theme name and save it
    set data(original_theme) [theme::get_current_theme]

    # Initialize the themer
    initialize

    # Save the current theme
    set_current_theme_to $data(original_theme)

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
  # Checks to see if the current theme needs to be saved.  If it has
  # changed since the last save, prompts the user for direction and saves
  # the theme if specified.  Returns 1 if the save was handled (or no
  # save was necessary).  Returns 0 if the user canceled the save operation.
  proc check_for_save {} {

    # First, check to see if the current theme needs to be saved
    if {[theme_needs_saving]} {
      switch [tk_messageBox -parent .thmwin -icon question -message [msgcat::mc "Save theme changes?"] -detail [msgcat::mc "The current theme has unsaved changes"] -type yesnocancel -default yes] {
        yes    { save_current_theme }
        cancel { return 0 }
      }
    }

    return 1

  }

  ######################################################################
  # Sets the title with the given information (including attribution
  # information from the current theme.
  proc set_title {modified} {

    variable data

    # Set the theme name/attribution string to the theme
    set theme_attr $data(curr_theme)

    # Create the attribution portion of the title bar
    array set attr [theme::get_attributions]

    if {[info exists attr(creator)]} {
      if {[info exists attr(website)]} {
        append theme_attr "  (By: $attr(creator), $attr(website))"
      } else {
        append theme_attr "  (By: $attr(creator))"
      }
    } elseif {[info exists attr(website)]} {
      append theme_attr "  ($attr(website))"
    }

    # Finally, set the title bar
    wm title .thmwin [msgcat::mc "Theme Editor %s %s" [expr {$modified ? "*" : "-"}] $theme_attr]

  }

  ######################################################################
  # Sets the current theme to the given name and updates the title bar.
  proc set_current_theme_to {theme} {

    variable data

    # Set the variable value
    set data(curr_theme) $theme

    # Update the title bar
    set_title 0

  }

  ######################################################################
  # This should be called whenever the current theme has been modified.
  proc set_theme_modified {} {

    variable data

    # Make the preview button pressable
    $data(widgets,preview) state !disabled

    # If the open frame is shown, show the normal button bar
    end_open_frame

    # Update the title bar
    set_title 1

  }

  ######################################################################
  # Returns true if the current theme needs to be saved; otherwise, returns 0.
  proc theme_needs_saving {} {

    return [expr {[winfo exists .thmwin] && ([string first "*" [wm title .thmwin]] != -1)}]

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

      toplevel     .thmwin
      wm title     .thmwin [msgcat::mc "Theme Editor"]
      wm geometry  .thmwin 800x600
      wm transient .thmwin .
      wm protocol  .thmwin WM_DELETE_WINDOW [list themer::close_window 0]

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
        -labelcommand [list themer::show_filter_menu] \
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
      ttk::label  .thmwin.wf.l      -text [msgcat::mc "Save As:"]
      if {[::tke_development]} {
        set mb_width              [expr [msgcat::mcmax "User Directory" "Installation Directory"] - 5]
        set data(widgets,save_mb) [ttk::menubutton .thmwin.wf.mb -width $mb_width -menu [menu .thmwin.wf.mb_menu -tearoff 0]]
        .thmwin.wf.mb_menu add command -label [msgcat::mc "User Directory"]         -command [list themer::save_to_directory "user"]
        .thmwin.wf.mb_menu add command -label [msgcat::mc "Installation Directory"] -command [list themer::save_to_directory "install"]
      }
      set data(widgets,save_cb) [ttk::combobox .thmwin.wf.cb -width 30 -postcommand [list themer::add_combobox_themes .thmwin.wf.cb]]
      set data(widgets,save_b)  [ttk::button .thmwin.wf.save   -style BButton -text [msgcat::mc "Save"]   -width $bwidth -command [list themer::save_theme]]
      ttk::button .thmwin.wf.cancel -style BButton -text [msgcat::mc "Cancel"] -width $bwidth -command [list themer::end_save_frame]

      pack .thmwin.wf.cancel -side right -padx 2 -pady 2
      pack .thmwin.wf.save   -side right -padx 2 -pady 2
      pack .thmwin.wf.cb     -side right -padx 2 -pady 2
      if {[::tke_development]} {
        pack .thmwin.wf.mb -side right -padx 2 -pady 2
      }
      pack .thmwin.wf.l      -side right -padx 2 -pady 2
      pack .thmwin.wf.export -side left  -padx 2 -pady 2

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

      # Create the filter menu
      create_filter_menu

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
      $data(widgets,save_mb) configure -text  $lbl
      $data(widgets,save_b)  configure -state normal
    }

  }

  ######################################################################
  # Returns true if the themer window exists; otherwise, returns false.
  proc window_exists {} {

    return [winfo exists .thmwin]

  }


  ######################################################################
  # Called whenever the theme editor window is closed.
  proc close_window {on_exit} {

    variable data

    # If the theme window is not currently open, there's nothing left to do
    if {![winfo exists .thmwin]} {
      return
    }

    # Save the theme if it needs saving and the user agrees to it
    if {[theme_needs_saving]} {
      if {[tk_messageBox -parent .thmwin -icon question -message [msgcat::mc "Save theme changes?"] -detail [msgcat::mc "The current theme has unsaved changes"] -type yesno -default yes] eq "yes"} {
        save_current_theme
      }
    }

    # If we are close because the application is being quit, don't bother with the rest
    if {$on_exit} {
      return
    }

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

    # Cause the original theme to be reloaded in the UI
    theme::load_theme [themes::get_file $data(original_theme)]

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
    if {[catch { themes::get_file $data(curr_theme) } fname]} {
      $data(widgets,save_mb) configure -text [msgcat::mc "Select Directory"]
      $data(widgets,save_b)  configure -state disabled
    } elseif {([file dirname $fname] eq [file join $::tke_dir data themes]) && [::tke_development]} {
      save_to_directory "install"
    } else {
      save_to_directory "user"
    }

  }

  ######################################################################
  # Saves the current theme using selected name.
  proc save_theme {} {

    variable data

    # Get the theme name from the combobox
    set theme_name [$data(widgets,save_cb) get]

    if {$data(save_directory) eq "user"} {
      set theme_file [file join $::tke_home themes $theme_name $theme_name.tketheme]
    } else {
      set theme_file [file join $::tke_dir data themes $theme_name.tketheme]
    }

    # Write the theme to disk
    if {[catch { theme::write_tketheme $data(widgets,cat) $theme_file } rc]} {
      tk_messageBox -parent .thmwin -icon error -default ok -type ok -message "Save error" -detail $rc
      return
    }

    # Reload the themes
    themes::load

    # Set the current theme
    set_current_theme_to $theme_name

    # End the save frame
    end_save_frame

    # Refresh the detail information (in case it has changed)
    handle_category_selection

  }

  ######################################################################
  # Performs a save of the current theme to disk.
  proc save_current_theme {} {

    variable data

    # Get the current theme file
    set theme_file [themes::get_file $data(curr_theme)]

    # Write the theme to disk
    if {[catch { theme::write_tketheme $data(widgets,cat) $theme_file } rc]} {
      tk_messageBox -parent .thmwin -icon error -default ok -type ok -message "Save error" -detail $rc
      return
    }

    # Indicate that the theme was saved
    set_title 0

    # Refresh the detail information (in case it has changed)
    handle_category_selection

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

    # Category identifier and images should return the empty string; otherwise, return the value
    if {([$data(widgets,cat) parentkey $row] eq "root") ||
        ([$data(widgets,cat) cellcget $row,category -text] eq "images")} {
      return ""
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
          set title [string totitle [string map {{_} { }} [expr {([string index $data(opt) 0] eq "-") ? [string range $data(opt) 1 end] : $data(opt)}]]]
          detail_show_number $title $value {*}$values
        }
        treestyle {
          detail_show_treestyle $value
        }
        color {
          if {[theme::meta_do exists $data(category) $data(opt)]} {
            detail_show_color [theme::meta_do get $data(category) $data(opt)]
          } else {
            detail_show_color $value
          }
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
    foreach theme_name [themes::get_all_themes] {
      $mnu add command -label $theme_name -command [list themer::preview_theme $theme_name]
    }

  }

  ######################################################################
  # Previews the given theme.
  proc preview_theme {theme} {

    variable data

    # Save the current theme
    if {[check_for_save]} {

      # Reads the contents of the given theme
      theme::read_tketheme [themes::get_file $theme]

      # Display the theme contents in the UI
      initialize

      # Set the current theme to the given theme
      set_current_theme_to $theme

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

    # Set the combobox list to the list of theme values
    $data(widgets,save_cb) configure -values [themes::get_all_themes]

  }

  ######################################################################
  # Creates the relief detail panel.
  proc create_detail_relief {} {

    variable data

    # Create the frame
    set data(widgets,relief) [ttk::frame $data(widgets,df).rf]

    # Create the relief widgets
    ttk::frame $data(widgets,relief).f
    ttk::label $data(widgets,relief).f.l -text [msgcat::mc "Relief: "]
    set data(widgets,relief_mb) [ttk::menubutton $data(widgets,relief).f.mb -width -20 \
      -menu [set data(widgets,relief_menu) [menu $data(widgets,relief).menu -tearoff 0]]]

    # Pack the widgets
    pack $data(widgets,relief).f.l  -side left -padx 2 -pady 2
    pack $data(widgets,relief).f.mb -side left -padx 2 -pady 2

    pack $data(widgets,relief).f -padx 2 -pady 2

  }

  ######################################################################
  # Creates the number detail panel.
  proc create_detail_number {} {

    variable data

    # Create the frame
    set data(widgets,number) [ttk::frame $data(widgets,df).nf]

    # Create the widgets
    ttk::label $data(widgets,number).f
    set data(widgets,number_lbl) [ttk::label $data(widgets,number).f.l -text [msgcat::mc "Value: "]]
    set data(widgets,number_sb)  [ttk::spinbox $data(widgets,number).f.sb -command [list themer::handle_number_change]]

    # Pack the widgets
    pack $data(widgets,number).f.l  -side left -padx 2 -pady 2
    pack $data(widgets,number).f.sb -side left -padx 2 -pady 2

    pack $data(widgets,number).f -padx 2 -pady 2

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
    foreach {lbl mod max} [list [msgcat::mc "Value"] v 127 "R" r 255 "G" g 255 "B" b 255] {
      grid [ttk::radiobutton $data(widgets,color).mod.l$mod -text "$lbl:" -value $mod -variable themer::data(mod) -command [list themer::color_mod_changed $mod]] -row $i -column 0 -sticky w -padx 2 -pady 2
      grid [set data(widgets,color_${mod}_scale) [ttk::scale $data(widgets,color).mod.s$mod -orient horizontal -from 0 -to $max -command [list themer::detail_scale_change $mod]]] -row $i -column 1 -padx 2 -pady 2
      grid [set data(widgets,color_${mod}_entry) [$data(sb)  $data(widgets,color).mod.e$mod {*}$data(sb_opts) -width 3 -from 0 -to $max -command [list themer::detail_spinbox_change $mod]]] -row $i -column 2 -padx 2 -pady 2
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
    set data(widgets,image_pf)         [ttk::frame $data(widgets,image).pf]
    set data(widgets,image_pf_mb_dir)  [ttk::menubutton $data(widgets,image).pf.mb -menu [menu $data(widgets,image).pf.mnu -tearoff 0]]
    set data(widgets,image_pf_tl_file) [tablelist::tablelist $data(widgets,image).pf.tl \
      -columns {0 {} center 0 {} center 0 {} center} -showlabels 0 -selecttype cell -stretch all \
      -yscrollcommand [list $data(widgets,image).pf.vb set] -exportselection 0 \
    ]
    ttk::scrollbar $data(widgets,image).pf.vb -orient vertical -command [list $data(widgets,image_pf_tl_file) yview]

    # Configure the table columns
    for {set i 0} {$i < 3} {incr i} {
      $data(widgets,image_pf_tl_file) columnconfigure $i -formatcommand [list themer::format_image_cell] -editable 0 -width -100 -maxwidth -100
    }

    # Handle any tablelist selections
    bind $data(widgets,image_pf_tl_file) <<TablelistSelect>> [list themer::handle_image_select %W %x %y]

    grid rowconfigure    $data(widgets,image_pf) 1 -weight 1
    grid columnconfigure $data(widgets,image_pf) 0 -weight 1
    grid $data(widgets,image_pf).mb -row 0 -column 0 -sticky ew   -padx 2 -pady 2
    grid $data(widgets,image_pf).tl -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $data(widgets,image_pf).vb -row 1 -column 1 -sticky ns   -padx 2 -pady 2

    # Populate the photo menus
    $data(widgets,image).pf.mnu add command -label [msgcat::mc "Installation Directory"] -command [list themer::image_photo_dir install *.gif]
    $data(widgets,image).pf.mnu add command -label [msgcat::mc "User Directory"]         -command [list themer::image_photo_dir user    *.gif]
    $data(widgets,image).pf.mnu add separator
    $data(widgets,image).pf.mnu add command -label [msgcat::mc "Custom Directory"]       -command [list themer::image_photo_dir custom  *.gif]

  }

  ######################################################################
  # Handles formatting an cell in the image table.
  proc format_image_cell {value} {

    return ""

  }

  ######################################################################
  # Handles a selection in the image table.
  proc handle_image_select {W x y} {

    variable data

    # Get the selected cell
    set cell [$data(widgets,image_pf_tl_file) curcellselection]

    # Set the tablelist data and indicate that the theme has changed
    if {![catch { $data(widgets,image_pf_tl_file) cellcget $cell -text } value] && ($value ne "")} {
      theme::set_themer_category_table_row $data(widgets,cat) $data(row) $value
      set_theme_modified
    }

  }

  ######################################################################
  # Gets all of the GIF photos from
  proc image_photo_dir {type pattern {fname ""}} {

    variable data

    switch $type {
      install {
        set dir     [file join $::tke_dir lib images]
        set dirname [msgcat::mc "Installation Directory"]
      }
      user    {
        set dir     [file join $::tke_home themes [theme::get_current_theme]]
        set dirname [msgcat::mc "User Directory"]
      }
      custom  {
        if {$fname eq ""} {
          if {[set dir [tk_chooseDirectory -parent .thmwin]] eq ""} {
            return
          }
        } else {
          set dir   [file dirname $fname]
          set fname [file tail $fname]
        }
        set dirname $dir
        set type    $dir
      }
    }

    # Set the directory menubutton text
    $data(widgets,image_pf_mb_dir) configure -text $dirname

    # Delete any previous images
    if {[$data(widgets,image_pf_tl_file) size] > 0} {
      foreach value [$data(widgets,image_pf_tl_file) getcells 0,0 last] {
        array set value_array $value
        catch { image delete img_[file rootname $value_array(file)] }
        array unset value_array $value
      }
      $data(widgets,image_pf_tl_file) delete 0 end
    }

    # Make the tablelist visible
    grid $data(widgets,image_pf_tl_file)

    # Get all of the files in the directory that match the given file pattern
    set i          0
    set match_cell ""
    foreach iname [glob -nocomplain -directory $dir $pattern] {
      if {[expr $i % 3] == 0} {
        $data(widgets,image_pf_tl_file) insert end [list [list] [list] [list]]
      }
      set cell [expr $i / 3],[expr $i % 3]
      set img  [image create photo img_[file rootname [file tail $iname]] -file $iname]
      $data(widgets,image_pf_tl_file) cellconfigure $cell -text [list dir $type file [file tail $iname]] -image $img
      if {[file tail $iname] eq $fname} {
        set match_cell $cell
      }
      incr i
    }

    # Set the filename menubutton text
    if {$match_cell ne ""} {
      $data(widgets,image_pf_tl_file) cellselection set $match_cell
      $data(widgets,image_pf_tl_file) seecell $match_cell
    }

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
    ttk::frame $data(widgets,treestyle).f
    ttk::label $data(widgets,treestyle).f.l -text [msgcat::mc "Tree Style: "]
    set data(widgets,treestyle_mb) [ttk::menubutton $data(widgets,treestyle).f.mb -width -20 \
      -menu [set data(widgets,treestyle_menu) [menu $data(widgets,treestyle).menu -tearoff 0]]]

    # Add the available treestyles to the menubutton (note: tablelist::treeStyles is a private,
    # undocumented variable; however, the developer recommended that this be used for this purpose)
    foreach treestyle $tablelist::treeStyles {
      $data(widgets,treestyle_menu) add command -label $treestyle -command [list themer::set_treestyle $treestyle]
    }

    # Pack the widgets
    pack $data(widgets,treestyle).f.l  -side left -padx 2 -pady 2
    pack $data(widgets,treestyle).f.mb -side left -padx 2 -pady 2

    pack $data(widgets,treestyle).f -padx 2 -pady 2

  }

  ######################################################################
  # Updates the category tablelist.
  proc set_treestyle {treestyle} {

    variable data

    # Update the menubutton text
    $data(widgets,treestyle_mb) configure -text $treestyle

    # Update the category table
    theme::set_themer_category_table_row $data(widgets,cat) $data(row) $treestyle

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
    foreach mod [list v r g b] {
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
      v {
        set new_color [utils::auto_adjust_color $base_color $diff auto]
        set value     $base_color,v,$diff
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
      theme::meta_do delete $data(category) $data(opt)
    } else {
      theme::meta_do set $data(category) $data(opt) $value
    }

    # Update the table row
    theme::set_themer_category_table_row $data(widgets,cat) $data(row) $new_color

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

    # Set the menubutton
    $data(widgets,relief_mb) configure -text $value

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
      3 {
        lassign $values base_color data(mod) set_value
      }
      default {
        return -code error "Unknown color value format ($value)"
      }
    }

    # Colorize the widgets
    $data(widgets,color_canvas) configure -background [theme::get_value syntax background]
    $data(widgets,color_canvas) itemconfigure $data(widgets,color_base) -fill $base_color

    switch $data(mod) {
      none    { $data(widgets,color_canvas) itemconfigure $data(widgets,color_mod) -fill $base_color }
      v       { $data(widgets,color_canvas) itemconfigure $data(widgets,color_mod) -fill [utils::auto_adjust_color $base_color $set_value auto] }
      default { $data(widgets,color_canvas) itemconfigure $data(widgets,color_mod) -fill [utils::auto_mix_colors $base_color $data(mod) $set_value] }
    }

    # Get all of the color values
    lassign [utils::get_color_values $base_color] base(value) base(r) base(g) base(b)

    # Set the from/to values in the scales and entries
    foreach mod [list v r g b] {
      if {$mod eq $data(mod)} {
        $data(widgets,color_${mod}_scale) configure -value $set_value
        $data(widgets,color_${mod}_entry) set $set_value
        $data(widgets,color_${mod}_scale) state !disabled
        $data(widgets,color_${mod}_entry) {*}$data(sb_normal)
      } else {
        $data(widgets,color_${mod}_scale) configure -value 0
        $data(widgets,color_${mod}_entry) set 0
        $data(widgets,color_${mod}_scale) state disabled
        $data(widgets,color_${mod}_entry) {*}$data(sb_disabled)
      }
    }

  }

  ######################################################################
  # Displays the given image type in the detail image frame.
  proc show_image_frame {type {value ""}} {

    variable data

    set orig_value $value

    # Unpack any children in the image frame
    catch { pack forget {*}[pack slaves $data(widgets,image)] }

    # Make the image type selection menubutton visible again
    pack $data(widgets,image_mb) -padx 2 -pady 2

    # Get the value from the table if we dont have it
    if {$value eq ""} {
      set value [$data(widgets,cat) cellcget $data(row),value -text]
    }

    # Get the image base color from the table
    set base_color [$data(widgets,cat) cellcget $data(row),value -background]

    # Organize the value into an array
    array set value_array $value

    switch $type {
      mono {
        $data(widgets,image_mb)    configure -text [msgcat::mc "One-Color Bitmap"]
        $data(widgets,image_mf_bm) configure -swatches [theme::swatch_do get] -background $base_color
        if {[info exists value_array(dat)]} {
          bitmap::set_from_info $data(widgets,image_mf_bm) $value
          if {$orig_value eq ""} {
            handle_bitmap_changed [bitmap::get_info $data(widgets,image_mf_bm)]
          }
        }
        pack $data(widgets,image_mf) -padx 2 -pady 2
      }
      dual {
        $data(widgets,image_mb)    configure -text [msgcat::mc "Two-Color Bitmap"]
        $data(widgets,image_df_bm) configure -swatches [theme::swatch_do get] -background $base_color
        if {[info exists value_array(dat)]} {
          bitmap::set_from_info $data(widgets,image_df_bm) $value
          if {$orig_value eq ""} {
            handle_bitmap_changed [bitmap::get_info $data(widgets,image_df_bm)]
          }
        }
        pack $data(widgets,image_df) -padx 2 -pady 2
      }
      photo {
        $data(widgets,image_mb) configure -text [msgcat::mc "GIF Photo"]
        $data(widgets,image_pf_tl_file) configure -background $base_color
        if {[info exists value_array(dir)]} {
          switch $value_array(dir) {
            install { image_photo_dir install *.gif $value_array(file) }
            user    { image_photo_dir user    *.gif $value_array(file) }
            default { image_photo_dir custom  *.gif [file join $value_array(dir) $value_array(file)] }
          }
        } else {
          $data(widgets,image_pf_mb_dir) configure -text [msgcat::mc "Select Directory"]
          grid remove $data(widgets,image_pf_tl_file)
        }
        pack $data(widgets,image_pf) -fill both -expand yes -padx 2 -pady 2
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
    pack $data(widgets,image) -fill both -expand yes

    # Display the appropriate image detail frame
    show_image_frame $type $value

  }

  ######################################################################
  # Displays the treestyle detail frame.
  proc detail_show_treestyle {value} {

    variable data

    # Display the treestyle frame
    pack $data(widgets,treestyle) -fill both -expand yes

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

    # Clear the detail frame
    catch { pack forget {*}[pack slaves $data(widgets,df)] }

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
      set_theme_modified
    }

    # If the number of swatch elements exceeds the maximum, remove the plus button
    if {[theme::swatch_do length] == $data(max_swatches)} {
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
        set opt [$data(widgets,cat) cellcget $i,opt -text]
        if {([theme::get_type $category $opt] eq "color") && [theme::meta_do exists $category $opt]} {
          set value [split [theme::meta_do get $category $opt] ,]
          if {[lindex $value 0] eq $orig_color)} {
            lset value 0 $color
            theme::meta_do set $category $opt [join $value ,]
            theme::set_themer_category_table_row $data(widgets,cat) $i [get_color [join $value ,]]
          }
        }
      }
    }

    # Specify that the theme has been modified
    set_theme_modified

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

    # Add the plus button if the number of packed elements is the allowed maximum
    set len [theme::swatch_do length]
    if {$len == $data(max_swatches)} {
      pack $data(widgets,plus) -side left -padx 2 -pady 2
    } elseif {$len == 1} {
      pack forget $data(widgets,plus_text)
    }

    # Get the color being deleted
    set orig_color [theme::swatch_do index $pos]

    # Delete the swatch value from the list
    if {!$force} {

      theme::swatch_do delete $pos
      set_theme_modified

      # Make table colors dependent on this color independent
      for {set i 0} {$i < [$data(widgets,cat) size]} {incr i} {
        if {[set category [$data(widgets,cat) cellcget $i,category -text]] ne ""} {
          set opt [$data(widgets,cat) cellcget $i,opt -text]
          if {([theme::get_type $category $opt] eq "color") && [theme::meta_do exists $category $opt]} {
            if {[lindex [split [theme::meta_do get $category $opt] ,] 0] eq $orig_color} {
              theme::meta_do delete $category $opt
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
    if {[set theme [tk_getOpenFile -parent .thmwin -title [msgcat::mc "Import Theme File"] -filetypes {{{TKE Theme} {.tkethemz}} {{TextMate Theme} {.tmtheme}}}]] ne ""} {
      switch -exact [string tolower [file extension $theme]] {
        .tkethemz { import_tke $theme .thmwin }
        .tmtheme  { import_tm  $theme .thmwin }
        default   {}
      }
    }

  }

  ######################################################################
  # Imports the given TextMate theme and displays the result in the UI.
  proc import_tm {theme {parent .}} {

    variable data

    # Set the theme
    if {[check_for_save]} {

      # Read the theme
      if {[catch { theme::read_tmtheme $theme } rc]} {
        tk_messageBox -parent $parent -icon error -message [msgcat::mc "Import Error"] -detail $rc -default ok -type ok
        return
      }

      # Initialize the themer
      initialize

      # Set the current theme
      set_current_theme_to [file rootname [file tail $theme]]

      # Apply the theme to the UI
      apply_theme

    }

  }

  ######################################################################
  # Imports the given tke theme and displays the result in the UI.
  proc import_tke {theme {parent .}} {

    variable data

    # Perform the tkethemz import
    set theme_file [themes::import .thmwin $theme]

    # Set the theme
    if {[check_for_save]} {

      # Read the theme
      if {[catch { theme::read_tketheme $theme_file } rc]} {
        tk_messageBox -parent $parent -icon error -message [msgcat::mc "Import Error"] -detail $rc -default ok -type ok
        return
      }

      # Initialize the themer
      initialize

      # Set the current theme
      set_current_theme_to [file rootname [file tail $theme]]

      # Apply the theme to the UI
      apply_theme

    }

  }

  ######################################################################
  # Exports the current theme information to a tketheme file on the
  # filesystem.
  proc export {} {

    # Get the export information
    array set expdata [export_win]

    # If the export information exists, export the theme
    if {[info exists expdata(name)]} {

      # Export the theme
      themes::export .thmwin $expdata(name) $expdata(dir) $expdata(creator) $expdata(website)

      # Make the save frame disappear
      end_save_frame

    }

  }

  ######################################################################
  # Displays export window and returns when the user has supplied the
  # needed information.  Returns the empty list of the user cancels
  # the export function.
  proc export_win {} {

    variable export_retval

    toplevel     .expwin
    wm title     .expwin "Export Theme As"
    wm resizable .expwin 0 0
    wm transient .expwin .thmwin
    wm protocol  .expwin WM_DELETE_WINDOW {
      set themer::export_retval [list]
      destroy .expwin
    }

    ttk::frame     .expwin.f
    ttk::label     .expwin.f.cl  -text "Created By:"
    ttk::entry     .expwin.f.ce  -width 50
    ttk::label     .expwin.f.wl  -text "Website:"
    ttk::entry     .expwin.f.we  -width 50
    ttk::separator .expwin.f.sep -orient horizontal
    ttk::label     .expwin.f.nl  -text "Theme Name:"
    ttk::entry     .expwin.f.ne  -width 50 -validate key -validatecommand themer::validate_export
    ttk::label     .expwin.f.dl  -text "Output Directory:"
    ttk::entry     .expwin.f.de  -width 50 -state disabled
    ttk::button    .expwin.f.db  -style BButton -text "Choose" -command {
      if {[set fname [tk_chooseDirectory -parent .expwin -mustexist 1]] ne ""} {
        .expwin.f.de configure -state normal
        .expwin.f.de delete 0 end
        .expwin.f.de insert end $fname
        .expwin.f.de configure -state disabled
        themer::validate_export
      }
    }

    grid rowconfigure    .expwin.f 2 -weight 1
    grid columnconfigure .expwin.f 1 -weight 1
    grid .expwin.f.cl  -row 0 -column 0 -sticky e    -padx 2 -pady 2
    grid .expwin.f.ce  -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .expwin.f.wl  -row 1 -column 0 -sticky e    -padx 2 -pady 2
    grid .expwin.f.we  -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid .expwin.f.sep -row 2 -column 0 -sticky news -padx 2 -pady 2 -columnspan 3
    grid .expwin.f.nl  -row 3 -column 0 -sticky e    -padx 2 -pady 2
    grid .expwin.f.ne  -row 3 -column 1 -sticky news -padx 2 -pady 2
    grid .expwin.f.dl  -row 4 -column 0 -sticky e    -padx 2 -pady 2
    grid .expwin.f.de  -row 4 -column 1 -sticky news -padx 2 -pady 2
    grid .expwin.f.db  -row 4 -column 2 -sticky news -padx 2 -pady 2

    ttk::frame .expwin.bf
    ttk::button .expwin.bf.export -style BButton -text "Export" -command {
      set themer::export_retval [list \
        name    [.expwin.f.ne get] \
        dir     [.expwin.f.de get] \
        creator [.expwin.f.ce get] \
        website [.expwin.f.we get] \
      ]
      destroy .expwin
    } -state disabled
    ttk::button .expwin.bf.cancel -style BButton -text "Cancel" -command {
      set themer::export_retval [list]
      destroy .expwin
    }

    pack .expwin.bf.cancel -side right -padx 2 -pady 2
    pack .expwin.bf.export -side right -padx 2 -pady 2

    # Pack the frames
    pack .expwin.f  -fill x -padx 2 -pady 2
    pack .expwin.bf -fill x -padx 2 -pady 2

    # Set the focus on the first entry field
    focus .expwin.f.ce

    # Set the theme name to the current theme name
    .expwin.f.ne insert end [theme::get_current_theme]

    # Center the window in the .thmwin
    ::tk::PlaceWindow .expwin widget .thmwin

    # Wait for the window to close
    tkwait window .expwin

    return $export_retval

  }

  ######################################################################
  # Checks the window input to determine the state of the Export
  # button.
  proc validate_export {} {

    if {([.expwin.f.ne get] ne "") && ([.expwin.f.de get] ne "")} {
      .expwin.bf.export configure -state normal
    } else {
      .expwin.bf.export configure -state disabled
    }

    return 1

  }

  ######################################################################
  # Create the filter menu.
  proc create_filter_menu {} {

    variable data

    # Create the main filter menu
    set data(widgets,filter) [menu $data(widgets,cat).mnu -tearoff 1 -postcommand [list themer::handle_filter_menu_post]]

    $data(widgets,filter) add command -label [msgcat::mc "Table Filters"] -state disabled
    $data(widgets,filter) add separator
    $data(widgets,filter) add command -label [msgcat::mc "   Show All"] -command [list themer::filter_all]
    $data(widgets,filter) add cascade -label [msgcat::mc "   Show Category"] -menu [menu $data(widgets,filter).catMenu -tearoff 0]
    $data(widgets,filter) add cascade -label [msgcat::mc "   Show Color"]    -menu [menu $data(widgets,filter).colorMenu -tearoff 0 -postcommand [list themer::populate_filter_color_menu]]
    $data(widgets,filter) add command -label [msgcat::mc "   Show Selected Value"]  -command [list themer::filter_selected value]
    $data(widgets,filter) add command -label [msgcat::mc "   Show Selected Option"] -command [list themer::filter_selected opt]

    # Populate the category submenu
    foreach title [theme::get_category_titles] {
      $data(widgets,filter).catMenu add command -label $title -command [list themer::filter_category $title]
    }

  }

  ######################################################################
  # Handles the state of the filter menu.
  proc handle_filter_menu_post {} {

    variable data

    if {[$data(widgets,cat) curselection] eq ""} {
      $data(widgets,filter) entryconfigure [msgcat::mc "   Show Selected Value"]  -state disabled
      $data(widgets,filter) entryconfigure [msgcat::mc "   Show Selected Option"] -state disabled
    } else {
      $data(widgets,filter) entryconfigure [msgcat::mc "   Show Selected Value"]  -state normal
      $data(widgets,filter) entryconfigure [msgcat::mc "   Show Selected Option"] -state normal
    }

  }

  ######################################################################
  # Populates the filter color menu.
  proc populate_filter_color_menu {} {

    variable data

    # Clear the menu contents
    $data(widgets,filter).colorMenu delete 0 end

    # Gather the colors
    set first 1
    foreach colors [theme::get_all_colors] {
      foreach color $colors {
        $data(widgets,filter).colorMenu add command -label $color -command [list themer::filter_color $color]
      }
      if {$first} {
        $data(widgets,filter).colorMenu add separator
        set first 0
      }
    }

  }

  ######################################################################
  # Displays the filter menu.
  proc show_filter_menu {tbl col} {

    variable data

    tk_popup $data(widgets,filter) [winfo rootx $data(widgets,cat)] [winfo rooty $data(widgets,cat)]

  }

  ######################################################################
  # Show all table lines.
  proc filter_all {} {

    variable data

    for {set i 0} {$i < [$data(widgets,cat) size]} {incr i} {
      $data(widgets,cat) rowconfigure $i -hide 0
    }

  }

  ######################################################################
  # Only show the given category.
  proc filter_category {title} {

    variable data

    foreach cat [$data(widgets,cat) childkeys root] {
      if {[$data(widgets,cat) cellcget $cat,opt -text] eq $title} {
        $data(widgets,cat) rowconfigure $cat -hide 0
      } else {
        $data(widgets,cat) rowconfigure $cat -hide 1
      }
    }

  }

  ######################################################################
  # Only display rows with the given color.
  proc filter_color {color} {

    variable data

    foreach cat [$data(widgets,cat) childkeys root] {
      set one_match 0
      foreach child [$data(widgets,cat) childkeys $cat] {
        set category [$data(widgets,cat) cellcget $child,category -text]
        set opt      [$data(widgets,cat) cellcget $child,opt      -text]
        if {([lindex [theme::get_type $category $opt] 0] eq "color") && ([$data(widgets,cat) cellcget $child,value -background] eq $color)} {
          $data(widgets,cat) rowconfigure $child -hide 0
          set one_match 1
        } else {
          $data(widgets,cat) rowconfigure $child -hide 1
        }
      }
      $data(widgets,cat) rowconfigure $cat -hide [expr $one_match ^ 1]
    }

  }

  ######################################################################
  # Matches all rows that have the same column value as the currently
  # selected row.
  proc filter_selected {col} {

    variable data

    # Get the selected row
    set value [$data(widgets,cat) cellcget [$data(widgets,cat) curselection],$col -text]

    foreach cat [$data(widgets,cat) childkeys root] {
      set one_match 0
      foreach child [$data(widgets,cat) childkeys $cat] {
        if {[$data(widgets,cat) cellcget $child,$col -text] eq $value} {
          $data(widgets,cat) rowconfigure $child -hide 0
          set one_match 1
        } else {
          $data(widgets,cat) rowconfigure $child -hide 1
        }
      }
      $data(widgets,cat) rowconfigure $cat -hide [expr $one_match ^ 1]
    }

  }

}

