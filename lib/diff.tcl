# Name:     diff.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     3/23/2015
# Brief:    Contains namespace which handles displaying file version differences

namespace eval diff {
  
  source [file join $::tke_dir lib ns.tcl]
    
  array set data {}
  
  proc create_diff_bar {txt win} {
    
    variable data
    
    set data($txt,win) $win
    
    ttk::frame      $win
    ttk::label      $win.l1   -text "Version System: "
    ttk::menubutton $win.cvs  -menu $win.cvsMenu -direction above
    ttk::button     $win.show -text "Update" -command "diff::show $txt"
    
    # Create the version frame
    ttk::frame      $win.vf
    ttk::label      $win.vf.l1 -text "Start Version: "
    ttk::menubutton $win.vf.v1 -menu $win.v1Menu -direction above
    ttk::label      $win.vf.l2 -text "End Version: "
    ttk::menubutton $win.vf.v2 -menu $win.v2Menu -direction above
    
    grid rowconfigure    $win.vf 0 -weight 1
    grid columnconfigure $win.vf 2 -weight 1
    grid $win.vf.l1 -row 0 -column 0 -sticky ew -padx 2
    grid $win.vf.v1 -row 0 -column 1 -sticky ew -padx 2
    grid $win.vf.l2 -row 0 -column 2 -sticky ew -padx 2
    grid $win.vf.v2 -row 0 -column 3 -sticky ew -padx 2
       
    # Create the file frame
    ttk::frame  $win.ff
    ttk::label  $win.ff.l1 -text "Filename: "
    ttk::entry  $win.ff.e
       
    grid rowconfigure    $win.ff 0 -weight 1
    grid columnconfigure $win.ff 1 -weight 1
    grid $win.ff.l1 -row 0 -column 0 -sticky ew -padx 2
    grid $win.ff.e  -row 0 -column 1 -sticky ew -padx 2
       
    grid rowconfigure    $win 0 -weight 1
    grid columnconfigure $win 3 -weight 1
    grid $win
    grid $win.l1   -row 0 -column 0 -sticky ew -padx 2
    grid $win.cvs  -row 0 -column 1 -sticky ew -padx 2
    grid $win.vf   -row 0 -column 2 -sticky ew
    grid $win.ff   -row 0 -column 3 -sticky ew
    grid $win.show -row 0 -column 4 -sticky ew -padx 2
       
    # Hide the version frame, file frame and update button until they are valid
    grid remove $win.vf
    grid remove $win.ff
    grid remove $win.show
    
    # When text widget is destroyed delete our data
    bind $win <Destroy> "diff::destroy $txt"
    
    # Create and populate the CVS menu
    menu $win.cvsMenu -tearoff 0
    
    foreach cvs [get_cvs_names] {
      $win.cvsMenu add radiobutton -label $cvs -variable [ns diff]::data($txt,cvs) -value $cvs -command [list [ns diff]::update_diff_frame $txt]
    }
    
    # Create the V1 menu
    menu $win.v1Menu -tearoff 0 -postcommand [list [ns diff]::add_v1 $txt]
    
    # Create the V2 menu
    menu $win.v2Menu -tearoff 0 -postcommand [list [ns diff]::add_v2 $txt]
      
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
    
    # Get the current filename
    set fname [[ns gui]::current_filename]

    # If the CVS has not been set, attempt to figure it out
    if {![info exists data($txt,cvs)] || ($data($txt,cvs) eq "")} {
      set_default_cvs $txt
    }
    
    # Displays the difference data
    if {[[string tolower $data($txt,cvs)]::is_cvs]} {
      [string tolower $data($txt,cvs)]::show_diff $txt $data($txt,v1) $data($txt,v2) $fname
    }
    
    # Hide the update button
    grid remove $data($txt,win).show
    
  }
  
  ######################################################################
  # PRIVATE PROCEDURES
  ######################################################################
  
  ######################################################################
  # Gets a sorted list of all available CVS names.
  proc get_cvs_names {} {
    
    set names [list]
    
    foreach name [namespace children] {
      lappend names [${name}::name]
    }
    
    return [lsort $names]
    
  }
  
