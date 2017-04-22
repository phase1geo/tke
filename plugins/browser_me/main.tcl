# Plugin namespace
namespace eval browser_me {

  proc do {} {

    set indices [api::sidebar::get_selected_indices]

    foreach index $indices {
      if {[set fname [api::sidebar::get_info $index fname]] ne ""} {
        api::utils::open_file $fname 0
      }
    }

  }

  proc handle_state {} {

    set indices [api::sidebar::get_selected_indices]

    foreach index $indices {

      set fname [api::sidebar::get_info $index fname]

      switch -nocase [file extension $fname] {
        ".htm"  -
        ".html" -
        ".png"  -
        ".jpg"  -
        ".jpeg" -
        ".tiff" -
        ".gif"  {
          # These are supported
        }
        default {
          return 0
        }
      }

    }

    return 1

  }

}

# Register all plugin actions
api::register browser_me {
  {file_popup command "Show in Browser" browser_me::do browser_me::handle_state}
}
