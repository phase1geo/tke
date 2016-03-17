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

    switch $method($txt),$new_method {
      none,manual {
        enable_folding $txt
      }
      none,syntax {
        enable_folding $txt
        add_folds $txt 1.0 end
      }
      manual,none {
        disable_folding $txt
      }
      manual,syntax {
        $txt tag remove _folded 1.0 end
        add_folds $txt 1.0 end
      }
      indent,none {
        disable_folding $txt
      }
      indent,manual {
        $txt tag remove _folded 1.0 end
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
      open  [list -symbol \u25be -onclick [list [ns folding]::close_fold 1] -onshiftclick [list [ns folding]::close_fold 0]] \
      close [list -symbol \u25b8 -onclick [list [ns folding]::open_fold  1] -onshiftclick [list [ns folding]::open_fold  0]] \
      end   [list -symbol \u221f]

    # Create a tag that will cause stuff to hide
    $txt.t tag configure _folded -elide 1

  }

  ######################################################################
  # Adds any found folds to the gutter
  proc add_folds {txt startpos endpos} {

    # Get the starting and ending line
    set startline   [lindex [split [$txt index $startpos] .] 0]
    set endline     [lindex [split [$txt index $endpos]   .] 0]
    set lines(open) [list]
    set lines(end)  [list]

    # Clear the folding gutter in
    $txt gutter clear folding $startline $endline

    # Add the folding indicators
    for {set i $startline} {$i <= $endline} {incr i} {
      lappend lines([check_fold $txt $i]) $i
    }

    $txt gutter set folding open $lines(open) end $lines(end)

  }

  ######################################################################
  # Returns true if a fold point has been detected at the given index.
  proc check_fold {txt line} {

    set indent_cnt   [[ns indent]::get_tag_count $txt.t indent   $line.0 $line.end]
    set unindent_cnt [[ns indent]::get_tag_count $txt.t unindent $line.0 $line.end]

    return [expr {($indent_cnt > $unindent_cnt) ? "open" : ($indent_cnt < $unindent_cnt) ? "end" : ""}]

  }

  ######################################################################
  # Returns the gutter information in sorted order.
  proc get_gutter_info {txt} {

    set data [list]

    foreach tag [list open close end] {
      foreach tline [$txt gutter get folding $tag] {
        lappend data [list $tline $tag]
      }
    }

    return [lsort -integer -index 0 $data]

  }

  ######################################################################
  # Returns the starting and ending positions of the range to fold.
  proc get_fold_range {txt line depth} {

    array set inc [list end -1 open 1 close 1]

    set index  [lsearch -index 0 [set data [get_gutter_info $txt]] $line]
    set count  0
    set aboves [list]
    set belows [list]
    set closed [list]

    foreach {tline tag} [concat {*}[lrange $data $index end]] {
      if {$tag ne "end"} {
        if {$count < $depth} {
          lappend belows $tline
        } else {
          lappend aboves $tline
        }
        if {$tag eq "close"} {
          lappend closed $tline
        }
      }
      if {[incr count $inc($tag)] == 0} {
        return [list [expr $line + 1].0 $tline.0 $belows $aboves $closed]
      } elseif {$count < 0} {
        set count 0
      }
    }

    return [list [expr $line + 1].0 [lindex [split [$txt index end] .] 0].0 $belows $aboves $closed]

  }

  ######################################################################
  # Toggles the fold for the given line.
  proc toggle_fold {txt line {depth 1}} {

    switch [$txt gutter get folding $line] {
      open  { close_fold $depth $txt $line }
      close { open_fold  $depth $txt $line }
    }

  }

  ######################################################################
  # Close the selected text.
  proc close_selected {txt} {

    variable method

    set retval 0

    if {$method($txt) eq "manual"} {

      foreach {startpos endpos} [$txt tag ranges sel] {
        $txt tag add _folded "$startpos+1l linestart" "$endpos+1l linestart"
        $txt gutter set folding close [lindex [split [$txt index $startpos] .] 0]
        $txt gutter set folding end   [expr [lindex [split [$txt index $endpos] .] 0] + 1]
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
  proc delete_fold {txt} {

    variable method

    if {$method($txt) eq "manual"} {

      # Get the current line and state
      set line  [lindex [split [$txt index insert] .] 0]
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
      }

    }

  }

  ######################################################################
  # Closes a fold, hiding the contents.
  proc close_fold {depth txt line} {

    # Get the fold range
    lassign [get_fold_range $txt $line [expr ($depth == 0) ? 100000 : $depth]] startpos endpos belows

    # Hide the text
    $txt tag add _folded $startpos $endpos

    # Replace the open symbol with the close symbol
    foreach line $belows {
      $txt gutter clear folding $line
      $txt gutter set folding close $line
    }

  }

  ######################################################################
  # Closes all open folds.
  proc close_all_folds {txt} {

    array set inc [list end -1 open 1 close 1]

    # Get ordered gutter list
    set ranges [list]
    set count  0
    foreach {tline tag} [concat {*}[get_gutter_info $txt]] {
      if {($count == 0) && ($tag eq "open")} {
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
    $txt gutter set folding close [$txt gutter get folding open]

  }

  ######################################################################
  # Opens a fold, showing the contents.
  proc open_fold {depth txt line} {

    variable method

    # Get the fold range
    lassign [get_fold_range $txt $line [expr ($depth == 0) ? 100000 : $depth]] startpos endpos belows aboves closed

    # Remove the folded tag
    $txt tag remove _folded $startpos $endpos

    foreach tline [concat $belows $aboves] {
      $txt gutter clear folding $tline
      $txt gutter set folding open $tline
    }

    # Close all of the previous folds
    if {$depth == 1} {
      foreach tline $closed {
        if {$tline != $line} {
          close_fold 1 $txt $tline
        }
      }
    }

  }

  ######################################################################
  # Opens all closed folds.
  proc open_all_folds {txt} {

    variable method

    $txt tag remove _folded 1.0 end
    $txt gutter set folding open [$txt gutter get folding close]

  }

  ######################################################################
  # Jumps to the next or previous folding.
  proc jump_to {txt dir} {

    # Get a sorted list of open/close tags and locate our current position
    set data [set line [lindex [split [$txt index insert] .] 0]]
    foreach tag [list open close] {
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
