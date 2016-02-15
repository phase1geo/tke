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
  # Returns true if
  proc check_reindent_for_unindent {txtt index} {

    puts "In check_reindent_for_unindent, txtt: $txtt, index: $index"

    return [expr {[$txtt tag names $index] ne "_reindent"}]

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

    puts "In check_indent, txtt: $txtt, index: [$txtt index $index]"

    # If the current line contains an unindent expression, is not within a comment or string,
    # and is preceded in the line by only whitespace, replace the whitespace with the proper
    # indentation whitespace.
    if {[set uindex [$txtt search -regexp -- "$indent_exprs($txtt,unindent)\$" "$index linestart" $index]] ne ""} {
      if {![ctext::inCommentString $txtt $uindex]} {
        set line [$txtt get "$index linestart" $uindex]
        if {($line ne "") && ([string trim $line] eq "")} {
          $txtt replace "$index linestart" $uindex [get_indent_space $txtt 1.0 $index]
        }
      }
    } elseif {[set uindex [$txtt search -regexp -- {case$} "$index linestart" $index]] ne ""} {
      if {![ctext::inCommentString $txtt $uindex] && [check_reindent_for_unindent $txtt $uindex]} {
        set line [$txtt get "$index linestart" $uindex]
        if {($line ne "") && ([string trim $line] eq "")} {
          $txtt replace "$index linestart" $uindex [get_indent_space $txtt 1.0 $index -1]
        }
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

    # Get the previous space
    set prev_space [get_previous_indent_space $txtt $index]

    # If we do not need smart indentation, use the previous space
    if {$indent_exprs($txtt,mode) eq "IND"} {

      set indent_space $prev_space

    # Otherwise, do smart indentation
    } else {

      # Get the current indentation level
      set indent_space [get_indent_space $txtt 1.0 $index]

      # Check to see if the previous space is greater than the indent space (if so use it instead)
      if {[string length $prev_space] > [string length $indent_space]} {
        set indent_space $prev_space
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
  # Returns the indentation (in number of spaces) of the previous line
  # of text.
  proc get_previous_indent_space {txtt index} {

    variable indent_exprs

    if {($indent_exprs($txtt,mode) eq "OFF") || \
        [[ns vim]::in_vim_mode $txtt] || \
        ([lindex [split $index .] 0] == 1)} {
      return 0
    }

    set line_pos [expr [lindex [split [$txtt index $index] .] 0] - 1]

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

    puts "In get_tag_count, tag: $tag"

    # Initialize the indent_level
    set count 0

    # Count all tags that are not within comments or are escaped
    while {[set range [$txtt tag nextrange _$tag $start $end]] ne ""} {
      lassign $range index start
      puts "HERE, range: $range, expr: $indent_exprs($txtt,$tag), isEscaped: [ctext::isEscaped $txtt $index]"
      if {![ctext::inCommentString $txtt $index]} {
        puts [$txtt get $index $start]
        incr count [expr [regexp -all $indent_exprs($txtt,$tag) [$txtt get $index $start]] - [ctext::isEscaped $txtt $index]] }
    }

    return $count

  }

  ######################################################################
  # This procedure is called to get the indentation level of the given
  # index.
  proc get_indent_space {txtt start end {adjust 0}} {

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

    # If the current language doesn't have indentation enabled, quit now
    if {$indent_exprs($txtt,mode) eq "OFF"} {
      return
    }

    # Get the current position and recalculate the endpos
    set currpos [$txtt index "$startpos linestart"]
    set endpos  [$txtt index $endpos]

    # Update the indentation level at the start of the first text line
    if {[$txtt compare $startpos == 1.0]} {
      set indent_space ""
    } else {
      set indent_space [get_indent_space $txtt 1.0 "$startpos-1l lineend"]
    }

    # Create the regular expression containing the indent and unindent words
    set uni_re $indent_exprs($txtt,unindent)

    # Find the last open brace starting from the current insertion point
    while {[$txtt compare $currpos < $endpos]} {

      # Get the current line
      set line [$txtt get $currpos "$currpos lineend"]

      # Remove the leading whitespace and modify it to match the current indentation level
      if {[regexp {^(\s*)(.*)} $line -> whitespace rest]} {
        if {[string length $whitespace] > 0} {
          $txtt delete $currpos "$currpos+[string length $whitespace]c"
        }
        if {[regexp "^(\\\\)*($uni_re)" $rest -> escapes unindent_match] && \
            ![expr [string length $escapes] % 2]} {
          set unindent [get_shiftwidth $txtt]
        } else {
          set unindent_match ""
          set unindent       0
        }
        if {$indent_space ne ""} {
          $txtt insert $currpos [set indent_space [string range $indent_space $unindent end]]
        }
        append indent_space [get_indent_space $txtt "$currpos+[expr [string length $unindent_match] + [string length $indent_space]]c" "$currpos lineend"]
      } else {
        append indent_space [get_indent_space $txtt $currpos "$currpos lineend"]
      }

      # Increment the starting position to the next line
      set currpos [$txtt index "$currpos+1l linestart"]

    }

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
