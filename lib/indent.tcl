# Name:    indent.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for text bindings to handle proper indentations

namespace eval indent {

  source [file join $::tke_dir lib ns.tcl]

  array set indent_exprs  {}

  ######################################################################
  # Adds indentation bindings for the given text widget.
  proc add_bindings {txt} {

    bind indent$txt <Any-Key> "[ns indent]::check_indent %W insert"
    bind indent$txt <Return>  "[ns indent]::newline %W insert"

    # Add the indentation tag into the bindtags list just after Text
    set text_index [lsearch [bindtags $txt.t] Text]
    bindtags $txt.t [linsert [bindtags $txt.t] [expr $text_index + 1] indent$txt]
    
  }

  ######################################################################
  # Sets the indentation mode for the current text widget.
  proc set_indent_mode {mode} {
    
    variable indent_exprs
    
    # Get the current text widget
    set txt [[ns gui]::current_txt {}].t
    
    # Set the current mode
    set indent_exprs($txt,mode) $mode
    
    # Update the menu button
    [set [ns gui]::widgets(info_indent)] configure -text $mode
    
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
  # Checks the given text prior to the insertion marker to see if it
  # matches the unindent expressions.  Increment/decrement
  # accordingly.
  proc check_indent {txt index} {

    variable indent_exprs

    # If the auto-indent feature was disabled, we are in vim start mode, or
    # the current language doesn't have an indent expression, quit now
    if {($indent_exprs($txt,mode) eq "OFF") || [[ns vim]::in_vim_mode $txt]} {
      return
    }

    # If the current line contains an unindent expression, is not within a comment or string,
    # and is preceded in the line by only whitespace, replace the whitespace with the proper
    # indentation whitespace.
    if {([set uindex [$txt search -regexp -- "[join $indent_exprs($txt,unindent) |]\$" "$index linestart" $index]] ne "") && \
         ![ctext::inCommentString $txt $uindex]} {
      set line [$txt get "$index linestart" $uindex]
      if {($line ne "") && ([string trim $line] eq "")} {
        $txt replace "$index linestart" $uindex [get_indent_space $txt 1.0 $index]
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
    if {($indent_exprs($txt,mode) eq "OFF") || [[ns vim]::in_vim_mode $txt]} {
      return
    }

    # Get the previous space
    set prev_space [get_previous_indent_space $txt $index]
    
    # If we do not need smart indentation, use the previous space
    if {$indent_exprs($txt,mode) eq "IND"} {
      
      set indent_space $prev_space
      
    # Otherwise, do smart indentation
    } else {
      
      # Get the current indentation level
      set indent_space [get_indent_space $txt 1.0 $index]

      # Check to see if the previous space is greater than the indent space (if so use it instead)
      if {[string length $prev_space] > [string length $indent_space]} {
        set indent_space $prev_space
      }
      
    }
    
    # Get the current line
    set line [$txt get $index "$index lineend"]

    # Create an index to restore the insertion cursor, if necessary
    set restore_insert ""

    # Remove any leading whitespace and update indentation level
    # (if the first non-whitespace char is a closing bracket)
    if {[regexp {^( *)(.*)} $line -> whitespace rest] && ($rest ne "")} {

      # If the first non-whitespace characters match an unindent pattern,
      # lessen the indentation by one
      if {[regexp [subst {^[join $indent_exprs($txt,unindent) |]}] $rest]} {
        $txt insert insert "$indent_space\n"
        set restore_insert [$txt index insert-1c]
        set indent_space [string range $indent_space [[ns preferences]::get Editor/IndentSpaces] end]
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

    # If we need to restore the insertion cursor, do it now
    if {$restore_insert ne ""} {
      $txt mark set insert $restore_insert
    }

  }

  ######################################################################
  # Returns the indentation (in number of spaces) of the previous line
  # of text.
  proc get_previous_indent_space {txt index} {

    variable indent_exprs
    
    if {($indent_exprs($txt,mode) eq "OFF") || \
        [[ns vim]::in_vim_mode $txt] || \
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
  # This procedure counts the number of tags in the given range.
  proc get_tag_count {txt tag start end} {
    
    variable indent_exprs
    
    # Initialize the indent_level
    set count 0
    
    # Count all tags that are not within comments or are escaped
    while {[set range [$txt tag nextrange _$tag $start $end]] ne ""} {
      lassign $range index start
      if {![ctext::inCommentString $txt $index]} {
        incr count [expr [regexp -all $indent_exprs($txt,$tag) [$txt get $index $start]] - [ctext::isEscaped $txt $index]]
      }
    }
    
    return $count
    
  }
  
  ######################################################################
  # This procedure is called to get the indentation level of the given
  # index.
  proc get_indent_space {txt start end} {

    # Get the current indentation level
    set indent_level [expr [get_tag_count $txt indent $start $end] - [get_tag_count $txt unindent $start $end]] 

    return [string repeat " " [expr $indent_level * [[ns preferences]::get Editor/IndentSpaces]]]

  }

  ######################################################################
  # Formats the given str based on the indentation information of the text
  # widget at the current insertion cursor.
  proc format_text {txt startpos endpos} {

    variable indent_exprs

    # If the current language doesn't have indentation enabled, quit now
    if {$indent_exprs($txt,mode) eq "OFF"} {
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
        if {[regexp "^(\\\\)*($uni_re)" $rest -> escapes unindent_match] && \
            ![expr [string length $escapes] % 2]} {
          set unindent [[ns preferences]::get Editor/IndentSpaces]
        } else {
          set unindent_match ""
          set unindent       0
        }
        if {$indent_space ne ""} {
          $txt insert $currpos [set indent_space [string range $indent_space $unindent end]]
        }
        append indent_space [get_indent_space $txt "$currpos+[expr [string length $unindent_match] + [string length $indent_space]]c" "$currpos lineend"]
      } else {
        append indent_space [get_indent_space $txt $currpos "$currpos lineend"]
      }

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
    
    # Set the default indentation mode
    if {[[ns preferences]::get Editor/EnableAutoIndent]} {
      if {$indent ne ""} {
        set indent_exprs($txt,mode) "IND+"
      } else {
        set indent_exprs($txt,mode) "IND"
      }
    } else {
      set indent_exprs($txt,mode) "OFF"
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
      $mnu add radiobutton -label $lbl -variable [ns indent]::indent_exprs([[ns gui]::current_txt {}].t,mode) \
        -value $mode -command "[ns indent]::set_indent_mode $mode"
    }
    
    return $mnu

  }
  
  ######################################################################
  # Creates the menubutton to control the indentation mode for the current
  # editor.
  proc create_menubutton {w} {
    
    # Create the menubutton
    ttk::menubutton $w -menu $w.menu -direction above

    # Create the menubutton menu
    menu $w.menu -tearoff 0 -postcommand "[ns indent]::populate_indent_menu $w.menu"
    
    return $w
    
  }
  
  ######################################################################
  # Updates the menubutton to match the current mode.
  proc update_menubutton {w} {
    
    variable indent_exprs
    
    # Get the current text widget
    set txt [[ns gui]::current_txt {}]
    
    # Configure the menubutton
    if {[info exists indent_exprs($txt.t,mode)]} {
      $w configure -text $indent_exprs($txt.t,mode)
    }
    
  }

}
