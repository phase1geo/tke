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
    
    # If the snippets directory does not exist, create it
    if {![file exists $snippets_dir]} {
      file mkdir $snippets_dir
    }
    
    launcher::register "Snippets: Add snippet"         "snippets::add_new_snippet"
    launcher::register "Snippets: Reload all snippets" "snippets::load_directory"
    
  }
  
  ######################################################################
  # Load the snippets file.
  proc set_language {language} {
    
    variable snippets_dir
    variable snippets
    
    # Create language-specific snippets filename
    set sfile [file join $snippets_dir $language.snippets]

    # Clear the snippets for the given file
    array unset snippets $language,*
      
    # Remove any launcher commands that would be associated with this file
    launcher::unregister "Snippet: *"

    if {![catch "open $sfile r" rc]} {
      
      # Read the contents of the snippets file
      set contents [read $rc]
      close $rc
      
      set in_snippet 0
     
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
            set snippets($language,$name) [parse_snippet [string range $snippet 0 end-1]]
            set snippet    ""
            array set snip $snippets($language,$name)
            launcher::register "Snippet: $name: [string range $snip(raw_string) 0 30]" \
              [list snippets::insert_snippet_into_current $snippets($language,$name)] 
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
    set from_start 0
    set linenum    0
    set shell_str  ""
    set raw_string ""
    set tabs       [list]
    set dynamics   [list]
    
    set i 0
    while {$i < [string length $snippet]} {
      
      # Get the current character
      set char [string index $snippet $i]
      
      # We have found a dollar sign
      if {!$in_escape && !$in_tick && ($char eq "\$")} {

        # Handle a tab stop
        if {[regexp {^(\d+)} [string range $snippet [expr $i + 1] end] -> number]} {
          if {![info exists tabstop_string($number)]} {
            lappend tabs [list snippet_mark_$number $from_start [expr $from_start + 1]]
          } else {
            lappend tabs [list snippet_mirror_$number $from_start [expr $from_start + [string length $tabstop_string($number)]]]
            append raw_string $tabstop_string($number)
            incr from_start [string length $tabstop_string($number)]
          }
          incr i [string length $number]
          
        # Handle a single variable substitution
        } elseif {[regexp {^(\w+)} [string range $snippet [expr $i + 1] end] -> varname]} {
          
          lappend dynamics [list var $varname $from_start ""]
          incr i [string length $varname]
          
        } else {
          incr i
          
          # Handle a more complex dollar operator
          if {[string index $snippet $i] eq "\{"} {
            incr in_dollar
            incr i
          
            # Start handling a complex tab stop
            if {[regexp {^(\d+):} [string range $snippet $i end] -> number]} {
              set dollar($in_dollar,string)  ""
              set dollar($in_dollar,start)   $from_start
              set dollar($in_dollar,tabstop) $number
              incr i [string length $number]
              
            # Handle a tab stop mirror
            } elseif {[regexp {^(\d+)/(.*)/(.*)/(.*)} [string range $snippet $i end] -> number expr format opts]} {
              set dollar($in_dollar,string)  ""
              set dollar($in_dollar,start)   $from_start
              set dollar($in_dollar,tabstop) $number
              set dollar($in_dollar,regsub)  [list $expr $format $opts]
              incr i [expr [string length $number] + [string length $expr] + [string length $format] + [string length $opts] + 3]
              
            # Start handling a complex variable substitution  
            } elseif {[regexp {^(\w+):} [string range $snippet $i end] -> varname]} {
              set dollar($in_dollar,string)  ""
              set dollar($in_dollar,start)   $from_start
              set dollar($in_dollar,varname) $varname
              incr i [string length $varname]
              
            # Handle a variable with regular expression substitution
            } elseif {[regexp {^(\w+)/(.*)/(.*)/(.*)} [string range $snippet $i end] -> varname expr format opts]} {
              set dollar($in_dollar,string)  ""
              set dollar($in_dollar,start)   $from_start
              set dollar($in_dollar,varname) $varname
              set dollar($in_dollar,regsub)  [list $expr $format $opts]
              incr i [expr [string length $varname] + [string length $expr] + [string length $format] + [string length $opts] + 3]
            }
            
          }
          
        }
        
      # We have found an unescaped right brace
      } elseif {$in_dollar && !$in_escape && ($char eq "\}")} {
        if {[info exists dollar($in_dollar,varname)]} {
          lappend dynamics [list var $dollar($in_dollar,varname) $dollar($in_dollar,start) $dollar($in_dollar,string)]
        } else {
          set tabstop_string($dollar($in_dollar,tabstop)) $dollar($in_dollar,string)
          lappend tabs [list snippet_sel_$dollar($in_dollar,tabstop) $dollar($in_dollar,start) [expr $dollar($in_dollar,start) + [string length $dollar($in_dollar,string)]]]
        }
        array unset dollar $in_dollar,*
        incr in_dollar -1
        
      # We have found a tick, se we are either starting or stopping a shell command
      } elseif {!$in_escape && ($char eq "`")} {
        if {$in_tick} {
          set in_tick 0
          lappend dynamics [list cmd $shell_str $from_start ""]
        } else {
          set in_tick    1
          set sub_string ""
        }
        
      # We have found an escape character
      } elseif {!$in_escape && ($char eq "\\")} {
        set in_escape 1
        
      # We are in a shell command
      } elseif {$in_tick} {
        append shell_str $char
        set in_escape 0
        
      # We are in a dollar sign expression
      } elseif {$in_dollar} {
        append dollar($in_dollar,string) $char
        append raw_string $char
        set in_escape 0
        incr from_start
        
      # This is just a raw expression
      } else {
        append raw_string [expr {($char eq "\$") ? "\$" : $char}]
        set in_escape 0
        incr from_start
      }

      incr i
      
    }
    
    return [list raw_string $raw_string tabs $tabs dynamics $dynamics]   
    
  }
  
  ######################################################################
  # Adds the text widget bindings.
  proc add_bindings {txt} {
    
    variable within
    
    # Initialize the within array
    set within($txt.t) 0
    
    # Bind whitespace
    bind snippet$txt <Key-space> {
      if {[snippets::check_snippet %W]} {
        break
      }
    }
    bind snippet$txt <Return> {
      if {[snippets::check_snippet %W]} {
        break
      }
    }
    bind snippet$txt <Tab> {
      if {![snippets::handle_tab %W]} {
        if {![vim::in_vim_mode %W]} {
          %W insert insert [string repeat " " $preferences::prefs(Editor/SpacesPerTab)]
          %W mark set insert "insert + $preferences::prefs(Editor/SpacesPerTab) c"
        }
      }
      break
    }
    
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
    if {![regexp {^[a-zA-Z0-9_]+$} $last_word]} {
      return 0
    }
    
    # If the snippet exists, perform the replacement.
    if {[llength [set snippet [array names snippets *,$last_word]]] == 1} {
      
      # Delete the last_word
      $txt delete "insert-1c wordstart" "insert-1c wordend"
      
      # Insert the new text in its place
      insert_snippet $txt $snippets($snippet)
      
      # Make sure that the whitespace character is not inserted into the widget
      return 1
      
    }
    
    return 0
    
  }
  
  ######################################################################
  # Inserts the given snippet into the text widget, adhering to indentation.
  proc insert_snippet {txt snippet} {
  
    variable tabpoints
    variable within
    
    # Assign the snippet array information to an array
    array set snip $snippet
    
    # Initialize the tabpoints counter
    set tabpoints($txt) 1
    set within($txt)    0
    set insert_index    [$txt index insert]
    set current_line    [$txt get "insert linestart" "insert lineend"]
    
    # Insert the raw string into the text widget
    [winfo parent $txt] insert insert $snip(raw_string)

    # Create a tag for the inserted text
    $txt tag add snippet_raw $insert_index "$insert_index+[string length $snip(raw_string)]c"
    
    # Create the tab point selection tags
    foreach tab $snip(tabs) {
      $txt tag add [lindex $tab 0] "$insert_index+[lindex $tab 1]c" "$insert_index+[lindex $tab 2]c"
      set within($txt) 1
    }

    # Insert the dynamics into the raw string
    foreach dynamic [lreverse $snip(dynamics)] {
      if {[lindex $dynamic 0] eq "var"} {
        switch [lindex $dynamic 1] {
          CLIPBOARD     { set str [expr {![catch "clipboard get" rc] ? $rc : ""}] }
          CURRENT_LINE  { set str $current_line }
          CURRENT_WORD  { set str [$txt get "insert wordstart" "insert wordend"] }
          DIRECTORY     { set str [file dirname [gui::current_filename]] }
          FILEPATH      { set str [gui::current_filename] }
          FILENAME      { set str [file tail [gui::current_filename]] }
          LINE_INDEX    { set str [lindex [split [$txt index insert] .] 1] }
          LINE_NUMBER   { set str [lindex [split [$txt index insert] .] 0] }
          CURRENT_DATE  { set str [clock format [clock seconds] -format "%m/%d/%Y"] }
          default       { set str "" }
        }
      } elseif {[lindex $dynamic 0] eq "cmd"} {
        if {[catch "exec sh -c [lindex $dynamic 1]" str]} {
          set str ""
        }
      }
      if {$str ne ""} {
        $txt replace "$insert_index+[lindex $dynamic 2]c" "$insert_index+[expr [lindex $dynamic 2] + [string length [lindex $dynamic 3]]]c" $str snippet_raw
      }
    }

    # Indent the text
    indent::format_text $txt [$txt index snippet_raw.first] [$txt index snippet_raw.last]

    # Delete the snippet_raw tag
    $txt tag delete snippet_raw
    
    # Start to traverse the snippet
    traverse_snippet $txt
    
  }
  
  ######################################################################
  # Inserts the given snippet into the current text widget, adhering to
  # indentation rules.
  proc insert_snippet_into_current {snippet} {
    
    insert_snippet [gui::current_txt].t $snippet
    
  }
  
  ######################################################################
  # Handles a tab insertion
  proc handle_tab {txt} {
    
    variable within
    
    if {$within($txt)} {
      traverse_snippet $txt
      return 1
    } else {
      return [check_snippet $txt]
    }
    
  }
  
  ######################################################################
  # Moves the insertion cursor or selection to the next position in the
  # snippet.
  proc traverse_snippet {txt} {
  
    variable tabpoints
    variable within
    variable tabstart
    
    # Update any mirrored tab points
    if {[info exists tabstart($txt)]} {
      set mirrored_value [$txt get $tabstart($txt) insert]
      foreach {endpos startpos} [lreverse [$txt tag ranges snippet_mirror_[expr $tabpoints($txt) - 1]]] {
        $txt delete $startpos $endpos
        $txt insert $startpos $mirrored_value
      }
    }

    # Remove the selection
    $txt tag remove sel 1.0 end

    # Find the current tab point tag
    if {[llength [set range [$txt tag ranges snippet_sel_$tabpoints($txt)]]] == 2} {
      $txt tag add sel {*}$range
      $txt tag delete snippet_sel_$tabpoints($txt)
      $txt mark set insert [lindex $range 1]
      set tabstart($txt) [lindex $range 0]
    } elseif {[llength [set range [$txt tag ranges snippet_mark_$tabpoints($txt)]]] == 2} {
      $txt mark set insert [lindex $range 0]
      $txt tag delete snippet_mark_$tabpoints($txt)
      set tabstart($txt) [lindex $range 0]
    } elseif {[llength [set range [$txt tag ranges snippet_mark_0]]] == 2} {
      $txt mark set insert [lindex $range 0]
      $txt tag delete snippet_mark_0
      set tabstart($txt) [lindex $range 0]
      set within($txt)   0
    }
    
    # Increment the tabpoint
    incr tabpoints($txt)
    
  }
  
  ######################################################################
  # If a snippet file does not exist for the current language, creates
  # an empty snippet file in the user's local snippet directory.  Opens
  # the snippet file for editing.
  proc add_new_snippet {} {
    
    variable snippets_dir
    
    # Get the current language
    set language [syntax::get_current_language]
    
    # Get the snippet file name
    set fname [file join $::tke_home snippets $language.snippets]
    
    # If the snippet file does not exist, create the file
    if {![file exists $fname]} {
      touch $fname
    }
    
    # Add the snippet file to the editor
    gui::add_file end $fname [list snippets::set_language $language]
    
  }
  
}
