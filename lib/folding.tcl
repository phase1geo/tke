# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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

  source [file join $::tke_dir lib ns.tcl]

  array set method {}
  
  ######################################################################
  # Returns true if the given text widget has code folding enabled.
  proc get_method {txt} {

    variable method

    return $method($txt)

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

    variable method

    # Set the default method to none so we don't have to handle an unset method
    set method($txt) "none"

    # Set the fold method
    set_fold_method $txt [[ns preferences]::get View/CodeFoldingMethod]

  }

  ######################################################################
  # Set the fold method to the given type.
  proc set_fold_method {txt new_method} {

    variable method

    # If the new method is not valid, adjust it
    if {($new_method eq "syntax") && ![ctext::syntaxIndentationAllowed $txt]} {
      set new_method "indent"
    }

    # Set the text widget indentation mode
    $txt configure -indent_mode $new_method

    switch $method($txt),$new_method {
      none,manual {
        enable_folding $txt
      }
      none,indent -
      none,syntax {
        enable_folding $txt
        add_folds $txt 1.0 end
      }
      manual,none {
        disable_folding $txt
      }
      manual,indent -
      manual,syntax {
        $txt tag remove _folded 1.0 end
        add_folds $txt 1.0 end
      }
      indent,none {
        disable_folding $txt
      }
      indent,manual -
      indent,syntax {
        disable_folding $txt
        enable_folding $txt
      }
      syntax,none {
        disable_folding $txt
      }
      syntax,manual -
      syntax,indent {
        disable_folding $txt
        enable_folding $txt
      }
    }

    # Set the folding method for the specified text widget.
    set method($txt) $new_method

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
      open   [list -symbol \u25be -onclick [list [ns folding]::close_fold 1] -onshiftclick [list [ns folding]::close_fold 0]] \
      close  [list -symbol \u25b8 -onclick [list [ns folding]::open_fold  1] -onshiftclick [list [ns folding]::open_fold  0]] \
      eopen  [list -symbol \u25be -onclick [list [ns folding]::close_fold 1] -onshiftclick [list [ns folding]::close_fold 0]] \
      eclose [list -symbol \u25b8 -onclick [list [ns folding]::open_fold  1] -onshiftclick [list [ns folding]::open_fold  0]] \
      end    [list -symbol \u221f]

    # Create a tag that will cause stuff to hide
    $txt.t tag configure _folded -elide 1

  }

  ######################################################################
  # Adds any found folds to the gutter
  proc add_folds {txt startpos endpos} {

    variable method

    # If the method has not been set, don't continue
    if {![info exists method($txt)]} {
      return
    }

    # Get the starting and ending line
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

    variable method

    set indent_cnt   0
    set unindent_cnt 0

    if {$method($txt) eq "syntax"} {
      set indent_cnt   [[ns indent]::get_tag_count $txt.t indent   $line.0 $line.end]
      set unindent_cnt [[ns indent]::get_tag_count $txt.t unindent $line.0 $line.end]
    } elseif {$method($txt) eq "indent"} {
      set names        [$txt tag names $line.0]
      set indent_cnt   [expr [lsearch $names _indent]   != -1]
      set unindent_cnt [expr [lsearch $names _unindent] != -1]
      if {$indent_cnt && $unindent_cnt} {
        return "eopen"
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

    variable method

    set index  [lsearch -index 0 [set data [get_gutter_info $txt]] $line]
    set count  0
    set aboves [list]
    set belows [list]
    set closed [list]

    if {$method($txt) eq "indent"} {

      set start_chars [$txt count -chars {*}[$txt tag nextrange _indent $line.0]]
      set final       [lindex [split [$txt index end] .] 0].0
      set all_chars   [list]

      foreach {tline tag} [concat {*}[lrange $data $index end]] {
        if {$tag ne "end"} {
          set chars [$txt count -chars {*}[$txt tag nextrange _indent $tline.0]]
        } else {
          set chars [$txt count -chars {*}[$txt tag nextrange _unindent $tline.0]]
        }
        if {($tag eq "close") ||($tag eq "eclose")} {
          lappend closed $tline
        }
        if {($chars > $start_chars) || ($all_chars eq [list])} {
          lappend all_chars [list $tline $chars]
        } else {
          set final $tline.0
          break
        }
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
  # Toggles the fold for the given line.
  proc toggle_fold {txt line {depth 1}} {

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

    if {[$txt gutter get folding open] ne [list]} {
      close_all_folds $txt
    } else {
      open_all_folds $txt
    }

  }

  ######################################################################
  # Close the selected range.
  proc close_range {txt startpos endpos} {

    variable method

    if {$method($txt) eq "manual"} {
      lassign [split [$txt index $startpos] .] start_line start_col
      lassign [split [$txt index $endpos]   .] end_line   end_col
      if {$end_col == 0} {
        $txt tag add _folded "$startpos+1l linestart" $endpos
        $txt gutter set folding close $start_line
        $txt gutter set folding end   $end_line
      } else {
        $txt tag add _folded "$startpos+1l linestart" "$endpos+1l linestart"
        $txt gutter set folding close $start_line
        $txt gutter set folding end   [expr $end_line + 1]
      }
    }

  }

  ######################################################################
  # Close the selected text.
  proc close_selected {txt} {

    variable method

    set retval 0

    if {$method($txt) eq "manual"} {

      foreach {endpos startpos} [lreverse [$txt tag ranges sel]] {
        close_range $txt $startpos $endpos
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

    variable method

    if {$method($txt) eq "manual"} {

      # Get the current line state
      set state [fold_state $txt $line]

      # Open the fold if it is closed
      if {$state eq "close"} {
        open_fold 1 $txt $line
      }

      # Remove the start/end markers for the current fold
      if {($state eq "close") ||($state eq "open")} {
        lassign [get_fold_range $txt $line 1] startpos endpos
        $txt gutter clear folding $line
        $txt gutter clear folding [lindex [split $endpos .] 0]
        return $endpos
      }

    }

  }

  ######################################################################
  # Deletes all fold markers found in the given range.
  proc delete_folds_in_range {txt startline endline} {

    variable method

    if {$method($txt) eq "manual"} {

      # Get all of the open/close folds
      set all_lines [list {*}[$txt gutter get folding open] {*}[$txt gutter get folding close]]

      while {$startline <= $endline} {
        set lines     [lsort -integer [list $startline {*}$all_lines]]
        set index     [expr [lsearch $lines $startline] + 1]
        set startline [lindex [split [delete_fold $txt [lindex $lines $index]] .] 0]
      }

    }

  }

  ######################################################################
  # Deletes all fold markers.  This operation is only valid in manual
  # mode.
  proc delete_all_folds {txt} {

    variable method

    if {$method($txt) eq "manual"} {

      # Remove all folded text
      $txt tag remove _folded 1.0 end

      # Clear all of fold indicators in the gutter
      $txt gutter clear folding 1 [lindex [split [$txt index end] .] 0]

    }

  }

  ######################################################################
  # Closes a fold, hiding the contents.
  proc close_fold {depth txt line} {

    array set map {
      open   close
      close  close
      eopen  eclose
      eclose eclose
    }

    # Get the fold range
    lassign [get_fold_range $txt $line [expr ($depth == 0) ? 100000 : $depth]] startpos endpos belows

    # Hide the text
    $txt tag add _folded $startpos $endpos

    # Replace the open/eopen symbol with the close/eclose symbol
    foreach line $belows {
      set type [$txt gutter get folding $line]
      $txt gutter clear folding $line
      $txt gutter set folding $map($type) $line
    }

    return $endpos

  }

  ######################################################################
  # Close all folds in the given range.
  proc close_folds_in_range {txt startline endline depth} {

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

    array set inc [list end -1 open 1 close 1 eopen 0 eclose 0]

    # Get ordered gutter list
    set ranges [list]
    set count  0
    foreach {tline tag} [concat {*}[get_gutter_info $txt]] {
      if {($count == 0) && (($tag eq "open") || ($tag eq "eopen")} {
        set oline [expr $tline + 1]
      }
      if {[incr count $inc($tag)] == 0} {
        lappend ranges $oline.0 $tline.0
      } elseif {$count < 0} {
        set count 0
      }
    }

    # Adds folds
    $txt tag add _folded {*}$ranges

    # Close the folds
    $txt gutter set folding close  [$txt gutter get folding open]
    $txt gutter set folding eclose [$txt gutter get folding eopen]

  }

  ######################################################################
  # Opens a fold, showing the contents.
  proc open_fold {depth txt line} {

    array set map {
      close  open
      open   open
      eclose eopen
      eopen  eopen
    }

    # Get the fold range
    lassign [get_fold_range $txt $line [expr ($depth == 0) ? 100000 : $depth]] startpos endpos belows aboves closed

    # Remove the folded tag
    $txt tag remove _folded $startpos $endpos

    foreach tline [concat $belows $aboves] {
      set type [$txt gutter get folding $line]
      $txt gutter clear folding $tline
      $txt gutter set folding $map($type) $tline
    }

    # Close all of the previous folds
    if {$depth == 1} {
      foreach tline $closed {
        if {$tline != $line} {
          close_fold 1 $txt $tline
        }
      }
    }

    return $endpos

  }

  ######################################################################
  # Open all folds in the given range.
  proc open_folds_in_range {txt startline endline depth} {

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

    $txt tag remove _folded 1.0 end
    $txt gutter set folding open  [$txt gutter get folding close]
    $txt gutter set folding eopen [$txt gutter get folding eclose]

  }

  ######################################################################
  # Jumps to the next or previous folding.
  proc jump_to {txt dir} {

    # Get a sorted list of open/close tags and locate our current position
    set data [set line [lindex [split [$txt index insert] .] 0]]
    foreach tag [list open close eopen eclose] {
      lappend data {*}[$txt gutter get folding $tag]
    }

    # Find the index of the open/close symbols and set the cursor on the line
    if {[set index [lsearch [set data [lsort -unique -integer -index 0 $data]] $line]] != -1} {
      if {$dir eq "next"} {
        if {[incr index] == [llength $data]} {
          set index 0
        }
      } else {
        if {[incr index -1] < 0} {
          set index [expr [llength $data] - 1]
        }
      }
      ::tk::TextSetCursor $txt [lindex $data $index].0
      [ns vim]::adjust_insert $txt.t
    }

  }

}
