# Plugin namespace
namespace eval calendar {

  variable date_range

  ######################################################################
  # Gets the date range from the user and returns the result as two clock
  # times in seconds.
  proc get_date_range {} {

    variable date_range

    set date_range ""
    lassign [clock format [clock seconds] -format {%B %Y}] init_month init_year

    toplevel     .calwin
    wm title     .calwin "Select Date Range"
    wm resizable .calwin 0 0
    wm transient .calwin .

    ttk::labelframe .calwin.sf    -text "First Month"
    ttk::menubutton .calwin.sf.mb -width 12 -menu [menu .calwin.smonMenu -tearoff 0]
    ttk::spinbox    .calwin.sf.sb -from 1920 -to 2050 -width 4 -increment 1

    pack .calwin.sf.mb -side left -padx 2 -pady 2
    pack .calwin.sf.sb -side left -padx 2 -pady 2

    ttk::labelframe .calwin.ef    -text "Last Month"
    ttk::menubutton .calwin.ef.mb -width 12 -menu [menu .calwin.emonMenu -tearoff 0]
    ttk::spinbox    .calwin.ef.sb -from 1920 -to 2050 -width 4 -increment 1

    pack .calwin.ef.mb -side left -padx 2 -pady 2
    pack .calwin.ef.sb -side left -padx 2 -pady 2

    ttk::frame  .calwin.bf
    ttk::button .calwin.bf.ok     -style BButton -text "OK"     -width 6 -command [list calendar::handle_ok]
    ttk::button .calwin.bf.cancel -style BButton -text "Cancel" -width 6 -command [list destroy .calwin]

    pack .calwin.bf.cancel -side right -padx 2 -pady 2
    pack .calwin.bf.ok     -side right -padx 2 -pady 2

    pack .calwin.sf -fill x
    pack .calwin.ef -fill x
    pack .calwin.bf -fill x

    # Populate the month menus
    foreach month [list January February March April May June July August September October November December] {
      .calwin.smonMenu add command -label $month -command [list .calwin.sf.mb configure -text $month]
      .calwin.emonMenu add command -label $month -command [list .calwin.ef.mb configure -text $month]
    }

    # Initialize the widgets
    .calwin.sf.mb configure -text $init_month
    .calwin.sf.sb set $init_year
    .calwin.ef.mb configure -text $init_month
    .calwin.ef.sb set $init_year

    # Wait for the window
    ::tk::PlaceWindow  .calwin widget .
    ::tk::SetFocusGrab .calwin .calwin.sf.mb
    tkwait window .calwin
    ::tk::RestoreFocusGrab .calwin .calwin.sf.mb

    return $date_range

  }

  ######################################################################
  # Handles a keypress of the OK button in the date range selection window.
  proc handle_ok {} {

    variable date_range

    set sdate      [clock scan "[.calwin.sf.mb cget -text] 1, [.calwin.sf.sb get]"]
    set edate      [clock add [clock scan "[.calwin.ef.mb cget -text] 1, [.calwin.ef.sb get]"] 1 month]
    set date_range [list $sdate $edate]

    destroy .calwin

  }

  ######################################################################
  # Inserts a month calendar
  proc insert_month {txt start_date end_date} {

    set str      ""
    set dow      [expr [clock format $start_date -format {%u}] % 7]
    set last_day [clock format [clock add $end_date -1 day] -format {%e}]
    set col      [lindex [split [$txt index insert] .] 1]
    set prefix   [expr {($col == 0) ? "" : [string repeat { } $col]}]
    set title    [clock format $start_date -format {%B %Y}]

    append str [string repeat { } [expr int( (21 - [string length $title]) / 2.0 )]] $title \n $prefix
    append str "S  M  T  W  T  F  S" \n $prefix

    if {$dow > 0} {
      append str [string repeat {   } $dow]
    }

    # Insert the days into the string
    for {set day 1} {$day <= $last_day} {incr day} {
      append str [format {%-3d} $day]
      if {[set dow [expr ($dow + 1) % 7]] == 0} {
        append str \n $prefix
      }
    }

    # Insert the string
    $txt insert insert "[string trimright $str]\n\n$prefix"

  }

  ######################################################################
  # Inserts the calendar.
  proc do_insert {} {

    if {[set date_range [get_date_range]] ne ""} {

      lassign $date_range start_date end_date

      # Get the current text widget
      set txt [api::file::get_info [api::file::current_file_index] txt]

      # Insert each month
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
  {menu command "Calendar/Insert Mini Calendar" calendar::do_insert calendar::handle_insert_state}
}
