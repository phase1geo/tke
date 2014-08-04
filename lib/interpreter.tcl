# Name:    interpreter.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    8/1/2014
# Brief:   Namespace to support a plugin interpreter.

namespace eval interpreter {

  array set interps {}
  
  ######################################################################
  # Check the given file's accessibility (the file should be translated
  # prior to calling this procedure).
  proc check_file_access {pname fname} {
  
    variable interps
    
    if {[$interps($pname,interp) issafe]} {
    
      # Normalize the file name
      set fname [file normalize $fname]
  
      # Verify that the directory is within the access paths
      foreach access_dir [lindex [::safe::interpConfigure $interps($pname,interp) -accessPath] 1] {
        if {[string compare -length [string length $access_dir] $access_dir $fname] == 0} {
          return $fname
        }
      }
  
      return ""
      
    } else {
    
      return $fname
      
    }

  }
  
  ######################################################################
  # Checks to make sure that the given directory is within the allowed
  # directory paths.  Returns the name of the file if the directory is
  # okay to process; otherwise, returns the empty string.
  proc check_file {pname fname} {
    
    variable interps
    
    # We only need to check the file if we are in safe mode.
    if {[$interps($pname,interp) issafe]} {
    
      # Translate the directory
      if {[catch {::safe::TranslatePath $interps($pname,interp) $fname} fname]} {
        return ""
      }
      
      return [check_file_access $pname $fname]
      
    } else {
      
      return $fname
      
    }
    
  }
  
  ######################################################################
  # Adds a ctext widget to the list of wins (however, destroying the
  # interpreter will not destroy the ctext widgets).
  proc add_ctext {pname txt} {
    
    variable interps
    
    lappend interps($pname,wins) [list $txt 0] [list $txt.t 0]
    
  }
  
  ######################################################################
  # Creates a widget on behalf of the plugin, records and returns its value.
  proc widget_command {pname widget win args} {

    variable interps
    
    set command_args [list \
      -command -postcommand -validatecommand -invalidcommand -xscrollcommand \
      -yscrollcommand \
    ]
    
    # Substitute any commands with the appropriate interpreter eval statement
    set opts [list]
    foreach {opt value} $args {
      if {[lsearch $command_args $opt] != -1} {
        set value "$interps($pname,interp) eval $value"
      }
      lappend opts $opt $value
    }

    # Create the widget
    $widget $win {*}$opts

    # Allow the interpreter to do things with the element
    $interps($pname,interp) alias $win interpreter::widget_win $pname $win

    # Record the widget
    lappend interps($pname,wins) [list $win 1]

    return $win

  }
  
  ######################################################################
  # Handles any widget calls to cget/configure commands.
  proc widget_win {pname win cmd args} {
    
    variable interps
    
    set command_args [list \
      -command -postcommand -validatecommand -invalidcommand -xscrollcommand \
      -yscrollcommand \
    ]
    
    switch $cmd {
      
      cget {
        set opt [lindex $args 0]
        if {[lsearch $command_args $opt] != -1} {
          return [lrange [$win cget $opt] 2 end]
        } else {
          return [$win cget $opt]
        }
      }
      
      entrycget {
        lassign $args entry_index opt
        if {[lsearch $command_args $opt] != -1} {
          return [lrange [$win entrycget $entry_index $opt] 2 end]
        } else {
          return [$win entrycget $entry_index $opt]
        }
      }
      
      configure {
        set retval [list]
        switch [llength $args] {
          0 {
            foreach opt [$win configure] {
              if {[lsearch $command_args [lindex $opt 0]] != -1} {
                lset opt 4 [lrange [lindex $opt 4] 2 end]
              }
              lappend retval $opt
            }
            return $retval
          }
          1 {
            set opt    [lindex $args 0]
            set retval [$win configure $opt]
            if {[lsearch $command_args $opt] != -1} {
              lset retval 4 [lrange [lindex $retval 4] 2 end]
            }
            return $retval
          }
          default {
            foreach {opt value} $args {
              if {[lsearch $command_args $opt] != -1} {
                set value "$interps($pname,interp) eval $value"
              }
              lappend retval $opt $value
            }
            return [$win configure {*}$retval]
          }
        }
      }
      
      entryconfigure {
        set retval [list]
        set args [lassign $args entry_index]
        switch [llength $args] {
          0 {
            foreach opt [$win entryconfigure $entry_index] {
              if {[lsearch $command_args [lindex $opt 0]] != -1} {
                lset opt 4 [lrange [lindex $opt 4] 2 end]
              }
              lappend retval $opt
            }
            return $retval
          }
          1 {
            set opt    [lindex $args 0]
            set retval [$win entryconfigure $entry_index $opt]
            if {[lsearch $command_args $opt] != -1} {
              lset retval 4 [lrange [lindex $retval 4 2 end]
            }
            return $retval
          }
          default {
            foreach {opt value} $args {
              if {lsearch $command_args $opt] != -1} {
                set value "$interps($pname,interp) eval $value"
              }
              lappend retval $opt $value
            }
            return [$win entryconfigure $entry_index {*}$retval]
          }
        }
      }
      
      add {
        set args [lassign $args retval]
        foreach {opt value} $args {
          if {[lsearch $command_args $opt] != -1} {
            set value "$interps($pname,interp) eval $value"
          }
          lappend retval $opt $value
        }
        return [$win add {*}$retval]
      }
      
      default {
        return [$win $cmd {*}$args]
      }
    }
    
  }
  
