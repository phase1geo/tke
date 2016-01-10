# Plugin namespace
namespace eval choosers {

  variable font_value

  ######################################################################
  # Returns the string containing the filename to open.
  proc get_current_word {txt} {

    if {[llength [set sel [$txt tag ranges sel ]]] > 0} {

      lassign $sel first last

      return [$txt get $first $last]

    } else {

      # Get the index of pos
      set index [lindex [split [$txt index insert] .] 1]

      # Get the current line
      set line [$txt get "insert linestart" "insert lineend"]

      # Get the first space
      set first_space [string last " " $line $index]

      # Get the last space
      if {[set last_space [string first " " $line $index]] == -1} {
        set last_space [string length $line]
      }

      return [string range $line [expr $first_space + 1] [expr $last_space - 1]]

    }

  }

  ######################################################################
  # Run the color chooser.
  proc do_color_picker {} {

    # Get the current text widget
    set txt [api::file::get_info [api::file::current_file_index] txt]

    # Get the current word
    set word [get_current_word $txt]

    set opts [list]
    if {![catch { winfo rgb . $word } rc]} {
      lappend opts -initialcolor $word
    }

    if {[set color [tk_chooseColor -parent . -title "Choose Color" {*}$opts]] ne ""} {
      clipboard clear
      clipboard append $color
      api::show_info "Color copied to the clipboard"
    }

  }

  ######################################################################
  # Handles the state of the color picker.
  proc handle_state_color_picker {} {

    return 1

  }

  ######################################################################
  # Run the font chooser.
  proc do_font_picker {} {

    # Get the current text widget
    set txt [api::file::get_info [api::file::current_file_index] txt]

    # Get the current word
    set word [get_current_word $txt]

    set opts [list]
    if {![catch { [ttk::entry .___e] configure -font $word }]} {
      lappend opts -initialfont $word
    }
    destroy .___e

    # Insert the selected font, if valid
    if {[set font_value [fontchooser -parent . -title "Choose Font" {*}$opts]] ne ""} {
      clipboard clear
      clipboard append $font_value
      api::show_info "Font copied to the clipboard"
    }

  }

  ######################################################################
  # Handles the state of the font picker.
  proc handle_state_font_picker {} {

    return 1

  }

  ######################################################################
  # Chooses a directory.
  proc do_dir_picker {} {

    # Get the current text widget
    set txt [api::file::get_info [api::file::current_file_index] txt]

    # Gets any options to pass to directory chooser
    set opts [list]
    if {[file isdirectory [set word [get_current_word $txt]]]} {
      lappend opts -initialdir $word
    }

    # Get the directory and insert it
    if {[set dir [tk_chooseDirectory -mustexist 0 -parent . -title "Choose Directory" {*}$opts]] ne ""} {
      clipboard clear
      clipboard append $dir
      api::show_info "Directory copied to the clipboard"
    }

  }

  ######################################################################
  # Handles the state of the directory picker.
  proc handle_state_dir_picker {} {

    return 1

  }

  ######################################################################
  # Chooses one or more files.
  proc do_file_picker {} {

    # Get the current text widget
    set txt [api::file::get_info [api::file::current_file_index] txt]

    # Get the current filename
    set fname [get_current_word $txt]
    set dir   ""

    set opts [list]
    if {[file exists $fname]} {
      if {[file isfile $fname]} {
        lappend opts -initialdir [file dirname $fname]
      } else {
        lappend opts -initialdir $fname
      }
    }

    if {[set files [tk_getOpenFile -multiple 1 -parent . -title "Choose File(s)" {*}$opts]] ne ""} {
      clipboard clear
      clipboard append [join $files \n]
      api::show_info [format "File%s copied to the clipboard" [expr {([llength $files] > 1) ? "s" : ""}]]
    }

  }

  ######################################################################
  # Handles the state of the file picker.
  proc handle_state_file_picker {} {

    return 1

  }

  ######################################################################
  # This procedure is necessary so that we can get access to a text widget.
  proc do_bind {tag} {

    # We are not going to do anything with the binding

  }

}

# Register all plugin actions
api::register choosers {
  {menu command "Choosers/Color..."     choosers::do_color_picker choosers::handle_state_color_picker}
  {menu command "Choosers/Font..."      choosers::do_font_picker  choosers::handle_state_font_picker}
  {menu command "Choosers/Directory..." choosers::do_dir_picker   choosers::handle_state_dir_picker}
  {menu command "Choosers/File..."      choosers::do_file_picker  choosers::handle_state_file_picker}
  {text_binding pretext none all choosers::do_bind}
}
