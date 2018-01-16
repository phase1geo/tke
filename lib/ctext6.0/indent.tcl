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

    # Get the unindent information from the model
    lassign [ctext::model::indent_check_unindent $win $index [$win cget -shiftwidth]] startpos endpos indents

    if {$indents ne ""} {

      # Get the whitespace at the beginning of the logical line
      set indent_space [expr {($indents <= 0) ? "" : [string repeat " " $indents]}]

      # Replace the starting whitespace with the updated whitespace
      $win replace -highlight 0 -str $indent_space $startpos $endpos

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

    set index  [$win._t index "$index+1l linestart"]
    set nl_str ""

    # If we do not need smart indentation, use the previous space
    if {$indent_mode eq "IND"} {
      set insert_space [ctext::model::indent_previous $win $index]
    } else {
      set shiftwidth [$win cget -shiftwidth]
      lassign [ctext::model::indent_newline $win $index $shiftwidth] insert_space add_nl
      puts "insert_space: $insert_space, add_nl: $add_nl"
      if {$add_nl} {
        append nl_str [string repeat " " [expr $insert_space + $shiftwidth]] "\n"
      }
    }

    if {($insert_space == 0) && ($nl_str eq "")} {
      return
    }

    if {$insert_space < 0} {
      if {$nl_str ne ""} {
        $win replace -highlight 0 "$index+${insert_space}c" $index $nl_str
        $win._t mark set insert "$index+[expr [string length $nl_str] - 1]c"
      } else {
        $win delete -highlight 0 "$index+${insert_space}c" $index
      }
    } else {
      if {$nl_str ne ""} {
        $win insert -highlight 0 $index "$nl_str[string repeat { } $insert_space]"
        $win._t mark set insert "$index+[expr [string length $nl_str] - 1]c"
      } else {
        $win insert -highlight 0 $index [string repeat " " $insert_space]
      }
    }

    # If autoseparators are called for, add it now
    if {[$win cget -autoseparators]} {
      $win edit separator
    }

  }

  ######################################################################
  # Called whenever we delete whitespace such that all characters between
  # the beginning of the line and the given index are entirely whitespace.
  proc backspace {win index indent_mode} {

    # If the auto-indent feature was disabled, return immediately
    if {$indent_mode eq "OFF"} {
      return
    }

    # Figure out the leading space
    switch [set spaces [ctext::model::indent_backspace $win $index]] {
      -2      { return }
      -1      { set space [$win._t get "$index linestart" "$index lineend"] }
      default { set space [string repeat " " $spaces] }
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
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc indent_format {win startpos endpos {add_separator 1}} {

    # Create a separator
    if {$add_separator} {
      $win edit separator
    }

    set endpos     [$win._t index $endpos]
    set shiftwidth [$win cget -shiftwidth]

    foreach {spos epos indents} [ctext::model::indent_format $win $startpos $endpos $shiftwidth] {

      # Get the number of indentations to perform
      set indent_space [expr {($indents > 0) ? [string repeat " " $indents] : ""}]

      # Replace the text
      $win replace -highlight 0 -str $indent_space $spos $epos

    }

    # Create a separator
    $win edit separator

  }

}

