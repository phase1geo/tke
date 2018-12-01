# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
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
# Name:    api.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    07/09/2013
# Brief:   Provides user API to tke functionality.
######################################################################

namespace eval api {

  ######################################################################
  ## \return Returns true if we are doing tke_development.
  proc tke_development {interp pname} {

    return [::tke_development]

  }

  ######################################################################
  ## \return Returns the pathname to the plugin source directory.
  proc get_plugin_source_directory {interp pname} {

    set iplugin_dir [file join $::tke_home iplugins $pname]

    if {![file exists $iplugin_dir]} {
      set iplugin_dir [file join $::tke_dir plugins $pname] 
    }

    if {[$interp issafe]} {
      return [::safe::interpFindInAccessPath $interp $iplugin_dir]
    } else {
      return $iplugin_dir
    }

  }

  ######################################################################
  ## \return Returns the pathname to the plugin data directory.
  proc get_plugin_data_directory {interp pname} {

    set plugin_dir [file join $::tke_dir plugins $pname]

    if {[$interp issafe]} {
      return [::safe::interpFindInAccessPath $interp $plugin_dir]
    } else {
      return $plugin_dir
    }

  }

  ######################################################################
  ## \return Returns the pathname to the tke plugin images directory.
  proc get_images_directory {interp pname} {

    set img_dir [file join $::tke_dir plugins images]

    if {[$interp issafe]} {
      return [::safe::interpFindInAccessPath $interp $img_dir]
    } else {
      return $img_dir
    }

  }

  ######################################################################
  ## \return Returns the pathname to the user's home tke directory.
  proc get_home_directory {interp pname} {

    # Figure out the home directory
    set home [file join $::tke_home plugins $pname]

    # If the home directory does not exist, create it
    file mkdir $home

    if {[$interp issafe]} {
      return [::safe::interpFindInAccessPath $interp $home]
    } else {
      return $home
    }

  }

  ######################################################################
  ## \return Returns a fully NFS normalized filename based on the given host.
  #
  #  \param host   Name of the host that contains the filename
  #  \param fname  Name of the file to normalize
  proc normalize_filename {interp pname host fname} {

    return [files::normalize $host $fname]

  }

  ######################################################################
  ## Registers the given description and command in the command launcher.
  proc register_launcher {interp pname description command} {

    launcher::register [format "%s-%s: %s" [msgcat::mc "Plugin"] $pname $description] "$interp eval $command"

  }

  ######################################################################
  ## Unregisters a previously registered command launcher with the same
  #  description.
  proc unregister_launcher {interp pname description} {

    launcher::unregister [format "%s-%s: %s" [msgcat::mc "Plugin"] $pname $description]

  }

  ######################################################################
  ## Logs the given information in the diagnostic logfile and standard
  #  output.
  #
  # \param msg  Message to display.
  proc log {interp pname msg} {

    puts $msg

  }

  ######################################################################
  ## Displays the given message string in the information bar.  The
  #  message must not contain any newline characters.
  #
  #  \param msg   Message to display in the information bar
  #  \param args  Optional arguments:
  #
  #    -clear_delay  Specifies the number of milliseconds before the message
  #                  be automatically removed from sight.
  #    -win          If specified, the associated text widget path will be
  #                  associated with the message such that if the text
  #                  loses focus and then later regains the focus, the message
  #                  will be redisplayed.
  proc show_info {interp pname msg args} {

    # Displays the given message
    gui::set_info_message $msg {*}$args

  }

  ######################################################################
  ## Displays the given error message with detail information in a popup
  #  dialog window.
  #
  # \param msg     Main error message
  # \param detail  Error message detailed information
  proc show_error {interp pname msg {detail ""}} {

    gui::set_error_message $msg $detail

  }

  ######################################################################
  ## Displays a widget that allows the user to provide input.  This
  #  procedure will block until the user has either provided a response
  #  or has cancelled the input by hitting the escape key.
  #
  #  \param msg         Message to display next to input field (prompt)
  #  \param pvar        Reference to variable to store user input to
  #  \param allow_vars  If set to 1, variables embedded in string will have
  #                     substitutions performed; otherwise, the raw string
  #                     will be returned.  (Optional)
  #
  #  \return Returns a list containing two elements.  The first element is set to a
  #          1 if the user provided input; otherwise, returns 0 to indicate that the
  #          user cancelled the input operation.  The second item is the user provided
  #          value (if the first value is set to 1).
  proc get_user_input {interp pname msg pvar {allow_vars 1}} {

    set var [$interp eval set $pvar]

    if {[gui::get_user_response $msg var -allow_vars $allow_vars]} {
      $interp eval set $pvar [list $var]
      return 1
    }

    return 0

  }