  ######################################################################
  # Attempts to determine the default CVS that is used to manage the
  # current file and updates the UI elements to match.
  proc set_default_cvs {txt} {
    
    variable data
    
    # Get the current filename
    set fname [[ns gui]::current_filename]
    
    set data($txt,cvs) "diff"
    
    # Check each of the CVS
    foreach cvs [get_cvs_names] {
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
    
    if {$data($txt,cvs) eq "diff"} {
      
      # Remove the version frame
      grid remove $win.vf
      
      # Display the file frame and update button
      grid $win.ff
      grid $win.show
      
      # Set keyboard focus to the entry widget
      focus $win.ff.e
      
    } else {
      
      grid remove $win.ff
      
      # Get all of the versions available for the file
      get_versions $txt
      
      if {[llength $data($txt,versions)] > 1} {
        
        # Show the version frame and update button
        grid $win.vf
        grid $win.show
         
        # Configure the menu buttons
        $win.vf.v1 configure -text [lindex $data($txt,versions) 1]
        $win.vf.v2 configure -text [lindex $data($txt,versions) 0]
        
      } else {
        
        grid remove $win.vf
        grid remove $win.show
        
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
  # Adds the starting version menu items.
  proc add_v1 {txt} {
    
    variable data
    
    # Get the menubutton from the menu
    set mnu $data($txt,win).v1Menu
    
    # Clear the menu
    $mnu delete 0 end
    
    # Add the items to the menu
    foreach version $data($txt,versions) {
      if {$version ne "Current"} {
        $mnu add radiobutton -label $version -variable [ns diff]::data($txt,v1) -value $version -command [list [ns diff]::handle_v1 $txt]
      }
    }
    
  }
  
  ######################################################################
  # If the version of the ending version is less than or equal to the new
  # starting version, adjust the ending version to be one version newer
  # than the starting version.
  proc handle_v1 {txt} {
    
    variable data
    
    # Adjust version 2, if necessary
    if {$data($txt,v1) >= $data($txt,v2)} {
      set index         [lsearch $data($txt,versions) $data($txt,v1)]
      set data($txt,v2) [lindex $data($txt,versions) [expr $index - 1]]
    }
    
    # Set the menubutton text
    $data($txt,win).vf.v1 configure -text $data($txt,v1)
    
    # Make sure the update button is visible
    grid $data($txt,win).show
    
  }
  
  ######################################################################
  # Adds the ending version menu items.
  proc add_v2 {txt} {
    
    variable data
    
    # Get the menubutton from the menu
    set mnu $data($txt,win).v2Menu
    
    # Clear the menu
    $mnu delete 0 end
    
    # Add the items to the menu
    foreach version $data($txt,versions) {
      if {($version eq "current") || ($version > $data($txt,v1))} {
        $mnu add radiobutton -label $version -variable [ns diff]::data($txt,v2) -value $version -command [list [ns diff]::handle_v2 $txt]
      }
    }
    
  }
  
  ######################################################################
  # Handles a change to the V2 widget.
  proc handle_v2 {txt} {
    
    variable data
    
    # Get the current filename
    set fname [[ns gui]::current_filename]
    
    # If the currently selected version is not current, get the file command
    if {$data($txt,v2) ne "Current"} {
      set fname [[string tolower $data($txt,cvs)]::get_file_cmd $data($txt,v2) $fname]
    }
      
    # Execute the file open and update the text widget
    if {![catch { open $fname r } rc]} {
      $txt configure -state normal
      $txt delete 1.0 end
      $txt insert end [read $rc]
      $txt configure -state disabled
    }
      
    # Set the menubutton text
    $data($txt,win).vf.v2 configure -text $data($txt,v2)
    
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
    if {[catch { exec -ignorestderr {*}$cmd } rc]} {
      return -code error "ERROR:  Diff command failed, $rc"
    }

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
    
    proc is_cvs {} {
      return 1
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
    
    proc is_cvs {} {
      return 1
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
    
    proc is_cvs {} {
      return 1
    }
    
    proc handles {fname} {
      return 0
    }
    
    proc versions {fname} {
      return [list]
    }
    
    proc get_file_cmd {version fname} {
      return ""
    }
    
    proc show_diff {txt v1 v2 fname} {
      # TBD
    }
    
  }
  
  ######################################################################
  # Handles CVS commands
  namespace eval cvs {
    
    proc name {} {
      return "CVS"
    }
    
    proc is_cvs {} {
      return 1
    }
    
    proc handles {fname} {
      return 0
    }
    
    proc versions {fname} {
      return [list]
    }
    
    proc get_file_cmd {version fname} {
      return ""
    }
    
    proc show_diff {txt v1 v2 fname} {
      # TBD
    }
    
  }
  
  ######################################################################
  # Handles diff commands
  namespace eval diff {
    
    proc name {} {
      return "diff"
    }
    
    proc is_cvs {} {
      return 0
    }
    
    proc handles {fname} {
      return 0
    }
    
    proc show_diff {fname1 fname2} {
      diff::parse_unified_diff $txt "diff $fname1 $fname2"
    }
    
  }
  
}
