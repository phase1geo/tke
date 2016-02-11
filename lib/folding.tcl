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

  ######################################################################
  # Adds the bindings necessary for code folding to work.
  proc initialize {txt} {

    # Add the folding gutter
    $txt gutter create folding \
      open  [list -symbol \u25be -onclick [ns folding]::close_fold] \
      close [list -symbol \u25b8 -onclick [ns folding]::open_fold] \
      end   [list -symbol \u221f]

    # Add the fold markers to the gutter
    add_folds $txt 1.0 end

    # Create a tag that will cause stuff to hide
    $txt.t tag configure _folded -elide 1

  }

  ######################################################################
  # Adds any found folds to the gutter
  proc add_folds {txt startpos endpos} {

    array set ids {
      1 open
      2 end
    }

    # Get the starting and ending line
    set startline [lindex [split [$txt index $startpos] .] 0]
    set endline   [lindex [split [$txt index $endpos]   .] 0]

    # Clear the folding gutter in
    $txt gutter clear folding $startline $endline

    # Add the folding indicators
    for {set i $startline} {$i <= $endline} {incr i} {
      if {[info exists ids([set fold [check_fold $txt $i]])]} {
        $txt gutter set folding $ids($fold) $i
      }
    }

  }

  ######################################################################
  # Returns true if a fold point has been detected at the given index.
  proc check_fold {txt line} {

    set indent_cnt   [[ns indent]::get_tag_count $txt.t indent   $line.0 $line.end]
    set unindent_cnt [[ns indent]::get_tag_count $txt.t unindent $line.0 $line.end]

    return [expr ($indent_cnt > $unindent_cnt) ? 1 : ($indent_cnt < $unindent_cnt) ? 2 : 0]

  }

  ######################################################################
  # Returns the starting and ending positions of the range to fold.
  proc get_fold_range {txt line} {

    array set inc [list end -1 open 1 close 1]

    foreach tag [list open close end] {
      foreach tline [$txt gutter get folding $tag] {
        lappend data [list $tline $tag]
      }
    }

    set index [expr [lsearch -index 0 [set data [lsort -integer -index 0 $data]] $line] + 1]
    set count 1

    foreach {tline tag} [concat {*}[lrange $data $index end]] {
      if {[incr count $inc($tag)] == 0} {
        return [list [expr $line + 1].0 $tline.0]
      }
    }

    return [list [expr $line + 1].0 [lindex [split [$txt index end] .] 0].0]

  }

  ######################################################################
  # Closes a fold, hiding the contents.
  proc close_fold {txt line} {

    # Get the fold range
    lassign [get_fold_range $txt $line] startpos endpos

    # Hide the text
    $txt.t tag add _folded $startpos $endpos

    # Replace the open symbol with the close symbol
    $txt gutter clear folding $line
    $txt gutter set folding close $line

    # Clear the selection
    $txt tag remove sel 1.0 end

  }

  ######################################################################
  # Closes all open folds.
  proc close_all_folds {txt} {

    foreach line [$txt gutter get folding open] {
      close_fold $txt $line
    }

  }

  ######################################################################
  # Opens a fold, showing the contents.
  proc open_fold {txt line} {

    set index [expr [lsearch [set closed [$txt gutter get folding close]] $line] + 1]

    # Get the tag range
    lassign [$txt tag nextrange _folded $line.0] startpos endpos

    # Remove the folded tag
    $txt tag remove _folded $startpos $endpos

    # Close all of the previous folds
    foreach tline [lrange $closed $index end] {
      if {[$txt compare $tline.0 < $endpos]} {
        close_fold $txt $tline
      }
    }

    # Replace the close symbol with the open symbol
    $txt gutter clear folding $line
    $txt gutter set folding open $line

    # Clear the selection
    $txt tag remove sel 1.0 end

  }

  ######################################################################
  # Opens all closed folds.
  proc open_all_folds {txt} {

    # Remove all folded text
    $txt tag remove _folded 1.0 end

    foreach line [$txt gutter get folding close] {
      $txt gutter clear folding $line
      $txt gutter set folding open $line
    }

  }

}