  ######################################################################
  ## Sets the text focus back to the last text widget to receive focus.
  proc reset_text_focus {interp pname {txtt ""}} {

    if {$txtt eq ""} {
      after idle [list gui::set_txt_focus [gui::last_txt_focus]]
    } else {
      gui::get_info [winfo parent $txtt] txt tabbar tab
      after idle [list gui::set_current_tab $tabbar $tab]
    }

  }

  namespace eval file {

    ######################################################################
    ## \return Returns a list containing indices for all of the currently
    #          opened files.
    proc all_indices {interp pname} {

      return [files::get_indices fname]

    }

    ######################################################################
    ## \return Returns the file index of the file being currently edited.  If no
    #          such file exists, returns a value of -1.
    proc current_index {interp pname} {

      return [expr {[catch { gui::get_info {} current fileindex } index] ? -1 : $index}]

    }

    ######################################################################
    ## \return Returns the file information at the given file index.
    #
    #  \param file_index  Unique file identifier that is passed to some plugins.
    #  \param attr        File attribute to retrieve.  The following values are
    #                     valid for this option:
    #                     - \b fname    : Normalized file name
    #                     - \b mtime    : Last mofication timestamp (in seconds)
    #                     - \b lock     : Specifies the current lock status of the file
    #                     - \b readonly : Specifies if the file is readonly
    #                     - \b modified : Specifies if the file has been modified since the last save.
    #                     - \b sb_index : Specifies the index of the file in the sidebar.
    #                     - \b txt      : Specifies the text widget associated with the file
    #                     - \b current  : Returns 1 if the file is the current file being edited
    #                     - \b vimmode  : Returns 1 if the editor is not in edit mode; otherwise,
    #                                     returns 0.
    #                     - \b lang     : Returns the syntax language.
    proc get_info {interp pname file_index attr} {

      set value [gui::get_file_info $file_index $attr]

      if {$attr eq "txt"} {
        interpreter::add_ctext $interp $pname [winfo parent $value]
      }

      return $value

    }

    ######################################################################
    ## Adds a buffer to the browser.  The first option is the name of the
    #  buffer.  The second option is a command to execute once the save
    #  is successful.  The remaining arguments are the following options:
    #
    #
    proc add_buffer {interp pname name save_command args} {

      array set opts [list]

      # If we have an odd number of arguments, we have an error condition
      if {[expr [llength $args] % 2] == 1} {
        return -code error [msgcat::mc "Argument list to api::add_file was not an even key/value pair"]
      }

      # Get the options
      array set opts $args

      # Change out the gutter commands with interpreter versions
      if {[info exists opts(-gutters)]} {
        set new_gutters [list]
        foreach gutter $opts(-gutters) {
          set new_sym [list]
          foreach {symname symopts} [lassign $gutter gutter_name] {
            set new_symopts [list]
            foreach {symopt symval} $symopts {
              switch $symopt {
                "-onenter" -
                "-onleave" -
                "-onclick" {
                  lappend new_symopts $symopt "$interp eval $symval"
                }
                default {
                  lappend new_symopts $symopt $symval
                }
              }
            }
            lappend new_sym $symname $new_symopts
          }
          lappend new_gutters [list $gutter_name {*}$new_sym]
        }
        set opts(-gutters) $new_gutters
      }

      # Set the tags
      if {[info exists opts(-tags)]} {
        set tag_list [list]
        foreach tag $opts(-tags) {
          lappend tag_list "plugin__${pname}__$tag"
        }
        set opts(-tags) $tag_list
      }

      # If the save command was specified, add the interpreter evaluation
      if {$save_command ne ""} {
        set save_command "$interp eval $save_command"
      }

      # Finally, add the buffer
      gui::add_buffer end $name $save_command {*}[array get opts]

      # Allow the plugin to manipulate the ctext widget
      set txt [gui::current_txt]
      $interp alias $txt $txt

      return $txt

    }

