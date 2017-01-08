#]!wish8.5

######################################################################
# Name:    specl.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    10/14/2013
# Brief:   Update mechanism for Tcl applications.
######################################################################

# Error out if we are running on Windows
if {[string match $::tcl_platform(os) *Win*]} {
  error "specl is not available for the Windows platform at this time"
}

lappend auto_path [file dirname $::argv0]

package require Tk
package require http
package require tls
package require mime
package require msgcat
package require -exact xml 3.2

# Install the htmllib and gifblock
source [file join [file dirname $::argv0] htmllib.tcl]
source [file join [file dirname $::argv0] gifblock.tcl]
source [file join [file dirname $::argv0] resize.tcl]
source [file join [file dirname $::argv0] Tclxml3.2 dom.tcl]
source [file join [file dirname $::argv0] bgproc.tcl]
source [file join [file dirname $::argv0] utils.tcl]

namespace eval specl::releaser {

  array set widgets {}
  array set data {
    channel_title       ""
    channel_description ""
    channel_link        ""
    channel_language    "en"
    item_version        ""
    item_release_type   1
    item_release_notes  ""
    item_description    ""
    item_download_url   ""
    item_markdown       0
    cl_noui             0
    cl_version          ""
    cl_desc_file        ""
    cl_verbose          1
    cl_release_type     "stable"
    cl_test_mode        ""
    cl_user             ""
    cl_password         ""
  }

  # Add OS-specific variables
  foreach os $specl::oses {
    set data(item_val,$os)      0
    set data(item_prev,$os)     0
    set data(item_file,$os)     ""
    set data(item_url,$os)      ""
    set data(item_length,$os)   0
    set data(item_checksum,$os) ""
    set data(cl_file,$os)       ""
    set data(file_ok_eid,$os)   ""
  }

  ######################################################################
  # Help information when this is run as a stand-alone application.
  proc usage {} {

    puts "Usage:  wish8.5 releaser.tcl -- (-h | -v | <command> <options>)"
    puts ""
    puts "General Options:"
    puts "  -h       Outputs this help information."
    puts "  -v       Displays version information."
    puts ""
    puts "Commands:"
    puts "  new   Generates a new release of the given project for general availability"
    puts "  edit  Edits an existing release"
    puts ""
    puts "Options:"
    puts "  -noui              Runs the given command without displaying the GUI"
    puts "  -q                 Runs without displaying anything to standard output"
    puts "  -n <version>       Specifies the version number to use for the release (required)"
    puts "  -f <file>          Specifies a file to read in for the release description (optional)"
    puts "  -b <os>,<package>  Specifies an update package to upload where <os> can be linux, mac or win"
    puts "                     and <package> is the name of the associated file to upload"
    puts "  -r <type>          Specifies the type of release to create (stable or devel)"
    puts "  -u <username>      Username of database rw admin"
    puts "  -p <password>      Password associated with the specified username"
    puts ""

    exit 1

  }

  ######################################################################
  # Parses the command-line arguments to the release new command.
  proc parse_new_args {cl_args} {

    variable data

    if {[llength $cl_args] > 0} {

      # Parse the release arguments
      while {[llength $cl_args] > 0} {
        set cl_args [lassign $cl_args arg]
        switch -exact -- $arg {
          -noui   { set data(cl_noui) 1 }
          -q      { set data(cl_verbose) 0 }
          -n      { set cl_args [lassign $cl_args data(cl_version)] }
          -f      { set cl_args [lassign $cl_args data(cl_desc_file)] }
          -b      {
            set cl_args [lassign $cl_args bundle]
            lassign [split $bundle ,] os fname
            set data(item_file,$os) [set data(cl_file,$os) $fname]
            set data(item_val,$os)  1
          }
          -r      { set cl_args [lassign $cl_args data(cl_release_type)] }
          -test   { set cl_args [lassign $cl_args data(cl_test_mode)] }
          -u      { set cl_args [lassign $cl_args data(cl_user)] }
          -p      { set cl_args [lassign $cl_args data(cl_password)] }
          default { return 0 }
        }
      }

      # Check to make sure that all of the necessary arguments were set
      if {$data(cl_noui) && (($data(cl_version) eq "") || ($data(cl_desc_file) eq ""))} {
        return 0
      } else {
        foreach os $specl::oses {
          if {($data(cl_file,$os) ne "") && ![file exists $data(cl_file,$os)]} {
            return 0
          }
        }
      }

      # Handle the version value
      set data(item_version) $data(cl_version)

      # Handle the description file
      if {$data(cl_desc_file) ne ""} {
        if {[string range $data(cl_desc_file) 0 6] eq "http://"} {
          set data(item_release_notes) $data(cl_desc_file)
        } elseif {![catch { open $data(cl_desc_file) r } rc]} {
          set data(item_description) [read $rc]
          close $rc
        } else {
          return 0
        }
      }

      # Handle the release type
      switch $data(cl_release_type) {
        "stable" { set data(item_release_type) $specl::RTYPE_STABLE }
        "devel"  { set data(item_release_type) $specl::RTYPE_DEVEL }
        default  { return 0 }
      }

    }

    return 1

  }

