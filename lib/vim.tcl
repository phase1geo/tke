######################################################################
# Name:    vim.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    05/21/2013
# Brief:   Namespace containing special bindings to provide Vim-like
#          support.  The Vim commands supported are not meant to be
#          a complete representation of its functionality.
######################################################################

namespace eval vim {
  
  array set command_entries {}
  array set mode            {}
  array set number          {}
  
  ######################################################################
  # Enables/disables Vim mode for the current text widget.
  proc set_vim_mode {} {
    
    if {$preferences::prefs(Tools/VimMode)} {
      add_bindings [gui::current_txt]
    } else {
      remove_bindings [gui::current_txt]
    }
    
  }
  
  ######################################################################
  # Binds the given entry 
  proc bind_command_entry {txt entry} {
  
    variable command_entries
    
    # Save the entry
    set command_entries($txt.t) $entry
  
    bind $entry <Return> "vim::handle_command_return %W $txt"
    bind $entry <Escape> "vim::handle_command_escape %W $txt"
  
  }
  
  ######################################################################
  # Handles the command entry text.
  proc handle_command_return {w txt} {
  
    variable command_entries
    
    # Get the value from the command field
    set value [$w get]
    
    # FIXME - Do whatever the command says
    puts "Command: $value"
    
    # Remove the grab and set the focus back to the text widget
    grab release $w
    focus $txt.t
    
    # Hide the command entry widget
    grid remove $w 
  
  }
  
  ######################################################################
  # Handles an escape key in the command entry widget.
  proc handle_command_escape {w txt} {
  
    variable command_entries
    
    # Remove the grab and set the focus back to the text widget
    grab release $w
    focus $txt.t
    
    # Hide the command entry widget
    grid remove $w
    
  }
  
  ######################################################################
  # Add Vim bindings 
  proc add_bindings {txt} {
    
    variable mode
    variable number
    
    # Put the current mode into the "start" mode
    set mode($txt.t) "start"
    
    # Initialize the number for the current text widget
    set number($txt.t) ""
    
    # Change the cursor to the block cursor
    $txt configure -blockcursor true
    
    bind vim$txt <Key-i>  {
      if {[vim::handle_i %W]} {
        break
      }
    }
    bind vim$txt <Escape> {
      if {[vim::handle_escape %W]} {
        break
      }
    }
    bind vim$txt <Key-colon> {
      if {[vim::handle_colon %W]} {
        break
      }
    }
    bind vim$txt <Key-dollar> {
      if {[vim::handle_dollar %W]} {
        break
      }
    }
    bind vim$txt <Key-asciicircum> {
      if {[vim::handle_asciicircum %W]} {
        break
      }
    }
    bind vim$txt <Key-j> {
      if {[vim::handle_j %W]} {
        break
      }
    }
    bind vim$txt <Key-k> {
      if {[vim::handle_k %W]} {
        break
      }
    }
    bind vim$txt <Key-l> {
      if {[vim::handle_l %W]} {
        break
      }
    }
    bind vim$txt <Key-h> {
      if {[vim::handle_h %W]} {
        break
      }
    }
    bind vim$txt <Key-c> {
      if {[vim::handle_c %W]} {
        break
      }
    }
    bind vim$txt <Key-w> {
      if {[vim::handle_w %W]} {
        break
      }
    }
    bind vim$txt <Key-G> {
      if {[vim::handle_G %W]} {
        break
      }
    }
    bind vim$txt <Key-d> {
      if {[vim::handle_d %W]} {
        break
      }
    }
    bind vim$txt <Key-a> {
      if {[vim::handle_a %W]} {
        break
      }
    }
    bind vim$txt <Key-y> {
      if {[vim::handle_y %W]} {
        break
      }
    }
    bind vim$txt <Key-p> {
      if {[vim::handle_p %W]} {
        break
      }
    }
    bind vim$txt <Key-u> {
      if {[vim::handle_u %W]} {
        break
      }
    }
    bind vim$txt <Key-x> {
      if {[vim::handle_x %W]} {
        break
      }
    }
    bind vim$txt <Key-0> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    bind vim$txt <Key-1> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    bind vim$txt <Key-2> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    bind vim$txt <Key-3> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    bind vim$txt <Key-4> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    bind vim$txt <Key-5> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    bind vim$txt <Key-6> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    bind vim$txt <Key-7> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    bind vim$txt <Key-8> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    bind vim$txt <Key-9> {
      if {[vim::handle_number %W %A]} {
        break
      }
    }
    
    bindtags $txt.t [linsert [bindtags $txt.t] 1 vim$txt]
    
  }
  
  ######################################################################
  # Remove the Vim bindings on the text widget.
  proc remove_bindings {txt} {
    
    # Remove the Vim bindings from the widget
    bindtags $txt.t [lreplace [bindtags $txt.t] 1 1]
    
    # Change the cursor to the insertion cursor
    $txt configure -blockcursor false
    
  }
  
  ######################################################################
  # Handles the i-key when in Vim mode.
  proc handle_i {txt} {
    
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      
      # Change the mode to edit mode
      set mode($txt) "edit"
    
      # Change the cursor
      $txt configure -blockcursor false
     
      # Clear the current number
      set number($txt) ""
      
      return 1
       
    }
    
