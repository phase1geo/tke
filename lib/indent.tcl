# Name:    indent.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for text bindings to handle proper indentations
 
namespace eval indent {

  source [file join $::tke_dir lib ns.tcl]
  
  array set indent_exprs  {}
  array set widgets       {}
  
  ######################################################################
  # Adds indentation bindings for the given text widget.
  proc add_bindings {txt} {
 
    variable widgets
    
    bind indent$txt <Any-Key> "after 2 [list indent::check_indent %W insert]"
    bind indent$txt <Return>  "after 2 [list indent::newline %W insert]"
    
    # Add the indentation tag into the bindtags list just after Text
    set text_index [lsearch [bindtags $txt.t] Text]
    bindtags $txt.t [linsert [bindtags $txt.t] [expr $text_index + 1] indent$txt]
    
    # Add the text item to the list of widgets
    set widgets($txt.t) 1
     
  }
  
  ######################################################################
  # Checks the given text prior to the insertion marker to see if it
  # matches the indent or unindent expressions.  Increment/decrement
  # accordingly.
  proc check_indent {txt index} {
    
    variable indent_exprs
    
    # If the auto-indent feature was disabled, we are in vim start mode, or
    # the current language doesn't have an indent expression, quit now
    if {!$preferences::prefs(Editor/EnableAutoIndent) || \
        [vim::in_vim_mode $txt] || \
        ($indent_exprs($txt,indent) eq "")} {
      return
    }
    
    # Get the indent of the start of the current word
    set wordStart [$txt index "$index-1c wordstart"]
 
    # If the current word is in a string, a comment or is escaped, stop processing.
    if {[ctext::inCommentString $txt $wordStart]} {
      return
    }
 
    # Get the current word
    set word [$txt get "$index-1c wordstart" "$index-1c wordend"]
 
    # If the current word matches an unindent pattern and there is only
    # whitespace prior to the unindent word, replace the whitespace with the
    # appropriate indentation space.
    if {[lsearch -exact $indent_exprs($txt,unindent) $word] != -1} {
      set line [$txt get "$index linestart" $wordStart]
      if {($line ne "") && ([string trim $line] eq "")} {
        $txt replace "$index linestart" $wordStart [get_indent_space $txt 1.0 $index]
      }
    }
    
  }

  ######################################################################
  # Handles a newline character.  Returns the character position of the
  # first line of non-space text.
  proc newline {txt index} {
 
    variable indent_exprs
 
    # If the auto-indent feature was disabled, we are in vim start mode,
    # or the current language doesn't have an indent expression, quit now
    if {!$preferences::prefs(Editor/EnableAutoIndent) || \
        [vim::in_vim_mode $txt] || \
        ($indent_exprs($txt,indent) eq "")} {
      return
    }
    
    # Get the current indentation level
    set indent_space [get_indent_space $txt 1.0 $index]
    
    # Check to see if the previous space is greater than the indent space (if so use it instead)
    set prev_space [get_previous_indent_space $txt $index]
    if {[string length $prev_space] > [string length $indent_space]} {
      set indent_space $prev_space
    }
    
    # Get the current line
    set line [$txt get $index "$index lineend"]
 
    # Remove any leading whitespace and update indentation level
    # (if the first non-whitespace char is a closing bracket)
    if {[regexp {^( *)(.*)} $line -> whitespace rest] && ($rest ne "")} {
      
      # If the first non-whitespace characters match an unindent pattern,
      # lessen the indentation by one
      if {[regexp [subst {^[join $indent_exprs($txt,unindent) |]}] $rest]} {
        set indent_space [string range $indent_space $preferences::prefs(Editor/IndentSpaces) end]
      }
      
      # See if we are deleting a multicursor
      set mcursor [lsearch [$txt tag names $index] "mcursor"]
      
      # Delete the whitespace
      $txt delete $index "$index+[string length $whitespace]c"
      
      # If the newline was from a multicursor, we need to re-add the tag since we have deleted it
      if {$mcursor != -1} {
        $txt tag add mcursor $index
      }
 
    }
 
    # Insert leading whitespace to match current indentation level
    if {$indent_space ne ""} {
      $txt insert $index $indent_space
    }
    
  }
  
