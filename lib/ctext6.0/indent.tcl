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
# Name:    indent.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for text bindings to handle proper indentations
######################################################################

namespace eval indent {

  ######################################################################
  # Checks the given text prior to the insertion marker to see if it
  # matches the unindent expressions.  Increment/decrement
  # accordingly.
  proc check_unindent {win index indent_mode} {

    # If the auto-indent feature was disabled, we are in vim start mode, or
    # the current language doesn't have an indent expression, quit now
    if {$indent_mode ne "IND+"} {
      return
    }

    # Get the whitespace at the beginning of the current line
    if {[set endpos [lassign [$win._t tag nextrange _prewhite "$index linestart"] startpos]] ne ""} {

      # Get the unindent information from the model
      if {[set data [[model::indent_check_unindent $win $endpos $index]]] ne ""} {

        lassign $data data_index data_less

        # Get the whitespace at the beginning of the logical line
        set indent_space [string range [get_start_of_line $win $data_index] [expr [$win cget -shiftwidth] * $data_less] end]

        # If required, replace the starting whitespace with the updated whitespace
        if {$indent_space ne [$win._t get $startpos $endpos]} {
          $win replace -highlight 0 $startpos $endpos $indent_space
        }

      }

    }

  }

  ######################################################################
  # Get the matching indentation marker.
  proc get_match_indent {win index} {

    if {[set indent [ctext::model::get_match_char $win $index]] ne ""} {
      return [lindex $indent 0]
    }

    return ""

  }

  ######################################################################
  # Returns the whitespace found at the beginning of the specified logical
  # line.
  proc get_start_of_line {win index} {

    # Ignore whitespace
    if {[lsearch [$win._t tag names "$index linestart"] _prewhite] == -1} {
      if {[set range [$win._t tag prevrange _prewhite "$index lineend"]] ne ""} {
        set index [$win._t index "[lindex $range 1] lineend"]
      } else {
        set index 1.0
      }
    }

    # Get the starting line number from the text model
    set index [ctext::model::indent_line_start $win $index].0

    if {[lsearch [$win._t tag names $index] _prewhite] != -1} {
      return [expr [string length [$win._t get {*}[$win._t tag nextrange _prewhite $index]]] - 1]
    } else {
      return 0
    }

  }

  ######################################################################
  # Handles a newline character.  Returns the character position of the
  # first line of non-space text.
  proc newline {win index indent_mode} {

    # If the auto-indent feature was disable, quit now
    # or the current language doesn't have an indent expression, quit now
    if {$indent_mode eq "OFF"} {
      if {[$win cget -autoseparators]} {
        $win edit separator
      }
      return
    }

    # If we do not need smart indentation, use the previous space
    if {$indent_mode eq "IND"} {
      set insert_space [get_previous_indent_space $win $index]
    } else {
      if {[lassign [$win._t tag nextrange _prewhite $index "$index lineend"] first_index] eq ""} {
        set first_index [$win._t index "$index linestart"]
      }
      set insert_space [get_start_of_line $win [$win._t index "$index-1l lineend"]]
      set insert_space [model::line_newline $win $first_index $insert_space [$win cget -shiftwidth]]
    }

    if {$insert_space == 0} {
      return
    }

    if {$indent_space < 0} {
      $win delete -highlight 0 $index "$index+${insert_space}c"
    } else {
      $win insert -highlight 0 $index [string repeat " " $insert_space]
    }

    # If autoseparators are called for, add it now
    if {[$win cget -autoseparators]} {
      $win edit separator
    }

  }

  ######################################################################
  # Called whenever we delete whitespace such that all characters between
  # the beginning of the line and the given index are entirely whitespace.
  proc backspace {win index} {

    # If the auto-indent feature was disabled, return immediately
    if {[$win cget -indentmode] eq "OFF"} {
      return
    }

    # Figure out the leading space
    set space ""
    if {[set endpos [lassign [$win._t tag prevrange _prewhite $index "$index linestart"] startpos]] ne ""} {
      if {[$win._t compare $endpos == "$index+1c"]} {
        set space [$win._t get $startpos $index]
      } else {
        return $index
      }
    } else {
      set space [$win._t get "$index linestart" "$index lineend"]
    }

    # If the leading whitespace only consists of spaces, attempt to delete to the previous tab
    if {([string trim $space] eq "")} {

      # Calculate the new indentation
      set shiftwidth   [$win cget -shiftwidth]
      set space_len    [string length $space]
      set tab_count    [expr $space_len / $shiftwidth]
      set remove_chars [expr $space_len - ($tab_count * $shiftwidth)]

      # Replace the whitespace with the appropriate amount of indentation space
      if {$remove_chars > 0} {
        $win delete -highlight 0 "$index-${remove_chars}c" $index
      }

    }

  }

