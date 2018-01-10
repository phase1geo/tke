######################################################################
# Name:    model.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    10/20/2017
# Brief:   Data model for a syntax buffer.  Contains marker positions that would otherwise
#          be stored within the text widget as tags, but is much more performant.
#          This code will be executed by all threads and manipulates a data structure
#          that will be shared in its nature.
######################################################################

package require Thread

# TBD - We need to enhance this
switch -glob $tcl_platform(os) {
  Darwin  { load -lazy [file join [ctext::DIR] model.dylib] }
  *Win* -
  CYG*    { load -lazy [file join [ctext::DIR] model.dll] }
  default { load -lazy [file join [ctext::DIR] model.so] }
}

namespace eval model {

  array set data {}

  ######################################################################
  # Creates a new tree for the given window
  proc create {win} {

    variable data

    set data($win,model) [model $win]
    set data($win,debug) 0

    # Add the escape type
    add_type $win "escape" 0 0 0 0 0

  }

  ######################################################################
  # Removes the memory associated with the model.
  proc destroy {win} {

    variable data

    # Destroy the tree
    $data($win,model) -delete

    # Clear the rest of the memory
    array unset data $win,*

  }

  ######################################################################
  # Clears the data stored in the model for reuse.
  proc clear {win} {

    variable data

    $data($win,model) clear

  }

  ######################################################################
  # Sets the debug variable and save it for future purposes
  proc set_debug {win value} {

    variable data

    set data($win,debug) $value

  }

  ######################################################################
  # Displays the serial list to standard output.
  proc debug_show_serial {win {msg "Serial"}} {

    variable data

    ctext::utils::log "$msg:"
    ctext::utils::log [$data($win,model) showserial]

  }

  ######################################################################
  # Displays the specified tree to standard output.
  proc debug_show_tree {win {msg "Tree"}} {

    variable data

    ctext::utils::log "$msg:"
    ctext::utils::log [$data($win,model) showtree]

  }

  ######################################################################
  # Adds the given types to the model.
  proc add_type {win name tagname matching comstr indent reindent reindentStart} {

    variable data

    $data($win,model) addtype [list $name $tagname $matching $comstr $indent $reindent $reindentStart]

  }

  ######################################################################
  # Returns the tagname associated with the given type.
  proc get_tagname {win type} {

    variable data

    return $data($win,tags,$type)

  }

  ######################################################################
  # Returns true if the character at the given index is escaped.
  proc is_escaped {win tindex} {

    variable data

    return [$data($win,model) isescaped $tindex]

  }

  ######################################################################
  # Returns true if the given index contains the given information.
  proc is_index {win type tindex} {

    variable data

    return [$data($win,model) isindex $type $tindex]

  }

  ######################################################################
  # Returns a list containing the indices of all comment markers in
  # the specified ranges.
  proc get_comment_markers {win ranges} {

    variable data

    return [$data($win,model) getcommentmarkers $ranges]

  }

  ######################################################################
  # Inserts the given items into the tree.
  proc insert {win ranges str cursor} {

    variable data

    $data($win,model) insert $ranges $str $cursor

  }

  ######################################################################
  # Deletes the given text range and updates the model.
  proc delete {win ranges strs cursor mark_command} {

    variable data

    set markers [$data($win,model) delete $ranges $strs $cursor]

    if {$mark_command ne ""} {
      foreach marker $markers {
        uplevel #0 [list {*}$mark_command $win unmarked $marker]
      }
    }

  }

  ######################################################################
  # Update the model with the replacement information.
  proc replace {win ranges dstrs istrs cursor mark_command} {

    variable data

    set markers [$data($win,model) replace $ranges $dstrs $istrs $cursor]

    if {$mark_command ne ""} {
      foreach marker $markers {
        uplevel #0 [list {*}$mark_command $win unmarked $marker]
      }
    }

  }

  ######################################################################
  # Temporarily merge the current serial list with the tags
  # so that we can figure out which contexts to serially highlight
  proc render_contexts {win linestart lineend tags} {

    variable data

    foreach {tag ranges} [$data($win,model) rendercontexts $linestart $lineend [lsort -dictionary -index 2 $tags]] {
      ctext::render $win $tag $ranges 1
    }

  }

