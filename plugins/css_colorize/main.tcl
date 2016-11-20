# Plugin namespace
namespace eval css_colorize {

  variable lengths
  variable res {
    {#([0-9a-fA-F]{3,6})}
    {rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)}
    {rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+.\d+)\s*)}
    {hsl\(\s*(\d+)\s*,\s*(\d+)\s*%\s*,\s*(\d+)\s*%\s*)}
    {hsla\(\s*(\d+)\s*,\s*(\d+)\s*%\s*,\s*(\d+)\s*%\s*,\s*(\d+.\d+)\s*)}
  }

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
        [expr int( (($mr * $a) + ($or * (1.0 - $a))) / 2 )] \
        [expr int( (($mg * $a) + ($og * (1.0 - $a))) / 2 )] \
        [expr int( (($mb * $a) + ($ob * (1.0 - $a))) / 2 )] \
      ]

    } elseif {[regexp [lindex $res 3] $value -> h s l]} {
      return [format "#%02x%02x%02x" {*}[api::hsl_to_rgb $h $s $l]]

    } elseif {[regexp [lindex $res 4] $value -> h s l a]} {
      lassign [api::hsl_to_rgb $h $s $l] mr mg mb
      lassign [api::color_to_rgb [$txt cget -background]] or og ob
      return [format "#%02x%02x%02x" \
        [expr int( (($mr * $a) + ($or * (1.0 - $a))) / 2 )] \
        [expr int( (($mg * $a) + ($og * (1.0 - $a))) / 2 )] \
        [expr int( (($mb * $a) + ($ob * (1.0 - $a))) / 2 )] \
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

    variable res

    # Get the current editing buffer index.
    set index [api::file::current_file_index]
    set txt   [api::file::get_info $index txt]

    puts "txt: $txt"

    # Remove the current colorx
    remove_colors $txt

    puts "Colors has been removed"

    # Colorize
    catch {
    foreach re $res {
      puts "re: $re"
      set lengths [list]
      set i       0
      foreach start [$txt search -all -count lengths -regexp -- $re 1.0 end] {
        puts "  HERE, start: $start, lengths: $lengths"
        set end   [$txt index "$start+[lindex $lengths $i]c"]
        set color [get_color $txt [$txt get $start $end]]
        $txt tag configure css_colorize:$color -background $color -foreground [api::get_complementary_mono_color $color]
        $txt tag add css_colorize:$color $start $end
        incr i
      }
    }
    } rc
    puts "rc: $rc"

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
  # This is only needed so that we can interact with the text
  # widget.  We are not going to do anything right now.
  proc do_binding {tag} {

    # Do nothing

  }

}

# Register all plugin actions
api::register css_colorize {
  {text_binding pretext attach all css_colorize::do_binding}
  {menu command "CSS Colorize/Colorize" css_colorize::colorize_do css_colorize::colorize_handle_state}
}
