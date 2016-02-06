# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
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
# Name:    embed_tke.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    06/05/2014
# Brief:   Package that provides an embeddable TKE editor to be used
#          in external applications.
######################################################################

package provide embed_tke 1.0

set tke_dir   [file normalize [embed_tke::DIR]]
set tke_home  [file normalize [file join ~ .tke]]

set auto_path [concat [file join $tke_dir lib] $auto_path]

package require -exact ctext 4.0
package require tooltip

source [file join $tke_dir lib bgproc.tcl]

namespace eval embed_tke {

  source [file join [DIR] lib preferences.tcl]
  source [file join [DIR] lib tkedat.tcl]
  source [file join [DIR] lib gui.tcl]
  source [file join [DIR] lib vim.tcl]
  source [file join [DIR] lib syntax.tcl]
  source [file join [DIR] lib indent.tcl]
  source [file join [DIR] lib utils.tcl]
  source [file join [DIR] lib multicursor.tcl]
  source [file join [DIR] lib snippets.tcl]
  source [file join [DIR] lib markers.tcl]

  # Handle launcher requests
  namespace eval launcher {
    proc register {args} {}
    proc unregister {args} {}
  }

  namespace eval gui {
    rename update_position update_position__orig
    rename save_current save_current__orig
    rename close_current close_current__orig

    proc update_position {args} {}
    proc save_current {args} { puts "Saving" }
    proc close_current {args} { puts "Closing" }
  }

  variable right_click 3

  array set data   {}
  array set images {}

  array set widget_options {
    -language {language Language}
  }

  # On Mac, the right-click button is button 2
  if {[tk windowingsystem] eq "aqua"} {
    set right_click 2
  }

