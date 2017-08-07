# Plugin namespace
namespace eval css_colorize {

  variable lengths
  variable res {
    {#([0-9a-fA-F]{3,6})}
    {rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)}
    {rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+\.\d+)\s*\)}
    {hsl\(\s*(\d+)\s*,\s*(\d+)\s*%\s*,\s*(\d+)\s*%\s*\)}
    {hsla\(\s*(\d+)\s*,\s*(\d+)\s*%\s*,\s*(\d+)\s*%\s*,\s*(\d+\.\d+)\s*\)}
  }

  array set colorized {}

  ######################################################################
  # Returns the RGB color associated with the given value
  # string
  proc get_color {txt value} {

    variable res

    if {[regexp [lindex $res 0] $value -> val]} {
      switch [string length $val] {
        3       -
        6       { return $value }
        default { return "" }
      }

    } elseif {[regexp [lindex $res 1] $value -> r g b]} {
      return [format "#%02x%02x%02x" $r $g $b]

    } elseif {[regexp [lindex $res 2] $value -> r g b a]} {
      lassign [api::color_to_rgb [format "#%02x%02x%02x" $r $g $b]] mr mg mb
      lassign [api::color_to_rgb [$txt cget -background]] or og ob
      return [format "#%02x%02x%02x" \
        [expr int( ($mr * $a) + ($or * (1.0 - $a)) )] \
        [expr int( ($mg * $a) + ($og * (1.0 - $a)) )] \
        [expr int( ($mb * $a) + ($ob * (1.0 - $a)) )] \
      ]

    } elseif {[regexp [lindex $res 3] $value -> h s l]} {
      return [format "#%02x%02x%02x" {*}[api::hsl_to_rgb $h $s $l]]

    } elseif {[regexp [lindex $res 4] $value -> h s l a]} {
      lassign [api::hsl_to_rgb $h $s $l] mr mg mb
      lassign [api::color_to_rgb [$txt cget -background]] or og ob
      return [format "#%02x%02x%02x" \
        [expr int( ($mr * $a) + ($or * (1.0 - $a)) )] \
        [expr int( ($mg * $a) + ($og * (1.0 - $a)) )] \
        [expr int( ($mb * $a) + ($ob * (1.0 - $a)) )] \
      ]
    }

    return white

  }

  ######################################################################
  # Removes all of the colorized elements in the specifies text widget.
  proc remove_colors {txt} {

    catch {
      $txt tag delete {*}[lsearch -all -inline [$txt tag names] css_colorize:*]
    }

  }

  ######################################################################
  # Parses and colorizes the current editing buffer.
  proc colorize_do {} {

    variable colorized

    # Get the current editing buffer index.
    set index [api::file::current_file_index]
    set txt   [api::file::get_info $index txt]

    # Indicate that this editing buffer has been colorized
    set colorized($txt) 1

    # Perform colorization
    colorize $txt

  }

  ######################################################################
  # Perform colorization.
  proc colorize {txt} {

    variable res
    variable colorized

    # If we weren't manually colorized, stop now
    if {![info exists colorized($txt)]} {
      return
    }

    # Remove the current colorx
    remove_colors $txt

    # Colorize
    foreach re $res {
      set lengths [list]
      set i       0
      foreach start [$txt search -all -count lengths -regexp -- $re 1.0 end] {
        set end   [$txt index "$start+[lindex $lengths $i]c"]
        set color [get_color $txt [$txt get $start $end]]
        $txt tag configure css_colorize:$color -background $color -foreground [api::get_complementary_mono_color $color]
        $txt tag add css_colorize:$color $start $end
        incr i
      }
    }

    # Track that we have colorized this text widget
    set colorized($txt) 1

  }

  ######################################################################
  # Handles the state of the colorize menu item.  Only allow colorizing
  # CSS and HTML files.
  proc colorize_handle_state {} {

    if {[set index [api::file::current_file_index]] == -1} {
      return 0
    }

    set lang [api::file::get_info $index lang]

    return [expr [lsearch [list CSS SCSS HTML] $lang] != -1]

  }

  ######################################################################
  # Uncolorizes the current editing buffer.
  proc uncolorize_do {} {

    variable colorized

    # Get the current editing buffer index.
    set index [api::file::current_file_index]
    set txt   [api::file::get_info $index txt]

    # Indicate that this editing buffer has been colorized
    set colorized($txt) 0

    # Remove the colors
    remove_colors $txt

  }

  ######################################################################
  # Returns 1 if the uncolorize option should be enabled in the menu.
  proc uncolorize_handle_state {} {

    variable colorized

    # Get the current file index, if there is one
    if {[set index [api::file::current_file_index]] == -1} {
      return 0
    }

    # Get the current text widget and language
    set txt  [api::file::get_info $index txt]
    set lang [api::file::get_info $index lang]

    if {![info exists colorized($txt)]} {
      return 0
    } else {
      return [expr ([lsearch [list CSS SCSS HTML] $lang] != -1) && $colorized($txt)]
    }

  }

  ######################################################################
  # This is only needed so that we can interact with the text
  # widget.  We are not going to do anything right now.
  proc do_binding {tag} {

    bind $tag <<ThemeChanged>> [list css_colorize::colorize %W]

  }

  ######################################################################
  # Called on buffer save.  Re-colorizes the current editing buffer if
  # colorizing was enabled.
  proc save_do {file_index} {

    # Perform the colorizing
    colorize [api::file::get_info $file_index txt]

  }

  ######################################################################
  # Called just prior to the plugin being reloaded.
  proc store_do {index} {

    variable colorized

    # Save the value of some_data to non-corruptible memory
    api::plugin::save_variable $index "colorized" [array get colorized]

  }

  ######################################################################
  # Called just after the plugin is reloaded.
  proc restore_do {index} {

    variable colorized

    array set colorized [api::plugin::load_variable $index "colorized"]

  }

}

# Register all plugin actions
api::register css_colorize {
  {text_binding pretext attach all css_colorize::do_binding}
  {menu command "CSS Colorize/Colorize"   css_colorize::colorize_do   css_colorize::colorize_handle_state}
  {menu command "CSS Colorize/Uncolorize" css_colorize::uncolorize_do css_colorize::uncolorize_handle_state}
  {on_save css_colorize::save_do}
  {on_reload css_colorize::store_do css_colorize::restore_do}
}
