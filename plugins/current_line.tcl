# HEADER_BEGIN
# NAME         current_line
# AUTHOR       Trevor Williams  (phase1geo@gmail.com)
# DATE         07/15/2014
# INCLUDE      yes
# DESCRIPTION  Adds a current line indicator to the text widget.
# HEADER_END

namespace eval plugins::current_line {
  
  array set configured {}
  
  proc do_cline {tag} {
    
    bind $tag <FocusIn>       "plugins::current_line::update_line %W"
    bind $tag <FocusOut>      "plugins::current_line::remove_line %W"
    bind $tag <<Modified>>    "after idle [list plugins::current_line::update_line %W]"
    bind $tag <ButtonPress-1> "after idle [list plugins::current_line::update_line %W]"
    bind $tag <B1-Motion>     "after idle [list plugins::current_line::update_line %W]"
    bind $tag <KeyPress>      "after idle [list plugins::current_line::update_line %W]"
    
  }
  
  proc update_line {txt} {
    
    variable configured
    
    # Configure the current line, if has not been configured yet
    if {![info exists configured($txt)]} {
      $txt tag configure current_line -background [utils::auto_adjust_color [$txt cget -background] 25]
      $txt tag lower     current_line 
      set configured($txt) 1
    }
    
    # Get the current cursor line number
    set line [lindex [split [$txt index insert] .] 0]
    
    # Get the last highlighted line number
    if {[set range [$txt tag ranges current_line]] eq ""} {
      set last_line 0
    } else {
      set last_line [lindex [split [lindex $range 0] .] 0]
    }
    
    if {$last_line != $line} {
      $txt tag remove current_line $last_line.0 [expr $last_line + 1].0
      $txt tag add    current_line $line.0      [expr $line + 1].0
    }
    
  }
  
  proc remove_line {txt} {
    
    if {[set range [$txt tag ranges current_line]] ne ""} {
      $txt tag remove current_line {*}$range
    }
    
  }
  
  proc do_uninstall {} {
    
    variable configured
    
    foreach txt [array names configured] {
      $txt tag delete current_line
    }
    
    array unset configured
    
  }
  
}

plugins::register current_line {
  {text_binding pretext cline plugins::current_line::do_cline}
  {on_uninstall plugins::current_line::do_uninstall}
}
