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
# Name:    syntax.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    06/11/2013
# Brief:   Namespace that handles proper syntax highlighting.
######################################################################

namespace eval syntax {

  source [file join $::tke_dir lib ns.tcl]

  variable filetypes    {}
  variable current_lang [msgcat::mc "None"]
  variable assoc_file

  array set lang_template {
    filepatterns       {}
    vimsyntax          {}
    embedded           {}
    matchcharsallowed  {}
    escapes            1
    tabsallowed        0
    casesensitive      0
    delimiters         {}
    indent             {}
    unindent           {}
    reindent           {}
    icomment           {}
    lcomments          {}
    bcomments          {}
    strings            {}
    keywords           {}
    symbols            {}
    numbers            {}
    punctuation        {}
    precompile         {}
    miscellaneous1     {}
    miscellaneous2     {}
    miscellaneous3     {}
    highlighter        {}
    meta               {}
    advanced           {}
  }
  array set langs        {}
  array set curr_lang    {}
  array set meta_tags    {}
  array set associations {}

  ######################################################################
  # Loads the syntax information.
  proc load {} {

    variable langs
    variable filetypes
    variable assoc_file

    # Load the tke_dir syntax files
    set sfiles [[ns utils]::glob_install [file join $::tke_dir data syntax] *.syntax]

    # Load the tke_home syntax files
    set sfiles [concat $sfiles [glob -nocomplain -directory [file join $::tke_home syntax] *.syntax]]

    # Get the syntax information from all of the files in the user's syntax directory.
    foreach sfile $sfiles {
      add_syntax $sfile
    }

    # Create the association filename
    set assoc_file [file join $::tke_home lang_assoc.tkedat]

    # Add all of the syntax plugins
    plugins::add_all_syntax

  }

  ######################################################################
  # Adds the given syntax file to the total list.
  proc add_syntax {sfile {interp ""}} {

    variable langs
    variable lang_template
    variable filetypes

    # Get the name of the syntax
    set name [file rootname [file tail $sfile]]

    # Initialize the language array
    array set lang_array [array get lang_template]

    # Read the file
    if {![catch { open $sfile r } rc]} {

      # Read in the file information
      array set lang_array [read $rc]
      close $rc

      # Format the extension information
      set extensions [list]
      foreach pattern $lang_array(filepatterns) {
        if {[regexp {^\.\w+$} [set extension [file extension $pattern]]]} {
          lappend extensions $extension
        }
      }
      set lang_array(extensions) $extensions
      if {[llength $extensions] > 0} {
        lappend filetypes [list "$name Files" $extensions TEXT]
      }

      # Sort the filetypes by name
      set filetypes [lsort -index 0 $filetypes]

      # Add the interpreter
      set lang_array(interp) $interp

      # Add the language and the command launcher
      set langs($name) [array get lang_array]
      [ns launcher]::register [format "%s: %s" [msgcat::mc "Syntax"] $name] [list [ns syntax]::set_current_language $name]

    }

  }

  ######################################################################
  # Deletes the given syntax file from the total list.
  proc delete_syntax {sfile} {

    variable langs
    variable filetypes

    # Get the name of the syntax
    set name [file rootname [file tail $sfile]]

    # Delete the syntax
    if {[set index [lsearch -index 0 $filetypes $name]] != -1} {
      set filetypes [lreplace $filetypes $index $index]
    }

    # Delete the langs
    unset langs($name)

    # Unregister the language with the launcher
    [ns launcher]::unregister [format "%s: %s" [msgcat::mc "Syntax"] $name]

  }

  ######################################################################
  # Returns a list of supported languages.
  proc get_languages {} {

    variable langs

    return [array names langs]

  }