    return 0
    
  }
  
  ######################################################################
  # Handles the escape-key when in Vim mode.
  proc handle_escape {txt} {
    
    variable mode
    variable number
    
    if {$mode($txt) eq "edit"} {
    
      # Change the cursor to the block cursor
      $txt configure -blockcursor true
      
    }
    
    # Clear the current number string
    set number($txt) ""
    
    # Set the mode to start
    set mode($txt) "start"
    
    return 1
    
  }
  
  ######################################################################
  # If we are in "start" mode, append number to number value.
  proc handle_number {txt num} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      append number($txt) $num
      return 1
    }
    
    return 0
  
  }
  
  ######################################################################
  # If we are in the "start" mode, display the command entry field and
  # give it the focus.
  proc handle_colon {txt} {
  
    variable mode
    variable command_entries'
    variable number
    
    # If we are in the "start" mode, bring up the command entry widget
    # and give it the focus.
    if {$mode($txt) eq "start"} {
    
      # Show the command entry widget
      grid $command_entries($txt)
      
      # Set the focus and grab on the widget
      grab $command_entries($txt)
      focus $command_entries($txt)
      
      # Clear the number
      set number($txt) ""
      
      return 1
      
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in the "start" mode, move insertion cursor to the end of
  # the current line.  If we are in "delete" mode, delete all of the
  # text from the insertion marker to the end of the line.
  proc handle_dollar {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert lineend"
      set number($txt) ""
      return 1
    } elseif {$mode($txt) eq "delete"} {
      $txt delete insert "insert lineend"
      set mode($txt) "start"
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in the "start" mode, move insertion cursor to the beginning
  # of the current line.  If we are in "delete" mode, delete all of the
  # text between the beginning of the current line and the current
  # insertion marker.
  proc handle_asciicircum {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert linestart"
      set number($txt) ""
      return 1
    } elseif {$mode($txt) eq "delete"} {
      $txt delete "insert linestart" insert
      set mode($txt) "start"
      return 1
    }
    
    return 0

  }
  
  ######################################################################
  # If we are in "start" mode, move the insertion cursor down one line.
  proc handle_j {txt} {
  
    variable mode
    variable number
    
    # Move the insertion cursor down one line
    if {$mode($txt) eq "start"} {
      if {$number($txt) ne ""} {
        $txt mark set insert "insert+$number($txt)l"
        set number($txt) ""
      } else {
        $txt mark set insert "insert+1l"
      }
      $txt see insert
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, move the insertion cursor up one line.
  proc handle_k {txt} {
  
    variable mode
    variable number
    
    # Move the insertion cursor up one line
    if {$mode($txt) eq "start"} {
      if {$number($txt) ne ""} {
        $txt mark set insert "insert-$number($txt)l"
        set number($txt) ""
      } else {
        $txt mark set insert "insert-1l"
      }
      $txt see insert
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, move the insertion cursor right one
  # character.
  proc handle_l {txt} {
  
    variable mode
    variable number
    
    # Move the insertion cursor right one character
    if {$mode($txt) eq "start"} {
      if {$number($txt) ne ""} {
        $txt mark set insert "insert+$number($txt)c"
        set number($txt) ""
      } else {
        $txt mark set insert "insert+1c"
      }
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, move the insertion cursor left one
  # character.
  proc handle_h {txt} {
  
    variable mode
    variable number
    
    # Move the insertion cursor left one character
    if {$mode($txt) eq "start"} {
      if {$number($txt) ne ""} {
        $txt mark set insert "insert-$number($txt)c"
        set number($txt) ""
      } else {
        $txt mark set insert "insert-1c"
      }
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, change the state to "cut" mode.
  proc handle_c {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      set mode($txt)   "cut"
      set number($txt) ""
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "cut" mode, delete the current word and change to edit
  # mode.
  proc handle_w {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "cut"} {
      $txt delete "insert wordstart" "insert wordend"
      set mode($txt) "edit"
      $txt configure -blockcursor false
      set number($txt) ""
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, go to the last line.
  proc handle_G {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "end linestart"
      $txt see end
      set number($txt) ""
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, transition the mode to the delete mode.
  # If we are in the "delete" mode, delete the current line.
  proc handle_d {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      if {$number($txt) ne ""} {
        clipboard clear
        clipboard append [$txt get "insert linestart" "insert linestart+$number($txt)l"]
        $txt delete "insert linestart" "insert linestart+$number($txt)l"
        set number($txt) ""
      } else {
        set mode($txt) "delete"
      }
      return 1
    } elseif {$mode($txt) eq "delete"} {
      clipboard clear
      clipboard append [$txt get "insert linestart" "insert linestart+1l"]
      $txt delete "insert linestart" "insert linestart+1l"
      set mode($txt) "start"
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in the "start" mode, move the insertion cursor ahead by
  # one character and set ourselves into "edit" mode.
  proc handle_a {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert+1c"
      set mode($txt) "edit"
      $txt configure -blockcursor false
      set number($txt) ""
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in the "start" mode, set ourselves to yank mode.  If we
  # are in "yank" mode, copy the current line to the clipboard.
  proc handle_y {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      if {$number($txt) ne ""} {
        clipboard clear
        clipboard append [$txt get "insert linestart" "insert linestart+$number($txt)l"]
        set number($txt) ""
      } else {
        set mode($txt) "yank"
      }
      return 1
    } elseif {$mode($txt) eq "yank"} {
      clipboard clear
      clipboard append [$txt get "insert linestart" "insert linestart+1l"]
      set mode($txt) "start"
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in the "start" mode, put the contents of the clipboard
  # after the current line.
  proc handle_p {txt} {
  
    variable mode
    variable number

    if {$mode($txt) eq "start"} {
      if {[$txt index "insert linestart+1l"] eq [$txt index end]} {
        $txt insert end "\n[clipboard get]"
      } else {
        $txt insert "insert linestart+1l" [clipboard get]
      }
      set number($txt) ""
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, undoes the last operation.
  proc handle_u {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      gui::undo
      set number($txt) ""
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, deletes the current character.
  proc handle_x {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      if {$number($txt) ne ""} {
        $txt delete insert "insert+$number($txt)c"
        set number($txt) ""
      } else {
        $txt delete insert
      }
      return 1
    }
    
    return 0
    
  }
      
}
