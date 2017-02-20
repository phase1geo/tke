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

  trace variable preferences::prefs(Editor/SpacesPerTab) w [list indent::handle_spaces_per_tab]
  trace variable preferences::prefs(Editor/IndentSpaces) w [list indent::handle_indent_spaces]

  ######################################################################
  # Sets the tabstop value to match the value of Editor/SpacesPerTab and
  # updates all text widgets to match, cleaning up any non-existent windows
  # along the way.
  proc handle_spaces_per_tab {name1 name2 op} {

    variable tabstops

    foreach txtt [array names tabstops] {
      if {[winfo exists $txtt]} {
        set_tabstop $txtt [preferences::get Editor/SpacesPerTab]
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
        set_shiftwidth $txtt [preferences::get Editor/IndentSpaces]
      } else {
        unset shiftwidths($txtt)
      }
    }

  }

  ######################################################################
  # Adds indentation bindings for the given text widget.
  proc add_bindings {txt} {

    # Initialize the tabstop
    set_tabstop    $txt.t [preferences::get Editor/SpacesPerTab]
    set_shiftwidth $txt.t [preferences::get Editor/IndentSpaces]

    bind indent$txt <Any-Key>   { indent::check_indent %W insert 1 }
    bind indent$txt <Return>    { indent::newline      %W insert 1 }
    bind indent$txt <BackSpace> { indent::backspace    %W insert 1 }

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
  proc set_indent_mode {mode} {

    variable indent_exprs
    variable indent_mode_map

    # Get the current text widget
    set txt [gui::current_txt]

    # Set the current mode
    set indent_exprs($txt.t,mode) $indent_mode_map($mode)

    # Set the text widget's indent mode
    folding::add_folds $txt 1.0 end

    # Update the menu button
    $gui::widgets(info_indent) configure -text $mode

    # Set the focus back to the text widget
    catch { gui::set_txt_focus [gui::last_txt_focus] }

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
  proc check_indent {txtt index do_update} {

    variable indent_exprs

    # If the auto-indent feature was disabled, we are in vim start mode, or
    # the current language doesn't have an indent expression, quit now
    if {($indent_exprs($txtt,mode) ne "IND+") || [vim::in_vim_mode $txtt]} {
      return $index
    }

    # If the current line contains an unindent expression, is not within a comment or string,
    # and is preceded in the line by only whitespace, replace the whitespace with the proper
    # indentation whitespace.
    if {([set endpos [lassign [$txtt tag prevrange _unindent $index] startpos]] ne "") && [$txtt compare $endpos >= $index]} {

      if {[string trim [set space [$txtt get "$index linestart" $startpos]]] eq ""} {

        # Find the matching indentation index
        if {[set tindex [get_match_indent $txtt $startpos]] ne ""} {
          set indent_space [get_start_of_line $txtt $tindex]
        } else {
          set indent_space [get_start_of_line $txtt $index]
        }

        # Replace the whitespace with the appropriate amount of indentation space
        if {$indent_space ne $space} {
          $txtt fastreplace -update $do_update "$index linestart" $startpos $indent_space
          set offset [expr [lindex [split $index .] 1] + ([string length $indent_space] - [lindex [split $startpos .] 1])]
          return [$txtt index "$index linestart+${offset}c"]
        }

      }

    } elseif {(([set endpos [lassign [$txtt tag prevrange _reindent $index] startpos]] ne "") && [$txtt compare $endpos == $index]) && [check_reindent_for_unindent $txtt $startpos]} {

      if {[string trim [set space [$txtt get "$index linestart" $startpos]]] eq ""} {

        # Get the starting whitespace of the previous line
        set indent_space [get_start_of_line $txtt [$txtt index "$index-1l lineend"]]

        # Check to see if the previous line contained a reindent
        if {[$txtt compare "$index-1l linestart" > [lindex [$txtt tag prevrange _reindent "$index linestart"] 0]]} {
          set indent_space [string range $indent_space [get_shiftwidth $txtt] end]
        }

        # Replace the whitespace with the appropriate amount of indentation space
        if {$indent_space ne $space} {
          $txtt fastreplace -update $do_update "$index linestart" $startpos $indent_space
          set offset [expr [lindex [split $index .] 1] + ([string length $indent_space] - [lindex [split $startpos .] 1])]
          return [$txtt index "$index linestart+${offset}c"]
        }

      }

    }

    return $index

  }

  ######################################################################
  # Returns 1 if the given line contains an indentation.
  proc line_contains_indentation {txtt index} {

    # Ignore whitespace
    if {[lsearch [$txtt tag names "$index linestart"] _prewhite] == -1} {
      if {[set range [$txtt tag prevrange _prewhite "$index lineend"]] ne ""} {
        set index [$txtt index "[lindex $range 1] lineend"]
      } else {
        set index 1.0
      }
    }

    # Check to see if the current line contains an indentation symbol towards the end of the line
    if {[lassign [$txtt tag prevrange _indent $index "$index linestart"] ipos] ne ""} {
      return [expr {([lassign [$txtt tag prevrange _unindent $index] upos] eq "") || [$txtt compare $ipos > $upos]}]
    }

    # Returns true if we have a reindent symbol in the current line
    return [expr {[lassign [$txtt tag prevrange _reindent $index "$index linestart"] ipos] ne ""}]

  }

  ######################################################################
  # Get the matching indentation marker.
  proc get_match_indent {txtt index} {

    set count 1

    lassign [$txtt tag prevrange _indent   $index] sfirst slast
    lassign [$txtt tag prevrange _unindent $index] ofirst olast

    if {($olast ne "") && [$txtt compare $olast >= $index]} {
      set olast $index
    }

    while {($ofirst ne "") && ($sfirst ne "")} {
      if {[$txtt compare $sfirst > $ofirst]} {
        if {[incr count -1] == 0} {
          return $sfirst
        }
        lassign [$txtt tag prevrange _indent $sfirst] sfirst slast
      } else {
        incr count
        lassign [$txtt tag prevrange _unindent $ofirst] ofirst olast
      }
    }

    while {$sfirst ne ""} {
      if {[incr count -1] == 0} {
        return $sfirst
      }
      lassign [$txtt tag prevrange _indent $sfirst] sfirst slast
    }

    return ""

  }

  ######################################################################
  # Returns the whitespace found at the beginning of the specified logical
  # line.
  proc get_start_of_line {txtt index} {

    # Ignore whitespace
    if {[lsearch [$txtt tag names "$index linestart"] _prewhite] == -1} {
      if {[set range [$txtt tag prevrange _prewhite "$index lineend"]] ne ""} {
        set index [$txtt index "[lindex $range 1] lineend"]
      } else {
        set index 1.0
      }
    }

    # Find an ending bracket on the current line
    set win_type       "none"
    set startpos(none) "$index linestart"
    foreach type [list curlyR parenR squareR angledR] {
      if {([lassign [$txtt tag prevrange _$type $index] startpos($type)] ne "") && \
          [$txtt compare $startpos($type) >= "$index linestart"] && \
          [$txtt compare $startpos($type) >= $startpos($win_type)]} {
        set win_type $type
      }
    }

    # If we could not find a right bracket, we have found the line that we are looking for
    if {$win_type eq "none"} {
      if {[lsearch [$txtt tag names "$index linestart"] _prewhite] != -1} {
        return [string range [$txtt get {*}[$txtt tag nextrange _prewhite "$index linestart"]] 0 end-1]
      } else {
        return ""
      }

    # Otherwise, jump the insertion cursor to the line containing the matching bracket and
    # do the search again.
    } else {
      array set other_type [list curlyR curlyL parenR parenL squareR squareL angledR angledL]
      if {[set match_index [ctext::get_match_bracket [winfo parent $txtt] $other_type($win_type) $startpos($win_type)]] ne ""} {
        return [get_start_of_line $txtt $match_index]
      } elseif {[lsearch [$txtt tag names "$index linestart"] _prewhite] != -1} {
        return [string range [$txtt get {*}[$txtt tag nextrange _prewhite "$index linestart"]] 0 end-1]
      } else {
        return ""
      }
    }

  }

  ######################################################################
  # Handles a newline character.  Returns the character position of the
  # first line of non-space text.
  proc newline {txtt index do_update} {

    variable indent_exprs

    # If the auto-indent feature was disabled, we are in vim start mode,
    # or the current language doesn't have an indent expression, quit now
    if {($indent_exprs($txtt,mode) eq "OFF") || [vim::in_vim_mode $txtt]} {
      return $index
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

    # Create an index to restore the insertion cursor, if necessary
    set restore_insert ""

    # Remove any leading whitespace and update indentation level
    # (if the first non-whitespace char is a closing bracket)
    if {[lsearch [$txtt tag names "$index linestart"] _prewhite] != -1} {

      lassign [$txtt tag nextrange _prewhite "$index linestart"] startpos endpos

      # If the first non-whitespace characters match an unindent pattern,
      # lessen the indentation by one
      if {[lsearch [$txtt tag names "$endpos-1c"] _unindent*] != -1} {
        $txtt fastinsert -update 0 insert "$indent_space\n"
        set startpos [$txtt index $startpos+1l]
        set endpos   [$txtt index $endpos+1l]
        set restore_insert [$txtt index insert-1c]
        if {$indent_exprs($txtt,mode) eq "IND+"} {
          set indent_space [string range $indent_space [get_shiftwidth $txtt] end]
        }

      # Otherwise, if the first non-whitepace characters match a reindent pattern, lessen the
      # indentation by one
      } elseif {([lsearch [$txtt tag names "$endpos-1c"] _reindent*] != -1) && [check_reindent_for_unindent $txtt [lindex [$txtt tag prevrange _reindent $endpos] 0]]} {
        # $txtt insert insert "$indent_space\n"
        # set restore_insert [$txtt index insert-1c]
        if {$indent_exprs($txtt,mode) eq "IND+"} {
          set indent_space [string range $indent_space [get_shiftwidth $txtt] end]
        }
      }

      # See if we are deleting a multicursor
      set mcursor [lsearch [$txtt tag names $index] "mcursor"]

      # Delete the whitespace
      $txtt fastdelete -update [expr {($do_update && ($indent_space eq "")) ? 1 : 0}] $startpos "$endpos-1c"

      # If the newline was from a multicursor, we need to re-add the tag since we have deleted it
      if {$mcursor != -1} {
        $txtt tag add mcursor $index
      }

    }

    # Insert leading whitespace to match current indentation level
    if {$indent_space ne ""} {
      $txtt fastinsert -update $do_update "$index linestart" $indent_space
    }

    # If we need to restore the insertion cursor, do it now
    if {$restore_insert ne ""} {
      ::tk::TextSetCursor $txtt $restore_insert
    }

    return [$txtt index "$index+[string length $indent_space]c"]

  }

  ######################################################################
  # Handles the backspace key.  If we are
  proc backspace {txtt index do_update} {

    variable indent_exprs

    # If the auto-indent feature was disabled, we are in vim start mode, or
    # the current language doesn't have an indent expression, quit now
    if {($indent_exprs($txtt,mode) eq "OFF") || [vim::in_vim_mode $txtt]} {
      return $index
    }

    # Figure out the leading space
    set space ""
    if {[set endpos [lassign [$txtt tag prevrange _prewhite $index "$index linestart"] startpos]] ne ""} {
      if {[$txtt compare $endpos == "$index+1c"]} {
        set space [$txtt get $startpos $index]
      } else {
        return $index
      }
    } else {
      set space [$txtt get "$index linestart" "$index lineend"]
    }

    # If the leading whitespace only consists of spaces, attempt to delete to the previous tab
    if {([string map {{ } {}} $space] eq "")} {

      # Calculate the new indentation
      set shiftwidth   [get_shiftwidth $txtt]
      set tab_count    [expr [string length $space] / $shiftwidth]
      set indent_space [string repeat " " [expr $tab_count * $shiftwidth]]

      # Replace the whitespace with the appropriate amount of indentation space
      if {$indent_space ne $space} {
        $txtt fastreplace -update $do_update "$index linestart" $index $indent_space
        set offset [string length $indent_space]
        return [$txtt index "$index linestart+${offset}c"]
      }

    }

    return $index

  }

  ######################################################################
  # Returns the whitespace of the previous (non-empty) line of text.
  proc get_previous_indent_space {txtt index} {

    variable indent_exprs

    if {($indent_exprs($txtt,mode) eq "OFF") || \
        [vim::in_vim_mode $txtt] || \
        ([lindex [split $index .] 0] == 1)} {
      return 0
    }

    if {[set range [$txtt tag prevrange _prewhite "$index-1l lineend"]] ne ""} {
      return [string range [$txtt get {*}$range] 0 end-1]
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
      incr count
      set start [lindex $range 1]
    }

    return $count

  }

  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc format_text {txtt startpos endpos} {

    variable indent_exprs

    # Create a separator
    $txtt edit separator

    # If we are the first line containing non-whitespace, preserve the indentation
    if {([$txtt tag prevrange _prewhite "$startpos linestart"] eq "") || \
        ([string trim [$txtt get "$startpos linestart" $startpos]] ne "")} {
      set curpos [$txtt index "$startpos+1l linestart"]
    } else {
      set curpos [$txtt index "$startpos linestart"]
    }

    set endpos       [$txtt index $endpos]
    set indent_space ""
    set shiftwidth   [get_shiftwidth $txtt]

    while {[$txtt compare $curpos < $endpos]} {

      if {$curpos ne "1.0"} {

        # If the current line contains an unindent expression, is not within a comment or string,
        # and is preceded in the line by only whitespace, replace the whitespace with the proper
        # indentation whitespace.
        if {[set epos [lassign [$txtt tag nextrange _unindent $curpos "$curpos lineend"] spos]] ne ""} {
          if {[set tindex [get_match_indent $txtt $spos]] ne ""} {
            if {[$txtt compare "$tindex linestart" == "$spos linestart"]} {
              set indent_space [get_start_of_line $txtt "$tindex-1l lineend"]
              if {[line_contains_indentation $txtt "$tindex-1l lineend"]} {
                append indent_space [string repeat " " $shiftwidth]
              }
            } else {
              set indent_space [get_start_of_line $txtt $tindex]
            }
          } else {
            set indent_space [get_start_of_line $txtt $epos]
          }

        } elseif {([set epos [lassign [$txtt tag nextrange _reindent $curpos "$curpos lineend"] spos]] ne "") && [check_reindent_for_unindent $txtt $spos]} {
          set indent_space [get_start_of_line $txtt [$txtt index "$curpos-1l lineend"]]
          if {[string trim [$txtt get "$curpos linestart" $spos]] eq ""} {
            if {[$txtt compare "$curpos-1l linestart" > [lindex [$txtt tag prevrange _reindent "$curpos linestart"] 1]]} {
              set indent_space [string range $indent_space $shiftwidth end]
            }
          }

        } else {
          set indent_space [get_start_of_line $txtt [$txtt index "$curpos-1l lineend"]]
          if {[line_contains_indentation $txtt "$curpos-1l lineend"]} {
            append indent_space [string repeat " " $shiftwidth]
          }
        }

      }

      # Remove any leading whitespace and update indentation level
      # (if the first non-whitespace char is a closing bracket)
      set whitespace ""
      if {[lsearch [$txtt tag names $curpos] _prewhite] != -1} {
        set whitespace [string range [$txtt get {*}[$txtt tag nextrange _prewhite $curpos]] 0 end-1]
      }

      # Replace the leading whitespace with the calculated amount of indentation space
      if {$whitespace ne $indent_space} {
        $txtt replace $curpos "$curpos+[string length $whitespace]c" $indent_space
      }

      # Adjust the startpos
      set curpos [$txtt index "$curpos+1l linestart"]

    }

    # Create a separator
    $txtt edit separator

    # Perform syntax highlighting
    [winfo parent $txtt] highlight $startpos $endpos

  }

  ######################################################################
  # Sets the indentation expressions for the given text widget.
  proc set_indent_expressions {txtt indent unindent reindent {add 0}} {

    variable indent_exprs

    # If we are adding the given indentation expressions
    if {$add} {
      lappend indent   {*}[split $indent_exprs($txtt,indent) |]
      lappend unindent {*}[split $indent_exprs($txtt,unindent) |]
      lappend reindent {*}[split $indent_exprs($txtt,reindent) |]
    }

    # Set the indentation expressions
    set indent_exprs($txtt,indent)   [join $indent |]
    set indent_exprs($txtt,unindent) [join $unindent |]
    set indent_exprs($txtt,reindent) [join $reindent |]

    # Set the default indentation mode
    if {[preferences::get Editor/EnableAutoIndent]} {
      if {$indent ne ""} {
        set indent_exprs($txtt,mode) "IND+"
      } else {
        set indent_exprs($txtt,mode) "IND"
      }
    } else {
      set indent_exprs($txtt,mode) "OFF"
    }

    # Update the state of the indentation widget
    gui::update_indent_button

  }

  ######################################################################
  # Repopulates the specified syntax selection menu.
  proc populate_indent_menu {mnu} {

    variable langs

    # Clear the menu
    $mnu delete 0 end

    # Populate the menu with the available languages
    foreach {lbl mode} [list "No Indent" "OFF" "Auto-Indent" "IND" "Smart Indent" "IND+"] {
      $mnu add radiobutton -label $lbl -variable indent::current_indent \
        -value $mode -command [list indent::set_indent_mode $mode]
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
    set txtt [gui::current_txt].t

    # Configure the menubutton
    if {[info exists indent_exprs($txtt,mode)]} {
      $w configure -text [set current_indent $indent_exprs($txtt,mode)]
    }

  }

}
