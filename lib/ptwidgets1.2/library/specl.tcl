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

package provide specl 1.2

namespace eval specl {
  
  variable appname      ""
  variable version      ""
  variable release      1
  variable rss_url      ""
  variable download_url ""
  variable icon_path    ""
  
  ######################################################################
  # Returns the full, normalized pathname of the specl_version.tcl file.
  proc get_specl_version_dir {start_dir} {
    
    set current_dir [file normalize $start_dir]
    while {($current_dir ne "/") && ![file exists [file join $current_dir specl_version.tcl]]} {
      set current_dir [file dirname $current_dir]
    }
    
    # If we could not find the specl_version.tcl file, return an error
    if {$current_dir eq "/"} {
      return -code error "Unable to find specl_version.tcl file"
    }
    
    return $current_dir
    
  }
  
  ######################################################################
  # Loads the specl version file.
  proc load_specl_version {specl_version_dir} {
    
    # Read the version and URL information
    if {[catch "source [file join $specl_version_dir specl_version.tcl]" rc]} {
      return -code error $rc
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
      if {[set path [file join [lrange $path 0 [lsearch -glob $path *.app]]]] ne ""} {
        set install_dir $path
      }
    }
    
    return $install_dir
    
  }
  
  ######################################################################
  # Checks for updates.  Throws an exception if there was a problem
  # checking for the update.
  proc check_for_update {{cl_args {}} {cleanup_script {}}} {
    
    # Allow the UI to update before we proceed
    update
    
    # Loads the specl_version.tcl file
    set specl_version_dir [get_specl_version_dir [file dirname $::argv0]]
    
    # Get the current file
    array set frame [info frame 0]
    
    # Get the normalized name of argv0
    set script_name [file normalize $::argv0]
    
    # Execute this script
    if {[catch { exec -ignorestderr [info nameofexecutable] $frame(file) -- update $specl_version_dir } rc options]} {
      return
    }
    
    # If there is a cleanup script to execute, do it now
    if {$cleanup_script ne ""} {
      eval $cleanup_script
    }
    
    # Relaunch the application
    cd $specl_version_dir
    exec [info nameofexecutable] $script_name {*}$cl_args &
    
    # Exit this application
    exit
    
  }
  
}
  
######################################################################
# APPLICATION CODE BELOW
######################################################################
  
namespace eval specl::helpers {
  
  array set xignore    {}
  array set xignore_id {}
  
  ######################################################################
  # Returns the node content found within the given parent node.
  proc get_elements {node name} {
    
    set node_content [lindex $node 1]
    set elements     [list]

    while {1} {
      if {[regexp "<$name\(.*?\)>\(.*?\)</$name>\(.*\)\$" $node_content -> attrs content node_content]} {
        lappend elements [list [string trim $attrs] [string trim $content]]
      } elseif {[regexp "<$name\(.*?\)/>\(.*\)\$" $node_content -> attrs node_content]} {
        lappend elements [list [string trim [string range $attrs 0 end-1]] ""]
      } else {
        break
      }
    }

    return $elements
    
  }

  ######################################################################
  # Returns a single element node.
  proc get_element {node name} {

    set elements [get_elements $node $name]

    return [lindex $elements 0]

  }
  
  ######################################################################
  # Returns the data located inside the CDATA element.
  proc get_cdata {node} {
    
    if {[regexp {<!\[CDATA\[(.*?)\]\]>} [lindex $node 1] -> content]} {
      return [string trim $content]
    } else {
      return -code error "Node does not contain CDATA"
    }
    
  }
  
  ######################################################################
  # Searches for and returns the attribute in the specified parent.
  proc get_attr {parent name} {
    
    if {[regexp "$name\\s*=\\s*\"\(\[^\"]*\)\"" [lindex $parent 0] -> attr]} {
      return $attr
    } else {
      return -code error "Node does not contain attribute '$name'"
    }
    
  }
  
  ######################################################################
  # Returns a unique pathname in the given directory.
  proc get_unique_path {dpath fname} {
    
    set path  [file join $dpath $fname]
    set index 0
    while {[file exists $path]} {
      set path [file join $dpath "$fname ([incr index])"]
    }
    
    return $path
    
  }
  
  ###########################################################################
  # Performs the set operation on a given yscrollbar.
  proc set_yscrollbar {sb first last} {
        
    # If everything is displayed, hide the scrollbar
    if {($first == 0) && (($last == 1) || ($last == 0))} {
      grid remove $sb
    } else {
      grid $sb
      $sb set $first $last
    }

  }
  
  ######################################################################
  # Performs the set operation on a given xscrollbar.
  proc set_xscrollbar {sb first last} {
    
    variable xignore
    variable xignore_id
    
    if {($first == 0) && ($last == 1)} {
      grid remove $sb
      set_xignore $sb 1 0
      set xignore_id($sb) [after 1000 [list specl::helpers::set_xignore $sb 0 1]]
    } else {
      if {![info exists xignore($sb)] || !$xignore($sb)} {
        grid $sb
        $sb set $first $last
      }
      set_xignore $sb 0 0
    }
    
  }
  
