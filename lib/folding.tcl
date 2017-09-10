# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2017  Trevor Williams (phase1geo@gmail.com)
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
# Name:     folding.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     02/06/2016
# Brief:    Contains namespace handling code folding.
######################################################################

namespace eval folding {

  array set enable {}

  ######################################################################
  # Returns true if the given text widget has code folding enabled.
  proc get_enable {txt} {

    variable enable

    return $enable($txt)

  }

  ######################################################################
  # Returns the current value of fold enable
  proc get_vim_foldenable {txt} {

    return [expr [$txt gutter hide folding] ^ 1]

  }

  ######################################################################
  # Returns the indentation method based on the values of enable and the
  # current indentation mode.
  proc get_method {txt} {

    variable enable

    if {[info exists enable($txt)] && $enable($txt)} {
      switch [indent::get_indent_mode $txt] {
        "OFF"   { return "manual" }
        "IND"   { return "indent" }
        "IND+"  { return [expr {[indent::is_auto_indent_available $txt] ? "syntax" : "indent"}] }
        default { return "none" }
      }
    } else {
      return "none"
    }

  }

  ######################################################################
  # Returns true if the given position contains a fold point.
  proc fold_state {txt line} {

    if {[set state [$txt gutter get folding $line]] ne ""} {
      return $state
    }

    return "none"

  }

  ######################################################################
  # Returns a value of true if at least one of the specified folding marker
  # exists; otherwise, returns true.
  proc fold_state_exists {txt state} {

    return [expr [llength [$txt gutter get folding $state]] > 0]

  }

  ######################################################################
  # Adds the bindings necessary for code folding to work.
  proc initialize {txt} {

    # Set the fold enable
    set_fold_enable $txt [preferences::get View/EnableCodeFolding]

  }

  ######################################################################
  # Called whenever the text widget is destroyed.
  proc handle_destroy_txt {txt} {

    variable enable

    unset -nocomplain enable($txt)

  }

  ######################################################################
  # Set the fold enable to the given type.
  proc set_fold_enable {txt value} {

    variable enable

    if {[set enable($txt) $value]} {
      enable_folding $txt
      add_folds $txt 1.0 end
    } else {
      disable_folding $txt
    }

  }

  ######################################################################
  # Sets the value of the Vim foldenable indicator to the given boolean
  # value.  Updates the UI state accordingly.
  proc set_vim_foldenable {txt value} {

    if {$value == [$txt gutter hide folding]} {
      if {$value} {
        restore_folds $txt
        $txt gutter hide folding 0
      } else {
        $txt tag remove _folded 1.0 end
        $txt gutter hide folding 1
      }
    }

  }

  ######################################################################
  # Disables code folding in the given text widget.
  proc disable_folding {txt} {

    # Remove all folded text
    $txt tag remove _folded 1.0 end

    # Remove the gutter
    $txt gutter destroy folding

  }

  ######################################################################
  # Enables code folding in the current text widget.
  proc enable_folding {txt} {

    # Add the folding gutter
    $txt gutter create folding \
      open   [list -symbol \u25be -onclick [list folding::close_fold 1] -onshiftclick [list folding::close_fold 0]] \
      close  [list -symbol \u25b8 -onclick [list folding::open_fold  1] -onshiftclick [list folding::open_fold  0]] \
      eopen  [list -symbol \u25be -onclick [list folding::close_fold 1] -onshiftclick [list folding::close_fold 0]] \
      eclose [list -symbol \u25b8 -onclick [list folding::open_fold  1] -onshiftclick [list folding::open_fold  0]] \
      end    [list -symbol \u221f]

    # Restart the folding
    restart $txt

    # Update the closed marker color
    update_closed $txt

  }

  ######################################################################
  # Restarts the folder after the text widget has had its tags cleared.
  proc restart {txt} {

    $txt.t tag configure _folded -elide 1

  }

  ######################################################################
  # Update the closed marker colors.
  proc update_closed {txt} {

    if {[lsearch [$txt gutter names] folding] != -1} {

      array set theme [theme::get_syntax_colors]

      # Update the folding color
      $txt gutter configure folding close  -fg $theme(closed_fold)
      $txt gutter configure folding eclose -fg $theme(closed_fold)

    }

  }

