# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2019  Trevor Williams (phase1geo@gmail.com)
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
  array set last_selection  {}
  array set modeline        {}
  array set findchar        {}

  array set multiplier      {}
  array set operator        {}
  array set motion          {}
  array set number          {}

  array set recording {
    mode     "none"
    curr_reg ""
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
  proc set_vim_mode_all {{value ""}} {

    variable command_entries

    if {$value ne ""} {
      set preferences::prefs(Editor/VimMode) $value
    }

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

    return [expr {[in_vim_mode $txtt] && (([get_edit_mode $txtt] ne "") || [$txtt cget -multimove])}]

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

    if {[preferences::get Editor/VimMode]} {
      set record ""
      if {[in_recording]} {
        set record ", REC\[ $recording(curr_reg) \]"
      }
      if {[info exists mode($txt.t)]} {
        switch $mode($txt.t) {
          "edit"         { return [format "%s%s" [msgcat::mc "INSERT MODE"] $record] }
          "visual:char"  { return [format "%s%s" [msgcat::mc "VISUAL MODE"] $record] }
          "visual:line"  { return [format "%s%s" [msgcat::mc "VISUAL LINE MODE"] $record] }
          "visual:block" { return [format "%s%s" [msgcat::mc "VISUAL BLOCK MODE"] $record] }
          default        {
            if {[$txt.t cget -multimove]} {
              return [msgcat::mc "MULTIMOVE MODE"]
            } else {
              return [format "%s%s" [msgcat::mc "COMMAND MODE"] $record]
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

    variable recording

    # Get the last txt widget that had the focus
    set txt [gui::last_txt_focus]

    # Get the value from the command field
    set value [$w get]

    # Save the value as a recording
    set recording(:,events) $value

    # Delete the value in the command entry
    $w delete 0 end

    # Execute the colon command
    set txt [handle_colon_command $txt $value]

    # Remove the grab
    grab release $w

    if {$txt ne ""} {

      # Hide the command entry widget
      gui::panel_forget $w

      # Set the focus back to the text widget
      gui::set_txt_focus $txt

    }

  }

  ######################################################################
  # Parses and executes the colon command value.
  proc handle_colon_command {txt value} {

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
          if {[regexp {^((\d+|[.^$]|\w+),(\d+|[.^$]|\w+))?s/(.*)/(.*)/([giI]*)$} $value -> dummy from to search replace opts]} {
            set ranges [list]
            if {$dummy eq ""} {
              if {[set ranges [$txt tag ranges sel]] eq ""} {
                set ranges [list [$txt index "insert linestart"] [$txt index "insert lineend"]]
              }
            } else {
              set ranges [list [get_linenum $txt $from] [$txt index "[get_linenum $txt $to] lineend-1c"]]
            }
            foreach {from to} $ranges {
              search::replace_do_raw $from $to $search $replace "regexp" \
                [expr [string first "i" $opts] != -1] [expr [string first "g" $opts] != -1]
            }

          # Delete/copy lines
          } elseif {[regexp {^(\d+|[.^$]|\w+),(\d+|[.^$]|\w+)([dy])$} $value -> from to cmd]} {
            set from [get_linenum $txt $from]
            set to   [$txt index "[get_linenum $txt $to] lineend"]
            clipboard clear
            clipboard append [$txt get $from $to]
            if {$cmd eq "d"} {
              $txt delete $from $to
            }
            cliphist::add_from_clipboard

          # Jump to line
          } elseif {[regexp {^(\d+|[.^$]|\w+)$} $value]} {
            $txt cursor set [get_linenum $txt $value]

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
            gui::get_info $txt txt tab
            if {$marker ne ""} {
              if {[set tag [ctext::linemapSetMark $txt $line]] ne ""} {
                markers::add $tab tag $tag $marker
                gui::update_tab_markers $tab
              }
            } else {
              markers::delete_by_line $tab $line
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

    return $txt

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

    set txt [gui::current_txt]

    # Get the current mode
    set curr [indent::get_indent_mode $txt]

    # If the indentation mode will change, set it to the new value
    if {$curr ne $newval($curr,$type,$value)} {
      $txt configure -indentmode $newval($curr,$type,$value)
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
      marker 1
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
    set lang [ctext::getLang $txt insert]

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
      [gui::current_txt].t configure -shiftwidth $val
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
      gui::show_split_pane [gui::get_info {} current tab]
    } else {
      gui::hide_split_pane [gui::get_info {} current tab]
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
  proc set_cursor {txtt index} {

    if {[in_visual_mode $txtt]} {
      if {[set cursors [$txtt cursor get]] eq ""} {
        $txtt cursor set [set index [$txtt index $index]]
        adjust_select $txtt 0 $index
      } else {
        $txtt cursor set $index
        for {set i 0} {$i < [llength $cursors]} {incr i} {
          adjust_select $txtt $i $index
        }
      }
    } else {
      $txtt cursor set $index
    }

  }

  ######################################################################
  # Adjust the current selection if we are in visual mode.
  proc adjust_select {txtt cindex tindex} {

    variable mode
    variable select_anchors
    variable seltype

    # Get the visual type from the mode
    set type [lindex [split $mode($txtt) :] 1]

    # Get the anchor for the given selection
    set anchor [lindex $select_anchors($txtt) $cindex]

    if {$type eq "block"} {
      if {$seltype eq "exclusive"} {
        select::handle_block_selection $txtt $anchor [$txtt index $tindex]
      } else {
        select::handle_block_selection $txtt $anchor [$txtt index $tindex+1c]
      }
    } elseif {[$txtt compare $anchor < $tindex]} {
      if {$type eq "line"} {
        $txtt tag add sel "$anchor linestart" "$tindex lineend"
      } elseif {$seltype eq "exclusive"} {
        $txtt tag add sel $anchor $tindex
      } else {
        $txtt tag add sel $anchor $tindex+1c
      }
    } else {
      if {$type eq "line"} {
        $txtt tag add sel "$tindex linestart" "$anchor lineend"
      } elseif {$seltype eq "exclusive"} {
        $txtt tag add sel $tindex $anchor
      } else {
        $txtt tag add sel $tindex $anchor+1c
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

    gui::get_info $txt txt tab

    if {$char eq "."} {
      return [$txt index "insert linestart"]
    } elseif {$char eq "^"} {
      return "1.0"
    } elseif {$char eq "$"} {
      return [$txt index "end linestart"]
    } elseif {[set index [markers::get_index $tab $char]] ne ""} {
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
    variable recording
    variable operator
    variable motion
    variable findchar

    # Change the cursor to the block cursor
    $txt configure -blockcursor true -insertwidth 1 -multimove 0

    # Put ourselves into start mode
    set mode($txt.t)             "command"
    set number($txt.t)           ""
    set multiplier($txt.t)       ""
    set search_dir($txt.t)       "next"
    set column($txt.t)           ""
    set select_anchors($txt.t)   [list]
    set modeline($txt.t)         1
    set operator($txt.t)         ""
    set motion($txt.t)           ""
    set findchar($txt.t)         [list]

    # Add bindings
    bind vim$txt <Escape>                [list vim::handle_escape %W break]
    bind vim$txt <Key>                   [list vim::handle_any %W %k %A %K break]
    bind vim$txt <Control-Button-1>      [list vim::nil]
    bind vim$txt <Shift-Button-1>        [list vim::nil]
    # bind vim$txt <Button-1>              "vim::handle_button1 %W %x %y; break"
    bind vim$txt <Double-Shift-Button-1> [list vim::nil]
    # bind vim$txt <Double-Button-1>       "vim::handle_double_button1 %W %x %y; break"
    bind vim$txt <Triple-Button-1>       [list vim::nil]
    bind vim$txt <Triple-Shift-Button-1> [list vim::nil]
    # bind vim$txt <B1-Motion>             "vim::handle_motion %W %x %y; break"

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
    variable findchar

    unset -nocomplain command_entries($txt.t)
    unset -nocomplain mode($txt.t)
    unset -nocomplain number($txt.t)
    unset -nocomplain multiplier($txt.t)
    unset -nocomplain search_dir($txt.t)
    unset -nocomplain column($txt.t)
    unset -nocomplain select_anchors($txt.t)
    unset -nocomplain modeline($txt.t)
    unset -nocomplain findchar($txt.t)

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
    set_cursor $W $current

    focus $W

  }

  ######################################################################
  # Handles a double-left-click event when in Vim mode.
  proc handle_double_button1 {W x y} {

    $W tag remove sel 1.0 end

    set current [$W index @$x,$y]
    set_cursor $W [$W index "$current wordstart"]

    $W tag add sel [$W index "$current wordstart"] [$W index "$current wordend"]

    focus $W

  }

  ######################################################################
  # Handle left-button hold motion event when in Vim mode.
  proc handle_motion {W x y} {

    $W tag remove sel 1.0 end

    set current [$W index @$x,$y]
    set_cursor $W $current

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
    $txt configure -blockcursor false -autoseparators 1 -multimove 1 -insertwidth [preferences::get Appearance/CursorWidth]

  }

  ######################################################################
  # Resets the operator/motion states.
  proc reset_state {txtt err} {

    variable operator
    variable motion
    variable multiplier
    variable number

    # Stop recording
    record_stop 0

    # Clear the state information
    set operator($txtt)   ""
    set motion($txtt)     ""
    set multiplier($txtt) ""
    set number($txtt)     ""

    # Add a separator
    $txtt edit separator

  }

  ######################################################################
  # Sets the operator.
  proc set_operator {txtt op keysyms} {

    variable operator

    # Set operator
    set operator($txtt) $op

    # Start recording
    if {[$txtt tag ranges sel] eq ""} {
      record_start $txtt $keysyms
    }

  }

  ######################################################################
  # Set the current mode to the "edit" mode.
  proc edit_mode {txtt} {

    variable mode

    # Set the mode to the edit mode
    set mode($txtt) "edit"

    # Clear multimove mode
    disable_multimove $txtt

    # Set the blockcursor to false
    $txtt configure -blockcursor false -insertwidth [preferences::get Appearance/CursorWidth] -multimove 1

  }

  ######################################################################
  # Saves the last selection in case the user wants to use it again.
  proc set_last_selection {txtt} {

    variable mode
    variable last_selection

    if {[info exists mode($txtt)]} {
      set last_selection($txtt) [list $mode($txtt) [$txtt tag ranges sel]]
    }

  }

  ######################################################################
  # Set the current mode to the "command" mode.
  proc command_mode {txtt} {

    variable mode
    variable operator

    # If we are coming from visual mode, clear the selection and the anchors
    if {[$txtt tag ranges sel] ne ""} {
      set_last_selection $txtt
      $txtt tag remove sel 1.0 end
    }

    # If were in the edit or replace_all state, move the insertion cursor back
    # one character.
    if {(($mode($txtt) eq "edit") || \
         ([string compare -length 7 $mode($txtt) "replace"] == 0) || \
         (($operator($txtt) eq "delete") && [$txtt is lineend cursor])) && \
        ![$txtt is linestart cursor]} {
      $txtt cursor set left
    }

    # Set the blockcursor to true
    $txtt configure -blockcursor true -insertwidth 1 -multimove 0

    # Set the current mode to the command mode
    set mode($txtt) "command"

    # Clear multimove mode
    disable_multimove $txtt

    # Reset the states
    reset_state $txtt 0

  }

  ######################################################################
  # Set the current mode to multicursor move mode.
  proc multimove_mode {txtt} {

    variable mode

    # Effectively make the insertion cursor disappear
    $txtt configure -multimove 1

    # Make sure that the status bar is updated properly
    gui::update_position [winfo parent $txtt]

  }

  ######################################################################
  # Turns off multicursor move mode.
  proc disable_multimove {txtt} {

    variable mode

    # If we are in multimove mode, get out of multimove
    $txtt configure -multimove 0

    # Make sure that the status bar is updated properly
    gui::update_position [winfo parent $txtt]

  }

  ######################################################################
  # Set the current mode to the "visual" mode.
  proc visual_mode {txtt type} {

    variable mode
    variable select_anchors
    variable seltype
    variable last_selection

    # If we are called with the type of "last", set the selection
    if {$type eq "last"} {
      if {$last_selection($txtt) ne ""} {
        lassign $last_selection($txtt) vmode sel
        set mode($txtt) $vmode
        ::tk::TextSetCursor $txtt "[lindex $sel 1]-1c"
        $txtt tag remove sel 1.0
        $txtt tag add sel {*}$sel
      }
      return
    }

    # Set the current mode
    set mode($txtt) "visual:$type"

    # Clear the current selection
    $txtt tag remove sel 1.0 end

    # Initialize the select range
    if {[$txtt cursor enabled]} {
      set select_anchors($txtt) [list]
      foreach {start end} [$txtt tag ranges mcursor] {
        lappend select_anchors($txtt) $start
      }
      $txtt configure -multimove 1
    } else {
      set select_anchors($txtt) [$txtt index insert]
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

    # Make sure that the mode is updated in the status bar
    gui::update_position [winfo parent $txtt]

  }

  ######################################################################
  # Returns true if we are in visual mode.
  proc in_visual_mode {txtt} {

    variable mode

    return [expr {[lindex [split $mode($txtt) :] 0] eq "visual"}]

  }

  ######################################################################
  # Starts recording keystrokes.
  proc record_start {txtt {keysyms {}} {reg ""}} {

    variable recording
    variable multiplier

    if {$recording(mode) eq "none"} {
      set recording(mode)   "record"
      set recording(num)    $multiplier($txtt)
      set recording(events) $keysyms
      if {($recording(curr_reg) eq "") && ($reg ne "")} {
        set recording($reg,events) [list]
        set recording(curr_reg)    $reg
      }
    }

  }

  ######################################################################
  # Stops recording keystrokes.
  proc record_stop {reg_stop} {

    variable recording

    set recording(mode) "none"

    if {[set reg $recording(curr_reg)] ne ""} {
      lappend recording($reg,events) {*}$recording(events)
      if {$reg_stop} {
        set recording(curr_reg) ""
      }
    }

  }

  ######################################################################
  # Records a signal event and stops recording.
  proc record {txtt keysyms {reg ""}} {

    variable recording
    variable multiplier

    if {$recording(mode) eq "none"} {
      set recording(events) $keysyms
      set recording(num)    $multiplier($txtt)
      if {$recording(curr_reg) ne ""} {
        lappend recording($reg,events) {*}$recording(events)
      }
    }

  }

  ######################################################################
  # Adds an event to the recording buffer if we are in record mode.
  proc record_add {keysym} {

    variable recording

    if {$recording(mode) eq "record"} {
      lappend recording(events) $keysym
    }

  }

  ######################################################################
  # Returns true if we are currently in a user-recording state.
  proc in_recording {} {

    variable recording

    return [expr {$recording(curr_reg) ne ""}]

  }

  ######################################################################
  # Plays back the record buffer.
  proc playback {txtt {reg ""}} {

    variable recording
    variable multiplier

    # Set the record mode to playback
    set recording(mode) "playback"

    if {$reg eq ""} {

      # Sets the number to use prior to the sequence
      set num [expr {($multiplier($txtt) ne "") ? $multiplier($txtt) : $recording(num)}]

      # Clear the multiplier
      set multiplier($txtt) ""

      # Add the numerical value
      foreach event [split $num {}] {
        event generate $txtt <Key> -keysym $event
      }

      set events "events"

    } else {

      set events "$reg,events"

    }

    # Replay the recording buffer
    foreach event $recording($events) {
      event generate $txtt <Key> -keysym $event
    }

    # Set the record mode to none
    set recording(mode) "none"

  }

  ######################################################################
  # Performs the last colon command operation.
  proc playback_colon {txtt} {

    variable recording

    if {[info exists recording(:,events)] && ($recording(:,events) ne "")} {
      handle_colon_command [winfo parent $txtt] $recording(:,events)
    }

  }

  ######################################################################
  # Stops recording and clears the recording array.
  proc record_clear {{reg ""}} {

    variable recording

    set recording(mode)        "none"
    set recording(num)         ""
    set recording(events)      [list]
    set recording($reg,num)    ""
    set recording($reg,events) [list]

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
  # Handles the escape-key when in Vim mode.
  proc handle_escape {txtt {retcode ok}} {

    variable mode
    variable recording

    if {$mode($txtt) ne "command"} {

      # Add to the recording if we are doing so
      record_add Escape

      # Set the mode to command
      command_mode $txtt

    } else {

      # Clear the any selections
      $txtt tag remove sel 1.0 end

      # If were in start mode, clear the auto recording buffer
      record_clear

      # Clear any searches
      search::find_clear

      # Clear the state
      reset_state $txtt 1

    }

    # If we are in multimove mode, disable it
    if {[$txtt cget -multimove]} {
      disable_multimove $txtt

    # Otherwise, get out of multicursor mode
    } else {
      $txtt cursor disable
    }

    return -code $retcode 1

  }

  if {[tk windowingsystem] eq "aqua"} {
    proc get_keysym {keycode keysym} {
      return $utils::code2sym([expr $keycode & 0xffff])
    }
  } else {
    proc get_keysym {keycode keysym} { return $keysym }
  }

  ######################################################################
  # Handles any single printable character.
  proc handle_any {txtt keycode char keysym {retcode ok}} {

    variable mode
    variable operator
    variable column
    variable recording

    # Lookup the keysym
    if {[catch { get_keysym $keycode $keysym } keysym]} {
      return 0

    # If the key does not have a printable char representation, quit now
    } elseif {([string compare -length 5 $keysym "Shift"]   == 0) || \
              ([string compare -length 7 $keysym "Control"] == 0) || \
              ([string compare -length 3 $keysym "Alt"]     == 0) || \
              ($keysym eq "??")} {
      return 0
    }

    # Record the character
    record_add $keysym

    # If the current character needs to be used by the current mode, handle it now
    if {[info procs do_mode_$mode($txtt)] ne ""} {
      if {![catch { do_mode_$mode($txtt) $txtt $keysym $char } rc]} {
        return $rc
      }
    }

    # If we are handling a motion based on a character, handle it
    if {[handle_find_motion $txtt $char]} {
      return -code $retcode 1
    } elseif {[handle_between_motion $txtt $char]} {
      return -code $retcode 1
    }

    # If the keysym is neither j or k, clear the column
    if {($keysym ne "j") && ($keysym ne "k")} {
      set column($txtt) ""
    }

    # Handle the command
    if {[info procs handle_$keysym] ne ""} {
      if {![catch { handle_$keysym $txtt } rc] && $rc} {
        return -code $retcode 1
      }
    } elseif {[string is integer $keysym] && [handle_number $txtt $char]} {
      return -code $retcode 1
    }

    # Reset the state
    reset_state $txtt 1

    return -code $retcode 1

  }

  ######################################################################
  # Called by handle_any when the current mode is edit.
  proc do_mode_edit {txtt keysym char} {

    return 0

  }

  ######################################################################
  # Called by handle_any when the current mode is replace.
  proc do_mode_replace {txtt keysym char} {

    # Replace the current character with the given character
    do_replace $txtt $char

    # Change our mode back to command mode
    command_mode $txtt

    return 1

  }

  ######################################################################
  # Called by handle_any when the current mode is replace_all.
  proc do_mode_replace_all {txtt keysym char} {

    # Replace the current character with the given character
    do_replace $txtt $char

    return 1

  }

  ######################################################################
  # Called by handle_any when the current mode is record_reg.  Parses
  # character for a valid recording register.
  proc do_mode_record_reg {txtt keysym char} {

    # Set the mode to command
    command_mode $txtt

    # Parse the given character to see if it is a matching register name
    if {[regexp {^[a-zA-Z\"]$} $keysym]} {
      record_start $txtt {} $keysym
      return 1
    }

    return -code error "Unexpected recording register"

  }

  ######################################################################
  # Called by handle_any when the current mode is playback_reg.  Parses
  # the character for a valid playback register.
  proc do_mode_playback_reg {txtt keysym char} {

    # Set the mode to command
    command_mode $txtt

    if {[regexp {^[a-z]$} $keysym]} {
      playback $txtt $keysym
      return 1
    } elseif {$keysym eq "at"} {
      if {$recording(curr_reg) ne ""} {
        playback $txtt $recording(curr_reg)
      }
      return 1
    } elseif {$keysym at "colon"} {
      for {set i 0} {$i < [get_number $txtt]} {incr i} {
        playback_colon $txtt
      }
      return 1
    }

    return -code error "Unexpected playback register"

  }

  ######################################################################
  # Perform text replacement.
  proc do_replace {txtt char} {

    $txtt replace insert "insert+1c" $char

  }

  ######################################################################
  # Determines the operation cursor based on the current mode and returns it.
  proc get_operation_cursors {txtt precursor postcursor} {
    variable motion
    if {[set sel [$txtt tag ranges sel]] ne ""} {
      set precursor  [list -cursor cursor]
      set postcursor [lindex $sel 0]
    } elseif {$precursor ne ""} {
      set precursor [list -cursor $precursor]
    }
    return [list $precursor $postcursor]
  }

  ######################################################################
  # Performs the current motion-specific operation on the text range specified
  # by startpos/endpos.
  #
  # Options:
  #   -precursor  cursorspec  Sets the cursor based on the starting position(s) before the operation
  #   -postcursor cursorpsec  Sets the cursor based on the cursor position after the operation
  #   -object     (0|1)       Specifies if we are operating on an object
  proc do_operation {txtt eposargs {sposargs cursor} args} {

    variable mode
    variable operator
    variable motion
    variable multiplier
    variable number

    array set opts {
      -precursor  ""
      -postcursor ""
      -object     0
    }
    array set opts $args

    set object $opts(-object)
    lassign [get_operation_cursors $txtt $opts(-precursor) $opts(-postcursor)] precursor postcursor

    switch $operator($txtt) {
      "" {
        if {[$txtt cget -multimove]} {
          if {[in_visual_mode $txtt]} {
            $txtt cursor select $eposargs
          } else {
            $txtt cursor move $eposargs
          }
        } elseif {$opts(-object)} {
          if {$sposargs ne "cursor"} {
            $txtt cursor set $sposargs
            visual_mode $txtt char
            set_cursor $txtt [$txtt index {*}$eposargs]
          }
        } else {
          set_cursor $txtt [$txtt index {*}$eposargs]
        }
        reset_state $txtt 0
        return 1
      }
      "delete" {
        if {[string range [lindex $eposargs 0] 0 4] ne "space"} {
          $txtt copy $sposargs $eposargs
        }
        $txtt delete -object $object $sposargs $eposargs
        # $txtt delete -indent 0 -object $object $sposargs $eposargs   ;# We might want this since we are not in edit mode
        if {$postcursor ne ""} {
          $txtt cursor set $opts(-postcursor)
        }
        command_mode $txtt
        return 1
      }
      "change" {
        $txtt delete -indent 0 -object $object $sposargs $eposargs
        edit_mode $txtt
        set operator($txtt)   ""
        set motion($txtt)     ""
        set multiplier($txtt) ""
        set number($txtt)     ""
        return 1
      }
      "yank" {
        $txtt copy -object $object $sposargs $eposargs
        if {$postcursor ne ""} {
          $txtt cursor set $postcursor
        }
        command_mode $txtt
        return 1
      }
      "swap" {
        $txtt transform -object $object {*}$precursor $sposargs $eposargs toggle_case
        if {($precursor eq "") && ($postcursor ne "")} {
          $txtt cursor set $postcursor
        }
        command_mode $txtt
        return 1
      }
      "upper" {
        $txtt transform -object $object {*}$precursor $sposargs $eposargs upper_case
        if {($precursor eq "") && ($postcursor ne "")} {
          $txtt cursor set $postcursor
        }
        command_mode $txtt
        return 1
      }
      "lower" {
        $txtt transform -object $object {*}$precursor $sposargs $eposargs lower_case
        if {($precursor eq "") && ($postcursor ne "")} {
          $txtt cursor set $postcursor
        }
        command_mode $txtt
        return 1
      }
      "rot13" {
        $txtt transform -object $object {*}$precursor $sposargs $eposargs rot13
        if {($precursor eq "") && ($postcursor ne "")} {
          $txtt cursor set $postcursor
        }
        command_mode $txtt
        return 1
      }
      "format" {
        $txtt indent auto $sposargs $eposargs
        $txtt cursor move [list firstchar -num 0]
        command_mode $txtt
        return 1
      }
      "lshift" {
        $txtt indent left $sposargs $eposargs
        $txtt cursor move [list firstchar -num 0]
        command_mode $txtt
        return 1
      }
      "rshift" {
        $txtt indent right $sposargs $eposargs
        $txtt cursor move [list firstchar -num 0]
        command_mode $txtt
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Perform the current operation on the given object.
  proc do_object_operation {txtt object} {

    variable operator
    variable motion

    # Execute the operation
    switch $motion($txtt) {
      "a" {   ;# Inclusive
        if {[in_visual_mode $txtt] || ($operator($txtt) ne "")} {
          set num [get_number $txtt]
          return [do_operation $txtt [list blockend -type $object -num $num -adjust +1c] [list blockstart -type $object -num $num] -object 1]
        }
      }
      "i" {   ;# Exclusive
        if {[in_visual_mode $txtt] || ($operator($txtt) ne "")} {
          set num [get_number $txtt]
          return [do_operation $txtt [list blockend -type $object -num $num] [list blockstart -type $object -num $num -adjust "+1c"] -object 1]
        }
      }
    }

    reset_state $txtt 0

    return 1

  }

  ######################################################################
  # Checks the current mode and if we are in a find character motion,
  # handle the action.
  proc handle_find_motion {txtt char} {

    variable motion
    variable findchar

    # If the current mode does not pertain to us, return now
    if {[lsearch {t f} [string tolower $motion($txtt)]] == -1} {
      return 0
    }

    # Get the motion information
    set dir  [expr {[string is lower $motion($txtt)] ? "next" : "prev"}]
    set excl [expr {[string tolower $motion($txtt)] eq "t"}]

    # Remember the findchar motion
    set findchar($txtt) [list $char $dir $excl]

    return [do_find_motion $txtt $char $dir $excl]

  }

  ######################################################################
  # Perform the find motion operation with the given information.
  proc do_find_motion {txtt char dir excl} {

    variable operator

    # Determine where to put the cursor
    set postcursor ""
    if {($dir eq "prev") && ($operator($txtt) ne "delete")} {
      set postcursor [list findchar -dir prev -char $char -num [get_number $txtt] -exclusive $excl]
    }

    set spec [list findchar -dir $dir -char $char -num [get_number $txtt] -exclusive $excl]

    if {$dir eq "prev"} {
      return [do_operation $txtt $spec cursor -precursor cursor -postcursor $postcursor]
    } elseif {$operator($txtt) eq ""} {
      return [do_operation $txtt [list {*}$spec -adjust -1c] cursor -precursor cursor -postcursor $postcursor]
    } else {
      return [do_operation $txtt $spec cursor -precursor cursor]
    }

  }

  ######################################################################
  # Checks the current mode and if we are in a between character motion,
  # handle the action.
  proc handle_between_motion {txtt char} {

    variable motion

    # TBD - We have some work to do here to support between characters
    return 0

    return [do_operation $txtt [list betweenchar -dir prev -char $char] [list betweenchar -dir next -char $char]]

  }

  ######################################################################
  # If we are in "command" mode, the number is 0 and the current number
  # is empty, set the insertion cursor to the beginning of the line;
  # otherwise, append the number current to number value.
  proc handle_number {txtt num} {

    variable motion
    variable number
    variable multiplier

    if {($multiplier($txtt) eq "") && ($num eq "0")} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt linestart]
      } elseif {$motion($txtt) eq "g"} {
        return [do_operation $txtt dispstart]
      }
    } else {
      append multiplier($txtt) $num
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in the "command" mode, display the command entry field and
  # give it the focus.
  proc handle_colon {txtt} {

    variable motion
    variable command_entries

    if {$motion($txtt) eq ""} {
      $command_entries($txtt) configure \
        -background [$txtt cget -background] -foreground [$txtt cget -foreground] \
        -insertbackground [$txtt cget -insertbackground] -font [$txtt cget -font]
      gui::panel_place $command_entries($txtt)
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

    variable operator
    variable motion

    if {$motion($txtt) eq ""} {
      if {$operator($txtt) eq ""} {
        return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1] -exclusive 1]]
      } else {
        return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]]]
      }
    } elseif {$motion($txtt) eq "g"} {
      return [do_operation $txtt [list dispend -num [expr [get_number $txtt] - 1]]]
    }

    return 0

  }

  ######################################################################
  # If we are in the "command" mode, move insertion cursor to the beginning
  # of the current line.  If we are in "delete" mode, delete all of the
  # text between the beginning of the current line and the current
  # insertion marker.
  proc handle_asciicircum {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
      return [do_operation $txtt [list firstchar -num 0]]
    } elseif {$motion($txtt) eq "g"} {
      return [do_operation $txtt dispfirst]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, display the search bar.
  proc handle_slash {txtt} {

    variable motion
    variable search_dir

    if {$motion($txtt) eq ""} {
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

    variable operator
    variable motion
    variable search_dir

    switch $operator($txtt) {
      "" {
        if {$motion($txtt) eq ""} {
          gui::search "prev"
          set search_dir($txtt) "prev"
        } elseif {$motion($txtt) eq "g"} {
          set_operator $txtt "rot13" {g question}
          set motion($txtt)   ""
          if {[$txtt tag ranges sel] ne ""} {
            return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart]
          }
          return 1
        }
      }
      "rot13" {
        return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart -postcursor linestart]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, invokes the buffered command at the current
  # insertion point.
  proc handle_period {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
      set start_index [$txtt index insert]
      playback $txtt
      set end_index [$txtt index insert]
      if {$start_index != $end_index} {
        if {[$txtt compare $start_index < $end_index]} {
          $txtt syntax highlight $start_index $end_index
        } else {
          $txtt syntax highlight $end_index $start_index
        }
      }
      reset_state $txtt 0
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode and the insertion point character has a
  # matching left/right partner, display the partner.
  proc handle_percent {txtt} {

    variable multiplier

    if {$multiplier($txtt) eq ""} {
      gui::show_match_pair
    } else {
      set lines [lindex [split [$txtt index end] .] 0]
      set line  [expr int( ($multiplier($txtt) * $lines + 99) / 100 )]
      return [do_operation $txtt [list linenum -num $line]]
    }

    return 0

  }

  ######################################################################
  # Handles the i-key when in Vim mode.
  proc handle_i {txtt} {

    variable operator
    variable motion

    switch $operator($txtt) {
      "" {
        if {![in_visual_mode $txtt]} {
          edit_mode $txtt
          record_start $txtt "i"
        } else {
          set motion($txtt) i
        }
        return 1
      }
      "folding" {
        if {![in_visual_mode $txtt]} {
          folding::set_vim_foldenable [winfo parent $txtt] [expr [folding::get_vim_foldenable [winfo parent $txtt]] ^ 1]
        }
      }
      default {
        if {$motion($txtt) eq ""} {
          set motion($txtt) "i"
          return 1
        }
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, inserts at the beginning of the current
  # line.
  proc handle_I {txtt} {

    variable operator

    if {$operator($txtt) eq ""} {
      ::tk::TextSetCursor $txtt "insert linestart"
      edit_mode $txtt
      record_start $txtt "I"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor down one line.
  proc handle_j {txtt} {

    variable column
    variable operator

    # Move the insertion cursor down one line
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
        record $txtt J
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor up one line.
  proc handle_k {txtt} {

    variable column
    variable operator

    set num [get_number $txtt]

    # Move the insertion cursor up one line
    switch $operator($txtt) {
      "folding" {
        folding::jump_to [winfo parent $txtt] prev [get_number $txtt]
      }
      "folding:range" {
        folding::close_range [winfo parent $txtt] [$txtt index up -num [get_number $txtt] -column vim::column($txtt)] insert
        $txtt cursor set [list "insert-1 display lines"]
      }
      default {
        return [do_operation $txtt [list up -num [get_number $txtt] -column vim::column($txtt)]]
      }
    }

    return 0

  }

  ######################################################################
  # Search documentation for the current language with the current word.
  proc handle_K {txtt} {

    variable operator

    if {$operator($txtt) eq ""} {
      if {[set word [string trim [$txtt get "insert wordstart" "insert wordend"]]] ne ""} {
        search::search_documentation -str $word
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor right one
  # character.
  proc handle_l {txtt} {

    variable motion

    # Move the insertion cursor right one character
    set startargs cursor
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

    return [do_operation $txtt $endargs $startargs -precursor cursor]

  }

  ######################################################################
  # If we are in "command" mode, jump the insertion cursor to the bottom
  # line.
  proc handle_L {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
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

    variable operator
    variable motion

    if {$operator($txtt) eq "folding"} {
      if {![folding::close_selected [winfo parent $txtt]]} {
        set operator($txtt) "folding:range"
        return 1
      }
    } else {
      if {$motion($txtt) eq ""} {
        set motion($txtt) "f"
        return 1
      } elseif {$motion($txtt) eq "g"} {
        if {[$txtt cursor enabled]} {
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

    return 0

  }

  ######################################################################
  # Handles any previous find character motions.
  proc handle_F {txtt} {

    variable operator
    variable motion

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

    return 0

  }

  ######################################################################
  # Handles any next find character (non-inclusive) motions.
  proc handle_t {txtt} {

    variable operator
    variable motion

    switch $motion($txtt) {
      "" {
        set motion($txtt) "t"
        return 1
      }
      default {
        return [do_object_operation $txtt tag]
      }
    }

    return 0

  }

  ######################################################################
  # Handles any next find character (non-inclusive) motions.
  proc handle_T {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
      set motion($txtt) "T"
      return 1
    }

    return 0

  }

  ######################################################################
  # Repeats the last findchar motion.
  proc handle_semicolon {txtt} {

    variable operator
    variable motion
    variable findchar

    if {$motion($txtt) eq ""} {
      if {$findchar($txtt) ne ""} {
        lassign $findchar($txtt) char dir excl
        return [do_find_motion $txtt $char $dir $excl]
      }
      return 1
    } elseif {$motion($txtt) eq "g"} {
      gui::jump_to_cursor [expr 0 - [get_number $txtt]] 1
      set motion($txtt) ""
      return 1
    }

    return 0

  }

  ######################################################################
  # Repeats the last findchar motion in the opposite direction.
  proc handle_comma {txtt} {

    variable operator
    variable motion
    variable findchar

    if {$motion($txtt) eq ""} {
      if {$findchar($txtt) ne ""} {
        lassign $findchar($txtt) char dir excl
        set dir [expr {($dir eq "next") ? "prev" : "next"}]
        return [do_find_motion $txtt $char $dir $excl]
      }
      return 1
    } elseif {$motion($txtt) eq "g"} {
      gui::jump_to_cursor [get_number $txtt] 1
      set motion($txtt) ""
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, edit any filenames found under any of
  # the cursors.
  proc handle_g {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
      set motion($txtt) "g"
      return 1
    } elseif {$motion($txtt) eq "g"} {
      return [do_operation $txtt first]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor left one
  # character.
  proc handle_h {txtt} {

    variable motion
    variable operator

    # Move the insertion cursor left one character
    set startargs cursor
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

    if {$operator($txtt) eq "delete"} {
      set cursorargs [list]
    } else {
      set cursorargs [list -postcursor [list left -num [get_number $txtt]]]
    }

    return [do_operation $txtt $endargs $startargs {*}$cursorargs]

  }

  ######################################################################
  # If we are just in "command" mode, jump to the top line of the editor.
  proc handle_H {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
      return [do_operation $txtt screentop]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the insertion cursor to the beginning
  # of previous word.
  proc handle_b {txtt} {

    variable motion

    switch $motion($txtt) {
      "" {
        return [do_operation $txtt [list wordstart -dir prev -num [get_number $txtt] -exclusive 1]]
      }
      default {
        return [do_object_operation $txtt paren]
      }
    }

    return 0

  }

  ######################################################################
  # Move counts WORDs backward.
  proc handle_B {txtt} {

    variable motion

    switch $motion($txtt) {
      "" {
        return [do_operation $txtt [list WORDstart -dir prev -num [get_number $txtt] -exclusive 1]]
      }
      default {
        return [do_object_operation $txtt curly]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, change the state to "change" mode.  If
  # we are in the "change" mode, delete the current line and put ourselves
  # into edit mode.
  proc handle_c {txtt} {

    variable operator

    switch $operator($txtt) {
      "" {
        if {[edit::delete_selected $txtt 0]} {
          edit_mode $txtt
        } else {
          set_operator $txtt "change" {c}
          return 1
        }
      }
      "change" {
        return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart]
      }
      "folding" {
        folding::close_fold [get_number $txtt] [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, delete from the insertion cursor to the
  # end of the line and put ourselves into "edit" mode.
  proc handle_C {txtt} {

    variable operator

    if {$operator($txtt) eq ""} {
      if {[edit::delete_selected $txtt 1]} {
        edit_mode $txtt
      } else {
        $txtt delete insert "insert lineend"
        edit_mode $txtt
        record_start $txtt "C"
      }
      return 1
    } elseif {$operator($txtt) eq "folding"} {
      folding::close_fold 0 [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
    }

    return 0

  }

  ######################################################################
  # If we are in "change" mode, delete the current word and change to edit
  # mode.
  proc handle_w {txtt} {

    variable operator
    variable motion

    switch $motion($txtt) {
      "" {
        switch $operator($txtt) {
          ""       { return [do_operation $txtt [list wordstart -dir next -num [get_number $txtt] -exclusive 1]] }
          "change" {
            set num [get_number $txtt]
            if {[string is space [$txtt get insert]]} {
              return [do_operation $txtt [list wordstart -dir next -num $num -exclusive 1]]
            } else {
              return [do_operation $txtt [list wordend -dir next -num $num -exclusive 0]]
            }
          }
          default { return [do_operation $txtt [list wordstart -dir next -num [get_number $txtt] -exclusive 0]] }
        }
      }
      default {
        return [do_object_operation $txtt word]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "change" mode, delete the current WORD and change to edit
  # mode.
  proc handle_W {txtt} {

    variable operator
    variable motion

    switch $motion($txtt) {
      "" {
        switch $operator($txtt) {
          ""       { return [do_operation $txtt [list WORDstart -dir next -num [get_number $txtt] -exclusive 1]] }
          "change" {
            set num [get_number $txtt]
            if {[string is space [$txtt index insert]]} {
              return [do_operation $txtt [list WORDstart -dir next -num $num -exclusive 1]]
            } else {
              return [do_operation $txtt [list WORDend -dir next -num $num -exclusive 0 -adjust +1c]]
            }
          }
          default  { return [do_operation $txtt [list WORDstart -dir next -num [get_number $txtt] -exclusive 0]] }
        }
      }
      default {
        return [do_object_operation $txtt WORD]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, go to the last line.
  proc handle_G {txtt} {

    variable multiplier

    if {$multiplier($txtt) eq ""} {
      return [do_operation $txtt [list firstchar -startpos last]]
    } else {
      return [do_operation $txtt [list linenum -num $multiplier($txtt)]]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, transition the mode to the delete mode.
  # If we are in the "delete" mode, delete the current line.
  proc handle_d {txtt} {

    variable operator

    switch $operator($txtt) {
      "" {
        if {[edit::delete_selected $txtt 0]} {
          command_mode $txtt
        } else {
          set_operator $txtt "delete" {d}
        }
        return 1
      }
      "delete" {
        return [do_operation $txtt [list linestart -num [get_number $txtt]] linestart -postcursor "firstchar -num 0"]
      }
      "folding" {
        folding::delete_fold [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, deletes all text from the current
  # insertion cursor to the end of the line.
  proc handle_D {txtt} {

    variable operator

    switch $operator($txtt) {
      "" {
        if {[edit::delete_selected $txtt 1]} {
          command_mode $txtt
          return 1
        } else {
          set_operator $txtt "delete" {D}
          return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]]]
        }
      }
      "folding" {
        folding::delete_folds [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in the "command" mode, move the insertion cursor ahead by
  # one character and set ourselves into "edit" mode.
  proc handle_a {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          $txtt cursor move [list achar -num 1]
          edit_mode $txtt
          record_start $txtt "a"
          return 1
        }
        "folding" {
          folding::toggle_fold [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0] [get_number $txtt]
        }
        default {
          set motion($txtt) "a"
          return 1
        }
      }
    } elseif {[in_visual_mode $txtt]} {
      set motion($txtt) "a"
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
          record_start $txtt "A"
          return 1
        }
        "folding" {
          folding::toggle_fold [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0] 0
        }
      }
    }

    return 0

  }

  ######################################################################
  # If we are in the "command" mode, set ourselves to yank mode.  If we
  # are in "yank" mode, copy the current line to the clipboard.
  proc handle_y {txtt} {

    variable operator

    switch $operator($txtt) {
      "" {
        set_operator $txtt "yank" {y}
        if {[set ranges [$txtt tag ranges sel]] ne ""} {
          return [do_operation $txtt [list linestart -num [get_number $txtt]] linestart]
        }
        return 1
      }
      "yank" {
        return [do_operation $txtt [list linestart -num [get_number $txtt]] linestart]
      }
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
        record_stop 0
      }

    }

  }

  ######################################################################
  # Pastes the contents of the given clip to the text widget after the
  # current line.
  proc do_post_paste {txtt} {

    # Create a separator
    $txtt edit separator

    # Get the number of pastes that we need to perform
    set num [get_number $txtt]

    # Get the contents of the clipboard
    set clip [clipboard get]

    if {[set nl_index [string last \n $clip]] != -1} {
      if {$nl_index == ([string length $clip] - 1)} {
        $txtt paste -num $num -pre "\n" -post "\b" "insert lineend"
      } else {
        $txtt paste -num $num -pre "\n" "insert lineend"
      }
      $txtt cursor move [list linestart -num 1]
      $txtt cursor move [list firstchar -num 0]
    } else {
      $txtt paste -num $num "insert+1c"
      $txtt cursor set [list char -num [expr [string length $clip] * $num]]
    }

    # Create a separator
    $txtt edit separator

  }

  ######################################################################
  # If we are in the "command" mode, put the contents of the clipboard
  # after the current line.
  proc handle_p {txtt} {

    variable motion

    switch $motion($txtt) {
      "" {
        do_post_paste $txtt
        cliphist::add_from_clipboard
        record $txtt p
      }
      default {
        return [do_object_operation $txtt paragraph]
      }
    }

    return 0

  }

  ######################################################################
  # Pastes the contents of the given clip prior to the current line
  # in the text widget.
  proc do_pre_paste {txtt} {

    $txtt edit separator

    # Calculate the number of clips to pre-paste
    set num [get_number $txtt]

    # Get the contents of the clipboard
    set clip [clipboard get]

    if {[set nl_index [string last \n $clip]] != -1} {
      set cursor [$txtt index cursor]
      if {$nl_index == ([string length $clip] - 1)} {
        $txtt paste -num $num linestart
      } else {
        $txtt paste -num $num -post "\n" linestart
      }
      $txtt cursor move [list linestart -num 0 -startpos $cursor]
      $txtt cursor move [list firstchar -num 0]
    } else {
      $txtt paste -num $num insert
      $txtt cursor move [list char -num 1 -dir prev]
    }

    # Create separator
    $txtt edit separator

  }

  ######################################################################
  # If we are in the "command" mode, put the contents of the clipboard
  # before the current line.
  proc handle_P {txtt} {

    do_pre_paste $txtt
    cliphist::add_from_clipboard
    record $txtt P

    return 0

  }

  ######################################################################
  # Performs an undo operation.
  proc undo {txtt} {

    # Perform the undo operation
    catch { $txtt edit undo }

    # Allow the UI to update its state
    gui::check_for_modified $txtt

  }

  ######################################################################
  # Performs a redo operation.
  proc redo {txtt} {

    # Performs the redo operation
    catch { $txtt edit redo }

    # Allow the UI to update its state
    gui::check_for_modified $txtt

  }

  ######################################################################
  # If we are in "command" mode, undoes the last operation.
  proc handle_u {txtt} {

    variable operator
    variable motion

    switch $operator($txtt) {
      "" {
        if {$motion($txtt) eq ""} {
          undo $txtt
        } elseif {$motion($txtt) eq "g"} {
          set_operator $txtt "lower" {g u}
          set motion($txtt) ""
          if {[$txtt tag ranges sel] ne ""} {
            return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart]
          }
          return 1
        }
      }
      "lower" {
        return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart -postcursor linestart]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "goto" mode, convert the mode to uppercase mode.
  proc handle_U {txtt} {

    variable operator
    variable motion

    switch $operator($txtt) {
      "" {
        if {$motion($txtt) eq "g"} {
          set_operator $txtt "upper" {g U}
          set motion($txtt) ""
          if {[$txtt tag ranges sel] ne ""} {
            return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart]
          }
          return 1
        }
      }
      "upper" {
        return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart -postcursor linestart]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, deletes the current character.
  proc handle_x {txtt} {

    if {[$txtt is selected cursor]} {
      $txtt delete selstart selend
      command_mode $txtt
      return 1
    } else {
      set_operator $txtt "delete" {x}
      return [do_operation $txtt [list right -num [get_number $txtt]]]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, deletes the current character (same as
  # the 'x' command).
  proc handle_Delete {txtt} {

    if {[$txtt is selected cursor]} {
      $txtt delete selstart selend
      command_mode $txtt
      return 1
    } else {
      set_operator $txtt "delete" {Delete}
      return [do_operation $txtt [list right -num [get_number $txtt]]]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, deletes the previous character.
  proc handle_X {txtt} {

    if {[$txtt is selected cursor]} {
      $txtt delete [list selstart -dir prev] [list selend -dir prev]
      command_mode $txtt
      return 1
    } else {
      set_operator $txtt "delete" {X}
      return [do_operation $txtt [list left -num [get_number $txtt]]]
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
      switch $operator($txtt) {
        "" {
          edit::insert_line_below_current $txtt
          record_start $txtt "o"
          return 1
        }
        "folding" {
          folding::open_fold [get_number $txtt] [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
        }
      }
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
      switch $operator($txtt) {
        "" {
          edit::insert_line_above_current $txtt
          record_start $txtt "O"
          return 1
        }
        "folding" {
          folding::open_fold 0 [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
        }
      }
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
      switch $operator($txtt) {
        "" {
          set operator($txtt) "quit"
          return 1
        }
        "quit" {
          gui::save_current
          gui::close_current
        }
      }
    }

    return 0

  }

  ######################################################################
  # If we are in start mode and multicursors are enabled, set the Vim mode
  # to indicate that any further movement commands should be applied to
  # the multicursors instead of the standard cursor.
  proc handle_m {txtt} {

    variable motion

    if {[$txtt cursor enabled]} {
      multimove_mode $txtt
    } elseif {$motion($txtt) eq "g"} {
      return [do_operation $txtt dispmid]
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
          return [do_operation $txtt [list numberend -exclusive 0]]
        }
      }
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
      record_start $txtt "r"
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
      switch $operator($txtt) {
        "" {
          set mode($txtt) "replace_all"
          record_start $txtt "R"
          return 1
        }
        "folding" {
          folding::open_all_folds [winfo parent $txtt]
        }
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, sets the mode to "visual char" mode.
  proc handle_v {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      switch $operator($txtt) {
        "" {
          if {$motion($txtt) eq "g"} {
            visual_mode $txtt last
          } else {
            visual_mode $txtt char
          }
        }
        "folding" {
          folding::show_line [winfo parent $txtt] [lindex [split [$txtt index insert] .] 0]
        }
        default {
          set motion($txtt) "v"
          return 1
        }
      }
    } elseif {[in_visual_mode $txtt]} {
      if {$mode($txtt) eq "visual:char"} {
        visual_mode $txtt block
      } else {
        command_mode $txtt
      }
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, sets the mode to "visual line" mode.
  proc handle_V {txtt} {

    variable mode
    variable operator
    variable motion

    if {$mode($txtt) eq "command"} {
      if {$operator($txtt) eq ""} {
        visual_mode $txtt line
      } else {
        set motion($txtt) "V"
      }
      return 1
    } elseif {[in_visual_mode $txtt]} {
      command_mode $txtt
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, add a cursor.
  proc handle_s {txtt} {

    variable mode
    variable operator
    variable motion

    switch $motion($txtt) {
      "" {
        if {$mode($txtt) eq "command"} {
          if {$operator($txtt) eq ""} {
            $txtt cursor add [$txtt index insert]
          } else {
            return [do_operation $txtt spaceend]
          }
        }
      }
      default {
        return [do_object_operation $txtt sentence]
      }
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
        $txtt cursor addcolumn insert
      } else {
        return [do_operation $txtt spacestart]
      }
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

    return [do_object_operation $txtt double]

  }

  ######################################################################
  # Handles single-quote object selection.
  proc handle_quoteright {txtt} {

    return [do_object_operation $txtt single]

  }

  ######################################################################
  # Handle a` and i` Vim motions.
  proc handle_quoteleft {txtt} {

    return [do_object_operation $txtt btick]

  }

  ######################################################################
  # If any text is selected, square brackets are placed around all
  # selections.  If the insertion cursor is within a completed
  # bracket sequence, the right-most bracket of the sequence is moved one
  # word to the end; otherwise, the current word is placed within
  # curly brackets.
  proc handle_bracketleft {txtt} {

    return [do_object_operation $txtt square]

  }

  ######################################################################
  # Handles a] or i] Vim command.
  proc handle_bracketright {txtt} {

    return [do_object_operation $txtt square]

  }

  ######################################################################
  # If any text is selected, square brackets are placed around all
  # selections.  If the insertion cursor is within a completed
  # bracket sequence, the right-most bracket of the sequence is moved one
  # word to the end; otherwise, the current word is placed within
  # square brackets.
  proc handle_braceleft {txtt} {

    variable motion

    switch $motion($txtt) {
      "" {
        return [do_operation $txtt [list paragraph -dir prev -num [get_number $txtt]]]
      }
      default {
        return [do_object_operation $txtt curly]
      }
    }

    return 0

  }

  ######################################################################
  # Handles right curly bracket character.
  proc handle_braceright {txtt} {

    variable motion

    switch $motion($txtt) {
      "" {
        return [do_operation $txtt [list paragraph -dir next -num [get_number $txtt]]]
      }
      default {
        return [do_object_operation $txtt curly]
      }
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

    variable motion

    switch $motion($txtt) {
      "" {
        return [do_operation $txtt [list sentence -dir prev -num [get_number $txtt]]]
      }
      default {
        return [do_object_operation $txtt paren]
      }
    }

    return 0

  }

  ######################################################################
  # Handles a parenthesis right motion.
  proc handle_parenright {txtt} {

    variable motion

    switch $motion($txtt) {
      "" {
        return [do_operation $txtt [list sentence -dir next -num [get_number $txtt]]]
      }
      default {
        return [do_object_operation $txtt paren]
      }
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

    variable operator
    variable motion

    switch $operator($txtt) {
      "" {
        if {$motion($txtt) eq ""} {
          if {[edit::unindent_selected $txtt]} {
            command_mode $txtt
          } else {
            set_operator $txtt "lshift" {less}
          }
          return 1
        } else {
          return [do_object_operation $txtt angled]
        }
      }
      default {
        if {($operator($txtt) eq "lshift") && ($motion($txtt) eq "")} {
          return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart]
        } else {
          return [do_object_operation $txtt angled]
        }
      }
    }

    return 0

  }

  ######################################################################
  # If we are in start mode, begin a rshift mode.  If we are in
  # rshift mode, shift the current line right by one indent.
  proc handle_greater {txtt} {

    variable operator
    variable motion

    switch $operator($txtt) {
      "" {
        if {$motion($txtt) eq ""} {
          if {[edit::indent_selected $txtt]} {
            command_mode $txtt
          } else {
            set_operator $txtt "rshift" {greater}
          }
          return 1
        } else {
          return [do_object_operation $txtt angled]
        }
      }
      default {
        if {($operator($txtt) eq "rshift") && ($motion($txtt) eq "")} {
          return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart]
        } else {
          return [do_object_operation $txtt angled]
        }
      }
    }

    return 0

  }

  ######################################################################
  # When in start mode, if any text is selected, the selected code is
  # formatted; otherwise, if we are in start mode, we are transitioned to
  # format mode.  If we are in format mode, we format the currently selected
  # line only.
  proc handle_equal {txtt} {

    variable operator

    switch $operator($txtt) {
      "" {
        set_operator $txtt "format" {equal}
        if {[$txtt tag ranges sel] ne ""} {
          return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart]
        }
        return 1
      }
      "format" {
        return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" or "visual" mode, moves the insertion cursor to the first
  # non-whitespace character in the next line.
  proc handle_Return {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
      return [do_operation $txtt [list firstchar -num [get_number $txtt]]]
    }

    return 0

  }

  ######################################################################
  # Synonymous with the handle_Return command.
  proc handle_plus {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
      return [do_operation $txtt [list firstchar -num [get_number $txtt]]]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" or "visual" mode, moves the insertion cursor to the first
  # non-whitespace character in the previous line.
  proc handle_minus {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
      return [do_operation $txtt [list firstchar -num [expr 0 - [get_number $txtt]]]]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" or "visual" mode, move the cursor to the given
  # column of the current line.
  proc handle_bar {txtt} {

    return [do_operation $txtt [list column -num [get_number $txtt]]]

  }

  ######################################################################
  # If we are in "command" mode, change the case of the current character.
  proc handle_asciitilde {txtt} {

    variable operator
    variable motion

    switch $operator($txtt) {
      "" {
        if {$motion($txtt) eq ""} {
          set_operator $txtt "swap" {asciitilde}
          return [do_operation $txtt [list char -dir next -num [get_number $txtt]] cursor]
        } elseif {$motion($txtt) eq "g"} {
          set_operator $txtt "swap" {g asciitilde}
          set motion($txtt) ""
          if {[$txtt tag ranges sel] ne ""} {
            return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart -postcursor linestart]
          }
          return 1
        }
      }
      "swap" {
        return [do_operation $txtt [list lineend -num [expr [get_number $txtt] - 1]] linestart -postcursor linestart]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, move the cursor to the start of the middle
  # line.
  proc handle_M {txtt} {

    variable operator

    if {$operator($txtt) eq "folding"} {
      folding::close_all_folds [winfo parent $txtt]
    } else {
      return [do_operation $txtt screenmid]
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, search for all occurences of the current
  # word.
  proc handle_asterisk {txtt} {

    variable mode

    if {$mode($txtt) eq "command"} {
      set startpos [$txtt index wordstart -dir prev -startpos "insert+1c"]
      set endpos   [$txtt index wordend -startpos "insert-1c"]
      if {[string trim [set word [$txtt get $startpos $endpos]]] ne ""} {
        array set theme [theme::get_syntax_colors]
        catch { $txtt syntax delete classes search search_curr }
        $txtt syntax addclass search -fgtheme search_foreground -bgtheme search_background -highpriority 1
        $txtt syntax search   search $word
        search::find_next [winfo parent $txtt]
      }
    }

    return 0

  }

  ######################################################################
  # If we are in "command" mode, sets the current mode to "record" mode.
  proc handle_q {txtt} {

    variable mode
    variable recording

    if {$mode($txtt) eq "command"} {
      if {[in_recording]} {
        record_stop 1
        reset_state $txtt 0
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
    set startargs cursor
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

    return [do_operation $txtt $endargs $startargs -precursor cursor]

  }

  ######################################################################
  # This is just a synonym for the 'h' command so we'll just call the
  # handle_h procedure instead of replicating the code.
  proc handle_BackSpace {txtt} {

    variable operator
    variable motion

    # Move the insertion cursor left one character
    set startargs  cursor
    switch [lindex $motion($txtt) end] {
      "V" {
        set startargs  "linestart"
        set endargs    "lineend"
        # set cursorargs "none"
      }
      "v" {
        set startargs "right"
        if {$operator($txtt) eq ""} {
          set endargs [list char -dir prev -num [get_number $txtt]]
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

    if {$operator($txtt) ne "delete"} {
      set cursorargs [list dchar -dir prev -num [get_number $txtt]]
    } else {
      set cursorargs ""
    }

    return [do_operation $txtt $endargs $startargs -postcursor $cursorargs]

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

    variable operator

    if {$operator($txtt) eq ""} {
      set operator($txtt) "folding"
      return 1
    }

    return 0

  }

  ######################################################################
  # If we are in goto mode, move the cursor to the last character of the
  # line.
  proc handle_underscore {txtt} {

    variable motion

    if {$motion($txtt) eq ""} {
      return [do_operation $txtt [list firstchar -num [expr [get_number $txtt] - 1]]]
    } elseif {$motion($txtt) eq "g"} {
      return [do_operation $txtt [list lastchar -num [expr [get_number $txtt] - 1]]]
    }

    return 0

  }

  ######################################################################
  # Moves the cursor to the end of the next word.
  proc handle_e {txtt} {

    variable operator
    variable motion

    if {$operator($txtt) eq ""} {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list wordend -startpos char -dir next -num [get_number $txtt] -exclusive 1]]
      } elseif {$motion($txtt) eq "g"} {
        return [do_operation $txtt [list wordend -dir prev -num [get_number $txtt] -exclusive 1]]
      }
    } else {
      if {$motion($txtt) eq ""} {
        return [do_operation $txtt [list wordend -startpos char -dir next -num [get_number $txtt] -adjust "+1 display chars" -exclusive 1]]
      } elseif {$motion($txtt) eq "g"} {
        return [do_operation $txtt [list wordend -dir prev -num [get_number $txtt] -exclusive 1] right]
      }
    }

    return 0

  }

  ######################################################################
  # Move forward/backward to the end of a WORD.
  proc handle_E {txtt} {

    variable operator
    variable motion

    switch $operator($txtt) {
      "" {
        if {$motion($txtt) eq ""} {
          return [do_operation $txtt [list WORDend -dir next -num [get_number $txtt] -exclusive 1]]
        } elseif {$motion($txtt) eq "g"} {
          return [do_operation $txtt [list WORDend -dir prev -num [get_number $txtt] -exclusive 1]]
        }
      }
      "folding" {
        folding::delete_all_folds [winfo parent $txtt]
      }
      default {
        if {$motion($txtt) eq ""} {
          return [do_operation $txtt [list WORDend -dir next -num [get_number $txtt] -adjust "+1 display chars" -exclusive 1]]
        } elseif {$motion($txtt) eq "g"} {
          return [do_operation $txtt [list WORDend -dir prev -num [get_number $txtt] -exclusive 1] right]
        }
      }
    }

    return 0

  }

}
