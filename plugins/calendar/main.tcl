# Plugin namespace
namespace eval calendar {

  ######################################################################
  # Gets the date range from the user and returns the result as two clock
  # times in seconds.
  proc get_date_range {} {

    return [list [clock scan {August 1, 2017}] [clock scan {October 1, 2017}]]

  }

  ######################################################################
  # Inserts a month calendar
  proc insert_month {txt start_date end_date} {

    set dow [expr [clock format $start_date -format {%u}] % 7]
    set day 1

    $txt insert insert "\n[clock format $start_date -format {%B %Y}]\n"
    $txt insert insert "S  M  T  W  T  F  S\n"

    if {$dow > 0} {
      $txt insert insert [string repeat {   } $dow]
    }

    while {$start_date < $end_date} {
      $txt insert insert [format {%-3d} $day]
      incr day
      set dow        [expr ($dow + 1) % 7]
      set start_date [clock add $start_date 1 day]
      if {$dow == 0} {
        $txt insert insert "\n"
      }
    }

    $txt replace insert-1c insert "\n"

  }

  ######################################################################
  # Inserts the calendar.
  proc do_insert {} {

    if {[set date_range [get_date_range]] ne ""} {
      lassign $date_range start_date end_date
      set txt [api::file::get_info [api::file::current_file_index] txt]
      while {$start_date < $end_date} {
        insert_month $txt $start_date [clock add $start_date 1 month]
        set start_date [clock add $start_date 1 month]
      }
    }

  }

  ######################################################################
  # Handles the insert menu state.
  proc handle_insert_state {} {

    return 1

  }

}

# Register all plugin actions
api::register calendar {
  {menu command "Calendar/Insert" calendar::do_insert calendar::handle_insert_state}
}