  ######################################################################
  # Adds any found folds to the gutter
  proc add_folds {txt startpos endpos} {

    set method [get_method $txt]

    # If we are doing manual code folding, don't go any further
    if {$method eq "manual"} {
      return

    # Get the starting and ending line
    } elseif {$method eq "indent"} {
      set startpos 1.0
      if {[set range [$txt tag prevrange _prewhite "$startpos lineend"]] ne ""} {
        set startpos [lindex $range 0]
      }
    }

    set startline    [lindex [split [$txt index $startpos] .] 0]
    set endline      [lindex [split [$txt index $endpos]   .] 0]
    set lines(open)  [list]
    set lines(end)   [list]
    set lines(eopen) [list]

    # Clear the folding gutter in
    $txt gutter clear folding $startline $endline

    # Add the folding indicators
    for {set i $startline} {$i <= $endline} {incr i} {
      lappend lines([check_fold $txt $i]) $i
    }

    $txt gutter set folding open $lines(open) end $lines(end) eopen $lines(eopen)

  }

  ######################################################################
  # Returns true if a fold point has been detected at the given index.
  proc check_fold {txt line} {

    set indent_cnt   0
    set unindent_cnt 0

    switch [get_method $txt] {
      syntax {
        set indent_cnt   [indent::get_tag_count $txt.t indent   $line.0 $line.end]
        set unindent_cnt [indent::get_tag_count $txt.t unindent $line.0 $line.end]
      }
      indent {
        if {[lsearch [$txt tag names $line.0] _prewhite] != -1} {
          set prev 0
          set curr 0
          set next 0
          catch { set prev [$txt count -chars {*}[$txt tag prevrange _prewhite $line.0]] }
          catch { set curr [$txt count -chars {*}[$txt tag nextrange _prewhite $line.0]] }
          catch { set next [$txt count -chars {*}[$txt tag nextrange _prewhite $line.0+1c]] }
          set indent_cnt   [expr $curr < $next]
          set unindent_cnt [expr $curr < $prev]
          if {$indent_cnt && $unindent_cnt} {
            return "eopen"
          }
        }
      }
    }

    return [expr {($indent_cnt > $unindent_cnt) ? "open" : ($indent_cnt < $unindent_cnt) ? "end" : ""}]

  }

  ######################################################################
  # Returns the gutter information in sorted order.
  proc get_gutter_info {txt} {

    set data [list]

    foreach tag [list open close eopen eclose end] {
      foreach tline [$txt gutter get folding $tag] {
        lappend data [list $tline $tag]
      }
    }

    return [lsort -integer -index 0 $data]

  }

  ######################################################################
  # Returns the starting and ending positions of the range to fold.
  proc get_fold_range {txt line depth} {

    set count  0
    set aboves [list]
    set belows [list]
    set closed [list]

    if {[get_method $txt] eq "indent"} {

      set start_chars [$txt count -chars {*}[$txt tag nextrange _prewhite $line.0]]
      set next_line   $line.0
      set final       [lindex [split [$txt index end] .] 0].0
      set all_chars   [list]

      while {[set range [$txt tag nextrange _prewhite $next_line]] ne ""} {
        set chars [$txt count -chars {*}$range]
        set tline [lindex [split [lindex $range 0] .] 0]
        set state [fold_state $txt $tline]
        if {($state eq "close") || ($state eq "eclose")} {
          lappend closed $tline
        }
        if {($chars > $start_chars) || ($all_chars eq [list])} {
          if {($state ne "none") && ($state ne "end")} {
            lappend all_chars [list $tline $chars]
          }
        } else {
          set final $tline.0
          break
        }
        set next_line [lindex $range 1]
      }

      set last $start_chars
      foreach {tline chars} [concat {*}[lsort -integer -index 1 $all_chars]] {
        incr count [expr $chars != $last]
        if {$count < $depth} {
          lappend belows $tline
        } else {
          lappend aboves $tline
        }
        set last $chars
      }

      return [list [expr $line + 1].0 $final $belows $aboves $closed]

    } else {

      array set inc [list end -1 open 1 close 1 eopen -1 eclose -1]

      set index [lsearch -index 0 [set data [get_gutter_info $txt]] $line]

      foreach {tline tag} [concat {*}[lrange $data $index end]] {
        if {$tag ne "end"} {
          if {$count < $depth} {
            lappend belows $tline
          } else {
            lappend aboves $tline
          }
          if {($tag eq "close") || ($tag eq "eclose")} {
            lappend closed $tline
          }
        }
        if {[incr count $inc($tag)] == 0} {
          return [list [expr $line + 1].0 $tline.0 $belows $aboves $closed]
        } elseif {$count < 0} {
          set count 0
        } elseif {($tag eq "eopen") || ($tag eq "eclose")} {
          incr count
        }
      }

      return [list [expr $line + 1].0 [lindex [split [$txt index end] .] 0].0 $belows $aboves $closed]

    }

  }

