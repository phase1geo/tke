# This TKE plugin allows the user to highlight all matches of a word
# when it's selected by double-clicking.

# Plugin namespace
namespace eval highlight_matches {

  variable rows_to_span ""

  #====== Get current text command

  proc get_txt {} {

    set file_index [api::file::current_index]
    if {$file_index == -1} {
        return ""
    }
    return [api::file::get_info $file_index txt]

  }

  #====== Get checked rows_to_span from string

  proc get_rows_to_span {inst} {

    variable rows_to_span
    set rows_to_span [string trim $inst]
    if {$rows_to_span ne ""} {
      if { [catch {set rows_to_span [expr int($rows_to_span)]}] } {
        set rows_to_span ""
        return 0
      }
    }
    return 1

  }

  #====== Get spanned index as "row.0" or "row.end"

  #  ins  - text inserting index (position of cursor)
  #  addn - number of rows to be added to ins
  #  col  - starting/ending column

  proc get_span {ins addn col} {

    set span "[lindex [split $ins .] 0] $addn"
    # Tk properly treats the out-of-ranges as "1.0" and "end"
    # so no reason to worry
    return [expr {*}$span].$col

  }

  #====== Setup the plugin by entering the rows to be spanned

  proc do_setup {} {

    variable rows_to_span
    if {[api::get_user_input \
    "Nearby rows to span (0 means NONE, blank means ALL):" rows_to_span 0]} {
      set rts [string trim $rows_to_span]
      if {![get_rows_to_span $rts]} {
        api::show_error "\"$rts\" seems to be not a proper number.
          \nGood choices would be \"55\", \"99\" etc."
      }
    }

  }

  #====== Get current word or selection

  # returns a list containing:
  # - starting position of selection/word or 0
  # - selection/word

  proc get_selection {} {

    set txt [get_txt]
    if {$txt == ""} {return [list "" 0 0]}
    set err [catch {$txt tag ranges sel} sel]
    if {!$err && [llength $sel]==2} {
      lassign $sel pos pos2           ;# single selection
      set sel [$txt get $pos $pos2]
    } else {
      if {$err || [string trim $sel]==""} {
        set sel [string trim [$txt get "insert wordstart" "insert wordend"]]
        set pos  [$txt index "insert wordstart"]
        set pos2 [$txt index "insert wordend"]
      } else {
        foreach {pos pos2} $sel {     ;# multiple selections: find current one
          if {[$txt compare $pos >= insert] ||
          [$txt compare $pos <= insert] && [$txt compare insert <= $pos2]} {
            break
          }
        }
        set sel [$txt get $pos $pos2]
      }
    }
    if {[string length $sel] == 0} {
      set pos 0
    }
    return [list $sel $pos $pos2]

  }

  #====== Seek the selected word forward/backward/to first/to last

  proc do_seek {mode} {

    lassign [get_selection] sel pos pos2
    if {!$pos} return
    set txt [get_txt]
    if {$txt == ""} return
    switch $mode {
      0 { # backward
          set nc [expr {[string length $sel] - 1}]
          set pos [$txt index "$pos - $nc chars"]
          set pos [$txt search -backwards -- $sel $pos 1.0]
        }
      1 { # forward
          set pos [$txt search -- $sel $pos2 end]
        }
      2 { # to first
          set pos [$txt search -- $sel 1.0 end]
        }
      3 { # to last
          set pos [$txt search -backwards -- $sel end 1.0]
        }
    }
    if {[string length "$pos"]} {
      api::edit::move_cursor $txt left -startpos $pos -num 0
      $txt tag add sel $pos [$txt index "$pos + [string length $sel] chars"]
    }

  }

  #====== Get the selected word and highlight its matches

  proc highlight_operate {w fromto} {

    if {![handle_highlight_state]} return
    lassign [get_selection] sel pos
    set lenList {}
    set posList [$w search -all -count lenList -- "$sel" {*}$fromto]
    set mlen [llength $lenList]
    set mmes "$mlen matches of \"$sel\""
    api::show_info "$mmes to be highlighted... PLEASE WAIT..."
    update
    foreach pos $posList len $lenList {
      $w tag add sel $pos [$w index "$pos + $len chars"]
    }
    api::show_info "$mmes highlighted" -clear_delay [expr 7000+$mlen*20]

  }

  #====== Highlight matches of selected text

  proc highlight_from_menu {} {

    variable rows_to_span
    set txt [get_txt]
    if {$txt == ""} return
    if {$rows_to_span eq "" || $rows_to_span eq "0"} {
      set from 1.0
      set to end
    } else {
      set ins [$txt index "insert"]
      set from [get_span $ins -$rows_to_span 0]
      set to   [get_span $ins +$rows_to_span end]
    }
    highlight_operate $txt "$from $to"

  }

  proc highlight_matches {} {

    variable rows_to_span
    if {$rows_to_span ne "0"} {
      highlight_from_menu
    }

  }

  #====== Procedures to save/restore options

  proc do_store {index} {

    variable rows_to_span
    api::plugin::save_variable $index "rows_to_span" $rows_to_span

  }

  proc do_restore {index} {

    get_rows_to_span [api::plugin::load_variable $index "rows_to_span"]

  }

  #====== Procedures to register the plugin

  proc do_matches {btag} {

    bind $btag <Double-ButtonPress-1> {highlight_matches::highlight_matches}
    return 1

  }

  proc handle_highlight_state {} {

    lassign [get_selection] sel
    if {[string length $sel] < 2}      {return 0}  ;# nothing to highlight
    if {[string first "\n" $sel] >= 0} {return 0}  ;# ignore multilines
    return 1

  }

  proc handle_seek_state {} {

    lassign [get_selection] sel pos
    return $pos

  }

  proc handle_options_state {} {

    return 1

  }

}

#====== Register plugin action

api::register highlight_matches {
  {text_binding posttext himatch all highlight_matches::do_matches}
  {menu command {Highlight Matches/Highlight} \
      highlight_matches::highlight_from_menu  highlight_matches::handle_highlight_state}
  {menu separator {Highlight Matches}}
  {menu command {Highlight Matches/Jump Backward} \
      {highlight_matches::do_seek 0}  highlight_matches::handle_seek_state}
  {menu command {Highlight Matches/Jump Forward} \
      {highlight_matches::do_seek 1}  highlight_matches::handle_seek_state}
  {menu command {Highlight Matches/Jump to First} \
      {highlight_matches::do_seek 2}  highlight_matches::handle_seek_state}
  {menu command {Highlight Matches/Jump to Last} \
      {highlight_matches::do_seek 3}  highlight_matches::handle_seek_state}
  {menu separator {Highlight Matches}}
  {menu command {Highlight Matches/Options...} \
      highlight_matches::do_setup  highlight_matches::handle_options_state}
  #{on_start highlight_matches::do_restore}
  #{on_quit highlight_matches::do_store}
}