  ######################################################################
  # Given the specified filename, returns the language name that supports
  # it.  If multiple languages respond, use the first match.
  proc get_default_language {filename} {

    variable langs
    variable assoc_file

    # Check to see if the user has specified a language override for files like
    # the filename.
    if {![catch { tkedat::read $assoc_file 0 } rc]} {
      array set associations $rc
      set key [file dirname $filename],[file extension $filename]
      if {[info exists associations($key)]} {
        return $associations($key)
      }
    }

    # Get the list of extension overrides
    array set overrides [[ns preferences]::get {General/LanguagePatternOverrides}]

    foreach lang [array names langs] {
      array set lang_array $langs($lang)
      set patterns $lang_array(filepatterns)
      set excluded 0
      if {[info exists overrides($lang)]} {
        set exclude_patterns [list]
        foreach pattern $overrides($lang) {
          switch [string index $pattern 0] {
            "+" { lappend patterns  [string range $pattern 1 end] }
            "-" { lappend epatterns [string range $pattern 1 end] }
          }
        }
        foreach pattern $epatterns {
          if {[string match $pattern $filename]} {
            set excluded 1
            break
          }
        }
      }
      if {!$excluded} {
        foreach pattern $patterns {
          if {[string match $pattern $filename]} {
            return $lang
          }
        }
      }
    }

    return [msgcat::mc "None"]

  }

  ######################################################################
  # Returns the name of the language which supports the given vim syntax
  # identifier.  If no match is found, the value of "None" is returned.
  proc get_vim_language {vimsyntax} {

    variable langs

    foreach lang [array names langs] {
      array set lang_array $langs($lang)
      if {[lsearch $lang_array(vimsyntax) $vimsyntax] != -1} {
        return $lang
      }
    }

    return [msgcat::mc "None"]

  }

  ######################################################################
  # Retrieves the language of the current text widget.
  proc get_language {txt} {

    variable curr_lang

    if {[info exists curr_lang($txt)]} {
      return $curr_lang($txt)
    }

    return [msgcat::mc "None"]

  }

  ######################################################################
  # Sets the syntax language for the current text widget.
  proc set_current_language {language args} {

    # Get information about the current tab
    lassign [[ns gui]::get_info {} current {txt fname}] txt fname

    # Save the directory, extension and selected language
    if {$fname ne "Untitled"} {
      save_language_association [file dirname $fname] [file extension $fname] $language
    }

    # Set the language of the current buffer
    set_language $txt $language {*}$args

    # Set the focus back to the text editor
    [ns gui]::set_txt_focus [[ns gui]::last_txt_focus {}]

  }

