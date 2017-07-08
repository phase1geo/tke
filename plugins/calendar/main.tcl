# Plugin namespace
namespace eval calendar {

  ######################################################################
  proc get_date_range {} {

    return [list August 2017 August 2017]

  }

  ######################################################################
  proc insert_month {txt start_date end_date} {

    set dow [clock format $date -format {%u}]
    set day 1

    $txt insert insert "\n[clock format $week_start -format {%B %Y}]\n"
    $txt insert insert "S  M  T  W  T  F  S"

    $txt insert insert [string repeat {   } [expr ($week_start % 7) - 1]]

    while {$date < $next} {
      if {$dow == 0} {
        $txt insert insert "\n"
      }
      $txt insert insert [format {%2d } $day]
      incr day
      incr dow
    }

  }

  ######################################################################
  proc do_insert {} {

    if {[set date_range [get_date_range]] ne ""} {
      set start_date [clock scan [lrange $date_range 0 1]]
      set end_date   [clock add [clock scan [lrange $date_range 2 3]] 1 month]
      set txt        [api::file::get_info [api::file::current_file_index] txt]
      while {$start_date < $end_date} {
        insert_month $txt $start_date $end_date
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
