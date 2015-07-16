# Name:    snippets.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace containing functionality to support snippets

namespace eval snippets {

  source [file join $::tke_dir lib ns.tcl]

  variable snippets_dir [file join $::tke_home snippets]

  array set widgets    {}
  array set snippets   {}
  array set timestamps {}
  array set within     {}

  ######################################################################
  # Loads the snippet information.
  proc load {} {

    variable snippets_dir

    # If the snippets directory does not exist, create it
    if {![file exists $snippets_dir]} {
      file mkdir $snippets_dir
    }

  }

  ######################################################################
  # Reloads the current snippet.
  proc reload_snippets {} {

    # Get the current language
    set language [syntax::get_current_language [gui::current_txt $tid]]

    # Reload the snippet file for the current language
    set_language $language

  }

  ######################################################################
  # Load the snippets file.
  proc set_language {language} {

    variable snippets_dir
    variable snippets
    variable timestamps

    # Remove all of the current snippets
    array unset snippets current,*

    # Remove any launcher commands that would be associated with this file
    [ns launcher]::unregister [msgcat::mc "Snippet: *"]

    foreach lang [list user $language] {

      # Create language-specific snippets filename if it exists
      if {[file exists [set sfile [file join $snippets_dir $lang.snippets]]]} {

        # Get the file status
        file stat $sfile fstat

        # Check to see if the language file timestamp has been updated
        if {![info exists timestamps($lang)] || ($fstat(mtime) > $timestamps($lang))} {
          set timestamps($lang) $fstat(mtime)
          parse_snippets $lang
        }

        # Add the files to the current snippets array
        foreach name [array names snippets $lang,*] {
          set snippets(current,[lindex [split $name ,] 1]) $snippets($name)
        }

      }

    }

  }

  ######################################################################
  # Parses snippets for the given language.
  proc parse_snippets {language} {

    variable snippets_dir
    variable snippets

    # Clear the snippets for the given file
    array unset snippets $language,*

    # Create snippet file name
    set sfile [file join $snippets_dir $language.snippets]

    if {![catch { open $sfile r } rc]} {

      # Read the contents of the snippets file
      set contents [read $rc]
      close $rc

      set in_snippet 0

      # Do a quick parse of the snippets file
      foreach line [concat [split $contents \n] ""] {
        if {$in_snippet} {
          if {[regexp {^\t(.*)$} $line -> txt]} {
            append snippet "[string trimright $txt]\n"
          } else {
            set in_snippet 0
            set snippets($language,$name) [string range $snippet 0 end-1]
          }
        }
        if {[regexp {^snippet\s+(\w+)} $line -> name]} {
          set in_snippet 1
          set snippet    ""
        }

      }

    }

    if {$language eq "snippets"} {
      set_language snippets
    }

  }

  ######################################################################
  # Adds the text widget bindings.
  proc add_bindings {txt} {

    variable within

    # Initialize the within array
    set within($txt.t) 0

    # Bind whitespace
    bind snippet$txt <Key-space> "if {\[[ns snippets]::check_snippet %W %K\]} { break }"
    bind snippet$txt <Return>    "if {\[[ns snippets]::check_snippet %W %K\]} { break }"
    bind snippet$txt <Tab>       "if {\[[ns snippets]::handle_tab %W\]} { break }"

    bindtags $txt.t [linsert [bindtags $txt.t] 3 snippet$txt]

  }

  ######################################################################
  # Handles a tab key event.
  proc handle_tab {W} {

    if {![tab_clicked $W]} {
      if {![[ns vim]::in_vim_mode $W] && ![[ns syntax]::get_tabs_allowed [winfo parent $W]]} {
        $W insert insert [string repeat " " [[ns preferences]::get Editor/SpacesPerTab]]
        return 1
      }
    } else {
      return 1
    }

    return 0

  }

  ######################################################################
  # Checks the text widget to see if a snippet name was just typed in
  # the text widget.  If it was, delete the string and replace it with
  # the snippet string.
  proc check_snippet {txt keysym} {

    variable snippets
    variable within
    variable tabpoints

    # If the given key symbol is not one of the snippet completers, stop now
    if {[lsearch [[ns preferences]::get Editor/SnippetCompleters] [string tolower $keysym]] == -1} {
      return 0
    }

    # Get the last word
    set last_word [string trim [$txt get "insert-1c wordstart" "insert-1c wordend"]]

    # If the last word is not a valid word, stop now
    if {![regexp {^[a-zA-Z0-9_]+$} $last_word]} {
      return 0
    }

    # If the snippet exists, perform the replacement.
    if {[info exists snippets(current,$last_word)]} {
      return [insert_snippet $txt $snippets(current,$last_word)]
    }

    return 0

  }

  ######################################################################
  # Inserts the given snippet contents at the current insertion point.
  proc insert_snippet {txt snippet} {

    variable tabpoints

    # Clear any residual tabstops
    clear_tabstops $txt

    # Initialize tabpoints
    set tabpoints($txt) 1

    # Call the snippet parser
    if {[set result [parse_snippet $txt $snippet]] ne ""} {

      # Delete the last_word
      $txt delete "insert-1c wordstart" "insert-1c wordend"

      # Insert the text
      puts $result
      $txt insert insert {*}$result

      # Traverse the inserted snippet
      traverse_snippet $txt

      # Make sure that the whitespace character is not inserted into the widget
      return 1

    }

    return 0

  }