  ######################################################################
  # Sets the language of the given text widget to the given language.
  # Options:
  #   -highlight (0 | 1)   Specifies whether syntax highlighting should be performed
  proc set_language {txt language args} {

    variable langs
    variable curr_lang
    variable current_lang

    array set opts {
      -highlight 1
    }
    array set opts $args

    # Get the current syntax theme
    array set theme [[ns theme]::get_syntax_colors]

    # Clear the syntax highlighting for the widget
    if {$opts(-highlight)} {
      ctext::clearHighlightClasses   $txt
      ctext::setBlockCommentPatterns $txt {} {}
      ctext::setLineCommentPatterns  $txt {} {}
      ctext::setStringPatterns       $txt {} {}
    }

    [winfo parent $txt] configure -background $theme(background)

    # Set the text background color to the current theme
    $txt configure -background $theme(background) -foreground $theme(foreground) \
      -selectbackground $theme(select_background) -selectforeground $theme(select_foreground) \
      -insertbackground $theme(cursor) -highlightcolor $theme(border_highlight) \
      -linemapbg $theme(background) -linemapfg $theme(line_number) \
      -linemap_select_bg $theme(cursor) -linemap_select_fg $theme(background) \
      -warnwidth_bg $theme(warning_width) -relief flat \
      -diffaddbg $theme(difference_add) -diffsubbg $theme(difference_sub) \
      -matchchar_fg $theme(background) -matchchar_bg $theme(foreground)

    # Set default indent/unindent strings
    [ns indent]::set_indent_expressions $txt.t {} {} {}

    # Apply the new syntax highlighting syntax, if one exists for the given language
    if {[info exists langs($language)]} {

      if {[catch {

        array set lang_array $langs($language)

        # Get the command prefix
        if {$lang_array(interp) ne ""} {
          set cmd_prefix "$lang_array(interp) eval"
          $lang_array(interp) alias $txt $txt
        } else {
          set cmd_prefix ""
        }

        # Set the case sensitivity and delimiter characters
        $txt configure -casesensitive $lang_array(casesensitive) \
          -escapes $lang_array(escapes)
        if {$lang_array(delimiters) ne ""} {
          $txt configure -delimiters $lang_array(delimiters)
        }

        # Add the language keywords
        ctext::addHighlightClass $txt keywords $theme(keywords)
        ctext::addHighlightKeywords $txt $lang_array(keywords) class keywords

        # Add the rest of the sections
        set_language_section $txt symbols        $lang_array(symbols) "" $cmd_prefix
        set_language_section $txt punctuation    $lang_array(punctuation) ""
        set_language_section $txt numbers        $lang_array(numbers) ""
        set_language_section $txt precompile     $lang_array(precompile) ""
        set_language_section $txt miscellaneous1 $lang_array(miscellaneous1) ""
        set_language_section $txt miscellaneous2 $lang_array(miscellaneous2) ""
        set_language_section $txt miscellaneous3 $lang_array(miscellaneous3) ""
        set_language_section $txt highlighter    $lang_array(highlighter) ""
        set_language_section $txt meta           $lang_array(meta) ""
        set_language_section $txt advanced       $lang_array(advanced) "" $cmd_prefix

        # Add the comments, strings and indentations
        ctext::clearCommentStringPatterns $txt
        ctext::setBlockCommentPatterns $txt {} $lang_array(bcomments) $theme(comments)
        ctext::setLineCommentPatterns  $txt {} $lang_array(lcomments) $theme(comments)
        ctext::setStringPatterns       $txt {} $lang_array(strings)   $theme(strings)
        ctext::setIndentation          $txt {} $lang_array(indent)   indent
        ctext::setIndentation          $txt {} $lang_array(unindent) unindent

        set reindentStarts [list]
        set reindents      [list]
        foreach reindent $lang_array(reindent) {
          lappend reindentStarts [lindex $reindent 0]
          lappend reindents      {*}[lrange $reindent 1 end]
        }
        ctext::setIndentation $txt {} $reindentStarts reindentStart
        ctext::setIndentation $txt {} $reindents      reindent

        # Add the FIXME
        ctext::addHighlightClass $txt fixme $theme(miscellaneous1)
        ctext::addHighlightKeywords $txt FIXME class fixme

        # Set the indent/unindent regular expressions
        [ns indent]::set_indent_expressions $txt.t $lang_array(indent) $lang_array(unindent) $lang_array(reindent) 0

        # Set the completer options for the given language
        ctext::setAutoMatchChars $txt {} $lang_array(matchcharsallowed)
        [ns completer]::set_auto_match_chars $txt.t {} $lang_array(matchcharsallowed)

        foreach embedded $lang_array(embedded) {
          lassign $embedded sublang embed_start embed_end
          if {($embed_start ne "") && ($embed_end ne "")} {
            ctext::setEmbedLangPattern $txt $sublang $embed_start $embed_end $theme(embedded)
            add_sublanguage $txt $sublang $cmd_prefix "" $embed_start $embed_end
          } else {
            add_sublanguage $txt $sublang $cmd_prefix "" {} {}
          }
        }

        # Set the snippets for the current text widget
        [ns snippets]::set_language $language

      } rc]} {
        [ns gui]::set_error_message [format "%s (%s)" [msgcat::mc "Syntax error in syntax file"] $language] $rc
        puts $::errorInfo
      }

    }

    # Save the language
    set curr_lang($txt) [set current_lang $language]

    # Re-highlight
    if {$opts(-highlight)} {
      $txt highlight 1.0 end
    }

    # Generate a <<ThemeChanged>> event on the text widget
    event generate $txt <<ThemeChanged>>

    # Set the menubutton text
    if {[info exists [ns gui]::widgets(info_syntax)]} {
      [set [ns gui]::widgets(info_syntax)] configure -text $language
    }

  }

