namespace eval utils {

  variable main_tid

  ######################################################################
  # Allows thread code to send log messages to standard output.
  proc log {msg} {

    variable main_tid

    thread::send -async $main_tid [list ctext::thread_log [thread::id] $msg]

  }

}
