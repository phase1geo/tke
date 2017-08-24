# Plugin namespace
namespace eval publish_markdown {

  ######################################################################
  # Perform the publish operation.
  proc publish_do {} {

    foreach index [api::sidebar::get_selected_indices] {

      set str ""

      # Collate the Markdown content into a single string
      publish_collate $index str

      # Get the directory name
      set dname [file tail [api::sidebar::get_info $index fname]]
      
      # Write the contents to a file
      if {![catch { open [file join ~ Documents $dname.md] w } rc]} {
        puts $rc $str
        close $rc
      }

    }

  }

  ######################################################################
  # Gather the contents of each Markdown file in a depth-first method into
  # a single string.
  proc publish_collate {index pstr} {

    upvar $pstr str

    if {[api::sidebar::get_info $index is_dir]} {
      
      # Open the directory if it isn't already
      if {[set was_opened [api::sidebar::get_info $index is_open]] == 0} {
        api::sidebar::set_info $index open 1
      }

      # Collate the children
      foreach child [api::sidebar::get_info $index children] {
        publish_collate $child str
      }

      # Close the directory contents when we are done with it if it was previously
      # closed.
      if {!$was_opened} {
        api::sidebar::set_info $index open 0
      }

    } else {

      if {[lsearch {.md .mmd .markdown} [file extension [set fname [api::sidebar::get_info $index fname]]]] != -1} {
        if {![catch { open $fname r } rc]} {
          append str [string trim [read $rc]]
          append str "\n\n"
          close $rc
        }
      }

    }

  }

  ######################################################################
  # Handle the state of the Publish Markdown option.
  proc publish_handle_state {} {

    foreach index [api::sidebar::get_selected_indices] {
      if {[api::sidebar::get_info $index sortby] eq "manual"} {
        return 1
      }
    }

    return 0

  }

}

# Register all plugin actions
api::register publish_markdown {
  {root_popup command {Publish Markdown} publish_markdown::publish_do publish_markdown::publish_handle_state}
  {dir_popup  command {Publish Markdown} publish_markdown::publish_do publish_markdown::publish_handle_state}
}
