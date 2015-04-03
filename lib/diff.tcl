# Name:     diff.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     3/23/2015
# Brief:    Contains namespace which handles displaying file version differences

namespace eval diff {

  source [file join $::tke_dir lib ns.tcl]

  array set data {}
  
  # Check to see if the ttk::spinbox command exists
  if {[catch { ttk::spinbox .__tmp }]} {
    set bg            [utils::get_default_background]
    set fg            [utils::get_default_foreground]
    set data(sb)      "spinbox"
    set data(sb_opts) "-relief flat -buttondownrelief flat -buttonuprelief flat -background $bg -foreground $fg"
  } else {
    set data(sb)      "ttk::spinbox"
    set data(sb_opts) ""
    destroy .__tmp
  }

  proc create_diff_bar {txt win} {

    variable data

    set data($txt,win) $win

    ttk::frame      $win
    ttk::label      $win.l1   -text "Version System: "
    ttk::menubutton $win.cvs  -menu $win.cvsMenu -direction above
    ttk::button     $win.show -text "Update" -command "[ns diff]::show $txt"

    # Create the version frame
    ttk::frame $win.vf
    ttk::label $win.vf.l1 -text "    Start: "
    $data(sb)  $win.vf.v1 {*}$data(sb_opts) -textvariable [ns diff]::data($txt,v1) -state readonly -command "[ns diff]::handle_v1 $txt"
    ttk::label $win.vf.l2 -text "    End: "
    $data(sb)  $win.vf.v2 {*}$data(sb_opts) -textvariable [ns diff]::data($txt,v2) -state readonly -command "[ns diff]::handle_v2 $txt"

    grid rowconfigure    $win.vf 0 -weight 1
    grid columnconfigure $win.vf 2 -weight 1
    grid $win.vf.l1 -row 0 -column 0 -sticky ew -padx 2
    grid $win.vf.v1 -row 0 -column 1 -sticky ew -padx 2
    grid $win.vf.l2 -row 0 -column 2 -sticky ew -padx 2
    grid $win.vf.v2 -row 0 -column 3 -sticky ew -padx 2

    # Create the file frame
    ttk::frame             $win.ff
    wmarkentry::wmarkentry $win.ff.e -watermark "Enter starting file"

    grid rowconfigure    $win.ff 0 -weight 1
    grid columnconfigure $win.ff 0 -weight 1
    grid $win.ff.e -row 0 -column 0 -sticky ew -padx 2
    
    # Create the command frame
    ttk::frame $win.cf
    wmarkentry::wmarkentry $win.cf.e -watermark "Enter difference command"

    grid rowconfigure    $win.cf 0 -weight 1
    grid columnconfigure $win.cf 0 -weight 1
    grid $win.cf.e -row 0 -column 0 -sticky ew -padx 2
    
    grid rowconfigure    $win 0 -weight 1
    grid columnconfigure $win 3 -weight 1
    grid $win
    grid $win.l1   -row 0 -column 0 -sticky ew -padx 2 -pady 2
    grid $win.cvs  -row 0 -column 1 -sticky ew -padx 2 -pady 2
    grid $win.vf   -row 0 -column 2 -sticky ew         -pady 2
    grid $win.ff   -row 0 -column 3 -sticky ew         -pady 2
    grid $win.cf   -row 0 -column 4 -sticky ew         -pady 2
    grid $win.show -row 0 -column 5 -sticky ew -padx 2 -pady 2

    # Hide the version frame, file frame and update button until they are valid
    grid remove $win.vf
    grid remove $win.ff
    grid remove $win.cf
    grid remove $win.show

    # When text widget is destroyed delete our data
    bind $win <Destroy> "diff::destroy $txt"

    # Create the CVS menu
    menu $win.cvsMenu -tearoff 0

    # Populate the CVS menu
    set first 1
    foreach type [list cvs file command] {
      if {!$first} {
        $win.cvsMenu add separator
      }
      foreach name [get_cvs_names $type] {
        $win.cvsMenu add radiobutton -label $name -variable [ns diff]::data($txt,cvs) -value $name -command "[ns diff]::update_diff_frame $txt"
      }
      set first 0
    }

  }
  
