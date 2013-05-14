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
    bind indent$txt <Return>          "indent::newline $txt"
    bind indent$txt <Key-Up>          "indent::update_indent_level $txt"
    bind indent$txt <Key-Down>        "indent::update_indent_level $txt"
    bind indent$txt <Key-Left>        "indent::update_indent_level $txt"
    bind indent$txt <Key-Right>       "indent::update_indent_level $txt"
    bind indent$txt <ButtonRelease-1> "indent::update_indent_level $txt"
    bind indent$txt <Key-Delete>      "indent::update_indent_level $txt"
    bind indent$txt <Key-BackSpace>   "indent::update_indent_level $txt"
    
    # Add the indentation tag into the bindtags list
    bindtags $txt.t [linsert [bindtags $txt.t] 3 indent$txt]
     
  }
  
  ######################################################################
  # Deletes the bindings for the given text widget.
  proc remove_bindings {txt} {
  
    variable indent_levels
    
    catch { unset indent_levels($txt) }
    
  }
  
  ######################################################################
  # Increments the indentation level for the given text widget.
  proc increment {txt} {
  
    variable indent_levels
    
    if {[string first "#" [$txt get "insert linestart" insert]] == -1} {
      incr indent_levels($txt)
    }
    
  }
  
  ######################################################################
  # Decrements the indentation level for the given text widget.
  proc decrement {txt} {
  
    variable indent_levels
    
    if {[string first "#" [$txt get "insert linestart" insert]] == -1} {
      incr indent_levels($txt) -1
    }
    
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
    
    # Insert leading whitespace to match current indentation level
    if {$indent_levels($txt) > 0} {
      $txt insert insert [string repeat " " [expr $indent_levels($txt) * 2]]
    }

  }
  
  ######################################################################
  # This procedure is called whenever the insertion cursor moves to a
  # new spot via keyboard traversal or a left button click.
  proc update_indent_level {txt} {
  
    variable indent_levels
    
    # Get the current line
    set line [$txt get "insert linestart" insert]
    
    # First, get the indentation level of the current line
    regexp {^(\s*)} $line -> leading_whitespace
    set indent_levels($txt) [expr [string length $leading_whitespace] / 2]
    
    # Second, if we have a mismatched brace on the current line,
    # add an indent level to ourselves

    # If we are in a comment, do nothing
    if {[string first "#" $line] != -1} {
      return
    }
    
    set lcount 0
    set rcount 0
    
    # Count the number of left braces in the current line
    set index 0
    while {[set index [string first "\{" $line $index]] != -1} {
      incr lcount
      incr index
    }
    
    # Count the number of right braces in the current line, if necessary
    if {$lcount > 0} {
      set index 0
      while {[set index [string first "\}" $line $index]] != -1} {
        incr rcount
        incr index
      }
    }
    
    # If the left count is greater then the right count, increment the
    # indentation level
    if {$lcount > $rcount} {
      incr indent_levels($txt)
    }
  
  }
  
}
