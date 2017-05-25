# Plugin namespace
namespace eval markdown_table_beautifier {

  ######################################################################
  # Beautify all of the tables.
  proc beautify_all_do {} {

    # Get the text widget
    set txt [api::file::get_info [api::file::current_file_index] txt]

    foreach {endpos startpos} [lreverse [find_all_tables $txt]] {
      beautify_table $txt $startpos $endpos
    }

    # Remove any selections
    $txt tag remove sel 1.0 end

    # Add a separator
    $txt edit separator

  }

  ######################################################################
  # Handle the state of the Beautify command
  proc beautify_all_handle_state {} {

    if {![catch { api::file::get_info [api::file::current_file_index] lang } lang]} {
      return [expr {($lang eq "Markdown") || ($lang eq "MultiMarkdown")}]
    }

    return 0

  }

  ######################################################################
  # Beautify the current table
  proc beautify_current_do {} {

    set txt [api::file::get_info [api::file::current_file_index] txt]

    if {[set selected [$txt tag ranges sel]] ne ""} {
      foreach {endpos startpos} [lreverse [find_all_tables $txt]] {
        if {([$txt compare $startpos <= [lindex $selected 0]] && [$txt compare [lindex $selected 0] <= $endpos]) || \
            ([$txt compare [lindex $selected 0] <= $startpos] && [$txt compare $startpos <= [lindex $selected 1]])} {
          beautify_table $txt $startpos $endpos
        }
      }
    } else {
      foreach {startpos endpos} [find_all_tables $txt] {
        if {[$txt compare $startpos <= insert] && [$txt compare insert <= $endpos]} {
          beautify_table $txt $startpos $endpos
          break
        }
      }
    }

    # Remove any selections
    $txt tag remove sel 1.0 end

    # Add a separator
    $txt edit separator

  }

  ######################################################################
  # Handles the state of the beautify current state menu option.
  proc beautify_current_handle_state {} {

    if {![catch { api::file::get_info [api::file::current_file_index] lang } lang]} {
      return [expr {($lang eq "Markdown") || ($lang eq "MultiMarkdown")}]
    }

    return 0

  }

