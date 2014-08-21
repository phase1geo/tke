namespace eval mercurial {
  
  variable enabled 0
  
  ######################################################################
  # Performs an 'hg status' command and displays it to a scratch file
  proc status_do {} {
    
    if {[catch "exec hg status" rc]} {
      api::show_info "Mercurial status failed: [lindex [split $rc \n] 0]"
    }
    
  }
  
  ######################################################################
  # Returns 1 or 0 depending on whether the status command can be executed.
  proc status_state {} {
    
    variable enabled
    
    return $enabled
    
  }
  
  ######################################################################
  # Performs an 'hg commit' command and displays it to a scratch file.
  proc commit_do {} {
    
    set msg ""
    
    # Get the commit message from the user
    if {[api::get_user_input "Commit message" msg]} {
    
      if {[catch "exec hg commit -m {$msg}" rc]} {
        api::show_info "Mercurial commit failed: [lindex [split $rc \n] 0]"
      }
      
    }
    
  }
  
  ######################################################################
  # Returns 1 or 0 depending on whether the commit command can be executed.
  proc commit_state {} {
    
    variable enabled
    
    return $enabled
    
  }
  
  ######################################################################
  # Performs an 'hg push' command and displays it to a scratch file.
  proc push_do {} {
    
    if {[catch "exec hg push" rc]} {
      api::show_info "Mercurial push failed: [lindex [split $rc \n] 0]"
    }
    
  }
  
  ######################################################################
  # Returns 1 or 0 depending on whether the push command can be executed.
  proc push_state {} {
    
    variable enabled
    
    return $enabled
    
  }
  
  ######################################################################
  # Performs an 'hg pull' command and displays it to a scratch file.
  proc pull_do {} {
    
    if {[catch "exec hg pull -u" rc]} {
      api::show_info "Mercurial pull failed: [lindex [split $rc \n] 0]"
    }
    
  }
  
  ######################################################################
  # Returns 1 or 0 depending on whether the pull command can be executed.
  proc pull_state {} {
    
    variable enabled
    
    return $enabled
    
  }
  
  ######################################################################
  # Reverts the current file.
  proc revert_do {} {
    
    if {[catch "exec hg revert -C [api::file::get_info [api::file::current_file_index] fname]" rc]} {
      api::show_info "Mercurial revert failed: [lindex [split $rc \n] 0]"
    }
    
  }
  
  ######################################################################
  # Returns 1 or 0 depending on whether the revert command can be
  # executed.
  proc revert_state {} {
    
    variable enabled
    
    return $enabled
    
  }
  
  # Figure out if the hg stuff will work or not
  if {[catch "exec hg status"]} {
    set enabled 0
  } else {
    set enabled 1
  }
  
}

api::register mercurial {
  {menu command "Mercurial Commands/Display hg status output" mercurial::status_do mercurial::status_state}
  {menu command "Mercurial Commands/Commit current files"     mercurial::commit_do mercurial::commit_state}
  {menu command "Mercurial Commands/Push changelists"         mercurial::push_do   mercurial::push_state}
  {menu command "Mercurial Commands/Pull changelists"         mercurial::pull_do   mercurial::pull_state}
  {menu separator "Mercurial Commands"}
  {menu command "Mercurial Commands/Revert current file"      mercurial::revert_do mercurial::revert_state}
}