    ######################################################################
    ## Adds a file to the browser.  If the first argument does not start with
    #  a '-' character, the argument is considered to be the name of a file
    #  to add.  If no filename is specified, an empty/unnamed file will be added.
    #  All other options are considered to be parameters.
    #
    #   -savecommand \e command
    #     * Specifies the name of a command to execute after
    #       the file is saved.
    #
    #   -lock (0|1)
    #     * If set to 0, the file will begin in the unlocked
    #       state (i.e., the user can edit the file immediately).
    #     * If set to 1, the file will begin in the locked state
    #       (i.e., the user must unlock the file to edit it)
    #
    #   -readonly (0|1)
    #     * If set to 1, the file will be considered readonly
    #       (i.e., the file will be locked indefinitely); otherwise,
    #       the file will be able to be edited.
    #
    #   -remember (0|1)
    #     * If set to 0, the file will not be saved to the user's session file
    #       when the application is quit.  By default, the file will be
    #       remembered and reloaded when the application is reopened.
    #
    #   -sidebar (0|1)
    #     * If set to 1 (default), the file's directory contents
    #       will be included in the sidebar; otherwise, the file's
    #       directory components will not be added to the sidebar.
    #
    #   -saveas (0|1)
    #     * If set to 0 (default), the file will be saved to the
    #       current file; otherwise, the file will always force a
    #       save as dialog to be displayed when saving.
    #
    #   -buffer (0|1)
    #     * If set to 0 (default), the file will be added as a normal file;
    #       however, if set to 1, the file will be treated as a temporary file
    #       that will be automatically deleted when the tab is closed.
    #
    #   -diff (0|1)
    #     * If set to 0 (default), the file will be added as an editable file;
    #       however, if set to 1, the file will be inserted as a difference viewer,
    #       allowing the user to view file differences visually within the editor.
    #
    #   -gutters \e list
    #     * Creates a gutter in the editor.  The contents of list are as follows:
    #       \code {name {{symbol_name {symbol_tag_options+}}+}}+ \endcode
    #       For a list of valid symbol_tag_options, see the options available for
    #       tags in a text widget.
    #
    #   -other (0|1)
    #     * If set to 0 (default), the file will be created in a new tab in the
    #       current pane; however, if set to 1, the file will be created in a new
    #       tab in the other pane (the other pane will be created if it does not
    #       exist).
    #
    #   -tags \e list
    #     * A list of plugin bindtag suffixes that will be applied only to this
    #       this text widget.
    #
    #   -name \e filename
    #     * If this option is specified when the filename is not specified, it will
    #       add a new tab to the editor whose name matches the given name.  If the
    #       user saves the file, the contents will be saved to disk with the given
    #       file name.  The given filename does not need to exist prior to calling
    #       this procedure.
    proc add_file {interp pname args} {

      set fname ""
      array set opts [list]

      # If no filename is given, add a new file to the editor
      if {([llength $args] > 0) && ([string index [lindex $args 0] 0] ne "-")} {

        # Peel the filename from the rest of the arguments
        set args [lassign $args fname]

        # Check to make sure that the file is safe to add to the editor, and
        # if it is, create the normalized pathname of the filename.
        if {[set fname [interpreter::check_file $pname $fname]] eq ""} {
          return -code error "permission error"
        }

      }

      # If we have an odd number of arguments, we have an error condition
      if {[expr [llength $args] % 2] == 1} {
        return -code error [msgcat::mc "Argument list to api::add_file was not an even key/value pair"]
      }

      # Get the options
      array set opts $args

      # If the -savecommand option was given, wrap it in an interp eval call
      # so that we don't execute the command in the master interpreter.
      if {[info exists opts(-savecommand)]} {
        set opts(-savecommand) "$interp eval $opts(-savecommand)"
      }

      # Change out the gutter commands with interpreter versions
      if {[info exists opts(-gutters)]} {
        set new_gutters [list]
        foreach gutter $opts(-gutters) {
          set new_sym [list]
          foreach {symname symopts} [lassign $gutter gutter_name] {
            set new_symopts [list]
            foreach {symopt symval} $symopts {
              switch $symopt {
                "-onenter" -
                "-onleave" -
                "-onclick" {
                  lappend new_symopts $symopt "$interp eval $symval"
                }
                default {
                  lappend new_symopts $symopt $symval
                }
              }
            }
            lappend new_sym $symname $new_symopts
          }
          lappend new_gutters [list $gutter_name {*}$new_sym]
        }
        set opts(-gutters) $new_gutters
      }

      # Set the tags
      if {[info exists opts(-tags)]} {
        set tag_list [list]
        foreach tag $opts(-tags) {
          lappend tag_list "plugin__${pname}__$tag"
        }
        set opts(-tags) $tag_list
      }

      # Finally, add the new file
      if {$fname eq ""} {
        gui::add_new_file end {*}[array get opts]
      } else {
        gui::add_file end $fname {*}[array get opts]
      }

      # Allow the plugin to manipulate the ctext widget
      set txt [gui::current_txt]
      $interp alias $txt $txt

      return $txt

    }

  }

