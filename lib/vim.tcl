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
# Name:    vim.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    05/21/2013
# Brief:   Namespace containing special bindings to provide Vim-like
#          support.  The Vim commands supported are not meant to be
#          a complete representation of its functionality.
######################################################################

namespace eval vim {

  source [file join $::tke_dir lib ns.tcl]

  array set command_entries {}
  array set mode            {}
  array set number          {}
  array set search_dir      {}
  array set ignore_modified {}
  array set column          {}
  array set select_anchors  {}
  array set patterns {
    number {^([0-9]+|0x[0-9a-fA-F]+|[0-9]+\.[0-9]+)}
    space  {^([ \t]+)}
  }

  array set recording {
    curr_reg ""
  }

  foreach reg [list a b c d e f g h i j k l m n o p q r s t u v w x y z auto] {
    set recording($reg,mode)   "none"
    set recording($reg,events) [list]
  }

  ######################################################################
  # Enables/disables Vim mode for all text widgets.
  proc set_vim_mode_all {} {

    variable command_entries

    # Set the Vim mode on all text widgets
    foreach txt [array names command_entries] {
      if {[winfo exists $txt]} {
        set_vim_mode [winfo parent $txt] {}  ;# TBD
      } else {
        unset command_entries($txt)
      }
    }

  }

  ######################################################################
  # Enables/disables Vim mode for the specified text widget.
  proc set_vim_mode {txt tid} {

    if {[[ns preferences]::get Tools/VimMode]} {
      add_bindings $txt $tid
    } else {
      remove_bindings $txt
    }

  }

  ######################################################################
  # Returns the current edit mode type (insert or replace).
  proc get_edit_mode {txt} {

    variable mode

    if {[info exists mode($txt)]} {
      if {$mode($txt) eq "edit"} {
        return "insert"
      } elseif {[string equal -length 7 $mode($txt) "replace"]} {
        return "replace"
      }
    }

    return ""

  }

  ######################################################################
  # Returns 1 if we are currently in non-edit vim mode; otherwise,
  # returns 0.
  proc in_vim_mode {txt} {

    variable mode

    if {[[ns preferences]::get Tools/VimMode] && \
        [info exists mode($txt)] && \
        ($mode($txt) ne "edit")} {
      return 1
    } else {
      return 0
    }

  }

