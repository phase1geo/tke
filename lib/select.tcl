# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2017  Trevor Williams (phase1geo@gmail.com)
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
# Name:    select.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    06/05/2017
# Brief:   Provides select mode functionality.
######################################################################

namespace eval select {
  
  array set data [list]
  
  ######################################################################
  # Adds bindings for selection mode.  Returns the hierarchical reference
  # to the select mode sidebar widget which needs to be packed into a grid
  # controlled layout manager and hidden from view.
  proc add {txt frame} {
    
    variable data
    
    set data($txt,mode)    0
    set data($txt,object)  "inner"
    set data($txt,type)    "char"
    set data($txt,anchor)  0
    set data($txt,sidebar) [create_sidebar $frame]
    
    bind select <Key>    "if {\[select::handle_any %W %k\]} break"
    bind select <Return> "if {\[select::handle_return %W\]} break"
    bind select <Escape> "if {\[select::handle_escape %W\]} break"
    
    bindtags $txt [linsert [bindtags $txt] [expr [lsearch [bindtags $txt] $txt] + 1]]
    
    return $data($txt,sidebar)
    
  }
  
  ######################################################################
  # Creates the selection mode sidebar which displays the currently selected
  # modes, their key bindings and their description.
  proc create_sidebar {w} {
    
    ttk::frame $w
    
  }
  
  ######################################################################
  # Open the sidebar for view.  This should only be called by the
  # set_select_mode internal procedure.
  proc open_sidebar {txt} {
    
    variable data
    
    # Make the sidebar visible
    grid $data($txt,sidebar)
    
  }
  
  ######################################################################
  # Closes the selection mode sidebar from view.  This should only be
  # called by the set_select_mode internal procedure.
  proc close_sidebar {txt} {
    
    variable data
    
    # Hide the sidebar
    grid remove $data($txt,sidebar)
    
  }
  
  ######################################################################
  # Sets the selection mode for the given text widget to the given value.
  # This will cause the selection sidebar to appear or disappear as needed.
  proc set_select_mode {txt value} {
    
    variable data
    
    # Set the mode
    if {$data($txt,mode) != $value} {
      if {$value == 0} {
        close_sidebar $txt
      } else {
        open_sidebar $txt
      }
      set data($txt,mode) $value
    }
    
  }
  
  ######################################################################
  # Handles the Return key when in selection mode.  Ends selection mode,
  # leaving the selection in place.
  proc handle_return {txt} {
    
    variable data
    
    if {$data($txt,mode) == 0} {
      return 0
    }
    
    # Disable selection mode
    set_select_mode $txt 0
    
    return 1
    
  }
  
  ######################################################################
  # Handles the Escape key when in selection mode.  Ends selection mode
  # and clears the selection.
  proc handle_escape {txt} {
    
    variable data
    
    if {$data($txt,mode) == 0} {
      return 0
    }
    
    # Disable selection mode
    set_select_mode $txt 0
    
    # Clear the selection
    $txt tag remove sel 1.0 end
    
    return 1
    
  }
  
  ######################################################################
  # Handles any other entered keys when in selection mode.
  proc handle_any {txt keysym} {
    
    variable data
    
    if {$data($txt,mode) == 0} {
      return 0
    }
    
    # Handle the specified key
    catch { handle_$keysym $txt }
    
    return 1
    
  }
  
  ######################################################################
  # Handles the user hitting the "i" key which will adjust the selection
  # to include the "inner" portion of the current selection type.  This
  # is not valid for character, line or block selection.
  proc handle_i {txt} {
    
    variable data
    
    # Set the object mode to "inner"
    set data($txt,object) "inner"
    
  }
  
  ######################################################################
  # Handles the user hitting the "o" key which will adjust the selection
  # to include the "outer" portion of the current selection type.  This
  # is not valid for character, line or block selection.
  proc handle_o {txt} {
    
    variable data
    
    # Set the object mode to "outer"
    set data($txt,object) "outer"
    
  }
  
  ######################################################################
  # Sets the current selection type to character mode.
  proc handle_c {txt} {
    
    variable data
    
    set data($txt,type) "char"
    
  }
  
  ######################################################################
  # Sets the current selection type to line mode.
  proc handle_l {txt} {
    
    variable data
    
    set data($txt,type) "line"
    
  }
  
  ######################################################################
  # Sets the current selection type to block mode.
  proc handle_b {txt} {
    
    variable data
    
    set data($txt,type) "block"
    
  }
  
  ######################################################################
  # Set the current selection type to word mode.
  proc handle_w {txt} {
    
    variable data
    
    set data($txt,type) "word"
    
  }
  
  ######################################################################
  # Set the current selection type to WORD mode.
  proc handle_W {txt} {
    
    variable data
    
    set data($txt,type) "WORD"
    
  }
  
  ######################################################################
  # Set the current selection type to sentence mode.
  proc handle_s {txt} {
    
    variable data
    
    set data($txt,type) "sentence"
    
  }
  
  ######################################################################
  # Set the current selection type to paragraph mode.
  proc handle_p {txt} {
    
    variable data
    
    set data($txt,type) "paragraph"
    
  }
  
  ######################################################################
  # Set the current selection type to square mode.
  proc handle_braceleft {txt} {
    
    variable data
    
    set data($txt,type) "square"
    
  }
  
  ######################################################################
  # Set the current selection type to parenthesis mode.
  proc handle_parenleft {txt} {
    
    variable data
    
    set data($txt,type) "paren"
    
  }
  
  ######################################################################
  # Set the current selection type to angled mode.
  proc handle_less {txt} {
    
    variable data
    
    set data($txt,type) "angled"
    
  }
  
  ######################################################################
  # Set the current selection type to curly mode.
  proc handle_bracketleft {txt} {
    
    variable data
    
    set data($txt,type) "curly"
    
  }
  
  ######################################################################
  # Set the current selection type to double quote mode.
  proc handle_dblquote {txt} {
    
    variable data
    
    set data($txt,type) "double"
    
  }
  
  ######################################################################
  # Set the current selection type to single quote mode.
  proc handle_apostrophe {txt} {
    
    variable data
    
    set data($txt,type) "single"
    
  }
  
  ######################################################################
  # Handles moving the selection back by the selection type amount.
  proc handle_Left {txt} {
    
    variable data
    
    if {$data($txt,anchor)} {
      # Move end of selection backwards
    } else {
      # Move beginning of selection backwards
    }
    
  }
  
  ######################################################################
  # Handles moving the selection forward by the selection type amount.
  proc handle_right {txt} {
    
    variable data
    
    if {$data($txt,anchor)} {
      # Move end of selection forwards
    } else {
      # Move start of selection forwards
    }
    
  }
  
  ######################################################################
  # Handles moving the entire selection to include the parent of the
  # currently selected text.
  proc handle_Up {txt} {
    
    variable data
    
    # TBD
    
  }
  
  ######################################################################
  # Handles moving the entire selection to include just the first child
  # of the currently selected text.
  proc handle_Down {txt} {
    
    variable data
    
    # TBD
    
  }
  
  ######################################################################
  # Changes the selection anchor to the other side of the selection.
  proc handle_a {txt} {
    
    variable data
    
    set data($txt,anchor) [expr $data($txt,anchor) ^ 1]
    
  }
  
}
