#!wish8.5

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
catch { package require tls }
package require msgcat
package require -exact xml 3.2

# Install the htmllib and gifblock
source [file join [file dirname $::argv0] htmllib.tcl]
source [file join [file dirname $::argv0] gifblock.tcl]
source [file join [file dirname $::argv0] resize.tcl]
source [file join [file dirname $::argv0] Tclxml3.2 dom.tcl]
source [file join [file dirname $::argv0] bgproc.tcl]
source [file join [file dirname $::argv0] utils.tcl]

namespace eval specl::updater {

  array set widgets {}

  array set data {
    specl_version_dir    ""
    cl_quiet             0
    cl_theme             ""
    cl_test_type         ""
    cl_release_type      $specl::RTYPE_STABLE
    cl_force             0
    appicon              ""
    fetch_ncode          ""
    fetch_content        ""
    fetch_error          ""
    stylecount           0
    cancel               0
    translation_dir      ""
    password_attempts    0
    ui,icon_path         ""
    ui,appicon_path      ""
    ui,appicon_side      left
    ui,utd_win_width     400
    ui,utd_win_height    120
    ui,utd_title         "You are up-to-date!"
    ui,utd_message       "Your version of {APPNAME} ({CURVERSION}) is the latest available."
    ui,upd_win_width     500
    ui,upd_win_height    400
    ui,upd_win_title     "Software Updater"
    ui,upd_win_resizable 1
    ui,upd_title         "A new version is available!"
    ui,upd_message       "Version ({NEWVERSION}) is ready for installation. You are currently\nusing version ({CURVERSION}). Click Download to update your version."
    ui,upd_desc_height   200
    ui,pwd_win_title     "Enter root password"
    ui,pwd_win_width     300
    ui,pwd_win_height    120
    ui,pwd_max_attempts  3
    ui,pwd_message       "{APPNAME} requires administrative privileges\nto install the latest update"
  }

  ######################################################################
  # Help information when this is run as a stand-alone application.
  proc usage {} {

    puts "Usage:  wish8.5 updater.tcl -- (-h | -v | <options> <specl_version_directory>)"
    puts ""
    puts "General Options:"
    puts "  -h       Outputs this help information."
    puts "  -v       Displays version information."
    puts ""
    puts "Options:"
    puts "  -q            Run without any output to standard output"
    puts "  -f            Forces the update to proceed even if it is not required (testing purposes only)"
    puts "  -r <type>     Specifies type of release to update to (1 = stable, 2 = devel, 3 = either)"
    puts "  -t <theme>    Specifies the Tk theme to use for the update window."
    puts "  -test <type>  Causes the updater window to run in test mode only.  The valid values"
    puts "                for <type> are as follows:"
    puts "                  update        - Display the update window"
    puts "                  full-update   - Allow the entire update process to run assuming we require an update"
    puts "                  uptodate      - Display the up-to-date window"
    puts "                  full-uptodate - Allow the entire update process to run assuming we are up-to-date"
    puts "                  password      - Display the password input window"
    puts ""
    puts "The <specl_version_directory> is the directory within the project where the specl_version.tcl file resides."
    puts ""

    exit 1

  }

  ######################################################################
  # Parses the given arguments to the update command.
  proc parse_args {cl_args} {

    variable data

    # Parse the release arguments
    while {[llength $cl_args] > 0} {
      set cl_args [lassign $cl_args arg]
      switch -exact -- $arg {
        -q      { set data(cl_quiet) 1 }
        -f      { set data(cl_force) 1 }
        -r      { set cl_args [lassign $cl_args data(cl_release_type)] }
        -t      {
          set cl_args [lassign $cl_args data(cl_theme)]
          catch { ttk::style theme use $data(cl_theme) }
        }
        -test   {
          set cl_args [lassign $cl_args data(cl_test_type)]
          if {($data(cl_test_type) ne "update") && \
              ($data(cl_test_type) ne "full-update") && \
              ($data(cl_test_type) ne "uptodate") && \
              ($data(cl_test_type) ne "full-uptodate") && \
              ($data(cl_test_type) ne "password")} {
            return 0
          }
        }
        default {
          if {$data(specl_version_dir) eq ""} {
            set data(specl_version_dir) [file normalize $arg]
          } else {
            return 0
          }
        }
      }
    }

    # Check to make sure that the user specified the version directory
    if {$data(specl_version_dir) eq ""} {
      return 0
    }

    return 1

  }

  ######################################################################
  # Fetches the application RSS feed sheet from the stored URL.
  proc fetch_url {} {

    variable data

    # Figure out which OS we want to get the upgrade for
    switch -glob $::tcl_platform(os) {
      Darwin  { set os "mac" }
      Linux*  { set os "linux" }
      *Win*   { set os "windows" }
      default { set os "linux" }
    }

    # Figure out the release type
    switch $data(cl_release_type) {
      $specl::RTYPE_STABLE { set type "stable" }
      $specl::RTYPE_DEVEL  { set type "devel" }
      default              { set type "any" }
    }

    # Create the POST request
    set query [http::formatQuery command upgrade os $os type $type index $specl::release]

    # Get the data from the given URL
    set token [http::geturl "$specl::rss_url/index.php?$query"]

    # Set the ncode
    set data(fetch_ncode) [http::ncode $token]

    # Get the data
    if {([http::status $token] eq "ok") && ($data(fetch_ncode) == 200)} {
      set data(fetch_content) [http::data $token]
    } else {
      set data(fetch_error) [http::error $token]
    }

    # Cleanup the HTTP request
    http::cleanup $token

  }

