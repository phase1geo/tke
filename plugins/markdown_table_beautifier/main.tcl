# Plugin namespace
namespace eval markdown_table_beautifier {

  proc beautify_do {} {

    # Get the text widget
    set txt [api::file::get_info [api::file::current_file_index] txt]

    foreach {endpos startpos} [lreverse [find_tables $txt]] {
      beautify_table $txt $startpos $endpos
    }

  }

  # Handle the state of the Beautify command
  proc beautify_handle_state {} {

    set lang [api::file::get_info [api::file::current_file_index] lang]

    return [expr {($lang eq "Markdown") || ($lang eq "MultiMarkdown")}]

  }

  ######################################################################
  # Returns a list containing the start and end positions of found Markdown
  # tables in the text widget.
  proc find_tables {txt} {

    set last_line -1
    set ranges    [list]

    foreach index [$txt search -all -forwards -regexp -- {^\s*\|} 1.0 end] {
      set line [lindex [split $index .] 0]
      if {($last_line + 1) != $line} {
        if {$last_line != -1} {
          lappend ranges [$txt index "$last_line.0 lineend"]
        }
        lappend ranges [$txt index "$index linestart"]
      }
      set last_line $line
    }

    if {$last_line != -1} {
      lappend ranges [$txt index "$last_line.0 lineend"]
    }

    return $ranges

  }

  ######################################################################
  # Beautifies the table specified in the given range.
  proc beautify_table {txt startpos endpos} {

    # Create a matrix containing the positions of each column divider in all rows
    set matrix [create_table_matrix $txt $startpos $endpos]

    # Figure out the width of each column
    set col_widths [calculate_col_widths $matrix]

    # Adjust rows
    adjust_rows $txt $matrix $col_widths

  }

  ######################################################################
  # Returns a two dimensional table containing the column divider positions
  # for each row/column.
  proc create_table_matrix {txt startpos endpos} {

    set rows     [list]
    set row      [list]
    set curr_row [lindex [split $startpos .] 0]

    # Gather the matrix results
    foreach index [$txt search -all -forwards "|" $startpos $endpos] {
      lassign [split $index .] rowpos colpos
      if {$curr_row != $rowpos} {
        lappend rows [list $curr_row.0 $row]
        set row      [list]
        set curr_row $rowpos
      }
      lappend row $colpos
    }
    lappend rows [list $curr_row.0 $row]

    return $rows

  }

  ######################################################################
  # Calculate the max column widths.  Returns a list for each table column
  # with the width of the column.
  proc calculate_col_widths {matrix} {

    set col_widths [list]

    set min 10000
    foreach row $matrix {
      if {[lindex $row 1 0] < $min} {
        set min [lindex $row 1 0]
      }
    }

    lappend col_widths $min

    for {set div 0} {$div < ([llength [lindex $matrix 0 1]] - 1)} {incr div} {
      set max 0
      foreach row $matrix {
        set col_width [expr ([lindex $row 1 [expr $div + 1]] - [lindex $row 1 $div]) - 1]
        if {$col_width > $max} {
          set max $col_width
        }
      }
      lappend col_widths $max
    }

    return $col_widths

  }

  ######################################################################
  # Adjust the spacing of all rows in the given table.
  proc adjust_rows {txt matrix col_widths} {

    foreach row [lreverse $matrix] {
      adjust_row $txt {*}$row $col_widths
    }

  }

  ######################################################################
  # Adjusts the spacing of the given row.
  proc adjust_row {txt startpos divs widths} {

    set col [expr [llength $widths] - 1]
    for {set div [expr [llength $divs] - 1]} {$div > 0} {incr div -1} {
      set col_width [expr ([lindex $divs $div] - [lindex $divs [expr $div - 1]]) - 1]
      if {[set spaces [expr [lindex $widths $col] - $col_width]] > 0} {
        $txt fastinsert "$startpos+[lindex $divs $div]c" [string repeat " " $spaces]
      }
      incr col -1
    }

    if {[lindex $widths 0] != [lindex $divs 0]} {
      $txt fastdelete "$startpos+[lindex $widths 0]c" "$startpos+[lindex $divs 0]c"
    }

  }

}

# Register all plugin actions
api::register markdown_table_beautifier {
  {menu command {Markdown Table Beautifier/Beautify} markdown_table_beautifier::beautify_do markdown_table_beautifier::beautify_handle_state}
}
