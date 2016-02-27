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
# Name:    indent.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for text bindings to handle proper indentations
######################################################################

namespace eval indent {

  source [file join $::tke_dir lib ns.tcl]

  variable current_indent "IND+"

  array set tabstops     {}
  array set indent_exprs {}
  array set indent_mode_map {
    "OFF"  "OFF"
    "IND"  "IND"
    "IND+" "IND+"
    "0"    "OFF"
    "1"    "IND+"
  }

  trace variable [ns preferences]::prefs(Editor/SpacesPerTab) w [list [ns indent]::handle_spaces_per_tab]
  trace variable [ns preferences]::prefs(Editor/IndentSpaces) w [list [ns indent]::handle_indent_spaces]

  ######################################################################
  # Sets the tabstop value to match the value of Editor/SpacesPerTab and
  # updates all text widgets to match, cleaning up any non-existent windows
  # along the way.
  proc handle_spaces_per_tab {name1 name2 op} {

    variable tabstops

    foreach txtt [array names tabstops] {
      if {[winfo exists $txtt]} {
        set_tabstop $txtt [[ns preferences]::get Editor/SpacesPerTab]
      } else {
        unset tabstops($txtt)
      }
    }

  }

  ######################################################################
  # Sets the shiftwidth value to match the value of Editor/IndentSpaces.
  # Updates all text widgets to match, cleaning up any non-existent
  # windows along the way.
  proc handle_indent_spaces {name1 name2 op} {

    variable shiftwidths

    foreach txtt [array names shiftwidths] {
      if {[winfo exists $txtt]} {
        set_shiftwidth $txtt [[ns preferences]::get Editor/IndentSpaces]
      } else {
        unset shiftwidths($txtt)
      }
    }

  }

  ######################################################################
  # Adds indentation bindings for the given text widget.
  proc add_bindings {txt} {

    # Initialize the tabstop
    set_tabstop    $txt.t [[ns preferences]::get Editor/SpacesPerTab]
    set_shiftwidth $txt.t [[ns preferences]::get Editor/IndentSpaces]

    bind indent$txt <Any-Key> "[ns indent]::check_indent %W insert"
    bind indent$txt <Return>  "[ns indent]::newline %W insert"

    # Add the indentation tag into the bindtags list just after Text
    set text_index [lsearch [bindtags $txt.t] Text]
    bindtags $txt.t [linsert [bindtags $txt.t] [expr $text_index + 1] indent$txt]

  }

  ######################################################################
  # Sets the tabstop value for the given text widget.
  proc set_tabstop {txtt value} {

    variable tabstops

    # Check to make sure that the value is an integer
    if {![string is integer $value]} {
      return -code error "Tabstop value is not an integer"
    }

    # Save the tabstop value
    set tabstops($txtt) $value

    # Set the text widget tabstop value
    $txtt configure -tabs [list [expr $value * [font measure [$txtt cget -font] 0]] left]

  }

  ######################################################################
  # Returns the tabstop value for the given text widget.
  proc get_tabstop {txtt} {

    variable tabstops

    if {[info exists tabstops($txtt)]} {
      return $tabstops($txtt)
    }

    return -code error "Tabstop information for $txtt does not exist"

  }

  ######################################################################
  # Sets the shiftwidth value for the given text widget.
  proc set_shiftwidth {txtt value} {

    variable shiftwidths

    # Check to make sure that the value is an integer
    if {![string is integer $value]} {
      return -code error "Shiftwidth value is not an integer"
    }

    # Save the shiftwidth value
    set shiftwidths($txtt) $value

  }

  ######################################################################
  # Returns the shiftwidth value for the given text widget.
  proc get_shiftwidth {txtt} {

    variable shiftwidths

    if {[info exists shiftwidths($txtt)]} {
      return $shiftwidths($txtt)
    }

    return -code error "Shiftwidth information for $txtt does not exist"

  }

  ######################################################################
  # Sets the indentation mode for the current text widget.
  proc set_indent_mode {tid mode} {

    variable indent_exprs
    variable indent_mode_map

    # Get the current text widget
    set txt [[ns gui]::current_txt $tid].t

    # Set the current mode
    set indent_exprs($txt,mode) $indent_mode_map($mode)

    # Update the menu button
    [set [ns gui]::widgets(info_indent)] configure -text $mode

    # Set the focus back to the text widget
    catch { [ns gui]::set_txt_focus [[ns gui]::last_txt_focus {}] }

  }

