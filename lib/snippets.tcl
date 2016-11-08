# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:    snippets.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace containing functionality to support snippets
######################################################################

namespace eval snippets {

  source [file join $::tke_dir lib ns.tcl]

  array set widgets    {}
  array set snippets   {}
  array set timestamps {}
  array set within     {}
  array set expandtabs {}

  set snippets_dir [file join $::tke_home snippets]

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
  proc reload_snippets {tid} {

    # Get the current language
    set language [syntax::get_language [gui::current_txt $tid]]

    # Reload the snippet file for the current language
    set_language $language

  }

  ######################################################################
  # Load the snippets file.
  proc set_language {language {dummy 0}} {

    variable snippets
    variable timestamps
    variable snippets_dir

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

      }

    }

  }

  ######################################################################
  # Sets the expandtabs memory for the given text widget to the given value.
  proc set_expandtabs {txt val} {

    variable expandtabs

    set expandtabs($txt.t) $val

  }

  ######################################################################
  # Parses snippets for the given language.
  proc parse_snippets {language} {

    variable snippets
    variable snippets_dir

    # Clear the snippets for the given file
    array unset snippets $language,*

    # Create snippet file name
    set sfile [file join $snippets_dir $language.snippets]

    if {![catch { open $sfile r } rc]} {

      # Read the contents of the snippets file
      set contents [read $rc]
      close $rc

      set in_snippet 0
      set tab_seen   0

      # Do a quick parse of the snippets file
      foreach line [concat [split $contents \n] ""] {
        if {$in_snippet} {
          if {[regexp {^\t(.*)$} $line -> txt]} {
            append snippet "[string trimright $txt]\n"
            set tab_seen 1
          } elseif {([string trim $line] eq "endsnippet") || (([string trim $line] eq "") && $tab_seen)} {
            set in_snippet 0
            set snippets($language,$name) [string range $snippet 0 end-1]
          } else {
            append snippet "[string trimright $line]\n"
          }
        }
        if {[regexp {^snippet\s+(\w+)} $line -> name]} {
          set in_snippet 1
          set snippet    ""
          set tab_seen   0
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
    variable expandtabs

    # Initialize the within array
    set within($txt.t)     0
    set expandtabs($txt.t) [expr [[ns syntax]::get_tabs_allowed $txt] ? 0 : 1]

    # Bind whitespace
    bind snippet$txt <Key-space> "if {\[[ns snippets]::check_snippet %W %K\]} { break }"
    bind snippet$txt <Return>    "if {\[[ns snippets]::check_snippet %W %K\]} { break }"
    bind snippet$txt <Tab>       "if {\[[ns snippets]::handle_tab %W\]} { break }"

    bindtags $txt.t [linsert [bindtags $txt.t] 3 snippet$txt]

  }

  ######################################################################
  # Handles a tab key event.
  proc handle_tab {txtt} {

    variable expandtabs

    if {![tab_clicked $txtt]} {
      if {![[ns vim]::in_vim_mode $txtt] && $expandtabs($txtt)} {
        $txtt insert insert [string repeat " " [[ns indent]::get_tabstop $txtt]]
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
  proc check_snippet {txtt keysym} {

    variable snippets
    variable tabpoints

    # If the given key symbol is not one of the snippet completers, stop now
    if {[lsearch [[ns preferences]::get Editor/SnippetCompleters] [string tolower $keysym]] == -1} {
      return 0
    }

    # Get the last word
    set last_word [string trim [$txtt get "insert-1c wordstart" "insert-1c wordend"]]

    # Get the current language
    set lang [[ns utils]::get_current_lang [winfo parent $txtt]]

    # If the snippet exists, perform the replacement.
    foreach type [list $lang user] {
      if {[info exists snippets($type,$last_word)]} {
        return [insert_snippet $txtt $snippets($type,$last_word) -delrange [list "insert-1c wordstart" "insert-1c wordend"]]
      }
    }

    return 0

  }

  ######################################################################
  # Inserts the given snippet contents at the current insertion point.
  proc insert_snippet {txtt snippet args} {

    variable tabpoints

    array set opts {
      -delrange ""
      -traverse 1
    }
    array set opts $args

    # Clear any residual tabstops
    clear_tabstops $txtt

    # Initialize tabpoints
    set tabpoints($txtt) 1

    # Mark the change
    $txtt edit separator

    # Delete the last_word, if specified
    if {$opts(-delrange) ne ""} {
      $txtt delete {*}$opts(-delrange)
    }

    # Call the snippet parser
    if {[set result [parse_snippet $txtt $snippet]] ne ""} {

      # Get the snippet marks
      set marks [lsearch -glob -inline -all [$txtt tag names] snippet_*]

      # Add a $0 tabstop (if one was not specified)
      if {([llength $marks] > 0) && ([lsearch $marks snippet_mark_0] == -1)} {
        set_tabstop $txtt 0
        lappend result \$0 snippet_mark_0
      }

      # Get the insertion cursor
      set insert [$txtt index insert]

      # Insert the text
      $txtt insert insert {*}$result

      # Format the text to match indentation
      if {[[ns preferences]::get Editor/SnippetFormatAfterInsert]} {
        set datalen 0
        foreach {str tags} $result {
          incr datalen [string length $str]
        }
        indent::format_text $txtt $insert "$insert+${datalen}c"
      }

      # Traverse the inserted snippet
      if {$opts(-traverse)} {
        traverse_snippet $txtt
      }

    }

    # Adjust the cursor, if necessary
    vim::adjust_insert $txtt

    # Create a separator
    $txtt edit separator

    return 1

  }

  ######################################################################
  # Inserts the given snippet into the current text widget, adhering to
  # indentation rules.
  proc insert_snippet_into_current {tid snippet {delrange ""}} {

    insert_snippet [gui::current_txt $tid].t $snippet -delrange $delrange

  }

  ######################################################################
  # Parses the given snippet string and returns
  proc parse_snippet {txtt str} {

    # Flush the parsing buffer
    SNIP__FLUSH_BUFFER

    # Insert the string to scan
    snip__scan_string $str

    # Initialize some values
    set ::snip_txtt   $txtt
    set ::snip_begpos 0
    set ::snip_endpos 0

    # Parse the string
    if {[catch { snip_parse } rc] || ($rc != 0)} {
      display_error $str $::snip_errstr $::snip_errmsg
      return ""
    }

    return $::snip_value

  }

  ######################################################################
  # Creates a tab stop or tab mirror.
  proc set_tabstop {txtt index {default_value ""}} {

    variable tabpoints
    variable within

    # Indicate that the text widget contains a tabstop
    set within($txtt) 1

    # Set the lowest tabpoint value
    if {($index > 0) && ($tabpoints($txtt) > $index)} {
      set tabpoints($txtt) $index
    }

    # Get the list of tags
    set tags [$txtt tag names]

    if {[lsearch -regexp $tags snippet_(sel|mark)_$index] != -1} {
      if {[lsearch $tags snippet_mirror_$index] == -1} {
        $txtt tag configure snippet_mirror_$index -elide 1
      }
      return "snippet_mirror_$index"
    } else {
      if {$default_value eq ""} {
        $txtt tag configure snippet_mark_$index -elide 1
        return "snippet_mark_$index"
      } else {
        $txtt tag configure snippet_sel_$index -background blue
        return "snippet_sel_$index"
      }
    }

  }

  ######################################################################
  # Returns the value of the given tabstop.
  proc get_tabstop {txtt index} {

    variable tabvals

    if {[info exists tabvals($txtt,$index)]} {
      return $tabvals($txtt,$index)
    }

    return ""

  }

  ######################################################################
  # Clears any residual tabstops embedded in code.
  proc clear_tabstops {txtt} {

    variable tabvals

    # Delete all text that is tagged with a snippet tag
    foreach tabstop [lsearch -inline -all -glob [$txtt tag names] snippet_*] {
      foreach {start end} [$txtt tag ranges $tabstop] {
        $txtt fastdelete $start $end
      }
      $txtt tag delete $tabstop
    }

    array unset tabvals $txtt,*

  }

  ######################################################################
  # Handles a tab insertion
  proc tab_clicked {txtt} {

    variable within

    if {$within($txtt)} {
      traverse_snippet $txtt
      return 1
    } else {
      return [check_snippet $txtt Tab]
    }

  }

  ######################################################################
  # Moves the insertion cursor or selection to the next position in the
  # snippet.
  proc traverse_snippet {txtt} {

    variable tabpoints
    variable within
    variable tabstart
    variable tabvals

    if {[info exists tabpoints($txtt)]} {

      # Update any mirrored tab points
      if {[info exists tabstart($txtt)]} {
        set index [expr $tabpoints($txtt) - 1]
        set tabvals($txtt,$index) [$txtt get $tabstart($txtt) insert]
        foreach {endpos startpos} [lreverse [$txtt tag ranges snippet_mirror_$index]] {
          set str [parse_snippet $txtt [$txtt get $startpos $endpos]]
          $txtt fastdelete $startpos $endpos
          $txtt insert $startpos {*}$str
        }
      }

      # Remove the selection
      $txtt tag remove sel 1.0 end

      # Find the current tab point tag
      if {[llength [set range [$txtt tag ranges snippet_sel_$tabpoints($txtt)]]] == 2} {
        $txtt tag delete snippet_sel_$tabpoints($txtt)
        ::tk::TextSetCursor $txtt [lindex $range 1]
        $txtt tag add sel {*}$range
        set tabstart($txtt) [lindex $range 0]
      } elseif {[llength [set range [$txtt tag ranges snippet_mark_$tabpoints($txtt)]]] == 2} {
        $txtt fastdelete {*}$range
        ::tk::TextSetCursor $txtt [lindex $range 0]
        $txtt tag delete snippet_mark_$tabpoints($txtt)
        set tabstart($txtt) [lindex $range 0]
      } elseif {[llength [set range [$txtt tag ranges snippet_mark_0]]] == 2} {
        $txtt fastdelete {*}$range
        ::tk::TextSetCursor $txtt [lindex $range 0]
        $txtt tag delete snippet_mark_0
        set tabstart($txtt) [lindex $range 0]
      }

      # Increment the tabpoint
      incr tabpoints($txtt)

      # Clear the within indicator if we are out of tab stops
      if {([$txtt tag ranges snippet_sel_$tabpoints($txtt)]  eq "") && \
          ([$txtt tag ranges snippet_mark_$tabpoints($txtt)] eq "") && \
          ([$txtt tag ranges snippet_mark_0] eq "")} {
        set within($txtt) 0
      }

    }

  }

  ######################################################################
  # If a snippet file does not exist for the current language, creates
  # an empty snippet file in the user's local snippet directory.  Opens
  # the snippet file for editing.
  proc add_new_snippet {tid type} {

    variable snippets_dir

    # Set the language
    set language [expr {($type eq "user") ? "user" : [[ns utils]::get_current_lang [gui::current_txt $tid]]}]

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
    set lang  [[ns utils]::get_current_lang [[ns gui]::current_txt {}]]

    foreach type [list user $lang] {
      foreach name [array names snippets $type,*] {
        lappend names [list [lindex [split $name ,] 1] $snippets($name)]
      }
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
      launcher::register_temp "`SNIPPET:$name" \
        [list [ns snippets]::insert_snippet_into_current {} $value] \
        $name $i [list snippets::add_detail $value]
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

  ######################################################################
  # Displays the error information when a snippet parsing error is detected.
  proc display_error {snip_str ptr_str error_info} {

    if {![winfo exists .snipwin]} {

      toplevel     .snipwin
      wm title     .snipwin "Snippet Error"
      wm transient .snipwin .
      wm resizable .snipwin 0 0

      ttk::labelframe .snipwin.f -text "Error Information"
      text            .snipwin.f.t -wrap none -width 60 -relief flat -borderwidth 0 \
        -highlightthickness 0 \
        -background [utils::get_default_background] -foreground [utils::get_default_foreground] \
        -xscrollcommand { .snipwin.f.hb set } -yscrollcommand { .snipwin.f.vb set }
      ttk::scrollbar .snipwin.f.vb -orient vertical   -command { .snipwin.f.t xview }
      ttk::scrollbar .snipwin.f.hb -orient horizontal -command { .snipwin.f.t yview }

      grid rowconfigure    .snipwin.f 0 -weight 1
      grid columnconfigure .snipwin.f 0 -weight 1
      grid .snipwin.f.t  -row 0 -column 0 -sticky news
      grid .snipwin.f.vb -row 0 -column 1 -sticky ns
      grid .snipwin.f.hb -row 1 -column 0 -sticky ew

      ttk::frame  .snipwin.bf
      ttk::button .snipwin.bf.okay -style BButton -text "Close" -width 5 -command { destroy .snipwin }

      pack .snipwin.bf.okay -padx 2 -pady 2

      pack .snipwin.f  -fill both -expand yes
      pack .snipwin.bf -fill x

      # Make sure that the window is centered in the window
      ::tk::PlaceWindow .snipwin widget .

    } else {

      # Clear the text widget
      .snipwin.f.t configure -state normal
      .snipwin.f.t delete 1.0 end

    }

    # Insert the error information into the text widget
    foreach line [split $snip_str \n] {
      set ptr     [string range $ptr_str 0 [string length $line]]
      set ptr_str [string range $ptr_str [expr [string length $line] + 1] end]
      .snipwin.f.t insert end "$line\n"
      if {[string trim $ptr] ne ""} {
        .snipwin.f.t insert end "$ptr\n"
      }
    }
    .snipwin.f.t insert end "\n$error_info"
    .snipwin.f.t configure -state disabled
    .snipwin.f.t configure -height [expr {([set lines [.snipwin.f.t count -lines 1.0 end]] < 20) ? $lines : 20}]

  }

  ######################################################################
  # Perform snippet substitutions of the given text string.
  proc substitute {str lang} {

    # Returns the string if there are no snippets to expand
    if {![regexp {<tke:ExportString>.*</tke:ExportString>} $str]} {
      return $str
    }

    # Place an escape character before dollar signs and backticks
    set str [string map {\$ {\$} ` {\`}} $str]

    # Convert the string
    while {[regexp {^(.*)<tke:ExportString>(.*?)</tke:ExportString>(.*)$} $str -> pre snip post]} {
      set snip [string map {{\$} \$ {\`} `} $snip]
      set str "$pre$snip$post"
    }

    # Create a temporary editing buffer
    set tab [[ns gui]::add_buffer end temporary [list] -lang $lang -background 1]

    # Get the current text widget
    set txt [[ns gui]::get_info $tab tab txt]

    # Insert the content as a snippet
    [ns snippets]::insert_snippet $txt.t $str -traverse 0

    # Get the text
    set str [[ns gui]::scrub_text $txt]

    # Close the tab
    [ns gui]::close_tab {} $tab -keeptab 0 -check 0

    return $str

  }

  ######################################################################
  # Returns a list of snippet information from the given file.
  proc load_list {language} {

    variable snippets_dir
    variable snippets

    if {$language eq "Any"} {
      set language "user"
    }

    # Parse the snippets file
    parse_snippets $language

    # Configure the snippets into a list
    set items [list]
    foreach key [array names snippets $language,*] {
      lappend items [list [lindex [split $key ,] 1] $snippets($key)]
    }

    return $items

  }

  ######################################################################
  # Saves the given snippet items to the appropriate snippet file.
  proc save_list {items language} {

    variable snippets_dir

    if {$language eq "Any"} {
      set language "user"
    }

    if {![catch { open [file join $snippets_dir $language.snippets] w } rc]} {
      foreach item $items {
        lassign $item keyword snippet
        puts $rc "snippet $item"
        puts $rc $snippet
        puts $rc "endsnippet\n"
      }
      close $rc
    }

  }

  ######################################################################
  # Returns the list of files in the TKE home directory to copy.
  proc get_share_items {dir} {

    return [list snippets]

  }

  ######################################################################
  # Called whenever the share directory changes.
  proc share_changed {dir} {

    variable snippets_dir

    set snippets_dir [file join $dir snippets]

  }

}

