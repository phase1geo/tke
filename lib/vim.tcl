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
# Name:    vim.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    05/21/2013
# Brief:   Namespace containing special bindings to provide Vim-like
#          support.  The Vim commands supported are not meant to be
#          a complete representation of its functionality.
######################################################################

namespace eval vim {

  variable modelines
  variable seltype   "inclusive"

  array set command_entries {}
  array set mode            {}
  array set search_dir      {}
  array set column          {}
  array set select_anchors  {}
  array set modeline        {}
  array set multicursor     {}

  array set multiplier      {}
  array set operator        {}
  array set motion          {}
  array set number          {}

  array set recording {
    curr_reg ""
  }

  foreach reg [list a b c d e f g h i j k l m n o p q r s t u v w x y z auto] {
    set recording($reg,mode)   "none"
    set recording($reg,events) [list]
  }

  trace variable preferences::prefs(Editor/VimModelines) w [list vim::handle_vim_modelines]

  ######################################################################
  # Handles any value changes to the Editor/VimModlines preference value.
  proc handle_vim_modelines {name1 name2 op} {

    variable modelines

    set modelines [preferences::get Editor/VimModelines]

  }

  ######################################################################
  # Enables/disables Vim mode for all text widgets.
  proc set_vim_mode_all {} {

    variable command_entries

    # Set the Vim mode on all text widgets
    foreach txtt [array names command_entries] {
      set_vim_mode [winfo parent $txtt]
    }

  }

  ######################################################################
  # Enables/disables Vim mode for the specified text widget.
  proc set_vim_mode {txt} {

    if {[preferences::get Editor/VimMode]} {
      add_bindings $txt
    } else {
      remove_bindings $txt
    }

    # Update the position information in the status bar
    gui::update_position $txt

  }

  ######################################################################
  # Returns true if we are currently in multi-cursor move mode.
  proc in_multimove {txtt} {

    variable multicursor

    return [expr {[in_vim_mode $txtt] && (([get_edit_mode $txtt] ne "") || $multicursor($txtt))}]

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

    if {[preferences::get Editor/VimMode] && \
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
    variable multicursor

    if {[preferences::get Editor/VimMode]} {
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
          default       {
            if {[info exists multicursor($txt.t)] && $multicursor($txt.t)} {
              return "MULTIMOVE MODE"
            } else {
              return "COMMAND MODE$record"
            }
          }
        }
      }
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

    if {$modelines && (![info exists modeline($txt.t)] || $modeline($txt.t))} {

      foreach {startline endline} [list 1.0 "1.0+${modelines}l linestart" "end-${modelines}l linestart" end] {
        foreach line [split [$txt get $startline $endline] \n] {
          if {[regexp {(^|\s)(vi|vim|vim\d+|vim<\d+|vim>\d+|vim=\d+|ex):\s*(set?\s+(.*):.*|(.*)$)} $line -> dummy0 dummy1 dummy2 opts1 opts2]} {
            set opts [expr {(([string range $dummy2 0 2] eq "se ") || ([string range $dummy2 0 3] eq "set ")) ? $opts1 : $opts2}]
            set opts [string map {"\\:" {:} ":" { }} $opts]
            foreach opt $opts {
              if {[regexp {(\S+?)(([+-])?=(\S+))?$} $opt -> key dummy mod val]} {
                do_set_command $txt $key $val $mod 1
              }
            }
            return
          }
        }
      }

    }

  }

  ######################################################################
  # Binds the given entry
  proc bind_command_entry {txt entry} {

    variable command_entries

    # Save the entry
    set command_entries($txt.t) $entry

    bind $entry <Return>    [list vim::handle_command_return %W]
    bind $entry <Escape>    [list vim::handle_command_escape %W]
    bind $entry <BackSpace> [list vim::handle_command_backspace %W]

  }