  ######################################################################
  # Parses the returned XML data.
  proc parse_data {} {

    variable data

    set first          1
    set description    ""
    set download_url   ""
    set length         0
    set checksum       ""
    set num_updates    0
    set latest_version $specl::version
    set latest_release $specl::release
    set force          $data(cl_force)

    # Parse the DOM
    if {[catch { dom::parse $data(fetch_content) } dom]} {
      return -code error "Unable to parse RSS contents: $dom"
    }

    # Get the contents of the 'releases' node
    set rss_node      [specl::utils::get_element $dom "rss"]
    set channel_node  [specl::utils::get_element $rss_node "channel"]
    set releases_node [specl::utils::get_element $channel_node "releases"]

    # Get the contents of the next 'release' node
    foreach release_node [specl::utils::get_elements $releases_node "release"] {

      set release [specl::utils::get_attr $release_node "index"]
      set version [specl::utils::get_attr $release_node "version"]
      set rtype   [specl::utils::get_attr $release_node "type"]

      # Set the title
      set title "<h2>Version ($version) Release Notes</h2>"

      # Add the publish date, if available
      if {![catch { specl::utils::get_element $release_node "pubDate" } pubdate_node] && \
          ![catch { specl::utils::get_text $pubdate_node } publish_date] && \
          ($publish_date ne "")} {
        append title "<h6>[string repeat {&nbsp;} 4]&nbsp;$publish_date</h6>"
      }

      # Get any release notes
      if {![catch { specl::utils::get_element $release_node "releaseNotesLink" } release_link_node] && \
          ![catch { specl::utils::get_text $release_link_node } release_link] && \
          ($release_link ne "")} {

        # Retrieve the release notes from the given link
        set token [http::geturl $release_link]

        # Get the HTML description
        if {([http::status $token] eq "ok") && ([http::ncode $token] == 200)} {
          set curr_description [http::data $token]
        } else {
          set curr_description "No description available"
        }

        # Cleanup the HTTP token
        http::cleanup $token

      # Otherwise, attempt to get the description from the embedded description
      } elseif {![catch { specl::utils::get_element $release_node "description" } description_node]} {

        # Remove the CDATA around the description
        if {[catch { specl::utils::get_cdata $description_node } curr_description]} {
          set curr_description "No description available"
        }

      } else {
        set curr_description "No description available"
      }

      if {$first} {

        # Set the description
        set description    "$title<br>$curr_description"
        set latest_version $version
        set latest_release $release

        # Get the downloads node
        set downloads_node [specl::utils::get_element $release_node "downloads"]

        # Get the download information
        foreach download_node [specl::utils::get_elements $downloads_node "download"] {

          # Get the download URL
          set download_url [specl::utils::get_attr $download_node "url"]

          # Get the file length
          set length [specl::utils::get_attr $download_node "length"]

          # Get the md5 checksum
          set checksum [specl::utils::get_attr $download_node "checksum"]

        }

        set first 0

      } else {

        # Append to the current description
        append description "<br><hr>$title<br>$curr_description"

      }

      incr num_updates

    }

    # Delete the DOM
    dom::destroy $dom

    return [list description  $description \
                 download_url $download_url \
                 version      $latest_version \
                 release      $latest_release \
                 length       $length \
                 checksum     $checksum \
                 num_updates  $num_updates]

  }

  ######################################################################
  # Unpacks the content into the tmp directory.
  proc check_bundle {bundle content_list} {

    variable data

    array set content $content_list

    # Check the file size against the stored data
    if {[file size $bundle] ne $content(length)} {
      return -code error "Downloaded bundle is not the expected length"
    }

    # Check the md5 checksum against the stored data
    if {[specl::utils::get_checksum $bundle] ne $content(checksum)} {
      return -code error "Downloaded bundle has an incorrect checksum"
    }

    set fname [file tail $bundle]
    set ext   [file extension $fname]
    set root  [file rootname $fname]

    # If the bundle is a tarball, unpack it into the tmp directory
    if {$ext eq ".tgz"} {
      if {[catch { exec -ignorestderr tar xf $bundle -C [file join / tmp] } rc]} {
        return -code error $rc
      }
    } elseif {$ext eq ".gz"} {
      if {[catch { exec -ignorestderr gzip -d $bundle } rc]} {
        return -code error $rc
      }
    } elseif {$ext eq ".bz2"} {
      if {[catch { exec -ignorestderr bunzip2 $bundle } rc]} {
        return -code error $rc
      }
    } elseif {$ext eq ".dmg"} {
      if {[catch { file mkdir [set mountpoint [file join / tmp $root]] } rc]} {
        return -code error $rc
      }
      if {[catch { exec -ignorestderr hdiutil attach $bundle -mountpoint $mountpoint -nobrowse } rc]} {
        return -code error $rc
      }
      set appname [glob -directory $mountpoint *.app]
      if {[catch { file copy -force $appname [file join / tmp [file tail $appname]] } rc]} {
        return -code error $rc
      }
      if {[catch { exec -ignorestderr hdiutil detach $mountpoint } rc]} {
        return -code error $rc
      }
      catch { file delete -force $mountpoint $bundle }
    }

    # If the file needs to be untar'ed do it now
    if {[file extension $root] eq ".tar"} {
      if {[catch { exec -ignorestderr tar xf $root -C [file join / tmp] } rc]} {
        return -code error $rc
      }
    }

  }

