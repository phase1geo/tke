namespace eval utils {

  variable main_tid ""

  ######################################################################
  # Renders the given tag with the specified ranges.
  proc log {msg} {

    variable main_tid

    thread::send -async $main_tid [list ctext::thread_log [thread::id] $msg]

  }

}