  ######################################################################
  # Creates an embeddable TKE widget and returns the pathname to the widget
  proc embed_tke {w args} {

    variable data
    variable images
    variable widget_options
    variable right_click

    # If this is the first time we have been called, do some initialization
    if {[array size images] == 0} {

      # Initialize default options
      option add *EmbedTke.language      "None" widgetDefault

      # Create images
      set imgdir [file join $::tke_dir lib images]
      set images(split) \
        [image create bitmap -file     [file join $imgdir split.bmp] \
                             -maskfile [file join $imgdir split.bmp] \
                             -foreground grey10]
      set images(close) \
        [image create bitmap -file     [file join $imgdir close.bmp] \
                             -maskfile [file join $imgdir close.bmp] \
                             -foreground grey10]
      set images(global) \
        [image create photo  -file     [file join $imgdir global.gif]]

      # Load the preferences
      preferences::load

      # Load the snippets
      snippets::load

      # Load the syntax highlighting information
      syntax::load

    }

    # Create widget
    ttk::frame $w
    ctext $w.txt -wrap none -undo 1 -autoseparators 1 -insertofftime 0 \
      -highlightcolor yellow \
      -linemap_mark_command gui::mark_command -linemap_select_bg orange
    #-warnwidth $preferences::prefs(Editor/WarningWidth)
    ttk::label     $w.split -image $images(split) -anchor center
    ttk::scrollbar $w.vb    -orient vertical   -command "$w.txt yview"
    ttk::scrollbar $w.hb    -orient horizontal -command "$w.txt xview"

    bind Ctext    <<Modified>>               "[namespace current]::gui::text_changed %W"
    bind $w.txt.l <ButtonPress-$right_click> [bind $w.txt.l <ButtonPress-1>]
    bind $w.txt.l <ButtonPress-1>            "[namespace current]::gui::select_line %W %y"
    bind $w.txt.l <B1-Motion>                "[namespace current]::gui::select_lines %W %y"
    bind $w.txt.l <Shift-ButtonPress-1>      "[namespace current]::gui::select_lines %W %y"
    bind $w.txt   <<Selection>>              "[namespace current]::gui::selection_changed %W"
    bind $w.txt   <ButtonPress-1>            "after idle [list [namespace current]::gui::update_position %W]"
    bind $w.txt   <B1-Motion>                "[namespace current]::gui::update_position %W"
    bind $w.txt   <KeyRelease>               "[namespace current]::gui::update_position %W"
    bind $w.split <Button-1>                 "[namespace current]::gui::toggle_split_pane $w.txt"
    bind Text     <<Cut>>                    ""
    bind Text     <<Copy>>                   ""
    bind Text     <<Paste>>                  ""
    bind Text     <Control-d>                ""
    bind Text     <Control-i>                ""

    # Move the all bindtag ahead of the Text bindtag
    set text_index [lsearch [bindtags $w.txt.t] Text]
    set all_index  [lsearch [bindtags $w.txt.t] all]
    bindtags $w.txt.t [lreplace [bindtags $w.txt.t] $all_index $all_index]
    bindtags $w.txt.t [linsert  [bindtags $w.txt.t] $text_index all]

    # Create the Vim command bar
    vim::bind_command_entry $w.txt \
      [entry $w.ve -background black -foreground white -insertbackground white \
        -font [$w.txt cget -font]] $w.txt

    # Create the search bar
    ttk::frame $w.sf
    ttk::label $w.sf.l1    -text [msgcat::mc "Find:"]
    ttk::entry $w.sf.e
    ttk::label $w.sf.case  -text "Aa" -relief raised
    ttk::label $w.sf.close -image $images(close)

    tooltip::tooltip $w.sf.case "Case sensitivity"

    pack $w.sf.l1    -side left  -padx 2 -pady 2
    pack $w.sf.e     -side left  -padx 2 -pady 2 -fill x -expand yes
    pack $w.sf.close -side right -padx 2 -pady 2
    pack $w.sf.case  -side right -padx 2 -pady 2

    bind $w.sf.e     <Escape>    "[namespace current]::gui::close_search"
    bind $w.sf.case  <Button-1>  "[namespace current]::gui::toggle_labelbutton %W"
    bind $w.sf.case  <Key-space> "[namespace current]::gui::toggle_labelbutton %W"
    bind $w.sf.case  <Escape>    "[namespace current]::gui::close_search"
    bind $w.sf.close <Button-1>  "[namespace current]::gui::close_search"
    bind $w.sf.close <Key-space> "[namespace current]::gui::close_search"

    # Create the search/replace bar
    ttk::frame $w.rf
    ttk::label $w.rf.fl    -text [msgcat::mc "Find:"]
    ttk::entry $w.rf.fe
    ttk::label $w.rf.rl    -text [msgcat::mc "Replace:"]
    ttk::entry $w.rf.re
    ttk::label $w.rf.case  -text "Aa" -relief raised
    ttk::label $w.rf.glob  -image $images(global) -relief raised
    ttk::label $w.rf.close -image $images(close)

    tooltip::tooltip $w.rf.case "Case sensitivity"
    tooltip::tooltip $w.rf.glob "Replace globally"

    pack $w.rf.fl    -side left -padx 2 -pady 2
    pack $w.rf.fe    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $w.rf.rl    -side left -padx 2 -pady 2
    pack $w.rf.re    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $w.rf.case  -side left -padx 2 -pady 2
    pack $w.rf.glob  -side left -padx 2 -pady 2
    pack $w.rf.close -side left -padx 2 -pady 2

    bind $w.rf.fe    <Return>    "[namespace current]::gui::do_search_and_replace $w.txt"
    bind $w.rf.re    <Return>    "[namespace current]::gui::do_search_and_replace $w.txt"
    bind $w.rf.glob  <Return>    "[namespace current]::gui::do_search_and_replace $w.txt"
    bind $w.rf.fe    <Escape>    "[namespace current]::gui::close_search_and_replace"
    bind $w.rf.re    <Escape>    "[namespace current]::gui::close_search_and_replace"
    bind $w.rf.case  <Button-1>  "[namespace current]::gui::toggle_labelbutton %W"
    bind $w.rf.case  <Key-space> "[namespace current]::gui::toggle_labelbutton %W"
    bind $w.rf.case  <Escape>    "[namespace current]::gui::close_search_and_replace"
    bind $w.rf.glob  <Button-1>  "[namespace current]::gui::toggle_labelbutton %W"
    bind $w.rf.glob  <Key-space> "[namespace current]::gui::toggle_labelbutton %W"
    bind $w.rf.glob  <Escape>    "[namespace current]::gui::close_search_and_replace"
    bind $w.rf.close <Button-1>  "[namespace current]::gui::close_search_and_replace"
    bind $w.rf.close <Key-space> "[namespace current]::gui::close_search_and_replace"

    # FOOBAR
    grid rowconfigure    $w 1 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid $w.txt   -row 0 -column 0 -sticky news -rowspan 2
    grid $w.split -row 0 -column 1 -sticky news
    grid $w.vb    -row 1 -column 1 -sticky ns
    grid $w.hb    -row 2 -column 0 -sticky ew
    grid $w.ve    -row 3 -column 0 -sticky ew
    grid $w.sf    -row 4 -column 0 -sticky ew
    grid $w.rf    -row 5 -column 0 -sticky ew

    # Hide the vim command entry, search bar, search/replace bar and search separator
    grid remove $w.ve
    grid remove $w.sf
    grid remove $w.rf

    # Add the text bindings
    indent::add_bindings      $w.txt
    multicursor::add_bindings $w.txt
    snippets::add_bindings    $w.txt
    vim::set_vim_mode         $w.txt $w.txt

    # Apply the appropriate syntax highlighting for the given extension
    syntax::set_language $w.txt "<None>"

    # Initialize the options array
    foreach opt [array names widget_options] {
      set data($w,option,$opt) [option get $w [lindex $widget_options($opt) 0] [lindex $widget_options($opt) 1]]
    }

    # Configure the widget
    configure 1 $w {*}$args

    # Rename and alias the embed_tke window
    rename ::$w $w
    interp alias {} ::$w {} embed_tke::widget_cmd $w

    return $w

  }