  ######################################################################
  # Performs the actual application update.
  proc do_download {content_list} {

    variable data

    array set content $content_list

    # Show the progress bar
    grid .updwin.pf

    # Display the current status
    .updwin.pf.status configure -text [msgcat::mc "Downloading..."]

    # Disable the Download button
    .updwin.bf1.download configure -state disabled

    # If we are in non-full test mode, return now
    if {($data(cl_test_type) ne "") && [string range $data(cl_test_type) 0 4] ne "full-"} {
      return
    }

    # Get the update
    set token [http::geturl $content(download_url) -progress "specl::updater::gzip_download_progress" \
      -channel [set rc [open [set download [file join / tmp [file tail $content(download_url)]]] w]] \
      -binary 1]

    # Close the channel
    close $rc

    # Get the data if the status is okay
    if {([http::status $token] eq "ok") && ([http::ncode $token] == 200)} {

      .updwin.pf.status configure -text [msgcat::mc "Verifying..."]
      update idletasks

      if {[catch { check_bundle $download $content_list } rc]} {

        # Display the error information
        .updwin.if.title configure -text [msgcat::mc "Downloaded data corrupted"]
        .updwin.if.info  configure -text $rc

        # Change the download button to a Close button
        grid remove .updwin.pf
        grid remove .updwin.bf1
        grid .updwin.bf3

      } else {

        # Indicate that the download was successful.
       .updwin.if.title configure -text [msgcat::mc "Download was successful!"]
       .updwin.if.info  configure -text [msgcat::mc "Click \"Install and Restart\" to install the update."]

       # Change the download button to an Install and Restart button
       grid remove .updwin.pf
       grid remove .updwin.bf1
       grid .updwin.bf2

      }

    } else {

      # Display the error information
      .updwin.if.title configure -text [msgcat::mc "Unable to download"]
      .updwin.if.info  configure -text [msgcat::mc "Cannot communicate with download server"]

      # Change the download button to a Close button
      grid remove .updwin.pf
      grid remove .updwin.bf1
      grid .updwin.bf3

    }

    # Clean the token
    http::cleanup $token

  }

  ######################################################################
  # Returns the password entered from the user.
  proc get_password {content_list} {

    variable data
    variable temp_password

    set temp_password ""

    # Create text
    set msg [transform_text $data(ui,pwd_message) $content_list]

    toplevel     .passwin
    wm title     .passwin [transform_text $data(ui,pwd_win_title) $content_list]
    wm resizable .passwin 0 0

    if {$data(cl_test_type) eq ""} {
      wm transient .passwin .updwin
    } else {
      wm protocol .passwin WM_DELETE_WINDOW {}
    }

    # Set the window geometry
    set wx [expr ([winfo screenwidth  .passwin] / 2) - ($data(ui,pwd_win_width)  / 2)]
    set wy [expr ([winfo screenheight .passwin] / 2) - ($data(ui,pwd_win_height) / 2)]
    wm geometry .passwin $data(ui,pwd_win_width)x$data(ui,pwd_win_height)+$wx+$wy

    ttk::frame .passwin.f
    ttk::label .passwin.f.l1 -text $msg -justify center -anchor center
    ttk::label .passwin.f.l2 -text "Root password: "
    ttk::label .passwin.f.l3 -text " "
    ttk::entry .passwin.f.e  -show \u2022 -validate key -validatecommand "specl::updater::validate_password %P"
    ttk::label .passwin.f.l4 -text " "

    bind .passwin.f.e <Return> {
      .passwin.bf.ok state pressed
      update idletasks
      .passwin.bf.ok invoke
    }

    grid rowconfigure    .passwin.f 2 -weight 1
    grid columnconfigure .passwin.f 2 -weight 1
    grid .passwin.f.l1 -row 0 -column 0 -sticky news -padx 2 -pady 2 -columnspan 4
    grid .passwin.f.l2 -row 1 -column 0 -sticky ew   -padx 2 -pady 2
    grid .passwin.f.l3 -row 1 -column 1 -sticky ew   -padx 2 -pady 2
    grid .passwin.f.e  -row 1 -column 2 -sticky ew   -padx 2 -pady 2
    grid .passwin.f.l4 -row 1 -column 3 -sticky ew   -padx 2 -pady 2

    # Hide the error message and shake text
    grid remove .passwin.f.l3

    ttk::frame  .passwin.bf
    ttk::button .passwin.bf.ok -text "OK" -width 6 -command {
      if {[specl::updater::password_check specl::updater::temp_password]} {
        destroy .passwin
      }
    } -state disabled
    ttk::button .passwin.bf.cancel -text "Cancel" -width 6 -command {
      destroy .passwin
    }

    pack .passwin.bf.cancel -side right -padx 2 -pady 2
    pack .passwin.bf.ok     -side right -padx 2 -pady 2

    pack .passwin.f  -fill both -expand yes
    pack .passwin.bf -fill x

    # Center the password window over the update window
    ::tk::PlaceWindow .passwin widget .updwin

    # Grab and focus on the window
    ::tk::SetFocusGrab .passwin .passwin.f.e

    # Wait for the window to be closed
    tkwait window .passwin

    # Release the grab and focus
    ::tk::RestoreFocusGrab .passwin .passwin.f.e

    # Get the returned password and then clear the namespace variable for protection
    set password $temp_password
    set temp_password ""

    return $password

  }

