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

  array set indent_exprs {}
  array set indent_mode_map {
    "OFF"  "OFF"
    "IND"  "IND"
    "IND+" "IND+"
    "0"    "OFF"
    "1"    "IND+"
  }

  ######################################################################
  # Sets the indentation mode for the current text widget.
  #
  # TBD
  proc set_indent_mode {mode} {

    variable indent_exprs
    variable indent_mode_map

    # Get the current text widget
    set txt [gui::current_txt]

    # Set the current mode
    set indent_exprs($txt.t,mode) $indent_mode_map($mode)

    # Set the text widget's indent mode
    $txt configure -foldstate [gui::get_folding_method $txt]

    # Update the menu button
    $gui::widgets(info_indent) configure -text $mode

    # Set the focus back to the text widget
    catch { gui::set_txt_focus [gui::last_txt_focus] }

  }

  ######################################################################
  # Returns the value of the indentation mode for the given text widget.
  #
  # TBD
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
  #
  # TBD
  proc is_auto_indent_available {txt} {

    variable indent_exprs

    return [expr {$indent_exprs($txt.t,indentation) ne ""}]

  }

  ######################################################################
  # Checks the given text prior to the insertion marker to see if it
  # matches the unindent expressions.  Increment/decrement
  # accordingly.
  proc check_unindent {txtt index} {

    variable indent_exprs

    # If the auto-indent feature was disabled, we are in vim start mode, or
    # the current language doesn't have an indent expression, quit now
    if {$indent_exprs($txtt,mode) ne "IND+"} {
      return
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
          $txtt replace -highlight 0 "$index linestart" $startpos $indent_space
          return
        }

      }

    } elseif {(([set endpos [lassign [$txtt tag prevrange _reindent $index] startpos]] ne "") && [$txtt compare $endpos == $index]) && [set type [MODEL::is_unindent_after_reindent $txtt $startpos]]} {

      if {[string trim [set space [$txtt get "$index linestart" $startpos]]] eq ""} {

        if {$type == 1} {

          # Get the starting whitespace of the previous line
          set indent_space [get_start_of_line $txtt [$txtt index "$index-1l lineend"]]

          # Check to see if the previous line contained a reindent
          if {[$txtt compare "$index-1l linestart" > [lindex [$txtt tag prevrange _reindent "$index linestart"] 0]]} {
            set indent_space [string range $indent_space [$txtt cget -shiftwidth] end]
          }

        } else {

          # Set the indentation space to the same as the reindentStart line
          set indent_space [get_start_of_line $txtt [lindex [$txtt tag prevrange _reindentStart $index] 0]]

        }

        # Replace the whitespace with the appropriate amount of indentation space
        if {$indent_space ne $space} {
          $txtt replace -highlight 0 "$index linestart" $startpos $indent_space
        }

      }

    }

  }

  ######################################################################
  # Get the matching indentation marker.
  #
  # DONE!
  proc get_match_indent {txtt index} {

    if {[set indent [model::get_match_char [winfo parent $txtt] $index]] ne ""} {
      return [lindex $indent 0]
    }

    return ""

  }

  ######################################################################
  # Returns the whitespace found at the beginning of the specified logical
  # line.
  #
  # DONE!
  proc get_start_of_line {txtt index} {

    # Ignore whitespace
    if {[lsearch [$txtt tag names "$index linestart"] _prewhite] == -1} {
      if {[set range [$txtt tag prevrange _prewhite "$index lineend"]] ne ""} {
        set index [$txtt index "[lindex $range 1] lineend"]
      } else {
        set index 1.0
      }
    }

    # Get the starting line number from the text model
    set index [model::indent_line_start [winfo parent $txtt] $index].0

    if {[lsearch [$txtt tag names $index] _prewhite] != -1} {
      return [string range [$txtt get {*}[$txtt tag nextrange _prewhite $index]] 0 end-1]
    } else {
      return ""
    }

  }

  ######################################################################
  # Handles a newline character.  Returns the character position of the
  # first line of non-space text.
  proc newline {txtt index} {

    variable indent_exprs

    # If the auto-indent feature was disable, quit now
    # or the current language doesn't have an indent expression, quit now
    if {$indent_exprs($txtt,mode) eq "OFF"} {
      if {[$txtt cget -autoseparators]} {
        $txtt edit separator
      }
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
      if {[MODEL::line_contains_indentation $txtt "$index-1l lineend"]} {
        append indent_space [string repeat " " [$txtt cget -shiftwidth]]
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
        $txtt insert -highlight 0 insert "$indent_space\n"
        set startpos [$txtt index $startpos+1l]
        set endpos   [$txtt index $endpos+1l]
        set restore_insert [$txtt index insert-1c]
        if {$indent_exprs($txtt,mode) eq "IND+"} {
          set indent_space [string range $indent_space [$txtt cget -shiftwidth] end]
        }

      # Otherwise, if the first non-whitepace characters match a reindent pattern, lessen the
      # indentation by one
      } elseif {([lsearch [$txtt tag names "$endpos-1c"] _reindent*] != -1) && [MODEL::is_unindent_after_reindent $txtt [lindex [$txtt tag prevrange _reindent $endpos] 0]]} {
        # $txtt insert insert "$indent_space\n"
        # set restore_insert [$txtt index insert-1c]
        if {$indent_exprs($txtt,mode) eq "IND+"} {
          set indent_space [string range $indent_space [$txtt get -shiftwidth] end]
        }
      }

      # See if we are deleting a multicursor
      set mcursor [lsearch [$txtt tag names $index] "mcursor"]

      # Delete the whitespace
      $txtt delete -highlight 0 $startpos "$endpos-1c"

      # If the newline was from a multicursor, we need to re-add the tag since we have deleted it
      if {$mcursor != -1} {
        $txtt tag add mcursor $index
      }

    }

    # Insert leading whitespace to match current indentation level
    if {$indent_space ne ""} {
      $txtt insert -highlight 0 "$index linestart" $indent_space
    }

    # If we need to restore the insertion cursor, do it now
    if {$restore_insert ne ""} {
      ::tk::TextSetCursor $txtt $restore_insert
    }

    # If autoseparators are called for, add it now
    if {[$txtt cget -autoseparators]} {
      $txtt edit separator
    }

    return [$txtt index "$index+[string length $indent_space]c"]

  }

  ######################################################################
  # Called whenever we delete whitespace such that all characters between
  # the beginning of the line and the given index are entirely whitespace.
  #
  # DONE!
  proc handle_backspace {win startpos endpos} {

    # If the auto-indent feature was disabled, return immediately
    if {[$win cget -foldstate] eq "none"} {
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
      set shiftwidth   [$txtt cget -shiftwidth]
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
  #
  # DONE!
  proc get_previous_indent_space {txtt index} {

    if {[lindex [split $index .] 0] != 1) && ([set range [$txtt tag prevrange _prewhite "$index-1l lineend"]] ne "")} {
      return [string range [$txtt get {*}$range] 0 end-1]
    } else {
      return ""
    }

  }

  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc format_text {txtt startpos endpos {add_separator 1}} {

    variable indent_exprs

    # Create a separator
    if {$add_separator} {
      $txtt edit separator
    }

    # If we are the first line containing non-whitespace, preserve the indentation
    if {([$txtt tag prevrange _prewhite "$startpos linestart"] eq "") || \
        ([string trim [$txtt get "$startpos linestart" $startpos]] ne "")} {
      set curpos [$txtt index "$startpos+1l linestart"]
    } else {
      set curpos [$txtt index "$startpos linestart"]
    }

    set endpos       [$txtt index $endpos]
    set indent_space ""
    set shiftwidth   [$txtt cget -shiftwidth]

    while {[$txtt compare $curpos < $endpos]} {

      if {$curpos ne "1.0"} {

        # If the current line contains an unindent expression, is not within a comment or string,
        # and is preceded in the line by only whitespace, replace the whitespace with the proper
        # indentation whitespace.
        if {[set epos [lassign [$txtt tag nextrange _unindent $curpos "$curpos lineend"] spos]] ne ""} {
          if {[set tindex [get_match_indent $txtt $spos]] ne ""} {
            if {[$txtt compare "$tindex linestart" == "$spos linestart"]} {
              set indent_space [get_start_of_line $txtt "$tindex-1l lineend"]
              if {[MODEL::line_contains_indentation $txtt "$tindex-1l lineend"]} {
                append indent_space [string repeat " " $shiftwidth]
              }
            } else {
              set indent_space [get_start_of_line $txtt $tindex]
            }
          } else {
            set indent_space [get_start_of_line $txtt $epos]
          }

        } elseif {([set epos [lassign [$txtt tag nextrange _reindent $curpos "$curpos lineend"] spos]] ne "") && [MODEL::is_unindent_after_reindent $txtt $spos]} {
          set indent_space [get_start_of_line $txtt [$txtt index "$curpos-1l lineend"]]
          if {[string trim [$txtt get "$curpos linestart" $spos]] eq ""} {
            if {[$txtt compare "$curpos-1l linestart" > [lindex [$txtt tag prevrange _reindent "$curpos linestart"] 1]]} {
              set indent_space [string range $indent_space $shiftwidth end]
            }
          }

        } else {
          set indent_space [get_start_of_line $txtt [$txtt index "$curpos-1l lineend"]]
          if {[MODEL::line_contains_indentation $txtt "$curpos-1l lineend"]} {
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
  proc set_indent_expressions {txtt {indentation ""}} {

    variable indent_exprs

    set indent_exprs($txtt,indentation) $indentation

    # Set the default indentation mode
    if {[preferences::get Editor/EnableAutoIndent]} {
      if {$indentation ne ""} {
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
  #
  # TBD - Put into gui.tcl
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
  #
  # TBD - Put into gui.tcl
  proc create_menu {w} {

    # Create the menubutton menu
    set mnu [menu ${w}Menu -tearoff 0]

    # Populate the indent menu
    populate_indent_menu $mnu

    # Register the menu
    theme::register_widget $mnu menus

    return $mnu

  }

  ######################################################################
  # Updates the menubutton to match the current mode.
  #
  # TBD - Put into gui.tcl
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

