######################################################################
# Name:    vim.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    05/21/2013
# Brief:   Namespace containing special bindings to provide Vim-like
#          support.  The Vim commands supported are not meant to be
#          a complete representation of its functionality.
######################################################################
 
namespace eval vim {
 
  variable record_mode "none"
  variable recording   {}

  array set command_entries {}
  array set mode            {}
  array set number          {}
  array set search_dir      {}
  array set ignore_modified {}
  array set column          {}
  
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
  # Returns 1 if we are currently in non-edit vim mode; otherwise,
  # returns 0.
  proc in_vim_mode {txt} {
    
    variable mode
    
    if {$preferences::prefs(Tools/VimMode) && [info exists mode($txt)] && ($mode($txt) ne "edit")} {
      return 1
    } else {
      return 0
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
      q  { gui::close_current 0 }
      q! { gui::close_current 1 }
      e! { gui::update_current }
      n  { gui::next_tab }
      e\# { gui::previous_tab }
      m  {
        set line [lindex [split [$txt index insert] .] 0]
        markers::delete_by_line $txt $line
        ctext::linemapClearMark $txt $line
      }
      default {
        catch {
          if {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)s/(.*)/(.*)/(g?)$} $value -> from to search replace glob]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend-1c"]
            gui::do_raw_search_and_replace $from $to $search $replace [expr {$glob eq "g"}]
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)([dy])$} $value -> from to cmd]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend"]
            clipboard clear
            clipboard append [$txt get $from $to]
            if {$cmd eq "d"} {
              $txt delete $from $to
              adjust_insert $txt.t
            }
          } elseif {[regexp {^(\d+|[.^$]|\w+)$} $value]} {
            $txt mark set insert [get_linenum $txt $value]
            adjust_insert $txt.t
            $txt see insert
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)c/(.*)/$} $value -> from to search]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend"]
            multicursor::search_and_add_cursors $txt $from $to $search
          } elseif {[regexp {^e\s+(.*)$} $value -> filename]} {
            gui::add_file end [normalize_filename $filename]
          } elseif {[regexp {^w\s+(.*)$} $value -> filename]} {
            gui::save_current [normalize_filename $filename]
          } elseif {[regexp {^m\s+(.*)$} $value -> marker]} {
            set line [lindex [split [$txt index insert] .] 0]
            if {$marker ne ""} {
              markers::add $txt [$txt index insert] $marker
              ctext::linemapSetMark $txt $line
            } else {
              markers::delete_by_line $txt $line
              ctext::linemapClearMark $txt $line
            }
          } elseif {[regexp {^r\s+(.*)$} $value -> filename]} {
            vim::insert_file $txt $filename
          } elseif {[regexp {^cd\s+(.*)$} $value -> directory]} {
            if {[file isdirectory $directory]} {
              cd $directory
              gui::set_title
            }
          }
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
  # Normalizes the given filename string, performing any environment
  # variable substitutions.
  proc normalize_filename {file_str} {
    
    while {[regexp -indices {(\$(\w+))} $file_str -> str var]} {
      set var [string range $file_str {*}$var]
      if {[info exists ::env($var)]} {
        set file_str [string replace $file_str {*}$str $::env($var)]
      } else {
        return -code error "Environment variable $var does not exist"
      }
    }
    
    return [file normalize $file_str]
    
  }
  
  ######################################################################
  # Inserts the given file contents beneath the current insertion line.
  proc insert_file {txt filename} {
    
    if {![catch "open $filename r" rc]} {
      
      # Read the contents of the file and close the file
      set contents [read $rc]
      close $rc
      
      # Insert the file contents beneath the current insertion line
      $txt insert "insert lineend" "\n$contents"
      
      # Adjust the insert cursor
      adjust_cursor $txt
      
    }
    
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
    } elseif {[set index [markers::get_index $txt $char]] ne ""} {
      return [$txt index "$index linestart"]
    } elseif {[regexp {^\d+$} $char]} {
      return "$char.0"
    } else {
      return -code error "$char is not a valid marker name"
    }
    
  }
  
  ######################################################################
  # Add Vim bindings 
  proc add_bindings {txt} {
    
    variable mode
    variable number
    variable ignore_modified
    variable column
    
    # Change the cursor to the block cursor
    $txt configure -blockcursor true
    
    # Put ourselves into start mode
    set mode($txt.t)          "start"
    set number($txt.t)        ""
    set search_dir($txt.t)    "next"
    set ignore_modified($txt) 0
    set column($txt.t)        ""
    
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
      set current [%W index @%x,%y]
      # if {($vim::mode(%W) ne "edit") && ($current ne [%W index "$current lineend"])} {
      #   set current [%W index "$current+1c"]
      # }
      %W mark set [utils::text_anchor %W] $current
      %W mark set insert $current
      if {$vim::mode(%W) ne "edit"} {
        vim::adjust_insert %W
      }
      focus %W
      break
    }
    bind vim$txt <Double-Button-1> {
      %W tag remove sel 1.0 end
      set current [%W index @%x,%y]
      # if {($vim::mode(%W) ne "edit") && ($current ne [%W index "$current lineend"])} {
      #   set current [%W index "$current+1c"]
      # }
      %W tag add sel [%W index "$current wordstart"] [%W index "$current wordend"]
      %W mark set insert [%W index "$current wordstart"]
      focus %W
      break
    }
    bind vim$txt <B1-Motion> {
      %W tag remove sel 1.0 end
      set current [%W index @%x,%y]
      %W tag add sel [utils::text_anchor %W] $current
      %W mark set insert $current
      if {$vim::mode(%W) ne "edit"} {
        vim::adjust_insert %W
      }
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
    
    # Set the mode to the edit mode
    set mode($txt) "edit"
 
    # Set the blockcursor to false
    $txt configure -blockcursor false
 
    # If the current cursor is on a dummy space, remove it
    set tags [$txt tag names insert]
    if {([lsearch $tags "dspace"] != -1) && ([lsearch $tags "mcursor"] == -1)} {
      $txt delete insert
    }
 
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
    
    # If were in the edit or replace_all state, move the insertion cursor back
    # one character.
    if {(($mode($txt) eq "edit") || ($mode($txt) eq "replace_all")) && \
        ([$txt index insert] ne [$txt index "insert linestart"])} {
      $txt mark set insert "insert-1c"
    }

    # Set the current mode to the start mode
    set mode($txt) "start"
    
    # Set the blockcursor to true
    $txt configure -blockcursor true
    
    # Adjust the insertion marker
    adjust_insert $txt
 
  }
  
  ######################################################################
  # Starts recording keystrokes.
  proc record_start {} {
    
    variable record_mode
    variable recording
    
    if {$record_mode eq "none"} {
      set record_mode "record"
      set recording   [list]
    }
    
  }
  
  ######################################################################
  # Stops recording keystrokes.
  proc record_stop {} {
    
    variable record_mode
    
    if {$record_mode eq "record"} {
      set record_mode "none"
    }
    
  }
  
  ######################################################################
  # Records a signal event and stops recording.
  proc record {event} {
    
    variable record_mode
    variable recording
    
    if {$record_mode eq "none"} {
      set recording $event
    }
    
  }
  
  ######################################################################
  # Adds an event to the recording buffer if we are in record mode.
  proc record_add {event} {
    
    variable record_mode
    variable recording
    
    if {$record_mode eq "record"} {
      lappend recording $event
    }
    
  }
  
  ######################################################################
  # Plays back the record buffer.
  proc playback {txt} {
    
    variable record_mode
    variable recording

    # Set the record mode to playback
    set record_mode "playback"
    
    # Replay the recording buffer
    foreach event $recording {
      eval "event generate $txt <$event>"
    }
    
    # Set the record mode to none
    set record_mode "none"
    
  }
  
  ######################################################################
  # Stops recording and clears the recording array.
  proc record_clear {} {
    
    variable record_mode
    variable recording
    
    set record_mode "none"
    set recording   [list]
    
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
      $txt fastinsert insert " " dspace
      $txt mark set insert "insert-1c"
      
    # Make sure that lineend is never the insertion point
    } elseif {[$txt index insert] eq [$txt index "insert lineend"]} {
      $txt mark set insert "insert-1c"
    }
    
  }
  
  ######################################################################
  # Cleans up the dspace.
  proc cleanup_dspace {w} {

    variable ignore_modified
      
    foreach {endpos startpos} [lreverse [$w tag ranges dspace]] {
      if {[lsearch [$w tag names $startpos] "mcursor"] == -1} {
        set ignore_modified($w) 1
        $w fastdelete $startpos $endpos
      }
    }

  }
 
  ######################################################################
  # Returns the contents of the given text widget without the injected
  # dspaces.
  proc get_cleaned_content {txt} {
  
    set str ""
    set last_startpos 1.0
    
    # Remove any dspace characters
    foreach {startpos endpos} [$txt tag ranges dspace] {
      append str [$txt get $last_startpos $startpos]
      set last_startpos $endpos
    }
    
    append str [$txt get $last_startpos "end-1c"]
    
    return $str
    
  }
  
  ######################################################################
  # Handles the escape-key when in Vim mode.
  proc handle_escape {txt} {
    
    variable mode
    variable number
    
    if {$mode($txt) ne "start"} {
      
      # Add to the recording if we are doing so
      record_add Escape
      record_stop
      
      # Set the mode to start
      start_mode $txt
      
    } else {
      
      # If were in start mode, clear the recording buffer
      record_clear
      
    }
    
    # Clear the current number string
    set number($txt) ""

    return 1
    
  }
  
  ######################################################################
  # Handles any single printable character.
  proc handle_any {txt keysym char} {

    variable mode
    variable number
    variable column
    
    # If the keysym is the shift key, stop
    if {($keysym eq "Shift_L") || ($keysym eq "Shift_R")} {
      return 1
    }
    
    # If the keysym is neither j or k, clear the column
    if {($keysym ne "j") && ($keysym ne "k")} {
      set column($txt) ""
    }
    
    # If we are not in edit mode
    if {![catch "handle_$keysym $txt" rc] && $rc} {
      record_add "Key-$keysym"
      if {$mode($txt) eq "start"} {
        set number($txt) ""
      }
      return 1
    } elseif {[string is integer $keysym] && [handle_number $txt $char]} {
      record_add "Key-$keysym"
      return 1
    } elseif {$mode($txt) eq "start"} {
      return 1
    }
    
    record_add "Key-$keysym"

    # Append the text to the insertion buffer
    if {[string equal -length 7 $mode($txt) "replace"]} {
      $txt replace insert "insert+1c" $char
      $txt highlight "insert linestart" "insert lineend"
      if {$mode($txt) eq "replace"} {
        $txt mark set insert "insert-1c"
        start_mode $txt
        record_stop
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
        record_start
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
      if {[multicursor::enabled $txt]} {
        multicursor::delete $txt "lineend"
      } else {
        $txt delete insert "insert lineend"
      }
      start_mode $txt
      record_add "Key-dollar"
      record_stop
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
      if {[multicursor::enabled $txt]} {
        multicursor::delete $txt "linestart"
      } else {
        $txt delete "insert linestart" insert
      }
      start_mode $txt
      record_add "Key-asciicircum"
      record_stop
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
  # If we are in "start" mode, invokes the buffered command at the current
  # insertion point.
  proc handle_period {txt} {
 
    variable mode
 
    if {$mode($txt) eq "start"} {
      playback $txt
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
    
    if {$mode($txt) eq "start"} {
      edit_mode $txt
      record_start
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
      record_start
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, move the insertion cursor down one line.
  proc handle_j {txt} {
  
    variable mode
    variable number
    variable column
    
    # Move the insertion cursor down one line
    if {$mode($txt) eq "start"} {
      lassign [split [$txt index insert] .] row col
      if {$column($txt) ne ""} {
        set col $column($txt)
      } else {
        set column($txt) $col
      }
      $txt tag remove sel 1.0 end
      set row [expr {$row + (($number($txt) ne "") ? $number($txt) : 1)}]
      if {[$txt compare "$row.$col" < end]} {
        $txt mark set insert "$row.$col"
        adjust_insert $txt
        $txt see insert
      }
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # Performs a join operation.
  proc do_join {txt} {

    # Perform a line join with the current line, trimming whitespace
    set line [string trimleft [$txt get "insert+1l linestart" "insert+1l lineend"]]
    $txt delete "insert+1l linestart" "insert+2l linestart"
    set index [$txt index "insert lineend"]
    if {$line ne ""} {
      $txt insert "insert lineend" " [string trimleft $line]"
    }
    $txt mark set insert $index
    $txt see insert

    # Create a separator in the text history
    $txt edit separator

  }

  ######################################################################
  # If we are in "start" mode, join the next line to the end of the
  # previous line.
  proc handle_J {txt} {

    variable mode

    if {$mode($txt) eq "start"} {
      do_join $txt
      record "Key-J"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor up one line.
  proc handle_k {txt} {
  
    variable mode
    variable number
    variable column
    
    # Move the insertion cursor up one line
    if {$mode($txt) eq "start"} {
      lassign [split [$txt index insert] .] row col
      if {$column($txt) ne ""} {
        set col $column($txt)
      } else {
        set column($txt) $col
      }
      $txt tag remove sel 1.0 end
      set row [expr {$row - (($number($txt) ne "") ? $number($txt) : 1)}]
      if {$row >= 1} {
        $txt mark set insert "$row.$col"
        adjust_insert $txt
        $txt see insert
      }
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
        $txt see insert
      } elseif {[utils::compare_indices [$txt index "insert lineend"] [$txt index "insert+1c"]] == 1} {
        $txt mark set insert "insert+1c"
        $txt see insert
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
        $txt see insert
      } elseif {[utils::compare_indices [$txt index "insert linestart"] [$txt index "insert-1c"]] != 1} {
        $txt mark set insert "insert-1c"
        $txt see insert
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
      record_start
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # Performs a word cut operation.
  proc do_word_cut {txt} {
    
    $txt delete insert "insert wordend"
    edit_mode $txt
 
  }
  
  ######################################################################
  # If we are in "cut" mode, delete the current word and change to edit
  # mode.
  proc handle_w {txt} {
  
    variable mode
    
    if {$mode($txt) eq "cut"} {
      do_word_cut $txt
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
      record_start
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
      record_add "Key-d"
      record_stop
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
      if {[multicursor::enabled $txt]} {
        multicursor::adjust $txt "+1c" 1 dspace
      }
      $txt mark set insert "insert+1c"
      edit_mode $txt
      record_start
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
      record_start
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
      record_add "Key-y"
      record_stop
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # Pastes the contents of the given clip to the text widget after the
  # current line.
  proc do_post_paste {txt clip} {
    
    # $txt insert "insert+1l linestart" "$clip\n"
    $txt insert "insert lineend" "\n$clip"
    $txt mark set insert "insert+1l linestart"
    $txt see insert
    
    # Create a marker in the text history
    $txt edit separator
    
  }
  
  ######################################################################
  # If we are in the "start" mode, put the contents of the clipboard
  # after the current line.
  proc handle_p {txt} {
  
    variable mode

    if {$mode($txt) eq "start"} {
      do_post_paste $txt [set clip [clipboard get]]
      record "Key-p"
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # Pastes the contents of the given clip prior to the current line
  # in the text widget.
  proc do_pre_paste {txt clip} {
    
    $txt insert "insert linestart" "$clip\n"
    
    # Create a marker in the text history
    $txt edit separator
    
  }
  
  ######################################################################
  # If we are in the "start" mode, put the contents of the clipboard
  # before the current line.
  proc handle_P {txt} {
  
    variable mode

    if {$mode($txt) eq "start"} {
      do_pre_paste $txt [set clip [clipboard get]]
      record "Key-P"
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
      adjust_insert $txt
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # Performs a single character delete.
  proc do_char_delete {txt number} {

    if {$number ne ""} {
      if {[multicursor::enabled $txt]} {
        multicursor::delete $txt "+${number}c"
      } elseif {[utils::compare_indices [$txt index "insert+${number}c"] [$txt index "insert lineend"]] == 1} {
        $txt delete insert "insert lineend"
        if {[$txt index insert] eq [$txt index "insert linestart"]} {
          $txt insert insert " "
        }
        $txt mark set insert "insert-1c"
      } else {
        $txt delete insert "insert+${number}c"
      }
    } elseif {[multicursor::enabled $txt]} {
      multicursor::delete $txt "+1c"
    } else {
      $txt delete insert
      if {[$txt index insert] eq [$txt index "insert lineend"]} {
        if {[$txt index insert] eq [$txt index "insert linestart"]} {
          $txt insert insert " "
        }
        $txt mark set insert "insert-1c"
      }
    }

    # Create a separator in the text history
    $txt edit separator

  }

  ######################################################################
  # If we are in "start" mode, deletes the current character.
  proc handle_x {txt} {
  
    variable mode
    variable number
    
    if {$mode($txt) eq "start"} {
      do_char_delete $txt $number($txt)
      record_add "Key-x"
      record_stop
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
      if {[multicursor::enabled $txt]} {
        multicursor::adjust $txt "+1l" 1 dspace
      } else {
        $txt insert "insert lineend" "\n"
      }
      $txt mark set insert "insert+1l"
      $txt see insert
      edit_mode $txt
      indent::newline $txt insert
      record_start
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
      if {[multicursor::enabled $txt]} {
        multicursor::adjust $txt "-1l" 1 dspace
      } else {
        $txt insert "insert linestart" "\n"
      }
      $txt mark set insert "insert-1l"
      edit_mode $txt
      indent::newline $txt insert
      record_start
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
      record_start
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
      record_start
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
      record "Control-f"
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
      record "Control-b"
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, add a cursor.
  proc handle_s {txt} {
    
    variable mode
    
    if {$mode($txt) eq "start"} {
      multicursor::add_cursor $txt [$txt index insert]
      return 1
    }
    
    return 0
    
  }
  
  ######################################################################
  # If we are in "start" mode, add cursors between the current anchor
  # the current line.
  proc handle_S {txt} {
    
    variable mode
    
    if {$mode($txt) eq "start"} {
      multicursor::add_cursors $txt [$txt index insert]
      return 1
    }
    
    return 0
    
  }
  
}
