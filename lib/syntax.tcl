######################################################################
# Name:    syntax.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    06/11/2013
# Brief:   Namespace that handles proper syntax highlighting.
###################################################################### 
 
namespace eval syntax {

  source [file join $::tke_dir lib ns.tcl]
    
  variable filetypes

  array set lang_template {
    filepatterns      {}
    matchcharsallowed {}
    tabsallowed       0
    casesensitive     0
    indent            {}
    unindent          {}
    lcomments         {}
    bcomments         {}
    strings           {}
    keywords          {}
    symbols           {}
    numbers           {}
    punctuation       {}
    precompile        {}
    miscellaneous1    {}
    miscellaneous2    {}
    miscellaneous3    {}
    advanced          {}
  }
  array set langs     {}
  array set themes    {}
  array set theme     {}
  array set colorizers {
    keywords       1
    comments       1
    strings        1
    numbers        1
    punctuation    1
    precompile     1
    miscellaneous1 1
    miscellaneous2 1
    miscellaneous3 1
  }
  
  ######################################################################
  # Loads the syntax and theme information.
  proc load {} {
    
    # Load the supported syntax information
    load_syntax
    
    # Load themes
    load_themes
 
  }
  
  ######################################################################
  # Loads the syntax highlighting information.
  proc load_syntax {} {
    
    variable langs
    variable lang_template
    
    # Load the tke_dir syntax files
    set sfiles [glob -nocomplain -directory [file join $::tke_dir data syntax] *.syntax]
    
    # Load the tke_home syntax files
    set sfiles [concat $sfiles [glob -nocomplain -directory [file join $::tke_home syntax] *.syntax]]
    
    # Get the syntax information from all of the files in the user's syntax directory.
    foreach sfile $sfiles {
      set name [file rootname [file tail $sfile]]
      array set lang_array [array get lang_template]
      if {![catch { open $sfile r } rc]} {
        array set lang_array [read $rc]
        close $rc
        set langs($name) [array get lang_array]
        [ns launcher]::register [msgcat::mc "Syntax:  %s" $name] "syntax::set_language $name"
      }
    }
    
    # Calculate the filetypes array
    create_filetypes
    
  }
  
  ######################################################################
  # Generates the filetypes list.
  proc create_filetypes {} {
    
    variable langs
    variable filetypes
    
    # Calculate the filetypes array
    set filetypes [list]
    foreach {name syntax_list} [array get langs] {
      array set lang_array $syntax_list
      set extensions [list]
      foreach pattern $lang_array(filepatterns) {
        if {[regexp {^\.\w+$} [set extension [file extension $pattern]]]} {
          lappend extensions $extension
        }
      }
      lappend syntax_list extensions $extensions
      set langs($name) $syntax_list
      if {[llength $extensions] > 0} {
        lappend filetypes [list "$name Files" $extensions TEXT]
      }
    }
    
    # Sort the filetypes by name
    set filetypes [lsort -index 0 $filetypes]
    
    # Add an "All Files" to the beginning of the filetypes list
    set filetypes [list [list "All Files" "*"] {*}$filetypes]
    
  }
  
  ######################################################################
  # Loads the theme file information.
  proc load_themes {} {
    
    variable themes
    variable theme
    
    # Clear the themes and unregister any themes from the launcher
    array unset themes
    array unset theme
    [ns launcher]::unregister "Theme:*"
    
    # Load the tke_dir theme files
    set tfiles [glob -nocomplain -directory [file join $::tke_dir data themes] *.tketheme]
    
    # Load the tke_home theme files
    lappend tfiles {*}[glob -nocomplain -directory [file join $::tke_home themes] *.tketheme]
    
    # Get the theme information
    foreach tfile $tfiles {
      if {![catch { open $tfile r } rc]} {
        set name [file rootname [file tail $tfile]]
        set themes($name) [list name $name {*}[read $rc]]
        [ns launcher]::register [msgcat::mc "Theme:  %s" $name] [list [ns syntax]::set_theme $name]
        close $rc
      }
    }
    
    # Sets the current theme
    set_theme [[ns preferences]::get Appearance/Theme]
    
    # Trace changes to syntax preference values
    trace variable [ns preferences]::prefs(Appearance/Theme)    w [ns syntax]::handle_theme_change
    trace variable [ns preferences]::prefs(Appearance/Colorize) w [ns syntax]::handle_colorize_change
      
  }
  
