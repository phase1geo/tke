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

package provide specl 2.0

source [file join [specl::DIR] lib bgproc.tcl]
source [file join [specl::DIR] lib utils.tcl]

namespace eval specl {

  ######################################################################
  # Returns the full, normalized pathname of the specl_version.tcl file.
  proc get_specl_version_dir {start_dir} {

    set current_dir [file normalize $start_dir]
    while {($current_dir ne "/") && \
           ![file exists [file join $current_dir specl_version.tcl]] && \
           ![file exists [file join $current_dir specl specl_version.tcl]]} {
      set current_dir [file dirname $current_dir]
    }

    # If we could not find the specl_version.tcl file, return an error
    if {$current_dir eq "/"} {

      # If we are running Mac OSX, the specl_version.tcl file could be in one of the child
      # directories under start_dir, check to see if this is the case
      if {$::tcl_platform(os) eq "Darwin"} {
        if {![catch { exec -ignorestderr find $start_dir -name specl_version.tcl } rc] && ([set current_dir [string trim $rc]] ne "")} {
          foreach line [split $rc \n] {
            set current_dir [file dirname [string trim $line]]
            if {[file tail $current_dir] eq "specl"} {
              return $current_dir
            }
          }
          return $current_dir
        }
      }

      # Otherwise, specify that we could not find the specl_version.tcl file
      return -code error "Unable to find specl_version.tcl file"

    # If we found a specl directory with the version file within it, adjust the current_dir
    } elseif {[file exists [file join $current_dir specl specl_version.tc]]} {

      set current_dir [file join $current_dir specl]

    }

    return $current_dir

  }

  ######################################################################
  # Checks for updates.  Throws an exception if there was a problem
  # checking for the update.
  proc check_for_update {on_start release_type args} {

    array set opts {
      -cl_args        {}
      -cleanup_script ""
      -title          "Software Updater"
      -test_mode      ""
    }
    array set opts $args

    # Allow the UI to update before we proceed
    update

    # Loads the specl_version.tcl file
    set specl_version_dir [get_specl_version_dir $::tke_dir]

    # Get the normalized name of argv0
    set script_name [file normalize $::argv0]

    # Create update arguments
    if {$on_start} {
      set update_args "-q"
    }
    if {$opts(-test_mode) ne ""} {
      lappend update_args -test $opts(-test_mode)
    }
    lappend update_args -t [ttk::style theme use] -r $release_type
    lappend update_args $specl_version_dir

    # puts "[info nameofexecutable] [file join [specl::DIR] lib updater.tcl] -- $update_args"

    # Execute this script
    bgproc::system updater [list [info nameofexecutable] [file join [specl::DIR] lib updater.tcl] -name $opts(-title) -- {*}$update_args] \
      -callback [list specl::complete_update $opts(-test_mode) $script_name $specl_version_dir $opts(-cleanup_script) $opts(-cl_args)]

    # If this is on startup, wait for the update to complete before moving on
    if {$on_start} {
      bgproc::synchronize updater
    }

  }

  ######################################################################
  # Called on completion of the update operation.
  proc complete_update {test_mode script_name specl_version_dir cleanup_script cl_args err data} {

    # puts "In complete_update, script_name: $script_name, specl_version_dir: $specl_version_dir, cl_args: $cl_args, err: $err, data: $data"

    if {!$err && ($test_mode eq "")} {

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

}