  ######################################################################
  # Calls the various widget commands.
  proc widget_cmd {w args} {

    if {[llength $args] == 0} {
      return -code error "embed_tke widget called without a command"
    }

    set cmd  [lindex $args 0]
    set opts [lrange $args 1 end]

    switch $cmd {
      cget      { return [embed_tke::cget $w {*}$opts] }
      configure { return [embed_tke::configure 0 $w {*}$opts] }
      default   { return -code error "Unknown embed_tke command ($cmd)" }
    }

  }

  ######################################################################
  # configure command.
  proc configure {initialize w args} {

    variable data
    variable widget_options

    if {([llength $args] == 0) && !$initialize} {

      set results [list]

      foreach opt [lsort [array names widget_options]] {
        if {[llength $widget_options($opt)] == 2} {
          set opt_name    [lindex $widget_options($opt) 0]
          set opt_class   [lindex $widget_options($opt) 1]
          set opt_default [option get $w $opt_name $opt_class]
          if {[info exists data($w,option,$opt)]} {
            lappend results [list $opt $opt_name $opt_class $opt_default $data($w,option,$opt)]
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
        if {[info exists data($w,option,$opt)]} {
          return [list $opt $opt_name $opt_class $opt_default $data($w,option,$opt)]
        } else {
          return [list $opt $opt_name $opt_class $opt_default ""]
        }
      }

      return -code error "tabbar::configuration option [lindex $args 0] does not exist"

    } else {

      # Save the original contents
      array set orig_options [array get data $w,option,*]

      # Parse the arguments
      foreach {name value} $args {
        if {[info exists data($w,option,$name)]} {
          set data($w,option,$name) $value
        } else {
          return -code error "Illegal option given to the embed_tke::configure command ($name)"
        }
      }

      # Set the language
      if {$orig_options($w,option,-language) ne $data($w,option,-language)} {
        if {[lsearch [syntax::get_languages] $data($w,option,-language)] != -1} {
          syntax::set_language $w.txt $data($w,option,-language)
        } else {
          return -code error "Unknown language ($data($w,option,-language) specified in embed_tke::configure command"
        }
      }

    }

  }

  ######################################################################
  # cget command.
  proc cget {w args} {

    variable data

    # Verify the argument list is valid
    if {[llength $args] != 1} {
      return -code error "Incorrect number of parameters given to the embed_tke::cget command"
    }

    if {[info exists data($w,option,[lindex $args 0])]} {
      return $data($w,option,[lindex $args 0])
    } else {
      return -code error "Illegal options given to the embed_tke::cget command ([lindex $args 0])"
    }

  }

}
