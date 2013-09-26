# Name:    indent.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for text bindings to handle proper indentations
 
namespace eval indent {

  array set indent_levels {}
  array set indent_exprs  {}
  array set widgets       {}
  
  ######################################################################
  # Initializes the indent namespace.
  proc initialize {} {
    
    # Set traces on preference items
    trace variable preferences::prefs(Editor/EnableAutoIndent) w indent::handle_auto_indent
    trace variable preferences::prefs(Editor/IndentSpaces)     w indent::handle_indent_spaces
    
  }
  
  ######################################################################
  # Called whenever the Editor/EnableAutoIndent option is changed.
  proc handle_auto_indent {name1 name2 op} {
    
    variable widgets
    
    # Make sure that we reformat the text if auto-indent is turned on (from being off)
    if {$preferences::prefs(Editor/EnableAutoIndent)} {
      foreach widget [array names widgets] {
        if {[winfo exists $widget]} {
          format_text $widget 1.0 end
        } else {
          catch { unset widgets($widget) }
        }
      }
    }
    
  }
  
  ######################################################################
  # Called whenever the Editor/IndentSpaces option is changed.
  proc handle_indent_spaces {name1 name2 op} {
    
    variable widgets
   
    puts "In handle_indent_spaces"
    
    # Reformat the text with the given indentation spaces
    if {$preferences::prefs(Editor/EnableAutoIndent} {
      foreach widget [array names widgets] {
        if {[winfo exists $widget]} {
          format_text $widget 1.0 end
        } else {
          catch { unset widgets($widget) }
        }
      }
    }
    
  }
  
  ######################################################################
  # Adds indentation bindings for the given text widget.
  proc add_bindings {txt} {
  
    variable widgets
    
    # Set the indent level for the given text widget to 0
    add_indent_level $txt.t insert

    bind indent$txt <Any-Key>         "after 2 [list indent::check_indent %W insert insert]"
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
    
    # Add the text item to the list of widgets
    set widgets($txt.t) 1
     
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
    
    # If the auto-indent feature was disabled, quit now
    if {!$preferences::prefs(Editor/EnableAutoIndent)} {
      return
    }
    
    # Get the indent of the start of the current word
    set wordStart [$txt index "$insert_index-1c wordstart"]
    
    # If the current word is in a string, a comment or is escaped, stop processing.
    if {[ctext::inCommentString $txt $wordStart]} {
      return
    }
         
    # Get the current word
    set word [$txt get "$insert_index-1c wordstart" "$insert_index-1c wordend"]
    
    # Increment the indentation level
    if {[lsearch -exact $indent_exprs($txt,indent) $word] != -1} {
      incr indent_levels($txt,$indent_name)
        
    # Decrement the indentation level and replace preceding whitespace
    } elseif {[lsearch -exact $indent_exprs($txt,unindent) $word] != -1} {
      incr indent_levels($txt,$indent_name) -1
      set line [$txt get "$insert_index linestart" "$insert_index-[string length $word]c"]
      if {($line ne "") && ([string trim $line] eq "")} {
        $txt replace "$insert_index linestart" "$insert_index-[string length $word]c" \
          [string repeat " " [expr $indent_levels($txt,$indent_name) * $preferences::prefs(Editor/IndentSpaces)]]
      }
    }
    
  }

  ######################################################################
  # Handles a newline character.  Returns the character position of the
  # first line of non-space text.
  proc newline {txt insert_index indent_name} {
  
    variable indent_levels
    variable indent_exprs
    
    # If the auto-indent feature was disabled, quit now
    if {!$preferences::prefs(Editor/EnableAutoIndent)} {
      return
    }
    
    # Get the current line
    set line [$txt get $insert_index "$insert_index lineend"]

    # Remove any leading whitespace and update indentation level (if the first non-whitespace char is a closing bracket)
    if {[regexp {^( *)(.*)} $line -> whitespace rest] && (($rest ne "") || ([string index $indent_name 0] ne "m"))} {
      if {[regexp [subst {^$indent_exprs($txt,unindent)}] $rest]} {
        incr indent_levels($txt,$indent_name) -1
      }
      $txt delete $insert_index "$insert_index+[string length $whitespace]c"
      
      # If the insert_name was a multicursor, we need to re-add the tag since we have deleted it
      if {[string index $indent_name 0] eq "m"} {
        $txt tag add mcursor $insert_index
      }

    }
    
    # Insert leading whitespace to match current indentation level
    if {$indent_levels($txt,$indent_name) > 0} {
      $txt insert $insert_index [string repeat " " [expr $indent_levels($txt,$indent_name) * $preferences::prefs(Editor/IndentSpaces)]]
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
        set level [expr $start / $preferences::prefs(Editor/IndentSpaces)]
        set i     0
        while {[regexp -indices -start $start -- $re $line match]} {
        
          # If the current word is in a string, a comment or is escaped, skip it
          set wordTags [$txt tag names $start_row.[lindex $match 0]]
          if {[ctext::inCommentString $txt "$start_row.[lindex $match 0]"]} {
            set start [expr [lindex $match 1] + 1]
            continue
          }
          
          # Check to see if the current word is an indent or an unindent and adjust the current level
          set word [string range $line {*}$match]
          if {[lsearch -exact $indent_exprs($txt,indent) $word] != -1} {
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
    
    # Get the current position and recalculate the endpos
    set currpos [$txt index "$startpos linestart"]
    set endpos  [$txt index $endpos]
    
    # Update the indentation level at the start of the first text line
    if {$currpos eq "1.0"} {
      set indent_levels($txt,insert) 0
    } else {
      update_indent_level $txt "$startpos-1l lineend" insert
    }
              
    # Create the regular expression containing the indent and unindent words
    set re [join [concat $indent_exprs($txt,indent) $indent_exprs($txt,unindent)] |]
    
    # Find the last open brace starting from the current insertion point
    while {[$txt compare $currpos < $endpos]} {
    
      # Get the current line
      set line [$txt get $currpos "$currpos lineend"]
      
      # Remove the leading whitespace and modify it to match the current indentation level
      if {[regexp {^(\s*)\S} $line -> whitespace]} {
        if {[string length $whitespace] > 0} {
          $txt delete $currpos "$currpos+[string length $whitespace]c"
          set line [string replace $line 0 [expr [string length $whitespace] - 1]]
        }
        if {[regexp "^$indent_exprs($txt,unindent)" $line]} {
          incr indent_levels($txt,insert) -1
        }
        if {$indent_levels($txt,insert) > 0} {
          set spaces [string repeat " " [expr $indent_levels($txt,insert) * $preferences::prefs(Editor/IndentSpaces)]]
          $txt insert $currpos $spaces
          set line "$spaces$line"
        }
      }
      
      # Calculate the indentation level for the next line based on the contents of the current line
      set i     0
      set start 0
      while {[regexp -indices -start $start -- $re $line match]} {
        
        # If the current word is in a string, a comment or is escaped, skip it
        set wordTags [$txt tag names "$currpos+[lindex $match 0]c"]
        if {[ctext::inCommentString $txt "$currpos+[lindex $match 0]c"]} {
          set start [expr [lindex $match 1] + 1]
          continue
        }
          
        # Check to see if the current word is an indent or an unindent and adjust the current level
        set word [string range $line {*}$match]
        if {[lsearch -exact $indent_exprs($txt,indent) $word] != -1} {
          incr indent_levels($txt,insert)
        } elseif {($i != 0) || ([lindex $match 0] != $start)} {
          incr indent_levels($txt,insert) -1
        }
        
        set start [expr [lindex $match 1] + 1]
        incr i
        
      }
      
      # Increment the starting position to the next line
      set currpos [$txt index "$currpos+1l linestart"]
      
    }
    
    # Perform syntax highlighting
    [winfo parent $txt] highlight $startpos $endpos

    # Update the indentation level based on the current cursor location
    update_indent_level $txt insert insert
        
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