  ######################################################################
  # Returns a list containing the start and end positions of found Markdown
  # tables in the text widget.
  proc find_all_tables {txt} {

    set last_line -1
    set ranges    [list]

    foreach index [$txt search -all -forwards -regexp -- {^[ \t]*\|} 1.0 end] {
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
    set col_widths [get_col_widths $matrix]

    # Figure out alignment
    set col_aligns [get_col_aligns $matrix]

    # Adjust rows
    adjust_rows $txt $startpos $endpos $matrix $col_widths $col_aligns

  }

  ######################################################################
  # Returns a two dimensional table containing the column divider positions
  # for each row/column.
  proc create_table_matrix {txt startpos endpos} {

    set rows [list]
    set max  0

    foreach rowstr [split [$txt get $startpos $endpos] \n] {
      set row [list]
      foreach item [lrange [split $rowstr |] 0 end-1] {
        lappend row [string trim $item]
      }
      if {[llength $row] > $max} {
        set max [llength $row]
      }
      lappend rows $row
    }

    # Perform any table adjustments to account for row number mismatches
    set i 0
    foreach row $rows {
      if {[llength $row] < $max} {
        lappend row {*}[lrepeat [expr $max - [llength $row]] [expr {($i == 1) ? "?" : ""}]]
        lset rows $i $row
      }
      incr i
    }

    return $rows

  }

  ######################################################################
  # Calculate the max column widths.  Returns a list for each table column
  # with the width of the column.
  proc get_col_widths {matrix} {

    set col_widths [list]

    set min 10000
    foreach row $matrix {
      set col_width [string length [lindex $row 0]]
      if {$col_width < $min} {
        set min $col_width
      }
    }

    lappend col_widths $min

    for {set col 1} {$col < [llength [lindex $matrix 0]]} {incr col} {
      set max 0
      set num 0
      foreach row $matrix {
        set col_width [expr {($num == 1) ? 0 : [string length [lindex $row $col]]}]
        if {$col_width > $max} {
          set max $col_width
        }
        incr num
      }
      lappend col_widths $max
    }

    return $col_widths

  }

  ######################################################################
  # Get the column alignment information from the matrix.
  proc get_col_aligns {matrix} {

    set aligns [list]

    foreach item [lindex $matrix 1] {
      if {[string index $item 0] eq ":"} {
        if {[string index $item end] eq ":"} {
          lappend aligns "center"
        } else {
          lappend aligns "left"
        }
      } else {
        if {[string index $item end] eq ":"} {
          lappend aligns "right"
        } elseif {[string index $item 0] eq "?"} {
          if {[llength [lsearch -all $aligns "none"]] == [llength $aligns]} {
            lappend aligns "none"
          } else {
            lappend aligns "left"
          }
        } else {
          lappend aligns "none"
        }
      }
    }

    return $aligns

  }

  ######################################################################
  # Adjust the spacing of all rows in the given table.
  proc adjust_rows {txt startpos endpos matrix col_widths col_aligns} {

    set rows   [list]
    set rownum 0
    foreach row $matrix {
      if {$rownum == 1} {
        lappend rows [create_align_row $col_widths $col_aligns]
      } else {
        lappend rows [adjust_data_row $row $col_widths $col_aligns]
      }
      incr rownum
    }

    # Replace the table text
    $txt replace $startpos $endpos [join $rows \n]

  }

  ######################################################################
  # Adjusts the spacing of the given row.
  proc adjust_data_row {row widths aligns} {

    lset row 0 [expr {([lindex $widths 0] > 0) ? [string repeat " " [lindex $widths 0]] : ""}]

    for {set col 1} {$col < [llength $row]} {incr col} {
      if {[set spaces [expr [lindex $widths $col] - [string length [lindex $row $col]]]] > 0} {
        switch [lindex $aligns $col] {
          "left" -
          "none" {
            lset row $col " [lindex $row $col][string repeat { } $spaces] "
          }
          "right" {
            lset row $col " [string repeat { } $spaces][lindex $row $col] "
          }
          "center" {
            set rspaces [expr $spaces / 2]
            set lspaces [expr $spaces - $rspaces]
            lset row $col " [expr {($lspaces > 0) ? [string repeat { } $lspaces] : {}}][lindex $row $col][expr {($lspaces > 0) ? [string repeat { } $rspaces] : {}}] "
          }
        }
      } else {
        lset row $col " [lindex $row $col] "
      }
    }

    return "[join $row |]|"

  }

  ######################################################################
  # Creates the alignment row content.
  proc create_align_row {widths aligns} {

    lappend row [expr {([lindex $widths 0] > 0) ? [string repeat " " [lindex $widths 0]] : ""}]

    for {set col 1} {$col < [llength $widths]} {incr col} {
      switch [lindex $aligns $col] {
        "left" {
          lappend row ":[string repeat {-} [expr [lindex $widths $col] + 1]]"
        }
        "right" {
          lappend row "[string repeat {-} [expr [lindex $widths $col] + 1]]:"
        }
        "center" {
          lappend row ":[string repeat {-} [lindex $widths $col]]:"
        }
        "none" {
          lappend row "[string repeat {-} [expr [lindex $widths $col] + 2]]"
        }
      }
    }

    return "[join $row |]|"

  }

}

# Register all plugin actions
api::register markdown_table_beautifier {
  {menu command {Markdown Table Beautifier/Beautify All Tables}    markdown_table_beautifier::beautify_all_do markdown_table_beautifier::beautify_all_handle_state}
  {menu command {Markdown Table Beautifier/Beautify Current Table} markdown_table_beautifier::beautify_current_do markdown_table_beautifier::beautify_current_handle_state}
}