  namespace eval edit {

    ######################################################################
    ## \return Returns the text widget index based on the given input
    #  parameters.
    #
    #  \param txt       Pathname of text widget to get index of.
    #  \param position  The specifies the visible cursor position to lookup.  The
    #                   values that can be used for this option are as follows:
    #    - left       Index num characters left of the starting position, staying on the same line.
    #    - right      Index num characters right of the starting position, staying on the same line.
    #    - up         Index above the starting position, remaining in the same
    #                 column, if possible.
    #    - down       Index below the starting position, remaining in the same
    #                 column, if possible.
    #    - first      Index of the first line/column in the buffer.
    #    - last       Index of the last line/column in the buffer.
    #    - char       Index of the a specified character before or after the starting
    #                 position.
    #    - dchar      Index of num'th character before or after the starting
    #                 position.
    #    - findchar   Index of a specified character before or after the starting
    #                 position.
    #    - firstchar  Index of first non-whitespace character of the line specified
    #                 by startpos.
    #    - lastchar   Index of last non-whitespace character of the line specified
    #                 by startpos.
    #    - wordstart  Index of the first character of the word containing startpos.
    #    - wordend    Index of the last character+1 of the word containing startpos.
    #    - WORDstart  Index of the first character of the WORD containing startpos.
    #    - WORDend    Index of the last character+1 of the WORD containing startpos.
    #    - column     Index of the character in the line containing startpos at the
    #                 num'th position.
    #    - linenum    Index of the first non-whitespace character on the given line.
    #    - linestart  Index of the beginning of the line containing startpos.
    #    - lineend    Index of the ending of the line containing startpos.
    #    - dispstart  Index of the first character that is displayed in the line
    #                 containing startpos.
    #    - dispmid    Index of the middle-most character that is displayed in the
    #                 line containing startpos.
    #    - dispend    Index of the last character that is displayed in the line
    #                 containing startpos.
    #    - screentop  Index of the start of the first line that is displayed in
    #                 the buffer.
    #    - screenmid  Index of the start of the middle-most line that is displayed
    #                 in the buffer.
    #    - screenbot  Index of the start of the last line that is displayed in
    #                 the buffer.
    #    - numberstart  First numerical character of the word containing startpos.
    #    - numberend    Last numerical character of the word containing startpos.
    #    - spacestart   First whitespace character of the whitespace containing startpos.
    #    - spaceend     Last whitespace character of the whitespace containing startpos.
    #  \param args  Modifier arguments based on position value.
    #    -dir        Specifies direction from starting position (values are "next"
    #                or "prev").  Defaults to "next".
    #    -startpos   Specifies the starting index of calculation.  Defaults to "insert".
    #    -num        Specifies the number to apply.  Defaults to 1.
    #    -char       Used with "findchar" position type.  Specifies the character
    #                to find.
    #    -exclusive  If set to 1, returns character position before calculated
    #                index.  Defaults to 0.
    #    -column     Specifies the name of a variable containing the column to
    #                use for "up" and "down" positions.
    #    -adjust     Adjusts the calculated index by the given value before
    #                returning the result.
    proc get_index {interp pname txt position args} {

      return [edit::get_index $txt $position {*}$args]

    }

    ######################################################################
    ## Deletes all characters between startpos and endpos-1, inclusive.
    #
    #  \param txt       Pathname of text widget to delete text from.
    #  \param startpos  Text widget index to begin deleting from.
    #  \param endpos    Text widget index to stop deleting from.
    #  \param copy      Copies deleted text to the clipboard.
    proc delete {interp pname txt startpos endpos copy} {

      edit::delete $txt $startpos $endpos $copy 1

    }