  ######################################################################
  # Inserts the given snippet into the current text widget, adhering to
  # indentation rules.
  proc insert_snippet_into_current {tid snippet} {

    insert_snippet [gui::current_txt $tid].t $snippet

  }

  ######################################################################
  # Parses the given snippet string and returns
  proc parse_snippet {txt str} {

    # Flush the parsing buffer
    SNIP__FLUSH_BUFFER

    # Insert the string to scan
    snip__scan_string $str

    # Initialize some values
    set ::snip_txt    $txt
    set ::snip_begpos 0
    set ::snip_endpos 0

    # Parse the string
    if {[catch { snip_parse } rc] || ($rc != 0)} {
      puts "ERROR-snippet: $::snip_errmsg ($rc)"
      puts -nonewline "line: "
      puts [string map {\n {}} $str]
      puts "      $::snip_errstr"
      puts "$::errorInfo"
      return ""
    }

    return $::snip_value

  }

  ######################################################################
  # Creates a tab stop or tab mirror.
  proc set_tabstop {txt index {default_value ""}} {

    variable tabpoints
    variable within

    # Indicate that the text widget contains a tabstop
    set within($txt) 1

    # Set the lowest tabpoint value
    if {($index > 0) && ($tabpoints($txt) > $index)} {
      set tabpoints($txt) $index
    }

    # Get the list of tags
    set tags [$txt tag names]

    if {[lsearch -regexp $tags snippet_(sel|mark)_$index] != -1} {
      if {[lsearch $tags snippet_mirror_$index] == -1} {
        $txt tag configure snippet_mirror_$index -elide 1
      }
      return "snippet_mirror_$index"
    } else {
      if {$default_value eq ""} {
        $txt tag configure snippet_mark_$index -elide 1
        return "snippet_mark_$index"
      } else {
        $txt tag configure snippet_sel_$index -background blue
        return "snippet_sel_$index"
      }
    }

  }

  ######################################################################
  # Returns the value of the given tabstop.
  proc get_tabstop {txt index} {

    variable tabvals

    if {[info exists tabvals($txt,$index)]} {
      return $tabvals($txt,$index)
    }

    return ""

  }

  ######################################################################
  # Clears any residual tabstops embedded in code.
  proc clear_tabstops {txt} {

    if {[llength [set tabstops [lsearch -inline -all -glob [$txt tag names] snippet_*]]] > 0} {
      $txt tag delete {*}$tabstops
    }

  }

  ######################################################################
  # Handles a tab insertion
  proc tab_clicked {txt} {

    variable within

    if {$within($txt)} {
      traverse_snippet $txt
      return 1
    } else {
      return [check_snippet $txt Tab]
    }

  }

  ######################################################################
  # Moves the insertion cursor or selection to the next position in the
  # snippet.
  proc traverse_snippet {txt} {

    variable tabpoints
    variable within
    variable tabstart
    variable tabvals

    if {[info exists tabpoints($txt)]} {

      # Update any mirrored tab points
      if {[info exists tabstart($txt)]} {
        set index [expr $tabpoints($txt) - 1]
        set tabvals($txt,$index) [$txt get $tabstart($txt) insert]
        foreach {endpos startpos} [lreverse [$txt tag ranges snippet_mirror_$index]] {
          set str [parse_snippet $txt [$txt get $startpos $endpos]]
          $txt delete $startpos $endpos
          $txt insert $startpos {*}$str
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
        $txt delete {*}$range
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

  }

  ######################################################################
  # If a snippet file does not exist for the current language, creates
  # an empty snippet file in the user's local snippet directory.  Opens
  # the snippet file for editing.
  proc add_new_snippet {tid type} {

    variable snippets_dir

    # Set the language
    set language [expr {($type eq "user") ? "user" : [syntax::get_current_language [gui::current_txt $tid]]}]

    # If the snippet file does not exist, create the file
    if {![file exists [set fname [file join $snippets_dir $language.snippets]]]} {
      if {![catch { open $fname w } rc]} {
        close $rc
      }
    }

    # Add the snippet file to the editor
    gui::add_file end $fname -sidebar 0 -savecommand [list snippets::set_language $language]

  }

  ######################################################################
  # Returns the list of snippets
  proc get_current_snippets {} {

    variable snippets

    set names [list]

    foreach name [array names snippets current,*] {
      lappend names [list [lindex [split $name ,] 1] $snippets($name)]
    }

    return $names

  }

  ######################################################################
  # Displays all of the available snippets in the current editor in the
  # command launcher.
  proc show_snippets {} {

    # Add temporary registries to launcher
    set i 0
    foreach snippet [get_current_snippets] {
      lassign $snippet name value
      array set snip $value
      launcher::register_temp "`SNIPPET:$name" \
        [list [ns snippets]::insert_snippet_into_current {} $value] \
        $name $i [list snippets::add_detail $snip(snippet)]
      incr i
    }

    # Display the launcher in SNIPPET: mode
    launcher::launch "`SNIPPET:" 1

  }

  ######################################################################
  # Adds the given detail
  proc add_detail {str txt} {

    $txt insert end $str

  }

}

