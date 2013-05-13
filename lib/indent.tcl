# Name:    indent.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Namespace for text bindings to handle proper indentations

namespace eval indent {

  array set indent_levels {}
  
  ######################################################################
  # Adds indentation bindings for the given text widget.
  proc add_bindings {txt} {
  
    variable indent_levels
    
    # Set the indent level for the given text widget to 0
    set indent_levels($txt) 0
    
    bind indent$txt <Key-braceleft>   "indent::increment $txt"
    bind indent$txt <Key-braceright>  "indent::decrement $txt"
    bind indent$txt <Return>          "puts HERE!; indent::newline $txt"
    # bind $txt <Return> "indent::newline $txt"
    
    # Add the indentation tag into the bindtags list
    bindtags $txt.t [linsert [bindtags $txt.t] 3 indent$txt]
    
    puts "Bindtags: [bindtags $txt.t], bindings: [bind indent$txt]"
    
    puts "Ctext bindings: [bind Ctext]"
     
  }
  
  ######################################################################
  # Deletes the bindings for the given text widget.
  proc remove_bindings {txt} {
  
    variable indent_levels
    
    unset indent_levels($txt)
    
  }
  
  ######################################################################
  # Increments the indentation level for the given text widget.
  proc increment {txt} {
  
    variable indent_levels
    
    if {0} {
    
      # Get the index of the insertion point
      set index [$txt index insert]
    
      # Auto-add the completion curly bracket
      append str "\n"
      if {$indent_levels($txt) > 0} {
        append str [string repeat " " [expr $indent_levels($txt) * 2]]
      }
      append str "\}"
      $txt insert insert $str
    
      # Set the insertion point
      $txt mark set insert $index
      
    }
    
    incr indent_levels($txt)
    
  }
  
  ######################################################################
  # Decrements the indentation level for the given text widget.
  proc decrement {txt} {
  
    variable indent_levels
    
    incr indent_levels($txt) -1
    
    # Remove one indentation of whitespace before the right curly character
    set line [$txt get "insert linestart" insert-1c]
    if {($line ne "") && ([string trim $line] eq "")} {
      $txt delete insert-3c insert-1c
    }
  
  }
  
  ######################################################################
  # Handles a newline character.
  proc newline {txt} {
  
    variable indent_levels
    
    puts "In indent::newline!  indent_levels: $indent_levels($txt)"
    
    # Remove any whitespace on lines with no code
    
    if {$indent_levels($txt) > 0} {
      $txt insert insert [string repeat " " [expr $indent_levels($txt) * 2]]
    }

  }
  
}