  ######################################################################
  # Returns the value of the indentation mode for the given text widget.
  proc get_indent_mode {txt} {

    variable indent_exprs

    if {![info exists indent_exprs($txt.t,mode)]} {
      return "OFF"
    } else {
      return $indent_exprs($txt.t,mode)
    }

  }

  ######################################################################
  # Returns true if auto-indentation is available; otherwise, returns false.
  proc is_auto_indent_available {txt} {

    variable indent_exprs

    return [expr {$indent_exprs($txt.t,indent) ne ""}]

  }

  ######################################################################
  # Returns true if the reindent symbol is not the first in the parent statement.
  proc check_reindent_for_unindent {txtt index} {

    if {([lassign [$txtt tag prevrange _reindent      $index] rpos] ne "") && \
        ([lassign [$txtt tag prevrange _reindentStart $index] spos] ne "") && \
        [$txtt compare $rpos > $spos]} {

      # Find the indent symbol that is just before the reindentStart symbol
      while {([lassign [$txtt tag prevrange _indent $index] ipos] ne "") && [$txtt compare $ipos > $spos]} {
        set index $ipos
      }

      return [$txtt compare $index < $rpos]

    }

    return 0

  }

  ######################################################################
  # Checks the given text prior to the insertion marker to see if it
  # matches the unindent expressions.  Increment/decrement
  # accordingly.
  proc check_indent {txtt index} {

    variable indent_exprs

    # If the auto-indent feature was disabled, we are in vim start mode, or
    # the current language doesn't have an indent expression, quit now
    if {($indent_exprs($txtt,mode) ne "IND+") || [[ns vim]::in_vim_mode $txtt]} {
      return
    }

    # If the current line contains an unindent expression, is not within a comment or string,
    # and is preceded in the line by only whitespace, replace the whitespace with the proper
    # indentation whitespace.
    if {(([set endpos [lassign [$txtt tag prevrange _unindent $index] startpos]] ne "") && [$txtt compare $endpos == $index]) || \
        (([set endpos [lassign [$txtt tag prevrange _reindent $index] startpos]] ne "") && [$txtt compare $endpos == $index]) && [check_reindent_for_unindent $txtt $startpos]} {
      if {[string trim [set space [$txtt get "$index linestart" $startpos]]] eq ""} {
        $txtt replace "$index linestart" $startpos [string range $space [get_shiftwidth $txtt] end]
      }
    }

  }

  ######################################################################
  # Returns 1 if the given line contains an indentation.
  proc line_contains_indentation {txtt index} {

    # Ignore whitespace
    while {[string trim [$txtt get "$index linestart" "$index lineend"]] eq ""} {
      set index [$txtt index "$index-1l lineend"]
    }

    # Check to see if the current line contains an indentation symbol towards the end of the line
    if {([lassign [$txtt tag prevrange _indent $index] ipos] ne "") && [$txtt compare $ipos >= "$index linestart"]} {
      return [expr {([lassign [$txtt tag prevrange _unindent $index] upos] eq "") || [$txtt compare $ipos > $upos]}]
    }

    # Returns true if we have a reindent symbol in the current line
    return [expr {([lassign [$txtt tag prevrange _reindent $index] ipos] ne "") && [$txtt compare $ipos >= "$index linestart"]}]

  }

  ######################################################################
  # Returns the whitespace found at the beginning of the specified logical
  # line.
  proc get_start_of_line {txtt index} {

    # Ignore whitespace
    while {[string trim [$txtt get "$index linestart" "$index lineend"]] eq ""} {
      set index [$txtt index "$index-1l lineend"]
    }

    # Find an ending bracket on the current line
    set win_type       "none"
    set startpos(none) "$index linestart"
    foreach type [list curlyR parenR squareR angledR] {
      if {([lassign [$txtt tag prevrange _$type $index] startpos($type)] ne "") && \
          [$txtt compare $startpos($type) > "$index linestart"] && \
          [$txtt compare $startpos($type) > $startpos($win_type)]} {
        set win_type $type
      }
    }

    # If we could not find a right bracket, we have found the line that we are looking for
    if {$win_type eq "none"} {
      if {[regexp {^( *)(.*)} [$txtt get "$index linestart" "$index lineend"] -> whitespace rest]} {
        return $whitespace
      } else {
        return ""
      }

    # Otherwise, jump the insertion cursor to the line containing the matching bracket and
    # do the search again.
    } else {
      array set other_type [list curlyR curlyL parenR parenL squareR squareL angledR angledL]
      if {[set match_index [ctext::get_match_bracket [winfo parent $txtt] $other_type($win_type) $startpos($win_type)]] ne ""} {
        return [get_start_of_line $txtt $match_index]
      } elseif {[regexp {^( *)(.*)} [$txtt get "$index linestart" "$index lineend"] -> whitespace rest]} {
        return $whitespace
      } else {
        return ""
      }
    }

  }

