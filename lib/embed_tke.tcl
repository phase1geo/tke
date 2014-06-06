######################################################################
# Name:    embed_tke.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    06/05/2014
# Brief:   Package that provides an embeddable TKE editor to be used
#          in external applications.
######################################################################

package provide embed_tke 1.0

set tke_dir   [embed_tke::DIR]
set tke_home  [file normalize [file join ~ .tke]]
set auto_path [concat [file join [embed_tke::DIR] lib] $auto_path]

package require Tclx
package require ctext
package require tooltip

namespace eval embed_tke {
  
  source [file join [DIR] lib preferences.tcl]
  source [file join [DIR] lib tkedat.tcl]
  source [file join [DIR] lib gui.tcl] 
  source [file join [DIR] lib vim.tcl]
  source [file join [DIR] lib syntax.tcl]
  source [file join [DIR] lib indent.tcl]
  source [file join [DIR] lib utils.tcl]
  source [file join [DIR] lib multicursor.tcl]
  source [file join [DIR] lib snippets.tcl]
  
  # Handle launcher requests
  namespace eval launcher {
    proc register {args} {}
    proc unregister {args} {}
  }

  array set data   {}
  array set images {}
  
  ######################################################################
  # Creates an embeddable TKE widget and returns the pathname to the widget
  proc embed_tke {w args} {
    
    variable data
    variable images
    
    # If this is the first time we have been called, do some initialization
    if {[array size images] == 0} {
      
      # Create images
      set images(split) \
        [image create bitmap -file     [file join $::tke_dir lib images split.bmp] \
                             -maskfile [file join $::tke_dir lib images split.bmp] \
                             -foreground grey10]
      set images(close) \
        [image create bitmap -file     [file join $::tke_dir lib images close.bmp] \
                             -maskfile [file join $::tke_dir lib images close.bmp] \
                             -foreground grey10]
      set images(global) \
        [image create photo  -file     [file join $::tke_dir lib images global.gif]]
        
      # Load the preferences
      preferences::load

      # Load the snippets
      snippets::load

      # Load the syntax highlighting information
      syntax::load
      
    }
    
    # Create widget
    ttk::frame $w
    ctext $w.txt -wrap none -undo 1 -autoseparators 1 -insertofftime 0 \
      -highlightcolor yellow \
      -linemap_mark_command gui::mark_command -linemap_select_bg orange
    #-warnwidth $preferences::prefs(Editor/WarningWidth)
    ttk::label     $w.split -image $images(split) -anchor center
    ttk::scrollbar $w.vb    -orient vertical   -command "$w.txt yview"
    ttk::scrollbar $w.hb    -orient horizontal -command "$w.txt xview"
    
    bind Ctext    <<Modified>>          "gui::text_changed %W"
    bind $w.txt.t <FocusIn>             "gui::set_current_tab_from_txt %W"
    bind $w.txt.l <ButtonPress-3>       [bind $w.txt.l <ButtonPress-1>]
    bind $w.txt.l <ButtonPress-1>       "gui::select_line %W %y"
    bind $w.txt.l <B1-Motion>           "gui::select_lines %W %y"
    bind $w.txt.l <Shift-ButtonPress-1> "gui::select_lines %W %y"
    bind $w.txt   <<Selection>>         "gui::selection_changed %W"
    bind $w.txt   <ButtonPress-1>       "after idle [list gui::update_position %W]"
    bind $w.txt   <B1-Motion>           "gui::update_position %W"
    bind $w.txt   <KeyRelease>          "gui::update_position %W"
    bind $w.split <Button-1>            "gui::toggle_split_pane"
    bind Text     <<Cut>>               ""
    bind Text     <<Copy>>              ""
    bind Text     <<Paste>>             ""
    bind Text     <Control-d>           ""
    bind Text     <Control-i>           ""
    
    # Move the all bindtag ahead of the Text bindtag
    set text_index [lsearch [bindtags $w.txt.t] Text]
    set all_index  [lsearch [bindtags $w.txt.t] all]
    bindtags $w.txt.t [lreplace [bindtags $w.txt.t] $all_index $all_index]
    bindtags $w.txt.t [linsert  [bindtags $w.txt.t] $text_index all]
    
    # Create the Vim command bar
    vim::bind_command_entry $w.txt \
      [entry $w.ve -background black -foreground white -insertbackground white \
        -font [$w.txt cget -font]]
    
    # Create the search bar
    ttk::frame $w.sf
    ttk::label $w.sf.l1    -text [msgcat::mc "Find:"]
    ttk::entry $w.sf.e
    ttk::label $w.sf.case  -text "Aa" -relief raised
    ttk::label $w.sf.close -image $images(close)
    
    tooltip::tooltip $w.sf.case "Case sensitivity"
    
    pack $w.sf.l1    -side left  -padx 2 -pady 2
    pack $w.sf.e     -side left  -padx 2 -pady 2 -fill x -expand yes
    pack $w.sf.close -side right -padx 2 -pady 2
    pack $w.sf.case  -side right -padx 2 -pady 2
    
    bind $w.sf.e     <Escape>    "gui::close_search"
    bind $w.sf.case  <Button-1>  "gui::toggle_labelbutton %W"
    bind $w.sf.case  <Key-space> "gui::toggle_labelbutton %W"
    bind $w.sf.case  <Escape>    "gui::close_search"
    bind $w.sf.close <Button-1>  "gui::close_search"
    bind $w.sf.close <Key-space> "gui::close_search"
 
    # Create the search/replace bar
    ttk::frame $w.rf
    ttk::label $w.rf.fl    -text [msgcat::mc "Find:"]
    ttk::entry $w.rf.fe
    ttk::label $w.rf.rl    -text [msgcat::mc "Replace:"]
    ttk::entry $w.rf.re
    ttk::label $w.rf.case  -text "Aa" -relief raised
    ttk::label $w.rf.glob  -image $images(global) -relief raised
    ttk::label $w.rf.close -image $images(close)
    
    tooltip::tooltip $w.rf.case "Case sensitivity"
    tooltip::tooltip $w.rf.glob "Replace globally"
 
    pack $w.rf.fl    -side left -padx 2 -pady 2
    pack $w.rf.fe    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $w.rf.rl    -side left -padx 2 -pady 2
    pack $w.rf.re    -side left -padx 2 -pady 2 -fill x -expand yes
    pack $w.rf.case  -side left -padx 2 -pady 2
    pack $w.rf.glob  -side left -padx 2 -pady 2
    pack $w.rf.close -side left -padx 2 -pady 2
 
    bind $w.rf.fe    <Return>    "gui::do_search_and_replace"
    bind $w.rf.re    <Return>    "gui::do_search_and_replace"
    bind $w.rf.glob  <Return>    "gui::do_search_and_replace"
    bind $w.rf.fe    <Escape>    "gui::close_search_and_replace"
    bind $w.rf.re    <Escape>    "gui::close_search_and_replace"
    bind $w.rf.case  <Button-1>  "gui::toggle_labelbutton %W"
    bind $w.rf.case  <Key-space> "gui::toggle_labelbutton %W"
    bind $w.rf.case  <Escape>    "gui::close_search_and_replace"
    bind $w.rf.glob  <Button-1>  "gui::toggle_labelbutton %W"
    bind $w.rf.glob  <Key-space> "gui::toggle_labelbutton %W"
    bind $w.rf.glob  <Escape>    "gui::close_search_and_replace"
    bind $w.rf.close <Button-1>  "gui::close_search_and_replace"
    bind $w.rf.close <Key-space> "gui::close_search_and_replace"
    
    # FOOBAR
    grid rowconfigure    $w 1 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid $w.txt   -row 0 -column 0 -sticky news -rowspan 2
    grid $w.split -row 0 -column 1 -sticky news
    grid $w.vb    -row 1 -column 1 -sticky ns
    grid $w.hb    -row 2 -column 0 -sticky ew
    grid $w.ve    -row 3 -column 0 -sticky ew
    grid $w.sf    -row 4 -column 0 -sticky ew
    grid $w.rf    -row 5 -column 0 -sticky ew
    
    # Hide the vim command entry, search bar, search/replace bar and search separator
    grid remove $w.ve
    grid remove $w.sf
    grid remove $w.rf
    
    # Add the text bindings
    indent::add_bindings      $w.txt
    multicursor::add_bindings $w.txt
    snippets::add_bindings    $w.txt
    vim::set_vim_mode         $w.txt
        
    # Apply the appropriate syntax highlighting for the given extension
    if {$initial_language eq ""} {
      syntax::initialize_language $w.txt [syntax::get_default_language $title]
    } else {
      syntax::initialize_language $w.txt $initial_language
    }

    # Set the current language
    syntax::set_current_language

    # TBD
    
    return $w
    
  }
  
}