  ######################################################################
  # Parses the command-line arguments to the release edit command.
  proc parse_edit_args {cl_args} {

    variable data

    if {[llength $cl_args] > 0} {

      # Parse the release arguments
      while {[llength $cl_args] > 0} {
        set cl_args [lassign $cl_args arg]
        switch -exact -- $arg {
          -noui   { set data(cl_noui) 1 }
          -q      { set data(cl_verbose) 0 }
          -n      { set cl_args [lassign $cl_args data(cl_version)] }
          -f      { set cl_args [lassign $cl_args data(cl_desc_file)] }
          -b      {
            set cl_args [lassign $cl_args bundle]
            lassign [split $bundle ,] os fname
            set data(item_file,$os) [set data(cl_file,$os) $fname]
            set data(item_val,$os)  1
          }
          -r      { set cl_args [lassign $cl_args data(cl_release_type)] }
          -u      { set cl_args [lassign $cl_args data(cl_user)] }
          -p      { set cl_args [lassign $cl_args data(cl_password)] }
          default { return 0 }
        }
      }

      # Check to make sure that all of the necessary arguments were set
      foreach os $specl::oses {
        if {($data(cl_file,$os) ne "") && ![file exists $data(cl_file,$os)]} {
          return 0
        }
      }

      # Handle the version value
      set data(item_version) $data(cl_version)

      # Handle the description file
      if {$data(cl_desc_file) ne ""} {
        if {[string range $data(cl_desc_file) 0 6] eq "http://"} {
          set data(item_release_notes) $data(cl_desc_file)
        } elseif {![catch { open $data(cl_desc_file) r } rc]} {
          set data(item_description) [read $rc]
          close $rc
        } else {
          return 0
        }
      }

      # Handle the release type
      switch $data(cl_release_type) {
        "stable" { set data(item_release_type) $specl::RTYPE_STABLE }
        "devel"  { set data(item_release_type) $specl::RTYPE_DEVEL }
        default  { return 0 }
      }

    }

    return 1

  }

