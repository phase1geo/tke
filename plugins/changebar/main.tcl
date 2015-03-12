# Plugin namespace
namespace eval changebar {

  variable enabled 0
  
  # Handles text widget binding
  proc do_bind {btag} {
    
    bind $btag <<Modified>> "changebar::text_modified %W %d"
    
  }
  
  # Handles any modifications to the given text widget
  proc text_modified {txt data} {
    
    lassign $data cmd pos datalen
    
    puts "In text_modified, cmd: $cmd, pos: $pos, datalen: $datalen"
    
    if {$cmd eq "insert"} {
      if {[$txt count -lines $pos "$pos+${datalen}c"] == 1} {
        set_changed $txt $pos
      } else {
        set_added $txt $pos $datalen
      }
    }
    
  }
  
  # Marks the given line as changed
  proc set_changed {txt pos} {
    
    # TBD
    
  }
  
  # Marks the given line as added
  proc set_added {txt pos datalen} {
    
    # TBD
    
  }
  
  # Called when the Enabled menu option is clicked
  proc do_enable {} {
    
    variable enabled
    
    if {$enabled} {
      # TBD
    } else {
      # TBD
    }
    
  }
  
  proc handle_state_enable {} {
    
    return 1
    
  }
  
  proc do_goto_next {} {
    
    # TBD
    
  }
  
  proc handle_state_goto_next {} {
    
    variable enabled
    
    return $enabled
    
  }
  
  proc do_goto_prev {} {
    
    # TBD
    
  }
  
  proc handle_state_goto_prev {} {
    
    variable enabled
    
    return $enabled
    
  }

}

# Register all plugin actions
api::register changebar {
  {menu {checkbutton changebar::enabled} "Change Bars/Enable" changebar::do_enable changebar::handle_state_enable}
  {menu command "Change Bars/Goto Next"     changebar::do_goto_next changebar::handle_state_goto_next}
  {menu command "Change Bars/Goto Previous" changebar::do_goto_prev changebar::handle_state_goto_prev}
  {text_binding pretext changes changebar::do_bind}
}
