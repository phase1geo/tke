# Name:    indent.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for text bindings to handle proper indentations
 
namespace eval indent {

  array set indent_levels {}
  array set indent_exprs  {}
  
  ######################################################################
  # Adds indentation bindings for the given text widget.
  proc add_bindings {txt} {
  
    # Set the indent level for the given text widget to 0
    add_indent_level $txt.t insert

    bind indent$txt <Any-Key>        "after 2 [list indent::check_indent %W insert insert]"
    # bind indent$txt <Key-braceleft>   "indent::increment %W insert insert"
    # bind indent$txt <Key-braceright>  "indent::decrement %W insert insert"
    bind indent$txt <Return>          "after 2 [list indent::newline %W insert insert]"
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
  # Checks the given text prior to the insertion marker to see if it
  # matches the indent or unindent expressions.  Increment/decrement
  # accordingly.
  proc check_indent {txt insert_index indent_name} {
    
    variable indent_levels
    variable indent_exprs
    
    # Get the indent of the start of the current word
    set wordStart [$txt index "$insert_index-1c wordstart"]
    
    # If the start of the current word is in a comment or string, do nothing
    set wordTags [$txt tag names $wordStart]
    
    # If the current word is in a string, a comment or is escaped, stop processing.
    if {([lsearch -glob $wordTags _strings*] != -1) || \
        ([lsearch -glob $wordTags _comments*] != -1) || \
        ([lsearch $wordTags _cComment] != -1) || \
        ([$txt compare $wordStart > "$insert_index linestart"] && ([$txt get "$wordStart-1c"] eq "\\"))} {
      return
    }
         
    # Get the current word
    set word [$txt get "$insert_index-1c wordstart" "$insert_index-1c wordend"]
          
    # Increment the indentation level
    if {[lsearch $indent_exprs($txt,indent) $word] != -1} {
      incr indent_levels($txt,$indent_name)
        
    # Decrement the indentation level and replace preceding whitespace
    } elseif {[lsearch $indent_exprs($txt,unindent) $word] != -1} {
      incr indent_levels($txt,$indent_name) -1
      set line [$txt get "$insert_index linestart" "$insert_index-[string length $word]c"]
      if {($line ne "") && ([string trim $line] eq "")} {
        $txt replace "$insert_index linestart" "$insert_index-[string length $word]c" \
          [string repeat " " [expr $indent_levels($txt,$indent_name) * 2]]
      }
    }
    
  }

  ######################################################################
  # Handles a newline character.
  proc newline {txt insert_index indent_name} {
  
    variable indent_levels
    variable indent_exprs
    
    # Get the current line
    set line [$txt get $insert_index "$insert_index lineend"]

    # Remove any leading whitespace and update indentation level (if the first non-whitespace char is a closing bracket)
    if {[regexp {^( *)(.*)} $line -> whitespace rest]} {
      if {[regexp [subst {^$indent_exprs($txt,unindent)}] $rest]} {
        incr indent_levels($txt,$indent_name) -1
      }
      $txt delete $insert_index "$insert_index+[string length $whitespace]c"
    }
    
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
    variable indent_exprs

    # If we are in a Vim mode (non-editing state), stop now
    if {[vim::in_vim_mode $txt]} {
      return
    }
    
    # Initialize the indent_levels
    set indent_levels($txt,$indent_name) 0
          
    # Create the regular expression
    set re [join [concat $indent_exprs($txt,indent) $indent_exprs($txt,unindent)] |]
         
    # Find the last open brace starting from the current insertion point
    lassign [split [set insert_index [$txt index $insert_index]] .] start_row end_col
    incr end_col -1
    set end $insert_index
    while {$start_row >= 1} {
      set indents [list]
      set line    [$txt get $start_row.0 $start_row.end]
      if {[regexp {^([ ]*)\S} $line -> whitespace]} {
        set line  [string range $line 0 $end_col]
        set start [string length $whitespace]
        set level [expr $start / 2]
        set i     0
        while {[regexp -indices -start $start -- $re $line match]} {
        
          # If the current word is in a string, a comment or is escaped, skip it
          set wordTags [$txt tag names $start_row.[lindex $match 0]]
          if {([lsearch -glob $wordTags _strings*] != -1) || \
              ([lsearch -glob $wordTags _comments*] != -1) || \
              ([lsearch $wordTags _cComment] != -1) || \
              (([lindex $match 0] > 0) && ([string index $line [expr [lindex $match 0] - 1]] eq "\\"))} {
            set start [expr [lindex $match 1] + 1]
            continue
          }
          
          # Check to see if the current word is an indent or an unindent and adjust the current level
          set word [string range $line {*}$match]
          if {[lsearch $indent_exprs($txt,indent) $word] != -1} {
            incr level
          } elseif {($i != 0) || ([lindex $match 0] != $start)} {
            incr level -1
          }
        
          set start [expr [lindex $match 1] + 1]
          incr i
        }
        set indent_levels($txt,$indent_name) $level
        break
      }
      incr start_row -1
      set end_col "end"
    }
    
  }
  
  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc format_text {txt startpos endpos} {
  
    variable indent_levels
    variable indent_exprs
    
    # Get the text widget contents, trimming the whitespace and splitting into lines
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
          $txt insert $linestart [string repeat " " [expr $indent_levels($txt,insert) * 2]] $tags incr indent_levels($txt,insert) } else { if {[regexp {^\s*\}} [lindex $str $i]]} { incr indent_levels($txt,insert) -1 } $txt insert $linestart [string repeat " " [expr $indent_levels($txt,insert) * 2]] $tags
        }
      }
    }
    
    # Perform syntax highlighting
    [winfo parent $txt] highlight $startpos $endpos
    
  }
  
  ######################################################################
  # Sets the indentation expressions for the given text widget.
  proc set_indent_expressions {txt indent unindent} {
    
    variable indent_levels
    variable indent_exprs
    
    # Clear the indentation levels
    foreach name [array names indent_level $txt,*] {
      set indent_levels($name) 0
    }

    # Set the indentation expressions
    set indent_exprs($txt,indent)   $indent
    set indent_exprs($txt,unindent) $unindent
    
  }
  
}
