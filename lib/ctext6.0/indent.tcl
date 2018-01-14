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

      set endpos [$win._t index "$endpos-1c"]

      # Get the unindent information from the model
      if {[set data [ctext::model::indent_check_unindent $win $endpos $index]] ne ""} {

        lassign $data data_index data_less

        # Get the whitespace at the beginning of the logical line
        set indent_spaces [expr [get_start_of_line $win [$win._t index $data_index]] - ([$win cget -shiftwidth] * $data_less)]

        if {$indent_spaces <= 0} {
          set indent_space ""
        } else {
          set indent_space [string repeat " " $indent_spaces]
        }

        # If required, replace the starting whitespace with the updated whitespace
        if {$indent_space ne [$win._t get $startpos $endpos]} {
          $win replace -highlight 0 -str $indent_space $startpos $endpos
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
  # Returns the amount of whitespace found at the beginning of the specified
  # logical line.
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

    # Ignore whitespace
    if {[lsearch [$win._t tag names "$index linestart"] _prewhite] == -1} {
      if {[set range [$win._t tag prevrange _prewhite "$index lineend"]] ne ""} {
        set prev_index [$win._t index "[lindex $range 1] lineend"]
      } else {
        set prev_index 1.0
      }
    } else {
      set prev_index $index
    }

    set index  [$win._t index "$index+1l linestart"]
    set nl_str ""

    # If we do not need smart indentation, use the previous space
    if {$indent_mode eq "IND"} {
      set insert_space [get_previous_indent_space $win $index]
    } else {
      if {[set first_index [lassign [$win._t tag nextrange _prewhite $index "$index lineend"] unused]] ne ""} {
        set first_index [$win._t index "$first_index-1c"]
      } else {
        set first_index $index
      }
      set insert_space [get_start_of_line $win [$win._t index "$index-1l lineend"]]
      lassign [ctext::model::indent_newline $win $prev_index $first_index $insert_space [$win cget -shiftwidth]] insert_space add_nl
      if {$add_nl} {
        set nl_str "[string repeat { } [expr $insert_space + [$win cget -shiftwidth]]]\n"
      }
    }

    if {($insert_space == 0) && ($nl_str eq "")} {
      return
    }

    if {$insert_space < 0} {
      if {$nl_str ne ""} {
        $win replace -highlight 0 $index "$index+${insert_space}c" $nl_str
        $win._t mark set insert "$index+[expr [string length $nl_str] - 1]c"
      } else {
        $win delete -highlight 0 $index "$index+${insert_space}c"
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

    if {([lindex [split $index .] 0] != 1) && ([set range [$win._t tag prevrange _prewhite "$index-1l lineend"]] ne "")} {
      return [expr [string length [$win._t get {*}$range]] - 1]
    } else {
      return 0
    }

  }

  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc format_text {win startpos endpos {add_separator 1}} {

    # Create a separator
    if {$add_separator} {
      $win edit separator
    }

    # If we are the first line containing non-whitespace, preserve the indentation
    if {([$win._t tag prevrange _prewhite "$startpos linestart"] eq "") || \
        ([string trim [$win._t get "$startpos linestart" $startpos]] ne "")} {
      set startpos [$win._t index "$startpos+1l linestart"]
    } else {
      set startpos [$win._t index "$startpos linestart"]
    }

    set endpos     [$win._t index $endpos]
    set shiftwidth [$win cget -shiftwidth]

    foreach {index check_index adjust} [ctext::model::format_text $win $startpos $endpos] {

      # Get the number of indentations to perform
      set indents      [expr [get_start_of_line $win $check_index] + $adjust]
      set indent_space ""
      set whitespace   ""

      # Calculate the indentation space for the given line
      if {$indents > 0} {
        set indent_space [string repeat " " [expr $indents * $shiftwidth]]
      }

      # Remove any leading whitespace and update indentation level (if the first non-whitespace char is a closing bracket)
      if {[lsearch [$win._t tag names $index] _prewhite] != -1} {
        set whitespace [string range [$win._t get {*}[$win._t tag nextrange _prewhite $index]] 0 end-1]
      }

      # Replace the leading whitespace with the calculated amount of indentation space
      if {$whitespace ne $indent_space} {
        $win replace -highlight 0 $index "$index+[string length $whitespace]c" $indent_space
      }

    }

    # Create a separator
    $win edit separator

  }

}