  ######################################################################
  # Called whenever the Appearance/Theme preference value is changed.
  proc handle_theme_change {name1 name2 op} {

    set_theme [[ns preferences]::get Appearance/Theme]

  }
  
  ######################################################################
  # Called whenever the Appearance/Colorize preference value is changed.
  proc handle_colorize_change {name1 name2 op} {
    
    set_theme [[ns preferences]::get Appearance/Theme]
    
  }

  ######################################################################
  # Sets the theme to the specified value.  Returns 1 if the theme was
  # set; otherwise, returns 0.
  proc set_theme {theme_name} {
    
    variable themes
    variable theme
    variable lang
    variable colorizers
    
    if {[info exists themes($theme_name)]} {
      
      # Set the current theme array
      array set theme [list none ""]
      array set theme $themes($theme_name)
      
      # Remove theme values that aren't in the Appearance/Colorize array
      foreach name [array names theme] {
        if {[info exists colorizers($name)] && \
            [lsearch [[ns preferences]::get Appearance/Colorize] $name] == -1} {
          set theme($name) ""
        }
      }
      
      # Iterate through our tab list and update there
      foreach txt [array names lang] {
        if {[winfo exists $txt]} {
          set_language $lang($txt) $txt
        } else {
          unset lang($txt)
        }
      }
      
    }
    
    return 0
    
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
    
    foreach lang [array names langs] {
      array set lang_array $langs($lang)
      foreach filepattern $lang_array(filepatterns) {
        if {[string match $filepattern $filename]} {
          return $lang
        }
      }
    }
    
    return "None"
    
  }
  
  ######################################################################
  # Retrieves the language of the current text widget.
  proc get_current_language {txt} {
    
    variable lang
    
    if {[info exists lang($txt)]} {
      return $lang($txt)
    }
    
    return "None"
    
  }
  
  ######################################################################
  # Initializes the language for the given text widget.
  proc initialize_language {txt language} {
  
    variable lang
    
    set lang($txt) $language
    
  }
    
  ######################################################################
  # Sets the language of the current tab to the specified language.
  proc set_current_language {tid} {
    
    variable lang
    
    # Get the current text widget
    set txt [[ns gui]::current_txt $tid]
    
    if {[info exists lang($txt)]} {
      set_language $lang($txt) $txt
    }
    
  }
  
  ######################################################################
  # Sets the language of the given text widget to the given language.
  proc set_language {language {txt ""}} {
    
    variable langs
    variable theme
    variable lang
    
    # If a text widget wasn't specified, get the current text widget
    if {$txt eq ""} {
      set txt [[ns gui]::current_txt {}]
    }
    
    # Clear the syntax highlighting for the widget
    ctext::clearHighlightClasses   $txt
    ctext::setBlockCommentPatterns $txt {}
    ctext::setLineCommentPatterns  $txt {}
    ctext::setStringPatterns       $txt {}
    
    # Set the text background color to the current theme
    $txt configure -background $theme(background) -foreground $theme(foreground) \
      -selectbackground $theme(selectbackground) -selectforeground $theme(selectforeground) \
      -insertbackground $theme(cursor) -highlightcolor $theme(highlightcolor) \
      -linemapbg $theme(background) -linemapfg $theme(foreground) \
      -warnwidth_bg $theme(warnwidthcolor)
    
    # Set default indent/unindent strings
    [ns indent]::set_indent_expressions $txt.t {\{} {\}}
    
    # Set the snippet set to the current language
    [ns snippets]::set_language $language
    
    # Apply the new syntax highlighting syntax, if one exists for the given language
    if {[info exists langs($language)]} {
      
      if {[catch {
          
        array set lang_array $langs($language)
          
        # Set the case sensitivity
        $txt configure -casesensitive $lang_array(casesensitive)
        
        # Add the language keywords
        ctext::addHighlightClass $txt keywords $theme(keywords)
        ctext::addHighlightKeywords $txt $lang_array(keywords) class keywords
        
        # Add the rest of the sections
        set_language_section $txt symbols        $lang_array(symbols)
        set_language_section $txt punctuation    $lang_array(punctuation)
        set_language_section $txt numbers        $lang_array(numbers)
        set_language_section $txt precompile     $lang_array(precompile)
        set_language_section $txt miscellaneous1 $lang_array(miscellaneous1)
        set_language_section $txt miscellaneous2 $lang_array(miscellaneous2)
        set_language_section $txt miscellaneous3 $lang_array(miscellaneous3)
        set_language_section $txt advanced       $lang_array(advanced)
        
        # Add the comments and strings
        ctext::setBlockCommentPatterns $txt $lang_array(bcomments) $theme(comments)
        ctext::setLineCommentPatterns  $txt $lang_array(lcomments) $theme(comments)
        ctext::setStringPatterns       $txt $lang_array(strings)   $theme(strings)

        # Add the FIXME
        ctext::addHighlightClass $txt fixme $theme(miscellaneous1)
        ctext::addHighlightKeywords $txt FIXME class fixme
          
        # Set the indentation namespace for the given text widget to be
        # the indent/unindent expressions for this language
        ctext::addHighlightClass $txt indent ""
        ctext::addHighlightClass $txt unindent ""
        ctext::addHighlightRegexp $txt [join $lang_array(indent) |] class indent
        ctext::addHighlightRegexp $txt [join $lang_array(unindent) |] class unindent
        
        # TBD - Leave this in for now
        [ns indent]::set_indent_expressions $txt.t $lang_array(indent) $lang_array(unindent)
        
        # Set the completer options for the given language
        [ns completer]::set_auto_match_chars $txt.t $lang_array(matchcharsallowed)

      } rc]} {
        tk_messageBox -parent . -type ok -default ok -message [msgcat::mc "Syntax error in %s.syntax file" $language] -detail $rc
      }
      
    }
    
    # Save the language
    set lang($txt) $language

    # Re-highlight
    $txt highlight 1.0 end
    
    # Generate a <<ThemeChanged>> event on the text widget
    event generate $txt <<ThemeChanged>>
    
    # Set the menubutton text
    if {[info exists [ns gui]::widgets(info_syntax)]} {
      [set [ns gui]::widgets(info_syntax)] configure -text $language
    }
    
  }
  
