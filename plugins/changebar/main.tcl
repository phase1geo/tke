# Plugin namespace
namespace eval changebar {

  array set data {
    enabled 0
  }
  
  proc current_txt {} {
    
    if {[set file_index [api::file::current_file_index]] != -1} {
      return [api::file::get_info $file_index txt]
    } else {
      return ""
    }
    
  }
  
  # Creates the gutter
  proc create {txt} {
    
    # Create the gutter
    $txt gutter create changebar added {-symbol "|" -fg green} changed {-symbol "|" -fg yellow}
    
  }
  
  # Adds the gutter
  proc do_open {file_index} {
    
    variable data
    
    # Get the associated text widget
    set txt [api::file::get_info $file_index txt]
    
    # Set the enabled term to 0
    set data($txt,enabled) 0
    
  }
  
  # Closes the file
  proc do_close {file_index} {
    
    variable data
    
    # Get the current text
    unset data([current_txt],enabled)
    
  }
    
  # Removes the gutter
  proc do_uninstall {} {
    
    foreach name [array names data *,enabled] {
      set txt [lindex [split $name ,] 0]
      $txt gutter destroy changebar
    }
    
  }
  
  # Handles text widget binding
  proc do_bind {btag} {
    
    variable data
    
    bind $btag <<Modified>> "changebar::text_modified %W %d"
    
  }
  
  # Handles any modifications to the given text widget
  proc text_modified {txt mod_data} {
    
    variable data
    
    if {$data($txt,enabled)} {
      
      lassign $mod_data cmd pos chars lines
       
      if {$lines == 0} {
        set_changed $txt $pos
      } elseif {$cmd eq "insert"} {
        set_added $txt $pos $lines
      } elseif {[$txt compare 1.0 == "end-1c"]} {
        set_added $txt $pos 1
      }
      
    }
    
  }
  
  # Marks the given line as changed
  proc set_changed {txt pos} {
    
    set line [lindex [split $pos .] 0]
    
    if {[$txt gutter get changebar $line] ne "added"} {
      $txt gutter set changebar changed $line
    }
    
  }
  
  # Marks the given line as added
  proc set_added {txt pos num_lines} {
    
    set start_line [lindex [split $pos .] 0]
    set lines      [list]
    
    for {set i 0} {$i < $num_lines} {incr i} {
      lappend lines [expr $start_line + $i]
    }
    
    $txt gutter set changebar added $lines
    
  }
  
  # Called when the Enabled menu option is clicked
  proc do_enable {} {
    
    variable data
    
    # Get the current text widget
    set txt [current_txt]
    
    # Save the enable status
    set data($txt,enabled) $data(enabled)
    
    if {$data($txt,enabled)} {
      create $txt
    } else {
      $txt gutter destroy changebar
    }
    
  }
  
  proc handle_state_enable {} {
    
    variable data
    
    set txt [current_txt]
    
    if {[info exists data($txt,enabled)]} {
      set data(enabled) $data([current_txt],enabled)
      return 1
    } else {
      return 0
    }
    
  }
  
  proc do_clear {} {
    
    # Clear the changebar symbols for the current text widget
    [current_txt] gutter clear 1 [lindex [split [$txt index end] .] 0]
    
  }
  
  proc handle_state_clear {} {
    
    variable data
    
    if {[set txt [current_txt]] ne ""} {
      return $data($txt,enabled)
    } else {
      return 0
    }
    
  }
  
  proc do_goto_next {} {
    
    # TBD
    
  }
  
  proc handle_state_goto_next {} {
    
    variable data
    
    if {[set txt [current_txt]] ne ""} {
      return $data($txt,enabled)
    } else {
      return 0
    }
    
  }
  
  proc do_goto_prev {} {
    
    # TBD
    
  }
  
  proc handle_state_goto_prev {} {
    
    variable data
    
    if {[set txt [current_txt]] ne ""} {
      return $data($txt,enabled)
    } else {
      return 0
    }
    
  }

}

# Register all plugin actions
api::register changebar {
  {on_open changebar::do_open}
  {on_close changebar::do_close}
  {on_uninstall changebar::do_uninstall}
  {menu {checkbutton changebar::data(enabled)} "Change Bars/Enable" changebar::do_enable changebar::handle_state_enable}
  {menu separator "Change Bars"}
  {menu command "Change Bars/Clear"         changebar::do_clear     changebar::handle_state_clear}
  {menu separator "Change Bars"}
  {menu command "Change Bars/Goto Next"     changebar::do_goto_next changebar::handle_state_goto_next}
  {menu command "Change Bars/Goto Previous" changebar::do_goto_prev changebar::handle_state_goto_prev}
  {text_binding pretext changes changebar::do_bind}
}