  ######################################################################
  # Add sublanguage features to current text widget.
  proc add_sublanguage {txt language cmd_prefix parent embed_start embed_end} {

    variable langs

    array set lang_array $langs($language)

    # Adjust the language value if we are not performing a full insertion
    if {$embed_start eq ""} {
      set language $parent
    }

    # Add the keywords
    ctext::addHighlightKeywords $txt $lang_array(keywords) class keywords $language

    # Add the rest of the sections
    set_language_section $txt symbols        $lang_array(symbols) $language $cmd_prefix
    set_language_section $txt punctuation    $lang_array(punctuation) $language
    set_language_section $txt miscellaneous1 $lang_array(miscellaneous1) $language
    set_language_section $txt miscellaneous2 $lang_array(miscellaneous2) $language
    set_language_section $txt miscellaneous3 $lang_array(miscellaneous3) $language
    set_language_section $txt highlighter    $lang_array(highlighter) $language
    set_language_section $txt meta           $lang_array(meta) $language
    set_language_section $txt advanced       $lang_array(advanced) $language $cmd_prefix

    if {$embed_start ne ""} {

      # Get the current syntax theme
      array set theme [[ns theme]::get_syntax_colors]

      # Add the rest of the sections
      set_language_section $txt numbers    $lang_array(numbers) $language
      set_language_section $txt precompile $lang_array(precompile) $language

      # Add the comments, strings and indentations
      ctext::setBlockCommentPatterns $txt $language $lang_array(bcomments) $theme(comments)
      ctext::setLineCommentPatterns  $txt $language $lang_array(lcomments) $theme(comments)
      ctext::setStringPatterns       $txt $language $lang_array(strings)   $theme(strings)
      ctext::setIndentation          $txt $language [list $embed_start {*}$lang_array(indent)]   indent
      ctext::setIndentation          $txt $language [list $embed_end   {*}$lang_array(unindent)] unindent

      set reindentStarts [list]
      set reindents      [list]
      foreach reindent $lang_array(reindent) {
        lappend reindentStarts [lindex $reindent 0]
        lappend reindents      {*}[lrange $reindent 1 end]
      }
      ctext::setIndentation $txt $language $reindentStarts reindentStart
      ctext::setIndentation $txt $language $reindents      reindent

      # Add the FIXME
      ctext::addHighlightKeywords $txt FIXME class fixme $language

      # Set the indent/unindent regular expressions
      [ns indent]::set_indent_expressions $txt.t $lang_array(indent) $lang_array(unindent) $lang_array(reindent) 1

      # Set the completer options for the given language
      ctext::setAutoMatchChars $txt $language $lang_array(matchcharsallowed)
      [ns completer]::set_auto_match_chars $txt.t $language $lang_array(matchcharsallowed)

      # Set the snippets for the current text widget
      [ns snippets]::set_language $language

    }

    # Add any mixed languages
    foreach embedded $lang_array(embedded) {
      lassign $embedded sublang embed_start embed_end
      if {$embed_start eq ""} {
        add_sublanguage $txt $sublang $cmd_prefix $language {} {}
      }
    }

  }

