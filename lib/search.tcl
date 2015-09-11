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