  ######################################################################
  # Handles a newline character.  Returns the character position of the
  # first line of non-space text.
  proc newline {txtt index} {

    variable indent_exprs

    # If the auto-indent feature was disabled, we are in vim start mode,
    # or the current language doesn't have an indent expression, quit now
    if {($indent_exprs($txtt,mode) eq "OFF") || [[ns vim]::in_vim_mode $txtt]} {
      return
    }

    # If we do not need smart indentation, use the previous space
    if {$indent_exprs($txtt,mode) eq "IND"} {

      set indent_space [get_previous_indent_space $txtt $index]

    # Otherwise, do smart indentation
    } else {

      # Get the current indentation level
      set indent_space [get_start_of_line $txtt [$txtt index "$index-1l lineend"]]

      # If the previous line indicates an indentation is required,
      if {[line_contains_indentation $txtt "$index-1l lineend"]} {
        append indent_space [string repeat " " [get_shiftwidth $txtt]]
      }

    }

    # Get the current line
    set line [$txtt get $index "$index lineend"]

    # Create an index to restore the insertion cursor, if necessary
    set restore_insert ""

    # Remove any leading whitespace and update indentation level
    # (if the first non-whitespace char is a closing bracket)
    if {[regexp {^( *)(.*)} $line -> whitespace rest] && ($rest ne "")} {

      # If the first non-whitespace characters match an unindent pattern,
      # lessen the indentation by one
      if {[regexp "^$indent_exprs($txtt,unindent)" $rest]} {
        $txtt insert insert "$indent_space\n"
        set restore_insert [$txtt index insert-1c]
        if {$indent_exprs($txtt,mode) eq "IND+"} {
          set indent_space [string range $indent_space [get_shiftwidth $txtt] end]
        }
      }

      # See if we are deleting a multicursor
      set mcursor [lsearch [$txtt tag names $index] "mcursor"]

      # Delete the whitespace
      $txtt delete $index "$index+[string length $whitespace]c"

      # If the newline was from a multicursor, we need to re-add the tag since we have deleted it
      if {$mcursor != -1} {
        $txtt tag add mcursor $index
      }

    }

    # Insert leading whitespace to match current indentation level
    if {$indent_space ne ""} {
      $txtt insert $index $indent_space
    }

    # If we need to restore the insertion cursor, do it now
    if {$restore_insert ne ""} {
      ::tk::TextSetCursor $txtt $restore_insert
    }

  }

  ######################################################################
  # Returns the whitespace of the previous (non-empty) line of text.
  proc get_previous_indent_space {txtt index} {

    variable indent_exprs

    if {($indent_exprs($txtt,mode) eq "OFF") || \
        [[ns vim]::in_vim_mode $txtt] || \
        ([lindex [split $index .] 0] == 1)} {
      return 0
    }

    set line_pos [expr [lindex [split [$txtt index $index] .] 0] - 1]

    # Get the last line that was not a blank line
    while {($line_pos > 0) && ([string trim [set line [$txtt get "$line_pos.0" "$line_pos.end"]]] eq "")} {
      incr line_pos -1
    }

    if {($line_pos > 0) && [regexp {^( *)(.*)} $line -> whitespace rest]} {
      return $whitespace
    } else {
      return ""
    }

  }

  ######################################################################
  # This procedure counts the number of tags in the given range.
  proc get_tag_count {txtt tag start end} {

    variable indent_exprs

    # Initialize the indent_level
    set count 0

    # Count all tags that are not within comments or are escaped
    while {[set range [$txtt tag nextrange _$tag $start $end]] ne ""} {
      lassign $range index start
      if {![ctext::inCommentString $txtt $index]} {
        incr count [expr [regexp -all $indent_exprs($txtt,$tag) [$txtt get $index $start]] - [ctext::isEscaped $txtt $index]]
      }
    }

    return $count

  }

