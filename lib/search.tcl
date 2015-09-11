# TKE - Advanced Programmer's Editor
# Copyright (C) 2014  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:    search.tcl
# Author:  Trevor Williams (phase1geo@gmail.com)
# Date:    9/9/2013
# Brief:   Namespace for all things related to editor searching.
######################################################################

namespace eval search {

  source [file join $::tke_dir lib ns.tcl]
  
  array set data {
    find_case_sensitive 1
    find_hist           {}
    find_hist_ptr       0
    find_current        {}
  }
  
  ######################################################################
  # Performs a search of the curren text widget in the given direction
  # with the text specified in the specified entry widget.
  proc find_start {w txt direction} {
    
    variable data
    
    # If the user has specified a new search value, find all occurrences
    if {[set str [$w get]] ne ""} {

      # Escape any parenthesis in the regular expression
      set str [string map {{(} {\(} {)} {\)}} $str]

      # Test the regular expression, if it is invalid, let the user know
      if {[catch { regexp $str "" } rc]} {
        after 100 [list [ns gui]::set_info_message $rc]
        return
      }

      # Gather any search options
      set search_opts [list]
      if {!$data(find_case_sensitive)} {
        lappend search_opts -nocase
      }
      
      # Save the find text to history
      find_add_history $str

      # Clear the search highlight class
      find_clear $txt

      # Create a highlight class for the given search string
      ctext::addSearchClassForRegexp $txt search black yellow "" $str $search_opts
      
    }

    # Select the search term
    if {$direction eq "next"} {
      find_next $txt 0
    } else {
      find_prev $txt 0
    }
    
  }

  ######################################################################
  # Clears the current search text.
  proc find_clear {txt} {

    variable data
    
    # Clear the history pointer
    set data(find_hist_ptr) [llength $data(find_hist)]
    
    # Clear the current find text
    set data(find_current)  ""
    
    # Clear the highlight class
    catch { ctext::deleteHighlightClass $txt search }

  }
  
  ######################################################################
  # Searches for the next occurrence of the search item.
  proc find_next {txt app} {

    set wrapped 0

    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }

    # Search the text widget from the current insertion cursor forward.
    lassign [$txt tag nextrange _search "insert+1c"] startpos endpos

    # We need to wrap on the search item
    if {$startpos eq ""} {
      lassign [$txt tag nextrange _search 1.0] startpos endpos
      set wrapped 1
    }

    # Select the next match
    if {$startpos ne ""} {
      if {![[ns vim]::in_vim_mode $txt.t]} {
        $txt tag add sel $startpos $endpos
      }
      $txt mark set insert $startpos
      $txt see insert
      if {$wrapped} {
        [ns gui]::set_info_message [msgcat::mc "Search wrapped to beginning of file"]
      }
    } else {
      [ns gui]::set_info_message [msgcat::mc "No search results found"]
    }

