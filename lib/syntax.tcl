# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
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

  variable filetypes    {}
  variable current_lang [msgcat::mc "None"]
  variable assoc_file
  variable syntax_menus {}

  array set lang_template {
    filepatterns       {}
    vimsyntax          {}
    reference          {}
    embedded           {}
    matchcharsallowed  {}
    escapes            1
    tabsallowed        0
    linewrap           0
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
    functions          {}
    variables          {}
    symbols            {}
    numbers            {}
    punctuation        {}
    precompile         {}
    miscellaneous1     {}
    miscellaneous2     {}
    miscellaneous3     {}
    highlighter        {}
    meta               {}
    readmeta           {}
    advanced           {}
    formatting         {}
  }
  array set highlight_types {
    HighlightKeywords  addwords
    HighlightRegexp    addregexp
    HighlightCharStart addcharstart
  }
  array set langs        {}
  array set curr_lang    {}
  array set associations {}

  ######################################################################
  # Loads the syntax information.
  proc load {} {

    variable langs
    variable filetypes
    variable assoc_file

    # Load the tke_dir syntax files
    set sfiles [utils::glob_install [file join $::tke_dir data syntax] *.syntax]

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

    # Create preference trace on language hiding and syntax menu
    trace add variable preferences::prefs(General/DisabledLanguages) write [list syntax::handle_syntax_menu]
    trace add variable preferences::prefs(View/ShowLanguagesSubmenu) write [list syntax::handle_syntax_menu]

  }

  ######################################################################
  # Called whenever the given text widget is destroyed.
  proc handle_destroy_txt {txt} {

    variable curr_lang

    catch { unset curr_lang($txt) }

  }

  ######################################################################
  # Handle any changes to the General/DisabledLanguages preference
  # variable.
  proc handle_syntax_menu {name1 name2 op} {

    variable syntax_menus

    # Populate the syntax menus to match the required view type
    foreach syntax_menu $syntax_menus {
      populate_syntax_menu $syntax_menu syntax::set_current_language syntax::current_lang [msgcat::mc "None"] [get_enabled_languages]
    }

    # Make sure that the syntax menus are updated
    update_syntax_menus

  }

  ######################################################################
  # Adds the given syntax file to the total list.
  proc add_syntax {sfile {interp ""}} {

    variable langs
    variable lang_template
    variable filetypes

    # Get the name of the syntax
    set name [file rootname [file tail $sfile]]

    # See if the syntax type should be hidden from users
    set hidden [expr {[string index $name 0] eq "_"}]

    # Initialize the language array
    array set lang_array [array get lang_template]

    # Read the file
    if {![catch { open $sfile r } rc]} {

      # Read in the file information
      set contents [read $rc]
      close $rc

      # Parse the file contents but if there was an error, just return without adding the syntax
      if {[catch { array set lang_array $contents } rc]} {
        return
      }

      if {!$hidden} {

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

        # Add the language to the command launcher
        launcher::register [format "%s: %s" [msgcat::mc "Syntax"] $name] [list syntax::set_current_language $name]

      }

      # Add the interpreter
      set lang_array(interp) $interp

      # Add the language and the command launcher
      set langs($name) [array get lang_array]

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
    launcher::unregister [format "%s: %s" [msgcat::mc "Syntax"] $name]

  }

  ######################################################################
  # Returns a list of all supported languages.
  proc get_all_languages {} {

    variable langs

    return [array names langs]

  }

  ######################################################################
  # Returns a list of all enabled languages.
  proc get_enabled_languages {} {

    variable langs

    # Get the list of disabled languages
    set dis_langs [preferences::get General/DisabledLanguages]

    # If we don't have any disabled languages, just return the full list
    if {[llength $dis_langs] == 0} {
      return [get_all_languages]
    }

    set enabled [list]
    foreach lang [get_all_languages] {
      if {[lsearch $dis_langs $lang] == -1} {
        lappend enabled $lang
      }
    }

    return $enabled

  }

  ######################################################################
  # Given the specified filename, returns the language name that supports
  # it.  If multiple languages respond, use the first match.
  proc get_default_language {filename} {

    variable langs
    variable assoc_file

    # Make sure that the filename is an absolute pathname
    set filename [file normalize $filename]

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
    array set overrides [preferences::get {General/LanguagePatternOverrides}]

    set maxlen     0
    set best_match [msgcat::mc "None"]

    foreach lang [array names langs] {
      array set lang_array $langs($lang)
      set patterns $lang_array(filepatterns)
      set excluded 0
      if {[info exists overrides($lang)]} {
        set epatterns [list]
        foreach pattern $overrides($lang) {
          switch [string index $pattern 0] {
            "+" { lappend patterns  [string range $pattern 1 end] }
            "-" { lappend epatterns [string range $pattern 1 end] }
          }
        }
        foreach pattern $epatterns {
          if {[string match -nocase $pattern [file tail $filename]]} {
            set excluded 1
            break
          }
        }
      }
      if {!$excluded} {
        foreach pattern $patterns {
          if {[string match -nocase [file join * $pattern] $filename]} {
            if {[string length $pattern] > $maxlen} {
              set maxlen     [string length $pattern]
              set best_match $lang
            }
          }
        }
      }
    }

    return $best_match

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
  # Returns the language information for just the given language.
  proc get_lang_references {language} {

    variable langs

    array set lang_array $langs($language)

    set refs [list]
    foreach item $lang_array(reference) {
      lassign $item name url
      lappend refs [list "$language: $name" $url]
    }

    return $refs

  }

  ######################################################################
  # Returns the language's reference information, including any embedded
  # language reference information.  If no reference documentation is
  # available, returns the empty string.
  proc get_references {language} {

    variable langs

    set refs [list]

    if {[info exists langs($language)]} {

      # Add primary language references
      set refs [get_lang_references $language]

      # Add embedded language references
      array set lang_array $langs($language)
      foreach embedded $lang_array(embedded) {
        set sublang [lindex $embedded 0]
        if {[info exists langs($sublang)]} {
          lappend refs {*}[get_lang_references $sublang]
        }
      }

    }

    return $refs

  }

  ######################################################################
  # Sets the syntax language for the current text widget.
  proc set_current_language {language args} {

    # Get information about the current tab
    gui::get_info {} current txt fname

    # Save the directory, extension and selected language
    if {$fname ne "Untitled"} {
      save_language_association [file dirname $fname] [file extension $fname] $language
    }

    # Set the language of the current buffer
    set_language $txt $language {*}$args

    # Update the menubutton text
    [set gui::widgets(info_syntax)] configure -text $language

    # Set the focus back to the text editor
    gui::set_txt_focus [gui::last_txt_focus]

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

    # Clear the syntax highlighting for the widget
    if {$opts(-highlight)} {
      $txt syntax delete all
      $txt syntax addblockcomments {} {}
      $txt syntax addlinecomments  {} {}
      $txt syntax addstrings       {} {}
      ctext::setAutoMatchChars $txt {} {}
    }

    # Set default indent/unindent strings
    indent::set_indent_expressions $txt.t {} {} {}

    # Apply the new syntax highlighting syntax, if one exists for the given language
    if {[info exists langs($language)]} {

      if {[catch {

        array set lang_array $langs($language)

        # Get the command prefix and create a namespace for the language, if necessary
        if {$lang_array(interp) ne ""} {
          set cmd_prefix "syntax::exec_plugin_command $lang_array(interp)"
          set lang_ns    ""
          $lang_array(interp) alias $txt $txt
        } else {
          set cmd_prefix ""
          set lang_ns    [string tolower $language]
        }

        # Set the case sensitivity, delimiter characters and wrap mode
        $txt configure -casesensitive $lang_array(casesensitive) -escapes $lang_array(escapes)
        if {$lang_array(delimiters) ne ""} {
          $txt configure -delimiters $lang_array(delimiters)
        }

        # Set the wrap mode
        switch [preferences::get View/EnableLineWrapping] {
          syntax  { $txt configure -wrap [expr {$lang_array(linewrap) ? "word" : "none"}] }
          enable  { $txt configure -wrap "word" }
          disable { $txt configure -wrap "none" }
        }

        # Add the language keywords
        $txt syntax addclass keywords -fgtheme keywords
        $txt syntax addwords class keywords $lang_array(keywords)

        # Add the rest of the sections
        set_language_section $txt symbols        $lang_array(symbols) "" $cmd_prefix $lang_ns
        set_language_section $txt functions      $lang_array(functions) "" $cmd_prefix $lang_ns
        set_language_section $txt variables      $lang_array(variables) "" $cmd_prefix $lang_ns
        set_language_section $txt punctuation    $lang_array(punctuation) ""
        set_language_section $txt numbers        $lang_array(numbers) ""
        set_language_section $txt precompile     $lang_array(precompile) ""
        set_language_section $txt miscellaneous1 $lang_array(miscellaneous1) ""
        set_language_section $txt miscellaneous2 $lang_array(miscellaneous2) ""
        set_language_section $txt miscellaneous3 $lang_array(miscellaneous3) ""
        set_language_section $txt highlighter    $lang_array(highlighter) ""
        set_language_section $txt meta           $lang_array(meta) ""
        set_language_section $txt readmeta       $lang_array(readmeta) ""
        set_language_section $txt advanced       $lang_array(advanced) "" $cmd_prefix $lang_ns

        # Add the comments, strings and indentations
        ctext::clearCommentStringPatterns $txt
        $txt syntax addblockcomments {} $lang_array(bcomments)
        $txt syntax addlinecomments  {} $lang_array(lcomments)
        $txt syntax addstrings       {} $lang_array(strings)
        ctext::setIndentation $txt {} $lang_array(indent)   indent
        ctext::setIndentation $txt {} $lang_array(unindent) unindent

        set reindentStarts [list]
        set reindents      [list]
        foreach reindent $lang_array(reindent) {
          lappend reindentStarts [lindex $reindent 0]
          lappend reindents      {*}[lrange $reindent 1 end]
        }
        ctext::setIndentation $txt {} $reindentStarts reindentStart
        ctext::setIndentation $txt {} $reindents      reindent

        # Add the FIXME
        # $txt syntax addclass fixme -fgtheme miscellaneous1
        # $txt syntax addwords class fixme FIXME

        # Set the indent/unindent regular expressions
        indent::set_indent_expressions $txt.t $lang_array(indent) $lang_array(unindent) $lang_array(reindent)

        # Set the completer options for the given language
        ctext::setAutoMatchChars $txt {} $lang_array(matchcharsallowed)
        completer::set_auto_match_chars $txt.t {} $lang_array(matchcharsallowed)

        foreach embedded $lang_array(embedded) {
          lassign $embedded sublang embed_tokens
          if {$embed_tokens ne ""} {
            $txt syntax addembedlang $sublang $embed_tokens
            add_sublanguage $txt $sublang $cmd_prefix "" $embed_tokens
          } else {
            add_sublanguage $txt $sublang $cmd_prefix "" {}
          }
        }

        # Set the snippets for the current text widget
        snippets::set_language $language
        snippets::set_expandtabs $txt [expr $lang_array(tabsallowed) ? 0 : 1]

      } rc]} {
        gui::set_error_message [format "%s (%s)" [msgcat::mc "Syntax error in syntax file"] $language] $rc
        puts $::errorInfo
      }

    }

    # Save the language
    set curr_lang($txt) $language

    # Re-highlight
    if {$opts(-highlight)} {
      $txt syntax highlight 1.0 end
      folding::restart $txt
    }

  }

  ######################################################################
  # Add sublanguage features to current text widget.
  proc add_sublanguage {txt language cmd_prefix parent embed_patterns} {

    variable langs

    array set lang_array $langs($language)

    # Adjust the language value if we are not performing a full insertion
    if {$embed_patterns eq ""} {
      set lang_ns  [string tolower $language]
      set language $parent
    } elseif {$cmd_prefix ne ""} {
      set lang_ns ""
    } else {
      set lang_ns [string tolower $language]
    }

    # Add the keywords
    $txt syntax addwords class keywords $lang_array(keywords) $language

    # Add the rest of the sections
    set_language_section $txt symbols        $lang_array(symbols) $language $cmd_prefix $lang_ns
    set_language_section $txt functions      $lang_array(functions) $language $cmd_prefix $lang_ns
    set_language_section $txt variables      $lang_array(variables) $language $cmd_prefix $lang_ns
    set_language_section $txt punctuation    $lang_array(punctuation) $language
    set_language_section $txt miscellaneous1 $lang_array(miscellaneous1) $language
    set_language_section $txt miscellaneous2 $lang_array(miscellaneous2) $language
    set_language_section $txt miscellaneous3 $lang_array(miscellaneous3) $language
    set_language_section $txt highlighter    $lang_array(highlighter) $language
    set_language_section $txt meta           $lang_array(meta) $language
    set_language_section $txt readmeta       $lang_array(readmeta) $language
    set_language_section $txt advanced       $lang_array(advanced) $language $cmd_prefix $lang_ns

    if {$embed_patterns ne ""} {

      # Let's convert the embed_patterns list into start/end pattern lists
      foreach embed_pattern $embed_patterns {
        lassign $embed_pattern embed_start embed_end
        lappend embed_starts $embed_start
        lappend embed_ends $embed_end
      }

      # Add the rest of the sections
      set_language_section $txt numbers    $lang_array(numbers) $language
      set_language_section $txt precompile $lang_array(precompile) $language

      # Add the comments, strings and indentations
      $txt syntax addblockcomments $language $lang_array(bcomments)
      $txt syntax addlinecomments  $language $lang_array(lcomments)
      $txt syntax addstrings       $language $lang_array(strings)
      ctext::setIndentation $txt $language [list {*}$embed_starts {*}$lang_array(indent)]   indent
      ctext::setIndentation $txt $language [list {*}$embed_ends   {*}$lang_array(unindent)] unindent

      set reindentStarts [list]
      set reindents      [list]
      foreach reindent $lang_array(reindent) {
        lappend reindentStarts [lindex $reindent 0]
        lappend reindents      {*}[lrange $reindent 1 end]
      }
      ctext::setIndentation $txt $language $reindentStarts reindentStart
      ctext::setIndentation $txt $language $reindents      reindent

      # Add the FIXME
      # $txt syntax addwords class fixme FIXME $language

      # Set the indent/unindent regular expressions
      indent::set_indent_expressions $txt.t $lang_array(indent) $lang_array(unindent) $lang_array(reindent)

      # Set the completer options for the given language
      ctext::setAutoMatchChars $txt $language $lang_array(matchcharsallowed)
      completer::set_auto_match_chars $txt.t $language $lang_array(matchcharsallowed)

      # Set the snippets for the current text widget
      snippets::set_language $language

    }

    # Add any mixed languages
    foreach embedded $lang_array(embedded) {
      lassign $embedded sublang embed_tokens
      if {$embed_tokens eq ""} {
        add_sublanguage $txt $sublang $cmd_prefix $language {}
      }
    }

  }

  ######################################################################
  # Calls the proper
  proc add_highlight_type {txt type valtype value syntax lang} {

    variable highlight_types

    if {[info exists highlight_types($type)]} {
      $txt syntax $highlight_types($type) $valtype $value $syntax $lang
    } else {
      return -code error "Unknown syntax type $type"
    }

  }

  ######################################################################
  # Adds syntax highlighting for a given type
  proc set_language_section {txt section section_list lang {cmd_prefix ""} {lang_ns ""}} {

    variable meta_tags

    switch $section {
      "advanced"  -
      "symbols"   -
      "functions" -
      "variables" {
        if {($section eq "functions") || ($section eq "variables")} {
          $txt syntax addclass $section -fgtheme $section
        }
        while {[llength $section_list]} {
          set section_list [lassign $section_list type]
          switch -glob $type {
            "HighlightClass" {
              if {$section eq "advanced"} {
                set section_list [lassign $section_list name modifiers]
                $txt syntax addclass $name {*}$modifiers
              }
            }
            "HighlightProc" {
              if {$section eq "advanced"} {
                set section_list [lassign $section_list name body]
                if {([llength $section_list] > 0) && ![string match Highlight* [lindex $section_list 0]]} {
                  set params       $body
                  set section_list [lassign $section_list body]
                } else {
                  set params       [list txt row str varlist ins]
                }
                if {$lang_ns ne ""} {
                  namespace eval $lang_ns [list proc $name $params [subst -nocommands -novariables $body]]
                }
              }
            }
            "HighlightEndProc" -
            "TclEnd" -
            "IgnoreEnd" {
              # This is not invalid syntax but is not used for anything in this namespace
            }
            "Highlight*" {
              set section_list [lassign $section_list syntax command]
              if {$command ne ""} {
                if {$cmd_prefix ne ""} {
                  add_highlight_type $txt $type command "$cmd_prefix $command" $syntax $lang
                } elseif {[string first :: $command] != -1} {
                  add_highlight_type $txt $type command $command $syntax $lang
                } else {
                  add_highlight_type $txt $type command syntax::${lang_ns}::$command $syntax $lang
                }
              } else {
                set classname [expr {($section eq "advanced") ? "none" : $section}]
                $txt syntax addclass $classname -fgtheme $classname
                add_highlight_type $txt $type class $classname $syntax $lang
              }
            }
            "TclBegin" {
              set section_list [lassign $section_list content]
              namespace eval $lang_ns $content
            }
            "IgnoreBegin" {
              set section_list [lrange $section_list 1 end]
            }
            default {
              return -code error "Syntax error found in $section section -- bad type $type"
            }
          }
        }
      }
      "highlighter" {
        foreach {type syntax modifiers} $section_list {
          if {$syntax ne ""} {
            set class $section
            if {[llength $modifiers] > 0} {
              append class -[join $modifiers -]
            }
            $txt syntax addclass $class -fgtheme background -bgtheme $section -fontopts $modifiers
            add_highlight_type $txt $type class $class $syntax $lang
          }
        }
      }
      default {
        foreach {type syntax modifiers} $section_list {
          if {$syntax ne ""} {
            set class $section
            if {[llength $modifiers] > 0} {
              append class -[join $modifiers -]
            }
            $txt syntax addclass $class -fgtheme $section -fontopts $modifiers -meta [expr {($class eq "meta") || ($class eq "readmeta")}]
            add_highlight_type $txt $type class $class $syntax $lang
          }
        }
      }
    }

  }

  ######################################################################
  # This should be called whenever the current language is changed.  This
  # will update the syntax menu states to make them consistent with the
  # current language.
  proc update_syntax_menus {} {

    variable syntax_menus
    variable current_lang

    foreach mnu $syntax_menus {
      if {[$mnu type 1] eq "cascade"} {
        for {set i 1} {$i < [$mnu index last]} {incr i} {
          $mnu entryconfigure $i -image menu_nocheck
        }
        if {$current_lang ne [msgcat::mc "None"]} {
          $mnu entryconfigure [string toupper [string index $current_lang 0]] -image menu_check
        }
      }
    }

  }

  ######################################################################
  # Repopulates the specified syntax selection menu.
  proc populate_syntax_menu {mnu command varname dflt languages} {

    variable langs
    variable letters

    # Clear the menu
    $mnu delete 0 end

    # If the user wants to view languages in a submenu, organize them that way
    if {[preferences::get View/ShowLanguagesSubmenu] && [winfo exists $mnu.submenuA]} {
      array unset letters
      foreach lang [lsort [lsearch -inline -not -all $languages _*]] {
        lappend letters([string toupper [string index $lang 0]]) $lang
      }
      $mnu add radiobutton -label [format "<%s>" $dflt] -variable $varname -value $dflt -command [list {*}$command $dflt]
      foreach letter [lsort [array names letters]] {
        $mnu add cascade -compound left -label $letter -image menu_nocheck -menu $mnu.submenu$letter
      }
      return
    }

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

    # Populate the menu with the available languages
    $mnu add radiobutton -label [format "<%s>" $dflt] -variable $varname -value $dflt -command [list {*}$command $dflt]
    set i 0
    foreach lang [lsort [lsearch -inline -not -all $languages _*]] {
      $mnu add radiobutton -label $lang -variable $varname \
        -value $lang -command [list {*}$command $lang] -columnbreak [expr (($len / $cols) == $i) && $dobreak]
      set i [expr (($len / $cols) == $i) ? 0 : ($i + 1)]
    }

  }

  ######################################################################
  # Called just prior to posting the menu.
  proc post_menu {} {

    variable current_lang

    # Gets the current language
    gui::get_info {} current lang

    set current_lang $lang

  }

  ######################################################################
  # Displays language submenu.
  proc post_submenu {mnu letter} {

    variable letters

    # Clear the menu
    $mnu delete 0 end

    # Populate the menu with the available languages
    foreach lang $letters($letter) {
      $mnu add radiobutton -label $lang -variable syntax::current_lang -value $lang -command [list syntax::set_current_language $lang]
    }

  }

  ######################################################################
  # Create a menubutton containing a list of all available languages.
  proc create_menu {w} {

    variable syntax_menus

    # Create the menubutton menu
    lappend syntax_menus [menu ${w}Menu -tearoff 0 -postcommand syntax::post_menu]

    # Create submenus
    foreach letter [list A B C D E F G H I J K L M N O P Q R S T U V W X Y Z] {
      menu ${w}Menu.submenu$letter -tearoff 0 -postcommand [list syntax::post_submenu ${w}Menu.submenu$letter $letter]
    }

    # Populate the menu
    populate_syntax_menu ${w}Menu syntax::set_current_language syntax::current_lang [msgcat::mc "None"] [get_enabled_languages]

    # Register the menu
    theme::register_widget ${w}Menu menus

    return ${w}Menu

  }

  ######################################################################
  # Updates the menubutton with the current language.
  proc update_button {w} {

    variable curr_lang
    variable current_lang

    # Get the current language
    set current_lang $curr_lang([gui::current_txt])

    # Update the syntax menus
    update_syntax_menus

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
  proc get_extensions {{language ""}} {

    variable langs
    variable curr_lang

    if {$language eq ""} {
      set language $curr_lang([gui::current_txt])
    }

    # Get the current language
    if {$language eq [msgcat::mc "None"]} {
      return [list]
    } else {
      array set lang_array $langs($language)
      return $lang_array(extensions)
    }

  }

  ######################################################################
  # Returns the file patterns from the syntax file for the specified
  # language (or for the language associated with the current editor if
  # not specified).
  proc get_file_patterns {{language ""}} {

    variable langs
    variable curr_lang

    if {$language eq ""} {
      set language $curr_lang([gui::current_txt])
    }

    if {$language eq [msgcat::mc "None"]} {
      return [list]
    } else {
      array set lang_array $langs($language)
      return $lang_array(filepatterns)
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
  # Retrieves the values stored in the formatting array.
  proc get_formatting {txt} {

    variable langs
    variable curr_lang

    # Get the current language
    if {[set language $curr_lang($txt)] eq [msgcat::mc "None"]} {
      return [list]
    } else {
      array set lang_array $langs($language)
      return $lang_array(formatting)
    }

  }

  ######################################################################
  # Returns the information for syntax-file symbols.
  proc get_syntax_symbol {txt row str varlist ins} {

    array set vars $varlist

    if {[lindex $vars(0) 0] == 0} {
      return [list __symbols: {*}$vars(0)]
    }

    return ""

  }

  ######################################################################
  # Returns the information for symbols that are preceded by the word
  # specified with startpos/endpos.
  proc get_prefixed_symbol {txt row str varlist ins} {

    array set vars $varlist

    if {[regexp -indices -start [expr [lindex $vars(0) 1] + 1] -- {[a-zA-Z0-9_:]+} $str name]} {
      return [list __symbols:[string range $str {*}$vars(0)] {*}$name]
    }

    return ""

  }

  ######################################################################
  # Returns the information for syntax file functions.
  proc get_syntax_function {txt row str varlist ins} {

    array set vars $varlist

    return [list [list functions {*}$vars(1)] ""]

  }

  ######################################################################
  # Parses an XML tag.
  proc get_xml_tag {txt row str varlist ins} {

    array set vars $varlist

    return [list [list tag {*}$vars(1)] ""]

  }

  ######################################################################
  # Returns the XML attribute to highlight.
  proc get_xml_attribute {txt row str varlist ins} {

    array set vars $varlist

    return [list [list attribute {*}$vars(1)] ""]

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

  ######################################################################
  # Executes the plugin command and returns the result.
  proc exec_plugin_command {interp command txt row str varlist ins} {

    return [$interp eval [list $command $txt $row $str $varlist $ins]]

  }

}