  ######################################################################
  # Handles changes to the windowing theme.
  proc handle_window_theme {theme} {
    
    variable data
    
    # Get the default background and foreground colors
    set bg  [utils::get_default_background]
    set fg  [utils::get_default_foreground]
    set abg [utils::auto_adjust_color $bg 30]
    
    # Update the spinboxes (if we are not using ttk::spinbox)
    if {$data(sb) eq "spinbox"} {
      foreach win [array names data *,win] {
        $data($win).vf.v1 configure -background $bg -foreground $fg
      }
    }
    
    # Update the difference maps
    foreach win [array names data *,canvas] {
      $data($win) configure -background $bg
    }
    
  }

  ######################################################################
  # Deletes all data associated with the given text widget.
  proc destroy {txt} {

    variable data

    array unset data $txt,*

  }

  ######################################################################
  # Performs the difference command and displays it in the text widget.
  proc show {txt} {

    variable data
    
    # Get the current working directory
    set cwd [pwd]

    # Get the current filename
    set fname [[ns gui]::current_filename]
    
    # Set the current working directory to the directory of the file
    cd [file dirname $fname]
    
    # Set fname to the tail of fname
    set fname [file tail $fname]

    # If the CVS has not been set, attempt to figure it out
    if {![info exists data($txt,cvs)] || ($data($txt,cvs) eq "")} {
      set_default_cvs $txt
    }
    
    # Get the CVS namespace name
    set cvs_ns [string tolower $data($txt,cvs)]
    
    # If the V2 file changed, replace the current file with the new content
    if {![info exists data($txt,last_v2)] || ($data($txt,v2) ne $data($txt,last_v2))} {
      
      set v2_fname $fname
    
      # If the currently selected version is not current, get the file command
      if {$data($txt,v2) ne "Current"} {
        set v2_fname [${cvs_ns}::get_file_cmd $data($txt,v2) $fname]
      }
      
      # Execute the file open and update the text widget
      if {![catch { open $v2_fname r } rc]} {
        $txt configure -state normal
        $txt delete 1.0 end
        $txt insert end [read $rc]
        $txt configure -state disabled
      }
      
      # Save the last V2
      set data($txt,last_v2) $data($txt,v2)
      
    }

    # Displays the difference data
    switch [${cvs_ns}::type] {
      cvs     { ${cvs_ns}::show_diff $txt $data($txt,v1) $data($txt,v2) $fname }
      file    { ${cvs_ns}::show_diff $txt [$data($txt,win).ff.e get] $fname }
      command { ${cvs_ns}::show_diff $txt [$data($txt,win).cf.e get] }
    }

    # Hide the update button if we are in cvs mode
    if {[${cvs_ns}::type] eq "cvs"} {
      grid remove $data($txt,win).show
    }
    
    # Reset the current working directory
    cd $cwd

  }
  
  ######################################################################
  # Returns true if the specified text widget is eligible for a file
  # update via the gui::update_file command.
  proc updateable {txt} {
    
    variable data
    
    return [expr {$data($txt,v2) eq "Current"}]
    
  }

  ######################################################################
  # PRIVATE PROCEDURES
  ######################################################################

  ######################################################################
  # Gets a sorted list of all available CVS names.
  proc get_cvs_names {type} {

    set names [list]

    foreach name [namespace children] {
      if {([${name}::type] eq $type) && ([${name}::name] ne "CVS")} {
        lappend names [${name}::name]
      }
    }

    return [lsort $names]

  }

  ######################################################################
  # Attempts to determine the default CVS that is used to manage the
  # current file and updates the UI elements to match.
  proc set_default_cvs {txt} {

    variable data
    
    # Get the current filename
    set fname [file tail [[ns gui]::current_filename]]

    set data($txt,cvs) "diff"

    # Check each of the CVS
    foreach cvs [get_cvs_names cvs] {
      if {[[string tolower $cvs]::handles $fname]} {
        set data($txt,cvs) $cvs
        break
      }
    }
    
    # Update the UI to match the selected CVS
    update_diff_frame $txt

  }