  ######################################################################
  # Destroys the specified widget (if it was created by the interpreter
  # specified by pname).
  proc destroy_command {pname win} {

    variable interps

    if {[set win_index [lsearch $interps($pname,wins) [list $win 1]]] != -1} {
      set interps($pname,wins) [lreplace $intersp($pname,wins) $win_index $win_index]
      catch { destroy $win }
    }

  }
  
  ######################################################################
  # Binds an event to a widget owned by the slave interpreter.
  proc bind_command {pname tag args} {
  
    variable interps
    
    switch [llength $args] {
      1 { return [bind $tag [lindex $args 0]] }
      2 { 
        if {[string index [lindex $args 1] 0] eq "+"} {
          return [bind $tag [lindex $args 0] [list +interp eval $interps($pname,interp) [lrange [lindex $args 1] 1 end]]]
        } else {
          return [bind $tag [lindex $args 0] [list interp eval $interps($pname,interp) [lindex $args 1]]]
        }
      }
    }
    
  }
  
  ######################################################################
  # Executes a safe winfo command.
  proc winfo_command {pname subcmd args} {
  
    variable interps
    
    switch $subcmd {
      atom -
      atomname -
      cells -
      children -
      class -
      colormapfull -
      depth -
      exists -
      fpixels -
      geometry -
      height -
      id -
      ismapped -
      manager -
      name -
      pixels -
      pointerx -
      pointerxy -
      pointery -
      reqheight -
      reqwidth -
      rgb -
      rootx -
      rooty -
      screen -
      screencells -
      screendepth -
      screenheight -
      screenmmheight -
      screenmmwidth -
      screenvisual -
      screenwidth -
      viewable -
      visual -
      visualsavailable -
      vrootheight -
      vrootwidth -
      vrootx -
      vrooty -
      width -
      x -
      y {
        if {[lsearch -index 0 $interps($pname,wins) [lindex $args 0]] == -1} {
          return -code error 
        }
        return [winfo $subcmd {*}$args]
      }
      containing -
      parent -
      pathname -
      toplevel {
        set win [winfo $subcmd {*}$args]
        if {[lsearch -index 0 $interps($pname,wins) $win] == -1} {
          return -code error "permission error"
        }
        return $win
      }
      default {
        return -code error "permission error"
      }
    }
  
  }
  
  ######################################################################
  # Executes a safe wm command.
  proc wm_command {pname subcmd win args} {
  
    variable interps
    
    if {[lsearch $interps($pname,wins) [list $win 1]] != -1} {
      return [wm $subcmd $win {*}$args]
    } else {
      return ""
    }
    
  }
  
  ######################################################################
  # Executes a safe image command.
  proc image_command {pname subcmd args} {
  
    variable interps
    
    switch $subcmd {
      
      create {      
        
        # Find any -file or -maskfile options and convert the filename and check it
        set i 0
        while {$i < [llength $args]} {
          switch [lindex $args $i] {
            -file -
            -maskfile {
              if {[set fname [check_file $pname [lindex $args [incr i]]]] eq ""} {
                return -error code "permission error"
              }
              lset args $i $fname
            }  
          }
          incr i
        }
      
        # Create the image
        set img [image create {*}$args]
        
        # Create an alias for the image so that it can be used in cget/configure calls
        $interps($pname,interp) alias $img interpreter::image_win $pname $img
      
        # Hang onto the generated image
        lappend interps($pname,images) $img
      
        return $img
        
      }
      
      delete {
        
        foreach name $args {
          if {[set img_index [lsearch $interps($pname,images) $name]] != -1} {
            set interps($pname,images) [lreplace $interps($pname,images) $img_index $img_index]
            image delete $name
          }
        }
        
      }
      
      default {
        
        return [image $subcmd {*}$args]
        
      } 

    }
  
  }
  