  ######################################################################
  # Validate the given password value.
  proc validate_password {value} {

    if {$value eq ""} {
      .passwin.bf.ok configure -state disabled -default normal
    } else {
      .passwin.bf.ok configure -state normal -default active
    }

    return 1

  }

  ######################################################################
  # Checks to see if the current password is valid.  If it is valid,
  # returns a value of 1.  If it is invalid, select the text and shake the
  # entry field.
  proc password_check {ppassword} {

    variable data

    upvar $ppassword password

    # Check the password
    if {[catch { run_admin_cmd -l [.passwin.f.e get] }]} {

      # Make sure the OK button is normalized
      .passwin.bf.ok state !pressed

      # If we have not exceeded the number of bad attempts, reshow the window
      if {($data(ui,pwd_max_attempts) == 0) || \
          ([incr data(password_attempts)] < $data(ui,pwd_max_attempts))} {

        # Select the bad password
        .passwin.f.e selection range 0 end

        # Shake the entry field
        for {set i 0} {$i < 2} {incr i} {
          grid        .passwin.f.l3
          grid remove .passwin.f.l4
          update idletasks
          after 50
          grid remove .passwin.f.l3
          grid        .passwin.f.l4
          update idletasks
          after 50
        }

        return 0

      } else {

        set password ""

        return 1

      }

    }

    # Make sure the OK button is normalized
    .passwin.bf.ok state !pressed

    # Grab the password and return it
    set password [.passwin.f.e get]

    return 1

  }

  ######################################################################
  # Cause the password to be sent to the command.
  proc run_admin_cmd_write {rc password} {

    catch { puts $rc $password }
    fileevent $rc writable {}

  }

  ######################################################################
  proc run_admin_cmd_read {rc password} {

    variable admin_cmd_done

    set chars [gets $rc line]

    set failed [expr {[string first "try again" $line] != -1}]

    if {[eof $rc] || $failed} {
      fileevent $rc writable {}
      fileevent $rc readable {}
      catch { close $rc }
      set admin_cmd_done $failed
    }

  }

  ######################################################################
  # Runs the given command with administrative privileges.
  proc run_admin_cmd {cmd password} {

    variable admin_cmd_done
  
    if {[catch "open {| sudo -S $cmd 2>@1} r+" rc]} {
      return -code error $rc
    }

    fconfigure $rc -buffering none -blocking 1
    fileevent  $rc writable [list specl::updater::run_admin_cmd_write $rc $password]
    fileevent  $rc readable [list specl::updater::run_admin_cmd_read  $rc $password]
    
    set admin_cmd_done 0

    # Wait for the command to complete
    vwait specl::updater::admin_cmd_done

    if {$admin_cmd_done} {
      return -code error "Password incorrect"
    }

    # Remove the timestamp
    exec -ignorestderr sudo -k

  }

  ######################################################################
  # Performs a more 'manual' trash operation when the gvfs-trash script
  # cannot be found.
  proc linux_manual_trash {install_dir} {

    if {[file exists [set trash [file join ~ .local share Trash]]]} {

      if {[info exists ::env(XDG_DATA_HOME)] && ($::env(XDG_DATA_HOME) ne "") && [file exists $::env(XDG_DATA_HOME)]} {
        set trash $::env(XDG_DATA_HOME)
      }

      set trash_path [specl::utils::get_unique_path [file join $trash files] [file tail $install_dir]]

      if {![catch { open [file join $trash info [file tail $trash_path].trashinfo] w } rc]} {
        puts $rc "\[Trash Info\]"
        puts $rc "Path=$install_dir"
        puts $rc "DeletionDate=[clock format [clock seconds] -format {%Y-%m-%dT%T}]"
        close $rc
      }

      return $trash_path

    } elseif {[file exists [set trash [file join ~ .Trash]]]} {

      set trash_path [specl::utils::get_unique_path [file join $trash files] [file tail $install_dir]]

      return $trash_path

    } else {

      tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to install"] \
                    -detail [msgcat::mc "Unable to trash old library files"]
      exit 1

    }

  }

  ######################################################################
  # Returns the installation path.
  proc get_install_dir {specl_version_dir} {

    # Initialize the installation path to the current directory
    set install_dir $specl_version_dir

    # If we are running on a Mac, find the .app installation directory
    if {$::tcl_platform(os) eq "Darwin"} {
      set path [file split $specl_version_dir]
      if {[set path [file join {*}[lrange $path 0 [lsearch -glob $path *.app]]]] ne ""} {
        set install_dir $path
      }
    }

    return $install_dir

  }

