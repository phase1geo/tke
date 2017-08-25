# Plugin namespace
namespace eval publish_markdown {

  variable publish
  variable type
  variable html
  variable command
  variable output_dir

  ######################################################################
  # Perform the publish operation.
  proc publish_do {} {

    variable type
    variable output_dir

    if {![create_dialog]} {
      return
    }

    foreach index [api::sidebar::get_selected_indices] {

      set str ""

      # Collate the Markdown content into a single string
      publish_collate $index str

      # Get the directory name
      set dname [file tail [api::sidebar::get_info $index fname]]

      # Write the contents to a file
      if {![catch { open [file join ~ Documents $dname.md] w } rc]} {
        puts $rc $str
        close $rc
      }

    }

  }

  ######################################################################
  # Creates the dialog window used perform the publish.
  proc create_dialog {} {

    variable publish
    variable type
    variable html
    variable command
    variable output_dir

    set publish    0
    set type       "export"
    set html       0
    set command    ""
    set output_dir ""

    array set apps {}

    toplevel .pubmd
    wm title .pubmd "Publish Markdown"
    wm transient .pubmd .

    ttk::frame .pubmd.tf
    ttk::radiobutton .pubmd.tf.write -text "Publish To: " -variable publish_markdown::type -value "export" -command {
      .pubmd.tf.browse configure -state normal
      .pubmd.tf.html   configure -state normal
    }
    ttk::entry .pubmd.tf.dir -state disabled
    ttk::button .pubmd.tf.browse -text "Browse" -command {
      if {[set publish_markdown::output_dir [tk_chooseDirectory -parent .pubmd]] ne ""} {
        .pubmd.tf.dir configure -state normal
        .pubmd.tf.dir delete 0 end
        .pubmd.tf.dir insert end $publish_markdown::output_dir
        .pubmd.tf.dir configure -state disabled
      }
    }
    ttk::checkbutton .pubmd.tf.html   -text "Export As HTML" -variable publish_markdown::html
    ttk::radiobutton .pubmd.tf.openin -text "Open In: "      -variable publish_markdown::type -value "openin" -command {
      .pubmd.tf.browse configure -state disabled
      .pubmd.tf.html   configure -state disabled
    }
    ttk::menubutton .pubmd.tf.apps -menu [menu .pubmd.tf.appsMenu -tearoff 0]

    switch -glob $tcl_platform(os) {
      Darwin {
        array set apps {
          {Marked 2} {open -a {Marked 2.app} {MDFILE}}
        }
      }
      Linux* {

      }
      *Win* {

      }
    }

    grid rowconfigure    .pubmd.tf 0 -weight 1
    grid columnconfigure .pubmd.tf 1 -weight 1
    grid .pubmd.tf.write  -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid .pubmd.tf.dir    -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .pubmd.tf.browse -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid .pubmd.tf.html   -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid .pubmd.tf.openin -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid .pubmd.tf.apps   -row 2 -column 1 -sticky nws  -padx 2 -pady 2

    ttk::frame .pubmd.bf
    ttk::button .pubmd.bf.publish -text "Publish" -width 7 -command {
      set publish_markdown::publish 1
      destroy .pubmd
    }
    ttk::button .pubmd.bf.cancel -text "Cancel" -width 7 -command {
      destroy .pubmd
    }

    pack .pubmd.bf.cancel  -side right -padx 2 -pady 2
    pack .pubmd.bf.publish -side right -padx 2 -pady 2

    pack .pubmd.tf -fill both -expand yes
    pack .pubmd.bf -fill x

    # Get the focus and wait for the window to be closed
    tk::PlaceWindow widget .pubmd .
    tk::SetFocusGrab .pubmd .pubmd.tf.export
    tkwait window .pubmd
    tk::RestoreFocusGrab .pubmd .pubmd.rf.export

    return $publish

  }

  ######################################################################
  # Gather the contents of each Markdown file in a depth-first method into
  # a single string.
  proc publish_collate {index pstr} {

    upvar $pstr str

    if {[api::sidebar::get_info $index is_dir]} {

      # Open the directory if it isn't already
      if {[set was_opened [api::sidebar::get_info $index is_open]] == 0} {
        api::sidebar::set_info $index open 1
      }

      # Collate the children
      foreach child [api::sidebar::get_info $index children] {
        publish_collate $child str
      }

      # Close the directory contents when we are done with it if it was previously
      # closed.
      if {!$was_opened} {
        api::sidebar::set_info $index open 0
      }

    } else {

      if {[lsearch {.md .mmd .markdown} [file extension [set fname [api::sidebar::get_info $index fname]]]] != -1} {
        if {![catch { open $fname r } rc]} {
          append str [string trim [read $rc]]
          append str "\n\n"
          close $rc
        }
      }

    }

  }

  ######################################################################
  # Open the Markdown output in Marked 2.
  proc open_in_marked2 {fname} {

    exec -ignorestderr open -a {Marked 2.app} $fname &

  }

  ######################################################################
  # Handle the state of the Publish Markdown option.
  proc publish_handle_state {} {

    foreach index [api::sidebar::get_selected_indices] {
      if {[api::sidebar::get_info $index sortby] eq "manual"} {
        return 1
      }
    }

    return 0

  }

}

# Register all plugin actions
api::register publish_markdown {
  {root_popup command {Publish Markdown} publish_markdown::publish_do publish_markdown::publish_handle_state}
  {dir_popup  command {Publish Markdown} publish_markdown::publish_do publish_markdown::publish_handle_state}
}
