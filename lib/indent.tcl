# Name:    indent.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for text bindings to handle proper indentations

namespace eval indent {

  array set indent_levels {}
  
  ######################################################################
  # Adds indentation bindings for the given text widget.
  proc add_bindings {txt} {
  
    # Set the indent level for the given text widget to 0
    add_indent_level $txt insert

    bind indent$txt <Key-braceleft>   "indent::increment $txt insert insert"
    bind indent$txt <Key-braceright>  "indent::decrement $txt insert insert"
    bind indent$txt <Return>          "indent::newline $txt insert insert"
    bind indent$txt <Key-Up>          "indent::update_indent_level $txt insert insert"
    bind indent$txt <Key-Down>        "indent::update_indent_level $txt insert insert"
    bind indent$txt <Key-Left>        "indent::update_indent_level $txt insert insert"
    bind indent$txt <Key-Right>       "indent::update_indent_level $txt insert insert"
    bind indent$txt <ButtonRelease-1> "indent::update_indent_level $txt insert insert"
    bind indent$txt <Key-Delete>      "indent::update_indent_level $txt insert insert"
    bind indent$txt <Key-BackSpace>   "indent::update_indent_level $txt insert insert"
    
    # Add the indentation tag into the bindtags list
    bindtags $txt.t [linsert [bindtags $txt.t] 3 indent$txt]
     
  }
  
  ######################################################################
  # Deletes the bindings for the given text widget.
  proc remove_bindings {txt} {
  
    variable indent_levels
    
    catch { array unset indent_levels $txt,* }
    
  }
  
  ######################################################################
  # Adds an indentation level marker called name.
  proc add_indent_level {txt indent_name} {

    variable indent_levels

    set indent_levels($txt,$indent_name) 0

  }

  ######################################################################
  # Removes all of the indent levels that match indent_pattern.
  proc remove_indent_levels {txt indent_pattern} {

    variable indent_levels

    catch { array unset indent_levels $txt,$indent_pattern }
 
  }

  ######################################################################
  # Increments the indentation level for the given text widget.
  proc increment {txt insert_index indent_name} {
  
    variable indent_levels
    
    if {[string first "#" [$txt get "$insert_index linestart" $insert_index]] == -1} {
      incr indent_levels($txt,$indent_name)
    }
    
  }
  
  ######################################################################
  # Decrements the indentation level for the given text widget.
  proc decrement {txt insert_index indent_name} {
  
    variable indent_levels
    
    if {[string first "#" [$txt get "$insert_index linestart" $insert_index]] == -1} {
      incr indent_levels($txt,$indent_name) -1
    }
    
    # Remove one indentation of whitespace before the right curly character
    set line [$txt get "$insert_index linestart" $insert_index-1c]
    if {($line ne "") && ([string trim $line] eq "")} {
      $txt delete $insert_index-3c $insert_index-1c
    }
  
  }
  
  ######################################################################
  # Handles a newline character.
  proc newline {txt insert_index indent_name} {
  
    variable indent_levels
    
    # Insert leading whitespace to match current indentation level
    if {$indent_levels($txt,$indent_name) > 0} {
      $txt insert $insert_index [string repeat " " [expr $indent_levels($txt,$indent_name) * 2]]
    }

  }
  
  ######################################################################
  # This procedure is called whenever the insertion cursor moves to a
  # new spot via keyboard traversal or a left button click.
  proc update_indent_level {txt insert_index indent_name} {
  
    variable indent_levels
    
    # First, get the indentation level of the current line
    regexp {^(\s*)} [$txt get "$insert_index linestart" "$insert_index lineend"] -> whitespace
    set indent_levels($txt,$indent_name) [expr [string length $whitespace] / 2]
    
    # Get the current line
    set line [$txt get "$insert_index linestart" $insert_index]
    
    # Second, if we have a mismatched brace on the current line,
    # add an indent level to ourselves

    # If we are in a comment, do nothing
    if {[string first "#" $line] != -1} {
      return
    }
    
    # If the line contains an open brace with no following close brace,
    # increment the indentation level.
    if {[regexp {\{[^\}]*$} $line]} {
      incr indent_levels($txt,$indent_name)
    }
  
  }
  
  ######################################################################
  # Grabs the text in the clipboard, formats the text to match the current
  # insertion point, and puts the formatted text back into the clipboard
  # for future pasting.
  proc format_clipboard {txt} {
  
    variable indent_levels
    
    # Get the clipboard contents, trimming the whitespace and splitting into lines
    foreach line [split [clipboard get] \n] {
      lappend clipped [string trim $line]
    }
    
    # Clear the clipboard
    clipboard clear
    
    # Get the line up to the insertion point
    set line         [$txt get "insert linestart" insert]
    set current_line 0
    
    # If we have non-whitespace text to our left, paste the first line as is.
    if {[regexp {^\s*$} $line]} {
      set extra_whitespace [expr ($indent_levels($txt,insert) * 2) - [string length $line]]
      if {$extra_whitespace > 0} {
        clipboard append [string repeat " " $extra_whitespace]
      }
    }
    
    # Append the first line to the clipboard
    clipboard append [lindex $clipped 0]
    
    # If we have more than one line to paste, add the newline to the first
    if {[llength $clipped] > 1} {

      # Adjust the indent levels, if necessary
      if {[regexp {\{[^\}]*$} [lindex $clipped 0]]} {
        incr indent_levels($txt,insert)
      } elseif {[string index [lindex $clipped 0] 0] eq "\}"} {
        incr indent_levels($txt,insert) -1
      }

      # Add the newline and adjust the indent levels if necessary
      clipboard append "\n"

      for {set i 1} {$i < [llength $clipped]} {incr i} {
        if {[regexp {\{[^\}]*$} [lindex $clipped $i]]} {
          clipboard append [string repeat " " [expr $indent_levels($txt,insert) * 2]]
          incr indent_levels($txt)
        } else {
          if {[string index [lindex $clipped $i] 0] eq "\}"} {
            incr indent_levels($txt) -1
          }
          clipboard append [string repeat " " [expr $indent_levels($txt,insert) * 2]]
        }
        clipboard append [lindex $clipped $i]
        if {($i + 1) < [llength $clipped]} {
          clipboard append "\n"
        }
      }
    }
  
  }
  
}