  ######################################################################
  # Handles the command entry text.
  proc handle_command_return {w} {

    # Get the last txt widget that had the focus
    set txt [gui::last_txt_focus]

    # Get the value from the command field
    set value [$w get]

    # Delete the value in the command entry
    $w delete 0 end

    # Execute the command
    switch -- $value {
      w   { gui::save_current }
      w!  { gui::save_current -force 1 }
      wq  { if {[gui::save_current]} { gui::close_current; set txt "" } }
      wq! { if {[gui::save_current -force 1]} { gui::close_current; set txt "" } }
      q   { gui::close_current; set txt "" }
      q!  { gui::close_current -force 1; set txt "" }
      cq  { gui::close_all -force 1 -exiting 1; menus::exit_command }
      e!  { gui::update_current }
      n   { gui::next_tab }
      N   { gui::previous_tab }
      p   { after idle gui::next_pane }
      e\# { gui::last_tab }
      m   { gui::remove_current_marker }
      default {
        catch {

          # Perform search and replace
          if {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)s/(.*)/(.*)/([giI]*)$} $value -> from to search replace opts]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend-1c"]
            search::replace_do_raw $from $to $search $replace \
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
            edit::jump_to_line $txt.t [get_linenum $txt $value]

          # Add multicursors to a range of lines
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)c/(.*)/$} $value -> from to search]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend"]
            multicursor::search_and_add_cursors $txt $from $to $search

          # Handle code fold opening in range
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)foldo(pen)?(!?)$} $value -> from to dummy full_depth]} {
            set from [lindex [split [get_linenum $txt $from] .] 0]
            set to   [lindex [split [get_linenum $txt $to] .] 0]
            folding::open_folds_in_range $txt $from $to [expr {$full_depth ne ""}]

          # Handle code fold closing in range
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)foldc(lose)?(!?)$} $value -> from to dummy full_depth]} {
            set from [lindex [split [get_linenum $txt $from] .] 0]
            set to   [lindex [split [get_linenum $txt $to] .] 0]
            folding::close_folds_in_range $txt $from $to [expr {$full_depth ne ""}]

          # Handling code folding
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)fo(ld)?$} $value -> from to]} {
            set from [lindex [split [get_linenum $txt $from] .] 0]
            set to   [lindex [split [get_linenum $txt $to] .] 0]
            folding::close_range $txt $from $to

          # Save/quit a subset of lines as a filename
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)w(q)?(!)?\s+(.*)$} $value -> from to and_close overwrite fname]} {
            set from [$txt index "[get_linenum $txt $from] linestart"]
            set to   [$txt index "[get_linenum $txt $to] lineend"]
            if {[edit::save_selection $txt $from $to [expr {$overwrite eq "!"}] $fname]} {
              if {$and_close ne ""} {
                gui::close_current
                set txt ""
              }
            }

          # Open a new file
          } elseif {[regexp {^e\s+(.*)$} $value -> filename]} {
            set filename [normalize_filename [utils::perform_substitutions $filename]]
            if {[file exists $filename]} {
              gui::add_file end $filename
            } else {
              gui::add_new_file end -name $filename
            }

          # Save/quit the entire file with a new name
          } elseif {[regexp {^w(q)?(!)?\s+(.*)$} $value -> and_close and_force filename]} {
            if {![file exists [file dirname [set filename [normalize_filename [utils::perform_substitutions $filename]]]]]} {
              gui::set_error_message [msgcat::mc "Unable to write"] [msgcat::mc "Filename directory does not exist"]
            } else {
              gui::save_current -force [expr {$and_force ne ""}] -save_as [normalize_filename [utils::perform_substitutions $filename]]
              if {$and_close ne ""} {
                gui::close_current -force [expr {($and_close eq "q") ? 0 : 1}]
                set txt ""
              }
            }

          # Create/delete a marker for the current line
          } elseif {[regexp {^m\s+(.*)$} $value -> marker]} {
            set line [lindex [split [$txt index insert] .] 0]
            if {$marker ne ""} {
              if {[set tag [ctext::linemapSetMark $txt $line]] ne ""} {
                markers::add $txt $tag $marker
              }
            } else {
              markers::delete_by_line $txt $line
              ctext::linemapClearMark $txt $line
            }

          # Insert the contents of a file after the current line
          } elseif {[regexp {^r\s+(.*)$} $value -> filename]} {
            if {[string index $filename 0] eq "!"} {
              edit::insert_file $txt "|[utils::perform_substitutions [string range $filename 1 end]]"
            } else {
              edit::insert_file $txt [normalize_filename [utils::perform_substitutions $filename]]
            }

          # Change the working directory
          } elseif {[regexp {^cd\s+(.*)$} $value -> directory]} {
            if {[file isdirectory [utils::perform_substitutions $directory]]} {
              gui::change_working_directory $directory
            }

          # Handle set commands
          } elseif {[regexp {^set?\s+(.*)$} $value -> opts]} {
            foreach opt [split $opts ": "] {
              if {[regexp {(\S+?)(([+-])?=(\S+))?$} $opt -> key dummy mod val]} {
                set txt [do_set_command $txt $key $val $mod]
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
      gui::set_txt_focus $txt

      # Hide the command entry widget
      gui::panel_forget $w

    }

  }

  ######################################################################
  # Handles set command calls and modeline settings.
  proc do_set_command {txt opt val mod {ml 0}} {

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
      ai               { do_set_indent_mode IND 1 }
      noautoindent     -
      noai             { do_set_indent_mode IND 0 }
      browsedir        -
      bsdir            { do_set_browse_dir $val }
      expandtab        -
      et               { do_set_expandtab 1 }
      noexpandtab      -
      noet             { do_set_expandtab 0 }
      fileformat       -
      ff               { do_set_fileformat $val }
      foldenable       -
      fen              { do_set_foldenable 1 }
      nofoldenable     -
      nofen            { do_set_foldenable 0 }
      foldmethod       -
      fdm              { do_set_foldmethod $val }
      matchpairs       -
      mps              { do_set_matchpairs $val $mod }
      modeline         -
      ml               { do_set_modeline 1 }
      nomodeline       -
      noml             { do_set_modeline 0 }
      modelines        -
      mls              {
        if {$ml} { return $txt }
        do_set_modelines $val
      }
      modifiable       -
      ma               { do_set_modifiable 1 }
      nomodifiable     -
      noma             { do_set_modifiable 0 }
      modified         -
      mod              { do_set_modified 1 }
      nomodified       -
      nomod            { do_set_modified 0 }
      number           -
      nu               { do_set_number 1 }
      nonumber         -
      nonu             { do_set_number 0 }
      numberwidth      -
      nuw              {
        if {$ml} { return $txt }
        do_set_numberwidth $val
      }
      relativenumber   -
      rnu              { do_set_relativenumber relative }
      norelativenumber -
      nornu            { do_set_relativenumber absolute }
      selection        -
      sel              { do_set_selection $val }
      shiftwidth       -
      sw               { do_set_shiftwidth $val }
      showmatch        -
      sm               { do_set_showmatch 1 }
      noshowmatch      -
      nosm             { do_set_showmatch 0 }
      smartindent      -
      si               { do_set_indent_mode IND+ 1 }
      nosmartindent    -
      nosi             { do_set_indent_mode IND+ 0 }
      splitbelow       -
      sb               { do_set_split 1 }
      nosplitbelow     -
      nosb             { do_set_split 0; set txt [gui::current_txt] }
      syntax           -
      syn              { do_set_syntax $val }
      tabstop          -
      ts               { do_set_tabstop $val }
      default          {
        gui::set_info_message [format "%s (%s)" [msgcat::mc "Unrecognized vim option"] $opt]
      }
    }

    return $txt

  }

  ######################################################################
  # Causes the current working directory to automatically change to be
  # the directory of the currently opened file.  This is a global setting.
  proc do_set_autochdir {value} {

    gui::set_auto_cwd $value

  }

  ######################################################################
  # Sets the indentation mode based on the current value, the specified
  # type (IND, IND+) and the value (0 or 1).
  proc do_set_indent_mode {type value} {

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
    set curr [indent::get_indent_mode [gui::current_txt]]

    # If the indentation mode will change, set it to the new value
    if {$curr ne $newval($curr,$type,$value)} {
      indent::set_indent_mode $newval($curr,$type,$value)
    }

  }

  ######################################################################
  # Sets the file browser directory default pathname.
  proc do_set_browse_dir {val} {

    gui::set_browse_directory $val

  }

  ######################################################################
  # Sets the tab expansion mode for the current buffer to (use tabs or
  # translate tabs to spaces.
  proc do_set_expandtab {val} {

    snippets::set_expandtabs [gui::current_txt] $val

  }

  ######################################################################
  # Set the EOL setting for the current buffer.
  proc do_set_fileformat {val} {

    array set map {
      dos  crlf
      unix lf
      mac  cr
    }

    # Set the current EOL translation
    if {[info exists map($val)]} {
      gui::set_current_eol_translation $map($val)
    } else {
      gui::set_info_message [format "%s (%s)" [msgcat::mc "File format unrecognized"] $val]
    }

  }

  ######################################################################
  # Perform a fold_all or unfold_all command call.
  proc do_set_foldenable {val} {

    folding::set_vim_foldenable [gui::current_txt] $val

  }

  ######################################################################
  # Set the current code folding method.
  proc do_set_foldmethod {val} {

    array set map {
      none   1
      manual 1
      syntax 1
    }

    # Set the current folding method
    if {[info exists map($val)]} {
      folding::set_fold_method [gui::current_txt] $val
    } else {
      gui::set_info_message [format "%s (%s)" [msgcat::mc "Folding method unrecognized"] $val]
    }

  }

  ######################################################################
  # Set the matchpairs to the given value(s).  The value of val is like
  # <:> and mod will be {}, + or -.
  proc do_set_matchpairs {val mod} {

    # Get the current text widget
    set txt  [gui::current_txt]
    set lang [ctext::get_lang $txt insert]

    # Get the current match characters
    set match_chars [ctext::getAutoMatchChars $txt $lang]
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
    ctext::setAutoMatchChars $txt $lang $match_chars

  }

  ######################################################################
  # Sets whether or not modeline information should be used for the current
  # buffer.
  proc do_set_modeline {val} {

    variable modeline

    set modeline([gui::current_txt].t) $val

  }

  ######################################################################
  # Sets the number of lines to parse for modeline information.
  proc do_set_modelines {val} {

    variable modelines

    if {[string is integer $val]} {
      set modelines $val
    } else {
      gui::set_info_message [msgcat::mc "Illegal modelines value"]
    }

  }

  ######################################################################
  # Set the locked status of the current buffer.
  proc do_set_modifiable {val} {

    gui::set_current_file_lock [expr {$val ? 0 : 1}]

  }

  ######################################################################
  # Changes the modified state of the current buffer.
  proc do_set_modified {val} {

    gui::set_current_modified $val

  }

  ######################################################################
  # Sets the visibility of the line numbers.
  proc do_set_number {val} {

    gui::set_line_number_view $val

  }

  ######################################################################
  # Sets the minimum width of the line number gutter area to the specified
  # value.
  proc do_set_numberwidth {val} {

    if {[string is integer $val]} {
      gui::set_line_number_width $val
    } else {
      gui::set_info_message [format "%s (%s)" [msgcat::mc "Number width not a number"] $val]
    }

  }

  ######################################################################
  # Sets the relative numbering mode to the given value.
  proc do_set_relativenumber {val} {

    [gui::current_txt] configure -linemap_type $val

  }

  ######################################################################
  # Sets the selection value to either old, inclusive or exclusive.
  proc do_set_selection {val} {

    variable seltype

    switch $val {
      "inclusive" -
      "exclusive" {
        set seltype $val
      }
      default     {
        gui::set_info_message [format "%s (%s)" [msgcat::mc "Selection value is unsupported"] $val]
      }
    }

  }

  ######################################################################
  # Specifies the number of spaces to use for each indentation.
  proc do_set_shiftwidth {val} {

    if {[string is integer $val]} {
      indent::set_shiftwidth [gui::current_txt].t $val
    } else {
      gui::set_info_message [msgcat::mc "Shiftwidth value is not an integer"]
    }

  }

  ######################################################################
  # Sets the showmatch value in all of the text widgets.
  proc do_set_showmatch {val} {

    gui::set_matching_char $val

  }

  ######################################################################
  # Shows or hides split view in the current buffer.
  proc do_set_split {val} {

    if {$val} {
      gui::show_split_pane
    } else {
      gui::hide_split_pane
    }

  }

  ######################################################################
  # Run the set syntax command.
  proc do_set_syntax {val} {

    syntax::set_current_language [syntax::get_vim_language $val]

  }

  ######################################################################
  # Specifies number of spaces that a TAB in the file counts for.
  proc do_set_tabstop {val} {

    if {[string is integer $val]} {
      indent::set_tabstop [gui::current_txt].t $val
    } else {
      gui::set_info_message [msgcat::mc "Tabstop value is not an integer"]
    }

  }

  ######################################################################
  # Set the select anchor for visual mode.
  proc set_select_anchors {txtt indices} {

    variable select_anchors

    set select_anchors($txtt) $indices

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
  proc adjust_select {txtt index pos} {

    variable mode
    variable select_anchors
    variable seltype

    # Get the visual type from the mode
    set type [lindex [split $mode($txtt) :] 1]

    # Get the anchor for the given selection
    set anchor [lindex $select_anchors($txtt) $index]

    if {[$txtt compare $anchor < $pos]} {
      if {$type eq "line"} {
        $txtt tag add sel "$anchor linestart" "$pos lineend"
      } elseif {$seltype eq "exclusive"} {
        $txtt tag add sel $anchor $pos
      } else {
        $txtt tag add sel $anchor $pos+1c
      }
    } else {
      if {$type eq "line"} {
        $txtt tag add sel "$pos linestart" "$anchor lineend"
      } elseif {$seltype eq "exclusive"} {
        $txtt tag add sel $pos $anchor
      } else {
        $txtt tag add sel $pos $anchor+1c
      }
    }

  }

  ######################################################################
  # Handles an escape key in the command entry widget.
  proc handle_command_escape {w} {

    # Get the last text widget that had focus
    set txt [gui::last_txt_focus]

    # Delete the value in the command entry
    $w delete 0 end

    # Remove the grab and set the focus back to the text widget
    grab release $w
    gui::set_txt_focus $txt

    # Hide the command entry widget
    gui::panel_forget $w

  }

  ######################################################################
  # Handles a backspace key in the command entry widget.
  proc handle_command_backspace {w} {

    if {[$w get] eq ""} {

      # Remove the grab and set the focus back to the text widget
      grab release $w
      gui::set_txt_focus [gui::last_txt_focus]

      # Hide the command entry widget
      gui::panel_forget $w

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
    variable multiplier
    variable search_dir
    variable column
    variable select_anchors
    variable modeline
    variable multicursor
    variable recording
    variable operator
    variable motion

    # Change the cursor to the block cursor
    $txt configure -blockcursor true -insertwidth 1

    # Put ourselves into start mode
    set mode($txt.t)             "command"
    set number($txt.t)           ""
    set multiplier($txt.t)       ""
    set search_dir($txt.t)       "next"
    set column($txt.t)           ""
    set select_anchors($txt.t)   [list]
    set modeline($txt.t)         1
    set multicursor($txt.t)      0
    set operator($txt.t)         ""
    set motion($txt.t)           ""

    # Add bindings
    bind vim$txt <Escape>                "if {\[vim::handle_escape %W\]} { break }"
    bind vim$txt <Key>                   "if {\[vim::handle_any %W %k %A %K\]} { break }"
    bind vim$txt <Control-Button-1>      "vim::nil"
    bind vim$txt <Shift-Button-1>        "vim::nil"
    bind vim$txt <Button-1>              "vim::handle_button1 %W %x %y; break"
    bind vim$txt <Double-Shift-Button-1> "vim::nil"
    bind vim$txt <Double-Button-1>       "vim::handle_double_button1 %W %x %y; break"
    bind vim$txt <Triple-Button-1>       "vim::nil"
    bind vim$txt <Triple-Shift-Button-1> "vim::nil"
    bind vim$txt <B1-Motion>             "vim::handle_motion %W %x %y; break"

    # Insert the vim binding just after all
    set all_index [lsearch [bindtags $txt.t] all]
    bindtags $txt.t [linsert [bindtags $txt.t] [expr $all_index + 1] vim$txt]

    # Put ourselves into start mode
    command_mode $txt.t

    # Set autoseparator mode to false
    $txt configure -autoseparators 0

  }

  ######################################################################
  # Called whenever the given text widget is destroyed.
  proc handle_destroy_txt {txt} {

    variable command_entries
    variable mode
    variable number
    variable multiplier
    variable search_dir
    variable column
    variable select_anchors
    variable modeline

    unset -nocomplain command_entries($txt.t)
    unset -nocomplain mode($txt.t)
    unset -nocomplain number($txt.t)
    unset -nocomplain multiplier($txt.t)
    unset -nocomplain search_dir($txt.t)
    unset -nocomplain column($txt.t)
    unset -nocomplain select_anchors($txt.t)
    unset -nocomplain modeline($txt.t)

  }

  ######################################################################
  # This is a do-nothing procedure that is called by bindings that would
  # otherwise match other keybindings that we don't want to call.
  proc nil {} {

  }

  ######################################################################
  # Handles a left-click event when in Vim mode.
  proc handle_button1 {W x y} {

    $W tag remove sel 1.0 end

    set current [$W index @$x,$y]
    $W mark set [utils::text_anchor $W] $current
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
    set anchor [utils::text_anchor $W]
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
    $txt configure -blockcursor false -autoseparators 1 -insertwidth [preferences::get Appearance/CursorWidth]

  }

  ######################################################################
  # Resets the operator/motion states.
  proc reset_state {txtt} {

    variable operator
    variable motion
    variable multiplier
    variable number

    # Clear the state information
    set operator($txtt)   ""
    set motion($txtt)     ""
    set multiplier($txtt) ""
    set number($txtt)     ""

    # Add a separator
    $txtt edit separator

  }

  ######################################################################
  # Set the current mode to the "edit" mode.
  proc edit_mode {txtt} {

    variable mode
    variable multicursor

    # Set the mode to the edit mode
    set mode($txtt) "edit"

    # Clear the multicursor mode (since we are not moving multicursors around)
    disable_multicursor $txtt

    # Set the blockcursor to false
    $txtt configure -blockcursor false -insertwidth [preferences::get Appearance/CursorWidth]

    # If the current cursor is on a dummy space, remove it
    set tags [$txtt tag names insert]
    if {([lsearch $tags "dspace"] != -1) && ([lsearch $tags "mcursor"] == -1)} {
      $txtt fastdelete -update 0 -undo 0 insert
    }

  }

  ######################################################################
  # Set the current mode to the "command" mode.
  proc command_mode {txtt} {

    variable mode
    variable multicursor

    # If we are coming from visual mode, clear the selection and the anchors
    if {[in_visual_mode $txtt]} {
      $txtt tag remove sel 1.0 end
    }

    # If were in the edit or replace_all state, move the insertion cursor back
    # one character.
    if {(($mode($txtt) eq "edit") || ($mode($txtt) eq "replace_all")) && \
        ([$txtt index insert] ne [$txtt index "insert linestart"])} {
      if {[multicursor::enabled $txtt]} {
        multicursor::adjust_left $txtt 1
      } else {
        ::tk::TextSetCursor $txtt "insert-1c"
      }
    }

    # Set the blockcursor to true
    $txtt configure -blockcursor true -insertwidth 1

    # Set the current mode to the command mode
    set mode($txtt) "command"

    # Clear multicursor mode
    disable_multicursor $txtt

    # Reset the states
    reset_state $txtt

    # Adjust the insertion marker
    adjust_insert $txtt

  }

  ######################################################################
  # Set the current mode to multicursor move mode.
  proc multicursor_mode {txtt} {

    variable mode
    variable multicursor

    set multicursor($txtt) 1

    # Effectively make the insertion cursor disappear
    $txtt configure -blockcursor 0 -insertwidth 0

    # Make the multicursors look like the normal cursor
    $txtt tag configure mcursor -background [$txtt cget -insertbackground]

    # Make sure that the status bar is updated properly
    gui::update_position [winfo parent $txtt]

  }

  ######################################################################
  # Turns off multicursor moving mode.
  proc disable_multicursor {txtt} {

    variable mode
    variable multicursor

    set multicursor($txtt) 0

    # Restore the insertion cursor width
    $txtt configure -blockcursor [expr {$mode($txtt) ne "edit"}] -insertwidth [preferences::get Appearance/CursorWidth]

    # Make the multicursors look like normal
    $txtt tag configure mcursor -background ""

    # Make sure that the status bar is updated properly
    gui::update_position [winfo parent $txtt]

  }

  ######################################################################
  # Set the current mode to the "visual" mode.
  proc visual_mode {txtt type} {

    variable mode
    variable select_anchors
    variable multicursor
    variable seltype

    # Set the current mode
    set mode($txtt) "visual:$type"

    # Clear the current selection
    $txtt tag remove sel 1.0 end

    # Initialize the select range
    if {$multicursor($txtt)} {
      set select_anchors($txtt) [list]
      foreach {start end} [$txtt tag ranges mcursor] {
        lappend select_anchors($txtt) $start
      }
    } else {
      set select_anchors($txtt) [$txtt index insert]
      # adjust_select $txtt 0 insert
    }

    # If the selection type is inclusive or old, include the current insertion cursor in the selection
    if {$type eq "line"} {
      foreach anchor $select_anchors($txtt) {
        $txtt tag add sel "$anchor linestart" "$anchor+1l linestart"
      }
    } elseif {$seltype ne "exclusive"} {
      foreach anchor $select_anchors($txtt) {
        $txtt tag add sel $anchor $anchor+1c
      }
    }

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
  proc record {keysym {reg auto}} {

    variable recording

    if {$recording($reg,mode) eq "none"} {
      set recording($reg,events) $keysym
    }

  }

  ######################################################################
  # Adds an event to the recording buffer if we are in record mode.
  proc record_add {keysym {reg auto}} {

    variable recording

    if {$recording($reg,mode) eq "record"} {
      lappend recording($reg,events) $keysym
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
      event generate $txtt <Key> -keysym $event
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

    # If we are not running in Vim mode, don't continue
    if {![in_vim_mode $txtt]} {
      return
    }

    # Remove any existing dspace characters
    remove_dspace [winfo parent $txtt]

    # If the current line contains nothing, add a dummy space so that the
    # block cursor doesn't look dumb.
    if {[$txtt index "insert linestart"] eq [$txtt index "insert lineend"]} {
      $txtt fastinsert -update 0 -undo 0 insert " " dspace
      $txtt mark set insert "insert-1c"

    # Make sure that lineend is never the insertion point
    } elseif {[$txtt index insert] eq [$txtt index "insert lineend"]} {
      $txtt mark set insert "insert-1 display chars"
    }

    # Adjust the selection (if we are in visual mode)
    if {[in_visual_mode $txtt]} {
      adjust_select $txtt 0 insert
    }

  }

  ######################################################################
  # Returns the current number.
  proc get_number {txtt} {

    variable number
    variable multiplier

    set num  [expr {($number($txtt)     eq "") ? 1 : $number($txtt)}]
    set mult [expr {($multiplier($txtt) eq "") ? 1 : $multiplier($txtt)}]

    return [expr $mult * $num]

  }

  ######################################################################
  # Removes dspace characters.
  proc remove_dspace {w} {

    foreach {endpos startpos} [lreverse [$w tag ranges dspace]] {
      if {[lsearch [$w tag names $startpos] "mcursor"] == -1} {
        $w fastdelete -update 0 -undo 0 $startpos $endpos
      }
    }

  }

  ######################################################################
  # Removes the dspace tag from the current index (if it is set).
  proc cleanup_dspace {w} {

    if {[lsearch [$w tag names insert] dspace] != -1} {
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
  proc handle_escape {txtt} {

    variable mode
    variable recording
    variable multicursor

    # Add this keysym to the current recording buffer (if one exists)
    set curr_reg $recording(curr_reg)
    if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
      record_add Escape $curr_reg
    }

    # Clear the any selections
    $txtt tag remove sel 1.0 end

    if {$mode($txtt) ne "command"} {

      # Add to the recording if we are doing so
      record_add Escape
      record_stop

      # Set the mode to command
      command_mode $txtt

    } else {

      # If were in start mode, clear the auto recording buffer
      record_clear

      # Clear any searches
      search::find_clear

    }

    # Clear the state
    reset_state $txtt

    # Clear the multicursor indicator
    disable_multicursor $txtt

    return 1

  }

  if {[tk windowingsystem] eq "aqua"} {
    proc get_keysym {keycode keysym} {
      return $utils::code2sym($keycode)
    }
  } else {
    proc get_keysym {keycode keysym} { return $keysym }
  }

  ######################################################################
  # Handles any single printable character.
  proc handle_any {txtt keycode char keysym} {

    variable mode
    variable operator
    variable column
    variable recording

    # Lookup the keysym
    if {[catch { get_keysym $keycode $keysym } keysym]} {
      return 0
    }

    # If the key does not have a printable char representation, quit now
    if {([string compare -length 5 $keysym "Shift"]   == 0) || \
        ([string compare -length 7 $keysym "Control"] == 0) || \
        ([string compare -length 3 $keysym "Alt"]     == 0) || \
        ($keysym eq "??")} {
      return 1
    }

    # Handle a character when recording a macro
    if {$mode($txtt) eq "record_reg"} {
      command_mode $txtt
      if {[regexp {^[a-z]$} $keysym]} {
        record_start $keysym
        return 1
      }
    } elseif {$mode($txtt) eq "playback_reg"} {
      command_mode $txtt
      if {[regexp {^[a-z]$} $keysym]} {
        playback $txtt $keysym
        return 1
      } elseif {$keysym eq "at"} {
        if {$recording(curr_reg) ne ""} {
          playback $txtt $recording(curr_reg)
        }
        return 1
      }
    } elseif {($mode($txtt) ne "command") || ($keysym ne "q")} {
      set curr_reg $recording(curr_reg)
      if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
        record_add $keysym $curr_reg
      }
    }

    if {[handle_find_motion $txtt $char]} {
      reset_state $txtt
      return 1
    }

    # If the keysym is neither j or k, clear the column
    if {($keysym ne "j") && ($keysym ne "k")} {
      set column($txtt) ""
    }

    # If we are not in edit mode
    if {![catch "handle_$keysym $txtt" rc] && $rc} {
      record_add $keysym
      return 1

    # If the keysym is a number, handle the number
    } elseif {[string is integer $keysym] && [handle_number $txtt $char]} {
      record_add $keysym
      return 1

    # If we are in start, visual, record or format modes, stop character processing
    } elseif {($mode($txtt) eq "command")  || \
              ([in_visual_mode $txtt])   || \
              ($mode($txtt) eq "record") || \
              ($operator($txtt) eq "format")} {
      return 1

    # Append the text to the insertion buffer
    } elseif {[string equal -length 7 $mode($txtt) "replace"]} {
      record_add $keysym
      if {[multicursor::enabled $txtt]} {
        multicursor::replace $txtt $char indent::check_indent
      } else {
        $txtt replace insert "insert+1c" $char
        $txtt highlight "insert linestart" "insert lineend"
      }
      if {$mode($txtt) eq "replace"} {
        if {[multicursor::enabled $txtt]} {
          multicursor::adjust_left $txtt 1
        } else {
          ::tk::TextSetCursor $txtt "insert-1c"
        }
        command_mode $txtt
        record_stop
      }
      return 1

    # Remove all text within the current character
    } elseif {$mode($txtt) eq "changein"} {
      record_add $keysym
      if {[edit::delete_between_char $txtt $char 0]} {
        edit_mode $txtt
      } else {
        command_mode $txtt
      }
      return 1

    # Select all text within the current character
    } elseif {[lindex [split $mode($txtt) :] 0] eq "visualin"} {
      record_add $keysym
      if {[edit::select_between_char $txtt $char]} {
        set mode($txtt) "visual:[lindex [split $mode($txtt) :] 1]"
      } else {
        command_mode $txtt
      }
      return 1

    # Format all text within the current character
    } elseif {$mode($txtt) eq "formatin"} {
      record_add $keysym
      edit::format_between_char $txtt $char
      command_mode $txtt
      return 1

    # Left shift all text within the current character
    } elseif {$mode($txtt) eq "lshiftin"} {
      record_add $keysym
      edit::lshift_between_char $txtt $char
      command_mode $txtt
      return 1

    # Right shift all text within the current character
    } elseif {$mode($txtt) eq "rshiftin"} {
      record_add $keysym
      edit::rshift_between_char $txtt $char
      command_mode $txtt
      return 1

    # If we are not in edit mode, switch to command mode (an illegal command was executed)
    } elseif {$mode($txtt) ne "edit"} {
      command_mode $txtt
      return 1
    }

    # Record the keysym
    record_add $keysym

    return 0

  }


  ######################################################################
  # Performs the current motion-specific operation on the text range specified
  # by startpos/endpos.
  proc do_operation {txtt eposargs {sposargs {}}} {

    variable operator
    variable multicursor

    puts "In do_operation, txtt: $txtt, eposargs: $eposargs, sposargs: $sposargs, operator($txtt): $operator($txtt), multicursor: $multicursor($txtt)"

    switch $operator($txtt) {
      "" {
        if {$multicursor($txtt)} {
          multicursor::move $txtt $eposargs
        } else {
          ::tk::TextSetCursor $txtt [edit::get_index $txtt {*}$eposargs]
          vim::adjust_insert $txtt
        }
        reset_state $txtt
        return 1
      }
      "delete" {
        if {![multicursor::delete $txtt $eposargs $sposargs]} {
          set copy [expr [lsearch [list spacestart spaceend] [lindex $eposargs 0]] == -1]
          edit::delete $txtt {*}[edit::get_range $txtt $eposargs $sposargs] $copy 1
        }
        reset_state $txtt
        return 1
      }
      "change" {
        if {![multicursor::delete $txtt $eposargs $sposargs]} {
          edit::delete $txtt {*}[edit::get_range $txtt $eposargs $sposargs] 0 0
        }
        edit_mode $txtt
        reset_state $txtt
        return 1
      }
      "yank" {
        lassign [edit::get_range $txtt $eposargs $sposargs] startpos endpos
        clipboard clear
        clipboard append [$txtt get $startpos $endpos]
        ::tk::TextSetCursor $txtt $startpos
        vim::adjust_insert $txtt
        reset_state $txtt
        return 1
      }
      "swap" {
        if {![multicursor::toggle_case $txtt $eposargs $sposargs]} {
          lassign [edit::get_range $txtt $eposargs $sposargs] startpos endpos
          edit::transform_toggle_case $txtt $startpos $endpos
        }
        command_mode $txtt
        return 1
      }
      "upper" {
        if {![multicursor::upper_case $txtt $eposargs $sposargs]} {
          lassign [edit::get_range $txtt $eposargs $sposargs] startpos endpos
          edit::transform_to_upper_case $txtt $startpos $endpos
        }
        command_mode $txtt
        return 1
      }
      "lower" {
        if {![multicursor::lower_case $txtt $eposargs $sposargs]} {
          lassign [edit::get_range $txtt $eposargs $sposargs] startpos endpos
          edit::transform_to_lower_case $txtt $startpos $endpos
        }
        command_mode $txtt
        return 1
      }
      "rot13" {
        if {![multicursor::rot13 $txtt $eposargs $sposargs]} {
          lassign [edit::get_range $txtt $eposargs $sposargs] startpos endpos
          edit::transform_to_rot13 $txtt $startpos $endpos
        }
        command_mode $txtt
        return 1
      }
      "format" {
        if {![multicursor::format_text $txtt $eposargs $sposargs]} {
          lassign [edit::get_range $txtt $eposargs $sposargs] startpos endpos
          indent::format_text $txtt $startpos $endpos
          ::tk::TextSetCursor $txtt [edit::get_index $txtt firstchar -num 0 -startpos $startpos]
        }
        command_mode $txtt
        return 1
      }
      "lshift" {
        if {![multicursor::shift $txtt left $eposargs $sposargs]} {
          lassign [edit::get_range $txtt $eposargs $sposargs] startpos endpos
          edit::unindent $txtt $startpos $endpos
          ::tk::TextSetCursor $txtt [edit::get_index $txtt firstchar -num 0 -startpos $startpos]
        }
        command_mode $txtt
        return 1
      }
      "rshift" {
        if {![multicursor::shift $txtt right $eposargs $sposargs]} {
          lassign [edit::get_range $txtt $eposargs $sposargs] startpos endpos
          edit::indent $txtt $startpos $endpos
          ::tk::TextSetCursor $txtt [edit::get_index $txtt firstchar -num 0 -startpos $startpos]
        }
        command_mode $txtt
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Checks the current mode and if we are in a find character motion,
  # handle the action.
  proc handle_find_motion {txtt char} {

    variable operator
    variable motion

    # If the current mode does not pertain to us, return now
    if {[lsearch {t f} [string tolower $motion($txtt)]] == -1} {
      return 0
    }

    # Get the motion information
    set dir  [expr {[string is lower $motion($txtt)] ? "next" : "prev"}]
    set excl [expr {[string tolower $motion($txtt)] eq "t"}]

    if {($operator($txtt) eq "") || ($dir eq "prev")} {
      return [do_operation $txtt [list findchar -dir $dir -char $char -num [get_number $txtt] -exclusive $excl]]
    } else {
      return [do_operation $txtt [list findchar -dir $dir -char $char -num [get_number $txtt] -exclusive $excl -adjust "+1 display chars"]]
    }

  }

  ######################################################################
  # If we are in "command" mode, the number is 0 and the current number
  # is empty, set the insertion cursor to the beginning of the line;
  # otherwise, append the number current to number value.
  proc handle_number {txtt num} {

    variable mode
    variable motion
    variable number
    variable multiplier

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {($multiplier($txtt) eq "") && ($num eq "0")} {
        if {$motion($txtt) eq ""} {
          return [do_operation $txtt linestart]
        } elseif {$motion($txtt) eq "g"} {
          return [do_operation $txtt dispstart]
        }
      } else {
        append multiplier($txtt) $num
        record_start
        return 1
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in the "command" mode, display the command entry field and
  # give it the focus.
  proc handle_colon {txtt} {

    variable mode
    variable command_entries

    # If we are in the "command" mode, bring up the command entry widget
    # and give it the focus.
    if {$mode($txtt) eq "command"} {

      # Colorize the entry widget to match the look of the associated text widget
      $command_entries($txtt) configure \
        -background [$txtt cget -background] -foreground [$txtt cget -foreground] \
        -insertbackground [$txtt cget -insertbackground] -font [$txtt cget -font]

      # Show the command entry widget
      gui::panel_place $command_entries($txtt)

      # Set the focus and grab on the widget
      grab $command_entries($txtt)
      focus $command_entries($txtt)

      return 1

    }

    return 0

  }

  ######################################################################
  # If we are in the "command" mode, move insertion cursor to the end of
  # the current line.  If we are in "delete" mode, delete all of the
  # text from the insertion marker to the end of the line.
  proc handle_dollar {txtt} {

    variable mode
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list lineend -num [get_number $txtt]]]
      } elseif {$motion($txtt) eq "g"} {
        return [do_operation $txtt [list dispend -num [get_number $txtt]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in the "command" mode, move insertion cursor to the beginning
  # of the current line.  If we are in "delete" mode, delete all of the
  # text between the beginning of the current line and the current
  # insertion marker.
  proc handle_asciicircum {txtt} {

    variable mode
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list firstchar -num 0]]
      } elseif {$motion($txtt) eq "g"} {
        return [do_operation $txtt dispfirst]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, display the search bar.
  proc handle_slash {txtt} {

    variable mode
    variable search_dir

    if {$mode($txtt) eq "command"} {
      gui::search "next"
      set search_dir($txtt) "next"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, display the search bar for doing a
  # a previous search.
  proc handle_question {txtt} {

    variable mode
    variable operator
    variable motion
    variable search_dir

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        if {$motion($txtt) eq ""} {
          gui::search "prev"
          set search_dir($txtt) "prev"
        } elseif {$motion($txtt) eq "g"} {
          set operator($txtt) "rot13"
          set motion($txtt)   ""
          return 1
        }
      } elseif {$operator($txtt) eq "rot13"} {
        return [do_operation $txtt lineend linestart]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, invokes the buffered command at the current
  # insertion point.
  proc handle_period {txtt} {

    variable mode

    if {$mode($txtt) eq "command"} {
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
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode and the insertion point character has a
  # matching left/right partner, display the partner.
  proc handle_percent {txtt} {

    variable mode
    variable multiplier

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$multiplier($txtt) eq ""} {
        gui::show_match_pair
      } else {
        set lines [lindex [split [$txtt index end] .] 0]
        set line  [expr int( ($multiplier($txtt) * $lines + 99) / 100 )]
        return [do_operation $txtt [list linenum -num $line]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles the i-key when in Vim mode.
  proc handle_i {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      switch $operator($txtt) {
        "" {
          if {![in_visual_mode $txtt]} {
            edit_mode $txtt
            record_start
          } else {
            set motion($txtt) i
            return 1
          }
        }
        "folding" {
          if {![in_visual_mode $txtt]} {
            folding::set_vim_foldenable [winfo parent $txtt] [expr [folding::get_vim_foldenable [winfo parent $txtt]] ^ 1]
          }
        }
        default {
          if {$motion($txtt) ne ""} {
            set operator($txtt) "$operator($txtt)in"
            return 1
          }
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, inserts at the beginning of the current
  # line.
  proc handle_I {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        ::tk::TextSetCursor $txtt "insert linestart"
        edit_mode $txtt
        record_start
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor down one line.
  proc handle_j {txtt} {

    variable mode
    variable column
    variable operator

    # Move the insertion cursor down one line
    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      switch $operator($txtt) {
        "folding" {
          folding::jump_to [winfo parent $txtt] next [get_number $txtt]
        }
        "folding:range" {
          folding::close_range [winfo parent $txtt] insert "insert+[get_number $txtt] display lines"
        }
        default {
          return [do_operation $txtt [list down -num [get_number $txtt] -column vim::column($txtt)]]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, join the next line to the end of the
  # previous line.
  proc handle_J {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        edit::transform_join_lines $txtt [get_number $txtt]
        record J
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor up one line.
  proc handle_k {txtt} {

    variable mode
    variable column
    variable multicursor
    variable operator

    set num [get_number $txtt]

    # Move the insertion cursor up one line
    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      switch $operator($txtt) {
        "folding" {
          folding::jump_to [winfo parent $txtt] prev [get_number $txtt]
        }
        "folding:range" {
          folding::close_range [winfo parent $txtt] [edit::get_index $txtt up -num [get_number $txtt] -column vim::column($txtt)] insert
          ::tk::TextSetCursor $txtt "insert-1 display lines"
          adjust_insert $txtt
        }
        default {
          return [do_operation $txtt [list up -num [get_number $txtt] -column vim::column($txtt)]]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in start mode and multicursor is enabled, move all of the
  # cursors up one line.
  proc handle_K {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        if {[set word [string trim [$txtt get "insert wordstart" "insert wordend"]]] ne ""} {
          search::search_documentation -str $word
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor right one
  # character.
  proc handle_l {txtt} {

    variable mode
    variable motion

    # Move the insertion cursor right one character
    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      set startargs ""
      switch [lindex $motion($txtt) end] {
        "V" {
          set startargs linestart
          set endargs   lineend
        }
        "v" {
          set endargs [list right -num [expr [get_number $txtt] + 1]]
        }
        default {
          set endargs [list right -num [get_number $txtt]]
        }
      }
      return [do_operation $txtt $endargs $startargs]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode and multicursor mode is enabled, adjust
  # all of the cursors to the right by one character.  If we are only
  # in "command" mode, jump the insertion cursor to the bottom line.
  proc handle_L {txtt} {

    variable mode
    variable multicursor

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      return [do_operation $txtt screenbot]
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
  # If we are in "goto" mode, edit any filenames that are found under
  # any of the cursors.
  proc handle_f {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$operator($txtt) eq "folding"} {
        if {![folding::close_selected [winfo parent $txtt]]} {
          set mode($txtt) "folding:range"
          return 1
        }
      } else {
        if {$motion($txtt) eq ""} {
          set motion($txtt) "f"
          return 1
        } elseif {$motion($txtt) eq "g"} {
          if {[multicursor::enabled $txtt]} {
            foreach {startpos endpos} [$txtt tag ranges mcursor] {
              if {[file exists [set fname [get_filename $txtt $startpos]]]} {
                gui::add_file end $fname
              }
            }
          } else {
            if {[file exists [set fname [get_filename $txtt insert]]]} {
              gui::add_file end $fname
            }
          }
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles any previous find character motions.
  proc handle_F {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$operator($txtt) eq "folding"} {
        if {![folding::close_selected [winfo parent $txtt]]} {
          if {[set num [get_number $txtt]] > 1} {
            folding::close_range [winfo parent $txtt] insert "insert+[expr $num - 1] display lines"
          }
        }
      } else {
        if {$motion($txtt) eq ""} {
          set motion($txtt) "F"
          return 1
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles any next find character (non-inclusive) motions.
  proc handle_t {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        set motion($txtt) "t"
        return 1
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles any next find character (non-inclusive) motions.
  proc handle_T {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        set motion($txtt) "T"
        return 1
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, edit any filenames found under any of
  # the cursors.
  proc handle_g {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        set motion($txtt) "g"
        return 1
      } elseif {$motion($txtt) eq "g"} {
        return [do_operation $txtt first]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor left one
  # character.
  proc handle_h {txtt} {

    variable mode
    variable operator
    variable motion

    # Move the insertion cursor left one character
    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      set startargs ""
      switch [lindex $motion($txtt) end] {
        "V" {
          set startargs "linestart"
          set endargs   "lineend"
        }
        "v" {
          set startargs right
          set endargs   [list left -num [get_number $txtt]]
        }
        default {
          set endargs [list left -num [get_number $txtt]]
        }
      }
      return [do_operation $txtt $endargs $startargs]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode and multicursor mode is enabled, move all
  # cursors to the left by one character.  Otherwise, if we are just in
  # "command" mode, jump to the top line of the editor.
  proc handle_H {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$operator($txtt) eq ""} {
        if {$motion($txtt) eq ""} {
          return [do_operation $txtt screentop]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor to the beginning
  # of previous word.
  proc handle_b {txtt} {

    variable mode
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list wordstart -dir prev -num [get_number $txtt]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, change the state to "change" mode.  If
  # we are in the "change" mode, delete the current line and put ourselves
  # into edit mode.
  proc handle_c {txtt} {

    variable mode
    variable operator

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      switch $operator($txtt) {
        "" {
          if {[edit::delete_selected $txtt]} {
            edit_mode $txtt
            reset_state $txtt
          } else {
            set operator($txtt) "change"
            record_start
          }
        }
        "change" {
          return [do_operation $txtt [list lineend -num [get_number $txtt]] linestart]
        }
        "folding" {
          folding::close_fold [get_number $txtt] [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
          reset_state $txtt
        }
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, delete from the insertion cursor to the
  # end of the line and put ourselves into "edit" mode.
  proc handle_C {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        $txtt delete insert "insert lineend"
        edit_mode $txtt
      } elseif {$operator($txtt) eq "folding"} {
        folding::close_fold 0 [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "folding" mode, remove all folds in the current text editor.
  proc handle_E {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq "folding"} {
        folding::delete_all_folds [winfo parent $txtt]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "change" mode, delete the current word and change to edit
  # mode.
  proc handle_w {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        if {$operator($txtt) eq "change"} {
          return [do_operation $txtt [list wordend -dir next -num [get_number $txtt]]]
        } else {
          return [do_operation $txtt [list wordstart -dir next -num [get_number $txtt]]]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, go to the last line.
  proc handle_G {txtt} {

    variable mode
    variable multiplier

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$multiplier($txtt) eq ""} {
        return [do_operation $txtt last]
      } else {
        return [do_operation $txtt [list linenum -num $multiplier($txtt)]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, transition the mode to the delete mode.
  # If we are in the "delete" mode, delete the current line.
  proc handle_d {txtt} {

    variable mode
    variable operator

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      switch $operator($txtt) {
        "" {
          if {![edit::delete_selected $txtt]} {
            set operator($txtt) "delete"
            record_start
            return 1
          }
        }
        "delete" {
          return [do_operation $txtt [list lineend -num $num -adjust +1c] linestart]
        }
        "folding" {
          folding::delete_fold [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, deletes all text from the current
  # insertion cursor to the end of the line.
  proc handle_D {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        edit::delete_to_end $txtt 1
      } elseif {$operator($txtt) eq "folding"} {
        folding::delete_folds [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in the "command" mode, move the insertion cursor ahead by
  # one character and set ourselves into "edit" mode.
  proc handle_a {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          if {[multicursor::enabled $txtt]} {
            multicursor::adjust_right $txtt 1 dspace
          }
          cleanup_dspace $txtt
          ::tk::TextSetCursor $txtt "insert+1c"
          edit_mode $txtt
          record_start
        }
        "folding" {
          folding::toggle_fold [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0] [get_number $txtt]
        }
        "change" {
          set motion($txtt) "a"
          return 1
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, insert text at the end of the current line.
  proc handle_A {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          ::tk::TextSetCursor $txtt "insert lineend"
          edit_mode $txtt
          record_start
        }
        "folding" {
          folding::toggle_fold [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0] 0
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in the "command" mode, set ourselves to yank mode.  If we
  # are in "yank" mode, copy the current line to the clipboard.
  proc handle_y {txtt} {

    variable mode
    variable operator

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$operator($txtt) eq ""} {
        set operator($txtt) "yank"
        return 1
      } elseif {$operator($txtt) eq "yank"} {
        return [do_operation $txtt [list lineend -num [get_number $txtt] -adjust +1c] linestart]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a paste operation from the menu (or keyboard shortcut).
  proc handle_paste {txt} {

    variable mode

    if {[preferences::get Editor/VimMode] && [info exists mode($txt.t)]} {

      # If we are not currently in edit mode, temporarily set ourselves to edit mode
      if {$mode($txt.t) ne "edit"} {
        record_add i
      }

      # Add the characters
      foreach c [split [clipboard get] {}] {
        record_add [utils::string_to_keysym $c]
      }

      # If we were in command mode, escape out of edit mode
      if {$mode($txt.t) ne "edit"} {
        record_add Escape
        record_stop
      }

    }

  }

  ######################################################################
  # Pastes the contents of the given clip to the text widget after the
  # current line.
  proc do_post_paste {txtt clip} {

    # Create a separator
    $txtt edit separator

    # Get the number of pastes that we need to perform
    set num [get_number $txtt]

    if {[set nl_index [string last \n $clip]] != -1} {
      if {[expr ([string length $clip] - 1) == $nl_index]} {
        set clip [string replace $clip $nl_index $nl_index]
      }
      $txtt insert "insert lineend" [string repeat "\n$clip" $num]
      multicursor::paste $txtt "insert+1l linestart"
      ::tk::TextSetCursor $txtt "insert+1l linestart"
      edit::move_cursor $txtt firstword
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
  # If we are in the "command" mode, put the contents of the clipboard
  # after the current line.
  proc handle_p {txtt} {

    variable mode

    if {$mode($txtt) eq "command"} {
      do_post_paste $txtt [set clip [clipboard get]]
      cliphist::add_from_clipboard
      record p
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Pastes the contents of the given clip prior to the current line
  # in the text widget.
  proc do_pre_paste {txtt clip} {

    $txtt edit separator

    # Calculate the number of clips to pre-paste
    set num [get_number $txtt]

    if {[set nl_index [string last \n $clip]] != -1} {
      if {[expr ([string length $clip] - 1) == $nl_index]} {
        set clip [string replace $clip $nl_index $nl_index]
      }
      set startpos [$txtt index "insert linestart"]
      $txtt insert "insert linestart" [string repeat "$clip\n" $num]
      multicursor::paste $txtt $startpos
      ::tk::TextSetCursor $txtt $startpos
      edit::move_cursor $txtt firstword
    } else {
      $txtt insert insert [string repeat $clip $num]
      multicursor::paste $txtt insert
      ::tk::TextSetCursor $txtt "insert-1c"
    }
    adjust_insert $txtt

    # Create separator
    $txtt edit separator

  }

  ######################################################################
  # If we are in the "command" mode, put the contents of the clipboard
  # before the current line.
  proc handle_P {txtt} {

    variable mode

    if {$mode($txtt) eq "command"} {
      do_pre_paste $txtt [set clip [clipboard get]]
      cliphist::add_from_clipboard
      record P
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Performs an undo operation.
  proc undo {txtt} {

    # Perform the undo operation
    catch { $txtt edit undo }

    # Adjusts the insertion cursor
    adjust_insert $txtt

  }

  ######################################################################
  # Performs a redo operation.
  proc redo {txtt} {

    # Performs the redo operation
    catch { $txtt edit redo }

    # Adjusts the insertion cursor
    adjust_insert $txtt

  }

  ######################################################################
  # If we are in "command" mode, undoes the last operation.
  proc handle_u {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        if {$motion($txtt) eq ""} {
          undo $txtt
        } elseif {$motion($txtt) eq "g"} {
          set operator($txtt) "lower"
          set motion($txtt)   ""
          return 1
        }
      } elseif {$operator($txtt) eq "lower"} {
        return [do_operation $txtt [list lineend -num [get_number $txtt]] linestart]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "goto" mode, convert the mode to uppercase mode.
  proc handle_U {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        if {$motion($txtt) eq "g"} {
          set operator($txtt) "upper"
          set motion($txtt)   ""
          return 1
        }
      } elseif {$operator($txtt) eq "upper"} {
        return [do_operation $txtt [list lineend -num [get_number $txtt]] linestart]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, deletes the current character.
  proc handle_x {txtt} {

    variable mode
    variable operator

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {![edit::delete_selected $txtt]} {
        set operator($txtt) "delete"
        return [do_operation $txtt [list right -num [get_number $txtt]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, deletes the current character (same as
  # the 'x' command).
  proc handle_Delete {txtt} {

    variable mode
    variable operator

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {![edit::delete_selected $txtt]} {
        set operator($txtt) "delete"
        return [do_operation $txtt [list right -num [get_number $txtt]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, deletes the previous character.
  proc handle_X {txtt} {

    variable mode
    variable operator

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {![edit::delete_selected $txtt]} {
        set operator($txtt) "delete"
        return [do_operation $txtt [list left -num [get_number $txtt]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, add a new line below the current line
  # and transition into "edit" mode.
  proc handle_o {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        edit::insert_line_below_current $txtt
      } elseif {$operator($txtt) eq "folding"} {
        folding::open_fold [get_number $txtt] [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, add a new line above the current line
  # and transition into "edit" mode.
  proc handle_O {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        edit::insert_line_above_current $txtt
      } elseif {$operator($txtt) eq "folding"} {
        folding::open_fold 0 [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, set the mode to the "quit" mode.  If we
  # are in "quit" mode, save and exit the current tab.
  proc handle_Z {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        set operator($txtt) "quit"
      } elseif {$operator($txtt) eq "quit"} {
        gui::save_current
        gui::close_current
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in start mode and multicursors are enabled, set the Vim mode
  # to indicate that any further movement commands should be applied to
  # the multicursors instead of the standard cursor.
  proc handle_m {txtt} {

    variable mode
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {[multicursor::enabled $txtt]} {
        multicursor_mode $txtt
      } elseif {$motion($txtt) eq "g"} {
        return [do_operation $txtt dispmid]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, finds the next occurrence of the search text.
  proc handle_n {txtt} {

    variable mode
    variable operator
    variable search_dir

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          set count [get_number $txtt]
          if {$search_dir($txtt) eq "next"} {
            for {set i 0} {$i < $count} {incr i} {
              search::find_next [winfo parent $txtt]
            }
          } else {
            for {set i 0} {$i < $count} {incr i} {
              search::find_prev [winfo parent $txtt]
            }
          }
        }
        "folding" {
          folding::set_vim_foldenable [winfo parent $txtt] 0
        }
        default {
          return [do_operation $txtt numberend]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, finds the previous occurrence of the
  # search text.
  proc handle_N {txtt} {

    variable mode
    variable operator
    variable search_dir

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          set count [get_number $txtt]
          if {$search_dir($txtt) eq "next"} {
            for {set i 0} {$i < $count} {incr i} {
              search::find_prev [winfo parent $txtt]
            }
          } else {
            for {set i 0} {$i < $count} {incr i} {
              search::find_next [winfo parent $txtt]
            }
          }
        }
        "folding" {
          folding::set_vim_foldenable [winfo parent $txtt] 1
        }
        default {
          return [do_operation $txtt numberstart]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, replaces the current character with the
  # next character.
  proc handle_r {txtt} {

    variable mode

    if {$mode($txtt) eq "command"} {
      set mode($txtt) "replace"
      record_start
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, replaces all characters until the escape
  # key is hit.
  proc handle_R {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        set mode($txtt) "replace_all"
        record_start
        return 1
      } elseif {$operator($txtt) eq "folding"} {
        folding::open_all_folds [winfo parent $txtt]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, puts the mode into "visual char" mode.
  proc handle_v {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          visual_mode $txtt char
        }
        "folding" {
          folding::show_line [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
        }
        default {
          set motion($txtt) "v"
          return 1
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, puts the mode into "visual line" mode.
  proc handle_V {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        visual_mode $txtt line
      } else {
        set motion($txtt) "V"
        return 1
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, add a cursor.
  proc handle_s {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        multicursor::add_cursor $txtt [$txtt index insert]
      } else {
        return [do_operation $txtt spaceend]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, add cursors between the current anchor
  # the current line.
  proc handle_S {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        multicursor::add_cursors $txtt [$txtt index insert]
      } else {
        return [do_operation $txtt spacestart]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, run the gui::insert_numbers procedure to
  # allow the user to potentially insert incrementing numbers into the
  # specified text widget.
  proc handle_numbersign {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        gui::insert_numbers $txtt
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # Moves the specified bracket one word to the right.
  proc move_bracket_right {txtt char} {

    if {[set index [$txtt search -forwards -- $char insert]] ne ""} {
      $txtt delete $index
      $txtt insert "$index wordend" $char
    }

  }

  ######################################################################
  # Inserts or moves the specified bracket pair.
  proc place_bracket {txtt left {right ""}} {

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
          move_bracket_right $txtt $left
        } else {
          $txtt insert "insert wordend"   $left
          $txtt insert "insert wordstart" $left
        }
      } else {
        set re "(\\$left|\\$right)"
        if {([set index [$txtt search -backwards -regexp -- $re insert]] ne "") && ([$txtt get $index] eq $left)} {
          move_bracket_right $txtt $right
        } else {
          $txtt insert "insert wordend"   $right
          $txtt insert "insert wordstart" $left
        }
      }

    }

    # Put ourselves back into start mode
    command_mode $txtt

  }

  ######################################################################
  # If any text is selected, double quotes are placed around all
  # selections.  If the insertion cursor is within a completed
  # string, the right-most quote of the completed string is moved one
  # word to the end; otherwise, the current word is placed within
  # double-quotes.
  proc handle_quotedbl {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      if {($operator($txtt) eq "change") && ($motion($txtt) eq "a")} {
        place_bracket $txtt \"
      }
      reset_state $txtt
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
  proc handle_apostrophe {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      if {($operator($txtt) eq "change") && ($motion($txtt) eq "a")} {
        place_bracket $txtt '
      }
      reset_state $txtt
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
  proc handle_bracketleft {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      if {($operator($txtt) eq "change") && ($motion($txtt) eq "a")} {
        place_bracket $txtt \[ \]
      }
      reset_state $txtt
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
  proc handle_braceleft {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list paragraph -dir prev -num [get_number $txtt]]]
      } elseif {($operator($txtt) eq "change") && ($motion($txtt) eq "a")} {
        place_bracket $txtt \{ \}
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles right curly bracket character.
  proc handle_braceright {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {($operator($txtt) eq "change") && ($motion($txtt) eq "a")} {
        return [do_operation $txtt [list paragraph -dir next -num [get_number $txtt]]]
      }
      reset_state $txtt
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
  proc handle_parenleft {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        puts "Going to previous sentence"
        catch {
        return [do_operation $txtt [list sentence -dir prev -num [get_number $txtt]]]
        } rc
        puts "rc: $rc"
      } elseif {($operator($txtt) eq "change") && ($motion($txtt) eq "a")} {
        place_bracket $txtt ( )
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles a parenthesis right motion.
  proc handle_parenright {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list sentence -dir next -num [get_number $txtt]]]
      }
      reset_state $txtt
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
  proc handle_less {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          set operator($txtt) "lshift"
          return 1
        }
        "change" {
          if {$motion($txtt) eq "a"} {
            place_bracket $txtt < >
          }
        }
        "lshift" {
          return [do_operation $txtt [list lineend -num [get_number $txtt]] linestart]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in start mode, begin a rshift mode.  If we are in
  # rshift mode, shift the current line right by one indent.
  proc handle_greater {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          set operator($txtt) "rshift"
          return 1
        }
        "rshift" {
          return [do_operation $txtt [list lineend -num [get_number $txtt]] linestart]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # When in start mode, if any text is selected, the selected code is
  # formatted; otherwise, if we are in start mode, we are transitioned to
  # format mode.  If we are in format mode, we format the currently selected
  # line only.
  proc handle_equal {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          if {[llength [set selected [$txtt tag ranges sel]]] > 0} {
            foreach {endpos startpos} [lreverse $selected] {
              indent::format_text $txtt $startpos $endpos
            }
          } else {
            set operator($txtt) "format"
          }
          return 1
        }
        "format" {
          return [do_operation $txtt [list lineend -num [get_number $txtt]] linestart]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" or "visual" mode, moves the insertion cursor to the first
  # non-whitespace character in the next line.
  proc handle_Return {txtt} {

    variable mode
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list firstchar -dir next -num [get_number $txtt]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Synonymous with the handle_Return command.
  proc handle_plus {txtt} {

    variable mode
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list firstchar -dir next -num [get_number $txtt]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" or "visual" mode, moves the insertion cursor to the first
  # non-whitespace character in the previous line.
  proc handle_minus {txtt} {

    variable mode
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list firstchar -dir prev -num [get_number $txtt]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" or "visual" mode, move the cursor to the given
  # column of the current line.
  proc handle_bar {txtt} {

    variable mode

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      return [do_operation $txtt [list column -num [get_number $txtt]]]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, change the case of the current character.
  proc handle_asciitilde {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq "g"} {
        set operator($txtt) "swap"
        return 1
      } elseif {$motion($txtt) eq ""} {
        set operator($txtt) "swap"
        return [do_operation $txtt [list char -dir next -num [get_number $txtt]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the cursor to the start of the middle
  # line.
  proc handle_M {txtt} {

    variable mode
    variable operator

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$operator($txtt) eq "folding"} {
        folding::close_all_folds [winfo parent $txtt]
      } else {
        return [do_operation $txtt screenmid]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, search for all occurences of the current
  # word.
  proc handle_asterisk {txtt} {

    variable mode

    if {$mode($txtt) eq "command"} {
      set word [$txtt get "insert wordstart" "insert wordend"]
      catch { ctext::deleteHighlightClass [winfo parent $txtt] search }
      array set theme [theme::get_syntax_colors]
      ctext::addSearchClass [winfo parent $txtt] search $theme(search_foreground) $theme(search_background) "" $word
      $txtt tag lower _search sel
      search::find_next [winfo parent $txtt]
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, sets the current mode to "record" mode.
  proc handle_q {txtt} {

    variable mode
    variable recording

    if {$mode($txtt) eq "command"} {
      set curr_reg $recording(curr_reg)
      if {($curr_reg ne "") && ($recording($curr_reg,mode) eq "record")} {
        record_stop $curr_reg
        reset_state $txtt
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
  proc handle_Q {txtt} {

    variable mode
    variable operator

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        set operator($txtt) "quit"
        return 1
      } elseif {$operator($txtt) eq "quit"} {
        gui::close_current -force 1
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, replays the register specified with the
  # next character.  If we are in "replay_reg" mode, playback the current
  # register again.
  proc handle_at {txtt} {

    variable mode

    if {$mode($txtt) eq "command"} {
      set mode($txtt) "playback_reg"
      return 1
    }

    return 0

  }

  ######################################################################
  # This is just a synonym for the 'l' command so we'll just call the
  # handle_l procedure instead of replicating the code.
  proc handle_space {txtt} {

    variable mode
    variable operator
    variable motion

    # Move the insertion cursor right one character
    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      set startargs ""
      switch [lindex $motion($txtt) end] {
        "V" {
          set startargs "linestart"
          set endargs   "lineend"
        }
        "v" {
          if {$operator($txtt) eq ""} {
            set endargs [list char -dir next -num [expr [get_number $txtt] + 1]]
          } else {
            set endargs [list dchar -dir next -num [expr [get_number $txtt] + 1]]
          }
        }
        default {
          if {$operator($txtt) eq ""} {
            set endargs [list char -dir next -num [get_number $txtt]]
          } else {
            set endargs [list dchar -dir next -num [get_number $txtt]]
          }
        }
      }
      return [do_operation $txtt $endargs $startargs]
    }

    return 0

  }

  ######################################################################
  # This is just a synonym for the 'h' command so we'll just call the
  # handle_h procedure instead of replicating the code.
  proc handle_BackSpace {txtt} {

    variable mode
    variable operator
    variable motion

    # Move the insertion cursor left one character
    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      set startargs ""
      switch [lindex $motion($txtt) end] {
        "V" {
          set startargs "linestart"
          set endargs   "lineend"
        }
        "v" {
          set startargs "right"
          if {$operator($txtt) eq ""} {
            set endargs   [list char -dir prev -num [get_number $txtt]]
          } else {
            set endargs [list dchar -dir prev -num [get_number $txtt]]
          }
        }
        default {
          if {$operator($txtt) eq ""} {
            set endargs [list char -dir prev -num [get_number $txtt]]
          } else {
            set endargs [list dchar -dir prev -num [get_number $txtt]]
          }
        }
      }
      return [do_operation $txtt $endargs $startargs]
    }

    return 0

  }

  ######################################################################
  # This is just a synonym for the 'l' command so we'll just call the
  # handle_l procedure instead of replicating the code.
  proc handle_Right {txtt} {

    return [handle_l $txtt]

  }

  ######################################################################
  # This is just a synonym for the 'h' command so we'll just call the
  # handle_h procedure instead of replicating the code.
  proc handle_Left {txtt} {

    return [handle_h $txtt]

  }

  ######################################################################
  # This is just a synonym for the 'k' command so we'll just call the
  # handle_k procedure instead of replicating the code.
  proc handle_Up {txtt} {

    return [handle_k $txtt]

  }

  ######################################################################
  # This is just a synonym for the 'j' command so we'll just call the
  # handle_j procedure instead of replicating the code.
  proc handle_Down {txtt} {

    return [handle_j $txtt]

  }

  ######################################################################
  # If we are in start mode, transition to the folding mode.
  proc handle_z {txtt} {

    variable mode
    variable operator

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$operator($txtt) eq ""} {
        set operator($txtt) "folding"
        return 1
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in goto mode, move the cursor to the last character of the
  # line.
  proc handle_underscore {txtt} {

    variable mode
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list firstchar -dir next -num [expr [get_number $txtt] - 1]]]
      } elseif {$motion($txtt) eq "g"} {
        return [do_operation $txtt [list lastchar -num [expr [get_number $txtt] - 1]]]
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # Moves the cursor to the end of the next word.
  proc handle_e {txtt} {

    variable mode
    variable operator
    variable motion

    if {($mode($txtt) eq "command") || [in_visual_mode $txtt]} {
      if {$operator($txtt) eq ""} {
        if {$motion($txtt) eq ""} {
          return [do_operation $txtt [list wordend -dir next -num [get_number $txtt]]]
        } elseif {$motion($txtt) eq "g"} {
          return [do_operation $txtt [list wordend -dir prev -num [get_number $txtt]]]
        }
      }
      reset_state $txtt
      return 1
    }

    return 0

  }

}
