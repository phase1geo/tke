# Plugin namespace
namespace eval regexp_checker {

  array set widgets {}

  proc menu_do {} {

    variable widgets

    set w [toplevel .regcheck]
    wm title     $w "Regular Expression Checker"

    ttk::labelframe $w.ef -text "Regexp Pattern"
    pack [set widgets(entry) [ttk::entry $w.ef.e -validate key -validatecommand [list regexp_checker::check %P]]] -fill x

    ttk::labelframe $w.tf -text "Text"
    set widgets(text) [text $w.tf.t -xscrollcommand [list api::set_xscrollbar $w.tf.hb] -yscrollcommand [list api::set_yscrollbar $w.tf.vb]]
    ttk::scrollbar $w.tf.vb -orient vertical   -command [list $w.tf.t yview]
    ttk::scrollbar $w.tf.hb -orient horizontal -command [list $w.tf.t xview]

    grid rowconfigure    $w.tf 0 -weight 1
    grid columnconfigure $w.tf 0 -weight 1
    grid $w.tf.t  -row 0 -column 0 -sticky news
    grid $w.tf.vb -row 0 -column 1 -sticky ns
    grid $w.tf.hb -row 1 -column 0 -sticky ew

    pack $w.ef -fill x    -padx 2 -pady 2
    pack $w.tf -fill both -padx 2 -pady 2

    $widgets(text) tag configure matched -background green

  }

  proc check {value} {

    variable widgets

    $widgets(text) tag remove matched 1.0 end

    if {[regexp -indices -- $value [$widgets(text) get 1.0 end-1c] all]} {
      $widgets(text) tag add matched {*}$all
    }

    return 1

  }

  proc menu_handle_state {} {

    return 1

  }

}

# Register all plugin actions
api::register regexp_checker {
  {menu command {Regexp Checker/Check} regexp_checker::menu_do regexp_checker::menu_handle_state}
}