  ######################################################################
  # Installs the downloaded content into the installation directory.
  proc do_install {content_list} {

    variable data

    array set content $content_list

    # Get the name of the downloaded directory
    set app      "$specl::appname-$content(version)"
    set download [file join / tmp $app]

    if {$data(cl_test_type) eq ""} {

      # Get the name of the installation directory
      set install_dir [get_install_dir $data(specl_version_dir)]

      # Move the original directory to the trash
      switch -glob $::tcl_platform(os) {
        Darwin {
          set download [file join / tmp [file tail $install_dir]]
          set cmd      "tell app \"Finder\" to move the POSIX file \"$install_dir\" to trash"
          if {[catch { exec -ignorestderr osascript -e $cmd }]} {
            set trash_path [specl::utils::get_unique_path [file join ~ .Trash] [file tail $install_dir]]
          }
        }
        Linux* {
          if {![catch { exec -ignorestderr which gvfs-trash 2>@1 }]} {
            if {[catch { exec -ignorestderr gvfs-trash $install_dir }]} {
              set password [get_password $content_list]
              if {[catch { run_admin_cmd "gvfs-trash [list $install_dir]" $password }]} {
                set trash_path [linux_manual_trash $install_dir]
              }
            }
          } elseif {![catch { exec -ignorestderr which kioclient 2>@1 }]} {
            if {[catch { exec -ignorestderr kioclient move $install_dir trash:/ }]} {
              set password [get_password $content_list]
              if {[catch { run_admin_cmd "kioclient move [list $install_dir] trash:/" $password }]} {
                set trash_path [linux_manual_trash $install_dir]
              }
            }
          } elseif {![catch { exec -ignorestderr which gio 2>@1 }]} {
            if {[catch { exec -ignorestderr gio trash $install_dir }]} {
              set password [get_password $content_list]
              if {[catch { run_admin_cmd "gio trash [list $install_dir]" $password }]} {
                set trash_path [linux_manual_trash $install_dir]
              }
            }
          } else {
            set trash_path [linux_manual_trash $install_dir]
          }
        }
        *Win*  {
          set binit [file join [file dirname $::argv0] .. bin binit.exe]
          if {[namespace exists ::freewrap] && [zvfs::exists $binit]} {
            if {[catch { exec -ignorestderr [freewrap::unpack $binit] $fname }]} {
              tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to install"] -detail $rc
              exit 1
            }
          } elseif {[file exists $binit]} {
            if {[catch { exec -ignorestderr $binit $fname } rc]} {
              tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to install"] -detail $rc
              exit 1
            }
          } elseif {[file exists [file join C: RECYCLER]]} {
            set trash_path [file join C: RECYCLER]
          } elseif {[file exists [file join C: {$Recycle.bin}]]} {
            set trash_path [file join C: {$Recycle.bin}]
          } else {
            tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to install"] -detail $rc
            exit 1
          }
        }
        default {
          tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to install"] -detail $rc
          exit 1
        }
      }

      # Move the installation directory to the trash
      if {[info exists trash_path]} {
        if {[catch { file rename -force $install_dir $trash_path } rc]} {
          if {![info exists password]} {
            set password [get_password $content_list]
          }
          if {[catch { run_admin_cmd [list mv $install_dir $trash_path] $password } rc]} {
            tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to install"] -detail $rc
            exit 1
          }
        }
      }

      # Perform the directory move
      if {[catch { file rename -force $download $install_dir } rc]} {
        if {![info exists password]} {
          set password [get_password $content_list]
        }
        if {[catch { run_admin_cmd [list mv $download $install_dir] $password } rc]} {
          tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to install"] -detail $rc
          exit 1
        }
      }

    } else {

      # Just delete the download directory since we are just testing
      file delete -force $download

    }

    exit

  }

  ######################################################################
  # Removes the downloaded content and quit the updater.
  proc do_cancel_install {content_list} {

    array set content $content_list

    # Delete the downloaded content
    catch { file delete -force [file join / tmp [file rootname [file tail $content(download_url)]]] }

    # Kill the window and exit the updater
    destroy .updwin
    exit 1

  }

  ######################################################################
  # Returns the size string for the given number of bytes
  proc get_size_string {bytes} {

    if {[set mbs [expr $bytes.0 / pow(2,20)]] > 1} {
      return [format {%.1f MB} $mbs]
    } else {
      return [format {%.1f KB} [expr $bytes.0 / pow(2,10)]]
    }

  }

  ######################################################################
  # Called whenever the geturl call for the do_download procedure needs to
  # update progress.
  proc gzip_download_progress {token total current} {

    # Update the progress bar
    .updwin.pf.pb configure -value [expr int( ($current / $total.0) * 100 )]

    # Update the download progress display
    .updwin.pf.info configure -text [msgcat::mc "%s of %s" [get_size_string $current] [get_size_string $total]]

  }