  ######################################################################
  # Updates the model, inserting the given parsed elements prior to rebuilding
  # the model tree.
  proc update {win linestart lineend elements} {

    variable data

    if {[$data($win,model) update $linestart $lineend $elements]} {
      ctext::parsers::render_mismatched $win
    }

  }

  ######################################################################
  # Gets an index list of all nodes in the tree that are not matched.
  proc get_mismatched {win} {

    variable data

    return [$data($win,model) mismatched]

  }

  ######################################################################
  # Returns the depth of the given node.
  proc get_depth {win tindex {type ""}} {

    variable data

    return [$data($win,model) depth $tindex $type]

  }

  ######################################################################
  # Returns 1 if the given text widget index has a matching character
  # the tindex parameter will be populated with the matching character
  # text widget index.  If the character does not contain a match, a value
  # of 0 will be returned.
  proc get_match_char {win ptindex} {

    variable data

    upvar $ptindex tindex

    set tindex [$data($win,model) matchindex $tindex]

    return [expr {$tindex ne ""}]

  }

  ######################################################################
  # Set the marker for the given line to the specified value.
  proc set_marker {win line name} {

    variable data

    $data($win,model) setmarker $line $name

  }

  ######################################################################
  # Returns the marker name stored at the given line.
  proc get_marker_name {win line} {

    variable data

    return [$data($win,model) getmarkername $line]

  }

  ######################################################################
  # Returns the line number of the marker with the given name.  If name
  # is not found, a value of 0 is returned.
  proc get_marker_line {win name} {

    variable data

    return [$data($win,model) getmarkerline $name]

  }

  ######################################################################
  # Creates a new gutter.
  proc guttercreate {win name args} {

    variable data

    $data($win,model) guttercreate $name $args

  }

  ######################################################################
  # Destroys the given gutter.
  proc gutterdestroy {win name} {

    variable data

    $data($win,model) gutterdestroy $name

  }

  ######################################################################
  # Sets the hidden state of the given gutter if a value is supplied;
  # otherwise, returns the hidden state.
  proc gutterhide {win name {value ""}} {

    variable data

    return [$data($win,model) gutterhide $name $value]

  }

  ######################################################################
  # Deletes one or more symbols from the given gutter.
  proc gutterdelete {win name syms} {

    variable data

    $data($win,model) gutterdelete $name $syms

  }

  ######################################################################
  # Set the gutter with the given value/lines.
  proc gutterset {win name values} {

    variable data

    $data($win,model) gutterset $name $values

  }

  ######################################################################
  # Unsets a single line or all lines in a given range within a gutter.
  proc gutterunset {win name args} {

    variable data

    $data($win,model) gutterunset $name {*}$args

  }

  ######################################################################
  # Retrieves the specified gutter information.  If value not specified,
  # returns each stored gutter symbol with a list of all lines set to the
  # symbol.  If value is an integer, returns the symbol stored at the given
  # line (or the empty string if nothing is set).  If value is a symbol
  # name, returns all lines containing that symbol.  Any errors results
  # in an empty string being returned.
  proc gutterget {win name {value ""}} {

    variable data

    return [$data($win,model) gutterget $name $value]

  }

  ######################################################################
  # Returns the gutter symbol option value.
  proc guttercget {win name sym opt} {

    variable data

    return [$data($win,model) guttercget $name $sym $opt]

  }

  ######################################################################
  # Sets the value of the specified gutter symbol options.
  proc gutterconfigure {win name {sym ""} args} {

    variable data

    return [$data($win,model) gutterconfigure $name $sym $args]

  }

  ######################################################################
  # Returns the gutter names stored in the linemap.
  proc gutternames {win} {

    variable data

    return [$data($win,model) gutternames]

  }

  ######################################################################
  # Returns the linemap information for rendering purposes.
  proc render_linemap {win first last} {

    variable data

    return [$data($win,model) renderlinemap $first $last]

  }

  ######################################################################
  # Adds an undo separator.
  proc add_separator {win} {

    variable data

    $data($win,model) undoseparator

  }