  ######################################################################
  # Clears the xignore and xignore_id values.
  proc set_xignore {sb value auto} {
  
    variable xignore
    variable xignore_id
        
    # Clear the after (if it exists)
    if {[info exists xignore_id($sb)]} {
      after cancel $xignore_id($sb)
      unset xignore_id($sb)
    }
    
    # Set the xignore value to the specified value
    set xignore($sb) $value
    
  }
    
}
  
###################################################  UPDATER  ###################################################

namespace eval specl::updater {
  
  array set widgets {}
  
  array set data {
    specl_version_dir ""
    icon              ""
    fetch_ncode       ""
    fetch_content     ""
    fetch_error       ""
    stylecount        0
    cancel            0
  }

  ######################################################################
  # Fetches the application RSS feed sheet from the stored URL.
  proc fetch_url {} {
    
    variable data
    
    # Get the data from the given URL
    set token [http::geturl "$specl::rss_url/appcast.xml"]
    
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
    
    set first       1
    set description ""
    
    # Get the contents of the 'releases' node
    set releases_node [specl::helpers::get_element [list "" $data(fetch_content)] "releases"]
    
    # Get the contents of the next 'release' node
    foreach release_node [specl::helpers::get_elements $releases_node "release"] {
    
      set release [specl::helpers::get_attr $release_node "index"]
      set version [specl::helpers::get_attr $release_node "version"]

      if {[specl::helpers::get_attr $release_node "index"] >= $specl::release} {

        # Set the title
        set title "<h2>Version ($version) Release Notes</h2>"

        # Get any release notes
        if {![catch { specl::helpers::get_element $release_node "specl:releaseNotesLink" } release_link] && \
            ([lindex $release_link 1] ne "")} {
         
          # Retrieve the release notes from the given link
          set token [http::geturl [lindex $release_link 1]]
         
          # Get the HTML description
          if {([http::status $token] eq "ok") && ([http::ncode $token] == 200)} {
            set curr_description [http::data $token]
          } else {
            set curr_description "No description available"
          }
         
          # Cleanup the HTTP token
          http::cleanup $token
         
        # Otherwise, attempt to get the description from the embedded description
        } elseif {![catch { specl::helpers::get_element $release_node "description" } description_node]} {
         
          # Remove the CDATA around the description
          if {[catch { specl::helpers::get_cdata $description_node } curr_description]} {
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
          
          # Get the download information
          set download_node [specl::helpers::get_element $release_node "download"]
           
          # Get the download URL
          set download_url [specl::helpers::get_attr $download_node "url"]
           
          # Get the file length
          set length [specl::helpers::get_attr $download_node "length"]
           
          # Get the md5 checksum
          set checksum [specl::helpers::get_attr $download_node "checksum"]
          
          set first 0
          
        } else {
          
          # Append to the current description
          append description "<br><hr>$title<br>$curr_description"
          
        }
        
      }
      
    }
    
    return [list description  $description \
                 download_url $download_url \
                 version      $latest_version \
                 release      $latest_release \
                 length       $length \
                 checksum     $checksum]
    
  }
  
  ######################################################################
  # Unpacks the content into the tmp directory.
  proc check_tarball {tarball content_list} {
    
    variable data
    
    array set content $content_list
    
    # Check the file size against the stored data
    if {[file size $tarball] ne $content(length)} {
      return -code error "Downloaded tarball is not the expected length"
    }
    
    # Check the md5 checksum against the stored data
    if {[specl::releaser::get_checksum $tarball] ne $content(checksum)} {
      return -code error "Downloaded tarball has an incorrect checksum"
    }
    
    # Unpack the tarball into the down directory
    if {[catch { exec -ignorestderr tar xf $tarball -C [file join / tmp] } rc]} {
      return -code error $rc
    }
    
  }
  
  ######################################################################
  # Performs the actual application update.
  proc do_download {content_list} {
    
    array set content $content_list
    
    # Show the progress bar
    grid .updwin.pf
    
    # Display the current status
    .updwin.pf.status configure -text "Downloading..."
    
    # Get the update
    set token [http::geturl $content(download_url) -progress "specl::updater::gzip_download_progress" \
      -channel [set rc [open [set download [file join / tmp [file tail $content(download_url)]]] w]]]
      
    # Close the channel
    close $rc
    
    # Get the data if the status is okay
    if {([http::status $token] eq "ok") && ([http::ncode $token] == 200)} {
      
      .updwin.pf.status configure -text "Verifying..."
      # .updwin.pf.pb     configure -mode indeterminate
      update idletasks
      
      if {[catch { check_tarball $download $content_list } rc]} {
        
        # Display the error information
        .updwin.if.title configure -text "Downloaded data corrupted"
        .updwin.if.info  configure -text $rc
        
        # Change the download button to a Close button
        grid remove .updwin.pf
        grid remove .updwin.bf1
        grid .updwin.bf3
        
      } else {
        
        # Indicate that the download was successful.
       .updwin.if.title configure -text "Download was successful!"
       .updwin.if.info  configure -text "Click \"Install and Restart\" to install the update."
    
       # Change the download button to an Install and Restart button
       grid remove .updwin.pf
       grid remove .updwin.bf1
       grid .updwin.bf2
    
      }
      
    } else {
      
      # Display the error information
      .updwin.if.title configure -text "Unable to download"
      .updwin.if.info  configure -text "Cannot communicate with download server"
        
      # Change the download button to a Close button
      grid remove .updwin.pf
      grid remove .updwin.bf1
      grid .updwin.bf3
        
    }
    
    # Clean the token
    http::cleanup $token
    
  }
  
  ######################################################################
  # Installs the downloaded content into the installation directory.
  proc do_install {content_list} {
    
    variable data
    
    array set content $content_list
    
    # Get the name of the downloaded directory
    set app      "$specl::appname-$content(version)"
    set download [file join / tmp $app]
    
    # Get the name of the installation directory
    set install_dir [specl::get_install_dir $data(specl_version_dir)]
    
    # Attempt to write a file to the installation directory (to see if su permissions are needed)
    if {[catch { open [file join $install_dir .specl_test] w } rc]} {
      lassign [get_username_password] username password
      set rename_cmd "sudo -A mv $download $install_dir"
    } else {
      close $rc
      set rename_cmd "mv $download $install_dir"
    }
    
    # Move the original directory to the trash
    switch -glob $::tcl_platform(os) {
      Darwin {
        set trash_path [specl::helpers::get_unique_path [file join ~ .Trash] [file tail $install_dir]]
      }
      Linux* {
        if {[catch { exec -ignorestderr gvfs-trash [file tail $install_dir] }]} {
          if {[file exists [set trash [file join ~ .local share Trash]]]} {
            if {[info exists ::env(XDG_DATA_HOME)] && \
                ($::env(XDG_DATA_HOME) ne "") && \
                [file exists $::env(XDG_DATA_HOME)]} {
              set trash $::env(XDG_DATA_HOME)
            }
            set trash_path [specl::helpers::get_unique_path [file join $trash files] [file tail $install_dir]]
            if {![catch { open [file join $trash info [file tail $trash_path].trashinfo] w } rc]} {
              puts $rc "\[Trash Info\]"
              puts $rc "Path=$install_dir"
              puts $rc "DeletionDate=[clock format [clock seconds] -format {%Y-%m-%dT%T}]"
              close $rc
            }
          } else {
            tk_messageBox -parent . -default ok -type ok -message "Unable to install" -detail "Unable to trash old library files"
            exit 1
          }
        }
      }
      *Win*  { 
        if {[file exists [file join C: RECYCLER]]} {
          set trash_path [file join C: RECYCLER]
        } elseif {[file exists [file join C: {$Recycle.bin}]]} {
          set trash_path [file join C: {$Recycle.bin}]
        } else {
          tk_messageBox -parent . -default ok -type ok -message "Unable to install" -detail $rc
          exit 1
        }
      }
      default {
        tk_messageBox -parent . -default ok -type ok -message "Unable to install" -detail $rc
        exit 1
      }
    }
    
    # Move the installation directory to the trash
    if {[catch { file rename -force $install_dir $trash_path } rc]} {
      tk_messageBox -parent . -default ok -type ok -message "A Unable to install" -detail $rc
      exit 1
    }
    
    # Perform the directory move
    if {[catch { file rename -force $download $install_dir } rc]} {
      tk_messageBox -parent . -default ok -type ok -message "B Unable to install" -detail $rc
      exit 1
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
  # Called whenever the geturl call for the do_download procedure needs to
  # update progress.
  proc gzip_download_progress {token total current} {
    
    .updwin.pf.pb configure -value [expr int( ($current / $total.0) * 100 )]
    
  }
  
  ######################################################################
  # Displays the update information and allows the user to either
  # do the update or stop the update.
  proc display_update {content_list} {
    
    variable widgets
    variable data
    
    array set content $content_list
    
    toplevel     .updwin
    wm title     .updwin "Software Updater"
    wm geometry  .updwin 500x400
    wm resizable .updwin 0 0
    
    set msg "Version ($content(version)) is ready for installation. "
    append msg "You are currently\nusing version ($specl::version). "
    append msg "Click Download to update your version."
    
    ttk::frame .updwin.if
    ttk::label .updwin.if.icon
    ttk::label .updwin.if.title -text "A new version of $specl::appname is available!" -font TkHeadingFont
    ttk::label .updwin.if.info  -text $msg
    
    if {$data(icon) ne ""} {
      .updwin.if.icon configure -image $data(icon)
    }
    
    grid rowconfigure    .updwin.if 1 -weight 1
    grid columnconfigure .updwin.if 1 -weight 1
    grid .updwin.if.icon  -row 0 -column 0 -padx 2 -pady 2 -rowspan 2
    grid .updwin.if.title -row 0 -column 1 -padx 2 -pady 2
    grid .updwin.if.info  -row 1 -column 1 -padx 2 -pady 2
    
    ttk::frame       .updwin.pf
    ttk::progressbar .updwin.pf.pb -mode determinate -length 300
    ttk::label       .updwin.pf.status
    
    pack .updwin.pf.pb     -side left -padx 2 -pady 2 -fill x
    pack .updwin.pf.status -side left -padx 2 -pady 2
    
    ttk::frame     .updwin.hf
    set widgets(html) [html .updwin.hf.h -width 400 -height 200 \
      -xscrollcommand "specl::helpers::set_xscrollbar .updwin.hf.hb" \
      -yscrollcommand "specl::helpers::set_yscrollbar .updwin.hf.vb"]
    ttk::scrollbar .updwin.hf.vb -orient vertical   -command ".updwin.hf.h yview"
    ttk::scrollbar .updwin.hf.hb -orient horizontal -command ".updwin.hf.h xview"
    
    grid rowconfigure    .updwin.hf 0 -weight 1
    grid columnconfigure .updwin.hf 0 -weight 1
    grid .updwin.hf.h  -row 0 -column 0 -sticky news
    grid .updwin.hf.vb -row 0 -column 1 -sticky ns
    grid .updwin.hf.hb -row 1 -column 0 -sticky ew
    
    ttk::frame  .updwin.bf1
    ttk::button .updwin.bf1.update -text "Download" -width 8 -command [list specl::updater::do_download $content_list]
    ttk::button .updwin.bf1.cancel -text "Cancel"   -width 8 -command { destroy .updwin; exit 1 }
    
    pack .updwin.bf1.cancel -side right -padx 2 -pady 2
    pack .updwin.bf1.update -side right -padx 2 -pady 2
    
    ttk::frame  .updwin.bf2
    ttk::button .updwin.bf2.install -text "Install and Restart" -command [list specl::updater::do_install $content_list]
    ttk::button .updwin.bf2.cancel  -text "Cancel" -width 8     -command [list specl::updater::do_cancel_install $content_list]
    
    pack .updwin.bf2.cancel  -side right -padx 2 -pady 2
    pack .updwin.bf2.install -side right -padx 2 -pady 2
    
    ttk::frame  .updwin.bf3
    ttk::button .updwin.bf3.close -text "Close" -width 8 -command [list specl::updater::do_cancel_install $content_list]
    
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
    
    # Tie together some stuff for the HTML widget to handle CSS
    $widgets(html) handler script style specl::updater::style_handler
    $widgets(html) configure -imagecmd specl::updater::image_handler
    
    # Add the HTML to the HTML widget
    $widgets(html) reset
    catch { $widgets(html) parse -final $content(description) }
    
    # Wait for the window to be closed
    tkwait window .updwin
    
  }
  
  ######################################################################
  # Handles any styling information to the HTML widget.
  proc style_handler {attr tagcontents} {
    
    variable data
    variable widgets
    
    set id "author.[format %.4d [incr data(stylecount)]]"
    $widgets(html) style -id $id.9999 $tagcontents
    
  }
  
  ######################################################################
  # Handles any images in the HTML.
  proc image_handler {data} {
    
    regexp {data:image/png;base64,(.*)} $data -> data
    
    return [image create photo -data $data]
    
  }
  
  ######################################################################
  # Perform the update.
  proc start_update {} {
    
    variable data
    
    # Load the specl_version.tcl file
    if {[catch { specl::load_specl_version $data(specl_version_dir) } rc]} {
      tk_messageBox -parent . -default ok -type ok -message "Unable to update" -detail $rc
      exit 1
    }
    
    # If an icon path was specified, create the icon image
    if {$specl::icon_path ne ""} {
      if {[file exists [set icon_path [file join $data(specl_version_dir) $specl::icon_path]]]} {
        set data(icon) [image create photo -file $icon_path]
      }
    }
    
    # Get the URL
    if {[catch "fetch_url" rc]} {
      tk_messageBox -parent . -default ok -type ok -message "Unable to update" -detail $rc
      exit 1
    }
    
    # If there was an issue with the download, display the message to the user.
    if {$data(fetch_content) eq ""} {
      tk_messageBox -parent . -default ok -type ok -message "Unable to update" -detail "Error code: $data(fetch_ncode)\n$data(fetch_error)"
      exit 1
    }
    
    # Parse the data
    if {[catch "parse_data" rc]} {
      tk_messageBox -parent . -default ok -type ok -message "Unable to parse update" -detail $rc
      exit 1
    }
    
    # Get the content
    array set content $rc
    
    # If the content does not require an update, tell the user
    if {$content(version) eq $specl::version} {
      tk_messageBox -parent . -default ok -type ok -message "Application is already up-to-date!"
      exit 1
    } else {
      display_update $rc
    }
    
    # Stop the application
    exit
    
  }
  
}

###################################################  RELEASER  ###################################################

namespace eval specl::releaser {
  
  array set widgets {}
  array set data {
    channel_title       ""
    channel_description ""
    channel_link        ""
    channel_language    "en"
    item_version        ""
    item_release        0
    item_description    ""
    item_release_notes  ""
    item_url            ""
    item_length         0
    item_checksum       ""
    cl_noui             0
    cl_version          ""
    cl_desc_file        ""
    cl_tarball          ""
    cl_directory        ""
    cl_verbose          1
  }
  
  ######################################################################
  # Parses the command-line arguments to the release command.
  proc parse_args {cl_args} {

    variable data

    if {[llength $cl_args] > 0} {

      # Parse the release arguments
      while {[llength $cl_args] > 0} {
        set args [lassign $cl_args arg]
        switch -exact -- $arg {
          -noui   { set data(cl_noui) 1 }
          -q      { set data(cl_verbose) 0 }
          -n      { set cl_args [lassign $cl_args data(cl_version)] }
          -f      { set cl_args [lassign $cl_args data(cl_desc_file)] }
          -t      { set cl_args [lassign $cl_args data(cl_tarball)] }
          -d      { set cl_args [lassign $cl_args data(cl_directory)] }
          default { return 0 }
        }
      }

      # Check to make sure that all of the necessary arguments were set
      if {$cl_noui && (($data(cl_version) eq "") || ($data(cl_desc_file) eq ""))} {
        return 0
      } elseif {($data(cl_tarball) ne "") && ![file exists $data(cl_tarball)]} {
        return 0
      } elseif {($data(cl_directory) ne "") && ![file exists $data(cl_directory)]} {
        return 0
      }

      # Handle the description file
      if {[string range $data(cl_desc_file) 0 6] eq "http://"} {
        set data(item_release_notes) $data(cl_desc_file)
      } elseif {![catch { open $data(cl_desc_file) r } rc]} {
        set data(item_description) [read $rc]
        close $rc
      } else {
        return 0
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
    
    set widgets(nb) [ttk::notebook .relwin.nb]

    $widgets(nb) add [ttk::frame .relwin.nb.rf] -text "General"
    
    set widgets(appname_label)       [ttk::label .relwin.nb.rf.l0 -text "Application Name:"]
    set widgets(appname)             [ttk::entry .relwin.nb.rf.e0 -validate key -validatecommand {specl::releaser::update_url 0 %P}]
    set widgets(general_title_label) [ttk::label .relwin.nb.rf.l1 -text "Title:"]
    set widgets(general_title)       [ttk::entry .relwin.nb.rf.e1]
    set widgets(general_desc_label)  [ttk::label .relwin.nb.rf.l2 -text "Description:"]
    set widgets(general_desc)        [text       .relwin.nb.rf.e2 -height 5 -width 60]
    set widgets(general_link_label)  [ttk::label .relwin.nb.rf.l3 -text "Link:"]
    set widgets(general_link)        [ttk::entry .relwin.nb.rf.e3]
    set widgets(language_label)      [ttk::label .relwin.nb.rf.l4 -text "Language:"]
    set widgets(language)            [ttk::entry .relwin.nb.rf.e4]
    set widgets(rss_url_label)       [ttk::label .relwin.nb.rf.l5 -text "RSS URL:"]
    set widgets(rss_url)             [ttk::entry .relwin.nb.rf.e5]
    set widgets(rss_url_suffix)      [ttk::label .relwin.nb.rf.l51 -text "/appcast.xml"]
    set widgets(download_url_label)  [ttk::label .relwin.nb.rf.l6  -text "Default Download URL:"]
    set widgets(download_url)        [ttk::entry .relwin.nb.rf.e6]
    set widgets(icon_path_label)     [ttk::label .relwin.nb.rf.l7  -text "Icon Path:"]
    set widgets(icon_path)           [ttk::entry .relwin.nb.rf.e7]
      
    grid columnconfigure .relwin.nb.rf 1 -weight 1
    grid $widgets(appname_label)       -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(appname)             -row 0 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(general_title_label) -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(general_title)       -row 1 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(general_desc_label)  -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(general_desc)        -row 2 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(general_link_label)  -row 3 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(general_link)        -row 3 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(language_label)      -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(language)            -row 4 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(rss_url_label)       -row 5 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(rss_url)             -row 5 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(rss_url_suffix)      -row 5 -column 2 -sticky news -padx 2 -pady 2
    grid $widgets(download_url_label)  -row 6 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(download_url)        -row 6 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(icon_path_label)     -row 7 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(icon_path)           -row 7 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    
    $widgets(nb) add [ttk::frame .relwin.nb.tf] -text "Release"
    
    set widgets(item_version_label) [ttk::label .relwin.nb.tf.l1  -text "Version:"]
    set widgets(item_version)       [ttk::entry .relwin.nb.tf.e1 -validate key -validatecommand {specl::releaser::update_url 1 %P}]
    set widgets(item_desc_label)    [ttk::label .relwin.nb.tf.l2  -text "Description:"]
    set widgets(item_desc)          [text       .relwin.nb.tf.e2  -height 5 -width 60]
    set widgets(item_notes_label)   [ttk::label .relwin.nb.tf.l3  -text "Release Notes URL:"]
    set widgets(item_notes)         [ttk::entry .relwin.nb.tf.e3]
    set widgets(item_url_label)     [ttk::label .relwin.nb.tf.l4  -text "Download URL:"]
    set widgets(item_url)           [ttk::entry .relwin.nb.tf.e4]
    set widgets(item_url_suffix)    [ttk::label .relwin.nb.tf.l41 -text ""]

    grid rowconfigure    .relwin.nb.tf 2 -weight 1
    grid columnconfigure .relwin.nb.tf 1 -weight 1
    grid $widgets(item_version_label) -row 0 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(item_version)       -row 0 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_desc_label)    -row 2 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(item_desc)          -row 2 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_notes_label)   -row 3 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(item_notes)         -row 3 -column 1 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_url_label)     -row 4 -column 0 -sticky news -padx 2 -pady 2
    grid $widgets(item_url)           -row 4 -column 1 -sticky news -padx 2 -pady 2
    grid $widgets(item_url_suffix)    -row 4 -column 2 -sticky news -padx 2 -pady 2
    
    ttk::frame  .relwin.bf
    ttk::button .relwin.bf.ok -text "OK" -width 6 -command {
      specl::releaser::handle_okay
    }
    ttk::button .relwin.bf.cancel -text "Cancel" -width 6 -command {
      destroy .relwin
      exit
    }
    
    pack .relwin.bf.cancel -side right -padx 2 -pady 2
    pack .relwin.bf.ok     -side right -padx 2 -pady 2
    
    pack .relwin.nb -fill both -expand yes
    pack .relwin.bf -fill x
    
    # Fill in known values in the above fields
    $widgets(appname)       insert end $specl::appname
    $widgets(general_title) insert end $data(channel_title)
    $widgets(general_desc)  insert end $data(channel_description)
    $widgets(general_link)  insert end $data(channel_link)
    $widgets(language)      insert end $data(channel_language)
    $widgets(rss_url)       insert end $specl::rss_url
    $widgets(download_url)  insert end $specl::download_url
    $widgets(icon_path)     insert end $specl::icon_path
    
    $widgets(item_version)  insert end $data(item_version)
    $widgets(item_url)      insert end $data(item_url)

    if {($specl::appname ne "") && ($data(item_version) ne "")} {
      $widgets(item_url_suffix) configure -text "/[string tolower $specl::appname]-$data(item_version).tgz"
    }

    # If the general tab has been setup, change the view to the Release tab
    if {$specl::appname eq ""} {
      focus $widgets(appname)
    } else {
      $widgets(nb) select 1
      focus $widgets(item_version)
    }
    
    # Wait for the window to close
    tkwait window .relwin
    
    return 
    
  }

  ######################################################################
  # Handles a user click on the Okay button.
  proc handle_okay {} {

    variable widgets

    # Get user-provided parameters
    set specl::appname                             [$widgets(appname) get]
    set specl::releaser::data(channel_title)       [$widgets(general_title) get]
    set specl::releaser::data(channel_description) [$widgets(general_desc) get 1.0 end-1c]
    set specl::releaser::data(channel_link)        [$widgets(general_link) get]
    set specl::releaser::data(channel_language)    [$widgets(language) get]
    set specl::rss_url                             [$widgets(rss_url) get]
    set specl::download_url                        [$widgets(download_url) get]
    set specl::icon_path                           [$widgets(icon_path) get]

    set specl::releaser::data(item_version)        [$widgets(item_version) get]
    set specl::releaser::data(item_description)    [$widgets(item_desc) get 1.0 end-1c]
    set specl::releaser::data(item_release_notes)  [$widgets(item_notes) get]
    set specl::releaser::data(item_url)            [$widgets(item_url) get]

    # Colorize the missing labels
    $widgets(appname_label)       configure -background [expr {($specl::appname                             eq "") ? "red" : ""}]
    $widgets(general_title_label) configure -background [expr {($specl::releaser::data(channel_title)       eq "") ? "red" : ""}]
    $widgets(general_desc_label)  configure -background [expr {($specl::releaser::data(channel_description) eq "") ? "red" : ""}]
    $widgets(language_label)      configure -background [expr {($specl::releaser::data(channel_language)    eq "") ? "red" : ""}]
    $widgets(rss_url_label)       configure -background [expr {($specl::rss_url                             eq "") ? "red" : ""}]

    # Set the tab background color to red if any fields are missing
    if {($specl::appname                             eq "") || \
        ($specl::releaser::data(channel_title)       eq "") || \
        ($specl::releaser::data(channel_description) eq "") || \
        ($specl::releaser::data(channel_language)    eq "") || \
        ($specl::rss_url                             eq "")} {
      $widgets(nb) tab 0 -text "!! General !!"
    } else {
      $widgets(nb) tab 0 -text "General"
    }
    
    $widgets(item_version_label)  configure -background [expr {($specl::releaser::data(item_version)        eq "") ? "red" : ""}]
    $widgets(item_desc_label)     configure -background [expr {($specl::releaser::data(item_description)    eq "") ? "red" : ""}]
    $widgets(item_url_label)      configure -background [expr {($specl::releaser::data(item_url)            eq "") ? "red" : ""}]

    # Set the tab background color to red if any fields are missing
    if {($specl::releaser::data(item_version)        eq "") || \
        ($specl::releaser::data(item_description)    eq "") || \
        ($specl::releaser::data(item_url)            eq "")} {
      $widgets(nb) tab 1 -text "!! Release !!"
    } else {
      $widgets(nb) tab 1 -text "Release"
    }

    # Check to make sure that the parameters are valid
    if {([$widgets(nb) tab 0 -text] eq "!! General !!") ||
        ([$widgets(nb) tab 1 -text] eq "!! Release !!")} {
      tk_messageBox -parent .relwin -default ok -type ok -message "Missing required fields"
    } else {
      append specl::releaser::data(item_url) [$widgets(item_url_suffix) cget -text]
      destroy .relwin
    }

    # Allow the UI to update
    update idletasks

  }
  
  ######################################################################
  # Update the URL tarball name.
  proc update_url {type value} {
    
    variable widgets
    variable data
    
    set appname [$widgets(appname) get]
    set version [$widgets(item_version) get]
    
    switch $type {
      0 { set appname $value }
      1 { set version $value }
    }
    
    if {($appname ne "") && ($version ne "")} {
      $widgets(item_url_suffix) configure -text "/[string tolower $appname]-$version.tgz"
    }
    
    return 1
    
  }
  
  ######################################################################
  # Parses the RSS content and save the information in the data array.
  proc parse_rss {content} {
    
    variable data
    
    # Get channel node
    set channel_node [specl::helpers::get_element [list "" $content] "channel"]
    
    # Get the RSS title
    set data(channel_title) [lindex [specl::helpers::get_element $channel_node "title"] 1]
    
    # Get the RSS link
    set data(channel_link) [lindex [specl::helpers::get_element $channel_node "link"] 1]
    
    # Get the RSS description
    set data(channel_description) [lindex [specl::helpers::get_element $channel_node "description"] 1]
    
    # Get the RSS language
    set data(channel_language) [lindex [specl::helpers::get_element $channel_node "language"] 1]
    
    # Get the releases node
    set data(other_releases) [lindex [specl::helpers::get_element $channel_node "releases"] 1]

  }
  
  ######################################################################
  # Read RSS data.
  proc read_rss {} {
    
    # Get the RSS file to read
    set token [http::geturl "$specl::rss_url/appcast.xml"]
    
    # If the request is valid, parse the content
    if {([set status [http::status $token]] eq "ok") && ([set ncode [http::ncode $token]] == 200)} {
      parse_rss [http::data $token] 
    } else {
      puts "Warning:  Unable to fetch RSS information, status: $status, ncode: $ncode"
    }
    
    # Cleanup the request
    http::cleanup $token
    
  }
  
  ######################################################################
  # Write the version file.
  proc write_version {} {
    
    variable data
    
    if {![catch "open specl_version.tcl w" rc]} {
      
      puts $rc "set specl::appname      \"$specl::appname\""
      puts $rc "set specl::version      \"$data(item_version)\""
      puts $rc "set specl::release      \"$data(item_release)\""
      puts $rc "set specl::rss_url      \"$specl::rss_url\""
      puts $rc "set specl::download_url \"$specl::download_url\""
      puts $rc "set specl::icon_path    \"$specl::icon_path\""
      
      close $rc
      
    }
    
  }
  
  ######################################################################
  # Writes the contents of the RSS feed to the appcast.xml file.
  proc write_rss {tmpdir} {
    
    variable data
    
    if {![catch "open [file join $tmpdir appcast.xml] w" rc]} {
      
      puts $rc "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
      puts $rc "<rss version=\"2.0\">"
      puts $rc "  <channel>"
      puts $rc "    <title>$data(channel_title)</title>"
      puts $rc "    <link>$data(channel_link)</link>"
      puts $rc "    <description>$data(channel_description)</description>"
      puts $rc "    <language>$data(channel_language)</language>"
      puts $rc "    <releases>"
      puts $rc "      <release index=\"$data(item_release)\" version=\"$data(item_version)\">"
      puts $rc "        <description><!\[CDATA\[$data(item_description)\]\]></description>"
      puts $rc "        <pubDate>[clock format [clock seconds]]</pubDate>"
      puts $rc "        <specl:releaseNotesLink>$data(item_release_notes)</specl:releaseNotesLink>"
      puts $rc "        <download url=\"$data(item_url)\" length=\"$data(item_length)\" type=\"application/octet-stream\" checksum=\"$data(item_checksum)\" />"
      puts $rc "      </release>"
      puts $rc "      $data(other_releases)"
      puts $rc "    </releases>"
      puts $rc "  </channel>"
      puts $rc "</rss>"
      
      close $rc
      
    }
    
  }
  
  ######################################################################
  # Returns the MD5 checksum for the given tarball.
  proc get_checksum {tarball} {
    
    # Get the md5 checksum of the tarball file
    if {[catch { exec -ignorestderr md5sum $tarball } rc]} {
      return ""
    }
    
    return [lindex $rc 0]
    
  }
  
  ######################################################################
  # Create the files that need to be sent.
  proc create_files {} {
    
    variable data
    
    # Create application name with version information
    set app "$specl::appname-$data(item_version)"
    
    # Create a temporary directory for the application files
    if {$data(cl_directory) ne ""} {
      set tmp $data(cl_directory)
    } else {
      set tmp [file join / tmp]
    }
    set tmpdir [file join $tmp $app]
    
    # Write the version file to the current directory
    if {$data(cl_verbose)} { puts -nonewline "Writing specl_version.tcl ............."; flush stdout }
    write_version
    if {$data(cl_verbose)} { puts "  Done!" }
    
    # If the tarball was not specified on the command-line, generate it
    if {$data(cl_tarball) eq ""} {

      # Copy the current directory to the /tmp directory
      if {$data(cl_verbose)} { puts -nonewline "Copying current directory to /tmp ....."; flush stdout }
      file copy -force [pwd] $tmpdir
      if {$data(cl_verbose)} { puts "  Done!" }
    
      # Tarball and gzip the current directory
      if {$data(cl_verbose)} { puts -nonewline "Tarballing directory .................."; flush stdout }
      if {[catch { exec -ignorestderr tar czf [set tarball [file join $tmp [file tail $data(item_url)]]] -C $tmp $app } rc]} {
        if {$data(cl_verbose)} { puts "  Failed!" }
        return -code error $rc
      }
      if {$data(cl_verbose)} { puts "  Done!" }

    # Otherwise, just use the given tarball
    } else {

      set tarball $data(cl_tarball)

    }
    
    # Figure out the size of the tarball and save it to the item_length item
    set data(item_length) [file size $tarball]
    
    # Figure out the md5 checksum
    if {$data(cl_verbose)} { puts -nonewline "Calculate checksum ...................."; flush stdout }
    set data(item_checksum) [get_checksum $tarball]
    if {$data(cl_verbose)} { puts "  Done!" }
      
    # Write the RSS file
    if {$data(cl_verbose)} { puts -nonewline "Writing RSS appcast file .............."; flush stdout }
    write_rss $tmp
    if {$data(cl_verbose)} { puts "  Done!\n" }
    
    puts "Upload [file join $tmp appcast.xml] to $specl::rss_url/appcast.xml"
    puts "Upload [file join $tmp [file tail $data(item_url)]] to $data(item_url)"
    puts ""

  }
  
  ######################################################################
  # Performs a release of the current project.
  proc start_release {} {
    
    variable data
    
    # Attempt to source the specl_version.tcl file
    if {[catch { specl::load_specl_version [pwd] } rc]} {
      
      # If the specl_version file doesn't exist, initialize the variables
      set data(item_version) "1.0"
      set data(item_release) 1
      set data(item_url)     ""
      
    } else {
      
      # Create the new version
      set version $specl::version
      
      set data(item_version) [join $version .]
      set data(item_release) [expr $specl::release + 1]
      set data(item_url)     $specl::download_url
      
      # Read the RSS file since it exists
      read_rss
      
    }
    
    # Get the release information from the user
    if {!$data(cl_noui)} {
      get_release_info
    }
    
    # Create the necessary files
    create_files
    
    # End the application
    exit
    
  }
  
}

# If this is being run as an application, do the following
if {[file tail $::argv0] eq "specl.tcl"} {
  
  package require http
  package require Tkhtml 3.0

  # Make the theme be clam
  ttk::style theme use clam
  
  # Withdraw the top-level window so that it isn't visible
  wm withdraw .
  
  ######################################################################
  # Help information when this is run as a stand-alone application.
  proc usage {} {
    
    puts "Usage:  specl (-h | -v | <command> <options>)"
    puts ""
    puts "General Options:"
    puts "  -h       Outputs this help information."
    puts "  -v       Displays version information."
    puts ""
    puts "Commands:"
    puts "  release  Generates a release of the given project for general availability"
    puts "  update   Called by clients to update the project to the latest release"
    puts ""
    
    exit
    
  }
  
  # If no options were supplied, display the usage information
  if {[llength $argv] == 0} {
    puts "ERROR:  No arguments supplied to specl command"
    usage
  }
  
  # Parse command-line arguments
  set args $argv
  switch -exact -- [lindex $args 0] {
    -h      { usage }
    -v      { puts $specl::version; exit }
    release {
      set args [lassign $args arg]
      if {![specl::releaser::parse_args $args]} {
        puts "ERROR:  Incorrect arguments passed to specl release command"
        usage
      }
      specl::releaser::start_release
    }
    update  {
      set args [lassign $args arg]
      if {[llength $args] != 1} {
        puts "ERROR:  Incorrect arguments passed to specl update command"
        usage
      }
      lassign $args specl::updater::data(specl_version_dir)
      specl::updater::start_update
    }
    default {
      puts "ERROR:  Unknown command/option ([lindex $args 0])"
      usage
    }
  }
  
}