  ######################################################################
  # This procedure is called to get the indentation level of the given
  # index.
  proc get_indent_space {txtt index} {

    # Check to see if the previous line requires an indentation

    # Get the current indentation level
    set indent_count   [get_tag_count $txtt indent   $start $end]
    set reindent_count [get_tag_count $txtt reindent $start $end]
    set unindent_count [get_tag_count $txtt unindent $start $end]

    return [string repeat " " [expr ((($indent_count + $reindent_count) - $unindent_count) + $adjust) * [get_shiftwidth $txtt]]]

  }

  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc format_text {txtt startpos endpos} {

    variable indent_exprs

    # Create a separator
    $txtt edit separator

    # Check to see if there is only whitespace between the beginning of the line and the start position
    if {[string trim [$txtt get "$startpos linestart" $startpos]] eq ""} {
      set curpos [$txtt index "$startpos linestart"]
    } else {
      set curpos [$txtt index "$startpos+1l linestart"]
    }

    set endpos       [$txtt index $endpos]
    set indent_space ""

    while {[$txtt compare $curpos < $endpos]} {

      if {$curpos ne "1.0"} {

        # Get the current indentation level
        set indent_space [get_start_of_line $txtt [$txtt index "$curpos-1l lineend"]]
      
        # If the previous line indicates an indentation is required,
        if {[line_contains_indentation $txtt "$curpos-1l lineend"]} {
          append indent_space [string repeat " " [get_shiftwidth $txtt]]
        }

      }

      # Remove any leading whitespace and update indentation level
      # (if the first non-whitespace char is a closing bracket)
      if {[regexp {^( *)(.*)} [$txtt get $curpos "$curpos lineend"] -> whitespace rest] && ($rest ne "")} {
  
        # If the first non-whitespace characters match an unindent pattern,
        # lessen the indentation by one
        if {[regexp "^$indent_exprs($txtt,unindent)" $rest]} {
          set indent_space [string range $indent_space [get_shiftwidth $txtt] end]
        }
  
      }
  
      # Delete the whitespace
      $txtt replace $curpos "$curpos+[string length $whitespace]c" $indent_space
  
      # Adjust the startpos
      set curpos [$txtt index "$curpos+1l linestart"]
      set ignore 0
      
    }

    # Create a separator
    $txtt edit separator

    # Perform syntax highlighting
    [winfo parent $txtt] highlight $startpos $endpos

  }

  ######################################################################
  # Sets the indentation expressions for the given text widget.
  proc set_indent_expressions {txtt indent unindent reindent} {

    variable indent_exprs

    # Set the indentation expressions
    set indent_exprs($txtt,indent)   [join $indent |]
    set indent_exprs($txtt,unindent) [join $unindent |]
    set indent_exprs($txtt,reindent) [join $reindent |]

    # Set the default indentation mode
    if {[[ns preferences]::get Editor/EnableAutoIndent]} {
      if {$indent ne ""} {
        set indent_exprs($txtt,mode) "IND+"
      } else {
        set indent_exprs($txtt,mode) "IND"
      }
    } else {
      set indent_exprs($txtt,mode) "OFF"
    }

  }

  ######################################################################
  # Repopulates the specified syntax selection menu.
  proc populate_indent_menu {mnu} {

    variable langs

    # Clear the menu
    $mnu delete 0 end

    # Populate the menu with the available languages
    foreach {lbl mode} [list "No Indent" "OFF" "Auto-Indent" "IND" "Smart Indent" "IND+"] {
      $mnu add radiobutton -label $lbl -variable [ns indent]::current_indent \
        -value $mode -command "[ns indent]::set_indent_mode {} $mode"
    }

    return $mnu

  }

  ######################################################################
  # Creates the menubutton to control the indentation mode for the current
  # editor.
  proc create_menu {w} {

    # Create the menubutton menu
    set mnu [menu ${w}Menu -tearoff 0]

    # Populate the indent menu
    populate_indent_menu $mnu

    return $mnu

  }

  ######################################################################
  # Updates the menubutton to match the current mode.
  proc update_button {w} {

    variable indent_exprs
    variable current_indent

    # Get the current text widget
    set txtt [[ns gui]::current_txt {}].t

    # Configure the menubutton
    if {[info exists indent_exprs($txtt,mode)]} {
      $w configure -text [set current_indent $indent_exprs($txtt,mode)]
    }

  }

}