  ######################################################################
  # Adds syntax highlighting for a given type
  proc set_language_section {txt section section_list} {
    
    variable theme
    
    set i 0

    switch $section {
      "advanced" -
      "symbols" {
        while {[llength $section_list]} {
          set section_list [lassign $section_list type]
          if {$type eq "HighlightClass"} {
            if {$section eq "advanced"} {
              set section_list [lassign $section_list name color modifiers]
              ctext::addHighlightClass $txt $name $theme($color) "" $modifiers
            }
          } else {
            set section_list [lassign $section_list syntax command]
            if {$command ne ""} {
              ctext::add$type $txt $syntax command $command
            } else {
              ctext::add$type $txt $syntax class [expr {($section eq "symbols") ? "symbols" : "none"}]
            }
          }
        }
      }
      default {
        foreach {type syntax modifiers} $section_list {
          if {$syntax ne ""} {
            ctext::addHighlightClass $txt $section$i $theme($section) "" $modifiers
            ctext::add$type $txt $syntax class $section$i
            incr i
          }
        }
      }
    }
    
  }
  
  ######################################################################
  # Repopulates the specified theme selection menu.
  proc populate_theme_menu {mnu} {
    
    variable themes
    
    # Clear the menu
    $mnu delete 0 end
    
    # Populate the menu with the available themes
    foreach name [lsort [array names themes]] {
      $mnu add radiobutton -label $name -variable [ns syntax]::theme(name) -value $name -command [list [ns syntax]::set_theme $name]
    }
    
    return $mnu
    
  }
  
  ######################################################################
  # Repopulates the specified syntax selection menu.
  proc populate_syntax_menu {mnu} {
    
    variable langs
    
    # Clear the menu
    $mnu delete 0 end
    
    # Populate the menu with the available languages
    $mnu add radiobutton -label "<[msgcat::mc None]>" -variable [ns syntax]::lang([[ns gui]::current_txt {}]) \
      -value "<[msgcat::mc None]>" -command [list [ns syntax]::set_language <None>]
    foreach lang [lsort [array names langs]] {
      $mnu add radiobutton -label $lang -variable [ns syntax]::lang([[ns gui]::current_txt {}]) \
        -value $lang -command [list [ns syntax]::set_language $lang]
    }
    
    return $mnu
    
  }
  
  ######################################################################
  # Create a menubutton containing a list of all available languages.
  proc create_menubutton {w} {
  
    # Create the menubutton
    ttk::menubutton $w -menu $w.menu -direction above

    # Create the menubutton menu
    menu $w.menu -tearoff 0 -postcommand "[ns syntax]::populate_syntax_menu $w.menu"

    return $w
    
  }
  