  ######################################################################
  # Displays the update information and allows the user to either
  # do the update or stop the update.
  proc display_update {content_list} {

    variable widgets
    variable data

    array set content $content_list

    # Initialize information
    set title          [transform_text $data(ui,upd_title)   $content_list]
    set msg            [transform_text $data(ui,upd_message) $content_list]
    set appicon_column [expr {($data(ui,appicon_side) eq "right") ? 2 : 0}]

    toplevel     .updwin
    wm title     .updwin [transform_text $data(ui,upd_win_title) $content_list]
    if {!$data(ui,upd_win_resizable)} {
      wm resizable .updwin 0 0
    } else {
      wm minsize .updwin $data(ui,upd_win_width) $data(ui,upd_win_height)
    }
    wm attributes .updwin -topmost 1
    wm protocol   .updwin WM_DELETE_WINDOW {}

    # Set the window geometry
    set wx [expr ([winfo screenwidth  .updwin] / 2) - ($data(ui,upd_win_width)  / 2)]
    set wy [expr ([winfo screenheight .updwin] / 2) - ($data(ui,upd_win_height) / 2)]
    wm geometry  .updwin $data(ui,upd_win_width)x$data(ui,upd_win_height)+$wx+$wy

    ttk::frame .updwin.if
    ttk::label .updwin.if.appicon
    ttk::label .updwin.if.title -text $title -font [specl::utils::bold_font]
    ttk::label .updwin.if.info  -text $msg

    # If there is an appicon, create it and assign it to the appicon label
    if {$data(ui,appicon_path) ne ""} {
      .updwin.if.appicon configure -image [set appicon [image create photo -file $data(ui,appicon_path)]]
    }

    grid rowconfigure    .updwin.if 1 -weight 1
    grid columnconfigure .updwin.if 1 -weight 1
    grid .updwin.if.appicon -row 0 -column $appicon_column -padx 2 -pady 2 -rowspan 2
    grid .updwin.if.title   -row 0 -column 1            -padx 2 -pady 2
    grid .updwin.if.info    -row 1 -column 1            -padx 2 -pady 2

    ttk::frame       .updwin.pf
    ttk::progressbar .updwin.pf.pb -mode determinate -length [expr $data(ui,upd_win_width) - 120]
    ttk::label       .updwin.pf.status
    ttk::label       .updwin.pf.info

    grid .updwin.pf.pb     -row 0 -column 0 -sticky ew -padx 2 -pady 2
    grid .updwin.pf.status -row 0 -column 1 -sticky ew -padx 2 -pady 2
    grid .updwin.pf.info   -row 1 -column 0 -sticky ew -padx 2 -pady 2

    ttk::frame     .updwin.hf
    set widgets(html) [text .updwin.hf.h \
      -xscrollcommand "specl::utils::set_xscrollbar .updwin.hf.hb" \
      -yscrollcommand "specl::utils::set_yscrollbar .updwin.hf.vb"]
    ttk::scrollbar .updwin.hf.vb -orient vertical   -command ".updwin.hf.h yview"
    ttk::scrollbar .updwin.hf.hb -orient horizontal -command ".updwin.hf.h xview"

    grid rowconfigure    .updwin.hf 0 -weight 1
    grid columnconfigure .updwin.hf 0 -weight 1
    grid .updwin.hf.h  -row 0 -column 0 -sticky news
    grid .updwin.hf.vb -row 0 -column 1 -sticky ns
    grid .updwin.hf.hb -row 1 -column 0 -sticky ew

    ttk::frame  .updwin.bf1
    ttk::button .updwin.bf1.download -text [msgcat::mc "Download"] -width 8 -command [list specl::updater::do_download $content_list]
    ttk::button .updwin.bf1.cancel   -text [msgcat::mc "Cancel"]   -width 8 -command { destroy .updwin; exit 1 }

    pack .updwin.bf1.cancel   -side right -padx 2 -pady 2
    pack .updwin.bf1.download -side right -padx 2 -pady 2

    ttk::frame  .updwin.bf2
    ttk::button .updwin.bf2.install -text [msgcat::mc "Install and Restart"] -command [list specl::updater::do_install $content_list]
    ttk::button .updwin.bf2.cancel  -text [msgcat::mc "Cancel"] -width 8     -command [list specl::updater::do_cancel_install $content_list]

    pack .updwin.bf2.cancel  -side right -padx 2 -pady 2
    pack .updwin.bf2.install -side right -padx 2 -pady 2

    ttk::frame  .updwin.bf3
    ttk::button .updwin.bf3.close -text [msgcat::mc "Close"] -width 8 -command [list specl::updater::do_cancel_install $content_list]

    pack .updwin.bf3.close -side right -padx 2 -pady 2

    grid rowconfigure    .updwin 2 -weight 1
    grid columnconfigure .updwin 0 -weight 1
    grid .updwin.if  -row 0 -column 0 -sticky news
    grid .updwin.pf  -row 1 -column 0 -sticky news
    grid .updwin.hf  -row 2 -column 0 -sticky news
    grid .updwin.bf1 -row 3 -column 0 -sticky news
    grid .updwin.bf2 -row 4 -column 0 -sticky news
    grid .updwin.bf3 -row 5 -column 0 -sticky news

    grid remove .updwin.pf
    grid remove .updwin.bf2
    grid remove .updwin.bf3

    # Add the HTML to the HTML widget
    specl::utils::HMinitialize $widgets(html)
    HMparse_html $content(description) "HMrender $widgets(html)"

    # Configure the text widget to be disabled
    $widgets(html) configure -state disabled

    # Wait for the window to be closed
    tkwait window .updwin

    # Delete the appicon
    if {[info exists appicon]} {
      image delete $appicon
    }

  }

