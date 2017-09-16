# Plugin namespace
namespace eval regexp_checker {

  array set widgets {}

  ######################################################################
  # Displays the regular expression checker window.  If text is highlighted
  # in the current editing window, copies that text into the window's
  # text field for immediate processing.
  proc menu_do {} {

    variable widgets

    if {![winfo exists .regcheck]} {

      set w [toplevel .regcheck]
      wm title $w "Regular Expression Checker"

      ttk::labelframe $w.ef -text "Regexp Pattern"
      set widgets(entry) [ttk::entry       $w.ef.e  -validate key -validatecommand [list regexp_checker::check_after]]
      set widgets(line)  [ttk::checkbutton $w.ef.cb -text " Match on line" -command [list regexp_checker::check]]
      set widgets(copy)  [ttk::button      $w.ef.b  -text "Copy Pattern"   -command [list regexp_checker::copy] -state disabled]

      grid rowconfigure    $w.ef 2 -weight 1
      grid columnconfigure $w.ef 1 -weight 1
      grid $widgets(entry) -row 0 -column 0 -sticky news -padx 2 -pady 2 -columnspan 3
      grid $widgets(line)  -row 1 -column 0 -sticky w -padx 2 -pady 2
      grid $widgets(copy)  -row 1 -column 2 -sticky e -padx 2 -pady 2

      ttk::labelframe $w.tf -text "Text"
      set widgets(text) [text $w.tf.t -height 10 \
        -xscrollcommand [list api::set_xscrollbar $w.tf.hb] \
        -yscrollcommand [list api::set_yscrollbar $w.tf.vb]]
      ttk::scrollbar $w.tf.vb -orient vertical   -command [list $w.tf.t yview]
      ttk::scrollbar $w.tf.hb -orient horizontal -command [list $w.tf.t xview]

      bind $widgets(text) <<Modified>> [list regexp_checker::text_modified]

      grid rowconfigure    $w.tf 0 -weight 1
      grid columnconfigure $w.tf 0 -weight 1
      grid $w.tf.t  -row 0 -column 0 -sticky news
      grid $w.tf.vb -row 0 -column 1 -sticky ns
      grid $w.tf.hb -row 1 -column 0 -sticky ew

      ttk::labelframe $w.vf -text "Variables"
      set widgets(vars) [ttk::treeview $w.vf.tl -columns {value} -displaycolumns #all \
        -height 5 -yscrollcommand [list $w.vf.vb set]]
      ttk::scrollbar $w.vf.vb -orient vertical -command [list $w.vf.tl yview]

      $widgets(vars) heading #0    -text "Variable" -anchor center
      $widgets(vars) heading value -text "Value"    -anchor center

      $widgets(vars) column  #0    -anchor center
      $widgets(vars) column  value -anchor center

      grid rowconfigure    $w.vf 0 -weight 1
      grid columnconfigure $w.vf 0 -weight 1
      grid $w.vf.tl -row 0 -column 0 -sticky news
      grid $w.vf.vb -row 0 -column 1 -sticky ns

      pack $w.ef -fill x
      pack $w.tf -fill both -expand yes
      pack $w.vf -fill x

      # Create the matched color
      $widgets(text) tag configure matched -background green

      # Set the text focus
      focus $widgets(entry)

    } else {

      wm withdraw  .regcheck
      wm deiconify .regcheck

    }

    # If text was selected in the file, put it into the text widget automatically
    if {[set file_index [api::file::current_index]] != -1} {
      set txt [api::file::get_info $file_index txt]
      catch {
        if {[llength [set sel [$txt tag ranges sel]]] > 0} {
          $widgets(text) delete 1.0 end
          $widgets(text) insert end [$txt get {*}$sel]
        }
      }
    }

  }

  ######################################################################
  # Called whenever the text widget is modified.
  proc text_modified {} {

    variable widgets

    if {[$widgets(text) edit modified]} {
      $widgets(text) edit modified false
      check
    }

  }

  ######################################################################
  # Checks the regular expression match after idle.
  proc check_after {} {

    after idle regexp_checker::check

    return 1

  }

  ######################################################################
  # Called when either the pattern entry field is changed or the case
  # sensitivity is changed.  Performs the regular expression match and
  # highlights matching text in the text box.
  proc check {} {

    variable widgets

    # Get the current value in the entry field
    set value [$widgets(entry) get]

    # Remove the matched tag
    $widgets(text) tag remove matched 1.0 end

    # Create opts
    set opts [list]
    if {[lsearch [$widgets(line) state] "selected"] != -1} {
      lappend opts "-line"
    }

    # Clear the variable table
    $widgets(vars) delete [$widgets(vars) children {}]

    # Perform the match
    catch {
      if {[regexp -indices {*}$opts $value [$widgets(text) get 1.0 end-1c] all v(1) v(2) v(3) v(4) v(5) v(6) v(7) v(8) v(9)]} {
        $widgets(text) tag add matched "1.0+[lindex $all 0]c" "1.0+[expr [lindex $all 1] + 1]c"
        foreach index [list 1 2 3 4 5 6 7 8 9] {
          lassign $v($index) off1 off2
          if {$off1 != -1} {
            $widgets(vars) insert {} end -text $index -values [list [$widgets(text) get "1.0+${off1}c" "1.0+[expr $off2 + 1]c"]]
          }
        }
      }
    }

    # Handle the copy button state
    if {$value eq ""} {
      $widgets(copy) configure -state disabled
    } else {
      $widgets(copy) configure -state normal
    }

  }

  ######################################################################
  # Copies the current contents of the pattern entry field into the clipboard.
  proc copy {} {

    variable widgets

    # Clear and append the pattern text to the clipboard
    clipboard clear
    clipboard append [$widgets(entry) get]

  }

  ######################################################################
  # Handles the state of the regular expression checker.
  proc menu_handle_state {} {

    return 1

  }

}

# Register all plugin actions
api::register regexp_checker {
  {menu command {Regexp Checker} regexp_checker::menu_do regexp_checker::menu_handle_state}
}