  ######################################################################
  # Returns the indentation (in number of spaces) of the previous line
  # of text.
  proc get_previous_indent_space {txt index} {
    
    if {!$preferences::prefs(Editor/EnableAutoIndent) || \
        [vim::in_vim_mode $txt] || \
        ([lindex [split $index .] 0] == 1)} {
      return 0
    }
    
    set line_pos [expr [lindex [split [$txt index $index] .] 0] - 1]
    
    while {($line_pos > 0) && ([string trim [set line [$txt get "$line_pos.0" "$line_pos.end"]]] eq "")} {
      incr line_pos -1
    }
    
    if {($line_pos > 0) && [regexp {^( *)(.*)} $line -> whitespace rest]} {
      return $whitespace
    } else {
      return ""
    }
    
  }
 
  ######################################################################
  # This procedure is called to get the indentation level of the given
  # index.
  proc get_indent_space {txt start end} {
 
    variable indent_exprs

    # If the auto-indent feature was disabled, we are in vim start mode,
    # or the current language doesn't have an indent expression, quit now
    if {!$preferences::prefs(Editor/EnableAutoIndent) || \
        [vim::in_vim_mode $txt] || \
        ($indent_exprs($txt,indent) eq "")} {
      return 0
    }
 
    # Initialize the indent_space
    set indent_level 0
  
    # Create the regular expression
    set all_re [join [concat $indent_exprs($txt,indent) $indent_exprs($txt,unindent)] |]
    set ind_re [join $indent_exprs($txt,indent) |]
    
    # Get the indentation level based on the indent/unindent words found
    set i 0
    foreach index [$txt search -all -count lengths -regexp -- $all_re $start $end] {
      if {[ctext::inCommentString $txt $index] || \
          (([lindex [split $index .] 1] > 0) && ([$txt get "$index-1c"] eq {\\}))} {
        incr i
        continue
      }
      set word [$txt get $index "$index+[lindex $lengths $i]c"]
      incr indent_level [expr {[regexp $ind_re $word] ? 1 : -1}]
      incr i
    }
 
    return [string repeat " " [expr $indent_level * $preferences::prefs(Editor/IndentSpaces)]]
    
  }
 
  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc format_text {txt startpos endpos} {
  
    variable indent_exprs
 
    # If the auto-indent feature was disabled, we are in vim start mode,
    # or the current language doesn't have an indent expression, quit now
    if {!$preferences::prefs(Editor/EnableAutoIndent) || \
        [vim::in_vim_mode $txt] || \
        ($indent_exprs($txt,indent) eq "")} {
      return
    }
 
    # Get the current position and recalculate the endpos
    set currpos [$txt index "$startpos linestart"]
    set endpos  [$txt index $endpos]
 
    # Update the indentation level at the start of the first text line
    if {[$txt compare $startpos == 1.0]} {
      set indent_space ""
    } else {
      set indent_space [get_indent_space $txt 1.0 "$startpos-1l lineend"]
    }
    
    # Create the regular expression containing the indent and unindent words
    set uni_re [join $indent_exprs($txt,unindent) |]
 
    # Find the last open brace starting from the current insertion point
    while {[$txt compare $currpos < $endpos]} {
    
      # Get the current line
      set line [$txt get $currpos "$currpos lineend"]
 
      # Remove the leading whitespace and modify it to match the current indentation level
      if {[regexp {^(\s*)(.*)} $line -> whitespace rest]} {
        if {[string length $whitespace] > 0} {
          $txt delete $currpos "$currpos+[string length $whitespace]c"
        }
        set unindent [expr {[regexp "^$uni_re" $rest] ? $preferences::prefs(Editor/IndentSpaces) : 0}]
        if {$indent_space ne ""} {
          $txt insert $currpos [set indent_space [string range $indent_space $unindent end]]
        }
      }
 
      # Update the indentation level based on the current line
      append indent_space [get_indent_space $txt $currpos "$currpos lineend"]
      
      # Increment the starting position to the next line
      set currpos [$txt index "$currpos+1l linestart"]
 
    }
 
    # Perform syntax highlighting
    [winfo parent $txt] highlight $startpos $endpos
 
  }
 
  ######################################################################
  # Sets the indentation expressions for the given text widget.
  proc set_indent_expressions {txt indent unindent} {
 
    variable indent_exprs
 
    # Set the indentation expressions
    set indent_exprs($txt,indent)   $indent
    set indent_exprs($txt,unindent) $unindent
 
  }
  
}
