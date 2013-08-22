######################################################################
# Name:    syntax.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    06/11/2013
# Brief:   Namespace that handles proper syntax highlighting.
###################################################################### 
 
namespace eval syntax {
  
  array set langs  {}
  array set themes {}
  array set theme  {}
  
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
    
    # Load the tke_dir syntax files
    set sfiles [glob -nocomplain -directory [file join [file dirname $::tke_dir] data syntax] *.syntax]
    
    # Load the tke_home syntax files
    set sfiles [concat $sfiles [glob -nocomplain -directory [file join $::tke_home syntax] *.syntax]]
    
    # Get the syntax information from all of the files in the user's syntax directory.
    foreach sfile $sfiles {
      if {![catch "open $sfile r" rc]} {
        set name [file rootname [file tail $sfile]]
        set langs($name) [read $rc]
        launcher::register "Syntax:  $name" "syntax::set_language $name"
        close $rc
      }
    }
    
  }
  
  ######################################################################
  # Loads the theme file information.
  proc load_themes {} {
    
    variable themes
    variable theme
    
    # Load the tke_dir theme files
    set tfiles [glob -nocomplain -directory [file join [file dirname $::tke_dir] data themes] *.tketheme]
    
    # Load the tke_home theme files
    set tfiles [concat $tfiles [glob -nocomplain -directory [file join $::tke_home themes] *.tketheme]]
    
    # Get the theme information
    foreach tfile $tfiles {
      if {![catch "open $tfile r" rc]} {
        set name [file rootname [file tail $tfile]]
        set themes($name) [read $rc]
        launcher::register "Theme:  $name" "syntax::set_theme $name"
        close $rc
      }
    }
    
    # Sets the current theme
    set_theme $preferences::prefs(Appearance/Theme)
    
    # Trace changes to the Appearance/Theme preference variable
    trace variable preferences::prefs(Appearance/Theme) w syntax::handle_theme_change
    
  }
  
  ######################################################################
  # Called whenever the Appearance/Theme preference value is changed.
  proc handle_theme_change {name1 name2 op} {

    set_theme $preferences::prefs(Appearance/Theme)

  }

  ######################################################################
  # Sets the theme to the specified value.  Returns 1 if the theme was
  # set; otherwise, returns 0.
  proc set_theme {theme_name} {
    
    variable themes
    variable theme
    variable lang
    
    if {[info exists themes($theme_name)]} {
      
      # Set the current theme array
      array set theme $themes($theme_name)
      
      # Iterate through our tab list and update there
      foreach txt [array names lang] {
        if {[winfo exists $txt]} {
          set_language $lang($txt)
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
  proc get_language {filename} {
    
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
  proc get_current_language {} {
    
    variable lang
    
    # Get the current text widget
    set txt [gui::current_txt]
    
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
  proc set_current_language {} {
    
    variable lang
    
    # Get the current text widget
    set txt [gui::current_txt]
    
    if {[info exists lang($txt)]} {
      set_language $lang($txt)
    }
    
  }
  
  ######################################################################
  # Sets the language of the given text widget to the given language.
  proc set_language {language} {
    
    variable langs
    variable theme
    variable lang
    
    # Get the current text widget
    set txt [gui::current_txt]
        
    # Clear the syntax highlighting for the widget
    ctext::clearHighlightClasses $txt
    ctext::disableComments $txt
    
    # Set the text background color to the current theme
    $txt configure -background $theme(background) -foreground $theme(foreground) \
      -selectbackground $theme(selectbackground) -selectforeground $theme(selectforeground) \
      -insertbackground $theme(cursor) -highlightcolor $theme(highlightcolor) \
      -warnwidth_bg $theme(warnwidthcolor)
    
    # Set default indent/unindent strings
    indent::set_indent_expressions $txt.t "\{" "\}"
    
    # Set the snippet set to the current language
    snippets::set_language $language

    # Apply the new syntax highlighting syntax, if one exists for the given language
    if {[info exists langs($language)]} {
      
      if {[catch {
        
        array set lang_array $langs($language)
        
        # Add the language keywords
        ctext::addHighlightClass $txt keywords $theme(keywords) $lang_array(keywords)
        
        # Add the language symbols
        ctext::addHighlightClass $txt symbols  $theme(keywords) $lang_array(symbols)
        
        # Add the rest of the sections
        set_language_section $txt punctuation   $lang_array(punctuation)
        set_language_section $txt numbers       $lang_array(numbers)
        set_language_section $txt precompile    $lang_array(precompile)
        set_language_section $txt miscellaneous $lang_array(miscellaneous)
        set_language_section $txt strings       $lang_array(strings)
        set_language_section $txt comments      $lang_array(lcomments)
        
        # Add the C comments, if specified
        if {$lang_array(ccomments)} {
          ctext::enableComments $txt $theme(comments)
        }

        # Add the FIXME
        ctext::addHighlightClassForRegexp $txt fixme $theme(miscellaneous) {FIXME}
        
        # Set the indentation namespace for the given text widget to be
        # the indent/unindent expressions for this language
        indent::set_indent_expressions $txt.t $lang_array(indent) $lang_array(unindent)
        
      } rc]} {
        tk_messageBox -parent . -type ok -default ok -message "Syntax error in $language.syntax file" -detail $rc
      }
      
    }
    
    # Save the language
    set lang($txt) $language

    # Re-highlight
    $txt highlight 1.0 end
    
    # Set the menubutton text
    $gui::widgets(info_syntax) configure -text $language
    
  }
  
  ######################################################################
  # Adds syntax highlighting for a given type
  proc set_language_section {txt section section_list} {
    
    variable theme
    
    set i 0
    
    foreach {type syntax} $section_list {
      if {$syntax ne ""} {
        ctext::add$type $txt $section$i $theme($section) $syntax
      }
      incr i
    }
    
  }
  
  ######################################################################
  # Create a menubutton containing a list of all available languages.
  proc create_menubutton {w} {
  
    variable langs
    
    # Create the menubutton
    ttk::menubutton $w -menu $w.menu -direction above
    
    # Create the menu
    set mnu [menu $w.menu -tearoff 0]
    
    # Populate the menu with the available languages
    $mnu add command -label "<None>" -command "syntax::set_language <None>"
    foreach lang [lsort [array names langs]] {
      $mnu add command -label $lang -command "syntax::set_language $lang"
    }
    
    return $w
  
  }
  
  ######################################################################
  # Updates the menubutton with the current language.
  proc update_menubutton {w} {
    
    variable lang
    
    # Configures the current language for the specified text widget
    $w configure -text $lang([gui::current_txt])
    
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
  
}
