# Plugin namespace
namespace eval publish_markdown {

  variable publish
  variable type       "export"
  variable html       0
  variable appname    ""
  variable command    ""
  variable output_dir ""

  ######################################################################
  # Perform the publish operation.
  proc publish_do {} {

    variable type
    variable html
    variable command
    variable output_dir

    if {![create_dialog]} {
      return
    }

    # Get the processor
    set processor [string trim [api::preferences::get_value "processor"]]

    foreach index [set indices [api::sidebar::get_selected_indices]] {

      set str ""

      # Collate the Markdown content into a single string
      publish_collate $index str

      # Write the contents to a temporary file
      if {($type ne "export") || !$html || ($processor ne "")} {
        if {![catch { file tempfile tfile } rc]} {
          puts $rc $str
          close $rc
        } else {
          api::show_error "Unable to write file contents" $rc
          return
        }
      }

      # Generate the output file
      switch $type {
        export {
          set dname  [file tail [api::sidebar::get_info $index fname]]
          if {$html} {
            if {$processor ne ""} {
              if {[catch { exec -ignorestderr {*}[string map [list MDFILE $tfile] $processor] } rc]} {
                api::show_error "Unable to export file contents" $rc
                return
              }
            } else{
              if {[catch { api::export $str "Markdown" [file join $output_dir $dname.html] } rc]} {
                api::show_error "Unable to export file contents" $rc
                return
              }
            }
          } else {
            file rename -force $tfile [file join $output_dir $dname.md]
          }
        }
        openin {
          exec -ignorestderr {*}[string map [list MDFILE $tfile] $command] &
        }
      }

    }

    if {[llength $indices] == 1} {
      api::show_info "Markdown file successfully published"
    } else {
      api::show_info "Markdown files successfully published"
    }

  }

  ######################################################################
  # Creates the dialog window used perform the publish.
  proc create_dialog {} {

    variable publish
    variable type
    variable html
    variable appname
    variable command
    variable output_dir

    set publish 0
    set apps    [list]

    switch -glob $::tcl_platform(os) {
      Darwin {
        set apps {
          {{Marked 2} {open -a {Marked 2.app} {MDFILE}}}
        }
      }
    }

    lappend apps {*}[api::preferences::get_value "openin"]

    toplevel .pubmd
    wm title .pubmd "Publish Markdown"
    wm transient .pubmd .

    ttk::frame .pubmd.tf
    if {[llength $apps] > 0} {
      ttk::radiobutton .pubmd.tf.write -text "Publish To: " -variable publish_markdown::type -value "export" -command {
        .pubmd.tf.browse configure -state normal
        .pubmd.tf.html   configure -state normal
        .pubmd.tf.apps   configure -state disabled
        if {[.pubmd.tf.dir get] eq ""} {
          .pubmd.bf.publish configure -state disabled
        } else {
          .pubmd.bf.publish configure -state normal
        }
      }
    } else {
      ttk::label .pubmd.tf.write -text " Publish To: "
    }
    ttk::entry  .pubmd.tf.dir -width 40 -state disabled
    ttk::button .pubmd.tf.browse -text "Browse" -command {
      set publish_markdown::output_dir [tk_chooseDirectory -parent .pubmd]
      if {$publish_markdown::output_dir ne ""} {
        .pubmd.tf.dir configure -state normal
        .pubmd.tf.dir delete 0 end
        .pubmd.tf.dir insert end $publish_markdown::output_dir
        .pubmd.tf.dir configure -state disabled
        .pubmd.bf.publish configure -state normal
      }
    }
    ttk::checkbutton .pubmd.tf.html   -text " Export As HTML" -variable publish_markdown::html
    ttk::radiobutton .pubmd.tf.openin -text " Open In: "      -variable publish_markdown::type -value "openin" -command {
      .pubmd.tf.browse configure -state disabled
      .pubmd.tf.html   configure -state disabled
      .pubmd.tf.apps   configure -state normal
      if {[.pubmd.tf.apps cget -text] eq "Choose Application"} {
        .pubmd.bf.publish configure -state disabled
      } else {
        .pubmd.bf.publish configure -state normal
      }
    }
    ttk::menubutton .pubmd.tf.apps -text "Choose Application" -menu [menu .pubmd.tf.appsMenu -tearoff 0] -state disabled

    grid rowconfigure    .pubmd.tf 0 -weight 1
    grid columnconfigure .pubmd.tf 1 -weight 1
    grid .pubmd.tf.write  -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid .pubmd.tf.dir    -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .pubmd.tf.browse -row 0 -column 2 -sticky news -padx 2 -pady 2
    grid .pubmd.tf.html   -row 1 -column 1 -sticky news -padx 2 -pady 2

    if {[llength $apps] > 0} {
      grid .pubmd.tf.openin -row 2 -column 0 -sticky news -padx 2 -pady 2
      grid .pubmd.tf.apps   -row 2 -column 1 -sticky nws  -padx 2 -pady 2
    }

    ttk::frame .pubmd.bf
    ttk::button .pubmd.bf.publish -text "Publish" -width 7 -command {
      set publish_markdown::publish 1
      destroy .pubmd
    } -state disabled
    ttk::button .pubmd.bf.cancel -text "Cancel" -width 7 -command {
      destroy .pubmd
    }

    pack .pubmd.bf.cancel  -side right -padx 2 -pady 2
    pack .pubmd.bf.publish -side right -padx 2 -pady 2

    pack .pubmd.tf -fill both -expand yes
    pack .pubmd.bf -fill x

    # Create the openin menu
    foreach appcmd $apps {
      .pubmd.tf.appsMenu add command -label [lindex $appcmd 0] -command [list publish_markdown::set_app {*}$appcmd]
    }

    # Use the last settings
    if {$type eq "openin"} {
      if {$appname ne ""} {
        .pubmd.tf.browse configure -state disabled
        .pubmd.tf.html   configure -state disabled
        .pubmd.tf.apps   configure -state normal
        set_app $appname $command
      }
    }

    # Get the focus and wait for the window to be closed
    tk::PlaceWindow .pubmd widget .
    tk::SetFocusGrab .pubmd .pubmd.tf.export
    tkwait window .pubmd
    tk::RestoreFocusGrab .pubmd .pubmd.rf.export

    return $publish

  }

