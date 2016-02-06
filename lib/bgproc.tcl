# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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
# Name:    bgproc.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/13/2013
# Brief:   Provides services for performing system and Tcl commands in
#          the background.
######################################################################

namespace eval bgproc {

  source [file join $::tke_dir lib ns.tcl]

  variable last_update     0
  variable update_interval 100

  array set resource_completed {
    all 0
  }
  array set resources    {}
  array set resource_pid {}
  array set resource_tmo {}
  array set cancelled    {}

  #############################################################
  #------------------------------------------------------------
  #  PUBLIC PROCEDURES
  #------------------------------------------------------------
  #############################################################

  #############################################################
  # This procedure should be called by the toplevel code when
  # it wants to wait for all pending commands to complete.
  # blocks until all background activity has completed.
  proc synchronize {{resource ""}} {

    variable resource_completed
    variable resources

    # Wait for the specified resource to complete
    if {$resource ne ""} {

      # If the given resource list is in existence, wait for it to complete.
      if {[info exists resources($resource)]} {
        if {![info exists resource_completed($resource)]} {
          set resource_completed($resource)] 0
        }
        vwait bgproc::resource_completed($resource)
      }

    # Wait for all resources to complete
    } else {

      # If we have any processes outstanding, wait for them to be completed.
      if {[array size resources] > 0} {
        vwait bgproc::resource_completed(all)
      }

    }

  }

  #############################################################
  # Calls the given system command in the background and guarantees
  # that it will complete before the GUI is shutdown.
  proc system {resource cmd args} {

    # Handle options
    array set opts {
      -cancelable   0
      -killable     0
      -releasable   0
      -callback     ""
      -readcallback ""
      -redirect     ""
      -timeout      0
      -variable     ""
    }
    array set opts $args

    # Push the resource
    push_resource $resource [array get opts] [list bgproc::system_helper $resource $cmd $opts(-callback) $opts(-readcallback) $opts(-redirect) $opts(-timeout) $opts(-variable)]

  }

  #############################################################
  # Calls the given Tcl command in the background and guarantees
  # that it will complete before the GUI is shutdown.
  proc command {resource cmd args} {

    # Handle options
    array set opts {
      -cancelable 0
      -callback   ""
    }
    array set opts $args

    # We cannot kill or release Tcl commands
    array set opts {
      -killable   0
      -releasable 0
    }

    # Push the resource
    push_resource $resource [array get opts] [list bgproc::command_helper $resource $cmd $opts(-callback)]

  }

  #############################################################
  # This procedure can be called from anywhere.  It calls the
  # update command if it hasn't been called within a specified
  # period of time.
  proc update {{initialize 0}} {

    variable last_update
    variable update_interval

    # Get the current time
    set curr_time [clock milliseconds]

    # If we are initializing, don't update
    if {$initialize} {
      set last_update $curr_time

    # If the difference between the last update time and the current time exceeds the
    # maximum allowed update interval, perform the update and save the current time as
    # the last update time.
    } elseif {($curr_time - $last_update) >= $update_interval} {
      set last_update $curr_time
      ::update
    }

  }

  if {[string first wish [info nameofexecutable]] != -1} {

    #############################################################
    # Displays a progress dialog box that performs a local grab with
    # a potential cancel button (available if the resource is killable).
    proc progress_dialog {resource msg parent} {

      variable resources
      variable cancelled

      if {[llength $resources($resource)] > 0} {

        set w ".resourceprogwin[lsearch [array names resources] $resource]"

        if {![winfo exists $w]} {

          toplevel            $w -bd 2 -relief raised
          wm overrideredirect $w 1
          wm transient        $w $parent
          wm resizable        $w 0 0

          frame            $w.f
          label            $w.f.msg    -text $msg
          ttk::progressbar $w.f.pb     -orient horizontal -mode indeterminate
          button           $w.f.cancel -text [msgcat::mc "Cancel"] -command "set bgproc::cancelled($resource) 1; bgproc::killall $resource"

          grid columnconfigure $w.f 0 -weight 1
          grid $w.f.msg -row 0 -column 0 -sticky news -padx 2 -pady 2
          grid $w.f.pb  -row 1 -column 0 -sticky news -padx 2 -pady 2
          if {[lindex $resources($resource) 0 2]} {
            grid $w.f.cancel -row 0 -column 1 -sticky ews -rowspan 2 -padx 2 -pady 2
          }

          pack $w.f -fill both -expand yes

          # Place the window and set the focus/grab
          ::tk::PlaceWindow $w widget $parent
          ::tk::SetFocusGrab $w $w

          # Start the progress bar
          $w.f.pb start

          # Wait for the resource to complete
          synchronize $resource

          # Stop the progress bar
          $w.f.pb stop

          # Restore the focus and grab
          ::tk::RestoreFocusGrab $w $w

          # Return a value of 0 if we were cancelled
          if {[info exists cancelled($resource)]} {
            unset cancelled($resource)
            return 0
          }

        }

      }

      return 1

    }

  }

  #############################################################
  #------------------------------------------------------------
  #  INTERNAL PROCEDURES
  #------------------------------------------------------------
  #############################################################

  #############################################################
  # Gathers the command output from the given command channel.
  proc get_command_output {resource callback readcallback fid pid redirect_id var} {

    variable system_result
    variable resource_pid
    variable resource_tmo

    if {[eof $fid]} {

      # Change the file to blocking so that we can get error information from it - TBD
      fconfigure $fid -blocking 1

      # Close the channel
      if {[catch "close $fid" rc]} {
        set error_found         1
        set system_result($pid) $rc
        if {$var ne ""} {
          upvar #0 $var uvar
          set uvar ""
        }
      } else {
        set error_found 0
      }

      # Handle an I/O redirect
      if {$redirect_id ne ""} {
        catch "close $redirect_id"
      }

      # If we have a timeout mechanism set for our resource, cancel it.
      if {[info exists resource_tmo($resource)]} {
        after cancel $resource_tmo($resource)
        unset resource_tmo($resource)
      }

      # If we have a callback function to invoke, call it now
      if {[info exists resource_pid($resource)]} {
        unset resource_pid($resource)
        if {$callback ne ""} {
          if {[catch "$callback $error_found [list $system_result($pid)]" rc]} {
            bgerror $rc
          }
        }
        unset system_result($pid)
      }

      # Pop the current resource and handle any new jobs
      pop_resource $resource

    } elseif {[set data [read $fid]] ne ""} {
      if {$redirect_id ne ""} {
        puts -nonewline $redirect_id $data
      }
      if {$readcallback ne ""} {
        if {[catch "$readcallback [list $data]" rc]} {
          bgerror $rc
        }
      }
      append system_result($pid) $data
      if {$var ne ""} {
        upvar #0 $var uvar
        append uvar $data
      }
    }

  }

  #############################################################
  # Helper procedure for the system procedure.
  proc system_helper {resource cmd callback readcallback redirect timeout var} {

    variable system_result
    variable resources
    variable resource_pid
    variable resource_tmo

    # If we are killable and our resource queue is > 1, don't run ourself.
    if {![lindex $resources($resource) 0 2] || ([llength $resources($resource)] == 1)} {

      # Start the executable in the background
      if {[catch "open {| $cmd 2>@1} r" cmd_id]} {
        if {$callback ne ""} {
          if {[catch "$callback 1 [list $cmd_id]" rc]} {
            bgerror $rc
          }
        } else {
          notifier::notify -type error -parent $::top_window \
            -message [format "%s (%s)" [msgcat::mc "Unable to run system command"] $cmd] -detail $cmd_id
        }
        pop_resource $resource
        return
      }

      set pid                 [pid $cmd_id]
      set system_result($pid) ""

      # If a variable was specified, initialize it as well
      if {$var ne ""} {
        upvar #0 $var uvar
        set uvar ""
      }

      # Add our PID to the resources queue
      set resource_pid($resource) $pid

      # If we need to redirect the I/O, open the file
      set redirect_id ""
      if {$redirect ne ""} {
        set redirect_id [open $redirect a]
      }

      # Create a file handler to gather the return information
      fconfigure $cmd_id -blocking 0
      fileevent  $cmd_id readable [list bgproc::get_command_output $resource $callback $readcallback $cmd_id $pid $redirect_id $var]

      # If a timeout value was specified, kill the resource after the specified period of time
      if {$timeout > 0} {
        set resource_tmo($resource) [after $timeout [list bgproc::kill_pid $resource]]
      }

    } else {

      # Pop the current resource and handle any new jobs
      pop_resource $resource

    }

  }

  #############################################################
  # Interrupts the given PID and frees the resource_pid, if necessary.
  proc interrupt_pid {resource} {

    variable resource_pid
    variable resource_tmo

    if {[info exists resource_pid($resource)]} {
      if {![catch "exec kill -s INT $resource_pid($resource)" rc]} {
        unset resource_pid($resource)
      }
    }

    catch "unset resource_tmo($resource)"

  }

  #############################################################
  # Kills the given PID and frees the resource_pid, if necessary.
  proc kill_pid {resource} {

    variable resource_pid
    variable resource_tmo

    if {[info exists resource_pid($resource)]} {
      if {![catch "exec kill -9 $resource_pid($resource)" rc]} {
        unset resource_pid($resource)
      }
    }

    catch "unset resource_tmo($resource)"

  }

  #############################################################
  # Helper procedure for the command proc.
  proc command_helper {resource cmd {callback ""}} {

    # Perform the command
    set retval [eval $cmd]

    # If we have a callback function to invoke, call it now
    if {$callback ne ""} {
      eval "$callback [list $retval]"
    }

    # Pop the current resource and handle any new jobs
    pop_resource $resource

  }

  #############################################################
  # Kills/removes all resources from the given resource queue
  # pattern.  Returns 1 if a process was successfully killed;
  # otherwise, returns 0.
  proc killall {{pattern *}} {

    variable resources
    variable resource_pid

    set retval 0

    foreach resource [array names resources $pattern] {

      if {[info exists resources($resource)] && [lindex $resources($resource) 0 2]} {

        if {[info exists resource_pid($resource)]} {

          # Kill the resource at the beginning of the queue
          if {![catch "exec kill -9 $resource_pid($resource)"]} {
            unset resource_pid($resource)
          }

        }

        # Clear out the rest of the entries in the given resource list
        if {[llength $resources($resource)] > 1} {
          set resources($resource) [lrange $resources($resource) 1 end]
        }

        set retval 1

      }

    }

    return $retval

  }

  #############################################################
  # Releases any resources that are releasable.
  proc releaseall {} {

    variable resources
    variable resource_pid

    foreach resource [array names resources] {
      if {[llength [set resources($resource) [lsearch -not -all -inline -index 3 $resources($resource) 1]]] == 0} {
        unset resources($resource)
      }
    }

  }

  #############################################################
  # Adds a given resource to its resource queue and runs the head
  # queue, if its the only one.
  proc push_resource {resource popts cmd} {

    variable resources
    variable resource_pid

    array set opts $popts

    # Add the command call to the associated resource queue
    lappend resources($resource) [list $cmd $opts(-cancelable) $opts(-killable) $opts(-releasable)]

    # Call the system helper, if we are the only thing in the resource queue, run it now
    if {[llength $resources($resource)] == 1} {
      after 1 [lindex $resources($resource) 0 0]

    # If the command at the head of the queue is killable, kill it now
    } elseif {[lindex $resources($resource) 0 2] && [info exists resource_pid($resource)]} {

      # Attempt to kill the job
      if {![catch "exec kill -9 $resource_pid($resource)"]} {
        unset resource_pid($resource)
      }

    }

  }

  #############################################################
  # Pops the given resource and starts the next job, if one exists.
  proc pop_resource {resource} {

    variable resources
    variable resource_completed

    # Pop ourselves off of the resource queue and start the next, if there is something
    set resources($resource) [lrange $resources($resource) 1 end]

    # Start the next command if one exists
    if {[llength $resources($resource)] > 0} {

      # Pop any cancelable events (except for the last one)
      while {([llength $resources($resource)] > 1) && [lindex $resources($resource) 0 1]} {
        set resources($resource) [lrange $resources($resource) 1 end]
      }

      # Run the command
      after 1 [lindex $resources($resource) 0 0]

    } else {

      unset resources($resource)
      set resource_completed($resource) 1

      # If the resource array is empty, specify that all current processes have completed
      if {[array size resources] == 0} {
        set resource_completed(all) 1
      }

    }

  }

}
