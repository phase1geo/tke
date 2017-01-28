# Plugin namespace
namespace eval regexp_checker {

  array set widgets {}

  proc menu_do {} {

    variable widgets

    set w [toplevel .regcheck]
    wm title $w "Regular Expression Checker"

    ttk::labelframe $w.ef -text "Regexp Pattern"
    set widgets(entry) [ttk::entry       $w.ef.e  -validate key -validatecommand [list regexp_checker::check %P]]
    set widgets(case)  [ttk::checkbutton $w.ef.cb -text " Case-sensitive" -command [list regexp_checker::check_with_case]]
    set widgets(copy)  [ttk::button      $w.ef.b  -text "Copy Pattern"    -command [list regexp_checker::copy] -state disabled]

    grid rowconfigure    $w.ef 2 -weight 1
    grid columnconfigure $w.ef 1 -weight 1
    grid $widgets(entry) -row 0 -column 0 -sticky news -padx 2 -pady 2 -columnspan 3
    grid $widgets(case)  -row 1 -column 0 -sticky w -padx 2 -pady 2
    grid $widgets(copy)  -row 1 -column 2 -sticky e -padx 2 -pady 2

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

    # Create the matched color
    $widgets(text) tag configure matched -background green

    # Set the text focus
    focus $widgets(entry)

    # If text was selected in the file, put it into the text widget automatically
    if {[set file_index [api::file::current_file_index]] != -1} {
      set txt [api::file::get_info $file_index txt]
      if {[llength [set sel [$txt tag ranges sel]]] > 0} {
        $widgets(text) insert end [$txt get {*}$sel]
      }
    }

  }

  proc check {{value ""}} {

    variable widgets

    # Remove the matched tag
    $widgets(text) tag remove matched 1.0 end

    # Create opts
    set opts [list]
    if {[$widgets(case) state] ne "selected"} {
      lappend opts "-nocase"
    }

    # Perform the match
    catch {
      if {[regexp -indices {*}$opts [string map {\\ \\\\} $value] [$widgets(text) get 1.0 end-1c] all]} {
        $widgets(text) tag add matched "1.0+[lindex $all 0]c" "1.0+[expr [lindex $all 1] + 1]c"
      }
    }

    # Handle the copy button state
    if {$value eq ""} {
      $widgets(copy) configure -state disabled
    } else {
      $widgets(copy) configure -state normal
    }

    return 1

  }

  proc check_with_case {} {

    variable widgets

    return [check [$widgets(entry) get]]

  }

  proc copy {} {

    variable widgets

    # Clear and append the pattern text to the clipboard
    clipboard clear
    clipboard append [$widgets(entry) get]

  }

  proc menu_handle_state {} {

    return 1

  }

}

# Register all plugin actions
api::register regexp_checker {
  {menu command {Regexp Checker/Check} regexp_checker::menu_do regexp_checker::menu_handle_state}
}
