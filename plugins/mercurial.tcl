# HEADER_BEGIN
# NAME         mercurial
# AUTHOR       Trevor Williams  (phase1geo@gmail.com)
# DATE         6/18/2013
# INCLUDE      yes
# DESCRIPTION  Provides several often used Mercurial commands in the menu bar.
# HEADER_END

namespace eval plugins::mercurial {
  
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
  
  # Figure out if the hg stuff will work or not
  if {[catch "exec hg status"]} {
    set enabled 0
  } else {
    set enabled 1
  }
  
}

plugins::register mercurial {
  {menu command "Mercurial Commands.Display hg status output" plugins::mercurial::status_do plugins::mercurial::status_state}
  {menu command "Mercurial Commands.Commit current files"     plugins::mercurial::commit_do plugins::mercurial::commit_state}
  {menu command "Mercurial Commands.Push changelists"         plugins::mercurial::push_do   plugins::mercurial::push_state}
  {menu command "Mercurial Commands.Pull changelists"         plugins::mercurial::pull_do   plugins::mercurial::pull_state}
}

