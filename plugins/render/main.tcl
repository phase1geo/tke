# Plugin namespace
namespace eval render {

  array set files {}
  
  ######################################################################
  # Returns true if the given filename is an HTML file.
  proc is_html {fname} {
    
    return [expr {([file extension $fname] eq ".html") || ([file extension $fname] eq ".htm")}]
    
  }
  
  ######################################################################
  # Shows the specified file in the local browser.
  proc show_in_browser {fname {in_background 0}} {
    
    variable files
    
    # Open the file in an external browser
    api::utils::open_file $fname $in_background
    
    # Keep track of the file
    set files($fname) 1
    
  }
  
  ######################################################################
  # Called when a file is saved.  Re-renders file if it is currently displayed
  # in the browser.
  proc save_show_in_browser {file_index} {
    
    variable files
    
    # Get the file name to show
    set fname [api::file::get_info $file_index fname]
    
    # If the file exists in the browser, go ahead and reload it
    if {[info exists files($fname)]} {
      after idle [list render::show_in_browser $fname 1]
    }
    
  }
  
  ######################################################################
  # Shows the associated tab file contents in the browser.
  proc tab_show_in_browser {} {
    
    # Get the filename associated with the current tab
    if {[set file_index [api::file::current_file_index]] != -1} {
      show_in_browser [api::file::get_info $file_index fname]
    }
    
  }
  
  ######################################################################
  # Handles the state of the associated "Show in browser" menu item.
  proc handle_tab_show_in_browser {} {
    
    # Get the filename associated with the current tab
    if {[set file_index [api::file::current_file_index]] != -1} {
      return [is_html [api::file::get_info $file_index fname]]
    } else {
      return 0
    }
    
  }
    
  ######################################################################
  # Shows the associated tab file contents in the browser.
  proc sb_show_in_browser {} {
    
    # Get the sidebar index
    set sb_index [lindex [api::sidebar::get_selected_indices] 0]
    
    # Display the sidebar item in the browser
    show_in_browser [api::sidebar::get_info $sb_index fname]
    
  }
  
  ######################################################################
  # Handles the stat of the associated "Show in browser" menu item.
  proc handle_sb_show_in_browser {} {
    
    if {[llength [set sb_index [api::sidebar::get_selected_indices]]] == 1} {
      return [is_html [api::sidebar::get_info $sb_index fname]]
    } else {
      return 0
    }
    
  }

}

# Register all plugin actions
api::register render {
  {tab_popup  command "Show in browser" render::tab_show_in_browser render::handle_tab_show_in_browser}
  {file_popup command "Show in browser" render::sb_show_in_browser  render::handle_sb_show_in_browser}
  {on_save    render::save_show_in_browser}
}