  ######################################################################
  # Called whenever the CVS value is changed.
  proc update_diff_frame {txt} {

    variable data

    set win $data($txt,win)

    switch [[string tolower $data($txt,cvs)]::type] {
      
      cvs {
        
        # Remove the file and command frames from view
        grid remove $win.ff
        grid remove $win.cf

        # Get all of the versions available for the file
        get_versions $txt

        if {[llength $data($txt,versions)] > 1} {

          # Show the version frame and update button
          grid $win.vf
          grid $win.show

          # Configure the spinboxes buttons
          $win.vf.v1 configure -values [lreverse [lrange $data($txt,versions) 1 end]]
          $win.vf.v2 configure -values [lindex $data($txt,versions) 0]

        } else {

          grid remove $win.vf
          grid remove $win.show

        } 
        
      }
      
      file {
        
        # Remove the version and command frames
        grid columnconfigure $win 4 -weight 0
        grid remove $win.vf
        grid remove $win.cf

        # Display the file frame and update button
        grid columnconfigure $win 3 -weight 1
        grid $win.ff
        grid $win.show

        # Set keyboard focus to the entry widget
        focus $win.ff.e.e

      }
      
      command {
        
        # Remove the version and file frames
        grid columnconfigure $win 3 -weight 0
        grid remove $win.vf
        grid remove $win.ff

        # Display the command frame and update button
        grid columnconfigure $win 4 -weight 1
        grid $win.cf
        grid $win.show

        # Set keyboard focus to the entry widget
        focus $win.cf.e.e

      }

    }

    # Set the menubutton name
    $win.cvs configure -text $data($txt,cvs)

  }

  ######################################################################
  # Get the available versions based on the currently selected CVS.
  proc get_versions {txt} {

    variable data

    # Get the versions
    set data($txt,versions) [list "Current" {*}[[string tolower $data($txt,cvs)]::versions [[ns gui]::current_filename]]]

    # Set the version 2 value to the current value
    set data($txt,v2) "Current"

    # Set the version 1 value to the second value
    set data($txt,v1) [lindex $data($txt,versions) 1]

  }

  ######################################################################
  # If the version of the ending version is less than or equal to the new
  # starting version, adjust the ending version to be one version newer
  # than the starting version.
  proc handle_v1 {txt} {

    variable data

    # Find the current V1 version in the versions list
    set index [lsearch $data($txt,versions) $data($txt,v1)]
    
    # Adjust version 2, if necessary
    if {$data($txt,v1) >= $data($txt,v2)} {
      set data($txt,v2) [lindex $data($txt,versions) [expr $index - 1]]
    }

    # Update V2 available versions
    $data($txt,win).vf.v2 configure -values [lreverse [lrange $data($txt,versions) 0 [expr $index - 1]]]
    
    # Make sure the update button is visible
    grid $data($txt,win).show

  }

  ######################################################################
  # Handles a change to the V2 widget.
  proc handle_v2 {txt} {

    variable data

    # Make sure the update button is visible
    grid $data($txt,win).show

  }

  ######################################################################
  # Executes the given diff command that produces diff output in unified
  # format.  Updates the specified text widget with the result.  The
  # command must be called only after the file is inserted into the editor.
  # Additionally, the file that is in the editor must be the same version
  # that is associated with the '+++' file in the diff output.
  proc parse_unified_diff {txt cmd} {
    
    # Execute the difference command
    catch { exec -ignorestderr {*}$cmd } rc

    # Open the UI for editing
    $txt configure -state normal

    # Reset the diff output
    $txt diff reset

    # Initialize variables
    set adds       0
    set subs       0
    set strSub     ""
    set total_subs 0

    # Parse the output
    foreach line [split $rc \n] {
      if {[regexp {^@@\s+\-\d+,\d+\s+\+(\d+),\d+\s+@@$} $line -> tline]} {
        set adds   0
        set subs   0
        set strSub ""
        incr tline $total_subs
      } else {
        if {[regexp {^\+([^+]|$)} $line]} {
          if {$subs > 0} {
            $txt diff sub [expr $tline - $subs] $subs $strSub
            set subs   0
            set strSub ""
          }
          incr adds
        } elseif {[regexp {^\-([^-].*$|$)} $line -> str]} {
          if {$adds > 0} {
            $txt diff add [expr $tline - $adds] $adds
            set adds 0
          }
          append strSub "$str\n"
          incr subs
          incr total_subs
        } else {
          if {$adds > 0} {
            $txt diff add [expr $tline - $adds] $adds
            set adds 0
          } elseif {$subs > 0} {
            $txt diff sub [expr $tline - $subs] $subs $strSub
            set subs   0
            set strSub ""
          }
        }
        incr tline
      }
    }

    # Disable the text window from editing
    $txt configure -state disabled
    
    # Update the map widget
    map_configure $txt

  }

