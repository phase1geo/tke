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
    
    # Load the snippet files into memory
    foreach file [glob -nocomplain -directory $snippets_dir *.snippets] {
      load_file $file
      launcher::register "Snippets: Edit [file tail $file] snippets" "gui::add_file end $file"
    }
    
    launcher::register "Snippets: Create new snippets file" "snippets::add_new_snippet_file"
    
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
            set snippets($sfile,$name) [parse_snippet $snippet]
            set snippet    ""
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
    set from_start 0
    set linenum    0
    set last_char  ""
    set sub_string ""
    set raw_string ""
    set tabs       [list]
    set dynamics   [list]
    
    set i 0
    while {$i < [string length $snippet]} {
      set char [string index $snippet $i]
      if {!$in_escape && !$in_tick && ($char eq "\$")} {
        incr in_dollar
      } elseif {($last_char eq "\$") && [regexp {^(\d+)} [string range $snippet $i end] -> number]} {
        lappend tabs [list snippet_mark_$number $from_start [expr $from_start + 1]]
        incr i [string length $number]
      } elseif {($last_char eq "\$") && ($char eq "\{") && \
                [regexp {^(\{(\d+)\s*:\s*([^\}]+))} [string range $snippet $i end] -> whole_string number dflt_string]} {
        set dflt_string [string trim $dflt_string]
        append raw_string $dflt_string
        lappend tabs [list snippet_sel_$number $from_start [expr $from_start + [string length $dflt_string]]]
        incr i [string length $whole_string]
        incr from_start [string length $dflt_string]
      } elseif {!$in_escape && ($char eq "`")} {
        if {$in_tick} {
          set in_tick 0
          lappend dynamics [list command $sub_string $from_start]
        } else {
          set in_tick    1
          set sub_string ""
        }
      } elseif {!$in_escape && ($char eq "\\")} {
        set in_escape 1
      } elseif {$in_tick} {
        append sub_string $char
        set in_escape 0
      } else {
        append raw_string $char
        set in_escape 0
        incr from_start
      }
      set last_char $char
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
      if {[snippets::handle_tab %W]} {
        break
      }
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
    
    # Perform indentation formatting for the raw string and insert it into
    # the text widget at the current insertion point.
    $txt insert insert [set formatted [indent::format_string $txt $snip(raw_string)]]
    
    # Create the tab point selection tags
    foreach tab $snip(tabs) {
      $txt tag add [lindex $tab 0] "$insert_index+[lindex $tab 1]c" "$insert_index+[lindex $tab 2]c"
      set within($txt) 1
    }
    
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
    
    # Remove the selection
    $txt tag remove sel 1.0 end
    
    # Find the current tab point tag
    if {[llength [set range [$txt tag ranges snippet_sel_$tabpoints($txt)]]] == 2} {
      $txt tag add sel {*}$range
      $txt tag delete snippet_sel_$tabpoints($txt)
      $txt mark set insert [lindex $range 1]
    } elseif {[llength [set range [$txt tag ranges snippet_mark_$tabpoints($txt)]]] == 2} {
      $txt mark set insert [lindex $range 0]
      $txt tag delete snippet_mark_$tabpoints($txt)
    } elseif {[llength [set range [$txt tag ranges snippet_mark_0]]] == 2} {
      $txt mark set insert [lindex $range 0]
      $txt tag delete snippet_mark_0
    }
    
    puts "END"
    
  }
  
  ######################################################################
  # Prompts the user for the name of the snippets group, creates a
  # file in the ~/.tke/snippets directory based on its name, and makes
  # this file editable.
  proc add_new_snippet_file {} {
  
    variable snippets_dir
    
    toplevel     .snipwin
    wm title     .snipwin "Create new snippet file"
    wm transient .snipwin .
    wm resizable .snipwin 0 0
    
    ttk::frame .snipwin.f
    ttk::label .snipwin.f.l -text "Name:"
    ttk::entry .snipwin.f.e
    
    bind .snipwin.f.e <Return> {
      .snipwin.bf.ok invoke
    }
    
    pack .snipwin.f.l -side left -padx 2 -pady 2
    pack .snipwin.f.e -side left -padx 2 -pady 2
    
    ttk::frame .snipwin.bf
    ttk::button .snipwin.bf.ok -text "OK" -width 6 -command {
      set sfname [file join $snippets::snippets_dir [.snipwin.f.e get].snippets]
      exec touch $sfname
      gui::add_file end $sfname
      destroy .snipwin
    }
    ttk::button .snipwin.bf.cancel -text "Cancel" -width 6 -command {
      destroy .snipwin
    }
    
    pack .snipwin.bf.cancel -side right -padx 2 -pady 2
    pack .snipwin.bf.ok     -side right -padx 2 -pady 2
    
    pack .snipwin.f  -fill x
    pack .snipwin.bf -fill x
    
    # Position the window in the center of the main window
    wm withdraw .snipwin
    update idletasks
    set x [expr (([winfo width  .] / 2) - ([winfo reqwidth  .snipwin] / 2)) + [winfo x .]]
    set y [expr (([winfo height .] / 4) - ([winfo reqheight .snipwin] / 2)) + [winfo y .]]
    if {$x < 0} {
      set x 0
    }
    if {$y < 0} {
      set y 0
    }
    wm geometry  .snipwin +$x+$y
    wm deiconify .snipwin

    # Get current focus and grab
    set old_focus [focus]
    set old_grab  [grab current .snipwin]
    if {$old_grab ne ""} {
      set grab_status [grab status $old_grab]
    }

    # Make sure the entry field is given focus
    focus .snipwin.f.e

    # Wait for the window to be destroyed
    tkwait window .snipwin

    # Reset the original focus and grab
    catch { focus $old_focus }
    if {$old_grab ne ""} {
      if {$grab_status ne "global"} {
        grab $old_grab
      } else {
        grab -global $old_grab
      }
    }
    
  }
  
}
