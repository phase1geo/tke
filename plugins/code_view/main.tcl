namespace eval code_view {
  
  ######################################################################
  # Adds a command launcher registration to quickly put the current
  # buffer into locked mode and format the text for easier viewing.
  proc on_start {} {
    
    api::register_launcher "Run code_view workflow" code_view::run
    
  }
  
  ######################################################################
  # Runs the code view workflow.
  proc run {} {
    
    if {![api::file::get_info [api::file::current_file_index] lock]} {
      api::invoke_menu "File/Lock"
      api::invoke_menu "Edit/Format Text/All"
    } 
    
  }
  
  ######################################################################
  # Unregisters the command-launcher registration.
  proc on_uninstall {} {
    
    api::unregister_launcher "Run code_view workflow"
    
  }

}

api::register code_view {
  {on_start     code_view::on_start}
  {on_uninstall code_view::on_uninstall}
}