    # Closes the search interface
    [ns gui]::close_search

  }

  ######################################################################
  # Searches for the previous occurrence of the search item.
  proc find_prev {txt app} {

    set wrapped 0

    # If we are not appending to the selection, clear the selection
    if {!$app} {
      $txt tag remove sel 1.0 end
    }

    # Search the text widget from the current insertion cursor forward.
    lassign [$txt tag prevrange _search insert] startpos endpos

    # We need to wrap on the search item
    if {$startpos eq ""} {
      lassign [$txt tag prevrange _search end] startpos endpos
      set wrapped 1
    }

    # Select the next match
    if {$startpos ne ""} {
      if {![[ns vim]::in_vim_mode $txt.t]} {
        $txt tag add sel $startpos $endpos
      }
      $txt mark set insert $startpos
      $txt see insert
      if {$wrapped} {
        [ns gui]::set_info_message [msgcat::mc "Search wrapped to end of file"]
      }
    } else {
      [ns gui]::set_info_message [msgcat::mc "No search results found"]
    }

    # Close the search interface
    [ns gui]::close_search

  }
  
  ######################################################################
  # Searches for all of the occurrences and selects them all.
  proc find_all {txt} {

    # Clear the selection
    $txt tag remove sel 1.0 end

    # Add all matching search items to the selection
    $txt tag add sel {*}[$txt tag ranges _search]

    # Make the first line viewable
    catch {
      set firstpos [lindex [$txt tag ranges _search] 0]
      $txt mark set insert $firstpos
      $txt see $firstpos
    }

    # Close the search interface
    [ns gui]::close_search

  }
  
  ######################################################################
  # Adds the given string to the find history list.
  proc find_add_history {str} {
    
    variable data
    
    # Check to see if the search string exists within the history
    if {[set index [lsearch -exact $data(find_hist) $str]] != -1} {
      set data(find_hist) [lreplace $data(find_hist) $index $index]
        
    # Otherwise, reduce the size of the find history if adding another element will cause it to overflow
    } else {
      set hist_diff [expr [llength $data(find_hist)] - [[ns preferences]::get {Find/MaxHistory}]]
      if {$hist_diff >= 0} {
        set data(find_hist) [lreplace $data(find_hist) 0 $hist_diff]
      }
    }
      
    # Save the find text to history
    lappend data(find_hist) $str
    
  }
  
  ######################################################################
  # Moves backwards or forwards through search history, populating the given
  # entry widget with the history search result.  If we are moving forward
  # in history such that we fall into the present, the entry field will be
  # set to any text that was entered prior to traversing history.
  proc find_history {w dir} {
    
    variable data
    
    # Get the length of the find history list
    set hlen [llength $data(find_hist)]
    
    # If the history pointer is -1, save the current text entered
    if {$data(find_hist_ptr) == $hlen} {
      if {$dir == 1} {
        return
      }
      set data(find_current) [$w get]
    }
    
    # Update the current pointer
    if {($data(find_hist_ptr) == 0) && ($dir == -1)} {
      return
    }
    
    incr data(find_hist_ptr) $dir
    
    # Remove the text in the entry widget
    $w delete 0 end
    
    # If the new history pointer is -1, restore the current text value
    if {$data(find_hist_ptr) == $hlen} {
      $w insert end $data(find_current)
    } else {
      $w insert end [lindex $data(find_hist) $data(find_hist_ptr)]
    }
    
  }
  
  ######################################################################
  # Performs an egrep-like search in a user-specified list of files/directories.
  proc fif_start {} {

    set rsp_list [list]

    # Display the find UI to the user and get input
    if {[[ns gui]::fif_get_input rsp_list]} {

      array set rsp $rsp_list

      # Convert directories into files
      array set files {}
      foreach file $rsp(in) {
        if {[file isdirectory $file]} {
          foreach sfile [glob -nocomplain -directory $file -types {f r} *] {
            if {![[ns sidebar]::ignore_file $sfile]} {
              set files($sfile) 1
            }
          }
        } elseif {![[ns sidebar]::ignore_file $file]} {
          set files($file) 1
        }
      }

      # Perform egrep operation (test)
      if {[array size files] > 0} {
        if {$::tcl_platform(platform) eq "windows"} {
          [ns search]::fif_callback $rsp(find) [array size files] 0 [utils::egrep $rsp(find) [lsort [array names files]] [preferences::get Find/ContextNum] $rsp(egrep_opts)]
        } else {
          [ns bgproc]::system find_in_files "egrep -a -H -C[[ns preferences]::get Find/ContextNum] -n $rsp(egrep_opts) -s {$rsp(find)} [lsort [array names files]]" -killable 1 \
            -callback "[ns search]::fif_callback [list $rsp(find)] [array size files]"
        }
      } else {
        [ns gui]::set_info_message [msgcat::mc "No files found in specified directories"]
      }

    }

  }

  ######################################################################
  # Called when the egrep operation has completed.
  proc fif_callback {find_expr num_files err data} {

    # Add the file to the viewer
    [ns gui]::add_buffer end "FIF Results" "" -readonly 1 -other [[ns preferences]::get View/ShowFindInFileResultsInOtherPane]

    # Inserts the results into the current buffer
    fif_insert_results $find_expr $num_files $err $data

  }

  ######################################################################
  # Inserts the results from the find in files egrep execution into the
  # newly created buffer.
  proc fif_insert_results {find_expr num_files err result} {

    # Get the current text widget
    set txt [[ns gui]::current_txt {}]
    
    # Change the text state to allow text to be inserted
    $txt configure -state normal

    # Get the last index of the text widget
    set last_line [$txt index end]

    # Insert a starting mark
    $txt insert -moddata ignore end "----\n"

    if {!$err || ($num_files == 0)} {

      # Append the results to the text widget
      $txt insert -moddata ignore end [fif_format $result]

      # Modify find_expr so that information in results window will match
      if {[string index $find_expr 0] eq "^"} {
        set find_expr [string range $find_expr 1 end]
      }

      # Highlight and bind the matches
      $txt tag configure fif -underline 1 -borderwidth 1 -relief raised -foreground black -background yellow
      set i 0
      foreach index [$txt search -regexp -all -count find_counts -- $find_expr $last_line] {
        $txt tag add fif $index "$index + [lindex $find_counts $i]c"
        $txt tag bind fif <Enter>           [list %W configure -cursor [ttk::cursor link]]
        $txt tag bind fif <Leave>           [list %W configure -cursor [$txt cget -cursor]]
        $txt tag bind fif <ButtonRelease-1> [list [ns search]::fif_handle_click %W %x %y]
        incr i
      }

      bind $txt <Key-space> [list if {[[ns search]::fif_handle_space %W]} break]

    } else {

      $txt insert -moddata ignore end "ERROR: $result\n\n\n"

    }

    # Make sure that the beginning of the inserted text is in view
    $txt see end
    $txt mark set insert $last_line
    $txt see $last_line

    # Change the state back to disabled
    $txt configure -state disabled

  }

  ######################################################################
  # Formats the raw egrep data to make it more readable.
  proc fif_format {data} {

    set results         ""
    set file_results    [list]
    set last_linenum    ""
    set first_separator 1
    array set indices   {}
    array set fnames    {}
    set index           0
    set matches         0

    foreach line [split $data \n] {
      if {[regexp {^(.*?)([:-])(\d+)[:-](.*)$} $line -> fname type linenum content]} {
        set first_separator 1
        if {![info exists fnames($fname)]} {
          set fnames($fname) 1
          if {[llength $file_results] > 0} {
            if {[string trim [lindex $file_results end]] eq "..."} {
              set file_results [lrange $file_results 0 end-1]
            }
            append results "[join $file_results \n]\n\n"
            set file_results [list]
          }
          lappend file_results "  [file normalize $fname]:\n"
          set last_linenum ""
          array unset indices
        }
        if {$type eq ":"} {
          if {($last_linenum eq "") || ($linenum > $last_linenum)} {
            lappend file_results [format "    %6d: %s" $linenum $content]
            set indices($linenum) $index
            set last_linenum $linenum
            incr index
          } else {
            lset file_results $indices($linenum) [string replace [lindex $file_results $indices($linenum)] 11 11 ":"]
          }
          incr matches
        } else {
          if {($last_linenum eq "") || ($linenum > $last_linenum)} {
            lappend file_results [format "    %6d  %s" $linenum $content]
            set indices($linenum) $index
            set last_linenum $linenum
            incr index
          }
        }
      } elseif {[string trim $line] eq "--"} {
        if {$first_separator} {
          set first_separator 0
        } else {
          lappend file_results "    ..."
        }
      }
    }

    # Append the last files information to the results string
    append results "[join $file_results \n]\n\n"

    return "Found $matches [expr {($matches != 1) ? {matches} : {match}}] in [array size fnames] [expr {([array size fnames] != 1) ? {files} : {file}}]\n\n$results"

  }

  ######################################################################
  # Handles a left-click on a matched pattern in the given text widget.
  # Causes the matching file to be opened and we jump to the matching line.
  proc fif_handle_selection {W index} {

    # Get the line number from the beginning of the line
    regexp {^\s*(\d+)} [$W get "$index linestart" $index] -> linenum

    # Get the filename of the line that is clicked
    set findex [$W search -regexp -backwards -count fif_count -- {^\s*/.*:$} $index]
    set fname  [$W get $findex "$findex+[expr $fif_count - 1]c"]

    # Add the file to the file viewer (if necessary)
    [ns gui]::add_file end [string trim $fname]

    # Jump to the line and set the cursor to the beginning of the line
    set txt [[ns gui]::current_txt {}]
    $txt see $linenum.0
    $txt mark set insert $linenum.0

  }

  ######################################################################
  # Handles a left-click on a matched pattern in the given text widget.
  proc fif_handle_click {W x y} {

    fif_handle_selection $W [$W index @$x,$y]

  }

  ######################################################################
  # Handles a space bar key hit on a matched pattern in the given text
  # widget.
  proc fif_handle_space {W} {

    # Get the current insertion index
    set insert [$W index insert]

    # Check to see if the space bar was hit inside of a tag
    foreach {first last} [$W tag ranges fif] {
      if {[$W compare $first <= $insert] && [$W compare $insert < $last]} {
        fif_handle_selection $W [$W index insert]
        return 1
      }
    }

    return 0

  }
  
  ######################################################################
  # Loads the given session data.
  proc load_session {session_data} {
    
    variable data
    
    # Get the data
    array set data $session_data
    
    # Clear the history pointer
    set data(find_hist_ptr) [llength $data(find_hist)]
    
  }
  
  ######################################################################
  # Returns find data to be saved in session history.
  proc save_session {} {
    
    variable data
    
    return [array get data]
    
  }
  
  
}