  ######################################################################
  # Adds syntax highlighting for a given type
  proc set_language_section {txt section section_list lang {cmd_prefix ""}} {

    variable theme
    variable meta_tags

    # Get the current syntax theme
    array set theme [[ns theme]::get_syntax_colors]

    set meta_tags($txt) "meta"

    switch $section {
      "advanced" -
      "symbols" {
        while {[llength $section_list]} {
          set section_list [lassign $section_list type]
          if {$type eq "HighlightClass"} {
            if {$section eq "advanced"} {
              set section_list [lassign $section_list name color modifiers]
              switch $color {
                none        { ctext::addHighlightClass $txt $name $theme(foreground) "" $modifiers }
                highlighter { ctext::addHighlightClass $txt $name $theme(background) $theme($color) $modifiers }
                default     { ctext::addHighlightClass $txt $name $theme($color) "" $modifiers }
              }
              if {$color eq "meta"} {
                lappend meta_tags($txt) $name
              }
            }
          } else {
            set section_list [lassign $section_list syntax command]
            if {$command ne ""} {
              ctext::add$type $txt $syntax command [string trim "$cmd_prefix $command"] $lang
            } else {
              ctext::add$type $txt $syntax class [expr {($section eq "symbols") ? "symbols" : "none"}] $lang
            }
          }
        }
      }
      "highlighter" {
        set i 0
        foreach {type syntax modifiers} $section_list {
          if {$syntax ne ""} {
            ctext::addHighlightClass $txt $section$i $theme(background) $theme($section) $modifiers
            ctext::add$type $txt $syntax class $section$i $lang
          }
          incr i
        }
      }
      default {
        set i 0
        foreach {type syntax modifiers} $section_list {
          if {$syntax ne ""} {
            ctext::addHighlightClass $txt $section$i $theme($section) "" $modifiers
            ctext::add$type $txt $syntax class $section$i $lang
          }
          incr i
        }
      }
    }

  }

  ######################################################################
  # Returns true if the given text widget contains meta characters.
  proc contains_meta_chars {txt} {

    variable meta_tags

    set all_tags [ctext::getHighlightClasses $txt]

    if {[info exists meta_tags($txt)]} {
      foreach tag $meta_tags($txt) {
        if {[lsearch $all_tags $tag] != -1} {
          return 1
        }
      }
    }

    return 0

  }

  ######################################################################
  # Sets the visibility of all meta tags to the given value.
  proc set_meta_visibility {txt value} {

    variable meta_tags

    set all_tags [ctext::getHighlightClasses $txt]

    if {[info exists meta_tags($txt)]} {
      foreach tag $meta_tags($txt) {
        if {[lsearch $all_tags $tag] != -1} {
          $txt tag configure _$tag -elide [expr $value ^ 1]
        }
      }
    }

  }

  ######################################################################
  # Repopulates the specified syntax selection menu.
  proc populate_syntax_menu {mnu} {

    variable langs

    # Figure out the height of a menu entry
    menu .__tmpMenu
    .__tmpMenu add command -label "foobar"
    .__tmpMenu add command -label "foobar"
    update
    set max_entries [expr ([winfo screenheight .] / [set rheight [winfo reqheight .__tmpMenu]]) * 2]
    destroy .__tmpMenu

    # Calculate the number of needed columns
    set len  [expr [array size langs] + 1]
    set cols 1
    while {[expr ($len / $cols) > $max_entries]} {
      incr cols
    }

    # If we are running in Aqua, don't perform the column break
    set dobreak [expr {[tk windowingsystem] ne "aqua"}]

    # Clear the menu
    $mnu delete 0 end

    # Populate the menu with the available languages
    $mnu add radiobutton -label [format "<%s>" [msgcat::mc "None"]] -variable [ns syntax]::current_lang \
      -value [msgcat::mc "None"] -command [list [ns syntax]::set_current_language [msgcat::mc "None"]]
    set i 0
    foreach lang [lsort [array names langs]] {
      $mnu add radiobutton -label $lang -variable [ns syntax]::current_lang \
        -value $lang -command [list [ns syntax]::set_current_language $lang] -columnbreak [expr (($len / $cols) == $i) && $dobreak]
      set i [expr (($len / $cols) == $i) ? 0 : ($i + 1)]
    }

    return $mnu

  }

  ######################################################################
  # Create a menubutton containing a list of all available languages.
  proc create_menu {w} {

    # Create the menubutton menu
    set mnu [menu ${w}Menu -tearoff 0]

    # Populate the syntax menu
    populate_syntax_menu $mnu

    return $mnu

  }

  ######################################################################
  # Updates the menubutton with the current language.
  proc update_button {w} {

    variable curr_lang
    variable current_lang

    # Get the current language
    set current_lang $curr_lang([[ns gui]::current_txt {}])

    # Configures the current language for the specified text widget
    $w configure -text $current_lang

  }

