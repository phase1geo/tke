######################################################################
# Name:    syntax.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    06/11/2013
# Brief:   Namespace that handles proper syntax highlighting.
###################################################################### 
 
namespace eval syntax {
  
  array set langs {}
  
  ######################################################################
  # Loads the syntax highlighting information.
  proc load {} {
    
    variable langs
    
    # Load the tke_dir syntax files
    set sfiles [glob -nocomplain -directory [file join [file dirname $::tke_dir] data syntax] *.syntax]
    
    # Load the tke_home syntax files
    set sfiles [concat $sfiles [glob -nocomplain -directory [file join $::tke_home syntax] *.syntax]]
    
    # Get the syntax information from all of the files in the user's syntax directory.
    foreach sfile $sfiles {
      if {![catch "open $sfile r" rc]} {
        set langs([file rootname [file tail $sfile]]) [read $rc]
        close $rc
      }
    }
    
  }
  
  ######################################################################
  # Returns a list of supported languages.
  proc get_languages {} {
    
    variable langs
    
    return [array names langs]
    
  }
  
  ######################################################################
  # Given the specified extension, returns the language name that supports
  # this extension.  If multiple extensions respond, use the first match.
  proc get_language {extension} {
    
    variable langs
    
    foreach lang [array names langs] {
      if {[lsearch [lindex $langs($lang) 0] $extension] != -1} {
        return $lang
      }
    }
    
    return "<None>"
    
  }
  
  ######################################################################
  # Sets the language of the given text widget to the given language.
  proc set_language {txt mb language} {
    
    variable langs
    
    # Clear the syntax highlighting for the widget
    ctext::clearHighlightClasses $txt
    ctext::disableComments $txt

    # Apply the new syntax highlighting syntax, if one exists for the given language
    if {[info exists langs($language)]} {
      if {[catch {
        foreach {type name color syntax} [lindex $langs($language) 1] {
          ctext::add$type $txt $name $color $syntax
        }
      } rc]} {
        tk_messageBox -parent . -type ok -default ok -message "Syntax error in $language.syntax file" -detail $rc
      }
      if {[lindex $langs($language) 2] eq "CComment"} {
        ctext::enableComments $txt
      }
    }
    
    # Re-highlight
    $txt highlight 1.0 end
    
    # Set the menubutton text
    $mb configure -text $language
    
  }
  
  ######################################################################
  # Create a menubutton containing a list of all available languages.
  proc create_menubutton {w txt} {
  
    variable langs
    
    # Create the menubutton
    ttk::menubutton $w -menu $w.menu -direction above
    
    # Create the menu
    set mnu [menu $w.menu -tearoff 0]
    
    # Populate the menu with the available languages
    $mnu add command -label "<None>" -command "syntax::set_language $txt $w <None>"
    foreach lang [lsort [array names langs]] {
      $mnu add command -label $lang -command "syntax::set_language $txt $w $lang"
    }
    
    return $w
  
  }
  
}