  ######################################################################
  # Displays the up-to-date window.
  proc display_up_to_date {content_list} {

    variable data

    array set content $content_list

    toplevel      .utdwin
    wm title      .utdwin ""
    wm resizable  .utdwin 0 0
    wm attributes .utdwin -topmost 1
    wm protocol   .utdwin WM_DELETE_WINDOW {}

    # Set the window geometry
    set wx [expr ([winfo screenwidth  .utdwin] / 2) - ($data(ui,utd_win_width)  / 2)]
    set wy [expr ([winfo screenheight .utdwin] / 2) - ($data(ui,utd_win_height) / 2)]
    wm geometry .utdwin $data(ui,utd_win_width)x$data(ui,utd_win_height)+$wx+$wy

    # Create text
    set title          [transform_text $data(ui,utd_title)   $content_list]
    set msg            [transform_text $data(ui,utd_message) $content_list]
    set appicon_column [expr {($data(ui,appicon_side) eq "right") ? 2 : 0}]

    ttk::frame .utdwin.f
    ttk::label .utdwin.f.appicon
    ttk::label .utdwin.f.title -text $title -font [specl::utils::bold_font]
    ttk::label .utdwin.f.msg   -text $msg

    # If there is an appicon, create it and assign it to the appicon label
    if {$data(ui,appicon_path) ne ""} {
      .utdwin.f.appicon configure -image [set appicon [image create photo -file $data(ui,appicon_path)]]
    }

    grid rowconfigure    .utdwin.f 1 -weight 1
    grid columnconfigure .utdwin.f 1 -weight 1
    grid .utdwin.f.appicon -row 0 -column $appicon_column -padx 2 -pady 2 -sticky new -rowspan 2
    grid .utdwin.f.title   -row 0 -column 1               -padx 2 -pady 2
    grid .utdwin.f.msg     -row 1 -column 1               -padx 2 -pady 2 -sticky n

    ttk::frame  .utdwin.bf
    ttk::button .utdwin.bf.ok -text [msgcat::mc "OK"] -width 6 -default active -command {
      destroy .utdwin
    }

    pack .utdwin.bf.ok -padx 2 -pady 2

    pack .utdwin.f  -fill both -expand yes
    pack .utdwin.bf -fill x

    # Grab the focus
    ::tk::SetFocusGrab .utdwin .utdwin.b

    # Wait for the window to be closed
    tkwait window .utdwin

    # Release the grab
    ::tk::RestoreFocusGrab .utdwin .utdwin.b

    # Delete the appicon
    if {[info exists appicon]} {
      image delete $appicon
    }

  }

  ######################################################################
  # Loads the specl_customize.xml file, if it exists.
  proc load_customizations {} {

    variable data

    if {![catch { open [file join $data(specl_version_dir) specl_customize.xml] r } rc]} {

      # Read the data
      set contents [read $rc]
      close $rc

      # Parse the XML
      if {[catch { dom::parse $contents } dom]} {
        return -code error "Unable to parse RSS contents: $dom"
      }

      # Parse the customization XML
      if {![catch { specl::utils::get_element $dom "customizations" } custom_node]} {

        # Get translation directory
        if {![catch { specl::utils::get_element $custom_node "translations" } trans_node]} {
          if {![catch { specl::utils::get_attr $trans_node "dir"} value]} {
            set data(translation_dir) $value
          }
        }

        # Get icon information
        if {![catch { specl::utils::get_element $custom_node "icon" } icon_node]} {
          if {![catch { specl::utils::get_attr $icon_node "path" } value]} {
            set data(ui,icon_path) [file join $data(specl_version_dir) $value]
            wm iconphoto . -default [image create photo -file $data(ui,icon_path)]
          }
        }

        # Get appicon information
        if {![catch { specl::utils::get_element $custom_node "appicon" } appicon_node]} {
          if {![catch { specl::utils::get_attr $appicon_node "path" } value]} {
            set data(ui,appicon_path) [file join $data(specl_version_dir) $value]
          }
          foreach attr [list side] {
            if {![catch { specl::utils::get_attr $appicon_node $attr } value]} {
              set data(ui,appicon_$attr) $value
            }
          }
        }

        # Get update window information
        if {![catch { specl::utils::get_element $custom_node "update" } update_node]} {
          if {![catch { specl::utils::get_element $update_node "window" } window_node]} {
            foreach name [list width height resizable] {
              if {![catch { specl::utils::get_attr $window_node $name } value]} {
                set data(ui,upd_win_$name) $value
              }
            }
            if {![catch { specl::utils::get_element $window_node "title" } title_node]} {
              set data(ui,upd_win_title) [specl::utils::get_text $title_node]
            }
          }
          foreach name [list title message] {
            if {![catch { specl::utils::get_element $update_node $name } node]} {
              set data(ui,upd_$name) [specl::utils::get_text $node]
            }
          }
        }

        # Get up-to-date window information
        if {![catch { specl::utils::get_element $custom_node "uptodate" } uptodate_node]} {
          if {![catch { specl::utils::get_element $uptodate_node "window" } window_node]} {
            foreach name [list width height] {
              if {![catch { specl::utils::get_attr $window_node $name } value]} {
                set data(ui,utd_win_$name) $value
              }
            }
          }
          foreach name [list title message] {
            if {![catch { specl::utils::get_element $uptodate_node $name } node]} {
              set data(ui,utd_$name) [specl::utils::get_text $node]
            }
          }
        }

        # Get password window information
        if {![catch { specl::utils::get_element $custom_node "password" } password_node]} {
          foreach name [list max_attempts] {
            if {![catch { specl::utils::get_attr $password_node $name } value]} {
              set data(ui,pwd_$name) $value
            }
          }
          if {![catch { specl::utils::get_element $password_node "window" } window_node]} {
            foreach name [list width height] {
              if {![catch { specl::utils::get_attr $window_node $name } value]} {
                set data(ui,pwd_win_$name) $value
              }
            }
            if {![catch { specl::utils::get_element $window_node "title" } title_node]} {
              set data(ui,pwd_win_title) [specl::utils::get_text $title_node]
            }
          }
          foreach name [list title message] {
            if {![catch { specl::utils::get_element $password_node $name } node]} {
              set data(ui,pwd_$name) [specl::utils::get_text $node]
            }
          }
        }

      }

    }

  }