  ######################################################################
  # Returns the whitespace of the previous (non-empty) line of text.
  proc get_previous_indent_space {win index} {

    if {[lindex [split $index .] 0] != 1) && ([set range [$win._t tag prevrange _prewhite "$index-1l lineend"]] ne "")} {
      return [expr [string length [$win._t get {*}$range]] - 1]
    } else {
      return 0
    }

  }

  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  #
  # TBD
  proc format_text {win startpos endpos {add_separator 1}} {

    # Create a separator
    if {$add_separator} {
      $win edit separator
    }

    # If we are the first line containing non-whitespace, preserve the indentation
    if {([$win._t tag prevrange _prewhite "$startpos linestart"] eq "") || \
        ([string trim [$win._t get "$startpos linestart" $startpos]] ne "")} {
      set curpos [$win._t index "$startpos+1l linestart"]
    } else {
      set curpos [$win._t index "$startpos linestart"]
    }

    set endpos       [$win._t index $endpos]
    set indent_space ""
    set shiftwidth   [$win cget -shiftwidth]

    while {[$win._t compare $curpos < $endpos]} {

      if {$curpos ne "1.0"} {

        # If the current line contains an unindent expression, is not within a comment or string,
        # and is preceded in the line by only whitespace, replace the whitespace with the proper
        # indentation whitespace.
        if {[set epos [lassign [$win._t tag nextrange _unindent $curpos "$curpos lineend"] spos]] ne ""} {
          if {[set tindex [get_match_indent $win $spos]] ne ""} {
            if {[$win._t compare "$tindex linestart" == "$spos linestart"]} {
              set indent_space [get_start_of_line $win "$tindex-1l lineend"]
              if {[MODEL::line_contains_indentation $win "$tindex-1l lineend"]} {
                append indent_space [string repeat " " $shiftwidth]
              }
            } else {
              set indent_space [get_start_of_line $win $tindex]
            }
          } else {
            set indent_space [get_start_of_line $win $epos]
          }

        } elseif {([set epos [lassign [$win._t tag nextrange _reindent $curpos "$curpos lineend"] spos]] ne "") && [MODEL::is_unindent_after_reindent $win $spos]} {
          set indent_space [get_start_of_line $win [$win._t index "$curpos-1l lineend"]]
          if {[string trim [$win._t get "$curpos linestart" $spos]] eq ""} {
            if {[$win._t compare "$curpos-1l linestart" > [lindex [$win._t tag prevrange _reindent "$curpos linestart"] 1]]} {
              set indent_space [string range $indent_space $shiftwidth end]
            }
          }

        } else {
          set indent_space [get_start_of_line $win [$win._t index "$curpos-1l lineend"]]
          if {[MODEL::line_contains_indentation $win "$curpos-1l lineend"]} {
            append indent_space [string repeat " " $shiftwidth]
          }
        }

      }

      # Remove any leading whitespace and update indentation level
      # (if the first non-whitespace char is a closing bracket)
      set whitespace ""
      if {[lsearch [$win._t tag names $curpos] _prewhite] != -1} {
        set whitespace [string range [$win._t get {*}[$win._t tag nextrange _prewhite $curpos]] 0 end-1]
      }

      # Replace the leading whitespace with the calculated amount of indentation space
      if {$whitespace ne $indent_space} {
        $win replace -highlight 0 $curpos "$curpos+[string length $whitespace]c" $indent_space
      }

      # Adjust the startpos
      set curpos [$win._t index "$curpos+1l linestart"]

    }

    # Create a separator
    $win edit separator

    # Perform syntax highlighting
    $win highlight $startpos $endpos

  }

}