  ######################################################################
  # Gets the release information from the user from a form.
  proc get_release_info {} {

    variable widgets
    variable data

    toplevel .relwin
    wm title .relwin "Release Information"

    wm protocol .relwin WM_DELETE_WINDOW {
      exit
    }

    ttk::frame .relwin.tf
    set widgets(item_version_label)      [ttk::label       .relwin.tf.l0  -text "Version:"]
    set widgets(item_version)            [ttk::entry       .relwin.tf.e0]
    set widgets(item_rtype_label)        [ttk::label       .relwin.tf.l1  -text "Release Type:"]
    set widgets(item_rtype_frame)        [ttk::frame       .relwin.tf.rf]
    set widgets(item_rtype_stable)       [ttk::radiobutton .relwin.tf.rf.rbs -text "Stable"      -variable specl::releaser::data(item_release_type) -value $specl::RTYPE_STABLE]
    set widgets(item_rtype_devel)        [ttk::radiobutton .relwin.tf.rf.rbd -text "Development" -variable specl::releaser::data(item_release_type) -value $specl::RTYPE_DEVEL]
    set widgets(item_desc_label)         [ttk::label       .relwin.tf.l2  -text "Description:"]
    set widgets(item_desc)               [text             .relwin.tf.e2  -height 5 -width 60 -wrap word]
    set widgets(item_markdown_cb)        [ttk::checkbutton .relwin.tf.cb3 -text "Enable Markdown" -variable specl::releaser::data(item_markdown)]
    set widgets(item_notes_label)        [ttk::label       .relwin.tf.l4  -text "Release Notes URL:"]
    set widgets(item_notes)              [ttk::entry       .relwin.tf.e4]
    set widgets(item_download_url_label) [ttk::label       .relwin.tf.l5  -text "Download Directory URL:"]
    set widgets(item_download_url)       [ttk::entry       .relwin.tf.e5]

    array set full_os {linux Linux mac MacOSX win Windows}
    set row 6
    foreach os $specl::oses {
      set widgets(item_file_cb,$os)    [ttk::checkbutton .relwin.tf.cb${row} -variable specl::releaser::data(item_val,$os)]
      set widgets(item_file_label,$os) [ttk::label       .relwin.tf.l${row}  -text "$full_os($os) Installation Package:"]
      set widgets(item_file,$os)       [ttk::entry       .relwin.tf.e${row}  -validate key -validatecommand [list specl::releaser::handle_file_entry $os %P]]
      set widgets(item_file_btn,$os)   [ttk::button      .relwin.tf.l${row}2 -text "Browse..." -command "specl::releaser::handle_browse $os"]
      incr row
    }

    pack $widgets(item_rtype_stable) -side left -padx 2
    pack $widgets(item_rtype_devel)  -side left -padx 2

    grid rowconfigure    .relwin.tf 2 -weight 1
    grid columnconfigure .relwin.tf 2 -weight 1
    grid $widgets(item_version_label)      -row 0 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_version)            -row 0 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_rtype_label)        -row 1 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_rtype_frame)        -row 1 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_desc_label)         -row 2 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_desc)               -row 2 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_markdown_cb)        -row 3 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_notes_label)        -row 4 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_notes)              -row 4 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_download_url_label) -row 5 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_download_url)       -row 5 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2

    set row 6
    foreach os $specl::oses {
      grid $widgets(item_file_cb,$os)    -row $row -column 0 -sticky news -padx 2 -pady 2
      grid $widgets(item_file_label,$os) -row $row -column 1 -sticky news -padx 2 -pady 2
      grid $widgets(item_file,$os)       -row $row -column 2 -sticky news -padx 2 -pady 2
      grid $widgets(item_file_btn,$os)   -row $row -column 3 -sticky news -padx 2 -pady 2
      incr row
    }

    ttk::frame  .relwin.bf
    ttk::button .relwin.bf.preview -text "Preview" -width 7 -command {
      specl::releaser::handle_preview
    }
    ttk::button .relwin.bf.ok -text "OK" -width 7 -command {
      specl::releaser::handle_okay
    }
    ttk::button .relwin.bf.cancel -text "Cancel"  -width 7 -command {
      destroy .relwin
      exit 1
    }

    pack .relwin.bf.preview -side left -padx 2 -pady 2
    pack .relwin.bf.cancel  -side right -padx 2 -pady 2
    pack .relwin.bf.ok      -side right -padx 2 -pady 2

    pack .relwin.tf -fill both -expand yes
    pack .relwin.bf -fill x

    # Fill in known values in the above fields
    $widgets(item_version)      insert end $data(item_version)
    $widgets(item_desc)         insert end $data(item_description)
    $widgets(item_download_url) insert end $data(item_download_url)

    foreach os $specl::oses {
      $widgets(item_file,$os) insert end $data(cl_file,$os)
    }

    # If the general tab has been setup, change the view to the Release tab
    focus $widgets(item_version)

    # Wait for the window to close
    tkwait window .relwin

    return

  }

  ######################################################################
  # Returns the HTML item description, performing Markdown conversion,
  # if specified.
  proc get_item_description {} {

    variable widgets
    variable data

    # Get the content from the description
    set content [$widgets(item_desc) get 1.0 end-1c]

    # If we need to run markdown, do it now
    if {$data(item_markdown)} {

      # Create the Markdown command
      set md_cmd "perl [file join [file dirname $::argv0] Markdown_1.0.1 Markdown.pl]"

      # Run the file through the markdown processor
      if {![catch { exec -ignorestderr {*}$md_cmd << $content } rc]} {
        set content $rc
      } else {
        tk_messageBox -parent .relwin -icon warning -title "Markdown Error" -detail $rc -default ok -type ok
      }

    }

    return $content

  }

  ######################################################################
  # Handles changes to the item_file entry field.
  proc handle_file_entry {os value} {

    variable widgets
    variable data

    if {$value ne ""} {
      if {[file exists $value] && [file isfile $value]} {
        $widgets(item_file_label,$os) configure -background green
        set data(file_ok_eid,$os) [after 1000 [list $widgets(item_file_label,$os) configure -background ""]]
      } else {
        catch { after cancel $specl::releaser::data(file_ok_eid,$os) }
        $widgets(item_file_label,$os) configure -background red
      }
    } else {
      $widgets(item_file_label,$os) configure -background ""
    }

    return 1

  }

  ######################################################################
  # Handles a click on the file browser.  Allows the user to choose
  # an installation filename which will be populated in the entry field.
  proc handle_browse {os} {

    variable widgets

    array set full_os {linux Linux mac MacOSX win Windows}

    if {[set data(item_file,$os) [tk_getOpenFile -title "Select $full_os($os) Installation Package" -initialdir [pwd]]] ne ""} {
      $widgets(item_file,$os) configure -text $data(item_file,$os)
    }

  }

  ######################################################################
  # Handles the preview of the release notes.
  proc handle_preview {} {

    variable widgets
    variable data

    if {![winfo exists .prevwin]} {

      toplevel     .prevwin
      wm title     .prevwin "Release Preview"
      wm geometry  .prevwin 500x400
      wm resizable .prevwin 0 0

      ttk::frame     .prevwin.f
      text           .prevwin.f.t  -yscrollcommand {specl::utils::set_yscrollbar .prevwin.f.vb}
      ttk::scrollbar .prevwin.f.vb -orient vertical -command {.prevwin.f.t yview}

      grid rowconfigure    .prevwin.f 0 -weight 1
      grid columnconfigure .prevwin.f 0 -weight 1
      grid .prevwin.f.t  -row 0 -column 0 -sticky news
      grid .prevwin.f.vb -row 0 -column 1 -sticky ns

      ttk::frame  .prevwin.bf
      ttk::button .prevwin.bf.refresh -text "Refresh" -width 7 -command {
        specl::utils::HMcancel_animations
        .prevwin.f.t configure -state normal
        HMreset_win .prevwin.f.t
        HMparse_html [specl::releaser::get_item_description] "HMrender .prevwin.f.t"
        .prevwin.f.t configure -state disabled
      }

      pack .prevwin.bf.refresh -side right -padx 2 -pady 2

      pack .prevwin.f  -fill both -expand yes
      pack .prevwin.bf -fill x

      # Render the HTML
      specl::utils::HMinitialize .prevwin.f.t
      HMparse_html [get_item_description] "HMrender .prevwin.f.t"

      # Disable the text widget
      .prevwin.f.t configure -state disabled

    } else {

      # This will be called when the preview button is clicked in the main window while
      # this window is still open, so let's just reset and re-render the HTML.
      .prevwin.bf.refresh invoke

    }

  }

  ######################################################################
  # Handles a user click on the Okay button.
  proc handle_okay {} {

    variable widgets
    variable data

    # Get user-provided parameters
    set data(item_version)        [$widgets(item_version) get]
    set data(item_description)    [get_item_description]
    set data(item_release_notes)  [$widgets(item_notes) get]
    set data(item_download_url)   [$widgets(item_download_url) get]

    foreach os $specl::oses {
      set data(item_file,$os) [$widgets(item_file,$os) get]
    }

    $widgets(item_version_label) configure -background [expr {($data(item_version)      eq "") ? "red" : ""}]
    $widgets(item_desc_label)    configure -background [expr {($data(item_description)  eq "") ? "red" : ""}]
    $widgets(item_download_url)  configure -background [expr {($data(item_download_url) eq "") ? "red" : ""}]

    set valids          0
    set release_warning 0
    foreach os $specl::oses {
      if {$data(item_val,$os) || ($data(item_prev,$os) ne "")} {
        incr valids 1
      }
      if {[$widgets(item_file_label,$os) cget -background] eq "red"} {
        set release_warning 1
      }
    }

    if {$valids == 0} {
      foreach os $specl::oses {
        $widgets(item_file_label,$os) configure -background "red"
      }
      set release_warning 1
    }

    # Set the tab background color to red if any fields are missing
    if {($data(item_version)      eq "") ||
        ($data(item_description)  eq "") ||
        ($data(item_download_url) eq "") ||
        $release_warning} {
      tk_messageBox -parent .relwin -default ok -type ok -message "Missing required fields"
    } else {
      destroy .relwin
    }

    # Allow the UI to update
    update idletasks

  }

  ######################################################################
  # Create the message to send.
  proc form_data_compose {partv {type multipart/form-data}} {

    upvar 1 $partv parts

    set mime     [mime::initialize -canonical $type -parts $parts]
    set packaged [mime::buildmessage $mime]

    foreach part $parts {
      mime::finalize $part
    }

    mime::finalize $mime

    return $packaged

  }

  ######################################################################
  # Adds a data field to the message.
  proc form_data_add_field {partv name value} {

    upvar 1 $partv parts

    set disposition "form-data; name=\"${name}\""

    lappend parts [mime::initialize -canonical text/plain -string $value \
                   -header [list Content-Disposition $disposition]]

  }

  ######################################################################
  # Adds a binary file to the message.
  proc form_data_add_binary {partv name fname value type} {

     upvar 1 $partv parts

     set disposition "form-data; name=\"${name}\"; filename=\"$fname\""

     lappend parts [mime::initialize -canonical $type \
                    -string $value \
                    -encoding binary \
                    -header [list Content-Disposition $disposition]]

  }

  ######################################################################
  # Create the full message.
  proc form_data_format {name fname value type args} {

    set parts [list]

    foreach {n v} $args {
      form_data_add_field parts $n $v
    }

    form_data_add_binary parts $name $fname $value $type

    return [form_data_compose parts]

  }

  ######################################################################
  # Uploads the given file to the download server.
  proc upload_file {os fname} {

    variable data

    set field    "fname"
    set type     ""
    set size     [file size $fname]
    set checksum [specl::utils::get_checksum $fname]
    set params   [list \
      command  addfile \
      user     $data(cl_user) \
      passwd   $data(cl_password) \
      size     $size \
      checksum $checksum \
      os       $os \
      version  $data(item_version) \
    ]
    set headers  [list]

    if {[catch { open $fname r } rc]} {
      return -code error "Error uploading file $fname"
    }

    fconfigure $rc -translation binary -encoding binary
    set content [read $rc]
    close $rc

    # format the file and form
    set message [form_data_format $field [file tail $fname] $content $type {*}$params]

    # parse the headers out of the message body because http get url wants
    # them as a separate parameter
    set headerEnd   [expr [string first "\r\n\r\n" $message] + 1]
    set bodystart   [expr $headerEnd + 3]
    set headers_raw [string range $message 0 $headerEnd]
    set body        [string range $message $bodystart end]
    set headers_raw [string map {"\r\n " " " "\r\n" "\n"} $headers_raw]
    regsub {  +} $headers_raw " " headers_raw

    foreach line [split $headers_raw "\n"] {
      regexp {^([^:]+): (.*)$} $line all label value
      lappend headers $label $value
    }

    # get the content-type
    array set ha $headers
    set content_type $ha(Content-Type)
    unset ha(Content-Type)
    set headers [array get ha]

    puts "Uploading file $fname"

    # POST it
    set token [http::geturl "$specl::rss_url/index.php" -type $content_type -binary true -headers $headers -query $body]

    # Upload the file
    if {([http::status $token] eq "ok") && ([http::ncode $token] == 200)} {
      http::cleanup $token
      return 1
    } else {
      set data(fetch_error) [http::error $token]
      http::cleanup $token
      return 0
    }

  }

  ######################################################################
  # Create the release on the server.
  proc create_release {} {

    variable data

    # Create SQL query
    set query [http::formatQuery \
      command addrelease \
      version $data(item_version) \
      type    $data(item_release_type) \
      desc    $data(item_description) \
      user    $data(cl_user) \
      passwd  $data(cl_password) \
    ]

    # Create the release
    set token [http::geturl "$specl::rss_url/index.php" -query $query]

    if {([http::status $token] eq "ok") && ([http::ncode $token] == 200)} {
      write_version [http::data $token]
      http::cleanup $token
      return 1
    } else {
      set data(fetch_error) [http::error $token]
      http::cleanup $token
      return 0
    }

  }

  ######################################################################
  # Uploads specified files.
  proc upload_files {} {

    variable data

    # Upload files
    foreach os $specl::oses {
      if {$data(item_val,$os) || ($data(item_prev,$os) && ($data(item_file,$os) ne ""))} {
        upload_file $os $data(item_file,$os)
      }
    }

  }

  ######################################################################
  # Write the version file.
  proc write_version {release} {

    variable data

    if {![catch { open specl_version.tcl w } rc]} {

      puts $rc "set specl::appname      \"$specl::appname\""
      puts $rc "set specl::version      \"$data(item_version)\""
      puts $rc "set specl::release      \"$release\""
      puts $rc "set specl::rss_url      \"$specl::rss_url\""
      puts $rc "set specl::download_url \"$data(item_download_url)\""

      close $rc

    }

  }

  ######################################################################
  # Performs a release of the current project.
  proc start_release {type} {

    variable data

    # Attempt to source the specl_version.tcl file
    if {[catch { specl::load_specl_version [pwd] } rc]} {

      # If the specl_version file doesn't exist, initialize the variables
      if {$data(item_version) eq ""} {
        set data(item_version) "1.0"
      }
      set data(item_download_url) ""

    } else {

      # Enable HTTPS transfer, if necessary
      if {[string range $specl::rss_url 0 4] eq "https"} {
        ::http::register https 443 ::tls::socket
      }

      # Initialize variables from specl_version file
      if {$data(item_version) eq ""} {
        set data(item_version) $specl::version
      }
      set data(item_download_url) $specl::download_url

    }

    # Get the release information from the user
    if {!$data(cl_noui)} {
      get_release_info
    }

    # Create the necessary files
    if {$type eq "new"} {
      create_release
    } else {
      upload_files
    }

    # End the application
    exit

  }

}


