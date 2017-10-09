namespace eval current_line {

  array set colors {
    normal "black"
    embed  "black"
  }

  proc do_cline {tag} {

    bind $tag <FocusIn>         "current_line::update_line %W"
    bind $tag <FocusOut>        "current_line::remove_line %W"
    bind $tag <B1-Motion>       "after idle [list current_line::update_line %W]"
    bind $tag <<CursorChanged>> "after idle [list current_line::update_line %W]"

  }

  proc update_color {txt} {

    variable colors

    if {![winfo exists $txt]} {
      return
    }

    # Get the current color
    set color [expr {([lsearch [$txt tag names insert] _Lang=*] != -1) ? $colors(embed) : $colors(normal)}]

    # Configure the current_line tag
    $txt tag configure current_line -background $color

  }

  proc update_line {txt} {

    # If the text window no longer exists, exit now
    if {![winfo exists $txt]} {
      return
    }

    # If a selection exists, remove the current line indicator
    if {[$txt tag ranges sel] ne ""} {
      remove_line $txt
      return
    }

    # Update the current line color
    update_color $txt

    # Get the current cursor line number
    set line [lindex [split [$txt index insert] .] 0]

    # Get the last highlighted line number
    if {[set range [$txt tag ranges current_line]] eq ""} {
      set last_line_start 0
      set last_line_end   0
    } else {
      set last_line_start [lindex [split [lindex $range 0] .] 0]
      set last_line_end   [lindex [split [lindex $range 1] .] 0]
    }

    # If the line has changed, delete the current line
    if {$last_line_start != $line} {
      $txt tag remove current_line $last_line_start.0 [expr $last_line_end + 1].0
    }

    # Highlight the current line
    $txt tag add current_line $line.0 [expr $line + 1].0

  }

  proc remove_line {txt} {

    if {[set range [$txt tag ranges current_line]] ne ""} {
      $txt tag remove current_line {*}$range
    }

  }

  proc do_reload_store {index} {

    variable colors

    api::plugin::save_variable $index "colors" [array get colors]

  }

  proc do_reload_restore {index} {

    variable colors

    array set colors [api::plugin::load_variable $index "colors"]

  }

  proc do_open {index} {

    variable colors

    set txt [api::file::get_info $index txt]

    $txt tag configure current_line -background $colors(normal)
    $txt tag lower     current_line

  }

  proc do_uninstall {} {

    foreach index [api::file::all_indices] {
      [api::file::get_info $index txt] tag delete current_line
    }

  }

  ######################################################################
  # Update the current line colors to match the new theme.
  proc do_theme_changed {} {

    variable colors

    # Get the new background and embedded background colors
    set colors(normal) [api::auto_adjust_color [api::theme::get_value "syntax" "background"] 25]
    set colors(embed)  [api::auto_adjust_color [api::theme::get_value "syntax" "embedded"]   25]

    foreach index [api::file::all_indices] {
      current_line::update_color [api::file::get_info $index txt]
    }

  }

}

api::register current_line {
  {text_binding pretext cline all current_line::do_cline}
  {on_reload current_line::do_reload_store current_line::do_reload_restore}
  {on_open current_line::do_open}
  {on_uninstall current_line::do_uninstall}
  {on_theme_changed current_line::do_theme_changed}
}