    ######################################################################
    ## Toggles the case of all characters in the range of startpos to endpos-1,
    #  inclusive.  If text is selected, the selected text is toggled instead
    #  of the given range.
    #
    #  \param txt        Text widget to modify.
    #  \param startpos   Starting index of range to modify.
    #  \param endpos     Ending index of range to modify.
    proc toggle_case {interp pname txt startpos endpos} {

      edit::transform_toggle_case $txt $startpos $endpos

    }

    ######################################################################
    ## Transforms all text in the given range of startpos to endpos-1,
    #  inclusive, to lower case.  If text is seelected, the selected text
    #  is transformed instead of the given range.
    #
    #  \param txt        Text widget to modify.
    #  \param startpos   Starting index of range to modify.
    #  \param endpos     Ending index of range to modify.
    proc lower_case {interp pname txt startpos endpos} {

      edit::transform_to_lower_case $txt $startpos $endpos

    }

    ######################################################################
    ## Transforms all text in the given range of startpos to endpos-1,
    #  inclusive, to upper case.  If text is selected, the selected text
    #  is transformed instead of the given range.
    #
    #  \param txt        Text widget to modify.
    #  \param startpos   Starting index of range to modify.
    #  \param endpos     Ending index of range to modify.
    proc upper_case {interp pname txt startpos endpos} {

      edit::transform_to_upper_case $txt $startpos $endpos

    }

    ######################################################################
    ## Transforms all text in the given range of startpos to endpos-1,
    #  inclusive, to its rot13 equivalent.  If text is selected, the
    #  selected text is transformed instead of the given range.
    #
    #  \param txt        Text widget to modify.
    #  \param startpos   Starting index of range to modify.
    #  \param endpos     Ending index of range to modify.
    proc rot13 {interp pname txt startpos endpos} {

      edit::transform_to_rot13 $txt $startpos $endpos

    }

    ######################################################################
    ## Transforms all text in the given range of startpos to endpos-1,
    #  inclusive, to title case (first character of each word is capitalized
    #  while the rest of the characters are set to lowercase).
    #
    #  \param txt        Text widget to modify.
    #  \param startpos   Starting index of range to modify.
    #  \param endpos     Ending index of range to modify.
    proc title_case {interp pname txt startpos endpos} {

      edit::transform_to_title_case $txt $startpos $endpos

    }

    ######################################################################
    ## Joins the given number of lines, guaranteeing that on a single space
    #  separates the text of each joined line, starting at the current
    #  insertion cursor position.  If text is selected, any line that contains
    #  a selection will be joined together.
    #
    #  \param txt  Text widget to modify.
    #  \param num  Number of lines to join below current line.
    proc join_lines {interp pname txt {num 1}} {

      edit::transform_join_lines $txt $num

    }

    ######################################################################
    ## Moves the current line up by one (unless the current line is the
    #  first line in the buffer.  If any text is selected, lines containing
    #  a selection will be moved up by one line.
    #
    # \param txt  Text widget to change.
    proc bubble_up {interp pname txt} {

      edit::transform_bubble_up $txt

    }

    ######################################################################
    ## Moves the current line down by one (unless the current line is the
    #  last line in the buffer.  If any text is selected, lines containing
    #  a selection will be moved down by one line.
    #
    # \param txt  Text widget to change.
    proc bubble_down {interp pname txt} {

      edit::transform_bubble_down $txt

    }

    ######################################################################
    ## Comments the currently selected lines.
    #
    #  \param txt  Text widget to comment.
    proc comment {interp pname txt} {

      edit::comment_text [winfo parent $txt]

    }

    ######################################################################
    ## Uncomments the currently selected lines.
    #
    #  \param txt  Text widget to uncomment.
    proc uncomment {interp pname txt} {

      edit::uncomment_text [winfo parent $txt]

    }

    ######################################################################
    ## Toggles the comment status of the currently selected lines.
    #
    #  \param txt  Text widget to change.
    proc toggle_comment {interp pname txt} {

      edit::comment_toggle_text [winfo parent $txt]

    }

    ######################################################################
    ## Indents the given range of text between startpos and endpos-1, inclusive,
    #  by one level of indentation.  If text is currently selected, the
    #  selected text is indented instead.
    #
    #  \param txt       Text widget to indent.
    #  \param startpos  Starting position of range to indent.
    #  \param endpos    Ending position of range to indent.
    proc indent {interp pname txt {startpos insert} {endpos insert}} {

      edit::indent $txt $startpos $endpos

    }

