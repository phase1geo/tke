# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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

  variable modelines

  array set command_entries {}
  array set mode            {}
  array set number          {}
  array set search_dir      {}
  array set ignore_modified {}
  array set column          {}
  array set select_anchors  {}
  array set modeline        {}

  array set recording {
    curr_reg ""
  }

  foreach reg [list a b c d e f g h i j k l m n o p q r s t u v w x y z auto] {
    set recording($reg,mode)   "none"
    set recording($reg,events) [list]
  }

  trace variable [ns preferences]::prefs(Editor/VimModelines) w [list [ns vim]::handle_vim_modelines]

  ######################################################################
  # Handles any value changes to the Editor/VimModlines preference value.
  proc handle_vim_modelines {name1 name2 op} {

    variable modelines

    set modelines [[ns preferences]::get Editor/VimModelines]

  }

  ######################################################################
  # Enables/disables Vim mode for all text widgets.
  proc set_vim_mode_all {} {

    variable command_entries

    # Set the Vim mode on all text widgets
    foreach txtt [array names command_entries] {
      if {[winfo exists $txtt]} {
        set_vim_mode [winfo parent $txtt] {}  ;# TBD
      } else {
        unset command_entries($txtt)
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

    # Update the position information in the status bar
    [ns gui]::update_position $txt

  }

  ######################################################################
  # Returns the current edit mode type (insert or replace).
  proc get_edit_mode {txtt} {

    variable mode

    if {[info exists mode($txtt)]} {
      if {$mode($txtt) eq "edit"} {
        return "insert"
      } elseif {[string equal -length 7 $mode($txtt) "replace"]} {
        return "replace"
      }
    }

    return ""

  }

  ######################################################################
  # Returns 1 if we are currently in non-edit vim mode; otherwise,
  # returns 0.
  proc in_vim_mode {txtt} {

    variable mode

    if {[[ns preferences]::get Tools/VimMode] && \
        [info exists mode($txtt)] && \
        ($mode($txtt) ne "edit")} {
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
          "format"      { return "FORMAT$record" }
        }
      }
      return "COMMAND MODE$record"
    } else {
      return ""
    }

  }

  ######################################################################
  # Parses the first N lines of the given text widget for a Vim modeline.
  # Parses out the language (if specified) and/or indentation information.
  proc parse_modeline {txt} {

    variable modeline
    variable modelines

    if {$modelines && $modeline($txt.t)} {

      foreach line [split [$txt get 1.0 "1.0+${modelines}l"] \n] {
        if {[regexp {\s(vi|vim|vim\d+|vim<\d+|vim>\d+|vim=\d+|ex):\s*(set\s+(.*):|(.*)$)} $line -> dummy1 dummy2 opts1 opts2]} {
          set opts [expr {([string range $dummy2 0 2] eq "set") ? $opts1 : $opts2}]
          set opts [string map {"\\:" {:} ":" { }} $opts]
          foreach opt $opts {
            if {[regexp {(\S+?)(([+-])?=(\S+))?$} $opt -> key dummy mod val]} {
              do_set_command {} $txt $key $val $mod 1
            }
          }
        }
      }

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
      w   { [ns gui]::save_current $tid 0 }
      w!  { [ns gui]::save_current $tid 1 }
      wq  { if {[[ns gui]::save_current $tid 0]} { [ns gui]::close_current $tid 0; set txt "" } }
      wq! { if {[[ns gui]::save_current $tid 1]} { [ns gui]::close_current $tid 0; set txt "" } }
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

          # Perform search and replace
          if {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)s/(.*)/(.*)/([giI]*)$} $value -> from to search replace opts]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend-1c"]
            [ns search]::replace_do_raw $tid $from $to $search $replace \
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
            [ns edit]::jump_to_line $txt.t [get_linenum $txt $value]

          # Add multicursors to a range of lines
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)c/(.*)/$} $value -> from to search]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend"]
            [ns multicursor]::search_and_add_cursors $txt $from $to $search

          # Save/quit a subset of lines as a filename
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)w(q)?(!)?\s+(.*)$} $value -> from to and_close overwrite fname]} {
            set from [$txt index "[get_linenum $txt $from] linestart"]
            set to   [$txt index "[get_linenum $txt $to] lineend"]
            if {[[ns edit]::save_selection $txt $from $to [expr {$overwrite eq "!"}] $fname]} {
              if {$and_close ne ""} {
                [ns gui]::close_current $tid 0
                set txt ""
              }
            }

          # Open a new file
          } elseif {[regexp {^e\s+(.*)$} $value -> filename]} {
            [ns gui]::add_file end [normalize_filename [[ns utils]::perform_substitutions $filename]]

          # Save/quit the entire file with a new name
          } elseif {[regexp {^w(q)?(!)?\s+(.*)$} $value -> and_close and_force filename]} {
            if {![file exists [file dirname [set filename [normalize_filename [[ns utils]::perform_substitutions $filename]]]]]} {
              [ns gui]::set_error_message [msgcat::mc "Unable to write"] [msgcat::mc "Filename directory does not exist"]
            } else {
              [ns gui]::save_current $tid [expr {$and_force ne ""}] [normalize_filename [[ns utils]::perform_substitutions $filename]]
              if {$and_close ne ""} {
                [ns gui]::close_current $tid [expr {($and_close eq "q") ? 0 : 1}]
                set txt ""
              }
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
              [ns edit]::insert_file $txt "|[[ns utils]::perform_substitutions [string range $filename 1 end]]"
            } else {
              [ns edit]::insert_file $txt [normalize_filename [[ns utils]::perform_substitutions $filename]]
            }

          # Change the working directory
          } elseif {[regexp {^cd\s+(.*)$} $value -> directory]} {
            if {[file isdirectory [[ns utils]::perform_substitutions $directory]]} {
              gui::change_working_directory $directory
            }

          # Handle set commands
          } elseif {[regexp {^set?\s+(.*)$} $value -> opts]} {
            foreach opt [split $opts ": "] {
              if {[regexp {(\S+?)(([+-])?=(\S+))?$} $opt -> key dummy mod val]} {
                set txt [do_set_command $tid $txt $key $val $mod]
              }
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
  # Handles set command calls and modeline settings.
  proc do_set_command {tid txt opt val mod {ml 0}} {

    switch $opt {
      autochdir        -
      acd              {
        if {$ml} { return $txt }
        do_set_autochdir 1
      }
      noautochdir      -
      noacd            {
        if {$ml} { return $txt }
        do_set_autochdir 0
      }
      autoindent       -
      ai               { do_set_indent_mode $tid IND 1 }
      noautoindent     -
      noai             { do_set_indent_mode $tid IND 0 }
      expandtab        -
      et               { do_set_expandtab $tid 1 }
      noexpandtab      -
      noet             { do_set_expandtab $tid 0 }
      fileformat       -
      ff               { do_set_fileformat $tid $val }
      matchpairs       -
      mps              { do_set_matchpairs $tid $val $mod }
      modeline         -
      ml               { do_set_modeline $tid 1 }
      nomodeline       -
      noml             { do_set_modeline $tid 0 }
      modelines        -
      mls              {
        if {$ml} { return $txt }
        do_set_modelines $val
      }
      modifiable       -
      ma               { do_set_modifiable $tid 1 }
      nomodifiable     -
      noma             { do_set_modifiable $tid 0 }
      modified         -
      mod              { do_set_modified $tid 1 }
      nomodified       -
      nomod            { do_set_modified $tid 0 }
      number           -
      nu               { do_set_number $tid 1 }
      nonumber         -
      nonu             { do_set_number $tid 0 }
      numberwidth      -
      nuw              {
        if {$ml} { return $txt }
        do_set_numberwidth $tid $val
      }
      relativenumber   -
      rnu              { do_set_relativenumber $tid relative }
      norelativenumber -
      nornu            { do_set_relativenumber $tid absolute }
      shiftwidth       -
      sw               { do_set_shiftwidth $tid $val }
      smartindent      -
      si               { do_set_indent_mode $tid IND+ 1 }
      nosmartindent    -
      nosi             { do_set_indent_mode $tid IND+ 0 }
      splitbelow       -
      sb               { do_set_split $tid 1 }
      nosplitbelow     -
      nosb             { do_set_split $tid 0; set txt [[ns gui]::current_txt $tid] }
      syntax           -
      syn              { do_set_syntax $val }
      tabstop          -
      ts               { do_set_tabstop $tid $val }
      default          {
        [ns gui]::set_info_message [format "%s (%s)" [msgcat::mc "Unrecognized vim option"] $opt]
      }
    }

    return $txt

  }

  ######################################################################
  # Causes the current working directory to automatically change to be
  # the directory of the currently opened file.  This is a global setting.
  proc do_set_autochdir {value} {

    [ns gui]::set_auto_cwd $value

  }

  ######################################################################
  # Sets the indentation mode based on the current value, the specified
  # type (IND, IND+) and the value (0 or 1).
  proc do_set_indent_mode {tid type value} {

    array set newval {
      {OFF,IND,0}   {OFF}
      {OFF,IND,1}   {IND}
      {OFF,IND+,0}  {OFF}
      {OFF,IND+,1}  {IND+}
      {IND,IND,0}   {OFF}
      {IND,IND,1}   {IND}
      {IND,IND+,0}  {IND}
      {IND,IND+,1}  {IND+}
      {IND+,IND,0}  {IND+}
      {IND+,IND,1}  {IND+}
      {IND+,IND+,0} {OFF}
      {IND+,IND+,1} {IND+}
    }

    # Get the current mode
    set curr [[ns indent]::get_indent_mode [[ns gui]::current_txt $tid]]

    # If the indentation mode will change, set it to the new value
    if {$curr ne $newval($curr,$type,$value)} {
      [ns indent]::set_indent_mode $tid $newval($curr,$type,$value)
    }

  }

  ######################################################################
  # Sets the tab expansion mode for the current buffer to (use tabs or
  # translate tabs to spaces.
  proc do_set_expandtab {tid val} {

    [ns snippets]::set_expandtabs [[ns gui]::current_txt $tid] $val

  }

  ######################################################################
  # Set the EOL setting for the current buffer.
  proc do_set_fileformat {tid val} {

    array set map {
      dos  crlf
      unix lf
      mac  cr
    }

    # Set the current EOL translation
    if {[info exists map($val)]} {
      [ns gui]::set_current_eol_translation $map($val)
    } else {
      [ns gui]::set_info_message [format "%s (%s)" [msgcat::mc "File format unrecognized"] $val]
    }

  }

  ######################################################################
  # Set the matchpairs to the given value(s).  The value of val is like
  # <:> and mod will be {}, + or -.
  proc do_set_matchpairs {tid val mod} {

    # Get the current text widget
    set txt [[ns gui]::current_txt $tid]

    # Get the current match characters
    set match_chars [ctext::getAutoMatchChars $txt]
    set new_chars   [list]

    # Iterate through the match characters
    foreach pair [split $val ,] {
      switch $pair {
        \{:\} { lappend new_chars curly }
        \(:\) { lappend new_chars paren }
        \[:\] { lappend new_chars square }
        <:>   { lappend new_chars angled }
      }
    }

    # Handle the modification value
    switch $mod {
      {} { set match_chars $new_chars }
      \+ { set match_chars [::struct::set union $match_chars $new_chars] }
      \- { set match_chars [::struct::set difference $match_chars $new_chars] }
    }

    # Set the AutoMatchChars to the given set
    ctext::setAutoMatchChars $txt $match_chars

  }

  ######################################################################
  # Sets whether or not modeline information should be used for the current
  # buffer.
  proc do_set_modeline {tid val} {

    variable modeline

    set modeline([[ns gui]::current_txt $tid].t) $val

  }

  ######################################################################
  # Sets the number of lines to parse for modeline information.
  proc do_set_modelines {val} {

    variable modelines

    if {[string is integer $val]} {
      set modelines $val
    } else {
      [ns gui]::set_info_message [msgcat::mc "Illegal modelines value"]
    }

  }

  ######################################################################
  # Set the locked status of the current buffer.
  proc do_set_modifiable {tid val} {

    [ns gui]::set_current_file_lock $tid [expr {$val ? 0 : 1}]

  }

  ######################################################################
  # Changes the modified state of the current buffer.
  proc do_set_modified {tid val} {

    [ns gui]::set_current_modified $val

  }

  ######################################################################
  # Sets the visibility of the line numbers.
  proc do_set_number {tid val} {

    [ns gui]::set_line_number_view $tid $val

  }

  ######################################################################
  # Sets the minimum width of the line number gutter area to the specified
  # value.
  proc do_set_numberwidth {tid val} {

    if {[string is integer $val]} {
      [ns gui]::set_line_number_width $tid $val
    } else {
      [ns gui]::set_info_message [format "%s (%s)" [msgcat::mc "Number width not a number"] $val]
    }

  }

  ######################################################################
  # Sets the relative numbering mode to the given value.
  proc do_set_relativenumber {tid val} {

    [[ns gui]::current_txt $tid] configure -linemap_type $val

  }

  ######################################################################
  # Specifies the number of spaces to use for each indentation.
  proc do_set_shiftwidth {tid val} {

    if {[string is integer $val]} {
      [ns indent]::set_shiftwidth [[ns gui]::current_txt $tid].t $val
    } else {
      [ns gui]::set_info_message [msgcat::mc "Shiftwidth value is not an integer"]
    }

  }

  ######################################################################
  # Shows or hides split view in the current buffer.
  proc do_set_split {tid val} {

    if {$val} {
      [ns gui]::show_split_pane $tid
    } else {
      [ns gui]::hide_split_pane $tid
    }

  }

  ######################################################################
  # Run the set syntax command.
  proc do_set_syntax {val} {

    [ns syntax]::set_current_language [[ns syntax]::get_vim_language $val]

  }

  ######################################################################
  # Specifies number of spaces that a TAB in the file counts for.
  proc do_set_tabstop {tid val} {

    if {[string is integer $val]} {
      [ns indent]::set_tabstop [[ns gui]::current_txt $tid].t $val
    } else {
      [ns gui]::set_info_message [msgcat::mc "Tabstop value is not an integer"]
    }

  }

  ######################################################################
  # Set the select anchor for visual mode.
  proc set_select_anchor {txtt index} {

    variable select_anchors

    set select_anchors($txtt) $index

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
  # Adjust the current selection if we are in visual mode.
  proc adjust_select {txtt index} {

    variable mode
    variable select_anchors

    # Get the visual type from the mode
    set type [lindex [split $mode($txtt) :] 1]

    # Get the anchor for the given selection
    set anchor [lindex $select_anchors($txtt) $index]

    if {[$txtt compare $anchor < insert]} {
      if {$type eq "char"} {
        $txtt tag add sel $anchor insert
      } else {
        $txtt tag add sel "$anchor linestart" "insert lineend"
      }
    } else {
      if {$type eq "char"} {
        $txtt tag add sel insert $anchor
      } else {
        $txtt tag add sel "insert linestart" "$anchor lineend"
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
    variable modeline
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
    set modeline($txt.t)         1

    # Add bindings
    bind $txt       <<Modified>>            "if {\[[ns vim]::handle_modified %W\]} { break }"
    bind vim$txt    <Escape>                "if {\[[ns vim]::handle_escape %W {$tid}\]} { break }"
    bind vim$txt    <Key>                   "if {\[[ns vim]::handle_any %W {$tid} %K %A\]} { break }"
    bind vim$txt    <Control-Button-1>      "[ns vim]::nil"
    bind vim$txt    <Shift-Button-1>        "[ns vim]::nil"
    bind vim$txt    <Button-1>              "[ns vim]::handle_button1 %W %x %y; break"
    bind vim$txt    <Double-Shift-Button-1> "[ns vim]::nil"
    bind vim$txt    <Double-Button-1>       "[ns vim]::handle_double_button1 %W %x %y; break"
    bind vim$txt    <Triple-Button-1>       "[ns vim]::nil"
    bind vim$txt    <Triple-Shift-Button-1> "[ns vim]::nil"
    bind vim$txt    <B1-Motion>             "[ns vim]::handle_motion %W %x %y; break"
    bind vimpre$txt <Control-f>             "if {\[[ns vim]::handle_control_f %W\]} { break }"
    bind vimpre$txt <Control-b>             "if {\[[ns vim]::handle_control_b %W\]} { break }"
    bind vimpre$txt <Control-g>             "if {\[[ns vim]::handle_control_g %W\]} { break }"
    bind vimpre$txt <Control-j>             "if {\[[ns vim]::handle_control_j %W\]} { break }"
    bind vimpre$txt <Control-k>             "if {\[[ns vim]::handle_control_k %W\]} { break }"

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
  # This is a do-nothing procedure that is called by bindings that would
  # otherwise match other keybindings that we don't want to call.
  proc nil {} {

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
    ::tk::TextSetCursor $W $current

    adjust_insert $W

    focus $W

  }

  ######################################################################
  # Handles a double-left-click event when in Vim mode.
  proc handle_double_button1 {W x y} {

    $W tag remove sel 1.0 end

    set current [$W index @$x,$y]
    ::tk::TextSetCursor $W [$W index "$current wordstart"]

    adjust_insert $W

    $W tag add sel [$W index "$current wordstart"] [$W index "$current wordend"]

    focus $W

  }

  ######################################################################
  # Handle left-button hold motion event when in Vim mode.
  proc handle_motion {W x y} {

    $W tag remove sel 1.0 end

    set current [$W index @$x,$y]
    ::tk::TextSetCursor $W $current

    adjust_insert $W

    # Add the selection
    set anchor [[ns utils]::text_anchor $W]
    if {[$W compare $anchor < $current]} {
      $W tag add sel $anchor $current
    } else {
      $W tag add sel $current $anchor
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
  proc edit_mode {txtt} {

    variable mode

    # Set the mode to the edit mode
    set mode($txtt) "edit"

    # Add separator
    $txtt edit separator

    # Set the blockcursor to false
    $txtt configure -blockcursor false

    # If the current cursor is on a dummy space, remove it
    set tags [$txtt tag names insert]
    if {([lsearch $tags "dspace"] != -1) && ([lsearch $tags "mcursor"] == -1)} {
      $txtt delete insert
    }

  }

  ######################################################################
  # Set the current mode to the "start" mode.
  proc start_mode {txtt} {

    variable mode

    # If we are coming from visual mode, clear the selection
    if {[in_visual_mode $txtt]} {
      $txtt tag remove sel 1.0 end
    }

    # If were in the edit or replace_all state, move the insertion cursor back
    # one character.
    if {(($mode($txtt) eq "edit") || ($mode($txtt) eq "replace_all")) && \
        ([$txtt index insert] ne [$txtt index "insert linestart"])} {
      if {[[ns multicursor]::enabled $txtt]} {
        [ns multicursor]::adjust $txtt -1c
      } else {
        ::tk::TextSetCursor $txtt "insert-1c"
      }
    }

    # Set the blockcursor to true
    $txtt configure -blockcursor true

    # Adjust the insertion marker
    adjust_insert $txtt

    # Add a separator if we were in edit mode
    if {$mode($txtt) ne "start"} {
      $txtt edit separator
    }

    # Set the current mode to the start mode
    set mode($txtt) "start"

  }

  ######################################################################
  # Set the current mode to the "visual" mode.
  proc visual_mode {txtt type} {

    variable mode
    variable select_anchors

    # Set the current mode
    set mode($txtt) "visual:$type"

    # Clear the current selection
    $txtt tag remove sel 1.0 end

    # Initialize the select range
    set select_anchors($txtt) [$txtt index insert]

    # Perform the initial selection
    adjust_select $txtt 0

  }

  ######################################################################
  # Returns true if we are in visual mode.
  proc in_visual_mode {txtt} {

    variable mode

    return [expr {[lindex [split $mode($txtt) :] 0] eq "visual"}]

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
  proc playback {txtt {reg auto}} {

    variable recording

    # Set the record mode to playback
    set recording($reg,mode) "playback"

    # Replay the recording buffer
    foreach event $recording($reg,events) {
      eval "event generate $txtt <$event>"
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
  proc adjust_insert {txtt} {

    variable mode
    variable ignore_modified
    
    # If we are not running in Vim mode, don't continue
    if {![in_vim_mode $txtt]} {
      return
    }

    # Remove any existing dspace characters
    remove_dspace [winfo parent $txtt]

    # If the current line contains nothing, add a dummy space so that the
    # block cursor doesn't look dumb.
    if {[$txtt index "insert linestart"] eq [$txtt index "insert lineend"]} {
      set ignore_modified([winfo parent $txtt]) 1
      $txtt fastinsert insert " " dspace
      ::tk::TextSetCursor $txtt "insert-1c"

    # Make sure that lineend is never the insertion point
    } elseif {[$txtt index insert] eq [$txtt index "insert lineend"]} {
      ::tk::TextSetCursor $txtt "insert-1c"
    }

    # Adjust the selection (if we are in visual mode)
    if {[in_visual_mode $txtt]} {
      adjust_select $txtt 0
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
  proc handle_escape {txtt tid} {

    variable mode
    variable number
    variable recording

    # Add this keysym to the current recording buffer (if one exists)
    set curr_reg $recording(curr_reg)
    if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
      record_add Escape $curr_reg
    }

    if {$mode($txtt) ne "start"} {

      # Add to the recording if we are doing so
      record_add Escape
      record_stop

      # Set the mode to start
      start_mode $txtt

    } else {

      # If were in start mode, clear the auto recording buffer
      record_clear

      # Clear the any selections
      $txtt tag remove sel 1.0 end

      # Clear any searches
      [ns search]::find_clear $tid

    }

    # Clear the current number string
    set number($txtt) ""

    return 1

  }

  ######################################################################
  # Handles any single printable character.
  proc handle_any {txtt tid keysym char} {

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
    if {$mode($txtt) eq "record_reg"} {
      start_mode $txtt
      if {[regexp {^[a-z]$} $keysym]} {
        record_start $keysym
        return 1
      }
    } elseif {$mode($txtt) eq "playback_reg"} {
      start_mode $txtt
      if {[regexp {^[a-z]$} $keysym]} {
        playback $txtt $keysym
        return 1
      } elseif {$keysym eq "at"} {
        if {$recording(curr_reg) ne ""} {
          playback $txtt $recording(curr_reg)
        }
        return 1
      }
    } elseif {($mode($txtt) ne "start") || ($keysym ne "q")} {
      set curr_reg $recording(curr_reg)
      if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
        record_add "Key-$keysym" $curr_reg
      }
    }

    # If the keysym is neither j or k, clear the column
    if {($keysym ne "j") && ($keysym ne "k")} {
      set column($txtt) ""
    }

    # If we are not in edit mode
    if {![catch "handle_$keysym $txtt {$tid}" rc] && $rc} {
      record_add "Key-$keysym"
      if {$mode($txtt) eq "start"} {
        set number($txtt) ""
      }
      return 1

    # If the keysym is a number, handle the number
    } elseif {[string is integer $keysym] && [handle_number $txtt $char]} {
      record_add "Key-$keysym"
      return 1

    # If we are in start, visual, record or format modes, stop character processing
    } elseif {($mode($txtt) eq "start") || \
              ([in_visual_mode $txtt]) || \
              ($mode($txtt) eq "record") || \
              ($mode($txtt) eq "format")} {
      return 1

    # Append the text to the insertion buffer
    } elseif {[string equal -length 7 $mode($txtt) "replace"]} {
      record_add "Key-$keysym"
      if {[[ns multicursor]::enabled $txtt]} {
        [ns multicursor]::replace $txtt $char [ns indent]::check_indent
      } else {
        $txtt replace insert "insert+1c" $char
        $txtt highlight "insert linestart" "insert lineend"
      }
      if {$mode($txtt) eq "replace"} {
        if {[[ns multicursor]::enabled $txtt]} {
          [ns multicursor]::adjust $txtt -1c
        } else {
          ::tk::TextSetCursor $txtt "insert-1c"
        }
        start_mode $txtt
        record_stop
      }
      return 1

    # Remove all text within the current character
    } elseif {$mode($txtt) eq "changein"} {
      record_add "Key-$keysym"
      if {[[ns edit]::delete_between_char $txtt $char]} {
        edit_mode $txtt
      } else {
        start_mode $txtt
      }
      return 1

    # Select all text within the current character
    } elseif {[lindex [split $mode($txtt) :] 0] eq "visualin"} {
      record_add "Key-$keysym"
      if {[[ns edit]::select_between_char $txtt $char]} {
        set mode($txtt) "visual:[lindex [split $mode($txtt) :] 1]"
      } else {
        start_mode $txtt
      }
      return 1

    # Format all text within the current character
    } elseif {$mode($txtt) eq "formatin"} {
      record_add "Key-$keysym"
      [ns edit]::format_between_char $txtt $char
      start_mode $txtt
      return 1

    # Left shift all text within the current character
    } elseif {$mode($txtt) eq "lshiftin"} {
      record_add "Key-$keysym"
      [ns edit]::lshift_between_char $txtt $char
      start_mode $txtt
      return 1

    # Right shift all text within the current character
    } elseif {$mode($txtt) eq "rshiftin"} {
      record_add "Key-$keysym"
      [ns edit]::rshift_between_char $txtt $char
      start_mode $txtt
      return 1

    # If we are not in edit mode, switch to start mode (an illegal command was executed)
    } elseif {$mode($txtt) ne "edit"} {
      start_mode $txtt
      return 1
    }

    # Record the keysym
    record_add "Key-$keysym"

    return 0

  }

  ######################################################################
  # If we are in "start" mode, the number is 0 and the current number
  # is empty, set the insertion cursor to the beginning of the line;
  # otherwise, append the number current to number value.
  proc handle_number {txtt num} {

    variable mode
    variable number

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      if {($mode($txtt) eq "start") && ($num eq "0") && ($number($txtt) eq "")} {
        [ns edit]::move_cursor $txtt linestart
      } else {
        append number($txtt) $num
        record_start
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in the "start" mode, display the command entry field and
  # give it the focus.
  proc handle_colon {txtt tid} {

    variable mode
    variable command_entries

    # If we are in the "start" mode, bring up the command entry widget
    # and give it the focus.
    if {$mode($txtt) eq "start"} {

      # Colorize the entry widget to match the look of the associated text widget
      $command_entries($txtt) configure \
        -background [$txtt cget -background] -foreground [$txtt cget -foreground] \
        -insertbackground [$txtt cget -insertbackground] -font [$txtt cget -font]

      # Show the command entry widget
      grid $command_entries($txtt)

      # Set the focus and grab on the widget
      grab $command_entries($txtt)
      focus $command_entries($txtt)

      return 1

    }

    return 0

  }

  ######################################################################
  # If we are in the "start" mode, move insertion cursor to the end of
  # the current line.  If we are in "delete" mode, delete all of the
  # text from the insertion marker to the end of the line.
  proc handle_dollar {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns edit]::move_cursor $txtt lineend
      ::tk::TextSetCursor $txtt "insert lineend-1c"
      return 1
    } elseif {$mode($txtt) eq "delete"} {
      [ns edit]::delete_to_end $txtt
      start_mode $txtt
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
  proc handle_asciicircum {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      ::tk::TextSetCursor $txtt "insert linestart"
      return 1
    } elseif {$mode($txtt) eq "delete"} {
      [ns edit]::delete_from_start $txtt
      start_mode $txtt
      record_add "Key-asciicircum"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, display the search bar.
  proc handle_slash {txtt tid} {

    variable mode
    variable search_dir

    if {$mode($txtt) eq "start"} {
      [ns gui]::search $tid "next"
      set search_dir($txtt) "next"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, display the search bar for doing a
  # a previous search.
  proc handle_question {txtt tid} {

    variable mode
    variable search_dir

    if {$mode($txtt) eq "start"} {
      [ns gui]::search $tid "prev"
      set search_dir($txtt) "prev"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, invokes the buffered command at the current
  # insertion point.
  proc handle_period {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      set start_index [$txtt index insert]
      playback $txtt
      set end_index [$txtt index insert]
      if {$start_index != $end_index} {
        if {[$txtt compare $start_index < $end_index]} {
          $txtt highlight $start_index $end_index
        } else {
          $txtt highlight $end_index $start_index
        }
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode and the insertion point character has a
  # matching left/right partner, display the partner.
  proc handle_percent {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns gui]::show_match_pair $tid
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles the i-key when in Vim mode.
  proc handle_i {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      edit_mode $txtt
      record_start
      return 1
    } elseif {$mode($txtt) eq "change"} {
      set mode($txtt) "changein"
      return 1
    } elseif {$mode($txtt) eq "format"} {
      set mode($txtt) "formatin"
      return 1
    } elseif {$mode($txtt) eq "lshift"} {
      set mode($txtt) "lshiftin"
      return 1
    } elseif {$mode($txtt) eq "rshift"} {
      set mode($txtt) "rshiftin"
      return 1
    } elseif {[in_visual_mode $txtt]} {
      set mode($txtt) [join [list "visualin" [lindex [split $mode($txtt) :] 1]] :]
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, inserts at the beginning of the current
  # line.
  proc handle_I {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      ::tk::TextSetCursor $txtt "insert linestart"
      edit_mode $txtt
      record_start
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor down one line.
  proc handle_j {txtt tid} {

    variable mode
    variable number
    variable column

    # Move the insertion cursor down one line
    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      $txtt tag remove sel 1.0 end
      lassign [split [$txtt index insert] .] row col
      if {$column($txtt) ne ""} {
        set col $column($txtt)
      } else {
        set column($txtt) $col
      }
      set rows [expr {($number($txtt) ne "") ? $number($txtt) : 1}]
      set row  [lindex [split [$txtt index "$row.0+$rows display lines"] .] 0]
      if {[$txtt compare "$row.$col" < end]} {
        ::tk::TextSetCursor $txtt "$row.$col"
        adjust_insert $txtt
      }
      return 1
    } elseif {$mode($txtt) eq "folding"} {
      [ns folding]::jump_to [winfo parent $txtt] next
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, join the next line to the end of the
  # previous line.
  proc handle_J {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      if {[[ns multicursor]::enabled $txtt]} {
        [ns edit]::move_cursors $txtt "+1l"
      } else {
        [ns edit]::transform_join_lines $txtt $number($txtt)
        record "Key-J"
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor up one line.
  proc handle_k {txtt tid} {

    variable mode
    variable number
    variable column

    # Move the insertion cursor up one line
    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      $txtt tag remove sel 1.0 end
      lassign [split [$txtt index insert] .] row col
      if {$column($txtt) ne ""} {
        set col $column($txtt)
      } else {
        set column($txtt) $col
      }
      set rows [expr {($number($txtt) ne "") ? $number($txtt) : 1}]
      set row  [lindex [split [$txtt index "$row.0-$rows display lines"] .] 0]
      if {$row >= 1} {
        ::tk::TextSetCursor $txtt "$row.$col"
        adjust_insert $txtt
      }
      return 1
    } elseif {$mode($txtt) eq "folding"} {
      [ns folding]::jump_to [winfo parent $txtt] prev
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in start mode and multicursor is enabled, move all of the
  # cursors up one line.
  proc handle_K {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      if {[[ns multicursor]::enabled $txtt]} {
        [ns edit]::move_cursors $txtt "-1l"
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor right one
  # character.
  proc handle_l {txtt tid} {

    variable mode
    variable number

    # Move the insertion cursor right one character
    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      $txtt tag remove sel 1.0 end
      if {$number($txtt) ne ""} {
        if {[$txtt compare "insert lineend" < "insert+$number($txtt)c"]} {
          ::tk::TextSetCursor $txtt "insert lineend"
        } else {
          ::tk::TextSetCursor $txtt "insert+$number($txtt)c"
        }
        adjust_insert $txtt
      } elseif {[$txtt compare "insert lineend" > "insert+1c"]} {
        ::tk::TextSetCursor $txtt "insert+1c"
        adjust_insert $txtt
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
  proc handle_L {txtt tid} {

    variable mode
    variable number

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      if {[[ns multicursor]::enabled $txtt]} {
        [ns edit]::move_cursors $txtt "+1c"
      } elseif {$mode($txtt) eq "start"} {
        [ns edit]::move_cursor $txtt screenbot $number($txtt)
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # Returns the string containing the filename to open.
  proc get_filename {txtt pos} {

    # Get the index of pos
    set index [lindex [split [$txtt index $pos] .] 1]

    # Get the current line
    set line [$txtt get "$pos linestart" "$pos lineend"]

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
  proc handle_f {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      return 1
    } elseif {$mode($txtt) eq "goto"} {
      if {[[ns multicursor]::enabled $txtt]} {
        foreach {startpos endpos} [$txtt tag ranges mcursor] {
          if {[file exists [set fname [get_filename $txtt $startpos]]]} {
            [ns gui]::add_file end $fname
          }
        }
      } else {
        if {[file exists [set fname [get_filename $txtt insert]]]} {
          [ns gui]::add_file end $fname
        }
      }
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, edit any filenames found under any of
  # the cursors.
  proc handle_g {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "goto"
      return 1
    } elseif {$mode($txtt) eq "goto"} {
      ::tk::TextSetCursor $txtt 1.0
      adjust_insert $txtt
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor left one
  # character.
  proc handle_h {txtt tid} {

    variable mode
    variable number

    # Move the insertion cursor left one character
    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      $txtt tag remove sel 1.0 end
      if {$number($txtt) ne ""} {
        if {[$txtt compare "insert linestart" > "insert-$number($txtt)c"]} {
          ::tk::TextSetCursor $txtt "insert linestart"
        } else {
          ::tk::TextSetCursor $txtt "insert-$number($txtt)c"
        }
        adjust_insert $txtt
      } elseif {[$txtt compare "insert linestart" <= "insert-1c"]} {
        ::tk::TextSetCursor $txtt "insert-1c"
        adjust_insert $txtt
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
  proc handle_H {txtt tid} {

    variable mode
    variable number

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      if {[[ns multicursor]::enabled $txtt]} {
        [ns edit]::move_cursors $txtt "-1c"
      } else {
        [ns edit]::move_cursor $txtt screentop $number($txtt)
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the insertion cursor to the beginning
  # of previous word.
  proc handle_b {txtt tid} {

    variable mode
    variable number

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      [ns edit]::move_cursor $txtt prevword $number($txtt)
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, change the state to "change" mode.  If
  # we are in the "change" mode, delete the current line and put ourselves
  # into edit mode.
  proc handle_c {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "change"
      record_start
      return 1
    } elseif {[in_visual_mode $txtt]} {
      if {![[ns multicursor]::delete $txtt "selected"]} {
        $txtt delete sel.first sel.last
      }
      edit_mode $txtt
      return 1
    } elseif {$mode($txtt) eq "change"} {
      if {![[ns multicursor]::delete $txtt "line"]} {
        $txtt delete "insert linestart" "insert lineend"
      }
      edit_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, delete from the insertion cursor to the
  # end of the line and put ourselves into "edit" mode.
  proc handle_C {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      $txtt delete insert "insert lineend"
      edit_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "change" mode, delete the current word and change to edit
  # mode.
  proc handle_w {txtt tid} {

    variable mode
    variable number

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      [ns edit]::move_cursor $txtt nextword $number($txtt)
      return 1
    } elseif {$mode($txtt) eq "change"} {
      if {($number($txtt) ne "") && ($number($txtt) > 1)} {
        if {![[ns multicursor]::delete $txtt "word" $number($txtt)]} {
          $txtt delete insert "[[ns edit]::get_word $txtt next [expr $number($txtt) - 1]] wordend"
        }
      } else {
        if {![[ns multicursor]::delete $txtt " wordend"]} {
          $txtt delete insert "insert wordend"
        }
      }
      edit_mode $txtt
      return 1
    } elseif {$mode($txtt) eq "yank"} {
      clipboard clear
      if {$number($txtt) ne ""} {
        clipboard append [$txtt get "insert wordstart" "[[ns edit]::get_word $txtt next [expr $number($txtt) - 1]] wordend"]
      } else {
        clipboard append [$txtt get "insert wordstart" "insert wordend"]
      }
      start_mode $txtt
      return 1
    } elseif {$mode($txtt) eq "delete"} {
      [ns edit]::delete_current_word $txtt $number($txtt)
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, go to the last line.
  proc handle_G {txtt tid} {

    variable mode
    variable number

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      [ns edit]::move_cursor $txtt last $number($txtt)
      return 1
    } elseif {$mode($txtt) eq "format"} {
      [ns indent]::format_text $txtt "insert linestart" end
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, transition the mode to the delete mode.
  # If we are in the "delete" mode, delete the current line.
  proc handle_d {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "delete"
      record_start
      $txtt edit separator
      return 1
    } elseif {$mode($txtt) eq "delete"} {
      [ns edit]::delete_current_line $txtt $number($txtt)
      start_mode $txtt
      record_add "Key-d"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, deletes all text from the current
  # insertion cursor to the end of the line.
  proc handle_D {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns edit]::delete_to_end $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in the "start" mode, move the insertion cursor ahead by
  # one character and set ourselves into "edit" mode.
  proc handle_a {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      if {[[ns multicursor]::enabled $txtt]} {
        [ns multicursor]::adjust $txtt "+1c" 1 dspace
      }
      cleanup_dspace $txtt
      ::tk::TextSetCursor $txtt "insert+1c"
      edit_mode $txtt
      record_start
      return 1
    } elseif {$mode($txtt) eq "folding"} {
      [ns folding]::toggle_fold [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, insert text at the end of the current line.
  proc handle_A {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      ::tk::TextSetCursor $txtt "insert lineend"
      edit_mode $txtt
      record_start
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in the "start" mode, set ourselves to yank mode.  If we
  # are in "yank" mode, copy the current line to the clipboard.
  proc handle_y {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "yank"
      return 1
    } elseif {[in_visual_mode $txtt]} {
      clipboard clear
      clipboard append [$txtt get sel.first sel.last]
      cliphist::add_from_clipboard
      start_mode $txtt
      return 1
    } elseif {$mode($txtt) eq "yank"} {
      clipboard clear
      if {($number($txtt) ne "") && ($number($txtt) > 1)} {
        clipboard append [$txtt get "insert linestart" "insert linestart+[expr $number($txtt) - 1]l lineend"]\n
        multicursor::copy $txtt "insert linestart" "insert linestart+[expr $number($txtt) - 1]l lineend"
      } else {
        clipboard append [$txtt get "insert linestart" "insert lineend"]\n
        multicursor::copy $txtt "insert linestart" "insert lineend"
      }
      cliphist::add_from_clipboard
      start_mode $txtt
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
  proc do_post_paste {txtt clip} {

    variable number

    # Create a separator
    $txtt edit separator

    # Get the number of pastes that we need to perform
    set num [expr {($number($txtt) ne "") ? $number($txtt) : 1}]

    if {[set nl_index [string last \n $clip]] != -1} {
      if {[expr ([string length $clip] - 1) == $nl_index]} {
        set clip [string replace $clip $nl_index $nl_index]
      }
      $txtt insert "insert lineend" [string repeat "\n$clip" $num]
      multicursor::paste $txtt "insert+${num}l linestart"
      ::tk::TextSetCursor $txtt "insert+${num}l linestart"
    } else {
      set clip [string repeat $clip $num]
      $txtt insert "insert+1c" $clip
      multicursor::paste $txtt "insert+1c"
      ::tk::TextSetCursor $txtt "insert+[string length $clip]c"
    }
    adjust_insert $txtt

    # Create a separator
    $txtt edit separator

  }

  ######################################################################
  # If we are in the "start" mode, put the contents of the clipboard
  # after the current line.
  proc handle_p {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      do_post_paste $txtt [set clip [clipboard get]]
      cliphist::add_from_clipboard
      record "Key-p"
      return 1
    }

    return 0

  }

  ######################################################################
  # Pastes the contents of the given clip prior to the current line
  # in the text widget.
  proc do_pre_paste {txtt clip} {

    variable number

    $txtt edit separator

    # Calculate the number of clips to pre-paste
    set num [expr {($number($txtt) ne "") ? $number($txtt) : 1}]

    if {[set nl_index [string last \n $clip]] != -1} {
      if {[expr ([string length $clip] - 1) == $nl_index]} {
        set clip [string replace $clip $nl_index $nl_index]
      }
      $txtt insert "insert linestart" [string repeat "$clip\n" $num]
      multicursor::paste $txtt "insert linestart"
    } else {
      $txtt insert "insert-1c" [string repeat $clip $num]
      multicursor::paste $txtt "insert-1c"
    }
    adjust_insert $txtt

    # Create separator
    $txtt edit separator

  }

  ######################################################################
  # If we are in the "start" mode, put the contents of the clipboard
  # before the current line.
  proc handle_P {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      do_pre_paste $txtt [set clip [clipboard get]]
      cliphist::add_from_clipboard
      record "Key-P"
      return 1
    }

    return 0

  }

  ######################################################################
  # Performs an undo operation.
  proc undo {txtt} {

    # Perform the undo operation
    $txtt edit undo

    # Adjusts the insertion cursor
    adjust_insert $txtt

  }

  ######################################################################
  # Performs a redo operation.
  proc redo {txtt} {

    # Performs the redo operation
    $txtt edit redo

    # Adjusts the insertion cursor
    adjust_insert $txtt

  }

  ######################################################################
  # If we are in "start" mode, undoes the last operation.
  proc handle_u {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      undo $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Performs a single character delete.
  proc do_char_delete_current {txtt number} {

    # Create separator
    $txtt edit separator

    if {$number ne ""} {
      if {[[ns multicursor]::enabled $txtt]} {
        [ns multicursor]::delete $txtt "+${number}c"
      } elseif {[$txtt compare "insert+${number}c" > "insert lineend"]} {
        $txtt delete insert "insert lineend"
        if {[$txtt index insert] eq [$txtt index "insert linestart"]} {
          $txtt insert insert " "
        }
        ::tk::TextSetCursor $txtt "insert-1c"
      } else {
        $txtt delete insert "insert+${number}c"
      }
    } elseif {[[ns multicursor]::enabled $txtt]} {
      [ns multicursor]::delete $txtt "+1c"
    } else {
      $txtt delete insert
      if {[$txtt index insert] eq [$txtt index "insert lineend"]} {
        if {[$txtt index insert] eq [$txtt index "insert linestart"]} {
          $txtt insert insert " "
        }
        ::tk::TextSetCursor $txtt "insert-1c"
      }
    }

    # Adjust the cursor
    adjust_cursor $txtt

    # Create separator
    $txtt edit separator

  }

  ######################################################################
  # Performs a single character delete.
  proc do_char_delete_previous {txtt number} {

    # Create separator
    $txtt edit separator

    if {$number ne ""} {
      if {[[ns multicursor]::enabled $txtt]} {
        [ns multicursor]::delete $txtt "-${number}c"
      } elseif {[$txtt compare "insert-${number}c" < "insert linestart"]} {
        $txtt delete "insert linestart" insert
      } else {
        $txtt delete "insert-${number}c" insert
      }
    } elseif {[[ns multicursor]::enabled $txtt]} {
      [ns multicursor]::delete $txtt "-1c"
    } elseif {[$txtt compare "insert-1c" >= "insert linestart"] && ([$txtt index insert] ne "1.0")} {
      $txtt delete "insert-1c"
    }

    # Adjust the cursor
    adjust_cursor $txtt

    # Create separator
    $txtt edit separator

  }

  ######################################################################
  # If we are in "start" mode, deletes the current character.
  proc handle_x {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      do_char_delete_current $txtt $number($txtt)
      record_add "Key-x"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, deletes the current character (same as
  # the 'x' command).
  proc handle_Delete {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      do_char_delete_current $txtt $number($txtt)
      record_add "Key-Delete"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, deletes the previous character.
  proc handle_X {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      do_char_delete_previous $txtt $number($txtt)
      record_add "Key-X"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, add a new line below the current line
  # and transition into "edit" mode.
  proc handle_o {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      [ns edit]::insert_line_below_current $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, add a new line above the current line
  # and transition into "edit" mode.
  proc handle_O {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns edit]::insert_line_above_current $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, set the mode to the "quit" mode.  If we
  # are in "quit" mode, save and exit the current tab.
  proc handle_Z {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "quit"
      return 1
    } elseif {$mode($txtt) eq "quit"} {
      [ns gui]::save_current $tid 0
      [ns gui]::close_current $tid
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, finds the next occurrence of the search text.
  proc handle_n {txtt tid} {

    variable mode
    variable search_dir
    variable number

    if {$mode($txtt) eq "start"} {
      set count [expr {($number($txtt) ne "") ? $number($txtt) : 1}]
      if {$search_dir($txtt) eq "next"} {
        for {set i 0} {$i < $count} {incr i} {
          [ns search]::find_next [winfo parent $txtt] 0
        }
      } else {
        for {set i 0} {$i < $count} {incr i} {
          [ns search]::find_prev [winfo parent $txtt] 0
        }
      }
      return 1
    } elseif {$mode($txtt) eq "delete"} {
      [ns edit]::delete_current_number $txtt
      start_mode $txtt
      record_add "Key-n"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, finds the previous occurrence of the
  # search text.
  proc handle_N {txtt tid} {

    variable mode
    variable search_dir
    variable number

    if {$mode($txtt) eq "start"} {
      set count [expr {($number($txtt) ne "") ? $number($txtt) : 1}]
      if {$search_dir($txtt) eq "next"} {
        for {set i 0} {$i < $count} {incr i} {
          [ns search]::find_prev [winfo parent $txtt] 0
        }
      } else {
        for {set i 0} {$i < $count} {incr i} {
          [ns search]::find_next [winfo parent $txtt] 0
        }
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, replaces the current character with the
  # next character.
  proc handle_r {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "replace"
      record_start
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, replaces all characters until the escape
  # key is hit.
  proc handle_R {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "replace_all"
      record_start
      return 1
    } elseif {$mode($txtt) eq "folding"} {
      [ns folding]::open_all_folds [winfo parent $txtt]
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, puts the mode into "visual char" mode.
  proc handle_v {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      visual_mode $txtt char
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, puts the mode into "visual line" mode.
  proc handle_V {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      visual_mode $txtt line
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the cursor down by 1 page.
  proc handle_control_f {txtt} {

    variable mode

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      [ns edit]::move_cursor_by_page $txtt next
      record "Control-f"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the cursor up by 1 page.
  proc handle_control_b {txtt} {

    variable mode

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      [ns edit]::move_cursor_by_page $txtt prior
      record "Control-b"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, display the current text counts.
  proc handle_control_g {txtt} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns gui]::display_file_counts $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the current line or selection down one line.
  proc handle_control_j {txtt} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns edit]::transform_bubble_down $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the current line or selection up one line.
  proc handle_control_k {txtt} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns edit]::transform_bubble_up $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, add a cursor.
  proc handle_s {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns multicursor]::add_cursor $txtt [$txtt index insert]
      return 1
    } elseif {$mode($txtt) eq "delete"} {
      [ns edit]::delete_next_space $txtt
      start_mode $txtt
      record_add "Key-s"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, add cursors between the current anchor
  # the current line.
  proc handle_S {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns multicursor]::add_cursors $txtt [$txtt index insert]
      return 1
    } elseif {$mode($txtt) eq "delete"} {
      [ns edit]::delete_prev_space $txtt
      start_mode $txtt
      record_add "Key-S"
      record_stop
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, run the gui::insert_numbers procedure to
  # allow the user to potentially insert incrementing numbers into the
  # specified text widget.
  proc handle_numbersign {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      [ns gui]::insert_numbers $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Moves the specified bracket one word to the right.
  proc move_bracket_right {txtt tid char} {

    if {[set index [$txtt search -forwards -- $char insert]] ne ""} {
      $txtt delete $index
      $txtt insert "$index wordend" $char
    }

  }

  ######################################################################
  # Inserts or moves the specified bracket pair.
  proc place_bracket {txtt tid left {right ""}} {

    variable mode

    # Get the current selection
    if {[llength [set selected [$txtt tag ranges sel]]] > 0} {

      foreach {end start} [lreverse $selected] {
        $txtt insert $end [expr {($right eq "") ? $left : $right}]
        $txtt insert $start $left
      }

    } else {

      # Add the bracket in the appropriate place
      if {($left eq "\"") || ($left eq "'")} {
        set tag [expr {($left eq "'") ? "_sString" : "_dString"}]
        if {[lsearch [$txtt tag names insert] $tag] != -1} {
          move_bracket_right $txtt $tid $left
        } else {
          $txtt insert "insert wordend"   $left
          $txtt insert "insert wordstart" $left
        }
      } else {
        set re "(\\$left|\\$right)"
        if {([set index [$txtt search -backwards -regexp -- $re insert]] ne "") && ([$txtt get $index] eq $left)} {
          move_bracket_right $txtt $tid $right
        } else {
          $txtt insert "insert wordend"   $right
          $txtt insert "insert wordstart" $left
        }
      }

    }

    # Put ourselves back into start mode
    start_mode $txtt

  }

  ######################################################################
  # If any text is selected, double quotes are placed around all
  # selections.  If the insertion cursor is within a completed
  # string, the right-most quote of the completed string is moved one
  # word to the end; otherwise, the current word is placed within
  # double-quotes.
  proc handle_quotedbl {txtt tid} {

    variable mode

    if {$mode($txtt) eq "change"} {
      place_bracket $txtt $tid \"
      return 1
    }

    return 0

  }

  ######################################################################
  # If any text is selected, single quotes are placed around all
  # selections.  If the insertion cursor is within a completed
  # single string, the right-most quote of the completed string is moved one
  # word to the end; otherwise, the current word is placed within
  # single-quotes.
  proc handle_apostrophe {txtt tid} {

    variable mode

    if {$mode($txtt) eq "change"} {
      place_bracket $txtt $tid '
      return 1
    }

    return 0

  }

  ######################################################################
  # If any text is selected, curly brackets are placed around all
  # selections.  If the insertion cursor is within a completed
  # bracket sequence, the right-most bracket of the sequence is moved one
  # word to the end; otherwise, the current word is placed within
  # curly brackets.
  proc handle_bracketleft {txtt tid} {

    variable mode

    if {$mode($txtt) eq "change"} {
      place_bracket $txtt $tid \[ \]
      return 1
    }

    return 0

  }

  ######################################################################
  # If any text is selected, square brackets are placed around all
  # selections.  If the insertion cursor is within a completed
  # bracket sequence, the right-most bracket of the sequence is moved one
  # word to the end; otherwise, the current word is placed within
  # square brackets.
  proc handle_braceleft {txtt tid} {

    variable mode

    if {$mode($txtt) eq "change"} {
      place_bracket $txtt $tid \{ \}
      return 1
    }

    return 0

  }

  ######################################################################
  # If any text is selected, parenthesis are placed around all
  # selections.  If the insertion cursor is within a completed
  # parenthetical sequence, the right-most parenthesis of the sequence
  # is moved one word to the end; otherwise, the current word is placed
  # within parenthesis.
  proc handle_parenleft {txtt tid} {

    variable mode

    if {$mode($txtt) eq "change"} {
      place_bracket $txtt $tid ( )
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in start mode, begin a lshift mode.  If we are in
  # lshift mode, shift the current line left by one indent.  If we
  # are in change mode:
  #
  # If any text is selected, angled brackets are placed around all
  # selections.  If the insertion cursor is within a completed
  # bracket sequence, the right-most bracket of the sequence is moved one
  # word to the end; otherwise, the current word is placed within
  # angled brackets.
  proc handle_less {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "lshift"
      return 1
    } elseif {$mode($txtt) eq "lshift"} {
      set lines [expr {($number($txtt) eq "") ? 0 : ($number($txtt) - 1)}]
      [ns edit]::unindent $txtt insert "insert+${lines}l"
      start_mode $txtt
      return 1
    } elseif {$mode($txtt) eq "change"} {
      place_bracket $txtt $tid < >
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in start mode, begin a rshift mode.  If we are in
  # rshift mode, shift the current line right by one indent.
  proc handle_greater {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "rshift"
      return 1
    } elseif {$mode($txtt) eq "rshift"} {
      set lines [expr {($number($txtt) eq "") ? 0 : ($number($txtt) - 1)}]
      [ns edit]::indent $txtt insert "insert+${lines}l"
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # When in start mode, if any text is selected, the selected code is
  # formatted; otherwise, if we are in start mode, we are transitioned to
  # format mode.  If we are in format mode, we format the currently selected
  # line only.
  proc handle_equal {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      if {[llength [set selected [$txtt tag ranges sel]]] > 0} {
        foreach {endpos startpos} [lreverse $selected] {
          [ns indent]::format_text $txtt $startpos $endpos
        }
      } else {
        set mode($txtt) "format"
      }
      return 1
    } elseif {$mode($txtt) eq "format"} {
      [ns indent]::format_text $txtt "insert linestart" "insert lineend"
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" or "visual" mode, moves the insertion cursor to the first
  # non-whitespace character in the next line.
  proc handle_Return {txtt tid} {

    variable mode

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      ::tk::TextSetCursor $txtt "insert+1l linestart"
      if {[string is space [$txtt get insert]]} {
        set next_word [[ns edit]::get_word $txtt next]
        if {[$txtt compare $next_word < "insert lineend"]} {
          ::tk::TextSetCursor $txtt $next_word
        } else {
          ::tk::TextSetCursor $txtt "insert lineend"
        }
      }
      adjust_insert $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" or "visual" mode, moves the insertion cursor to the first
  # non-whitespace character in the previous line.
  proc handle_minus {txtt tid} {

    variable mode

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      ::tk::TextSetCursor $txtt "insert-1l linestart"
      if {[string is space [$txtt get insert]]} {
        set next_word [[ns edit]::get_word $txtt next]
        if {[$txtt compare $next_word < "insert lineend"]} {
          ::tk::TextSetCursor $txtt $next_word
        } else {
          ::tk::TextSetCursor $txtt "insert lineend"
        }
      }
      adjust_insert $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" or "visual" mode, move the cursor to the given
  # column of the current line.
  proc handle_bar {txtt tid} {

    variable mode
    variable number

    if {(($mode($txtt) eq "start") || [in_visual_mode $txtt]) && ($number($txtt) ne "")} {
      ::tk::TextSetCursor $txtt [lindex [split [$txtt index insert] .] 0].$number($txtt)
      adjust_insert $txtt
      $txtt see insert
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, change the case of the current character.
  proc handle_asciitilde {txtt tid} {

    variable mode
    variable number

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      [ns edit]::transform_toggle_case $txtt $number($txtt)
      adjust_insert $txtt
      if {[in_visual_mode $txtt]} {
        start_mode $txtt
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, move the cursor to the start of the middle
  # line.
  proc handle_M {txtt tid} {

    variable mode
    variable number

    if {($mode($txtt) eq "start") || [in_visual_mode $txtt]} {
      [ns edit]::move_cursor $txtt screenmid $number($txtt)
      return 1
    } elseif {$mode($txtt) eq "folding"} {
      [ns folding]::close_all_folds [winfo parent $txtt]
      start_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, search for all occurences of the current
  # word.
  proc handle_asterisk {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      set word [$txtt get "insert wordstart" "insert wordend"]
      catch { ctext::deleteHighlightClass [winfo parent $txtt] search }
      ctext::addSearchClass [winfo parent $txtt] search black yellow "" $word
      $txtt tag lower _search sel
      [ns search]::find_next [winfo parent $txtt] 0
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, sets the current mode to "record" mode.
  proc handle_q {txtt tid} {

    variable mode
    variable recording

    if {$mode($txtt) eq "start"} {
      set curr_reg $recording(curr_reg)
      if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
        record_stop $curr_reg
      } else {
        set mode($txtt) "record_reg"
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in start mode, do nothing.  If we are in quit mode, close
  # the current tab without writing the file (same as :q!).
  proc handle_Q {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      return 1
    } elseif {$mode($txtt) eq "quit"} {
      [ns gui]::close_current $tid 1
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, replays the register specified with the
  # next character.  If we are in "replay_reg" mode, playback the current
  # register again.
  proc handle_at {txtt tid} {

    variable mode
    variable recording

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "playback_reg"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, increments the insertion cursor by number
  # characters.
  proc handle_space {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      set chars [expr {($number($txtt) eq "") ? 1 : $number($txtt)}]
      ::tk::TextSetCursor $txtt "insert+$chars display char"
      if {[$txtt index insert] eq [$txtt index "insert lineend"]} {
        ::tk::TextSetCursor $txtt "insert+1 display char"
      } else {
        adjust_insert $txtt
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "start" mode, decrements the insertion cursor by number
  # characters.
  proc handle_BackSpace {txtt tid} {

    variable mode
    variable number

    if {$mode($txtt) eq "start"} {
      set chars [expr {($number($txtt) eq "") ? 1 : $number($txtt)}]
      ::tk::TextSetCursor $txtt "insert-$chars display char"
      adjust_insert $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in start mode, transition to the folding mode.
  proc handle_z {txtt tid} {

    variable mode

    if {$mode($txtt) eq "start"} {
      set mode($txtt) "folding"
      return 1
    }

    return 0

  }

}