  ######################################################################
  # Returns a list containing three items.  The first item is a regular
  # expression that matches the string(s) to indicate that an indentation
  # should occur on the following line.  The second item is a regular
  # expression that matches the string(s) to indicate that an unindentation
  # should occur on the following line.  The third item is a regular
  # expression that matches the string(s) to indicate that a reindentation
  # should occur on the following line.  All of these expressions come
  # from the syntax file for the current language.
  proc get_indentation_expressions {txt} {

    variable langs
    variable curr_lang

    if {![info exists curr_lang($txt)]} {
      return [list {} {} {}]
    }

    # Get the language array for the current language.
    array set lang_array $langs($curr_lang($txt))

    return [list $lang_array(indent) $lang_array(unindent) $lang_array(reindent)]

  }

  ######################################################################
  # Returns the full list of available file patterns.
  proc get_filetypes {} {

    variable filetypes

    # Add an "All Files" to the beginning of the filetypes list
    set filetypes [list [list "All Files" "*"] {*}$filetypes]

    return $filetypes

  }

  ######################################################################
  # Retrieves the extensions for the current text widget.
  proc get_extensions {tid} {

    variable langs
    variable curr_lang

    # Get the current language
    if {[set language $curr_lang([[ns gui]::current_txt $tid])] eq [msgcat::mc "None"]} {
      return [list]
    } else {
      array set lang_array $langs($language)
      return $lang_array(extensions)
    }

  }

  ######################################################################
  # Retrieves the value of tabsallowed in the current syntax.
  proc get_tabs_allowed {txt} {

    variable langs
    variable curr_lang

    # Get the current language
    if {[set language $curr_lang($txt)] eq [msgcat::mc "None"]} {
      return 1
    } else {
      array set lang_array $langs($language)
      return $lang_array(tabsallowed)
    }

  }

  ######################################################################
  # Retrieves the value of lcomment in the current syntax.
  proc get_comments {txt} {

    variable langs
    variable curr_lang

    # Get the current language
    if {[set language $curr_lang($txt)] eq [msgcat::mc "None"]} {
      return [list [list] [list] [list]]
    } else {
      array set lang_array $langs($language)
      return [list $lang_array(icomment) $lang_array(lcomments) $lang_array(bcomments)]
    }

  }

  ######################################################################
  # Returns the information for syntax-file symbols.
  proc get_syntax_symbol {txt startpos endpos} {

    if {[lindex [split $startpos .] 1] == 0} {
      return [list symbols: $startpos $endpos [list]]
    }

    return ""

  }