    ######################################################################
    ## Unindents the given range of text between startpos and endpos-1,
    #  inclusive, by one level of indentation.  If text is currently
    #  selected, the selected text is unindented instead.
    #
    #  \param txt       Text widget to unindent.
    #  \param startpos  Starting position of range to unindent.
    #  \param endpos    Ending position of range to unindent.
    proc unindent {interp pname txt {startpos insert} {endpos insert}} {

      edit::unindent $txt $startpos $endpos

    }

    ######################################################################
    ## Moves the cursor to the given cursor position.  The value of position
    #  and args are the same as those of the \ref api::edit::get_index.
    #
    #  \param txt       Text widget to change the cursor of.
    #  \param position  Position to move the cursor to (see \ref api::edit::get_index)
    #  \param args      List of arguments based on position value (see \ref api::edit::get_index)
    proc move_cursor {interp pname txt position args} {

      edit::move_cursor $txt $position {*}$args

    }

    ######################################################################
    ## Adds text formatting to current word of the given type.  If text is
    #  currently selected, the formatting will be applied to all of the
    #  selected text.
    #
    #  \param txt   Text widget to apply formatting to.
    #  \param type  Type of formatting to apply.  The available formats
    #               supported by the current syntax are allowed.  The legal
    #               values for this
    #               parameter are as follows:
    #   - bold
    #   - italics
    #   - underline
    #   - strikethrough
    #   - highlight
    #   - superscript
    #   - subscript
    #   - code
    #   - header1
    #   - header2
    #   - header3
    #   - header4
    #   - header5
    #   - header6
    #   - unordered
    #   - ordered
    proc format {interp pname txt type} {

      edit::format $txt $type

    }

    ######################################################################
    ## Removes any formatting that is applied to the selected text.
    #
    #  \param txt  Text widget to unformat.
    proc unformat {interp pname txt} {

      edit::unformat $txt

    }

  }

  namespace eval sidebar {

    ######################################################################
    ## \return Returns the selected sidebar file index.
    proc get_selected_indices {interp pname} {

      return [::sidebar::get_selected_indices]

    }

    ######################################################################
    ## \return Returns the value for the specified attribute of the
    #          file/directory in the sidebar with the given index.
    #
    #  \param sb_index  Sidebar index of file/directory in the sidebar
    #  \param attr      Attribute to return the value of.  Valid attribute
    #                   names are:
    #                   - \b fname      : Normalized name file or directory
    #                   - \b file_index : If not set, indicates the file has
    #                                     not been opened in the editor; otherwise,
    #                                     specifies the file index of the opened
    #                                     file.
    #                   - \b is_dir     : True if the given sidebar item is a directory.
    #                   - \b is_open    : True if the given sidebar item is in the
    #                                     open state.
    #                   - \b children   : Ordered list of children items of the given
    #                                     sidebar directory.
    proc get_info {interp pname sb_index attr} {

      return [::sidebar::get_info $sb_index $attr]

    }

    ######################################################################
    ## Changes the state of the specified sidebar item to the given value.
    #
    #  \param sb_index  Sidebar index of file/directory in the sidebar
    #  \param attr      Attribute to set the value of.  Valid attribute names
    #                   are:
    #                   - \b open : If set to 1, causes the sidebar item to be
    #                               opened; otherwise, if set to 0, causes the sidebar
    #                               item to be closed.
    proc set_info {interp pname sb_index attr value} {

      ::sidebar::set_info $sb_index $attr $value

    }

  }

  namespace eval plugin {

    ######################################################################
    ## Saves the value of the given variable name to non-corruptible memory
    #  so that it can be later retrieved when the plugin is reloaded.
    #
    #  \param index  Unique value that is passed to the on_reload save command.
    #  \param name   Name of the variable to store
    #  \param value  Variable value to store
    proc save_variable {interp pname index name value} {

      plugins::save_data $index $name $value

    }

    ######################################################################
    ## Retrieves the value of the named variable from non-corruptible memory
    #  (from a previous save_variable call.
    #
    #  \param index  Unique value that is passed to the on_reload retrieve command.
    #  \param name   Name of the variable to get the value of.  If the named variable
    #                could not be found), an empty string is returned.
    proc load_variable {interp pname index name} {

      return [plugins::restore_data $index $name]

    }