  ######################################################################
  # Handles a call to manipulate the image.
  proc image_win {pname img cmd args} {
  
    variable interps
    
    # Probably unnecessary, but it can't hurt to check that the image is part of this plugin
    if {[lsearch $interps($pname,images) $img] == -1} {
      return -code error "permission error"
    }
    
    switch $cmd {
      
      cget {
        
        switch [lindex $args 0] {
          -file -
          -maskfile {
            set fname [$img cget [lindex $args 0]]
            return [file join [::safe::interpFindInAccessPath $interps($pname,interp) [file dirname $fname]] [file tail $fname]]
          }
        }
        
      }
      
      configure {
        
        set i 0
        while {$i < [llength $args]} {
          switch [lindex $args $i] {
            -file -
            -maskfile {
              if {[set fname [check_file $pname [lindex $args [incr i]]]] eq ""} {
                return -code error "permission error"
              }
              lset args $i $fname
            }
          }
          incr i
        }
        
        return [$img configure {*}$args]
        
      }
      
    }
    
  }
  
  ######################################################################
  # Executes the open command.
  proc open_command {pname fname args} {
  
    variable interps
    
    # Make sure that the given filename is valid
    if {[set fname [check_file $pname $fname]] eq ""} {
      return -code error "permission error"
    }
    
    # Open the file
    if {[catch { open $fname {*}$args } rc]} {
      return -code error $rc
    }
    
    # Share the file stream with the interpreter
    interp share {} $rc $interps($pname,interp)
    
    # Save the file descriptor
    lappend interps($pname,files) $rc
    
    return $rc
  
  }
  
  ######################################################################
  # Executes the close command.
  proc close_command {pname channel} {
  
    variable interps
    
    if {[lsearch $interps($pname,files) $channel] != -1} {
      close $channel
    }
    
  }

  ######################################################################
  # Executes the flush command.
  proc flush_command {pname channel} {
  
    variable interps
    
    if {[lsearch $interps($pname,files) $channel] != -1} {
      flush $channel
    }
    
  }
  
  ######################################################################
  # Executes the exec command.
  proc exec_command {pname args} {
    
    variable interps
    
    if {![$interps($pname,interp) issafe]} {
      return [exec {*}$args]
    } else {
      return -code error "permission error"
    }
    
  }
  
  ######################################################################
  # Executes the file command.
  proc file_command {pname subcmd args} {
    
    variable interps
    
    switch $subcmd {
      
      atime -
      attributes -
      exists -
      executable -
      isdirectory -
      isfile -
      mtime -
      owned -
      readable -
      size -
      type -
      writable {
        if {[set fname [check_file $pname [lindex $args 0]]] eq ""} {
          return -code error "permission error"
        }
        return [file $subcmd $fname {*}[lrange $args 1 end]]
      }
      
      delete {
        set opts   [list]
        set fnames [list]
        set double_dash_seen 0
        foreach arg $args {
          if {!$double_dash_seen && [string index $arg 0] eq "-"} {
            if {$arg eq "--"} {
              set double_dash_seen 1
            }
            lappend opts $arg
          } elseif {[set fname [check_file $pname $arg]] ne ""} {
            lappend fnames $fname
          }
        }
        if {[llength $fnames] > 0} {
          return [file delete {*}$opts {*}$fnames]
        } else {
          return -code error "permission error"
        }
      }
      
      dirname {
        if {[set fname [check_file $pname [lindex $args 0]]] eq ""} {
          return -code error "permission error"
        }
        if {[set fname [check_file_access $pname [file dirname $fname]]] eq ""} {
          return -code error "permission error"
        }
        return [::safe::interpFindInAccessPath $interps($pname,interp) $fname]
      }
      
      mkdir {
        set dnames [list]
        foreach arg $args {
          if {[set dname [check_file $pname $arg]] ne ""} {
            lappend dnames $dname
          }
        }
        if {[llength $dnames] > 0} {
          return [file mkdir {*}$dnames]
        } else {
          return -code error "permission error"
        }
      }
      
      join -
      extension -
      rootname -
      tail -
      separator -
      split {
        return [file $subcmd {*}$args]
      }
      
      default {
        if {![$interps($pname,interp) issafe]} {
          return [file $subcmd {*}$args]
        }
        return -code error "file command $subcmd is not allowed by a plugin"
      }
    }
    
  }
  
