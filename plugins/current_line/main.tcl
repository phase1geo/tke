namespace eval current_line {
  
  array set configured {}
  
  proc do_cline {tag} {
    
    bind $tag <FocusIn>        "current_line::update_line %W"
    bind $tag <FocusOut>       "current_line::remove_line %W"
    bind $tag <<Modified>>     "after idle [list current_line::update_line %W]"
    bind $tag <ButtonPress-1>  "after idle [list current_line::update_line %W]"
    bind $tag <B1-Motion>      "after idle [list current_line::update_line %W]"
    bind $tag <KeyPress>       "after idle [list current_line::update_line %W]"
    bind $tag <<ThemeChanged>> "current_line::update_color %W"
    
  }
  
  proc update_color {txt} {
    
    variable configured
    
    if {![winfo exists $txt]} {
      return
    }
    
    # Configure the current_line tag
    $txt tag configure current_line -background [api::auto_adjust_color [$txt cget -background] 25]
    $txt tag lower     current_line
    
    # Specify that we have been previously configured
    unset -nocomplain configured($txt)
    set configured($txt) 1
    
  }
  
  proc update_line {txt} {
    
    variable configured
    
    # If the text window no longer exists, exit now
    if {![winfo exists $txt]} {
      return
    }
    
    # Configure the current line, if has not been configured yet
    if {![info exists configured($txt)]} {
      update_color $txt
    }
    
    # Get the current cursor line number
    set line [lindex [split [$txt index insert] .] 0]
    
    # Get the last highlighted line number
    if {[set range [$txt tag ranges current_line]] eq ""} {
      set last_line_start 0
      set last_line_end   0
    } else {
      set last_line_start [lindex [split [lindex $range 0] .] 0]
      set last_line_end   [lindex [split [lindex $range 1] .] 0]
    }
    
    if {$last_line_start != $line} {
      $txt tag remove current_line $last_line_start.0 [expr $last_line_end + 1].0
      $txt tag add    current_line $line.0            [expr $line + 1].0
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

api::register current_line {
  {text_binding pretext cline current_line::do_cline}
  {on_uninstall current_line::do_uninstall}
}