  ######################################################################
  # Perform the update.
  proc start_update {} {

    variable data

    # Load the customization file if it exists
    catch { load_customizations }

    # If a translation directory was specified, load it
    if {$data(translation_dir) ne ""} {
      catch { msgcat::mcload $data(translation_dir) }
    }

    # Load the specl_version.tcl file
    if {[catch { specl::load_specl_version $data(specl_version_dir) } rc]} {
      tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to update"] -detail $rc
      exit 1
    }

    # Enable HTTPS transfer, if necessary
    if {[string range $specl::rss_url 0 4] eq "https"} {
      catch { ::http::register https 443 ::tls::socket }
    }

    # If we are running in live mode, fetch the appcast data and parse it
    if {($data(cl_test_type) eq "") || ([string range $data(cl_test_type) 0 4] eq "full-")} {

      # If we are testing the update path, set the release to force one to occur (last release)
      if {$data(cl_test_type) eq "full-update"} {
        incr specl::release -1
      }

      # Get the URL
      if {[catch "fetch_url" rc]} {
        tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to update"] -detail $rc
        exit 1
      }

      # If there was an issue with the download, display the message to the user.
      if {$data(fetch_content) eq ""} {
        tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to update"] -detail [msgcat::mc "Error code: %s\%s" $data(fetch_ncode) $data(fetch_error)]
        exit 1
      }

      # Parse the data
      if {[catch "parse_data" rc]} {
        tk_messageBox -parent . -default ok -type ok -message [msgcat::mc "Unable to parse update"] -detail $rc
        exit 1
      }

      # Get the content
      array set content $rc

      # If we are testing the up-to-date path, set the release to force it to occur (current release)
      if {$data(cl_test_type) eq "full-uptodate"} {
        set specl::release $content(release)
        set data(cl_force) 0
      }

      # If the content does not require an update, tell the user
      if {($content(release) <= $specl::release) && !$data(cl_force)} {
        if {!$data(cl_quiet)} {
          display_up_to_date $rc
        }
        exit 1
      } else {
        display_update $rc
      }

    } else {

      set    sample_text "<h2>Version (3.4) Release Notes</h2><br>"
      append sample_text "This is some <code>sample text</code> describing this release.<br><br>"
      append sample_text "<b>New Features</b>"
      append sample_text "<ul>"
      append sample_text "<li>Feature 1</li>"
      append sample_text "<li>Feature 2</li>"
      append sample_text "<li>Feature 3</li>"
      append sample_text "</ul>"

      set rc [list description $sample_text download_url "" version "3.4" release 10 \
                   length 7042856 checksum foobar num_updates  1]

      # Display the desired window
      switch $data(cl_test_type) {
        "update"   { display_update $rc }
        "uptodate" { display_up_to_date $rc }
        "password" { get_password $rc }
      }

    }

    # Stop the application
    exit

  }

  ######################################################################
  # Transforms the given text string by substituting keywords with values.
  proc transform_text {txt content_list} {

    variable data

    array set content $content_list

    # Create text map
    set text_map(APPNAME)    $specl::appname
    set text_map(CURVERSION) $specl::version
    set text_map(NEWVERSION) $content(version)
    set text_map(UPDATES)    $content(num_updates)
    set text_map(FILESIZE)   [get_size_string $content(length)]
    set text_map(RELTYPE)    [expr {($data(cl_release_type) == $specl::RTYPE_STABLE) ? "stable" : "development"}]

    set values [list]
    while {[regexp "^\(.*?\){\([join [array names text_map] |]\)}\(.*\)\$" $txt -> before key after]} {
      set txt "$before%s$after"
      lappend values $text_map($key)
    }

    return [msgcat::mc $txt {*}$values]

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
  specl::updater::usage
}

# Parse command-line arguments
set args $argv
switch -exact -- [lindex $args 0] {
  -h      { specl::updater::usage }
  -v      { puts $specl::version; exit }
  default {
    if {![specl::updater::parse_args $args]} {
      puts "ERROR:  Incorrect arguments passed to specl update command"
      specl::updater::usage
    }
    specl::updater::start_update
  }
}
