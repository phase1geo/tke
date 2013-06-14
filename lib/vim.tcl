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
  array set buffer          {}
  array set search_dir      {}
  array set ignore_modified {}
  
  ######################################################################
  # Enables/disables Vim mode for the current text widget.
  proc set_vim_mode_all {} {
 
    variable command_entries

    # Set the Vim mode on all text widgets
    foreach txt [array names command_entries] {
      set_vim_mode [winfo parent $txt]
    }
    
  }
  
  ######################################################################
  # Enables/disables Vim mode for the specified text widget.
  proc set_vim_mode {txt} {

    if {$preferences::prefs(Tools/VimMode)} {
      add_bindings $txt
    } else {
      remove_bindings $txt
    }
    
  }

  ######################################################################
  # Binds the given entry 
  proc bind_command_entry {txt entry} {
  
    variable command_entries
    
    # Save the entry
    set command_entries($txt.t) $entry
  
    bind $entry <Return>    "vim::handle_command_return %W $txt"
    bind $entry <Escape>    "vim::handle_command_escape %W $txt"
    bind $entry <BackSpace> "vim::handle_command_backspace %W $txt"
  
  }
  
  ######################################################################
  # Handles the command entry text.
  proc handle_command_return {w txt} {
      
    # Get the value from the command field
    set value [$w get]
    
    # Delete the value in the command entry
    $w delete 0 end
    
    # Execute the command
    switch -- $value {
      w  { gui::save_current }
      w! { gui::save_current }
      wq { gui::save_current; gui::close_current }
      q  { gui::close_current }
      q! { gui::close_current }
      n  { gui::next_tab }
      e\# { gui::previous_tab }
      default {
        if {[regexp {^([0-9]+|[.^$]),([0-9]+|[.^$])s/(.*)/(.*)/(g?)$} $value -> from to search replace glob]} {
          set from [get_linenum $txt $from]
          set to   [$txt index "[get_linenum $txt $to] lineend-1c"]
          gui::do_raw_search_and_replace $from $to $search $replace [expr {$glob eq "g"}]
        } elseif {[regexp {^([0-9]+|[.^$]),([0-9]+|[.^$])([dy])$} $value -> from to cmd]} {
          set from [get_linenum $txt $from]
          set to   [$txt index "[get_linenum $txt $to] lineend-1c"]
          clipboard clear
          clipboard append [$txt get $from $to]
          if {$cmd eq "d"} {
            $txt delete $from $to
          }
        } elseif {[regexp {^([0-9]+|[.^$])$} $value]} {
          $txt mark set insert [get_linenum $txt $value]
          adjust_insert $txt.t
          $txt see insert
        } elseif {[regexp {^e\s+(.*)$} $value -> filename]} {
          gui::add_file end [file normalize $filename]
        } elseif {[regexp {^w\s+(.*)$} $value -> filename]} {
          gui::save_current $filename
        }
      }
    }
    
    # Remove the grab and set the focus back to the text widget
    grab release $w
    focus $txt.t
    
    # Hide the command entry widget
    grid remove $w 
  
  }
  
  ######################################################################
  # Handles an escape key in the command entry widget.
  proc handle_command_escape {w txt} {
    
    # Delete the value in the command entry
    $w delete 0 end
    
    # Remove the grab and set the focus back to the text widget
    grab release $w
    focus $txt.t
    
    # Hide the command entry widget
    grid remove $w
    
  }
  
  ######################################################################
  # Handles a backspace key in the command entry widget.
  proc handle_command_backspace {w txt} {
 
    if {[$w get] eq ""} {
      
      # Remove the grab and set the focus back to the text widget
      grab release $w
      focus $txt.t
      
      # Hide the command entry widget
      grid remove $w
      
    }
  
  }
 
  ######################################################################
  # Returns the line number based on the given line number character.
  proc get_linenum {txt char} {
    
    if {$char eq "."} {
      return [$txt index "insert linestart"]
    } elseif {$char eq "^"} {
      return "1.0"
    } elseif {$char eq "$"} {
      return [$txt index "end linestart"]
    } else {
      return "$char.0"
    }
    
  }
  
  ######################################################################
  # Add Vim bindings 
  proc add_bindings {txt} {
    
    variable mode
    variable number
    variable buffer
    variable ignore_modified
    
    # Change the cursor to the block cursor
    $txt configure -blockcursor true
    
    # Put ourselves into start mode
    set mode($txt.t)          "start"
    set number($txt.t)        ""
    set search_dir($txt.t)    "next"
    set ignore_modified($txt) 0
    
    # Handle any other modifications to the text
    bind $txt <<Modified>>   {
      if {[info exists vim::ignore_modified(%W)] && $vim::ignore_modified(%W)} {
        set vim::ignore_modified(%W) 0
        %W edit modified false
        break
      }
    }
 
    bind vim$txt <Escape> {
      if {[vim::handle_escape %W]} {
        break
      }
    }
    bind vim$txt <Any-Key> {
      if {[vim::handle_any %W %K %A]} {
        break
      }
    }
    bind vimpre$txt <Control-f> {
      if {[vim::handle_control_f %W]} {
        break
      }
    }
    bind vimpre$txt <Control-b> {
      if {[vim::handle_control_b %W]} {
        break
      }
    }
    bind vim$txt <Button-1> {
      %W tag remove sel 1.0 end
      %W mark set insert [%W index @%x,%y]
      vim::adjust_insert %W
      focus %W
      break
    }
    
    # Insert the vimpre binding just prior to all
    set all_index [lsearch [bindtags $txt.t] all]
    bindtags $txt.t [linsert [bindtags $txt.t] $all_index vimpre$txt]
    
    # Insert the vim binding just prior to Text    
    set text_index [lsearch [bindtags $txt.t] Text]
    bindtags $txt.t [linsert [bindtags $txt.t] $text_index vim$txt]
    
    # Put ourselves into start mode
    start_mode $txt.t
 
  }
  
  ######################################################################
  # Remove the Vim bindings on the text widget.
  proc remove_bindings {txt} {
    
    # Remove the vim* bindings from the widget
    if {[set index [lsearch [bindtags $txt.t] vim$txt]] != -1} {
      bindtags $txt.t [lreplace [bindtags $txt.t] $index $index]
    }
    
    # Remove the vimpre* bindings from the widget
    if {[set index [lsearch [bindtags $txt.t] vimpre$txt]] != -1} {
      bindtags $txt.t [lreplace [bindtags $txt.t] $index $index]
    }
    
    # Move $txt.t <<Modified>> binding back to $txt
    bind $txt <<Modified>> ""
    
    # Change the cursor to the insertion cursor
    $txt configure -blockcursor false
    
  }
  
  ######################################################################
  # Set the current mode to the "edit" mode.
  proc edit_mode {txt} {
    
    variable mode
    variable buffer
    
    # Set the mode to the edit mode
    set mode($txt) "edit"
 
    # Set the blockcursor to false
    $txt configure -blockcursor false
 
    # Clear the buffer
    set buffer($txt) ""
    
    # If the current cursor is on a dummy space, remove it
    if {[lsearch [$txt tag names insert] "dspace"] != -1} {
      $txt delete insert
    }

    # Update the current indentation level
    indent::update_indent_level $txt insert insert
 
  }
 
  ######################################################################
  # Set the current mode to the "start" mode.
  proc start_mode {txt} {
 
    variable mode
    
    # If we are going from the edit state to the start state, add a separator
    # to the undo stack.
    if {$mode($txt) eq "edit"} {
      $txt edit separator
    }
    
    # Set the current mode to the start mode
    set mode($txt) "start"
    
    # Set the blockcursor to true
    $txt configure -blockcursor true
    
    # Adjust the insertion marker
    adjust_insert $txt
 
  }
  
  ######################################################################
  # Adjust the insertion marker so that it never is allowed to sit on
  # the lineend spot.
  proc adjust_insert {txt} {
  
    variable ignore_modified
  
    # Remove any existing dspace characters
    cleanup_dspace [winfo parent $txt]
    
    # If the current line contains nothing, add a dummy space so that the
    # block cursor doesn't look dumb.
    if {[$txt index "insert linestart"] eq [$txt index "insert lineend"]} {
      set ignore_modified([winfo parent $txt]) 1
      $txt insert insert " " dspace
    }
    
    # Make sure that lineend is never the insertion point
    if {[$txt index insert] ne [$txt index "insert linestart"]} {
      $txt mark set insert "insert-1c"
    }
    
  }
 
  ######################################################################
  # Cleans up the dspace.
  proc cleanup_dspace {w} {
    
    variable ignore_modified
    
    foreach {endpos startpos} [lreverse [$w tag ranges dspace]] {
      set ignore_modified($w) 1
      $w delete $startpos $endpos
    }
    
  }
  
  ######################################################################
  # Handles the escape-key when in Vim mode.
  proc handle_escape {txt} {
    
    variable mode
    variable number
    
    if {$mode($txt) ne "start"} {
      
      # Clear the current number string
      set number($txt) ""
    
      # Set the mode to start
      start_mode $txt
      
    }
    
    return 1
    
  }
  
  ######################################################################
  # Handles any single printable character.
  proc handle_any {txt keysym char} {

    variable mode
    variable number
    variable buffer
    
    # If we are not in edit mode
    if {![catch "handle_$keysym $txt" rc] && $rc} {
      if {$mode($txt) eq "start"} {
        set number($txt) ""
      }
      return 1
    } elseif {[string is integer $keysym] && [handle_number $txt $char]} {
      return 1
    }

    # Append the text to the insertion buffer
    if {$mode($txt) eq "edit"} {
      append buffer($txt) $char
    } else {
      if {$mode($txt) eq "replace"} {
        $txt replace insert "insert+1c" $char
        start_mode $txt
      } elseif {$mode($txt) eq "replace_all"} {
        $txt replace insert "insert+1c" $char
      }
      return 1
    }
    
    return 0
        
  }
  
  ######################################################################
  # If we are in "start" mode, the number is 0 and the current number
  # is empty, set the insertion cursor to the beginning of the line;
  # otherwise, append the number current to number value.
  proc handle_number {txt num} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      if {($num eq "0") && ($number($txt) eq "")} {
        $txt mark set insert "insert linestart"
        $txt see insert
      } else {
        append number($txt) $num
      }
      return 1
    }
    
    return 0
  
  }
  
  ######################################################################
  # If we are in the "start" mode, display the command entry field and
  # give it the focus.
  proc handle_colon {txt} {
  
    variable mode
    variable command_entries
    
    # If we are in the "start" mode, bring up the command entry widget
    # and give it the focus.
    if {$mode($txt) eq "start"} {
    
      # Show the command entry widget
      grid $command_entries($txt)
      
      # Set the focus and grab on the widget
      grab $command_entries($txt)
      focus $command_entries($txt)
      
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
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert lineend-1c"
      $txt see insert
      return 1
    } elseif {$mode($txt) eq "delete"} {
      $txt delete insert "insert lineend"
      start_mode $txt
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
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert linestart"
      $txt see insert
      return 1
    } elseif {$mode($txt) eq "delete"} {
      $txt delete "insert linestart" insert
      start_mode $txt
      return 1
    }
    
    return 0

  }
  
  ######################################################################
  # If we are in "start" mode, display the search bar.
  proc handle_slash {txt} {
  
    variable mode
    variable search_dir
    
    if {$mode($txt) eq "start"} {
      gui::search "next"
      set search_dir($txt) "next"
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, display the search bar for doing a
  # a previous search.
  proc handle_question {txt} {
    
    variable mode
    variable search_dir
    
    if {$mode($txt) eq "start"} {
      gui::search "prev"
      set search_dir($txt) "prev"
      return 1
    }
    
    return 0
    
  }
 
  ######################################################################
  # If we are in "start" mode, inserts the contents of the insertion
  # buffer at the current location.
  proc handle_period {txt} {
 
    variable mode
    variable buffer
 
    if {$mode($txt) eq "start"} {
      $txt insert insert $buffer($txt)
      $txt mark set insert "insert-1c"
      return 1
    }
 
    return 0
      
  }
 
  ######################################################################
  # If we are in "start" mode and the insertion point character has a
  # matching left/right partner, display the partner. 
  proc handle_percent {txt} {
    
    variable mode
    
    if {$mode($txt) eq "start"} {
      gui::show_match_pair
      return 1
    }
    
    return 0
    
  }

  ######################################################################
  # Handles the i-key when in Vim mode.
  proc handle_i {txt} {
    
    variable mode
    variable buffer
    
    if {$mode($txt) eq "start"} {
      edit_mode $txt
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, inserts at the beginning of the current
  # line.
  proc handle_I {txt} {
    
    variable mode
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert linestart"
      edit_mode $txt
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
      $txt tag remove sel 1.0 end
      if {$number($txt) ne ""} {
        $txt mark set insert "insert+$number($txt)l"
      } else {
        $txt mark set insert "insert+1l"
      }
      if {[$txt index insert] ne [$txt index "insert lineend"]} {
        $txt mark set insert "insert+1c"
      }
      adjust_insert $txt
      $txt see insert
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, join the next line to the end of the
  # previous line.
  proc handle_J {txt} {

    variable mode

    if {$mode($txt) eq "start"} {
      set line [string trimleft [$txt get "insert+1l linestart" "insert+1l lineend"]]
      $txt delete "insert+1l linestart" "insert+2l linestart"
      set index [$txt index "insert lineend"]
      if {$line ne ""} {
        $txt insert "insert lineend" " [string trimleft $line]"
      }
      $txt mark set insert $index
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
      $txt tag remove sel 1.0 end
      if {$number($txt) ne ""} {
        $txt mark set insert "insert-$number($txt)l"
      } else {
        $txt mark set insert "insert-1l"
      }
      if {[$txt index insert] ne [$txt index "insert lineend"]} {
        $txt mark set insert "insert+1c"
      }
      adjust_insert $txt
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
      $txt tag remove sel 1.0 end
      if {$number($txt) ne ""} {
        if {[utils::compare_indices [$txt index "insert lineend"] [$txt index "insert+$number($txt)c"]] == -1} {
          $txt mark set insert "insert lineend"
        } else {
          $txt mark set insert "insert+$number($txt)c"
        }
      } elseif {[utils::compare_indices [$txt index "insert lineend"] [$txt index "insert+1c"]] == 1} {
        $txt mark set insert "insert+1c"
      } else {
        bell
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
      $txt tag remove sel 1.0 end
      if {$number($txt) ne ""} {
        if {[utils::compare_indices [$txt index "insert linestart"] [$txt index "insert-$number($txt)c"]] == 1} {
          $txt mark set insert "insert linestart"
        } else {
          $txt mark set insert "insert-$number($txt)c"
        }
      } elseif {[utils::compare_indices [$txt index "insert linestart"] [$txt index "insert-1c"]] != 1} {
        $txt mark set insert "insert-1c"
      } else {
        bell
      }
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, change the state to "cut" mode.
  proc handle_c {txt} {
  
    variable mode
    
    if {$mode($txt) eq "start"} {
      set mode($txt) "cut"
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "cut" mode, delete the current word and change to edit
  # mode.
  proc handle_w {txt} {
  
    variable mode
    
    if {$mode($txt) eq "cut"} {
      $txt delete insert "insert wordend"
      edit_mode $txt
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, go to the last line.
  proc handle_G {txt} {
  
    variable mode
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "end linestart"
      adjust_insert $txt
      $txt see end
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
      set mode($txt) "delete"
      return 1
    } elseif {$mode($txt) eq "delete"} {
      clipboard clear
      if {$number($txt) ne ""} {
        clipboard append [$txt get "insert linestart" "insert linestart+$number($txt)l"]
        $txt delete "insert linestart" "insert linestart+$number($txt)l"
      } else {
        clipboard append [$txt get "insert linestart" "insert linestart+1l"]
        $txt delete "insert linestart" "insert linestart+1l"
      }
      start_mode $txt
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in the "start" mode, move the insertion cursor ahead by
  # one character and set ourselves into "edit" mode.
  proc handle_a {txt} {
  
    variable mode
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert+1c"
      edit_mode $txt
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, insert text at the end of the current line.
  proc handle_A {txt} {
    
    variable mode
    
    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert lineend"
      edit_mode $txt
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
      set mode($txt) "yank"
      return 1
    } elseif {$mode($txt) eq "yank"} {
      clipboard clear
      if {($number($txt) ne "") && ($number($txt) > 1)} {
        clipboard append [$txt get "insert linestart" "insert linestart+[expr $number($txt) - 1]l lineend"]
      } else {
        clipboard append [$txt get "insert linestart" "insert lineend"]
      }
      start_mode $txt
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in the "start" mode, put the contents of the clipboard
  # after the current line.
  proc handle_p {txt} {
  
    variable mode

    if {$mode($txt) eq "start"} {
      $txt insert "insert lineend" "\n[clipboard get]"
      $txt mark set insert "insert+1l linestart"
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in the "start" mode, put the contents of the clipboard
  # before the current line.
  proc handle_P {txt} {
  
    variable mode

    if {$mode($txt) eq "start"} {
      $txt insert "insert linestart" "[clipboard get]\n"
      return 1
    }
    
    return 0
  
  }

  ######################################################################
  # If we are in "start" mode, undoes the last operation.
  proc handle_u {txt} {
  
    variable mode
    
    if {$mode($txt) eq "start"} {
      gui::undo
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
        if {[utils::compare_indices [$txt index "insert+$number($txt)c"] [$txt index "insert lineend"]] == 1} {
          $txt delete insert "insert lineend"
          if {[$txt index insert] eq [$txt index "insert linestart"]} {
            $txt insert insert " "
          }
          $txt mark set insert "insert-1c"
        } else {
          $txt delete insert "insert+$number($txt)c"
        }
      } else {
        $txt delete insert
        if {[$txt index insert] eq [$txt index "insert lineend"]} {
          if {[$txt index insert] eq [$txt index "insert linestart"]} {
            $txt insert insert " "
          }
          $txt mark set insert "insert-1c"
        }
      }
      $txt edit separator
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, add a new line below the current line
  # and transition into "edit" mode.
  proc handle_o {txt} {
  
    variable mode
    
    if {$mode($txt) eq "start"} {
      $txt insert "insert lineend" "\n"
      $txt mark set insert "insert+1l"
      edit_mode $txt
      indent::newline $txt insert insert
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, add a new line above the current line
  # and transition into "edit" mode.
  proc handle_O {txt} {
  
    variable mode
    
    if {$mode($txt) eq "start"} {
      $txt insert "insert linestart" "\n"
      $txt mark set insert "insert-1l"
      edit_mode $txt
      indent::newline $txt insert insert
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, set the mode to the "quit" mode.  If we
  # are in "quit" mode, save and exit the current tab.
  proc handle_Z {txt} {
  
    variable mode
    
    if {$mode($txt) eq "start"} {
      set mode($txt) "quit"
      return 1
    } elseif {$mode($txt) eq "quit"} {
      gui::save_current
      gui::close_current
      return 1
    }
    
    return 0
    
  }
 
  ######################################################################
  # If we are in "start" mode, finds the next occurrence of the search text.
  proc handle_n {txt} {
      
    variable mode
    variable search_dir
 
    if {$mode($txt) eq "start"} {
      if {$search_dir($txt) eq "next"} {
        gui::search_next 0
      } else {
        gui::search_prev 0
      }
      return 1
    }
    
    return 0
    
  }
 
  ######################################################################
  # If we are in "start" mode, replaces the current character with the
  # next character.
  proc handle_r {txt} {
 
    variable mode
 
    if {$mode($txt) eq "start"} {
      set mode($txt) "replace"
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, replaces all characters until the escape
  # key is hit.
  proc handle_R {txt} {
    
    variable mode
    
    if {$mode($txt) eq "start"} {
      set mode($txt) "replace_all"
      return 1
    }
    
    return 0
    
  }
    
  ######################################################################
  # If we are in "start" mode, move the cursor down by 1 page.
  proc handle_control_f {txt} {
    
    variable mode
    
    if {$mode($txt) eq "start"} {
      eval [string map {%W $txt} [bind Text <Next>]]
      adjust_insert $txt
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, move the cursor up by 1 page.
  proc handle_control_b {txt} {
    
    variable mode
    
    if {$mode($txt) eq "start"} {
      eval [string map {%W $txt} [bind Text <Prior>]]
      adjust_insert $txt
      return 1
    }
    
    return 0
    
  }
        
}