    ######################################################################
    ## Returns a value of true if the given procedure has been exposed by
    #  another plugin.  The value of "name" should be in the form of:
    #    <plugin_name>::<procedure_name>
    proc is_exposed {interp pname name} {

      return [plugins::is_exposed $name]

    }

    ######################################################################
    ## Executes the exposed procedure (if it exists) and returns the value
    #  returned by the procedure.  If the procedure does not exist or there
    #  is an exception thrown by the procedure, a value of -1 will be
    #  returned to the calling method.
    proc exec_exposed {interp pname name args} {

      if {[plugins::is_exposed $name] && ![catch { plugins::execute_exposed $name {*}$args } retval]} {
        return $retval
      }

      return -1

    }

    ######################################################################
    ## Reloads the plugins.  This is useful if the plugin changes its own
    #  code at runtime and needs to re-source itself.
    proc reload {interp pname} {

      plugins::reload

    }

  }

  namespace eval preferences {

    ######################################################################
    ## Returns a references to a widget created for the preferences window.
    #
    # \return Returns the pathname of the widget to pack.
    #
    # \param type Specifies the type of widget to create.
    #             (Legal values are: checkbutton, radiobutton, menubutton,
    #                emtry, text, spinbox)
    # \param win  Pathname of parent window to add widgets to.
    # \param pref Name of preference value associated with the widget.
    # \param msg  Label text to associate with the widget (this text is
    #             searchable.
    # \param args For all widget types that are not "spacer", the first arg
    #             must be the name of the preference value associated with the
    #             widget, the second arg must be a label to associated with the
    #             widget (this text is searchable), the rest of the arguments
    #             provide additional information required by the widget.
    proc widget {interp pname type win args} {

      # Figure out a unique identifier for the widget within the parent frame
      set index [llength [winfo children $win]]

      array set opts {
        -grid 0
      }

      switch $type {
        spacer {
          array set opts $args
          return [pref_ui::make_spacer $win $opts(-grid)]
        }
        help {
          if {([llength $args] < 1) || (([llength $args] % 2) == 0)} {
            return -code error "api::preferences::widget $type sent an incorrect number of parameters"
          }
          set args [lassign $args msg]
          array set opts $args
          return [pref_ui::make_help $win $msg $opts(-grid)]
        }
        default {

          if {([llength $args] < 2) || (([llength $args] % 2) == 1)} {
            return -code error "api::preferences::widget $type sent an incorrect number of parameters"
          }

          set args [lassign $args pref msg]

          array set opts {
            -value     ""
            -values    ""
            -watermark ""
            -grid      0
            -from      ""
            -to        ""
            -increment 1
            -ending    ""
            -color     "white"
            -height    4
            -columns   ""
            -help      ""
          }
          array set opts $args

          # Calculate the full preference pathname
          set pref_path "Plugins/$pname/$pref"

          # Make sure that the preference was loaded prior to creating the UI
          if {![info exists [preferences::ref $pref_path]]} {
            return -code error "Plugin preference $pref for $pname not previously loaded"
          }

          switch $type {
            checkbutton {
              return [pref_ui::make_cb $win.cb$index $msg Plugins/$pname/$pref $opts(-grid)]
            }
            radiobutton {
              if {$opts(-value) eq ""} {
                return -code error "Radiobutton widget must have -value option set"
              }
              return [pref_ui::make_rb $win.rb$index $msg Plugins/$pname/$pref $opts(-value) $opts(-grid)]
            }
            menubutton {
              if {$opts(-values) eq ""} {
                return -code error "Menubutton widget must have -values option set"
              }
              return [pref_ui::make_mb $win.mb$index $msg Plugins/$pname/$pref $opts(-values) $opts(-grid)]
            }
            entry {
              return [pref_ui::make_entry $win.e$index $msg Plugins/$pname/$pref $opts(-watermark) $opts(-grid) $opts(-help)]
            }
            token {
              return [pref_ui::make_token $win.te$index $msg Plugins/$pname/$pref $opts(-watermark) $opts(-grid) $opts(-help)]
            }
            text {
              return [pref_ui::make_text $win.t$index $msg Plugins/$pname/$pref $opts(-height) $opts(-grid) $opts(-help)]
            }
            spinbox {
              if {$opts(-from) eq ""} {
                return -code error "Spinbox widget must have -from option set"
              }
              if {$opts(-to) eq ""} {
                return -code error "Spinbox widget must have -to option set"
              }
              return [pref_ui::make_sb $win.sb$index $msg Plugins/$pname/$pref $opts(-from) $opts(-to) $opts(-increment) $opts(-grid) $opts(-ending)]
            }
            colorpicker {
              return [pref_ui::make_cp $win.cp$index $msg Plugins/$pname/$pref $opts(-color) $opts(-grid)]
            }
            table {
              if {$opts(-columns) eq ""} {
                return -code error "Table widget must have -columns option set"
              }
              return [pref_ui::make_table $win.tl$index $msg Plugins/$pname/$pref $opts(-columns) $opts(-height) $opts(-grid) $opts(-help)]
            }
            default {
              return -code error "Unsupported preference widget type ($type)"
            }
          }

        }
      }

    }

