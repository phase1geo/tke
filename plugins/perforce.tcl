# HEADER_BEGIN
# NAME         perforce
# AUTHOR       Trevor Williams  (phase1geo@gmail.com)
# DATE         07/10/2013
# INCLUDE      yes
# DESCRIPTION  Performs a Perforce edit (or add) when a file is opened.
# HEADER_END

namespace eval plugins::perforce {
  
  variable disable_edit 0
  
  ######################################################################
  # Allow us to change the disable status of the "edit on open" menu
  # option.
  proc toggle_edit_do {} {
    
    # We don't need to do anything special here
    
  }
  
  ######################################################################
  # Always allow the user to change the state of the "edit on open"
  # menu option.
  proc toggle_edit_state {} {
    
    return 1
    
  }
  
  ######################################################################
  # When a file is opened in a tab, this procedure is invoked which will
  # perform a Perforce edit if the file exists.
  proc on_open_do {file_index} {
    
    variable disable_edit
    
    if {!$disable_edit} {
      
      # Get the filename
      set fname [api::get_file_info $file_index fname]
    
      # If the file does not exist, do a Perforce add
      if {[file exists $fname] && ![catch "exec p4 edit $fname"]} {
        api::show_info "File in Perforce edit state"
      }
      
    }
    
  }

}

plugins::register perforce {
  {menu {checkbutton plugins::perforce::disable_edit} "Perforce Options.Disable edit on open" plugins::perforce::toggle_edit_do plugins::perforce::toggle_edit_state}
  {on_open plugins::perforce::on_open_do}
}
