# Plugin namespace
namespace eval line_count {

  proc do_line_count {} {

    # Create the UI
    create_window

    # Populate the UI
    foreach index [api::sidebar::get_selected_indices] {
      add_items [api::sidebar::get_info $index fname]
    }

    # Update the table
    .lcwin.tf.tl embedttkcheckbuttons included [list line_count::included_changed]
    .lcwin.tf.tl collapseall

  }

  proc create_window {} {

    toplevel .lcwin
    wm title .lcwin "Line Counter"

    ttk::frame .lcwin.tf
    tablelist .lcwin.tf.tl -columns {0 {} 0 {Pathname} 0 {Line Count}} \
      -treecolumn 1 -stretch all \
      -yscrollcommand {.lcwin.tf.vb set} -xscrollcommand {.lcwin.tf.hb set}
    ttk::scrollbar .lcwin.tf.vb -orient vertical   -command {.lcwin.tf.tl yview}
    ttk::scrollbar .lcwin.tf.hb -orient horizontal -command {.lcwin.tf.tl xview}

    .lcwin.tf.tl columnconfigure 0 -name included -resizable 0 -stretchable 0 -formatcommand line_count::empty_string
    .lcwin.tf.tl columnconfigure 1 -name path     -editable 0  -stretchable 1 -formatcommand line_count::show_path -maxwidth 60
    .lcwin.tf.tl columnconfigure 2 -name lines    -editable 0  -stretchable 0 -resizable 0 -editable 0

    grid rowconfigure    .lcwin.tf 0 -weight 1
    grid columnconfigure .lcwin.tf 0 -weight 1
    grid .lcwin.tf.tl -row 0 -column 0 -sticky news
    grid .lcwin.tf.vb -row 0 -column 1 -sticky ns
    grid .lcwin.tf.hb -row 1 -column 0 -sticky ew

    pack .lcwin.tf -fill both -expand yes

  }

  proc included_changed {tbl row col} {

    set lines    [$tbl cellcget $row,lines -text]
    set included [$tbl cellcget $row,included -text]
    set adjust   [expr $included ? $lines : (0 - $lines)]

    set_included $tbl $row $included

    while {[set row [$tbl parentkey $row]] ne "root"} {
      $tbl cellconfigure $row,lines -text [expr [$tbl cellcget $row,lines -text] + $adjust]
      set include 0
      foreach child [$tbl childkeys $row] {
        if {[$tbl cellcget $child,included -text]} {
          set include 1
          break
        }
      }
      $tbl cellconfigure $row,included -text $include
    }

  }

  proc set_included {tbl parent included} {

    set children [$tbl childkeys $parent]

    if {[llength $children] > 0} {
      $tbl cellconfigure $parent,lines -text 0
      foreach row [$tbl childkeys $parent] {
        $tbl cellconfigure $row,included -text $included
        set_included $tbl $row $included
      }
    }

  }

  proc empty_string {value} {

    return ""

  }

  proc show_path {value} {

    lassign [.lcwin.tf.tl formatinfo] key row col

    if {[.lcwin.tf.tl parentkey $row] eq "root"} {
      return $value
    } else {
      return [file tail $value]
    }

  }

  proc add_items {fname {parent root}} {

    set lines 0

    if {[file isdirectory $fname]} {
      set parent [.lcwin.tf.tl insertchild $parent end [list 1 $fname 0]]
      foreach item [lsort [glob -directory $fname *]] {
        incr lines [add_items $item $parent]
      }
      .lcwin.tf.tl cellconfigure $parent,lines -text $lines
    } else {
      if {![catch { open $fname r } rc]} {
        set lines [llength [split [read $rc] \n]]
        close $rc
        .lcwin.tf.tl insertchild $parent end [list 1 $fname $lines]
      }
    }

    return $lines

  }

  # Only allow the menu item to be enabled if the UI window does not exist
  proc handle_menu_status {} {

    return [expr [winfo exists .lcwin] ^ 1]

  }

}

# Register all plugin actions
api::register line_count {
  {root_popup command "Line count report" line_count::do_line_count line_count::handle_menu_status}
  {dir_popup  command "Line count report" line_count::do_line_count line_count::handle_menu_status}
}
