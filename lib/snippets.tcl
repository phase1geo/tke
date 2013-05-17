# Name:    snippets.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace containing functionality to support snippets

namespace eval snippets {
  
  variable snippets_dir [file join $::tke_home snippets]

  array set widgets  {}
  array set snippets {}
  array set within   {}
  
  ######################################################################
  # Loads the snippet information.
  proc load {} {
  
    variable snippets_dir
    
    # Load the snippet files into memory
    foreach file [glob -nocomplain -directory $snippets_dir *.snippets] {
      load_file $file
      launcher::register "Snippets: Edit [file tail $file] snippets" "gui::add_file end $file"
    }
    
    launcher::register "Snippets: Create new snippets file" "gui::add_new_file end"
    
  }
  
  ######################################################################
  # Load the snippets file.
  proc load_file {sfile} {
    
    variable snippets
    
    if {![catch "open $sfile r" rc]} {
      
      # Read the contents of the snippets file
      set contents [read $rc]
      close $rc
      
      # Clear the snippets for the given file
      array unset snippets $sfile,*
     
      # Do a quick parse of the snippets file
      foreach line [split $contents \n] {
        if {[regexp {^\s*snippet\s+(\w+)} $line -> name]} {
          set in_snippet 1
          set snippet    ""
        } elseif {$in_snippet} {
          if {[regexp {^\t(.*)$} $line -> txt]} {
            append snippet "[string trim $txt]\n"
          } else {
            set in_snippet 0
            set snippet    ""
            lappend snippets($sfile,$name) [parse_snippet $snippet]
            array set snip $snippets($sfile,$name)
            launcher::register "Snippet: $name: [string range $snip(raw_string) 0 30]" \
              [list snippets::insert_snippet_into_current $snippets($sfile,$name)] 
          }
        }
        
      }
      
    }
    
  }
  
  ######################################################################
  # Returns a list array containing the information obtained from parsing
  # the given snippet.
  proc parse_snippet {snippet} {
    
    set in_dollar  0
    set in_tick    0
    set in_escape  0
    set raw_string ""
    set from_start 0
    set sub_string ""
    
    for {set i 0} {$i < [string length $snippet]} {incr i} {
      set char [string index $snippet $i]
      if {!$in_escape && !$in_tick && ($char eq "\$")} {
        incr in_dollar
      } elseif {!$in_escape && ($char eq "`")} {
        if {$in_tick} {
          set in_tick 0
          
        } else {
          set in_tick    1
          set sub_string ""
        }
      } elseif {!$in_escape && ($char eq "\\")} {
        set in_escape 1
      } elseif {($char eq " ") || ($char eq "\t") || ($char eq "\n")} {
        if {$in_dollar} {
          # FIXME
        }
      } elseif {($last_char eq "\$") && ($char eq "\{")} {
      } elseif {$in_tick} {
        append sub_string $char
        set in_escape 0
      } else {
        append raw_string $char
        set in_escape 0
        incr from_start
      }
      set last_char $char
    }     
    
  }
  
  ######################################################################
  # Adds the text widget bindings.
  proc add_bindings {txt} {
    
    variable within
    
    # Initialize the within array
    set within($txt) 0
    
    # Bind whitespace
    bind snippet$txt <Key-space> "snippets::check_snippet $txt"
    bind snippet$txt <Tab>       "snippets::handle_tab $txt"
    bind snippet$txt <Return>    "snippets::check_snippet $txt"
    
    bindtags $txt.t [linsert [bindtags $txt.t] 3 snippet$txt]
    
  }
  
  ######################################################################
  # Checks the text widget to see if a snippet name was just typed in
  # the text widget.  If it was, delete the string and replace it with
  # the snippet string.
  proc check_snippet {txt} {
    
    variable snippets
    variable within
    
    # Get the last word
    set last_word [string trim [$txt get "insert-1c wordstart" "insert-1c wordend"]]
    
    # If the last word is not a valid word, stop now
    if {![regexp {^[a-zA-Z0-9_]$} $last_word]} {
      return
    }
    
    # If the snippet exists, perform the replacement.
    if {[llength [set snippet [array names snippets *,$last_word]]] == 1} {
      set within($txt) 1
      insert_snippet $txt $snippets($snippet)
    }
    
  }
  
  ######################################################################
  # Inserts the given snippet into the text widget, adhering to indentation.
  proc insert_snippet {txt snippet} {
    
  }
  
  ######################################################################
  # Inserts the given snippet into the current text widget, adhering to
  # indentation rules.
  proc insert_snippet_into_current {snippet} {
    
    insert_snippet [gui::current_txt] $snippet
    
  }
  
  ######################################################################
  # Handles a tab insertion
  proc handle_tab {txt} {
    
    variable within
    
    if {$within($txt)} {
      traverse_snippet $txt
    } else {
      check_snippet $txt
    }
    
  }
  
  ######################################################################
  # Moves the insertion cursor or selection to the next position in the
  # snippet.
  proc traverse_snippet {txt} {
    
  }
  
}
