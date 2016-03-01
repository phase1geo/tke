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
  # Returns true if the given text widget has code folding enabled.
  proc enabled {txt} {

    return [expr [lsearch [$txt gutter names] folding] != -1]

  }

  ######################################################################
  # Returns true if the given position contains a fold point.
  proc is_fold {txt line} {

    return [expr {[$txt gutter get folding $line] ne ""}]

  }

  ######################################################################
  # Adds the bindings necessary for code folding to work.
  proc initialize {txt} {

    if {[[ns preferences]::get View/EnableCodeFolding]} {
      enable_folding $txt
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
  proc get_fold_range {txt line} {

    array set inc [list end -1 open 1 close 1]

    set index [lsearch -index 0 [set data [get_gutter_info $txt]] $line]
    set count 0

    foreach {tline tag} [concat {*}[lrange $data $index end]] {
      if {[incr count $inc($tag)] == 0} {
        return [list [expr $line + 1].0 $tline.0]
      } elseif {$count < 0} {
        set count 0
      }
    }

    return [list [expr $line + 1].0 [lindex [split [$txt index end] .] 0].0]

  }

  ######################################################################
  # Toggles the fold for the given line.
  proc toggle_fold {txt line} {

    switch [$txt gutter get folding $line] {
      open  { close_fold $txt $line }
      close { open_fold $txt $line }
    }

  }

  ######################################################################
  # Close the selected text.
  proc close_selected {txt} {

    set retval 0

    foreach {startpos endpos} [$txt tag ranges sel] {
      $txt tag add _folded "$startpos+1l linestart" "$endpos+1l linestart"
      $txt gutter set folding close [lindex [split [$txt index $startpos] .] 0]
      set retval 1
    }

    # Clear the selection
    $txt tag remove sel 1.0 end

    return $retval

  }

  ######################################################################
  # Closes a fold, hiding the contents.
  proc close_fold {txt line} {

    # Get the fold range
    lassign [get_fold_range $txt $line] startpos endpos

    # Hide the text
    $txt tag add _folded $startpos $endpos

    # Replace the open symbol with the close symbol
    $txt gutter clear folding $line
    $txt gutter set folding close $line

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
        incr oindex
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

  }

  ######################################################################
  # Opens all closed folds.
  proc open_all_folds {txt} {

    # Remove all folded text
    $txt tag remove _folded 1.0 end

    # Change all of the closed folds to open folds
    $txt gutter set folding open [$txt gutter get folding close]

  }

  ######################################################################
  # Jumps to the next or previous folding.
  proc jump_to {txt dir} {

    if {[lassign [$txt tag ${dir}range _folded [expr {($dir eq "next") ? "insert+1 display l" : "insert"}]] index] ne ""} {
      ::tk::TextSetCursor $txt "$index-1l linestart"
      [ns vim]::adjust_insert $txt.t
    }

  }

}