  ######################################################################
  # Returns the current Vim mode for the editor.
  proc get_mode {txt} {

    variable mode
    variable recording

    if {[[ns preferences]::get Tools/VimMode]} {
      set record ""
      set curr_reg $recording(curr_reg)
      if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
        set record ", REC\[ $curr_reg \]"
      }
      if {[info exists mode($txt.t)]} {
        switch $mode($txt.t) {
          "edit"        { return "INSERT MODE$record" }
          "visual:char" { return "VISUAL MODE$record" }
          "visual:line" { return "VISUAL LINE MODE$record"}
        }
      }
      return "COMMAND MODE$record"
    } else {
      return ""
    }

  }

  ######################################################################
  # Binds the given entry
  proc bind_command_entry {txt entry tid} {

    variable command_entries

    # Save the entry
    set command_entries($txt.t) $entry

    bind $entry <Return>    "[ns vim]::handle_command_return %W {$tid}"
    bind $entry <Escape>    "[ns vim]::handle_command_escape %W {$tid}"
    bind $entry <BackSpace> "[ns vim]::handle_command_backspace %W {$tid}"

  }

  ######################################################################
  # Handles the command entry text.
  proc handle_command_return {w tid} {

    # Get the last txt widget that had the focus
    set txt [[ns gui]::last_txt_focus $tid]

    # Get the value from the command field
    set value [$w get]

    # Delete the value in the command entry
    $w delete 0 end

    # Execute the command
    switch -- $value {
      w   { [ns gui]::save_current $tid }
      w!  { [ns gui]::save_current $tid }
      wq  { [ns gui]::save_current $tid; [ns gui]::close_current }
      wq! { [ns gui]::save_current $tid; [ns gui]::close_current }
      q   { [ns gui]::close_current $tid 0; set txt "" }
      q!  { [ns gui]::close_current $tid 1; set txt "" }
      cq  { [ns gui]::close_all 1 1; [ns menus]::exit_command }
      e!  { [ns gui]::update_current }
      n   { [ns gui]::next_tab }
      N   { [ns gui]::previous_tab }
      p   { after idle [ns gui]::next_pane }
      e\# { [ns gui]::last_tab }
      m   { [ns gui]::remove_current_marker $tid }
      default {
        catch {

          # Perform searcn and replace
          if {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)s/(.*)/(.*)/([giI]*)$} $value -> from to search replace opts]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend-1c"]
            [ns gui]::do_raw_search_and_replace $tid $from $to $search $replace \
              [expr [string first "i" $opts] != -1] [expr [string first "g" $opts] != -1]

          # Delete/copy lines
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)([dy])$} $value -> from to cmd]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend"]
            clipboard clear
            clipboard append [$txt get $from $to]
            if {$cmd eq "d"} {
              $txt delete $from $to
              adjust_insert $txt.t
            }
            cliphist::add_from_clipboard

          # Jump to line
          } elseif {[regexp {^(\d+|[.^$]|\w+)$} $value]} {
            $txt mark set insert [get_linenum $txt $value]
            adjust_insert $txt.t
            $txt see insert

          # Add multicursors to a range of lines
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)c/(.*)/$} $value -> from to search]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend"]
            [ns multicursor]::search_and_add_cursors $txt $from $to $search

          # Save/quit a subset of lines as a filename
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)w(q)?(!)?\s+(.*)$} $value -> from to and_close overwrite fname]} {
            set from [get_linenum $txt $from]
            set to   [get_linenum $txt $to]
            if {($overwrite eq "") && [file exists $fname]} {
              [ns gui]::set_info_message [msgcat::mc "Filename %s already exists" $fname]
            } else {
              if {[catch { open $fname w } rc]} {
                [ns gui]::set_info_message [msgcat::mc "Unable to open %s for writing" $fname]
              } else {
                puts $rc [$txt get "$from linestart" "$to lineend"]
                close $rc
                [ns gui]::set_info_message [msgcat::mc "File %s successfully written" $fname]
              }
            }
            if {$and_close ne ""} {
              [ns gui]::close_current $tid 0
              set txt ""
            }

          # Open a new file
          } elseif {[regexp {^e\s+(.*)$} $value -> filename]} {
            [ns gui]::add_file end [normalize_filename [[ns utils]::perform_substitutions $filename]]

          # Save/quit the entire file with a new name
          } elseif {[regexp {^w(q!?)?\s+(.*)$} $value -> and_close filename]} {
            [ns gui]::save_current $tid [normalize_filename [[ns utils]::perform_substitutions $filename]]
            if {$and_close ne ""} {
              [ns gui]::close_current $tid [expr {($and_close eq "q") ? 0 : 1}]
              set txt ""
            }

          # Create/delete a marker for the current line
          } elseif {[regexp {^m\s+(.*)$} $value -> marker]} {
            set line [lindex [split [$txt index insert] .] 0]
            if {$marker ne ""} {
              if {[set tag [ctext::linemapSetMark $txt $line]] ne ""} {
                [ns markers]::add $txt $tag $marker
              }
            } else {
              [ns markers]::delete_by_line $txt $line
              ctext::linemapClearMark $txt $line
            }

          # Insert the contents of a file after the current line
          } elseif {[regexp {^r\s+(.*)$} $value -> filename]} {
            if {[string index $filename 0] eq "!"} {
              [ns vim]::insert_file $txt "|[[ns utils]::perform_substitutions [string range $filename 1 end]]"
            } else {
              [ns vim]::insert_file $txt [normalize_filename [[ns utils]::perform_substitutions $filename]]
            }

          # Change the working directory
          } elseif {[regexp {^cd\s+(.*)$} $value -> directory]} {
            set directory [[ns utils]::perform_substitutions $directory]
            if {[file isdirectory $directory]} {
              cd $directory
              [ns gui]::set_title
            }
          }
        }
      }
    }

    # Remove the grab
    grab release $w

    if {$txt ne ""} {

      # Set the focus back to the text widget
      [ns gui]::set_txt_focus $txt

      # Hide the command entry widget
      grid remove $w

    }

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
      adjust_insert $txt

    }

  }

  ######################################################################
  # Adjust the current selection if we are in visual mode.
  proc adjust_select {txt index} {

    variable mode
    variable select_anchors

    # Get the visual type from the mode
    set type [string range $mode($txt) 7 end]

    # Get the anchor for the given selection
    set anchor [lindex $select_anchors($txt) $index]

    if {[$txt compare $anchor < insert]} {
      if {$type eq "char"} {
        $txt tag add sel $anchor insert
      } else {
        $txt tag add sel "$anchor linestart" "insert lineend"
      }
    } else {
      if {$type eq "char"} {
        $txt tag add sel insert $anchor
      } else {
        $txt tag add sel "insert linestart" "$anchor lineend"
      }
    }

  }

  ######################################################################
  # Handles an escape key in the command entry widget.
  proc handle_command_escape {w tid} {

    # Get the last text widget that had focus
    set txt [[ns gui]::last_txt_focus $tid]

    # Delete the value in the command entry
    $w delete 0 end

    # Remove the grab and set the focus back to the text widget
    grab release $w
    [ns gui]::set_txt_focus $txt

    # Hide the command entry widget
    grid remove $w

  }

  ######################################################################
  # Handles a backspace key in the command entry widget.
  proc handle_command_backspace {w tid} {

    if {[$w get] eq ""} {

      # Remove the grab and set the focus back to the text widget
      grab release $w
      [ns gui]::set_txt_focus [[ns gui]::last_txt_focus $tid]

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
    } elseif {[set index [[ns markers]::get_index $txt $char]] ne ""} {
      return [$txt index "$index linestart"]
    } elseif {[regexp {^\d+$} $char]} {
      return "$char.0"
    } else {
      return -code error "$char is not a valid marker name"
    }

  }

  ######################################################################
  # Add Vim bindings
  proc add_bindings {txt tid} {

    variable mode
    variable number
    variable ignore_modified
    variable column
    variable select_anchors
    variable recording

    # Change the cursor to the block cursor
    $txt configure -blockcursor true

    # Put ourselves into start mode
    set mode($txt.t)             "start"
    set number($txt.t)           ""
    set search_dir($txt.t)       "next"
    set ignore_modified($txt)    0
    set column($txt.t)           ""
    set select_anchors($txt.t)   [list]

    # Add bindings
    bind $txt       <<Modified>>      "if {\[[ns vim]::handle_modified %W\]} { break }"
    bind vim$txt    <Escape>          "if {\[[ns vim]::handle_escape %W {$tid}\]} { break }"
    bind vim$txt    <Key>             "if {\[[ns vim]::handle_any %W {$tid} %K %A\]} { break }"
    bind vim$txt    <Button-1>        "[ns vim]::handle_button1 %W %x %y; break"
    bind vim$txt    <Double-Button-1> "[ns vim]::handle_double_button1 %W %x %y; break"
    bind vim$txt    <B1-Motion>       "[ns vim]::handle_motion %W %x %y; break"
    bind vimpre$txt <Control-f>       "if {\[[ns vim]::handle_control_f %W\]} { break }"
    bind vimpre$txt <Control-b>       "if {\[[ns vim]::handle_control_b %W\]} { break }"
    bind vimpre$txt <Control-g>       "if {\[[ns vim]::handle_control_g %W\]} { break }"
    bind vimpre$txt <Control-j>       "if {\[[ns vim]::handle_control_j %W\]} { break }"
    bind vimpre$txt <Control-k>       "if {\[[ns vim]::handle_control_k %W\]} { break }"

    # Insert the vimpre binding just prior to all
    set all_index [lsearch [bindtags $txt.t] all]
    bindtags $txt.t [linsert [bindtags $txt.t] $all_index vimpre$txt]

    # Insert the vim binding just prior to Text
    set text_index [lsearch [bindtags $txt.t] Text]
    bindtags $txt.t [linsert [bindtags $txt.t] $text_index vim$txt]

    # Put ourselves into start mode
    start_mode $txt.t

    # Set autoseparator mode to false
    $txt configure -autoseparators 0

  }

  ######################################################################
  # Handles a modified event when in Vim mode.
  proc handle_modified {W} {

    variable ignore_modified

    if {[info exists ignore_modified($W)] && $ignore_modified($W)} {
      set ignore_modified($W) 0
      $W edit modified false
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a left-click event when in Vim mode.
  proc handle_button1 {W x y} {

    $W tag remove sel 1.0 end

    set current [$W index @$x,$y]
    $W mark set [[ns utils]::text_anchor $W] $current
    $W mark set insert $current

    if {[set [ns vim]::mode($W)] ne "edit"} {
      adjust_insert $W
    }

    focus $W

  }

  ######################################################################
  # Handles a double-left-click event when in Vim mode.
  proc handle_double_button1 {W x y} {

    $W tag remove sel 1.0 end

    set current [$W index @$x,$y]
    $W tag add sel [$W index "$current wordstart"] [$W index "$current wordend"]
    $W mark set insert [$W index "$current wordstart"]

    focus $W

  }

  ######################################################################
  # Handle left-button hold motion event when in Vim mode.
  proc handle_motion {W x y} {

    $W tag remove sel 1.0 end

    set current [$W index @$x,$y]
    $W tag add sel [[ns utils]::text_anchor $W] $current
    $W mark set insert $current

    if {[set [ns vim]::mode($W)] ne "edit"} {
      adjust_insert $W
    }

    focus $W

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

    # Change the cursor to the insertion cursor and turn autoseparators on
    $txt configure -blockcursor false -autoseparators 1

  }

  ######################################################################
  # Set the current mode to the "edit" mode.
  proc edit_mode {txt} {

    variable mode

    # Set the mode to the edit mode
    set mode($txt) "edit"

    # Add separator
    $txt edit separator

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

    # If we are coming from visual mode, clear the selection
    if {[string range $mode($txt) 0 5] eq "visual"} {
      $txt tag remove sel 1.0 end
    }

    # If were in the edit or replace_all state, move the insertion cursor back
    # one character.
    if {(($mode($txt) eq "edit") || ($mode($txt) eq "replace_all")) && \
        ([$txt index insert] ne [$txt index "insert linestart"])} {
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::adjust $txt -1c
      } else {
        $txt mark set insert "insert-1c"
      }
    }

    # Set the blockcursor to true
    $txt configure -blockcursor true

    # Adjust the insertion marker
    adjust_insert $txt

    # Add a separator if we were in edit mode
    if {$mode($txt) ne "start"} {
      $txt edit separator
    }

    # Set the current mode to the start mode
    set mode($txt) "start"

  }

  ######################################################################
  # Set the current mode to the "visual" mode.
  proc visual_mode {txt type} {

    variable mode
    variable select_anchors

    # Set the current mode
    set mode($txt) "visual:$type"

    # Clear the current selection
    $txt tag remove sel 1.0 end

    # Initialize the select range
    set select_anchors($txt) [$txt index insert]

    # Perform the initial selection
    adjust_select $txt 0

  }

  ######################################################################
  # Starts recording keystrokes.
  proc record_start {{reg auto}} {

    variable recording

    if {$recording($reg,mode) eq "none"} {
      set recording($reg,mode)   "record"
      set recording($reg,events) [list]
      if {$reg ne "auto"} {
        set recording(curr_reg) $reg
      }
    }

  }

  ######################################################################
  # Stops recording keystrokes.
  proc record_stop {{reg auto}} {

    variable recording

    if {$recording($reg,mode) eq "record"} {
      set recording($reg,mode) "none"
    }

  }

  ######################################################################
  # Records a signal event and stops recording.
  proc record {event {reg auto}} {

    variable recording

    if {$recording($reg,mode) eq "none"} {
      set recording($reg,events) $event
    }

  }

  ######################################################################
  # Adds an event to the recording buffer if we are in record mode.
  proc record_add {event {reg auto}} {

    variable recording

    if {$recording($reg,mode) eq "record"} {
      lappend recording($reg,events) $event
    }

  }

  ######################################################################
  # Plays back the record buffer.
  proc playback {txt {reg auto}} {

    variable recording

    # Set the record mode to playback
    set recording($reg,mode) "playback"

    # Replay the recording buffer
    foreach event $recording($reg,events) {
      eval "event generate $txt <$event>"
    }

    # Set the record mode to none
    set recording($reg,mode) "none"

  }

  ######################################################################
  # Stops recording and clears the recording array.
  proc record_clear {{reg auto}} {

    variable recording

    set recording($reg,mode)   "none"
    set recording($reg,events) [list]

  }

  ######################################################################
  # Adjust the insertion marker so that it never is allowed to sit on
  # the lineend spot.
  proc adjust_insert {txt} {

    variable mode
    variable ignore_modified

    # Remove any existing dspace characters
    remove_dspace [winfo parent $txt]

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

    # Adjust the selection (if we are in visual mode)
    if {[string range $mode($txt) 0 5] eq "visual"} {
      adjust_select $txt 0
    }

  }

  ######################################################################
  # Removes dspace characters.
  proc remove_dspace {w} {

    variable ignore_modified

    foreach {endpos startpos} [lreverse [$w tag ranges dspace]] {
      if {[lsearch [$w tag names $startpos] "mcursor"] == -1} {
        set ignore_modified($w) 1
        $w fastdelete $startpos $endpos
      }
    }

  }

  ######################################################################
  # Removes the dspace tag from the current index (if it is set).
  proc cleanup_dspace {w} {

    variable ignore_modified

    if {[lsearch [$w tag names insert] dspace] != -1} {
      set ignore_modified($w) 1
      $w tag remove dspace insert
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
  proc handle_escape {txt tid} {

    variable mode
    variable number
    variable recording

    # Add this keysym to the current recording buffer (if one exists)
    set curr_reg $recording(curr_reg)
    if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
      record_add Escape $curr_reg
    }

    if {$mode($txt) ne "start"} {

      # Add to the recording if we are doing so
      record_add Escape
      record_stop

      # Set the mode to start
      start_mode $txt

    } else {

      # If were in start mode, clear the auto recording buffer
      record_clear

      # Clear the any selections
      $txt tag remove sel 1.0 end

      # Clear any searches
      gui::clear_search $tid

    }

    # Clear the current number string
    set number($txt) ""

    return 1

  }

  ######################################################################
  # Handles any single printable character.
  proc handle_any {txt tid keysym char} {

    variable mode
    variable number
    variable column
    variable recording

    # If the key does not have a printable char representation, quit now
    if {([string compare -length 5 $keysym "Shift"]   == 0) || \
        ([string compare -length 7 $keysym "Control"] == 0) || \
        ([string compare -length 3 $keysym "Alt"]     == 0) || \
        ($keysym eq "??")} {
      return 1
    }

    # Handle a character when recording a macro
    if {$mode($txt) eq "record_reg"} {
      start_mode $txt
      if {[regexp {^[a-z]$} $keysym]} {
        record_start $keysym
        return 1
      }
    } elseif {$mode($txt) eq "playback_reg"} {
      start_mode $txt
      if {[regexp {^[a-z]$} $keysym]} {
        playback $txt $keysym
        return 1
      } elseif {$keysym eq "at"} {
        if {$recording(curr_reg) ne ""} {
          playback $txt $recording(curr_reg)
        }
        return 1
      }
    } elseif {($mode($txt) ne "start") || ($keysym ne "q")} {
      set curr_reg $recording(curr_reg)
      if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
        record_add "Key-$keysym" $curr_reg
      }
    }

    # If the keysym is neither j or k, clear the column
    if {($keysym ne "j") && ($keysym ne "k")} {
      set column($txt) ""
    }

    # If we are not in edit mode
    if {![catch "handle_$keysym $txt {$tid}" rc] && $rc} {
      record_add "Key-$keysym"
      if {$mode($txt) eq "start"} {
        set number($txt) ""
      }
      return 1
    } elseif {[string is integer $keysym] && [handle_number $txt $char]} {
      record_add "Key-$keysym"
      return 1
    } elseif {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual") || ($mode($txt) eq "record")} {
      return 1
    }

    # Add the keysym to the auto recording
    record_add "Key-$keysym"

    # Append the text to the insertion buffer
    if {[string equal -length 7 $mode($txt) "replace"]} {
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::replace $txt $char [ns indent]::check_indent
      } else {
        $txt replace insert "insert+1c" $char
        $txt highlight "insert linestart" "insert lineend"
      }
      if {$mode($txt) eq "replace"} {
        if {[[ns multicursor]::enabled $txt]} {
          [ns multicursor]::adjust $txt -1c
        } else {
          $txt mark set insert "insert-1c"
        }
        start_mode $txt
        record_stop
      }
      return 1

    # Remove all text within the current character
    } elseif {$mode($txt) eq "changein"} {
      if {([set start_index [$txt search -backwards $char insert 1.0]] ne "") && \
          ([set end_index   [$txt search -forwards  $char insert end]] ne "")} {
        $txt delete $start_index+1c $end_index
        edit_mode $txt
      } else {
        start_mode $txt
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

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      if {($mode($txt) eq "start") && ($num eq "0") && ($number($txt) eq "")} {
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
  proc handle_colon {txt tid} {

    variable mode
    variable command_entries

    # If we are in the "start" mode, bring up the command entry widget
    # and give it the focus.
    if {$mode($txt) eq "start"} {

      # Colorize the entry widget to match the look of the associated text widget
      $command_entries($txt) configure \
        -background [$txt cget -background] -foreground [$txt cget -foreground] \
        -insertbackground [$txt cget -insertbackground] -font [$txt cget -font]

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
  proc handle_dollar {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert lineend-1c"
      $txt see insert
      return 1
    } elseif {$mode($txt) eq "delete"} {
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::delete $txt "lineend"
      } else {
        clipboard clear
        clipboard append [$txt get insert "insert lineend"]
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
  proc handle_asciicircum {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      $txt mark set insert "insert linestart"
      $txt see insert
      return 1
    } elseif {$mode($txt) eq "delete"} {
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::delete $txt "linestart"
      } else {
        clipboard clear
        clipboard append [$txt get "insert linestart" insert]
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
  proc handle_slash {txt tid} {

    variable mode
    variable search_dir

    if {$mode($txt) eq "start"} {
      [ns gui]::search $tid "next"
      set search_dir($txt) "next"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, display the search bar for doing a
  # a previous search.
  proc handle_question {txt tid} {

    variable mode
    variable search_dir

    if {$mode($txt) eq "start"} {
      [ns gui]::search $tid "prev"
      set search_dir($txt) "prev"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, invokes the buffered command at the current
  # insertion point.
  proc handle_period {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      set start_index [$txt index insert]
      playback $txt
      set end_index [$txt index insert]
      if {$start_index != $end_index} {
        if {[$txt compare $start_index < $end_index]} {
          $txt highlight $start_index $end_index
        } else {
          $txt highlight $end_index $start_index
        }
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode and the insertion point character has a
  # matching left/right partner, display the partner.
  proc handle_percent {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      [ns gui]::show_match_pair $tid
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles the i-key when in Vim mode.
  proc handle_i {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      edit_mode $txt
      record_start
      return 1
    } elseif {$mode($txt) eq "change"} {
      set mode($txt) "changein"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, inserts at the beginning of the current
  # line.
  proc handle_I {txt tid} {

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
  proc handle_j {txt tid} {

    variable mode
    variable number
    variable column

    # Move the insertion cursor down one line
    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      $txt tag remove sel 1.0 end
      lassign [split [$txt index insert] .] row col
      if {$column($txt) ne ""} {
        set col $column($txt)
      } else {
        set column($txt) $col
      }
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

    variable number

    # Create a separator
    $txt edit separator

    set lines [expr {($number($txt) ne "") ? $number($txt) : 1}]

    while {$lines > 0} {

      # Perform a line join with the current line, trimming whitespace
      set line [string trimleft [$txt get "insert+1l linestart" "insert+1l lineend"]]
      $txt delete "insert lineend" "insert+1l lineend"
      set index [$txt index "insert lineend"]
      if {$line ne ""} {
        $txt insert "insert lineend" " [string trimleft $line]"
      }

      incr lines -1

    }

    # Set the insertion cursor and make it viewable
    $txt mark set insert $index
    $txt see insert

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # If we are in "start" mode, join the next line to the end of the
  # previous line.
  proc handle_J {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      if {[[ns multicursor]::enabled $txt]} {
        $txt tag remove sel 1.0 end
        [ns multicursor]::adjust $txt "+1l"
      } else {
        do_join $txt
        record "Key-J"
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor up one line.
  proc handle_k {txt tid} {

    variable mode
    variable number
    variable column

    # Move the insertion cursor up one line
    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      $txt tag remove sel 1.0 end
      lassign [split [$txt index insert] .] row col
      if {$column($txt) ne ""} {
        set col $column($txt)
      } else {
        set column($txt) $col
      }
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
  # If we are in start mode and multicursor is enabled, move all of the
  # cursors up one line.
  proc handle_K {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      $txt tag remove sel 1.0 end
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::adjust $txt "-1l"
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor right one
  # character.
  proc handle_l {txt tid} {

    variable mode
    variable number

    # Move the insertion cursor right one character
    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      $txt tag remove sel 1.0 end
      if {$number($txt) ne ""} {
        if {[$txt compare "insert lineend" < "insert+$number($txt)c"]} {
          $txt mark set insert "insert lineend"
        } else {
          $txt mark set insert "insert+$number($txt)c"
        }
        adjust_insert $txt
        $txt see insert
      } elseif {[$txt compare "insert lineend" > "insert+1c"]} {
        $txt mark set insert "insert+1c"
        adjust_insert $txt
        $txt see insert
      } else {
        bell
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode and multicursor mode is enabled, adjust
  # all of the cursors to the right by one character.  If we are only
  # in "start" mode, jump the insertion cursor to the bottom line.
  proc handle_L {txt tid} {

    variable mode

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      if {[[ns multicursor]::enabled $txt]} {
        $txt tag remove sel 1.0 end
        [ns multicursor]::adjust $txt "+1c"
      } elseif {$mode($txt) eq "start"} {
        $txt mark set insert @0,[winfo height $txt]
        adjust_insert $txt
        $txt see insert
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # Returns the string containing the
  proc get_filename {txt pos} {

    # Get the index of pos
    set index [lindex [split [$txt index $pos] .] 1]

    # Get the current line
    set line [$txt get "$pos linestart" "$pos lineend"]

    # Get the first space
    set first_space [string last " " $line $index]

    # Get the last space
    if {[set last_space [string first " " $line $index]] == -1} {
      set last_space [string length $line]
    }

    return [string range $line [expr $first_space + 1] [expr $last_space - 1]]

  }

  ######################################################################
  # If we are in "goto" mode, edit any filesnames that are found under
  # any of the cursors.
  proc handle_f {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      return 1
    } elseif {$mode($txt) eq "goto"} {
      if {[[ns multicursor]::enabled $txt]} {
        foreach {startpos endpos} [$txt tag ranges mcursor] {
          if {[file exists [set fname [get_filename $txt $startpos]]]} {
            [ns gui]::add_file end $fname
          }
        }
      } else {
        if {[file exists [set fname [get_filename $txt insert]]]} {
          [ns gui]::add_file end $fname
        }
      }
      start_mode $txt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, edit any filenames found under any of
  # the cursors.
  proc handle_g {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      set mode($txt) "goto"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor left one
  # character.
  proc handle_h {txt tid} {

    variable mode
    variable number

    # Move the insertion cursor left one character
    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      $txt tag remove sel 1.0 end
      if {$number($txt) ne ""} {
        if {[$txt compare "insert linestart" > "insert-$number($txt)c"]} {
          $txt mark set insert "insert linestart"
        } else {
          $txt mark set insert "insert-$number($txt)c"
        }
        adjust_insert $txt
        $txt see insert
      } elseif {[$txt compare "insert linestart" <= "insert-1c"]} {
        $txt mark set insert "insert-1c"
        adjust_insert $txt
        $txt see insert
      } else {
        bell
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode and multicursor mode is enabled, move all
  # cursors to the left by one character.  Otherwise, if we are just in
  # "start" mode, jump to the top line of the editor.
  proc handle_H {txt tid} {

    variable mode

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      if {[[ns multicursor]::enabled $txt]} {
        $txt tag remove sel 1.0 end
        [ns multicursor]::adjust $txt "-1c"
      } else {
        $txt mark set insert @0,0
        adjust_insert $txt
        $txt see insert
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # Returns the index of the beginning next/previous word.  If num is
  # given a value > 1, the procedure will return the beginning index of
  # the next/previous num'th word.  If no word was found, return the index
  # of the current word.
  proc get_word {txt dir {num 1} {start insert}} {

    # If the direction is 'next', search forward
    if {$dir eq "next"} {

      # Get the end of the current word (this will be the beginning of the next word)
      set curr_index [$txt index "$start wordend"]

      # Use a brute-force method of finding the next word
      while {[$txt compare $curr_index < end]} {
        if {![string is space [$txt get $curr_index]]} {
          if {[incr num -1] == 0} {
            return [$txt index "$curr_index wordstart"]
          }
        }
        set curr_index [$txt index "$curr_index wordend"]
      }

      return [$txt index "$curr_index wordstart"]

    } else {

      # Get the index of the current word
      set curr_index [$txt index "$start wordstart"]

      while {[$txt compare $curr_index > 1.0]} {
        if {![string is space [$txt get $curr_index]] && \
             [$txt compare $curr_index != $start]} {
          if {[incr num -1] == 0} {
            return $curr_index
          }
        }
        set curr_index [$txt index "$curr_index-1c wordstart"]
      }

      return $curr_index

    }

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor to the beginning
  # of previous word.
  proc handle_b {txt tid} {

    variable mode
    variable number

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      $txt tag remove sel 1.0 end
      if {$number($txt) ne ""} {
        $txt mark set insert [get_word $txt prev $number($txt)]
      } else {
        $txt mark set insert [get_word $txt prev]
      }
      adjust_insert $txt
      $txt see insert
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, change the state to "change" mode.  If
  # we are in the "change" mode, delete the current line and put ourselves
  # into edit mode.
  proc handle_c {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      set mode($txt) "change"
      record_start
      return 1
    } elseif {[string range $mode($txt) 0 5] eq "visual"} {
      if {![[ns multicursor]::delete $txt "selected"]} {
        $txt delete sel.first sel.last
      }
      edit_mode $txt
      return 1
    } elseif {$mode($txt) eq "change"} {
      if {![[ns multicursor]::delete $txt "line"]} {
        $txt delete "insert linestart" "insert lineend"
      }
      edit_mode $txt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, delete from the insertion cursor to the
  # end of the line and put ourselves into "edit" mode.
  proc handle_C {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      $txt delete insert "insert lineend"
      edit_mode $txt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "change" mode, delete the current word and change to edit
  # mode.
  proc handle_w {txt tid} {

    variable mode
    variable number

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      $txt tag remove sel 1.0 end
      if {$number($txt) ne ""} {
        $txt mark set insert [get_word $txt next $number($txt)]
      } else {
        $txt mark set insert [get_word $txt next]
      }
      adjust_insert $txt
      $txt see insert
      return 1
    } elseif {$mode($txt) eq "change"} {
      if {($number($txt) ne "") && ($number($txt) > 1)} {
        if {![[ns multicursor]::delete $txt "word" $number($txt)]} {
          $txt delete insert "[get_word $txt next [expr $number($txt) - 1]] wordend"
        }
      } else {
        if {![[ns multicursor]::delete $txt " wordend"]} {
          $txt delete insert "insert wordend"
        }
      }
      edit_mode $txt
      return 1
    } elseif {$mode($txt) eq "yank"} {
      clipboard clear
      if {$number($txt) ne ""} {
        clipboard append [$txt get "insert wordstart" "[get_word $txt next [expr $number($txt) - 1]] wordend"]
      } else {
        clipboard append [$txt get "insert wordstart" "insert wordend"]
      }
      start_mode $txt
      return 1
    } elseif {$mode($txt) eq "delete"} {
      clipboard clear
      if {$number($txt) ne ""} {
        set word [get_word $txt next [expr $number($txt) - 1]]
        clipboard append [$txt get "insert wordstart" "$word wordend"]
        $txt delete "insert wordstart" "$word wordend"
      } else {
        clipboard append [$txt get "insert wordstart" "insert wordend"]
        $txt delete "insert wordstart" "insert wordend"
      }
      start_mode $txt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, go to the last line.
  proc handle_G {txt tid} {

    variable mode
    variable number

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      if {$number($txt) ne ""} {
        $txt mark set insert [get_linenum $txt $number($txt)]
      } else {
        $txt mark set insert "end linestart"
      }
      adjust_insert $txt
      $txt see insert
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, transition the mode to the delete mode.
  # If we are in the "delete" mode, delete the current line.
  proc handle_d {txt tid} {

    variable mode
    variable number

    if {$mode($txt) eq "start"} {
      set mode($txt) "delete"
      record_start
      $txt edit separator
      return 1
    } elseif {$mode($txt) eq "delete"} {
      clipboard clear
      if {$number($txt) ne ""} {
        clipboard append [$txt get "insert linestart" "insert linestart+[expr $number($txt) - 1]l lineend"]\n
        $txt delete "insert linestart" "insert linestart+$number($txt)l"
      } else {
        clipboard append [$txt get "insert linestart" "insert lineend"]\n
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
  # If we are in "start" mode, deletes all text from the current
  # insertion cursor to the end of the line.
  proc handle_D {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      if {[multicursor::enabled $txt]} {
        multicursor::delete $txt "lineend"
      } else {
        clipboard clear
        clipboard append [$txt get insert "insert lineend"]
        $txt delete insert "insert lineend"
        adjust_insert $txt
        $txt see insert
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in the "start" mode, move the insertion cursor ahead by
  # one character and set ourselves into "edit" mode.
  proc handle_a {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::adjust $txt "+1c" 1 dspace
      }
      cleanup_dspace $txt
      $txt mark set insert "insert+1c"
      edit_mode $txt
      record_start
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, insert text at the end of the current line.
  proc handle_A {txt tid} {

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
  proc handle_y {txt tid} {

    variable mode
    variable number

    if {$mode($txt) eq "start"} {
      set mode($txt) "yank"
      return 1
    } elseif {[string range $mode($txt) 0 5] eq "visual"} {
      clipboard clear
      clipboard append [$txt get sel.first sel.last]
      cliphist::add_from_clipboard
      start_mode $txt
      return 1
    } elseif {$mode($txt) eq "yank"} {
      clipboard clear
      if {($number($txt) ne "") && ($number($txt) > 1)} {
        clipboard append [$txt get "insert linestart" "insert linestart+[expr $number($txt) - 1]l lineend"]\n
        multicursor::copy $txt "insert linestart" "insert linestart+[expr $number($txt) - 1]l lineend"
      } else {
        clipboard append [$txt get "insert linestart" "insert lineend"]\n
        multicursor::copy $txt "insert linestart" "insert lineend"
      }
      cliphist::add_from_clipboard
      start_mode $txt
      record_add "Key-y"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a paste operation from the menu (or keyboard shortcut).
  proc handle_paste {txt} {

    variable mode

    if {[[ns preferences]::get Tools/VimMode] && [info exists mode($txt.t)]} {

      # If we are not currently in edit mode, temporarily set ourselves to edit mode
      if {$mode($txt.t) ne "edit"} {
        record_add "Key-i"
      }

      # Add the characters
      foreach c [split [clipboard get] {}] {
        record_add [utils::string_to_keysym $c]
      }

      # If we were in command mode, escape out of edit mode
      if {$mode($txt.t) ne "edit"} {
        record_add "Escape"
        record_stop
      }

    }

  }

  ######################################################################
  # Pastes the contents of the given clip to the text widget after the
  # current line.
  proc do_post_paste {txt clip} {

    variable number

    # Create a separator
    $txt edit separator

    # Get the number of pastes that we need to perform
    set num [expr {($number($txt) ne "") ? $number($txt) : 1}]

    if {[set nl_index [string last \n $clip]] != -1} {
      if {[expr ([string length $clip] - 1) == $nl_index]} {
        set clip [string replace $clip $nl_index $nl_index]
      }
      $txt insert "insert lineend" [string repeat "\n$clip" $num]
      multicursor::paste $txt "insert+${num}l linestart"
      $txt mark set insert "insert+${num}l linestart"
    } else {
      set clip [string repeat $clip $num]
      $txt insert "insert+1c" $clip
      multicursor::paste $txt "insert+1c"
      $txt mark set insert "insert+[string length $clip]c"
    }
    adjust_insert $txt
    $txt see insert

    # Create a separator
    $txt edit separator

  }

  ######################################################################
  # If we are in the "start" mode, put the contents of the clipboard
  # after the current line.
  proc handle_p {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      do_post_paste $txt [set clip [clipboard get]]
      cliphist::add_from_clipboard
      record "Key-p"
      return 1
    }

    return 0

  }

  ######################################################################
  # Pastes the contents of the given clip prior to the current line
  # in the text widget.
  proc do_pre_paste {txt clip} {

    variable number

    $txt edit separator

    # Calculate the number of clips to pre-paste
    set num [expr {($number($txt) ne "") ? $number($txt) : 1}]

    if {[set nl_index [string last \n $clip]] != -1} {
      if {[expr ([string length $clip] - 1) == $nl_index]} {
        set clip [string replace $clip $nl_index $nl_index]
      }
      $txt insert "insert linestart" [string repeat "$clip\n" $num]
      multicursor::paste $txt "insert linestart"
    } else {
      $txt insert "insert-1c" [string repeat $clip $num]
      multicursor::paste $txt "insert-1c"
    }
    adjust_insert $txt

    # Create separator
    $txt edit separator

  }

  ######################################################################
  # If we are in the "start" mode, put the contents of the clipboard
  # before the current line.
  proc handle_P {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      do_pre_paste $txt [set clip [clipboard get]]
      cliphist::add_from_clipboard
      record "Key-P"
      return 1
    }

    return 0

  }

  ######################################################################
  # Performs an undo operation.
  proc undo {txt} {

    # Perform the undo operation
    $txt edit undo

    # Adjusts the insertion cursor if we are in Vim mode
    if {[in_vim_mode $txt]} {
      adjust_insert $txt
    }

  }

  ######################################################################
  # Performs a redo operation.
  proc redo {txt} {

    # Performs the redo operation
    $txt edit redo

    # Adjusts the insertion cursor if we are in Vim mode
    if {[in_vim_mode $txt]} {
      adjust_insert $txt
    }

  }

  ######################################################################
  # If we are in "start" mode, undoes the last operation.
  proc handle_u {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      undo $txt
      return 1
    }

    return 0

  }

  ######################################################################
  # Performs a single character delete.
  proc do_char_delete_current {txt number} {

    # Create separator
    $txt edit separator

    if {$number ne ""} {
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::delete $txt "+${number}c"
      } elseif {[$txt compare "insert+${number}c" > "insert lineend"]} {
        $txt delete insert "insert lineend"
        if {[$txt index insert] eq [$txt index "insert linestart"]} {
          $txt insert insert " "
        }
        $txt mark set insert "insert-1c"
      } else {
        $txt delete insert "insert+${number}c"
      }
    } elseif {[[ns multicursor]::enabled $txt]} {
      [ns multicursor]::delete $txt "+1c"
    } else {
      $txt delete insert
      if {[$txt index insert] eq [$txt index "insert lineend"]} {
        if {[$txt index insert] eq [$txt index "insert linestart"]} {
          $txt insert insert " "
        }
        $txt mark set insert "insert-1c"
      }
    }

    # Adjust the cursor
    adjust_cursor $txt

    # Create separator
    $txt edit separator

  }

  ######################################################################
  # Performs a single character delete.
  proc do_char_delete_previous {txt number} {

    # Create separator
    $txt edit separator

    if {$number ne ""} {
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::delete $txt "-${number}c"
      } elseif {[$txt compare "insert-${number}c" < "insert linestart"]} {
        $txt delete "insert linestart" insert
      } else {
        $txt delete "insert-${number}c" insert
      }
    } elseif {[[ns multicursor]::enabled $txt]} {
      [ns multicursor]::delete $txt "-1c"
    } elseif {[$txt compare "insert-1c" >= "insert linestart"] && ([$txt index insert] ne "1.0")} {
      $txt delete "insert-1c"
    }

    # Adjust the cursor
    adjust_cursor $txt

    # Create separator
    $txt edit separator

  }

  ######################################################################
  # If we are in "start" mode, deletes the current character.
  proc handle_x {txt tid} {

    variable mode
    variable number

    if {$mode($txt) eq "start"} {
      do_char_delete_current $txt $number($txt)
      record_add "Key-x"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, deletes the current character (same as
  # the 'x' command).
  proc handle_Delete {txt tid} {

    variable mode
    variable number

    if {$mode($txt) eq "start"} {
      do_char_delete_current $txt $number($txt)
      record_add "Key-Delete"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, deletes the previous character.
  proc handle_X {txt tid} {

    variable mode
    variable number

    if {$mode($txt) eq "start"} {
      do_char_delete_previous $txt $number($txt)
      record_add "Key-X"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, add a new line below the current line
  # and transition into "edit" mode.
  proc handle_o {txt tid} {

    variable mode
    variable number

    if {$mode($txt) eq "start"} {
      edit_mode $txt
      set insert [$txt index insert]
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::adjust $txt "+1l" 1 dspace
      } else {
        $txt insert "insert lineend" "\n"
      }
      if {$insert == [$txt index insert]} {
        $txt mark set insert "insert+1l"
      }
      $txt see insert
      [ns indent]::newline $txt insert
      record_start
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, add a new line above the current line
  # and transition into "edit" mode.
  proc handle_O {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      edit_mode $txt
      if {[[ns multicursor]::enabled $txt]} {
        [ns multicursor]::adjust $txt "-1l" 1 dspace
      } else {
        $txt insert "insert linestart" "\n"
      }
      $txt mark set insert "insert-1l"
      [ns indent]::newline $txt insert
      record_start
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, set the mode to the "quit" mode.  If we
  # are in "quit" mode, save and exit the current tab.
  proc handle_Z {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      set mode($txt) "quit"
      return 1
    } elseif {$mode($txt) eq "quit"} {
      [ns gui]::save_current $tid
      [ns gui]::close_current $tid
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, finds the next occurrence of the search text.
  proc handle_n {txt tid} {

    variable mode
    variable search_dir
    variable number
    variable patterns

    if {$mode($txt) eq "start"} {
      set count [expr {($number($txt) ne "") ? $number($txt) : 1}]
      if {$search_dir($txt) eq "next"} {
        for {set i 0} {$i < $count} {incr i} {
          [ns gui]::search_next $tid 0
        }
      } else {
        for {set i 0} {$i < $count} {incr i} {
          [ns gui]::search_prev $tid 0
        }
      }
      return 1
    } elseif {$mode($txt) eq "delete"} {
      if {[multicursor::enabled $txt]} {
        foreach {endpos startpos} [lreverse [$txt tag ranges mcursor]] {
          if {[regexp $patterns(number) [$txt get $startpos "$startpos lineend"] -> num]} {
            $txt delete $startpos "$startpos+[string length $num]c"
          }
        }
      } else {
        if {[regexp $patterns(number) [$txt get insert "insert lineend"] -> num]} {
          $txt delete insert "insert+[string length $num]c"
        }
      }
      start_mode $txt
      record_add "Key-n"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, finds the previous occurrence of the
  # search text.
  proc handle_N {txt tid} {

    variable mode
    variable search_dir
    variable number

    if {$mode($txt) eq "start"} {
      set count [expr {($number($txt) ne "") ? $number($txt) : 1}]
      if {$search_dir($txt) eq "next"} {
        for {set i 0} {$i < $count} {incr i} {
          [ns gui]::search_prev $tid 0
        }
      } else {
        for {set i 0} {$i < $count} {incr i} {
          [ns gui]::search_next $tid 0
        }
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, replaces the current character with the
  # next character.
  proc handle_r {txt tid} {

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
  proc handle_R {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      set mode($txt) "replace_all"
      record_start
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, puts the mode into "visual char" mode.
  proc handle_v {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      visual_mode $txt char
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, puts the mode into "visual line" mode.
  proc handle_V {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      visual_mode $txt line
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the cursor down by 1 page.
  proc handle_control_f {txt} {

    variable mode

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
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

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      eval [string map {%W $txt} [bind Text <Prior>]]
      adjust_insert $txt
      record "Control-b"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, display the current text counts.
  proc handle_control_g {txt} {

    variable mode

    if {$mode($txt) eq "start"} {
      [ns gui]::display_file_counts $txt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the current line or selection down one line.
  proc handle_control_j {txt} {

    variable mode

    if {$mode($txt) eq "start"} {
      $txt edit separator
      if {[llength [set selected [$txt tag ranges sel]]] > 0} {
        foreach {end_range start_range} [lreverse $selected] {
          set str [$txt get "$end_range+1l linestart" "$end_range+l2 linestart"]
          $txt delete "$end_range lineend" "$end_range+1l lineend"
          $txt insert "$start_range linestart" $str
        }
      } else {
        set str [$txt get "insert+1l linestart" "insert+2l linestart"]
        $txt delete "insert lineend" "insert+1l lineend"
        $txt insert "insert linestart" $str
      }
      $txt edit separator
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the current line or selection up one line.
  proc handle_control_k {txt} {

    variable mode

    if {$mode($txt) eq "start"} {
      $txt edit separator
      if {[llength [set selected [$txt tag ranges sel]]] > 0} {
        foreach {end_range start_range} [lreverse $selected] {
          set str [$txt get "$start_range-1l linestart" "$start_range linestart"]
          $txt delete "$start_range-1l linestart" "$start_range linestart"
          $txt insert "$end_range+1l linestart" $str
        }
      } else {
        set str [$txt get "insert-1l linestart" "insert linestart"]
        $txt delete "insert-1l linestart" "insert linestart"
        if {[$txt compare "insert+1l linestart" == end]} {
          set str "\n[string trimright $str]"
        }
        $txt insert "insert+1l linestart" $str
      }
      $txt edit separator
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, add a cursor.
  proc handle_s {txt tid} {

    variable mode
    variable patterns

    if {$mode($txt) eq "start"} {
      [ns multicursor]::add_cursor $txt [$txt index insert]
      return 1
    } elseif {$mode($txt) eq "delete"} {
      if {[multicursor::enabled $txt]} {
        foreach {endpos startpos} [lreverse [$txt tag ranges mcursor]] {
          if {[regexp $patterns(space) [$txt get $startpos "$startpos lineend"] -> space]} {
            $txt delete $startpos "$startpos+[string length $space]c"
          }
        }
      } else {
        if {[regexp $patterns(space) [$txt get insert "insert lineend"] -> space]} {
          $txt delete insert "insert+[string length $space]c"
        }
      }
      start_mode $txt
      record_add "Key-s"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, add cursors between the current anchor
  # the current line.
  proc handle_S {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      [ns multicursor]::add_cursors $txt [$txt index insert]
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, run the gui::insert_numbers procedure to
  # allow the user to potentially insert incrementing numbers into the
  # specified text widget.
  proc handle_numbersign {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      [ns gui]::insert_numbers $txt
      return 1
    }

    return 0

  }

  ######################################################################
  # Moves the specified bracket one word to the right.
  proc move_bracket_right {txt tid char} {

    if {[set index [$txt search -forwards -- $char insert]] ne ""} {
      $txt delete $index
      $txt insert "$index wordend" $char
    }

  }

  ######################################################################
  # Inserts or moves the specified bracket pair.
  proc place_bracket {txt tid left {right ""}} {

    variable mode

    # Get the current selection
    if {[llength [set selected [$txt tag ranges sel]]] > 0} {
      foreach {end start} [lreverse $selected] {
        $txt insert $end [expr {($right eq "") ? $left : $right}]
        $txt insert $start $left
      }
      return 1
    }

    # If we are in start mode, add the bracket in the appropriate place
    if {$mode($txt) eq "start"} {
      if {($left eq "\"") || ($left eq "'")} {
        set tag [expr {($left eq "'") ? "_sString" : "_dString"}]
        if {[lsearch [$txt tag names insert] $tag] != -1} {
          move_bracket_right $txt $tid $left
        } else {
          $txt insert "insert wordend"   $left
          $txt insert "insert wordstart" $left
        }
      } else {
        set re "(\\$left|\\$right)"
        if {([set index [$txt search -backwards -regexp -- $re insert]] ne "") && ([$txt get $index] eq $left)} {
          move_bracket_right $txt $tid $right
        } else {
          $txt insert "insert wordend"   $right
          $txt insert "insert wordstart" $left
        }
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If any text is selected, double quotes are placed around all
  # selections.  If the insertion cursor is within a completed
  # string, the right-most quote of the completed string is moved one
  # word to the end; otherwise, the current word is placed within
  # double-quotes.
  proc handle_quotedbl {txt tid} {

    return [place_bracket $txt $tid \"]

  }

  ######################################################################
  # If any text is selected, single quotes are placed around all
  # selections.  If the insertion cursor is within a completed
  # single string, the right-most quote of the completed string is moved one
  # word to the end; otherwise, the current word is placed within
  # single-quotes.
  proc handle_apostrophe {txt tid} {

    return [place_bracket $txt $tid ']

  }

  ######################################################################
  # If any text is selected, curly brackets are placed around all
  # selections.  If the insertion cursor is within a completed
  # bracket sequence, the right-most bracket of the sequence is moved one
  # word to the end; otherwise, the current word is placed within
  # curly brackets.
  proc handle_bracketleft {txt tid} {

    return [place_bracket $txt $tid \[ \]]

  }

  ######################################################################
  # If any text is selected, square brackets are placed around all
  # selections.  If the insertion cursor is within a completed
  # bracket sequence, the right-most bracket of the sequence is moved one
  # word to the end; otherwise, the current word is placed within
  # square brackets.
  proc handle_braceleft {txt tid} {

    return [place_bracket $txt $tid \{ \}]

  }

  ######################################################################
  # If any text is selected, parenthesis are placed around all
  # selections.  If the insertion cursor is within a completed
  # parenthetical sequence, the right-most parenthesis of the sequence
  # is moved one word to the end; otherwise, the current word is placed
  # within parenthesis.
  proc handle_parenleft {txt tid} {

    return [place_bracket $txt $tid ( )]

  }

  ######################################################################
  # If any text is selected, angled brackets are placed around all
  # selections.  If the insertion cursor is within a completed
  # bracket sequence, the right-most bracket of the sequence is moved one
  # word to the end; otherwise, the current word is placed within
  # angled brackets.
  proc handle_less {txt tid} {

    return [place_bracket $txt $tid < >]

  }

  ######################################################################
  # If we are in "start" or "visual" mode, moves the insertion cursor to the first
  # non-whitespace character in the next line.
  proc handle_Return {txt tid} {

    variable mode

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      $txt mark set insert "insert+1l linestart"
      if {[string is space [$txt get insert]]} {
        set next_word [get_word $txt next]
        if {[$txt compare $next_word < "insert lineend"]} {
          $txt mark set insert $next_word
        } else {
          $txt mark set insert "insert lineend"
        }
      }
      adjust_insert $txt
      $txt see insert
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" or "visual" mode, moves the insertion cursor to the first
  # non-whitespace character in the previous line.
  proc handle_minus {txt tid} {

    variable mode

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      $txt mark set insert "insert-1l linestart"
      if {[string is space [$txt get insert]]} {
        set next_word [get_word $txt next]
        if {[$txt compare $next_word < "insert lineend"]} {
          $txt mark set insert $next_word
        } else {
          $txt mark set insert "insert lineend"
        }
      }
      adjust_insert $txt
      $txt see insert
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" or "visual" mode, move the cursor to the given
  # column of the current line.
  proc handle_bar {txt tid} {

    variable mode
    variable number

    if {(($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")) && ($number($txt) ne "")} {
      $txt mark set insert [lindex [split [$txt index insert] .] 0].$number($txt)
      adjust_insert $txt
      $txt see insert
      return 1
    }

    return 0

  }

  ######################################################################
  # Converts a character-by-character case inversion of the given text.
  proc convert_case {txt index str} {

    set strlen [string length $str]

    for {set i 0} {$i < $strlen} {incr i} {
      set char [string index $str $i]
      append newstr [expr {[string is lower $char] ? [string toupper $char] : [string tolower $char]}]
    }

    $txt replace $index "$index+${strlen}c" $newstr

    adjust_insert $txt

  }

  ######################################################################
  # If we are in "start" mode, change the case of the current character.
  proc handle_asciitilde {txt tid} {

    variable mode
    variable number

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      if {[llength [set sel_ranges [$txt tag ranges sel]]] > 0} {
        foreach {endpos startpos} [lreverse $sel_ranges] {
          convert_case $txt $startpos [$txt get $startpos $endpos]
        }
      } else {
        set num_chars [expr {($number($txt) ne "") ? $number($txt) : 1}]
        set str       [string range [$txt get insert "insert lineend"] 0 [expr $num_chars - 1]]
        convert_case $txt insert $str
      }
      if {[string range $mode($txt) 0 5] eq "visual"} {
        start_mode $txt
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the cursor to the start of the middle
  # line.
  proc handle_M {txt tid} {

    variable mode

    if {($mode($txt) eq "start") || ([string range $mode($txt) 0 5] eq "visual")} {
      $txt mark set insert @0,[expr [winfo height $txt] / 2]
      adjust_insert $txt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, search for all occurences of the current
  # word.
  proc handle_asterisk {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      set word [$txt get "insert wordstart" "insert wordend"]
      catch { ctext::deleteHighlightClass [winfo parent $txt] search }
      ctext::addSearchClass [winfo parent $txt] search black yellow "" $word
      $txt tag lower _search sel
      gui::search_next $tid 0
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, sets the current mode to "record" mode.
  proc handle_q {txt tid} {

    variable mode
    variable recording

    if {$mode($txt) eq "start"} {
      set curr_reg $recording(curr_reg)
      if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
        record_stop $curr_reg
      } else {
        set mode($txt) "record_reg"
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in start mode, do nothing.  If we are in quit mode, close
  # the current tab without writing the file (same as :q!).
  proc handle_Q {txt tid} {

    variable mode

    if {$mode($txt) eq "start"} {
      return 1
    } elseif {$mode($txt) eq "quit"} {
      [ns gui]::close_current $tid 1
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, replays the register specified with the
  # next character.  If we are in "replay_reg" mode, playback the current
  # register again.
  proc handle_at {txt tid} {

    variable mode
    variable recording

    if {$mode($txt) eq "start"} {
      set mode($txt) "playback_reg"
      return 1
    }

    return 0

  }

}
