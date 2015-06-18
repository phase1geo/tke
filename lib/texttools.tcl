######################################################################
# Name:    texttools.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    05/21/2013
# Brief:   Namespace containing procedures to manipulate text in the
#          current text widget.
######################################################################

namespace eval texttools {

  ######################################################################
  # Comments out the currently selected text.
  proc comment {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    # Get the comment syntax
    lassign [syntax::get_comments $txt] icomment lcomments bcomments

    # Insert comment lines/blocks
    foreach {endpos startpos} [lreverse $selected] {
      if {[llength $icomment] == 1} {
        set i 0
        foreach line [split [$txt get $startpos $endpos] \n] {
          if {$i == 0} {
            $txt insert $startpos "[lindex $icomment 0]"
            $txt tag add sel $startpos "$startpos lineend"
          } else {
            $txt insert "$startpos+${i}l linestart" "[lindex $icomment 0]"
          }
          incr i
        }
      } else {
        $txt insert $endpos   "[lindex $icomment 1]"
        $txt insert $startpos "[lindex $icomment 0]"
        if {[lindex [split $startpos .] 0] == [lindex [split $endpos .] 0]} {
          set endpos "$endpos+[expr [string length [lindex $icomment 0]] + [string length [lindex $icomment 1]]]c"
        } else {
          set endpos "$endpos+[string length [lindex $icomment 1]]c"
        }
        $txt tag add sel $startpos $endpos
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Uncomments out the currently selected text in the current text
  # widget.
  proc uncomment {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    # Get the comment syntax
    lassign [syntax::get_comments $txt] icomment lcomments bcomments

    # Get the comment syntax to remove
    set comments [join [eval concat $lcomments $bcomments] |]

    # Strip out comment syntax
    foreach {endpos startpos} [lreverse $selected] {
      set linestart $startpos
      foreach line [split [$txt get $startpos $endpos] \n] {
        if {[regexp -indices -- "($comments)+?" $line -> com]} {
          set delstart [$txt index "$linestart+[lindex $com 0]c"]
          set delend   [$txt index "$linestart+[expr [lindex $com 1] + 1]c"]
          $txt delete $delstart $delend
        }
        set linestart [$txt index "$linestart+1l linestart"]
        incr i
      }
    }

    # Create a separator
    $txt edit separator

  }
  
  ######################################################################
  # Handles commenting/uncommenting either the currently selected code
  # or the current cursor.
  proc comment_toggle {tid} {
    
    # Get the current text widget
    set txt [gui::current_txt $tid]
    
    # Create a separator
    $txt edit separator
    
    # Get various comments
    lassign [syntax::get_comments $txt] icomment lcomments bcomments
    
    # Get the current selection
    set selected 1
    if {[llength [set ranges [$txt tag ranges sel]]] == 0} {
      if {[llength [set mcursors [$txt tag ranges mcursor]]] > 0} {
        foreach {startpos endpos} $mcursors {
          lappend ranges [$txt index "$startpos linestart"] [$txt index "$startpos lineend"]
        }
      } elseif {[lsearch [$txt tag names insert] _cComment] != -1} {
        lassign [$txt tag prevrange _cComment insert] startpos endpos
        if {[regexp "^[lindex $bcomments 0 0](.*)[lindex $bcomments 0 1]\$" [$txt get $startpos $endpos] -> str]} {
          $txt replace $startpos $endpos $str
          $txt edit separator
        }
        return
      } else {
        set ranges [list [$txt index "insert linestart"] [$txt index "insert lineend"]]
      }
      set selected 0
    } 
    
    # Iterate through each range
    foreach {endpos startpos} [lreverse $ranges] {
      if {![do_uncomment $txt $startpos $endpos]} {
        if {[llength $icomment] == 1} {
          set i 0
          foreach line [split [$txt get $startpos $endpos] \n] {
            if {$i == 0} {
              $txt insert $startpos "[lindex $icomment 0]"
              if {$selected} {
                $txt tag add sel $startpos "$startpos lineend"
              }
            } else {
              $txt insert "$startpos+${i}l linestart" "[lindex $icomment 0]"
            }
            incr i
          }
        } else {
          $txt insert $endpos   "[lindex $icomment 1]"
          $txt insert $startpos "[lindex $icomment 0]"
          if {$selected} {
            if {[lindex [split $startpos .] 0] == [lindex [split $endpos .] 0]} {
              set endpos "$endpos+[expr [string length [lindex $icomment 0]] + [string length [lindex $icomment 1]]]c"
            } else {
              set endpos "$endpos+[string length [lindex $icomment 1]]c"
            }
            $txt tag add sel $startpos $endpos
          }
        }
      }
    }

    # Create a separator
    $txt edit separator

  }
  
  ######################################################################
  # Determines if the given range can be uncommented.  If so, performs
  # the uncomment and returns 1; otherwise, returns 0.
  proc do_uncomment {txt startpos endpos} {
    
    set retval 0
    
    # Get the comment syntax
    lassign [syntax::get_comments $txt] icomment lcomments bcomments
    
    # Get the comment syntax to remove
    set comments [join [eval concat $lcomments $bcomments] |]

    set linestart $startpos
    foreach line [split [$txt get $startpos $endpos] \n] {
      if {[regexp -indices -- "($comments)+?" $line -> com]} {
        set delstart [$txt index "$linestart+[lindex $com 0]c"]
        set delend   [$txt index "$linestart+[expr [lindex $com 1] + 1]c"]
        $txt delete $delstart $delend
        set retval 1
      }
      set linestart [$txt index "$linestart+1l linestart"]
      incr i
    }
    
    return $retval
    
  }

  ######################################################################
  # Indents the selected text of the current text widget by one
  # indentation level.
  proc indent {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    foreach {endpos startpos} [lreverse $selected] {
      while {[$txt index "$startpos linestart"] <= [$txt index "$endpos linestart"]} {
        $txt insert "$startpos linestart" "  "
        set startpos [$txt index "$startpos linestart+1l"]
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Unindents the selected text of the current text widget by one
  # indentation level.
  proc unindent {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Create a separator
    $txt edit separator

    # Get the selection ranges
    set selected [$txt tag ranges sel]

    foreach {endpos startpos} [lreverse $selected] {
      while {[$txt index "$startpos linestart"] <= [$txt index "$endpos linestart"]} {
        if {[regexp {^  } [$txt get "$startpos linestart" "$startpos lineend"]]} {
          $txt delete "$startpos linestart" "$startpos linestart+2c"
        }
        set startpos [$txt index "$startpos linestart+1l"]
      }
    }

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # Replaces the current line with the output contents of it as a script.
  proc replace_line_with_script {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Get the current line
    set cmd [$txt get "insert linestart" "insert lineend"]

    # Execute the line text
    catch { exec -ignorestderr {*}$cmd } rc

    # Replace the line with the given text
    $txt replace "insert linestart" "insert lineend" $rc

  }

  ######################################################################
  # Returns true if the current line is empty; otherwise, returns false.
  proc current_line_empty {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    return [expr {[$txt get "insert linestart" "insert lineend"] eq ""}]

  }

  ######################################################################
  # Aligns the current cursors.
  proc align {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Align multicursors
    multicursor::align $txt

  }

  ######################################################################
  # Inserts an enumeration when in multicursor mode.
  proc insert_enumeration {tid} {

    # Get the current text widget
    set txt [gui::current_txt $tid]

    # Perform the insertion
    gui::insert_numbers $txt

  }

}

