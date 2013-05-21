namespace eval texttools {

  proc comment {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    foreach {endpos startpos} [lreverse $selected] {
      # FIXME
    }

  }

  proc uncomment {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    foreach {endpos startpos} [lreverse $selected] {
      # FIXME
    }

  }

}