######################################################################
# START OF HTMLLIB CUSTOMIZATION
######################################################################

# Create behavior of links when cursor rolls over them and when link
# is clicked.
array unset HMevents {}

# Override symbols used in links
# TBD - HMset_state $win -symbols [lrepeat "\x2022\x2023\x25e6\x2043" 5]

# Handles a click on a link
proc HMlink_callback {win href} {
  specl::utils::open_file_externally $href
}

# Handles an image
proc HMset_image {win handle src} {
  specl::utils::HMhandle_image $win $handle $src
}

######################################################################
# END OF HTMLLIB CUSTOMIZATION
######################################################################

# Make the theme be clam
ttk::style theme use clam

# Withdraw the top-level window so that it isn't visible
wm withdraw .

# If no options were supplied, display the usage information
if {[llength $argv] == 0} {
  puts "ERROR:  No arguments supplied to specl command"
  specl::releaser::usage
}

# Parse command-line arguments
set args $argv
switch -exact -- [lindex $args 0] {
  -h      { specl::releaser::usage }
  -v      { puts $specl::version; exit }
  default {
    set args [lassign $args command]
    switch $command {
      new {
        if {![specl::releaser::parse_new_args $args]} {
          puts "ERROR:  Incorrect arguments passed to specl release new command"
          specl::releaser::usage
        }
      }
      edit {
        if {![specl::releaser::parse_edit_args $args]} {
          puts "ERROR:  Incorrect arguments passed to specl release edit command"
          specl::releaser::usage
        }
      }
      default {
        puts "ERROR:  Incorrect arguments passed to specl release command"
        specl::releaser::usage
      }
    }
    specl::releaser::start_release $command
  }
}