  ######################################################################
  # CVS TOOL NAMESPACES
  ######################################################################

  ######################################################################
  # Handles Perforce commands
  namespace eval perforce {

    proc name {} {
      return "Perforce"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec p4 filelog $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      if {![catch { exec p4 filelog $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^\.\.\.\s+#(\d+)} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|p4 print $fname#$version"
    }

    proc show_diff {txt v1 v2 fname} {
      if {$v2 eq "Current"} {
        set ::env(P4DIFF) ""
        diff::parse_unified_diff $txt "p4 diff -du ${fname}#$v1"
      } else {
        diff::parse_unified_diff $txt "p4 diff2 -u ${fname}#$v1 ${fname}#$v2"
      }
    }

  }

  ######################################################################
  # Handles Mercurial commands
  namespace eval mercurial {

    proc name {} {
      return "Mercurial"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec hg status $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      if {![catch { exec hg log $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {changeset:\s+(\d+):} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|hg cat -r $version $fname"
    }

    proc show_diff {txt v1 v2 fname} {
      if {$v2 eq "Current"} {
        diff::parse_unified_diff $txt "hg diff -r $v1 $fname"
      } else {
        diff::parse_unified_diff $txt "hg diff -r $v1 -r $v2 $fname"
      }
    }

  }

  ######################################################################
  # Handles Subversion commands
  namespace eval subversion {

    proc name {} {
      return "Subversion"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec svn log $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      if {![catch { exec svn log $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^r(\d+)\s*\|} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|svn cat -r $version $fname"
    }

    proc show_diff {txt v1 v2 fname} {
      if {$v2 eq "Current"} {
        diff::parse_unified_diff $txt "svn diff -r $v1 $fname"
      } else {
        diff::parse_unified_diff $txt "svn diff -r $v1:$v2 $fname"
      }
    }

  }

  ######################################################################
  # Handles CVS commands
  namespace eval cvs {

    proc name {} {
      return "CVS"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec cvs log $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      if {![catch { exec cvs log $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^revision\s+(.*)$} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|cvs update -p -r $version $fname"
    }

    proc show_diff {txt v1 v2 fname} {
      if {$v2 eq "Current"} {
        diff::parse_unified_diff $txt "cvs diff -u -r $v1 $fname"
      } else {
        diff::parse_unified_diff $txt "cvs diff -u -r $v1 -r $v2 $fname"
      }
    }

  }

  ######################################################################
  # Handles diff commands
  namespace eval diff {

    proc name {} {
      return "diff"
    }

    proc type {} {
      return "file"
    }

    proc handles {fname} {
      return 0
    }

    proc show_diff {txt fname1 fname2} {
      diff::parse_unified_diff $txt "diff -u $fname1 $fname2"
    }

  }
  
  ######################################################################
  # Handles custom commands
  namespace eval custom {
    
    proc name {} {
      return "custom"
    }
    
    proc type {} {
      return "command"
    }
    
    proc handles {fname} {
      return 0
    }
    
    proc show_diff {txt command} {
      diff::parse_unified_diff $txt $command
    }
    
  }
  
  ######################################################################
  # DIFFERENCE MAP WIDGET
  ######################################################################
  
  ######################################################################
  # Creates the difference map which is basically a colored scrollbar.
  proc map {win txt args} {
    
    variable data
    
    array set opts {
      -command ""
    }
    array set opts $args
    
    # Get the background color
    set bg [utils::get_default_background]
    
    # Create the canvas
    set data($txt,canvas) [canvas $win -width 15 -relief flat -bd 1 -highlightthickness 0 -bg $bg]
    
    # Create canvas bindings
    bind $data($txt,canvas) <Configure>  [list [ns diff]::map_configure $txt]
    bind $data($txt,canvas) <Button-1>   [list [ns diff]::map_position_slider %W %y $txt $opts(-command)]
    bind $data($txt,canvas) <B1-Motion>  [list [ns diff]::map_position_slider %W %y $txt $opts(-command)]
    bind $data($txt,canvas) <MouseWheel> "event generate $txt.t <MouseWheel> -delta %D"
    bind $data($txt,canvas) <4>          "event generate $txt.t <4>"
    bind $data($txt,canvas) <5>          "event generate $txt.t <5>"
    
    rename ::$win $win
    interp alias {} ::$win {} [ns diff]::map_command $txt
    
    return $win
    
  }
  
  ######################################################################
  # Executes map commands.
  proc map_command {txt args} {
    
    variable data
    
    set args [lassign $args cmd]
    
    switch $cmd {
      
      set {
        lassign $args first last
        set height [winfo height $data($txt,canvas)]
        set y1     [expr int( $height * $first )]
        
        # Adjust the size and position of the slider
        $data($txt,canvas) coords $data($txt,slider) 2 [expr $y1 + 2] 15 [expr $y1 + $data($txt,sheight)]
      }
      
      default {
        return -code error "difference map called with invalid command ($cmd)"
      }
      
    }
    
  }
  
  ######################################################################
  # Handles a left-click or click-drag in the canvas area, positioning
  # the cursor at the given position.
  proc map_position_slider {W y txt cmd} {
    
    variable data
    
    if {$cmd ne ""} {
      
      # Calculate the moveto fraction
      set moveto [expr ($y.0 - ($data($txt,sheight) / 2)) / [winfo height $W]]
       
      # Call the command
      uplevel #0 "$cmd moveto $moveto"
      
    }
    
  }
  
  ######################################################################
  # Called whenever the map widget is configured.
  proc map_configure {txt} {
    
    variable data
    
    # Remove all canvas items
    $data($txt,canvas) delete all
    
    # Add the difference bars
    foreach type [list sub add] {
      foreach {start end} [$txt diff ranges $type] {
        set start_line [lindex [split $start .] 0]
        set end_line   [lindex [split $end .] 0]
        map_add $txt $type $start_line [expr $end_line - $start_line]
      }
    }
    
    # Calculate the slider height
    lassign [$txt yview] first last
    set height             [winfo height $data($txt,canvas)]
    set sheight            [expr ((int( $height * $last ) - int( $height * $first )) + 1) - 4]
    set data($txt,sheight) [expr ($sheight < 11) ? 11 : $sheight]
    
    # Add cursor
    set bg                [utils::get_default_background]
    set abg               [utils::auto_adjust_color $bg 50]
    set data($txt,slider) [$data($txt,canvas) create rectangle 2 0 15 10 -outline $abg -width 2]
    map_command $txt set $first $last
    
  }
  
  ######################################################################
  # Adds a sub or add bar to the associated widget.
  proc map_add {txt type start lines} {
    
    variable data
    
    # Get the number of lines in the text widget
    set txt_lines [lindex [split [$txt index end-1c] .] 0]
    
    # Get the height of the box to add
    set y1 [expr int( ($start.0 / $txt_lines) * [winfo height $data($txt,canvas)] )]
    set y2 [expr int( (($start + $lines.0) / $txt_lines) * [winfo height $data($txt,canvas)] )]
    
    # Get the color to display
    set color [expr {($type eq "sub") ? [$txt cget -diffsubbg] : [$txt cget -diffaddbg]}]
    
    # Create the rectangle and place it in the widget
    $data($txt,canvas) create rectangle 0 $y1 15 $y2 -fill $color -width 0
    
  }

}