  ######################################################################
  # Updates the menubutton with the current language.
  proc update_menubutton {w} {
    
    variable lang
    
    # Configures the current language for the specified text widget
    $w configure -text $lang([[ns gui]::current_txt {}])
    
  }
 
  ######################################################################
  # Returns a list containing two items.  The first item is a regular
  # expression that matches the string(s) to indicate that an indentation
  # should occur on the following line.  The second item is a regular
  # expression that matches the string(s) to indicate that an unindentation
  # should occur on the following line.  Both of these expressions come
  # from the syntax file for the current language.
  proc get_indentation_expressions {} {
    
    variable langs
    variable lang
    
    # Get the language array for the current language.
    array set lang_array $langs($lang)
    
    return [list $lang_array(indent) $lang_array(unindent)]
    
  }
  
  ######################################################################
  # Returns the full list of available file patterns.
  proc get_filetypes {} {
    
    variable filetypes
    
    return $filetypes
    
  }
  
  ######################################################################
  # Retrieves the extensions for the current text widget.
  proc get_extensions {tid} {
    
    variable langs
    variable lang
    
    # Get the current language
    if {[set language $lang([[ns gui]::current_txt $tid])] eq "None"} {
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
    variable lang
    
    # Get the current language
    if {[set language $lang($txt)] eq "None"} {
      return 1
    } else {
      array set lang_array $langs($language)
      return $lang_array(tabsallowed)
    }
    
  }

  ######################################################################
  # Returns the information for syntax-file symbols.
  proc get_syntax_symbol {txt startpos endpos} {

    if {[lindex [split $startpos .] 1] == 0} {
      return [list symbols: $startpos $endpos]
    }

    return ""

  }

  ######################################################################
  # Returns the information for symbols that are preceded by the word
  # specified with startpos/endpos.
  proc get_prefixed_symbol {txt startpos endpos} {

    set type [$txt get $startpos $endpos]
    if {[set startpos [$txt search -count lengths -regexp -- {\w+} $endpos]] ne ""} {
      return [list symbols:$type $startpos [$txt index "$startpos+[lindex $lengths 0]c"]]
    }

    return ""

  }
  
  ######################################################################
  # Returns the information for the given Markdown header string.
  proc get_markdown_header {txt startpos endpos prestart_from} {
    
    if {[regexp {(#{1,6})[^#]+} [$txt get $startpos $endpos] all hashes]} {
      set num [string length $hashes]
      return [list h$num [$txt index "$startpos+${num}c"] [$txt index "$startpos+[string length $all]c"]]
    }
    
    return ""
    
  }
  
  ######################################################################
  # Returns the information for the given Markdown bold string.
  proc get_markdown_bold {txt startpos endpos prestart_from} {
    
    puts "In get_markdown_bold, word: [$txt get $startpos $endpos]"
    
    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-3c"] ne "\\")} {
      return [list bold        [$txt index "$startpos+2c"] [$txt index "$endpos-2c"] \
                   boldmarkers $startpos [$txt index "$startpos+2c"] \
                   boldmarkers [$txt index "$endpos-2c"] $endpos]
    }
    
    return ""
    
  }
  
  ######################################################################
  # Returns the information for the given Markdown italics string.
  proc get_markdown_italics {txt startpos endpos prestart_from} {
    
    upvar $prestart_from restart_from
    
    puts "In get_markdown_italics, word: [$txt get $startpos $endpos]"
    
    set prev_char [expr {($startpos ne "1.0") ? [$txt get "$startpos-1c"] : ""}]
    
    if {$prev_char ne "\\"} {
      if {[lsearch [$txt tag names $startpos] boldmarkers] == -1} {
        while {1} {
          set res [$txt search -exact -- [$txt get $startpos] "$startpos+1c"]
          if {[lsearch [$txt tag names $res] boldmarkers] != -1} {
            break
          } elseif {[$txt get "$res-1c"] ne "\\"} {
            set restart_from [$txt index "$res+1c"]
            return [list italics [$txt index "$startpos+1c"] [$txt index "$res-1c"]]
          }
        }
      } else {
        set restart_from [$txt index "$startpos+2c"]
        return ""
      }
    }
    
    return ""
    
  }

}
