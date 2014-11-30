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
  variable oses         {linux mac win}
  
  ######################################################################
  # Returns the full, normalized pathname of the specl_version.tcl file.
  proc get_specl_version_dir {start_dir} {

    set current_dir [file normalize $start_dir]
    while {($current_dir ne "/") && ![file exists [file join $current_dir specl_version.tcl]]} {
      set current_dir [file dirname $current_dir]
    }
    
    # If we could not find the specl_version.tcl file, return an error
    if {$current_dir eq "/"} {

      # If we are running Mac OSX, the specl_version.tcl file could be in one of the child
      # directories under start_dir, check to see if this is the case
      if {$::tcl_platform(os) eq "Darwin"} {
        if {![catch { exec -ignorestderr find $start_dir -name specl_version.tcl } rc] && ([set current_dir [string trim $rc]] ne "")} {
          return [file dirname $current_dir]
        }
      }
    
      # Otherwise, specify that we could not find the specl_version.tcl file
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
      if {[set path [file join {*}[lrange $path 0 [lsearch -glob $path *.app]]]] ne ""} {
        set install_dir $path
      }
    }
    
    return $install_dir
    
  }
  
  ######################################################################
  # Checks for updates.  Throws an exception if there was a problem
  # checking for the update.
  proc check_for_update {on_start {cl_args {}} {cleanup_script {}}} {
    
    # Allow the UI to update before we proceed
    update
    
    # Loads the specl_version.tcl file
    set specl_version_dir [get_specl_version_dir [file dirname $::argv0]]
    
    # Get the current file
    array set frame [info frame 0]
    
    # Get the normalized name of argv0
    set script_name [file normalize $::argv0]
    
    # Create update arguments
    if {$on_start} {
      set update_args "-q"
    }
    lappend update_args -t [ttk::style theme use]
    lappend update_args $specl_version_dir
    
    # Execute this script
    if {[catch { exec -ignorestderr [info nameofexecutable] $frame(file) -- update {*}$update_args } rc options]} {
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
        lappend elements [list [string trim $attrs] ""]
      } else {
        break
      }
    }

    return $elements
    
  }

  ######################################################################
  # Returns a single element node.
  proc get_element {node name} {

    if {[llength [set elements [get_elements $node $name]]] == 0} {
      return -code error "Unable to find element node $name"
    }

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

  ######################################################################
  # Opens the given filename in an external application, using one of the
  # open terminal commands to determine the proper application to use.
  proc open_file_externally {fname {in_background 0}} {
    
    set opts ""
    
    switch -glob $::tcl_platform(os) {
      Darwin {
        if {$in_background} {
          set opts "-g"
        }
        catch { exec open {*}$opts $fname }
      }
      Linux* {
        catch { exec xdg-open $fname }
      }
      *Win* {
        catch { exec os.startfile $fname }
      }
    }
    
  }

  ######################################################################
  # Initializes the given text widget to render HTML via htmllib.
  proc HMinitialize {win} {

    # Initialize the text widget to display HTML
    HMinit_win $win

    # Set <ul> symbols
    HMset_state $win -symbols [string repeat \u2022\u2023\u25e6\u2043 5]

  }
    
  ######################################################################
  # Handles the creation of an image.
  proc HMhandle_image {win handle src} {

    variable animation_ids

    # Initialize tfile to indicate that it was not used
    set tfile ""

    # If the file is from the web, download it
    if {[string first "http" $src] == 0} {
      set tfile [file join / tmp tmp.[pid]]
      set outfl [open $tfile w]
      http::geturl $src -channel $outfl
      close $outfl
      set src $tfile
    }

    # Load the GIF information
    set depth 0
    if {![catch { gifblock::gif.load blocks $tfile } rc]} {
      set depth [llength [set gc_blocks [lsearch -all [gifblock::gif.blocknames blocks] {Graphic Control}]]]
    }

    # Create the image from the file
    if {$depth == 0} {
      if {[catch { image create photo -file $src } img_list]} {
        puts $::errorInfo
        return
      }
    } else {
      for {set i 0} {$i < $depth} {incr i} {
        if {![catch { image create photo -file $tfile -format "gif -index $i" } img]} {
          lappend img_list [list $img [expr [gifblock::gif.get blocks [lindex $gc_blocks $i] {delay time}] * 10]]
        }
      }
    }

    # Delete the temporary file if set
    if {$tfile ne ""} {
      file delete $tfile
    }

    # If this is an animated GIF, display the next image in the series after the given period of time
    if {[llength $img_list] > 1} {
      set animation_ids($handle) [after [lindex $img_list 0 1] [list specl::helpers::HMcycle_image $handle 1 $img_list]]
    }

    # Display the image
    HMgot_image $handle [lindex $img_list 0 0]

  }

  ######################################################################
  # Handles an animated GIF.
  proc HMcycle_image {handle pos img_list} {

    variable animation_ids

    if {[winfo exists $handle]} {

      lassign [lindex $img_list $pos] img delay

      # Display the image
      HMgot_image $handle $img

      # Increment the position
      incr pos
      if {$pos >= [llength $img_list]} { set pos 0 }

      # Cycle again
      set animation_ids($handle) [after $delay [list specl::helpers::HMcycle_image $handle $pos $img_list]]

    }

  }

  ######################################################################
  # Cancels all animations for the current window.
  proc HMcancel_animations {} {

    variable animation_ids

    # Cancel all of the outstanding IDs
    foreach {handle id} [array get animation_ids] {
      after cancel $id
    }

    # Clear all of the IDs
    array unset animation_ids

  }

}
  
