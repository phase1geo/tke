# Plugin namespace
namespace eval markdown_drop {

  ######################################################################
  # Inserts the given string into the current text widget.
  proc insert_string {index value} {

    # Get the associated text widget
    set str  ""
    set txt  [api::file::get_info $index txt]
    set pre  [$txt get "insert linestart" insert]
    set post [$txt get insert "insert lineend"]

    if {($pre ne "") && ![string is space [string index $pre end]]} {
      append str " "
    }
    append str $value
    if {($post ne "") && ![string is space [string index $post 0]]} {
      append str " "
    }

    # Insert the string
    $txt insert insert $str

  }

  ######################################################################
  # Gets optional image information to include in the image insertion.
  proc get_user_image_info {index fname mddir} {

    variable assets

    set assets 0

    toplevel     .imgwin
    wm title     .imgwin "Image Properties"
    wm transient .imgwin .
    wm resizable .imgwin 0 0

    ttk::frame             .imgwin.tf
    ttk::label             .imgwin.tf.lt -text "Title: "
    wmarkentry::wmarkentry .imgwin.tf.et -watermark "Optional" -width 40
    ttk::label             .imgwin.tf.la -text "Alt Text: "
    wmarkentry::wmarkentry .imgwin.tf.ea -watermark "Optional" -width 40
    ttk::checkbutton       .imgwin.tf.cb -text " Create and copy image to local assets directory" -variable markdown_drop::assets

    grid columnconfigure .imgwin.tf 1 -weight 1
    grid .imgwin.tf.lt -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid .imgwin.tf.et -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .imgwin.tf.la -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid .imgwin.tf.ea -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid .imgwin.tf.cb -row 2 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2

    ttk::frame  .imgwin.bf
    ttk::button .imgwin.bf.insert -style BButton -text "Insert" -width 6 -command [list markdown_drop::insert_image $index $fname $mddir]
    ttk::button .imgwin.bf.cancel -style BButton -text "Cancel" -width 6 -command {
      destroy .imgwin
    }

    pack .imgwin.bf.cancel -side right -padx 2 -pady 2
    pack .imgwin.bf.insert -side right -padx 2 -pady 2

    pack .imgwin.tf -fill x
    pack .imgwin.bf -fill x

    # Wait for the window to be closed
    tk::PlaceWindow  .imgwin widget .
    tk::SetFocusGrab .imgwin .imgwin.tf.et
    tkwait window .imgwin
    tk::RestoreFocusGrab .imgwin .imgwin.tf.et

  }

  ######################################################################
  # Handles the image insertion process.
  proc insert_image {index fname mddir} {

    variable assets

    # Get the title and alternative text from the user
    set title [.imgwin.tf.et get]
    set alt   [.imgwin.tf.ea get]

    # If we are copying the image to the assets directory, do it now
    # and update the pathname of the fname variable.
    if {$assets} {
      file mkdir [set assets_dir [file join $mddir assets]]
      if {[catch { file copy $fname $assets_dir } rc]} {
        show_error "Unable to copy the image" $rc
      } else {
        set fname [file join assets [file tail $fname]]
      }
    }

    # Insert the title, if necessary
    if {$title ne ""} {
      append fname " \"$title\""
    }

    # Finally, insert the stringi
    insert_string $index "!\[$alt\]($fname)"

    # Close the window
    destroy .imgwin

  }

  ######################################################################
  # Checks the incoming data and if it is an image file, sets the specified
  # string to be an image syntax.
  proc handle_image {index istext data mddir} {

    if {!$istext && ([lsearch [list .gif .png .jpg .jpeg] [file extension $data]] != -1)} {
      after idle [list markdown_drop::get_user_image_info $index $data $mddir]
      return 1
    }

    return 0

  }

  ######################################################################
  # Allow the user to edit link information prior to inserting the text.
  proc get_user_link_info {index url} {

    toplevel     .lnkwin
    wm title     .lnkwin "Link Properties"
    wm transient .lnkwin .
    wm resizable .lnkwin 0 0

    ttk::frame             .lnkwin.tf
    ttk::label             .lnkwin.tf.lx -text "Text: "
    ttk::entry             .lnkwin.tf.ex -width 40 -validate key -validatecommand  [list markdown_drop::validate_link %P]
    ttk::label             .lnkwin.tf.lt -text "Title: "
    wmarkentry::wmarkentry .lnkwin.tf.et -watermark "Optional" -width 40

    grid columnconfigure .lnkwin.tf 1 -weight 1
    grid .lnkwin.tf.lx -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid .lnkwin.tf.ex -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .lnkwin.tf.lt -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid .lnkwin.tf.et -row 1 -column 1 -sticky news -padx 2 -pady 2

    ttk::frame  .lnkwin.bf
    ttk::button .lnkwin.bf.insert -style BButton -text "Insert" -width 6 -command [list markdown_drop::insert_link $index $url] -state disabled
    ttk::button .lnkwin.bf.cancel -style BButton -text "Cancel" -width 6 -command {
      destroy .lnkwin
    }

    pack .lnkwin.bf.cancel -side right -padx 2 -pady 2
    pack .lnkwin.bf.insert -side right -padx 2 -pady 2

    pack .lnkwin.tf -fill x
    pack .lnkwin.bf -fill x

    # Wait for the window to be closed
    tk::PlaceWindow  .lnkwin widget .
    tk::SetFocusGrab .lnkwin .lnkwin.tf.ex
    tkwait window .lnkwin
    tk::RestoreFocusGrab .lnkwin .lnkwin.tf.ex

  }

  ######################################################################
  # Validate the given link text value.
  proc validate_link {value} {

    if {$value eq ""} {
      .lnkwin.bf.insert configure -state disabled
    } else {
      .lnkwin.bf.insert configure -state normal
    }

    return 1

  }

  ######################################################################
  # Insert the link text into the editing buffer.
  proc insert_link {index url} {

    set ltext [.lnkwin.tf.ex get]
    set title [.lnkwin.tf.et get]

    if {$title ne ""} {
      append url " \"$title\""
    }

    # Insert the link string
    insert_string $index "\[$ltext\]($url)"

    # Close the window
    destroy .lnkwin

  }

  ######################################################################
  # Checks the incoming data and if it is a link, sets the specified string
  # to be link syntax.
  proc handle_link {index istext data} {

    if {$istext && [regexp {^((https?://)?[a-z0-9\-]+\.[a-z0-9\-\.]+(?:/|(?:/[a-zA-Z0-9!#\$%&'\*\+,\-\.:;=\?@\[\]_~]+)*))$} $data -> url]} {
      after idle [list markdown_drop::get_user_link_info $index $data]
      return 1
    }

    return 0

  }

  ######################################################################
  # Handles any drop events within a Markdown document.
  proc on_drop {index istext data} {

    # If the current language is one that we support with this plugin, attempt to handle
    # the dropped information
    if {[lsearch [list "Markdown" "MultiMarkdown"] [api::file::get_info $index lang]] != -1} {

      # Check to see if the insertion item is either an image or link
      if {[handle_image $index $istext $data [file dirname [api::file::get_info $index fname]]] || \
          [handle_link  $index $istext $data]} {
        return 1
      }

    }

    return 0

  }

}

# Register all plugin actions
api::register markdown_drop {
  {on_drop markdown_drop::on_drop}
}
