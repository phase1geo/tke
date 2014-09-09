# Plugin namespace
namespace eval render {

  ######################################################################
  # Returns true if the given filename is an HTML file.
  proc is_html {fname} {
    
    puts "Checking fname: $fname"
    
    return [expr {([file extension $fname] eq ".html") || ([file extension $fname] eq ".htm")}]
    
  }
  
  ######################################################################
  # Shows the specified file in the local browser.
  proc show_in_browser {fname} {
    
    # Open the file in an external browser
    api::utils::open_file $fname
    
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
    
    if {[set sb_index [api::sidebar::get_selected_index]] != -1} {
      show_in_browser [api::sidebar::get_info $sb_index fname]
    }
    
  }
  
  ######################################################################
  # Handles the stat of the associated "Show in browser" menu item.
  proc handle_sb_show_in_browser {} {
    
    if {[set sb_index [api::sidebar::get_selected_index]] != -1} {
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
  {on_save    render::tab_show_in_browser}
}