  ######################################################################
  # Returns the information for symbols that are preceded by the word
  # specified with startpos/endpos.
  proc get_prefixed_symbol {txt startpos endpos} {

    set type [$txt get $startpos $endpos]
    if {[set startpos [$txt search -count lengths -regexp -- {\w+} $endpos]] ne ""} {
      return [list symbols:$type $startpos [$txt index "$startpos+[lindex $lengths 0]c"] [list]]
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown code string.
  proc get_markdown_ccode {txt startpos endpos} {

    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-3c"] ne "\\")} {
      $txt tag remove _code $startpos $endpos
      return [list [list [list ccode       [$txt index "$startpos+2c"] [$txt index "$endpos-2c"] [list]] \
                         [list codemarkers $startpos [$txt index "$startpos+2c"] [list]] \
                         [list codemarkers [$txt index "$endpos-2c"] $endpos [list]]] ""]
                         [list grey        $startpos [$txt index "$startpos+2c"] [list]] \
                         [list grey        [$txt index "$endpos-2c"] $endpos [list]]] ""]
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown code string.
  proc get_markdown_code {txt startpos endpos} {

    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-2c"] ne "\\")} {
      if {([lsearch [$txt tag names $startpos]    _codemarkers] == -1) && \
          ([lsearch [$txt tag names "$endpos-1c"] _codemarkers] == -1)} {
        return [list [list [list code [$txt index "$startpos+1c"] [$txt index "$endpos-1c"] [list]] \
                           [list grey $startpos [$txt index "$startpos+1c"] [list]] \
                           [list grey [$txt index "$endpos-1c"] $endpos [list]]] ""]
      } else {
        return [list [list] [$txt index "$startpos+2c"]
      }
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown header string.
  proc get_markdown_header {txt startpos endpos} {

    if {[regexp {(#{1,6})[^#]+} [$txt get $startpos $endpos] all hashes]} {
      set num [string length $hashes]
      return [list [list [list h$num [$txt index "$startpos+${num}c"] [$txt index "$startpos+[string length $all]c"] [list]] \
                         [list grey  $startpos [$txt index "$startpos+${num}c"] [list]]] ""]
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown bold string.
  proc get_markdown_bold {txt startpos endpos} {

    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-3c"] ne "\\")} {
      $txt tag remove _italics $startpos $endpos
      return [list [list [list bold        [$txt index "$startpos+2c"] [$txt index "$endpos-2c"] [list]] \
                         [list boldmarkers $startpos [$txt index "$startpos+2c"] [list]] \
                         [list boldmarkers [$txt index "$endpos-2c"] $endpos [list]] \
                         [list grey        $startpos [$txt index "$startpos+2c"] [list]] \
                         [list grey        [$txt index "$endpos-2c"] $endpos [list]]] ""]
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown italics string.
  proc get_markdown_italics {txt startpos endpos} {

    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-2c"] ne "\\")} {
      if {([lsearch [$txt tag names $startpos]    _boldmarkers] == -1) && \
          ([lsearch [$txt tag names "$endpos-1c"] _boldmarkers] == -1)} {
        return [list [list [list italics [$txt index "$startpos+1c"] [$txt index "$endpos-1c"] [list]] \
                           [list grey    $startpos [$txt index "$startpos+1c"] [list]] \
                           [list grey    [$txt index "$endpos-1c"] $endpos [list]]] ""]
      } else {
        return [list [list] [$txt index "$startpos+2c"]]
      }
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown overstrike string.
  proc get_markdown_overstrike {txt startpos endpos} {

    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-3c"] ne "\\")} {
      return [list [list [list strike        [$txt index "$startpos+2c"] [$txt index "$endpos-2c"] [list]] \
                         [list strikemarkers $startpos [$txt index "$startpos+2c"] [list]] \
                         [list strikemarkers [$txt index "$endpos-2c"] $endpos [list]] \
                         [list grey          $startpos [$txt index "$startpos+2c"] [list]] \
                         [list grey          [$txt index "$endpos-2c"] $endpos [list]]] ""]
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown highlighter string.
  proc get_markdown_highlight {txt startpos endpos} {

    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-3c"] ne "\\")} {
      return [list [list [list hilite [$txt index "$startpos+2c"] [$txt index "$endpos-2c"] [list]] \
                         [list grey   $startpos [$txt index "$startpos+2c"] [list]] \
                         [list grey   [$txt index "$endpos-2c"] $endpos [list]]] ""]
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown subscript string.
  proc get_markdown_subscript {txt startpos endpos} {

    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-2c"] ne "\\")} {
      if {([lsearch [$txt tag names $startpos]    _strikemarkers] == -1) && \
          ([lsearch [$txt tag names "$endpos-1c"] _strikemarkers] == -1)} {
        return [list [list [list sub  [$txt index "$startpos+1c"] [$txt index "$endpos-1c"] [list]] \
                           [list grey $startpos [$txt index "$startpos+1c"] [list]] \
                           [list grey [$txt index "$endpos-1c"] $endpos [list]]] ""]
      } else {
        return [list [list] [$txt index "$startpos+2c"]]
      }
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown subscript string.
  proc get_markdown_superscript {txt startpos endpos} {

    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-2c"] ne "\\")} {
      return [list [list [list super [$txt index "$startpos+1c"] [$txt index "$endpos-1c"] [list]] \
                         [list grey  $startpos [$txt index "$startpos+1c"] [list]] \
                         [list grey  [$txt index "$endpos-1c"] $endpos [list]]] ""]
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown link string.
  proc get_markdown_link {txt startpos endpos} {

    if {[$txt get "$startpos-1c"] ne "\\"} {
      if {[regexp {^\[(.+?)\]((\s*)\[(.*?)\]|\((.*?)\))} [$txt get $startpos $endpos] -> label dummy ref linkref url]} {
        if {[string index [string trim $ref] 0] eq "\["} {
          if {$linkref eq ""} {
            set cmd "syntax::handle_markdown_reflink_click $txt [string tolower $label]"
          } else {
            set cmd "syntax::handle_markdown_reflink_click $txt [string tolower $linkref]"
          }
        } else {
          set cmd "utils::open_file_externally [lindex $url 0]"
        }
        set start2a [expr [string length $label] + 1]
        set start2b [expr [string length $label] + [string length $dummy] + 2]
        return [list [list [list link [$txt index "$startpos+1c"] [$txt index "$startpos+[expr [string length $label] + 1]c"] $cmd] \
                           [list grey $startpos [$txt index "$startpos+1c"] [list]] \
                           [list grey [$txt index "$startpos+${start2a}c"] [$txt index "$startpos+${start2b}c"] [list]] \
                           [list grey [$txt index "$endpos-1c"] $endpos [list]]] ""]
      }
    }

    return ""

  }

  ######################################################################
  # Returns the information for the given Markdown link reference.
  proc get_markdown_linkref {txt startpos endpos} {

    variable markdown_linkrefs

    if {[$txt get "$startpos-1c"] ne "\\"} {
      if {[regexp {^\s*\[(.+?)\]:\s+(\S+)} [$txt get $startpos $endpos] -> linkref url]} {
        set markdown_linkrefs($txt,[string tolower $linkref]) $url
      }
    }

    return ""

  }

  ######################################################################
  # Handles a user click on a references link.
  proc handle_markdown_reflink_click {txt ref} {

    variable markdown_linkrefs

    if {[info exists markdown_linkrefs($txt,$ref)]} {
      utils::open_file_externally $markdown_linkrefs($txt,$ref)
    }

  }
  
  ######################################################################
  # Checks to see if the previous line contains a list item and inserts
  # a new list item of the same type.
  proc get_markdown_list {txt startpos endpos} {
    
    puts "HERE A"
    
    if {[lindex [split [$txt index insert] .] 1] == 0} {
      puts "HERE B"
    }
    
  }

  ######################################################################
  # Parses an XML tag.
  proc get_xml_tag {txt startpos endpos} {

    set str [$txt get $startpos $endpos]

    if {[regexp -indices -start 1 -- {(\S+)} $str -> tag]} {
      set start [expr [lindex $tag 1] + 1]
      lappend retval [list tag [$txt index "$startpos+1c"] [$txt index "$startpos+${start}c"] [list]]
      while {[regexp -indices -start $start {(\S+)=} $str -> attribute]} {
        set start [expr [lindex $attribute 1] + 1]
        lappend retval [list attribute [$txt index "$startpos+[lindex $attribute 0]c"] [$txt index "$startpos+${start}c"] [list]]
      }
    }

    return [list $retval ""]

  }

  ######################################################################
  # Returns the XML attribute to highlight.
  proc get_xml_attribute {txt startpos endpos} {

    return [list [list [list attribute $startpos [$txt index "$endpos-1c"] [list]]] ""]

  }

  ######################################################################
  # Save the language associations to the association file.
  proc save_language_association {dname ext language} {

    variable assoc_file
    variable associations

    array set associations [list]

    if {![catch { tkedat::read $assoc_file 0 } rc]} {
      array set associations $rc
    }

    # Set the association
    set associations($dname,$ext) $language

    # Write the association file
    catch { tkedat::write $assoc_file [array get associations] 0 }

  }

}
