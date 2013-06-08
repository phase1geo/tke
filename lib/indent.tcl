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
    add_indent_level $txt.t insert

    bind indent$txt <Key-braceleft>   "indent::increment %W insert insert"
    bind indent$txt <Key-braceright>  "indent::decrement %W insert insert"
    bind indent$txt <Return>          "indent::newline %W insert insert"
    bind indent$txt <Key-Up>          "indent::update_indent_level %W insert insert"
    bind indent$txt <Key-Down>        "indent::update_indent_level %W insert insert"
    bind indent$txt <Key-Left>        "indent::update_indent_level %W insert insert"
    bind indent$txt <Key-Right>       "indent::update_indent_level %W insert insert"
    bind indent$txt <ButtonRelease-1> "indent::update_indent_level %W insert insert"
    bind indent$txt <Key-Delete>      "indent::update_indent_level %W insert insert"
    bind indent$txt <Key-BackSpace>   "indent::update_indent_level %W insert insert"
    
    # Add the indentation tag into the bindtags list just after Text
    set text_index [lsearch [bindtags $txt.t] Text]
    bindtags $txt.t [linsert [bindtags $txt.t] [expr $text_index + 1] indent$txt]
     
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
      $txt replace "$insert_index linestart" "$insert_index-1c" [string repeat " " [expr $indent_levels($txt,$indent_name) * 2]]
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

    # Initialize the indent_levels
    set indent_levels($txt,$indent_name) 0

    # Find the last open brace starting from the current insertion point
    set i 0
    foreach line [lreverse [split [$txt get 1.0 $insert_index] \n]] {
      if {[regexp {^[^#]*\}[^\{]*$} $line]} {
        regexp {^(\s*)} $line -> whitespace
        set indent_levels($txt,$indent_name) [expr [string length $whitespace] / 2]
        break
      } elseif {[regexp {^[^#]*\{[^\}]*$} $line]} {
        regexp {^(\s*)} $line -> whitespace
        set indent_levels($txt,$indent_name) [expr ([string length $whitespace] / 2) + 1]
        break
      } elseif {[regexp {^(\s*)\S+$} $line -> whitespace]} {
        set indent_levels($txt,$indent_name) [expr [string length $whitespace] / 2]
        break
      }
      incr i
    }
    
  }
  
  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc format_text {txt startpos endpos} {
  
    variable indent_levels
    
    # Get the clipboard contents, trimming the whitespace and splitting into lines
    foreach line [split [$txt get $startpos $endpos] \n] {
      lappend str $line
    }

    # Get the line up to the insertion point
    set line         [$txt get "$startpos linestart" $startpos]
    set current_line 0
    
    # If we have non-whitespace text to our left, paste the first line as is.
    if {[regexp {^\s*$} $line]} {
      set extra_whitespace [expr ($indent_levels($txt,insert) * 2) - [string length $line]]
      if {$extra_whitespace > 0} {
        $txt insert $startpos [string repeat " " $extra_whitespace]
      }
    }
    
    # If we have more than one line, add the newline to the first
    if {[llength $str] > 1} {

      # Adjust the indent levels, if necessary
      if {[regexp {^(.*)\{[^\}\\]*$} [lindex $str 0] -> content] && ![regexp {[^\{]*(;\s*)?#} $content]} {
        incr indent_levels($txt,insert)
      } elseif {[string index [lindex $str 0] 0] eq "\}"} {
        incr indent_levels($txt,insert) -1
      }
 
      for {set i 1} {$i < [llength $str]} {incr i} {
        set linestart [$txt index "$startpos+${i}l linestart"]
        set tags      [$txt tag names $linestart]
        if {[regexp {^(\s*)} [lindex $str $i] -> whitespace]} {
          $txt delete $linestart "$linestart+[string length $whitespace]c"
        }
        if {[regexp {^\s*\}(.*)\{[^\}\\]*$} [lindex $str $i] -> content] && ![regexp {[^\{]*;\s*#} $content]} {
          $txt insert $linestart [string repeat " " [expr ($indent_levels($txt,insert) - 1) * 2]] $tags
        } elseif {[regexp {^(.*)\{[^\}\\]*$} [lindex $str $i] -> content] && ![regexp {[^\{]*(;\s*)?#} $content]} {
          $txt insert $linestart [string repeat " " [expr $indent_levels($txt,insert) * 2]] $tags
          incr indent_levels($txt,insert)
        } else {
          if {[regexp {^\s*\}} [lindex $str $i]]} {
            incr indent_levels($txt,insert) -1
          }
          $txt insert $linestart [string repeat " " [expr $indent_levels($txt,insert) * 2]] $tags
        }
      }
    }
    
    # Perform syntax highlighting
    [winfo parent $txt] highlight $startpos $endpos
    
  }
  
}