  ######################################################################
  # Performs a single undo operation.
  proc undo {win} {

    variable data

    return [$data($win,model) undo]

  }

  ######################################################################
  # Performs a single redo operation.
  proc redo {win} {

    variable data

    return [$data($win,model) redo]

  }

  ######################################################################
  # Returns the cursor history.
  proc cursor_history {win} {

    variable data

    return [$data($win,model) cursorhistory]

  }

  ######################################################################
  # Returns true if there is something in the undo buffer.
  proc undoable {win} {

    variable data

    return [$data($win,model) undoable]

  }

  ######################################################################
  # Returns true if there is something in the redo buffer.
  proc redoable {win} {

    variable data

    return [$data($win,model) redoable]

  }

  ######################################################################
  # Resets the undo buffer.
  proc undo_reset {win} {

    variable data

    $data($win,model) undoreset

  }

  ######################################################################
  # Sets the auto-separators feature to the given value.
  proc auto_separate {win value} {

    variable data

    $data($win,model) autoseparate $value

  }

  ######################################################################
  # Deletes the fold found on the given line.
  proc fold_delete {win line depth prange} {

    upvar $prange range

    variable data

    lassign [$data($win,model) folddelete $line $depth] retval range

    return $retval

  }

  ######################################################################
  # Deletes all folds that begin within the startline and endline range.
  proc fold_delete_range {win startline endline pranges} {

    upvar $pranges ranges

    variable data

    lassign [$data($win,model) folddeleterange $startline $endline] retval ranges

    return $retval

  }

  ######################################################################
  # Opens the given fold and all descendents to the given depth.
  proc fold_open {win line depth pranges} {

    upvar $pranges ranges

    variable data

    lassign [$data($win,model) foldopen $line $depth] retval ranges

    return $retval

  }

  ######################################################################
  # Opens all closed folds that begin within the specified range.
  proc fold_open_range {win startline endline depth pranges} {

    upvar $pranges ranges

    variable data

    lassign [$data($win,model) foldopenrange $startline $endline $depth] retval ranges

    return $retval

  }

  ######################################################################
  # Opens all folds to reveal the given line.
  proc fold_show_line {win line} {

    variable data

    return [$data($win,model) foldshowline $line]

  }

  ######################################################################
  # Closes the given fold and all descendents to the given depth.
  proc fold_close {win line depth pranges} {

    upvar $pranges ranges

    variable data

    lassign [$data($win,model) foldclose $line $depth] retval ranges

    return $retval

  }

  ######################################################################
  # Closes all open folds found within the given startline and endline
  # range.
  proc fold_close_range {win startline endline depth pranges} {

    upvar $pranges ranges

    variable data

    lassign [$data($win,model) foldcloserange $startline $endline $depth] retval ranges

    return $retval

  }

  ######################################################################
  # Finds the num'th next/previous fold marker in the given direction.
  proc fold_find {win startline dir num} {

    variable data

    return [$data($win,model) foldfind $startline $dir $num]

  }

  ######################################################################
  # Updates the linemap folding gutter to match the file based on indentation
  # folding.
  proc fold_indent_update {win} {

    variable data

    if {[set ranges [$win._t tag ranges _prewhite]] ne ""} {
      $data($win,model) foldindentupdate $ranges
    }

  }

  ######################################################################
  # Updates the linemap folding gutter to match the file based on syntax
  # folding.
  proc fold_syntax_update {win} {

    variable data

    $data($win,model) foldsyntaxupdate

  }

  ######################################################################
  # Returns the line number containing the starting character that the
  # given index is a part of.
  proc indent_line_start {win index} {

    variable data

    return [$data($win,model) indentlinestart $index]

  }

  ######################################################################
  # Checks for indentation needs after a newline is entered.
  proc indent_newline {win prev_line first_line spaces shift_width} {

    variable data

    return [$data($win,model) indentnewline $prev_line $first_line $spaces $shift_width]

  }

  ######################################################################
  # Get information to handle an unindentation.
  proc indent_check_unindent {win first_index curr_index} {

    variable data

    return [$data($win,model) indentcheckunindent $first_index $curr_index]

  }

}