  ######################################################################
  # Returns the line number of the highest level folding marker that contains
  # the given line.
  proc show_line {txt line} {

    if {![get_vim_foldenable $txt]} {
      return
    }

    array set counts [list open -1 close -1 eopen 0 eclose 0 end 1]

    # Find our current position
    set data  [lsort -integer -index 0 [list [list $line current] {*}[get_gutter_info $txt]]]
    set index [lsearch $data [list $line current]]
    set count 1

    for {set i [expr $index - 1]} {$i >= 0} {incr i -1} {
      lassign [lindex $data $i] line tag
      if {[incr count $counts($tag)] == 0} {
        open_fold 1 $txt $line
        if {[lsearch [$txt tag names $line.0] _folded] == -1} {
          return
        }
        set count 1
      }
    }

  }

  ######################################################################
  # Restores the eliding based on the stored values within the given text
  # widget.
  proc restore_folds {txt} {

    foreach line [$txt gutter get folding close] {
      lassign [get_fold_range $txt $line 1] startpos endpos
      $txt tag add _folded $startpos $endpos
    }

  }

  ######################################################################
  # Toggles the fold for the given line.
  proc toggle_fold {txt line {depth 1}} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return
    }

    switch [$txt gutter get folding $line] {
      open   -
      eopen  { close_fold $depth $txt $line }
      close  -
      eclose { open_fold  $depth $txt $line }
    }

  }

  ######################################################################
  # Toggles all folds.
  proc toggle_all_folds {txt} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return
    }

    if {[$txt gutter get folding open] ne [list]} {
      close_all_folds $txt
    } else {
      open_all_folds $txt
    }

  }

  ######################################################################
  # Close the selected range.
  proc close_range {txt startpos endpos} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return
    }

    if {[get_method $txt] eq "manual"} {

      lassign [split [$txt index $startpos] .] start_line start_col
      lassign [split [$txt index $endpos]   .] end_line   end_col

      $txt tag add _folded [expr $start_line + 1].0 [expr $end_line + 1].0
      $txt gutter set folding close $start_line
      $txt gutter set folding end   [expr $end_line + 1]

    }

  }

  ######################################################################
  # Close the selected text.
  proc close_selected {txt} {

    set retval 0

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    if {[get_method $txt] eq "manual"} {

      foreach {endpos startpos} [lreverse [$txt tag ranges sel]] {
        close_range $txt $startpos $endpos-1c
        set retval 1
      }

      # Clear the selection
      $txt tag remove sel 1.0 end

    }

    return $retval

  }

  ######################################################################
  # Attempts to delete the closed fold marker (if it exists).  This operation
  # is only valid in manual mode.
  proc delete_fold {txt line} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    if {[get_method $txt] eq "manual"} {

      # Get the current line state
      set state [fold_state $txt $line]

      # Open the fold if it is closed
      if {$state eq "close"} {
        open_fold 1 $txt $line
      }

      # Remove the start/end markers for the current fold
      if {($state eq "close") || ($state eq "open")} {
        lassign [get_fold_range $txt $line 1] startpos endpos
        $txt gutter clear folding $line
        $txt gutter clear folding [lindex [split $endpos .] 0]
        return $endpos
      }

    }

  }

  ######################################################################
  # Delete all folds between the first and last lines of the current
  # open/close fold.
  proc delete_folds {txt line} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    if {[get_method $txt] eq "manual"} {

      # Get the current line state
      set state [fold_state $txt $line]

      # Open the fold recursively if it is closed
      if {$state eq "close"} {
        open_fold 0 $txt $line
      }

      # If the line is closed or opened, continue with the recursive deletion
      if {($state eq "close") || ($state eq "open")} {
        lassign [get_fold_range $txt $line 1] startpos endpos
        $txt gutter clear folding $line [lindex [split $endpos .] 0]
      }

    }

  }

  ######################################################################
  # Deletes all fold markers found in the given range.
  proc delete_folds_in_range {txt startline endline} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    if {[get_method $txt] eq "manual"} {

      # Get all of the open/close folds
      set lines    [lsort -integer [list $startline {*}[$txt gutter get folding open] {*}[$txt gutter get folding close]]]
      set lineslen [llength $lines]
      set index    [expr [lsearch $lines $startline] + 1]

      while {($index < $lineslen) && ([lindex $lines $index] <= $endline)} {
        delete_fold $txt [lindex $lines $index]
        incr index
      }

    }

  }

  ######################################################################
  # Deletes all fold markers.  This operation is only valid in manual
  # mode.
  proc delete_all_folds {txt} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    if {[get_method $txt] eq "manual"} {

      # Remove all folded text
      $txt tag remove _folded 1.0 end

      # Clear all of fold indicators in the gutter
      $txt gutter clear folding 1 [lindex [split [$txt index end] .] 0]

    }

  }

  ######################################################################
  # Closes a fold, hiding the contents.
  proc close_fold {depth txt line} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    array set map {
      open   close
      close  close
      eopen  eclose
      eclose eclose
    }

    # Get the fold range
    lassign [get_fold_range $txt $line [expr ($depth == 0) ? 100000 : $depth]] startpos endpos belows

    # Replace the open/eopen symbol with the close/eclose symbol
    foreach line $belows {
      set type [$txt gutter get folding $line]
      $txt gutter clear folding $line
      $txt gutter set folding $map($type) $line
    }

    # Hide the text
    $txt tag add _folded $startpos $endpos

    return $endpos

  }

  ######################################################################
  # Close all folds in the given range.
  proc close_folds_in_range {txt startline endline depth} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    # Get all of the open folds
    set open_lines [$txt gutter get folding open]

    while {$startline <= $endline} {
      set lines     [lsort -integer [list $startline {*}$open_lines]]
      set index     [expr [lsearch $lines $startline] + 1]
      set startline [lindex [split [close_fold $depth $txt [lindex $lines $index]] .] 0]
    }

  }

  ######################################################################
  # Closes all open folds.
  proc close_all_folds {txt} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    array set inc [list end -1 open 1 close 1 eopen 0 eclose 0]

    # Get ordered gutter list
    set ranges [list]
    set count  0
    set oline  ""
    foreach {tline tag} [concat {*}[get_gutter_info $txt]] {
      if {($count == 0) && (($tag eq "open") || ($tag eq "eopen"))} {
        set oline [expr $tline + 1]
      }
      if {[incr count $inc($tag)] == 0} {
        if {$oline ne ""} {
          lappend ranges $oline.0 $tline.0
          set oline ""
        }
      } elseif {$count < 0} {
        set count 0
      }
    }

    if {[llength $ranges] > 0} {

      # Close the folds
      $txt gutter set folding close  [$txt gutter get folding open]
      $txt gutter set folding eclose [$txt gutter get folding eopen]

      # Adds folds
      $txt tag add _folded {*}$ranges

    }

  }

  ######################################################################
  # Opens a fold, showing the contents.
  proc open_fold {depth txt line} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    array set map {
      close  open
      open   open
      eclose eopen
      eopen  eopen
    }

    # Get the fold range
    lassign [get_fold_range $txt $line [expr ($depth == 0) ? 100000 : $depth]] startpos endpos belows aboves closed

    foreach tline [concat $belows $aboves] {
      set type [$txt gutter get folding $line]
      $txt gutter clear folding $tline
      $txt gutter set folding $map($type) $tline
    }

    # Remove the folded tag
    $txt tag remove _folded $startpos $endpos

    # Close all of the previous folds
    if {$depth > 0} {
      foreach tline [::struct::set intersect $aboves $closed] {
        close_fold 1 $txt $tline
      }
    }

    return $endpos

  }

  ######################################################################
  # Open all folds in the given range.
  proc open_folds_in_range {txt startline endline depth} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    # Get all of the closed folds
    set close_lines [$txt gutter get folding close]

    while {$startline <= $endline} {
      set lines     [lsort -integer [list $startline {*}$close_lines]]
      set index     [expr [lsearch $lines $startline] + 1]
      set startline [lindex [split [open_fold $depth $txt [lindex $lines $index]] .] 0]
    }

  }

  ######################################################################
  # Opens all closed folds.
  proc open_all_folds {txt} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    $txt tag remove _folded 1.0 end
    $txt gutter set folding open  [$txt gutter get folding close]
    $txt gutter set folding eopen [$txt gutter get folding eclose]

  }

  ######################################################################
  # Jumps to the next or previous folding.
  proc jump_to {txt dir {num 1}} {

    # If foldenable is 0, return immediately
    if {![get_vim_foldenable $txt]} {
      return $retval
    }

    # Get a sorted list of open/close tags and locate our current position
    set data [set line [lindex [split [$txt index insert] .] 0]]
    foreach tag [list close eclose] {
      lappend data {*}[$txt gutter get folding $tag]
    }

    # Find the index of the close symbols and set the cursor on the line
    if {[set index [lsearch [set data [lsort -unique -integer -index 0 $data]] $line]] != -1} {
      if {$dir eq "next"} {
        if {[incr index $num] == [llength $data]} {
          return
        }
      } else {
        if {[incr index -$num] < 0} {
          return
        }
      }
      ::tk::TextSetCursor $txt [lindex $data $index].0
      vim::adjust_insert $txt.t
    }

  }

  ######################################################################
  # Returns true if the specified index exists within a fold.
  proc is_folded {txt index} {

    return [expr [lsearch -exact [$txt tag names $index] _folded] != -1]

  }

}