  ######################################################################
  # Executes the glob command.
  proc glob_command {pname args} {
    
    variable interps
    
    set i        0
    set new_args [list]
    
    # Parse the options
    while {$i < [llength $args]} {
      switch -exact [set opt [lindex $args $i]] {
        -directory -
        -path {
          if {[set dname [check_file $pname [lindex $args [incr i]]]] eq ""} {
            return -code error "permission error"
          }
          lappend new_args $opt $dname
        }
        default {
          lappend new_args $opt
        }
      } 
      incr i
    }
    
    # Encode the returned filenames
    set fnames [list]
    foreach fname [glob {*}$new_args] {
      lappend fnames [file join [::safe::interpFindInAccessPath $interps($pname,interp) [file dirname $fname]] [file tail $fname]]
    }
    
    return $fnames
    
  }
  
  ######################################################################
  # Creates and sets up a safe interpreter for a plugin.
  proc create {pname trust_granted} {

    variable interps
    
    # Setup the access paths
    lappend access_path $::tcl_library
    lappend access_path [file join $::tke_home plugins $pname]
    lappend access_path [file join $::tke_dir  plugins $pname]
    lappend access_path [file join $::tke_dir  plugins images]
    
    # Create the interpreter
    if {$trust_granted} {
      set interp [interp create]
    } else {
      set interp [::safe::interpCreate -nested true -accessPath $access_path]
    }
    
    # Save the interpreter and initialize the structure
    set interps($pname,interp) $interp
    set interps($pname,wins)   [list]
    set interps($pname,files)  [list]
    set interps($pname,images) [list]
    
    # If we are in development mode, share standard output for debug purposes
    if {[::tke_development]} {
      interp share {} stdout $interp
    }
    
    # Create Tcl command aliases if we are running in untrusted mode
    if {!$trust_granted} {
      foreach cmd [list close exec file flush glob open] {
        $interp alias $cmd interpreter::${cmd}_command $pname
      }
    }
    
    # Create raw ttk widget aliases
    foreach widget [list canvas listbox menu text toplevel ttk::button ttk::checkbutton ttk::combobox \
                         ttk::entry ttk::frame ttk::label ttk::labelframe ttk::menubutton ttk::notebook \
                         ttk::panedwindow ttk::progressbar ttk::radiobutton ttk::scale ttk::scrollbar \
                         ttk::separator ttk::spinbox ttk::treeview] {
      $interp alias $widget interpreter::widget_command $pname $widget
    }

    # Create Tk commands
    foreach cmd [list clipboard event focus font grid pack place tk_messageBox] {
      $interp alias $cmd $cmd
    }

    # Specialized Tk commands
    foreach cmd [list destroy bind winfo wm image] {
      $interp alias $cmd interpreter::${cmd}_command $pname
    }

    # Recursively add all commands that are within the api namespace
    foreach pattern [list ::api::* {*}[join [namespace children ::api]::* {::* }]] {
      foreach cmd [info commands $pattern] {
        if {$cmd ne "::api::ns"} {
          $interp alias $cmd $cmd $interp $pname
        }
      }
    }
    
    # Create TKE command aliases
    $interp alias api::register          plugins::register
    $interp alias api::auto_adjust_color utils::auto_adjust_color  ;# TEMPORARY
    
    return $interp
    
  }
  
  ######################################################################
  # Destroys the interpreter at the given index.
  proc destroy {pname} {
  
    variable interps
    
    # Destroy any existing windows
    foreach win $interps($pname,wins) {
      if {[lindex $win 1]} {
        catch { ::destroy [lindex $win 0] }
      }
    }
    
    # Close any opened files
    foreach channel $interps($pname,files) {
      catch { close $channel }
    }
    
    # Destroy any images
    foreach img $interps($pname,images) {
      catch { image delete $img }
    }

    # Finally, destroy the interpreter
    catch { ::safe::interpDelete $interps($pname,interp) }
    
    # Destroy the interpreter for the given plugin name
    array unset interps $pname,*
    
  }
  
}