###################################################  UPDATER  ###################################################

namespace eval specl::updater {
  
  array set widgets {}
  
  array set data {
    specl_version_dir    ""
    cl_quiet             0
    cl_theme             ""
    icon                 ""
    fetch_ncode          ""
    fetch_content        ""
    fetch_error          ""
    stylecount           0
    cancel               0
    ui,icon_path         ""
    ui,icon_side         left
    ui,utd_win_width     400
    ui,utd_win_height    100
    ui,utd_title         "You are up-to-date!"
    ui,utd_message       "Your version of {APPNAME} ({CURVERSION}) is the latest available."
    ui,upd_win_width     500
    ui,upd_win_height    400
    ui,upd_win_title     "Software Updater"
    ui,upd_win_resizable 1
    ui,upd_title         "A new version is available!"
    ui,upd_message       "Version ({NEWVERSION}) is ready for installation. You are currently\nusing version ({CURVERSION}). Click Download to update your version."
    ui,upd_desc_height   200
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
        -t      {
          set cl_args [lassign $cl_args data(cl_theme)]
          catch { ttk::style theme use $data(cl_theme) }
        }
        default {
          if {$data(specl_version_dir) eq ""} {
            set data(specl_version_dir) $arg
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
    
    set first        1
    set description  ""
    set download_url ""
    set length       0
    set checksum     ""
    set num_updates  0
    
    # Get the contents of the 'releases' node
    set releases_node [specl::helpers::get_element [list "" $data(fetch_content)] "releases"]
    
    # Get the contents of the next 'release' node
    foreach release_node [specl::helpers::get_elements $releases_node "release"] {
    
      set release [specl::helpers::get_attr $release_node "index"]
      set version [specl::helpers::get_attr $release_node "version"]

      if {$release > $specl::release} {

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
          
          # Get the current OS
          switch -glob $::tcl_platform(os) {
            Linux*  { set my_os "linux" }
            Darwin  { set my_os "mac" }
            *Win*   { set my_os "win" }
            default {
              return -code error "Unable to find installation bundle"
            }
          }
          
          # Set the description
          set description    "$title<br>$curr_description"
          set latest_version $version
          set latest_release $release
          
          # Get the downloads node
          set downloads_node [specl::helpers::get_element $release_node "downloads"]
          
          # Get the download information
          foreach download_node [specl::helpers::get_elements $downloads_node "download"] {
          
            # Get the OS
            if {[specl::helpers::get_attr $download_node "os"] ne $my_os} {
              continue
            }
            
            # Get the download URL
            set download_url [specl::helpers::get_attr $download_node "url"]
           
            # Get the file length
            set length [specl::helpers::get_attr $download_node "length"]
           
            # Get the md5 checksum
            set checksum [specl::helpers::get_attr $download_node "checksum"]
              
          }
          
          set first 0
          
        } else {
          
          # Append to the current description
          append description "<br><hr>$title<br>$curr_description"
          
        }
        
        incr num_updates
        
      # If we are up-to-date, just return the version/release information
      } elseif {$first} {
        
        set latest_version $version
        set latest_release $release
        
      }
      
    }
    
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
    if {[specl::releaser::get_checksum $bundle] ne $content(checksum)} {
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
      update idletasks
      
      if {[catch { check_bundle $download $content_list } rc]} {
        
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
  # Returns the password entered from the user.
  proc get_password {} {
    
    variable temp_password
    
    set temp_password ""
    
    toplevel     .passwin
    wm title     .passwin "Enter root password"
    wm resizable .passwin 0 0
    wm transient .passwin .updwin

    ttk::frame .passwin.f
    ttk::label .passwin.f.l1 -text "$specl::appname requires administrative privileges\nto install the latest update"
    ttk::label .passwin.f.l2 -text "Root password: "
    ttk::entry .passwin.f.e  -show \u2022 -validate key -validatecommand "specl::updater::validate_password %P"
    
    bind .passwin.f.e <Return> ".passwin.bf.ok invoke"
    
    grid rowconfigure    .passwin.f 2 -weight 1
    grid columnconfigure .passwin.f 1 -weight 1
    grid .passwin.f.l1 -row 0 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid .passwin.f.l2 -row 1 -column 0 -sticky ew   -padx 2 -pady 2
    grid .passwin.f.e  -row 1 -column 1 -sticky ew   -padx 2 -pady 2
    
    ttk::frame  .passwin.bf
    ttk::button .passwin.bf.ok     -text "OK"     -width 6 -command {
      set specl::updater::temp_password [.passwin.f.e get]
      destroy .passwin
    } -state disabled -default active
    ttk::button .passwin.bf.cancel -text "Cancel" -width 6 -command {
      destroy .passwin
    }
    
    pack .passwin.bf.cancel -side right -padx 2 -pady 2
    pack .passwin.bf.ok     -side right -padx 2 -pady 2
    
    pack .passwin.f  -fill x -expand yes
    pack .passwin.bf -fill x
    
    # Center the password window over the update window
    ::tk::PlaceWindow .passwin widget .updwin

    # Grab and focus on the window
    ::tk::SetFocusGrab .passwin .passwin.e
    
    # Wait for the window to be closed
    tkwait window .passwin
    
    # Release the grab and focus
    ::tk::RestoreFocusGrab .passwin .passwin.e
    
    # Get the returned password and then clear the namespace variable for protection
    set password $temp_password
    set temp_password ""
    
    return $password
    
  }
  
  ######################################################################
  # Validate the given password value.
  proc validate_password {value} {
    
    if {$value eq ""} {
      .passwin.bf.ok configure -state disabled
    } else {
      .passwin.bf.ok configure -state normal
    }
    
    return 1
    
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
    
    # Move the original directory to the trash
    switch -glob $::tcl_platform(os) {
      Darwin {
        set trash_path [specl::helpers::get_unique_path [file join ~ .Trash] [file tail $install_dir]]
        set download   [file join / tmp [file tail $install_dir]]
      }
      Linux* {
        if {[catch { exec -ignorestderr gvfs-trash $install_dir }]} {
          set password [get_password]
          if {[catch { exec -ignorestderr sudo -S gvfs-trash $install_dir << "$password\n"}]} {
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
    if {[info exists trash_path]} {
      if {[catch { file rename -force $install_dir $trash_path } rc]} {
        if {![info exists password]} {
          set password [get_password]
        }
        if {[catch { exec -ignorestderr sudo -S mv $install_dir $trash_path << "$password\n" } rc]} {
          tk_messageBox -parent . -default ok -type ok -message "A Unable to install" -detail $rc
          exit 1
        }
      }
    }
    
    # Perform the directory move
    if {[catch { file rename -force $download $install_dir } rc]} {
      if {![info exists password]} {
        set password [get_password]
      }
      if {[catch { exec -ignorestderr sudo -S mv $download $install_dir << "$password\n" } rc]} {
        tk_messageBox -parent . -default ok -type ok -message "B Unable to install" -detail $rc
        exit 1
      }
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
    .updwin.pf.info configure -text "[get_size_string $current] of [get_size_string $total]"
    
  }
  
  ######################################################################
  # Displays the update information and allows the user to either
  # do the update or stop the update.
  proc display_update {content_list} {
    
    variable widgets
    variable data
    
    array set content $content_list
    
    # Initialize information
    set title       [transform_text $data(ui,upd_title)   $content(version) $content(num_updates)]
    set msg         [transform_text $data(ui,upd_message) $content(version) $content(num_updates)]
    set icon_column [expr {($data(ui,icon_side) eq "right") ? 2 : 0}]
    
    toplevel     .updwin
    wm title     .updwin [transform_text $data(ui,win_title) $content(version) $content(num_updates)]
    wm geometry  .updwin $data(ui,upd_win_width)x$data(ui,upd_win_height)
    if {!$data(ui,win_resizable)} {
      wm resizable .updwin 0 0
    }
    
    ttk::frame .updwin.if
    ttk::label .updwin.if.icon
    ttk::label .updwin.if.title -text $title -font TkHeadingFont
    ttk::label .updwin.if.info  -text $msg
    
    # If there is an icon, create it and assign it to the icon label
    if {$data(ui,icon_path) ne ""} {
      .updwin.if.icon configure -image [set icon [image create photo -file $data(ui,icon_path)]]
    }
    
    grid rowconfigure    .updwin.if 1 -weight 1
    grid columnconfigure .updwin.if 1 -weight 1
    grid .updwin.if.icon  -row 0 -column $icon_column -padx 2 -pady 2 -rowspan 2
    grid .updwin.if.title -row 0 -column 1            -padx 2 -pady 2
    grid .updwin.if.info  -row 1 -column 1            -padx 2 -pady 2
    
    ttk::frame       .updwin.pf
    ttk::progressbar .updwin.pf.pb -mode determinate -length [expr $data(ui,upd_win_width) - 120]
    ttk::label       .updwin.pf.status
    ttk::label       .updwin.pf.info
    
    grid .updwin.pf.pb     -row 0 -column 0 -sticky ew -padx 2 -pady 2
    grid .updwin.pf.status -row 0 -column 1 -sticky ew -padx 2 -pady 2
    grid .updwin.pf.info   -row 1 -column 0 -sticky ew -padx 2 -pady 2
    
    ttk::frame     .updwin.hf
    set widgets(html) [text .updwin.hf.h -width $data(ui,upd_win_width) -height $data(ui,upd_desc_height) \
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
    
    # Add the HTML to the HTML widget
    specl::helpers::HMinitialize $widgets(html)
    HMparse_html $content(description) "HMrender $widgets(html)"

    # Configure the text widget to be disabled
    $widgets(html) configure -state disabled

    # Center the window on the screen
    set wx [expr ([winfo screenwidth  .updwin] / 2) - ($data(ui,upd_win_width)  / 2)]
    set wy [expr ([winfo screenheight .updwin] / 2) - ($data(ui,upd_win_height) / 2)]
    wm geometry .updwin +$wx+$wy

    # Raise the window to the top
    wm attributes .updwin -topmost 1
     
    # Wait for the window to be closed
    tkwait window .updwin
    
    # Delete the icon
    if {[info exists icon]} {
      image delete $icon
    }
    
  }
  
  ######################################################################
  # Displays the up-to-date window.
  proc display_up_to_date {content_list} {
    
    variable data
    
    array set content $content_list
    
    toplevel     .utdwin
    wm title     .utdwin ""
    wm geometry  .utdwin $data(ui,utd_win_width)x$data(ui,utd_win_height)
    wm resizable .utdwin 0 0

    # Create text
    set title       [transform_text $data(ui,utd_title)   $content(version) $content(num_updates)]
    set msg         [transform_text $data(ui,utd_message) $content(version) $content(num_updates)]
    set icon_column [expr {($data(ui,icon_side) eq "right") ? 2 : 0}]
    
    ttk::frame .utdwin.f
    ttk::label .utdwin.f.icon
    ttk::label .utdwin.f.title -text $title -font TkHeadingFont
    ttk::label .utdwin.f.msg   -text $msg
    
    # If there is an icon, create it and assign it to the icon label
    if {$data(ui,icon_path) ne ""} {
      .utdwin.f.icon configure -image [set icon [image create photo -file $data(ui,icon_path)]]
    }
    
    grid rowconfigure    .utdwin.f 1 -weight 1
    grid columnconfigure .utdwin.f 1 -weight 1
    grid .utdwin.f.icon  -row 0 -column $icon_column -padx 2 -pady 2 -rowspan 2
    grid .utdwin.f.title -row 0 -column 1            -padx 2 -pady 2
    grid .utdwin.f.msg   -row 1 -column 1            -padx 2 -pady 2
    
    ttk::frame  .utdwin.bf
    ttk::button .utdwin.bf.ok -text "OK" -width 6 -default active -command {
      destroy .utdwin
    }
    
    pack .utdwin.bf.ok -padx 2 -pady 2
    
    pack .utdwin.f  -fill x
    pack .utdwin.bf -fill x
    
    # Center the window on the screen
    set wx [expr ([winfo screenwidth  .updwin] / 2) - ($data(ui,utd_win_width)  / 2)]
    set wy [expr ([winfo screenheight .updwin] / 2) - ($data(ui,utd_win_height) / 2)]
    wm geometry .utdwin +$wx+$wy

    # Raise the window to the top
    wm attributes .updwin -topmost 1
     
    # Grab the focus
    ::tk::SetFocusGrab .utdwin .utdwin.b
    
    # Wait for the window to be closed
    tkwait window .utdwin
    
    # Release the grab
    ::tk::RestoreFocusGrab .utdwin .utdwin.b
    
    # Delete the icon
    if {[info exists icon]} {
      image delete $icon
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
      
      # Parse the customization XML
      if {![catch { specl::helpers::get_element [list "" $contents] "customizations" } custom_node]} {
      
        # Get icon information
        if {![catch { specl::helpers::get_element $custom_node "icon" } icon_node]} {
          foreach attr [list path size] {
            if {![catch { specl::helpers::get_attr $icon_node $attr } value]} {
              set data(ui,icon_$attr) $value
            }
          }
        }
         
        # Get update window information
        if {![catch { specl::helpers::get_element $custom_node "update" } update_node]} {
          if {[catch { specl::helpers::get_attr $update_node "description_height" } value]} {
            set data(ui,upd_desc_height) $value
          }
          if {![catch { specl::helpers::get_element $update_node "window" } window_node]} {
            foreach name [list width height resizable] {
              if {![catch { specl::helpers::get_attr $window_node $name } value]} {
                set data(ui,upd_win_$name) $value
              }
            }
            if {![catch { specl::helpers::get_element $window_node "title" } title_node]} {
              set data(ui,upd_win_title) [lindex $title_node 1]
            }
          }
          foreach name [list win_width win_height win_title win_resizable title message] {
            if {![catch { specl::helpers::get_element $update_node $name } node]} {
              set data(ui,upd_$name) [lindex $node 1]
            }
          }
        }
         
        # Get up-to-date window information
        if {![catch { specl::helpers::get_element $custom_node "uptodate" } uptodate_node]} {
          if {![catch { specl::helpers::get_element $uptodate_node "window" } window_node]} {
            foreach name [list width height] {
              if {[catch { specl::helpers::get_attr $window_node $name } value]} {
                set data(ui,upd_win_$name) $value
              }
            }
          }
          foreach name [list title message] { 
            if {![catch { specl::helpers::get_element $uptodate_node $name } node]} {
              set data(ui,utd_$name) [lindex $node 1]
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
    
    # Load the specl_version.tcl file
    if {[catch { specl::load_specl_version $data(specl_version_dir) } rc]} {
      tk_messageBox -parent . -default ok -type ok -message "Unable to update" -detail $rc
      exit 1
    }
    
    # Load the customization file if it exists
    catch { load_customizations }
    
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
    if {$content(release) <= $specl::release} {
      if {!$data(cl_quiet)} {
        display_up_to_date $rc
      }
      exit 1
    } else {
      display_update $rc
    }
    
    # Stop the application
    exit
    
  }
  
  ######################################################################
  # Transforms the given text string by substituting keywords with values.
  proc transform_text {txt new_version num_updates} {
    
    variable data
    
    set txt [regsub -all -- \{APPNAME\}    $txt $specl::appname]
    set txt [regsub -all -- \{CURVERSION\} $txt $specl::version]
    set txt [regsub -all -- \{NEWVERSION\} $txt $new_version]
    set txt [regsub -all -- \{UPDATES\}    $txt $num_updates]
    
    return $txt
    
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
    item_download_url   ""
    cl_noui             0
    cl_version          ""
    cl_desc_file        ""
    cl_verbose          1
    cl_directory        ""
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
          -d      { set cl_args [lassign $cl_args data(cl_directory)] }
          default { return 0 }
        }
      }

      # Check to make sure that all of the necessary arguments were set
      if {$data(cl_noui) && (($data(cl_version) eq "") || ($data(cl_desc_file) eq ""))} {
        return 0
      } elseif {($data(cl_directory) ne "") && (![file exists $data(cl_directory)] || ![file isdirectory $data(cl_directory)])} {
        return 0
      } else {
        foreach os $specl::oses {
          if {($data(cl_file,$os) ne "") && ![file exists $data(cl_file,$os)]} {
            return 0
          }
        }
      }

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
          -d      { set cl_args [lassign $cl_args data(cl_directory)] }
          default { return 0 }
        }
      }

      # Check to make sure that all of the necessary arguments were set
      if {($data(cl_directory) ne "") && (![file exists $data(cl_directory)] || ![file isdirectory $data(cl_directory)])} {
        return 0
      } else {
        foreach os $specl::oses {
          if {($data(cl_file,$os) ne "") && ![file exists $data(cl_file,$os)]} {
            return 0
          }
        }
      }

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
    set widgets(appname)             [ttk::entry .relwin.nb.rf.e0]
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
    
    $widgets(nb) add [ttk::frame .relwin.nb.tf] -text "Release"
    
    set widgets(item_version_label)      [ttk::label .relwin.nb.tf.l0  -text "Version:"]
    set widgets(item_version)            [ttk::entry .relwin.nb.tf.e0]
    set widgets(item_desc_label)         [ttk::label .relwin.nb.tf.l1  -text "Description:"]
    set widgets(item_desc)               [text       .relwin.nb.tf.e1  -height 5 -width 60 -wrap word]
    set widgets(item_notes_label)        [ttk::label .relwin.nb.tf.l2  -text "Release Notes URL:"]
    set widgets(item_notes)              [ttk::entry .relwin.nb.tf.e2]
    set widgets(item_download_url_label) [ttk::label .relwin.nb.tf.l3  -text "Download Directory URL:"]
    set widgets(item_download_url)       [ttk::entry .relwin.nb.tf.e3]
    
    array set full_os {linux Linux mac MacOSX win Windows}
    set row 4
    foreach os $specl::oses {
      set widgets(item_file_cb,$os)    [ttk::checkbutton .relwin.nb.tf.cb${row} -variable specl::releaser::data(item_val,$os)]
      set widgets(item_file_label,$os) [ttk::label       .relwin.nb.tf.l${row}  -text "$full_os($os) Installation Package:"]
      set widgets(item_file,$os)       [ttk::entry       .relwin.nb.tf.e${row}  -validate key -validatecommand [list specl::releaser::handle_file_entry $os %P]]
      set widgets(item_file_btn,$os)   [ttk::button      .relwin.nb.tf.l${row}2 -text "Browse..." -command "specl::releaser::handle_browse $os"]
      incr row
    }

    grid rowconfigure    .relwin.nb.tf 1 -weight 1
    grid columnconfigure .relwin.nb.tf 2 -weight 1
    grid $widgets(item_version_label)      -row 0 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_version)            -row 0 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_desc_label)         -row 1 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_desc)               -row 1 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_notes_label)        -row 2 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_notes)              -row 2 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_download_url_label) -row 3 -column 0 -sticky news -padx 2 -pady 2 -columnspan 2
    grid $widgets(item_download_url)       -row 3 -column 2 -sticky news -padx 2 -pady 2 -columnspan 2
    
    set row 4
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
    
    pack .relwin.nb -fill both -expand yes
    pack .relwin.bf -fill x
    
    # Fill in known values in the above fields
    $widgets(appname)       insert end $specl::appname
    $widgets(general_title) insert end $data(channel_title)
    $widgets(general_desc)  insert end $data(channel_description)
    $widgets(general_link)  insert end $data(channel_link)
    $widgets(language)      insert end $data(channel_language)
    $widgets(rss_url)       insert end $specl::rss_url
    
    $widgets(item_version)      insert end $data(item_version)
    $widgets(item_desc)         insert end $data(item_description)
    $widgets(item_download_url) insert end $data(item_download_url)
    
    foreach os $specl::oses {
      $widgets(item_file,$os) insert end $data(cl_file,$os)
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

    if {![winfo exists .prevwin]} {

      toplevel     .prevwin
      wm title     .prevwin "Release Preview"
      wm geometry  .prevwin 500x400
      wm resizable .prevwin 0 0

      ttk::frame     .prevwin.f
      text           .prevwin.f.t  -yscrollcommand {specl::helpers::set_yscrollbar .prevwin.f.vb}
      ttk::scrollbar .prevwin.f.vb -orient vertical -command {.prevwin.f.t yview}

      grid rowconfigure    .prevwin.f 0 -weight 1
      grid columnconfigure .prevwin.f 0 -weight 1
      grid .prevwin.f.t  -row 0 -column 0 -sticky news
      grid .prevwin.f.vb -row 0 -column 1 -sticky ns

      ttk::frame  .prevwin.bf
      ttk::button .prevwin.bf.refresh -text "Refresh" -width 7 -command {
        specl::helpers::HMcancel_animations
        .prevwin.f.t configure -state normal
        HMreset_win .prevwin.f.t
        HMparse_html [$specl::releaser::widgets(item_desc) get 1.0 end-1c] "HMrender .prevwin.f.t"
        .prevwin.f.t configure -state disabled
      }

      pack .prevwin.bf.refresh -side right -padx 2 -pady 2

      pack .prevwin.f  -fill both -expand yes
      pack .prevwin.bf -fill x

      # Render the HTML
      specl::helpers::HMinitialize .prevwin.f.t
      HMparse_html [$specl::releaser::widgets(item_desc) get 1.0 end-1c] "HMrender .prevwin.f.t"

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
    set specl::appname            [$widgets(appname) get]
    set data(channel_title)       [$widgets(general_title) get]
    set data(channel_description) [$widgets(general_desc) get 1.0 end-1c]
    set data(channel_link)        [$widgets(general_link) get]
    set data(channel_language)    [$widgets(language) get]
    set specl::rss_url            [$widgets(rss_url) get]
    set data(item_version)        [$widgets(item_version) get]
    set data(item_description)    [$widgets(item_desc) get 1.0 end-1c]
    set data(item_release_notes)  [$widgets(item_notes) get]
    set data(item_download_url)   [$widgets(item_download_url) get]
    
    foreach os $specl::oses {
      set data(item_file,$os) [$widgets(item_file,$os) get]
    }

    # Colorize the missing labels
    $widgets(appname_label)       configure -background [expr {($specl::appname            eq "") ? "red" : ""}]
    $widgets(general_title_label) configure -background [expr {($data(channel_title)       eq "") ? "red" : ""}]
    $widgets(general_desc_label)  configure -background [expr {($data(channel_description) eq "") ? "red" : ""}]
    $widgets(language_label)      configure -background [expr {($data(channel_language)    eq "") ? "red" : ""}]
    $widgets(rss_url_label)       configure -background [expr {($specl::rss_url            eq "") ? "red" : ""}]

    # Set the tab background color to red if any fields are missing
    if {($specl::appname            eq "") || \
        ($data(channel_title)       eq "") || \
        ($data(channel_description) eq "") || \
        ($data(channel_language)    eq "") || \
        ($specl::rss_url            eq "")} {
      $widgets(nb) tab 0 -text "!! General !!"
    } else {
      $widgets(nb) tab 0 -text "General"
    }
    
    $widgets(item_version_label) configure -background [expr {($data(item_version)      eq "") ? "red" : ""}]
    $widgets(item_desc_label)    configure -background [expr {($data(item_description)  eq "") ? "red" : ""}]
    $widgets(item_download_url)  configure -background [expr {($data(item_download_url) eq "") ? "red" : ""}]
    
    set valids              0
    set release_tab_warning 0
    foreach os $specl::oses {
      if {$data(item_val,$os) || ($data(item_prev,$os) ne "")} {
        incr valids 1
      }
      if {[$widgets(item_file_label,$os) cget -background] eq "red"} {
        set release_tab_warning 1
      }
    }
    
    if {$valids == 0} {
      foreach os $specl::oses {
        $widgets(item_file_label,$os) configure -background "red"
      }
      set release_tab_warning 1
    }

    # Set the tab background color to red if any fields are missing
    if {($data(item_version)      eq "") ||
        ($data(item_description)  eq "") ||
        ($data(item_download_url) eq "") ||
        $release_tab_warning} {
      $widgets(nb) tab 1 -text "!! Release !!"
    } else {
      $widgets(nb) tab 1 -text "Release"
    }

    # Check to make sure that the parameters are valid
    if {([$widgets(nb) tab 0 -text] eq "!! General !!") ||
        ([$widgets(nb) tab 1 -text] eq "!! Release !!")} {
      tk_messageBox -parent .relwin -default ok -type ok -message "Missing required fields"
    } else {
      destroy .relwin
    }

    # Allow the UI to update
    update idletasks

  }
  
  ######################################################################
  # Parses the RSS content and save the information in the data array.
  proc parse_rss {type content} {
    
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
    
    if {$type eq "new"} {
      
      # Get the releases node
      set data(other_releases) [lindex [specl::helpers::get_element $channel_node "releases"] 1]
      
    } else {
      
      # Get the last release information and all other releases
      set releases_node [specl::helpers::get_element $channel_node "releases"]

      set first                1
      set data(other_releases) ""
      foreach release_node [specl::helpers::get_elements $releases_node "release"] {
        
        if {$first} {
          
          set data(item_version)       [specl::helpers::get_attr $release_node "version"]
          set data(item_release)       [specl::helpers::get_attr $release_node "index"]
          set data(item_release_notes) [lindex [specl::helpers::get_element $release_node "specl:releaseNotesLink"] 1]
          set description_node         [specl::helpers::get_element $release_node "description"]
          set data(item_description)   [specl::helpers::get_cdata $description_node]
          
          set downloads_node [specl::helpers::get_element $release_node "downloads"]
          foreach download_node [specl::helpers::get_elements $downloads_node "download"] {
            set os [specl::helpers::get_attr $download_node "os"]
            set data(item_prev,$os)     1
            set data(item_url,$os)      [specl::helpers::get_attr $download_node "url"]
            set data(item_length,$os)   [specl::helpers::get_attr $download_node "length"]
            set data(item_checksum,$os) [specl::helpers::get_attr $download_node "checksum"]
            if {[file exists [set item_file [file join $data(cl_directory) [file tail $data(item_url,$os)]]]]} {
              set data(item_file,$os) $item_file
            }
          }
          
          set first 0
          
        } else {
          
          append data(other_releases) "<release [lindex $release_node 0]>[lindex $release_node 1]</release>"
          
        }
        
      }
      
    }
 
  }
  
  ######################################################################
  # Read RSS data.
  proc read_rss {type} {
    
    variable data
    
    # Get the filename of the local appcast.xml file
    set local_appcast [file join $data(cl_directory) appcast.xml]
    
    # If we are in edit mode and the appcast file exists, read it
    if {($type eq "edit") && [file exists $local_appcast]} {
      
      # Read the content from the appcast file
      if {![catch { open $local_appcast r } rc]} {
        set content [read $rc]
        close $rc
        parse_rss $type $content
      } else {
        return -code error "ERROR:  Unable to read $local_appcast for editing"
      }
      
    # Otherwise, get the information fro the appcast file online
    } else {
      
      # Get the RSS file to read
      set token [http::geturl "$specl::rss_url/appcast.xml"]
    
      # If the request is valid, parse the content
      if {([set status [http::status $token]] eq "ok") && ([set ncode [http::ncode $token]] == 200)} {
        parse_rss $type [http::data $token] 
      } else {
        puts "Warning:  Unable to fetch RSS information, status: $status, ncode: $ncode"
      }
    
      # Cleanup the request
      http::cleanup $token
      
    }
    
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
      puts $rc "set specl::download_url \"$data(item_download_url)\""
      
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
      puts $rc "        <downloads>"
      
      foreach os $specl::oses {
        if {$data(item_val,$os) || $data(item_prev,$os)} {
          puts $rc "          <download os=\"$os\" url=\"$data(item_url,$os)\" length=\"$data(item_length,$os)\" type=\"application/octet-stream\" checksum=\"$data(item_checksum,$os)\" />"
        }
      }
      
      puts $rc "        </downloads>"
      puts $rc "      </release>"
      puts $rc "      $data(other_releases)"
      puts $rc "    </releases>"
      puts $rc "  </channel>"
      puts $rc "</rss>"
      
      close $rc
      
    }
    
  }
  
  ######################################################################
  # Returns the MD5 checksum for the given bundle.
  proc get_checksum {bundle} {
    
    # On Mac OSX, the md5sum executable is just called "md5" and its output is a bit different
    if {$::tcl_platform(os) eq "Darwin"} {
      if {[catch { exec -ignorestderr md5 $bundle } rc]} {
        return ""
      }
      return [lindex $rc 3]

    # Otherwise, use the normal md5sum
    } else {
      if {[catch { exec -ignorestderr md5sum $bundle } rc]} {
        return ""
      }
      return [lindex $rc 0]
    }
    
  }
  
  ######################################################################
  # Create the files that need to be sent.
  proc create_files {type} {
    
    variable data
    
    # Create a temporary directory for the application files
    if {$data(cl_directory) ne ""} {
      set tmp $data(cl_directory)
    } else {
      set tmp [file join / tmp]
    }
    
    # Write the version file to the current directory if we are creating a new release
    if {$type eq "new"} {
      if {$data(cl_verbose)} { puts -nonewline "Writing specl_version.tcl ............."; flush stdout }
      write_version
      if {$data(cl_verbose)} { puts "  Done!" }
    }
    
    foreach os $specl::oses {
      
      if {$data(item_val,$os) || ($data(item_prev,$os) && ($data(item_file,$os) ne ""))} {
        
        # Figure out the size of the tarball and save it to the item_length item
        set data(item_length,$os) [file size $data(item_file,$os)]
      
        # Figure out the md5 checksum
        if {$data(cl_verbose)} { puts -nonewline "Calculate checksum ...................."; flush stdout }
        set data(item_checksum,$os) [get_checksum $data(item_file,$os)]
        if {$data(cl_verbose)} { puts "  Done!" }
        
        # Create the item URL
        set data(item_url,$os) "$data(item_download_url)/[file tail $data(item_file,$os)]"
        
      }
      
    }
      
    # Write the RSS file
    if {$data(cl_verbose)} { puts -nonewline "Writing RSS appcast file .............."; flush stdout }
    write_rss $tmp
    if {$data(cl_verbose)} { puts "  Done!\n" }
    
    puts "Upload [file join $tmp appcast.xml] to $specl::rss_url/appcast.xml"
    
    foreach os $specl::oses {
      if {$data(item_val,$os)} {
        puts "Upload $data(item_file,$os) to $data(item_url,$os)"
      }
    }
    
    puts ""

  }
  
  ######################################################################
  # Performs a release of the current project.
  proc start_release {type} {
    
    variable data
    
    # Attempt to source the specl_version.tcl file
    if {[catch { specl::load_specl_version [pwd] } rc]} {
      
      # If the specl_version file doesn't exist, initialize the variables
      set data(item_version)      "1.0"
      set data(item_release)      1
      set data(item_download_url) ""
      
    } else {
      
      # Initialize variables from specl_version file
      set data(item_version)      $specl::version
      set data(item_release)      $specl::release
      set data(item_download_url) $specl::download_url
      
      # If we are creating a new release, increment the release number
      if {$type eq "new"} {
        incr data(item_release)
      }
      
      # Read the RSS file since it exists
      read_rss $type
      
    }
    
    # Get the release information from the user
    if {!$data(cl_noui)} {
      get_release_info
    }
    
    # Create the necessary files
    create_files $type
    
    # End the application
    exit
    
  }
  
}

# If this is being run as an application, do the following
if {[file tail $::argv0] eq "specl.tcl"} {
  
  package require Tk
  package require http

  # Install the htmllib and gifblock
  source [file join [file dirname $::argv0] .. common htmllib.tcl]
  source [file join [file dirname $::argv0] .. common gifblock.tcl]
  source [file join [file dirname $::argv0] .. common resize.tcl]

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
    specl::helpers::open_file_externally $href
  }

  # Handles an image
  proc HMset_image {win handle src} {
    specl::helpers::HMhandle_image $win $handle $src
  }

  ######################################################################
  # END OF HTMLLIB CUSTOMIZATION
  ######################################################################

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
    
    exit 1
    
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
      set args [lassign $args arg command]
      switch $command {
        new {
          if {![specl::releaser::parse_new_args $args]} {
            puts "ERROR:  Incorrect arguments passed to specl release new command"
            usage
          }
        }
        edit {
          if {![specl::releaser::parse_edit_args $args]} {
            puts "ERROR:  Incorrect arguments passed to specl release edit command"
            usage
          }
        }
        default {
          puts "ERROR:  Incorrect arguments passed to specl release command"
          usage
        }
      }
      specl::releaser::start_release $command
    }
    update  {
      set args [lassign $args arg]
      if {![specl::updater::parse_args $args]} {
        puts "ERROR:  Incorrect arguments passed to specl update command"
        usage
      }
      specl::updater::start_update
    }
    default {
      puts "ERROR:  Unknown command/option ([lindex $args 0])"
      usage
    }
  }
  
}