  ######################################################################
  # Set the application command.
  proc set_app {app cmd} {

    variable appname
    variable command

    # Remember the command
    set appname $app
    set command $cmd

    # Set the application name in the menubutton
    .pubmd.tf.apps configure -text $app

    # Enable the publish button
    .pubmd.bf.publish configure -state normal

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

      # Get the filename
      set fname [api::sidebar::get_info $index fname]

      # If the filename extension is a markdown file, continue
      if {[lsearch [api::preferences::get_value extensions] [file extension $fname]] == -1} {
        return
      }

      # If the filename matches an ignore item, don't include it
      foreach ignore [api::preferences::get_value "ignore"] {
        if {[string match *$ignore $fname]} {
          return
        }
      }

      # Append the file contents to the string
      if {![catch { open $fname r } rc]} {
        append str [string trim [read $rc]]
        append str "\n\n"
        close $rc
      }

    }

  }

  ######################################################################
  # Handle the state of the Publish Markdown option.
  proc publish_handle_state {} {

    # Get the list of extensions to consider
    set extensions [api::preferences::get_value extensions]

    foreach index [api::sidebar::get_selected_indices] {
      if {([api::sidebar::get_info $index sortby] eq "manual") || \
          (![api::sidebar::get_info $index is_dir] && ([lsearch $extensions [file extension [api::sidebar::get_info $index fname]]] != -1))} {
        return 1
      }
    }

    return 0

  }

  ######################################################################
  # Lists the preferences that are stored for this plugin.
  proc on_pref_load {} {

    return {
      "ignore"    ""
      "processor" ""
      "extensions" {.md .markdown}
      "openin"    ""
    }

  }

  ######################################################################
  # Setup the preferences window.
  proc on_pref_ui {w} {

    api::preferences::widget entry  $w "processor" "Processor Command" \
      -help "By default, the standard Markdown processor will be used; however, if this field is non-empty, the specified command will be run.  Use the string {MDFILE} to specify the location in the command-line to insert the Markdown file to be parsed."
    api::preferences::widget spacer $w
    api::preferences::widget token  $w "extensions" "Markdown File Extensions" \
      -help "List of file extensions that will be concatenated together to formulate the input file to the Markdown processor."
    api::preferences::widget token  $w "ignore" "File Patterns to Ignore" \
      -help "Pattern string used to remove files from Markdown processing.  Question marks (?) will match any single character while asterisks (*) will match any number of characters (including no characters)."
    api::preferences::widget spacer $w
    api::preferences::widget table  $w "openin" "'Open In' Applications" -columns [list 0 "Application Name" 0 "Command"] -height 4

  }

}

# Register all plugin actions
api::register publish_markdown {
  {root_popup command {Publish Markdown} publish_markdown::publish_do publish_markdown::publish_handle_state}
  {dir_popup  command {Publish Markdown} publish_markdown::publish_do publish_markdown::publish_handle_state}
  {file_popup command {Publish Markdown} publish_markdown::publish_do publish_markdown::publish_handle_state}
  {on_pref_load publish_markdown::on_pref_load}
  {on_pref_ui   publish_markdown::on_pref_ui}
}