    ######################################################################
    # Returns the current specified preference value.
    #
    # \param varname Name of the preference value to retrieve
    proc get_value {interp pname varname} {

      return $preferences::prefs(Plugins/$pname/$varname)

    }

  }

  namespace eval menu {

    # This is a list of menu items that a plugin will not be allowed to invoke
    array set not_allowed {
      "File/Quit" 1
      "Tools/Restart TKE" 1
    }

    ######################################################################
    ## Returns true if the given menu path exists in the main menubar;
    #  otherwise, returns false.  The 'mnu_path' is a slash-separated (/) path
    #  to a menu item.  The menu path must match the menu strings exactly
    #  (case-sensitive).
    proc exists {interp pname mnu_path} {

      set menu_list [split $mnu_path /]

      if {![catch { menus::get_menu [lrange $menu_list 0 end-1] } mnu]} {
        if {![catch { menus::get_menu_index $mnu [lindex $menu_list end] } res] && ($res ne "none")} {
          return 1
        }
      }

      return 0

    }

    ######################################################################
    # Returns 1 if the given menu path is enabled in the menu; otherwise,
    # returns 0.
    proc enabled {interp pname mnu_path} {

      set menu_list [split $mnu_path /]

      if {![catch { menus::get_menu [lrange $menu_list 0 end-1] } mnu]} {
        if {![catch { menus::get_menu_index $mnu [lindex $menu_list end] } index] && ($index ne "none")} {
          return [expr {[$mnu entrycget $index -state] eq "normal"}]
        }
      }

      return 0

    }

    ######################################################################
    ## Returns the current value of the given menu path (only valid for
    #  checkbutton or radiobutton menus).
    proc get_value {interp pname mnu_path} {

      set menu_list [split $mnu_path /]

      if {![catch { menus::get_menu [lrange $menu_list 0 end-1] } mnu]} {
        if {![catch { menus::get_menu_index $mnu [lindex $menu_list end] } index] && ($index ne "none")} {
          switch [$mnu type $index] {
            checkbutton -
            radiobutton { return [$mnu entrycget $index -value] }
            default     { return "" }
          }
        }
      }

      return ""

    }

    ######################################################################
    ## Attempts to invoke the menu item specified by the given menu path.
    proc invoke {interp pname mnu_path} {

      variable not_allowed

      if {[info exists not_allowed($mnu_path)]} {
        return 0
      }

      set menu_list [split $mnu_path /]

      if {![catch { menus::get_menu [lrange $menu_list 0 end-1] } mnu]} {
        if {![catch { menus::get_menu_index $mnu [lindex $menu_list end] } index] && ($index ne "none")} {
          if {![catch { menus::invoke $mnu $index }]} {
            return 1
          }
        }
      }

      return 0

    }

  }

  namespace eval theme {

    ######################################################################
    ## Returns the given theme value as specified by the category and option
    #  value.  If no value exists, we will return an error.
    proc get_value {interp pname category option} {

      # Get the category options
      array set opts [theme::get_category_options $category 1]

      if {![info exists opts($option)]} {
        return -code error "Unable to find theme category option ($category, $option)"
      }

      return $opts($option)

    }

  }

  namespace eval utils {

    ######################################################################
    ## Opens the given file in a file browser.  If in_background is set to
    #  a value of 1, the focus will remain in the editor; otherwise, focus
    #  will be given to the opening application.
    proc open_file {interp pname fname {in_background 0}} {

      return [utils::open_file_externally $fname $in_background]

    }

  }

}
